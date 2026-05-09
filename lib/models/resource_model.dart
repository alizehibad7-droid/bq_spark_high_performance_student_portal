class ResourceModel {
  final String id;
  final String title;
  final String description;
  final String link;
  final String category;

  ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
    required this.category,
  });

  factory ResourceModel.fromMap(String id, Map<String, dynamic> data) {
    return ResourceModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      link: data['link'] ?? '',
      category: data['category'] ?? '',
    );
  }
}