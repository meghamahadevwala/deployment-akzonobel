import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CURRENCY_ISO_CODE from '@salesforce/schema/Account.CurrencyIsoCode';
import LOCALE from '@salesforce/i18n/locale';
import labelCollectionDetails from '@salesforce/label/c.Collection_Details';
import labelTotalAR from '@salesforce/label/c.Total_AR';
import labelTotalPastDue from '@salesforce/label/c.Total_Past_Due';
import labelTotalOpenInvoices from '@salesforce/label/c.Total_Open_Invoices';
import labelClosedInvoices from '@salesforce/label/c.Closed_Invoices';
import labelDisputedInvoices from '@salesforce/label/c.Disputed_Invoices';
import labelPromisedInvoices from '@salesforce/label/c.Promised_Invoices';

/**
 * Set to true when deploying to an org with the celsrm managed package installed.
 * Set to false for unmanaged / unpackaged orgs.
 */
const IS_MANAGED = true;
const NS = IS_MANAGED ? 'celsrm__' : '';

const BASE_TOTAL_AR          = { objectApiName: 'Account', fieldApiName: NS + 'Total_AR__c' };
const TOTAL_PAST_DUE         = { objectApiName: 'Account', fieldApiName: NS + 'Total_Past_Due__c' };
const OPEN_INVOICES          = { objectApiName: 'Account', fieldApiName: NS + 'Open_Invoices__c' };
const TOTAL_CLOSED_INVOICES  = { objectApiName: 'Account', fieldApiName: NS + 'Closed_Invoices__c' };
const NO_OF_DISPUTED_INVOICES = { objectApiName: 'Account', fieldApiName: 'No_Of_Disputed_Invoices__c' };
const NO_OF_PROMISE          = { objectApiName: 'Account', fieldApiName: 'No_of_Promised__c' };

const FIELDS = [
  BASE_TOTAL_AR,
  TOTAL_PAST_DUE,
  OPEN_INVOICES,
  TOTAL_CLOSED_INVOICES,
  NO_OF_DISPUTED_INVOICES,
  NO_OF_PROMISE,
  CURRENCY_ISO_CODE,
];

function formatCurrency(value, currencyCode) {
  if (value == null) return '—';
  return Intl.NumberFormat(LOCALE, {
    notation: 'compact',
    compactDisplay: 'short',
    maximumFractionDigits: 2,
    style: 'currency',
    currency: currencyCode || 'USD',
  }).format(value);
}

export default class CollectionDetailsCard extends LightningElement {
  @api recordId;

  label = { collectionDetails: labelCollectionDetails };

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  acc;

  get details() {
    if (!this.acc?.data) return [];
    const data = this.acc.data;
    const currencyCode = getFieldValue(data, CURRENCY_ISO_CODE) || 'USD';
    const totalAR = getFieldValue(data, BASE_TOTAL_AR);
    const totalPastDue = getFieldValue(data, TOTAL_PAST_DUE);
    return [
      { key: '1', label: labelTotalAR, value: formatCurrency(totalAR, currencyCode), iconName: 'utility:moneybag', iconClass: 'icon-blue', isHighlight: false },
      { key: '2', label: labelTotalPastDue, value: formatCurrency(totalPastDue, currencyCode), iconName: 'utility:clock', iconClass: 'icon-red', isHighlight: true },
      { key: '3', label: labelTotalOpenInvoices, value: String(getFieldValue(data, OPEN_INVOICES) ?? '—'), iconName: 'utility:description', iconClass: 'icon-indigo', isHighlight: false },
      { key: '4', label: labelClosedInvoices, value: String(getFieldValue(data, TOTAL_CLOSED_INVOICES) ?? '—'), iconName: 'utility:success', iconClass: 'icon-green', isHighlight: false },
      { key: '5', label: labelDisputedInvoices, value: String(getFieldValue(data, NO_OF_DISPUTED_INVOICES) ?? '—'), iconName: 'utility:warning', iconClass: 'icon-amber', isHighlight: false },
      { key: '6', label: labelPromisedInvoices, value: String(getFieldValue(data, NO_OF_PROMISE) ?? '—'), iconName: 'utility:task', iconClass: 'icon-teal', isHighlight: false },
    ];
  }
}