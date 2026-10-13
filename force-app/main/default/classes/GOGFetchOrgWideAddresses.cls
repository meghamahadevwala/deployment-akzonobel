global with sharing class GOGFetchOrgWideAddresses implements celsrm.GOGIScreenCustomLogic {
  global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
      System.debug('into GOGCustomImplementation');
      System.debug('functionName ::: ' + functionName);
      System.debug('inMap ::: ' + inMap);
      inMap.put('VendorName','adding new value');
      String AccId = (String)inMap.get('Id');
      
     // List<SelectOption> emailTemplatesops = new List<SelectOption>();
       List<map<string,string>> customObject = new List<map<string,string>>();
        List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress ];
          
          for(OrgWideEmailAddress lw : listName) {
             //orgwideadd.put(lw.Address,lw);
              map<string,string> tmp = new map<string,string>();
                  tmp.put('label',lw.Address);
                  tmp.put('value',lw.Id);
                  customObject.add(tmp);
          }
          inMap.put('dataServiceResponse',customObject);
      return inMap;
     
     }
      
      
    }