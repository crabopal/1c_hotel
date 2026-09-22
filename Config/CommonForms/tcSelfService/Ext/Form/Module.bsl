#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vError = False;
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then 
		If SessionParameters.CurrentWorkstation.HasConnectionToCashAcceptors And 
			ValueIsFilled(SessionParameters.CurrentWorkstation.CashAcceptorsConnectionParameters) Then
			SelCashAcceptorsConnectionParameters = SessionParameters.CurrentWorkstation.CashAcceptorsConnectionParameters;
			SelCashAcceptorsConnectionParametersArray = tcOnServer.cmGetAtributeAsArray(SelCashAcceptorsConnectionParameters);
			Items.PageFolioDetailsCashPay.Visible = True;
			SelCashPay = True;
		Else
			Items.PageFolioDetailsCashPay.Visible = False;
			SelCashPay = False;
		EndIf;
		If SessionParameters.CurrentWorkstation.HasConnectionToCreditCardsProcessingSystem And 
			ValueIsFilled(SessionParameters.CurrentWorkstation.CreditCardsProcessingSystemParameters) And CheckPayment() Then
			SelCreditCardsProcessingSystemParameter = SessionParameters.CurrentWorkstation.CreditCardsProcessingSystemParameters;
			SelCreditCardsProcessingSystemParameterArray = tcOnServer.cmGetAtributeAsArray(SelCreditCardsProcessingSystemParameter);
			Items.PageFolioDetailsCreditCardPay.Visible = True;
			SelCreditCardPay = True;
		Else
			Items.PageFolioDetailsCreditCardPay.Visible = False;
			SelCreditCardPay = False;
		EndIf;
		If SessionParameters.CurrentWorkstation.CashRegisters.Count() = 1 Then
			vCashRegister = SessionParameters.CurrentWorkstation.CashRegisters.Get(0).CashRegister;
			If ValueIsFilled(vCashRegister) Then
				SelCashRegister = vCashRegister;
			Else
				vError = True;
				WriteLogEvent(NStr("en = 'Self service terminal'; de = 'Selbstbedienungs-terminal'; ru = 'Терминал самообслуживания'"), EventLogLevel.Error, , , 
				NStr("en = 'Error description: KKM is not selected!'; de = 'Error description: KKM is not selected!'; ru = 'Описание ошибки: ККМ не выбран!'"));
			EndIf;
		Else
			vError = True;
			WriteLogEvent(NStr("en = 'Self service terminal'; de = 'Selbstbedienungs-terminal'; ru = 'Терминал самообслуживания'"), EventLogLevel.Error, , , 
			NStr("en = 'Error description: KKM is not selected!'; de = 'Error description: KKM is not selected!'; ru = 'Описание ошибки: ККМ не выбран!'"));
		EndIf;
	Else
		vError = True;
		WriteLogEvent(NStr("en = 'Self service terminal'; de = 'Selbstbedienungs-terminal'; ru = 'Терминал самообслуживания'"), EventLogLevel.Error, , , 
		NStr("en = 'Error description: Workstation not specified!'; de = 'Error description: Workstation not specified!'; ru = 'Описание ошибки: Рабочее место не указано!'"));
	EndIf;
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		SelHotel = SessionParameters.CurrentHotel; 
		If ValueIsFilled(SelHotel.BaseCurrency) Then 
			SelCurrency = SelHotel.BaseCurrency;
		Else
			vError = True;
			WriteLogEvent(NStr("en = 'Self service terminal'; de = 'Selbstbedienungs-terminal'; ru = 'Терминал самообслуживания'"), EventLogLevel.Error, , , 
			NStr("en = 'Error description: Payment curency should be specified!'; de = 'Error description: Payment curency should be specified!'; ru = 'Описание ошибки: Валюта платежа должна быть указана!'"));
		EndIf;
		vAdvanceSettlementPaymentMethod = Undefined;
		vAdvancePaymentSection = Undefined;
		cmFillAdvanceAndAdvanceSettlementParameters(SelHotel, SessionParameters.CurrentUser, vAdvancePaymentSection, vAdvanceSettlementPaymentMethod);	
		If ValueIsFilled(vAdvancePaymentSection) Then
			SelPaymentSection = vAdvancePaymentSection;	
		Else
			vError = True;
			WriteLogEvent(NStr("en = 'Self service terminal'; de = 'Selbstbedienungs-terminal'; ru = 'Терминал самообслуживания'"), EventLogLevel.Error, , , 
			NStr("en = 'Error description: Payment section must be specified!'; de = 'Error description: Payment section must be specified!'; ru = 'Описание ошибки: Секция оплаты должна быть указана!'"));
		EndIf;
		If ValueIsFilled(SelHotel.PlannedPaymentMethod) Then
			SelPaymentMethod = SelHotel.PlannedPaymentMethod;
			Items.PageFolioDetailsCashPay.Visible = SelCashPay;
		Else
			If SelCashPay Then 
				WriteLogEvent(NStr("en = 'Self service terminal'; de = 'Selbstbedienungs-terminal'; ru = 'Терминал самообслуживания'"), EventLogLevel.Error, , , 
				NStr("en = 'Error description: Payment method should be choosen!'; de = 'Error description: Payment method should be choosen!'; ru = 'Описание ошибки: Способ оплаты должен быть указан!'"));
			EndIf;
			Items.PageFolioDetailsCashPay.Visible = False;
			SelCashPay = False;
			vError = True;
		EndIf;
	Else
		vError = True; 
		WriteLogEvent(NStr("en = 'Self service terminal'; de = 'Selbstbedienungs-terminal'; ru = 'Терминал самообслуживания'"), EventLogLevel.Error, , , 
		NStr("en = 'Error description: Hotel should be specified!'; de = 'Error description: Hotel should be specified!'; ru = 'Описание ошибки: Гостиница должна быть указана!'"));	
	EndIf;
	If vError Then
		Items.Pages.CurrentPage = Items.PageFatalError;
	Else
		ClearAttributes();
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If SelCashPay Then
		If Not tcCashAcceptorsSystemDriverCCNET.pmPool(SelCashAcceptorsConnectionParametersArray,,,, True) Then
			SelCashPay = False;
			Items.PageFolioDetailsCashPay.Visible = False;							   
		EndIf;
	EndIf;
	If ValueIsFilled(SelCashRegister) Then
		CheckPrintCheque();
	Else
		Items.PageFolioDetailsErrorMsg.Visible = True;
		Items.PageMainErrorMsg.Title = NStr("en = 'Cash registers error: Cash registers is not specified'; de = 'Registrierkassenfehler: Registrierkassen sind nicht angegeben'; ru = 'Ошибка ККМ: ККМ не указан'");
		SelCashPay = False;
		SelCreditCardPay = False;	
	EndIf;
