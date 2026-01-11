import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String? _selectedGender;

  final List<String> _statusOptions = [
    'safe',
    'need_help',
    'at_hospital',
    'in_danger',
    'unavailable',
  ];
  String _selectedStatus = 'safe';

  final _bloodTypeCtrl = TextEditingController();
  final _chronicCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _disabilitiesCtrl = TextEditingController();
  final _preferredHospitalCtrl = TextEditingController();
  final _otherNotesCtrl = TextEditingController();

  final TextEditingController _allergyInputCtrl = TextEditingController();
  List<String> _allergyList = [];

  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _uploadingImage = false;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  late final ProfileService _profileService;

  String? _validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 8) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validateOptionalInt(
    String? value, {
    String fieldName = 'Value',
    int? min,
    int? max,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName must be a whole number';
    }
    if (min != null && parsed < min) {
      return '$fieldName must be ≥ $min';
    }
    if (max != null && parsed > max) {
      return '$fieldName must be ≤ $max';
    }
    return null;
  }

  String? _validateOptionalDouble(
    String? value, {
    String fieldName = 'Value',
    double? min,
    double? max,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName must be a number';
    }
    if (min != null && parsed < min) {
      return '$fieldName must be ≥ $min';
    }
    if (max != null && parsed > max) {
      return '$fieldName must be ≤ $max';
    }
    return null;
  }

  String? _validateOptionalText(
    String? value, {
    String fieldName = 'Field',
    int? maxLength,
  }) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final text = value.trim();

    if (maxLength != null && text.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(Supabase.instance.client);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getCurrentUserProfile();
      if (profile != null) {
        _nameCtrl.text = profile.fullName ?? '';
        _phoneCtrl.text = profile.phone ?? '';

        _selectedStatus = profile.profileStatus ?? 'safe';

        _ageCtrl.text = profile.age?.toString() ?? '';
        // Normalize gender value to allowed set
        final gender = (profile.gender ?? '').toLowerCase();
        if (['male', 'female', 'other'].contains(gender)) {
          _selectedGender = gender;
        } else {
          _selectedGender = null;
        }
        _weightCtrl.text = profile.weightKg?.toString() ?? '';
        _heightCtrl.text = profile.heightCm?.toString() ?? '';

        _bloodTypeCtrl.text = profile.bloodType ?? '';
        _chronicCtrl.text = profile.chronicConditions ?? '';
        _medicationsCtrl.text = profile.medications ?? '';
        _disabilitiesCtrl.text = profile.disabilities ?? '';
        _preferredHospitalCtrl.text = profile.preferredHospital ?? '';
        _otherNotesCtrl.text = profile.otherNotes ?? '';

        _profileImageUrl = profile.profileImageUrl;

        final allergiesString = profile.allergies;
        if (allergiesString != null && allergiesString.trim().isNotEmpty) {
          _allergyList = allergiesString
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          _allergyList = [];
        }
      }
    } catch (e) {
      _error = 'Failed to load profile: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addAllergy() {
    final text = _allergyInputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _allergyList.add(text);
      _allergyInputCtrl.clear();
    });
  }

  Future<void> _pickAndUploadImage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _error = 'Not logged in');
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() {
        _uploadingImage = true;
        _error = null;
      });

      final Uint8List bytes = await picked.readAsBytes();
      final path = 'avatars/${user.id}.jpg';

      final client = Supabase.instance.client;

      await client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final publicUrl = client.storage.from('avatars').getPublicUrl(path);
      final cacheBustedUrl =
          '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _profileImageUrl = cacheBustedUrl;
      });
    } catch (e) {
      setState(() => _error = 'Failed to upload image: $e');
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    print('Save pressed');
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _error = 'Not logged in');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final allergiesString = _allergyList.isEmpty
          ? null
          : _allergyList.join(',');

      final profile = UserProfile(
        id: user.id,
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        profileImageUrl: _profileImageUrl,
        profileStatus: _selectedStatus,
        age: _ageCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_ageCtrl.text.trim()),
        gender: _selectedGender,
        weightKg: _weightCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_weightCtrl.text.trim()),
        heightCm: _heightCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_heightCtrl.text.trim()),
        bloodType: _bloodTypeCtrl.text.trim().isEmpty
            ? null
            : _bloodTypeCtrl.text.trim(),
        allergies: allergiesString,
        chronicConditions: _chronicCtrl.text.trim().isEmpty
            ? null
            : _chronicCtrl.text.trim(),
        medications: _medicationsCtrl.text.trim().isEmpty
            ? null
            : _medicationsCtrl.text.trim(),
        disabilities: _disabilitiesCtrl.text.trim().isEmpty
            ? null
            : _disabilitiesCtrl.text.trim(),
        preferredHospital: _preferredHospitalCtrl.text.trim().isEmpty
            ? null
            : _preferredHospitalCtrl.text.trim(),
        otherNotes: _otherNotesCtrl.text.trim().isEmpty
            ? null
            : _otherNotesCtrl.text.trim(),
      );

      await _profileService.upsertCurrentUserProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } catch (e) {
      print('Save error: $e');
      setState(() => _error = 'Failed to save profile: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _bloodTypeCtrl.dispose();
    _chronicCtrl.dispose();
    _medicationsCtrl.dispose();
    _disabilitiesCtrl.dispose();
    _preferredHospitalCtrl.dispose();
    _otherNotesCtrl.dispose();
    _allergyInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: _profileImageUrl != null
                              ? CachedNetworkImageProvider(_profileImageUrl!)
                              : null,
                          child: _profileImageUrl == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _uploadingImage ? null : _pickAndUploadImage,
                            child: CircleAvatar(
                              radius: 16,
                              child: _uploadingImage
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              const Text(
                'Basic Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _validateRequired(v, fieldName: 'Full name'),
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  border: OutlineInputBorder(),
                ),
                validator: _validatePhone,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    _validateOptionalInt(v, fieldName: 'Age', min: 0, max: 120),
              ),

              const SizedBox(height: 12),

              const Text(
                'Gender',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Select gender',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'Gender is required' : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Status
              const Text(
                'Current Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _statusOptions.map((status) {
                  final isSelected = _selectedStatus == status;
                  return ChoiceChip(
                    label: Text(status.replaceAll('_', ' ')),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedStatus = status);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: const [
                      Icon(Icons.medical_information_outlined),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Medical information is managed in a separate screen for clarity and safety.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _saveProfile,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
