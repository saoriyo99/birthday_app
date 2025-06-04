import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/models/group.dart';
import 'package:birthday_app/services/group_service.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:birthday_app/app_router_delegate.dart'; // Import AppRouterDelegate
import 'package:birthday_app/app_route_path.dart'; // Import AppRoutePath

class HomeGroupsSection extends StatefulWidget {
  final Function(String?) onGroupSelected;
  final List<Group> groups;
  final bool isLoadingGroups;
  final String? groupsError;
  final String? selectedGroupId;
  final VoidCallback onGroupCreated;

  const HomeGroupsSection({
    super.key,
    required this.onGroupSelected,
    required this.groups,
    required this.isLoadingGroups,
    this.groupsError,
    this.selectedGroupId,
    required this.onGroupCreated,
  });

  @override
  State<HomeGroupsSection> createState() => _HomeGroupsSectionState();
}

class _HomeGroupsSectionState extends State<HomeGroupsSection> {
  late GroupService _groupService;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Groups',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        _buildGroupList(),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _showCreateGroupDialog(context),
          child: const Text('Create Group'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGroupList() {
    if (widget.isLoadingGroups) {
      return const Center(child: CircularProgressIndicator());
    } else if (widget.groupsError != null) {
      return Center(child: Text(widget.groupsError!));
    } else if (widget.groups.isEmpty) {
      return const Center(child: Text('No groups found'));
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.groups.length,
        itemBuilder: (context, index) {
          final group = widget.groups[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            color: widget.selectedGroupId == group.id ? Theme.of(context).colorScheme.secondaryContainer : null,
            child: ListTile(
              title: Text(group.name),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                final groupId = group.id;
                debugPrint('Group ID clicked: $groupId');
                // Navigate to SeePostScreen with selected group ID
                final delegate = Router.of(context).routerDelegate as AppRouterDelegate;
                delegate.setNewRoutePath(AppRoutePath.postsByGroup(groupId));
                widget.onGroupSelected(groupId); // Call the callback to update parent state
              },
            ),
          );
        },
      );
    }
  }

  void _showCreateGroupDialog(BuildContext context) {
    String groupName = '';
    String groupType = 'Family';
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Group'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                      ),
                      onChanged: (value) {
                        groupName = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: groupType,
                      decoration: const InputDecoration(
                        labelText: 'Group Type',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Family', child: Text('Family')),
                        DropdownMenuItem(value: 'Friends', child: Text('Friends')),
                        DropdownMenuItem(value: 'Work', child: Text('Work')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            groupType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InputDatePickerFormField(
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      fieldLabelText: 'End Date (optional)',
                      onDateSubmitted: (date) {
                        endDate = date;
                      },
                      onDateSaved: (date) {
                        endDate = date;
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (groupName.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group name cannot be empty')),
                  );
                  return;
                }
                try {
                  await _groupService.createGroup(
                    name: groupName,
                    type: groupType,
                    endDate: endDate,
                  );
                  widget.onGroupCreated(); // Notify parent to refresh groups
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Group "$groupName" of type "$groupType" created and you were added as a member')),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exception creating group: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
