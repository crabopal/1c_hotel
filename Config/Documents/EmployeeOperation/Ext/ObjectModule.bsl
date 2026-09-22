
#Region Variables

Var DoFillEmployeeAssignmentTime;

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// 1. Post to the employee operations history register
	PostToEmployeeOperationsHistory();
	
	// 2. Post to the employee operations turnover
	PostToEmployeeOperationsTurnover();
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	DoFillEmployeeAssignmentTime = False;
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ChangeAuthor = SessionParameters.CurrentUser;
	ChangeDate = CurrentSessionDate();
	
	If pWriteMode = DocumentWriteMode.Posting Then
		AutoOperation();	
		NotifyEmployee(); 		
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		Else
			If ValueIsFilled(Ref) And ValueIsFilled(Employee) Then
				If Employee <> Ref.Employee Then
					DoFillEmployeeAssignmentTime = True;
				EndIf;
				If Not ValueIsFilled(Ref.Employee) AND
					Not ValueIsFilled(EmployeeAssignmentTime) Then
					DoFillEmployeeAssignmentTime = True;
				EndIf;
			EndIf;
			If DoFillEmployeeAssignmentTime Then
				EmployeeAssignmentTime = CurrentSessionDate();
			EndIf;
			pmCalculateDurations();
			If Ref.EmployeeAssignmentTime <> EmployeeAssignmentTime And ValueIsFilled(EmployeeAssignmentTime) And ValueIsFilled(Room) Then
				vRoomStatusAtAssignment = Undefined;
				vRSHStateRows = Room.GetObject().pmGetRoomStatusHistoryState(EmployeeAssignmentTime);
				If vRSHStateRows.Count() > 0 Then
					vRoomStatusAtAssignment = vRSHStateRows.Get(0).RoomStatus;
				EndIf;
				If ValueIsFilled(vRoomStatusAtAssignment) And vRoomStatusAtAssignment.OperationsSchedule.Count() > 0 Then
					// Try to get operation
					vPeriodTime = '00010101' + (EmployeeAssignmentTime - BegOfDay(EmployeeAssignmentTime));
					vOperation = Undefined;
					For Each vScheduleRow In vRoomStatusAtAssignment.OperationsSchedule Do
						If ValueIsFilled(vScheduleRow.Operation) Then
							If Not IsBlankString(vScheduleRow.WeekDays) Then
								If Find(vScheduleRow.WeekDays, String(WeekDay(EmployeeAssignmentTime))) = 0 Then
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
					If ValueIsFilled(vOperation) And vOperation <> Operation Then
						Operation = vOperation;
						// Get operation room space
						vStds = Catalogs.Operations.GetOperationStandards(Operation, Hotel, RoomType, Room, Employee);
						If vStds.Count() > 0 then
							vStdsRow = vStds.Get(0);
							RoomSpace = Quantity * vStdsRow.RoomSpace;
							Price = Round(Quantity * vStdsRow.Price, 2);
						EndIf;
						// Fill operation articles consumption standards table
						Articles.Clear();
						pmFillArticles();
						// Fill operation start and end PBX codes
						pmFillPBXCodes();
					EndIf;
				EndIf;
			EndIf;	
		EndIf;	
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
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
	If Not ValueIsFilled(Operation) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Работа> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Operation> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Operation> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Operation", pAttributeInErr);
	EndIf;
	If Quantity = 0 Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Количество работ> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Operations quantity> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Operations quantity> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Quantity", pAttributeInErr);
	EndIf;
	// Check that there is only one document for the given employee, operation and operation start date
	If ValueIsFilled(Hotel) And ValueIsFilled(Employee) And ValueIsFilled(Operation) And ValueIsFilled(RoomType) Then
		// Run query
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	EmployeeOperation.Ref
		|FROM
		|	Document.EmployeeOperation AS EmployeeOperation
		|WHERE
		|	EmployeeOperation.Posted
		|	AND EmployeeOperation.Employee = &qEmployee
		|	AND EmployeeOperation.Hotel = &qHotel
		|	AND EmployeeOperation.Operation = &qOperation
		|	AND EmployeeOperation.RoomType = &qRoomType
		|	AND EmployeeOperation.Room = &qRoom
		|	AND (EmployeeOperation.OperationStartTime = &qOperationStartTime
		|				AND &qOperationStartTime > &qEmptyDate
		|			OR EmployeeOperation.OperationIntentTime = &qOperationIntentTime
		|				AND &qOperationIntentTime > &qEmptyDate)
		|	AND EmployeeOperation.Ref <> &qRef
		|
		|ORDER BY
		|	EmployeeOperation.PointInTime";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qEmployee", Employee);
		vQry.SetParameter("qOperation", Operation);
		vQry.SetParameter("qRoomType", RoomType);
		vQry.SetParameter("qRoom", Room);
		vQry.SetParameter("qOperationStartTime", OperationStartTime);
		vQry.SetParameter("qOperationIntentTime", OperationIntentTime);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qRef", Ref);
		vQryRes = vQry.Execute().Unload();
		// Check query result
		If vQryRes.Count() > 0 Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "У указанного сотрудника в указанное время начала работы уже есть один документ регистрации выбранной работы!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "There is already one operation registration document for the given operation, employee and operation start time!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "There is already one operation registration document for the given operation, employee and operation start time!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Employee", pAttributeInErr);
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	// Fill from session parameters
	Author = SessionParameters.CurrentUser;
	Date = CurrentSessionDate();
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(OperationIntentTime) And Not ValueIsFilled(EmployeeAssignmentTime) Then
		OperationStartTime = cm1SecondShift(CurrentSessionDate());
	EndIf;
	// Set quantity to 1
	Quantity = 1;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetOperationEndTime() Export
	vOperationEndTime = OperationEndTime;
	If ValueIsFilled(OperationStartTime) Then
		vOperationEndTime = cm0SecondShift(OperationStartTime + Duration * 60);
	EndIf;
	Return vOperationEndTime;
