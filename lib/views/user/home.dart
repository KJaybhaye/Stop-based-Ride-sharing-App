import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:project/controller/auth_controller.dart';
import 'package:project/controller/location_handler.dart';
import 'package:project/controller/polyline_handler.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/utils/app_constants.dart';
import 'package:project/views/support_view_user.dart';
import 'package:project/views/user/my_profile.dart';
import 'package:project/views/user/nearest_rides_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geocoding/geocoding.dart' as geoCoding;
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

import '../../controller/ride_controller.dart';
import '../../widgets/purple_button.dart';
import '../../widgets/icon_title_widget.dart';
import '../decision_screens/decision_screen.dart';
import '../my_rides.dart';
import 'package:project/models/stops.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _mapStyle;
  DateTime? date = DateTime.now();

  AuthController authController = Get.find<AuthController>();
  RideController rideController = Get.find<RideController>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late GeoPoint destination;
  late GeoPoint source;
  late LatLng search;
  final Set<Polyline> _polyline = {};
  LatLng country = LatLng(18.516726, 73.856255);
  
  LatLng imploc = LatLng(200,200);
  LatLng currentLocation = LatLng(200,200);

  // saving all the markers that will be showing on the map and store them in this set
  Set<Marker> markers = Set<Marker>();

  String? mtoken = '';
  var flutterLocalNotificationsPlugin;
  var channel;
  
void getCurrentLocation({bool updateMarker=false}) async {
    onSuccess(LatLng value){
      if(!updateMarker){
      setState(() {
      currentLocation = value;});
      }else{
        setState(() {
        currentLocation = value;});
        moveicon(value);
        updateMarkers(value);
      }
    }

    onError(e){
      if(currentLocation != imploc){
        moveicon(currentLocation);
        updateMarkers(currentLocation);
      }else if(authController.myUser.value.city_address != null){
          moveicon(authController.myUser.value.city_address!);
          updateMarkers(authController.myUser.value.city_address!);
      }
    }
    LocationHandler.determinePosition().then(onSuccess).catchError(onError);
  }

void updateMarkers(loc) async{
try {
  List<Map<String, dynamic>> stops = await getNearbyBusStops(loc.latitude, loc.longitude);
setState(() {
        // markers = Set<Marker>.from(stops.map((s) => BusStop.fromJson(s)).map((busStop){
        markers = Set<Marker>.from(stops.map((busStop){
        return Marker(
            markerId: MarkerId(busStop['name']),
            position: LatLng(busStop['geometry']['location']['lat'],busStop['geometry']['location']['lng']),
            infoWindow: InfoWindow(
              title: busStop['name'],
              snippet: 'Click to view details',
              onTap: () {
                // Handle marker tap here
                busStopDetails(busStop);
              },
            ),
          );
      })
      );
      });
} catch (e) {
  print(e);
}

}


void moveicon(LatLng loc, {double zoom = 17.0}){
  myMapController!.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(target: loc, zoom: zoom)));
}
void busStopDetails(Map<String, dynamic> stop) {
    setState(() {
      // selectedStop = BusStop(name: stop['name'], location: LatLng(stop['geometry']['location']['lat'], stop['geometry']['location']['lng']));
      selectedStopLoc = GeoPoint(stop['geometry']['location']['lat'], stop['geometry']['location']['lng']);
      selectedStopName = stop['name'];
      showStop = true;
    });

    print(stop['name']);
  }

