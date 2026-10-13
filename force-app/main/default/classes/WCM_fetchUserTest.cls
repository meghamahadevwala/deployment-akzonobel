@isTest
public with sharing class WCM_fetchUserTest {

    static Map<Object, Object> inMap = new Map<Object, Object>();
    public static testmethod void WCM_fetchUserTest() {
        Map<Object,Object> objMap1 = new Map<Object,Object>();
        objMap1.put('searchKey','a');
        inMap.put('AssignedTo', objMap1);

        WCM_fetchUser fetch = new WCM_fetchUser();
        fetch.invoke('', inMap);
    }

    public static testmethod void GetCurrencyDetails(){
        GetCurrencyDetails CurrencyDetail = new GetCurrencyDetails();
        CurrencyDetail.invoke('functionName', inMap);
    }
}