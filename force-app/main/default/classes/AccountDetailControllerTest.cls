@isTest
public class AccountDetailControllerTest {
      public static testMethod void testmethod1(){
        Account acc = DataGenerator.insertAccount();
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', acc.Id);
        AccountDetailController accountDetailController= new AccountDetailController();
        accountDetailCOntroller.invoke('AgingSummary', inMap);
        accountDetailCOntroller.invoke('getAccountName', inMap);
        accountDetailCOntroller.invoke('getScoreCardDetail', inMap);
     }
}