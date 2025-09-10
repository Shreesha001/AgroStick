import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agro_stick/theme/colors.dart';

class CropHealthScreen extends StatefulWidget {
  const CropHealthScreen({super.key});

  @override
  _CropHealthScreenState createState() => _CropHealthScreenState();
}

class _CropHealthScreenState extends State<CropHealthScreen> {
  // Placeholder data
  double soilMoisture = 65; // %
  double humidity = 70; // %
  double temperature = 30; // °C
  String cropStatus = "Healthy";
  List<Map<String, dynamic>> diseaseAlerts = [
    {"name": "Leaf Rust", "severity": "Low"},
    {"name": "Brown Spot", "severity": "Medium"},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text(
          'Crop Health',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop Status Card
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crop Status',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        cropStatus,
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w500,
                          color: cropStatus == "Healthy"
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    cropStatus == "Healthy" ? Icons.check_circle : Icons.warning,
                    color: cropStatus == "Healthy" ? Colors.green : Colors.red,
                    size: 40,
                  )
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),

            // Soil & Environmental Stats (2 in 1 row)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: "Soil Moisture",
                    value: "$soilMoisture%",
                    color: Colors.blue,
                    screenWidth: screenWidth,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: _buildStatCard(
                    title: "Humidity",
                    value: "$humidity%",
                    color: Colors.teal,
                    screenWidth: screenWidth,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: "Temperature",
                    value: "$temperature°C",
                    color: Colors.orange,
                    screenWidth: screenWidth,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: _buildStatCard(
                    title: "Battery",
                    value: "80%",
                    color: Colors.green,
                    screenWidth: screenWidth,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),

            // Disease Alerts
            Text(
              'Disease Alerts',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            diseaseAlerts.isEmpty
                ? Text(
                    'No disease detected.',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.045,
                      color: Colors.grey,
                    ),
                  )
                : Column(
                    children: diseaseAlerts
                        .map((alert) => Container(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    alert["name"],
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: alert["severity"] == "Low"
                                          ? Colors.green
                                          : alert["severity"] == "Medium"
                                              ? Colors.orange
                                              : Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      alert["severity"],
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // Helper method for stat cards
  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required double screenWidth,
  }) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
