// lib/features/home/screens/drawer_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agro_stick/theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _configRef;

  @override
  void initState() {
    super.initState();
    _configRef = _firestore.collection('devices');
    _ensureConfigExists();
  }

  // Create config if not exists
  Future<void> _ensureConfigExists() async {
    final doc = await _configRef.doc('config').get();
    if (!doc.exists) {
      await _configRef.doc('config').set({
        'device1': 'agrostick_1',
        'device2': 'agrostick_2',
        'device3': 'agrostick_3',
        'device4': 'agrostick_4',
        'connected': ['device1', 'device2'],
      });
    }
  }

  // Edit name with **duplicate check**
  Future<void> _editName(String field, String currentName, List<String> allNames) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Device Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g. farm_stick_1',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              // Check for duplicate
              final lowerNew = newName.toLowerCase();
              final isDuplicate = allNames.any((name) => name.toLowerCase() == lowerNew && name != currentName);

              if (isDuplicate) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Name already exists! Choose a unique name.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(ctx, newName);
            },
            child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _configRef.doc('config').update({field: result});
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;

    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: _configRef.doc('config').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins(color: Colors.red)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final connectedList = List<String>.from(data['connected'] ?? ['device1', 'device2']);

          final devices = [
            {
              'name': data['device1'] ?? 'agrostick_1',
              'icon': Icons.looks_one,
              'field': 'device1',
              'connected': connectedList.contains('device1'),
            },
            {
              'name': data['device2'] ?? 'agrostick_2',
              'icon': Icons.looks_two,
              'field': 'device2',
              'connected': connectedList.contains('device2'),
            },
            {
              'name': data['device3'] ?? 'agrostick_3',
              'icon': Icons.looks_3,
              'field': 'device3',
              'connected': connectedList.contains('device3'),
            },
            {
              'name': data['device4'] ?? 'agrostick_4',
              'icon': Icons.looks_4,
              'field': 'device4',
              'connected': connectedList.contains('device4'),
            },
          ];

          // For duplicate check
          final allNames = devices.map((d) => d['name'] as String).toList();

          return Column(
            children: [
              // === HEADER: Only Logo + AgroStick ===
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: safePadding.top + 30,
                  left: 20,
                  bottom: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGreen, Colors.greenAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/logo.png'),
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AgroStick',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // === DEVICE LIST ===
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isConnected = device['connected'] as bool;

                    return ListTile(
                      leading: Icon(
                        device['icon'] as IconData,
                        color: isConnected ? AppColors.primaryGreen : Colors.grey,
                      ),
                      title: Text(
                        device['name'].toString().toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        isConnected ? 'Connected' : 'Disconnected',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isConnected ? AppColors.primaryGreen : Colors.redAccent,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                        onPressed: () {
                          _editName(
                            device['field'] as String,
                            device['name'] as String,
                            allNames,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}