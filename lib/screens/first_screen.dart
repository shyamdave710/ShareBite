import 'package:flutter/material.dart';
import 'package:share_bite_try1/screens/register_sign_in_screen.dart';
import 'package:share_bite_try1/utils/app_scaffold.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    bool isTablet = size.width > 600;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAF9),
            Colors.white,
          ],
        ),
      ),
      child: AppScaffold(
        title: "ShareBite",
        backgroundColor: Colors.transparent,
        child: SafeArea(
          child: Column(
            children: [
              // Header Section with Logo and Image
              Expanded(
                flex: isTablet ? 3 : 2,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.1,
                      vertical: size.height * 0.02,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with shadow
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
                              "assets/images/logo.png",
                              height: isTablet ? size.height * 0.2 : size.height * 0.18,
                              width: size.width * (isTablet ? 0.6 : 0.7),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        SizedBox(height: size.height * 0.03),

                        // Main image with rounded corners
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              "assets/images/img4.jpg",
                              height: isTablet ? size.height * 0.2 : size.height * 0.18,
                              width: size.width * (isTablet ? 0.6 : 0.7),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        SizedBox(height: size.height * 0.02),

                        // Subtitle text
                        Text(
                          "Share food, spread kindness",
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 16,
                            color: const Color.fromRGBO(57, 81, 68, 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // CTA Button Section
              Expanded(
                flex: 1,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Enhanced CTA Button
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 400 : double.infinity,
                          ),
                          child: ElevatedButton(
                            onPressed: () => _showRoleSelection(context, size, isTablet),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(57, 81, 68, 1.0),
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: const Color.fromRGBO(57, 81, 68, 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 20 : 18,
                                horizontal: 30,
                              ),
                            ).copyWith(
                              overlayColor: MaterialStateProperty.all(
                                Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_add_outlined, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  "Get Started",
                                  style: TextStyle(
                                    fontSize: isTablet ? 22 : 20,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: size.height * 0.02),


                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoleSelection(BuildContext context, Size size, bool isTablet) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      barrierColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 50,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Text(
                  "Choose your role",
                  style: TextStyle(
                    color: const Color.fromRGBO(57, 81, 68, 1.0),
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 26 : 24,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Select how you'd like to contribute",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),

                const SizedBox(height: 32),

                // Role buttons
                isTablet
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _buildRoleButtons(context, isTablet),
                )
                    : Column(
                  children: _buildRoleButtons(context, isTablet)
                      .map((btn) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(width: double.infinity, child: btn),
                  ))
                      .toList(),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildRoleButtons(BuildContext context, bool isTablet) {
    final roles = [
      {
        'title': 'Donor',
        'subtitle': 'Share surplus food',
        'icon': Icons.restaurant_outlined,
        'role': 'Donor',
      },
      {
        'title': 'NGO',
        'subtitle': 'Distribute to communities',
        'icon': Icons.people_outline,
        'role': 'NGO',
      },
      {
        'title': 'Delivery Partner',
        'subtitle': 'Transport food safely',
        'icon': Icons.delivery_dining_outlined,
        'role': 'Delivery Partner',
      },
    ];

    return roles.map((role) => _buildRoleButton(
      context,
      title: role['title'] as String,
      subtitle: role['subtitle'] as String,
      icon: role['icon'] as IconData,
      role: role['role'] as String,
      isTablet: isTablet,
    )).toList();
  }

  Widget _buildRoleButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required String role,
        required bool isTablet,
      }) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterSignUp(role: role),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromRGBO(57, 81, 68, 1.0),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color.fromRGBO(57, 81, 68, 0.2),
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(isTablet ? 24 : 20),
      ).copyWith(
        overlayColor: MaterialStateProperty.all(
          const Color.fromRGBO(57, 81, 68, 0.05),
        ),
      ),
      child: isTablet
          ? Column(
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      )
          : Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}