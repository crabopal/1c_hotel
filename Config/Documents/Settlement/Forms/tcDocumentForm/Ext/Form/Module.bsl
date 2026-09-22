
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	OldStateObject = Undefined;
	
	// Save current user
	CurrentUser = SessionParameters.CurrentUser;
	
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;

	// Check edit prohibited date
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(Object.Hotel.EditProhibitedDate) And 
			BegOfDay(Object.Hotel.EditProhibitedDate) >= BegOfDay(Object.Date) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.Company) Then
		If ValueIsFilled(Object.Company.EditProhibitedDate) And 
			BegOfDay(Object.Company.EditProhibitedDate) >= BegOfDay(Object.Date) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	If Object.Posted Then
		vHasRightsToEditInvoice = cmHasRightsToEditInvoice(Object.Company, Object.Date, Object.ExternalCode);
		If Not vHasRightsToEditInvoice Then
			ReadOnly = True;
		EndIf;  
	EndIf;
	If ReadOnly Then
		Items.ServicesRecalculateServices.Visible = False;
		Items.ServicesRecalculateServices.Enabled = False;
		Items.PaymentDocumentsRecalculatePayments.Visible = False;
		Items.PaymentDocumentsRecalculatePayments.Enabled = False;
		Items.FormSetDeletionMarkAction.Visible = False;
		Items.FormSetDeletionMarkAction.Enabled = False;
		Items.FormUndoPosting.Visible = False;
		Items.FormUndoPosting.Enabled = False;  
		If Items.Find("FormPost") <> Undefined Then
			Items.FormPost.Visible = False;
			Items.FormPost.Enabled = False;       
		EndIf;        
		If Items.Find("FormPostAndClose") <> Undefined Then
			Items.FormPostAndClose.Visible = False;
			Items.FormPostAndClose.Enabled = False;  
		EndIf;
	Else
		If Not Object.Posted Then
			Items.FormUndoPosting.Visible = False;
			Items.FormUndoPosting.Enabled = False;
		EndIf;
		If Not ValueIsFilled(Object.Ref) Then
			Items.FormSetDeletionMarkAction.Visible = False;
			Items.FormSetDeletionMarkAction.Enabled = False;
		Else
			If Object.DeletionMark Then
				Items.FormSetDeletionMarkAction.Title = NStr("en = 'Clear deletion mark'; ru = 'Снять отметку удаления'; de = 'Löschmarkierung aufheben'");
			EndIf;
		EndIf;
	EndIf;
	
	// Rights to edit document number and date
	If Not IsInRole("Administrator") Then
		Items.Number.ReadOnly = True;
		Items.Date.ReadOnly = True;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);

	// Set availability of the "Do not export to the accounting system" flag
	If Not cmCheckUserPermissions("HavePermissionToEditExportedSettlements") Then
		Items.DoNotExportToTheAccountingSystem.Enabled = False;
	EndIf;
	
	// Check basis
	If Parameters.Property("Basis") And ValueIsFilled(Parameters.Basis) And TypeOf(Parameters.Basis) = Type("CatalogRef.GuestGroups") Then
		vHasOfficialLetter = False;
		If Parameters.Property("HasOfficialLetter") And Parameters.HasOfficialLetter Then
			vHasOfficialLetter = True;
		EndIf;
		If Parameters.Property("ParentDoc") And ValueIsFilled(Parameters.ParentDoc) And TypeOf(Parameters.ParentDoc) = Type("DocumentRef.Accommodation") Then
			vObj = FormAttributeToValue("Object");
			vObj.Fill(Parameters.ParentDoc);
			If Not vHasOfficialLetter Then
				vObj.ParentDoc = Documents.Accommodation.EmptyRef();
				vObj.Fill(Parameters.Basis);
			EndIf;
			ValueToFormAttribute(vObj, "Object");
		ElsIf ValueIsFilled(Parameters.Basis.ClientDoc) And TypeOf(Parameters.Basis.ClientDoc) = Type("DocumentRef.Accommodation") Then
			vObj = FormAttributeToValue("Object");
			vObj.Fill(Parameters.Basis.ClientDoc);
			If Not vHasOfficialLetter Then
				vObj.ParentDoc = Documents.Accommodation.EmptyRef();
				vObj.Fill(Parameters.Basis);
			EndIf;
			ValueToFormAttribute(vObj, "Object");
		EndIf;
	EndIf;
	
	If Parameters.Property("PrintOnOpen") Then
		PrintOnOpen = Parameters.PrintOnOpen;
	EndIf;
	If Parameters.Property("PrintFormLanguage") Then
		PrintFormLanguage = Parameters.PrintFormLanguage;
	EndIf;
	
	If ValueIsFilled(Object.GuestGroup) Then
		Items.GuestGroup.ToolTip = TrimAll(Object.GuestGroup.Description);
	Else
		Items.GuestGroup.ToolTip = "";
	EndIf;	
	
	CalculateTotals(); 
	FillFunctionsButton();	
	FillPrintingButton();
	EditNumber = False;
	
	// Availability
	If ValueIsFilled(Object.ParentDoc) And TypeOf(Object.ParentDoc) = Type("DocumentRef.Folio") Then
		Items.Company.ReadOnly = True;
		Items.AccountingCustomer.ReadOnly = True;
		Items.AccountingContract.ReadOnly = True;
		Items.GuestGroup.ReadOnly = True;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Check if we have to open print form instead of opening the document
	If PrintOnOpen Then
		vPrintForm = tcOnServer.GetInvoiceDefaultPrintForm(PrintFormLanguage);
		If ValueIsFilled(vPrintForm) Then
			vPrintFormExternalProcessing = tcOnServer.cmGetAttributeByRef(vPrintForm, "ExternalProcessing");
			vPrintFormReport = tcOnServer.cmGetAttributeByRef(vPrintForm, "Report");
			If ValueIsFilled(vPrintFormExternalProcessing) Then 
				Try
					OpenExternalProcedureForm(vPrintFormExternalProcessing, vPrintForm);
				Except
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
				EndTry;
			ElsIf ValueIsFilled(vPrintFormReport) Then
				Try
					OpenExternalReportForm(vPrintFormReport, vPrintForm);
				Except
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
				EndTry;
			Else
				vPrintFormLanguage = tcOnServer.cmGetAttributeByRef(vPrintForm, "Language");
				vPredefinedDataName = tcOnServer.cmGetAttributeByRef(vPrintForm, "PredefinedDataName");
				If Left(vPredefinedDataName, 22) = "SettlementPrintInvoice" Then
					OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm, PrintFormType", Object.Ref, vPrintFormLanguage, vPrintForm, "Invoice"), ThisObject, Object.Ref);
				ElsIf Left(vPredefinedDataName, 25) = "SettlementPrintSettlement" Then
					OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm, PrintFormType", Object.Ref, vPrintFormLanguage, vPrintForm, "Settlement"), ThisObject, Object.Ref);
				ElsIf Left(vPredefinedDataName, 25) = "SettlementPrintVATInvoice" Then
					OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm, PrintFormType", Object.Ref, vPrintFormLanguage, vPrintForm, "VATInvoice"), ThisObject, Object.Ref);
				ElsIf Left(vPredefinedDataName, 17) = "SettlementPrint7G" Then
					OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm, PrintFormType", Object.Ref, vPrintFormLanguage, vPrintForm, "Settlement7G"), ThisObject, Object.Ref);
				ElsIf vPredefinedDataName = "SettlementPrintHotelProducts" Then
					OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm, PrintFormType", Object.Ref, vPrintFormLanguage, vPrintForm, "SettlementHotelProduct"), ThisObject, Object.Ref);
				EndIf;
			EndIf;
			pCancel = True;
			Return;
		EndIf;
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Subsystem.Accounts.Changed", Object.Ref);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	If Modified And OldStateObject <> Undefined And OldStateObject.Property("Ref") And ValueIsFilled(OldStateObject.Ref) Then  
		pCancel = True;
		pStandardProcessing = False; 
		vQMsg = NStr("en = 'The data has been changed. Save the changes?'; 
					 |de = 'Die Daten wurden geändert. Änderungen speichern?'; 
					 |ru = 'Данные были изменены. Сохранить изменения?'");
		ShowQueryBox(New NotifyDescription("BeforeCloseMsg", ThisObject), vQMsg, QuestionDialogMode.YesNoCancel);	
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Not pExit Then
		OnCloseAtServer();
	EndIf;
EndProcedure // OnClose

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "SessionParameters.CurrentUser.Change" Then
		EmployeePINCodeChecked = True;
		If Not ValueIsFilled(Object.Ref) Then
			Object.Author = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
		EndIf;
		If pParameter.ModeAfterCheck = "BeforeWrite" Then
			If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
				Close();
			EndIf;
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)  
	ClearMessages();
	
	vMessage = ""; 
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then    
		// APDEX
		vApdexRemarks = GetRemarksForAPDEX();
		vKeyOperation = "Document.Settlement.Form.tcDocumentForm.Posting";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);    
		
		
		// Do some extra processing
		BeforeWriteAtServer();
		// Check document attributes
		If Not CheckDocumentAttributesAtServer(vMessage) Then
			pCancel = True;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , ,tcOnServer.cmNStrAtServer(vMessage));
			Return;
		EndIf;
		vMessage = "";
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "BeforeWrite"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			pCancel = True;
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
	EndIf;
