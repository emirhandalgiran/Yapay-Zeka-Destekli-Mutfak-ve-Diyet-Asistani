import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 36),
            _buildBentoGrid(),
            const SizedBox(height: 36),
            _buildQuoteCard(),
            const SizedBox(height: 40),
            _buildCTASection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'AuraCook',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.accent,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              'Hakkımızda',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VİZYONUMUZ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              height: 1.1,
              letterSpacing: -1.5,
            ),
            children: [
              const TextSpan(text: 'Geleceği\n'),
              TextSpan(
                text: 'Besliyoruz.',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'AuraCook, mutfak yönetimini sadece bir araç değil, sürdürülebilir bir yaşam biçimi haline getiren dijital bir eczacıdır.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                '40%',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Dünya genelinde üretilen gıdanın çöpe gitme oranı. Biz bu rakamı değiştirmek için buradayız.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid() {
    return Column(
      children: [
        _buildMissionCard(),
        const SizedBox(height: 14),
        _buildSustainabilityCard(),
        const SizedBox(height: 14),
        _buildAcademicCard(),
      ],
    );
  }

  Widget _buildMissionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.gps_fixed,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Misyonumuz',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Her evde gıda israfını sıfıra indirmek. AuraCook, akıllı envanter takibi ve dinamik tarif önerileriyle, elinizdeki her malzemenin en yüksek değerine ulaşmasını sağlar. Kullanıcılarımıza sadece neyi pişireceklerini değil, kaynaklarını nasıl koruyacaklarını öğretiyoruz.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'DAHA FAZLA BİLGİ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.trending_flat,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.eco,
            size: 40,
            color: AppColors.onPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'Sürdürülebilirlik',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tüketim alışkanlıklarımızı değiştirerek gezegenimizin karbon ayak izini azaltıyoruz. Her kurtarılan gıda, korunan su ve toprak demektir.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onPrimary.withValues(alpha: 0.85),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proje Bağlamı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'AuraCook, modern teknoloji ve çevresel verimlilik arasındaki sinerjiyi araştıran bir Mobil Uygulama Geliştirme Dersi Final Ödevi Projesi olarak hayata geçirilmiştir. Kullanıcı deneyimi tasarımı ve yapay zeka entegrasyonu üzerine odaklanan bu çalışma, gıda ekosisteminde dijital dönüşümü hedefler.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'TOPKAPI ÜNİVERSİTESİ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote,
            size: 32,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            '"En iyi yemek, israf edilmeyen malzemenin yaratıcılıkla buluştuğu andır."',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              color: AppColors.onSurface,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Pulse Chef Assistant',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Bu Değişimin\nBir Parçası Olun.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Mutfak auranızı bugün keşfedin ve daha yeşil bir gelecek için ilk adımı AuraCook ile atın.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hemen Başlayın',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.rocket_launch,
                        color: AppColors.onPrimary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'İletişime Geçin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
