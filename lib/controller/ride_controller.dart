import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project/shared%20preferences/shared_pref.dart';
import 'package:project/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:project/utils/app_constants.dart';
import 'package:project/widgets/pending_rides_for_user.dart';
import 'package:http/http.dart' as http;

class RideController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    getUsers();
    getRides();
  }

  FirebaseAuth auth = FirebaseAuth.instance;

  late DocumentSnapshot myDocument;

  RxList allUsers = [].obs;
  RxList allRides = [].obs;
  RxList userSnapshots = [].obs;
  RxList filteredAndArrangedRides = [].obs;
  RxList closestRides = [].obs;

  RxList ridesICreated = [].obs; // Rides with all dates
  RxList ridesICancelled = [].obs; // Rides that were cancelled
  RxList ridesIJoined = [].obs; // Rides user joined it
  RxList ridesIEnded = [].obs; // Rides that were ended

  RxList upcomingRidesForDriver = [].obs; // Rides with upcoming date for driver
  RxList upcomingRidesForUser = [].obs; // Rides with upcoming date for user
  RxList requestedRidesForUser = [].obs;
  RxList allPendingRidesForUser = [].obs;
  RxList futureRidesForDriver = [].obs; // Rides with upcoming date for driver
  RxList futureRidesForUser = [].obs;

  RxList driverHistory = [].obs; // Rides that ended or cancelled for driver
  RxList userHistory = [].obs; // Rides that ended or cancelled for user

  RxList driverCurrentRide = [].obs; // contains the driver current ride
  RxList userCurrentRide = [].obs; // contains the user current ride

  RxList myRequests = [].obs;
  RxList pendingRequests = [].obs;
  RxList acceptedRequests = [].obs;
  RxList rejectedRequests = [].obs;

  var isRideUploading = false.obs;
  var isRidesLoading = false.obs;
  var isUsersLoading = false.obs;
  var isRequestLoading = false.obs;

  // Main Functionalities
  ///this method is for storing Ride Info into Firebase
  createRide(Map<String, dynamic> rideData) async {
    isRideUploading(true);
    await FirebaseFirestore.instance
        .collection('rides')
        .add(rideData)
        .then((value) {
      Get.snackbar('Success', 'Your ride is created successfully.',
          colorText: Colors.white, backgroundColor: Color(0xFF00832C));
      isRideUploading(false);
      updateUpcomingDriverRide();
      updateUpcomingUserRide();
    }).catchError((e) {
      isRideUploading(false);
      Get.snackbar('Failure', 'Failed to create ride.',
          colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
    });
  }

  /// this method allows the driver to cancel his ride
  cancelRide(String rideId) async {
    try {
      // Get a reference to the ride document in Firestore to update to it
      DocumentReference rideRef =
          FirebaseFirestore.instance.collection('rides').doc(rideId);

      // Add the userId to the pending array in the ride document
      await rideRef.update({
        'status': "Cancelled",
      }).then((value) {
        Get.snackbar('Success', 'Your ride was canceled',
            colorText: Colors.white, backgroundColor: Colors.red);
        updateHistoryDriverRide();
        updateHistoryUserRide();
      });
      try {
        rideRef.get().then((value) async {
        for (String id in value.get('joined')){
          DocumentSnapshot ur = await FirebaseFirestore.instance.collection('tokens').doc(id).get();
        sendPushMessage("Your ride at ${value.get('start_time')} was cancelled", "Ride cancelled", ur['token']);
        }
      } 
      );
      } catch (e) {
        // continue if failed to send notification
      }
    } catch (e) {
      Get.snackbar('Failure','Could not cancel ride.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
    }
  }

  /// this method allows the driver to start his ride
  startRide(String rideId) async {
    try {
      // Get a reference to the ride document in Firestore to update to it
      DocumentReference rideRef =
          FirebaseFirestore.instance.collection('rides').doc(rideId);

      // Add the userId to the pending array in the ride document
      await rideRef.update({
        'status': "Started",
      }).then((value) {
        Get.snackbar('Success', 'Have a safe journey!',
            colorText: Colors.white, backgroundColor: const Color(0xFF00832C));
        isRideUploading(false);
        updateOngoingDriverRide();
        updateOngoingUserRide();
      });
      try {
        rideRef.get().then((value) async {
        for (String id in value.get('joined')){
          if (!value.get('picked_up').contains(id)){
          DocumentSnapshot ur = await FirebaseFirestore.instance.collection('tokens').doc(id).get();
          sendPushMessage("Driver for ride at ${value.get('start_time')} is at pickup point.", "Ride ready", ur['token']);
          }
        }
      } 
      );
      } catch (e) {
        // continue if failed to send notification
      }
    } catch (e) {
      Get.snackbar('Failure!','Could not start the ride.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
    }
  }

  pickup(String rideId, String userId, String code) async{
    //get code for user
    //if codes equal
    //put in pickeup
    // print('pickup');
    try {
      // Get a reference to the ride document in Firestore to update to it
      DocumentReference rideRef =
          FirebaseFirestore.instance.collection('rides').doc(rideId);
          print(rideId);
          DocumentSnapshot doc = await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
      if (doc.exists) {
        print('exists123');
      // Access the 'codes' map from the document data
      // Map<String, dynamic> codesMap = doc.get('codes') as Map<String, dynamic>;
      Map<String, dynamic> passengersMap = doc.get('passengers') as Map<String, dynamic>;

      // Retrieve the value of the specified key
      // dynamic value = codesMap[userId];
      // Map<String, dynamic> passenger = passengersMap[userId];
      dynamic value = passengersMap[userId]['code'];

      print("value");

      if(code.length == 0 || value != int.parse(code)){
        print('equal');
        Get.snackbar('Failed!','Wrong code',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
            throw Exception('Wrong code');
      }
      // String userCode = doc
      }else{
        Get.snackbar('An error occured','failed',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
            throw Exception('error');
      }

      // Add the userId to the pending array in the ride document
      await rideRef.set(
        {'picked_up': FieldValue.arrayUnion([userId])},
        SetOptions(merge: true)).then((value) {
        Get.snackbar('Success', 'Picked up user!',
            colorText: Colors.white, backgroundColor: const Color(0xFF00832C));
        isRideUploading(false);
        // updateOngoingDriverRide();
        updateOngoingUserRide();
      });
    } catch (e) {
      Get.snackbar('Failure!','Could not pickup the user.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
      throw Exception('failed');
    }
  }

  /// this method allows the driver to end his ride
  endRide(String rideId) async {
    try {
      // Get a reference to the ride document in Firestore to update to it
      DocumentReference rideRef =
          FirebaseFirestore.instance.collection('rides').doc(rideId);

      // Add the userId to the pending array in the ride document
      await rideRef.update({
        'status': "Ended",
      }).then((value) {
        Get.snackbar('Success', 'You have ended the ride!',
            colorText: Colors.white, backgroundColor: Color(0xFF00832C));
        isRideUploading(false);
        updateHistoryUserRide();
        updateHistoryDriverRide();
        try {
        rideRef.get().then((value) async {
        for (String id in value.get('picked_up')){
          DocumentSnapshot ur = await FirebaseFirestore.instance.collection('tokens').doc(id).get();
          sendPushMessage("Your fair is ${value.get('price_per_seat')}.", "Ride Finished", ur['token']);
        }
      } 
      );
      } catch (e) {
        // continue if failed to send notification
      }
      });
    } catch (e) {
      Get.snackbar('Failure!','Could not end the ride.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
    }
  }

  /// this method allows the user to send request to driver to join him on the ride
  requestToJoinRide(DocumentSnapshot ride, String userId, String mobile) async {
    try {
      String driverId = ride.get('driver');
      DateTime currentDateTime = DateTime.now();

      // Get a reference to the ride document in Firestore to update to it
      await FirebaseFirestore.instance.collection('rides').doc(ride.id).set({
        'pending': FieldValue.arrayUnion([userId]),
      }, SetOptions(merge: true)).then((value) async {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(driverId)
            .collection('requests')
            .add({'user_id': userId, 'ride_id': ride.id, 'status': 'Pending', 'date_time': currentDateTime, 'mobile': mobile});

            try{
            DocumentSnapshot dr = await FirebaseFirestore.instance.collection('tokens').doc(ride.get('driver')).get();
            sendPushMessage("You have new request!", "Ride request", dr['token']);
          } catch(e){
            // cannot send notification.
    }
      });

      Get.snackbar('Success', 'Your request was sent successfully.',
          colorText: Colors.white, backgroundColor: AppColors.purpleColor);
      isRequestLoading(false);
    } catch (e) {
      Get.snackbar('Failure!','Could not sent the request.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
    }
  }

  cancelRequestToJoinRide(DocumentSnapshot ride, String userId) async {
    try {
    String driverId = ride.get('driver');
    final fi = FirebaseFirestore.instance;
    final batch = fi.batch();
    CollectionReference requestReference = FirebaseFirestore.instance.collection('drivers').doc(driverId).collection('requests');

    // Query to find the document with a specific field value
    requestReference.where('user_id', isEqualTo: userId).
    where('ride_id', isEqualTo: ride.id).get().then((value){
      if (value.docs.isNotEmpty) {
      // Delete the document
      for (QueryDocumentSnapshot document in value.docs) {
        var di = requestReference.doc(document.id);
        batch.delete(di);
        // await collectionReference.doc(document.id).delete();
      }}
    }).catchError((e){
      Get.snackbar('Failure!','Could not cancel the request.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
      return;
    });
    var rideref = FirebaseFirestore.instance.collection('rides').doc(ride.id);
    batch.set(rideref, {
      'pending': FieldValue.arrayRemove([userId]),
      },SetOptions(merge: true));

      batch.commit().then((val) async {
        Get.snackbar('Success', 'Your request was canceled successfully.',
          colorText: Colors.white, backgroundColor: AppColors.purpleColor);
        try{
          DocumentSnapshot dr = await FirebaseFirestore.instance.collection('tokens').doc(ride.get('driver')).get();
          sendPushMessage("User cancelled a ride/request!", "Request cancelled", dr['token']);
        } catch(e){
        // cannot send message
        }
      });
      
    } catch (e) {
      Get.snackbar('Failure!','Could not cancel the request.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
    }
  }
  
  cancelAcceptedRequestUser(DocumentSnapshot ride, String userId) async{
  // String requestId = request!.id;
  int seat = 0;
  String maxSeats = "";
  List seatInformation = [];
   try {
    seatInformation = ride.get('max_seats').toString().split(' ');
    seat = int.parse(seatInformation[0]) + 1;
    maxSeats = seat == 1 ? '$seat seat' : '$seat seats';
    print(userId);
    String driverId = ride.get('driver');

    final fi = FirebaseFirestore.instance;
    final batch = fi.batch();
    CollectionReference requestReference = FirebaseFirestore.instance.collection('drivers').doc(driverId).collection('requests');

    // Query to find the document with a specific field value
    requestReference.where('user_id', isEqualTo: userId).
    where('ride_id', isEqualTo: ride.id).get().then((value){
      if (value.docs.isNotEmpty) {
      // Delete the document
      for (QueryDocumentSnapshot document in value.docs) {
        var di = requestReference.doc(document.id);
        batch.delete(di);
      }}
    }).catchError((e){
      Get.snackbar('Failure!','Could not cancel the request.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
      return;
    });
    
      var rideref = FirebaseFirestore.instance.collection('rides').doc(ride.id);
      batch.set(rideref, {
      'joined': FieldValue.arrayRemove([userId]),
      'max_seats': maxSeats,
      },SetOptions(merge: true));

      // batch.update(rideref, {'codes.$userId': FieldValue.delete(),
      // 'phones.$userId': FieldValue.delete()});

      batch.update(rideref, {'passengers.$userId': FieldValue.delete()});

      batch.commit().then((value) async {
         Get.snackbar('Success', 'Your request was canceled successfully.',
          colorText: Colors.white, backgroundColor: AppColors.purpleColor);
          try{
          DocumentSnapshot dr = await FirebaseFirestore.instance.collection('tokens').doc(ride.get('driver')).get();
          sendPushMessage("User cancelled a ride/request!", "Request cancelled", dr['token']);
        } catch(e){
        // cannot send message
        }    
      });
    } catch (e) {
      print('Failed to cancel to ride: $e');
      Get.snackbar('Failure!','Could not cancel the ride.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
    }
  }
  rejectAcceptedRequestDriver(DocumentSnapshot ride, DocumentSnapshot? request) async{
  // String requestId = request!.id;
  String driverId = ride.get('driver');
  String userId = request!.get('user_id');
  String requestId = request!.id;
  int seat = 0;
  String maxSeats = "";
  List seatInformation = [];
   try {
    seatInformation = ride.get('max_seats').toString().split(' ');
    seat = int.parse(seatInformation[0]) + 1;
    maxSeats = seat == 1 ? '$seat seat' : '$seat seats';
    print(userId);
    // String driverId = ride.get('driver');
    // CollectionReference collectionReference = FirebaseFirestore.instance.collection('users').doc(driverId).collection('requests');

    // Query to find the document with a specific field value
    final fi = FirebaseFirestore.instance;
    final batch = fi.batch();
    var reqref = FirebaseFirestore.instance.collection('drivers').doc(driverId)
          .collection('requests').doc(requestId);
    batch.set(reqref, {'status': 'Rejected'}, SetOptions(merge: true));

    var setref = FirebaseFirestore.instance.collection('rides').doc(ride.id);
    batch.set(setref, {'joined': FieldValue.arrayRemove([userId]),
      'max_seats': maxSeats,
      'rejected': FieldValue.arrayUnion([userId])}, SetOptions(merge: true));

    var updateref = FirebaseFirestore.instance.collection('rides').doc(ride.id);
    // batch.update(updateref, {'codes.$userId': FieldValue.delete(),
    //   'phones.$userId': FieldValue.delete()});

    batch.update(updateref, {'passengers.$userId': FieldValue.delete()});

      batch.commit().then((value) async {
        Get.snackbar('Success', 'Your ride was canceled successfully.',
          colorText: Colors.white, backgroundColor: AppColors.purpleColor);
          try{
          DocumentSnapshot ur = await FirebaseFirestore.instance.collection('tokens').doc(userId).get();
          sendPushMessage("Your request for ride at ${ride.get('start_time')} was cancelled!", "Request cancelled", ur['token']);
        } catch(e){
        // cannot send message
        }
      });
    } catch (e) {
      print('Failed to cancel to ride: $e');
      Get.snackbar('Failure!','Could not cancel the ride.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
    }
  }
  /// this method allows the driver to accept the request made by the user to join his ride
  acceptRequest(DocumentSnapshot ride, DocumentSnapshot? request) async {
    String driverId = ride.get('driver');
    String userId = request!.get('user_id');
    String requestId = request!.id;
    String phone = request!.get('mobile');
    int seat = 0;
    String maxSeats = "";
    //generate code and add to codes
    var rng = new Random();
    var code = rng.nextInt(9000) + 1000;

    List seatInformation = [];
    try {
      seatInformation = ride.get('max_seats').toString().split(' ');
      seat = int.parse(seatInformation[0]) - 1;
      maxSeats = seat == 1 ? '$seat seat' : '$seat seats';
    } catch (e) {
      print('exception');
      seatInformation = [];
    }
    try{pendingRequests.remove(userId);
    final fi = FirebaseFirestore.instance;
    final batch = fi.batch();
    var rideref = FirebaseFirestore.instance.collection('rides').doc(ride.id);

    batch.set(rideref, {
      'pending': FieldValue.arrayRemove([userId]),
      'joined': FieldValue.arrayUnion([userId]),
      'max_seats': maxSeats,
      // 'codes': {userId: code},
      // 'phones': {userId: phone},
      'passengers': {userId: {'phone': phone, 'code': code}}
    }, SetOptions(merge: true));

    var requref = FirebaseFirestore.instance.collection('drivers').doc(driverId).collection('requests').doc(requestId);
    batch.set(requref, {'status': 'Accepted'}, SetOptions(merge: true));

    batch.commit().then((value) async {
        Get.snackbar('Success', 'Request was accepted successfully.',
            colorText: Colors.white, backgroundColor: AppColors.purpleColor);
        updatePendingRequests();
        try{
          DocumentSnapshot ur = await FirebaseFirestore.instance.collection('tokens').doc(userId).get();
          sendPushMessage("Your request for ride at ${ride.get('start_time')} was accepted!", "Request accepted", ur['token']);
        } catch(e){
        // cannot send message
        }
      });
    }
    catch (e){
      Get.snackbar('Failure', 'Could not accept request.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
    }
  }

  /// this method allows the driver to reject the request made by the user to join his ride
  rejectRequest(DocumentSnapshot ride, DocumentSnapshot? request) async { 
    try{
    String driverId = ride.get('driver');
    String userId = request!.get('user_id');
    String requestId = request!.id;
    final fi = FirebaseFirestore.instance;
    final batch = fi.batch();
    var rideref = FirebaseFirestore.instance.collection('rides').doc(ride.id);
    batch.set(rideref, {
      'pending': FieldValue.arrayRemove([userId]),
      'rejected': FieldValue.arrayUnion([userId]),
    }, SetOptions(merge: true));

    var requestref = FirebaseFirestore.instance.collection('drivers').doc(driverId).collection('requests').doc(requestId);
    batch.set(requestref,{'status': 'Rejected'}, SetOptions(merge: true));

    batch.commit().then((value) async {
      Get.snackbar('Success', 'Request was rejected successfully.',
            colorText: Colors.white, backgroundColor: AppColors.purpleColor);

        isRequestLoading(false);
        updatePendingRequests();
        try{
          DocumentSnapshot ur = await FirebaseFirestore.instance.collection('tokens').doc(userId).get();
          sendPushMessage("Your request for ride at ${ride.get('start_time')} was rejected!", "Request rejected", ur['token']);
        } catch(e){
        // cannot send message
        }
    });
    // await FirebaseFirestore.instance.collection('rides').doc(ride.id).set({
    //   'pending': FieldValue.arrayRemove([userId]),
    //   'rejected': FieldValue.arrayUnion([userId]),
    // }, SetOptions(merge: true)).then((value) {
    //   FirebaseFirestore.instance
    //       .collection('users')
    //       .doc(driverId)
    //       .collection('requests')
    //       .doc(requestId)
    //       .set({'status': 'Rejected'}, SetOptions(merge: true)).then((value) {
    //     Get.snackbar('Success', 'Request was rejected successfully.',
    //         colorText: Colors.white, backgroundColor: AppColors.purpleColor);

    //     isRequestLoading(false);
    //     updatePendingRequests();
      // });
    // });
    }
    catch (e){
      Get.snackbar('Failure!','Could not reject the request.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
    }
  }

  /// this method is to add userId tho pickup array this shows that the users has rode the car with the driver
  pickedUp(String rideId, String userId) async {
    try {
      DocumentReference rideRef =
          FirebaseFirestore.instance.collection('rides').doc(rideId);
      rideRef.update({
        'picked_up': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print('Failed to add userId to picked_up array: $e');
    }
  }

  addReview(String reviewee, String reviewer, double stars, {update=false, collection='users'}){
  try {
    if(update){
      FirebaseFirestore.instance.collection(collection).doc(reviewee).update(
        {'reviews.$reviewer': stars}
      ).then((value){
        Get.snackbar('Success', 'Review updated successfully.',
          colorText: Colors.white, backgroundColor: AppColors.purpleColor);
      });
    }else{    FirebaseFirestore.instance.collection(collection).doc(reviewee).set(
      {'reviews': {reviewer: stars}}, SetOptions(merge: true)
      ).then((value){
          Get.snackbar('Success', 'Review added successfully.',
          colorText: Colors.white, backgroundColor: AppColors.purpleColor);
      });
    }
  } on Exception catch (e) {
  Get.snackbar('Failure', 'Could not complete the procedure.',
            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
  }
}
  /// this method find all rides with the sam destination and date given by user then arrange them from the nearest in distance to furthest
  void findAndArrangeRides(Map<String, dynamic> searchRideInfo) {
    DateTime dateTime = searchRideInfo['dateTime'];
    DateTime currentDateTime = DateTime.now();
    GeoPoint src = searchRideInfo['pickup_latlng'];
    if(!dateTime.isAfter(currentDateTime)){
      dateTime = currentDateTime.add(Duration(minutes: 5));
    }

    if(searchRideInfo['destination_address'] == null){
    List filteredRides = allRides.where((ride) {
      String rideDate = ride.get('date');
      String status = ride['status'];
      // String rideStatus = ride.get('status');
      String startTime = ride.get('start_time');
      // String rideSource = ride.get('pickup_address');
      GeoPoint rideSourceLat = ride.get('pickup_latlng');
      num ltDiff = src.latitude - rideSourceLat.latitude;
      num lnDiff = src.longitude - rideSourceLat.longitude;

      // Parse ride's date and start time
      DateTime rideDateTime =
          DateFormat('dd-MM-yyyy hh:mm a').parse('$rideDate $startTime');
      var seatInformation = ride.get('max_seats').toString().split(' ');
      int seat = int.parse(seatInformation[0]);
      return 
          // rideDate == date &&
          rideDateTime.isAfter(currentDateTime) &&
          status != 'Cancelled' &&
          ltDiff.abs() <= 0.003 &&
          lnDiff.abs() <= 0.003 &&
          // src == rideSourceLat &&
          rideDateTime.isAfter(dateTime) &&
          status != 'Ended' &&
          seat >= 1;
    }).toList();
    print(filteredRides.length);
    filteredAndArrangedRides.assignAll(filteredRides);
    }else{
      // String destinationAddress = searchRideInfo['destination_address'];
      GeoPoint des = searchRideInfo['destination_latlng'];
      List filteredRides = allRides.where((ride) {
      // String rideDestination = ride.get('destination_address');
      String rideDate = ride.get('date');
      String status = ride['status'];
      // String rideStatus = ride.get('status');
      String startTime = ride.get('start_time');
      GeoPoint rideSourceLat = ride.get('pickup_latlng');
      GeoPoint rideDestLat = ride.get('destination_latlng');

      num ltDiff = src.latitude - rideSourceLat.latitude;
      num lnDiff = src.longitude - rideSourceLat.longitude;
      num ltDiff2 = des.latitude - rideDestLat.latitude;
      num lnDiff2 = des.longitude - rideDestLat.longitude;

      // Parse ride's date and start time
      DateTime rideDateTime =
          DateFormat('dd-MM-yyyy hh:mm a').parse('$rideDate $startTime');
      var seatInformation = ride.get('max_seats').toString().split(' ');
      int seat = int.parse(seatInformation[0]);
      return 
          // rideDestLat == des &&
          ltDiff2.abs() <= 0.003 &&
          lnDiff2.abs() <= 0.003 &&
          // rideDate == date &&
          rideDateTime.isAfter(dateTime) &&
          // src == rideSourceLat &&
          ltDiff.abs() <= 0.003 &&
          lnDiff.abs() <= 0.003 &&
          status != 'Cancelled' &&
          status != 'Ended' &&
          seat >= 1;
    }).toList();
    // Sort the filtered rides based on proximity to the source location
    // filteredRides.sort((a, b) {
    //   double distanceA = calculateDistance(
    //       a.get('pickup_latlng'), searchRideInfo['pickup_latlng']);
    //   double distanceB = calculateDistance(
    //       b.get('pickup_latlng'), searchRideInfo['pickup_latlng']);
    //   return distanceA.compareTo(distanceB);
    // });
    print(filteredRides.length);
    filteredAndArrangedRides.assignAll(filteredRides);
    }
    
  }

  void findClosestRides(Map<String, dynamic> searchRideInfo) {
    DateTime dateTime = searchRideInfo['dateTime'];
    DateTime currentDateTime = DateTime.now();
    if(!dateTime.isAfter(currentDateTime)){
      dateTime = currentDateTime.add(Duration(minutes: 5));
    }
    GeoPoint src = searchRideInfo['pickup_latlng'];

      // String destinationAddress = searchRideInfo['destination_address'];
      GeoPoint des = searchRideInfo['destination_latlng'];
      List filteredRides = allRides.where((ride) {
      // String rideDestination = ride.get('destination_address');
      String rideDate = ride.get('date');
      String status = ride['status'];
      // String rideStatus = ride.get('status');
      String startTime = ride.get('start_time');
      GeoPoint rideSourceLat = ride.get('pickup_latlng');
      GeoPoint rideDestLat = ride.get('destination_latlng');

      num ltDiff = src.latitude - rideSourceLat.latitude;
      num lnDiff = src.longitude - rideSourceLat.longitude;
      num ltDiff2 = des.latitude - rideDestLat.latitude;
      num lnDiff2 = des.longitude - rideDestLat.longitude;

      // Parse ride's date and start time
      DateTime rideDateTime =
          DateFormat('dd-MM-yyyy hh:mm a').parse('$rideDate $startTime');
      
      double srcDist = calculateDistance(src, rideSourceLat);
      // print(srcDist);
      double destDist = calculateDistance(des, rideDestLat);
      // print(destDist + srcDist);
      return 
          srcDist + destDist <= 1.6 &&
          // destDist <= 1.0 &&
          // rideDate == date &&
          rideDateTime.isAfter(dateTime) &&
          (ltDiff > 0.003 || ltDiff2 > 0.003 || lnDiff > 0.003 || lnDiff2 > 0.003) &&
          status != 'Cancelled' &&
          status != 'Ended';
    }).toList();
    // Sort the filtered rides based on proximity to the source location
    filteredRides.sort((a, b) {
      double distanceA = calculateDistance(src, a.get('pickup_latlng')) + calculateDistance(des, a.get('destination_latlng'));
      double distanceB = calculateDistance(src, b.get('pickup_latlng')) + calculateDistance(des, b.get('destination_latlng'));
      return distanceA.compareTo(distanceB);
    });
    print(filteredRides.length);

    closestRides.assignAll(filteredRides);
    
  }

  double calculateDistance(GeoPoint location, GeoPoint sourceLatLng) {
    const int earthRadius = 6371; // Radius of the Earth in kilometers

    double lat1 = location.latitude;
    double lon1 = location.longitude;

    double lat2 = sourceLatLng.latitude;
    double lon2 = sourceLatLng.longitude;

    // Calculate the differences between the latitudes and longitudes
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    // Apply the Haversine formula
    double a = pow(sin(dLat / 2), 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance; // Return the calculated distance
  }

  double _toRadians(double degree) {
    return degree * pi / 180; // Convert degree to radians
  }

  // Getters
  getMyDocument() async {
    var isDriver = await CacheHelper.getData(key: AppConstants.decisionKey) ?? false;
    // print(a);
    String collection = isDriver ? 'drivers': 'users';
    FirebaseFirestore.instance
          .collection(collection)
          .doc(auth.currentUser!.uid)
          .snapshots()
          .listen((event) {
            myDocument = event;
          });
    // CacheHelper.getData(key: AppConstants.decisionKey).then(
    //   (val){
    //     String collection = 'users';
    //     if(val){
    //       collection = 'drivers';
    //     }
    //     FirebaseFirestore.instance
    //       .collection(collection)
    //       .doc(auth.currentUser!.uid)
    //       .snapshots()
    //       .listen((event) {
    //         myDocument = event;
    //       });
    //   }
    // ).catchError((e){
    //   print(e);
    // });
    // FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(auth.currentUser!.uid)
    //     .snapshots()
    //     .listen((event) {
    //   myDocument = event;
    // });
  }

  ///this method is getting all Users from the database and store inside allUsers list
  getUsers() {
    isUsersLoading(true);
    FirebaseFirestore.instance.collection('users').snapshots().listen((event) {
      allUsers.assignAll(event.docs);
      isUsersLoading(false);
    });
    FirebaseFirestore.instance.collection('drivers').snapshots().listen((event) {
      allUsers.addAll(event.docs);
      isUsersLoading(false);
    });
  }

  ///this method is getting all Rides from the database and store inside allRides list
  getRides() {
    isRidesLoading(true);
    FirebaseFirestore.instance.collection('rides').snapshots().listen((event) {
      allRides.assignAll(event.docs);
      isRidesLoading(false);
    });
  }

  ///this method is getting all rides Created by Specific Driver from the database and store inside RidesICreated list
  getRidesICreated() {
    ridesICreated.assignAll(allRides.where((e) {
      String driverId = e.get('driver');
      String status = e.get('status');

      return driverId.contains(FirebaseAuth.instance.currentUser!.uid) &&
          status == 'Upcoming';
    }).toList());
  }

  ///this method gets length of joined array in ride entity
  getJoinedArrayLength(String rideId) async {
    final rideSnapshot =
        await FirebaseFirestore.instance.collection('rides').doc(rideId).get();

    if (rideSnapshot.exists && rideSnapshot.data() != null) {
      final joinedArray = rideSnapshot.data()!['joined'] as List<dynamic>;
      return joinedArray.length;
    }

    return 0; // Default value if the 'joined' array doesn't exist or ride doesn't exist
  }

  getJoinedArray(String rideId) async {
    print('here');
    final rideSnapshot =
        await FirebaseFirestore.instance.collection('rides').doc(rideId).get();

    if (rideSnapshot.exists && rideSnapshot.data() != null) {
      final joinedArray = await rideSnapshot.data()!['joined'] as List<dynamic>;
      return joinedArray;
    }
  }

  getPickedArray(String rideId) async {
    final rideSnapshot =
        await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
    print('length');
    // print(rideSnapshot.get('picked_up').length);
    // return rideSnapshot.get('picked_up');

    if (rideSnapshot.exists && rideSnapshot.data() != null) {
      final pickedArray = rideSnapshot.data()!['picked_up'] as List<dynamic>;
      return pickedArray;
    }
  }

  /// this method gets the current ride for the driver
  getOngoingRideForDriver() async {
    DateTime currentDate = DateTime.now();
    DateTime previous30Minutes = currentDate.subtract(Duration(minutes: 30));
    DateTime next30Minutes = currentDate.add(Duration(minutes: 30));

    List tempArray = allRides.where((ride) {
    String driverId = ride['driver'];
    String status = ride['status'];
    DateTime rideDate = DateFormat('dd-MM-yyyy').parse(ride['date']);
    DateTime startTime = DateFormat('hh:mm a').parse(ride['start_time']);
    List<dynamic> pickedUp = ride.get('picked_up');

      // Combine date and time for comparison
    DateTime rideDateTime = DateTime(
        rideDate.year,
        rideDate.month,
        rideDate.day,
        startTime.hour,
        startTime.minute,
      );

      // Filter rides that occur within 30 minutes before and 3 hours after the current date and time
    return driverId == FirebaseAuth.instance.currentUser!.uid && 
          // !pickedUp.isEmpty &&
          rideDateTime.isAfter(previous30Minutes) &&
          (pickedUp.isNotEmpty || rideDateTime.isBefore(next30Minutes))&&
          (status == 'Upcoming' || status == 'Started' );
          // status != 'Cancelled' &&
          // status != 'Ended' &&
          // status != 'Started';
    }).toList();

    // Assign filtered rides to currentRide array
    print(tempArray.length);
    print(FirebaseAuth.instance.currentUser!.uid);
    driverCurrentRide.assignAll(tempArray);
  }

  /// this method get all rides with still active date and arrange them from the nearest date to the furthest for driver
  getUpcomingRidesForDriver() {
    DateTime currentDate = DateTime.now();
    DateTime next3Hours = currentDate.add(Duration(hours: 3, minutes: 1)); // Get the next 5 hours from the current date

    List tempArray = ridesICreated.where((ride) {
      String driverId = ride['driver'];
      String status = ride['status'];
      DateTime rideDate = DateFormat('dd-MM-yyyy').parse(ride['date']);
      DateTime startTime = DateFormat('hh:mm a').parse(ride['start_time']);
      List<dynamic> pickedUp = ride.get('picked_up');

      // Combine date and time for comparison
      DateTime rideDateTime = DateTime(
        rideDate.year,
        rideDate.month,
        rideDate.day,
        startTime.hour,
        startTime.minute,
      );

      // Filter rides that occur after the next 5 hours from the current date
      return driverId.contains(FirebaseAuth.instance.currentUser!.uid) &&
          rideDateTime.isBefore(next3Hours) && rideDateTime.isAfter(currentDate) &&
          status != 'Cancelled' &&
          status != 'Ended';
          // pickedUp.isEmpty;
    }).toList();

    // Sort rides by nearest date and time
    tempArray.sort((a, b) {
      DateTime rideDateTimeA = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(a['date'] + ' ' + a['start_time']);
      DateTime rideDateTimeB = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(b['date'] + ' ' + b['start_time']);
      return rideDateTimeA.compareTo(rideDateTimeB);
    });

    // Assign sorted rides to activeRides array
    upcomingRidesForDriver.assignAll(tempArray);
  }
  getFutureRidesForDriver() {
    DateTime currentDate = DateTime.now();
    DateTime next3Hours = currentDate.add(Duration(hours: 3, minutes: 1)); // Get the next 5 hours from the current date

    List tempArray = ridesICreated.where((ride) {
      String driverId = ride['driver'];
      String status = ride['status'];
      DateTime rideDate = DateFormat('dd-MM-yyyy').parse(ride['date']);
      DateTime startTime = DateFormat('hh:mm a').parse(ride['start_time']);
      List<dynamic> pickedUp = ride.get('picked_up');

      // Combine date and time for comparison
      DateTime rideDateTime = DateTime(
        rideDate.year,
        rideDate.month,
        rideDate.day,
        startTime.hour,
        startTime.minute,
      );

      // Filter rides that occur after the next 5 hours from the current date
      return driverId.contains(FirebaseAuth.instance.currentUser!.uid) &&
          rideDateTime.isAfter(next3Hours) &&
          status != 'Cancelled' &&
          status != 'Ended';
          // pickedUp.isEmpty;
    }).toList();

    // Sort rides by nearest date and time
    tempArray.sort((a, b) {
      DateTime rideDateTimeA = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(a['date'] + ' ' + a['start_time']);
      DateTime rideDateTimeB = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(b['date'] + ' ' + b['start_time']);
      return rideDateTimeA.compareTo(rideDateTimeB);
    });

    // Assign sorted rides to activeRides array
    futureRidesForDriver.assignAll(tempArray);
  }

  /// this method get all rides that was ended or cancelled by driver and arrange them from the nearest date to the furthest for driver
  getRideHistoryForDriver() {
    List tempArray = ridesIEnded.where((ride) {
      String driverId = ride['driver'];

      // Filter rides that have already occurred
      return driverId.contains(FirebaseAuth.instance.currentUser!.uid);
    }).toList();

    // Concatenate the canceled rides to the temporary array
    tempArray.addAll(ridesICancelled);

    // Sort rides by nearest date and time
    tempArray.sort((b, a) {
      DateTime rideDateTimeA = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(a['date'] + ' ' + a['start_time']);
      DateTime rideDateTimeB = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(b['date'] + ' ' + b['start_time']);
      return rideDateTimeA.compareTo(rideDateTimeB);
    });

    // Assign sorted rides to endedRides array
    driverHistory.assignAll(tempArray);
  }

  /// this method gets the current ride for the user
  getOngoingRideForUser() {
    //TODO change to accepted array
    List tempArray = ridesIJoined.where((ride) {
      // List<dynamic> joinedUsers = ride['joined'];
      List<dynamic> pickedUsers = ride['picked_up'];
      String status = ride['status'];

      return pickedUsers.contains(FirebaseAuth.instance.currentUser!.uid) &&
              status != 'Ended';
    }).toList();

    // Assign filtered rides to currentRide array
    userCurrentRide.assignAll(tempArray);
  }

  /// this method get all rides with still active date and arrange them from the nearest date to the furthest for user
  getUpcomingRidesForUser() {
    DateTime currentDate = DateTime.now();
    DateTime next3Hours = currentDate.add(Duration(hours: 3, minutes: 1));

    List tempArray = ridesIJoined.where((ride) {
      List<dynamic> joinedUsers = ride['joined'];
      List<dynamic> pickedUsers = ride['picked_up'];
      String status = ride['status'];
      DateTime rideDate = DateFormat('dd-MM-yyyy').parse(ride['date']);
      DateTime startTime = DateFormat('hh:mm a').parse(ride['start_time']);

      // Combine date and time for comparison
      DateTime rideDateTime = DateTime(
        rideDate.year,
        rideDate.month,
        rideDate.day,
        startTime.hour,
        startTime.minute,
      );

      // Filter rides that occur within the next 4 hours and have the user in the joined list
      return joinedUsers.contains(FirebaseAuth.instance.currentUser!.uid) &&
          rideDateTime.isBefore(next3Hours) && rideDateTime.isAfter(currentDate) && 
          (status == 'Upcoming' && 
          !pickedUsers.contains(FirebaseAuth.instance.currentUser!.uid)) || (status == 'Ongoing' && 
          pickedUsers.contains(FirebaseAuth.instance.currentUser!.uid)); // and not in picked up
    }).toList();

    // Sort rides by nearest date and time
    tempArray.sort((a, b) {
      DateTime rideDateTimeA = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(a['date'] + ' ' + a['start_time']);
      DateTime rideDateTimeB = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(b['date'] + ' ' + b['start_time']);
      return rideDateTimeA.compareTo(rideDateTimeB);
    });

    // Assign filtered rides to upcomingRides array
    upcomingRidesForUser.assignAll(tempArray);
  }

  getFutureRidesForUser() {
    DateTime currentDate = DateTime.now();
    DateTime next3Hours = currentDate.add(Duration(hours: 3, minutes: 1));

    List tempArray = ridesIJoined.where((ride) {
      List<dynamic> joinedUsers = ride['joined'];
      List<dynamic> pickedUsers = ride['picked_up'];
      String status = ride['status'];
      DateTime rideDate = DateFormat('dd-MM-yyyy').parse(ride['date']);
      DateTime startTime = DateFormat('hh:mm a').parse(ride['start_time']);

      // Combine date and time for comparison
      DateTime rideDateTime = DateTime(
        rideDate.year,
        rideDate.month,
        rideDate.day,
        startTime.hour,
        startTime.minute,
      );

      // Filter rides that occur within the next 4 hours and have the user in the joined list
      return joinedUsers.contains(FirebaseAuth.instance.currentUser!.uid) &&
          rideDateTime.isAfter(next3Hours) && 
          status == 'Upcoming' && 
          !pickedUsers.contains(FirebaseAuth.instance.currentUser!.uid); // and not in picked up
    }).toList();

    // Sort rides by nearest date and time
    tempArray.sort((a, b) {
      DateTime rideDateTimeA = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(a['date'] + ' ' + a['start_time']);
      DateTime rideDateTimeB = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(b['date'] + ' ' + b['start_time']);
      return rideDateTimeA.compareTo(rideDateTimeB);
    });

    // Assign filtered rides to upcomingRides array
    futureRidesForUser.assignAll(tempArray);
  }

  getAllPendingRide(){
    isRidesLoading(true);
    FirebaseFirestore.instance.collection('rides').where('pending', arrayContains: FirebaseAuth.instance.currentUser!.uid).snapshots().listen((event) {
      allPendingRidesForUser.assignAll(event.docs);
      isRidesLoading(false);
    });
  }
  getRequestedRidesForUser(){
    print("hell");
    DateTime currentDate = DateTime.now();
    DateTime next3Hours = currentDate.add(Duration(hours: 3, minutes: 1));

    // print(allPendingRidesForUser);

    List tempArray = allPendingRidesForUser.where((ride) {
      // List<dynamic> joinedUsers = ride['joined'];
      List<dynamic> pendingUsers = ride['pending'];
      String status = ride['status'];
      DateTime rideDate = DateFormat('dd-MM-yyyy').parse(ride['date']);
      DateTime startTime = DateFormat('hh:mm a').parse(ride['start_time']);

      // Combine date and time for comparison
      DateTime rideDateTime = DateTime(
        rideDate.year,
        rideDate.month,
        rideDate.day,
        startTime.hour,
        startTime.minute,
      );

      // Filter rides that occur within the next 4 hours and have the user in the joined list
      return pendingUsers.contains(FirebaseAuth.instance.currentUser!.uid) &&
           rideDateTime.isAfter(currentDate) &&
          status == 'Upcoming';
    }).toList();

    // print(tempArray[0]);

    // Sort rides by nearest date and time
    tempArray.sort((a, b) {
      DateTime rideDateTimeA = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(a['date'] + ' ' + a['start_time']);
      DateTime rideDateTimeB = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(b['date'] + ' ' + b['start_time']);
      return rideDateTimeA.compareTo(rideDateTimeB);
    });

    // Assign filtered rides to upcomingRides array
    requestedRidesForUser.assignAll(tempArray);
  }
  /// this method get all rides that was ended or cancelled by driver and arrange them from the nearest date to the furthest for user
  getRideHistoryForUser() {
    DateTime currentDate = DateTime.now();

    List tempArray = ridesIJoined.where((ride) {
      List<dynamic> joinedUsers = ride['joined'];
      String status = ride['status'];
      DateTime rideDate = DateFormat('dd-MM-yyyy').parse(ride['date']);
      DateTime startTime = DateFormat('hh:mm a').parse(ride['start_time']);

      // Combine date and time for comparison
      DateTime rideDateTime = DateTime(
        rideDate.year,
        rideDate.month,
        rideDate.day,
        startTime.hour,
        startTime.minute,
      );

      // Filter rides that have already occurred
      return joinedUsers.contains(FirebaseAuth.instance.currentUser!.uid) &&
          (status == 'Ended' ||
              status == 'Cancelled' ||
              rideDateTime.isBefore(currentDate));
    }).toList();

    // Sort rides by nearest date and time
    tempArray.sort((b, a) {
      DateTime rideDateTimeA = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(a['date'] + ' ' + a['start_time']);
      DateTime rideDateTimeB = DateFormat('dd-MM-yyyy hh:mm a')
          .parse(b['date'] + ' ' + b['start_time']);
      return rideDateTimeA.compareTo(rideDateTimeB);
    });

    // Assign sorted rides to endedRides array
    userHistory.assignAll(tempArray);
  }

  /// this method gets all cancelled rides by driver
  getRidesICancelled() {
    ridesICancelled.assignAll(allRides.where((e) {
      String driverId = e.get('driver');
      String status = e.get('status');

      return driverId.contains(FirebaseAuth.instance.currentUser!.uid) &&
          status == 'Cancelled';
    }).toList());
  }

  /// this method gets all rides a user joined
  getRidesIJoined() {
    ridesIJoined.assignAll(allRides.where((e) {
      List joinedIds = e.get('joined');

      return joinedIds.contains(FirebaseAuth.instance.currentUser!.uid);
    }).toList());
  }

  /// this method gets all rides that a driver has ended after making it
  getRidesIEnded() {
    ridesIEnded.assignAll(allRides.where((e) {
      String driverId = e.get('driver');
      String status = e.get('status');

      return driverId.contains(FirebaseAuth.instance.currentUser!.uid) &&
          status == 'Ended';
    }).toList());
  }

  /// this method to get all requests sent to driver by the users to join his rides
  getMyRequests() {
    isRequestLoading(true);
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('requests')
        .snapshots()
        .listen((event) {
      myRequests.value = event.docs;
      isRequestLoading(false);
    });
  }

  /// this method gets all users who joined a specific ride
  getAcceptedUserForRide(String rideId) async {
    String currentDriverId = FirebaseAuth.instance.currentUser!.uid;
    List<String> userIds = [];

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('drivers')
        .doc(currentDriverId)
        .collection('requests')
        .where('ride_id', isEqualTo: rideId)
        .where('status', isEqualTo: 'Accepted')
        .get();

    for (QueryDocumentSnapshot<Map<String, dynamic>> document
        in querySnapshot.docs) {
      userIds.add(document.data()['user_id']);
    }

    List<DocumentSnapshot<Map<String, dynamic>>> userSnapshots =
        []; // Create a local list

    for (String userId in userIds) {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (userSnapshot.exists) {
        userSnapshots.add(userSnapshot);
      }
    }

    // Update the userSnapshots in the RideController instance
    this.userSnapshots.assignAll(userSnapshots);
  }

  /// this method gets all pending requests that the driver is yet to accept or reject
  getPendingRequests() {
    pendingRequests.assignAll(myRequests.where((e) {
      String status = e.get('status');

      return status == 'Pending';
    }).toList());

    pendingRequests.sort((b, a) {
      return a['date_time'].compareTo(b['date_time']);
    });
  }

  /// this method gets all requests accepted by the driver
  getAcceptedRequests() {
    acceptedRequests.assignAll(myRequests.where((e) {
      String status = e.get('status');

      return status == 'Accepted';
    }).toList());

    acceptedRequests.sort((b, a) {
      return a['date_time'].compareTo(b['date_time']);
    });
  }

  /// this method gets all requests rejected by the driver
  getRejectedRequests() {
    rejectedRequests.assignAll(myRequests.where((e) {
      String status = e.get('status');

      return status == 'Rejected';
    }).toList());

    rejectedRequests.sort((b, a) {
      return a['date_time'].compareTo(b['date_time']);
    });
  }

    // Updaters
  updateOngoingDriverRide() {
    getOngoingRideForDriver();
  }

  updateOngoingUserRide() {
    getOngoingRideForUser();
  }

  updateUpcomingUserRide() {
    getUpcomingRidesForUser();
  }

  updateUpcomingDriverRide() {
    getUpcomingRidesForDriver();
  }

  updateHistoryUserRide() {
    getRideHistoryForUser();
  }

  updateHistoryDriverRide() {
    getRideHistoryForDriver();
  }

  updatePendingRequests() {
    getPendingRequests();
  }

  updateAcceptedRequests(){
    getAcceptedRequests();
  }

  updateRequestedRides(){
    getRequestedRidesForUser();
  }

  void sendPushMessage(String body, String title, String token) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=FIREBASEE_MESSAGE_KEY',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'body': body,
              'title': title,
            },
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
            },
            "to": token,
          },
        ),
      );
    } catch (e) {
      // error
    }
  }
}
