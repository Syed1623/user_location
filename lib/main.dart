import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:userlocation/pages/location_stream_page.dart';
import 'package:userlocation/providers/location_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Location Stream Example',
      home: LocationStreamPage(),
    );
  }
}
