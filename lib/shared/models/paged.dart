/// Cursor-based page of results. Cursor pagination works for both REST
/// (`?before=<cursor>`) and realtime backends, unlike offset pagination which
/// breaks when new items arrive.
class Paged<T> {
  const Paged({required this.items, this.nextCursor});

  const Paged.empty() : items = const [], nextCursor = null;

  final List<T> items;

  /// Opaque cursor for the next (older) page; null when there is no more.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
