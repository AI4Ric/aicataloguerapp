import 'dart:io';
import 'package:camera/camera.dart';
import 'package:aicataloguer/test.dart'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ImageList()),
        ChangeNotifierProvider(create: (context) => FieldSelector()),
      ],
      child: const MyApp(),
    ),
  );
}

enum SelectedField { none, vendor, lot }

class ImageList extends ChangeNotifier {
  List<XFile>? images = [];
  bool get hasImages => images != null && images!.isNotEmpty;
  bool get hasTwoImages => images != null && images!.length == 2;

  void updateImages(List<XFile> newImages) {
    images = newImages;
    notifyListeners();
  }

  void clearImages() async {
    if (images != null){
      for (XFile image in images!) {
        try {
          File file = File(image.path);
          await file.delete();
        } catch (e) {
          print("Error deleting image: ${image.path}, $e");
        }
      }
    }
    images = [];
    notifyListeners();
  }
}

class FieldSelector extends ChangeNotifier {
  SelectedField selectedField = SelectedField.vendor;
  TextEditingController vendorController = TextEditingController();
  TextEditingController lotController = TextEditingController();

  void selectVendor() {
    selectedField = SelectedField.vendor;
    notifyListeners();
  }

  void selectLot() {
    selectedField = SelectedField.lot;
    notifyListeners();
  }

  bool autoIncrement = false;

  void toggleAutoIncrement() {
    autoIncrement = !autoIncrement;
    notifyListeners();
  }
}

Widget buildNumberButton(BuildContext context, String number) {
  return Expanded(
    child: InkWell(
      onTap: () {
        final appData = Provider.of<FieldSelector>(context, listen: false);
        if (appData.selectedField == SelectedField.vendor) {
          if (appData.vendorController.text.length < 6) {
            appData.vendorController.text += number;
          }
        } else if (appData.selectedField == SelectedField.lot) {
          if (appData.lotController.text.length < 3) {
            appData.lotController.text += number;
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5), // Optional: adds rounded corners
        ),
        child: Center(
          child: Text(number, style: const TextStyle(fontSize: 24, color: Colors.grey)), 
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'aicataloguer',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: <Widget>[
            Builder(builder: (context){
              return IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
                  );
                },
              );
            },
          ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey,
              height: 1.0,
            ),
          ),
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            return orientation == Orientation.landscape
                ? const LandscapeLayout()
                : const PortraitLayout();
          },
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy and Policy'),
      ),
      body: FutureBuilder<String>(
        future: DefaultAssetBundle.of(context).loadString('assets/privacy_policy.txt'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading the privacy policy'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: MarkdownBody(data: snapshot.data ?? ''),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}



class LandscapeLayout extends StatelessWidget {
  const LandscapeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(flex: 2,child: TopBlock()),
        Expanded(child: BottomBlockP()),
      ],
    );
  }
}

class PortraitLayout extends StatelessWidget {
  const PortraitLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        Expanded(flex: 2, child: TopBlock()),
        Expanded(flex: 1, child: BottomBlock()),
      ],
    );
  }
}

class TopBlock extends StatelessWidget {
  const TopBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        Expanded(flex: 2, child: ImagesContainer()),
        Expanded(child: VariablesBlock()),
      ],
    );
  }
}

class ImagesContainer extends StatelessWidget {
  const ImagesContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        Expanded(child: ImagesTags()),
        Expanded(flex: 3, child: ImagesPreview()),
      ],
    );
  }
}

class ImagesTags extends StatelessWidget {
  const ImagesTags({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 50.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: Colors.blue, width: 3),
              ),
              child: Text(
                'Image 01',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 50.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: Colors.blue, width: 3),
              ),
              child: Text(
                'Image 02',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ),
      ],
    );
  }
}



class ImagesPreview extends StatelessWidget{
  const ImagesPreview({super.key});

