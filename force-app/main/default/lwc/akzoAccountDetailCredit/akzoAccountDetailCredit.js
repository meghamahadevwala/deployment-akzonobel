import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getContactRecord from '@salesforce/apex/ContactController.getContactRecord';
import getChildAccounts from '@salesforce/apex/AkzoAccountDetailController.getChildAccounts';
// import getParentAccountRecord from '@salesforce/apex/ContactController.getParentAccountRecord';
import getTotalOpenTask from '@salesforce/apex/ContactController.getTotalOpenTask';
import getTotalBucket from '@salesforce/apex/ContactController.getTotalBucket';
// import getLatestTreatmentTask from '@salesforce/apex/ContactController.getLatestTreatmentTask';
// import getTotalLastMonthActivity from '@salesforce/apex/ContactController.getTotalLastMonthActivity';

// import REGION from '@salesforce/schema/Account.Region__c';
import ACCOUNT_NUMBER_FIELD from '@salesforce/schema/Account.AccountNumber';
import PHONE_FIELD from '@salesforce/schema/Account.Phone';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Account.Type';
// import BUSINESS_UNIT from '@salesforce/schema/Account.Business_Unit__c';
import BASE_TOTAL_AR from '@salesforce/schema/Account.celsrm__Total_AR__c';
import TOTAL_PAST_DUE from '@salesforce/schema/Account.celsrm__Total_Past_Due__c';
// import NET_COLLECTIBLE from '@salesforce/schema/Account.Net_Collectible__c';
import BILLING_STREET from '@salesforce/schema/Account.BillingStreet';
import BILLING_CITY from '@salesforce/schema/Account.BillingCity';
import BILLING_STATE from '@salesforce/schema/Account.BillingState';
import BILLING_POSTAL_CODE from '@salesforce/schema/Account.BillingPostalCode';
import BILLING_COUNTRY from '@salesforce/schema/Account.BillingCountry';
import NOTE_FIELD from '@salesforce/schema/Account.celsrm__Latest_Note__c';
import SYSTEM_CREDIT_LIMIT from '@salesforce/schema/Account.Recommended_Credit_Limit__c';
// import TOTAL_OPEN_TRANSACTION from '@salesforce/schema/Account.Total_Open_Transaction__c';
import RISK_SCORE from '@salesforce/schema/Account.celsrm__Risk_Score__c';
// import SHORT_TERM_UTILIZATION from '@salesforce/schema/Account.Short_term_Utilization__c';
import LATEST_CREDIT_REVIEW from '@salesforce/schema/Account.celsrm__Latest_Credit_Review__c';
import LATEST_CREDIT_REVIEW_NUMBER from '@salesforce/schema/Account.celsrm__Latest_Credit_Review__r.Name';
import OPEN_BILLING_VALUE from '@salesforce/schema/Account.Open_Billing_Value__c';
import OPEN_DELIVERY_VALUE from '@salesforce/schema/Account.Open_Delivery_Value__c';
import TOTAL_ORDER_VALUE from '@salesforce/schema/Account.Total_Order_Value__c';
// import RECENT_PAYMENT_BEHAVIOUR from '@salesforce/schema/Account.Recent_Payment_Behaviour__c';
import CREDIT_REFORM_RATING from '@salesforce/schema/Account.Credit_Reform_Rating__c';
// import REVENUE_CATEGORY from '@salesforce/schema/Account.Revenue_Category__c';
import AMOUNT_AR_PAST_DUE from '@salesforce/schema/Account.celsrm__Total_Past_Due__c';
// import DRAWS_DISCOUNT from '@salesforce/schema/Account.Draws_Discount__c';
import FREQUENT_PAYMENT_TERM from '@salesforce/schema/Account.Frequent_Payment_Term__c';
import CURRENCY_ISO_CODE from '@salesforce/schema/Account.CurrencyIsoCode';


// import getDefaultContactRecord from '@salesforce/apex/ContactController.getDefaultContactRecord';
// import BILLING_LATITUDE from '@salesforce/schema/Account.BillingLatitude';
// import BILLING_LONGITUDE from '@salesforce/schema/Account.BillingLongitude';
import TIMEZONE from '@salesforce/i18n/timeZone';
import LOCALE from '@salesforce/i18n/locale';

import CURRENT from '@salesforce/schema/Account.celsrm__Age0__c';
import FIELD_1_30 from '@salesforce/schema/Account.celsrm__Age1__c';
import FIELD_31_60 from '@salesforce/schema/Account.celsrm__Age2__c';
import FIELD_61_90 from '@salesforce/schema/Account.celsrm__Age3__c';
import FIELD_91_180 from '@salesforce/schema/Account.celsrm__Age4__c';
import FIELD_OVER_180 from '@salesforce/schema/Account.celsrm__Age5__c';
import LAST_CONTACT_DATE from '@salesforce/schema/Account.celsrm__Last_Contact_Date__c';
import LAST_CONTACT_METHOD from '@salesforce/schema/Account.celsrm__Last_Contact_Method__c';
// import ACCOUNT_OWNER from '@salesforce/schema/Account.Owner.Name';
import OWNER_ID from '@salesforce/schema/Account.OwnerId';
// import BRAND_LOGO from '@salesforce/schema/Account.Brand_Logo__c';

