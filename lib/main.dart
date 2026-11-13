import 'package:flutter/material.dart';

import 'ai_prediction_screen.dart';
import 'services/api_service.dart';
import 'services/token_storage.dart';
import 'prediction_history_screen.dart';
import 'doctor_list_screen.dart';
import 'profile_screen.dart';
import 'consultation_history_screen.dart';
import 'notification_screen.dart';

void main() {
  runApp(const TeleHeartApp());
}

class TeleHeartApp extends StatelessWidget {
  const TeleHeartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TeleHeart',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D9488)),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F766E), Color(0xFF134E5E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo TeleHeart
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFF0D9488),
                  size: 65,
                ),
              ),

              const SizedBox(height: 28),

              // Nama aplikasi
              const Text(
                'TeleHeart',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Pendamping Kesehatan Jantung Anda',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),

              const Spacer(),

              // Tombol sementara
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Mulai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                'TeleHeart © 2026',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isPasswordVisible = false;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password wajib diisi.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.login(email: email, password: password);

      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];

      if (accessToken == null || refreshToken == null) {
        throw Exception('Token login tidak ditemukan dari server.');
      }

      await TokenStorage.saveTokens(
        accessToken: accessToken.toString(),
        refreshToken: refreshToken.toString(),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selamat datang, ${data['user']?['full_name'] ?? 'Pasien'}!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 35),

              const Center(
                child: Icon(Icons.favorite, size: 65, color: Color(0xFF0D9488)),
              ),

              const SizedBox(height: 15),

              const Center(
                child: Text(
                  'TeleHeart',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF134E5E),
                  ),
                ),
              ),

              const SizedBox(height: 45),

              const Text(
                'Selamat Datang!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF134E5E),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Silakan masuk ke akun TeleHeart Anda.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Masukkan email Anda',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Password',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Masukkan password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Lupa Password?',
                    style: TextStyle(color: Color(0xFF0D9488)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Daftar',
                        style: TextStyle(
                          color: Color(0xFF0D9488),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool _privacyAccepted = false;
  bool _medicalDataAccepted = false;
  bool _isLoading = false;

  String? _gender;

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      _birthDateController.text =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_privacyAccepted || !_medicalDataAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan setujui kedua persetujuan terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.registerPatient(
        fullName: _nameController.text.trim(),
        nik: _nikController.text.trim(),
        birthDate: _birthDateController.text,
        gender: _gender!,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Registrasi Berhasil'),
          content: const Text(
            'Akun berhasil dibuat. Silakan masuk menggunakan email dan password yang telah didaftarkan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Kembali ke Login'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF134E5E)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                const Text(
                  'Buat Akun Baru',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF134E5E),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lengkapi data berikut untuk membuat akun TeleHeart.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                const Text('Nama Lengkap'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _decoration(
                    'Masukkan nama lengkap',
                    Icons.person_outline,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Nama lengkap wajib diisi.'
                          : null,
                ),

                const SizedBox(height: 18),
                const Text('NIK'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nikController,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  decoration: _decoration(
                    'Masukkan 16 digit NIK',
                    Icons.badge_outlined,
                  ),
                  validator: (v) =>
                      v == null || !RegExp(r'^\d{16}$').hasMatch(v.trim())
                          ? 'NIK harus terdiri dari 16 digit.'
                          : null,
                ),

                const SizedBox(height: 8),
                const Text('Tanggal Lahir'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: _selectBirthDate,
                  decoration: _decoration(
                    'Pilih tanggal lahir',
                    Icons.calendar_month_outlined,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty
                          ? 'Tanggal lahir wajib dipilih.'
                          : null,
                ),

                const SizedBox(height: 18),
                const Text('Jenis Kelamin'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: _decoration(
                    'Pilih jenis kelamin',
                    Icons.people_outline,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'male',
                      child: Text('Laki-laki'),
                    ),
                    DropdownMenuItem(
                      value: 'female',
                      child: Text('Perempuan'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                  validator: (v) =>
                      v == null ? 'Jenis kelamin wajib dipilih.' : null,
                ),

                const SizedBox(height: 18),
                const Text('Nomor Telepon'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _decoration(
                    'Contoh: 081234567890',
                    Icons.phone_outlined,
                  ),
                ),

                const SizedBox(height: 18),
                const Text('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoration(
                    'Masukkan email',
                    Icons.email_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email wajib diisi.';
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(v.trim())) {
                      return 'Format email tidak valid.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),
                const Text('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: _decoration(
                    'Minimal 8 karakter',
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => isPasswordVisible = !isPasswordVisible,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 8
                          ? 'Password minimal 8 karakter.'
                          : null,
                ),

                const SizedBox(height: 18),
                const Text('Konfirmasi Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !isConfirmPasswordVisible,
                  decoration: _decoration(
                    'Ulangi password',
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => isConfirmPasswordVisible =
                            !isConfirmPasswordVisible,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v != _passwordController.text
                          ? 'Konfirmasi password tidak sama.'
                          : null,
                ),

                const SizedBox(height: 20),
                const Text(
                  'Persetujuan Pengguna',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF134E5E),
                  ),
                ),

                CheckboxListTile(
                  value: _privacyAccepted,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Saya menyetujui kebijakan privasi TeleHeart.',
                    style: TextStyle(fontSize: 13),
                  ),
                  onChanged: (v) =>
                      setState(() => _privacyAccepted = v ?? false),
                ),

                CheckboxListTile(
                  value: _medicalDataAccepted,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Saya menyetujui pemrosesan data kesehatan.',
                    style: TextStyle(fontSize: 13),
                  ),
                  onChanged: (v) =>
                      setState(() => _medicalDataAccepted = v ?? false),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
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
                            'Daftar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun?'),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: Color(0xFF0D9488),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat Datang,',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Pasien TeleHeart 👋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF134E5E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF0D9488),
                      size: 27,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Kartu kesehatan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF134E5E)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 35),
                    const SizedBox(height: 15),
                    const Text(
                      'Jaga Kesehatan Jantung Anda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pantau kesehatan dan lakukan konsultasi '
                      'dengan dokter melalui TeleHeart.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Layanan Utama',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF134E5E),
                ),
              ),

              const SizedBox(height: 15),

              // Menu prediksi AI
              menuCard(
                icon: Icons.monitor_heart_outlined,
                title: 'Prediksi Risiko Jantung',
                description:
                    'Periksa estimasi risiko penyakit jantung '
                    'menggunakan AI.',
                color: const Color(0xFF0D9488),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AiPredictionScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Menu konsultasi
              menuCard(
                icon: Icons.medical_services_outlined,
                title: 'Konsultasi Dokter',
                description: 'Temukan dokter dan lakukan konsultasi.',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorListScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Menu riwayat
              menuCard(
                icon: Icons.history,
                title: 'Riwayat Aktivitas',
                description: 'Lihat riwayat prediksi dan konsultasi.',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PredictionHistoryScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              const Text(
                'Informasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF134E5E),
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF0D9488)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hasil prediksi AI merupakan informasi '
                        'pendukung dan bukan pengganti diagnosis dokter.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Navigasi bawah
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DoctorListScreen()),
            );
            return;
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PredictionHistoryScreen(),
              ),
            );
            return;
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            return;
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConsultationHistoryScreen(),
              ),
            );
            return;
          }

          setState(() {
            selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0D9488),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            label: 'Konsultasi',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Riwayat Konsul',
          ),
        ],
      ),
    );
  }

  // Widget untuk membuat kartu menu
  Widget menuCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
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
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
