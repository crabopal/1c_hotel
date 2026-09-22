

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	vActualDocs = New ValueList();
	vOperations = New ValueTable();
	vOperations.Columns.Add("Employee", cmGetCatalogTypeDescription("Employees"));
	vOperations.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vOperations.Columns.Add("Room", cmGetCatalogTypeDescription("Rooms"));
	vOperations.Columns.Add("Operation", cmGetCatalogTypeDescription("Operations"));
	vOperations.Columns.Add("Quantity", cmGetNumberTypeDescription(6, 0));
	vOperations.Columns.Add("NumberOfPersons", cmGetNumberTypeDescription(6, 0));
	vCurRoom = Undefined;
	vNumberOfPersons = 0;
	For Each vOprRow In Operations Do
		vOperation = vOprRow.Operation;
		If ValueIsFilled(vOprRow.Room) And ValueIsFilled(vOprRow.RoomType) And 
		   ValueIsFilled(vOperation) And Not vOperation.OperationRegistrationIsUsed And 
		  (vOperation.ChatbotOperationRegistrationIsUsed Or ValueIsFilled(vOprRow.Employee)) Then
			vCurOprRow = vOperations.Add();
			vCurOprRow.Employee = vOprRow.Employee;
			vCurOprRow.RoomType = vOprRow.RoomType;
			vCurOprRow.Room = vOprRow.Room;
			vCurOprRow.Operation = vOprRow.Operation;
			If vCurOprRow.Operation = RegularOperationGroup And ValueIsFilled(RegularCleaning) Then
				vCurOprRow.Operation = RegularCleaning;
			EndIf;
			If vOprRow.CheckOutCleaningCount > 0 Then
				vCurOprRow.Quantity = vOprRow.CheckOutCleaningCount;
			ElsIf vOprRow.RepairEndCleaningCount > 0 Then
				vCurOprRow.Quantity = vOprRow.RepairEndCleaningCount;
			ElsIf vOprRow.RegularCleaningCount > 0 Then
				vCurOprRow.Quantity = vOprRow.RegularCleaningCount;
			ElsIf vOprRow.VacantRoomCleaningCount > 0 Then
				vCurOprRow.Quantity = vOprRow.VacantRoomCleaningCount;
			Else
				vCurOprRow.Quantity = 1;
			EndIf;
			If vCurRoom <> vOprRow.Room Then
				vCurRoom = vOprRow.Room;
				vNumberOfPersons = vOprRow.NumberOfGuests;
			EndIf;
			vCurOprRow.NumberOfPersons = vNumberOfPersons;
		EndIf;
	EndDo;
	vOperations.GroupBy("Employee, RoomType, Room, Operation", "Quantity, NumberOfPersons");
	For Each vOperationsRow In vOperations Do
		vOperation = vOperationsRow.Operation;
		// Get all documents for the given day
		vDocs = GetDayDocuments(vOperationsRow, Date);
		// If current day quantity is zero then get all documents for the given day and delete them
		If vOperationsRow.Quantity = 0 Then
			For Each vDocsRow In vDocs Do
				vDocObj = vDocsRow.Ref.GetObject();
				vDocObj.SetDeletionMark(True);
				// Save reference to the document being written
				vActualDocs.Add(vDocObj.Ref);
			EndDo;
		EndIf;
		// Update first one and delete all other
		vWriteDoc = False;
		vDocObj = Undefined;
		If vDocs.Count() > 0 And vOperationsRow.Quantity <> 0 Then
			If vDocs.Count() > 1 Then
				j = 1;
				While j < vDocs.Count() Do
					vDocObj = vDocs.Get(j).Ref.GetObject();
					If Not vDocObj.DeletionMark Then
						vDocObj.SetDeletionMark(True);
						// Save reference to the document being written
						vActualDocs.Add(vDocObj.Ref);
					EndIf;
					j = j + 1;
				EndDo;
			EndIf;
			vDocObj = vDocs.Get(0).Ref.GetObject();
		Else
			vWriteDoc = True;
			vDocObj = Documents.EmployeeOperation.CreateDocument();
			If ValueIsFilled(Hotel) And Not Hotel.IsFolder Then
				vDocObj.Hotel = Hotel;
			EndIf;
			vDocObj.pmFillAttributesWithDefaultValues();
			vDocObj.SetTime(AutoTimeMode.DontUse);
			vDocObj.Quantity = 0; // Reset quantity
			vDocObj.Employee = vOperationsRow.Employee;
			vDocObj.RoomType = vOperationsRow.RoomType;
			vDocObj.Room = vOperationsRow.Room;
			vDocObj.Operation = vOperation;
			If Not vOperation.ChatbotOperationRegistrationIsUsed Then
				vDocObj.OperationIntentTime = cm1SecondShift(Date);
				vDocObj.OperationStartTime = '00010101';
			Else
				vDocObj.OperationIntentTime = Date;
				vDocObj.OperationStartTime = '00010101';
			EndIf;
		EndIf;
		vDocObj.Date = Date;
		// Fill reference to the current document
		vDocObj.OperationSchedule = Ref;
		// Operation assignment time
		If ValueIsFilled(vOperationsRow.Employee) Then
			If Not ValueIsFilled(vDocObj.EmployeeAssignmentTime) Or vDocObj.Employee <> vOperationsRow.Employee Then
				vWriteDoc = True;
				vDocObj.Employee = vOperationsRow.Employee;
				vDocObj.EmployeeAssignmentTime = CurrentSessionDate();
			EndIf;
		ElsIf ValueIsFilled(vDocObj.Employee) Then
			vWriteDoc = True;
			vDocObj.Employee = Undefined;
			vDocObj.EmployeeAssignmentTime = '00010101';
		EndIf;
		// Write document only if it's quantity has changed
		If vWriteDoc Or vDocObj.Quantity <> vOperationsRow.Quantity Then
			vWriteDoc = True;
			// Fill quantity
			If vOperation.IsPerGuest Then
				vDocObj.Quantity = vOperationsRow.Quantity;
			Else
				vDocObj.Quantity = 1;
			EndIf;
			// Fill number of persons as number of beds in the room
			vDocObj.NumberOfPersons = vOperationsRow.NumberOfPersons;
			// Get operation standards
			vStds = Catalogs.Operations.GetOperationStandards(vOperation, vDocObj.Hotel, vDocObj.RoomType, vDocObj.Room, vDocObj.Employee);
			If vStds.Count() > 0 Then
				vStdsRow = vStds.Get(0);
				If Not vOperation.ChatbotOperationRegistrationIsUsed Then
					vDocObj.Duration = vStdsRow.Duration;
				EndIf;
				vDocObj.RoomSpace = vStdsRow.RoomSpace;
				vDocObj.Price = vStdsRow.Price;
			EndIf;
			// Fill operation articles consumption standards table
			vDocObj.Articles.Clear();
			vDocObj.pmFillArticles();
		EndIf;
		If vWriteDoc Then
			// Post document
			vDocObj.Write(DocumentWriteMode.Posting);
		EndIf;			
		// Save reference to the document being written
		vActualDocs.Add(vDocObj.Ref);
	EndDo;
	// Delete employee operations not created or update by current posting procedure
	vOperationScheduleDocs = pmGetEmployeeOperations();
	For Each vOperationScheduleDocsRow In vOperationScheduleDocs Do
		If vActualDocs.FindByValue(vOperationScheduleDocsRow.Ref) = Undefined Then
			vDocObj = vOperationScheduleDocsRow.Ref.GetObject();
			vDocObj.SetDeletionMark(True);
		EndIf;
	EndDo;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	vOperationScheduleDocs = pmGetEmployeeOperations();
	For Each vOperationScheduleDocsRow In vOperationScheduleDocs Do
		vDocObj = vOperationScheduleDocsRow.Ref.GetObject();
		vDocObj.SetDeletionmark(True);
	EndDo;
