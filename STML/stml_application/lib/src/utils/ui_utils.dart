import 'package:memoryminder/src/database/model/media_type.dart';
import 'package:memoryminder/src/utils/permission_manager.dart';
import 'package:memoryminder/ui/assistant_screen.dart';
import 'package:memoryminder/src/features/stml_user_dashboard/presentation/stml_user_dashboard.dart';
import 'package:memoryminder/ui/significant_objects_screen.dart';
import 'package:memoryminder/ui/video_screen.dart';
import 'package:flutter/material.dart';

class UiUtils {
  static IconData getMediaIconData(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.audio:
        return Icons.chat;
      case MediaType.photo:
        return Icons.photo;
      case MediaType.video:
        return Icons.video_camera_back;
      default:
        throw Exception('Unsupported media type: $mediaType');
    }
  }

  static BottomNavigationBar createBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
        elevation: 0.0,
        items: const [
          BottomNavigationBarItem(
            backgroundColor: Color.fromARGB(255, 2, 63, 129),
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake_outlined),
            label: 'Virtual Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_camera_back),
            label: 'Video',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (int index) {
          // Handle navigation bar item taps
          if (index == 0) {
            // Navigate to Gallery screen
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => HomeScreen()));
          } else if (index == 1) {
            // Navigate to Search screen
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AssistantScreen()));
          } else if (index == 2) {
            if (PermissionManager.attemptToShowVideoScreen(context)) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VideoScreen()),
              );
            }
          }
          else if (index == 3) {
            // Navigate to Gallery screen
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SignificantObjectScreen()));
          }
        });
  }
}
