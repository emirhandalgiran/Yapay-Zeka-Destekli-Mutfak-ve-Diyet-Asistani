import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../auth/auth_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _isPrivate = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final user = ServiceLocator.auth.currentUser;
    if (user != null) {
      final data = await ServiceLocator.profile.getUserProfile(user.uid);
      if (data != null && mounted) {
        setState(() {
          _isPrivate = data['isPrivate'] ?? false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePrivacy(bool val) async {
    setState(() => _isPrivate = val);
    final user = ServiceLocator.auth.currentUser;
    if (user != null) {
      await ServiceLocator.profile.updateUserProfile(user.uid, {'isPrivate': val});
    }
  }

  Future<void> _deleteAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Hesabı Sil', style: TextStyle(color: AppColors.error)),
        content: const Text('Bu işlem geri alınamaz. Tüm verileriniz silinecektir. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final user = ServiceLocator.auth.currentUser;
    if (user != null) {
      try {
        await user.delete();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Hesap silmek için lütfen önce çıkış yapıp tekrar giriş yapın (Güvenlik gereksinimi).'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Gizlilik ve Güvenlik', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.onSurface)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.onSurfaceVariant, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil Görünürlüğü',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                title: const Text('Gizli Profil', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Profilinizi sadece sosyal bağlantılarınız görebilir.', style: TextStyle(fontSize: 12)),
                trailing: Switch(
                  value: _isPrivate,
                  onChanged: _togglePrivacy,
                  activeThumbColor: AppColors.white,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: AppColors.white,
                  inactiveTrackColor: AppColors.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Hesap Yönetimi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.error,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton.icon(
                  onPressed: _deleteAccount,
                  icon: Icon(
                    Icons.delete_forever,
                    color: AppColors.error,
                    size: 20,
                  ),
                  label: Text(
                    'Hesabımı Kalıcı Olarak Sil',
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
          ],
        ),
      ),
    );
  }
}
