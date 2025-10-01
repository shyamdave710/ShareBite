import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_bite_try1/screens/otp_verify_screen.dart';
import 'package:share_bite_try1/utils/app_scaffold.dart';

class RegisterSignUp extends StatefulWidget {
  final String role;

  const RegisterSignUp({super.key, required this.role});

  @override
  State<RegisterSignUp> createState() => _RegisterSignUpState();
}

class _RegisterSignUpState extends State<RegisterSignUp> with TickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isSendingOtp = false;
  String selectedCountryCode = "+91";
  String selectedCountryFlag = "🇮🇳";
  String selectedCountryName = "India";

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Common country codes
  final List<Map<String, String>> countries = [
    {"code": "+91", "flag": "🇮🇳", "name": "India"},
    {"code": "+1", "flag": "🇺🇸", "name": "United States"},
    {"code": "+44", "flag": "🇬🇧", "name": "United Kingdom"},
    {"code": "+971", "flag": "🇦🇪", "name": "UAE"},
    {"code": "+65", "flag": "🇸🇬", "name": "Singapore"},
    {"code": "+61", "flag": "🇦🇺", "name": "Australia"},
    {"code": "+49", "flag": "🇩🇪", "name": "Germany"},
    {"code": "+33", "flag": "🇫🇷", "name": "France"},
    {"code": "+81", "flag": "🇯🇵", "name": "Japan"},
    {"code": "+86", "flag": "🇨🇳", "name": "China"},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void sendOTP(String phoneNumber) async {
    setState(() {
      isSendingOtp = true;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          isSendingOtp = false;
        });
        _showErrorSnackBar("OTP Failed: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          isSendingOtp = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              verificationId: verificationId,
              phoneNumber: phoneNumber,
              role: widget.role,
              username: usernameController.text.trim(),
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 50,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Select Country",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(57, 81, 68, 1.0),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: countries.length,
                itemBuilder: (context, index) {
                  final country = countries[index];
                  return ListTile(
                    leading: Text(
                      country["flag"]!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(country["name"]!),
                    trailing: Text(
                      country["code"]!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(57, 81, 68, 1.0),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selectedCountryCode = country["code"]!;
                        selectedCountryFlag = country["flag"]!;
                        selectedCountryName = country["name"]!;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleIcon() {
    switch (widget.role) {
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    bool isTablet = size.width > 600;

    return AppScaffold(
      backgroundColor: Colors.white,
      title: "ShareBite",
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? size.width * 0.15 : 24,
            vertical: 20,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: isTablet ? size.height * 0.2 : size.height * 0.15,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Role indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(57, 81, 68, 0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color.fromRGBO(57, 81, 68, 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getRoleIcon(),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Registering as ${widget.role}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color.fromRGBO(57, 81, 68, 1.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Form section
                Text(
                  "Let's get you started!",
                  style: TextStyle(
                    fontSize: isTablet ? 26 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromRGBO(57, 81, 68, 1.0),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Create your ShareBite account",
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 32),

                // Username field
                _buildInputLabel("Full Name"),
                const SizedBox(height: 8),
                TextField(
                  controller: usernameController,
                  decoration: _buildInputDecoration(
                    hintText: "Enter your full name",
                    prefixIcon: Icons.person_outline,
                  ),
                ),

                const SizedBox(height: 24),

                // Phone number field
                _buildInputLabel("Phone Number"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Country code selector
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          color: Colors.grey[50],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(selectedCountryFlag, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 4),
                            Text(
                              selectedCountryCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                    // Phone number input
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: "Enter phone number",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            borderSide: BorderSide(
                              color: Color.fromRGBO(57, 81, 68, 1.0),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Phone number hint
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
                          "We'll send you a verification code via SMS",
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSendingOtp ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(57, 81, 68, 1.0),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color.fromRGBO(57, 81, 68, 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: isSendingOtp
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      "Send Verification Code",
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Terms text
                Center(
                  child: Text(
                    "By registering, you agree to our Terms & Privacy Policy",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Color.fromRGBO(57, 81, 68, 1.0),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[500]),
      prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder:  OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(57, 81, 68, 1.0),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  void _handleRegister() {
    String phone = phoneController.text.trim();
    String username = usernameController.text.trim();

    if (username.isEmpty) {
      _showErrorSnackBar("Please enter your full name");
      return;
    }

    if (phone.isEmpty || phone.length < 10) {
      _showErrorSnackBar("Please enter a valid phone number");
      return;
    }

    // Combine country code with phone number
    String fullPhoneNumber = selectedCountryCode + phone;
    sendOTP(fullPhoneNumber);
  }
}