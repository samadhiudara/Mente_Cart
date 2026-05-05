import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticatedState) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = state.user;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Avatar
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(user.email,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              // Menu items
              _ProfileMenuItem(
                icon: Icons.receipt_long_outlined,
                title: 'My Bookings',
                onTap: () {},
              ),
              _ProfileMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {},
              ),
              _ProfileMenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _ProfileMenuItem(
                icon: Icons.logout,
                title: 'Sign Out',
                color: Colors.red,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text(
                          'Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                            context
                                .read<AuthBloc>()
                                .add(const AuthLogoutEvent());
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'MenteCart v1.0.0',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: color)),
      trailing: color == null
          ? const Icon(Icons.chevron_right, color: Colors.grey)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    );
  }
}
