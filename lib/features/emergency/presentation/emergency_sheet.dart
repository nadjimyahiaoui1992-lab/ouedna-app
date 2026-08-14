import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencySheet extends StatefulWidget {
  const EmergencySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const EmergencySheet(),
    );
  }

  @override
  State<EmergencySheet> createState() => _EmergencySheetState();
}

class _EmergencySheetState extends State<EmergencySheet> {
  Position? _position;
  bool _locating = false;
  String? _locationError;

  Future<void> _getLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _EmergencyLocationError(
            'خدمة الموقع متوقفة. فعّلها من إعدادات الهاتف ثم أعد المحاولة.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const _EmergencyLocationError(
            'لم توافق على مشاركة موقع الضحية. يمكنك الاتصال بالطوارئ مباشرة.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw const _EmergencyLocationError(
            'صلاحية الموقع مرفوضة نهائياً. فعّلها من إعدادات التطبيق إن أردت مشاركة الموقع.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) setState(() => _position = position);
    } on _EmergencyLocationError catch (error) {
      if (mounted) setState(() => _locationError = error.message);
    } catch (_) {
      if (mounted)
        setState(() => _locationError =
            'تعذر تحديد الموقع حالياً. يمكنك الاتصال بالطوارئ مباشرة.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String get _locationMessage {
    final current = _position;
    if (current == null) return '';
    final latitude = current.latitude.toStringAsFixed(6);
    final longitude = current.longitude.toStringAsFixed(6);
    return 'موقع الضحية عبر تطبيق وادنا:\nالإحداثيات: $latitude، $longitude\nرابط الموقع: https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=18/$latitude/$longitude';
  }

  Future<void> _call(String number) async {
    final launched = await launchUrl(Uri(scheme: 'tel', path: number));
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تعذر فتح شاشة الاتصال. اطلب الرقم يدوياً.')),
      );
    }
  }

  Future<void> _shareLocation() async {
    if (_position == null) await _getLocation();
    if (_position == null || !mounted) return;
    await Share.share(_locationMessage, subject: 'موقع طارئ — وادنا');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.errorContainer,
                  foregroundColor: scheme.onErrorContainer,
                  child: const Icon(Icons.emergency_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('مساعدة عاجلة',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
                'اتصل فوراً بخدمات الطوارئ. مشاركة الموقع اختيارية ولا تتم إلا بعد موافقتك الصريحة.'),
            const SizedBox(height: 18),
            _EmergencyNumberCard(
              icon: Icons.local_police_outlined,
              title: 'الشرطة',
              number: '1055',
              onCall: () => _call('1055'),
            ),
            const SizedBox(height: 10),
            _EmergencyNumberCard(
              icon: Icons.security_outlined,
              title: 'الدرك الوطني',
              number: '1548',
              onCall: () => _call('1548'),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _locating ? null : _shareLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_position == null
                      ? Icons.my_location_outlined
                      : Icons.share_location_outlined),
              label: Text(_position == null
                  ? 'تحديد الموقع ثم مشاركته'
                  : 'مشاركة موقع الضحية'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
            if (_position != null) ...[
              const SizedBox(height: 8),
              Text(
                  'تم تحديد الموقع بدقة تقريبية ${_position!.accuracy.round()} م. يمكنك الآن مشاركته مع الجهة التي تتواصل معها.',
                  style: TextStyle(
                      color: scheme.primary, fontSize: 12, height: 1.4)),
            ],
            if (_locationError != null) ...[
              const SizedBox(height: 8),
              Text(_locationError!,
                  style: TextStyle(
                      color: scheme.error, fontSize: 12, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmergencyNumberCard extends StatelessWidget {
  const _EmergencyNumberCard(
      {required this.icon,
      required this.title,
      required this.number,
      required this.onCall});
  final IconData icon;
  final String title;
  final String number;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(icon)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(number,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          trailing: FilledButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.call_outlined),
            label: const Text('اتصال'),
          ),
        ),
      );
}

class _EmergencyLocationError implements Exception {
  const _EmergencyLocationError(this.message);
  final String message;
}
