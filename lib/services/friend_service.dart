import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friendship.dart';

class FriendService {
  final _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  /// ================= SEARCH USERS BY NAME OR EMAIL =================
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final data = await _client
        .from('profiles')
        .select('id, email, full_name, avatar_url')
        .neq('id', _userId)
        .or('full_name.ilike.%$query%,email.ilike.%$query%')
        .limit(10);
    return List<Map<String, dynamic>>.from(data);
  }

  /// ================= SEND FRIEND REQUEST =================
  Future<void> sendFriendRequest(String friendId) async {
    await _client.from('friendships').insert({
      'user_id': _userId,
      'friend_id': friendId,
      'status': 'pending',
    });
  }

  /// ================= ACCEPT FRIEND REQUEST =================
  Future<void> acceptFriendRequest(String friendshipId) async {
    await _client
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', friendshipId);
  }

  /// ================= REJECT FRIEND REQUEST =================
  Future<void> rejectFriendRequest(String friendshipId) async {
    await _client
        .from('friendships')
        .update({'status': 'rejected'})
        .eq('id', friendshipId);
  }

  /// ================= REMOVE FRIEND =================
  Future<void> removeFriend(String friendshipId) async {
    await _client.from('friendships').delete().eq('id', friendshipId);
  }

  /// ================= GET FRIENDS (accepted) =================
  Future<List<Friendship>> getFriends() async {
    final data = await _client
        .from('friendships')
        .select('''
          *,
          user_profile:profiles!friendships_user_id_profiles_fkey(id, full_name, email, avatar_url),
          friend_profile:profiles!friendships_friend_id_profiles_fkey(id, full_name, email, avatar_url)
        ''')
        .or('user_id.eq.$_userId,friend_id.eq.$_userId')
        .eq('status', 'accepted')
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => Friendship.fromJson(e, currentUserId: _userId))
        .toList();
  }

  /// ================= GET PENDING REQUESTS (nhận được) =================
  Future<List<Friendship>> getPendingRequests() async {
    final data = await _client
        .from('friendships')
        .select('''
          *,
          user_profile:profiles!friendships_user_id_profiles_fkey(id, full_name, email, avatar_url),
          friend_profile:profiles!friendships_friend_id_profiles_fkey(id, full_name, email, avatar_url)
        ''')
        .eq('friend_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => Friendship.fromJson(e, currentUserId: _userId))
        .toList();
  }

  /// ================= GET SENT REQUESTS =================
  Future<List<Friendship>> getSentRequests() async {
    final data = await _client
        .from('friendships')
        .select('''
          *,
          user_profile:profiles!friendships_user_id_profiles_fkey(id, full_name, email, avatar_url),
          friend_profile:profiles!friendships_friend_id_profiles_fkey(id, full_name, email, avatar_url)
        ''')
        .eq('user_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => Friendship.fromJson(e, currentUserId: _userId))
        .toList();
  }
}
