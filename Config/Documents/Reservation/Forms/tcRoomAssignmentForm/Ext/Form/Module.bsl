// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Current hotel
	If Parameters.Property("SelHotel") Then
		SelHotel = Parameters.SelHotel;
	EndIf;
	If Not ValueIsFilled(SelHotel) Then
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(SelHotel) Then
		pCancel = True;
		Return;
	EndIf;
	
	// Date
	SelFilterByRoomStatus = False;
	If Parameters.Property("SelCheckInDate") Then
		SelCheckInDate = Parameters.SelCheckInDate;
		If ValueIsFilled(SelCheckInDate) And BegOfDay(SelCheckInDate) = BegOfDay(CurrentSessionDate()) Then
			SelFilterByRoomStatus = True;
		EndIf;
	EndIf;
	
	// Guest group
	If Parameters.Property("SelGuestGroup") Then
		SelGuestGroup = Parameters.SelGuestGroup;
	EndIf;
	
	// Fill room statuses
	vRoomStatuses = cmGetAllRoomStatuses();
	Items.SelRoomStatus.ChoiceList.Add(Catalogs.RoomStatuses.EmptyRef(), NStr("en='<Empty>'; ru='<Пустой>'; de='<Leer>'"), , PictureLib.Empty);
	For Each vRoomStatusesRow In vRoomStatuses Do
		Items.SelRoomStatus.ChoiceList.Add(vRoomStatusesRow.RoomStatus, , , cmGetRoomStatusIcon(vRoomStatusesRow.RoomStatus));
	EndDo;
	
	// Fill reservations
	vReservationsList = New ValueList();
	CurReservation = Undefined;
	CurRemarks = "";
	CurHousekeepingRemarks = "";
	CurTasks = "";
	Reservations.Clear();
	If Parameters.Property("SelReservations") Then
		vReservationsList = Parameters.SelReservations;
	Else
		If ValueIsFilled(SelCheckInDate) Or ValueIsFilled(SelGuestGroup) Then
			vReservationsList = GetReservationsByParameters();
		EndIf;
	EndIf;
	If vReservationsList.Count() > 0 Then
		For Each vItem In vReservationsList Do
			vReservation = vItem.Value;
			If vReservation.RoomQuantity > 1 Then
				Continue;
			EndIf;
			If Not ValueIsFilled(CurReservation) Then
				CurReservation = vReservation;
				vStruct = GetReservationTasksAndRemarks(CurReservation);
				CurRemarks = vStruct.Remarks;
				CurHousekeepingRemarks = vStruct.HousekeepingRemarks;
				CurTasks = vStruct.Tasks;
			EndIf;
			
			vRow = Reservations.Add();
			vRow.Reservation = vReservation;
			vRow.Room = vReservation.Room;
			vRow.RoomType = vReservation.RoomType;
			vRow.RoomTypeUpgrade = vReservation.RoomTypeUpgrade;
			vRow.SortCode = vReservation.SortCode;
			vRow.AccommodationTypeType = vReservation.AccommodationType.Type;
			vRow.AccommodationTemplate = vReservation.AccommodationTemplate;
			vRow.PlannedPaymentMethodCode = ?(ValueIsFilled(vReservation.PlannedPaymentMethod), TrimAll(vReservation.PlannedPaymentMethod.Code), "");
			vRow.Customer = vReservation.Customer;
			vRow.Agent = vReservation.Agent;
		EndDo;
		Reservations.Sort("SortCode");
	EndIf;
	
	// Fill room properties
	RoomProperties.Clear();
	vRoomPropertiesList = cmGetAllRoomProperties(, SelHotel, True);
	For Each vRoomPropertiesItem In vRoomPropertiesList Do
		vRoomProperty = vRoomPropertiesItem.Value;
		RoomProperties.Add(vRoomProperty, TrimAll(vRoomProperty.Code) + " - " + TrimAll(vRoomProperty.Description), False);
	EndDo;
	
	// Beds setup availability
	SetBedsSetupAvailability();
	
	// Sel room status
	SelRoomStatus = SelHotel.VacantRoomStatus;
	
	// Filter by room type by default
	If Reservations.Count() > 0 Then
		vResRow = Reservations.Get(0);
		CurRoomType = vResRow.RoomType;
	EndIf;
	If ValueIsFilled(CurRoomType) Then
		SelFilterByRoomType = True;
	EndIf;
	
	// Build list of vacant rooms
	RefreshRoomsAtServer()
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	For Each vRowData In Reservations Do
		If ValueIsFilled(vRowData.Reservation) Then
			NotifyChanged(vRowData.Reservation);
		EndIf;
	EndDo;
EndProcedure // OnOpen

// --------------------------------------------------------------------------------
&AtServer
Function GetReservationsByParameters()
	vDocsList = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservations.Ref AS Ref
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Hotel = &qHotel
	|	AND (&qCheckInDateIsFilled
	|				AND BEGINOFPERIOD(Reservations.CheckInDate, DAY) = &qCheckInDate
	|			OR NOT &qCheckInDateIsFilled)
	|	AND (&qGuestGroupIsFilled
	|				AND Reservations.GuestGroup = &qGuestGroup
	|			OR NOT &qGuestGroupIsFilled)
	|	AND Reservations.Posted
	|	AND Reservations.ReservationStatus.IsActive
	|	AND Reservations.RoomQuantity = 1
	|	AND Reservations.Room = VALUE(Catalog.Rooms.EmptyRef)
	|	AND Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|ORDER BY
	|	Reservations.SortCode";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qCheckInDate", BegOfDay(SelCheckInDate));
	vQry.SetParameter("qCheckInDateIsFilled", ValueIsFilled(SelCheckInDate));
	vQry.SetParameter("qGuestGroup", SelGuestGroup);
	vQry.SetParameter("qGuestGroupIsFilled", ValueIsFilled(SelGuestGroup));
	vDocs = vQry.Execute().Unload();
	vDocsList.LoadValues(vDocs.UnloadColumn("Ref"));
	Return vDocsList;