  @override
  Widget build(BuildContext context){
    final imageList = Provider.of<ImageList>(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: imageList.images!.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.file(File(imageList.images![0].path)),
              )
              : Center(
                child: Image.asset('assets/images/ImagePlaceholder.png'),
              ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: imageList.images!.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.file(File(imageList.images![1].path)),
              )
              : Center(
                child: Image.asset('assets/images/ImagePlaceholder.png'),
              ),
          ),
        ),
      ],
    );
  }
}

class VariablesBlock extends StatelessWidget {
  const VariablesBlock({super.key});

  @override
  Widget build(BuildContext context){
    final fieldSelector = Provider.of<FieldSelector>(context);
    final imageList = Provider.of<ImageList>(context);
    return Column(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Row(
            children: <Widget>[
              const Expanded(child: LotDisplay()),
              Expanded(
                child: Center(
                  child: CheckboxListTile(
                    title: const Text("Auto Increment"),
                    value: fieldSelector.autoIncrement, 
                    onChanged: (bool? newValue) {
                      fieldSelector.toggleAutoIncrement();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: <Widget>[
              Expanded(child: VendorDisplay()),
              if (imageList.hasImages)
                Expanded(
                  child: Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.delete_outline, color: Colors.white),
                      label: Text('Discard', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Provider.of<ImageList>(context, listen: false).clearImages();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                )
              else
                Expanded(child: Center(child: Text(''))),
            ],
          ),
        ),
      ],
    );
  }
}

class VendorDisplay extends StatelessWidget {
  const VendorDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<FieldSelector>(context);
    return IgnorePointer(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
        child: TextFormField(
          controller: appData.vendorController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Vendor Number',
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 2, color: Colors.blueAccent),
            ),
          ),
          inputFormatters: [LengthLimitingTextInputFormatter(6)],
        ),
      ),
    );
  }
}

class LotDisplay extends StatelessWidget {
  const LotDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<FieldSelector>(context);
    return IgnorePointer(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
        child: TextFormField(
          controller: appData.lotController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Lot Number',
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 2, color: Colors.blueAccent),
            ),
          ),
          inputFormatters: [LengthLimitingTextInputFormatter(3)],
        ),
      ),
    );
  }
}

class SettinsSelect extends StatelessWidget{
  const SettinsSelect({super.key});

  @override
  Widget build(BuildContext context){
    return Consumer<FieldSelector>(
      builder: (context, fieldSelector, child) {
        final Color lotSelectedColor = fieldSelector.selectedField == SelectedField.lot ? Colors.blue : Colors.grey;
        final Color vendorSelectedColor = fieldSelector.selectedField == SelectedField.vendor ? Colors.blue : Colors.grey;

        return Row(
          children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: () {
                  fieldSelector.selectLot();
                },
                child: Container(
                  color: lotSelectedColor,
                  child: const Center(
                    child: Text(
                      'Lot Number',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      ),),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  fieldSelector.selectVendor();
                },
                child: Container(
                  color: vendorSelectedColor,
                  child: const Center(
                    child: 
                    Text(
                      'Vendor Number',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      ),),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BottomBlock extends StatelessWidget {
  const BottomBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        Expanded(child: SettinsSelect()),
        Expanded(
          flex: 3,
          child: KeyPad(),
        ),
        Expanded(child: ActionB()),
      ],
    );
  }
}

class BottomBlockP extends StatelessWidget {
  const BottomBlockP({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Expanded(child: SettinsSelect()),
          Expanded(flex: 5,child: Container(
            child: Row(
              children: [
                Expanded(flex: 3,child: KeyPad()),
                Expanded(child: ActionB_P()),
              ],
            ),
          ))],
      ),
    );
  }
}

List<Widget> buildButtons(BuildContext context, ImageList imageList, FieldSelector fieldSelector ) {
  return [
    buildNumberButton(context, '0'),
    if (imageList.hasImages)
      buildSaveButton(context, imageList, fieldSelector)
    else
      buildCameraButton(context),
    Expanded(
      child: InkWell(
        onTap: () {
          if (fieldSelector.selectedField == SelectedField.vendor && fieldSelector.vendorController.text.isNotEmpty) {
            fieldSelector.vendorController.text = fieldSelector.vendorController.text.substring(0, fieldSelector.vendorController.text.length - 1);
          } else if (fieldSelector.selectedField == SelectedField.lot && fieldSelector.lotController.text.isNotEmpty) {
            fieldSelector.lotController.text = fieldSelector.lotController.text.substring(0, fieldSelector.lotController.text.length - 1);
          }
        },
        child: Container(
          child: const Icon(Icons.backspace_outlined),
        ),
      ), 
    ),
  ];
}

class ActionB extends StatelessWidget {
  const ActionB({super.key});

