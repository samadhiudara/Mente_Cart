import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/bookings/bookings_bloc.dart';
import '../../models/models.dart';
import '../../repositories/bookings_repository.dart';
import '../../utils/app_router.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late BookingsBloc _bloc;
  late BookingModel _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _bloc = BookingsBloc(repository: context.read<BookingsRepository>());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _cancelBooking() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
            'Are you sure you want to cancel this booking? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(BookingsCancelEvent(_booking.id,
                  reason: 'Cancelled by user'));
            },
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      case 'failed':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking Details'),
          // Back button — goes to previous screen
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          // Home button — clears stack and goes to home
          actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Go to Home',
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(
                  AppRouter.home, (r) => false),
            ),
          ],
        ),
        body: BlocListener<BookingsBloc, BookingsState>(
          listener: (context, state) {
            if (state is BookingsCancelledState) {
              setState(() => _booking = state.booking);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled successfully'),
                  backgroundColor: Colors.green,
                ),
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
                // Status banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _statusColor(_booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _statusColor(_booking.status).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _statusIcon(_booking.status),
                        size: 56,
                        color: _statusColor(_booking.status),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _booking.status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(_booking.status),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_booking.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Booked Services
                _SectionTitle('Booked Services'),
                const SizedBox(height: 12),
                ..._booking.items.map((item) => _BookingItemRow(item: item)),
                const SizedBox(height: 24),

                // Payment Info
                _SectionTitle('Payment Info'),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Method',
                  value: _booking.paymentMethod
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                ),
                _InfoRow(
                  label: 'Status',
                  value: _booking.paymentStatus.toUpperCase(),
                ),
                const SizedBox(height: 24),

                // Booking Info
                _SectionTitle('Booking Info'),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Booking ID',
                  value: _booking.id
                      .substring(_booking.id.length - 8)
                      .toUpperCase(),
                ),
                _InfoRow(
                  label: 'Booked On',
                  value: DateFormat('MMM d, y h:mm a')
                      .format(_booking.createdAt.toLocal()),
                ),
                _InfoRow(
                  label: 'Cancel By',
                  value: DateFormat('MMM d, y h:mm a')
                      .format(_booking.cancelCutoff.toLocal()),
                ),
                const SizedBox(height: 24),

                // Back to Home button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil(
                        AppRouter.home, (r) => false),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Back to Home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _booking.canCancel
            ? SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocBuilder<BookingsBloc, BookingsState>(
              builder: (context, state) {
                final loading = state is BookingsLoadingState;
                return OutlinedButton.icon(
                  onPressed: loading ? null : _cancelBooking,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: loading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.red),
                  )
                      : const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel This Booking'),
                );
              },
            ),
          ),
        )
            : null,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _BookingItemRow extends StatelessWidget {
  final BookingItemModel item;
  const _BookingItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.home_repair_service_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.serviceTitle,
                      style:
                      const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${item.slotDate} at ${item.slotTime}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                  if (item.quantity > 1)
                    Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
            Text(
              '\$${(item.price * item.quantity).toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}