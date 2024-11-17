import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/views/decision_screens/decision_screen.dart';

class Intro extends StatelessWidget {
  const Intro({super.key});

  @override
  Widget build(BuildContext context) {
    Timer(
            Duration(seconds: 1),
                () =>
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (BuildContext context) => DecisionScreen())
          )
      );

    return Stack(
      alignment: Alignment.center,
      children:[
      Container(
      width: double.infinity,
      decoration: BoxDecoration(
      color: AppColors.purpleColor
      )
      ),
      Image.asset('assets/car_icon.png',
      width: 200,
      )
    ]);
  }
}