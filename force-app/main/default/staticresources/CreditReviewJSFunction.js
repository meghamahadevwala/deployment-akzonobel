//--- DO NOT CHANGE CODE | START ---//
(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
            (factory((global.gog = global.gog || {})));
}(this, (function (exports) {
    'use strict';

    var version = "1.0.0";
    //--- DO NOT CHANGE CODE | END ---//	
    
    function onLoadInitiateCreditReview(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        debugger;
        return new Promise(function (resolve, reject) {
            invoke({
                nameSpace: '',
                className: 'CreditReviewParameters',
                functionName: 'initiateCreditReview',
                values: values
            }).then(result => {
                if(
                    (result.creditReviewExists != null && result.creditReviewExists == true) || 
                    (result.isAccountSnoozed != null && result.isAccountSnoozed == true) || 
                    (result.isChildAccount != null && result.isChildAccount == true) || 
                    (result.isCreditGroupEmpty != null && result.isCreditGroupEmpty == true) ||
                    (result.isCreditGroupInvalid != null && result.isCreditGroupInvalid == true)
                ) {
                    fireEvent(cmp.pageRef, 'closeScreen_' + values['ggScreenName'], result);
                    // registerListener('closeScreen_' + this.config.name, this.closeScreen, this);
                }
                if(result.companyDetailList != null && result.companyDetailList.length > 0) {
                    fireEvent(cmp.pageRef, 'companyDetailList_' + values['ggScreenName'], result.companyDetailList);
                }
                result['companyDetailList'] = [];
                resolve(result);
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });
        });
    }

    // function onLoadInitiateScoreItCreditReview(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, ShowToastEvent) {
    //     var screenName = values['ggScreenName'];
    //     console.log('onLoadInitiateScoreItCreditReview');
    //     return new Promise(function (resolve, reject) {
    //             invoke({
    //                 nameSpace: '',
    //                 className: 'CreditReviewParameters',
    //                 functionName: 'getCreditScoreData',
    //                 values: values
    //             }).then(result => {
    //                 if(result.ggErrorMessage != null && result.ggErrorMessage != '') {
    //                     fireEvent(cmp.pageRef, 'closeScreen_' + screenName , null);
    //                 }
    //                 resolve(result);
    //             }).catch(error => {
    //                 console.log('error :' + error.body.message);
    //                 reject(error);
    //             });
    //         // }
    //     });
    // }

    // function onLoadQuickScoreAccont(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, ShowToastEvent) {
    //     console.log('onLoadQuickScoreAccont');
    //     return new Promise(function (resolve, reject) {
    //         // resolve({
    //         //     hideCompanyList: 'false',
    //         //     hideScoreCalculation: 'true'
    //         // });
    //             invoke({
    //                 nameSpace: '',
    //                 className: 'CreditReviewParameters',
    //                 functionName: 'getCreditScoreDataAccount',
    //                 values: values
    //             }).then(result => {
    //                 console.debug('result.BillingAddress >>' + JSON.stringify(result.BillingAddress));
    //                 fireEvent(cmp.pageRef, 'companyDetailList_' + values['ggScreenName'], result.companyDetailList);
    //                 // result['companyDetailList'] = [];
    //                 resolve(result);
    //             }).catch(error => {
    //                 console.log('error :' + error.body.message);
    //                 reject(error);
    //             });
    //     });
    // }

    // function onChangeModelType (values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, ShowToastEvent) {
    //     return new Promise(function (resolve, reject) {
    //             if(values.modelType == null || values.modelType == '') {
    //                 let inMap = {};
    //                 inMap.ggErrorMessage = 'Model Type should not be empty';
    //                 resolve(inMap)
    //             } else {
    //                 invoke({
    //                     nameSpace: '',
    //                     className: 'CreditReviewParameters',
    //                     functionName: 'getCreditScoreDataAccount',
    //                     values: values
    //                 }).then(result => {
    //                     fireEvent(cmp.pageRef, 'companyDetailList_' + values['ggScreenName'], result.companyDetailList);
    //                     // result['companyDetailList'] = [];
    //                     resolve(result);
    //                 }).catch(error => {
    //                     console.log('error :' + error.body.message);
    //                     reject(error);
    //                 });   
    //             }
    //     });
    // }

    // function updateDUNSNumberOnAccount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
    //     let DUNSNumber = '';
    //     //var screenName = values['ggScreenName'];
    //     if(values.companyDetailList.length > 0){
    //         let companyDetails = values.companyDetailList[0];
    //         DUNSNumber = companyDetails.DUNSNumber;
    //         values.DUNSNumber = DUNSNumber;
    //         return new Promise(function (resolve, reject) {
    //             invoke({
    //                 nameSpace: '',
    //                 className: 'CreditReviewParameters',
    //                 functionName: 'updateDUNSNumber',
    //                 values: values
    //             }).then(result => {
    //                 let result2;
    //                 if(values['ggScreenName'] == 'InitiateCreditReview') {
    //                     result2 = onLoadInitiateCreditReview(result, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum)
    //                 } else if(values['ggScreenName'] == 'AccountQuickScore') {
    //                     result2 = onLoadQuickScoreAccont(result, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum)
    //                 }
    //                 resolve(result2);
    //             }).catch(error => {
    //                 console.log('error :' + error.body.message);
    //                 reject(error);
    //             });
    //         });
    //     } else {
            
    //         return new Promise(function (resolve, error) {
    //             values.ggErrorMessage = 'Please select company.';
    //             resolve(values.ggErrorMessage);
    //         });
    //     }
    // }

    function saveCreditReviewRecord(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, showToast) {
        var screenName = values['ggScreenName'];
        return new Promise(function (resolve, reject) {
            // if(values.Id == null || values.Id == '') {
            //     let inMap = {};
            //     inMap.ggErrorMessage = 'Failed to get reference of Credit Review';
            //     fireEvent(cmp.pageRef, 'closeScreen_' + screenName , null);
            //     resolve(inMap);
            // } else if(values.dunsNumber == null || values.dunsNumber == '') {
            //     let inMap = {};
            //     inMap.ggErrorMessage = 'Please update Duns Number on Credit Review';
            //     fireEvent(cmp.pageRef, 'closeScreen_' + screenName , null);
            //     resolve(inMap);
            // } else {
            // if(values.modelType == null || values.modelType == undefined || values.modelType == '') {
            //     let inMap = {};
            //     inMap.ggErrorMessage = 'Please select model type!';
            //     // fireEvent(cmp.pageRef, 'closeScreen_' + screenName , null);
            //     resolve(inMap);
            // } else {
            debugger;
            let today = new Date();
            let oneYearFromToday = new Date();
            oneYearFromToday.setDate(today.getDate() + 365);
            if(values.RequestedCreditLimit == null || values.RequestedCreditLimit == 0 || isNaN(values.RequestedCreditLimit)) {
                values.RequestedCreditLimit = 0.0;
                values.RequestedCreditLimitEUR = 0.0;
            }
            // if(values.RequestedCreditLimit == null || isNaN(values.RequestedCreditLimit)) {
            //     let inMap = {};
            //     inMap.ggErrorMessage = 'Requested Credit Limit must not be empty';
            //     resolve(inMap);
            // } else 
            if(values.RequestedValidToDate == null ) {
                let inMap = {};
                inMap.ggErrorMessage = 'Requested Valid To Date must not be empty';
                resolve(inMap);
            // << START - MM - CBE-49447 - Requested Valid To Date should not be today>>
            // } else if(!(new Date(values.RequestedValidToDate) >= today && new Date(values.RequestedValidToDate) <= oneYearFromToday)) {
            } else if(!(new Date(values.RequestedValidToDate) > today && new Date(values.RequestedValidToDate) <= oneYearFromToday)) {
            // << END - MM - CBE-49447 - Requested Valid To Date should not be today>>
                let inMap = {};
                // << START - MM - CBE-49447 - Requested Valid To Date should not be today>>
                // inMap.ggErrorMessage = 'Requested Valid To Date must be ranges from TODAY to TODAY + 365 days';
                inMap.ggErrorMessage = 'Requested Valid To Date must be ranges from TODAY + 1 day to TODAY + 365 days';
                // << END - MM - CBE-49447 - Requested Valid To Date should not be today>>
                resolve(inMap);
            } else {
                invoke({
                    nameSpace: '',
                    className: 'CreditReviewParameters',
                    functionName: 'createCreditReviewRecord',
                    values: values
                }).then(result => {
                    fireEvent(cmp.pageRef, 'closeScreen_' + screenName , null);
                    window.open('/' + result.creditReviewId, "_self");
                    resolve(result);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            }
                
            // }
        });
    }   

    // function saveCreditScore(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
    //     var screenName = values['ggScreenName'];
    //     return new Promise(function (resolve, reject) {
    //         // if(values.DUNSNumber != '' && values.DUNSNumber != null) {
    //             invoke({
    //                 nameSpace: '',
    //                 className: 'CreditReviewParameters',
    //                 functionName: 'saveCreditScoreData',
    //                 values: values
    //             }).then(result => {
    //                 fireEvent(cmp.pageRef, 'closeScreen_' + screenName , null);
    //                 // if(result.ggErrorMessage == null || result.ggErrorMessage == '') {
    //                 //     window.open('/' + result.creditScoreId, "_self");
    //                 // }
    //                 resolve(result);
    //             }).catch(error => {
    //                 console.log('error :' + error.body.message);
    //                 reject(error);
    //             });
    //         // }  else {
    //         //     let inMap = {};
    //         //     inMap.ggErrorMessage = 'Please update Duns Number on Credit Review';
    //         //     fireEvent(cmp.pageRef, 'closeScreen_' + screenName , null);
    //         //     resolve(inMap);
    //         // }
            
    //     });
    // }  

    function submitVoidCreditReview(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent){
        debugger;
        var screenName = values['ggScreenName'];
        return new Promise(function (resolve, reject) {
            invoke({
                nameSpace: '',
                className: 'VoidCreditReviewController',
                functionName: 'onSubmitVoidCreditReview',
                values: values
            }).then(result => {
                if(result.resStatus != null && result.resStatus == 'error') {
                    let inMap = {};
                    inMap.ggErrorMessage = result.resMessage;
                    resolve(inMap);
                } else {
                    cmp.dispatchEvent(new ShowToastEvent({
                        title: "Success",
                        message: result.resMessage,
                        variant: "success",
                        mode: "dismissable"
                     }));
                    fireEvent(cmp.pageRef, 'closeScreen_' + screenName , null);
                    
                    // resolve({});
                    resolve(inMap);
                }
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });
        });
    }

    function loadVoidCreditReview(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum){
        debugger;
        var screenName = values['ggScreenName'];
        return new Promise(function (resolve, reject) {
            invoke({
                nameSpace: '',
                className: 'VoidCreditReviewController',
                functionName: 'onLoadVoidCreditReview',
                values: values
            }).then(result => {
                if(result.resStatus != null && result.resStatus == 'error') {
                    let inMap = {};
                    inMap.ggErrorMessage = result.resMessage;
                    fireEvent(cmp.pageRef, 'closeScreen_' + screenName , null);
                    resolve(inMap);
                } else {
                    // fireEvent(cmp.pageRef, 'closeScreen_' + screenName , null);
                    resolve({});
                }
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });
        });
    }

    function updateBvdIdOnAccount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        let bvdId = '';
        debugger;
        //var screenName = values['ggScreenName'];
        console.log(JSON.stringify(values));
        if(values.companyDetailList.length > 0){
            let companyDetails = values.companyDetailList[0];
            bvdId = companyDetails.bvDId;
            values.bvDId = bvdId;
            return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CreditReviewParameters',
                    functionName: 'updateBvdId',
                    values: values
                }).then(result => {
                    let result2;
                    if(values['ggScreenName'] == 'InitiateCreditReview') {
                        result2 = onLoadInitiateCreditReview(result, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum)
                    } 
                    // else if(values['ggScreenName'] == 'AccountQuickScore') {
                    //     result2 = onLoadQuickScoreAccont(result, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum)
                    // }
                    resolve(result2);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            });
        } else {
            return new Promise(function (resolve, reject) {
                let objToResolve = {};
                objToResolve.fetchParams = 'true';
                resolve(objToResolve);
            });
        }
        //     return new Promise(function (resolve, error) {
        //         values.ggErrorMessage = 'Please select company.';
        //         resolve(values.ggErrorMessage);
        //     });
        // }
    }

    function onChangeRequestedCreditLimit(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        return new Promise(function (resolve, reject) {
            debugger;
            if(values.RequestedCreditLimit == 0 || values.RequestedCreditLimit == null || values.RequestedCreditLimit == undefined) {
                let inMap = {};
                inMap.RequestedCreditLimit = 0;
                inMap.RequestedCreditLimitEUR = 0;
                resolve(inMap);
            } else {
                invoke({
                    nameSpace: '',
                    className: 'CreditReviewParameters',
                    functionName: 'calculateRequestedCreditLimitEUR',
                    values: values
                }).then(result => {
                    // let result2;
                    // if(values['ggScreenName'] == 'InitiateCreditReview') {
                    //     result2 = onLoadInitiateCreditReview(result, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum)
                    // } 
                    // else if(values['ggScreenName'] == 'AccountQuickScore') {
                    //     result2 = onLoadQuickScoreAccont(result, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum)
                    // }
                    resolve(result);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            }
        });
    }
    exports.onLoadInitiateCreditReview = onLoadInitiateCreditReview;
    // exports.updateDUNSNumberOnAccount = updateDUNSNumberOnAccount;
    exports.saveCreditReviewRecord = saveCreditReviewRecord;
    // exports.onLoadInitiateScoreItCreditReview = onLoadInitiateScoreItCreditReview;
    // exports.saveCreditScore = saveCreditScore;
    // exports.onLoadQuickScoreAccont = onLoadQuickScoreAccont;
    // exports.onChangeModelType = onChangeModelType;
    exports.submitVoidCreditReview = submitVoidCreditReview;
    exports.loadVoidCreditReview = loadVoidCreditReview;
    exports.updateBvdIdOnAccount = updateBvdIdOnAccount;
    exports.onChangeRequestedCreditLimit = onChangeRequestedCreditLimit;
    //--- DO NOT CHANGE CODE | START ---//
    Object.defineProperty(exports, '__esModule', {
        value: true
    });
    //--- DO NOT CHANGE CODE | END ---//
})));