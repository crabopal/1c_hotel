// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	If not ValueIsFilled(Object.Ref) Then
		vObject = FormAttributeToValue("Object");
		If Not ValueIsFilled(Object.Author) Then
			vObject.pmFillAttributesWithDefaultValues();
		Else
			vObject.pmFillAuthorAndDate();
		EndIf;
		ValueToFormAttribute(vObject,"Object");
	EndIf;
	
	// Check edit prohibited date
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(Object.Hotel.EditProhibitedDate) And 
			BegOfDay(Object.Hotel.EditProhibitedDate) >= BegOfDay(Object.Date) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.Company) Then
		Object.VATRate = Object.Company.VATRate;
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
	
	// Fill guest group description
	FillGuestGroupDiscription();
	
	FillPrintingButton();  
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function BeforeWriteAtServer(pWriteMode)
	vAttributeInErr = "";
	vMessage = "";
	vObject = FormAttributeToValue("Object");		
	
	If EditNumber Then
		vObject.SetNewNumber();
	EndIf;
	
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel = vObject.pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, vObject.Metadata(), vObject.Ref, NStr(vMessage));
			
			If Not IsBlankString(vAttributeInErr) Then
				CurrentItem = Items[vAttributeInErr];
				vUserMessage = New UserMessage;
				vUserMessage.Field = vAttributeInErr;
				vUserMessage.Text = NStr(vMessage);
				vUserMessage.Message();
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage));
			EndIf;
		EndIf;
	EndIf;
	
	ValueToFormAttribute(vObject,"Object");	
	Return pCancel;;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	ClearMessages();
	
	pCancel = BeforeWriteAtServer(pWriteParameters.WriteMode);
EndProcedure

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
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillActionAtServer()
	// Clear guest groups
	Object.Invoices.Clear();
	Object.Services.Clear();
	
	// Refill guest groups
	If ValueIsFilled(Object.GuestGroup) Then
		vObject = FormAttributeToValue("Object");
		vObject.pmFillByGuestGroup(Object.GuestGroup);
		ValueToFormAttribute(vObject, "Object");
	ElsIf ValueIsFilled(Object.AccountingContract) Then
		vObject = FormAttributeToValue("Object");
		vObject.pmFillByContract(Object.AccountingContract);
		ValueToFormAttribute(vObject, "Object");
	ElsIf ValueIsFilled(Object.AccountingCustomer) Then
		vObject = FormAttributeToValue("Object");
		vObject.pmFillByCustomer(Object.AccountingCustomer);
		ValueToFormAttribute(vObject, "Object");
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Fill customer first!';ru='Контрагент должен быть выбран!';de='Partner muss gewählt sein!'"));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillAction(pCommand)
	FillActionAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillGuestGroupDiscription()
	If ValueIsFilled(Object.GuestGroup) Then
		Items.GuestGroup.ToolTip = TrimAll(Object.GuestGroup.Description);
	Else
		Items.GuestGroup.ToolTip = "";
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	If ValueIsFilled(Object.Hotel) Then
		EditNumber = True;
	EndIf;
	Object.Invoices.Clear();
	Object.Services.Clear();
	RecalculateTotalsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	If ValueIsFilled(Object.Company) Then
		Object.VATRate = tcOnServer.cmGetAttributeByRef(Object.Company, "VATRate");
		EditNumber = True;
	EndIf;
	Object.Invoices.Clear();
	Object.Services.Clear();
	RecalculateTotalsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingCurrencyOnChange(pItem)
	Object.Invoices.Clear();
	Object.Services.Clear();
	RecalculateTotalsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingCustomerOnChange(pItem)
	Object.Invoices.Clear();
	Object.Services.Clear();
	RecalculateTotalsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingContractOnChange(pItem)
	Object.Invoices.Clear();
	Object.Services.Clear();
	RecalculateTotalsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingContractStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Contracts.Form.tcChoiceForm", New Structure("Filter, ShowValidContractsOnly", New Structure("Owner", Object.AccountingCustomer), True), pItem);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOnChange(pItem)
	FillGuestGroupDiscription();
	Object.Invoices.Clear();
	Object.Services.Clear();
	RecalculateTotalsAtServer();
EndProcedure // GuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	// Notify changes in the accounts subsystem
	Notify("Subsystem.Accounts.Changed");
