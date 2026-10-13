//--- DO NOT CHANGE CODE | START ---//
(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
		typeof define === 'function' && define.amd ? define(['exports'], factory) :
			(factory((global.gog = global.gog || {})));
}(this, (function (exports) {
	'use strict';

	var version = "1.0.0";
	var STATEMENT_PDF_TABLE_CHUNK_SIZE = 90000;
	//--- DO NOT CHANGE CODE | END ---//	

	//-- This method is related to Send Email action --//
	exports.handleTreatmentNotes = (values, invoke, dataServiceObj, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent) => {
		return new Promise(function (resolve, reject) {
			if (values["buttonClassListremoveTreatmentNotes"] && values["buttonClassListremoveTreatmentNotes"].contains("removeTreatment")) {
				values.hideTreatmentNotes = "false";
				values.treatmentButtonName = "";
				delete values["buttonClassListremoveTreatmentNotes"];
				resolve(values);
			} if (values["buttonClassListtreatmentNotes"] && values["buttonClassListtreatmentNotes"].contains("oninclude")) {
				values.hideTreatmentNotes = "true";
				values.treatmentButtonName = "Include";

				delete values["buttonClassListtreatmentNotes"];
				resolve(values);
			} else if (values["buttonClassListtreatmentNotes"] && values["buttonClassListtreatmentNotes"].contains("onno")) {
				values.hideTreatmentNotes = "true";
				values.treatmentButtonName = "No";
				delete values["buttonClassListtreatmentNotes"];
				resolve(values);
			} else {
				resolve(values);
			}
		});
	}

	exports.generateAttachment = (values, invoke, ds, fireEvent, cmp) => {
	//-- End | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//
		return new Promise(function (resolve, reject) {
			
			if (!values['AttachCheckBox']) {
				resolve(values);
				return;
			}
			if (values['StatementFormat'] == null || values['StatementFormat'] == "") {
				values['StatementFormat'] = 'PDF'
			}

			cleanupGeneratedStatementAttachment(values, invoke).then(cleanValues => {
				let attachmentPromise;
				if (cleanValues['StatementFormat'] == 'PDF') {
					attachmentPromise = generatePDFAttachment(cleanValues, invoke, cmp);
				} else {
					attachmentPromise = generateExcelAttachmentForAccountDetail(cleanValues, invoke, ds, fireEvent, cmp);
				}

				attachmentPromise.then(result1 => {
					var result = JSON.parse(JSON.stringify(result1 || {}));
					delete result.enableSubmitButton;
					delete result.preview;
					resolve(result);
				}).catch(err => {
					reject(err);
				});
			}).catch(reject);
		});
	}

	exports.generateAttachmentPreview = (values, invoke, ds, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent, controlName, parentControlName, ExcelJS) => {
		return new Promise(function (resolve, reject) {
			if (values.hasOwnProperty('ContentDocID')) {
				debugger;
				let url = "/lightning/r/ContentDocument/" + values['ContentDocID'] + "/view";
				window.open(url, '_blank');
				resolve({});
			} else {
				showToast("Error", "Attachment copy is not available for preview.", "error", "dismissable", cmp, ShowToastEvent);
				resolve({});
			}
		});
	}

	exports.onSubmitSendEmail = (values, invoke, ds) => {
		return new Promise(function (resolve, reject) {
			if (values['ContentIDSendStmt'] && values['ContentIDSendStmt'] != null) {
				invoke({
					className: 'SendStatementActionController',
					functionName: 'deleteAttachmentAfterSendStatement',
					values: values
				}).then(result => {
					resolve(result);
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			} else {
				resolve({});
			}

		});
	}
	// << START - MM - FIN-10130 | Send Email -> On Load -> Generate attachment >> 
	exports.onLoadSendEmail = (values, invoke, ds, fireEvent, cmp, rowvals, NavigationMixin, ShowToastEvent, ExcelJS) => {
		debugger;
		return new Promise(function (resolve, reject) {
			if (values.AttachCheckBox) {
				gog.generateAttachment(values, invoke, ds, fireEvent, cmp, rowvals, NavigationMixin, null, ShowToastEvent, null, null, ExcelJS).then(result => {
					result = JSON.parse(JSON.stringify(result));
					delete result.enableSubmitButton;
					delete result.ComposeEmail;
					resolve(result);
				}).catch(err => {
					reject(err);
				});
				// }
			} else {
				resolve({});
			}
		});
	}
	// << END - MM - FIN-10130 | Send Email -> On Load -> Generate attachment >> 

	const generatePDFAttachment = (values, invoke, cmp) => {
		let requestValues = { ...values };
		requestValues.StatementFormat = 'PDF';
		requestValues.preview = true;
		delete requestValues.finalContent;

		return new Promise(async function (resolve, reject) {
			let statementTableHtmlKey = null;
			if (requestValues['ListView'] == '') {
				resolve({});
				return;
			}
			try {
				let pdfDataResult = await invoke({
					className: 'SendStatementActionController',
					functionName: 'preparePDFAttachmentData',
					values: requestValues
				});
				pdfDataResult = { ...pdfDataResult };
				if (pdfDataResult && pdfDataResult.ggErrorMessage) {
					reject(pdfDataResult.ggErrorMessage);
					return;
				}

				const tableHtml = await window.gog.statementUtils.buildStatementTableHtml(pdfDataResult, true, cmp);
				if (tableHtml) {
					statementTableHtmlKey = await uploadStatementPDFTableHTML(tableHtml, requestValues, invoke);
					requestValues.statementTableHtmlKey = statementTableHtmlKey;
				}

				const result1 = await invoke({
					className: 'SendStatementActionController',
					functionName: 'generatePDFAttachment',
					values: requestValues
				});
				const result = JSON.parse(JSON.stringify(result1 || {}));
				if (result && result.ggErrorMessage) {
					reject(result.ggErrorMessage);
					return;
				}
				resolve({ ...requestValues, ...result });
			} catch (error) {
				await cleanupStatementPdfTempChunks(statementTableHtmlKey, invoke);
				console.log('error :' + error);
				reject(error);
			}
		});
	}

	const generateExcelAttachmentForAccountDetail = (values, invoke, ds, fireEvent, cmp) => {
		const requestValues = { ...values };
		if (!requestValues.accountLocale && requestValues.accountLanguageCode) {
			requestValues.accountLocale = requestValues.accountLanguageCode;
		}
		requestValues.preview = true;
		return createStatementAttachmentOnPreview(requestValues, invoke, ds, fireEvent, cmp);
	}

	const uploadStatementPDFTableHTML = async (tableHtml, requestValues, invoke) => {
		if (!tableHtml) {
			return null;
		}

		const uploadToken = 'stmtpdf_' + Date.now() + '_' + Math.random().toString(36).substring(2, 10);
		let statementTableHtmlKey = null;

		for (let startIndex = 0, chunkIndex = 0; startIndex < tableHtml.length; startIndex += STATEMENT_PDF_TABLE_CHUNK_SIZE, chunkIndex++) {
			const htmlChunk = tableHtml.substring(startIndex, Math.min(startIndex + STATEMENT_PDF_TABLE_CHUNK_SIZE, tableHtml.length));
			const chunkResult1 = await invoke({
				className: 'SendStatementActionController',
				functionName: 'saveStatementPdfTableHtmlChunk',
				values: {
					...requestValues,
					uploadToken: uploadToken,
					chunkIndex: chunkIndex,
					htmlChunk: htmlChunk
				}
			});
			const chunkResult = JSON.parse(JSON.stringify(chunkResult1 || {}));
			if (chunkResult && chunkResult.ggErrorMessage) {
				throw chunkResult.ggErrorMessage;
			}
			statementTableHtmlKey = chunkResult.statementTableHtmlKey || statementTableHtmlKey;
		}

		return statementTableHtmlKey;
	}

	const cleanupStatementPdfTempChunks = async (tempKeyPrefix, invoke) => {
		if (!tempKeyPrefix) {
			return;
		}

		try {
			await invoke({
				className: 'SendStatementActionController',
				functionName: 'deleteStatementPdfTempChunks',
				values: {
					tempKeyPrefix: tempKeyPrefix
				}
			});
		} catch (cleanupError) {
			console.log('statement pdf temp cleanup error :' + cleanupError);
		}
	}

	const cleanupGeneratedStatementAttachment = (values, invoke) => {
		return new Promise(function (resolve, reject) {
			const hasGeneratedAttachment = (values['ContentIDSendStmt'] && values['ContentIDSendStmt'] != null) ||
				(values['AttachmentIDSendStmt'] && values['AttachmentIDSendStmt'] != null);
			if (!hasGeneratedAttachment) {
				resolve(values);
				return;
			}
			invoke({
				className: 'SendStatementActionController',
				functionName: 'deleteAttachmentAfterSendStatement',
				values: values
			}).then(result => {
				const mergedValues = { ...values, ...(result || {}) };
				delete mergedValues.ContentIDSendStmt;
				delete mergedValues.ContentDocID;
				delete mergedValues.AttachmentIDSendStmt;
				resolve(mergedValues);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}

	const createStatementAttachmentOnPreview = (values, invoke, ds, fireEvent, cmp) => {
		//-- End | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//	
		debugger;
		if (!values.accountLocale && values.accountLanguageCode) {
			values.accountLocale = values.accountLanguageCode;
		}
		var arr = values['TransactionList'];
		var trxnId = '';
		var formatType = values['StatementFormat'] ? values['StatementFormat'] : 'PDF'; //FIN-9048 | Chanegs by Asera 02-Feb-2026
		let fileName = values['fileName'] ? values['fileName'] : 'BillingStatement';
		return new Promise(function (resolve, reject) {
			if (!formatType) {
				reject('Please select Statement Format');
			} else {
				if (arr && arr.length > 0) {
					for (var i = 0; i < arr.length; i++) {
						if (i == arr.length - 1) {
							trxnId += arr[i].Id;
						} else {
							trxnId += arr[i].Id + ',';
						}
					}
				}
				values.trxnId = trxnId;
				
				invoke({
					className: 'SendStatementOnAccount',
					functionName: 'contactCustomerPreview',
					values: values
				}).then(async result1 => {
					var result = JSON.parse(JSON.stringify(result1));
					if (result) {
						//-- Start | FIN-9543 | Changes by Dhwanil | 06-Arl-2026 --//
						result['fontLibraryUrl'] = '/resource/FontLibrary';
						//-- ends | FIN-9543 | Changes by Dhwanil | 06-Arl-2026 --//
						//-- Start | FIN-9048 | Chanegs by Asera 02-Feb-2026--//
						if (result.templateBody) {
							//-- Start | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//
							const contentHtml = await window.gog.statementUtils.getProcessedTemplateHtml(result, true, cmp);
							//-- End | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//
							if (formatType == "Excel") {
								values["SendStmtAttachmentContent"] = await window.gog.statementUtils.generateExcelFromHtml(contentHtml, fileName, ExcelJS, result);
							} else if (formatType == "PDF") {
								//-- Start | FIN-9410 | Changed by Ravi | 16-Mar-2026 --//
								values["SendStmtAttachmentContent"] = await window.gog.statementUtils.generatePdfFromHtml(contentHtml, window, result, 'landscape');
								//-- End | FIN-9410 | Changed by Ravi | 16-Mar-2026 --//
							}
							delete result['templateBodyImageBase64Map']; // FIN-9351
						}
						//-- End | FIN-9048 | Chanegs by Asera 02-Feb-2026--//
						//-- Start | FIN-7812 | Changed By Ravi | 14 July 2025 --//
						else if (formatType != "Excel") {
							if (!window.jspdf) {
								console.error('jsPDF not loaded');
								return;
							}

							// Landscape to match wide tables
							const doc = window.jspdf.jsPDF({
								orientation: 'l',   // 'p' = portrait, 'l' = landscape
								unit: 'pt',         // 'pt', 'mm', 'cm', 'in'
								format: 'a4',       // 'a4', 'letter', [210, 297]
								compress: true,     // enable internal PDF compression
								precision: 2        // reduce float precision (smaller size)
							});

							let y = 40; // starting vertical position

							// Add Company Logo if exists
							if (result.hasCompanyLogo) {
								const logoUrl = '/resource/CompanyLogo'; // static resource
								const response = await fetch(logoUrl);
								const blob = await response.blob();
								const base64 = await blobToBase64(blob);

								doc.addImage(base64, 'PNG', 40, y, 100, 50); // x, y, width, height
								y += 60; // space after logo

								doc.setDrawColor(0);       // black line
								doc.setLineWidth(0.5);     // thin line
								doc.line(40, y, 800, y);
								y += 20;
							}

							// Add Title
							doc.setFontSize(20);
							doc.setFont('Times New Roman', 'bold');
							doc.text('STATEMENT OF ACCOUNT', 50, y);
							y += 10;

							doc.setDrawColor(0);       // black line
							doc.setLineWidth(0.5);     // thin line
							doc.line(40, y, 590, y);
							y += 20;

							if (result.orgName) {
								// Organization Name
								doc.setFontSize(16);
								doc.text(result.orgName, 50, y);
								y += 20;
							}
							//-- Start | FIN-9250 | Chanegs by Asera 18-Feb-2026--//
							const LOCAL = (result.LOCALE || 'en-US').replace('_', '-');;
							//-- Ends | FIN-9250 | Chanegs by Asera 18-Feb-2026--//
							if (result.customerName) {
								y -= 60;
								const summaryStartX = 600;   // right side position
								const summaryStartY = y;     // current Y
								const boxWidth = 180;

								const headerStyle = {
									fillColor: [222, 242, 241], // light teal
									fontStyle: 'bold'
								};

								const valueStyle = {
									fillColor: [255, 255, 255],
									fontStyle: 'bold'
								};
								//--Start | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
								doc.autoTable({
									startY: summaryStartY,
									margin: { left: summaryStartX },
									tableWidth: boxWidth,
									body: [
										[{ content: 'Customer Name : ', styles: headerStyle }],
										[{ content: result.customerName || '', styles: valueStyle }],
										[{ content: 'Customer Number : ', styles: headerStyle }],
										[{ content: result.customerNumber || '', styles: valueStyle }],
										[{ content: 'Statement Date : ', styles: headerStyle }],
										[{ content: new Intl.DateTimeFormat(LOCAL).format(new Date(result.statementDate)) || '', styles: valueStyle }]
									],
									theme: 'grid',
									styles: {
										font: 'Time new roman',
										fontSize: 12,
										halign: 'center',
										valign: 'middle',
										lineWidth: 0.8,
										lineColor: [0, 0, 0]
									}
								});
								//--Ends | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
								// move y below the table
								y = doc.lastAutoTable.finalY + 20;
							}

							let startY = y;

							const data = result.DueTransList;
							const newLstFields = result.selectedFields;
							const newLstFieldsLabel = result.selectedFieldsLabel;
							let fieldTypeMap = result.selectedFieldTypes;

							if (typeof result.selectedFieldTypes === 'string') {
								fieldTypeMap = JSON.parse(result.selectedFieldTypes);
							}

							//-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
							const attachmentFontFamily = result['attachmentFontFamily'] || 'Times New Roman';
							const attachmentFontSize = (result['attachmentFontSize'] || '9') + 'px';
							//-- End | FIN-9543 | Changed by Dhwanil | 06-Apr-2026 --//
							/* ===============================
							COLUMN METADATA
							=============================== */
							const columns = newLstFields.map((field, index) => {
								const typeFromApex = fieldTypeMap?.[field];

								let type = 'text';

								if (typeFromApex === 'currency' || typeFromApex === 'double' || typeFromApex === 'decimal') {
									type = 'currency';
								} else if (typeFromApex === 'number' || typeFromApex === 'integer') {
									type = 'number';
								} else if (typeFromApex === 'date' || typeFromApex === 'datetime') {
									type = 'date';
								}

								return {
									fieldName: field,
									label: newLstFieldsLabel[index],
									isExport: true,
									type
								};
							});

							/* ===============================
							TABLE HEADER
							=============================== */
							const head = [newLstFieldsLabel];

							/* ===============================
							TABLE BODY + TOTALS
							=============================== */
							const body = [];
							const totalMap = {};

							data.forEach(record => {
								const row = [];

								newLstFields.forEach(fieldName => {
									let value = record[fieldName] ?? '';

									const colDef = columns.find(c => c.fieldName === fieldName);

									if (colDef?.type === 'currency') {
										const currencyCode = record.CurrencyIsoCode;
										const amount = parseFloat(value) || 0;

										if (currencyCode) {
											const symbol = getCurrencySymbol(currencyCode);
											value = `${symbol} ${amount.toFixed(2)}`;

											if (fieldName?.toLowerCase().endsWith('balance__c')) {
												totalMap[currencyCode] =
													(totalMap[currencyCode] || 0) + amount;
											}
										}
									}
									else if (colDef?.type === 'date') {
										//--Start | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
										value = value ? new Intl.DateTimeFormat(LOCAL).format(new Date(value)) : '';
										//--Ends | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
									}

									row.push(value);
								});

								body.push(row);
							});

							/* ===============================
							MAIN TABLE
							=============================== */
							doc.autoTable({
								startY,
								head,
								body,
								theme: 'grid',
								styles: {
									font: attachmentFontFamily,
									fontSize: attachmentFontSize,
									cellPadding: 4,
									valign: 'middle',
									lineWidth: 0.8,
									lineColor: [0, 0, 0]
								},
								headStyles: {
									halign: 'center',
									font: attachmentFontFamily,
									fontStyle: 'bold',
									fillColor: [222, 242, 241],
									textColor: [0, 0, 0],
									lineWidth: 0.8,
									lineColor: [0, 0, 0]
								},
								bodyStyles: {
									lineWidth: 0.3
								},
								columnStyles: columns.reduce((acc, col, idx) => {
									if (col.type === 'currency' || col.type === 'number') {
										acc[idx] = { halign: 'right' };
									}
									return acc;
								}, {}),
								showHead: 'everyPage',
								pageBreak: 'auto'
							});

							/* ===============================
							TOTAL ROWS (POST TABLE)
							=============================== */
							y = doc.lastAutoTable.finalY + 20;
							doc.setFont('Times New Roman', 'bold');
							doc.setFontSize(10);

							Object.entries(totalMap).forEach(([currencyCode, totalValue]) => {
								const symbol = getCurrencySymbol(currencyCode);
								doc.text(
									`Total (${symbol}) : ${totalValue.toFixed(2)}`,
									doc.internal.pageSize.getWidth() - 220,
									y
								);
								y += 14;
							});

							/* ===============================
							BASE64 OUTPUT FOR APEX
							=============================== */
							//const pdfBase64 = doc.output('datauristring').split(',')[1];
							//values['SendStmtAttachmentContent'] = pdfBase64;
							const buffer = doc.output('arraybuffer');
							values['SendStmtAttachmentContent'] = await bufferToBase64(buffer, 'application/pdf');
						} else if (formatType == "Excel") {
							const data = result.DueTransList;
							const newLstFields = result.selectedFields;
							const newLstFieldsLabel = result.selectedFieldsLabel;
							let fieldTypeMap = result.selectedFieldTypes;

							if (typeof result.selectedFieldTypes === 'string') {
								fieldTypeMap = JSON.parse(result.selectedFieldTypes);
							}

							const columns = newLstFields.map((field, index) => {
								const apexType = fieldTypeMap?.[field];

								let type = 'text';

								if (apexType === 'currency') {
									type = 'currency';
								} else if (apexType === 'number') {
									type = 'number';
								} else if (apexType === 'date') {
									type = 'date';
								} else if (apexType === 'link') {
									type = 'text'; // ExcelJS does not support hyperlink formatting here
								}

								return {
									fieldName: field,
									label: newLstFieldsLabel[index],
									isExport: true,
									type
								};
							});

							const workbook = new ExcelJS.Workbook();
							//-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
							const worksheet = workbook.addWorksheet(fileName);
							//-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
							// Format header row
							const headerRow = worksheet.getRow(1);
							headerRow.values = newLstFieldsLabel;

							headerRow.eachCell((cell) => {
								//-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
								cell.font = { bold: true };
								cell.border = {
									top: { style: 'thin' },
									left: { style: 'thin' },
									bottom: { style: 'thin' },
									right: { style: 'thin' }
								}
								// cell.fill = {
								// 	type: 'pattern',
								// 	pattern: 'solid',
								// 	fgColor: { argb: '000000' } // Black background color
								// };
								//-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
							});

							// Define columns using newLstFields
							worksheet.columns = newLstFields.map(field => ({ key: field, width: 20 }));

							// Add data rows starting from the 2nd row
							let totalMap = {}; // FIN-8285 | Changed by Asera | 23-Oct-2025 --//
							data.forEach((record, index) => {
								const row = worksheet.getRow(2 + index);

								newLstFields.forEach((fieldName, colIndex) => {
									let value = record[fieldName] || '';
									row.getCell(colIndex + 1).value = value;
									//-- Start | FIN-8285 | Changed by Asera | 23-Oct-2025 --//
									// Apply currency formatting if needed
									// if (columns.find(c => c.fieldName === fieldName || c.name === fieldName)?.type === 'currency') {
									// 	const currencyCode = record['CurrencyIsoCode'] || additionalAttributes.currencyCode;
									// 	if (currencyCode) {
									// 		const currencySymbol = getCurrencySymbol(currencyCode);
									// 		row.getCell(colIndex + 1).numFmt = `${currencySymbol} #,##0.00`;
									// 	}
									// }
									if (columns.find(c => c.fieldName === fieldName || c.name === fieldName)?.type === 'currency') {
										const currencyCode = record['CurrencyIsoCode'];
										if (currencyCode) {
											const currencySymbol = getCurrencySymbol(currencyCode);
											row.getCell(colIndex + 1).numFmt = '[$' + currencySymbol + '] #,##0.00';
											if (fieldName?.toLowerCase().endsWith('balance__c')) {
												if (totalMap[currencyCode]) {
													totalMap[currencyCode] = totalMap[currencyCode] + parseFloat(value);
												} else {
													totalMap[currencyCode] = parseFloat(value);
												}
											}

										}
									}
									//-- End | FIN-8285 | Changed by Asera | 23-Oct-2025 --//
								});

								// Apply borders after all cells are populated
								row.eachCell((cell) => {
									cell.border = {
										top: { style: 'thin' },
										left: { style: 'thin' },
										bottom: { style: 'thin' },
										right: { style: 'thin' }
									}
								});
							});
							//-- Start | FIN-8285 | Changed by Asera | 23-Oct-2025 --//
							// Write the workbook to a binary string
							// Add total rows for each currency in totalMap
							if (Object.keys(totalMap).length > 0) {
								let recordCounter = data.length + 2;
								for (const [currencyCode, totalValue] of Object.entries(totalMap)) {
									const rowCounter = recordCounter++;
									const totalRow = worksheet.getRow(rowCounter);
									const currencySymbol = getCurrencySymbol(currencyCode);
									// Set the total title in the first cell
									totalRow.getCell(1).value = 'Total (' + currencySymbol + ')';
									totalRow.getCell(1).alignment = { horizontal: 'right' };

									worksheet.mergeCells({
										top: rowCounter,
										left: 1,
										bottom: rowCounter,
										right: columns.length - 1
									});


									// Set the total value in the aggregation column
									const totalAmountColumnIndex = columns.length;
									if (totalAmountColumnIndex > 0) {
										totalRow.getCell(totalAmountColumnIndex).value = totalValue;
										totalRow.getCell(totalAmountColumnIndex).numFmt = '[$' + getCurrencySymbol(currencyCode) + '] #,##0.00';

									}
									// Style the total row
									totalRow.eachCell((cell) => {
										cell.font = { bold: true };
										cell.border = {
											top: { style: 'thin' },
											left: { style: 'thin' },
											bottom: { style: 'thin' },
											right: { style: 'thin' }
										}
									});
								}
							}
							//-- End | FIN-8285 | Changed by Asera | 23-Oct-2025 --//
							const buffer = await workbook.xlsx.writeBuffer();
							// var temp = window.btoa(String.fromCharCode(...new Uint8Array(buffer)));
							var temp = await bufferToBase64(buffer, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
							values['SendStmtAttachmentContent'] = temp;
							delete result.DueTransList;
							delete result.selectedFields;
							delete result.selectedFieldsLabel;
							delete result.TransIds;
							delete result.returnTemplateAmount;
						}
						//-- Start | FIN-7812 | Changed By Ravi | 14 July 2025 --//
						onAttachFormatCompletion(values, invoke, ds).then(result => {
							resolve(result);
						}).catch(err => {
							reject(err);
						});
					}

				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			}
		});
	}

	// Helper: Blob → Base64
	const blobToBase64 = (blob) => {
		return new Promise((resolve, reject) => {
			const reader = new FileReader();
			reader.onloadend = () => resolve(reader.result);
			reader.onerror = reject;
			reader.readAsDataURL(blob);
		});
	}

	const onAttachFormatCompletion = (values, invoke, ds) => {
		let tempVal = {
			'finalContent': values['SendStmtAttachmentContent'],
			'StatementFormat': values['StatementFormat'],
			'AttachmentIDSendStmt': values['AttachmentIDSendStmt']
		};
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'SendStatementAttachmentInsert',
				functionName: 'Send Statement',
				values: tempVal
			}).then(result => {
				if (result) {
					values['AttachmentIDSendStmt'] = result.AttachmentIDSendStmt;
					onAttachGenerateCompletion(values, invoke, ds).then(result => {
						resolve(result);
					}).catch(err => {
						reject(err);
					});
				}
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}

	const onAttachGenerateCompletion = (values, invoke, ds) => {
		let tempVal = {
			'AttachmentIDSendStmt': values['AttachmentIDSendStmt'],
			'StatementFormat': values['StatementFormat'],
			'ComposeEmail': values['ComposeEmail'],
			'ContentIDSendStmt': values['ContentIDSendStmt'],
			//-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
			'fileName': values['fileName']
			//-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
		};
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'SendStatementAttachmentformation',
				functionName: 'Send Statement',
				values: tempVal
			}).then(result => {
				if (result) {
					values['AttachmentIDSendStmt'] = result.AttachmentIDSendStmt;
					values['ContentIDSendStmt'] = result.ContentIDSendStmt;
					values['SendStmtAttachmentContent'] = '';
					values['ContentDocID'] = result.ContentDocID;
					//values['ComposeEmail'] = result.ComposeEmail;
					resolve(values);
				}
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}

	const showToast = (stTitle, stMessage, stVariant, stMode, stDispatchFunction, ShowToastEvent) => {
		stDispatchFunction.dispatchEvent(new ShowToastEvent({
			title: stTitle,
			message: stMessage,
			variant: stVariant,
			mode: stMode
		}));
	};

	const getCurrencySymbol = (currencyKey) => {
		if (currencyKey == 'INR') {
			return 'INR';
		}
		else {
			return (0).toLocaleString(
				'en-US',
				{
					style: 'currency',
					currency: currencyKey,
					minimumFractionDigits: 0,
					maximumFractionDigits: 0,
				}
			).replace(/[0-9\u0660-\u0669]/g, '').trim()
		}
	}

	const bufferToBase64 = (buffer, mimeType) => {
		return new Promise((resolve, reject) => {
			const blob = new Blob([buffer], { type: mimeType });
			const reader = new FileReader();
			reader.onload = function () {
				const dataUrl = reader.result;
				const base64 = dataUrl.split(',')[1]; // Remove the data URL header
				resolve(base64);
			};
			reader.onerror = reject;
			reader.readAsDataURL(blob);
		});
	}

	//--- DO NOT CHANGE CODE | START ---//
	Object.defineProperty(exports, '__esModule', {
		value: true
	});
	//--- DO NOT CHANGE CODE | END ---//

})));
