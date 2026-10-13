@isTest
public class AIDunningGenAiControllerTest {

    @isTest
    static void testGetDunningEfficiencyReasoning() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, Object> params = new Map<String, Object>{
            'accountName' => 'Test Account',
            'dunningTag' => 'Over Dunning Observed',
            'historicDpd' => 10,
            'actualReminders' => 3.0,
            'actualGap' => 5.0,
            'actualClosure' => 2.0,
            'preDueCount' => 1.0,
            'preDueAlignment' => 4.0,
            'expRem' => '2',
            'expGap' => '7',
            'expClos' => '3',
            'expPreCount' => '1',
            'expPreGap' => '5'
        };
        Test.startTest();
        try {
            celsrm.AIWrapper.ReturnResponse resp = AIDunningGenAiController.getDunningEfficiencyReasoning(params);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetAiDunningEmailTemplateMock() {
        AIDunningGenAiController.useMockAI = true;
        celsrm.AIWrapper.ReturnResponse mock = new celsrm.AIWrapper.ReturnResponse();
        AIDunningGenAiController.mockResponse = mock;

        Map<String, Object> params = new Map<String, Object>{
            'accountName' => 'Test Account',
            'accountNumber' => 'ACC-001',
            'accountId' => '001000000000000',
            'overdueRiskCategory' => 'High',
            'currency' => 'USD',
            'totalAR' => 5000
        };
        Map<String, String> collectorDetails = new Map<String, String>{
            'name' => 'John Collector',
            'email' => 'john@test.com',
            'title' => 'Manager',
            'role' => 'Collections'
        };
        Test.startTest();
        try {
            celsrm.AIWrapper.ReturnResponse resp = AIDunningGenAiController.getAiDunningEmailTemplate(
                params, 'Additional prompt', 'English', collectorDetails);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetAiDunningEmailTemplateLive() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Map<String, Object> params = new Map<String, Object>{
            'accountName' => 'Test Account',
            'accountNumber' => 'ACC-002',
            'accountId' => '001000000000001',
            'overdueRiskCategory' => 'Low',
            'currency' => 'USD',
            'totalAR' => 1000
        };
        Test.startTest();
        try {
            celsrm.AIWrapper.ReturnResponse resp = AIDunningGenAiController.getAiDunningEmailTemplate(
                params, 'prompt', null, null);
        } catch (Exception e) {}
        Test.stopTest();
    }
}