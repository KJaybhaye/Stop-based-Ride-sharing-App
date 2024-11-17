import 'package:project/controller/auth_controller.dart';
import 'package:project/shared%20preferences/shared_pref.dart';
import 'package:project/views/login_screen.dart';
import 'package:project/widgets/my_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../utils/app_constants.dart';
import '../../widgets/purple_intro_widget.dart';

class DecisionScreen extends StatefulWidget {
  DecisionScreen({Key? key}) : super(key: key);

  @override
  State<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends State<DecisionScreen> {
  AuthController authController = Get.find<AuthController>();

  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        child: Column(
          children: [
            purpleIntroWidget(),
            const SizedBox(
              height: 50,
            ),
            DecisionButton('assets/driver.png', 'Login As Driver', () {
              //authController.isLoginAsDriver = true;
              CacheHelper.saveData(key: AppConstants.decisionKey, val: true);
              Get.to(() => LoginScreen());
            }, Get.width * 0.8),
            const SizedBox(
              height: 20,
            ),
            DecisionButton('assets/customer.png', 'Login As User', () {
              CacheHelper.saveData(key: AppConstants.decisionKey, val: false);
              Get.to(() => LoginScreen());
            }, Get.width * 0.8),
          ],
        ),
      ),
    );
  }
}
