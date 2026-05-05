import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../repositories/bookings_repository.dart';
import '../../utils/api_failure.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class BookingsEvent extends Equatable {
  const BookingsEvent();
  @override
  List<Object?> get props => [];
}

class BookingsLoadEvent extends BookingsEvent {
  const BookingsLoadEvent();
}

class BookingsCheckoutEvent extends BookingsEvent {
  final String paymentMethod;
  const BookingsCheckoutEvent(this.paymentMethod);
  @override
  List<Object?> get props => [paymentMethod];
}

class BookingsCancelEvent extends BookingsEvent {
  final String bookingId;
  final String? reason;
  const BookingsCancelEvent(this.bookingId, {this.reason});
  @override
  List<Object?> get props => [bookingId, reason];
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class BookingsState extends Equatable {
  const BookingsState();
  @override
  List<Object?> get props => [];
}

class BookingsInitialState extends BookingsState {
  const BookingsInitialState();
}

class BookingsLoadingState extends BookingsState {
  const BookingsLoadingState();
}

class BookingsLoadedState extends BookingsState {
  final List<BookingModel> bookings;
  const BookingsLoadedState(this.bookings);
  @override
  List<Object?> get props => [bookings];
}

class BookingsCheckoutSuccessState extends BookingsState {
  final BookingModel booking;
  const BookingsCheckoutSuccessState(this.booking);
  @override
  List<Object?> get props => [booking];
}

class BookingsCancelledState extends BookingsState {
  final BookingModel booking;
  const BookingsCancelledState(this.booking);
  @override
  List<Object?> get props => [booking];
}

class BookingsErrorState extends BookingsState {
  final String message;
  const BookingsErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class BookingsBloc extends Bloc<BookingsEvent, BookingsState> {
  final BookingsRepository _repository;

  BookingsBloc({required BookingsRepository repository})
      : _repository = repository,
        super(const BookingsInitialState()) {
    on<BookingsLoadEvent>(_onLoad);
    on<BookingsCheckoutEvent>(_onCheckout);
    on<BookingsCancelEvent>(_onCancel);
  }

  Future<void> _onLoad(
      BookingsLoadEvent event, Emitter<BookingsState> emit) async {
    emit(const BookingsLoadingState());
    try {
      final bookings = await _repository.listBookings();
      emit(BookingsLoadedState(bookings));
    } on ApiFailure catch (e) {
      emit(BookingsErrorState(e.message));
    }
  }

  Future<void> _onCheckout(
      BookingsCheckoutEvent event, Emitter<BookingsState> emit) async {
    emit(const BookingsLoadingState());
    try {
      final booking = await _repository.checkout(
          paymentMethod: event.paymentMethod);
      emit(BookingsCheckoutSuccessState(booking));
    } on ApiFailure catch (e) {
      emit(BookingsErrorState(e.message));
    }
  }

  Future<void> _onCancel(
      BookingsCancelEvent event, Emitter<BookingsState> emit) async {
    emit(const BookingsLoadingState());
    try {
      final booking = await _repository.cancelBooking(event.bookingId,
          reason: event.reason);
      emit(BookingsCancelledState(booking));
    } on ApiFailure catch (e) {
      emit(BookingsErrorState(e.message));
    }
  }
}
