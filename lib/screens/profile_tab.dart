import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../main.dart';
import '../models/profile.dart';
import '../widgets/status_badge.dart';
import 'verification_form_screen.dart';

class ProfileTab extends StatefulWidget {
  final Profile profile;
  final Future<void> Function() onProfileChanged;

  const ProfileTab({super.key, required this.profile, required this.onProfileChanged});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _uploadingAvatar = false;
  String? _avatarError;

  Future<void> _changeAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file == null) return;

    setState(() {
      _uploadingAvatar = true;
      _avatarError = null;
    });

    try {
      final bytes = await file.readAsBytes();
      final userId = supabase.auth.currentUser!.id;
      final ext = file.name.split('.').last.toLowerCase();
      final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await supabase.storage.from(AppConfig.avatarsBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
              upsert: true,
            ),
          );

      final publicUrl = supabase.storage.from(AppConfig.avatarsBucket).getPublicUrl(path);

      await supabase.from('profiles').update({'avatar_url': publicUrl}).eq('id', userId);

      await widget.onProfileChanged();
    } catch (e) {
      setState(() => _avatarError = 'Could not update your photo. Try again.');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _openVerificationForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationFormScreen(
          profile: widget.profile,
          onSubmitted: widget.onProfileChanged,
        ),
      ),
    );
    await widget.onProfileChanged();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (profile.hasPendingReverificationRequest) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('An admin asked you to update your verification documents.',
                    style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w500)),
                if (profile.verificationRequestedNote != null) ...[
                  const SizedBox(height: 4),
                  Text('"${profile.verificationRequestedNote}"',
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 12)),
                ],
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _openVerificationForm,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: Colors.amber.shade800,
                  ),
                  child: const Text('Update now'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
              child: profile.avatarUrl == null
                  ? Text(
                      profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 28),
                    )
                  : null,
            ),
            if (_uploadingAvatar)
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.black45,
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            Positioned(
              bottom: -4,
              right: -4,
              child: Material(
                color: Theme.of(context).colorScheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _uploadingAvatar ? null : _changeAvatar,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_avatarError != null) ...[
          const SizedBox(height: 8),
          Text(_avatarError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        Text(profile.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(profile.email, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        if (profile.phone != null && profile.phone!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(profile.phone!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatusBadge(status: profile.status),
            const SizedBox(width: 8),
            StatusBadge(status: profile.role),
          ],
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: _openVerificationForm,
          icon: const Icon(Icons.badge_outlined),
          label: Text(profile.hasSubmittedVerification
              ? 'Update verification documents'
              : 'Submit verification documents'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => supabase.auth.signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
