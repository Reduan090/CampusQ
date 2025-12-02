import 'token_type.dart';
import 'token_status.dart';

class Token {
  final String id;
  final String userId;
  final TokenType type;
  final DateTime requestedAt;
  int queuePosition;
  final int totalInQueue;
  TokenStatus status;
  final String? message;
  DateTime? activatedAt;
  DateTime? completedAt;

  Token({
    required this.id,
    required this.userId,
    required this.type,
    required this.requestedAt,
    required this.queuePosition,
    required this.totalInQueue,
    this.status = TokenStatus.pending,
    this.message,
    this.activatedAt,
    this.completedAt,
  });

  int get estimatedWaitMinutes {
    // Estimate 5 minutes per person ahead in queue
    return queuePosition * 5;
  }

  String get tokenNumber {
    return '${type.name.toUpperCase().substring(0, 3)}-${id.substring(0, 6)}';
  }

  bool get isNearTurn {
    return queuePosition <= 3 && status == TokenStatus.waiting;
  }

  Token copyWith({
    String? id,
    String? userId,
    TokenType? type,
    DateTime? requestedAt,
    int? queuePosition,
    int? totalInQueue,
    TokenStatus? status,
    String? message,
    DateTime? activatedAt,
    DateTime? completedAt,
  }) {
    return Token(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      requestedAt: requestedAt ?? this.requestedAt,
      queuePosition: queuePosition ?? this.queuePosition,
      totalInQueue: totalInQueue ?? this.totalInQueue,
      status: status ?? this.status,
      message: message ?? this.message,
      activatedAt: activatedAt ?? this.activatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
