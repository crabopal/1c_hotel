
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(Object.Hotel) And SessionParameters.CurrentHotel <> Object.Hotel Then
			pCancel = True;
		EndIf;
	EndIf;	
	vObj = FormAttributeToValue("Object");
	If vObj.IsNew() Then
		// Use current time by default
		If Not Parameters.SkipTimeSetting Then
			vObj.SetTime(AutoTimeMode.CurrentOrLast);
		EndIf;
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			If Not Parameters.SkipTimeSetting Then
				vObj.pmFillAuthorAndDate();
			EndIf;
		EndIf;
	EndIf;
	// Check edit prohibited date
	If ValueIsFilled(vObj.Hotel) Then
		If ValueIsFilled(vObj.Hotel.EditProhibitedDate) And 
		   BegOfDay(vObj.Hotel.EditProhibitedDate) >= BegOfDay(vObj.Date) Then
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;	
	// Check permission to edit client type
	If Not cmCheckUserPermissions("HavePermissionToChooseClientTypeManually") Then
		Items.ClientType.Enabled = False;
		Items.LabelClientTypeConfirmationText.Enabled = False;
	EndIf;
	// Fill folio description
	FillFolioDescription();
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
	// Set view only mode
	If vObj.Posted Then
		If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
			ThisForm.ReadOnly = True;
		EndIf;
	Else
		If vObj.IsNew() And Not ValueIsFilled(vObj.Service) Then
			// Check if there are any client types
			vClientTypes = cmGetAllClientTypes();
			If vClientTypes.Count() > 0 Then
				ThisForm.CurrentItem = Items.ClientType;
			Else
				// Open services choice form
				vSrvFrm = Catalogs.Services.GetChoiceForm("ChoiceForm", vObj.Service, ThisForm);
				vSrvFrm.ChoiceFoldersAndItemsParameter = FoldersAndItemsUse.Items;
				vSrvFrm.DoModal();
			EndIf;
		EndIf;
	EndIf;	
	ValueToFormAttribute(vObj, "Object");
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	ChoiceProcessingAtServer(pSelectedValue);
EndProcedure // ChoiceProcessing

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		SetObjectAndFormAttributeConformity(pCurrentObject, "Object");
		// Basic checks
		vMessage = "";
		vAttributeInErr = "";
		If pCurrentObject.pmCheckDocumentAttributes(vMessage, vAttributeInErr) Then
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = vAttributeInErr;
			vUM.Text = NStr(vMessage);
			vUM.Message();
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure // DateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	ClientTypeOnChangeAtServer();
	If ValueIsFilled(Object.ClientType) Then
		If tcOnServer.cmGetAttributeByRef(Object.ClientType, "AskForConfirmation") Then
			If IsBlankString(Object.ClientTypeConfirmationText) Or Upper(TrimAll(Object.ClientTypeConfirmationText)) = Upper(TrimAll(tcOnServer.cmGetAttributeByRef(Object.ClientType, "ConfirmationPattern"))) Then
				ClientTypeConfirmationTextClick(Items.ClientTypeConfirmationText, False);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ClientTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeConfirmationTextClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(Object.ClientType) Then
		If tcOnServer.cmGetAttributeByRef(Object.ClientType, "AskForConfirmation") Then
			If IsBlankString(Object.ClientTypeConfirmationText) Then
				Object.ClientTypeConfirmationText = tcOnServer.cmGetAttributeByRef(Object.ClientType, "ConfirmationPattern");
			EndIf;
			ShowInputString(New NotifyDescription("ClientTypeConfirmationTextAfterInput", ThisForm), Object.ClientTypeConfirmationText,
			                NStr("ru='Заполните шаблон строки подтверждения!';
			                     |de='Vorlage der Bestätigungszeile ausfüllen!';
			                     |en='Please fill confirmation text pattern!'"),
			                100, False);
		Else
			Object.ClientTypeConfirmationText = "";
		EndIf;
	Else
		Object.ClientTypeConfirmationText = "";
	EndIf;
EndProcedure // ClientTypeConfirmationTextClick

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceOnChange(pItem)
	ServiceOnChangeAtServer();
EndProcedure // ServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceStartChoice(pItem, pChoiceData, pStandardProcessing)
	// APDEX
	vKeyOperation = "Catalog.Services.Form.tcChoiceForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
		
	pStandardProcessing = False;
	OpenForm("Catalog.Services.Form.tcChoiceForm",
	         new Structure("CurrentRow, Hotel, ClientType, AccountingDate", Object.Service, Object.Hotel, Object.ClientType, Object.Date),
			 pItem,
	         ThisForm.UUID);
EndProcedure // ServiceStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceOnChange(pItem)
	PriceOnChangeAtServer();
EndProcedure // PriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure QuantityOnChange(pItem)
	QuantityOnChangeAtServer();
EndProcedure // QuantityOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SumOnChange(pItem)
	ProcessSumChange();
EndProcedure // SumOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionChooseFolio(pCommand)
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToChangeFolioInFolioTransactions") Then
		OpenForm("Document.Folio.ChoiceForm", 
				new Structure("CurrentRow, MultipleChoice, CloseOnChoice", Object.Folio, False, True), 
				ThisForm, 
				ThisForm.UUID);
	Else
		ShowMessageBox(,NStr("en='You do not have rights to change folio!';ru='Нет прав на смену лицевого счета!';de='Sie haben keine Rechte, das Personenkonto zu wechseln!'"));
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFolioDescription()
	vClientDescr = "";
	If ValueIsFilled(Object.Folio.Client) Then
		vClientDescr = String(Object.Folio.Client);
	ElsIf ValueIsFilled(Object.Folio.Customer) Then
		vClientDescr = String(Object.Folio.Customer);
	ElsIf ValueIsFilled(Object.Folio.Room) Then
		vClientDescr = String(Object.Folio.Room);
	EndIf;
	vClientDescr = vClientDescr + ?(IsBlankString(Object.Folio.Description), "", " - " + TrimAll(Object.Folio.Description));
	Items.FolioDescription.Title = ?(IsBlankString(vClientDescr), "", TrimAll(vClientDescr));
EndProcedure // FillFolioDescription

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	// Automatically assign new document number if year has changed
	If ValueIsFilled(Object.Date) And ValueIsFilled(OldDate) Then
		If Year(OldDate) <> Year(Object.Date) Then
		vObj = FormAttributeToValue("Object");	
		vObj.SetNewNumber();
		ValueToFormAttribute(vObj, "Object");	
		EndIf;
		OldDate = Object.Date;
	EndIf;
EndProcedure // DateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ChoiceProcessingAtServer(pSelectedValue)
	If TypeOf(pSelectedValue) = Type("DocumentRef.Folio") Then
		vObj = FormAttributeToValue("Object");
		vObj.Folio = pSelectedValue;
		vObj.FolioCurrency = vObj.Folio.FolioCurrency;
		vObj.Hotel = vObj.Folio.Hotel;
		vObj.ParentDoc = vObj.Folio.ParentDoc;
		vObj.GuestGroup = vObj.Folio.GuestGroup;
		vObj.Client = vObj.Folio.Client;
		vObj.Room = vObj.Folio.Room;
		// Fill folio description
		FillFolioDescription();
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // ChoiceProcessingAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClientTypeOnChangeAtServer()
	// Retrieve price for the given client type
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.Service) Then
		vCurPrice = 0;
		vCurUnit = vObj.Unit;
		vCurCurrency = vObj.FolioCurrency;
		vServiceObj = vObj.Service.GetObject();
		vSrvPrices = vServiceObj.pmGetServicePrices(vObj.Hotel, vObj.Date, vObj.ClientType);
		For Each vSrvPricesRow In vSrvPrices Do
			vCurPrice = vSrvPricesRow.Price;
			vCurUnit = vObj.Service.Unit;
			vCurCurrency = vSrvPricesRow.Currency;
			Break;
		EndDo;
		If vCurPrice = 0 Then
			If ValueIsFilled(vObj.ClientType) Then
				vSrvPrices = vServiceObj.pmGetServicePrices(vObj.Hotel, vObj.Date, vObj.Catalogs.ClientTypes.EmptyRef());
				For Each vSrvPricesRow In vSrvPrices Do
					vCurPrice = vSrvPricesRow.Price;
					vCurUnit = vObj.Service.Unit;
					vCurCurrency = vSrvPricesRow.Currency;
					Break;
				EndDo;
			EndIf;
		EndIf;
		If vObj.Quantity = 0 Then
			vObj.Quantity = 1;
		EndIf;
		If vCurPrice = 0 Then
			vCurPrice = vObj.Price;
			vCurUnit = vObj.Unit;
			vCurCurrency = vObj.FolioCurrency;
		EndIf;
		vObj.Price = Round(cmConvertCurrencies(vCurPrice, vCurCurrency, , 
		                                  vObj.FolioCurrency, 
		                                  , 
		                                  , vObj.Hotel), 2);
		vObj.Unit = vCurUnit;
		vObj.Sum = Round(vObj.Price * vObj.Quantity, 2);
	EndIf;
	ValueToFormAttribute(vObj, "Object");
	// Recalculate sums
	ProcessSumChange();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ProcessSumChange()
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.Service) Then
		If vObj.Service.RecalculatePriceWhenSumChanged And Not IsChargeSplit Then
			If vObj.Quantity = 0 And vObj.Sum > 0 Then
				vObj.Quantity = 1;
			EndIf;
			vObj.Price = ?(vObj.Quantity = 0, 0, Round(vObj.Sum / vObj.Quantity, 2));
		Else
			vObj.Quantity = ?(vObj.Price = 0, 1, Round(vObj.Sum / vObj.Price, 7));
		EndIf;
	Else
		vObj.Quantity = ?(vObj.Price = 0, 1, Round(vObj.Sum / vObj.Price, 7));
	EndIf;
	ValueToFormAttribute(vObj, "Object");
