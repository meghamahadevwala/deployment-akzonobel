@isTest
public with sharing class SRM_ScreenLayoutTest {
    public static testMethod void SRM_ScreenLayout() {
        Account acc = DataGenerator.insertAccount();
        SRM_ScreenLayout test = new SRM_ScreenLayout();
        test.getDefaultValue();
        
        celsrm__Screens__c scr1 = new celsrm__Screens__c();
        scr1.celsrm__Profile__c = 'test';
        scr1.celsrm__Page_Mode__c = 'view';
        scr1.celsrm__Object__c= 'Contact';
        scr1.celsrm__Screen_Name__c = 'NewScreen591';
        scr1.celsrm__Is_Active__c = true;
        insert scr1;
        SRM_ScreenLayout test1 = new SRM_ScreenLayout();
        test1.getValues();

        try {
           SRM_ScreenLayout.getScreenConfig(scr1.Id, 'view', 'Contact');
        } catch (Exception ex) {
            System.debug('Exception:'+ex.getMessage());
        }
        try {
             SRM_ScreenLayout.getScreenConfig(null, 'view', 'Contact');
        } catch (Exception ex) {
            System.debug('Exception:'+ex.getMessage());
        }
        try {
             SRM_ScreenLayout.getScreenConfig(null, null, null);
        } catch (Exception ex) {
            System.debug('Exception:'+ex.getMessage());
        }
        try {
             SRM_ScreenLayout.AccountDetails(acc.Id);
        } catch (Exception ex) {
            System.debug('Exception:'+ex.getMessage());
        }
    }
    
}