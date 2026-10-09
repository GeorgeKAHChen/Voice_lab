// Voice analysis DSP: magnitude spectrum, pitch (YIN) and level.
#pragma once

namespace vc {

constexpr int kFftSize = 4096;            // zero-padded FFT length
constexpr int kSpecBins = kFftSize / 2;   // 2048 bins, 0..fs/2
constexpr int kSpecWin = 2048;            // samples actually windowed
constexpr int kAnalysisSamples = 4096;    // samples the analyzer looks back over

constexpr float kF0Min = 60.f;            // pitch search range (Hz)
constexpr float kF0Max = 1000.f;

struct Result {
  float rmsDb = -120.f;
  float f0 = 0.f;        // 0 = unvoiced / silence
  float clarity = 0.f;   // 0..1 periodicity
  float spectrum[kSpecBins];  // dB (0 dB = full-scale sine), bin k = k * fs / kFftSize
};

// x: the most recent `n` samples (newest last) at sample rate fs.
// If n < kAnalysisSamples the signal is treated as zero-padded at the start.
void analyze(const float* x, int n, float fs, Result& out);

// Exposed for tests.
void fft(float* re, float* im, int n);
float yin(const float* x, int n, float fs, float fmin, float fmax, float* clarity);

}  // namespace vc
