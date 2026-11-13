import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/api_service.dart';
import 'services/token_storage.dart';

class PrescriptionScreen extends StatefulWidget {
  final String consultationId;

  const PrescriptionScreen({super.key, required this.consultationId});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;

  Map<String, dynamic>? _prescription;

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  Future<void> _loadPrescription() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await TokenStorage.getAccessToken();

      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      final response = await ApiService.getConsultationPrescription(
        consultationId: widget.consultationId,
        accessToken: token,
      );

      final data = response['data'];

      if (data is Map) {
        final prescriptionData = data['prescription'];

        final result = prescriptionData is Map
            ? Map<String, dynamic>.from(prescriptionData)
            : Map<String, dynamic>.from(data);

        if (!mounted) return;

        setState(() {
          _prescription = result;
          _isLoading = false;
        });
      } else {
        throw Exception('Format data resep tidak sesuai.');
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _getValue(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value == null) continue;

      if (value is Map) {
        final nestedValue =
            value['full_name'] ?? value['name'] ?? value['doctor_name'];

        if (nestedValue != null && nestedValue.toString().trim().isNotEmpty) {
          return nestedValue.toString();
        }
      } else if (value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    final localDate = date.toLocal();

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final day = localDate.day.toString().padLeft(2, '0');
    final month = months[localDate.month - 1];
    final year = localDate.year;

    return '$day $month $year';
  }

  List<dynamic> _getMedicines() {
    if (_prescription == null) return [];

    for (final key in ['medicines', 'items', 'details', 'prescription_items']) {
      final value = _prescription![key];

      if (value is List) {
        return value;
      }
    }

    return [];
  }

  String _getPrescriptionId() {
    if (_prescription == null) return '';

    return _getValue(_prescription!, ['id', 'prescription_id'], fallback: '');
  }

  Future<void> _downloadPrescription() async {
    if (_isDownloading) return;

    final prescriptionId = _getPrescriptionId();

    if (prescriptionId.isEmpty) {
      _showMessage('ID resep tidak ditemukan.');
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final token = await TokenStorage.getAccessToken();

      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final response = await ApiService.downloadPrescription(
        prescriptionId: prescriptionId,
        accessToken: token,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Gagal mengunduh resep. Kode: ${response.statusCode}');
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      final isPdf =
          contentType.contains('application/pdf') ||
          (response.bodyBytes.length >= 4 &&
              String.fromCharCodes(response.bodyBytes.take(4)) == '%PDF');

      if (isPdf) {
        final pdfUri = Uri.dataFromBytes(
          response.bodyBytes,
          mimeType: 'application/pdf',
        );

        final opened = await launchUrl(
          pdfUri,
          mode: LaunchMode.externalApplication,
        );

        if (!opened) {
          throw Exception(
            'PDF tidak dapat dibuka. Silakan coba melalui browser.',
          );
        }
      } else {
        dynamic decoded;

        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          throw Exception('Format file unduhan tidak dikenali.');
        }

        if (decoded is! Map) {
          throw Exception('Respons unduhan resep tidak valid.');
        }

        final responseData = decoded['data'];

        String? downloadUrl;

        if (responseData is Map) {
          downloadUrl =
              responseData['download_url']?.toString() ??
              responseData['url']?.toString();
        }

        downloadUrl ??=
            decoded['download_url']?.toString() ?? decoded['url']?.toString();

        if (downloadUrl == null || downloadUrl.isEmpty) {
          throw Exception('Tautan unduhan resep tidak ditemukan.');
        }

        final uri = Uri.tryParse(downloadUrl);

        if (uri == null || uri.scheme != 'https') {
          throw Exception('Tautan unduhan tidak valid.');
        }

        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!opened) {
          throw Exception('Link resep tidak dapat dibuka.');
        }
      }

      _showMessage('Permintaan membuka resep berhasil.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(title, style: const TextStyle(color: Colors.grey)),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(dynamic medicine, int index) {
    if (medicine is! Map) {
      return const SizedBox.shrink();
    }

    final data = Map<String, dynamic>.from(medicine);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Obat ${index + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00897B),
              ),
            ),
            const SizedBox(height: 10),
            _buildInfo('Nama obat', _getValue(data, ['medicine_name', 'name'])),
            _buildInfo('Dosis', _getValue(data, ['dosage'])),
            _buildInfo('Frekuensi', _getValue(data, ['frequency'])),
            _buildInfo('Durasi', _getValue(data, ['duration'])),
            _buildInfo('Jumlah', _getValue(data, ['quantity'])),
            _buildInfo('Petunjuk', _getValue(data, ['instructions', 'notes'])),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionContent() {
    final prescription = _prescription!;
    final medicines = _getMedicines();

    return RefreshIndicator(
      onRefresh: _loadPrescription,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.medical_information_outlined,
                        color: Color(0xFF00897B),
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Informasi Resep',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfo(
                    'Dokter',
                    _getValue(prescription, ['doctor_name', 'doctor']),
                  ),
                  _buildInfo(
                    'Tanggal',
                    _formatDate(
                      prescription['issued_at'] ??
                          prescription['created_at'] ??
                          prescription['date'],
                    ),
                  ),
                  _buildInfo(
                    'Diagnosis',
                    _getValue(prescription, ['diagnosis', 'diagnosis_name']),
                  ),
                  _buildInfo('Status', _getValue(prescription, ['status'])),
                  _buildInfo(
                    'Catatan',
                    _getValue(prescription, ['notes', 'instructions']),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Daftar Obat',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (medicines.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belum ada daftar obat pada resep ini.'),
              ),
            )
          else
            ...List.generate(
              medicines.length,
              (index) => _buildMedicineCard(medicines[index], index),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadPrescription,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(
                _isDownloading ? 'Memproses...' : 'Unduh / Buka Resep',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resep Obat'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadPrescription,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 55,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Resep belum dapat ditampilkan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadPrescription,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _prescription == null
          ? const Center(child: Text('Belum ada resep dari dokter.'))
          : _buildPrescriptionContent(),
    );
  }
}
