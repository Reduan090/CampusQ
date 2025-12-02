import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';

class NoticeService extends ChangeNotifier {
  final FirebaseFirestore? _firestore;
  final List<Notice> _notices = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _noticesSub;

  NoticeService({FirebaseFirestore? firestore}) : _firestore = firestore {
    if (_firestore != null) {
      _listenToNotices();
    }
  }

  List<Notice> get notices => List.unmodifiable(_notices);

  List<Notice> get activeNotices =>
      _notices.where((n) => n.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Notice? getNoticeById(String id) {
    try {
      return _notices.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  void _listenToNotices() {
    _noticesSub = _firestore!
        .collection('notices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _notices.clear();
      for (final doc in snapshot.docs) {
        try {
          _notices.add(Notice.fromMap(doc.data()));
        } catch (e) {
          debugPrint('Error parsing notice: $e');
        }
      }
      notifyListeners();
    });
  }

  Future<void> createNotice({
    required String title,
    required String content,
    required String createdBy,
  }) async {
    if (_firestore == null) return;

    final id = _firestore!.collection('notices').doc().id;
    final notice = Notice(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      isActive: true,
    );

    await _firestore!.collection('notices').doc(id).set(notice.toMap());
  }

  Future<void> updateNotice(String id, {String? title, String? content}) async {
    if (_firestore == null) return;

    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;

    if (updates.isNotEmpty) {
      await _firestore!.collection('notices').doc(id).update(updates);
    }
  }

  Future<void> toggleNoticeActive(String id) async {
    if (_firestore == null) return;

    final notice = getNoticeById(id);
    if (notice != null) {
      await _firestore!.collection('notices').doc(id).update({
        'isActive': !notice.isActive,
      });
    }
  }

  Future<void> deleteNotice(String id) async {
    if (_firestore == null) return;
    await _firestore!.collection('notices').doc(id).delete();
  }

  @override
  void dispose() {
    _noticesSub?.cancel();
    super.dispose();
  }
}