EndProcedure // OnOpen

// --------------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Or Items.Pages.CurrentPage <> Items.PageMain Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		If ValueIsFilled(vEventData.DeviceData) Then
			vCard = GetIdentificationCardByCardID(vEventData.DeviceData);
			If ValueIsFilled(vCard) Then
				SelFolio = GetFolioByCard(vCard);
				If Not ValueIsFilled(SelFolio) Then
					ErrorPageMessage(NStr("en = 'Error'; de = 'Error'; ru = 'Ошибка'"), NStr("en = 'Folio not found'; de = 'Persönliches Konto nicht gefunden'; ru = 'Лицевой счет не найден'"));
					Return;
				EndIf;
			ElsIf IsManagementKey(vEventData.DeviceData, SelHotel) Then
				Items.Pages.CurrentPage =  Items.PageManagement;
				Return;
			Else
				ErrorPageMessage(NStr("en = 'Error'; de = 'Error'; ru = 'Ошибка'"), NStr("en = 'Could not find card'; de = 'Karte konnte nicht gefunden werden'; ru = 'Не удалось найти  карту'"));
				Return;
			EndIf;
		Else
			ErrorPageMessage(NStr("en = 'Error'; de = 'Error'; ru = 'Ошибка'"), NStr("en = 'Failed to read card'; de = 'Karte konnte nicht gelesen werden'; ru = 'Не удалось считать карту'"));
			Return;
		EndIf;
		FillAttributesByFolio();
		CheckPrintCheque();
	ElsIf vEventData.DeviceType = "BarCodeScaner" Then
		Try
			If ValueIsFilled(vEventData.DeviceData) Then
				vStructure = GetStructureFromTheJSON(ConvertACSIIToUTF8(vEventData.DeviceData));
				If ValueIsFilled(vStructure) Then
					SelFolio = GetFolioByJson(vStructure);
					If Not ValueIsFilled(SelFolio) Then
						ErrorPageMessage(NStr("en = 'Error'; de = 'Error'; ru = 'Ошибка'"), NStr("en = 'Folio not found'; de = 'Persönliches Konto nicht gefunden'; ru = 'Лицевой счет не найден'"));
						Return;
					EndIf;
				ElsIf IsManagementKey(vEventData.DeviceData, SelHotel) Then
					Items.Pages.CurrentPage =  Items.PageManagement;
					Return;
				Else
					ErrorPageMessage(NStr("en = 'Error'; de = 'Error'; ru = 'Ошибка'"), NStr("en = 'Failed to read QR-Code'; de = 'QR-Code konnte nicht gelesen werden'; ru = 'Не удалось прочитать QR-код'"));
					Return;
				EndIf;
			Else
				ErrorPageMessage(NStr("en = 'Error'; de = 'Error'; ru = 'Ошибка'"), NStr("en = 'Failed to read QR-Code'; de = 'QR-Code konnte nicht gelesen werden'; ru = 'Не удалось прочитать QR-код'"));
				Return;
			EndIf;
			FillAttributesByFolio();
			CheckPrintCheque();
		Except
			ErrorPageMessage(NStr("en = 'Error'; de = 'Error'; ru = 'Ошибка'"), NStr("en = 'Failed to read QR-Code'; de = 'QR-Code konnte nicht gelesen werden'; ru = 'Не удалось прочитать QR-код'"));
		EndTry;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormCommandsEventHandlers 

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionCashPay(pCommand)
	If tcCashAcceptorsSystemDriverCCNET.pmEnableSequence(SelCashAcceptorsConnectionParametersArray, SelAmount) Then
		DetachIdleHandler("GoToHomeScreen");
		Items.DecorationCash.Title = NStr("en = 'ADDED: '; de = 'ADDED: '; ru = 'ВНЕСЕНО: '") + FormatSumAtServer(SelAmount, SelCurrency);
		Items.Pages.CurrentPage = Items.PageCash;
		SelStopPoll = False;
		FillNewFolio(True);
		AttachIdleHandler("Poll", 0.1, True);
	EndIf;
EndProcedure // ActionCashPay

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionPaymentCash(pCommand)
	SelStopPoll = True;
	DetachIdleHandler("Poll");
	tcCashAcceptorsSystemDriverCCNET.pmDisableSequence(SelCashAcceptorsConnectionParametersArray, SelAmount);
	Items.Pages.CurrentPage = Items.PagePaymentProcessMessage;
	AttachIdleHandler("BeginPaymentCash", 0.1, True);
