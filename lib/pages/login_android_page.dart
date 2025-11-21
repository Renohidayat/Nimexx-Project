import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'privacy_policy_page.dart';

class WelcomeAndLoginAndroidPage extends StatefulWidget {
  const WelcomeAndLoginAndroidPage({super.key});

  @override
  State<WelcomeAndLoginAndroidPage> createState() =>
      _WelcomeAndLoginAndroidPageState();
}

class _WelcomeAndLoginAndroidPageState extends State<WelcomeAndLoginAndroidPage>
    with TickerProviderStateMixin {
  // Welcome animation
  late AnimationController _welcomeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Onboarding
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAnimating = false;
  late AnimationController _onboardingAnimController;
  late Animation<double> _imageOpacity;
  late Animation<Offset> _imageOffset;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textOffset;
  bool _showOnboarding = false;
  bool _showLogin = false;
  bool _hasStartedOnboarding = false;

  final _authService = AuthService();

  final List<Map<String, dynamic>> onboardingData = [
    {
      'image': 'assets/images/h2.png',
      'title': 'Fitur Canggih, Nonton Makin Seru!',
      'description':
          'Temukan anime favoritmu dengan cepat dan mudah. Rasakan sensasi baru nonton anime bareng Nimexx!',
      'descOnTop': true,
    },
    {
      'image': 'assets/images/h3.png',
      'title': 'Grafis Ultra, Kualitas Anak Sultan!',
      'description':
          'Gabungkan kualitas gambar terbaik dan pengalaman nonton yang halus banget. Nikmati episode favorit dengan kualitas sinematik tinggi!',
      'descOnTop': false,
    },
    {
      'image': 'assets/images/h4.png',
      'title': 'Simpan Anime',
      'description':
          'Simpan anime favoritmu dan akses dengan cepat di menu Favorit. Kamu nggak perlu cari-cari lagi!',
      'descOnTop': true,
    },
  ];

  @override
  void initState() {
    super.initState();

    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeOut),
    );

    _welcomeController.forward();

    _onboardingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _setupOnboardingAnimations();

    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? _currentPage;
      if (!_isAnimating && newPage != _currentPage) {
        setState(() => _currentPage = newPage);
        _onboardingAnimController.reset();
        _onboardingAnimController.forward();
      }
    });
  }

  void _setupOnboardingAnimations() {
    const curve = Curves.easeOutQuart;

    _imageOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _onboardingAnimController,
        curve: const Interval(0.0, 0.5, curve: curve),
      ),
    );
    _imageOffset = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _onboardingAnimController,
        curve: const Interval(0.0, 0.5, curve: curve),
      ),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _onboardingAnimController,
        curve: const Interval(0.3, 1.0, curve: curve),
      ),
    );
    _textOffset = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _onboardingAnimController,
        curve: const Interval(0.3, 1.0, curve: curve),
      ),
    );
  }

  Future<void> _nextPage() async {
    if (_isAnimating) return;
    _isAnimating = true;
    await _onboardingAnimController.reverse();

    if (_currentPage < onboardingData.length - 1) {
      setState(() => _currentPage += 1);
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
      await _onboardingAnimController.forward();
    } else {
      setState(() => _showLogin = true);
    }

    _isAnimating = false;
  }

  void _startOnboarding() {
    if (_hasStartedOnboarding) return;
    _hasStartedOnboarding = true;
    setState(() => _showOnboarding = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      _onboardingAnimController.forward();
    });
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    _onboardingAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _showLogin
              ? _buildLoginPage()
              : _showOnboarding
              ? _buildOnboardingContent()
              : _buildWelcomeContent(),
    );
  }

  Widget _buildWelcomeContent() {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/wibu.png', height: 300),
                  const SizedBox(height: 32),
                  const Text(
                    '"Hloo~ Siap Masuk Dunia Anime?"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sebelum mulai petualangan, yuk kenalan dulu\nsama Nimexx!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _startOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Ayo Mulai',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingContent() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: onboardingData.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = onboardingData[index];
              final descOnTop = item['descOnTop'] as bool;
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              descOnTop
                                  ? [
                                    _buildAnimatedText(item),
                                    const SizedBox(height: 32),
                                    _buildAnimatedImage(item),
                                  ]
                                  : [
                                    _buildAnimatedImage(item),
                                    const SizedBox(height: 32),
                                    _buildAnimatedText(item),
                                  ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildDotIndicator(),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildDotIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(onboardingData.length, (index) {
          final isActive = _currentPage == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.deepOrange : Colors.white30,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNextButton() {
    final isLastPage = _currentPage == onboardingData.length - 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 250),
        scale: isLastPage ? 1.1 : 1.0,
        child: GestureDetector(
          onTap: _nextPage,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepOrange,
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedImage(Map<String, dynamic> item) {
    return AnimatedBuilder(
      animation: _onboardingAnimController,
      builder: (_, __) {
        return Opacity(
          opacity: _imageOpacity.value,
          child: SlideTransition(
            position: _imageOffset,
            child: Image.asset(
              item['image'] as String,
              height: 280,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedText(Map<String, dynamic> item) {
    return AnimatedBuilder(
      animation: _onboardingAnimController,
      builder: (_, __) {
        return Opacity(
          opacity: _textOpacity.value,
          child: SlideTransition(
            position: _textOffset,
            child: Column(
              children: [
                Text(
                  item['title'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    item['description'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginPage() {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 2),
          const Text(
            'Login',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton(
              onPressed: () async {
                final user = await _authService.signInWithGoogle();
                if (user != null) {
                  final userDoc =
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get();

                  final isBanned = userDoc.data()?['isBanned'] == true;

                  if (isBanned) {
                    await _authService.signOut();
                    if (!mounted) return;

                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text("Akun Diblokir"),
                            content: const Text(
                              "🚫 Akun Anda telah diblokir oleh admin.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                    );
                    return;
                  }

                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Login sukses!")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("⚠️ Login dibatalkan atau gagal"),
                    ),
                  );
                }
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Sign in With Google',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Spacer(flex: 3),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Dengan Login anda berarti menyetujui\nPrivacy Policy',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Privacy Policy'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
