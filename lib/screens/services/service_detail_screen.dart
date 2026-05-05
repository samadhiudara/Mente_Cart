import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/services/services_bloc.dart';
import '../../models/models.dart';
import '../../repositories/services_repository.dart';
import '../../utils/app_router.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceModel service;
  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  late ServicesBloc _servicesBloc;
  ServiceModel? _fullService;
  TimeSlotModel? _selectedSlot;
  String? _selectedDate;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _servicesBloc = ServicesBloc(
        repository: context.read<ServicesRepository>());
    // Load full service with slots
    _servicesBloc.add(ServiceDetailLoadEvent(widget.service.id));
  }

  @override
  void dispose() {
    _servicesBloc.close();
    super.dispose();
  }

  ServiceModel get _service => _fullService ?? widget.service;

  List<String> get _availableDates {
    final dates = _service.slots
        .where((s) => !s.isFull)
        .map((s) => s.date)
        .toSet()
        .toList();
    dates.sort();
    return dates;
  }

  List<TimeSlotModel> get _slotsForDate {
    if (_selectedDate == null) return [];
    return _service.slots
        .where((s) => s.date == _selectedDate && !s.isFull)
        .toList();
  }

  void _addToCart() {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time slot')),
      );
      return;
    }
    context.read<CartBloc>().add(CartAddItemEvent(
      serviceId: _service.id,
      slotDate: _selectedSlot!.date,
      slotTime: _selectedSlot!.time,
      quantity: _quantity,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _servicesBloc,
      child: Scaffold(
        body: BlocListener<CartBloc, CartState>(
          listener: (context, state) {
            if (state is CartItemAddedState) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Added to cart!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (state is CartErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          child: BlocListener<ServicesBloc, ServicesState>(
            listener: (context, state) {
              if (state is ServiceDetailLoadedState) {
                setState(() {
                  _fullService = state.service;
                });
              }
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _service.image.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: _service.image,
                      fit: BoxFit.cover,
                    )
                        : Container(color: Colors.grey[300]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: BlocBuilder<ServicesBloc, ServicesState>(
                    builder: (context, state) {
                      final isLoading = state is ServiceDetailLoadingState;
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Chip(label: Text(_service.category), padding: EdgeInsets.zero),
                            const SizedBox(height: 8),
                            Text(_service.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.attach_money,
                                    color: Theme.of(context).colorScheme.primary),
                                Text(
                                  _service.price.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.timer_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${_service.duration} min',
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('About this service',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(_service.description,
                                style: TextStyle(
                                    color: Colors.grey[700], height: 1.5)),
                            const SizedBox(height: 24),
                            Text('Select Date',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            // Loading indicator for slots
                            if (isLoading)
                              const Center(child: CircularProgressIndicator())
                            else if (_availableDates.isEmpty)
                              const Text('No available slots',
                                  style: TextStyle(color: Colors.grey))
                            else
                              SizedBox(
                                height: 56,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _availableDates.length,
                                  itemBuilder: (_, i) {
                                    final date = _availableDates[i];
                                    final parsed = DateTime.parse(date);
                                    final selected = _selectedDate == date;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _selectedDate = date;
                                          _selectedSlot = null;
                                        }),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: selected
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                DateFormat('MMM d').format(parsed),
                                                style: TextStyle(
                                                  color: selected ? Colors.white : Colors.black,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                DateFormat('EEE').format(parsed),
                                                style: TextStyle(
                                                  color: selected ? Colors.white70 : Colors.grey,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 20),
                            if (_selectedDate != null && !isLoading) ...[
                              Text('Select Time',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _slotsForDate.map((slot) {
                                  final selected = _selectedSlot?.id == slot.id;
                                  return ChoiceChip(
                                    label: Text(slot.time),
                                    selected: selected,
                                    onSelected: (_) =>
                                        setState(() => _selectedSlot = slot),
                                    selectedColor:
                                    Theme.of(context).colorScheme.primary,
                                    labelStyle: TextStyle(
                                      color: selected ? Colors.white : null,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (_selectedSlot != null) ...[
                              Text('Quantity',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  IconButton.outlined(
                                    onPressed: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('$_quantity',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  IconButton.outlined(
                                    onPressed: _quantity < _selectedSlot!.available
                                        ? () => setState(() => _quantity++)
                                        : null,
                                    icon: const Icon(Icons.add),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_selectedSlot!.available} spots left',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                            const SizedBox(height: 80),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                final loading = state is CartUpdatingState;
                return FilledButton.icon(
                  onPressed: loading ? null : _addToCart,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: loading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : Text(
                    _selectedSlot == null
                        ? 'Select a Slot'
                        : 'Add to Cart — \$${(_service.price * _quantity).toStringAsFixed(2)}',
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}