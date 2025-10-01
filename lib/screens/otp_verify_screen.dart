import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_bite_try1/screens/deliveryPerson/delivery_person_home_Screen.dart';
import 'package:share_bite_try1/screens/donors/home_screenDonor.dart';
import 'package:share_bite_try1/screens/ngos/NGOHomeScreen.dart';
import 'dart:async';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String role;
  final String username;

  const OTPVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.role,
    required this.username,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  bool isLoading = false;
  bool canResend = false;
  int resendTimer = 60;
  Timer? _timer;

  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  // Test credentials for development
  final String testPhoneNumber = "+91 99999 99999";
  final String testOTP = "123456";

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startResendTimer();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _fadeController.forward();
  }

  void _startResendTimer() {
    setState(() {
      resendTimer = 60;
      canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        resendTimer--;
        if (resendTimer == 0) {
          canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    _timer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get enteredOTP {
    return otpControllers.map((controller) => controller.text).join();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all digits are entered
    if (enteredOTP.length == 6) {
      _verifyOTP();
    }
  }

  Future<bool> _checkExistingRole() async {
    try {
      // Query Firestore to check if phone number exists with different role
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: widget.phoneNumber)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final existingUser = querySnapshot.docs.first.data();
        final existingRole = existingUser['role'] as String;

        if (existingRole != widget.role) {
          _showRoleConflictDialog(existingRole);
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Error checking existing role: $e');
      return true; // Allow if there's an error checking
    }
  }

  void _showRoleConflictDialog(String existingRole) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[600], size: 28),
              const SizedBox(width: 12),
              const Text("Account Exists"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "This phone number is already registered as:",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(57, 81, 68, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(_getRoleIcon(existingRole), style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      existingRole,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(57, 81, 68, 1.0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "You cannot register the same phone number for multiple roles. Please use a different number or sign in with your existing account.",
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to registration
                Navigator.of(context).pop(); // Go back to welcome
              },
              child: const Text("Go Back"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                // Here you could navigate to sign-in screen instead
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(57, 81, 68, 1.0),
                foregroundColor: Colors.white,
              ),
              child: const Text("Sign In Instead"),
            ),
          ],
        );
      },
    );
  }

  String _getRoleIcon(String role) {
    switch (role) {
      case "Donor":
        return "🍽️";
      case "NGO":
        return "🏢";
      case "Delivery Partner":
        return "🚴‍♂️";
      default:
        return "👤";
    }
  }

  void _verifyOTP() async {
    final otp = enteredOTP;

    if (otp.length != 6) {
      _showErrorMessage("Please enter complete OTP");
      _shakeController.forward().then((_) => _shakeController.reset());
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Check for role conflict before proceeding
      final canProceed = await _checkExistingRole();
      if (!canProceed) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Handle test OTP for development
      if (widget.phoneNumber == testPhoneNumber && otp == testOTP) {
        await _saveUserToFirestore("test-uid");
        if (!mounted) return;
        _navigateToHome();
        return;
      }

      // Regular Firebase OTP verification
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      await _saveUserToFirestore(uid);

      if (!mounted) return;
      _navigateToHome();

    } on FirebaseAuthException catch (e) {
      _showErrorMessage("Invalid OTP. Please try again.");
      _shakeController.forward().then((_) => _shakeController.reset());
      _clearOTP();
    } catch (e) {
      _showErrorMessage("Something went wrong. Please try again.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveUserToFirestore(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'phone': widget.phoneNumber,
      'username': widget.username,
      'role': widget.role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _navigateToHome() {
    // Navigate to role-specific home screen
    Widget homeScreen;

    switch (widget.role) {
      case "Donor":
        homeScreen = const DonorHomeScreen();
        break;
      case "NGO":
        homeScreen = const NGOHomeScreen();
        break;
      case "Delivery Partner":
        homeScreen = const DeliveryHomeScreen();
        break;
      default:
      // Fallback - should not happen with proper role validation
        homeScreen = const DonorHomeScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => homeScreen),
    );
  }

  void _clearOTP() {
    for (var controller in otpControllers) {
      controller.clear();
    }
    focusNodes[0].requestFocus();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resendOTP() {
    _startResendTimer();
    _showErrorMessage("OTP sent again!");
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    bool isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(57, 81, 68, 1.0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Verify OTP',
          style: TextStyle(
            color: Color.fromRGBO(57, 81, 68, 1.0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? size.width * 0.15 : 24,
            vertical: 20,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Header icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(57, 81, 68, 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.sms_outlined,
                    size: 40,
                    color: Color.fromRGBO(57, 81, 68, 1.0),
                  ),
                ),

                const SizedBox(height: 32),

                // Title and subtitle
                Text(
                  "Verify Your Phone",
                  style: TextStyle(
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromRGBO(57, 81, 68, 1.0),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "Enter the 6-digit code sent to",
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.phoneNumber,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromRGBO(57, 81, 68, 1.0),
                  ),
                ),

                // Test credentials info for development
                if (widget.phoneNumber == testPhoneNumber) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Test Mode: Use OTP 123456",
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // OTP input fields
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value * 10 * (1 - _shakeAnimation.value), 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) => _buildOTPField(index)),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(57, 81, 68, 1.0),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color.fromRGBO(57, 81, 68, 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      "Verify & Continue",
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Resend OTP section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive code? ",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: canResend ? _resendOTP : null,
                      child: Text(
                        canResend ? "Resend" : "Resend in ${resendTimer}s",
                        style: TextStyle(
                          color: canResend ? const Color.fromRGBO(57, 81, 68, 1.0) : Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Security note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Your phone number will be used securely and never shared with third parties.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
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

  Widget _buildOTPField(int index) {
    return SizedBox(
      width: 50,
      height: 60,
      child: TextField(
        controller: otpControllers[index],
        focusNode: focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color.fromRGBO(57, 81, 68, 1.0),
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.grey[50],
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
            borderSide: const BorderSide(
              color: Color.fromRGBO(57, 81, 68, 1.0),
              width: 2,
            ),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => _onOtpChanged(index, value),
      ),
    );
  }
}