EndFunction // pmGetOperationEndTime 

// -----------------------------------------------------------------------------
Function pmGetOperationDuration() Export
	vDuration = Duration;
	If ValueIsFilled(OperationStartTime) And ValueIsFilled(OperationEndTime) Then
		If OperationEndTime >= OperationStartTime Then
			vDuration = Round((OperationEndTime - OperationStartTime)/60, 0);
		EndIf;
	EndIf;
	Return vDuration;
EndFunction // pmGetOperationEndTime

// -----------------------------------------------------------------------------
Procedure pmCalculateDurations() Export
	vAssignmentDuration = 0;
	If ValueIsFilled(OperationIntentTime) And ValueIsFilled(EmployeeAssignmentTime) And EmployeeAssignmentTime > OperationIntentTime Then
		vAssignmentDuration = Round((EmployeeAssignmentTime - OperationIntentTime)/60, 0);
	EndIf;
	If vAssignmentDuration <> AssignmentDuration Then
		AssignmentDuration = vAssignmentDuration;
	EndIf;
	vWaitDuration = 0;
	If ValueIsFilled(EmployeeAssignmentTime) And ValueIsFilled(OperationStartTime) And OperationStartTime > EmployeeAssignmentTime Then
		vWaitDuration = Round((OperationStartTime - EmployeeAssignmentTime)/60, 0);
	EndIf;
	If vWaitDuration <> WaitDuration Then
		WaitDuration = vWaitDuration;
	EndIf;
	If ValueIsFilled(OperationStartTime) And ValueIsFilled(OperationEndTime) And OperationEndTime > OperationStartTime Then
		vDuration = Round((OperationEndTime - OperationStartTime)/60, 0);
		If vDuration <> Duration Then
			Duration = vDuration;
		EndIf;
	EndIf;
	vConfirmationDuration = 0;
	If ValueIsFilled(OperationEndTime) And ValueIsFilled(OperationEndConfirmedTime) And OperationEndConfirmedTime > OperationEndTime Then
		vConfirmationDuration = Round((OperationEndConfirmedTime - OperationEndTime)/60, 0);
	EndIf;
	If vConfirmationDuration <> ConfirmationDuration Then
		ConfirmationDuration = vConfirmationDuration;
	EndIf;
	vTotalDuration = AssignmentDuration + WaitDuration + Duration + ConfirmationDuration;
	If vTotalDuration <> TotalDuration Then
		TotalDuration = vTotalDuration;
	EndIf;
