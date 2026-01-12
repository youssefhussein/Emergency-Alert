import 'package:emergency_alert/services/emergency_service.dart';
import 'package:flutter/material.dart';

import '../../services/location_service.dart';
import '../../services/emergency_request_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:image_picker/image_picker.dart';

// ✅ IMPORTANT: use the SAME filename as your follow up screen file
// If your file is: emergency_follow_up_screen.dart
import 'emergency_followup_screen.dart';

class EmergencyAdditionalInfoScreen extends StatefulWidget {
  final void Function() onBack;
  final void Function() onSubmit;
  final String type;
  final String location;
  final String profileName;
  final String profilePhone;

  const EmergencyAdditionalInfoScreen({
    super.key,
    required this.onBack,
    required this.onSubmit,
    required this.type,
    required this.location,
    required this.profileName,
    required this.profilePhone,
  });

  @override
  State<EmergencyAdditionalInfoScreen> createState() =>
      _EmergencyAdditionalInfoScreenState();
}

Widget _buildStepper(BuildContext context, {required int activeStep}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  final active = cs.error;
  final inactiveBorder = cs.outlineVariant.withOpacity(isDark ? 0.55 : 0.45);
  final chipBg = cs.surfaceContainerHighest;
  final line = cs.outlineVariant.withOpacity(isDark ? 0.55 : 0.40);

  Widget circle(int step, bool isActive) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isActive ? active : chipBg,
        shape: BoxShape.circle,
        border: Border.all(color: isActive ? active : inactiveBorder, width: 2),
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? cs.onError : cs.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget stepLine() => Container(width: 34, height: 2, color: line);

  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      circle(1, activeStep == 1),
      stepLine(),
      circle(2, activeStep == 2),
      stepLine(),
      circle(3, activeStep == 3),
    ],
  );
}

