import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

Widget purpleIntroWidget() {
  return Container(
    width: Get.width,
     decoration: BoxDecoration(
      color: Color.fromARGB(255, 118, 12, 247)),
    // decoration: BoxDecoration(
    //     image: DecorationImage(
    //         image: AssetImage('assets/mask.png'), fit: BoxFit.cover)),
    height: Get.height * 0.6,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/car_icon.png',
          fit: BoxFit.cover,
          width: 200,
        ),
      ],
    ),
  );
}

Widget purpleIntroWidgetWithoutLogos(
    {String title = "Profile Settings", String? subtitle}) {
  return Container(
    width: Get.width,
    decoration: BoxDecoration(
      color: Color.fromARGB(255, 118, 12, 247)),
    // decoration: BoxDecoration(
    //     image: DecorationImage(
    //         image: AssetImage('assets/mask.png'), fit: BoxFit.fill)),
    height: Get.height * 0.3,
    child: Container(
        height: Get.height * 0.1,
        width: Get.width,
        margin: EdgeInsets.only(bottom: Get.height * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white),
              ),
          ],
        )),
  );
}
