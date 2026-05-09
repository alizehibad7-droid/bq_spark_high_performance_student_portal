import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  final String apiKey = "YOUR_NEWSAPI_KEY";

  Future<List<dynamic>> fetchTechNews() async {
    final url =
        "https://newsapi.org/v2/everything?q=flutter&apiKey=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['articles'];
    } else {
      throw Exception("Failed to load news");
    }
  }
}