EndProcedure // AfterWrite

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CalculateVATSumAtServer(pSum, pVATRate, pDate = '00010101')
	Return cmCalculateVATSum(pVATRate, pSum, pDate);
EndFunction // CalculateVATSumAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoicesSumOnChange(pItem)
	vCurRow = Items.Invoices.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.Invoices.FindByID(vCurRow);
		vCurData.CorrectionSum = vCurData.InvoiceSum - vCurData.Sum;
		vCurData.CorrectionVATSum = CalculateVATSumAtServer(vCurData.CorrectionSum, Object.VATRate, Object.Date);
	EndIf;
EndProcedure // InvoicesSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoicesCorrectionSumOnChange(pItem)
	vCurRow = Items.Invoices.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.Invoices.FindByID(vCurRow);
		vCurData.Sum = vCurData.InvoiceSum - vCurData.CorrectionSum;
		vCurData.CorrectionVATSum = CalculateVATSumAtServer(vCurData.CorrectionSum, Object.VATRate, Object.Date);
	EndIf;
EndProcedure // InvoicesCorrectionSumOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateTotalsAtServer()
	Object.CorrectionSum = Object.Invoices.Total("CorrectionSum");
EndProcedure // RecalculateTotalsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoicesAfterDeleteRow(pItem)
	// Clear current group rows from services
	ClearGroupServices();
	RecalculateTotalsAtServer();
EndProcedure // InvoicesAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoicesOnEditEnd(pItem, pNewRow, pCancelEdit)
	RecalculateTotalsAtServer();
EndProcedure // InvoicesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoicesInvoiceStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Document.Settlement.ChoiceForm", New Structure("ChoiceMode, SelCustomer, SelContract, SelGuestGroup", True, Object.AccountingCustomer, Object.AccountingContract, Object.GuestGroup), pItem, Object.AccountingCustomer);
EndProcedure // InvoicesInvoiceStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoicesInvoiceOnChange(pItem)
	vCurRow = Items.Invoices.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.Invoices.FindByID(vCurRow);
		vCurData.InvoiceSum = 0;
		vCurData.Sum = 0;
		vCurData.CorrectionSum = 0;
		// Clear current group rows from services
		ClearGroupServices();
		// Process selected invoice
		If ValueIsFilled(vCurData.Invoice) Then
			vCurInvoice = vCurData.Invoice;
			vInvoiceParentDoc = tcOnServer.cmGetAttributeByRef(vCurInvoice, "ParentDoc");
			vCompany = tcOnServer.cmGetAttributeByRef(vCurInvoice, "Company");
			vAccountingCustomer = tcOnServer.cmGetAttributeByRef(vCurInvoice, "AccountingCustomer");
			vAccountingContract = tcOnServer.cmGetAttributeByRef(vCurInvoice, "AccountingContract");
			vGuestGroup = tcOnServer.cmGetAttributeByRef(vCurInvoice, "GuestGroup");
			If ValueIsFilled(vCompany) And vCompany <> Object.Company Then
				Object.Company = vCompany;
				Object.BankAccount = tcOnServer.cmGetAttributeByRef(Object.Company, "BankAccount");
			EndIf;
			If ValueIsFilled(vAccountingCustomer) And vAccountingCustomer <> Object.AccountingCustomer Then
				Object.AccountingCustomer = vAccountingCustomer;
				If ValueIsFilled(Object.AccountingContract) And tcOnServer.cmGetAttributeByRef(Object.AccountingContract, "Owner") <> Object.AccountingCustomer Then
					Object.AccountingContract = Undefined;
				EndIf;
			EndIf;
			If ValueIsFilled(vAccountingContract) And vAccountingContract <> Object.AccountingContract Then
				Object.AccountingContract = vAccountingContract;
			EndIf;
			If ValueIsFilled(vInvoiceParentDoc) And TypeOf(vInvoiceParentDoc) = Type("DocumentRef.Folio") Then
				Object.GuestGroup = Undefined;
				// Clear folio rows from services
				ClearFolioServices(vInvoiceParentDoc);
				// Fill invoice amount
				vCurData.InvoiceSum = tcOnServer.cmGetAttributeByRef(vCurInvoice, "Sum");
				// Retrieve group corrections
				vCurData.CorrectionSum = GetFolioCorrectionServices(vInvoiceParentDoc);
				// Calculate new row amount
				vCurData.Sum = vCurData.InvoiceSum - vCurData.CorrectionSum;
			ElsIf ValueIsFilled(vGuestGroup) Then
				If ValueIsFilled(Object.GuestGroup) And vGuestGroup <> Object.GuestGroup Then
					Object.GuestGroup = Undefined;
				EndIf;
				// Clear invoice group rows from services
				ClearGroupServices(vGuestGroup);
				// Fill invoice amount
				vCurData.InvoiceSum = tcOnServer.cmGetAttributeByRef(vCurInvoice, "Sum");
				// Retrieve group corrections
				vCurData.CorrectionSum = GetGroupCorrectionServices(vGuestGroup);
				// Calculate new group amount
				vCurData.Sum = vCurData.InvoiceSum - vCurData.CorrectionSum;
			Else
				If vCurData.LineNumber > 1 Then
					vCurData.Invoice = Undefined;
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Only one common invoice with empty guest group could be specified per credit node!'; 
					             |ru='В кредитовой корректировке разрешено указывать только один общий акт с пустой группой гостей!'; 
								 |de='Im Gutschrift ist nur ein Rechnung mit leerer Gästegruppe erlaubt!'"));
				Else
					// Fill invoice amount
					vCurData.InvoiceSum = tcOnServer.cmGetAttributeByRef(vCurInvoice, "Sum");
					// Retrieve group corrections
					vCurData.CorrectionSum = vCurData.InvoiceSum;
					// Calculate new row amount
					vCurData.Sum = vCurData.InvoiceSum - vCurData.CorrectionSum;
					// Copy invoice transactions with negative sign
					FillServicesByInvoice(vCurInvoice);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // InvoicesInvoiceOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure FillServicesByInvoice(pInvoice)
	Object.Services.Clear();
	For Each vInvSrvRow In pInvoice.Services Do
		vSrvRow = Object.Services.Add();
		FillPropertyValues(vSrvRow, vInvSrvRow);
		vSrvRow.Quantity = -vSrvRow.Quantity;
		vSrvRow.Sum = -vSrvRow.Sum;
		vSrvRow.VATSum = -vSrvRow.VATSum;
		vSrvRow.CommissionSum = -vSrvRow.CommissionSum;
		vSrvRow.VATCommissionSum = -vSrvRow.VATCommissionSum;
	EndDo;
