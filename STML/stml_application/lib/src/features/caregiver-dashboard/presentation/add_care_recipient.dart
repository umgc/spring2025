import 'dart:async';
import 'package:flutter/material.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/model/CareRecipient.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/model/emergency_contact.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/app_bar.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/service/manage_care_recipient_service.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';

class AddCareRecipientForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? itemId;

  const AddCareRecipientForm({super.key, this.itemId, this.initialData});

  @override
  _AddCareRecipientFormState createState() => _AddCareRecipientFormState();
}

class _AddCareRecipientFormState extends State<AddCareRecipientForm> {
  final ManageCareRecipientService manageCareRecipientService =
  ManageCareRecipientService();
  bool _isUpdateMode = false;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countyController = TextEditingController();
  final _stateController = TextEditingController();
  List<EmergencyContact> _emergencyContacts = [];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _countyController.dispose();
    _stateController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _isUpdateMode = true;
      _firstNameController.text = widget.initialData!['firstName'] ?? '';
      _lastNameController.text = widget.initialData!['lastName'] ?? '';
      _ageController.text = widget.initialData!['age']?.toString() ?? '';
      _addressController.text =
          widget.initialData!['address']?.toString() ?? '';
      _emailController.text = widget.initialData!['email']?.toString() ?? '';
      _phoneController.text = widget.initialData!['phone']?.toString() ?? '';
      _cityController.text = widget.initialData!['city']?.toString() ?? '';
      _countyController.text = widget.initialData!['county']?.toString() ?? '';
      _stateController.text = widget.initialData!['state']?.toString() ?? '';
      _emergencyContacts = widget.initialData?['emergencyContacts'];
    }
  }

  void _submitForm() {
    print(
        'Emergency Contacts: $_emergencyContacts'); // Print emergency contacts

    if (_formKey.currentState!.validate()) {
      // Form is valid, process the data
      String firstName = _firstNameController.text;
      String lastName = _lastNameController.text;
      String age = _ageController.text;
      String email = _emailController.text;
      String address = _addressController.text;
      String phone = _phoneController.text;
      String city = _cityController.text;
      String county = _countyController.text;
      String state = _stateController.text;
      List<EmergencyContact> emergencyContacts = [];

      // Here you would typically send the data to a backend or database
      print(
          'First Name: $firstName, Last Name: $lastName, Address: $address, City: $city, County: $county, State: $state, Age: $age, Email: $email, Phone: $phone');
      print(
          'Emergency Contacts: $_emergencyContacts'); // Print emergency contacts
      CareRecipient careRecipient = CareRecipient(
          firstName: firstName,
          lastName: lastName,
          address: address,
          city: city,
          state: state,
          county: county,
          email: email,
          phone: phone,
          age: int.tryParse(age),
          emergencyContacts: _emergencyContacts);
      if (_isUpdateMode) {
        manageCareRecipientService.updateCareRecipient(
            widget.itemId, careRecipient);
      } else {
        manageCareRecipientService.createCareRecipient(careRecipient);
      }

      // Optionally, clear the form after submission
      _firstNameController.clear();
      _lastNameController.clear();
      _addressController.clear();
      _cityController.clear();
      _stateController.clear();
      _countyController.clear();
      _emailController.clear();
      _phoneController.clear();
      _ageController.clear();
      _emergencyContacts = [];
      setState(() {});

      // Optionally, show a success message
      if (_isUpdateMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully!')),
        );
      }
    }
  }

  void _addEmergencyContact() {
    final _formKey1 = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        String phone = '';
        return AlertDialog(
          title: const Text('Add Emergency Contact'),
          backgroundColor: const Color(0XFFCCFFFF),
          content: Form(
            key: _formKey1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Contact Name'),
                  onChanged: (value) => name = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a contact name';
                    }
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Contact Phone'),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => phone = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a contact phone';
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey1.currentState?.validate() ?? false) {
                  setState(() {
                    _emergencyContacts
                        .add(EmergencyContact(name: name, phone: phone));
                  });
                  Navigator.of(context).pop();
                }
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
        appBar: const CustomAppBar(
          title: 'Care Recipient',
        ),
        body: Container (
          child : Column (
            children : [
              Expanded ( // Wrap Column with Expanded
                child : SingleChildScrollView (
                  child : ConstrainedBox (
                    constraints :
                    BoxConstraints (
                      minWidth : double.infinity, // Ensure width matches screen
                      minHeight : 0, // Allow height to expand based on content
                    ),
                    child : Column (
                      children : [
                        Form (
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'First Name',
                                  focusColor: Colors.blueGrey,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a first name';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Last Name',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a last name';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _ageController,
                                decoration: const InputDecoration(labelText: 'Age'),
                              ),
                              TextFormField(
                                controller: _addressController,
                                decoration: const InputDecoration(labelText: 'Address Line'),
                              ),
                              TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(labelText: 'City'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a city';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(labelText: 'State'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a state';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _countyController,
                                decoration: const InputDecoration(labelText: 'County'),
                              ),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(labelText: 'Email'),
                              ),
                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(labelText: 'Phone'),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _addEmergencyContact,
                                child: const Text('Add Emergency Contact'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.fromLTRB(16.0, 2, 16.0, 2),
                                ),
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
                                child: Text(_isUpdateMode
                                    ? 'Update Care Recipient'
                                    : 'Add Care Recipient'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.fromLTRB(16.0, 2, 16.0, 2),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(
                          color: Colors.black,
                          thickness: 2,
                          height: 10,
                          indent: 20,
                          endIndent: 20,
                        ),


                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: UiUtils.createBottomNavigationBar(context));
  }

}

// Helper function to create each button for the GridView
Widget _buildElevatedButton({
  required BuildContext context,
  required Icon icon,
  required String text,
  required Widget screen,
  required String keyName,
}) {
  return SizedBox(
      width: 150,
      height: 150,
      child: ElevatedButton(
        key: Key(keyName),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.lightBlue[100],
          // Button text color
          padding: const EdgeInsets.all(2.0),
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 7.0),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                color: Color(0XFF000000),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ));
}