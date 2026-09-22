
#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Release room allotments
	pmReleaseExpiredRoomAllotments(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure pmReleaseExpiredRoomAllotments(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.ReleaseExpiredRoomAllotments';ru='Обработка.СнятиеПросроченныхКвотНомеров';de='DataProcessor.ReleaseExpiredRoomAllotments'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	vCurDate = BegOfDay(CurrentSessionDate());
	// Get list of room allotments to process
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	AllRoomQuotas.Allotment AS Allotment,
	|	AllRoomQuotas.Allotment.PeriodFrom AS AllotmentPeriodFrom,
	|	AllRoomQuotas.Allotment.PeriodTo AS AllotmentPeriodTo,
	|	AllRoomQuotas.Allotment.ReleaseDate AS AllotmentReleaseDate,
	|	AllRoomQuotas.Hotel AS Hotel,
	|	AllRoomQuotas.RoomType AS RoomType,
	|	AllRoomQuotas.PeriodFrom AS PeriodFrom,
	|	AllRoomQuotas.PeriodTo AS PeriodTo,
	|	AllRoomQuotas.ReleaseTime AS ReleaseTime
	|FROM
	|	(SELECT
	|		RoomQuotasRoomTypes.Ref AS Allotment,
	|		RoomQuotasRoomTypes.Hotel AS Hotel,
	|		RoomQuotasRoomTypes.RoomType AS RoomType,
	|		RoomQuotasRoomTypes.PeriodFrom AS PeriodFrom,
	|		RoomQuotasRoomTypes.PeriodTo AS PeriodTo,
	|		RoomQuotasRoomTypes.ReleaseTime AS ReleaseTime
	|	FROM
	|		Catalog.RoomQuotas.RoomTypes AS RoomQuotasRoomTypes
	|	WHERE
	|		NOT RoomQuotasRoomTypes.Ref.IsFolder
	|		AND NOT RoomQuotasRoomTypes.Ref.DeletionMark
	|		AND (RoomQuotasRoomTypes.Hotel IN HIERARCHY (&qHotel)
	|				OR RoomQuotasRoomTypes.Hotel = &qEmptyHotel
	|				OR &qHotelIsEmpty)
	|		AND RoomQuotasRoomTypes.ReleaseTime > 0
	|		AND RoomQuotasRoomTypes.PeriodTo > &qCurrentDate
	|		AND CASE
	|				WHEN &qProcessingType = 1
	|					THEN RoomQuotasRoomTypes.Ref.IsCommitment
	|				WHEN &qProcessingType = 2
	|					THEN NOT RoomQuotasRoomTypes.Ref.IsCommitment
	|				ELSE TRUE
	|			END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomQuotas.Ref,
	|		RoomQuotas.Hotel,
	|		&qEmptyRoomType,
	|		&qEmptyDate,
	|		&qEmptyDate,
	|		RoomQuotas.ReleaseTime
	|	FROM
	|		Catalog.RoomQuotas AS RoomQuotas
	|	WHERE
	|		NOT RoomQuotas.IsFolder
	|		AND NOT RoomQuotas.DeletionMark
	|		AND (RoomQuotas.Hotel IN HIERARCHY (&qHotel)
	|				OR RoomQuotas.Hotel = &qEmptyHotel
	|				OR &qHotelIsEmpty)
	|		AND (RoomQuotas.ReleaseTime > 0
	|				OR RoomQuotas.ReleaseDate <> &qEmptyDate
	|					AND RoomQuotas.ReleaseDate <= &qCurrentDate
	|					AND RoomQuotas.PeriodTo <> &qEmptyDate
	|					AND RoomQuotas.PeriodTo > &qCurrentDate)
	|		AND CASE
	|				WHEN &qProcessingType = 1
	|					THEN RoomQuotas.IsCommitment
	|				WHEN &qProcessingType = 2
	|					THEN NOT RoomQuotas.IsCommitment
	|				ELSE TRUE
	|			END) AS AllRoomQuotas
	|
	|ORDER BY
	|	AllRoomQuotas.Allotment.SortCode,
	|	AllRoomQuotas.Allotment.Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qCurrentDate", vCurDate);
	vQry.SetParameter("qProcessingType", ProcessingType);
	vAllotments = vQry.Execute().Unload();
	// Write off room allotment remains
	For Each vAllotmentsRow In vAllotments Do
		vAllotmentRef = Undefined;
		Try
			vAllotmentRef = vAllotmentsRow.Allotment;
			// Get hotel
			vHotel = Hotel;
			If Not ValueIsFilled(vHotel) Then
				vHotel = vAllotmentsRow.Hotel;
			EndIf;
			If Not ValueIsFilled(vHotel) Then
				Raise NStr("en='Failed to get hotel!';ru='Не указана гостиница!';de='Das Hotel ist nicht angegeben!'");
			EndIf;
			// Build release period
			vRoomRate = Undefined;
			If ValueIsFilled(vAllotmentRef.RoomRate) Then
				vRoomRate = vAllotmentRef.RoomRate;
			Else
				vRoomRate = vHotel.RoomRate;
			EndIf;
			If ValueIsFilled(vRoomRate) Then
				If ValueIsFilled(vAllotmentsRow.AllotmentReleaseDate) And 
				   vAllotmentsRow.AllotmentReleaseDate <= vCurDate And 
				   ValueIsFilled(vAllotmentsRow.AllotmentPeriodTo) And 
				   vAllotmentsRow.AllotmentPeriodTo >= vCurDate Then
					vReleaseDateFrom = vCurDate - 24*3600;
					vReleasePeriodFrom = cm0SecondShift(cmInitializeDateTime(vReleaseDateFrom, vRoomRate));
					vReleasePeriodTo = cm0SecondShift(cmInitializeDateTime(BegOfDay(vAllotmentsRow.AllotmentPeriodTo), vRoomRate));
					// Do for each room type
					vRoomTypes = cmGetAllRoomTypes(vHotel);
					For Each vRoomTypesRow In vRoomTypes Do
						cmWriteOffAllotmentRooms(vAllotmentRef, vRoomTypesRow.RoomType, vReleasePeriodFrom, vReleasePeriodTo);
					EndDo;
					// Log current state
					vMessage = NStr("ru = 'Обработана квота: " + String(vAllotmentRef) + "'; 
					                |de = 'Room allotment " + String(vAllotmentRef) + " was processed'; 
					                |en = 'Room allotment " + String(vAllotmentRef) + " was processed'");
					WriteLogEvent(NStr("en='DataProcessor.ReleaseExpiredRoomAllotments';ru='Обработка.СнятиеПросроченныхКвотНомеров';de='DataProcessor.ReleaseExpiredRoomAllotments'"), EventLogLevel.Information, ThisObject.Metadata(), vAllotmentRef, vMessage);
					If pIsInteractive Then
						tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
					EndIf;
				ElsIf vAllotmentsRow.ReleaseTime > 0 Then
					vReleaseDateFrom = vCurDate - 24*3600;
					vReleasePeriodFrom = cm0SecondShift(cmInitializeDateTime(vReleaseDateFrom, vRoomRate));
					vReleasePeriodTo = cm0SecondShift(cmInitializeDateTime(vCurDate + 24*3600*vAllotmentsRow.ReleaseTime, vRoomRate));
					If ValueIsFilled(vAllotmentsRow.PeriodFrom) And ValueIsFilled(vAllotmentsRow.PeriodTo) Then
						vPeriodFrom = cm0SecondShift(cmInitializeDateTime(BegOfDay(vAllotmentsRow.PeriodFrom), vRoomRate));
						vPeriodTo = cm0SecondShift(cmInitializeDateTime(BegOfDay(vAllotmentsRow.PeriodTo)+24*3600, vRoomRate));
						If vReleasePeriodFrom >= vPeriodTo Or vReleasePeriodTo <= vPeriodFrom Then
							Continue;
						Else
							If vPeriodFrom > vReleasePeriodFrom Then
								vReleasePeriodFrom = vPeriodFrom;
							EndIf;
							If vPeriodTo < vReleasePeriodTo Then
								vReleasePeriodTo = vPeriodTo;
							EndIf;
							If vReleasePeriodTo <= vReleasePeriodFrom Then
								Continue;
							EndIf;
						EndIf;
					EndIf;
					// Do for each room type
					vRoomTypes = New ValueTable();
					vRoomType = vAllotmentsRow.RoomType;
					If ValueIsFilled(vRoomType) Then
						If vRoomType.IsFolder Then
							vRoomTypes = cmGetAllRoomTypes(vHotel, vRoomType);
						Else
							vRoomTypes.Columns.Add("RoomType");
							vRoomTypesRow = vRoomTypes.Add();
							vRoomTypesRow.RoomType = vRoomType;
						EndIf;
					Else
						vRoomTypes = cmGetAllRoomTypes(vHotel);
					EndIf;
					For Each vRoomTypesRow In vRoomTypes Do
						cmWriteOffAllotmentRooms(vAllotmentRef, vRoomTypesRow.RoomType, vReleasePeriodFrom, vReleasePeriodTo);
					EndDo;
					// Log current state
					vMessage = NStr("ru = 'Обработана квота: " + String(vAllotmentRef) + "'; 
					                |de = 'Room allotment " + String(vAllotmentRef) + " was processed'; 
					                |en = 'Room allotment " + String(vAllotmentRef) + " was processed'");
					WriteLogEvent(NStr("en='DataProcessor.ReleaseExpiredRoomAllotments';ru='Обработка.СнятиеПросроченныхКвотНомеров';de='DataProcessor.ReleaseExpiredRoomAllotments'"), EventLogLevel.Information, ThisObject.Metadata(), vAllotmentRef, vMessage);
					If pIsInteractive Then
						tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
					EndIf;
				EndIf;
			Else
				// Log warning
				vMessage = NStr("ru = 'Не удалось определить тариф для квоты: " + String(vAllotmentRef) + "!'; 
				                |de = 'Failed to find room rate for the allotment " + String(vAllotmentRef) + "!'; 
				                |en = 'Failed to find room rate for the allotment " + String(vAllotmentRef) + "!'");
				WriteLogEvent(NStr("en='DataProcessor.ReleaseExpiredRoomAllotments';ru='Обработка.СнятиеПросроченныхКвотНомеров';de='DataProcessor.ReleaseExpiredRoomAllotments'"), EventLogLevel.Warning, ThisObject.Metadata(), vAllotmentRef, vMessage);
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				EndIf;
			EndIf;
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.ReleaseExpiredRoomAllotments';ru='Обработка.СнятиеПросроченныхКвотНомеров';de='DataProcessor.ReleaseExpiredRoomAllotments'"), EventLogLevel.Warning, ThisObject.Metadata(), ?(vAllotmentRef = Undefined, Undefined, vAllotmentRef), vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	WriteLogEvent(NStr("en='DataProcessor.ReleaseExpiredRoomAllotments';ru='Обработка.СнятиеПросроченныхКвотНомеров';de='DataProcessor.ReleaseExpiredRoomAllotments'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmReleaseExpiredRoomAllotments

#EndRegion   
