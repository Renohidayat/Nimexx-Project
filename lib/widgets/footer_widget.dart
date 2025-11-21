import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Container(
              width: double.infinity,
              color: const Color(0xFFD6D6D6),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical:
                    isMobile ? 16 : 40, // Reduced vertical padding for mobile
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child:
                      isMobile
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildFooterContent(isMobile: true),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildFooterContent(isMobile: false),
                          ),
                ),
              ),
            );
          },
        ),
        const Divider(height: 0, thickness: 1, color: Colors.grey),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6F00), Color(0xFFD32F2F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ), // Reduced padding
          width: double.infinity,
          child: const Text(
            "Rights reserved © Copyright 2025, Nimexx. Created using Flutter",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.4,
            ), // Reduced font size
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFooterContent({required bool isMobile}) {
    final sections = [
      {
        'title': "About",
        'content':
            "Streaming Anime Subtitle Indonesia Resolusi 360p, 480p, 720p.",
      },
      {
        'title': "Tips",
        'content': "Simpan dan bookmark halaman nimexx.web.app di HP kalian!",
      },
      {
        'title': "Info",
        'content':
            "Web dalam tahap pengembangan. Laporkan ke admin bila ada error.",
      },
    ];

    if (isMobile) {
      // Mobile: Column
      return sections
          .map(
            (section) => Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ), // Reduced vertical padding
              child: _footerSection(
                title: section['title']!,
                content: section['content']!,
              ),
            ),
          )
          .toList();
    } else {
      // Web: Row with spacing
      return sections.map((section) {
        return Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ), // Added horizontal padding
            child: _footerSection(
              title: section['title']!,
              content: section['content']!,
            ),
          ),
        );
      }).toList();
    }
  }

  Widget _footerSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16, // Reduced font size
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 100, // Adjusted width for better responsiveness
          color: const Color.fromARGB(255, 0, 0, 0),
        ),
        const SizedBox(height: 8), // Reduced spacing
        Text(
          content,
          style: const TextStyle(
            fontSize: 14, // Reduced font size
            color: Colors.black,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
