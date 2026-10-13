//--- DO NOT CHANGE CODE | START ---//
(function(global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
        (factory((global.gog = global.gog || {})));
}(this, (function(exports) {
    'use strict';

    var version = "1.0.0";
	//--- DO NOT CHANGE CODE | END ---//

    function onCloneTransactionListRow(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            if (rowNum != undefined) {
                let transactionRecord = JSON.parse(JSON.stringify(values.transactionList[rowNum]));
                transactionRecord.amount = 0;
                values.transactionList.splice(rowNum + 1, 0,transactionRecord);
            }
            onChangeAppliedAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
            resolve(values);
            fireEvent(cmp.pageRef, 'refreshGrid_' + values.ggScreenName + '_transactionList', rowNum);
        });
    }
	
    function onSelectTransaction(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent) {
        
        return new Promise(function (resolve, error) {
            var recordList = values.transactionList;
            if (rowNum && !rowNum.isNaN && rowNum != 'on') {//rowNum != 'on'
                if (recordList.length != rowNum && recordList[rowNum].celsrm__CashApp_Balance__c != 0) {
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
                            recordList[rowNum].appliedBalanceCopy = recordList[rowNum].appliedBalance;
                            recordList[rowNum].discountAmountRequested = recordList[rowNum].discountAmount;
                        }
                    } 
                } else {
                    if (recordList.length != rowNum) {
                        recordList[rowNum].isSelected = false;
                        cmp.dispatchEvent(new ShowToastEvent({
                            title: "Error",
                            message: "You are selecting one of the Invoice which was already Paid",
                            variant: "error",
                            mode: "dismissable"
                        }));
                    }
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
                    } else {

                    }
                }
            }
            onChangeAppliedAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);

            resolve(values);
        });
    }

    function transferToPaymentDetail(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            var inclDisc = false;
            if (confirm('Do you want to add Discount?\nIf yes, click on "Ok", otherwise click on "Cancel".')) {
                inclDisc = true;
            } else {
                inclDisc =  false;
            }
            var totalAppliedAmt = 0, totalRemainingBal = 0, RemainingChequeBalance = 0, totalCAbalance = 0, totalOverPayment = 0, totalDiscountAmount = 0, totalDeductionBal = 0, totalCreditAmt = 0;
            var paymentDetails = [], OpenItemList = [], originalTransactionList = {};
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
                            item.appliedBalance = inclDisc == true ? parseFloat(((item.appliedBalance) - (item.discountAmountRequested)).toFixed(2)) : parseFloat((item.appliedBalance).toFixed(2));
                            item.discountAmountRequested = inclDisc == true ? parseFloat((item.discountAmountRequested).toFixed(2)) : 0;
                        } else if (item.CurrencyIsoCode != values.CurrencyCode) {
                            if (values.CurrencyCode == item.BaseCurrency) {
                                item.appliedBalance = item.BaseBalance;
                            } else if (values.CurrencyCode != item.BaseCurrency && values.corporateCurrency == values.CurrencyCode) {
                                item.appliedBalance = Number((item.cashAppBalance / values.conversionRatesMap[item.CurrencyIsoCode]).toFixed(2));   //CA
                                item.cashAppBalance = Number((item.cashAppBalance / values.conversionRatesMap[item.CurrencyIsoCode]).toFixed(2));   //CA
                                item.discountAmountRequested = inclDisc == true ? Number((item.discountAmount / values.conversionRatesMap[item.CurrencyIsoCode]).toFixed(2)) : 0;
                            } else if (values.CurrencyCode != item.BaseCurrency && values.corporateCurrency != values.CurrencyCode) {
                                item.appliedBalance = Number((item.cashAppBalance * conversionrate).toFixed(2));    //CA
                                item.cashAppBalance = Number((item.cashAppBalance * conversionrate).toFixed(2));    //CA
                                item.discountAmountRequested = inclDisc == true ? Number((item.discountAmount * conversionrate).toFixed(2)) : 0;
                            }
                        }
                        item.appliedBalCopy = Number(item.appliedBalance.toFixed(2));
                    } else {
                        item.appliedBalance = inclDisc == true ? parseFloat(((item.appliedBalance) - (item.discountAmountRequested)).toFixed(2)) : parseFloat((item.appliedBalance).toFixed(2));
                        item.discountAmountRequested = inclDisc == true ? parseFloat((item.discountAmountRequested).toFixed(2)) : 0;
                    }
                    if(item.overPayment > 0){
                        if(Number((item.appliedBalance + item.discountAmountRequested).toFixed(2)) == item.cashAppBalance){
                            item.overPayment = 0;
                        }
                    }
                    paymentDetails.push(item);
                }

                if (item.appliedBalance >= 0) {
                    totalAppliedAmt += item.appliedBalance;
                    totalRemainingBal += item.remainingBalance;
                    totalCAbalance += item.cashAppBalance;
                    totalOverPayment += item.overPayment;
                    totalDiscountAmount += item.discountAmountRequested;
                    totalDeductionBal += item.remainingBalance;
                } else if (item.appliedBalance < 0) {
                    totalCreditAmt += item.appliedBalance;
                    if (values.ggScreenName == 'CA_ManualApplyCashCreditOffset') {
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

            if (values.ggScreenName == 'CA_ManualApplyCashCreditOffset') {
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt - totalCreditAmt).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (values.unAppliedBalanceVal - totalAppliedAmt.toFixed(2)).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
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

    function appendToPaymentDetail(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            var inclDisc = false;
            if (confirm('Do you want to add Discount?\nIf yes, click on "Ok", otherwise click on "Cancel".')) {
                inclDisc = true;
            } else {
                inclDisc =  false;
            }
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
                            item.appliedBalance = inclDisc == true ? parseFloat(((item.appliedBalance) - (item.discountAmountRequested)).toFixed(2)) : parseFloat((item.appliedBalance).toFixed(2));
                            item.discountAmountRequested = inclDisc == true ? parseFloat((item.discountAmountRequested).toFixed(2)) : 0;
                        } else if (item.CurrencyIsoCode != values.CurrencyCode) {
                            if (values.CurrencyCode == item.BaseCurrency) {
                                item.appliedBalance = item.BaseBalance;
                            } else if (values.CurrencyCode != item.BaseCurrency && values.corporateCurrency == values.CurrencyCode) {
                                item.appliedBalance = Number((item.cashAppBalance / values.conversionRatesMap[item.CurrencyIsoCode]).toFixed(2));   //CA
                                item.cashAppBalance = Number((item.cashAppBalance / values.conversionRatesMap[item.CurrencyIsoCode]).toFixed(2));   //CA
                                item.discountAmountRequested = inclDisc == true ? Number((item.discountAmount / values.conversionRatesMap[item.CurrencyIsoCode]).toFixed(2)) : 0;
                            } else if (values.CurrencyCode != item.BaseCurrency && values.corporateCurrency != values.CurrencyCode) {
                                item.appliedBalance = Number((item.cashAppBalance * conversionrate).toFixed(2));    //CA
                                item.cashAppBalance = Number((item.cashAppBalance * conversionrate).toFixed(2));    //CA
                                item.discountAmountRequested = inclDisc == true ? Number((item.discountAmount * conversionrate).toFixed(2)) : 0;
                            }
                        }
                        item.appliedBalCopy = Number(item.appliedBalance.toFixed(2));
                    } else {
                        item.appliedBalance = inclDisc == true ? parseFloat(((item.appliedBalance) - (item.discountAmountRequested)).toFixed(2)) : parseFloat((item.appliedBalance).toFixed(2));
                        item.discountAmountRequested = inclDisc == true ? parseFloat((item.discountAmountRequested).toFixed(2)) : 0;
                    }

                    if(item.overPayment > 0){
                        if(Number((item.appliedBalance + item.discountAmountRequested).toFixed(2)) == item.cashAppBalance){
                            item.overPayment = 0;
                        }
                    }
                    paymentDetails.push(item);
                }

                if (item.appliedBalance >= 0) {
                    totalAppliedAmt += item.appliedBalance;
                    totalRemainingBal += item.remainingBalance;
                    totalCAbalance += item.cashAppBalance;
                    totalOverPayment += item.overPayment;
                    totalDiscountAmount += item.discountAmountRequested;
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
                    tx.appliedBalance = tx.appliedBalance;
                    if (values.isMultiCurrencyOrganization) {
                        if (values.PaymentBatchList) {
                            values.CurrencyCode = values.CurrencyIsoCode;

                        }
                        var conversionrate = values.conversionRatesMap[values.CurrencyCode];
                        if (tx.CurrencyIsoCode == values.CurrencyCode) {
                            tx.appliedBalance = parseFloat(((tx.appliedBalance)).toFixed(2));
                        } else if (tx.CurrencyIsoCode != values.CurrencyCode) {
                            if (values.CurrencyCode == tx.BaseCurrency) {
                                tx.appliedBalance = tx.BaseBalance;
                            } else if (values.CurrencyCode != tx.BaseCurrency && values.corporateCurrency == values.CurrencyCode) {
                                tx.appliedBalance = Number((tx.cashAppBalance / values.conversionRatesMap[tx.CurrencyIsoCode]).toFixed(2));     //CA
                                tx.cashAppBalance = Number((tx.cashAppBalance / values.conversionRatesMap[tx.CurrencyIsoCode]).toFixed(2));     //CA
                                tx.discountAmountRequested = Number((tx.discountAmount / values.conversionRatesMap[tx.CurrencyIsoCode]).toFixed(2));
                            } else if (values.CurrencyCode != tx.BaseCurrency && values.corporateCurrency != values.CurrencyCode) {
                                tx.appliedBalance = Number((tx.cashAppBalance * conversionrate).toFixed(2));       //CA
                                tx.cashAppBalance = Number((tx.cashAppBalance * conversionrate).toFixed(2));       //CA
                                tx.discountAmountRequested = Number((tx.discountAmount * conversionrate).toFixed(2));
                            }
                        }
                        tx.appliedBalCopy = Number(tx.appliedBalance.toFixed(2));
                    } else {
                        tx.appliedBalCopy = Number(tx.appliedBalance.toFixed(2));     //CA
                    }
                        originalTransactionList[tx.invoiceId] = tx;
                        paymentDetails.push(tx);

                if (tx.appliedBalance >= 0) {
                    totalAppliedAmt += tx.appliedBalance;
                    totalRemainingBal += tx.remainingBalance;
                    totalCAbalance += tx.cashAppBalance;
                    totalOverPayment += tx.overPayment;
                    totalDiscountAmount += tx.discountAmountRequested;
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
                // (grid change) values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (values.PaymentBatchList[values.gogGridIndex].unappliedBalance - totalAppliedAmt.toFixed(2)).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (values.unAppliedBalanceVal - totalAppliedAmt.toFixed(2)).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
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

    function onLoadRemittanceBatch(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CA_ManualApplyCashController',
                    functionName: 'getRemittanceBatchList',
                    values: values
                }).then(result => {
                    fireEvent(cmp.pageRef, 'remittanceBatchList_' + values.ggScreenName, result.remittanceBatchList);
                    result.enableSubmitButton = true;
                    resolve(result);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
        });
    }

    function openBankRemittance(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            var rowVals = {};
            
            if (rowValue) {
                values['remitBatchId'] = rowValue.remitId;
            } else {
                values['remitBatchId'] = values.OriginalRemittanceBatchList[rowNum].remitId;
            }
            let customChangeHandler = {
                "callingControlName": "remittanceBatchList",
                "targetScreen": "CA_RemittanceBatch_BSR_List",
                "targetScreenSize": "medium-width",
                "sourceControlName": "remittanceBatchList",
                "vals": values
            };

            fireEvent(cmp.pageRef, 'openChildScreen_' + cmp.additionalAttributes.screenName + "remittanceBatchList", customChangeHandler);
            resolve(values);
        });
    }

    function onLoadRemittanceBatchBSR(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            console.log('now Time start>> ' + new Date());
            setTimeout(() => {
                fireEvent(cmp.pageRef, 'loadingEffect_' + values.ggScreenName + '_bankRemitEditList', true);
                invoke({
                    nameSpace: '',
                    className: 'CA_ManualApplyCashController',
                    functionName: 'getBankRemittanceList',
                    values: values
                }).then(result => {
                    console.log('now Time then>> ' + new Date());
                    fireEvent(cmp.pageRef, 'bankRemitEditList_' + values.ggScreenName, result.bankRemitEditList);
                    resolve(result);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            }, 0);
            console.log('now Time end>> ' + new Date());
        });
    }

    function onSubmitRemittanceBatchBSR(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            invoke({
                nameSpace: '',
                className: 'CA_ManualApplyCashController',
                functionName: 'submitBankRemittanceList',
                values: values
            }).then(result => {
                fireEvent(cmp.pageRef, "onCancel_CA_RemittanceBatchListScreen_remittanceBatchList", values);
                resolve(result);
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });
        });
    }

    function onChangeInvoiceAmountBSRList(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            var bsrList = values.bsrIdList;
            var bsrMap = {};
            if (values.hasOwnProperty('updateBSRMap')){
                bsrMap = values.updateBSRMap;
            }
            if (rowNum != null && !isNaN(rowNum)) {
                var Id = values.bankRemitEditList[rowNum].bsrId;
                bsrList.push(Id);

                var bsrValues = {};
                bsrValues['amount']= values.bankRemitEditList[rowNum].celsrm__Invoice_Paid_Amount__c;
                bsrMap[Id] = bsrValues;
            }
            values.bsrIdList = bsrList;
            values.updateBSRMap = bsrMap;
            resolve(values);
        });
    }

    function onSubmitRemittanceBatch(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent) {
        
        if (values.remittanceBatchList.length <= 0) {
            return new Promise(function (resolve, reject) {
                let resolveVal = {};
                resolveVal.errorSelectRecord = 'true';
                resolve(resolveVal);
            });
        } else {
            return new Promise(function (resolve, reject) {
                values.ggScreenName = 'CA_ManualApplyCashCreditOffset';
                invoke({
                    nameSpace: '',
                    className: 'CA_ManualApplyCashController',
                    functionName: 'submitRemittanceBatch',
                    values: values
                }).then(result => {
                    let valueToResolve = {};
                    let valuesTOrefresh = {};
                    if (result.hasOwnProperty('ggErrorMessage')) {
                        cmp.dispatchEvent(new ShowToastEvent({
                            title: "Error",
                            message: result['ggErrorMessage'],
                            variant: "error",
                            mode: "dismissable"
                        }));
                        valueToResolve = result;
                        resolve(valueToResolve);
                    } else {
                        valuesTOrefresh = {
                            detail: {
                                refreshParentValues: result.refreshParentValues
                            }
                        }
                        let returnData = {};
                        returnData.transactionList = result.transactionList;
                        fireEvent(cmp.pageRef, 'refreshValues_CA_ManualApplyCashCreditOffset', returnData);
                        fireEvent(cmp.pageRef, "onCancel_CA_ManualApplyCashCreditOffset_Button Group1", valuesTOrefresh);

                        if (result.GlAccount != null && result.GlAccount != undefined)
                            delete result.GlAccount;
                        if (result.OriginalRemittanceBatchList && result.OriginalRemittanceBatchList != undefined)
                            delete result.OriginalRemittanceBatchList;
                        if (result.PaymentBatchList && result.PaymentBatchList != undefined)
                            delete result.PaymentBatchList;
                        if (result.originalPaymentBatchList && result.originalPaymentBatchList != undefined)
                            delete result.originalPaymentBatchList;
                        resolve(result);
                    }
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            });
        }
    }

    function onSelectionChangeAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            let unAppliedBalance = 0;
            var totalAppliedAmt = 0.0, totalRemainingAmt = 0.0, totalOverPay = 0.0, totalDeductionBal = 0.0, totalDiscount = 0.0, totalSelectedCredit = 0;

            if (values.includeCredit == false) {
                unAppliedBalance = Number(parseFloat((values.unAppliedBalance.replace(/^\D+|\D+$/g, "")).replace(/,/g, '')));
            } else {
                unAppliedBalance = Number(parseFloat((values.unAppliedBalance.replace(/^\D+|\D+$/g, "")).replace(/,/g, ''))) + Number(parseFloat(((values.creAmt == null ? '<b style="color:Green"> USD : 0.00</b>' : values.creAmt).replace(/^\D+|\D+$/g, "")).replace(/,/g, '')));
            }

            for (let trans of Object.values(values['OpenItemList'])) {
                if (trans.isSelected == true) {
                    if (trans.appliedBalCopy < 0) {
                        totalSelectedCredit += trans.appliedBalCopy;
                        if (values.ggScreenName == 'CA_ManualApplyCashCreditOffset') {
                            totalAppliedAmt += trans.appliedBalCopy;
                        }
                    } else {
                        totalAppliedAmt += trans.appliedBalCopy;
                        totalRemainingAmt += trans.remainingBalance;
                        totalDiscount += trans.discountAmount;
                    }
                }
            }

            values.appliedAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalAppliedAmt.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            if (values.ggScreenName == 'CA_ManualApplyCashCreditOffset') {
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (values.unAppliedBalanceVal - totalAppliedAmt.toFixed(2)).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt - totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.totalDiscountAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalDiscount).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            } else if (values.ggScreenName == 'CA_NetOffset' || values.ggScreenName == 'CA_Adjustment') {
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt + totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            }

            values.creAmt = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            resolve(values);

        });
    }

    function onChangeInvoiceType(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        if (values.InvoiceType == 'OpenItem') { 
            var screenName = values['ggScreenName'];
            return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CA_ManualApplyCashController',
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
        } else {
            return new Promise(function (resolve, error) {
                if(values.transactionList.length > 0){
                    resolve(values);
                } else {
                    resolve({});
                }
            });
        }
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
            values.totalDiscountAmount = '<b style="color:Green"> '+ values.CurrencyCode +' : '+totalDiscount.toLocaleString(undefined, {minimumFractionDigits: 2,maximumFractionDigits: 2}) +'</b>';
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
                }
                trans.appliedBalCopy = Number(trans.appliedBalance.toFixed(2));
                trans.discountAmountRequested = trans.discountAmount;
            }
            onChangeAppliedAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
            resolve(values);
        });
    }

    function onExport(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        return new Promise(function (resolve, error) {
            
            var csvStringResult, counter, keys, columnDivider, lineDivider;
            var paymentHeader = ['Payment #', 'Amount', 'Deposit Date', 'Lock Box #', 'Payment Batch #', 'Payment Status', 'Applied Amount', 'Unapplied Balance', 'Payment Posted Date', 'Remaining Payment Balance', 'Selected Balance', 'Discount Amount'];
            var paymentKey = ['paymentName', 'amount', 'depositDate', 'lockBoxNo', 'ChequeBatch', 'paymentStatus', 'appliedAmt', 'unAppliedBalance', 'paymentPostedDate', 'RemainingChequeBalance', 'appliedAmount', 'totalDiscountAmount'];
            var header = ['Invoice', 'Reference', 'Account', 'Account_Number', 'Balance', 'DiscountAmountRequested', 'AppliedBalance', 'Application_Code', 'Reason_Code', 'Short Pay', 'Over Pay', 'InvoiceDate'];
            keys = ['invoice', 'invoiceName', 'accountName', 'AccountNumber', 'balance', 'discountAmountRequested', 'appliedBalance', 'applicationCode', 'reasonCode', 'remainingBalance', 'overPayment', 'createdDate'];
            columnDivider = ',';
            lineDivider = '\n';
            csvStringResult = '';
            if(values.hasOwnProperty('Account')){
                csvStringResult += ('Account' + ':' + columnDivider);
                csvStringResult += '"' + values['Account'].replace(/<a[^>]*>|<\/a>/g, "") + '"';
                csvStringResult += lineDivider;
            }
            paymentHeader.forEach(function (hd, index) {
                    if(index > 0){
                        if(index%3 == 0){
                            csvStringResult += lineDivider;
                        } else {
                            csvStringResult += columnDivider;
                            csvStringResult += columnDivider;
                        }
                    }
                    csvStringResult += (hd + ':' + columnDivider);
                    if(values.hasOwnProperty(paymentKey[index])){
                        if(paymentKey[index] == 'RemainingChequeBalance' || paymentKey[index] == 'appliedAmount' || paymentKey[index] == 'totalDiscountAmount'){
                            var headerValue = values[paymentKey[index]].replaceAll(',', '');
                            var temp = headerValue.replace(/<b[^>]*>|<\/b>/g, "");
                            csvStringResult += ('"' + temp.substring(1) + '"');
                        } else if (paymentKey[index] == 'amount' || paymentKey[index] == 'appliedAmt' || paymentKey[index] == 'unAppliedBalance' ){
                            var headerValue = values[paymentKey[index]].replaceAll(',', '');
                            csvStringResult += '"' + headerValue + '"';
                        } else if (paymentKey[index] == 'paymentPostedDate'){
                            if(values[paymentKey[index]] == null || values[paymentKey[index]] == undefined){
                                csvStringResult += '"' + '"';
                            } else {
                                csvStringResult += '"' + values[paymentKey[index]] + '"';
                            }
                        }
                        else {
                            csvStringResult += '"' + values[paymentKey[index]] + '"';
                        }
                    }
              });
              csvStringResult += lineDivider;
              csvStringResult += lineDivider;
            csvStringResult += header.join(columnDivider);
            csvStringResult += lineDivider;
            var objectRecords = values['transactionList'];
            
            if (objectRecords.length > 0) {
                for (var i = 0; i < objectRecords.length; i++) {
                    counter = 0;
                    for (var sTempkey in keys) {
                        var skey = keys[sTempkey];
                        if (counter > 0) {
                            csvStringResult += columnDivider;
                        }
                        if (objectRecords[i][skey] != undefined) {
                            if (skey == 'accountName' || skey == 'invoice') {
                                csvStringResult += '"' + objectRecords[i][skey].replace(/<a[^>]*>|<\/a>/g, "") + '"';
                            } else {
                                csvStringResult += '"' + objectRecords[i][skey] + '"';
                            }
                        } else {
                            csvStringResult += "";
                        }
                        counter++;
                    } // inner for loop close 
                    csvStringResult += lineDivider;
                    // }
                }
            }// outer main for loop close 
            
            var hiddenElement = document.createElement('a');
            // hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvStringResult);
            const encodedURI = encodeURI(csvStringResult);
            const fixedEncodedURI = encodedURI.replaceAll('#', '%23');
            hiddenElement.href = 'data:text/csv;charset=utf-8,' + fixedEncodedURI;
            hiddenElement.target = '_self'; // 
            hiddenElement.download = 'TransactionsData.csv';  // CSV file Name* you can change it.[only name not .csv] 
            document.body.appendChild(hiddenElement); // Required for FireFox browser
            hiddenElement.click();
            resolve({});
        });
    }

    function navigateToFile(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            var rowVals = {};
            if (rowValue) {
                rowVals = rowValue;
            } else {
                rowVals = values;
            }
            var urlParams = '';
            if (rowVals) {
                urlParams += 'c__paymentId=' + rowVals.PaymentId;
                urlParams += '&c__acc=' + rowVals.accountId;
                urlParams += '&c__paymentKey=' + rowVals.paymentKey;
                if (rowVals.contentDocId) {
                    urlParams += '&c__Doc=' + rowVals.contentDocId;
                }
                if (values.paymentType == 'OFFSET') {
                    urlParams += '&c__chequeNo=' + rowVals.paymentName + '/offset';
                } else if(values.paymentType == 'Write Off'){
                    urlParams += '&c__chequeNo=' + rowVals.paymentName + '/adjust';
                } else if(rowVals.LockBox == 'ACH'){
                    urlParams += '&c__chequeNo=' + rowVals.paymentName + '/ACH';
                } else {
                    urlParams += '&c__chequeNo=' + rowVals.paymentName;
                }
            }
            window.open('/lightning/cmp/c__CA_RemittanceViewer?' + urlParams, '_blank', "width=1200,height=600,modal=yes,alwaysRaised=yes");
            resolve({});
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

    function onChangePaymentSelection(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        if (values.ggScreenName == "CA_NetOffset" || values.ggScreenName == 'CA_Adjustment') {
            return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CA_NetOffsetController',
                    functionName: 'selectInvoiceBasedOnMatch',
                    values: values
                }).then(result => {
                    fireEvent(cmp.pageRef, 'OpenItemList_' + cmp.additionalAttributes.screenName, result.paymentDetailList);
                    resolve(result);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            });
        } else if (values.ggScreenName == "CA_ManualApplyCashCreditOffset") {
            return new Promise(function (resolve, reject) {
                invoke({
                    nameSpace: '',
                    className: 'CA_ManualApplyCashController',
                    functionName: 'selectInvoiceBasedOnPay',
                    values: values
                }).then(result => {
                    fireEvent(cmp.pageRef, 'OpenItemList_' + cmp.additionalAttributes.screenName, result.paymentDetailList);
                    resolve(result);
                }).catch(error => {
                    console.log('error :' + error.body.message);
                    reject(error);
                });
            });
        }
    }

    function onSelectOldestMatch(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            values.MatchOption = 'oldestMatch';
            onChangePaymentSelection(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
            resolve(values);
        });
    }

    function onSelectClosestMatch(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            values.MatchOption = 'closestMatch';
            onChangePaymentSelection(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
            resolve(values);
        });
    }

    function onSelectPromisedMatch(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            values.MatchOption = 'promiseMatch';
            onChangePaymentSelection(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
            resolve(values);
        });
    }

    function onSelectIncludeFamily(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            values.MatchOption = 'includeFamily';
            onChangePaymentSelection(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
            resolve(values);
        });
    }

    function onAppliedFilter(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        if (values['SearchNumber'] == null || values['SearchNumber'] == ''){
            return new Promise(function (resolve, reject) {
                let resolveVal = {};
                resolveVal.errorSearchValue = 'true';
                resolve(resolveVal);
            });
        } else {
            if (values['SearchNumber'].trim()) {
                var Searchtext = values['SearchNumber'];
                values.Searchtext = values['SearchNumber'].trim().replaceAll('\n', ' OR ').replaceAll('-', '\\-');
                return new Promise(function (resolve, reject) {
                    invoke({
                        nameSpace: '',
                        className: 'CA_ManualApplyCashController',
                        functionName: 'selectInvoiceBasedOnApplyFilter',
                        values: values
                    }).then(result => {
                        if (values['ggScreenName'] == 'CA_IC_Payment'){
                            resolve({ 'transactionList': result.paymentDetailList });
                        } else {
                            fireEvent(cmp.pageRef, 'OpenItemList_' + cmp.additionalAttributes.screenName, result.paymentDetailList);
                            values.isParentChildSearch = false;
                            resolve({ 'OpenItemList': result.paymentDetailList });
                        }
                    }).catch(error => {
                        console.log('error :' + error.body.message);
                        reject(error);
                    });
                });
            } else {
                return new Promise(function (resolve, reject) {
                    invoke({
                        nameSpace: '',
                        className: 'CA_ManualApplyCashController',
                        functionName: 'getOpenItems',
                        values: values
                    }).then(result => {
                        resolve(result);
                        fireEvent(cmp.pageRef, 'OpenItemList_' + cmp.additionalAttributes.screenName, result.OpenItemList);
                        resolve({ 'OpenItemList': result.OpenItemList });
                    }).catch(error => {
                        console.log('error :' + error.body.message);
                        reject(error);
                    });
                });
            }
        }
    }

    function onAppliedFilterForParentChild(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            if (values['SearchNumber'] == null || values['SearchNumber'] == ''){
                let resolveVal = {};
                resolveVal.errorSearchValue = 'true';
                resolve(resolveVal);
            } else {
                values.isParentChildSearch = true;
                onAppliedFilter(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
                values.isParentChildSearch = false;
                resolve(values);
            }
        });
    }

    function onSubmitApplyCash(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent) {
        
		 var RemainingbalAmt = Number(values.RemainingChequeBalance.split(' : ')[1].split('</b>')[0].replace(/,/g, ''));
            let isEmptyApplicationCode = false;
            if(values.transactionList.length > 0){
                for (let trans of Object.values(values['transactionList'])){
                    if (trans.isSelected == true && trans.applicationCode == '') {
                        isEmptyApplicationCode = true;
                    }
                }
            }

            if (isEmptyApplicationCode == false){
                return new Promise(function (resolve, reject) {
                    invoke({
                        nameSpace: '',
                        className: 'CA_ManualApplyCashController',
                        functionName: 'ManualApplyCash',
                        values: values
                    }).then(result => {
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
            } else {
                return new Promise(function (resolve, error) {
                    let resolveVals = {};
                    resolveVals.errorSelectAppCode = "true";
                    resolve(resolveVals);
                });
                
            }
    }

    function onCHangeDiscountAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            values.transactionList[rowNum].appliedBalance = parseFloat((values.transactionList[rowNum].cashAppBalance - values.transactionList[rowNum].discountAmountRequested).toFixed(2));
            onChangeAppliedAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum);
            resolve(values);
        });
    }

    function onChangeAppliedAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        

        if (values.OriginalRemittanceBatchList != null && values.OriginalRemittanceBatchList != undefined) {
            delete values.OriginalRemittanceBatchList;
        }

        if (values.originalPaymentBatchList != null && values.originalPaymentBatchList != undefined)
            delete values.originalPaymentBatchList;
        
        return new Promise(function (resolve, reject) {
            if(values.paymentStatus == 'Applied' || values.paymentStatus == 'Auto Applied' || values.paymentStatus == 'Auto Matched'){
                resolve(values);
            } else {
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
                if (transRecord != undefined) {
                        if (transRecord.appliedBalance > 0) {
                            transRecord.discountAmountRequested = (isNaN(transRecord.discountAmountRequested) || transRecord.discountAmountRequested == null) ? 0 : Number(transRecord.discountAmountRequested.toFixed(2));
                            transRecord.appliedBalance = (isNaN(transRecord.appliedBalance) || transRecord.appliedBalance == null) ? 0 : Number(transRecord.appliedBalance.toFixed(2));
                            
                            if(transRecord.applicationCode != 'WO' && transRecord.applicationCode != '99'){
                                transRecord.remainingBalance = (isNaN(transRecord.remainingBalance) || transRecord.remainingBalance == null) ? 0 : Number(transRecord.remainingBalance.toFixed(2));
                                transRecord.cashAppBalance = (isNaN(transRecord.cashAppBalance) || transRecord.cashAppBalance == null) ? 0 : Number(transRecord.cashAppBalance.toFixed(2));
                            } else {
                                transRecord.remainingBalance = 0;
                            }
                            
                            if ((transRecord.appliedBalance + transRecord.discountAmountRequested) > transRecord.cashAppBalance) {
                                if(transRecord.applicationCode != 'WO' && transRecord.applicationCode != '99'){
                                    transRecord.overPayment = Number(((transRecord.appliedBalance + transRecord.discountAmountRequested) - (transRecord.cashAppBalance )).toFixed(2));
                                } else {
                                    transRecord.overPayment = 0;
                                }
                                transRecord.remainingBalance = 0;
                            } else {
                                if(transRecord.applicationCode != 'WO' && transRecord.applicationCode != '99'){
                                    transRecord.remainingBalance = Number((transRecord.cashAppBalance - (transRecord.appliedBalance + transRecord.discountAmountRequested)).toFixed(2));
                                } else {
                                    transRecord.remainingBalance = 0;
                                }
                                
                                transRecord.overPayment = 0;
                            }
                        }else  if (transRecord.appliedBalance < 0) {
                            transRecord.appliedBalance = (isNaN(transRecord.appliedBalance) || transRecord.appliedBalance == null) ? 0 : Number(transRecord.appliedBalance.toFixed(2));
                            if(transRecord.applicationCode != 'WO' && transRecord.applicationCode != '99'){
                                transRecord.remainingBalance = (isNaN(transRecord.remainingBalance) || transRecord.remainingBalance == null) ? 0 : Number(transRecord.remainingBalance.toFixed(2));
                            } else {
                                transRecord.remainingBalance = 0;
                            }
                            transRecord.cashAppBalance = (isNaN(transRecord.cashAppBalance) || transRecord.cashAppBalance == null) ? 0 : Number(transRecord.cashAppBalance.toFixed(2));
                            
                            if (transRecord.appliedBalance < transRecord.cashAppBalance) {
                                if(transRecord.applicationCode != 'WO' && transRecord.applicationCode != '99'){
                                    transRecord.overPayment = Number(((transRecord.appliedBalance) - (transRecord.cashAppBalance)).toFixed(2));
                                } else {
                                    transRecord.overPayment = 0;
                                }
                                transRecord.remainingBalance = 0;
                            } else {
                                if(transRecord.applicationCode != 'WO' && transRecord.applicationCode != '99'){
                                    transRecord.remainingBalance = Number((transRecord.cashAppBalance - transRecord.appliedBalance).toFixed(2));//  Number(transRecord.cashAppBalance.toFixed(2)) - Number(transRecord.appliedBalance.toFixed(2)); 
                                } else {
                                    transRecord.remainingBalance = 0;
                                }
                                transRecord.overPayment = 0;
                            }

                        }
                }
                for (let trans of Object.values(values['transactionList'])) {
                    if (trans.isSelected == true) {
                        if (trans.appliedBalance < 0) {
                            totalSelectedCredit += trans.appliedBalance;
                            
                            if (values.ggScreenName == 'CA_ManualApplyCashCreditOffset') {
                                totalAppliedAmt += trans.appliedBalance;
                            }
                        } else {
                            totalAppliedAmt += trans.appliedBalance;
                            totalRemainingAmt += trans.remainingBalance;
                            totalDeductionBal += trans.remainingBalance;
                            totalOverPay += trans.overPayment;
                            totalDiscount += trans.discountAmountRequested;
                        }
                        values.originalTransactionList[trans.invoiceId] = trans;
                    }
                }
            } else {
                for (let transRecord of Object.values(values['transactionList'])) {
                        transRecord.appliedBalance = (isNaN(transRecord.appliedBalance) || transRecord.appliedBalance == null) ? 0 : Number(transRecord.appliedBalance.toFixed(2));
                        transRecord.discountAmountRequested = (isNaN(transRecord.discountAmountRequested) || transRecord.discountAmountRequested == null) ? 0 : Number(transRecord.discountAmountRequested.toFixed(2));
                        if(transRecord.applicationCode != 'WO' && transRecord.applicationCode != '99'){
                            transRecord.remainingBalance = (isNaN(transRecord.remainingBalance) || transRecord.remainingBalance == null) ? 0 : Number(transRecord.remainingBalance.toFixed(2));
                        } else {
                            transRecord.remainingBalance = 0;
                        }
                        transRecord.cashAppBalance = (isNaN(transRecord.cashAppBalance) || transRecord.cashAppBalance == null) ? 0 : Number(transRecord.cashAppBalance.toFixed(2));
                        
                        if ((transRecord.appliedBalance + transRecord.discountAmountRequested) > transRecord.cashAppBalance) {
                            if(transRecord.applicationCode != 'WO' && transRecord.applicationCode != '99'){
                                transRecord.overPayment = Number(((transRecord.appliedBalance + transRecord.discountAmountRequested) - (transRecord.cashAppBalance )).toFixed(2));
                            } else {
                                transRecord.overPayment = 0;
                            }
                        } else {
                            transRecord.overPayment = 0;
                        }
                        if ((transRecord.appliedBalance + transRecord.discountAmountRequested) < transRecord.cashAppBalance) {
                            if(transRecord.applicationCode != 'WO' && transRecord.applicationCode != '99'){
                                transRecord.remainingBalance = Number((transRecord.cashAppBalance - (transRecord.appliedBalance + transRecord.discountAmountRequested)).toFixed(2));
                            } else {
                                transRecord.remainingBalance = 0;
                            }
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
                        values.originalTransactionList[transRecord.invoiceId] = transRecord;
                        
                }
            }

            values.totalOverPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalOverPay.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.totalOverPaymentVal = totalOverPay;
            values.appliedAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalAppliedAmt.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.remainingAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalRemainingAmt.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.totalDiscountAmount = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalDiscount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            if (values.ggScreenName == 'CA_ManualApplyCashCreditOffset') {
               
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (values.unAppliedBalanceVal - totalAppliedAmt.toFixed(2)).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt - totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            } else if (values.ggScreenName == 'CA_NetOffset' || values.ggScreenName == 'CA_Adjustment') {
                values.TotalSelectedPayment = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
                values.RemainingChequeBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalAppliedAmt + totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            }
            values.totalDeductionBalance = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + totalDeductionBal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.creAmt = '<b style="color:Green"> ' + values.CurrencyCode + ' : ' + (totalSelectedCredit).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</b>';
            values.deductionBal = totalDeductionBal;
            resolve(values);
        }
        });
    }

    function onChangeApplicationCode(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, error) {
            var record = values.transactionList[rowNum];
            record.reasonCode = '';
            record.reasonCodeDescription = '';
            record.GLaccount = '';
            values.transactionList[rowNum] = record;
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

    function savePaymentLines(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent) {
        
        //FIN-3051 - START - Changed by MM - Removed unneccesary data from value which is causing more payload
        if (values.OriginalRemittanceBatchList != null && values.OriginalRemittanceBatchList != undefined) {
            delete values.OriginalRemittanceBatchList;
        }
        //FIN-3051 - END - Changed by MM - Removed unneccesary data from value which is causing more payload
        return new Promise(function (resolve, reject) {
            invoke({
                nameSpace: '',
                className: 'CA_ManualApplyCashController',
                functionName: 'savePaymentLines',
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
                    resolve(valueToResolve);
                } else {
                    let transactionListMap = new Map();
                    transactionListMap.transactionList = result.transactionList;
                    resolve(transactionListMap);
                }
                
                        
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });
        });
        
    }

    function viewAccountMappingManualApply(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            
            values.gogGridIndex = rowNum;
            values.scrNameManualApply = values.ggScreenName;
            values.paymentTransferId = values.transactionList[rowNum].invoiceId;
            let customChangeHandler = {
                "callingControlName": "AccountMap",
                "targetScreen": "CA_AccountMapping",
                "targetScreenSize": "medium-width",
                "sourceControlName": "AccountMap",
                "vals": values
            };

            if (values.ggScreenName == 'CA_ManualApplyCashCreditOffset'){
                fireEvent(cmp.pageRef, 'openChildScreen_' + cmp.additionalAttributes.screenName + '_transactionList', customChangeHandler);
            }
            resolve(values);
        });
    }

    function onClearInSAP(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
        
        return new Promise(function (resolve, reject) {
            invoke({
                nameSpace: '',
                className: 'CA_ManualApplyCashController',
                functionName: 'clearInSAP',
                values: values
            }).then(result => {
                resolve(result);
            }).catch(error => {
                console.log('error :' + error.body.message);
                reject(error);
            });
        });
    }

    exports.onSelectTransaction = onSelectTransaction;
    exports.transferToPaymentDetail = transferToPaymentDetail;
    exports.appendToPaymentDetail = appendToPaymentDetail;
    exports.onLoadRemittanceBatch = onLoadRemittanceBatch;
    exports.openBankRemittance = openBankRemittance;
    exports.onLoadRemittanceBatchBSR = onLoadRemittanceBatchBSR;
    exports.onSubmitRemittanceBatchBSR = onSubmitRemittanceBatchBSR;
    exports.onChangeInvoiceAmountBSRList = onChangeInvoiceAmountBSRList;
    exports.onSelectionChangeAmount = onSelectionChangeAmount;
    exports.onCloneTransactionListRow = onCloneTransactionListRow;
    exports.onChangeInvoiceType = onChangeInvoiceType;
    exports.onCustomSorting = onCustomSorting;
    exports.onChangeCurrency = onChangeCurrency;
    exports.onExport = onExport;
    exports.navigateToFile = navigateToFile;
    exports.openDeductionScreenClone = openDeductionScreenClone;
    exports.onSelectOldestMatch = onSelectOldestMatch;
    exports.onSelectClosestMatch = onSelectClosestMatch;
    exports.onSelectPromisedMatch = onSelectPromisedMatch;
    exports.onSelectIncludeFamily = onSelectIncludeFamily;
    exports.onAppliedFilter = onAppliedFilter;
    exports.onAppliedFilterForParentChild = onAppliedFilterForParentChild;
    exports.onSubmitApplyCash = onSubmitApplyCash;
    exports.onSubmitRemittanceBatch = onSubmitRemittanceBatch;
    exports.onCHangeDiscountAmount = onCHangeDiscountAmount;
    exports.onChangeAppliedAmount = onChangeAppliedAmount;
    exports.onChangeApplicationCode = onChangeApplicationCode;
    exports.onSelectReasonCode = onSelectReasonCode;
    exports.savePaymentLines = savePaymentLines;
    exports.viewAccountMappingManualApply = viewAccountMappingManualApply;
    exports.onClearInSAP = onClearInSAP;

//--- DO NOT CHANGE CODE | START ---//
    Object.defineProperty(exports, '__esModule', {
        value: true
    });
//--- DO NOT CHANGE CODE | END ---//
})));