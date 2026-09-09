import 'package:flutter/material.dart';

class TvSignagePage extends StatelessWidget {
  const TvSignagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('tv_signage_page'),
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'TV Signage',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
