import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_stick/theme/colors.dart';
import 'package:agro_stick/features/blog/models/blog_model.dart';
import 'package:agro_stick/features/blog/services/blog_service.dart';
import 'package:agro_stick/features/blog/screens/blog_list_screen.dart';
import 'package:agro_stick/features/blog/screens/blog_content_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Placeholder values, replace with real data from ESP32-S3
  bool _isDeviceConnected = true;
  String _batteryLevel = '80%';
  String _sprayStatus = 'Idle';
  String _temperature = '28°C';
  
  // Blog data
  List<BlogModel> _featuredBlogs = [];

  @override
  void initState() {
    super.initState();
    _loadFeaturedBlogs();
  }

  void _loadFeaturedBlogs() {
    final allBlogs = BlogService.getBlogs();
    _featuredBlogs = allBlogs; // Show all blogs as featured
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

  Widget _buildBlogCard(BlogModel blog, double screenWidth) {
    return Container(
      width: screenWidth * 0.8, // 80% of screen width
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlogContentScreen(blog: blog),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blog Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[300],
                child: Image.network(
                  blog.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Blog Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      blog.category,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Title
                  Text(
                    blog.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Excerpt
                  Text(
                    blog.excerpt,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Author and Read Time
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: NetworkImage(blog.authorImage),
                        onBackgroundImageError: (exception, stackTrace) {
                          // Handle image error
                        },
                        child: blog.authorImage.isEmpty
                            ? Icon(Icons.person, size: 12, color: Colors.grey[600])
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          blog.author,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 10,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${blog.readTime}m',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  dataCard(
                    'Battery Level',
                    _batteryLevel,
                    Colors.orange,
                    Icons.battery_full,
                    screenWidth,
                  ),
                  dataCard(
                    'Temperature',
                    _temperature,
                    Colors.red,
                    Icons.thermostat,
                    screenWidth,
                  ),
                  dataCard(
                    'Spray Status',
                    _sprayStatus,
                    _sprayStatus == 'Spraying' ? Colors.green : Colors.grey,
                    Icons.water_drop,
                    screenWidth,
                  ),
                ],
              ),
              
              SizedBox(height: screenHeight * 0.04),
              
              // Blog Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Blogs',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BlogListScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: screenHeight * 0.02),
              
              // Horizontal Blog Cards
              SizedBox(
                height: 280, // Fixed height for horizontal scrolling
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: _featuredBlogs.length,
                  itemBuilder: (context, index) {
                    return _buildBlogCard(_featuredBlogs[index], screenWidth);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}