class _EmergencyAdditionalInfoScreenState
    extends State<EmergencyAdditionalInfoScreen> {
  // Location state
  bool _shareLocation = true;
  bool _notifyTrustedContacts = false;
  double? _lat;
  double? _lng;
  bool _loadingLocation = true;
  String? _locationError;
  String? _detectedAddress;

  // Form controllers
  final TextEditingController _detailsCtrl = TextEditingController();
  final TextEditingController _locationDetailsCtrl = TextEditingController();

  // Photo selection state
  Uint8List? _photoBytes;
  String? _photoExt;
  String? _photoContentType;

  // Voice note state
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _voicePath;
  Duration _voiceDuration = Duration.zero;
  Timer? _recordTimer;
  DateTime? _recordStartAt;
  StreamSubscription<PlayerState>? _playerStateSub;

  // Picker + submit state
  final ImagePicker _picker = ImagePicker();
  bool _sending = false;

  Widget _toggleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.outlineVariant.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.onSurface.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: c.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: c.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    _locationDetailsCtrl.dispose();
    _recordTimer?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final pos = await LocationService().getCurrentPosition();
      _lat = pos.latitude;
      _lng = pos.longitude;
    } catch (e) {
      _lat = null;
      _lng = null;
      _locationError = "Couldn't detect location. You can still request help.";
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _startRecording() async {
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) throw Exception("Microphone permission denied");

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );

    _recordStartAt = DateTime.now();
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final start = _recordStartAt;
      if (start == null) return;
      setState(() => _voiceDuration = DateTime.now().difference(start));
    });

    setState(() {
      _isRecording = true;
      _voicePath = null;
      _voiceDuration = Duration.zero;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _recordTimer?.cancel();
    _recordStartAt = null;

    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _voicePath = path;
      if (_voiceDuration.inMilliseconds < 300) {
        _voicePath = null;
        _voiceDuration = Duration.zero;
      }
    });
  }

  Future<void> _togglePlayback() async {
    if (_voicePath == null) return;
    if (_isPlaying) {
      await _player.stop();
    } else {
      await _player.play(DeviceFileSource(_voicePath!));
    }
  }

  Future<void> _removeVoice() async {
    await _player.stop();
    final p = _voicePath;
    setState(() {
      _voicePath = null;
      _voiceDuration = Duration.zero;
      _isPlaying = false;
    });
    if (p != null) {
      final f = File(p);
      if (await f.exists()) await f.delete();
    }
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Widget _voiceNoteSection(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final hasVoice = _voicePath != null;

    String title;
    String subtitle;
    IconData trailing;

    if (_isRecording) {
      title = "Recording…";
      subtitle = _formatDuration(_voiceDuration);
      trailing = Icons.stop_circle_outlined;
    } else if (hasVoice) {
      title = "Voice note ready";
      subtitle = _formatDuration(_voiceDuration);
      trailing = _isPlaying
          ? Icons.pause_circle_outline
          : Icons.play_circle_outline;
    } else {
      title = "Tap to record voice note";
      subtitle = "Microphone will be used";
      trailing = Icons.mic_none_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Add Voice Note (Optional)",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: c.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            try {
              if (_isRecording) {
                await _stopRecording();
              } else if (hasVoice) {
                await _togglePlayback();
              } else {
                await _startRecording();
              }
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text("Voice note error: $e"),
                ),
              );
            }
          },
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: c.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.outlineVariant.withOpacity(0.6)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _isRecording
                        ? c.error.withOpacity(0.18)
                        : c.onSurface.withOpacity(0.06),
                    border: Border.all(
                      color: _isRecording
                          ? c.error.withOpacity(0.35)
                          : c.outlineVariant.withOpacity(0.35),
                    ),
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic_rounded : Icons.mic_none_outlined,
                    color: _isRecording ? c.error : c.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: c.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(trailing, color: c.primary, size: 32),
                const SizedBox(width: 6),
                if (!_isRecording && hasVoice)
                  IconButton(
                    tooltip: "Remove",
                    onPressed: _removeVoice,
                    icon: Icon(Icons.delete_outline, color: c.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickPhoto({required ImageSource source}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final ext = _extFromPath(file.name.isNotEmpty ? file.name : file.path);
      final contentType = _guessImageContentType(ext);

      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _photoExt = ext;
        _photoContentType = contentType;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Failed to pick photo: $e'),
        ),
      );
    }
  }

  void _clearPhoto() {
    setState(() {
      _photoBytes = null;
      _photoExt = null;
      _photoContentType = null;
    });
  }

  String _extFromPath(String path) {
    final p = path.trim();
    final dot = p.lastIndexOf('.');
    if (dot == -1 || dot == p.length - 1) return 'jpg';
    return p.substring(dot + 1).toLowerCase();
  }

  String _guessImageContentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _showPhotoSourceSheet(BuildContext context) async {
    final c = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text("Camera"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickPhoto(source: ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text("Gallery"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickPhoto(source: ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _photoPicker(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showPhotoSourceSheet(context),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: c.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.outlineVariant.withOpacity(0.6)),
        ),
        child: _photoBytes == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      color: c.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap to add photo",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_photoBytes!, fit: BoxFit.cover),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: InkWell(
                        onTap: _clearPhoto,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          "Tap to change",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ✅ FIXED: EmergencyFollowUpScreen needs BOTH emergencyId + service
  Future<void> _submit() async {
    setState(() => _sending = true);

    final requestService = EmergencyRequestService(Supabase.instance.client);

    Uint8List? voiceBytes;
    String? voiceExt;
    String? voiceContentType;
    int? voiceDurationSec;

    if (_voicePath != null) {
      final f = File(_voicePath!);
      if (await f.exists()) {
        voiceBytes = await f.readAsBytes();
        voiceExt = 'wav';
        voiceContentType = 'audio/wav';
        voiceDurationSec = _voiceDuration.inSeconds;
      }
    }

    try {
      final details = _detailsCtrl.text.trim();
      final locationDetails = _locationDetailsCtrl.text.trim();

      final lat = _shareLocation ? _lat : null;
      final lng = _shareLocation ? _lng : null;

      // Find the matching EmergencyService by name (case-insensitive)
      final selectedService = emergencyServices.firstWhere(
        (s) => s.name.toLowerCase() == widget.type.toLowerCase(),
        orElse: () => emergencyServices.first,
      );

      final int emergencyId = await requestService.sendRequest(
        service: selectedService,
        description: details,
        latitude: lat,
        longitude: lng,
        shareLocation: _shareLocation,
        notifyContacts: _notifyTrustedContacts,
        locationDetails: locationDetails.isEmpty ? null : locationDetails,
        photoBytes: _photoBytes,
        photoExt: _photoExt,
        photoContentType: _photoContentType,
        voiceBytes: voiceBytes,
        voiceExt: voiceExt,
        voiceContentType: voiceContentType,
        voiceDurationSec: voiceDurationSec,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Emergency request sent successfully'),
        ),
      );

      widget.onSubmit();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmergencyFollowUpScreen(
            emergencyId: emergencyId,
            service: selectedService, // ✅ required by your FollowUp screen
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Failed to send: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final pageBg = cs.surface;
    final cardBg = cs.surfaceContainerHighest;
    final border = cs.outlineVariant.withOpacity(isDark ? 0.55 : 0.70);
    final shadow = Colors.black.withOpacity(isDark ? 0.32 : 0.10);

    // Form field fill that works in both modes
    final fieldFill = isDark
        ? cs.surfaceContainerHighest.withOpacity(0.55)
        : cs.surfaceContainerHighest.withOpacity(0.75);

    // Profile box (theme based instead of hardcoded blue)
    final profileBoxBg = cs.primary.withOpacity(isDark ? 0.14 : 0.10);
    final profileBoxBorder = cs.primary.withOpacity(isDark ? 0.30 : 0.22);

    // Summary box
    final summaryBg = cs.surfaceContainerHighest;
    final summaryBorder = border;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        foregroundColor: cs.onSurface,
        elevation: 0,
        titleSpacing: 12,
        title: const Text(
          'Additional Info',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_locationError != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cs.error.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: cs.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _locationError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onErrorContainer,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row + stepper
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: cs.error.withOpacity(isDark ? 0.18 : 0.12),
                              border: Border.all(
                                color: cs.error.withOpacity(
                                  isDark ? 0.35 : 0.22,
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
                              'Emergency Request',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          _buildStepper(context, activeStep: 2),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Describe the Situation',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _detailsCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'What happened and the current condition...',
                          filled: true,
                          fillColor: fieldFill,
                          hintStyle: TextStyle(color: cs.onSurfaceVariant),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: cs.primary,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),
                      Text(
                        'Extra Location Details (optional)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _locationDetailsCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Apartment, floor, landmark, gate number…',
                          filled: true,
                          fillColor: fieldFill,
                          hintStyle: TextStyle(color: cs.onSurfaceVariant),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: cs.primary,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                      Text(
                        'Photo (optional)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _photoPicker(context),

                      const SizedBox(height: 18),
                      _voiceNoteSection(context),

                      const SizedBox(height: 18),
                      _toggleCard(
                        context,
                        icon: Icons.location_on_outlined,
                        title: "Share Location",
                        subtitle: "Help responders find you faster",
                        value: _shareLocation,
                        onChanged: (v) => setState(() => _shareLocation = v),
                      ),

                      const SizedBox(height: 10),
                      _toggleCard(
                        context,
                        icon: Icons.group_outlined,
                        title: "Notify Trusted Contacts",
                        subtitle: "Alert your emergency contacts",
                        value: _notifyTrustedContacts,
                        onChanged: (v) =>
                            setState(() => _notifyTrustedContacts = v),
                      ),

                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: profileBoxBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: profileBoxBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.contact_phone, color: cs.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.profileName} - ${widget.profilePhone}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Auto-filled from profile',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: summaryBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: summaryBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Summary',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type: ${widget.type}',
                              style: TextStyle(color: cs.onSurface),
                            ),
                            Text(
                              'Location: ${widget.location}',
                              style: TextStyle(color: cs.onSurface),
                            ),
                            Text(
                              'Time: ${TimeOfDay.now().format(context)}',
                              style: TextStyle(color: cs.onSurface),
                            ),
                            if (_loadingLocation)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Detecting GPS…',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              )
                            else if (_shareLocation &&
                                _lat != null &&
                                _lng != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'GPS: $_lat, $_lng',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.onSurface,
                                side: BorderSide(color: border),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: widget.onBack,
                              child: const Text(
                                'Back',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.error,
                                foregroundColor: cs.onError,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: _sending ? null : _submit,
                              icon: const Icon(Icons.warning_amber_rounded),
                              label: Text(
                                _sending ? 'Submitting...' : 'Submit',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
