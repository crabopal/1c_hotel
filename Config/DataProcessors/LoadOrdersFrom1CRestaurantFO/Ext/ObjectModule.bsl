
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
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(DataExchangeFileCurrency) Then
			DataExchangeFileCurrency = Hotel.BaseCurrency;
		EndIf;
		If Not ValueIsFilled(Service) Then
			Service = Hotel.CateringService;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Load restaurant orders
	pmLoadOrders(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure pmLoadOrders(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFrom1CRestaurantFO'; de='DataProcessor.LoadOrdersFrom1CRestaurantFO'; ru='Обработка.ЗагрузкаЗаказовРесторанаИз1СФО'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Check parameters
	If IsBlankString(DataExchangeFile) Then
		vMessage = NStr("ru = 'Не указан файл обмена данными!'; 
		                |de = 'Data exchange file is not set up!'; 
						|en = 'Data exchange file is not set up!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFrom1CRestaurantFO'; de='DataProcessor.LoadOrdersFrom1CRestaurantFO'; ru='Обработка.ЗагрузкаЗаказовРесторанаИз1СФО'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If Not ValueIsFilled(Service) Then
		vMessage = NStr("ru = 'Не указана услуга!'; 
		                |de = 'Service is not set up!'; 
						|en = 'Service is not set up!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFrom1CRestaurantFO'; de='DataProcessor.LoadOrdersFrom1CRestaurantFO'; ru='Обработка.ЗагрузкаЗаказовРесторанаИз1СФО'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If Not ValueIsFilled(DataExchangeFileCurrency) Then
		vMessage = NStr("ru = 'Не указана валюта файла обмена!'; 
		                |de = 'Data exchange file currency is not set up!';
						|en = 'Data exchange file currency is not set up!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFrom1CRestaurantFO'; de='DataProcessor.LoadOrdersFrom1CRestaurantFO'; ru='Обработка.ЗагрузкаЗаказовРесторанаИз1СФО'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	vOrdersFile = New File(TrimAll(DataExchangeFile));
	If Not tcCommonFunctionOnClientServer.cmExists(vOrdersFile) Then
		vMessage = NStr("ru = 'Файл с выгруженными заказами ресторана не найден!'; 
						|en = 'Data exchange file with exported restaurant orders is not found!';
						|de = 'Data exchange file with exported restaurant orders is not found!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFrom1CRestaurantFO'; de='DataProcessor.LoadOrdersFrom1CRestaurantFO'; ru='Обработка.ЗагрузкаЗаказовРесторанаИз1СФО'"), EventLogLevel.Note, ThisObject.Metadata(), Undefined, vMessage);
		Return;
	EndIf;
	
	// Rename data exchange file to lock it from external change
	vDataExchangeFile = GetTempDataExchangeFileName(DataExchangeFile);
	vFileIsNotMoved = True;
	While vFileIsNotMoved Do
		Try
			MoveFile(DataExchangeFile, vDataExchangeFile);
			vFileIsNotMoved = False;
		Except
			// Wait some time
			i = 0;
			While i < 50000 Do
				i = i + 1;
			EndDo;
			
			// Check user interrupt processing
			If pIsInteractive Then
				#IF CLIENT THEN
					UserInterruptProcessing();
				#ENDIF
			EndIf;
		EndTry;
	EndDo;

	// Begin transaction if running on server
	If Not pIsInteractive Then
		BeginTransaction(DataLockControlMode.Managed);
	EndIf;
	
	// Open orders file
	vCount = 0;
	vOrders = New XBase();
	vOrders.Encoding = GetXBaseEncoding(DataExchangeFileEncoding);
	vOrders.ShowDeleted = False;
	vOrders.OpenFile(TrimAll(vDataExchangeFile), , True);
	If vOrders.First() Then
		While Not vOrders.EOF() Do
			Try
				vCount = vCount + 1;
				
				// Parse orders fields
				vOrderNumber = TrimAll(vOrders.NUMDOC);
				vOrderTime = Date(vOrders.DATE);
				vOrderTime = AddTime(vOrderTime, vOrders.TIME);
				vOrderCardCode = TrimAll(vOrders.CODECARD);
				vOrderCardID = TrimAll(vOrders.IDCARD);
				vOrderPlace = TrimAll(vOrders.NAMEREST);
				vOrderTable = TrimAll(vOrders.NUMPLACE);
				vOrderAuthor = TrimAll(vOrders.TNOFIC);
				
				vOrderSum = Number(vOrders.SUMBN);
				vOrderCashSum = Number(vOrders.SUMNAL);
				vOrderCreditSum = Number(vOrders.SUMCREDIT);
				vOrderNoPaymentSum = Number(vOrders.SUMNEPLAT);
				
				vOrderData = NStr("ru = 'Заказ №'; en = 'Order N'; de = 'Bestellung Nr.'") + vOrderNumber + NStr("en=' on ';ru=' от ';de=' vom '") + vOrderTime + " - " + vOrderPlace + NStr("ru = ', стол '; en = ', table '; de = ', Tisch '") + vOrderTable + " - " + vOrderAuthor;
				
				// Take room number description from the card code
				vRoomDescription = vOrderCardCode;
				// Take room code from the table number
				vRoomCode = vOrderTable;
				
				// Load order sum only
				If vOrderSum <> 0 Then
					// Check if room is filled
					vSkipLoading = False;
					vRoomRef = Catalogs.Rooms.EmptyRef();
					If Not IsBlankString(vRoomDescription) Or Not IsBlankString(vRoomCode) Then
						If Not IsBlankString(vRoomCode) Then
							vRoomRef = Catalogs.Rooms.FindByDescription(vRoomCode, True, , Hotel);
						EndIf;
						If Not ValueIsFilled(vRoomRef) Then
							If Not IsBlankString(vRoomDescription) Then
								vRoomRef = Catalogs.Rooms.FindByDescription(vRoomDescription, True, , Hotel);
							EndIf;
						EndIf;
						If Not ValueIsFilled(vRoomRef) Then
							// Skip this order cause this order do not have reference to the room
							vSkipLoading = True;
							
							vMessage= NStr("ru = 'Пропущен заказ на стол '; en = 'Skip loading order from table '; de = 'Skip loading order from table '") + vOrderTable + "!" + Chars.LF + vOrderData;
							WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFrom1CRestaurantFO'; de='DataProcessor.LoadOrdersFrom1CRestaurantFO'; ru='Обработка.ЗагрузкаЗаказовРесторанаИз1СФО'"), EventLogLevel.Note, ThisObject.Metadata(), , vMessage);
							If pIsInteractive Then
								tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Important);
							EndIf;
						EndIf;
					Else
						// Skip this order cause this order do not have reference to the room
						vSkipLoading = True;
						
						vMessage= NStr("ru = 'Пропущен заказ без указания стола!'; en = 'Skip loading order without table!'; de = 'Skip loading order without table!'") + Chars.LF + vOrderData;
						WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFrom1CRestaurantFO'; de='DataProcessor.LoadOrdersFrom1CRestaurantFO'; ru='Обработка.ЗагрузкаЗаказовРесторанаИз1СФО'"), EventLogLevel.Note, ThisObject.Metadata(), , vMessage);
						If pIsInteractive Then
							tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Important);
						EndIf;
					EndIf;
					
					// Try to create interface document
					If Not vSkipLoading Then
						WriteOrder(vRoomRef, vOrderTime, vOrderSum, vOrderAuthor, vOrderData, pIsInteractive);
					EndIf;
				EndIf;
			Except
				vMessage = ErrorDescription();
				WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFrom1CRestaurantFO'; de='DataProcessor.LoadOrdersFrom1CRestaurantFO'; ru='Обработка.ЗагрузкаЗаказовРесторанаИз1СФО'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
				
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				Else
					// Rollback transaction if running on server
					RollbackTransaction();
					
					// Rename file back
					If vOrders.IsOpen() Then
						vOrders.CloseFile();
					EndIf;
					MoveFile(vDataExchangeFile, DataExchangeFile);
					
					Raise vMessage;
				EndIf;
			EndTry;
			
			// Go to the previous record
			vOrders.Next();
			
			// Check user interrupt processing
			If pIsInteractive Then
				#IF CLIENT THEN
					UserInterruptProcessing();
				#ENDIF
			EndIf;
		EndDo;
	EndIf;
						
	If vOrders.IsOpen() Then
		vOrders.CloseFile();
	EndIf;
	
	// Commit transaction if running on server
	If Not pIsInteractive Then
		CommitTransaction();
	EndIf;
	
	// Move export file to the history catalog
	If Not IsBlankString(HistoryCatalog) Then
		If NumberOfFilesInHistory > 0 Then
			vHistoryDataExchangeFile = GetHistoryDataExchangeFileName(DataExchangeFile);
			MoveFile(vDataExchangeFile, vHistoryDataExchangeFile);
			// Delete old files
			vFilesArray = FindFiles(TrimAll(HistoryCatalog), "*.dbf");
			If vFilesArray.Count() > 0 Then
				vFilesList = New ValueList();
				For Each vFile In vFilesArray Do
					vFileItem = vFilesList.Add(vFile, vFile.Name);
				EndDo;
				vFilesList.SortByPresentation(SortDirection.Asc);
				While vFilesList.Count() > NumberOfFilesInHistory Do
					vFileItem = vFilesList.Get(0);
					DeleteFiles(vFileItem.Value.FullName);
					vFilesList.Delete(0);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	// Log that processing is finished
	WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFrom1CRestaurantFO'; de='DataProcessor.LoadOrdersFrom1CRestaurantFO'; ru='Обработка.ЗагрузкаЗаказовРесторанаИз1СФО'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("ru = 'Конец выполнения процедуры загрузки заказов ресторана. Загружено " + vCount + " записей.'; en = 'End of loading orders. " + vCount + " orders were loaded.'; de = 'End of loading orders. " + vCount + " orders were loaded.'"));
EndProcedure // pmLoadOrders

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function AddTime(pDate, pTime)
	vHours = Number(Left(pTime, 2));
	vMinutes = Number(Mid(pTime, 4, 2));
	vSeconds = Number(Right(pTime, 2));
	Return BegOfday(pDate) + vHours*3600 + vMinutes*60 + vSeconds;
EndFunction // AddTime

// -----------------------------------------------------------------------------
Function GetTempDataExchangeFileName(pDataExchangeFile)
	vExt = Right(TrimR(pDataExchangeFile), 4);
	vLeft = Left(pDataExchangeFile, StrLen(TrimR(pDataExchangeFile))-4);
	Return vLeft + "~" + vExt;
EndFunction // GetTempDataExchangeFileName

// -----------------------------------------------------------------------------
Function GetHistoryDataExchangeFileName(pDataExchangeFile)
	vFile = New File(pDataExchangeFile);
	vFileName = TrimAll(vFile.BaseName);
	vExt = Right(pDataExchangeFile, 4);
	vHistoryCatalog = TrimAll(HistoryCatalog);
	If Right(vHistoryCatalog, 1) <> "\" And Right(vHistoryCatalog, 1) <> "/" Then
		vHistoryCatalog = vHistoryCatalog + "\";
	EndIf;
	Return vHistoryCatalog + vFileName + "_" + Format(CurrentSessionDate(), "DF=yyyyMMddHHmmss") + vExt;
EndFunction // GetHistoryDataExchangeFileName

// -----------------------------------------------------------------------------
Function GetXBaseEncoding(pDataExchangeFileEncoding)
	If pDataExchangeFileEncoding = Enums.FileEncoding.OEM Then
		Return XBaseEncoding.OEM;
	Else
		Return XBaseEncoding.ANSI;
	EndIf;
EndFunction // GetXBaseEncoding

// -----------------------------------------------------------------------------
Procedure WriteOrder(pRoom, pOrderTime, pOrderSum, pOrderAuthor, pOrderData, pIsInteractive)
	// Create new interface document object
	vRoomServiceObj = Documents.RecordRoomService.CreateDocument();
	vRoomServiceObj.Hotel = Hotel;
	vRoomServiceObj.pmFillAuthorAndDate();
	vRoomServiceObj.SetNewNumber();
	vRoomServiceObj.pmFillAttributesWithDefaultValues();
	
	// Fill order sum
	vRoomServiceObj.RoomService = Service;
	vRoomServiceObj.Unit = Service.Unit;
	vRoomServiceObj.RoomServiceChargeType = NStr("en='Restaurant';ru='Ресторан';de='Restaurant'");
	vRoomServiceObj.Price = pOrderSum;
	vRoomServiceObj.Quantity = 1;
	vRoomServiceObj.Sum = pOrderSum;
	
	// Fill currency attributes
	vRoomServiceObj.Currency = DataExchangeFileCurrency;
	vRoomServiceObj.CurrencyExchangeRate = cmGetCurrencyExchangeRate(vRoomServiceObj.Hotel, vRoomServiceObj.Currency, vRoomServiceObj.ExchangeRateDate);
	
	// Fill call attributes
	vRoomServiceObj.ServiceDate = pOrderTime;
	
	// Try to find folio to charge to
	vRoomServiceObj.Room = pRoom;
	If ValueIsFilled(vRoomServiceObj.Room) Then
		If ValueIsFilled(vRoomServiceObj.Room.Company) Then
			vRoomServiceObj.Company = vRoomServiceObj.Room.Company;
			If Not ValueIsFilled(vRoomServiceObj.RoomService) Then
				vRoomServiceObj.VATRate = vRoomServiceObj.Company.VATRate;
			EndIf;
			If Not ValueIsFilled(vRoomServiceObj.FixedService) Then
				vRoomServiceObj.FixedServiceVATRate = vRoomServiceObj.Company.VATRate;
			EndIf;
		EndIf;
		vRoomServiceObj.Folio = vRoomServiceObj.pmGetFolioToChargeTo();
	EndIf;
	
	// Try to find active room folio
	If Not ValueIsFilled(vRoomServiceObj.Folio) Then
		vFolios = cmGetActiveRoomFolios(Hotel, vRoomServiceObj.Room, Hotel.FolioCurrency);
		If vFolios.Count() > 0 Then
			vRow = vFolios.Get(0);
			vRoomServiceObj.Folio = vRow.Folio;
		EndIf;
	EndIf;
	// Create new empty one
	If Not ValueIsFilled(vRoomServiceObj.Folio) Then
		vFolioObj = Documents.Folio.CreateDocument();
		vFolioObj.Hotel = Hotel;
		vFolioObj.pmFillAttributesWithDefaultValues();
		vFolioObj.Room = vRoomServiceObj.Room;
		vFolioObj.Description = NStr("en='Restaurant orders on vacant rooms';ru='Заказы ресторана на свободные номера';de='Restaurantbestellungen auf freie Plätze'");
		vFolioObj.Write(DocumentWriteMode.Write);
		
		vRoomServiceObj.Folio = vFolioObj.Ref;
		
		vMessage = NStr("ru = 'Создано фолио: " + String(vRoomServiceObj.Folio) + "'; 
		                |de = 'Folio " + String(vRoomServiceObj.Folio) + " was created'; 
						|en = 'Folio " + String(vRoomServiceObj.Folio) + " was created'");
		WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFrom1CRestaurantFO'; de='DataProcessor.LoadOrdersFrom1CRestaurantFO'; ru='Обработка.ЗагрузкаЗаказовРесторанаИз1СФО'"), EventLogLevel.Note, vRoomServiceObj.Folio.Metadata(), vRoomServiceObj.Folio, vMessage);
	EndIf;
	
	// Process folio
	vRoomServiceObj.pmFillByFolio();
	vRoomServiceObj.pmRecalculateSums();
	
	// Fill remarks
	vRoomServiceObj.Remarks = pOrderData;
	
	// Post current document
	vRoomServiceObj.Write(DocumentWriteMode.Posting);
				
	// Log current state
	vMessage = NStr("ru = 'Создан документ: " + String(vRoomServiceObj.Ref) + "'; 
	                |de = 'Document " + String(vRoomServiceObj.Ref) + " was created'; 
					|en = 'Document " + String(vRoomServiceObj.Ref) + " was created'") + Chars.LF + pOrderData;
	WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFrom1CRestaurantFO'; de='DataProcessor.LoadOrdersFrom1CRestaurantFO'; ru='Обработка.ЗагрузкаЗаказовРесторанаИз1СФО'"), EventLogLevel.Information, ThisObject.Metadata(), vRoomServiceObj.Ref, vMessage);
	If pIsInteractive Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
	Endif;
EndProcedure // WriteOrder

#EndRegion

