
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Save current user
	CurrentUser = SessionParameters.CurrentUser;
	
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		vObject = FormAttributeToValue("Object");
		
		If Not ValueIsFilled(Object.Author) Then
			vObject.pmFillAttributesWithDefaultValues();
		Else
			vObject.pmFillAuthorAndDate();
		EndIf;
		
		// Check parameters
		If Parameters.Property("AccountingContract") Then
			If ValueIsFilled(Parameters.AccountingContract) Then
				vObject.OperationType = Enums.AdvanceDistributionTypes.ByGroups;
				vObject.Fill(Parameters.AccountingContract);
			EndIf;
		ElsIf Parameters.Property("AccountingCustomer") Then
			If ValueIsFilled(Parameters.AccountingCustomer) Then
				vObject.OperationType = Enums.AdvanceDistributionTypes.ByGroups;
				vObject.Fill(Parameters.AccountingCustomer);
			EndIf;
		EndIf;
		If Parameters.Property("Invoices") Then
			If TypeOf(Parameters.Invoices) = Type("ValueList") Then
				vObject.OperationType = Enums.AdvanceDistributionTypes.BySettlementInvoices;
				vObject.GuestGroups.Clear();
				vSumAdvance = vObject.SumAdvance;
				For Each vInvoiceItem In Parameters.Invoices Do
					vInvoice = vInvoiceItem.Value;
					
					vRow = vObject.GuestGroups.Add();
					vRow.Invoice = vInvoice;
					vRow.AccountingContract = vInvoice.AccountingContract;
					vRow.GuestGroup = vInvoice.GuestGroup;
					vRow.Sum = ?(vSumAdvance > vInvoice.SumDue, vInvoice.SumDue, vSumAdvance);
					vRow.Balance = vInvoice.SumDue;
					
					vSumAdvance = vSumAdvance - vRow.Sum;
				EndDo;
			EndIf;
		EndIf;
		ValueToFormAttribute(vObject, "Object");
	EndIf;

	Rest = Object.SumAdvance - Object.GuestGroups.Total("Sum");
	
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
	
	// Fill guest group description
	GuestGroupDis();
	
	// Write to last visited objects
	If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
		Items.Number.ReadOnly = True;
		Items.Number.Enabled = False;
	EndIf;
	FormVisible();	
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	ClearMessages();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	SetObjectAndFormAttributeConformity(pCurrentObject, "Object");
	
	If EditNumber Then
		pCurrentObject.SetNewNumber();
		EditNumber = False;
	EndIf;
	
	vMessage = "";
	vAttributeInErr = "";
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		pCancel = pCurrentObject.pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, pCurrentObject.Metadata(), pCurrentObject.Ref, NStr(vMessage));
			
			vUserMessage = New UserMessage;
			vUserMessage.SetData(pCurrentObject);
			vUserMessage.Field = vAttributeInErr;
			vUserMessage.Text = NStr(vMessage);
			vUserMessage.Message();
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	// Notify changes in the accounts subsystem
	Notify("Subsystem.Accounts.Changed");
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

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	HotelOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	If ValueIsFilled(Object.Company) Then
		FillActionAtServer();
		EditNumber = True;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingCurrencyOnChange(pItem)
	If ValueIsFilled(Object.AccountingCurrency) Then
		FillActionAtServer();
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingCustomerOnChange(pItem)
	If ValueIsFilled(Object.AccountingCustomer) Then
		FillActionAtServer();
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingContractOnChange(pItem)
	FillActionAtServer();
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
	GuestGroupOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ProformaInvoiceOnChange(pItem)
	FillActionAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ProformaInvoiceStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vFilter = New Structure("SelFilterStatus,SelGuestGroup,SelCustomer", 2, Object.GuestGroup, Object.AccountingCustomer);
	vParam = New Structure("FillingValues,SelHotel,ChoiceMode", vFilter, Object.Hotel, True);
	OpenForm("Document.ProformaInvoice.Form.tcListForm", vParam, pItem);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ProformaInvoiceClearing(pItem, pStandardProcessing)
	FillActionAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentOnChange(pItem)
	FillActionAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OperationTypeOnChange(pItem)
	Object.GuestGroups.Clear();
	FillActionAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("DocumentJournal.CustomerAccountsJournal.ListForm", New Structure("ChoiceMode, Filter", True, New Structure("Hotel, Customer, Contract, GuestGroup", Object.Hotel, Object.AccountingCustomer, Object.AccountingContract, Object.GuestGroup)), pItem);
EndProcedure // PaymentStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupsOnEditEnd(pItem, pNewRow, pCancelEdit)
	Rest = Object.SumAdvance - Object.GuestGroups.Total("Sum");
EndProcedure // GuestGroupsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupsAfterDeleteRow(pItem)
	Rest = Object.SumAdvance - Object.GuestGroups.Total("Sum");
EndProcedure // GuestGroupsAfterDeleteRow

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FillAction(pCommand)
	FillActionAtServer();
EndProcedure

#EndRegion

