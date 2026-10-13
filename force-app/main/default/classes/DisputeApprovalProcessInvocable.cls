//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
public class DisputeApprovalProcessInvocable {
    public class Request {
        @InvocableVariable(
            required=true
            label='Dispute Id'
            description='Id of the newly created dispute to initiate approval for.'
        )
        public Id disputeId;
    }

    @InvocableMethod(
        label='Initiate Dispute Approval Process'
        description='Evaluates the approval matrix and creates dispute workflow details for new disputes.'
    )
    public static void initiateApprovalProcess(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        List<Id> disputeIds = new List<Id>();
        for (Request request : requests) {
            if (request != null && request.disputeId != null) {
                disputeIds.add(request.disputeId);
            }
        }
        DisputeApprovalProcessController.initiateApprovalProcess(disputeIds);
    }
}
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//