  @override
  Widget build(BuildContext context){

    final imageList = Provider.of<ImageList>(context);
    final fieldSelector = Provider.of<FieldSelector>(context);

    return Row(children: buildButtons(context, imageList,fieldSelector));
  }
}

class ActionB_P extends StatelessWidget {
  const ActionB_P({super.key});

  @override
  Widget build(BuildContext context){

    final imageList = Provider.of<ImageList>(context);
    final fieldSelector = Provider.of<FieldSelector>(context);

    return Column(children: buildButtons(context, imageList, fieldSelector));
  }
}



Widget buildCameraButton(BuildContext context) {
  return Expanded(
    child: InkWell(
      onTap: () async {
        final List<XFile>? returnedImages = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
        if (returnedImages != null) {
          Provider.of<ImageList>(context, listen: false).updateImages(returnedImages);
        }
      },
      child: Container(
        child: const Icon(Icons.camera_alt),
      ),
    ),
  );
}

Widget buildSaveButton(BuildContext context, ImageList imageList, FieldSelector fieldSelector) {
  return Expanded(
    child: InkWell(
      onTap: () async {
        for (int i = 0; i < imageList.images!.length; i++) {
          final image = imageList.images![i];

          try {
            File rotatedImage = await FlutterExifRotation.rotateImage(path: image.path);
            final byteData = await image.readAsBytes();
            String lotNumber = fieldSelector.lotController.text.isEmpty ? "000" : fieldSelector.lotController.text;
            String vendorNumber = fieldSelector.vendorController.text.isEmpty ? "9999" : fieldSelector.vendorController.text;
            String originalFileName = path.basenameWithoutExtension(rotatedImage.path);
            String customFileName = "${lotNumber}_C$vendorNumber${i == 1 ? '_2' : ''}_$originalFileName.jpg";
            print("Rotated image path:");
            print(image.path);
            if (Platform.isIOS) {
              print("Saving on IOS");
              File savedFile = await saveImageToFile(byteData, customFileName);
              await rotatedImage.delete();
            } else if (Platform.isAndroid) {
              print("Saving on android");
              final result = await ImageGallerySaver.saveImage(
                byteData,
                name: customFileName,
              );
            }
          } catch (e) {
            print("An error ocurred while saving the image: $e");
          }
        }

        if (fieldSelector.autoIncrement) {
          int currentLotNumber = int.tryParse(fieldSelector.lotController.text) ?? 0;
          fieldSelector.lotController.text = (currentLotNumber  + 1).toString(); //.padLeft(3, '0')
        }

        imageList.clearImages();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Images saved successfully')));

      },
      child: Container(
        child: const Icon(Icons.save),
      ),
    ),
  );
}

Future<File> saveImageToFile(Uint8List imageData, String imageName) async {
  // Get the directory to save the image
  final directory = await getApplicationDocumentsDirectory();

  // Create a file path with your custom file name
  final imagePath = '${directory.path}/$imageName';

  // Create a file at the path
  final imageFile = File(imagePath);

  // Write the image data to the file
  await imageFile.writeAsBytes(imageData);

  return imageFile;
}

class KeyPad extends StatelessWidget {
  const KeyPad({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              buildNumberButton(context, '7'),
              buildNumberButton(context, '8'),
              buildNumberButton(context, '9'),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              buildNumberButton(context, '4'),
              buildNumberButton(context, '5'),
              buildNumberButton(context, '6'),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              buildNumberButton(context, '1'),
              buildNumberButton(context, '2'),
              buildNumberButton(context, '3'),
            ],
          ),
        ),
      ],
    );
  }
}