EndProcedure // BeforeWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingCurrencyOnChange(Item)
	If ValueIsFilled(Object.AccountingCurrency) Then
		RecalculateServicesAtServer(True);
	Else
		Object.Services.Clear();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	CompanyOnChangeAtServer();
EndProcedure // CompanyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingCustomerOnChange(pItem)
	AccountingCustomerOnChangeAtServer();
EndProcedure // AccountingCustomerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingContractOnChange(pItem)
	AccountingContractOnChangeAtServer();
EndProcedure // AccountingContractOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PerInvoiceCommissionOnChange(pItem)
	PerInvoiceCommissionOnChangeAtServer();
EndProcedure // PerInvoiceCommissionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOnChange(pItem)
	GuestGroupOnChangeAtServer();
EndProcedure // GuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BankAccountOnChange(pItem)
	BankAccountOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesAfterDeleteRow(pItem)
	ServicesAfterDeleteRowAtServer();
EndProcedure // ServicesAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentDocumentsAfterDeleteRow(pItem)
	CalculateTotals();
EndProcedure // PaymentDocumentsAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentDocumentsOnEditEnd(pItem, pNewRow, pCancelEdit)
	CalculateTotals();
EndProcedure // PaymentDocumentsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	vRow = Object.Services.FindByID(pSelectedRow);
	If vRow <> Undefined And pField <> Undefined Then
		If pField.Name = "ServicesClient" Then
			If ValueIsFilled(vRow.Client) Then
				ShowValue(, vRow.Client);
			EndIf;
		ElsIf pField.Name = "ServicesGuestGroup" Then
			If ValueIsFilled(vRow.GuestGroup) Then
				ShowValue(, vRow.GuestGroup);
			EndIf;
		ElsIf pField.Name = "ServicesAgent" Then
			If ValueIsFilled(vRow.Agent) Then
				ShowValue(, vRow.Agent);
			EndIf;
		ElsIf pField.Name = "ServicesParentDoc" Then
			If ValueIsFilled(vRow.ParentDoc) Then
				ShowValue(, vRow.ParentDoc);
			EndIf;
		ElsIf pField.Name = "ServicesFolio" Then
			If ValueIsFilled(vRow.Folio) Then
				ShowValue(, vRow.Folio);
			EndIf;
		ElsIf pField.Name = "ServicesCharge" Then
			If ValueIsFilled(vRow.Charge) Then
				ShowValue(, vRow.Charge);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ServicesSelection

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentDocumentsPaymentDocOnChangeAtServer(pCurRowId)
	If pCurRowId <> Undefined Then
		vRow = Object.PaymentDocuments.FindByID(pCurRowId);
		If vRow <> Undefined Then
			If ValueIsFilled(vRow.PaymentDoc) Then
				vPaymentDoc = vRow.PaymentDoc;
				vRow.PaymentDocNumber = cmGetDocumentNumberPresentation(vPaymentDoc.Number);
				vRow.PaymentDocDate = vPaymentDoc.Date;
				If TypeOf(vRow.PaymentDoc) = Type("DocumentRef.DepositTransfer") Then
					vRow.Sum = Round(cmConvertCurrencies(vPaymentDoc.SumInFolioToCurrency, vPaymentDoc.FolioToCurrency, , Object.AccountingCurrency, , Object.Date, Object.Hotel), 2);
				ElsIf TypeOf(vRow.PaymentDoc) = Type("DocumentRef.DebitNote") Then
					vRow.Sum = Round(cmConvertCurrencies(vPaymentDoc.CorrectionSum, vPaymentDoc.AccountingCurrency, , Object.AccountingCurrency, , Object.Date, Object.Hotel), 2);
				Else
					vRow.Sum = Round(cmConvertCurrencies(vPaymentDoc.Sum, vPaymentDoc.PaymentCurrency, , Object.AccountingCurrency, , Object.Date, Object.Hotel), 2);
				EndIf;
			Else
				vRow.PaymentDocNumber = "";
				vRow.PaymentDocDate = '00010101';
				vRow.Sum = 0;
			EndIf;
			CalculateTotals();
		EndIf;
	EndIf;
EndProcedure // PaymentDocumentsPaymentDocOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentDocumentsPaymentDocOnChange(pItem)
	PaymentDocumentsPaymentDocOnChangeAtServer(Items.PaymentDocuments.CurrentRow);
EndProcedure // PaymentDocumentsPaymentDocOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateServices(pCommand)
	RecalculateServicesAtServer(True);
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculatePayments(pCommand)
	RecalculatePaymentsAtServer();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FuncButtonClick(Command)
	// Save document first
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Choose processing type
	vActionsNumber = StrReplace(Command.Name,"Func","");
	vAction = GetActionForNumber(vActionsNumber);
	If ValueIsFilled(vAction.ExternalProcessing) Then
		#IF ThickClientOrdinaryApplication THEN
			If Not cmLoadExternalDataProcessor(vAction.ExternalProcessing, FormAttributeToValue("Object", Type("DocumentObject.Accommodation")), , Undefined) Then
				ShowMessageBox(, NStr("en='Failed to load external action!';ru='Не удалось загрузить внешнюю операцию!';de='Die externe Operation konnte nicht geladen werden!'"));
			EndIf;
		#ENDIF
	Else
		If vAction.PredefinedDataName = "SettlementFillInvoice" Then
			If ValueIsFilled(Object.Ref) Then
				OpenForm("Document.ProformaInvoice.ObjectForm", New Structure("Basis", Object.Ref), Object.Ref, Object.Ref);
			EndIf;
		ElsIf vAction.PredefinedDataName = "SettlementFillVATInvoiceNumber" Then
			vExtProcessing = tcOnServer.cmGetAttributeByRef(vAction, "ExternalProcessing");
			If ValueIsFilled(vExtProcessing) Then
				If Not RunExternalProcessingAtServer(vExtProcessing) Then
					ShowMessageBox( , NStr("en='Failed to run data processor!';ru='Не удалось выполнить обработку!';de='Die Bearbeitung ist fehlgeschlagen!'"));
				EndIf;
			Else
				FillVATInvoiceNumberAtServer();
			EndIf;
		ElsIf ValueIsFilled(vAction.DataProcessor) Then     
			If Not RunDataProcessor(vAction.DataProcessor) Then
				ShowMessageBox( , NStr("en='Failed to run data processor!';ru='Не удалось выполнить обработку!';de='Die Bearbeitung ist fehlgeschlagen!'"));
			EndIf;
		Else
			ShowMessageBox( , NStr("en='No data processor found for action!';ru='У действия не указан обработчик!';de='Bei der Aktion ist kein Bearbeiter angegeben!'"));
		EndIf;
	EndIf;   
