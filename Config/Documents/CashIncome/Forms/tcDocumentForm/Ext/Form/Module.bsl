
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CashIncome"));
	If vObj.IsNew() Then
		// Use current time by default
		vObj.SetTime(AutoTimeMode.CurrentOrLast);
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Fill list of cash registers allowed for the current user
	FillListOfCashRegisters(vObj);
	// Set default cash register
	If vObj.IsNew() Then
		SetDefaultCashRegister(vObj);
	EndIf;
	// Check edit prohibited date
	If ValueIsFilled(vObj.Company) Then
		If ValueIsFilled(vObj.Company.EditProhibitedDate) And 
		   BegOfDay(vObj.Company.EditProhibitedDate) >= BegOfDay(vObj.Date) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	// Set view only mode
	If vObj.Posted Then
		If Not cmCheckUserPermissions("HavePermissionToEditPostedCashIncomeOutcomeTransactions") Then
			ReadOnly = True;
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
		Items.Number.ReadOnly = True;
		Items.Number.Enabled = False;
		Items.Date.ReadOnly = True;
		Items.Date.Enabled = False;
		Items.Date.ChoiceButton = False;
	EndIf;
	// Save current document date
	OldDate = vObj.Date;
	// Cheque was not printed
	ChequeWasPrinted = False;
	// Value to form attribute
	ValueToFormAttribute(vObj, "Object");
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pStandardProcessing)
	pCancel = CancelWrite;
	If CancelWrite Then
		BeforeCloseAtServer(pCancel);
	EndIf;
	// Notify changes
	Notify("Documents.CashIncomeOutcome.Write", Object.Ref, ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	WasPosted = pCurrentObject.Posted;
	// Before posting actions
	vMessage = "";
	vAttributeInErr = "";
	// Check document attributes
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		pCancel = pCurrentObject.pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			vUM = New UserMessage();
			vUM.Field = vAttributeInErr;
			vUM.Text = cmNStr(vMessage);
			vUM.Message();
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	CancelWrite = False;
	// Print cash income cheque at cash register
	vMessage = "";
	If Not WasPosted And Not ChequeWasPrinted And pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		If ValueIsFilled(Object.CashRegister) Then
			If tcOnServer.cmGetAttributeByRef(Object.CashRegister, "IsControlledByProgram") Then
				StartPrintCheque(vMessage);
				If Not IsBlankString(vMessage) Then
					ShowMessageBox(, vMessage);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // AfterWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	CompanyOnChangeAtServer();
EndProcedure // CompanyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure // DateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterOnChange(pItem)
	CashRegisterOnChangeAtServer();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfCashRegisters(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then   
		Items.Company.ReadOnly = False;
		Items.CashRegister.ChoiceList.LoadValues(cmGetListOfAllCashRegisters(vObj.Company).UnloadValues());
	Else   
		Items.Company.ReadOnly = True;
		Items.CashRegister.ChoiceList.LoadValues(cmGetListOfCashRegistersAllowed(, SessionParameters.CurrentWorkstation).UnloadValues());
	EndIf;
	// Check that current cash register is in the list
	If vObj.Posted Then
		If ValueIsFilled(vObj.CashRegister) Then
			If Items.CashRegister.ChoiceList.FindByValue(vObj.CashRegister) = Undefined Then
				Items.CashRegister.ChoiceList.Add(vObj.CashRegister);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillListOfCashRegisters

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDefaultCashRegister(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	If Items.CashRegister.ChoiceList.FindByValue(vObj.CashRegister) = Undefined Then
		vObj.CashRegister = Catalogs.CashRegisters.EmptyRef();
		If Items.CashRegister.ChoiceList.Count() > 0 Then
			vObj.CashRegister = Items.CashRegister.ChoiceList.Get(0).Value;
		EndIf;
	EndIf;
EndProcedure // SetDefaultCashRegister

// -----------------------------------------------------------------------------
&AtServer
Procedure CompanyOnChangeAtServer()
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CashIncome"));
	// Change document number
	If ValueIsFilled(vObj.Company) Then
		If Not IsBlankString(vObj.Company.Prefix) Then
			If Left(vObj.Number, StrLen(TrimR(vObj.Company.Prefix))) <> TrimR(vObj.Company.Prefix) Then
				vObj.SetNewNumber();
			EndIf;
		EndIf;
	EndIf;
	// Fill list of cash registers allowed for the current user
	FillListOfCashRegisters(vObj);
	// Set default cash register
	SetDefaultCashRegister(vObj);
	// Value to form attribute
	ValueToFormAttribute(vObj, "Object");
EndProcedure // CompanyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CashIncome"));
	// Automatically assign new document number if year has changed
	If ValueIsFilled(vObj.Date) And ValueIsFilled(OldDate) Then
		If Year(OldDate) <> Year(vObj.Date) Then
			vObj.SetNewNumber();
		EndIf;
		OldDate = vObj.Date;
	EndIf;
	// Value to form attribute
	ValueToFormAttribute(vObj, "Object");
EndProcedure // DateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure StartPrintCheque(rMessage)
	rMessage = "";
	vDriver = tcOnClient.cmGetModulTO(Object.CashRegister);
	If Not vDriver = Undefined Then
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(, Object.CashRegister);
		If IsBlankString(vPasswordKKM) Then
			// Break before write event and ask user to input cash register password
			CancelWrite = True;
			vNotify = New NotifyDescription("AfterInputCashRegisterPassword", ThisObject, New Structure("Driver, rMessage", vDriver, rMessage));
			vQuestion =  NStr("ru='Пожалуйста введите пароль ККМ...'; 
			                  |de='Input cash register password please...';
			                  |en='Input cash register password please...'");
			OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion), ThisObject, , , , vNotify);
		Else
			vObject = Object;
			CancelWrite = Not vDriver.pmPrintCashIncome(vObject.Sum, vObject, rMessage, vPasswordKKM);
			If Not CancelWrite Then
				ChequeWasPrinted = True;
			EndIf;
		EndIf;
	Else
		// Device driver was not found
		CancelWrite = True;
		rMessage = Nstr("en = 'Work with this device driver is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'");
	EndIf;	
EndProcedure // StartPrintCheque

// -----------------------------------------------------------------------------
&AtClient
Function AfterInputCashRegisterPassword(pValue, pAdditionalParameters) Export
	vDriver = pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.rMessage;
	If Not pValue = Undefined Then
		vPasswordKKM = pValue.Password;
		vObject = Object;
		CancelWrite = Not vDriver.pmPrintCashIncome(vObject.Sum, vObject, vMessage, vPasswordKKM);
		If Not CancelWrite Then
			ChequeWasPrinted = True;
			Write(New Structure("WriteMode", DocumentWriteMode.Posting));
			Close();
		Else
			If Not IsBlankString(vMessage) Then
				ShowMessageBox(, vMessage);
			EndIf;
		EndIf;
	EndIf;
EndFunction // AfterInputCashRegisterPassword

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeCloseAtServer(pCancel)
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CashIncome"));
	// Cancel posting if was posted
	If CancelWrite And vObj.Posted Then
		vObj.Write(DocumentWriteMode.UndoPosting);
	EndIf;
	CancelWrite = False;
	// Value to form attribute
	ValueToFormAttribute(vObj, "Object");
EndProcedure

&AtServer
Procedure CashRegisterOnChangeAtServer()
	// Fill company
	If ValueIsFilled(Object.CashRegister) Then
		Object.Company = Object.CashRegister.Owner;
	Else
		Object.Company = Catalogs.Companies.EmptyRef();
	EndIf;
EndProcedure


#EndRegion
