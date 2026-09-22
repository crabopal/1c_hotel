
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	NumberOfKidAgeFields = 8;
	IsFromObject = False;
	vRoomRate = Undefined;
	If ThisForm.Parameters.Property("RoomRate", vRoomRate) Then
		SelRoomRate = vRoomRate;
	EndIf;
	vFilter = Undefined;
	vHotel = Undefined;
	If ThisForm.Parameters.Property("Filter", vFilter) Then
		If vFilter.Property("Owner", vHotel) Then
			SelHotel = vHotel;
		EndIf;
	EndIf;
	If ThisForm.Parameters.Property("Hotel", vHotel) Then
		SelHotel = vHotel;
	EndIf;
	vCheckInDate = Undefined;
	If ThisForm.Parameters.Property("CheckInDate", vCheckInDate) Then
		SelCheckInDate = vCheckInDate;
		SelCheckInTime = vCheckInDate;
	EndIf;
	vCheckOutDate = Undefined;
	If ThisForm.Parameters.Property("CheckOutDate", vCheckOutDate) Then
		SelCheckOutDate = vCheckOutDate;
		SelCheckOutTime = vCheckOutDate;
	EndIf;
	vRoomQuota = Undefined;
	If ThisForm.Parameters.Property("RoomQuota", vRoomQuota) Then
		SelRoomQuota = vRoomQuota;
	EndIf;
	vClientType = Undefined;
	If ThisForm.Parameters.Property("ClientType", vClientType) Then
		SelClientType = vClientType;
	EndIf;
	vNumberOfAdults = Undefined;
	If ThisForm.Parameters.Property("NumberOfAdults", vNumberOfAdults) Then
		NumberOfAdults = vNumberOfAdults;
	EndIf;
	AgeList.Clear();
	vNumberOfKids = Undefined;
	If ThisForm.Parameters.Property("NumberOfKids", vNumberOfKids) Then
		NumberOfKids = vNumberOfKids;
		vAgeArray = Undefined;
		If ThisForm.Parameters.Property("AgeArray", vAgeArray) Then
			For Each vItem In vAgeArray Do
				AgeList.Add(vItem);
			EndDo;
		EndIf;
	EndIf;
	vCustomer = Undefined;
	If ThisForm.Parameters.Property("Customer", vCustomer) Then
		SelCustomer = vCustomer;
	EndIf;
	vContract = Undefined;
	If ThisForm.Parameters.Property("Contract", vContract) Then
		SelContract = vContract;
	EndIf;
	vRoomType = Undefined;
	If ThisForm.Parameters.Property("RoomType", vRoomType) Then
		If ValueIsFilled(vRoomType) Then
			SelChoiceInitialValue = vRoomType;
		EndIf;
	EndIf;
	vWindowView = Undefined;
	SelWindowView = Undefined;
	If ThisForm.Parameters.Property("WindowView", vWindowView) Then
		Items.WindowView.Visible = True;
		If ValueIsFilled(vWindowView) Then
			SelWindowView = vWindowView;
		EndIf;
	Else
		Items.WindowView.Visible = False;
	EndIf;
	If (NumberOfAdults <> 0 Or NumberOfKids <> 0) And 
	   ValueIsFilled(SelRoomRate) And SelRoomRate.PeriodInHours = 24 And 
	   SelRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour And 
	   ((cm0SecondShift(SelCheckInTime) - BegOfDay(SelCheckInTime)) = (SelRoomRate.DefaultCheckInTime - BegOfDay(SelRoomRate.DefaultCheckInTime)) Or (cm0SecondShift(SelCheckInTime) - BegOfDay(SelCheckInTime)) = (SelRoomRate.ReferenceHour - BegOfDay(SelRoomRate.ReferenceHour))) And 
	   (SelCheckOutTime - BegOfDay(SelCheckOutTime)) = (SelRoomRate.ReferenceHour - BegOfDay(SelRoomRate.ReferenceHour)) Then
		If Not ValueIsFilled(SelRoomRate.PriceTagType) Then
			vRoomRates = New ValueList();
			vRoomRates.Add(SelRoomRate);
			If ValueIsFilled(SelHotel) And SelHotel.UseRoomRateDailyPrices And cmRoomRatePricesCacheIsFilled(SelHotel, vRoomRates, SelClientType, SelCheckInDate, SelCheckOutDate) Then
				IsFromObject = True;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(SelHotel) And SelHotel.ShowReportsInBeds Then
		Items.RoomTypesListBedsAvailableWithTentativePresentation.Visible = True;
	Else
		Items.RoomTypesListBedsAvailableWithTentativePresentation.Visible = False;
	EndIf;
	If Not IsFromObject Then
		Items.NumberOfPersons.Visible = False;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If ValueIsFilled(NumberOfKids) Then
		NumberOfKidsOnChange(Items.NumberOfKids);
		If AgeList.Count() > 0 Then
			vIndex = 1;
			For Each vItem In AgeList Do
				Try
					Items["KidAge"+String(vIndex)].Visible = True;
					ThisForm["KidAge"+String(vIndex)] = vItem.Value;
				Except
				EndTry;
				vIndex = vIndex + 1;
				If vIndex > NumberOfKidAgeFields Then
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	OnOpenForm();
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If Not Items.FormAvailableRoomsAction.Check Then
		If ValueIsFilled(RoomQuota) Then
			vIsFolder = tcOnServer.cmGetAttributeByRef(RoomQuota, "IsFolder");
			If vIsFolder Then
				vMessage = New UserMessage;
				vMessage.Field = "RoomQuota";
				vMessage.Text = NStr("en='You should choose allotment item not group to select room type!';ru='Нельзя выбирать тип номера при указанной группе квот!';de='Der Zimmertyp bei angegebener Quotengruppe darf nicht gewählt werden!'");
				vMessage.Message();
				Return;
			EndIf;
		EndIf;
		If ValueIsFilled(pItem.CurrentData.Ref) Then
			If FormOwner = Undefined Then
				If pSelectedRow<>Undefined Then
					RoomType = pItem.CurrentData.Ref;
				EndIf;
			Else
				vInd = 0;
				If Left(pField.Name, 28) = "RoomTypesListSumPresentation" And pField.Name <> "RoomTypesListSumPresentation" Then
					vInd = Number(Right(pField.Name, 1));
					RoomRate = pItem.CurrentData["RoomRate"+vInd];
				EndIf;
				vFormOwner = FormOwner;
				vType = Undefined;
				#If ThickClientOrdinaryApplication Then
					vType = Type("TextBox");
				#EndIf
				If TypeOf(vFormOwner) <> vType Then
					While (TypeOf(vFormOwner) <> Type("ClientApplicationForm")) Or vFormOwner = Undefined Do
						vFormOwner = vFormOwner.Parent;
					EndDo;
				Else
					vFormOwner = Undefined;
				EndIf;
				If vFormOwner <> Undefined Then
					If vFormOwner.FormName = "Document.Reservation.Form.tcDocumentForm" Or 
					   vFormOwner.FormName = "Document.Accommodation.Form.tcDocumentForm" Or 
					   vFormOwner.FormName = "CommonForm.tcAvailableRoomsReport" Then
						NotifyChoice(New Structure("RoomQuota, RoomType, AccommodationType, RoomRate, ClientType, CheckInDate, CheckOutDate, Duration", RoomQuota, pItem.CurrentData.Ref, Undefined, RoomRate, ClientType, CheckInDate, CheckOutDate, Duration));
					Else
						NotifyChoice(pItem.CurrentData.Ref);
					EndIf;
				Else
					NotifyChoice(pItem.CurrentData.Ref);
	            EndIf;
			EndIf;
		EndIf;
	Else
		GetAvailableRoomsForm();	
	EndIf;
