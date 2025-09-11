import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_stick/auth_screens/login_screen.dart';
import 'package:agro_stick/theme/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Placeholder values, replace with real data from ESP32-S3
  bool _isDeviceConnected = true;
  String _batteryLevel = '80%';
  String _humidity = '65%';
  String _soilMoisture = 'Optimal';
  String _sprayStatus = 'Idle';
  String _temperature = '28°C';

  Widget dataCard(String title, String value, Color color, IconData icon, double screenWidth) {
    return Container(
      width: (screenWidth - 60) / 2, // 2 cards per row with spacing
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: screenWidth * 0.08),
          SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.035,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user != null ? 'Hi, ${user.email?.split("@")[0]}!' : 'Welcome!',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              // Image in a curved box
              Container(
                width: double.infinity,
                height: screenHeight * 0.25,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'assets/crop_image.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              // Sensor Data Grid (2 per row)
              Wrap(
                spacing: 10,
                runSpacing: 15,
                children: [
                  dataCard(
                    'ESP32-S3 Connection',
                    _isDeviceConnected ? 'Connected' : 'Disconnected',
                    _isDeviceConnected ? Colors.green : Colors.red,
                    Icons.wifi,
                    screenWidth,
                  ),
                  dataCard('Battery Level', _batteryLevel, Colors.orange, Icons.battery_full, screenWidth),
                  dataCard('Humidity', _humidity, Colors.blue, Icons.water_drop, screenWidth),
                  dataCard('Soil Condition', _soilMoisture, Colors.brown, Icons.grass, screenWidth),
                  dataCard('Temperature', _temperature, Colors.red, Icons.thermostat, screenWidth),
                  dataCard(
                    'Spray Status',
                    _sprayStatus,
                    _sprayStatus == 'Spraying' ? Colors.green : Colors.grey,
                    Icons.water_drop,
                    screenWidth,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}