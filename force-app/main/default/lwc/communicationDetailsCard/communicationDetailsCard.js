import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getDefaultContactRecord from '@salesforce/apex/ContactController.getDefaultContactRecord';
import getLatestTreatmentTask from '@salesforce/apex/ContactController.getLatestTreatmentTask';
import LOCALE from '@salesforce/i18n/locale';
import labelCommunicationDetails from '@salesforce/label/c.Communication_Details';
import labelContactName from '@salesforce/label/c.Contact_Name';
import labelContactPhone from '@salesforce/label/c.Contact_Phone';
import labelMobilePhone from '@salesforce/label/c.Mobile_Phone';
import labelEmail from '@salesforce/label/c.Email';
import labelTitle from '@salesforce/label/c.Title';
import labelLastContactDate from '@salesforce/label/c.Last_Contact_Date';
import labelLastContactMethod from '@salesforce/label/c.Last_Contact_Method';
import labelTask from '@salesforce/label/c.Task';

/**
 * Set to true when deploying to an org with the celsrm managed package installed.
 * Set to false for unmanaged / unpackaged orgs.
 */
const IS_MANAGED = true;
const NS = IS_MANAGED ? 'celsrm__' : '';

const LAST_CONTACT_DATE   = { objectApiName: 'Account', fieldApiName: NS + 'Last_Contact_Date__c' };
const LAST_CONTACT_METHOD = { objectApiName: 'Account', fieldApiName: NS + 'Last_Contact_Method__c' };

const ACCOUNT_FIELDS = [LAST_CONTACT_DATE, LAST_CONTACT_METHOD];

export default class CommunicationDetailsCard extends NavigationMixin(LightningElement) {
  label = { communicationDetails: labelCommunicationDetails };

  _recordId;

  @api
  get recordId() {
    return this._recordId;
  }
  set recordId(value) {
    this._recordId = value;
    this._loadContactData();
  }

  defContact;
  treatmentTask;
  lastContactDate;
  lastContactMethod;

  @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
  wiredAccount({ data }) {
    if (data) {
      const value = getFieldValue(data, LAST_CONTACT_DATE);
      if (value) {
        const d = new Date(value);
        this.lastContactDate = d.toLocaleString(LOCALE, { dateStyle: 'short' });
      } else {
        this.lastContactDate = '—';
      }
      this.lastContactMethod = getFieldValue(data, LAST_CONTACT_METHOD) ?? '—';
    }
  }

  connectedCallback() {
    this._loadContactData();
  }

  /** Reload contact/task when recordId is set or changes. */
  _loadContactData() {
    if (!this.recordId) return;
    getDefaultContactRecord({ recordId: this.recordId })
      .then((result) => {
        this.defContact = result || null;
      })
      .catch(() => {
        this.defContact = null;
      });
    getLatestTreatmentTask({ recordId: this.recordId })
      .then((result) => {
        if (result?.task) {
          this.treatmentTask = { ...result.task, url: '/' + result.task.Id };
        } else {
          this.treatmentTask = null;
        }
      })
      .catch(() => {
        this.treatmentTask = null;
      });
  }

  get details() {
    const rows = [];
    // Contact fields (same as gogAccountDetails Communication Details)
    if (this.defContact) {
      rows.push({ key: 'contactName', label: labelContactName, value: this.defContact.Name, iconName: 'utility:user', iconClass: 'icon-blue', isLink: true, recordId: this.defContact.Id, objectApiName: 'Contact' });
      rows.push({ key: 'contactPhone', label: labelContactPhone, value: this.defContact.Phone ?? '—', iconName: 'utility:call', iconClass: 'icon-teal', isLink: false });
      // rows.push({ key: 'mobilePhone', label: labelMobilePhone, value: this.defContact.MobilePhone ?? '—', iconName: 'utility:call', iconClass: 'icon-emerald', isLink: false });
      rows.push({ key: 'email', label: labelEmail, value: this.defContact.Email ?? '—', iconName: 'utility:email', iconClass: 'icon-purple', isLink: true, recordId: this.defContact.Id, objectApiName: 'Contact' });
      if (this.defContact.Title != null && this.defContact.Title !== '') {
        rows.push({ key: 'title', label: labelTitle, value: this.defContact.Title, iconName: 'utility:identity', iconClass: 'icon-indigo', isLink: false });
      }
    } else {
      rows.push({ key: 'contactName', label: labelContactName, value: '—', iconName: 'utility:user', iconClass: 'icon-blue', isLink: false });
      rows.push({ key: 'contactPhone', label: labelContactPhone, value: '—', iconName: 'utility:call', iconClass: 'icon-teal', isLink: false });
      rows.push({ key: 'mobilePhone', label: labelMobilePhone, value: '—', iconName: 'utility:call', iconClass: 'icon-emerald', isLink: false });
      rows.push({ key: 'email', label: labelEmail, value: '—', iconName: 'utility:email', iconClass: 'icon-purple', isLink: false });
    }
    rows.push({ key: 'lastContactDate', label: labelLastContactDate, value: this.lastContactDate ?? '—', iconName: 'utility:event', iconClass: 'icon-amber', isLink: false });
    rows.push({ key: 'lastContactMethod', label: labelLastContactMethod, value: this.lastContactMethod ?? '—', iconName: 'utility:chat', iconClass: 'icon-rose', isLink: false });
    if (this.treatmentTask) {
      rows.push({ key: 'task', label: labelTask, value: this.treatmentTask.Subject, iconName: 'utility:task', iconClass: 'icon-indigo', isLink: true, recordId: this.treatmentTask.Id, objectApiName: 'Task' });
    }
    return rows;
  }

  handleNavigate(event) {
    const recordId = event.currentTarget.dataset.recordId;
    const objectApiName = event.currentTarget.dataset.objectApiName;
    if (recordId && objectApiName) {
      event.preventDefault();
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId, objectApiName, actionName: 'view' },
      });
    }
  }
}