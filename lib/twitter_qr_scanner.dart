library twitter_qr_scanner;

import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';


typedef void QRViewCreatedCallback(QRViewController controller);

class QRView extends StatefulWidget {
  const QRView({
    required GlobalKey<State<StatefulWidget>> key,
    required this.onQRViewCreated,
    required this.data,
    required this.overlay,
    this.qrCodeBackgroundColor = Colors.blue,
    this.qrCodeForegroundColor = Colors.white,
    this.switchButtonColor = Colors.white,

  })  : super(key: key);

  final QRViewCreatedCallback onQRViewCreated;

  final ShapeBorder overlay;
  final String data;
  final Color qrCodeBackgroundColor;
  final Color qrCodeForegroundColor;
  final Color switchButtonColor;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  bool isScanMode = true;
  CarouselSlider? slider;
  var flareAnimation = "view";
  CarouselController _controller = CarouselController();

  getSlider(){
    setState(() {


      slider = CarouselSlider(
        carouselController: _controller,
        items: [
          Container(
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: widget.overlay,
            ),
          ),
          Container(
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: widget.overlay,
            ),
            child: Container(
              width: 240,
              height: 240,
              padding: EdgeInsets.all(21),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: widget.qrCodeBackgroundColor,
              ),
              child: QrImage(
                data: widget.data,
                version: QrVersions.auto,
                foregroundColor: widget.qrCodeForegroundColor,
                gapless: true,
              ),
            ),
          ),
        ],
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height,
          viewportFraction: 1.0,
          enableInfiniteScroll: false,
          onPageChanged: (index,reason) {
            setState(() {
              isScanMode = index == 0;
              if(isScanMode) {
                flareAnimation = "scanToView";
              }else {
                flareAnimation = "viewToScan";
              }
            });
          },
        ),
      );
    });
    return slider;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _getPlatformQrView(),
         getSlider(),
        Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
              child: IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.white70,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: InkWell(

            onTap: () {
              setState(() {

                isScanMode = !isScanMode;
                if(isScanMode) {
                  flareAnimation = "scanToView";
                  _controller.previousPage(duration: Duration(milliseconds: 500),
                      curve: Curves.linear);
                }else {
                  flareAnimation = "viewToScan";

                  _controller.nextPage(duration: Duration(milliseconds: 500),
                      curve: Curves.linear);
                }
              });
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(255),
              ),
              child: ClipRRect(

                borderRadius: BorderRadius.circular(255),
                child: FlareActor("packages/twitter_qr_scanner/asset/QRButton.flr",
                  alignment: Alignment.center,
                  animation: flareAnimation,
                  fit: BoxFit.contain,
                  color: widget.switchButtonColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getPlatformQrView() {
    Widget _platformQrView;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        _platformQrView = AndroidView(
          viewType: 'com.anka.twitter_qr_scanner/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
        );
        break;
      case TargetPlatform.iOS:
        _platformQrView = UiKitView(
          viewType: 'com.anka.twitter_qr_scanner/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams: _CreationParams.fromWidget(0, 0).toMap(),
          creationParamsCodec: StandardMessageCodec(),
        );
        break;
      default:
        throw UnsupportedError(
            "Trying to use the default webview implementation for $defaultTargetPlatform but there isn't a default one");
    }
    return _platformQrView;
  }

  void _onPlatformViewCreated(int id) async{
    widget.onQRViewCreated(QRViewController._(id,widget.key as GlobalKey<State<StatefulWidget>>));
  }
}

class _CreationParams {
  _CreationParams({required this.width, required this.height});

  static _CreationParams fromWidget(double width, double height) {
    return _CreationParams(
      width: width,
      height: height,
    );
  }

  final double width;
  final double height;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': width,
      'height': height,
    };
  }
}

class QRViewController {
  static const scanMethodCall = "onRecognizeQR";

  final MethodChannel _channel;

  StreamController<String> _scanUpdateController = StreamController<String>();

  Stream<String> get scannedDataStream => _scanUpdateController.stream;

  QRViewController._(int id, GlobalKey qrKey)
      : _channel = MethodChannel('com.anka.twitter_qr_scanner/qrview_$id') {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final RenderBox renderBox = qrKey.currentContext!.findRenderObject() as RenderBox;
      _channel.invokeMethod("setDimensions",
          {"width": renderBox.size.width, "height": renderBox.size.height});
    }
    _channel.setMethodCallHandler(
          (MethodCall call) async {
        switch (call.method) {
          case scanMethodCall:
            if (call.arguments != null) {
              _scanUpdateController.sink.add(call.arguments.toString());
            }
        }
      },
    );
  }

  void flipCamera() {
    _channel.invokeMethod("flipCamera");
  }

  void toggleFlash() {
    _channel.invokeMethod("toggleFlash");
  }

  void pauseCamera() {
    _channel.invokeMethod("pauseCamera");
  }

  void resumeCamera() {
    _channel.invokeMethod("resumeCamera");
  }

  void dispose() {
    _scanUpdateController.close();
  }
}