EndProcedure // FuncButtonClick

// -----------------------------------------------------------------------------
&AtClient
Procedure UndoPosting(pCommand)
	UndoPostingAtServer();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(Command)
	// Save document first
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Choose processing type
	vPrintNumber = StrReplace(Command.Name,"Print","");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	// Load external print form
	If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
		Try
			OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
		EndTry;
	ElsIf ValueIsFilled(vPrintForm.Report) Then
		Try
			OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
		EndTry;
	ElsIf Left(vPrintForm.PredefinedDataName, 22) = "SettlementPrintInvoice" Then
		OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm, PrintFormType", Object.Ref, vPrintForm.Language, vPrintForm, "Invoice"), ThisObject, Object.Ref);
	ElsIf Left(vPrintForm.PredefinedDataName, 25) = "SettlementPrintSettlement" Then
		OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm, PrintFormType", Object.Ref, vPrintForm.Language, vPrintForm, "Settlement"), ThisObject, Object.Ref);
	ElsIf Left(vPrintForm.PredefinedDataName, 25) = "SettlementPrintVATInvoice" Then
		OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm, PrintFormType", Object.Ref, vPrintForm.Language, vPrintForm, "VATInvoice"), ThisObject, Object.Ref);
	ElsIf Left(vPrintForm.PredefinedDataName, 17) = "SettlementPrint7G" Then
		OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm, PrintFormType", Object.Ref, vPrintForm.Language, vPrintForm, "Settlement7G"), ThisObject, Object.Ref);
	ElsIf vPrintForm.PredefinedDataName = "SettlementPrintHotelProducts" Then
		OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm, PrintFormType", Object.Ref, vPrintForm.Language, vPrintForm, "SettlementHotelProduct"), ThisObject, Object.Ref);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetDeletionMarkAction(pCommand)
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	If Modified Then
		Modified = False;
	EndIf;
	SetDeletionMarkAtServer();
	Read();
	Notify("Subsystem.Accounts.Changed", Object.Ref);
	Close();
EndProcedure // SetDeletionMarkAction

// -----------------------------------------------------------------------------
&AtClient
Procedure CreatePayment(pCommand)
	If Modified Or Not Object.Posted Then
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.Ref) Then
		OpenForm("Document.CustomerPayment.ObjectForm", New Structure("Basis", Object.Ref), , Object.Ref);
		Close();
	EndIf;
EndProcedure // CreatePayment

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateDepositClearing(pCommand)
	If Modified Or Not Object.Posted Then
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.Ref) Then
		OpenForm("Document.CustomerAdvanceDistribution.ObjectForm", New Structure("Basis", Object.Ref), , Object.Ref);
		Close();
	EndIf;
