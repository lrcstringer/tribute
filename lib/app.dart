import 'package:flutter/material.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/views/root_view.dart';

class MyWalkApp extends StatelessWidget {
  const MyWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyWalk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RootView(),
    );
  }
}