EndProcedure // UndoPosting

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)   
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(HousekeepingDepartment) Then
			HousekeepingDepartment = Hotel.HousekeepingDepartment;
		EndIf;
		If Not ValueIsFilled(CheckOutCleaning) Then
			CheckOutCleaning = Hotel.CheckOutCleaning;
		EndIf;
		If Not ValueIsFilled(RegularCleaning) Then
			RegularCleaning = Hotel.RegularCleaning;
		EndIf;
		If Not ValueIsFilled(VacantRoomCleaning) Then
			VacantRoomCleaning = Hotel.VacantRoomCleaning;
		EndIf;
		If Not ValueIsFilled(RepairEndCleaning) Then
			RepairEndCleaning = Hotel.RepairEndCleaning;
		EndIf;
		If Not ValueIsFilled(RegularOperationGroup) Then
			RegularOperationGroup = Hotel.RegularOperationGroup;
		EndIf;
		If Not ValueIsFilled(RoomStatusAfterCheckOut) Then
			RoomStatusAfterCheckOut = Hotel.RoomStatusAfterCheckOut;
		EndIf;
		If Not ValueIsFilled(RoomStatusAfterEarlyCheckIn) Then
			RoomStatusAfterEarlyCheckIn = Hotel.RoomStatusAfterEarlyCheckIn;
		EndIf;
		If Not ValueIsFilled(OccupiedDirtyRoomStatus) Then
			OccupiedDirtyRoomStatus = Hotel.OccupiedDirtyRoomStatus;
		EndIf;
		If Not ValueIsFilled(RoomStatusInspection) Then
			RoomStatusInspection = Hotel.RoomStatusInspection;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetOperations() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.Room AS Room,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
	|INTO RoomsList
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriod,
	|			Hotel = &qHotel
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (Room.RoomSection IN HIERARCHY (&qRoomSection)
	|					OR &qIsEmptyRoomSection)) AS RoomInventoryBalance
	|WHERE
	|	RoomInventoryBalance.TotalRoomsBalance > 0
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomStatusChangeHistory.Period AS Period,
	|	RoomStatusChangeHistory.User AS User,
	|	RoomStatusChangeHistory.Room AS Room,
	|	RoomStatusChangeHistory.RoomStatus AS RoomStatus
	|INTO RoomStatusLastChangeRecords
	|FROM
	|	InformationRegister.RoomStatusChangeHistory AS RoomStatusChangeHistory
	|		INNER JOIN InformationRegister.RoomStatusChangeHistory.SliceLast(
	|				&qStatusesStateDate,
	|				Room.Owner = &qHotel
	|					AND (Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|					AND (Room.RoomSection IN HIERARCHY (&qRoomSection)
	|						OR &qIsEmptyRoomSection)) AS RoomStatusChangeHistorySliceLast
	|		ON RoomStatusChangeHistory.Period = RoomStatusChangeHistorySliceLast.Period
	|			AND RoomStatusChangeHistory.Room = RoomStatusChangeHistorySliceLast.Room
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomsList.Hotel AS Hotel,
	|	RoomsList.Room AS Room,
	|	CASE
	|		WHEN RoomStatusLastChangeRecords.RoomStatus IS NOT NULL 
	|			THEN RoomStatusLastChangeRecords.RoomStatus
	|		ELSE RoomsList.Room.RoomStatus
	|	END AS RoomStatus,
	|	RoomsList.RoomType AS RoomType,
	|	RoomsList.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomsList.TotalBedsBalance AS TotalBedsBalance
	|INTO RoomsListWithStatuses
	|FROM
	|	RoomsList AS RoomsList
	|		LEFT JOIN RoomStatusLastChangeRecords AS RoomStatusLastChangeRecords
	|		ON RoomsList.Room = RoomStatusLastChangeRecords.Room
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryInHousePersons.Room AS Room,
	|	RoomInventoryInHousePersons.Recorder AS InHouseAccommodation,
	|	RoomInventoryInHousePersons.Recorder.ClientType AS InHouseClientType,
	|	RoomInventoryInHousePersons.Guest AS InHouseGuest,
	|	RoomInventoryInHousePersons.GuestGroup AS InHouseGuestGroup,
	|	RoomInventoryInHousePersons.Customer AS InHouseCustomer,
	|	RoomInventoryInHousePersons.NumberOfPersons AS InHouseNumberOfPersons,
	|	RoomInventoryInHousePersons.PeriodFrom AS InHousePeriodFrom,
	|	RoomInventoryInHousePersons.PeriodTo AS InHousePeriodTo,
	|	RoomInventoryInHousePersons.CheckInDate AS InHouseCheckInDate,
	|	RoomInventoryInHousePersons.CheckOutDate AS InHouseCheckOutDate,
	|	RoomInventoryInHousePersons.Recorder.RoomRate AS InHouseRoomRate,
	|	RoomInventoryInHousePersons.Recorder.RoomRate.Parent AS InHouseRoomRateParent,
	|	RoomInventoryInHousePersons.Recorder.RoomRate.Parent.Parent AS InHouseRoomRateParentParent
	|INTO RoomInventoryInHousePersonsList
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryInHousePersons
	|WHERE
	|	RoomInventoryInHousePersons.PeriodTo > &qPeriodTo
	|	AND RoomInventoryInHousePersons.RecordType = &qExpense
	|	AND RoomInventoryInHousePersons.IsInHouse
	|	AND RoomInventoryInHousePersons.Period = RoomInventoryInHousePersons.PeriodFrom
	|	AND RoomInventoryInHousePersons.Hotel = &qHotel
	|
	|INDEX BY
	|	InHousePeriodFrom
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryInHousePersons.Room AS Room,
	|	RoomInventoryInHousePersons.InHouseAccommodation AS InHouseAccommodation,
	|	RoomInventoryInHousePersons.InHouseClientType AS InHouseClientType,
	|	RoomInventoryInHousePersons.InHouseGuest AS InHouseGuest,
	|	RoomInventoryInHousePersons.InHouseGuestGroup AS InHouseGuestGroup,
	|	RoomInventoryInHousePersons.InHouseCustomer AS InHouseCustomer,
	|	RoomInventoryInHousePersons.InHouseNumberOfPersons AS InHouseNumberOfPersons,
	|	RoomInventoryInHousePersons.InHouseCheckInDate AS InHouseCheckInDate,
	|	RoomInventoryInHousePersons.InHouseCheckOutDate AS InHouseCheckOutDate,
	|	RoomInventoryInHousePersons.InHouseRoomRate AS InHouseRoomRate,
	|	RoomInventoryInHousePersons.InHouseRoomRateParent AS InHouseRoomRateParent,
	|	RoomInventoryInHousePersons.InHouseRoomRateParentParent AS InHouseRoomRateParentParent,
	|	MIN(RoomInventoryInHousePersons.InHousePeriodFrom) AS InHousePeriodFrom,
	|	MAX(RoomInventoryInHousePersons.InHousePeriodTo) AS InHousePeriodTo
	|INTO InHousePersons
	|FROM
	|	RoomInventoryInHousePersonsList AS RoomInventoryInHousePersons
	|WHERE
	|	RoomInventoryInHousePersons.InHousePeriodFrom < &qPeriodFrom
	|
	|GROUP BY
	|	RoomInventoryInHousePersons.Room,
	|	RoomInventoryInHousePersons.InHouseAccommodation,
	|	RoomInventoryInHousePersons.InHouseClientType,
	|	RoomInventoryInHousePersons.InHouseGuest,
	|	RoomInventoryInHousePersons.InHouseGuestGroup,
	|	RoomInventoryInHousePersons.InHouseCustomer,
	|	RoomInventoryInHousePersons.InHouseNumberOfPersons,
	|	RoomInventoryInHousePersons.InHouseCheckInDate,
	|	RoomInventoryInHousePersons.InHouseCheckOutDate,
	|	RoomInventoryInHousePersons.InHouseRoomRate,
	|	RoomInventoryInHousePersons.InHouseRoomRateParent,
	|	RoomInventoryInHousePersons.InHouseRoomRateParentParent
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryCheckedOutGuests.Room AS Room,
	|	RoomInventoryCheckedOutGuests.Recorder AS CheckOutAccommodation,
	|	RoomInventoryCheckedOutGuests.Recorder.ClientType AS CheckOutClientType,
	|	RoomInventoryCheckedOutGuests.IsInHouse AS CheckOutIsInHouse,
	|	RoomInventoryCheckedOutGuests.Guest AS CheckOutGuest,
	|	RoomInventoryCheckedOutGuests.GuestGroup AS CheckOutGuestGroup,
	|	RoomInventoryCheckedOutGuests.Customer AS CheckOutCustomer,
	|	RoomInventoryCheckedOutGuests.NumberOfPersons AS CheckOutNumberOfPersons,
	|	RoomInventoryCheckedOutGuests.CheckInDate AS CheckOutCheckInDate,
	|	RoomInventoryCheckedOutGuests.CheckOutDate AS CheckOutCheckOutDate,
	|	ISNULL(RoomInventoryCheckedOutGuests.Recorder.AccommodationStatus.IsInHouse, FALSE) AS CheckOutGuestIsInHouse
	|INTO CheckedOutGuests
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryCheckedOutGuests
	|WHERE
	|	RoomInventoryCheckedOutGuests.PeriodTo > &qPeriodFrom
	|	AND RoomInventoryCheckedOutGuests.PeriodTo <= &qPeriodTo
	|	AND RoomInventoryCheckedOutGuests.RecordType = &qReceipt
	|	AND RoomInventoryCheckedOutGuests.IsCheckOut
	|	AND RoomInventoryCheckedOutGuests.PeriodTo = RoomInventoryCheckedOutGuests.CheckOutDate
	|	AND RoomInventoryCheckedOutGuests.Period = RoomInventoryCheckedOutGuests.PeriodTo
	|	AND RoomInventoryCheckedOutGuests.Hotel = &qHotel
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryCheckedInPersons.Room AS Room,
	|	RoomInventoryCheckedInPersons.Recorder AS CheckedInAccommodation,
	|	RoomInventoryCheckedInPersons.Recorder.ClientType AS CheckedInClientType,
	|	RoomInventoryCheckedInPersons.Guest AS CheckedInGuest,
	|	RoomInventoryCheckedInPersons.GuestGroup AS CheckedInGuestGroup,
	|	RoomInventoryCheckedInPersons.Customer AS CheckedInCustomer,
	|	RoomInventoryCheckedInPersons.NumberOfPersons AS CheckedInNumberOfPersons,
	|	RoomInventoryCheckedInPersons.CheckInDate AS CheckedInCheckInDate,
	|	RoomInventoryCheckedInPersons.CheckOutDate AS CheckedInCheckOutDate
	|INTO CheckedInPersons
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryCheckedInPersons
	|WHERE
	|	RoomInventoryCheckedInPersons.PeriodFrom >= &qPeriodFrom
	|	AND RoomInventoryCheckedInPersons.PeriodFrom < &qPeriodTo
	|	AND RoomInventoryCheckedInPersons.RecordType = &qExpense
	|	AND RoomInventoryCheckedInPersons.IsInHouse
	|	AND RoomInventoryCheckedInPersons.PeriodFrom = RoomInventoryCheckedInPersons.CheckInDate
	|	AND RoomInventoryCheckedInPersons.Period = RoomInventoryCheckedInPersons.PeriodFrom
	|	AND RoomInventoryCheckedInPersons.Hotel = &qHotel
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomsListWithStatuses.Hotel AS Hotel,
	|	RoomsListWithStatuses.Room AS Room,
	|	RoomsListWithStatuses.RoomStatus AS RoomStatus,
	|	RoomsListWithStatuses.RoomType AS RoomType,
	|	RoomsListWithStatuses.RoomType.Parent AS RoomTypeParent,
	|	RoomsListWithStatuses.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomsListWithStatuses.TotalBedsBalance AS TotalBedsBalance,
	|	CheckedInPersons.CheckedInAccommodation AS CheckedInAccommodation,
	|	CheckedInPersons.CheckedInClientType AS CheckedInClientType,
	|	CheckedInPersons.CheckedInGuest AS CheckedInGuest,
	|	CheckedInPersons.CheckedInGuestGroup AS CheckedInGuestGroup,
	|	CheckedInPersons.CheckedInCustomer AS CheckedInCustomer,
	|	CheckedInPersons.CheckedInNumberOfPersons AS CheckedInNumberOfPersons,
	|	CheckedInPersons.CheckedInCheckInDate AS CheckedInCheckInDate,
	|	CheckedInPersons.CheckedInCheckOutDate AS CheckedInCheckOutDate,
	|	InHousePersons.InHouseAccommodation AS InHouseAccommodation,
	|	InHousePersons.InHouseClientType AS InHouseClientType,
	|	InHousePersons.InHouseGuest AS InHouseGuest,
	|	InHousePersons.InHouseGuestGroup AS InHouseGuestGroup,
	|	InHousePersons.InHouseCustomer AS InHouseCustomer,
	|	InHousePersons.InHouseNumberOfPersons AS InHouseNumberOfPersons,
	|	InHousePersons.InHousePeriodFrom AS InHousePeriodFrom,
	|	InHousePersons.InHousePeriodTo AS InHousePeriodTo,
	|	InHousePersons.InHouseCheckInDate AS InHouseCheckInDate,
	|	InHousePersons.InHouseCheckOutDate AS InHouseCheckOutDate,
	|	InHousePersons.InHouseRoomRate AS InHouseRoomRate,
	|	InHousePersons.InHouseRoomRateParent AS InHouseRoomRateParent,
	|	InHousePersons.InHouseRoomRateParentParent AS InHouseRoomRateParentParent,
	|	CheckedOutGuests.CheckOutAccommodation AS CheckOutAccommodation,
	|	CheckedOutGuests.CheckOutClientType AS CheckOutClientType,
	|	CheckedOutGuests.CheckOutIsInHouse AS CheckOutIsInHouse,
	|	CheckedOutGuests.CheckOutGuest AS CheckOutGuest,
	|	CheckedOutGuests.CheckOutGuestGroup AS CheckOutGuestGroup,
	|	CheckedOutGuests.CheckOutCustomer AS CheckOutCustomer,
	|	CheckedOutGuests.CheckOutNumberOfPersons AS CheckOutNumberOfPersons,
	|	CheckedOutGuests.CheckOutCheckInDate AS CheckOutCheckInDate,
	|	CheckedOutGuests.CheckOutCheckOutDate AS CheckOutCheckOutDate,
	|	CheckedOutGuests.CheckOutGuestIsInHouse AS CheckOutGuestIsInHouse
	|INTO BaseRoomsRecords
	|FROM
	|	RoomsListWithStatuses AS RoomsListWithStatuses
	|		LEFT JOIN InHousePersons AS InHousePersons
	|		ON RoomsListWithStatuses.Room = InHousePersons.Room
	|		LEFT JOIN CheckedOutGuests AS CheckedOutGuests
	|		ON RoomsListWithStatuses.Room = CheckedOutGuests.Room
	|		LEFT JOIN CheckedInPersons AS CheckedInPersons
	|		ON RoomsListWithStatuses.Room = CheckedInPersons.Room
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryLastCheckedOutGuests.Room AS Room,
	|	MAX(RoomInventoryLastCheckedOutGuests.PeriodTo) AS LastCheckOutDate
	|INTO RoomInventoryLastCheckedOutGuestsList
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryLastCheckedOutGuests
	|WHERE
	|	RoomInventoryLastCheckedOutGuests.PeriodFrom >= &qPeriodFrom
	|	AND RoomInventoryLastCheckedOutGuests.CheckOutDate <= &qPeriodFrom
	|	AND RoomInventoryLastCheckedOutGuests.RecordType = &qReceipt
	|	AND RoomInventoryLastCheckedOutGuests.IsCheckOut
	|	AND RoomInventoryLastCheckedOutGuests.Hotel = &qHotel
	|
	|GROUP BY
	|	RoomInventoryLastCheckedOutGuests.Room
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BaseRoomsRecords.Hotel AS Hotel,
	|	BaseRoomsRecords.Room AS Room,
	|	BaseRoomsRecords.RoomStatus AS RoomStatus,
	|	BaseRoomsRecords.RoomType AS RoomType,
	|	BaseRoomsRecords.RoomTypeParent AS RoomTypeParent,
	|	BaseRoomsRecords.TotalRoomsBalance AS TotalRoomsBalance,
	|	BaseRoomsRecords.TotalBedsBalance AS TotalBedsBalance,
	|	BaseRoomsRecords.CheckedInAccommodation AS CheckedInAccommodation,
	|	BaseRoomsRecords.CheckedInClientType AS CheckedInClientType,
	|	BaseRoomsRecords.CheckedInGuest AS CheckedInGuest,
	|	BaseRoomsRecords.CheckedInGuestGroup AS CheckedInGuestGroup,
	|	BaseRoomsRecords.CheckedInCustomer AS CheckedInCustomer,
	|	BaseRoomsRecords.CheckedInNumberOfPersons AS CheckedInNumberOfPersons,
	|	BaseRoomsRecords.CheckedInCheckInDate AS CheckedInCheckInDate,
	|	BaseRoomsRecords.CheckedInCheckOutDate AS CheckedInCheckOutDate,
	|	BaseRoomsRecords.InHouseAccommodation AS InHouseAccommodation,
	|	BaseRoomsRecords.InHouseClientType AS InHouseClientType,
	|	BaseRoomsRecords.InHouseGuest AS InHouseGuest,
	|	BaseRoomsRecords.InHouseGuestGroup AS InHouseGuestGroup,
	|	BaseRoomsRecords.InHouseCustomer AS InHouseCustomer,
	|	BaseRoomsRecords.InHouseNumberOfPersons AS InHouseNumberOfPersons,
	|	BaseRoomsRecords.InHousePeriodFrom AS InHousePeriodFrom,
	|	BaseRoomsRecords.InHousePeriodTo AS InHousePeriodTo,
	|	BaseRoomsRecords.InHouseCheckInDate AS InHouseCheckInDate,
	|	BaseRoomsRecords.InHouseCheckOutDate AS InHouseCheckOutDate,
	|	BaseRoomsRecords.InHouseRoomRate AS InHouseRoomRate,
	|	BaseRoomsRecords.InHouseRoomRateParent AS InHouseRoomRateParent,
	|	BaseRoomsRecords.InHouseRoomRateParentParent AS InHouseRoomRateParentParent,
	|	BaseRoomsRecords.CheckOutAccommodation AS CheckOutAccommodation,
	|	BaseRoomsRecords.CheckOutClientType AS CheckOutClientType,
	|	BaseRoomsRecords.CheckOutIsInHouse AS CheckOutIsInHouse,
	|	BaseRoomsRecords.CheckOutGuest AS CheckOutGuest,
	|	BaseRoomsRecords.CheckOutGuestGroup AS CheckOutGuestGroup,
	|	BaseRoomsRecords.CheckOutCustomer AS CheckOutCustomer,
	|	BaseRoomsRecords.CheckOutNumberOfPersons AS CheckOutNumberOfPersons,
	|	BaseRoomsRecords.CheckOutCheckInDate AS CheckOutCheckInDate,
	|	BaseRoomsRecords.CheckOutCheckOutDate AS CheckOutCheckOutDate,
	|	BaseRoomsRecords.CheckOutGuestIsInHouse AS CheckOutGuestIsInHouse,
	|	LastCheckedOutGuests.LastCheckOutDate AS LastCheckOutDate,
	|	CASE
	|		WHEN PlannedCheckedIn.Recorder IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS IsCheckInWaiting,
	|	PlannedCheckedIn.Recorder AS PlannedCheckInReservation,
	|	PlannedCheckedIn.ClientType AS PlannedCheckInClientType,
	|	PlannedCheckedIn.Guest AS PlannedCheckInGuest,
	|	PlannedCheckedIn.CheckInDate AS PlannedCheckInCheckInDate,
	|	PlannedCheckedIn.CheckOutDate AS PlannedCheckInCheckOutDate,
	|	PlannedCheckInTotals.ExpectedNumberOfPersons AS ExpectedNumberOfPersons
	|INTO RoomsRecordsWithExpectedData
	|FROM
	|	BaseRoomsRecords AS BaseRoomsRecords
	|		LEFT JOIN RoomInventoryLastCheckedOutGuestsList AS LastCheckedOutGuests
	|		ON BaseRoomsRecords.Room = LastCheckedOutGuests.Room
	|		LEFT JOIN AccumulationRegister.RoomInventory AS PlannedCheckedIn
	|		ON BaseRoomsRecords.Room = PlannedCheckedIn.Room
	|			AND (PlannedCheckedIn.PeriodFrom >= &qPeriodFrom)
	|			AND (PlannedCheckedIn.PeriodFrom < &qPeriodTo)
	|			AND (PlannedCheckedIn.RecordType = &qExpense)
	|			AND (PlannedCheckedIn.IsReservation)
	|			AND (PlannedCheckedIn.PeriodFrom = PlannedCheckedIn.CheckInDate)
	|			AND (PlannedCheckedIn.Period = PlannedCheckedIn.PeriodFrom)
	|			AND (PlannedCheckedIn.Hotel = &qHotel)
	|		LEFT JOIN (SELECT
	|			PlannedCheckInMovements.Room AS Room,
	|			SUM(PlannedCheckInMovements.NumberOfPersons) AS ExpectedNumberOfPersons
	|		FROM
	|			AccumulationRegister.RoomInventory AS PlannedCheckInMovements
	|		WHERE
	|			PlannedCheckInMovements.PeriodFrom >= &qPeriodFrom
	|			AND PlannedCheckInMovements.PeriodFrom < &qPeriodTo
	|			AND PlannedCheckInMovements.RecordType = &qExpense
	|			AND PlannedCheckInMovements.IsReservation
	|			AND PlannedCheckInMovements.PeriodFrom = PlannedCheckInMovements.CheckInDate
	|			AND PlannedCheckInMovements.Period = PlannedCheckInMovements.PeriodFrom
	|			AND PlannedCheckInMovements.Hotel = &qHotel
	|		
	|		GROUP BY
	|			PlannedCheckInMovements.Room) AS PlannedCheckInTotals
	|		ON BaseRoomsRecords.Room = PlannedCheckInTotals.Room
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomBlock.Ref AS Ref,
	|	RoomBlock.DateFrom AS DateFrom,
	|	RoomBlock.RoomBlockType AS RoomBlockType
	|INTO RoomBlockList
	|FROM
	|	Document.SetRoomBlock AS RoomBlock
	|WHERE
	|	RoomBlock.DateTo > &qPeriodFrom
	|	AND RoomBlock.DateFrom < &qPeriodTo
	|	AND RoomBlock.Hotel = &qHotel
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBlock.Room AS Room,
	|	RoomBlockList.RoomBlockType AS CurrentRoomBlockType
	|INTO RoomBlocks
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryBlock
	|		INNER JOIN RoomBlockList AS RoomBlockList
	|		ON RoomInventoryBlock.Recorder = RoomBlockList.Ref
	|			AND (RoomBlockList.DateFrom = RoomInventoryBlock.CheckInDate)
	|WHERE
	|	RoomInventoryBlock.RecordType = &qExpense
	|	AND RoomInventoryBlock.IsBlocking
	|	AND RoomInventoryBlock.Hotel = &qHotel
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomBlockRepairs.Ref AS Ref,
	|	RoomBlockRepairs.DateFrom AS DateFrom
	|INTO RoomBlockRepairsList
	|FROM
	|	Document.SetRoomBlock AS RoomBlockRepairs
	|WHERE
	|	(RoomBlockRepairs.DateTo > &qPeriodFrom
	|			OR RoomBlockRepairs.DateTo = &qEmptyDate)
	|	AND RoomBlockRepairs.DateFrom < &qPeriodTo
	|	AND RoomBlockRepairs.RoomBlockType.IsRoomRepair
	|	AND RoomBlockRepairs.Hotel = &qHotel
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryRepairs.Room AS Room,
	|	RoomInventoryRepairs.Recorder AS RoomRepairsRecorder
	|INTO RoomRepairs
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryRepairs
	|		INNER JOIN RoomBlockRepairsList AS RoomBlockRepairsList
	|		ON RoomInventoryRepairs.Recorder = RoomBlockRepairsList.Ref
	|			AND (RoomBlockRepairsList.DateFrom = RoomInventoryRepairs.CheckInDate)
	|WHERE
	|	RoomInventoryRepairs.RecordType = &qExpense
	|	AND RoomInventoryRepairs.Hotel = &qHotel
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomFinishedBlock.Ref AS Ref,
	|	RoomFinishedBlock.DateFrom AS DateFrom,
	|	RoomFinishedBlock.RoomBlockType AS RoomBlockType
	|INTO RoomFinishedBlockList
	|FROM
	|	Document.SetRoomBlock AS RoomFinishedBlock
	|WHERE
	|	RoomFinishedBlock.DateTo > &qPeriodFrom
	|	AND RoomFinishedBlock.DateTo <= &qPeriodTo
	|	AND ISNULL(RoomFinishedBlock.RoomBlockType.IsRoomRepair, FALSE)
	|	AND RoomFinishedBlock.Hotel = &qHotel
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryFinishedBlocks.Room AS Room,
	|	RoomInventoryFinishedBlocks.Recorder AS SetRoomBlock,
	|	RoomInventoryFinishedBlocks.RoomBlockType AS RoomBlockType,
	|	SUBSTRING(RoomInventoryFinishedBlocks.Remarks, 1, 999) AS RoomBlockRemarks,
	|	RoomInventoryFinishedBlocks.CheckInDate AS RoomBlockStartDate,
	|	RoomInventoryFinishedBlocks.CheckOutDate AS RoomBlockEndDate
	|INTO FinishedRoomBlocks
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryFinishedBlocks
	|		INNER JOIN RoomFinishedBlockList AS RoomFinishedBlockList
	|		ON RoomInventoryFinishedBlocks.Recorder = RoomFinishedBlockList.Ref
	|			AND (RoomFinishedBlockList.DateFrom = RoomInventoryFinishedBlocks.CheckInDate)
	|WHERE
	|	RoomInventoryFinishedBlocks.RecordType = &qExpense
	|	AND RoomInventoryFinishedBlocks.Hotel = &qHotel
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomsRecordsWithExpectedData.Hotel AS Hotel,
	|	RoomsRecordsWithExpectedData.Room AS Room,
	|	RoomsRecordsWithExpectedData.RoomStatus AS RoomStatus,
	|	RoomsRecordsWithExpectedData.RoomType AS RoomType,
	|	RoomsRecordsWithExpectedData.RoomTypeParent AS RoomTypeParent,
	|	RoomsRecordsWithExpectedData.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomsRecordsWithExpectedData.TotalBedsBalance AS TotalBedsBalance,
	|	RoomsRecordsWithExpectedData.CheckedInAccommodation AS CheckedInAccommodation,
	|	RoomsRecordsWithExpectedData.CheckedInClientType AS CheckedInClientType,
	|	RoomsRecordsWithExpectedData.CheckedInGuest AS CheckedInGuest,
	|	RoomsRecordsWithExpectedData.CheckedInGuestGroup AS CheckedInGuestGroup,
	|	RoomsRecordsWithExpectedData.CheckedInCustomer AS CheckedInCustomer,
	|	RoomsRecordsWithExpectedData.CheckedInNumberOfPersons AS CheckedInNumberOfPersons,
	|	RoomsRecordsWithExpectedData.CheckedInCheckInDate AS CheckedInCheckInDate,
	|	RoomsRecordsWithExpectedData.CheckedInCheckOutDate AS CheckedInCheckOutDate,
	|	RoomsRecordsWithExpectedData.InHouseAccommodation AS InHouseAccommodation,
	|	RoomsRecordsWithExpectedData.InHouseClientType AS InHouseClientType,
	|	RoomsRecordsWithExpectedData.InHouseGuest AS InHouseGuest,
	|	RoomsRecordsWithExpectedData.InHouseGuestGroup AS InHouseGuestGroup,
	|	RoomsRecordsWithExpectedData.InHouseCustomer AS InHouseCustomer,
	|	RoomsRecordsWithExpectedData.InHouseNumberOfPersons AS InHouseNumberOfPersons,
	|	RoomsRecordsWithExpectedData.InHousePeriodFrom AS InHousePeriodFrom,
	|	RoomsRecordsWithExpectedData.InHousePeriodTo AS InHousePeriodTo,
	|	RoomsRecordsWithExpectedData.InHouseCheckInDate AS InHouseCheckInDate,
	|	RoomsRecordsWithExpectedData.InHouseCheckOutDate AS InHouseCheckOutDate,
	|	RoomsRecordsWithExpectedData.InHouseRoomRate AS InHouseRoomRate,
	|	RoomsRecordsWithExpectedData.InHouseRoomRateParent AS InHouseRoomRateParent,
	|	RoomsRecordsWithExpectedData.InHouseRoomRateParentParent AS InHouseRoomRateParentParent,
	|	RoomsRecordsWithExpectedData.CheckOutAccommodation AS CheckOutAccommodation,
	|	RoomsRecordsWithExpectedData.CheckOutClientType AS CheckOutClientType,
	|	RoomsRecordsWithExpectedData.CheckOutIsInHouse AS CheckOutIsInHouse,
	|	RoomsRecordsWithExpectedData.CheckOutGuest AS CheckOutGuest,
	|	RoomsRecordsWithExpectedData.CheckOutGuestGroup AS CheckOutGuestGroup,
	|	RoomsRecordsWithExpectedData.CheckOutCustomer AS CheckOutCustomer,
	|	RoomsRecordsWithExpectedData.CheckOutNumberOfPersons AS CheckOutNumberOfPersons,
	|	RoomsRecordsWithExpectedData.CheckOutCheckInDate AS CheckOutCheckInDate,
	|	RoomsRecordsWithExpectedData.CheckOutCheckOutDate AS CheckOutCheckOutDate,
	|	RoomsRecordsWithExpectedData.CheckOutGuestIsInHouse AS CheckOutGuestIsInHouse,
	|	RoomsRecordsWithExpectedData.LastCheckOutDate AS LastCheckOutDate,
	|	RoomsRecordsWithExpectedData.IsCheckInWaiting AS IsCheckInWaiting,
	|	RoomsRecordsWithExpectedData.PlannedCheckInReservation AS PlannedCheckInReservation,
	|	RoomsRecordsWithExpectedData.PlannedCheckInClientType AS PlannedCheckInClientType,
	|	RoomsRecordsWithExpectedData.PlannedCheckInGuest AS PlannedCheckInGuest,
	|	RoomsRecordsWithExpectedData.PlannedCheckInCheckInDate AS PlannedCheckInCheckInDate,
	|	RoomsRecordsWithExpectedData.PlannedCheckInCheckOutDate AS PlannedCheckInCheckOutDate,
	|	RoomsRecordsWithExpectedData.ExpectedNumberOfPersons AS ExpectedNumberOfPersons,
	|	RoomBlocks.CurrentRoomBlockType AS CurrentRoomBlockType,
	|	FinishedRoomBlocks.SetRoomBlock AS SetRoomBlock,
	|	FinishedRoomBlocks.RoomBlockType AS RoomBlockType,
	|	FinishedRoomBlocks.RoomBlockRemarks AS RoomBlockRemarks,
	|	FinishedRoomBlocks.RoomBlockStartDate AS RoomBlockStartDate,
	|	FinishedRoomBlocks.RoomBlockEndDate AS RoomBlockEndDate,
	|	RoomRepairs.RoomRepairsRecorder AS RoomRepairsRecorder
	|INTO RoomsRecordsWithBlocks
	|FROM
	|	RoomsRecordsWithExpectedData AS RoomsRecordsWithExpectedData
	|		LEFT JOIN RoomBlocks AS RoomBlocks
	|		ON RoomsRecordsWithExpectedData.Room = RoomBlocks.Room
	|		LEFT JOIN RoomRepairs AS RoomRepairs
	|		ON RoomsRecordsWithExpectedData.Room = RoomRepairs.Room
	|		LEFT JOIN FinishedRoomBlocks AS FinishedRoomBlocks
	|		ON RoomsRecordsWithExpectedData.Room = FinishedRoomBlocks.Room
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RoomsRecordsWithBlocks.Hotel AS Hotel,
	|	RoomsRecordsWithBlocks.Room AS Room,
	|	RoomsRecordsWithBlocks.RoomStatus AS RoomStatus,
	|	RoomsRecordsWithBlocks.RoomType AS RoomType,
	|	RoomsRecordsWithBlocks.RoomTypeParent AS RoomTypeParent,
	|	RoomsRecordsWithBlocks.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomsRecordsWithBlocks.TotalBedsBalance AS TotalBedsBalance,
	|	RoomsRecordsWithBlocks.CheckedInAccommodation AS CheckedInAccommodation,
	|	RoomsRecordsWithBlocks.CheckedInClientType AS CheckedInClientType,
	|	RoomsRecordsWithBlocks.CheckedInGuest AS CheckedInGuest,
	|	RoomsRecordsWithBlocks.CheckedInGuestGroup AS CheckedInGuestGroup,
	|	RoomsRecordsWithBlocks.CheckedInCustomer AS CheckedInCustomer,
	|	RoomsRecordsWithBlocks.CheckedInNumberOfPersons AS CheckedInNumberOfPersons,
	|	RoomsRecordsWithBlocks.CheckedInCheckInDate AS CheckedInCheckInDate,
	|	RoomsRecordsWithBlocks.CheckedInCheckOutDate AS CheckedInCheckOutDate,
	|	RoomsRecordsWithBlocks.InHouseAccommodation AS InHouseAccommodation,
	|	RoomsRecordsWithBlocks.InHouseClientType AS InHouseClientType,
	|	RoomsRecordsWithBlocks.InHouseGuest AS InHouseGuest,
	|	RoomsRecordsWithBlocks.InHouseGuestGroup AS InHouseGuestGroup,
	|	RoomsRecordsWithBlocks.InHouseCustomer AS InHouseCustomer,
	|	RoomsRecordsWithBlocks.InHouseNumberOfPersons AS InHouseNumberOfPersons,
	|	RoomsRecordsWithBlocks.InHousePeriodFrom AS InHousePeriodFrom,
	|	RoomsRecordsWithBlocks.InHousePeriodTo AS InHousePeriodTo,
	|	RoomsRecordsWithBlocks.InHouseCheckInDate AS InHouseCheckInDate,
	|	RoomsRecordsWithBlocks.InHouseCheckOutDate AS InHouseCheckOutDate,
	|	RoomsRecordsWithBlocks.InHouseRoomRate AS InHouseRoomRate,
	|	RoomsRecordsWithBlocks.InHouseRoomRateParent AS InHouseRoomRateParent,
	|	RoomsRecordsWithBlocks.InHouseRoomRateParentParent AS InHouseRoomRateParentParent,
	|	RoomsRecordsWithBlocks.CheckOutAccommodation AS CheckOutAccommodation,
	|	RoomsRecordsWithBlocks.CheckOutClientType AS CheckOutClientType,
	|	RoomsRecordsWithBlocks.CheckOutIsInHouse AS CheckOutIsInHouse,
	|	RoomsRecordsWithBlocks.CheckOutGuest AS CheckOutGuest,
	|	RoomsRecordsWithBlocks.CheckOutGuestGroup AS CheckOutGuestGroup,
	|	RoomsRecordsWithBlocks.CheckOutCustomer AS CheckOutCustomer,
	|	RoomsRecordsWithBlocks.CheckOutNumberOfPersons AS CheckOutNumberOfPersons,
	|	RoomsRecordsWithBlocks.CheckOutCheckInDate AS CheckOutCheckInDate,
	|	RoomsRecordsWithBlocks.CheckOutCheckOutDate AS CheckOutCheckOutDate,
	|	RoomsRecordsWithBlocks.CheckOutGuestIsInHouse AS CheckOutGuestIsInHouse,
	|	RoomsRecordsWithBlocks.LastCheckOutDate AS LastCheckOutDate,
	|	RoomsRecordsWithBlocks.IsCheckInWaiting AS IsCheckInWaiting,
	|	RoomsRecordsWithBlocks.PlannedCheckInReservation AS PlannedCheckInReservation,
	|	RoomsRecordsWithBlocks.PlannedCheckInClientType AS PlannedCheckInClientType,
	|	RoomsRecordsWithBlocks.PlannedCheckInGuest AS PlannedCheckInGuest,
	|	RoomsRecordsWithBlocks.PlannedCheckInCheckInDate AS PlannedCheckInCheckInDate,
	|	RoomsRecordsWithBlocks.PlannedCheckInCheckOutDate AS PlannedCheckInCheckOutDate,
	|	RoomsRecordsWithBlocks.ExpectedNumberOfPersons AS ExpectedNumberOfPersons,
	|	RoomsRecordsWithBlocks.CurrentRoomBlockType AS CurrentRoomBlockType,
	|	RoomsRecordsWithBlocks.SetRoomBlock AS SetRoomBlock,
	|	RoomsRecordsWithBlocks.RoomBlockType AS RoomBlockType,
	|	RoomsRecordsWithBlocks.RoomBlockRemarks AS RoomBlockRemarks,
	|	RoomsRecordsWithBlocks.RoomBlockStartDate AS RoomBlockStartDate,
	|	RoomsRecordsWithBlocks.RoomBlockEndDate AS RoomBlockEndDate,
	|	RoomsRecordsWithBlocks.RoomRepairsRecorder AS RoomRepairsRecorder,
	|	RegularOperations.RegularOperation AS RegularOperation,
	|	ISNULL(RegularOperations.RegularOperation.SortCode, 999999) AS RegularOperationSortCode
	|INTO RoomsRecords
	|FROM
	|	RoomsRecordsWithBlocks AS RoomsRecordsWithBlocks
	|		LEFT JOIN Catalog.RegularOperationGroups.RegularOperations AS RegularOperations
	|		ON (RegularOperations.Ref = &qRegularOperationGroup)
	|			AND (RegularOperations.PerformWhenRoomIsBusy
	|					AND DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(RoomsRecordsWithBlocks.InHousePeriodFrom, DAY), DAY) / RegularOperations.RegularOperationFrequency = (CAST(DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(RoomsRecordsWithBlocks.InHousePeriodFrom, DAY), DAY) / RegularOperations.RegularOperationFrequency AS NUMBER(17, 0)))
	|					AND (&qPeriodFrom = BEGINOFPERIOD(RoomsRecordsWithBlocks.InHousePeriodFrom, DAY)
	|							AND RegularOperations.PerformOnCheckInDay
	|						OR &qPeriodFrom = BEGINOFPERIOD(RoomsRecordsWithBlocks.InHousePeriodTo, DAY)
	|							AND RegularOperations.PerformOnCheckOutDay
	|						OR &qPeriodFrom > BEGINOFPERIOD(RoomsRecordsWithBlocks.InHousePeriodFrom, DAY)
	|							AND &qPeriodFrom < BEGINOFPERIOD(RoomsRecordsWithBlocks.InHousePeriodTo, DAY)
	|							AND NOT RegularOperations.PerformOnCheckInDay
	|							AND NOT RegularOperations.PerformOnCheckOutDay)
	|				OR RegularOperations.PerformWhenRoomIsBusy
	|					AND RegularOperations.PerformOnCheckInDay
	|					AND RoomsRecordsWithBlocks.CheckedInAccommodation IS NOT NULL 
	|				OR RegularOperations.PerformWhenRoomIsBusy
	|					AND RegularOperations.PerformOnCheckOutDay
	|					AND RoomsRecordsWithBlocks.CheckOutAccommodation IS NOT NULL 
	|				OR RegularOperations.PerformWhenRoomIsFree
	|					AND RoomsRecordsWithBlocks.InHouseAccommodation IS NULL
	|					AND RoomsRecordsWithBlocks.CheckedInAccommodation IS NULL
	|					AND RoomsRecordsWithBlocks.CheckOutAccommodation IS NULL
	|					AND (RegularOperations.RegularOperationFrequency = 0
	|						OR RegularOperations.RegularOperationFrequency = 1
	|						OR RegularOperations.RegularOperationFrequency > 1
	|							AND DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(RoomsRecordsWithBlocks.LastCheckOutDate, DAY), DAY) / RegularOperations.RegularOperationFrequency = (CAST(DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(RoomsRecordsWithBlocks.LastCheckOutDate, DAY), DAY) / RegularOperations.RegularOperationFrequency AS NUMBER(17, 0)))
	|							AND DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(RoomsRecordsWithBlocks.LastCheckOutDate, DAY), DAY) <> 0))
	|			AND (NOT RegularOperations.DoNotPerformOnWeekends
	|				OR RegularOperations.DoNotPerformOnWeekends
	|					AND WEEKDAY(&qPeriodFrom) < 6)
	|			AND (RegularOperations.RoomType = &qEmptyRoomType
	|				OR RegularOperations.RoomType <> &qEmptyRoomType
	|					AND RoomsRecordsWithBlocks.RoomType = RegularOperations.RoomType
	|				OR RegularOperations.RoomType <> &qEmptyRoomType
	|					AND RoomsRecordsWithBlocks.RoomTypeParent <> &qEmptyRoomType
	|					AND RoomsRecordsWithBlocks.RoomTypeParent = RegularOperations.RoomType)
	|			AND (RegularOperations.RoomRate = &qEmptyRoomRate
	|				OR RegularOperations.RoomRate <> &qEmptyRoomRate
	|					AND RoomsRecordsWithBlocks.InHouseRoomRate IS NOT NULL 
	|					AND RoomsRecordsWithBlocks.InHouseRoomRate <> &qEmptyRoomRate
	|					AND (RoomsRecordsWithBlocks.InHouseRoomRate = RegularOperations.RoomRate
	|						OR RoomsRecordsWithBlocks.InHouseRoomRateParent = RegularOperations.RoomRate
	|						OR RoomsRecordsWithBlocks.InHouseRoomRateParentParent = RegularOperations.RoomRate))
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomStatuses.Ref AS RoomStatus,
	|	RoomStatuses.Operation AS Operation,
	|	Operations.SortCode AS OperationSortCode
	|INTO RoomStatusesWithOperation
	|FROM
	|	Catalog.RoomStatuses AS RoomStatuses
	|		INNER JOIN Catalog.Operations AS Operations
	|		ON RoomStatuses.Operation = Operations.Ref
	|WHERE
	|	NOT Operations.DeletionMark
	|	AND NOT Operations.IsFolder
	|	AND NOT RoomStatuses.DoEmployeeOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CleaningTasks.Hotel AS Hotel,
	|	CleaningTasks.Hotel.SortCode AS HotelSortCode,
	|	CleaningTasks.Room AS Room,
	|	CleaningTasks.Room.SortCode AS RoomSortCode,
	|	CleaningTasks.RoomType AS RoomType,
	|	CleaningTasks.RoomType.SortCode AS RoomTypeSortCode,
	|	CleaningTasks.RoomStatus AS RoomStatus,
	|	CleaningTasks.RoomStatusChangeTime AS RoomStatusChangeTime,
	|	CleaningTasks.RoomStatusChangeAuthor AS RoomStatusChangeAuthor,
	|	CASE
	|		WHEN CleaningTasks.CheckOutCleaning IS NOT NULL 
	|			THEN CleaningTasks.CheckOutCleaning
	|		WHEN CleaningTasks.RegularOperation IS NOT NULL 
	|			THEN CleaningTasks.RegularOperation
	|		WHEN CleaningTasks.RegularCleaning IS NOT NULL 
	|			THEN CleaningTasks.RegularCleaning
	|		WHEN CleaningTasks.RepairEndCleaning IS NOT NULL 
	|			THEN CleaningTasks.RepairEndCleaning
	|		WHEN CleaningTasks.VacantRoomCleaning IS NOT NULL 
	|			THEN CleaningTasks.VacantRoomCleaning
	|		WHEN RoomStatusesWithOperation.Operation IS NOT NULL 
	|			THEN RoomStatusesWithOperation.Operation
	|		ELSE NULL
	|	END AS Operation,
	|	CASE
	|		WHEN CleaningTasks.CheckOutCleaning IS NOT NULL 
	|			THEN CleaningTasks.CheckOutCleaningSortCode
	|		WHEN CleaningTasks.RegularOperation IS NOT NULL 
	|			THEN CleaningTasks.RegularOperationSortCode
	|		WHEN CleaningTasks.RegularCleaning IS NOT NULL 
	|			THEN CleaningTasks.RegularCleaningSortCode
	|		WHEN CleaningTasks.RepairEndCleaning IS NOT NULL 
	|			THEN CleaningTasks.RepairEndCleaningSortCode
	|		WHEN CleaningTasks.VacantRoomCleaning IS NOT NULL 
	|			THEN CleaningTasks.VacantRoomCleaningSortCode
	|		WHEN RoomStatusesWithOperation.Operation IS NOT NULL 
	|			THEN RoomStatusesWithOperation.OperationSortCode
	|		ELSE 999999
	|	END AS OperationSortCode,
	|	CASE
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				AND CleaningTasks.CheckOutGuestIsInHouse
	|			THEN CleaningTasks.CheckOutGuest
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseGuest
	|		WHEN CleaningTasks.CheckedInAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckedInGuest
	|		WHEN CleaningTasks.PlannedCheckInReservation IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckInGuest
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutGuest
	|		ELSE NULL
	|	END AS Guest,
	|	CASE
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				AND CleaningTasks.CheckOutGuestIsInHouse
	|			THEN CleaningTasks.CheckOutGuestFullName
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseGuestFullName
	|		WHEN CleaningTasks.CheckedInAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckedInGuestFullName
	|		WHEN CleaningTasks.PlannedCheckInReservation IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckInGuest
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutGuestFullName
	|		ELSE NULL
	|	END AS GuestFullName,
	|	CASE
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				AND CleaningTasks.CheckOutGuestIsInHouse
	|			THEN CleaningTasks.CheckOutGuestDateOfBirth
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseGuestDateOfBirth
	|		WHEN CleaningTasks.CheckedInAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckedInGuestDateOfBirth
	|		WHEN CleaningTasks.PlannedCheckInReservation IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckInGuestDateOfBirth
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutGuestDateOfBirth
	|		ELSE NULL
	|	END AS GuestDateOfBirth,
	|	CASE
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				AND CleaningTasks.CheckOutGuestIsInHouse
	|			THEN CleaningTasks.CheckOutGuest.Citizenship
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseGuest.Citizenship
	|		WHEN CleaningTasks.CheckedInAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckedInGuest.Citizenship
	|		WHEN CleaningTasks.PlannedCheckInReservation IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckInGuest.Citizenship
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutGuest.Citizenship
	|		ELSE NULL
	|	END AS Citizenship,
	|	CleaningTasks.ClientType AS ClientType,
	|	CASE
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				AND CleaningTasks.CheckOutGuestIsInHouse
	|			THEN CleaningTasks.CheckOutCheckInDate
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseCheckInDate
	|		WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|			THEN CleaningTasks.RoomBlockStartDate
	|		WHEN CleaningTasks.CheckedInAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckedInCheckInDate
	|		WHEN CleaningTasks.PlannedCheckInReservation IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckInCheckInDate
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutCheckInDate
	|		ELSE NULL
	|	END AS CheckInDate,
	|	CASE
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				AND CleaningTasks.CheckOutGuestIsInHouse
	|			THEN CleaningTasks.CheckOutCheckOutDate
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseCheckOutDate
	|		WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|			THEN CleaningTasks.RoomBlockEndDate
	|		WHEN CleaningTasks.CheckedInAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckedInCheckOutDate
	|		WHEN CleaningTasks.PlannedCheckInReservation IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckInCheckOutDate
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutCheckOutDate
	|		ELSE NULL
	|	END AS CheckOutDate,
	|	CASE
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				AND CleaningTasks.CheckOutGuestIsInHouse
	|			THEN CleaningTasks.CheckOutAccommodation
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseAccommodation
	|		WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|			THEN CleaningTasks.SetRoomBlock
	|		WHEN CleaningTasks.CheckedInAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckedInAccommodation
	|		WHEN CleaningTasks.PlannedCheckInReservation IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckInReservation
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutAccommodation
	|		ELSE NULL
	|	END AS ParentDoc,
	|	CASE
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				AND CleaningTasks.CheckOutGuestIsInHouse
	|			THEN CleaningTasks.CheckOutAccommodation.AccommodationType.SortCode
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseAccommodation.AccommodationType.SortCode
	|		WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|			THEN 999999999
	|		WHEN CleaningTasks.CheckedInAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckedInAccommodation.AccommodationType.SortCode
	|		WHEN CleaningTasks.PlannedCheckInReservation IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckInReservation.AccommodationType.SortCode
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutAccommodation.AccommodationType.SortCode
	|		ELSE NULL
	|	END AS AccommodationTypeSortCode,
	|	CleaningTasks.CheckOutCleaning AS CheckOutCleaning,
	|	CleaningTasks.RegularCleaning AS RegularCleaning,
	|	CleaningTasks.RepairEndCleaning AS RepairEndCleaning,
	|	CASE
	|		WHEN ISNULL(CleaningTasks.VacantRoomCleaning, VALUE(Catalog.Operations.EmptyRef)) <> VALUE(Catalog.Operations.EmptyRef)
	|			THEN CleaningTasks.VacantRoomCleaning
	|		WHEN RoomStatusesWithOperation.Operation IS NOT NULL 
	|			THEN RoomStatusesWithOperation.Operation
	|		ELSE NULL
	|	END AS VacantRoomCleaning,
	|	CleaningTasks.RegularOperation AS RegularOperation,
	|	CleaningTasks.IsCheckInWaiting AS IsCheckInWaiting,
	|	CleaningTasks.InHouseAccommodation AS InHouseAccommodation,
	|	CleaningTasks.InHouseGuest AS InHouseGuest,
	|	CleaningTasks.InHouseGuestFullName AS InHouseGuestFullName,
	|	CleaningTasks.InHouseGuestDateOfBirth AS InHouseGuestDateOfBirth,
	|	CleaningTasks.InHouseCheckInDate AS InHouseCheckInDate,
	|	CleaningTasks.InHouseCheckOutDate AS InHouseCheckOutDate,
	|	CleaningTasks.InHouseCustomer AS Customer,
	|	CASE
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				AND CleaningTasks.CheckOutGuestIsInHouse
	|			THEN CleaningTasks.CheckOutNumberOfPersons
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseNumberOfPersons
	|		WHEN CleaningTasks.CheckedInAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckedInNumberOfPersons
	|		ELSE 0
	|	END AS NumberOfGuests,
	|	CleaningTasks.ExpectedNumberOfPersons AS ExpectedNumberOfGuests,
	|	CAST(CleaningTasks.InHouseAccommodation.HousekeepingRemarks AS STRING(1024)) AS InHouseAccommodationHousekeepingRemarks,
	|	CleaningTasks.CheckOutAccommodation AS CheckOutAccommodation,
	|	CleaningTasks.CheckOutAccommodationStatus AS CheckOutAccommodationStatus,
	|	CleaningTasks.CheckOutAccommodationStatus.IsInHouse AS CheckOutAccommodationStatusIsInHouse,
	|	CleaningTasks.CheckOutGuest AS CheckOutGuest,
	|	CleaningTasks.CheckOutGuestFullName AS CheckOutGuestFullName,
	|	CleaningTasks.CheckOutGuestDateOfBirth AS CheckOutGuestDateOfBirth,
	|	CleaningTasks.CheckOutCheckInDate AS CheckOutCheckInDate,
	|	CleaningTasks.CheckOutCheckOutDate AS CheckOutCheckOutDate,
	|	CleaningTasks.SetRoomBlock AS SetRoomBlock,
	|	CleaningTasks.RoomBlockType AS RoomBlockType,
	|	CleaningTasks.RoomBlockRemarks AS RoomBlockRemarks,
	|	CleaningTasks.RoomBlockStartDate AS RoomBlockStartDate,
	|	CleaningTasks.RoomBlockEndDate AS RoomBlockEndDate,
	|	CleaningTasks.CurrentRoomBlockType AS CurrentRoomBlockType,
	|	CAST("""" AS STRING(999)) AS OperationRemarks
	|FROM
	|	(SELECT
	|		RoomsRecords.Hotel AS Hotel,
	|		RoomsRecords.Room AS Room,
	|		CASE
	|			WHEN RoomStatusLastChangeRecords.RoomStatus IS NOT NULL 
	|				THEN RoomStatusLastChangeRecords.RoomStatus
	|			ELSE RoomsRecords.RoomStatus
	|		END AS RoomStatus,
	|		CASE
	|			WHEN NOT &qHousekeepingDepartmentIsFilled
	|				THEN RoomStatusLastChangeRecords.User
	|			WHEN RoomStatusLastChangeRecords.User.Department = &qHousekeepingDepartment
	|				THEN RoomStatusLastChangeRecords.User
	|			ELSE NULL
	|		END AS RoomStatusChangeAuthor,
	|		RoomStatusLastChangeRecords.Period AS RoomStatusChangeTime,
	|		RoomsRecords.RoomType AS RoomType,
	|		RoomsRecords.TotalRoomsBalance AS TotalRoomsBalance,
	|		RoomsRecords.TotalBedsBalance AS TotalBedsBalance,
	|		RoomsRecords.CheckedInAccommodation AS CheckedInAccommodation,
	|		RoomsRecords.CheckedInGuest AS CheckedInGuest,
	|		RoomsRecords.CheckedInGuest.FullName AS CheckedInGuestFullName,
	|		RoomsRecords.CheckedInGuest.DateOfBirth AS CheckedInGuestDateOfBirth,
	|		RoomsRecords.CheckedInGuestGroup AS CheckedInGuestGroup,
	|		CASE
	|			WHEN &qShowGuestGroupDescriptionInCustomerColumns
	|				THEN RoomsRecords.CheckedInGuestGroup.Description
	|			ELSE RoomsRecords.CheckedInCustomer
	|		END AS CheckedInCustomer,
	|		RoomsRecords.CheckedInNumberOfPersons AS CheckedInNumberOfPersons,
	|		RoomsRecords.CheckedInCheckInDate AS CheckedInCheckInDate,
	|		RoomsRecords.CheckedInCheckOutDate AS CheckedInCheckOutDate,
	|		RoomsRecords.InHouseAccommodation AS InHouseAccommodation,
	|		RoomsRecords.InHouseGuest AS InHouseGuest,
	|		RoomsRecords.InHouseGuest.FullName AS InHouseGuestFullName,
	|		RoomsRecords.InHouseGuest.DateOfBirth AS InHouseGuestDateOfBirth,
	|		RoomsRecords.InHouseGuestGroup AS InHouseGuestGroup,
	|		CASE
	|			WHEN &qShowGuestGroupDescriptionInCustomerColumns
	|				THEN RoomsRecords.InHouseGuestGroup.Description
	|			ELSE RoomsRecords.InHouseCustomer
	|		END AS InHouseCustomer,
	|		RoomsRecords.InHouseNumberOfPersons AS InHouseNumberOfPersons,
	|		RoomsRecords.InHouseCheckInDate AS InHouseCheckInDate,
	|		RoomsRecords.InHouseCheckOutDate AS InHouseCheckOutDate,
	|		CASE
	|			WHEN RoomsRecords.InHouseAccommodation IS NOT NULL 
	|					AND RoomsRecords.CheckOutAccommodation IS NULL
	|					AND (RoomsRecords.RoomStatus <> &qRoomStatusAfterCheckOut
	|						OR NOT &qRoomStatusAfterCheckOutIsFilled)
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaning
	|			WHEN RoomsRecords.RoomStatus = &qRoomStatusAfterEarlyCheckIn
	|					AND &qRoomStatusAfterEarlyCheckinIsFilled
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaning
	|			WHEN RoomsRecords.RoomStatus = &qOccupiedDirtyRoomStatus
	|					AND &qOccupiedDirtyRoomStatusIsFilled
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaning
	|			ELSE NULL
	|		END AS RegularCleaning,
	|		CASE
	|			WHEN RoomsRecords.InHouseAccommodation IS NOT NULL 
	|					AND RoomsRecords.CheckOutAccommodation IS NULL
	|					AND (RoomsRecords.RoomStatus <> &qRoomStatusAfterCheckOut
	|						OR NOT &qRoomStatusAfterCheckOutIsFilled)
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaningSortCode
	|			WHEN RoomsRecords.RoomStatus = &qRoomStatusAfterEarlyCheckIn
	|					AND &qRoomStatusAfterEarlyCheckinIsFilled
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaningSortCode
	|			WHEN RoomsRecords.RoomStatus = &qOccupiedDirtyRoomStatus
	|					AND &qOccupiedDirtyRoomStatusIsFilled
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaningSortCode
	|			ELSE 999999
	|		END AS RegularCleaningSortCode,
	|		RoomsRecords.CheckOutAccommodation AS CheckOutAccommodation,
	|		RoomsRecords.CheckOutGuest AS CheckOutGuest,
	|		RoomsRecords.CheckOutGuest.FullName AS CheckOutGuestFullName,
	|		RoomsRecords.CheckOutGuest.DateOfBirth AS CheckOutGuestDateOfBirth,
	|		RoomsRecords.CheckOutGuestGroup AS CheckOutGuestGroup,
	|		CASE
	|			WHEN &qShowGuestGroupDescriptionInCustomerColumns
	|				THEN RoomsRecords.CheckOutGuestGroup.Description
	|			ELSE RoomsRecords.CheckOutCustomer
	|		END AS CheckOutCustomer,
	|		RoomsRecords.CheckOutNumberOfPersons AS CheckOutNumberOfPersons,
	|		RoomsRecords.CheckOutCheckInDate AS CheckOutCheckInDate,
	|		RoomsRecords.CheckOutCheckOutDate AS CheckOutCheckOutDate,
	|		CASE
	|			WHEN RoomsRecords.CheckOutAccommodation IS NOT NULL 
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaning
	|			WHEN RoomsRecords.RoomStatus = &qRoomStatusAfterCheckOut
	|					AND &qRoomStatusAfterCheckOutIsFilled
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaning
	|			ELSE NULL
	|		END AS CheckOutCleaning,
	|		CASE
	|			WHEN RoomsRecords.CheckOutAccommodation IS NOT NULL 
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaningSortCode
	|			WHEN RoomsRecords.RoomStatus = &qRoomStatusAfterCheckOut
	|					AND &qRoomStatusAfterCheckOutIsFilled
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaningSortCode
	|			ELSE 999999
	|		END AS CheckOutCleaningSortCode,
	|		RoomsRecords.CheckOutGuestIsInHouse AS CheckOutGuestIsInHouse,
	|		RoomsRecords.SetRoomBlock AS SetRoomBlock,
	|		RoomsRecords.RoomBlockType AS RoomBlockType,
	|		RoomsRecords.RoomBlockRemarks AS RoomBlockRemarks,
	|		RoomsRecords.RoomBlockStartDate AS RoomBlockStartDate,
	|		RoomsRecords.RoomBlockEndDate AS RoomBlockEndDate,
	|		CASE
	|			WHEN RoomsRecords.SetRoomBlock IS NOT NULL 
	|					AND &qRepairEndCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRepairEndCleaning
	|			ELSE NULL
	|		END AS RepairEndCleaning,
	|		CASE
	|			WHEN RoomsRecords.SetRoomBlock IS NOT NULL 
	|					AND &qRepairEndCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRepairEndCleaningSortCode
	|			ELSE 999999
	|		END AS RepairEndCleaningSortCode,
	|		CASE
	|			WHEN RoomsRecords.CheckOutAccommodation IS NULL
	|					AND RoomsRecords.RoomBlockType IS NULL
	|					AND RoomsRecords.InHouseAccommodation IS NULL
	|					AND RoomsRecords.CheckedInAccommodation IS NULL
	|					AND RoomsRecords.RoomRepairsRecorder IS NULL
	|					AND (RoomsRecords.RoomStatus <> &qRoomStatusAfterCheckOut
	|						OR NOT &qRoomStatusAfterCheckOutIsFilled)
	|					AND &qVacantRoomCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qVacantRoomCleaning
	|			ELSE NULL
	|		END AS VacantRoomCleaning,
	|		CASE
	|			WHEN RoomsRecords.CheckOutAccommodation IS NULL
	|					AND RoomsRecords.RoomBlockType IS NULL
	|					AND RoomsRecords.InHouseAccommodation IS NULL
	|					AND RoomsRecords.CheckedInAccommodation IS NULL
	|					AND RoomsRecords.RoomRepairsRecorder IS NULL
	|					AND (RoomsRecords.RoomStatus <> &qRoomStatusAfterCheckOut
	|						OR NOT &qRoomStatusAfterCheckOutIsFilled)
	|					AND &qVacantRoomCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qVacantRoomCleaningSortCode
	|			ELSE 999999
	|		END AS VacantRoomCleaningSortCode,
	|		RoomsRecords.IsCheckInWaiting AS IsCheckInWaiting,
	|		RoomsRecords.ExpectedNumberOfPersons AS ExpectedNumberOfPersons,
	|		RoomsRecords.PlannedCheckInReservation AS PlannedCheckInReservation,
	|		RoomsRecords.PlannedCheckInGuest AS PlannedCheckInGuest,
	|		RoomsRecords.PlannedCheckInGuest.FullName AS PlannedCheckInGuestFullName,
	|		RoomsRecords.PlannedCheckInGuest.DateOfBirth AS PlannedCheckInGuestDateOfBirth,
	|		RoomsRecords.PlannedCheckInCheckInDate AS PlannedCheckInCheckInDate,
	|		RoomsRecords.PlannedCheckInCheckOutDate AS PlannedCheckInCheckOutDate,
	|		RoomsRecords.RegularOperation AS RegularOperation,
	|		RoomsRecords.RegularOperationSortCode AS RegularOperationSortCode,
	|		RoomsRecords.CurrentRoomBlockType AS CurrentRoomBlockType,
	|		CASE
	|			WHEN RoomsRecords.CheckOutClientType IS NOT NULL 
	|					AND ISNULL(RoomsRecords.CheckOutIsInHouse, FALSE)
	|				THEN RoomsRecords.CheckOutClientType
	|			WHEN RoomsRecords.InHouseClientType IS NOT NULL 
	|				THEN RoomsRecords.InHouseClientType
	|			WHEN RoomsRecords.CheckedInClientType IS NOT NULL 
	|				THEN RoomsRecords.CheckedInClientType
	|			WHEN RoomsRecords.PlannedCheckInClientType IS NOT NULL 
	|				THEN RoomsRecords.PlannedCheckInClientType
	|			WHEN RoomsRecords.CheckOutClientType IS NOT NULL 
	|				THEN RoomsRecords.CheckOutClientType
	|			ELSE NULL
	|		END AS ClientType,
	|		RoomsRecords.CheckOutAccommodation.AccommodationStatus AS CheckOutAccommodationStatus
	|	FROM
	|		RoomsRecords AS RoomsRecords
	|			LEFT JOIN RoomStatusLastChangeRecords AS RoomStatusLastChangeRecords
	|			ON RoomsRecords.Room = RoomStatusLastChangeRecords.Room
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VirtualRooms.Owner,
	|		VirtualRooms.Ref,
	|		CASE
	|			WHEN VirtualRoomStatusLastChangeRecords.RoomStatus IS NOT NULL 
	|				THEN VirtualRoomStatusLastChangeRecords.RoomStatus
	|			ELSE VirtualRooms.Ref.RoomStatus
	|		END,
	|		CASE
	|			WHEN NOT &qHousekeepingDepartmentIsFilled
	|				THEN VirtualRoomStatusLastChangeRecords.User
	|			WHEN VirtualRoomStatusLastChangeRecords.User.Department = &qHousekeepingDepartment
	|				THEN VirtualRoomStatusLastChangeRecords.User
	|			ELSE NULL
	|		END,
	|		VirtualRoomStatusLastChangeRecords.Period,
	|		VirtualRooms.RoomType,
	|		0,
	|		0,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		0,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		0,
	|		NULL,
	|		NULL,
	|		CASE
	|			WHEN VirtualRoomStatusLastChangeRecords.RoomStatus = &qRoomStatusAfterEarlyCheckIn
	|					AND &qRoomStatusAfterEarlyCheckinIsFilled
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaning
	|			WHEN VirtualRoomStatusLastChangeRecords.RoomStatus = &qOccupiedDirtyRoomStatus
	|					AND &qOccupiedDirtyRoomStatusIsFilled
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaning
	|			ELSE NULL
	|		END,
	|		CASE
	|			WHEN VirtualRoomStatusLastChangeRecords.RoomStatus = &qRoomStatusAfterEarlyCheckIn
	|					AND &qRoomStatusAfterEarlyCheckinIsFilled
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaningSortCode
	|			WHEN VirtualRoomStatusLastChangeRecords.RoomStatus = &qOccupiedDirtyRoomStatus
	|					AND &qOccupiedDirtyRoomStatusIsFilled
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaningSortCode
	|			ELSE 999999
	|		END,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		0,
	|		NULL,
	|		NULL,
	|		CASE
	|			WHEN VirtualRoomStatusLastChangeRecords.RoomStatus = &qRoomStatusAfterCheckOut
	|					AND &qRoomStatusAfterCheckOutIsFilled
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaning
	|			ELSE NULL
	|		END,
	|		CASE
	|			WHEN VirtualRoomStatusLastChangeRecords.RoomStatus = &qRoomStatusAfterCheckOut
	|					AND &qRoomStatusAfterCheckOutIsFilled
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaningSortCode
	|			ELSE 999999
	|		END,
	|		FALSE,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		999999,
	|		FALSE,
	|		0,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		999999,
	|		NULL,
	|		NULL,
	|		NULL
	|	FROM
	|		Catalog.Rooms AS VirtualRooms
	|			LEFT JOIN RoomStatusLastChangeRecords AS VirtualRoomStatusLastChangeRecords
	|			ON VirtualRooms.Ref = VirtualRoomStatusLastChangeRecords.Room
	|	WHERE
	|		VirtualRooms.IsVirtual
	|		AND NOT VirtualRooms.IsFolder
	|		AND NOT VirtualRooms.DeletionMark
	|		AND VirtualRooms.OperationStartDate <= &qPeriodTo
	|		AND (VirtualRooms.OperationEndDate = &qEmptyDate
	|				OR VirtualRooms.OperationEndDate > &qPeriodTo)
	|		AND VirtualRooms.Owner = &qHotel
	|		AND (VirtualRooms.Ref IN HIERARCHY (&qRoom)
	|				OR &qIsEmptyRoom)
	|		AND (VirtualRooms.RoomSection IN HIERARCHY (&qRoomSection)
	|				OR &qIsEmptyRoomSection)) AS CleaningTasks
	|		LEFT JOIN RoomStatusesWithOperation AS RoomStatusesWithOperation
	|		ON CleaningTasks.RoomStatus = RoomStatusesWithOperation.RoomStatus
	|
	|ORDER BY
	|	HotelSortCode,
	|	RoomSortCode,
	|	GuestFullName DESC,
	|	OperationSortCode,
	|	AccommodationTypeSortCode";
	// Fill query parameters
	vQry.SetParameter("qPeriod", EndOfDay(Date));
	vQry.SetParameter("qPeriodFrom", BegOfDay(Date));
	vQry.SetParameter("qPeriodTo", EndOfDay(Date));
	vQry.SetParameter("qStatusesStateDate", RoomStatusesStateDate(EndOfDay(Date)));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qIsEmptyRoom", Not ValueIsFilled(Room));
    vQry.SetParameter("qRoomSection", RoomSection);
    vQry.SetParameter("qIsEmptyRoomSection", Not ValueIsFilled(RoomSection));
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vQry.SetParameter("qRegularCleaning", RegularCleaning);
	vQry.SetParameter("qRegularCleaningSortCode", ?(ValueIsFilled(RegularCleaning), RegularCleaning.SortCode, 0));
	vQry.SetParameter("qCheckOutCleaning", CheckOutCleaning);
	vQry.SetParameter("qCheckOutCleaningSortCode", ?(ValueIsFilled(CheckOutCleaning), CheckOutCleaning.SortCode, 0));
	vQry.SetParameter("qVacantRoomCleaning", VacantRoomCleaning);
	vQry.SetParameter("qVacantRoomCleaningSortCode", ?(ValueIsFilled(VacantRoomCleaning), VacantRoomCleaning.SortCode, 0));
	vQry.SetParameter("qRepairEndCleaning", RepairEndCleaning);
	vQry.SetParameter("qRepairEndCleaningSortCode", ?(ValueIsFilled(RepairEndCleaning), RepairEndCleaning.SortCode, 0));
	vQry.SetParameter("qRoomStatusAfterCheckOut", RoomStatusAfterCheckOut);
	vQry.SetParameter("qRoomStatusAfterCheckOutIsFilled", ValueIsFilled(RoomStatusAfterCheckOut));
    vQry.SetParameter("qRegularOperationGroup", RegularOperationGroup);
	vQry.SetParameter("qShowGuestGroupDescriptionInCustomerColumns", cmCheckUserPermissions("ShowGuestGroupDescriptionInCustomerColumns"));
	vQry.SetParameter("qHousekeepingDepartment", HousekeepingDepartment);
	vQry.SetParameter("qHousekeepingDepartmentIsFilled", ValueIsFilled(HousekeepingDepartment)); 
	vQry.SetParameter("qRoomStatusAfterEarlyCheckin", RoomStatusAfterEarlyCheckIn);
	vQry.SetParameter("qRoomStatusAfterEarlyCheckinIsFilled", ValueIsFilled(RoomStatusAfterEarlyCheckIn));
	vQry.SetParameter("qOccupiedDirtyRoomStatus", OccupiedDirtyRoomStatus);
	vQry.SetParameter("qOccupiedDirtyRoomStatusIsFilled", ValueIsFilled(OccupiedDirtyRoomStatus));
	vQry.SetParameter("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	vQry.SetParameter("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	vOperations = vQry.Execute().Unload();
	// Remove doubled rows per guests
	i = 0;
	While i < (vOperations.Count() - 1) Do
		vRow = vOperations.Get(i);
		vNextRow = vOperations.Get(i + 1);
		If ValueIsFilled(vRow.Room) And ValueIsFilled(vRow.Operation) And ValueIsFilled(vRow.ParentDoc) And 
		   vRow.Room = vNextRow.Room And vRow.Operation = vNextRow.Operation And vRow.ParentDoc = vNextRow.ParentDoc Then
			vOperations.Delete(i + 1);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Clear per room operations added per every guest
	For Each vRow In vOperations Do
		If ValueIsFilled(vRow.Room) And ValueIsFilled(vRow.Operation) Then
			If Not vRow.Operation.IsPerGuest Then
				vOprRows = vOperations.FindRows(New Structure("Room, Operation", vRow.Room, vRow.Operation));
				If vOprRows.Count() > 1 Then
					For i = 1 To (vOprRows.Count()-1) Do
						vOprRow = vOprRows.Get(i);
						vOprRow.Operation = Catalogs.Operations.EmptyRef();
						vOprRow.OperationSortCode = 999999;
						If vOprRow.CheckOutCleaning = vRow.Operation Then
							vOprRow.CheckOutCleaning = Catalogs.Operations.EmptyRef();
						EndIf;
						If vOprRow.RegularCleaning = vRow.Operation Then
							vOprRow.RegularCleaning = Catalogs.Operations.EmptyRef();
						EndIf;
						If vOprRow.VacantRoomCleaning = vRow.Operation Then
							vOprRow.VacantRoomCleaning = Catalogs.Operations.EmptyRef();
						EndIf;
						If vOprRow.RepairEndCleaning = vRow.Operation Then
							vOprRow.RepairEndCleaning = Catalogs.Operations.EmptyRef();
						EndIf;
						If vOprRow.RegularOperation = vRow.Operation Then
							vOprRow.RegularOperation = Catalogs.Operations.EmptyRef();
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
		vRow.OperationRemarks = pmGetOperationRemarks(vRow); 
	EndDo;
	// Sort operations
	vOperations.Sort("HotelSortCode, RoomSortCode, GuestFullName DESC, OperationSortCode, AccommodationTypeSortCode");
	// Return
	Return vOperations;
EndFunction // pmGetOperations

// -----------------------------------------------------------------------------
Function RoomStatusesStateDate(Val pDate, pUseTime = False)
	If pDate = Undefined Then
		Return pDate;	
	EndIf;
	
	vCurDate = CurrentSessionDate();
	If pUseTime Then
		If pDate >= vCurDate Then
			Return Undefined;
		EndIf;
	Else
		If BegOfDay(pDate) >= BegOfDay(vCurDate) Then
			Return Undefined;
		EndIf;
	EndIf;

	Return pDate;
EndFunction // RoomStatusesStateDate

// -----------------------------------------------------------------------------
Function pmGetOperationRemarks(pOprRow) Export
	vOprRem = "";
	If ValueIsFilled(pOprRow.CheckOutCleaning) Then
		If ValueIsFilled(pOprRow.CheckOutGuest) And ValueIsFilled(pOprRow.CheckOutAccommodation) Then
			If ValueIsFilled(pOprRow.CheckOutAccommodationStatus) And pOprRow.CheckOutAccommodationStatusIsInHouse Then
				vOprRem = vOprRem + AddComma(vOprRem) + GetGuestFullName(pOprRow.CheckOutGuest, pOprRow.CheckOutGuestFullName, pOprRow.CheckOutGuestDateOfBirth);
			ElsIf ValueIsFilled(pOprRow.Guest) Then
				vOprRem = vOprRem + AddComma(vOprRem) + GetGuestFullName(pOprRow.Guest, pOprRow.GuestFullName, pOprRow.GuestDateOfBirth);
			EndIf;
		EndIf;
	ElsIf ValueIsFilled(pOprRow.RegularOperation) Then
		vOprRem = vOprRem + AddComma(vOprRem) + GetGuestFullName(?(ValueIsFilled(pOprRow.InHouseGuest), pOprRow.InHouseGuest, pOprRow.Guest), ?(ValueIsFilled(pOprRow.InHouseGuest), pOprRow.InHouseGuestFullName, pOprRow.GuestFullName), ?(ValueIsFilled(pOprRow.InHouseGuest), pOprRow.InHouseGuestDateOfBirth, pOprRow.GuestDateOfBirth));
		If Not IsBlankString(pOprRow.InHouseAccommodationHousekeepingRemarks) Then
			vOprRem = vOprRem + AddComma(vOprRem) + TrimAll(pOprRow.InHouseAccommodationHousekeepingRemarks);
		EndIf;
	ElsIf ValueIsFilled(pOprRow.RegularCleaning) Then
		vOprRem = vOprRem + AddComma(vOprRem) + GetGuestFullName(?(ValueIsFilled(pOprRow.InHouseGuest), pOprRow.InHouseGuest, pOprRow.Guest), ?(ValueIsFilled(pOprRow.InHouseGuest), pOprRow.InHouseGuestFullName, pOprRow.GuestFullName), ?(ValueIsFilled(pOprRow.InHouseGuest), pOprRow.InHouseGuestDateOfBirth, pOprRow.GuestDateOfBirth));
		If Not IsBlankString(pOprRow.InHouseAccommodationHousekeepingRemarks) Then
			vOprRem = vOprRem + AddComma(vOprRem) + TrimAll(pOprRow.InHouseAccommodationHousekeepingRemarks);
		EndIf;
	ElsIf ValueIsFilled(pOprRow.RepairEndCleaning) Then
		vOprRem = vOprRem + AddComma(vOprRem) + TrimAll(pOprRow.RoomBlockRemarks);
	ElsIf ValueIsFilled(pOprRow.Guest) Then
		vOprRem = vOprRem + AddComma(vOprRem) + GetGuestFullName(pOprRow.Guest, pOprRow.GuestFullName, pOprRow.GuestDateOfBirth);
	EndIf;
	Return vOprRem;
EndFunction // pmGetOperationRemarks

// -----------------------------------------------------------------------------
Procedure pmFillOperationRowResources(pRow, pOprRow) Export
	pRow.CheckOutCleaningCount = 0;
	pRow.RegularCleaningCount = 0;
	pRow.RepairEndCleaningCount = 0;
	pRow.VacantRoomCleaningCount = 0;
	pRow.RoomSpace = 0;
	pRow.Duration = 0;
	If ValueIsFilled(pRow.Operation) Then
		If ValueIsFilled(pOprRow.CheckOutCleaning) Then
			pRow.CheckOutCleaningCount = 1;
		ElsIf ValueIsFilled(pOprRow.RegularOperation) Then
			pRow.RegularCleaningCount = 1;
		ElsIf ValueIsFilled(pOprRow.RegularCleaning) Then
			pRow.RegularCleaningCount = 1;
		ElsIf ValueIsFilled(pOprRow.RepairEndCleaning) And pOprRow.RepairEndCleaning = RepairEndCleaning Then
			pRow.RepairEndCleaningCount = 1;
		ElsIf ValueIsFilled(pOprRow.VacantRoomCleaning) Then
			pRow.VacantRoomCleaningCount = 1;
		EndIf;
		vOprStds = Catalogs.Operations.GetOperationStandards(pRow.Operation, Hotel, pRow.RoomType, pRow.Room, pRow.Employee);
		If vOprStds.Count() > 0 Then
			vOprStdsRow = vOprStds.Get(0);
			pRow.RoomSpace = vOprStdsRow.RoomSpace;
			pRow.Duration = vOprStdsRow.Duration;
			pRow.Price = vOprStdsRow.Price;
		EndIf;
	EndIf;
EndProcedure // pmFillOperationRowResources

// -----------------------------------------------------------------------------
Function pmGetAvailableEmployees() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	EmployeeWorkingTimeSchedule.Employee AS Employee,
	|	EmployeeWorkingTimeSchedule.Employee.Department AS Department,
	|	EmployeeWorkingTimeSchedule.Employee.SortCode AS EmployeeSortCode,
	|	SUM(EmployeeWorkingTimeSchedule.Hours) AS Hours
	|FROM
	|	InformationRegister.EmployeeWorkingTimeSchedule AS EmployeeWorkingTimeSchedule
	|WHERE
	|	EmployeeWorkingTimeSchedule.Hotel = &qHotel
	|	AND (EmployeeWorkingTimeSchedule.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (EmployeeWorkingTimeSchedule.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qIsEmptyRoomSection)
	|	AND (EmployeeWorkingTimeSchedule.Department IN HIERARCHY (&qDepartment)
	|			OR &qIsEmptyDepartment)
	|	AND EmployeeWorkingTimeSchedule.Period >= &qPeriodFrom
	|	AND EmployeeWorkingTimeSchedule.Period < &qPeriodTo
	|
	|GROUP BY
	|	EmployeeWorkingTimeSchedule.Employee,
	|	EmployeeWorkingTimeSchedule.Employee.Department,
	|	EmployeeWorkingTimeSchedule.Employee.SortCode
	|
	|HAVING
	|	SUM(EmployeeWorkingTimeSchedule.Hours) > 0
	|
	|ORDER BY
	|	EmployeeSortCode,
	|	EmployeeWorkingTimeSchedule.Employee.Department.SortCode";
	vQry.SetParameter("qPeriodFrom", BegOfDay(Date));
	vQry.SetParameter("qPeriodTo", EndOfDay(Date));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qIsEmptyRoom", Not ValueIsFilled(Room));
    vQry.SetParameter("qRoomSection", RoomSection);
    vQry.SetParameter("qIsEmptyRoomSection", Not ValueIsFilled(RoomSection));
	vQry.SetParameter("qDepartment", HousekeepingDepartment);
	vQry.SetParameter("qIsEmptyDepartment", Not ValueIsFilled(HousekeepingDepartment));
	vEmployees = vQry.Execute().Unload();
	Return vEmployees;
EndFunction // pmGetAvailableEmployees

// -----------------------------------------------------------------------------
Function pmGetEmployeePresentation(pEmpRow) Export
	vEmpPres = "";
	If pEmpRow = Undefined Then
		// Add name
		vEmpPres = NStr("en='<clear assignment>'; ru='<очистить назначение>'; de='<klare mitarbeiterzuweisung>'");
		// Add cleaning counts by types
		vEmpPres = vEmpPres + NStr("en=', n/a: '; ru=', н/н: '; de=', n/z: '");
		vNAC = Operations.Total("CheckOutCleaningCount") - Employees.Total("CheckOutCleaningCount");
		If vNAC > 0 Then
			vEmpPres = vEmpPres + NStr("en='C ';ru='В ';de='In '") + Format(vNAC, "ND=6; NFD=0; NZ=");
		EndIf;
		vNAR = Operations.Total("RegularCleaningCount") - Employees.Total("RegularCleaningCount");
		If vNAR > 0 Then
			vEmpPres = vEmpPres + ", ";
			vEmpPres = vEmpPres + NStr("en='R ';ru='Т ';de='Т '") + Format(vNAR, "ND=6; NFD=0; NZ=");
		EndIf;
		vNAV = Operations.Total("VacantRoomCleaningCount") - Employees.Total("VacantRoomCleaningCount");
		If vNAV > 0 Then
			vEmpPres = vEmpPres + ", ";
			vEmpPres = vEmpPres + NStr("en='V ';ru='С ';de='Ab '") + Format(vNAV, "ND=6; NFD=0; NZ=");
		EndIf;
		vNAA = Operations.Total("RepairEndCleaningCount") - Employees.Total("RepairEndCleaningCount");
		If vNAA > 0 Then
			vEmpPres = vEmpPres + ", ";
			vEmpPres = vEmpPres + NStr("en='A ';ru='Р ';de='R '") + Format(vNAA, "ND=6; NFD=0; NZ=");
		EndIf;
	Else
		// Add employee name
		If ValueIsFilled(pEmpRow.Employee) Then
			vEmpPres = TrimAll(pEmpRow.Employee);
		EndIf;
		// Add employee totals for time and space
		If pEmpRow.Hours > 0 Or pEmpRow.RoomSpace > 0 Then
			If Not IsBlankString(vEmpPres) Then
				vEmpPres = vEmpPres + ", ";
			EndIf;
		EndIf;
		If pEmpRow.Hours > 0 Then
			vEmpPres = vEmpPres + cmFormatDurationInHours(pEmpRow.Duration, True) + "/" +
			                      cmFormatDurationInHours(pEmpRow.Hours, True);
		EndIf;
		If pEmpRow.RoomSpace > 0 Then
			vEmpPres = vEmpPres + " (" + Format(pEmpRow.RoomSpace, "ND=8; NFD=2; NZ=") + ")";
		EndIf;
		// Add cleaning counts by types
		If Not IsBlankString(vEmpPres) Then
			vEmpPres = vEmpPres + ", ";
		EndIf;
		If pEmpRow.CheckOutCleaningCount > 0 Then
			vEmpPres = vEmpPres + NStr("en='C ';ru='В ';de='In '") + Format(pEmpRow.CheckOutCleaningCount, "ND=6; NFD=0; NZ=");
		EndIf;
		If Not IsBlankString(vEmpPres) Then
			vEmpPres = vEmpPres + ", ";
		EndIf;
		If pEmpRow.RegularCleaningCount > 0 Then
			vEmpPres = vEmpPres + NStr("en='R ';ru='Т ';de='Т '") + Format(pEmpRow.RegularCleaningCount, "ND=6; NFD=0; NZ=");
		EndIf;
		If Not IsBlankString(vEmpPres) Then
			vEmpPres = vEmpPres + ", ";
		EndIf;
		If pEmpRow.VacantRoomCleaningCount > 0 Then
			vEmpPres = vEmpPres + NStr("en='V ';ru='С ';de='Ab '") + Format(pEmpRow.VacantRoomCleaningCount, "ND=6; NFD=0; NZ=");
		EndIf;
		If Not IsBlankString(vEmpPres) Then
			vEmpPres = vEmpPres + ", ";
		EndIf;
		If pEmpRow.RepairEndCleaningCount > 0 Then
			vEmpPres = vEmpPres + NStr("en='A ';ru='Р ';de='R '") + Format(pEmpRow.RepairEndCleaningCount, "ND=6; NFD=0; NZ=");
		EndIf;
		// Remove trailing commas
		vEmpPres = TrimAll(vEmpPres);
		While Right(vEmpPres, 1) = "," Do
			vEmpPres = Left(vEmpPres, StrLen(vEmpPres)-1);
			vEmpPres = TrimAll(vEmpPres);
		EndDo;
	EndIf;
	// Return
	Return vEmpPres;
EndFunction // pmGetEmployeePresentation 

// -----------------------------------------------------------------------------
Function pmGetEmployeeOperations() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	EmployeeOperation.Ref
	|FROM
	|	Document.EmployeeOperation AS EmployeeOperation
	|WHERE
	|	EmployeeOperation.Posted
	|	AND EmployeeOperation.OperationSchedule = &qOperationSchedule
	|
	|ORDER BY
	|	EmployeeOperation.Date,
	|	EmployeeOperation.PointInTime";
	vQry.SetParameter("qOperationSchedule", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetEmployeeOperations

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function AddComma(pStr)
	If IsBlankString(pStr) Then
		Return "";
	Else
		Return ", ";
	EndIf;
EndFunction // AddComma

// -----------------------------------------------------------------------------
Function GetGuestFullName(pGuest, pFullName, pDateOfBirth)
	If ValueIsFilled(pGuest) Then
		If ValueIsFilled(pDateOfBirth) Then
			Return TrimAll(pFullName) + ", " + Format(pDateOfBirth, "DF=dd.MM.yy");
		Else
			Return TrimAll(pFullName);
		EndIf;
	Else
		Return "";
	EndIf;
EndFunction // GetGuestFullName

// -----------------------------------------------------------------------------
Function GetDayDocuments(pRow, pDay)
	// Get all documents for the given day
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	EmployeeOperation.Ref
	|FROM
	|	Document.EmployeeOperation AS EmployeeOperation
	|WHERE
	|	(EmployeeOperation.OperationStartTime >= &qPeriodFrom
	|				AND EmployeeOperation.OperationStartTime <= &qPeriodTo
	|				AND EmployeeOperation.OperationStartTime > &qEmptyDate
	|			OR EmployeeOperation.OperationIntentTime >= &qPeriodFrom
	|				AND EmployeeOperation.OperationIntentTime <= &qPeriodTo
	|				AND EmployeeOperation.OperationStartTime = &qEmptyDate)
	|	AND EmployeeOperation.Posted
	|	AND EmployeeOperation.OperationSchedule = &qRef
	|	AND EmployeeOperation.RoomType = &qRoomType
	|	AND EmployeeOperation.Room = &qRoom
	|	AND EmployeeOperation.Operation = &qOperation";
	vQry.SetParameter("qRoomType", pRow.RoomType);
	vQry.SetParameter("qRoom", pRow.Room);
	vQry.SetParameter("qRef", Ref);
	vQry.SetParameter("qOperation", pRow.Operation);
	vQry.SetParameter("qPeriodFrom", BegOfDay(pDay));
	vQry.SetParameter("qPeriodTo", EndOfDay(pDay));
	vQry.SetParameter("qEmptyDate", '00010101');
	Return vQry.Execute().Unload();
EndFunction // GetDayDocuments

#EndRegion

