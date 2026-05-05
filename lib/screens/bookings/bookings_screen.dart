import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/bookings/bookings_bloc.dart';
import '../../models/models.dart';
import '../../repositories/bookings_repository.dart';
import '../../utils/app_router.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late BookingsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = BookingsBloc(repository: context.read<BookingsRepository>())
      ..add(const BookingsLoadEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _bloc.add(const BookingsLoadEvent()),
            ),
          ],
        ),
        body: BlocBuilder<BookingsBloc, BookingsState>(
          builder: (context, state) {
            if (state is BookingsLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is BookingsErrorState) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _bloc.add(const BookingsLoadEvent()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is BookingsLoadedState) {
              if (state.bookings.isEmpty) {
                return _EmptyBookings();
              }
              return RefreshIndicator(
                onRefresh: () async => _bloc.add(const BookingsLoadEvent()),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _BookingCard(booking: state.bookings[i]),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'failed':
        return Colors.red[900]!;
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
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.bookingDetail,
          arguments: booking),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.items.isNotEmpty
                          ? booking.items.first.serviceTitle
                          : 'Booking',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(booking.status),
                            size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          booking.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (booking.items.length > 1)
                Text(
                  '+${booking.items.length - 1} more service(s)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              const SizedBox(height: 8),
              // Slot info
              if (booking.items.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${booking.items.first.slotDate} at ${booking.items.first.slotTime}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    booking.paymentMethod
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, y')
                        .format(booking.createdAt.toLocal()),
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    '\$${booking.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No bookings yet',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Book a service to get started',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
