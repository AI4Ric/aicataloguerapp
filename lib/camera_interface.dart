import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _checkAndRequestCameraPermissions().then((hasPermissions) {
      if (hasPermissions) {
        _initCamera();
      } else {
        // Handle the case where camera permissions are not granted
        print('Camera permission was not granted.');
      }
    });
  }

  Future<bool> _checkAndRequestCameraPermissions() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    return true; // Permissions are already granted
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.isNotEmpty ? cameras.first : null;

    if (firstCamera != null) {
      _controller = CameraController(firstCamera, ResolutionPreset.veryHigh);
      _initializeControllerFuture = _controller?.initialize().then((_) {
        if (!mounted) return;
        setState(() {}); // Rebuild the widget after camera initialization
      }).catchError((e) {
        print(e); // Log any errors for debugging
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capture Image')),
      // Ensure the FutureBuilder is linked to _initializeControllerFuture
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _controller != null) {
            return CameraPreview(_controller!); // Display the camera preview if the Future is complete
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return const Center(child: CircularProgressIndicator()); // Otherwise, show a loading indicator
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement your action for taking pictures
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