EndProcedure // pmCalculateDurations

// -----------------------------------------------------------------------------
Procedure pmFillArticles() Export
	// Initialize resulting value table
	vStds = New ValueTable();
	
	If ValueIsFilled(Operation) Then
		// Get data from the standards table for the room
		If ValueIsFilled(Room) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ArticleConsumptionStandards.Article,
			|	ArticleConsumptionStandards.Quantity,
			|	ArticleConsumptionStandards.Unit,
			|	ArticleConsumptionStandards.IsPerPerson,
			|	ArticleConsumptionStandards.IsPerRoomSpaceUnit
			|FROM
			|	InformationRegister.ArticleConsumptionStandards AS ArticleConsumptionStandards
			|WHERE
			|	ArticleConsumptionStandards.Operation = &qOperation
			|	AND ArticleConsumptionStandards.Hotel = &qHotel
			|	AND ArticleConsumptionStandards.Room = &qRoom
			|
			|ORDER BY
			|	ArticleConsumptionStandards.Article.SortCode";
			vQry.SetParameter("qOperation", Operation);
			vQry.SetParameter("qHotel", Hotel);
			vQry.SetParameter("qRoom", Room);
			vStds = vQry.Execute().Unload();
		EndIf;
		
		// Get data from the standards table for the room type
		If vStds.Count() = 0 And ValueIsFilled(RoomType) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ArticleConsumptionStandards.Article,
			|	ArticleConsumptionStandards.Quantity,
			|	ArticleConsumptionStandards.Unit,
			|	ArticleConsumptionStandards.IsPerPerson,
			|	ArticleConsumptionStandards.IsPerRoomSpaceUnit
			|FROM
			|	InformationRegister.ArticleConsumptionStandards AS ArticleConsumptionStandards
			|WHERE
			|	ArticleConsumptionStandards.Operation = &qOperation
			|	AND ArticleConsumptionStandards.Hotel = &qHotel
			|	AND ArticleConsumptionStandards.RoomType = &qRoomType
			|	AND ArticleConsumptionStandards.Room = &qRoom
			|ORDER BY
			|	ArticleConsumptionStandards.Article.SortCode";
			vQry.SetParameter("qOperation", Operation);
			vQry.SetParameter("qHotel", Hotel);
			vQry.SetParameter("qRoomType", RoomType);
			vQry.SetParameter("qRoom", Catalogs.Rooms.EmptyRef());
			vStds = vQry.Execute().Unload();
		Endif;
		
		// Get data from the standards table for the hotel and empty room and room type
		If vStds.Count() = 0 Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ArticleConsumptionStandards.Article,
			|	ArticleConsumptionStandards.Quantity,
			|	ArticleConsumptionStandards.Unit,
			|	ArticleConsumptionStandards.IsPerPerson,
			|	ArticleConsumptionStandards.IsPerRoomSpaceUnit
			|FROM
			|	InformationRegister.ArticleConsumptionStandards AS ArticleConsumptionStandards
			|WHERE
			|	ArticleConsumptionStandards.Operation = &qOperation
			|	AND ArticleConsumptionStandards.Hotel = &qHotel
			|	AND ArticleConsumptionStandards.RoomType = &qRoomType
			|	AND ArticleConsumptionStandards.Room = &qRoom
			|ORDER BY
			|	ArticleConsumptionStandards.Article.SortCode";
			vQry.SetParameter("qOperation", Operation);
			vQry.SetParameter("qHotel", Hotel);
			vQry.SetParameter("qRoomType", Catalogs.RoomTypes.EmptyRef());
			vQry.SetParameter("qRoom", Catalogs.Rooms.EmptyRef());
			vStds = vQry.Execute().Unload();
		Endif;
		
		// Get data from the standards table for the empty hotel, room and room type
		If vStds.Count() = 0 Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ArticleConsumptionStandards.Article,
			|	ArticleConsumptionStandards.Quantity,
			|	ArticleConsumptionStandards.Unit,
			|	ArticleConsumptionStandards.IsPerPerson,
			|	ArticleConsumptionStandards.IsPerRoomSpaceUnit
			|FROM
			|	InformationRegister.ArticleConsumptionStandards AS ArticleConsumptionStandards
			|WHERE
			|	ArticleConsumptionStandards.Operation = &qOperation
			|	AND ArticleConsumptionStandards.Hotel = &qHotel
			|	AND ArticleConsumptionStandards.RoomType = &qRoomType
			|	AND ArticleConsumptionStandards.Room = &qRoom
			|ORDER BY
			|	ArticleConsumptionStandards.Article.SortCode";
			vQry.SetParameter("qOperation", Operation);
			vQry.SetParameter("qHotel", Catalogs.Hotels.EmptyRef());
			vQry.SetParameter("qRoomType", Catalogs.RoomTypes.EmptyRef());
			vQry.SetParameter("qRoom", Catalogs.Rooms.EmptyRef());
			vStds = vQry.Execute().Unload();
		Endif;
		
		// Add rows to the articles tabular part
		If vStds.Count() > 0 Then
			For Each vStdsRow In vStds Do
				vRow = Articles.Add();
				vRow.Article = vStdsRow.Article;
				vRow.Unit = vStdsRow.Unit;
				vRow.IsPerPerson = vStdsRow.IsPerPerson;
				vRow.IsPerRoomSpaceUnit = vStdsRow.IsPerRoomSpaceUnit;
				// Calculate article quantity according to the parameters
				If vRow.IsPerRoomSpaceUnit Then
					If vRow.IsPerPerson Then
						vRow.QuantityPerUnit = vStdsRow.Quantity;
						vRow.PlannedQuantity = Quantity * vRow.QuantityPerUnit * RoomSpace * NumberOfPersons;
					Else
						vRow.QuantityPerUnit = vStdsRow.Quantity;
						vRow.PlannedQuantity = Quantity * vRow.QuantityPerUnit * RoomSpace;
					EndIf;
				Else
					If vRow.IsPerPerson Then
						vRow.QuantityPerUnit = vStdsRow.Quantity;
						vRow.PlannedQuantity = Quantity * vStdsRow.Quantity * NumberOfPersons;
					Else
						vRow.PlannedQuantity = Quantity * vStdsRow.Quantity;
					EndIf;
				EndIf;
				vRow.Quantity = vRow.PlannedQuantity;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // pmFillArticles

