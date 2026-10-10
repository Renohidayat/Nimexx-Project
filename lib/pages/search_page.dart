import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_fonts/google_fonts.dart'; // Add this import
import '../model/search_anime_item.dart';
import '../service/anime_service.dart';
import 'anime_detail_page.dart';
import '../service/remote_config_service.dart';
import 'genre_anime_page.dart';
import 'ongoing_anime_page.dart';
import 'completed_anime_page.dart';
import '../model/genre_model.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final _inputCtrl = TextEditingController();
  final _queryStream = BehaviorSubject<String>();
  final _focusNode = FocusNode();
  late final StreamSubscription _listener;
  late final AnimationController _animationController;
  late final Animation<double> _slideAnimation;

  Future<List<SearchAnimeItem>>? _future;
  Future<List<GenreModel>>? _genresFuture;
  bool _isSearching = false;

  bool get _isWeb => MediaQuery.of(context).size.width > 900;
  bool get _isTablet =>
      MediaQuery.of(context).size.width > 600 &&
      MediaQuery.of(context).size.width <= 900;

  @override
  void initState() {
    super.initState();
    _genresFuture = AnimeService().fetchGenres();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    _listener = _queryStream
        .map(_normalize)
        .where((q) => q.length >= 3)
        .distinct()
        .debounceTime(const Duration(milliseconds: 300))
        .listen(_search);

    _inputCtrl.addListener(() => setState(() {}));
  }

  static String _normalize(String q) =>
      q.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();

  void _search(String q) {
    if (!mounted) return;
    setState(() {
      _future = AnimeService().searchAnime(q);
      _isSearching = true;
    });
    _animationController.forward();
  }

  void _clearSearch() {
    _inputCtrl.clear();
    _focusNode.requestFocus();
    setState(() {
      _future = null;
      _isSearching = false;
    });
    _animationController.reset();
  }

  @override
  void dispose() {
    _listener.cancel();
    _queryStream.close();
    _inputCtrl.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Changed to black background
      body: _isWeb ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        // Sidebar atau spacing kiri
        if (_isWeb) const SizedBox(width: 80),

        // Content utama
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: CustomScrollView(
                slivers: [
                  _buildWebAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    sliver: SliverToBoxAdapter(child: _buildContent()),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Spacing kanan
        if (_isWeb) const SizedBox(width: 80),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        _buildMobileAppBar(),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: _isTablet ? 24 : 16,
            vertical: 8,
          ),
          sliver: SliverToBoxAdapter(child: _buildContent()),
        ),
      ],
    );
  }

  Widget _buildWebAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.black, // Changed to black
      automaticallyImplyLeading: false,
      toolbarHeight: 100,
      flexibleSpace: Container(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
        child: SafeArea(
          child: Row(
            children: [
              // Custom back button untuk web
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                iconSize: 24,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[900], // Dark background
                  foregroundColor: Colors.white, // White icon
                  minimumSize: const Size(48, 48),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildSearchField()),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: Colors.grey[800], // Dark divider
        ),
      ),
    );
  }

  Widget _buildMobileAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.black, // Changed to black
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
        style: IconButton.styleFrom(
          backgroundColor: Colors.grey[900], // Dark background
          foregroundColor: Colors.white, // White icon
        ),
      ),
      flexibleSpace: Container(
        padding: EdgeInsets.fromLTRB(_isTablet ? 80 : 64, 8, 16, 16),
        child: SafeArea(child: _buildSearchField()),
      ),
      toolbarHeight: 80,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: Colors.grey[800], // Dark divider
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: _isWeb ? 56 : 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.grey[900], // Dark background
        border: Border.all(
          color:
              _focusNode.hasFocus
                  ? const Color(0xFFFF5722) // Orange-red color
                  : Colors.transparent,
          width: 2,
        ),
        boxShadow:
            _focusNode.hasFocus
                ? [
                  BoxShadow(
                    color: const Color(
                      0xFFFF5722,
                    ).withOpacity(0.3), // Orange-red glow
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: TextField(
        controller: _inputCtrl,
        focusNode: _focusNode,
        style: TextStyle(
          color: Colors.white, // White text
          fontSize: _isWeb ? 18 : 16,
        ),
        decoration: InputDecoration(
          hintText: 'Cari anime favorit kamu...',
          hintStyle: TextStyle(
            color: Colors.grey[400], // Light grey hint
            fontSize: _isWeb ? 18 : 16,
          ),
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child:
                _isSearching
                    ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: const Color(0xFFFF5722), // Orange-red progress
                        ),
                      ),
                    )
                    : Icon(
                      Icons.search_rounded,
                      color: Colors.grey[400], // Light grey icon
                      size: _isWeb ? 28 : 24,
                    ),
          ),
          suffixIcon:
              _inputCtrl.text.isEmpty
                  ? null
                  : IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.grey[400], // Light grey icon
                      size: _isWeb ? 24 : 20,
                    ),
                    onPressed: _clearSearch,
                  ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: _isWeb ? 18 : 16,
          ),
        ),
        onChanged: _queryStream.add,
        onSubmitted: _search,
      ),
    );
  }

  Widget _buildContent() {
    if (_future == null) return _buildEmptyState();

    return FutureBuilder<List<SearchAnimeItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        _isSearching = false;

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final results = snapshot.data ?? [];
        return results.isEmpty
            ? _buildNoResultsState()
            : _buildResultsList(results);
      },
    );
  }

  Widget _buildEmptyState() {
    return _buildAdvancedFilters();
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isWeb ? 24 : 16,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eksplorasi Lanjutan',
            style: GoogleFonts.oswald(
              fontSize: _isWeb ? 24 : 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Temukan anime berdasarkan kategori atau status rilis.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          _buildFilterSection(
            title: 'Status Rilis',
            icon: Icons.movie_filter_rounded,
            chips: [
              _FilterChipData(
                label: 'Sedang Tayang (Ongoing)',
                color: Colors.green,
                icon: Icons.play_circle_fill_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OngoingAnimePage()),
                ),
              ),
              _FilterChipData(
                label: 'Sudah Tamat (Completed)',
                color: Colors.blue,
                icon: Icons.check_circle_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompletedAnimePage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(Icons.category_rounded, color: Colors.grey[400], size: 20),
              const SizedBox(width: 8),
              Text(
                'Berdasarkan Genre',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<GenreModel>>(
            future: _genresFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Color(0xFFFF5722)),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'Gagal memuat daftar genre',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }

              final genres = snapshot.data!;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: genres.map((genre) {
                  return ActionChip(
                    label: Text(genre.title),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: Colors.grey[850],
                    side: BorderSide(color: Colors.grey[800]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GenreAnimePage(
                            genreEndpoint: genre.endpoint,
                            genreTitle: genre.title,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required List<_FilterChipData> chips,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey[400], size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: chips.map((chip) {
            return InkWell(
              onTap: chip.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: chip.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: chip.color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chip.icon, color: chip.color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      chip.label,
                      style: TextStyle(
                        color: chip.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: _isWeb ? 400 : 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: _isWeb ? 48 : 36,
              height: _isWeb ? 48 : 36,
              child: CircularProgressIndicator(
                color: const Color(0xFFFF5722), // Orange-red progress
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: _isWeb ? 24 : 16),
            Text(
              'Mencari anime...',
              style: TextStyle(
                color: Colors.white70, // Light text
                fontSize: _isWeb ? 18 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return _buildCenteredState(
      icon: Icons.error_outline_rounded,
      iconColor: Colors.red[400],
      title: 'Terjadi Kesalahan',
      subtitle: 'Silakan coba lagi',
      action: FilledButton.icon(
        onPressed: () => _search(_inputCtrl.text),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Coba Lagi'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFF5722), // Orange-red button
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: _isWeb ? 32 : 24,
            vertical: _isWeb ? 16 : 12,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return _buildCenteredState(
      icon: Icons.search_off_rounded,
      title: 'Tidak Ada Hasil',
      subtitle: 'Coba kata kunci yang berbeda',
    );
  }

  Widget _buildCenteredState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    Widget? action,
  }) {
    return Container(
      height: _isWeb ? 400 : 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: _isWeb ? 80 : 64,
            color: iconColor ?? Colors.grey[600], // Light grey icon
          ),
          SizedBox(height: _isWeb ? 24 : 16),
          Text(
            title,
            style: GoogleFonts.oswald(
              // Changed to Oswald font
              fontSize: _isWeb ? 28 : 24,
              fontWeight: FontWeight.w600,
              color: Colors.white, // White text
            ),
          ),
          SizedBox(height: _isWeb ? 12 : 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: _isWeb ? 16 : 14,
              color: Colors.grey[400], // Light grey text
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[SizedBox(height: _isWeb ? 32 : 24), action],
        ],
      ),
    );
  }

  Widget _buildResultsList(List<SearchAnimeItem> results) {
    int crossAxisCount;
    double childAspectRatio;

    if (_isWeb) {
      crossAxisCount = 2;
      childAspectRatio = 3.5;
    } else if (_isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 3.0;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 2.8;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _slideAnimation,
        child:
            crossAxisCount == 1
                ? ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  separatorBuilder:
                      (_, __) => SizedBox(height: _isWeb ? 16 : 12),
                  itemBuilder: (_, i) => _SearchTile(item: results[i]),
                )
                : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: _isWeb ? 24 : 16,
                    mainAxisSpacing: _isWeb ? 16 : 12,
                  ),
                  itemCount: results.length,
                  itemBuilder: (_, i) => _SearchTile(item: results[i]),
                ),
      ),
    );
  }
}

class _SearchTile extends StatelessWidget {
  final SearchAnimeItem item;

  const _SearchTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    double imgSize;
    if (isWeb) {
      imgSize = 120;
    } else if (isTablet) {
      imgSize = 100;
    } else {
      imgSize = 80;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      color: Colors.grey[900], // Dark card background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        side: BorderSide(
          color: const Color(0xFFFF5722).withOpacity(0.3), // Orange-red border
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnimeDetailPage(endpoint: item.endpoint),
              ),
            ),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 16 : 12),
          child: Row(
            children: [
              Hero(
                tag: 'anime_${item.endpoint}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                  child: Container(
                    width: imgSize,
                    height: imgSize * 1.4,
                    color: Colors.grey[800], // Dark image placeholder
                    child: Image.network(
                      item.proxyThumb(RemoteConfigService.baseUrl),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: imgSize,
                          height: imgSize * 1.4,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(
                                0xFFFF5722,
                              ), // Orange-red progress
                            ),
                          ),
                        );
                      },
                      errorBuilder:
                          (_, __, ___) => Icon(
                            Icons.image_not_supported_rounded,
                            color: Colors.grey[500],
                            size: isWeb ? 32 : 24,
                          ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isWeb ? 20 : 12),
              Expanded(child: _AnimeInfo(item: item)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimeInfo extends StatelessWidget {
  final SearchAnimeItem item;

  const _AnimeInfo({required this.item});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            item.title,
            maxLines: isWeb ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style:
                isWeb
                    ? TextStyle(
                      fontSize: 16,
                      color: Colors.white, // White text
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    )
                    : TextStyle(
                      fontSize: 14,
                      color: Colors.white, // White text
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
          ),
        ),
        SizedBox(height: isWeb ? 8 : 6),
        if (item.genres.isNotEmpty)
          Flexible(
            child: Wrap(
              spacing: isWeb ? 8 : 6,
              runSpacing: 4,
              children:
                  item.genres
                      .take(isWeb ? 3 : 2)
                      .map(
                        (genre) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 10 : 8,
                            vertical: isWeb ? 3 : 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF5722,
                            ).withOpacity(0.2), // Orange-red background
                            borderRadius: BorderRadius.circular(
                              isWeb ? 14 : 12,
                            ),
                            border: Border.all(
                              color: const Color(
                                0xFFFF5722,
                              ).withOpacity(0.5), // Orange-red border
                              width: 1,
                            ),
                          ),
                          child: Text(
                            genre,
                            style: TextStyle(
                              fontSize: isWeb ? 12 : 10,
                              color: const Color(0xFFFF5722), // Orange-red text
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        SizedBox(height: isWeb ? 8 : 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: isWeb ? 18 : 16,
              color: Colors.amber[600],
            ),
            SizedBox(width: isWeb ? 4 : 3),
            Text(
              item.rating,
              style: TextStyle(
                fontSize: isWeb ? 14 : 12,
                color: Colors.white70, // Light white text
                fontWeight: FontWeight.w600,
              ),
            ),
            if (item.status.isNotEmpty) ...[
              SizedBox(width: isWeb ? 12 : 8),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 8 : 6,
                    vertical: isWeb ? 3 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[800], // Dark background
                    borderRadius: BorderRadius.circular(isWeb ? 10 : 8),
                    border: Border.all(
                      color: Colors.grey[600]!, // Grey border
                      width: 1,
                    ),
                  ),
                  child: Text(
                    item.status.first,
                    style: TextStyle(
                      fontSize: isWeb ? 12 : 10,
                      color: Colors.grey[300], // Light grey text
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _FilterChipData {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  _FilterChipData({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });
}