EndProcedure // RoomTypesListSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(pItem)
	// Build List
	BuildList();
EndProcedure // RoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure WindowViewOnChange(pItem)
	// Build List
	BuildList();
EndProcedure // WindowViewOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	// Build List
	BuildList();
EndProcedure // ClientTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomQuotaOnChange(pItem)
	// Build list
	BuildList();
EndProcedure // RoomQuotaOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	If ValueIsFilled(RoomRate) Then
		Items.FormAvailableRoomsAction.Enabled = True;
	Else
		Items.FormAvailableRoomsAction.Enabled = False;
	EndIf;
	// Build list
	BuildList();
EndProcedure // RoomRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInDateOnChange(pItem)
	CheckInDateChange();
EndProcedure // CheckInDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutDateOnChange(pItem)
	CheckOutDateChange();
EndProcedure // CheckOutDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(pItem)
	DurationChange();
EndProcedure // DurationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInTimeOnChange(pItem)
	CheckInTimeChange();
EndProcedure // CheckInTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutTimeOnChange(pItem)
	CheckOutTimeChange();
EndProcedure // CheckOutTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfKidsOnChange(pItem)
	If NumberOfKids = 0 Then
		Items.AgeDecoration.Visible = False;
		For vInd = 1 To NumberOfKidAgeFields Do
			Try
				Items["KidAge"+String(vInd)].Visible = False;
				ThisForm["KidAge"+String(vInd)] = 0;
			Except
			EndTry;
		EndDo;
	Else
		Items.AgeDecoration.Visible = True;
		If NumberOfKids < NumberOfKidAgeFields Then
			For vInd = NumberOfKids + 1 To NumberOfKidAgeFields Do
				Try
					Items["KidAge"+String(vInd)].Visible = False;
					ThisForm["KidAge"+String(vInd)] = 0;
				Except
				EndTry;
			EndDo;
		EndIf;
		For vInd = 1 To Min(NumberOfKidAgeFields, NumberOfKids) Do
			Try
				Items["KidAge"+String(vInd)].Visible = True;
				ThisForm["KidAge"+String(vInd)] = 0;
			Except
			EndTry;
		EndDo;
	EndIf;
EndProcedure // NumberOfKidsOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure AvailableRoomsAction(pCommand)
	Items.FormAvailableRoomsAction.Check = Not Items.FormAvailableRoomsAction.Check; 
EndProcedure // AvailableRoomsAction

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowFiletGroup(pCommand)
	Items.FilterGroup.Visible = Not Items.FilterGroup.Visible; 
	Items.ShowFilterGroup.Check = Items.FilterGroup.Visible;
EndProcedure // ShowFiletGroup 

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpenForm()
	// Check permission to edit client type
	If Not cmCheckUserPermissions("HavePermissionToChooseClientTypeManually") Then
		Items.ClientType.Enabled = False;
	EndIf;
	// Check that parameters are filled
	FillParametersByDefaultValues();
	ResetParameters();
	// Check permission to edit allotment
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.RoomQuota) Then
		Items.RoomQuota.ClearButton = False;
		Items.RoomQuota.ChoiceButton = False;
		Items.RoomQuota.OpenButton = False;
		Items.RoomQuota.ReadOnly = True;
	EndIf;
	// Build list
	BuildList();
	// Try to position list on choice initial value
	DoInitialListPositioning();
	// Check hotel
	If Not ValueIsFilled(Hotel) Or Hotel.IsFolder Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Hotel chould be choosen!';ru='Должна быть выбрана гостиница!';de='Das Hotel muss gewählt sein!'"));
		Return;
	EndIf;