// -----------------------------------------------------------------------------
Function pmGetPreviousOperation() Export
	vPrevOp = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	EmployeeOperation.Ref
	|FROM
	|	Document.EmployeeOperation AS EmployeeOperation
	|WHERE
	|	EmployeeOperation.Posted
	|	AND EmployeeOperation.Hotel = &qHotel
	|	AND EmployeeOperation.Room = &qRoom
	|	AND EmployeeOperation.Operation = &qOperation
	|	AND (EmployeeOperation.OperationStartTime < &qStartPeriod
	|				AND EmployeeOperation.OperationStartTime > &qEmptyDate
	|			OR EmployeeOperation.OperationIntentTime < &qIntentPeriod
	|				AND EmployeeOperation.OperationIntentTime > &qEmptyDate
	|				AND EmployeeOperation.OperationStartTime = &qEmptyDate)
	|
	|ORDER BY
	|	EmployeeOperation.PointInTime DESC";
	vQry.SetParameter("qStartPeriod", OperationStartTime);
	vQry.SetParameter("qIntentPeriod", OperationIntentTime);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qOperation", Operation);
	vQry.SetParameter("qEmptyDate", '00010101');
	vPrevOperations = vQry.Execute().Unload();
	For Each vPrevOperationsRow In vPrevOperations Do
		vPrevOp = vPrevOperationsRow.Ref;
		Break;
	EndDo;
	Return vPrevOp;
