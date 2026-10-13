import { LightningElement, wire } from 'lwc';
import getDeterioratedAccounts from '@salesforce/apex/DeterioratedAccountsController.getDeterioratedAccounts';

const COLUMNS = [
    { label: 'Account Number', fieldName: 'accountNumber', type: 'text' },
    { label: "Moody's Risk Class", fieldName: 'moodysRiskClass', type: 'text' },
    { label: "Moody's Credit Limit", fieldName: 'moodysCreditLimit', type: 'currency' }
];

export default class DeterioratedAccountsList extends LightningElement {
    columns = COLUMNS;
    accounts;
    error;

    @wire(getDeterioratedAccounts)
    wiredAccounts({ data, error }) {
        if (data) {
            this.accounts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accounts = undefined;
        }
    }

    get accountCount() {
        return this.accounts ? this.accounts.length : 0;
    }

    get hasAccounts() {
        return this.accounts && this.accounts.length > 0;
    }

    get hasError() {
        return this.error != null;
    }

    get errorMessage() {
        return this.error && this.error.body ? this.error.body.message : '';
    }
}