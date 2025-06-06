import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/models/group.dart';
import 'package:birthday_app/models/group_member_profile.dart'; // Import the new model

/// Service for handling group-related operations.
class GroupService {
  final SupabaseClient _supabaseClient;

  GroupService(this._supabaseClient);

  /// Fetches the list of groups the current user belongs to.
  Future<List<Group>> fetchUserGroups() async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return [];
    }
    try {
      final groupMemberships = await _supabaseClient
          .schema('social')
          .from('group_members')
          .select('group_id')
          .eq('user_id', currentUser.id);

      final groupIds = groupMemberships
          .map((e) => e['group_id'] as String)
          .toList();

      if (groupIds.isEmpty) {
        return [];
      }

      final groupsResponse = await _supabaseClient
          .schema('social')
          .from('groups')
          .select('id, name, created_at, type, end_date, group_members(id, group_id, user_id, joined_at, users(first_name, last_name))')
          .inFilter('id', groupIds);

      return (groupsResponse as List<dynamic>)
          .map((data) => Group.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user groups: $e');
    }
  }

  /// Creates a new group and adds the current user as a member.
  Future<Group> createGroup({
    required String name,
    required String type,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabaseClient
          .schema('social')
          .from('groups')
          .insert({
            'name': name,
            'type': type,
            'end_date': endDate?.toIso8601String(),
          })
          .select()
          .single();

      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser != null) {
        await _supabaseClient
            .schema('social')
            .from('group_members')
            .insert({
              'group_id': response['id'],
              'user_id': currentUser.id,
            });
      }
      return Group.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  /// Fetches the members of a specific group using a Supabase function.
  Future<List<GroupMemberProfile>> fetchGroupMembers(String groupId) async {
    try {
      final response = await _supabaseClient
          .schema('social')
          .rpc('get_group_members', params: {'p_group_id': groupId});

      if (response == null) {
        return [];
      }

      debugPrint('Group ID: ${groupId}');
      debugPrint('Got the group members: ${response}');

      return (response as List<dynamic>)
          .map((data) => GroupMemberProfile.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch group members: $e');
    }
  }

  /// Updates the name of an existing group.
  Future<void> updateGroupName(String groupId, String newName) async {
    try {
      await _supabaseClient
          .schema('social')
          .from('groups')
          .update({'name': newName})
          .eq('id', groupId);
    } catch (e) {
      throw Exception('Failed to update group name: $e');
    }
  }
}
