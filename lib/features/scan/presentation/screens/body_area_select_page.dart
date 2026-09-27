import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class BodyAreaSelectPage extends StatelessWidget {
  const BodyAreaSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Body Area Select',
      description:
          'This page can let the user choose the body area and prepare the lesion location for the scan record.',
    );
  }
}
