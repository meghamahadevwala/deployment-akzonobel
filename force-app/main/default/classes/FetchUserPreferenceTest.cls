@isTest
public with sharing class FetchUserPreferenceTest {
    public static testMethod Void  FetchUserPreferenceTest1() {
        celsrm__Custom_List_View__c listView = DataGenerator.insertCustomListView(false);
        celsrm__User_Preference__c userPref  = DataGenerator.insertUserPreference(listView.Id);
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans1 = DataGenerator.insertTransaction(acc);
        celsrm__Transaction__c trans2 = DataGenerator.insertTransaction(acc);
        celsrm__Transaction__c trans3 = DataGenerator.insertTransaction(acc);
        // Convert trans into a Map<String, Object>
        Map<Object, Object> inMap = new Map<Object, Object>();
        Map<Object, Object> transMap1 = new Map<Object, Object>();
        Date promiseDate = datetime.now().date();
        transMap1.put('Id', trans1.Id);
        transMap1.put('celsrm__Account__c', trans1.celsrm__Account__c);
        transMap1.put('celsrm__Balance__c', trans1.celsrm__Balance__c);
        transMap1.put('celsrm__Amount__c', trans1.celsrm__Amount__c);
        transMap1.put('celsrm__Promised_Amount__c', trans1.celsrm__Promised_Amount__c);
        transMap1.put('celsrm__Disputed_Amount__c', 1000);
        transMap1.put('celsrm__Promise_Date__c', promiseDate );
        transMap1.put('celsrm__Is_Broken_Promise__c', 100 );
        transMap1.put('disputeType', 'Billing');
        transMap1.put('reasonCode', 'Tax rate incorrect');
        transMap1.put('totalSLADays', 2);

        Map<Object, Object> transMap2 = new Map<Object, Object>();
        trans2.celsrm__Promise_Date__c = (datetime.now().addDays(2)).date();
        trans2.celsrm__Disputed_Amount__c = 0;
        update trans2;
        transMap2.put('Id', trans2.Id);
        transMap2.put('celsrm__Account__c', trans2.celsrm__Account__c);
        transMap2.put('celsrm__Balance__c', trans2.celsrm__Balance__c);
        transMap2.put('celsrm__Amount__c', trans2.celsrm__Amount__c);
        transMap2.put('celsrm__Promised_Amount__c', trans2.celsrm__Promised_Amount__c);
        transMap2.put('celsrm__Disputed_Amount__c',trans2.celsrm__Disputed_Amount__c);
        transMap2.put('celsrm__Promise_Date__c', (datetime.now().addDays(2)).date());
        transMap2.put('celsrm__Is_Broken_Promise__c', false);
        transMap2.put('disputeType', 'Billing');
        transMap2.put('reasonCode', 'Tax rate incorrect');
        transMap2.put('totalSLADays', 2);

        Map<Object, Object> transMap3 = new Map<Object, Object>();
        trans3.celsrm__Promised_Amount__c = 0;
        trans3.celsrm__Promise_Date__c = null;
        trans3.celsrm__Disputed_Amount__c = 0;
        trans3.celsrm__Due_Date__c = (datetime.now().addDays(-2)).date();
        update trans3;
        transMap3.put('Id', trans3.Id);
        transMap3.put('celsrm__Account__c', trans3.celsrm__Account__c);
        transMap3.put('celsrm__Balance__c', trans3.celsrm__Balance__c);
        transMap3.put('celsrm__Amount__c', trans3.celsrm__Amount__c);
        transMap3.put('celsrm__Promised_Amount__c', trans3.celsrm__Promised_Amount__c);
        transMap3.put('celsrm__Disputed_Amount__c', trans3.celsrm__Disputed_Amount__c);
        transMap3.put('celsrm__Promise_Date__c', trans3.celsrm__Promise_Date__c);
        transMap3.put('celsrm__Is_Broken_Promise__c', false);
        transMap3.put('disputeType', 'Billing');
        transMap3.put('reasonCode', 'Tax rate incorrect');
        transMap3.put('totalSLADays', 2);

        inMap.put('Id', acc.Id); 
        inMap.put('NoteBody', 'Test Note'); 
        inMap.put('Status', 'Open');  
        inMap.put('ContactMehods', 'Email');   
        // Add other transaction details as required by your controller
        inMap.put('TransactionList', new List<Map<Object, Object>>{transMap1, transMap2,transMap3});     
        try{
            inMap.put('screenName','Send Statement');
           FetchUserPreference fuserPref = new FetchUserPreference();
           fuserPref.invoke('', inMap); 
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
        try{
            inMap.put('screenName','Contact Customer');
           FetchUserPreference fuserPref = new FetchUserPreference();
           fuserPref.invoke('', inMap); 
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
        try{
            inMap.put('screenName','');
           FetchUserPreference fuserPref = new FetchUserPreference();
           fuserPref.invoke('', inMap); 
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
        trans1.celsrm__Disputed_Amount__c = 0;
        update trans1;
        try{
            inMap.put('screenName','Contact Customer');
           FetchUserPreference fuserPref = new FetchUserPreference();
           fuserPref.invoke('', inMap); 
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
        trans1.celsrm__Promise_Date__c = null;
        update trans1;
        try{
            inMap.put('screenName','Contact Customer');
           FetchUserPreference fuserPref = new FetchUserPreference();
           fuserPref.invoke('', inMap); 
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}