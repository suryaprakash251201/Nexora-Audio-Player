import '../../domain/entities/paginated.dart';

class PaginatedResponseDto<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginatedResponseDto({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  Paginated<T> toEntity() => Paginated<T>(
    data: data,
    page: page,
    limit: limit,
    total: total,
    totalPages: totalPages,
    hasNext: hasNext,
    hasPrev: hasPrev,
  );

  /// Flexible parser: handles
  /// {data: [...], pagination: {...}}
  /// {items: [...], total: 100}
  /// [...] // raw list
  static PaginatedResponseDto<U> fromJson<U>(
    dynamic json,
    U Function(Map<String, dynamic>) mapper, {
    int fallbackPage = 1,
    int fallbackLimit = 20,
  }) {
    if (json is List) {
      final items = json.whereType<Map<String, dynamic>>().map(mapper).toList();
      return PaginatedResponseDto<U>(
        data: items,
        page: 1,
        limit: items.length,
        total: items.length,
        totalPages: 1,
        hasNext: false,
        hasPrev: false,
      );
    }
    if (json is Map<String, dynamic>) {
      // Unwrap success envelope
      final payload =
          json['data'] is Map &&
              json['pagination'] == null &&
              json['data'] is List
          ? json['data']
          : json;
      // Check variations
      List<dynamic>? rawList;
      Map<String, dynamic>? pagination;

      if (json['data'] is List) {
        rawList = json['data'] as List;
        pagination = json['pagination'] as Map<String, dynamic>?;
        if (pagination == null && json['meta'] is Map)
          pagination = json['meta'] as Map<String, dynamic>;
      } else if (json['items'] is List) {
        rawList = json['items'] as List;
        pagination = json['pagination'] as Map<String, dynamic>?;
      } else if (json['results'] is List) {
        rawList = json['results'] as List;
      } else if (json['data'] is Map && json['data']['items'] is List) {
        rawList = (json['data']['items'] as List);
        pagination = (json['data']['pagination'] as Map<String, dynamic>?);
      }

      if (rawList != null) {
        final items = rawList
            .whereType<Map<String, dynamic>>()
            .map(mapper)
            .toList();
        final page =
            (pagination?['page'] ?? pagination?['currentPage'] ?? 1) is int
            ? pagination!['page'] as int
            : int.tryParse((pagination?['page'] ?? '1').toString()) ?? 1;
        final limit = (pagination?['limit'] ?? fallbackLimit) is int
            ? pagination!['limit'] as int
            : int.tryParse(
                    (pagination?['limit'] ?? '$fallbackLimit').toString(),
                  ) ??
                  fallbackLimit;
        final total = (pagination?['total'] ?? items.length) is int
            ? pagination!['total'] as int
            : int.tryParse(
                    (pagination?['total'] ?? '${items.length}').toString(),
                  ) ??
                  items.length;
        final totalPages =
            (pagination?['totalPages'] ??
                    pagination?['pages'] ??
                    (total / limit).ceil())
                is int
            ? pagination!['totalPages'] as int
            : int.tryParse((pagination?['totalPages'] ?? '1').toString()) ?? 1;
        final hasNext = pagination?['hasNext'] as bool? ?? (page < totalPages);
        final hasPrev = pagination?['hasPrev'] as bool? ?? (page > 1);

        // Also handle offset/limit style: hasNext via total > offset+limit
        return PaginatedResponseDto<U>(
          data: items,
          page: page,
          limit: limit,
          total: total,
          totalPages: totalPages,
          hasNext: hasNext,
          hasPrev: hasPrev,
        );
      }

      // Fallback: maybe json itself is wrapped {success:true, data:[...]}
      if (json['success'] == true && json['data'] is List) {
        final items = (json['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(mapper)
            .toList();
        return PaginatedResponseDto<U>(
          data: items,
          page: 1,
          limit: items.length,
          total: items.length,
          totalPages: 1,
          hasNext: false,
          hasPrev: false,
        );
      }
    }
    // Empty
    return PaginatedResponseDto<U>(
      data: [],
      page: fallbackPage,
      limit: fallbackLimit,
      total: 0,
      totalPages: 0,
      hasNext: false,
      hasPrev: false,
    );
  }
}
