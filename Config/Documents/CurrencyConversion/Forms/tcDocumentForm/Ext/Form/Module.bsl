// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	If Not ValueIsFilled(Object.Ref) Then 
		If Not ValueIsFilled(Object.Hotel) Then
			vObj = FormAttributeToValue("Object");
			vObj.pmFillAttributesWithDefaultValues();
			ValueToFormAttribute(vObj, "Object");
		EndIf;
		Items.FormPrintTicket.Visible = False;
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
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Fill list of cash registers allowed for the current user
	FillListOfCashRegisters();
	If Not ValueIsFilled(Object.CashRegister) Then
		SetDefaultCashRegister();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfCashRegisters()
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		CashRegistersList = cmGetListOfAllCashRegisters(Object.Company);
	Else
		CashRegistersList = cmGetListOfCashRegistersAllowed(Object.Company, SessionParameters.CurrentWorkstation);
	EndIf;
	// Check that current cash register is in the list
	If ValueIsFilled(Object.Ref) Then
		If ValueIsFilled(Object.CashRegister) Then
			If CashRegistersList.FindByValue(Object.CashRegister) = Undefined Then
				CashRegistersList.Add(Object.CashRegister);
			EndIf;
		EndIf;
	EndIf;
	// Attach list of cash registers to the form item
	Items.CashRegister.ChoiceList.LoadValues(CashRegistersList.UnloadValues());
EndProcedure // FillListOfCashRegisters

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDefaultCashRegister()
	If CashRegistersList.FindByValue(Object.CashRegister) = Undefined Then
		If CashRegistersList.Count() > 0 Then
			Object.CashRegister = CashRegistersList.Get(0).Value;
		EndIf;
	EndIf;
EndProcedure // SetDefaultCashRegister

// -----------------------------------------------------------------------------
&AtServer
Procedure CompanyOnChangeAtServer()
	If ValueIsFilled(Object.Company) Then
		If ValueIsFilled(Object.CashRegister) And Object.CashRegister.Owner <> Object.Company Then
			Object.CashRegister = Catalogs.CashRegisters.EmptyRef();
		EndIf;
		FillListOfCashRegisters();
		If Not ValueIsFilled(Object.CashRegister) Then
			SetDefaultCashRegister();
		EndIf;
	Else
		If ValueIsFilled(Object.CashRegister) Then
			Object.CashRegister = Catalogs.CashRegisters.EmptyRef();
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	CompanyOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCurrencyExchangeRate(pHotel, pCurrency, pExchangeRateDate, pUseTCHQRate = False)
	Return cmGetCurrencyExchangeRate(pHotel, pCurrency, pExchangeRateDate, pUseTCHQRate);
EndFunction // GetCurrencyExchangeRate


// -----------------------------------------------------------------------------
&AtServer
Procedure ConvertCurrenciesTo(pCurRow)
	vCurData = Object.Conversions.FindByID(pCurRow);
	If ValueIsFilled(vCurData.CurrencyFrom) Then
		If vCurData.TravellerChequesQuantity <> 0 Then
			vCurData.CurrencyFromExchangeRate = GetCurrencyExchangeRate(Object.Hotel, vCurData.CurrencyFrom, Object.ExchangeRateDate, True);
		Else
			vCurData.CurrencyFromExchangeRate = GetCurrencyExchangeRate(Object.Hotel, vCurData.CurrencyFrom, Object.ExchangeRateDate);
		EndIf;
	Else
		vCurData.CurrencyFromExchangeRate = 0;
	EndIf;
	If ValueIsFilled(vCurData.CurrencyTo) Then
		vCurData.CurrencyToExchangeRate = GetCurrencyExchangeRate(Object.Hotel, vCurData.CurrencyTo, Object.ExchangeRateDate);
		vCurData.ToSum = cmConvertCurrencies(vCurData.FromSum, vCurData.CurrencyFrom, vCurData.CurrencyFromExchangeRate, vCurData.CurrencyTo, vCurData.CurrencyToExchangeRate, Object.ExchangeRateDate, Object.Hotel);
	Else
		vCurData.CurrencyToExchangeRate = 0;
		vCurData.ToSum = 0;
	EndIf;
EndProcedure // ConvertCurrenciesTo

