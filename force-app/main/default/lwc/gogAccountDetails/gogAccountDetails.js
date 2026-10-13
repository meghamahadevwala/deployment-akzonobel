import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getContactRecord from '@salesforce/apex/ContactController.getContactRecord';
import getDefaultContactRecord from '@salesforce/apex/ContactController.getDefaultContactRecord';
import getTotalOpenTask from '@salesforce/apex/ContactController.getTotalOpenTask';
import getTotalBucket from '@salesforce/apex/ContactController.getTotalBucket';
import getLatestTreatmentTask from '@salesforce/apex/ContactController.getLatestTreatmentTask';
import ACCOUNT_NUMBER_FIELD from '@salesforce/schema/Account.AccountNumber';
import COMPANY_CODE from '@salesforce/schema/Account.celsrm__Company_Code__c';
import ACCOUNT_OWNER from '@salesforce/schema/Account.Owner.Name';
import ACCOUNT_OWNER_ID from '@salesforce/schema/Account.OwnerId';
import PHONE_FIELD from '@salesforce/schema/Account.Phone';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Account.Type';
import BASE_TOTAL_AR from '@salesforce/schema/Account.celsrm__Total_AR__c';
import TOTAL_PAST_DUE from '@salesforce/schema/Account.celsrm__Total_Past_Due__c';
import BILLING_STREET from '@salesforce/schema/Account.BillingStreet';
import BILLING_CITY from '@salesforce/schema/Account.BillingCity';
import BILLING_STATE from '@salesforce/schema/Account.BillingState';
import BILLING_POSTAL_CODE from '@salesforce/schema/Account.BillingPostalCode';
import BILLING_COUNTRY from '@salesforce/schema/Account.BillingCountry';
import NOTE_FIELD from '@salesforce/schema/Account.celsrm__Latest_Note__c';
import OPEN_INVOICES from '@salesforce/schema/Account.celsrm__Open_Invoices__c';
//-- Start | FIN-6531 | Changed By Dilshad | 27 Nov 2024 --//
import AMOUNT_IMPACTED from '@salesforce/schema/Account.Impacted_Amount__c';
import AMOUNT_IMPACTED_REASON from '@salesforce/schema/Account.Impacted_Amount_Reason__c';
//-- Ends | FIN-6531 | Changed By Dilshad | 27 Nov 2024 --//
import LOCALE from '@salesforce/i18n/locale';
import CURRENT from '@salesforce/schema/Account.celsrm__Age0__c';
import FIELD_1_30 from '@salesforce/schema/Account.celsrm__Age1__c';
import PRIORITY from '@salesforce/schema/Account.Calculated_Priority__c';
import FIELD_31_60 from '@salesforce/schema/Account.celsrm__Age2__c';
import FIELD_61_90 from '@salesforce/schema/Account.celsrm__Age3__c';
import FIELD_91_180 from '@salesforce/schema/Account.celsrm__Age4__c';
import FIELD_OVER_180 from '@salesforce/schema/Account.celsrm__Age5__c';
import LAST_CONTACT_DATE from '@salesforce/schema/Account.celsrm__Last_Contact_Date__c';
import LAST_CONTACT_METHOD from '@salesforce/schema/Account.celsrm__Last_Contact_Method__c';
import PERCENT_DISPUTE from '@salesforce/schema/Account.celsrm__Percent_Disputed__c';
import NO_OF_DISPUTED_INVOICES from '@salesforce/schema/Account.No_Of_Disputed_Invoices__c';
import NO_OF_PROMISE from '@salesforce/schema/Account.No_of_Promised__c';
import CURRENCY_ISO_CODE from '@salesforce/schema/Account.CurrencyIsoCode';
import fetchStickyNotes from '@salesforce/apex/WCM_FetchAccountDetails.fetchStickyNotes';
import saveStickyNotes from '@salesforce/apex/WCM_FetchAccountDetails.saveStickyNotes';
import saveStickyNotesColor from '@salesforce/apex/WCM_FetchAccountDetails.saveStickyNotesColor';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import chartJs from '@salesforce/resourceUrl/Chartjs'
import callToCustomer from '@salesforce/apex/OutgoingCallHandler.callToCustomer';
import checkChangeStatus from '@salesforce/apex/OutgoingCallHandler.checkChangeStatus';
import isCallerIdVerified from '@salesforce/apex/OutgoingCallHandler.isCallerIdVerified';
import initCallerIDVerification from '@salesforce/apex/OutgoingCallHandler.initCallerIDVerification';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Account_Number from '@salesforce/label/c.SRM_AT_Account_Number';
import Invoice_Risk from '@salesforce/label/c.SRM_AD_Invoice_Risk';
import Dispute_Risk from '@salesforce/label/c.SRM_AD_Dispute_Risk';
import Collection_Details from '@salesforce/label/c.SRM_AD_Collection_Details';
import Company_Code from '@salesforce/label/c.Company_Code';
import Account_Owner from '@salesforce/label/c.Account_Owner';
import Total_AR from '@salesforce/label/c.SRM_AT_Total_AR';
import Total_Past_Due from '@salesforce/label/c.SRM_AD_Total_Past_Due';
import Total_Open_Invoice from '@salesforce/label/c.SRM_AD_Total_Open_Invoice';
import Total_Open_Task from '@salesforce/label/c.SRM_AD_Total_Open_Task';
import Aging_Bucket from '@salesforce/label/c.SRM_AD_Aging_Bucket';
import Current from '@salesforce/label/c.SRM_AD_Current';
import Communication_Details from '@salesforce/label/c.SRM_AD_Communication_Details';
import Latest_Note from '@salesforce/label/c.SRM_AD_Latest_Note';
import Contact_Name from '@salesforce/label/c.SRM_AD_Contact_Name';
import Contact_Phone from '@salesforce/label/c.SRM_AD_Contact_Phone';
import Email from '@salesforce/label/c.SRM_Email';
import Last_Contact_Date from '@salesforce/label/c.SRM_AD_Last_Contact_Date';
import Last_Contact_Method from '@salesforce/label/c.SRM_AD_Last_Contact_Method';
import Header_Note from '@salesforce/label/c.SRM_AD_Header_Note';
import Edit from '@salesforce/label/c.SRM_Edit';
import Cancel from '@salesforce/label/c.SRM_Cancel';
import Save from '@salesforce/label/c.SRM_Save';
import Account_Priority from '@salesforce/label/c.Account_Priority';
import Account_Health from '@salesforce/label/c.Account_Health';
import Latest_Note_For_Account from '@salesforce/label/c.Latest_Note';
import Billing_Address from '@salesforce/label/c.Billing_Address';
import TOTAL_CLOSED_INVOICES from '@salesforce/schema/Account.celsrm__Closed_Invoices__c';
import Amount_Impacted from '@salesforce/label/c.Amount_Impacted';
import Amount_Impacted_Reason from '@salesforce/label/c.Amount_Impacted_Reason';
import Total_Closed_Invoices from '@salesforce/label/c.Total_Closed_Invoices';
import Total_Disputed_Invoices from '@salesforce/label/c.Total_Disputed_Invoices';
import Total_Promised_Invoices from '@salesforce/label/c.Total_Promised_Invoices';
import Task from '@salesforce/label/c.Task';
import X1_30 from '@salesforce/label/c.X1_30';
import X31_60 from '@salesforce/label/c.X31_60';
import X61_90 from '@salesforce/label/c.X61_90';
import X91_180 from '@salesforce/label/c.X91_180';
import Over_180 from '@salesforce/label/c.Over_180';

