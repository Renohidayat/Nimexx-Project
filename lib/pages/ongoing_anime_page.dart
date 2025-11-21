import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/ongoing_anime.dart';
import '../service/anime_service.dart';
import 'anime_detail_page.dart';
import '../widgets/web_app_bar.dart';
import '../widgets/footer_widget.dart';
import 'package:flutter/services.dart';
import '../service/remote_config_service.dart'; // pastikan ini diimport
import '../widgets/anime_loading_screens.dart';

class OngoingAnimePage extends StatefulWidget {
  const OngoingAnimePage({super.key});

  @override
  State<OngoingAnimePage> createState() => _OngoingAnimePageState();
}

class _OngoingAnimePageState extends State<OngoingAnimePage> {
  static const int _maxPage = 4;
  final Map<int, List<OngoingAnime>> _cache = {};
  int _page = 1;
  bool _busy = false;
  late Future<List<OngoingAnime>> _future;
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black, // pastikan status bar hitam
        statusBarIconBrightness: Brightness.light, // ikon status bar putih
      ),
    );

    _load(_page);
  }

  void _load(int p) {
    if (_busy || p < 1 || p > _maxPage) return;

    if (_cache.containsKey(p)) {
      setState(() {
        _page = p;
        _future = Future.value(_cache[p]);
      });
      return;
    }

    setState(() => _busy = true);

    _future = AnimeService()
        .fetchOngoingAnime(p)
        .then((list) => _cache[p] = list)
        .whenComplete(() {
          setState(() {
            _page = p;
            _busy = false;
          });
        });
  }

  void _handleMenuSelected(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1:
        Navigator.pushNamed(context, '/list');
        break;
      case 2:
        Navigator.pushNamed(context, '/schedule');
        break;
      case 3:
        break;
      case 4:
        Navigator.pushNamed(context, '/genre');
        break;
      case 5:
        Navigator.pushNamed(context, '/search');
        break;
    }
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1200) return 6;
    if (width >= 992) return 5;
    if (width >= 768) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final crossAxisCount = _calculateCrossAxisCount(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          !kIsWeb
              ? AppBar(
                backgroundColor: Colors.black,
                elevation: 2,
                title: Text(
                  'NimeXx',
                  style: GoogleFonts.oswald(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              )
              : null,
      body: FutureBuilder<List<OngoingAnime>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ModernLoadingScreens.buildLoadingScreen(
              selectedIndex: _selectedIndex,
              onMenuSelected: _handleMenuSelected,
            );
          }
          // Jika tidak ada data
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ModernLoadingScreens.buildNoDataScreen(
              selectedIndex: _selectedIndex,
              onMenuSelected: _handleMenuSelected,
            );
          }

          final list = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              if (kIsWeb)
                SliverToBoxAdapter(
                  child: WebAppBar(
                    selectedIndex: _selectedIndex,
                    onSelected: _handleMenuSelected,
                  ),
                ),

              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 60,
                  vertical: 20,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12 : 40,
                      ),
                      child: Text(
                        'ON-GOING ANIME',
                        style: GoogleFonts.oswald(
                          fontSize: isMobile ? 22 : 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: isMobile ? 90 : 120,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ]),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _AnimeCard(anime: list[i]),
                    childCount: list.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: isMobile ? 20 : 40,
                    crossAxisSpacing: isMobile ? 12 : 30,
                    childAspectRatio: isMobile ? 0.58 : 0.6,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 60,
                    vertical: 40,
                  ),
                  child: _Pagination(
                    page: _page,
                    max: _maxPage,
                    busy: _busy,
                    onJump: _load,
                  ),
                ),
              ),

              if (kIsWeb) const SliverToBoxAdapter(child: FooterWidget()),
            ],
          );
        },
      ),
    );
  }
}

class _AnimeCard extends StatelessWidget {
  final OngoingAnime anime;
  const _AnimeCard({required this.anime});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnimeDetailPage(endpoint: anime.endpoint),
                ),
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 0.65,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        anime.proxyThumb(
                          RemoteConfigService.baseUrl,
                        ), // ✅ ambil dari Remote Config
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) =>
                                const ColoredBox(color: Colors.grey),
                      ),

                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(6),
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'ON-GOING',
                              style: GoogleFonts.oswald(
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[800],
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(6),
                            ),
                          ),
                          child: Text(
                            ' ${anime.totalEpisode}',
                            style: GoogleFonts.oswald(
                              textStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Bungkus Text dengan Flexible agar bisa turun dan tidak overflow
              Flexible(
                child: Text(
                  anime.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int page;
  final int max;
  final bool busy;
  final ValueChanged<int> onJump;

  const _Pagination({
    required this.page,
    required this.max,
    required this.busy,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    const maxButtons = 3;
    int half = (maxButtons / 2).floor();
    int start = (page - half).clamp(1, max);
    int end = (start + maxButtons - 1).clamp(1, max);
    if (end - start + 1 < maxButtons) {
      start = (end - maxButtons + 1).clamp(1, max);
    }

    List<Widget> btns = [
      _labelBtn('Pages'),
      _flatBtn(
        label: '←',
        enabled: page > 1 && !busy,
        onPressed: () => onJump(page - 1),
      ),
      if (start > 1) _ellipsis(onJump, 1),
      for (int i = start; i <= end; i++) _numBtn(i, i == page, busy, onJump),
      if (end < max) _ellipsis(onJump, max),
      _flatBtn(
        label: '→',
        enabled: page < max && !busy,
        onPressed: () => onJump(page + 1),
      ),
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: btns,
          ),
        ),
      ),
    );
  }

  Widget _labelBtn(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _numBtn(int num, bool selected, bool busy, ValueChanged<int> onJump) {
    return InkWell(
      onTap: selected || busy ? null : () => onJump(num),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.orange : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          num.toString(),
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _ellipsis(ValueChanged<int> onJump, int page) {
    return InkWell(
      onTap: () => onJump(page),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '...',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _flatBtn({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? Colors.grey[200] : Colors.grey[400],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.black : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