import CREDIT_UTILIZATION from '@salesforce/schema/Account.Credit_Utilization__c';
// import NO_OF_DISPUTE from '@salesforce/schema/Account.No_of_Disputes__c';
// import AVG_RISK_PROMISE from '@salesforce/schema/Account.celsrm__Average_Risk_Promise__c';
// import NO_OF_PROMISE from '@salesforce/schema/Account.No_of_Promises__c';
// import RISK_PERCENTAGE from '@salesforce/schema/Account.celsrm__Risk__c';
// import AVG_RISK_PRMOISE from '@salesforce/schema/Account.celsrm__Average_Risk_Promise__c';
// import AVG_RISK_DISPUTE from '@salesforce/schema/Account.celsrm__Average_Risk_Dispute__c';
//import CURRENCY_ISO_CODE from '@salesforce/schema/Account.CurrencyIsoCode';
import CREDIT_LIMIT from '@salesforce/schema/Account.celsrm__Credit_Limit__c';
import LAST_CREDIT_REVIEW_DATE from '@salesforce/schema/Account.celsrm__Last_Credit_Review_Date__c';
import LAST_CREDIT_REVIEW_STATUS from '@salesforce/schema/Account.Latest_Credit_Review_Status__c';
// import PAYMENT_TERMS from '@salesforce/schema/Account.celsrm__Payment_Terms__c';
// import COLLECTION_SPECIALIST from '@salesforce/schema/Account.Collection_Specialist__c';

import PERCENT_DISPUTE from '@salesforce/schema/Account.celsrm__Percent_Disputed__c';
import fetchStickyNotes from '@salesforce/apex/WCM_FetchAccountDetails.fetchStickyNotes';
import saveStickyNotes from '@salesforce/apex/WCM_FetchAccountDetails.saveStickyNotes';
import saveStickyNotesColor from '@salesforce/apex/WCM_FetchAccountDetails.saveStickyNotesColor';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import chartJs from '@salesforce/resourceUrl/Chartjs';
// import d3Resource from '@salesforce/resourceUrl/D3'
// import fetchAverageDisputeRisk from '@salesforce/apex/WCM_FetchAccountDetails.fetchAverageDisputeRisk';
// import fetchCurrencyISOCode from '@salesforce/apex/WCM_FetchAccountDetails.fetchCurrencyISOCode';
import callToCustomer from '@salesforce/apex/OutgoingCallHandler.callToCustomer';
import checkChangeStatus from '@salesforce/apex/OutgoingCallHandler.checkChangeStatus';

import Risk_Score from '@salesforce/label/c.SRM_AD_Risk_Score';
import Credit_Utilization from '@salesforce/label/c.SRM_AD_Credit_Utilization';
import Credit_And_Collection_Details from '@salesforce/label/c.SRM_AD_Credit_And_Collection_Details';
import Open_Billing_Value from '@salesforce/label/c.SRM_AD_Open_Billing_Value';
import Open_Delivery_Value from '@salesforce/label/c.SRM_AD_Open_Delivery_Value';
import Historic_Data_Analysis from '@salesforce/label/c.SRM_AD_Historic_Data_Analysis';
import Credit_Reform_Rating from '@salesforce/label/c.SRM_AD_Credit_Reform_Rating';
import Amount_AR_Past_Due from '@salesforce/label/c.SRM_AD_Amount_AR_Past_Due';
import Frequent_Payment_Term from '@salesforce/label/c.SRM_AD_Frequent_Payment_Term';
import Communication_Details from '@salesforce/label/c.SRM_AD_Communication_Details';
import Latest_Credit_Review from '@salesforce/label/c.SRM_AD_Latest_Credit_Review';
import Last_Credit_Review_Date from '@salesforce/label/c.SRM_AD_Last_Credit_Review_Date';
import Contact_Details from '@salesforce/label/c.SRM_AD_Contact_Details';
import Header_Note from '@salesforce/label/c.SRM_AD_Header_Note';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const fields = [
    // BUSINESS_UNIT,
    ACCOUNT_NUMBER_FIELD,
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
    // ACCOUNT_OWNER,
    BILLING_STREET,
    BILLING_CITY,
    BILLING_STATE,
    BILLING_POSTAL_CODE,
    BILLING_COUNTRY,
    NOTE_FIELD,
    OWNER_ID,
    // TOTAL_OPEN_TRANSACTION,
    PERCENT_DISPUTE,
    // NO_OF_DISPUTE,
    // AVG_RISK_PROMISE,
    // NO_OF_PROMISE,
    // RISK_PERCENTAGE,
    // AVG_RISK_PRMOISE,
    // AVG_RISK_DISPUTE,
    CREDIT_LIMIT,
    // PAYMENT_TERMS,
    // BRAND_LOGO,
    CREDIT_UTILIZATION,
    SYSTEM_CREDIT_LIMIT,
    LAST_CREDIT_REVIEW_DATE,
    LAST_CREDIT_REVIEW_STATUS,
    RISK_SCORE,
    // SHORT_TERM_UTILIZATION,
    LATEST_CREDIT_REVIEW,
    LATEST_CREDIT_REVIEW_NUMBER,
    OPEN_BILLING_VALUE,
    OPEN_DELIVERY_VALUE,
    TOTAL_ORDER_VALUE,
    // RECENT_PAYMENT_BEHAVIOUR,
    CREDIT_REFORM_RATING,
    // REVENUE_CATEGORY,
    AMOUNT_AR_PAST_DUE,
    // DRAWS_DISCOUNT,
    FREQUENT_PAYMENT_TERM,
    // COLLECTION_SPECIALIST,
    CURRENCY_ISO_CODE
];
//CURRENCY_ISO_CODE,
export default class AkzoAccountDetailCredit extends NavigationMixin(LightningElement) {
    @api recordId;
    @wire(getRecord, { recordId: '$recordId', fields })
    acc;
    @wire(CurrentPageReference) pageRef;
    @track stickyNotes = '';
    @track isEditable = false;
    @track spanBackground = '';
    @track defCon;
    @track currentcnt;
    @track age1cnt;
    @track age2cnt;
    @track age3cnt;
    @track age4cnt;
    @track age5cnt;
    // @track defContact;
    @track len;
    @track parentAccount;
    @track isChartJSLoaded;
    @track isD3Loaded;
    @track isChartAlreadyLoaded;
    @track isD3AlreadyLoaded;
    @track disputeRisk = 0;
    @track accountDetailDivSize = 2;
    @track headNoteDivSize = 3;
    @track accountRiskDivSize = 12;
    @track showAccountDetails = false;
    @track accountRiskColorClass = 'between0_30';
    @track avgTXRiskColorClass = 'between0_30';
    @track avgDisputeRiskColorClass = 'between0_30';
    @track riskPercent;
    @track invoiceRiskPer = 0;
    @track disputeRiskPer = 0;
    @track headerNoteContentWidth = 'width:auto;';
    @track isHighlightPanel = true;
    @track currencyISOCode = 'USD';
    @track totalARShortForm;
    @track totalPassDueShortForm;
    @track currentShortForm;
    @track filed1_30ShortForm;
    @track filed31_60ShortForm;
    @track filed61_90ShortForm;
    @track filed91_180ShortForm;
    @track filedOver_180ShortForm;

