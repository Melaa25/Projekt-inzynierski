/// Pojedyncza operacja czekajaca na wyslanie do serwera.
/// Trzymamy gotowe zapytanie (adres + dane), zeby synchronizacja
/// polegala po prostu na wyslaniu ich po kolei.
class PendingOperation {
  static const String statusPending = 'pending';
  static const String statusFailed = 'failed';

  final String id;
  final String endpoint;
  final Map<String, dynamic> payload;
  final String description;
  final DateTime createdAt;
  final String status;
  final String? errorMessage;

  const PendingOperation({
    required this.id,
    required this.endpoint,
    required this.payload,
    required this.description,
    required this.createdAt,
    this.status = statusPending,
    this.errorMessage,
  });

  bool get isFailed => status == statusFailed;

  PendingOperation copyWithFailure(String message) {
    return PendingOperation(
      id: id,
      endpoint: endpoint,
      payload: payload,
      description: description,
      createdAt: createdAt,
      status: statusFailed,
      errorMessage: message,
    );
  }

  PendingOperation copyWithRetry() {
    return PendingOperation(
      id: id,
      endpoint: endpoint,
      payload: payload,
      description: description,
      createdAt: createdAt,
      status: statusPending,
    );
  }

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'] as String,
      endpoint: json['endpoint'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      description: json['description'] as String? ?? 'Operacja magazynowa',
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? statusPending,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint': endpoint,
      'payload': payload,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'error_message': errorMessage,
    };
  }
}