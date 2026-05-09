import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<dynamic> _articles = <dynamic>[];
  bool _isLoading = true;
  String _error = '';

  // Replace this with your key from https://newsapi.org
  final String _apiKey = 'YOUR_NEWSAPI_KEY';

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final Uri uri = Uri.parse(
        'https://newsapi.org/v2/everything?q=flutter+mobile+development&sortBy=publishedAt&pageSize=20&apiKey=$_apiKey',
      );
      final http.Response response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _articles = data['articles'] as List<dynamic>? ?? <dynamic>[];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load news. Add a valid NewsAPI key.';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'No internet connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openArticle(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tech News'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            onPressed: _fetchNews,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : _error.isNotEmpty
          ? _errorState()
          : _articles.isEmpty
          ? _emptyState()
          : RefreshIndicator(
        onRefresh: _fetchNews,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _articles.length,
          itemBuilder: (BuildContext context, int index) {
            return _articleCard(
              _articles[index] as Map<String, dynamic>,
            );
          },
        ),
      ),
    );
  }

  Widget _articleCard(Map<String, dynamic> article) {
    final String title = (article['title'] as String?) ?? '';
    final String source =
        (article['source'] as Map<String, dynamic>?)?['name'] as String? ?? '';
    final String imageUrl = (article['urlToImage'] as String?) ?? '';
    final String url = (article['url'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: url.isNotEmpty ? () => _openArticle(url) : null,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    height: 160,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    source,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Could not load news.',
            style: TextStyle(fontSize: 15, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchNews,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Text(
        'No articles found.',
        style: TextStyle(fontSize: 15, color: AppColors.textGray),
      ),
    );
  }
}
