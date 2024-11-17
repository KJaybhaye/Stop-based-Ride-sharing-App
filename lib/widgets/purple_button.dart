import 'package:project/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

Widget purpleButton(String title, Function onPressed, {double width=0}) {
  if(width == 0){
    width = Get.width;
  }
  return MaterialButton(
    minWidth: width,
    height: 50,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    color: AppColors.purpleColor,
    onPressed: () => onPressed(),
    child: Text(
      title,
      style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    ),
  );
}

Widget customButton(String title, onPressed, {color= Colors.red}) {
  return InkWell(
            onTap: onPressed,
            child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 8.0,
              ),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  // color: Colors.red.withOpacity(0.9)),
                  color: color),
              child: Center(
                child: Text(
                   title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
}
