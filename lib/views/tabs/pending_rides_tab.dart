import 'package:project/views/driver/pending_requests_view.dart';
import 'package:flutter/material.dart';
import 'package:project/views/pending_rides_view.dart';

class PendingRidesTab extends StatelessWidget {
  const PendingRidesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            SizedBox(height: 30),
            Expanded(
              child: PendingRidesView(),
            )
          ])),
    );
  }
}
