@isTest
public with sharing class WCMFetchChildAccountTest {

     @isTest public static void createNameLinkTest() {
        Account acc = DataGenerator.insertAccount();
        List<Map<String,Object>> accnew = new List<Map<String,Object>>();
        Map<String,Object> tempMap = new Map<String,Object>();
        tempMap.put('accountName',acc.Name);
        tempMap.put('Id', acc.Id);
        accnew.add(tempMap);
        List<Map<Object,Object>> accnew1 = new List<Map<Object,Object>>();
        Map<Object,Object> tempMap1 = new Map<Object,Object>();
        tempMap1.put('accountName',acc.Name);
        tempMap1.put('Id', acc.Id);
        accnew1.add(tempMap1);
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('dataServiceResponse',accnew);
        inMap.put('ChildAccount',accnew1);
        WCMFetchChildAccount test = new WCMFetchChildAccount();
        test.invoke('createNameLink', inMap);
         try{
             test.invoke('fetchChildAccount', inMap);
         } catch (Exception e) {
             System.debug(e.getMessage());
         }
         try{
             test.invoke('checkChildAccount', inMap);
         } catch (Exception e) {
             System.debug(e.getMessage());
         }
         
        
    }
}