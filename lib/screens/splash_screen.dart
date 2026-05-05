import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../utils/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthCheckStatusEvent());
      }
    });
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && !_navigated) _navigate(AppRouter.login);
    });
  }

  void _navigate(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticatedState) {
          _navigate(AppRouter.home);
        } else if (state is AuthUnauthenticatedState) {
          _navigate(AppRouter.login);
        } else if (state is AuthErrorState) {
          _navigate(AppRouter.login);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF4F46E5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.shopping_cart_rounded,
                    size: 48, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(height: 20),
              const Text('MenteCart',
                  style: TextStyle(color: Colors.white, fontSize: 32,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Service Booking Made Easy',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 60),
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}