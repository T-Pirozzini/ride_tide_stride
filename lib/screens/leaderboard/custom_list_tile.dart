import 'package:flutter/material.dart';
import 'package:ride_tide_stride/screens/leaderboard/custom_place.dart';
import 'package:ride_tide_stride/screens/leaderboard/custom_total.dart';

class CustomListTile extends StatelessWidget {
  const CustomListTile({super.key, required this.title, required this.trailingText, required this.entry, required this.currentPlace});

  final String title;
  final String trailingText;
  final Map<String, dynamic> entry;
  final int currentPlace;

  @override
  Widget build(BuildContext context) {
    return ListTile(
                tileColor: Colors.white,
                title: Text('${entry['full_name']}',
                    style: Theme.of(context).textTheme.bodyLarge),
                leading: CustomPlaceWidget(place: '$currentPlace'),
                subtitle:
                    Text(title, style: Theme.of(context).textTheme.bodyMedium),
                trailing: CustomTotalWidget(total: trailingText),
              );
            }
}


              