// -----------------------------------------------------------------------------
&AtServer
Procedure ConvertCurrenciesFrom(pCurRow)
	vCurData = Object.Conversions.FindByID(pCurRow);
	If ValueIsFilled(vCurData.CurrencyTo) Then
		If ValueIsFilled(vCurData.CurrencyFrom) Then
			vCurData.FromSum = cmConvertCurrencies(vCurData.ToSum, vCurData.CurrencyTo, vCurData.CurrencyToExchangeRate, vCurData.CurrencyFrom, vCurData.CurrencyFromExchangeRate, Object.ExchangeRateDate, Object.Hotel);
		Else
			vCurData.ToSum = 0;
		EndIf;
	Else
		vCurData.ToSum = 0;
	EndIf;
EndProcedure // ConvertCurrenciesFrom

// -----------------------------------------------------------------------------
&AtClient
Procedure ConversionsCurrencyFromOnChange(pItem)
	vCurRow = Items.Conversions.CurrentRow;
	If vCurRow <> Undefined Then
		ConvertCurrenciesTo(vCurRow);
	EndIf;
EndProcedure // ConversionsCurrencyFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ConversionsFromSumOnChange(Item)
	vCurRow = Items.Conversions.CurrentRow;
	If vCurRow <> Undefined Then
		ConvertCurrenciesTo(vCurRow);
	EndIf;
EndProcedure // ConversionsFromSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ConversionsTravellerChequesQuantityOnChange(Item)
	vCurRow = Items.Conversions.CurrentRow;
	If vCurRow <> Undefined Then
		ConvertCurrenciesTo(vCurRow);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ConversionsCurrencyToOnChange(pItem)
	vCurRow = Items.Conversions.CurrentRow;
	If vCurRow <> Undefined Then
		ConvertCurrenciesTo(vCurRow);
	EndIf;
EndProcedure // ConversionsCurrencyToOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ConversionsToSumOnChange(Item)
	vCurRow = Items.Conversions.CurrentRow;
	If vCurRow <> Undefined Then
		ConvertCurrenciesFrom(vCurRow);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ExchangeRateDateOnChangeAtServer()
	If ValueIsFilled(Object.Hotel) And ValueIsFilled(Object.ExchangeRateDate) Then
		For Each vCurData In Object.Conversions Do
			If ValueIsFilled(vCurData.CurrencyFrom) Then
				If vCurData.TravellerChequesQuantity <> 0 Then
					vCurData.CurrencyFromExchangeRate = GetCurrencyExchangeRate(Object.Hotel, vCurData.CurrencyFrom, Object.ExchangeRateDate, True);
				Else
					vCurData.CurrencyFromExchangeRate = GetCurrencyExchangeRate(Object.Hotel, vCurData.CurrencyFrom, Object.ExchangeRateDate);
				EndIf;
			EndIf;
			If ValueIsFilled(vCurData.CurrencyTo) Then
				vCurData.CurrencyToExchangeRate = GetCurrencyExchangeRate(Object.Hotel, vCurData.CurrencyTo, Object.ExchangeRateDate);
			EndIf;
			If ValueIsFilled(vCurData.CurrencyFrom) And ValueIsFilled(vCurData.CurrencyTo) Then
				vCurData.ToSum = cmConvertCurrencies(vCurData.FromSum, vCurData.CurrencyFrom, vCurData.CurrencyFromExchangeRate, vCurData.CurrencyTo, vCurData.CurrencyToExchangeRate, Object.ExchangeRateDate, Object.Hotel);
			Else
				vCurData.ToSum = 0;
			EndIf;
		EndDo;
	Else
		Object.Conversions.Clear();
	EndIf;
EndProcedure // ExchangeRateDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ExchangeRateDateOnChange(Item)
	ExchangeRateDateOnChangeAtServer();
EndProcedure // ExchangeRateDateOnChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetSessionLanguage()
	Return SessionParameters.CurrentLanguage;
EndFunction // GetSessionLanguage

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function NeedToPrintReceipt(rPrtForm)
	rPrtForm = Catalogs.ObjectPrintingForms.FolioPrintNonFiscalChequeByCharges;
	If rPrtForm.IsActive And rPrtForm.AutomaticallyPrintOnFirstObjectWrite Then
		Return True;
	EndIf;
	Return False;
