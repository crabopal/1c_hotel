// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

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
		If ValueIsFilled(Hotel) Then
			If Not ValueIsFilled(RoomStatusAfterRoomBlock) And ValueIsFilled(Hotel.RoomStatusAfterRoomBlock) Then
				RoomStatusAfterRoomBlock = Hotel.RoomStatusAfterRoomBlock;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Manage "Has room blocks" flag for the rooms
	pmManageHasRoomBlocks(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmManageHasRoomBlocks(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.ManageHasRoomBlocks';ru='Обработка.УправлениеФлагомЕстьБлокировкиНомерногоФонда';de='DataProcessor.ManageHasRoomBlocks'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Get list of rooms to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Rooms.Ref AS Room,
	|	Rooms.RoomStatus AS RoomStatus,
	|	Rooms.Owner.OutOfOrderRoomStatus AS OutOfOrderRoomStatus
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND (Rooms.Owner IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|
	|ORDER BY
	|	Rooms.SortCode";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vRooms = vQry.Execute().Unload();
	For Each vRoomsRow In vRooms Do
		BeginTransaction(DataLockControlMode.Managed);
		Try
			vRoomObj = vRoomsRow.Room.GetObject();

			// Get list of active room blocks for the current room
			vBlocks = vRoomObj.pmGetRoomBlocks();

			// Check all room blocks
			vHasRoomBlocks = False;
			vRoomBlockType = Undefined;
			For Each vBlocksRow In vBlocks Do
				If ValueIsFilled(vBlocksRow.DateTo) And vBlocksRow.DateTo < CurrentSessionDate() Then
					vSetRoomBlockObj = vBlocksRow.SetRoomBlock.GetObject();
					vSetRoomBlockObj.IsFinished = True;
					vSetRoomBlockObj.Write(DocumentWriteMode.Posting);
					// Log current state
					vMessage = NStr("ru = 'Установлен флаг завершения блокировки: " + String(vSetRoomBlockObj.Ref) + "'; 
					                |de = 'Room block is finished flag was set: " + String(vSetRoomBlockObj.Ref) + "'; 
					                |en = 'Room block is finished flag was set: " + String(vSetRoomBlockObj.Ref) + "'");
					WriteLogEvent(NStr("en='DataProcessor.ManageHasRoomBlocks';ru='Обработка.УправлениеФлагомЕстьБлокировкиНомерногоФонда';de='DataProcessor.ManageHasRoomBlocks'"), EventLogLevel.Information, ThisObject.Metadata(), vSetRoomBlockObj.Ref, vMessage);
					If pIsInteractive Then
						tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
					EndIf;
					vRoomBlockType = vSetRoomBlockObj.RoomBlockType;
					// Refresh room object
					vRoomObj.Read();
				Else
					vHasRoomBlocks = True;
				EndIf;
			EndDo;
			
			// Check should we update room's has room blocks flag
			vRoomBlocksHasChanged = False;
			If vRoomObj.HasRoomBlocks <> vHasRoomBlocks Then
				vRoomObj.HasRoomBlocks = vHasRoomBlocks;
				vRoomBlocksHasChanged = True;
			EndIf;
			
			// Check should we change room status
			vRoomStatusHasChanged = False;
			If Not vHasRoomBlocks And ValueIsFilled(vRoomBlockType) Then
				If vRoomBlockType.IsRoomRepair Then
					If ValueIsFilled(RoomStatusAfterRoomBlock) And ValueIsFilled(vRoomObj.RoomStatus) And 
					   vRoomObj.RoomStatus <> RoomStatusAfterRoomBlock And vRoomObj.RoomStatus = vRoomsRow.OutOfOrderRoomStatus Then
						vRoomObj.RoomStatus = RoomStatusAfterRoomBlock;
						vRoomStatusHasChanged = True;
					EndIf;
				Else
					If ValueIsFilled(vRoomBlockType.RoomStatusAtBlockEnd) And vRoomObj.RoomStatus <> vRoomBlockType.RoomStatusAtBlockEnd And 
					  (vRoomObj.RoomStatus = vRoomBlockType.RoomStatusAtBlockStart Or Not ValueIsFilled(vRoomBlockType.RoomStatusAtBlockStart)) Then
						vRoomObj.RoomStatus = vRoomBlockType.RoomStatusAtBlockEnd;
						vRoomStatusHasChanged = True;
					EndIf;
				EndIf;
			EndIf;
			
			// Check room type and other type attributes
			vRoomAttrsHasChanged = False;
			vRoomAttrs = vRoomObj.pmGetRoomAttributes(CurrentSessionDate());
			For Each vRoomAttrsRow In vRoomAttrs Do
				If vRoomObj.NumberOfBedsPerRoom <> vRoomAttrsRow.NumberOfBedsPerRoom Then
					vRoomObj.NumberOfBedsPerRoom = vRoomAttrsRow.NumberOfBedsPerRoom;
					vRoomAttrsHasChanged = True;
				EndIf;
				If vRoomObj.NumberOfPersonsPerRoom <> vRoomAttrsRow.NumberOfPersonsPerRoom Then
					vRoomObj.NumberOfPersonsPerRoom = vRoomAttrsRow.NumberOfPersonsPerRoom;
					vRoomAttrsHasChanged = True;
				EndIf;
				If vRoomObj.RoomType <> vRoomAttrsRow.RoomType Then
					vRoomObj.RoomType = vRoomAttrsRow.RoomType;
					vRoomAttrsHasChanged = True;
				EndIf;
				Break;
			EndDo;
			
			// Check should we update room's stop sale state
			vRoomStopSaleHasChanged = False;
			If vRoomObj.StopSale Then
				vStopSale = False;
				For Each vStopSalePeriod In vRoomObj.StopSalePeriods Do
					If vStopSalePeriod.StopSale Then
						If Not ValueIsFilled(vStopSalePeriod.PeriodFrom) And Not ValueIsFilled(vStopSalePeriod.PeriodTo) Then
							vStopSale = True;
							Break;
						ElsIf Not ValueIsFilled(vStopSalePeriod.PeriodFrom) And ValueIsFilled(vStopSalePeriod.PeriodTo) Then
							If vStopSalePeriod.PeriodTo > CurrentSessionDate() Then
								vStopSale = True;
								Break;
							EndIf;
						ElsIf ValueIsFilled(vStopSalePeriod.PeriodFrom) And Not ValueIsFilled(vStopSalePeriod.PeriodTo) Then
							vStopSale = True;
							Break;
						ElsIf ValueIsFilled(vStopSalePeriod.PeriodFrom) And ValueIsFilled(vStopSalePeriod.PeriodTo) Then
							If vStopSalePeriod.PeriodTo > CurrentSessionDate() Then
								vStopSale = True;
								Break;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				If vStopSale <> vRoomObj.StopSale Then
					vRoomObj.StopSale = vStopSale;
					vRoomStopSaleHasChanged = True;
				EndIf;
			EndIf;
			
			// Update room if necessary
			If vRoomBlocksHasChanged Or vRoomAttrsHasChanged Or vRoomStopSaleHasChanged Or vRoomStatusHasChanged Then
				vRoomObj.Write();
				
				// Update room status change history
				If vRoomStatusHasChanged Then
					// Add record to the room status change history
					vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, NStr("en='Automatically after room block end date';ru='Автоматически после завершения блокировки';de='Automatisch nach Beendigung der Blockierung'"));
				EndIf;
				
				// Log current state
				vMessage = "";
				If vRoomBlocksHasChanged Then
					If vRoomObj.HasRoomBlocks Then
						vMessage = NStr("ru = 'Установлен флаг наличия блокировок у номера: " + String(vRoomObj.Ref) + "'; 
						                |de = 'Room has room blocks flag set to true for the room: " + String(vRoomObj.Ref) + "'; 
										|en = 'Room has room blocks flag set to true for the room: " + String(vRoomObj.Ref) + "'");
					Else
						vMessage = NStr("ru = 'Сброшен флаг наличия блокировок у номера: " + String(vRoomObj.Ref) + "'; 
						                |de = 'Room has room blocks flag set to false for the room: " + String(vRoomObj.Ref) + "'; 
										|en = 'Room has room blocks flag set to false for the room: " + String(vRoomObj.Ref) + "'");
					EndIf;
					WriteLogEvent(NStr("en='DataProcessor.ManageHasRoomBlocks';ru='Обработка.УправлениеФлагомЕстьБлокировкиНомерногоФонда';de='DataProcessor.ManageHasRoomBlocks'"), EventLogLevel.Information, ThisObject.Metadata(), vRoomObj.Ref, vMessage);
					If pIsInteractive Then
						tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
					EndIf;
				EndIf;
				If vRoomAttrsHasChanged Then
					vMessage = NStr("ru = 'Изменены атрибуты номера: " + String(vRoomObj.Ref) + " -> " + String(vRoomObj.RoomType) + "'; 
					                |de = 'Room attributes has changed: " + String(vRoomObj.Ref) + " -> " + String(vRoomObj.RoomType) + "'; 
									|en = 'Room attributes has changed: " + String(vRoomObj.Ref) + " -> " + String(vRoomObj.RoomType) + "'");
					WriteLogEvent(NStr("en='DataProcessor.ManageHasRoomBlocks';ru='Обработка.УправлениеФлагомЕстьБлокировкиНомерногоФонда';de='DataProcessor.ManageHasRoomBlocks'"), EventLogLevel.Information, ThisObject.Metadata(), vRoomObj.Ref, vMessage);
					If pIsInteractive Then
						tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
					EndIf;
				EndIf;
				If vRoomStopSaleHasChanged Then
					vMessage = NStr("ru = 'Изменен флаг остановки продаж номера: " + String(vRoomObj.Ref) + " -> " + Format(vRoomObj.StopSale, "BF='Продажа разрешена'; BT='Продажа запрещена'") + "'; 
					                |de = 'Room stop sale flag has changed: " + String(vRoomObj.Ref) + " -> " + Format(vRoomObj.StopSale, "BF='Sale is permitted'; BT='Sale is stopped'") + "'; 
									|en = 'Room stop sale flag has changed: " + String(vRoomObj.Ref) + " -> " + Format(vRoomObj.StopSale, "BF='Sale is permitted'; BT='Sale is stopped'") + "'");
					WriteLogEvent(NStr("en='DataProcessor.ManageHasRoomBlocks';ru='Обработка.УправлениеФлагомЕстьБлокировкиНомерногоФонда';de='DataProcessor.ManageHasRoomBlocks'"), EventLogLevel.Information, ThisObject.Metadata(), vRoomObj.Ref, vMessage);
					If pIsInteractive Then
						tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
					EndIf;
				EndIf;
			EndIf;
			CommitTransaction();
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.ManageHasRoomBlocks';ru='Обработка.УправлениеФлагомЕстьБлокировкиНомерногоФонда';de='DataProcessor.ManageHasRoomBlocks'"), EventLogLevel.Warning, ThisObject.Metadata(), vRoomsRow.Room, vMessage);
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	
	// Get list of room types to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomTypes.Ref AS RoomType
	|FROM
	|	Catalog.RoomTypes AS RoomTypes
	|WHERE
	|	(NOT RoomTypes.DeletionMark)
	|	AND (NOT RoomTypes.IsFolder)
	|	AND (RoomTypes.Owner IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|ORDER BY
	|	RoomTypes.SortCode";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vRoomTypes = vQry.Execute().Unload();
	For Each vRoomTypesRow In vRoomTypes Do
		BeginTransaction(DataLockControlMode.Managed);
		Try
			vRoomTypeObj = vRoomTypesRow.RoomType.GetObject();
			// Check should we update room type's stop sale state
			vRoomTypeStopSaleHasChanged = False;
			If vRoomTypeObj.StopSale Then
				vStopSale = False;
				For Each vStopSalePeriod In vRoomTypeObj.StopSalePeriods Do
					If vStopSalePeriod.StopSale Or vStopSalePeriod.StopInternetSale Then
						If Not ValueIsFilled(vStopSalePeriod.PeriodFrom) And Not ValueIsFilled(vStopSalePeriod.PeriodTo) Then
							vStopSale = True;
							Break;
						ElsIf Not ValueIsFilled(vStopSalePeriod.PeriodFrom) And ValueIsFilled(vStopSalePeriod.PeriodTo) Then
							If vStopSalePeriod.PeriodTo > CurrentSessionDate() Then
								vStopSale = True;
								Break;
							EndIf;
						ElsIf ValueIsFilled(vStopSalePeriod.PeriodFrom) And Not ValueIsFilled(vStopSalePeriod.PeriodTo) Then
							vStopSale = True;
							Break;
						ElsIf ValueIsFilled(vStopSalePeriod.PeriodFrom) And ValueIsFilled(vStopSalePeriod.PeriodTo) Then
							If vStopSalePeriod.PeriodTo > CurrentSessionDate() Then
								vStopSale = True;
								Break;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				If vStopSale <> vRoomTypeObj.StopSale Then
					vRoomTypeObj.StopSale = vStopSale;
					vRoomTypeStopSaleHasChanged = True;
				EndIf;
			EndIf;
			
			// Update room if necessary
			If vRoomTypeStopSaleHasChanged Then
				vRoomTypeObj.Write();
				// Log current state
				vMessage = NStr("ru = 'Изменен флаг остановки продаж типа номера: " + String(vRoomTypeObj.Ref) + " -> " + Format(vRoomTypeObj.StopSale, "BF='Продажа разрешена'; BT='Продажа запрещена'") + "'; 
				                |de = 'Room type stop sale flag has changed: " + String(vRoomTypeObj.Ref) + " -> " + Format(vRoomTypeObj.StopSale, "BF='Sale is permitted'; BT='Sale is stopped'") + "'; 
								|en = 'Room type stop sale flag has changed: " + String(vRoomTypeObj.Ref) + " -> " + Format(vRoomTypeObj.StopSale, "BF='Sale is permitted'; BT='Sale is stopped'") + "'");
				WriteLogEvent(NStr("en='DataProcessor.ManageHasRoomBlocks';ru='Обработка.УправлениеФлагомЕстьБлокировкиНомерногоФонда';de='DataProcessor.ManageHasRoomBlocks'"), EventLogLevel.Information, ThisObject.Metadata(), vRoomTypeObj.Ref, vMessage);
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
				EndIf;
			EndIf;
			CommitTransaction();
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.ManageHasRoomBlocks';ru='Обработка.УправлениеФлагомЕстьБлокировкиНомерногоФонда';de='DataProcessor.ManageHasRoomBlocks'"), EventLogLevel.Warning, ThisObject.Metadata(), vRoomTypesRow.RoomType, vMessage);
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Else
				Raise vMessage;
			EndIf;
		EndTry;
	EndDo;
	WriteLogEvent(NStr("en='DataProcessor.ManageHasRoomBlocks';ru='Обработка.УправлениеФлагомЕстьБлокировкиНомерногоФонда';de='DataProcessor.ManageHasRoomBlocks'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmManageHasRoomBlocks
