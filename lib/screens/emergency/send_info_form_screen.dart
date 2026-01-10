import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/emergency_service.dart';
import '../../services/emergency_request_service.dart';
import '../../services/location_service.dart';

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'emergency_followup_screen.dart';

class SendInfoFormScreen extends StatefulWidget {
  final EmergencyService service;

  const SendInfoFormScreen({super.key, required this.service});

  @override
  State<SendInfoFormScreen> createState() => _SendInfoFormScreenState();
}

class _SendInfoFormScreenState extends State<SendInfoFormScreen> {
  final _detailsCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationDetailsCtrl = TextEditingController();

  bool _shareLocation = true;
  bool _notifyTrustedContacts = false;

  final bool _hasVoiceNote = false;

  bool _sending = false;

  double? _lat;
  double? _lng;

  bool _loadingLocation = true;
  String? _locationError;
  String? _detectedAddress;

  // Photo selection state
  final ImagePicker _picker = ImagePicker();
  Uint8List? _photoBytes;
  String? _photoExt; // e.g. jpg/png
  String? _photoContentType;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;

  String? _voicePath; // local saved voice file path
  Duration _voiceDuration = Duration.zero;

  Timer? _recordTimer;
  DateTime? _recordStartAt;
  StreamSubscription<PlayerState>? _playerStateSub;

  int _currentStep = 0;

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

      // try {
      //   final address = await GeocodingService().reverseGeocode(_lat!, _lng!);
      //   _detectedAddress = (address.trim().isNotEmpty) ? address.trim() : null;
      // } catch (_) {
      //   _detectedAddress = null; // don't block
      // }
    } catch (e) {
      _lat = null;
      _lng = null;
      _detectedAddress = null;
      _locationError = "Couldn't detect location. You can still request help.";
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
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
      final phone = _phoneCtrl.text.trim();
      final details = _detailsCtrl.text.trim();
      final locationDetails = _locationDetailsCtrl.text.trim();

      final lat = _shareLocation ? _lat : null;
      final lng = _shareLocation ? _lng : null;
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

      final emergencyId = await requestService.sendRequest(
        service: widget.service,
        phone: phone,
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
      // Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmergencyFollowUpScreen(
            emergencyId: emergencyId,
            service: widget.service,
          ),
        ),
      );
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
  void dispose() {
    _detailsCtrl.dispose();
    _phoneCtrl.dispose();
    _locationDetailsCtrl.dispose();
    _recordTimer?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    _recorder.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    final title = "${widget.service.name} Emergency";

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: Text(title),
        centerTitle: true,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        onStepTapped: (step) => setState(() => _currentStep = step),
        steps: [
          Step(
            title: Text("Emergency Details"),
            subtitle: Text("Describe what's happening"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Provide emergency details",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "What's happening? (Optional)",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _detailsCtrl,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: "Brief description to help responders prepare...",
                    filled: true,
                    fillColor: c.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.primary, width: 1.2),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Keep it brief. AI will analyze and categorize automatically.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "Contact phone (Optional)",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: "Your phone number",
                    filled: true,
                    fillColor: c.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.primary, width: 1.2),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: Text("Supporting Media"),
            subtitle: Text("Add photo or voice note"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add Photo (Optional)",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _photoPicker(context),
                const SizedBox(height: 14),
                _voiceNoteSection(context),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: Text("Review & Send"),
            subtitle: Text("Confirm options and submit"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  onChanged: (v) => setState(() => _notifyTrustedContacts = v),
                ),
                const SizedBox(height: 16),
                _aiDispatchInfo(context),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B30),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            "Request Emergency Help",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  // Widget _locationCard(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final c = theme.colorScheme;

  //   final title = _locationError != null
  //       ? "Location Unavailable"
  //       : (_loadingLocation ? "Detecting location..." : "Location Detected");

  //   final subtitle =
  //       _locationError ??
  //       (_detectedAddress ??
  //           ((_lat != null && _lng != null)
  //               ? "Lat: ${_lat!.toStringAsFixed(6)}, Lng: ${_lng!.toStringAsFixed(6)}"
  //               : "Not available"));

  //   final shareHint = _shareLocation
  //       ? "Automatically shared with responders"
  //       : "Location not shared with responders";

  //   return Container(
  //     padding: const EdgeInsets.all(14),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFFE8F5E9),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: c.outlineVariant),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             const Icon(Icons.location_on, color: Colors.green),
  //             const SizedBox(width: 10),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     title,
  //                     style: theme.textTheme.bodyMedium?.copyWith(
  //                       fontWeight: FontWeight.w700,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 2),
  //                   Text(
  //                     subtitle,
  //                     style: theme.textTheme.bodySmall?.copyWith(
  //                       color: c.onSurfaceVariant,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             IconButton(
  //               tooltip: "Refresh",
  //               onPressed: _loadingLocation ? null : _loadLocation,
  //               icon: const Icon(Icons.refresh),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 10),

  //         // "Edit location details" button (opens a small editor)
  //         SizedBox(
  //           width: double.infinity,
  //           child: OutlinedButton(
  //             style: OutlinedButton.styleFrom(
  //               foregroundColor: c.onSurface,
  //               side: BorderSide(color: c.outlineVariant),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(14),
  //               ),
  //             ),
  //             onPressed: () => _editLocationDetails(context),
  //             child: const Text(
  //               "Edit location details (building, floor, etc.)",
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 8),

  //         Row(
  //           children: [
  //             Icon(Icons.check, size: 16, color: c.onSurfaceVariant),
  //             const SizedBox(width: 6),
  //             Text(
  //               shareHint,
  //               style: theme.textTheme.bodySmall?.copyWith(
  //                 color: c.onSurfaceVariant,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<void> _editLocationDetails(BuildContext context) async {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Location details",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _locationDetailsCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Building / floor / apartment / landmark...",
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.primary, width: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: c.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  String _guessAudioContentType(String ext) {
    if (ext == 'wav') return 'audio/wav';
    return 'audio/wav';
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

  Widget _aiDispatchInfo(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    final bg = c.primaryContainer.withOpacity(0.25);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: c.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI-Powered Dispatch",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Our AI will instantly analyze your emergency, determine severity, and automatically dispatch the nearest available responder. No approval needed.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
