import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

class BusStop {
  String name;
  LatLng location;
  static List<BusStop> busStops = [
    BusStop(name: 'Bus Stop 1', location: LatLng(37.42146999044655, -122.08786238494775)),
    BusStop(name: 'Bus Stop 3', location: LatLng(37.420447499272406, -122.08613504234216)),
    BusStop(name: 'Bus Stop 4', location: LatLng(37.42218572596128, -122.08530892196559)),
    BusStop(name: 'Bus Stop 2', location: LatLng(37.4210609956523, -122.08204735580351)),
    // Add more bus stops as needed
  ];
  BusStop({required this.name, required this.location});

  // BusStop.fromJson(Map<String, dynamic> json){
  //   location = LatLng(json['geometry']['location']['lat'], json['geometry']['location']['lng']);
  //   name = json['name'];
  // }
  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
          name: json['name'],
          location: LatLng(json['geometry']['location']['lat'], json['geometry']['location']['lng']) 
        );
    }

}