const fields = [
    // BUSINESS_UNIT,
    ACCOUNT_NUMBER_FIELD,
    COMPANY_CODE,
    // CLERK_NAME,
    PHONE_FIELD,
    ACCOUNT_TYPE_FIELD,
    BASE_TOTAL_AR,
    TOTAL_PAST_DUE,
    CURRENT,
    FIELD_1_30,
    FIELD_31_60,
    FIELD_61_90,
    FIELD_91_180,
    FIELD_OVER_180,
    LAST_CONTACT_DATE,
    LAST_CONTACT_METHOD,
    BILLING_STREET,
    BILLING_CITY,
    BILLING_STATE,
    BILLING_POSTAL_CODE,
    BILLING_COUNTRY,
    NOTE_FIELD,
    OPEN_INVOICES,
    PERCENT_DISPUTE,
    NO_OF_DISPUTED_INVOICES,
    // AVG_RISK_PROMISE,
    NO_OF_PROMISE,
    // RISK_PERCENTAGE,
    // AVG_RISK_PRMOISE,
    // AVG_RISK_DISPUTE,
    CURRENCY_ISO_CODE,
    PRIORITY,
    TOTAL_CLOSED_INVOICES,
    AMOUNT_IMPACTED,
    AMOUNT_IMPACTED_REASON,
    ACCOUNT_OWNER,
    ACCOUNT_OWNER_ID
];

export default class GogAccountDetails extends NavigationMixin(LightningElement) {
    @api recordId;
    @wire(getRecord, { recordId: '$recordId', fields })
    acc;
    @wire(CurrentPageReference) pageRef;
    @track stickyNotes = '';
    @track isEditable = false;
    @track spanBackground = '';
    @track defCon;
    @track defContact;
    @track currentcnt;
    @track age1cnt;
    @track age2cnt;
    @track age3cnt;
    @track age4cnt;
    @track age5cnt;
    @track len;
    @track isChartJSLoaded;
    @track isChartAlreadyLoaded;
    @track accountRiskDivSize = 12;
    @track showAccountDetails = false;
    @track accountPriorityClass = 'between0_30';
    @track accountHealthClass = 'between0_30'
    @track avgTXRiskColorClass = 'between0_30';
    @track avgDisputeRiskColorClass = 'between0_30';
    @track riskPercent;
    @track invoiceRiskPer = 0.0;
    @track disputeRiskPer = 0.0;
    @track headerNoteContentWidth = 'width:auto;';
    @track isDetailHighlightPanel = true;
    @track currencyISOCode = 'USD';
    @track totalARShortForm;
    @track totalPassDueShortForm;
    @track currentShortForm;
    @track filed1_30ShortForm;
    @track filed31_60ShortForm;
    @track filed61_90ShortForm;
    @track filed91_180ShortForm;
    @track filedOver_180ShortForm;

