import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:project/widgets/ride_box.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearestRidesCards extends StatefulWidget {
  const NearestRidesCards({Key? key}) : super(key: key);

  @override
  State<NearestRidesCards> createState() => _NearestRidesCardsState();
}

class _NearestRidesCardsState extends State<NearestRidesCards> {
  RideController rideController = Get.find<RideController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
    child: Column(
    children: [Obx(
          () => Visibility(
        visible: rideController.filteredAndArrangedRides.isNotEmpty,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: rideController.filteredAndArrangedRides.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ride =
            rideController.filteredAndArrangedRides[index];
            DocumentSnapshot driver = rideController.allUsers
                .firstWhere((e) => ride.get('driver') == e.id);

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 13, horizontal: 2),
              child: RideBox(
                ride: ride,
                driver: driver,
                showCarDetails: false,
                shouldNavigate: true,
              ),
            );
          },
        ),
        replacement: Center(
          child: Text(
            'No rides currently available!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
    SizedBox(height: 20),
    Obx(() => Visibility(
        visible: rideController.closestRides.isNotEmpty,
    child: Container(
      height: 30,
      child: Text("Other closest rides",
      style: TextStyle(
             color:Colors.green[700] ,
              fontSize: 20,
              fontWeight: FontWeight.bold),
              )
    ),
    replacement:Container(),)),
    SizedBox(height: 20),
    ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: rideController.closestRides.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ride =
            rideController.closestRides[index];
            DocumentSnapshot driver = rideController.allUsers
                .firstWhere((e) => ride.get('driver') == e.id);

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 13, horizontal: 2),
              child: RideBox(
                ride: ride,
                driver: driver,
                showCarDetails: false,
                shouldNavigate: true,
              ),
            );
          },
        )
    ]
    ));
  }
}
