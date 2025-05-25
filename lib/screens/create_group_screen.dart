import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _groupNameController = TextEditingController();
  String? _groupType;
  bool _hasEndDate = false;
  final TextEditingController _endDateController = TextEditingController();

  final List<String> _groupTypes = ['Family', 'Friends', 'Coworkers', 'Other'];

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Placeholder for the group share link. In a real app, this would be dynamic.
    const String groupShareLink = 'https://birthdayapp.com/joingroup/my_new_group';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _groupType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select Group Type'),
                onChanged: (String? newValue) {
                  setState(() {
                    _groupType = newValue;
                  });
                },
                items: _groupTypes.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a group type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _hasEndDate,
                    onChanged: (bool? value) {
                      setState(() {
                        _hasEndDate = value ?? false;
                        if (!_hasEndDate) {
                          _endDateController.clear();
                        }
                      });
                    },
                  ),
                  const Text('Set End Date'),
                ],
              ),
              if (_hasEndDate) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _endDateController,
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (_hasEndDate && (value == null || value.isEmpty)) {
                      return 'Please select an end date';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Creating group: ${_groupNameController.text}, Type: $_groupType, End Date: ${_endDateController.text.isEmpty ? "Never" : _endDateController.text}'),
                      ),
                    );
                    // TODO: Handle group creation and navigation
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Create Group',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Share Group:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: groupShareLink,
                version: QrVersions.auto,
                size: 150.0,
                backgroundColor: Colors.white,
                errorStateBuilder: (cxt, err) {
                  return const Center(
                    child: Text(
                      'Uh oh! Something went wrong with QR code generation.',
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing group link: $groupShareLink')),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text(
                  'Share Group Link',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
    _groupNameController.dispose();
    _endDateController.dispose();
    super.dispose();
  }
}
