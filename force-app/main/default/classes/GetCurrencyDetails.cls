global with sharing class GetCurrencyDetails implements celsrm.GOGIScreenCustomLogic {
    global Map < Object, Object > invoke(String functionName, Map < Object, Object > inMap) {
        inMap.put('isMultiCurrency',UserInfo.IsMultiCurrencyOrganization());
        inMap.put('userCurrency',UserInfo.getDefaultCurrency());
        return inMap;
    }
}