EndProcedure // FillServicesByInvoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearGroupServices(pGuestGroup = Undefined)
	vGuestGroup = pGuestGroup;
	If vGuestGroup = Undefined Then
		vGuestGroup = CurrentGuestGroup;
	EndIf;
	If ValueIsFilled(vGuestGroup) Then
		i = 0;
		While i < Object.Services.Count() Do
			vSrvRow = Object.Services.Get(i);
			If vSrvRow.GuestGroup = vGuestGroup Then
				Object.Services.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
		CurrentGuestGroup = Undefined;
	EndIf;
EndProcedure // ClearGroupServices

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearFolioServices(pFolio = Undefined)
	If ValueIsFilled(pFolio) Then
		i = 0;
		While i < Object.Services.Count() Do
			vSrvRow = Object.Services.Get(i);
			If vSrvRow.Folio = pFolio Then
				Object.Services.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // ClearFolioServices

// -----------------------------------------------------------------------------
&AtServer
Function GetGroupCorrectionServices(pGuestGroup)
	vCorrectionAmount = 0;
	vLanguage = SessionParameters.CurrentLanguage;
	
	// Get all current accounts receivable services with balances per end of time
	vCharges = cmGetCurrentAccountsReceivableChargesWithBalances('39991231235959', Object.AccountingCustomer, Object.AccountingContract, , pGuestGroup, Object.AccountingCurrency, Object.Hotel);
	For Each vFolioChargesRow In vCharges Do
		If ValueIsFilled(vFolioChargesRow.Charge) Then
			If vFolioChargesRow.Company <> Object.Company Then
				Continue;
			EndIf;
			// Add service
			vServicesRow = Object.Services.Add();
			If ValueIsFilled(vFolioChargesRow.Folio) Then
				vServicesRow.Client = vFolioChargesRow.Folio.Client;
				vServicesRow.Room = vFolioChargesRow.Folio.Room;
			EndIf;
			vParentDoc = vFolioChargesRow.ParentDoc;
			If ValueIsFilled(vParentDoc) Then
				If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or 
				   TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
					vServicesRow.Client = vParentDoc.Guest;
					vServicesRow.Room = vParentDoc.Room;
					vServicesRow.AccommodationType = vParentDoc.AccommodationType;
					vServicesRow.NumberOfPersons = vParentDoc.NumberOfPersons;
				ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
					vServicesRow.Client = vParentDoc.Client;
					vServicesRow.Resource = vParentDoc.Resource;
					vServicesRow.NumberOfPersons = vParentDoc.NumberOfPersons;
				EndIf;
			EndIf;
			FillPropertyValues(vServicesRow, vFolioChargesRow.Charge);
			FillPropertyValues(vServicesRow, vFolioChargesRow);
			vServicesRow.AccountingDate = BegOfDay(vFolioChargesRow.Charge.Date);
			vServicesRow.Sum = vFolioChargesRow.SumBalance;
			vServicesRow.VATSum = vFolioChargesRow.VATSumBalance;
			vServicesRow.Quantity = vFolioChargesRow.QuantityBalance;
			vServicesRow.Price = cmRecalculatePrice(vServicesRow.Sum, vServicesRow.Quantity);
			// Commission
			If ValueIsFilled(vFolioChargesRow.Folio) Then
				vServicesRow.Agent = vFolioChargesRow.Folio.Agent;
			EndIf;
			If ValueIsFilled(vFolioChargesRow.Charge) Then
				vServicesRow.AgentCommissionType = vFolioChargesRow.Charge.AgentCommissionType;
				vServicesRow.AgentCommission = vFolioChargesRow.Charge.AgentCommission;
			EndIf;
			vServicesRow.CommissionSum = vFolioChargesRow.CommissionSumBalance;
			vServicesRow.VATCommissionSum = cmCalculateVATSum(vServicesRow.VATRate, vServicesRow.CommissionSum, vServicesRow.AccountingDate);
			If vServicesRow.CommissionSum = 0 And vServicesRow.VATCommissionSum = 0 And 
			   ValueIsFilled(vServicesRow.AgentCommissionType) Then
				vServicesRow.AgentCommissionType = Undefined;
				vServicesRow.AgentCommission = 0;
			EndIf;				
			// Fill remarks by service description by default
			vServiceDescription = TrimAll(vServicesRow.Service);
			If ValueIsFilled(vServicesRow.Service) Then
				vServiceObj = vServicesRow.Service.GetObject();
				vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
			EndIf;
			vServicesRow.Remarks = vServiceDescription + 
			                       ?(IsBlankString(vServicesRow.Remarks), "", " - " + cmNStr(vServicesRow.Remarks, vLanguage));
								   
			// Calculate correction amount					   
			vCorrectionAmount = vCorrectionAmount + vServicesRow.Sum;
		EndIf;
	EndDo;

	// Return correction amount
	Return -vCorrectionAmount;
