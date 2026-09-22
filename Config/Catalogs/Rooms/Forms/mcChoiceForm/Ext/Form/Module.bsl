#Region FormEventHandlers

// -------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Hotel") Then
		Hotel = Parameters.Hotel;
	EndIf;
	SelRoomProperties = cmGetAllRoomProperties(Undefined, Hotel, True); 
	If Parameters.Property("SelRoomProperties") Then
		For Each vRP In Parameters.SelRoomProperties Do
			If ValueIsFilled(vRP.Value) Then
				vRPItem = SelRoomProperties.FindByValue(vRP.Value);
				If vRPItem <> Undefined Then
					vRPItem.Check = True;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Parameters.Property("DateFrom") Then
		DateFrom = cm1SecondShift(Parameters.DateFrom);
	Else
		DateFrom = CurrentSessionDate();
	EndIf;
	If Parameters.Property("DateTo") Then
		DateTo = cm0SecondShift(Parameters.DateTo);
	Else
		DateTo = cmCalculateCheckOutDate(Hotel.RoomRate, DateFrom, 1);
	EndIf;
	If Parameters.Property("RoomType") Then
		SelRoomType = Parameters.RoomType;
	EndIf;
	If Parameters.Property("RoomQuota") Then
		If ValueIsFilled(Parameters.RoomQuota) And Parameters.RoomQuota.IsQuotaForRooms Then
			SelRoomQuota = Parameters.RoomQuota;
		EndIf;
	EndIf;
	If Parameters.Property("Room") Then
		SelRoom = Parameters.Room;
	EndIf;
	If Parameters.Property("IsOpenedFromReservation") Then
		SelIsOpenedFromReservation = Parameters.IsOpenedFromReservation;
	EndIf;	
	If Parameters.Property("NumberOfBeds") Then
		SelNumberOfBeds = Parameters.NumberOfBeds;
	EndIf;	
	If Parameters.Property("NumberOfRooms") Then
		SelNumberOfRooms = Parameters.NumberOfRooms;
	EndIf;
	If Parameters.Property("Company") Then
		Company = Parameters.Company;
	EndIf;
	RoomPropertiesPresentation = GetRoomPropertiesPresentation();
	OnOpenForm();
	PutData();	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -------------------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceRoomStsCode(pItem, pExtraParams) Export 
	If pItem <> Undefined Then
		Items.FormChoiceRoomStsCode.Title = pItem.Presentation;
		Items.FormChoiceRoomStsCode.Picture = pItem.Picture;
		RoomStsCode = pItem.Value; 
		PutData();	
	EndIf;
EndProcedure // AfterChoiceRoomStsCode

// -------------------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(pItem, pEditText = "") Export
	PutData();
EndProcedure // RoomTypeOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure TableBoxRoomsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If pItem.CurrentData <> Undefined Then
		If ValueIsFilled(pItem.CurrentData.RoomType) Then
			If pSelectedRow <> Undefined Then	
				vRef = pItem.CurrentData.Room;
				If ThisForm.FormOwner <> Undefined Then
					NotifyChoice(vRef);
				Else
					OpenForm("Catalog.Rooms.Form.tcHousekeepingItemForm", New Structure("Key", vRef), , vRef);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // TableBoxRoomsSelection

// -------------------------------------------------------------------------------------
&AtClient
Procedure TableBoxRoomsValueChoice(pItem, pValue, pStandardProcessing)
	pStandardProcessing = False;
	If ThisForm.FormOwner<>Undefined Then
		If pItem.CurrentData <> Undefined Then
			If ValueIsFilled(pItem.CurrentData.RoomType) Then
				vRef = pItem.CurrentData.Room;
				NotifyChoice(vRef);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // TableBoxRoomsValueChoice

// -------------------------------------------------------------------------------------
&AtClient
Procedure DateFromOnChange(pItem)
	If ValueIsFilled(DateFrom) Then
		If (DateFrom - BegOfDay(DateFrom)) = 0 Then
			vRoomRate = Undefined;
			If Not ValueIsFilled(vRoomRate) And ValueIsFilled(Hotel) Then
				vRoomRate = tcOnServer.cmGetAttributeByRef(Hotel, "RoomRate");
			EndIf;
			If ValueIsFilled(vRoomRate) Then
				vReferenceHour = tcOnServer.cmGetAttributeByRef(vRoomRate, "ReferenceHour");
				vDefaultCheckInTime = tcOnServer.cmGetAttributeByRef(vRoomRate, "DefaultCheckInTime");
				If ValueIsFilled(vDefaultCheckInTime) Then
					DateFrom = DateFrom + (vDefaultCheckInTime - BegOfDay(vDefaultCheckInTime));
				ElsIf ValueIsFilled(vReferenceHour) Then
					DateFrom = DateFrom + (vReferenceHour - BegOfDay(vReferenceHour));
				EndIf;
			EndIf;
		EndIf;
		If Second(DateFrom) = 0 Then
			DateFrom = DateFrom + 1;
		EndIf;
	EndIf;
	If ValueIsFilled(DateTo) Then
		If DateTo < DateFrom Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Check-in date is later then check-out date!';ru='Дата заезда указана позже даты выезда!';de='Das Anreisedatum ist nach dem Abreisedatum angegeben!'"));
		Else
			// Use filter
			PutData();
		EndIf;
	EndIf;	
