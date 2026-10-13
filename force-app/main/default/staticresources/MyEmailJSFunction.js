//--- DO NOT CHANGE CODE | START ---//
(function (global, factory) {
   typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
      typeof define === 'function' && define.amd ? define(['exports'], factory) :
         (factory((global.gog = global.gog || {})));
}(this, (function (exports) {
   'use strict';

   var version = "1.0.0";
   //--- DO NOT CHANGE CODE | END ---//
   function validateCustomAction(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
      debugger;
      return new Promise(function (resolve, reject) {
         var screenName = values['ggScreenName'];
         if (!rowvals || !rowvals.RelatedToId) {
            gog.showToast('Warning', 'Please ensure that email is mapped before proceeding with the action.', 'Warning', 'dismissable', cmp, ShowToastEvent);
         } else {
            let screenParam = {
               screenName: 'Send Statement',
               screenSize: 'medium-width'
            }            
            fireEvent(cmp.pageRef, 'openChildScreenFromActivity_ActivityForMyEmailsTab_All Incoming Emails', screenParam);
         }
         resolve({});
      }).catch(error => {
         console.log('error :' + error);
         reject(error);
      });
   }
   function validateCustomActionOnMailbox(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
      debugger;
      return new Promise(function (resolve, reject) {
         var screenName = values['ggScreenName'];
         if (!rowvals || !rowvals.RelatedToId) {
            gog.showToast('Warning', 'Please ensure that email is mapped before proceeding with the action.', 'Warning', 'dismissable', cmp, ShowToastEvent);
         } else {
            let screenParam = {
               screenName: 'Send Statement',
               screenSize: 'medium-width'
            }            
            fireEvent(cmp.pageRef, 'openChildScreenFromMailbox_ActivityForMyEmailsTabMailbox_All_Incoming_Emails_of_Mailbox', screenParam);
         }
         resolve({});
      }).catch(error => {
         console.log('error :' + error);
         reject(error);
      });
   }
   function validateDisputeAction(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
      debugger;
      return new Promise(function (resolve, reject) {
         var screenName = values['ggScreenName'];
         if (!rowvals || !rowvals.RelatedToId) {
            gog.showToast('Warning', 'Please ensure that email is mapped before proceeding with the action.', 'Warning', 'dismissable', cmp, ShowToastEvent);
         } else {
            let screenParam = {
               screenName: 'Create Dispute',
               screenSize: 'medium-width'
            }            
            fireEvent(cmp.pageRef, 'openChildScreenFromActivity_ActivityForMyEmailsTab_All Incoming Emails', screenParam);
         }
         resolve({});
      }).catch(error => {
         console.log('error :' + error);
         reject(error);
      });
   }
   function validateDisputeActionOnMailbox(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
      debugger;
      return new Promise(function (resolve, reject) {
         var screenName = values['ggScreenName'];
         if (!rowvals || !rowvals.RelatedToId) {
            gog.showToast('Warning', 'Please ensure that email is mapped before proceeding with the action.', 'Warning', 'dismissable', cmp, ShowToastEvent);
         } else {
            let screenParam = {
               screenName: 'Create Dispute',
               screenSize: 'medium-width'
            }            
            fireEvent(cmp.pageRef, 'openChildScreenFromMailbox_ActivityForMyEmailsTabMailbox_All_Incoming_Emails_of_Mailbox', screenParam);
         }
         resolve({});
      }).catch(error => {
         console.log('error :' + error);
         reject(error);
      });
   }
   function validatePromiseAction(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
      debugger;
      return new Promise(function (resolve, reject) {
         var screenName = values['ggScreenName'];
         if (!rowvals || !rowvals.RelatedToId) {
            gog.showToast('Warning', 'Please ensure that email is mapped before proceeding with the action.', 'Warning', 'dismissable', cmp, ShowToastEvent);
         } else {
            let screenParam = {
               screenName: 'Promise To Pay',
               screenSize: 'medium-width'
            }            
            fireEvent(cmp.pageRef, 'openChildScreenFromActivity_ActivityForMyEmailsTab_All Incoming Emails', screenParam);
         }
         resolve({});
      }).catch(error => {
         console.log('error :' + error);
         reject(error);
      });
   }
   function validatePromiseActionOnMailbox(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
      debugger;
      return new Promise(function (resolve, reject) {
         var screenName = values['ggScreenName'];
         if (!rowvals || !rowvals.RelatedToId) {
            gog.showToast('Warning', 'Please ensure that email is mapped before proceeding with the action.', 'Warning', 'dismissable', cmp, ShowToastEvent);
         } else {
            let screenParam = {
               screenName: 'Promise To Pay',
               screenSize: 'medium-width'
            }            
            fireEvent(cmp.pageRef, 'openChildScreenFromMailbox_ActivityForMyEmailsTabMailbox_All_Incoming_Emails_of_Mailbox', screenParam);
         }
         resolve({});
      }).catch(error => {
         console.log('error :' + error);
         reject(error);
      });
   }

   // << START - MM - FIN-8439 - Mailbox filter on My Emails>>
   function changeMailbox(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
      debugger;
      return new Promise(function (resolve, reject) {
         fireEvent(cmp.pageRef, 'refreshActivity_ActivityForMyEmailsTabMailbox_All_Incoming_Emails_of_Mailbox', values);
         resolve({});
      }).catch(error => {
         console.log('error :' + error);
         reject(error);
      });
   }
   // << END - MM - FIN-8439 - Mailbox filter on My Emails>>

   // << START - MM - FIN-8439 - Mailbox filter on My Emails>>
   function loadMyEmails(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
      debugger;
      return new Promise(function (resolve, reject) {
         invoke({ 
            className: 'MyEmailsScreenController', 
            functionName: 'onLoadMyEmails',
            values: values 
         }).then(result1 => {
            var result = JSON.parse(JSON.stringify(result1));
            let resolveVal = {};
            resolveVal.MailboxPickList = result.MailboxPickList;
            values.MailboxPickList = result.MailboxPickList
            fireEvent(cmp.pageRef, 'refreshActivity_ActivityForMyEmailsTabMailbox_All_Incoming_Emails_of_Mailbox', values);
            resolve(resolveVal);
         }).catch(error => {
            console.log('error :' + error);
            //sessionStorage.removeItem(rNumber);
            reject(error);
         });
      }).catch(error => {
         console.log('error :' + error);
         reject(error);
      });
   }
   // << END - MM - FIN-8439 - Mailbox filter on My Emails>>

   function showToast(stTitle, stMessage, stVariant, stMode, stDispatchFunction, ShowToastEvent) {
      stDispatchFunction.dispatchEvent(new ShowToastEvent({
         title: stTitle,
         message: stMessage,
         variant: stVariant,
         mode: stMode
      })); ''
   };

   function openActionFromAgent(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
      debugger;
      return new Promise(function (resolve, reject) {
         if (!rowvals || !rowvals.actionName) {
            gog.showToast('Warning', 'Action is not defined', 'Warning', 'dismissable', cmp, ShowToastEvent);
         }
         //-- Starts | FIN-7319 | Changed by Ravi | 16-Jun-2026 --//
         if(rowvals.actionName == 'send_statement'){
            let screenParam = {
               screenName: 'Send Statement',
               screenSize: 'medium-width',
               value: {
                  'openFromSummaryAgent': true,
                  'summaryArguments': rowvals.arguments,
                  'summaryTaskId': rowvals.taskId,
                  'summaryActionName': rowvals.actionName,
                  'summaryAutoActionResultFileId': rowvals.resultFileId
               }
            }            
            fireEvent(cmp.pageRef, 'openChildScreenFromMailbox_ActivityForMyEmailsTabMailbox_All_Incoming_Emails_of_Mailbox', screenParam);
         } else if(rowvals.actionName == 'promise_to_pay'){
            let screenParam = {
               screenName: 'Promise To Pay',
               screenSize: 'medium-width',
               value: {
                  'openFromSummaryAgent': true,
                  'summaryArguments': rowvals.arguments,
                  'summaryTaskId': rowvals.taskId,
                  'summaryActionName': rowvals.actionName,
                  'summaryAutoActionResultFileId': rowvals.resultFileId
               }
            }            
            fireEvent(cmp.pageRef, 'openChildScreenFromMailbox_ActivityForMyEmailsTabMailbox_All_Incoming_Emails_of_Mailbox', screenParam);
         } else if(rowvals.actionName == 'raise_dispute'){
            let screenParam = {
               screenName: 'Create Dispute',
               screenSize: 'medium-width',
               value: {
                  'openFromSummaryAgent': true,
                  'summaryArguments': rowvals.arguments,
                  'summaryTaskId': rowvals.taskId,
                  'summaryActionName': rowvals.actionName,
                  'summaryAutoActionResultFileId': rowvals.resultFileId
               }
            }            
            fireEvent(cmp.pageRef, 'openChildScreenFromMailbox_ActivityForMyEmailsTabMailbox_All_Incoming_Emails_of_Mailbox', screenParam);
         }
         //-- End | FIN-7319 | Changed by Ravi | 16-Jun-2026 --//
         let message = {};
         message.repharseSummary = false;
         message.isUser = false;
         message.hasError = false;
         message.errorMessage = '';
         message.resultSummary = 'Executing action...';
         resolve(message);
      });
   }

   exports.validatePromiseAction = validatePromiseAction;
   exports.validateDisputeAction = validateDisputeAction;
   exports.showToast = showToast;
   exports.validateCustomAction = validateCustomAction;
   exports.validateDisputeActionOnMailbox = validateDisputeActionOnMailbox;
   exports.validatePromiseActionOnMailbox = validatePromiseActionOnMailbox;
   exports.validateCustomActionOnMailbox = validateCustomActionOnMailbox;
   exports.openActionFromAgent = openActionFromAgent;
   // << START - MM - FIN-8439 - Mailbox filter on My Emails>>
   exports.changeMailbox = changeMailbox;
   exports.loadMyEmails = loadMyEmails;
   // << END - MM - FIN-8439 - Mailbox filter on My Emails>>
   //--- DO NOT CHANGE CODE | START ---//
   Object.defineProperty(exports, '__esModule', {
      value: true
   });
   //--- DO NOT CHANGE CODE | END ---//
})));