EndProcedure // ActionPaymentCash

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionCreditCardPay(pCommand)
	DetachIdleHandler("GoToHomeScreen");
	Items.DecorationCreditCard.Title = FormatSumAtServer(SelAmount, SelCurrency);
	Items.Pages.CurrentPage = Items.PageCreditCard;
	Items.PageCreditCardPayment.Enabled = ?(SelAmount = 0, False, True);	
EndProcedure // ActionCreditCardPay

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionPaymentCreditCards(pCommand)
	FillNewFolio();	
	SumOnChange();
	Items.Pages.CurrentPage = Items.PageCreditCardProcessMessage;
	AttachIdleHandler("ProcessCreditCardTerminal", 0.1, True);
EndProcedure // ActionPaymentCreditCards

// --------------------------------------------------------------------------------
&AtClient
Procedure Button_Command(pCommand)
	StrArr = StrSplit(SelAmountString, ".");
	If StrFind(SelAmountString, ".") = 0  Then
		If StrLen(StrArr[0]) >= 15 Then
			Return
		EndIf;
	Else
		If StrLen(StrArr[1]) >= 2 Then
			Return
		EndIf;
	EndIf;
	vNubmer = Number(StrReplace(pCommand.Name, "Button_", ""));
	SelAmountString = SelAmountString + vNubmer;
	SelAmount = Number(SelAmountString);
	Items.PageCreditCardPayment.Enabled = ?(SelAmount = 0, False, True);
	Items.DecorationCreditCard.Title = FormatSumAtServer(SelAmount, SelCurrency);
EndProcedure // Button_Command

// --------------------------------------------------------------------------------
&AtClient
Procedure Button_C(pCommand)
	SelAmountString = Left(SelAmountString, StrLen(SelAmountString) - 1);
	If SelAmountString = "" Then
		SelAmountString = "0";	
	EndIf;
	SelAmount = Number(SelAmountString);
	Items.PageCreditCardPayment.Enabled = ?(SelAmount = 0, False, True);
	Items.DecorationCreditCard.Title = FormatSumAtServer(SelAmount, SelCurrency);
EndProcedure // Button_C

// --------------------------------------------------------------------------------
&AtClient
Procedure Button_Comma(pCommand)
	If StrFind(SelAmountString, ".") = 0 Then
		SelAmountString = SelAmountString + ".";
		SelAmount = Number(SelAmountString);
		Items.DecorationCreditCard.Title = FormatSumAtServer(SelAmount, SelCurrency);
	EndIf;
EndProcedure // Button_Comma

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionBack(pCommand)
	If Items.Pages.CurrentPage = Items.PageCash Then
		DetachIdleHandler("Poll");
		SelStopPoll = True;
		tcCashAcceptorsSystemDriverCCNET.pmDisableSequence(SelCashAcceptorsConnectionParametersArray);
	EndIf;
	If Items.Pages.CurrentPage = Items.PageManagement Then
		If Items.PagesManagement.CurrentPage = Items.PageManagementCashAcceptor Or Items.PagesManagement.CurrentPage = Items.PageManagementCashRegister Then
			If Items.PagesManagement.CurrentPage = Items.PageManagementCashAcceptor Then
				SelCashPay = tcCashAcceptorsSystemDriverCCNET.pmPool(SelCashAcceptorsConnectionParametersArray,,, True); 	
			EndIf;
			Items.PagesManagement.CurrentPage = Items.PageManagementMain;	
		Else
			DetachIdleHandler("GoToHomeScreen");
			ClearAttributes();
			Items.Pages.CurrentPage = Items.PageMain;	
		EndIf;
	Else
		DetachIdleHandler("GoToHomeScreen");
		ClearAttributes();
		Items.Pages.CurrentPage = Items.PageMain;
	EndIf;
EndProcedure // ActionBack

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionsWithCashRegister(pCommand)
	vHasRightsForXReport = tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterXReport");
	Items.PageManagementCashRegisterXReport.Enabled = vHasRightsForXReport; 
	Items.PageManagementCashRegisterZReport.Enabled = Not vHasRightsForXReport;
	UpdateNumberOfClosedShifts();
	Items.PagesManagement.CurrentPage = Items.PageManagementCashRegister;
EndProcedure // ActionsWithCashRegister

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionCashRegisterTest(pCommand)
	rMessage = "";
	If ValueIsFilled(SelCashRegister) Then
		vDriver = tcOnClient.cmGetModulTO(SelCashRegister);
		If Not vDriver = Undefined Then
			If vDriver.pmIsReadyToPrint(rMessage, , SelCashRegister) Then
				Items.DecorationManagementCashRegister.Title = NStr("en = 'Cash register was connected!'; de = 'Kasse war angeschlossen!'; ru = 'Контрольно-Кассовая Машина подключена!'");
			Else
				Items.DecorationManagementCashRegister.Title = rMessage;
			EndIf;
		Else
			Items.DecorationManagementCashRegister.Title = Nstr("en = 'Work with this device driver is not supported!'; ru = 'Работа с драйвером этого устройства не поддерживается!'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'");
		EndIf;		
	EndIf;	
