
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'doctor_detail_screen.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() =>
      _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<dynamic> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getDoctors();
      final data = response['data'];

      if (data is! List) {
        throw Exception('Format data dokter tidak valid.');
      }

      if (!mounted) return;

      setState(() {
        _doctors = data;
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

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final name = doctor['full_name'] ?? 'Nama tidak tersedia';
    final specialization =
        doctor['specialization'] ?? 'Spesialisasi tidak tersedia';
    final workplace = doctor['workplace'] ?? '-';
    final photoUrl = doctor['photo_url'];
    final isAvailable = doctor['is_available'] == true;

    final prices = doctor['prices'] is List
        ? doctor['prices'] as List
        : [];

    String priceText = 'Harga belum tersedia';

    if (prices.isNotEmpty) {
      final firstPrice = prices.first;

      if (firstPrice is Map &&
          firstPrice['total_price'] is num) {
        priceText =
            'Mulai Rp${firstPrice['total_price']}';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFE0F2F1),
                  backgroundImage:
                      photoUrl is String && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                  child: photoUrl == null ||
                          photoUrl.toString().isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 35,
                          color: Color(0xFF0D9488),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF134E5E),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        specialization.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                const Icon(
                  Icons.local_hospital_outlined,
                  size: 18,
                  color: Color(0xFF0D9488),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    workplace.toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Icon(
                  isAvailable
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 18,
                  color: isAvailable
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isAvailable ? 'Tersedia' : 'Tidak tersedia',
                  style: TextStyle(
                    fontSize: 13,
                    color: isAvailable
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              priceText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D9488),
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAvailable
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorDetailScreen(
                              doctorId: doctor['id'].toString(),
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Lihat Detail Dokter'),
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
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        title: const Text('Konsultasi Dokter'),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadDoctors,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
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
                          onPressed: _loadDoctors,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _doctors.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada dokter tersedia.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDoctors,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          final doctor =
                              _doctors[index]
                                  as Map<String, dynamic>;

                          return _buildDoctorCard(doctor);
                        },
                      ),
                    ),
    );
  }
}
