
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/friend_service.dart'; // Import FriendService
import '../services/wish_service.dart'; // Import WishService

/// A page displaying a user's birthday profile.
///
/// Can display either the current user's profile or a friend's profile
/// if a [userProfile] is provided.
class UserProfilePage extends StatefulWidget {
  final UserProfile? userProfile;

  const UserProfilePage({super.key, this.userProfile});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  late final FriendService _friendService; // Declare FriendService
  late final WishService _wishService; // Declare WishService
  bool _isEditingName = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    _friendService = FriendService(Supabase.instance.client); // Initialize FriendService
    _wishService = WishService(Supabase.instance.client); // Initialize WishService
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    if (widget.userProfile != null) {
      _userProfile = widget.userProfile;
      _isLoading = false;
      _firstNameController.text = _userProfile!.firstName;
      _lastNameController.text = _userProfile!.lastName;
    } else {
      _fetchUserProfile();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  /// Fetches the current user's profile from Supabase.
  ///
  /// If the user is not logged in, sets loading to false and returns.
  /// Displays a SnackBar on failure to load the profile.
  Future<void> _fetchUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _setLoadingState(false);
      _showSnackBar('User not logged in.');
      return;
    }

    try {
      final fetchedProfile = await _friendService.fetchUserProfileById(user.id);
      if (fetchedProfile != null) {
        _userProfile = fetchedProfile;
      } else {
        _showSnackBar('Failed to load user profile: Profile not found.');
      }
    } catch (e) {
      _showSnackBar('Failed to load user profile: ${e.toString()}');
    } finally {
      _setLoadingState(false);
    }
  }

  /// Helper to update the loading state and trigger a UI rebuild.
  void _setLoadingState(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  /// Helper to display a SnackBar message.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Updates the user's first and last name in Supabase.
  Future<void> _updateUserName() async {
    if (_userProfile == null) {
      _showSnackBar('User profile not loaded.');
      return;
    }

    final newFirstName = _firstNameController.text.trim();
    final newLastName = _lastNameController.text.trim();

    if (newFirstName.isEmpty || newLastName.isEmpty) {
      setState(() {
        _firstNameController.text = _userProfile!.firstName;
        _lastNameController.text = _userProfile!.lastName;
        _isEditingName = false; // Exit editing mode
      });
      _showSnackBar('First name and last name cannot be empty. Reverted to current name.');
      return;
    }

    _setLoadingState(true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      _setLoadingState(false);
      _showSnackBar('User not logged in.');
      return;
    }

    try {
      final response = await supabase
          .schema('social')
          .from('users')
          .update({
            'first_name': newFirstName,
            'last_name': newLastName,
          })
          .eq('id', user.id)
          .select();

      if (response != null && response.isNotEmpty) {
        setState(() {
          _userProfile = _userProfile!.copyWith(
            firstName: newFirstName,
            lastName: newLastName,
          );
          _isEditingName = false; // Exit editing mode
        });
        _showSnackBar('Name updated successfully!');
      } else {
        _showSnackBar('Failed to update name: No response or empty response.');
      }
    } catch (e) {
      _showSnackBar('Failed to update name: ${e.toString()}');
    } finally {
      _setLoadingState(false);
    }
  }

  /// Calculates the current age based on a given birthday.
  int _calculateAge(DateTime birthday) {
    final today = DateTime.now();
    int age = today.year - birthday.year;
    if (today.month < birthday.month || (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age;
  }

  /// Sends a birthday wish to the user whose profile is being viewed.
  ///
  /// Inserts a wish into `social.wishes` and a notification into `social.notifications`.
  Future<void> _sendBirthdayWish() async {
    if (_userProfile == null || widget.userProfile == null) {
      _showSnackBar('Cannot send wish: User profile not loaded or recipient not specified.');
      return;
    }

    _setLoadingState(true);
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      _setLoadingState(false);
      _showSnackBar('User not logged in.');
      return;
    }

    // Fetch sender's profile to get their first name for the notification
    final senderProfile = await _friendService.fetchUserProfileById(currentUser.id);
    if (senderProfile == null) {
      _showSnackBar('Failed to load sender profile.');
      _setLoadingState(false);
      return;
    }

    try {
      debugPrint('senderID: ${currentUser.id} and recipientId: ${widget.userProfile!.id}');
      await _wishService.insertWishAndNotification(
        senderId: currentUser.id,
        recipientId: widget.userProfile!.id,
        message: 'Happy Birthday ${widget.userProfile!.firstName}!',
        senderFirstName: senderProfile.firstName, // Pass sender's first name
        senderLastName: senderProfile.lastName, // Pass sender's last name
      );

      _showSnackBar('Birthday wish sent successfully!');
    } catch (e) {
      _showSnackBar('Failed to send birthday wish: ${e.toString()}');
    } finally {
      _setLoadingState(false);
    }
  }

  /// Allows the user to edit their birthday via a date picker.
  ///
  /// Updates the birthday in Supabase and refreshes the UI.
  Future<void> _editBirthday() async {
    if (_userProfile == null) {
      _showSnackBar('User profile not loaded.');
      return;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _userProfile!.birthday,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null || pickedDate == _userProfile!.birthday) {
      return; // User cancelled or picked the same date
    }

    _setLoadingState(true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      _setLoadingState(false);
      _showSnackBar('User not logged in.');
      return;
    }

    try {
      final response = await supabase
          .schema('social')
          .from('users')
          .update({'birthday': pickedDate.toIso8601String()})
          .eq('id', user.id)
          .select();

      if (response != null && response.isNotEmpty) {
        setState(() {
          // Use copyWith to update the user profile immutably
          _userProfile = _userProfile!.copyWith(birthday: pickedDate);
        });
        _showSnackBar('Birthday updated successfully!');
      } else {
        _showSnackBar('Failed to update birthday: No response or empty response.');
      }
    } catch (e) {
      _showSnackBar('Failed to update birthday: ${e.toString()}');
    } finally {
      _setLoadingState(false);
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
        appBar: AppBar(
          title: const Text('User Profile'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Text('User profile not found', style: Theme.of(context).textTheme.headlineMedium),
        ),
      );
    }

    final isSelf = widget.userProfile == null;
    final fullName = '${_userProfile!.firstName} ${_userProfile!.lastName}';
    final age = _calculateAge(_userProfile!.birthday);
    final groups = _userProfile!.groups ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _ProfileHeader(
              fullName: fullName,
              age: age,
              groups: groups,
              isSelf: isSelf,
              isEditingName: _isEditingName,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              onEditPressed: () {
                setState(() {
                  _isEditingName = true;
                });
              },
              onSavePressed: _updateUserName,
              onCancelPressed: () {
                setState(() {
                  _firstNameController.text = _userProfile!.firstName;
                  _lastNameController.text = _userProfile!.lastName;
                  _isEditingName = false;
                });
              },
            ),
            const SizedBox(height: 24),
            _WishButton(
              fullName: fullName,
              onWishPressed: _sendBirthdayWish, // Pass the new callback
            ),
            const SizedBox(height: 32),
            _ActionTilesSection(
              isSelf: isSelf,
              onEditBirthday: _editBirthday,
              onActionTapped: _showSnackBar, // Pass the snackbar helper
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying the user's profile header.
class _ProfileHeader extends StatelessWidget {
  final String fullName;
  final int age;
  final String groups;
  final bool isSelf;
  final bool isEditingName;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final VoidCallback onEditPressed;
  final VoidCallback onSavePressed;
  final VoidCallback onCancelPressed;

  const _ProfileHeader({
    required this.fullName,
    required this.age,
    required this.groups,
    required this.isSelf,
    required this.isEditingName,
    required this.firstNameController,
    required this.lastNameController,
    required this.onEditPressed,
    required this.onSavePressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        if (isEditingName && isSelf)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: onSavePressed,
              ),
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: onCancelPressed,
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fullName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (isSelf)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEditPressed,
                ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          'Turning $age!',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        if (groups.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Groups: $groups'),
          ),
      ],
    );
  }
}

/// Widget for the "Wish Happy Birthday" button.
class _WishButton extends StatelessWidget {
  final String fullName;
  final VoidCallback onWishPressed; // Add a callback for the button press

  const _WishButton({required this.fullName, required this.onWishPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onWishPressed, // Use the provided callback
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      child: Text(
        'Wish $fullName HB!',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}

/// Widget for displaying the list of action tiles.
class _ActionTilesSection extends StatelessWidget {
  final bool isSelf;
  final VoidCallback onEditBirthday;
  final Function(String) onActionTapped;

  const _ActionTilesSection({
    required this.isSelf,
    required this.onEditBirthday,
    required this.onActionTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          title: 'Find gift',
          icon: Icons.card_giftcard,
          onTap: () => onActionTapped('Find gift'),
        ),
        _ActionTile(
          title: 'Reserve a restaurant',
          icon: Icons.restaurant,
          onTap: () => onActionTapped('Reserve a restaurant'),
        ),
        _ActionTile(
          title: 'Get a card',
          icon: Icons.mail,
          onTap: () => onActionTapped('Get a card'),
        ),
        _ActionTile(
          title: 'Plan a party',
          icon: Icons.celebration,
          onTap: () => onActionTapped('Plan a party'),
        ),
        _ActionTile(
          title: 'Send a sweet treat',
          icon: Icons.cake,
          onTap: () => onActionTapped('Send a sweet treat'),
        ),
        if (isSelf)
          _ActionTile(
            title: 'Edit Birthday',
            icon: Icons.edit_calendar,
            onTap: onEditBirthday,
          ),
      ],
    );
  }
}

/// Reusable widget for a single action tile.
class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
