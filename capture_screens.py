import os
import sys
import time
import subprocess
import shutil

# Files to modify and back up
FILES_TO_BACKUP = [
    "lib/main.dart",
    "lib/features/navigation/main_navigation.dart",
    "lib/features/home/home_screen.dart",
    "lib/features/recipes/recipes_screen.dart",
    "lib/features/social/social_screen.dart",
    "lib/features/profile/profile_screen.dart"
]

def backup_files():
    print("Backing up files...")
    for f in FILES_TO_BACKUP:
        if os.path.exists(f):
            shutil.copyfile(f, f + ".bak")
            print(f"Backed up: {f}")

def restore_files():
    print("Restoring original files...")
    for f in FILES_TO_BACKUP:
        bak_file = f + ".bak"
        if os.path.exists(bak_file):
            shutil.copyfile(bak_file, f)
            os.remove(bak_file)
            print(f"Restored: {f}")

def modify_main_dart():
    print("Modifying lib/main.dart to bypass splash/auth on screen parameter...")
    path = "lib/main.dart"
    with open(path, "r", encoding="utf-8") as file:
        content = file.read()
        
    # Add imports
    imports = "\nimport 'features/onboarding/onboarding_screen.dart';\nimport 'features/navigation/main_navigation.dart';\n"
    if "import 'core/theme/theme_provider.dart';" in content:
        content = content.replace("import 'core/theme/theme_provider.dart';", "import 'core/theme/theme_provider.dart';" + imports)
    
    # Inject debug widget selector
    debug_methods = """
  Widget _getDebugScreen(bool showHome) {
    final screen = Uri.base.queryParameters['screen'];
    if (screen == 'onboarding') return const OnboardingScreen();
    if (screen == 'home') return const MainNavigation();
    return SplashScreen(showHome: showHome);
  }
"""
    
    # Place inside AuraCookApp class
    if "class AuraCookApp extends ConsumerWidget {" in content:
        target = "class AuraCookApp extends ConsumerWidget {"
        content = content.replace(target, target + "\n" + debug_methods)
        
    # Replace home argument
    content = content.replace(
        "home: SplashScreen(showHome: showHome),",
        "home: _getDebugScreen(showHome),"
    )
    
    with open(path, "w", encoding="utf-8") as file:
        file.write(content)
    print("lib/main.dart modified successfully.")

def modify_main_navigation():
    print("Modifying lib/features/navigation/main_navigation.dart for tab redirection...")
    path = "lib/features/navigation/main_navigation.dart"
    with open(path, "r", encoding="utf-8") as file:
        content = file.read()
        
    old_init = "  int _currentIndex = 0;"
    new_init = """  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    final tabParam = Uri.base.queryParameters['tab'];
    _currentIndex = tabParam != null ? int.tryParse(tabParam) ?? 0 : 0;
  }"""
  
    if old_init in content:
        content = content.replace(old_init, new_init)
    else:
        # Fallback if double spacing
        content = content.replace("  int _currentIndex = 0;", new_init)
        
    with open(path, "w", encoding="utf-8") as file:
        file.write(content)
    print("main_navigation.dart modified successfully.")

def modify_home_screen():
    print("Modifying lib/features/home/home_screen.dart to pre-populate ingredients...")
    path = "lib/features/home/home_screen.dart"
    with open(path, "r", encoding="utf-8") as file:
        content = file.read()
        
    old_list = "  final List<String> _ingredients = [];"
    new_list = "  final List<String> _ingredients = ['Tavuk Göğsü', 'Domates', 'Soğan', 'Sarımsak', 'Tereyağı'];"
    
    content = content.replace(old_list, new_list)
    
    with open(path, "w", encoding="utf-8") as file:
        file.write(content)
    print("home_screen.dart modified successfully.")

