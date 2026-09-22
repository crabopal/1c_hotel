
#Region Public

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel, pReplacing)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Check room status
	For Each vRcd In ThisObject Do
		If ValueIsFilled(vRcd.Room) And ValueIsFilled(vRcd.RoomStatus) Then
			vRoom = vRcd.Room;
			vHotel = vRoom.Owner;
			vRoomStatus = vRcd.RoomStatus;
			If vRoomStatus.DoEmployeeOperation And BegOfDay(CurrentSessionDate()) = BegOfDay(vRcd.Period) Then
				// Check previous room status and skip processing if it is the same
				vSkipProcessing = False;
				If Find(vRcd.Remarks, "NO_OP_UPD") > 0 Then
					vSkipProcessing = True;
				Else
					vPrevRoomStatusRow = Undefined;
					vPrevRoomStatuses = vRoom.GetObject().pmGetRoomStatusHistoryState(vRcd.Period - 1);
					If vPrevRoomStatuses.Count() > 0 Then
						vPrevRoomStatusRow = vPrevRoomStatuses.Get(vPrevRoomStatuses.Count() - 1);
					EndIf;
					If vPrevRoomStatusRow <> Undefined And 
					   vPrevRoomStatusRow.RoomStatus = vRoomStatus And 
					   BegOfDay(vPrevRoomStatusRow.Period) = BegOfDay(vRcd.Period) Then
						vSkipProcessing = True;
					EndIf;
				EndIf;
				If Not vSkipProcessing Then
					// Try to get operation
					vPeriodTime = '00010101' + (vRcd.Period - BegOfDay(vRcd.Period));
					vOperation = vRoomStatus.Operation;
					vRegularOperationGroup = vRoomStatus.RegularOperationGroup;
					If vRoomStatus.OperationsSchedule.Count() > 0 Then
						For Each vScheduleRow In vRoomStatus.OperationsSchedule Do
							If ValueIsFilled(vScheduleRow.Operation) Then
								If Not IsBlankString(vScheduleRow.WeekDays) Then
									If Find(vScheduleRow.WeekDays, String(WeekDay(vRcd.Period))) = 0 Then
										Continue;
									EndIf;
								EndIf;
								vTimeFrom = vScheduleRow.TimeFrom;
								vTimeTo = vScheduleRow.TimeTo;
								If vTimeFrom < vTimeTo Then
									If vTimeFrom <= vPeriodTime And vPeriodTime < vTimeTo Then
										vOperation = vScheduleRow.Operation;
										Break;
									EndIf;
								Else
									If vTimeFrom <= vPeriodTime And vPeriodTime <= EndOfDay(vTimeFrom) Or
									   BegOfDay(vTimeTo) <= vPeriodTime And vPeriodTime < vTimeTo Then
										vOperation = vScheduleRow.Operation;
										Break;
									EndIf;
								EndIf;
							EndIf;
						EndDo;
					EndIf;
					// Check state of operation
					vState = 0;
					If vRoomStatus = vHotel.RoomStatusAfterCheckOut Or 
					   vRoomStatus = vHotel.RoomStatusAfterEarlyCheckIn Or
					   vRoomStatus = vHotel.OccupiedDirtyRoomStatus Or 
					   vRoomStatus = vHotel.RoomStatusDueOut Or 
					   vRoomStatus = vHotel.RoomStatusAfterRoomBlock Then
						vState = 1; // Create new operation
						If vRoomStatus = vHotel.OccupiedDirtyRoomStatus Then
							// Check should we change operation to the regular operation
							If ValueIsFilled(vRegularOperationGroup) Then
								vOperation = GetRegularOperation(vOperation, vRoom, vRcd.Period, vRegularOperationGroup);
							EndIf;
						EndIf;
					ElsIf vRoomStatus = vHotel.CleaningInProgressRoomStatus Or vRoomStatus.OperationIsInProgress Then
						vState = 3; // Operation has started
					ElsIf vRoomStatus = vHotel.RoomStatusInspection Or vRoomStatus.InspectionIsInProgress Then
						vState = 4; // Operation has ended, inspection has started						
					ElsIf (vRoomStatus = vHotel.VacantRoomStatus Or vRoomStatus.RoomIsVacantClear) Or 
						  (vRoomStatus = vHotel.OccupiedRoomStatus And ValueIsFilled(vHotel.OccupiedDirtyRoomStatus) And vHotel.OccupiedRoomStatus <> vHotel.OccupiedDirtyRoomStatus) Then
						vState = 5; // Operation has ended, inspection has ended
					Else
						vState = 1; // Create new operation for all other states
					EndIf;
					If vState > 0 Then
						vEmpOpRef = GetOperationDocument(vOperation, vRoom, vRcd.Period, vState);
						If vState = 1 And ValueIsFilled(vOperation) Then
							// Create new employee operation document
							GetNewOperationDocument(vOperation, vRoom, vRcd.Period, vEmpOpRef);
							// Send telegram notification
							Try
								vParams = New Array();
								vParams.Add(vHotel);
								vParams.Add(Enums.ChatRoles.Supervisor);
								AsyncCalls.StartBackgroundJob("ProlongedOperations.Telegram_SendNotification", vParams, "Telegram_SendNotification", "Telegram_SendNotification");
							Except
							EndTry;
						Else
							If ValueIsFilled(vEmpOpRef) Then
								vEmpOpObj = vEmpOpRef.GetObject();
								// Try to find existing operation document
								If vState = 3 Then
									// Update operation start time
									vEmpOpObj.OperationStartTime = vRcd.Period;
								ElsIf vState = 4 Then
									// Update operation start time
									If Not ValueIsFilled(vEmpOpObj.OperationStartTime) Then
										If ValueIsFilled(vEmpOpObj.EmployeeAssignmentTime) Then
											vEmpOpObj.OperationStartTime = vEmpOpObj.EmployeeAssignmentTime;
										ElsIf ValueIsFilled(vEmpOpObj.OperationIntentTime) Then
											vEmpOpObj.OperationStartTime = vEmpOpObj.OperationIntentTime;
										ElsIf vEmpOpObj.Date <= vRcd.Period Then
											vEmpOpObj.OperationStartTime = vEmpOpObj.Date;
										EndIf;
									EndIf;
									// Update operation end time
									vEmpOpObj.OperationEndTime = vRcd.Period;
								ElsIf vState = 5 Then
									// Update operation start time
									If Not ValueIsFilled(vEmpOpObj.OperationStartTime) Then
										If ValueIsFilled(vEmpOpObj.EmployeeAssignmentTime) Then
											vEmpOpObj.OperationStartTime = vEmpOpObj.EmployeeAssignmentTime;
										ElsIf ValueIsFilled(vEmpOpObj.OperationIntentTime) Then
											vEmpOpObj.OperationStartTime = vEmpOpObj.OperationIntentTime;
										ElsIf vEmpOpObj.Date <= vRcd.Period Then
											vEmpOpObj.OperationStartTime = vEmpOpObj.Date;
										EndIf;
									EndIf;
									// Update inspection end and operation end time
									If Not ValueIsFilled(vEmpOpObj.OperationEndTime) Then
										vEmpOpObj.OperationEndTime = vRcd.Period;
									EndIf;
									vEmpOpObj.OperationEndConfirmedTime = vRcd.Period;
								EndIf;
								// Calculate durations
								vEmpOpObj.pmCalculateDurations();
								// Post document
								vEmpOpObj.Write(DocumentWriteMode.Posting);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // OnWrite

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetNewOperationDocument(pOperation, pRoom, pPeriod, pEmpOpRef = Undefined)
	If ValueIsFilled(pEmpOpRef) Then
		// Update existing operation document
		vEmpOpObj = pEmpOpRef.GetObject();
	Else
		// Create new employee operation document
		vEmpOpObj = Documents.EmployeeOperation.CreateDocument();
		vEmpOpObj.SetTime(AutoTimeMode.DontUse);
	EndIf;
	vEmpOpObj.Hotel = pRoom.Owner;
	vEmpOpObj.Room = pRoom;
	// Retrieve room resources
	vRoomAttrs = vEmpOpObj.Room.GetObject().pmGetRoomAttributes(pPeriod);
	For Each vRoomAttrsRow In vRoomAttrs Do
		vEmpOpObj.RoomType = vRoomAttrsRow.RoomType;
		Break;
	EndDo;
	If vEmpOpObj.Operation <> pOperation Then
		vEmpOpObj.Date = pPeriod;
		vEmpOpObj.OperationIntentTime = pPeriod;
		vEmpOpObj.pmFillAttributesWithDefaultValues();
		// Fill employee and operation
		vEmpOpObj.Employee = Catalogs.Employees.EmptyRef();
		vEmpOpObj.Operation = pOperation;
	EndIf;
	// Get operation room space
	vStds = Catalogs.Operations.GetOperationStandards(vEmpOpObj.Operation, vEmpOpObj.Hotel, vEmpOpObj.RoomType, vEmpOpObj.Room, vEmpOpObj.Employee);
	If vStds.Count() > 0 then
		vStdsRow = vStds.Get(0);
		vEmpOpObj.RoomSpace = vStdsRow.RoomSpace;
		vEmpOpObj.Price = vStdsRow.Price;
	EndIf;
	// Get number of persons in the room for the operation start date
	vEmpOpObj.NumberOfPersons = vEmpOpObj.pmGetNumberOfPersons();
	// Fill operation start and end PBX codes
	vEmpOpObj.pmFillPBXCodes();
	// Fill operation articles consumption standards table
	vEmpOpObj.Articles.Clear();
	vEmpOpObj.pmFillArticles();
	// Calculate durations
	vEmpOpObj.pmCalculateDurations();
	// Post document
	vEmpOpObj.Write(DocumentWriteMode.Posting);
	Return vEmpOpObj.Ref;
