import 'package:project/utils/app_colors.dart';
import 'package:project/views/tabs/accepted_tab.dart';
import 'package:project/views/tabs/pending_tab.dart';
import 'package:project/views/tabs/rejected_tab.dart';
import 'package:flutter/material.dart';

class RideRequests extends StatelessWidget {
  const RideRequests({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.purpleColor,
          title: const Text('My Requests'),
          centerTitle: true,
          bottom: TabBar(
              isScrollable: true,
              labelColor: AppColors.whiteColor,
              labelStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              unselectedLabelColor: Colors.grey[300],
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              indicatorWeight: 3.0,
              padding: const EdgeInsets.only(left: 30, right: 30),
              tabs: [
                const Tab(text: 'Pending'),
                const Tab(text: 'Accepted'),
                const Tab(text: 'Rejected'),
                // Tab(icon: Icon(Icons.settings )),
              ]),
        ),
        body: const Column(
          children: [
            Expanded(
              child: const TabBarView(children: [
                PendingTab(),
                AcceptedTab(),
                RejectedTab(),
              ]),
            )
          ],
        ),
      ),
    );
  }
}
