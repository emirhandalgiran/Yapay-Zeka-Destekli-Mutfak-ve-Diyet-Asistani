import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../gamification/data/gamification_service.dart';
import '../profile/public_profile_screen.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    {'label': 'Tarifler', 'field': 'recipesPostedCount', 'icon': Icons.restaurant_menu},
    {'label': 'Takipçi', 'field': 'followersCount', 'icon': Icons.people},
    {'label': 'Yorumlar', 'field': 'commentsCount', 'icon': Icons.chat_bubble},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Liderlik Tablosu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: _tabs.map((t) => Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t['icon'] as IconData, size: 16),
                    const SizedBox(width: 6),
                    Text(t['label'] as String),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          return _buildLeaderboardList(tab['field'] as String);
        }).toList(),
      ),
    );
  }

  Widget _buildLeaderboardList(String field) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ServiceLocator.gamification.getLeaderboard(field),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 64, color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(
                  'Henüz kimse sıralamada yok.\nİlk sen ol!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildLeaderboardTile(user, index + 1)
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 60), duration: 400.ms)
                .slideX(begin: 0.05);
          },
        );
      },
    );
  }

  Widget _buildLeaderboardTile(Map<String, dynamic> user, int rank) {
    final bool isTop3 = rank <= 3;
    final Color rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : AppColors.onSurfaceVariant;

    final String rankEmoji = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '';
    final String displayName = user['displayName'] ?? 'Anonim Şef';
    final int score = user['score'] ?? 0;
    final List<String> badges = List<String>.from(user['badges'] ?? []);

    return GestureDetector(
      onTap: () {
        final uid = user['userId'] ?? '';
        if (uid.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              userId: uid,
              initialUserName: displayName,
            ),
          ));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isTop3
              ? rankColor.withValues(alpha: 0.08)
              : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTop3
                ? rankColor.withValues(alpha: 0.25)
                : AppColors.outlineVariant.withValues(alpha: 0.12),
          ),
          boxShadow: isTop3
              ? [
                  BoxShadow(
                    color: rankColor.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Sıralama
            SizedBox(
              width: 36,
              child: isTop3
                  ? Text(rankEmoji, style: const TextStyle(fontSize: 22))
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
            ),
            const SizedBox(width: 8),

            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isTop3
                    ? rankColor.withValues(alpha: 0.15)
                    : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: isTop3
                    ? Border.all(color: rankColor.withValues(alpha: 0.4), width: 2)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: user['photoURL'] != null && user['photoURL'].toString().isNotEmpty
                    ? (user['photoURL'].toString().startsWith('data:image')
                        ? Image.memory(
                            base64Decode(user['photoURL'].toString().split(',').last),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildInitialAvatar(displayName, isTop3, rankColor),
                          )
                        : CachedNetworkImage(
                            imageUrl: user['photoURL'],
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _buildInitialAvatar(displayName, isTop3, rankColor),
                          ))
                    : _buildInitialAvatar(displayName, isTop3, rankColor),
              ),
            ),
            const SizedBox(width: 14),

            // İsim + Rozet
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isTop3 ? FontWeight.w800 : FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: badges.take(3).map((b) {
                        final badge = GamificationService.badgeData[b];
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            badge?['icon'] ?? '🏅',
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Skor
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isTop3
                    ? rankColor.withValues(alpha: 0.12)
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                score.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isTop3 ? rankColor : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(String displayName, bool isTop3, Color rankColor) {
    return Center(
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: isTop3 ? rankColor : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