    @track avgTransactionRisk = 0;
    @track avgDisputeRisk = 0;
    // @track currencyISOCode;
    @track checkStickyPopup;
    @track isOpenContact = false;
    @track showCallButton = false;
    @track CustomerCommunicationId;
    @track bucketRecCnt;
    @track TreatmentTask;
    @track drivingTransactionTotalBalance;
    @track drivingTransactionTotalCount = 0;
    @track treatmentStage;
    @track totalDTShortForm;
    @track stepNameList = undefined;
    @track latestTreatmentSegment = '';
    @track totalActivityOfLastMonth = {};
    @track treatmentSegment;
    @track parentIndicatorValue = '';

    label = {
        Risk_Score,
        Credit_Utilization,
        Credit_And_Collection_Details,
        Open_Billing_Value,
        Open_Delivery_Value,
        Historic_Data_Analysis,
        Credit_Reform_Rating,
        Amount_AR_Past_Due,
        Frequent_Payment_Term,
        Communication_Details,
        Latest_Credit_Review,
        Last_Credit_Review_Date,
        Contact_Details,
        Header_Note
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
                //finalValue = temp.substring(0, temp.indexOf('.') + 3);
            }
            else if (String(temp).substring(0, String(temp).indexOf('.')).length >= 4) {
                temp = String(temp / 1000);
                finalValue = temp.substring(0, temp.indexOf('.') + 3) + 'k';
                //finalValue = temp.substring(0, temp.indexOf('.'));
            }
            else if (String(temp).substring(0, String(temp).indexOf('.')).length <= 3) {
                finalValue = String(temp);
            }
            finalValue = getFieldValue(this.acc.data, CURRENCY_ISO_CODE) + ' ' + finalValue;
            // finalValue = (getFieldValue(this.acc.data, CURRENCY_ISO_CODE) != null && getFieldValue(this.acc.data, CURRENCY_ISO_CODE) != '' ? getFieldValue(this.acc.data, CURRENCY_ISO_CODE) + ' ' : '') +  finalValue;
        }
        else {

            if (String(temp).length >= 10) {
                temp = String(temp / 1000000000);
                finalValue = (temp.indexOf('.') > 0 ? temp.substring(0, temp.indexOf('.') + 3) + 'B' : temp + 'B');
                //finalValue = (temp.indexOf('.') > 0 ? temp.substring(0, temp.indexOf('.') + 3): temp);
            }
            else if (String(temp).length >= 7) {
                temp = String(temp / 1000000);
                finalValue = (temp.indexOf('.') > 0 ? temp.substring(0, temp.indexOf('.') + 3) + 'M' : temp + 'M');
                //finalValue = (temp.indexOf('.') > 0 ? temp.substring(0, temp.indexOf('.') + 3) : temp);
            }
            else if (String(temp).length >= 4) {
                temp = String(temp / 1000);
                finalValue = (temp.indexOf('.') > 0 ? temp.substring(0, temp.indexOf('.') + 3) + 'k' : temp + 'k');
                //finalValue = (temp.indexOf('.') > 0 ? temp.substring(0, temp.indexOf('.')) : temp);
            }
            else if (String(temp).substring(0, String(temp).indexOf('.')).length <= 3) {
                finalValue = String(temp);
            }
            finalValue = getFieldValue(this.acc.data, CURRENCY_ISO_CODE) + ' ' + finalValue;
        }
        return finalValue;
    }
    connectedCallback() {
        //this.len = getTotalOpenTask({ recordId: this.recordId });
        registerListener('updateLatestNote', this.updateLatestNote, this);
        this.isChartJSLoaded = false;
        this.isD3Loaded = false;
        this.isChartAlreadyLoaded = false;
        this.isD3AlreadyLoaded = false;
        Promise.all([
            loadScript(this, chartJs)
        ]).then(() => {
            this.isChartJSLoaded = true;
        });
        // Promise.all([
        //     loadScript(this, d3Resource)
        // ]).then(() => {
        //     this.isD3Loaded = true;
        // });
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
        // getParentAccountRecord({ recordId: this.recordId })
        // .then(result => {
        //     if (result) {
        //         //console.log('gettting contact @@@ : ' + JSON.stringify(result));
        //         this.parentAccount = result.Parent;
        //     }
        // })
        // .catch(error => {
        //     this.error = error;
        //     this.parentAccount = undefined;
        // });
        // getDefaultContactRecord({ recordId: this.recordId })
        // .then(result => {
        //     if (result) {
        //         //console.log('gettting contact @@@ : ' + JSON.stringify(result));
        //         this.defContact = result;
        //     }
        // })
        // .catch(error => {
        //     this.error = error;
        //     this.defContact = undefined;
        // });
        // getLatestTreatmentTask({ recordId: this.recordId })
        //     .then(result => {
        //         if (result) {
        //             let task = result.task;
        //             this.TreatmentTask = task;
        //             this.TreatmentTask.url = '/' + this.TreatmentTask.Id;
        //             this.drivingTransactionTotalBalance = result.totalBalace;
        //             // this.drivingTransactionTotalCount = result.totalcount;
        //             this.treatmentStage = result.treatmentStage;
        //             this.stepNameList = result.stepNameList;
        //             this.latestTreatmentSegment = result.treatmentSegment;
        //             // if (stepNameList !== undefined) {
        //             //     this.treatmentStageHelp = '<table> <tr> '
        //             //     for(let step of stepNameList){
        //             //         if (step === this.treatmentStage) {
        //             //             this.treatmentStageHelp += '<td style="border: 2px dashed red">step</td>';
        //             //         } else {
        //             //             this.treatmentStageHelp += '<td style="border: 1px solid #dddddd;">step</td>';
        //             //         }
        //             //     }
        //             //     this.treatmentStageHelp = '</tr></table> '
        //             // }

        //         }

        //         // this.TreatmentTask = {};
        //         // this.TreatmentTask.subject = '<a href="' + '/'+ result1.Id + '"' + ' target="_blank">' +  result1.Subject + '</a>'
        //     })
        //     .catch(error => {
        //         this.error = error;
        //         this.TreatmentTask = undefined;
        //     });
        // getTotalOpenTask({ recordId: this.recordId })
        //     .then(result => {
        //         // if (result > 0) {
        //         //console.log('gettting Task @@@ : ' + JSON.stringify(result));
        //         this.len = result.length;
        //         //} 
        //     })
        //     .catch(error => {
        //         this.error = error;
        //         this.len = undefined;
        //     });
        // getTotalLastMonthActivity({ recordId: this.recordId })
        //     .then(result => {
        //         // if (result > 0) {l
        //         //console.log('gettting Task @@@ : ' + JSON.stringify(result));
        //         this.totalActivityOfLastMonth = result;
        //         //} 
        //     })
        //     .catch(error => {
        //         this.error = error;
        //         this.totalTaskOfLastMonth = {};
        //     });
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
            }
        }).catch(error => {
            console.log('error>>>' + error);
        });

        getChildAccounts({ recordId: this.recordId })
            .then(result => {
                if (result && result.length > 0) {
                    this.parentIndicatorValue = 'Yes';
                } else {
                    this.parentIndicatorValue = 'No';
                }
            })
            .catch(error => {
                this.error = error;
                this.defCon = undefined;
            });
        // this.currentcnt = this.bucketRange(0,-23243432432);
        // this.age1cnt = this.bucketRange(1,30);
        // this.age2cnt = this.bucketRange(31,60);
        // this.age3cnt = this.bucketRange(61,90);
        // this.age4cnt = this.bucketRange(91,180);
        // this.age5cnt = this.bucketRange(180,283888388383);


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

    // get region() {
    //     return getFieldValue(this.acc.data, REGION);
    // }
    get treatmentStageHelp() {

        // if (this.template.querySelector('.tooltiptext') !== null) {
        //     if (this.stepNameList !== undefined) {
        //         let table = document.createElement('table');
        //         let tr = document.createElement('tr');
        //         // help = '<table> <tr> '
        //         for (let step of this.stepNameList) {
        //             let help = '';
        //             if (step.stepName === this.treatmentStage) {
        //                 let that = this;
        //                 let td = document.createElement('td');
        //                 // td.onclick = function() {that.changeTransactionData()};
        //                 td.style = "border: 2px dashed red;padding: 0.3rem;";
        //                 // if(step.stepName === 'Proactive Email' || step.stepName === 'Automated Proactive Email' || step.stepName === 'Polite Email' || step.stepName === 'Automated Light Email'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Green_Email.png" title="'+step.stepName+'" width="20" height="20">';
        //                 // } else if(step.stepName === 'Due Date: No Payment'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Due_Payment.png" title="'+step.stepName+'" width="20" height="20">';
        //                 // } else if(step.stepName === 'Person Based Polite Call'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Green_Phone.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Person Based Reminder Call'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Yellow_Phone.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Person Based Firm Call'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Red_Phone.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Escalation 1'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Blue_Edit.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Escalation 2'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Blue_Edit.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Escalation 3'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Blue_Edit.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Collections Hold Decision'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Hold.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Demand Letter Decision'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Yellow_Edit.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === '3rd Party Placement Decision'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Red_Edit.png" title="'+step.stepName+'" >';
        //                 // }  else if(step.stepName === 'Automated Firm Email/Firm Call'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Red_Email.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Reminder Email' || step.stepName === 'Automated Medium Email'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Yellow_Email.png" title="'+step.stepName+'" >';
        //                 // }
        //                 if (step.iconClass) {
        //                     help += '<span class="' + step.iconClass + '" style="font-size: 20px;vertical-align: middle;padding-right: 0.3rem;color: ' + step.iconColor + '"></span>';
        //                 }
        //                 help += step.stepName;
        //                 td.innerHTML = help;
        //                 tr.appendChild(td);
        //             } else {
        //                 let td = document.createElement('td');
        //                 // td.onclick = this.changeTransactionData();

        //                 td.style = "border: 1px solid #b0adab;padding: 0.3rem;";
        //                 // if(step.stepName    === 'Proactive Email' || step.stepName === 'Automated Proactive Email' || step.stepName === 'Polite Email' || step.stepName === 'Automated Light Email'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Green_Email.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Due Date: No Payment'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Due_Payment.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Person Based Polite Call'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Green_Phone.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Person Based Reminder Call'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Yellow_Phone.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Person Based Firm Call'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Red_Phone.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Escalation 1'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Blue_Edit.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Escalation 2'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Blue_Edit.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Escalation 3'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Blue_Edit.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Collections Hold Decision'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Hold.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Demand Letter Decision'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Yellow_Edit.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === '3rd Party Placement Decision'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Red_Edit.png" title="'+step.stepName+'" >';
        //                 // }  else if(step.stepName === 'Automated Firm Email/Firm Call'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Red_Email.png" title="'+step.stepName+'" >';
        //                 // } else if(step.stepName === 'Reminder Email' || step.stepName === 'Automated Medium Email'){
        //                 //     help += '<img src="/resource/Treatment_Step_Icon/Treatment_Step_Icon/Yellow_Email.png" title="'+step.stepName+'" >';
        //                 // }
        //                 if (step.iconClass) {
        //                     help += '<span class="' + step.iconClass + '" style="font-size: 20px;vertical-align: middle;padding-right: 0.3rem;color: ' + step.iconColor + '"></span>';
        //                 }
        //                 help += step.stepName;
        //                 td.innerHTML = help;
        //                 tr.appendChild(td);

        //             }
        //         }
        //         // help += '</tr></table> ';
        //         table.appendChild(tr);
        //         // this.template.querySelector('.tooltiptext').removeChild();
        //         if (this.template.querySelector('.treatmentStageHelp') != null) {
        //             this.template.querySelector('.tooltiptext').appendChild(table);
        //             this.template.querySelector('.treatmentStageHelp').remove();
        //         }

        //     }
        // }
        return '';
    }
    get CreditUtilization() {
        let credit = getFieldValue(this.acc.data, CREDIT_UTILIZATION);
        if (this.template.querySelector('.CreditUtilization') != null) {
            this.template.querySelector('.CreditUtilization').innerHTML = credit;
        }
        return credit;
    }
    
    get accountNumber() {
        return getFieldValue(this.acc.data, ACCOUNT_NUMBER_FIELD);
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
    get baseTotalAR() {
        var temp = getFieldValue(this.acc.data, BASE_TOTAL_AR);
        var valuetoReturn;
        valuetoReturn = this.converter(temp);
        return valuetoReturn;
    }
    get drivingTransactionTotal() {
        var temp = this.drivingTransactionTotalBalance;
        var valuetoReturn;
        valuetoReturn = this.converter(temp);
        // if(valuetoReturn != undefined && valuetoReturn != null){
        // 	if(valuetoReturn.indexOf('M') > 0){
        // 		valuetoReturn = valuetoReturn.substring(0,valuetoReturn.indexOf('M'));
        // 		this.totalDTShortForm = 'M';
        // 	}else if(valuetoReturn.indexOf('B') > 0){
        // 		valuetoReturn = valuetoReturn.substring(0,valuetoReturn.indexOf('B'));
        // 		this.totalDTShortForm = 'B';
        // 	}else if(valuetoReturn.indexOf('k') > 0){
        // 		valuetoReturn = valuetoReturn.substring(0,valuetoReturn.indexOf('k'));
        // 		this.totalDTShortForm = 'k';
        // 	}
        // }
        return valuetoReturn;
    }
    get totalPastDue() {
        var temp = getFieldValue(this.acc.data, TOTAL_PAST_DUE);
        var valuetoReturn = this.converter(temp);
        return valuetoReturn;
    }
    get openBillingValue() {
        var temp = getFieldValue(this.acc.data, OPEN_BILLING_VALUE);
        var valuetoReturn = this.converter(temp);
        return valuetoReturn;
    }
    get openDeliveryValue() {
        var temp = getFieldValue(this.acc.data, OPEN_DELIVERY_VALUE);
        var valuetoReturn = this.converter(temp);
        return valuetoReturn;
    }
    get TotalOrderValue() {
        var temp = getFieldValue(this.acc.data, TOTAL_ORDER_VALUE);
        var valuetoReturn = this.converter(temp);
        return valuetoReturn;
    }

    // get revenueCategory() {
    //     return getFieldValue(this.acc.data, REVENUE_CATEGORY);
    // }
    get creditReformRating() {
        var temp = getFieldValue(this.acc.data, CREDIT_REFORM_RATING);
        return temp ? temp + '%' : 'No Data';
    }
    // get recentPaymentBehaviour() {
    //     return getFieldValue(this.acc.data, RECENT_PAYMENT_BEHAVIOUR);
    // }
    // get drawsDiscount() {
    //     return getFieldValue(this.acc.data, DRAWS_DISCOUNT);
    // }
    get amountARPastDue() {
        var temp = getFieldValue(this.acc.data, AMOUNT_AR_PAST_DUE);
        var valuetoReturn = this.converter(temp);
        return valuetoReturn;
    }
    get frequentPaymentTerm() {
        return getFieldValue(this.acc.data, FREQUENT_PAYMENT_TERM);
    }
    // get brandLogo() {
    //     return getFieldValue(this.acc.data, BRAND_LOGO);
    // }

    get note() {
        return getFieldValue(this.acc.data, NOTE_FIELD);
    }

    get percentageDispute() {
        return getFieldValue(this.acc.data, PERCENT_DISPUTE);
    }

    // get numberOfDispute() {
    //     return getFieldValue(this.acc.data, NO_OF_DISPUTE);
    // }
    // get BUSINESSUNIT() {
    //     return getFieldValue(this.acc.data, BUSINESS_UNIT);
    // }
    get averageRiskPromise() {
        return getFieldValue(this.acc.data, AVG_RISK_PROMISE);
    }

    // get numberOfpromise() {
    //     return getFieldValue(this.acc.data, NO_OF_PROMISE);
    // }
    get CreditLimit() {
        var temp = getFieldValue(this.acc.data, CREDIT_LIMIT);
        var valuetoReturn = this.converter(temp);
        return valuetoReturn;
    }
    get systemCreditLimit() {
        var temp = getFieldValue(this.acc.data, SYSTEM_CREDIT_LIMIT);
        var valuetoReturn = this.converter(temp);
        return valuetoReturn;

    }
    get lastCreditReviewDate() {
        let value = getFieldValue(this.acc.data, LAST_CREDIT_REVIEW_DATE);
        let d;
        if (value) {
            d = new Date(value);
            return d.toLocaleString(LOCALE, {
                // "timeZone" : TIMEZONE, 
                "dateStyle": "short",
                // "timeStyle" : "short"
            });
        } else {
            return "";
        }
    }
    get latestCreditReview() {
        var Id = getFieldValue(this.acc.data, LATEST_CREDIT_REVIEW);
        var reviewNumber = getFieldValue(this.acc.data, LATEST_CREDIT_REVIEW_NUMBER);
        if (this.template.querySelector('.latestCreditReview') && Id && reviewNumber) {
            this.template.querySelector('.latestCreditReview').innerHTML = '<a href="' + '/' + Id + '"' + ' target="_blank">' + reviewNumber + '</a>';
        }
        return '';

    }
    get riskPercentage() {
        var temp = getFieldValue(this.acc.data, RISK_SCORE);

        var percentRiskStr = (temp !== undefined && temp !== null ? parseFloat(temp).toFixed(2) : 0);

        var percentRiskInt = parseInt(percentRiskStr);

        if (percentRiskInt > 50) {
            this.accountRiskColorClass = 'over50';
        } else if (percentRiskInt > 30 && percentRiskInt <= 50) {
            this.accountRiskColorClass = 'between30_50';
        } else {
            this.accountRiskColorClass = 'between0_30';
        }

        this.riskPercent = percentRiskStr != null && percentRiskStr > 0 ? percentRiskStr : 0;
    }
    // get shortTermUtilization() {
    //     return getFieldValue(this.acc.data, SHORT_TERM_UTILIZATION);
    // }

    get current() {
        var temp = getFieldValue(this.acc.data, CURRENT);
        return (temp === undefined || temp === null || temp === '') ? 0 : temp;
        //return this.converter(temp) !== null ? (this.converter(temp) + (this.bucketRecCnt !== undefined && this.bucketRecCnt.hasOwnProperty('Current') ? ' (' + this.bucketRecCnt['Current']+ ')' : '')) : '';
        //return this.converter(temp) !== null ? (this.converter(temp) + (this.bucketRecCnt !== undefined && this.bucketRecCnt.hasOwnProperty('Current') ? ' (' + this.bucketRecCnt['Current']+ ')' : '')) : '';
        // this.bucketRange(0,-2225235855);
        // var valuetoReturn = this.converter(temp);     
        // return valuetoReturn + ' (' + this.currentcnt + ')';
    }

    get current_Formated() {
        var temp = getFieldValue(this.acc.data, CURRENT);

        return this.converter(temp) != null ? (this.converter(temp)) : '';
        //return this.converter(temp) != null ? (this.converter(temp) + (this.bucketRecCnt !== undefined && this.bucketRecCnt.hasOwnProperty('Current') ? ' (' + this.bucketRecCnt['Current']+ ')' : '')) : '';
        // this.bucketRange(0,-2225235855);
        // var valuetoReturn = this.converter(temp);     
        // return valuetoReturn + ' (' + this.currentcnt + ')';
    }

    get filed1_30() {
        var temp = getFieldValue(this.acc.data, FIELD_1_30);
        return (temp === undefined || temp === null || temp === '') ? 0 : temp;
        //return this.converter(temp) !== null ? (this.converter(temp) + (this.bucketRecCnt !== undefined && this.bucketRecCnt.hasOwnProperty('130') ? ' (' + this.bucketRecCnt['130']+ ')' : '')) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('130') ? ' (' + this.bucketRecCnt['130'] + ')' : '');
        // this.bucketRange(1,30);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get filed1_30_Formated() {
        var temp = getFieldValue(this.acc.data, FIELD_1_30);
        return this.converter(temp) != null ? (this.converter(temp)) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('130') ? ' (' + this.bucketRecCnt['130'] + ')' : '');
        // this.bucketRange(1,30);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get filed31_60() {
        var temp = getFieldValue(this.acc.data, FIELD_31_60);
        return (temp === undefined || temp === null || temp === '') ? 0 : temp;
        //return this.converter(temp) !== null ? (this.converter(temp) + (this.bucketRecCnt !== undefined && this.bucketRecCnt.hasOwnProperty('3160') ? ' (' + this.bucketRecCnt['3160']+ ')' : '')) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('3160') ? ' (' + this.bucketRecCnt['3160'] + ')' : '');
        // this.bucketRange(31,60);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get filed31_60_Formated() {
        var temp = getFieldValue(this.acc.data, FIELD_31_60);
        return this.converter(temp) != null ? (this.converter(temp)) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('3160') ? ' (' + this.bucketRecCnt['3160'] + ')' : '');
        // this.bucketRange(31,60);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get filed61_90() {
        var temp = getFieldValue(this.acc.data, FIELD_61_90);
        return (temp === undefined || temp === null || temp === '') ? 0 : temp;
        //return this.converter(temp) !== null ? (this.converter(temp) + (this.bucketRecCnt !== undefined && this.bucketRecCnt.hasOwnProperty('6190') ? ' (' + this.bucketRecCnt['6190']+ ')' : '')) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('6190') ? ' (' + this.bucketRecCnt['6190'] + ')' : '');
        // this.bucketRange(61,90);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get filed61_90_Formated() {
        var temp = getFieldValue(this.acc.data, FIELD_61_90);
        return this.converter(temp) != null ? (this.converter(temp)) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('6190') ? ' (' + this.bucketRecCnt['6190'] + ')' : '');
        // this.bucketRange(61,90);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get filed91_180() {
        var temp = getFieldValue(this.acc.data, FIELD_91_180);
        return (temp === undefined || temp === null || temp === '') ? 0 : temp;
        //return this.converter(temp) !== null ? (this.converter(temp) + (this.bucketRecCnt !== undefined && this.bucketRecCnt.hasOwnProperty('91180') ? ' (' + this.bucketRecCnt['91180']+ ')' : '')) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('91180') ? ' (' + this.bucketRecCnt['91180'] + ')' : '');
        // this.bucketRange(91,180);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get filed91_180_Formated() {
        var temp = getFieldValue(this.acc.data, FIELD_91_180);
        return this.converter(temp) != null ? (this.converter(temp)) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('91180') ? ' (' + this.bucketRecCnt['91180'] + ')' : '');
        // this.bucketRange(91,180);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get filedOver_180() {
        // return getFieldValue(this.acc.data, FIELD_OVER_180);
        var temp = getFieldValue(this.acc.data, FIELD_OVER_180);
        return (temp === undefined || temp === null || temp === '') ? 0 : temp;
        //return this.converter(temp) !== null ? (this.converter(temp) + (this.bucketRecCnt !== undefined && this.bucketRecCnt.hasOwnProperty('Over180') ? ' (' + this.bucketRecCnt['Over180']+ ')' : '')) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('Over180') ? ' (' + this.bucketRecCnt['Over180'] + ')' : '');
        // this.bucketRange(180,1512456115);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get filedOver_180_Formated() {
        // return getFieldValue(this.acc.data, FIELD_OVER_180);
        var temp = getFieldValue(this.acc.data, FIELD_OVER_180);
        return this.converter(temp) != null ? (this.converter(temp)) : '';
        // return this.converter(temp) + (this.bucketRecCnt !== undefined  && this.bucketRecCnt.hasOwnProperty('Over180') ? ' (' + this.bucketRecCnt['Over180'] + ')' : '');
        // this.bucketRange(180,1512456115);
        // var valuetoReturn = this.converter(temp);
        // return valuetoReturn  + ' (' + this.currentcnt + ')';
    }

    get lastContactDate() {
        let value = getFieldValue(this.acc.data, LAST_CONTACT_DATE);
        let d;
        if (value) {
            d = new Date(value);
            return d.toLocaleString(LOCALE, {
                // "timeZone" : TIMEZONE, 
                "dateStyle": "short",
                // "timeStyle" : "short"
            });
        } else {
            return "";
        }

    }
    get lastContactMethod() {
        return getFieldValue(this.acc.data, LAST_CONTACT_METHOD);
    }

    // get AccountOwner() {
    //     return getFieldValue(this.acc.data, ACCOUNT_OWNER);
    // }

    // get totalOpenInvoiceCount() {
    //     return getFieldValue(this.acc.data, TOTAL_OPEN_TRANSACTION);
    // }
    // get CollectionSpecialist() {
    //     return getFieldValue(this.acc.data, COLLECTION_SPECIALIST);
    // }

    get latestcreditreviewstatus() {
         return getFieldValue(this.acc.data, LAST_CREDIT_REVIEW_STATUS);
    }
    
    viewContactDetails() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.defCon.Id,
                objectApiName: 'Contact',
                actionName: 'view'
            }
        });
    }

    viewUserDetails() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: getFieldValue(this.acc.data, OWNER_ID),
                objectApiName: 'User',
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

    showAccountDetail() {
        this.showAccountDetails = true;
        this.accountDetailDivSize = 3;
        this.headNoteDivSize = 2;
        this.accountRiskDivSize = 6;
    }

    hideAccountDetail() {
        this.showAccountDetails = false;
        this.accountDetailDivSize = 2;
        this.headNoteDivSize = 3;
        this.accountRiskDivSize = 12;
    }

    showHighlightPanel() {
        this.isHighlightPanel = true;
        var that = this;
        setTimeout(function () {
            that.isChartAlreadyLoaded = false;
            that.isD3AlreadyLoaded = false;
        });
    }

    hideHighlightPanel() {
        this.isHighlightPanel = false;
    }

    checkIsEditableFalse() {
        this.isEditable = false;
    }
    openStickyPopup() {
        document.body.style.overflow = "hidden";
        this.tempStickyNotes = JSON.parse(JSON.stringify(this.stickyNotes));
        this.checkStickyPopup = true;
    }
    closeStickyPopup() {
        document.body.style.overflow = "auto";
        this.checkStickyPopup = false;
    }
    updateStickyNotes(event) {
        let updateNotes = event.target.value;
        this.tempStickyNotes = updateNotes;

        if (updateNotes && updateNotes !== "") {
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
        val.contactNo = this.defCon[event.target.dataset.name].replace("(", "").replace(")", "").replace(/\s/g, '').replace("-", "");
        val.account = this.recordId;
        val.calledTo = this.defCon.Id;
        val.screenName = 'Contact Customer';
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
        if (this.isD3Loaded && !this.isD3AlreadyLoaded) {
            const data = [
                { label: 'Information', range: [0, 75] },
                { label: 'Part A', range: [0, 50] },
                { label: 'Subpart 1', range: [0, 10] },
                { label: 'Subpart 2', range: [11, 50] },
                { label: 'Subpart 3', range: [50, 57] },
                { label: 'Subpart 4', range: [57, 65] },
                { label: 'Subpart 5', range: [65, 75] }
            ];
        
            // Set up chart dimensions
            const width = 500;
            const height = 300;
            const margin = { top: 20, right: 20, bottom: 30, left: 60 };
        
            const svg = d3.select(this.template.querySelector('.chart'))
                .attr('width', width + margin.left + margin.right)
                .attr('height', height + margin.top + margin.bottom)
                .append('g')
                .attr('transform', `translate(${margin.left},${margin.top})`);


            const xScale = d3.scaleLinear()
                .domain([0, d3.max(data, d => d.range[1])])
                .range([0, width]);

            const yScale = d3.scaleBand()
                .domain(data.map(d => d.label))
                .range([0, height])
                .padding(0.1);
            // Add x axis
            svg.append('g')
            .attr('transform', `translate(0, ${height})`)
            .call(d3.axisBottom(xScale));

            // Add y axis
            svg.append('g')
            .call(d3.axisLeft(yScale));

            svg.selectAll('rect')
                .data(data)
                .enter()
                .append('rect')
                .attr('x', d => xScale(d.range[0]))
                .attr('y', d => yScale(d.label))
                .attr('width', d => xScale(d.range[1]) - xScale(d.range[0]))
                .attr('height', yScale.bandwidth())
                .attr('fill', 'steelblue');
            
            svg.selectAll('text')
                .data(data)
                .enter()
                .append('text')
                .attr('x', d => xScale((d.range[0] + d.range[1]) / 2))
                .attr('y', d => yScale(d.label) + yScale.bandwidth() / 2)
                .attr('text-anchor', 'middle')
                .attr('alignment-baseline', 'middle')
                .text(d => `${d.range[0]} - ${d.range[1]}`);
            
            // Add upper and lower boundary lines
            svg.append('line')
                .attr('x1', xScale(50))
                .attr('y1', 0)
                .attr('x2', xScale(50))
                .attr('y2', height)
                .attr('stroke', 'red')
                .attr('stroke-dasharray', '5');
            
            svg.append('line')
                .attr('x1', xScale(75))
                .attr('y1', 0)
                .attr('x2', xScale(75))
                .attr('y2', height)
                .attr('stroke', 'green')
                .attr('stroke-dasharray', '5');
            this.isD3AlreadyLoaded = true;
        }
        // if (this.isChartJSLoaded && !this.isChartAlreadyLoaded) {
        //     var dataVal = [];
        //     dataVal.push((this.current !== undefined && this.current !== null && this.current !== '' ? this.current : 0));
        //     dataVal.push((this.filed1_30 !== undefined && this.filed1_30 !== null && this.filed1_30 !== '' ? this.filed1_30 : 0));
        //     dataVal.push((this.filed31_60 !== undefined && this.filed31_60 !== null && this.filed31_60 !== '' ? this.filed31_60 : 0));
        //     dataVal.push((this.filed61_90 !== undefined && this.filed61_90 !== null && this.filed61_90 !== '' ? this.filed61_90 : 0));
        //     dataVal.push((this.filed91_180 !== undefined && this.filed91_180 !== null && this.filed91_180 !== '' ? this.filed91_180 : 0));
        //     dataVal.push((this.filedOver_180 !== undefined && this.filedOver_180 !== null && this.filedOver_180 !== '' ? this.filedOver_180 : 0));
        //     // inputBox.focus();
        //     var that = this;
        //     var ctx = this.template.querySelector('.pieChartContainer');
        //     ctx.height = 130;
        //     ctx.width = 290;
        //     new Chart(ctx, {
        //         type: 'bar',
        //         data: {
        //             labels: ["Current", "1-30", "31-60", "61-90", "91-180", "Over 180"],
        //             datasets: [{
        //                 label: "value",
        //                 backgroundColor: ["#00a1e0", "#16325c", "#76ded9", "#08a69e", "#e2ce7d", "#e49f01"],
        //                 data: dataVal
        //             }]
        //         },
        //         options: {
        //             legend: { display: false },
        //             title: {
        //                 display: false,
        //                 text: 'Aging'
        //             },
        //             responsive: false,
        //             maintainAspectRatio: false,
        //             events: ['mousemove', 'mouseout', 'touchstart', 'touchmove'],
        //             tooltips: {
        //                 enabled: true,
        //                 callbacks: {
        //                     label: function (tooltipItem, data) {
        //                         return data.labels[tooltipItem['index']] + ':' + that.converter(data['datasets'][0]['data'][tooltipItem['index']]);
        //                     }
        //                 }

        //             },
        //             animation: {
        //                 onComplete: function (animation) {
        //                     var isAllBlank = true;
        //                     dataVal.forEach(function (v, i) {
        //                         if (v != null && v > 0) {
        //                             isAllBlank = false;
        //                         }
        //                     });
        //                     if (!isAllBlank) {
        //                         that.isChartAlreadyLoaded = true;
        //                     }
        //                 }
        //             }
        //         }
        //     });
        // }
    }


    viewParentAccountDetails() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.parentAccount.Id,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }
    treatmentStageFocus() {
        this.template.querySelector('.tooltip-main').classList.remove("tooltip");
    }
    treatmentStageFocusOut() {
        this.template.querySelector('.tooltip-main').classList.add("tooltip");
    }
}