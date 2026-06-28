import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final News news;
  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  String _fullText = "";
  bool _textLoading = true;
  final NewsService _service = NewsService();

  @override
  void initState() {
    super.initState();
    _loadFullText();
  }

  Future<void> _loadFullText() async {
    final text = await _service.getFullText(widget.news.url);
    if (!mounted) return;
    setState(() {
      _fullText = text;
      _textLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.news;
    final color = news.color;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Collapsible Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: news.pngUrl != null ? 280 : 120,
            pinned: true,
            backgroundColor: color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: news.pngUrl != null
                  ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    news.pngUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: color),
                  ),
                  // gradient so back button stays readable
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black38, Colors.transparent],
                        stops: [0, 0.5],
                      ),
                    ),
                  ),
                ],
              )
                  : Container(
                color: color,
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip + icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(News.iconForCategory(news.category),
                                size: 14, color: color),
                            const SizedBox(width: 6),
                            Text(
                              news.category,
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Headline
                  Text(
                    news.header,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider with label
                  Row(
                    children: [
                      Container(width: 4, height: 18, color: color,
                          margin: const EdgeInsets.only(right: 8)),
                      const Text("Full Article",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Article body
                  _textLoading
                      ? Column(
                    children: [
                      const CircularProgressIndicator(strokeWidth: 2),
                      const SizedBox(height: 12),
                      Text(
                        "Fetching article…",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  )
                      : SelectableText(
                    _fullText,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}