    @track unreadcnt;
    @track isOpenContact = false;
    @track showCallButton = false;
    @track CustomerCommunicationId;
    @track bucketRecCnt;
    @track checkStickyPopup;
    @track openCallerIdVerified;
    @track verifiedMessage;
    @track UserPhoneNumber;
    @track OTPMessage;
    @track callLogDetails;
    @track errorMessage;
    @track successMessage;
    @track TreatmentTask;
    @track drivingTransactionTotalBalance;
    @track drivingTransactionTotalCount = 0;
    @track treatmentStage;
    @track totalDTShortForm;
    @track stepNameList = undefined;
    @track latestNotes;
    label = {
        Account_Number,
        Invoice_Risk,
        Dispute_Risk,
        Collection_Details,
        Total_AR,
        Total_Past_Due,
        Total_Open_Invoice,
        Total_Open_Task,
        Aging_Bucket,
        Current,
        Communication_Details,
        Latest_Note,
        Contact_Name,
        Contact_Phone,
        Email,
        Last_Contact_Date,
        Last_Contact_Method,
        Header_Note,
        Latest_Note_For_Account,
        Edit,
        Cancel,
        Save,
        Account_Priority,
        Account_Health,
        Billing_Address,
        Total_Closed_Invoices,
        // Clerk_Name,
        Company_Code,
        Amount_Impacted,
        Amount_Impacted_Reason,
        Account_Owner,
        X1_30,
        X31_60,
        X61_90,
        X91_180,
        Over_180,
        Total_Disputed_Invoices,
        Total_Promised_Invoices,
        Task
        
    }
    converter(temp) {
        var finalValue;
        if (temp == null) { return null }

        if (String(temp).substring(0, String(temp).indexOf('.'))) {
            if (String(temp).substring(0, String(temp).indexOf('.')).length >= 10) {
                temp = String(temp / 1000000000);
                finalValue = temp.substring(0, temp.indexOf('.') + 3) + 'B';
            }
            else if (String(temp).substring(0, String(temp).indexOf('.')).length >= 7) {
                temp = String(temp / 1000000);
                finalValue = temp.substring(0, temp.indexOf('.') + 3) + 'M';
            }
            else if (String(temp).substring(0, String(temp).indexOf('.')).length >= 4) {
                temp = String(temp / 1000);
                finalValue = temp.substring(0, temp.indexOf('.')) + 'k';
            }
            else if (String(temp).substring(0, String(temp).indexOf('.')).length <= 3) {
                finalValue = String(temp);
            }
            //finalValue = '$' + finalValue;
        }
        else {

            if (String(temp).length >= 10) {
                temp = String(temp / 1000000000);
                finalValue = (temp.indexOf('.') > 0 ? temp.substring(0, temp.indexOf('.') + 3) + 'B' : temp + 'B');
            }
            else if (String(temp).length >= 7) {
                temp = String(temp / 1000000);
                finalValue = (temp.indexOf('.') > 0 ? temp.substring(0, temp.indexOf('.') + 3) + 'M' : temp + 'M');
            }
            else if (String(temp).length >= 4) {
                temp = String(temp / 1000);
                finalValue = (temp.indexOf('.') > 0 ? temp.substring(0, temp.indexOf('.')) + 'k' : temp + 'k');
            }
            else if (String(temp).substring(0, String(temp).indexOf('.')).length <= 3) {
                finalValue = String(temp);
            }
            //finalValue = '$' + finalValue;
        }
        return finalValue;
    }
    connectedCallback() {
        //this.len = getTotalOpenTask({ recordId: this.recordId });
        registerListener('updateLatestNote', this.updateLatestNote, this);

        this.isChartJSLoaded = false;
        this.isChartAlreadyLoaded = false;
        Promise.all([
            loadScript(this, chartJs)
        ]).then(() => {
            this.isChartJSLoaded = true;
        });

        getContactRecord({ recordId: this.recordId })
            .then(result => {
                if (result && result.length > 0) {
                    //console.log('gettting contact @@@ : ' + JSON.stringify(result));
                    this.defCon = result[0];
                }
            })
            .catch(error => {
                this.error = error;
                this.defCon = undefined;
            });

        getDefaultContactRecord({ recordId: this.recordId })
            .then(result => {
                if (result) {
                    //console.log('gettting contact @@@ : ' + JSON.stringify(result));
                    this.defContact = result;
                }
            })
            .catch(error => {
                this.error = error;
                this.defContact = undefined;
            });



        // fetchCurrencyISOCode({ recordId: this.recordId })
        // .then(result => {
        // 	if (result && result.length > 0) {
        // 		this.currencyISOCode = result;
        // 	}
        // })
        // .catch(error => {
        // 	this.error = error;
        // 	this.defCon = undefined;
        // });
        getLatestTreatmentTask({ recordId: this.recordId })
            .then(result => {
                if (result) {
                    let task = result.task;
                    this.TreatmentTask = task;
                    this.TreatmentTask.url = '/' + this.TreatmentTask.Id;
                    this.drivingTransactionTotalBalance = result.totalBalace;
                    this.drivingTransactionTotalCount = result.totalcount;
                    this.treatmentStage = result.treatmentStage;
                    this.stepNameList = result.stepNameList;
                    // if (stepNameList !== undefined) {
                    //     this.treatmentStageHelp = '<table> <tr> '
                    //     for(let step of stepNameList){
                    //         if (step === this.treatmentStage) {
                    //             this.treatmentStageHelp += '<td style="border: 2px dashed red">step</td>';
                    //         } else {
                    //             this.treatmentStageHelp += '<td style="border: 1px solid #dddddd;">step</td>';
                    //         }
                    //     }
                    //     this.treatmentStageHelp = '</tr></table> '
                    // }

                }

                // this.TreatmentTask = {};
                // this.TreatmentTask.subject = '<a href="' + '/'+ result1.Id + '"' + ' target="_blank">' +  result1.Subject + '</a>'
            })
            .catch(error => {
                this.error = error;
                this.TreatmentTask = undefined;
            });
            console.log('this.recordId=' + this.recordId);
        getTotalOpenTask({ recordId: this.recordId })
            .then(result => {
                this.len = result
            })
            .catch(error => {
                this.error = error;
                this.len = undefined;
            });
        console.log('######## this.recordId : ' + this.recordId);
        getTotalBucket({ recordId: this.recordId }).then(result => {
            console.log('######## this.recordId : ' + JSON.stringify(result));
            this.bucketRecCnt = result;
            //} 
        })
            .catch(error => {
                this.error = error;
                this.len = undefined;
            });

        fetchStickyNotes({
            recordId: this.recordId
        }).then(result => {
            if (result) {
                if (result.hasOwnProperty('celsrm__Sticky_Note__c') && result.celsrm__Sticky_Note__c) {
                    this.stickyNotes = result.celsrm__Sticky_Note__c;
                    this.headerNoteContentWidth = 'width:100%';
                }
                if (result.hasOwnProperty('celsrm__Sticky_Note_Color__c') && result.celsrm__Sticky_Note_Color__c) {
                    this.spanBackground = 'background:' + result.celsrm__Sticky_Note_Color__c;
                }
                if (result.hasOwnProperty('celsrm__Latest_Note__c') && result.celsrm__Latest_Note__c) {
                    this.latestNotes = result.celsrm__Latest_Note__c;
                    this.headerNoteContentWidth = 'width:100%';
                }
            }
        }).catch(error => {
            console.log('error>>>' + error);
        });
    }
    // bucketRange( start,  ending){

