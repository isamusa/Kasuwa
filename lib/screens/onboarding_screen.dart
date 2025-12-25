import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:kasuwa/screens/home_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';
// import 'package:kasuwa/screens/login_screen.dart';
// import 'package:kasuwa/providers/auth_provider.dart';
// import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  final List<Map<String, dynamic>> _slides = [
    {
      "title": "Discover Latest Trends",
      "desc":
          "Explore the vast Nigerian marketplace with thousands of products at your fingertips.",
      "image": "assets/images/onboarding1.jpg",
    },
    {
      "title": "Secure Payments",
      "desc":
          "Experience safe and seamless transactions with our integrated payment systems.",
      "image": "assets/images/onboarding2.jpg",
    },
    {
      "title": "Fast Delivery",
      "desc": "Get your orders delivered to your doorstep in record time.",
      "image": "assets/images/onboarding3.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: CarouselSlider.builder(
                carouselController: _controller,
                itemCount: _slides.length,
                itemBuilder: (context, index, realIndex) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          // Allocating about 40% of screen height for the illustration
                          height: size.height * 0.4,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            slide['image'],
                            // BoxFit.contain ensures the entire illustration is visible without cropping
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['desc'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                options: CarouselOptions(
                  height: size.height * 0.75,
                  viewportFraction: 1,
                  enableInfiniteScroll: false,
                  onPageChanged: (index, reason) {
                    setState(() => _current = index);
                  },
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _slides.asMap().entries.map((entry) {
                        return GestureDetector(
                          onTap: () => _controller.animateToPage(entry.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _current == entry.key ? 24.0 : 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _current == entry.key
                                  ? AppTheme.primaryColor
                                  : AppTheme.primaryColor.withOpacity(0.2),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Spacer(),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_current == _slides.length - 1) {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const EnhancedHomeScreen()));
                          } else {
                            _controller.nextPage();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _current == _slides.length - 1
                              ? "Get Started"
                              : "Next",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Skip Button
                    if (_current != _slides.length - 1)
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EnhancedHomeScreen()));
                        },
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox(
                          height: 48), // Placeholder to keep layout stable
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
