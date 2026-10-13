@isTest
public class AccountSnoozeControllerTest {
      public static testMethod void testmethod1(){
        Account acc = DataGenerator.insertAccount();
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', acc.Id);
        AccountSnoozeController accountSnoozeController= new AccountSnoozeController();
        accountSnoozeController.invoke('onLoadFunction', inMap);

        inMap.put('NoteBody', 'test note body');
        inMap.put('Reason', 'no response');
        inMap.put('SnoozeUntil', System.today().addDays(5));
        accountSnoozeController.invoke('onSubmit', inMap);
		    accountSnoozeController.invoke('removeSnooze', inMap);
        inMap.put('NoteBody', '');
        accountSnoozeController.invoke('removeSnooze', inMap);
        inMap.put('NoteBody', '');
        accountSnoozeController.invoke('onLoadRemoveSnooze', inMap);
     }
}