EndFunction // GetReservationsByParameters

// --------------------------------------------------------------------------------
&AtServer
Procedure RefreshRoomsAtServer(pDoNotChangePropertiesFilter = False)
	Rooms.Parameters.SetParameterValue("qHotel", SelHotel);
	Rooms.Parameters.SetParameterValue("qRoomStatus", SelRoomStatus);
	Rooms.Parameters.SetParameterValue("qRoomStatusIsEmpty", Not SelFilterByRoomStatus);
	If ValueIsFilled(CurReservation) Then
		vCheckInDate = Max(CurrentSessionDate(), CurReservation.CheckInDate);
		vCheckOutDate = CurReservation.CheckOutDate;
		If vCheckOutDate <= vCheckInDate Then
			vCheckInDate = CurReservation.CheckInDate;
		EndIf;
		Rooms.Parameters.SetParameterValue("qBeginOfPeriod", vCheckInDate);
		Rooms.Parameters.SetParameterValue("qEndOfPeriod", vCheckOutDate);
		Rooms.Parameters.SetParameterValue("qRoomType", ?(SelFilterByRoomType, CurRoomType, Catalogs.RoomTypes.EmptyRef()));
	Else
		Rooms.Parameters.SetParameterValue("qBeginOfPeriod", CurrentSessionDate());
		Rooms.Parameters.SetParameterValue("qEndOfPeriod", CurrentSessionDate() + 24*3600);
		Rooms.Parameters.SetParameterValue("qRoomType", Catalogs.RoomTypes.EmptyRef());
	EndIf;
	Rooms.Parameters.SetParameterValue("qBedsSetup", ?(SelFilterByBedsSetup, CurBedsSetup, Catalogs.BedsSetups.EmptyRef()));
	Rooms.Parameters.SetParameterValue("qFilterByBedsSetup", SelFilterByBedsSetup);
	If Not pDoNotChangePropertiesFilter Then
		If ValueIsFilled(CurReservation) And CurReservation.RoomProperties.Count() > 0 Then
			For Each vRPItem In RoomProperties Do
				If CurReservation.RoomProperties.Find(vRPItem.Value, "RoomProperty") <> Undefined Then
					vRPItem.Check = True;
				Else
					vRPItem.Check = False;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	vPropertiesAreChecked = False;
	vPropertiesList = New ValueList();
	For Each vRPItem In RoomProperties Do
		If vRPItem.Check Then
			vPropertiesAreChecked = True;
			vPropertiesList.Add(vRPItem.Value);
		EndIf;
	EndDo;
	vRoomsWithProperties = GetRoomsWithSelectedProperties(SelHotel, vPropertiesList);
	Rooms.Parameters.SetParameterValue("qRoomsWithProperties", vRoomsWithProperties);
	Rooms.Parameters.SetParameterValue("qFilterByProperties", vPropertiesAreChecked);
	vByRooms = True;
	If ValueIsFilled(CurReservation) Then
		vByRooms = ?(CurReservation.AccommodationType.Type = Enums.AccomodationTypes.Room, True, False);
	EndIf;
	Rooms.Parameters.SetParameterValue("qByRooms", vByRooms);
	Rooms.Parameters.SetParameterValue("qAll", SelShowAll);
	vAllotment = Catalogs.RoomQuotas.EmptyRef();
	If ValueIsFilled(CurReservation) Then
		vAllotment = CurReservation.RoomQuota;
	EndIf;
	Rooms.Parameters.SetParameterValue("qAllotment", vAllotment);
	If ValueIsFilled(vAllotment) Then
		If vAllotment.IsQuotaForRooms Then
			If vAllotment.DoWriteOff Then
				Rooms.Parameters.SetParameterValue("qUseAllotmentBalances", True);
				Rooms.Parameters.SetParameterValue("qFilterByAllotmentRoomsList", False);
				Rooms.Parameters.SetParameterValue("qAllotmentRoomsList", New ValueList());
			Else
				Rooms.Parameters.SetParameterValue("qUseAllotmentBalances", False);
				Rooms.Parameters.SetParameterValue("qFilterByAllotmentRoomsList", True);
				Rooms.Parameters.SetParameterValue("qAllotmentRoomsList", cmGetAllotmentRooms(SelHotel, vAllotment, CurReservation.CheckInDate, CurReservation.CheckOutDate, vByRooms));
			EndIf;
		Else
			Rooms.Parameters.SetParameterValue("qUseAllotmentBalances", False);
			Rooms.Parameters.SetParameterValue("qFilterByAllotmentRoomsList", False);
			Rooms.Parameters.SetParameterValue("qAllotmentRoomsList", New ValueList());
		EndIf;
	Else
		Rooms.Parameters.SetParameterValue("qUseAllotmentBalances", False);
		Rooms.Parameters.SetParameterValue("qFilterByAllotmentRoomsList", False);
		Rooms.Parameters.SetParameterValue("qAllotmentRoomsList", New ValueList());
	EndIf;
	Rooms.Parameters.SetParameterValue("qEmptyDate", '00010101');
	Rooms.Parameters.SetParameterValue("qSelectedRoomsList", SelectedRoomsList);
EndProcedure // RefreshRoomsAtServer

