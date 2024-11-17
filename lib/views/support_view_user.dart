import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:project/widgets/purple_button.dart';
import 'package:project/widgets/ride_box.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/widgets/support_form.dart';
import 'package:project/widgets/support_ride_box.dart';

class SupportViewUser extends StatefulWidget {
  const SupportViewUser({Key? key}) : super(key: key);

  @override
  State<SupportViewUser> createState() => _SupportViewUserState();
}

class _SupportViewUserState extends State<SupportViewUser> {
  RideController rideController = Get.find<RideController>();
  bool loading = true;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      rideController.getRidesIJoined();
      rideController.getRideHistoryForUser();
      rideController.getMyDocument();
      timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if(!rideController.isRidesLoading.value){
          rideController.getRideHistoryForUser();
          timer.cancel();
          setState((){
        loading = rideController.isRidesLoading.value;
        });
      }
    });
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Support', style: TextStyle(color: Colors.black)),
      backgroundColor: Colors.white,),
      resizeToAvoidBottomInset: false,
      body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),

          child: SingleChildScrollView(
          child: Column(children: [
            SizedBox(height: 30),
            purpleButton("General Support", (){
              Get.to(()=> SupportFormWidget(userId: FirebaseAuth.instance.currentUser!.uid,));
              //get to support page without ride details
            }),
            SizedBox(height: 20),
            Container(
              height: 30,
              child: Text("Support for rides",
              style: TextStyle(
                color:Colors.black ,
                fontSize: 18,
                fontWeight: FontWeight.bold),
              )
            ),
          
            ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
              DocumentSnapshot driver = rideController.allUsers.firstWhere(
                (e) => rideController.userHistory[index].get('driver') == e.id);

            return Padding(
                padding: EdgeInsets.symmetric(vertical: 10,
                horizontal: 10
                ),
                child: SupportRideBox(
                  ride: rideController.userHistory[index],
                  driver: driver,
                ));
          },
          itemCount: rideController.userHistory.length,
        )
    ]
    ))
    )

    );
    
  }
}
