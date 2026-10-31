import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/mock/mock_repository.dart';
import 'core/routes/app_router.dart';
import 'core/services/session_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class ResQApp extends StatefulWidget {
  final ThemeController themeController;
  final SessionService sessionService;
  final MockRepository? mockRepository;

  const ResQApp({
    super.key,
    required this.themeController,
    required this.sessionService,
    this.mockRepository,
  });

  @override
  State<ResQApp> createState() => _ResQAppState();
}

class _ResQAppState extends State<ResQApp> {
  late final _router = createRouter(widget.sessionService);
  late final MockRepository _mockRepository = widget.mockRepository ?? MockRepository();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.themeController),
        ChangeNotifierProvider.value(value: widget.sessionService),
        ChangeNotifierProvider.value(value: _mockRepository),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.mode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
