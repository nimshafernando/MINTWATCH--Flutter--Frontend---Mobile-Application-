import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the video player and mute the video
    _controller = VideoPlayerController.asset('assets/hola.mp4')
      ..initialize().then((_) {
        setState(() {
          _controller.play();
          _controller.setLooping(true);
          _controller.setVolume(0.0); // Mute the video
        });
      });

    // Animation controller for transition effect
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Restart the video when returning to this screen
    if (_controller.value.isInitialized && !_controller.value.isPlaying) {
      _controller.play();
    }
  }

  // Method to start the animated transition and navigate
  void _navigateWithTransition(String route) {
    _animationController.forward().then((_) {
      Navigator.pushNamed(context, route).then((_) {
        // Restart the animation controller and video player when navigating back
        _animationController.reset();
        if (_controller.value.isInitialized && !_controller.value.isPlaying) {
          _controller.play();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video background
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size?.width ?? 0,
                height: _controller.value.size?.height ?? 0,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          // Fade transition for splash screen animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(color: Colors.black),
          ),
          // Overlay content
          Column(
            children: [
              Spacer(),
              // Logo in the center
              Center(
                child: Image.asset(
                  'assets/hello.png', // Replace with your logo
                  height: 100, // Adjust the size accordingly
                ),
              ),
              SizedBox(height: 20),
              // Slogan text styled similarly to the provided example
              Text(
                'Where the World Collects Watches',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Serif', // Use a similar serif font
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 80),
              // Buttons at the bottom
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _navigateWithTransition('/register'); // Trigger transition and navigate to register
                      },
                      child: Text('Create Account', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Square edges
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _navigateWithTransition('/login'); // Trigger transition and navigate to login
                      },
                      child: Text('Sign In', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: Colors.white, width: 2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Square edges
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30), // Adjust spacing from the bottom if needed
            ],
          ),
        ],
      ),
    );
  }
}
