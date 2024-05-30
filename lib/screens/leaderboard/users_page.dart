import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/providers/users_provider.dart';

class UsersListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsyncValue = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Users List')),
      body: usersAsyncValue.when(
        data: (users) => ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.username),
              subtitle: Column(
                children: [
                  Text(user.email),
                  Text(user.color),
                  Text(user.role),
                  Text(user.dateCreated.toString()),
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
