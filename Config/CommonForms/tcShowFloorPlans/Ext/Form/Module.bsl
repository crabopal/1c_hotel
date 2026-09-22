
#Region Variables

&AtClient
Var LastKidsNumber;

&AtClient
Var PeriodFromChangeMode;

&AtClient
Var FloorPlan;

#EndRegion 

#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	NumberOfKidAgeFields = 8;
	FillHotelList();
	If Parameters.Property("SelHotel") And ValueIsFilled(Parameters.SelHotel) Then
		SelHotel = Parameters.SelHotel;
	Else
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	
	FillDefaultParametersAtServer();
	
	FillFloorPlan();
	FillRoomStatus();
	
	If Parameters.Property("SelFloorPlan") And ValueIsFilled(Parameters.SelFloorPlan) Then
		CurFloorPlan = Parameters.SelFloorPlan;
		SelHotel = CurFloorPlan.Hotel;
	EndIf;
	
	If Parameters.Property("SelRoom") And ValueIsFilled(Parameters.SelRoom) Then
		vRoomDescription = Parameters.SelRoom;
		If TypeOf(vRoomDescription) = Type("CatalogRef.Rooms") Then
			SelHotel = vRoomDescription.Owner;
			vRoomDescription = vRoomDescription.Description;
		EndIf;
		SelRoomDescription = TrimAll(vRoomDescription);
		CurFloorPlan = GetFloorPlansByRoom(SelRoomDescription);
	EndIf; 
	
	// Set hotel color
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
	EndIf;
	If ValueIsFilled(CurFloorPlan) Then
		CurParent = CurFloorPlan.Parent;
	Else
		SelRoomDescription = "";
	EndIf;
	
	Items.TypeCurrentDate.Title = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");
	Items.TypeCurrentDate.Check = True;
	
	Items.Settings.Visible = IsInRole("Administrator");
	
	HTML = Catalogs.FloorPlans.GetTemplate("HTML").GetText();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	LastKidsNumber = 0;
	
	Items.ShowGropPlans.Title = NStr("en = 'No floor plan selected!';de = 'Kein Grundriss ausgewählt!';ru = 'Не выбран план этажа!'");
	AutoUpdateFloorPlanOnChange();
	ChangeFloorPlans(FloorPlans.GetItems());
	If ValueIsFilled(CurFloorPlan) Then
		ShowGropPlans()
	EndIf;
	Items.ShowGropPlans.Title = ?(ValueIsFilled(CurParent), TrimAll(CurParent) + ": ", "") + CurFloorPlan;
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure KidAgeOnChange(pItem)
	RefreshListToolTipVisible();
EndProcedure // KidAgeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	FillFloorPlan();
	ChangeFloorPlans(FloorPlans.GetItems());
EndProcedure // SelHotelOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelHotelClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure HTMLDocumentComplete(pItem)
	FloorPlan = GetHTMLDocument(Items.HTML.Document).floorPlan;
	If FloorPlan = Undefined Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Не найден шаблон плана этажа!';de='No floor plan template found!';en='No floor plan template found!'"));
		Return;
	EndIf;
	
	PrintFloorPlan(False);
EndProcedure // HTMLDocumentComplete

// -----------------------------------------------------------------------------
&AtClient
Procedure HTMLOnClick(pItem, pEventData, pStandardProcessing)
	pStandardProcessing = False;
	vElement = pEventData.Element;
	If vElement = Undefined Then
		vElement = pEventData.Document.activeElement;
	EndIf;
	vHref = Right(pEventData.Href, StrLen(pEventData.Href) - StrFind(pEventData.Href, "/", SearchDirection.FromEnd));
	If ValueIsFilled(pEventData.Href) Then
		If vHref = "RoomInfo" Then
			vId = "";
			
			If ValueIsFilled(vElement.id) Then
				vId = vElement.id;
			Else
				While vElement.parentElement <> Undefined And Not ValueIsFilled(vElement.id) Do
					vElement = vElement.parentElement;
				EndDo;
				vId = vElement.id;
			EndIf;
			
			If Not Items.TypeAvailableRooms.Check Then
				SelRoomDescription = StrReplace(vId, "_divID", "");
				FillRoomInfo(GetRoomInfoByRoom(SelRoomDescription, SelHotel));
			Else 
				vRoom = GetRoomByCode(TrimAll(strReplace(vId, "_divID", "")));
				If ValueIsFilled(vRoom) Then
					AllowedCheckInRoomArr = AllowedCheckInRoom.FindRows(New Structure("Room, IsCheckIn", vRoom, True));
					If AllowedCheckInRoomArr.Count() > 0 Then
						OpenForm("Document.Reservation.Form.tcReservationListForm", New Structure("SelRoom, SelFilterStatus", vRoom, "&ACTIVE"));
						Return;
					EndIf;
					AllowedCheckInRoomArr = AllowedCheckInRoom.FindRows(New Structure("Room", vRoom));
					If AllowedCheckInRoomArr.Count() > 0 Then
						NewReservation(vRoom);
					EndIf;
				EndIf;
			EndIf;
		Else
			GotoURL(pEventData.Href);
		EndIf;
	EndIf;
EndProcedure // HTMLOnClick

// -----------------------------------------------------------------------------
&AtClient
Procedure AutoUpdateFloorPlanOnChange(pItem = Undefined)
	DetachIdleHandler("AttachRefresh");
	
	If AutoUpdateFloorPlan Then
		
		If AutoUpdatePeriodFloorPlan < 10 Then
			AutoUpdatePeriodFloorPlan = 10;
		EndIf;
		
		Items.AutoUpdatePeriodBackgroundJob.Visible = True;
		AttachIdleHandler("AttachRefresh", AutoUpdatePeriodFloorPlan, False);
	Else
		Items.AutoUpdatePeriodBackgroundJob.Visible = False;
	EndIf;
EndProcedure // AutoUpdateFloorPlanOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInDateOnChange(pItem)
	RefreshListToolTipVisible();
	CheckInDateChange();
	Duration = CalculateDurationAtServer(RoomRate, CheckInDate, CheckOutDate);
EndProcedure // CheckInDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(pItem) 
	RefreshListToolTipVisible();
	CheckOutDate = CalculateCheckOutDateAtServer(RoomRate, CheckInDate, Duration);
	CheckInDateChange();
EndProcedure // DurationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutDateOnChange(pItem)
	RefreshListToolTipVisible();
	CheckOutDateChange();
EndProcedure // CheckOutDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	RefreshListToolTipVisible();
EndProcedure // ClientTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	RefreshListToolTipVisible();
EndProcedure // RoomRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfAdultsOnChange(pItem)
	RefreshListToolTipVisible();
EndProcedure // NumberOfAdultsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfKidsOnChange(pItem)
	RefreshListToolTipVisible();
	If NumberOfKids = 0 Then
		Items.AgeDecoration.Visible = False;
		If LastKidsNumber > 0 Then
			For vInd = 1 To LastKidsNumber Do
				Try
					Items["KidAge"+String(vInd)].Visible = False;
					ThisForm["KidAge"+String(vInd)] = 0;
				Except
				EndTry;
			EndDo;
		EndIf;
	Else
		If NumberOfKids > NumberOfKidAgeFields Then
			NumberOfKids = NumberOfKidAgeFields;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Maximum number of children allowed is " + NumberOfKidAgeFields + "!';de='Maximum number of children allowed is " + NumberOfKidAgeFields + "!';ru='Максимально возможное число детей равно " + NumberOfKidAgeFields + "!'"));
		EndIf;
		Items.AgeDecoration.Visible = True;
		If NumberOfKids < LastKidsNumber Then
			For vInd = NumberOfKids + 1 To LastKidsNumber Do
				Try
					Items["KidAge"+String(vInd)].Visible = False;
					ThisForm["KidAge"+String(vInd)] = 0;
				Except
				EndTry;
			EndDo;
		ElsIf NumberOfKids > LastKidsNumber Then
			vNumberOfFieldsToAdd = 0;
			If NumberOfKids > NumberOfKidAgeFields Then
				Try
					For vInd = LastKidsNumber + 1 To NumberOfKidAgeFields Do
						Items["KidAge"+String(vInd)].Visible = True;
						ThisForm["KidAge"+String(vInd)] = 0;
					EndDo;
				Except
				EndTry;
				vNumberOfFieldsToAdd = NumberOfKids - NumberOfKidAgeFields;
				If LastKidsNumber > NumberOfKidAgeFields Then
					vNumberOfFieldsToAdd = vNumberOfFieldsToAdd - (LastKidsNumber - NumberOfKidAgeFields);
				EndIf;
				AddKidAgeAttributes(vNumberOfFieldsToAdd);
			Else
				Try
					For vInd = LastKidsNumber + 1 To NumberOfKids Do
						Items["KidAge"+String(vInd)].Visible = True;
						ThisForm["KidAge"+String(vInd)] = 0;
					EndDo;
				Except
				EndTry;
			EndIf;
		EndIf;
	EndIf;
	LastKidsNumber = NumberOfKids;
EndProcedure // NumberOfKidsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsForFolioSplitOnChange(pItem)
	RefreshListToolTipVisible();
EndProcedure // IsForFolioSplitOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure RoomRateStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.RoomRates.Form.tcChoiceForm", New Structure("ChoiceMode, Hotel, PeriodFrom, PeriodTo, RoomRates", True, SelHotel, PredefinedValue("Catalog.Companies.EmptyRef"), CheckInDate, CheckOutDate, New ValueList, RoomRate), pItem, ThisForm.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // RoomRateStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInTimeOnChange(pItem)
	RefreshListToolTipVisible();
	CheckInTimeChange();
EndProcedure // CheckInTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutTimeOnChange(pItem)
	RefreshListToolTipVisible();
	CheckOutTimeChange();
