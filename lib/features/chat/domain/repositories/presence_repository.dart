abstract class PresenceRepository {
  Future<void> setOnline(String userId);
  Future<void> setOffline(String userId);
  Future<void> updateLastSeen(String userId);
}
