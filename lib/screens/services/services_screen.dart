import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/services/services_bloc.dart';
import '../../models/models.dart';
import '../../repositories/services_repository.dart';
import '../../utils/app_router.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late ServicesBloc _bloc;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _bloc = ServicesBloc(
        repository: context.read<ServicesRepository>())
      ..add(const ServicesLoadEvent());
    _loadCategories();
    _scrollCtrl.addListener(_onScroll);
  }

  Future<void> _loadCategories() async {
    try {
      final cats =
      await context.read<ServicesRepository>().getCategories();
      if (mounted) setState(() => _categories = ['All', ...cats]);
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _bloc.add(const ServicesLoadMoreEvent());
    }
  }

  void _applyFilter(String? category) {
    setState(() => _selectedCategory = category == 'All' ? null : category);
    _bloc.add(ServicesLoadEvent(
      category: category == 'All' ? null : category,
      search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
    ));
  }

  void _onSearch(String value) {
    _bloc.add(ServicesLoadEvent(
      category: _selectedCategory,
      search: value.isEmpty ? null : value,
    ));
  }

  @override
  void dispose() {
    _bloc.close();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Services'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => showSearch(
                  context: context,
                  delegate: _ServiceSearchDelegate(_bloc)),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_categories.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final selected =
                        (cat == 'All' && _selectedCategory == null) ||
                            cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) => _applyFilter(cat),
                      ),
                    );
                  },
                ),
              ),
            Expanded(
              child: BlocBuilder<ServicesBloc, ServicesState>(
                builder: (context, state) {
                  if (state is ServicesLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ServicesErrorState) {
                    return _ErrorView(
                        message: state.message,
                        onRetry: () => _bloc.add(const ServicesLoadEvent()));
                  }
                  if (state is ServicesLoadedState ||
                      state is ServicesLoadingMoreState) {
                    final loaded = state as ServicesLoadedState;
                    if (loaded.services.isEmpty) {
                      return const Center(
                          child: Text('No services found'));
                    }
                    return GridView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: loaded.services.length +
                          (state is ServicesLoadingMoreState ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == loaded.services.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return _ServiceCard(service: loaded.services[i]);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.serviceDetail,
          arguments: service),
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: service.image.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: service.image,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                        child: CircularProgressIndicator())),
                errorWidget: (_, __, ___) =>
                    Container(color: Colors.grey[200],
                        child: const Icon(Icons.home_repair_service, size: 40)),
              )
                  : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.home_repair_service, size: 40)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.category,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${service.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ServiceSearchDelegate extends SearchDelegate<String> {
  final ServicesBloc _bloc;
  _ServiceSearchDelegate(this._bloc);

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          _bloc.add(const ServicesLoadEvent());
        })
  ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    _bloc.add(ServicesLoadEvent(search: query));
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<ServicesBloc, ServicesState>(
        builder: (_, state) {
          if (state is ServicesLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ServicesLoadedState) {
            return ListView.builder(
              itemCount: state.services.length,
              itemBuilder: (_, i) {
                final s = state.services[i];
                return ListTile(
                  title: Text(s.title),
                  subtitle: Text('\$${s.price.toStringAsFixed(2)}'),
                  onTap: () {
                    close(context, s.id);
                    Navigator.pushNamed(context, AppRouter.serviceDetail,
                        arguments: s);
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
