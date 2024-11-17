import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class UploadDocumentPage extends StatefulWidget {
  const UploadDocumentPage({Key? key,required this.onImageSelected}) : super(key: key);

  final Function onImageSelected;

  @override
  State<UploadDocumentPage> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends State<UploadDocumentPage> {


  File? selectedImage ;
  File? licenceImage;
  final ImagePicker _picker = ImagePicker();

  getImage(ImageSource source, {licence=false}) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      if(licence){
        licenceImage = File(image.path);
        if(selectedImage != null){
          widget.onImageSelected(selectedImage, licenceImage);
        }
      }
      else{
        selectedImage = File(image.path);
        if(licenceImage != null){
          widget.onImageSelected(selectedImage, licenceImage);
  }
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [

        Text('Upload Documents',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600,color: Colors.black),),

        SizedBox(height: 10,),


        GestureDetector( // This widget is to call a specific function when a specific widget is clicked
          onTap: (){
            getImage(ImageSource.camera); // Call this function when the container is clicked
          },
          child: Container(
            width: Get.width,
            height: Get.height*0.13,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Color(0xffE3E3E3).withOpacity(0.4),
                border: Border.all(color: Color(0xff2FB654).withOpacity(0.26),width: 1)
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selectedImage == null?Icons.cloud_upload : const IconData(0xe156, fontFamily: 'MaterialIcons'),size: 40,color: Color(0xff7D7D7D),),

                Text(selectedImage == null?'Tap here to upload ': 'Document is selected.',style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: Color(0xff7D7D7D)),),
              ],
            ),
          ),
        ),

        Text('Upload Licence',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600,color: Colors.black),),

        SizedBox(height: 10,),

        GestureDetector( // This widget is to call a specific function when a specific widget is clicked
          onTap: (){
            getImage(ImageSource.camera, licence: true); // Call this function when the container is clicked
          },
          child: Container(
            width: Get.width,
            height: Get.height*0.13,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Color(0xffE3E3E3).withOpacity(0.4),
                border: Border.all(color: Color(0xff2FB654).withOpacity(0.26),width: 1)
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(licenceImage == null?Icons.cloud_upload : const IconData(0xe156, fontFamily: 'MaterialIcons'),size: 40,color: Color(0xff7D7D7D),),

                Text(licenceImage == null?'Tap here to upload ': 'Document is selected.',style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: Color(0xff7D7D7D)),),
              ],
            ),
          ),
        ),

      ],
    );
  }
}