EndProcedure // DateFromOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure DateToOnChange(pItem)
	If ValueIsFilled(DateTo) Then
		If (DateTo - BegOfDay(DateTo)) = 0 Then
			vRoomRate = Undefined;
			If Not ValueIsFilled(vRoomRate) And ValueIsFilled(Hotel) Then
				vRoomRate = tcOnServer.cmGetAttributeByRef(Hotel, "RoomRate");
			EndIf;
			If ValueIsFilled(vRoomRate) Then
				vReferenceHour = tcOnServer.cmGetAttributeByRef(vRoomRate, "ReferenceHour");
				If ValueIsFilled(vReferenceHour) Then
					DateTo = DateTo + (vReferenceHour - BegOfDay(vReferenceHour));
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(DateFrom) Then
		If DateTo<DateFrom Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Check-in date is later then check-out date!';ru='Дата заезда указана позже даты выезда!';de='Das Anreisedatum ist nach dem Abreisedatum angegeben!'"));
		Else
			// Use filter
			PutData();
		EndIf;
	EndIf;	
EndProcedure // DateToOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure RoomQuotaOnChange(pItem)
	PutData();
EndProcedure // RoomQuotaOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	PutData();
EndProcedure // HotelOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	PutData();
EndProcedure // CompanyOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vRoomPropertiesList = FillRoomPropertiesList();
	vNotifyDescription = New NotifyDescription("RoomPropertiesPresentationStartChoice_AfterInput", ThisForm);
	vParams = New Structure("ValueList, MultipleChoice, Title", vRoomPropertiesList, True, NStr("en='Check room properties...'; ru='Отметьте свойства номеров...'; de='Markieren Zimmereigenschaften...'"));
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
EndProcedure // RoomPropertiesPresentationStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -------------------------------------------------------------------------------------
&AtClient
Procedure ChoiceRoomStsCode(pCommand)
	vNotifyDescription = New NotifyDescription("AfterChoiceRoomStsCode", ThisForm);
	vParams = New Structure("ValueList, MultipleChoice, Title", ListRoomStsCode, False, NStr("en = 'Statuses'; de = 'Status'; ru = 'Статусы'"));
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
EndProcedure // ChoiceRoomStsCode

// -------------------------------------------------------------------------------------
&AtClient
Procedure ShowAllRooms(pCommand)
	SelNumberOfBeds = 0;
	SelNumberOfRooms = 0;
	PutData();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowFiletGroup(pCommand)
	Items.ShowFiletGroup.Check = Not Items.ShowFiletGroup.Check;
	If Items.ShowFiletGroup.Check Then
		Items.Pages.CurrentPage = Items.PageFilter;
	Else
		Items.Pages.CurrentPage = Items.PageMain;	
	Endif;
EndProcedure // ShowFiletGroup

#EndRegion

#Region Private

// -------------------------------------------------------------------------------------
&AtServer
Procedure OnOpenForm()
	vVacantRoomStatus = Undefined;
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.VacantRoomStatus) Then
		vVacantRoomStatus = Hotel.VacantRoomStatus;
	EndIf;
	RoomStsCode = "Any";
	vRoomStses = GetAllRoomStatuses();
	
	ListRoomStsCode.Clear();
	ListRoomStsCode.Add("Any", NStr("en = 'Any'; de = 'Beliebig'; ru = 'Любой'"));  
	vItem = ListRoomStsCode.FindByValue("Any");
	If vItem <> Undefined Then
		Items.FormChoiceRoomStsCode.Title = vItem.Presentation;
		Items.FormChoiceRoomStsCode.Picture = vItem.Picture;
	EndIf;

	For Each vRoomSts In vRoomStses Do
		vRoomStsesCode = cmGetValidName(TrimAll(vRoomSts.Code));
		ListRoomStsCode.Add(vRoomStsesCode, TrimAll(vRoomSts.Description), , tcOnServer.cmGetRoomStatusIconOnServer(vRoomSts.RoomStatus));		
		vNewRow = TempRoomSts.Add();
		vNewRow.RoomStsCode = vRoomStsesCode;
		vNewRow.Value = vRoomSts.RoomStatus;
		If vVacantRoomStatus = vRoomSts.RoomStatus Then
			If Not SelIsOpenedFromReservation Then
				If BegOfDay(ThisForm.DateFrom) = BegOfDay(CurrentSessionDate()) Then
					RoomStsCode = vRoomStsesCode;
					vItem = ListRoomStsCode.FindByValue(vRoomStsesCode);
					If vItem <> Undefined Then
						Items.FormChoiceRoomStsCode.Title = vItem.Presentation;
						Items.FormChoiceRoomStsCode.Picture = vItem.Picture;
					EndIf;
				EndIf;
			EndIf;
		EndIf;

	EndDo;
	If Not ValueIsFilled(DateFrom) Or Not ValueIsFilled(DateTo) Then
		DateFrom = CurrentSessionDate();
		DateTo = CurrentSessionDate()+86400;
	EndIf;
EndProcedure // OnOpenForm

// -------------------------------------------------------------------------------------
&AtServer
Function GetAllRoomStatuses()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomStatuses.Ref AS RoomStatus,
	|	RoomStatuses.Code AS Code,
	|	RoomStatuses.RoomStatusIcon AS RoomStatusIcon,
	|	RoomStatuses.Description AS Description,
	|	RoomStatuses.SortCode AS SortCode
	|FROM
	|	Catalog.RoomStatuses AS RoomStatuses
	|WHERE
	|	RoomStatuses.DeletionMark = FALSE
	|	AND RoomStatuses.IsFolder = FALSE
	|	AND (RoomStatuses.Hotel = &qHotel
	|			OR RoomStatuses.Hotel = &qEmptyHotel)
	|	AND NOT RoomStatuses.CheckInIsForbidden
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // GetAllRoomStatuses