EndFunction // NeedToPrintReceipt

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetReceiptPrintSettins(pPrtForm)
	vWidth = 30;
	If ValueIsFilled(pPrtForm) And Not IsBlankString(pPrtForm.Parameter) And cmIsNumber(TrimAll(pPrtForm.Parameter)) Then
		vWidth = Number(TrimAll(pPrtForm.Parameter));
	EndIf;
	vFormPrintSettings = New Structure("ReceiptWidth, FooterText, CashRegister, PrintDirection, PrinterName, FitToPage, PrintScale, Copies, CopiesPerPage, Collate, PageOrientation, PageSize, TopMargin, BottomMargin, LeftMargin, RightMargin, HeaderSize, FooterSize, BlackAndWhite, DuplexPrintingType", 
	                                   vWidth, "en='Thank you!'; ru='Спасибо!'; de='Vielen Dank!'", Undefined, Undefined, "", True, 0, 1, 1, False, Undefined, "", 0, 0, 0, 0, 0, 0, False, Undefined);
	vWstnSettings = SessionParameters.CurrentWorkstation;
	If vWstnSettings.CashRegisters.Count() > 0 Then
		For Each vCRRow In vWstnSettings.CashRegisters Do
			If ValueIsFilled(vCRRow.CashRegister) And vCRRow.CashRegister.IsControlledByProgram Then
				vFormPrintSettings.CashRegister = vCRRow.CashRegister;
				Break;
			EndIf;
		EndDo;
	EndIf;
	If ValueIsFilled(vWstnSettings.WorkstationPrintSettings) Then
		vWstnPrintSettings = vWstnSettings.WorkstationPrintSettings;
		vPrtFrmSettingsRow = vWstnPrintSettings.PrintFormsList.Find(pPrtForm, "ObjectPrintingForm");
		If vPrtFrmSettingsRow <> Undefined And vPrtFrmSettingsRow.IsActive Then
			FillPropertyValues(vFormPrintSettings, vPrtFrmSettingsRow);
		EndIf;
	EndIf;
	Return vFormPrintSettings;
EndFunction // GetReceiptPrintSettins

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Write Then
		vPrtForm = Undefined;
		If NeedToPrintReceipt(vPrtForm) Then
			vFormPrintSettings = GetReceiptPrintSettins(vPrtForm);
			PrintTicket(vFormPrintSettings);
		EndIf;
	EndIf;
EndProcedure
 
