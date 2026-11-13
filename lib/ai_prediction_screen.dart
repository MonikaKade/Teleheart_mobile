
import 'package:flutter/material.dart';
import 'ai_model.dart';
import 'ai_result_screen.dart';
import 'services/api_service.dart';
import 'services/token_storage.dart';


class AiPredictionScreen extends StatefulWidget {
  const AiPredictionScreen({super.key});

  @override
  State<AiPredictionScreen> createState() =>
      _AiPredictionScreenState();
}

class _AiPredictionScreenState extends State<AiPredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _controllers = {
    'age': TextEditingController(),
    'cigsPerDay': TextEditingController(),
    'totChol': TextEditingController(),
    'sysBP': TextEditingController(),
    'diaBP': TextEditingController(),
    'BMI': TextEditingController(),
    'heartRate': TextEditingController(),
    'glucose': TextEditingController(),
  };

  final Map<String, double?> _selections = {
    'male': null,
    'education': null,
    'currentSmoker': null,
    'BPMeds': null,
    'prevalentStroke': null,
    'prevalentHyp': null,
    'diabetes': null,
  };

  late final Future<HeartRiskModel> _modelFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _modelFuture = HeartRiskModel.load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D9488),
        ),
      ),
    );
  }

  Widget _numberField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Bagian ini wajib diisi';
          }

          final number = double.tryParse(value.trim());

          if (number == null || !number.isFinite) {
            return 'Masukkan angka yang valid';
          }

          return null;
        },
      ),
    );
  }

  Widget _dropdownField(
    String key,
    String label,
    List<DropdownMenuItem<double>> items,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<double>(
        initialValue: _selections[key],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        items: items,
        onChanged: (value) {
          setState(() {
            _selections[key] = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Silakan pilih salah satu';
          }
          return null;
        },
      ),
    );
  }

  List<DropdownMenuItem<double>> _binaryOptions() {
    return [
      const DropdownMenuItem(
        value: 0,
        child: Text('Tidak'),
      ),
      const DropdownMenuItem(
        value: 1,
        child: Text('Ya'),
      ),
    ];
  }


Future<void> _analyzeRisk() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final input = <String, double>{};

    // Mengambil input numerik
    for (final entry in _controllers.entries) {
      input[entry.key] =
          double.parse(entry.value.text.trim());
    }

    // Mengambil input kategori
    for (final entry in _selections.entries) {
      input[entry.key] = entry.value!;
    }

    // Menjalankan prediksi AI secara lokal
    final model = await _modelFuture;
    final result = model.predict(input);

    // Menyiapkan data untuk backend
    final payload = <String, dynamic>{
      'male': input['male'] == 1,
      'age': input['age']!.toInt(),
      'education': input['education']!.toInt(),
      'current_smoker': input['currentSmoker'] == 1,
      'cigs_per_day': input['cigsPerDay']!.toInt(),
      'bp_meds': input['BPMeds'] == 1,
      'prevalent_stroke': input['prevalentStroke'] == 1,
      'prevalent_hyp': input['prevalentHyp'] == 1,
      'diabetes': input['diabetes'] == 1,
      'total_cholesterol': input['totChol'],
      'sys_bp': input['sysBP'],
      'dia_bp': input['diaBP'],
      'bmi': input['BMI'],
      'heart_rate': input['heartRate']!.toInt(),
      'glucose': input['glucose']!.toInt(),
      'result': result.atRisk ? 'at_risk' : 'not_at_risk',
      'model_version': 'lr-v1',
    };

    // Mengirim hasil prediksi ke backend
    String saveMessage;

    try {
      final accessToken =
          await TokenStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception(
          'Sesi login tidak ditemukan. Silakan login kembali.',
        );
      }

      await ApiService.savePrediction(
        payload: payload,
        accessToken: accessToken,
      );

      saveMessage = 'Hasil prediksi berhasil disimpan ke server.';
    } catch (e) {
      saveMessage =
          'Prediksi berhasil, tetapi gagal disimpan ke server: $e';
    }

    if (!mounted) return;

    // Menampilkan hasil prediksi AI
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiResultScreen(
          result: result,
        ),
      ),
    );

    // Menampilkan status penyimpanan
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saveMessage),
        duration: const Duration(seconds: 4),
      ),
    );

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal melakukan analisis: $e'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediksi Risiko Jantung'),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Masukkan Data Kesehatan',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lengkapi seluruh data berikut untuk '
              'melakukan estimasi risiko jantung.',
              style: TextStyle(color: Colors.grey.shade700),
            ),

            _sectionTitle('1. Data Demografi'),

            _dropdownField(
              'male',
              'Jenis Kelamin',
              [
                const DropdownMenuItem(
                  value: 1,
                  child: Text('Laki-laki'),
                ),
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Perempuan'),
                ),
              ],
            ),

            _numberField('age', 'Usia (tahun)'),

            _dropdownField(
              'education',
              'Kategori Pendidikan',
              [
                for (int i = 1; i <= 4; i++)
                  DropdownMenuItem(
                    value: i.toDouble(),
                    child: Text('Kategori $i'),
                  ),
              ],
            ),

            _sectionTitle('2. Kebiasaan Merokok'),

            _dropdownField(
              'currentSmoker',
              'Apakah saat ini merokok?',
              _binaryOptions(),
            ),

            _numberField(
              'cigsPerDay',
              'Jumlah rokok per hari',
            ),

            _sectionTitle('3. Riwayat Kesehatan'),

            _dropdownField(
              'BPMeds',
              'Menggunakan obat tekanan darah?',
              _binaryOptions(),
            ),

            _dropdownField(
              'prevalentStroke',
              'Memiliki riwayat stroke?',
              _binaryOptions(),
            ),

            _dropdownField(
              'prevalentHyp',
              'Memiliki riwayat hipertensi?',
              _binaryOptions(),
            ),

            _dropdownField(
              'diabetes',
              'Memiliki riwayat diabetes?',
              _binaryOptions(),
            ),

            _sectionTitle('4. Hasil Pemeriksaan Kesehatan'),

            _numberField(
              'totChol',
              'Kolesterol total (mg/dL)',
            ),

            _numberField(
              'sysBP',
              'Tekanan darah sistolik (mmHg)',
            ),

            _numberField(
              'diaBP',
              'Tekanan darah diastolik (mmHg)',
            ),

            _numberField(
              'BMI',
              'Body Mass Index (BMI)',
            ),

            _numberField(
              'heartRate',
              'Detak jantung (bpm)',
            ),

            _numberField(
              'glucose',
              'Glukosa darah (mg/dL)',
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Penting: Masukkan hasil pemeriksaan yang '
                'sebenarnya. Jangan mengarang nilai kolesterol '
                'atau glukosa jika belum melakukan pemeriksaan.',
                style: TextStyle(fontSize: 12),
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyzeRisk,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.favorite),
                label: Text(
                  _isLoading
                      ? 'Sedang Menganalisis...'
                      : 'Analisis Risiko',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
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
    );
  }
}
