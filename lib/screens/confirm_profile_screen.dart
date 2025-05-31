import 'package:flutter/material.dart';
import 'package:birthday_app/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfirmProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String userId;

  const ConfirmProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.userId,
  });

  @override
  State<ConfirmProfileScreen> createState() => _ConfirmProfileScreenState();
}

class _ConfirmProfileScreenState extends State<ConfirmProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _birthdayController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _birthdayController = TextEditingController();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Your Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthdayController,
                decoration: const InputDecoration(
                  labelText: 'Birthday',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your birthday';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final supabase = Supabase.instance.client;

                    String fullName = _nameController.text.trim();
                    String firstName = '';
                    String lastName = '';

                    List<String> nameParts = fullName.split(' ');
                    if (nameParts.length > 1) {
                      firstName = nameParts.first;
                      lastName = nameParts.sublist(1).join(' ');
                    } else {
                      firstName = fullName;
                    }

                    DateTime? birthday;
                    try {
                      birthday = DateTime.parse(_birthdayController.text);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid birthday format: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                      return;
                    }

                    try {
                      await supabase.schema('social').from('users').insert({
                        'id': widget.userId,
                        'first_name': firstName,
                        'last_name': lastName,
                        'birthday': birthday.toIso8601String().split('T')[0], // Save as YYYY-MM-DD
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile confirmed and saved!'),
                        ),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error saving profile: $error'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Confirm Profile',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }
}