// --------------------------------------------------------------------------------
Function GetRoomsWithSelectedProperties(pHotel, pPropertiesList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Properties.Ref AS RoomProperty
	|INTO PropertiesChecked
	|FROM
	|	Catalog.RoomProperties AS Properties
	|WHERE
	|	Properties.Ref IN(&qPropertiesList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomProperties.Room AS Room,
	|	SUM(1) AS RoomPropertiesCount
	|FROM
	|	InformationRegister.RoomProperties AS RoomProperties
	|		INNER JOIN PropertiesChecked AS PropertiesChecked
	|		ON (PropertiesChecked.RoomProperty = RoomProperties.RoomProperty)
	|WHERE
	|	RoomProperties.Room.Owner = &qHotel
	|	AND NOT RoomProperties.Room.DeletionMark
	|	AND NOT RoomProperties.Room.IsFolder
	|
	|GROUP BY
	|	RoomProperties.Room
	|
	|HAVING
	|	SUM(1) = &qNumberOfPropertiesChecked
	|
	|ORDER BY
	|	RoomProperties.Room.SortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qPropertiesList", pPropertiesList);
	vQry.SetParameter("qNumberOfPropertiesChecked", pPropertiesList.Count());
	vRooms = vQry.Execute().Unload();
	vRoomsList = New ValueList();
	vRoomsList.LoadValues(vRooms.UnloadColumn("Room"));
	Return vRoomsList;
EndFunction // GetRoomsWithSelectedProperties

// --------------------------------------------------------------------------------
&AtClient
Procedure RefreshRooms(Command)
	RefreshRoomsAtServer(True);
EndProcedure // RefreshRooms

// --------------------------------------------------------------------------------
&AtClient
Procedure SelRoomStatusOnChange(Item)
	SelFilterByRoomStatus = True;
	RefreshRoomsAtServer(True);
EndProcedure // SelRoomStatusOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelFilterByRoomStatusOnChange(pItem)
	RefreshRoomsAtServer(True);
EndProcedure // SelFilterByRoomStatusOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsRoomStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.Reservations.CurrentData;
	If vCurData <> Undefined Then
		vRoomType = vCurData.RoomType;
		vReservation = vCurData.Reservation;
		If Not ValueIsFilled(vRoomType) Then
			vRoomType = tcOnServer.cmGetAttributeByRef(vReservation, "RoomType");
		EndIf;
		vRoomQuota = tcOnServer.cmGetAttributeByRef(vReservation, "RoomQuota");
		vNumberOfBeds = tcOnServer.cmGetAttributeByRef(vReservation, "NumberOfBeds");
		vNumberOfRooms = tcOnServer.cmGetAttributeByRef(vReservation, "NumberOfRooms");
		vCheckInDate = tcOnServer.cmGetAttributeByRef(vReservation, "CheckInDate");
		vCheckOutDate = tcOnServer.cmGetAttributeByRef(vReservation, "CheckOutDate");
		vBedsSetup = tcOnServer.cmGetAttributeByRef(vReservation, "BedsSetup");
		OpenForm("Catalog.Rooms.Form.tcChoiceForm", New Structure("Hotel, DateFrom, DateTo, RoomType, RoomQuota, Company, NumberOfRooms, NumberOfBeds, IsOpenedFromReservation, BedsSetup", SelHotel, vCheckInDate, vCheckOutDate, vRoomType, vRoomQuota, Undefined, vNumberOfRooms, vNumberOfBeds, False, vBedsSetup), pItem);
	EndIf;
EndProcedure // ReservationsRoomStartChoice

// --------------------------------------------------------------------------------
&AtServer
Function CheckRoomStopSale(pRoom, pReservation)
	vMessage = "";
	If ValueIsFilled(pRoom) And pRoom.StopSale Then
		vRemarks = "";
		If cmIsRoomStopSalePeriod(pRoom, pReservation.CheckInDate, pReservation.CheckOutDate, vRemarks) Then
			vMessage = NStr("en='You have choosen room with stop sale flag turned on!';ru='Выбрали номер снятый с продажи!';de='Sie haben ein Zimmer gewählt, das aus dem Angebot genommen wurde!'") + Chars.LF + vRemarks;
		EndIf;
	EndIf;
	Return vMessage;
EndFunction // CheckRoomStopSale

// --------------------------------------------------------------------------------
&AtServer
Function CheckRoomAllotment(pRoom, pReservation)
	vMessage = "";
	If ValueIsFilled(pRoom) And ValueIsFilled(pReservation) And 
	   ValueIsFilled(pReservation.RoomQuota) And pReservation.RoomQuota.IsQuotaForRooms Then
		vQuotasForRoom = cmGetRoomQuotasForRoom(SelHotel, pReservation.RoomType, pRoom, pReservation.CheckInDate, pReservation.CheckOutDate);
		If vQuotasForRoom.Find(pReservation.RoomQuota, "RoomQuota") = Undefined Then
			vMessage = NStr("en='You have choosen room not from the allotment in reservation!';ru='Выбрали номер, который не входит в квоту брони!';de='Sie haben ein Zimmer ausgewählt, das nicht im Reservierungsallotment enthalten ist!'");
		EndIf;
	EndIf;
	Return vMessage;
EndFunction // CheckRoomAllotment

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomsValueChoice(pItem, pValue, pStandardProcessing)
	pStandardProcessing = False;
	RoomsChoice();
EndProcedure // RoomsValueChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	RoomsChoice();
EndProcedure // RoomsSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomsChoice()
	vCurRoomData = Items.Rooms.CurrentData;
	If vCurRoomData <> Undefined Then
		vCurResData = Items.Reservations.CurrentData;
		If vCurResData <> Undefined And ValueIsFilled(vCurResData.Reservation) Then
			vRoom = vCurRoomData.Room;
			vVacantBeds = vCurRoomData.BedsVacant;
			If ValueIsFilled(vRoom) And Not tcOnServer.cmGetAttributeByRef(vRoom, "IsFolder") Then
				// Check room choosen
				vMessage = CheckRoomStopSale(vRoom, vCurResData.Reservation);
				If Not IsBlankString(vMessage) Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage);
					Return;
				EndIf;
				// Check if this room is in reservation allotment
				vMessage = CheckRoomAllotment(vRoom, vCurResData.Reservation);
				If Not IsBlankString(vMessage) Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage);
					Return;
				EndIf;
					
				// Save old room paramters
				vOldRoom = vCurResData.Room;
				vOldRoomType = vCurResData.RoomType;
				
				// Get new room parameters
				vNewNumberOfBedsPerRoom = 0;
				vNewRoomType = GetRoomRoomType(vRoom, vCurResData.Reservation, vNewNumberOfBedsPerRoom);
				
				// Fill room
				vDoBreak = False;
				vUpdatedResData = New ValueList();
				vAskForRoomTypeUpgrade = False;
				vSaveOldRoomPrice = False;
				vFirstReservation = Undefined;

				vCurReservationNumber = tcOnServer.cmGetAttributeByRef(vCurResData.Reservation, "Number");
				
				vCurAccommodationTypeType = vCurResData.AccommodationTypeType;
				vCurAccommodationTemplate = vCurResData.AccommodationTemplate;
				vCurNumberOfBeds = GetNumberOfOccupiedBedsByReservtion(vCurAccommodationTemplate);
				
				While True Do
					// Save current row old data
					If vFirstReservation = Undefined Then
						vFirstReservation = vCurResData.Reservation;
					EndIf;
					
					// Fill room
					vCurResData.Room = vRoom;
					vCurResData.IsChanged = True;
					
					// Fill room type
					vCurResData.RoomType = vNewRoomType;
					
					// Check room type
					If Not ValueIsFilled(vCurResData.RoomTypeUpgrade) And ValueIsFilled(vNewRoomType) And vNewRoomType <> vOldRoomType Then
						If Not vAskForRoomTypeUpgrade Then
							vAskForRoomTypeUpgrade = True;
							vSaveOldRoomPrice = UseOldRoomTypePrices(vCurResData.Reservation);
						EndIf;
					EndIf;

					vUpdatedResData.Add(vCurResData);
					
					// Go to the next reservation
					If Items.Reservations.CurrentRow <> Undefined Then
						vNewIndex = Reservations.IndexOf(Reservations.FindByID(Items.Reservations.CurrentRow)) + 1;
						If vNewIndex < Reservations.Count() Then
							vCurResData = Reservations.Get(vNewIndex);
							Items.Reservations.CurrentRow = vCurResData.GetID();
							
							If ValueIsFilled(vCurResData.Reservation) Then
								vReservationNumber = tcOnServer.cmGetAttributeByRef(vCurResData.Reservation, "Number");
								vReservationRoomType = vCurResData.RoomType;
								If vCurReservationNumber <> vReservationNumber Then
									If vCurAccommodationTypeType = PredefinedValue("Enum.AccomodationTypes.Beds") Then
										If vReservationRoomType = vNewRoomType Then
											If vVacantBeds > vCurNumberOfBeds Then
												vVacantBeds = vVacantBeds - vCurNumberOfBeds;
											Else
												vDoBreak = True;
											EndIf;
										Else
											vDoBreak = True;
										EndIf;
									Else
										vDoBreak = True;
									EndIf;
								EndIf;
							Else
								vDoBreak = True;
							EndIf;
						Else
							vDoBreak = True;
						EndIf;
					Else
						vDoBreak = True;
					EndIf;
					
					// Break
					If vDoBreak Then
						Break;
					EndIf;
				EndDo;
				
				If vAskForRoomTypeUpgrade Then
					vQryText = NStr("en='Do you want to use room type " + TrimAll(vOldRoomType) + " for price calculation for reservation - ';
					                |ru='Нужно ли для расчета стоимости проживания использовать тип номера " + TrimAll(vOldRoomType) + " для брони - ';
					                |de='Möchten Sie zur Berechnung der Tarifpreis der Zimmertyp " + TrimAll(vOldRoomType) + " verwenden für Reservierung - '") + TrimAll(vFirstReservation) + "?" + Chars.LF + 
					           NStr("en='If you answer <No> then room price will be calculated by room type '; ru='Если ответите <Нет>, то стоимость проживания будет рассчитана по типу номера '; de='Wenn Sie <Nein> Antworten, wird der Zimmerpreis nach Zimmertyp '") + TrimAll(vNewRoomType) + NStr("en='.'; ru='.'; de=' berechnet.'");
					ShowQueryBox(New NotifyDescription("RoomsChoiceAfterRoomTypeChangeQuestionAnswer", ThisForm, New Structure("UpdatedResDataList, OldRoomType", vUpdatedResData, vOldRoomType)), vQryText, QuestionDialogMode.YesNo, , ?(vSaveOldRoomPrice, DialogReturnCode.Yes, DialogReturnCode.No));
				EndIf;

				// Add room to the selected rooms list
				If ValueIsFilled(vOldRoom) Then
					vOldRoomItem = SelectedRoomsList.FindByValue(vOldRoom);
					If vOldRoomItem <> Undefined Then
						SelectedRoomsList.Delete(vOldRoomItem);
					EndIf;
				EndIf;
				If vCurAccommodationTypeType = PredefinedValue("Enum.AccomodationTypes.Room") Or 
				   vCurAccommodationTypeType = PredefinedValue("Enum.AccomodationTypes.Beds") And vVacantBeds <= 1 Then
					If ValueIsFilled(vRoom) Then
						If SelectedRoomsList.FindByValue(vRoom) = Undefined Then
							SelectedRoomsList.Add(vRoom);
						EndIf;
					EndIf;
				EndIf;
				Rooms.Parameters.SetParameterValue("qSelectedRoomsList", SelectedRoomsList);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // RoomsChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomsChoiceAfterRoomTypeChangeQuestionAnswer(pAnswer, pParams) Export
	If pAnswer <> Undefined Then
		For Each vResDataItem In pParams.UpdatedResDataList Do
			vResData = vResDataItem.Value;
			If pAnswer = DialogReturnCode.Yes Then
				vResData.RoomTypeUpgrade = pParams.OldRoomType;
			Else
				vResData.RoomTypeUpgrade = Undefined;
			EndIf;
			If pParams.Property("NewRoomType") And ValueIsFilled(pParams.NewRoomType) Then
				vResData.RoomType = pParams.NewRoomType;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // RoomsChoiceAfterRoomTypeChangeQuestionAnswer

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomRoomType(pRoom, pReservation, rNumberOfBedsPerRoom = 0)
	vRoomRoomType = Undefined;
	If ValueIsFilled(pRoom) And ValueIsFilled(pReservation) Then
		vCheckInDate = pReservation.CheckInDate;
		If ValueIsFilled(vCheckInDate) Then
			vRoomAttrs = pRoom.GetObject().pmGetRoomAttributes(cm1SecondShift(vCheckInDate));
			For Each vRoomAttrsRow In vRoomAttrs Do
				vRoomRoomType = vRoomAttrsRow.RoomType;
				rNumberOfBedsPerRoom = vRoomAttrsRow.NumberOfBedsPerRoom;
				Break;
			EndDo;
		EndIf;
	EndIf;
	Return vRoomRoomType;
EndFunction // GetRoomRoomType

// --------------------------------------------------------------------------------
&AtServerNoContext
Function UseOldRoomTypePrices(pReservation)
	If pReservation.RoomType <> pReservation.RoomTypeUpgrade Then
		If ValueIsFilled(pReservation.Contract) And ValueIsFilled(pReservation.Contract.MealBoardTerm) Then
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction // UseOldRoomTypePrices

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetReservationTasksAndRemarks(pReservation)
	vTasks = "";
	vRemarks = "";
	vHousekeepingRemarks = "";
	If ValueIsFilled(pReservation) Then
		vRemarks = TrimAll(pReservation.Remarks);
		vHousekeepingRemarks = TrimAll(pReservation.HousekeepingRemarks);
		vTasksTable = cmGetMessagesForObject(pReservation);
		For Each vTasksRow In vTasksTable Do
			vTaskRemarks = TrimAll(vTasksRow.Remarks);
			If Left(vTaskRemarks, 1) = "•" Then
				vTasks = vTasks + vTaskRemarks + Chars.LF;
			Else
				vTasks = vTasks + "• " + vTaskRemarks + Chars.LF;
			EndIf;
		EndDo;
	EndIf;
	vTasks = TrimAll(vTasks);
	Return New Structure("Remarks, HousekeepingRemarks, Tasks", vRemarks, vHousekeepingRemarks, vTasks);
EndFunction // GetReservationTasksAndRemarks

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsOnActivateRow(pItem)
	vCurData = Items.Reservations.CurrentData;
	If vCurData <> Undefined Then
		If CurReservation <> vCurData.Reservation Then
			vOldRoomType = CurRoomType;
			vOldBedsSetup = CurBedsSetup;
			
			CurReservation = vCurData.Reservation;
			CurRoomType = vCurData.RoomType;
			CurRoom = vCurData.Room;
			vStruct = GetReservationTasksAndRemarks(CurReservation);
			CurRemarks = vStruct.Remarks;
			CurHousekeepingRemarks = vStruct.HousekeepingRemarks;
			CurTasks = vStruct.Tasks;
			CurBedsSetup = tcOnServer.cmGetAttributeByRef(vCurData.Reservation, "BedsSetup");
			
			// Fill rooms
			If SelFilterByRoomType And vOldRoomType <> CurRoomType Or 
			   SelFilterByBedsSetup And vOldBedsSetup <> CurBedsSetup Then
				RefreshRoomsAtServer();
			EndIf;
		EndIf;
	Else
		CurReservation = Undefined;
		CurRemarks = "";
		CurHousekeepingRemarks = "";
		CurTasks = "";
	EndIf;
EndProcedure // ReservationsOnActivateRow

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveAssignments(pCommand)
	vOperationName = NStr("en='Saving room assignments'; ru='Сохранение назначенных номеров'; de='Zimmernummern speichern'");
	
	ListOfMessages.Clear();
	
	vRoomAssignments = New Array;
	For Each vRowData In Reservations Do
		If vRowData.IsChanged And ValueIsFilled(vRowData.RoomType) Then
			vResStruct = New Structure("Reservation, Room, RoomType, RoomTypeUpgrade, IsChanged", vRowData.Reservation, vRowData.Room, vRowData.RoomType, vRowData.RoomTypeUpgrade, vRowData.IsChanged);
			vRoomAssignments.Add(vResStruct);
		EndIf;
	EndDo;
	
	vParameters = New Array;
	vParameters.Add(SelHotel);
	vParameters.Add(vRoomAssignments);
	vParameters.Add(tcOnServer.cmGetCurrentUserAttribute());
	
	vBackgroundJob = AsyncCalls.StartBackgroundJobWithRecordInRegister(SelHotel, vOperationName, "ProlongedOperations.ReservationsList_WriteRoomAssignment", vParameters);
	CurrentBackgroundJobUUID = vBackgroundJob.UUID;
	
	AttachIdleHandler("Attachable_CheckBackgroundJobs", 1, False);
	
	BlockForm_ShowProgressBar(vOperationName);
EndProcedure // SaveAssignments

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_CheckBackgroundJobs()
	vBackgroundJob = CheckBackgroundJobStatus(CurrentBackgroundJobUUID);
	BackgroundOperationProgress = vBackgroundJob.Progress; 
	
	For Each vMsg in vBackgroundJob.Messages Do
		If ListOfMessages.FindByValue(vMsg) = Undefined Then
			ListOfMessages.Add(vMsg);
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
		EndIf;
	EndDo;
	
	If vBackgroundJob.Status = "Error" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: '; ru = 'Ошибка выполнения фонового задания: '; de = 'Fehler beim Ausführen des Hintergrundjobs: '") + vBackgroundJob.Error);
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Canceled" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job - canceled'; ru = 'Фоновое задание - отменено'; de = 'Hintergrundjob - abgebrochen'"));
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Completed" Then
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_Completed();
		If ValueIsFilled(SelGuestGroup) Then
			Notify("Catalog.GuestGroups.Changed", SelGuestGroup);
		EndIf;
	EndIf;
