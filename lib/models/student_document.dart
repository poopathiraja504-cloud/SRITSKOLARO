class StudentDocument {
  const StudentDocument({
    required this.id,
    required this.name,
    required this.url,
    required this.contentType,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String url;
  final String contentType;
  final DateTime? updatedAt;

  bool get isPdf => contentType == 'application/pdf' || name.toLowerCase().endsWith('.pdf');
}
