public without sharing class AWCS_CreateAccountAction {

    public class Request {
        @InvocableVariable(required=true)
        public Id accountWoCreditSegmentId;
    }

    public class Response {
        @InvocableVariable public Id accountId;
        @InvocableVariable public Boolean created;
        @InvocableVariable public Boolean updated;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label='Create/Link/Update Account from AccountWoCreditSegment'
        description='Creates an Account when missing, links intake via Account__c, and updates existing Account credit segment/check rule when applicable.'
    )
    public static List<Response> run(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Response resp = new Response();
        resp.created = false;
        resp.updated = false;
        resp.message = '';
        responses.add(resp);

        // Validate input
        if (requests == null || requests.size() != 1 || requests[0] == null || requests[0].accountWoCreditSegmentId == null) {
            resp.message = 'accountWoCreditSegmentId is required.';
            return responses;
        }

        Id intakeId = requests[0].accountWoCreditSegmentId;

        // Load source record
        AccountWoCreditSegment__c aw = [
            SELECT Id, Name, Account__c, Business_Partner_Number__c, CurrencyIsoCode, Credit_Segment__c
            FROM AccountWoCreditSegment__c
            WHERE Id = :intakeId
            LIMIT 1
        ];

        if (String.isBlank(aw.Business_Partner_Number__c)) {
            resp.message = 'Business_Partner_Number__c is blank. Cannot create/link/update Account.';
            return responses;
        }

        if (String.isBlank(aw.Credit_Segment__c)) {
            resp.message = 'Credit_Segment__c is blank. Cannot build Account Key.';
            return responses;
        }

        String bp = aw.Business_Partner_Number__c.trim();
        String seg = aw.Credit_Segment__c.trim();

        // Build Account Key
        String accountKey = 'CFIN_CustomerMasterCreditManagement_' + '100' + bp + seg;

        // Check if Account already exists
        List<Account> accByKey = [
            SELECT Id, AccountNumber, Name, celsrm__Check_Rule__c, celsrm__Credit_Control_Area__c,
                   celsrm__App_Name__c, celsrm__Account_Key__c
            FROM Account
            WHERE celsrm__Account_Key__c = :accountKey
            LIMIT 1
        ];

        // If match exists, link and stop
        if (!accByKey.isEmpty()) {
            Account target = accByKey[0];

            if (aw.Account__c == null || aw.Account__c != target.Id) {
                update new AccountWoCreditSegment__c(Id = aw.Id, Account__c = target.Id);
            }

            String errorMsg = 'An Account with Credit Segment "' + seg + '" already exists for Business Partner ' + bp + '. No duplicate was created.';
            AuraHandledException e = new AuraHandledException(errorMsg);
            e.setMessage(errorMsg);
            throw e;
        }

        // Query Credit_Control_Area__c — required for Region check and currency
        Credit_Control_Area__c cca = null;
        try {
            cca = [
                SELECT Id, BaseCurrency__c, Credit_Segment__c, Region__c
                FROM Credit_Control_Area__c
                WHERE Credit_Segment__c = :seg
                LIMIT 1
            ];
        } catch (Exception ex) {
            // CCA not found — region validation cannot proceed
        }

        // ── REGION VALIDATION ──────────────────────────────────────────────────
        // Credit_Control_Area__c.Region__c (Text) must match one of the values
        // in the running User's Region__c (Multi-Select Picklist).
        // Users with the GLOBAL region bypass this check entirely.
        if (cca == null || String.isBlank(cca.Region__c)) {
            String errMsg = 'Cannot proceed: no Credit Control Area found for segment "' + seg + '", or its Region__c is blank.';
            AuraHandledException e = new AuraHandledException(errMsg);
            e.setMessage(errMsg);
            throw e;
        }

        User currentUser = [
            SELECT Id, Region__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        // Multi-select picklist values are semicolon-separated → split into a List
        // (List preserves original order for the error message)
        List<String> userRegionList = new List<String>();
        Set<String> userRegions = new Set<String>();
        if (!String.isBlank(currentUser.Region__c)) {
            for (String r : currentUser.Region__c.split(';')) {
                String trimmed = r.trim();
                userRegionList.add(trimmed);
                userRegions.add(trimmed);
            }
        }

        // GLOBAL users can create Accounts in any region — skip the check
        // if (!userRegions.contains('GLOBAL') && !userRegions.contains(cca.Region__c.trim())) {
        //     // Format assigned regions for a readable error message
        //     String formattedRegions;
        //     if (userRegionList.size() == 1) {
        //         formattedRegions = '"' + userRegionList[0] + '"';
        //     } else {
        //         List<String> quoted = new List<String>();
        //         for (String r : userRegionList) {
        //             quoted.add('"' + r + '"');
        //         }
        //         formattedRegions = String.join(quoted, ', ');
        //     }

        //     String errMsg = 'You do not have permission to create Accounts for region "'
        //         + cca.Region__c + '". Your assigned region(s): ' + formattedRegions + '.';
        //     AuraHandledException e = new AuraHandledException(errMsg);
        //     e.setMessage(errMsg);
        //     throw e;
        // }
        // ── END REGION VALIDATION ──────────────────────────────────────────────

        // Create new Account
        Account aNew = new Account();
        aNew.Name = aw.Name;
        aNew.AccountNumber = bp;
        aNew.celsrm__Account_Key__c = accountKey;
        aNew.celsrm__Credit_Control_Area__c = seg;
        aNew.celsrm__Check_Rule__c = 'Z01 Risk Class New Customer';
        aNew.celsrm__App_Name__c = 'Credit';
        aNew.Region__c = (cca.Region__c == 'South Asia & Oceania')
        ? 'South Asia and Oceania'
        : cca.Region__c;
        aNew.celsrm__Credit_Limit__c= 0;
        aNew.celsrm__Limit_Valid_To_Date__c = Date.today().addDays(365);

        // Payment Behaviour Text/Trend default for brand-new accounts
        aNew.celsrm__Payment_Behaviour_Text__c = 'No Data Available';
        aNew.celsrm__Payment_Behaviour_Trend__c = 'No Data Available';

        // Currency assignment using the CCA table
        if (!String.isBlank(cca.BaseCurrency__c)) {
            aNew.CurrencyIsoCode = cca.BaseCurrency__c;
        } else if (!String.isBlank(aw.CurrencyIsoCode)) {
            aNew.CurrencyIsoCode = aw.CurrencyIsoCode;
        } else {
            aNew.CurrencyIsoCode = UserInfo.getDefaultCurrency();
        }

        insert aNew;

        // Writeback to source system (SAP via Celonis EMS webhook)
        UpdateBlockInSourceSystemService.updateBlockInSAP(new List<String>{ aNew.Id });

        // Link AWCS → Account
        update new AccountWoCreditSegment__c(Id = aw.Id, Account__c = aNew.Id);

        resp.accountId = aNew.Id;
        resp.created = true;
        resp.updated = false;
        resp.message = 'Account created and linked.';

        return responses;
    }
}