EndFunction // pmGetPreviousOperation

// -----------------------------------------------------------------------------
Function pmGetNumberOfPersons() Export
	vOccupiedBeds = 0; 
	vOccupiedPersons = 0;
	vTime = OperationStartTime;
	If Not ValueIsFilled(vTime) Then
		vTime = OperationIntentTime;
	EndIf;
	If ValueIsFilled(Room) And ValueIsFilled(vTime) Then
		If ValueIsFilled(Operation) And ValueIsFilled(Hotel) And Operation = Hotel.CheckOutCleaning Then
			// Room is usually empty at the moment of check-out cleaning start, 
			// so we need to find number of checked out guests. The best decision would be
			// to calculate the check-out persons turnover from the moment of previous check-out 
			// cleaning but we'll limit this turnover by the number of beds in the room
			vPrevOp = pmGetPreviousOperation();
			If ValueIsFilled(vPrevOp) Then
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	RoomInventoryTurnovers.GuestsCheckedOutTurnover,
				|	RoomInventoryTurnovers.BedsCheckedOutTurnover
				|FROM
				|	AccumulationRegister.RoomInventory.Turnovers(
				|			&qPeriodFrom,
				|			&qPeriodTo,
				|			Period,
				|			Hotel = &qHotel
				|				AND Room = &qRoom) AS RoomInventoryTurnovers";
				vQry.SetParameter("qPeriodFrom", ?(ValueIsFilled(vPrevOp.OperationStartTime), vPrevOp.OperationStartTime, vPrevOp.OperationIntentTime));
				vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(OperationStartTime), OperationStartTime, OperationIntentTime));
				vQry.SetParameter("qHotel", Hotel);
				vQry.SetParameter("qRoom", Room);
				vTurnovers = vQry.Execute().Unload();
				If vTurnovers.Count() > 0 Then
					vTurnoversRow = vTurnovers.Get(0);
					vOccupiedBeds = Min(Room.NumberOfBedsPerRoom, vTurnoversRow.BedsCheckedOutTurnover);
					vOccupiedPersons = Min(Room.NumberOfBedsPerRoom, vTurnoversRow.GuestsCheckedOutTurnover);
				Else
					// We'll get the number of beds in the room
					vOccupiedBeds = Room.NumberOfBedsPerRoom;
					vOccupiedPersons = Room.NumberOfBedsPerRoom;
				EndIf;
			Else
				// We'll get the number of beds in the room
				vOccupiedBeds = Room.NumberOfBedsPerRoom;
				vOccupiedPersons = Room.NumberOfBedsPerRoom;
			EndIf;
		Else
			// In all other situations we'll get the number of persons currently in the room
			vRoomPresentation = cmGetRoomPresentation(Hotel, Room, vTime, vOccupiedBeds, vOccupiedPersons);
		EndIf;
	Else
		If ValueIsFilled(RoomType) Then
			// We'll get the number of beds in the room
			vOccupiedBeds = RoomType.NumberOfBedsPerRoom;
			vOccupiedPersons = RoomType.NumberOfBedsPerRoom;
		EndIf;
	EndIf;
	Return vOccupiedPersons;
EndFunction // pmGetNumberOfPersons

// -----------------------------------------------------------------------------
Procedure pmCalculateArticleQuantity(pRow) Export
	If pRow.IsPerRoomSpaceUnit Then
		If pRow.IsPerPerson Then
			pRow.PlannedQuantity = Quantity * pRow.QuantityPerUnit * RoomSpace * NumberOfPersons;
		Else
			pRow.PlannedQuantity = Quantity * pRow.QuantityPerUnit * RoomSpace;
		EndIf;
	Else
		If pRow.IsPerPerson Then
			pRow.PlannedQuantity = Quantity * pRow.QuantityPerUnit * NumberOfPersons;
		Else
			pRow.PlannedQuantity = Quantity * pRow.QuantityPerUnit;
		EndIf;
	EndIf;
	pRow.Quantity = pRow.PlannedQuantity;
EndProcedure // pmCalculateArticleQuantity

