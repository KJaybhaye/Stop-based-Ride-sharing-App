import 'package:project/views/future_rides_view.dart';
import 'package:flutter/material.dart';

class FutureTab extends StatelessWidget {
  const FutureTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureRidesView(),
    );
  }
}
