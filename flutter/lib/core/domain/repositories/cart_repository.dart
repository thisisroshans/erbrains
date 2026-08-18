import '../entities/cart.dart';

/// Read-only by design: cart *writes* go through the offline queue
/// (`core/cart_sync/`), not this repository — see CartController and
/// docs/ARCHITECTURE.md's "Deliberate departures" note on why the reading
/// sync engine similarly bypasses a repository abstraction for writes.
abstract class CartRepository {
  Future<Cart> get(String userId);
}
