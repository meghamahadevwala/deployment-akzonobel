//--- DO NOT CHANGE CODE | START ---//
(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
            (factory((global.gog = global.gog || {})));
}(this, (function (exports) {
    'use strict';

    var version = "1.0.0";
    //--- DO NOT CHANGE CODE | END ---//	
    function onSubmitApplyCash(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent) {
        
		 var RemainingbalAmt = Number(values.RemainingChequeBalance.split(' : ')[1].split('</b>')[0].replace(/,/g, ''));
        if (values.accountName == 'Suspense Account') {
            return new Promise(function (resolve, error) {
                values.ggErrorMessage = 'You can not apply cash on Suspense Account, Please map Payment to any Account.';
                resolve(values.ggErrorMessage);
            });
        } else if (RemainingbalAmt > 0) {
            return new Promise(function (resolve, error) {
                values.ggErrorMessage = 'Remaining Balance should not be less then zero';
                resolve(values.ggErrorMessage);
            });
        }else {
            return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CA_ApplyCashController_Cloned',
                    functionName: 'ApplyCash',
                    values: values
                }).then(result => {
                    let valueToResolve = {};
                    if (result.hasOwnProperty('ggErrorMessage')) {
                        cmp.dispatchEvent(new ShowToastEvent({
                            title: "Error",
                            message: result['ggErrorMessage'],
                            variant: "error",
                            mode: "dismissable"
                        }));
                        valueToResolve = result;
                    } else {
                        let valuesTOrefresh = {
                            detail: {
                                refreshParentValues: result.refreshParentValues
                            }
                        }
                        fireEvent(cmp.pageRef, "onCancel_CA_PaymentBatchListScreen_PaymentBatchList", valuesTOrefresh);
                    }
                    resolve(valueToResolve);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            });
        }
    }

    function onSelectCashAppPayment(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        return new Promise(function (resolve, reject) {
            invoke({
                nameSpace: '',
                className: 'CA_ApplyCashController_Cloned',
                functionName: 'getTransactions',
                values: values
            }).then(result => {
                if (values['ggScreenName'] = 'CA_ApplyCashCreditOffset_Clone') {
                    onChangeAppliedAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
                }
                resolve(result);
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });
        });
    }

    function onPageLoadInvoiceType(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            invoke({
                nameSpace: '',
                className: 'CA_ApplyCashController_Cloned',
                functionName: 'getOpenItems',
                values: values
            }).then(result => {
                resolve(result);
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });
        });

    }

    function onChangeInvoiceType(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        if (values.InvoiceType == 'OpenItem') {
            var screenName = values['ggScreenName'];
            return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CA_ApplyCashController_Cloned',
                    functionName: 'getOpenItems',
                    values: values
                }).then(result => {
                    var selInvo = new Set()
                    for (let tx of result.transactionList) {
                        if (tx.isSelected == true) {
                            selInvo.add(tx.trnsName);
                        }
                    }
                    for (let Item of result.OpenItemList) {
                        if (selInvo.has(Item.trnsName)) {
                            Item.isSelected = true;
                        }
                    }
                    fireEvent(cmp.pageRef, 'OpenItemList_' + screenName, result.OpenItemList);
                    delete result.OpenItemList;
                    let resultMap = {};
                    resultMap.OpenItemList = result.OpenItemList;
                    resultMap.BaseCurrencyCode = result.isBaseCurrencyCode;
                    resolve(resultMap);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            });
        } else if (values.InvoiceType == 'Unmatch') {
            var screenName = values['ggScreenName'];
            return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CA_ApplyCashController_Cloned',
                    functionName: 'UnMatchwithRemiitance',
                    values: values
                }).then(result => {
                    var invoicePaidAmount = 0;
                    let resultMap = {};
                    if(result.UnMatchwithRemiitance){
                        for (let tx of result.UnMatchwithRemiitance) {
                            tx.errorMsg = '<img src="/resource/cashApp_images/cashApp_images/errorMsg.png" height="20" width="20" title="'+tx.celsrm__Error_Description__c+'" style="margin-bottom: 0px;"/>';
                            invoicePaidAmount+=tx.celsrm__Invoice_Paid_Amount__c;
                        }
                        values.UnMatchAmount='<b style="color:Green"> ' + values.CurrencyCode + ' : ' + parseFloat(invoicePaidAmount).toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,') + '</b>';
                        fireEvent(cmp.pageRef, 'UnMatchwithRemiitance_' + screenName, result.UnMatchwithRemiitance);
                        
                        resultMap.UnMatchwithRemiitance = result.UnMatchwithRemiitance;
                        delete result.UnMatchwithRemiitance;
                    }
                    resolve(resultMap);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            });
        } else {
            return new Promise(function (resolve, error) {
                resolve({});
            });
        }
    }

    function onChangeCurrency(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        var CurrencyCode = values['CurrencyCode'];
        var convertRate = values.conversionRatesMap;
        return new Promise(function (resolve, error) {
            if (convertRate.hasOwnProperty(CurrencyCode)) {
                values['ConversionRate'] = convertRate[CurrencyCode];
            } else {
                values['ConversionRate'] = '';
            }

            for (let trans of Object.values(values['transactionList'])) {
                if (trans.isSelected == true) {
                    // (grid change) if (values.corporateCurrency == values.PaymentBatchList[values.gogGridIndex].CurrencyIsoCode) {
                    if (values.corporateCurrency == values.CurrencyIsoCode) {    
                        trans.appliedBalance = Number((trans.balance / values.conversionRatesMap[trans.CurrencyIsoCode]).toFixed(2));
                        trans.cashAppBalance = Number((trans.balance / values.conversionRatesMap[trans.CurrencyIsoCode]).toFixed(2));
                        trans.discountAmountRequested = Number((trans.discountAmount / values.conversionRatesMap[trans.CurrencyIsoCode]).toFixed(2));
                    } else {
                        trans.appliedBalance = Number((trans.balance * values['ConversionRate']).toFixed(2));
                        trans.cashAppBalance = Number((trans.balance * values['ConversionRate']).toFixed(2));
                        trans.discountAmountRequested = Number((trans.discountAmount * values['ConversionRate']).toFixed(2));
                    }
                    trans.appliedBalCopy = Number(trans.appliedBalance.toFixed(2));
                    //  trans.discountAmountRequested = trans.discountAmount;
                }
                trans.appliedBalCopy = Number(trans.appliedBalance.toFixed(2));
                trans.discountAmountRequested = trans.discountAmount;
            }
            onChangeAppliedAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
            resolve(values);
        });
    }

    function onConvertRate(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            for (let trans of Object.values(values['transactionList'])) {
                if (trans.isSelected == true) {
                    // (grid change) if (values.corporateCurrency == values.PaymentBatchList[values.gogGridIndex].CurrencyIsoCode) {
                    if (values.corporateCurrency == values.CurrencyIsoCode) {    
                        trans.appliedBalance = Number((trans.balance * values['ConversionRate']).toFixed(2));
                        trans.cashAppBalance = Number((trans.balance * values['ConversionRate']).toFixed(2));
                    } else {
                        trans.appliedBalance = Number((trans.balance / values['ConversionRate']).toFixed(2));
                        trans.cashAppBalance = Number((trans.balance / values['ConversionRate']).toFixed(2));
                    }
                    trans.appliedBalCopy = Number(trans.appliedBalance.toFixed(2));
                    trans.discountAmountRequested = trans.discountAmount;
                }
                trans.appliedBalCopy = Number(trans.appliedBalance.toFixed(2));
                trans.discountAmountRequested = trans.discountAmount;
            }
            onChangeAppliedAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);

            resolve(values);
        });
    }

    function onSelectTransaction(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent) {
        
        return new Promise(function (resolve, error) {
            var recordList = values.transactionList;
            if (rowNum && !rowNum.isNaN && rowNum != 'on') {//rowNum != 'on'
                if (recordList[rowNum].celsrm__CashApp_Balance__c != 0) {
                    if (recordList[rowNum].isSelected == true) {
                        if (values.isMultiCurrencyOrganization) {
                            if (values.PaymentBatchList) {
                                values.CurrencyCode = values.CurrencyIsoCode;
                            }
                            var conversionrate = values.conversionRatesMap[values.CurrencyCode];
                            if (recordList[rowNum].CurrencyIsoCode == values.CurrencyCode) {
                                recordList[rowNum].appliedBalance = recordList[rowNum].appliedBalance;
                            } else if (recordList[rowNum].CurrencyIsoCode != values.CurrencyCode) {
                                if (values.CurrencyCode == recordList[rowNum].BaseCurrency) {
                                    recordList[rowNum].appliedBalance = recordList[rowNum].appliedBalance;
                                } else if (values.CurrencyCode != recordList[rowNum].BaseCurrency && values.corporateCurrency == values.CurrencyCode) {
                                    recordList[rowNum].appliedBalance = Number((recordList[rowNum].appliedBalance / values.conversionRatesMap[recordList[rowNum].CurrencyIsoCode]).toFixed(2));
                                    recordList[rowNum].cashAppBalance = Number((recordList[rowNum].balance / values.conversionRatesMap[recordList[rowNum].CurrencyIsoCode]).toFixed(2));
                                    recordList[rowNum].discountAmountRequested = Number((recordList[rowNum].discountAmountRequested / values.conversionRatesMap[recordList[rowNum].CurrencyIsoCode]).toFixed(2));
                                } else if (values.CurrencyCode != recordList[rowNum].BaseCurrency && values.corporateCurrency != values.CurrencyCode) {
                                    recordList[rowNum].appliedBalance = Number((recordList[rowNum].appliedBalance * conversionrate).toFixed(2));
                                    recordList[rowNum].cashAppBalance = Number((recordList[rowNum].balance * conversionrate).toFixed(2));
                                    recordList[rowNum].discountAmountRequested = Number((recordList[rowNum].discountAmountRequested * conversionrate).toFixed(2));
                                }
                            }
                            recordList[rowNum].appliedBalCopy = Number(recordList[rowNum].appliedBalance.toFixed(2));
                        } else {
                            recordList[rowNum].appliedBalance = recordList[rowNum].appliedBalCopy;
                        }
                    } 
                } else {
                    recordList[rowNum].isSelected = false;
                    cmp.dispatchEvent(new ShowToastEvent({
                        title: "Error",
                        message: "You are selecting one of the Invoice which was already Paid",
                        variant: "error",
                        mode: "dismissable"
                    }));
                }
            } else {
                for (let trans of recordList) {
                    if (trans.celsrm__CashApp_Balance__c == 0) {
                        cmp.dispatchEvent(new ShowToastEvent({
                            title: "Error",
                            message: "You are selecting one of the Invoice which was already Paid",
                            variant: "error",
                            mode: "dismissable"
                        }));
                        trans.isSelected = false;
                        break;
                    }
                }
            }
            onChangeAppliedAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);

            resolve(values);
        });
    }

    function onCHangeDiscountAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            values.transactionList[rowNum].appliedBalance = parseFloat((values.transactionList[rowNum].cashAppBalance - values.transactionList[rowNum].discountAmountRequested).toFixed(2));
            onChangeAppliedAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
            resolve(values);
        });
    }

    function onSelectionChangeAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            let unAppliedBalance = 0;
            var totalAppliedAmt = 0.0, totalRemainingAmt = 0.0, totalOverPay = 0.0, totalDeductionBal = 0.0, totalDiscount = 0.0, totalSelectedCredit = 0;

            if (values.includeCredit == false) {
                unAppliedBalance = Number(parseFloat((values.unAppliedBalance.replace(/^\D+|\D+$/g, "")).replace(/,/g, '')));
            } else {
                unAppliedBalance = Number(parseFloat((values.unAppliedBalance.replace(/^\D+|\D+$/g, "")).replace(/,/g, ''))) + Number(parseFloat((values.creAmt.replace(/^\D+|\D+$/g, "")).replace(/,/g, '')));
            }

            for (let trans of Object.values(values['OpenItemList'])) {
                if (trans.isSelected == true) {
                    if (trans.appliedBalCopy < 0) {
                        totalSelectedCredit += trans.appliedBalCopy;
                        if (values.ggScreenName == 'CA_ApplyCashCreditOffset_Clone') {
                            totalAppliedAmt += trans.appliedBalCopy;
                        }
                    } else {
                        totalAppliedAmt += trans.appliedBalCopy;
                        totalRemainingAmt += trans.remainingBalance;
                    }
                }
            }

            values.appliedAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalAppliedAmt.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            if (values.ggScreenName == 'CA_ApplyCashCreditOffset_Clone') {
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (values.unappliedBalance - totalAppliedAmt.toFixed(2)).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt - totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            } else if (values.ggScreenName == 'CA_NetOffset' || values.ggScreenName == 'CA_Adjustment') {
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt + totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            }

            values.creAmt = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            resolve(values);

        });
    }

    function onChangeAppliedAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            var recordList = values.transactionList;
            let unAppliedBalance = 0;
            var totalAppliedAmt = 0.0, totalRemainingAmt = 0.0, totalOverPay = 0.0, totalDeductionBal = 0.0, totalDiscount = 0.0, totalSelectedCredit = 0;
            
            if (values.includeCredit == false) {
                // =  remainingAmount
                unAppliedBalance = Number(parseFloat((values.unAppliedBalance.replace(/^\D+|\D+$/g, "")).replace(/,/g, '')));
            } else {
                // =  remainingAmount
                unAppliedBalance = Number(parseFloat((values.unAppliedBalance.replace(/^\D+|\D+$/g, "")).replace(/,/g, ''))) + Number(parseFloat((values.creAmt.replace(/^\D+|\D+$/g, "")).replace(/,/g, '')));
            }
            
            if (rowNum != null && !isNaN(rowNum)) {
                var transRecord = {};
                transRecord = recordList[rowNum];
                if (transRecord.appliedBalance > 0) {
                    transRecord.discountAmountRequested = (isNaN(transRecord.discountAmountRequested) || transRecord.discountAmountRequested == null) ? 0 : Number(transRecord.discountAmountRequested.toFixed(2));
                    transRecord.appliedBalance = (isNaN(transRecord.appliedBalance) || transRecord.appliedBalance == null) ? 0 : Number(transRecord.appliedBalance.toFixed(2));
                    transRecord.remainingBalance = (isNaN(transRecord.remainingBalance) || transRecord.remainingBalance == null) ? 0 : Number(transRecord.remainingBalance.toFixed(2));
                    transRecord.cashAppBalance = (isNaN(transRecord.cashAppBalance) || transRecord.cashAppBalance == null) ? 0 : Number(transRecord.cashAppBalance.toFixed(2));
                    
                    if ((transRecord.appliedBalance + transRecord.discountAmountRequested) > transRecord.cashAppBalance) {
                        transRecord.overPayment = Number(((transRecord.appliedBalance + transRecord.discountAmountRequested) - (transRecord.cashAppBalance )).toFixed(2));
                        transRecord.remainingBalance = 0;
                    } else {
                        transRecord.remainingBalance = Number((transRecord.cashAppBalance - (transRecord.appliedBalance + transRecord.discountAmountRequested)).toFixed(2));
                        transRecord.overPayment = 0;
                    }
                }else  if (transRecord.appliedBalance < 0) {
                    transRecord.appliedBalance = (isNaN(transRecord.appliedBalance) || transRecord.appliedBalance == null) ? 0 : Number(transRecord.appliedBalance.toFixed(2));
                    transRecord.remainingBalance = (isNaN(transRecord.remainingBalance) || transRecord.remainingBalance == null) ? 0 : Number(transRecord.remainingBalance.toFixed(2));
                    transRecord.cashAppBalance = (isNaN(transRecord.cashAppBalance) || transRecord.cashAppBalance == null) ? 0 : Number(transRecord.cashAppBalance.toFixed(2));
                    
                    if (transRecord.appliedBalance < transRecord.cashAppBalance) {
                        transRecord.overPayment = Number(((transRecord.appliedBalance) - (transRecord.cashAppBalance)).toFixed(2));
                        transRecord.remainingBalance = 0;
                    } else {
                        transRecord.remainingBalance = Number((transRecord.cashAppBalance - transRecord.appliedBalance).toFixed(2));//  Number(transRecord.cashAppBalance.toFixed(2)) - Number(transRecord.appliedBalance.toFixed(2)); 
                        transRecord.overPayment = 0;
                    }
                }
                
                for (let trans of Object.values(values['transactionList'])) {
                    if (trans.isSelected == true) {
                        if (trans.appliedBalance < 0) {
                            totalSelectedCredit += trans.appliedBalance;
                            
                            if (values.ggScreenName == 'CA_ApplyCashCreditOffset_Clone') {
                                totalAppliedAmt += trans.appliedBalance;
                            }
                        } else {
                            totalAppliedAmt += trans.appliedBalance;
                            totalRemainingAmt += trans.remainingBalance;
                            totalDeductionBal += trans.remainingBalance;
                            totalOverPay += trans.overPayment;
                            totalDiscount += trans.discountAmountRequested;
                        }
                        if(values.hasOwnProperty('originalTransactionList')){
                            values.originalTransactionList[trans.invoiceId] = trans;
                        } else {
                            values.originalTransactionList = {}
                            values.originalTransactionList[trans.invoiceId] = trans;
                        }
                    }
                }
            } else {
                for (let transRecord of Object.values(values['transactionList'])) {
                    transRecord.appliedBalance = (isNaN(transRecord.appliedBalance) || transRecord.appliedBalance == null) ? 0 : Number(transRecord.appliedBalance.toFixed(2));
                    transRecord.discountAmountRequested = (isNaN(transRecord.discountAmountRequested) || transRecord.discountAmountRequested == null) ? 0 : Number(transRecord.discountAmountRequested.toFixed(2));
                    transRecord.remainingBalance = (isNaN(transRecord.remainingBalance) || transRecord.remainingBalance == null) ? 0 : Number(transRecord.remainingBalance.toFixed(2));
                    transRecord.cashAppBalance = (isNaN(transRecord.cashAppBalance) || transRecord.cashAppBalance == null) ? 0 : Number(transRecord.cashAppBalance.toFixed(2));

                    if ((transRecord.appliedBalance + transRecord.discountAmountRequested) > transRecord.cashAppBalance) {
                        transRecord.overPayment = Number(((transRecord.appliedBalance + transRecord.discountAmountRequested) - (transRecord.cashAppBalance )).toFixed(2));
                    } else {
                        transRecord.overPayment = 0;
                    }

                    if ((transRecord.appliedBalance + transRecord.discountAmountRequested) < transRecord.cashAppBalance) {
                        transRecord.remainingBalance = Number((transRecord.cashAppBalance - (transRecord.appliedBalance + transRecord.discountAmountRequested)).toFixed(2));
                    } else {
                        transRecord.remainingBalance = 0;
                    }
                    if(transRecord.isSelected == true){
                        if (transRecord.appliedBalance < 0) {
                            totalSelectedCredit += transRecord.appliedBalance;
                            
                            if (values.ggScreenName == 'CA_ManualApplyCashCreditOffset') {
                                totalAppliedAmt += transRecord.appliedBalance;
                            }
                        } else {
                            totalAppliedAmt += transRecord.appliedBalance;
                            totalRemainingAmt += transRecord.remainingBalance;
                            totalDeductionBal += transRecord.remainingBalance;
                            totalOverPay += transRecord.overPayment;
                            totalDiscount += transRecord.discountAmountRequested;
                        }
                    }
                    if(values.hasOwnProperty('originalTransactionList')){
                        values.originalTransactionList[transRecord.invoiceId] = transRecord;
                    } else {
                        values.originalTransactionList = {}
                        values.originalTransactionList[transRecord.invoiceId] = transRecord;
                    }
                }
            }

            values.totalOverPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalOverPay.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.totalOverPaymentVal = totalOverPay;
            values.appliedAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalAppliedAmt.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.remainingAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalRemainingAmt.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.totalDiscountAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalDiscount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            if (values.ggScreenName == 'CA_ApplyCashCreditOffset_Clone') {
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (values.unappliedBalance - totalAppliedAmt.toFixed(2)).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt - totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            } else if (values.ggScreenName == 'CA_NetOffset' || values.ggScreenName == 'CA_Adjustment') {
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt + totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            }
            values.totalDeductionBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalDeductionBal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.creAmt = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.deductionBal = totalDeductionBal;
            resolve(values);
        });
    }

    function onAddMemoRow(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            if (!rowNum) {
                values.memoList[values.memoList.length - 1].PaymentRef = values.PaymentRef;
                values.memoList[values.memoList.length - 1].reasonCode = 'Credit Memo';
            }
            resolve(values);
        });
    }

    function transferToPaymentDetail(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            var totalAppliedAmt = 0, totalRemainingBal = 0, RemainingChequeBalance = 0, totalCAbalance = 0, totalOverPayment = 0, totalDiscountAmount = 0, totalDeductionBal = 0, totalCreditAmt = 0;
            var paymentDetails = [], OpenItemList = [], originalTransactionList = {};
            if (values.OpenItemList != null && values.OpenItemList.length > 0) {
                OpenItemList = values.OpenItemList;
            } else if (values.hasOwnProperty('selectedTransList') && values.selectedTransList != null) {
                OpenItemList = values.selectedTransList;
            }
            for (var item of OpenItemList) {
                if (item.isSelected == true) {
                    item.appliedBalance = item.cashAppBalance;     //CA
                    if (values.isMultiCurrencyOrganization) {
                        if (values.PaymentBatchList) {
                            values.CurrencyCode = values.CurrencyIsoCode;

                        }
                        var conversionrate = values.conversionRatesMap[values.CurrencyCode];
                        if (item.CurrencyIsoCode == values.CurrencyCode) {
                            item.appliedBalance = parseFloat(((item.appliedBalance) - (item.discountAmountRequested)).toFixed(2));
                        } else if (item.CurrencyIsoCode != values.CurrencyCode) {
                            if (values.CurrencyCode == item.BaseCurrency) {
                                item.appliedBalance = item.cashAppBalance;  //CA
                            } else if (values.CurrencyCode != item.BaseCurrency && values.corporateCurrency == values.CurrencyCode) {
                                item.appliedBalance = Number((item.cashAppBalance / values.conversionRatesMap[item.CurrencyIsoCode]).toFixed(2));   //CA
                                item.cashAppBalance = Number((item.cashAppBalance / values.conversionRatesMap[item.CurrencyIsoCode]).toFixed(2));   //CA
                                item.discountAmountRequested = Number((item.discountAmount / values.conversionRatesMap[item.CurrencyIsoCode]).toFixed(2));
                            } else if (values.CurrencyCode != item.BaseCurrency && values.corporateCurrency != values.CurrencyCode) {
                                item.appliedBalance = Number((item.cashAppBalance * conversionrate).toFixed(2));    //CA
                                item.cashAppBalance = Number((item.cashAppBalance * conversionrate).toFixed(2));    //CA
                                item.discountAmountRequested = Number((item.discountAmount * conversionrate).toFixed(2));
                            }
                        }
                        item.appliedBalCopy = Number(item.appliedBalance.toFixed(2));
                    } else {
                        item.appliedBalance = item.cashAppBalance;  //CA
                    }
                    paymentDetails.push(item);
                }

                if (item.appliedBalance >= 0) {
                    totalAppliedAmt += item.appliedBalance;
                    totalRemainingBal += item.remainingBalance;
                    totalCAbalance += item.cashAppBalance;
                    totalOverPayment += item.overPayment;
                    totalDiscountAmount += item.discountAmount;
                    totalDeductionBal += item.remainingBalance;
                } else if (item.appliedBalance < 0) {
                    totalCreditAmt += item.appliedBalance;
                    if (values.ggScreenName == 'CA_ApplyCashCreditOffset_Clone') {
                        totalAppliedAmt += item.appliedBalance;
                    }
                }
            }

            for (let tx of values.transactionList) {
                if (tx.isSelected == false && tx.celsrm__CashApp_Balance__c == 0) {
                    originalTransactionList[tx.invoiceId] = tx;
                    paymentDetails.push(tx);
                }
            }
            values.transactionList = paymentDetails;
            values.originalTransactionList = originalTransactionList;
            values.totalOverPaymentVal = totalOverPayment;
            values.appliedAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.totalCAbalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalAppliedAmt.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.remainingAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalRemainingBal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.totalOverPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalOverPayment.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.totalDiscountAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalDiscountAmount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.totalDeductionBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalDeductionBal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.creAmt = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalCreditAmt.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';

            if (values.ggScreenName == 'CA_ApplyCashCreditOffset_Clone') {
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt - totalCreditAmt).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (values.unappliedBalance - totalAppliedAmt.toFixed(2)).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            } else if (values.ggScreenName == 'CA_NetOffset' || values.ggScreenName == 'CA_Adjustment') {
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalCreditAmt).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt + totalCreditAmt).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            }
            values.InvoiceType = 'PaymentDetail';
            if (values.BaseCurrencyCode) {
                values.isBaseCurrencyCode = values.BaseCurrencyCode;
            }
            resolve(values);
        });
    }

    function openDeductionScreenClone(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            var additionalParams = {};
            var transactionList = [];
            var referenceList = [];

            for (let trans of Object.values(values['transactionList'])) {
                if (trans.isSelected == true) {
                    if (trans.remainingBalance != 0 || trans.overPayment != 0 || ((trans.taxAmount > 0 || trans.freightAmt > 0 ||
                        trans.handlingCharge || trans.VAcharge > 0) && trans.remainingBalance == 0)) {
                        transactionList.push(trans);
                    }
                    referenceList.push(trans.trnsName);
                }
            }

            additionalParams.memoAmount = Number(values.RemainingChequeBalance.split(' : ')[1].split('</b>')[0].replace(/,/g, ''));
			additionalParams.appliedAmount = Number(values.appliedAmount.split(' : ')[1].split('</b>')[0].replace(/,/g, ''));
            if (additionalParams.memoAmount != 0 && values.PaymentBatchList) {
                additionalParams.paymentRecord = values.ChequeNo;
                additionalParams.paymentName = values.paymentName;
                additionalParams.accountId = values.accountId;
                additionalParams.accountName = values.accountName;
            } else {
                additionalParams.paymentRecord = null;
            }

            if(values.hasOwnProperty('deductionAndMemoList')){
                additionalParams.deductionAndMemoList = values.deductionAndMemoList;
                additionalParams.totalDeductionBal = values.totalDeductionBal;
                additionalParams.totalInvoiceOverPayment = values.totalInvoiceOverPayment;
            }

            additionalParams.referenceList = referenceList;
            additionalParams.transactionList = transactionList;
            additionalParams.deductionBal = values.deductionBal;
            additionalParams.CurrencyCode = values.CurrencyCode;
            additionalParams.paymentAmount = values.paymentAmount;
            let customChangeHandler = {
                "callingControlName": "createDeduction",
                "targetScreen": "CA_CreateDeductionScreen_Clone",
                "targetScreenSize": "large-width",
                "sourceControlName": "createDeduction",
                "vals": additionalParams
            };

            fireEvent(cmp.pageRef, 'openChildScreen_' + cmp.additionalAttributes.screenName + "Button Group1", customChangeHandler);
            resolve(values);
        });
    }

    function onApplyDeduction(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            var CurrencyCode = values.CurrencyCode;
            var totalDeductionbal = values.totalDeductionBal;
            var totalDeductionAmount = 0;
            for (let deductionList of Object.values(values['deductionAndMemoList'])) {
                if (!deductionList.isTax && deductionList.remainingBal && deductionList.transaction != values.paymentName) {//!deductionList.isTax && deductionList.remainingBal && deductionList.amount <= deductionList.remainingBal
                    totalDeductionAmount += parseFloat(deductionList.amount.toFixed(2));
                }
            }
            totalDeductionAmount = parseFloat(totalDeductionAmount.toFixed(2));

            if (totalDeductionAmount > totalDeductionbal) {
                values.ggErrorMessage = "You can not utilize balance more than your total Deduction Balance!!";
            } else {
                values.utilizedBalance = '<b style="color:Green"> ' + CurrencyCode + ' : ' + totalDeductionAmount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.remainingBalance = '<b style="color:Green"> ' + CurrencyCode + ' : ' + (totalDeductionbal - totalDeductionAmount).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.utilizedDeductionBalance = totalDeductionAmount;
            }

            resolve(values);
        });
    }

    function onChangeApplicationCode(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            var record = values.transactionList[rowNum];
            record.reasonCode = '';
            record.reasonCodeDescription = '';
            record.GLaccount = '';
            values.transactionList[rowNum] = record;
            resolve(values.transactionList);
        });
    }

    function oncloneDeductionRow(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            if (rowNum != undefined) {
                let deductionRecord = JSON.parse(JSON.stringify(values.deductionAndMemoList[rowNum]));
                deductionRecord.amount = 0;
                values.deductionAndMemoList.splice(rowNum + 1, 0,deductionRecord);
            }
            resolve(values);
        });
    }

    function onChangeDeductionReference(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            if (rowNum) {
                values.deductionAndMemoList[rowNum].reference = values.deductionAndMemoList[rowNum].transaction;
                if(values.deductionAndMemoList[rowNum].transaction == values.paymentName){
                    values.deductionAndMemoList[rowNum].DeductionType = 'Credit Memo';
                    values.deductionAndMemoList[rowNum].type = 'payment';
                } else {
                    values.deductionAndMemoList[rowNum].DeductionType = 'Deduction';
                    values.deductionAndMemoList[rowNum].applicationCode = '';
                    values.deductionAndMemoList[rowNum].type = 'invoice';
                }
            }
            resolve(values);
        });
    }

    function onSelectReasonCode(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        var GLAccount = values.GlAccount;
        return new Promise(function (resolve, error) {
            if (GLAccount.hasOwnProperty(values.transactionList[rowNum].reasonCode)) {
                values.transactionList[rowNum].reasonCodeDescription = GLAccount[values.transactionList[rowNum].reasonCode].celsrm__Description__c;
                values.transactionList[rowNum].GLaccount = GLAccount[values.transactionList[rowNum].reasonCode].celsrm__GL_Account__c;
            } else {
                values.transactionList[rowNum].reasonCodeDescription = '';
                values.transactionList[rowNum].GLaccount = '';
            }
            resolve(values);
        });
    }

    function onSelectDeductionType(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            if (values.deductionAndMemoList[rowNum].DeductionType) {
                values.DeductType = values.deductionAndMemoList[rowNum].DeductionType;
            }
            resolve(values);
        });
    }

    function saveDeductionScreen(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            var flag = 0;
            if (values.deductionAndMemoList.length > 0){
                for (let record of Object.values(values['deductionAndMemoList'])){
                    if (record['amount'] == 0){
                        flag = 1;
                    }
                }
            } 

            if (flag == 1){
                reject('You cannot set amount as 0.');
            }
            else {
                invoke({
                    nameSpace: '',
                    className: 'CA_ApplyCashController_Cloned',
                    functionName: 'createDeductionSave',
                    values: values
                }).then(result => {
                    
                    let valuesTOrefresh = {
                        detail: {
                            refreshParentValues: result.refreshParentValues
                        }
                    }
                    fireEvent(cmp.pageRef, 'closeScreen_CA_CreateDeductionScreen_Clone', valuesTOrefresh);
                    resolve(valuesTOrefresh);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            }
        });
    }

    function onLoadApplyCash(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            console.log('now Time start>> ' + new Date());
            setTimeout(() => {
                fireEvent(cmp.pageRef, 'loadingEffect_' + values.ggScreenName + '_transactionList', true);
                invoke({
                    nameSpace: '',
                    className: 'CA_ApplyCashController_Cloned',
                    functionName: 'getTransactions',
                    values: values
                }).then(result => {
                    console.log('now Time then>> ' + new Date());
                    resolve(result);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            }, 0);
            console.log('now Time end>> ' + new Date());
        });
    }

    function onChangeWriteoffAmountAdjust(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            var writeOff = values.WriteOff[rowNum];
            console.log('writeOff>>>' + JSON.stringify(writeOff));
            if (writeOff && writeOff != null && ((writeOff.WriteOffAmount > 0 && writeOff.WriteOffAmount > writeOff.CashAppBalance) || (writeOff.WriteOffAmount < 0 && writeOff.WriteOffAmount < writeOff.CashAppBalance )) && writeOff.isSelected == true) {
                values.ggErrorMessage = 'Write Off Amount should be less than equal to CashApp Balance';
                writeOff.isSelected = false;
            }
            var NoofSelectedTransaction = 0;
            var TotalCashAppBalance = 0;
            var TotalWriteOffAmount = 0;
            var amountCurrency = {};
            for (let woff of Object.values(values['WriteOff'])) {
                if (woff.isSelected == true) {

                    NoofSelectedTransaction = NoofSelectedTransaction + 1;
                    if (values.isMultiCurrencyOrganization) {

                        if(woff['CurrencyIsoCode'] in amountCurrency) {
							amountCurrency[ woff['CurrencyIsoCode'] ] += woff['WriteOffAmount'];
						} else {
							amountCurrency[ woff['CurrencyIsoCode'] ] = woff['WriteOffAmount'];
						}
                        TotalCashAppBalance = TotalCashAppBalance + Number(woff.CashAppBalance);
                    }
                }
            }
            values.NoofSelectedTransaction = '<b>' + NoofSelectedTransaction + '</b>';
            values.TotalCashAppBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + TotalCashAppBalance.toLocaleString() + '</b>';
            var str = '';
					for(var k in amountCurrency) {
						str +='<b style="color:Green">'+ k + ' : ' + parseFloat(amountCurrency[k]).toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,') +  '</b>'+',';
					}
					if(str != '') {
						values.TotalWriteOffAmount = str.substring(0, str.length-1);
					}
            resolve(values);
        });
    }

    function onCustomSorting(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            var sortedList = [];
            let unAppliedBalance = 0;
            var totalAppliedAmt = 0.0, totalRemainingAmt = 0.0, totalOverPay = 0.0, totalDeductionBal = 0.0 , totalDiscount = 0.0, totalSelectedCredit = 0;
            
            var originalTransactionList = Object.values(values.originalTransactionList);
            var sortedBy = values.customSorting;
            if(sortedBy == 'All' || sortedBy == null){
                sortedList = originalTransactionList;
                for(let Record of sortedList){
                    if(Record.isSelected == true){
                        values.originalTransactionList[Record.invoiceId] = Record;
                        totalAppliedAmt += Record.appliedBalance;
                        totalRemainingAmt += Record.remainingBalance;
                        totalDeductionBal += Record.remainingBalance;
                        totalOverPay += Record.overPayment;
                        totalDiscount += Record.discountAmountRequested;
                    }
                }
            } else if(sortedBy != null){
                for(let Record of originalTransactionList){
                    if(Record.isSelected == true){
                        if(sortedBy == 'Discount' && Record.discountAmountRequested > 0){
                            sortedList.push(Record);
                        } else if(sortedBy == 'ShortPay' && Record.remainingBalance != 0){
                            sortedList.push(Record);
                        } else if(sortedBy == 'OverPay' && Record.overPayment != 0){
                            sortedList.push(Record);
                        }

                        values.originalTransactionList[Record.invoiceId] = Record;
                        totalAppliedAmt += Record.appliedBalance;
                        totalRemainingAmt += Record.remainingBalance;
                        totalDeductionBal += Record.remainingBalance;
                        totalOverPay += Record.overPayment;
                        totalDiscount += Record.discountAmountRequested;
                    }
                }
                
            }
            values.transactionList = sortedList;
            values.totalOverPayment = '<b style="color:Green"> '+ values.CurrencyCode +' : ' + totalOverPay.toLocaleString(undefined, {minimumFractionDigits: 2,maximumFractionDigits: 2}) + '</b>'; 
            values.totalOverPaymentVal = totalOverPay;
            values.appliedAmount = '<b style="color:Green"> '+ values.CurrencyCode +' : ' + totalAppliedAmt.toLocaleString(undefined, {minimumFractionDigits: 2,maximumFractionDigits: 2}) + '</b>';
            values.remainingAmount = '<b style="color:Green"> '+ values.CurrencyCode +' : ' + totalRemainingAmt.toLocaleString(undefined, {minimumFractionDigits: 2,maximumFractionDigits: 2}) + '</b>';
            // if(values.isDiscount == 'true'){
                values.totalDiscountAmount = '<b style="color:Green"> '+ values.CurrencyCode +' : '+totalDiscount.toLocaleString(undefined, {minimumFractionDigits: 2,maximumFractionDigits: 2}) +'</b>';
            // }
            if(values.ggScreenName == 'CA_ApplyCashCreditOffset_Clone'){
                values.RemainingChequeBalance = '<b style="color:Green"> '+ values.CurrencyCode +' : ' + (values.PaymentBatchList[values.gogGridIndex].unappliedBalance - totalAppliedAmt.toFixed(2)).toLocaleString(undefined, {minimumFractionDigits: 2,maximumFractionDigits: 2}) + '</b>';
            } else if(values.ggScreenName == 'CA_NetOffset'){
                values.RemainingChequeBalance = '<b style="color:Green"> '+ values.CurrencyCode +' : ' + ((unAppliedBalance - totalAppliedAmt) - totalSelectedCredit.toFixed(2)).toLocaleString(undefined, {minimumFractionDigits: 2,maximumFractionDigits: 2}) + '</b>';
            }
            values.totalDeductionBalance = '<b style="color:Green"> '+ values.CurrencyCode +' : ' + totalDeductionBal.toLocaleString(undefined, {minimumFractionDigits: 2,maximumFractionDigits: 2}) + '</b>';
            values.TotalSelectedPayment = '<b style="color:Green"> '+ values.CurrencyCode +' : ' + (totalAppliedAmt - totalSelectedCredit).toLocaleString(undefined, {minimumFractionDigits: 2,maximumFractionDigits: 2}) + '</b>';
            values.creAmt = '<b style="color:Green"> '+ values.CurrencyCode +' : ' + (totalSelectedCredit).toLocaleString(undefined, {minimumFractionDigits: 2,maximumFractionDigits: 2}) + '</b>';
            values.deductionBal = totalDeductionBal;
            resolve(values);
        });
    }
	function submitPaymentReversal(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            var payLineList = [];
            for (let payLine of Object.values(values['paymentLineList'])) {
                if (payLine.isSelected) {
                    payLineList.push(payLine);
                }
            }
            if (payLineList.length > 0) {
                values.paymentLineList = payLineList;
                invoke({
                    nameSpace: '',
                    className: 'CA_PaymentReversalController',
                    functionName: 'SavePaymentReversal',
                    values: values
                }).then(result => {
                    let valuesTOrefresh = {
                        detail: {
                            refreshParentValues: result.refreshParentValues
                        }
                    }
                    fireEvent(cmp.pageRef, "onCancel_CA_PaymentBatchListScreen_PaymentBatchList", valuesTOrefresh);
                    resolve(result);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
                resolve(values);
            } else {
                values.ggErrorMessage = 'Select Payment line to reverse';
                resolve(values.ggErrorMessage);
            }
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

    function appendToPaymentDetail(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            var totalAppliedAmt = 0, totalRemainingBal = 0, RemainingChequeBalance = 0, totalCAbalance = 0, totalOverPayment = 0, totalDiscountAmount = 0, totalDeductionBal = 0, totalCreditAmt = 0;
            var paymentDetails = [], OpenItemList = [], originalTransactionList = {};
            var invoiceIdList = [];
            if (values.OpenItemList != null && values.OpenItemList.length > 0) {
                OpenItemList = values.OpenItemList;
            } else if (values.hasOwnProperty('selectedTransList') && values.selectedTransList != null) {
                OpenItemList = values.selectedTransList;
            }
            for (var item of OpenItemList) {
                if (item.isSelected == true) {
                    item.appliedBalance = item.cashAppBalance;  //CA
                    if (values.isMultiCurrencyOrganization) {
                        if (values.PaymentBatchList) {
                            values.CurrencyCode = values.CurrencyIsoCode;

                        }
                        var conversionrate = values.conversionRatesMap[values.CurrencyCode];
                        if (item.CurrencyIsoCode == values.CurrencyCode) {
                            item.appliedBalance = parseFloat(((item.appliedBalance) - (item.discountAmountRequested)).toFixed(2));
                        } else if (item.CurrencyIsoCode != values.CurrencyCode) {
                            if (values.CurrencyCode == item.BaseCurrency) {
                                item.appliedBalance = item.cashAppBalance;  //CA
                            } else if (values.CurrencyCode != item.BaseCurrency && values.corporateCurrency == values.CurrencyCode) {
                                item.appliedBalance = Number((item.cashAppBalance / values.conversionRatesMap[item.CurrencyIsoCode]).toFixed(2));   //CA
                                item.cashAppBalance = Number((item.cashAppBalance / values.conversionRatesMap[item.CurrencyIsoCode]).toFixed(2));   //CA
                                item.discountAmountRequested = Number((item.discountAmount / values.conversionRatesMap[item.CurrencyIsoCode]).toFixed(2));
                            } else if (values.CurrencyCode != item.BaseCurrency && values.corporateCurrency != values.CurrencyCode) {
                                item.appliedBalance = Number((item.cashAppBalance * conversionrate).toFixed(2));    //CA
                                item.cashAppBalance = Number((item.cashAppBalance * conversionrate).toFixed(2));    //CA
                                item.discountAmountRequested = Number((item.discountAmount * conversionrate).toFixed(2));
                            }
                        }
                        item.appliedBalCopy = Number(item.appliedBalance.toFixed(2));
                    } else {
                        item.appliedBalance = item.cashAppBalance;  //CA
                    }
                    paymentDetails.push(item);
                }

                if (item.appliedBalance >= 0) {
                    totalAppliedAmt += item.appliedBalance;
                    totalRemainingBal += item.remainingBalance;
                    totalCAbalance += item.cashAppBalance;
                    totalOverPayment += item.overPayment;
                    totalDiscountAmount += item.discountAmount;
                    totalDeductionBal += item.remainingBalance;
                } else if (item.appliedBalance < 0) {
                    totalCreditAmt += item.appliedBalance;
                    if (values.ggScreenName == 'CA_ManualApplyCashCreditOffset') {
                        totalAppliedAmt += item.appliedBalance;
                    }
                }
            }

            var selInvo = new Set()
            for (let tx of paymentDetails) {
                selInvo.add(tx.invoiceId);
            }

            for (let tx of values.transactionList) {
                if (tx.isSelected == true && !selInvo.has(tx.invoiceId)) {
                    tx.appliedBalance = tx.cashAppBalance;  //CA
                    if (values.isMultiCurrencyOrganization) {
                        if (values.PaymentBatchList) {
                            values.CurrencyCode = values.CurrencyIsoCode;

                        }
                        var conversionrate = values.conversionRatesMap[values.CurrencyCode];
                        if (tx.CurrencyIsoCode == values.CurrencyCode) {
                            tx.appliedBalance = parseFloat(((tx.appliedBalance) - (tx.discountAmountRequested)).toFixed(2));
                        } else if (tx.CurrencyIsoCode != values.CurrencyCode) {
                            if (values.CurrencyCode == tx.BaseCurrency) {
                                tx.appliedBalance = tx.cashAppBalance;  //CA
                            } else if (values.CurrencyCode != tx.BaseCurrency && values.corporateCurrency == values.CurrencyCode) {
                                tx.appliedBalance = Number((tx.cashAppBalance / values.conversionRatesMap[tx.CurrencyIsoCode]).toFixed(2));     //CA
                                tx.cashAppBalance = Number((tx.cashAppBalance / values.conversionRatesMap[tx.CurrencyIsoCode]).toFixed(2));     //CA
                                tx.discountAmountRequested = Number((tx.discountAmount / values.conversionRatesMap[tx.CurrencyIsoCode]).toFixed(2));
                            } else if (values.CurrencyCode != tx.BaseCurrency && values.corporateCurrency != values.CurrencyCode) {
                                tx.appliedBalance = Number((tx.cashAppBalance * conversionrate).toFixed(2));    //CA
                                tx.cashAppBalance = Number((tx.cashAppBalance * conversionrate).toFixed(2));    //CA
                                tx.discountAmountRequested = Number((tx.discountAmount * conversionrate).toFixed(2));
                            }
                        }
                        tx.appliedBalCopy = Number(tx.appliedBalance.toFixed(2));
                    } else {
                        tx.appliedBalance = tx.cashAppBalance;      //CA
                    }

                    originalTransactionList[tx.invoiceId] = tx;
                    paymentDetails.push(tx);

                if (tx.appliedBalance >= 0) {
                    totalAppliedAmt += tx.appliedBalance;
                    totalRemainingBal += tx.remainingBalance;
                    totalCAbalance += tx.cashAppBalance;
                    totalOverPayment += tx.overPayment;
                    totalDiscountAmount += tx.discountAmount;
                    totalDeductionBal += tx.remainingBalance;
                } else if (tx.appliedBalance < 0) {
                    totalCreditAmt += tx.appliedBalance;
                    if (values.ggScreenName == 'CA_ManualApplyCashCreditOffset') {
                        totalAppliedAmt += tx.appliedBalance;
                    }
                }
                }
            }
            values.transactionList = paymentDetails;
            values.originalTransactionList = originalTransactionList;
            values.totalOverPaymentVal = totalOverPayment;
            values.appliedAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.totalCAbalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalAppliedAmt.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.remainingAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalRemainingBal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.totalOverPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalOverPayment.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.totalDiscountAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalDiscountAmount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.totalDeductionBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalDeductionBal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.creAmt = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalCreditAmt.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';

            if (values.ggScreenName == 'CA_ManualApplyCashCreditOffset') {
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt - totalCreditAmt).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (values.unappliedBalance - totalAppliedAmt.toFixed(2)).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            } else if (values.ggScreenName == 'CA_NetOffset' || values.ggScreenName == 'CA_Adjustment') {
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalCreditAmt).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt + totalCreditAmt).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            }
            values.InvoiceType = 'PaymentDetail';
            if (values.BaseCurrencyCode) {
                values.isBaseCurrencyCode = values.BaseCurrencyCode;
            }
            resolve(values);
        });
    }

    function onCloneTransactionListRow(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            if (rowNum != undefined) {
                let transactionRecord = JSON.parse(JSON.stringify(values.transactionList[rowNum]));
                transactionRecord.amount = 0;
                values.transactionList.splice(rowNum + 1, 0,transactionRecord);
            }
            onChangeAppliedAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
            resolve(values);
        });
    }

    function viewAccountMappingAdjustment(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            
            values.gogGridIndex = rowNum;
            values.paymentTransferId = values.transactionList[rowNum].invoiceId;
            values.scrNameAdjustment = values.ggScreenName;
            let customChangeHandler = {
                "callingControlName": "AccountMap",
                "targetScreen": "CA_AccountMapping",
                "targetScreenSize": "medium-width",
                "sourceControlName": "AccountMap",
                "vals": values
            };

            if (values.ggScreenName == 'CA_Adjustment'){
                fireEvent(cmp.pageRef, 'openChildScreen_' + cmp.additionalAttributes.screenName + '_transactionList', customChangeHandler);
            } 
            resolve(values);
        });
    }
    
    exports.onCustomSorting = onCustomSorting;
    exports.onLoadApplyCash = onLoadApplyCash;
    exports.onSubmitApplyCash = onSubmitApplyCash;
    exports.onCHangeDiscountAmount = onCHangeDiscountAmount;
    exports.onSelectionChangeAmount = onSelectionChangeAmount;
    exports.onChangeCurrency = onChangeCurrency;
    exports.onSelectTransaction = onSelectTransaction;
    exports.onChangeAppliedAmount = onChangeAppliedAmount;
    exports.onChangeInvoiceType = onChangeInvoiceType;
    exports.transferToPaymentDetail = transferToPaymentDetail;
    exports.onApplyDeduction = onApplyDeduction;
    exports.onChangeApplicationCode = onChangeApplicationCode;
    exports.onChangeDeductionReference = onChangeDeductionReference;
    exports.oncloneDeductionRow = oncloneDeductionRow;
    exports.onSelectDeductionType = onSelectDeductionType;
    exports.onSelectReasonCode = onSelectReasonCode;
    exports.openDeductionScreenClone = openDeductionScreenClone;
    exports.saveDeductionScreen = saveDeductionScreen;
    exports.onConvertRate = onConvertRate;
    exports.onPageLoadInvoiceType = onPageLoadInvoiceType;
    exports.onChangeWriteoffAmountAdjust = onChangeWriteoffAmountAdjust;
	exports.submitPaymentReversal = submitPaymentReversal;
	exports.updateAllPaymentReversal = updateAllPaymentReversal;
    exports.appendToPaymentDetail = appendToPaymentDetail;
    exports.onCloneTransactionListRow = onCloneTransactionListRow;
    exports.viewAccountMappingAdjustment = viewAccountMappingAdjustment;
    
    //--- DO NOT CHANGE CODE | START ---//
    Object.defineProperty(exports, '__esModule', {
        value: true
    });
    //--- DO NOT CHANGE CODE | END ---//
})));