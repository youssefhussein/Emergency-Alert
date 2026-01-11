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
      setState(() {
        _loadingProfile = false;
      });
      return;
    }
    final response = await supabase
        .from('profiles')
        .select('full_name, phone')
        .eq('id', user.id)
        .single();
    setState(() {
      profileName = response['full_name'] ?? '';
      profilePhone = response['phone'] ?? '';
      _loadingProfile = false;
    });
  }

  int _selectedType = -1;

  List<_EmergencyType> _typesForTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return emergencyServices.map((service) {
      // Map service colors to dark/light theme variants
      Color cardColor;
      Color borderColor;
      Color iconColor;
      Color textColor;
      
      switch (service.type) {
        case EmergencyType.ambulance:
          cardColor = isDark ? const Color(0xFF3B2323) : service.background;
          borderColor = isDark ? const Color(0xFFB71C1C) : const Color(0xFFFFB3B3);
          iconColor = isDark ? Colors.red[200]! : service.iconColor;
          textColor = isDark ? Colors.red[200]! : service.iconColor;
          break;
        case EmergencyType.police:
          cardColor = isDark ? const Color(0xFF232B3B) : service.background;
          borderColor = isDark ? const Color(0xFF1976D2) : const Color(0xFFB3D1FF);
          iconColor = isDark ? Colors.blue[200]! : service.iconColor;
          textColor = isDark ? Colors.blue[200]! : service.iconColor;
          break;
        case EmergencyType.fire:
          cardColor = isDark ? const Color(0xFF3B2F23) : service.background;
          borderColor = isDark ? const Color(0xFFFFA726) : const Color(0xFFFFD59E);
          iconColor = isDark ? Colors.orange[200]! : service.iconColor;
          textColor = isDark ? Colors.orange[200]! : service.iconColor;
          break;
        case EmergencyType.car:
          cardColor = isDark ? const Color(0xFF2B3B2B) : service.background;
          borderColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFFA5D6A7);
          iconColor = isDark ? Colors.green[200]! : service.iconColor;
          textColor = isDark ? Colors.green[200]! : service.iconColor;
          break;
      }
      
      return _EmergencyType(
        emergencyType: service.type,
        emergencyService: service,
        icon: service.icon,
        title: service.name,
        description: service.availableServices.join(', '),
        color: cardColor,
        borderColor: borderColor,
        iconColor: iconColor,
        textColor: textColor,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final shadowColor = isDark ? Colors.black54 : Colors.black12;
    final stepActiveColor = isDark ? Colors.red[300] : Colors.red[600];
    final stepInactiveColor = isDark ? Colors.grey[700] : Colors.grey[200];
    final stepBorderColor = isDark ? Colors.red[300]! : Colors.red[600]!;
    final stepTextColor = isDark ? Colors.white : Colors.black54;
    final types = _typesForTheme(context);
    final dangerBannerColor = isDark
        ? const Color(0xFF3B2323)
        : const Color(0xFFFFE5E5);
    final dangerTextColor = isDark ? Colors.red[200] : Colors.red[700];
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.phone_in_talk,
                              color: isDark ? Colors.red[200] : Colors.red[400],
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Emergency Request',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildStepper(),
                        SizedBox(height: 16),
                        Text(
                          'What type of emergency are you reporting?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        ...List.generate(
                          types.length,
                          (i) => _buildTypeCard(i, types),
                        ),
                        SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.red[400]
                                  : Colors.red[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
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
                                              type: types[_selectedType].title,
                                              location:
                                                  'Unknown', // TODO: Replace with real location
                                              profileName: profileName!,
                                              profilePhone: profilePhone ?? '',
                                            ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: dangerBannerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'In immediate danger?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.red[300]
                              : Colors.red[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          final Uri telUri = Uri(scheme: 'tel', path: '108');
                          if (await canLaunchUrl(telUri)) {
                            await launchUrl(telUri);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not launch dialer'),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Call 108 Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'For life-threatening emergencies, call directly',
                        style: TextStyle(color: dangerTextColor, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _stepCircle(1, true, isDark),
        _stepLine(isDark),
        _stepCircle(2, false, isDark),
        _stepLine(isDark),
        _stepCircle(3, false, isDark),
      ],
    );
  }

  Widget _stepCircle(int step, bool active, bool isDark) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active
            ? (isDark ? Colors.red[300] : Colors.red[600])
            : (isDark ? Colors.grey[700] : Colors.grey[200]),
        shape: BoxShape.circle,
        border: Border.all(
          color: active
              ? (isDark ? Colors.red[300]! : Colors.red[600]!)
              : (isDark ? Colors.grey[500]! : Colors.grey[400]!),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _stepLine(bool isDark) {
    return Container(
      width: 32,
      height: 2,
      color: isDark ? Colors.grey[700] : Colors.grey[300],
    );
  }

  Widget _buildTypeCard(int index, List<_EmergencyType> types) {
    final type = types[index];
    final selected = _selectedType == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = index;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: type.color,
          border: Border.all(
            color: selected ? type.borderColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Icon(type.icon, color: type.iconColor, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: type.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      type.description,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 13,
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

class _EmergencyType {
  final EmergencyType emergencyType;
  final EmergencyService emergencyService;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  _EmergencyType({
    required this.emergencyType,
    required this.emergencyService,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
}
