(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
		typeof define === 'function' && define.amd ? define(['exports'], factory) :
			(factory((global.gog = global.gog || {})));
}(this, (function (exports) {
	'use strict';

	var version = "1.1.0";
	var TotalBalance = 0;
	var flag = false;
	//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | Start --//
	var STATEMENT_PDF_TABLE_CHUNK_SIZE = 90000;
	//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//

	function showNoteBody(values, invoke, ds) {
		values["showNoteBody"] = "true";
		return new Promise(function (resolve, error) {
			resolve(values);
		});
	}
	function OnChangeCantactNamePhone(values, invoke, ds) {
		var contactId = values["ContactName"];

		return new Promise(function (resolve, error) {
			invoke({
				className: 'PopulateContactDetailPhone',
				functionName: 'SelectionContactDetail',
				values: values
			}).then(result1 => {
				var result = JSON.parse(JSON.stringify(result1));
				resolve(result);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}
	// generateStatement is depricated
	function generateStatement(values, invoke, ds, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent, controlName, parentControlName, ExcelJS) {
		var attId = values['AttachmentIDSendStmt'];
		var formatType = values['StatementFormat'];
		//lightning/r/ContentDocument/069a5000009Bg3ZAAS/view
		return new Promise(function (resolve, reject) {
			//-- Start | FIN-7269 | 11-April-2025 -- (Attachment Related changes)//
			if(values.hasOwnProperty('ContentDocID')) {
				debugger;
				let url = "/lightning/r/ContentDocument/"+ values['ContentDocID'] +"/view";
				window.open(url, '_blank');
				resolve({});
			//-- End | FIN-7269 | 11-April-2025 -- (Attachment Related changes)//
			} else {

			
			if (!formatType) {
				reject('Please select Statement Format');
			} else if (values['ListView'] == '') {
				resolve({});
			} else {
				if (formatType == 'PDF' && values['ContentIDSendStmt']) {
					invoke({
						className: 'SendStatementActionController',
						functionName: 'generatePublicURLforPDF',
						values: values
					}).then(result => {
						var url = result.publicURL;
						window.open(url, '_blank');
						resolve({});
					}).catch(error => {
						console.log('error :' + error);
						reject(error);
					});
				}
				else {
					values.preview = true;
					// gog.createStatementAttachment(values, invoke, ds, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent, ExcelJS).then(result1 => {
					gog.createStatementAttachment(values, invoke, ds, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent, null, null, ExcelJS).then(result1 => {
						debugger;
						var result = JSON.parse(JSON.stringify(result1));
						delete result.preview;
						attId = result['AttachmentIDSendStmt'];
						var url = "/servlet/servlet.FileDownload?file=" + attId;
						window.open(url, '_blank');
						resolve({});
					}).catch(err => {
						reject(err);
					});
				}
			}
			}
		});
	}
	//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | Start --//
	function createStatementAttachment(values, invoke, ds, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent, controlName, parentControlName, ExcelJS) {
		const formatType = values['StatementFormat'];
		return new Promise(function (resolve, reject) {
			if (!(values['AttachCheckBox'] || values.preview)) {
				resolve(values);
				return;
			}
			debugger;
			const attachmentPromise = formatType === 'PDF'
				? generatePDFAttachment(values, invoke, cmp)
				: generateExcelAttachment(values, invoke, ds, cmp, ExcelJS);

			attachmentPromise.then(resolve).catch(reject);
		});
	}
	//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//

	// onAttachFormatCompletion is depricated
	function onAttachFormatCompletion(values, invoke, ds) {
		let tempVal = { 'finalContent': values['SendStmtAttachmentContent'], 'StatementFormat': values['StatementFormat'] };
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'SendStatementAttachmentInsert',
				functionName: 'Send Statement',
				values: tempVal
			}).then(result => {
				if (result) {
					values['AttachmentIDSendStmt'] = result.AttachmentIDSendStmt;
					gog.onAttachGenerateCompletion(values, invoke, ds).then(result => {
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
	//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//

	function onAttachGenerateCompletion(values, invoke, ds, flag = false) {
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
					
					//-- Start | FIN-6913 | 17-Dec-2024 --//
					// Start || FIN-7286 || Created a new temp variable for changeListView
					let tempValOnListChange = {
						'AttachmentIDSendStmt': result.AttachmentIDSendStmt,
						'ContentIDSendStmt': result.ContentIDSendStmt,
						'SendStmtAttachmentContent': '',
						'ComposeEmail': result.ComposeEmail,
						'ContentDocID': result.ContentDocID
					};
					let tempVal = {
						'AttachmentIDSendStmt': result.AttachmentIDSendStmt,
						'ContentIDSendStmt': result.ContentIDSendStmt,
						'SendStmtAttachmentContent': '',
						// 'ComposeEmail': result.ComposeEmail,
						'ContentDocID': result.ContentDocID
					}
					let isListChanged = flag ? tempValOnListChange : tempVal;

					// values['AttachmentIDSendStmt'] = result.AttachmentIDSendStmt;
					// values['ContentIDSendStmt'] = result.ContentIDSendStmt;
					// values['SendStmtAttachmentContent'] = '';
					// values['ComposeEmail'] = result.ComposeEmail;
					// resolve(values);
					resolve(isListChanged);
					// End || FIN-7286 || Created a new temp variable for changeListView
					//-- Ends | FIN-6913 | 17-Dec-2024 --//
				}
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}
	//-- End | FIN-7269 | 11-April-2025 -- (Attachment Related changes)//

	exports.onLoadSendStatement = (values, invoke, ds, fireEvent, cmp, rowvals, NavigationMixin, ShowToastEvent, ExcelJS) => {
		debugger;
		return new Promise(function (resolve, reject) {
			if (values.AttachCheckBox) {
				gog.createStatementAttachment(values, invoke, ds, fireEvent, cmp, rowvals, NavigationMixin, null, ShowToastEvent, null, null, ExcelJS).then(result => {
					result = JSON.parse(JSON.stringify(result));
					delete result.enableSubmitButton;
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
	//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
	function removeChildAccountFromStatement(values, invoke, dataServiceObj, fireEvent, ref) {
		debugger;
		console.log('values>>>>>' + values);
		return new Promise(function (resolve, reject) {
			if (values.buttonClassListchildAccountNotes && values.buttonClassListchildAccountNotes.contains('closeChildAccount')) {
				sessionStorage.removeItem('selectedAccountIds');
				values['accountHierarchyChildIds'] = null;
				var onchangeMap = {
					"onChangeMethod": 'filterDataByView',
					"accountHierarchyChildIds": null,
					"enableChildNotes": 'false',
					"childAccountNotes": ''
				};
				fireEvent(ref.pageRef, 'refreshValues_SRMTransactionGridScreen', onchangeMap);
				var onchangeMap1 = {
					"onChangeMethod": 'filterDataByViewDispute',
					"accountHierarchyChildIds": null,
					"enableChildNotes": 'false',
					"childAccountNotes": ''
				};
				fireEvent(ref.pageRef, 'refreshValues_Disputes On Account', onchangeMap1);
				gog.changeListView(values, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
					var result = JSON.parse(JSON.stringify(result1));
					result.enableChildNotes = 'false';
					resolve(result);
				}).catch(err => {
					reject(err);
				});
			
			} else {
				resolve({});
			}
		});
	}
	//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
	//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | Start --//
	exports.changeListView = (values, invoke, ds, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent, controlName, parentControlName, ExcelJS) => {
		debugger;
		return new Promise(async function (resolve, reject) {
			if (values['ListView'] == '') {
				resolve({});
				return;
			}
			fireEvent(ref.pageRef, "loadSpinner_Send Statement", true);
			try {
				const bodyResult1 = await invoke({
					className: 'SendStatementActionController',
					functionName: 'changeListView',
					values: values
				});
				const bodyResult = JSON.parse(JSON.stringify(bodyResult1 || {}));

				if (!values['AttachCheckBox']) {
					fireEvent(ref.pageRef, "loadSpinner_Send Statement", false);
					resolve(bodyResult);
					return;
				}

				const valuesForAttachment = {
					...values,
					...bodyResult
				};
				const cleanValues = await cleanupGeneratedStatementAttachment(valuesForAttachment, invoke);
				const attachmentResult1 = await gog.createStatementAttachment(
					cleanValues,
					invoke,
					ds,
					fireEvent,
					ref,
					null,
					null,
					null,
					null,
					null,
					null,
					window.ExcelJS
				);
				const attachmentResult = JSON.parse(JSON.stringify(attachmentResult1 || {}));

				const finalResult = {
					...bodyResult,
					...attachmentResult
				};

				if (bodyResult &&
					bodyResult.hasOwnProperty("ComposeEmail") &&
					typeof bodyResult.ComposeEmail === "object" &&
					Object.keys(bodyResult.ComposeEmail).length > 0) {
					finalResult["ComposeEmail"] = bodyResult.ComposeEmail;
				}

				fireEvent(ref.pageRef, "loadSpinner_Send Statement", false);
				resolve(finalResult);
			} catch (error) {
				fireEvent(ref.pageRef, "loadSpinner_Send Statement", false);
				console.log('error :' + error);
				reject(error);
			}
		});
	}
	//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//

	
	function getAlignmentByType(type) {
		switch (type) {
			case 'currency':
			case 'number':
				return { horizontal: 'right' };

			case 'date':
				return { horizontal: 'left' };

			case 'text':
			default:
				return { horizontal: 'left' };
		}
	}

	//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | Start --//
	function changeStatementFormat(values, invoke, ds, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent, controlName, parentControlName, ExcelJS) {
		return new Promise(function (resolve, reject) {
			cleanupGeneratedStatementAttachment(values, invoke).then(cleanValues => {
				gog.createStatementAttachment(cleanValues, invoke, ds, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent, controlName, parentControlName, ExcelJS).then(resolve).catch(reject);
			}).catch(reject);
		});
	}
	
	
	const generateExcelAttachment = (values, invoke, ds, ref, ExcelJS) => {
		delete values.finalContent;
		let fileName = values['fileName'] ? values['fileName'] : 'BillingStatement';

		return new Promise(function (resolve, reject) {
			if (!values['AttachCheckBox']) {
				resolve({});
				return;
			}

			if (values['ListView'] == '') {
				resolve({});
				return;
			}

			values["finalContent"] = '';
			invoke({
				className: 'SendStatementActionController',
				functionName: 'createStatementAttachment',
				values: values
			}).then(async result1 => {
				var result = JSON.parse(JSON.stringify(result1));

				if (result.templateBody) {
					result['fontLibraryUrl'] = '/resource/FontLibrary';
					const contentHtml = await window.gog.statementUtils.getProcessedTemplateHtml(result, true, ref);
					values["finalContent"] = await window.gog.statementUtils.generateExcelFromHtml(contentHtml, fileName, ExcelJS, result);

					if (result.hasOwnProperty("ComposeEmail") && typeof result.ComposeEmail === "object" && Object.keys(result.ComposeEmail).length > 0) {
						values["ComposeEmail"] = result.ComposeEmail;
					}

					delete result['templateBodyImageBase64Map'];
					const prunedValues = { ...values };
					delete prunedValues.TransactionList;
					delete prunedValues.DueTransList;
					delete prunedValues.stmtTemplate;
					delete prunedValues.SendStmtAttachmentContent;
					delete prunedValues.ComposeEmail;

					if (values["finalContent"]) {
						invoke({
							className: 'SendStatementAttachmentInsert',
							functionName: 'Send Statement',
							values: prunedValues
						}).then(insertResult => {
							if (insertResult.AttachmentIDSendStmt) {
								values.AttachmentIDSendStmt = insertResult.AttachmentIDSendStmt;
								delete values.finalContent;
							}
							gog.onAttachGenerateCompletion(insertResult, invoke, ds, true).then(resolve).catch(reject);
						}).catch(reject);
					} else {
						resolve(result);
					}
					return;
				}

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
						type = 'text';
					}

					return {
						fieldName: field,
						label: newLstFieldsLabel[index],
						isExport: true,
						type
					};
				});

				const workbook = new ExcelJS.Workbook();
				const worksheet = workbook.addWorksheet(fileName);
				let currentRow = 1;

				if (result.hasCompanyLogo) {
					const logoUrl = '/resource/CompanyLogo';
					const response = await fetch(logoUrl);
					const blob = await response.blob();
					const logoBase64 = await blobToBase64(blob);

					const imageId = workbook.addImage({
						base64: logoBase64,
						extension: 'png'
					});

					worksheet.addImage(imageId, {
						tl: { col: 0, row: currentRow - 1 },
						ext: { width: 300, height: 100 }
					});

					currentRow += 6;
					currentRow += 1;
					worksheet.mergeCells(`A${currentRow}:H${currentRow}`);
					worksheet.getCell(`A${currentRow}`).border = {
						bottom: { style: 'thin' }
					};
					currentRow += 1;
				}

				worksheet.mergeCells(`A${currentRow}:H${currentRow}`);
				const titleCell = worksheet.getCell(`A${currentRow}`);
				titleCell.value = 'STATEMENT OF ACCOUNT';
				titleCell.font = {
					name: 'Times New Roman',
					size: 20,
					bold: true
				};
				titleCell.alignment = { horizontal: 'center' };

				currentRow++;
				worksheet.mergeCells(`A${currentRow}:H${currentRow}`);
				worksheet.getCell(`A${currentRow}`).border = {
					bottom: { style: 'thin' }
				};
				currentRow += 1;

				if (result.orgName) {
					worksheet.mergeCells(`A${currentRow}:D${currentRow}`);
					const orgCell = worksheet.getCell(`A${currentRow}`);
					orgCell.value = result.orgName;
					orgCell.font = {
						name: 'Times New Roman',
						size: 16,
						bold: true
					};
				}

				currentRow += 1;

				if (result.customerName) {
					const startCol = 6;
					let r = currentRow;
					const headerStyle = {
						font: { bold: true },
						fill: {
							type: 'pattern',
							pattern: 'solid',
							fgColor: { argb: 'DEF2F1' }
						},
						alignment: { horizontal: 'center', vertical: 'middle' },
						border: {
							top: { style: 'thin' },
							left: { style: 'thin' },
							bottom: { style: 'thin' },
							right: { style: 'thin' }
						}
					};
					const valueStyle = {
						font: { bold: true },
						alignment: { horizontal: 'center', vertical: 'middle' },
						border: {
							top: { style: 'thin' },
							left: { style: 'thin' },
							bottom: { style: 'thin' },
							right: { style: 'thin' }
						}
					};
					const summaryData = [
						['Customer Name :', result.customerName || ''],
						['Customer Number :', result.customerNumber || ''],
						['Statement Date :', result.statementDate || '']
					];

					summaryData.forEach(([label, value]) => {
						worksheet.mergeCells(r, startCol, r, startCol + 1);
						worksheet.getCell(r, startCol).value = label;
						Object.assign(worksheet.getCell(r, startCol), headerStyle);
						r++;
						worksheet.mergeCells(r, startCol, r, startCol + 1);
						worksheet.getCell(r, startCol).value = value;
						Object.assign(worksheet.getCell(r, startCol), valueStyle);
						r++;
					});

					currentRow = r + 1;
				}

				const headerRow = worksheet.getRow(currentRow);
				headerRow.values = newLstFieldsLabel;
				headerRow.eachCell((cell) => {
					cell.font = { bold: true };
					cell.border = {
						top: { style: 'thin' },
						left: { style: 'thin' },
						bottom: { style: 'thin' },
						right: { style: 'thin' }
					};
					cell.alignment = { horizontal: 'center', vertical: 'middle' };
				});

				worksheet.columns = newLstFields.map(field => ({ key: field, width: 20 }));

				let totalMap = {};
				data.forEach((record) => {
					const row = worksheet.getRow(++currentRow);

					newLstFields.forEach((fieldName, colIndex) => {
						let value = record[fieldName] || '';
						const cell = row.getCell(colIndex + 1);
						cell.value = value;

						const columnDef = columns.find(c => c.fieldName === fieldName);
						cell.alignment = getAlignmentByType(columnDef?.type);

						if (columns.find(c => c.fieldName === fieldName || c.name === fieldName)?.type === 'currency') {
							const currencyCode = record['CurrencyIsoCode'];
							if (currencyCode) {
								const currencySymbol = getCurrencySymbol(currencyCode);
								row.getCell(colIndex + 1).numFmt = '[$' + currencySymbol + '] #,##0.00';
								if (fieldName?.toLowerCase().endsWith('celsrm__balance__c')) {
									if (totalMap[currencyCode]) {
										totalMap[currencyCode] = totalMap[currencyCode] + parseFloat(value);
									} else {
										totalMap[currencyCode] = parseFloat(value);
									}
								}
							}
						}
					});

					row.eachCell((cell) => {
						cell.border = {
							top: { style: 'thin' },
							left: { style: 'thin' },
							bottom: { style: 'thin' },
							right: { style: 'thin' }
						};
					});
				});

				++currentRow;
				if (Object.keys(totalMap).length > 0) {
					let recordCounter = data.length + 2;
					for (const [currencyCode, totalValue] of Object.entries(totalMap)) {
						const rowCounter = recordCounter++;
						const totalRow = worksheet.getRow(currentRow++);
						const currencySymbol = getCurrencySymbol(currencyCode);
						const totalAmountColumnIndex = columns.length;
						totalRow.getCell(totalAmountColumnIndex - 1).value = 'Total (' + currencySymbol + ')';
						totalRow.getCell(totalAmountColumnIndex - 1).alignment = { horizontal: 'right' };

						worksheet.mergeCells({
							top: currentRow,
							left: 1,
							bottom: rowCounter,
							right: columns.length - 1
						});

						if (totalAmountColumnIndex > 0) {
							totalRow.getCell(totalAmountColumnIndex).value = totalValue;
							totalRow.getCell(totalAmountColumnIndex).numFmt = '[$' + getCurrencySymbol(currencyCode) + '] #,##0.00';
						}

						totalRow.eachCell((cell) => {
							cell.font = { bold: true };
							cell.border = {
								top: { style: 'thin' },
								left: { style: 'thin' },
								bottom: { style: 'thin' },
								right: { style: 'thin' }
							};
						});
					}
				}

				const buffer = await workbook.xlsx.writeBuffer();
				var temp = await bufferToBase64(buffer, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
				values["finalContent"] = temp;

				if (result.hasOwnProperty("ComposeEmail") &&
					typeof result.ComposeEmail === "object" &&
					Object.keys(result.ComposeEmail).length > 0) {
					values["ComposeEmail"] = result.ComposeEmail;
				}

				invoke({
					className: 'SendStatementAttachmentInsert',
					functionName: 'Send Statement',
					values: values
				}).then(result => {
					debugger;
					gog.onAttachGenerateCompletion(result, invoke, ds).then(result => {
						resolve(result);
						delete values.finalContent;
					}).catch(err => {
						reject(err);
					});
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
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
			const chunkResult = JSON.parse(JSON.stringify(chunkResult1));
			if (chunkResult && chunkResult.ggErrorMessage) {
				throw chunkResult.ggErrorMessage;
			}
			statementTableHtmlKey = chunkResult.statementTableHtmlKey || statementTableHtmlKey;
		}

		return statementTableHtmlKey;
	}

	const generatePDFAttachment = (values, invoke, ref) => {
		debugger;
		let requestValues = { ...values };
		requestValues.StatementFormat = 'PDF';
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

				const tableHtml = await window.gog.statementUtils.buildStatementTableHtml(pdfDataResult, true, ref);
				if (tableHtml) {
					statementTableHtmlKey = await uploadStatementPDFTableHTML(tableHtml, requestValues, invoke);
					requestValues.statementTableHtmlKey = statementTableHtmlKey;
				}

				const result1 = await invoke({
					className: 'SendStatementActionController',
					functionName: 'generatePDFAttachment',
					values: requestValues
				});
				const result = JSON.parse(JSON.stringify(result1));
				if (result && result.ggErrorMessage) {
					reject(result.ggErrorMessage);
					return;
				}
				resolve(result);
			} catch (error) {
				await cleanupStatementPdfTempChunks(statementTableHtmlKey, invoke);
				console.log('error :' + error);
				reject(error);
			}
		});
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

	
	// Set this method on click of Preview button on screen //
	exports.generateAttachmentPreview = (values, invoke, ds, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent, controlName, parentControlName, ExcelJS) => {
		var formatType = values['StatementFormat'];
		return new Promise(function (resolve, reject) {
			if (values.hasOwnProperty('ContentDocID')) {
				debugger;
				let url = "/lightning/r/ContentDocument/" + values['ContentDocID'] + "/view";
				window.open(url, '_blank');
				resolve({});
			} else {
				gog.showToast("Error", "Attachment copy is not available for preview.", "error", "dismissable", cmp, ShowToastEvent);
				resolve({});
			}
		});
	}

	//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//
	// Helper: Blob → Base64
	function blobToBase64(blob) {
		return new Promise((resolve, reject) => {
			const reader = new FileReader();
			reader.onloadend = () => resolve(reader.result);
			reader.onerror = reject;
			reader.readAsDataURL(blob);
		});
	}
	//-- Start | FIN-7269 | 11-April-2025 -- (Attachment Related changes)//
	const getCurrencySymbol = (currencyKey) => {
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
	//-- End | FIN-7269 | 11-April-2025 -- (Attachment Related changes)//


	function onSubmitEmail(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function (resolve, error) {
			fireEvent(cmp.pageRef, 'refreshActivity_ComposeMailFromAnonomusActivity_Activity');
			resolve(values);
		});
	}

	function noteChange(values, invoke, dataServiceObj, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		return new Promise(function (resolve, reject) {
			if (values["buttonClassListremoveTreatmentNotes"] && values["buttonClassListremoveTreatmentNotes"].contains("removeTreatment")) {
				values.hideTreatmentNotes = "false";
				values.treatmentButtonName = "";
				delete values["buttonClassListremoveTreatmentNotes"];
				resolve(values);
			} if (values["buttonClassListtreatmentNotes"] && values["buttonClassListtreatmentNotes"].contains("oninclude")) {
				values.hideTreatmentNotes = "true";
				values.treatmentButtonName = "Include";
				// ref.dispatchEvent(new ShowToastEvent({
				// 	title: "Error",
				// 	message: "click yes",
				// 	variant: "error",
				// 	mode: "dismissable"
				// }));
				delete values["buttonClassListtreatmentNotes"];
				resolve(values);
			} else if (values["buttonClassListtreatmentNotes"] && values["buttonClassListtreatmentNotes"].contains("onno")) {
				values.hideTreatmentNotes = "true";
				values.treatmentButtonName = "No";
				// ref.dispatchEvent(new ShowToastEvent({
				// 	title: "Error",
				// 	message: "click no",
				// 	variant: "error",
				// 	mode: "dismissable"
				// }));
				delete values["buttonClassListtreatmentNotes"];
				resolve(values);
			} else {
				resolve(values);
			}
		});
	}

	function showFollowUpDays(values, invoke, ds) {
		return new Promise(function (resolve, reject) {
			try {
				let returnVal = {};
				if (values.isFollowUp) {
					returnVal.FollowUpDate = new Date(new Date().getTime() + (5 * 24 * 60 * 60 * 1000));
				}
				resolve(returnVal);
			} catch (error) {
				console.log('error :' + error);
				reject(error);
			}
		});
	}

	function showToast(stTitle, stMessage, stVariant, stMode, stDispatchFunction, ShowToastEvent) {
		stDispatchFunction.dispatchEvent(new ShowToastEvent({
			title: stTitle,
			message: stMessage,
			variant: stVariant,
			mode: stMode
		}));
	};

	function onSubmitSendStatement(values, invoke, ds) {
		return new Promise(function (resolve, reject) {
			//-- Start | FIN-7319 | Changed by Ravi | 16-Jun-2026 --//
			let message = {};
			message.repharseSummary = true;
			message.isUser = false;
			message.hasError = false;
			message.errorMessage = '';
			message.resultSummary = 'We send a statement as requested.';
			// << START - MM - FIN-10142 - Account -> Send Statement -> fire event undefined error on Send Statement submit >>
			let screenName = values['ggScreenName'];
			if(screenName && screenName == 'ActivityForMyEmailsTab') {
				fireEvent(ref.pageRef, 'All Incoming Emails_SummaryAgent_ActivityForMyEmailsTab', message);
			}
			// << END - MM - FIN-10142 - Account -> Send Statement -> fire event undefined error on Send Statement submit >>
			//-- End | FIN-7319 | Changed by Ravi | 16-Jun-2026 --//
			//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | Start --//
			if (
				(values['ContentIDSendStmt'] && values['ContentIDSendStmt'] != null) ||
				(values['AttachmentIDSendStmt'] && values['AttachmentIDSendStmt'] != null)
			) {
			//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//
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

	function OnChangeViewCreate(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		debugger;
		var ListViewName = values["ListView"];
		return new Promise(function (resolve, error) {
			// window.location.reload(true); send setament 
			if (!values['ListViewEditMode'] && values['selectedListViewOption']) {
				fireEvent(cmp.pageRef, 'addPicklistOption_Send Statement_ListView', values['selectedListViewOption']);
			}
			if (ListViewName != '') {
				gog.changeListView(values, invoke, dataServiceObj);
			}
			resolve(values);
		});
	}

	function bufferToBase64(buffer,mimeType) {
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

	// << Start - ND - FIN-8132 - Email Templates based on Account Locale >>
	// << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Renamed fucntion from onChangeCompanyCode -> onChangeAccountLocale>>
	function onChangeAccountLocale(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		debugger;
		return new Promise(function (resolve, reject) {
			if (values['accountLocale'] && values['accountLocale'] != null) {
				invoke({
					className: 'SendStatementActionController',
					functionName: 'updateAccountLocale',
					values: values
				}).then(result => {
					fireEvent(cmp.pageRef, 'ComposeEmail__'+ cmp.additionalAttributes.screenName, result.accountLocale);
					resolve(result);
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			} else {
				resolve({});
			}
			// fireEvent(cmp.pageRef, 'ComposeEmail__'+ cmp.additionalAttributes.screenName, values.CompanyCode);
			// resolve(values);
		});
	}
	// << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Renamed fucntion from onChangeCompanyCode -> onChangeAccountLocale>>
	
	exports.onChangeAccountLocale = onChangeAccountLocale;
	// << End - ND - FIN-8132 - Email Templates based on Account Locale >>
	//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
	exports.removeChildAccountFromStatement = removeChildAccountFromStatement;
	//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
	exports.noteChange = noteChange;
	exports.onSubmitEmail = onSubmitEmail;
	exports.changeStatementFormat = changeStatementFormat;
	exports.OnChangeCantactNamePhone = OnChangeCantactNamePhone;
	exports.createStatementAttachment = createStatementAttachment;
	exports.showNoteBody = showNoteBody;
	exports.generateStatement = generateStatement;
	exports.onAttachFormatCompletion = onAttachFormatCompletion;
	exports.onAttachGenerateCompletion = onAttachGenerateCompletion;
	// exports.displayDefaultView = displayDefaultView;

	exports.showFollowUpDays = showFollowUpDays;
	exports.showToast = showToast;
	exports.onSubmitSendStatement = onSubmitSendStatement;
	exports.OnChangeViewCreate = OnChangeViewCreate;
	//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | Start --//
	//exports.generateExcelAttachment = generateExcelAttachment;
	//-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//


	Object.defineProperty(exports, '__esModule', {
		value: true
	});

})));