#Region Private

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
Procedure OnCloseAtServer()
	If ValueIsFilled(CurrentUser) Then
		SessionParameters.CurrentUser = CurrentUser;
	EndIf;
EndProcedure // OnCloseAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillActionAtServer()
	// Clear guest groups
	Object.GuestGroups.Clear();
	// Refill guest groups
	If ValueIsFilled(Object.ProformaInvoice) Then
		vObject = FormAttributeToValue("Object");
		vObject.pmFillByProformaInvoice(Object.ProformaInvoice);
		ValueToFormAttribute(vObject,"Object");
		
	ElsIf ValueIsFilled(Object.Payment) Then
		vObject = FormAttributeToValue("Object");
		vObject.pmFillByPayment(Object.Payment);
		ValueToFormAttribute(vObject,"Object");
		
	ElsIf ValueIsFilled(Object.GuestGroup) Then
		vObject = FormAttributeToValue("Object");
		vObject.pmFillByGuestGroup(Object.GuestGroup);
		ValueToFormAttribute(vObject,"Object");
		
	ElsIf ValueIsFilled(Object.AccountingContract) Then
		vObject = FormAttributeToValue("Object");
		vObject.pmFillByContract(Object.AccountingContract);
		ValueToFormAttribute(vObject,"Object");
		
	ElsIf ValueIsFilled(Object.AccountingCustomer) Then
		vObject = FormAttributeToValue("Object");
		vObject.pmFillByCustomer(Object.AccountingCustomer);
		ValueToFormAttribute(vObject,"Object");
		
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Fill customer first!';ru='Контрагент должен быть выбран!';de='Partner muss gewählt sein!'"));
	EndIf;

	Rest = Object.SumAdvance - Object.GuestGroups.Total("Sum");
	
	FormVisible();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GuestGroupDis()
	If ValueIsFilled(Object.GuestGroup) Then
		Items.GuestGroup.ToolTip = TrimAll(Object.GuestGroup.Description);
	Else
		Items.GuestGroup.ToolTip = "";
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()
	If ValueIsFilled(Object.Hotel) Then
		EditNumber = True;
		FillActionAtServer();
	Else		
		If ValueIsFilled(Object.AccountingContract) Then
			vObject = FormAttributeToValue("Object");
			vObject.pmFillByContract(Object.AccountingContract);
			ValueToFormAttribute(vObject,"Object");
		ElsIf ValueIsFilled(Object.AccountingCustomer) Then
			vObject = FormAttributeToValue("Object");
			vObject.pmFillByCustomer(Object.AccountingCustomer);
			ValueToFormAttribute(vObject,"Object");
		EndIf;
		// Remove rows with empty invoice and guest group
		i = 0;
		While i < Object.GuestGroups.Count() Do
			vGroupRow = Object.GuestGroups.Get(i);
			If Not ValueIsFilled(vGroupRow.Invoice) And Not ValueIsFilled(vGroupRow.GuestGroup) Then
				Object.GuestGroups.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FormVisible()
	If ValueIsFilled(Object.ProformaInvoice) Then
		Items.ProformaInvoice.ReadOnly    = False;
		Items.Payment.ReadOnly            = True;
		Items.GuestGroup.ReadOnly         = True;
		Items.AccountingContract.ReadOnly = True;
		Items.AccountingCustomer.ReadOnly = True;
		
	ElsIf ValueIsFilled(Object.Payment) Then
		Items.ProformaInvoice.ReadOnly    = False;
		Items.Payment.ReadOnly            = False;
		Items.GuestGroup.ReadOnly         = True;
		Items.AccountingContract.ReadOnly = True;
		Items.AccountingCustomer.ReadOnly = True;
			
	ElsIf ValueIsFilled(Object.GuestGroup) Then
		Items.ProformaInvoice.ReadOnly    = False;
		Items.Payment.ReadOnly            = False;
		Items.GuestGroup.ReadOnly         = False;
		Items.AccountingContract.ReadOnly = True;
		Items.AccountingCustomer.ReadOnly = True;
		
	ElsIf ValueIsFilled(Object.AccountingContract) Then
		Items.ProformaInvoice.ReadOnly    = False;
		Items.Payment.ReadOnly            = False;
		Items.GuestGroup.ReadOnly         = False;
		Items.AccountingContract.ReadOnly = False;
		Items.AccountingCustomer.ReadOnly = True;
		
	ElsIf ValueIsFilled(Object.AccountingCustomer) Then
		Items.ProformaInvoice.ReadOnly    = False;
		Items.Payment.ReadOnly            = False;
		Items.GuestGroup.ReadOnly         = False;
		Items.AccountingContract.ReadOnly = False;
		Items.AccountingCustomer.ReadOnly = False;
		
	Else
		Items.ProformaInvoice.ReadOnly    = False;
		Items.Payment.ReadOnly            = False;
		Items.GuestGroup.ReadOnly         = False;
		Items.AccountingContract.ReadOnly = False;
		Items.AccountingCustomer.ReadOnly = False;
		
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GuestGroupOnChangeAtServer()
	GuestGroupDis();
	FillActionAtServer();	
EndProcedure

#EndRegion
