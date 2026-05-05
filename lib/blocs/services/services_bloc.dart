import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../repositories/services_repository.dart';
import '../../utils/api_failure.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class ServicesEvent extends Equatable {
  const ServicesEvent();
  @override
  List<Object?> get props => [];
}

class ServicesLoadEvent extends ServicesEvent {
  final String? category;
  final String? search;
  const ServicesLoadEvent({this.category, this.search});
  @override
  List<Object?> get props => [category, search];
}

class ServicesLoadMoreEvent extends ServicesEvent {
  const ServicesLoadMoreEvent();
}

class ServiceDetailLoadEvent extends ServicesEvent {
  final String serviceId;
  const ServiceDetailLoadEvent(this.serviceId);
  @override
  List<Object?> get props => [serviceId];
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class ServicesState extends Equatable {
  const ServicesState();
  @override
  List<Object?> get props => [];
}

class ServicesInitialState extends ServicesState {
  const ServicesInitialState();
}

class ServicesLoadingState extends ServicesState {
  const ServicesLoadingState();
}

class ServicesLoadedState extends ServicesState {
  final List<ServiceModel> services;
  final int currentPage;
  final bool hasMore;
  final String? category;
  final String? search;

  const ServicesLoadedState({
    required this.services,
    required this.currentPage,
    required this.hasMore,
    this.category,
    this.search,
  });

  @override
  List<Object?> get props => [services, currentPage, hasMore, category, search];
}

class ServicesLoadingMoreState extends ServicesLoadedState {
  const ServicesLoadingMoreState({
    required super.services,
    required super.currentPage,
    required super.hasMore,
    super.category,
    super.search,
  });
}

class ServicesErrorState extends ServicesState {
  final String message;
  const ServicesErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

class ServiceDetailLoadingState extends ServicesState {
  const ServiceDetailLoadingState();
}

class ServiceDetailLoadedState extends ServicesState {
  final ServiceModel service;
  const ServiceDetailLoadedState(this.service);
  @override
  List<Object?> get props => [service];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServicesRepository _repository;

  ServicesBloc({required ServicesRepository repository})
      : _repository = repository,
        super(const ServicesInitialState()) {
    on<ServicesLoadEvent>(_onLoad);
    on<ServicesLoadMoreEvent>(_onLoadMore);
    on<ServiceDetailLoadEvent>(_onDetailLoad);
  }

  Future<void> _onLoad(
      ServicesLoadEvent event, Emitter<ServicesState> emit) async {
    emit(const ServicesLoadingState());
    try {
      final result = await _repository.listServices(
        page: 1,
        category: event.category,
        search: event.search,
      );
      emit(ServicesLoadedState(
        services: result.data,
        currentPage: 1,
        hasMore: result.hasMore,
        category: event.category,
        search: event.search,
      ));
    } on ApiFailure catch (e) {
      emit(ServicesErrorState(e.message));
    }
  }

  Future<void> _onLoadMore(
      ServicesLoadMoreEvent event, Emitter<ServicesState> emit) async {
    final current = state;
    if (current is! ServicesLoadedState || !current.hasMore) return;

    emit(ServicesLoadingMoreState(
      services: current.services,
      currentPage: current.currentPage,
      hasMore: current.hasMore,
      category: current.category,
      search: current.search,
    ));

    try {
      final result = await _repository.listServices(
        page: current.currentPage + 1,
        category: current.category,
        search: current.search,
      );
      emit(ServicesLoadedState(
        services: [...current.services, ...result.data],
        currentPage: current.currentPage + 1,
        hasMore: result.hasMore,
        category: current.category,
        search: current.search,
      ));
    } on ApiFailure catch (e) {
      emit(ServicesErrorState(e.message));
    }
  }

  Future<void> _onDetailLoad(
      ServiceDetailLoadEvent event, Emitter<ServicesState> emit) async {
    emit(const ServiceDetailLoadingState());
    try {
      final service = await _repository.getService(event.serviceId);
      emit(ServiceDetailLoadedState(service));
    } on ApiFailure catch (e) {
      emit(ServicesErrorState(e.message));
    }
  }
}
