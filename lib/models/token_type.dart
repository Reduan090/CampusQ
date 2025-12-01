enum TokenType {
  library,
  cafeteria,
  lab,
  examPermission,
  transportPermission,
}

extension TokenTypeExtension on TokenType {
  String get displayName {
    switch (this) {
      case TokenType.library:
        return 'Library';
      case TokenType.cafeteria:
        return 'Cafeteria';
      case TokenType.lab:
        return 'Lab';
      case TokenType.examPermission:
        return 'One Day Exam Permission';
      case TokenType.transportPermission:
        return 'One Day Transport Permission';
    }
  }

  String get icon {
    switch (this) {
      case TokenType.library:
        return '📚';
      case TokenType.cafeteria:
        return '🍽️';
      case TokenType.lab:
        return '🔬';
      case TokenType.examPermission:
        return '📝';
      case TokenType.transportPermission:
        return '🚌';
    }
  }

  String get description {
    switch (this) {
      case TokenType.library:
        return 'Access to library resources';
      case TokenType.cafeteria:
        return 'Queue for cafeteria service';
      case TokenType.lab:
        return 'Lab equipment access';
      case TokenType.examPermission:
        return 'One-time exam permission';
      case TokenType.transportPermission:
        return 'One-time transport permission';
    }
  }
}
