enum TokenStatus {
  pending,
  approved,
  rejected,
  waiting,
  nearTurn,
  active,
  completed,
  expired,
}

extension TokenStatusExtension on TokenStatus {
  String get displayName {
    switch (this) {
      case TokenStatus.pending:
        return 'Pending Approval';
      case TokenStatus.approved:
        return 'Approved';
      case TokenStatus.rejected:
        return 'Rejected';
      case TokenStatus.waiting:
        return 'Waiting';
      case TokenStatus.nearTurn:
        return 'Near Your Turn';
      case TokenStatus.active:
        return 'Active';
      case TokenStatus.completed:
        return 'Completed';
      case TokenStatus.expired:
        return 'Expired';
    }
  }
}
