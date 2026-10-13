import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getChildAccounts from '@salesforce/apex/AkzoAccountDetailController.getChildAccounts';
import LATEST_CREDIT_REVIEW_STATUS from '@salesforce/schema/Account.Latest_Credit_Review_Status__c';
import labelLatestCreditReview from '@salesforce/label/c.SRM_AD_Latest_Credit_Review';
import labelIsParentAccount from '@salesforce/label/c.Is_Parent_Account';
import labelCLRStatus from '@salesforce/label/c.CLR_Status';

/**
 * Set to true when deploying to an org with the celsrm managed package installed.
 * Set to false for unmanaged / unpackaged orgs.
 */
const IS_MANAGED = true;
const NS = IS_MANAGED ? 'celsrm__' : '';

const REVIEW_ID_FIELD = 'Account.' + NS + 'Latest_Credit_Review__c';
const REVIEW_NUMBER_FIELD = 'Account.' + NS + 'Latest_Credit_Review__r.Name';

const FIELDS = [REVIEW_ID_FIELD, REVIEW_NUMBER_FIELD, LATEST_CREDIT_REVIEW_STATUS];

export default class LatestCreditReviewCard extends NavigationMixin(LightningElement) {
  label = {
    latestCreditReview: labelLatestCreditReview,
  };

  isParentAccount = null;

  _recordId;

  @api
  get recordId() {
    return this._recordId;
  }
  set recordId(value) {
    this._recordId = value;
    if (value) this.loadParentIndicator();
  }

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  acc;

  connectedCallback() {
    if (this.recordId) this.loadParentIndicator();
  }

  loadParentIndicator() {
    getChildAccounts({ recordId: this.recordId })
      .then((result) => {
        this.isParentAccount = result && result.length > 0 ? 'Yes' : 'No';
      })
      .catch((error) => {
        console.error('LatestCreditReviewCard: getChildAccounts error', error);
        this.isParentAccount = null;
      });
  }

  get infoRows() {
    const data = this.acc && this.acc.data;
    const reviewId = data ? getFieldValue(data, REVIEW_ID_FIELD) : null;
    const reviewNumber = data ? getFieldValue(data, REVIEW_NUMBER_FIELD) : null;
    const status = data ? getFieldValue(data, LATEST_CREDIT_REVIEW_STATUS) : null;

    return [
      {
        key: '1',
        label: labelIsParentAccount,
        value: this.isParentAccount != null ? this.isParentAccount : '—',
        iconName: 'utility:hierarchy',
        iconClass: 'icon-indigo',
        isLink: false,
      },
      {
        key: '2',
        label: labelLatestCreditReview,
        value: reviewNumber != null ? reviewNumber : '—',
        iconName: 'utility:record',
        iconClass: 'icon-blue',
        isLink: !!reviewId,
        reviewId,
        reviewLink: reviewId ? '/lightning/r/' + reviewId + '/view' : null,
      },
      {
        key: '3',
        label: labelCLRStatus,
        value: status != null ? status : '—',
        iconName: 'utility:check',
        iconClass: 'icon-teal',
        isLink: false,
      },
    ];
  }

  handleRowClick(event) {
    const recordId = event.currentTarget.dataset.link;
    if (recordId) {
      event.preventDefault();
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId, actionName: 'view' },
      });
    }
  }
}