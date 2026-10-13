global class WCM_CloseDisputeScreen implements celsrm.GOGIScreenCustomLogic {
    //DEPRICATED
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
            System.debug('@@ inMap : ' + inMap);
            
            if(functionName == 'SaveCloseDispute'){
                inMap = SaveCloseDispute(inMap);
            } else if(functionName == 'FetchCloseDispute'){
                inMap = FetchCloseDispute(inMap);
            }
            return inMap;
    } 

    public static Map<Object,Object> FetchCloseDispute(Map<Object,Object> inMap){
        String disputeId = (String)inMap.get('Id');
        celsrm__Dispute__c dis = [SELECT Id, Name, celsrm__Dispute_Type__c FROM celsrm__Dispute__c where id =: disputeId]; 
        System.debug('type>>>>>'+ dis.celsrm__Dispute_Type__c );
        if(dis.celsrm__Dispute_Type__c != null){
            inMap.put('type',dis.celsrm__Dispute_Type__c);
        }
        return inMap;

    }

    public static Map<Object,Object> SaveCloseDispute (Map<Object,Object> inMap){
        String disputeId = (String)inMap.get('Id');
        Map<id,celsrm__Dispute__c> MapTransOlderNotes = new Map<Id,celsrm__Dispute__c>([select id, celsrm__Latest_Note__c from celsrm__Dispute__c where Id =: disputeId ]);
        celsrm__Dispute__c dis = new celsrm__Dispute__c();
        dis.Id = disputeId;
        dis.celsrm__Close_Date__c = Date.today();
        dis.celsrm__Dispute_Type__c	= String.valueOf(inMap.get('disputeType'));
        dis.celsrm__Status__c = 'Closed';
        dis.celsrm__Resolution_Code__c = String.valueOf(inMap.get('resolutionCode'));
        System.debug('noteBody>>>>>>>>>>'+String.valueOf(inMap.get('noteBody')));
        if(String.valueOf(inMap.get('noteBody')) != null){
            dis=  (celsrm__Dispute__c)celsrm.SRMUtilityController.saveNoteOnRecord( dis,MapTransOlderNotes.get(disputeId).celsrm__Latest_Note__c, 'Closed Dispute - '+String.valueOf(inMap.get('noteTitle')),String.valueOf(inMap.get('noteBody')),'','') ;
          
           /* dis.celsrm__Latest_Note_Title__c = String.valueOf(inMap.get('noteTitle'));
            dis.celsrm__Note_Date__c = date.today();
            //  currentTrx.Latest_Note__c = String.valueOf(inMap.get('NoteTitle')) + '\n' + String.valueOf(inMap.get('NoteBody'));
            dis.celsrm__Latest_Note__c =  String.valueOf(inMap.get('noteBody'));     
            dis.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
            dis.celsrm__Notes__c = String.valueOf(inMap.get('noteTitle')) + '\n' + String.valueOf(inMap.get('noteBody')) +'\n'+UserInfo.getName() + ':' + date.today().year()+'-'+date.today().month()+'-'+date.today().day() + '\n\n' + (MapTransOlderNotes.get(disputeId).celsrm__Notes__c != null && MapTransOlderNotes.get(disputeId).celsrm__Notes__c != '' ? MapTransOlderNotes.get(disputeId).celsrm__Notes__c : '');*/
        }
        update dis;
        return inMap;
    }
    
    
}