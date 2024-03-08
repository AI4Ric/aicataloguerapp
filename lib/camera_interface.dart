import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  FlashMode _flashMode = FlashMode.off; // Default flash mode is 'off'

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(); // Display a loading indicator or a placeholder
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Take a Photo'),
        actions: <Widget>[
          IconButton(
            icon: Icon(_getFlashIcon(_flashMode)),
            onPressed: () {
              setState(() {
                _flashMode = FlashMode.values[(_flashMode.index + 1) % FlashMode.values.length];
                _controller!.setFlashMode(_flashMode);
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Expanded(
            child: CameraPreview(_controller!), 
          ),
        ],
      ),
      floatingActionButton: Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Center(
          child: FloatingActionButton(
            onPressed: _takePicture,
            child: const Icon(Icons.camera),
          ),
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final image = await _controller!.takePicture();
        // Handle the captured image, e.g., display or save it
      } catch (e) {
        // Handle errors
        print(e); // Consider using proper error handling
      }
    }
  }

  IconData _getFlashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
      case FlashMode.torch:
        return Icons.flash_on;
      default:
        return Icons.flash_off;
    }
  }
}
