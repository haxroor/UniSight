import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/data_persistence.dart';

class ExamProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _allExams = [];
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> get allExams => _allExams;

  List<Map<String, dynamic>> get completedExams {
    List<Map<String, dynamic>> exams = _allExams
        .where(
            (exam) => exam["voto"] != null && exam["voto"].toString().isNotEmpty)
        .toList();

    exams.sort((a, b) {
      try {
        DateTime dateA = DateFormat('yyyy-MM-dd').parse(a["data"]);
        DateTime dateB = DateFormat('yyyy-MM-dd').parse(b["data"]);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });
    return exams;
  }

  List<Map<String, dynamic>> get pendingExams {
    return _allExams
        .where(
            (exam) => exam["voto"] == null || exam["voto"].toString().isEmpty)
        .toList();
  }

  int get totalCfu {
    return _allExams.fold(0, (sum, exam) => sum + (exam['cfu'] as int));
  }

  int get acquiredCfu {
    return completedExams.fold(0, (sum, exam) => sum + (exam['cfu'] as int));
  }

  double get weightedAverage {
    if (completedExams.isEmpty || acquiredCfu == 0) return 0.0;
    double weightedSum = completedExams.fold(0, (sum, exam) {
      return sum + (int.parse(exam['voto'].toString()) * (exam['cfu'] as int));
    });
    return weightedSum / acquiredCfu;
  }

  double get arithmeticAverage {
    if (completedExams.isEmpty) return 0.0;
    double sum = completedExams.fold(0, (sum, exam) {
      return sum + int.parse(exam['voto'].toString());
    });
    return sum / completedExams.length;
  }

  Future<void> loadCoursePlan() async {
    _isLoading = true;
    notifyListeners();
    _allExams = await Data.loadData();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setCoursePlan(List<Map<String, dynamic>> courses) async {
    _allExams = courses;
    await Data.saveData(_allExams);
    notifyListeners();
  }

  Future<void> updateExamGrade(
      String examName, String grade, String date) async {
    final index = _allExams.indexWhere((exam) => exam['nome'] == examName);
    if (index != -1) {
      _allExams[index]['voto'] = grade;
      _allExams[index]['data'] = date;
      await Data.saveData(_allExams);
      notifyListeners();
    }
  }

  Future<void> deleteExamGrade(String examName) async {
    await updateExamGrade(examName, '', '');
  }
}