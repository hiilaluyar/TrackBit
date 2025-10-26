import 'package:flutter/material.dart';
import '../models/streak_model.dart';

class StreakCard extends StatelessWidget {
  final StreakModel streak;
  final VoidCallback onCheck;
  final VoidCallback onDelete;

  const StreakCard({
    required this.streak,
    required this.onCheck,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckedToday = streak.isCheckedToday;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isCheckedToday
              ? LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Emoji
                  Text(streak.emoji, style: TextStyle(fontSize: 40)),
                  SizedBox(width: 16),

                  // İsim ve streak sayısı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          streak.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isCheckedToday ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: isCheckedToday
                                  ? Colors.white
                                  : Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${streak.currentStreak} gün',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isCheckedToday
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sil butonu
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: isCheckedToday ? Colors.white70 : Colors.red,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Streak\'i Sil'),
                          content: Text(
                            'Bu streak\'i silmek istediğinden emin misin?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('İptal'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onDelete();
                              },
                              child: Text(
                                'Sil',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 12),

              // İşaretle butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCheckedToday ? null : onCheck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCheckedToday
                        ? Colors.white
                        : Colors.blue,
                    foregroundColor: isCheckedToday
                        ? Colors.green
                        : Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isCheckedToday ? '✓ Bugün Tamamlandı' : 'Bugün Yaptım',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // En uzun streak
              if (streak.longestStreak > 0)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'En uzun: ${streak.longestStreak} gün',
                    style: TextStyle(
                      fontSize: 12,
                      color: isCheckedToday ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
