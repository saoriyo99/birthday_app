import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  int _currentStep = 0;
  final TextEditingController _postTextController = TextEditingController();
  final List<String> _selectedGroups = [];

  // Placeholder for groups. In a real app, this would come from user data.
  final List<String> _availableGroups = [
    'NYC',
    'Friends #1',
    'Family',
    'Basketball',
    'Yoshimoto',
    'Livio',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create HB Post'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          setState(() {
            if (_currentStep < _getSteps().length - 1) {
              _currentStep += 1;
            } else {
              // Last step, submit post
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Submitting post with text: "${_postTextController.text}" to groups: ${_selectedGroups.join(', ')}'),
                ),
              );
              Navigator.pop(context); // Go back after submission
            }
          });
        },
        onStepCancel: () {
          setState(() {
            if (_currentStep > 0) {
              _currentStep -= 1;
            } else {
              Navigator.pop(context); // Go back if on first step
            }
          });
        },
        steps: _getSteps(),
      ),
    );
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Content'),
        content: Column(
          children: <Widget>[
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[300],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                    const Text('Upload Photo'),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo upload simulated')),
                        );
                        // TODO: Implement actual photo picking
                      },
                      child: const Text('Choose Photo'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postTextController,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'What was your favorite part?',
                hintText: 'Enter your birthday memories here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _currentStep >= 0 ? StepState.indexed : StepState.disabled,
      ),
      Step(
        title: const Text('Share'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Choose who to share with:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._availableGroups.map((group) {
              return CheckboxListTile(
                title: Text(group),
                value: _selectedGroups.contains(group),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedGroups.add(group);
                    } else {
                      _selectedGroups.remove(group);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Friend (not in selected groups)'),
              value: _selectedGroups.contains('Friend'), // Placeholder for individual friend
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedGroups.add('Friend');
                  } else {
                    _selectedGroups.remove('Friend');
                  }
                });
              },
            ),
          ],
        ),
        isActive: _currentStep >= 1,
        state: _currentStep >= 1 ? StepState.indexed : StepState.disabled,
      ),
      Step(
        title: const Text('Review'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Review your post:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text('Photo: [Placeholder Image]'),
            Text('Text: ${_postTextController.text}'),
            Text('Shared with: ${_selectedGroups.join(', ')}'),
          ],
        ),
        isActive: _currentStep >= 2,
        state: _currentStep >= 2 ? StepState.indexed : StepState.disabled,
      ),
    ];
  }

  @override
  void dispose() {
    _postTextController.dispose();
    super.dispose();
  }
}
