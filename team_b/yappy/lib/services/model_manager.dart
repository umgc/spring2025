import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'toast_service.dart';

class ModelManager {
  // Base directory for storing models
  late final Future<String> _modelDirPath;
  
  // Model information with URLs and extraction details
  final List<ModelInfo> _models = [
    ModelInfo(
      name: 'Speaker Recognition Model',
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/speaker-recongition-models/3dspeaker_speech_eres2net_sv_en_voxceleb_16k.onnx',
      isCompressed: false,
      size: 25.3, // Size in MB
    ),
    ModelInfo(
      name: 'Offline Whisper Model (Tiny)',
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-tiny.en.tar.bz2',
      isCompressed: true,
      keepPaths: ['sherpa-onnx-whisper-tiny.en/tiny.en-tokens.txt', 'sherpa-onnx-whisper-tiny.en/tiny.en-decoder.int8.onnx', 'sherpa-onnx-whisper-tiny.en/tiny.en-encoder.int8.onnx'],
      size: 113, // Size in MB
    ),
    ModelInfo(
      name: 'Online Zipformer Model',
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17-mobile.tar.bz2',
      isCompressed: true,
      keepPaths: ['sherpa-onnx-streaming-zipformer-en-20M-2023-02-17-mobile/tokens.txt', 'sherpa-onnx-streaming-zipformer-en-20M-2023-02-17-mobile/decoder-epoch-99-avg-1.onnx', 'sherpa-onnx-streaming-zipformer-en-20M-2023-02-17-mobile/encoder-epoch-99-avg-1.int8.onnx', 'sherpa-onnx-streaming-zipformer-en-20M-2023-02-17-mobile/joiner-epoch-99-avg-1.int8.onnx'],
      size: 103, // Size in MB
    ),
  ];
  
  // Toast service
  final _toastService = ToastService();
  
  ModelManager() {
    _modelDirPath = _initModelDir();
  }
  
  // Initialize the models directory
  Future<String> _initModelDir() async {
    final appDir = await getApplicationCacheDirectory();
    final modelDir = Directory('${appDir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }
  
  // Check if all required models exist
  Future<bool> modelsExist() async {
    try {
      final modelDir = await _modelDirPath;
      
      // Check for a marker file indicating successful model installation
      final markerFile = File('$modelDir/models_installed.txt');
      if (await markerFile.exists()) {
        return true;
      }
      
      // Check individual models if marker doesn't exist
      for (var model in _models) {
        final modelFile = File('$modelDir/${model.getFilename()}');
        if (!await modelFile.exists()) {
          return false;
        }
      }
      
      // If all models exist but marker doesn't, create the marker
      await markerFile.writeAsString('Models installed on ${DateTime.now()}');
      return true;
    } catch (e) {
      debugPrint('Error checking models: $e');
      return false;
    }
  }
  
  // Check if we should only download on Wi-Fi
  Future<bool> _getWifiOnlySetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('wifi_only_downloads') ?? true; // Default to true
  }

  // Save Wi-Fi only setting
  Future<void> saveWifiOnlySetting(bool wifiOnly) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wifi_only_downloads', wifiOnly);
  }

