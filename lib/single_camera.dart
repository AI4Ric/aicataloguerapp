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
      MaterialPageRoute(builder: (context) => const SingleCameraScreen()),
    );
  } else {
    // Handle the case where permission was denied
    // You might want to show an alert or some other UI to inform the user
  }
}


class SingleCameraScreen extends StatefulWidget {
  const SingleCameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<SingleCameraScreen> {
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

  bool _isFlashOn = false;
  void _toggleFlash() async {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });

    if (_controller != null) {
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    }
  }



  void _takePicture() async {
    if (_controller != null) {
      try {
        final image = await _controller!.takePicture();
        Navigator.pop(context, image); // Return the single XFile and pop the screen
      } catch (e) {
        // You might want to handle any errors that occur during picture taking
        print("Error taking picture: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Picture'),
        actions: [
          IconButton(
            onPressed: _toggleFlash, 
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
          ),
        ],
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

