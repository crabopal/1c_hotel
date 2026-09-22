
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Check permissions
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = True;
			Return;
		Else
			ReadOnly = True;
		EndIf;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
	EndIf;
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	// Initialize currency
	If Not ValueIsFilled(Object.Currency) Then
		If ValueIsFilled(Object.Hotel) Then
			Object.Currency = Object.Hotel.BaseCurrency;
		ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
			Object.Currency = SessionParameters.CurrentHotel.BaseCurrency;
		EndIf;
	EndIf;
	
	// Apply filter to the periods table
	ValidityPeriods.Parameters.SetParameterValue("qSpecialOffer", Object.Ref);
	
	// Check if terms service packages are available
	vTerms = cmGetAllMealBoardTerms(Object.Hotel);
	If vTerms.Count() = 0 Then
		Items.GroupTermsUpgrades.Visible = False;
	EndIf;
	Items.DecorationManualBindTooltip.Visible = Not Object.ApplyAutomatically;
	Items.DecorationOfferTypeBindToReservation.Visible = Not Object.ApplyAutomatically;
	Items.DecorationOfferTypeBindToClient.Visible = Not Object.ApplyAutomatically;
	Items.DecorationOfferTypeAutomatically.Visible = Object.ApplyAutomatically;	

	// Fill filter lists
	FillFilterLists();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure OnWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	// Fill room types links
	vRTRcdSet = InformationRegisters.SpecialOffersForRoomTypes.CreateRecordSet();
	vSOFlt = vRTRcdSet.Filter.SpecialOffer;
	vSOFlt.ComparisonType = ComparisonType.Equal;
	vSOFlt.Value = pCurrentObject.Ref;
	vSOFlt.Use = True;
	For Each vRoomTypesListItem In RoomTypesList Do
		For Each vRoomClassesListItem In RoomClassesList Do
			For Each vAccommodationTypesListItem In AccommodationTypesList Do
				vRTRcd = vRTRcdSet.Add();
				vRTRcd.SpecialOffer = pCurrentObject.Ref;
				vRTRcd.Hotel = pCurrentObject.Hotel;
				vRTRcd.RoomType = vRoomTypesListItem.Value;
				vRTRcd.RoomClass = vRoomClassesListItem.Value;
				vRTRcd.AccommodationType = vAccommodationTypesListItem.Value;
			EndDo;
		EndDo;
	EndDo;
	vRTRcdSet.Write(True);
	
	// Fill room rates links
	vRRRcdSet = InformationRegisters.SpecialOffersForRates.CreateRecordSet();
	vSOFlt = vRRRcdSet.Filter.SpecialOffer;
	vSOFlt.ComparisonType = ComparisonType.Equal;
	vSOFlt.Value = pCurrentObject.Ref;
	vSOFlt.Use = True;
	For Each vRoomRatesListItem In RoomRatesList Do
		For Each vRoomRateTypesListItem In RoomRateTypesList Do
			For Each vSourceOfBusinessListItem In SourcesOfBusinessList Do
				For Each vMarketingCodesListItem In MarketingCodesList Do
					For Each vTripPurposesListItem In TripPurposesList Do
						For Each vClientTypesListItem In ClientTypesList Do
							For Each vCustomerTypesListItem In CustomerTypesList Do
								vRRRcd = vRRRcdSet.Add();
								vRRRcd.SpecialOffer = pCurrentObject.Ref;
								vRRRcd.Hotel = pCurrentObject.Hotel;
								vRRRcd.RoomRate = vRoomRatesListItem.Value;
								vRRRcd.RoomRateType = vRoomRateTypesListItem.Value;
								vRRRcd.SourceOfBusiness = vSourceOfBusinessListItem.Value;
								vRRRcd.MarketingCode = vMarketingCodesListItem.Value;
								vRRRcd.TripPurpose = vTripPurposesListItem.Value;
								vRRRcd.ClientType = vClientTypesListItem.Value;
								vRRRcd.CustomerType = vCustomerTypesListItem.Value;
								vRRRcd.MLOS = MLOS;
								vRRRcd.MaxLOS = MaxLOS;
								vRRRcd.MinDaysBeforeCheckIn = MinDaysBeforeCheckIn;
								vRRRcd.MaxDaysBeforeCheckIn = MaxDaysBeforeCheckIn;
							EndDo;
						EndDo;
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	vRRRcdSet.Write(True);
EndProcedure // OnWriteAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	// Apply filter to the periods table
	ValidityPeriods.Parameters.SetParameterValue("qSpecialOffer", Object.Ref);
EndProcedure // AfterWriteAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	SetFormAttributesAppearance(True);
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	HotelOnChangeAtServer();
EndProcedure // HotelOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomTypesListStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	AllRoomTypesList.ShowCheckItems(New NotifyDescription("RoomTypesListEndChoice", ThisObject));
EndProcedure // RoomTypesListStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomTypesListEndChoice(pList, pExtraParams) Export
	If pList <> Undefined Then
		RoomTypesList.Clear();
		vSomethingIsChecked = Undefined;
		For Each vListItem In pList Do
			If Not ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = False;
					RoomTypesList.Add(PredefinedValue("Catalog.RoomTypes.EmptyRef"), NStr("en='<all room types>'; ru='<все типы номеров>'; de='<alle Zimmertypen>'"));
				EndIf;
			ElsIf ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = True;
					RoomTypesList.Add(vListItem.Value, vListItem.Presentation);
				Else
					If vSomethingIsChecked Then
						RoomTypesList.Add(vListItem.Value, vListItem.Presentation);
					Else
						vListItem.Check = False;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vSomethingIsChecked <> Undefined Then
			Items.RoomClassesList.Enabled = Not vSomethingIsChecked;
			If vSomethingIsChecked Then
				For Each vAllRoomClassesListItem In AllRoomClassesList Do
					vAllRoomClassesListItem.Check = Not ValueIsFilled(vAllRoomClassesListItem.Value);
				EndDo;
				RoomClassesList.Clear();
				RoomClassesList.Add(PredefinedValue("Catalog.RoomTypeClasses.EmptyRef"), NStr("en='<all room type classes>'; ru='<все классы номеров>'; de='<alle Zimmerklassen>'"));
			EndIf;
		Else
			AllRoomTypesList.FindByValue(PredefinedValue("Catalog.RoomTypes.EmptyRef")).Check = True;
			RoomTypesList.Add(PredefinedValue("Catalog.RoomTypes.EmptyRef"), NStr("en='<all room types>'; ru='<все типы номеров>'; de='<alle Zimmertypen>'"));
			Items.RoomClassesList.Enabled = True;
		EndIf;
	EndIf;
