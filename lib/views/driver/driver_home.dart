import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:project/controller/auth_controller.dart';
import 'package:project/controller/location_handler.dart';
import 'package:project/controller/polyline_handler.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:project/models/stops.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/utils/app_constants.dart';
import 'package:project/views/decision_screens/decision_screen.dart';
import 'package:project/views/driver/driver_profile.dart';
import 'package:project/views/ride_requests.dart';
import 'package:project/views/my_rides.dart';
import 'package:project/views/support_view_driver.dart';
import 'package:project/widgets/purple_button.dart';
import 'package:project/widgets/icon_title_widget.dart';
import 'package:project/widgets/text_widget.dart';
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

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  String? _mapStyle;
  DateTime? date = DateTime.now();

  AuthController authController = Get.find<AuthController>();
  RideController rideController = Get.find<RideController>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late GeoPoint destination;
  late GeoPoint source;
  late LatLng search;
  final Set<Polyline> _polyline = {};
  bool showsearch = false;


  // saving all the markers that will be showing on the map and store them in this set
  Set<Marker> markers = Set<Marker>();
  List<String> list = <String>[
    '**** **** **** 8789',
    '**** **** **** 8921',
    '**** **** **** 1233',
    '**** **** **** 4352'
  ];
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  LatLng imploc = LatLng(200,200);
  LatLng currentLocation = LatLng(200,200);
  LatLng country = LatLng(18.516726, 73.856255);
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
    rideController.getMyDocument();
    authController.getDriverInfo();

    rootBundle.loadString('assets/map_style.txt').then((string) {
      _mapStyle = string;
    });

    loadCustomMarker();
    getCurrentLocation(updateMarker: true);

    _kGooglePlex = CameraPosition(
      target: country,
      zoom: 10.0);

    timeController.text = '${date!.hour}:${date!.minute}:${date!.second}';
    dateController.text = '${date!.day}-${date!.month}-${date!.year}';

    requestPermission();
    getToken();
    loadFCM();
    listenFCM();
  }

  CameraPosition? _kGooglePlex;
  String dropdownValue = '**** **** **** 8789';  

  GoogleMapController? myMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: buildProfileTitle(),
        backgroundColor: Colors.white70,
        iconTheme: IconThemeData(color: Colors.black),
        titleSpacing: 0,
      ),
      key: _key, 
      drawer: buildDrawer(),
      body: Container(
        child: Form(
          key: formKey,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: GoogleMap(
                  markers: markers,
                  polylines: _polyline,
                  zoomControlsEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    myMapController = controller;
                    myMapController!.setMapStyle(_mapStyle);
                  },
                  initialCameraPosition: _kGooglePlex!,
                  mapToolbarEnabled: false
                ),
              ),
              Column(
                children: [
                  buildSearchField(),
                  showSourceField ? buildTextFieldForSource() : Container(),
                  showDestField ? buildTextField() : Container(),
                  ],
              ),
              Positioned(
                bottom: Get.height * 0.12,
                child: Column(children: [
                  sourceSelected && destSelected && showDateTimeFields ? buildDateTimeFields() : Container(),
                  sourceSelected && destSelected && showDateTimeFields ? buildMaxSeatsAndPriceFields() : Container(),
                  sourceSelected && destSelected && showDateTimeFields ? buildConfirmButton() : Container(),
                  showStop ? buildStop() : Container()
              ],)),
              buildCurrentLocationIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget pendingWidget(){
    return Container(
                width: Get.width,
                height: Get.width * 0.5,
                child: Column(children: [
                  Text(
                        "Verification Pending",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                  customButton('REFRESH',(){
                    authController.getDriverInfo();
                    if(authController.myDriver.value.verified == true)
                    setState(() {
                      showsearch = true;
                    });

                  },color: AppColors.purpleColor)
                ]),
          );
  }
  Widget buildProfileTitle() {
    return Obx(() => authController.myDriver.value.name == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: authController.myDriver.value.image == null
                            ? DecorationImage(
                                image: AssetImage('assets/person.png'),
                                fit: BoxFit.fill)
                            : DecorationImage(
                                image: NetworkImage(
                                    authController.myDriver.value.image!),
                                fit: BoxFit.fill)),
                  ),
                  const SizedBox(
                    width: 20,
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
                              text: authController.myDriver.value.name
                                  ?.substring(
                                      0,
                                      authController.myDriver.value.name
                                          ?.indexOf(' ')),
                              style: TextStyle(
                                  color: Colors.purple,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ),
                      Text(
                        "Create your ride",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      )
                    ],
                  )
                ],
              ),
            )    
          );
  }

  TimeOfDay startTime = TimeOfDay(hour: 0, minute: 0);

  TextEditingController destinationController = TextEditingController();
  TextEditingController sourceController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController maxSeatsController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  // bool showsearch = false;
  bool showSourceField = false;
  bool showDateTimeFields = false;
  String? maxSeats = '1 seat';
  List<String> maxSeatsList = [
    '1 seat',
    '2 seats',
    '3 seats',
    '4 seats',
  ];
  bool showDestField = false;
  bool showRideButton = false;
  bool showStop = false;
  bool sourceSelected = false;
  bool destSelected = false;

  late GeoPoint selectedStopLoc;
  late String selectedStopName;

  // late BusStop selectedStop = BusStop(name: 'name', location: LatLng(18.3, 37.5));

  Widget buildStop(){
    return Container(
        width: Get.width,
        child: Obx(() => authController.myDriver.value.verified == false
          ? Center(
              child: pendingWidget(),
            )
          : Column(
          children: [
            Text('Bustop Name: ${selectedStopName}',
            style: TextStyle(
              color: Colors.black,
              backgroundColor: Colors.greenAccent,
              fontWeight: FontWeight.w900
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 5, 5, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  customButton("Add as source", (){
                    if(destSelected){
                    if(destination == selectedStopLoc){
                            Get.snackbar('Failure', 'Source and Destination cannot be same.',
                            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
                            return;
                    }
                    }
                    source  = selectedStopLoc;
                    sourceController.text = selectedStopName;
                    setState(() {
                      showStop = false;
                      sourceSelected = true;
                      showSourceField = true;
                    });
                  }, color: AppColors.purpleColor),
                  customButton("Add as Destination", (){
                    if(sourceSelected){
                    if(source == selectedStopLoc){
                            Get.snackbar('Failure', 'Source and Destination cannot be same.',
                            colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
                            return;
                    }
                    }
                    destination = selectedStopLoc;
                    destinationController.text = selectedStopName;
                    setState(() {
                      showStop = false;
                      showDestField = true;
                      destSelected = true;
                      showDateTimeFields = true;
                    });
                  }, color: AppColors.purpleColor),
                  customButton("Back", (){
                    setState(() {
                      showStop = false;
                    });
                  }, color: AppColors.purpleColor)
                ],
              ),
            ),
          ],
        ),
      )
      );
  }

  Widget buildSearchField() {
    return Container(
        // width: Get.width*0.95,
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

            // markers.add(Marker(
            //   markerId: MarkerId(selectedPlace),
            //   infoWindow: InfoWindow(
            //     title: 'Destination: $selectedPlace',
            //   ),
            //   position: destination,
            //   icon: BitmapDescriptor.fromBytes(markIcons),
            // ));

            moveicon(search, zoom: 16.0);
            updateMarkers(search);

            // setState(() {
            //   showSourceField = true;
            // });
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
            // suffixIcon: Padding(
            //   padding: const EdgeInsets.only(left: 10),
            //   child: Icon(
            //     Icons.search,
            //   ),
            // ),
            border: InputBorder.none,
          ),
        ),
    );
  }

  Widget buildTextField() {
    return Obx(() => authController.myDriver.value.verified == false
          ? Center(
              child: pendingWidget(),
            )
          : Container(
        // margin: EdgeInsets.only(top:0),
        child: Row(
        // Container(height: 30,),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Container(
        width: Get.width*0.80,
        // height: 35,
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
    ));
  }

  Widget buildTextFieldForSource() {
    return Container(
        child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Container(
        width: Get.width*0.8,
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
      }, icon: Icon(Icons.close))
      ],
    ));
  }

  Widget buildDateTimeFields() {
    return Container(
      width: Get.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconTitleContainer(
            isReadOnly: true,
            path: 'assets/date.png',
            text: 'Date',
            controller: dateController,
            validator: (input) {
              print(date);
              print(dateController.text);
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
              width: 170,
              validator: (input) {
                DateTime currentDate = DateTime.now().add(Duration(minutes: 20));
                DateTime selectedDateTime = DateTime(
                date!.year,
                date!.month,
                date!.day,
                startTime.hour,
                startTime.minute,
                );
                if(!selectedDateTime.isAfter(currentDate)){
                  Get.snackbar('Warning', "Select time atlest 20 minutes from now.",
                      colorText: Colors.white,
                      backgroundColor: AppColors.purpleColor);
                  return '';
                }
                
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

  Widget buildMaxSeatsAndPriceFields() {
    return Container(
      width: Get.width,
      child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(left: 10, right: 10),
                width: 150,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 4,
                        blurRadius: 10)
                  ],
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(width: 1, color: AppColors.genderTextColor),
                ),
                child: DropdownButton(
                  isExpanded: true,
                  underline: Container(),
                  borderRadius: BorderRadius.circular(10),
                  icon: Image.asset('assets/arrowDown.png'),
                  elevation: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.blackColor,
                  ),
                  value: maxSeats,
                  onChanged: (String? newValue) {
                    if (mounted)
                      setState(
                        () {
                          maxSeats = newValue!;
                        },
                      );
                  },
                  items: maxSeatsList
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: AppColors.blackColor,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              iconTitleContainer(
                  path: 'assets/ruppes.png',
                  text: 'Price per Seat',
                  type: TextInputType.number,
                  height: 40,
                  controller: priceController,
                  width: 170,
                  onPress: () {},
                  validator: (String input) {
                    if (input.isEmpty) {
                      Get.snackbar('Warning', "Price is required.",
                          colorText: Colors.white,
                          backgroundColor: AppColors.purpleColor);
                      return '';
                    }
                  })
            ],
          ),
      );
  }

  Widget buildConfirmButton() {
    return Container(
        width: Get.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Obx(() => rideController.isRideUploading.value
            ? Center(
                child: CircularProgressIndicator(),
              ):customButton(
                'Create Ride',
                () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  Get.defaultDialog(
                    title: "Are you sure to create this ride ?",
                    content: Container(),
                    //barrierDismissible: false,
                    actions: [
                      MaterialButton(
                        onPressed: () {
                          Get.back();
                          Map<String, dynamic> rideData = {
                            'pickup_address': sourceController.text,
                            'destination_address': destinationController.text,
                            'date': '${date!.day}-${date!.month}-${date!.year}',
                            'start_time': startTimeController.text,
                            'max_seats': maxSeats,
                            'price_per_seat': priceController.text,
                            'driver': FirebaseAuth.instance.currentUser!.uid,
                            'pending': [],
                            'picked_up': [],
                            'joined': [],
                            'rejected': [],
                            // 'codes': {},
                            // 'phones': {},
                            'passengers': {},
                            'driverPhone': FirebaseAuth.instance.currentUser?.phoneNumber,
                            'status': "Upcoming",
                            'payment_method': '',
                            'pickup_latlng':
                                GeoPoint(source!.latitude, source.longitude),
                            'destination_latlng': GeoPoint(
                                destination!.latitude, destination.longitude),
                          };
      
                          rideController.isRideUploading(true);
                          rideController.createRide(rideData).then((value) {
                            print("Ride is done");
                            resetControllers();
                            showSourceField = false;
                            showDateTimeFields = false;
                            sourceSelected = false;
                            destSelected = false;
                            showDestField = false;
                            _polyline.clear();
                            // markers.clear();
                          });
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
                },color: AppColors.purpleColor),
                ),
                const SizedBox(width: 20),
                customButton("Cancel", (){
        setState(() {
          showDateTimeFields = false;
          showDestField = false;
        });
          },color: AppColors.purpleColor),
          const SizedBox(width: 50,)]),
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
          backgroundColor: AppColors.purpleColor,
          child: Icon(Icons.my_location, color: Colors.white),
        ),
      ),
    ));
  }


  //each option inside the side drawer
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
        // minVerticalPadding: 0,
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

  buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Obx(
            () => authController.myDriver.value.name == null
                ? Center(child: CircularProgressIndicator())
                : InkWell(
                    onTap: () {
                      // Get.to(() => const DriverProfile());
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
                                image: authController.myDriver.value.image ==
                                        null
                                    ? const DecorationImage(
                                        image: AssetImage('assets/person.png'),
                                        fit: BoxFit.fill)
                                    : DecorationImage(
                                        image: NetworkImage(authController
                                            .myDriver.value.image!),
                                        fit: BoxFit.fill),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Welcome, ',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black.withOpacity(0.28),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    authController.myDriver.value.name == null
                                        ? "User"
                                        : authController.myDriver.value.name!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                // buildDrawerItem(
                //   title: 'Payment History',
                //   onPressed: () => Get.to(() => PaymentScreen()),
                // ),
                Stack(
                  children: [
                    buildDrawerItem(
                      title: 'Ride Requests',
                      onPressed: () => Get.to(() => RideRequests()),
                    ),
                    Positioned(
                      top: 19,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Obx(
                            () => Text(
                              '${rideController.pendingRequests.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    buildDrawerItem(
                      title: 'My Rides',
                      onPressed: () => Get.to(() => const MyRides()),
                    ),
                    Positioned(
                      top: 17,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Obx(
                            () => Text(
                              '${rideController.driverCurrentRide.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                buildDrawerItem(
                  title: 'Settings',
                  onPressed: () => Get.to(() => const DriverProfile()),
                ),
                buildDrawerItem(title: 'Support', onPressed: () {
                  Get.to(() => const SupportViewDriver());
                }),
                buildDrawerItem(
                  title: 'Log Out',
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    Get.to(() => DecisionScreen());
                  },
                ),
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
          const SizedBox(height: 20),
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

  void resetControllers() {
    destinationController.clear();
    sourceController.clear();
    date = DateTime.now();
    dateController.text = '${date!.day}-${date!.month}-${date!.year}';
    timeController.clear();
    priceController.clear();
    maxSeatsController.clear();
    startTimeController.clear();
    if (mounted) setState(() {});
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

  Dialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          title: Text('Are you sure to create this ride ?'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MaterialButton(
                onPressed: () {},
                child: textWidget(
                  text: 'Confirm',
                  color: Colors.white,
                ),
                color: AppColors.purpleColor,
                shape: StadiumBorder(),
              ),
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
          ),
        );
      },
    );
  }
}