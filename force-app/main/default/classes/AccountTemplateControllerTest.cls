@isTest
public class AccountTemplateControllerTest {
      public static testMethod void UnreadEmailCount(){
        Account acc = DataGenerator.insertAccount();
        AccountTemplateController agingchart= new AccountTemplateController();
        AccountTemplateController.getUnreadEmailCount(acc.Id);    
     }
}