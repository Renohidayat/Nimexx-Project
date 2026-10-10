import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/remote_config_service.dart';
import '../model/release_schedule.dart';
import '../service/anime_service.dart';
import 'anime_detail_page.dart';
import '../widgets/web_app_bar.dart';
import '../widgets/footer_widget.dart';
import '../widgets/anime_loading_screens.dart';

class ReleaseSchedulePage extends StatefulWidget {
  const ReleaseSchedulePage({super.key});

  @override
  State<ReleaseSchedulePage> createState() => _ReleaseSchedulePageState();
}

class _ReleaseSchedulePageState extends State<ReleaseSchedulePage> {
  final AnimeService _service = AnimeService();
  late Future<List<ReleaseSchedule>> _futureSchedule;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _futureSchedule = _service.fetchSchedule();
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
        Navigator.pushNamed(context, '/ongoing');
        break;
      case 4:
        Navigator.pushNamed(context, '/genre');
        break;
      case 5:
        Navigator.pushNamed(context, '/search');
        break;
    }
  }

  Map<String, List<ReleaseSchedule>> groupByDay(List<ReleaseSchedule> list) {
    final Map<String, List<ReleaseSchedule>> grouped = {};
    for (var item in list) {
      final day = item.updatedDay.isNotEmpty ? item.updatedDay : 'Lainnya';
      grouped.putIfAbsent(day, () => []).add(item);
    }
    return grouped;
  }

  int calculateCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 6;
    if (width >= 1100) return 5;
    if (width >= 800) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
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
      body: // Update bagian FutureBuilder di ReleaseSchedulePage
          FutureBuilder<List<ReleaseSchedule>>(
        future: _futureSchedule,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ModernLoadingScreens.buildLoadingScreen(
              selectedIndex: _selectedIndex,
              onMenuSelected: _handleMenuSelected,
            );
          }
          else if (snapshot.hasError) {
            return ModernLoadingScreens.buildErrorScreen(
              snapshot.error.toString(),
              selectedIndex: _selectedIndex,
              onMenuSelected: _handleMenuSelected,
              onRetry: () {
                setState(() {
                  _futureSchedule = _service.fetchSchedule();
                });
              },
            );
          }
          // Jika tidak ada data
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ModernLoadingScreens.buildNoDataScreen(
              selectedIndex: _selectedIndex,
              onMenuSelected: _handleMenuSelected,
            );
          }

          // ... rest of your existing code

          final schedules = snapshot.data!;
          final grouped = groupByDay(schedules);
          const sortedDays = [
            'Senin',
            'Selasa',
            'Rabu',
            'Kamis',
            'Jumat',
            'Sabtu',
            'Minggu',
          ];

          return CustomScrollView(
            slivers: [
              // Tampilkan WebAppBar hanya jika web
              if (kIsWeb)
                SliverToBoxAdapter(
                  child: WebAppBar(
                    selectedIndex: _selectedIndex,
                    onSelected: _handleMenuSelected,
                  ),
                ),

              // Judul utama
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JADWAL RILIS ANIME',
                        style: GoogleFonts.oswald(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(width: 60, height: 3, color: Colors.orange),
                    ],
                  ),
                ),
              ),

              // List berdasarkan hari
              ...sortedDays.map((day) {
                final animeList = grouped[day] ?? [];
                if (animeList.isEmpty) return const SliverToBoxAdapter();

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 30, bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 30,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                day.toUpperCase(),
                                style: GoogleFonts.oswald(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final count = calculateCrossAxisCount(context);
                            const spacing = 16.0;
                            final totalSpacing = spacing * (count - 1);
                            final cardWidth =
                                (constraints.maxWidth - totalSpacing) / count;
                            const aspectRatio = 0.68;
                            final cardHeight = cardWidth / aspectRatio + 48;

                            return GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: count,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: 24,
                                    childAspectRatio: cardWidth / cardHeight,
                                  ),
                              itemCount: animeList.length,
                              itemBuilder: (context, index) {
                                final schedule = animeList[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AnimeDetailPage(
                                              endpoint: schedule.endpoint,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AspectRatio(
                                        aspectRatio: aspectRatio,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.network(
                                            schedule.proxyThumb(
                                              RemoteConfigService.baseUrl,
                                            ),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      color: Colors.grey[900],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 40,
                                        child: Text(
                                          schedule.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              if (kIsWeb) const SliverToBoxAdapter(child: FooterWidget()),
            ],
          );
        },
      ),
    );
  }
}
