import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'views/root_view.dart';

class TributeApp extends StatelessWidget {
  const TributeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tribute',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RootView(),
    );
  }
}
