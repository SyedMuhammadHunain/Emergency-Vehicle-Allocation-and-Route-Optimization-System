import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/session_service.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = ThemeController();
  final sessionService = SessionService();

  await Future.wait([
    themeController.load(),
    sessionService.restore(),
  ]);

  runApp(ResQApp(
    themeController: themeController,
    sessionService: sessionService,
  ));
}
