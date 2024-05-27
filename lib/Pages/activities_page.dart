import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/providers/activity_provider.dart';

class ActivitiesListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsyncValue = ref.watch(monthlyActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Activities List')),
      body: activitiesAsyncValue.when(
        data: (activities) => ListView.builder(
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return ListTile(
              title: Text(activity.id.toString()),
              subtitle: Column(
                children: [
                  Text(index.toString()),
                  Text(activity.startDateLocal),
                ],
              ),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
