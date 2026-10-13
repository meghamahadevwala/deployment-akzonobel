public with sharing class DunningTaskManagerBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    /** Wrapper: account strategy label and frequency (days between reminders) for SOQL and logic. */
    public class StrategyAndFrequency {
        public String accountStrategy { get; set; }
        public Decimal frequency { get; set; }
        public StrategyAndFrequency(String accountStrategy, Decimal frequency) {
            this.accountStrategy = accountStrategy;
            this.frequency = frequency;
        }
    }

    /**
     * Static map: Treatment celsrm__Dunning_Strategy__c (picklist value) -> Account strategy (AI_Dunning_Strategy__c) + frequency (days).
     * Treatment strategy name and account strategy name can differ; this map defines the mapping.
     */
    private static final Map<String, StrategyAndFrequency> TREATMENT_STRATEGY_TO_ACCOUNT_MAP = buildTreatmentStrategyToAccountMap();

    private static Map<String, StrategyAndFrequency> buildTreatmentStrategyToAccountMap() {
        Map<String, StrategyAndFrequency> m = new Map<String, StrategyAndFrequency>();
        m.put('Reactive', new StrategyAndFrequency('Reactive', 0));
        m.put('Proactive - upto 25% overdue risk', new StrategyAndFrequency('Proactive', 7));
        m.put('Proactive - 50% overdue risk', new StrategyAndFrequency('Proactive', 14));
        m.put('Proactive - 75% overdue risk', new StrategyAndFrequency('Proactive', 21));
        m.put('Very Proactive - meant for  delinquent payer', new StrategyAndFrequency('Proactive', 28));
        return m;
    }

    /** For AIDunningTasksManager.createDunningTasks(List<Id>) so it can resolve Treatment from account strategy. */
    public static Map<String, StrategyAndFrequency> getTreatmentStrategyToAccountMap() {
        return TREATMENT_STRATEGY_TO_ACCOUNT_MAP;
    }

    private Set<Id> inputAccountIds;
    private Integer accountBatchSize = 50;
    /** Key = Treatment.celsrm__Dunning_Strategy__c (treatment strategy name). */
    private Map<String, celsrm__Treatment__c> strategyToTreatment = new Map<String, celsrm__Treatment__c>();
    /** Key = Treatment.celsrm__Dunning_Strategy__c -> account strategy + frequency. */
    private Map<String, StrategyAndFrequency> strategyToAccountStrategyAndFrequency = new Map<String, StrategyAndFrequency>();
    /** Key = Account.AI_Dunning_Strategy__c (account strategy name) -> Treatment. Used to find treatment from account. */
    private Map<String, celsrm__Treatment__c> accountStrategyToTreatment = new Map<String, celsrm__Treatment__c>();
    private List<String> stateTreatmentIds = new List<String>();
    private Datetime futureDt;

    public DunningTaskManagerBatch() {
        initializeTreatments(null);
    }

    public DunningTaskManagerBatch(Set<Id> accountIds) {
        this.inputAccountIds = accountIds;
        initializeTreatments(null);
    }

    public DunningTaskManagerBatch(Integer accountBatchSize) {
        this.accountBatchSize = accountBatchSize;
        initializeTreatments(null);
    }

    public DunningTaskManagerBatch(Set<Id> accountIds, Integer accountBatchSize) {
        this.inputAccountIds = accountIds;
        this.accountBatchSize = accountBatchSize;
        initializeTreatments(null);
    }

    public DunningTaskManagerBatch(List<String> treatmentIds) {
        initializeTreatments(treatmentIds);
    }

    public DunningTaskManagerBatch(List<String> treatmentIds, Integer accountBatchSize) {
        this.accountBatchSize = accountBatchSize;
        initializeTreatments(treatmentIds);
    }

    private void initializeTreatments(List<String> treatmentIds) {
        this.futureDt = System.now().addHours(24);

        String query = 'SELECT Id, Name, celsrm__Dunning_Strategy__c, celsrm__Dunning_Gap_For_Reactive_Strategy__c, ' +
                        'celsrm__Task_Due_Date__c, celsrm__Task_Owner_Queue__c, celsrm__Business_Hours__c, celsrm__Auto_Execute_After_Business_Hours__c, Auto_Dunning__c ' +
                        'FROM celsrm__Treatment__c ' +
                        'WHERE celsrm__Intelligent_Dunning__c = true AND celsrm__Dunning_Strategy__c != null AND Active__c = true';

        if (treatmentIds != null && !treatmentIds.isEmpty()) {
            query += ' AND Id IN :treatmentIds';
        }

        List<celsrm__Treatment__c> allTreatments = Database.query(query);

        for (celsrm__Treatment__c tr : allTreatments) {
            if (isWithinBusinessHours(tr)) {
                strategyToTreatment.put(tr.celsrm__Dunning_Strategy__c, tr);
                StrategyAndFrequency s = TREATMENT_STRATEGY_TO_ACCOUNT_MAP.get(tr.celsrm__Dunning_Strategy__c);
                if (s != null) {
                    strategyToAccountStrategyAndFrequency.put(tr.celsrm__Dunning_Strategy__c, s);
                    accountStrategyToTreatment.put(s.accountStrategy+s.frequency, tr);
                }
            } else if (tr.celsrm__Auto_Execute_After_Business_Hours__c) {
                stateTreatmentIds.add(tr.Id);
            }
        }
        System.debug('strategyToTreatment: ' + strategyToTreatment);
        System.debug('strategyToAccountStrategyAndFrequency: ' + strategyToAccountStrategyAndFrequency);
        System.debug('accountStrategyToTreatment: ' + accountStrategyToTreatment);
        System.debug('stateTreatmentIds: ' + stateTreatmentIds);
    }

    private Boolean isWithinBusinessHours(celsrm__Treatment__c tr) {
        if (tr.celsrm__Business_Hours__c != null) {
            return BusinessHours.isWithin(tr.celsrm__Business_Hours__c, Datetime.now());
        }
        return true;
    }

    public void execute(SchedulableContext sc) {
        if (!stateTreatmentIds.isEmpty()) {
            Database.executeBatch(new DunningTaskManagerBatch(stateTreatmentIds, accountBatchSize), accountBatchSize);
        } else {
            Database.executeBatch(this, accountBatchSize);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (accountStrategyToTreatment.isEmpty()) {
            return Database.getQueryLocator([SELECT Id FROM Account WHERE Id = null]);
        }

        Set<String> validAccountStrategies = new Set<String>();
        Set<Decimal> validFrequencies = new Set<Decimal>();
        for (StrategyAndFrequency s : strategyToAccountStrategyAndFrequency.values()) {
            validAccountStrategies.add(s.accountStrategy);
            validFrequencies.add(s.frequency);
        }

        String soql =
            'SELECT Id, Predicted_Payment_Dates__c, Last_Payment_Date__c, Total_AR__c, ' +
            'Primary_Payment_Cycle__c, Secondary_Payment_Cycle__c, AI_Dunning_Frequency__c, ' +
            'Last_Dunning_Reminder_Date__c, AI_Dunning_Strategy__c, Avg_Payment_Term__c ' +
            'FROM Account WHERE AI_Dunning_Enabled__c = TRUE ' +
            'AND AI_Dunning_Strategy__c IN :validAccountStrategies';

        if (!validFrequencies.isEmpty()) {
            soql += ' AND (AI_Dunning_Strategy__c = \'Reactive\' OR AI_Dunning_Frequency__c IN :validFrequencies)';
        }

        if (inputAccountIds != null && !inputAccountIds.isEmpty()) {
            soql += ' AND Id IN :inputAccountIds';
        }

        return Database.getQueryLocator(soql);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        if (accountStrategyToTreatment.isEmpty()) return;

        Map<Id, List<Id>> treatmentToEligibleAccounts = new Map<Id, List<Id>>();

        for (Account acc : scope) {
            try {
                Decimal freq = acc.AI_Dunning_Frequency__c;
                if (acc.AI_Dunning_Strategy__c == 'Reactive') {
                    StrategyAndFrequency sf = TREATMENT_STRATEGY_TO_ACCOUNT_MAP.get('Reactive');
                    freq = sf != null ? sf.frequency : 0;
                }
                celsrm__Treatment__c treatment = accountStrategyToTreatment.get(acc.AI_Dunning_Strategy__c + freq);
                if (treatment != null && DunningTaskManager.shouldCreateDunningTask(acc, treatment)) {
                    if (!treatmentToEligibleAccounts.containsKey(treatment.Id)) {
                        treatmentToEligibleAccounts.put(treatment.Id, new List<Id>());
                    }
                    treatmentToEligibleAccounts.get(treatment.Id).add(acc.Id);
                }
            } catch (Exception ex) {
                System.debug('Error processing account ' + acc.Id + ' : ' + ex.getMessage());
            }
        }

        for (Id treatmentId : treatmentToEligibleAccounts.keySet()) {
            List<Id> eligibleAccountIds = treatmentToEligibleAccounts.get(treatmentId);
            celsrm__Treatment__c treatment = findTreatmentById(treatmentId);
            if (treatment != null && !eligibleAccountIds.isEmpty()) {
                AIDunningTasksManager.createDunningTasks(eligibleAccountIds, treatment);
            }
        }
    }

    private celsrm__Treatment__c findTreatmentById(Id treatmentId) {
        for (celsrm__Treatment__c tr : strategyToTreatment.values()) {
            if (tr.Id == treatmentId) return tr;
        }
        return null;
    }

    public void finish(Database.BatchableContext bc) {
        if (!stateTreatmentIds.isEmpty()) {
            String cron = getCronForDatetime(futureDt);
            String jobName = 'AIDunningTaskCreationJob_' + Datetime.now().getTime();
            System.schedule(jobName, cron, new DunningTaskManagerBatch(stateTreatmentIds, accountBatchSize));
        }
        System.debug('DunningTaskManagerBatch completed.');
    }
    public static String getCronForDatetime(Datetime dt) {
        return String.format(
            '{0} {1} {2} {3} {4} ? {5}',
            new List<String>{
                String.valueOf(dt.second()), // Seconds
                String.valueOf(dt.minute()), // Minutes
                String.valueOf(dt.hour()),   // Hours
                String.valueOf(dt.day()),    // Day of month
                String.valueOf(dt.month()),  // Month
                String.valueOf(dt.year())    // Year
            }
        );
    }
}