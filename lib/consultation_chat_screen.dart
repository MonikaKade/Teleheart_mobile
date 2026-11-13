
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/token_storage.dart';

class ConsultationChatScreen extends StatefulWidget {
  final String consultationId;

  const ConsultationChatScreen({
    super.key,
    required this.consultationId,
  });

  @override
  State<ConsultationChatScreen> createState() =>
      _ConsultationChatScreenState();
}

class _ConsultationChatScreenState extends State<ConsultationChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
    }

    return token;
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    setState(() {
      _error = null;
    });

    try {
      final token = await _getToken();

      final response = await ApiService.getConsultationMessages(
        consultationId: widget.consultationId,
        accessToken: token,
      );

      final data = response['data'];
      List<dynamic> items = [];

      if (data is List) {
        items = data;
      } else if (data is Map) {
        final nested = data['messages'] ?? data['items'];

        if (nested is List) {
          items = nested;
        }
      }

      if (!mounted) return;

      setState(() {
        _messages = items;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final token = await _getToken();

      await ApiService.sendConsultationMessage(
        consultationId: widget.consultationId,
        body: message,
        accessToken: token,
      );

      if (!mounted) return;

      _messageController.clear();

      await _loadMessages(showLoading: false);
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
          _isSending = false;
        });
      }
    }
  }

  String _getMessageText(Map<String, dynamic> message) {
    return (message['body'] ??
            message['message'] ??
            message['content'] ??
            '-')
        .toString();
  }

  bool _isPatientMessage(Map<String, dynamic> message) {
    final sender = message['sender'];

    final role = sender is Map
        ? (sender['role'] ??
                sender['user_role'] ??
                sender['type'])
            ?.toString()
            .toLowerCase()
        : (message['sender_role'] ??
                message['sender_type'] ??
                message['role'])
            ?.toString()
            .toLowerCase();

    return role == 'patient';
  }

  String _getSenderName(Map<String, dynamic> message) {
    final sender = message['sender'];

    if (sender is Map) {
      return (sender['full_name'] ??
              sender['name'] ??
              'Dokter')
          .toString();
    }

    return message['sender_name']?.toString() ?? 'Dokter';
  }

  String _formatMessageTime(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '';

    final localDate = date.toLocal();

    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isPatient = _isPatientMessage(message);

    final time = _formatMessageTime(
      message['created_at'] ?? message['sent_at'],
    );

    return Align(
      alignment:
          isPatient ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPatient
              ? Colors.teal.shade100
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPatient ? 'Anda' : _getSenderName(message),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isPatient ? Colors.teal : Colors.black54,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _getMessageText(message),
              style: const TextStyle(fontSize: 14),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 45,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadMessages,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMessages,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),
            Icon(
              Icons.chat_bubble_outline,
              size: 55,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                'Belum ada pesan.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 5),
            Center(
              child: Text(
                'Mulai percakapan dengan dokter.',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_error != null)
          Container(
            width: double.infinity,
            color: Colors.red.shade50,
            padding: const EdgeInsets.all(8),
            child: Text(
              'Gagal memperbarui pesan: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMessages,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final item = _messages[index];

                if (item is! Map) {
                  return const SizedBox.shrink();
                }

                return _buildMessage(
                  Map<String, dynamic>.from(item),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Dokter'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadMessages,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang pesan',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isSending,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.teal,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
