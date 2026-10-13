trigger AccountTrigger on Account (before update, before insert) {
    //-- Start | FIN-10061 | Changed by Asera | 7 July 2026 --//
    if(Trigger.isBefore) {
        for (Account acc : Trigger.new) {
            String accountNumber = acc.AccountNumber;
            Boolean isNumericAccountNumber = String.isNotBlank(accountNumber);

            if (isNumericAccountNumber) {
                for (Integer index = 0; index < accountNumber.length(); index++) {
                    if (!'0123456789'.contains(accountNumber.substring(index, index + 1))) {
                        isNumericAccountNumber = false;
                        break;
                    }
                }
            }

            if (isNumericAccountNumber) {
                Integer firstNonZeroIndex = 0;
                while (firstNonZeroIndex < accountNumber.length() && accountNumber.substring(firstNonZeroIndex, firstNonZeroIndex + 1) == '0') {
                    firstNonZeroIndex++;
                }

                acc.Account_No_Without_Leading_Zero__c = firstNonZeroIndex == accountNumber.length()
                    ? '0'
                    : accountNumber.substring(firstNonZeroIndex);
            } else {
                acc.Account_No_Without_Leading_Zero__c = accountNumber;
            }
        }
    }
    //-- End | FIN-10061 | Changed by Asera | 7 July 2026 --//

    if((Trigger.isUpdate) && Trigger.isBefore) {
        Profile currentUserProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];

        if(currentUserProfile.Name != 'System Administrator' || Test.IsRunningTest()){
            for (Account acc : Trigger.new) {
                Account oldAcc = Trigger.oldMap.get(acc.Id);
        
                if (oldAcc.Name != acc.Name && !Test.IsRunningTest()) {
                    acc.Name.addError('You cannot change the Account Name.');
                }
            }
        }
    }
}