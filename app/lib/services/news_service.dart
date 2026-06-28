import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';

class NewsService {
  final String _gnewsToken = '353f687753917062cfdd4fc52ed3609c';

  //final String _serverIp = '192.168.43.156'; //deneme amacidi
  final String _baseUrl = 'https://ibrahimomer72-nb-news-server.hf.space';

  // GNews topic karşılıkları
  static const Map<String, String> _topicMap = {
    "World": "world",
    "Sports": "sports",
    "Business": "business",
    "Sci/Tech": "technology",
  };

  // ── Kategoriye göre haber çek (sayfalama destekli) ────────────────────────
  //  tab      : "World", "Sports", "Business", "Sci/Tech", ya da "All News"
  //  page     : 1'den başlar, Load More'da artırılır
  //  pageSize : bir seferde kaç haber
  Future<List<News>> fetchByTab(String tab,
      {int page = 1, int pageSize = 10}) async {
    final topic = _topicMap[tab]; // null → "All News"

    String url =
        'https://gnews.io/api/v4/top-headlines?lang=en&max=$pageSize&page=$page&token=$_gnewsToken';
    if (topic != null) url += '&topic=$topic';

    try {
      final response =
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final articles = (data['articles'] as List?) ?? [];

        return articles
            .where((a) => a['title'] != null && a['url'] != null)
            .map((a) => News(
          header: a['title'] as String,
          url: a['url'] as String,
          pngUrl: a['image'] as String?,
          // Kategorili tab'larda kategoriyi direk atıyoruz
          // All News tab'ında AI sınıflandıracak
          category: tab == "All News" ? "Analyzing..." : tab,
          color: tab == "All News"
              ? Colors.grey
              : News.colorForCategory(tab),
        ))
            .toList();
      } else {
        debugPrint('[NewsService] GNews ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[NewsService] fetchByTab exception: $e');
    }
    return [];
  }

  // ── AI Kategori tahmini (sadece "All News" için) ──────────────────────────
  Future<String> findCategory(String header) async {
    try {
      final response = await http
          .post(
        Uri.parse('http://$_baseUrl:8000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'header': header}),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['kategori_adi'] as String;
      }
    } catch (e) {
      debugPrint('[NewsService] findCategory exception: $e');
    }
    return 'Uncategorized';
  }

  // ── Makalenin tam metni ───────────────────────────────────────────────────
  Future<String> getFullText(String url) async {
    try {
      final response = await http
          .post(
        // BURAYI GÜNCELLEDİK! Artık geçici link yerine _baseUrl kullanıyoruz.
        Uri.parse('$_baseUrl/get_full_text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['statu'] == 'successful') {
          final text = (data['full_text'] as String? ?? '').trim();
          return text.isEmpty
              ? 'The news site did not allow the full text to be extracted.'
              : text;
        }
      }
    } catch (e) {
      debugPrint('[NewsService] getFullText exception: $e');
    }
    return 'The text could not be retrieved or the server connection was lost.';
  }
}