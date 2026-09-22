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
			RoomRate = Hotel.RoomRate;
		EndIf;
		OutputRoomsVacant = True;
		OutputBedsVacant = False;
		OutputRoomsInQuota = False;
		OutputBedsInQuota = False;
		OutputRoomsChargedInQuota = False;
		OutputBedsChargedInQuota = False;
		OutputRoomsReserved = False;
		OutputBedsReserved = False;
		OutputInHouseRooms = False;
		OutputInHouseBeds = False;
		OutputRoomsRemains = False;
		OutputBedsRemains = False;
	EndIf;
	If Not ValueIsFilled(Language) And ValueIsFilled(Hotel) Then
		Language = Hotel.Language;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = CurrentSessionDate();
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfDay(CurrentSessionDate()) + 24*3600*30;
	EndIf;
	If FTPPort = 0 Then
		FTPPort = 21;
		UseZip = True;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Do data exchange
	pmDoExport(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmDoExport(pIsInteractive = False) Export
	// Log processing start
	WriteLogEvent(NStr("en='DataProcessor.ExportRoomInventoryBalances';ru='Обработка.ВыполнитьВыгрузкуОстатковСвободныхНомеров';de='DataProcessor.ExportRoomInventoryBalances'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	
	// Check parameters
	If Not ValueIsFilled(PeriodFrom) Then
		vMessage = NStr("ru='Не указано начало периода выгрузки!';
		                |de='Der Beginn des Auslagerungszeitraums ist nicht angegeben!'; 
						|en='Period from is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.ExportRoomInventoryBalances';ru='Обработка.ВыполнитьВыгрузкуОстатковСвободныхНомеров';de='DataProcessor.ExportRoomInventoryBalances'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		vMessage = NStr("ru='Не указано окончание периода выгрузки!';
		                |de='Das Ende des Auslagerungszeitraums ist nicht angegeben!';
						|en='Period to is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.ExportRoomInventoryBalances';ru='Обработка.ВыполнитьВыгрузкуОстатковСвободныхНомеров';de='DataProcessor.ExportRoomInventoryBalances'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		vMessage = NStr("ru='Не указана гостиница!';
		                |de='Das Hotel ist nicht angegeben!'; 
						|en='Hotel is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.ExportRoomInventoryBalances';ru='Обработка.ВыполнитьВыгрузкуОстатковСвободныхНомеров';de='DataProcessor.ExportRoomInventoryBalances'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If IsBlankString(Path) Then
		vMessage = NStr("ru='Не указан путь к файлу выгрузки!';
		                |de='Der Pfad zur Auslagerungsdatei ist nicht angegeben!';
						|en='Export file path is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.ExportRoomInventoryBalances';ru='Обработка.ВыполнитьВыгрузкуОстатковСвободныхНомеров';de='DataProcessor.ExportRoomInventoryBalances'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	
	// Get string parameters presentations
	vHotelCode = ?(ValueIsFilled(Hotel), TrimAll(Hotel.Code), "");
	vHotelDescription = ?(ValueIsFilled(Hotel), TrimAll(Hotel.Description), "");
	vRoomTypeCode = ?(ValueIsFilled(RoomType), TrimAll(RoomType.Code), "");
	vRoomQuotaCode = ?(ValueIsFilled(RoomQuota), TrimAll(RoomQuota.Code), "");
	vRoomRateCode = ?(ValueIsFilled(RoomRate), TrimAll(RoomRate.Code), "");
	vClientTypeCode = ?(ValueIsFilled(ClientType), TrimAll(ClientType.Code), "");
	vLanguageCode = ?(ValueIsFilled(Language), TrimAll(Language.Code), "");
	
	// Get temporal directory path and initialize file name
	vTempDirPath = TrimAll(TempFilesDir());
	vTempDirPath = StrReplace(vTempDirPath, "\", "/");
	If Right(vTempDirPath, 1) <> "/" Then
		vTempDirPath = vTempDirPath + "/";
	EndIf;
	vFileName = "RIBalances_" + vHotelCode + "_" + vLanguageCode;
	vFilePath = vTempDirPath;
	
	// Check path to write data to
	vTargetAddress = StrReplace(TrimAll(Path), "\", "/");
	If Right(vTargetAddress, 1) <> "/" Then
		vTargetAddress = vTargetAddress + "/";
	EndIf;
	
	// Call API to get XML with balances
	vXMLWriter = New XMLWriter();
	vXMLWriter.OpenFile(vFilePath + vFileName + ".xml");
	vXMLWriter.WriteXMLDeclaration();
	If Not OutputVacantCheckInPeriodsOnly Then
		vXDTOBalances = cmGetRoomInventoryBalance(vHotelDescription, vRoomTypeCode, "", "", "", vRoomQuotaCode, 
		                                          PeriodFrom, PeriodTo, vRoomRateCode, vClientTypeCode,
		                                          OutputRoomsVacant, OutputBedsVacant, OutputRoomsRemains, OutputBedsRemains, 
		                                          OutputRoomsInQuota, OutputBedsInQuota, OutputRoomsChargedInQuota, OutputBedsChargedInQuota, 
		                                          OutputRoomsReserved, OutputBedsReserved, OutputInHouseRooms, OutputInHouseBeds, 
		                                          ExternalSystemCode, vLanguageCode, "XML", vXMLWriter);
	Else
		vXDTOBalances = cmGetVacantCheckInPeriods(vHotelDescription, vRoomRateCode, vRoomTypeCode, "", "", "", vRoomQuotaCode, 
		                                          PeriodFrom, PeriodTo,
		                                          ExternalSystemCode, vLanguageCode, "XML", vXMLWriter);
	EndIf;
	vXMLWriter.Close();
	
	// Zip file with changes if necessary
	If UseZip Then
		vArchive = New ZipFileWriter(vFilePath + vFileName + ".zip", ZipPwd, , ZIPCompressionMethod.Deflate, ZIPCompressionLevel.Maximum, ZIPEncryptionMethod.AES256);
		vArchive.Add(vFilePath + vFileName + ".xml", ZIPStorePathMode.DontStorePath);
		vArchive.Write();
	EndIf;
	
	// Build file name to be used further
	vExchangeFileName = vFileName + ?(UseZip, ".zip", ".xml");
	
	// Copy file to the FTP or file target directory
	If Not IsBlankString(vTargetAddress) Then
		If UseFTP Then
			vFTPServer = Undefined;
			vProxy = cmGetInternetProxy(InternetConnectionSettings, False, TrimAll(FTPAddress));
			If vProxy <> Undefined Then
			    vFTPServer = New FTPConnection(TrimAll(FTPAddress), FTPPort, FTPUser, FTPPwd, vProxy, UsePassiveMode, FTPConnectionTimeout);
			Else
			    vFTPServer = New FTPConnection(TrimAll(FTPAddress), FTPPort, FTPUser, FTPPwd, , UsePassiveMode, FTPConnectionTimeout);
			EndIf;
			vFTPServer.Put(vFilePath + vExchangeFileName, vTargetAddress + vExchangeFileName);
		Else
			FileCopy(vFilePath + vExchangeFileName, vTargetAddress + vExchangeFileName);
		EndIf;
	EndIf;
	
	// Delete temp files
	DeleteFiles(vFilePath + vFileName + ".xml");
	If UseZip Then
		DeleteFiles(vFilePath + vFileName + ".zip");
	EndIf;
	
	// Log end of processing
	WriteLogEvent(NStr("en='DataProcessor.ExportRoomInventoryBalances';ru='Обработка.ВыполнитьВыгрузкуОстатковСвободныхНомеров';de='DataProcessor.ExportRoomInventoryBalances'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmDoExchange
