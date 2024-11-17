import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:project/widgets/text_widget.dart';

import '../shared preferences/shared_pref.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';


class UserBox extends StatefulWidget {
  final DocumentSnapshot user;
  final String rideId;
  DocumentSnapshot ride;

  UserBox({
    Key? key,
    required this.user,
    required this.rideId,
    required this.ride
  }) : super(key: key);

  @override
  State<UserBox> createState() => _UserBoxState();
}

class _UserBoxState extends State<UserBox> {
  RideController rideController = Get.find<RideController>();
  bool isDriver = false;
  bool isPickedUp = false;
  List pickedUp = [];

  @override
  void initState() {
    isDriver = CacheHelper.getData(key: AppConstants.decisionKey) ?? false;
    super.initState();
    try {
      FirebaseFirestore.instance.collection('rides').doc(widget.rideId).get().then((value) => pickedUp = value.get('picked_up'));
      print('here');
      print(pickedUp.length);
    } catch (e) {
      pickedUp = [];
    }
  }

  void onPickedUp() {
    setState(() {
      isPickedUp = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController? codeController = TextEditingController();
    //  Map<String, dynamic> phoneMap = widget.ride.get('phones') as Map<String, dynamic>;
    // final Uri launchPhoneUri = Uri(scheme: 'tel',path: phoneMap[widget.user.id]);
    Map<String, dynamic> passengersMap = widget.ride.get('passengers') as Map<String, dynamic>;
    final Uri launchPhoneUri = Uri(scheme: 'tel',path: passengersMap[widget.user.id]['phone']);
     Map<String, dynamic> reviews = widget.user.get('reviews');

    
    return InkWell(
        onTap: () {
          // Handle onTap logic here
        },
        child: Container(
          width: double.maxFinite,
          height: 170,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                blurRadius: 2,
                spreadRadius: 1,
                color: Color(0xff393939).withOpacity(0.15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(
                      widget.user.get('image')!,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      horizontalTitleGap: 10,
                      title: Text(
                        '${widget.user.get('name')}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            Ionicons.star,
                            color: Colors.yellow[700],
                            size: 18,
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 4, right: 6),
                            child: Text(
                              reviews.isEmpty ? " " : '${reviews.values.reduce((value, element) => value + element)/ reviews.length}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text("(${reviews.length} Review)")
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.phone),
                    color: AppColors.purpleColor,
                    onPressed: () async {
                      await launchUrl(launchPhoneUri);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(children: [
              ]),
              if(!pickedUp.contains(widget.user.id))...[
                MaterialButton(child: Text("Pickup"), onPressed: (){
                          Get.defaultDialog(
                                title: "Put code for user",
                                content: TextFormField(
                                    controller: codeController,
                                  ),
                                onConfirm: () {
                                  rideController.isRidesLoading(false);
                                    try {
                                      rideController.pickup(widget.ride.id, widget.user.id, codeController.text);
                                      Get.back();
                                    } catch (e) {
                                        print(e);
                                    }
                                    Get.back();    
                                    },
                                textConfirm: "Confirm",
                                textCancel: "Cancel",
                            );
                          }, color: AppColors.purpleColor,),
              ]else...[
                Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8.0,
                              ),
                              decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 1, 246, 66),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text(
                                  "Picked Up",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
              ]
            ],
            
          ),
        ));
  }
}