    //     getTotalBucketInvoice({ recordId: this.recordId,
    //                         StratingRange:start,
    //                         endingRange: ending })
    //     .then(result => {
    //         // if (result > 0) {
    //         //console.log('gettting Task @@@ : ' + JSON.stringify(result));
    //         this.currentcnt =  result;
    //         //} 
    //     })
    //     .catch(error => {
    //         this.error = error;
    //         this.len = undefined;
    //     });

    // }
    // get businessUnit() {
    //     return getFieldValue(this.acc.data, BUSINESS_UNIT);
    // }

    get accountNumber() {
        return getFieldValue(this.acc.data, ACCOUNT_NUMBER_FIELD);
    }

    get companyCode() {
        return getFieldValue(this.acc.data, COMPANY_CODE);
    }

    get accountOwnerName() {
        return getFieldValue(this.acc.data, ACCOUNT_OWNER);
    }
    get accountOwnerId() {
        return getFieldValue(this.acc.data, ACCOUNT_OWNER_ID);
    }
    get ownerLink() {
        return `/lightning/r/User/${this.accountOwnerId}/view`;
    }

    get billingStreet() {
        return getFieldValue(this.acc.data, BILLING_STREET);
    }
    get billingCity() {
        return getFieldValue(this.acc.data, BILLING_CITY);
    }
    get billingCountry() {
        return getFieldValue(this.acc.data, BILLING_COUNTRY);
    }
    get billingProvince() {
        return getFieldValue(this.acc.data, BILLING_STATE);
    }
    get billingPostalCode() {
        return getFieldValue(this.acc.data, BILLING_POSTAL_CODE);
    }
    get totalClosedInvoices() {
        return getFieldValue(this.acc.data, TOTAL_CLOSED_INVOICES);
    }

    get baseTotalAR() {
        var temp = getFieldValue(this.acc.data, BASE_TOTAL_AR);
        let currencyCode = getFieldValue(this.acc.data, CURRENCY_ISO_CODE) ? getFieldValue(this.acc.data, CURRENCY_ISO_CODE): 'USD';
        var valuetoReturn = Intl.NumberFormat(LOCALE, {
            notation: "compact",
            compactDisplay: "short",
            maximumFractionDigits: "2",
            style: 'currency',
            currency: currencyCode
          }).format(temp);

        return valuetoReturn;
    }
    get totalPastDue() {
        var temp = getFieldValue(this.acc.data, TOTAL_PAST_DUE);
        let currencyCode = getFieldValue(this.acc.data, CURRENCY_ISO_CODE) ? getFieldValue(this.acc.data, CURRENCY_ISO_CODE): 'USD';
        var valuetoReturn = Intl.NumberFormat(LOCALE, {
            notation: "compact",
            compactDisplay: "short",
            maximumFractionDigits: "2",
            style: 'currency',
            currency: currencyCode
          }).format(temp);
        return valuetoReturn;
    }
    get note() {
        return getFieldValue(this.acc.data, NOTE_FIELD);
    }

    get percentageDispute() {
        return getFieldValue(this.acc.data, PERCENT_DISPUTE);
    }

    get numberOfDisputedInvoices() {
        return getFieldValue(this.acc.data, NO_OF_DISPUTED_INVOICES);
    }

    // get averageRiskPromise(){
    // 	return getFieldValue(this.acc.data, AVG_RISK_PROMISE);
    // }

