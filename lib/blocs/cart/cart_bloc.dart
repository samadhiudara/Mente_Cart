import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../repositories/cart_repository.dart';
import '../../utils/api_failure.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class CartLoadEvent extends CartEvent {
  const CartLoadEvent();
}

class CartAddItemEvent extends CartEvent {
  final String serviceId;
  final String slotDate;
  final String slotTime;
  final int quantity;

  const CartAddItemEvent({
    required this.serviceId,
    required this.slotDate,
    required this.slotTime,
    this.quantity = 1,
  });

  @override
  List<Object?> get props => [serviceId, slotDate, slotTime, quantity];
}

class CartUpdateItemEvent extends CartEvent {
  final String itemId;
  final int? quantity;

  const CartUpdateItemEvent({required this.itemId, this.quantity});
  @override
  List<Object?> get props => [itemId, quantity];
}

class CartRemoveItemEvent extends CartEvent {
  final String itemId;
  const CartRemoveItemEvent(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class CartClearEvent extends CartEvent {
  const CartClearEvent();
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitialState extends CartState {
  const CartInitialState();
}

class CartLoadingState extends CartState {
  const CartLoadingState();
}

class CartLoadedState extends CartState {
  final CartModel cart;
  const CartLoadedState(this.cart);
  @override
  List<Object?> get props => [cart];
}

class CartUpdatingState extends CartLoadedState {
  const CartUpdatingState(super.cart);
}

class CartErrorState extends CartState {
  final String message;
  final CartModel? previousCart;
  const CartErrorState(this.message, {this.previousCart});
  @override
  List<Object?> get props => [message, previousCart];
}

class CartItemAddedState extends CartLoadedState {
  const CartItemAddedState(super.cart);
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _repository;

  CartBloc({required CartRepository repository})
      : _repository = repository,
        super(const CartInitialState()) {
    on<CartLoadEvent>(_onLoad);
    on<CartAddItemEvent>(_onAddItem);
    on<CartUpdateItemEvent>(_onUpdateItem);
    on<CartRemoveItemEvent>(_onRemoveItem);
    on<CartClearEvent>(_onClear);
  }

  Future<void> _onLoad(CartLoadEvent event, Emitter<CartState> emit) async {
    emit(const CartLoadingState());
    try {
      final cart = await _repository.getCart();
      emit(CartLoadedState(cart));
    } on ApiFailure catch (e) {
      emit(CartErrorState(e.message));
    }
  }

  Future<void> _onAddItem(
      CartAddItemEvent event, Emitter<CartState> emit) async {
    final prev = state is CartLoadedState
        ? (state as CartLoadedState).cart
        : null;
    try {
      final cart = await _repository.addItem(
        serviceId: event.serviceId,
        slotDate: event.slotDate,
        slotTime: event.slotTime,
        quantity: event.quantity,
      );
      emit(CartItemAddedState(cart));
    } on ApiFailure catch (e) {
      emit(CartErrorState(e.message, previousCart: prev));
      if (prev != null) emit(CartLoadedState(prev));
    }
  }

  Future<void> _onUpdateItem(
      CartUpdateItemEvent event, Emitter<CartState> emit) async {
    final prev = state is CartLoadedState
        ? (state as CartLoadedState).cart
        : null;
    if (prev != null) emit(CartUpdatingState(prev));
    try {
      final cart = await _repository.updateItem(event.itemId,
          quantity: event.quantity);
      emit(CartLoadedState(cart));
    } on ApiFailure catch (e) {
      emit(CartErrorState(e.message, previousCart: prev));
      if (prev != null) emit(CartLoadedState(prev));
    }
  }

  Future<void> _onRemoveItem(
      CartRemoveItemEvent event, Emitter<CartState> emit) async {
    final prev = state is CartLoadedState
        ? (state as CartLoadedState).cart
        : null;
    if (prev != null) emit(CartUpdatingState(prev));
    try {
      final cart = await _repository.removeItem(event.itemId);
      emit(CartLoadedState(cart));
    } on ApiFailure catch (e) {
      emit(CartErrorState(e.message, previousCart: prev));
      if (prev != null) emit(CartLoadedState(prev));
    }
  }

  Future<void> _onClear(CartClearEvent event, Emitter<CartState> emit) async {
    emit(const CartInitialState());
  }
}