EndProcedure // OnOpenForm

// -----------------------------------------------------------------------------
&AtServer
Procedure FillParametersByDefaultValues()
	If Not ValueIsFilled(SelRoomRate) Then
		If ValueIsFilled(SelHotel) Then
			SelRoomRate = SelHotel.RoomRate;
		EndIf;
	EndIf;
	If Not ValueIsFilled(SelCheckInDate) Then
		SelCheckInDate = Date(Year(CurrentSessionDate()), Month(CurrentSessionDate()), Day(CurrentSessionDate()), 
	                 Hour(CurrentSessionDate()), Minute(CurrentSessionDate()), 0);
	EndIf;
	If Not ValueIsFilled(SelCheckOutDate) Then
		vPeriodInHours = 24;
		SelDuration = 1;
		SelCheckOutDate = SelCheckInDate + SelDuration * vPeriodInHours * 3600;
	Else
		SelDuration = cmCalculateDuration(SelRoomRate, SelCheckInDate, SelCheckOutDate);
	EndIf;
	If Not ValueIsFilled(SelHotel) Then
		SelHotel = SessionParameters.CurrentHotel;
		If ValueIsFilled(SelHotel) Then
			SelDuration = SelHotel.Duration;
			SelRoomRate = SelHotel.RoomRate;
			SelCheckOutDate = cmCalculateCheckOutDate(SelRoomRate, SelCheckInDate, SelDuration);
		EndIf;
	EndIf;
	If Not ValueIsFilled(SelRoomQuota) Then
		If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.RoomQuota) Then
			SelRoomQuota = SessionParameters.CurrentUser.RoomQuota;
		EndIf;
	EndIf;
EndProcedure // FillParametersByDefaultValues

// -----------------------------------------------------------------------------
&AtServer
Procedure ResetParameters()
	CheckInDate = SelCheckInDate;
	CheckInTime = SelCheckInDate;
	Duration = SelDuration;
	CheckOutDate = SelCheckOutDate;
	CheckOutTime = SelCheckOutDate;
	ClientType = SelClientType;
	RoomRate = SelRoomRate;
	Hotel = SelHotel;
	RoomType = SelRoomType;
	RoomQuota = SelRoomQuota;
	WindowView = SelWindowView;
	If Not ValueIsFilled(NumberOfAdults) Then
		NumberOfAdults = 1;
	EndIf;
EndProcedure // ResetParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure DoInitialListPositioning()
	vPosRow = Undefined;
	If ValueIsFilled(SelChoiceInitialValue) Then
		For Each vRow In RoomTypesList Do
			If SelChoiceInitialValue = vRow.RoomType Then
				vPosRow = vRow.GetID();
				Break;
			EndIf;
		EndDo;
	EndIf;
	If vPosRow <> Undefined Then
		Items.RoomTypesList.CurrentRow = vPosRow;
	EndIf;
EndProcedure // DoInitialListPositioning

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutDateChange()
	Duration = 0;
	CheckOutTime = CheckOutDate;
	If ValueIsFilled(RoomRate) And
		ValueIsFilled(CheckInDate) And
		ValueIsFilled(CheckOutDate) Then
		Duration = cmCalculateDuration(RoomRate, CheckInDate, CheckOutDate);
		// Build list
		BuildList();
	EndIf;
EndProcedure // CheckOutDateChange

// -----------------------------------------------------------------------------
&AtServer
Procedure DurationChange()
	If ValueIsFilled(CheckInDate) Then
		CheckOutDate = cmCalculateCheckOutDate(RoomRate, CheckInDate, Duration);
		CheckOutTime = CheckOutDate;
		// Build list
		BuildList();
	EndIf;	
EndProcedure // DurationChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckInDateChange()
	CheckInTime = CheckInDate;
	If ValueIsFilled(CheckInDate) Then
		vReferenceHour = CheckInDate - BegOfDay(CheckInDate);
		vDefaultCheckInTime = Undefined;
		vPeriodInHours = 24;
		If ValueIsFilled(RoomRate) Then
			vPeriodInHours = ?(RoomRate.PeriodInHours = 0, vPeriodInHours, RoomRate.PeriodInHours);
			If RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
				vReferenceHour = RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour);
			EndIf;
			If ValueIsFilled(RoomRate.DefaultCheckInTime) Or ValueIsFilled(RoomRate.DefaultCheckOutTime) Then
				vDefaultCheckInTime = RoomRate.DefaultCheckInTime - BegOfDay(RoomRate.DefaultCheckInTime);
			EndIf;
		EndIf;
		If BegOfDay(CheckInDate) <> BegOfDay(CurrentSessionDate()) Then
			If ValueIsFilled(vDefaultCheckInTime) Then
				CheckInDate = BegOfDay(CheckInDate) + vDefaultCheckInTime;
			Else
				CheckInDate = BegOfDay(CheckInDate) + vReferenceHour;
			EndIf;
			CheckInTime = CheckInDate;
		EndIf;
		CheckOutDate = cmCalculateCheckOutDate(RoomRate, CheckInDate, Duration);
		CheckOutTime = CheckOutDate;
		// Build list
		BuildList();
	EndIf;
