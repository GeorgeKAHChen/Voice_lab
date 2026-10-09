#include "dsp.h"

#include <algorithm>
#include <cmath>
#include <vector>

namespace vc {

static const double kPi = 3.14159265358979323846;

// ---------------------------------------------------------------- FFT
void fft(float* re, float* im, int n) {
  for (int i = 1, j = 0; i < n; i++) {
    int bit = n >> 1;
    for (; j & bit; bit >>= 1) j ^= bit;
    j ^= bit;
    if (i < j) { std::swap(re[i], re[j]); std::swap(im[i], im[j]); }
  }
  for (int len = 2; len <= n; len <<= 1) {
    double ang = -2.0 * kPi / len;
    float wr = (float)std::cos(ang), wi = (float)std::sin(ang);
    for (int i = 0; i < n; i += len) {
      float cr = 1.f, ci = 0.f;
      for (int k = 0; k < len / 2; k++) {
        int a = i + k, b = i + k + len / 2;
        float tr = re[b] * cr - im[b] * ci;
        float ti = re[b] * ci + im[b] * cr;
        re[b] = re[a] - tr; im[b] = im[a] - ti;
        re[a] += tr;        im[a] += ti;
        float ncr = cr * wr - ci * wi;
        ci = cr * wi + ci * wr;
        cr = ncr;
      }
    }
  }
}

// ----------------------------------------------------- resampling
// Windowed-sinc resample of x[0..n) (rate fs) to rate fsOut.
static std::vector<float> resample(const float* x, int n, float fs, float fsOut) {
  std::vector<float> y;
  if (n <= 0) return y;
  double ratio = fs / fsOut;
  int m = (int)std::floor(n / ratio);
  y.resize(m);
  double fc = std::min(1.0, 1.0 / ratio) * 0.95;  // cutoff relative to input Nyquist
  const int half = 16;
  for (int i = 0; i < m; i++) {
    double t = i * ratio;
    int c = (int)std::floor(t);
    double acc = 0;
    for (int k = c - half + 1; k <= c + half; k++) {
      if (k < 0 || k >= n) continue;
      double d = k - t;
      double s = std::fabs(d) < 1e-9 ? fc : std::sin(kPi * fc * d) / (kPi * d);
      double w = 0.5 + 0.5 * std::cos(kPi * d / half);
      acc += x[k] * s * w;
    }
    y[i] = (float)acc;
  }
  return y;
}

// ---------------------------------------------------------------- YIN
float yin(const float* x, int n, float fs, float fmin, float fmax, float* clarity) {
  // Work at ~16 kHz for speed.
  std::vector<float> d16;
  float f16 = fs;
  const float* s = x;
  int sn = n;
  if (fs > 20000.f) {
    f16 = 16000.f;
    d16 = resample(x, n, fs, f16);
    s = d16.data();
    sn = (int)d16.size();
  }
  int tauMax = (int)(f16 / fmin);
  int tauMin = std::max(2, (int)(f16 / fmax));
  int W = std::min(sn - tauMax - 1, (int)(0.04f * f16));
  *clarity = 0.f;
  if (W < tauMax / 2 || W < 64) return 0.f;
  const float* seg = s + (sn - W - tauMax - 1);

  std::vector<float> df(tauMax + 1, 0.f), cm(tauMax + 1, 1.f);
  for (int tau = 1; tau <= tauMax; tau++) {
    double sum = 0;
    for (int j = 0; j < W; j++) {
      double dlt = seg[j] - seg[j + tau];
      sum += dlt * dlt;
    }
    df[tau] = (float)sum;
  }
  double run = 0;
  for (int tau = 1; tau <= tauMax; tau++) {
    run += df[tau];
    cm[tau] = run > 0 ? (float)(df[tau] * tau / run) : 1.f;
  }
  const float thr = 0.15f;
  int best = -1;
  for (int tau = tauMin; tau < tauMax; tau++) {
    if (cm[tau] < thr) {
      while (tau + 1 < tauMax && cm[tau + 1] < cm[tau]) tau++;
      best = tau;
      break;
    }
  }
  if (best < 0) {  // fall back to the global minimum, accepted only if reasonably periodic
    float mn = 1e9f;
    for (int tau = tauMin; tau < tauMax; tau++)
      if (cm[tau] < mn) { mn = cm[tau]; best = tau; }
    if (best < 0 || mn > 0.4f) return 0.f;
  }
  float t = (float)best;
  if (best > 1 && best < tauMax) {  // parabolic interpolation
    float a = cm[best - 1], b = cm[best], c = cm[best + 1];
    float den = a - 2 * b + c;
    if (std::fabs(den) > 1e-12f) t += 0.5f * (a - c) / den;
  }
  *clarity = std::max(0.f, std::min(1.f, 1.f - cm[best]));
  float f0 = f16 / t;
  if (f0 < fmin || f0 > fmax) return 0.f;
  return f0;
}

// ----------------------------------------------------------- analyze
void analyze(const float* x, int n, float fs, Result& out) {
  // Normalize to a fixed-length buffer, zero-padded at the front.
  std::vector<float> buf(kAnalysisSamples, 0.f);
  int take = std::min(n, kAnalysisSamples);
  std::copy(x + (n - take), x + n, buf.begin() + (kAnalysisSamples - take));

  // Level over the last kSpecWin samples.
  double e = 0;
  for (int i = kAnalysisSamples - kSpecWin; i < kAnalysisSamples; i++) e += (double)buf[i] * buf[i];
  e /= kSpecWin;
  out.rmsDb = (float)(10.0 * std::log10(e + 1e-12));

  // Hann-windowed, zero-padded magnitude spectrum.
  static thread_local std::vector<float> re, im, win;
  if (win.empty()) {
    win.resize(kSpecWin);
    for (int i = 0; i < kSpecWin; i++) win[i] = 0.5f - 0.5f * (float)std::cos(2 * kPi * i / (kSpecWin - 1));
  }
  re.assign(kFftSize, 0.f);
  im.assign(kFftSize, 0.f);
  const float* s = buf.data() + (kAnalysisSamples - kSpecWin);
  for (int i = 0; i < kSpecWin; i++) re[i] = s[i] * win[i];
  fft(re.data(), im.data(), kFftSize);
  // Scale so a full-scale sine reads ~0 dB (2 / (N * Hann coherent gain 0.5)).
  const float norm = 4.f / kSpecWin;
  for (int k = 0; k < kSpecBins; k++) {
    float mag = std::sqrt(re[k] * re[k] + im[k] * im[k]) * norm;
    out.spectrum[k] = 20.f * std::log10(mag + 1e-7f);
  }

  out.f0 = 0;
  out.clarity = 0;
  if (out.rmsDb < -60.f) return;  // silence: no pitch
  out.f0 = yin(buf.data(), kAnalysisSamples, fs, kF0Min, kF0Max, &out.clarity);
}

}  // namespace vc