EndFunction // GetGroupCorrectionServices

// -----------------------------------------------------------------------------
&AtServer
Function GetFolioCorrectionServices(pFolio)
	vCorrectionAmount = 0;
	vLanguage = SessionParameters.CurrentLanguage;
	
	// Get all current accounts receivable services with balances per end of time
	vCharges = cmGetCurrentAccountsReceivableChargesWithBalances('39991231235959', Object.AccountingCustomer, Object.AccountingContract, , , Object.AccountingCurrency, Object.Hotel, , pFolio);
	For Each vFolioChargesRow In vCharges Do
		If ValueIsFilled(vFolioChargesRow.Charge) Then
			If vFolioChargesRow.Company <> Object.Company Then
				Continue;
			EndIf;
			// Add service
			vServicesRow = Object.Services.Add();
			If ValueIsFilled(vFolioChargesRow.Folio) Then
				vServicesRow.Client = vFolioChargesRow.Folio.Client;
				vServicesRow.Room = vFolioChargesRow.Folio.Room;
			EndIf;
			vParentDoc = vFolioChargesRow.ParentDoc;
			If ValueIsFilled(vParentDoc) Then
				If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or 
				   TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
					vServicesRow.Client = vParentDoc.Guest;
					vServicesRow.Room = vParentDoc.Room;
					vServicesRow.AccommodationType = vParentDoc.AccommodationType;
					vServicesRow.NumberOfPersons = vParentDoc.NumberOfPersons;
				ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
					vServicesRow.Client = vParentDoc.Client;
					vServicesRow.Resource = vParentDoc.Resource;
					vServicesRow.NumberOfPersons = vParentDoc.NumberOfPersons;
				EndIf;
			EndIf;
			FillPropertyValues(vServicesRow, vFolioChargesRow.Charge);
			FillPropertyValues(vServicesRow, vFolioChargesRow);
			vServicesRow.AccountingDate = BegOfDay(vFolioChargesRow.Charge.Date);
			vServicesRow.Sum = vFolioChargesRow.SumBalance;
			vServicesRow.VATSum = vFolioChargesRow.VATSumBalance;
			vServicesRow.Quantity = vFolioChargesRow.QuantityBalance;
			vServicesRow.Price = cmRecalculatePrice(vServicesRow.Sum, vServicesRow.Quantity);
			// Commission
			If ValueIsFilled(vFolioChargesRow.Folio) Then
				vServicesRow.Agent = vFolioChargesRow.Folio.Agent;
			EndIf;
			If ValueIsFilled(vFolioChargesRow.Charge) Then
				vServicesRow.AgentCommissionType = vFolioChargesRow.Charge.AgentCommissionType;
				vServicesRow.AgentCommission = vFolioChargesRow.Charge.AgentCommission;
			EndIf;
			vServicesRow.CommissionSum = vFolioChargesRow.CommissionSumBalance;
			vServicesRow.VATCommissionSum = cmCalculateVATSum(vServicesRow.VATRate, vServicesRow.CommissionSum, vServicesRow.AccountingDate);
			If vServicesRow.CommissionSum = 0 And vServicesRow.VATCommissionSum = 0 And 
			   ValueIsFilled(vServicesRow.AgentCommissionType) Then
				vServicesRow.AgentCommissionType = Undefined;
				vServicesRow.AgentCommission = 0;
			EndIf;				
			// Fill remarks by service description by default
			vServiceDescription = TrimAll(vServicesRow.Service);
			If ValueIsFilled(vServicesRow.Service) Then
				vServiceObj = vServicesRow.Service.GetObject();
				vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
			EndIf;
			vServicesRow.Remarks = vServiceDescription + 
			                       ?(IsBlankString(vServicesRow.Remarks), "", " - " + cmNStr(vServicesRow.Remarks, vLanguage));
								   
			// Calculate correction amount					   
			vCorrectionAmount = vCorrectionAmount + vServicesRow.Sum;
		EndIf;
	EndDo;

	// Return correction amount
	Return -vCorrectionAmount;