EndProcedure // Attachable_CheckBackgroundJobs

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction // CheckBackgroundJobStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure BlockForm_ShowProgressBar(pOperationName)
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Title	= NStr("en = 'Background operation in progress, you can continue to work in other forms  - '; ru = 'Выполняется фоновая операция, можете продолжать работать в других формах  - '; de = 'Die Hintergrundoperation läuft, Sie können weiterhin in anderen Formen arbeiten - '") + pOperationName;
	Items.BackgroundOperationProgress.Visible = True;
	Items.FormSaveAssignments.Enabled = False;
	Items.Reservations.Enabled = False;
	Items.GroupRooms.Enabled = False;
EndProcedure // BlockForm_ShowProgressBar

// -----------------------------------------------------------------------------
&AtClient
Procedure UnlockForm_HideProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = False;
	Items.FormSaveAssignments.Enabled = True;
	Items.Reservations.Enabled = True;
	Items.GroupRooms.Enabled = True;
	// Notify that operation has completed
	Notify("Subsystem.Accounts.Changed", CurReservation);
	Notify("Document.Reservation.Write", CurReservation, ThisForm);
EndProcedure // UnlockForm_HideProgressBar

// -----------------------------------------------------------------------------
&AtClient
Procedure UnlockForm_Completed()
	For Each vRowData In Reservations Do
		vRowData.IsChanged = False;
	EndDo;
	Items.BackgroundOperationProgress.Title	= NStr("en = 'Job completed!'; ru = 'Задача выполнена!'; de = 'Die Aufgabe abgeschlossen!'");
	Items.FormSaveAssignments.Enabled = True;
	Items.Reservations.Enabled = True;
	Items.GroupRooms.Enabled = True;
	// Notify that operation has completed
	Notify("Subsystem.Accounts.Changed", CurReservation);
	Notify("Document.Reservation.Write", CurReservation, ThisForm);