// -------------------------------------------------------------------------------------
&AtServer
Procedure PutData()
	vRoomStses = GetAllRoomStatuses();

	TableBoxRooms.GetItems().Clear();
	Items.TableBoxRoomsVacantFrom.Title = NStr("en='Vacant from ';ru='Свободен с ';de='Frei ab '")+Format(DateFrom, "DF='dd.MM.yyyy HH:mm'");
	Items.TableBoxRoomsVacantTo.Title = NStr("en='Vacant to ';ru='Свободен по ';de='Frei bis '")+Format(DateTo, "DF='dd.MM.yyyy HH:mm'");
	
	// Initialize working vars
	vInBeds = True;
	vTotalVacant = 0;
	vTotalAvailable = 0;
	vUnit = "";
	If SelNumberOfRooms = 0 And SelNumberOfBeds = 0 Then
		If ValueIsFilled(Hotel) Then
			vInBeds = Hotel.ShowReportsInBeds;
		EndIf;
	Else
		If SelNumberOfRooms <> 0 Then
			vInBeds = False;
		EndIf;
	EndIf;
	If vInBeds Then
		vUnit = NStr("en='Beds';ru='Мест';de='Betten'");
	Else
		vUnit = NStr("en='Rooms';ru='Номеров';de='Zimmer'");
	EndIf;
	
	// Check if room status is selected
	vRoomStatus = Undefined;
	vCurPageValue = TempRoomSts.FindRows(New Structure("RoomStsCode", RoomStsCode));
	If vCurPageValue.Count()>0 Then
		If ValueIsFilled(vCurPageValue.Get(0).Value) Then
			vRoomStatus = vCurPageValue.Get(0).Value;
		EndIf;
	EndIf;
	// Initialize working arrays
	vRoomsArray = New Array();
	vRoomPropArray = New Array();
	
	// Clear resulting table
	TableBoxRooms.GetItems().Clear();
	
	// Run query to get rooms in room quota if filled
	vAllotmentByRooms = False;
	vRoomsInQuota = New ValueList();
	If ValueIsFilled(SelRoomQuota) Then
		If Not SelRoomQuota.DeletionMark And SelRoomQuota.IsQuotaForRooms Then
			vAllotmentByRooms = True;
			vQry = New Query();
			vQry.Text = "SELECT
			|	RoomQuotaSales.Room,
			|	RoomQuotaSales.RoomType,
			|	MIN(RoomQuotaSales.CounterClosingBalance) AS CounterClosingBalance,
			|	MIN(RoomQuotaSales.RoomsInQuotaClosingBalance) AS RoomsInQuotaClosingBalance,
			|	MIN(RoomQuotaSales.BedsInQuotaClosingBalance) AS BedsInQuotaClosingBalance
			|FROM
			|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
			|			&qDateFrom,
			|			&qDateTo,
			|			Minute,
			|			RegisterRecordsAndPeriodBoundaries, " + 
			?(ValueIsFilled(Hotel), "Hotel IN HIERARCHY (&qHotel)", "TRUE") + 
			?(ValueIsFilled(SelRoomType), " AND RoomType IN HIERARCHY (&qRoomType)", "") + "
			|				AND RoomQuota IN HIERARCHY (&qRoomQuota)) AS RoomQuotaSales
			|WHERE " + 
			?(ValueIsFilled(Company), " (RoomQuotaSales.RoomType.Company = &qCompany) OR (RoomQuotaSales.Room.Company = &qCompany) OR (RoomQuotaSales.RoomType.Company = &qEmptyCompany AND RoomQuotaSales.Room.Company = &qEmptyCompany)", "TRUE") + "
			|
			|GROUP BY
			|	RoomQuotaSales.Room,
			|	RoomQuotaSales.RoomType
			|
			|ORDER BY
			|	RoomQuotaSales.Room.SortCode";
			vQry.SetParameter("qRoomQuota", SelRoomQuota);
			vQry.SetParameter("qHotel", Hotel);
			vQry.SetParameter("qRoomType", SelRoomType);
			vQry.SetParameter("qDateFrom", DateFrom);
			vQry.SetParameter("qDateTo", New Boundary(DateTo, BoundaryType.Excluding));
			vQry.SetParameter("qCompany", Company);
			vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
			vQryResults = vQry.Execute().Unload();
			For Each vQryResultsRow In vQryResults Do
				vRoomsInQuota.Add(vQryResultsRow.Room);
			EndDo;
		EndIf;
	EndIf;
	
	// Run query to get number of vacant rooms for room types
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomTypes.RoomType AS RoomType,
	|	RoomTypes.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomTypes.BedsVacant AS BedsVacant,
	|	RoomTypes.RoomsVacant AS RoomsVacant,
	|	RoomTypes.RoomType.Company AS Company
	|
	|FROM(
	|	SELECT
	|		RoomTypesBalance.RoomType AS RoomType,
	|		MAX(RoomTypesBalance.TotalBeds) AS TotalBeds,
	|		MAX(RoomTypesBalance.TotalRooms) AS TotalRooms,
	|		MAX(RoomTypesBalance.BedsVacant) AS BedsVacant,
	|		MAX(RoomTypesBalance.RoomsVacant) AS RoomsVacant
	|	FROM (
	|		SELECT
	|			RoomInventoryBalance.RoomType AS RoomType,
	|			MIN(RoomInventoryBalance.CounterClosingBalance) AS CounterClosingBalance,
	|			MIN(RoomInventoryBalance.TotalBedsClosingBalance) AS TotalBeds,
	|			MIN(RoomInventoryBalance.TotalRoomsClosingBalance) AS TotalRooms,
	|			MIN(RoomInventoryBalance.BedsVacantClosingBalance) AS BedsVacant,
	|			MIN(RoomInventoryBalance.RoomsVacantClosingBalance) AS RoomsVacant
	|		FROM
	|			AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qDateFrom, &qDateTo, 
	|		    	                                                   Second, 
	|		        	                                               RegisterRecordsAndPeriodBoundaries, " +
	?(ValueIsFilled(Hotel), "Hotel IN HIERARCHY (&qHotel)", "TRUE") + 
	?(ValueIsFilled(SelRoomType), " AND RoomType IN HIERARCHY (&qRoomType)", "") + 
	?(vAllotmentByRooms, " AND Room IN (&qRoomsInQuota)", "") + "
	|		) AS RoomInventoryBalance
	|		GROUP BY
	|			RoomInventoryBalance.RoomType
	|		UNION ALL
	|		SELECT
	|			RoomQuotaSalesBalance.RoomType AS RoomType,
	|			MIN(RoomQuotaSalesBalance.CounterClosingBalance),
	|			MIN(RoomQuotaSalesBalance.BedsInQuotaClosingBalance),
	|			MIN(RoomQuotaSalesBalance.RoomsInQuotaClosingBalance),
	|			MIN(RoomQuotaSalesBalance.BedsRemainsClosingBalance),
	|			MIN(RoomQuotaSalesBalance.RoomsRemainsClosingBalance)
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(&qDateFrom, &qDateTo, 
	|		    	                                                    Minute, 
	|		           	                                                RegisterRecordsAndPeriodBoundaries, &qUseRoomQuota" +
	?(ValueIsFilled(SelRoomQuota), " AND RoomQuota IN HIERARCHY(&qRoomQuota)", "") + 
	?(ValueIsFilled(Hotel), " AND Hotel IN HIERARCHY (&qHotel)", "") + 
	?(ValueIsFilled(SelRoomType), " AND RoomType IN HIERARCHY (&qRoomType)", "") + 
	?(vAllotmentByRooms, " AND Room IN (&qRoomsInQuota)", "") + "
	|		) AS RoomQuotaSalesBalance
	|		GROUP BY
	|			RoomQuotaSalesBalance.RoomType
	|	) AS RoomTypesBalance
	|	WHERE
	|		RoomTypesBalance.RoomType.DeletionMark = FALSE 
	|	GROUP BY
	|		RoomTypesBalance.RoomType
	|	) AS RoomTypes
	|
	|WHERE " + 
	?(ValueIsFilled(Company), " (RoomTypes.RoomType.Company = &qCompany) OR (RoomTypes.RoomType.Company = &qEmptyCompany)", "TRUE") + "
	|
	|ORDER BY
	|	RoomTypeSortCode";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRoomType", SelRoomType);
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", New Boundary(DateTo, BoundaryType.Excluding));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qRoomQuota", SelRoomQuota);
	vQry.SetParameter("qRoomsInQuota", vRoomsInQuota);
	vQry.SetParameter("qUseRoomQuota", ValueIsFilled(SelRoomQuota));
	vQryResult = vQry.Execute();
	vRoomTypes = vQryResult.Unload();
	
	// Run query to get list of available rooms
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Rooms.Room AS Room,
	|	Rooms.Room.SortCode AS SortCode,
	|	Rooms.RoomType AS RoomType,
	|	Rooms.Room.RoomStatus AS RoomStatus,
	|	Rooms.TotalBeds AS TotalBeds,
	|	Rooms.TotalRooms AS TotalRooms,
	|	Rooms.BedsVacant AS BedsVacant,
	|	Rooms.RoomsVacant AS RoomsVacant,
	|	Rooms.Room.Company AS Company,
	|	Rooms.Room.IsFolder AS IsFolder,
	|	Rooms.Room.IsVirtual AS IsVirtual,
	|	Rooms.Room.RoomPropertiesCodes AS RoomPropertiesCodes,
	|	Rooms.Room.RoomPropertiesDescriptions AS RoomPropertiesDescriptions,
	|	Rooms.Room.Remarks AS Remarks
	|FROM
	|	(SELECT
	|		RoomBalance.Room AS Room,
	|		RoomBalance.RoomType AS RoomType,
	|		MAX(RoomBalance.TotalBeds) AS TotalBeds,
	|		MAX(RoomBalance.TotalRooms) AS TotalRooms,
	|		MAX(RoomBalance.BedsVacant) AS BedsVacant,
	|		MAX(RoomBalance.RoomsVacant) AS RoomsVacant
	|	FROM
	|		(SELECT
	|			RoomInventoryBalance.Room AS Room,
	|			RoomInventoryBalance.RoomType AS RoomType,
	|			MIN(RoomInventoryBalance.CounterClosingBalance) AS CounterClosingBalance,
	|			MIN(RoomInventoryBalance.TotalBedsClosingBalance) AS TotalBeds,
	|			MIN(RoomInventoryBalance.TotalRoomsClosingBalance) AS TotalRooms,
	|			MIN(RoomInventoryBalance.BedsVacantClosingBalance) AS BedsVacant,
	|			MIN(RoomInventoryBalance.RoomsVacantClosingBalance) AS RoomsVacant
	|		FROM
	|			AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|					&qDateFrom,
	|					&qDateTo,
	|					Second,
	|					RegisterRecordsAndPeriodBoundaries,
	|					(&qHotelIsFilled
	|							AND Hotel IN HIERARCHY (&qHotel)
	|						OR NOT &qHotelIsFilled)
	|						AND (&qRoomTypeIsFilled
	|								AND RoomType IN HIERARCHY (&qRoomType)
	|							OR NOT &qRoomTypeIsFilled)
	|						AND (&qAllotmentByRooms
	|								AND Room IN (&qRoomsInQuota)
	|							OR NOT &qAllotmentByRooms)) AS RoomInventoryBalance
	|		
	|		GROUP BY
	|			RoomInventoryBalance.Room,
	|			RoomInventoryBalance.RoomType
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomQuotaSalesBalance.Room,
	|			RoomQuotaSalesBalance.RoomType,
	|			MIN(RoomQuotaSalesBalance.CounterClosingBalance),
	|			MIN(RoomQuotaSalesBalance.BedsInQuotaClosingBalance),
	|			MIN(RoomQuotaSalesBalance.RoomsInQuotaClosingBalance),
	|			MIN(RoomQuotaSalesBalance.BedsRemainsClosingBalance),
	|			MIN(RoomQuotaSalesBalance.RoomsRemainsClosingBalance)
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|					&qDateFrom,
	|					&qDateTo,
	|					Minute,
	|					RegisterRecordsAndPeriodBoundaries,
	|					&qUseRoomQuota
	|						AND RoomQuota IN HIERARCHY (&qRoomQuota)
	|						AND (&qHotelIsFilled
	|								AND Hotel IN HIERARCHY (&qHotel)
	|							OR NOT &qHotelIsFilled)
	|						AND (&qRoomTypeIsFilled
	|								AND RoomType IN HIERARCHY (&qRoomType)
	|							OR NOT &qRoomTypeIsFilled)
	|						AND (&qAllotmentByRooms
	|								AND Room IN (&qRoomsInQuota)
	|							OR NOT &qAllotmentByRooms)) AS RoomQuotaSalesBalance
	|		
	|		GROUP BY
	|			RoomQuotaSalesBalance.Room,
	|			RoomQuotaSalesBalance.RoomType) AS RoomBalance
	|	WHERE
	|		NOT RoomBalance.Room.DeletionMark
	|		AND (&qRoomStatusIsFilled
	|					AND RoomBalance.Room.RoomStatus = &qRoomStatus
	|				OR NOT &qRoomStatusIsFilled)
	|	
	|	GROUP BY
	|		RoomBalance.RoomType,
	|		RoomBalance.Room
	|	
	|	HAVING
	|		(&qShowVacantOnly
	|				AND MAX(RoomBalance.BedsVacant) >= &qNumberOfBeds
	|				AND MAX(RoomBalance.RoomsVacant) >= &qNumberOfRooms
	|			OR NOT &qShowVacantOnly)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VirtualRooms.Ref,
	|		VirtualRooms.RoomType,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		Catalog.Rooms AS VirtualRooms
	|	WHERE
	|		VirtualRooms.IsVirtual
	|		AND (&qHotelIsFilled
	|					AND VirtualRooms.Owner IN HIERARCHY (&qHotel)
	|				OR NOT &qHotelIsFilled)
	|		AND (&qRoomTypeIsFilled
	|					AND VirtualRooms.RoomType IN HIERARCHY (&qRoomType)
	|				OR NOT &qRoomTypeIsFilled)) AS Rooms
	|WHERE
	|	(&qCompanyIsFilled
	|				AND (Rooms.RoomType.Company = &qCompany
	|					OR Rooms.Room.Company = &qCompany
	|					OR Rooms.RoomType.Company = &qEmptyCompany
	|						AND Rooms.Room.Company = &qEmptyCompany)
	|			OR NOT &qCompanyIsFilled)
	|
	|ORDER BY
	|	SortCode
	|TOTALS BY
	|	Room HIERARCHY";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(Hotel));
	vQry.SetParameter("qRoomType", SelRoomType);
	vQry.SetParameter("qRoomTypeIsFilled", ValueIsFilled(SelRoomType));
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", New Boundary(DateTo, BoundaryType.Excluding));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsFilled", ValueIsFilled(Company));
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qNumberOfBeds", SelNumberOfBeds);
	vQry.SetParameter("qNumberOfRooms", SelNumberOfRooms);
	vQry.SetParameter("qRoomStatus", vRoomStatus);
	vQry.SetParameter("qRoomStatusIsFilled", ValueIsFilled(vRoomStatus));
	vQry.SetParameter("qRoomQuota", SelRoomQuota);
	vQry.SetParameter("qRoomsInQuota", vRoomsInQuota);
	vQry.SetParameter("qAllotmentByRooms", vAllotmentByRooms);
	vQry.SetParameter("qUseRoomQuota", ValueIsFilled(SelRoomQuota));
	vQry.SetParameter("qShowVacantOnly", Not (SelNumberOfBeds = 0 And SelNumberOfRooms = 0));
	vQryResult = vQry.Execute();
	vRooms = vQryResult.Unload();
	
	
	// Get the value list of all vacant rooms
	vRoomsList = New ValueList();
	vRoomsAndFoldersList = New ValueList();
	For Each vRoom In vRooms Do
		vCurRoom = vRoom.Room;
		If ValueIsFilled(vCurRoom) Then
			If Not vRoom.IsFolder Then
				If vRoomsList.FindByValue(vCurRoom) = Undefined Then
					vRoomsList.Add(vCurRoom);
				EndIf;
			EndIf;
			If vRoomsAndFoldersList.FindByValue(vCurRoom) = Undefined Then
				vRoomsAndFoldersList.Add(vCurRoom);
			EndIf;
		EndIf;
	EndDo;
	
	// Get the table of nearest dates when rooms became busy
	vQryReserv = New Query();
	vQryReserv.Text = 
	"SELECT
	|	RoomInventory.Room,
	|	MIN(RoomInventory.PeriodFrom) AS CheckInDate,
	|	RoomInventory.Room.SortCode AS SortCode
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Room IN(&qRooms)
	|	AND RoomInventory.RecordType = &qExpense
	|	AND RoomInventory.PeriodFrom >= &qDateTo
	|	AND RoomInventory.PeriodFrom < &qNextDateTo
	|	AND (RoomInventory.IsReservation OR RoomInventory.IsAccommodation)
	|GROUP BY
	|	RoomInventory.Room
	|ORDER BY
	|	SortCode";
	vQryReserv.SetParameter("qRooms", vRoomsList);
	vQryReserv.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQryReserv.SetParameter("qDateTo", DateTo);
	vQryReserv.SetParameter("qNextDateTo", DateTo + 7*24*3600); // Look only for 7 days in the future
	vReserves = vQryReserv.Execute().Unload();
	
	// Get table of nearest times when rooms became vacant
	vNumDays = 2;
	If ValueIsFilled(Hotel) And Hotel.VacantRoomsChoiceFormVacantFromDateHistoryDepth > 0 Then
		vNumDays = Hotel.VacantRoomsChoiceFormVacantFromDateHistoryDepth;
	EndIf;
	vQryVacant = New Query();
	vQryVacant.Text = 
	"SELECT
	|	RoomInventory.Room,
	|	MAX(RoomInventory.PeriodTo) AS CheckOutDate,
	|	RoomInventory.Room.SortCode AS SortCode
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Room IN(&qRooms)
	|	AND RoomInventory.RecordType = &qReceipt
	|	AND RoomInventory.PeriodTo <= &qDateFrom
	|	AND RoomInventory.PeriodTo > &qPrevDateFrom
	|	AND (RoomInventory.IsReservation OR RoomInventory.IsAccommodation)
	|GROUP BY
	|	RoomInventory.Room
	|ORDER BY
	|	SortCode";
	vQryVacant.SetParameter("qRooms", vRoomsList);
	vQryVacant.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vQryVacant.SetParameter("qDateFrom", DateFrom);
	vQryVacant.SetParameter("qPrevDateFrom", DateFrom - vNumDays*24*3600); // Look only for 2 day in the past by default
	vVacants = vQryVacant.Execute().Unload();
		
	// Get table of room blocks
	vQryBlocks = New Query();
	vQryBlocks.Text = 
	"SELECT
	|	RoomInventory.Room AS Room,
	|	RoomInventory.RoomBlockType AS RoomBlockType,
	|	RoomInventory.Room.SortCode AS SortCode
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE " +
	?(ValueIsFilled(Hotel), "Hotel IN HIERARCHY(&qHotel)", "TRUE") + 
	?(ValueIsFilled(SelRoomType), " AND RoomType IN HIERARCHY(&qRoomType)", " AND TRUE") + 
	?(ValueIsFilled(Company), " AND ((RoomInventory.Room.Company = &qCompany) OR (RoomInventory.RoomType.Company = &qCompany) OR (RoomInventory.Room.Company = &qEmptyCompany AND RoomInventory.RoomType.Company = &qEmptyCompany)) ", " AND TRUE") + "
	|	AND RoomInventory.RecordType = &qExpense
	|	AND RoomInventory.IsBlocking
	|	AND RoomInventory.PeriodFrom > &qEmptyDate
	|	AND RoomInventory.PeriodFrom < &qDateTo
	|	AND (RoomInventory.PeriodTo > &qDateFrom OR RoomInventory.PeriodTo = &qEmptyDate)
	|GROUP BY
	|	RoomInventory.Room,
	|	RoomInventory.RoomBlockType
	|ORDER BY
	|	SortCode";
	vQryBlocks.SetParameter("qHotel", Hotel);
	vQryBlocks.SetParameter("qRoomType", SelRoomType);
	vQryBlocks.SetParameter("qCompany", Company);
	vQryBlocks.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQryBlocks.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQryBlocks.SetParameter("qDateFrom", DateFrom);
	vQryBlocks.SetParameter("qDateTo", DateTo);
	vQryBlocks.SetParameter("qEmptyDate", Date(1,1,1));
	vBlocks = vQryBlocks.Execute().Unload();
	
	// Get table of guest countries and sexes in all rooms
	vQryGuests = New Query();
	vQryGuests.Text = 
	"SELECT
	|	RoomInventory.Room AS Room,
	|	RoomInventory.IsReservation AS IsReservation,
	|	RoomInventory.Guest.Citizenship.ISOCode AS GuestCitizenship,
	|	RoomInventory.Guest.Sex AS GuestSex,
	|	COUNT(*) AS GuestCount,
	|	RoomInventory.Room.SortCode AS SortCode
	|FROM (
	|	SELECT
	|		RoomInventoryRecorders.Room AS Room,
	|		RoomInventoryRecorders.IsReservation AS IsReservation,
	|		RoomInventoryRecorders.Guest AS Guest,
	|		RoomInventoryRecorders.Recorder AS Recorder
	|	FROM
	|		AccumulationRegister.RoomInventory AS RoomInventoryRecorders
	|	WHERE " +
	?(ValueIsFilled(Hotel), "RoomInventoryRecorders.Hotel IN HIERARCHY(&qHotel)", "TRUE") + "
	|		AND RoomInventoryRecorders.RecordType = &qExpense
	|		AND RoomInventoryRecorders.PeriodFrom < &qDateTo
	|		AND RoomInventoryRecorders.PeriodTo > &qDateFrom
	|		AND (RoomInventoryRecorders.IsReservation OR RoomInventoryRecorders.IsAccommodation)
	|	GROUP BY
	|		RoomInventoryRecorders.Room,
	|		RoomInventoryRecorders.IsReservation,
	|		RoomInventoryRecorders.Guest,
	|		RoomInventoryRecorders.Recorder) AS RoomInventory
	|GROUP BY
	|	RoomInventory.Room,
	|	RoomInventory.IsReservation,
	|	RoomInventory.Guest.Citizenship.ISOCode,
	|	RoomInventory.Guest.Sex
	|ORDER BY
	|	SortCode
	|TOTALS
	|	SUM(GuestCount)
	|BY
	|	IsReservation, GuestCitizenship, GuestSex, Room HIERARCHY";
	vQryGuests.SetParameter("qHotel", Hotel);
	vQryGuests.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQryGuests.SetParameter("qDateFrom", DateFrom);
	vQryGuests.SetParameter("qDateTo", DateTo);
	vGuests = vQryGuests.Execute().Unload();
	// Group by all dimensions to get room folders totals
	vGuests.GroupBy("IsReservation, GuestCitizenship, GuestSex, Room", "GuestCount");
			
	// Get the table of messages
	vMessages = cmGetMessagesForObjectsList(vRoomsAndFoldersList);
	
	// Calculate number of vacant rooms/beds per room type
	For Each vRoomType In vRoomTypes Do
		vCurRoomType = vRoomType.RoomType;
		
		// Ignore empty room type
		If Not ValueIsFilled(vCurRoomType) Then
			Continue;
		EndIf;
		
		If Not vCurRoomType.IsFolder Then
			If vInBeds Then
				vTotalVacant = vTotalVacant + vRoomType.BedsVacant;
			Else
				vTotalVacant = vTotalVacant + vRoomType.RoomsVacant;
			EndIf;
		EndIf;
	EndDo;
	
	vTableBoxRooms = FormAttributeToValue("TableBoxRooms");
	For Each vRoom In vRooms Do
		vCurRoomType = vRoom.RoomType;
		vCurRoom = vRoom.Room;
		
		// Ignore duplicated totals
		If Not ValueIsFilled(vCurRoom) Then
			Continue;
		Else
			If Not vRoom.IsFolder And Not ValueIsFilled(vCurRoomType) Then
				Continue;
			EndIf;
		EndIf;
		If vRoomsArray.Find(vCurRoom) = Undefined Then
			vRoomsArray.Add(vCurRoom);
		Else
			Continue;
		EndIf;
		       
		vContinue = False;
		If Not vRoom.IsFolder Then
			vRoomProperties = GetRoomPropertiesByRoom(vRoom);
			If vRoomProperties.Count() > 0 Then
				For Each vProp In SelRoomProperties Do
					If vProp.Check Then
						If vProp.Value.KeepRoomsWithoutProperty Then
							If vRoomProperties.FindRows(New Structure("RoomProperty", vProp.Value)).Count() <> 0 Then
								vContinue = True;
								break;	
							EndIf;
						Else
							If vRoomProperties.FindRows(New Structure("RoomProperty", vProp.Value)).Count() = 0 Then
								vContinue = True;
								break;	
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		If vContinue Then
			Continue;	
		EndIf;
		
		// Calculate total number of available rooms/beds
		If Not vRoom.IsFolder Then
			If SelNumberOfRooms = 0 And SelNumberOfBeds = 0 Then
				If vInBeds Then
					vTotalAvailable = vTotalAvailable + vRoom.TotalBeds;
				Else
					vTotalAvailable = vTotalAvailable + vRoom.TotalRooms;
				EndIf;
			Else
				If vInBeds Then
					vTotalAvailable = vTotalAvailable + vRoom.BedsVacant;
				Else
					vTotalAvailable = vTotalAvailable + vRoom.RoomsVacant;
				EndIf;
			EndIf;
		EndIf;
				
		// Add new row
		vTableRow = vTableBoxRooms.Rows.Add();
		vRowIndex = vTableBoxRooms.Rows.IndexOf(vTableRow);
		
		// Fill main parameters
		vTableRow.Room = vCurRoom;
		vTableRow.RoomType = vCurRoomType;
		vTableRow.RoomStatus = vRoom.RoomStatus;
		vTableRow.SortCode = vRoom.SortCode;
		vTableRow.BedsVacant = vRoom.BedsVacant;
		vTableRow.RoomsVacant = vRoom.RoomsVacant;
		vTableRow.IsFolder = vRoom.IsFolder;
		vTableRow.IsVirtual = vRoom.IsVirtual;
		vTableRow.Company = vRoom.Company;
		vTableRow.RoomPropertiesCodes = StrReplace(vRoom.RoomPropertiesCodes, Chars.LF, ", ");
		
		// Fill picture index		
		If vRoom.IsFolder Then
			vTableRow.Icon = 6;
		Else
			If vInBeds Then
				If vTableRow.BedsVacant > 0 Then
					vTableRow.IsVacant = True;
					vTableRow.Icon = 20;
				Else
					vTableRow.IsVacant = False;
					vTableRow.Icon = 18;
				EndIf;
			Else
				If vTableRow.RoomsVacant > 0 And vTableRow.BedsVacant > 0 Then
					vTableRow.IsVacant = True;
					vTableRow.Icon = 20;
				Else
					vTableRow.IsVacant = False;
					vTableRow.Icon = 18;
				EndIf;
			EndIf;
		EndIf;
		
		// Fill vacant from
		If Not vRoom.IsFolder Then
			If vTableRow.IsVacant Then
				vRow = vVacants.Find(vCurRoom, "Room");
				If vRow <> Undefined Then
					vTableRow.VacantFrom = Format(vRow.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
				EndIf;
			EndIf;
		EndIf;
		
		// Fill guests
		vRowsArray = vGuests.FindRows(New Structure("Room", vCurRoom));
		vGuestsStr = "";
		For Each vRow In vRowsArray Do
			If Not IsBlankString(vGuestsStr) Then
				vGuestsStr = vGuestsStr + ", ";
			EndIf;
			vGuestCount = vRow.GuestCount;
			If Not vRoom.IsFolder Then
				vGuestCount = vGuestCount/2;
			EndIf;
			vGuestSex = TrimAll(String(vRow.GuestSex));
			vGuestCitizenship = TrimAll(vRow.GuestCitizenship);
			vGuestsStr = vGuestsStr + ?(vRow.IsReservation, NStr("en='r';ru='р';de='r'"), "") + 
			String(vGuestCount) + 
			Left(?(vGuestSex="", "?", vGuestSex), 1) + 
			"(" + ?(vGuestCitizenship="", "?", vGuestCitizenship) + ")";
		EndDo;
		vTableRow.Guests = vGuestsStr;
		
		// Fill room blocks
		If Not vRoom.IsFolder Then
			vRowsArray = vBlocks.FindRows(New Structure("Room", vCurRoom));
			vBlocksStr = "";
			If Not IsBlankString(vTableRow.Guests) Then
				vBlocksStr = Chars.LF;
			EndIf;
			For Each vRow In vRowsArray Do
				If Not IsBlankString(vBlocksStr) And vBlocksStr <> Chars.LF Then
					vBlocksStr = vBlocksStr + ", ";
				EndIf;
				If ValueIsFilled(vRow.RoomBlockType) Then
					vBlocksStr = vBlocksStr + TrimAll(vRow.RoomBlockType.Description);
				EndIf;
			EndDo;
			vTableRow.Guests = vTableRow.Guests + vBlocksStr;
		EndIf;
		
		// Fill vacant to
		If Not vRoom.IsFolder Then
			If vTableRow.IsVacant Then
				vRow = vReserves.Find(vCurRoom, "Room");
				If vRow <> Undefined Then
					vTableRow.VacantTo = Format(vRow.CheckInDate, "DF='dd.MM.yyyy HH:mm'");
				EndIf;
			EndIf;
		EndIf;
		
		// Fill messages
		vTableRow.Messages = cmGetMessagesPresentationForObject(vMessages, vCurRoom);
		// Fill room remarks
		If Not IsBlankString(vRoom.Remarks) Then
			If Not IsBlankString(vTableRow.Messages) Then
				vTableRow.Messages = vTableRow.Messages + Chars.LF;
			EndIf;
			vTableRow.Messages = vTableRow.Messages + TrimAll(vRoom.Remarks);
		EndIf;
	EndDo;
	
	RoomsVacantTotal = vTableBoxRooms.Rows.Total("RoomsVacant", True);
	BedsVacantTotal = vTableBoxRooms.Rows.Total("BedsVacant", True);
	ValueToFormAttribute(vTableBoxRooms, "TableBoxRooms");
EndProcedure // PutData

// -----------------------------------------------------------------------------
&AtServer
Function FillRoomPropertiesList()
	// Get all service packages available for use
	vRoomPropertiesList = cmGetAllRoomProperties(Undefined, Hotel, True);
	// Check service packages already being selected
	For Each vRP In SelRoomProperties Do
		If ValueIsFilled(vRP.Value) Then
			vRPItem = vRoomPropertiesList.FindByValue(vRP.Value);
			If vRPItem <> Undefined Then
				vRPItem.Check = vRP.Check;
			EndIf;
		EndIf;
	EndDo;
	Return vRoomPropertiesList;
EndFunction // FillRoomPropertiesList

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationStartChoice_AfterInput(pValue, pParametrs) Export	
	If pValue <> Undefined Then
		SaveRoomPropertiesList(pValue);
		PutData();
	EndIf;
	RoomPropertiesPresentation = GetRoomPropertiesPresentation();
EndProcedure // RoomPropertiesPresentationStartChoice_AfterInput

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveRoomPropertiesList(pRoomPropertiesList)
	SelRoomProperties.Clear();
	If pRoomPropertiesList.Count() > 0 Then
		For Each vRPItem In pRoomPropertiesList Do
			SelRoomProperties.Add(vRPItem.Value,,vRPItem.Check);
		EndDo;
	EndIf;
EndProcedure // SaveRoomPropertiesList

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomPropertiesPresentation()
	// Room properties
	vRPPresentation = "";
	For Each vRPItem In SelRoomProperties Do
		If vRPItem.Check Then
			If ValueIsFilled(vRPItem.Value) Then
				If IsBlankString(vRPPresentation) Then
					vRPPresentation = TrimAll(vRPItem.Value.Description);
				Else
					vRPPresentation = vRPPresentation + ", " + TrimAll(vRPItem.Value.Description);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	Return vRPPresentation;
EndFunction // GetRoomPropertiesPresentation

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationClearing(pItem, pStandardProcessing)
	SelRoomProperties.Clear();
	RoomPropertiesPresentation = GetRoomPropertiesPresentation();
	PutData();
EndProcedure // RoomPropertiesPresentationClearing

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomPropertiesByRoom(pRoom)
	vQryProp = New Query();
	vQryProp.Text = 
	"SELECT
	|	RoomProperties.RoomProperty AS RoomProperty
	|FROM
	|	InformationRegister.RoomProperties AS RoomProperties
	|WHERE
	|	RoomProperties.Room = &qRooms
	|	AND RoomProperties.Room.DeletionMark = FALSE";
	vQryProp.SetParameter("qRooms", pRoom.Room);
	vProps = vQryProp.Execute().Unload();
	Return vProps; 
EndFunction // GetRoomPropertiesByRoom

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxRoomsRefreshRequestProcessing()
	PutData();
EndProcedure // TableBoxRoomsRefreshRequestProcessing

#EndRegion
