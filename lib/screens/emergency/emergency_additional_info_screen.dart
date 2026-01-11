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

Widget _buildStepper(bool isDark) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      _stepCircle(1, false, isDark),
      _stepLine(isDark),
      _stepCircle(2, true, isDark),
      _stepLine(isDark),
      _stepCircle(3, false, isDark),
    ],
  );
}

Widget _stepLine(bool isDark) {
  return Container(
    width: 24,
    height: 2,
    color: isDark ? Colors.grey[700] : Colors.grey[300],
  );
}

Widget _stepCircle(int step, bool active, bool isDark) {
  return Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: active
          ? (isDark ? Colors.red[300] : Colors.redAccent)
          : (isDark ? Colors.grey[700] : Colors.grey[200]),
      shape: BoxShape.circle,
      border: Border.all(
        color: active
            ? (isDark ? Colors.red[300]! : Colors.redAccent)
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
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: c.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Voice note error: $e")));
            }
          },
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.outlineVariant),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  _isRecording ? Icons.mic : Icons.mic_none_outlined,
                  color: _isRecording ? Colors.red : c.onSurfaceVariant,
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
                          fontWeight: FontWeight.w700,
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
                Icon(trailing, color: c.primary, size: 30),
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

  final ImagePicker _picker = ImagePicker();
  bool _sending = false;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick photo: $e')));
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
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showPhotoSourceSheet(context),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.outlineVariant),
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
                      ),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
                            fontWeight: FontWeight.w600,
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
      final emergencyId = await requestService.sendRequest(
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
        const SnackBar(content: Text('Emergency request sent successfully')),
      );
      // TODO: Navigate to follow-up screen if needed
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final shadowColor = isDark ? Colors.black54 : Colors.black12;
    final fieldFillColor = isDark ? Colors.grey[900] : Colors.grey.shade100;
    final blueBoxColor = isDark ? Colors.blueGrey[900] : Colors.blue.shade50;
    final summaryBoxColor = isDark ? Colors.grey[900] : Colors.grey.shade100;
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
                              color: isDark
                                  ? Colors.red[300]
                                  : Colors.redAccent,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Emergency Request',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Spacer(),
                            _buildStepper(isDark),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 20),
                        Text(
                          'Describe the Situation',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
                            fillColor: fieldFillColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Photo (optional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _photoPicker(context),
                        const SizedBox(height: 18),
                        // Voice note section
                        _voiceNoteSection(context),
                        const SizedBox(height: 18),
                        // Location toggle
                        _toggleCard(
                          context,
                          icon: Icons.location_on_outlined,
                          title: "Share Location",
                          subtitle: "Help responders find you faster",
                          value: _shareLocation,
                          onChanged: (v) => setState(() => _shareLocation = v),
                        ),
                        const SizedBox(height: 10),
                        // Notify Trusted Contacts toggle
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: blueBoxColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.contact_phone, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${widget.profileName} - ${widget.profilePhone}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Auto-filled from profile',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: summaryBoxColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Summary',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('Type: ${widget.type}'),
                              Text('Location: ${widget.location}'),
                              Text('Time: ${TimeOfDay.now().format(context)}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: widget.onBack,
                                child: const Text('Back'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  minimumSize: Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                onPressed: _sending ? null : _submit,
                                icon: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                ),
                                label: const Text('Submit '),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