EndProcedure // RoomTypesListEndChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomTypesListClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	RoomTypesList.Clear();
	RoomTypesList.Add(PredefinedValue("Catalog.RoomTypes.EmptyRef"), NStr("en='<all room types>'; ru='<все типы номеров>'; de='<alle Zimmertypen>'"));
	For Each vListItem In AllRoomTypesList Do
		vListItem.Check = Not ValueIsFilled(vListItem.Value);
	EndDo;
	Items.RoomClassesList.Enabled = True;
EndProcedure // RoomTypesListClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomClassesListStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	AllRoomClassesList.ShowCheckItems(New NotifyDescription("RoomClassesListEndChoice", ThisObject));
EndProcedure // RoomClassesListStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomClassesListEndChoice(pList, pExtraParams) Export
	If pList <> Undefined Then
		RoomClassesList.Clear();
		vSomethingIsChecked = Undefined;
		For Each vListItem In pList Do
			If Not ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = False;
					RoomClassesList.Add(PredefinedValue("Catalog.RoomTypeClasses.EmptyRef"), NStr("en='<all room type classes>'; ru='<все классы номеров>'; de='<alle Zimmerklassen>'"));
				EndIf;
			ElsIf ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = True;
					RoomClassesList.Add(vListItem.Value, vListItem.Presentation);
				Else
					If vSomethingIsChecked Then
						RoomClassesList.Add(vListItem.Value, vListItem.Presentation);
					Else
						vListItem.Check = False;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vSomethingIsChecked <> Undefined Then
			Items.RoomTypesList.Enabled = Not vSomethingIsChecked;
			If vSomethingIsChecked Then
				For Each vAllRoomTypesListItem In AllRoomTypesList Do
					vAllRoomTypesListItem.Check = Not ValueIsFilled(vAllRoomTypesListItem.Value);
				EndDo;
				RoomTypesList.Clear();
				RoomTypesList.Add(PredefinedValue("Catalog.RoomTypes.EmptyRef"), NStr("en='<all room types>'; ru='<все типы номеров>'; de='<alle Zimmertypen>'"));
			EndIf;
		Else
			AllRoomClassesList.FindByValue(PredefinedValue("Catalog.RoomTypeClasses.EmptyRef")).Check = True;
			RoomClassesList.Add(PredefinedValue("Catalog.RoomTypeClasses.EmptyRef"), NStr("en='<all room type classes>'; ru='<все классы номеров>'; de='<alle Zimmerklassen>'"));
			Items.RoomTypesList.Enabled = True;
		EndIf;
	EndIf;
EndProcedure // RoomTypesListEndChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomClassesListClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	RoomClassesList.Clear();
	RoomClassesList.Add(PredefinedValue("Catalog.RoomTypeClasses.EmptyRef"), NStr("en='<all room type classes>'; ru='<все классы номеров>'; de='<alle Zimmerklassen>'"));
	For Each vListItem In AllRoomClassesList Do
		vListItem.Check = Not ValueIsFilled(vListItem.Value);
	EndDo;
	Items.RoomTypesList.Enabled = True;
EndProcedure // RoomClassesListClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomRatesListStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	AllRoomRatesList.ShowCheckItems(New NotifyDescription("RoomRatesListEndChoice", ThisObject));
EndProcedure // RoomRatesListStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomRatesListEndChoice(pList, pExtraParams) Export
	If pList <> Undefined Then
		RoomRatesList.Clear();
		vSomethingIsChecked = Undefined;
		For Each vListItem In pList Do
			If Not ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = False;
					RoomRatesList.Add(PredefinedValue("Catalog.RoomRates.EmptyRef"), NStr("en='<all room rates>'; ru='<все тарифы>'; de='<alle Tariffen>'"));
				EndIf;
			ElsIf ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = True;
					RoomRatesList.Add(vListItem.Value, vListItem.Presentation);
				Else
					If vSomethingIsChecked Then
						RoomRatesList.Add(vListItem.Value, vListItem.Presentation);
					Else
						vListItem.Check = False;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vSomethingIsChecked <> Undefined Then
			Items.RoomRateTypesList.Enabled = Not vSomethingIsChecked;
			If vSomethingIsChecked Then
				For Each vAllRoomRateTypesListItem In AllRoomRateTypesList Do
					vAllRoomRateTypesListItem.Check = Not ValueIsFilled(vAllRoomRateTypesListItem.Value);
				EndDo;
				RoomRateTypesList.Clear();
				RoomRateTypesList.Add(PredefinedValue("Catalog.RoomRateTypes.EmptyRef"), NStr("en='<all room rate types>'; ru='<все типы тарифов>'; de='<alle Tarifftypen>'"));
			EndIf;
		Else
			AllRoomRatesList.FindByValue(PredefinedValue("Catalog.RoomRates.EmptyRef")).Check = True;
			RoomRatesList.Add(PredefinedValue("Catalog.RoomRates.EmptyRef"), NStr("en='<all room rates>'; ru='<все тарифы>'; de='<alle Tariffen>'"));
			Items.RoomRateTypesList.Enabled = True;
		EndIf;
	EndIf;
EndProcedure // RoomRatesListEndChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomRatesListClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	RoomRatesList.Clear();
	RoomRatesList.Add(PredefinedValue("Catalog.RoomRates.EmptyRef"), NStr("en='<all room rates>'; ru='<все тарифы>'; de='<alle Tariffen>'"));
	For Each vListItem In AllRoomRatesList Do
		vListItem.Check = Not ValueIsFilled(vListItem.Value);
	EndDo;
	Items.RoomRateTypesList.Enabled = True;
