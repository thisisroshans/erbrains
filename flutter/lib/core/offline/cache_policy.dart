/// How a cached resource should be read. Per-resource, not global — a
/// near-static catalog and a fast-changing summary don't belong to the
/// same policy.
enum CacheStrategy {
  /// Return the cache immediately if it exists and isn't expired; only hit
  /// the network on a cold cache or after the TTL+grace window passes.
  cacheFirst,

  /// Return the cache immediately if present (even if stale), and kick off
  /// a background refresh whenever it's past [CachePolicy.ttl] — the UI
  /// sees the old value first, then the fresh one when the refresh lands.
  staleWhileRevalidate,
}

class CachePolicy {
  const CachePolicy({
    required this.strategy,
    required this.ttl,
    this.grace = Duration.zero,
  });

  final CacheStrategy strategy;

  /// Past this age, [staleWhileRevalidate] triggers a background refresh;
  /// [cacheFirst] just treats the value as still good until [ttl] + [grace].
  final Duration ttl;

  /// Extra time past [ttl] during which a value already in hand is still
  /// preferred over showing nothing/an error — e.g. offline with no
  /// network to refresh from. Read-time only, not a background job.
  final Duration grace;

  static const productsCatalog = CachePolicy(
    strategy: CacheStrategy.cacheFirst,
    ttl: Duration(hours: 24),
    grace: Duration(days: 7),
  );
}
