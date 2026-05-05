import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/app_widgets.dart';
import '../main_shell.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class _Article {
  final String title;
  final String section;
  final String thumbnail;
  final String url;
  final String date;
  final String snippet;

  _Article({
    required this.title,
    required this.section,
    required this.thumbnail,
    required this.url,
    required this.date,
    required this.snippet,
  });

  // Dari The Guardian API
  factory _Article.fromGuardian(Map<String, dynamic> json) {
    final fields = json['fields'] as Map<String, dynamic>? ?? {};
    return _Article(
      title: json['webTitle'] as String? ?? '',
      section: json['sectionName'] as String? ?? '',
      thumbnail: fields['thumbnail'] as String? ?? '',
      url: json['webUrl'] as String? ?? '',
      date: _formatDate(json['webPublicationDate'] as String? ?? ''),
      snippet: fields['trailText'] as String? ?? '',
    );
  }

  // Dari rss2json (Google News Indonesia)
  factory _Article.fromRss(Map<String, dynamic> json) {
    return _Article(
      title: json['title'] as String? ?? '',
      section: 'Indonesia',
      thumbnail: json['thumbnail'] as String? ?? '',
      url: json['link'] as String? ?? '',
      date: _formatDate(json['pubDate'] as String? ?? ''),
      snippet: '',
    );
  }

  static String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen>
    with SingleTickerProviderStateMixin {
  final Dio _dio = Dio();
  late TabController _tab;

  List<_Article> _international = [];
  List<_Article> _indonesia = [];

  bool _loadingIntl = true;
  bool _loadingId = true;
  String? _errorIntl;
  String? _errorId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _fetchInternational();
    _fetchIndonesia();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Fetch The Guardian ──────────────────────────────────────────────────────
  Future<void> _fetchInternational() async {
    setState(() {
      _loadingIntl = true;
      _errorIntl = null;
    });
    try {
      final url =
          'https://content.guardianapis.com/search'
          '?q=goat+farming+livestock'
          '&show-fields=thumbnail,trailText'
          '&page-size=20'
          '&order-by=newest'
          '&api-key=test';
      final res = await _dio.get(url);
      if (res.data['response']?['status'] == 'ok') {
        final results = res.data['response']['results'] as List;
        setState(() {
          _international =
              results.map((e) => _Article.fromGuardian(e)).toList();
          _loadingIntl = false;
        });
      } else {
        setState(() {
          _errorIntl = 'Gagal memuat berita internasional';
          _loadingIntl = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorIntl = 'Kesalahan jaringan: ${e.toString()}';
        _loadingIntl = false;
      });
    }
  }

  // ── Fetch Google News Indonesia via rss2json ────────────────────────────────
  Future<void> _fetchIndonesia() async {
    setState(() {
      _loadingId = true;
      _errorId = null;
    });
    try {
      const rssUrl =
          'https://news.google.com/rss/search?q=ternak+kambing&hl=id&gl=ID&ceid=ID:id';
      final url =
          'https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent(rssUrl)}';
      final res = await _dio.get(url);
      if (res.data['status'] == 'ok') {
        final items = res.data['items'] as List;
        setState(() {
          _indonesia = items.map((e) => _Article.fromRss(e)).toList();
          _loadingId = false;
        });
      } else {
        setState(() {
          _errorId = 'Gagal memuat berita Indonesia';
          _loadingId = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorId = 'Kesalahan jaringan: ${e.toString()}';
        _loadingId = false;
      });
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Info Peternakan',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.5),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => advancedDrawerController.showDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchInternational();
              _fetchIndonesia();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.public, size: 18), text: 'Internasional'),
            Tab(icon: Icon(Icons.flag, size: 18), text: 'Indonesia'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── Tab Internasional ──
          _buildArticleList(
            loading: _loadingIntl,
            error: _errorIntl,
            articles: _international,
            onRefresh: _fetchInternational,
            showImage: true,
          ),
          // ── Tab Indonesia ──
          _buildArticleList(
            loading: _loadingId,
            error: _errorId,
            articles: _indonesia,
            onRefresh: _fetchIndonesia,
            showImage: false,
          ),
        ],
      ),
    );
  }

  Widget _buildArticleList({
    required bool loading,
    required String? error,
    required List<_Article> articles,
    required Future<void> Function() onRefresh,
    required bool showImage,
  }) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return ErrorStateWidget(message: error, onRetry: onRefresh);
    }
    if (articles.isEmpty) {
      return const EmptyState(
        message: 'Tidak ada berita tersedia',
        icon: Icons.article_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics:
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        itemCount: articles.length,
        itemBuilder: (ctx, i) {
          final a = articles[i];
          return _ArticleCard(
            article: a,
            showImage: showImage,
            onTap: () => _launchUrl(a.url),
          ).animate().fade(delay: (i * 50).ms).slideX(begin: 0.05, curve: Curves.easeOut);
        },
      ),
    );
  }
}

// ─── Article Card ─────────────────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  final _Article article;
  final bool showImage;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.article,
    required this.showImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasThumb = article.thumbnail.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: showImage
              // ── Layout kartu internasional: gambar atas + teks bawah ──
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasThumb)
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(16)),
                        child: CachedNetworkImage(
                          imageUrl: article.thumbnail,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 180,
                            color: AppColors.primary.withOpacity(0.05),
                            child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 100,
                            color: AppColors.primary.withOpacity(0.05),
                            child: const Center(
                                child: Icon(Icons.image_not_supported_outlined,
                                    color: AppColors.textHint)),
                          ),
                        ),
                      ),
                    _buildTextContent(),
                  ],
                )
              // ── Layout kartu Indonesia: row (ikon kiri + teks kanan) ──
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.newspaper_outlined,
                            color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    article.date,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.section.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                article.section,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ),
          Text(
            article.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
                height: 1.3),
          ),
          if (article.snippet.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              article.snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(article.date,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              const Text(
                'Baca selengkapnya →',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