EndProcedure // ProcessSumChange

// -----------------------------------------------------------------------------
&AtServer
Procedure QuantityOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Sum = Round(vObj.Price * vObj.Quantity, 2);
	ValueToFormAttribute(vObj, "Object");
	ProcessSumChange();
EndProcedure // QuantityOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PriceOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Sum = Round(vObj.Price * vObj.Quantity, 2);
	ValueToFormAttribute(vObj, "Object");
	ProcessSumChange();
EndProcedure // PriceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServiceOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.Service) Then
		vCurPrice = 0;
		vCurUnit = vObj.Service.Unit;
		vCurCurrency = vObj.FolioCurrency;
		vServiceObj = vObj.Service.GetObject();
		vSrvPrices = vServiceObj.pmGetServicePrices(vObj.Hotel, vObj.Date, vObj.ClientType); 
		For Each vSrvPricesRow In vSrvPrices Do
			vCurPrice = vSrvPricesRow.Price;
			vCurUnit = vObj.Service.Unit;
			vCurCurrency = vSrvPricesRow.Currency;
			Break;
		EndDo;
		If vCurPrice = 0 Then
			If ValueIsFilled(vObj.ClientType) Then
				vSrvPrices = vServiceObj.pmGetServicePrices(vObj.Hotel, vObj.Date, vObj.Catalogs.ClientTypes.EmptyRef());
				For Each vSrvPricesRow In vSrvPrices Do
					vCurPrice = vSrvPricesRow.Price;
					vCurUnit = vObj.Service.Unit;
					vCurCurrency = vSrvPricesRow.Currency;
					Break;
				EndDo;
			EndIf;
		EndIf;
		If vObj.Quantity = 0 Then
			vObj.Quantity = 1;
		EndIf;
		vObj.Price = Round(cmConvertCurrencies(vCurPrice, vCurCurrency, , 
		                                  vObj.FolioCurrency, 
		                                  , 
		                                  , vObj.Hotel), 2);
		vObj.Unit = vCurUnit;
		vObj.Sum = Round(vObj.Price * vObj.Quantity, 2);
		// Check if user can edit service price
		Items.Price.ReadOnly = False;
		If Not vObj.Service.AllowChangePrice Then
			If Not cmCheckUserPermissions("HavePermissionToEditServicePrices") Then
				Items.Price.ReadOnly = True;
			EndIf;
		EndIf;
	EndIf;
	ValueToFormAttribute(vObj, "Object");
	// Recalculate 
	ProcessSumChange();
