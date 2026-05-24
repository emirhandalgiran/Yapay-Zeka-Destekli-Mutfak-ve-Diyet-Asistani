import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/components/aura_app_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../navigation/app_drawer.dart';
import '../recipes/share_recipe_screen.dart';
import 'components/comments_bottom_sheet.dart';
import '../profile/public_profile_screen.dart';
import 'leaderboard_screen.dart';
import '../gamification/quests_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _userId => ServiceLocator.auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _checkAndAddStockPosts();
  }

  Future<void> _checkAndAddStockPosts() async {
    try {
      final query = await ServiceLocator.social.firestore.collection('social_posts').get();
      final hasOldStockPosts = query.docs.any((doc) => doc.data()['userId']?.toString().startsWith('stock_') == true && !doc.data().containsKey('likedBy'));
      
      if (query.docs.isEmpty || hasOldStockPosts) {
        // Delete old stock posts to recreate with new fields
        for (var doc in query.docs) {
          if (doc.data()['userId']?.toString().startsWith('stock_') == true) {
             await doc.reference.delete();
          }
        }

        final stockPosts = [
          {
            'userId': 'stock_1',
            'authorName': 'Ayşe Şef',
            'authorLetter': 'A',
            'authorAvatar': 'https://randomuser.me/api/portraits/women/44.jpg',
            'title': 'Ev Yapımı Pizza',
            'description': 'İnce hamurlu, bol malzemeli nefis İtalyan pizzası. Hamuru 24 saat mayalandı!',
            'imageUrl': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
            'likesCount': 42,
            'commentsCount': 4,
            'likedBy': [],
          },
          {
            'userId': 'stock_2',
            'authorName': 'Mehmet Usta',
            'authorLetter': 'M',
            'authorAvatar': 'https://randomuser.me/api/portraits/men/32.jpg',
            'title': 'Klasik Burger',
            'description': 'Karamelize soğan ve cheddar peyniri ile kendi hazırladığım burger köftesi.',
            'imageUrl': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80',
            'likesCount': 89,
            'commentsCount': 3,
            'likedBy': [],
          },
          {
            'userId': 'stock_3',
            'authorName': 'Zeynep Mutfakta',
            'authorLetter': 'Z',
            'authorAvatar': 'https://randomuser.me/api/portraits/women/68.jpg',
            'title': 'Çikolatalı Sufle',
            'description': 'İçi akışkan, tam kıvamında fırından yeni çıkmış sufle tarifim.',
            'imageUrl': 'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=800&q=80',
            'likesCount': 156,
            'commentsCount': 4,
            'likedBy': [],
          },
          {
            'userId': 'stock_4',
            'authorName': 'Caner Aşçı',
            'authorLetter': 'C',
            'authorAvatar': 'https://randomuser.me/api/portraits/men/46.jpg',
            'title': 'Fırın Somon',
            'description': 'Kuşkonmaz ve limon dilimleri eşliğinde fırınlanmış taze somon.',
            'imageUrl': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80',
            'likesCount': 67,
            'commentsCount': 3,
            'likedBy': [],
          },
          {
            'userId': 'stock_5',
            'authorName': 'Elif\'in Tarifleri',
            'authorLetter': 'E',
            'authorAvatar': 'https://randomuser.me/api/portraits/women/12.jpg',
            'title': 'Taze Makarna',
            'description': 'Ev yapımı fesleğenli pesto sos ile taze makarna keyfi.',
            'imageUrl': 'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=800&q=80',
            'likesCount': 112,
            'commentsCount': 3,
            'likedBy': [],
          },
          {
            'userId': 'stock_6',
            'authorName': 'Gurme Burak',
            'authorLetter': 'G',
            'authorAvatar': 'https://randomuser.me/api/portraits/men/22.jpg',
            'title': 'Avokado Tost',
            'description': 'Ekşi mayalı ekmek üzerine poşe yumurta ve avokado ezmesi. Harika bir kahvaltı!',
            'imageUrl': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800&q=80',
            'likesCount': 210,
            'commentsCount': 4,
            'likedBy': [],
          }
        ];

        for (var post in stockPosts) {
          // Stok kullanıcıyı users koleksiyonuna da ekle ki profili ve avatarı çalışsın
          await ServiceLocator.profile.updateUserProfile(post['userId'] as String, {
            'displayName': post['authorName'],
            'photoUrl': post['authorAvatar'],
            'email': '${post['userId']}@aura.com',
          });

          final docRef = await ServiceLocator.social.firestore.collection('social_posts').add({
            ...post,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          final comments = [
            {'userId': 'mock_u1', 'authorName': 'Ahmet Yıldız', 'authorLetter': 'A', 'text': 'Harika görünüyor, ellerinize sağlık!'},
            {'userId': 'mock_u2', 'authorName': 'Merve Demir', 'authorLetter': 'M', 'text': 'Bunu hafta sonu kesinlikle deneyeceğim.'},
            {'userId': 'mock_u3', 'authorName': 'Burcu Aydın', 'authorLetter': 'B', 'text': 'Çok lezzetli duruyor, tarif için teşekkürler.'},
            if (post['commentsCount'] == 4)
              {'userId': 'mock_u4', 'authorName': 'Hakan Kaya', 'authorLetter': 'H', 'text': 'Favorilerime ekledim bile.'},
          ];

          for (var comment in comments) {
            await docRef.collection('comments').add({
              ...comment,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Stock posts error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShareRecipeScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: AppColors.onPrimary),
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ServiceLocator.social.getFeedPosts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Bir hata oluştu.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          itemCount: docs.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSocialActions(),
                  const SizedBox(height: 24),
                  if (docs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'Henüz hiç paylaşım yapılmadı. İlk tarifi sen paylaş!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ),
                ],
              );
            }

            final doc = docs[index - 1];
            final data = doc.data();
            final postId = doc.id;

            final Timestamp? ts = data['createdAt'] as Timestamp?;
            final timeAgo = ts != null ? _formatTimeAgo(ts.toDate()) : 'Az önce';

            return Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _buildPostCard(
                postId: postId,
                authorId: data['userId'] ?? '',
                avatarLetter: data['authorLetter'] ?? 'Ş',
                authorAvatar: data['authorAvatar'] ?? '',
                name: data['authorName'] ?? 'Aura Şefi',
                timeAgo: timeAgo,
                imageUrl: data['imageUrl'] ?? '',
                title: data['title'] ?? 'İsimsiz Tarif',
                description: data['description'] ?? '',
                likeCount: data['likesCount'] ?? 0,
                commentCount: data['commentsCount'] ?? 0,
                isLiked: data['likedBy'] is List && (data['likedBy'] as List).contains(_userId),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} gün önce';
    if (diff.inHours > 0) return '${diff.inHours} saat önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes} dk önce';
    return 'Az önce';
  }

  // ───────────── AppBar ─────────────
  PreferredSizeWidget _buildAppBar() {
    return AuraAppBar(scaffoldKey: _scaffoldKey);
  }

  // ───────────── Header ─────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aura Topluluk',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mutfağınızdaki ilhamı paylaşın.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ───────────── Liderlik & Görevler Butonları ─────────────
  Widget _buildSocialActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    const Color(0xFFF59E0B).withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Liderlik',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'En iyi şefler',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 20,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuestsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.10),
                    AppColors.primary.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('⚡', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Görevler',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'Günlük hedefler',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 20,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────── Post Card ─────────────
  Widget _buildPostCard({
    required String postId,
    required String authorId,
    required String avatarLetter,
    required String authorAvatar,
    required String name,
    required String timeAgo,
    required String imageUrl,
    required String title,
    required String description,
    required int likeCount,
    required int commentCount,
    required bool isLiked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar + İsim + Zaman
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (authorId.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(
                        userId: authorId,
                        initialUserName: name,
                      ),
                    ));
                  }
                },
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                        image: authorAvatar.isNotEmpty
                            ? DecorationImage(
                                image: authorAvatar.startsWith('data:image')
                                    ? MemoryImage(base64Decode(authorAvatar.split(',').last)) as ImageProvider
                                    : CachedNetworkImageProvider(authorAvatar),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: authorAvatar.isEmpty
                          ? Center(
                              child: Text(
                                avatarLetter,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            )
                          : null,
                    ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
                  ],
                ),
              ),
            ),
            if (authorId.isNotEmpty && authorId != _userId)
              StreamBuilder<bool>(
                stream: ServiceLocator.social.isFollowingStream(_userId, authorId),
                builder: (context, snapshot) {
                  final isFollowing = snapshot.data ?? false;
                  return GestureDetector(
                    onTap: () {
                      if (isFollowing) {
                        ServiceLocator.social.unfollowUser(_userId, authorId);
                      } else {
                        ServiceLocator.social.followUser(_userId, authorId);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFollowing ? AppColors.surfaceContainerHigh : AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        border: isFollowing ? Border.all(color: AppColors.outlineVariant) : null,
                      ),
                      child: Text(
                        isFollowing ? 'Takiptesin' : 'Takip Et',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isFollowing ? AppColors.onSurface : AppColors.onPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Yemek Görseli (4:5 aspect ratio)
        if (imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                color: AppColors.surfaceContainerLow,
                child: imageUrl.startsWith('data:image')
                  ? Image.memory(
                      base64Decode(imageUrl.split(',').last),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.restaurant, size: 64, color: AppColors.outlineVariant),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) {
                        return Container(
                          color: AppColors.surfaceContainerLow,
                          child: Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 64,
                              color: AppColors.outlineVariant,
                            ),
                          ),
                        );
                      },
                      progressIndicatorBuilder: (context, url, downloadProgress) {
                        return Container(
                          color: AppColors.surfaceContainerLow,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: downloadProgress.progress,
                              color: AppColors.primary,
                              strokeWidth: 2.5,
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ),
        if (imageUrl.isNotEmpty) const SizedBox(height: 16),

        // Başlık
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),

        // Açıklama
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        // Beğeni / Yorum / Paylaş
        Container(
          padding: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Beğeni
              _buildActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                iconColor: isLiked ? Colors.red : AppColors.onSurfaceVariant,
                label: likeCount.toString(),
                onTap: () {
                   final uId = _userId.isNotEmpty ? _userId : 'guest_\${DateTime.now().millisecondsSinceEpoch}';
                   ServiceLocator.social.likePost(postId, uId);
                },
              ),
              const SizedBox(width: 24),
              // Yorum
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: commentCount.toString(),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => FractionallySizedBox(
                      heightFactor: 0.75,
                      child: CommentsBottomSheet(postId: postId),
                    ),
                  );
                },
              ),
              const Spacer(),
              // Paylaş
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Bağlantı panoya kopyalandı!'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.share_outlined,
                  size: 22,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, duration: 500.ms, curve: Curves.easeOut);
  }

  // ───────────── Aksiyon Butonu ─────────────
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor ?? AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
