import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../providers/kambing_provider.dart';
import '../../widgets/common/app_widgets.dart';

class PerkembanganFormScreen extends StatefulWidget {
  final int kambingId;
  const PerkembanganFormScreen({super.key, required this.kambingId});
  @override
  State<PerkembanganFormScreen> createState() => _PerkembanganFormScreenState();
}

class _PerkembanganFormScreenState extends State<PerkembanganFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _beratCtrl = TextEditingController();
  final _tinggiCtrl = TextEditingController();
  final _umurCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  String _kondisi = 'Sehat';
  DateTime _tglCatat = DateTime.now();

  @override
  void dispose() {
    _beratCtrl.dispose();
    _tinggiCtrl.dispose();
    _umurCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tglCatat,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _tglCatat = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      if (_beratCtrl.text.isNotEmpty) 'berat': double.tryParse(_beratCtrl.text),
      if (_tinggiCtrl.text.isNotEmpty) 'tinggi': double.tryParse(_tinggiCtrl.text),
      if (_umurCtrl.text.isNotEmpty) 'umur_bulan': int.tryParse(_umurCtrl.text),
      'kondisi': _kondisi,
      if (_catatanCtrl.text.isNotEmpty) 'catatan': _catatanCtrl.text.trim(),
      'tanggal_catat': _tglCatat.toIso8601String().split('T').first,
    };

    final provider = context.read<KambingProvider>();
    final ok = await provider.addPerkembangan(widget.kambingId, payload);

    if (!mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, 'Data perkembangan berhasil disimpan');
      context.pop();
    } else {
      SnackbarHelper.showError(context, provider.error ?? 'Gagal menyimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KambingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Catat Perkembangan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tanggal
              AppTextField(
                label: 'Tanggal Catat',
                controller: TextEditingController(
                  text: '${_tglCatat.day.toString().padLeft(2, '0')}/${_tglCatat.month.toString().padLeft(2, '0')}/${_tglCatat.year}',
                ),
                prefixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Berat (kg)',
                hint: 'Contoh: 25.5',
                controller: _beratCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.scale_outlined,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Tinggi (cm)',
                hint: 'Contoh: 65',
                controller: _tinggiCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.height_outlined,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Umur (bulan)',
                hint: 'Contoh: 12',
                controller: _umurCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.cake_outlined,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _kondisi,
                decoration: const InputDecoration(labelText: 'Kondisi Saat Ini', prefixIcon: Icon(Icons.health_and_safety_outlined)),
                items: ['Sehat', 'Sakit', 'Dalam Perawatan']
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (v) => setState(() => _kondisi = v!),
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Catatan',
                hint: 'Catatan tambahan (opsional)',
                controller: _catatanCtrl,
                maxLines: 3,
                prefixIcon: Icons.notes_outlined,
              ),
              const SizedBox(height: 28),

              AppButton(
                label: 'Simpan Perkembangan',
                isLoading: provider.isSubmitting,
                onPressed: _submit,
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
