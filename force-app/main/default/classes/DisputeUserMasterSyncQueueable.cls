public with sharing class DisputeUserMasterSyncQueueable implements Queueable {
    private List<Id> userIds;

    public DisputeUserMasterSyncQueueable(Set<Id> userIdsToSync) {
        userIds = userIdsToSync == null ? new List<Id>() : new List<Id>(userIdsToSync);
    }

    public void execute(QueueableContext context) {
        if (userIds.isEmpty()) {
            return;
        }
        DisputeUserMasterService.syncInternalUsers(new Set<Id>(userIds));
    }
}