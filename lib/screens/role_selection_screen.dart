import 'package:flutter/material.dart';

import '../services/remote_config_service.dart';

// Top-level colors + non-const RoleSelectionScreen constructor reduce hot
// reload failures ("Const class cannot remove fields") after UI refactors.
const Color _primaryGreen = Color(0xFF1A5C35);
const Color _gradientEnd = Color(0xFF2E7D52);
const Color _lightGreen = Color(0xFFE8F4EE);
const Color _white = Color(0xFFFFFFFF);
const Color _background = Color(0xFFF4F6F8);
const Color _textDark = Color(0xFF1A1A2E);
const Color _textMuted = Color(0xFF6B7280);

class RoleSelectionScreen extends StatelessWidget {
  /// Non-const so hot reload can patch this widget after edits (avoids VM
  /// "Const class cannot remove fields" when `const` was used site-wide).
  // ignore: prefer_const_constructors_in_immutables
  RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (RemoteConfigService().maintenanceMode) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A5C35),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction_rounded, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text(
                'App under maintenance',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                'Please check back later',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primaryGreen, _gradientEnd],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: _white,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            'assets/images/bano_qabil_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'BQ Spark Portal',
                        style: TextStyle(
                          color: _white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'High Performance Student Program',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Login to continue your HP journey',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/student-login');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _primaryGreen, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryGreen.withValues(alpha: 0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _lightGreen,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: _primaryGreen,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Student Login',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: _textDark,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Access tasks, progress & leaderboard',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: _primaryGreen,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin-login');
                  },
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Admin? ',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 13,
                          ),
                        ),
                        TextSpan(
                          text: 'Continue as Admin',
                          style: TextStyle(
                            color: _primaryGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
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
}
