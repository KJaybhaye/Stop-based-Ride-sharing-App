import 'dart:io';

import 'package:project/controller/auth_controller.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/views/driver/car_registration/pages/document_uploaded_page.dart';
import 'package:project/views/driver/car_registration/pages/location_page.dart';
import 'package:project/views/driver/car_registration/pages/upload_document_page.dart';
import 'package:project/views/driver/car_registration/pages/vehicle_color_page.dart';
import 'package:project/views/driver/car_registration/pages/vehicle_make.dart';
import 'package:project/views/driver/car_registration/pages/vehicle_model_page.dart';
import 'package:project/views/driver/car_registration/pages/vehicle_model_year_page.dart';
import 'package:project/views/driver/car_registration/pages/vehicle_number_page.dart';
import 'package:project/views/driver/car_registration/pages/vehicle_type_page.dart';
import 'package:project/views/driver/verification_pending_screen.dart';
import 'package:project/widgets/purple_intro_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';

class CarRegistrationTemplate extends StatefulWidget {
  const CarRegistrationTemplate({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CarRegistrationTemplateState();
}

class _CarRegistrationTemplateState extends State<CarRegistrationTemplate> {
  String selectedLocation = '';
  String selectedVehicalType = '';
  String selectedVehicalMake = '';
  String selectedVehicalModel = '';
  String selectModelYear = '';
  PageController pageController = PageController();
  TextEditingController vehicalNumberController = TextEditingController();
  String vehicalColor = '';
  File? document;
  File? licence;

  int currentPage = 0;
  final FocusNode _focusNode = FocusNode();

    @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        purpleIntroWidgetWithoutLogos(
            title: 'Car Registration', subtitle: 'Complete the process detail'),
        const SizedBox(
          height: 20,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: PageView(
              onPageChanged: (int page) {
                currentPage = page;
                WidgetsBinding.instance?.focusManager.primaryFocus?.unfocus();
              },
              controller: pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                LocationPage(
                  selectedLocation: selectedLocation,
                  onSelect: (String location) {
                    setState(() {
                      selectedLocation = location;
                    });
                  },
                ),
                VehicalTypePage(
                  selectedVehical: selectedVehicalType,
                  onSelect: (String vehicalType) {
                    setState(() {
                      selectedVehicalType = vehicalType;
                    });
                  },
                ),
                VehicalMakePage(
                  selectedVehical: selectedVehicalMake,
                  onSelect: (String vehicalMake) {
                    setState(() {
                      selectedVehicalMake = vehicalMake;
                    });
                  },
                ),
                VehicalModelPage(
                  selectedModel: selectedVehicalModel,
                  onSelect: (String vehicalModel) {
                    setState(() {
                      selectedVehicalModel = vehicalModel;
                    });
                  },
                ),
                VehicalModelYearPage(
                  onSelect: (int year) {
                    setState(() {
                      selectModelYear = year.toString();
                    });
                  },
                ),
                VehicalNumberPage(
                  controller: vehicalNumberController,
                ),
                VehicalColorPage(
                  onColorSelected: (String selectedColor) {
                    vehicalColor = selectedColor;
                  },
                ),
                UploadDocumentPage(
                  onImageSelected: (File image, File lc) {
                    document = image;
                    licence = lc;
                  },
                ),
                DocumentUploadedPage(),
              ],
            ),
          ),
        ),
        Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Obx(()=> isUploading.value? Center(child: CircularProgressIndicator(),): FloatingActionButton(
                onPressed: () {
                  if (currentPage < 8) {
                    pageController.animateToPage(currentPage + 1,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeIn);
                  } else {
                    uploadDriverCarEntry();
                  }
                },
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
                backgroundColor: AppColors.purpleColor,
              ),)
            )),
      ],
    ));
  }

  var isUploading = false.obs;
  var pnumber = 0;

  bool valid(){
    String inputText = vehicalNumberController.text.trim();
    if(inputText.isEmpty){
      pnumber = 5;
      Get.snackbar("Invalid car Number", "Enter valid number.");
      return false;
    }
    RegExp regex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{2}[0-9]{4}$');
      if(!regex.hasMatch(inputText)){
        pnumber = 5;
        Get.snackbar("Invalid car Number", "Enter valid number.");
        return false;
      }
    if(document == null || licence == null){
      pnumber = 7;
      Get.snackbar(" ", "Select both document photos");
      return false;
    }
    return true;
  }

  void uploadDriverCarEntry() async {

    if(!valid()){
      pageController.animateToPage(
          pnumber,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
      );
      return;
    }
    isUploading(true);

    String imageURL = await Get.find<AuthController>().uploadImage(document!); 
    String licenceURL = await Get.find<AuthController>().uploadImage(document!);// This will upload the image

    Map<String, dynamic> carData = {
      'Country': selectedLocation,
      'Vehicle_type': selectedVehicalType,
      'Vehicle_make': selectedVehicalMake,
      'Vehicle_model': selectedVehicalModel,
      'Vehicle_year': selectModelYear,
      'Vehicle_number': vehicalNumberController.text.trim(),
      'Vehicle_color': vehicalColor,
      'document': imageURL,
      'licence': licenceURL,
      'verified': false,
      'details_pending': false
    };

    await Get.find<AuthController>().uploadCarEntry(carData); //This will upload the car info
    isUploading(false);

    Get.to(()=> VerificaitonPendingScreen());
  }
}
