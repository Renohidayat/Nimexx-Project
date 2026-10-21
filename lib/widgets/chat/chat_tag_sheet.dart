import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../service/anime_service.dart';
import '../../model/search_anime_item.dart';
import '../../model/anime_detail.dart';

class ChatTagSheet extends StatefulWidget {
  final void Function(Map<String, dynamic> tagData) onTagSelected;

  const ChatTagSheet({super.key, required this.onTagSelected});

  @override
  State<ChatTagSheet> createState() => _ChatTagSheetState();
}

class _ChatTagSheetState extends State<ChatTagSheet> {
  final _searchCtrl = TextEditingController();
  final _animeService = AnimeService();
  
  Future<List<SearchAnimeItem>>? _searchFuture;
  SearchAnimeItem? _selectedAnime;
  Future<AnimeDetail>? _detailFuture;

  void _doSearch(String query) {
    if (query.length < 3) return;
    setState(() {
      _searchFuture = _animeService.searchAnime(query);
      _selectedAnime = null;
      _detailFuture = null;
    });
  }

  void _selectAnime(SearchAnimeItem anime) {
    setState(() {
      _selectedAnime = anime;
      _detailFuture = _animeService.fetchAnimeDetail(anime.endpoint);
    });
  }

  void _sendTag(String? episodeEndpoint, String? episodeTitle) {
    if (_selectedAnime == null) return;
    widget.onTagSelected({
      'seriesEndpoint': _selectedAnime!.endpoint,
      'seriesTitle': _selectedAnime!.title,
      'seriesThumb': _selectedAnime!.thumb,
      'episodeEndpoint': episodeEndpoint,
      'episodeTitle': episodeTitle,
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2A), // Slightly purplish dark like reference
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: _selectedAnime == null
                    ? _buildStep1Search(scrollCtrl)
                    : _buildStep2Episodes(scrollCtrl),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep1Search(ScrollController scrollCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.movie_rounded, color: Colors.deepPurpleAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tag series',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Cari judul, lalu pilih episode bila perlu',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A38),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Ketik judul anime...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (q) {
                if (q.length >= 3) _doSearch(q);
              },
              onSubmitted: _doSearch,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _searchFuture == null
              ? const SizedBox()
              : FutureBuilder<List<SearchAnimeItem>>(
                  future: _searchFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'Tidak ditemukan',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      );
                    }

                    final results = snapshot.data!;
                    return ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final anime = results[index];
                        return _buildSearchItem(anime);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchItem(SearchAnimeItem anime) {
    return InkWell(
      onTap: () => _selectAnime(anime),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                anime.thumb,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[800],
                  child: Icon(Icons.movie_rounded, color: Colors.grey[600]),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih episode >',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Episodes(ScrollController scrollCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => setState(() => _selectedAnime = null),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _selectedAnime!.thumb,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAnime!.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tag series ini atau salah satu episodenya',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tombol Tag Series Saja
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _sendTag(null, null),
              icon: const Icon(Icons.movie_filter_rounded),
              label: const Text('Tag series saja'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7), // Purple like reference
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'atau pilih episode',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<AnimeDetail>(
            future: _detailFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Text('Gagal memuat episode', style: TextStyle(color: Colors.grey[500])),
                );
              }

              final episodes = snapshot.data!.episodes;
              if (episodes.isEmpty) {
                return Center(
                  child: Text('Belum ada episode', style: TextStyle(color: Colors.grey[500])),
                );
              }

              return GridView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: episodes.length,
                itemBuilder: (context, index) {
                  final ep = episodes[index];
                  // Extract just the number or short text
                  var shortLabel = ep.title.replaceAll(RegExp(r'Episode\s+', caseSensitive: false), 'Eps ');
                  if (shortLabel.length > 10) {
                     shortLabel = 'Eps ${episodes.length - index}';
                  }

                  return InkWell(
                    onTap: () => _sendTag(ep.endpoint, ep.title),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        shortLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
