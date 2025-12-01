import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/token.dart';
import '../models/token_type.dart';
import '../models/token_status.dart';

class TokenService extends ChangeNotifier {
  final List<Token> _allTokens = [];
  final Map<TokenType, int> _queueCounters = {};
  Timer? _queueUpdateTimer;
  final bool _useFirestore;
  final FirebaseFirestore? _firestore;
  final String? _userId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tokensSub;

  TokenService({bool useFirestore = false, FirebaseFirestore? firestore, String? userId})
      : _useFirestore = useFirestore,
        _firestore = firestore,
        _userId = userId {
    if (_useFirestore && _firestore != null) {
      _listenToFirestore();
    } else {
      _startQueueSimulation();
    }
  }

  List<Token> get activeTokens => _allTokens
      .where((t) =>
          t.status == TokenStatus.waiting ||
          t.status == TokenStatus.nearTurn ||
          t.status == TokenStatus.active)
      .toList()
    ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

  List<Token> get historyTokens => _allTokens
      .where((t) =>
          t.status == TokenStatus.completed || t.status == TokenStatus.expired)
      .toList()
    ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

  Token? getTokenById(String id) {
    try {
      return _allTokens.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Token> requestToken(TokenType type) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_useFirestore && _firestore != null) {
      // Compute queue size from Firestore for this type
      final qSnap = await _firestore!
          .collection('tokens')
          .where('type', isEqualTo: type.name)
          .where('status', whereIn: ['waiting', 'nearTurn', 'active'])
          .get();
      final currentQueue = qSnap.size;

      final id = _generateTokenId();
      final token = Token(
        id: id,
        type: type,
        requestedAt: DateTime.now(),
        queuePosition: currentQueue + 1,
        totalInQueue: currentQueue + 1,
        status: TokenStatus.waiting,
      );

      await _firestore!.collection('tokens').doc(id).set({
        'id': id,
        'userId': _userId ?? FirebaseAuth.instance.currentUser?.uid,
        'type': type.name,
        'requestedAt': token.requestedAt.toIso8601String(),
        'queuePosition': token.queuePosition,
        'totalInQueue': token.totalInQueue,
        'status': token.status.name,
      });

      // Local list will be updated by listener; return immediate token
      return token;
    } else {
      final currentQueue = _getCurrentQueueSize(type);
      final token = Token(
        id: _generateTokenId(),
        type: type,
        requestedAt: DateTime.now(),
        queuePosition: currentQueue + 1,
        totalInQueue: currentQueue + 1,
        status: TokenStatus.waiting,
      );
      _allTokens.add(token);
      _queueCounters[type] = (_queueCounters[type] ?? 0) + 1;
      notifyListeners();
      return token;
    }
  }

  void cancelToken(String tokenId) async {
    if (_useFirestore && _firestore != null) {
      await _firestore!.collection('tokens').doc(tokenId).update({
        'status': TokenStatus.expired.name,
        'completedAt': DateTime.now().toIso8601String(),
      });
      return;
    }
    final token = getTokenById(tokenId);
    if (token != null) {
      token.status = TokenStatus.expired;
      token.completedAt = DateTime.now();
      notifyListeners();
    }
  }

  void completeToken(String tokenId) async {
    if (_useFirestore && _firestore != null) {
      await _firestore!.collection('tokens').doc(tokenId).update({
        'status': TokenStatus.completed.name,
        'completedAt': DateTime.now().toIso8601String(),
      });
      return;
    }
    final token = getTokenById(tokenId);
    if (token != null) {
      token.status = TokenStatus.completed;
      token.completedAt = DateTime.now();
      notifyListeners();
    }
  }

  int _getCurrentQueueSize(TokenType type) {
    return _allTokens
        .where((t) =>
            t.type == type &&
            (t.status == TokenStatus.waiting ||
                t.status == TokenStatus.nearTurn ||
                t.status == TokenStatus.active))
        .length;
  }

  String _generateTokenId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(999999);
    return '$timestamp$randomNum';
  }

  // Simulate queue progression
  void _startQueueSimulation() {
    _queueUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      bool hasChanges = false;

      for (var token in _allTokens) {
        if (token.status == TokenStatus.waiting) {
          // Move queue forward randomly
          if (Random().nextBool() && token.queuePosition > 1) {
            token.queuePosition--;
            hasChanges = true;

            // Check if near turn (3 or less positions ahead)
            if (token.queuePosition <= 3) {
              token.status = TokenStatus.nearTurn;
            }
          }
        } else if (token.status == TokenStatus.nearTurn) {
          if (token.queuePosition == 1) {
            token.status = TokenStatus.active;
            token.activatedAt = DateTime.now();
            hasChanges = true;
          } else if (Random().nextBool() && token.queuePosition > 1) {
            token.queuePosition--;
            hasChanges = true;
          }
        } else if (token.status == TokenStatus.active) {
          // Auto-complete after some time (30% chance every cycle)
          if (Random().nextInt(10) < 3) {
            token.status = TokenStatus.completed;
            token.completedAt = DateTime.now();
            hasChanges = true;
          }
        }
      }

      if (hasChanges) {
        notifyListeners();
      }
    });
  }

  void _listenToFirestore() {
    _tokensSub = _firestore!
        .collection('tokens')
        .where('userId', isEqualTo: _userId ?? FirebaseAuth.instance.currentUser?.uid)
        .snapshots()
        .listen((snapshot) {
      _allTokens.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = TokenType.values.firstWhere((e) => e.name == (data['type'] as String));
        final status = TokenStatus.values.firstWhere((e) => e.name == (data['status'] as String));
        _allTokens.add(Token(
          id: data['id'] as String,
          type: type,
          requestedAt: DateTime.parse(data['requestedAt'] as String),
          queuePosition: (data['queuePosition'] as num).toInt(),
          totalInQueue: (data['totalInQueue'] as num).toInt(),
          status: status,
          completedAt: data['completedAt'] != null ? DateTime.parse(data['completedAt'] as String) : null,
        ));
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _queueUpdateTimer?.cancel();
    _tokensSub?.cancel();
    super.dispose();
  }
}
