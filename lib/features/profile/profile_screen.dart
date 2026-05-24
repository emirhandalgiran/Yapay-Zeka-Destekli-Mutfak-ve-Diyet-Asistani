import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import 'kitchen_preferences_screen.dart';
import 'account_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../gamification/data/gamification_service.dart';
import '../../core/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;

  String _name = 'AuraCook Kullanıcısı';
  String _email = '';
  String _photoUrl = '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String _getBadgeTitle(String badgeId, bool isTr) {
    return GamificationService.getBadgeTitle(badgeId, isTr);
  }

  String _getBadgeDesc(String badgeId, bool isTr) {
    return GamificationService.getBadgeDesc(badgeId, isTr);
  }

  Future<void> _pickAndUploadImage() async {
    final user = ServiceLocator.auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 30, maxWidth: 400);
    
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    final isTr = ref.read(localeProvider) == 'tr';

    try {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final downloadUrl = 'data:image/jpeg;base64,$base64String';

      await ServiceLocator.profile.updateUserProfile(user.uid, {'photoUrl': downloadUrl});

      setState(() {
        _photoUrl = downloadUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTr ? 'Profil fotoğrafı güncellendi!' : 'Profile picture updated!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTr ? 'Hata oluştu: $e' : 'An error occurred: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    final user = ServiceLocator.auth.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          _email = user.email ?? '';
          _name = user.displayName ?? (ref.read(localeProvider) == 'tr' ? 'AuraCook Kullanıcısı' : 'AuraCook User');
        });
      }
      final doc = await ServiceLocator.profile.getUserProfile(user.uid);
      if (doc != null && mounted) {
        setState(() {
          if (doc['name'] != null) _name = doc['name'];
          if (doc['photoUrl'] != null) _photoUrl = doc['photoUrl'];
          if (doc['notificationsEnabled'] != null) _notificationsEnabled = doc['notificationsEnabled'];
          if (doc['language'] != null) {
            ref.read(localeProvider.notifier).syncWithFirebase(doc['language']);
          }
        });
      }
    }
  }

  void _showLanguageDialog() {
    final isTr = ref.read(localeProvider) == 'tr';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTr ? 'Uygulama Dili' : 'Application Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Türkçe', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: isTr ? Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () async {
                  setState(() {});
                  Navigator.pop(ctx);
                  await ref.read(localeProvider.notifier).setLocale('tr');
                },
              ),
              ListTile(
                title: const Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: !isTr ? Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () async {
                  setState(() {});
                  Navigator.pop(ctx);
                  await ref.read(localeProvider.notifier).setLocale('en');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isTr ? 'Dil tercihi kaydedildi.' : 'Language preference saved.'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgesRow() {
    final user = ServiceLocator.auth.currentUser;
    if (user == null) return const SizedBox.shrink();
    final isTr = ref.watch(localeProvider) == 'tr';

    return StreamBuilder<List<String>>(
      stream: ServiceLocator.gamification.getUserBadges(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final badges = snapshot.data!;
        return Container(
          width: double.infinity,
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
                  final badgeInfo = GamificationService.badgeData[badgeId];
                  if (badgeInfo == null) return const SizedBox.shrink();
                  
                  final title = _getBadgeTitle(badgeId, isTr);
                  final desc = _getBadgeDesc(badgeId, isTr);
                  
                  return Tooltip(
                    message: desc,
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
                          Text(badgeInfo['icon'] ?? '', style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            title,
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

  Widget _buildStatsRow() {
    final user = ServiceLocator.auth.currentUser;
    if (user == null) return const SizedBox.shrink();
    final isTr = ref.watch(localeProvider) == 'tr';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn(isTr ? 'Takipçi' : 'Followers', ServiceLocator.profile.getFollowersCount(user.uid)),
          Container(width: 1, height: 30, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          _buildStatColumn(isTr ? 'Takip Edilen' : 'Following', ServiceLocator.profile.getFollowingCount(user.uid)),
          Container(width: 1, height: 30, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          _buildStatColumn(isTr ? 'Tarifler' : 'Recipes', ServiceLocator.profile.getUserRecipesCount(user.uid)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = ref.watch(localeProvider) == 'tr';
    final currentLang = isTr ? 'Türkçe' : 'English';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // — Header —
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isTr ? 'Profil ve Ayarlar' : 'Profile & Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: _photoUrl.isNotEmpty 
                        ? (_photoUrl.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(_photoUrl.split(',').last),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Icon(Icons.person, color: AppColors.primary, size: 20),
                              )
                            : CachedNetworkImage(
                                imageUrl: _photoUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ))
                        : Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 20,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // — Profile Hero —
              Center(
                child: Column(
                  children: [
                    // Avatar with edit button
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 4,
                            ),
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
                          ? (_photoUrl.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(_photoUrl.split(',').last),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    child: Icon(Icons.person, size: 48, color: AppColors.primary),
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: _photoUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.person,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ))
                          : Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.person,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _isUploading ? null : _pickAndUploadImage,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _isUploading 
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                                    )
                                  : Icon(
                                      Icons.edit,
                                      color: AppColors.white,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Name
                    Text(
                      _name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _email,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    _buildBadgesRow(),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // — GENEL AYARLAR —
              _buildSectionTitle(isTr ? 'GENEL AYARLAR' : 'GENERAL SETTINGS'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildNavigableTile(
                      icon: Icons.person_outline,
                      title: isTr ? 'Hesap Ayarları' : 'Account Settings',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountSettingsScreen(),
                          ),
                        );
                        _loadUserData(); // refresh name if changed
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.notifications_outlined,
                      title: isTr ? 'Bildirim Tercihleri' : 'Notification Preferences',
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (val) async {
                          setState(() => _notificationsEnabled = val);
                          final user = ServiceLocator.auth.currentUser;
                          if (user != null) {
                            await ServiceLocator.profile.updateUserProfile(
                                user.uid, {'notificationsEnabled': val});
                          }
                        },
                        activeThumbColor: AppColors.white,
                        activeTrackColor: AppColors.primary,
                        inactiveThumbColor: AppColors.white,
                        inactiveTrackColor: AppColors.surfaceContainerHighest,
                      ),
                    ),
                    _buildDivider(),
                    _buildNavigableTile(
                      icon: Icons.security_outlined,
                      title: isTr ? 'Gizlilik ve Güvenlik' : 'Privacy & Security',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacySecurityScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // — TERCİHLER —
              _buildSectionTitle(isTr ? 'TERCİHLER' : 'PREFERENCES'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildNavigableTile(
                      icon: Icons.restaurant_menu,
                      title: isTr ? 'Mutfak Tercihleri' : 'Kitchen Preferences',
                      subtitle: isTr ? 'Beslenme & malzeme tercihleri' : 'Dietary & ingredient preferences',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const KitchenPreferencesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.language,
                      title: isTr ? 'Uygulama Dili' : 'Application Language',
                      subtitle: currentLang,
                      trailing: IconButton(
                        icon: Icon(Icons.expand_more, color: AppColors.onSurfaceVariant),
                        onPressed: _showLanguageDialog,
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: isTr ? 'Karanlık Mod' : 'Dark Mode',
                      trailing: Consumer(
                        builder: (context, ref, _) {
                          final isDark = ref.watch(themeProvider);
                          return Switch(
                            value: isDark,
                            onChanged: (val) async {
                              ref.read(themeProvider.notifier).toggleTheme(val);
                            },
                            activeThumbColor: AppColors.white,
                            activeTrackColor: AppColors.primary,
                            inactiveThumbColor: AppColors.white,
                            inactiveTrackColor: AppColors.surfaceContainerHighest,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Oturumu Kapat ──
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton.icon(
                    onPressed: () async {
                      await ServiceLocator.auth.signOut();
                    },
                    icon: Icon(
                      Icons.logout,
                      color: AppColors.error,
                      size: 20,
                    ),
                    label: Text(
                      isTr ? 'Oturumu Kapat' : 'Log Out',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.onSurfaceVariant,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Trailing widget
          trailing,
        ],
      ),
    );
  }

  Widget _buildNavigableTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: _buildSettingsTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: AppColors.black.withValues(alpha: 0.04),
      ),
    );
  }
}
