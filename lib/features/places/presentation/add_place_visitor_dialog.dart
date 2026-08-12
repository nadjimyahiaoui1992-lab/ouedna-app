import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/repositories/place_repository.dart';

class AddPlaceVisitorDialog extends StatefulWidget {
  const AddPlaceVisitorDialog({super.key, required this.repository});

  final PlaceRepository? repository;

  @override
  State<AddPlaceVisitorDialog> createState() => _AddPlaceVisitorDialogState();
}

class _AddPlaceVisitorDialogState extends State<AddPlaceVisitorDialog> {
  static const Map<String, List<String>> _categories = {
    'معلم طبيعي': [],
    'معلم ديني': [],
    'معلم تراثي': [],
    'مرافق صحية': [
      'مستشفيات',
      'مصحات خاصة',
      'مركز التصوير الإشعاعي',
      'أطباء مختصون وعيادات خاصة',
      'مراكز التأهيل',
      'صيدليات',
      'شبه صيدلي',
    ],
    'مطاعم': [
      'تقليدي',
      'عصري',
      'مختلط',
      'أكل سريع',
      'أكلات شعبية',
      'مقاهي',
    ],
    'فنادق ومنتجعات': ['فنادق', 'منتجعات', 'مراقد'],
    'أسواق': [],
    'متاجر ومحلات': [],
  };

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  XFile? _selectedImage;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mapLinkController = TextEditingController();
  final _openingHoursController = TextEditingController();

  String _mainCategory = 'معلم تراثي';
  String? _subCategory;
  var _subcategories = <String>[];
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _subcategories = _categories[_mainCategory] ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _municipalityController.dispose();
    _phoneController.dispose();
    _mapLinkController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = widget.repository;
    if (repository == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عذراً، خدمة الإضافة غير متاحة حالياً بدون اتصال.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      Uint8List? imageBytes;
      String? imageFileName;
      if (_selectedImage != null) {
        imageBytes = await _selectedImage!.readAsBytes();
        imageFileName = _selectedImage!.name;
      }

      await repository.submitVisitorPlace(
        name: _nameController.text.trim(),
        mainCategory: _mainCategory,
        subCategory: _subCategory,
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        municipality: _municipalityController.text.trim(),
        phone: _phoneController.text.trim(),
        mapLink: _mapLinkController.text.trim(),
        openingHours: _openingHoursController.text.trim(),
        imageBytes: imageBytes,
        imageFileName: imageFileName,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال المعلم بنجاح! سيتم مراجعته ونشره قريباً من طرف الإدارة.'),
          backgroundColor: Color(0xFF193F38),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال المعلم: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اقتراح وإضافة معلم جديد'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ساهم معنا في إثراء دليل وادي سوف. املأ معلومات المعلم وسيقوم فريق الإدارة بمراجعتها ونشرها.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المعلم أو المكان *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم المعلم' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _mainCategory,
                  decoration: const InputDecoration(labelText: 'التصنيف الرئيسي *'),
                  items: _categories.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _mainCategory = val;
                        _subcategories = _categories[val] ?? [];
                        _subCategory = null;
                      });
                    }
                  },
                ),
                if (_subcategories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _subCategory,
                    decoration: const InputDecoration(labelText: 'التصنيف الفرعي'),
                    items: _subcategories.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _subCategory = val),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'وصف المعلم / نبذة تعريفيّة'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'العنوان أو الحي'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _municipalityController,
                        decoration: const InputDecoration(labelText: 'البلدية'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _openingHoursController,
                        decoration: const InputDecoration(labelText: 'ساعات العمل'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mapLinkController,
                  decoration: const InputDecoration(labelText: 'رابط الخريطة (Google Maps URL)'),
                ),
                const SizedBox(height: 16),
                const Text('صورة المعلم البارزة', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(_selectedImage == null ? 'اختر صورة' : 'تغيير الصورة'),
                    ),
                    const SizedBox(width: 12),
                    if (_selectedImage != null)
                      const Expanded(
                        child: Text('تم اختيار صورة بنجاح', style: TextStyle(color: Colors.green)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF193F38)),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('إرسال للمراجعة', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
