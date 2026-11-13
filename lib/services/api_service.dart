import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://backend-teleheart.netlify.app/api/v1';

  static Future<Map<String, dynamic>> login({
    
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Client-Platform': 'mobile',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format respons dari server tidak valid.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = decoded['data'];

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception('Data login tidak ditemukan.');
    }

    final error = decoded['error'];
    final message = error is Map ? error['message']?.toString() : null;

    throw Exception(message ?? 'Login gagal. Silakan coba lagi.');
  }
static Future<Map<String, dynamic>> registerPatient({
  required String fullName,
  required String nik,
  required String birthDate,
  required String gender,
  required String phone,
  required String email,
  required String password,
}) async {
  final url = Uri.parse('$baseUrl/auth/register/patient');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'full_name': fullName,
      'nik': nik,
      'birth_date': birthDate,
      'gender': gender,
      'phone': phone,
      'email': email,
      'password': password,
      'consents': [
        {
          'consent_type': 'privacy_policy',
          'version': '1.0',
        },
        {
          'consent_type': 'medical_data_processing',
          'version': '1.0',
        },
      ],
    }),
  );

  final decoded = jsonDecode(response.body);

  if (decoded is! Map<String, dynamic>) {
    throw Exception('Format respons dari server tidak valid.');
  }

  if (response.statusCode >= 200 && response.statusCode < 300) {
    final data = decoded['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    return decoded;
  }

  final error = decoded['error'];
  final message = error is Map
      ? error['message']?.toString()
      : null;

  throw Exception(
    message ?? 'Registrasi gagal. Silakan coba lagi.',
  );
}


  // Menyimpan hasil prediksi AI ke backend
  static Future<Map<String, dynamic>> savePrediction({
    required Map<String, dynamic> payload,
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/predictions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(payload),
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format respons server tidak valid.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final error = decoded['error'];
    final message = error is Map ? error['message']?.toString() : null;

    throw Exception(message ?? 'Gagal menyimpan hasil prediksi.');
  }

  // Mengambil riwayat prediksi pasien dari backend
  static Future<Map<String, dynamic>> getPredictions({
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/predictions');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format respons server tidak valid.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final error = decoded['error'];
    final message = error is Map ? error['message']?.toString() : null;

    throw Exception(message ?? 'Gagal mengambil riwayat prediksi.');
  }

  // Mengambil daftar dokter dari backend
  static Future<Map<String, dynamic>> getDoctors() async {
    final url = Uri.parse('$baseUrl/doctors');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format respons dokter tidak valid.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final error = decoded['error'];
    final message = error is Map ? error['message']?.toString() : null;

    throw Exception(message ?? 'Gagal mengambil daftar dokter.');
  }

  static Future<Map<String, dynamic>> getDoctorById(String doctorId) async {
    final url = Uri.parse('$baseUrl/doctors/$doctorId');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format respons detail dokter tidak valid.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final error = decoded['error'];
    final message = error is Map ? error['message']?.toString() : null;

    throw Exception(message ?? 'Gagal mengambil detail dokter.');
  }

  static Future<Map<String, dynamic>> createConsultation({
    required String doctorId,
    required int durationMinutes,
    required String complaint,
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/consultations');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'doctor_id': doctorId,
        'duration_minutes': durationMinutes,
        'complaint': complaint,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format respons konsultasi tidak valid.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final error = decoded['error'];
    final message = error is Map ? error['message']?.toString() : null;

    throw Exception(message ?? 'Gagal membuat konsultasi.');
  }

static Future<Map<String, dynamic>> saveConsultationVitals({
  required String consultationId,
  required int systolic,
  required int diastolic,
  required int heartRate,
  required int spo2,
  required String accessToken,
  String notes = '',
}) async {
  final url = Uri.parse(
    '$baseUrl/consultations/$consultationId/vitals',
  );

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
    body: jsonEncode({
      'systolic': systolic,
      'diastolic': diastolic,
      'heart_rate': heartRate,
      'oxygen_saturation': spo2,
      'notes': notes,
    }),
  );

  return _handlePatientProfileResponse(
    response,
    'Gagal menyimpan tanda vital.',
  );
}


  // Melakukan checkout pembayaran konsultasi melalui Mayar
  static Future<Map<String, dynamic>> checkoutConsultation({
    required String consultationId,
    required String doctorId,
    required int durationMinutes,
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/consultations/$consultationId/checkout');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'doctor_id': doctorId,
        'duration_minutes': durationMinutes,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format respons pembayaran tidak valid.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final error = decoded['error'];
    final message = error is Map ? error['message']?.toString() : null;

    throw Exception(message ?? 'Gagal membuat pembayaran konsultasi.');
  }

  // Mengambil profil pasien yang sedang login
  static Future<Map<String, dynamic>> getPatientProfile({
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/patients/me/profile');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format respons profil pasien tidak valid.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final error = decoded['error'];
    final message = error is Map ? error['message']?.toString() : null;

    throw Exception(message ?? 'Gagal mengambil profil pasien.');
  }

  // UPDATE PROFIL PASIEN
  static Future<Map<String, dynamic>> updatePatientProfile({
    required String accessToken,
    required String phone,
    required bool hasPriorHospitalCheckup,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/patients/me/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'phone': phone,
        'has_prior_hospital_checkup': hasPriorHospitalCheckup,
      }),
    );

    return _handlePatientProfileResponse(
      response,
      'Gagal memperbarui profil pasien.',
    );
  }

  // TAMBAH RIWAYAT PENYAKIT
  static Future<Map<String, dynamic>> addMedicalHistory({
    required String accessToken,
    required String conditionName,
    required int diagnosedYear,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients/me/medical-histories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'condition_name': conditionName,
        'diagnosed_year': diagnosedYear,
        'status': status,
      }),
    );

    return _handlePatientProfileResponse(
      response,
      'Gagal menambahkan riwayat penyakit.',
    );
  }

  // TAMBAH OBAT
  static Future<Map<String, dynamic>> addMedication({
    required String accessToken,
    required String medicineName,
    required String dosage,
    required String frequency,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients/me/medications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'medicine_name': medicineName,
        'dosage': dosage,
        'frequency': frequency,
      }),
    );

    return _handlePatientProfileResponse(response, 'Gagal menambahkan obat.');
  }

  // TAMBAH ALERGI
  static Future<Map<String, dynamic>> addAllergy({
    required String accessToken,
    required String allergen,
    required String reactionType,
    required String severity,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients/me/allergies'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'allergen': allergen,
        'reaction_type': reactionType,
        'severity': severity,
      }),
    );

    return _handlePatientProfileResponse(response, 'Gagal menambahkan alergi.');
  }

  // PENANGANAN RESPONSE API
  static Map<String, dynamic> _handlePatientProfileResponse(
    http.Response response,
    String fallbackMessage,
  ) {
    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format respons API tidak valid.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final error = decoded['error'];
    final message = error is Map ? error['message']?.toString() : null;

    throw Exception(message ?? fallbackMessage);
  }
  
  // ==========================================
  // RIWAYAT KONSULTASI PASIEN
  // ==========================================

  static Future<Map<String, dynamic>> getConsultations({
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/consultations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    return _handlePatientProfileResponse(
      response,
      'Gagal mengambil riwayat konsultasi.',
    );
  }

  // DETAIL KONSULTASI
  static Future<Map<String, dynamic>> getConsultationById({
    required String consultationId,
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/consultations/$consultationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    return _handlePatientProfileResponse(
      response,
      'Gagal mengambil detail konsultasi.',
    );
  }

  // ==========================================
  // CHAT KONSULTASI
  // ==========================================

  // Mengambil daftar pesan konsultasi
  static Future<Map<String, dynamic>> getConsultationMessages({
    required String consultationId,
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/consultations/$consultationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    return _handlePatientProfileResponse(
      response,
      'Gagal mengambil pesan konsultasi.',
    );
  }

  // Mengirim pesan kepada dokter
  static Future<Map<String, dynamic>> sendConsultationMessage({
    required String consultationId,
    required String body,
    required String accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/consultations/$consultationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'body': body,
      }),
    );

    return _handlePatientProfileResponse(
      response,
      'Gagal mengirim pesan.',
    );
  }

  // ==========================================
  // RESEP OBAT
  // ==========================================

  // Mengambil resep berdasarkan konsultasi
  static Future<Map<String, dynamic>> getConsultationPrescription({
    required String consultationId,
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/consultations/$consultationId/prescription'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    return _handlePatientProfileResponse(
      response,
      'Gagal mengambil resep obat.',
    );
  }

  // Mengambil file resep dari backend
  static Future<http.Response> downloadPrescription({
    required String prescriptionId,
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/prescriptions/$prescriptionId/download'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return response;
    }

    String message = 'Gagal mengunduh resep obat.';

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];

        if (error is Map && error['message'] != null) {
          message = error['message'].toString();
        }
      }
    } catch (_) {
      // Gunakan pesan default jika respons bukan JSON.
    }

    throw Exception(message);
  }