EndProcedure // UnlockForm_Completed

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsRoomOnChange(pItem)
	vCurData = Items.Reservations.CurrentData;
	If vCurData <> Undefined Then
		vCurData.IsChanged = True;
		// Add room to the selected rooms list
		If ValueIsFilled(vCurData.AccommodationTemplate) Or 
		   vCurData.AccommodationTypeType = PredefinedValue("Enum.AccomodationTypes.Room") Then
			If ValueIsFilled(CurRoom) Then
				vOldRoomItem = SelectedRoomsList.FindByValue(CurRoom);
				If vOldRoomItem <> Undefined Then
					SelectedRoomsList.Delete(vOldRoomItem);
				EndIf;
			EndIf;
			If ValueIsFilled(vCurData.Room) Then
				If SelectedRoomsList.FindByValue(vCurData.Room) = Undefined Then
					SelectedRoomsList.Add(vCurData.Room);
				EndIf;
			EndIf;
			Rooms.Parameters.SetParameterValue("qSelectedRoomsList", SelectedRoomsList);
		EndIf;
		CurRoom = vCurData.Room;
		// Check room type
		If ValueIsFilled(vCurData.Room) And ValueIsFilled(vCurData.Reservation) Then
			vOldRoomType = vCurData.RoomType;
			vReservation = vCurData.Reservation;
			vNewNumberOfBedsPerRoom = 0;
			vNewRoomType = GetRoomRoomType(vCurData.Room, vCurData.Reservation, vNewNumberOfBedsPerRoom);
			If ValueIsFilled(vNewRoomType) And vOldRoomType <> vNewRoomType Then
				If ValueIsFilled(vOldRoomType) Then
					vUpdatedResData = New ValueList();
					vUpdatedResData.Add(vCurData);
					vSaveOldRoomPrice = UseOldRoomTypePrices(vCurData.Reservation);
					vQryText = NStr("en='Do you want to use room type " + TrimAll(vOldRoomType) + " for price calculation for reservation - ';
					                |ru='Нужно ли для расчета стоимости проживания использовать тип номера " + TrimAll(vOldRoomType) + " для брони - ';
					                |de='Möchten Sie zur Berechnung der Tarifpreis der Zimmertyp " + TrimAll(vOldRoomType) + " verwenden für Reservierung - '") + TrimAll(vReservation) + "?" + Chars.LF + 
					           NStr("en='If you answer <No> then room price will be calculated by room type '; ru='Если ответите <Нет>, то стоимость проживания будет рассчитана по типу номера '; de='Wenn Sie <Nein> Antworten, wird der Zimmerpreis nach Zimmertyp '") + TrimAll(vNewRoomType) + NStr("en='.'; ru='.'; de=' berechnet.'");
					ShowQueryBox(New NotifyDescription("RoomsChoiceAfterRoomTypeChangeQuestionAnswer", ThisForm, New Structure("UpdatedResDataList, OldRoomType, NewRoomType", vUpdatedResData, vOldRoomType, vNewRoomType)), vQryText, QuestionDialogMode.YesNo, , ?(vSaveOldRoomPrice, DialogReturnCode.Yes, DialogReturnCode.No));
				Else
					vCurData.RoomType = vNewRoomType;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ReservationsRoomOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowAllRooms(pCommand)
	SelShowAll = Not SelShowAll;
	Items.RoomsShowAllRooms.Check = SelShowAll;
	// Fill rooms
	RefreshRoomsAtServer(True);
EndProcedure // ShowAllRooms

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If pField.Name = "ReservationsReservation" Then
		pStandardProcessing = False;
		vRowData = Reservations.FindByID(pSelectedRow);
		If vRowData <> Undefined Then
			OpenForm("Document.Reservation.ObjectForm", New Structure("Key", vRowData.Reservation), ThisForm, vRowData.Reservation);
		EndIf;
	EndIf;
EndProcedure // ReservationsSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesOnChange(pItem)
	RefreshRoomsAtServer(True);
EndProcedure // RoomPropertiesOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure AutoAssignment(pCommand)
	// Ask user to choose room folder
	OpenForm("Catalog.Rooms.FolderChoiceForm", New Structure("Filter", New Structure("Owner", SelHotel)), ThisForm, SelHotel);
EndProcedure // AutoAssignment

// --------------------------------------------------------------------------------
&AtServer
Procedure DoAutoAssignment(pFolderToStart)
	If ValueIsFilled(SelHotel) Then
		For Each vRowData In Reservations Do
			If Not ValueIsFilled(vRowData.Room) Then
				vDocRef = vRowData.Reservation;
				vVacantRooms = cmGetListOfVacantRoomsForReservation(1, vDocRef.Hotel, vDocRef.Company, vDocRef.RoomQuota, vDocRef.RoomType, vDocRef.CheckInDate, vDocRef.CheckOutDate);
				For Each vVacantRoomsRow In vVacantRooms Do
					vRoom = vVacantRoomsRow.Room;
					If vRoom.RoomStatus = SelHotel.VacantRoomStatus Or BegOfDay(vDocRef.CheckInDate) > BegOfDay(CurrentSessionDate()) Then
						If Not ValueIsFilled(pFolderToStart) Or ValueIsFilled(pFolderToStart) And vRoom.SortCode >= pFolderToStart.SortCode Then
							If Reservations.FindRows(New Structure("Room", vRoom)).Count() = 0 Then
								vStopSaleIsActiveForRoom = False;
								If vRoom.StopSale Then
									vRemarks = "";
									If cmIsRoomStopSalePeriod(vRoom, vDocRef.CheckInDate, vDocRef.CheckOutDate, vRemarks) Then
										If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
											vStopSaleIsActiveForRoom = True;
										EndIf;
									EndIf;
								EndIf;
								If Not vStopSaleIsActiveForRoom Then
									vReservationBedsSetup = vDocRef.BedsSetup;
									If Not ValueIsFilled(vReservationBedsSetup) Or vReservationBedsSetup = vRoom.BedsSetup Then
										vRowData.Room = vRoom;
										vRowData.IsChanged = True;
										// Add room to the selected rooms list
										If ValueIsFilled(vRowData.AccommodationTemplate) Or 
										  vRowData.AccommodationTypeType = PredefinedValue("Enum.AccomodationTypes.Room") Then
											If ValueIsFilled(vRowData.Room) Then
												If SelectedRoomsList.FindByValue(vRowData.Room) = Undefined Then
													SelectedRoomsList.Add(vRowData.Room);
												EndIf;
											EndIf;
										EndIf;
										// Go to the next reservation
										Break;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		Rooms.Parameters.SetParameterValue("qSelectedRoomsList", SelectedRoomsList);
	EndIf;
EndProcedure // DoAutoAssignment

// --------------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If pSelectedValue <> Undefined And TypeOf(pSelectedValue) = Type("CatalogRef.Rooms") Then
		If Not ValueIsFilled(pSelectedValue) Or ValueIsFilled(pSelectedValue) And tcOnServer.cmGetAttributeByRef(pSelectedValue, "IsFolder") Then
			DoAutoAssignment(pSelectedValue);
		EndIf;
	EndIf;
EndProcedure // ChoiceProcessing

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetKidsAgeArray(pDocRef, rNumberOfAdults, rNumberOfChildren)
	rNumberOfAdults = 0;
	rNumberOfChildren = 0;
	vKidsAgeArray = New Array;
	vDocs = cmGetOneRoomReservations(pDocRef.Number, pDocRef.GuestGroup, pDocRef.CheckInDate, pDocRef.CheckOutDate, False);
	For Each vDocsRow In vDocs Do
		vDocRef = vDocsRow.Ref;
		If vDocRef.GuestAge < 18 And vDocRef.GuestAge > 0 Then
			rNumberOfChildren = rNumberOfChildren + 1;
			vKidsAgeArray.Add(vDocRef.GuestAge);
		Else
			rNumberOfAdults = rNumberOfAdults + 1;
		EndIf;
	EndDo;
	Return vKidsAgeArray;
EndFunction // GetKidsAgeArray

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetDocumentDataStructure(pDocRef, pNumberOfAdults, pNumberOfChildren, pKidsAgeArray)
	vParams = New Structure("Hotel, RoomType, CheckInDate, CheckOutDate, Duration, RoomRate, ClientType, RoomQuota, NumberOfAdults, NumberOfKids, AgeArray", 
	                         pDocRef.Hotel, pDocRef.RoomType, pDocRef.CheckInDate, pDocRef.CheckOutDate, pDocRef.Duration, pDocRef.RoomRate, pDocRef.ClientType, pDocRef.RoomQuota, pNumberOfAdults, pNumberOfChildren, pKidsAgeArray);
	Return vParams;
EndFunction // GetDocumentDataStructure

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsRoomTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vRowData = Items.Reservations.CurrentData;
	If vRowData <> Undefined Then
		// APDEX
		vKeyOperation = "Catalog.RoomTypes.Form.tcChoiceForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		vDocRef = vRowData.Reservation;
		vNumberOfAdults = 0;
		vNumberOfChildren = 0;
		vKidsAgeArray = GetKidsAgeArray(vDocRef, vNumberOfAdults, vNumberOfChildren);
		vParams = GetDocumentDataStructure(vDocRef, vNumberOfAdults, vNumberOfChildren, vKidsAgeArray);
		vFrm = OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", vParams, pItem, vDocRef, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // ReservationsRoomTypeStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsRoomTypeChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	CurRemarks = "";
	CurHousekeepingRemarks = "";
	CurTasks = "";
	If TypeOf(pSelectedValue) = Type("CatalogRef.RoomTypes") Then
		vRowData = Items.Reservations.CurrentData;
		If vRowData <> Undefined Then
			vOldRoomType = vRowData.RoomType;
			
			vRowData.Room = PredefinedValue("Catalog.Rooms.EmptyRef");
			vRowData.RoomType = pSelectedValue;
			vRowData.IsChanged = True;
			
			CurReservation = vRowData.Reservation;
			CurRoomType = vRowData.RoomType;
			
			vUpdatedResData = New ValueList();
			vUpdatedResData.Add(vRowData);
			
			If Not ValueIsFilled(vRowData.RoomTypeUpgrade) And ValueIsFilled(vOldRoomType) And 
			   ValueIsFilled(vRowData.RoomType) And vOldRoomType <> vRowData.RoomType Then
				vSaveOldRoomPrice = UseOldRoomTypePrices(vRowData.Reservation);
				vQryText = NStr("en='Do you want to use room type " + TrimAll(vOldRoomType) + " for price calculation for reservation - ';
				                |ru='Нужно ли для расчета стоимости проживания использовать тип номера " + TrimAll(vOldRoomType) + " для брони - ';
				                |de='Möchten Sie zur Berechnung der Tarifpreis der Zimmertyp " + TrimAll(vOldRoomType) + " verwenden für Reservierung - '") + TrimAll(vRowData.Reservation) + "?" + Chars.LF + 
				           NStr("en='If you answer <No> then room price will be calculated by room type '; ru='Если ответите <Нет>, то стоимость проживания будет рассчитана по типу номера '; de='Wenn Sie <Nein> Antworten, wird der Zimmerpreis nach Zimmertyp '") + TrimAll(vRowData.RoomType) + NStr("en='.'; ru='.'; de=' berechnet.'");
				ShowQueryBox(New NotifyDescription("RoomsChoiceAfterRoomTypeChangeQuestionAnswer", ThisForm, New Structure("UpdatedResDataList, OldRoomType", vUpdatedResData, vOldRoomType)), vQryText, QuestionDialogMode.YesNo, , ?(vSaveOldRoomPrice, DialogReturnCode.Yes, DialogReturnCode.No));
			EndIf;
			
			// Fill rooms
			RefreshRoomsAtServer();
		EndIf;
	EndIf;	
EndProcedure // ReservationsRoomTypeChoiceProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearRooms(pCommand)
	If Items.Reservations.SelectedRows.Count() > 1 Then
		For Each vSelRowId In Items.Reservations.SelectedRows Do
			vRowData = Reservations.FindByID(vSelRowId);
			If ValueIsFilled(vRowData.Room) Then
				vOldRoom = vRowData.Room;
				vRowData.Room = PredefinedValue("Catalog.Rooms.EmptyRef");
				vRowData.IsChanged = True;
				If ValueIsFilled(vOldRoom) Then
					vOldRoomItem = SelectedRoomsList.FindByValue(vOldRoom);
					If vOldRoomItem <> Undefined Then
						SelectedRoomsList.Delete(vOldRoomItem);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	Else
		For Each vRowData In Reservations Do
			If ValueIsFilled(vRowData.Room) Then
				vRowData.Room = PredefinedValue("Catalog.Rooms.EmptyRef");
				vRowData.IsChanged = True;
			EndIf;
		EndDo;
		SelectedRoomsList.Clear();
	EndIf;			
	Rooms.Parameters.SetParameterValue("qSelectedRoomsList", SelectedRoomsList);
EndProcedure // ClearRooms

// --------------------------------------------------------------------------------
&AtClient
Procedure SelFilterByRoomTypeOnChange(pItem)
	CurRemarks = "";
	CurHousekeepingRemarks = "";
	CurTasks = "";
	vCurData = Items.Reservations.CurrentData;
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.Reservation) Then
			CurReservation = vCurData.Reservation;
			CurRoomType = vCurData.RoomType;
			vStruct = GetReservationTasksAndRemarks(CurReservation);
			CurRemarks = vStruct.Remarks;
			CurHousekeepingRemarks = vStruct.HousekeepingRemarks;
			CurTasks = vStruct.Tasks;
			CurBedsSetup = tcOnServer.cmGetAttributeByRef(vCurData.Reservation, "BedsSetup");
			
			// Fill rooms
			RefreshRoomsAtServer();
		EndIf;
	EndIf;
EndProcedure // SelFilterByRoomTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelFilterByBedsSetupOnChange(pItem)
	CurRemarks = "";
	CurHousekeepingRemarks = "";
	CurTasks = "";
	vCurData = Items.Reservations.CurrentData;
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.Reservation) Then
			CurReservation = vCurData.Reservation;
			CurRoomType = vCurData.RoomType;
			vStruct = GetReservationTasksAndRemarks(CurReservation);
			CurRemarks = vStruct.Remarks;
			CurHousekeepingRemarks = vStruct.HousekeepingRemarks;
			CurTasks = vStruct.Tasks;
			CurBedsSetup = tcOnServer.cmGetAttributeByRef(vCurData.Reservation, "BedsSetup");
			
			// Fill rooms
			RefreshRoomsAtServer();
		EndIf;
	EndIf;
