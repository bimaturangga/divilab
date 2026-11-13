/// Prediksi sederhana berbasis regresi linear (least squares) untuk
/// halaman Laporan > Prediksi. Butuh minimal [minSamples] data.
class Forecast {
  const Forecast({required this.predicted, required this.average, required this.max, required this.changePercent});

  final List<double> predicted;
  final double average;
  final double max;
  final double changePercent; // perkiraan perubahan rata-rata ke depan (%)

  static const minSamples = 7;

  /// [values] urut dari yang paling lama ke paling baru.
  static Forecast? compute(List<double> values, {int ahead = 4}) {
    if (values.length < minSamples) return null;
    final n = values.length;
    final xs = List<double>.generate(n, (i) => i.toDouble());
    final meanX = xs.reduce((a, b) => a + b) / n;
    final meanY = values.reduce((a, b) => a + b) / n;
    var numer = 0.0;
    var den = 0.0;
    for (var i = 0; i < n; i++) {
      numer += (xs[i] - meanX) * (values[i] - meanY);
      den += (xs[i] - meanX) * (xs[i] - meanX);
    }
    final slope = den == 0 ? 0.0 : numer / den;
    final intercept = meanY - slope * meanX;
    final predicted = List<double>.generate(ahead, (i) => intercept + slope * (n + i));
    final futureAvg = predicted.reduce((a, b) => a + b) / ahead;
    return Forecast(
      predicted: predicted,
      average: meanY,
      max: values.reduce((a, b) => a > b ? a : b),
      changePercent: meanY == 0 ? 0 : (futureAvg - meanY) / meanY * 100,
    );
  }
}
