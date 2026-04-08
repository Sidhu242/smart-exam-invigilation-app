import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';
import '../../services/exam_service.dart';
import '../../services/submission_service.dart';
import '../../services/base_service.dart';
import '../../screens/teacher_dashboard.dart';
import '../../config/globals.dart';
import '../../widgets/ui_effects.dart';
import 'schedule_exam_page.dart';
import 'manage_exams_page.dart';

class TeacherHomePage extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherHomePage({
    required this.teacherId,
    required this.teacherName,
    super.key,
  });

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  final _examService = ExamService();
  final _submissionService = SubmissionService();
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<dynamic> _exams = [];
  List<dynamic> _students = [];
  Map<String, dynamic> _stats = {
    'total_exams': 0,
    'active_exams': 0,
    'total_students': 0,
    'violations': 0,
    'avg_score': '0%',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final exams = await _examService.getAllExams(institution: GlobalState.institution);
      
      // Calculate some basic stats from exams
      int active = 0;
      for (var e in exams) {
        if (e['is_published'] == true) active++; // Assuming is_published means active for now
      }

      if (mounted) {
        final active = exams.where((e) => e['status'] != 'closed').length;
        setState(() {
          _exams = exams;
          _stats['total_exams'] = exams.length;
          _stats['active_exams'] = active;
        });

        // Load students
        final studentsResp = await http.get(
          Uri.parse('${AppConfig.SERVER_URL}/students'),
        );
        if (mounted) {
          final decoded = jsonDecode(studentsResp.body);
          setState(() {
            _students = decoded is List ? List<dynamic>.from(decoded) : [];
            _stats['total_students'] = _students.length;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final _baseService = BaseService();

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    GlobalState.clear();
    context.go('/login');
  }

  Future<void> _closeExam(String examId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Exam'),
        content: const Text('Are you sure you want to close this exam? Students will no longer be able to submit answers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Close Exam', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);
      await _examService.closeExam(examId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam closed successfully'), backgroundColor: Colors.green),
      );
      await _loadData(); // refresh
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to close exam: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        drawer: isDesktop ? null : _buildSidebar(isMobile: true),
        body: AnimatedGradientBackground(
          child: ParticleBackground(
            child: Row(
              children: [
                if (isDesktop) _buildSidebar(isMobile: false),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopNavigation(),
                      Expanded(
                        child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: _buildMainContent(isDesktop),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDesktop) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview(isDesktop);
      case 1:
        return const ScheduleExamPage();
      case 2:
        return const ManageExamsPage();
      case 3:
        return _buildStudentsView(isDesktop);
      case 4:
        return _buildReportsView(isDesktop);
      case 5:
        return _buildSettingsView(isDesktop);
      case 6:
        return _buildLiveMonitoringSelect(isDesktop);
      default:
        return _buildOverview(isDesktop);
    }
  }

  Widget _buildOverview(bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 32),
          _buildStatisticsRow(isDesktop),
          const SizedBox(height: 32),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildQuickActionsGrid(),
                      const SizedBox(height: 24),
                      _buildRecentExamsSection(),
                      const SizedBox(height: 24),
                      _buildAnalyticsSection(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildLiveMonitoringWidget(),
                      const SizedBox(height: 24),
                      _buildAIProctoringStats(),
                      const SizedBox(height: 24),
                      _buildRecentViolationAlerts(),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildQuickActionsGrid(),
                const SizedBox(height: 24),
                _buildLiveMonitoringWidget(),
                const SizedBox(height: 24),
                _buildRecentExamsSection(),
                const SizedBox(height: 24),
                _buildAnalyticsSection(),
                const SizedBox(height: 24),
                _buildAIProctoringStats(),
              ],
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // LAYOUT COMPONENTS (Sidebar, Top Nav)
  // ===========================================================================

  Widget _buildTopNavigation() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width < 1024)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )
          else
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
              ).createShader(rect),
              child: const Text(
                "Teacher Dashboard",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          const Spacer(),
          Container(
            width: 220,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.3)),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.white.withOpacity(0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white.withOpacity(0.6)),
            onPressed: () => _showNotifications(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.SECONDARY.withOpacity(0.3),
                  child: Text(
                    widget.teacherName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.teacherName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool isMobile}) {
    final content = Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.4),
                        blurRadius: 12,
                      )
                    ],
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Smart OS",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                AnimatedSidebarItem(index: 0, selectedIndex: _selectedIndex, icon: Icons.dashboard_rounded, title: 'Overview', isMobile: isMobile, onTap: () => setState(() => _selectedIndex = 0)),
                AnimatedSidebarItem(index: 1, selectedIndex: _selectedIndex, icon: Icons.add_circle_outline, title: 'Schedule Exam', isMobile: isMobile, onTap: () => setState(() => _selectedIndex = 1)),
                AnimatedSidebarItem(index: 2, selectedIndex: _selectedIndex, icon: Icons.folder_open_rounded, title: 'Manage Exams', isMobile: isMobile, onTap: () => setState(() => _selectedIndex = 2)),
                AnimatedSidebarItem(index: 3, selectedIndex: _selectedIndex, icon: Icons.group_rounded, title: 'Students', isMobile: isMobile, onTap: () => setState(() => _selectedIndex = 3)),
                AnimatedSidebarItem(index: 4, selectedIndex: _selectedIndex, icon: Icons.bar_chart_rounded, title: 'Reports', isMobile: isMobile, onTap: () => setState(() => _selectedIndex = 4)),
                AnimatedSidebarItem(index: 6, selectedIndex: _selectedIndex, icon: Icons.live_tv_rounded, title: 'Live Monitoring', isMobile: isMobile, onTap: () => setState(() => _selectedIndex = 6)),
                AnimatedSidebarItem(index: 5, selectedIndex: _selectedIndex, icon: Icons.settings_rounded, title: 'Settings', isMobile: isMobile, onTap: () => setState(() => _selectedIndex = 5)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GlowButton(
              label: 'Logout',
              icon: Icons.logout,
              onPressed: _handleLogout,
              gradientColors: [Colors.red.shade900, Colors.red.shade700],
              glowColor: Colors.red,
              isSmall: true,
            ),
          ),
        ],
      ),
    );

    if (isMobile) return Drawer(child: content);
    return content;
  }

  // Legacy _buildNavItem kept for reference but no longer used
  Widget _buildNavItem(int index, IconData icon, String title, bool isMobile) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.PRIMARY_LIGHT.withOpacity(0.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.PRIMARY_DARK : AppColors.TEXT_SECONDARY,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: () {
          setState(() => _selectedIndex = index);
          if (index == 1) context.go('/schedule_exam');
          if (index == 2) context.go('/manage_exams');
          if (!isMobile) {
            // No action needed for desktop sidebar other than state update
          } else {
            Navigator.pop(context); // Close drawer on mobile
          }
        },
      ),
    );
  }

  // ===========================================================================
  // CONTENT WIDGETS
  // ===========================================================================

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${widget.teacherName}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Here is what is happening with your exams today.',
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _buildStatisticsRow(bool isDesktop) {
    final stats = [
      PremiumStatCard(title: "Total Exams", value: "${_stats['total_exams']}", icon: Icons.assignment_outlined, color: AppColors.INFO, animDelay: const Duration(milliseconds: 0)),
      PremiumStatCard(title: "Active Exams", value: "${_stats['active_exams']}", icon: Icons.play_circle_outline, color: AppColors.SUCCESS, animDelay: const Duration(milliseconds: 80)),
      PremiumStatCard(title: "Total Students", value: "${_stats['total_students']}", icon: Icons.people_outline, color: AppColors.PRIMARY, animDelay: const Duration(milliseconds: 160)),
      PremiumStatCard(title: "Violations", value: "${_stats['violations']}", icon: Icons.warning_amber_rounded, color: AppColors.ERROR, animDelay: const Duration(milliseconds: 240)),
      PremiumStatCard(title: "Avg. Score", value: "${_stats['avg_score']}", icon: Icons.analytics_outlined, color: AppColors.WARNING, animDelay: const Duration(milliseconds: 320)),
    ];

    if (!isDesktop) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: stats.map((s) => SizedBox(width: (MediaQuery.of(context).size.width - 48) / 2, child: s)).toList(),
      );
    }
    return Row(
      children: stats.map((s) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: s))).toList(),
    );
  }

  // Legacy _statCard kept for internal use if needed
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return PremiumStatCard(title: title, value: value, icon: icon, color: color);
  }

  Widget _buildQuickActionsGrid() {
    return _sectionWrapper(
      title: "Quick Actions",
      child: Row(
        children: [
          _quickActionItem("Create Exam", Icons.add_task, AppColors.PRIMARY, () => setState(() => _selectedIndex = 1)),
          const SizedBox(width: 16),
          _quickActionItem("Manage Exams", Icons.post_add, AppColors.SECONDARY, () => setState(() => _selectedIndex = 2)),
          const SizedBox(width: 16),
          _quickActionItem("View Reports", Icons.description_outlined, AppColors.INFO, () => setState(() => _selectedIndex = 4)),
        ],
      ),
    );
  }

  Widget _quickActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GlowButton(
        label: label,
        icon: icon,
        onPressed: onTap,
        gradientColors: [color, color.withOpacity(0.7)],
        glowColor: color,
      ),
    );
  }

  Widget _buildLiveMonitoringWidget() {
    return _sectionWrapper(
      title: "Live Monitoring",
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text("No exams are currently being live monitored.", style: TextStyle(color: AppColors.TEXT_MUTED)),
        ),
      ),
    );
  }

  // _monitoringTile removed as it was unused

  Widget _buildRecentExamsSection() {
    final activeExams = _exams.where((e) => e['status'] != 'closed').toList();
    final finishedExams = _exams.where((e) => e['status'] == 'closed').toList();

    return Column(
      children: [
        _sectionWrapper(
          title: "Active Exams",
          actionText: "See All",
          child: activeExams.isEmpty 
            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No active exams")))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeExams.length > 5 ? 5 : activeExams.length,
                itemBuilder: (context, index) {
                  final exam = activeExams[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.PRIMARY.withOpacity(0.5)),
                      color: AppColors.PRIMARY.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.play_circle_fill, color: AppColors.PRIMARY),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exam['name'] ?? "Untitled Exam", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("${exam['exam_datetime'] ?? 'No Date'} • Institution: ${exam['institution']}", style: const TextStyle(fontSize: 12, color: AppColors.TEXT_SECONDARY)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/add_question/${exam['id']}?examName=${Uri.encodeComponent(exam['name'] ?? '')}'),
                          child: const Text("Edit"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => _closeExam(exam['id']),
                          child: const Text("Close", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
        const SizedBox(height: 24),
        _sectionWrapper(
          title: "Finished Exams",
          actionText: "See Reports",
          child: finishedExams.isEmpty 
            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No finished exams")))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: finishedExams.length > 5 ? 5 : finishedExams.length,
                itemBuilder: (context, index) {
                  final exam = finishedExams[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.BORDER),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.SUCCESS),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exam['name'] ?? "Untitled Exam", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.TEXT_MUTED)),
                              Text("${exam['exam_datetime'] ?? 'No Date'} • Institution: ${exam['institution']}", style: const TextStyle(fontSize: 12, color: AppColors.TEXT_SECONDARY)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/exam_results/${exam['id']}'),
                          child: const Text("View Results"),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection() {
    return _sectionWrapper(
      title: "Class Performance Trends",
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            barGroups: [
              BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: AppColors.PRIMARY)]),
              BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: AppColors.PRIMARY)]),
              BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: AppColors.SECONDARY)]),
              BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: AppColors.PRIMARY)]),
              BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 13, color: AppColors.PRIMARY)]),
            ],
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIProctoringStats() {
    return _sectionWrapper(
      title: "AI Monitoring Efficiency",
      child: Column(
        children: [
          _aiStatRow("Students Monitored", "${_stats['total_students']}", Icons.remove_red_eye_outlined),
          _aiStatRow("Faces Detected", "0%", Icons.face_retouching_natural),
          _aiStatRow("Warnings Issued", "${_stats['violations']}", Icons.warning_amber_rounded),
          _aiStatRow("Auto Submissions", "0", Icons.auto_delete_outlined),
        ],
      ),
    );
  }

  Widget _aiStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.TEXT_SECONDARY),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.PRIMARY)),
        ],
      ),
    );
  }

  Widget _buildRecentViolationAlerts() {
    return _sectionWrapper(
      title: "Real-time Alerts",
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No real-time alerts", style: TextStyle(color: AppColors.TEXT_MUTED)),
        ),
      ),
    );
  }

  // _alertItem and _actionButton removed/renamed

  Widget _sectionWrapper({required String title, required Widget child, String? actionText}) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              if (actionText != null) TextButton(onPressed: () {}, child: Text(actionText, style: const TextStyle(color: Color(0xFF60A5FA)))),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }



  Widget _buildSettingsView(bool isDesktop) {
    return _pageWrapper(
      title: "Settings",
      child: Column(
        children: [
          _sectionWrapper(
            title: "Profile Information",
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text("Teacher Name"),
                  subtitle: Text(widget.teacherName),
                  trailing: const Icon(Icons.edit_outlined),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.email_outlined),
                  title: Text("Email Address"),
                  subtitle: Text("teacher@institution.edu"),
                  trailing: Icon(Icons.edit_outlined),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.domain),
                  title: const Text("Institution"),
                  subtitle: Text(GlobalState.institution),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionWrapper(
            title: "System Preferences",
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Real-time Email Alerts"),
                  subtitle: const Text("Receive notifications for critical violations"),
                  value: true,
                  onChanged: (v) {},
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  subtitle: const Text("Use dark theme for the interface"),
                  value: false,
                  onChanged: (v) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageWrapper({required String title, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.TEXT_PRIMARY)),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notifications"),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "No new notifications",
                    style: TextStyle(color: AppColors.TEXT_MUTED),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _buildLiveMonitoringSelect(bool isDesktop) {
    final activeExams = _exams.where((e) => e['status'] != 'closed').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Live Exam Monitoring",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Select an active exam to start live invigilation",
              style: TextStyle(color: AppColors.TEXT_MUTED)),
          const SizedBox(height: 32),
          if (activeExams.isEmpty)
            _buildEmptyState("No active exams available")
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeExams.length,
              itemBuilder: (context, index) {
                final exam = activeExams[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.videocam, color: Colors.red),
                    ),
                    title: Text(exam['name'] ?? 'Unnamed Exam',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('ID: ${exam['id']} • ${exam['institution']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _closeExam(exam['id']),
                          child: const Text("Close Exam", style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => context.push('/live_monitor/${exam['id']}'),
                          child: const Text("Start Monitoring"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStudentsView(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Registered Students", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (_students.isEmpty)
            _buildEmptyState("No students registered yet")
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(student['name'] ?? 'Unknown'),
                    subtitle: Text('ID: ${student['id']} • ${student['institution']}'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReportsView(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Performance Reports", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (_exams.isEmpty)
             _buildEmptyState("No exams data available for reports")
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exams.length,
              itemBuilder: (context, index) {
                final exam = _exams[index];
                return Card(
                  child: ListTile(
                    title: Text(exam['name'] ?? 'Unnamed Exam'),
                    subtitle: const Text('Summary of student performance and violations'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/exam_results/${exam['id']}'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }


  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.TEXT_MUTED.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: AppColors.TEXT_MUTED)),
          ],
        ),
      ),
    );
  }
}
