public class AccountTemplateController {
    @AuraEnabled
    public static Integer getUnreadEmailCount(String accId) {
        AggregateResult[] groupedResults = [SELECT COUNT(Id) cnt FROM EmailMessage 
                                                Where RelatedToId = :accId And Incoming=TRUE And celsrm__IsRead__c=FALSE];
        Object avgAmount = groupedResults[0].get('cnt');
        return Integer.valueOf(avgAmount);
    }
}