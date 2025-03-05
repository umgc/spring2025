package com.spring2025.yappy;

import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.media.MediaScannerConnection;
import android.net.Uri;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "com.yourcompany.yappy/files";

  @Override
  public void configureFlutterEngine(FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
      .setMethodCallHandler(
        (call, result) -> {
          if (call.method.equals("scanFile")) {
            String filePath = (String) call.argument("filePath");
            scanFile(filePath);
            result.success(null);
          } else {
            result.notImplemented();
          }
        }
      );
  }

  private void scanFile(String path) {
    MediaScannerConnection.scanFile(this, new String[]{path}, null, (path1, uri) -> {
      // File scanned
    });
  }
}