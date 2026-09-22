
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Hotel
	Hotel = SessionParameters.CurrentHotel;
	If Parameters.Property("Hotel") And ValueIsFilled(Parameters.Hotel) Then
		Hotel = Parameters.Hotel;
	EndIf;
	// Room rate
	RoomRate = Undefined;
	If Parameters.Property("RoomRate") And ValueIsFilled(Parameters.RoomRate) Then
		RoomRate = Parameters.RoomRate;
		If RoomRate.UsePricesFromCalendar Then
			pCancel = True;
		EndIf;
		If ValueIsFilled(RoomRate.BasedOnRoomRate) Then
			RoomRate = RoomRate.BasedOnRoomRate;
		EndIf;
		If ValueIsFilled(RoomRate) Then
			Items.RoomRate.ReadOnly = True;
		EndIf;
	EndIf;
	// Basis
	Basis = Undefined;
	If Parameters.Property("Basis") Then
		If TypeOf(Parameters.Basis) = Type("CatalogRef.RoomTypes") And ValueIsFilled(Parameters.Basis) Then
			Basis = Parameters.Basis;
		ElsIf TypeOf(Parameters.Basis) = Type("ValueList") Then
			Basis = Parameters.Basis;
		EndIf;
	EndIf;
	// Period
	If Parameters.Property("DateFrom") And ValueIsFilled(Parameters.DateFrom) And Parameters.Property("DateTo") And ValueIsFilled(Parameters.DateTo) Then
		DateFrom = Parameters.DateFrom;
		DateTo = Parameters.DateTo;
	EndIf;
	// Fill days of week
	FillDays();
	// Fill name of new calandar day type
	CalendarDayTypeDescription = GetPeriodDescription();
	// Get all room types
	FillRoomTypesList();
	// Get all client types
	AllClientTypes.Clear();
	vClientTypes = cmGetAllClientTypes();
	// Fill client types table
	vCTFirstItem = AllClientTypes.Add();
	vCTFirstItem.Check = True;
	vCTFirstItem.Value = Catalogs.ClientTypes.EmptyRef();
	vCTFirstItem.Presentation = NStr("en='<Empty client type>';ru='<Пустой тип клиента>';de='<Leerer Kundentyp>'");
	For Each vClientTypesRow In vClientTypes Do
		vCTItem = AllClientTypes.Add();
		vCTItem.Check = False;
		vCTItem.Value = vClientTypesRow.ClientType;
		vCTItem.Presentation = TrimAll(vClientTypesRow.Description);
	EndDo;
	ClientTypes.Add(vCTFirstItem.Value, vCTFirstItem.Presentation);
    // Get all price tags
	FillPriceTagsOnServer();
	// Fill default currency
	vDefaultCurrency = Hotel.FolioCurrency;
	// Create accommodation types fields
	vAccTypes = cmGetAllAccommodationTypes();
	// Create form items
	For Each vRoomTypeItem In AllRoomTypes Do
		vRoomTypeIndex = AllRoomTypes.IndexOf(vRoomTypeItem) + 1;
		
		// Room type group
		vRoomTypeGroup = Items.Add("RoomTypeGroup"+Format(vRoomTypeIndex, "ND=3; NFD=; NZ=; NLZ=; NG="), Type("FormGroup"), Items.RoomTypesGroup);
		vRoomTypeGroup.Title = TrimAll(vRoomTypeItem.Value);
		vRoomTypeGroup.Type = FormGroupType.UsualGroup;
		vRoomTypeGroup.Representation = UsualGroupRepresentation.WeakSeparation;
		vRoomTypeGroup.Group = ChildFormItemsGroup.Vertical;
		vRoomTypeGroup.ShowTitle = True;
		vRoomTypeGroup.Visible = False;
		vRoomTypeGroup.HorizontalStretch = True;
		vRoomTypeGroup.ChildItemsWidth = ChildFormItemsWidth.Equal;
		
		// Add accommodation types for each room type		
		vAccTypeIndex = 0;
		For Each vAccTypesRow In vAccTypes Do
			vAccTypeIndex = vAccTypes.IndexOf(vAccTypesRow);
			
			vIndex = Format(vRoomTypeIndex, "ND=3; NFD=; NZ=; NLZ=; NG=") + Format(vAccTypeIndex, "ND=3; NFD=; NZ=; NLZ=; NG=");
			AddAccommodationTypeFieldAttributes(vRoomTypeGroup, vIndex);
			
			ThisForm["AccommodationType"+vIndex] = vAccTypesRow.AccommodationType;
			ThisForm["Currency"+vIndex] = vDefaultCurrency;
		EndDo;
	EndDo;
	
	Items.GetPrices.Visible = True;
	Items.GetPrices.Enabled = True;
	Items.RoomTypesGroup.Visible = False;
	Items.RoomRatePrices.Visible = False;
	Items.SetPrices.Visible = False;
	Items.SetPrices.Enabled = False;
	Items.Splitter1.Visible = False;
	Items.Splitter2.Visible = False;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CurrencyStartChoice(pItem, pChoiceData, pStandardProcessing)
	vValue = Undefined;
	ShowChooseFromList(New NotifyDescription("CurrencyStartChoiceEnd", ThisForm, New Structure("pItem, pStandardProcessing", pItem, pStandardProcessing)), GetCurrencies(), pItem);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CurrencyStartChoiceEnd(pSelectedItem, pAdditionalParameters) Export
	pItem = pAdditionalParameters.pItem;
	pStandardProcessing = pAdditionalParameters.pStandardProcessing;
	Try	
		vValue = pSelectedItem.Value;
		ThisForm[pItem.Name] = vValue;	
		pStandardProcessing = False;
	Except
		pStandardProcessing = False;
	EndTry;
EndProcedure // CurrencyStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceOnChange(pItem)
	Items.SetPrices.Visible = True;
	Items.SetPrices.Enabled = True;
EndProcedure
 
