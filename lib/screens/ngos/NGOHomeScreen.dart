import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_bite_try1/screens/introduction_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class NGOHomeScreen extends StatefulWidget {
  const NGOHomeScreen({super.key});

  @override
  State<NGOHomeScreen> createState() => _NGOHomeScreenState();
}

class _NGOHomeScreenState extends State<NGOHomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String ngoName = "NGO"; // Default value
  Position? currentPosition;

  // Filter variables
  String selectedFoodTypeFilter = 'All';
  String selectedLocationFilter = 'All';
  List<String> foodTypeOptions = ['All', 'Veg', 'Non-Veg'];
  List<String> locationOptions = ['All', 'Nearby (5km)', 'Nearby (10km)', 'City-wide'];

  @override
  void initState() {
    super.initState();
    _fetchNGOName();
    _getCurrentLocation();
  }

  Future<void> _fetchNGOName() async {
    try {
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              ngoName = data['username'] ?? data['name'] ?? "NGO";
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching NGO name: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // in km
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const IntroductionPage()),
            (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error logging out. Please try again.')),
        );
      }
    }
  }

  Future<void> _claimFood(String postId, Map<String, dynamic> postData) async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Claim Food'),
            content: Text('Do you want to claim "${postData['foodName']}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Claim'),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        // Update post status to claimed and add NGO details
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .update({
          'status': 'Claimed', // Match your Firestore case convention
          'claimedBy': user!.uid,
          'claimedByName': ngoName,
          'claimedAt': FieldValue.serverTimestamp(),
          'isAccepted': true, // Update the isAccepted field as well
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully claimed "${postData['foodName']}"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error claiming food: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error claiming food. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filter Options",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Food Type Filter
          Row(
            children: [
              const Text("Food Type: ", style: TextStyle(fontWeight: FontWeight.w500)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: foodTypeOptions.map((option) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(option),
                          selected: selectedFoodTypeFilter == option,
                          onSelected: (selected) {
                            setState(() {
                              selectedFoodTypeFilter = option;
                            });
                          },
                          selectedColor: Colors.orange[200],
                          checkmarkColor: Colors.orange[800],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Location Filter
          Row(
            children: [
              const Text("Location: ", style: TextStyle(fontWeight: FontWeight.w500)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: locationOptions.map((option) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(option),
                          selected: selectedLocationFilter == option,
                          onSelected: (selected) {
                            setState(() {
                              selectedLocationFilter = option;
                            });
                          },
                          selectedColor: Colors.blue[200],
                          checkmarkColor: Colors.blue[800],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _passesFilters(Map<String, dynamic> post) {
    // Food Type Filter
    if (selectedFoodTypeFilter != 'All') {
      String foodType = post['foodType']?.toString().toLowerCase() ?? '';
      if (selectedFoodTypeFilter.toLowerCase() != foodType) {
        return false;
      }
    }

    // Location Filter
    if (selectedLocationFilter != 'All' && currentPosition != null) {
      double? postLat = post['latitude']?.toDouble();
      double? postLng = post['longitude']?.toDouble();

      if (postLat != null && postLng != null) {
        double distance = _calculateDistance(
          currentPosition!.latitude,
          currentPosition!.longitude,
          postLat,
          postLng,
        );

        switch (selectedLocationFilter) {
          case 'Nearby (5km)':
            if (distance > 5) return false;
            break;
          case 'Nearby (10km)':
            if (distance > 10) return false;
            break;
          case 'City-wide':
            if (distance > 50) return false;
            break;
        }
      }
    }

    return true;
  }

  List<QueryDocumentSnapshot> _sortPostsByDistance(List<QueryDocumentSnapshot> posts) {
    if (currentPosition == null) return posts;

    posts.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      double? aLat = aData['latitude']?.toDouble();
      double? aLng = aData['longitude']?.toDouble();
      double? bLat = bData['latitude']?.toDouble();
      double? bLng = bData['longitude']?.toDouble();

      if (aLat == null || aLng == null) return 1;
      if (bLat == null || bLng == null) return -1;

      double aDistance = _calculateDistance(
        currentPosition!.latitude,
        currentPosition!.longitude,
        aLat,
        aLng,
      );

      double bDistance = _calculateDistance(
        currentPosition!.latitude,
        currentPosition!.longitude,
        bLat,
        bLng,
      );

      return aDistance.compareTo(bDistance);
    });

    return posts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.volunteer_activism,
                color: Colors.orange[800],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Hello, $ngoName",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "logout") {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "logout",
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text("Logout"),
                  ],
                ),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: Colors.orange,
                radius: 18,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Hero Section with illustration
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.orange[300]!,
                    Colors.orange[400]!,
                    Colors.orange[500]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Help Those in Need",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Find and claim food donations to distribute in your community",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),

            // Filter Section
            _buildFilterChips(),

            const SizedBox(height: 8),

            // Available Posts Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    "Available Food Posts",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  // Real-time indicator
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where('status', isEqualTo: 'Available') // Fixed case sensitivity
                        .snapshots(),
                    builder: (context, snapshot) {
                      return Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: snapshot.hasData ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.green[800]),
                                const SizedBox(width: 4),
                                Text(
                                  "Live Updates",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Available Posts List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('status', isEqualTo: 'Available') // Fixed case sensitivity
                    .orderBy('createdAt', descending: true) // Order by creation time
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView( // Fixed: Wrap with SingleChildScrollView
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min, // Fixed: Add mainAxisSize.min
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Error loading posts: ${snapshot.error}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => setState(() {}),
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView( // Fixed: Wrap with SingleChildScrollView
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min, // Fixed: Add mainAxisSize.min
                            children: [
                              Icon(
                                Icons.food_bank_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No available food posts",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Check back later for new donations",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  List<QueryDocumentSnapshot> posts = snapshot.data!.docs;

                  // Apply filters
                  posts = posts.where((doc) {
                    final postData = doc.data() as Map<String, dynamic>;
                    return _passesFilters(postData);
                  }).toList();

                  // Sort by distance
                  posts = _sortPostsByDistance(posts);

                  if (posts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView( // Fixed: Wrap with SingleChildScrollView
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min, // Fixed: Add mainAxisSize.min
                            children: [
                              Icon(
                                Icons.filter_alt_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No posts match your filters",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Try adjusting your filter settings",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final postDoc = posts[index];
                      final post = postDoc.data() as Map<String, dynamic>;

                      // Calculate distance if location is available
                      String distanceText = '';
                      if (currentPosition != null &&
                          post['latitude'] != null &&
                          post['longitude'] != null) {
                        double distance = _calculateDistance(
                          currentPosition!.latitude,
                          currentPosition!.longitude,
                          post['latitude'].toDouble(),
                          post['longitude'].toDouble(),
                        );
                        distanceText = ' • ${distance.toStringAsFixed(1)}km away';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IntrinsicHeight(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.restaurant,
                                        color: Colors.orange[800],
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            post['foodName'] ?? "Food Item",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.person, size: 12, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  "by ${post['donorName'] ?? 'Anonymous'}${distanceText}",
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 11,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Food type indicator
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: post['foodType']?.toLowerCase() == 'veg'
                                            ? Colors.green[100]
                                            : Colors.red[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        post['foodType'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: post['foodType']?.toLowerCase() == 'veg'
                                              ? Colors.green[800]
                                              : Colors.red[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Show location text instead of detail
                                if (post['locationText'] != null && post['locationText'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      post['locationText'],
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                // Bottom row with details and button
                                Row(
                                  children: [
                                    if (post['quantity'] != null) ...[
                                      Icon(Icons.shopping_basket, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 3),
                                      Text(
                                        "${post['quantity']}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],

                                    // Show expiry date
                                    if (post['expiryDate'] != null) ...[
                                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          _formatDate(post['expiryDate']),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _claimFood(postDoc.id, post),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        minimumSize: const Size(60, 28),
                                      ),
                                      child: const Text(
                                        "Claim",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Home is selected
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
            // Navigate to add volunteer screen
              print('Navigate to Add Volunteer');
              break;
            case 1:
            // Already on Home
              break;
            case 2:
            // Navigate to previous orders/history
              print('Navigate to Previous Orders');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_outlined),
            label: "Add Volunteer",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            label: "Previous Orders",
          ),
        ],
      ),
    );
  }

  // Helper method to format date
  String _formatDate(dynamic date) {
    try {
      if (date is Timestamp) {
        final dateTime = date.toDate();
        return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      }
      return "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }
}