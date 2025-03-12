import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'toast_service.dart';

// Data class for passing to isolate
class ExtractionData {
  final List<int> fileBytes;
  final String modelDir;
  final List<OutputFileMapping> outputMappings;
  final SendPort sendPort;

  ExtractionData({
    required this.fileBytes,
    required this.modelDir,
    required this.outputMappings,
    required this.sendPort,
  });
}

// Class for mapping source files to destination names
class OutputFileMapping {
  final String source;
  final String destination;
  
  OutputFileMapping({
    required this.source,
    required this.destination,
  });
  
  // Factory constructor from JSON
  factory OutputFileMapping.fromJson(Map<String, dynamic> json) {
    return OutputFileMapping(
      source: json['source'],
      destination: json['destination'],
    );
  }
}

class ModelInfo {
  final String id;
  final String name;
  final String url;
  final bool isCompressed;
  final String type;
  final String? modelType;
  final List<OutputFileMapping> outputFiles;
  final double size; // Size in MB
  
  ModelInfo({
    required this.id,
    required this.name,
    required this.url,
    required this.isCompressed,
    required this.type,
    this.modelType,
    required this.outputFiles,
    required this.size,
  });
  
  // Factory constructor to create ModelInfo from JSON
  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    final outputFilesJson = json['outputFiles'] as List<dynamic>;
    
    return ModelInfo(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      isCompressed: json['isCompressed'],
      type: json['type'],
      modelType: json['modelType'],  // Added modelType
      outputFiles: outputFilesJson
          .map((fileJson) => OutputFileMapping.fromJson(fileJson))
          .toList(),
      size: json['size'],
    );
  }
  
  String getFilename() {
    return path.basename(url);
  }
}

class ModelManager {
  // Base directory for storing models
  late final Future<String> _modelDirPath;
  
  // List to hold models loaded from config
  List<ModelInfo> _models = [];
  
  // Config file path in assets
  static const String _configAssetPath = 'assets/models_config.json';
  
  final _toastService = ToastService();
  
