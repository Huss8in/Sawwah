import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'MapSelectionScreen.dart';

class EditPostScreen extends StatefulWidget {
  static const routeName = '/edit_post';
  final Post post;

  EditPostScreen({required this.post});

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _bodyController = TextEditingController(text: widget.post.body);
    _locationController = TextEditingController(text: widget.post.location);
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final String newTitle = _titleController.text;
      final String newBody = _bodyController.text;
      final String newLocation = _locationController.text;

      try {
        // Update the post document in Firestore
        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(widget.post.id)
            .update(
                {'title': newTitle, 'body': newBody, 'location': newLocation});

        print('Post updated successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated')),
        );

        // Navigate back to the previous screen
        Navigator.pop(context);
        Navigator.pop(context);
      } catch (error) {
        print('Failed to update post: $error');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update post')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Post',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController, // Set the controller
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _bodyController, // Set the controller
                decoration: const InputDecoration(
                  labelText: 'Body',
                ),
                maxLines: null,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a body';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
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
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
