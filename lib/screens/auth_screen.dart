import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/store_controller.dart';

class AuthScreen extends StatefulWidget {
  final StoreController controller;

  const AuthScreen({
    super.key,
    required this.controller,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int step = 0;

  final phone = TextEditingController();
  final otp = TextEditingController();
  final firstName = TextEditingController();
  final secondName = TextEditingController();
  final thirdName = TextEditingController();
  final lastName = TextEditingController();

  String governorate = 'أمانة العاصمة';
  bool busy = false;
  String? error;

  @override
  void dispose() {
    phone.dispose();
    otp.dispose();
    firstName.dispose();
    secondName.dispose();
    thirdName.dispose();
    lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = step == 0
        ? 'تسجيل الدخول برقم الهاتف'
        : step == 1
            ? 'تأكيد كود التحقق'
            : 'إكمال بيانات الحساب';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    step == 0
                        ? 'سيتم إرسال رمز تحقق إلى رقمك عبر خادم التخفيض الصح.'
                        : step == 1
                            ? 'التحقق يتم على الخادم. عند نجاحه يُعرف تلقائيًا هل الحساب موجود أم جديد.'
                            : 'هذا الحساب جديد أو بياناته غير مكتملة؛ أكمل البيانات مرة واحدة.',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.slate500,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          if (step == 0)
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                hintText: '77XXXXXXX',
              ),
            ),
          if (step == 1)
            TextField(
              controller: otp,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'رمز التحقق',
                hintText: '••••••',
              ),
              style: const TextStyle(
                fontSize: 22,
                letterSpacing: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          if (step == 2) ...[
            TextField(
              controller: firstName,
              decoration: const InputDecoration(
                labelText: 'الاسم الأول *',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: secondName,
              decoration: const InputDecoration(
                labelText: 'الاسم الثاني',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: thirdName,
              decoration: const InputDecoration(
                labelText: 'الاسم الثالث',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lastName,
              decoration: const InputDecoration(
                labelText: 'اسم العائلة',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: governorate,
              items: const [
                DropdownMenuItem(
                  value: 'أمانة العاصمة',
                  child: Text('أمانة العاصمة'),
                ),
                DropdownMenuItem(
                  value: 'صنعاء',
                  child: Text('صنعاء'),
                ),
                DropdownMenuItem(
                  value: 'عدن',
                  child: Text('عدن'),
                ),
                DropdownMenuItem(
                  value: 'تعز',
                  child: Text('تعز'),
                ),
                DropdownMenuItem(
                  value: 'حضرموت',
                  child: Text('حضرموت'),
                ),
                DropdownMenuItem(
                  value: 'إب',
                  child: Text('إب'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => governorate = value);
                }
              },
              decoration: const InputDecoration(
                labelText: 'المحافظة *',
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.roseSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                error!,
                style: const TextStyle(
                  color: AppColors.rose,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
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
                        ? 'إرسال رمز التحقق'
                        : step == 1
                            ? 'تحقق من الرقم'
                            : 'حفظ البيانات والدخول',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (step == 1)
            TextButton(
              onPressed: busy ? null : () => setState(() => step = 0),
              child: const Text(
                'تغيير الرقم',
                style: TextStyle(fontSize: 10),
              ),
            ),
        ],
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
        final value = phone.text.trim();
        if (value.isEmpty) {
          throw Exception('أدخل رقم الهاتف');
        }
        await widget.controller.sendOtp(value);
        step = 1;
        otp.clear();
      } else if (step == 1) {
        if (otp.text.trim().length != 6) {
          throw Exception('أدخل رمز التحقق المكون من 6 أرقام');
        }

        final ok = await widget.controller.verifyOtp(
          phone.text,
          otp.text,
        );

        if (!ok) {
          throw Exception('تعذر التحقق من الرقم');
        }

        if (!widget.controller.lastOtpNeedsProfile &&
            widget.controller.profile != null) {
          if (mounted) Navigator.pop(context);
          return;
        }

        step = 2;
      } else {
        if (firstName.text.trim().isEmpty) {
          throw Exception('الاسم الأول مطلوب');
        }

        await widget.controller.completeProfile(
          firstName: firstName.text,
          secondName: secondName.text,
          thirdName: thirdName.text,
          lastName: lastName.text,
          governorate: governorate,
        );

        if (mounted) Navigator.pop(context);
        return;
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