#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SetPrices(pCommand)
	// Create and post set room rate prices document
	If SetPricesAtServer() Then
		
		// Update price cache if necessary
		vCurrentHotel = tcOnServer.cmGetSessionParametersAttribute("CurrentHotel");
		If ValueIsFilled(vCurrentHotel) And tcOnServer.cmGetAttributeByRef(vCurrentHotel, "UseRoomRateDailyPrices") Then
			vRatesList = New ValueList();
			If ValueIsFilled(RoomRate) Then
				vRatesList.Add(RoomRate);
			EndIf;
			If vRatesList.Count() > 0 And DateFrom <= DateTo And ValueIsFilled(DateFrom) Then
				RunFillRoomRatePricesCacheAtServer(vCurrentHotel, vRatesList, DateFrom, DateTo);
			EndIf;
		EndIf;
		
		ShowMessageBox(, NStr("en='Price change has completed!';ru='Изменение цен завершено!';de='Preisänderung abgeschlossen ist!'"));
			
		// Reread prices
		FillPrices(Commands.FillPrices);
	EndIf;
	
	// Clear form items cache
	ThisObject.RefreshDataRepresentation(Items.GroupRoomRate);
EndProcedure // SetPrices

// -----------------------------------------------------------------------------
&AtClient
Procedure FillPrices(Command)
	GetRoomRatePrices();
	Items.SetPrices.Visible = True;
	Items.SetPrices.Enabled = False;
	Items.Splitter1.Visible = True;
	Items.Splitter2.Visible = True;
EndProcedure // FillPrices

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure AddAccommodationTypeFieldAttributes(pRoomTypeGroup, pIndex)
    // Accommodation type parameters
	vTempArray = New Array;	
	vTempArray.Add(New FormAttribute("AccommodationType"+pIndex, New TypeDescription("CatalogRef.AccommodationTypes")));
	vTempArray.Add(New FormAttribute("Price"+pIndex, New TypeDescription("Number",,,New NumberQualifiers(17, 2))));
	vTempArray.Add(New FormAttribute("Currency"+pIndex, New TypeDescription("CatalogRef.Currencies")));
	ChangeAttributes(vTempArray);
	
	// Accommodation type group
	vAccommodationTypeGroup = Items.Add("AccommodationTypeGroup"+pIndex, Type("FormGroup"), pRoomTypeGroup);
	vAccommodationTypeGroup.Title = NStr("en='""Accommodation type №';ru='Группа ""Вид размещения №';de='Gruppe ""Typ der Unterkunft Nr.'")+pIndex+NStr("ru='""';en='"" group';de='"" gruppe'");
	vAccommodationTypeGroup.Type = FormGroupType.UsualGroup;
	vAccommodationTypeGroup.Representation = UsualGroupRepresentation.None;
	vAccommodationTypeGroup.Group = ChildFormItemsGroup.Horizontal;
	vAccommodationTypeGroup.ChildItemsWidth = ChildFormItemsWidth.Auto;
	vAccommodationTypeGroup.ShowTitle = False;
	vAccommodationTypeGroup.Enabled = True;
	vAccommodationTypeGroup.Visible = True;
	vAccommodationTypeGroup.Width = 60;
	vAccommodationTypeGroup.HorizontalStretch = False;
	
	// Accommodation type field
	vNewField = Items.Add("AccommodationType"+pIndex, Type("FormField"), vAccommodationTypeGroup);
	vNewField.Type = FormFieldType.LabelField;
	vNewField.Enabled = True;
	vNewField.Visible = True;
	vNewField.DataPath = "AccommodationType"+pIndex;
	vNewField.Title = "";
	vNewField.TitleLocation = FormItemTitleLocation.None;
	vNewField.Width = 40;
	vNewField.HorizontalStretch = True;
	
	// Price field
	vNewField = Items.Add("Price"+pIndex, Type("FormField"), vAccommodationTypeGroup);
	vNewField.Type = FormFieldType.InputField;
	vNewField.Enabled = True;
	vNewField.Visible = True;
	vNewField.TextEdit = True;
	vNewField.Title = "";
	vNewField.TitleLocation = FormItemTitleLocation.None;
	vNewField.DataPath = "Price"+pIndex;
	vNewField.Width = 13;
	vNewField.ClearButton = False;
	vNewField.ChoiceButton = False;
	vNewField.OpenButton = False;
	vNewField.HorizontalStretch = False;
	vNewField.SetAction("OnChange", "PriceOnChange");
	
	// Currency field
	vNewField = Items.Add("Currency"+pIndex, Type("FormField"), vAccommodationTypeGroup);
	vNewField.Type = FormFieldType.InputField;
	vNewField.Enabled = True;
	vNewField.Visible = True;
	vNewField.TextEdit = False;
	vNewField.Title = "";
	vNewField.TitleLocation = FormItemTitleLocation.None;
	vNewField.DataPath = "Currency"+pIndex;
	vNewField.Width = 7;
	vNewField.ClearButton = False;
	vNewField.ChoiceButton = True;
	vNewField.OpenButton = False;
	vNewField.HorizontalStretch = False;
	vNewField.SetAction("StartChoice", "CurrencyStartChoice");
EndProcedure // AddAccommodationTypeFieldAttributes

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckParamAtServer()
	// Check parmeters
	If ValueIsFilled(BegOfDay(DateFrom)) And ValueIsFilled(EndOfDay(DateTo))   Then
		If Not BegOfDay(DateFrom) < EndOfDay(DateTo)  Then
			vMessage = NStr("en='Check-in date is later then check-out date!';ru='Дата окончания должна быть больше даты начала!';de='Das Abreisedatum liegt vor dem Anreisedatum!'");
			Raise vMessage;
		EndIf;
	Else
		vMessage = NStr("en='You must fill in the start date and the end date!';ru='Необходимо заполнить дату начала и дату окончания!';de='Sie müssen in der Startdatum und Enddatum zu füllen!'");
		Raise vMessage;
	EndIf;

	If Not Day1 And Not Day2 And Not Day3 And Not Day4 And Not Day5 And Not Day6 And Not Day7 Then
		vMessage = NStr("en='Check days of week!';ru='Отметьте дни недели!';de='Wochentage markieren!'");
		Raise vMessage;
	EndIf;
	
	If Not ValueIsFilled(RoomRate) Then
		vMessage = NStr("en='Select room rate first!';ru='Выберите тариф для изменения!';de='Wählen Sie den zu ändernden Tarif aus!'");
		Raise vMessage;
	EndIf;

	If RoomTypes.Count() = 0 Then
		vMessage = NStr("en='Check room types for a change!';ru='Отметьте типы номеров для изменения!';de='Markieren Sie die Zimmern Typen für eine Veränderung!'");
		Raise vMessage;
	EndIf;  
	
	If ClientTypes.Count() = 0 Then
		vMessage = NStr("en='Mark the client types to change!';ru='Отметьте типы клиентов для изменения!';de='Markieren Sie die Kundentypen, um sich zu ändern!'");
		Raise vMessage;
	EndIf;
	
	If PriceTags.Count() = 0 And Items.PriceTags.Visible Then
		vMessage = NStr("en='Mark the price tags to change!';ru='Отметьте признаки цены для изменения!';de='Markieren Sie die Preiszeichen, um sich zu ändern!'");
		Raise vMessage;
	EndIf;
