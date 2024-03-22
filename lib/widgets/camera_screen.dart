import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  final Function(String path) onPictureTaken;

  CameraScreen({required this.onPictureTaken});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeCameraControllerFuture;
  bool _hasError = false; // Add a flag to check for errors

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  void initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final firstCamera = cameras.first;

        _cameraController = CameraController(
          firstCamera,
          ResolutionPreset.medium,
        );

        _initializeCameraControllerFuture = _cameraController!.initialize();
      } else {
        print('No cameras found on this device.');
        setState(() => _hasError = true);
      }
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() => _hasError = true);
    }
  }

  // @override
  // void onResume() {
  //   //super.onResume();
  //   if (_cameraController != null) {
  //     // Check if camera controller is already initialized
  //     initializeCamera(); // Re-initialize the camera controller
  //   }
  // }
  //
  // @override
  // void onPause() {
  //   //super.onPause();
  //   _cameraController?.dispose(); // Dispose of the camera controller when paused
  // }

  @override
  void dispose() {
    print ('haha disposed');
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a Picture')),
      body: _hasError
          ? Center(child: Text('Error initializing camera.'))
          : FutureBuilder<void>(
        future: _initializeCameraControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_cameraController!);
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: () async {
          if (!_hasError) {
            try {
              final image = await _cameraController!.takePicture();
              widget.onPictureTaken(image.path);
              Navigator.pop(context);
            } catch (e) {
              print(e);
            }
          }
        },
      ),
    );
  }
}
