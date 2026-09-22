
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Fill attributes from parameters
	If Parameters.Property("RoomRate") Then
		 Object.RoomRate = Parameters.RoomRate;
	EndIf;
	 
	// Write button appearance
	If Object.Posted Then
		Items.FormWrite.Enabled = False;
		Items.FormWrite.Visible = False;
	EndIf;
    Items.ChangeProtection.Visible = False;
	
	vObject = FormAttributeToValue("Object");	
	
	// Check user rights to use document
	If not ValueIsFilled(vObject.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights to manage prices!'; de = 'Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'; ru = 'Нет прав на управление услугами и ценами!'"));
		EndIf;		
		vObject.SetTime(AutoTimeMode.DontUse);
		If Not ValueIsFilled(vObject.Author) Then
			vObject.pmFillAttributesWithDefaultValues();
		Else
			vObject.pmFillAuthorAndDate();
		EndIf;				
	EndIf;
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(vObject.Hotel) And SessionParameters.CurrentHotel <> vObject.Hotel Then
			pCancel = True;
		EndIf;
	EndIf;	
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	Else
		// Check if there are any reservation with Price calculation date grater than document date.
		If Not vObject.IsNew() Then
			If RatesManagement.IsRoomRateInUse(vObject.Date, vObject.RoomRate,vObject.CalendarDayType, vObject.PriceTag) Then
				ReadOnly = True;
				Items.ChangeProtection.Visible = True;
			EndIf;
		EndIf;
		// Check user rights to edit room rates
		If Not cmCheckUserPermissions("HavePermissionToApproveRoomRates") Then
			Items.RoomRatesApproved.Enabled = False;
		Else
			Items.RoomRatesApproved.Enabled = True;
		EndIf;
	EndIf;
	
	// Client types choice
	vClientTypes = GetClientTypes();
	Items.ClientType.ChoiceList.Add(Catalogs.ClientTypes.EmptyRef(), NStr("en = 'Empty client type'; ru = 'Пустой тип клиента'; de = 'Leerer Kundentyp!'"));	
	For Each vClientTypesRow In vClientTypes Do
		Items.ClientType.ChoiceList.Add(vClientTypesRow.ClientType, TrimAll(vClientTypesRow.Description));
	EndDo;
	Items.ClientType.ColumnsCount = vClientTypes.Count() + 1;
	
	DayTypeAndPriceTagFormulasView = GetDayTypeAndPriceTagFormulasMode();
	
	OldDate = Object.Date;
	
	// Appearance of prices are approved items
	RoomRatesApprovedAppearance();
	
	// Appearance of the prices table
	PricesAppearance();
	
	// Appearance of the day types and price tags formulas
	FormulasForDayTypesAndPriceTagsAvailability();
	
	// Fill room type parent column
	FillRoomTypeParentColumn("Prices");
	FillRoomTypeParentColumn("Formulas");
	FillRoomTypeParentColumn("FormulasForDayTypesAndPricetags");
	
	// Set default filter by empty client type
	SetFilter();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	WasModified = (ThisObject.Modified Or Not Object.Posted) And 
	              pWriteParameters.WriteMode = DocumentWriteMode.Posting;
	If WasModified Then
		// APDEX
		vKeyOperation = "Document.SetRoomRatePrices.Form.tcDocumentForm.Posting";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If Not ReadOnly Then
		vCopyValueButton = Items.PricesCopy;
		vPasteValueButton = Items.PricesPaste;
		If amClipboard.Property("SetRoomRatePricesPrices") Then
			vCopyValueButton.Check = True;
			vPasteValueButton.Enabled = True;
			vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "SetRoomRatePricesActionRestore" Then		
		Restore(pParameter);		
	ElsIf pEventName = "SetRoomRatePricesCopyRows" Then
		If Not ReadOnly Then
			vCopyValueButton = Items.PricesCopy;
			vPasteValueButton = Items.PricesPaste;
			If amClipboard.Property("SetRoomRatePricesPrices") Then
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
			EndIf;
		EndIf;
	ElsIf pEventName = "SetRoomRatePricesCancelCopyRows" Then
		vCopyValueButton = Items.PricesCopy;
		vPasteValueButton = Items.PricesPaste;
		ColumnCopied = Undefined;
		ValueCopied = Undefined;
	ElsIf pEventName = "SetRoomRatePricesCopyRowsFormulas" Then
		If Not ReadOnly Then
			vCopyValueButton = Items.FormulasCopy;
			vPasteValueButton = Items.FormulasPaste;
			If amClipboard.Property("SetRoomRatePricesFormulas") Then
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
			EndIf;
		EndIf;
	ElsIf pEventName = "SetRoomRatePricesCancelCopyRowsFormulas" Then
		vCopyValueButton = Items.FormulasCopy;
		vPasteValueButton = Items.FormulasPaste;
		ColumnCopiedFormulas = Undefined;
		ValueCopiedFormulas = Undefined;
	ElsIf pEventName = "SetRoomRatePricesCopyRowsPTFormulas" Then
		If Not ReadOnly Then
			vCopyValueButton = Items.PTFormulasCopy;
			vPasteValueButton = Items.PTFormulasPaste;
			If amClipboard.Property("SetRoomRatePricesPTFormulas") Then
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
			EndIf;
		EndIf;
	ElsIf pEventName = "SetRoomRatePricesCancelCopyRowsPTFormulas" Then
		vCopyValueButton = Items.PTFormulasCopy;
		vPasteValueButton = Items.PTFormulasPaste;
		ColumnCopiedPTFormulas = Undefined;
		ValueCopiedPTFormulas = Undefined;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	// Process room rate accommodation service settings
	vRoomRate = pCurrentObject.RoomRate;
	If ValueIsFilled(vRoomRate) And Not vRoomRate.IsFolder And ValueIsFilled(vRoomRate.AccommodationService) Then
		vAccommodationService = vRoomRate.AccommodationService;
		vAccommodationServiceVATRate = Undefined;
		vAccSrvPrices = vAccommodationService.GetObject().pmGetServicePrices(pCurrentObject.Hotel, pCurrentObject.Date, Catalogs.ClientTypes.EmptyRef());
		If vAccSrvPrices.Count() > 0 Then
			vAccommodationServiceVATRate = vAccSrvPrices.Get(0).VATRate;
		EndIf;
		vAccommodationServiceQuantityCalculationRule = vAccommodationService.QuantityCalculationRule;
		If ValueIsFilled(vRoomRate.QuantityCalculationRule) Then
			vAccommodationServiceQuantityCalculationRule = vRoomRate.QuantityCalculationRule;
		EndIf;
		For Each vPricesRow In pCurrentObject.Prices Do
			If Not ValueIsFilled(vPricesRow.Service) Then
				vPricesRow.Service = vAccommodationService;
				vPricesRow.IsRoomRevenue = True;
				vPricesRow.IsInPrice = True;
			EndIf;
			If vPricesRow.Service = vAccommodationService Then
				If ValueIsFilled(vAccommodationServiceVATRate) And vPricesRow.VATRate <> vAccommodationServiceVATRate Then
					vPricesRow.VATRate = vAccommodationServiceVATRate;
				EndIf;
				If ValueIsFilled(vAccommodationServiceQuantityCalculationRule) And vPricesRow.QuantityCalculationRule <> vAccommodationServiceQuantityCalculationRule Then
					vPricesRow.QuantityCalculationRule = vAccommodationServiceQuantityCalculationRule;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Check document attributes
	vMessage = "";
	vAttributeInErr = "";
	pCancel = pCurrentObject.pmCheckDocumentAttributes(vMessage, vAttributeInErr);
	If pCancel Then
		SetObjectAndFormAttributeConformity(pCurrentObject, "Object");
		vUM = New UserMessage();
		vUM.SetData(pCurrentObject);
		vUM.Field = vAttributeInErr;
		vUM.Text = NStr(vMessage);
		vUM.Message();
	Else
		If pCurrentObject.Date > CurrentSessionDate() Then
			pCurrentObject.IsInFuture = True;
		Else
			pCurrentObject.IsInFuture = False;
		EndIf;
		For Each vDTPTFormulasRow In pCurrentObject.FormulasForDayTypesAndPricetags Do
			If DayTypeAndPriceTagFormulasView = 0 Then
				vDTPTFormulasRow.Multiplier = 0;
				vDTPTFormulasRow.BracketsConstant = 0;
				vDTPTFormulasRow.Constant = 0;
			Else
				vDTPTFormulasRow.Discount = 0;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Document.SetRoomRatePrices.Write", Object.Ref, ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	pCurrentObject.pmWriteToSetRoomRatePricesChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	
	// Update price cache if necessary
	vHotel = pCurrentObject.Hotel;
	If WasModified And pCurrentObject.Posted And 
	   ValueIsFilled(vHotel) And 
	   vHotel.UseRoomRateDailyPrices And 
	   ValueIsFilled(pCurrentObject.RoomRate) And 
	   Not pCurrentObject.IsInFuture Then
		vRates = pCurrentObject.pmGetListOfActiveRoomRates();
		vRatesList = New ValueList();
		vRatesList.LoadValues(vRates.UnloadColumn("RoomRate"));
		
		vDayTypes = pCurrentObject.pmGetListOfActiveCalendarDayTypes();
	
		vDateFrom = '39991231';
		vDateTo = '00010101';
		
		cmGetCacheEffectivePeriod(vRatesList, vDayTypes, vDateFrom, vDateTo);
		
		If vDateFrom <= vDateTo Then
			cmRunFillRoomRatePricesCacheAtServer(vHotel, vRatesList, vDateFrom, vDateTo);
		EndIf;
	EndIf;
	
	WasModified = False;
EndProcedure // AfterWriteAtServer

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
	SetFilter();	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypeOnChange(pItem)
	SetFilter();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomClassOnChange(pItem)
	SetFilter();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(pItem)
	SetFilter();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceOnChange(pItem)
	SetFilter();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasOnStartEdit(pItem, pNewRow, pClone)
	pItem.CurrentData.Char1 = " = (";
	pItem.CurrentData.Char2 = "+";
	pItem.CurrentData.Char3 = ") x";
	pItem.CurrentData.Char4 = "+";
	If pNewRow Then
		pItem.CurrentData.ClientType = ClientType;	
	EndIf;
EndProcedure // FormulasOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasForDayTypesAndPricetagsOnStartEdit(pItem, pNewRow, pClone)
	pItem.CurrentData.Char1 = NStr("en='Price = ('; ru='Цена = ('; de='Preis = ('");
	pItem.CurrentData.Char2 = "+";
	pItem.CurrentData.Char3 = ") x";
	pItem.CurrentData.Char4 = "+";
	If pNewRow Then
		pItem.CurrentData.ClientType = ClientType;	
	EndIf;
EndProcedure // FormulasForDayTypesAndPricetagsOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesApprovedOnChange(pItem)
	RoomRatesApprovedAppearance();
	GetDefaultDocumentDate();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceTagOnChange(pItem)
	GetDefaultDocumentDate();
	FormulasForDayTypesAndPriceTagsAvailability();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CalendarDayTypeOnChange(pItem)
	GetDefaultDocumentDate();
	FormulasForDayTypesAndPriceTagsAvailability();
EndProcedure // CalendarDayTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	RoomRatesApprovedAppearance();
	PricesAppearance();
	GetDefaultDocumentDate();	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PricesOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow Then
		pItem.CurrentData.ClientType = ClientType;
	EndIf;
EndProcedure // PricesOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure PricesServiceOnChange(pItem)
	PricesServiceOnChangeAtServer(Items.Prices.CurrentRow);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DayTypeAndPriceTagFormulasViewOnChange(pItem)
	FormulasForDayTypesAndPriceTagsAvailability();
EndProcedure // DayTypeAndPriceTagFormulasViewOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	Object.Number = "";
EndProcedure // HotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PricesRoomClassOnChange(pItem)
	vCurRow = Items.Prices.CurrentData;
	If ValueIsFilled(vCurRow.RoomClass) Then
		vCurRow.RoomType = Undefined;
	EndIf;
EndProcedure // PricesRoomClassOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PricesRoomTypeOnChange(pItem)
	vCurRow = Items.Prices.CurrentData;
	If ValueIsFilled(vCurRow.RoomType) Then
		vCurRow.RoomClass = Undefined;
	EndIf;
EndProcedure // PricesRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasRoomClassOnChange(pItem)
	vCurRow = Items.Formulas.CurrentData;
	If ValueIsFilled(vCurRow.RoomClass) Then
		vCurRow.RoomType = Undefined;
	EndIf;
EndProcedure // FormulasRoomClassOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasRoomTypeOnChange(pItem)
	vCurRow = Items.Formulas.CurrentData;
	If ValueIsFilled(vCurRow.RoomType) Then
		vCurRow.RoomClass = Undefined;
	EndIf;
EndProcedure // FormulasRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasForDayTypesAndPricetagsRoomClassOnChange(pItem)
	vCurRow = Items.FormulasForDayTypesAndPricetags.CurrentData;
	If ValueIsFilled(vCurRow.RoomClass) Then
		vCurRow.RoomType = Undefined;
	EndIf;
EndProcedure // FormulasForDayTypesAndPricetagsRoomClassOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasForDayTypesAndPricetagsRoomTypeOnChange(pItem)
	vCurRow = Items.FormulasForDayTypesAndPricetags.CurrentData;
	If ValueIsFilled(vCurRow.RoomType) Then
		vCurRow.RoomClass = Undefined;
	EndIf;
EndProcedure // FormulasForDayTypesAndPricetagsRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PricesOnEditEnd(pItem, pNewRow, pCancelEdit)
	TabularPartRowOnEditEnd("Prices");
EndProcedure // PricesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasOnEditEnd(pItem, pNewRow, pCancelEdit)
	TabularPartRowOnEditEnd("Formulas");
EndProcedure // FormulasOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasForDayTypesAndPricetagsOnEditEnd(pItem, pNewRow, pCancelEdit)
	TabularPartRowOnEditEnd("FormulasForDayTypesAndPricetags");
EndProcedure // FormulasForDayTypesAndPricetagsOnEditEnd

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandFillByDefaultAction(pCommand)
	If Not ValueIsFilled(Object.Hotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Hotel attribute should be filled!';ru='Гостиница должна быть выбрана!';de='Das Hotel muss ausgewählt sein!'"));
		Return;
	EndIf;
	// Clear rows for client type selected
	vRows = Object.Prices.FindRows(New Structure("ClientType", ClientType));
	If vRows.Count() > 0 Then
		vText = NStr("en='Clear rows for client type selected?';ru='Удалить строки для выбранного типа клиента?';de='Zeilen für den ausgewählten Kundentyp löschen?'");
		ShowQueryBox(New NotifyDescription("DeleteAnswer", ThisObject), vText,QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
	Else
		If Not Items.PricesService.Visible Then
			CommandFillByDefaultActionAtServer(Undefined);
		Else
			// APDEX
			vKeyOperation = "Catalog.Services.Form.tcChoiceForm.OpenForm";
			APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

			OpenForm("Catalog.Services.ChoiceForm",New Structure("Hotel, ClientType, AccountingDate, MultipleChoice", Object.Hotel, ClientType, Object.Date, False), ThisObject, , , , New NotifyDescription("ServicesAnswer", ThisObject));	
		EndIf;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangePrice(pCommand)
	vSelectedRows = Items.Prices.SelectedRows;
	If vSelectedRows.Count() > 0 Then
		vActionType = Undefined;
		ShowInputValue(New NotifyDescription("InputValueChoice", ThisObject), , NStr("en='Choose action type';ru='Выберите тип действия';de=' Wählen Sie die Aktionsart'"), Type("EnumRef.ChangePriceActionTypes"));
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='There is no selected rows!';ru='Нет выделенных строк!';de='Es gibt keine markierten Zeilen!'"));
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillCopy(pCommand)	
	// Clear rows for client type selected
	vRows = Object.Prices.FindRows(New Structure("ClientType", ClientType));
	If vRows.Count() > 0 Then
		vText = NStr("en='Clear rows for client type selected?';ru='Удалить строки для выбранного типа клиента?';de='Zeilen für den ausgewählten Kundentyp löschen?'");
		ShowQueryBox(New NotifyDescription("DeleteAnswerCopy", ThisObject), vText,QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
	Else
		Items.ClientType.ChoiceList.ShowChooseItem(New NotifyDescription("ClientTypeAnswer", ThisObject), NStr("en='Choose client type';ru='Выберите тип клиента';de='Wählen Sie den Kundentyp'"));		
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateService(pCommand)
	vServicesList = New ValueList();
	For Each vRow In Object.Prices Do
		If ValueIsFilled(vRow.Service) Then
			If vServicesList.FindByValue(vRow.Service) = Undefined Then
				vServicesList.Add(vRow.Service);
			EndIf;
		EndIf;
	EndDo;
	vServicesList.ShowChooseItem(New NotifyDescription("FillByTemplateServiceAnswer", ThisObject), NStr("en='Choose template service';ru='Выберите услугу - шаблон';de='Wählen Sie die Dienstleistung - Vorlage'"));	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomClass(pCommand)
	vRoomClassesList = New ValueList();
	For Each vRow In Object.Prices Do
		If ValueIsFilled(vRow.RoomClass) Then
			If vRoomClassesList.FindByValue(vRow.RoomClass) = Undefined Then
				vRoomClassesList.Add(vRow.RoomClass);
			EndIf;
		EndIf;
	EndDo;
	vRoomClassesList.ShowChooseItem(New NotifyDescription("FillByTemplateRoomClassAnswer", ThisObject), NStr("en='Choose template room class';ru='Выберите класс номера - шаблон';de='Wählen Sie die Zimmerklass - Vorlage'"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomType(pCommand)
	vServicesList = New ValueList();
	For Each vRow In Object.Prices Do
		If ValueIsFilled(vRow.RoomType) Then
			If vServicesList.FindByValue(vRow.RoomType) = Undefined Then
				vServicesList.Add(vRow.RoomType);
			EndIf;
		EndIf;
	EndDo;
	vServicesList.ShowChooseItem(New NotifyDescription("FillByTemplateRoomTypeAnswer", ThisObject), NStr("en='Choose template room type';ru='Выберите тип номера - шаблон';de='Wählen Sie die Zimmertyp - Vorlage'"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateAccommodationType(pCommand)
	vAccommodationTypeList = New ValueList();
	For Each vRow In Object.Prices Do
		If ValueIsFilled(vRow.AccommodationType) Then
			If vAccommodationTypeList.FindByValue(vRow.AccommodationType) = Undefined Then
				vAccommodationTypeList.Add(vRow.AccommodationType);
			EndIf;
		EndIf;
	EndDo;
	vAccommodationTypeList.ShowChooseItem(New NotifyDescription("FillByTemplateAccommodationTypeAnswer", ThisObject),NStr("en='Choose template accommodation type';ru='Выберите вид размещения - шаблон';de='Wählen Sie die Unterkunfttyp - Vorlage'"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Copy(pCommand)
	vCopyValueButton = Items.PricesCopy;
	vPasteValueButton = Items.PricesPaste;
	amClipboard.Delete("SetRoomRatePricesPrices");
	If vCopyValueButton.Check Then
		ColumnCopied = Undefined;
		ValueCopied = Undefined;
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Notify("SetRoomRatePricesCancelCopyRows", Undefined, ThisObject);
	Else
		vCurRow = Items.Prices.CurrentRow;
		If vCurRow <> Undefined Then
			vSelectedRows = Items.Prices.SelectedRows;
			
			If vSelectedRows.Count() > 1 Then				
				ColumnCopied = "SelectedRows";
				ValueCopied = GetRows(vSelectedRows);
				amClipboard.Insert("SetRoomRatePricesPrices", ValueCopied);
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
				Notify("SetRoomRatePricesCopyRows", ValueCopied, ThisObject);				
			Else
				ColumnCopied = StrReplace(Items.Prices.CurrentItem.Name, "Prices", "");
				ValueCopied = Items.Prices.CurrentData[ColumnCopied];
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste ';ru='Вставить ';de='Einsetzen '") + TrimAll(ValueCopied);				
			EndIf;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Row is not selected!';ru='Не выбрана строка!';de='Keine Zeile ist gewählt!'"));
			ColumnCopied = Undefined;
			ValueCopied = Undefined;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Paste(pCommand)
	vCopyValueButton = Items.PricesCopy;
	vPasteValueButton = Items.PricesPaste;
	
	vSelectedRows = Undefined;
	
	If amClipboard.Property("SetRoomRatePricesPrices") Then
		UploadTable(amClipboard.SetRoomRatePricesPrices);
		amClipboard.Delete("SetRoomRatePricesPrices");
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Notify("SetRoomRatePricesCancelCopyRows", Undefined, ThisObject);
	Else
		vSelectedRows = Items.Prices.SelectedRows;
		If vSelectedRows.Count() > 0 Then
			For Each vRow In vSelectedRows Do				
				Object.Prices.FindByID(vRow)[ColumnCopied] = ValueCopied;			
			EndDo;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Else
			ShowMessageBox(, NStr("en='There is no selected rows!';ru='Нет выделенных строк!';de='Es gibt keine markierten Zeilen!'"));
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateDayTypeForDayTypeFormulas(pCommand)
	vFormulasList = New ValueList();
	For Each vRow In Object.FormulasForDayTypesAndPricetags Do
		If ValueIsFilled(vRow.CalendarDayType) Then
			If vFormulasList.FindByValue(vRow.CalendarDayType) = Undefined Then
				vFormulasList.Add(vRow.CalendarDayType);
			EndIf;
		EndIf;
	EndDo;
	vFormulasList.ShowChooseItem(New NotifyDescription("FillByTemplateDayTypeForDayTypeFormulasAnswer", ThisObject), NStr("en='Choose template day type';ru='Выберите тип дня - шаблон';de='Wählen Sie die Tagestyp - Vorlage'"));			
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplatePriceTagForDayTypeFormulas(pCommand)
	vFormulasList = New ValueList();
	For Each vRow In Object.FormulasForDayTypesAndPricetags Do
		If ValueIsFilled(vRow.PriceTag) Then
			If vFormulasList.FindByValue(vRow.PriceTag) = Undefined Then
				vFormulasList.Add(vRow.PriceTag);
			EndIf;
		EndIf;
	EndDo;
	vFormulasList.ShowChooseItem(New NotifyDescription("FillByTemplatePriceTagForDayTypeFormulasAnswer", ThisObject), NStr("en='Choose template price tag';ru='Выберите признак цены - шаблон';de='Wählen Sie das Preisschild - Vorlage'"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillCopyForDayTypeFormulas(pCommand)	
	// Clear rows for client type selected
	vRows = Object.FormulasForDayTypesAndPricetags.FindRows(New Structure("ClientType", ClientType));
	If vRows.Count() > 0 Then
		vText = NStr("en='Clear rows for client type selected?';ru='Удалить строки для выбранного типа клиента?';de='Zeilen für den ausgewählten Kundentyp löschen?'");
		ShowQueryBox(New NotifyDescription("DeleteAnswerCopyForDayTypeFormulas", ThisObject), vText,QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
	Else
		Items.ClientType.ChoiceList.ShowChooseItem(New NotifyDescription("ClientTypeForDayTypeFormulasAnswer", ThisObject), NStr("en='Choose client type';ru='Выберите тип клиента';de='Wählen Sie den Kundentyp'"));		
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomTypeForDayTypeFormulas(pCommand)
	vFormulasList = New ValueList();
	For Each vRow In Object.FormulasForDayTypesAndPricetags Do
		If ValueIsFilled(vRow.RoomType) Then
			If vFormulasList.FindByValue(vRow.RoomType) = Undefined Then
				vFormulasList.Add(vRow.RoomType);
			EndIf;
		EndIf;
	EndDo;
	vFormulasList.ShowChooseItem(New NotifyDescription("FillByTemplateRoomTypeForDayTypeFormulasAnswer", ThisObject), NStr("en='Choose template room type';ru='Выберите тип номера - шаблон';de='Wählen Sie die Zimmertyp - Vorlage'"));			
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomClassForDayTypeFormulas(pCommand)
	vFormulasList = New ValueList();
	For Each vRow In Object.FormulasForDayTypesAndPricetags Do
		If ValueIsFilled(vRow.RoomClass) Then
			If vFormulasList.FindByValue(vRow.RoomClass) = Undefined Then
				vFormulasList.Add(vRow.RoomClass);
			EndIf;
		EndIf;
	EndDo;
	vFormulasList.ShowChooseItem(New NotifyDescription("FillByTemplateRoomClassForDayTypeFormulasAnswer", ThisObject), NStr("en='Choose template room class';ru='Выберите класс номера - шаблон';de='Wählen Sie die Zimmerklass - Vorlage'"));			
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillCopyForFormulas(pCommand)	
	// Clear rows for client type selected
	vRows = Object.Formulas.FindRows(New Structure("ClientType", ClientType));
	If vRows.Count() > 0 Then
		vText = NStr("en='Clear rows for client type selected?';ru='Удалить строки для выбранного типа клиента?';de='Zeilen für den ausgewählten Kundentyp löschen?'");
		ShowQueryBox(New NotifyDescription("DeleteAnswerCopyForFormulas", ThisObject), vText,QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
	Else
		Items.ClientType.ChoiceList.ShowChooseItem(New NotifyDescription("ClientTypeForFormulasAnswer", ThisObject), NStr("en='Choose client type to copy rows from';ru='Выберите тип клиента, у которого скопировать строки';de='Wählen Sie den Clienttyp aus, von dem Zeilen kopiert werden sollen'"));		
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomTypeForFormulas(pCommand)
	vFormulasList = New ValueList();
	For Each vRow In Object.Formulas Do
		If ValueIsFilled(vRow.RoomType) Then
			If vFormulasList.FindByValue(vRow.RoomType) = Undefined Then
				vFormulasList.Add(vRow.RoomType);
			EndIf;
		EndIf;
	EndDo;
	vFormulasList.ShowChooseItem(New NotifyDescription("FillByTemplateRoomTypeForFormulasAnswer", ThisObject), NStr("en='Choose template room type';ru='Выберите тип номера - шаблон';de='Wählen Sie die Zimmertyp - Vorlage'"));			
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomClassForFormulas(pCommand)
	vFormulasList = New ValueList();
	For Each vRow In Object.Formulas Do
		If ValueIsFilled(vRow.RoomClass) Then
			If vFormulasList.FindByValue(vRow.RoomClass) = Undefined Then
				vFormulasList.Add(vRow.RoomClass);
			EndIf;
		EndIf;
	EndDo;
	vFormulasList.ShowChooseItem(New NotifyDescription("FillByTemplateRoomClassForFormulasAnswer", ThisObject), NStr("en='Choose template room class';ru='Выберите класс номера - шаблон';de='Wählen Sie die Zimmerklass - Vorlage'"));			
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyFormulas(pCommand)
	vCopyValueButton = Items.FormulasCopy;
	vPasteValueButton = Items.FormulasPaste;
	amClipboard.Delete("SetRoomRatePricesFormulas");
	If vCopyValueButton.Check Then
		ColumnCopiedFormulas = Undefined;
		ValueCopiedFormulas = Undefined;
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Notify("SetRoomRatePricesCancelCopyRowsFormulas", Undefined, ThisObject);
	Else
		vCurRow = Items.Formulas.CurrentRow;
		If vCurRow <> Undefined Then
			vSelectedRows = Items.Formulas.SelectedRows;
			
			If vSelectedRows.Count() > 1 Then				
				ColumnCopiedFormulas = "SelectedRows";
				ValueCopiedFormulas = GetRowsFormulas(vSelectedRows);
				amClipboard.Insert("SetRoomRatePricesFormulas", ValueCopiedFormulas);
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
				Notify("SetRoomRatePricesCopyRowsFormulas", ValueCopiedFormulas, ThisObject);				
			Else
				ColumnCopiedFormulas = StrReplace(Items.Formulas.CurrentItem.Name, "Formulas", "");
				ValueCopiedFormulas = Items.Formulas.CurrentData[ColumnCopiedFormulas];
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste ';ru='Вставить ';de='Einsetzen '") + TrimAll(ValueCopiedFormulas);				
			EndIf;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Row is not selected!';ru='Не выбрана строка!';de='Keine Zeile ist gewählt!'"));
			ColumnCopiedFormulas = Undefined;
			ValueCopiedFormulas = Undefined;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PasteFormulas(pCommand)
	vCopyValueButton = Items.FormulasCopy;
	vPasteValueButton = Items.FormulasPaste;
	
	vSelectedRows = Undefined;
	
	If amClipboard.Property("SetRoomRatePricesFormulas") Then
		UploadTableFormulas(amClipboard.SetRoomRatePricesFormulas);
		amClipboard.Delete("SetRoomRatePricesFormulas");
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Notify("SetRoomRatePricesCancelCopyRowsFormulas", Undefined, ThisObject);
	Else
		vSelectedRows = Items.Formulas.SelectedRows;
		If vSelectedRows.Count() > 0 Then
			For Each vRow In vSelectedRows Do				
				Object.Formulas.FindByID(vRow)[ColumnCopiedFormulas] = ValueCopiedFormulas;			
			EndDo;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Else
			ShowMessageBox(, NStr("en='There is no selected rows!';ru='Нет выделенных строк!';de='Es gibt keine markierten Zeilen!'"));
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyPTFormulas(pCommand)
	vCopyValueButton = Items.PTFormulasCopy;
	vPasteValueButton = Items.PTFormulasPaste;
	amClipboard.Delete("SetRoomRatePricesPTFormulas");
	If vCopyValueButton.Check Then
		ColumnCopiedPTFormulas = Undefined;
		ValueCopiedPTFormulas = Undefined;
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Notify("SetRoomRatePricesCancelCopyRowsPTFormulas", Undefined, ThisObject);
	Else
		vCurRow = Items.FormulasForDayTypesAndPricetags.CurrentRow;
		If vCurRow <> Undefined Then
			vSelectedRows = Items.FormulasForDayTypesAndPricetags.SelectedRows;
			
			If vSelectedRows.Count() > 1 Then				
				ColumnCopiedPTFormulas = "SelectedRows";
				ValueCopiedPTFormulas = GetRowsPTFormulas(vSelectedRows);
				amClipboard.Insert("SetRoomRatePricesPTFormulas", ValueCopiedPTFormulas);
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
				Notify("SetRoomRatePricesCopyRowsPTFormulas", ValueCopiedPTFormulas, ThisObject);				
			Else
				ColumnCopiedPTFormulas = StrReplace(Items.FormulasForDayTypesAndPricetags.CurrentItem.Name, "FormulasForDayTypesAndPricetags", "");
				ValueCopiedPTFormulas = Items.FormulasForDayTypesAndPricetags.CurrentData[ColumnCopiedPTFormulas];
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste ';ru='Вставить ';de='Einsetzen '") + TrimAll(ValueCopiedPTFormulas);				
			EndIf;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Row is not selected!';ru='Не выбрана строка!';de='Keine Zeile ist gewählt!'"));
			ColumnCopiedPTFormulas = Undefined;
			ValueCopiedPTFormulas = Undefined;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PastePTFormulas(pCommand)
	vCopyValueButton = Items.PTFormulasCopy;
	vPasteValueButton = Items.PTFormulasPaste;
	
	vSelectedRows = Undefined;
	
	If amClipboard.Property("SetRoomRatePricesPTFormulas") Then
		UploadTablePTFormulas(amClipboard.SetRoomRatePricesPTFormulas);
		amClipboard.Delete("SetRoomRatePricesPTFormulas");
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Notify("SetRoomRatePricesCancelCopyRowsPTFormulas", Undefined, ThisObject);
	Else
		vSelectedRows = Items.FormulasForDayTypesAndPricetags.SelectedRows;
		If vSelectedRows.Count() > 0 Then
			For Each vRow In vSelectedRows Do				
				Object.FormulasForDayTypesAndPricetags.FindByID(vRow)[ColumnCopiedPTFormulas] = ValueCopiedPTFormulas;			
			EndDo;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Else
			ShowMessageBox(, NStr("en='There is no selected rows!';ru='Нет выделенных строк!';de='Es gibt keine markierten Zeilen!'"));
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyDocument(Command) 
	If ValueIsFilled(Object.Ref) Then
		OpenForm("Document.SetRoomRatePrices.ObjectForm", New Structure("CopyingValue", Object.Ref));       
		Close();
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	// Automatically assign new document number if year has changed
	If ValueIsFilled(Object.Date) Then
		If ValueIsFilled(OldDate) And Year(OldDate) <> Year(Object.Date) Then
			vObj = FormAttributeToValue("Object");
			vObj.SetNewNumber();
			ValueToFormAttribute(vObj, "Object");
		EndIf;
		OldDate = Object.Date;
		If Object.Date > CurrentSessionDate() Then
			Object.IsInFuture = True;
			Items.Date.ToolTip = NStr("en='Prices will be effective after the specified date and time'; 
			                          |ru='Цены вступят в силу после указанной даты и времени'; 
									  |de='Die Preise werden nach dem angegebenen Datum und der angegebenen Uhrzeit wirksam'");
			Items.Date.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		Else
			Object.IsInFuture = False;
			Items.Date.ToolTip = "";
			Items.Date.ToolTipRepresentation = ToolTipRepresentation.None;
		EndIf;
	EndIf;
EndProcedure // DateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomTypeParentColumn(pTabularPartName)
	For Each vRow In Object[pTabularPartName] Do
		If ValueIsFilled(vRow.RoomType) Then
			vRowRoomType = vRow.RoomType;
			If vRowRoomType.IsFolder Then
				vRow.RoomTypeParent = vRowRoomType;
			Else
				vRow.RoomTypeParent = vRowRoomType.Parent;
			EndIf;
		Else
			vRow.RoomTypeParent = Undefined;
		EndIf;
	EndDo;		
EndProcedure // FillRoomTypeParentColumn

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomRatesApprovedAppearance()
	If Object.RoomRatesApproved Or ValueIsFilled(Object.RoomRate) And Object.RoomRate.RoomRatesApproved Then
		Items.Hotel.ReadOnly = True;
		Items.RoomRate.ReadOnly = True;
		Items.CalendarDayType.ReadOnly = True;
		Items.Prices.ReadOnly = True;
		Items.PricesAdd.Enabled = False;
		Items.PricesDelete.Enabled = False;
		Items.PricesFillByDefault.Enabled = False;
		Items.PricesFillCopy.Enabled = False;
		Items.PricesFillByTemplateService.Enabled = False;
		Items.PricesFillByTemplateRoomType.Enabled = False;
		Items.PricesFillByTemplateAccommodationType.Enabled = False;
		Items.PricesChangePrice.Enabled = False;
		Items.PricesCopy.Enabled = False;
		Items.PricesPaste.Enabled = False;
		Items.Formulas.ReadOnly = True;
		Items.FormulasFillCopyForFormulas.Enabled = False;
		Items.FormulasFillByTemplateRoomTypeForFormulas.Enabled = False;
		Items.FormulasFillByTemplateRoomClassForFormulas.Enabled = False;
		Items.FormulasCopy.Enabled = False;
		Items.FormulasPaste.Enabled = False;
		Items.FormulasForDayTypesAndPricetags.ReadOnly = True;
		Items.FormulasForDayTypesAndPricetagsFillCopyForFormulas.Enabled = False;
		Items.FormulasForDayTypesAndPricetagsFillByTemplateDayType.Enabled = False;
		Items.FormulasForDayTypesAndPricetagsFillByTemplateRoomTypeForFormulas.Enabled = False;
		Items.FormulasForDayTypesAndPricetagsFillByTemplateRoomClassForFormulas.Enabled = False;
		Items.FormulasForDayTypesAndPricetagsFillByTemplatePriceTag.Enabled = False;
		Items.DayTypeAndPriceTagFormulasView.Enabled = False;
		Items.PTFormulasCopy.Enabled = False;
		Items.PTFormulasPaste.Enabled = False;
	Else
		Items.Hotel.ReadOnly = False;
		Items.RoomRate.ReadOnly = False;
		Items.CalendarDayType.ReadOnly = False;
		Items.Prices.ReadOnly = False;
		Items.PricesAdd.Enabled = True;
		Items.PricesDelete.Enabled = True;
		Items.PricesFillByDefault.Enabled = True;
		Items.PricesFillCopy.Enabled = True;
		Items.PricesFillByTemplateService.Enabled = True;
		Items.PricesFillByTemplateRoomType.Enabled = True;
		Items.PricesFillByTemplateAccommodationType.Enabled = True;
		Items.PricesChangePrice.Enabled = True;
		Items.PricesCopy.Enabled = True;
		Items.PricesPaste.Enabled = True;
		Items.Formulas.ReadOnly = False;
		Items.FormulasFillCopyForFormulas.Enabled = True;
		Items.FormulasFillByTemplateRoomTypeForFormulas.Enabled = True;
		Items.FormulasFillByTemplateRoomClassForFormulas.Enabled = True;
		Items.FormulasCopy.Enabled = True;
		Items.FormulasPaste.Enabled = True;
		Items.FormulasForDayTypesAndPricetags.ReadOnly = False;
		Items.FormulasForDayTypesAndPricetagsFillCopyForFormulas.Enabled = True;
		Items.FormulasForDayTypesAndPricetagsFillByTemplateDayType.Enabled = True;
		Items.FormulasForDayTypesAndPricetagsFillByTemplateRoomTypeForFormulas.Enabled = True;
		Items.FormulasForDayTypesAndPricetagsFillByTemplateRoomClassForFormulas.Enabled = True;
		Items.FormulasForDayTypesAndPricetagsFillByTemplatePriceTag.Enabled = True;
		Items.DayTypeAndPriceTagFormulasView.Enabled = True;
		Items.PTFormulasCopy.Enabled = True;
		Items.PTFormulasPaste.Enabled = True;
	EndIf;
EndProcedure // RoomRatesApprovedAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure PricesAppearance()
	Items.FormulasService.Visible = True;
	Items.FormulasService.ListChoiceMode = False;
	Items.FormulasService.ChoiceList.Clear();
	Items.FormulasForDayTypesAndPricetagsService.Visible = True;
	Items.FormulasForDayTypesAndPricetagsService.ListChoiceMode = False;
	Items.FormulasForDayTypesAndPricetagsService.ChoiceList.Clear();
	Items.PricesService.Visible = True;
	Items.PricesVATRate.Visible = True;
	Items.PricesIsRoomRevenue.Visible = True;
	Items.PricesIsInPrice.Visible = True;
	Items.PricesQuantityCalculationRule.Visible = True;
	Items.GroupPrices.Visible = True;
	Items.CalendarDayType.Visible = True;
	Items.CalendarDayType.AutoMarkIncomplete = True;
	Items.CalendarDayType.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
	Items.PriceTag.Visible = True;
	Items.FormulasMasterAccType.Visible = True;
	Items.FormulasChar2.Visible = True;
	Items.GroupFormulasForDayTypesAndPriceTags.Visible = True;
	Items.FormulasForDayTypesAndPricetagsCalendarDayType.Visible = True;
	If ValueIsFilled(Object.RoomRate) And Not Object.RoomRate.IsFolder Then
		If Not Object.RoomRate.UsePricesFromCalendar Then
			If ValueIsFilled(Object.RoomRate.AccommodationService) Then
				Items.PricesService.Visible = False;
				Items.PricesVATRate.Visible = False;
				Items.PricesIsRoomRevenue.Visible = False;
				Items.PricesIsInPrice.Visible = False;
				Items.PricesQuantityCalculationRule.Visible = False;
			EndIf;
		Else
			Items.GroupPrices.Visible = False;
			Items.CalendarDayType.Visible = True; // False; Starting from 9.1.2.81 we allow to specify different formulas for accommodation types for different day types
			Items.CalendarDayType.AutoMarkIncomplete = False;
			Items.CalendarDayType.ChoiceFoldersAndItems = FoldersAndItems.Items;
			If Object.Prices.Count() > 0 Then
				Object.Prices.Clear();
			EndIf;
			Items.FormulasMasterAccType.Visible = False;
			Items.FormulasChar2.Visible = False;
			If Not ValueIsFilled(Object.RoomRate.PriceTagType) Then
				Items.GroupFormulasForDayTypesAndPriceTags.Visible = False;
				If Object.FormulasForDayTypesAndPricetags.Count() > 0 Then
					Object.FormulasForDayTypesAndPricetags.Clear();
				EndIf;
			Else
				Items.FormulasForDayTypesAndPricetagsCalendarDayType.Visible = False;
			EndIf;
			Items.FormulasService.ListChoiceMode = True;
			Items.FormulasForDayTypesAndPricetagsService.ListChoiceMode = True;
			vFormulasServicesList = Items.FormulasService.ChoiceList;
			vFormulasServicesList.Clear();
			vDTFormulasServicesList = Items.FormulasForDayTypesAndPricetagsService.ChoiceList;
			vDTFormulasServicesList.Clear();
			vFormulasServicesList.Add(Catalogs.Services.EmptyRef(), NStr("en='<for any>'; ru='<для любой>'; de='<für jeden>'"));
			vDTFormulasServicesList.Add(Catalogs.Services.EmptyRef(), NStr("en='<for any>'; ru='<для любой>'; de='<für jeden>'"));
			If ValueIsFilled(Object.RoomRate.AccommodationService) Then
				vFormulasServicesList.Add(Object.RoomRate.AccommodationService);
				vDTFormulasServicesList.Add(Object.RoomRate.AccommodationService);
			EndIf;
			If ValueIsFilled(Object.RoomRate.EarlyCheckInService) Then
				vFormulasServicesList.Add(Object.RoomRate.EarlyCheckInService);
				vDTFormulasServicesList.Add(Object.RoomRate.EarlyCheckInService);
			EndIf;
			If ValueIsFilled(Object.RoomRate.LateCheckOutService) Then
				vFormulasServicesList.Add(Object.RoomRate.LateCheckOutService);
				vDTFormulasServicesList.Add(Object.RoomRate.LateCheckOutService);
			EndIf;
			If vFormulasServicesList.Count() < 3 Then
				Items.FormulasService.Visible = False;
				For Each vFormulasRow In Object.Formulas Do
					If ValueIsFilled(vFormulasRow.Service) Then
						vFormulasRow.Service = Catalogs.Services.EmptyRef();
					EndIf;
				EndDo;
			EndIf;
			If vDTFormulasServicesList.Count() < 3 Then
				Items.FormulasForDayTypesAndPricetagsService.Visible = False;
				For Each vDTFormulasRow In Object.FormulasForDayTypesAndPricetags Do
					If ValueIsFilled(vDTFormulasRow.Service) Then
						vDTFormulasRow.Service = Catalogs.Services.EmptyRef();
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		If Not ValueIsFilled(Object.RoomRate.PriceTagType) Then
			Items.PriceTag.Visible = False;
		EndIf;
	EndIf;
EndProcedure // PricesAppearance

// -----------------------------------------------------------------------------
&AtServer
Function GetClientTypes()
	vQry = New Query();
	vQry.Text = 
	"   SELECT
	|		ClientTypes.Ref AS ClientType,
	|		ClientTypes.IsFolder AS IsFolder,
	|		ClientTypes.Code AS Code,
	|		ClientTypes.Description AS Description,
	|		ClientTypes.SortCode AS SortCode
	|	FROM
	|		Catalog.ClientTypes AS ClientTypes
	|	WHERE
	|		ClientTypes.DeletionMark = FALSE
	|		AND ClientTypes.Parent = &qEmptyClientType
	|		AND (NOT &qHotelIsEmptyRef AND ClientTypes.Hotel = &qHotel 
	|		      OR ClientTypes.Hotel = &qEmptyHotel 
	|		      OR &qHotelIsEmptyRef)
	|	
	|	ORDER BY
	|		SortCode,
	|		Description";
	vQry.SetParameter("qHotel", ?(Object.Hotel = Catalogs.Hotels.EmptyRef(), SessionParameters.CurrentHotel, Object.Hotel));
	vQry.SetParameter("qHotelIsEmptyRef", ?(Object.Hotel = Catalogs.Hotels.EmptyRef(), True, False));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qEmptyClientType", Catalogs.ClientTypes.EmptyRef());
	vElements = vQry.Execute().Unload();
	// Check user permissions
	vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vPermissionGroup) Then
		If vPermissionGroup.ClientTypesAllowed.Count() > 0 Then
			i = 0;
			While i < vElements.Count() Do
				vRow = vElements.Get(i);
				If Not vRow.IsFolder And vPermissionGroup.ClientTypesAllowed.Find(vRow.ClientType, "ClientType") = Undefined Then
					vElements.Delete(i);
				Else
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;	
	Return vElements;
EndFunction // GetClientTypes

// -----------------------------------------------------------------------------
&AtServer
Procedure GetDefaultDocumentDate()
	If Not ValueIsFilled(Object.Date) Then
		Object.Date = CurrentSessionDate();
		DateOnChangeAtServer();
	EndIf;
EndProcedure // GetDefaultDocumentDate

// -----------------------------------------------------------------------------
&AtServer
Procedure SetFilter()
	vFilter = New Structure();	
	vFilter.Insert("ClientType",ClientType);	
	If ValueIsFilled(AccommodationType) Then
		vFilter.Insert("AccommodationType", AccommodationType);	
	EndIf;	
	If ValueIsFilled(RoomClass) Then
		vFilter.Insert("RoomClass", RoomClass);	
	EndIf;	
	If ValueIsFilled(RoomType) Then
		If RoomType.IsFolder Then
			vFilter.Insert("RoomTypeParent", RoomType);
		Else
			vFilter.Insert("RoomType", RoomType);	
		EndIf;
	EndIf;	
	If ValueIsFilled(Service) Then
		vFilter.Insert("Service", Service);	
	EndIf;
	vFilterStruct = New FixedStructure(vFilter);
	Items.Prices.RowFilter = vFilterStruct;	
	Items.Formulas.RowFilter = vFilterStruct;	
	Items.FormulasForDayTypesAndPricetags.RowFilter = vFilterStruct;
EndProcedure // SetFilter

// -----------------------------------------------------------------------------
&AtServer
Procedure FormulasForDayTypesAndPriceTagsAvailability()
	If DayTypeAndPriceTagFormulasView = 0 Then
		Items.FormulasForDayTypesAndPricetagsChar1.Visible = False;
		Items.FormulasForDayTypesAndPricetagsDiscount.Visible = True;
		Items.FormulasForDayTypesAndPricetagsChar2.Visible = False;
		Items.FormulasForDayTypesAndPricetagsBracketsConstant.Visible = False;
		Items.FormulasForDayTypesAndPricetagsChar3.Visible = False;
		Items.FormulasForDayTypesAndPricetagsMultiplier.Visible = False;
		Items.FormulasForDayTypesAndPricetagsChar4.Visible = False;
		Items.FormulasForDayTypesAndPricetagsConstant.Visible = False;
	Else
		Items.FormulasForDayTypesAndPricetagsChar1.Visible = True;
		Items.FormulasForDayTypesAndPricetagsDiscount.Visible = False;
		Items.FormulasForDayTypesAndPricetagsChar2.Visible = True;
		Items.FormulasForDayTypesAndPricetagsBracketsConstant.Visible = True;
		Items.FormulasForDayTypesAndPricetagsChar3.Visible = True;
		Items.FormulasForDayTypesAndPricetagsMultiplier.Visible = True;
		Items.FormulasForDayTypesAndPricetagsChar4.Visible = True;
		Items.FormulasForDayTypesAndPricetagsConstant.Visible = True;
	EndIf;
	If ValueIsFilled(Object.CalendarDayType) And Not Object.CalendarDayType.IsFolder Then
		Items.FormulasForDayTypesAndPricetagsCalendarDayType.Visible = False;
		For Each vDTPTRow In Object.FormulasForDayTypesAndPricetags Do
			If vDTPTRow.CalendarDayType <> Object.CalendarDayType Then
				vDTPTRow.CalendarDayType = Object.CalendarDayType;
			EndIf;
		EndDo;
	Else
		If ValueIsFilled(Object.RoomRate) And Not Object.RoomRate.IsFolder And Object.RoomRate.UsePricesFromCalendar Then
			Items.FormulasForDayTypesAndPricetagsCalendarDayType.Visible = False;
			For Each vDTPTRow In Object.FormulasForDayTypesAndPricetags Do
				If ValueIsFilled(vDTPTRow.CalendarDayType) Then
					vDTPTRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				EndIf;
			EndDo;
		Else
			Items.FormulasForDayTypesAndPricetagsCalendarDayType.Visible = True;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.PriceTag) And Not Object.PriceTag.IsFolder Then
		Items.FormulasForDayTypesAndPricetagsPriceTag.Visible = False;
		For Each vDTPTRow In Object.FormulasForDayTypesAndPricetags Do
			If vDTPTRow.PriceTag <> Object.PriceTag Then
				vDTPTRow.PriceTag = Object.PriceTag;
			EndIf;
		EndDo;
	Else
		If ValueIsFilled(Object.RoomRate) And Not Object.RoomRate.IsFolder And Not ValueIsFilled(Object.RoomRate.PriceTagType) Then
			Items.FormulasForDayTypesAndPricetagsPriceTag.Visible = False;
			For Each vDTPTRow In Object.FormulasForDayTypesAndPricetags Do
				If ValueIsFilled(vDTPTRow.PriceTag) Then
					vDTPTRow.PriceTag = Catalogs.PriceTags.EmptyRef();
				EndIf;
			EndDo;
		Else
			Items.FormulasForDayTypesAndPricetagsPriceTag.Visible = True;
		EndIf;
	EndIf;
EndProcedure // FormulasForDayTypesAndPriceTagsAvailability

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandFillByDefaultActionAtServer(pService)
	vRows = Object.Prices.FindRows(New Structure("ClientType", ClientType));
	For Each vRow In vRows Do
		Object.Prices.Delete(vRow);
	EndDo;
	// Get room and accommodation type lists
	If ValueIsFilled(Object.Hotel) AND ValueIsFilled(Object.Hotel.AccommodationType) Then
		vAccommodationTypes = New ValueTable;
		vAccommodationTypes.Columns.Add("AccommodationType");
		rAC = vAccommodationTypes.Add();
		rAC.AccommodationType = Object.Hotel.AccommodationType;
	Else
		vAccommodationTypes = cmGetAllAccommodationTypes();
	EndIf;
	vRoomTypes = cmGetAllRoomTypes(Object.Hotel);
	If (pService = Undefined) Then 
		If ValueIsFilled(Object.RoomRate) And ValueIsFilled(Object.RoomRate.AccommodationService) Then
			vService = Object.RoomRate.AccommodationService;
		Else
			Return;
		EndIf;
	Else
		vService = pService;
	EndIf;
	// Fill default service attributes
	vServicePrice = 0;
	vServiceCurrency = Object.Hotel.FolioCurrency;
	If ValueIsFilled(Object.Hotel.Company) Then
		vServiceVATRate = Object.Hotel.Company.VATRate;
	Else
		vServiceVATRate = Catalogs.VATRates.EmptyRef();
	EndIf;
	// Get service attributes actual on document date
	vServicePrices = vService.GetObject().pmGetServicePrices(Object.Hotel, Object.Date, ClientType);
	If vServicePrices.Count() > 0 Then
		vServicePriceRow = vServicePrices.Get(0);
		// Fill default service attributes
		vServicePrice = vServicePriceRow.Price;
		vServiceCurrency = vServicePriceRow.Currency;
		vServiceVATRate = vServicePriceRow.VATRate;
	EndIf;
	vRoomRate = Object.RoomRate;
	vServiceQuantityCalculationRule = Catalogs.QuantityCalculationRules.EmptyRef();
	If ValueIsFilled(vService) Then
		vServiceQuantityCalculationRule = vService.QuantityCalculationRule;
	EndIf;
	If ValueIsFilled(vService) And vService.IsInPrice And vService.IsRoomRevenue And 
	   ValueIsFilled(vRoomRate) And Not vRoomRate.IsFolder And ValueIsFilled(vRoomRate.QuantityCalculationRule) Then
		vServiceQuantityCalculationRule = vRoomRate.QuantityCalculationRule;
	EndIf;
	// Add rows
	For Each vRoomTypeRow In vRoomTypes Do
		For Each vAccommodationTypeRow In vAccommodationTypes Do
			If vAccommodationTypeRow.AccommodationType.Type = Enums.AccomodationTypes.Room Then
				// Check allowed room type accommodation types
				If ValueIsFilled(vRoomTypeRow.RoomType) And vRoomTypeRow.RoomType.AccommodationTypesAllowed.Count() > 0 Then
					If vRoomTypeRow.RoomType.AccommodationTypesAllowed.Find(vAccommodationTypeRow.AccommodationType) = Undefined Then
						Continue;
					EndIf;
				EndIf;
				// Add prices row
				vRow = Object.Prices.Add();
				vRow.ClientType = ClientType;
				vRow.RoomType = vRoomTypeRow.RoomType;
				vRow.AccommodationType = vAccommodationTypeRow.AccommodationType;
				vRow.Service = vService;
				vRow.Price = vServicePrice;
				vRow.Currency = vServiceCurrency;
				vRow.MinimumQuantity = 0;
				vRow.VATRate = vServiceVATRate;
				vRow.QuantityCalculationRule = vServiceQuantityCalculationRule;
				vRow.IsRoomRevenue = vService.IsRoomRevenue;
				vRow.IsInPrice = vService.IsInPrice;
			EndIf;
		EndDo;
	EndDo;		
	// Filter
	SetFilter();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteAnswer(pAnswer,pParametr) Export 	
	If pAnswer = DialogReturnCode.Yes Then	
		// APDEX
		vKeyOperation = "Catalog.Services.Form.tcChoiceForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
		
		OpenForm("Catalog.Services.ChoiceForm", New Structure("Hotel, ClientType, AccountingDate, MultipleChoice", Object.Hotel, ClientType, Object.Date, False), ThisObject, , , , New NotifyDescription("ServicesAnswer", ThisObject));	
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesAnswer(pReturn,pParametr) Export 	
	If ValueIsFilled(pReturn) Then
		CommandFillByDefaultActionAtServer(pReturn);
	Else
		Return;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure InputValueChoice(pActionType, pExtraParam) Export 	
	If pActionType <> Undefined Then	
		ShowInputNumber(New NotifyDescription("InputNumberChoice", ThisObject, pActionType), , NStr("en='Enter value';ru='Введите значение';de='Geben Sie den Wert ein'"), 17, 2);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure InputNumberChoice(pAmount, pActionType) Export
	If pAmount <> Undefined Then
		vSelectedRows = Items.Prices.SelectedRows;
		For Each vRowNumber In vSelectedRows Do
			vRow = Object.Prices.FindByID(vRowNumber);
			If pActionType = PredefinedValue("Enum.ChangePriceActionTypes.AddSubtract") Then
				vRow.Price = vRow.Price + pAmount;
			ElsIf pActionType = PredefinedValue("Enum.ChangePriceActionTypes.AddSubtractPercent") Then
				vRow.Price = Round(vRow.Price + vRow.Price*pAmount/100, 2);
			ElsIf pActionType = PredefinedValue("Enum.ChangePriceActionTypes.Multiply") Then
				vRow.Price = Round(vRow.Price * pAmount, 2);
			ElsIf pActionType = PredefinedValue("Enum.ChangePriceActionTypes.Divide") Then
				If pAmount <> 0 Then
					vRow.Price = Round(vRow.Price / pAmount, 2);
				Else
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='You can not divide by zero!'; ru='Нельзя делить на ноль!'; de='Du kannst es nicht durch Null teilen!'"), MessageStatus.Attention);
					Break;
				EndIf;
			EndIf;
		EndDo;
		Modified = True;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
Procedure FillAsCopyAction(pClientType)
	// Clear rows for client type selected
	vRows = Object.Prices.FindRows(New Structure("ClientType", ClientType));
	For Each vRow In vRows Do
		Object.Prices.Delete(vRow);
	EndDo;
	// Retrieve rows of the type choosen
	vRows = Object.Prices.FindRows(New Structure("ClientType", pClientType));
	For Each vRow In vRows Do
		vNewRow = Object.Prices.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.ClientType = ClientType;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure // FillAsCopyAction

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteAnswerCopy(pAnswer,pParametr) Export 	
	If pAnswer = DialogReturnCode.Yes Then			
		Items.ClientType.ChoiceList.ShowChooseItem(New NotifyDescription("ClientTypeAnswer", ThisObject), NStr("en='Choose client type to copy rows from';ru='Выберите тип клиента, у которого скопировать строки';de='Wählen Sie den Clienttyp aus, von dem Zeilen kopiert werden sollen'"));		
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeAnswer(pAnswer,pParametr) Export
	If pAnswer <> Undefined Then
		FillAsCopyAction(pAnswer.Value);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateServiceAnswer(pAnswer,pParametr) Export 	
	If pAnswer <> Undefined Then
		// APDEX
		vKeyOperation = "Catalog.Services.Form.tcChoiceForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
		
		OpenForm("Catalog.Services.ChoiceForm", New Structure("Hotel, ClientType, AccountingDate, MultipleChoice", Object.Hotel, ClientType, Object.Date, False), ThisObject, , , , New NotifyDescription("FillByTemplateServiceAnswer2", ThisObject, pAnswer.Value));	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateServiceAnswer2(pAnswer,pParametr) Export 	
	If ValueIsFilled(pAnswer) Then
		FillByTemplateServiceAction(pAnswer, pParametr);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillByTemplateServiceAction(pNewService, pTemplateService)
	vRoomRate = Object.RoomRate;
	vQuantityCalculationRule = pNewService.QuantityCalculationRule;
	If pNewService.IsRoomRevenue And pNewService.IsInPrice And ValueIsFilled(vRoomRate) And Not vRoomRate.IsFolder And ValueIsFilled(vRoomRate.QuantityCalculationRule) Then
		vQuantityCalculationRule = vRoomRate.QuantityCalculationRule;
	EndIf;
	vRows = Object.Prices.FindRows(New Structure("ClientType, Service", ClientType, pTemplateService));
	For Each vRow In vRows Do
		// Add new row for the new service as copy of the current one
		vNewRow = Object.Prices.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.Service = pNewService;
		vNewRow.IsRoomRevenue = pNewService.IsRoomRevenue;
		vNewRow.IsInPrice = pNewService.IsInPrice;
		vNewRow.QuantityCalculationRule = vQuantityCalculationRule;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure // FillByTemplateServiceAction

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomClassAnswer(pAnswer,pParametr) Export
	If pAnswer <> Undefined Then
		OpenForm("Catalog.RoomTypeClasses.Form.tcChoiceForm", New Structure("Hotel", Object.Hotel), ThisObject, , , , New NotifyDescription("FillByTemplateRoomClassAnswer2", ThisObject, pAnswer.Value));	
	EndIf;
EndProcedure // FillByTemplateRoomClassAnswer

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomClassAnswer2(pAnswer, pParametr) Export
	If ValueIsFilled(pAnswer) Then
		FillByTemplateRoomClassAction(pAnswer, pParametr);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillByTemplateRoomClassAction(pNewRoomClass,pTemplateRoomClass)
	vRows = Object.Prices.FindRows(New Structure("ClientType, RoomClass", ClientType, pTemplateRoomClass));
	For Each vRow In vRows Do
		vNewRow = Object.Prices.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.RoomClass = pNewRoomClass;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure // FillByTemplateRoomClassAction

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomTypeAnswer(pAnswer, pParametr) Export
	If pAnswer <> Undefined Then
		// APDEX
		vKeyOperation = "Catalog.RoomTypes.Form.tcChoiceForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", New Structure("Hotel", Object.Hotel), ThisObject, , , , New NotifyDescription("FillByTemplateRoomTypeAnswer2", ThisObject, pAnswer.Value));	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomTypeAnswer2(pAnswer,pParametr) Export
	If ValueIsFilled(pAnswer) Then
		FillByTemplateRoomTypeAction(pAnswer, pParametr);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillByTemplateRoomTypeAction(pNewRoomType, pTemplateRoomType)
	vRows = Object.Prices.FindRows(New Structure("ClientType, RoomType", ClientType, pTemplateRoomType));
	For Each vRow In vRows Do
		vNewRow =  Object.Prices.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.RoomType = pNewRoomType;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure // FillByTemplateServiceAction

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateAccommodationTypeAnswer2(pAnswer, pParametr) Export
	If ValueIsFilled(pAnswer) Then
		FillByTemplateAccommodationTypeAction(pAnswer, pParametr);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillByTemplateAccommodationTypeAction(pNewAccommodationType, pTemplateAccommodationType)
	vRows = Object.Prices.FindRows(New Structure("ClientType, AccommodationType", ClientType, pTemplateAccommodationType));
	For Each vRow In vRows Do
		vNewRow = Object.Prices.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.AccommodationType = pNewAccommodationType;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure // FillByTemplateServiceAction

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateAccommodationTypeAnswer(pAnswer, pParametr) Export
	If pAnswer <> Undefined Then
		OpenForm("Catalog.AccommodationTypes.Form.tcListForm", New Structure("Hotel, ChoiceMode", Object.Hotel, True), ThisObject, , , , New NotifyDescription("FillByTemplateAccommodationTypeAnswer2", ThisObject, pAnswer.Value));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure Restore(pDate)
	vObj = FormAttributeToValue("Object");	
	vRChg = InformationRegisters.SetRoomRatePricesChangeHistory;
	vRChgRec = vRChg.Get(pDate, New Structure("SetRoomRatePrices", vObj.Ref));
	vObj.pmRestoreAttributesFromHistory(vRChgRec);
	ValueToFormAttribute(vObj, "Object");	
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UploadTable(pTempStorage)
	vTable = GetFromTempStorage(pTempStorage);	
	For Each vRow In vTable Do
		vNewRow = Object.Prices.Add();
		FillPropertyValues(vNewRow, vRow);
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetRows(val vSelectedRows)
	vRows = New Array;
	For Each vRow In vSelectedRows Do
		vRows.Add(Object.Prices.FindByID(vRow));	
	EndDo;
	Return PutToTempStorage(Object.Prices.Unload(vRows), New UUID);
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure PricesServiceOnChangeAtServer(pRow)
	vRoomRate = Object.RoomRate;
	vCurRow = Object.Prices.FindByID(pRow);
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.Service) Then
			vService = vCurRow.Service;
			// Set default service attributes
			If vService.IsRoomRevenue And vService.IsInPrice And ValueIsFilled(vRoomRate) And Not vRoomRate.IsFolder And ValueIsFilled(vRoomRate.QuantityCalculationRule) Then
				vCurRow.QuantityCalculationRule = vRoomRate.QuantityCalculationRule;
			ElsIf ValueIsFilled(vService.QuantityCalculationRule) Then
				vCurRow.QuantityCalculationRule = vService.QuantityCalculationRule;
			EndIf;
			vCurRow.IsRoomRevenue = vService.IsRoomRevenue;
			vCurRow.IsInPrice = vService.IsInPrice;
			vCurRow.IsPricePerPerson = vService.ChargePerPerson;
			// Get service attributes actual on document date
			vServicePrices = vService.GetObject().pmGetServicePrices(Object.Hotel, Object.Date, ClientType);
			If vServicePrices.Count() > 0 Then
				vServicePriceRow = vServicePrices.Get(0);
				// Fill default service attributes
				vCurRow.Currency = vServicePriceRow.Currency;
				vCurRow.VATRate = vServicePriceRow.VATRate;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetDayTypeAndPriceTagFormulasMode()
	vMode = 1;
	For Each vDTPTRow In Object.FormulasForDayTypesAndPricetags Do
		If vDTPTRow.Discount <> 0 Then
			vMode = 0;
			Break;
		EndIf;
	EndDo;
	Return vMode;
EndFunction // GetDayTypeAndPriceTagFormulasMode

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateDayTypeForDayTypeFormulasAnswer(pAnswer,pParametr) Export
	If pAnswer <> Undefined Then
		OpenForm("Catalog.CalendarDayTypes.Form.tcChoiceForm", New Structure("Hotel", Object.Hotel), ThisObject, , , , New NotifyDescription("FillByTemplateDayTypeForDayTypeFormulasAnswer2", ThisObject, pAnswer.Value));	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateDayTypeForDayTypeFormulasAnswer2(pAnswer, pParametr) Export
	If ValueIsFilled(pAnswer) Then
		FillByTemplateDayTypeForDayTypeFormulasAction(pAnswer, pParametr);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillByTemplateDayTypeForDayTypeFormulasAction(pNewDayType, pTemplateDayType)
	vRows = Object.FormulasForDayTypesAndPricetags.FindRows(New Structure("ClientType, CalendarDayType", ClientType, pTemplateDayType));
	For Each vRow In vRows Do
		vNewRow = Object.FormulasForDayTypesAndPricetags.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.CalendarDayType = pNewDayType;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplatePriceTagForDayTypeFormulasAnswer(pAnswer, pParametr) Export
	If pAnswer <> Undefined Then
		OpenForm("Catalog.PriceTags.Form.tcChoiceForm", New Structure("Hotel", Object.Hotel), ThisObject, , , , New NotifyDescription("FillByTemplatePriceTagForDayTypeFormulasAnswer2", ThisObject, pAnswer.Value));	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplatePriceTagForDayTypeFormulasAnswer2(pAnswer, pParametr) Export
	If ValueIsFilled(pAnswer) Then
		FillByTemplatePriceTagForDayTypeFormulasAction(pAnswer, pParametr);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillByTemplatePriceTagForDayTypeFormulasAction(pNewPriceTag, pTemplatePriceTag)
	vRows = Object.FormulasForDayTypesAndPricetags.FindRows(New Structure("ClientType, PriceTag", ClientType, pTemplatePriceTag));
	For Each vRow In vRows Do
		vNewRow = Object.FormulasForDayTypesAndPricetags.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.PriceTag = pNewPriceTag;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
Procedure FillAsCopyForDayTypeFormulasAction(pClientType)
	// Clear rows for client type selected
	vRows = Object.FormulasForDayTypesAndPricetags.FindRows(New Structure("ClientType", ClientType));
	For Each vRow In vRows Do
		Object.FormulasForDayTypesAndPricetags.Delete(vRow);
	EndDo;
	// Retrieve rows of the type choosen
	vRows = Object.FormulasForDayTypesAndPricetags.FindRows(New Structure("ClientType", pClientType));
	For Each vRow In vRows Do
		vNewRow = Object.FormulasForDayTypesAndPricetags.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.ClientType = ClientType;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteAnswerCopyForDayTypeFormulas(pAnswer, pParametr) Export 	
	If pAnswer = DialogReturnCode.Yes Then			
		Items.ClientType.ChoiceList.ShowChooseItem(New NotifyDescription("ClientTypeForDayTypeFormulasAnswer", ThisObject), NStr("en='Choose client type';ru='Выберите тип клиента';de='Wählen Sie den Kundentyp'"));		
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeForDayTypeFormulasAnswer(pAnswer, pParametr) Export
	If pAnswer <> Undefined Then
		FillAsCopyForDayTypeFormulasAction(pAnswer.Value);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomTypeForDayTypeFormulasAnswer(pAnswer,pParametr) Export
	If pAnswer <> Undefined Then
		// APDEX
		vKeyOperation = "Catalog.RoomTypes.Form.tcChoiceForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", New Structure("Hotel", Object.Hotel), ThisObject, , , , New NotifyDescription("FillByTemplateRoomTypeForDayTypeFormulasAnswer2", ThisObject, pAnswer.Value));	
	EndIf;                                                                                                  
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomTypeForDayTypeFormulasAnswer2(pAnswer, pParametr) Export
	If ValueIsFilled(pAnswer) Then
		FillByTemplateRoomTypeForDayTypeFormulasAction(pAnswer, pParametr);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillByTemplateRoomTypeForDayTypeFormulasAction(pNewRoomType, pTemplateRoomType)
	vRows = Object.FormulasForDayTypesAndPricetags.FindRows(New Structure("ClientType, RoomType", ClientType, pTemplateRoomType));
	For Each vRow In vRows Do
		vNewRow = Object.FormulasForDayTypesAndPricetags.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.RoomType = pNewRoomType;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomClassForDayTypeFormulasAnswer2(pAnswer, pParametr) Export
	If ValueIsFilled(pAnswer) Then
		FillByTemplateRoomClassForDayTypeFormulasAction(pAnswer, pParametr);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillByTemplateRoomClassForDayTypeFormulasAction(pNewRoomClass, pTemplateRoomClass)
	vRows = Object.FormulasForDayTypesAndPricetags.FindRows(New Structure("ClientType, RoomClass", ClientType, pTemplateRoomClass));
	For Each vRow In vRows Do
		vNewRow = Object.FormulasForDayTypesAndPricetags.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.RoomClass = pNewRoomClass;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
Procedure FillAsCopyForFormulasAction(pClientType)
	// Clear rows for client type selected
	vRows = Object.Formulas.FindRows(New Structure("ClientType", ClientType));
	For Each vRow In vRows Do
		Object.Formulas.Delete(vRow);
	EndDo;
	// Retrieve rows of the type choosen
	vRows = Object.Formulas.FindRows(New Structure("ClientType", pClientType));
	For Each vRow In vRows Do
		vNewRow = Object.Formulas.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.ClientType = ClientType;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomClassForDayTypeFormulasAnswer(pAnswer,pParametr) Export
	If pAnswer <> Undefined Then
		OpenForm("Catalog.RoomTypeClasses.Form.tcChoiceForm", New Structure("Hotel", Object.Hotel), ThisObject, , , , New NotifyDescription("FillByTemplateRoomClassForDayTypeFormulasAnswer2", ThisObject, pAnswer.Value));	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteAnswerCopyForFormulas(pAnswer, pParametr) Export 	
	If pAnswer = DialogReturnCode.Yes Then			
		Items.ClientType.ChoiceList.ShowChooseItem(New NotifyDescription("ClientTypeForFormulasAnswer", ThisObject), NStr("en='Choose client type';ru='Выберите тип клиента';de='Wählen Sie den Kundentyp'"));		
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeForFormulasAnswer(pAnswer, pParametr) Export
	If pAnswer <> Undefined Then
		FillAsCopyForFormulasAction(pAnswer.Value);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomTypeForFormulasAnswer(pAnswer,pParametr) Export
	If pAnswer <> Undefined Then
		// APDEX
		vKeyOperation = "Catalog.RoomTypes.Form.tcChoiceForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", New Structure("Hotel", Object.Hotel), ThisObject, , , , New NotifyDescription("FillByTemplateRoomTypeForFormulasAnswer2", ThisObject, pAnswer.Value));	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomTypeForFormulasAnswer2(pAnswer, pParametr) Export
	If ValueIsFilled(pAnswer) Then
		FillByTemplateRoomTypeForFormulasAction(pAnswer, pParametr);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillByTemplateRoomTypeForFormulasAction(pNewRoomType, pTemplateRoomType)
	vRows = Object.Formulas.FindRows(New Structure("ClientType, RoomType", ClientType, pTemplateRoomType));
	For Each vRow In vRows Do
		vNewRow = Object.Formulas.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.RoomType = pNewRoomType;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomClassForFormulasAnswer(pAnswer,pParametr) Export
	If pAnswer <> Undefined Then
		OpenForm("Catalog.RoomTypeClasses.Form.tcChoiceForm", New Structure("Hotel", Object.Hotel), ThisObject, , , , New NotifyDescription("FillByTemplateRoomClassForFormulasAnswer2", ThisObject, pAnswer.Value));	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomClassForFormulasAnswer2(pAnswer, pParametr) Export
	If ValueIsFilled(pAnswer) Then
		FillByTemplateRoomClassForFormulasAction(pAnswer, pParametr);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillByTemplateRoomClassForFormulasAction(pNewRoomClass, pTemplateRoomClass)
	vRows = Object.Formulas.FindRows(New Structure("ClientType, RoomClass", ClientType, pTemplateRoomClass));
	For Each vRow In vRows Do
		vNewRow = Object.Formulas.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.RoomClass = pNewRoomClass;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure TabularPartRowOnEditEnd(pTPName)
	vCurRowID = Items[pTPName].CurrentRow;
	If vCurRowID <> Undefined Then
		vCurRow = Object[pTPName].FindByID(vCurRowID);
		If ValueIsFilled(vCurRow.RoomType) Then
			If tcOnServer.cmGetAttributeByRef(vCurRow.RoomType, "IsFolder") Then
				vCurRow.RoomTypeParent = vCurRow.RoomType;
			Else
				vCurRow.RoomTypeParent = tcOnServer.cmGetAttributeByRef(vCurRow.RoomType, "Parent");
			EndIf;
		Else
			vCurRow.RoomTypeParent = Undefined;
		EndIf;
	EndIf;
EndProcedure // TabularPartRowOnEditEnd

// -----------------------------------------------------------------------------
&AtServer
Procedure UploadTableFormulas(pTempStorage)
	vTable = GetFromTempStorage(pTempStorage);	
	For Each vRow In vTable Do
		vNewRow = Object.Formulas.Add();
		FillPropertyValues(vNewRow, vRow);
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetRowsFormulas(val vSelectedRows)
	vRows = New Array;
	For Each vRow In vSelectedRows Do
		vRows.Add(Object.Formulas.FindByID(vRow));	
	EndDo;
	Return PutToTempStorage(Object.Formulas.Unload(vRows), New UUID); 	
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure UploadTablePTFormulas(pTempStorage)
	vTable = GetFromTempStorage(pTempStorage);	
	For Each vRow In vTable Do
		vNewRow = Object.FormulasForDayTypesAndPricetags.Add();
		FillPropertyValues(vNewRow, vRow);
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetRowsPTFormulas(val vSelectedRows)
	vRows = New Array;
	For Each vRow In vSelectedRows Do
		vRows.Add(Object.FormulasForDayTypesAndPricetags.FindByID(vRow));	
	EndDo;
	Return PutToTempStorage(Object.FormulasForDayTypesAndPricetags.Unload(vRows), New UUID); 	
EndFunction

#EndRegion
