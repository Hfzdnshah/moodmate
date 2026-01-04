import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../mood/mood_entry_screen.dart';
import '../mood/mood_history_screen.dart';
import '../mood/mood_trends_screen.dart';
import '../counsellor/counsellor_list_screen.dart';
import '../counsellor/support_requests_screen.dart';
import '../counsellor/counsellor_dashboard_screen.dart';
import '../counsellor/pending_requests_screen.dart';
import '../counsellor/counsellor_messages_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;

        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              user.name,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout_rounded),
                          color: colorScheme.onSurfaceVariant,
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Sign Out'),
                                content: const Text(
                                  'Are you sure you want to sign out?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Sign Out'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await authProvider.signOut();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Role Badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(
                          user.role,
                          colorScheme,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getRoleColor(
                            user.role,
                            colorScheme,
                          ).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        _getRoleDisplayName(user.role),
                        style: TextStyle(
                          color: _getRoleColor(user.role, colorScheme),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Dashboard Grid
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (user.role == UserRole.user)
                          _buildUserGrid(context)
                        else if (user.role == UserRole.counsellor)
                          _buildCounsellorGrid(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'User';
      case UserRole.counsellor:
        return 'Counsellor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  Color _getRoleColor(UserRole role, ColorScheme colorScheme) {
    switch (role) {
      case UserRole.user:
        return colorScheme.primary;
      case UserRole.counsellor:
        return colorScheme.tertiary;
      case UserRole.admin:
        return colorScheme.error;
    }
  }

  Widget _buildUserGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildDashboardCard(
          context,
          icon: Icons.edit_note_rounded,
          title: 'Log Mood',
          subtitle: 'How are you?',
          color: colorScheme.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MoodEntryScreen()),
          ),
        ),
        _buildDashboardCard(
          context,
          icon: Icons.history_rounded,
          title: 'History',
          subtitle: 'Past entries',
          color: colorScheme.secondary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MoodHistoryScreen()),
          ),
        ),
        _buildDashboardCard(
          context,
          icon: Icons.show_chart_rounded,
          title: 'Trends',
          subtitle: 'Your patterns',
          color: colorScheme.tertiary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MoodTrendsScreen()),
          ),
        ),
        _buildDashboardCard(
          context,
          icon: Icons.support_agent_rounded,
          title: 'Counsellor',
          subtitle: 'Get help',
          color: Colors.orange,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CounsellorListScreen(),
            ),
          ),
        ),
        _buildDashboardCard(
          context,
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Requests',
          subtitle: 'Support status',
          color: Colors.indigo,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SupportRequestsScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounsellorGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildDashboardCard(
          context,
          icon: Icons.people_alt_rounded,
          title: 'My Clients',
          subtitle: 'Manage clients',
          color: colorScheme.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CounsellorDashboardScreen(),
            ),
          ),
        ),
        _buildDashboardCard(
          context,
          icon: Icons.pending_actions_rounded,
          title: 'Requests',
          subtitle: 'New clients',
          color: colorScheme.secondary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PendingRequestsScreen(),
            ),
          ),
        ),
        _buildDashboardCard(
          context,
          icon: Icons.message_rounded,
          title: 'Messages',
          subtitle: 'Chat',
          color: colorScheme.tertiary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CounsellorMessagesScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