def modify_recipes_screen():
    print("Modifying lib/features/recipes/recipes_screen.dart to inject mock recipes...")
    path = "lib/features/recipes/recipes_screen.dart"
    with open(path, "r", encoding="utf-8") as file:
        content = file.read()
        
    # We will replace the entire _buildRecipesStream method to bypass stream and render beautiful static cards
    # Let's locate the start of _buildRecipesStream
    # In recipes_screen.dart:
    # Widget _buildRecipesStream() { ... }
    # We will replace from the beginning of _buildRecipesStream down to the start of _buildRecipeGrid
    
    target_start = "  Widget _buildRecipesStream() {"
    # We'll replace the full method with our mocked method
    mock_method = """  Widget _buildRecipesStream() {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final List<Map<String, dynamic>> mockRecipes = [
      {
        'id': '1',
        'title': 'Köz Patlıcanlı Vejetaryen Lazanya',
        'category': 'Vejetaryen',
        'prepTime': '35 dk',
        'calories': '280 kcal',
        'imageUrl': 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=500&auto=format&fit=crop&q=60',
        'description': 'Közlenmiş patlıcan dilimleri ve ev yapımı domates sosu ile hafifletilmiş nefis İtalyan klasiği.',
      },
      {
        'id': '2',
        'title': 'Fırında Sarımsaklı Soslu Levrek',
        'category': 'Deniz Ürünleri',
        'prepTime': '25 dk',
        'calories': '320 kcal',
        'imageUrl': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=500&auto=format&fit=crop&q=60',
        'description': 'Ege otları ve zeytinyağlı marine sosu ile taptaze fırınlanmış çıtır levrek.',
      },
      {
        'id': '3',
        'title': 'Çıtır Nohutlu Avokado Salata',
        'category': 'Sağlıklı Yaşam',
        'prepTime': '15 dk',
        'calories': '240 kcal',
        'imageUrl': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&auto=format&fit=crop&q=60',
        'description': 'Fırınlanmış baharatlı nohutlar, avokado dilimleri ve nar ekşili sos eşliğinde protein deposu.',
      },
      {
        'id': '4',
        'title': 'Çilekli Chia Puding',
        'category': 'Fit Tatlılar',
        'prepTime': '10 dk',
        'calories': '180 kcal',
        'imageUrl': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=500&auto=format&fit=crop&q=60',
        'description': 'Hindistan cevizi sütü ile jelleştirilmiş chia tohumları ve taze çilek püresi.',
      }
    ];

    final featuredItem = mockRecipes.first;
    final listItems = mockRecipes.sublist(1);

    return Column(
      children: [
        _buildFeaturedRecipeCard(featuredItem),
        const SizedBox(height: 20),
        _buildRecipeGrid(listItems),
      ],
    );
  }"""
  
    # Find _buildRecipesStream in content and replace it
    # We will search for _buildRecipesStream and cut up to Widget _buildRecipeGrid
    split_term = "  Widget _buildRecipeGrid"
    if target_start in content and split_term in content:
        parts = content.split(target_start)
        post_part = parts[1].split(split_term)
        # Re-assemble
        content = parts[0] + mock_method + "\n\n" + split_term + post_part[1]
        print("Successfully injected mock recipes inside recipes_screen.dart!")
    else:
        print("Warning: Could not replace _buildRecipesStream method using splitting!")
        
    with open(path, "w", encoding="utf-8") as file:
        file.write(content)