EndProcedure // SelFilterByBedsSetupOnChange

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetNumberOfOccupiedBedsByReservtion(pAccommodationTemplate) 
	vNumberOfBeds = 0;
	If ValueIsFilled(pAccommodationTemplate) And pAccommodationTemplate.AccommodationTypes.Count() > 0 Then
		For Each vAccTmpAccTypeRow In pAccommodationTemplate.AccommodationTypes Do
			vCurAccType = vAccTmpAccTypeRow.AccommodationType;
			If ValueIsFilled(vCurAccType) And vCurAccType.Type = Enums.AccomodationTypes.Beds Then
				vNumberOfBeds = vNumberOfBeds + vCurAccType.NumberOfBeds;
			EndIf;
		EndDo;
	EndIf;
	If vNumberOfBeds = 0 Then
		vNumberOfBeds = 1;
	EndIf;
	Return vNumberOfBeds;
EndFunction // GetNumberOfOccupiedBedsByReservtion

// --------------------------------------------------------------------------------
&AtServer
Procedure SetBedsSetupAvailability()
	vUseBedsSetup = False;
	If ValueIsFilled(SelHotel) And Not SelHotel.IsFolder Then
		vUseBedsSetup = SelHotel.BedsSetups;
	EndIf;
	Items.ReservationsReservationBedsSetup.Visible = vUseBedsSetup;
	Items.SelFilterByBedsSetup.Visible = vUseBedsSetup;
	Items.RoomsBedsSetup.Visible = vUseBedsSetup;
EndProcedure // SetBedsSetupAvailability
