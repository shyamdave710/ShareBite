import 'package:flutter/material.dart';

// class RegistersignUp extends StatelessWidget {
//   final String role;
//
//   const RegistersignUp({super.key, required this.role});
//
//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;
//
//     return Scaffold(
//       resizeToAvoidBottomInset: true, // Important for keyboard handling
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Logo
//               Center(
//                 child: ClipRRect(
//                   borderRadius: const BorderRadius.all(Radius.circular(35.0)),
//                   child: Image.asset(
//                     'assets/images/logo.png',
//                     height: size.height * 0.25,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//
//               // Role text
//               Text(
//                 "Role as : $role",
//                 style: const TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 30),
//
//               // Username Field
//               const Text(
//                 "UserName",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 5),
//               TextField(
//                 decoration: InputDecoration(
//                   hintText: "Enter UserName",
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 15),
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // Phone Number Field
//               const Text(
//                 "Phone Number",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 5),
//               TextField(
//                 keyboardType: TextInputType.phone,
//                 decoration: InputDecoration(
//                   hintText: "Enter Phone Number",
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 15),
//                 ),
//               ),
//               const SizedBox(height: 120),
//               // Register Button
//               Center(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // Handle register action
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color.fromRGBO(57, 81, 68, 1.0),
//                     elevation: 15,
//                     side: const BorderSide(color: Color.fromRGBO(57, 81, 68, 1.0), width: 2),
//                     shadowColor: Colors.black,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     padding: const EdgeInsets.all(15),
//                   ),
//                   child: const Text(
//                     "Register",
//                     style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_bite_try1/screens/otp_verify_screen.dart';
import 'package:share_bite_try1/utils/app_scaffold.dart';

class RegisterSignUp extends StatefulWidget {
  final String role;

  const RegisterSignUp({super.key, required this.role});

  @override
  State<RegisterSignUp> createState() => _RegisterSignUpState();
}

class _RegisterSignUpState extends State<RegisterSignUp> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isSendingOtp = false;

  void sendOTP(String phoneNumber) async {
    setState(() {
      isSendingOtp = true;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Optional: Auto sign-in
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          isSendingOtp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP Failed: ${e.message}")),
        );
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return AppScaffold(
      backgroundColor: Colors.white,
      title: "ShareBite",
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: size.height * 0.25,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Role as : ${widget.role}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              const Text("UserName", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  hintText: "Enter UserName",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Phone Number", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Enter Phone Number (e.g. +91XXXXXXXXXX)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                ),
              ),
              const SizedBox(height: 80),
              Center(
                child: ElevatedButton(
                  onPressed: isSendingOtp
                      ? null
                      : () {
                    String phone = phoneController.text.trim();
                    if (phone.isEmpty || !phone.startsWith('+')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Enter valid phone number with country code")),
                      );
                      return;
                    }
                    if (usernameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Enter a username")),
                      );
                      return;
                    }
                    sendOTP(phone);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(57, 81, 68, 1.0),
                    elevation: 15,
                    side: const BorderSide(color: Color.fromRGBO(57, 81, 68, 1.0), width: 2),
                    shadowColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(15),
                  ),
                  child: isSendingOtp
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Register",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
