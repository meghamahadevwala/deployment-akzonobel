public class GetActiveDisputeForTransaction {

    private static final String STATUS_CLOSED = '60 Closed';

    public class Request {
        @InvocableVariable(required=true)
        public Id transactionId;

        @InvocableVariable(required=false)
        public Decimal promisedAmount;
    }

    public class Result {
        @InvocableVariable public Id disputeId;
        @InvocableVariable public String disputeStatus;
        @InvocableVariable public Decimal disputedAmount;
        @InvocableVariable public Decimal promisedAmount;
        @InvocableVariable public Boolean found;
    }

    @InvocableMethod(
        label='Get Active Dispute for Transaction'
        description='Returns the most recent non-closed dispute and promised amount for a Transaction record'
    )
    public static List<Result> getActiveDispute(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            res.found = false;
            res.promisedAmount = req.promisedAmount ?? 0;

            List<celsrm__Dispute__c> disputes = [
                SELECT Id, celsrm__Status__c, Disputed_Amount__c
                FROM celsrm__Dispute__c
                WHERE celsrm__Transaction__c = :req.transactionId
                  AND celsrm__Status__c != :STATUS_CLOSED
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];

            if (!disputes.isEmpty()) {
                res.found          = true;
                res.disputeId      = disputes[0].Id;
                res.disputeStatus  = disputes[0].celsrm__Status__c;
                res.disputedAmount = disputes[0].Disputed_Amount__c;
            }

            results.add(res);
        }

        return results;
    }
}