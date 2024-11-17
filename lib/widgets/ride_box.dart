import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:project/views/driver/view_users.dart';
import 'package:project/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared preferences/shared_pref.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../views/ride_details_view.dart';

class RideBox extends StatefulWidget {
  final DocumentSnapshot ride;
  final DocumentSnapshot driver;
  final bool showCarDetails;
  final bool showOptions;
  final bool shouldNavigate;
  final bool showStartOption;
  bool showRejectOption;
  bool showCode;
  DocumentSnapshot? request;
  bool isUpcoming;
  bool hasEnded;

  RideBox(
      {super.key,
      required this.ride,
      required this.driver,
      required this.showCarDetails,
      this.showOptions = false,
      this.shouldNavigate = false,
      this.request,
      this.showStartOption = false,
      this.showRejectOption = false,
      this.showCode = false,
      this.isUpcoming = false,
      this.hasEnded = false});

  @override
  State<RideBox> createState() => _RideBoxState();
}

class _RideBoxState extends State<RideBox> {
  RideController rideController = Get.find<RideController>();
  bool isDriver = false;

  @override
  void initState() {
    isDriver = CacheHelper.getData(key: AppConstants.decisionKey) ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List dateInformation = [];
    // Map<String, dynamic> codes = {};
    Map<String, dynamic> passengers = {};
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String driverPhone = '';
    TextEditingController? codeController = TextEditingController();
    List pickedUp = [];
    Map<String, dynamic> reviews = {};
    var src;
    var dest;
    // pickedUp = widget.ride.get('picked_up');
    // codes = widget.ride.get('codes');
    
    try {
      dateInformation = widget.ride.get('date').toString().split('-');
      pickedUp = widget.ride.get('picked_up');
      // codes = widget.ride.get('codes');
      driverPhone = widget.ride.get('driverPhone');
      passengers = widget.ride.get('passengers');
      reviews = widget.driver.get("reviews");
      src = widget.ride.get('pickup_latlng');
      dest = widget.ride.get('destination_latlng');
    } catch (e) {
      print(e);
      // dateInformation = [];
      // codes = {};
    }

    return InkWell(
      onTap: () {
        if (widget.showCarDetails == false) {
          if (widget.showOptions == true ||
              widget.shouldNavigate == false ||
              widget.showStartOption == true) {
          } else {
            Get.to(() => RideDetailsView(widget.ride, widget.driver, hasEnded: widget.hasEnded));
          }
        }
      },
      child: Container(
        width: double.maxFinite,
        height: widget.showCarDetails ||
                widget.showOptions ||
                widget.showStartOption ||
                widget.showRejectOption ||
                widget.isUpcoming || widget.showCode
            ? 290
            : 245,
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              horizontalTitleGap: 10,
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                  widget.driver.get('image')!,
                ),
              ),
              title: Text(
                '${widget.driver.get('name')}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              trailing: Text('${widget.driver.get('gender')}',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),),
              subtitle: Row(children: [
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
                Text("(${reviews.length} Review)"),
              ]),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Ionicons.location_outline,
                          color: AppColors.purpleColor,
                          size: 20,
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width / 1.6),
                          child: SizedBox(
                            width: double.maxFinite,
                            child: Text(
                              'From: ${widget.ride.get('pickup_address')}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Icon(
                          Ionicons.location_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width / 1.6),
                          child: SizedBox(
                            width: double.maxFinite,
                            child: Text(
                              'To: ${widget.ride.get('destination_address')}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8.0,
                  ),
                  decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(
                        Ionicons.calendar_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 6, right: 14),
                        child: Text(
                          '${dateInformation[0]}-${dateInformation[1]}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Ionicons.time_outline,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${widget.ride.get('start_time')}',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.showCarDetails) ...[
                  Spacer(),
                  myText(
                    text: '${widget.ride.get('price_per_seat')} RS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ]
              ],
            ),
            if (widget.showOptions) ...[
              const SizedBox(height: 10),
              Obx(() => rideController.isRequestLoading.value
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Get.defaultDialog(
                                title: "Are you sure to accept this request ?",
                                content: Container(),
                                actions: [
                                  MaterialButton(
                                    onPressed: () {
                                      Get.back();

                                      rideController.isRequestLoading(true);
                                      rideController.acceptRequest(
                                          widget.ride, widget.request);
                                      rideController.updatePendingRequests();

                                      Get.back();
                                    },
                                    child: textWidget(
                                      text: 'Confirm',
                                      color: Colors.white,
                                    ),
                                    color: AppColors.purpleColor,
                                    shape: StadiumBorder(),
                                  ),
                                  SizedBox(width: 7),
                                  MaterialButton(
                                    onPressed: () {
                                      Get.back();
                                    },
                                    child: textWidget(
                                      text: 'Cancel',
                                      color: Colors.white,
                                    ),
                                    color: Colors.red,
                                    shape: StadiumBorder(),
                                  ),
                                ],
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8.0,
                              ),
                              decoration: BoxDecoration(
                                  color: AppColors.purpleColor,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text(
                                  "Accept",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Get.defaultDialog(
                                title: "Are you sure to reject this request ?",
                                content: Container(),
                                actions: [
                                  MaterialButton(
                                    onPressed: () {
                                      Get.back();
                                      rideController.isRequestLoading(true);
                                      rideController.rejectRequest(
                                          widget.ride, widget.request);
                                      rideController.updatePendingRequests();
                                      Get.back();
                                    },
                                    child: textWidget(
                                      text: 'Confirm',
                                      color: Colors.white,
                                    ),
                                    color: AppColors.purpleColor,
                                    shape: StadiumBorder(),
                                  ),
                                  SizedBox(width: 7),
                                  MaterialButton(
                                    onPressed: () {
                                      Get.back();
                                    },
                                    child: textWidget(
                                      text: 'Cancel',
                                      color: Colors.white,
                                    ),
                                    color: Colors.red,
                                    shape: StadiumBorder(),
                                  ),
                                ],
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8.0,
                              ),
                              decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text(
                                  "Reject",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ))
            ], if(widget.showRejectOption && !pickedUp.contains(widget.request?.get('user_id'))) ...[
              const SizedBox(height: 10),
              Obx(() => rideController.isRequestLoading.value
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Row(children: [Expanded(
                          child: InkWell(
                            onTap: () {
                              Get.defaultDialog(
                                title: "Are you sure to cancel this request ?",
                                content: Container(),
                                actions: [
                                  MaterialButton(
                                    onPressed: () {
                                      Get.back();

                                      rideController.isRequestLoading(true);
                                      rideController.rejectAcceptedRequestDriver(widget.ride, widget.request);
                                      // rideController.acceptRequest(
                                      //     widget.ride, widget.request);
                                      rideController.updateAcceptedRequests();
                                      // rideController.updatePendingRequests();

                                      Get.back();
                                    },
                                    child: textWidget(
                                      text: 'Confirm',
                                      color: Colors.white,
                                    ),
                                    color: AppColors.purpleColor,
                                    shape: StadiumBorder(),
                                  ),
                                  SizedBox(width: 7),
                                  MaterialButton(
                                    onPressed: () {
                                      Get.back();
                                    },
                                    child: textWidget(
                                      text: 'Cancel',
                                      color: Colors.white,
                                    ),
                                    color: Colors.red,
                                    shape: StadiumBorder(),
                                  ),
                                ],
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8.0,
                              ),
                              decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text(
                                  "Cancel Request",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Expanded(
                        //   child: InkWell(
                        //     onTap: () {
                        //       Get.defaultDialog(
                        //         title: "Put code for user",
                        //         content: Container(),
                        //         actions: [
                        //           TextFormField(
                        //             controller: codeController,
                        //           ),

                        //           SizedBox(width: 7),
                        //           MaterialButton(
                        //             onPressed: () {
                        //               try {
                        //               rideController.pickup(widget.ride.id, widget.request?.get('user_id'), codeController.text);
                        //               // pickedUp = widget.ride.get('picked_up');
                        //               } catch (e) {
                        //                 print(e);
                        //               }
                        //                Get.back(closeOverlays: true);
                        //               //  Get.back();                                     
                        //             },
                        //             child: textWidget(
                        //               text: 'Enter',
                        //               color: Colors.white,
                        //             ),
                        //             color: Color.fromARGB(255, 3, 251, 7),
                        //             shape: StadiumBorder(),
                        //           ),
                        //         ],
                        //       );
                        //     },
                        //     child: Container(
                        //       padding: const EdgeInsets.symmetric(
                        //         vertical: 6,
                        //         horizontal: 8.0,
                        //       ),
                        //       decoration: BoxDecoration(
                        //           color: Color.fromARGB(255, 1, 246, 66),
                        //           borderRadius: BorderRadius.circular(10)),
                        //       child: Center(
                        //         child: Text(
                        //           "Pickup",
                        //           style: TextStyle(
                        //             color: Colors.white,
                        //             fontWeight: FontWeight.w500,
                        //             fontSize: 16,
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        ]
              )
            )
            ],
            
           if (widget.isUpcoming && isDriver) ...[
              const SizedBox(height: 10),
              Obx(
                () => rideController.isRidesLoading.value
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Row(
                        children: [
                          IconButton(
                    icon: Icon(Icons.map),
                    color: AppColors.purpleColor,
                    onPressed: () async {
                      try {
                        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${dest?.latitude},${dest?.longitude}');
                        launchUrl(url);
                      } catch (e) {
                        print(e);
                      }                      
                    },
                    ),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                // Check if the 'joined' field exists and has a length >= 1
                                final joinedArrayLength = await rideController
                                    .getJoinedArrayLength(widget.ride.id);
                                if (joinedArrayLength >= 1) {
                                          Get.to(() => ViewUsers(
                                              rideId: widget.ride.id, ride: widget.ride, isUpcoming: true,));
                                } else {
                                  Get.snackbar(
                                    'FAILED TO PICKUP!',
                                    'No one joined the ride, you need to have at least one passenger with you!',
                                    colorText: Colors.white,
                                    backgroundColor: Colors.red,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.purpleColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    "Pickup",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                rideController.cancelRide(widget.ride.id);
                                rideController.updateHistoryDriverRide();
                                rideController.updateHistoryUserRide();
                                rideController.updateUpcomingDriverRide();
                              },
                              child: Container(
                                // height: 50,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8.0,
                                ),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(13),
                                    color: Colors.red.withOpacity(0.9)),
                                child: Center(
                                  child: Text(
                                    "Cancel Ride",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
            if (widget.showStartOption && isDriver) ...[
              const SizedBox(height: 10),
              Obx(
                () => rideController.isRidesLoading.value
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                // Check if the 'joined' field exists and has a length >= 1
                                final joinedArrayLength = await rideController
                                    .getJoinedArrayLength(widget.ride.id);
                                if (joinedArrayLength >= 1) {
                                          Get.to(() => ViewUsers(
                                              rideId: widget.ride.id, ride: widget.ride));
                                } else {
                                  Get.snackbar(
                                    'FAILED TO START THE RIDE!',
                                    'No one joined the ride, you need to have at least one passenger with you!',
                                    colorText: Colors.white,
                                    backgroundColor: Colors.red,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.purpleColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    "Pickup/Start/End",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                    icon: Icon(Icons.map),
                    color: AppColors.purpleColor,
                    onPressed: () async {
                      try {
                        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${dest?.latitude},${dest?.longitude}');
                        launchUrl(url);
                      } catch (e) {
                        print(e);
                      }                      
                    },
                    ),
                        ],
                      ),
              ),
            ],
            if (widget.showStartOption && !isDriver) ...[
              const SizedBox(height: 7),
              Center(
                child: Text(
                  "Welcome Aboard!",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purpleColor,
                  ),
                ),
              ),
              IconButton(
                    icon: Icon(Icons.map),
                    color: AppColors.purpleColor,
                    onPressed: () async {
                      try {
                        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${dest?.latitude},${dest?.longitude}');
                        launchUrl(url);
                      } catch (e) {
                        print(e);
                      }                      
                    },
                    ),
            ],
            if (widget.showCarDetails) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    //width: 200,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8.0,
                    ),
                    decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(
                          Ionicons.car_sport,
                          size: 18,
                          color: Colors.white,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 6, right: 8),
                          child: Text(
                            '${widget.driver.get('Vehicle_make')} ${widget.driver.get('Vehicle_model')}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Container(
                            color: Colors.white,
                            child: SizedBox(
                              width: 2,
                              height: 16,
                            ),
                          ),
                        ),
                        Text(
                          '${widget.driver.get('Vehicle_color')}',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
            if (widget.ride.get('status') == "Cancelled") ...[
              const SizedBox(height: 7),
              Center(
                child: Text(
                  '${widget.ride.get('status')}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ]else if(widget.showCode)...[
              const SizedBox(height: 7),
              Row(
              children: [Text(
                  'Code: ${passengers[userId]['code']}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 250, 30, 14),
                  ),
                ),
                IconButton(
                    icon: Icon(Icons.phone),
                    color: AppColors.purpleColor,
                    onPressed: () async {
                      final Uri launchPhoneUri = Uri(scheme: 'tel',path: driverPhone);
                      await launchUrl(launchPhoneUri);
                    },),
                IconButton(
                    icon: Icon(Icons.map),
                    color: AppColors.purpleColor,
                    onPressed: () async {
                      try {
                        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${src?.latitude},${src?.longitude}');
                        launchUrl(url);
                      } catch (e) {
                        print(e);
                      }                      
                    },)
                    ]),
            ],
          ],
        ),
      ),
    );
  }
}
