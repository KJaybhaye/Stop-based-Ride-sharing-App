import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:project/controller/auth_controller.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/utils/app_constants.dart';
import 'package:project/widgets/purple_intro_widget.dart';
import 'package:project/widgets/otp_verification_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class OtpVerificationScreen extends StatefulWidget {
  String phoneNumber;
  OtpVerificationScreen(this.phoneNumber, {super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    authController.phoneAuth(widget.phoneNumber);
    // startTimer();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (start == 0) {
        setState(() {
          addResendButton = true;
          // timer.cancel();
        });
      } else {
        setState(() {
          start--;
        });
      }
    });
  }

  int start = 30;
  bool addResendButton = false;
  late Timer timer;

  void startTimer() {
    const onsec = Duration(seconds: 1);
    timer = Timer.periodic(onsec, (timer) {
      if (start == 0) {
        setState(() {
          addResendButton = true;
          timer.cancel();
        });
      } else {
        setState(() {
          start--;
        });
      }
    });
  }

   @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                purpleIntroWidget(),
                Positioned(
                  top: 60,
                  left: 30,
                  child: InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.purpleColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 50,
            ),
            otpVerificationWidget(start, false),
            (addResendButton)
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      addResendButton = false;
                      start = 90;
                      authController.phoneAuth(widget.phoneNumber);
                    });
                  },
                  child: const Text("Resend OTP"),
                  style: TextButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 118, 12, 247),
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RichText(
                  textAlign: TextAlign.start,
                  text: TextSpan(
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                    children: [
                      const TextSpan(
                        text: AppConstants.resendCode + " ",
                      ),
                      TextSpan(
                        text: (start > 9)
                            ? "00:$start seconds"
                            : "00:0$start seconds",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
