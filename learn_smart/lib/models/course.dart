class Course {
  final int id;
  final String name;
  final String description;
  final String courseCode;
  final String createdByUsername;
  final List<String> students;
  final String? imageUrl;

  Course({
    required this.id,
    required this.name,
    required this.description,
    required this.createdByUsername,
    required this.courseCode,
    required this.students,
    required this.imageUrl,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'No Course',
      description: json['description'] ?? 'No Description',
      createdByUsername: json['created_by']['username'] ?? 'No Instructor',
      courseCode: json['code'] ?? 'No Course Code',
      students: List<String>.from(json['students']),
      imageUrl: json['image'] ?? 'No image',
    );
  }
}
