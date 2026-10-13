import { LightningElement, api } from 'lwc';
import logActivity from '@salesforce/apex/UtilityController.logActivity';
import getRelatedAccountId from '@salesforce/apex/UtilityController.getRelatedAccountId';
import USER_ID from '@salesforce/user/Id';

export default class ExposeUserLogActivity extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api screenName; // Optional input from App Builder

    accountId;
    connectedCallback() {
        const screen = this.screenName || `${this.objectApiName || 'Unknown'} Page`;
        this.logUserActivity(screen);
    }

    /**
     * Retrieves the related Account ID from the Task and logs the activity.
     * @param {String} screen - Name of the screen for logging.
     */
    // resolveAccountAndLog(screen) {
    //     getRelatedId({ id: this.recordId })
    //         .then(accountId => {
    //             if (accountId) {
    //                 this.accountId = accountId;
    //                 this.logUserActivity(screen);
    //             } else {
    //                 console.warn('[ExposeUserLogActivity] No related Account found for this Task.');
    //             }
    //         })
    //         .catch(error => {
    //             console.error('[ExposeUserLogActivity] Failed to retrieve Account:', error);
    //         });
    // }

    /**
     * Sends user activity details to Apex for logging.
     * @param {String} screen - Screen name to log.
     */
    logUserActivity(screen) {
        const activityPayload = {
            // accountId: this.accountId,
            userId: USER_ID,
            pageScreenName: screen,
            actionPerformed: false,
            actionTakenTime: null,
            recordId: this.recordId,
            // transactionId: null,
            // disputeId: null,
            additionalMetadata: JSON.stringify({ source: 'LWC Logger' })
        };

        const jsonInput = JSON.stringify(activityPayload);

        logActivity({ inputParamsJson: jsonInput })
            .then(() => {
                console.log('[ExposeUserLogActivity] User activity logged successfully.');
            })
            .catch(error => {
                console.error('[ExposeUserLogActivity] Error logging user activity:', error);
            });
    }
}