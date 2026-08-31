class Paginated<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const Paginated({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Paginated.empty() => const Paginated(data: [], page: 1, limit: 20, total: 0, totalPages: 0, hasNext: false, hasPrev: false);

  factory Paginated.singlePage(List<T> items) => Paginated(
        data: items,
        page: 1,
        limit: items.length,
        total: items.length,
        totalPages: 1,
        hasNext: false,
        hasPrev: false,
      );
}
