import 'package:flutter/material.dart';
import 'main.dart'; // Para usar 'supabase'

class PaginaHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userName = user?.userMetadata?['nombre'] ?? 'Usuario';
    final avatarUrl = user?.userMetadata?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Página Principal'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (avatarUrl != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(avatarUrl),
              )
            else
              CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
            SizedBox(height: 20),
            Text(
              '¡Bienvenido, $userName!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text('Has iniciado sesión como:\n${user?.email}'),
          ],
        ),
      ),
    );
  }
}