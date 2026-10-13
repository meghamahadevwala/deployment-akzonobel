import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CURRENCY_ISO_CODE from '@salesforce/schema/Account.CurrencyIsoCode';
import LOCALE from '@salesforce/i18n/locale';
import labelAgingBucket from '@salesforce/label/c.Aging_Bucket';

/**
 * Set to true when deploying to an org with the celsrm managed package installed.
 * Set to false for unmanaged / unpackaged orgs.
 */
const IS_MANAGED = true;
const NS = IS_MANAGED ? 'celsrm__' : '';

const FIELD_MAP = {
  CURRENT:  { objectApiName: 'Account', fieldApiName: NS + 'Age0__c' },
  AGE_1_30: { objectApiName: 'Account', fieldApiName: NS + 'Age1__c' },
  AGE_31_60:{ objectApiName: 'Account', fieldApiName: NS + 'Age2__c' },
  AGE_61_90:{ objectApiName: 'Account', fieldApiName: NS + 'Age3__c' },
  AGE_91_180:{ objectApiName: 'Account', fieldApiName: NS + 'Age4__c' },
  AGE_OVER_180:{ objectApiName: 'Account', fieldApiName: NS + 'Age5__c' },
};

const FIELDS = [...Object.values(FIELD_MAP), CURRENCY_ISO_CODE];

const BUCKET_CONFIG = [
  { name: 'Current', field: FIELD_MAP.CURRENT, color: '#00a1e0' },
  { name: '1-30', field: FIELD_MAP.AGE_1_30, color: '#16325c' },
  { name: '31-60', field: FIELD_MAP.AGE_31_60, color: '#76ded9' },
  { name: '61-90', field: FIELD_MAP.AGE_61_90, color: '#08a69e' },
  { name: '91-180', field: FIELD_MAP.AGE_91_180, color: '#e2ce7d' },
  { name: 'Over 180', field: FIELD_MAP.AGE_OVER_180, color: '#e49f01' },
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

export default class AgingBucketCard extends LightningElement {
  @api recordId;

  label = { agingBucket: labelAgingBucket };

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  acc;

  get bucketData() {
    if (!this.acc?.data) return [];
    const data = this.acc.data;
    const currencyCode = getFieldValue(data, CURRENCY_ISO_CODE) || 'USD';
    return BUCKET_CONFIG.map((config, idx) => {
      const raw = getFieldValue(data, config.field);
      const num = raw === undefined || raw === null || raw === '' ? 0 : Number(raw);
      return {
        key: String(idx),
        name: config.name,
        value: num,
        valueFormatted: formatCurrency(num, currencyCode),
        dotStyle: `background-color: ${config.color}`,
        valueStyle: `color: ${config.color}`,
        color: config.color,
      };
    });
  }

  get total() {
    const data = this.bucketData;
    return data.reduce((sum, d) => sum + (d.value || 0), 0);
  }

  /** Sum of absolute values for chart proportions so negative buckets still render as segments */
  get chartTotal() {
    const data = this.bucketData;
    return data.reduce((sum, d) => sum + Math.abs(d.value || 0), 0);
  }

  get chartSegments() {
    const data = this.bucketData;
    const total = this.chartTotal;
    if (total <= 0) return data.map((d) => ({ ...d, dashArray: '0 276', dashOffset: 0 }));
    const circumference = 2 * Math.PI * 44;
    let offset = 0;
    return data.map((d) => {
      const magnitude = Math.abs(d.value || 0);
      const pct = magnitude / total;
      const dashLength = pct * circumference;
      const dash = dashLength.toFixed(1) + ' ' + (circumference - dashLength).toFixed(1);
      const seg = { ...d, dashArray: dash, dashOffset: -offset, isNegative: (d.value || 0) < 0 };
      offset += dashLength;
      return seg;
    });
  }
}