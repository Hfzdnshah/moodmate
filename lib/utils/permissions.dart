import '../models/user_model.dart';

/// Helper class for checking user permissions and roles
class Permissions {
  /// Check if user has admin role
  static bool isAdmin(UserModel? user) {
    return user?.role == UserRole.admin;
  }

  /// Check if user has counsellor role
  static bool isCounsellor(UserModel? user) {
    return user?.role == UserRole.counsellor;
  }

  /// Check if user has regular user role
  static bool isUser(UserModel? user) {
    return user?.role == UserRole.user;
  }

  /// Check if user has permission to view mood entries
  static bool canViewMoodEntries(UserModel? user) {
    return user != null; // All authenticated users can view their own
  }

  /// Check if user has permission to create mood entries
  static bool canCreateMoodEntry(UserModel? user) {
    return user != null && user.role == UserRole.user;
  }

  /// Check if user has permission to manage clients
  static bool canManageClients(UserModel? user) {
    return isCounsellor(user) || isAdmin(user);
  }

  /// Check if user has permission to send messages
  static bool canSendMessages(UserModel? user) {
    return user != null; // All authenticated users can send messages
  }

  /// Check if user has permission to view analytics
  static bool canViewAnalytics(UserModel? user) {
    return user != null; // All users can view their own analytics
  }

  /// Check if user has permission to manage users
  static bool canManageUsers(UserModel? user) {
    return isAdmin(user);
  }

  /// Check if user has permission to access admin panel
  static bool canAccessAdminPanel(UserModel? user) {
    return isAdmin(user);
  }

  /// Check if user has permission to view all mood entries
  static bool canViewAllMoodEntries(UserModel? user) {
    return isCounsellor(user) || isAdmin(user);
  }

  /// Check if user has permission to delete any content
  static bool canDeleteAnyContent(UserModel? user) {
    return isAdmin(user);
  }

  /// Check if user has permission to modify security settings
  static bool canModifySecuritySettings(UserModel? user) {
    return isAdmin(user);
  }

  /// Get display name for role
  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'User';
      case UserRole.counsellor:
        return 'Counsellor';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  /// Get description for role
  static String getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'Can track mood, receive recommendations, and connect with counsellors';
      case UserRole.counsellor:
        return 'Can manage clients, view client mood entries, and provide support';
      case UserRole.admin:
        return 'Has full access to all system features and user management';
    }
  }

  /// Check if user can access a specific feature
  static bool canAccessFeature(UserModel? user, String featureId) {
    if (user == null) return false;

    switch (featureId) {
      case 'mood_tracking':
        return isUser(user);
      case 'client_management':
        return isCounsellor(user) || isAdmin(user);
      case 'admin_panel':
        return isAdmin(user);
      case 'messaging':
        return user.role != UserRole.admin; // All except admin for now
      case 'analytics':
        return true; // All authenticated users
      default:
        return false;
    }
  }
}
