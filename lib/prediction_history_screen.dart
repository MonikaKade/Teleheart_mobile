
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/token_storage.dart';

class PredictionHistoryScreen extends StatefulWidget {
  const PredictionHistoryScreen({super.key});

  @override
  State<PredictionHistoryScreen> createState() =>
      _PredictionHistoryScreenState();
}

class _PredictionHistoryScreenState
    extends State<PredictionHistoryScreen> {
  List<dynamic> _predictions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken =
          await TokenStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final response =
          await ApiService.getPredictions(
        accessToken: accessToken,
      );

      final data = response['data'];

      if (data is! List) {
        throw Exception('Format riwayat tidak valid.');
      }

      if (!mounted) return;

      setState(() {
        _predictions = data;
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

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '-';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year} '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }

  String _formatValue(dynamic value) {
    if (value == null) return '-';

    if (value is num) {
      return value.toString();
    }

    return value.toString();
  }

  Widget _buildPredictionCard(
    Map<String, dynamic> prediction,
  ) {
    final isAtRisk = prediction['result'] == 'at_risk';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Hasil Prediksi AI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    isAtRisk ? 'Berisiko' : 'Risiko Rendah',
                  ),
                  backgroundColor: isAtRisk
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              _formatDate(prediction['created_at']),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const Divider(height: 24),

            _buildInfoRow('Usia', '${_formatValue(prediction['age'])} tahun'),
            _buildInfoRow('Tekanan Sistolik', '${_formatValue(prediction['sys_bp'])} mmHg'),
            _buildInfoRow('Tekanan Diastolik', '${_formatValue(prediction['dia_bp'])} mmHg'),
            _buildInfoRow('Kolesterol', '${_formatValue(prediction['total_cholesterol'])} mg/dL'),
            _buildInfoRow('Detak Jantung', '${_formatValue(prediction['heart_rate'])} bpm'),
            _buildInfoRow('Glukosa', '${_formatValue(prediction['glucose'])} mg/dL'),
            _buildInfoRow('BMI', _formatValue(prediction['bmi'])),

            const Divider(height: 24),

            Text(
              'Model: ${_formatValue(prediction['model_version'])}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
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
        title: const Text('Riwayat Prediksi'),
        actions: [
          IconButton(
            onPressed: _loadPredictions,
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
                          onPressed: _loadPredictions,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _predictions.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada riwayat prediksi.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPredictions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _predictions.length,
                        itemBuilder: (context, index) {
                          final prediction =
                              _predictions[index]
                                  as Map<String, dynamic>;

                          return _buildPredictionCard(
                            prediction,
                          );
                        },
                      ),
                    ),
    );
  }
}