EndProcedure // CheckOutTimeOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FloorPlansSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	Try
		vCurRow = Items.FloorPlans.CurrentData;
		If vCurRow = Undefined Or Not ValueIsFilled(vCurRow.FloorPlan) Or vCurRow.IsFolder Then
			Return;
		EndIf;
		
		If CurFloorPlan <> vCurRow.FloorPlan Then
			SelRoomDescription = "";
		EndIf;
		
		CurFloorPlan = vCurRow.FloorPlan;
		CurParent = vCurRow.Parent;
		Items.ShowGropPlans.Title = ?(ValueIsFilled(CurParent), TrimAll(CurParent) + ": ", "") + CurFloorPlan;
		PrintFloorPlan(False);
	Except
		vError = ErrorInfo();
		tcCommonFunctionOnClientServer.TextMessage(ErrorProcessing.BriefErrorDescription(vError));
	EndTry;
EndProcedure // FloorPlansSelection

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Refresh(pCommand = Undefined)
	PrintFloorPlan(True);
EndProcedure // Refresh

// --------------------------------------------------------------------------------
&AtClient
Procedure TypeCurrentDate(pCommand)
	If Items.TypeCurrentDate.Check Then
		Return;
	EndIf;
	
	Items.TypeCurrentDate.Check = True;
	Items.TypeAvailableRooms.Check = False;
	Items.GroupRoomStatuses.Visible = True;
	Items.PeriodAndRoomTypeGroup.Visible = False;
	Items.SpaceLeft.Visible = True;
	Items.ClientType.Visible = False;
	Items.RoomRate.Visible = False;
	
	PrintFloorPlan(True);
EndProcedure // TypeCurrentDate

// --------------------------------------------------------------------------------
&AtClient
Procedure TypeAvailableRooms(pCommand)
	If Items.TypeAvailableRooms.Check Then
		Return;
	EndIf;
	
	Items.TypeAvailableRooms.Check = True;
	Items.TypeCurrentDate.Check = False;
	Items.GroupRoomStatuses.Visible = False;
	Items.PeriodAndRoomTypeGroup.Visible = True;
	Items.SpaceLeft.Visible = False;
	Items.ClientType.Visible = True;
	Items.RoomRate.Visible = True;
	
	If Not tcOnServer.cmGetAttributeByRef(SelHotel, "Cruises") Then
		Items.CityFrom.Visible = False;
		Items.CityTo.Visible = False;
		PrintFloorPlan(True);
		Return;
	EndIf;
	
	Items.CityFrom.Visible = True;
	Items.CityTo.Visible = True;
	Items.CheckOutDate.ChoiceButton = False;
	Items.CheckOutDate.DropListButton = True;
	Items.CheckInDate.ChoiceButton = False;
	Items.CheckInDate.DropListButton = True;
	Items.Duration.ReadOnly = True;
	
	Items.CheckInDate.TextEdit = False;
	Items.CheckInTime.TextEdit = False;
	Items.CheckOutDate.TextEdit = False;
	Items.CheckOutTime.TextEdit = False;
	
	FillFirstCruises();
	FillCruisesCityFrom();
	PrintFloorPlan(True);
EndProcedure // TypeAvailableRooms

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowGropPlans(pCommand = Undefined)
	Items.GroupFloorPlans.Visible = Not Items.GroupFloorPlans.Visible;
	Items.ShowGropPlans.Picture = PictureLib.MoveLeft;
	If Items.GroupFloorPlans.Visible Then
		Items.ShowGropPlans.Picture = PictureLib.MoveRight;
	EndIf;
EndProcedure // ShowGropPlans

// --------------------------------------------------------------------------------
&AtClient
Procedure Settings(pCommand)
	OpenForm("Catalog.FloorPlans.ListForm");
EndProcedure // Settings

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomByCode(pRoomCode)
	Return cmGetRoomByCode(pRoomCode);
EndFunction // GetRoomByCode

// -----------------------------------------------------------------------------
&AtClient
Procedure NewReservation(pRoom)
	If AccommodationTypesTable.Count() <= 0 Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Accommodation types table is empty';ru='Заполните таблицу видов размещения';de='Tabelle der Unterbringungstypen ausfüllen'"));
		Return;
	EndIf;
	
	vError = "";
	vWarning = "";
	vParams = GetNewReservationFormParameters(pRoom, vError, vWarning);
	If Not IsBlankString(vError) Then
		tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		Return;
	EndIf;
	
	vParams.Insert("Template", AccommodationTemplate);
	#IF MobileClient Then
		OpenForm("Document.Reservation.Form.mcDocumentForm", vParams, ThisForm);
	#ELSE
		vKeyOperation = "Document.Reservation.Form.tcDocumentForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
		
		OpenForm("Document.Reservation.Form.tcDocumentForm", vParams, ThisForm);
	#ENDIF

	If Not IsBlankString(vWarning) Then
		tcCommonFunctionOnClientServer.TextMessage(vWarning, MessageStatus.Attention);
	EndIf;
EndProcedure // NewReserv

// -----------------------------------------------------------------------------
&AtServer
Function GetNewReservationFormParameters(pRoom, rError = "", rWarning = "")
	rError = "";
	rWarning = "";
	vRowStruct = GetParameters(pRoom);
	If Not pRoom.RoomType.StopSale Then
		Return vRowStruct;
	EndIf;
	
	vRemarks = "";
	If cmIsStopSalePeriod(pRoom.RoomType, cm1SecondShift(CheckInDate), cm0SecondShift(CheckOutDate), vRemarks) Then
		If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
			rError = NStr("en = 'The room type selected is no longer available for sale! Rechoose room type!';de = 'Der ausgewählte Zimmertyp ist nicht mehr zum Verkauf verfügbar! Zimmertyp neu wählen!';ru = 'Выбран тип номера снятый с продажи! Перевыберите тип номера!'") + Chars.LF + vRemarks;
		Else
			rWarning = NStr("en = 'The room type selected is no longer available for sale!';de = 'Der ausgewählte Zimmertyp steht nicht mehr zum Verkauf!';ru = 'Выбран тип номера снятый с продажи!'") + Chars.LF + vRemarks;
		EndIf;
	EndIf;
	Return vRowStruct;
EndFunction // GetNewReservationFormParameters

// -----------------------------------------------------------------------------
&AtServer
Function GetParameters(pRoom)
	vRowStruct = Undefined;
	vCompany = Catalogs.Companies.EmptyRef();
	vCurHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) Then
		vCompany = SessionParameters.CurrentUser.Company;
	ElsIf ValueIsFilled(vCurHotel.RoomRate) And ValueIsFilled(vCurHotel.RoomRate.Company) Then
		vCompany = vCurHotel.RoomRate.Company;
	ElsIf ValueIsFilled(pRoom.RoomType) And ValueIsFilled(pRoom.RoomType.Company) Then
		vCompany = pRoom.RoomType.Company;
	ElsIf ValueIsFilled(vCurHotel.Company) Then
		vCompany = vCurHotel.Company;
	EndIf;
	vKidsAges = New Array();
	For i = 1 To NumberOfKids Do
		vKidsAges.Add(ThisObject["KidAge" + i]);
	EndDo;
	vAccommodationTypesArr = AccommodationTypesTable.FindRows(New Structure("RoomType", pRoom.RoomType));
	If vAccommodationTypesArr.Count() > 0 Then
		vNumberOfPersons = 1;
		vRowStruct = New Structure("Hotel, Room, RoomType, RoomQuantity, AccommodationType, NumberOfPersons, CheckInDate, Duration, CheckOutDate, RoomRate, ClientType, Company, Posted, DeletionMark, IsForFolioSplit, NumberOfAdults, NumberOfKids, KidsAges", 
		vCurHotel, pRoom, pRoom.RoomType, 1, vAccommodationTypesArr.Get(0).AccommodationType, vNumberOfPersons, CheckInDate, Duration, CheckOutDate, RoomRate, ClientType, vCompany, False, False, IsForFolioSplit, NumberOfAdults, NumberOfKids, vKidsAges);
	Else
		vRowStruct = New Structure("Hotel, Room, RoomType, RoomQuantity, AccommodationType, CheckInDate, Duration, CheckOutDate, RoomRate, ClientType, Company, IsForFolioSplit, NumberOfAdults, NumberOfKids, KidsAges", 
		vCurHotel, pRoom, pRoom.RoomType, 1, Undefined, CheckInDate, Duration, CheckOutDate, RoomRate, ClientType, vCompany, IsForFolioSplit, NumberOfAdults, NumberOfKids, vKidsAges);
	EndIf;
	Return vRowStruct;
EndFunction // GetParameters

// ----------------------------------------------------------------------------
&AtServer
Procedure FillDefaultParametersAtServer()
	RoomRate = SelHotel.RoomRate;
	vCiT = cmGetDefaultCheckInTime(RoomRate);
	vCoT = cmGetDefaultCheckOutTime(RoomRate);
	CheckInDate = CurrentSessionDate();
	If (vCiT - BegOfDay(vCiT)) > (CheckInDate - BegOfDay(CheckInDate)) Then
		CheckInDate = cm1SecondShift(BegOfDay(CheckInDate) + (vCiT - BegOfDay(vCiT)));
	EndIf; 
	CheckOutDate = cm0SecondShift(BegOfDay(CheckInDate + 24*3600) + (vCoT - BegOfDay(vCoT)));
	CheckInTime = CheckInDate;
	CheckOutTime = CheckOutDate;
	Duration = CalculateDurationAtServer(RoomRate, CheckInDate, CheckOutDate);
	NumberOfAdults = 1;
