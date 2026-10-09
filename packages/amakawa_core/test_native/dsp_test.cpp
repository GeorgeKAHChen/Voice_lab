// Unit test for the DSP core (no audio hardware needed).
//   g++ -O2 -std=c++17 test_native/dsp_test.cpp src/dsp.cpp -o dsp_test && ./dsp_test
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <vector>

#include "../src/dsp.h"

using namespace vc;

static const double kPi = 3.14159265358979323846;
static int failures = 0;

static void check(bool ok, const char* what) {
  std::printf("  [%s] %s\n", ok ? "ok" : "FAIL", what);
  if (!ok) failures++;
}

// Band-limited harmonic source (1/h roll-off) passed through a few resonators:
// a crude vowel. Sampled from a continuous waveform, so any f0 (not just ones
// with an integer period in samples) behaves like a real recording.
static std::vector<float> vowel(float f0, float fs, int n) {
  const float F[3] = {700, 1220, 2600}, B[3] = {80, 90, 120};
  std::vector<float> x(n, 0.f);
  for (int h = 1; h * f0 < 8000.f; h++)
    for (int i = 0; i < n; i++) x[i] += (float)(std::sin(2 * kPi * h * f0 * i / fs) / h);
  for (int k = 0; k < 3; k++) {
    double r = std::exp(-kPi * B[k] / fs), th = 2 * kPi * F[k] / fs;
    double a1 = 2 * r * std::cos(th), a2 = -r * r, y1 = 0, y2 = 0;
    for (int i = 0; i < n; i++) {
      double y = x[i] + a1 * y1 + a2 * y2;
      y2 = y1;
      y1 = y;
      x[i] = (float)y;
    }
  }
  float mx = 0;
  for (float v : x) mx = std::max(mx, std::fabs(v));
  for (auto& v : x) v *= 0.3f / mx;
  return x;
}

int main() {
  const float fs = 48000.f;
  const int N = 8192;
  static Result r;

  std::printf("pitch of a synthetic vowel\n");
  for (float f0 : {90.f, 120.f, 220.f, 440.f, 800.f}) {
    auto x = vowel(f0, fs, N);
    analyze(x.data(), N, fs, r);
    char msg[96];
    std::snprintf(msg, sizeof msg, "f0 %.0f Hz -> %.1f Hz (clarity %.2f)", f0, r.f0, r.clarity);
    check(std::fabs(r.f0 - f0) < 0.012f * f0 && r.clarity > 0.8f, msg);
  }

  std::printf("spectrum of a 1 kHz sine at -6 dBFS\n");
  {
    std::vector<float> x(N);
    for (int i = 0; i < N; i++) x[i] = 0.5f * (float)std::sin(2 * kPi * 1000.0 * i / fs);
    analyze(x.data(), N, fs, r);
    int pk = 0;
    for (int k = 0; k < kSpecBins; k++)
      if (r.spectrum[k] > r.spectrum[pk]) pk = k;
    float hz = pk * fs / kFftSize;
    char msg[96];
    std::snprintf(msg, sizeof msg, "peak at %.1f Hz, %.1f dB", hz, r.spectrum[pk]);
    check(std::fabs(hz - 1000) < 15 && std::fabs(r.spectrum[pk] + 6) < 1.5f, msg);
    check(std::fabs(r.rmsDb - (-9.0f)) < 0.5f, "rms level of a 0.5 sine is -9 dB");
  }

  std::printf("silence and noise\n");
  {
    std::vector<float> x(N, 0.f);
    analyze(x.data(), N, fs, r);
    check(r.f0 == 0.f, "silence has no pitch");
    std::srand(1);
    for (auto& v : x) v = 0.3f * ((std::rand() / (float)RAND_MAX) - 0.5f);
    analyze(x.data(), N, fs, r);
    check(r.clarity < 0.6f, "white noise is not periodic");
  }

  std::printf(failures ? "FAILED (%d)\n" : "PASS\n", failures);
  return failures ? 1 : 0;
}