    get numberOfpromise() {
        return getFieldValue(this.acc.data, NO_OF_PROMISE);
    }

    // get avgRiskPromise(){
    // 	var avgRiskPromise = getFieldValue(this.acc.data, AVG_RISK_PRMOISE);

    //     if(avgRiskPromise){
    //         var avgTXRiskInt = parseInt(avgRiskPromise);

    //         if(avgTXRiskInt > 50){
    //             this.avgTXRiskColorClass = 'over50';
    //         }else if(avgTXRiskInt > 30 && avgTXRiskInt <= 50){
    //             this.avgTXRiskColorClass = 'between30_50';
    //         }else{
    //             this.avgTXRiskColorClass = 'between0_30';
    //         }

    //         avgRiskPromise = parseFloat(avgRiskPromise).toFixed(2);

    //         this.invoiceRiskPer = avgRiskPromise;
    //     }

    // }

    // get avgRiskDispute(){
    // 	var avgRiskDispute = getFieldValue(this.acc.data, AVG_RISK_DISPUTE);

    //     if(avgRiskDispute){
    //         var avgTXRiskInt = parseInt(avgRiskDispute);

    //         if(avgTXRiskInt > 50){
    //             this.avgDisputeRiskColorClass = 'over50';
    //         }else if(avgTXRiskInt > 30 && avgTXRiskInt <= 50){
    //             this.avgDisputeRiskColorClass = 'between30_50';
    //         }else{
    //             this.avgDisputeRiskColorClass = 'between0_30';
    //         }

    //         avgRiskDispute = parseFloat(avgRiskDispute).toFixed(2);

    // 		this.disputeRiskPer = avgRiskDispute;
    //     }
    // }

    // get riskPercentage(){
    //     var temp =  getFieldValue(this.acc.data, RISK_PERCENTAGE);

    //     var percentRiskStr = (temp != undefined && temp != null ? parseFloat(temp).toFixed(2) : 0);

    //     var percentRiskInt = parseInt(percentRiskStr);

    //     if(percentRiskInt > 50){
    //         this.accountRiskColorClass = 'over50';
    //     }else if(percentRiskInt > 30 && percentRiskInt <= 50){
    //         this.accountRiskColorClass = 'between30_50';
    //     }else{
    //         this.accountRiskColorClass = 'between0_30';
    //     }

    // 	this.riskPercent =  percentRiskStr;
    // }
    get accountPriority() {
        if (this.acc.data) {
            var accPr = getFieldValue(this.acc.data, PRIORITY);
            var valuetoReturn = Intl.NumberFormat(LOCALE, {
                maximumFractionDigits: "2",
                style: 'percent'
              }).format(accPr/100);
            if (accPr > 50) {
                this.accountPriorityClass = 'over50';
                this.accountHealthClass = 'over50Health';
            } else if (accPr > 30 && accPr <= 50) {
                this.accountPriorityClass = 'between30_50';
                this.accountHealthClass = 'between30_50Health';
            } else {
                this.accountPriorityClass = 'between0_30';
                this.accountHealthClass = 'between0_30Health';
            }
            return valuetoReturn;
        } else {
            null;
        }
    }

    get current() {
        var temp = getFieldValue(this.acc.data, CURRENT);
        return (temp === undefined || temp === null || temp === '') ? 0 : temp;
    }

    get current_Formated() {
        var temp = getFieldValue(this.acc.data, CURRENT);
        let currencyCode = getFieldValue(this.acc.data, CURRENCY_ISO_CODE) ? getFieldValue(this.acc.data, CURRENCY_ISO_CODE): 'USD';
        return this.formateNumberToCurrency(temp, currencyCode);
    }

    get filed1_30() {
        var temp = getFieldValue(this.acc.data, FIELD_1_30);
        return (temp === undefined || temp === null || temp === '') ? 0 : temp;
    }

    get filed1_30_Formated() {
        var temp = getFieldValue(this.acc.data, FIELD_1_30);
        let currencyCode = getFieldValue(this.acc.data, CURRENCY_ISO_CODE) ? getFieldValue(this.acc.data, CURRENCY_ISO_CODE): 'USD';
        return this.formateNumberToCurrency(temp, currencyCode);
    }

    get filed31_60() {
        var temp = getFieldValue(this.acc.data, FIELD_31_60);
        return (temp === undefined || temp === null || temp === '') ? 0 : temp;
        //return this.converter(temp) != null ? (this.converter(temp) + (this.bucketRecCnt !== undefined && this.bucketRecCnt.hasOwnProperty('3160') ? ' (' + this.bucketRecCnt['3160']+ ')' : '')) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('3160') ? ' (' + this.bucketRecCnt['3160'] + ')' : '');
        // this.bucketRange(31,60);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get filed31_60_Formated() {
        var temp = getFieldValue(this.acc.data, FIELD_31_60);
        let currencyCode = getFieldValue(this.acc.data, CURRENCY_ISO_CODE) ? getFieldValue(this.acc.data, CURRENCY_ISO_CODE): 'USD';
        return this.formateNumberToCurrency(temp, currencyCode);
    }

    get filed61_90() {
        var temp = getFieldValue(this.acc.data, FIELD_61_90);
        return (temp === undefined || temp === null || temp === '') ? 0 : temp;
    }

