import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

/// Widget that checks if user has required permissions before rendering child
class PermissionGuard extends StatelessWidget {
  final UserRole? requiredRole;
  final List<UserRole>? allowedRoles;
  final Widget child;
  final Widget? fallback;
  final String? message;

  const PermissionGuard({
    super.key,
    this.requiredRole,
    this.allowedRoles,
    required this.child,
    this.fallback,
    this.message,
  }) : assert(
         requiredRole != null || allowedRoles != null,
         'Either requiredRole or allowedRoles must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.userModel;

        if (user == null) {
          return fallback ?? _buildAccessDenied(context);
        }

        final hasPermission = _checkPermission(user);

        if (hasPermission) {
          return child;
        }

        return fallback ?? _buildAccessDenied(context);
      },
    );
  }

  bool _checkPermission(UserModel user) {
    if (requiredRole != null) {
      return user.role == requiredRole;
    }

    if (allowedRoles != null) {
      return allowedRoles!.contains(user.role);
    }

    return false;
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message ?? 'You do not have permission to access this feature.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mixin for checking permissions in widgets
mixin PermissionCheckerMixin<T extends StatefulWidget> on State<T> {
  bool hasRole(UserRole role) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userModel?.role == role;
  }

  bool hasAnyRole(List<UserRole> roles) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.userModel?.role;
    return userRole != null && roles.contains(userRole);
  }

  bool isAdmin() => hasRole(UserRole.admin);
  bool isCounsellor() => hasRole(UserRole.counsellor);
  bool isUser() => hasRole(UserRole.user);

  void showPermissionDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You do not have permission to perform this action.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