EndProcedure // ActionCashRegisterTest

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionCashRegisterXReport(pCommand)
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterXReport") Then
		vDriver = tcOnClient.cmGetModulTO(SelCashRegister);
		If Not vDriver = Undefined And tcOnServer.cmGetAttributeByRef(SelCashRegister, "IsControlledByProgram") Then
			vMessage = "";
			vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(True, SelCashRegister);
			If Not vDriver.pmPrintXReport(vMessage, SelCashRegister, vPasswordKKM) Then
				Items.DecorationManagementCashRegister.Title = vMessage;
			Else			
				// Open program printing form
				OpenForm("Report.PrintCashRegisterDayReport.Form.tcXReportForm", New Structure("CashRegister", SelCashRegister), , SelCashRegister);
				// Enable Z-Report button
				Items.PageManagementCashRegisterZReport.Enabled = True;
			EndIf;	
		Else
			Items.DecorationManagementCashRegister.Title = NStr("en = 'This device is not supported by the driver!'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'");
		EndIf;
	Else
		Items.DecorationManagementCashRegister.Title = NStr("en='You do not have rights to print X-Report!'; ru='Нет прав на печать X-Отчета!'; de='Sie haben keine Rechte, X-Report zu drucken!'");
	EndIf;
EndProcedure // ActionCashRegisterXReport

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionCashRegisterZReport(pCommand)
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterZReport") Then
		// Call external command if necessary
		vZCommand = TrimAll(tcOnServer.cmGetAttributeByRef(SelCashRegister, "ZReportCommand"));
		If Not IsBlankString(vZCommand) Then
			vCurDir = "";
			j = StrLen(vZCommand); 
			// ACC:561-off
			While j > 1 Do
				vFile = New File(Left(vZCommand, j));
				If tcCommonFunctionOnClientServer.cmExists(vFile) Then
					vCurDir = vFile.Path;
					Break;
				Else
					j = j - 1;
				EndIf;
			EndDo;       
			// ACC:561-on
			BeginRunningApplication(New NotifyDescription, vZCommand, vCurDir, True)   
		Else
			// Open close of cash register shift document
			OpenForm("Document.CloseOfCashRegisterDay.ObjectForm", New Structure("Basis, PostAndCloseOnOpen", SelCashRegister, True), , SelCashRegister);
		EndIf;
		// Disable Z-Report button
		Items.PageManagementCashRegisterZReport.Enabled = False;
		// Update number of closed shifts
		UpdateNumberOfClosedShifts();
	Else
		Items.DecorationManagementCashRegister.Title = NStr("en='You do not have rights to print Z-Report!'; ru='Нет прав на печать Z-Отчета!'; de='Sie haben keine Rechte, Z-Report zu drucken!'");
	EndIf;
EndProcedure // ActionCashRegisterZReport

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionsWithCashRegisterCashAcceptor(pCommand)
	Items.PagesManagement.CurrentPage = Items.PageManagementCashAcceptor;	
EndProcedure // ActionsWithCashRegisterCashAcceptor

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionCashAcceptorPoll(pCommand)
	vHexCode = Undefined;
	If tcCashAcceptorsSystemDriverCCNET.pmPool(SelCashAcceptorsConnectionParametersArray, vHexCode,, True) Then
		vSum = 0;
		Items.DecorationManagementCashAcceptor.Title = tcCashAcceptorsSystemDriverCCNET.pmGetErrorDescription(vHexCode, vSum);
		If vSum > 0 Then
			Items.DecorationManagementCashAcceptor.Title = Items.DecorationManagementCashAcceptor.Title + FormatSumAtServer(vSum, SelCurrency,,, Not ValueIsFilled(SelCurrency));	
		EndIf;
	EndIf;		
EndProcedure // ActionCashAcceptorPoll

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionCashAcceptorReturn(pCommand)
	If Not tcCashAcceptorsSystemDriverCCNET.pmReturn(SelCashAcceptorsConnectionParametersArray) Then
		Items.DecorationManagementCashAcceptor.Title = NStr("en = 'An error has occurred'; de = 'Ein Fehler ist aufgetreten'; ru = 'Произошла ошибка'");	
	EndIf;
EndProcedure // ActionCashAcceptorReturn

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionCashAcceptorReset(pCommand)
	tcCashAcceptorsSystemDriverCCNET.pmReset(SelCashAcceptorsConnectionParametersArray);		