static Future<Map<String, dynamic>> getNotifications({
  required String accessToken,
  int limit = 20,
}) async {
  final response = await http.get(
    Uri.parse('$baseUrl/notifications?limit=$limit'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'X-Client-Platform': 'mobile',
    },
  );

  return _handlePatientProfileResponse(
    response,
    'Gagal mengambil notifikasi.',
  );
}

static Future<Map<String, dynamic>> markNotificationAsRead({
  required String notificationId,
  required String accessToken,
}) async {
  final response = await http.patch(
    Uri.parse('$baseUrl/notifications/$notificationId/read'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'X-Client-Platform': 'mobile',
    },
  );

  return _handlePatientProfileResponse(
    response,
    'Gagal menandai notifikasi sebagai dibaca.',
  );
}

static Future<Map<String, dynamic>> markAllNotificationsAsRead({
  required String accessToken,
}) async {
  final response = await http.patch(
    Uri.parse('$baseUrl/notifications/read-all'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'X-Client-Platform': 'mobile',
    },
  );

  return _handlePatientProfileResponse(
    response,
    'Gagal menandai seluruh notifikasi sebagai dibaca.',
  );
}

static Future<Map<String, dynamic>> cancelConsultation({
  required String consultationId,
  required String accessToken,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/consultations/$consultationId/cancel'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'X-Client-Platform': 'mobile',
    },
  );

  final decoded = jsonDecode(response.body);

  if (decoded is! Map<String, dynamic>) {
    throw Exception('Format respons server tidak valid.');
  }

  if (response.statusCode >= 200 && response.statusCode < 300) {
    final data = decoded['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    return decoded;
  }

  final error = decoded['error'];
  final message = error is Map
      ? error['message']?.toString()
      : null;

  throw Exception(
    message ?? 'Gagal membatalkan konsultasi.',
  );
}

}
