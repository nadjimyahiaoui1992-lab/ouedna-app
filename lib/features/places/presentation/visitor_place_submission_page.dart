import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../domain/repositories/place_repository.dart';

class VisitorPlaceSubmissionPage extends StatefulWidget {
  const VisitorPlaceSubmissionPage({super.key, required this.repository});

  final PlaceRepository repository;

  @override
  State<VisitorPlaceSubmissionPage> createState() =>
      _VisitorPlaceSubmissionPageState();
}

class _VisitorPlaceSubmissionPageState
    extends State<VisitorPlaceSubmissionPage> {
  static const _elOued = LatLng(33.3683, 6.8674);
  static const _categories = <String>[
    'معلم طبيعي',
    'معلم ديني',
    'معلم تراثي',
    'مطاعم',
    'فنادق ومنتجعات',
    'أسواق',
    'متاجر ومحلات',
    'مرافق صحية',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _municipalityController = TextEditingController(text: 'الوادي');
  final _phoneController = TextEditingController();
  final _hoursController = TextEditingController();
  final _picker = ImagePicker();

  String _category = _categories.first;
  LatLng? _point;
  XFile? _image;
  bool _sending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _municipalityController.dispose();
    _phoneController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (selected != null && mounted) setState(() => _image = selected);
  }

  Future<void> _pickPoint() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => _VisitorMapPicker(initialPoint: _point ?? _elOued),
      ),
    );
    if (result != null && mounted) setState(() => _point = result);
  }

  Future<void> _submit() async {
    if (_sending) return;
    if (!_formKey.currentState!.validate()) return;
    if (_point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى تحديد موقع المعلم بالدبوس على الخريطة.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      Uint8List? bytes;
      if (_image != null) bytes = await _image!.readAsBytes();
      await widget.repository.submitVisitorPlace(
        name: _nameController.text,
        mainCategory: _category,
        description: _descriptionController.text,
        address: _addressController.text,
        municipality: _municipalityController.text,
        phone: _phoneController.text,
        latitude: _point!.latitude,
        longitude: _point!.longitude,
        openingHours: _hoursController.text,
        imageBytes: bytes,
        imageFileName: _image?.name,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_outlined, size: 40),
          title: const Text('تم استلام اقتراحك'),
          content: const Text(
            'سيقوم فريق وادنا بمراجعة المعلومات والصورة والموقع قبل النشر. شكراً لمساهمتك في إثراء دليل وادي سوف.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'تعذر إرسال الاقتراح حالياً. تحقق من اتصال الإنترنت وحاول مجدداً.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('اقترح معلماً')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(Icons.volunteer_activism_outlined, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'شاركنا مكاناً موثوقاً في وادي سوف. لا يُنشر أي اقتراح قبل المراجعة من فريق الإدارة.',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle('المعلومات الأساسية'),
              _InputField(
                controller: _nameController,
                label: 'اسم المعلم أو المكان',
                icon: Icons.place_outlined,
                required: true,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                decoration:
                    _decoration('التصنيف الرئيسي', Icons.category_outlined),
                items: _categories
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(growable: false),
                onChanged: (value) =>
                    setState(() => _category = value ?? _category),
              ),
              const SizedBox(height: 14),
              _InputField(
                controller: _descriptionController,
                label: 'وصف مختصر ومعلومات مفيدة',
                icon: Icons.description_outlined,
                minLines: 3,
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              _SectionTitle('الموقع والتواصل'),
              _InputField(
                controller: _addressController,
                label: 'العنوان أو الحي',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 14),
              _InputField(
                controller: _municipalityController,
                label: 'البلدية',
                icon: Icons.location_city_outlined,
              ),
              const SizedBox(height: 14),
              _LocationCard(point: _point, onTap: _pickPoint),
              const SizedBox(height: 14),
              _InputField(
                controller: _phoneController,
                label: 'رقم الهاتف (اختياري)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _InputField(
                controller: _hoursController,
                label: 'أوقات العمل (اختياري)',
                icon: Icons.schedule_outlined,
              ),
              const SizedBox(height: 24),
              _SectionTitle('صورة المكان'),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: Icon(_image == null
                    ? Icons.add_photo_alternate_outlined
                    : Icons.photo_outlined),
                label: Text(_image == null
                    ? 'إضافة صورة من المعرض'
                    : 'تم اختيار: ${_image!.name}'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerRight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'بإرسال الاقتراح، تؤكد أن المعلومات والصورة صحيحة وأنك تملك حق مشاركتها.',
                style:
                    TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: FilledButton.icon(
            onPressed: _sending ? null : _submit,
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(_sending ? 'جاري الإرسال...' : 'إرسال للمراجعة'),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(.45),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
      );
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.required = false,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final int? minLines;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? 'هذا الحقل مطلوب.'
                : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(.45),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.point, required this.onTap});
  final LatLng? point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.pin_drop_outlined)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('دبوس الموقع',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      point == null
                          ? 'حدّد موقع المكان من خريطة وادنا.'
                          : '${point!.latitude.toStringAsFixed(5)}، ${point!.longitude.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              FilledButton(
                  onPressed: onTap,
                  child: Text(point == null ? 'تحديد' : 'تعديل')),
            ],
          ),
        ),
      );
}

class _VisitorMapPicker extends StatefulWidget {
  const _VisitorMapPicker({required this.initialPoint});
  final LatLng initialPoint;

  @override
  State<_VisitorMapPicker> createState() => _VisitorMapPickerState();
}

class _VisitorMapPickerState extends State<_VisitorMapPicker> {
  late LatLng _point = widget.initialPoint;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('حدد موقع المعلم'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _point),
              child: const Text('تأكيد',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        body: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _point,
                initialZoom: 14,
                onTap: (_, point) => setState(() => _point = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ouedna.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _point,
                      width: 56,
                      height: 56,
                      child: const Icon(Icons.location_on_rounded,
                          color: Color(0xFFB63D32), size: 50),
                    ),
                  ],
                ),
              ],
            ),
            PositionedDirectional(
              start: 16,
              end: 16,
              top: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'اضغط على الخريطة لوضع الدبوس بدقة، ثم اضغط «تأكيد».',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