EndProcedure // RoomRatesListClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomRateTypesListStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	AllRoomRateTypesList.ShowCheckItems(New NotifyDescription("RoomRateTypesListEndChoice", ThisObject));
EndProcedure // RoomRateTypesListStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomRateTypesListEndChoice(pList, pExtraParams) Export
	If pList <> Undefined Then
		RoomRateTypesList.Clear();
		vSomethingIsChecked = Undefined;
		For Each vListItem In pList Do
			If Not ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = False;
					RoomRateTypesList.Add(PredefinedValue("Catalog.RoomRateTypes.EmptyRef"), NStr("en='<all room rate types>'; ru='<все типы тарифов>'; de='<alle Tarifftypen>'"));
				EndIf;
			ElsIf ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = True;
					RoomRateTypesList.Add(vListItem.Value, vListItem.Presentation);
				Else
					If vSomethingIsChecked Then
						RoomRateTypesList.Add(vListItem.Value, vListItem.Presentation);
					Else
						vListItem.Check = False;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vSomethingIsChecked <> Undefined Then
			Items.RoomRatesList.Enabled = Not vSomethingIsChecked;
			If vSomethingIsChecked Then
				For Each vAllRoomRatesListItem In AllRoomRatesList Do
					vAllRoomRatesListItem.Check = Not ValueIsFilled(vAllRoomRatesListItem.Value);
				EndDo;
				RoomRatesList.Clear();
				RoomRatesList.Add(PredefinedValue("Catalog.RoomRates.EmptyRef"), NStr("en='<all room rates>'; ru='<все тарифы>'; de='<alle Tariffen>'"));
			EndIf;
		Else
			AllRoomRateTypesList.FindByValue(PredefinedValue("Catalog.RoomRateTypes.EmptyRef")).Check = True;
			RoomRateTypesList.Add(PredefinedValue("Catalog.RoomRateTypes.EmptyRef"), NStr("en='<all room rate types>'; ru='<все типы тарифов>'; de='<alle Tarifftypen>'"));
			Items.RoomRatesList.Enabled = True;
		EndIf;
	EndIf;
EndProcedure // RoomRateTypesListEndChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomRateTypesListClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	RoomRateTypesList.Clear();
	RoomRateTypesList.Add(PredefinedValue("Catalog.RoomRateTypes.EmptyRef"), NStr("en='<all room rate types>'; ru='<все типы тарифов>'; de='<alle Tarifftypen>'"));
	For Each vListItem In AllRoomRateTypesList Do
		vListItem.Check = Not ValueIsFilled(vListItem.Value);
	EndDo;
	Items.RoomRatesList.Enabled = True;
EndProcedure // RoomRateTypesListClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure SourcesOfBusinessListStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	AllSourcesOfBusinessList.ShowCheckItems(New NotifyDescription("SourcesOfBusinessListEndChoice", ThisObject));
EndProcedure // SourcesOfBusinessListStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure SourcesOfBusinessListEndChoice(pList, pExtraParams) Export
	If pList <> Undefined Then
		SourcesOfBusinessList.Clear();
		vSomethingIsChecked = Undefined;
		For Each vListItem In pList Do
			If Not ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = False;
					SourcesOfBusinessList.Add(PredefinedValue("Catalog.SourcesOfBusiness.EmptyRef"), NStr("en='<all sources>'; ru='<все источники>'; de='<alle Quelle>'"));
				EndIf;
			ElsIf ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = True;
					SourcesOfBusinessList.Add(vListItem.Value, vListItem.Presentation);
				Else
					If vSomethingIsChecked Then
						SourcesOfBusinessList.Add(vListItem.Value, vListItem.Presentation);
					Else
						vListItem.Check = False;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vSomethingIsChecked = Undefined Then
			AllSourcesOfBusinessList.FindByValue(PredefinedValue("Catalog.SourcesOfBusiness.EmptyRef")).Check = True;
			SourcesOfBusinessList.Add(PredefinedValue("Catalog.SourcesOfBusiness.EmptyRef"), NStr("en='<all sources>'; ru='<все источники>'; de='<alle Quelle>'"));
		EndIf;
	EndIf;
EndProcedure // SourcesOfBusinessListEndChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure SourcesOfBusinessListClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	SourcesOfBusinessList.Clear();
	SourcesOfBusinessList.Add(PredefinedValue("Catalog.SourcesOfBusiness.EmptyRef"), NStr("en='<all sources>'; ru='<все источники>'; de='<alle Quelle>'"));
	For Each vListItem In AllSourcesOfBusinessList Do
		vListItem.Check = Not ValueIsFilled(vListItem.Value);
	EndDo;
EndProcedure // SourcesOfBusinessListClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure MarketingCodesListStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	AllMarketingCodesList.ShowCheckItems(New NotifyDescription("MarketingCodesListEndChoice", ThisObject));
EndProcedure // MarketingCodesListStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure MarketingCodesListEndChoice(pList, pExtraParams) Export
	If pList <> Undefined Then
		MarketingCodesList.Clear();
		vSomethingIsChecked = Undefined;
		For Each vListItem In pList Do
			If Not ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = False;
					MarketingCodesList.Add(PredefinedValue("Catalog.MarketingCodes.EmptyRef"), NStr("en='<all market codes>'; ru='<все направления маркетинга>'; de='<alle Marktcodes>'"));
				EndIf;
			ElsIf ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = True;
					MarketingCodesList.Add(vListItem.Value, vListItem.Presentation);
				Else
					If vSomethingIsChecked Then
						MarketingCodesList.Add(vListItem.Value, vListItem.Presentation);
					Else
						vListItem.Check = False;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vSomethingIsChecked = Undefined Then
			AllMarketingCodesList.FindByValue(PredefinedValue("Catalog.MarketingCodes.EmptyRef")).Check = True;
			MarketingCodesList.Add(PredefinedValue("Catalog.MarketingCodes.EmptyRef"), NStr("en='<all market codes>'; ru='<все направления маркетинга>'; de='<alle Marktcodes>'"));
		EndIf;
	EndIf;
EndProcedure // MarketingCodesListEndChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure MarketingCodesListClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	MarketingCodesList.Clear();
	MarketingCodesList.Add(PredefinedValue("Catalog.MarketingCodes.EmptyRef"), NStr("en='<all market codes>'; ru='<все направления маркетинга>'; de='<alle Marktcodes>'"));
	For Each vListItem In AllMarketingCodesList Do
		vListItem.Check = Not ValueIsFilled(vListItem.Value);
	EndDo;
EndProcedure // MarketingCodesListClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure TripPurposesListStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	AllTripPurposesList.ShowCheckItems(New NotifyDescription("TripPurposesListEndChoice", ThisObject));
EndProcedure // TripPurposesListStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure TripPurposesListEndChoice(pList, pExtraParams) Export
	If pList <> Undefined Then
		TripPurposesList.Clear();
		vSomethingIsChecked = Undefined;
		For Each vListItem In pList Do
			If Not ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = False;
					TripPurposesList.Add(PredefinedValue("Catalog.TripPurposes.EmptyRef"), NStr("en='<all trip purposes>'; ru='<все цели поездки>'; de='<alle Reisezwecke>'"));
				EndIf;
			ElsIf ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = True;
					TripPurposesList.Add(vListItem.Value, vListItem.Presentation);
				Else
					If vSomethingIsChecked Then
						TripPurposesList.Add(vListItem.Value, vListItem.Presentation);
					Else
						vListItem.Check = False;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vSomethingIsChecked = Undefined Then
			AllTripPurposesList.FindByValue(PredefinedValue("Catalog.TripPurposes.EmptyRef")).Check = True;
			TripPurposesList.Add(PredefinedValue("Catalog.TripPurposes.EmptyRef"), NStr("en='<all trip purposes>'; ru='<все цели поездки>'; de='<alle Reisezwecke>'"));
		EndIf;
	EndIf;