EndProcedure // FillDefaultParametersAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetFloorPlansByRoom(pRoomDescription)
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	FloorPlans.Ref AS Ref
	|FROM
	|	Catalog.FloorPlans AS FloorPlans
	|WHERE
	|	NOT FloorPlans.DeletionMark
	|	AND NOT FloorPlans.IsFolder
	|	AND FloorPlans.Areas LIKE &qRoomDescription
	|	AND FloorPlans.Hotel = &qHotel";
	vQ.SetParameter("qRoomDescription", "%state=""" + pRoomDescription + """%");
	vQ.SetParameter("qHotel", SelHotel);
	vSelect = vQ.Execute().Select();
	If vSelect.Next() Then
		Return vSelect.Ref;
	EndIf;
	Return Catalogs.FloorPlans.EmptyRef();
EndFunction // CheckFloorPlansByRoom

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeFloorPlans(pFloorPlansCollection)
	If pFloorPlansCollection.Count() <= 0 Then
		Return;
	EndIf;
	
	For Each vRow In pFloorPlansCollection Do
		ChangeFloorPlans(vRow.GetItems());
		If ValueIsFilled(vRow.FloorPlan) Then
			vRow.Parent = vRow.FloorPlan;
		ElsIf Not ValueIsFilled(vRow.Parent) Then
			vRow.Parent = NStr("en = 'Plans';de = 'Pläne';ru = 'Планы'");
		EndIf;
		Items.FloorPlans.Expand(vRow.GetID());
	EndDo;
EndProcedure // ChangeFloorPlans

// -----------------------------------------------------------------------------
&AtServer
Procedure FillHotelList()
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	Hotels.Ref AS Hotel
	|FROM
	|	Catalog.Hotels AS Hotels
	|WHERE
	|	NOT Hotels.DeletionMark
	|	AND NOT Hotels.IsFolder";
	Items.SelHotel.ChoiceList.Clear();
	Items.SelHotel.ChoiceList.LoadValues(vQ.Execute().Unload().UnloadColumn("Hotel"));
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFloorPlan()
	FloorPlans.GetItems().Clear();
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	FloorPlans.Ref AS FloorPlan,
	|	FloorPlans.Parent AS Parent,
	|	FloorPlans.IsFolder AS IsFolder
	|FROM
	|	Catalog.FloorPlans AS FloorPlans
	|WHERE
	|	NOT FloorPlans.DeletionMark
	|	AND CASE
	|			WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
	|				THEN FloorPlans.Hotel = &qHotel
	|			ELSE TRUE
	|		END
	|	AND NOT FloorPlans.IsFolder
	|
	|ORDER BY
	|	FloorPlans.SortCode
	|TOTALS BY
	|	Parent HIERARCHY";
	vQ.SetParameter("qHotel", SelHotel);
	ValueToFormAttribute(vQ.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy), "FloorPlans");
EndProcedure // FillFloorPlan

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomStatus()
	While Items.GroupRoomStatuses.ChildItems.Count() > 0 Do
		Items.Delete(Items.GroupRoomStatuses.ChildItems[0]);
	EndDo;
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	RoomStatuses.Ref AS Ref
	|FROM
	|	Catalog.RoomStatuses AS RoomStatuses
	|WHERE
	|	NOT RoomStatuses.DeletionMark
	|	AND NOT RoomStatuses.IsFolder
	|	AND (RoomStatuses.Hotel = &qHotel
	|			OR RoomStatuses.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|
	|ORDER BY
	|	RoomStatuses.SortCode";
	vQ.SetParameter("qHotel", SelHotel);
	vResult = vQ.Execute().Unload();
	vNumber = 0;
	For Each vRow In vResult Do
		vStatus = vRow.Ref;
		vNewItem = Items.Add("RoomStatus_" + TrimAll(vNumber), Тип("FormDecoration"), Items.GroupRoomStatuses);
		vNewItem.Type = FormDecorationType.Label;
		vNewItem.Title = vStatus;
		vColor = vStatus.Color.Get();
		If vColor <> Undefined Then
			vNewItem.BackColor = vColor;
		Else
			vNewItem.BackColor = New Color();
		EndIf;
		vNewItem.Font = New Font(, 10, True);
		vNumber = vNumber + 1;
	EndDo;
EndProcedure // FillRoomStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintFloorPlanAttach() Export
	PrintFloorPlan(True);
EndProcedure // PrintFloorPlanAttach

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintFloorPlan(pUpdate)
	If Not ValueIsFilled(SelHotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Specify a hotel!';de = 'Füllen Sie das Hotel auf!';ru = 'Укажите гостиницу!'"));
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurFloorPlan) Then
		Return;
	EndIf;
	
	vCurFloorPlanArr = tcOnServer.cmGetAtributeAsArray(CurFloorPlan);
	If IsBlankString(vCurFloorPlanArr.ImageInBase64) Or IsBlankString(vCurFloorPlanArr.Areas) Then
		Return;
	EndIf;
	
	Try
		If Not pUpdate Or Items.TypeAvailableRooms.Check Then
			SelRoomDescription = "";
			FillRoomInfo(Undefined);
		EndIf;
		
		If Not pUpdate Then
			FloorPlan.unbindMap();
			FloorPlan.setImg(StrTemplate("data:image/%1;base64, %2", ?(IsBlankString(vCurFloorPlanArr.ImageType), "png", vCurFloorPlanArr.ImageType), vCurFloorPlanArr.ImageInBase64));
			FloorPlan.setMap(vCurFloorPlanArr.Areas);
			FloorPlan.buildMap();
			AttachIdleHandler("PrintFloorPlanAttach", 0.1, True);
			Return;
		EndIf;
		
		vArr = New Array;
		For i = 0 To FloorPlan.strItems.length -1 Do
			vArr.Add(FloorPlan.getDataArr(FloorPlan.strItems, i));
		EndDo;
		
		FloorPlan.notUseSelect = Items.TypeAvailableRooms.Check;
		If Items.TypeAvailableRooms.Check Then
			vFloorPlanData = FillAvailableRooms(vArr);
		Else
			vFloorPlanData = FillDocumentsList(SelHotel, vArr);
		EndIf;
		
		FloorPlan.setData(GetHTMLObj(vFloorPlanData), False);
		Items.RefreshListToolTip.Visible = False;
		
		If Not Items.TypeAvailableRooms.Check Then
			FillRoomInfo(GetRoomInfoByRoom(SelRoomDescription, SelHotel));
		EndIf;
	Except
		vErr = ErrorInfo();
		tcCommonFunctionOnClientServer.TextMessage(ErrorProcessing.BriefErrorDescription(vErr));
	EndTry;
EndProcedure // PrintFloorPlan

// ----------------------------------------------------------------------------
&AtClient
Function GetHTMLObj(pData)
	vObj = Undefined;
	If TypeOf(pData) = Type("Structure") Or TypeOf(pData) = Type("Map") Then
		vObj = FloorPlan.createObj();
		For Each vItem In pData Do
			If TypeOf(vItem.Value) = Type("Structure") Or TypeOf(vItem.Value) = Type("Map") Or TypeOf(vItem.Value) = Type("Array") Then
				FloorPlan.setToObj(vObj, vItem.Key, GetHTMLObj(vItem.Value));
			Else
				FloorPlan.setToObj(vObj, vItem.Key, vItem.Value);
			EndIf;
		EndDo;
	ElsIf TypeOf(pData) = Type("Array") Then
		vObj = FloorPlan.createArr();
		For Each vItem In pData Do
			If TypeOf(vItem) = Type("Structure") Or TypeOf(vItem) = Type("Map") Or TypeOf(vItem) = Type("Array") Then
				FloorPlan.setToArr(vObj, GetHTMLObj(vItem));
			Else
				FloorPlan.setToArr(vObj, vItem);
			EndIf;
		EndDo;
	EndIf;
	Return vObj;
EndFunction // getHTMLObj

// -----------------------------------------------------------------------------
&AtClient
Function GetHTMLDocument(pDocument)
	vDoc = pDocument.parentWindow;
	If vDoc = Undefined Then
		vDoc = pDocument.defaultView;
	EndIf;
	Return vDoc;
EndFunction // GetHTMLDocument

// -----------------------------------------------------------------------------
&AtServer
Function FillAvailableRooms(pRoomList)
	AccommodationTypesTable.Clear();
	AllowedCheckInRoom.Clear();
	
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	Rooms.Ref AS Ref,
	|	Rooms.RoomType AS RoomType
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	Rooms.Owner = &qHotel
	|	AND Rooms.Description IN(&qRooms)";
	vQ.SetParameter("qHotel", SelHotel);
	vQ.SetParameter("qRooms", pRoomList);
	vResult = vQ.Execute().Unload();
	vRoomsList = vResult.UnloadColumn(0);
	
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	Docs.Number AS Number,
	|	Docs.GuestGroup AS GuestGroup,
	|	MIN(Docs.CheckInDate) AS CheckInDate,
	|	MAX(Docs.CheckOutDate) AS CheckOutDate,
	|	Docs.Room AS Room,
	|	Docs.IsCheckIn AS IsCheckIn
	|FROM
	|	(SELECT
	|		Accommodation.Number AS Number,
	|		Accommodation.GuestGroup AS GuestGroup,
	|		Accommodation.CheckInDate AS CheckInDate,
	|		Accommodation.CheckOutDate AS CheckOutDate,
	|		Accommodation.Room AS Room,
	|		1 AS IsCheckIn
	|	FROM
	|		Document.Accommodation AS Accommodation
	|	WHERE
	|		Accommodation.AccommodationStatus.IsActive
	|		AND Accommodation.Posted
	|		AND Accommodation.Hotel = &qHotel
	|		AND Accommodation.CheckInDate < &qCheckOutDate
	|		AND Accommodation.CheckOutDate > &qCheckInDate
	|		AND Accommodation.Room IN(&qRoomsList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Reservation.Number,
	|		Reservation.GuestGroup,
	|		Reservation.CheckInDate,
	|		Reservation.CheckOutDate,
	|		Reservation.Room,
	|		0
	|	FROM
	|		Document.Reservation AS Reservation
	|	WHERE
	|		(Reservation.ReservationStatus.IsActive
	|				OR Reservation.ReservationStatus.IsPreliminary)
	|		AND NOT Reservation.ReservationStatus.IsCheckIn
	|		AND Reservation.Posted
	|		AND Reservation.Hotel = &qHotel
	|		AND Reservation.CheckInDate < &qCheckOutDate
	|		AND Reservation.CheckOutDate > &qCheckInDate
	|		AND Reservation.Room IN(&qRoomsList)) AS Docs
	|
	|GROUP BY
	|	Docs.Number,
	|	Docs.GuestGroup,
	|	Docs.Room,
	|	Docs.IsCheckIn
	|
	|ORDER BY
	|	CheckInDate,
	|	CheckOutDate";
	vQ.SetParameter("qHotel", SelHotel);
	vQ.SetParameter("qCheckInDate", CheckInDate);
	vQ.SetParameter("qCheckOutDate", CheckOutDate);
	vQ.SetParameter("qRoomsList", vRoomsList);
	
	vDocsList = vQ.Execute().Unload();
	
	vRoomTypesList = New ValueList;
	For Each vRoomRow In vResult Do
		If vRoomTypesList.FindByValue(vRoomRow.RoomType) = Undefined Then 
			If vDocsList.FindRows(New Structure("Room", vRoomRow.Ref)).Count() = 0 Then
				vRoomTypesList.Add(vRoomRow.RoomType);
			EndIf;
		EndIf;
	EndDo;
	
	vPrices = Undefined;
	If ValueIsFilled(RoomRate) Then 
		vRoomRatesList = New ValueList();
		vRoomRatesList.Add(RoomRate);
		If cmRoomRatePricesCacheIsFilled(SelHotel, vRoomRatesList, ClientType, CheckInDate, CheckOutDate) Then
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
			
			vAccTemplates = cmGetAccommodationTemplateDetailsByGuestsQuantity(NumberOfAdults, NumberOfKids, vAgeArray, SelHotel, Not IsForFolioSplit, Undefined);
			vAccTemplatesList = New ValueList();
			If Not IsForFolioSplit Then
				vAccTemplatesList.LoadValues(vAccTemplates.UnloadColumn("AccommodationTemplate"));
			Else
				// Try to search folio split templates
				For Each vAccTemplatesRow In vAccTemplates Do
					If ValueIsFilled(vAccTemplatesRow.AccommodationTemplate) And vAccTemplatesRow.AccommodationTemplate.IsForFolioSplit Then
						vAccTemplatesList.Add(vAccTemplatesRow.AccommodationTemplate);
					EndIf;
				EndDo;
				// If nothing special was found then use normal templates
				If vAccTemplatesList.Count() = 0 Then
					vAccTemplatesList.LoadValues(vAccTemplates.UnloadColumn("AccommodationTemplate"));
				EndIf;
			EndIf;
			
			vPrices = cmGetCachedPricesForPriceTags(SelHotel, ClientType, BegOfDay(CheckInDate), BegOfDay(CheckOutDate), vRoomRatesList, vRoomTypesList, vAccTemplatesList);
			
			For Each vPricesRow In vPrices Do
				vNewRow = AccommodationTypesTable.Add();
				vNewRow.AccommodationType = vPricesRow.AccommodationType;
				vNewRow.RoomType = vPricesRow.RoomType;
			EndDo;
		EndIf;
	EndIf;
	
	vData = New Map;
	For Each vRoomRow In vResult Do
		vDataStr = New Structure;
		vRoom = vRoomRow.Ref;
		vRoomType = vRoomRow.RoomType;
		vDocsArr = vDocsList.FindRows(New Structure("Room", vRoom));
		If vDocsArr.Count() > 0 Then 
			vDocsIsCheckIn = vDocsList.FindRows(New Structure("Room, IsCheckIn", vRoom, 1)).Count() > 0;
			
			If vDocsIsCheckIn Then
				vCheckInColor = SelHotel.CheckInColor.Get();
				If vCheckInColor <> Undefined Then
					vColor = vCheckInColor;
				EndIf;
			Else
				vReservationColor = SelHotel.ReservationColor.Get();
				If vReservationColor <> Undefined Then
					vColor = vReservationColor;
				EndIf;
			EndIf;
			
			vDataStr.Insert("color", "");
			If vColor <> Undefined Then
				vColor = tcOnServer.ColorToHex(vColor);
				vDataStr.color = Lower(StrReplace(vColor, "#", ""));
			EndIf;
			
			vOccupied = New Array;
			
			For Each vDocRow In vDocsArr Do
				vOccupied.Add(Format(vDocRow.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vDocRow.CheckOutDate, "DF=dd.MM.yyyy"));
			EndDo;
			
			vDataStr.Insert("occupied", ?(vOccupied.Count() > 0, New Structure("guests", vOccupied), Undefined));
			vDataStr.Insert("status", "");
			vNewRowAllowedCheckInRoom = AllowedCheckInRoom.Add();
			vNewRowAllowedCheckInRoom.Room = vRoom;
			vNewRowAllowedCheckInRoom.IsCheckIn = True;
		Else 
			vOccupied = New Array; 
			If vPrices <> Undefined Then 
				vRoomRateRoomTypePrices = vPrices.FindRows(New Structure("RoomType", vRoomType));
				If vRoomRateRoomTypePrices.Count() > 0 Then
					vCurrency = Catalogs.Currencies.EmptyRef();
					vSum = 0;
					
					For Each vRoomRateRoomTypePricesRow In vRoomRateRoomTypePrices Do
						If Not ValueIsFilled(vCurrency) Then
							vCurrency = vRoomRateRoomTypePricesRow.Currency;
						EndIf;
						vSum = vSum + vRoomRateRoomTypePricesRow.Amount;
					EndDo;
					
					vOccupied.Add(cmFormatSum(vSum, vCurrency));
					vDataStr.Insert("status", NStr("en = 'New reservation';de = 'Neue Reservierung';ru = 'Забронировать'"));
					vNewRowAllowedCheckInRoom = AllowedCheckInRoom.Add();
					vNewRowAllowedCheckInRoom.Room = vRoom;
				Else
					vOccupied.Add("N/A");
					vDataStr.Insert("status", "");
				EndIf;
			Else
				vOccupied.Add("N/A");
				vDataStr.Insert("status", "");
			EndIf;
			vDataStr.Insert("occupied", ?(vOccupied.Count() > 0, New Structure("guests", vOccupied), Undefined));
			
			vDataStr.Insert("color", Lower(StrReplace(tcOnServer.ColorToHex(WebColors.Snow), "#", "")));
		EndIf;
		vDataStr.Insert("room", TrimAll(vRoom.Description) + " " + TrimAll(vRoomType.Code));
		
		vData.Insert(TrimAll(vRoom.Description), vDataStr);
	EndDo;
	Return vData;
EndFunction // FillAvailableRooms

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshListToolTipVisible() 
	Items.RefreshListToolTip.Visible = True;
	RefreshListToolTip = NStr("en='Prices are not relevant. Refresh the list please';
	|ru='Цены не актуальны. Обновите список';
	|de='Preise sind nicht relevant. Aktualisieren Sie die Liste'");
EndProcedure // RefreshListToolTipVisible

// -----------------------------------------------------------------------------
&AtServerNoContext
Function FillDocumentsList(pHotel, pRoomList)
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	Rooms.Ref AS Room,
	|	Rooms.Description AS RoomDescription,
	|	ISNULL(RoomTypes.Code, """") AS RoomTypeCode,
	|	RoomStatuses.ColorHexString AS RoomColor
	|INTO RoomsList
	|FROM
	|	Catalog.Rooms AS Rooms
	|		LEFT JOIN Catalog.RoomStatuses AS RoomStatuses
	|		ON Rooms.RoomStatus = RoomStatuses.Ref
	|		LEFT JOIN Catalog.RoomTypes AS RoomTypes
	|		ON Rooms.RoomType = RoomTypes.Ref
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND Rooms.Owner = &qHotel
	|	AND Rooms.Description IN(&qRooms)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.Room AS Room,
	|	RoomInventory.Guest AS Guest,
	|	Clients.MilitaryRank AS MilitaryRank,
	|	RoomInventory.ClientType AS ClientType,
	|	RoomInventory.AccommodationTemplate AS AccommodationTemplate,
	|	&qExpectedCheckInClause AS Clause,
	|	0 AS SortCode
	|INTO DocumentList
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|		INNER JOIN RoomsList AS RoomsList
	|		ON RoomInventory.Room = RoomsList.Room
	|		LEFT JOIN Catalog.Clients AS Clients
	|		ON RoomInventory.Guest = Clients.Ref
	|WHERE
	|	RoomInventory.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|	AND RoomInventory.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RoomInventory.CheckInDate = RoomInventory.PeriodFrom
	|	AND BEGINOFPERIOD(RoomInventory.PeriodFrom, DAY) = &qDate
	|	AND NOT RoomInventory.IsCheckIn
	|	AND RoomInventory.IsReservation
	|
	|UNION ALL
	|
	|SELECT
	|	ReservationList.Room,
	|	ReservationList.Guest,
	|	Clients.MilitaryRank,
	|	ReservationList.ClientType,
	|	ReservationList.AccommodationTemplate,
	|	&qExpectedCheckInClause,
	|	1
	|FROM
	|	Document.Reservation AS ReservationList
	|		INNER JOIN RoomsList AS RoomsList
	|		ON ReservationList.Room = RoomsList.Room
	|		INNER JOIN Catalog.ReservationStatuses AS ReservationStatuses
	|		ON ReservationList.ReservationStatus = ReservationStatuses.Ref
	|			AND (ReservationStatuses.IsPreliminary)
	|		LEFT JOIN Catalog.Clients AS Clients
	|		ON ReservationList.Guest = Clients.Ref
	|WHERE
	|	ReservationList.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|	AND BEGINOFPERIOD(ReservationList.CheckInDate, DAY) = &qDate
	|
	|UNION ALL
	|
	|SELECT
	|	RoomInventory.Room,
	|	RoomInventory.Guest,
	|	Clients.MilitaryRank,
	|	RoomInventory.ClientType,
	|	RoomInventory.AccommodationTemplate,
	|	&qExpectedCheckOutClause,
	|	2
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|		INNER JOIN RoomsList AS RoomsList
	|		ON RoomInventory.Room = RoomsList.Room
	|		LEFT JOIN Catalog.Clients AS Clients
	|		ON RoomInventory.Guest = Clients.Ref
	|WHERE
	|	RoomInventory.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|	AND RoomInventory.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RoomInventory.CheckOutDate = RoomInventory.PeriodTo
	|	AND BEGINOFPERIOD(RoomInventory.PeriodTo, DAY) = &qDate
	|	AND RoomInventory.IsInHouse
	|	AND RoomInventory.IsCheckOut
	|	AND RoomInventory.IsAccommodation
	|
	|UNION ALL
	|
	|SELECT
	|	RoomInventory.Room,
	|	RoomInventory.Guest,
	|	Clients.MilitaryRank,
	|	RoomInventory.ClientType,
	|	RoomInventory.AccommodationTemplate,
	|	&qInHouseClause,
	|	3
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|		INNER JOIN RoomsList AS RoomsList
	|		ON RoomInventory.Room = RoomsList.Room
	|		LEFT JOIN Catalog.Clients AS Clients
	|		ON RoomInventory.Guest = Clients.Ref
	|WHERE
	|	RoomInventory.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|	AND RoomInventory.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RoomInventory.CheckInDate = RoomInventory.PeriodFrom
	|	AND &qDate BETWEEN BEGINOFPERIOD(RoomInventory.CheckInDate, DAY) AND BEGINOFPERIOD(RoomInventory.CheckOutDate, DAY)
	|	AND BEGINOFPERIOD(RoomInventory.CheckInDate, DAY) <> &qDate
	|	AND BEGINOFPERIOD(RoomInventory.CheckOutDate, DAY) <> &qDate
	|	AND RoomInventory.IsCheckIn
	|	AND RoomInventory.IsInHouse
	|	AND RoomInventory.IsAccommodation
	|
	|UNION ALL
	|
	|SELECT
	|	RoomInventory.Room,
	|	RoomInventory.Guest,
	|	Clients.MilitaryRank,
	|	RoomInventory.ClientType,
	|	RoomInventory.AccommodationTemplate,
	|	&qCheckedInClause,
	|	4
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|		INNER JOIN RoomsList AS RoomsList
	|		ON RoomInventory.Room = RoomsList.Room
	|		LEFT JOIN Catalog.Clients AS Clients
	|		ON RoomInventory.Guest = Clients.Ref
	|WHERE
	|	RoomInventory.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|	AND RoomInventory.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RoomInventory.CheckInDate = RoomInventory.PeriodFrom
	|	AND BEGINOFPERIOD(RoomInventory.PeriodFrom, DAY) = &qDate
	|	AND RoomInventory.IsCheckIn
	|	AND RoomInventory.IsInHouse
	|	AND RoomInventory.IsAccommodation
	|
	|UNION ALL
	|
	|SELECT
	|	RoomInventory.Room,
	|	RoomInventory.Guest,
	|	Clients.MilitaryRank,
	|	RoomInventory.ClientType,
	|	RoomInventory.AccommodationTemplate,
	|	&qCheckedOutClause,
	|	5
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|		INNER JOIN RoomsList AS RoomsList
	|		ON RoomInventory.Room = RoomsList.Room
	|		LEFT JOIN Catalog.Clients AS Clients
	|		ON RoomInventory.Guest = Clients.Ref
	|WHERE
	|	RoomInventory.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|	AND RoomInventory.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RoomInventory.CheckOutDate = RoomInventory.PeriodTo
	|	AND BEGINOFPERIOD(RoomInventory.PeriodTo, DAY) = &qDate
	|	AND NOT RoomInventory.IsInHouse
	|	AND RoomInventory.IsCheckOut
	|	AND RoomInventory.IsAccommodation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomsList.Room AS Room,
	|	RoomsList.RoomDescription AS RoomDescription,
	|	RoomsList.RoomTypeCode AS RoomTypeCode,
	|	RoomsList.RoomColor AS RoomColor,
	|	DocumentList.Guest AS Guest,
	|	DocumentList.MilitaryRank AS MilitaryRank,
	|	DocumentList.ClientType AS ClientType,
	|	DocumentList.AccommodationTemplate AS AccommodationTemplate,
	|	DocumentList.Clause AS Clause,
	|	ISNULL(DocumentList.SortCode, 0) AS SortCode
	|FROM
	|	RoomsList AS RoomsList
	|		LEFT JOIN DocumentList AS DocumentList
	|		ON RoomsList.Room = DocumentList.Room
	|
	|ORDER BY
	|	SortCode";
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qRooms", pRoomList);
	vQuery.SetParameter("qDate", BegOfDay(CurrentSessionDate()));
	vQuery.SetParameter("qExpectedCheckInClause", NStr("en='Arrival today';ru='На заезде';de='Anreise heute'"));
	vQuery.SetParameter("qCheckedInClause", NStr("en='Checked-in';ru='Заехал';de='Checked-in'"));
	vQuery.SetParameter("qInHouseClause", NStr("en='In house';ru='Занят';de='In house'"));
	vQuery.SetParameter("qExpectedCheckOutClause", NStr("en='Departure today';ru='На выезде';de='Abreise heute'"));
	vQuery.SetParameter("qCheckedOutClause", NStr("en='Checked-out';ru='Выехал';de='Checked-out'"));
	vResult = vQuery.Execute().Unload();
	
	vRooms = vResult.Copy(, "Room");
	vRooms.GroupBy("Room");
	
	vData = New Map;
	For Each vRoomRow In vRooms Do
		vDataStr = New Structure;
		
		vRoomInfoArr = vResult.FindRows(New Structure("Room", vRoomRow.Room));
		If vRoomInfoArr.Count() <= 0 Then
			Continue;
		EndIf;
		
		vSelect = vRoomInfoArr[0];
		
		vDataStr.Insert("room", TrimAll(vSelect.RoomDescription) + " " + TrimAll(vSelect.RoomTypeCode));
		
		vOccupied = New Array;
		
		If ValueIsFilled(vSelect.AccommodationTemplate) Then
			vOccupied.Add(TrimAll(vSelect.AccommodationTemplate));
		EndIf;
		If ValueIsFilled(vSelect.Guest) Then
			vOccupied.Add(TrimAll(vSelect.Guest));
			If ValueIsFilled(vSelect.ClientType) Then
				vOccupied.Add("<b>" + TrimAll(vSelect.ClientType) + "</b>");
			EndIf;
			If ValueIsFilled(vSelect.MilitaryRank) Then
				vOccupied.Add(vSelect.MilitaryRank);
			EndIf;
		EndIf;
		vDataStr.Insert("occupied", ?(vOccupied.Count() > 0, New Structure("guests", vOccupied), Undefined));
		
		vDataStr.Insert("status", GetStatus(vRoomInfoArr));
		
		vDataStr.Insert("color", "");
		If Not IsBlankString(vSelect.RoomColor)Then
			vDataStr.color = Lower(StrReplace(vSelect.RoomColor, "#", ""));
		Else
			vDataStr.color = "fffff0";
		EndIf;
		
		vData.Insert(TrimAll(vSelect.RoomDescription), vDataStr);
	EndDo;
	Return vData;
EndFunction // FillDocumentsList

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetStatus(pRows)
	vFooter = "";
	For Each vRow In pRows Do
		If IsBlankString(vRow.Clause) Or StrFind(vFooter, vRow.Clause) <> 0 Then
			Continue;
		EndIf;
		
		vFooter = vFooter + ?(IsBlankString(vFooter), "", ", ") + vRow.Clause;
	EndDo;
	Return vFooter;
EndFunction // GetStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure AttachRefresh() Export
	If IsInputAvailable() Then
		Refresh();
	EndIf;
EndProcedure // AttachRefresh

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomRefByDescription(pDescription, pHotel)
	vRoom = Catalogs.Rooms.EmptyRef();
	If IsBlankString(pDescription) Then
		Return vRoom;
	EndIf;
	
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	Rooms.Ref AS Ref
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND Rooms.Description = &qDescription
	|	AND (Rooms.Owner = &qHotel
	|			OR Rooms.Owner = VALUE(Catalog.Hotels.EmptyRef))";
	vQ.SetParameter("qDescription", TrimAll(pDescription));
	vQ.SetParameter("qHotel", pHotel);
	vSelect = vQ.Execute().Select();
	
	If vSelect.Next() Then
		Return vSelect.Ref;
	EndIf;
	
	Return vRoom;
EndFunction // GetRoomRefByUUID

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomInfoByRoom(pRoomDescription, pHotel)
	vResult = Undefined;
	vRoom = GetRoomRefByDescription(pRoomDescription, pHotel);
	If ValueIsFilled(vRoom) Then
		vResult = New Array;
		vRoomType = "";
		If ValueIsFilled(vRoom.RoomType) Then
			vRoomType = TrimAll(vRoom.RoomType.Code);
		EndIf;
		vRoomInfo = ?(ValueIsFilled(vRoomType), TrimAll(vRoom.Description) + " " + vRoomType, TrimAll(vRoom.Description));
		If ValueIsFilled(TrimAll(vRoom.Remarks)) Then
			vRoomInfo = vRoomInfo + "</br>" + TrimAll(vRoom.Remarks);
		Else
			vRoomInfo = vRoomInfo + "</br>";
		EndIf;
		vResult.Add(New Structure("Column1, Column2", NStr("en = 'Room:';de = 'Zimmer:';ru = 'Номер:'"), vRoomInfo));
		vRoomStatus = "";
		If ValueIsFilled(vRoom.RoomStatus) Then
			vRoomStatus = TrimAll(vRoom.RoomStatus.Description);
		Else
			vRoomStatus = vRoomStatus + "</br>";
		EndIf;
		vResult.Add(New Structure("Column1, Column2", NStr("en = 'Room status:';de = 'Zimmerstatus:';ru = 'Статус номера:'"), vRoomStatus));
		vResult.Add(New Structure("Column1, Column2", NStr("en = 'Lives:';de = 'Leben:';ru = 'Проживает:'"), GetAccommodation(vRoom, pHotel)));
		vEmployeeOperationInfo = GetEmployeeOperation(vRoom, pHotel);
		vResult.Add(New Structure("Column1, Column2", NStr("en = 'Operation:';de = 'Arbeit:';ru = 'Работа:'"), vEmployeeOperationInfo.Operation));
		vResult.Add(New Structure("Column1, Column2", NStr("en = 'Employee:';de = 'Angestellter:';ru = 'Горничная:'"), vEmployeeOperationInfo.Employee));
		vResult.Add(New Structure("Column1, Column2", NStr("en = 'Tasks:';de = 'Aufgaben:';ru = 'Задачи:'"), GetTasks(vRoom)));
		vResult.Add(New Structure("Column1, Column2", NStr("en = 'Blocking:';de = 'Blockierung:';ru = 'Блокировки:'"), GetBlocking(vRoom, pHotel)));
		vResult.Add(New Structure("Column1, Column2", NStr("en = 'Next check-in:';de = 'Nächste Anmeldung:';ru = 'Следующий заезд:'"), GetReservation(vRoom, pHotel)));
	EndIf;
	Return vResult;
EndFunction // GetRoomInfoByRoom

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetAccommodation(pRoom, pHotel)
	vAccommodationInfo = "";
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	ISNULL(Clients.FullName, """") AS GuestFullName,
	|	RoomInventory.CheckOutDate AS CheckOutDate,
	|	RoomInventory.AccommodationTemplate AS AccommodationTemplate,
	|	RoomInventory.HousekeepingRemarks AS HousekeepingRemarks,
	|	RoomInventory.Recorder AS Ref,
	|	RoomInventory.CheckInDate AS CheckInDate
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|		LEFT JOIN Catalog.Clients AS Clients
	|		ON RoomInventory.Guest = Clients.Ref
	|WHERE
	|	RoomInventory.Room = &qRoom
	|	AND RoomInventory.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RoomInventory.CheckInDate = RoomInventory.PeriodFrom
	|	AND &qDate BETWEEN BEGINOFPERIOD(RoomInventory.CheckInDate, DAY) AND BEGINOFPERIOD(RoomInventory.CheckOutDate, DAY)
	|	AND RoomInventory.IsInHouse
	|	AND RoomInventory.IsAccommodation
	|
	|ORDER BY
	|	AccommodationTemplate DESC";
	vQ.SetParameter("qRoom", pRoom);
	vQ.SetParameter("qDate", BegOfDay(CurrentSessionDate()));
	vResult = vQ.Execute().Unload();
	For Each vRowItem In vResult Do
		If ValueIsFilled(vRowItem.AccommodationTemplate) Then
			vObjAccommodationTemplate = vRowItem.AccommodationTemplate.GetObject();
			vAccommodationInfo = vAccommodationInfo + vObjAccommodationTemplate.pmGetTemplateDescription(SessionParameters.CurrentLanguage) + "</br>";
			vAccommodationInfo = vAccommodationInfo + NStr("en = 'Check in: ';de = 'Check-In: ';ru = 'Заезд: '") + Format(vRowItem.CheckInDate, "DF=dd/MM/yyyy") + " "+ NStr("en = 'Check out: ';de = 'Abreise: ';ru = 'Выезд: '") + Format(vRowItem.CheckOutDate, "DF=dd/MM/yyyy") + "</br>"; 
			vAccommodationInfo = vAccommodationInfo + "<a href=""" + GetURL(vRowItem.Ref) + """>" + ?(IsBlankString(vRowItem.GuestFullName), TrimAll(vRowItem.Ref), TrimAll(vRowItem.GuestFullName)) + "</a>" + "</br>";
			If ValueIsFilled(TrimAll(vRowItem.HousekeepingRemarks)) Then
				vAccommodationInfo = vAccommodationInfo + TrimAll(vRowItem.HousekeepingRemarks) + "</br>";
			EndIf;
		Else
			vAccommodationInfo = vAccommodationInfo + "<a href=""" + GetURL(vRowItem.Ref) + """>" + ?(IsBlankString(vRowItem.GuestFullName), TrimAll(vRowItem.Ref), TrimAll(vRowItem.GuestFullName)) + "</a>" + "</br>";
			If ValueIsFilled(TrimAll(vRowItem.HousekeepingRemarks)) Then
				vAccommodationInfo = vAccommodationInfo + TrimAll(vRowItem.HousekeepingRemarks) + "</br>";
			EndIf;
		EndIf;
	EndDo;
	Return vAccommodationInfo;
EndFunction // GetAccommodation

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetEmployeeOperation(pRoom, pHotel)
	vEmployeeOperationInfo = New Structure("Operation, Employee", "", "");
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	EmployeeOperation.Employee AS Employee,
	|	EmployeeOperation.Operation AS Operation
	|FROM
	|	Document.EmployeeOperation AS EmployeeOperation
	|WHERE
	|	EmployeeOperation.Room = &qRoom
	|	AND EmployeeOperation.Hotel = &qHotel
	|	AND NOT EmployeeOperation.DeletionMark
	|	AND EmployeeOperation.Posted
	|	AND BEGINOFPERIOD(EmployeeOperation.Date, DAY) = &qDate
	|	AND EmployeeOperation.Operation <> VALUE(Catalog.Operations.EmptyRef)
	|
	|ORDER BY
	|	EmployeeOperation.Employee.SortCode,
	|	EmployeeOperation.Operation.SortCode";
	vQ.SetParameter("qRoom", pRoom);
	vQ.SetParameter("qHotel", pHotel);
	vQ.SetParameter("qDate", BegOfDay(CurrentSessionDate()));
	vResult = vQ.Execute().Unload();
	For Each vRowItem In vResult Do
		If ValueIsFilled(vRowItem.Employee) Then
			vObjEmployee = vRowItem.Employee.GetObject();
			vEmployeeOperationInfo.Employee = vEmployeeOperationInfo.Employee + ?(ValueIsFilled(vEmployeeOperationInfo.Employee), "</br>", "") + vObjEmployee.pmGetEmployeeDescription(SessionParameters.CurrentLanguage);
		EndIf;
		vEmployeeOperationInfo.Operation = vEmployeeOperationInfo.Operation + ?(ValueIsFilled(vEmployeeOperationInfo.Operation), "</br>", "") + TrimAll(vRowItem.Operation.Description);
	EndDo;
	Return vEmployeeOperationInfo;
EndFunction // GetAccommodation

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetTasks(pRoom) 
	TasksInfo = "";
	vTasks = cmGetMessagesForObject(pRoom);
	For Each vRowItem In vTasks Do
		TasksInfo = TasksInfo + ?(ValueIsFilled(TasksInfo), "</br>", "") + "<a href=""" + GetURL(vRowItem.Recorder) + """>" + vRowItem.Remarks + "</a>";
	EndDo;
	Return TasksInfo;
EndFunction // GetAccommodation

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetBlocking(pRoom, pHotel)
	vBlockingInfo = "";
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	SetRoomBlock.Ref AS Ref,
	|	SetRoomBlock.RoomBlockType AS RoomBlockType,
	|	SetRoomBlock.DateFrom AS DateFrom,
	|	SetRoomBlock.DateTo AS DateTo
	|FROM
	|	Document.SetRoomBlock AS SetRoomBlock
	|WHERE
	|	NOT SetRoomBlock.DeletionMark
	|	AND (SetRoomBlock.DateTo >= &qDate
	|			OR SetRoomBlock.DateTo = DATETIME(1, 1, 1, 0, 0, 0)
	|				AND SetRoomBlock.DateFrom < &qDate)
	|	AND SetRoomBlock.Room = &qRoom
	|	AND (NOT &qHotelIsEmpty
	|				AND SetRoomBlock.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND NOT SetRoomBlock.IsFinished
	|	AND SetRoomBlock.Hotel = &qHotel
	|
	|ORDER BY
	|	SetRoomBlock.Room.SortCode";
	vQ.SetParameter("qDate", CurrentSessionDate());
	vQ.SetParameter("qRoom", pRoom);
	vQ.SetParameter("qHotel", pHotel);
	vQ.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SessionParameters.CurrentHotel));
	vQ.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vResult = vQ.Execute().Unload();
	For Each vRowItem In vResult Do
		vBlockingInfo = vBlockingInfo + ?(ValueIsFilled(vBlockingInfo), "</br>", "") + 
		"<a href=""" + GetURL(vRowItem.Ref) + """>" + TrimAll(vRowItem.RoomBlockType.Description) + 
		?(ValueIsFilled(vRowItem.DateFrom), NStr("en = ' from ';de = ' vom ';ru = ' c '") + Format(vRowItem.DateFrom, "DF=dd/MM/yy"), "") + 
		?(ValueIsFilled(vRowItem.DateTo), NStr("en = ' to ';de = ' bis ';ru = ' по '") + Format(vRowItem.DateTo, "DF=dd/MM/yy"), "") + "</a>";
	EndDo;
	Return vBlockingInfo;
EndFunction // GetAccommodation

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetReservation(pRoom, pHotel)
	vReservationInfo = "";
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	RoomInventory.CheckInDate AS CheckInDate,
	|	RoomInventory.AccommodationTemplate AS AccommodationTemplate,
	|	RoomInventory.Recorder AS Ref
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|	AND RoomInventory.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RoomInventory.CheckInDate = RoomInventory.PeriodFrom
	|	AND BEGINOFPERIOD(RoomInventory.PeriodFrom, DAY) = &qDate
	|	AND NOT RoomInventory.IsCheckIn
	|	AND RoomInventory.IsReservation
	|	AND RoomInventory.Room = &qRoom
	|
	|UNION ALL
	|
	|SELECT
	|	ReservationList.CheckInDate,
	|	ReservationList.AccommodationTemplate,
	|	ReservationList.Ref
	|FROM
	|	Document.Reservation AS ReservationList
	|		INNER JOIN Catalog.ReservationStatuses AS ReservationStatuses
	|		ON ReservationList.ReservationStatus = ReservationStatuses.Ref
	|			AND (ReservationStatuses.IsPreliminary)
	|WHERE
	|	ReservationList.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|	AND BEGINOFPERIOD(ReservationList.CheckInDate, DAY) = &qDate
	|	AND ReservationList.Room = &qRoom";
	vQ.SetParameter("qRoom", pRoom);
	vQ.SetParameter("qDate", BegOfDay(CurrentSessionDate()));
	vResult = vQ.Execute().Unload();
	For Each vRowItem In vResult Do
		vReservationInfo = vReservationInfo + Format(vRowItem.CheckInDate, "DF=dd/MM/yyyy") + "</br>";
		vObjAccommodationTemplate = vRowItem.AccommodationTemplate.GetObject();
		vReservationInfo = vReservationInfo + vObjAccommodationTemplate.pmGetTemplateDescription(SessionParameters.CurrentLanguage) + "</br>";
		vReservationInfo = vReservationInfo + "<a href=""" + GetURL(vRowItem.Ref) + """>" + TrimAll(vRowItem.Ref) + "</a>";
		Break;
	EndDo;
	Return vReservationInfo;
EndFunction // GetAccommodation

// --------------------------------------------------------------------------------
&AtClient
Procedure FillRoomInfo(pRoomInfo)
	vDocument = GetHTMLDocument(Items.HTML.Document).document;
	If vDocument = Undefined Then
		Return;
	EndIf;
	
	vTable = vDocument.getElementById("room-info");
	If vTable = Undefined Then
		Return;
	EndIf;
	
	While vTable.firstChild <> Undefined Do
		vTable.removeChild(vTable.firstChild);
	EndDo;
	
	If pRoomInfo = Undefined Then
		Return;
	EndIf;
	
	vTBody = vDocument.createElement("tbody");
	
	For Each vRow In pRoomInfo Do
		vTR = vDocument.createElement("tr");
		
		vTD1 = vDocument.createElement("td");
		vTD1.innerHTML = vRow.Column1;
		vTR.append(vTD1);
		
		vTD2 = vDocument.createElement("td");
		vTD2.innerHTML = vRow.Column2;
		vTR.append(vTD2);
		
		vTBody.append(vTR);
	EndDo;
	
	vTable.append(vTBody);
EndProcedure // FillRoomInfo

// -----------------------------------------------------------------------------
&AtServer
Function CalculateDurationAtServer(pRoomRate, pCheckInDate, pCheckOutDate)
	Return cmCalculateDuration(pRoomRate, pCheckInDate, pCheckOutDate);
EndFunction // CalculateDurationAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CalculateCheckOutDateAtServer(pRoomRate, pCheckInDate, pDuration)
	Return cmCalculateCheckOutDate(pRoomRate, pCheckInDate, pDuration);
EndFunction // CalculateCheckOutDateAtServer 

// -----------------------------------------------------------------------------
&AtServer
Procedure AddKidAgeAttributes(pNumberOfFields)
	vTempArray = New Array;
	For vInd = 1 To pNumberOfFields Do
		vTempArray.Add(New FormAttribute("KidAge"+String(NumberOfKidAgeFields+vInd), New TypeDescription("Number")));
	EndDo;
	ChangeAttributes(vTempArray);
	For vInd = 1 To pNumberOfFields Do
		vNewField = Items.Add("KidAge"+String(NumberOfKidAgeFields+vInd), Type("FormField"), Items.KidsGroup);
		vNewField.Type = FormFieldType.InputField;
		vNewField.HorizontalAlign = ItemHorizontalLocation.Center;
		vNewField.Width = 2;
		vNewField.TitleLocation = FormItemTitleLocation.None;
		vNewField.DataPath = "KidAge"+String(NumberOfKidAgeFields+vInd);
	EndDo;
	NumberOfKidAgeFields = NumberOfKidAgeFields + pNumberOfFields;
EndProcedure // AddKidAgeAttributes 

// -----------------------------------------------------------------------------
&AtClient
Procedure AllowedRoomRatesOnActivateRow(pItem)
	vCurItem = Items.AllowedRoomRates.CurrentData;
	If vCurItem <> Undefined Then
		If ValueIsFilled(vCurItem.Value) Then
			RefreshListToolTipVisible();
			RoomRate = vCurItem.Value;
		EndIf;
	EndIf;
EndProcedure // AllowedRoomRatesOnActivateRow

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutDateChange()
	If SelHotel.Cruises Then
		FindCruises();
	EndIf;
	
	Duration = 0;
	CheckOutTime = CheckOutDate;
	If ValueIsFilled(RoomRate) And
		ValueIsFilled(CheckInDate) And
		ValueIsFilled(CheckOutDate) Then
		Duration = cmCalculateDuration(RoomRate, CheckInDate, CheckOutDate);
	EndIf;
EndProcedure // CheckOutDateChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckInDateChange() 
	// Cruises
	If SelHotel.Cruises Then
		FillCruisesCityTo();
		FindCruises();
	EndIf;
	
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
	EndIf;
EndProcedure // CheckInTimeChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutTimeChange()
	CheckOutDate = BegOfDay(CheckOutDate) + (CheckOutTime - BegOfDay(CheckOutTime));
	CheckOutTime = CheckOutDate;
	CheckOutDateChange();
EndProcedure // CheckOutTimeChange

// ----------------------------------------------------------------------------
&AtServer
Procedure FillFirstCruises()
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	Cruises.DepartureCity,
	|	Cruises.CityOfArrival,
	|	Cruises.DateFrom AS DateFrom,
	|	Cruises.DateTo AS DateTo
	|FROM
	|	InformationRegister.Cruises AS Cruises
	|WHERE
	|	Cruises.Hotel = &qHotel
	|	AND Cruises.DateFrom >= &qDateFrom
	|ORDER BY
	|	DateFrom,
	|	DateTo";
	Query.SetParameter("qHotel", SelHotel);
	Query.SetParameter("qDateFrom", BegOfDay(CheckInDate));
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	If SelectionDetailRecords.Next() Then
		CityTo = SelectionDetailRecords.CityOfArrival;
		CityFrom = SelectionDetailRecords.DepartureCity;
		CheckInDate = SelectionDetailRecords.DateFrom;
		CheckOutDate = SelectionDetailRecords.DateTo;
		CheckOutDateOnChangeAtServer();
	EndIf;
	
EndProcedure // FillFirstCruises

// ----------------------------------------------------------------------------
&AtServer
Procedure FillCruisesCityFrom()
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	Cruises.DepartureCity AS DepartureCity
	|FROM
	|	InformationRegister.Cruises AS Cruises
	|WHERE
	|	Cruises.Hotel = &qHotel
	|	AND Cruises.DateFrom >= &qDateFrom
	|
	|GROUP BY
	|	Cruises.DepartureCity
	|
	|ORDER BY
	|	DepartureCity";
	
	vQ.SetParameter("qHotel", SelHotel);
	vQ.SetParameter("qDateFrom", BegOfDay(CurrentSessionDate()));
	
	vQResult = vQ.Execute();
	
	vSelectionDetailRecords = vQResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		Items.CityFrom.ChoiceList.Add(vSelectionDetailRecords.DepartureCity);
	EndDo;
EndProcedure // FillCruisesCityFrom

// ----------------------------------------------------------------------------
&AtServer
Procedure FindCruises()
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	Cruises.DepartureCity,
	|	Cruises.CityOfArrival
	|FROM
	|	InformationRegister.Cruises AS Cruises
	|WHERE
	|	BEGINOFPERIOD(Cruises.DateFrom, DAY) = &qDateFrom
	|	AND BEGINOFPERIOD(Cruises.DateTo, DAY) = &qDateTo
	|	AND Cruises.Hotel = &qHotel";
	vQ.SetParameter("qDateFrom", BegOfDay(CheckInDate));
	vQ.SetParameter("qDateTo", BegOfDay(CheckOutDate));
	vQ.SetParameter("qHotel", SelHotel);
	vQueryResult = vQ.Execute();
	vSelectionDetailRecords = vQueryResult.Select();
	If vSelectionDetailRecords.Next() Then
		CityTo = vSelectionDetailRecords.CityOfArrival;
		CityFrom = vSelectionDetailRecords.DepartureCity;
		Items.CheckInDate.ChoiceList.Clear();
		vQ = New Query;
		vQ.Text = 
		"SELECT
		|	Cruises.DateFrom
		|FROM
		|	InformationRegister.Cruises AS Cruises
		|WHERE
		|	Cruises.Hotel = &qHotel
		|	AND Cruises.DateFrom >= &qDateFrom
		|	AND Cruises.DepartureCity = &qDepartureCity
		|
		|GROUP BY
		|	Cruises.DateFrom";
		vQ.SetParameter("qHotel", SelHotel);
		vQ.SetParameter("qDateFrom", BegOfDay(CurrentSessionDate()));
		vQ.SetParameter("qDepartureCity", CityFrom);
		vQueryResult = vQ.Execute();
		vSelectionDetailRecords = vQueryResult.Select();
		While vSelectionDetailRecords.Next() Do
			Items.CheckInDate.ChoiceList.Add(vSelectionDetailRecords.DateFrom);
		EndDo;
		Items.CityTo.ChoiceList.Clear();
		vQ = New Query;
		vQ.Text = 
		"SELECT
		|	Cruises.CityOfArrival,
		|	Cruises.DateTo AS DateTo
		|FROM
		|	InformationRegister.Cruises AS Cruises
		|WHERE
		|	Cruises.Hotel = &qHotel
		|	AND Cruises.DateFrom = &qDateFrom
		|	AND Cruises.DepartureCity = &qDepartureCity
		|
		|GROUP BY
		|	Cruises.CityOfArrival,
		|	Cruises.DateTo
		|
		|ORDER BY
		|	DateTo";
		vQ.SetParameter("qHotel", SelHotel);
		vQ.SetParameter("qDateFrom", CheckInDate);
		vQ.SetParameter("qDepartureCity", CityFrom);
		vQueryResult = vQ.Execute();
		vSelectionDetailRecords = vQueryResult.Select();
		While vSelectionDetailRecords.Next() Do
			Items.CityTo.ChoiceList.Add(vSelectionDetailRecords.CityOfArrival,vSelectionDetailRecords.CityOfArrival + " " + Format(vSelectionDetailRecords.DateTo,"DF=dd.MM"));
		EndDo;
		Items.CheckOutDate.ChoiceList.Clear();
		vQ = New Query;
		vQ.Text = 
		"SELECT
		|	Cruises.DateTo
		|FROM
		|	InformationRegister.Cruises AS Cruises
		|WHERE
		|	Cruises.Hotel = &qHotel
		|	AND BEGINOFPERIOD(Cruises.DateFrom, DAY) = &qDateFrom
		|	AND Cruises.DepartureCity = &qDepartureCity
		|	AND Cruises.CityOfArrival = &qCityOfArrival
		|
		|GROUP BY
		|	Cruises.DateTo";
		
		vQ.SetParameter("qHotel", SelHotel);
		vQ.SetParameter("qDateFrom",BegOfDay(CheckInDate));
		vQ.SetParameter("qDepartureCity", CityFrom);
		vQ.SetParameter("qCityOfArrival", CityTo);
		vQueryResult = vQ.Execute();
		vSelectionDetailRecords = vQueryResult.Select();
		While vSelectionDetailRecords.Next() Do
			Items.CheckOutDate.ChoiceList.Add(vSelectionDetailRecords.DateTo);
		EndDo;
	Else
		tcCommonFunctionOnClientServer.UserMessage("Рейс не найден!");
	EndIf;
EndProcedure // FindCruises

// ----------------------------------------------------------------------------
&AtServer
Procedure CheckOutDateOnChangeAtServer(pObj = Undefined, pIsOnOpenForm = False)
	// Cruises
	If SelHotel.Cruises Then
		FindCruises();
	EndIf;
	// Check if date is valid
	If CheckOutDate < CheckInDate Then
		Duration = 1;
		vCheckInDate = CheckInDate;
		vCheckOutDate = CheckOutDate;
		vCheckOutYear = Year(vCheckInDate);
		vCheckOutMonth = Month(vCheckInDate);
		vCheckOutDay = Day(CheckOutDate);
		If BegOfDay(vCheckInDate) > BegOfDay(CurrentSessionDate()) And BegOfDay(vCheckOutDate) > BegOfDay(CurrentSessionDate()) Then
			If vCheckOutDay = 1 Then
				If vCheckOutMonth = 1 Then
					vCheckOutYear = vCheckOutYear - 1;
					vCheckOutMonth = 12;
					vCheckOutDay = 31;
				Else
					vCheckOutMonth = vCheckOutMonth - 1;
					vCheckOutDay = Day(EndOfMonth(Date(vCheckOutYear, vCheckOutMonth, 1)));
				EndIf;
			Else
				vCheckOutDay = vCheckOutDay - 1;
			EndIf;
			CheckInDate = cm1SecondShift(Date(vCheckOutYear, vCheckOutMonth, vCheckOutDay, Hour(vCheckInDate), Minute(vCheckInDate), 0));
		Else
			CheckInDate = cm1SecondShift(Date(Year(CurrentSessionDate()), Month(CurrentSessionDate()), Day(CurrentSessionDate()), Hour(vCheckInDate), Minute(vCheckInDate), 0));
			Duration = 1;
			CheckOutDate = cmCalculateCheckOutDate(RoomRate, CheckInDate, Duration);
		EndIf;
	Else
		// Calculate duration
		Duration = cmCalculateDuration(RoomRate, CheckInDate, CheckOutDate);
	EndIf;
	CheckOutTime = cmExtractTime(CheckOutDate);
	CheckInTime = cmExtractTime(CheckInDate);
EndProcedure // CheckOutDateOnChangeAtServer

// ----------------------------------------------------------------------------
&AtClient
Procedure CityFromOnChange(pItem)
	RefreshListToolTipVisible();
	FillDateFrom();
EndProcedure // CityFromOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure CityToOnChange(pItem)
	RefreshListToolTipVisible();
	FillDateTo();
EndProcedure // CityToOnChange

// ----------------------------------------------------------------------------
&AtServer
Procedure FillDateFrom()
	Items.CheckInDate.ChoiceList.Clear();
	CheckInDate = Undefined;
	CheckOutDate = Undefined;
	Duration = 0;
	CityTo = Undefined;
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	Cruises.DateFrom
	|FROM
	|	InformationRegister.Cruises AS Cruises
	|WHERE
	|	Cruises.Hotel = &qHotel
	|	AND Cruises.DateFrom >= &qDateFrom
	|	AND Cruises.DepartureCity = &qDepartureCity
	|
	|GROUP BY
	|	Cruises.DateFrom";
	vQ.SetParameter("qHotel", SelHotel);
	vQ.SetParameter("qDateFrom", BegOfDay(CurrentSessionDate()));
	vQ.SetParameter("qDepartureCity", CityFrom);
	vQueryResult = vQ.Execute();
	vSelectionDetailRecords = vQueryResult.Select();
	iF vSelectionDetailRecords.Count() > 1 Then
		While vSelectionDetailRecords.Next() Do
			Items.CheckInDate.ChoiceList.Add(vSelectionDetailRecords.DateFrom);
		EndDo;
	Else 		
		If vSelectionDetailRecords.Next() Then
			CheckInDate = vSelectionDetailRecords.DateFrom;
			FillCruisesCityTo();
		EndIf;
	EndIf;
EndProcedure // FillDateFrom

// ----------------------------------------------------------------------------
&AtServer
Procedure FillCruisesCityTo()
	Items.CityTo.ChoiceList.Clear();
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	Cruises.CityOfArrival,
	|	Cruises.DateTo AS DateTo
	|FROM
	|	InformationRegister.Cruises AS Cruises
	|WHERE
	|	Cruises.Hotel = &qHotel
	|	AND Cruises.DateFrom = &qDateFrom
	|	AND Cruises.DepartureCity = &qDepartureCity
	|
	|GROUP BY
	|	Cruises.CityOfArrival,
	|	Cruises.DateTo
	|
	|ORDER BY
	|	DateTo";
	
	vQ.SetParameter("qHotel", SelHotel);
	vQ.SetParameter("qDateFrom", CheckInDate);
	vQ.SetParameter("qDepartureCity", CityFrom);
	
	vQueryResult = vQ.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	If vSelectionDetailRecords.Count() > 1 Then
		While vSelectionDetailRecords.Next() Do
			Items.CityTo.ChoiceList.Add(vSelectionDetailRecords.CityOfArrival,vSelectionDetailRecords.CityOfArrival + " " + Format(vSelectionDetailRecords.DateTo,"DF=dd.MM"));
		EndDo;
	Else 
		If vSelectionDetailRecords.Next() Then
			CityTo = vSelectionDetailRecords.CityOfArrival;
			FillDateTo();
		EndIf;
	EndIf;
EndProcedure // FillCruisesCityTo

// ----------------------------------------------------------------------------
&AtServer
Procedure FillDateTo()
	Items.CheckOutDate.ChoiceList.Clear();
	CheckOutDate = Undefined;
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	Cruises.DateTo
	|FROM
	|	InformationRegister.Cruises AS Cruises
	|WHERE
	|	Cruises.Hotel = &qHotel
	|	AND BEGINOFPERIOD(Cruises.DateFrom, DAY) = &qDateFrom
	|	AND Cruises.DepartureCity = &qDepartureCity
	|	AND Cruises.CityOfArrival = &qCityOfArrival
	|
	|GROUP BY
	|	Cruises.DateTo";
	
	vQ.SetParameter("qHotel", SelHotel);
	vQ.SetParameter("qDateFrom",BegOfDay(CheckInDate));
	vQ.SetParameter("qDepartureCity", CityFrom);
	vQ.SetParameter("qCityOfArrival", CityTo);
	vQueryResult = vQ.Execute();
	vSelectionDetailRecords = vQueryResult.Select();
	iF vSelectionDetailRecords.Count() > 1 Then
		While vSelectionDetailRecords.Next() Do
			Items.CheckOutDate.ChoiceList.Add(vSelectionDetailRecords.DateTo);
		EndDo;
	Else
		If vSelectionDetailRecords.Next() Then
			CheckOutDate = vSelectionDetailRecords.DateTo;
			CheckOutDateOnChangeAtServer();
		EndIf;
	EndIf;
EndProcedure // FillDateTo

#EndRegion
