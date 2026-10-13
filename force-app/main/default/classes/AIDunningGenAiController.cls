public with sharing class AIDunningGenAiController {

    @TestVisible
    static Boolean useMockAI = false;

    @TestVisible
    static celsrm.AIWrapper.ReturnResponse mockResponse;
    public static final String MODEL = 'gpt-4.1-2025-04-14';

    @AuraEnabled
    public static celsrm.AIWrapper.ReturnResponse getDunningEfficiencyReasoning(Map<String, Object> params) {
        try {
            // Extract data from the params map
            String accountName = (String)params.get('accountName');
            String dunningTag = (String)params.get('dunningTag');
            Integer historicDpd = (Integer)params.get('historicDpd');
            
            // KPI actuals
            Decimal actualReminders = (Decimal)params.get('actualReminders');
            Decimal actualGap = (Decimal)params.get('actualGap');
            Decimal actualClosure = (Decimal)params.get('actualClosure');
            Decimal preDueCount = (Decimal)params.get('preDueCount');
            Decimal preDueAlignment = (Decimal)params.get('preDueAlignment');

            // KPI expectations
            String expRem = (String)params.get('expRem');
            String expGap = (String)params.get('expGap');
            String expClos = (String)params.get('expClos');
            String expPreCount = (String)params.get('expPreCount');
            String expPreGap = (String)params.get('expPreGap');

            // Construct the dynamic prompt
            String userPrompt = 'Generate reasoning for the ' + dunningTag +  ' performance of account "' + accountName + '" which has an average of ' + historicDpd + ' days of historic delay.\n\n' +
                'KPI Data for Analysis' +
                '1) Reminder count (Avg reminders per invoice): Actual: ' + actualReminders + ', Expected: ' + expRem + '\n' +
                '2) Reminder frequency (Avg days gap): Actual: ' + actualGap + ', Expected: ' + expGap + '\n' +
                '3) Reminder to closure (Avg days gap last reminder to payment): Actual: ' + actualClosure + ', Expected: ' + expClos + '\n' +
                '4) Pre-due reminder count: Actual: ' + preDueCount + ', Expected: ' + expPreCount + '\n' +
                '5) Days to Due Date (Gap between pre-due reminder and due date): Actual: ' + preDueAlignment + ', Expected: ' + expPreGap;

            AiDunningEfficiencyAgent agent = new AiDunningEfficiencyAgent();
            
            celsrm.AIWrapper.ReturnResponse aiResponse = agent.run(
                userPrompt, 
                new celsrm.AIWrapper.EmailContent(), 
                null, 
                'gpt-4.1', 0.4, 1000
            );

            System.debug('aiResp$$' + aiResponse);
            // Return the serialized response (assuming response is part of aiResponse or defined)
            return aiResponse;
            
        } catch (Exception e) {
            return handleError(e);
        }
    }

    @AuraEnabled
    public static celsrm.AIWrapper.ReturnResponse getAiDunningEmailTemplate(Map<String, Object> params, String additionalPrompt, String language, Map<String, String> collectorDetails) {
        try {
            if (useMockAI && Test.isRunningTest()) {
                return mockResponse;
            }

            String languageInstruction = '';
            if (String.isNotBlank(language)) {
                languageInstruction = 'The email MUST be written entirely in ' + language + '.\n';
            }

            String collectorInfo = '';
            if (collectorDetails != null && !collectorDetails.isEmpty()) {
                collectorInfo = '\nCollector Details:\n';
                if (String.isNotBlank(collectorDetails.get('name'))) {
                    collectorInfo += 'Name: ' + collectorDetails.get('name') + '\n';
                }
                if (String.isNotBlank(collectorDetails.get('email'))) {
                    collectorInfo += 'Email: ' + collectorDetails.get('email') + '\n';
                }
                if (String.isNotBlank(collectorDetails.get('title'))) {
                    collectorInfo += 'Designation: ' + collectorDetails.get('title') + '\n';
                }
                if (String.isNotBlank(collectorDetails.get('role'))) {
                    collectorInfo += 'Role: ' + collectorDetails.get('role') + '\n';
                }
            }

            String userPrompt =
                'Generate a dunning reminder email subject (with accountNumber) and HTML email template.\n' +
                languageInstruction +
                'There should be text only and no CTAs or other actionable content.\n' +
                'Include a professional email signature at the end using the Collector Details provided below.\n' +
                'Place the exact placeholder {transactions.summary} in the email body where the transaction details table should appear.\n' +
                'Output must be ONLY JSON containing:\n' +
                '{ "subject": "...", "emailTemplateHtml": "<html>...</html>" }\n\n' +
                'Account Information:\n' +
                'Account: ' + params.get('accountName') + '\n' +
                'Account Number: ' + params.get('accountNumber') + '\n' +
                'Account ID: ' + params.get('accountId') + '\n' +
                'Risk: ' + params.get('overdueRiskCategory') + '\n' +
                'Total AR: ' + params.get('currency') + ' ' + params.get('totalAR') + '\n' +
                collectorInfo + '\n' +
                additionalPrompt +
                'Return ONLY JSON with an HTML email body.';

            // 2. Execute AI Request
            AIDunningAutoEmailTemplateAgent dunningEmailTemplateAgent = new AIDunningAutoEmailTemplateAgent();

            celsrm.AIWrapper.ReturnResponse aiResponse = dunningEmailTemplateAgent.run(
                userPrompt, 
                new celsrm.AIWrapper.EmailContent(), 
                null, 
                MODEL, 0.4, 1000
            );

            return aiResponse;

        } catch (Exception e) {
            return handleError(e);
        }
    }

    private static celsrm.AIWrapper.ReturnResponse handleError(Exception e) {
        celsrm.AIWrapper.ReturnResponse errorResponse = new celsrm.AIWrapper.ReturnResponse();
        errorResponse.isSuccess = false;
        errorResponse.errorMessage = e.getMessage();
        return errorResponse;
    }
}