EndProcedure // TripPurposesListEndChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure TripPurposesListClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	TripPurposesList.Clear();
	TripPurposesList.Add(PredefinedValue("Catalog.TripPurposes.EmptyRef"), NStr("en='<all trip purposes>'; ru='<все цели поездки>'; de='<alle Reisezwecke>'"));
	For Each vListItem In AllTripPurposesList Do
		vListItem.Check = Not ValueIsFilled(vListItem.Value);
	EndDo;
EndProcedure // TripPurposesListClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientTypesListStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	AllClientTypesList.ShowCheckItems(New NotifyDescription("ClientTypesListEndChoice", ThisObject));
EndProcedure // ClientTypesListStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientTypesListEndChoice(pList, pExtraParams) Export
	If pList <> Undefined Then
		ClientTypesList.Clear();
		vSomethingIsChecked = Undefined;
		For Each vListItem In pList Do
			If Not ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = False;
					ClientTypesList.Add(PredefinedValue("Catalog.ClientTypes.EmptyRef"), NStr("en='<all client types>'; ru='<все типы клиентов>'; de='<alle Kundetypen>'"));
				EndIf;
			ElsIf ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = True;
					ClientTypesList.Add(vListItem.Value, vListItem.Presentation);
				Else
					If vSomethingIsChecked Then
						ClientTypesList.Add(vListItem.Value, vListItem.Presentation);
					Else
						vListItem.Check = False;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vSomethingIsChecked = Undefined Then
			AllClientTypesList.FindByValue(PredefinedValue("Catalog.ClientTypes.EmptyRef")).Check = True;
			ClientTypesList.Add(PredefinedValue("Catalog.ClientTypes.EmptyRef"), NStr("en='<all client types>'; ru='<все типы клиентов>'; de='<alle Kundetypen>'"));
		EndIf;
	EndIf;
EndProcedure // ClientTypesListEndChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientTypesListClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	ClientTypesList.Clear();
	ClientTypesList.Add(PredefinedValue("Catalog.ClientTypes.EmptyRef"), NStr("en='<all client types>'; ru='<все типы клиентов>'; de='<alle Kundetypen>'"));
	For Each vListItem In AllClientTypesList Do
		vListItem.Check = Not ValueIsFilled(vListItem.Value);
	EndDo;
EndProcedure // ClientTypesListClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure CustomerTypesListStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	AllCustomerTypesList.ShowCheckItems(New NotifyDescription("CustomerTypesListEndChoice", ThisObject));
EndProcedure // CustomerTypesListStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure CustomerTypesListEndChoice(pList, pExtraParams) Export
	If pList <> Undefined Then
		CustomerTypesList.Clear();
		vSomethingIsChecked = Undefined;
		For Each vListItem In pList Do
			If Not ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = False;
					CustomerTypesList.Add(PredefinedValue("Catalog.CustomerTypes.EmptyRef"), NStr("en='<all customer types>'; ru='<все типы контрагентов>'; de='<alle Firmatypen>'"));
				EndIf;
			ElsIf ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = True;
					CustomerTypesList.Add(vListItem.Value, vListItem.Presentation);
				Else
					If vSomethingIsChecked Then
						CustomerTypesList.Add(vListItem.Value, vListItem.Presentation);
					Else
						vListItem.Check = False;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vSomethingIsChecked = Undefined Then
			AllCustomerTypesList.FindByValue(PredefinedValue("Catalog.CustomerTypes.EmptyRef")).Check = True;
			CustomerTypesList.Add(PredefinedValue("Catalog.CustomerTypes.EmptyRef"), NStr("en='<all customer types>'; ru='<все типы контрагентов>'; de='<alle Firmatypen>'"));
		EndIf;
	EndIf;
EndProcedure // CustomerTypesListEndChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure CustomerTypesListClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	CustomerTypesList.Clear();
	CustomerTypesList.Add(PredefinedValue("Catalog.CustomerTypes.EmptyRef"), NStr("en='<all customer types>'; ru='<все типы контрагентов>'; de='<alle Firmatypen>'"));
	For Each vListItem In AllCustomerTypesList Do
		vListItem.Check = Not ValueIsFilled(vListItem.Value);
	EndDo;
EndProcedure // CustomerTypesListClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypesListStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	AllAccommodationTypesList.ShowCheckItems(New NotifyDescription("AccommodationTypesListEndChoice", ThisObject));
EndProcedure // AccommodationTypesListStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypesListEndChoice(pList, pExtraParams) Export
	If pList <> Undefined Then
		AccommodationTypesList.Clear();
		vSomethingIsChecked = Undefined;
		For Each vListItem In pList Do
			If Not ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = False;
					AccommodationTypesList.Add(PredefinedValue("Catalog.AccommodationTypes.EmptyRef"), NStr("en='<all accommodation types>'; ru='<все виды размещений>'; de='<alle Unterkunftstypen>'"));
				EndIf;
			ElsIf ValueIsFilled(vListItem.Value) And vListItem.Check Then
				If vSomethingIsChecked = Undefined Then
					vSomethingIsChecked = True;
					AccommodationTypesList.Add(vListItem.Value, vListItem.Presentation);
				Else
					If vSomethingIsChecked Then
						AccommodationTypesList.Add(vListItem.Value, vListItem.Presentation);
					Else
						vListItem.Check = False;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vSomethingIsChecked = Undefined Then
			AllAccommodationTypesList.FindByValue(PredefinedValue("Catalog.AccommodationTypes.EmptyRef")).Check = True;
			AccommodationTypesList.Add(PredefinedValue("Catalog.AccommodationTypes.EmptyRef"), NStr("en='<all accommodation types>'; ru='<все виды размещений>'; de='<alle Unterkunftstypen>'"));
		EndIf;
	EndIf;
EndProcedure // AccommodationTypesListEndChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypesListClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	AccommodationTypesList.Clear();
	AccommodationTypesList.Add(PredefinedValue("Catalog.AccommodationTypes.EmptyRef"), NStr("en='<all accommodation types>'; ru='<все виды размещения>'; de='<alle Unterkunftstypen>'"));
	For Each vListItem In AllAccommodationTypesList Do
		vListItem.Check = Not ValueIsFilled(vListItem.Value);
	EndDo;
EndProcedure // AccommodationTypesListClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure PromoCodeOnChange(pItem)
	If Not IsBlankString(Object.PromoCode) Then
		Object.PromoCode = Upper(TrimAll(Object.PromoCode));
	EndIf;
	SetFormAttributesAppearance();
	ThisObject.Modified = True;
EndProcedure // PromoCodeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure TeenagersMaxAgeOnChange(pItem)
	SetFormAttributesAppearance();
	ThisObject.Modified = True;
EndProcedure // TeenagersMaxAgeOnChange 

// --------------------------------------------------------------------------------
&AtClient
Procedure ChildrenMaxAgeOnChange(pItem)
	SetFormAttributesAppearance();
	ThisObject.Modified = True;
EndProcedure // ChildrenMaxAgeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure InfantsMaxAgeOnChange(pItem)
	SetFormAttributesAppearance();
	ThisObject.Modified = True;
EndProcedure // InfantsMaxAgeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AddValidityPeriod(pCommand)
	If Not ValueIsFilled(Object.Ref) Then
		If Not ThisObject.Write() Then
			Return;
		EndIf;
	EndIf;
	OpenForm("InformationRegister.SpecialOfferPeriods.RecordForm", New Structure("FillingValues", New Structure("SpecialOffer", Object.Ref)), Object.Ref, Object.Ref);
EndProcedure // AddValidityPeriod

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure SetFormAttributesAppearance(pIsOnOpenMode = False)
	If Not IsBlankString(Object.PromoCode) Or Object.TeenagersMaxAge <> 0 Or Object.ChildrenMaxAge <> 0 Or Object.InfantsMaxAge <> 0 Then
		If Object.TeenagersMaxAge <> 0 Or Object.ChildrenMaxAge <> 0 Or Object.InfantsMaxAge <> 0 Then
			If Not pIsOnOpenMode Then
				RoomTypesList.Clear();
				RoomTypesList.Add(PredefinedValue("Catalog.RoomTypes.EmptyRef"), NStr("en='<all room types>'; ru='<все типы номеров>'; de='<alle Zimmertypen>'"));
				For Each vListItem In AllRoomTypesList Do
					vListItem.Check = Not ValueIsFilled(vListItem.Value);
				EndDo;
				RoomClassesList.Clear();
				RoomClassesList.Add(PredefinedValue("Catalog.RoomTypeClasses.EmptyRef"), NStr("en='<all room type classes>'; ru='<все классы номеров>'; de='<alle Zimmerklassen>'"));
				For Each vListItem In AllRoomClassesList Do
					vListItem.Check = Not ValueIsFilled(vListItem.Value);
				EndDo;
			EndIf;
			If Not Items.RoomTypesList.Enabled Then
				Items.RoomTypesList.Enabled = True;
			EndIf;
			If Not Items.RoomClassesList.Enabled Then
				Items.RoomClassesList.Enabled = True;
			EndIf;
			If Items.GroupRowRoomTypes.Visible Then
				Items.GroupRowRoomTypes.Visible = False;
			EndIf;
		EndIf;
		If Not pIsOnOpenMode Then
			AccommodationTypesList.Clear();
			AccommodationTypesList.Add(PredefinedValue("Catalog.AccommodationTypes.EmptyRef"), NStr("en='<all accommodation types>'; ru='<все виды размещения>'; de='<alle Unterkunftstypen>'"));
			For Each vListItem In AllAccommodationTypesList Do
				vListItem.Check = Not ValueIsFilled(vListItem.Value);
			EndDo;
		EndIf;
		If Items.AccommodationTypesList.Visible Then
			Items.AccommodationTypesList.Visible = False;
		EndIf;
	Else
		If Not Items.GroupRowRoomTypes.Visible Then
			Items.GroupRowRoomTypes.Visible = True;
		EndIf;
		If Not Items.AccommodationTypesList.Visible Then
			Items.AccommodationTypesList.Visible = True;
		EndIf;
	EndIf;
EndProcedure // SetFormAttributesAppearance

