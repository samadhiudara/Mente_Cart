import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/bookings/bookings_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../models/models.dart';
import '../../repositories/bookings_repository.dart';
import '../../utils/app_router.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'cash';
  late BookingsBloc _bookingsBloc;

  @override
  void initState() {
    super.initState();
    _bookingsBloc =
        BookingsBloc(repository: context.read<BookingsRepository>());
  }

  @override
  void dispose() {
    _bookingsBloc.close();
    super.dispose();
  }

  void _placeOrder() {
    _bookingsBloc.add(BookingsCheckoutEvent(_paymentMethod));
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartBloc>().state;
    CartModel? cart;
    if (cartState is CartLoadedState) cart = cartState.cart;

    return BlocProvider.value(
      value: _bookingsBloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: BlocListener<BookingsBloc, BookingsState>(
          listener: (context, state) {
            if (state is BookingsCheckoutSuccessState) {
              // Clear the cart in UI
              context.read<CartBloc>().add(const CartClearEvent());
              // Navigate to booking detail
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.bookingDetail,
                (route) => route.settings.name == AppRouter.home,
                arguments: state.booking,
              );
            } else if (state is BookingsErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order summary
                Text('Order Summary',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                if (cart != null) ...[
                  ...cart.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OrderItemRow(item: item),
                    ),
                  ),
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18)),
                      Text(
                        '\$${cart.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                // Payment method
                Text('Payment Method',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                _PaymentOption(
                  value: 'cash',
                  groupValue: _paymentMethod,
                  icon: Icons.payments_outlined,
                  title: 'Cash on Arrival',
                  subtitle: 'Pay when the service is delivered',
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 10),
                _PaymentOption(
                  value: 'pay_on_arrival',
                  groupValue: _paymentMethod,
                  icon: Icons.credit_card_outlined,
                  title: 'Card on Arrival',
                  subtitle: 'Pay by card when service is delivered',
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 10),
                _PaymentOption(
                  value: 'payhere',
                  groupValue: _paymentMethod,
                  icon: Icons.language,
                  title: 'PayHere (Online)',
                  subtitle: 'Pay securely online via PayHere',
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 32),
                // Cancellation policy note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Free cancellation within 24 hours of booking.',
                          style: TextStyle(
                              color: Colors.amber[900], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocBuilder<BookingsBloc, BookingsState>(
              builder: (context, state) {
                final loading = state is BookingsLoadingState;
                return FilledButton.icon(
                  onPressed: (loading || cart == null || cart.items.isEmpty)
                      ? null
                      : _placeOrder,
                  icon: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(loading ? 'Placing Order...' : 'Place Order'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final CartItemModel item;
  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.serviceTitle ?? 'Service',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${item.slotDate} at ${item.slotTime} × ${item.quantity}',
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Text(
          '\$${item.subtotal.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
