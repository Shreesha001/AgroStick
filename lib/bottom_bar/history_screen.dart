// lib/features/history/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agro_stick/theme/colors.dart';
import 'package:agro_stick/l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _expandedPeriod;

  // Sample data
  final Map<String, dynamic> _historyData = {
    'today': {
      'count': 3,
      'sprays': [
        {'time': '08:30 AM', 'amount': 1.5},
        {'time': '12:15 PM', 'amount': 2.0},
        {'time': '05:45 PM', 'amount': 1.0},
      ],
    },
    'thisWeek': {
      'count': 15,
      'sprays': [
        {'time': 'Mon 09:00 AM', 'amount': 3.0},
        {'time': 'Tue 11:30 AM', 'amount': 2.5},
        {'time': 'Wed 02:15 PM', 'amount': 1.8},
        {'time': 'Thu 10:00 AM', 'amount': 2.2},
        {'time': 'Fri 04:30 PM', 'amount': 1.5},
      ],
    },
    'thisMonth': {
      'count': 60,
      'sprays': [
        {'time': 'Day 1 - 09:00 AM', 'amount': 3.5},
        {'time': 'Day 5 - 11:00 AM', 'amount': 2.8},
        {'time': 'Day 10 - 01:30 PM', 'amount': 2.0},
        {'time': 'Day 15 - 03:00 PM', 'amount': 3.2},
        {'time': 'Day 20 - 10:15 AM', 'amount': 1.7},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text(
          t.sprayHistory,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: screenWidth * 0.055,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          children: [
            _buildHistoryCard(
              title: t.today,
              count: _historyData['today']['count'],
              sprays: _historyData['today']['sprays'],
              period: 'today',
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              t: t,
            ),
            SizedBox(height: screenHeight * 0.02),
            _buildHistoryCard(
              title: t.thisWeek,
              
              count: _historyData['thisWeek']['count'],
              sprays: _historyData['thisWeek']['sprays'],
              period: 'thisWeek',
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              t: t,
            ),
            SizedBox(height: screenHeight * 0.02),
            _buildHistoryCard(
              title: t.thisMonth,
              count: _historyData['thisMonth']['count'],
              sprays: _historyData['thisMonth']['sprays'],
              period: 'thisMonth',
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              t: t,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required int count,
    required List<Map<String, dynamic>> sprays,
    required String period,
    required double screenWidth,
    required double screenHeight,
    required AppLocalizations t,
  }) {
    final isExpanded = _expandedPeriod == period;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Tap to expand)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _expandedPeriod = isExpanded ? null : period;
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.025),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      period == 'today'
                          ? Icons.today
                          : period == 'thisWeek'
                              ? Icons.calendar_view_week
                              : Icons.calendar_month,
                      color: AppColors.primaryGreen,
                      size: screenWidth * 0.07,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '$count ${t.sprays}',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.04,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: screenWidth * 0.06,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Spray List
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.01,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                children: sprays.map((spray) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
                    child: Row(
                      children: [
                        Icon(Icons.water_drop, color: AppColors.primaryGreen, size: screenWidth * 0.05),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            spray['time'],
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.04,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenHeight * 0.005,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${spray['amount']}L',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}