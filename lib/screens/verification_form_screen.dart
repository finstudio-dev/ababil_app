import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../main.dart';
import '../models/profile.dart';

/// Collects the identity info an admin needs to approve a new member:
/// address, NID number, a passport-size photo, and a photo of the front of
/// their NID card. Used both for a brand-new member's first submission and
/// for a rejected member resubmitting after fixing whatever the admin
/// flagged (see `review_note` shown above the form in that case).
class VerificationFormScreen extends StatefulWidget {
  final Profile profile;
  final Future<void> Function() onSubmitted;

  const VerificationFormScreen({
    super.key,
    required this.profile,
    required this.onSubmitted,
  });

  @override
  State<VerificationFormScreen> createState() => _VerificationFormScreenState();
}

class _VerificationFormScreenState extends State<VerificationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _addressController =
      TextEditingController(text: widget.profile.address ?? '');
  late final _nidController =
      TextEditingController(text: widget.profile.nidNumber ?? '');

  XFile? _photoFile;
  Uint8List? _photoBytes;
  XFile? _nidPhotoFile;
  Uint8List? _nidPhotoBytes;

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _addressController.dispose();
    _nidController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto({required bool isNid, required ImageSource source}) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      if (isNid) {
        _nidPhotoFile = file;
        _nidPhotoBytes = bytes;
      } else {
        _photoFile = file;
        _photoBytes = bytes;
      }
    });
  }

  Future<String> _upload(String prefix, XFile file, Uint8List bytes) async {
    final userId = supabase.auth.currentUser!.id;
    final ext = file.name.split('.').last.toLowerCase();
    final path = '$userId/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await supabase.storage.from(AppConfig.verificationBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
          ),
        );
    return path;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photoFile == null && widget.profile.photoUrl == null) {
      setState(() => _error = 'Please add your passport-size photo.');
      return;
    }
    if (_nidPhotoFile == null && widget.profile.nidPhotoUrl == null) {
      setState(() => _error = 'Please add a photo of the front of your NID.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final userId = supabase.auth.currentUser!.id;

      String? photoPath = widget.profile.photoUrl;
      if (_photoFile != null && _photoBytes != null) {
        photoPath = await _upload('passport', _photoFile!, _photoBytes!);
      }

      String? nidPhotoPath = widget.profile.nidPhotoUrl;
      if (_nidPhotoFile != null && _nidPhotoBytes != null) {
        nidPhotoPath = await _upload('nid', _nidPhotoFile!, _nidPhotoBytes!);
      }

      await supabase.from('profiles').update({
        'address': _addressController.text.trim(),
        'nid_number': _nidController.text.trim(),
        'photo_url': photoPath,
        'nid_photo_url': nidPhotoPath,
        'verification_submitted_at': DateTime.now().toIso8601String(),
        // An already-active member updating their documents voluntarily (or
        // because an admin asked them to) stays active — there's no reason
        // to block them from using the app over an info refresh. Anyone
        // else reaching this form (brand-new, or resubmitting after a
        // rejection) goes to 'pending' for review, which the
        // enforce_profile_self_update_limits trigger allows a member to
        // set on themselves only when moving from 'rejected'.
        'status': widget.profile.isActive ? 'active' : 'pending',
        // Clears any admin "please update your documents" request, since
        // that's exactly what this submission satisfies. The trigger only
        // allows a member to move these back to null, never set them.
        'verification_requested_at': null,
        'verification_requested_note': null,
      }).eq('id', userId);

      if (mounted) await widget.onSubmitted();
    } catch (e) {
      setState(() => _error = 'Could not submit: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _photoPicker({
    required String label,
    required bool isNid,
    required Uint8List? bytes,
    required String? existingUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        if (bytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, height: 160, fit: BoxFit.cover),
          )
        else if (existingUrl != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Already uploaded — pick a new photo below to replace it.',
              style: TextStyle(color: Colors.green.shade800, fontSize: 12),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(isNid: isNid, source: ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(isNid: isNid, source: ImageSource.gallery),
                icon: const Icon(Icons.photo_outlined),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isResubmit = widget.profile.isRejected;
    final isVoluntaryUpdate = widget.profile.isActive;
    final requestNote = widget.profile.verificationRequestedNote;

    return Scaffold(
      appBar: AppBar(
        title: Text(isResubmit
            ? 'Resubmit verification'
            : isVoluntaryUpdate
                ? 'Update verification documents'
                : 'Verify your identity'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isResubmit && widget.profile.reviewNote != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('An admin rejected your last submission:',
                            style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('"${widget.profile.reviewNote}"',
                            style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (isVoluntaryUpdate && requestNote != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('An admin asked you to update your documents:',
                            style: TextStyle(color: Colors.amber.shade900, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('"$requestNote"',
                            style: TextStyle(
                                color: Colors.amber.shade900, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (isVoluntaryUpdate) ...[
                  const Text(
                    'Update your address, NID number, or photos below. Your '
                    'account stays active while you do this.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const Text(
                    'An admin needs to verify your identity before you can '
                    'submit deposits. This only takes a minute.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your address' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nidController,
                  decoration: const InputDecoration(labelText: 'NID number'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your NID number' : null,
                ),
                const SizedBox(height: 20),
                _photoPicker(
                  label: 'Passport-size photo',
                  isNid: false,
                  bytes: _photoBytes,
                  existingUrl: widget.profile.photoUrl,
                ),
                const SizedBox(height: 20),
                _photoPicker(
                  label: 'NID front side photo',
                  isNid: true,
                  bytes: _nidPhotoBytes,
                  existingUrl: widget.profile.nidPhotoUrl,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isResubmit
                          ? 'Resubmit for review'
                          : isVoluntaryUpdate
                              ? 'Save changes'
                              : 'Submit for review'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