EndFunction // GetNewOperationDocument

// -----------------------------------------------------------------------------
Function GetOperationDocument(pOperation, pRoom, pPeriod, pState)
	vEmpOpRef = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	EmployeeOperation.Ref
	|FROM
	|	Document.EmployeeOperation AS EmployeeOperation
	|WHERE
	|	EmployeeOperation.Posted
	|	AND EmployeeOperation.Room = &qRoom
	|	AND (EmployeeOperation.OperationEndTime = &qEmptyDate
	|				AND &qState < 5
	|			OR EmployeeOperation.OperationEndConfirmedTime = &qEmptyDate
	|				AND &qState = 5)
	|	AND EmployeeOperation.Date > ENDOFPERIOD(EmployeeOperation.Room.Owner.EditProhibitedDate, DAY)
	|
	|ORDER BY
	|	EmployeeOperation.PointInTime DESC";
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qState", pState);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		vEmpOpRef = vDocs.Get(0).Ref;
		If ValueIsFilled(pOperation) And vEmpOpRef.Operation <> pOperation Then
			vEmpOpObj = vEmpOpRef.GetObject();
			vEmpOpObj.Operation = pOperation;
			// Get operation room space
			vStds = Catalogs.Operations.GetOperationStandards(vEmpOpObj.Operation, vEmpOpObj.Hotel, vEmpOpObj.RoomType, vEmpOpObj.Room, vEmpOpObj.Employee);
			If vStds.Count() > 0 then
				vStdsRow = vStds.Get(0);
				vEmpOpObj.RoomSpace = vStdsRow.RoomSpace;
				vEmpOpObj.Price = vStdsRow.Price;
			EndIf;
			// Fill operation start and end PBX codes
			vEmpOpObj.pmFillPBXCodes();
			// Fill operation articles consumption standards table
			vEmpOpObj.Articles.Clear();
			vEmpOpObj.pmFillArticles();
			// Calculate durations
			vEmpOpObj.pmCalculateDurations();
			// Repost document
			vEmpOpObj.Write(DocumentWriteMode.Posting);
		EndIf;
		If vDocs.Count() > 1 Then
			For i = 1 To (vDocs.Count() - 1) Do
				vDocRef = vDocs.Get(i).Ref;
				vDocObj = vDocRef.GetObject();
				vDocObj.SetDeletionMark(True);
			EndDo;
		EndIf;
	Else
		If ValueIsFilled(pOperation) Then
			vEmpOpRef = GetNewOperationDocument(pOperation, pRoom, pPeriod);
		EndIf;
	EndIf;
	Return vEmpOpRef;
