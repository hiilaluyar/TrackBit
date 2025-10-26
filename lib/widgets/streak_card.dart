import 'package:flutter/material.dart';
import '../models/streak_model.dart';

class StreakCard extends StatelessWidget {
  final StreakModel streak;
  final VoidCallback onCheck;
  final VoidCallback onDelete;

  const StreakCard({
    Key? key,
    required this.streak,
    required this.onCheck,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCheckedToday = streak.isCheckedToday;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kısım: Emoji, İsim ve Sil butonu
            Row(
              children: [
                // Emoji
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(streak.emoji, style: TextStyle(fontSize: 32)),
                ),
                SizedBox(width: 16),

                // Streak ismi ve streak sayısı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        streak.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: streak.currentStreak > 0
                                ? Colors.orange
                                : Colors.grey,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${streak.currentStreak} gün',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: streak.currentStreak > 0
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                          ),
                          if (streak.longestStreak > 0) ...[
                            SizedBox(width: 8),
                            Text(
                              '(En iyi: ${streak.longestStreak})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Sil butonu
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    // Silme onayı
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Streak\'i Sil'),
                        content: Text(
                          '${streak.name} streak\'ini silmek istediğine emin misin?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('İptal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onDelete();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Text('Sil'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: 16),

            // İşaretle butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCheckedToday ? null : onCheck,
                icon: Icon(
                  isCheckedToday ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                ),
                label: Text(
                  isCheckedToday ? 'Bugün Tamamlandı! 🎉' : 'Bugün Yaptım!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCheckedToday ? Colors.green : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Son işaretleme zamanı
            if (streak.lastChecked != null) ...[
              SizedBox(height: 8),
              Text(
                'Son işaretlenme: ${_formatDate(streak.lastChecked!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Bugün ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (checkDate == yesterday) {
      return 'Dün ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
