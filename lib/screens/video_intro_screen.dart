import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'home_screen.dart';

class VideoIntroScreen extends StatefulWidget {
  const VideoIntroScreen({super.key});

  @override
  State<VideoIntroScreen> createState() => _VideoIntroScreenState();
}

class _VideoIntroScreenState extends State<VideoIntroScreen> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _fadingOut = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800)); // 1.8s
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);

    _controller = VideoPlayerController.asset(
      'assets/Inicio.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        setState(() {
          _initialized = true;
          _controller.play();
          _fadeController.forward();
        });
      });

    _controller.addListener(() {
      if (!_initialized) return;
      
      final position = _controller.value.position;
      final duration = _controller.value.duration;

      // Iniciar Fade Out 1.8 segundos antes de que termine
      if (!_fadingOut && position >= duration - const Duration(milliseconds: 1800)) {
        _fadingOut = true;
        _fadeController.reverse().then((_) => _navigateToHome());
      }
    });
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (!_fadingOut) {
            _fadingOut = true;
            _fadeController.reverse().then((_) => _navigateToHome());
          }
        },
        child: SizedBox.expand(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _initialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
          ),
        ),
      ),
    );
  }
}
