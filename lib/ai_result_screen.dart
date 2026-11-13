import 'package:flutter/material.dart';
import 'ai_model.dart';

class AiResultScreen extends StatelessWidget {
  final HeartRiskPrediction result;

  const AiResultScreen({
    super.key,
    required this.result,
  });

  static const Color primaryColor = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) {
    final bool atRisk = result.atRisk;
    final Color statusColor =
        atRisk ? Colors.orange.shade700 : primaryColor;
    final Color statusBackground =
        atRisk ? Colors.orange.shade50 : const Color(0xFFE0F2F1);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        title: const Text('Hasil Prediksi AI'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              const Text(
                'Hasil Analisis Risiko Jantung',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Berikut adalah hasil estimasi berdasarkan '
                'data kesehatan yang Anda masukkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 28),

              // Kartu hasil utama
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: statusBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        atRisk
                            ? Icons.warning_amber_rounded
                            : Icons.favorite_rounded,
                        color: statusColor,
                        size: 48,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      result.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${result.percentage.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Probabilitas keluaran model',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 22),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: result.probability.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Keterangan hasil
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: primaryColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Informasi Hasil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      atRisk
                          ? 'Model memberikan estimasi probabilitas '
                              'yang mencapai atau melebihi ambang '
                              'klasifikasi 50%. Hasil ini bukan '
                              'diagnosis penyakit jantung.'
                          : 'Model memberikan estimasi probabilitas '
                              'di bawah ambang klasifikasi 50%. '
                              'Hasil ini bukan jaminan bahwa seseorang '
                              'bebas dari penyakit jantung.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.orange.shade100,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      color: Colors.deepOrange,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Penting: Hasil ini merupakan estimasi '
                        'eksperimental dari model Framingham, '
                        'bukan diagnosis atau pengganti pemeriksaan '
                        'medis. Konsultasikan kondisi kesehatan '
                        'Anda kepada tenaga medis.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFF75420B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali ke Form'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}