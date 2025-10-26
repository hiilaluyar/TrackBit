import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/streak_model.dart';
import '../widgets/streak_card.dart';
import 'friends_screen.dart';
import 'challenges_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final DatabaseService _databaseService = DatabaseService();

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      _HomeTab(),
      FriendsScreen(),
      ChallengesScreen(),
      ProfileScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Arkadaşlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Challengelar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('TrackBit 🔥'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<StreakModel>>(
        stream: _databaseService.getUserStreaks(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🎯', style: TextStyle(fontSize: 80)),
                  SizedBox(height: 16),
                  Text(
                    'Henüz streak\'in yok',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'İlk streak\'ini ekleyerek başla!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final streaks = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.only(top: 16, bottom: 80),
            itemCount: streaks.length,
            itemBuilder: (context, index) {
              final streak = streaks[index];
              return StreakCard(
                streak: streak,
                onCheck: () {
                  _databaseService.checkStreak(streak.id, streak);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Harika! Streak\'in artıyor!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                onDelete: () {
                  _databaseService.deleteStreak(streak.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Streak silindi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStreakDialog(context, userId),
        icon: Icon(Icons.add),
        label: Text('Yeni Streak'),
      ),
    );
  }

  void _showAddStreakDialog(BuildContext context, String userId) {
    final nameController = TextEditingController();
    String selectedEmoji = '⭐';

    final emojis = [
      '⭐',
      '🔥',
      '💪',
      '📚',
      '🏃',
      '🎯',
      '🧘',
      '💧',
      '🥗',
      '🏠',
      '🎨',
      '🎵',
      '🎮',
      '✍️',
      '🧠',
      '😊',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Yeni Streak Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Streak İsmi',
                  hintText: 'Örn: Spor yaptım',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('Emoji Seç:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: emojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedEmoji = emoji);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedEmoji == emoji
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedEmoji == emoji
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(emoji, style: TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lütfen bir isim girin')),
                  );
                  return;
                }

                _databaseService.addStreak(
                  userId: userId,
                  name: nameController.text.trim(),
                  emoji: selectedEmoji,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Yeni streak eklendi! 🎉'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
