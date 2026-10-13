trigger PreventTaskDeletionTrigger on Task (before delete) {
    // Set of profile names that should not be able to delete Task records
    Set<String> restrictedProfiles = new Set<String>{'Collector User' , 'Management User' , 'Collector Support'};
    
    // Get the current user's profile name
    String currentUserProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
    
    // Check if the current user's profile is in the restricted set
    if (restrictedProfiles.contains(currentUserProfileName)) {
        for (Task t : Trigger.old) {
            t.addError('Error: Deletion of tasks is not allowed for your profile.');
        }
    }
}