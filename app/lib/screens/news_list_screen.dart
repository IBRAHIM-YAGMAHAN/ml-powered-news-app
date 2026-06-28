import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import 'news_detail_screen.dart';

class _TabInfo {
  final String label;
  final IconData icon;
  const _TabInfo(this.label, this.icon);
}

const List<_TabInfo> _tabs = [
  _TabInfo("All News", Icons.newspaper),
  _TabInfo("World", Icons.public),
  _TabInfo("Sports", Icons.sports_soccer),
  _TabInfo("Business", Icons.trending_up),
  _TabInfo("Sci/Tech", Icons.memory),
];

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final NewsService _service = NewsService();

  // Her kategori için bağımsız durum
  final Map<String, _TabState> _tabStates = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Her kategori için state oluştur ve ilk yüklemeyi başlat
    for (final tab in _tabs) {
      _tabStates[tab.label] = _TabState();
    }
    _loadTab("All News");
    // Kullanıcı tab değiştirince o tab'ı ilk kez yükle
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final label = _tabs[_tabController.index].label;
        if (_tabStates[label]!.news.isEmpty && !_tabStates[label]!.loading) {
          _loadTab(label);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTab(String tab, {bool reset = false}) async {
    final state = _tabStates[tab]!;
    if (state.loading) return;

    if (reset) {
      setState(() {
        state.news.clear();
        state.page = 1;
        state.hasMore = true;
        state.error = null;
      });
    }

    setState(() => state.loading = true);

    final fetched = await _service.fetchByTab(tab, page: state.page);

    if (!mounted) return;

    setState(() {
      state.loading = false;
      if (fetched.isEmpty) {
        state.hasMore = false;
        if (state.news.isEmpty) {
          state.error = 'Could not load news. Check your connection.';
        }
      } else {
        state.news.addAll(fetched);
        state.page++;
        // GNews ücretsiz planda genellikle 10'dan fazla dönmez
        if (fetched.length < 10) state.hasMore = false;
      }
    });

    // "All News" tab'ında AI ile sınıflandır
    if (tab == "All News") {
      _classifyAllNews();
    }
  }
  // AI sınıflandırma — sadece "Analyzing..." olanlar için
  Future<void> _classifyAllNews() async {
    final news = _tabStates["All News"]!.news;
    for (int i = 0; i < news.length; i++) {
      if (!mounted) return;
      if (news[i].category != "Analyzing...") continue;
      final category = await _service.findCategory(news[i].header);
      if (!mounted) return;
      setState(() {
        news[i].category = category;
        news[i].color = News.colorForCategory(category);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 18),
            SizedBox(width: 8),
            Text("AI News Radar",
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: _tabs
              .map((t) => Tab(
            child: Row(children: [
              Icon(t.icon, size: 15),
              const SizedBox(width: 6),
              Text(t.label),
            ]),
          ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((t) => _buildTabView(t.label)).toList(),
      ),
    );
  }

  Widget _buildTabView(String tab) {
    final state = _tabStates[tab]!;

    if (state.loading && state.news.isEmpty) {
      return const _LoadingView();
    }

    if (state.error != null && state.news.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => _loadTab(tab, reset: true),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadTab(tab, reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
        itemCount: state.news.length + 1,
        itemBuilder: (ctx, i) {
          if (i == state.news.length) {
            return _buildBottomWidget(tab, state);
          }
          return _NewsCard(news: state.news[i]);
        },
      ),
    );
  }

  Widget _buildBottomWidget(String tab, _TabState state) {
    if (state.loading) {
      // Yeni sayfa yüklenirken spinner
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: CircularProgressIndicator(
                color: Colors.deepPurple, strokeWidth: 2)),
      );
    }

    if (state.hasMore) {
      // "Load More" butonu
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.deepPurple,
            side: const BorderSide(color: Colors.deepPurple),
            padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.expand_more),
          label: const Text("Load 10 More",
              style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _loadTab(tab),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          "You've seen all the news ✓",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ),
    );
  }
}

class _TabState {
  List<News> news = [];
  int page = 1;
  bool loading = false;
  bool hasMore = true;
  String? error;
}

class _NewsCard extends StatelessWidget {
  final News news;
  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => NewsDetailScreen(news: news)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim + kategori badge
            if (news.pngUrl != null)
              Stack(
                children: [
                  Image.network(
                    news.pngUrl!,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      color: Colors.grey.shade200,
                      child: Center(
                          child: Icon(Icons.broken_image,
                              size: 40, color: Colors.grey.shade400)),
                    ),
                  ),
                  // Hafif gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.45),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _CategoryBadge(news: news),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                child: _CategoryBadge(news: news),
              ),

            // Başlık
            Padding(
              padding: EdgeInsets.fromLTRB(
                  14, news.pngUrl != null ? 12 : 6, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      news.header,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios,
                      size: 13, color: Colors.grey.shade400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final News news;
  const _CategoryBadge({required this.news});

  @override
  Widget build(BuildContext context) {
    final analyzing = news.category == "Analyzing...";
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: analyzing ? Colors.grey.shade700 : news.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (analyzing)
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: Colors.white),
            )
          else
            Icon(News.iconForCategory(news.category),
                size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            news.category,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ── Yardımcı widget'lar ───────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: Colors.deepPurple),
        SizedBox(height: 16),
        Text("Loading news…",
            style: TextStyle(color: Colors.grey, fontSize: 15)),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style:
              const TextStyle(fontSize: 15, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            onPressed: onRetry,
          ),
        ],
      ),
    ),
  );
}