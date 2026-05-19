import 'package:flutter/material.dart';
import 'package:kissanai/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../services/asset_helper.dart';
import '../../providers/language_provider.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    final List<Map<String, String>> slides = [
      {
        "title": langProvider.translate('onboarding_1_title'),
        "desc": langProvider.translate('onboarding_1_body'),
        "tag": "ZABAANAI & GEMINI ORCHESTRATION"
      },
      {
        "title": langProvider.translate('onboarding_2_title'),
        "desc": langProvider.translate('onboarding_2_body'),
        "tag": "REAL-TIME WEBSOCKETS"
      },
      {
        "title": langProvider.translate('onboarding_3_title'),
        "desc": langProvider.translate('onboarding_3_body'),
        "tag": "DYNAMIC ARBITRATION"
      }
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF022E17)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Language Toggle & Skip Button Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Premium Bilingual Language Toggle Switch Pill
                    InkWell(
                      onTap: () {
                        langProvider.toggleLanguage();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "EN",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: langProvider.isUrdu ? Colors.white38 : AppColors.emeraldAccent,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 1,
                              height: 10,
                              color: Colors.white24,
                            ),
                            Text(
                              "اردو",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: langProvider.isUrdu ? AppColors.emeraldAccent : Colors.white38,
                                fontFamily: 'Noto Naskh Arabic',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Skip Button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        langProvider.translate('skip'),
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. High-Fidelity Local Vector Banner Illustration
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: -2,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: AssetHelper.getOnboardingImage(),
                  ),
                ),
              ),

              // 3. Sliding PageView text contents
              Expanded(
                flex: 3,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemCount: slides.length,
                  itemBuilder: (context, idx) {
                    final slide = slides[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.emeraldAccent.withOpacity(0.4)),
                            ),
                            child: Text(
                              slide["tag"]!,
                              style: const TextStyle(color: AppColors.emeraldAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide["title"]!,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide["desc"]!,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5, fontFamily: 'Plus Jakarta Sans'),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 4. Dot indicator and dynamic forward action buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Slide Indicators
                    Row(
                      children: List.generate(slides.length, (index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6.0),
                          width: _currentPage == index ? 24.0 : 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: _currentPage == index ? AppColors.emeraldAccent : Colors.white24,
                          ),
                        );
                      }),
                    ),

                    // Next/Start Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      onPressed: () {
                        if (_currentPage < slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        }
                      },
                      child: Text(
                        _currentPage == slides.length - 1 
                            ? langProvider.translate('get_started') 
                            : langProvider.translate('next'),
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

