import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder_page.dart';

class QuestionnairePage extends StatelessWidget {
  const QuestionnairePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Questionnaire',
      description:
          'This page can ask baseline screening questions such as recent change, family history, and prior concern.',
    );
  }
}
