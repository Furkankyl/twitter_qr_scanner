#import "TwitterQrScannerPlugin.h"
#if __has_include(<twitter_qr_scanner/twitter_qr_scanner-Swift.h>)
#import <twitter_qr_scanner/twitter_qr_scanner-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "twitter_qr_scanner-Swift.h"
#endif

@implementation TwitterQrScannerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTwitterQrScannerPlugin registerWithRegistrar:registrar];
}
@end
