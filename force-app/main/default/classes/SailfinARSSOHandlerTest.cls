@isTest
public class SailfinARSSOHandlerTest {
    static testMethod void testCanCreateUser() {
        SailfinARSSOHandler handler = new SailfinARSSOHandler();
        Auth.UserData userData = new Auth.UserData(
            'sample_id', 
            'sample_first_name',
            'sample_last_name',
            'sample_first_name sample_last_name',
            'sample_email@example.com', 
            'sample_link',
            'sample_email@example.com', 
            'en_US',
            'Celonis', 
            'https://sample.com',
            new Map<String, String>{
                'federationIdentifier' => 'sample_email@example.com'
            }
        
        );

        // Test that canCreateUser returns false as the default implementation does.
        System.assertEquals(false, handler.canCreateUser(userData));
    }

    static testMethod void testCreateUserWithCommunityAccess() {
        SailfinARSSOHandler handler = new SailfinARSSOHandler();

        Map<String, String> attributeMap = new Map<String, String>{
            'sfdc_networkid' => 'some_network_id',
            'federationIdentifier' => 'sample_email@example.com'
        };
       Auth.UserData userData = new Auth.UserData(
            'sample_id', 
            'sample_first_name',
            'sample_last_name',
            'sample_first_name sample_last_name',
            'sample_email@example.com', 
            'sample_link',
            'sample_email@example.com', 
            'en_US',
            'Celonis', 
            'https://sample.com',
            attributeMap
        );

        Test.startTest();
        try {
            handler.createUser(null, userData);
            System.assert(false, 'Expected a RegHandlerException to be thrown');
        } catch (SailfinARSSOHandler.RegHandlerException e) {
            System.assert(e.getMessage().contains('SSO Login is not supported for Experiecnce cloud in Sailfin AR App.'));
        }
        Test.stopTest();
    }

    static testMethod void testCreateUserWithoutCommunityAccess() {
        SailfinARSSOHandler handler = new SailfinARSSOHandler();

        // Create an active user to match on email
        User existingUser = new User(
            Username = 'sample_email@example.com',
            Email = 'sample_email@example.com',
            LastName = 'Existing',
            FirstName = 'User',
            Alias = 'exuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            federationIdentifier = 'sample_email@example.com'
        );
        insert existingUser;

        Auth.UserData userData = new Auth.UserData(
            'sample_id', 
            'sample_first_name',
            'sample_last_name',
            'sample_first_name sample_last_name',
            'sample_email@example.com', 
            'sample_link',
            'sample_email@example.com', 
            'en_US',
            'Celonis', 
            'https://sample.com',
            new Map<String, String>{
                'federationIdentifier' => 'sample_email@example.com'
            }
        );

        Test.startTest();
        User createdUser = handler.createUser(null, userData);
        Test.stopTest();

        // Verify that the existing user was returned
        System.assertEquals(existingUser.Id, createdUser.Id);
    }

    static testMethod void testCreateUserWithoutCommunityAccessUserNotFound() {
        SailfinARSSOHandler handler = new SailfinARSSOHandler();

        Auth.UserData userData = new Auth.UserData(
            'sample_id', 
            'sample_first_name',
            'sample_last_name',
            'sample_first_name sample_last_name',
            'sample_email123@example.com', 
            'sample_link',
            'sample_email123@example.com', 
            'en_US',
            'Celonis', 
            'https://sample.com',
            new Map<String, String>{
                'federationIdentifier' => 'sample_email123@example.com'
            }
        );

        Test.startTest();
        try {
            handler.createUser(null, userData);
            System.assert(false, 'Expected a RegHandlerException to be thrown');
        } catch (SailfinARSSOHandler.RegHandlerException e) {
            System.assert(e.getMessage().contains('Cannot find the user with email sample_email123@example.com'));
        }
        Test.stopTest();
    }

    static testMethod void testUpdateUser() {
        SailfinARSSOHandler handler = new SailfinARSSOHandler();

        // Create a user to be updated
        User existingUser = new User(
            Username = 'update_user@example.com',
            Email = 'update_user@example.com',
            LastName = 'Update',
            FirstName = 'User',
            Alias = 'upduser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            federationIdentifier = 'update_user@example.com'
        );
        insert existingUser;

        Auth.UserData userData = new Auth.UserData(
            'sample_id', 
            'sample_first_name',
            'sample_last_name',
            'sample_first_name sample_last_name',
            'update_user@example.com', 
            'sample_link',
            'update_user@example.com', 
            'en_US',
            'Celonis', 
            'https://sample.com',
            new Map<String, String>{
                
            }
        );

        Test.startTest();
        handler.updateUser(existingUser.Id, null, userData);
        Test.stopTest();

        // Verify that the user was updated with the correct details
        User updatedUser = [SELECT Email FROM User WHERE Id = :existingUser.Id];
        System.assertEquals('update_user@example.com', updatedUser.Email);
    }
}