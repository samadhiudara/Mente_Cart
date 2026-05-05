import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../models/models.dart';
import '../../utils/app_router.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(const CartLoadEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CartLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CartLoadedState ||
              state is CartUpdatingState ||
              state is CartItemAddedState) {
            final cart = (state as CartLoadedState).cart;
            if (cart.items.isEmpty) {
              return _EmptyCart();
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _CartItemCard(
                      item: cart.items[i],
                      isUpdating: state is CartUpdatingState,
                    ),
                  ),
                ),
                _CartSummary(cart: cart),
              ],
            );
          }

          return _EmptyCart();
        },
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final bool isUpdating;

  const _CartItemCard({required this.item, required this.isUpdating});

  @override
  Widget build(BuildContext context) {
    final expiry = item.expiresAt.difference(DateTime.now());
    final expiryMinutes = expiry.inMinutes;
    final isExpiringSoon = expiryMinutes < 5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.serviceImage != null && item.serviceImage!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.serviceImage!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey[200],
                      child: const Icon(Icons.home_repair_service, size: 32),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.serviceTitle ?? 'Service',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${item.slotDate} at ${item.slotTime}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (isExpiringSoon)
                    Row(
                      children: [
                        const Icon(Icons.timer,
                            size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Expires in $expiryMinutes min',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.orange),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Quantity controls
                      _QuantityButton(
                        icon: Icons.remove,
                        onTap: item.quantity > 1
                            ? () => context.read<CartBloc>().add(
                                  CartUpdateItemEvent(
                                    itemId: item.id,
                                    quantity: item.quantity - 1,
                                  ),
                                )
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      _QuantityButton(
                        icon: Icons.add,
                        onTap: () => context.read<CartBloc>().add(
                              CartUpdateItemEvent(
                                itemId: item.id,
                                quantity: item.quantity + 1,
                              ),
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Remove button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: isUpdating
                  ? null
                  : () => context
                      .read<CartBloc>()
                      .add(CartRemoveItemEvent(item.id)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: onTap == null ? Colors.grey[100] : Colors.white,
        ),
        child: Icon(icon, size: 16,
            color: onTap == null ? Colors.grey : Colors.black),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartModel cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${cart.itemCount} item(s)',
                    style: const TextStyle(color: Colors.grey)),
                Text(
                  'Total: \$${cart.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.checkout),
                icon: const Icon(Icons.payment),
                label: const Text('Proceed to Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Your cart is empty',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Add some services to get started',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse Services'),
          ),
        ],
      ),
    );
  }
}