EndProcedure // CheckParamAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GetRoomRatePrices()
	// Check parmeters
	CheckParamAtServer();
	
	vAccTypes = cmGetAllAccommodationTypes();
	
	If RoomTypes.Count() = 0 Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Select at least one room type!'; 
		                                                |ru='Отметьте как минимум один тип номера!'; 
														|de='Markieren Sie mindestens einen Zimmertyp!'"), MessageStatus.Attention);
		Return;
	EndIf;
	If ClientTypes.Count() = 0 Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Select at least one client type (check mark empty by default)!'; 
		                                                |ru='Отметьте как минимум один тип клиента (по умолчанию отметьте пустой)!'; 
														|de='Markieren Sie mindestens einen Kundentyp (häkchen standardmäßig leer)!'"), MessageStatus.Attention);
		Return;
	EndIf;
	If Items.PriceTags.Visible And PriceTags.Count() = 0 Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Select at least one price tag!'; 
		                                                |ru='Отметьте как минимум один признак цены!'; 
														|de='Markieren Sie mindestens einen Preiseigenschaft!'"), MessageStatus.Attention);
		Return;
	EndIf;

	vRoomRate = RoomRate;
	vClientType = ClientTypes[0].Value;
	vPriceTag = Catalogs.PriceTags.EmptyRef();
		
	// Get day type
	vDayType = cmGetCalendarDayType(vRoomRate, DateFrom, DateTo, DateTo, , , CurrentSessionDate());
	
	// Get prices valid for the period from date
	vBasePrices = vRoomRate.GetObject().pmGetRoomRatePrices(DateFrom, CurrentSessionDate(), vClientType, , , , vPriceTag, DateFrom, DateTo, , True, , Hotel);
	If ValueIsFilled(vClientType) And (vBasePrices.Count() = 0 Or vBasePrices.FindRows(New Structure("IsRoomRevenue", True)).Count() = 0) Then
		vBasePrices = vRoomRate.GetObject().pmGetRoomRatePrices(DateFrom, CurrentSessionDate(), Catalogs.ClientTypes.EmptyRef(), , , , vPriceTag, DateFrom, DateTo, , True, , Hotel);
	EndIf;
	If vBasePrices.Count() = 0 Then
		vMessage = NStr("en='You have to perform initial prices configuration of the room rate item: ';ru='Нужно выполнить первоначальную настройку цен для тарифа: ';de='Sie haben die ersten Preise Konfiguration des Zimmerpreises durchführen für Tariff: '") + TrimAll(vRoomRate.Description);
		Raise vMessage;
	EndIf;
	vBasePrices.Indexes.Add("CalendarDayType");
	vBasePrices.Indexes.Add("Recorder, IsRoomRevenue, RoomType, AccommodationType");
	
	RoomRatePrices = Undefined;
	If ValueIsFilled(vDayType) Then
		vFilterBasePrices = vBasePrices.FindRows(New Structure ("CalendarDayType, Hotel, IsRoomRevenue, IsInPrice", vDayType, Hotel, True, True));
		If vFilterBasePrices.Count() = 0 Then
			For Each vBasePricesRow In vBasePrices Do
				If ValueIsFilled(vBasePricesRow.Recorder) Then
					RoomRatePrices = vBasePricesRow.Recorder;
					If RoomRatePrices.Hotel <> Hotel Then
						RoomRatePrices = Undefined;
					Else
						Break;
					EndIf;
				EndIf;
			EndDo;
		Else
			RoomRatePrices = vFilterBasePrices[0].Recorder;
		EndIf;
	EndIf;
	If Not ValueIsFilled(RoomRatePrices) Then
		vMessage = NStr("en='No active set room rate prices document found for the room rate: ';ru='Не найден действующий приказ об изменении цен для тарифа: ';de='Keine aktive Set Zimmerpreis Dokument für die Tariff gefunden: '") + TrimAll(vRoomRate) + ", " + TrimAll(vDayType) + ", " + TrimAll(vPriceTag);
		Raise vMessage;
	EndIf;	
	
	// Get price table
	vTablePrices = vBasePrices.FindRows(New Structure("Recorder, IsRoomRevenue, IsInPrice", RoomRatePrices, True, True));
	If vTablePrices.Count() = 0 Then
		vMessage = NStr("en='No prices found for the room rate: ';ru='Не найдены цены для тарифа: ';de='Keine Preise für die Tariff gefunden: '") + TrimAll(vRoomRate.Description);
		Raise vMessage;
	EndIf;	
	
	// Fill prices for all room types
	For Each vRoomTypesItem In AllRoomTypes Do
		vRoomTypeInd = AllRoomTypes.IndexOf(vRoomTypesItem) + 1;
		For Each vAccTypesRow In vAccTypes Do
			vIndex = Format(vRoomTypeInd, "ND=3; NFD=; NZ=; NLZ=; NG=") + Format(vAccTypes.IndexOf(vAccTypesRow), "ND=3; NFD=; NZ=; NLZ=; NG=");
			vPrices = vBasePrices.FindRows(New Structure("Recorder, IsRoomRevenue, RoomType, AccommodationType", RoomRatePrices, True, vRoomTypesItem.Value, vAccTypesRow.AccommodationType));
			ThisForm["Price"+vIndex] = ?(vPrices.Count() > 0, vPrices[0].Price, 0);
		EndDo;
	EndDo;

	SetVisible();
