import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:kasuwa/screens/home_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/screens/login_screen.dart';

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
          "Explore the vast marketplace of Jos with thousands of products at your fingertips.",
      "icon": Icons.shopping_bag_outlined,
    },
    {
      "title": "Secure Payments",
      "desc":
          "Experience safe and seamless transactions with our integrated payment systems.",
      "icon": Icons.lock_outline,
    },
    {
      "title": "Fast Delivery",
      "desc": "Get your orders delivered to your doorstep in record time.",
      "icon": Icons.local_shipping_outlined,
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
            const Spacer(),
            // Carousel
            CarouselSlider.builder(
              carouselController: _controller,
              itemCount: _slides.length,
              itemBuilder: (context, index, realIndex) {
                final slide = _slides[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(slide['icon'],
                            size: 80, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        slide['title'],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        slide['desc'],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                );
              },
              options: CarouselOptions(
                height: size.height * 0.6,
                viewportFraction: 1,
                onPageChanged: (index, reason) {
                  setState(() => _current = index);
                },
              ),
            ),

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

            // Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EnhancedHomeScreen()));
                    },
                    child: const Text("Get Started"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