    get filed61_90_Formated() {
        var temp = getFieldValue(this.acc.data, FIELD_61_90);
        let currencyCode = getFieldValue(this.acc.data, CURRENCY_ISO_CODE) ? getFieldValue(this.acc.data, CURRENCY_ISO_CODE): 'USD';
        return this.formateNumberToCurrency(temp, currencyCode);
    }

    get filed91_180() {
        var temp = getFieldValue(this.acc.data, FIELD_91_180);
        return (temp === undefined || temp === null || temp === '') ? 0 : temp;
        //return this.converter(temp) != null ? (this.converter(temp) + (this.bucketRecCnt !== undefined && this.bucketRecCnt.hasOwnProperty('91180') ? ' (' + this.bucketRecCnt['91180']+ ')' : '')) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('91180') ? ' (' + this.bucketRecCnt['91180'] + ')' : '');
        // this.bucketRange(91,180);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get filed91_180_Formated() {
        var temp = getFieldValue(this.acc.data, FIELD_91_180);
        let currencyCode = getFieldValue(this.acc.data, CURRENCY_ISO_CODE) ? getFieldValue(this.acc.data, CURRENCY_ISO_CODE): 'USD';
        return this.formateNumberToCurrency(temp, currencyCode);
    }

    get filedOver_180() {
        // return getFieldValue(this.acc.data, FIELD_OVER_180);
        var temp = getFieldValue(this.acc.data, FIELD_OVER_180);
        return (temp === undefined || temp === null || temp === '') ? 0 : temp;
        //return this.converter(temp) != null ? (this.converter(temp) + (this.bucketRecCnt !== undefined && this.bucketRecCnt.hasOwnProperty('Over180') ? ' (' + this.bucketRecCnt['Over180']+ ')' : '')) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('Over180') ? ' (' + this.bucketRecCnt['Over180'] + ')' : '');
        // this.bucketRange(180,1512456115);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get filedOver_180_Formated() {
        var temp = getFieldValue(this.acc.data, FIELD_OVER_180);
        let currencyCode = getFieldValue(this.acc.data, CURRENCY_ISO_CODE) ? getFieldValue(this.acc.data, CURRENCY_ISO_CODE): 'USD';
        return this.formateNumberToCurrency(temp, currencyCode);
    }
    get lastContactDate() {
        let value = getFieldValue(this.acc.data, LAST_CONTACT_DATE);
        let d;
        if (value) {
            d = new Date(value);
            return d.toLocaleString(LOCALE, {
                "dateStyle": "short",
            });
        } else {
            return "";
        }

    }
    get lastContactMethod() {
        return getFieldValue(this.acc.data, LAST_CONTACT_METHOD);
    }
    get totalOpenInvoiceCount() {
        return getFieldValue(this.acc.data, OPEN_INVOICES);
    }

    get amountImpacted() {
        var temp = getFieldValue(this.acc.data, AMOUNT_IMPACTED);
        let currencyCode = getFieldValue(this.acc.data, CURRENCY_ISO_CODE) ? getFieldValue(this.acc.data, CURRENCY_ISO_CODE): 'USD';
        var valuetoReturn = Intl.NumberFormat(LOCALE, {
            notation: "compact",
            compactDisplay: "short",
            maximumFractionDigits: "2",
            style: 'currency',
            currency: currencyCode
          }).format(temp);

        return valuetoReturn;
    }

    get amountImpactedReason() {
        return getFieldValue(this.acc.data, AMOUNT_IMPACTED_REASON);
    }

