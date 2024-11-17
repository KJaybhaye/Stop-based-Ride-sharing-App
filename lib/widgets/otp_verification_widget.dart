import 'dart:async';

import 'package:project/utils/app_constants.dart';
import 'package:project/widgets/pinput_widget.dart';
import 'package:project/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

Widget otpVerificationWidget(int start, bool addResendButton) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(text: AppConstants.phoneVerification),
        textWidget(
            text: AppConstants.enterOtp,
            fontSize: 22,
            fontWeight: FontWeight.bold),
        const SizedBox(
          height: 40,
        ),
        Center(
          child: Container(
              width: Get.width, height: 50, child: RoundedWithShadow()),
        ),
        const SizedBox(
          height: 40,
        ),
      ],
    ),
  );
}
