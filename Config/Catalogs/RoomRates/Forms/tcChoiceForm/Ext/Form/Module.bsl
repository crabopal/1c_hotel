
#Region FormEventHandlers

// -------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Hotel") And ValueIsFilled(Parameters.Hotel) Then
		SelHotel = Parameters.Hotel;
	EndIf;
	If Parameters.Filter.Property("Hotel") Then
		If ValueIsFilled(Parameters.Filter.Hotel) And Not ValueIsFilled(SelHotel) Then
			SelHotel = Parameters.Filter.Hotel;
		EndIf;
		Parameters.Filter.Delete("Hotel");
	EndIf;
	If Parameters.Filter.Property("IsFolder") Then
		vIsFolder = Parameters.Filter.IsFolder;
		If vIsFolder Then
		    Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Folders;
		Else 	
		    Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Items;
		EndIf; 
	Else 	
	    Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Items;
	EndIf;
	Parameters.Property("Company", SelCompany);
	Parameters.Property("Customer", SelCustomer);
	Parameters.Property("Contract", SelContract);
	Parameters.Property("RoomRateType", SelRoomRateType);
	Parameters.Property("Calendar", SelCalendar);
	Parameters.Property("PeriodFrom", SelPeriodFrom);
	Parameters.Property("PeriodTo", SelPeriodTo);
	Parameters.Property("CurrentRow", CurRoomRate);
	Parameters.Property("RoomRates", SelRoomRates);
	
	SetDefaultSearchFilter();
	SetFilterCollapsedTitle();
EndProcedure // OnCreateAtServer

// -------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If ValueIsFilled(tcOnServer.cmGetCurrentUserAttribute("Customer")) Then
		Items.SelHotel.ClearButton = False;
		Items.FormShowAll.Visible = False;
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -------------------------------------------------------
&AtClient
Procedure RoomRateTypeOnChange(pItem)
	AddNewFilter(pItem.Name, pItem.EditText);
	SetFilterCollapsedTitle();
EndProcedure // RoomRateTypeOnChange

// -------------------------------------------------------
&AtClient
Procedure CalendarOnChange(pItem)
	AddNewFilter(pItem.Name, pItem.EditText);
	SetFilterCollapsedTitle();
EndProcedure // CalendarOnChange

// -------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	AddNewFilter(pItem.Name, pItem.EditText);
	SetFilterCollapsedTitle();
EndProcedure // CompanyOnChange

// -------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	AddNewFilter(pItem.Name, pItem.EditText);
	SetFilterCollapsedTitle();
EndProcedure // HotelOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowAll(pCommand)
	Title = NStr("en='All room rates';ru='Все тарифы';de='Alle Tarife'");
	DeletingAllFilters();
EndProcedure // ShowAll

#EndRegion

#Region Private

// -------------------------------------------------------
&AtServer
Procedure AddNewFilter(pItem, pValue) Export
	vFilterItems = List.Filter.Items;
	If pItem = "SelRoomRates" Then
		vFindedField = List.ConditionalAppearance.FilterAvailableFields.Items.Find("Ref").Field;
	Else
		vFindedField = List.ConditionalAppearance.FilterAvailableFields.Items.Find(Right(pItem, StrLen(pItem)-3)).Field;
	EndIf;
	
	// Deleting old filter
	N = 1;
	For Num = 1 to vFilterItems.Count() Do
		If vFilterItems.Get(vFilterItems.Count()-N).LeftValue = vFindedField Then
			vFilterItems.Delete(vFilterItems.Get(vFilterItems.Count()-N));
		Else
			N = N + 1;
		EndIf;
	EndDo;
	
	// Add new filter
	If ValueIsFilled(String(pValue)) Then
		vNewFilter = vFilterItems.Add(Type("DataCompositionFilterItem"));
		vNewFilter.LeftValue = vFindedField;
		If pItem = "SelHotel" Then
			vListOfHotels = New ValueList();
			vListOfHotels.Add(Catalogs.Hotels.EmptyRef());
			vListOfHotels.Add(ThisForm[pItem]);
			vNewFilter.RightValue = vListOfHotels;		
			vNewFilter.ComparisonType = DataCompositionComparisonType.InList;
		ElsIf pItem = "SelRoomRates" Then
			vNewFilter.RightValue = SelRoomRates;		
			vNewFilter.ComparisonType = DataCompositionComparisonType.InList;
		Else
			vNewFilter.RightValue = ThisForm[pItem];		
			vNewFilter.ComparisonType = DataCompositionComparisonType.Equal;
		EndIf;
	EndIf;
	
	// Reset all filter titles
	Title = NStr("en='Filter room rates by: ';ru='Отбор тарифов по: ';de='Auswahl von Tarifen nach: '");
	
	// Filter title by room rate type
	If SelRoomRates.Count() > 0 Then
		Title = Title + NStr("en='allowed room rates; ';ru='разрешенным тарифам; ';de='autorisierte Tarife; '");
	EndIf;
	// Filter title by room rate type
	If ValueIsFilled(SelRoomRateType) Then
		Title = Title + NStr("en='room rate type; ';ru='типу тарифа; ';de='Tariftyp; '");
	EndIf;
	// Filter title by calendar
	If ValueIsFilled(SelCalendar) Then
		Title = Title + NStr("en='calendar; ';ru='календарю; ';de='dem Kalender; '");
	EndIf;
	// Filter title by company
	If ValueIsFilled(SelCompany) Then
		Title = Title + NStr("en='company; ';ru='фирме; ';de='der Firma; '");
	EndIf;
	// Filter title by hotel
	If ValueIsFilled(SelHotel) Then
		Title = Title + NStr("en='hotel; ';ru='гостинице; ';de='Hotel; '");
	EndIf;
	
	// If show all room rates
	If Not ValueIsFilled(SelHotel)
		And Not ValueIsFilled(SelCompany)
		And Not ValueIsFilled(SelCalendar)
		And Not ValueIsFilled(SelRoomRateType) Then
		Title = NStr("en='All room rates';ru='Все тарифы';de='Alle Tarife'");
	EndIf;
