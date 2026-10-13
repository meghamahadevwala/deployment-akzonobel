trigger UserTrigger on User (after insert, after update) {
    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
    System.enqueueJob(new DisputeUserMasterSyncQueueable(Trigger.newMap.keySet()));
    //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
}