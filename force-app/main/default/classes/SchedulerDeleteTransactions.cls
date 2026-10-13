global class SchedulerDeleteTransactions implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchDeleteTransactions(), 200);  // Executing the batch
    }
}