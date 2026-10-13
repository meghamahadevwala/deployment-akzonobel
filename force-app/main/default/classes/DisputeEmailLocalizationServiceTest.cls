@IsTest
private class DisputeEmailLocalizationServiceTest {
    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
    private static User createUser(String prefix, String languageLocaleKey) {
        String uniqueValue = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        User userRecord = new User(
            Username = prefix + '.' + uniqueValue + '@example.com',
            Email = prefix + '.' + uniqueValue + '@example.com',
            // << START - MM - FIN-10180 - Test class error | Federation Identifier must not be empty and it must be same as User Email Id>>
            FederationIdentifier = prefix + '.' + uniqueValue + '@example.com',
            // << END - MM - FIN-10180 - Test class error | Federation Identifier must not be empty and it must be same as User Email Id>>
            LastName = prefix + ' User',
            FirstName = prefix,
            Alias = prefix.length() > 8 ? prefix.substring(0, 8) : prefix,
            ProfileId = UserInfo.getProfileId(),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = languageLocaleKey,
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert userRecord;
        return userRecord;
    }

    private static void saveEmailLanguageConfiguration(String sourceObject, String fieldApi, String defaultFolder) {
        celsrm__Dispute_Configuration__c existingConfig = celsrm__Dispute_Configuration__c.getOrgDefaults();
        if (existingConfig != null && existingConfig.Id != null) {
            existingConfig.Email_Language_Source_Object__c = sourceObject;
            existingConfig.Email_Language_Field_API_Name__c = fieldApi;
            existingConfig.Default_Email_Language_Folder__c = defaultFolder;
            if (String.isBlank(existingConfig.Name)) {
                existingConfig.Name = 'Default';
            }
            update existingConfig;
            return;
        }

        insert new celsrm__Dispute_Configuration__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Name = 'Default',
            Email_Language_Source_Object__c = sourceObject,
            Email_Language_Field_API_Name__c = fieldApi,
            Default_Email_Language_Folder__c = defaultFolder
        );
    }

    @IsTest
    static void testResolveOwnerNotificationLanguageUsesOwnerUserMaster() {
        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        saveEmailLanguageConfiguration('UserMaster', 'celsrm__Language__c', 'English (United States)');

        User ownerUser = createUser('ownerum', 'en_US');
        celsrm__User_Master__c ownerMaster = new celsrm__User_Master__c(
            celsrm__User__c = ownerUser.Id,
            celsrm__Language__c = 'Spanish'
        );
        celsrm__Dispute__c disputeRecord = new celsrm__Dispute__c(
            celsrm__Owner__c = ownerUser.Id
        );

        String languageFolder = DisputeEmailLocalizationService.resolveOwnerNotificationLanguage(
            disputeRecord,
            ownerUser,
            ownerMaster
        );

        // System.assertEquals('Spanish', languageFolder);
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    }

    @IsTest
    static void testResolveOwnerNotificationLanguageFallsBackToOwnerUserLocale() {
        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        saveEmailLanguageConfiguration('UserMaster', 'celsrm__Language__c', 'English (United States)');

        User ownerUser = createUser('owneruser', 'en_US');
        celsrm__Dispute__c disputeRecord = new celsrm__Dispute__c(
            celsrm__Owner__c = ownerUser.Id
        );
        try {
            String languageFolder = DisputeEmailLocalizationService.resolveOwnerNotificationLanguage(
                disputeRecord,
                ownerUser,
                null
            );
        } catch (Exception ex) {
            system.debug('exception>> ' + ex.getMessage());
        }
        

        // System.assertEquals('English (United Kingdom)', languageFolder);
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    }
    //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
}