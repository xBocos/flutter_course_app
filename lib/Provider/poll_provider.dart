import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PollProvider extends ChangeNotifier {
  final titleController = TextEditingController();
  List<TextEditingController> optionNameControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final List<File?> optionImages = [null, null, null];
  final ImagePicker _imagePicker = ImagePicker();
  bool loader = false;
  List<String>? existingImages = [];
  List<dynamic> originalOptions = [];

  Future<void> pickimage(int i) async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 250,
      maxHeight: 250,
      imageQuality: 30,
    );
    if (pickedFile != null) {
      optionImages[i] = File(pickedFile.path);
      notifyListeners();
    }
  }

  void resetForm() {
    titleController.clear();
    optionNameControllers = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    optionImages
      ..clear()
      ..addAll([null, null, null]);
    existingImages?.clear();
    originalOptions.clear();
  }

  void initializePoll(DocumentSnapshot poll) {
    final data = poll.data() as Map<String, dynamic>;
    titleController.text = data['title'] ?? '';

    optionNameControllers.clear();
    optionImages.clear();
    existingImages?.clear();

    originalOptions = List<dynamic>.from(data['options'] ?? []);
    for (var option in originalOptions) {
      optionNameControllers.add(TextEditingController(text: option['name']));
      existingImages?.add(option['imageUrl'] ?? '');
      optionImages.add(null);
    }
  }

  Future<void> submitPoll(String userId, BuildContext context) async {
    if (!validateForm(context)) return;
    loader = true;
    notifyListeners();
    try {
      final pollDoc = FirebaseFirestore.instance.collection('polls').doc();
      final pollId = pollDoc.id;
      final List<dynamic> options = [];

      for (int i = 0; i < 3; i++) {
        String imageBase64 = '';
        if (optionImages[i] != null) {
          final bytes = await optionImages[i]!.readAsBytes();
          imageBase64 = base64Encode(bytes);
        }
        options.add({
          'name': optionNameControllers[i].text,
          'imageUrl': imageBase64,
          'votes': 0,
        });
      }

      await pollDoc.set({
        'pollId': pollId,
        'title': titleController.text,
        'options': options,
        'createdAt': FieldValue.serverTimestamp(),
        'creatorId': userId,
        'total_votes': 0,
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Poll Created Successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      log("Error creating poll: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create Poll: $e")),
      );
    } finally {
      loader = false;
      notifyListeners();
    }
  }

  bool validateForm(BuildContext context) {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Title is required")));
      return false;
    }

    for (int i = 0; i < optionNameControllers.length; i++) {
      if (optionNameControllers[i].text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Option ${i + 1} name is required")),
        );
        return false;
      }

      final bool hasNewImage = optionImages[i] != null;
      final bool hasExistingImage = existingImages != null &&
          i < existingImages!.length &&
          existingImages![i].isNotEmpty;

      if (!hasNewImage && !hasExistingImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please Select an Image for all options"),
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> updatePoll(String pollId, BuildContext context) async {
    if (!validateForm(context)) return;
    loader = true;
    notifyListeners();
    try {
      final List<dynamic> options = [];
      for (int i = 0; i < optionNameControllers.length; i++) {
        String imageData = existingImages?[i] ?? '';
        if (optionImages[i] != null) {
          final bytes = await optionImages[i]!.readAsBytes();
          imageData = base64Encode(bytes);
        }
        options.add({
          'name': optionNameControllers[i].text,
          'imageUrl': imageData,
          'votes': originalOptions[i]['votes'] ?? 0,
          if (originalOptions[i]['voters'] != null)
            'voters': originalOptions[i]['voters'],
        });
      }

      await FirebaseFirestore.instance.collection('polls').doc(pollId).update({
        'title': titleController.text,
        'options': options,
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Poll Edited Successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      log("Error editing poll: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to edit Poll: $e")),
      );
    } finally {
      loader = false;
      notifyListeners();
    }
  }
}
