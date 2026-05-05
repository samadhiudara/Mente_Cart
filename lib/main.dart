import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/cart/cart_bloc.dart';
import 'repositories/auth_repository.dart';
import 'repositories/services_repository.dart';
import 'repositories/cart_repository.dart';
import 'repositories/bookings_repository.dart';
import 'services/api_client.dart';
import 'services/token_storage.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_router.dart';

void main() {
  runApp(const MenteCartApp());
}

class MenteCartApp extends StatelessWidget {
  const MenteCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    // DI setup (simple manual DI for clarity)
    const storage = FlutterSecureStorage();
    final tokenStorage = TokenStorage(storage);
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    final authRepo = AuthRepository(apiClient: apiClient);
    final servicesRepo = ServicesRepository(apiClient: apiClient);
    final cartRepo = CartRepository(apiClient: apiClient);
    final bookingsRepo = BookingsRepository(apiClient: apiClient);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepo),
        RepositoryProvider.value(value: servicesRepo),
        RepositoryProvider.value(value: cartRepo),
        RepositoryProvider.value(value: bookingsRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(authRepository: authRepo)
              ..add(const AuthCheckStatusEvent()),
          ),
          BlocProvider(
            create: (_) => CartBloc(repository: cartRepo),
          ),
        ],
        child: MaterialApp(
          title: 'MenteCart',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

