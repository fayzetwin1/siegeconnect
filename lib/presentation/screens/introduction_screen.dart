import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import 'home_screen.dart';

class IntroductionScreen extends ConsumerStatefulWidget {
  const IntroductionScreen({super.key});

  @override
  ConsumerState<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends ConsumerState<IntroductionScreen>
    with SingleTickerProviderStateMixin {
  final _linkController = TextEditingController();
  late AnimationController _animController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _finishIntro() {
    final link = _linkController.text.trim();
    if (link.isNotEmpty) {
      ref.read(settingsProvider.notifier).updateSubLink(link);
    }
    ref.read(settingsProvider.notifier).completeIntro();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Widget _buildGlowingBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final isLight = colorScheme.brightness == Brightness.light;
    final primaryOpacity = isLight ? 0.4 : 0.15;
    final tertiaryOpacity = isLight ? 0.3 : 0.1;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final val = _animController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -50 - (val * 20),
                    left: -50 - (val * 30),
                    child: Transform.scale(
                      scale: 1.0 + (val * 0.2),
                      child: _buildGlowingBlob(
                        colorScheme.primary.withOpacity(primaryOpacity),
                        400,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50 + (val * 30),
                    right: -50 - (val * 20),
                    child: Transform.scale(
                      scale: 1.0 + ((1 - val) * 0.2),
                      child: _buildGlowingBlob(
                        colorScheme.tertiary.withOpacity(tertiaryOpacity),
                        500,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 48.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to SiegeConnect',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Setup your VPN client in just two simple steps.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Step Content
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _currentStep == 0
                            ? _buildThemeStep(colorScheme, settings)
                            : _buildLinkStep(colorScheme),
                      ),
                      const SizedBox(height: 48),

                      // Navigation Buttons
                      if (_currentStep == 0)
                        Center(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text(
                              'Next Step',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () => setState(() => _currentStep++),
                          ),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () => setState(() => _currentStep--),
                            ),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text(
                                'Finish & Connect',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () => _finishIntro(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeStep(ColorScheme colorScheme, dynamic settings) {
    return Column(
      key: const ValueKey('step0'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Choose your style',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'system',
              icon: Icon(Icons.brightness_auto),
              label: Text('System'),
            ),
            ButtonSegment(
              value: 'light',
              icon: Icon(Icons.light_mode),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: 'dark',
              icon: Icon(Icons.dark_mode),
              label: Text('Dark'),
            ),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (Set<String> newSelection) {
            ref
                .read(settingsProvider.notifier)
                .setThemeMode(newSelection.first);
          },
        ),
      ],
    );
  }

  Widget _buildLinkStep(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('step1'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Connect your Subscription',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Paste your subscription link from the Telegram bot below.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () async {
            final url = Uri.parse('https://t.me/siegeconnectbot');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
          icon: const Icon(Icons.telegram),
          label: const Text(
            'Get Key from Telegram Bot',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _linkController,
          decoration: InputDecoration(
            hintText: 'https://...',
            prefixIcon: const Icon(Icons.link),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _finishIntro(),
          child: const Text('Skip for now'),
        ),
      ],
    );
  }
}