EndProcedure // ActionCashAcceptorReset

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionsWithCashRegisterCreditCard(pCommand)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterXReport") Then
		ShowMessageBox(, NStr("en='You do not have rights to open payment terminal service functions menu!'; ru='Нет прав на открытие меню сервисных функций платежного термнала!'; de='Sie haben keine Rechte, das Menü der Servicefunktionen des Zahlungsterminals zu öffnen!'"), 5);
		Return;
	EndIf;	
	If Not ValueIsFilled(SelCreditCardsProcessingSystemParameter) Then
		ShowMessageBox(, NStr("en = 'You have not connected payment terminal!'; ru = 'Нет подключенного платежного термнала!'; de = 'Sie haben nicht angeschlossen Zahlungsterminal!'"), 5);
		Return;
	EndIf;
	vDriver = tcOnClient.cmGetModulTO(SelCreditCardsProcessingSystemParameterArray);
	If Not vDriver = Undefined Then
		vMessage = "";
		If Not ValueIsFilled(SelCashRegister) Then
			vMessage = NStr("en='No cash register is selected!';ru='Не выбрана ККМ!';de='Keine Registrierkasse ist gewählt!'");
			ShowMessageBox(, vMessage, 5);
			Return;
		EndIf;
		If Not vDriver.pmOpenServiceFunctionsMenu(vMessage, SelCashRegister, SelCreditCardsProcessingSystemParameterArray) Then
			ShowMessageBox(, vMessage, 5);
		EndIf;	
	Else
		ShowMessageBox(, Nstr("en = 'Working with this terminal driver is not supported'; ru = 'Работа с этим драйвером терминала не поддерживается'; de = 'Arbeiten mit diesem Terminal-Treiber wird nicht unterstützt'"), 5,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;
EndProcedure // ActionsWithCashRegisterCreditCard

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServerNoContext
Function IsManagementKey(pKey, pHotel)
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(pHotel) Then
		vHotel = pHotel; 	
	EndIf;
	If vHotel.SelfServiceTerminalManagementIDСard = pKey Or vHotel.SelfServiceTerminalManagementQRCode = New UUID(pKey) Then
		Return True;	
	Else
		Return False;
	EndIf;
EndFunction // IsManagementKey

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetIdentificationCardByCardID(pCardId)
	Return cmGetClientIdentificationCardById(pCardId);
EndFunction // GetIdentificationCardByCardID

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetFolioByCard(pCard)
	If ValueIsFilled(pCard.Folio) Then
		Return pCard.Folio;
	Else
		Return Documents.Folio.EmptyRef();
	EndIf;
EndFunction // GetFolioByCard

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetFolioBalance(pFolioRef)
	Return pFolioRef.GetObject().pmGetBalance(); 	
EndFunction // GetFolioBalance

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetFolioByJson(pBarCodeData)
	vFolioRef = Documents.Folio.EmptyRef();
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Ref
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.Hotel.Code = &qCode
	|	AND Folio.Number = &qNumber
	|	AND NOT Folio.DeletionMark
	|	AND NOT Folio.IsClosed";
	vQry.SetParameter("qCode", pBarCodeData.Hotel);
	vQry.SetParameter("qNumber", pBarCodeData.FolioNumber);
	vFolios = vQry.Execute().Unload();
	If vFolios.Count() > 0 Then
		vFolioRef = vFolios.Get(0).Ref;
	EndIf;
	Return vFolioRef;	
EndFunction // GetIdentificationCardByBarCodeData

// --------------------------------------------------------------------------------
&AtServerNoContext
Function CheckPayment()
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	PaymentMethods.Ref AS Ref
	|FROM
	|	Catalog.PaymentMethods AS PaymentMethods
	|WHERE
	|	NOT PaymentMethods.DeletionMark
	|	AND PaymentMethods.IsByCreditCard";
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		Return True;	
	Else
		Return False;	
	EndIf;
EndFunction // CheckPayment

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GatPaymentMethodByTypeCard(pCartType)
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	PaymentMethods.Ref AS Ref
	|FROM
	|	Catalog.PaymentMethods AS PaymentMethods
	|WHERE
	|	NOT PaymentMethods.DeletionMark
	|	AND PaymentMethods.IsByCreditCard
	|	AND PaymentMethods.CardType = &qCardType
	|
	|ORDER BY
	|	PaymentMethods.SortCode,
	|	PaymentMethods.Code";
	vQuery.SetParameter("qCardType", pCartType);
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		Return vResult.Get(0).Ref;			
	Else
		vQuery = New Query();
		vQuery.Text = 
		"SELECT
		|	PaymentMethods.Ref AS Ref
		|FROM
		|	Catalog.PaymentMethods AS PaymentMethods
		|WHERE
		|	NOT PaymentMethods.DeletionMark
		|	AND PaymentMethods.IsByCreditCard
		|	AND PaymentMethods.CardType = VALUE(Catalog.CreditCardTypes.EmptyRef)
		|
		|ORDER BY
		|	PaymentMethods.SortCode,
		|	PaymentMethods.Code"; 
		vResult = vQuery.Execute().Unload();
		If vResult.Count() > 0 Then
			Return vResult.Get(0).Ref;			
		Else
			vQuery = New Query();
			vQuery.Text = 
			"SELECT
			|	PaymentMethods.Ref AS Ref
			|FROM
			|	Catalog.PaymentMethods AS PaymentMethods
			|WHERE
			|	NOT PaymentMethods.DeletionMark
			|	AND PaymentMethods.IsByCreditCard
			|
			|ORDER BY
			|	PaymentMethods.SortCode,
			|	PaymentMethods.Code";
			vResult = vQuery.Execute().Unload();
			If vResult.Count() > 0 Then
				Return vResult.Get(0).Ref;	
			Else
				Return Catalogs.CreditCardTypes.EmptyRef();	
			EndIf;
		EndIf;
	EndIf;
EndFunction // GatPaymentMethodByTypeCard

// --------------------------------------------------------------------------------
&AtServerNoContext
Function FormatSumAtServer(pSum, pCurrency, pZeroPresentation = "NZ=0", pLang = Undefined, pNoCurrency = False)
	Return cmFormatSum(pSum, pCurrency, pZeroPresentation, pLang, pNoCurrency);
EndFunction // FormatSumAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetAccountingDate(pHotel)
	vAccountingDate = BegOfDay(CurrentSessionDate());
	If ValueIsFilled(pHotel) And ValueIsFilled(pHotel.AccountingDate) Then
		vAccountingDate = BegOfDay(pHotel.AccountingDate);
	EndIf;
	Return vAccountingDate;
EndFunction // GetAccountingDate

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetNumberOfClosedShiftsPerDay(pCashRegister, pDate)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CloseOfCashRegisterDay.CashRegister AS CashRegister,
	|	CloseOfCashRegisterDay.CashRegister.MaximumNumberOfZReportsPerDay AS MaximumNumberOfZReportsPerDay,
	|	COUNT(CloseOfCashRegisterDay.Ref) AS NumberOfClosedShifts
	|FROM
	|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
	|WHERE
	|	CloseOfCashRegisterDay.CashRegister = &qCashRegister
	|	AND (CloseOfCashRegisterDay.AccountingDate <> &qEmptyDate
	|				AND CloseOfCashRegisterDay.AccountingDate = &qAccountingDate
	|			OR CloseOfCashRegisterDay.AccountingDate = &qEmptyDate
	|				AND BEGINOFPERIOD(CloseOfCashRegisterDay.Date, DAY) = &qAccountingDate)
	|	AND CloseOfCashRegisterDay.Posted
	|
	|GROUP BY
	|	CloseOfCashRegisterDay.CashRegister,
	|	CloseOfCashRegisterDay.CashRegister.MaximumNumberOfZReportsPerDay";
	vQry.SetParameter("qCashRegister", pCashRegister);
	vQry.SetParameter("qAccountingDate", BegOfDay(pDate));
	vQry.SetParameter("qEmptyDate", '00010101');
	vResult = vQry.Execute().Unload();
	If vResult.Count() > 0 Then 
		Return vQry.Execute().Unload().Get(0);	
	Else
		Return Undefined;	
	EndIf;	
EndFunction // GetNumberOfClosedShiftsPerDay

// --------------------------------------------------------------------------------
&AtServer
Procedure PostOrSavePayment(Save = False)
	vObj = FormAttributeToValue("SelObjPayment");
	If Not Save Then 
		vObj.Write(DocumentWriteMode.Posting);
	Else
		vObj.Write(DocumentWriteMode.Write);	
	EndIf;
	ValueToFormAttribute(vObj, "SelObjPayment");	
EndProcedure // PostringPayment

// --------------------------------------------------------------------------------
&AtClient
Function AuthorizePayment(rMessage)
	rMessage = "";
	If Not ValueIsFilled(SelObjPayment.AuthorizationCode) Then
		vDriver = tcOnClient.cmGetModulTO(SelCreditCardsProcessingSystemParameterArray);
		If Not vDriver = Undefined Then
			Return vDriver.pmAuthorizePayment(SelObjPayment.Sum, SelObjPayment.VATSum, SelObjPayment, rMessage, SelCreditCardsProcessingSystemParameterArray);
		Else
			Return False;                                                  
		EndIf;	
	EndIf;
	Return True;
EndFunction // AuthorizePayment

// --------------------------------------------------------------------------------
&AtClient
Procedure StartPrintCheque(rMessage, pCancel)
	vDriver = tcOnClient.cmGetModulTO(SelCashRegister);
	If Not vDriver = Undefined Then
		pCancel = Not vDriver.pmPrintCheque(SelObjPayment.Sum, SelObjPayment.VATSum, SelObjPayment, SelObjPayment.Ref, rMessage, "", , False, False, "", 0, Date(1,1,1), SelObjPayment.SendPayerContactsToOFD, SelObjPayment.EmailToSendToOFD, SelObjPayment.PhoneToSendToOFD);
	Else
		// Device driver was not found
		pCancel = True;
		rMessage = Nstr("en = 'Work with this device driver is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'");
	EndIf;	
EndProcedure // StartPrintCheque

// --------------------------------------------------------------------------------
&AtClient
Procedure GoToHomeScreen() Export 
	ActionBack(Commands["ActionBack"]);	
EndProcedure // GoToHomeScreen

// --------------------------------------------------------------------------------
&AtClient
Procedure BeginPaymentCash() Export
	pCancel = False;
	vMessage = "";
	StartPrintCheque(vMessage, pCancel);
	If pCancel And Not IsBlankString(vMessage) Then
		ErrorMessage(vMessage);
	Else
		PostOrSavePayment();
		AfterPayment();
	EndIf;	
EndProcedure // BeginPaymentCash

// --------------------------------------------------------------------------------
&AtClient
Procedure ProcessCreditCardTerminal() Export
	vMessage = "";
	If Not AuthorizePayment(vMessage) Then	
		ErrorMessage(vMessage);	
	Else
		Items.Pages.CurrentPage = Items.PagePaymentProcessMessage;
		AttachIdleHandler("BeginPaymentCreditCards", 0.1, True);	
	EndIf;	
EndProcedure // BeginPaymentCreditCards

// --------------------------------------------------------------------------------
&AtClient
Procedure BeginPaymentCreditCards() Export
	vMessage = "";
	vPaymentMethod = GatPaymentMethodByTypeCard(SelObjPayment.CardType);
	If ValueIsFilled(vPaymentMethod) Then
		SelObjPayment.PaymentMethod = vPaymentMethod;
	EndIF;
	PostOrSavePayment(True);
	pCancel = False;
	StartPrintCheque(vMessage, pCancel);
	If pCancel And Not IsBlankString(vMessage) Then
		ErrorMessage(vMessage);
	Else
		PostOrSavePayment();
		AfterPayment();
	EndIf;	
EndProcedure // BeginPaymentCreditCards

// --------------------------------------------------------------------------------
&AtClient
Procedure Poll() Export
	OldSelAmount = SelAmount;
	If tcCashAcceptorsSystemDriverCCNET.pmPool(SelCashAcceptorsConnectionParametersArray,, SelAmount) Then
		If OldSelAmount <> SelAmount Then
			SumOnChange(True);
			Items.DecorationCash.Title = NStr("en = 'ADDED: '; de = 'ADDED: '; ru = 'ВНЕСЕНО: '") + FormatSumAtServer(SelAmount, SelCurrency);			
		EndIf;
	Else
		SelStopPoll = True;	
	EndIf;
	If SelAmount <> 0 And Items.PageCashBack.Enabled Then
		Items.PageCashPayment.Enabled = True;
		Items.PageCashBack.Enabled = False;
	EndIf;
	If Not SelStopPoll Then
		AttachIdleHandler("Poll", 0.1, True);
	EndIf;
EndProcedure // Poll

// --------------------------------------------------------------------------------
&AtClient
Function GetStructureFromTheJSON(pJSON)	
	vResult = Undefined;
	Try
		#IF NOT WebClient THEN
			If ValueIsFilled(pJSON) Then
				vJSONReader = New JSONReader;
				vJSONReader.SetString(pJSON);
				vResult = ReadJSON(vJSONReader);
			EndIf;		
		#ENDIF	
	Except
	EndTry;		
	Return vResult;
EndFunction // GetBaudRate

// --------------------------------------------------------------------------------
&AtClient
Procedure FillAttributesByFolio()
	SelBalance = GetFolioBalance(SelFolio);
	vBalanceMsg = ?(SelBalance >= 0, NStr("en = 'Your Debt '; de = 'Deine Schulden'; ru = 'Долг '"), NStr("en = 'Your deposit '; de = 'Ihre Anzahlung'; ru = 'Депозит '")) + FormatSumAtServer(?(SelBalance >= 0, SelBalance, -SelBalance), tcOnServer.cmGetAttributeByRef(SelFolio, "FolioCurrency")); 
	Items.DecorationFolioDetails.Title = NStr("en = 'Hello, '; de = 'Hallo '; ru = 'Здравствуйте, '") + tcOnServer.cmGetAttributeByRef(SelFolio, "Client") + Chars.LF + Chars.LF + vBalanceMsg;
	Items.DecorationCashHeader.Title = vBalanceMsg;
	Items.DecorationCreditCardHeader.Title = vBalanceMsg;
	Items.Pages.CurrentPage = Items.PageFolioDetails;
	AttachIdleHandler("GoToHomeScreen", 20, True);
EndProcedure // FillAttributesByFolio

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterPayment()
	SelBalance = GetFolioBalance(SelFolio);
	Items.DecorationMessageHeader.Title = ?(SelBalance >= 0, NStr("en = 'Your Debt '; de = 'Deine Schulden'; ru = 'Долг '"), NStr("en = 'Your deposit '; de = 'Ihre Anzahlung'; ru = 'Депозит '")) + FormatSumAtServer(?(SelBalance >= 0, SelBalance, -SelBalance), tcOnServer.cmGetAttributeByRef(SelFolio, "FolioCurrency")); 
	Items.DecorationMessage.Title = NStr("en = 'Operation completed successfully'; de = 'Der Vorgang war erfolgreich'; ru = 'Операция выполнена успешно'");	
	Items.Pages.CurrentPage = Items.PageMessage;
	AttachIdleHandler("GoToHomeScreen", 5, True);	
EndProcedure //  AfterPayment

// --------------------------------------------------------------------------------
&AtClient
Procedure ErrorMessage(pMessage)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(pMessage));
	ErrorPageMessage(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), NStr("en = 'The operation cannot be completed, please contact the reception to resolve the problem'; de = 'Der Vorgang kann nicht abgeschlossen werden, Kontaktieren Sie bitte die Rezeption, um das problem zu lösen'; ru = 'Невозможно завершить операцию, обратитесь на ресепшн для решения проблемы'")); 
