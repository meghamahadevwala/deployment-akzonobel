@isTest
public with sharing class GOGFetchEmailTemplateForReminderTest {
    public static testMethod void GOGFetchEmailTemplateForReminderTest() {
        Account acc = DataGenerator.insertAccount();
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', acc.Id);
        inMap.put('Locale', UserInfo.getName());
        GOGFetchEmailTemplateForReminder fetch = new GOGFetchEmailTemplateForReminder();
        fetch.invoke('', inMap);
    }
}