EndFunction // GetOperationDocument

// -----------------------------------------------------------------------------
Function GetRegularOperation(pOperation, pRoom, pPeriod, pRegularOperationGroup)
	vOperation = pOperation;
	If pRegularOperationGroup.RegularOperations.Count() > 0 Then
		vDuration = 0;
		vWeekDay = WeekDay(pPeriod);
		vNumDay = -1;
		vRoomRate = Undefined;
		vAccDocs = cmGetRoomGuests(pRoom.Owner, Undefined, pRoom, pPeriod, pPeriod);
		For Each vAccDocsRow In vAccDocs Do
			If BegOfDay(pPeriod) >= BegOfDay(vAccDocsRow.DateFrom) And BegOfDay(pPeriod) <= BegOfDay(vAccDocsRow.DateTo) Then
				vDuration = (BegOfDay(vAccDocsRow.DateTo) - BegOfDay(vAccDocsRow.DateFrom))/(24*3600);
				vNumDay = (BegOfDay(pPeriod) - BegOfDay(vAccDocsRow.DateFrom))/(24*3600);
				vRoomRate = vAccDocsRow.RoomRate;
				Break;
			EndIf;
		EndDo;
		If vNumDay >= 0 Then
			For Each vRPRow In pRegularOperationGroup.RegularOperations Do
				If ValueIsFilled(vRPRow.RegularOperation) And vRPRow.PerformWhenRoomIsBusy Then
					If vRPRow.DoNotPerformOnWeekends Then
						If vWeekDay = 6 Or vWeekDay = 7 Then
							Continue;
						EndIf;
					EndIf;
					If Not ValueIsFilled(vRPRow.RoomType) Or vRPRow.RoomType = pRoom.RoomType Or ValueIsFilled(vRPRow.RoomType) And vRPRow.RoomType.IsFolder And pRoom.RoomType.BelongsToItem(vRPRow.RoomType) Then
						If Not ValueIsFilled(vRPRow.RoomRate) Or vRPRow.RoomRate = vRoomRate Or ValueIsFilled(vRPRow.RoomRate) And vRPRow.RoomRate.IsFolder And vRoomRate.BelongsToItem(vRPRow.RoomRate) Then
							If vNumDay = 0 And vRPRow.PerformOnCheckInDay Then
								vOperation = vRPRow.RegularOperation;
								Break;
							ElsIf vNumDay = vDuration And vRPRow.PerformOnCheckOutDay Then
								vOperation = vRPRow.RegularOperation;
								Break;
							ElsIf vRPRow.RegularOperationFrequency > 0 And vNumDay > 0 And Int(vNumDay/vRPRow.RegularOperationFrequency) = vNumDay/vRPRow.RegularOperationFrequency Then
								vOperation = vRPRow.RegularOperation;
								Break;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vOperation;
EndFunction // GetRegularOperation

#EndRegion