EndProcedure // CreateDepositClearing

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCloseAtServer()
	If ValueIsFilled(CurrentUser) Then
		SessionParameters.CurrentUser = CurrentUser;
	EndIf;
EndProcedure // OnCloseAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateServicesAtServer(pDoNotUpdateCurrency = False)
	// Read document state before services recalculation
	If OldStateObject = Undefined Then
		OldStateObject = tcOnServer.cmGetAtributeAsArray(Object.Ref);
	EndIf;
	// Undo posting of the current document first
	vObject = FormAttributeToValue("Object");
	If vObject.Posted Then
		vObject.Write(DocumentWriteMode.UndoPosting);
	EndIf;
	// Do not update document currency
	If pDoNotUpdateCurrency Then
		vObject.AdditionalProperties.Insert("DoNotUpdateCurrency", True);
	EndIf;
	// Refill the document services
	vParentDoc = vObject.ParentDoc;
	If ValueIsFilled(vParentDoc) Then
		If TypeOf(vParentDoc) = Type("DocumentRef.Folio") Then
			vObject.pmFillByFolio(vParentDoc);
		ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then 
			vObject.pmFillByDocument(vParentDoc, False);
		ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then 
			vObject.pmFillByDocument(vParentDoc, False);
		ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then 
			vObject.pmFillByDocument(vParentDoc, False);
		ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ProformaInvoice") Then 
			vObject.pmFillByInvoice(vParentDoc);
		EndIf;
	ElsIf ValueIsFilled(vObject.GuestGroup) Then 
		vObject.pmFillByGuestGroup(vObject.GuestGroup);
	ElsIf ValueIsFilled(vObject.AccountingContract) Then 
		vObject.pmFillByContract(vObject.AccountingContract);
	ElsIf ValueIsFilled(vObject.AccountingCustomer) Then 
		vObject.pmFillByCustomer(vObject.AccountingCustomer);
	EndIf;
	ValueToFormAttribute(vObject, "Object");
	CalculateTotals();
EndProcedure // RecalculateServicesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculatePaymentsAtServer()
	// Undo posting of the current document first
	vObject = FormAttributeToValue("Object");
	If vObject.Posted Then
		vObject.Write(DocumentWriteMode.UndoPosting);
	EndIf;
	// Refill the document payments
	vObject.pmFillListOfPayments();
	ValueToFormAttribute(vObject, "Object");
	CalculateTotals();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UndoPostingAtServer()
	vObject = FormAttributeToValue("Object");
	If vObject.Posted Then
		vObject.Write(DocumentWriteMode.UndoPosting);
	EndIf;
	ValueToFormAttribute(vObject, "Object");
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateTotals() 
	vServices =  Object.Services;
	vPaymentDocuments = Object.PaymentDocuments;
	
	vSum = vServices.Total("Sum");
	If vSum <> Object.Sum Then
		Object.Sum = vSum;
	EndIf;
	vVATSum = vServices.Total("VATSum");
	If vVATSum <> Object.VATSum Then
		Object.VATSum = vVATSum;
	EndIf;
	vCommissionSum = vServices.Total("CommissionSum");
	vPerInvoiceCommissionSum = 0;
	vPerInvoiceVATCommissionSum = 0;
	If Object.PerInvoiceCommission <> 0 Then
		vPerInvoiceCommissionSum = Round(vSum * Object.PerInvoiceCommission / 100, 2);
		vPerInvoiceVATCommissionSum = Round(vVATSum * Object.PerInvoiceCommission / 100, 2);
	EndIf;
	vCommissionSum = vCommissionSum + vPerInvoiceCommissionSum;
	If vCommissionSum <> Object.CommissionSum Then
		Object.CommissionSum = vCommissionSum;
	EndIf;
	If vPerInvoiceCommissionSum <> Object.PerInvoiceCommissionSum Then
		Object.PerInvoiceCommissionSum = vPerInvoiceCommissionSum;
	EndIf;
	If vPerInvoiceVATCommissionSum <> Object.PerInvoiceVATCommissionSum Then
		Object.PerInvoiceVATCommissionSum = vPerInvoiceVATCommissionSum;
	EndIf;
	vPaymentDocumentsSum = vPaymentDocuments.Total("Sum");
	vSumDue = vSum - vPaymentDocumentsSum;
	If ValueIsFilled(Object.AccountingCustomer) And Not Object.AccountingCustomer.DoNotPostCommission Then
		vSumDue = vSumDue - vCommissionSum;
	EndIf;
	If vSumDue <> Object.SumDue Then
		Object.SumDue = vSumDue;
	EndIf;
	
	Items.GroupServices.Title = NStr("en='Services: '; ru='Услуги: '; de='Dienstleistungen: '") + cmFormatSum(vSum, Object.AccountingCurrency);
	Items.GroupPayments.Title = NStr("en='Payments: '; ru='Платежи: '; de='Zahlungen: '")       + cmFormatSum(vPaymentDocumentsSum,  Object.AccountingCurrency);
	
	Total = cmFormatSum(vSumDue, Object.AccountingCurrency);
