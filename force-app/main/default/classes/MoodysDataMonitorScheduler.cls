global class MoodysDataMonitorScheduler implements Schedulable{
    global void execute(SchedulableContext sc) {
        AsyncOptions asyncOptions = new AsyncOptions();
        asyncOptions.MaximumQueueableStackDepth = 100;
        System.enqueueJob(new MoodysDataMonitor(0), asyncOptions);
    }
}