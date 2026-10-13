@isTest
public class UpdateActionDetailOnEmailMessageTest {

    public static testMethod void updateActionDetail() {
        Account acc = DataGenerator.insertAccount();
        EmailMessage em = DataGenerator.insertEmailMsg(acc.Id);
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('actionName', 'Test');
        inMap.put('oldValue', 'Test');
        inMap.put('newValue', 'Test');
        Map<Object, Object> activityData = new Map<Object, Object>();
        activityData.put('Id', em.Id);
        inMap.put('activityData', activityData);
        test.starttest();
            UpdateActionDetailOnEmailMessage updateDetail = new UpdateActionDetailOnEmailMessage();
            updateDetail.invoke('actionTaken',inMap);
        Test.stopTest();
    }
}