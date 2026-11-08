import 'package:flutter/material.dart';

import 'performance_progress_tab.dart';
import 'weight_progress_tab.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Progression',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Poids'),
              Tab(text: 'Performances'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WeightProgressTab(),
            PerformanceProgressTab(),
          ],
        ),
      ),
    );
  }
}
