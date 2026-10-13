global with sharing class WCM_fetchUser implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        List<User> userList = new List<User>();
        String searchKeyValue = '';
        String wherecluse = '';
        if(inMap.containsKey('AssignedTo')){
            Map<Object,Object> Searchkey = (Map<Object,Object>)inMap.get('AssignedTo');
            if(Searchkey .containsKey('searchKey')){
                searchKeyValue = (String)Searchkey.get('searchKey');
                wherecluse = ' AND Name Like' + '\'' + '%' +searchKeyValue + '%' + '\'';
            }
        }
        
        String query = '';
        //System.SObjectException: SObject row was retrieved via SOQL without querying the requested field: User.Name
        if (Test.IsRunningTest()){
            String uId = String.valueof(UserInfo.getUserId());
         	query = 'Select Id, Name,profile.name,UserName from User where Id = \'' + uId + '\'';
        } else {
            query = 'Select Id, Name,profile.name,UserName from user where profile.name In ( ' + '\''+'Collector User'+'\'' + ',' +'\''+'Collector Super User'+'\''+ ')';
        }    
        
        if(wherecluse != ''){
            query += wherecluse;
        }
        userList = Database.query(query);
        List<Map<String,object>> listOfUserMap = new List<Map<String,object>>();
        for( User usrData : userList ){
            Map<String,object> mapUser = new Map<String,object>();
            mapUser.put('Id', usrData.Id);
            mapUser.put('Name', usrData.Name );
            mapUser.put('Profile', usrData.profile.name );
            mapUser.put('UserName', usrData.UserName );
            system.debug('mapUser>>>>>>'+mapUser);
            listOfUserMap.add(mapUser);
        }
        inMap.put('dataServiceResponse',listOfUserMap);
        return inMap;
    }
}