public class AssignEmailActivityToQueue implements Queueable {
    List<Task> task;
    Group emailQueue;
    public AssignEmailActivityToQueue(List<Task> task) {
        this.task = task;
        emailQueue = [select Id, Name, DeveloperName from Group where Type = 'Queue' and DeveloperName = 'EmailAccess' Limit 1];
    }
    public void execute(QueueableContext context) {
        List<Task> needToUpdate = new List<Task>();
        for(Task t : task) {
            needToUpdate.add(new Task(Id=t.Id, OwnerId=emailQueue.Id));
        }
        System.debug('@@ Task Need to update' + needToUpdate);
        update needToUpdate;
    }
}