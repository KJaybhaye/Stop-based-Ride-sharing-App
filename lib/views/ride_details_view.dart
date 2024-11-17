import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/shared%20preferences/shared_pref.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/utils/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/widgets/purple_button.dart';
import '../controller/ride_controller.dart';
import '../widgets/ride_box.dart';
import '../widgets/text_widget.dart';

class RideDetailsView extends StatefulWidget {
  DocumentSnapshot ride;
  DocumentSnapshot driver;
  DocumentSnapshot? request;
  bool hasEnded;
  RideDetailsView(this.ride, this.driver, {this.hasEnded = false});

  @override
  State<RideDetailsView> createState() => _RideDetailsViewState();
}

class _RideDetailsViewState extends State<RideDetailsView> {
  RideController rideController = Get.find<RideController>();
  TextEditingController starController = TextEditingController();

  bool isDriver = false;

  @override
  void initState() {
    super.initState();
    rideController.isRidesLoading(true);

    isDriver = CacheHelper.getData(key: AppConstants.decisionKey) ?? false;

    print(isDriver.toString());
    rideController.getAcceptedUserForRide(widget.ride.id);
  }

  @override
  Widget build(BuildContext context) {
    RideController rideController = Get.find<RideController>();

    String userId = FirebaseAuth.instance.currentUser!.uid;
    List pendingUsers = [];
    List joinedUsers = [];
    List rejectedUsers = [];
    Map<String, dynamic> driverReview = {};


    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.purpleColor,
        title: Text('Ride Details'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rides')
                .doc(widget.ride.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              DocumentSnapshot ride = snapshot.data!;

              String userId = FirebaseAuth.instance.currentUser!.uid;

              //String rideId = ride.id;

              String maxSeats = ride.get('max_seats');

              String status = ride.get('status');

              try {
                pendingUsers = ride.get('pending');
              } catch (e) {
                pendingUsers = [];
              }

              try {
                joinedUsers = ride.get('joined');
              } catch (e) {
                joinedUsers = [];
              }

              try {
                rejectedUsers = ride.get('rejected');
              } catch (e) {
                rejectedUsers = [];
              }
              try{
                driverReview = widget.driver.get('reviews');
              }catch(e){
                driverReview = {};
              }
              return SingleChildScrollView(child: Column(
                children: [
                  RideBox(ride: ride, driver: widget.driver, showCarDetails: true),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      child: Row(
                        children: [
                          if(isDriver)...[
                          Container(
                            width: Get.width * 0.7,
                            height: 50,
                            child: Row(
                              children: List<Widget>.generate(
                                joinedUsers.length,
                                (index) {
                                  DocumentSnapshot user =
                                      rideController.allUsers.firstWhere(
                                          (e) => e.id == joinedUsers[index]);
                                  String image = '';
                                  String name = '';
                                  Map<String, dynamic> reviews = {};

                                  try {
                                    image = user.get('image');
                                  } catch (e) {
                                    image = '';
                                  }
                                  try {
                                    name = user.get('name');
                                  } catch (e) {
                                    name = '';
                                  }
                                  try {
                                    reviews = user.get('reviews');
                                  } catch (e) {
                                    reviews = {};
                                  }
                                  print(reviews);
                                  return Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Row(children: [CircleAvatar(
                                      backgroundImage: NetworkImage(image),
                                    ),
                                    const SizedBox(width: 10,),
                                    Text(name, overflow:TextOverflow.clip),
                                    const SizedBox(width: 10,),
                                    if(widget.hasEnded)...[
                                      MaterialButton(child: Text(reviews.containsKey(userId)? "Update Review": "Review"), 
                                        onPressed: (){
                                          Get.defaultDialog(
                                          title: "Put number of stars (between 0 to 5)",
                                          content: TextFormField(
                                              controller: starController,
                                            ),
                                          onConfirm: () {
                                            double stars = double.parse(starController.text);
                                            if(stars < 0 || stars > 5){
                                              Get.snackbar('', 'Input value between 0 and 5 only.',
                                                colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
                                                return;
                                            }
                                            if(reviews.containsKey(userId)){
                                        //update review
                                            rideController.addReview(user.id, userId, stars, update: true, collection: 'users');
                                        // reviews = user.get('reviews');
                                            setState(() {
                                             reviews = user.get('reviews');
                                            });
                                            Get.back();
                                            return;
                                          }
                                          rideController.addReview(user.id, userId, stars, collection: 'users');
                                          setState(() {
                                            reviews = user.get('reviews');
                                          });  
                                          Get.back();                            
                                        },
                                        textConfirm: "Enter",
                                        textCancel: 'Cancel',
                                        
                                  );
                                  },color: AppColors.purpleColor
                                  )]
                                    ]),
                                  );
                                },
                              ),
                            ),
                          ),],
                          if(!widget.hasEnded)...[
                          Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${widget.ride.get('price_per_seat')} Rs',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                '${widget.ride.get('max_seats')} left',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          )]
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  // Spacer(),
                  if (isDriver) ...[
                    if (widget.ride.get('status') == 'Ended' ||
                        widget.ride.get('status') == 'Cancelled')
                      ...[]
                    else if (widget.ride.get('status') == 'Upcoming' && !widget.hasEnded) ...[
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                rideController.cancelRide(widget.ride.id);
                                rideController.updateHistoryDriverRide();
                                rideController.updateHistoryUserRide();
                              },
                              child: Container(
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
                    ]
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                              onTap: () {
                                if (pendingUsers.contains(userId))
                                {
                                } else if (joinedUsers.contains(userId))
                                {
                                } else if (rejectedUsers.contains(userId))
                                {
                                } else if (ride.get('max_seats') == "0 seats") {

                                } else {
                                  Get.defaultDialog(
                                    title: "Are you sure to join this ride ?",
                                    content: Container(),
                                    //barrierDismissible: false,
                                    actions: [
                                      MaterialButton(
                                        onPressed: () {
                                          Get.back();

                                          //rideController.isRequestLoading(true);
                                          rideController.requestToJoinRide(
                                              ride, userId, FirebaseAuth.instance.currentUser!.phoneNumber!);

                                          // Get.back();
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
                                }
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(13),
                                    color: pendingUsers.contains(userId)
                                        ? AppColors.yellow.withOpacity(0.9)
                                        : rejectedUsers.contains(userId)
                                            ? Colors.red.shade700
                                            : joinedUsers.contains(userId)
                                                ? AppColors.purpleColor
                                                    .withOpacity(0.9)
                                                : AppColors.purpleColor
                                                    .withOpacity(0.9)),
                                child: Center(
                                    child: Text(
                                      widget.hasEnded 
                                      ? "Completed"
                                      : pendingUsers.contains(userId)
                                        ? "Pending"
                                        : rejectedUsers.contains(userId)
                                          ? "Rejected"
                                          : joinedUsers.contains(userId)
                                              ? "Joined"
                                              : ride.get('max_seats') ==
                                                      "0 seats"
                                                  ? "No seats Available"
                                                  : "Send Request",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                )),
                              )),
                        ),
                        if (widget.hasEnded) ...[
                          SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              // child: InkWell(
                              //   onTap: () {
                              //     // Get.to(() =>
                              //     //     PaymentView(widget.ride, widget.driver));
                              //   },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.4),
                                          spreadRadius: 0.1,
                                          blurRadius: 60,
                                          offset: Offset(
                                              0, 1), // changes position of shadow
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(13)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  child: Center(
                                    child: Text(
                                      'Fair: ${widget.ride.get('price_per_seat')}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                        ]
                      ],
                    ),
                    if(widget.hasEnded)...[
                    MaterialButton(child: Text(driverReview.containsKey(userId)? "Update Review": "Review driver"),
                          onPressed: (){
                            Get.defaultDialog(
                                          title: "Put number of stars (between 0 to 5)",
                                          content: TextFormField(
                                              controller: starController,
                                            ),
                                          onConfirm: () {
                                            double stars = double.parse(starController.text);
                                            if(stars < 0 || stars > 5){
                                              Get.snackbar('', 'Input value between 0 and 5 only.',
                                                colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
                                                return;
                                            }
                                          if(driverReview.containsKey(userId)){
                                            rideController.addReview(widget.driver.id, userId, stars, update: true, collection: 'drivers');
                                            // driverReview = widget.driver.get('reviews');
                                            Get.back();
                                            return;
                                          }
                                           rideController.addReview(widget.driver.id, userId, stars, collection: 'drivers');
                                            Get.back();
                                          },
                                          textConfirm: "Confirm",
                                          textCancel: "Cancel",
                                  );
                          }, color: AppColors.purpleColor,),
                  ],
                  ],
                  // if(widget.hasEnded)...[
                  //   MaterialButton(child: Text(driverReview.containsKey(userId)? "Update Review": "Review driver"),
                  //         onPressed: (){
                  //           Get.defaultDialog(
                  //                         title: "Put number of stars (between 0 to 5)",
                  //                         content: TextFormField(
                  //                             controller: starController,
                  //                           ),
                  //                         onConfirm: () {
                  //                           double stars = double.parse(starController.text);
                  //                           if(stars < 0 || stars > 5){
                  //                             Get.snackbar('', 'Input value between 0 and 5 only.',
                  //                               colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
                  //                               return;
                  //                           }
                  //                         if(driverReview.containsKey(userId)){
                  //                           rideController.addReview(widget.driver.id, userId, stars, update: true, collection: 'drivers');
                  //                           // driverReview = widget.driver.get('reviews');
                  //                           Get.back();
                  //                           return;
                  //                         }
                  //                          rideController.addReview(widget.driver.id, userId, stars, collection: 'drivers');
                  //                           Get.back();
                  //                         },
                  //                         textConfirm: "Confirm",
                  //                         textCancel: "Cancel",
                  //                 );
                  //         }, color: AppColors.purpleColor,),
                  // ],
                  // SizedBox(
                  //   height: 10,
                  // ),
                  if (pendingUsers.contains(userId))...[
                          MaterialButton(onPressed: (){
                            Get.back();
                            //rideController.isRequestLoading(true);
                            rideController.cancelRequestToJoinRide(ride, userId);

                            Get.back();
                          },
                          color: Colors.amber[300],
                          child: const Text('Cancel Request'),)
                  ],
                  if (joinedUsers.contains(userId) && !widget.hasEnded)...[
                    MaterialButton(onPressed: (){
                            Get.back();
                            //rideController.isRequestLoading(true);
                            rideController.cancelAcceptedRequestUser(ride, userId);

                            Get.back();
                          },
                          color: Colors.amber[300],
                          child: const Text('Cancel Ride'),)
                  ]
                ],
              )
              );
            }),
      ),
    );
  }
}

Widget myText({text, style, textAlign}) {
  return Text(
    text,
    style: style,
    textAlign: textAlign,
  );
}
