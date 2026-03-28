import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/exam_service.dart';
import '../../services/submission_service.dart';
import '../../config/constants.dart';
import '../../config/globals.dart';
import '../../widgets/ui_effects.dart';

class StudentHomePage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentHomePage({
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final _examService = ExamService();
  final _submissionService = SubmissionService();

  bool _isLoading = true;
  List<dynamic> _exams = [];
  Map<String, dynamic> _summary = {};
  
  // UI State
  int _selectedIndex = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadData() async {
    try {
      final exams = await _examService.getExams(
        institution: GlobalState.institution,
        published: true,
      );
      final summary = await _submissionService.getSummary(widget.studentId);

      if (mounted) {
        setState(() {
          _exams = exams;
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    GlobalState.clear();
    context.go('/login');
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
                                color: AppColors.PRIMARY,
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
        return _buildMyExamsView(isDesktop);
      case 2:
        return _buildPerformanceView(isDesktop);
      default:
        return _buildOverview(isDesktop);
    }
  }

  Widget _buildOverview(bool isDesktop) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileAndReadinessPanel(),
          const SizedBox(height: 32),
          _buildDashboardStatisticsRow(isDesktop),
          const SizedBox(height: 32),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildUpcomingExamsSection(),
                      const SizedBox(height: 24),
                      _buildPerformanceAnalyticsSection(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildTimerWidget(),
                      const SizedBox(height: 24),
                      _buildAIProctoringStatusWidget(),
                      const SizedBox(height: 24),
                      _buildViolationMonitoringSection(),
                      const SizedBox(height: 24),
                      _buildRecentActivitySection(),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildTimerWidget(),
                const SizedBox(height: 24),
                _buildUpcomingExamsSection(),
                const SizedBox(height: 24),
                _buildPerformanceAnalyticsSection(),
                const SizedBox(height: 24),
                _buildAIProctoringStatusWidget(),
                const SizedBox(height: 24),
                _buildViolationMonitoringSection(),
                const SizedBox(height: 24),
                _buildRecentActivitySection(),
              ],
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1 & 2. NAVIGATION & TOP BAR
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
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )
          else
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
              ).createShader(rect),
              child: const Text(
                "Dashboard Overview",
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
                hintText: "Search exams...",
                hintStyle: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.3)),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.white.withOpacity(0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: Colors.white.withOpacity(0.6)),
                onPressed: () => _showNotifications(context),
              ),
              Positioned(
                right: 8, top: 8,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.ERROR,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.ERROR.withOpacity(0.5), blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.studentName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.studentName,
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
                  child: const Icon(Icons.security, color: Colors.white, size: 16),
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
                AnimatedSidebarItem(index: 1, selectedIndex: _selectedIndex, icon: Icons.assignment_rounded, title: 'My Exams', isMobile: isMobile, onTap: () => setState(() => _selectedIndex = 1)),
                AnimatedSidebarItem(index: 2, selectedIndex: _selectedIndex, icon: Icons.analytics_rounded, title: 'Performance', isMobile: isMobile, onTap: () => setState(() => _selectedIndex = 2)),
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

  Widget _buildNavItem(int index, IconData icon, String title, bool isMobile) {
    return AnimatedSidebarItem(
      index: index,
      selectedIndex: _selectedIndex,
      icon: icon,
      title: title,
      isMobile: isMobile,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  // ===========================================================================
  // 3. PROFILE & READINESS PANEL
  // ===========================================================================

  Widget _buildProfileAndReadinessPanel() {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 100),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.4),
                          blurRadius: 16,
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.studentName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.studentName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _infoBadge(Icons.badge, widget.studentId),
                          const SizedBox(width: 12),
                          _infoBadge(Icons.account_balance, GlobalState.institution),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                blurStrength: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("System Readiness", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _statusIndicator("Camera", true),
                        _statusIndicator("Internet", true),
                        _statusIndicator("Location", false),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.TEXT_MUTED),
        const SizedBox(width: 4),
        Text(text.isNotEmpty ? text : 'N/A', style: const TextStyle(color: AppColors.TEXT_SECONDARY, fontSize: 13)),
      ],
    );
  }

  Widget _statusIndicator(String label, bool isReady) {
    return Column(
      children: [
        Icon(
          isReady ? Icons.check_circle : Icons.error,
          color: isReady ? AppColors.SUCCESS : AppColors.WARNING,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.TEXT_SECONDARY)),
      ],
    );
  }

  // ===========================================================================
  // 4. STATS ROW
  // ===========================================================================

  Widget _buildDashboardStatisticsRow(bool isDesktop) {
    if (!isDesktop) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard("Upcoming Exams", "${_exams.length}", Icons.event, AppColors.PRIMARY)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard("Completed", "${_summary['completed_exams'] ?? 0}", Icons.task_alt, AppColors.SUCCESS)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard("Average Score", "${_summary['accuracy'] ?? '0'}%", Icons.analytics, AppColors.INFO)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard("Total Violations", "${_summary['warnings'] ?? 0}", Icons.warning_amber, AppColors.ERROR)),
            ],
          )
        ],
      );
    }
    
    return Row(
      children: [
        Expanded(child: _buildStatCard("Upcoming Exams", "${_exams.length}", Icons.event, AppColors.PRIMARY)),
        const SizedBox(width: 24),
        Expanded(child: _buildStatCard("Completed", "${_summary['completed_exams'] ?? 0}", Icons.task_alt, AppColors.SUCCESS)),
        const SizedBox(width: 24),
        Expanded(child: _buildStatCard("Average Score", "${_summary['accuracy'] ?? '0'}%", Icons.analytics, AppColors.INFO)),
        const SizedBox(width: 24),
        Expanded(child: _buildStatCard("Total Violations", "${_summary['warnings'] ?? 0}", Icons.warning_amber, AppColors.ERROR)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.BORDER),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.TEXT_SECONDARY, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.TEXT_PRIMARY)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. UPCOMING EXAMS & TIMER
  // ===========================================================================

  Widget _buildUpcomingExamsSection() {
    final activeExams = _exams.where((e) => e['status'] != 'finished').toList();
    final finishedExams = _exams.where((e) => e['status'] == 'finished').toList();

    return Column(
      children: [
        _buildCardWrapper(
          title: "Upcoming Exams",
          actionText: "View All",
          actionOnTap: () => setState(() => _selectedIndex = 1),
          child: activeExams.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text("No exams scheduled.", style: TextStyle(color: AppColors.TEXT_MUTED))),
              )
            : Column(
                children: activeExams.map((exam) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.BORDER),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.PRIMARY_LIGHT, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.assignment, color: AppColors.PRIMARY),
                      ),
                      title: Text(exam['name'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule, size: 14, color: AppColors.TEXT_SECONDARY),
                            const SizedBox(width: 4),
                            Text(exam['exam_datetime'] ?? 'TBD', style: const TextStyle(color: AppColors.TEXT_SECONDARY)),
                            const SizedBox(width: 16),
                            const Icon(Icons.timer, size: 14, color: AppColors.TEXT_SECONDARY),
                            const SizedBox(width: 4),
                            const Text("60 mins", style: TextStyle(color: AppColors.TEXT_SECONDARY)),
                          ],
                        ),
                      ),
                      trailing: FilledButton(
                        onPressed: () {
                          context.push(
                            '/exam_instruction/${exam['id']}?examName=${Uri.encodeComponent(exam['name'] ?? '')}&studentId=${Uri.encodeComponent(widget.studentId)}',
                          );
                        },
                        style: FilledButton.styleFrom(backgroundColor: AppColors.PRIMARY, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text("Start Exam"),
                      ),
                    ),
                  );
                }).toList(),
              ),
        ),
        const SizedBox(height: 24),
        _buildCardWrapper(
          title: "Finished Exams",
          child: finishedExams.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text("No finished exams.", style: TextStyle(color: AppColors.TEXT_MUTED))),
              )
            : Column(
                children: finishedExams.map((exam) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.BORDER),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.SUCCESS.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.check_circle, color: AppColors.SUCCESS),
                      ),
                      title: Text(exam['name'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule, size: 14, color: AppColors.TEXT_SECONDARY),
                            const SizedBox(width: 4),
                            Text(exam['exam_datetime'] ?? 'TBD', style: const TextStyle(color: AppColors.TEXT_SECONDARY)),
                            const SizedBox(width: 16),
                            const Icon(Icons.done_all, size: 14, color: AppColors.SUCCESS),
                            const SizedBox(width: 4),
                            const Text("Completed", style: TextStyle(color: AppColors.SUCCESS)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
        ),
      ],
    );
  }


  Widget _buildTimerWidget() {
    // Find closest upcoming exam to display countdown
    String days = "00";
    String hours = "00";
    String mins = "00";
    
    if (_exams.isNotEmpty) {
      try {
        final now = DateTime.now();
        DateTime? closest;
        
        for (final e in _exams) {
          final dt = DateTime.parse(e['exam_datetime']);
          if (dt.isAfter(now)) {
            if (closest == null || dt.isBefore(closest)) closest = dt;
          }
        }
        
        if (closest != null) {
          final diff = closest.difference(now);
          days = diff.inDays.toString().padLeft(2, '0');
          hours = (diff.inHours % 24).toString().padLeft(2, '0');
          mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
        }
      } catch (e) { /* Fallback to 00 */ }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.PRIMARY_GRADIENT,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.PRIMARY.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Next Exam Starts In", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeBox(days, "Days"),
              const Text(":", style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)),
              _buildTimeBox(hours, "Hours"),
              const Text(":", style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)),
              _buildTimeBox(mins, "Mins"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  // ===========================================================================
  // 6. ANALYTICS (Using fl_chart)
  // ===========================================================================

  Widget _buildPerformanceAnalyticsSection() {
    return _buildCardWrapper(
      title: "Performance Analytics",
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.BORDER, strokeWidth: 1)),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: (_summary['performance_data'] as List<dynamic>?)?.map((e) => FlSpot(double.parse(e['x'].toString()), double.parse(e['y'].toString()))).toList() ?? const [
                  FlSpot(1, 0),
                ],
                isCurved: true,
                color: AppColors.PRIMARY,
                barWidth: 3,
                belowBarData: BarAreaData(show: true, color: AppColors.PRIMARY.withOpacity(0.1)),
                dotData: const FlDotData(show: true),
              ),
            ],
            minY: 0, maxY: 100,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 7 & 10. AI MONITORING & VIOLATIONS
  // ===========================================================================

  Widget _buildAIProctoringStatusWidget() {
    return _buildCardWrapper(
      title: "AI Proctoring Status",
      child: Column(
        children: [
          _buildAIStatusRow(Icons.face, "Face Detection", "Active", AppColors.SUCCESS),
          const Divider(),
          _buildAIStatusRow(Icons.lightbulb_outline, "Lighting Quality", "Optimal", AppColors.SUCCESS),
          const Divider(),
          _buildAIStatusRow(Icons.mic_none, "Noise Level", "Quiet", AppColors.SUCCESS),
        ],
      ),
    );
  }

  Widget _buildAIStatusRow(IconData icon, String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.TEXT_SECONDARY),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(status, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationMonitoringSection() {
    return _buildCardWrapper(
      title: "Violation History",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.WARNING_LIGHT, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.WARNING.withOpacity(0.5))),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.WARNING),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_summary['last_warning'] ?? "No violations recorded in your recent exams. Great job!", style: TextStyle(color: _summary['last_warning'] != null ? Colors.amber.shade900 : Colors.green.shade900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 9. RECENT ACTIVITY
  // ===========================================================================

  Widget _buildRecentActivitySection() {
    return _buildCardWrapper(
      title: "Recent Activity",
      child: Column(
        children: (_summary['recent_activity'] as List<dynamic>?)?.map((item) {
          return _buildActivityItem(item['text'] ?? "", item['time'] ?? "");
        }).toList() ?? [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No recent activity", style: TextStyle(color: AppColors.TEXT_MUTED)),
          )
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 12),
            width: 8, height: 8,
            decoration: const BoxDecoration(color: AppColors.PRIMARY, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.TEXT_PRIMARY)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 12, color: AppColors.TEXT_MUTED)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // UTILS
  // ===========================================================================

  Widget _buildMyExamsView(bool isDesktop) {
    return _pageWrapper(
      title: "My Exams",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUpcomingExamsSection(),
          const SizedBox(height: 24),
          _sectionWrapper(
            title: "Past Exams",
            child: (_summary['past_exams'] as List<dynamic>?)?.isEmpty ?? true 
              ? const Padding(padding: EdgeInsets.all(16), child: Text("No past exams recorded."))
              : ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: (_summary['past_exams'] as List<dynamic>).map((exam) {
                    return _pastExamTile(
                      exam['name'] ?? "Untitled", 
                      exam['date'] ?? "Unknown", 
                      "${exam['score'] ?? 0}%", 
                      (exam['score'] ?? 0) >= 40 ? AppColors.SUCCESS : AppColors.ERROR
                    );
                  }).toList(),
                ),
          ),
        ],
      ),
    );
  }

  Widget _pastExamTile(String title, String date, String score, Color color) {
    return ListTile(
      leading: const Icon(Icons.history_edu, color: AppColors.TEXT_SECONDARY),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Completed: $date"),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(score, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPerformanceView(bool isDesktop) {
    return _pageWrapper(
      title: "Performance Analytics",
      child: Column(
        children: [
          _buildPerformanceAnalyticsSection(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStatCard("Accuracy", "${_summary['accuracy'] ?? 0}%", Icons.stars, AppColors.WARNING)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard("Violations", "${_summary['warnings'] ?? 0}", Icons.warning_amber_rounded, AppColors.ERROR)),
            ],
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

  Widget _sectionWrapper({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.BORDER),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.TEXT_PRIMARY)),
          const SizedBox(height: 20),
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

  Widget _notificationItem(String text, String time, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.PRIMARY),
      title: Text(text, style: const TextStyle(fontSize: 14)),
      subtitle: Text(time, style: const TextStyle(fontSize: 12, color: AppColors.TEXT_MUTED)),
    );
  }

  Widget _buildCardWrapper({required String title, String? actionText, VoidCallback? actionOnTap, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.BORDER),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.TEXT_PRIMARY)),
              if (actionText != null)
                TextButton(onPressed: actionOnTap, child: Text(actionText, style: const TextStyle(color: AppColors.PRIMARY))),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
