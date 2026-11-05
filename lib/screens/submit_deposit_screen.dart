import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../main.dart';

const List<Map<String, String>> _methods = [
  {'value': 'bkash', 'label': 'bKash'},
  {'value': 'nagad', 'label': 'Nagad'},
  {'value': 'rocket', 'label': 'Rocket'},
  {'value': 'bank', 'label': 'Bank Transfer'},
  {'value': 'cash', 'label': 'Cash (handed to admin)'},
  {'value': 'other', 'label': 'Other'},
];

class SubmitDepositScreen extends StatefulWidget {
  const SubmitDepositScreen({super.key});

  @override
  State<SubmitDepositScreen> createState() => _SubmitDepositScreenState();
}

class _SubmitDepositScreenState extends State<SubmitDepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  final _noteController = TextEditingController();

  String _method = 'bkash';
  XFile? _receiptFile;
  Uint8List? _receiptBytes;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _receiptFile = file;
      _receiptBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      String? receiptPath;

      if (_receiptFile != null && _receiptBytes != null) {
        final ext = _receiptFile!.name.split('.').last.toLowerCase();
        final path =
            '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage.from(AppConfig.receiptsBucket).uploadBinary(
              path,
              _receiptBytes!,
              fileOptions: FileOptions(
                contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
              ),
            );
        receiptPath = path;
      }

      final now = DateTime.now();
      final periodMonth = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);

      await supabase.from('deposits').insert({
        'member_id': userId,
        'amount': double.parse(_amountController.text.trim()),
        'method': _method,
        'transaction_ref': _refController.text.trim().isEmpty ? null : _refController.text.trim(),
        'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        'receipt_url': receiptPath,
        'period_month': periodMonth,
        'status': 'pending',
        'source': 'member',
      });

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Could not submit: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit a deposit')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (BDT)'),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: const InputDecoration(labelText: 'Payment method'),
                  items: _methods
                      .map((m) => DropdownMenuItem(value: m['value'], child: Text(m['label']!)))
                      .toList(),
                  onChanged: (v) => setState(() => _method = v ?? 'bkash'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _refController,
                  decoration: const InputDecoration(
                    labelText: 'Transaction ID / reference (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                ),
                const SizedBox(height: 16),
                Text('Receipt photo (optional but recommended)',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                if (_receiptBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_receiptBytes!, height: 180, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_outlined),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
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
                      : const Text('Submit for review'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
