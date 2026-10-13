public with sharing class MasssendEmail implements Queueable, Database.AllowsCallouts{
    //-- Starts | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
    Map<String, Object> taskMap = new Map<String, Object>();
    List<Object> taskMaplist = new List<Object>();

    public MasssendEmail(List<Object> taskMaplist) {
        this.taskMaplist = taskMaplist;
    }
    
    public void execute(QueueableContext context) {
        system.debug('taskMap>>>>>NEW BATCH CALL');
        for(Object taskdata : taskMaplist){
            Map<Object, Object> taskMap = (map<Object, Object>)taskdata;
            system.debug('taskMap>>>>>' + taskMap);
            TaskTreatmentController.customSendEmail(taskMap, true);
        }
    }

    public void finish(Database.BatchableContext bc){
    }
    //-- Ends | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
}