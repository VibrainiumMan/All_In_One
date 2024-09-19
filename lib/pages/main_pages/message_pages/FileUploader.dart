import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';

class FileUploader {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;

  Future<void> initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  Future<void> startRecording() async {
    await _recorder.startRecorder(toFile: 'voice_message.mp4');
    _isRecording = true;
  }

  Future<void> stopRecordingAndUpload() async {
    final path = await _recorder.stopRecorder();
    _isRecording = false;
    if (path != null) {
      await _sendVoiceMessage(path);
    }
  }

  Future<void> _sendVoiceMessage(String path) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String fileName = path.split('/').last;
      Reference storageRef = FirebaseStorage.instance.ref().child('voiceMessages/$fileName');
      UploadTask uploadTask = storageRef.putFile(File(path));

      try {
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String userName = userSnapshot.get('name');
        String userAvatar = userSnapshot.get('avatar');

        FirebaseFirestore.instance.collection('messages').add({
          'type': 'voice',
          'url': downloadUrl,
          'sender': user.uid,
          'senderName': userName,
          'senderAvatar': userAvatar,
          'timestamp': FieldValue.serverTimestamp(),
          'isPrivate': false,
        });
      } catch (e) {
        print('Error uploading voice message: $e');
      }
    }
  }

  Future<void> pickFileAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      _sendFileMessage(file.path!);
    }
  }

  void dispose() {
    _recorder.closeRecorder();
  }

  Future<void> _sendFileMessage(String filePath) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String fileName = filePath.split('/').last;
      Reference storageRef = FirebaseStorage.instance.ref().child('uploadedFiles/$fileName');
      UploadTask uploadTask = storageRef.putFile(File(filePath));

      try {
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String userName = userSnapshot.get('name');
        String userAvatar = userSnapshot.get('avatar');

        FirebaseFirestore.instance.collection('messages').add({
          'type': 'file',
          'url': downloadUrl,
          'fileName': fileName,
          'sender': user.uid,
          'senderName': userName,
          'senderAvatar': userAvatar,
          'timestamp': FieldValue.serverTimestamp(),
          'isPrivate': false,
        });
      } catch (e) {
        print('Error uploading file message: $e');
      }
    }
  }
}