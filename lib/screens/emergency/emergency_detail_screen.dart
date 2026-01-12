import 'emergency_additional_info_screen.dart';
import '../../services/emergency_service.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyDetailScreen extends StatefulWidget {
  final EmergencyService service;
  const EmergencyDetailScreen({super.key, required this.service});

  @override
  State<EmergencyDetailScreen> createState() => _EmergencyDetailScreenState();
}

class _EmergencyDetailScreenState extends State<EmergencyDetailScreen> {
  String? profileName;
  String? profilePhone;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loadingProfile = false);
      return;
    }

    final response = await supabase
        .from('profiles')
        .select('full_name, phone')
        .eq('id', user.id)
        .single();

    if (!mounted) return;
    setState(() {
      profileName = response['full_name'] ?? '';
      profilePhone = response['phone'] ?? '';
      _loadingProfile = false;
    });
  }

  int _selectedType = -1;

  List<_EmergencyType> _typesForTheme(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color tint(Color base) => base.withOpacity(isDark ? 0.22 : 0.10);
    Color border(Color base) => base.withOpacity(isDark ? 0.55 : 0.35);

    // Helper to pick a consistent accent per service type
    Color accentFor(EmergencyType t) {
      switch (t) {
        case EmergencyType.ambulance:
          return cs.error;
        case EmergencyType.police:
          return cs.primary;
        case EmergencyType.fire:
          return cs.tertiary;
        case EmergencyType.car:
          return cs.secondary;
      }
    }

    return emergencyServices.map((s) {
      final accent = accentFor(s.type);

      // Card base = surfaceContainerHighest (works in both light/dark)
      final bg = cs.surfaceContainerHighest;

      return _EmergencyType(
        emergencyType: s.type,
        emergencyService: s,
        icon: s.icon,
        title: s.name,
        // keep your original "available services"
        description: s.availableServices.join(', '),
        accent: accent,
        bg: bg,
        tint: tint(accent),
        border: border(accent),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_loadingProfile) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(child: CircularProgressIndicator(color: cs.error)),
      );
    }

    final types = _typesForTheme(context);

    final pageBg = cs.surface;
    final cardBg = cs.surfaceContainerHighest;
    final outline = cs.outlineVariant.withOpacity(isDark ? 0.55 : 0.75);
    final shadow = Colors.black.withOpacity(isDark ? 0.35 : 0.10);

    final headerTint = cs.error.withOpacity(isDark ? 0.12 : 0.08);

    final dangerBg = cs.errorContainer;
    final dangerFg = cs.onErrorContainer;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        foregroundColor: cs.onSurface,
        elevation: 0,
        titleSpacing: 12,
        title: const Text(
          'Emergency Request',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: outline),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ Main “modern” card wrapper (matches the second code)
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: outline),
                  boxShadow: [
                    BoxShadow(
                      color: shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ✅ subtle header strip (alive + consistent in dark mode)
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      decoration: BoxDecoration(
                        color: headerTint,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                        border: Border(bottom: BorderSide(color: outline)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: cs.error.withOpacity(isDark ? 0.18 : 0.12),
                              border: Border.all(
                                color: cs.error.withOpacity(
                                  isDark ? 0.35 : 0.25,
                                ),
                              ),
                            ),
                            child: Icon(
                              Icons.phone_in_talk_rounded,
                              color: cs.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Step 1 of 3',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          _casePill(context, outline),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepper(context),
                          const SizedBox(height: 16),

                          Text(
                            'What type of emergency are you reporting?',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ...List.generate(
                            types.length,
                            (i) => _buildTypeCard(context, i, types),
                          ),

                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.error,
                                foregroundColor: cs.onError,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed:
                                  _selectedType != -1 && profileName != null
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EmergencyAdditionalInfoScreen(
                                                onBack: () =>
                                                    Navigator.pop(context),
                                                onSubmit: () {},
                                                type:
                                                    types[_selectedType].title,
                                                location: 'Unknown', // TODO
                                                profileName: profileName!,
                                                profilePhone:
                                                    profilePhone ?? '',
                                              ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: const Text(
                                'Continue',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ✅ Danger banner (dark-mode safe + modern)
              Container(
                decoration: BoxDecoration(
                  color: dangerBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: cs.error.withOpacity(isDark ? 0.35 : 0.25),
                  ),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'In immediate danger?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: dangerFg,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.error,
                        foregroundColor: cs.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final Uri telUri = Uri(scheme: 'tel', path: '108');
                        if (await canLaunchUrl(telUri)) {
                          await launchUrl(telUri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text('Could not launch dialer'),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Call 108 Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For life-threatening emergencies, call directly',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: dangerFg.withOpacity(0.90),
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _casePill(BuildContext context, Color outline) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: outline),
      ),
      child: Text(
        'Select type',
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ===== Stepper (same as second code) =====
  Widget _buildStepper(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final active = cs.error;
    final inactive = cs.outlineVariant.withOpacity(isDark ? 0.55 : 0.45);
    final chipBg = cs.surfaceContainerHighest;

    return Row(
      children: [
        _stepCircle(context, 1, true, active, inactive, chipBg),
        _stepLine(inactive),
        _stepCircle(context, 2, false, active, inactive, chipBg),
        _stepLine(inactive),
        _stepCircle(context, 3, false, active, inactive, chipBg),
      ],
    );
  }

  Widget _stepCircle(
    BuildContext context,
    int step,
    bool active,
    Color activeColor,
    Color inactiveColor,
    Color chipBg,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: active ? activeColor : chipBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? activeColor : inactiveColor,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active ? cs.onError : cs.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _stepLine(Color color) {
    return Container(width: 34, height: 2, color: color);
  }

  // ===== Service cards (modern + dark-mode safe) =====
  Widget _buildTypeCard(
    BuildContext context,
    int index,
    List<_EmergencyType> types,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final type = types[index];
    final selected = _selectedType == index;

    final outline = cs.outlineVariant.withOpacity(isDark ? 0.55 : 0.40);

    return GestureDetector(
      onTap: () => setState(() => _selectedType = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: type.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? type.accent.withOpacity(0.9) : outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // subtle color wash overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: type.tint,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: type.accent.withOpacity(isDark ? 0.18 : 0.12),
                      border: Border.all(
                        color: type.accent.withOpacity(isDark ? 0.35 : 0.22),
                      ),
                    ),
                    child: Icon(type.icon, color: type.accent, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: selected ? type.accent : cs.onSurfaceVariant,
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

class _EmergencyType {
  final EmergencyType emergencyType;
  final EmergencyService emergencyService;

  final IconData icon;
  final String title;
  final String description;

  // “second code” style fields
  final Color accent;
  final Color bg;
  final Color tint;
  final Color border;

  _EmergencyType({
    required this.emergencyType,
    required this.emergencyService,
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.bg,
    required this.tint,
    required this.border,
  });
}
