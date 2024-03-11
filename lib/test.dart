import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> _checkCameraPermission() async {
  var status = await Permission.camera.status;
  if (!status.isGranted) {
    final result = await Permission.camera.request();
    return result == PermissionStatus.granted;
  }
  return true;
}

Future<void> _openCamera(BuildContext context) async {
  if (await _checkCameraPermission()) {
    // Permissions are granted, open the camera screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
  } else {
    // Handle the case where permission was denied
    // You might want to show an alert or some other UI to inform the user
  }
}


class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  int _picturesTaken = 0;
  List<XFile> _takenPictures = [];


  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Obtain a list of the available cameras on the device.
    _cameras = await availableCameras();

    // Get a specific camera from the list of available cameras.
    final firstCamera = _cameras!.first;

    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      firstCamera,
      // Define the resolution to use.
      ResolutionPreset.veryHigh,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller!.initialize().then((_) async {
      // Ensure the camera is initialized before displaying the camera preview.
      if (_controller!.value.isInitialized) {
        await _controller!.setFocusMode(FocusMode.auto);
      }

      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller?.dispose();
    super.dispose();
  }

  void _takePicture() async {
    if (_picturesTaken < 2) {
      // Assuming _controller is your CameraController
      final image = await _controller?.takePicture();
      _takenPictures.add(image!);

      setState(() {
        _picturesTaken++;
      });

      if (_picturesTaken == 2) {
        // Once two pictures are taken, return to the main menu with the pictures
        Navigator.pop(context, _takenPictures);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Take Picture ${_picturesTaken + 1}'),
        ),
      // You must wait until the controller is initialized before displaying the camera preview.
      // Use a FutureBuilder to display a loading spinner until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller!);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

}