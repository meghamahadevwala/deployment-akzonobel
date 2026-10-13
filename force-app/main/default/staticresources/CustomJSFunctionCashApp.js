//--- DO NOT CHANGE CODE | START ---//
(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
            (factory((global.gog = global.gog || {})));
}(this, (function (exports) {
    'use strict';

    var version = "1.0.0";
    //--- DO NOT CHANGE CODE | END ---//

    function onChangeCurrency(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        var CurrencyCode = values['CurrencyCode'];
        var convertRate = values.conversionRatesMap;
        return new Promise(function (resolve, reject) {
            if (convertRate.hasOwnProperty(CurrencyCode)) {
                values['ConversionRate'] = convertRate[CurrencyCode];
            } else {

                values['ConversionRate'] = '';
            }
            resolve(values);
        });
    }

    function onChangeTransactionCode(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {

            if (values.originalPaymentBatchList) {
                let payList = values.originalPaymentBatchList;
                let gridPayList = [];
                let transactionCode = values.TransactionCode;
                if (transactionCode == 'All') {
                    gridPayList = payList;
                } else {
                    for (let pay of payList) {
                        if (pay.TransactionCode == transactionCode) {
                            gridPayList.push(pay);
                        }
                    }
                }
                fireEvent(cmp.pageRef, 'PaymentBatchList_' + values.ggScreenName, gridPayList);
                resolve({ 'PaymentBatchList': gridPayList });
            } else {
                resolve({});
            }


        });
    }

    function onMyPayment(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {   //FIN-4855
        
        return new Promise(function (resolve, reject) {
            invoke({
            	nameSpace : '', 
            	className: 'CA_PaymentBatchController', 
            	functionName: 'myPayment',
            	values: values 
            }).then(result => { 
            	values = result;

                if (values.originalPaymentBatchList) {
                    let payList = values.originalPaymentBatchList;
                    let gridPayList = [];
                    let transactionCode = values.TransactionCode;
                    
                    if (transactionCode == 'All') {
                        for (let pay of payList) {
                            if (pay.assignedTo.includes(values.currentUserId)) {
                                gridPayList.push(pay);
                            }
                        }
                    } else {
                        for (let pay of payList) {
                            if (pay.TransactionCode == transactionCode && pay.assignedTo.includes(values.currentUserId)) {
                                gridPayList.push(pay);
                            }
                        }
                    }
                    
                    fireEvent(cmp.pageRef, 'PaymentBatchList_' + values.ggScreenName, gridPayList);
                    resolve({ 'PaymentBatchList': gridPayList });
                } else {
                    resolve({});
                }

                // resolve(result);
            }).catch(error => {
                console.log('error :' + error.body.message);
            	reject(error);
            });
        });
    }

    function navigateToFile(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            var rowVals = {};
            if (rowValue) {
                rowVals = rowValue;
            } else {
                rowVals = values.PaymentBatchList[values.gogGridIndex];
            }
            if (rowVals.hasOwnProperty('isBank') && rowVals.isBank == 'true') {
                sessionStorage.setItem("documentId", rowVals.contentDocId);
                window.open(rowVals.contentDocId, "_blank", "width=1200,height=600,modal=yes,alwaysRaised=yes");
            } else if (rowVals.hasOwnProperty('isRemittance') && rowVals.isRemittance == 'true') {
                cmp[navigationMixin.GenerateUrl]({
                    type: 'standard__navItemPage',
                    attributes: {
                        apiName: 'Email_Remittance',
                    },
                }).then(url => {
                    
                    if (rowValue) {
                        sessionStorage.setItem("paymentId", rowVals.AccountId);//rowVals.AccountId  
                        if (rowVals.paymentType != "OFFSET") {
                            sessionStorage.setItem("paymentName", rowVals.Name);
                        } else {
                            sessionStorage.setItem("paymentName", "");
                        }
                    }
                    setTimeout(function () {
                        window.open(url, "_blank", "width=1200,height=600,modal=yes,alwaysRaised=yes");
                    }, 0);
                });
            }
            resolve({});
        });
    }

    function showEmailRemittance(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            var paymentId = sessionStorage.getItem("paymentId");
            var paymentName = sessionStorage.getItem("paymentName");

            if (paymentName) {
                values.customEmailFilter = ' RelatedToId = \'' + paymentId + '\' AND Subject Like \'%' + paymentName + '%\' ';
            } else {
                values.customEmailFilter = ' RelatedToId = \'' + paymentId + '\' ';
            }

            sessionStorage.removeItem("paymentId");
            sessionStorage.removeItem("paymentName");
            
            resolve(values.customEmailFilter);
        });
    }

    function showRemittance(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            var Id = sessionStorage.getItem("documentId");
            cmp[navigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    // recordIds: Id,
                    selectedRecordId: Id,
                }
            });

            var url = "/servlet/servlet.FileDownload?file=" + attId;
            window.open(url, '_blank');

            sessionStorage.removeItem("documentId");
            
            resolve(values);
        });
    }

    function viewRemittance(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {

            if (rowValue.remittance != '') {
                navigateToFile(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
            }

            resolve({});
        });
    }

    function removeSubmitButton(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            values.submitProperties.enableSubmitButton = false;
            resolve(values);
        });
    }

    function onAssignUser(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent) {
        
            return new Promise(function (resolve, reject) {
                let payIdSet = [];
                for (let pay of values.PaymentBatchList) {
                    if (pay.isSelected && pay.PaymentId) {
                        payIdSet.push(pay.PaymentId);
                    }
                }

                let tempVal = {
                    "payIdSet": payIdSet,
                    "User": values.User
                }
                invoke({
                    nameSpace: '',
                    className: 'CA_PaymentBatchController',
                    functionName: 'AssignUserToPayment',
                    values: tempVal
                }).then(result => {
                    if(result.hasOwnProperty('ggErrorMessage') && result.ggErrorMessage != null && result.ggErrorMessage != undefined && result.ggErrorMessage != '') {
                        // let resolveVal = {};
                        // resolveVal.ggErrorMessage = result.ggErrorMessage;
                        // resolve(resolveVal);
                        cmp.dispatchEvent(new ShowToastEvent({
                            title: "Error",
                            message: result['ggErrorMessage'],
                            variant: "error",
                            mode: "sticky"
                        }));
                        resolve({});
                    } else {
                        if (values.PaymentBatchList && values.PaymentBatchList.length > 0) {
                            for (let Record of values['PaymentBatchList']) {
                                if (Record.isSelected == true) {
                                    Record.assignedTo = '<a href="' + '/' + values.User.id + '" target="_blank">' + values.User.name;
                                    Record.isSelected = false;
                                }
                            }
                            for (let Record of values['originalPaymentBatchList']) {
                                if (payIdSet.indexOf(Record.PaymentId) != -1) {
                                    Record.assignedTo = '<a href="' + '/' + values.User.id + '" target="_blank">' + values.User.name;
                                    Record.isSelected = false;
                                }
                            }
                        }
                        let resolveResult = {
                            "PaymentBatchList": values.PaymentBatchList,
                            "originalPaymentBatchList": values.originalPaymentBatchList,
                            "User": {}
                        }
                        resolve(resolveResult);
                    }
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            });
    }

    function refreshPaymentBatchCard(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            fireEvent(cmp.pageRef, "LoadCustomData_CA_PaymentBatchListScreen_batchInformation", values.batchInfo);
            resolve(values);
        });
    }

    function refreshpaymentbatchScreen(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            window.location.reload();
            resolve(values);
        });
    }

    function navigateToBankRemittance(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
         
        return new Promise(function (resolve, reject) {
            var urlParams = '';
            var rowVals = {};
            if (rowValue) {
                rowVals = rowValue;
            } else {
                rowVals = values.PaymentBatchList[rowNum];
            }

            if (rowVals) {
                urlParams += 'c__paymentId=' + rowVals.PaymentId;
                urlParams += '&c__acc=' + rowVals.AccountId;
                urlParams += '&c__paymentKey=' + rowVals.paymentKey;
                if (rowVals.contentDocId) {
                    urlParams += '&c__Doc=' + rowVals.contentDocId;
                }
                if (values.paymentType == 'OFFSET') {
                    urlParams += '&c__chequeNo=' + rowVals.paymentName + '/offset';
                } else if(values.paymentType == 'Write Off'){
                    urlParams += '&c__chequeNo=' + rowVals.paymentName + '/adjust';
                } else if(rowValue.LockBox == 'ACH'){
                    urlParams += '&c__chequeNo=' + rowVals.paymentName + '/ACH';
                } else {
                    urlParams += '&c__chequeNo=' + rowVals.paymentName;
                }
            }
            window.open('/lightning/cmp/c__CA_RemittanceViewer?' + urlParams, '_blank', "width=1200,height=600,modal=yes,alwaysRaised=yes");

            resolve({});
        });
    }

    function showBankRemittance(values, invoke, ds, fireEvent, ref) {
        
        return new Promise(function (resolve, reject) {
            if (values.Doc) {
                values.DocumentId = values.Doc;
                values.FileViewer = values.Doc;
            } else {
                if (values.chequeNo) {
                    values.customEmailFilter = ' RelatedToId = \'' + values.acc + '\' AND Subject Like \'%' + values.chequeNo + '%\' ';
                    if (values.chequeNo.includes('/offset')) {
                        values.chequeNo = values.chequeNo.split('/')[0];
                        values.customEmailFilter = ' RelatedToId = \'' + values.acc + '\' AND celsrm__CategoryPlain__c = \'Offset\'';
                    } else if(values.chequeNo.includes('/adjust')){
                        values.chequeNo = values.chequeNo.split('/')[0];
                        values.customEmailFilter = ' RelatedToId = \'' + values.acc + '\' AND celsrm__CategoryPlain__c = \'ADJUST\'';
                    } else if(values.chequeNo.includes('/ACH')){
                        values.chequeNo = values.chequeNo.split('/')[0];
                        values.customEmailFilter = ' RelatedToId = \'' + values.acc + '\' AND FromAddress = \'remittance.detail@ttiinc.com\'';
                    }
                } else {
                    values.customEmailFilter = ' RelatedToId = \'' + values.acc + '\' AND celsrm__CategoryPlain__c = \'Offset\'';
                }
                resolve(values.customEmailFilter);
            }
            invoke({
                nameSpace: '',
                className: 'CA_PaymentBatchController',
                functionName: 'getBankRemittanceForPayments',
                values: values
            }).then(result => {
                fireEvent(ref.pageRef, 'BankRemittanceList_' + result.ggScreenName, result.BankRemittanceList);
                fireEvent(ref.pageRef, 'refreshValues_' + result.ggScreenName, result);
                resolve({});
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });

        });
    }

    function refreshPaymentBatchList(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            invoke({
                nameSpace: '',
                className: 'CA_PaymentBatchController',
                functionName: 'GetPaymenBatchRecords',
                values: values
            }).then(result => {
                fireEvent(cmp.pageRef, 'PaymentBatchList_' + values.ggScreenName, result['PaymentBatchList']);
                resolve(result);
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });
        });
    }

    function onLoadPaymentBatchList(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            setTimeout(() => {
                fireEvent(cmp.pageRef, 'loadingEffect_' + values.ggScreenName + '_PaymentBatchList', true);
                invoke({
                    nameSpace: '',
                    className: 'CA_PaymentBatchController',
                    functionName: 'GetPaymenBatchRecords',
                    values: values
                }).then(result => {
                    fireEvent(cmp.pageRef,'PaymentBatchList_'+ values.ggScreenName, result['PaymentBatchList']);
                    resolve(result);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            }, 0);
        });
    }

    function submitPaymentReversal(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent) {
        
        return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CA_PaymentReversalController',
                    functionName: 'SavePaymentReversal',
                    values: values
                }).then(result => {
                    if(result.hasOwnProperty('ggErrorMessage') && result.ggErrorMessage != null && result.ggErrorMessage != undefined && result.ggErrorMessage != '') {
                        cmp.dispatchEvent(new ShowToastEvent({
                            title: "Error",
                            message: result['ggErrorMessage'],
                            variant: "error",
                            mode: "sticky"
                        }));
                        resolve({});
                    } else {
                        let valuesTOrefresh = {
                            detail: {
                                refreshParentValues: result.refreshParentValues
                            }
                        }
                        fireEvent(cmp.pageRef, "onCancel_CA_PaymentBatchListScreen_PaymentBatchList", valuesTOrefresh);
                        resolve(result);
                    }
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
        });
    }

    function updateAllPaymentReversal(values, invoke, ds, fireEvent, lwcRef, rowData) {
        
        var arr = values['paymentLineList'];
        var count = rowData['gogGridIndex'];
        var size = arr.length;
        var Fieldst = 'ReasonCode';
        if (arr[count][Fieldst] != null) {
            var RequiredValue = arr[count][Fieldst];
            for (var k = count; k < parseInt(size); k++) {
                arr[k][Fieldst] = RequiredValue;
            }
        }
        values['paymentLineList'] = arr;
        return new Promise(function (resolve, reject) {
            resolve(values);
        });
    }

    function showPaymentIdLoad(values, invoke, ds) {
        
        values["PayIdRemit"] = values.PaymentId;
        values["TitleName"] = values.Name + '| ' + values.Account.split('">')[1].split('</a>')[0] + '(' + values.accNumber + ')';
        return new Promise(function (resolve, reject) {
            resolve(values);
        });
    }

    function onSubmitUploadAttachment(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent) {
        
        return new Promise(function (resolve, reject) {
            invoke({
                nameSpace: '',
                className: 'CA_ApplyCashController_Cloned',
                functionName: 'UploadRemittance',
                values: values
            }).then(result => {
                // Added if else by ND - FIN-4493 - Upload remittance on alredy applied payment - show error message
                let valueToResolve = {};
                if (result.hasOwnProperty('ggErrorMessage')) {
                    cmp.dispatchEvent(new ShowToastEvent({
                        title: "Error",
                        message: result['ggErrorMessage'],
                        variant: "error",
                        mode: "sticky"
                    }));
                    delete result.ggErrorMessage;
                    valueToResolve = result;
                } else if(values.hasOwnProperty('PaymentBatchList')){
                    let valuesTOrefresh = {}
                    if (result.refreshParentValues) {
                        valuesTOrefresh = {
                            detail: {
                                refreshParentValues: result.refreshParentValues
                            }
                        }
                    }
                    fireEvent(cmp.pageRef, "onCancel_CA_PaymentBatchListScreen_PaymentBatchList", valuesTOrefresh);
                } else {
                    window.location.reload();
                }
                resolve(result);
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });
        });
    }

    function onAccountMappingSearch(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        var SearchBy = values['SearchBy'];
        var SearchValue = values['SearchValue'];
        let valuesTOsearch = {}
        valuesTOsearch.SearchBy = SearchBy;
        valuesTOsearch.SearchValue = SearchValue;
        if (SearchBy && SearchValue) {
            return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CA_PaymentBatchController',
                    functionName: 'accountMappingSearch',
                    values: valuesTOsearch
                }).then(result => {
                    if (SearchBy == 'Account') {
                        fireEvent(cmp.pageRef, 'AccountList_' + cmp.additionalAttributes.screenName, result.ResultList);
                    } else if (SearchBy == 'Invoice') {
                        fireEvent(cmp.pageRef, 'TransactionList_' + cmp.additionalAttributes.screenName, result.ResultList);
                    }
                    resolve(result);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            });
        } else if (SearchBy) {
            return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CA_PaymentBatchController',
                    functionName: 'accountMappingSearch',
                    values: valuesTOsearch
                }).then(result => {
                    if (SearchBy == 'Account') {
                        fireEvent(cmp.pageRef, 'AccountList_' + cmp.additionalAttributes.screenName, result.ResultList);
                    } else if (SearchBy == 'Invoice') {
                        fireEvent(cmp.pageRef, 'TransactionList_' + cmp.additionalAttributes.screenName, result.ResultList);
                    }
                    resolve(result);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            });
        } else {
            return new Promise(function (resolve, error) {
                let resolveVal = {};
                resolveVal.errorSearchValue = 'true';
                resolve(resolveVal);
            });
        }
    }

    function viewAccountMapping(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            
            values.gogGridIndex = rowNum;
            if (values.ggScreenName == 'CA_PaymentBatchListScreen'){
                values.paymentTransferId = rowValue.PaymentId;
            } else if (values.ggScreenName == 'CA_ClosePayment'){
                values.paymentTransferId = values.closePaymentList[rowNum].PaymentId;
            }
            
            let customChangeHandler = {
                "callingControlName": "AccountMap",
                "targetScreen": "CA_AccountMapping",
                "targetScreenSize": "medium-width",
                "sourceControlName": "AccountMap",
                "vals": values
            };

            if (values.ggScreenName == 'CA_PaymentBatchListScreen'){
                values.scrName = values.ggScreenName;
                fireEvent(cmp.pageRef, 'openChildScreen_' + cmp.additionalAttributes.screenName + '_PaymentBatchList', customChangeHandler);
            } else if (values.ggScreenName == 'CA_ClosePayment'){
                values.scrNameClosePayment = values.ggScreenName;
                fireEvent(cmp.pageRef, 'openChildScreen_' + cmp.additionalAttributes.screenName + '_closePaymentList', customChangeHandler);
            }
            resolve(values);
        });
    }

    function SubmitAccountMapping(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {

            if(values.AccountList.length > 0){
                rowNum = values.gogGridIndex;
                let accountTransferedId;
                let accountTransferedName;
                let accountTransferedNumber;
                var SearchBy = values['SearchBy'];
                if (SearchBy == 'Account' || SearchBy == '') {
                    accountTransferedId = values.AccountList[0].Id;
                    accountTransferedName = values.AccountList[0].Name;
                    accountTransferedNumber = values.AccountList[0].AccountNumber;
                } else if (SearchBy == 'Invoice') {
                    accountTransferedId = values.TransactionList[0].Id;
                    accountTransferedName = values.TransactionList[0].Name;
                    accountTransferedNumber = values.TransactionList[0].AccountNumber;
                }
                let paymentTransferId = values.paymentTransferId;
                let tempVal = {
                    "accountTransferedId": accountTransferedId,
                    "accountTransferedName": accountTransferedName,
                    "accountTransferedNumber": accountTransferedNumber,
                    "paymentTransferId": paymentTransferId
                }
                
                if (values.scrName == 'CA_PaymentBatchListScreen' && values.scrNameClosePayment != 'CA_ClosePayment' && values.scrNameAdjustment != 'CA_Adjustment' && values.scrNameManualApply != 'CA_ManualApplyCashCreditOffset'){   
                    invoke({
                        nameSpace: '',
                        className: 'CA_PaymentBatchController',
                        functionName: 'UpdateWebCash_PaymentTransafer',
                        values: tempVal
                    }).then(result => {
                        tempVal = {
                            "Id": values.Id
                        }
                        invoke({
                            nameSpace: '',
                            className: 'CA_PaymentBatchController',
                            functionName: 'GetPaymenBatchRecords',
                            values: tempVal
                        }).then(result1 => {
                            let refreshParentValues = {
                                "onChangeMethod": "onLoadPaymentBatchList"
                            }
                            let valuesTOrefresh = {
                                detail: {
                                    refreshParentValues: refreshParentValues
                                }
                            }
                            fireEvent(cmp.pageRef, "onCancel_CA_PaymentBatchListScreen_PaymentBatchList", valuesTOrefresh);
                            resolve({});
                            
                        }).catch(error => {
                            console.log('error :' + error.body.message);
                            reject(error);
                        });
                    }).catch(error => {
                        console.log('error :' + error.body.message);
                        reject(error);
                    });
                } else if (values.scrNameClosePayment == 'CA_ClosePayment'){
                    invoke({
                        nameSpace: '',
                        className: 'CA_PaymentBatchController',
                        functionName: 'UpdateWebCash_PaymentTransafer',
                        values: tempVal
                    }).then(result => {
                        values.closePaymentList[0].accountName = '<a href="' + '/'+ accountTransferedId + '"' + ' target="_blank">' + accountTransferedName + '</a>';
                        values.closePaymentList[0].accountNumber = accountTransferedNumber;
                        values.closePaymentList[0].accountId = accountTransferedId;
                        let refreshParentValues = {
                            "closePaymentList": values.closePaymentList
                        }
                        let valuesTOrefresh = {
                            detail: {
                                refreshParentValues: refreshParentValues
                            }
                        }
                        fireEvent(cmp.pageRef, "onCancel_CA_ClosePayment_closePaymentList", valuesTOrefresh);
                        resolve({});
                    }).catch(error => {
                        console.log('error :' + error.body.message);
                        reject(error);
                    });
                } else if (values.scrNameAdjustment == 'CA_Adjustment'){
                    values.transactionList[rowNum].accountName = '<a href="' + '/'+ accountTransferedId + '"' + ' target="_blank">' + accountTransferedName + '</a>';
                    values.transactionList[rowNum].AccountNumber = accountTransferedNumber;
                    values.transactionList[rowNum].account = accountTransferedId;
                    let refreshParentValues = {
                        "transactionList": values.transactionList
                    }
                    let valuesTOrefresh = {
                        detail: {
                            refreshParentValues: refreshParentValues
                        }
                    }
                    fireEvent(cmp.pageRef, "onCancel_CA_Adjustment_transactionList", valuesTOrefresh);
                    resolve({});
                } else if (values.scrNameManualApply == 'CA_ManualApplyCashCreditOffset'){
                    values.transactionList[rowNum].accountName = '<a href="' + '/'+ accountTransferedId + '"' + ' target="_blank">' + accountTransferedName + '</a>';
                    values.transactionList[rowNum].AccountNumber = accountTransferedNumber;
                    values.transactionList[rowNum].account = accountTransferedId;
                    let refreshParentValues = {
                        "transactionList": values.transactionList
                    }
                    let valuesTOrefresh = {
                        detail: {
                            refreshParentValues: refreshParentValues
                        }
                    }
                    fireEvent(cmp.pageRef, "onCancel_CA_ManualApplyCashCreditOffset_transactionList", valuesTOrefresh);
                    resolve({});
                }
                
            } else {
                let resolveVal = {};
                resolveVal.errorSelectRow = 'true';
                resolve(resolveVal);
            }

        });
    }

    function onChangeCreatePaymentAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            var TotalAmount = 0;
            for (let paymentbatch of Object.values(values['newPaymentBatchList'])) {
                if (paymentbatch.Amount && paymentbatch.Amount !== null && paymentbatch.Amount !== '') {
                    TotalAmount = TotalAmount + Number(paymentbatch.Amount);
                }
            }
            values['totalAmount'] = TotalAmount;
            resolve(values);
        });
    }

    function onSubmitCreatePayment(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            invoke({
                nameSpace: '',
                className: 'CA_PaymentBatchController',
                functionName: 'createPaymentandPaymentBatch',
                values: values
            }).then(result => {
                resolve({});
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });
        });
    }

    function onChangeInvoiceMatch(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            var invoiceMatch = values.InvoiceMatch;
           
            if (invoiceMatch == 'Unmatch'){
                let BankRemittanceUnmatchList = [];
               
                for (var item of Object.values(values['OriginalBankRemittanceList'])) {
                    if(item.isMatch == 'false'){
                        BankRemittanceUnmatchList.push(item);
                    }
                }
                if(BankRemittanceUnmatchList.length > 0){
                    values.BankRemittanceListUnmatch = BankRemittanceUnmatchList;
                }
                fireEvent(cmp.pageRef, 'BankRemittanceListUnmatch_' + cmp.additionalAttributes.screenName , values.BankRemittanceListUnmatch); 
            } else if(invoiceMatch == 'All'){
                values.BankRemittanceList = values.OriginalBankRemittanceList;
                fireEvent(cmp.pageRef, 'BankRemittanceList_' + cmp.additionalAttributes.screenName , values.BankRemittanceList); 
            }
            resolve({});
        });
    }

    function deletePayment(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        if (confirm('Are you sure want to delete payment# ' + rowValue.AutoNumber + ' ?')) {
            let valueMap = {
                "Id": values.Id,
                "TransactionCode": values.TransactionCode,
                "PaymentId": rowValue.Id,
                "Payment": rowValue
            }

            return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CA_PaymentBatchController',
                    functionName: 'deletePayment',
                    values: valueMap
                }).then(result => {
                    invoke({
                        nameSpace: '',
                        className: 'CA_PaymentBatchController',
                        functionName: 'GetPaymenBatchRecords',
                        values: values
                    }).then(result => {
                        fireEvent(cmp.pageRef,'PaymentBatchList_'+ values.ggScreenName, result['PaymentBatchList']);
                        resolve(result);
                    }).catch(error => {
                        console.log('error :' + error.body.message);
                        reject(error);
                    });
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            });
        } else {
            return new Promise(function (resolve, reject) {
                resolve({});
            });
        }
    }

    function onAddSplitPayment(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            let record = JSON.parse(JSON.stringify(values.splitedPaymentList[0]));
            record.amount = 0;
            record.entity = null;
            values.splitedPaymentList.push(record);
            resolve(values.splitedPaymentList);
        });
    }

    function onChangeSplitPaymentAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            let utilisedAmount = 0;
            let returnVal = {};
            for(let record of Object.values(values.splitedPaymentList)){
                utilisedAmount += parseFloat(record.amount.toString().replaceAll(',',''));
            }
            utilisedAmount = utilisedAmount.toFixed(2);
            returnVal.utilisedAmount = utilisedAmount;
            returnVal.remainingAmount = values.paymentAmount - utilisedAmount;
            if(utilisedAmount > values.paymentAmount){
                returnVal.errorUtilisedAmountGreater = 'true';
            }
            resolve(returnVal);
        });
    }

    function onSubmitSplitedPayment(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent) {
        
        return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CA_SplitPaymentController',
                    functionName: 'submitSplitedPayments',
                    values: values
                }).then(result => {
                    if(result.hasOwnProperty('ggErrorMessage') && result.ggErrorMessage != null && result.ggErrorMessage != undefined && result.ggErrorMessage != '') {
                        cmp.dispatchEvent(new ShowToastEvent({
                            title: "Error",
                            message: result['ggErrorMessage'],
                            variant: "error",
                            mode: "sticky"
                        }));
                        resolve({});
                    } else {
                        let valuesTOrefresh = {
                            detail: {
                                refreshParentValues: result.refreshParentValues
                            }
                        }
                        fireEvent(cmp.pageRef, "onCancel_CA_PaymentBatchListScreen_PaymentBatchList", valuesTOrefresh);
                        resolve({});
                    }
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
        });
    }

    function onSelectAccountMap(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum){
        
        return new Promise(function (resolve, reject) {
            
            if(values.ggScreenName == 'CA_CreatePaymentANDPaymentBatch'){
                if(rowNum != null && rowNum != undefined){
                    let AccountId = values.newPaymentBatchList[rowNum].Account.id;
                    if(AccountId != null && AccountId != '' && AccountId != undefined){
                        let tempMap = {};
                        tempMap.rowNum =  rowNum;
                        tempMap.AccountId = AccountId;
                        invoke({
                            // nameSpace: '',
                            className: 'CA_PaymentBatchController',
                            functionName: 'getPaymentAccount',
                            values: tempMap
                        }).then(result => {
                            values.newPaymentBatchList[rowNum].AccountNumber = result.AccountNumber;
                            resolve(values);
                        }).catch(error => {
                            console.log('error :' + error.body.message);
                            reject(error);
                        });
                    } else {
                        values.newPaymentBatchList[rowNum].AccountNumber = '';
                        resolve(values);
                    }
                }
            }
        });
    } 

    function onSubmitAddComment(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            invoke({
                nameSpace: '',
                className: 'CA_PaymentBatchController',
                functionName: 'submitAddComment',
                values: values
            }).then(result => {
                let valuesTOrefresh = {
                    detail: {
                        refreshParentValues: result.refreshParentValues
                    }
                }
                fireEvent(cmp.pageRef, "onCancel_CA_PaymentBatchListScreen_PaymentBatchList", valuesTOrefresh);
                resolve({});
                // resolve(result);
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });
        });
    }

    function onComment(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            var payList = [];
            for (let pay of Object.values(values['PaymentBatchList'])) {
                if (pay.isSelected === true) {
                    payList.push(pay);
                }
            }
            if (payList.length > 0) {
                let customChangeHandler = {
                    "callingControlName": "comment",
                    "targetScreen": "CA_AddComment",
                    "targetScreenSize": "small-width",
                    "sourceControlName": "comment",
                    "vals": values
                };
                // fireEvent(cmp.pageRef, 'openChildScreen_' + cmp.additionalAttributes.screenName + '_comment', customChangeHandler);
                fireEvent(cmp.pageRef, 'openChildScreen_' + cmp.additionalAttributes.screenName + '_PaymentBatchList', customChangeHandler);
                resolve(values);
            } else {
                let resolveVal = {};
                resolveVal.errorSelectRow = 'true';
                resolve(resolveVal);
            }
        });
    }
       
    exports.onComment = onComment;
    exports.onSubmitAddComment = onSubmitAddComment;
    exports.onSelectAccountMap = onSelectAccountMap;
    exports.onChangeInvoiceMatch = onChangeInvoiceMatch;
    exports.onLoadPaymentBatchList = onLoadPaymentBatchList;
    exports.onChangeCurrency = onChangeCurrency;
    exports.onChangeTransactionCode = onChangeTransactionCode;
    exports.onMyPayment = onMyPayment;
    exports.showEmailRemittance = showEmailRemittance;
    exports.showRemittance = showRemittance;
    exports.viewRemittance = viewRemittance;
    exports.removeSubmitButton = removeSubmitButton;
    exports.onAssignUser = onAssignUser;
    exports.refreshPaymentBatchCard = refreshPaymentBatchCard;
    exports.refreshpaymentbatchScreen = refreshpaymentbatchScreen;
    exports.navigateToBankRemittance = navigateToBankRemittance;
    exports.showBankRemittance = showBankRemittance;
    exports.deletePayment = deletePayment;
    exports.submitPaymentReversal = submitPaymentReversal;
    exports.updateAllPaymentReversal = updateAllPaymentReversal;
    exports.showPaymentIdLoad = showPaymentIdLoad;
    exports.onSubmitUploadAttachment = onSubmitUploadAttachment;
    exports.refreshPaymentBatchList = refreshPaymentBatchList;
    exports.onAccountMappingSearch = onAccountMappingSearch;
    exports.viewAccountMapping = viewAccountMapping;
    exports.SubmitAccountMapping = SubmitAccountMapping;
    exports.onChangeCreatePaymentAmount = onChangeCreatePaymentAmount;
    exports.onSubmitCreatePayment = onSubmitCreatePayment;
    exports.onAddSplitPayment = onAddSplitPayment;
    exports.onChangeSplitPaymentAmount = onChangeSplitPaymentAmount;
    exports.onSubmitSplitedPayment = onSubmitSplitedPayment;

    //--- DO NOT CHANGE CODE | START ---//
    Object.defineProperty(exports, '__esModule', {
        value: true
    });
    //--- DO NOT CHANGE CODE | END ---//
})));