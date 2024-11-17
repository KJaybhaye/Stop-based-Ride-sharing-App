import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserModel {
  // String? bAddress;
  // String? hAddress;
  // String? mallAddress;
  String? name;
  String? image;
  String? city;
  String? email;
  String? gender;

  LatLng? city_address;
  Map<String, dynamic>? reviews;
  // LatLng? homeAddress;
  // LatLng? bussinessAddres;
  // LatLng? shoppingAddress;

  // UserModel(
  //     {this.name, this.mallAddress, this.hAddress, this.bAddress, this.image});
  UserModel(
      {this.name, this.city_address, this.image, this.email, this.gender, this.reviews});
  

  UserModel.fromJson(Map<String, dynamic> json) {
    // bAddress = json['business_address'];
    // hAddress = json['home_address'];
    // mallAddress = json['shopping_address'];
    name = json['name'];
    image = json['image'];
    city = json['city'];
    email = json['email'];
    gender = json['gender'];
    // homeAddress =
    //     LatLng(json['home_latlng'].latitude, json['home_latlng'].longitude);
    // bussinessAddres = LatLng(
    //     json['business_latlng'].latitude, json['business_latlng'].longitude);
    // shoppingAddress = LatLng(
    //     json['shopping_latlng'].latitude, json['shopping_latlng'].longitude);
    city_address = 
        LatLng(json['city_address'].latitude, json['city_address'].longitude);
    reviews = json['reviews'];
  }
}