EndFunction // GetFolioCorrectionServices

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If ValueIsFilled(pSelectedValue) And TypeOf(pSelectedValue) = Type("DocumentRef.Settlement") Then
		vCurRow = Items.Invoices.CurrentRow;
		If vCurRow <> Undefined Then
			vCurData = Object.Invoices.FindByID(vCurRow);
			vCurData.Invoice = pSelectedValue;
			vCurData.InvoiceSum = tcOnServer.cmGetAttributeByRef(vCurData.Invoice, "Sum");
		EndIf;
	EndIf;
EndProcedure // ChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoicesOnActivateRow(pItem)
	vCurRow = Items.Invoices.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.Invoices.FindByID(vCurRow);
		If vCurData <> Undefined Then
			CurrentGuestGroup = Undefined;
			If ValueIsFilled(vCurData.Invoice) Then
				vGuestGroup = tcOnServer.cmGetAttributeByRef(vCurData.Invoice, "GuestGroup");
				If ValueIsFilled(vGuestGroup) Then
					CurrentGuestGroup = vGuestGroup;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // InvoicesOnActivateRow

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

// -----------------------------------------------------------------------------
&AtClient
Procedure UndoPosting(pCommand)
	UndoPostingAtServer();
	Modified = True;
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
Procedure FillPrintingButton()
	Query = New Query;
	Query.Text = 
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
	
	Query.SetParameter("ObjectType", Documents.CreditNote.EmptyRef());	
	QueryResult = Query.Execute();	
	SelectionRecords = QueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	vLang = Object.GuestGroup.Client.Language;
	While SelectionRecords.Next() Do
		SelectionDetailRecords = SelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = SelectionRecords.Language or not ValueIsFilled(SelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf not vLang = SelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtra,"Print" + SelectionRecords.Language, "FormGroup",
			New Structure("Type,Title",
			FormGroupType.Popup,SelectionRecords.Language));
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
			vStructure = New Structure("Title,CommandName",
			TrimAll(SelectionDetailRecords.Code) + " " + cmNStr(SelectionDetailRecords.ref), "Print" + vID);
			        
			tcOnServer.cmCreateItem(ThisObject, vParent, "Print" + vID, "FormButton", vStructure);
		EndDo;
	EndDo;
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
	ElsIf Left(vPrintForm.PredefinedDataName, 25) = "CreditNotePrintCreditNote" Then
		OpenForm("Document.CreditNote.Form.tcPrintForm", New Structure("CreditNote, Language, PrintForm", Object.Ref, vPrintForm.Language, vPrintForm), ThisObject, Object.Ref);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumber(pActionsNumber)
	vPrintForms = PrintForms.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vPrintForms);
	vStruct.Insert("PredefinedDataName",vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vPrintForms.ExternalProcessing);
	vStruct.Insert("Report",vPrintForms.Report);
	vStruct.Insert("Language",vPrintForms.Language);
	
	Return vStruct;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalReport

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
		vName = ConnectExternalDataProcessor(vURL, GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(pExtProcRef,"FileName")));
		vParams = New Structure("InputParameter, ObjectPrintingForm", Object.Ref, pPrintFormTypeRef);
		OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
	#EndIf
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtServer
Function GetExternalProcessingValidName(Val pStr)
	Return cmGetValidName(pStr); 	
