import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  final void Function(BuildContext context) onStart;

  const SplashScreen({super.key, required this.onStart});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _idleLogoOffset;
  late final Animation<Offset> _idleTextOffset;

  bool _swipeTriggered = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _authChecked = false;

  @override
  void initState() {
    super.initState();

    _auth.authStateChanges().listen((user) {
      if (!_authChecked) {
        _authChecked = true;
        if (user == null) {
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          widget.onStart(context);
        }
      }
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _idleLogoOffset = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.02, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _idleTextOffset = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.03, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSwipe() {
    if (_swipeTriggered) return;
    setState(() => _swipeTriggered = true);

    _controller.stop();
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onStart(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            _handleSwipe();
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "lib/assets/images/background_1.png",
                fit: BoxFit.cover,
              ),
            ),

            // Glide logo and tagline
            AnimatedSlide(
              offset: _swipeTriggered ? const Offset(-1.5, 0) : Offset.zero,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SlideTransition(
                        position: _idleLogoOffset,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Make logo width responsive up to 50% of screen width
                            final logoWidth = constraints.maxWidth * 0.5;
                            return SvgPicture.asset(
                              "lib/assets/images/glide_logo.svg",
                              width: 220,
                              height: 300,
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8), // reduced from 16 to 8 for closer spacing
                      SlideTransition(
                        position: _idleTextOffset,
                        child: const Text(
                          'Glide: Find Your Crew, Faster.',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'LeagueSpartan-Regular',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '◁ GLIDE TO START',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'LeagueSpartan-Regular',
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
