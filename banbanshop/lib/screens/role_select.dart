// lib/screens/role_select.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banbanshop/screens/buyer/province_selection.dart';
import 'package:banbanshop/screens/auth/seller_login_screen.dart';
import 'dart:ui'; // Required for BackdropFilter
import 'package:cached_network_image/cached_network_image.dart';

class RoleSelectPage extends StatefulWidget {
  const RoleSelectPage({super.key});

  @override
  State<RoleSelectPage> createState() => _RoleSelectPageState();
}

class _RoleSelectPageState extends State<RoleSelectPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget sellerIconWidget = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3), // เพิ่มความทึบเล็กน้อย
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.storefront_rounded,
        color: Colors.white,
        size: 24,
      ),
    );

    final Widget buyerIconWidget = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3), // เพิ่มความทึบเล็กน้อย
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.shopping_cart_rounded,
        color: Colors.white,
        size: 24,
      ),
    );


    return Scaffold(
      body: Container(
        // --- [การแก้ไข] เปลี่ยนชุดสี Gradient ของพื้นหลัง ---
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF89F7FE), // สีฟ้าสว่าง
              Color(0xFF66A6FF), // สีฟ้าอมเขียว
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedBackgroundShapes(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: 'https://firebasestorage.googleapis.com/v0/b/banbanshop.firebasestorage.app/o/icon%20basket.png?alt=media&token=f5c2f07c-ff19-4001-afa4-44ee4d0e9a83',
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white.withOpacity(0.8),
                                        strokeWidth: 2.0,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'บ้านบ้านช็อป',
                                style: GoogleFonts.kanit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.2), // ลดความเข้มของเงา
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 48),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      // --- [การแก้ไข] ปรับสีและความทึบของการ์ด ---
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'เลือกบทบาทของคุณ',
                                          style: GoogleFonts.kanit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildModernRoleButton(
                                          context,
                                          iconWidget: buyerIconWidget,
                                          label: 'ผู้ซื้อ',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => ProvinceSelectionPage()),
                                            );
                                          },
                                          // --- [การแก้ไข] เปลี่ยนชุดสีปุ่มผู้ซื้อ ---
                                          gradientColors: const [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                                          isFirst: true,
                                        ),
                                        const SizedBox(height: 20),
                                        _buildModernRoleButton(
                                          context,
                                          iconWidget: sellerIconWidget,
                                          label: 'ผู้ขาย',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const SellerLoginScreen()),
                                            );
                                          },
                                           // --- [การแก้ไข] เปลี่ยนชุดสีปุ่มผู้ขาย ---
                                          gradientColors: const [Color(0xFF6DD5FA), Color(0xFF29FFC6)],
                                          isFirst: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedBackgroundShapes() {
    // ปรับสีวงกลมพื้นหลังให้สว่างขึ้น
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -50,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  20 * _animationController.value,
                  30 * _animationController.value,
                ),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 150,
          right: -80,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -15 * _animationController.value,
                  -20 * _animationController.value,
                ),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: -120,
          left: -30,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  10 * _animationController.value,
                  -25 * _animationController.value,
                ),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernRoleButton(
    BuildContext context, {
    required Widget iconWidget,
    required String label,
    required VoidCallback onPressed,
    required List<Color> gradientColors,
    required bool isFirst,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 70),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                iconWidget,
                const SizedBox(width: 16),
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
