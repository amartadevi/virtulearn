class TeacherNotification {
  final String courseName;
  final String notificationMessage;
  final String status;

  TeacherNotification({
    required this.courseName,
    required this.notificationMessage,
    required this.status,
  });

  factory TeacherNotification.fromJson(Map<String, dynamic> json) {
    return TeacherNotification(
      courseName: json['courseName'],
      notificationMessage: json['notificationMessage'],
      status: json['status'],
    );
  }
}
