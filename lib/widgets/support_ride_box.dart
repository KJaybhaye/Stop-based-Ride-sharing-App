import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:project/widgets/support_form.dart';

import '../shared preferences/shared_pref.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../views/ride_details_view.dart';

class SupportRideBox extends StatefulWidget {
  final DocumentSnapshot ride;
  final DocumentSnapshot driver;

  SupportRideBox(
      {super.key,
      required this.ride,
      required this.driver,});

  @override
  State<SupportRideBox> createState() => _SupportRideBoxState();
}

class _SupportRideBoxState extends State<SupportRideBox> {
  RideController rideController = Get.find<RideController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List dateInformation = [];
    
    try {
      dateInformation = widget.ride.get('date').toString().split('-');
    } catch (e) {
      print(e);
      dateInformation = [];
    }

    return Material(
      child: InkWell(
      onTap: () {
            // to support with ride details
             Get.to(()=> SupportFormWidget(userId: widget.driver.id, rideId: widget.ride.id));
      },
      child: Container(
        width: 300,
        height: 230,
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
                  Spacer(),
                  myText(
                    text: '${widget.ride.get('price_per_seat')} RS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
              ],
            ),
            ]
            ),
        ),
    ));
  }
}

