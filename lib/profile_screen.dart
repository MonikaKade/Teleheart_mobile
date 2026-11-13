import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'services/token_storage.dart';
import 'profile_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Mengambil data profil pasien dari API
  Future<void> _loadProfile() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final response = await ApiService.getPatientProfile(
        accessToken: accessToken,
      );

      if (!mounted) return;

      final data = response['data'];

      setState(() {
        _profile = data is Map<String, dynamic> ? data : response;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        title: const Text(
          'Profil Pasien',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF134E5E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Kelola Profil',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileManagementScreen(),
                ),
              );

              if (!mounted) return;
              _loadProfile();
            },
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF134E5E)),
      ),
      body: _buildBody(),
    );
  }

  // Mengatur tampilan berdasarkan kondisi data
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D9488)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 45),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadProfile();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile ?? {};

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // HEADER PROFIL
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF134E5E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 48, color: Color(0xFF0D9488)),
                ),
                const SizedBox(height: 14),
                Text(
                  profile['full_name']?.toString() ?? 'Nama Pasien',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  profile['email']?.toString() ?? '-',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // INFORMASI PRIBADI
          _sectionTitle('Informasi Pribadi'),

          _infoCard(
            icon: Icons.badge_outlined,
            title: 'NIK',
            value: profile['nik_masked']?.toString() ?? '-',
          ),

          _infoCard(
            icon: Icons.phone_outlined,
            title: 'Nomor Telepon',
            value: profile['phone']?.toString() ?? '-',
          ),

          _infoCard(
            icon: Icons.cake_outlined,
            title: 'Tanggal Lahir',
            value: profile['birth_date']?.toString() ?? '-',
          ),

          _infoCard(
            icon: Icons.person_outline,
            title: 'Jenis Kelamin',
            value: profile['gender']?.toString() ?? '-',
          ),

          const SizedBox(height: 15),

          // RIWAYAT PENYAKIT
          _sectionTitle('Riwayat Penyakit'),

          _buildHealthList(
            items: profile['medical_histories'],
            icon: Icons.medical_information_outlined,
            emptyMessage: 'Belum ada riwayat penyakit.',
            titleKey: 'condition_name',
            details: (item) {
              final year = item['diagnosed_year'];
              final notes = item['notes'];

              return [
                if (year != null) 'Tahun diagnosis: $year',
                if (notes != null && notes.toString().isNotEmpty)
                  notes.toString(),
              ].join('\n');
            },
          ),

          const SizedBox(height: 15),

          // OBAT YANG DIKONSUMSI
          _sectionTitle('Obat yang Dikonsumsi'),

          _buildHealthList(
            items: profile['medications'],
            icon: Icons.medication_outlined,
            emptyMessage: 'Belum ada data obat.',
            titleKey: 'medicine_name',
            details: (item) {
              final dosage = item['dosage'];
              final frequency = item['frequency'];

              return [
                if (dosage != null) 'Dosis: $dosage',
                if (frequency != null) 'Frekuensi: $frequency',
              ].join('\n');
            },
          ),

          const SizedBox(height: 15),

          // RIWAYAT ALERGI
          _sectionTitle('Riwayat Alergi'),

          _buildHealthList(
            items: profile['allergies'],
            icon: Icons.warning_amber_outlined,
            emptyMessage: 'Belum ada data alergi.',
            titleKey: 'allergen',
            details: (item) {
              final reaction = item['reaction'];
              return reaction?.toString() ?? '';
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Judul setiap bagian profil
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF134E5E),
        ),
      ),
    );
  }

  // Menampilkan daftar riwayat kesehatan
  Widget _buildHealthList({
    required dynamic items,
    required IconData icon,
    required String emptyMessage,
    required String titleKey,
    required String Function(Map<String, dynamic>) details,
  }) {
    if (items is! List || items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return Column(
      children: items.map<Widget>((item) {
        if (item is! Map) {
          return const SizedBox.shrink();
        }

        final data = Map<String, dynamic>.from(item);
        final title = data[titleKey]?.toString() ?? '-';
        final subtitle = details(data);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF0D9488), size: 25),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF134E5E),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Kartu informasi pribadi
  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0D9488), size: 25),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF134E5E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
