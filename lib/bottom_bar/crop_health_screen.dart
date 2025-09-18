import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agro_stick/theme/colors.dart';
import 'package:agro_stick/features/map/farm_boundary/farm_boundary_screen.dart';
import 'package:image_picker/image_picker.dart'; // Added for image picking
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'dart:convert';

class CropHealthScreen extends StatefulWidget {
  const CropHealthScreen({super.key});

  @override
  _CropHealthScreenState createState() => _CropHealthScreenState();
}

class _CropHealthScreenState extends State<CropHealthScreen> {
  // Placeholder data
  String cropStatus = "Healthy";
  String _humidity = '65%';
  String _soilMoisture = 'Optimal';
  List<Map<String, dynamic>> diseaseAlerts = [
    {"name": "Leaf Rust", "severity": "Low"},
    {"name": "Brown Spot", "severity": "Medium"},
  ];

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // ML
  tfl.Interpreter? _interpreter;
  bool _modelLoading = false;
  String? _scanResult;
  XFile? _lastImage;
  List<String>? _classLabels;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() { _modelLoading = true; });
    try {
      _interpreter = await tfl.Interpreter.fromAsset('lib/model/plant_disease_model.tflite');
      // Load class labels (supports multiple JSON formats)
      final jsonStr = await DefaultAssetBundle.of(context).loadString('lib/features/blog/models/classes.json');
      final dynamic decoded = json.decode(jsonStr);
      if (decoded is List) {
        _classLabels = decoded.map((e) => e.toString()).toList();
      } else if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('classes') && decoded['classes'] is List) {
          _classLabels = (decoded['classes'] as List).map((e) => e.toString()).toList();
        } else {
          // If the map is {"Label": index, ...}, sort by value (index) and take keys as labels
          final entries = decoded.entries.toList();
          final allValuesAreNums = entries.every((e) => e.value is num);
          if (allValuesAreNums) {
            entries.sort((a, b) => (a.value as num).compareTo(b.value as num));
            _classLabels = entries.map((e) => e.key.toString()).toList();
          } else {
            // Fallback: if map is {"0":"Label", ...}, sort by numeric key and take values
            entries.sort((a, b) {
              int pa = int.tryParse(a.key) ?? 0;
              int pb = int.tryParse(b.key) ?? 0;
              return pa.compareTo(pb);
            });
            _classLabels = entries.map((e) => e.value.toString()).toList();
          }
        }
      } else {
        _classLabels = null; // fallback
      }
    } catch (e) {
      _scanResult = 'Failed to load model: $e';
    } finally {
      if (mounted) setState(() { _modelLoading = false; });
    }
  }

  Future<void> _runInferenceOnImage(XFile imageFile) async {
    if (_interpreter == null) {
      _scanResult = 'Model not loaded';
      if (mounted) setState(() {});
      return;
    }

    try {
      final bytes = await File(imageFile.path).readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _scanResult = 'Could not decode image';
        if (mounted) setState(() {});
        return;
      }

      final inputTensor = _interpreter!.getInputTensors().first;
      final outputTensor = _interpreter!.getOutputTensors().first;
      final inputShape = inputTensor.shape; // [1,h,w,c]
      final h = inputShape.length >= 2 ? inputShape[1] : 224;
      final w = inputShape.length >= 3 ? inputShape[2] : 224;
      final c = inputShape.length >= 4 ? inputShape[3] : 3;

      // Resize and normalize
      final resized = img.copyResize(decoded, width: w, height: h);

      final inputType = inputTensor.type;
      dynamic input;
      
      // Fixed: Use correct TfLiteType enum values for tflite_flutter
      if (inputType == tfl.TfLiteType.kTfLiteFloat32) {
        input = List.generate(1, (_) => List.generate(h, (y) => List.generate(w, (x) {
              final px = resized.getPixel(x, y);
              final r = px.r / 255.0;
              final g = px.g / 255.0;
              final b = px.b / 255.0;
              return c == 1 ? [0.299*r + 0.587*g + 0.114*b] : [r, g, b];
            })));
      } else {
        // uint8
        input = List.generate(1, (_) => List.generate(h, (y) => List.generate(w, (x) {
              final px = resized.getPixel(x, y);
              final r = px.r;
              final g = px.g;
              final b = px.b;
              return c == 1 ? [((0.299*r + 0.587*g + 0.114*b)).round()] : [r, g, b];
            })));
      }

      // Prepare output buffer
      final outShape = outputTensor.shape; // [1, numClasses] or similar
      int numOut = 1;
      for (final d in outShape.skip(1)) { numOut *= d; }
      List<List<double>> output = List.generate(1, (_) => List.filled(numOut, 0.0));

      _interpreter!.run(input, output);

      // Argmax
      double maxVal = -1e9;
      int maxIdx = -1;
      for (int i = 0; i < numOut; i++) {
        final v = output[0][i];
        if (v > maxVal) { maxVal = v; maxIdx = i; }
      }

      _lastImage = imageFile;
      final label = (_classLabels != null && maxIdx >= 0 && maxIdx < _classLabels!.length)
          ? _classLabels![maxIdx]
          : 'class #$maxIdx';
      _scanResult = 'Prediction: $label  (score: ${maxVal.toStringAsFixed(3)})';
      if (mounted) setState(() {});
    } catch (e) {
      _scanResult = 'Inference failed: $e';
      if (mounted) setState(() {});
    }
  }

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

  void _startSpray() {
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting pesticide spray...')),
      );
    });
  }

  void _stopSpray() {
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stopping pesticide spray...')),
      );
    });
  }

  void _scheduleSpray() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening spray schedule...')),
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

  // Updated _scanField to show dialog with camera and gallery options
  void _scanField() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Image Source',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                title: Text(
                  'Camera',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    await _runInferenceOnImage(image);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primaryGreen),
                title: Text(
                  'Gallery',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    await _runInferenceOnImage(image);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text(
          'Crop Health',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold , color: Colors.white),
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
                        'Farm Mapping',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Map your farm boundary and detect disease locations with precision',
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
                        'Open Farm Mapping',
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
                      Icon(Icons.camera_alt, color: AppColors.primaryGreen, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Scan Field for Accurate Results',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Initiate a field scan to detect crop health issues with high accuracy',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _scanField,
                      icon: Icon(Icons.camera_alt, size: 20),
                      label: Text(
                        'Field Scan',
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
                  if (_modelLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text('Loading model...', style: GoogleFonts.poppins(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  if (_lastImage != null || _scanResult != null) ...[
                    const SizedBox(height: 12),
                    if (_lastImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_lastImage!.path), height: 160, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        _scanResult ?? '', 
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            
            // 3. Quick Actions
            Text(
              'Quick Actions',
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
                  onPressed: _startSpray,
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
                        'Start Spray',
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
                  onPressed: _stopSpray,
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
                        'Stop Spray',
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
              onPressed: _scheduleSpray,
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
                    'Schedule Spray',
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
              'Environmental Conditions',
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
                dataCard('Humidity', _humidity, Colors.blue, Icons.water_drop, screenWidth),
                dataCard('Soil Condition', _soilMoisture, Colors.brown, Icons.grass, screenWidth),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            
            // 5. Overall Infection Level
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
                    'Overall Infection Level',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: 0.3,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.orange.withOpacity(0.7),
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
                        '30%',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
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
            
            // 6. Crop Status
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
            
            // 7. Treatment Recommendations
            Text(
              'Treatment Recommendations',
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
                    'Based on current infection level:',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.water_drop, color: AppColors.primaryGreen, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Apply low dosage pesticide spray (20% recommended)',
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
                      Icon(Icons.schedule, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Schedule next inspection in 3 days',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.04,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }
}