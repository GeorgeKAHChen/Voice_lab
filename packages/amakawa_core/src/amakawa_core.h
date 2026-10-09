// amakawa audio core: full-duplex monitoring, recording, playback and voice analysis.
// C API, consumed from Dart through dart:ffi (see ../lib/amakawa_core.dart).
#pragma once
#include <stdint.h>

#if defined(_WIN32)
#define VC_API __declspec(dllexport)
#else
#define VC_API __attribute__((visibility("default"))) __attribute__((used))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Layout of the float buffer filled by vc_analyze().
#define VC_OUT_RMS_DB 0
#define VC_OUT_F0 1           // Hz, 0 = unvoiced
#define VC_OUT_CLARITY 2      // 0..1
#define VC_OUT_SAMPLE_RATE 3
#define VC_OUT_SPECTRUM 4     // 2048 floats (dB), bin k = k * rate / 4096
#define VC_OUT_SIZE (4 + 2048)

// Per-column layout of the tracks filled by vc_file_analyze().
#define VC_TRACK_STRIDE 2     // f0, clarity
#define VC_SPEC_BINS 256      // spectrogram bins per column (0..specMaxHz)

// ---- devices
VC_API int vc_device_count(int capture);
VC_API int vc_device_name(int capture, int index, char* buf, int buflen);

// ---- engine (full duplex: mic in -> analysis/recording/monitor -> headphones out)
// Returns 0 on success, otherwise a miniaudio error code.
VC_API int vc_open(int capture_index, int playback_index, int sample_rate, int period_frames);
VC_API void vc_close(void);
VC_API double vc_latency_ms(void);   // estimated one-way buffering latency
VC_API int vc_sample_rate(void);

VC_API void vc_set_monitor(int on);
VC_API void vc_set_monitor_gain(float gain);
// Delay the headphone monitor by 0..10 seconds (0 = real time).
VC_API void vc_set_monitor_delay(float seconds);

// ---- analysis of the current source (mic, or the loaded file during playback)
VC_API int vc_analyze(float* out /* VC_OUT_SIZE floats */);

// ---- recording (16-bit mono WAV)
VC_API int vc_record_start(const char* path);
VC_API void vc_record_stop(void);
VC_API double vc_record_seconds(void);

// ---- playback
VC_API int vc_play_load(const char* path);
VC_API void vc_play_unload(void);
VC_API void vc_play_start(void);
VC_API void vc_play_pause(void);
VC_API void vc_play_seek(double seconds);
VC_API double vc_play_pos(void);
VC_API double vc_play_duration(void);
VC_API int vc_play_state(void);  // 0 paused/stopped, 1 playing, 2 finished

// ---- offline analysis of a file (thread-safe, does not need the engine)
VC_API int vc_file_info(const char* path, double* duration, int* sample_rate);
// tracks: ncols*VC_TRACK_STRIDE floats, spec: ncols*VC_SPEC_BINS floats (dB),
// wave: ncols floats (peak abs).
VC_API int vc_file_analyze(const char* path, int ncols, float spec_max_hz,
                           float* tracks, float* spec, float* wave);

#ifdef __cplusplus
}
#endif
