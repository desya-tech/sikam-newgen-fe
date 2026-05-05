import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/kambing_model.dart';
import '../../providers/kambing_provider.dart';
import '../../widgets/common/app_widgets.dart';

class KambingFormScreen extends StatefulWidget {
  final KambingModel? kambing;
  const KambingFormScreen({super.key, this.kambing});
  @override
  State<KambingFormScreen> createState() => _KambingFormScreenState();
}

class _KambingFormScreenState extends State<KambingFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  late final _namaCtrl  = TextEditingController(text: widget.kambing?.namaKambing);
  late final _beratCtrl = TextEditingController(text: widget.kambing?.beratLahir?.toString());
  final _tinggiCtrl = TextEditingController();
  final _umurCtrl   = TextEditingController();

  String _jenis   = '';
  String _kelamin = 'Jantan';
  String _kondisi = 'Sehat';
  String _status  = 'Hidup';
  DateTime? _tglLahir;

  final _jenisList   = ['Etawa','Kacang','Boer','Saanen','Nubian','Lainnya'];
  final _kelaminList = ['Jantan','Betina'];
  final _kondisiList = ['Sehat','Sakit','Dalam Perawatan'];
  final _statusList  = ['Hidup','Mati'];

  bool get _isEdit => widget.kambing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final k = widget.kambing!;
      _jenis   = k.jenisKambing;
      _kelamin = k.kelamin;
      _kondisi = k.kondisi;
      _status  = k.status;
      if (k.tanggalLahir != null) _tglLahir = DateTime.tryParse(k.tanggalLahir!);
    } else {
      _jenis = _jenisList.first;
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _beratCtrl.dispose();
    _tinggiCtrl.dispose();
    _umurCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tglLahir ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _tglLahir = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'nama'    : _namaCtrl.text.trim(),
      'jenis'   : _jenis,
      'kelamin' : _kelamin,
      'kondisi' : _kondisi,
      'status'  : _status,
      if (_tglLahir != null)
        'tanggal_lahir': _tglLahir!.toIso8601String().split('T').first,
      if (_beratCtrl.text.isNotEmpty)
        'berat' : double.tryParse(_beratCtrl.text) ?? 0,
      if (_tinggiCtrl.text.isNotEmpty)
        'tinggi': double.tryParse(_tinggiCtrl.text) ?? 0,
      if (_umurCtrl.text.isNotEmpty)
        'umur'  : int.tryParse(_umurCtrl.text) ?? 0,
    };

    final provider = context.read<KambingProvider>();
    final ok = _isEdit
        ? await provider.update(widget.kambing!.kambingId, payload)
        : await provider.create(payload);

    if (!mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(
          context, _isEdit ? 'Kambing berhasil diperbarui' : 'Kambing berhasil ditambahkan');
      context.pop();
    } else {
      SnackbarHelper.showError(context, provider.error ?? 'Gagal menyimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KambingProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Kambing' : 'Tambah Kambing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Nama Kambing *',
                hint: 'Contoh: Simba',
                controller: _namaCtrl,
                prefixIcon: Icons.pets,
                validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _jenis.isEmpty ? null : _jenis,
                decoration: const InputDecoration(labelText: 'Jenis Kambing *', prefixIcon: Icon(Icons.category_outlined)),
                items: _jenisList.map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
                onChanged: (v) => setState(() => _jenis = v!),
                validator: (v) => v == null ? 'Jenis wajib dipilih' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _kelamin,
                decoration: const InputDecoration(labelText: 'Kelamin *', prefixIcon: Icon(Icons.wc_outlined)),
                items: _kelaminList.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (v) => setState(() => _kelamin = v!),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _kondisi,
                decoration: const InputDecoration(labelText: 'Kondisi *', prefixIcon: Icon(Icons.health_and_safety_outlined)),
                items: _kondisiList.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (v) => setState(() => _kondisi = v!),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status *', prefixIcon: Icon(Icons.toggle_on_outlined)),
                items: _statusList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),

              // Tanggal Lahir
              AppTextField(
                label: 'Tanggal Lahir',
                hint: 'Pilih tanggal lahir',
                controller: TextEditingController(
                  text: _tglLahir != null
                      ? '${_tglLahir!.day.toString().padLeft(2,'0')}/${_tglLahir!.month.toString().padLeft(2,'0')}/${_tglLahir!.year}'
                      : '',
                ),
                prefixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _pickDate,
                suffix: _tglLahir != null
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _tglLahir = null))
                    : null,
              ),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(
                  child: AppTextField(
                    label: 'Berat (kg)',
                    hint: '3.5',
                    controller: _beratCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.scale_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Tinggi (cm)',
                    hint: '40',
                    controller: _tinggiCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.height_outlined,
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Umur (bulan)',
                hint: 'Contoh: 6',
                controller: _umurCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.cake_outlined,
              ),
              const SizedBox(height: 28),

              AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Tambah Kambing',
                isLoading: provider.isSubmitting,
                onPressed: _submit,
                icon: _isEdit ? Icons.save_outlined : Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}