// ------------------------------------------------------------------------------------------------
&AtClient
Procedure PrintTicket(pFormPrintSettings)
	vLanguage = Undefined;
	If ValueIsFilled(Object.Hotel) Then
		vLanguage = tcOnServer.cmGetAttributeByRef(Object.Hotel, "Language");
	EndIf;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = GetSessionLanguage();
	EndIf;
	
	// Check printer to be used
	If IsBlankString(pFormPrintSettings.PrinterName) And ValueIsFilled(Object.CashRegister) Then
		// Print non fiscal cheque via cash register printer
		vDriver = tcOnClient.cmGetModulTO(Object.CashRegister);
		If Not vDriver = Undefined Then
			// Cheque template
			vTicketText = 
			Upper(NStr("en='Currency conversion'; ru='Конвертация валют'; de='Währungsumrechnung'")) + "
			|&CurrentDate &CurrentTime
			|&Cashier
			|&Client
			|&Room
			|--------------------------------------------------------------------------------
			|" + Upper(NStr("en='Operations:'; ru='Операции:'; de='Operationen:'"));
			For Each vCurData In Object.Conversions Do
				If vCurData.TravellerChequesQuantity <> 0 Then
					vRowTxt = NStr("en='T/CHQ Q-ty: '; ru='T/CHQ кол-во: '; de='T/CHQ Menge: '") + Format(vCurData.TravellerChequesQuantity, "NFD=; NZ=; NG=") + " - " + Format(vCurData.FromSum, "NFD=2; NZ=") + " " + TrimAll(vCurData.CurrencyFrom) + " (" + TrimAll(vCurData.CurrencyFromExchangeRate) + ")";
				Else
					vRowTxt = Format(vCurData.FromSum, "NFD=2; NZ=") + " " + TrimAll(vCurData.CurrencyFrom) + " (" + TrimAll(vCurData.CurrencyFromExchangeRate) + ")";
				EndIf;
				vTicketText = vTicketText + Chars.LF + vRowTxt;
				vRowTxt = "-> " + Format(vCurData.ToSum, "NFD=2; NZ=") + " " + TrimAll(vCurData.CurrencyTo) + " (" + TrimAll(vCurData.CurrencyToExchangeRate) + ")";
				vTicketText = vTicketText + Chars.LF + vRowTxt;
			EndDo;
			vTicketText = vTicketText + Chars.LF + "--------------------------------------------------------------------------------";
			vTicketText = vTicketText + Chars.LF + "&Cliche";
			
			vMessage = "";
			vStruct = New Structure("Sum, VATSum, CashRegister, Folio, VATRate, Author, PaymentCurrency", 0, 0, Object.CashRegister, Undefined, Undefined, Object.Author, Undefined);
			If Not vDriver.pmPrintNonFiscalCheque(0, 0, vStruct, vTicketText, vMessage) Then
				vUM = New UserMessage();
				vUM.Text = vMessage;
				vUM.Message();
			EndIf;
		EndIf;
	Else
		// Print receipt on windows printer
		vBatch = New RepresentableDocumentBatch();
		
		vTicketAddress = GetTicketAtServer(vLanguage, pFormPrintSettings);
		vBatch.Content.Add(vTicketAddress);
		
		vBatch.Collate = pFormPrintSettings.Collate;
		vBatch.Copies = ?(pFormPrintSettings.Copies = 0, Undefined, pFormPrintSettings.Copies);
		vBatch.PrinterName = TrimAll(pFormPrintSettings.PrinterName);
		
		vBatch.Print(?(IsBlankString(TrimAll(pFormPrintSettings.PrinterName)), PrintDialogUseMode.Use, PrintDialogUseMode.DontUse));
	EndIf;
EndProcedure // PrintTicket

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetTicketAtServer(pLanguage, pFormPrintSettings)
	vOperationName = "en='Conversion'; ru='Конвертация'; de='Umrechnung'";
	vCompanyObj = Object.Company.GetObject();
	
	vTicket = New TextDocument();
	
	vTicketTemplateName = "Ticket" + Format(pFormPrintSettings.ReceiptWidth, "ND=2; NFD=0; NZ=; NLZ=; NG=");
	vTicketTemplate = Documents.CurrencyConversion.GetTemplate(vTicketTemplateName);
	
	vTextTicketTemplateName = vTicketTemplateName + TrimAll(pLanguage.Code);
	vTextTicketTemplate = Documents.CurrencyConversion.GetTemplate(vTextTicketTemplateName);
	
	vTicketHeaderArea = vTextTicketTemplate.GetArea("ReceiptHeader");
	vTicketHeaderArea.Parameters.Company = vCompanyObj.pmGetCompanyPrintName(pLanguage);
	vTicketHeaderArea.Parameters.Address = vCompanyObj.pmGetCompanyPostAddressPresentation(pLanguage);
	vTicketHeaderArea.Parameters.Operation = Upper(cmNStr(vOperationName, pLanguage));
	vTicketHeaderArea.Parameters.ReceiptN = cmNStr("en='N '; ru='№ '; de='N '", pLanguage) + cmGetDocumentNumberPresentation(Object.Number);
	vTicketHeaderArea.Parameters.Cashier = TrimAll(Object.Author);
	vTicketHeaderArea.Parameters.Date = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");
	vTicketHeaderArea.Parameters.Time = Format(CurrentSessionDate(), "DF=HH:mm:ss");
	If ValueIsFilled(Object.Client) Then
		vTicketHeaderArea.Parameters.Client = TrimAll(Object.Client.FullName);
	Else
		vTicketHeaderArea.Parameters.Client = "";
	EndIf;
	If ValueIsFilled(Object.Room) Then
		vTicketHeaderArea.Parameters.Room = TrimAll(Object.Room.Description);
	Else
		vTicketHeaderArea.Parameters.Room = "";
	EndIf;
	vTicket.Put(vTicketHeaderArea);
	
	For Each vRow In Object.Conversions Do
		vRowArea = vTextTicketTemplate.GetArea("ReceiptRow");
		If vRow.TravellerChequesQuantity <> 0 Then
			vRowArea.Parameters.OperationDescriptionLeft = cmNStr("en='T/CHQ Q-ty: '; ru='T/CHQ кол-во: '; de='T/CHQ Menge: '", pLanguage) + Format(vRow.TravellerChequesQuantity, "NFD=; NZ=; NG=") + " - " + Format(vRow.FromSum, "NFD=2; NZ=") + " " + TrimAll(vRow.CurrencyFrom) + " (" + TrimAll(vRow.CurrencyFromExchangeRate) + ")";
		Else
			vRowArea.Parameters.OperationDescriptionLeft = Format(vRow.FromSum, "NFD=2; NZ=") + " " + TrimAll(vRow.CurrencyFrom) + " (" + TrimAll(vRow.CurrencyFromExchangeRate) + ")";
		EndIf;
		vRowArea.Parameters.OperationDescriptionRight = "-> " + Format(vRow.ToSum, "NFD=2; NZ=") + " " + TrimAll(vRow.CurrencyTo) + " (" + TrimAll(vRow.CurrencyToExchangeRate) + ")";
		vTicket.Put(vRowArea);
	EndDo;
		
	vTicketFooterArea = vTextTicketTemplate.GetArea("ReceiptFooter");
	vTicketFooterArea.Parameters.FooterText = cmNStr(pFormPrintSettings.FooterText, pLanguage);
	vTicket.Put(vTicketFooterArea);
	
	vTicketText = vTicket.GetText();
	vTextRowsArray = cmGetTextLinesArray(vTicketText);
	
	vTicketSpreadsheet = New SpreadsheetDocument();
	For Each vTextRow In vTextRowsArray Do
		vTicketRowArea = vTicketTemplate.GetArea("ReceiptRow");
		vTicketRowArea.Parameters.RowText = vTextRow;
		vTicketSpreadsheet.Put(vTicketRowArea);
	EndDo;
	
	vTempAddress = PutToTempStorage(vTicketSpreadsheet);
	
	Return vTempAddress;
