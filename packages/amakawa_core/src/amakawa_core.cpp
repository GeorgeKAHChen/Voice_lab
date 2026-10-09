#include "amakawa_core.h"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <mutex>
#include <thread>
#include <vector>

#include "dsp.h"
#include "miniaudio.h"

namespace {

constexpr int kRingSize = 1 << 15;  // analysis ring (power of two)

struct Engine {
  ma_context ctx{};
  ma_device device{};
  int rate = 48000;

  std::atomic<bool> monitor{false};
  std::atomic<float> gain{1.f};

  // Monitor delay line (mono), written only by the audio thread.
  std::vector<float> delayBuf;
  uint64_t delayW = 0;
  std::atomic<int> delaySamples{0};

  // analysis ring (single writer = audio thread)
  float ring[kRingSize] = {};
  std::atomic<uint64_t> wpos{0};

  // recording: audio thread -> SPSC ring -> writer thread -> WAV
  static constexpr int kRecRing = 1 << 20;
  std::vector<int16_t> recRing = std::vector<int16_t>(kRecRing);
  std::atomic<uint64_t> recW{0}, recR{0};
  std::atomic<bool> recording{false};
  std::atomic<uint64_t> recFrames{0};
  std::thread recThread;
  std::atomic<bool> recStop{false};
  ma_encoder encoder{};

  // playback
  std::mutex decMu;
  ma_decoder decoder{};
  std::atomic<bool> loaded{false};
  std::atomic<bool> playing{false};
  std::atomic<bool> finished{false};
  std::atomic<uint64_t> playFrame{0};
  uint64_t totalFrames = 0;

  void push(const float* s, int n) {
    uint64_t w = wpos.load(std::memory_order_relaxed);
    for (int i = 0; i < n; i++) ring[(w + i) & (kRingSize - 1)] = s[i];
    wpos.store(w + n, std::memory_order_release);
  }
};

Engine* g = nullptr;
std::mutex gMu;  // guards open/close

void dataCallback(ma_device* dev, void* output, const void* input, ma_uint32 frames) {
  Engine* e = (Engine*)dev->pUserData;
  const float* in = (const float*)input;
  float* out = (float*)output;  // stereo
  std::memset(out, 0, sizeof(float) * 2 * frames);

  if (e->loaded.load()) {
    // File source: decode into out (mono -> stereo) and feed the analysis ring.
    if (e->playing.load() && e->decMu.try_lock()) {
      std::vector<float> tmp(frames);
      ma_uint64 got = 0;
      ma_decoder_read_pcm_frames(&e->decoder, tmp.data(), frames, &got);
      e->decMu.unlock();
      for (ma_uint64 i = 0; i < got; i++) out[2 * i] = out[2 * i + 1] = tmp[i];
      e->push(tmp.data(), (int)got);
      e->playFrame.fetch_add(got);
      if (got < frames) { e->playing.store(false); e->finished.store(true); }
    }
  } else if (in) {
    e->push(in, (int)frames);
    const uint64_t dn = e->delayBuf.size();
    const int ds = e->delaySamples.load();
    const bool mon = e->monitor.load();
    const float gn = e->gain.load();
    for (ma_uint32 i = 0; i < frames; i++) {
      float x = in[i];
      if (dn) {
        e->delayBuf[e->delayW % dn] = x;
        if (ds > 0) x = e->delayW >= (uint64_t)ds ? e->delayBuf[(e->delayW - ds) % dn] : 0.f;
        e->delayW++;
      }
      if (mon) out[2 * i] = out[2 * i + 1] = std::max(-1.f, std::min(1.f, x * gn));
    }
  }

  if (in && e->recording.load()) {
    uint64_t w = e->recW.load(std::memory_order_relaxed);
    uint64_t r = e->recR.load(std::memory_order_acquire);
    if (w - r + frames <= (uint64_t)Engine::kRecRing) {
      for (ma_uint32 i = 0; i < frames; i++) {
        float v = std::max(-1.f, std::min(1.f, in[i]));
        e->recRing[(w + i) & (Engine::kRecRing - 1)] = (int16_t)std::lrintf(v * 32767.f);
      }
      e->recW.store(w + frames, std::memory_order_release);
      e->recFrames.fetch_add(frames);
    }
  }
}

void recWriter(Engine* e) {
  std::vector<int16_t> tmp(4096);
  for (;;) {
    uint64_t w = e->recW.load(std::memory_order_acquire);
    uint64_t r = e->recR.load(std::memory_order_relaxed);
    if (w == r) {
      if (e->recStop.load()) break;
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
      continue;
    }
    uint64_t n = std::min<uint64_t>(w - r, tmp.size());
    for (uint64_t i = 0; i < n; i++) tmp[i] = e->recRing[(r + i) & (Engine::kRecRing - 1)];
    ma_encoder_write_pcm_frames(&e->encoder, tmp.data(), n, nullptr);
    e->recR.store(r + n, std::memory_order_release);
  }
}

bool listDevices(ma_context* c, int capture, ma_device_info** infos, ma_uint32* count) {
  ma_device_info *pp, *pc;
  ma_uint32 np, nc;
  if (ma_context_get_devices(c, &pp, &np, &pc, &nc) != MA_SUCCESS) return false;
  *infos = capture ? pc : pp;
  *count = capture ? nc : np;
  return true;
}

// Decode whole file to mono float at its native rate.
bool decodeAll(const char* path, std::vector<float>& pcm, int* rate) {
  ma_decoder_config cfg = ma_decoder_config_init(ma_format_f32, 1, 0);
  ma_decoder d;
  if (ma_decoder_init_file(path, &cfg, &d) != MA_SUCCESS) return false;
  *rate = (int)d.outputSampleRate;
  ma_uint64 total = 0;
  ma_decoder_get_length_in_pcm_frames(&d, &total);
  pcm.clear();
  std::vector<float> tmp(8192);
  for (;;) {
    ma_uint64 got = 0;
    ma_decoder_read_pcm_frames(&d, tmp.data(), tmp.size(), &got);
    if (got == 0) break;
    pcm.insert(pcm.end(), tmp.begin(), tmp.begin() + got);
  }
  ma_decoder_uninit(&d);
  return !pcm.empty();
}

}  // namespace