// --------------------------------------------------------------------------------
&AtServer
Procedure FillFilterLists()
	RoomTypesList.Clear();
	vAllRoomTypes = cmGetAllRoomTypes(Object.Hotel);
	AllRoomTypesList.Clear();
	AllRoomTypesList.LoadValues(vAllRoomTypes.UnloadColumn("RoomType"));
	AllRoomTypesList.Insert(0, Catalogs.RoomTypes.EmptyRef(), NStr("en='<all room types>'; ru='<все типы номеров>'; de='<alle Zimmertypen>'"));
	
	vAllRoomTypes.GroupBy("RoomClass", );
	RoomClassesList.Clear();
	AllRoomClassesList.Clear();
	AllRoomClassesList.LoadValues(vAllRoomTypes.UnloadColumn("RoomClass"));
	vEmptyRoomClassItem = AllRoomClassesList.FindByValue(Catalogs.RoomTypeClasses.EmptyRef());
	If vEmptyRoomClassItem <> Undefined Then
		AllRoomClassesList.Delete(vEmptyRoomClassItem);
	EndIf;
	AllRoomClassesList.Insert(0, Catalogs.RoomTypeClasses.EmptyRef(), NStr("en='<all room type classes>'; ru='<все классы номеров>'; de='<alle Zimmerklassen>'"));

	AccommodationTypesList.Clear();
	vAllAccommodationTypes = cmGetAllAccommodationTypes(, Object.Hotel);
	AllAccommodationTypesList.Clear();
	AllAccommodationTypesList.LoadValues(vAllAccommodationTypes.UnloadColumn("AccommodationType"));
	AllAccommodationTypesList.Insert(0, Catalogs.AccommodationTypes.EmptyRef(), NStr("en='<all accommodation types>'; ru='<все виды размещений>'; de='<alle Unterkunftstypen>'"));
	
	RoomRatesList.Clear();
	vAllRoomRates = cmGetAllRoomRates(Object.Hotel);
	AllRoomRatesList.Clear();
	AllRoomRatesList.LoadValues(vAllRoomRates.UnloadColumn("RoomRate"));
	AllRoomRatesList.Insert(0, Catalogs.RoomRates.EmptyRef(), NStr("en='<all room rates>'; ru='<все тарифы>'; de='<alle Tariffen>'"));
	
	vAllRoomRates.GroupBy("RoomRateType", );
	RoomRateTypesList.Clear();
	AllRoomRateTypesList.Clear();
	AllRoomRateTypesList.LoadValues(vAllRoomRates.UnloadColumn("RoomRateType"));
	vEmptyRoomRateTypeItem = AllRoomRateTypesList.FindByValue(Catalogs.RoomRateTypes.EmptyRef());
	If vEmptyRoomRateTypeItem <> Undefined Then
		AllRoomRateTypesList.Delete(vEmptyRoomRateTypeItem);
	EndIf;
	AllRoomRateTypesList.Insert(0, Catalogs.RoomRateTypes.EmptyRef(), NStr("en='<all room rate types>'; ru='<все типы тарифов>'; de='<alle Tarifftypen>'"));
	
	SourcesOfBusinessList.Clear();
	vAllSources = cmGetAllSourcesOfBusiness();
	AllSourcesOfBusinessList.Clear();
	AllSourcesOfBusinessList.LoadValues(vAllSources.UnloadColumn("SourceOfBusiness"));
	AllSourcesOfBusinessList.Insert(0, Catalogs.SourcesOfBusiness.EmptyRef(), NStr("en='<all sources>'; ru='<все источники>'; de='<alle Quelle>'"));
	
	MarketingCodesList.Clear();
	vAllMarketCodes = cmGetAllMarketingCodes(Object.Hotel);
	AllMarketingCodesList.Clear();
	AllMarketingCodesList.LoadValues(vAllMarketCodes.UnloadColumn("MarketingCode"));
	AllMarketingCodesList.Insert(0, Catalogs.MarketingCodes.EmptyRef(), NStr("en='<all market codes>'; ru='<все направления маркетинга>'; de='<alle Marktcodes>'"));
	
	ClientTypesList.Clear();
	vAllClientTypes = cmGetAllClientTypes(Object.Hotel);
	AllClientTypesList.Clear();
	AllClientTypesList.LoadValues(vAllClientTypes.UnloadColumn("ClientType"));
	AllClientTypesList.Insert(0, Catalogs.ClientTypes.EmptyRef(), NStr("en='<all client types>'; ru='<все типы клиентов>'; de='<alle Kundetypen>'"));
	
	CustomerTypesList.Clear();
	vAllCustomerTypes = cmGetAllCustomerTypes();
	AllCustomerTypesList.Clear();
	AllCustomerTypesList.LoadValues(vAllCustomerTypes.UnloadColumn("CustomerType"));
	AllCustomerTypesList.Insert(0, Catalogs.CustomerTypes.EmptyRef(), NStr("en='<all customer types>'; ru='<все типы контрагентов>'; de='<alle Firmatypen>'"));
	
	TripPurposesList.Clear();
	vAllTripPurposes = cmGetAllTripPurposes();
	AllTripPurposesList.Clear();
	AllTripPurposesList.LoadValues(vAllTripPurposes.UnloadColumn("TripPurpose"));
	AllTripPurposesList.Insert(0, Catalogs.TripPurposes.EmptyRef(), NStr("en='<all trip purposes>'; ru='<все цели поездки>'; de='<alle Reisezwecke>'"));
	
	// Load settings for room types and room type classes
	vRoomTypesFiltered = False;
	vRoomClassesFiltered = False;
	vAccommodationTypesFiltered = False;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SpecialOffersForRoomTypes.RoomType AS RoomType,
	|	SpecialOffersForRoomTypes.RoomClass AS RoomClass,
	|	SpecialOffersForRoomTypes.AccommodationType AS AccommodationType
	|FROM
	|	InformationRegister.SpecialOffersForRoomTypes AS SpecialOffersForRoomTypes
	|WHERE
	|	SpecialOffersForRoomTypes.SpecialOffer = &qSpecialOffer
	|	AND &qSpecialOffer <> VALUE(Catalog.SpecialOffers.EmptyRef)
	|
	|ORDER BY
	|	SpecialOffersForRoomTypes.RoomType.SortCode,
	|	SpecialOffersForRoomTypes.RoomClass.SortCode,
	|	SpecialOffersForRoomTypes.RoomClass.Code";
	vQry.SetParameter("qSpecialOffer", Object.Ref);
	vSettings = vQry.Execute().Unload();
	For Each vSettingsRow In vSettings Do
		If ValueIsFilled(vSettingsRow.RoomType) Then
			If RoomTypesList.FindByValue(vSettingsRow.RoomType) = Undefined Then
				RoomTypesList.Add(vSettingsRow.RoomType);
			EndIf;
			vAllRoomTypesListItem = AllRoomTypesList.FindByValue(vSettingsRow.RoomType);
			If vAllRoomTypesListItem = Undefined Then
				vAllRoomTypesListItem = AllRoomTypesList.Add(vSettingsRow.RoomType);
			EndIf;
			vAllRoomTypesListItem.Check = True;
			vRoomTypesFiltered = True;
		EndIf;
		If ValueIsFilled(vSettingsRow.RoomClass) Then
			If RoomClassesList.FindByValue(vSettingsRow.RoomClass) = Undefined Then
				RoomClassesList.Add(vSettingsRow.RoomClass);
			EndIf;
			vAllRoomClassesListItem = AllRoomClassesList.FindByValue(vSettingsRow.RoomClass);
			If vAllRoomClassesListItem = Undefined Then
				vAllRoomClassesListItem = AllRoomClassesList.Add(vSettingsRow.RoomClass);
			EndIf;
			vAllRoomClassesListItem.Check = True;
			vRoomClassesFiltered = True;
		EndIf;
		If ValueIsFilled(vSettingsRow.AccommodationType) Then
			If AccommodationTypesList.FindByValue(vSettingsRow.AccommodationType) = Undefined Then
				AccommodationTypesList.Add(vSettingsRow.AccommodationType);
			EndIf;
			vAllAccommodationTypesListItem = AllAccommodationTypesList.FindByValue(vSettingsRow.AccommodationType);
			If vAllAccommodationTypesListItem = Undefined Then
				vAllAccommodationTypesListItem = AllAccommodationTypesList.Add(vSettingsRow.AccommodationType);
			EndIf;
			vAllAccommodationTypesListItem.Check = True;
			vAccommodationTypesFiltered = True;
		EndIf;
	EndDo;
	AllRoomTypesList.Get(0).Check = Not vRoomTypesFiltered;
	AllRoomClassesList.Get(0).Check = Not vRoomClassesFiltered;
	AllAccommodationtypesList.Get(0).Check = Not vAccommodationTypesFiltered;
	If Not vRoomTypesFiltered Then
		RoomTypesList.Insert(0, Catalogs.RoomTypes.EmptyRef(), NStr("en='<all room types>'; ru='<все типы номеров>'; de='<alle Zimmertypen>'"));
	ElsIf Not vRoomClassesFiltered Then
		Items.RoomClassesList.Enabled = False;
	EndIf;
	If Not vRoomClassesFiltered Then
		RoomClassesList.Insert(0, Catalogs.RoomTypeClasses.EmptyRef(), NStr("en='<all room type classes>'; ru='<все классы номеров>'; de='<alle Zimmerklassen>'"));
	ElsIf Not vRoomTypesFiltered Then
		Items.RoomTypesList.Enabled = False;
	EndIf;
	If Not vAccommodationTypesFiltered Then
		AccommodationTypesList.Insert(0, Catalogs.AccommodationTypes.EmptyRef(), NStr("en='<all accommodation types>'; ru='<все виды размещений>'; de='<alle Unterkunftstypen>'"));
	EndIf;
	
	// Load settings for room rates, sources and so on
	vRoomRatesFiltered = False;
	vRoomRateTypesFiltered = False;
	vSourcesOfBusinessFiltered = False;
	vMarketingCodesFiltered = False;
	vTripPurposesFiltered = False;
	vClientTypesFiltered = False;
	vCustomerTypesFiltered = False;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SpecialOffersForRoomRates.RoomRate AS RoomRate,
	|	SpecialOffersForRoomRates.RoomRateType AS RoomRateType,
	|	SpecialOffersForRoomRates.SourceOfBusiness AS SourceOfBusiness,
	|	SpecialOffersForRoomRates.MarketingCode AS MarketingCode,
	|	SpecialOffersForRoomRates.TripPurpose AS TripPurpose,
	|	SpecialOffersForRoomRates.ClientType AS ClientType,
	|	SpecialOffersForRoomRates.CustomerType AS CustomerType,
	|	SpecialOffersForRoomRates.MLOS AS MLOS,
	|	SpecialOffersForRoomRates.MaxLOS AS MaxLOS,
	|	SpecialOffersForRoomRates.MinDaysBeforeCheckIn AS MinDaysBeforeCheckIn,
	|	SpecialOffersForRoomRates.MaxDaysBeforeCheckIn AS MaxDaysBeforeCheckIn
	|FROM
	|	InformationRegister.SpecialOffersForRates AS SpecialOffersForRoomRates
	|WHERE
	|	SpecialOffersForRoomRates.SpecialOffer = &qSpecialOffer
	|	AND &qSpecialOffer <> VALUE(Catalog.SpecialOffers.EmptyRef)
	|
	|ORDER BY
	|	SpecialOffersForRoomRates.RoomRate.SortCode,
	|	SpecialOffersForRoomRates.RoomRate.Description,
	|	SpecialOffersForRoomRates.RoomRateType.SortCode,
	|	SpecialOffersForRoomRates.RoomRateType.Description,
	|	SpecialOffersForRoomRates.SourceOfBusiness.SortCode,
	|	SpecialOffersForRoomRates.SourceOfBusiness.Description,
	|	SpecialOffersForRoomRates.MarketingCode.SortCode,
	|	SpecialOffersForRoomRates.MarketingCode.Description,
	|	SpecialOffersForRoomRates.TripPurpose.SortCode,
	|	SpecialOffersForRoomRates.TripPurpose.Description,
	|	SpecialOffersForRoomRates.ClientType.SortCode,
	|	SpecialOffersForRoomRates.ClientType.Description,
	|	SpecialOffersForRoomRates.CustomerType.SortCode,
	|	SpecialOffersForRoomRates.CustomerType.Description";
	vQry.SetParameter("qSpecialOffer", Object.Ref);
	vSettings = vQry.Execute().Unload();
	For Each vSettingsRow In vSettings Do
		If ValueIsFilled(vSettingsRow.RoomRate) Then
			If RoomRatesList.FindByValue(vSettingsRow.RoomRate) = Undefined Then
				RoomRatesList.Add(vSettingsRow.RoomRate);
			EndIf;
			vAllRoomRatesListItem = AllRoomRatesList.FindByValue(vSettingsRow.RoomRate);
			If vAllRoomRatesListItem = Undefined Then
				vAllRoomRatesListItem = AllRoomRatesList.Add(vSettingsRow.RoomRate);
			EndIf;
			vAllRoomRatesListItem.Check = True;
			vRoomRatesFiltered = True;
		EndIf;
		If ValueIsFilled(vSettingsRow.RoomRateType) Then
			If RoomRateTypesList.FindByValue(vSettingsRow.RoomRateType) = Undefined Then
				RoomRateTypesList.Add(vSettingsRow.RoomRateType);
			EndIf;
			vAllRoomRateTypesListItem = AllRoomRateTypesList.FindByValue(vSettingsRow.RoomRateType);
			If vAllRoomRateTypesListItem = Undefined Then
				vAllRoomRateTypesListItem = AllRoomRateTypesList.Add(vSettingsRow.RoomRateType);
			EndIf;
			vAllRoomRateTypesListItem.Check = True;
			vRoomRateTypesFiltered = True;
		EndIf;
		If ValueIsFilled(vSettingsRow.SourceOfBusiness) Then
			If SourcesOfBusinessList.FindByValue(vSettingsRow.SourceOfBusiness) = Undefined Then
				SourcesOfBusinessList.Add(vSettingsRow.SourceOfBusiness);
			EndIf;
			vAllSourcesOfBusinessListItem = AllSourcesOfBusinessList.FindByValue(vSettingsRow.SourceOfBusiness);
			If vAllSourcesOfBusinessListItem = Undefined Then
				vAllSourcesOfBusinessListItem = AllSourcesOfBusinessList.Add(vSettingsRow.SourceOfBusiness);
			EndIf;
			vAllSourcesOfBusinessListItem.Check = True;
			vSourcesOfBusinessFiltered = True;
		EndIf;
		If ValueIsFilled(vSettingsRow.MarketingCode) Then
			If MarketingCodesList.FindByValue(vSettingsRow.MarketingCode) = Undefined Then
				MarketingCodesList.Add(vSettingsRow.MarketingCode);
			EndIf;
			vAllMarketingCodesListItem = AllMarketingCodesList.FindByValue(vSettingsRow.MarketingCode);
			If vAllMarketingCodesListItem = Undefined Then
				vAllMarketingCodesListItem = AllMarketingCodesList.Add(vSettingsRow.MarketingCode);
			EndIf;
			vAllMarketingCodesListItem.Check = True;
			vMarketingCodesFiltered = True;
		EndIf;
		If ValueIsFilled(vSettingsRow.TripPurpose) Then
			If TripPurposesList.FindByValue(vSettingsRow.TripPurpose) = Undefined Then
				TripPurposesList.Add(vSettingsRow.TripPurpose);
			EndIf;
			vAllTripPurposesListItem = AllTripPurposesList.FindByValue(vSettingsRow.TripPurpose);
			If vAllTripPurposesListItem = Undefined Then
				vAllTripPurposesListItem = AllTripPurposesList.Add(vSettingsRow.TripPurpose);
			EndIf;
			vAllTripPurposesListItem.Check = True;
			vTripPurposesFiltered = True;
		EndIf;
		If ValueIsFilled(vSettingsRow.ClientType) Then
			If ClientTypesList.FindByValue(vSettingsRow.ClientType) = Undefined Then
				ClientTypesList.Add(vSettingsRow.ClientType);
			EndIf;
			vAllClientTypesListItem = AllClientTypesList.FindByValue(vSettingsRow.ClientType);
			If vAllClientTypesListItem = Undefined Then
				vAllClientTypesListItem = AllClientTypesList.Add(vSettingsRow.ClientType);
			EndIf;
			vAllClientTypesListItem.Check = True;
			vClientTypesFiltered = True;
		EndIf;
		If ValueIsFilled(vSettingsRow.CustomerType) Then
			If CustomerTypesList.FindByValue(vSettingsRow.CustomerType) = Undefined Then
				CustomerTypesList.Add(vSettingsRow.CustomerType);
			EndIf;
			vAllCustomerTypesListItem = AllCustomerTypesList.FindByValue(vSettingsRow.CustomerType);
			If vAllCustomerTypesListItem = Undefined Then
				vAllCustomerTypesListItem = AllCustomerTypesList.Add(vSettingsRow.CustomerType);
			EndIf;
			vAllCustomerTypesListItem.Check = True;
			vCustomerTypesFiltered = True;
		EndIf;
		If vSettingsRow.MLOS > 0 Then
			MLOS = vSettingsRow.MLOS;
		EndIf;
		If vSettingsRow.MaxLOS > 0 Then
			MaxLOS = vSettingsRow.MaxLOS;
		EndIf;
		If vSettingsRow.MinDaysBeforeCheckIn > 0 Then
			MinDaysBeforeCheckIn = vSettingsRow.MinDaysBeforeCheckIn;
		EndIf;
		If vSettingsRow.MaxDaysBeforeCheckIn > 0 Then
			MaxDaysBeforeCheckIn = vSettingsRow.MaxDaysBeforeCheckIn;
		EndIf;
	EndDo;
	AllRoomRatesList.Get(0).Check = Not vRoomRatesFiltered;
	AllRoomRateTypesList.Get(0).Check = Not vRoomRateTypesFiltered;
	AllSourcesOfBusinessList.Get(0).Check = Not vSourcesOfBusinessFiltered;
	AllMarketingCodesList.Get(0).Check = Not vMarketingCodesFiltered;
	AllTripPurposesList.Get(0).Check = Not vTripPurposesFiltered;
	AllClientTypesList.Get(0).Check = Not vClientTypesFiltered;
	AllCustomerTypesList.Get(0).Check = Not vCustomerTypesFiltered;
	If Not vRoomRatesFiltered Then
		RoomRatesList.Insert(0, Catalogs.RoomRates.EmptyRef(), NStr("en='<all room rates>'; ru='<все тарифы>'; de='<alle Tariffen>'"));
	ElsIf Not vRoomRateTypesFiltered Then
		Items.RoomRateTypesList.Enabled = False;
	EndIf;
	If Not vRoomRateTypesFiltered Then
		RoomRateTypesList.Insert(0, Catalogs.RoomRateTypes.EmptyRef(), NStr("en='<all room rate types>'; ru='<все типы тарифов>'; de='<alle Tarifftypen>'"));
	ElsIf Not vRoomRatesFiltered Then
		Items.RoomRatesList.Enabled = False;
	EndIf;
	If Not vSourcesOfBusinessFiltered Then
		SourcesOfBusinessList.Insert(0, Catalogs.SourcesOfBusiness.EmptyRef(), NStr("en='<all sources>'; ru='<все источники>'; de='<alle Quelle>'"));
	EndIf;
	If Not vMarketingCodesFiltered Then
		MarketingCodesList.Insert(0, Catalogs.MarketingCodes.EmptyRef(), NStr("en='<all market codes>'; ru='<все направления маркетинга>'; de='<alle Marktcodes>'"));
	EndIf;
	If Not vClientTypesFiltered Then
		ClientTypesList.Insert(0, Catalogs.ClientTypes.EmptyRef(), NStr("en='<all client types>'; ru='<все типы клиентов>'; de='<alle Kundetypen>'"));
	EndIf;
	If Not vCustomerTypesFiltered Then
		CustomerTypesList.Insert(0, Catalogs.CustomerTypes.EmptyRef(), NStr("en='<all customer types>'; ru='<все типы контрагентов>'; de='<alle Firmatypen>'"));
	EndIf;
	If Not vTripPurposesFiltered Then
		TripPurposesList.Insert(0, Catalogs.TripPurposes.EmptyRef(), NStr("en='<all trip purposes>'; ru='<все цели поездки>'; de='<alle Reisezwecke>'"));
	EndIf;
EndProcedure // FillFilterLists

// --------------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()
	If ValueIsFilled(Object.Hotel) Then
		If Not ValueIsFilled(Object.Currency) Then
			Object.Currency = Object.Hotel.BaseCurrency;
		EndIf;
	EndIf;
	FillFilterLists();
EndProcedure // HotelOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ApplyAutomaticallyOnChange(pItem)
	Items.DecorationManualBindTooltip.Visible = Not Object.ApplyAutomatically;
	Items.DecorationOfferTypeBindToReservation.Visible = Not Object.ApplyAutomatically;
	Items.DecorationOfferTypeBindToClient.Visible = Not Object.ApplyAutomatically;
	Items.DecorationOfferTypeAutomatically.Visible = Object.ApplyAutomatically;	
EndProcedure

#EndRegion