  ModelManager() {
    _modelDirPath = _initModelDir();
    _loadModelsFromConfig();
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
  
  // Load models from the config file
  Future<void> _loadModelsFromConfig() async {
    try {
      // Load the JSON file from assets
      final String jsonContent = await rootBundle.loadString(_configAssetPath);
      final Map<String, dynamic> configData = json.decode(jsonContent);
      
      // Parse models
      final List<dynamic> modelsJson = configData['models'];
      _models = modelsJson.map((modelJson) => ModelInfo.fromJson(modelJson)).toList();
      
      debugPrint('Loaded ${_models.length} models from config');
    } catch (e) {
      debugPrint('Error loading models from config: $e');
      // Fallback to empty list
      _models = [];
    }
  }
  
  // Reload models from config
  Future<void> reloadModelsConfig() async {
    await _loadModelsFromConfig();
  }
  
  // Get the list of models (for UI display)
  List<ModelInfo> get models => List.unmodifiable(_models);
  
  // Get model path by type and file type
  Future<String> getModelPath(String modelType, String fileName) async {
    final modelDir = await _modelDirPath;
    return '$modelDir/$fileName';
  }
  
  // Find a model by type
  ModelInfo? getModelByType(String type) {
    return _models.firstWhere(
      (model) => model.type == type,
      orElse: () => throw Exception('No model found with type: $type'),
    );
  }
  
  // Get model type string by type
  Future<String?> getModelTypeString(String type) async {
    try {
      final model = getModelByType(type);
      return model?.modelType;
    } catch (e) {
      debugPrint('Error getting model type: $e');
      return null;
    }
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
      
      // Make sure we've loaded the models config
      if (_models.isEmpty) {
        await _loadModelsFromConfig();
      }
      
      // Check if all destination files exist for all models
      for (var model in _models) {
        for (var outputFile in model.outputFiles) {
          final file = File('$modelDir/${outputFile.destination}');
          if (!await file.exists()) {
            return false;
          }
        }
      }
      
      // If all files exist but marker doesn't, create the marker
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
    // Make sure models are loaded
    if (_models.isEmpty) {
      await _loadModelsFromConfig();
    }
    
    // Calculate total download size
    final totalSize = _models.fold(0.0, (sum, model) => sum + model.size);
    
    if (!context.mounted) return false;
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
    // Make sure models are loaded
    if (_models.isEmpty) {
      await _loadModelsFromConfig();
      
      // If still empty after loading, show error
      if (_models.isEmpty) {
        _toastService.showError('Failed to load model configuration.');
        return false;
      }
    }
    
    // Check connectivity first - still need context for initial dialogs
    final canDownload = await _checkConnectivity();
    if (!canDownload && context.mounted) {
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
          
          // Handle compressed .bz2 file - now using isolate
          await _processCompressedFileInIsolate(
            response.bodyBytes,
            modelDir,
            model.outputFiles,
          );
        } else {
          // Handle direct files with mapping to new name
          for (var outputFile in model.outputFiles) {
            final file = File('$modelDir/${outputFile.destination}');
            await file.writeAsBytes(response.bodyBytes);
          }
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
  
  // Process compressed file in a separate isolate
  Future<void> _processCompressedFileInIsolate(
    List<int> fileBytes,
    String modelDir,
    List<OutputFileMapping> outputMappings,
  ) async {
    // Create a ReceivePort for communication
    final receivePort = ReceivePort();
    
    // Prepare data to send to isolate
    final data = ExtractionData(
      fileBytes: fileBytes,
      modelDir: modelDir,
      outputMappings: outputMappings,
      sendPort: receivePort.sendPort,
    );
    
    // Spawn the isolate
    await Isolate.spawn(_extractInIsolate, data);
    
    // Wait for a result from the isolate
    await for (final message in receivePort) {
      if (message == 'done') {
        // Extraction completed
        break;
      } else if (message is String && message.startsWith('error:')) {
        // Error occurred in isolate
        throw Exception(message.substring(6));
      }
    }
    
    // Close the port when done
    receivePort.close();
  }
  
  // Isolate entry point for extraction
  static Future<void> _extractInIsolate(ExtractionData data) async {
    try {
      // Decompress bz2
      final archive = BZip2Decoder().decodeBytes(data.fileBytes);
      
      // Extract tar archive
      final tarArchive = TarDecoder().decodeBytes(archive);
      
      // Create a mapping for efficient lookup
      final Map<String, String> pathMappings = {};
      for (final mapping in data.outputMappings) {
        pathMappings[mapping.source] = mapping.destination;
      }
      
      // Track which files we've processed
      final Set<String> processedDestinations = {};
      
      // Process each file in the archive
      for (final file in tarArchive) {
        if (!file.isFile) continue;
        
        // Check for exact matches
        String? destinationFile;
        
        for (final sourcePath in pathMappings.keys) {
          if (file.name == sourcePath) {
            destinationFile = pathMappings[sourcePath];
            break;
          }
        }
        
        // Skip files we don't need
        if (destinationFile == null) continue;
        
        // Mark as processed
        processedDestinations.add(destinationFile);
        
        // Create the destination file
        final filePath = '${data.modelDir}/$destinationFile';
        
        // Create parent directories if needed
        final parentDir = Directory(path.dirname(filePath));
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }
        
        // Write file
        await File(filePath).writeAsBytes(file.content as List<int>);
      }
      
      // Check if all needed files were found
      if (processedDestinations.length != pathMappings.length) {
        throw Exception('Not all required files were found in the archive');
      }
      
      // Signal completion
      data.sendPort.send('done');
    } catch (e) {
      // Send error back to main isolate
      data.sendPort.send('error: $e');
    } finally {
      // Terminate the isolate
      Isolate.exit();
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
    if (shouldDownload && context.mounted) {
      return await downloadModels(context);
    }
    return false;
  }
}