EndFunction // GetExternalProcessingValidName

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
		vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef, "Report"), "ExternalProcessingStorage"); 
		vName = ConnectExternalReport(vURL, "ExternalReportForm");
		vParams = New Structure("Document, ObjectPrintingForm", Object.Ref, pPrintFormTypeRef);
		OpenForm("ExternalReport." + vName + ".Form", vParams);
	#EndIf
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoiceOnChange(pItem)
	// Clear everything
	Object.Invoices.Clear();
	Object.Services.Clear();
	// Fill correction document with corrected services
	If ValueIsFilled(Object.Invoice) Then
		// Fill correction document header attributes
		vInvoiceAttrs = tcOnServer.cmGetAtributeAsArray(Object.Invoice);
		Object.AccountingCustomer = vInvoiceAttrs.AccountingCustomer;
		Object.AccountingContract = vInvoiceAttrs.AccountingContract;
		Object.GuestGroup = vInvoiceAttrs.GuestGroup;
		Object.AccountingCurrency = vInvoiceAttrs.AccountingCurrency;
		Object.Company = vInvoiceAttrs.Company;
		Object.BankAccount = vInvoiceAttrs.BankAccount;
		Object.VATRate = vInvoiceAttrs.VATRate;
		Object.PaymentSection = vInvoiceAttrs.PaymentSection;
		Object.DoNotExportToTheAccountingSystem = vInvoiceAttrs.DoNotExportToTheAccountingSystem;
		// Fill VAT rate
		If Not ValueIsFilled(Object.VATRate) And ValueIsFilled(Object.Company) Then
			Object.VATRate = tcOnServer.cmGetAttributeByRef(Object.Company, "VATRate");
		EndIf;
		// Add row with this particular invoice
		vInvoicesRow = Object.Invoices.Add();
		vInvoicesRow.Invoice = Object.Invoice;
		// Set this row as current
		Items.Invoices.CurrentRow = vInvoicesRow.GetID();
		// Call procedure to fill services by invoice
		InvoicesInvoiceOnChange(Items.InvoicesInvoice);
	EndIf;
EndProcedure // InvoiceOnChange

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
Procedure SetDeletionMarkAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Read();
	vObj.SetDeletionMark(Not vObj.DeletionMark);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // SetDeletionMarkAtServer
