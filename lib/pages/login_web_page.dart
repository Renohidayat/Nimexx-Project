import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';

class WelcomeToLoginPage extends StatefulWidget {
  const WelcomeToLoginPage({super.key});

  @override
  State<WelcomeToLoginPage> createState() => _WelcomeToLoginPageState();
}

class _WelcomeToLoginPageState extends State<WelcomeToLoginPage>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  final TapGestureRecognizer _privacyPolicyRecognizer = TapGestureRecognizer();

  late AnimationController _welcomeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _onboardingAnimController;
  late Animation<double> _imageOpacity;
  late Animation<Offset> _imageOffset;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textOffset;

  bool _showOnboarding = false;
  bool _showLogin = false;
  int _currentPage = 0;
  bool _isAnimating = false;
  bool _isLoading = false;

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

    _privacyPolicyRecognizer.onTap = () async {
      final url = Uri.parse('https://nimexx.web.app/privacy');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka Privacy Policy')),
          );
        }
      }
    };

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

  void _startOnboarding() {
    setState(() => _showOnboarding = true);
    _onboardingAnimController.forward();
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
      setState(() {
        _showLogin = true;
      });
    }

    _isAnimating = false;
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (user != null) {
        // 🔍 Cek apakah akun diblokir oleh admin
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        final isBanned = userDoc.data()?['isBanned'] == true;

        if (isBanned) {
          await _authService.signOut();

          // ❌ Tampilkan pop-up akun diblokir
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

        // ✅ Lanjutkan ke halaman utama
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ Login sukses!")));
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Login gagal/dibatalkan")),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("Error"),
                content: Text("❌ Terjadi error: $e"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _privacyPolicyRecognizer.dispose();
    _welcomeController.dispose();
    _onboardingAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Ubah dari Colors.black
      body: Stack(
        children: [
          // Letakkan animasi background di bawah semua konten
          Positioned.fill(child: AnimatedBackground()),

          // Konten utama
          _showLogin
              ? _buildLoginPage()
              : _showOnboarding
              ? _buildOnboardingContent()
              : _buildWelcomeContent(),
        ],
      ),
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
    return Stack(
      children: [
        // Animated background with floating shapes
        Positioned.fill(child: AnimatedBackground()),

        Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo/Icon
                  const Icon(
                    Icons.movie_filter_rounded,
                    size: 60,
                    color: Color.fromARGB(255, 255, 0, 0),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Welcome to NimeXx',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 30, 0),
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    'Login to start streaming your favorite anime!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  AnimatedButton(
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 24),

                  // Privacy Policy
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                      children: [
                        const TextSpan(
                          text: 'By logging in, you agree to our ',
                        ),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 58, 91, 183),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: _privacyPolicyRecognizer,
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom animated button widget
class AnimatedButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const AnimatedButton({Key? key, required this.isLoading, this.onPressed})
    : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton.icon(
            icon:
                widget.isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.login, color: Colors.white),
            label: Text(
              widget.isLoading ? "Logging in..." : "Sign in with Google",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                fontSize: 16,
              ),
            ),
            onPressed: widget.onPressed,
            onHover: (isHovering) {
              if (isHovering) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(double.infinity, 56),
              elevation: 5,
              shadowColor: const Color.fromARGB(
                255,
                255,
                0,
                0,
              ).withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Animated background with floating shapes

class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // Initialize particles
    final random = Random();
    particles = List.generate(50, (index) {
      return Particle(
        size: random.nextDouble() * 4 + 2, // Ukuran 2-6
        speed: random.nextDouble() * 0.5 + 0.1,
        position: Offset(random.nextDouble(), random.nextDouble()),
        color: Colors.deepOrange.withOpacity(random.nextDouble() * 0.5 + 0.3),
        direction: random.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: Colors.black, // Background hitam solid
          child: CustomPaint(
            painter: ParticlePainter(
              controllerValue: _controller.value,
              particles: particles,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ParticlePainter extends CustomPainter {
  final double controllerValue;
  final List<Particle> particles;

  ParticlePainter({required this.controllerValue, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    // Gambar semua partikel
    for (var particle in particles) {
      final posX =
          (particle.position.dx +
              sin(controllerValue * particle.speed + particle.direction) *
                  0.3) *
          size.width;
      final posY =
          (particle.position.dy +
              cos(controllerValue * particle.speed + particle.direction) *
                  0.3) *
          size.height;

      final paint =
          Paint()
            ..color = particle.color
            ..style = PaintingStyle.fill;

      // Gambar partikel sebagai lingkaran
      canvas.drawCircle(Offset(posX, posY), particle.size, paint);

      // Tambahkan efek glow/aura
      if (particle.size > 3) {
        canvas.drawCircle(
          Offset(posX, posY),
          particle.size * 1.5,
          paint..color = particle.color.withOpacity(0.1),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  final double size;
  final double speed;
  final Offset position;
  final Color color;
  final double direction;

  Particle({
    required this.size,
    required this.speed,
    required this.position,
    required this.color,
    required this.direction,
  });
}
