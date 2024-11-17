import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:project/utils/app_constants.dart';
import 'package:project/widgets/text_widget.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget loginWidget(
  CountryCode countryCode,
  Function onCountryChange,
  Function onSubmit,
  BuildContext context,
) {

  TextEditingController _mobileNumberController = TextEditingController();


  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(text: AppConstants.helloNiceToMeetYou),
        textWidget(
            text: AppConstants.getMoving,
            fontSize: 22,
            fontWeight: FontWeight.bold),
        const SizedBox(
          height: 40,
        ),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 3,
                    blurRadius: 3)
              ],
              borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () => onCountryChange(),
                    child: Container(
                      padding: EdgeInsets.all(2),
                      child: Row(
                        children: [
                          const SizedBox(width: 5),

                          Expanded(
                            child: Container(
                              child: countryCode.flagImage(),
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          textWidget(text: countryCode.dialCode),

                          // const SizedBox(width: 10,),

                          const Icon(Icons.keyboard_arrow_down_rounded)
                        ],
                      ),
                    ),
                  )),
              Container(
                width: 1,
                height: 55,
                color: Colors.black.withOpacity(0.2),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextFormField(

                    controller: _mobileNumberController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    onFieldSubmitted: (String? input) {
                      if (input != null && input.length == 10) {
                        onSubmit(input);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Mobile number should be 10 digits',
                            ),
                          ),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.normal),
                      hintText: AppConstants.enterMobileNumber,
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 40,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
                style: GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                children: [
                  TextSpan(
                    text: AppConstants.byCreating + " ",
                  ),
                  TextSpan(
                      text: AppConstants.termsOfService + " ",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  TextSpan(
                    text: "and ",
                  ),
                  TextSpan(
                      text: AppConstants.privacyPolicy + " ",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ]),
          ),
        )
      ],
    ),
  );
}