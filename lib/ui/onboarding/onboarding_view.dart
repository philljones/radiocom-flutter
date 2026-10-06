import 'package:cuacfm/main.dart';
import 'package:cuacfm/utils/push_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _yellow = Color(0xFFFCD444);
const _dark = Color(0xFF1A1A1A);
// Show the revised English onboarding once to existing development installs.
const onboardingVersion = 2;

class OnboardingView extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingView({Key? key, required this.onFinished}) : super(key: key);

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  // Welcome, live listening, favourites, alerts, and language.
  static const _totalPages = 4;
  String? _selectedLocale;
  bool _requestingNotifications = false;
  bool _notificationsAllowed = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _currentPage = i);
  }

  Future<void> _enableNotifications() async {
    setState(() => _requestingNotifications = true);
    try {
      final allowed = await requestPushPermission();
      if (!mounted) return;
      setState(() => _notificationsAllowed = allowed);
      if (!allowed) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'You can enable notifications later in your device settings.'),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Unable to enable notifications. Please try again later.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _requestingNotifications = false);
    }
  }

  Future<void> _finish() async {
    // Gardar idioma seleccionado
    final prefs = await SharedPreferences.getInstance();
    if (_selectedLocale != null) {
      await prefs.setString('app_locale', _selectedLocale!);
      MyApp.setLocale(MyApp.parseLocale(_selectedLocale));
    }
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('onboarding_version', onboardingVersion);
    widget.onFinished();
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _yellow,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _yellow,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _yellow,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: _currentPage == _totalPages
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  children: [
                    _buildWelcomePage(),
                    _buildInfoPage(
                      icon: Icons.play_circle_filled,
                      text: "Listen to Aber Radio live, wherever you are.",
                    ),
                    _buildInfoPage(
                      icon: Icons.favorite,
                      text: "Keep your favourite programmes together.",
                    ),
                    _buildInfoPage(
                      icon: Icons.notifications_active,
                      text:
                          "Turn on alerts for your favourite programmes and receive a notification when they go live.",
                      subtitle:
                          "You can pause all alerts at any time in Settings.",
                      action: pushNotificationsEnabled
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: TextButton(
                                onPressed: _requestingNotifications ||
                                        _notificationsAllowed
                                    ? null
                                    : _enableNotifications,
                                child: Text(_requestingNotifications
                                    ? 'Enabling notifications…'
                                    : _notificationsAllowed
                                        ? 'Notifications enabled'
                                        : 'Enable notifications'),
                              ),
                            )
                          : null,
                    ),
                    _buildLocalePage(),
                  ],
                ),
              ),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pantalla 1: Benvida ───────────────────────────────────────────────────

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              "assets/graphics/aber-radio-app-icon.png",
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "ABER RADIO",
            style: TextStyle(
              color: _dark,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Community radio for Abergavenny and the surrounding area.\nThanks for listening.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _dark,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pantallas 2-4: Información ────────────────────────────────────────────

  Widget _buildInfoPage(
      {required IconData icon,
      required String text,
      String? subtitle,
      Widget? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: _dark,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _yellow, size: 48),
          ),
          const SizedBox(height: 40),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _dark,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 16),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _dark.withValues(alpha: 0.55),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ],
          if (action != null) action,
        ],
      ),
    );
  }

  // ── Pantalla 5: Categorías e programas ────────────────────────────────────

  Widget _buildLocaleChip(Map<String, String> l) {
    final isSelected = _selectedLocale == l['code'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedLocale = l['code']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 140,
          height: 52,
          decoration: BoxDecoration(
            color: isSelected ? _dark : _dark.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            l['label']!,
            style: TextStyle(
              color: isSelected ? _yellow : _dark,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalePage() {
    final locales = [
      {'code': 'en', 'label': 'English'},
      {'code': 'cy', 'label': 'Cymraeg'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: _dark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.language, color: _yellow, size: 48),
          ),
          const SizedBox(height: 36),
          const Text(
            "Finally, choose the app language",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _dark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: locales.map((l) => _buildLocaleChip(l)).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedLocale == null
                ? "If you don't choose one, the app will use your system language."
                : "",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _dark.withValues(alpha: 0.45),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Controis inferiores ───────────────────────────────────────────────────

  Widget _buildBottomControls() {
    final isLastPage = _currentPage == _totalPages;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: [
          // Puntos indicadores
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPages + 1, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? _dark : _dark.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLastPage ? _finish : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _dark,
                foregroundColor: _yellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                isLastPage ? "Get started" : "Next",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          if (!isLastPage)
            TextButton(
              onPressed: () {
                _pageController.animateToPage(
                  _totalPages,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(
                "Skip",
                style: TextStyle(
                  color: _dark.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