// -----------------------------------------------------------------------------
Procedure pmFillPBXCodes() Export
	If ValueIsFilled(Employee) And ValueIsFilled(Operation) Then
		If Operation.PBXStartCode <> 0 And 
		   Operation.PBXEndCode <> 0 Then
			PBXStartCode = Operation.PBXStartCode;
			PBXEndCode = Operation.PBXEndCode;
		Else
			vCodes = Employee.GetObject().pmGetOperationPBXCodes(Operation);
			For Each vCodesRow In vCodes Do
				If vCodesRow.IsOperationStart Then
					PBXStartCode = vCodesRow.PBXCode;
				ElsIf vCodesRow.IsOperationEnd Then
					PBXEndCode = vCodesRow.PBXCode;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // pmFillPBXCodes

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure PostToEmployeeOperationsHistory()
	If ValueIsFilled(Employee) Then
		Movement = RegisterRecords.EmployeeOperationsHistory.Add();
		
		Movement.Period = ?(ValueIsFilled(OperationStartTime), OperationStartTime, Date);
		
		FillPropertyValues(Movement, ThisObject);
		
		Movement.Duration = Duration * Quantity;
		Movement.RoomSpace = RoomSpace * Quantity;
		
		RegisterRecords.EmployeeOperationsHistory.Write();
	EndIf;
EndProcedure // PostToEmployeeOperationsHistory

// -----------------------------------------------------------------------------
Procedure PostToEmployeeOperationsTurnover()
	If ValueIsFilled(OperationStartTime) Or ValueIsFilled(OperationIntentTime) Then
		// Add record for the operation itself
		Movement = RegisterRecords.EmployeeOperationsTurnover.Add();
		
		Movement.Period = ?(ValueIsFilled(OperationStartTime), OperationStartTime, OperationIntentTime);
		
		FillPropertyValues(Movement, ThisObject, , "Quantity");
		
		// Fill count resource
		Movement.Count = Quantity;
		
		// Fill durations
		Movement.AssignmentDuration = AssignmentDuration * Quantity;
		Movement.WaitDuration = WaitDuration * Quantity;
		Movement.Duration = Duration * Quantity;
		Movement.ConfirmationDuration = ConfirmationDuration * Quantity;
		Movement.TotalDuration = TotalDuration * Quantity;
		
		Movement.RoomSpace = RoomSpace * Quantity;

		// Fill amount
		Movement.Sum = Price * Quantity;
		
		// Add records for the each article in articles
		For Each vRow In Articles Do
			Movement = RegisterRecords.EmployeeOperationsTurnover.Add();
			
			Movement.Period = ?(ValueIsFilled(OperationStartTime), OperationStartTime, OperationIntentTime);
			
			FillPropertyValues(Movement, ThisObject, , "AssignmentDuration, WaitDuration, Duration, ConfirmationDuration, TotalDuration, RoomSpace, NumberOfPersons");
			FillPropertyValues(Movement, vRow);
			Movement.PlannedQuantity = vRow.PlannedQuantity;
			Movement.Sum = 0;
		EndDo;
		
		RegisterRecords.EmployeeOperationsTurnover.Write();
	EndIf;
EndProcedure // PostToEmployeeOperationsTurnover

// -----------------------------------------------------------------------------
Procedure NotifyEmployee()
	If not ValueIsFilled(Ref) Then
		vRef = Documents.EmployeeOperation.GetRef();
		SetNewObjectRef(vRef);
	Else
		vRef = Ref;
	EndIf;
	
	If vRef.Employee <> Employee and not ValueIsFilled(OperationStartTime) Then
		Catalogs.ChatBots.AddNotification(vRef,Hotel,Employee,"Назначен новый номер","");
	Endif;
	If Room.RoomStatus = Room.Owner.RoomStatusInspection  and ValueIsFilled(OperationEndTime) then
		Catalogs.ChatBots.AddNotification(vRef,Hotel,Enums.ChatRoles.Supervisor,"Новый номер ожидает проверки","");
	EndIf;
	If Room.RoomStatus = Operation.OperationsStart and not ValueIsFilled(Employee) then
		Catalogs.ChatBots.AddNotification(vRef,Hotel,Enums.ChatRoles.Supervisor,"Появился грязный номер! Назначьте на него сотрудника.","");
	ElsIf vRef.Room.RoomStatus <> Room.RoomStatus and ValueIsFilled(Employee) and Room.RoomStatus = Operation.OperationsStart  Then 
		Catalogs.ChatBots.AddNotification(vRef,Hotel,Employee,"Из номера выехали гости!","");
	EndIf;
	