EndProcedure // CheckInDateChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckInTimeChange()
	CheckInDate = BegOfDay(CheckInDate) + (CheckInTime - BegOfDay(CheckInTime));
	CheckInTime = CheckInDate;
	If ValueIsFilled(CheckInDate) Then
		CheckOutDate = cmCalculateCheckOutDate(RoomRate, CheckInDate, Duration);
		CheckOutTime = CheckOutDate;
		// Build list
		BuildList();
	EndIf;	
EndProcedure // CheckInTimeChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutTimeChange()
	CheckOutDate = BegOfDay(CheckOutDate) + (CheckOutTime - BegOfDay(CheckOutTime));
	CheckOutTime = CheckOutDate;
	CheckOutDateChange();
	// Build list
	BuildList();
EndProcedure // CheckOutTimeChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GetAvailableRoomsForm()
	vCurRow = Items.RoomTypesList.CurrentData;
	// Open choice form
	If vCurRow <> Undefined Then 
		OpenForm("Catalog.Rooms.Form.mcChoiceForm", New Structure("Hotel, RoomQuota, RoomType, Room, NumberOfBeds, NumberOfRooms, DateFrom, DateTo", Hotel, RoomQuota, vCurRow.RoomType, Undefined, 0, 1, CheckInDate, CheckOutDate), ThisForm, ThisForm.UUID);
	EndIf;
