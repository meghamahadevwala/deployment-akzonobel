global with sharing class EmailAddressSuggestion implements celsrm.GOGIScreenCustomLogic {
    public Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        Map<Object, Object> returnMap = new Map<Object, Object>();
        List<Map<String, String>> emailList = new List<Map<String, String>>();
        Map<String, String> emailMap;
        String AccountId = String.valueOf(inMap.get('Id'));
        Set<id> AccountIds= new set<id>();
        Map<Id,Account> MapAccountParent = new Map<id,Account>([Select id from Account Where ParentId =: AccountId Or Id =:AccountId]);
        system.debug('============'+AccountId );
        AccountIds = MapAccountParent.keySet();
      //  AccountIds.add((Id)AccountId);
        
        for(Contact contList : [Select Id, Name, Email FROM Contact WHERE AccountId in :AccountIds  ]){
            emailMap = new Map<String, String>();
            if(contList.Name != null && contList.Email != null){
            emailMap.put('label', contList.Name);
            emailMap.put('value', contList.Email);
            emailList.add(emailMap);
            }
        }
        if(emailList != null && emailList.size()>0){
            returnMap.put('toSuggestion',emailList);
            returnMap.put('bccSuggestion',emailList);
            returnMap.put('ccSuggestion',emailList);
        }
        return returnMap;
    }
}