class PaginationMeta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;

  PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return PaginationMeta(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
      hasNextPage: json['hasNextPage'] ?? false,
    );
  }
}

/// Wraps a list response from the backend: { data: [...], meta: {...} }
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta meta;

  PaginatedResponse({required this.items, required this.meta});

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawList = json['data'] as List? ?? [];
    return PaginatedResponse(
      items: rawList.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      meta: PaginationMeta.fromJson(json['meta']),
    );
  }
}
