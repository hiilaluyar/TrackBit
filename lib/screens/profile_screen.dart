import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/streak_model.dart';

class ProfileScreen extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: _databaseService.getUserData(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData) {
            return Center(child: Text('Kullanıcı bilgisi bulunamadı'));
          }

          final user = userSnapshot.data!;

          return StreamBuilder<List<StreakModel>>(
            stream: _databaseService.getUserStreaks(userId),
            builder: (context, streakSnapshot) {
              final streaks = streakSnapshot.data ?? [];

              // İstatistikleri hesapla
              final activeStreaks = streaks
                  .where((s) => s.currentStreak > 0)
                  .length;
              final totalDays = streaks.fold<int>(
                0,
                (sum, streak) => sum + streak.currentStreak,
              );
              final longestStreak = streaks.isEmpty
                  ? 0
                  : streaks
                        .map((s) => s.longestStreak)
                        .reduce((a, b) => a > b ? a : b);

              return SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 32),

                    // Profil resmi
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        user.username[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Kullanıcı adı
                    Text(
                      user.username,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),

                    // Email
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 32),

                    // İstatistik kartları
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.local_fire_department,
                              title: 'Aktif Streakler',
                              value: '$activeStreaks',
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.calendar_today,
                              title: 'Toplam Gün',
                              value: '$totalDays',
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.emoji_events,
                              title: 'En Uzun Streak',
                              value: '$longestStreak',
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.people,
                              title: 'Arkadaşlar',
                              value: '${user.friends.length}',
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),

                    // Streak listesi
                    if (streaks.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tüm Streaklerim',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      ...streaks
                          .map((streak) => _buildStreakListTile(streak))
                          .toList(),
                    ],

                    SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakListTile(StreakModel streak) {
    return ListTile(
      leading: Text(streak.emoji, style: TextStyle(fontSize: 32)),
      title: Text(streak.name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('En uzun: ${streak.longestStreak} gün'),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: streak.currentStreak > 0
              ? Colors.orange.shade100
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              color: streak.currentStreak > 0 ? Colors.orange : Colors.grey,
              size: 18,
            ),
            SizedBox(width: 4),
            Text(
              '${streak.currentStreak}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: streak.currentStreak > 0
                    ? Colors.orange.shade900
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
