import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'reels_api_service.dart';

class ReelsFeedScreen extends StatefulWidget {
  final bool isTabActive;
  const ReelsFeedScreen({super.key, this.isTabActive = true});

  @override
  State<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends State<ReelsFeedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final ReelsApiService _apiService = ReelsApiService();
  List<Map<String, dynamic>> _reels = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;

  YoutubePlayerController? _globalController;
  bool _isGlobalPlayerReady = false;
  bool _isVideoPlaying = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialReels();
  }

  Future<void> _loadInitialReels() async {
    final reels = await _apiService.fetchInitialReels();
    if (mounted) {
      setState(() {
        _reels = reels;
        _isLoading = false;
      });

      if (_reels.isNotEmpty) {
        _initGlobalPlayer(_reels[0]['videoId']);
      }
    }
  }

  void _initGlobalPlayer(String videoId) {
    _globalController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        loop: true,
        hideControls: true,
        disableDragSeek: true,
        enableCaption: false,
        forceHD: false, // Ağ yükünü ve cihaz kasmasını azaltmak için false
      ),
    )..addListener(_playerListener);
  }

  void _playerListener() {
    if (!mounted || _globalController == null) return;
    
    final isPlaying = _globalController!.value.isPlaying;
    if (_isVideoPlaying != isPlaying) {
      setState(() {
        _isVideoPlaying = isPlaying;
      });
    }
  }

  Future<void> _loadMoreReels() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    final moreReels = await _apiService.fetchMoreReels();
    
    if (mounted) {
      setState(() {
        _reels.addAll(moreReels);
        _isLoadingMore = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ReelsFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_globalController != null && _isGlobalPlayerReady) {
      if (widget.isTabActive && !oldWidget.isTabActive) {
        _globalController!.play();
      } else if (!widget.isTabActive && oldWidget.isTabActive) {
        _globalController!.pause();
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _globalController?.removeListener(_playerListener);
    _globalController?.dispose();
    _pageController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_globalController == null || !_isGlobalPlayerReady) return;
    if (_globalController!.value.isPlaying) {
      _globalController!.pause();
    } else {
      _globalController!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('Tarifler yükleniyor...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : _reels.isEmpty 
              ? const Center(child: Text('Video bulunamadı.', style: TextStyle(color: Colors.white)))
              : Stack(
                  children: [
                    // 1. GLOBAL YOUTUBE PLAYER (Arka Planda Tek Bir Tane)
                    if (_globalController != null)
                      SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: 1080,
                            height: 1920,
                            child: IgnorePointer(
                              child: YoutubePlayer(
                                controller: _globalController!,
                                showVideoProgressIndicator: false,
                                bottomActions: const [],
                                topActions: const [],
                                onReady: () {
                                  _isGlobalPlayerReady = true;
                                  if (widget.isTabActive) {
                                    _globalController!.play();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 2. ŞEFFAF KAYDIRMA EKRANI (PageView)
                    PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                          _isVideoPlaying = false; // Yeni videoya geçince kapak resmini göster
                        });
                        
                        if (_globalController != null && _isGlobalPlayerReady) {
                          // Anında videoyu durdur ki arka planda eski video sesi patlaması yapmasın
                          _globalController!.pause();
                          
                          // Hızlı kaydırmalarda kasmayı (lag) önlemek için yüklemeyi geciktir (debounce)
                          _debounceTimer?.cancel();
                          _debounceTimer = Timer(const Duration(milliseconds: 350), () {
                            if (mounted && _currentPage == index) {
                              _globalController!.load(_reels[index]['videoId']);
                            }
                          });
                        }
                        
                        if (index >= _reels.length - 2) {
                          _loadMoreReels();
                        }
                      },
                      itemCount: _reels.length,
                      itemBuilder: (context, index) {
                        final reel = _reels[index];
                        final isActive = index == _currentPage;
                        
                        // Sadece aktif sayfada ve video gerçekten oynamaya başladığında kapak resmini gizle.
                        // Diğer sayfalarda kapak resmini göster ki arka plandaki eski video görünmesin.
                        final showThumbnail = !isActive || !_isVideoPlaying;

                        return GestureDetector(
                          onTap: isActive ? _togglePlayPause : null,
                          behavior: HitTestBehavior.opaque,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Kapak Resmi (Thumbnail)
                              if (showThumbnail)
                                Image.network(
                                  YoutubePlayer.getThumbnail(videoId: reel['videoId'], quality: ThumbnailQuality.standard),
                                  fit: BoxFit.cover,
                                ),

                              // Karartma Efekti
                              IgnorePointer(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, Colors.black87],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: [0.5, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                              // Kullanıcı Bilgileri
                              Positioned(
                                bottom: 80,
                                left: 16,
                                right: 80,
                                child: IgnorePointer(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: NetworkImage(reel['avatar']),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            reel['user'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.white, width: 1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text('Takip Et', style: TextStyle(color: Colors.white, fontSize: 10)),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        reel['caption'],
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                                ),
                              ),

                              // Sağ Menü Butonları
                              Positioned(
                                bottom: 80,
                                right: 16,
                                child: Column(
                                  children: [
                                    _buildActionButton(Icons.favorite, reel['likes'], color: Colors.red),
                                    _buildActionButton(Icons.comment, reel['comments']),
                                    _buildActionButton(Icons.bookmark, 'Kaydet'),
                                    _buildActionButton(Icons.share, 'Paylaş'),
                                  ],
                                ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2, end: 0),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
