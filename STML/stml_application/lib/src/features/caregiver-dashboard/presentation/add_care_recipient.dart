import 'package:flutter/material.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/model/CareRecipient.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/service/manage_care_recipient_service.dart';

class AddCareRecipientForm extends StatefulWidget {
  AddCareRecipientForm({super.key});

  @override
  _AddCareRecipientFormState createState() => _AddCareRecipientFormState();
}

class _AddCareRecipientFormState extends State<AddCareRecipientForm> {
  final ManageCareRecipientService manageCareRecipientService = ManageCareRecipientService();

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _ageController = TextEditingController();
  List<EmergencyContact> _emergencyContacts = [];


  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _locationController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, process the data
      String firstName = _firstNameController.text;
      String lastName = _lastNameController.text;
      String location = _locationController.text;
      String age = _ageController.text;
      List<EmergencyContact> emergencyContacts = [];


      // Here you would typically send the data to a backend or database
      print('First Name: $firstName, Last Name: $lastName, Location: $location, Age: $age');
      print('Emergency Contacts: $_emergencyContacts'); // Print emergency contacts
      CareRecipient careRecipient = CareRecipient(firstName: firstName,
          lastName: lastName,
          location: location,
          age: int.tryParse(age),
          emergencyContacts: emergencyContacts);

      manageCareRecipientService.createCareRecipient(careRecipient);

      // Optionally, clear the form after submission
      _firstNameController.clear();
      _lastNameController.clear();
      _locationController.clear();
      _ageController.clear();
      setState(() {});

      // Optionally, show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully!')),
      );
    }
  }

  void _addEmergencyContact() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        String phone = '';
        return AlertDialog(
          title: const Text('Add Emergency Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
                validator: (value) {
                  if(value == null || value.isEmpty) {
                    return 'Please enter a contact name';
                  }
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                onChanged: (value) => phone = value,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _emergencyContacts.add(EmergencyContact(name: name, phone: phone));
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a first name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a last name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addEmergencyContact,
                child: const Text('Add Emergency Contact'),
              ),
              const SizedBox(height: 8),
              Column(
                children: _emergencyContacts.map((contact) {
                  return ListTile(
                    title: Text(contact.name),
                    subtitle: Text(contact.phone),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Add User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmergencyContact {
  final String name;
  final String phone;

  EmergencyContact({required this.name, required this.phone});

  @override
  String toString() {
    return 'Name: $name, Phone: $phone';
  }
}