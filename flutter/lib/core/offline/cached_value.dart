import 'cache_policy.dart';

/// A cached value plus when it was fetched, so [CachePolicy] can decide
/// whether it's still good, stale-but-usable, or expired.
class CachedValue<T> {
  const CachedValue({required this.value, required this.cachedAt});

  final T value;
  final DateTime cachedAt;

  Duration age(DateTime now) => now.difference(cachedAt);

  bool isFresh(CachePolicy policy, {DateTime? now}) =>
      age(now ?? DateTime.now()) <= policy.ttl;

  bool isUsable(CachePolicy policy, {DateTime? now}) =>
      age(now ?? DateTime.now()) <= policy.ttl + policy.grace;
}