EndFunction // GetTicketAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ConversionsOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow And Not pClone And ValueIsFilled(Object.Hotel) Then
		vCurRow = Items.Conversions.CurrentRow;
		If vCurRow <> Undefined Then
			vCurData = Object.Conversions.FindByID(vCurRow);
			vCurData.CurrencyTo = tcOnServer.cmGetAttributeByRef(Object.Hotel, "BaseCurrency");
			vCurData.CurrencyToExchangeRate = 1;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomOnChangeAtServer()
	If ValueIsFilled(Object.Room) Then
		vRoomGuests = cmGetRoomGuests(Object.Hotel, Undefined, Object.Room, BegOfDay(CurrentSessionDate()), EndOfDay(CurrentSessionDate()));
		vMainGuest = Undefined;
		Items.Client.ChoiceList.Clear();
		For Each vRoomGuestsRow In vRoomGuests Do
			If ValueIsFilled(vRoomGuestsRow.Guest) Then
				If vRoomGuestsRow.AccommodationTypeType = Enums.AccomodationTypes.Room Or vRoomGuestsRow.AccommodationTypeType = Enums.AccomodationTypes.Beds Then
					vMainGuest = vRoomGuestsRow.Guest;
				EndIf;
				Items.Client.ChoiceList.Add(vRoomGuestsRow.Guest);
			EndIf;
		EndDo;
		If ValueIsFilled(vMainGuest) Then
			Object.Client = vMainGuest;
		EndIf;
		If Items.Client.ChoiceList.Count() > 0 Then
			Items.Client.ListChoiceMode = True;
		Else
			Items.Client.ListChoiceMode = False;
		EndIf;
	Else
		Items.Client.ListChoiceMode = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomOnChange(Item)
	RoomOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintTicketAtClient(pCommand)
	vPrtForm = PredefinedValue("Catalog.ObjectPrintingForms.FolioPrintNonFiscalChequeByCharges");
	vFormPrintSettings = GetReceiptPrintSettins(vPrtForm);
	PrintTicket(vFormPrintSettings);
EndProcedure
