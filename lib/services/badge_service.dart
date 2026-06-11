import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '/services/friend_service.dart';
import '/services/collaboration_service.dart';

class BadgeService {
  static Stream<int> get pendingInvitesCountStream {
    return Rx.combineLatest2(
      FriendService.getPendingRequestsStream(),
      CollaborationService.getMyPendingCollabInvitesStream(),
      (List<Map<String, dynamic>> friendReqs, List<Map<String, dynamic>> collabInvites) {
        return friendReqs.length + collabInvites.length;
      },
    ).handleError((error) {
      return 0;
    });
  }
}