EndProcedure // AddNewFilter

// -------------------------------------------------------
&AtServer
Procedure SetDefaultSearchFilter()
	If Not ValueIsFilled(SelHotel) Then
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(SelHotel) Then
		AddNewFilter("SelHotel", SelHotel);
	EndIf;
	If ValueIsFilled(SelCompany) Then
		AddNewFilter("SelCompany", SelCompany);
	EndIf;
	If ValueIsFilled(SelCalendar) Then
		AddNewFilter("SelCalendar", SelCalendar);
	EndIf;
	If ValueIsFilled(SelRoomRateType) Then
		AddNewFilter("SelRoomRateType", SelRoomRateType);
	EndIf;
	If SelRoomRates.Count() = 0 Then
		vRoomRates = New ValueList();
		If ValueIsFilled(SelContract) And SelContract.RoomRates.Count() > 0 Then
			vRoomRates.LoadValues(SelContract.RoomRates.UnloadColumn("RoomRate"));
		ElsIf ValueIsFilled(SelCustomer) And SelCustomer.RoomRates.Count() > 0 Then
			vRoomRates.LoadValues(SelCustomer.RoomRates.UnloadColumn("RoomRate"));
		EndIf;
		r = 0;
		While r < vRoomRates.Count() Do
			If Not ValueIsFilled(vRoomRates.Get(r).Value) Then
				vRoomRates.Delete(r);
			Else
				r = r + 1;
			EndIf;
		EndDo;
		If ValueIsFilled(SelPeriodFrom) Or ValueIsFilled(SelPeriodTo) Then
			vRoomRatesAllowed = cmGetAllowedRoomRates(SelPeriodFrom, SelPeriodTo, CurrentSessionDate());
		Else
			vRoomRatesAllowed = cmGetAllowedRoomRates(Undefined, Undefined, CurrentSessionDate());
		EndIf;
		If vRoomRatesAllowed.Count() > 0 Then
			If vRoomRates.Count() > 0 Then
				i = 0;
				While i < vRoomRates.Count() Do
					vFrmRoomRate = vRoomRates.Get(i);
					If vRoomRatesAllowed.FindByValue(vFrmRoomRate.Value) = Undefined Then
						If Not (ValueIsFilled(CurRoomRate) And CurRoomRate = vFrmRoomRate.Value) Then
							vRoomRates.Delete(i);
						Else
							i = i + 1;
						EndIf;
					Else
						i = i + 1;
					EndIf;
				EndDo;
			Else
				vRoomRates.LoadValues(vRoomRatesAllowed.UnloadValues());
			EndIf;
		EndIf;
		SelRoomRates.LoadValues(vRoomRates.UnloadValues());
	EndIf;
	If SelRoomRates.Count() > 0 Then
		AddNewFilter("SelRoomRates", SelRoomRates);
	EndIf;
EndProcedure // SetDefaultSearchFilter

// -----------------------------------------------------------------------------
&AtServer
Procedure SetFilterCollapsedTitle()
	vAddColon = True;
	vAddSemiColon = False;
	vGroupSearchModeTitle = Items.FilterGroup.Title;
	If ValueIsFilled(SelRoomRateType) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelRoomRateType.Title + ": " + TrimAll(SelRoomRateType);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelCalendar) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelCalendar.Title + ": " + TrimAll(SelCalendar);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelCompany) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelCompany.Title + ": " + TrimAll(SelCompany);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	Items.FilterGroup.CollapsedRepresentationTitle = vGroupSearchModeTitle;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure // SetFilterCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure DeletingAllFilters()
	List.Filter.Items.Clear();
	SelRoomRateType = Undefined;
	SelCalendar = Undefined;
	SelCompany = Undefined;
	SetFilterCollapsedTitle();
	AddNewFilter("SelHotel", SelHotel);
	If SelRoomRates.Count() > 0 Then
		AddNewFilter("SelRoomRates", SelRoomRates);
	EndIf;
EndProcedure // DeletingAllFilters

#EndRegion
