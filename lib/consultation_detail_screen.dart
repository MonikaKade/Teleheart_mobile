
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/api_service.dart';
import 'services/token_storage.dart';
import 'consultation_chat_screen.dart';
import 'prescription_screen.dart';

class ConsultationDetailScreen extends StatefulWidget {
  final String consultationId;

  const ConsultationDetailScreen({
    super.key,
    required this.consultationId,
  });

  @override
  State<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState
    extends State<ConsultationDetailScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  Map<String, dynamic>? _consultation;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan.');
    }

    return token;
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getToken();

      final response = await ApiService.getConsultationById(
        consultationId: widget.consultationId,
        accessToken: token,
      );

      final data = response['data'];

      if (data is! Map<String, dynamic>) {
        throw Exception('Data detail konsultasi tidak ditemukan.');
      }

      if (!mounted) return;

      setState(() {
        _consultation = data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _value(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }
    return value.toString();
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              _value(value),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continuePayment() async {
    if (_isProcessing || _consultation == null) return;

    setState(() => _isProcessing = true);

    try {
      final token = await _getToken();

      final doctor = _consultation!['doctor'];
      final doctorId = _consultation!['doctor_id'] ??
          (doctor is Map ? doctor['id'] : null);

      final duration = int.tryParse(
            _consultation!['duration_minutes']?.toString() ?? '',
          ) ??
          0;

      if (doctorId == null || duration <= 0) {
        throw Exception(
          'Informasi dokter atau durasi konsultasi tidak lengkap.',
        );
      }

      final response = await ApiService.checkoutConsultation(
        consultationId: widget.consultationId,
        doctorId: doctorId.toString(),
        durationMinutes: duration,
        accessToken: token,
      );

      final data = response['data'];
      final paymentUrl =
          data is Map ? data['payment_url']?.toString() : null;

      final uri = Uri.tryParse(paymentUrl ?? '');

      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty) {
        throw Exception('URL pembayaran dari server tidak valid.');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Halaman pembayaran tidak dapat dibuka.');
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _cancelConsultation() async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Konsultasi?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan konsultasi ini? '
          'Setelah dibatalkan, Anda dapat membuat konsultasi baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final token = await _getToken();

      await ApiService.cancelConsultation(
        consultationId: widget.consultationId,
        accessToken: token,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konsultasi berhasil dibatalkan.'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadDetail();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = _consultation?['doctor'];

    final doctorName = doctor is Map
      ? (doctor['full_name'] ?? doctor['name'])
      : _consultation?['doctor_name'];

    final status = _consultation?['status']?.toString() ?? '';

    final canManagePayment =
        status == 'draft' || status == 'waiting_payment';

    final canChat =
        status == 'paid' ||
        status == 'scheduled' ||
        status == 'active';

    final canViewPrescription =
        status == 'completed' ||
        status == 'active' ||
        status == 'paid';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Konsultasi'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: (_isLoading || _isProcessing)
            ? null 
            : _loadDetail,
          icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadDetail,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _consultation == null
                  ? const Center(
                      child: Text('Data konsultasi tidak tersedia.'),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Informasi Konsultasi',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(height: 24),
                                _infoRow('Dokter', doctorName),
                                _infoRow('Status', status),
                                _infoRow(
                                  'Durasi',
                                  '${_value(_consultation!['duration_minutes'])} menit',
                                ),
                                _infoRow(
                                  'Tanggal',
                                  _consultation!['created_at'] ??
                                      _consultation!['scheduled_at'],
                                ),
                                _infoRow(
                                  'Keluhan',
                                  _consultation!['complaint'],
                                ),
                                _infoRow(
                                  'ID Konsultasi',
                                  widget.consultationId,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (canManagePayment)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pembayaran Konsultasi',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Konsultasi ini belum selesai dibayar. '
                                    'Silakan lanjutkan pembayaran atau '
                                    'batalkan konsultasi.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 16),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isProcessing
                                          ? null
                                          : _continuePayment,
                                      icon: const Icon(Icons.payment),
                                      label: Text(
                                        _isProcessing
                                            ? 'Memproses...'
                                            : 'Lanjutkan Pembayaran',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _isProcessing
                                          ? null
                                          : _cancelConsultation,
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        'Batalkan Konsultasi',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Layanan Konsultasi',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: canChat
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ConsultationChatScreen(
                                                  consultationId:
                                                      widget.consultationId,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    icon: const Icon(Icons.chat),
                                    label: const Text('Chat dengan Dokter'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: canViewPrescription
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PrescriptionScreen(
                                                  consultationId:
                                                      widget.consultationId,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    icon: const Icon(Icons.receipt_long),
                                    label: const Text('Lihat Resep Obat'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
