import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverModel {
  String? country;
  String? vehicle_color;
  String? vehicle_make;
  String? vehicle_model;
  String? vehicle_number;
  String? vehicle_type;
  String? vehicle_year;
  String? document;
  String? email;
  String? name;
  bool? IsDriver;
  String? image;
  bool? verified;
  bool? details_pending;

  String? city;
  LatLng? cityAddress;
  String? gender;
  Map<String, dynamic>? reviews;

  DriverModel(
      {this.name,
      this.country,
      this.vehicle_color,
      this.vehicle_make,
      this.vehicle_model,
      this.vehicle_number,
      this.vehicle_type,
      this.vehicle_year,
      this.document,
      this.IsDriver,
      this.email,
      this.image,
      this.verified,
      this.details_pending,
      this.city,
      this.cityAddress,
      this.gender,
      this.reviews});

  DriverModel.fromJson(Map<String, dynamic> json) {
    country = json['Country'];
    vehicle_color = json['Vehicle_color'];
    vehicle_make = json['Vehicle_make'];
    vehicle_model = json['Vehicle_model'];
    vehicle_number = json['Vehicle_number'];
    vehicle_type = json['Vehicle_type'];
    vehicle_year = json['Vehicle_year'];
    document = json['document'];
    email = json['email'];
    image = json['image'];
    IsDriver = json['isDriver'];
    name = json['name'];
    verified = json['verified'];
    details_pending = json['details_pending'];
    city = json['city'];
    cityAddress = LatLng(json['city_address'].latitude, json['city_address'].longitude);
    gender = json['gender'];
    reviews = json['review'];
  }
}