EndProcedure // ActionPaymentCash

// --------------------------------------------------------------------------------
&AtClient
Procedure ErrorPageMessage(pHeader, pMessage)
	Items.DecorationMessageHeader.Title = pHeader;
	Items.DecorationMessageHeader.TextColor = WebColors.Red;
	Items.DecorationMessage.Title = pMessage;	
	Items.Pages.CurrentPage = Items.PageMessage;
	AttachIdleHandler("GoToHomeScreen", 5, True);
EndProcedure // ErrorMessages

// --------------------------------------------------------------------------------
&AtClient
Procedure CheckPrintCheque()
	vDriver = tcOnClient.cmGetModulTO(SelCashRegister);
	If Not vDriver = Undefined Then
		rMessage = "";
		If vDriver.pmIsReadyToPrint(rMessage, , SelCashRegister) Then
			Items.PageMainErrorMsg.Title = "";
			Items.PageFolioDetailsErrorMsg.Visible = False;
			Items.PageFolioDetailsCashPay.Visible = SelCashPay;	
			Items.PageFolioDetailsCreditCardPay.Visible = SelCreditCardPay;
		Else
			Items.PageFolioDetailsErrorMsg.Visible = True;
			Items.PageMainErrorMsg.Title = NStr("en = 'Cash registers error: '; de = 'Registrierkassenfehler: '; ru = 'Ошибка ККМ: '") + rMessage;
			Items.PageFolioDetailsCashPay.Visible = False;
			Items.PageFolioDetailsCreditCardPay.Visible = False;	
		EndIf;
	Else
		Items.PageFolioDetailsCashPay.Visible = False;
		Items.PageFolioDetailsCreditCardPay.Visible = False;
	EndIf;
