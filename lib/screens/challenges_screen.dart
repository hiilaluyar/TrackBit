import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/challenge_model.dart';
import '../models/user_model.dart';

class ChallengesScreen extends StatefulWidget {
  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  int _selectedTab = 0; // 0: Aktif, 1: Katılınabilir

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Challengelar 🏆'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0
                                ? Colors.blue
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Aktif',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: _selectedTab == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedTab == 0 ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1
                                ? Colors.blue
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Katılınabilir',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: _selectedTab == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedTab == 1 ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _selectedTab == 0
          ? _buildActiveChallenges(userId)
          : _buildJoinableChallenges(userId),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateChallengeDialog(context, userId),
        icon: Icon(Icons.add),
        label: Text('Yeni Challenge'),
      ),
    );
  }

  Widget _buildActiveChallenges(String userId) {
    return StreamBuilder<List<ChallengeModel>>(
      stream: _databaseService.getUserChallenges(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🏆', style: TextStyle(fontSize: 80)),
                SizedBox(height: 16),
                Text(
                  'Henüz aktif challenge\'ın yok',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Arkadaşlarınla challenge oluştur!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final challenges = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _buildChallengeCard(challenge, userId);
          },
        );
      },
    );
  }

  Widget _buildChallengeCard(ChallengeModel challenge, String userId) {
    final isExpired = challenge.isExpired;
    final myScore = challenge.participantScores[userId] ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve emoji
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.grey.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(challenge.emoji, style: TextStyle(fontSize: 32)),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Oluşturan: ${challenge.creatorName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isExpired)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Bitti',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${challenge.daysRemaining} gün',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),

            // Skor tablosu
            Text(
              'Skor Tablosu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getParticipantsWithNames(challenge),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final participants = snapshot.data!;
                participants.sort((a, b) => b['score'].compareTo(a['score']));

                return Column(
                  children: participants.map((p) {
                    final isWinner =
                        isExpired && p['userId'] == challenge.winnerId;
                    final isMe = p['userId'] == userId;

                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? Colors.yellow.shade100
                            : isMe
                            ? Colors.blue.shade50
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isWinner
                              ? Colors.yellow.shade700
                              : isMe
                              ? Colors.blue
                              : Colors.transparent,
                          width: isWinner || isMe ? 2 : 0,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isWinner)
                            Text('🏆 ', style: TextStyle(fontSize: 20)),
                          Expanded(
                            child: Text(
                              '${p['name']}${isMe ? ' (Sen)' : ''}',
                              style: TextStyle(
                                fontWeight: isMe || isWinner
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${p['score']} gün',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // Check butonu (sadece aktif challengelarda)
            if (!isExpired) ...[
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _databaseService.updateChallengeScore(
                      challenge.id,
                      userId,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bugün tamamladın! 🎉'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: Icon(Icons.check_circle),
                  label: Text('Bugün Tamamladım'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJoinableChallenges(String userId) {
    return FutureBuilder<UserModel?>(
      future: _databaseService.getUserData(userId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final user = userSnapshot.data!;

        return FutureBuilder<List<ChallengeModel>>(
          future: _databaseService.getFriendsChallenges(user.friends),
          builder: (context, challengeSnapshot) {
            if (challengeSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!challengeSnapshot.hasData || challengeSnapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('👥', style: TextStyle(fontSize: 80)),
                    SizedBox(height: 16),
                    Text(
                      'Katılabileceğin challenge yok',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Arkadaşların challenge oluşturduğunda burada görünecek',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              );
            }

            final challenges = challengeSnapshot.data!
                .where((c) => !c.participantIds.contains(userId))
                .toList();

            if (challenges.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('✅', style: TextStyle(fontSize: 80)),
                    SizedBox(height: 16),
                    Text(
                      'Tüm challengelara katıldın!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                return _buildJoinableChallengeCard(challenge, userId);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildJoinableChallengeCard(ChallengeModel challenge, String userId) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(challenge.emoji, style: TextStyle(fontSize: 32)),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Oluşturan: ${challenge.creatorName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '${challenge.participantIds.length} kişi katıldı',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '${challenge.daysRemaining} gün kaldı',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _databaseService.joinChallenge(challenge.id, userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Challenge\'a katıldın! 🎉'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() => _selectedTab = 0);
                },
                icon: Icon(Icons.check),
                label: Text('Katıl'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getParticipantsWithNames(
    ChallengeModel challenge,
  ) async {
    List<Map<String, dynamic>> participants = [];

    for (String userId in challenge.participantIds) {
      final user = await _databaseService.getUserData(userId);
      if (user != null) {
        participants.add({
          'userId': userId,
          'name': user.username,
          'score': challenge.participantScores[userId] ?? 0,
        });
      }
    }

    return participants;
  }

  void _showCreateChallengeDialog(BuildContext context, String userId) async {
    final nameController = TextEditingController();
    String selectedEmoji = '🏆';
    int selectedDays = 7;

    final emojis = [
      '🏆',
      '🔥',
      '💪',
      '📚',
      '🏃',
      '🎯',
      '🧘',
      '💧',
      '🥗',
      '🎮',
      '🎨',
      '🎵',
    ];

    final user = await _databaseService.getUserData(userId);
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Yeni Challenge Oluştur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Challenge İsmi',
                    hintText: 'Örn: Her gün spor',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Emoji Seç:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: emojis.map((emoji) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedEmoji = emoji),
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
                SizedBox(height: 16),
                Text('Süre:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedDays,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [3, 7, 14, 30].map((days) {
                    return DropdownMenuItem(
                      value: days,
                      child: Text('$days gün'),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => selectedDays = value ?? 7),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lütfen bir isim girin')),
                  );
                  return;
                }

                try {
                  await _databaseService.createChallenge(
                    userId: userId,
                    userName: user.username,
                    name: nameController.text.trim(),
                    emoji: selectedEmoji,
                    durationDays: selectedDays,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Challenge oluşturuldu! 🎉'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