def modify_profile_screen():
    print("Modifying lib/features/profile/profile_screen.dart for static profile statistics & badges...")
    path = "lib/features/profile/profile_screen.dart"
    with open(path, "r", encoding="utf-8") as file:
        content = file.read()
        
    # Replace _loadUserData
    old_load = """  Future<void> _loadUserData() async {
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
  }"""
  
    new_load = """  Future<void> _loadUserData() async {
    setState(() {
      _email = 'emirhan@auracook.com';
      _name = 'Emirhan Dalgıran';
      _photoUrl = 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=200&auto=format&fit=crop&q=60';
    });
  }"""
  
    content = content.replace(old_load, new_load)
    
    # Replace _buildStatsRow with mocked static data
    old_stats_start = "  Widget _buildStatsRow() {"
    mock_stats = """  Widget _buildStatsRow() {
    final isTr = ref.watch(localeProvider) == 'tr';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text('128', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              const SizedBox(height: 4),
              Text(isTr ? 'Takipçi' : 'Followers', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
            ],
          ),
          Container(width: 1, height: 30, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          Column(
            children: [
              Text('45', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              const SizedBox(height: 4),
              Text(isTr ? 'Takip Edilen' : 'Following', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
            ],
          ),
          Container(width: 1, height: 30, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          Column(
            children: [
              Text('12', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              const SizedBox(height: 4),
              Text(isTr ? 'Tarifler' : 'Recipes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }"""

    # Replace _buildBadgesRow with mocked static data
    old_badges_start = "  Widget _buildBadgesRow() {"
    mock_badges = """  Widget _buildBadgesRow() {
    final isTr = ref.watch(localeProvider) == 'tr';
    final List<Map<String, String>> mockBadges = [
      {'icon': '🍳', 'title': isTr ? 'Tarif Kaşifi' : 'Recipe Explorer', 'desc': isTr ? '5 farklı yapay zekâ tarifi denendi' : 'Tried 5 different AI recipes'},
      {'icon': '🌱', 'title': isTr ? 'Aura Ustası' : 'Aura Master', 'desc': isTr ? 'Karbon tasarrufunda seviye 5' : 'Level 5 in carbon savings'},
      {'icon': '🔥', 'title': isTr ? 'Azimli Şef' : 'Determined Chef', 'desc': isTr ? '7 gün üst üste uygulamaya giriş yapıldı' : 'Logged into the app 7 days in a row'},
    ];

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
            children: mockBadges.map((badge) {
              return Tooltip(
                message: badge['desc']!,
                triggerMode: TooltipTriggerMode.tap,
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
                      Text(badge['icon']!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        badge['title']!,
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
  }"""

    # Split and replace stats row
    if old_stats_start in content:
        parts = content.split(old_stats_start)
        # Find next method declaration to cut the rest
        next_term = "  Widget _buildStatColumn"
        if next_term in parts[1]:
            subparts = parts[1].split(next_term)
            content = parts[0] + mock_stats + "\n\n" + next_term + subparts[1]
            
    # Split and replace badges row
    if old_badges_start in content:
        parts = content.split(old_badges_start)
        next_term = "  Widget _buildStatColumn"
        if next_term in parts[1]:
            subparts = parts[1].split(next_term)
            content = parts[0] + mock_badges + "\n\n" + next_term + subparts[1]
        else:
            # try next method build
            next_term_2 = "  @override\n  Widget build"
            if next_term_2 in parts[1]:
                subparts = parts[1].split(next_term_2)
                content = parts[0] + mock_badges + "\n\n" + next_term_2 + subparts[1]

    with open(path, "w", encoding="utf-8") as file:
        file.write(content)
    print("profile_screen.dart modified successfully.")

def modify_social_screen():
    print("Modifying lib/features/social/social_screen.dart to inject mock social posts...")
    path = "lib/features/social/social_screen.dart"
    with open(path, "r", encoding="utf-8") as file:
        content = file.read()
        
    old_body = """  Widget _buildBody() {
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
  }"""

    new_body = """  Widget _buildBody() {
    final List<Map<String, dynamic>> mockPosts = [
      {
        'id': 'stock_1',
        'userId': 'stock_1',
        'authorName': 'Şef Suna',
        'authorLetter': 'S',
        'authorAvatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&auto=format&fit=crop&q=60',
        'title': 'Köz Biberli Ev Pizzası 🍕',
        'description': 'Bahçeden taze topladığım kırmızı köz biberler ve ev yapımı ekşi maya ile sıfır atık pizza şöleni! 24 saat soğuk mayalandırma yaptım.',
        'imageUrl': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
        'likesCount': 142,
        'commentsCount': 8,
        'likedBy': [],
      },
      {
        'id': 'stock_2',
        'userId': 'stock_2',
        'authorName': 'Burak K.',
        'authorLetter': 'B',
        'authorAvatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=60',
        'title': 'Nefis Fırın Mantar 🍄',
        'description': 'Kalan peynirleri değerlendirerek fırınladığım nefis sarımsaklı ve kekikli kaşarlı dolgulu mantarlarım. 15 dakikada hazır!',
        'imageUrl': 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=800&q=80',
        'likesCount': 96,
        'commentsCount': 3,
        'likedBy': [],
      }
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      itemCount: mockPosts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _socialActionsMock(),
              const SizedBox(height: 24),
            ],
          );
        }

        final data = mockPosts[index - 1];
        final postId = data['id'];

        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: _buildPostCard(
            postId: postId,
            authorId: data['userId'] ?? '',
            avatarLetter: data['authorLetter'] ?? 'Ş',
            authorAvatar: data['authorAvatar'] ?? '',
            name: data['authorName'] ?? 'Aura Şefi',
            timeAgo: '2 saat önce',
            imageUrl: data['imageUrl'] ?? '',
            title: data['title'] ?? 'İsimsiz Tarif',
            description: data['description'] ?? '',
            likeCount: data['likesCount'] ?? 0,
            commentCount: data['commentsCount'] ?? 0,
            isLiked: false,
          ),
        );
      },
    );
  }

  Widget _socialActionsMock() {
    return Row(
      children: [
        Expanded(
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
        const SizedBox(width: 10),
        Expanded(
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
      ],
    );
  }"""
  
    content = content.replace(old_body, new_body)
    
    with open(path, "w", encoding="utf-8") as file:
        file.write(content)
    print("social_screen.dart modified successfully.")

