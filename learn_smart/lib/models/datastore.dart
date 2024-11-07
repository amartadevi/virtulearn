import 'package:flutter/material.dart';
import 'course.dart';
import 'module.dart';
import 'note.dart';
import 'quiz.dart';

class DataStore extends ChangeNotifier {
  // Token to be updated from the provider
  String? _token;

  // Courses
  static Map<int, Course> _courses = {};
  static List<dynamic> _enrollmentRequests = [];

  // Method to update token
  void updateToken(String? token) {
    _token = token;
    notifyListeners();
  }

  // Add a course to the datastore
  static void addCourse(Course course) {
    _courses[course.id] = course;
  }

  // Retrieve a course by its id
  static Course? getCourse(int id) {
    return _courses[id];
  }

  // Remove a course by its id
  static void removeCourse(int id) {
    _courses.remove(id);
  }

  // Retrieve a list of all courses
  static List<Course> getAllCourses() {
    return _courses.values.toList();
  }

  // Clear the existing courses
  static void clearCourses() {
    _courses.clear();
  }

  // Modules
  static Map<int, List<Module>> _modules = {};

  // Retrieve a specific module by its id
  static Module? getModuleById(int moduleId) {
    for (var moduleList in _modules.values) {
      for (var module in moduleList) {
        if (module.id == moduleId) {
          return module;
        }
      }
    }
    return null;
  }

  // Set modules for a specific course
  static void setModules(int courseId, List<Module> newModules) {
    _modules[courseId] = newModules;
  }

  // Retrieve modules for a specific course
  static List<Module> getModules(int courseId) {
    return _modules[courseId] ?? [];
  }

  // Add a new module to a course
  static void addModule(int courseId, Module module) {
    _modules[courseId] ??= [];
    _modules[courseId]?.add(module);
  }

  // Update a module in a specific course
  static void updateModule(int courseId, int moduleId, Module updatedModule) {
    final modules = _modules[courseId];
    if (modules != null) {
      final index = modules.indexWhere((m) => m.id == moduleId);
      if (index != -1) {
        modules[index] = updatedModule;
      }
    }
  }

  // Remove a module from a course
  static void removeModule(int courseId, int moduleId) {
    final modules = _modules[courseId];
    if (modules != null) {
      modules.removeWhere((m) => m.id == moduleId);
    }
  }

  // Notes
  static Map<int, List<Note>> _notes = {};

  // Set notes for a module
  static void setNotes(int moduleId, List<Note> notes) {
    _notes[moduleId] = notes;
  }

  // Retrieve notes for a module
  static List<Note> getNotes(int moduleId) {
    return _notes[moduleId] ?? [];
  }

  // Add a new note to a module
  static void addNoteToModule(int moduleId, Note note) {
    _notes[moduleId]?.add(note);
  }

  // Quizzes
  static Map<int, List<Quiz>> _quizzes = {};

  // Set quizzes for a module
  static void setQuizzes(int moduleId, List<Quiz> newQuizzes) {
    _quizzes[moduleId] = newQuizzes;
  }

  // Retrieve quizzes for a module
  static List<Quiz> getQuizzes(int moduleId) {
    return _quizzes[moduleId] ?? [];
  }

  // Add a new quiz to a module
  static void addQuiz(int moduleId, Quiz quiz) {
    _quizzes[moduleId] ??= [];
    _quizzes[moduleId]?.add(quiz);
  }

  // Update a quiz in a module
  static void updateQuiz(int moduleId, int quizId, Quiz updatedQuiz) {
    final quizzes = _quizzes[moduleId];
    if (quizzes != null) {
      final index = quizzes.indexWhere((q) => q.id == quizId);
      if (index != -1) {
        quizzes[index] = updatedQuiz;
      }
    }
  }

  // Remove a quiz from a module
  static void removeQuiz(int moduleId, int quizId) {
    final quizzes = _quizzes[moduleId];
    if (quizzes != null) {
      quizzes.removeWhere((q) => q.id == quizId);
    }
  }

  // Enrollment Requests
  static void setEnrollmentRequests(List<dynamic> requests) {
    _enrollmentRequests = requests;
  }

  // Retrieve all enrollment requests
  static List<dynamic> getEnrollmentRequests() {
    return _enrollmentRequests;
  }

  // Add a new enrollment request
  static void addEnrollmentRequest(Map<String, dynamic> request) {
    _enrollmentRequests.add(request);
  }

  // Update the status of an enrollment request
  static void updateEnrollmentRequestStatus(int requestId, String status) {
    for (var request in _enrollmentRequests) {
      if (request['id'] == requestId) {
        request['status'] = status;
        break;
      }
    }
  }

  // Quiz Results
  static final Map<int, List<dynamic>> _quizResults = {};

  static void setQuizResults(int quizId, List<dynamic> results) {
    _quizResults[quizId] = results;
  }

  static List<dynamic> getQuizResults(int quizId) {
    return _quizResults[quizId] ?? [];
  }
}
