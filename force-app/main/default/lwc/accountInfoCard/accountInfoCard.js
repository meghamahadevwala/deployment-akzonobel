import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import ACCOUNT_NUMBER_FIELD from '@salesforce/schema/Account.AccountNumber';
import COMPANY_CODE from '@salesforce/schema/Account.celsrm__Company_Code__c';
import ACCOUNT_OWNER from '@salesforce/schema/Account.Owner.Name';
import ACCOUNT_OWNER_ID from '@salesforce/schema/Account.OwnerId';
import PRIORITY from '@salesforce/schema/Account.Calculated_Priority__c';
import AMOUNT_IMPACTED from '@salesforce/schema/Account.Impacted_Amount__c';
import AMOUNT_IMPACTED_REASON from '@salesforce/schema/Account.Impacted_Amount_Reason__c';
import CURRENCY_ISO_CODE from '@salesforce/schema/Account.CurrencyIsoCode';
import LOCALE from '@salesforce/i18n/locale';
import labelAccountInfo from '@salesforce/label/c.Account_Info';
import labelAccountPriority from '@salesforce/label/c.Account_Priority';
import labelAccountNumber from '@salesforce/label/c.Account_Number';
import labelCompanyCode from '@salesforce/label/c.Company_Code';
import labelAccountOwner from '@salesforce/label/c.Account_Owner';
import labelAmountImpacted from '@salesforce/label/c.Amount_Impacted';
import labelImpactReason from '@salesforce/label/c.Impact_Reason';

const FIELDS = [
  ACCOUNT_NUMBER_FIELD,
  COMPANY_CODE,
  ACCOUNT_OWNER,
  ACCOUNT_OWNER_ID,
  PRIORITY,
  AMOUNT_IMPACTED,
  AMOUNT_IMPACTED_REASON,
  CURRENCY_ISO_CODE,
];

export default class AccountInfoCard extends NavigationMixin(LightningElement) {
  @api recordId;

  label = { accountInfo: labelAccountInfo };

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  acc;

  get infoRows() {
    if (!this.acc?.data) return [];
    const data = this.acc.data;
    const currencyCode = getFieldValue(data, CURRENCY_ISO_CODE) || 'USD';
    const priorityRaw = getFieldValue(data, PRIORITY);
    const accountPriority = priorityRaw != null
      ? Intl.NumberFormat(LOCALE, { maximumFractionDigits: 2, style: 'percent' }).format(priorityRaw / 100)
      : '—';
    const amountImpacted = getFieldValue(data, AMOUNT_IMPACTED);
    const amountFormatted = amountImpacted != null
      ? Intl.NumberFormat(LOCALE, {
          notation: 'compact',
          compactDisplay: 'short',
          maximumFractionDigits: 2,
          style: 'currency',
          currency: currencyCode,
        }).format(amountImpacted)
      : '—';
    const ownerId = getFieldValue(data, ACCOUNT_OWNER_ID);
    return [
      { key: '1', label: labelAccountPriority, value: accountPriority, iconName: 'utility:warning', iconClass: 'icon-amber', isLink: false },
      { key: '2', label: labelAccountNumber, value: getFieldValue(data, ACCOUNT_NUMBER_FIELD) ?? '—', iconName: 'utility:number_input', iconClass: 'icon-indigo', isLink: false },
      { key: '3', label: labelCompanyCode, value: getFieldValue(data, COMPANY_CODE) ?? '—', iconName: 'utility:company', iconClass: 'icon-teal', isLink: false },
      { key: '4', label: labelAccountOwner, value: getFieldValue(data, ACCOUNT_OWNER) ?? '—', iconName: 'utility:user', iconClass: 'icon-blue', isLink: !!ownerId, ownerId, ownerLink: ownerId ? `/lightning/r/User/${ownerId}/view` : null },
      { key: '5', label: labelAmountImpacted, value: amountFormatted, iconName: 'utility:money', iconClass: 'icon-emerald', isLink: false },
      { key: '6', label: labelImpactReason, value: getFieldValue(data, AMOUNT_IMPACTED_REASON) ?? '—', iconName: 'utility:info', iconClass: 'icon-purple', isLink: false },
    ];
  }

  handleRowClick(event) {
    const recordId = event.currentTarget.dataset.link;
    if (recordId) {
      event.preventDefault();
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId, objectApiName: 'User', actionName: 'view' },
      });
    }
  }
}