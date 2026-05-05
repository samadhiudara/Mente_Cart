import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/services/service_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/bookings/bookings_screen.dart';
import '../screens/bookings/booking_detail_screen.dart';
import '../screens/bookings/checkout_screen.dart';
import '../models/models.dart';

class AppRouter {
  static const home = '/home';
  static const login = '/login';
  static const signup = '/signup';
  static const serviceDetail = '/services/detail';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const bookings = '/bookings';
  static const bookingDetail = '/bookings/detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _slide(const HomeScreen());
      case login:
        return _slide(const LoginScreen());
      case signup:
        return _slide(const SignupScreen());
      case serviceDetail:
        final service = settings.arguments as ServiceModel;
        return _slide(ServiceDetailScreen(service: service));
      case cart:
        return _slide(const CartScreen());
      case checkout:
        return _slide(const CheckoutScreen());
      case bookings:
        return _slide(const BookingsScreen());
      case bookingDetail:
        final booking = settings.arguments as BookingModel;
        return _slide(BookingDetailScreen(booking: booking));
      default:
        return _slide(const HomeScreen());
    }
  }

  static MaterialPageRoute _slide(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
