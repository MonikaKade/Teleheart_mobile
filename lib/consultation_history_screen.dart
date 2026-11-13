
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/token_storage.dart';
import 'consultation_detail_screen.dart';

class ConsultationHistoryScreen extends StatefulWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  State<ConsultationHistoryScreen> createState() =>
      _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState
    extends State<ConsultationHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _consultations = [];

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await TokenStorage.getAccessToken();

      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      final response = await ApiService.getConsultations(
        accessToken: token,
      );

      final data = response['data'];
      List<dynamic> items = [];

      if (data is List) {
        items = data;
      } else if (data is Map) {
        final nested = data['consultations'] ?? data['items'];

        if (nested is List) {
          items = nested;
        }
      }

      if (!mounted) return;

      setState(() {
        _consultations = items;
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
    if (value == null || value.toString().trim().isEmpty) {
      return '-';
    }

    return value.toString();
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
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  String _formatStatus(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'waiting_payment':
        return 'Menunggu Pembayaran';
      case 'paid':
        return 'Sudah Dibayar';
      case 'scheduled':
        return 'Terjadwal';
      case 'active':
        return 'Sedang Berlangsung';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return _value(status);
    }
  }

  Color _statusColor(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'active':
        return Colors.blue;
      case 'scheduled':
        return Colors.teal;
      case 'waiting_payment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _doctorName(Map<String, dynamic> item) {
    final doctor = item['doctor'];

    if (doctor is Map) {
      return _value(
        doctor['full_name'] ??
            doctor['name'] ??
            doctor['doctor_name'],
      );
    }

    return _value(item['doctor_name']);
  }

  Widget _buildConsultationCard(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final status = item['status'];
    final statusText = status?.toString().toLowerCase() ?? '';

    final date = item['created_at'] ?? item['scheduled_at'];
    final duration = item['duration_minutes'];

    final doctorName = _doctorName(item);
    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(date),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatStatus(status),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Durasi: ${_value(duration)} menit',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),

            if (statusText == 'waiting_payment') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Konsultasi ini masih menunggu pembayaran. '
                        'Buka detail untuk melanjutkan pembayaran atau membatalkan konsultasi.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: id.isEmpty
                    ? null
                    : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ConsultationDetailScreen(
                              consultationId: id,
                            ),
                          ),
                        );

                        if (mounted) {
                          await _loadConsultations();
                        }
                      },
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Lihat Detail Konsultasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Konsultasi'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadConsultations,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadConsultations,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _consultations.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadConsultations,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Belum Ada Riwayat Konsultasi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Riwayat konsultasi akan muncul di sini.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConsultations,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _consultations.length,
                        itemBuilder: (context, index) {
                          final item = _consultations[index];

                          if (item is! Map) {
                            return const SizedBox.shrink();
                          }

                          return _buildConsultationCard(
                            Map<String, dynamic>.from(item),
                          );
                        },
                      ),
                    ),
    );
  }
}