EndProcedure // NotifyEmployee

// -----------------------------------------------------------------------------
Function AutoOperation()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ChatBots.Ref
	|FROM
	|	Catalog.ChatBots AS ChatBots
	|WHERE
	|	ChatBots.IsActive = TRUE
	|	AND ChatBots.UseAutoOperationControl = TRUE";		
	QueryResult = Query.Execute();		
	SelectionDetailRecords = QueryResult.Select();	
	If SelectionDetailRecords.Next() Then
		If ValueIsFilled(Employee) and ValueIsFilled(OperationEndTime) Then
			WriteLogEvent("AutoOperation", EventLogLevel.Information,Metadata(), Ref, "Employee = " + Employee + "OperationEndTime = " + OperationEndTime);
			vMaid = Employee;
			vMaidOperList = cmGetEmployeeOperationQueue(CurrentSessionDate(),vMaid);
			WriteLogEvent("AutoOperation", EventLogLevel.Information, Metadata(), Ref, "Найдено = " + vMaidOperList.Count());
			If vMaidOperList.Count() > 1 Then
				For Each vOper In vMaidOperList Do
					If not vOper.RefDoc = Ref Then
						WriteLogEvent("AutoOperation", EventLogLevel.Information, Metadata(), Ref, "Назначаем работу = " + vOper.RefDoc);
						
						WriteLogEvent("AutoOperation", EventLogLevel.Information, Metadata(), Ref, "Отправляем ответ");
						Catalogs.ChatBots.Response(vMaid,"<b>Назначен новый номер</b>", vOper.RefDoc.Room);
						Break;
					EndIf;
				EndDo;
			Else
				vMaidOperList = cmGetEmployeeOperationQueue(CurrentSessionDate(),,vMaid);
				WriteLogEvent("AutoOperation", EventLogLevel.Information, Metadata(), Ref, "Найдено = " + vMaidOperList.Count());
				If vMaidOperList.Count() > 0 Then
					vEmplOper                        = vMaidOperList[0].RefDoc.GetObject();
					WriteLogEvent("AutoOperation", EventLogLevel.Information, Metadata(), Ref, "Назначаем работу = " + vEmplOper);
					vEmplOper.Employee               = vMaid;
					vEmplOper.EmployeeAssignmentTime = CurrentSessionDate();
					vEmplOper.Write(DocumentWriteMode.Posting);
				EndIf;
			EndIf;	
		ElsIf not ValueIsFilled(Employee) and (Room.RoomStatus = Room.Owner.OccupiedDirtyRoomStatus or Room.RoomStatus = Room.Owner.RoomStatusAfterCheckOut) then
			vFreeMaids = cmGetFreeMaids(Catalogs.ChatBots.GetAutorizaitingEmployee(Room.Owner).UnloadColumn("Employee"));
			WriteLogEvent("AutoOperation", EventLogLevel.Information, Metadata(), Ref, "Свободных горничных = " + vFreeMaids.Count());
			If vFreeMaids.Count() > 0 Then
				Employee               = vFreeMaids[0].Employee;
				WriteLogEvent("AutoOperation", EventLogLevel.Information, Metadata(), Ref, "Назначаем работу на = " + vFreeMaids[0].Employee);
				
				EmployeeAssignmentTime = CurrentSessionDate();
			EndIf;
		EndIf;
	EndIf;
EndFunction // AutoOperation

#EndRegion

#Region Initialize    

// -----------------------------------------------------------------------------
DoFillEmployeeAssignmentTime = False;

#EndRegion
