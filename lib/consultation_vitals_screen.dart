
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/token_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsultationVitalsScreen extends StatefulWidget {
  final String consultationId;
  final String doctorId;
  final int durationMinutes;

  const ConsultationVitalsScreen({
    super.key,
    required this.consultationId,
    required this.doctorId,
    required this.durationMinutes,
  });

  @override
  State<ConsultationVitalsScreen> createState() =>
      _ConsultationVitalsScreenState();
}

class _ConsultationVitalsScreenState
    extends State<ConsultationVitalsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _spo2Controller = TextEditingController();

  bool _isLoading = false;
  bool _vitalsSaved = false;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _spo2Controller.dispose();
    super.dispose();
  }

  String? _validateNumber(
    String? value,
    String label,
    int min,
    int max,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi.';
    }

    final number = int.tryParse(value.trim());

    if (number == null) {
      return 'Masukkan angka yang valid.';
    }

    if (number < min || number > max) {
      return 'Masukkan nilai antara $min–$max.';
    }

    return null;
  }

  Future<void> _saveVitals() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final accessToken =
          await TokenStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception(
          'Sesi login tidak ditemukan. Silakan login kembali.',
        );
      }

      await ApiService.saveConsultationVitals(
        consultationId: widget.consultationId,
        systolic: int.parse(_systolicController.text.trim()),
        diastolic: int.parse(_diastolicController.text.trim()),
        heartRate: int.parse(_heartRateController.text.trim()),
        spo2: int.parse(_spo2Controller.text.trim()),
        accessToken: accessToken,
      );

      if (!mounted) return;

      setState(() {
        _vitalsSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanda vital berhasil disimpan.'),
          backgroundColor: Colors.green,
        ),
      );
      } catch (e) {
        if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
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
  
  Future<void> _startCheckout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accessToken = await TokenStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final response = await ApiService.checkoutConsultation(
        consultationId: widget.consultationId,
        doctorId: widget.doctorId,
        durationMinutes: widget.durationMinutes,
        accessToken: accessToken,
      );

      final data = response['data'];

      final paymentUrl = data is Map
          ? data['payment_url']?.toString()
          : null;

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception('URL pembayaran tidak ditemukan.');
      }

      debugPrint('PAYMENT URL DARI SERVER: $paymentUrl');
      final uri = Uri.tryParse(paymentUrl);

      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty) {
        throw Exception('URL pembayaran dari server tidak valid.');
      }

      if (!mounted) return;

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception('Halaman pembayaran gagal dibuka.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
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

  Widget _buildVitalField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String unit,
    required int min,
    required int max,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hint,
              suffixText: unit,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            validator: (value) => _validateNumber(
              value,
              label,
              min,
              max,
            ),
          ),
          Text(
            'Rentang input: $min–$max $unit',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        title: const Text('Tanda Vital Pasien'),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lengkapi Data Tanda Vital',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF134E5E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan hasil pengukuran tanda vital '
                'pasien sebelum melanjutkan pembayaran. '
                'Gunakan hasil pengukuran aktual atau data '
                'simulasi yang ditandai sebagai data uji.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 25),

              _buildVitalField(
                label: 'Tekanan Darah Sistolik',
                hint: 'Contoh: 120',
                controller: _systolicController,
                unit: 'mmHg',
                min: 50,
                max: 250,
              ),

              _buildVitalField(
                label: 'Tekanan Darah Diastolik',
                hint: 'Contoh: 80',
                controller: _diastolicController,
                unit: 'mmHg',
                min: 30,
                max: 150,
              ),

              _buildVitalField(
                label: 'Detak Jantung',
                hint: 'Contoh: 75',
                controller: _heartRateController,
                unit: 'bpm',
                min: 30,
                max: 220,
              ),

              _buildVitalField(
                label: 'Saturasi Oksigen (SpO₂)',
                hint: 'Contoh: 98',
                controller: _spo2Controller,
                unit: '%',
                min: 50,
                max: 100,
              ),

              const SizedBox(height: 12),
              
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_vitalsSaved ? _startCheckout : _saveVitals),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : Text(
                      _vitalsSaved
                          ? 'Lanjutkan ke Pembayaran'
                          : 'Simpan Tanda Vital',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
