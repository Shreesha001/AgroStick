import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agro_stick/theme/colors.dart';
import 'package:agro_stick/features/map/farm_boundary/farm_boundary_screen.dart';
import 'package:agro_stick/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../../secrets.dart'; // Import secrets

class CropHealthScreen extends StatefulWidget {
  const CropHealthScreen({super.key});

  @override
  _CropHealthScreenState createState() => _CropHealthScreenState();
}

class _CropHealthScreenState extends State<CropHealthScreen> {
  // Dynamic data - initially empty
  String cropStatus = ""; // Initially empty
  double _infectionPercentage = 0.0; // Initially 0
  String _humidity = '65%';
  String _soilMoisture = 'optimal';
  List<Map<String, dynamic>> diseaseAlerts = [];

  // AI response variables
  int? _infectionLevel;
  String? _diseaseName;
  String? _pesticideName;
  String? _dosage;
  String? _frequency;
  String? _precautions;
  bool _isAnalyzing = false;
  bool _isRateLimited = false;
  String _selectedLanguage = 'en'; // Default English

  // Rate limiting
  DateTime? _lastRequestTime;
  static const Duration _rateLimitDelay = Duration(seconds: 5);
  static const int _maxRetries = 3;
  int _retryCount = 0;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Scan result
  String? _scanResult;
  XFile? _lastImage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _getLanguageFromProfile(); // Get from profile/settings
  }

  // Get language from profile/settings (you'll need to implement this)
  String _getLanguageFromProfile() {
    // TODO: Implement language retrieval from shared preferences or profile
    // For now, returning 'en'
    return 'en';
  }

  // Rate limiting helper
  Future<bool> _checkRateLimit(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (_lastRequestTime == null) {
      _lastRequestTime = DateTime.now();
      return true;
    }

    final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
    if (timeSinceLastRequest < _rateLimitDelay) {
      final waitTime = _rateLimitDelay - timeSinceLastRequest;
      if (mounted) {
        setState(() {
          _isRateLimited = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.rateLimitedMessage(waitTime.inSeconds)),
            duration: waitTime,
          ),
        );
        await Future.delayed(waitTime);
        if (mounted) {
          setState(() {
            _isRateLimited = false;
          });
        }
      }
      return false;
    }

    _lastRequestTime = DateTime.now();
    return true;
  }

  Widget dataCard(
      String title, String value, Color color, IconData icon, double screenWidth, AppLocalizations t) {
    return Container(
      width: (screenWidth - 60) / 2,
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

  void _startSpray(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.startingPesticideSpray)),
      );
    });
  }

  void _stopSpray(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.stoppingPesticideSpray)),
      );
    });
  }

  void _scheduleSpray(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.openingSpraySchedule)),
    );
  }

  void _openFarmMapping() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FarmBoundaryScreen(),
      ),
    );
  }

  Future<Map<String, dynamic>?> _makeApiRequest(String base64Image, String language, {int retryCount = 0}) async {
    try {
      String prompt = """
You are an expert plant pathologist and agricultural advisor.
Analyze the uploaded plant leaf image and provide:
1. Infection level on a scale of 1 (healthy) to 5 (severely infected).
2. Type of infection/disease.
3. Pesticide recommendation:
   - Name
   - Dosage per hectare
   - Application frequency
   - Safety precautions

Respond in JSON format like:
{
  "infection_level": 3,
  "disease_name": "Early Blight",
  "pesticide": {
    "name": "Mancozeb",
    "dosage": "2.5 kg/ha",
    "frequency": "Every 10 days",
    "precautions": "Wear gloves and mask"
  }
}
""";

      // Add language context for Gemini response translation
      if (language != 'en') {
        final languageMap = {
          'hi': 'Hindi',
          'pa': 'Punjabi',
        };
        final targetLanguage = languageMap[language] ?? 'English';
        
        prompt = """
First, provide the analysis in English JSON format as specified.
Then, translate the disease name, pesticide name, dosage, frequency, and precautions to $targetLanguage.

Respond with:
1. JSON analysis (in English)
2. TRANSLATED_RESPONSE: [translated disease name and recommendations in $targetLanguage]

Example:
{
  "infection_level": 3,
  "disease_name": "Early Blight",
  "pesticide": {
    "name": "Mancozeb",
    "dosage": "2.5 kg/ha",
    "frequency": "Every 10 days",
    "precautions": "Wear gloves and mask"
  }
}
TRANSLATED_RESPONSE: बीमारी - प्रारंभिक झुलसा; दवा - मैनकोजेब; खुराक - 2.5 किलो/हेक्टेयर; आवृत्ति - हर 10 दिन; सावधानियां - दस्ताने और मास्क पहनें

$prompt
""";
      }

      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey');
      final headers = {
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 1024,
        }
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['candidates'] != null && jsonResponse['candidates'].isNotEmpty) {
          final content = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          
          // Extract JSON from the response
          final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(content);
          if (jsonMatch != null) {
            final jsonString = jsonMatch.group(0);
            if (jsonString != null) {
              final result = jsonDecode(jsonString);
              
              // Extract translated response if available
              String? translatedResponse;
              if (language != 'en') {
                final translatedMatch = RegExp(r'TRANSLATED_RESPONSE:\s*(.*)', dotAll: true).firstMatch(content);
                if (translatedMatch != null) {
                  translatedResponse = translatedMatch.group(1)?.trim();
                }
                
                // Parse translated fields if available
                if (translatedResponse != null) {
                  try {
                    // Simple parsing - you might need more sophisticated parsing based on your response format
                    final lines = translatedResponse.split(';');
                    for (String line in lines) {
                      line = line.trim();
                      if (line.toLowerCase().contains('बीमारी') || line.toLowerCase().contains('disease')) {
                        result['translated_disease'] = line.split('-')[1].trim();
                      } else if (line.toLowerCase().contains('दवा') || line.toLowerCase().contains('pesticide')) {
                        result['translated_pesticide'] = line.split('-')[1].trim();
                      }
                    }
                  } catch (e) {
                    // Fallback to full translated response
                    result['translated_response'] = translatedResponse;
                  }
                }
              }
              
              return result;
            }
          }
        }
        return null;
      } else if (response.statusCode == 429) {
        // Rate limit exceeded - implement exponential backoff
        final backoffDelay = Duration(seconds: (1 << retryCount));
        if (retryCount < _maxRetries) {
          await Future.delayed(backoffDelay);
          return _makeApiRequest(base64Image, language, retryCount: retryCount + 1);
        } else {
          throw Exception('Max retries exceeded due to rate limiting');
        }
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  Future<void> _runInferenceOnImage(XFile imageFile, AppLocalizations t) async {
    // Check rate limit first
    final canProceed = await _checkRateLimit(context);
    if (!canProceed) return;

    setState(() {
      _isAnalyzing = true;
      _scanResult = null;
      _retryCount = 0;
    });

    try {
      final bytes = await File(imageFile.path).readAsBytes();
      String base64Image = base64Encode(bytes);

      // Additional safety delay
      await Future.delayed(const Duration(milliseconds: 500));

      final parsedJson = await _makeApiRequest(base64Image, _selectedLanguage, retryCount: _retryCount);

      if (parsedJson != null && mounted) {
        setState(() {
          _infectionLevel = parsedJson['infection_level'];
          _diseaseName = parsedJson['disease_name'] ?? parsedJson['translated_disease'];
          _pesticideName = parsedJson['pesticide']?['name'] ?? parsedJson['translated_pesticide'];
          _dosage = parsedJson['pesticide']?['dosage'];
          _frequency = parsedJson['pesticide']?['frequency'];
          _precautions = parsedJson['pesticide']?['precautions'];

          // Use translated response if available, otherwise use disease name
          _scanResult = parsedJson['translated_response'] ?? 
                       parsedJson['translated_disease'] ?? 
                       (_diseaseName ?? t.unknownDiseaseDetected);
          _lastImage = imageFile;

          // Update crop status only after analysis
          cropStatus = (_infectionLevel! <= 2) ? "healthy" : "unhealthy";

          // Update infection percentage (scale 1-5 to 0-1)
          _infectionPercentage = _infectionLevel! / 5.0;

          // Update disease alerts
          diseaseAlerts = [
            {
              "name": _diseaseName ?? t.unknownDiseaseDetected, 
              "severity": _levelToSeverity(_infectionLevel ?? 3, t)
            },
          ];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.analysisCompleteMessage(_diseaseName ?? t.unknownDiseaseDetected)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        setState(() {
          _scanResult = t.couldNotParseAIResponse;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanResult = t.analysisFailedMessage(e.toString());
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.analysisFailedMessage(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  String _levelToSeverity(int level, AppLocalizations t) {
    if (level <= 2) return t.lowSeverity;
    if (level == 3) return t.mediumSeverity;
    return t.highSeverity;
  }

  void _scanField(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_isRateLimited || _isAnalyzing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait before scanning again'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            t.selectImageSource,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                title: Text(
                  t.camera,
                  style: GoogleFonts.poppins(),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    await _runInferenceOnImage(image, t);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primaryGreen),
                title: Text(
                  t.gallery,
                  style: GoogleFonts.poppins(),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    await _runInferenceOnImage(image, t);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                t.cancel,
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getStatusText(String statusKey, AppLocalizations t) {
    if (statusKey.isEmpty) return t.notAnalyzed;
    switch (statusKey) {
      case 'healthy':
        return t.healthy;
      case 'unhealthy':
        return t.unhealthy;
      case 'optimal':
        return t.optimal;
      default:
        return statusKey;
    }
  }

  Color _getStatusColor(String statusKey) {
    if (statusKey.isEmpty) return Colors.grey;
    switch (statusKey) {
      case 'healthy':
        return Colors.green;
      case 'unhealthy':
        return Colors.red;
      default:
        return Colors.brown;
    }
  }

  IconData _getStatusIcon(String statusKey) {
    if (statusKey.isEmpty) return Icons.help_outline;
    switch (statusKey) {
      case 'healthy':
        return Icons.check_circle;
      case 'unhealthy':
        return Icons.warning;
      default:
        return Icons.grass;
    }
  }

  // Get progress bar color based on percentage
  Color _getProgressColor(double percentage) {
    if (percentage <= 0.3) {
      return Colors.green;
    } else if (percentage <= 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final cropStatusText = _getStatusText(cropStatus, t);
    final soilMoistureText = _getStatusText(_soilMoisture, t);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text(
          t.cropHealth,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Farm Mapping Section
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.map, color: AppColors.primaryGreen, size: 24),
                      SizedBox(width: 8),
                      Text(
                        t.farmMapping,
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    t.farmMappingDescription,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openFarmMapping,
                      icon: Icon(Icons.map, size: 20),
                      label: Text(
                        t.openFarmMapping,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, screenHeight * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            
            // 2. Scan Field Section
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
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
                  Row(
                    children: [
                      Icon(Icons.camera_alt, color: AppColors.primaryGreen, size: 24),
                      SizedBox(width: 8),
                      Text(
                        t.scanField,
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    t.scanFieldDescription,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_isAnalyzing || _isRateLimited) ? null : () => _scanField(context),
                      icon: _isAnalyzing 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.camera_alt, size: 20),
                      label: Text(
                        _isAnalyzing 
                            ? t.analyzingMessage 
                            : (_isRateLimited ? t.rateLimitedMessage(2) : t.fieldScan),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isAnalyzing || _isRateLimited)
                            ? AppColors.primaryGreen.withOpacity(0.5)
                            : AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, screenHeight * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (_lastImage != null || _scanResult != null) ...[
                    const SizedBox(height: 12),
                    if (_lastImage != null)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_lastImage!.path),
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (_scanResult != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${t.detected}! $_scanResult',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            
            // 3. Quick Actions
            Text(
              t.quickActions,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _startSpray(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    minimumSize: Size(screenWidth * 0.42, screenHeight * 0.07),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, size: 20, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        t.startSpray,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.04,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _stopSpray(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: Size(screenWidth * 0.42, screenHeight * 0.07),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stop, size: 20, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        t.stopSpray,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.04,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            ElevatedButton(
              onPressed: () => _scheduleSpray(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: Size(double.infinity, screenHeight * 0.07),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    t.scheduleSpray,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            
            // 4. Humidity and Soil Condition Cards
            Text(
              t.environmentalConditions,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 15,
              children: [
                dataCard(t.humidity, _humidity, Colors.blue, Icons.water_drop, screenWidth, t),
                dataCard(t.soilCondition, soilMoistureText, Colors.brown, Icons.grass, screenWidth, t),
              ],
            ),
            SizedBox(height: screenHeight * 0.04),
            
            // 5. Overall Infection Level - Only show after analysis
            if (cropStatus.isNotEmpty) ...[
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.overallInfectionLevel,
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _infectionPercentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(_infectionPercentage),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0%',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${(_infectionPercentage * 100).toInt()}%',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.bold,
                            color: _getProgressColor(_infectionPercentage),
                          ),
                        ),
                        Text(
                          '100%',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
            ],
            
            // 6. Crop Status - Only show after analysis
            if (cropStatus.isNotEmpty) ...[
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
                          t.cropStatus,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          cropStatusText,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(cropStatus),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _getStatusIcon(cropStatus),
                      color: _getStatusColor(cropStatus),
                      size: 40,
                    )
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
            ],
            
            // 7. Treatment Recommendations - Only show after analysis
            if (cropStatus.isNotEmpty) ...[
              Text(
                t.treatmentRecommendations,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.basedOnCurrentInfection,
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 10),
                    if (_pesticideName != null && _dosage != null && _frequency != null) ...[
                      Row(
                        children: [
                          Icon(Icons.water_drop, color: AppColors.primaryGreen, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.applyPesticideFormat(_pesticideName!, _dosage!, _frequency!),
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Precautions: $_precautions',
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.04,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.inspectAndMonitorDaily,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.04,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ],
        ),
      ),
    );
  }
}