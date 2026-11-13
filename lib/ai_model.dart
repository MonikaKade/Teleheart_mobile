
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

class HeartRiskPrediction {
  final double probability;
  final bool atRisk;

  const HeartRiskPrediction({
    required this.probability,
    required this.atRisk,
  });

  String get label => atRisk ? 'Berisiko' : 'Tidak Berisiko';

  double get percentage => probability * 100;
}

class HeartRiskModel {
  final Map<String, dynamic> modelData;

  HeartRiskModel._(this.modelData);

  // Membaca parameter model dari file JSON
  static Future<HeartRiskModel> load() async {
    final jsonString = await rootBundle.loadString(
      'assets/teleheart_lr_model.json',
    );

    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    return HeartRiskModel._(data);
  }

  // Menghitung prediksi risiko jantung
  HeartRiskPrediction predict(Map<String, double> input) {
    final features =
        List<String>.from(modelData['numeric_features']);

    final medians =
        List<double>.from(modelData['numeric_medians']);

    final means =
        List<double>.from(modelData['scaler_means']);

    final scales =
        List<double>.from(modelData['scaler_scales']);

    final categories =
        List<double>.from(modelData['education_categories']);

    final coefficients =
        List<double>.from(modelData['coefficients']);

    final intercept = (modelData['intercept'] as num).toDouble();

    final threshold = (modelData['threshold'] as num).toDouble();

    // Memastikan seluruh input tersedia
    for (final feature in [...features, 'education']) {
      if (!input.containsKey(feature) ||
          !input[feature]!.isFinite) {
        throw ArgumentError('Input $feature belum valid.');
      }
    }

    // Memastikan education sesuai kategori dataset
    final education = input['education']!;

    if (!categories.contains(education)) {
      throw ArgumentError('Nilai education tidak valid.');
    }

    // Menghitung nilai linear (z)
    double z = intercept;

    // Standardisasi 14 fitur numerik
    for (int i = 0; i < features.length; i++) {
      final value = input[features[i]]!;

      final imputedValue = value.isNaN
          ? medians[i]
          : value;

      final scaledValue =
          (imputedValue - means[i]) / scales[i];

          z += scaledValue * coefficients[i];
    }

    // One-Hot Encoding education
    for (int i = 0; i < categories.length; i++) {
      final encodedValue =
          education == categories[i] ? 1.0 : 0.0;

      final coefficientIndex = features.length + i;

      z += encodedValue * coefficients[coefficientIndex];
    }

    // Mengubah nilai z menjadi probabilitas
    final probability = _sigmoid(z);

    // Menentukan kelas berdasarkan threshold
    return HeartRiskPrediction(
      probability: probability,
      atRisk: probability >= threshold,
    );
  }

  // Fungsi sigmoid
  double _sigmoid(double value) {
    if (value >= 0) {
      return 1 / (1 + math.exp(-value));
    }

    final expValue = math.exp(value);
    return expValue / (1 + expValue);
  }
}