EndProcedure // GetAvailableRoomsForm

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildList()
	RoomTypesList.Clear();
	Items.RoomTypesListSumPresentation.Visible = False;
	Items.RoomTypesListAvgPricePresentation.Visible = False;
	For i = 1 To 6 Do
		Items["RoomTypesListSumPresentation" + i].Visible = False;
		Items["RoomTypesListAvgPricePresentation" + i].Visible = False;
	EndDo;
	
	// Check periods
	If CheckInDate >= CheckOutDate Then
		CheckOutDate = CheckInDate + 86400;	
		Duration = 1;
	EndIf;
	
	// Build array of kid ages
	vAgeValueTable = New ValueTable();
	vAgeValueTable.Columns.Add("Age", cmGetNumberTypeDescription(3, 0));
	vAgeValueTable.Columns.Add("IsUsed", cmGetBooleanTypeDescription());
	vAgeArray = New Array;
	For vInd = 1 To NumberOfKids Do
		Try
			vAge = ThisForm["KidAge"+String(vInd)];
			
			vAgeRow = vAgeValueTable.Add();
			vAgeRow.Age = vAge;
			vAgeRow.IsUsed = False;
			
			vAgeArray.Add(vAge);
		Except
		EndTry;
	EndDo;
	
	// Build structure with children ages
	vChildrenAgesStruct = Undefined;
	If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.Contract) Then
		vAllotmentContract = RoomQuota.Contract;
		If vAllotmentContract.TeenagersMaxAge <> 0 Or vAllotmentContract.ChildrenMaxAge <> 0 Or vAllotmentContract.InfantsMaxAge <> 0 Then
			vChildrenAgesStruct = vAllotmentContract;
		EndIf;
	EndIf;
	
	// Get available room types
	vGuestsQuantity = NumberOfAdults + NumberOfKids;
	vRoomTypes = cmGetRoomTypesByGuestQuantity(vGuestsQuantity, Catalogs.RoomTypes.EmptyRef(), Hotel);
	
	// Build and run query with room inventory balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExpectedGuestGroupsTurnovers.Hotel AS Hotel,
	|	ExpectedGuestGroupsTurnovers.RoomType AS RoomType,
	|	MAX(ISNULL(ExpectedGuestGroupsTurnovers.RoomsReservedTurnover, 0)) AS PreliminaryRooms,
	|	MAX(ISNULL(ExpectedGuestGroupsTurnovers.BedsReservedTurnover, 0)) AS PreliminaryBeds
	|INTO PreliminaryTotals
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qTentativeDateTimeFrom,
	|			&qTentativeDateTimeTo,
	|			DAY,
	|			(Hotel = &qHotel
	|				OR &qHotelIsEmpty)
	|				AND CASE
	|					WHEN RoomQuota = VALUE(Catalog.RoomQuotas.EmptyRef)
	|						THEN TRUE
	|					WHEN GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|						THEN TRUE
	|					WHEN NOT ISNULL(RoomQuota.DoWriteOff, FALSE)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|				AND (&qRoomQuotaIsSet
	|						AND RoomQuota = &qRoomQuota
	|					OR NOT &qRoomQuotaIsSet)) AS ExpectedGuestGroupsTurnovers
	|
	|GROUP BY
	|	ExpectedGuestGroupsTurnovers.Hotel,
	|	ExpectedGuestGroupsTurnovers.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) AS Period,
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	RoomInventoryBalance.CounterClosingBalance AS CounterClosingBalance,
	|	CASE
	|		WHEN &qRoomQuotaIsSet
	|				AND &qDoWriteOff
	|			THEN ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|		WHEN &qRoomQuotaIsSet
	|				AND NOT &qDoWriteOff
	|				AND ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0) < ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|			THEN ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)
	|		WHEN &qRoomQuotaIsSet
	|				AND NOT &qDoWriteOff
	|				AND ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0) >= ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|			THEN ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|		ELSE ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)
	|	END AS RoomsVacant,
	|	CASE
	|		WHEN &qRoomQuotaIsSet
	|				AND &qDoWriteOff
	|			THEN ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|		WHEN &qRoomQuotaIsSet
	|				AND NOT &qDoWriteOff
	|				AND ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0) < ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|			THEN ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)
	|		WHEN &qRoomQuotaIsSet
	|				AND NOT &qDoWriteOff
	|				AND ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0) >= ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|			THEN ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|		ELSE ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)
	|	END AS BedsVacant,
	|	RoomInventoryBalance.Hotel.SortCode AS HotelSortCode,
	|	RoomInventoryBalance.RoomType.SortCode AS RoomTypeSortCode
	|INTO RoomInventoryBalanceByDays
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qDateTimeFrom,
	|			&qDateTimeTo,
	|			Minute,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qHotelIsEmpty
	|				OR Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalance
	|		LEFT JOIN (SELECT
	|			BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) AS Period,
	|			RoomQuotaSalesBalanceAndTurnovers.Hotel AS Hotel,
	|			RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType,
	|			RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|			RoomQuotaSalesBalanceAndTurnovers.RoomsInQuotaClosingBalance AS RoomsInQuota,
	|			RoomQuotaSalesBalanceAndTurnovers.BedsInQuotaClosingBalance AS BedsInQuota,
	|			RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemains,
	|			RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemains
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|					&qDateTimeFrom,
	|					&qDateTimeTo,
	|					Day,
	|					RegisterRecordsAndPeriodBoundaries,
	|					(&qHotelIsEmpty
	|						OR Hotel = &qHotel)
	|						AND &qRoomQuotaIsSet
	|						AND RoomQuota = &qRoomQuota) AS RoomQuotaSalesBalanceAndTurnovers) AS RoomQuotaBalances
	|		ON RoomInventoryBalance.Hotel = RoomQuotaBalances.Hotel
	|			AND RoomInventoryBalance.RoomType = RoomQuotaBalances.RoomType
	|			AND (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = BEGINOFPERIOD(RoomQuotaBalances.Period, DAY))
	|WHERE
	|	RoomInventoryBalance.RoomType IN(&qRoomTypesList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalanceByDays.Hotel AS Hotel,
	|	RoomInventoryBalanceByDays.RoomType AS RoomType,
	|	MIN(RoomInventoryBalanceByDays.RoomsVacant) AS RoomsAvailable,
	|	MIN(RoomInventoryBalanceByDays.BedsVacant) AS BedsAvailable
	|INTO RoomInventoryBalance
	|FROM
	|	RoomInventoryBalanceByDays AS RoomInventoryBalanceByDays
	|
	|GROUP BY
	|	RoomInventoryBalanceByDays.Hotel,
	|	RoomInventoryBalanceByDays.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	RoomInventoryBalance.RoomsAvailable AS RoomsAvailable,
	|	RoomInventoryBalance.BedsAvailable AS BedsAvailable,
	|	RoomInventoryBalance.RoomsAvailable - ISNULL(PreliminaryTotals.PreliminaryRooms, 0) AS RoomsAvailableWithTentative,
	|	RoomInventoryBalance.BedsAvailable - ISNULL(PreliminaryTotals.PreliminaryBeds, 0) AS BedsAvailableWithTentative
	|INTO RoomInventoryBalanceWithTentative
	|FROM
	|	RoomInventoryBalance AS RoomInventoryBalance
	|		LEFT JOIN PreliminaryTotals AS PreliminaryTotals
	|		ON RoomInventoryBalance.Hotel = PreliminaryTotals.Hotel
	|			AND RoomInventoryBalance.RoomType = PreliminaryTotals.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.RoomType AS Ref,
	|	RoomInventory.RoomsAvailable AS RoomsAvailable,
	|	RoomInventory.BedsAvailable AS BedsAvailable,
	|	RoomInventory.RoomsAvailableWithTentative AS RoomsAvailableWithTentative,
	|	RoomInventory.BedsAvailableWithTentative AS BedsAvailableWithTentative,
	|	&qEmptyCurrency AS Currency,
	|	&qEmptyNumber AS Sum,
	|	&qEmptyString AS SumPresentation,
	|	&qEmptyNumber AS AvgPrice,
	|	&qEmptyString AS AvgPricePresentation,
	|	&qRoomRate AS RoomRate,
	|	&qEmptyCurrency AS Currency1,
	|	&qEmptyNumber AS Sum1,
	|	&qEmptyString AS SumPresentation1,
	|	&qEmptyNumber AS AvgPrice1,
	|	&qEmptyString AS AvgPricePresentation1,
	|	&qEmptyRoomRate AS RoomRate1,
	|	&qEmptyCurrency AS Currency2,
	|	&qEmptyNumber AS Sum2,
	|	&qEmptyString AS SumPresentation2,
	|	&qEmptyNumber AS AvgPrice2,
	|	&qEmptyString AS AvgPricePresentation2,
	|	&qEmptyRoomRate AS RoomRate2,
	|	&qEmptyCurrency AS Currency3,
	|	&qEmptyNumber AS Sum3,
	|	&qEmptyString AS SumPresentation3,
	|	&qEmptyNumber AS AvgPrice3,
	|	&qEmptyString AS AvgPricePresentation3,
	|	&qEmptyRoomRate AS RoomRate3,
	|	&qEmptyCurrency AS Currency4,
	|	&qEmptyNumber AS Sum4,
	|	&qEmptyString AS SumPresentation4,
	|	&qEmptyNumber AS AvgPrice4,
	|	&qEmptyString AS AvgPricePresentation4,
	|	&qEmptyRoomRate AS RoomRate4,
	|	&qEmptyCurrency AS Currency5,
	|	&qEmptyNumber AS Sum5,
	|	&qEmptyString AS SumPresentation5,
	|	&qEmptyNumber AS AvgPrice5,
	|	&qEmptyString AS AvgPricePresentation5,
	|	&qEmptyRoomRate AS RoomRate5,
	|	&qEmptyCurrency AS Currency6,
	|	&qEmptyNumber AS Sum6,
	|	&qEmptyString AS SumPresentation6,
	|	&qEmptyNumber AS AvgPrice6,
	|	&qEmptyString AS AvgPricePresentation6,
	|	&qEmptyRoomRate AS RoomRate6,
	|	RoomInventory.RoomType.IsVirtual AS IsVirtual,
	|	&qEmptyString AS RoomsAvailableWithTentativePresentation,
	|	&qEmptyString AS BedsAvailableWithTentativePresentation
	|FROM
	|	(SELECT
	|		RoomInventoryBalanceWithTentative.Hotel AS Hotel,
	|		RoomInventoryBalanceWithTentative.RoomType AS RoomType,
	|		RoomInventoryBalanceWithTentative.RoomsAvailable AS RoomsAvailable,
	|		RoomInventoryBalanceWithTentative.BedsAvailable AS BedsAvailable,
	|		RoomInventoryBalanceWithTentative.RoomsAvailableWithTentative AS RoomsAvailableWithTentative,
	|		RoomInventoryBalanceWithTentative.BedsAvailableWithTentative AS BedsAvailableWithTentative
	|	FROM
	|		RoomInventoryBalanceWithTentative AS RoomInventoryBalanceWithTentative
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VirtualRoomTypes.Owner,
	|		VirtualRoomTypes.Ref,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		Catalog.RoomTypes AS VirtualRoomTypes
	|	WHERE
	|		VirtualRoomTypes.IsVirtual
	|		AND NOT VirtualRoomTypes.IsFolder
	|		AND (&qHotelIsEmpty
	|				OR VirtualRoomTypes.Owner IN HIERARCHY (&qHotel))) AS RoomInventory
	|WHERE
	|	NOT RoomInventory.RoomType.DeletionMark
	|	AND (NOT &qWindowViewIsFilled
	|			OR &qWindowViewIsFilled
	|				AND RoomInventory.RoomType.WindowView = &qWindowView)
	|	AND CASE
	|			WHEN &qCUCustomer <> VALUE(Catalog.Customers.EmptyRef)
	|				THEN RoomInventory.RoomsAvailable <> 0
	|						AND RoomInventory.BedsAvailable <> 0
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	RoomInventory.RoomType.SortCode"; 
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qRoomQuota", RoomQuota);
	vQry.SetParameter("qRoomQuotaIsSet", ValueIsFilled(RoomQuota));
	vQry.SetParameter("qDoWriteOff", ?(ValueIsFilled(RoomQuota), RoomQuota.DoWriteOff, False));
	vQry.SetParameter("qDateTimeFrom", cm1SecondShift(CheckInDate));
	vQry.SetParameter("qDateTimeTo", cm0SecondShift(CheckOutDate));
	vQry.SetParameter("qTentativeDateTimeFrom", BegOfDay(CheckInDate));
	vQry.SetParameter("qTentativeDateTimeTo", EndOfDay(CheckOutDate) - 24*3600);
	vQry.SetParameter("qRoomTypesList", vRoomTypes.UnloadColumn("RoomType"));
	vQry.SetParameter("qEmptyNumber", 0);
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qEmptyCurrency", Catalogs.Currencies.EmptyRef());
	vQry.SetParameter("qRoomRate", RoomRate);
	vQry.SetParameter("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	vQry.SetParameter("qWindowViewIsFilled", ValueIsFilled(WindowView));
	vQry.SetParameter("qWindowView", WindowView);
	vQry.SetParameter("qCUCustomer", SessionParameters.CurrentUser.Customer);
	vRoomTypes = vQry.Execute().Unload();
	
	ValueToFormAttribute(vRoomTypes, "RoomTypesList");
	
	For Each vItem In RoomTypesList Do
		vItem.RoomsAvailableWithTentativePresentation = Format(vItem.RoomsAvailable, "NFD=; NG=") + ?(vItem.RoomsAvailable <> vItem.RoomsAvailableWithTentative, " / " + Format(vItem.RoomsAvailableWithTentative, "NFD=; NG="), "");	
		vItem.BedsAvailableWithTentativePresentation = Format(vItem.BedsAvailable, "NFD=; NG=") + ?(vItem.BedsAvailable <> vItem.BedsAvailableWithTentative, " / " + Format(vItem.BedsAvailableWithTentative, "NFD=; NG="), "");	
	EndDo;
	
	// Fill totals
	vRoomsAvailableTotal = vRoomTypes.Total("RoomsAvailable"); 
	vBedsAvailableTotal = vRoomTypes.Total("BedsAvailable");
	vRoomsAvailableWithTentativeTotal = vRoomTypes.Total("RoomsAvailableWithTentative");
	vBedsAvailableWithTentativeTotal = vRoomTypes.Total("BedsAvailableWithTentative");
	Items.RoomTypesListRoomsAvailableWithTentativePresentation.FooterText = Format(vRoomsAvailableTotal, "NFD=; NG=") + ?(vRoomsAvailableTotal <> vRoomsAvailableWithTentativeTotal, " / " + Format(vRoomsAvailableWithTentativeTotal, "NFD=; NG="), "");
	Items.RoomTypesListBedsAvailableWithTentativePresentation.FooterText = Format(vBedsAvailableTotal, "NFD=; NG=") + ?(vBedsAvailableTotal <> vBedsAvailableWithTentativeTotal, " / " + Format(vBedsAvailableWithTentativeTotal, "NFD=; NG="), "");
	
	// Get default customer
	vCustomer = Undefined;
	vCurUser = SessionParameters.CurrentUser;
	If ValueIsFilled(vCurUser.Customer) Then
		vCustomer = vCurUser.Customer;
	EndIf;
	If IsFromObject Then
		// Get room type prices for default room rate and other room rates available for the given guest 
		vRoomRatesList = New ValueList();
		// Get allowed room rates for the case
		vCustomerRoomRatesAreUsed = False; 
		If ValueIsFilled(SelContract) And SelContract.RoomRates.Count() > 0 Then
			vRoomRatesList.LoadValues(SelContract.RoomRates.UnloadColumn("RoomRate"));
		ElsIf ValueIsFilled(SelCustomer) And SelCustomer.RoomRates.Count() > 0 Then
			vRoomRatesList.LoadValues(SelCustomer.RoomRates.UnloadColumn("RoomRate"));
		EndIf;
		r = 0;
		While r < vRoomRatesList.Count() Do
			If Not ValueIsFilled(vRoomRatesList.Get(r).Value) Then
				vRoomRatesList.Delete(r);
			Else
				r = r + 1;
			EndIf;
		EndDo;
		vRoomRatesAllowed = cmGetAllowedRoomRates(CheckInDate, CheckOutDate, CurrentSessionDate(), , Hotel);
		If vRoomRatesAllowed.Count() > 0 Then
			If vRoomRatesList.Count() > 0 Then
				vCustomerRoomRatesAreUsed = True; 
				If vRoomRatesAllowed.Count() > 0 Then
					i = 0;
					While i < vRoomRatesList.Count() Do
						vRoomRateItem = vRoomRatesList.Get(i);
						If vRoomRatesAllowed.FindByValue(vRoomRateItem.Value) = Undefined Then
							If RoomRate <> vRoomRateItem.Value Then
								vRoomRatesList.Delete(i);
								Continue;
							EndIf;
						EndIf;
						i = i + 1;
					EndDo;
				EndIf;
			Else
				vRoomRatesList.LoadValues(vRoomRatesAllowed.UnloadValues());
			EndIf;
		EndIf;
		If Not vCustomerRoomRatesAreUsed Then
			i = 0;
			While i < vRoomRatesList.Count() Do
				vRoomRateRef = vRoomRatesList.Get(i).Value;
				If RoomRate <> vRoomRateRef And 
				   Not vRoomRateRef.IsRackRate And 
				   Not vRoomRateRef.IsOnlineRate And 
				   Not vRoomRateRef.IsHiddenRateForAuthorizedClients And  
				   Not vRoomRateRef.IsRateForCRS Then
					vRoomRatesList.Delete(i);
					Continue;
				EndIf;
				i = i + 1;
			EndDo;
		EndIf;
		If ValueIsFilled(RoomRate) And Not ValueIsFilled(RoomRate.PriceTagType) Then
			// Force current room rate be the first in the list
			vRoomRateItem = vRoomRatesList.FindByValue(RoomRate);
			If vRoomRateItem <> Undefined Then
				vRoomRatesList.Delete(vRoomRateItem);
			EndIf;
			vRoomRatesList.Insert(0, RoomRate);
			
			// Process room rates with price cache filled only 
			If cmRoomRatePricesCacheIsFilled(Hotel, vRoomRatesList, ClientType, CheckInDate, CheckOutDate) Then
				// Get accommodation templates suitable for each room rate / room type
				vAccTemplates = cmGetAccommodationTemplateDetailsByGuestsQuantity(NumberOfAdults, NumberOfKids, vAgeArray, Hotel, True, vChildrenAgesStruct);
				vAccTemplatesList = New ValueList();
				vAccTemplatesList.LoadValues(vAccTemplates.UnloadColumn("AccommodationTemplate"));
				
				// Get prices for each suitable template
				vPrices = cmGetCachedPrices(Hotel, ClientType, BegOfDay(CheckInDate), BegOfDay(CheckOutDate), Catalogs.PriceTags.EmptyRef(), vRoomRatesList, vAccTemplatesList);
				
				vRatesCount = Min(vRoomRatesList.Count(), 7);
				i = 0;
				While i < vRatesCount Do
					vRoomRate = vRoomRatesList.Get(i).Value;
					vRoomRatePresentation = TrimAll(vRoomRate);
				
					// Check room rate is valid period
					If ValueIsFilled(vRoomRate.DateValidFrom) Or ValueIsFilled(vRoomRate.DateValidTo) Then
						If ValueIsFilled(vRoomRate.DateValidFrom) And CheckInDate < vRoomRate.DateValidFrom Then
							i = i + 1;
							Continue;
						EndIf;
						If ValueIsFilled(vRoomRate.DateValidTo) And CheckOutDate > EndOfDay(vRoomRate.DateValidTo) Then
							i = i + 1;
							Continue;
						EndIf;
					EndIf;
					
					vCurAccommodationTemplate = Undefined;
					vRoomTypesToSkip = New ValueList();
				
					For Each vRoomTypesRow In RoomTypesList Do
						vCurRoomType = vRoomTypesRow.RoomType;
						
						// Check room rate restrictions
						If vRoomTypesToSkip.FindByValue(vCurRoomType) <> Undefined Then
							vCurRoomType = Undefined;
							Continue;
						EndIf;
						If Not cmCheckRoomRateRestrictions(Hotel, vRoomRate, vCurRoomType, cm1SecondShift(CheckInDate), cm0SecondShift(CheckOutDate), cmCalculateDuration(vRoomRate, cm1SecondShift(CheckInDate), cm0SecondShift(CheckOutDate))) Then
							vRoomTypesToSkip.Add(vCurRoomType);
							vCurRoomType = Undefined;
							Continue;
						EndIf;
						
						// Get prices for current room rate, room type
						j = 0;
						vGoToOutput = False;
						
						// Filter prices by price tags
						vRoomRateRoomTypePrices = Undefined;
						If ValueIsFilled(vRoomRate.PriceTagType) Then
							vRoomRatePrices = cmGetCachedPricesForPriceTags(Hotel, ClientType, BegOfDay(CheckInDate), BegOfDay(CheckOutDate), vRoomRate, vCurRoomType, vAccTemplatesList);
							vRoomRateRoomTypePrices = vRoomRatePrices.FindRows(New Structure("RoomRate, RoomType", vRoomRate, vCurRoomType));
						Else
							// Get prices for current room rate and room type
							vRoomRateRoomTypePrices = vPrices.FindRows(New Structure("RoomRate, RoomType", vRoomRate, vCurRoomType));
						EndIf;
						If vRoomRateRoomTypePrices <> Undefined And vRoomRateRoomTypePrices.Count() > 0 Then
							vAgeValueTable.FillValues(False, "IsUsed");
							
							vCurAccommodationTemplate = Undefined;
							vCurrency = Catalogs.Currencies.EmptyRef();
							vSum = 0;
							For Each vRoomRateRoomTypePricesRow In vRoomRateRoomTypePrices Do
								j = j + 1;
								vWrkAccommodationTemplate = vRoomRateRoomTypePricesRow.AccommodationTemplate;
								If ValueIsFilled(vWrkAccommodationTemplate) Then
									If vWrkAccommodationTemplate.RoomTypes.Count() <> 0 And vWrkAccommodationTemplate.RoomTypes.Find(vCurRoomType, "RoomType") = Undefined Then
										vDoContinue = True;
										If ValueIsFilled(vCurRoomType) And Not vCurRoomType.IsFolder And ValueIsFilled(vCurRoomType.RoomClass) And vWrkAccommodationTemplate.RoomTypes.Find(vCurRoomType.RoomClass, "RoomClass") <> Undefined Then
											vDoContinue = False;
										EndIf;
										If vDoContinue Then
											Continue;
										EndIf;
									EndIf;
								EndIf;
								If ValueIsFilled(vCurAccommodationTemplate) And vCurAccommodationTemplate <> vRoomRateRoomTypePricesRow.AccommodationTemplate Then
									vGoToOutput = True;
								EndIf;
								If Not vGoToOutput Then
									vCurAccommodationTemplate = vRoomRateRoomTypePricesRow.AccommodationTemplate;
									vCurAccommodationType = vRoomRateRoomTypePricesRow.AccommodationType;
									
									For Each vAgeRow In vAgeValueTable Do
										If Not vAgeRow.IsUsed And vAgeRow.Age > vCurAccommodationType.AllowedClientAgeFrom And vAgeRow.Age < vCurAccommodationType.AllowedClientAgeTo Then
											vAgeRow.IsUsed = True;
											Break;
										EndIf;
									EndDo;
									
									If Not ValueIsFilled(vCurrency) Then
										vCurrency = vRoomRateRoomTypePricesRow.Currency;
									EndIf;
									vSum = vSum + vRoomRateRoomTypePricesRow.Amount;
								EndIf;
							EndDo; // By prices
							
							If vGoToOutput Or j = vRoomRateRoomTypePrices.Count() Or j < vRoomRateRoomTypePrices.Count() And vRoomRateRoomTypePrices.Get(j).AccommodationTemplate <> vCurAccommodationTemplate Then 
								If i = 0  Then
									vRoomTypesRow.Currency = vCurrency;
									vRoomTypesRow.Sum = vSum;
									vRoomTypesRow.SumPresentation = cmFormatSum(vSum, vCurrency);
									vRoomTypesRow.AvgPrice = ?(Duration <> 0, Round(vSum/Duration, 2), 0);
									vRoomTypesRow.AvgPricePresentation = cmFormatSum(vRoomTypesRow.AvgPrice, vCurrency);
									Items.RoomTypesListSumPresentation.Title = vRoomRatePresentation;
									Items.RoomTypesListSumPresentation.Visible = True;
								Else
									vRoomTypesRow["RoomRate" + i] = vRoomRate;
									vRoomTypesRow["Currency" + i] = vCurrency;
									vRoomTypesRow["Sum" + i] = vSum;
									vRoomTypesRow["SumPresentation" + i] = cmFormatSum(vSum, vCurrency);
									vRoomTypesRow["AvgPrice" + i] = ?(Duration <> 0, Round(vSum/Duration, 2), 0);
									vRoomTypesRow["AvgPricePresentation" + i] = cmFormatSum(vRoomTypesRow["AvgPrice" + i], vCurrency);
									Items["RoomTypesListSumPresentation" + i].Title = vRoomRatePresentation;
									Items["RoomTypesListSumPresentation" + i].Visible = True;
								EndIf;
								
								vSum = 0;
								vCurrency = Undefined;
							EndIf;
						EndIf; // Room rate/Room type prices found
					EndDo; // By room types
					i = i + 1;
				EndDo; // By room rates	
			Else
				IsFromObject = False;
			EndIf; // Prices cache is filled
		EndIf; // Room rate is filled
	EndIf; // Is from object	
EndProcedure // BuildList

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesListRefreshRequestProcessing()
	BuildList();
EndProcedure // RoomTypesListRefreshRequestProcessing



#EndRegion

