
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/token_storage.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState
    extends State<ProfileManagementScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _historyFormKey = GlobalKey<FormState>();
  final _medicationFormKey = GlobalKey<FormState>();
  final _allergyFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _conditionController = TextEditingController();
  final _yearController = TextEditingController();
  final _medicineController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _allergenController = TextEditingController();
  final _reactionController = TextEditingController();

  bool _hasPriorHospitalCheckup = false;
  bool _isSaving = false;

  String _historyStatus = 'chronic';
  String _allergySeverity = 'moderate';

  @override
  void dispose() {
    _phoneController.dispose();
    _conditionController.dispose();
    _yearController.dispose();
    _medicineController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _allergenController.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  Future<void> _saveData(
    Future<Map<String, dynamic>> Function(String token) action,
    String successMessage,
  ) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final token = await TokenStorage.getAccessToken();

      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      await action(token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
        ),
      );
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
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label wajib diisi';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSaveButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : onPressed,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Menyimpan...' : label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return _buildSection(
      title: 'Edit Profil',
      icon: Icons.person_outline,
      children: [
        Form(
          key: _profileFormKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _phoneController,
                label: 'Nomor Telepon',
                hint: 'Contoh: 081234567890',
                keyboardType: TextInputType.phone,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Pernah melakukan pemeriksaan di rumah sakit',
                ),
                value: _hasPriorHospitalCheckup,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _hasPriorHospitalCheckup = value ?? false;
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              _buildSaveButton(
                label: 'Simpan Profil',
                onPressed: () {
                  if (!_profileFormKey.currentState!.validate()) return;

                  _saveData(
                    (token) => ApiService.updatePatientProfile(
                      accessToken: token,
                      phone: _phoneController.text.trim(),
                      hasPriorHospitalCheckup:
                          _hasPriorHospitalCheckup,
                    ),
                    'Profil berhasil diperbarui.',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryForm() {
    return _buildSection(
      title: 'Tambah Riwayat Penyakit',
      icon: Icons.medical_information_outlined,
      children: [
        Form(
          key: _historyFormKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _conditionController,
                label: 'Nama Penyakit',
                hint: 'Contoh: Hipertensi',
              ),
              _buildTextField(
                controller: _yearController,
                label: 'Tahun Diagnosis',
                hint: 'Contoh: 2023',
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                initialValue: _historyStatus,
                decoration: const InputDecoration(
                  labelText: 'Status Penyakit',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'chronic',
                    child: Text('Kronis'),
                  ),
                  DropdownMenuItem(
                    value: 'recovered',
                    child: Text('Sudah sembuh'),
                  ),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _historyStatus = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 14),
              _buildSaveButton(
                label: 'Tambah Riwayat Penyakit',
                onPressed: () {
                  if (!_historyFormKey.currentState!.validate()) return;

                  final year = int.tryParse(_yearController.text.trim());

                  if (year == null || year < 1900 || year > 2100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Masukkan tahun diagnosis yang valid.'),
                      ),
                    );
                    return;
                  }

                  _saveData(
                    (token) => ApiService.addMedicalHistory(
                      accessToken: token,
                      conditionName: _conditionController.text.trim(),
                      diagnosedYear: year,
                      status: _historyStatus,
                    ),
                    'Riwayat penyakit berhasil ditambahkan.',
                  ).then((_) {
                    if (!mounted) return;
                    _conditionController.clear();
                    _yearController.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationForm() {
    return _buildSection(
      title: 'Tambah Obat',
      icon: Icons.medication_outlined,
      children: [
        Form(
          key: _medicationFormKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _medicineController,
                label: 'Nama Obat',
                hint: 'Contoh: Amlodipine',
              ),
              _buildTextField(
                controller: _dosageController,
                label: 'Dosis',
                hint: 'Contoh: 5 mg',
              ),
              _buildTextField(
                controller: _frequencyController,
                label: 'Frekuensi Konsumsi',
                hint: 'Contoh: 1x sehari',
              ),
              _buildSaveButton(
                label: 'Tambah Obat',
                onPressed: () {
                  if (!_medicationFormKey.currentState!.validate()) return;

                  _saveData(
                    (token) => ApiService.addMedication(
                      accessToken: token,
                      medicineName: _medicineController.text.trim(),
                      dosage: _dosageController.text.trim(),
                      frequency: _frequencyController.text.trim(),
                    ),
                    'Data obat berhasil ditambahkan.',
                  ).then((_) {
                    if (!mounted) return;
                    _medicineController.clear();
                    _dosageController.clear();
                    _frequencyController.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllergyForm() {
    return _buildSection(
      title: 'Tambah Alergi',
      icon: Icons.warning_amber_outlined,
      children: [
        Form(
          key: _allergyFormKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _allergenController,
                label: 'Nama Alergen',
                hint: 'Contoh: Penisilin',
              ),
              _buildTextField(
                controller: _reactionController,
                label: 'Reaksi Alergi',
                hint: 'Contoh: Gatal dan ruam kulit',
              ),
              DropdownButtonFormField<String>(
                initialValue: _allergySeverity,
                decoration: const InputDecoration(
                  labelText: 'Tingkat Keparahan',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'mild',
                    child: Text('Ringan'),
                  ),
                  DropdownMenuItem(
                    value: 'moderate',
                    child: Text('Sedang'),
                  ),
                  DropdownMenuItem(
                    value: 'severe',
                    child: Text('Berat'),
                  ),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _allergySeverity = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 14),
              _buildSaveButton(
                label: 'Tambah Alergi',
                onPressed: () {
                  if (!_allergyFormKey.currentState!.validate()) return;

                  _saveData(
                    (token) => ApiService.addAllergy(
                      accessToken: token,
                      allergen: _allergenController.text.trim(),
                      reactionType: _reactionController.text.trim(),
                      severity: _allergySeverity,
                    ),
                    'Data alergi berhasil ditambahkan.',
                  ).then((_) {
                    if (!mounted) return;
                    _allergenController.clear();
                    _reactionController.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Profil Pasien'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Perbarui informasi profil dan data kesehatan pasien.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildProfileForm(),
          _buildHistoryForm(),
          _buildMedicationForm(),
          _buildAllergyForm(),
        ],
      ),
    );
  }
}
