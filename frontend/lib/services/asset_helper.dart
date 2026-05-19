import 'dart:io';
import 'package:flutter/material.dart';

class AssetHelper {
  // Absolute file paths pointing directly to our premium local AI generated assets
  static const String onboardingPath = "C:/Users/Home/.gemini/antigravity/brain/a7941b51-e796-4cf3-80e8-3d234a2159a1/kissanai_onboarding_1779098795509.png";
  static const String tractorBannerPath = "C:/Users/Home/.gemini/antigravity/brain/a7941b51-e796-4cf3-80e8-3d234a2159a1/kissanai_tractor_banner_1779098778429.png";
  static const String avatarPlaceholderPath = "C:/Users/Home/.gemini/antigravity/brain/a7941b51-e796-4cf3-80e8-3d234a2159a1/kissanai_avatar_placeholder_1779099002939.png";

  /// Helper to safely load our generated image file. Fallbacks gracefully to placeholder icons
  /// if run outside the local filesystem environment.
  static Widget getOnboardingImage({double? width, double? height, BoxFit fit = BoxFit.cover}) {
    final file = File(onboardingPath);
    if (file.existsSync()) {
      return Image.file(file, width: width, height: height, fit: fit);
    }
    return Container(
      color: Colors.emerald.withOpacity(0.1),
      child: const Center(
        child: Icon(Icons.agriculture, size: 80, color: Colors.emeraldAccent),
      ),
    );
  }

  static Widget getTractorBanner({double? width, double? height, BoxFit fit = BoxFit.cover}) {
    final file = File(tractorBannerPath);
    if (file.existsSync()) {
      return Image.file(file, width: width, height: height, fit: fit);
    }
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.emerald.shade900, Colors.teal.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.airport_shuttle, size: 50, color: Colors.emeraldAccent),
      ),
    );
  }

  static Widget getAvatarPlaceholder({double? width, double? height, BoxFit fit = BoxFit.cover}) {
    final file = File(avatarPlaceholderPath);
    if (file.existsSync()) {
      return ClipOval(
        child: Image.file(file, width: width, height: height, fit: fit),
      );
    }
    return Container(
      width: width ?? 50,
      height: height ?? 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
      ),
      child: const Icon(Icons.person, color: Colors.white70),
    );
  }
}
