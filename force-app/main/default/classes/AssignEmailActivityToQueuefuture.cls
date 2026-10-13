public class AssignEmailActivityToQueuefuture {
    @future
    public static void getAssignEmailTaskList(set<Id> tsIds) {   
        System.debug('@@ Task Need to update tsIds' + tsIds);
    
        List<task> task= [Select id,subject,status,OwnerId, Owner.Name, IsReminderSet, ReminderDateTime from task where id in:tsIds];
        List<Task> needToUpdate = new List<Task>();
        if(task != null && task.size()>0){
            Group emailQueue = [select Id, Name, DeveloperName from Group where Type = 'Queue' and DeveloperName = 'EmailAccess' Limit 1];
            for(Task t : task) {
                needToUpdate.add(new Task(Id=t.Id, OwnerId=emailQueue.Id));
            }
            System.debug('@@ Task Need to update' + needToUpdate);
            update needToUpdate;
        }
    }
}