EndProcedure // CheckPrintCheque

// --------------------------------------------------------------------------------
&AtClient
Function ConvertACSIIToUTF8(pText)	
	vStream = New MemoryStream();
	vTextWrite = New TextWriter(vStream, TextEncoding.ANSI);
	vTextWrite.Write(pText);
	vTextWrite.Close();
	vBD = vStream.CloseAndGetBinaryData();
	Return GetStringFromBinaryData(vBD, TextEncoding.UTF8);
EndFunction // GetBaudRate

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearAttributes() 
	vNewObjPayment = Documents.Payment.CreateDocument();
	ValueToFormAttribute(vNewObjPayment, "SelObjPayment");
	SelAmount  = 0;
	SelAmountString = "0";
	SelBalance = 0;
	Items.PageCashPayment.Enabled = False;
	Items.PageCashBack.Enabled = True;
	SelFolio = Documents.Folio.EmptyRef();
	Items.DecorationFolioDetails.Title = "";
	Items.DecorationCashHeader.Title = "";
	Items.DecorationCash.Title = "";
	Items.DecorationCreditCardHeader.Title = "";
	Items.DecorationCreditCard.Title = "";
	Items.DecorationMessageHeader.Title = "";
	Items.DecorationMessageHeader.TextColor = New Color();
	Items.DecorationMessage.Title = "";
	Items.DecorationManagementCashAcceptor.Title = "";
	Items.DecorationManagementCashRegister.Title = "";
	Items.DecorationManagementCashRegisterHeader.Title = "";
	Items.PagesManagement.CurrentPage = Items.PageManagementMain;
