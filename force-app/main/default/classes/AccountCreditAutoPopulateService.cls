public class AccountCreditAutoPopulateService {

    private static final Set<String> SCENARIO_ONE = new Set<String>{
        '0004 - ALA - Legal Action',
        '0005 - EMP - Employee',
        '0007 - IC - Intercompany',
        '0008 - INAC - Inactive Customer',
        '0009 - RPDL - RPDL',
        '0010 - AGY - Agency/Lawyer',
        '0011 - ATR - Atradius',
        '0012 - WRT - Write Off',
        '0013 - BKR - Bankruptcy',
        '0015 - OS - (Online) Stores',
        '0016 - CAD - Cadex'
    };

    public static void applyDefaults(List<Account> records){

        for(Account acc : records){

            // Solo ejecutar si los campos están vacíos
            if(
                String.isBlank(acc.Dunning_Procedure__c) &&
                String.isBlank(acc.Dunning_Block__c) &&
                String.isBlank(acc.Statement_Indicator__c)
            ){

                if(SCENARIO_ONE.contains(acc.celsrm__Credit_Group__c)){

                    acc.Dunning_Procedure__c = 'Y002';
                    acc.Dunning_Block__c = 'E';
                    acc.Statement_Indicator__c = '1';
                }
            }
        }
    }
}