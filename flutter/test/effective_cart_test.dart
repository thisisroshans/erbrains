import 'package:fitring/core/cart_sync/effective_cart.dart';
import 'package:fitring/core/domain/entities/cart.dart';
import 'package:fitring/core/domain/entities/cart_mutation.dart';
import 'package:flutter_test/flutter_test.dart';

/// [applyPendingCartMutations] is pure (no Hive/network), so these tests
/// need no setup/teardown at all — just inputs and outputs.
void main() {
  CartMutation add(String id, {required String productId, required int quantity, String name = 'Widget'}) {
    return CartMutation(
      localId: id,
      type: CartMutationType.add,
      createdAt: DateTime.utc(2026, 1, 1),
      productId: productId,
      productName: name,
      productPrice: 10.0,
      quantity: quantity,
    );
  }

  test('an add mutation for a new product appears as a pending local line item', () {
    final result = applyPendingCartMutations(Cart.empty, [add('m1', productId: 'p1', quantity: 2)]);

    expect(result.items, hasLength(1));
    expect(result.items.single.cartItemId, 'local:m1');
    expect(result.items.single.quantity, 2);
    expect(result.items.single.subtotal, 20.0);
    expect(result.items.single.pendingSync, isTrue);
    expect(result.totalAmount, 20.0);
  });

  test('an add mutation for a product already in the baseline increments quantity, matching the '
      "backend's upsert semantics", () {
    final baseline = Cart(
      items: [
        CartItem(cartItemId: 'server-1', productId: 'p1', name: 'Widget', price: 10.0, quantity: 1, subtotal: 10.0),
      ],
      totalAmount: 10.0,
    );

    final result = applyPendingCartMutations(baseline, [add('m1', productId: 'p1', quantity: 3)]);

    expect(result.items, hasLength(1));
    expect(result.items.single.cartItemId, 'server-1'); // still the real id, not a local placeholder
    expect(result.items.single.quantity, 4);
    expect(result.items.single.subtotal, 40.0);
    expect(result.items.single.pendingSync, isTrue);
  });

  test('setQuantity resolves against a real cart_item_id from the baseline', () {
    final baseline = Cart(
      items: [
        CartItem(cartItemId: 'server-1', productId: 'p1', name: 'Widget', price: 10.0, quantity: 1, subtotal: 10.0),
      ],
      totalAmount: 10.0,
    );
    final mutation = CartMutation(
      localId: 'm1',
      type: CartMutationType.setQuantity,
      createdAt: DateTime.utc(2026, 1, 1),
      cartItemId: 'server-1',
      quantity: 5,
    );

    final result = applyPendingCartMutations(baseline, [mutation]);

    expect(result.items.single.quantity, 5);
    expect(result.items.single.subtotal, 50.0);
    expect(result.items.single.pendingSync, isTrue);
  });

  test('setQuantity resolves against a local: placeholder for an item added in the same queue', () {
    final addMutation = add('m1', productId: 'p1', quantity: 1);
    final setQuantityMutation = CartMutation(
      localId: 'm2',
      type: CartMutationType.setQuantity,
      createdAt: DateTime.utc(2026, 1, 1),
      cartItemId: 'local:m1', // targets the not-yet-synced add above
      quantity: 4,
    );

    final result = applyPendingCartMutations(Cart.empty, [addMutation, setQuantityMutation]);

    expect(result.items, hasLength(1));
    expect(result.items.single.cartItemId, 'local:m1');
    expect(result.items.single.quantity, 4);
  });

  test('remove drops the line item entirely', () {
    final baseline = Cart(
      items: [
        CartItem(cartItemId: 'server-1', productId: 'p1', name: 'Widget', price: 10.0, quantity: 1, subtotal: 10.0),
        CartItem(cartItemId: 'server-2', productId: 'p2', name: 'Gadget', price: 5.0, quantity: 1, subtotal: 5.0),
      ],
      totalAmount: 15.0,
    );
    final mutation = CartMutation(
      localId: 'm1',
      type: CartMutationType.remove,
      createdAt: DateTime.utc(2026, 1, 1),
      cartItemId: 'server-1',
    );

    final result = applyPendingCartMutations(baseline, [mutation]);

    expect(result.items, hasLength(1));
    expect(result.items.single.cartItemId, 'server-2');
    expect(result.totalAmount, 5.0);
  });

  test('placeOrder does not change the displayed line items', () {
    final baseline = Cart(
      items: [
        CartItem(cartItemId: 'server-1', productId: 'p1', name: 'Widget', price: 10.0, quantity: 1, subtotal: 10.0),
      ],
      totalAmount: 10.0,
    );
    final mutation = CartMutation(
      localId: 'm1',
      type: CartMutationType.placeOrder,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final result = applyPendingCartMutations(baseline, [mutation]);

    expect(result.items, hasLength(1));
    expect(result.totalAmount, 10.0);
  });

  test('no pending mutations returns the baseline unchanged (modulo object identity)', () {
    final baseline = Cart(
      items: [
        CartItem(cartItemId: 'server-1', productId: 'p1', name: 'Widget', price: 10.0, quantity: 2, subtotal: 20.0),
      ],
      totalAmount: 20.0,
    );

    final result = applyPendingCartMutations(baseline, []);

    expect(result.items.single.pendingSync, isFalse);
    expect(result.totalAmount, 20.0);
  });
}