EndProcedure // ClearAttributes

// --------------------------------------------------------------------------------
&AtServer
Procedure FillNewFolio(pCash = False)
	vObj = FormAttributeToValue("SelObjPayment");
	vObj.AdditionalProperties.Insert("AdvanceMode", True);
	vObj.Hotel = SelHotel;
	vObj.Fill(SelFolio);
	vObj.AccountingDate = SelHotel.AccountingDate;
	If pCash Then
		vObj.PaymentMethod = SelPaymentMethod;
	Else
		vObj.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
	EndIf;
	vObj.CashRegister = SelCashRegister;
	ValueToFormAttribute(vObj, "SelObjPayment");
EndProcedure // FillNewFolio

// --------------------------------------------------------------------------------
&AtServer
Procedure SumOnChange(pCash = False)
	vObj = FormAttributeToValue("SelObjPayment");
	vObj.Sum = SelAmount;
	vObj.VATSum = cmCalculateVATSum(vObj.VATRate, vObj.Sum, vObj.Date);
	vObj.SumInFolioCurrency = Round(cmConvertCurrencies(vObj.Sum, vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
	vObj.VATSumInFolioCurrency = cmCalculateVATSum(vObj.VATRate, vObj.SumInFolioCurrency, vObj.Date);
	i = 0;
	vWasUpdated = False;
	While i < vObj.PaymentSections.Count() Do
		vPSRow = vObj.PaymentSections.Get(i);
		If Not vWasUpdated And vObj.PaymentSection = vPSRow.PaymentSection Then
			vWasUpdated = True;
			vPSRow.Sum = vObj.Sum;
			vPSRow.VATSum = vObj.VATSum;
			vPSRow.SumInFolioCurrency = vObj.SumInFolioCurrency;
			vPSRow.VATSumInFolioCurrency = vObj.VATSumInFolioCurrency;
			If vPSRow.ChequeServiceQuantity <> 0 Then
				vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
			EndIf;
			i = i + 1;
		Else
			vObj.PaymentSections.Delete(i);
		EndIf;
	EndDo;
	If pCash Then
		vObj.Write(DocumentWriteMode.Write);
	EndIf;
	ValueToFormAttribute(vObj, "SelObjPayment");
EndProcedure // SumOnChange

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdateNumberOfClosedShifts()
	vShiftsRow = GetNumberOfClosedShiftsPerDay(SelCashRegister, GetAccountingDate(SelHotel));
	If vShiftsRow <> Undefined Then
		If vShiftsRow.NumberOfClosedShifts <> Null And vShiftsRow.NumberOfClosedShifts > 0 Then
			If vShiftsRow.MaximumNumberOfZReportsPerDay > 0 Then
				Items.DecorationManagementCashRegisterHeader.Title = NStr("en = 'Number of closed shifts: ('; de = 'Anzahl geschlossener Schichten: ('; ru = 'Количество закрытых смен: ('") + Format(vShiftsRow.NumberOfClosedShifts, "NFD=0; NZ=; NG=") + "/" + Format(vShiftsRow.MaximumNumberOfZReportsPerDay, "NFD=0; NZ=; NG=") + ")";
			Else
				Items.DecorationManagementCashRegisterHeader.Title = NStr("en = 'Number of closed shifts: ('; de = 'Anzahl geschlossener Schichten: ('; ru = 'Количество закрытых смен: ('") + Format(vShiftsRow.NumberOfClosedShifts, "NFD=0; NZ=; NG=") + ")";
			EndIf;
		Else
			If vShiftsRow.MaximumNumberOfZReportsPerDay > 0 Then
				Items.DecorationManagementCashRegisterHeader.Title = NStr("en = 'Number of closed shifts: (0/'; de = 'Anzahl geschlossener Schichten: (0/'; ru = 'Количество закрытых смен: (0/'") + Format(vShiftsRow.MaximumNumberOfZReportsPerDay, "NFD=0; NZ=; NG=") + ")";
			Else
				Items.DecorationManagementCashRegisterHeader.Title = NStr("en = 'Number of closed shifts: (0)'; de = 'Anzahl geschlossener Schichten: (0)'; ru = 'Количество закрытых смен: (0)'");
			EndIf;
		EndIf;
	Else
		If SelCashRegister.MaximumNumberOfZReportsPerDay > 0 Then
			Items.DecorationManagementCashRegisterHeader.Title = NStr("en = 'Number of closed shifts: (0/'; de = 'Anzahl geschlossener Schichten: (0/'; ru = 'Количество закрытых смен: (0/'") + Format(SelCashRegister.MaximumNumberOfZReportsPerDay, "NFD=0; NZ=; NG=") + ")";
		Else
			Items.DecorationManagementCashRegisterHeader.Title = NStr("en = 'Number of closed shifts: (0)'; de = 'Anzahl geschlossener Schichten: (0)'; ru = 'Количество закрытых смен: (0)'");
		EndIf;
	EndIf;
EndProcedure // UpdateNumberOfClosedShifts

#EndRegion