EndProcedure // ServiceOnChangeAtServer


#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pStr		 - String	 - Result user input
//  pExtraParams - Structure - Additional properties
//
&AtClient
Procedure ClientTypeConfirmationTextAfterInput(pStr, pExtraParams) Export 
	If pStr <> Undefined Then
		If Upper(TrimAll(pStr)) = Upper(TrimAll(tcOnServer.cmGetAttributeByRef(Object.ClientType, "ConfirmationPattern"))) Then
			ShowMessageBox(, NStr("ru='Строка подтверждения совпадает с шаблоном! Выбор типа клиента будет отменен.';
			                      |de='Zeile für die Bestätigung stimmt mit Vorlage überein! Die Auswahl des Kundentyps wird zurückgesetzt!'; 
			                      |en='Confirmation text is the same as confirmation pattern! Client type will be cleared.'"));
			Object.ClientType = PredefinedValue("Catalog.ClientTypes.EmptyRef");
			Object.ClientTypeConfirmationText = "";
			ClientTypeOnChange(Items.ClientType);
		ElsIf IsBlankString(pStr) Then
			ShowMessageBox(, NStr("ru='Строка подтверждения не введена! Выбор типа клиента будет отменен.';
			                      |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl des Kundentyps wird zurückgesetzt.'; 
						          |en='Confirmation text is not entered! Client type will be cleared.'"));
			Object.ClientType = PredefinedValue("Catalog.ClientTypes.EmptyRef");
			Object.ClientTypeConfirmationText = "";
			ClientTypeOnChange(Items.ClientType);
		Else
			Object.ClientTypeConfirmationText = TrimAll(pStr);
		EndIf;
	Else
		ShowMessageBox(, NStr("ru='Строка подтверждения не введена! Выбор типа клиента будет отменен.';
		                      |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl des Kundentyps wird zurückgesetzt.'; 
						      |en='Confirmation text is not entered! Client type will be cleared.'"));
		Object.ClientType = PredefinedValue("Catalog.ClientTypes.EmptyRef");
		Object.ClientTypeConfirmationText = "";
		ClientTypeOnChange(Items.ClientType);
	EndIf;
EndProcedure // ClientTypeConfirmationTextAfterInput

#EndRegion