def compile_web():
    print("Compiling Flutter web app in release mode...")
    cmd = ["flutter", "build", "web", "--release", "--no-tree-shake-icons"]
    res = subprocess.run(cmd, shell=True)
    if res.returncode != 0:
        print("Error compiling web app!")
        sys.exit(1)
    print("Flutter web app compiled successfully.")

def capture_screenshots():
    # Start local Python HTTP server on port 8080
    print("Starting local HTTP server...")
    server = subprocess.Popen(
        ["python", "-m", "http.server", "8080", "--directory", "build/web"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    time.sleep(2)  # Wait for server to start
    
    # Views to capture
    views = [
        {"url": "http://localhost:8080/?screen=onboarding", "out": "screenshot_onboarding.png"},
        {"url": "http://localhost:8080/?screen=home&tab=0", "out": "screenshot_fridge.png"},
        {"url": "http://localhost:8080/?screen=home&tab=1", "out": "screenshot_chef.png"},
        {"url": "http://localhost:8080/?screen=home&tab=3", "out": "screenshot_social.png"},
        {"url": "http://localhost:8080/?screen=home&tab=5", "out": "screenshot_profile.png"}
    ]
    
    out_dir = os.path.join("assets", "images")
    os.makedirs(out_dir, exist_ok=True)
    
    print("Taking automated screenshots via Selenium WebDriver...")
    from selenium import webdriver
    from selenium.webdriver.chrome.options import Options
    
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--window-size=540,1200") # High-res Samsung Galaxy S20 aspect ratio (9:20)
    chrome_options.add_argument("--hide-scrollbars")
    
    try:
        driver = webdriver.Chrome(options=chrome_options)
        driver.set_window_size(540, 1200) # Force exact S20 aspect ratio viewport
        for idx, view in enumerate(views):
            out_path = os.path.abspath(os.path.join(out_dir, view["out"]))
            print(f"Capturing via Selenium: {view['url']} -> {out_path}")
            driver.get(view["url"])
            
            # Wait 10 seconds for CanvasKit to initialize, load assets, and completely boot the Flutter engine
            print("Waiting 10 seconds for Flutter CanvasKit compilation and page render...")
            time.sleep(10)
            
            driver.save_screenshot(out_path)
            print(f"Captured screen {idx+1}/5.")
            
        driver.quit()
        print("All screenshots taken successfully via Selenium.")
    except Exception as e:
        print("Error capturing via Selenium:", e)
    finally:
        server.terminate()

def copy_raw_to_desktop():
    print("Copying raw screenshots to user's Desktop folder...")
    desktop_dir = r"C:\Users\Emirhan\Desktop\auracook_raw_screenshots"
    os.makedirs(desktop_dir, exist_ok=True)
    
    raw_files = [
        "screenshot_onboarding.png",
        "screenshot_fridge.png",
        "screenshot_chef.png",
        "screenshot_social.png",
        "screenshot_profile.png"
    ]
    
    src_dir = os.path.join("assets", "images")
    
    for f in raw_files:
        src_path = os.path.join(src_dir, f)
        dest_path = os.path.join(desktop_dir, f)
        if os.path.exists(src_path):
            shutil.copyfile(src_path, dest_path)
            print(f"Copied raw screenshot: {dest_path}")
        else:
            print(f"Warning: Raw screenshot not found for copy: {src_path}")

def main():
    try:
        backup_files()
        modify_main_dart()
        modify_main_navigation()
        modify_home_screen()
        modify_recipes_screen()
        modify_profile_screen()
        modify_social_screen()
        
        compile_web()
        capture_screenshots()
        copy_raw_to_desktop()
        
    finally:
        restore_files()
        
    # Now run mockup generator!
    print("\nRunning mockup generator to wrap raw screenshots in premium text-free Play Store templates...")
    subprocess.run(["python", "generate_mockups.py"])
    print("\nMockups ready! Everything completed with ZERO manual action needed!")

if __name__ == "__main__":
    main()