    viewContactDetails() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.defContact.Id,
                objectApiName: 'Contact',
                actionName: 'view'
            }
        });
    }

    checkIsEditable() {
        this.isEditable = true;
        // setTimeout(() => {
        // const inputBox = this.template.querySelector('lightning-textarea');
        // inputBox.focus();
        // },0);
    }
    openStickyPopup() {
        document.body.style.overflow = "hidden";
        this.checkStickyPopup = true;
    }
    closeStickyPopup() {
        document.body.style.overflow = "auto";
        this.checkStickyPopup = false;
    }
    showAccountDetail() {
        this.showAccountDetails = true;
        this.accountRiskDivSize = 6;
    }

    hideAccountDetail() {
        this.showAccountDetails = false;
        this.accountRiskDivSize = 12;
    }

    showDetailHighlightPanel() {
        this.isDetailHighlightPanel = true;
        var that = this;
        setTimeout(function () {
            that.isChartAlreadyLoaded = false;
        });
    }

    hideDetailHighlightPanel() {
        this.isDetailHighlightPanel = false;
    }

    checkIsEditableFalse() {
        this.isEditable = false;
    }

    updateStickyNotes(event) {
        let updateNotes = event.target.value;
        this.tempStickyNotes = updateNotes;
        if (updateNotes && updateNotes != "") {
            this.headerNoteContentWidth = 'width:100%';
        } else {
            this.headerNoteContentWidth = 'width:auto';
        }
        if (event.target.dataset.info === "inline") {
            this.stickyNotesSave(event);
        }
    }
    stickyNotesSave(event) {
        this.stickyNotes = this.tempStickyNotes;
        saveStickyNotes({
            notes: this.stickyNotes,
            recordId: this.recordId
        }).then(result => {
            if (result) {
                this.stickyNotes = result;
            }
        }).catch(error => {
            console.log('error>>>' + error);
        });
        if (event.target.dataset.info !== "inline") {
            this.checkStickyPopup = false;
            document.body.style.overflow = "auto";
        }

    }
    changeNoteColor(event) {
        let updatedColor = event.target.style.background;
        this.spanBackground = 'background:' + updatedColor;
        saveStickyNotesColor({
            noteColor: updatedColor,
            recordId: this.recordId
        }).then(result => {
            if (result) {
                this.stickyNotes = result;
            }
        }).catch(error => {
            console.log('error>>>' + error);
        });
    }

    updateLatestNote(newValues) {
        this.note = newValues;
    }
    onClickToOpenContact() {
        var contactActionElem = this.template.querySelector('[data-id="contact-action"]');
        if (contactActionElem.classList.contains("slds-hide")) {
            contactActionElem.classList.remove('slds-hide');
        } else {
            contactActionElem.classList.add("slds-hide");
        }
        // this.isOpenContact = !this.isOpenContact;
    }
    onBlurToHideContact() {
        setTimeout(() => {
            this.template.querySelector('[data-id="contact-action"]').classList.add('slds-hide');
        }, 150);
    }
    onClickToDial(event) {
        console.log('into onClickToDial>>>> ' + this.recordId);
        this.template.querySelector('[data-id="contact-action"]').classList.add('slds-hide');
        let val = {};
        val.contactNo = this.defContact[event.target.dataset.name].replace("(", "").replace(")", "").replace(/\s/g, '').replace("-", "");
        val.account = this.recordId;
        val.calledTo = this.defContact.Id;
        val.screenName = 'Contact Customer';
        isCallerIdVerified({
            values: val
        }).then(res => {
            if (!res.isCallerIdVerified) {
                this.UserPhoneNumber = res.UserPhoneNumber;
                this.verifiedMessage = 'Your ' + res.UserPhoneNumber + ' number is not verified. To verify please click on Verify button.';
                this.openCallerIdVerified = true;
                this.callLogDetails = val;
            } else {
                callToCustomer({
                    values: val
                }).then(result => {
                    if (result.CustomerCommunicationId) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: "Success",
                            message: 'Call has been initiated.',
                            variant: "Success",
                            mode: "dismissable"
                        }));
                        this.showCallButton = true;
                        this.CustomerCommunicationId = result.CustomerCommunicationId;
                        // setInterval(function(){
                        this.checkforCallButton();
                        //   }, 10000);
                    }
                }).catch(error => {
                    console.error("Error in OutgoingCallHandler.callToCustomer" + error.body.message);
                });
            }
        }).catch(error => {
            console.error("Error in OutgoingCallHandler.callToCustomer" + error.body.message);
        });

    }
    callerIDVerification() {
        let val = {};
        val.phone = this.UserPhoneNumber;
        initCallerIDVerification({
            values: val
        }).then(result => {
            if (result.OTP) {
                this.OTPMessage = 'Verification Code : <b style="font-size: x-large;">' + result.OTP + '</b>';
            }
            this.connectbwAgentAndCustomer(1);
        }).catch(error => {
            console.error("Error in OutgoingCallHandler.callToCustomer" + error.body.message);
        });
    }
    closeCallerIdVerified() {
        this.openCallerIdVerified = false;
        this.OTPMessage = '';
        this.verifiedMessage = '';
        this.errorMessage = '';
        this.successMessage = '';
    }
    connectbwAgentAndCustomer(count) {
        isCallerIdVerified({
            values: this.callLogDetails
        }).then(res => {
            if (!res.isCallerIdVerified) {
                if (count < 3) {
                    setTimeout(() => {
                        count++;
                        console.log('count >> : ' + count);
                        this.connectbwAgentAndCustomer(count);
                    }, 10000);
                } else {
                    //alert('Not able to verify caller id. Please try again');
                    this.errorMessage = 'OTP not verified';
                }
            } else {
                this.successMessage = '<p class="slds-text-align_center slds-text-heading--medium slds-text-color_success"><b>Caller ID has been verified successfully!</b></p>';
                // callToCustomer({
                //     values: this.callLogDetails
                // }).then(result => {
                //     if(result.CustomerCommunicationId){
                //         this.dispatchEvent(new ShowToastEvent({
                //             title: "Success",
                //             message: 'Call has been initiated.',
                //             variant: "Success",
                //             mode: "dismissable"
                //         }));
                //         this.showCallButton = true;
                //         this.CustomerCommunicationId = result.CustomerCommunicationId;
                //         // setInterval(function(){
                //             this.checkforCallButton();
                //         //   }, 10000);
                //     }
                // }).catch(error => {
                //     console.error("Error in OutgoingCallHandler.callToCustomer" + error.body.message);
                // });
                // this.OTPMessage = '';
                // this.verifiedMessage = '';
                // this.errorMessage = '';
                // this.openCallerIdVerified = false;
            }
        }).catch(error => {
            console.error("Error in OutgoingCallHandler.callToCustomer" + error.body.message);
        });

    }
    checkforCallButton() {
        checkChangeStatus({
            Id: this.CustomerCommunicationId,
        }).then(result => {
            if (result && result !== 'Call Initiation') {
                this.showCallButton = false;
                let message = '';
                let variant = 'Success';
                if (result == 'Call Completed') {
                    message = 'Call has been completed.';
                } else if (result == 'Call Failed') {
                    message = 'Call has been failed.';
                    variant = 'error';
                } else if (result == 'Call Cancelled') {
                    message = 'Call has been cancelled.';
                    variant = 'error';
                }
                if (message != '') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: variant,
                        message: message,
                        variant: variant,
                        mode: "dismissable"
                    }));
                }
            } else {
                setTimeout(() => {
                    this.checkforCallButton();
                }, 2000);
            }
        }).catch(error => {
            console.error("Error in OutgoingCallHandler.checkChangeStatus" + error.body.message);
        });

    }
    get chartData() {

        if (this.isChartJSLoaded && !this.isChartAlreadyLoaded) {
            var dataVal = [];
            dataVal.push((this.current != undefined && this.current != null && this.current != '' ? this.current : 0));
            dataVal.push((this.filed1_30 != undefined && this.filed1_30 != null && this.filed1_30 != '' ? this.filed1_30 : 0));
            dataVal.push((this.filed31_60 != undefined && this.filed31_60 != null && this.filed31_60 != '' ? this.filed31_60 : 0));
            dataVal.push((this.filed61_90 != undefined && this.filed61_90 != null && this.filed61_90 != '' ? this.filed61_90 : 0));
            dataVal.push((this.filed91_180 != undefined && this.filed91_180 != null && this.filed91_180 != '' ? this.filed91_180 : 0));
            dataVal.push((this.filedOver_180 != undefined && this.filedOver_180 != null && this.filedOver_180 != '' ? this.filedOver_180 : 0));
            // inputBox.focus();
            var that = this;
            var ctx = this.template.querySelector('.pieChartContainer');
            if (ctx != null) {
                ctx.height = 110;
                ctx.width = 110;
                new Chart(ctx, {
                    type: 'pie',
                    data: {
                        labels: [this.label.Current, this.label.X1_30, this.label.X31_60, this.label.X61_90, this.label.X91_180, this.label.Over_180],
                        datasets: [{
                            label: "value",
                            backgroundColor: ["#00a1e0", "#16325c", "#76ded9", "#08a69e", "#e2ce7d", "#e49f01"],
                            data: dataVal
                        }]
                    },
                    options: {
                        legend: { display: false },
                        title: {
                            display: false,
                            text: 'Aging'
                        },
                        responsive: false,
                        maintainAspectRatio: false,
                        events: ['mousemove', 'mouseout', 'touchstart', 'touchmove'],
                        tooltips: {
                            enabled: true,
                            callbacks: {
                                label: function (tooltipItem, data) {
                                    return data.labels[tooltipItem['index']] + ':' + that.converter(data['datasets'][0]['data'][tooltipItem['index']]);
                                }
                            }

                        },
                        animation: {
                            onComplete: function (animation) {
                                var isAllBlank = true;
                                dataVal.forEach(function (v, i) {
                                    if (v != null && v > 0) {
                                        isAllBlank = false;
                                    }
                                });
                                if (!isAllBlank) {
                                    that.isChartAlreadyLoaded = true;
                                }
                            }
                        }
                    }
                });
            }

        }
    }

    // get accountRisk(){
    //     fetchAverageDisputeRisk({
    //         recordId: this.recordId
    //     }).then(result => {
    //         if(result){

    // 			var perDispute  = (this.percentageDispute != undefined && this.percentageDispute != null && this.percentageDispute != '' ? this.percentageDispute : 0);

    //             console.log('perDispute : ' + perDispute);


    // 			var nuOfDis = (this.numberOfDispute != undefined && this.numberOfDispute != null && this.numberOfDispute != '' ? this.numberOfDispute : 0);

    // 			console.log('nuOfDis : ' + nuOfDis);

    // 			var totalOpnTx = (this.totalOpenInvoiceCount != undefined && this.totalOpenInvoiceCount != null && this.totalOpenInvoiceCount != '' ? this.totalOpenInvoiceCount : 1);

    // 			console.log('totalOpnTx : ' + totalOpnTx);

    //             var dispRisk = (result != undefined && result != null && result != '' ? result : 0);

    // 			console.log('avg dispRisk : ' + dispRisk);

    // 			var avgRskProm = (this.averageRiskPromise != undefined && this.averageRiskPromise != null && this.averageRiskPromise != '' ? this.averageRiskPromise : 0);

    // 			console.log('Avg risk promise : ' + avgRskProm);

    // 			var numOfProm = (this.numberOfpromise != undefined && this.numberOfpromise != null && this.numberOfpromise != '' ? this.numberOfpromise : 0);

    // 			console.log('no  promise : ' + numOfProm);

    // 			var finalRisk  = ((perDispute * 0.10) + ((nuOfDis / totalOpnTx) * 0.10) + (dispRisk * 0.80)) - ( (avgRskProm * 100) * ((numOfProm / totalOpnTx)));
    // 			this.disputeRisk = finalRisk.toFixed(2);

    //         }
    //     }).catch(error => {
    //         console.log('error>>>'+error);
    //     });
    // }
    formateNumberToCurrency (numberToFormat, currencyCode) {
        return Intl.NumberFormat(LOCALE, {
            notation: "compact",
            compactDisplay: "short",
            maximumFractionDigits: "2",
            style: 'currency',
            currency: currencyCode
          }).format(numberToFormat);
    }
}