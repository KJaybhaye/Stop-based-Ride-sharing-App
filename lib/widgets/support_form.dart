import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupportFormWidget extends StatefulWidget {
  String? rideId;
  String userId;
  SupportFormWidget({Key? key, required this.userId, this.rideId}) : super(key: key);
  @override
  _SupportFormWidgetState createState() => _SupportFormWidgetState();
}

class _SupportFormWidgetState extends State<SupportFormWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> data = {'UserId': widget.userId, 'Name': _nameController.text,
      'Email': _emailController.text, 'Conatact_Number': _numberController.text, 
      'Description': _descriptionController.text, 'Status': 'In Progress'
      };
      if (widget.rideId != null) {
      data['rideId'] = widget.rideId;
    }
    createSupportDocument(data);
    }

  }

  Future<void> createSupportDocument(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('support')
        .add(data)
        .then((value) {
      Get.snackbar('Success', 'Support request sent successfully.',
          colorText: Colors.white, backgroundColor: Color(0xFF00832C));
      Get.back(closeOverlays: true);
    }).catchError((e) {
      Get.snackbar('Failure', 'Failed to send support request.',
          colorText: Colors.white, backgroundColor: Color.fromARGB(255, 248, 25, 25));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Support Form', style: TextStyle(color: Colors.black)),
      backgroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _numberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                validator: (value) {
                  if (value == null || value.isEmpty ) {
                    return 'Please enter your phone number';
                  } else if (!RegExp(r'^[0-9]+$').hasMatch(value) || value.length != 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  } else if (value.length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),)
    );
  }
}