EndProcedure // CalculateTotals

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFunctionsButton()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectFormActions.Ref AS Ref,
	|	ObjectFormActions.Code AS Code,
	|	ObjectFormActions.PredefinedDataName AS PredefinedDataName,
	|	ObjectFormActions.IsDefault AS IsDefault
	|FROM
	|	Catalog.ObjectFormActions AS ObjectFormActions
	|WHERE
	|	NOT ObjectFormActions.DeletionMark
	|	AND ObjectFormActions.ObjectType = &ObjectType
	|	AND ObjectFormActions.IsActive = TRUE
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code";
	
	Query.SetParameter("ObjectType", Documents.Settlement.EmptyRef());	
	QueryResult = Query.Execute();	
	SelectionRecords = QueryResult.Select();
	Actions.Clear();
	While SelectionRecords.Next() Do
		If SelectionRecords.PredefinedDataName = "SettlementFillCustomerPayment" Then
			Continue;
		EndIf;
		
		vNewRow = Actions.Add();
		vNewRow.Action = SelectionRecords.Ref;
		vNewRow.IsDefault = SelectionRecords.IsDefault;
		
		vID = vNewRow.GetID();
		
		vCommand = Commands.Add("Func" + vID);
		vCommand.Action = "FuncButtonClick";
		vStructure = New Structure("Title, CommandName",
		TrimAll(SelectionRecords.Code) + " " + cmNStr(SelectionRecords.ref), "Func" + vID);
		
		
		tcOnServer.cmCreateItem(ThisObject, ?(SelectionRecords.IsDefault, Items.FormGroupFunctionsDefault, Items.FormGroupFunctionsNotDefault), "Func" + vID, "FormButton", vStructure);
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function RunExternalProcessingAtServer(pExtProc)
	vObj = FormAttributeToValue("Object", Type("DocumentObject.Settlement"));
	vResult = cmLoadExternalDataProcessor(pExtProc, vObj);
	ValueToFormAttribute(vObj, "Object");
	Return vResult;
