import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../gamification/data/gamification_service.dart';
import '../recipes/recipe_detail_screen.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? initialUserName;
  final String? initialUserPhoto;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.initialUserName,
    this.initialUserPhoto,
  });

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  String _name = '';
  String _photoUrl = '';
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _name = widget.initialUserName ?? 'Kullanıcı';
    _photoUrl = widget.initialUserPhoto ?? '';
    _currentUserId = ServiceLocator.auth.currentUser?.uid ?? '';
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final doc = await ServiceLocator.profile.getUserProfile(widget.userId);
    if (doc != null && mounted) {
      setState(() {
        _name = doc['name'] ?? _name;
        _photoUrl = doc['photoUrl'] ?? _photoUrl;
      });
    }
  }

  Widget _buildStatColumn(String label, Stream<int> stream) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBadgesRow(bool isTr) {
    return StreamBuilder<List<String>>(
      stream: ServiceLocator.gamification.getUserBadges(widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final badges = snapshot.data!;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTr ? 'Kazanılan Rozetler' : 'Earned Badges',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: badges.map((badgeId) {
                  final badgeTitle = GamificationService.getBadgeTitle(badgeId, isTr);
                  final badgeDesc = GamificationService.getBadgeDesc(badgeId, isTr);
                  final badgeIcon = GamificationService.badgeData[badgeId]?['icon'] ?? '🏅';
                  
                  return Tooltip(
                    message: badgeDesc,
                    triggerMode: TooltipTriggerMode.tap,
                    showDuration: const Duration(seconds: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(badgeIcon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            badgeTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecipesGrid(bool isTr) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ServiceLocator.social.getUserPosts(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(40.0),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                isTr ? 'Kullanıcının henüz paylaştığı bir tarif yok.' : 'This user hasn\'t shared any recipes yet.',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          );
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 24, bottom: 40),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.8,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final title = data['title'] ?? data['name'] ?? (isTr ? 'İsimsiz Tarif' : 'Untitled Recipe');
            final imageUrl = data['imageUrl'];
            final category = data['category'] ?? (isTr ? 'Genel' : 'General');

            return GestureDetector(
              onTap: () {
                // If it's a full recipe data structure it can go to RecipeDetailScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeData: data)),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageUrl == null
                            ? Center(child: Icon(Icons.restaurant, color: AppColors.primary))
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.tertiaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onTertiaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == _currentUserId) {
      // If the user taps on their own profile picture, they should just go back
      // or we can redirect to the main profile tab. But here we just build it.
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          _name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.onSurfaceVariant, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: _photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const CircularProgressIndicator(),
                        errorWidget: (_, _, _) => Icon(Icons.person, size: 48, color: AppColors.primary),
                      )
                    : Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.person, size: 48, color: AppColors.primary),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            
            if (_currentUserId != widget.userId && _currentUserId.isNotEmpty) ...[
              const SizedBox(height: 16),
              StreamBuilder<bool>(
                stream: ServiceLocator.social.isFollowingStream(_currentUserId, widget.userId),
                builder: (context, snapshot) {
                  final isFollowing = snapshot.data ?? false;
                  
                  return ElevatedButton(
                    onPressed: () async {
                      if (isFollowing) {
                        await ServiceLocator.social.unfollowUser(_currentUserId, widget.userId);
                      } else {
                        await ServiceLocator.social.followUser(_currentUserId, widget.userId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? AppColors.surfaceContainerHigh : AppColors.primary,
                      foregroundColor: isFollowing ? AppColors.onSurfaceVariant : AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      isFollowing ? 'Takipten Çık' : 'Takip Et',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  );
                },
              ),
            ],
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Takipçi', ServiceLocator.profile.getFollowersCount(widget.userId)),
                Container(width: 1, height: 30, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                _buildStatColumn('Takip Edilen', ServiceLocator.profile.getFollowingCount(widget.userId)),
                Container(width: 1, height: 30, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                _buildStatColumn('Tarifler', ServiceLocator.profile.getUserRecipesCount(widget.userId)),
              ],
            ),
            
            _buildBadgesRow(Localizations.localeOf(context).languageCode == 'tr'),
            
            const SizedBox(height: 24),
            const Divider(),
            
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tarifleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
            
            _buildRecipesGrid(Localizations.localeOf(context).languageCode == 'tr'),
          ],
        ),
      ),
    );
  }
}
