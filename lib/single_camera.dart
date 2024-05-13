import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async'; 

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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SingleCameraScreen()),
    );
  } else {
    // Handle the case where permission was denied
  }
}

class SingleCameraScreen extends StatefulWidget {
  const SingleCameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<SingleCameraScreen> {
  List<XFile> _takenPictures = [];
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  String? selectedAspectRatio;
  final List<String> _baseAspectRatios = ['9:16', '1:1', '2:3', '3:4'];
  List<String> aspectRatios = [];
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  int _currentRotation = 0;

  Rect _maskRect = Rect.zero;
  Rect _maskTop = Rect.zero;
  Rect _maskBottom = Rect.zero;
  Rect _maskLeft = Rect.zero;
  Rect _maskRight = Rect.zero;

  @override
  void initState() {
    super.initState();
    aspectRatios = _baseAspectRatios;
    selectedAspectRatio = aspectRatios.first;
    _calculateMaskRect();
    _initCamera();
    _setupOrientationListener();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _setupOrientationListener() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        final double threshold = 5; // Adjust sensitivity as needed

        if (event.x.abs() > threshold && event.x > 0) {
          _currentRotation = 270; // Device is on its left side
        } else if (event.x.abs() > threshold && event.x < 0) {
          _currentRotation = 90; // Device is on its right side
        } else if (event.y > threshold) {
          _currentRotation = 0; // Device is upside down
        } else if (event.y < -threshold) {
          _currentRotation = 0; // Device is upright
        }
      },
      onError: (e) {
        print("Error reading accelerometer events: $e");
      }
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateMaskRect();  // Safe to call here, after initialization
  }

  void _cropPreviewToAspectRatio() {
    _calculateMaskRect();
  }

  void _calculateMaskRect() {
    if (_controller == null || !_controller!.value.isInitialized || selectedAspectRatio == null) return;

    var screenSize = MediaQuery.of(context).size;
    var usableScreenHeight = (screenSize.width * 16) / 9;

    var screenAspectRatio = 9 / 16;

    var parts = selectedAspectRatio!.split(':');
    var selectedWidth = double.parse(parts[0]);
    var selectedHeight = double.parse(parts[1]);
    var selectedAspect = selectedWidth / selectedHeight;

    double maskWidth, maskHeight;
    if (selectedAspect > screenAspectRatio) {
      // Mask height will be based on width
      maskWidth = screenSize.width;
      maskHeight = maskWidth / selectedAspect;
    } else {
      // Mask width will be based on height
      maskHeight = usableScreenHeight;
      maskWidth = maskHeight * selectedAspect;
    }

    double topOffset = (usableScreenHeight - maskHeight) / 2;
    double bottomOffset = topOffset + maskHeight;
    double leftOffset = (screenSize.width - maskWidth) / 2;
    double rightOffset = leftOffset + maskWidth;

    setState(() {
      _maskRect = Rect.fromLTWH(leftOffset, topOffset, maskWidth, maskHeight);
      _maskTop = Rect.fromLTWH(0, 0, screenSize.width, topOffset);
      _maskBottom = Rect.fromLTWH(0, bottomOffset, screenSize.width, usableScreenHeight - bottomOffset + 1);//bottomOffset
      _maskLeft = Rect.fromLTWH(0, topOffset, leftOffset, maskHeight);
      _maskRight = Rect.fromLTWH(rightOffset, topOffset, screenSize.width - rightOffset, maskHeight);
    });
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    final firstCamera = _cameras!.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.veryHigh,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (!_controller!.value.isInitialized || !mounted) return;
      setState(() {
        _calculateMaskRect();
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _accelerometerSubscription?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _toggleFlash() async {
    if (_controller != null) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    }
  }

  void _takePicture() async {
    if (!_isCapturing) {
      setState(() {
        _isCapturing = true;  // Set flag to true to indicate capture has started
      });

      try {
        final image = await _controller?.takePicture();
        File imageFile = File(image!.path);
        img.Image? originalImage = img.decodeImage(imageFile.readAsBytesSync());

        if (originalImage != null) {
          originalImage = img.copyRotate(originalImage, angle: _currentRotation.toDouble());
          var parts = selectedAspectRatio!.split(':');
          double aspectWidth = double.parse(parts[0]);
          double aspectHeight = double.parse(parts[1]);

          if (_currentRotation == 90 || _currentRotation == 270) {
            double temp = aspectWidth;
            aspectWidth = aspectHeight;
            aspectHeight = temp;
          }

          double selectedAspect = aspectWidth / aspectHeight;

          int cropWidth, cropHeight;
          if (originalImage.width / originalImage.height > selectedAspect) {
            // Image is wider than the selected aspect ratio
            cropHeight = originalImage.height;
            cropWidth = (originalImage.height * selectedAspect).toInt();
          } else {
            // Image is taller than the selected aspect ratio
            cropWidth = originalImage.width;
            cropHeight = originalImage.width ~/ selectedAspect;
          }

          int offsetX = (originalImage.width - cropWidth) ~/ 2;
          int offsetY = (originalImage.height - cropHeight) ~/ 2;

          // Crop the image
          img.Image croppedImage = img.copyCrop(originalImage, x: offsetX, y: offsetY, width: cropWidth, height: cropHeight);

          // Encode the image back to jpg and overwrite the original file
          imageFile.writeAsBytesSync(img.encodeJpg(croppedImage));
        }
        Navigator.pop(context, XFile(imageFile.path));
      } catch (e) {
        print('Error taking picture: $e');
      } finally {
        _isCapturing = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Update Picture', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            onPressed: _toggleFlash,
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedAspectRatio,
              icon: const Icon(Icons.aspect_ratio, color: Colors.white),
              onChanged: (String? newValue) {
                setState(() {
                  selectedAspectRatio = newValue;
                  _cropPreviewToAspectRatio();
                });
              },
              items: aspectRatios.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              dropdownColor: Colors.black,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Positioned(
                  top: 0,
                  child: Container(
                    width: screenSize.width,
                    height: (screenSize.width * 16) / 9,
                    child: ClipRRect(
                      child: CameraPreview(_controller!),
                    ),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fromRect(rect: _maskTop, child: Container(color: Colors.black)),
                Positioned.fromRect(rect: _maskBottom, child: Container(color: Colors.black)),
                Positioned.fromRect(rect: _maskLeft, child: Container(color: Colors.black)),
                Positioned.fromRect(rect: _maskRight, child: Container(color: Colors.black)),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: _isCapturing ? null : _takePicture,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _isCapturing ? Colors.grey : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      spreadRadius: 4,
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.5),
                    )
                  ]
                ),
              ),
            ),
          ),
        ]
      ) 
    );
  }
}