extern "C" {

// A throw-away context used only for enumeration before/without an open engine.
static int withContext(int capture, int index, char* buf, int buflen, int* countOut) {
  ma_context c;
  if (ma_context_init(nullptr, 0, nullptr, &c) != MA_SUCCESS) return -1;
  ma_device_info* infos; ma_uint32 n;
  int res = -1;
  if (listDevices(&c, capture, &infos, &n)) {
    if (countOut) *countOut = (int)n;
    if (buf && index >= 0 && index < (int)n) {
      std::snprintf(buf, buflen, "%s", infos[index].name);
      res = 0;
    } else if (!buf) res = 0;
  }
  ma_context_uninit(&c);
  return res;
}

int vc_device_count(int capture) {
  int n = 0;
  if (withContext(capture, -1, nullptr, 0, &n) != 0) return 0;
  return n;
}

int vc_device_name(int capture, int index, char* buf, int buflen) {
  return withContext(capture, index, buf, buflen, nullptr);
}

int vc_open(int capIdx, int playIdx, int sampleRate, int periodFrames) {
  std::lock_guard<std::mutex> lk(gMu);
  if (g) return 0;
  Engine* e = new Engine();
  e->rate = sampleRate > 0 ? sampleRate : 48000;
  ma_result r = ma_context_init(nullptr, 0, nullptr, &e->ctx);
  if (r != MA_SUCCESS) { delete e; return (int)r; }

  ma_device_config cfg = ma_device_config_init(ma_device_type_duplex);
  cfg.sampleRate = (ma_uint32)e->rate;
  cfg.periodSizeInFrames = periodFrames > 0 ? periodFrames : 0;
  cfg.performanceProfile = ma_performance_profile_low_latency;
  cfg.capture.format = ma_format_f32;
  cfg.capture.channels = 1;
  cfg.playback.format = ma_format_f32;
  cfg.playback.channels = 2;
  cfg.dataCallback = dataCallback;
  cfg.pUserData = e;
  cfg.noPreSilencedOutputBuffer = MA_FALSE;
  ma_device_info *ci = nullptr, *pi = nullptr;
  ma_uint32 cn = 0, pn = 0;
  listDevices(&e->ctx, 1, &ci, &cn);
  listDevices(&e->ctx, 0, &pi, &pn);
  if (capIdx >= 0 && capIdx < (int)cn) cfg.capture.pDeviceID = &ci[capIdx].id;
  if (playIdx >= 0 && playIdx < (int)pn) cfg.playback.pDeviceID = &pi[playIdx].id;

  r = ma_device_init(&e->ctx, &cfg, &e->device);
  if (r != MA_SUCCESS) {
    ma_context_uninit(&e->ctx);
    delete e;
    return (int)r;
  }
  e->rate = (int)e->device.sampleRate;
  e->delayBuf.assign((size_t)e->rate * 12, 0.f);
  r = ma_device_start(&e->device);
  if (r != MA_SUCCESS) {
    ma_device_uninit(&e->device);
    ma_context_uninit(&e->ctx);
    delete e;
    return (int)r;
  }
  g = e;
  return 0;
}

void vc_close(void) {
  vc_record_stop();
  vc_play_unload();
  std::lock_guard<std::mutex> lk(gMu);
  if (!g) return;
  ma_device_uninit(&g->device);
  ma_context_uninit(&g->ctx);
  delete g;
  g = nullptr;
}

int vc_sample_rate(void) { return g ? g->rate : 0; }

double vc_latency_ms(void) {
  if (!g) return 0;
  double frames = (double)g->device.capture.internalPeriodSizeInFrames * g->device.capture.internalPeriods +
                  (double)g->device.playback.internalPeriodSizeInFrames * g->device.playback.internalPeriods;
  double irate = g->device.capture.internalSampleRate ? g->device.capture.internalSampleRate : g->rate;
  return 1000.0 * frames / irate;
}

void vc_set_monitor(int on) { if (g) g->monitor.store(on != 0); }
void vc_set_monitor_gain(float v) { if (g) g->gain.store(std::max(0.f, std::min(v, 4.f))); }

void vc_set_monitor_delay(float seconds) {
  if (!g) return;
  int n = (int)(std::max(0.f, std::min(seconds, 10.f)) * g->rate);
  g->delaySamples.store(n);
}

int vc_analyze(float* out) {
  Engine* e = g;
  if (!e || !out) return 0;
  const int n = vc::kAnalysisSamples;
  std::vector<float> buf(n);
  uint64_t w = e->wpos.load(std::memory_order_acquire);
  for (int i = 0; i < n; i++) {
    int64_t idx = (int64_t)w - n + i;
    buf[i] = idx < 0 ? 0.f : e->ring[idx & (kRingSize - 1)];
  }
  static thread_local vc::Result r;
  vc::analyze(buf.data(), n, (float)e->rate, r);
  out[VC_OUT_RMS_DB] = r.rmsDb;
  out[VC_OUT_F0] = r.f0;
  out[VC_OUT_CLARITY] = r.clarity;
  out[VC_OUT_SAMPLE_RATE] = (float)e->rate;
  std::memcpy(out + VC_OUT_SPECTRUM, r.spectrum, sizeof(float) * vc::kSpecBins);
  return 1;
}

// ------------------------------------------------------------ recording
int vc_record_start(const char* path) {
  Engine* e = g;
  if (!e || e->recording.load()) return -1;
  ma_encoder_config cfg = ma_encoder_config_init(ma_encoding_format_wav, ma_format_s16, 1, (ma_uint32)e->rate);
  ma_result r = ma_encoder_init_file(path, &cfg, &e->encoder);
  if (r != MA_SUCCESS) return (int)r;
  e->recW = 0; e->recR = 0; e->recFrames = 0; e->recStop = false;
  e->recThread = std::thread(recWriter, e);
  e->recording = true;
  return 0;
}

void vc_record_stop(void) {
  Engine* e = g;
  if (!e || !e->recording.load()) return;
  e->recording = false;
  e->recStop = true;
  if (e->recThread.joinable()) e->recThread.join();
  ma_encoder_uninit(&e->encoder);
}

double vc_record_seconds(void) {
  Engine* e = g;
  return e ? (double)e->recFrames.load() / e->rate : 0.0;
}

// ------------------------------------------------------------ playback
int vc_play_load(const char* path) {
  Engine* e = g;
  if (!e) return -1;
  vc_play_unload();
  std::lock_guard<std::mutex> lk(e->decMu);
  ma_decoder_config cfg = ma_decoder_config_init(ma_format_f32, 1, (ma_uint32)e->rate);
  ma_result r = ma_decoder_init_file(path, &cfg, &e->decoder);
  if (r != MA_SUCCESS) return (int)r;
  ma_uint64 total = 0;
  ma_decoder_get_length_in_pcm_frames(&e->decoder, &total);
  e->totalFrames = total;
  e->playFrame = 0;
  e->finished = false;
  e->playing = false;
  e->loaded = true;
  return 0;
}

void vc_play_unload(void) {
  Engine* e = g;
  if (!e || !e->loaded.load()) return;
  e->playing = false;
  e->loaded = false;
  std::lock_guard<std::mutex> lk(e->decMu);
  ma_decoder_uninit(&e->decoder);
}

void vc_play_start(void) {
  Engine* e = g;
  if (!e || !e->loaded.load()) return;
  if (e->finished.load()) vc_play_seek(0);
  e->playing = true;
}

void vc_play_pause(void) { if (g) g->playing = false; }

void vc_play_seek(double sec) {
  Engine* e = g;
  if (!e || !e->loaded.load()) return;
  bool wasPlaying = e->playing.exchange(false);
  std::lock_guard<std::mutex> lk(e->decMu);
  ma_uint64 f = (ma_uint64)std::max(0.0, sec * e->rate);
  if (e->totalFrames) f = std::min<ma_uint64>(f, e->totalFrames);
  ma_decoder_seek_to_pcm_frame(&e->decoder, f);
  e->playFrame = f;
  e->finished = false;
  // Prime the analysis ring with the audio just before the new position so
  // scrubbing while paused still shows a meaningful spectrum.
  ma_uint64 back = std::min<ma_uint64>(f, vc::kAnalysisSamples);
  if (back > 0) {
    ma_decoder_seek_to_pcm_frame(&e->decoder, f - back);
    std::vector<float> tmp(back);
    ma_uint64 got = 0;
    ma_decoder_read_pcm_frames(&e->decoder, tmp.data(), back, &got);
    e->push(tmp.data(), (int)got);
  } else {
    std::vector<float> z(vc::kAnalysisSamples, 0.f);
    e->push(z.data(), (int)z.size());
  }
  ma_decoder_seek_to_pcm_frame(&e->decoder, f);
  e->playing = wasPlaying;
}

double vc_play_pos(void) { return g ? (double)g->playFrame.load() / g->rate : 0.0; }
double vc_play_duration(void) { return g ? (double)g->totalFrames / g->rate : 0.0; }
int vc_play_state(void) {
  if (!g) return 0;
  if (g->finished.load()) return 2;
  return g->playing.load() ? 1 : 0;
}

// ------------------------------------------------------- offline analysis
int vc_file_info(const char* path, double* duration, int* rate) {
  ma_decoder_config cfg = ma_decoder_config_init(ma_format_f32, 1, 0);
  ma_decoder d;
  if (ma_decoder_init_file(path, &cfg, &d) != MA_SUCCESS) return -1;
  ma_uint64 total = 0;
  ma_decoder_get_length_in_pcm_frames(&d, &total);
  *rate = (int)d.outputSampleRate;
  *duration = (double)total / d.outputSampleRate;
  ma_decoder_uninit(&d);
  return 0;
}

int vc_file_analyze(const char* path, int ncols, float specMaxHz,
                    float* tracks, float* spec, float* wave) {
  std::vector<float> pcm;
  int rate = 0;
  if (!decodeAll(path, pcm, &rate) || ncols <= 0) return -1;
  int total = (int)pcm.size();
  static thread_local vc::Result r;
  const float binHz = (float)rate / vc::kFftSize;
  for (int c = 0; c < ncols; c++) {
    int64_t center = (int64_t)((c + 0.5) * total / ncols);
    int64_t endIdx = std::min<int64_t>(total, center + vc::kSpecWin / 2);
    int64_t startIdx = std::max<int64_t>(0, endIdx - vc::kAnalysisSamples);
    // peak over this column's span
    int64_t a = (int64_t)((double)c * total / ncols), b = (int64_t)((double)(c + 1) * total / ncols);
    float pk = 0;
    for (int64_t i = a; i < std::min<int64_t>(b, total); i++) pk = std::max(pk, std::fabs(pcm[i]));
    if (wave) wave[c] = pk;
    vc::analyze(pcm.data() + startIdx, (int)(endIdx - startIdx), (float)rate, r);
    float* t = tracks + (size_t)c * VC_TRACK_STRIDE;
    t[0] = r.f0; t[1] = r.clarity;
    float* s = spec + (size_t)c * VC_SPEC_BINS;
    for (int k = 0; k < VC_SPEC_BINS; k++) {
      // max-pool bins covering [k, k+1) * specMaxHz / VC_SPEC_BINS
      int b0 = (int)(k * specMaxHz / VC_SPEC_BINS / binHz);
      int b1 = std::max(b0 + 1, (int)((k + 1) * specMaxHz / VC_SPEC_BINS / binHz));
      b1 = std::min(b1, vc::kSpecBins);
      float m = -200.f;
      for (int j = std::min(b0, vc::kSpecBins - 1); j < b1; j++) m = std::max(m, r.spectrum[j]);
      s[k] = m;
    }
  }
  // Temporal median (7 columns) over voiced values to remove jitter / octave jumps.
  {
    std::vector<float> src(ncols);
    for (int c = 0; c < ncols; c++) src[c] = tracks[(size_t)c * VC_TRACK_STRIDE];
    for (int c = 0; c < ncols; c++) {
      float vals[7];
      int n = 0;
      for (int d = -3; d <= 3; d++) {
        int cc = c + d;
        if (cc >= 0 && cc < ncols && src[cc] > 0) vals[n++] = src[cc];
      }
      float* o = tracks + (size_t)c * VC_TRACK_STRIDE;
      if (n < 3 || src[c] <= 0) { *o = 0; continue; }
      std::sort(vals, vals + n);
      *o = vals[n / 2];
    }
  }
  return 0;
}

}  // extern "C"
