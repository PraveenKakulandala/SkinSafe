import 'package:flutter/material.dart';

import '../../../../app/skinsafe_frontend.dart'
    show AppPalette, AppPremiumBackground, MelanomaStagesEducationContent;

class MelanomaStagesPage extends StatelessWidget {
  const MelanomaStagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final pageBackground = isDark ? AppPalette.darkCanvas : AppPalette.canvas;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        surfaceTintColor: pageBackground,
        title: const Text('Melanoma Stages'),
      ),
      body: const AppPremiumBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: MelanomaStagesEducationContent(),
          ),
        ),
      ),
    );
  }
}
