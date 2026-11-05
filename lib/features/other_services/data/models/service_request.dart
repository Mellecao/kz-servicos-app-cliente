/// Estados reais de `service_requests.status` (enum `service_request_status`).
///
/// Fluxo canónico: o admin aprova, convida e escolhe o prestador
/// (`searching_provider → awaiting_client_confirmation`, com `final_price`).
/// O cliente aceita (`assigned`; o trigger do banco converte em
/// `awaiting_provider_confirmation` até o prestador confirmar) e o serviço
/// segue `assigned → in_progress → finished`.
enum ServiceRequestStatus {
  open('open', 'Pedido enviado'),
  underReview('under_review', 'Em análise'),
  reviewRejected('review_rejected', 'Pedido recusado'),
  searchingProvider('searching_provider', 'À procura de profissional'),
  awaitingClientConfirmation(
    'awaiting_client_confirmation',
    'Aguarda a sua confirmação',
  ),
  awaitingProviderConfirmation(
    'awaiting_provider_confirmation',
    'A aguardar o prestador',
  ),
  assigned('assigned', 'Prestador atribuído'),
  inProgress('in_progress', 'Em curso'),
  finished('finished', 'Concluído'),
  cancelled('cancelled', 'Cancelado');

  const ServiceRequestStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ServiceRequestStatus fromDb(String? value) => values.firstWhere(
    (s) => s.dbValue == value,
    orElse: () => ServiceRequestStatus.open,
  );

  /// O cliente só aceita o prestador escolhido neste estado.
  bool get canAccept => this == awaitingClientConfirmation;

  /// Cancelável pelo cliente até o serviço começar.
  bool get canCancel => switch (this) {
    open ||
    underReview ||
    searchingProvider ||
    awaitingClientConfirmation ||
    awaitingProviderConfirmation ||
    assigned => true,
    _ => false,
  };

  bool get isFinal => this == finished || this == cancelled || this == reviewRejected;

  /// Há prestador associado ao pedido e a conversa faz sentido.
  bool get hasChat => switch (this) {
    awaitingProviderConfirmation || assigned || inProgress || finished => true,
    _ => false,
  };

  /// Posição na linha `assigned → in_progress → finished`; `-1` fora dela.
  int get progressStep => switch (this) {
    assigned => 0,
    inProgress => 1,
    finished => 2,
    _ => -1,
  };
}

enum UrgencyType { now, scheduled }

double? _toDoubleOrNull(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Prestador associado ao pedido (`provider_profiles` + `users`).
class ServiceProvider {
  const ServiceProvider({
    required this.profileId,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.rating,
    this.totalRatings = 0,
  });

  final String profileId;
  final String userId;
  final String name;
  final String? avatarUrl;
  final double? rating;
  final int totalRatings;

  static ServiceProvider? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final user = json['users'] as Map<String, dynamic>?;
    return ServiceProvider(
      profileId: json['id'] as String,
      userId: json['user_id'] as String,
      name: (user?['full_name'] as String?) ?? 'Prestador',
      avatarUrl: user?['avatar_url'] as String?,
      rating: _toDoubleOrNull(json['average_rating']),
      totalRatings: (json['total_ratings'] as num?)?.toInt() ?? 0,
    );
  }
}

class ServiceRequest {
  final String id;
  final String? categoryId;
  final String? categorySlug;
  final String categoryName;
  final String? freeformProfession;
  final String problem;
  final String details;
  final List<String> mediaPaths;
  final String? address;
  final UrgencyType urgency;
  final DateTime? scheduledDate;
  final ServiceRequestStatus status;
  final DateTime createdAt;
  final double? finalPrice;
  final ServiceProvider? provider;

  const ServiceRequest({
    required this.id,
    this.categoryId,
    this.categorySlug,
    required this.categoryName,
    this.freeformProfession,
    required this.problem,
    required this.details,
    required this.mediaPaths,
    this.address,
    required this.urgency,
    this.scheduledDate,
    required this.status,
    required this.createdAt,
    this.finalPrice,
    this.provider,
  });

  Map<String, dynamic> toInsertJson({required String clientId}) {
    return {
      'client_id': clientId,
      if (categoryId != null) 'service_category_id': categoryId,
      if (freeformProfession != null) 'freeform_profession': freeformProfession,
      'description': '$problem\n\n$details',
      'service_date': (scheduledDate ?? DateTime.now()).toIso8601String(),
      if (address != null) 'observations': address,
    };
  }

  /// Colunas a pedir ao PostgREST: pedido + categoria + prestador (com perfil).
  static const String selectColumns =
      '*, service_categories(name, slug), '
      'provider_profiles(id, user_id, average_rating, total_ratings, '
      'users(full_name, avatar_url))';

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final description = json['description'] as String? ?? '';
    final parts = description.split('\n\n');
    final problem = parts.isNotEmpty ? parts.first : description;
    final details = parts.length > 1 ? parts.sublist(1).join('\n\n') : '';
    final categoryData = json['service_categories'] as Map<String, dynamic>?;

    return ServiceRequest(
      id: json['id'] as String,
      categoryId: json['service_category_id'] as String?,
      categorySlug: categoryData?['slug'] as String?,
      categoryName: categoryData?['name'] as String? ?? '',
      freeformProfession: json['freeform_profession'] as String?,
      problem: problem,
      details: details,
      mediaPaths: const [],
      address: json['observations'] as String?,
      urgency: json['service_date'] != null
          ? UrgencyType.scheduled
          : UrgencyType.now,
      scheduledDate: json['service_date'] != null
          ? DateTime.tryParse(json['service_date'] as String)
          : null,
      status: ServiceRequestStatus.fromDb(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      finalPrice: _toDoubleOrNull(json['final_price']),
      provider: ServiceProvider.fromJson(
        json['provider_profiles'] as Map<String, dynamic>?,
      ),
    );
  }
}
