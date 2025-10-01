import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class AddFoodPostScreen extends StatefulWidget {
  const AddFoodPostScreen({super.key});

  @override
  State<AddFoodPostScreen> createState() => _AddFoodPostScreenState();
}

class _AddFoodPostScreenState extends State<AddFoodPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController(); // Added food name controller
  final _detailsController = TextEditingController();
  final _quantityController = TextEditingController();

  String _selectedFoodType = 'Veg';
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isPosting = false;
  bool _isLocationLoading = false;

  // Location variables
  double? _latitude;
  double? _longitude;
  String _locationText = 'Tap to get current location';

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Set default time to 2 hours from now
    final now = DateTime.now().add(const Duration(hours: 2));
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D4A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D4A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationText = 'Getting location...';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog(
          'Location Services Disabled',
          'Please enable location services to get your current location.',
        );
        setState(() {
          _isLocationLoading = false;
          _locationText = 'Tap to get current location';
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationDialog(
            'Location Permission Denied',
            'Location permissions are denied. Please grant location permission to use this feature.',
          );
          setState(() {
            _isLocationLoading = false;
            _locationText = 'Tap to get current location';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationDialog(
          'Location Permission Permanently Denied',
          'Location permissions are permanently denied. Please enable them in app settings.',
          showSettingsButton: true,
        );
        setState(() {
          _isLocationLoading = false;
          _locationText = 'Tap to get current location';
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationText = 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isLocationLoading = false;
      });

      _showSnackBar('Location fetched successfully!');

    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLocationLoading = false;
        _locationText = 'Failed to get location. Tap to retry.';
      });
      _showSnackBar('Failed to get location. Please try again.', isError: true);
    }
  }

  void _showLocationDialog(String title, String content, {bool showSettingsButton = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (showSettingsButton)
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
              ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime() {
    final date = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final time = _selectedTime.format(context);
    return '$date at $time';
  }

  Future<void> _postFood() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if location is fetched
    if (_latitude == null || _longitude == null) {
      _showSnackBar('Please fetch your location before posting', isError: true);
      return;
    }

    if (user == null) {
      _showSnackBar('Please log in to post food', isError: true);
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      // Generate unique post ID
      const uuid = Uuid();
      final postId = 'FP${uuid.v4().substring(0, 8).toUpperCase()}';

      // Create expiry timestamp
      final expiryDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create post data according to your table structure
      final postData = {
        'postId': postId,
        'donorId': user!.uid,
        'foodName': _foodNameController.text.trim(), // Added food name field
        'foodType': _selectedFoodType,
        'quantity': int.parse(_quantityController.text),
        'latitude': _latitude,
        'longitude': _longitude,
        'locationText': _locationText,
        'isAccepted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'Details': _detailsController.text.trim(),
        'expiryDate': Timestamp.fromDate(expiryDateTime),
        // Additional fields for better functionality
        'status': 'Available',
        'acceptedBy': null,
        'acceptedAt': null,
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .set(postData);

      _showSnackBar('Food post created successfully!');

      // Navigate back to home screen
      if (mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      print('Error creating post: $e');
      _showSnackBar('Error creating post. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: isError ? 4 : 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const CircleAvatar(
              backgroundColor: Color(0xFF8B4A9C),
              radius: 18,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D4A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('🏠', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Add Surplus Meals',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Food Name Section
              const Text(
                'Food Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _foodNameController,
                decoration: InputDecoration(
                  hintText: 'Enter food name (e.g., Veg Biryani, Dal Fry)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E7D4A), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: const Icon(Icons.fastfood, color: Color(0xFF2E7D4A)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter food name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Food Details Section
              const Text(
                'Food Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Additional details about the food (optional)...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E7D4A), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  // Made details optional since we now have food name as the primary field
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Food Type Selection
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Vegetarian'),
                      value: 'Veg',
                      groupValue: _selectedFoodType,
                      onChanged: (value) {
                        setState(() {
                          _selectedFoodType = value!;
                        });
                      },
                      activeColor: const Color(0xFF2E7D4A),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Non-Vegetarian'),
                      value: 'Non-Veg',
                      groupValue: _selectedFoodType,
                      onChanged: (value) {
                        setState(() {
                          _selectedFoodType = value!;
                        });
                      },
                      activeColor: const Color(0xFF2E7D4A),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quantity Section
              const Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Number of meals (e.g., 50)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E7D4A), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: const Icon(Icons.restaurant, color: Color(0xFF2E7D4A)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Location Section
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              InkWell(
                onTap: _isLocationLoading ? null : _getCurrentLocation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_latitude == null || _longitude == null)
                          ? Colors.grey[300]!
                          : const Color(0xFF2E7D4A),
                      width: (_latitude == null || _longitude == null) ? 1 : 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isLocationLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D4A)),
                          ),
                        )
                      else
                        Icon(
                          (_latitude == null || _longitude == null)
                              ? Icons.location_on_outlined
                              : Icons.location_on,
                          color: (_latitude == null || _longitude == null)
                              ? const Color(0xFF2E7D4A)
                              : Colors.green,
                          size: 20,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _locationText,
                          style: TextStyle(
                            fontSize: 14,
                            color: (_latitude == null || _longitude == null)
                                ? Colors.grey[600]
                                : const Color(0xFF2E7D4A),
                            fontWeight: (_latitude == null || _longitude == null)
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (!_isLocationLoading && _latitude == null && _longitude == null)
                        Icon(
                          Icons.touch_app,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Expiry Date Section
              const Text(
                'Expiry Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B73FF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.calendar_today,
                                color: Color(0xFF6B73FF), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B73FF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.access_time,
                                color: Color(0xFF6B73FF), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Add Images Section (Placeholder for future implementation)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: Color(0xFF6B73FF),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Images',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(Coming Soon)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Post Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _postFood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D4A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isPosting
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Posting...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                      : const Text(
                    'Post',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Add Post is selected
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
            // Already on Add Post
              break;
            case 1:
            // Navigate back to Home
              Navigator.pop(context);
              break;
            case 2:
            // Navigate to History
              print('Navigate to History');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: "Add Post",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            label: "History",
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _detailsController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}