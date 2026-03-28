import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/submission_service.dart';
import '../../widgets/violation_card.dart';

class ExamResultsPage extends StatefulWidget {
  final String examId;

  const ExamResultsPage({required this.examId});

  @override
  State<ExamResultsPage> createState() => _ExamResultsPageState();
}

class _ExamResultsPageState extends State<ExamResultsPage>
    with SingleTickerProviderStateMixin {
  final _submissionService = SubmissionService();
  bool _isLoading = true;
  List<dynamic> _results = [];
  List<dynamic> _violations = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await _submissionService.getResults(widget.examId);
      final violationsList = await _submissionService.getViolations(widget.examId);
      
      // Parse violations from API
      // Backend returns: [{id, student_id, exam_id, message, timestamp}]
      final parsedViolations = violationsList.map((v) {
        return {
          'title': v['message'] ?? 'Unknown Violation',
          'description': 'Student ID: ${v['student_id']}',
          'timestamp': v['timestamp'] ?? 'Unknown Time',
          'severity': 'high', // Map depending on message if needed
        };
      }).toList();

      setState(() {
        _results = results;
        _violations = parsedViolations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF673AB7),
        elevation: 2,
        title: const Text('Exam Results & Violations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Results'),
            Tab(text: 'Violations'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildResultsTab(),
                _buildViolationsTab(),
              ],
            ),
    );
  }

  Widget _buildResultsTab() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline,
                size: 48, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No results available',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    double avgScore = 0;
    int passCount = 0;
    if (_results.isNotEmpty) {
      avgScore = _results.fold<double>(
              0, (prev, r) => prev + (r['score'] as num? ?? 0).toDouble()) /
          _results.length;
      passCount = _results.where((r) => (r['score'] as num? ?? 0) >= 60).length;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    label: 'Total Students',
                    value: _results.length.toString(),
                    icon: Icons.people,
                    color: Colors.blue)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    label: 'Average Score',
                    value: '${avgScore.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: Colors.green)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    label: 'Pass Rate',
                    value: '$passCount/${_results.length}',
                    icon: Icons.check_circle,
                    color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Student Performance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._results.map((result) => _buildResultCard(result)).toList(),
      ],
    );
  }

  Widget _buildViolationsTab() {
    if (_violations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified,
                size: 64, color: Colors.green.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No violations detected',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    int high = _violations.where((v) => v['severity'] == 'high').length;
    int medium = _violations.where((v) => v['severity'] == 'medium').length;
    int low = _violations.where((v) => v['severity'] == 'low').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ViolationStats(
            totalViolations: _violations.length,
            highSeverity: high,
            mediumSeverity: medium,
            lowSeverity: low),
        const SizedBox(height: 24),
        const Text('Violation Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._violations
            .map((v) => ViolationCard(
                studentName: v['student_name'] ?? 'Unknown',
                violationType: v['violation_type'] ?? 'Unknown',
                severity: v['severity'] ?? 'low',
                timestamp: v['timestamp'] ?? '',
                description:
                    v['description'] ?? 'Violation detected during exam',
                violationCount: v['violation_count'] ?? 1))
            .toList(),
      ],
    );
  }

  Widget _buildStatCard(
      {required String label,
      required String value,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildResultCard(dynamic result) {
    final score = (result['score'] as num? ?? 0).toDouble();
    final passed = score >= 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result['student_name'] ?? 'Unknown Student',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(result['student_id'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: passed ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(passed ? 'PASSED' : 'FAILED',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                    passed ? Colors.green : Colors.red),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScoreItem(
                    label: 'Score', value: '${score.toStringAsFixed(1)}%'),
                Container(
                    width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
                _buildScoreItem(
                    label: 'Correct',
                    value: '${result['correct_answers'] ?? 0}'),
                Container(
                    width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
                _buildScoreItem(
                    label: 'Total', value: '${result['total_questions'] ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem({required String label, required String value}) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF673AB7))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
