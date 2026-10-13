global with sharing class GOGTaskEditGridData implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into GOGCustomImplementation');
        System.debug('functionName ::: ' + functionName);
        System.debug('inMap ::: ' + inMap);       
        inMap.put('VendorName','adding new value');
        
        
        String str = JSON.serialize(inMap.get('TaskList')); 
        List<object> tsk = (List<object>)System.JSON.deserializeUntyped(str);
        system.debug(tsk );
        
        
        set<Id> taskIdList = new set<Id>();
        set<String> trxfldList = new set<String>();
        List<Task> Temptlst = new List<Task>();
        
        List < Id > AccIDs = new List< Id >();
        Set<String> conEmailAddresses = new Set<String>();
        set <String> valueofMapId = new Set<String>();
        List<Task> UpdatedTaskList = new List<Task>();
        
        if(tsk != null && tsk.size() > 0) {
            for(Object ts: tsk ){            
            
                system.debug('ts'+ts);
                Map<String, Object> m = (Map<String, Object>)ts;
                Id key = (String)m.get('Id');
                taskIdList.add(key);                      
            }
        }
  
        system.debug('==========='+taskIdList);
        if(taskIdList!= null && taskIdList.size() > 0){           
            Temptlst = [Select t.What.type,t.ownerId, t.ActivityDate,t.Account.Name, t.celsrm__Notes__c, t.WhatId, t.Type, t.SystemModstamp, t.Subject, t.Status, t.Id, t.Priority , t.Description, t.CallType, t.CallObject, t.AccountId, t.Owner.Email From Task t where id =: taskIdList];
            for(Task t: Temptlst ){
                AccIDs.add(t.WhatID);
                
            }
        }
        
        Map< String, Map<String, List<String>> > returnMap = UtilityController.fetchEmails(AccIDs);
        for(Task t : [Select t.Id,t.Account.Name,t.what.id,t.Subject,t.ActivityDate,t.Status,t.who.email,t.celsrm__To__c,t.celsrm__Cc__c,t.celsrm__Bcc__c,t.celsrm__From__c,t.celsrm__Auto_Dunning_Error__c From Task t where t.Status != 'Completed' and t.Status  != 'Auto Dunning Error' and t.what.type=:'Account' and t.Id IN : taskIdList])   
        {
            
            if(returnMap != null && returnMap.get(t.whatId).get('to') != null)
                t.celsrm__to__c = string.join(returnMap.get(t.whatId).get('to'),',');
            if(returnMap != null && returnMap.get(t.whatId).get('bcc') != null)
                t.celsrm__Bcc__c =  string.join(returnMap.get(t.whatId).get('bcc'),',');
            if(returnMap != null && returnMap.get(t.whatId).get('cc') != null)
                t.celsrm__cc__c = string.join(returnMap.get(t.whatId).get('cc'),',');
            if(returnMap != null && returnMap.get(t.whatId).get('from') != null)
                t.celsrm__From__c = string.join(returnMap.get(t.whatId).get('from'),',');
            
            UpdatedTaskList.add(t);
        }
        /* for(Task trxobj : Temptlst){
trxobj.Status = (String)inMap.get('Status');
trxobj.ownerId = (String)inMap.get('AssignedTo');
trxobj.ActivityDate = (date)inMap.get('DueDate');
trxobj.dunning_status__c = (String)inMap.get('DunningStatus'); 
}

update Temptlst;*/
        
        /*  Map<Id,String> accConFaxMap = new Map<Id, String>();
Map<Id,String> accConEmailMap = new Map<Id,String>();
Map<Id,Set<String>> accConEmailMapForAddtionalTo = new Map<Id,Set<String>>();
List<Contact> cc1 = new List<Contact>();
cc1 = [select Email,Fax,AccountId,Locale__c from Contact where celsrm__Default__c = true And AccountId IN : AccIDs order by LastName];
system.debug('---cc1 ' + cc1);
system.debug('---cc1 size ' + cc1.size());
system.debug('---Map ' +accConEmailMap);

for ( Contact contact : cc1 ) {

system.debug('contact.Email- '  +contact.Email);
if(contact.Email != null && contact.Email != '')
{
accConEmailMap.put(contact.accountId, contact.Email);
}
IF(accConEmailMapForAddtionalTo.containsKey(contact.accountId)){

conEmailAddresses = accConEmailMapForAddtionalTo.get(contact.accountId);

conEmailAddresses.add(contact.Email);

accConEmailMapForAddtionalTo.put(contact.AccountId,conEmailAddresses);
if(contact.Fax!= null && contact.Fax != '')
{
accConFaxMap.put(contact.AccountId,contact.Fax);
}
system.debug('----IF accConEmailMap '+ accConEmailMapForAddtionalTo);
}
ELSE{
conEmailAddresses = new Set<String>();
conEmailAddresses.add(contact.Email);
accConEmailMapForAddtionalTo.put(contact.accountId, conEmailAddresses);
if(contact.Fax != null && contact.Fax != '')
{   
accConFaxMap.put(contact.accountId, contact.Fax);
}

}                    




}

for(Task t : [Select t.Id,t.Account.Name,t.what.id,t.Subject,t.ActivityDate,t.Additional_To__c,t.Status,t.who.email,t.To__c,t.Cc__c,t.Bcc__c,t.From__c,t.Auto_Dunning_Error__c From Task t where t.Status != 'Completed' and t.Status  != 'Auto Dunning Error' and t.what.type=:'Account' and t.Id IN : taskIdList])   
{
system.debug('---accConEmailMapForAddtionalTo '+ accConEmailMapForAddtionalTo.get(t.whatid));
Boolean temp = false;   
if(t.whatid != null)
{
system.debug('accConEmailMapForAddtionalTo line 3762' + accConEmailMapForAddtionalTo);
system.debug('accConEmailMap line 3763' + accConEmailMap);
valueofMapId = accConEmailMapForAddtionalTo.get(t.whatid);
}
system.debug('!!! accConEmailMapForAddtionalTo line 3768'+ accConEmailMapForAddtionalTo);
String constring = '';

if(valueofMapId != null && valueofMapId.size() > 0  )
{
for(String s:valueofMapId) {
String Emailad='';
if (accConEmailMap != null && accConEmailMap.get(t.whatid) !=null){
Emailad= accConEmailMap.get(t.whatid);
}
if(s != null ){
if(!s.contains(Emailad))
{

constring += (constring==''?'':',')+s; 

}
}

}
}


if((accConEmailMap.containsKey(t.whatid) && accConFaxMap.containsKey(t.whatid) && t.subject.startsWith('Fax')) || (!accConEmailMap.containsKey(t.whatid) && accConFaxMap.containsKey(t.whatid)) )
{ 
t.to__c = accConFaxMap.get(t.WhatId);
t.Bcc__c = '';
t.cc__c = '';
t.Additional_To__c ='';
temp = true;
system.debug('!!!temp ==== '+ t.subject.contains('Fax'));
}
else
{
t.to__c = accConEmailMap.get(t.whatid);
t.Additional_To__c = constring;

// String ccadresses = (t.cc__c == ''|| t.cc__c == null) ? '' : t.cc__c ;
t.cc__c = UserInfo.getUserEmail();

temp = false;
system.debug('!!!temp ==== '+ temp);
} 
if(t.from__c != null && t.from__c != '')
{
t.from__c = '';
}
system.debug('after the if condition --- ');
// tlst1.add(new wrapperTask(t,temp,getEmailFromUsers(t.whatid)));
UpdatedTaskList.add(t);

}

}*/
        inMap.put('TaskList', UpdatedTaskList);
        return inMap;
    }
}