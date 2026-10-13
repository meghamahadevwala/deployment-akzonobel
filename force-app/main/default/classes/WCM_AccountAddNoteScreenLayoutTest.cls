@isTest
public with sharing class WCM_AccountAddNoteScreenLayoutTest {

    public static testmethod void WCM_AccountAddNoteScreenLayoutTest() {

        try{
            Account acc = DataGenerator.insertAccount();
            celsrm__Screens__c screen = DataGenerator.insertScreen();

            WCM_AccountAddNoteScreenLayout.getAccountDataAndScreenConfig(acc.Id, screen.Name); //-- Starts | FIN-8207 | Change by Asera | 04-Sep-25 //
            WCM_AccountAddNoteScreenLayout.AccountDetails(acc.Id);
            WCM_AccountAddNoteScreenLayout.getScreenConfig('testScreen', 'view', 'Account');
            WCM_AccountAddNoteScreenLayout.getScreenConfig('', 'view', 'Account');
            WCM_AccountAddNoteScreenLayout.getScreenConfig('', null, 'Account');
        } catch(Exception ex){
            system.debug('Exception >>>>'+ex.getLineNumber() + ex.getMessage() );
        }
    
    }
}