  // Check network connectivity
  Future<bool> _checkConnectivity() async {
    final wifiOnly = await _getWifiOnlySetting();
    
    if (!wifiOnly) {
      return true; // Download allowed on any connection
    }
    
    // Check for WiFi connection
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.wifi);
  }
  
  // Show download dialog to user
  Future<bool> showDownloadDialog(BuildContext context) async {
    // Calculate total download size
    final totalSize = _models.fold(0.0, (sum, model) => sum + model.size);
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Download AI Models'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This app requires downloading speech recognition models '
                  'to function properly (${totalSize.toStringAsFixed(1)} MB total).',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Models will be downloaded when connected to WiFi. '
                  'You can change this in Settings later.',
                ),
                const SizedBox(height: 16),
                const Text('Models to download:'),
                ...List.generate(_models.length, (index) {
                  final model = _models[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '• ${model.name} (${model.size.toStringAsFixed(1)} MB)',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Later'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Download Now'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed
  }
  
  // Show connectivity warning dialog
  Future<bool> _showConnectivityWarning(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Wi-Fi Required'),
          content: const Text(
            'You have selected to download models only on Wi-Fi. '
            'Please connect to a Wi-Fi network or change your settings to continue.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Change Setting'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed
  }

  // Check if downloads are currently in progress
  bool isDownloadInProgress() {
    return _toastService.isToastVisible;
  }
  
  // Download all models
  Future<bool> downloadModels(BuildContext context) async {
    // Check connectivity first - still need context for initial dialogs
    final canDownload = await _checkConnectivity();
    if (!canDownload) {
      final changeSettings = await _showConnectivityWarning(context);
      if (changeSettings) {
        // User wants to change settings
        await saveWifiOnlySetting(false);
      } else {
        // User canceled download
        return false;
      }
    }
    
    // Start async download process
    _startDownloadProcess();
    
    // Return true to indicate the download has started
    return true;
  }
  
  // Handle the download process independently of any specific context
  Future<void> _startDownloadProcess() async {
    try {
      // Show initial toast notification
      _toastService.showToast('Starting downloads...', progress: 0.0);
      
      final modelDir = await _modelDirPath;
      int completedModels = 0;
      
      // Process each model
      for (var model in _models) {
        // Update progress
        _toastService.showToast(
          'Downloading ${model.name}...',
          progress: completedModels / _models.length,
        );
        
        // Download file
        final response = await http.get(Uri.parse(model.url));
        if (response.statusCode != 200) {
          throw Exception('Failed to download ${model.name}');
        }
        
        // Process based on file type
        if (model.isCompressed) {
          // Update progress
          _toastService.showToast(
            'Extracting ${model.name}...',
            progress: completedModels / _models.length,
          );
          
          // Handle compressed .bz2 file
          await _processCompressedFile(
            response.bodyBytes,
            modelDir,
            model.keepPaths ?? [],
          );
        } else {
          // Handle direct .onnx file
          final file = File('$modelDir/${model.getFilename()}');
          await file.writeAsBytes(response.bodyBytes);
        }
        
        completedModels++;
        _toastService.updateProgress(completedModels / _models.length);
      }
      
      // Create marker file to indicate successful installation
      final markerFile = File('$modelDir/models_installed.txt');
      await markerFile.writeAsString('Models installed on ${DateTime.now()}');
      
      // Hide toast and show success toast
      _toastService.hideToast();
      _toastService.showSuccess('All models have been downloaded successfully.');
      
    } catch (e) {
      debugPrint('Error downloading models: $e');
      
      // Hide progress toast
      _toastService.hideToast();
      
      // Show error toast
      _toastService.showError('Failed to download models: $e');
    }
  }
  
  // Process compressed .bz2 file
  Future<void> _processCompressedFile(
    List<int> fileBytes,
    String modelDir,
    List<String> keepPaths,
  ) async {
    // Decompress bz2
    final archive = BZip2Decoder().decodeBytes(fileBytes);
    
    // Extract tar archive
    final tarArchive = TarDecoder().decodeBytes(archive);
    
    // Process each file in the archive
    for (final file in tarArchive) {
      // Check if this file/directory should be kept
      bool shouldKeep = keepPaths.isEmpty;
      for (final keepPath in keepPaths) {
        if (file.name.startsWith(keepPath)) {
          shouldKeep = true;
          break;
        }
      }
      
      if (shouldKeep) {
        final filePath = '$modelDir/${file.name}';
        
        if (file.isFile) {
          // Create parent directories if needed
          final parentDir = Directory(path.dirname(filePath));
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }
          
          // Write file
          await File(filePath).writeAsBytes(file.content as List<int>);
        } else {
          // Create directory
          await Directory(filePath).create(recursive: true);
        }
      }
    }
  }
  
  // Delete all downloaded models
  Future<bool> deleteModels() async {
    try {
      final modelDir = await _modelDirPath;
      final directory = Directory(modelDir);
      
      if (await directory.exists()) {
        // Get all immediate children first
        List<FileSystemEntity> children = await directory.list().toList();
        
        // Delete each child recursively
        for (var entity in children) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            // Log but continue with other deletions
            debugPrint('Error deleting ${entity.path}: $e');
          }
        }
      }
      
      // Double-check the marker file
      final markerFile = File('$modelDir/models_installed.txt');
      if (await markerFile.exists()) {
        await markerFile.delete();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error deleting models: $e');
      return false;
    }
  }
  
  // Trigger model download from settings page
  Future<bool> downloadModelsFromSettings(BuildContext context) async {
    final shouldDownload = await showDownloadDialog(context);
    if (shouldDownload) {
      return await downloadModels(context);
    }
    return false;
  }
}

class ModelInfo {
  final String name;
  final String url;
  final bool isCompressed;
  final List<String>? keepPaths;
  final double size; // Size in MB
  
  ModelInfo({
    required this.name,
    required this.url,
    required this.isCompressed,
    this.keepPaths,
    required this.size,
  });
  
  String getFilename() {
    return path.basename(url);
  }
}