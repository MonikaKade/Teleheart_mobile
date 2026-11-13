
import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'services/token_storage.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  bool _isMarkingAll = false;
  String? _errorMessage;

  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
    }

    return token;
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();

      final response = await ApiService.getNotifications(
        accessToken: token,
      );

      final data = response['data'];

      List<dynamic> items = [];

      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic>) {
        final list = data['notifications'] ?? data['items'];

        if (list is List) {
          items = list;
        }
      }

      if (!mounted) return;

      setState(() {
        _notifications = items;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getText(
    Map<String, dynamic> notification,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final key in keys) {
      final value = notification[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  bool _isRead(Map<String, dynamic> notification) {
    if (notification['is_read'] != null) {
      return notification['is_read'] == true;
    }

    if (notification['read_at'] != null) {
      return true;
    }

    if (notification['read'] != null) {
      return notification['read'] == true;
    }

    return false;
  }

  int get _unreadCount {
    return _notifications.where((item) {
      return item is Map<String, dynamic> && !_isRead(item);
    }).length;
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (_isRead(notification)) return;

    final id = _getText(notification, ['id'], fallback: '');

    if (id.isEmpty) {
      _showMessage('ID notifikasi tidak ditemukan.');
      return;
    }

    try {
      final token = await _getToken();

      await ApiService.markNotificationAsRead(
        notificationId: id,
        accessToken: token,
      );

      if (!mounted) return;

      setState(() {
        notification['is_read'] = true;
      });
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0 || _isMarkingAll) return;

    setState(() {
      _isMarkingAll = true;
    });

    try {
      final token = await _getToken();

      await ApiService.markAllNotificationsAsRead(
        accessToken: token,
      );

      if (!mounted) return;

      setState(() {
        for (final item in _notifications) {
          if (item is Map<String, dynamic>) {
            item['is_read'] = true;
          }
        }
      });

      _showMessage('Semua notifikasi berhasil ditandai dibaca.');
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAll = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(String value) {
    if (value == '-') return value;

    try {
      final date = DateTime.parse(value).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year $hour:$minute';
    } catch (_) {
      return value;
    }
  }

  Widget _buildNotificationCard(dynamic item) {
    if (item is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    final isRead = _isRead(item);

    final title = _getText(
      item,
      ['title', 'subject'],
      fallback: 'Notifikasi TeleHeart',
    );

    final message = _getText(
      item,
      ['body', 'message', 'content'],
      fallback: 'Tidak ada detail notifikasi.',
    );

    final date = _formatDate(
      _getText(
        item,
        ['created_at', 'sent_at', 'createdAt'],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isRead ? Colors.white : const Color(0xFFE8F5F3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _markAsRead(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFCCFBF1),
                child: Icon(
                  Icons.notifications_outlined,
                  color: isRead
                      ? Colors.grey
                      : const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D9488),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    if (!isRead)
                      const Padding(
                        padding: EdgeInsets.only(top: 7),
                        child: Text(
                          'Ketuk untuk menandai sudah dibaca',
                          style: TextStyle(
                            color: Color(0xFF0D9488),
                            fontSize: 11,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _isMarkingAll ? null : _markAllAsRead,
              child: _isMarkingAll
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Baca Semua',
                      style: TextStyle(
                        color: Color(0xFF0D9488),
                      ),
                    ),
            ),
          IconButton(
            onPressed: _loadNotifications,
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
                          Icons.notifications_off_outlined,
                          size: 55,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _notifications.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Icon(
                            Icons.notifications_none,
                            size: 65,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Center(
                            child: Text('Belum ada notifikasi.'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            '$_unreadCount notifikasi belum dibaca',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._notifications.map(_buildNotificationCard),
                        ],
                      ),
                    ),
    );
  }
}