Future<List<Map<String, dynamic>>> getNearbyBusStops(double lat, double lng) async {
    // var url = Uri.https('maps.googleapis.com','/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=1000&type=bus_station&key=$AppConstants.kGoogleApiKey');
    var url = Uri.https('maps.googleapis.com','/maps/api/place/nearbysearch/json',
    {'location':'$lat,$lng','radius':'1000','types':'transit_station','key': AppConstants.mapkey});
    print(url);
// var response = await http.post(url, body: {'name': 'doodle', 'color': 'blue'});
    final response = await http.get(url);
    print(response.statusCode);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final List<dynamic> results = data['results'];
        return results.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error: ${data['status']} - ${data['error_message']}');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  void getToken() async {
    FirebaseMessaging.instance.getToken().then((token) async {
      setState(() {
        mtoken = token;
      });
      await FirebaseFirestore.instance.collection('tokens')
      .doc(FirebaseAuth.instance.currentUser!.uid).set({
        'token': token
      });
    });
  }

  void requestPermission() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

   void loadFCM() async {
    if (!kIsWeb) {
      channel = const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        importance: Importance.high,
        enableVibration: true,
      );

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void listenFCM() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              icon: 'launch_background',
            ),
          ),
        );
      }
    });
  }
  
  @override
  void initState() {
    super.initState();

    authController.getUserInfo();
    rideController.getMyDocument();

    rootBundle.loadString('assets/map_style.txt').then((string) {
      _mapStyle = string;
    });

    _kGooglePlex = CameraPosition(
      target: country,
      zoom: 10.0);
    
    getCurrentLocation(updateMarker: true);
    loadCustomMarker();

    dateController.text = '${date!.day}-${date!.month}-${date!.year}';

    requestPermission();
    getToken();
    loadFCM();
    listenFCM();
  }


  
  CameraPosition? _kGooglePlex;

  GoogleMapController? myMapController;
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: buildProfileTitle(),
        backgroundColor: Colors.white70,
        iconTheme: IconThemeData(color: Colors.black),
        titleSpacing: 0,
      ),
      key : _key,
      drawer: buildDrawer(),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: GoogleMap(
              // markers: markers,
              polylines: _polyline,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                myMapController = controller;
                myMapController!.setMapStyle(_mapStyle);
              },
              initialCameraPosition: _kGooglePlex!,
              markers: markers,
              mapToolbarEnabled: false
            ),
          ),
          // buildProfileTitle(),
          // buildTextField(),
          Column(
            children: [
              buildSearchField(),
              showSourceField ? buildTextFieldForSource() : Container(),
              showDestField ? buildTextField() : Container(),
              sourceSelected && destSelected && showSearchButton ? buildSearchButton() : Container(),
            ],
          ),
          showStop ? buildStop() : Container(),
          Positioned(
            bottom: Get.width *0.01,
            left: 10,
            child:Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              showDateButton ? buildDateTimeField() : Container(),
              buildDateTimeButton(),
            ],
          )),
          buildCurrentLocationIcon(),
        ],
      ),
    );
  }

  Widget buildStop(){
    return Positioned(
      bottom: Get.height * 0.13,
      left: 20,
      child: Container(
        width: Get.width,
        child: Column(
          children: [
            Text('Bustop Name: ${selectedStopName}',
            style: TextStyle(
              color: Colors.black,
              backgroundColor: Colors.greenAccent,
              fontWeight: FontWeight.w900
            )),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    customButton("Add as source  ", (){
                  if(destSelected){
                  if(destination == selectedStopLoc){
                          Get.snackbar('Failure', 'Source and Destination cannot be same.',
                          colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
                          return;
                  }
                  }
                  source  = selectedStopLoc!;
                  sourceController.text = selectedStopName!;
                  setState(() {
                    showStop = false;
                    showSourceField = true;
                    showSearchButton = true;
                    sourceSelected = true;
                  });
                }, color: AppColors.purpleColor),
                const SizedBox(height: 4),
                customButton("Rides from here", (){
                 DateTime selectedDateTime = DateTime(date!.year, date!.month, date!.day, 
                startTime.hour, startTime.minute,);
                  Map<String, dynamic> searchRideInfo = {
                  'pickup_address': selectedStopName,
                  // 'destination_address': destinationController.text,
                  'dateTime': selectedDateTime,
                  'pickup_latlng': selectedStopLoc,
                  // 'destination_latlng':
                  //     GeoPoint(destination!.latitude, destination!.longitude),
                };
                rideController.findAndArrangeRides(searchRideInfo);
                resetControllers();
                Get.to(() => NearestRidePage(
                      rideController: rideController,
                    ));
                }, color: AppColors.purpleColor),
                  ],
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customButton("Add as Destination", (){
                  if(sourceSelected){
                  if(source == selectedStopLoc){
                          Get.snackbar('Failure', 'Source and Destination cannot be same.',
                          colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
                          return;
                  }
                  }
                  destination = selectedStopLoc!;
                  destinationController.text = selectedStopName!;
                  setState(() {
                    showStop = false;
                    showDestField = true;
                    showSearchButton = true;
                    destSelected = true;
                  });
                }, color: AppColors.purpleColor),
                const SizedBox(height: 4),
                customButton("Back", (){
                  setState(() {
                    showStop = false;
                  });
                }, color: AppColors.purpleColor),
                  ],
                )
              ],
            ),
          ],
        ),
      ));
  }
  Widget buildProfileTitle() {
    return Container(
      // top: 0,
      // left: 0,
      // right: 0,
      child: Obx(() => authController.myUser.value.name == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              // width: Get.width,
              // height: Get.width * 0.27,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              // decoration: BoxDecoration(color: Colors.white70),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: authController.myUser.value.image == null
                            ? DecorationImage(
                                image: AssetImage('assets/person.png'),
                                fit: BoxFit.fill)
                            : DecorationImage(
                                image: NetworkImage(
                                    authController.myUser.value.image!),
                                fit: BoxFit.fill)),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: 'Welcome back, ',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14)),
                          TextSpan(
                              text: authController.myUser.value.name?.substring(
                                  0,
                                  authController.myUser.value.name
                                      ?.indexOf(' ')),
                              style: TextStyle(
                                  color: Colors.purple,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ),
                      Text(
                        "Where are you going?",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      )
                    ],
                  )
                ],
              ),
            )),
    );
  }

  TextEditingController destinationController = TextEditingController();
  TextEditingController sourceController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();
  TimeOfDay startTime = TimeOfDay(hour: 0, minute: 0);
  bool showSourceField = false;
  bool showDestField = false;
  bool showSearchButton = false;
  bool showDateButton = false;
  bool showRideButton = false;
  bool showStop = false;
  bool sourceSelected = false;
  bool destSelected = false;

  GeoPoint? selectedStopLoc;
  String? selectedStopName;
  // late BusStop selectedStop = BusStop(name: 'name', location: LatLng(18.3, 37.5));

  Widget buildSearchField() {
    return Container(
        height: 35,
        padding: EdgeInsets.only(left: 15, top: 15),
        margin: EdgeInsets.only(top:5, left: 10, right: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 4,
                  blurRadius: 10)
            ],
            borderRadius: BorderRadius.circular(8)),
        child: TextFormField(
          controller: searchController,
          readOnly: true,
          onTap: () async {
            Prediction? p =
                await authController.showGoogleAutoComplete(context);

            String selectedPlace = p!.description!;
            searchController.text = selectedPlace;
            List<geoCoding.Location> locations =
                await geoCoding.locationFromAddress(selectedPlace);
            search =
                LatLng(locations.first.latitude, locations.first.longitude);

            moveicon(search, zoom: 16.0);
            updateMarkers(search);
          },
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'Search for a place.',
            hintStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            border: InputBorder.none,
          ),
        ),
      );
  }

  // Widget for destination field
  Widget buildTextField() {
    return Container(
        width: Get.width,
        // height: 44,
        margin: EdgeInsets.only(top:0, left: 10,),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: Get.width*0.80,
               padding: EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 4,
                  blurRadius: 10)
            ],
            borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              'To: ${destinationController.text}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black
            ),
          ),
        ),
    ),
    IconButton(onPressed: (){
        setState(() {
          destSelected = false;
          showDestField = false;
        });
      }, icon: Icon(Icons.close))
    ],
    )
    );
  }

  // Widget for Source field
  Widget buildTextFieldForSource() {
    return Container(
        width: Get.width,
        margin: EdgeInsets.only(top:0, left: 10,),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: Get.width*0.80,
              padding: EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 4,
                  blurRadius: 10)
            ],
            borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            'From : ${sourceController.text}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black, // 0xffA7A7A7
            )
          ),
        ),
    ),
    IconButton(onPressed: (){
        setState(() {
          sourceSelected = false;
          showSourceField = false;
        });
      }, icon: Icon(Icons.close),)
    ])
    );
  }

  Widget buildCurrentLocationIcon() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30, right: 15),
        child: InkWell(
          onTap: () {
            getCurrentLocation(updateMarker: true);
          },
          child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.purple,
          child: Icon(Icons.my_location, color: Colors.white),
        ),
      ),
    ));
  }

  Widget buildDateTimeField() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          iconTitleContainer(
            isReadOnly: true,
            path: 'assets/date.png',
            text: 'Date',
            height: 30,
            width: 140,
            controller: dateController,
            validator: (input) {
              if (date == null) {
                Get.snackbar('Warning', "Date is required.",
                    colorText: Colors.white,
                    backgroundColor: AppColors.purpleColor);
                return '';
              }
              return null;
            },
            onPress: () {
              _selectDate(context);
            },
          ),
          iconTitleContainer(
              path: 'assets/time.png',
              text: 'Start Time',
              controller: startTimeController,
              isReadOnly: true,
              width: 140,
              height: 30,
              validator: (input) {  
                if (input.isEmpty) {
                  Get.snackbar('Warning', "Time is required.",
                      colorText: Colors.white,
                      backgroundColor: AppColors.purpleColor);
                  return '';
                }
                return null;
              },
              onPress: () {
                startTimeMethod(context);
              }),
        ],
      ),
    );
  }

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.day,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      date = DateTime(picked.year, picked.month, picked.day, date!.hour,
          date!.minute, date!.second);
      dateController.text = '${date!.day}-${date!.month}-${date!.year}';
    }
    if (mounted) setState(() {});
  }

 Widget buildSearchButton() {
    return Container(
        width: Get.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[ Obx(
          () => rideController.isRideUploading.value
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : customButton('Search', () {
                
                DateTime selectedDateTime = DateTime(date!.year, date!.month, date!.day, 
                startTime.hour, startTime.minute,);
                  if(destSelected){
                  Map<String, dynamic> searchRideInfo = {
                    'pickup_address': sourceController.text,
                    'destination_address': destinationController.text,
                    'dateTime': selectedDateTime,
                    'pickup_latlng': GeoPoint(source!.latitude, source.longitude),
                    'destination_latlng':
                        GeoPoint(destination!.latitude, destination!.longitude),
                  };
      
                  rideController.findAndArrangeRides(searchRideInfo);
                  rideController.findClosestRides(searchRideInfo);
      
                  resetControllers();
                  Get.to(() => NearestRidePage(
                        rideController: rideController,
                      ));
                }else{
                  Map<String, dynamic> searchRideInfo = {
                    'pickup_address': sourceController.text,
                    // 'destination_address': destinationController.text,
                    'dateTime': selectedDateTime,
                    'pickup_latlng': GeoPoint(source!.latitude, source.longitude),
                    // 'destination_latlng':
                    //     GeoPoint(destination!.latitude, destination!.longitude),
                  };
      
                  rideController.findAndArrangeRides(searchRideInfo);
      
                  resetControllers();
                  Get.to(() => NearestRidePage(
                        rideController: rideController,
                      ));
                }
                }, color: AppColors.purpleColor),
          ),
          SizedBox(width: 30),
          customButton("Cancel", (){
          setState(() {
          showSearchButton = false;
          showDestField = false;
        });
          },color: AppColors.purpleColor)
        ]),
    );
  }

  Widget buildDateTimeButton() {
    return Container(
      margin: EdgeInsets.only(top:4),
      child: customButton(showDateButton? "Back": "Select other time", () {
        if(showDateButton){
          setState(() {
            showDateButton = false;
          });
        }else{
          setState(() {
            showDateButton = true;
          });
        }
        }, color: AppColors.purpleColor),
      );
  }

  // each option inside the side drawer
  buildDrawerItem(
      {required String title,
      required Function onPressed,
      Color color = Colors.black,
      double fontSize = 20,
      FontWeight fontWeight = FontWeight.w700,
      double height = 45,
      bool isVisible = false}) {
    return SizedBox(
      height: height,
      child: ListTile(
        contentPadding: EdgeInsets.all(0),
        dense: true,
        onTap: () => onPressed(),
        title: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                  fontSize: fontSize, fontWeight: fontWeight, color: color),
            ),
            const SizedBox(
              width: 5,
            ),
            isVisible
                ? CircleAvatar(
                    backgroundColor: AppColors.purpleColor,
                    radius: 15,
                    child: Text(
                      '1',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  )
                : Container()
          ],
        ),
      ),
    );
  }

  // Widget to create the side drawer
  buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Obx(
            () => authController.myUser.value.name == null
                ? Center(child: CircularProgressIndicator())
                : InkWell(
                    onTap: () {
                      Get.to(() => const MyProfile());
                    },
                    child: SizedBox(
                      height: 150,
                      child: DrawerHeader(
                          child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: authController.myUser.value.image == null
                                    ? const DecorationImage(
                                        image: AssetImage('assets/person.png'),
                                        fit: BoxFit.fill)
                                    : DecorationImage(
                                        image: NetworkImage(
                                            authController.myUser.value.image!),
                                        fit: BoxFit.fill)),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Welcome, ',
                                    style: GoogleFonts.poppins(
                                        color: Colors.black.withOpacity(0.28),
                                        fontSize: 14)),
                                Text(
                                  authController.myUser.value.name == null
                                      ? "User"
                                      : authController.myUser.value.name!,
                                  style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                )
                              ],
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                // buildDrawerItem(
                //     title: 'Payment History',
                //     onPressed: () => Get.to(() => PaymentScreen())),
                Stack(
                  children: [
                    buildDrawerItem(
                        title: 'All Rides',
                        onPressed: () => Get.to(() => const MyRides())),
                    Obx(() => rideController.userCurrentRide.length == 1
                        ? Positioned(
                            top: 16,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox()),
                  ],
                ),
                buildDrawerItem(
                    title: 'Settings',
                    onPressed: () {
                      Get.to(() => const MyProfile());
                    }),
                buildDrawerItem(title: 'Support', onPressed: () {
                  Get.to(() => const SupportViewUser());
                }),
                buildDrawerItem(
                    title: 'Log Out',
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Get.to(() => DecisionScreen());
                    }),
              ],
            ),
          ),
          // Spacer(),
          // Divider(),
          // Container(
          //   padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          //   child: Column(
          //     children: [
          //       buildDrawerItem(
          //           title: 'Do more',
          //           onPressed: () {},
          //           fontSize: 12,
          //           fontWeight: FontWeight.bold,
          //           color: Colors.black.withOpacity(0.15),
          //           height: 20),
          //       const SizedBox(
          //         height: 20,
          //       ),
          //       buildDrawerItem(
          //         title: 'Rate us on store',
          //         onPressed: () {},
          //         fontSize: 12,
          //         fontWeight: FontWeight.w500,
          //         color: Colors.black.withOpacity(0.15),
          //         height: 20,
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(
          //   height: 20,
          // ),
        ],
      ),
    );
  }

  late Uint8List markIcons;

  loadCustomMarker() async {
    // loading asset from folder with specified width (in this case width = 100)
    markIcons = await loadAsset('assets/dest_marker.png', 100);
  }

  // getting the asset from assets folder
  Future<Uint8List> loadAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  void drawPolyline(String placeId) {
    _polyline.clear();
    _polyline.add(Polyline(
      polylineId: PolylineId(placeId),
      visible: true, // this means this line should be visible to the user
      points: [
        LatLng(source.latitude, source.longitude),
        LatLng(destination.latitude, destination.longitude)
      ], // means from point a (source) to point b (destination) draw a polyline
      color: AppColors.purpleColor, // color of polyline
      width: 5,
    ));
  }

  startTimeMethod(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      startTime = picked;
      startTimeController.text =
          '${startTime.hourOfPeriod > 9 ? "" : '0'}${startTime.hour > 12 ? '${startTime.hour - 12}' : startTime.hour}:${startTime.minute > 9 ? startTime.minute : '0${startTime.minute}'} ${startTime.hour > 12 ? 'PM' : 'AM'}';
    }
    if (mounted) setState(() {});
  }


  void resetControllers() {
    destinationController.clear();
    sourceController.clear();
    date = DateTime.now();
    dateController.text = '${date!.day}-${date!.month}-${date!.year}';
    if (mounted) setState(() {});
  }
}