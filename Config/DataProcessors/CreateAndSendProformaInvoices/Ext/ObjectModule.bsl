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
		PeriodFrom = BegOfDay(CurrentSessionDate());
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
	// Create proforma invoices based on groups
	pmDoProcess(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Function pmDoProcess(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.CreateAndSendProformaInvoices';ru='Обработка.СозданиеИРассылкаСчетовНаОплату';de='DataProcessor.ErstellungUndVersendungVonProformaRechnungen'"), EventLogLevel.Information, Undefined, Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Print forms spreadsheet
	vSpreadsheet = New SpreadsheetDocument();
	vClear = True;
	// Some checks
	If Not ValueIsFilled(PeriodFrom) Then
		WriteLogEvent(NStr("en='DataProcessor.CreateAndSendProformaInvoices';ru='Обработка.СозданиеИРассылкаСчетовНаОплату';de='DataProcessor.ErstellungUndVersendungVonProformaRechnungen'"), EventLogLevel.Warning, Undefined, Undefined, NStr("en='Period from date is empty!';ru='Не указана дата начала периода отбора!';de='Das Datum des Zeitraumbeginns für die Auswahl von Übergabeprotokollen ist nicht angegeben!'"));
		Return vSpreadsheet;
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		WriteLogEvent(NStr("en='DataProcessor.CreateAndSendProformaInvoices';ru='Обработка.СозданиеИРассылкаСчетовНаОплату';de='DataProcessor.ErstellungUndVersendungVonProformaRechnungen'"), EventLogLevel.Warning, Undefined, Undefined, NStr("en='Period to date is empty!';ru='Не указана дата окончания периода отбора!';de='Das Datum des Zeitraumendes für die Auswahl von Übergabeprotokollen ist nicht angegeben!'"));
		Return vSpreadsheet;
	EndIf;
	// Build list of groups to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ProformaInvoices.Ref AS InvoiceRef,
	|	GuestGroups.Ref AS Ref
	|FROM
	|	Catalog.GuestGroups AS GuestGroups
	|		LEFT JOIN Document.ProformaInvoice AS ProformaInvoices
	|		ON GuestGroups.Ref = ProformaInvoices.GuestGroup
	|			AND (ProformaInvoices.Posted)
	|WHERE
	|	ProformaInvoices.Ref IS NULL
	|	AND NOT GuestGroups.DeletionMark
	|	AND GuestGroups.CheckInDate >= &qPeriodFrom
	|	AND GuestGroups.CheckInDate <= &qPeriodTo
	|	AND GuestGroups.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|	AND NOT ISNULL(GuestGroups.Customer.IsIndividual, TRUE)
	|	AND (&qCustomerIsEmpty
	|			OR NOT &qCustomerIsEmpty
	|				AND GuestGroups.Customer IN HIERARCHY (&qCustomer))
	|	AND GuestGroups.Owner = &qHotel
	|	AND (GuestGroups.ClientDoc REFS Document.Accommodation
	|			OR GuestGroups.ClientDoc REFS Document.Reservation)
	|
	|GROUP BY
	|	GuestGroups.Ref,
	|	ProformaInvoices.Ref
	|
	|ORDER BY
	|	GuestGroups.Code";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCustomerIsEmpty", NOT ValueIsFilled(Customer));
	vQry.SetParameter("qCustomer", Customer);
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vGroups = vQry.Execute().Unload();
	// Create proforma invoice for each group
	vTotalNumberOfInvoices = 0;
	For Each vGroupsRow In vGroups Do
		Try
			// Get current settlement reference
			vGroupRef = vGroupsRow.Ref;
			// Create new invoice
			vObj = Documents.ProformaInvoice.CreateDocument();
			vObj.Fill(vGroupRef.ClientDoc);
			vObj.ParentDoc = Undefined;
			vObj.Fill(vGroupRef);
			If vObj.Services.Count() = 0 Then
				Continue;	
			EndIf;
			vObj.PrintWithCompanyStamp = PrintWithCompanyStamp;
			vObj.Write(DocumentWriteMode.Posting);
			// Total
			vTotalNumberOfInvoices = vTotalNumberOfInvoices + 1;
			// Log invoice
			vMessage = NStr("de='Proforma-rechnung erstellt für gruppe: ';en='Proforma-invoice created for group: ';ru='Создан счет по группе: '") + TrimAll(vGroupRef) + " -> " + TrimAll(vObj.Ref);
			WriteLogEvent(NStr("en='DataProcessor.CreateAndSendProformaInvoices';ru='Обработка.СозданиеИРассылкаСчетовНаОплату';de='DataProcessor.ErstellungUndVersendungVonProformaRechnungen'"), EventLogLevel.Information, Undefined, Undefined, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
			EndIf;
			// Get document print form
			If ValueIsFilled(InvoicePrintForm) Then
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
					vObj.pmPrintInvoiceShort(vSpreadsheet, vObj.AccountingCustomer.Language, vSelGroupBy, InvoicePrintForm, mInvoiceNumber, vClear);
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
					vObj.pmPrintInvoiceHotelProduct(vSpreadsheet, vObj.AccountingCustomer.Language, vSelGroupBy, InvoicePrintForm, mInvoiceNumber, vClear);
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
					mInvoiceNumber = "";
					If Not vClear Then
						vSpreadsheet.PutHorizontalPageBreak();
					EndIf;
					vObj.pmPrintInvoice(vSpreadsheet, vObj.AccountingCustomer.Language, vSelGroupBy, InvoicePrintForm, mInvoiceNumber, vClear);
					vClear = False;
				EndIf;
			EndIf;
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.CreateAndSendProformaInvoices';ru='Обработка.СозданиеИРассылкаСчетовНаОплату';de='DataProcessor.ErstellungUndVersendungVonProformaRechnungen'"), EventLogLevel.Warning, Undefined, ?(vGroupRef = Undefined, Undefined, vGroupRef), vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	If ValueIsFilled(InvoicePrintForm) And vTotalNumberOfInvoices > 0 Then
		If Not IsBlankString(EMail2SendInvoices) Then
			vSubject = NStr("en='Proforma-invoices for the period from '; ru='Счета на оплату за период с '; de='Proforma-rechnungen für periode von '") + Format(PeriodFrom, "DF=dd.MM.yyyy") + NStr("en=' to '; ru=' по '; de=' zu '") + Format(PeriodTo, "DF=dd.MM.yyyy") + ?(ValueIsFilled(Customer), ", " + TrimAll(Customer), "") + ", " + TrimAll(Hotel);
			vEMailText = vSubject + Chars.LF + Chars.LF + NStr("en='Total number of proforma-invoices created: '; ru='Всего создано счетов: '; de='Insgesamt erstellt Proforma-rechnungen: '") + vTotalNumberOfInvoices;
			vFileName = "Proforma-invoices-" + ?(ValueIsFilled(Customer), StrReplace(TrimAll(Customer), " ", "-") + "-", "") + Format(PeriodFrom, "DF=yyyy-MM-dd") + ".pdf";
			vFullFileName = TempFilesDir() + vFileName;
			vSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.PDF);
			cmSendFileByEMailInBackground(vSubject, vEMailText, TrimAll(EMail2SendInvoices), vFileName, vFullFileName, SessionParameters.CurrentLanguage);
		EndIf;
	EndIf;
	WriteLogEvent(NStr("en='DataProcessor.CreateAndSendProformaInvoices';ru='Обработка.СозданиеИРассылкаСчетовНаОплату';de='DataProcessor.ErstellungUndVersendungVonProformaRechnungen'"), EventLogLevel.Information, Undefined, Undefined, vEMailText);
	Return vSpreadsheet;
EndFunction // pmDoProcess
