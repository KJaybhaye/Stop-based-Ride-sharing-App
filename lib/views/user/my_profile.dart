import 'dart:io';
import 'package:project/controller/auth_controller.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/widgets/purple_button.dart';
import 'package:project/widgets/purple_intro_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:image_picker/image_picker.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({Key? key}) : super(key: key);

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  TextEditingController nameController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  // TextEditingController homeController = TextEditingController();
  // TextEditingController businessController = TextEditingController();
  // TextEditingController shopController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AuthController authController = Get.find<AuthController>();

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;

  getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      selectedImage = File(image.path);
      setState(() {});
    }
  }

  // late LatLng homeAddress;
  // late LatLng businessAddress;
  // late LatLng shoppingAddress;
  late LatLng cityAddress;
  @override
  void initState() {
    super.initState();
    nameController.text = authController.myUser.value.name ?? "";
    cityController.text = authController.myUser.value.city ?? "";
    emailController.text = authController.myUser.value.email ?? "";
    genderController.text = authController.myUser.value.gender ?? 'Male';
    // homeController.text = authController.myUser.value.hAddress ?? "";
    // shopController.text = authController.myUser.value.mallAddress ?? "";
    // businessController.text = authController.myUser.value.bAddress ?? "";

    // homeAddress = authController.myUser.value.homeAddress!;
    // businessAddress = authController.myUser.value.bussinessAddres!;
    // shoppingAddress = authController.myUser.value.shoppingAddress!;
    cityAddress = authController.myUser.value.city_address!;
  }

  @override
  Widget build(BuildContext context) {
    print(authController.myUser.value.image!);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: Get.height * 0.4,
              child: Stack(
                children: [
                  purpleIntroWidgetWithoutLogos(title: 'My Profile'),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: InkWell(
                      onTap: () {
                        getImage(ImageSource.camera);
                      },
                      child: selectedImage == null
                          ? authController.myUser.value.image != null
                              ? Container(
                                  width: 120,
                                  height: 120,
                                  margin: EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: NetworkImage(authController
                                              .myUser.value.image!),
                                          fit: BoxFit.fill),
                                      shape: BoxShape.circle,
                                      color: Color(0xffD6D6D6)),
                                )
                              : Container(
                                  width: 120,
                                  height: 120,
                                  margin: EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xffD6D6D6)),
                                  child: Center(
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                          : Container(
                              width: 120,
                              height: 120,
                              margin: EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: FileImage(selectedImage!),
                                      fit: BoxFit.fill),
                                  shape: BoxShape.circle,
                                  color: Color(0xffD6D6D6)),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 23),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFieldWidget(
                      'Name',
                      Icons.person_outlined,
                      nameController,
                      (String? input) {
                        if (input!.isEmpty) {
                          return 'Name is required!';
                        }

                        if (input.length < 5) {
                          return 'Please enter a valid name!';
                        }
                        if (input != null){
                        List<String> words = input.split(" ");
                        if (words.length < 2) {
                        // List<String> words = input?.split(" ");
                        return 'Write full name!';
                      }
                      }

                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFieldWidget('Email', Icons.email, emailController,
                        (String? input) {
                      if (input!.isEmpty) {
                        return 'Email is required!';
                      }

                      if (!input.isEmail) {
                        return 'Enter valid email.';
                      }

                      return null;
                    }, onTap: () async {}, readOnly: false),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFieldWidget(
                        'City Address', Icons.home_outlined, cityController,
                        (String? input) {
                      if (input!.isEmpty) {
                        return 'City Address is required!';
                      }

                      return null;
                    }, onTap: () async {
                      Prediction? p =
                          await authController.showGoogleAutoComplete(context);

                      /// now let's translate this selected address and convert it to latlng obj
                      cityAddress = await authController
                          .buildLatLngFromAddress(p!.description!);
                      cityController.text = p.description!;

                      ///store this information into firebase together once update is clicked
                    }, readOnly: true),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Text("Gender:  ", 
                        style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xffA7A7A7))
                        ),
                        const SizedBox(width: 5,),
                        DropdownButton<String>(
                      // value: 'Male',
                      hint: Text(genderController.text),
                      // alignment: AlignmentDirectional.topStart,
                      items: <String>['Male', 'Female', 'Other'].map((String value) {
                        return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffA7A7A7)),),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          genderController.text = value!;
                        });
                      },
                      ),
                      ],
                    ),
                    // TextFieldWidget('Business Address', Icons.card_travel,
                    //     businessController, (String? input) {
                    //   if (input!.isEmpty) {
                    //     return 'Business Address is required!';
                    //   }

                    //   return null;
                    // }, onTap: () async {
                    //   Prediction? p =
                    //       await authController.showGoogleAutoComplete(context);

                    //   /// now let's translate this selected address and convert it to latlng obj
                    //   businessAddress = await authController
                    //       .buildLatLngFromAddress(p!.description!);
                    //   businessController.text = p.description!;

                    //   ///store this information into firebase together once update is clicked
                    // }, readOnly: true),
                    // const SizedBox(
                    //   height: 10,
                    // ),
                    // TextFieldWidget(
                    //     'Shopping Center',
                    //     Icons.shopping_cart_outlined,
                    //     shopController, (String? input) {
                    //   if (input!.isEmpty) {
                    //     return 'Shopping Center is required!';
                    //   }

                    //   return null;
                    // }, onTap: () async {
                    //   Prediction? p =
                    //       await authController.showGoogleAutoComplete(context);

                    //   /// now let's translate this selected address and convert it to latlng obj
                    //   shoppingAddress = await authController
                    //       .buildLatLngFromAddress(p!.description!);
                    //   shopController.text = p.description!;

                    //   ///store this information into firebase together once update is clicked
                    // }, readOnly: true),
                    const SizedBox(
                      height: 30,
                    ),
                    Obx(() => authController.isProfileUploading.value
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : purpleButton('Update', () {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            authController.isProfileUploading(true);
                            authController.storeUserInfo(
                                selectedImage,
                                nameController.text,
                                cityController.text,
                                emailController.text,
                                genderController.text,
                                // homeController.text,
                                // businessController.text,
                                // shopController.text,
                                url: authController.myUser.value.image ?? "",
                                cityLatLng: cityAddress
                                // homeLatLng: homeAddress,
                                // shoppingLatLng: shoppingAddress,
                                // businessLatLng: businessAddress
                                );
                          })),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  TextFieldWidget(String title, IconData iconData,
      TextEditingController controller, Function validator,
      {Function? onTap, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xffA7A7A7)),
        ),
        const SizedBox(
          height: 6,
        ),
        Container(
          width: Get.width,
          // height: 50,
          decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 1)
              ],
              borderRadius: BorderRadius.circular(8)),
          child: TextFormField(
            readOnly: readOnly,
            onTap: () => onTap!(),
            validator: (input) => validator(input),
            controller: controller,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xffA7A7A7)),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(
                  iconData,
                  color: AppColors.purpleColor,
                ),
              ),
              border: InputBorder.none,
            ),
          ),
        )
      ],
    );
  }
}