EndFunction // RunExternalProcessingAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillVATInvoiceNumberAtServer()
	vLastUsedInvoiceNumber = cmGetLastUsedVATInvoiceNumber(Object.Company);
	vNextInvoiceNumber = cmGetNextVATInvoiceNumber(vLastUsedInvoiceNumber);
	Object.InvoiceNumber = vNextInvoiceNumber;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function RunDataProcessor(pAction)
	Return cmRunDataProcessor(pAction);
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function GetActionForNumber(pActionsNumber)
	vActions = Actions.FindByID(Number(pActionsNumber)).Action;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vActions);
	vStruct.Insert("PredefinedDataName", vActions.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing", vActions.ExternalProcessing);
	vStruct.Insert("DataProcessor", vActions.DataProcessor);
	
	Return vStruct;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref AS Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName AS PredefinedDataName,
	|	ObjectPrintingForms.IsDefault AS IsDefault,
	|	ObjectPrintingForms.Language AS Language
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	NOT ObjectPrintingForms.DeletionMark
	|	AND ObjectPrintingForms.IsActive = TRUE
	|	AND ObjectPrintingForms.ObjectType = &ObjectType
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code
	|TOTALS BY
	|	Language";
	
	vQuery.SetParameter("ObjectType", Documents.Settlement.EmptyRef());	
	vRes = vQuery.Execute();	
	SelectionRecords = vRes.Select(QueryResultIteration.ByGroups);
	
	PrintForms.Clear();
	
	vLang = Object.GuestGroup.Client.Language;
	While SelectionRecords.Next() Do
		SelectionDetailRecords = SelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = SelectionRecords.Language Or Not ValueIsFilled(SelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf Not vLang = SelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, 
												  Items.FormGroupPrintingNotDefaultExtra, 
												  "Print" + SelectionRecords.Language, 
												  "FormGroup",
												  New Structure("Type,Title", FormGroupType.Popup,SelectionRecords.Language));
		EndIf;
		
		While SelectionDetailRecords.Next() Do
			vNewRow = PrintForms.Add();
			vNewRow.PrintForm = SelectionDetailRecords.Ref;
			vNewRow.IsDefault = SelectionDetailRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("Print" + vID);
			vCommand.Action = "PrintButtonClick";
			If SelectionDetailRecords.IsDefault Then
				vParent = Items.FormGroupPrintingDefault;
			Else
				vParent = vParentLang;
			EndIf;
			vStructure = New Structure("Title, CommandName", TrimAll(SelectionDetailRecords.Code) + " " + cmNStr(SelectionDetailRecords.ref), "Print" + vID);
			tcOnServer.cmCreateItem(ThisObject, vParent, "Print" + vID,"FormButton", vStructure);
		EndDo;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumber(pActionsNumber)
	vPrintForms = PrintForms.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref", vPrintForms);
	vStruct.Insert("PredefinedDataName", vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing", vPrintForms.ExternalProcessing);
	vStruct.Insert("Report", vPrintForms.Report);
	vStruct.Insert("Language", vPrintForms.Language);
	
	Return vStruct;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef)
	#If ThickClientOrdinaryApplication Then
		vExtProcData = pExtProcRef.ExternalProcessingStorage.Get();
		vExtProcPath = GetTempFileName(".efd");
		vExtProcData.Write(vExtProcPath);
		vExtProcObj = ExternalDataProcessors.Create(vExtProcPath, False);
		vStruct = New Structure("InputParameter, ObjectPrintingForm", FormDataToValue(Object, Type("DocumentObject.Accommodation")), pPrintFormTypeRef);
		FillPropertyValues(vExtProcObj, vStruct);
		vFrm = vExtProcObj.GetForm("GuestForm");
		vFrm.Open();
		BeginDeletingFiles(New NotifyDescription, vExtProcPath);
	#Else
		vURL = GetURL(pExtProcRef, "ExternalProcessingStorage"); 
		vName = ConnectExternalDataProcessor(vURL, "ExternalInvoicePrintingForm");
		vParams = New Structure("InputParameter, ObjectPrintingForm", Object.Ref, pPrintFormTypeRef);
	    vFrm = GetForm("ExternalDataProcessor." + vName + ".ObjectForm", vParams);
		vFrm.Open();
	#EndIf
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef)
	#If ThickClientOrdinaryApplication Then
		vExtRepData = pExtRepRef.ExternalProcessingStorage.Get();
		vExtRepPath = GetTempFileName(".erf");
		vExtRepData.Write(vExtRepPath);
		vExtRepObj = ExternalReports.Create(vExtRepPath, False);
		vStruct = New Structure("InputParameter, ObjectPrintingForm", FormDataToValue(Object, Type("DocumentObject.Accommodation")), pPrintFormTypeRef);
		FillPropertyValues(vExtRepObj, vStruct);
		// Fill reference to the report catalog item
		vExtRepObj.Report = pPrintFormTypeRef.Report;
		// Load report catalog item attributes
		vExtRepObj.pmLoadReportAttributes(Object.Ref);
		// Open report's default form
		vExtRepFrm = vExtRepObj.GetForm();
		vExtRepFrm.GenerateOnFormOpen = True;
		vExtRepFrm.Open();
		BeginDeletingFiles(New NotifyDescription, vExtRepPath);
	#Else
		ShowMessageBox(, NStr("en='Not supported in thin or web client mode!'; 
							  |ru='Не поддерживается в режиме тонкого и WEB клиента!'; 
							  |de='Nicht in Dünnen-Client-Modus oder Web-Client-Modus unterstützt!'"));
	#EndIf
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()	
	If ValueIsFilled(Object.Ref) And ValueIsFilled(Object.Date) Then
		If Year(Object.Ref.Date) <> Year(Object.Date) Then
			EditNumber = True;
		EndIf;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CompanyOnChangeAtServer()
	If ValueIsFilled(Object.Company) Then
		If Not IsBlankString(Object.Company.Consignor) Then
			Object.Consignor = TrimR(Object.Company.Consignor);
		EndIf;
		// Change document number
		If ValueIsFilled(Object.Ref) And Not IsBlankString(Object.Company.Prefix) Then
			If Left(Object.Number, StrLen(TrimR(Object.Company.Prefix))) <> TrimR(Object.Company.Prefix) Then
				EditNumber = True;
			EndIf;
		EndIf;
		RecalculateServicesAtServer(True);
		RecalculatePaymentsAtServer();
	EndIf;
EndProcedure // CompanyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AccountingCustomerOnChangeAtServer()
	If ValueIsFilled(Object.AccountingCustomer) Then
		If Not IsBlankString(Object.AccountingCustomer.Consignee) Then
			Object.Consignee = TrimR(Object.AccountingCustomer.Consignee);
		EndIf;
		If ValueIsFilled(Object.AccountingContract) Then
			If Object.AccountingContract.Owner <> Object.AccountingCustomer Then
				Object.AccountingContract = Object.AccountingCustomer.Contract;
				Object.PerInvoiceCommission = 0;
				If ValueIsFilled(Object.AccountingContract) And Object.AccountingContract.PerInvoiceCommission <> 0 Then
					Object.PerInvoiceCommission = Object.AccountingContract.PerInvoiceCommission;
				EndIf;
			EndIf;
		EndIf;
		RecalculateServicesAtServer();
		RecalculatePaymentsAtServer();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure AccountingContractOnChangeAtServer()
	If ValueIsFilled(Object.AccountingContract) Then
		If Object.AccountingCustomer <> Object.AccountingContract.Owner Then
			Object.AccountingCustomer = Object.AccountingContract.Owner;
		EndIf;
	EndIf;
	Object.PerInvoiceCommission = 0;
	If ValueIsFilled(Object.AccountingContract) And Object.AccountingContract.PerInvoiceCommission <> 0 Then
		Object.PerInvoiceCommission = Object.AccountingContract.PerInvoiceCommission;
	EndIf;
	RecalculateServicesAtServer();
	RecalculatePaymentsAtServer();
EndProcedure // AccountingContractOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PerInvoiceCommissionOnChangeAtServer()
	CalculateTotals();
EndProcedure // PerInvoiceCommissionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GuestGroupOnChangeAtServer()
	If ValueIsFilled(Object.GuestGroup) Then
		Items.GuestGroup.ToolTip = TrimAll(Object.GuestGroup.Description);
	Else
		Items.GuestGroup.ToolTip = "";
	EndIf;	
	RecalculateServicesAtServer();
	RecalculatePaymentsAtServer();
EndProcedure // GuestGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BankAccountOnChangeAtServer()
	If ValueIsFilled(Object.BankAccount) And ValueIsFilled(Object.BankAccount.AccountCurrency) And
		Object.BankAccount.AccountCurrency <> Object.AccountingCurrency Then
		Object.AccountingCurrency = Object.BankAccount.AccountCurrency;		
		If ValueIsFilled(Object.AccountingCurrency) Then
			RecalculateServicesAtServer(True);
		Else
			Object.Services.Clear();
		EndIf;		
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesAfterDeleteRowAtServer()
	CalculateTotals();
EndProcedure // ServicesAfterDeleteRowAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer()
	If EditNumber Then
		vObject = FormAttributeToValue("Object");		
		vObject.SetNewNumber();
		ValueToFormAttribute(vObject, "Object");
		EditNumber = False;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributesAtServer(rMessage)
	vObj = FormAttributeToValue("Object");	
	SetObjectAndFormAttributeConformity(vObj, "Object");
	// Basic checks
	vAttributeInErr = "";
	If vObj.pmCheckDocumentAttributes(rMessage, vAttributeInErr) Then
		vUM = New UserMessage();
		vUM.SetData(vObj);
		vUM.Field = vAttributeInErr;
		vUM.Text = NStr(rMessage);
		vUM.Message();
		Return False;
	Else
		Return True;
	EndIf;	
EndFunction // CheckDocumentAttributesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDeletionMarkAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Read();
	vObj.SetDeletionMark(Not vObj.DeletionMark);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // SetDeletionMarkAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeCloseMsg(pQuestionResult, pAdditionalParameters) Export
	If pQuestionResult = DialogReturnCode.Yes Then     
		OldStateObject = Undefined;
		vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting); 
		Write(vWriteParameters);
		Close();
	ElsIf pQuestionResult = DialogReturnCode.No Then
		If OldStateObject <> Undefined Then
		    FillPropertyValues(Object, OldStateObject, , "Ref, Services, PaymentDocuments");
			Object.Services.Clear();
			For Each vServiceRow In OldStateObject.Services Do
				FillPropertyValues(Object.Services.Add(), vServiceRow);
			EndDo;     
			Object.PaymentDocuments.Clear();
			For Each vPaymentDocumentsRow In OldStateObject.PaymentDocuments Do
				FillPropertyValues(Object.PaymentDocuments.Add(), vPaymentDocumentsRow);
			EndDo;
			If OldStateObject.RefPosted Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
			Else
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Write);
			EndIf;
			Write(vWriteParameters);
			Close();
		EndIf;
	Else
		Return;	
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Function GetRemarksForAPDEX()
	
	vAPDEXParams = New Structure;         
	vAPDEXParams.Insert("Date", String(Object.Date)); 
	vAPDEXParams.Insert("Number", Object.Number);  
	vAPDEXParams.Insert("Rows", Object.Services.Count());  
	
	Return vAPDEXParams;
EndFunction // GetRemarksForAPDEX

#EndRegion
