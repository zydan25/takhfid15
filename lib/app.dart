import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'services/store_api.dart';
import 'state/store_controller.dart';
import 'screens/shell_screen.dart';

class TakhfidApp extends StatefulWidget {
  const TakhfidApp({super.key});

  @override
  State<TakhfidApp> createState() => _TakhfidAppState();
}

class _TakhfidAppState extends State<TakhfidApp> {
  late final StoreController controller;

  @override
  void initState() {
    super.initState();
    controller = StoreController(StoreApi());
    controller.bootstrap();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'التخفيض الصح',
      theme: buildTakhfidTheme(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: ShellScreen(controller: controller),
    );
  }
}