EndProcedure // GetRoomRatePrices

// -----------------------------------------------------------------------------
Function CheckIfRoomRateHasUniqueCalendar(pRoomRate)
	vCalendar = pRoomRate.Calendar;
	
	// Try to find other room rates referencing the same calendar
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRates.Ref
	|FROM
	|	Catalog.RoomRates AS RoomRates
	|WHERE
	|	NOT (RoomRates.DeletionMark)
	|	AND (NOT RoomRates.IsFolder)
	|	AND RoomRates.Ref <> &qRoomRate
	|	AND RoomRates.Calendar = &qCalendar
	|	AND RoomRates.BasedOnRoomRate = &qEmptyRoomRate
	|
	|ORDER BY
	|	RoomRates.SortCode,
	|	RoomRates.Code";
	vQry.SetParameter("qRoomRate", pRoomRate);
	vQry.SetParameter("qCalendar", vCalendar);
	vQry.SetParameter("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	vOtherRoomRates = vQry.Execute().Unload();
	If vOtherRoomRates.Count() > 0 Then
		// Create new calendar as  copy of the old one and copy all it's dates
		vNewCalendar = RatesManagement.CopyCalendar(vCalendar, pRoomRate.Description, pRoomRate.Code);
		
		// Set the new calendar to the current room rate
		vRoomRateObj = pRoomRate.GetObject();
		vRoomRateObj.Calendar = vNewCalendar;
		vRoomRateObj.Write();
		
		// Set the new calendar to all room rates based on the current one
		vChildRoomRates = vRoomRateObj.pmGetChildRoomRates();
		For Each vChildRoomRatesRow In vChildRoomRates Do
			vChildRoomRateObj = vChildRoomRatesRow.RoomRate.GetObject();
			vChildRoomRateObj.Calendar = vNewCalendar;
			vChildRoomRateObj.Write();
		EndDo;
		
		// Update calendar reference
		vCalendar = vNewCalendar;
	EndIf;
	
	// Return calendar reference
	Return vCalendar;
EndFunction // CheckIfRoomRateHasUniqueCalendar

// -----------------------------------------------------------------------------
&AtServer
Function SetPricesAtServer()
	vResult = False;
	
	CheckParamAtServer();
	
	// Check set room prices document
	If Not ValueIsFilled(RoomRatePrices) Then
		vMessage = NStr("en='No active set room rate prices document found!';ru='Не найден действующий приказ об изменении цен для тарифа!';de='Keine aktive Set Zimmerpreis Dokument für die Tariff gefunden!'");
		Raise vMessage;
	EndIf;
	
	// Get all accommodation types
	vAccommodationTypes = cmGetAllAccommodationTypes();
	
	// Do all changes in one transaction
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vRoomRate = RoomRate;
		
		vPriceTags = New ValueList();
		If PriceTags.Count() > 0 Then
			vPriceTags = PriceTags;
		Else
			vPriceTags.Add(Catalogs.PriceTags.EmptyRef());
		EndIf;
		
		// Add day type to the calendar
		vPeriodDayType = UpdateRoomRateCalendar(vRoomRate);
		
		// Get room rate prices
		If ValueIsFilled(vPeriodDayType) Then
			For Each vPriceTagItem In vPriceTags Do
				// Create new set room rate prices document
				vNewRoomRatePrices = RoomRatePrices.Copy();
				vNewRoomRatePrices.Hotel = Hotel;
				vNewRoomRatePrices.Author = SessionParameters.CurrentUser;
				vNewRoomRatePrices.CalendarDayType = vPeriodDayType;
				vNewRoomRatePrices.RoomRate = vRoomRate;
				vNewRoomRatePrices.PriceTag = vPriceTagItem.Value;
				vNewRoomRatePrices.Date = CurrentSessionDate();
				vNewRoomRatePrices.SetTime(AutoTimeMode.CurrentOrLast);
				
				// Update it's prices
				vTab = vNewRoomRatePrices.Prices;
				For Each vClientTypeItem In ClientTypes Do
					For Each vRoomTypesItem In RoomTypes Do
						vFltrRows = vTab.FindRows(New Structure("RoomType, ClientType, IsRoomRevenue, IsInPrice", vRoomTypesItem.Value, vClientTypeItem.Value, True, True));
						If vFltrRows.Count() = 0 Then
							vFltrRows = vTab.FindRows(New Structure("RoomType, ClientType, IsRoomRevenue, IsInPrice", Catalogs.RoomTypes.EmptyRef(), vClientTypeItem.Value, True, True));
							If vFltrRows.Count() = 0 And ValueIsFilled(vRoomTypesItem.Value.Parent) Then
								vFltrRows = vTab.FindRows(New Structure("RoomType, ClientType, IsRoomRevenue, IsInPrice", vRoomTypesItem.Value.Parent, vClientTypeItem.Value, True, True));
							EndIf;
						EndIf;
						For Each vFltrRow In vFltrRows Do
							For Each vAccommodationTypesRow In vAccommodationTypes Do
								If ValueIsFilled(vFltrRow.AccommodationType) And vFltrRow.AccommodationType = vAccommodationTypesRow.AccommodationType Or 
								   vFltrRow.AccommodationType = Catalogs.AccommodationTypes.EmptyRef() Or 
								   ValueIsFilled(vFltrRow.AccommodationType) And vFltrRow.AccommodationType.IsFolder And vAccommodationTypesRow.AccommodationType.BelongsToItem(vFltrRow.AccommodationType) Then
									vIndex = Format(AllRoomTypes.IndexOf(AllRoomTypes.FindByValue(vRoomTypesItem.Value)) + 1, "ND=3; NFD=; NZ=; NLZ=; NG=") + Format(vAccommodationTypes.IndexOf(vAccommodationTypesRow), "ND=3; NFD=; NZ=; NLZ=; NG=");
									vFltrRow.Price = ThisForm["Price" + vIndex];
									vFltrRow.Currency = ThisForm["Currency" + vIndex];
								EndIf;
							EndDo;
						EndDo;
					EndDo;
				EndDo;
				
				// Write new document to the database
				vNewRoomRatePrices.Write(DocumentWriteMode.Posting);
				vNewRoomRatePrices.pmWriteToSetRoomRatePricesChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndDo; // By price tags
		EndIf;
		
		// Commit transaction
		CommitTransaction();
		
		vResult = True;
	Except
		vErrorInfo = ErrorInfo();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Raise cmGetRootErrorDescription(vErrorInfo);
	EndTry;
	
	Return vResult;
EndFunction // SetPricesAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetPeriodDayType(pDescription, pHotel)
	vDayType = Catalogs.CalendarDayTypes.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CalendarDayTypes.Ref AS Ref
	|FROM
	|	Catalog.CalendarDayTypes AS CalendarDayTypes
	|WHERE
	|	CalendarDayTypes.Description = &qDescription
	|	AND NOT CalendarDayTypes.IsFolder
	|	AND (CalendarDayTypes.Hotel = &qHotel
	|			OR CalendarDayTypes.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|
	|ORDER BY
	|	CalendarDayTypes.Code DESC";
	vQry.SetParameter("qDescription", pDescription);
	vQry.SetParameter("qHotel", pHotel);
	vDayTypes = vQry.Execute().Unload();
	If vDayTypes.Count() > 0 Then
		vDayType = vDayTypes.Get(0).Ref;
	EndIf;
	Return vDayType;
EndFunction // GetPeriodDayType

// -----------------------------------------------------------------------------
&AtServer
Function UpdateRoomRateCalendar(pRoomRate)
	vCurDateTime = CurrentSessionDate();

	// Get day type
	vPeriodDescription = TrimAll(CalendarDayTypeDescription);
	If IsBlankString(vPeriodDescription) Then
		vPeriodDescription = GetPeriodDescription();
	EndIf;
	vPeriodDayType = GetPeriodDayType(vPeriodDescription, Hotel);
	
	// Create new day type if it is not found or it was used already
	If Not ValueIsFilled(vPeriodDayType) Then
		vNewDayTypeObj = Catalogs.CalendarDayTypes.CreateItem();
		vNewDayTypeObj.Description = vPeriodDescription;
		vNewDayTypeObj.SetNewCode();
		vNewDayTypeObj.Write();
		vPeriodDayType = vNewDayTypeObj.Ref;
	ElsIf vPeriodDayType.DeletionMark Then
		vPeriodDayType.GetObject().SetDeletionMark(False);
	EndIf;	
	
	// Check if room rate has unique calendar. If not then create it as copy of the current
	vRoomRateOldCalendar = pRoomRate.Calendar;
	vCalendar = CheckIfRoomRateHasUniqueCalendar(pRoomRate);
	
	// Process user input
	vCalendarDaysRcdSet = InformationRegisters.CalendarDays.CreateRecordSet();
	vCalendarFlt = vCalendarDaysRcdSet.Filter.Calendar;
	vCalendarFlt.Value = vCalendar;

	vCalendarDaysByRoomTypesRcdSet = InformationRegisters.CalendarDaysByRoomTypes.CreateRecordSet();
	vCalendarFltByRoomTypes = vCalendarDaysByRoomTypesRcdSet.Filter.Calendar;
	vCalendarFltByRoomTypes.Value = vCalendar;
	
	vDate = DateFrom;
	vDateTo = DateTo;
	While vDate <= vDateTo Do
		// Check day of week
		If ThisObject["Day" + WeekDay(vDate)] Then
			// Read calendar record before the current date
			vOldCalendarDaysRow = Undefined;
			vOldCalendarDays = InformationRegisters.CalendarDays.SliceLast(New Boundary(vCurDateTime, BoundaryType.Excluding), New Structure("Calendar, AccountingDate", vCalendar, vDate));
			If vOldCalendarDays.Count() > 0 Then
				vOldCalendarDaysRow = vOldCalendarDays.Get(0);
			EndIf;
			
			// Write new caledar day record
			vCalendarDaysRow = vCalendarDaysRcdSet.Add();
			vCalendarDaysRow.Calendar = vCalendar;
			vCalendarDaysRow.Period = vCurDateTime;
			vCalendarDaysRow.AccountingDate = vDate;
			vCalendarDaysRow.CalendarDayType = vPeriodDayType;
			If vOldCalendarDaysRow <> Undefined Then
				vCalendarDaysRow.Timetable = vOldCalendarDaysRow.Timetable;
				vCalendarDaysRow.PriceTag = vOldCalendarDaysRow.PriceTag;
				vCalendarDaysRow.RoomPrice = vOldCalendarDaysRow.RoomPrice;
				vCalendarDaysRow.RoomPriceCurrency = vOldCalendarDaysRow.RoomPriceCurrency;
				vCalendarDaysRow.Remarks = vOldCalendarDaysRow.Remarks;
			EndIf;
			vCalendarDaysRow.Author = SessionParameters.CurrentUser;
			vCalendarDaysRow.Active = True;

			// Read calendar records by room types for the current date
			vOldCalendarDaysByRoomTypes = InformationRegisters.CalendarDaysByRoomTypes.SliceLast(New Boundary(vCurDateTime, BoundaryType.Excluding), New Structure("Calendar, AccountingDate", vCalendar, vDate));
			For Each vOldCalendarDaysByRoomTypesRow In vOldCalendarDaysByRoomTypes Do
				vCalendarDaysByRoomTypesRow = vCalendarDaysByRoomTypesRcdSet.Add();
				vCalendarDaysByRoomTypesRow.Calendar = vCalendar;
				vCalendarDaysByRoomTypesRow.RoomType = vOldCalendarDaysByRoomTypesRow.RoomType;
				vCalendarDaysByRoomTypesRow.Hotel = vOldCalendarDaysByRoomTypesRow.Hotel;
				vCalendarDaysByRoomTypesRow.Period = vCurDateTime;
				vCalendarDaysByRoomTypesRow.AccountingDate = vDate;
				vCalendarDaysByRoomTypesRow.CalendarDayType = vPeriodDayType;
				vCalendarDaysByRoomTypesRow.PriceTag = vOldCalendarDaysByRoomTypesRow.PriceTag;
				vCalendarDaysByRoomTypesRow.RoomPrice = vOldCalendarDaysByRoomTypesRow.RoomPrice;
				vCalendarDaysByRoomTypesRow.RoomPriceCurrency = vOldCalendarDaysByRoomTypesRow.RoomPriceCurrency;
				vCalendarDaysByRoomTypesRow.Remarks = vOldCalendarDaysByRoomTypesRow.Remarks;
				vCalendarDaysByRoomTypesRow.Author = SessionParameters.CurrentUser;
				vCalendarDaysByRoomTypesRow.Active = True;
			EndDo;
		EndIf;
		
		// Go to the next date
		vDate = vDate + 24 * 3600;
	EndDo;
	
	// Update dates in the calendar
	If vCalendarDaysRcdSet.Count() > 0 Then
		vCalendarDaysRcdSet.Write(False);
	EndIf;
	
	// Update dates in the calendar
	If vCalendarDaysByRoomTypesRcdSet.Count() > 0 Then
		vCalendarDaysByRoomTypesRcdSet.Write(False);
	EndIf;
	
	Return vPeriodDayType;
EndFunction // UpdateRoomRateCalendar

// -----------------------------------------------------------------------------
&AtServer
Procedure SetVisible()
 	vPrices = Undefined;
	vChangePrices = False;
	If ValueIsFilled(RoomRatePrices) Then
		vChangePrices = True;
		vPrices = RoomRatePrices.Prices;
	EndIf;
	Items.GetPrices.Visible = True;
	Items.GetPrices.Enabled = True;
	Items.RoomTypesGroup.Visible = vChangePrices;
	Items.RoomRatePrices.Visible = vChangePrices;
	For Each vRoomTypesItem In AllRoomTypes Do
		vRoomTypeIndex = AllRoomTypes.IndexOf(vRoomTypesItem) + 1;
		vRoomTypeGroup = Items["RoomTypeGroup" + Format(vRoomTypeIndex, "ND=3; NFD=; NZ=; NLZ=; NG=")];
		If vRoomTypesItem.Check Then
			vRoomTypeGroup.Visible = vChangePrices;
		Else
			vRoomTypeGroup.Visible = False;
		EndIf;
		If vChangePrices Then
			// Manage visibility of room type
			vRoomTypeHasPrices = False;
			vRoomTypePriceRows = vPrices.FindRows(New Structure("IsRoomRevenue, IsInPrice, RoomType", True, True, vRoomTypesItem.Value));
			If vRoomTypePriceRows.Count() > 0 Then
				vRoomTypeHasPrices = True;
			Else
				vRoomTypePriceRows = vPrices.FindRows(New Structure("IsRoomRevenue, IsInPrice, RoomType", True, True, Catalogs.RoomTypes.EmptyRef()));
				If vRoomTypePriceRows.Count() > 0 Then
					vRoomTypeHasPrices = True;
				ElsIf ValueIsFilled(vRoomTypesItem.Value.Parent) Then
					vRoomTypePriceRows = vPrices.FindRows(New Structure("IsRoomRevenue, IsInPrice, RoomType", True, True, vRoomTypesItem.Value.Parent));
					If vRoomTypePriceRows.Count() > 0 Then
						vRoomTypeHasPrices = True;
					EndIf;
				EndIf;
			EndIf;
			If Not vRoomTypeHasPrices Then
				vRoomTypeGroup.Visible = False;
			Else
				// Manage visibility of accommodation types				
				For vAccTypeIndex = 0 To 999 Do
					vIndex = Format(vRoomTypeIndex, "ND=3; NFD=; NZ=; NLZ=; NG=") + Format(vAccTypeIndex, "ND=3; NFD=; NZ=; NLZ=; NG=");
					vAccTypeGroupItem = Items.Find("AccommodationTypeGroup" + vIndex);
					If vAccTypeGroupItem = Undefined Then
						Break;
					EndIf;
					vAccommodationType = ThisForm["AccommodationType" + vIndex];
					If ValueIsFilled(vAccommodationType) Then
						vAccTypeHasPrices = False;
						vAccTypePriceRows = vPrices.FindRows(New Structure("IsRoomRevenue, IsInPrice, AccommodationType", True, True, vAccommodationType));
						If vAccTypePriceRows.Count() > 0 Then
							vAccTypeHasPrices = True;
						Else
							vAccTypePriceRows = vPrices.FindRows(New Structure("IsRoomRevenue, IsInPrice, AccommodationType", True, True, Catalogs.AccommodationTypes.EmptyRef()));
							If vAccTypePriceRows.Count() > 0 Then
								vAccTypeHasPrices = True;
							ElsIf ValueIsFilled(vAccommodationType.Parent) Then
								vAccTypePriceRows = vPrices.FindRows(New Structure("IsRoomRevenue, IsInPrice, AccommodationType", True, True, vAccommodationType.Parent));
								If vAccTypePriceRows.Count() > 0 Then
									vAccTypeHasPrices = True;
								EndIf;
							EndIf;
						EndIf;
						If Not vAccTypeHasPrices Then
							vAccTypeGroupItem.Visible = False;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // SetVisible	

// -----------------------------------------------------------------------------
Function GetCurrencies()
	vCurrenciesList = New ValueList;
	vCurrencies = cmGetAllCurrencies();
	vCurrenciesList.LoadValues(vCurrencies.UnloadColumn("Currency"));
	Return vCurrenciesList;
EndFunction // GetCurrencies

// -----------------------------------------------------------------------------
&AtServer
Function GetPeriodDescription()
	vDays = "";
	If ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) Then
		If DateFrom < DateTo Then
			vDays = String(Format(DateFrom, "DF=dd.MM")) + "-" + String(Format(DateTo, "DF=dd.MM"));
		Else
			vDays = String(Format(DateFrom, "DF=dd.MM"));
		EndIf;
	EndIf;
	If Not AllDays Then
		vDays = vDays + "_";
		If Day1 Then
			vDays = vDays + Title(cmGetDayOfWeekName(1, True));
		EndIf;
		If Day2 Then
			vDays = vDays + Title(cmGetDayOfWeekName(2, True));
		EndIf;
		If Day3 Then
			vDays = vDays + Title(cmGetDayOfWeekName(3, True));
		EndIf;
		If Day4 Then
			vDays = vDays + Title(cmGetDayOfWeekName(4, True));
		EndIf;
		If Day5 Then
			vDays = vDays + Title(cmGetDayOfWeekName(5, True));
		EndIf;
		If Day6 Then
			vDays = vDays + Title(cmGetDayOfWeekName(6, True));
		EndIf;
		If Day7 Then
			vDays = vDays + Title(cmGetDayOfWeekName(7, True));
		EndIf;
	EndIf;
	Return vDays;
EndFunction // GetPeriodDescription

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure RunFillRoomRatePricesCacheAtServer(pHotel, pRoomRatesList, pPeriodFrom, pPeriodTo)
	vParams = New Array();
	vParams.Add(pHotel);
	vParams.Add(pRoomRatesList);
	vParams.Add(pPeriodFrom);
	vParams.Add(pPeriodTo);
	vBJ = BackgroundJobs.Execute("JobsScheduled.cmFillRoomRatePricesCache", vParams, , NStr("en='Fill room rate prices cache: '; ru='Заполнение кэша цен тарифов: '; de='Zimmerpreis Preise Cache füllen: '") + TrimAll(pHotel) + ", " + GetListPresentation(pRoomRatesList) + ", " + Format(pPeriodFrom, "DF=dd.MM.yyyy") + " - " + Format(pPeriodTo, "DF=dd.MM.yyyy")); 
EndProcedure // RunFillRoomRatePricesCacheAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetListPresentation(pList)
	vStr = "";
	For Each vListItem In pList Do
		vStr = vStr + ?(IsBlankString(vStr), "", ", ") + TrimAll(vListItem.Value);
	EndDo;
	Return vStr;
EndFunction // GetListPresentation

// -------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = DateFrom;
	vChoosePeriodDialog.Period.EndDate = DateTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		DateFrom = pPeriod.StartDate;
		DateTo = pPeriod.EndDate;
		If DateFrom <= DateTo Then
			// Fill name of new calandar day type
			CalendarDayTypeDescription = GetPeriodDescription();
		Else
			ShowMessageBox(, NStr("en='Period is wrong!'; ru='Период указан неверно!'; de='Der Zeitraum ist falsch angegeben!'"));
		EndIf;
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDays()
	AllDays = True;
	For i = 1 To 7 Do
		ThisForm["Day" + i] = AllDays;		
	EndDo;
	// Switch off some days
	If Parameters.Property("SwitchedOffWeekdays") And TypeOf(Parameters.SwitchedOffWeekdays) = Type("Array") Then
		For Each vOffDay In Parameters.SwitchedOffWeekdays Do
			ThisForm["Day" + vOffDay] = False;
			AllDays = False;
		EndDo;
	EndIf;
EndProcedure // FillDays

// -----------------------------------------------------------------------------
&AtClient
Procedure AllDaysOnChange()
	For i = 1 To 7 Do
		ThisForm["Day" + i] = AllDays;		
	EndDo;
	// Fill name of new calandar day type
	CalendarDayTypeDescription = GetPeriodDescription();
EndProcedure // AllDaysOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure ResetAll(pItem)
	If Day1 And Day2 And Day3 And Day4 And Day5 And Day6 And Day7 Then
		AllDays = True;
	Else
		AllDays = False;
	EndIf;
	// Fill name of new calandar day type
	CalendarDayTypeDescription = GetPeriodDescription();
EndProcedure // ResetAll

// -----------------------------------------------------------------------------
&AtClient
Procedure DateFromOnChange(pItem)
	If DateFrom <= DateTo Then
		// Fill name of new calandar day type
		CalendarDayTypeDescription = GetPeriodDescription();
	Else
		ShowMessageBox(, NStr("en='Period is wrong!'; ru='Период указан неверно!'; de='Der Zeitraum ist falsch angegeben!'"));
	EndIf;
EndProcedure // DateFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DateToOnChange(pItem)
	If DateFrom <= DateTo Then
		// Fill name of new calandar day type
		CalendarDayTypeDescription = GetPeriodDescription();
	Else
		ShowMessageBox(, NStr("en='Period is wrong!'; ru='Период указан неверно!'; de='Der Zeitraum ist falsch angegeben!'"));
	EndIf;
EndProcedure // DateToOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomTypesList()
	AllRoomTypes.Clear();
	RoomTypes.Clear();

	If ValueIsFilled(Hotel) Then
		vAllRoomTypes = cmGetAllRoomTypes(Hotel);
		For Each vAllRoomTypesRow In vAllRoomTypes Do
			AllRoomTypes.Add(vAllRoomTypesRow.RoomType, TrimAll(vAllRoomTypesRow.RoomType) + " (" + TrimAll(vAllRoomTypesRow.RoomClass) + ")", False);
		EndDo;
		If TypeOf(Basis) = Type("CatalogRef.RoomTypes") And ValueIsFilled(Basis) Then
			RoomTypes.Add(Basis);
			vAllRoomTypesItem = AllRoomTypes.FindByValue(Basis);
			If vAllRoomTypesItem <> Undefined Then
				vAllRoomTypesItem.Check = True;
			EndIf;
		ElsIf TypeOf(Basis) = Type("ValueList") And Basis.Count() > 0 Then
			For Each vBasisItem In Basis Do
				RoomTypes.Add(vBasisItem.Value);
				vAllRoomTypesItem = AllRoomTypes.FindByValue(vBasisItem.Value);
				If vAllRoomTypesItem <> Undefined Then
					vAllRoomTypesItem.Check = True;
				EndIf;
			EndDo;
		Else
			For Each vAllRoomTypesItem In AllRoomTypes Do
				vAllRoomTypesItem.Check = True;
				RoomTypes.Add(vAllRoomTypesItem.Value);
			EndDo;
		EndIf;
	EndIf;
EndProcedure // FillRoomTypesList

// -------------------------------------------------------------------------
&AtClient
Procedure RoomTypesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If AllRoomTypes.Count() > 0 Then
		For Each vAllRoomTypesItem In AllRoomTypes Do
			vAllRoomTypesItem.Check = False;
		EndDo;
		For Each vRoomTypesItem In RoomTypes Do
			vAllRoomTypesItem = AllRoomTypes.FindByValue(vRoomTypesItem.Value);
			If vAllRoomTypesItem <> Undefined Then
				vAllRoomTypesItem.Check = True;
			EndIf;
		EndDo;
		AllRoomTypes.ShowCheckItems(New NotifyDescription("RoomTypesWereChecked", ThisForm), NStr("en='Select room types that need to be changed'; ru='Отметьте типы номеров для изменения'; de='Markieren Sie die zu ändernden Zimmertypen'"));
	EndIf;
EndProcedure // RoomTypesStartChoice

// -------------------------------------------------------------------------
&AtClient
Procedure RoomTypesWereChecked(pList, pExtraParams) Export
	If pList <> Undefined Then
		RoomTypes.Clear();
		For Each vListItem In pList Do
			If vListItem.Check Then
				RoomTypes.Add(vListItem.Value);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // RoomTypesWereChecked

// -------------------------------------------------------------------------
&AtClient
Procedure RoomTypesClearing(pItem, pStandardProcessing)
	For Each vRoomTypesItem In AllRoomTypes Do
		vRoomTypesItem.Check = False;
	EndDo;
EndProcedure // RoomTypesClearing

// -------------------------------------------------------------------------
&AtClient
Procedure ClientTypesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If AllClientTypes.Count() > 0 Then
		For Each vAllClientTypesItem In AllClientTypes Do
			vAllClientTypesItem.Check = False;
		EndDo;
		For Each vClientTypesItem In ClientTypes Do
			vAllClientTypesItem = AllClientTypes.FindByValue(vClientTypesItem.Value);
			If vAllClientTypesItem <> Undefined Then
				vAllClientTypesItem.Check = True;
			EndIf;
		EndDo;
		AllClientTypes.ShowCheckItems(New NotifyDescription("ClientTypesWereChecked", ThisForm), NStr("en='Select client types that need to be changed'; ru='Отметьте типы клиентов для изменения'; de='Markieren Sie die zu ändernden Kundentypen'"));
	EndIf;
EndProcedure // ClientTypesStartChoice

// -------------------------------------------------------------------------
&AtClient
Procedure ClientTypesWereChecked(pList, pExtraParams) Export
	If pList <> Undefined Then
		ClientTypes.Clear();
		For Each vListItem In pList Do
			If vListItem.Check Then
				If pList.IndexOf(vListItem) = 0 Then
					ClientTypes.Add(vListItem.Value, NStr("en='<Empty client type>'; ru='<Пустой тип клиента>'; de='<Leerer Kundentyp>'"));
				Else
					ClientTypes.Add(vListItem.Value);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // ClientTypesWereChecked

// -------------------------------------------------------------------------
&AtClient
Procedure ClientTypesClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	ClientTypes.Clear();
	ClientTypes.Add(PredefinedValue("Catalog.ClientTypes.EmptyRef"), NStr("en='<Empty client type>'; ru='<Пустой тип клиента>'; de='<Leerer Kundentyp>'"));
	For Each vAllClientTypesItem In AllClientTypes Do
		If AllClientTypes.IndexOf(vAllClientTypesItem) = 0 Then
			vAllClientTypesItem.Check = True;
		Else
			vAllClientTypesItem.Check = False;
		EndIf;
	EndDo;
EndProcedure // ClientTypesClearing

// -------------------------------------------------------------------------
&AtClient
Procedure PriceTagsStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If AllPriceTags.Count() > 0 Then
		For Each vAllPriceTagsItem In AllPriceTags Do
			vAllPriceTagsItem.Check = False;
		EndDo;
		For Each vPriceTagsItem In PriceTags Do
			vAllPriceTagsItem = AllPriceTags.FindByValue(vPriceTagsItem.Value);
			If vAllPriceTagsItem <> Undefined Then
				vAllPriceTagsItem.Check = True;
			EndIf;
		EndDo;
		AllPriceTags.ShowCheckItems(New NotifyDescription("PriceTagsWereChecked", ThisForm), NStr("en='Select client types that need to be changed'; ru='Отметьте типы клиентов для изменения'; de='Markieren Sie die zu ändernden Kundentypen'"));
	EndIf;
EndProcedure // PriceTagsStartChoice

// -------------------------------------------------------------------------
&AtClient
Procedure PriceTagsWereChecked(pList, pExtraParams) Export
	If pList <> Undefined Then
		PriceTags.Clear();
		For Each vListItem In pList Do
			If vListItem.Check Then
				PriceTags.Add(vListItem.Value);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // PriceTagsWereChecked

// -------------------------------------------------------------------------
&AtClient
Procedure PriceTagsClearing(pItem, pStandardProcessing)
	For Each vPriceTagsItem In AllPriceTags Do
		vPriceTagsItem.Check = False;
	EndDo;
EndProcedure // PriceTagsClearing

// -------------------------------------------------------------------------
&AtServer
Procedure FillPriceTagsOnServer()
	AllPriceTags.Clear();
	PriceTags.Clear();
	If ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.PriceTagType) Then
		Items.PriceTags.Visible = True;
		// Get all pricetags
		vPriceTags = cmGetAllPriceTags(, RoomRate.PriceTagType);
		// Fill price tags table
		For Each vPriceTagsRow In vPriceTags Do
			vPTItem = AllPriceTags.Add();
			vPTItem.Check = False;
			vPTItem.Value = vPriceTagsRow.PriceTag;
			vPTItem.Presentation = TrimAll(vPriceTagsRow.Description);
		EndDo;
	Else
		Items.PriceTags.Visible = False;
	EndIf;
EndProcedure // FillPriceTagsOnServer

// -------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	FillPriceTagsOnServer();
EndProcedure // RoomRateOnChange

#EndRegion




 