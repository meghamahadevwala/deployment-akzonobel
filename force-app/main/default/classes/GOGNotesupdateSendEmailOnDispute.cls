global with sharing class GOGNotesupdateSendEmailOnDispute implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into GOGCustomImplementation');
        System.debug('functionName ::: ' + functionName);
        System.debug('inMap ::: ' + inMap);       
        inMap.put('VendorName','adding new value');
        
        String str = JSON.serialize(inMap.get('DisputeGrid'));       
        List<string> strList = str.substring(1, str.length()-1).split('}');
        set<Id> trxIdList = new set<Id>();
        set<String> trxfldList = new set<String>();
        List<celsrm__Dispute__c> trxListtoUpdate = new List<celsrm__Dispute__c>();
        
       /* for(string str1 : strList){            
            string currentString;
            if(!str1.contains('}')){
                currentString = str1 + '}';
                currentString = currentString.substringBetween('{','}');
            }
            currentString = '{'+currentString+'}';
            map<string,string> m = (map<string,string>)JSON.deserialize(currentString, map<string,string>.class);   
            trxIdList.add(m.get('Id'));                      
        }*/
         List < object > tran = (List < object > ) inMap.get('DisputeGrid');
             for (Object ts: tran) {
                  Map < Object, Object > m = (Map < Object, Object > ) ts;
                  Id key = (String) m.get('Id');
                  trxIdList.add(key); 
             }
        if(trxIdList!= null && trxIdList.size() > 0){           
            trxListtoUpdate = [select id,name,celsrm__Dispute_Type__c,celsrm__Amount__c,celsrm__Status__c,celsrm__Latest_Note__c from celsrm__Dispute__c where id =: trxIdList];
            for(celsrm__Dispute__c trxobj : trxListtoUpdate){
             trxobj = (celsrm__Dispute__c) celsrm.SRMUtilityController.saveNoteOnRecord(trxobj,trxobj.celsrm__Latest_Note__c ,UtilityController.getDefaultContactMethodName('Email'),String.valueOf(inMap.get('NoteBody')),(String)(((Map<Object,Object>)inMap.get('ComposeEmail')).get('templateName')),UtilityController.getDefaultContactName((List < Object>)(((Map<Object,Object>)inMap.get('ComposeEmail')).get('to')))) ;
           
         /*  trxobj.Last_Contact_Date__c =  date.today();
            trxobj.Latest_Note_Title__c = String.valueOf(inMap.get('NoteTitle'));
            trxobj.Note_Date__c = date.today();
            trxobj.Latest_Note__c =   String.valueOf(inMap.get('NoteTitle')) +'\n'+ String.valueOf(inMap.get('NoteBody'));
            trxobj.Latest_Notes_Entered_By__c = UserInfo.getUserId();           
           trxobj.Notes__c =   String.valueOf(inMap.get('NoteTitle')) +'\n'+ String.valueOf(inMap.get('NoteBody'))+'\n'+ UserInfo.getName() + ':' +date.today().year()+'-'+date.today().month()+'-'+date.today().day() +  '\n\n' + (trxobj.Notes__c != null && trxobj.Notes__c != ''? trxobj.Notes__c : '') ;*/
            }
            
            update trxListtoUpdate;
        }
        inMap.put('ContactMehods','Email');
        return inMap;
    }
}