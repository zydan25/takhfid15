import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../state/store_controller.dart';

class AuthScreen extends StatefulWidget {
  final StoreController controller;
  const AuthScreen({super.key, required this.controller});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int step = 0;
  final phone = TextEditingController();
  final otp = TextEditingController();
  final first = TextEditingController();
  final last = TextEditingController();
  String governorate = 'صنعاء';
  bool busy = false;
  String? error;

  @override
  void dispose() {
    phone.dispose();
    otp.dispose();
    first.dispose();
    last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = step == 0
        ? 'تسجيل الدخول برقم الهاتف'
        : step == 1
            ? 'تأكيد كود التحقق'
            : 'إكمال الملف الشخصي';

    return Scaffold(
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (step == 0) ...[
              const Text('رقم الهاتف',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '77XXXXXXX أو 96777XXXXXXX'),
              ),
            ] else if (step == 1) ...[
              const Text('أدخل الرمز المكون من 6 أرقام',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              TextField(
                controller: otp,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(),
              ),
            ] else ...[
              TextField(
                controller: first,
                decoration: const InputDecoration(labelText: 'الاسم الأول'),
              ),
              const SizedBox(height: 9),
              TextField(
                controller: last,
                decoration: const InputDecoration(labelText: 'اسم العائلة'),
              ),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(
                initialValue: governorate,
                items: const [
                  DropdownMenuItem(value: 'صنعاء', child: Text('صنعاء')),
                  DropdownMenuItem(value: 'عدن', child: Text('عدن')),
                  DropdownMenuItem(value: 'تعز', child: Text('تعز')),
                  DropdownMenuItem(value: 'حضرموت', child: Text('حضرموت')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => governorate = value);
                },
                decoration: const InputDecoration(labelText: 'المحافظة'),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!,
                  style: const TextStyle(color: AppColors.rose, fontSize: 10)),
            ],
            const Spacer(),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  busy
                      ? 'جارٍ التنفيذ...'
                      : step == 0
                          ? 'إرسال الرمز'
                          : step == 1
                              ? 'تحقق'
                              : 'حفظ وإكمال',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      busy = true;
      error = null;
    });

    try {
      if (step == 0) {
        await widget.controller.api.sendOtp(phone.text);
        setState(() => step = 1);
      } else if (step == 1) {
        final ok = await widget.controller.verifyOtp(phone.text, otp.text);
        if (!ok) throw Exception('رمز التحقق غير صحيح');
        setState(() => step = 2);
      } else {
        await widget.controller.completeProfile(
          firstName: first.text,
          lastName: last.text,
          governorate: governorate,
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
