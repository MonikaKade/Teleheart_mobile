
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'consultation_form_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  final String doctorId;

  const DoctorDetailScreen({
    super.key,
    required this.doctorId,
  });

  @override
  State<DoctorDetailScreen> createState() =>
      _DoctorDetailScreenState();
}

class _DoctorDetailScreenState
    extends State<DoctorDetailScreen> {
  Map<String, dynamic>? _doctor;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedDuration = 15;

  @override
  void initState() {
    super.initState();
    _loadDoctorDetail();
  }

  Future<void> _loadDoctorDetail() async {
    try {
      final response =
          await ApiService.getDoctorById(widget.doctorId);

      final data = response['data'];

      if (data is! Map<String, dynamic>) {
        throw Exception('Data detail dokter tidak valid.');
      }

      if (!mounted) return;

      setState(() {
        _doctor = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getPrice() {
    final prices = _doctor?['prices'];

    if (prices is! List) {
      return 'Harga belum tersedia';
    }

    for (final item in prices) {
      if (item is Map &&
          item['duration_minutes'] == _selectedDuration) {
        final price = item['total_price'];

        if (price is num) {
          return 'Rp${price.toStringAsFixed(0)}';
        }
      }
    }

    return 'Harga belum tersedia';
  }

  Widget _buildDurationOption(int duration) {
    final selected = _selectedDuration == duration;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDuration = duration;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE0F2F1)
                : Colors.white,
            border: Border.all(
              color: selected
                  ? const Color(0xFF0D9488)
                  : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '$duration Menit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? const Color(0xFF0D9488)
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                selected ? 'Dipilih' : 'Pilih',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final doctor = _doctor!;

    final name =
        doctor['full_name'] ?? 'Nama tidak tersedia';
    final specialization =
        doctor['specialization'] ?? '-';
    final workplace = doctor['workplace'] ?? '-';
    final bio = doctor['bio'] ?? 'Belum ada biografi dokter.';
    final photoUrl = doctor['photo_url'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: const Color(0xFFE0F2F1),
                  backgroundImage:
                      photoUrl is String && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                  child: photoUrl == null ||
                          photoUrl.toString().isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF0D9488),
                        )
                      : null,
                ),
                const SizedBox(height: 15),
                Text(
                  name.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF134E5E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  specialization.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF0D9488),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Tempat Praktik',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.local_hospital_outlined,
                color: Color(0xFF0D9488),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(workplace.toString())),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            'Biografi Dokter',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bio.toString(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Pilih Durasi Konsultasi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildDurationOption(15),
              const SizedBox(width: 12),
              _buildDurationOption(30),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Biaya Konsultasi',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  _getPrice(),
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConsultationFormScreen(
                      doctorId: widget.doctorId,
                      doctorName: name.toString(),
                      durationMinutes: _selectedDuration,
                      price: _getPrice(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lanjutkan Konsultasi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),

          const Text(
            'Catatan: Konsultasi ini merupakan layanan '
            'pendampingan kesehatan dan bukan pengganti '
            'pemeriksaan medis darurat.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.5,
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
        title: const Text('Detail Dokter'),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadDoctorDetail,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }
}
