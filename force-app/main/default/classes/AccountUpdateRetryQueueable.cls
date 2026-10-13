public class AccountUpdateRetryQueueable implements Queueable {

    private List<Account> accounts;
    private Integer retryCount;
    private static final Integer MAX_RETRY = 3;

    public AccountUpdateRetryQueueable(List<Account> accounts, Integer retryCount) {
        this.accounts = accounts;
        this.retryCount = retryCount;
    }

    public void execute(QueueableContext context) {

        Database.SaveResult[] results = Database.update(accounts, false);
        List<Account> failedAgain = new List<Account>();
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    failedAgain.add(accounts[i]);
                }
            }
        }

        if (!failedAgain.isEmpty()) {
            if(retryCount < MAX_RETRY) {
                System.enqueueJob(
                    new AccountUpdateRetryQueueable(
                        failedAgain,
                        retryCount + 1
                    )
                );
            } else {
                throw new celsrm.CustomException('Failed to update accounts: ' + failedAgain + ' after ' + MAX_RETRY + ' retries.');
            }
        }
    }
}