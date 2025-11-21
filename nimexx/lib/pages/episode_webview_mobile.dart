import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EpisodeWebView extends StatefulWidget {
  final String url;

  const EpisodeWebView({Key? key, required this.url}) : super(key: key);

  @override
  State<EpisodeWebView> createState() => _EpisodeWebViewState();
}

class _EpisodeWebViewState extends State<EpisodeWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Aktifkan fullscreen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Inisialisasi controller WebView dengan params platform-specific
    final params = PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(params);

    // Setting controller
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
        const Color(0x00000000),
      ) // background transparan supaya ga ada flash putih
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (request) {
            // Izinkan semua navigasi
            return NavigationDecision.navigate;
          },
        ),
      );

    // Optimasi khusus Android: nonaktifkan zoom supaya UX video lebih baik
    if (Platform.isAndroid) {
      _controller.enableZoom(false);
      // Autoplay media akan di-handle via JS (bila perlu)
    }

    // Load URL awal
    _loadUrl(widget.url);
  }

  @override
  void dispose() {
    // Kembalikan UI mode seperti semula saat keluar halaman
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _loadUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme.startsWith('http')) {
        _controller.loadRequest(uri);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant EpisodeWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadUrl(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Tanpa AppBar, fullscreen, tanpa tombol back/judul
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
