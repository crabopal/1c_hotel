
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;

	// Fill attributes with default values
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CloseOfPeriod"));
	If vObj.IsNew() Then
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;
	EndIf;
	
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(vObj.Hotel) And SessionParameters.CurrentHotel <> vObj.Hotel Then
			pCancel = True;
			Return;
		EndIf;
	EndIf;	
	
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	// Check edit prohibited date
	If ValueIsFilled(vObj.Hotel) Then
		If ValueIsFilled(vObj.Hotel.EditProhibitedDate) And 
		   BegOfDay(vObj.Hotel.EditProhibitedDate) >= BegOfDay(vObj.Date) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	If ValueIsFilled(vObj.Company) Then
		If ValueIsFilled(vObj.Company.EditProhibitedDate) And 
		   BegOfDay(vObj.Company.EditProhibitedDate) >= BegOfDay(vObj.Date) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	
	// Set document number and date appearances
	If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
		Items.Number.ReadOnly = True;
		Items.Number.Enabled = False;
		Items.Date.ReadOnly = True;
		Items.Date.Enabled = False;
		Items.Date.ChoiceButton = False;
	EndIf;
	
	// Save current document date
	OldDate = vObj.Date;
	
	// Restore form attribute
	ValueToFormAttribute(vObj, "Object");
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	RefreshItemsAppearance();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	Var vMessage; 
	Var vAttributeInErr;
	// Before posting actions
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// APDEX
		vKeyOperation = "Document.CloseOfPeriod.Form.tcDocumentForm.Posting";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
		
		// Check document attributes
		pCancel = CheckDocumentAttributesAtServer(vMessage, vAttributeInErr);
		If pCancel Then
			tcCommonFunctionOnClientServer.UserMessage(NStr(vMessage));
		Else
			// Always undo posting first to repost document
			If Object.Posted Then
				pWriteParameters.WriteMode = DocumentWriteMode.Write;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	// Notify changes in the accounts subsystem
	Notify("Subsystem.Accounts.Changed");
EndProcedure // AfterWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	// Automatically assign new document number if year has changed
	If ValueIsFilled(Object.Date) And ValueIsFilled(OldDate) Then
		If Year(OldDate) <> Year(Object.Date) Then
			SetNewNumberAtServer();
		EndIf;
		OldDate = Object.Date;
	EndIf;
EndProcedure // DateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	If ValueIsFilled(Object.Company) Then
		CompanyOnChangeAtServer();
	EndIf;
EndProcedure // CompanyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AttributesOnChange(pItem)
	RefreshItemsAppearance();
EndProcedure // AttributesOnChange

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributesAtServer(vMessage, vAttributeInErr)
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CloseOfPeriod"));
	Return vObj.pmCheckDocumentAttributes(vMessage, vAttributeInErr);
EndFunction // CheckDocumentAttributesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetNewNumberAtServer()
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CloseOfPeriod"));
	vObj.SetNewNumber();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // SetNewNumberAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CompanyOnChangeAtServer()
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CloseOfPeriod"));
	vObj.pmFillByCompany(vObj.Company);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // CompanyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshItemsAppearance()
	// Check close of period parameters
	If Object.OneSettlementPerCustomerGuestGroups Then
		Items.OneSettlementPerCustomerGuestGroups.Enabled = True;
		Items.OneSettlementPerIndividualsCustomerGuestGroups.Enabled = False;
		If Object.OneSettlementPerIndividualsCustomerGuestGroups Then
			Object.OneSettlementPerIndividualsCustomerGuestGroups = False;
		EndIf;
	ElsIf Object.OneSettlementPerIndividualsCustomerGuestGroups Then
		Items.OneSettlementPerCustomerGuestGroups.Enabled = False;
		Items.OneSettlementPerIndividualsCustomerGuestGroups.Enabled = True;
		If Object.OneSettlementPerCustomerGuestGroups Then
			Object.OneSettlementPerCustomerGuestGroups = False;
		EndIf;
	Else
		Items.OneSettlementPerCustomerGuestGroups.Enabled = True;
		Items.OneSettlementPerIndividualsCustomerGuestGroups.Enabled = True;
	EndIf;
EndProcedure // RefreshItemsAppearance

#EndRegion
