import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memoryminder/config/config.dart';
import 'package:memoryminder/models/caregiver.dart';
import 'package:memoryminder/models/emergency_type.dart';
import 'package:memoryminder/services/caregiver_notification_service.dart';
import 'package:memoryminder/services/emergency_services.dart';
import 'package:memoryminder/services/esri_client.dart';
import 'package:memoryminder/services/navigation_service.dart';
import 'package:memoryminder/widgets/emergency_help_button.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

// Screen imports
import 'package:memoryminder/ui/assistant_screen.dart';
import 'package:memoryminder/ui/audio_screen.dart';
import 'package:memoryminder/ui/gallery_screen.dart';
import 'package:memoryminder/ui/location_history_screen.dart';
import 'package:memoryminder/ui/profile_screen.dart';
import 'package:memoryminder/ui/response_screen.dart';
import 'package:memoryminder/ui/tour_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger _logger = Logger('HomeScreen');
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late CaregiverNotificationService _notificationService;
  late EmergencyService _emergencyService;
  late NavigationService _navigationService;
  late EsriClient _esriClient;

  Caregiver? _currentCaregiver;
  Position? _currentPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadUserData();
    _setupLocationTracking();
  }

  void _initializeServices() {
    _notificationService = CaregiverNotificationService();
    _emergencyService = EmergencyService(baseUrl: Config.apiBaseUrl);
    _navigationService = NavigationService();
    _esriClient = EsriClient(apiKey: Config.esriApiKey);
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc =
            await _firestore.collection('caregivers').doc(user.uid).get();
        setState(() {
          _currentCaregiver = Caregiver.fromJson(doc.data()!);
        });
      }
    } catch (e, stackTrace) {
      _logger.severe('Error loading caregiver data', e, stackTrace);
    }
  }

  Future<void> _setupLocationTracking() async {
    try {
      await _requestLocationPermissions();
      Geolocator.getPositionStream().listen(_handleLocationUpdate);
    } catch (e, stackTrace) {
      _logger.severe('Location tracking setup failed', e, stackTrace);
    }
  }

  Future<void> _requestLocationPermissions() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  Future<void> _handleLocationUpdate(Position position) async {
    try {
      setState(() => _currentPosition = position);
      final address = await _esriClient.reverseGeocode(
          position.latitude, position.longitude);
      await _saveLocationEntry(address);
    } catch (e, stackTrace) {
      _logger.severe('Location update error', e, stackTrace);
    }
  }

  Future<void> _saveLocationEntry(String address) async {
    // Database save implementation
  }

  Future<String> _getFormattedLocation() async {
    if (_currentPosition == null) return 'Unknown location';
    return await _esriClient.reverseGeocode(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
  }

  Future<bool> _handleEmergencyPress() async {
    if (_currentCaregiver == null) return false;

    setState(() => _isLoading = true);

    try {
      final location = await _getFormattedLocation();

      // Send emergency alert
      final success = await _notificationService.sendEmergencyAlert(
        caregiver: _currentCaregiver!,
        patientLocation: location,
        emergencyType: EmergencyType.urgent,
        additionalData: {'timestamp': DateTime.now().toIso8601String()},
      );

      if (success) {
        // Trigger return home protocol
        final route = await _esriClient.getRouteToHome(location);
        await _esriClient.sendDirectionsToCaregiver(route);

        // Navigate to emergency help screen
        await _navigationService.navigateToEmergencyHelp(
          location,
          DateTime.now(),
        );

        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.severe('Emergency protocol failed', e, stackTrace);
      return false;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: UiUtils.createBottomNavigationBar(context),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/icons/app_icon.png', height: 32),
          const SizedBox(width: 10),
          const Text('MemoryMinder', style: TextStyle(color: Colors.black54)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person, color: Colors.black54),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        _buildBackgroundImage(),
        _buildMainContent(),
        _buildEmergencyButton(),
      ],
    );
  }

  Widget _buildBackgroundImage() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/background.jpg"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 140, 16, 25),
          child: Text(
            'Helping you remember the important things.\nChoose a feature to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
        Expanded(
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            padding: const EdgeInsets.all(26),
            children: _buildFeatureButtons(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeatureButtons() {
    return [
      _buildFeatureButton(
        icon: Icons.handshake_outlined,
        label: 'Virtual Assistant',
        screen: const AssistantScreen(),
      ),
      _buildFeatureButton(
        icon: Icons.photo,
        label: 'Gallery',
        screen: GalleryScreen(),
      ),
      _buildFeatureButton(
        icon: Icons.search,
        label: 'Object Search',
        screen: const ResponseScreen(),
      ),
      _buildFeatureButton(
        icon: Icons.mic_rounded,
        label: 'Record Audio',
        screen: AudioScreen(),
      ),
      _buildFeatureButton(
        icon: Icons.location_history,
        label: 'Location',
        screen: const LocationHistoryScreen(),
      ),
      _buildFeatureButton(
        icon: Icons.flag,
        label: 'Tour Guide',
        screen: TourScreen(),
      ),
    ];
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required Widget screen,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromRGBO(255, 255, 255, 0.3),
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 65, color: Colors.black54),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: EmergencyHelpButton(
        onPressed: _handleEmergencyPress,
        buttonText: 'EMERGENCY',
        successMessage: 'Help is on the way!',
        errorMessage: 'Failed to send request. Please try again.',
        isLoading: _isLoading,
      ),
    );
  }
}
