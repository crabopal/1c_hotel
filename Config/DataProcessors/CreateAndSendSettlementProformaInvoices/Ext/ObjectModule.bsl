// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate()) - 24*3600;
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfDay(PeriodFrom);
	EndIf;
	If Not ValueIsFilled(InvoicePrintForm) Then
		InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientRu;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Create invoice based on settlements
	pmDoProcess(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Function pmDoProcess(pIsInteractive = False) Export
	// Print forms spreadsheet
	vSpreadsheet = New SpreadsheetDocument();
	vClear = True;
	// Basic checks
	WriteLogEvent(NStr("en='DataProcessor.CreateAndSendSettlementInvoices';ru='Обработка.СозданиеИРассылкаСчетовПоАктам';de='DataProcessor.CreateAndSendSettlementInvoices'"), EventLogLevel.Information, Undefined, Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	If Not ValueIsFilled(Customer) Then
		WriteLogEvent(NStr("en='DataProcessor.CreateAndSendSettlementInvoices';ru='Обработка.СозданиеИРассылкаСчетовПоАктам';de='DataProcessor.CreateAndSendSettlementInvoices'"), EventLogLevel.Warning, Undefined, Undefined, NStr("en='Customer is empty!';ru='Не указан контрагент!';de='Der Partner ist nicht angegeben!'"));
		Return vSpreadsheet;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		WriteLogEvent(NStr("en='DataProcessor.CreateAndSendSettlementInvoices';ru='Обработка.СозданиеИРассылкаСчетовПоАктам';de='DataProcessor.CreateAndSendSettlementInvoices'"), EventLogLevel.Warning, Undefined, Undefined, NStr("en='Period from date is empty!';ru='Не указана дата начала периода отбора актов!';de='Das Datum des Zeitraumbeginns für die Auswahl von Übergabeprotokollen ist nicht angegeben!'"));
		Return vSpreadsheet;
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		WriteLogEvent(NStr("en='DataProcessor.CreateAndSendSettlementInvoices';ru='Обработка.СозданиеИРассылкаСчетовПоАктам';de='DataProcessor.CreateAndSendSettlementInvoices'"), EventLogLevel.Warning, Undefined, Undefined, NStr("en='Period to date is empty!';ru='Не указана дата окончания периода отбора актов!';de='Das Datum des Zeitraumendes für die Auswahl von Übergabeprotokollen ist nicht angegeben!'"));
		Return vSpreadsheet;
	EndIf;
	// Build list of settlements to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Settlement.Ref AS Ref,
	|	ProformaInvoice.Ref AS InvoiceRef
	|FROM
	|	Document.Settlement AS Settlement
	|		LEFT JOIN Document.ProformaInvoice AS ProformaInvoice
	|		ON Settlement.Ref = ProformaInvoice.ParentDoc
	|			AND (ProformaInvoice.Posted)
	|WHERE
	|	Settlement.Posted
	|	AND Settlement.Hotel = &qHotel
	|	AND Settlement.AccountingCustomer IN HIERARCHY(&qCustomer)
	|	AND Settlement.Date >= &qPeriodFrom
	|	AND Settlement.Date <= &qPeriodTo
	|	AND ProformaInvoice.Ref IS NULL
	|
	|GROUP BY
	|	Settlement.Ref,
	|	ProformaInvoice.Ref
	|
	|ORDER BY
	|	Settlement.Date,
	|	Settlement.PointInTime";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCustomer", Customer);
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vSettlements = vQry.Execute().Unload();
	// Create invoice for each settlement beign found
	vTotalNumberOfInvoices = 0;
	For Each vSettlementsRow In vSettlements Do
		Try
			// Get current settlement reference
			vSettlementRef = vSettlementsRow.Ref;
			// Create new invoice
			vInvoiceObj = Documents.ProformaInvoice.CreateDocument();
			vInvoiceObj.Fill(vSettlementRef);
			vInvoiceObj.PrintWithCompanyStamp = True;
			vInvoiceObj.Write(DocumentWriteMode.Posting);
			// Total
			vTotalNumberOfInvoices = vTotalNumberOfInvoices + 1;
			// Log invoice
			vMessage = NStr("de='Zum Übergabeprotokoll wurde eine Rechnung erstellt: ';en='Invoice created: ';ru='По акту создан счет-требование: '") + TrimAll(vSettlementRef) + " -> " + TrimAll(vInvoiceObj.Ref);
			WriteLogEvent(NStr("en='DataProcessor.CreateAndSendSettlementInvoices';ru='Обработка.СозданиеИРассылкаСчетовПоАктам';de='DataProcessor.CreateAndSendSettlementInvoices'"), EventLogLevel.Information, Undefined, Undefined, vMessage);
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
			// Get document print form
			If ValueIsFilled(InvoicePrintForm) And Not IsBlankString(EMail2SendInvoices) Then
				vSpreadsheet = Undefined;
				If InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupInPriceRu Or 
				   InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupInPriceEn Or
				   InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupAllRu Or
				   InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupAllEn Or
				   InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupByServiceRu Or
				   InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupByServiceEn Then
					
					// Get group by parameter
					vSelGroupBy = "";
					If InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupInPriceRu Or
					   InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupInPriceEn Then
						vSelGroupBy = "InPrice";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupAllRu Or
					      InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupAllEn Then
						vSelGroupBy = "All";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupByServiceRu Or
					      InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupByServiceEn Then
						vSelGroupBy = "ByService";
					EndIf;
					If Not IsBlankString(InvoicePrintForm.Parameter) Then
						vSelGroupBy = InvoicePrintForm.Parameter;
					EndIf;
					
					// Call invoice object procedure
					If Not vClear Then
						vSpreadsheet.PutHorizontalPageBreak();
					EndIf;
					mInvoiceNumber = "";
					vInvoiceObj.pmPrintInvoiceShort(vSpreadsheet, vInvoiceObj.AccountingCustomer.Language, vSelGroupBy, InvoicePrintForm, mInvoiceNumber);
					vClear = False;
				ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupInPriceRu Or 
				      InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupInPriceEn Or
				      InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupAllRu Or
				      InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupAllEn Or
				      InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupByServiceRu Or
				      InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupByServiceEn Then
					  
					// Get group by parameter
					vSelGroupBy = "";
					If InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupInPriceRu Or
					   InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupInPriceEn Then
						vSelGroupBy = "InPrice";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupAllRu Or
					      InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupAllEn Then
						vSelGroupBy = "All";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupByServiceRu Or
					      InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupByServiceEn Then
						vSelGroupBy = "ByService";
					EndIf;
					If Not IsBlankString(InvoicePrintForm.Parameter) Then
						vSelGroupBy = InvoicePrintForm.Parameter;
					EndIf;
					
					// Call invoice object procedure
					If Not vClear Then
						vSpreadsheet.PutHorizontalPageBreak();
					EndIf;
					mInvoiceNumber = "";
					vInvoiceObj.pmPrintInvoiceHotelProduct(vSpreadsheet, vInvoiceObj.AccountingCustomer.Language, vSelGroupBy, InvoicePrintForm, mInvoiceNumber);
					vClear = False;
				Else
					
					// Get group by parameter
					vSelGroupBy = "";
					If InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientPerDayRu Or
					   InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientPerDayEn Then
						vSelGroupBy = "InPricePerClientPerDay";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerDayRu Or
					      InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerDayEn Then
						vSelGroupBy = "InPricePerDay";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupPerClientRu Or
						  InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupPerClientEn Then
						vSelGroupBy = "PerClient";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupByServiceRu Or
						  InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupByServiceEn Then
						vSelGroupBy = "ByService";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientPerDayRu Or
						  InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientPerDayEn Then
						vSelGroupBy = "AllPerClientPerDay";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerDayRu Or
						  InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerDayEn Then
						vSelGroupBy = "AllPerDay";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientRu Or
						  InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientEn Then
						vSelGroupBy = "InPricePerClient";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPriceRu Or
						  InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPriceEn Then
						vSelGroupBy = "InPrice";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientRu Or
						  InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientEn Then
						vSelGroupBy = "AllPerClient";
					ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllRu Or
						  InvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllEn Then
						vSelGroupBy = "All";
					EndIf;
					
					// Call invoice object procedure
					If Not vClear Then
						vSpreadsheet.PutHorizontalPageBreak();
					EndIf;
					mInvoiceNumber = "";
					vInvoiceObj.pmPrintInvoice(vSpreadsheet, vInvoiceObj.AccountingCustomer.Language, vSelGroupBy, InvoicePrintForm, mInvoiceNumber);
					vClear = False;
				EndIf;
			EndIf;
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.CreateAndSendSettlementInvoices';ru='Обработка.СозданиеИРассылкаСчетовПоАктам';de='DataProcessor.CreateAndSendSettlementInvoices'"), EventLogLevel.Warning, Undefined, ?(vSettlementRef = Undefined, Undefined, vSettlementRef), vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	If ValueIsFilled(InvoicePrintForm) And vTotalNumberOfInvoices > 0 Then
		If Not IsBlankString(EMail2SendInvoices) Then
			vSubject = NStr("en='Proforma-invoices for the period from '; ru='Счета на оплату за период с '; de='Proforma-rechnungen für periode von '") + Format(PeriodFrom, "DF=dd.MM.yyyy") + NStr("en=' to '; ru=' по '; de=' bis '") + Format(PeriodTo, "DF=dd.MM.yyyy") + ?(ValueIsFilled(Customer), ", " + TrimAll(Customer), "") + ", " + TrimAll(Hotel);
			vEMailText = vSubject + Chars.LF + Chars.LF + NStr("en='Total number of proforma-invoices created: '; ru='Всего создано счетов: '; de='Insgesamt erstellt Proforma-rechnungen: '") + vTotalNumberOfInvoices;
			vFileName = "Proforma-invoices-" + ?(ValueIsFilled(Customer), StrReplace(TrimAll(Customer), " ", "-") + "-", "") + Format(PeriodFrom, "DF=yyyy-MM-dd") + ".pdf";
			vFullFileName = TempFilesDir() + vFileName;
			vSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.PDF);
			cmSendFileByEMailInBackground(vSubject, vEMailText, TrimAll(EMail2SendInvoices), vFileName, vFullFileName, SessionParameters.CurrentLanguage);
		EndIf;
	EndIf;
	WriteLogEvent(NStr("en='DataProcessor.CreateAndSendSettlementInvoices';ru='Обработка.СозданиеИРассылкаСчетовПоАктам';de='DataProcessor.CreateAndSendSettlementInvoices'"), EventLogLevel.Information, Undefined, Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
	Return vSpreadsheet;
EndFunction // pmDoProcess
