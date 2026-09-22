
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToPrintCashRegisterZReport") Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to close cash register days!';ru='Нет прав на закрытие кассовых смен!';de='Sie haben keine Rechte, Kassenschichten zu schließen!'"));
		Return;
	EndIf;
	
	If Object.Ref.IsEmpty() And Not ValueIsFilled(Object.Author) Then
		Object.Date = CurrentSessionDate();
		Object.Author = SessionParameters.CurrentUser;
		// Fill from session parameters
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			If ValueIsFilled(SessionParameters.CurrentHotel.Company) Then
				Object.Company = SessionParameters.CurrentHotel.Company;
			EndIf;
		EndIf;
	EndIf;
	
	// Check parameters
	PostAndCloseOnOpen = False;
	If Parameters.Property("PostAndCloseOnOpen") Then
		PostAndCloseOnOpen = Parameters.PostAndCloseOnOpen;
	EndIf;
	
	FillListOfCashRegisters();
	If Object.Ref.IsEmpty() Then
		If Not ValueIsFilled(Object.CashRegister) Then
			If CashRegistersList.Count() = 1 Then
				Object.CashRegister = CashRegistersList.Get(0).Value;
				CashRegisterOnChangeAtServer();
			Else
				// Fill from session parameters
				If Not ValueIsFilled(Object.Company) Then
					If ValueIsFilled(SessionParameters.CurrentHotel) Then
						If ValueIsFilled(SessionParameters.CurrentHotel.Company) Then
							Object.Company = SessionParameters.CurrentHotel.Company;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	Else
		Items.PostAndClose.Title = NStr("en='Print Z-Report'; ru='Печать Z-Отчета'; de='Z-Bericht drucken'");
	EndIf;
	
	// Set close of cash register day end date appearance
	If cmCheckUserPermissions("HavePermissionToEditCloseOfCashRegisterDayDate") Then
		Items.Date.ReadOnly = False;
		Items.AccountingDate.ReadOnly = False;
	Else
		Items.Date.ReadOnly = True;
		Items.AccountingDate.ReadOnly = True;
	EndIf;
	
	// Z-Report type
	ZReportType = Object.ZReportType;
	
	// Set view only mode
	If Object.Posted Then
		If Not cmCheckUserPermissions("HavePermissionToEditPostedCloseOfCashRegisterDayDocuments") Then
			Items.GroupHead.ReadOnly = True;
			Items.Company.ReadOnly = True;
			Items.GroupCashRegister.ReadOnly = True;
			Items.DateFrom.ReadOnly = True;
			Items.Date.ReadOnly = True;
			Items.Remarks.ReadOnly = True;
			Items.Pages.ReadOnly = True;
			Items.AccountingTotalsClearAccountingTotals.Enabled = False;
			Items.PostAndClose.Title = NStr("en='Reprint Z-Report';ru='Повторная печать Z-Отчета';de='Den Druck des Z-Berichts wiederholen'");
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToPrintCashRegisterXReport") Then
		Items.PostAndClose.Visible = False;
	EndIf;
	
	// Set parameters for Dynamic list
	TotalList.Parameters.SetParameterValue("qCompany", Object.Company);
	TotalList.Parameters.SetParameterValue("qCashRegister", Object.CashRegister);
	TotalList.Parameters.SetParameterValue("qDateFrom", Object.DateFrom);
	TotalList.Parameters.SetParameterValue("qDateTo", Object.Date);
	
	If Not IsInRole("Administrator") Then
		Items.AccountingTotalsClearAccountingTotals.Enabled = False;
	EndIf;	
	Items.TotalList.Refresh();
	SkipCheckUnprintedCheque = False;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If Object.Ref.IsEmpty() And Not ValueIsFilled(Object.CashRegister) Then
		If CashRegistersList.Count() > 1 Then
			AttachIdleHandler("OpenCashRegistersList", 0.1, True);
		Else
			vUserChoiceItem = Undefined;
			If CashRegistersList.Count() > 0 Then
				vUserChoiceItem = CashRegistersList.Get(0);
			EndIf;
			OnOpenAfterCashRegisterUserChoice(vUserChoiceItem, New Structure());
		EndIf;
	Else
		If PostAndCloseOnOpen Then
			If ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
				pCancel = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, WriteParameters)
	WasPosted = Object.Posted;
	pCashRegister = tcOnServer.cmGetAtributeAsArray(Object.CashRegister);
	// Before posting actions
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// Check document attributes
		vMessage = "";
		pCancel = CheckDocumentAttributes(vMessage);
		If pCancel Then
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Write';ru='Документ.Запись';de='Document.Write'"), , , , NStr(vMessage));
			ShowMessageBox(, NStr(vMessage), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Else
			If Not WasPosted Then
				If pCashRegister.IsControlledByProgram And pCashRegister.CheckUnprintedCheques And Not SkipCheckUnprintedCheque And CheckUnprintedCheques(Object.CashRegister, Object.DateFrom, Object.Date) Then
					pCancel = True;
					OpenForm("CommonForm.tcPrintUnprintedChequeForm", New Structure("IsCloseOfCashRegisterDay, SelCashRegister, SelDateFrom, SelDateTo", True, Object.CashRegister, Object.DateFrom, Object.Date), ThisForm, UUID, , , New NotifyDescription("AfterPrintUnprintedCheques", ThisForm));
					Return;
				EndIf;
				If pCashRegister.IsControlledByProgram And Not pCashRegister.DoNotPrintZReportAutomatically Then
					// Check if cash register is ready to print Z-report
					If Not IsReadyToPrint(vMessage, Object.CashRegister) Then
						pCancel = True;
						tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.CheckDeviceSession';ru='ККМ.ПроверитьВозможностьЗакрытияСессииПоФР';de='CashRegister.CheckDeviceSession'"), , ,, vMessage);
						ShowMessageBox(, vMessage, , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
						Return;	
					EndIf;
					DoReconcileTotalsOnTerminal();
					//////////////////////////////////////////
					// Print Z-report
					//////////////////////////////////////////
					CloseDeviceSession(vMessage, Object, pCancel);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	If SetNewDocNumber Then
		CurrentObject.SetNewNumber();
		SetNewDocNumber = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(WriteParameters)
	PrintZReport();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(Item)
	// Automatically assign new document number if year has changed
	If ValueIsFilled(Object.Date) And ValueIsFilled(OldDate) Then
		If Year(OldDate) <> Year(Object.Date) Then
			SetNewDocNumber = True;
		EndIf;
		OldDate = Object.Date;
	EndIf;
	// Fill cash register day totals
	FillTotalsTable();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterOnChange(pItem)
	CashRegisterOnChangeAtServer();
	FillTotalsTable();
EndProcedure // CashRegisterOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	CompanyOnChangeAtServer();
	FillTotalsTable();
EndProcedure // CompanyOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearAccountingTotals(Command)
	Object.AccountingTotals.Clear();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenCashRegistersList() 
	CashRegistersList.ShowChooseItem(New NotifyDescription("OnOpenAfterCashRegisterUserChoice", ThisForm, New Structure()), NStr("en='Select cash register please!';ru='Выберите ККМ!';de='Wählen Sie Registrierkasse!'"), CashRegistersList.FindByValue(Object.CashRegister));
EndProcedure // OpenCashRegistersList

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpenAfterCashRegisterUserChoice(pUserChoiceItem, pExtraParameters) Export
	If pUserChoiceItem <> Undefined Then
		Object.CashRegister = pUserChoiceItem.Value;
		CashRegisterOnChangeAtServer();
		FillTotalsTable();
	Else 
		Cancel = True;
	EndIf;
EndProcedure // OnOpenAfterCashRegisterUserChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure CashRegisterOnChangeAtServer()
	// Fill end of shift
	If Not ValueIsFilled(Object.Ref) And ValueIsFilled(Object.CashRegister) Then
		If ValueIsFilled(Object.CashRegister.Hotel) And ValueIsFilled(Object.CashRegister.Hotel.AccountingDate) Then
			Object.AccountingDate = Object.CashRegister.Hotel.AccountingDate;
		Else
			Object.AccountingDate = BegOfDay(CurrentSessionDate());
		EndIf;
	EndIf;
	// Fill company
	If ValueIsFilled(Object.CashRegister) Then
		Object.Company = Object.CashRegister.Owner;
	Else
		Object.Company = Catalogs.Companies.EmptyRef();
	EndIf;
	// Check cash register prefix 
	If SavCashRegister <> Object.CashRegister And Not IsBlankString(Object.CashRegister.CloseOfCashRegisterDayPrefix) Then
		If Left(Object.Number, StrLen(TrimR(Object.CashRegister.CloseOfCashRegisterDayPrefix))) <> TrimR(Object.CashRegister.CloseOfCashRegisterDayPrefix) Then
			SetNewDocNumber = True;
		EndIf;
	Else
		If ValueIsFilled(Object.Company) Then
			If Not IsBlankString(Object.Company.Prefix) Then
				If Left(Object.Number, StrLen(TrimR(Object.Company.Prefix))) <> TrimR(Object.Company.Prefix) Then
					SetNewDocNumber = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	SavCashRegister = Object.CashRegister;
	// Reset date from
	Object.DateFrom = Undefined;
	// Fill cash register day from date
	FillDateFrom();
	// Fill default Z-Report type
	If ValueIsFilled(Object.CashRegister) Then
		If ValueIsFilled(Object.CashRegister.ZReportType) Then
			Object.ZReportType = Object.CashRegister.ZReportType;
		EndIf;
	EndIf;
EndProcedure // CashRegisterOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDateFrom()
	vObj = FormAttributeToValue("Object");
	If Not ValueIsFilled(vObj.DateFrom) Then
		If ValueIsFilled(vObj.CashRegister) Then
			vDateFrom = vObj.pmCalculateDateFrom(vObj.Date);
			If Not ValueIsFilled(vDateFrom) Then
				vObj.DateFrom = vObj.Date - 24*3600;
			Else
				vObj.DateFrom = vDateFrom;
			EndIf;
		EndIf;
	EndIf;
	ValueToFormAttribute(vObj,"Object");
EndProcedure // FillDateFrom

// -----------------------------------------------------------------------------
&AtClient
Procedure FillTotalsTable()
	// Set parameters for Dynamic list
	TotalList.Parameters.SetParameterValue("qCompany", Object.Company);
	TotalList.Parameters.SetParameterValue("qCashRegister", Object.CashRegister);
	TotalList.Parameters.SetParameterValue("qDateFrom", Object.DateFrom);
	TotalList.Parameters.SetParameterValue("qDateTo", Object.Date);
	Items.TotalList.Refresh();
EndProcedure // FillTotalsTable

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfCashRegisters(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		Items.Company.ReadOnly = False;
		CashRegistersList = cmGetListOfAllCashRegisters(vObj.Company);
	Else
		CashRegistersList = cmGetListOfCashRegistersAllowed(, SessionParameters.CurrentWorkstation);
	EndIf;
	// Check that current cash register is in the list
	If vObj.Posted Then
		If ValueIsFilled(vObj.CashRegister) Then
			If CashRegistersList.FindByValue(vObj.CashRegister) = Undefined Then
				CashRegistersList.Add(vObj.CashRegister);
			EndIf;
		EndIf;
	EndIf;
	// Attach list to the item
	Items.CashRegister.ChoiceList.LoadValues(CashRegistersList.UnloadValues());
EndProcedure // FillListOfCashRegisters

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterPrintUnprintedCheques(pCloseOfShift, pExtraParams) Export 
	If pCloseOfShift <> Undefined And pCloseOfShift Then
		SkipCheckUnprintedCheque = True;
		If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Close();	
		EndIf;	
	EndIf;
EndProcedure // AfterPrintUnprintedChecks
	
// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckUnprintedCheques(pCashRegister, pDateFrom, pDateTo)
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	CashRegisters.Ref AS Ref
	|INTO CashRegistersList
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	CASE
	|			WHEN &qCashRegister <> VALUE(Catalog.CashRegisters.EmptyRef)
	|				THEN CashRegisters.Ref = &qCashRegister
	|			ELSE TRUE
	|		END
	|	AND CashRegisters.IsControlledByProgram
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PaymentsList.Ref AS Document,
	|	PaymentsList.CashRegister AS CashRegisters,
	|	FALSE AS IsUse,
	|	18 AS Status
	|FROM
	|	Document.Payment AS PaymentsList
	|		INNER JOIN Catalog.PaymentMethods AS PaymentMethods
	|		ON PaymentsList.PaymentMethod = PaymentMethods.Ref
	|			AND (PaymentMethods.PrintCheque)
	|			AND (PaymentMethods.BookByCashRegister)
	|			AND (NOT PaymentMethods.PrintNonFiscalCheque)
	|		INNER JOIN CashRegistersList AS CashRegistersList
	|		ON PaymentsList.CashRegister = CashRegistersList.Ref
	|		LEFT JOIN InformationRegister.ChequeAttributes AS ChequeAttributes
	|		ON PaymentsList.Ref = ChequeAttributes.Payment
	|WHERE
	|	PaymentsList.Posted
	|	AND CASE
	|			WHEN &qDateFrom <> DATETIME(1, 1, 1, 0, 0, 0)
	|				THEN PaymentsList.Date >= &qDateFrom
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qDateTo <> DATETIME(1, 1, 1, 0, 0, 0)
	|				THEN PaymentsList.Date <= &qDateTo
	|			ELSE TRUE
	|		END
	|	AND (ChequeAttributes.Payment IS NULL
	|			OR ChequeAttributes.ChequeFiscalNumber = """")
	|
	|UNION ALL
	|
	|SELECT
	|	ReturnList.Ref,
	|	ReturnList.CashRegister,
	|	FALSE,
	|	18
	|FROM
	|	Document.Return AS ReturnList
	|		INNER JOIN Catalog.PaymentMethods AS PaymentMethods
	|		ON ReturnList.PaymentMethod = PaymentMethods.Ref
	|			AND (PaymentMethods.PrintCheque)
	|			AND (PaymentMethods.BookByCashRegister)
	|			AND (NOT PaymentMethods.PrintNonFiscalCheque)
	|		INNER JOIN CashRegistersList AS CashRegistersList
	|		ON ReturnList.CashRegister = CashRegistersList.Ref
	|		LEFT JOIN InformationRegister.ChequeAttributes AS ChequeAttributes
	|		ON ReturnList.Ref = ChequeAttributes.Payment
	|WHERE
	|	ReturnList.Posted
	|	AND CASE
	|			WHEN &qDateFrom <> DATETIME(1, 1, 1, 0, 0, 0)
	|				THEN ReturnList.Date >= &qDateFrom
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qDateTo <> DATETIME(1, 1, 1, 0, 0, 0)
	|				THEN ReturnList.Date <= &qDateTo
	|			ELSE TRUE
	|		END
	|	AND (ChequeAttributes.Payment IS NULL
	|			OR ChequeAttributes.ChequeFiscalNumber = """")
	|
	|UNION ALL
	|
	|SELECT
	|	CustomerPaymentList.Ref,
	|	CustomerPaymentList.CashRegister,
	|	FALSE,
	|	18
	|FROM
	|	Document.CustomerPayment AS CustomerPaymentList
	|		INNER JOIN Catalog.PaymentMethods AS PaymentMethods
	|		ON CustomerPaymentList.PaymentMethod = PaymentMethods.Ref
	|			AND (PaymentMethods.PrintCheque)
	|			AND (PaymentMethods.BookByCashRegister)
	|			AND (NOT PaymentMethods.PrintNonFiscalCheque)
	|		INNER JOIN CashRegistersList AS CashRegistersList
	|		ON CustomerPaymentList.CashRegister = CashRegistersList.Ref
	|		LEFT JOIN InformationRegister.ChequeAttributes AS ChequeAttributes
	|		ON CustomerPaymentList.Ref = ChequeAttributes.Payment
	|WHERE
	|	CustomerPaymentList.Posted
	|	AND (ChequeAttributes.Payment IS NULL
	|			OR ChequeAttributes.ChequeFiscalNumber = """")";
	vQuery.SetParameter("qCashRegister", pCashRegister);
	vQuery.SetParameter("qDateFrom", pDateFrom);
	vQuery.SetParameter("qDateTo", pDateTo);
	vPayments = vQuery.Execute();
	Return Not vPayments.IsEmpty(); 
EndFunction // CheckUnprintedChecks

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributes(rMessage)
	vObj = FormAttributeToValue("Object");	
		
	rMessage = "";
	If vObj.pmCheckDocumentAttributes(rMessage, "") Then
		Return True;
	EndIf;	
	
	Return False;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Function IsReadyToPrint(rMessage, pCashRegister)
	rMessage = "";
	
	If Not ValueIsFilled(pCashRegister) Then
		Return False;
	EndIf;
	
	vDriver = tcOnClient.cmGetModulTO(pCashRegister);

	If Not vDriver = Undefined Then
		Return vDriver.pmIsReadyToPrint(rMessage, True ,pCashRegister);
	Else
		ShowMessageBox(,Nstr("en = 'Work with this device is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;	
	Return  False;
EndFunction //  IsReadyToPrintCheque()

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseDeviceSession(rMessage, pObject, pCancel)
	pCancel = True;
	rMessage = "";
	vCashRegister = pObject.CashRegister;
	vDriver = tcOnClient.cmGetModulTO(vCashRegister);
	If Not vDriver = Undefined Then
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(True, vCashRegister);
		If IsBlankString(vPasswordKKM) Then
			vQuestion =  NStr("ru='Пожалуйста введите пароль ККМ...'; 
							  |de='Input cash register password please...';
							  |en='Input cash register password please...'");
			vNotifity = New NotifyDescription("AfterInputCashRegisterPassword", ThisForm, New Structure("Driver,rMessage,pObject", vDriver, rMessage, pObject));
			// Show InputCashRegisterPassword
			OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion), ThisForm, , , ,vNotifity);
		Else
			If Not vDriver.pmPrintZReport(rMessage, pObject, vPasswordKKM) Then
				pCancel = True;
				ShowMessageBox(, rMessage, , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
			Else
				If WriteAtServer(rMessage) Then
					Modified = False;
					PrintZReport();
					Close();
				Else
					ShowMessageBox(, rMessage, , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'")); 
				EndIf;
			EndIf;
		EndIf;
	Else
		pCancel = True;
		ShowMessageBox(, Nstr("en = 'Work with this device is not supported'; 
						|ru = 'Работа с драйвером этого устройства не поддерживается'; 
						|de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DoReconcileTotalsOnTerminal()
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(Object.CashRegister);
	If Not vArrCashRegister.DoAutomaticallyReconcileTotals Then
		Return;	
	EndIf;
	
	vPaymentTerminalArr = GetCreditCardsProcessingSystemAllList();
	If vPaymentTerminalArr.Count() = 0 Then  
		Return;	
	EndIf;  
	
	For Each vPaymentTerminal In vPaymentTerminalArr Do
		vDriver = tcOnClient.cmGetModulTO(vPaymentTerminal);
		If vDriver = Undefined Then
			ShowUserNotification(NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"),,Nstr("en = 'Work with this device driver is not supported'; 
								  |de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'; 
								  |ru = 'Работа с драйвером этого терминала не поддерживается'"),, UserNotificationStatus.Important, TrimAll(vPaymentTerminal.UUID()));  
			Continue;
		EndIf;
		
		vResult = True;
		vDriver.ReconcileTotals(, vArrCashRegister, GetCreditCardsProcessingSystemParameters(vPaymentTerminal), vResult);
		If Not vResult Then
			ShowUserNotification(TrimAll(vPaymentTerminal),, NStr("en = 'Reconcile of totals on the terminal ended with an error!'; de = 'Summenabgleich am Terminal mit Fehler beendet!'; ru = 'Сверка итогов на терминале завершилась ошибкой!'"),, UserNotificationStatus.Important, TrimAll(vPaymentTerminal.UUID()));		
		EndIf;
	EndDo;
EndProcedure // DoReconcileTotalsOnTerminal

// -----------------------------------------------------------------------------
&AtServer
Function GetCreditCardsProcessingSystemParameters(pPaymentTerminal)
	vArrPaymentTerminal = tcOnServer.cmGetAtributeAsArray(pPaymentTerminal);
	vArrPaymentTerminal.ConnectionParameters = vArrPaymentTerminal.ConnectionParameters.Get();
	Return vArrPaymentTerminal;
EndFunction	// GetCreditCardsProcessingSystemParameters

// -----------------------------------------------------------------------------
&AtServer
Function GetCreditCardsProcessingSystemAllList() 
	vCurrentWorkstation = SessionParameters.CurrentWorkstation;
	If Not ValueIsFilled(vCurrentWorkstation) Then
		Return New Array;	
	EndIf; 
	
	vQry = New Query; 
	vQry.Text = 
	"SELECT
	|	ConnectedDevices.DeviceSettings AS DeviceSettings
	|FROM
	|	InformationRegister.ConnectedDevices AS ConnectedDevices
	|WHERE
	|	ConnectedDevices.Workstation = &qCurrentWorkstation
	|	AND ConnectedDevices.DeviceType = &qCreditCardProcessingSystem
	|	AND ConnectedDevices.IsActive
	|	AND (ConnectedDevices.DeviceSettings.Company = VALUE(Catalog.Companies.EmptyRef)
	|			OR ConnectedDevices.DeviceSettings.Company = &qCompany)";
	vQry.SetParameter("qCurrentWorkStation", SessionParameters.CurrentWorkstation);
	vQry.SetParameter("qCreditCardProcessingSystem", Enums.DeviceTypes.CreditCardsProcessingSystemParameters);
	vQry.SetParameter("qCompany", Object.Company);	
	Return vQry.Execute().Unload().UnloadColumn(0);	
EndFunction // GetCreditCardsProcessingSystemAllList

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterInputCashRegisterPassword(pValue, pAdditionalParameters) Export
	vDriver = pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.rMessage;
	If Not pValue = Undefined Then
		ZReportIsPrinted = vDriver.pmPrintZReport(vMessage, pAdditionalParameters.pObject, pValue.Password); 
		If ZReportIsPrinted Then
			If WriteAtServer(vMessage) Then
				Modified = False;
				PrintZReport();
				Close();
			Else
				ShowMessageBox(, vMessage, , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'")); 
			EndIf;
		Else
			ShowMessageBox(, vMessage, , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		EndIf;
	EndIf;
EndProcedure // AfterInputCashRegisterPassword()

// -----------------------------------------------------------------------------
&AtServer
Function WriteAtServer(pMessage)
	vObj = FormAttributeToValue("Object");
	Try
		vObj.Write(DocumentWriteMode.Posting);
		ValueToFormAttribute(vObj, "Object");
		Return True;
	Except
		vErr = ErrorDescription();
		pMessage = vErr;
		WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning,Type("DocumentObject.CloseOfCashRegisterDay"), , vErr);
		Return False;
	EndTry;
EndFunction	

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintZReport()
	vUseExternalForm = False;
	vPrintForm = PredefinedValue("Catalog.ObjectPrintingForms.CashRegisterPrintXReport");
	If ValueIsFilled(vPrintForm) Then
		vReportRef = tcOnServer.cmGetAttributeByRef(vPrintForm, "Report");
		If ValueIsFilled(vReportRef) Then
			vIsExternalReport = tcOnServer.cmGetAttributeByRef(vReportRef, "IsExternal");
			If vIsExternalReport Then
				vUseExternalForm = True;
				vExternalReport = tcOnServer.cmGetAttributeByRef(vReportRef, "Report");
				vURL = GetURL(vExternalReport, "ExternalProcessingStorage"); 
				vName = ConnectExternalReport(vURL, "ExternalReportForm");
				vParams = New Structure("CloseOfCashRegisterDay, SelObjectPrintForm", Object.Ref, vPrintForm);
				OpenForm("ExternalReport." + vName + ".Form.tcZReportForm", vParams);
			EndIf;
		EndIf;
	EndIf;
	If Not vUseExternalForm Then
		vParams = New Structure("CloseOfCashRegisterDay, SelObjectPrintForm", Object.Ref, vPrintForm);
		OpenForm("Report.PrintCashRegisterDayReport.Form.tcZReportForm", vParams, , Object.Ref);
	EndIf;
EndProcedure // PrintZReport

// -----------------------------------------------------------------------------
&AtServer
Procedure CompanyOnChangeAtServer()
	If ValueIsFilled(Object.Company) Then
		FillListOfCashRegisters();
		If ValueIsFilled(Object.CashRegister) And Object.CashRegister.Owner <> Object.Company Then
			If Items.CashRegister.ChoiceList.Count() > 0 Then
				Object.CashRegister = Items.CashRegister.ChoiceList.Get(0).Value;
				CashRegisterOnChangeAtServer();
			Else
				Object.CashRegister = Catalogs.CashRegisters.EmptyRef();
			EndIf;
		EndIf;
	Else
		Object.CashRegister = Catalogs.CashRegisters.EmptyRef();
		Items.CashRegister.ChoiceList.Clear();
	EndIf;
EndProcedure // CompanyOnChangeAtServer

#EndRegion





