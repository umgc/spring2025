import 'package:flutter/material.dart';  

class EmergencyHelpButton extends StatefulWidget {  
  const EmergencyHelpButton({super.key});  

  @override  
  State<EmergencyHelpButton> createState() => _EmergencyHelpButtonState();  
}  

class _EmergencyHelpButtonState extends State<EmergencyHelpButton> {  
  bool _isLoading = false;  

  @override  
  Widget build(BuildContext context) {  
    return Container(  
      margin: const EdgeInsets.all(16.0),  
      child: ElevatedButton(  
        style: ElevatedButton.styleFrom(  
          backgroundColor: Theme.of(context).colorScheme.error,  
          shape: const CircleBorder(),  
          padding: const EdgeInsets.all(24.0),  
          elevation: 8.0,  
        ),  
        onPressed: _isLoading ? null : () {  
          // La logique sera ajoutée dans la prochaine étape  
          setState(() => _isLoading = true);  
        },  
        child: _isLoading   
          ? const CircularProgressIndicator(color: Colors.white)  
          : const Icon(  
              Icons.emergency,  
              size: 40.0,  
              color: Colors.white,  
            ),  
      ),  
    );  
  }  
}  