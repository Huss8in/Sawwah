// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'MapSelectionScreen.dart';
import 'package:http/http.dart' as http;

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();

  //final places = GoogleMapsPlaces(apiKey: 'AIzaSyAUo9-XZrIFQGOCDcYU1GjOLaGTY4doZDM');
  final TextEditingController _locationController = TextEditingController();

  final _post = Post(
    id: '',
    title: '',
    location: '',
    body: '',
    imageUrl: [],
    author: '',
    userId: '',
    category: '',
  );
  late User _currentUser; // Add this line

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
  }

  Future<void> _selectLocationFromMap() async {
    final LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(),
      ),
    );

    if (selectedLocation != null) {
      final placemarks = await placemarkFromCoordinates(
        selectedLocation.latitude,
        selectedLocation.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address =
            "${placemark.name}, ${placemark.locality}, ${placemark.administrativeArea},${placemark.subAdministrativeArea} ,${placemark.country}";
        _locationController.text = address;
      }
    }
  }Future<void> sendPushNotificationToAllDevices() async {
    const postUrl = 'https://fcm.googleapis.com/fcm/send';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization':
          'key=AAAA2OPmGDw:APA91bFrT16PQMMCVQggKpjX4ZZqU_aYH_RiWuqeXcANjCS_eBDnuu8kDyObQ18XQ_IgwPA-30AD2JfeCjf-6KI8s--3KZBonBqF__q-ci7mQMOgw2Geo2TBHwbod8UI8RNKV-WPhU_D',
    };

    final data = {
      'notification': {
        'body': 'Check out the latest post!',
        'title': 'New Post: ${_post.title}',
      },
      'priority': 'high',
      'data': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'status': 'done',
        'sound': 'default',
      },
      'to': '/topics/all_users',
    };

    final response = await http.post(
      Uri.parse(postUrl),
      body: json.encode(data),
      headers: headers,
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully to all users');
      print('Response Body: ${response.body}');
    } else {
      print('Failed to send notification to all users');
      print('Response Body: ${response.body}');
      print('Status Code: ${response.statusCode}');
    }
  }


  String extractUsername(String email) {
    return email.split('@')[0];
  }

  @override
  Widget build(BuildContext context) {
    List<String> fileNames = [];
    Set<String> categoryValues = {
      'Beach',
      'Museum',
      'Club',
      'Restaurant',
      'Other',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Post',
          style: TextStyle(
            fontFamily: 'PharaonicFont',
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [
                Colors.purple,
                Colors.blue,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) {
                  _post.title = value!;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) {
                  _post.body = value!;
                },
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
                onTap: _selectLocationFromMap, // Open Google Maps on tap
                readOnly: true, // Make the field read-only
                onSaved: (value) {
                  _post.location = value!;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                value: _post.category,
                items: [
                  ...categoryValues.map((categoryValue) => DropdownMenuItem(
                        value: categoryValue,
                        key: Key(categoryValue),
                        child: Text(categoryValue),
                      )),
                  if (!categoryValues.contains(_post.category))
                    DropdownMenuItem(
                      value: _post.category,
                      key: Key(_post.category),
                      child: Text(_post.category),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _post.category = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  final pickedFiles = await ImagePicker().pickMultiImage();
                  if (pickedFiles.isNotEmpty) {
                    // ignore: use_build_context_synchronously
                    showDialog(
                      context: context,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      barrierDismissible: false,
                    );
                    final uploadTasks = pickedFiles.map((pickedFile) async {
                      final imageFile = File(pickedFile.path);
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('post_images')
                          .child('${_post.title}-${DateTime.now().toString()}');
                      final snapshot = await ref.putFile(imageFile);
                      final downloadUrl = await snapshot.ref.getDownloadURL();
                      return downloadUrl;
                    }).toList();
                    final imageUrlList = await Future.wait(uploadTasks);
                    // ignore: use_build_context_synchronously
                    Navigator.of(context)
                        .pop(); // Close the progress indicator dialog
                    setState(() {
                      _post.imageUrl.addAll(imageUrlList);
                      fileNames.addAll(
                        pickedFiles.map((file) => file.path.split('/').last),
                      );
                    });
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Icon(Icons.upload_file),
                    const SizedBox(width: 8),
                    Text(
                      fileNames.isEmpty ? 'Upload Images' : 'Add More Images',
                    ),
                  ],
                ),
              ),
              if (_post.imageUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _post.imageUrl.length,
                  itemBuilder: (context, i) {
                    return Stack(
                      children: [
                        Image.network(
                          _post.imageUrl[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                        if (fileNames.length > i)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(fileNames[i]),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ] else ...[
                const SizedBox(height: 16),
                const Text('No images uploaded'),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Container(
                  width: double.infinity, // Takes full width from left to right
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [
                        Colors.blue,
                        Colors.purple
                      ], // Specify the gradient colors
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();

                        _post.author =
                            extractUsername(_currentUser.email ?? '');
                        _post.userId = _currentUser.uid;

                        final postDoc = FirebaseFirestore.instance
                            .collection('Posts')
                            .doc();
                        _post.id = postDoc.id;
                        await postDoc.set(await _post.toJson());
                        await sendPushNotificationToAllDevices();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Post added successfully'),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.transparent, // Make button transparent
                      elevation: 0, // Remove button elevation
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            8.0), // Optional: Apply rounded corners to the button
                      ),
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
