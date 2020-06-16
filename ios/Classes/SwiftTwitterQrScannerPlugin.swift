import Flutter
import UIKit

public class SwiftTwitterQrScannerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let viewFactory = QRViewFactory(withRegistrar: registrar)
    let channel = FlutterMethodChannel(name: "twitter_qr_scanner", binaryMessenger: registrar.messenger())
    let instance = SwiftTwitterQrScannerPlugin()
    registrar.register(viewFactory, withId: "com.anka.twitter_qr_scanner/qrview")
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
