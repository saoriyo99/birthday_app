
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class BirthdayProfilePage extends StatefulWidget {
  final UserProfile? userProfile; // add optional param

  const BirthdayProfilePage({super.key, this.userProfile});

  @override
  State<BirthdayProfilePage> createState() => _BirthdayProfilePageState();
}

class _BirthdayProfilePageState extends State<BirthdayProfilePage> {
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.userProfile != null) {
      _userProfile = widget.userProfile;
      _isLoading = false;
    } else {
      _fetchUserProfile();
    }
  }

  Future<void> _fetchUserProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final response = await supabase
        .schema('social')
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    if (response != null) {
      setState(() {
        _userProfile = UserProfile.fromMap(response);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: SelectableText('Failed to load user profile: Unknown error')),
      );
    }
  }

  int _calculateAge(DateTime birthday) {
    final today = DateTime.now();
    int age = today.year - birthday.year;
    if (today.month < birthday.month || (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age;
  }

  Future<void> _editBirthday() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _userProfile!.birthday,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _userProfile!.birthday) {
      setState(() {
        _isLoading = true;
      });
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .schema('social')
            .from('users')
            .update({'birthday': pickedDate.toIso8601String()})
            .eq('id', user.id)
            .select();
        if (response != null) {
          setState(() {
            _userProfile = UserProfile(
              id: _userProfile!.id,
              createdAt: _userProfile!.createdAt,
              firstName: _userProfile!.firstName,
              lastName: _userProfile!.lastName,
              birthday: pickedDate,
              groups: _userProfile!.groups, // Add this line
            );
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Birthday updated successfully')),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update birthday')),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        body: Center(
          child: Text('User profile not found', style: Theme.of(context).textTheme.headlineMedium),
        ),
      );
    }

    final isSelf = widget.userProfile == null; // <-- if null, it's self

    final fullName = '${_userProfile!.firstName} ${_userProfile!.lastName}';
    final age = _calculateAge(_userProfile!.birthday);
    final groups = _userProfile!.groups ?? ""; // add this to your model

    return Scaffold(
      appBar: AppBar(
        title: const Text('Birthday Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey, // Placeholder for image
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                fullName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Turning $age!',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              if (groups.isNotEmpty) Text('Groups: $groups'), // Add this line
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Wishing $fullName Happy Birthday!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  'Wish $fullName HB!',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 32),
              _buildActionTile(context, 'Find gift', Icons.card_giftcard),
              _buildActionTile(context, 'Reserve a restaurant', Icons.restaurant),
              _buildActionTile(context, 'Get a card', Icons.mail),
              _buildActionTile(context, 'Plan a party', Icons.celebration),
              _buildActionTile(context, 'Send a sweet treat', Icons.cake),
              if (isSelf) _buildActionTile(context, 'Edit Birthday', Icons.edit_calendar), // Conditionally display
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          if (title == 'Edit Birthday') {
            _editBirthday();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped on $title')),
            );
          }
        },
      ),
    );
  }
}
