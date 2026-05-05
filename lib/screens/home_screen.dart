import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/cart/cart_bloc.dart';
import '../utils/app_router.dart';
import 'services/services_screen.dart';
import 'bookings/bookings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(const CartLoadEvent());
  }

  final _screens = const [
    ServicesScreen(),
    BookingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticatedState) {
          Navigator.pushReplacementNamed(context, AppRouter.login);
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Services',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Bookings',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
        floatingActionButton: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            int count = 0;
            if (state is CartLoadedState) count = state.cart.itemCount;
            return FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.cart),
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              label: const Text('Cart'),
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            );
          },
        ),
      ),
    );
  }
}
