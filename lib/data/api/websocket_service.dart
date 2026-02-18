import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/api_constants.dart';
import 'api_client.dart';

final _log = Logger(printer: SimplePrinter());

/// Event received from the WebSocket
class BoardEvent {
  final String type;
  final String boardId;
  final String userId;
  final dynamic data;

  BoardEvent({
    required this.type,
    required this.boardId,
    required this.userId,
    this.data,
  });

  factory BoardEvent.fromJson(Map<String, dynamic> json) {
    return BoardEvent(
      type: json['type'] as String,
      boardId: json['boardId'] as String,
      userId: json['userId'] as String,
      data: json['data'],
    );
  }
}

/// Manages a WebSocket connection to a specific board
class BoardWebSocket {
  final String boardId;
  final FlutterSecureStorage _storage;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _disposed = false;

  final _eventController = StreamController<BoardEvent>.broadcast();
  Stream<BoardEvent> get events => _eventController.stream;

  BoardWebSocket({required this.boardId, required FlutterSecureStorage storage})
      : _storage = storage;

  Future<void> connect() async {
    if (_disposed) return;

    final token = await _storage.read(key: ApiConstants.tokenKey);
    if (token == null) return;

    final url = Uri.parse(
      '${ApiConstants.wsBaseUrl}${ApiConstants.boardWebSocket(boardId)}?token=$token',
    );

    try {
      _channel = WebSocketChannel.connect(url);
      await _channel!.ready;
      _log.i('WS connected to board $boardId');

      _channel!.stream.listen(
        (message) {
          try {
            final json = jsonDecode(message as String) as Map<String, dynamic>;
            _eventController.add(BoardEvent.fromJson(json));
          } catch (e) {
            _log.w('WS parse error: $e');
          }
        },
        onError: (error) {
          _log.w('WS error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          _log.i('WS disconnected from board $boardId');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _log.w('WS connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed) connect();
    });
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _eventController.close();
  }
}

/// Provider that creates a WebSocket connection for a specific board.
/// Auto-disposes when the board screen is no longer visible.
final boardWebSocketProvider =
    Provider.autoDispose.family<BoardWebSocket, String>((ref, boardId) {
  final storage = ref.watch(secureStorageProvider);
  final ws = BoardWebSocket(boardId: boardId, storage: storage);
  ws.connect();

  ref.onDispose(() {
    ws.dispose();
  });

  return ws;
});
