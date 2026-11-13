
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/token_storage.dart';
import 'consultation_vitals_screen.dart';

class ConsultationFormScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final int durationMinutes;
  final String price;

  const ConsultationFormScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.durationMinutes,
    required this.price,
  });

  @override
  State<ConsultationFormScreen> createState() =>
      _ConsultationFormScreenState();
}

class _ConsultationFormScreenState
    extends State<ConsultationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _complaintController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _submitConsultation() async {
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

      final response = await ApiService.createConsultation(
        doctorId: widget.doctorId,
        durationMinutes: widget.durationMinutes,
        complaint: _complaintController.text.trim(),
        accessToken: accessToken,
      );

      debugPrint('RESPONS CREATE CONSULTATION: $response');
      
      final data = response['data'];
      final consultationId = data is Map
          ? data['id']?.toString()
          : null;

      if (consultationId == null || consultationId.isEmpty) {
         throw Exception('ID konsultasi tidak ditemukan dari server.');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
         builder: (context) => ConsultationVitalsScreen(
            consultationId: consultationId,
            doctorId: widget.doctorId,
            durationMinutes: widget.durationMinutes,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        title: const Text('Formulir Konsultasi'),
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
                'Informasi Konsultasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF134E5E),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.doctorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Durasi: ${widget.durationMinutes} menit',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Biaya: ${widget.price}',
                        style: const TextStyle(
                          color: Color(0xFF0D9488),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Keluhan Kesehatan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Jelaskan keluhan atau kondisi kesehatan '
                'yang ingin Anda konsultasikan kepada dokter.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _complaintController,
                maxLines: 6,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText:
                      'Contoh: Saya sering mengalami jantung '
                      'berdebar dan mudah lelah...',
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Keluhan kesehatan wajib diisi.';
                  }

                  if (value.trim().length < 10) {
                    return 'Jelaskan keluhan minimal 10 karakter.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : _submitConsultation,
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
                      : const Text(
                          'Buat Konsultasi',
                          style: TextStyle(
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
