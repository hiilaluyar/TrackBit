import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _databaseService.searchUsers(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUserId = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Arkadaşlar')),
      body: Column(
        children: [
          // Arama kutusu
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Kullanıcı Ara',
                hintText: 'Kullanıcı adı girin',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Arama sonuçları veya arkadaş listesi
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults(currentUserId)
                : _buildFriendsList(currentUserId),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(String currentUserId) {
    if (_isSearching) {
      return Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Kullanıcı bulunamadı',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];

        if (user.uid == currentUserId) {
          return SizedBox.shrink(); // Kendi profilini gösterme
        }

        return ListTile(
          leading: CircleAvatar(child: Text(user.username[0].toUpperCase())),
          title: Text(user.username),
          subtitle: Text(user.email),
          trailing: ElevatedButton(
            onPressed: () async {
              await _databaseService.addFriend(currentUserId, user.uid);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.username} arkadaş olarak eklendi!'),
                  backgroundColor: Colors.green,
                ),
              );
              _searchController.clear();
              _searchUsers('');
            },
            child: Text('Ekle'),
          ),
        );
      },
    );
  }

  Widget _buildFriendsList(String currentUserId) {
    return FutureBuilder<UserModel?>(
      future: _databaseService.getUserData(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('👥', style: TextStyle(fontSize: 80)),
                SizedBox(height: 16),
                Text(
                  'Henüz arkadaşın yok',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Yukarıdan kullanıcı adı ile arama yap',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final friendIds = snapshot.data!.friends;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _databaseService.getFriendsStreaks(friendIds),
          builder: (context, streakSnapshot) {
            if (streakSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!streakSnapshot.hasData || streakSnapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 80)),
                    SizedBox(height: 16),
                    Text(
                      'Arkadaşlarının aktif streak\'i yok',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final friendsStreaks = streakSnapshot.data!;

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: friendsStreaks.length,
              itemBuilder: (context, index) {
                final data = friendsStreaks[index];
                final username = data['username'];
                final streak = data['streak'];

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        username[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Text(streak.emoji, style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${streak.name}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${streak.currentStreak}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
