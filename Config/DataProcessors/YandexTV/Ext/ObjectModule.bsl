
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameter
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	pmFillAttributesWithDefaultValues();
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	
	// Fill attributes	
	
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter		 - Structure - Parameter
//  pIsInteractive	 - Boolean	 - Is interactive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export 
	If Not ValueIsFilled(InteractionParameters) Then  
		vErr = Nstr("en = 'No integration specified, no processing possible.'; 
					|de = 'Keine Integration angegeben, keine Verarbeitung möglich.'; 
					|ru = 'Не указана интеграция, выполнение обработки не возможно.'");
		Raise vErr; 
	EndIf;
	
	rIsErrors = False;
	If Type = 1 Then
		DoMakeFile(rIsErrors);
	Else
		CallAPI(rIsErrors);
	EndIf;
	
	If Not rIsErrors Then
		vIntPObj = InteractionParameters.GetObject();
		vIntPObj.SessionLastActivityTime = CurrentSessionDate();
		vIntPObj.Write();
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure DoMakeFile(rIsErrors)
	
	Try     
		// Get rooms
		vRooms = GetAvailableRooms();
		
		vArrRooms = vRooms.Unloadcolumn("RoomCode");
		vRowRooms = StrConcat(vArrRooms,",");
		
		// Write file
		vFileName = Base64String(GetBinaryDataFromString(TrimAll(InteractionParameters.InteractionID))) + ".csv"; 
		vFullFilName = TempFilesDir() + "\" + vFileName;
		vTextWriter = New TextWriter(vFullFilName, TextEncoding.UTF8); 
		vTextWriter.WriteLine(vRowRooms);  
		vTextWriter.Close();
		
		// Send e-mail
		vSubject = "RoomInformation";  
		vHTMLText = "";
		vParamsEmail = InteractionParameters.EmailAccount;  
		vAttachments = New Map; 
		vAttachments.Insert(vFileName, vFullFilName); 
		vToEMail = StrSplit(TrimAll(InteractionParameters.WSHost), ";");
		EMail.Send(vParamsEmail, vParamsEmail.Description, TrimAll(vParamsEmail.EMail), vSubject, vHTMLText, , , , , , , vAttachments, vToEMail, , , , , , , , True);
		
		If InteractionParameters.DebugMode Then
			// Write log
			vLogParams = New Structure;
			vLogParams.Insert("Hotel", InteractionParameters.Hotel);
			vLogParams.Insert("DateFrom", CurrentSessionDate());
			vLogParams.Insert("DateTo", CurrentSessionDate()+2);
			vLogParams.Insert("RoomQuota", InteractionParameters.Allotment);
			vLogParams.Insert("FullFilName", vFullFilName);
			vLogParams.Insert("Rooms", vRowRooms);
			vLogParams.Insert("EmailAccount", vParamsEmail);
			vLogParams.Insert("Recipient", TrimAll(InteractionParameters.WSHost));   
			vLogParams.Insert("Token", TrimAll(InteractionParameters.InteractionID));   
			vJson = Catalogs.DataConvertationRules.MapToJSON(vLogParams);  
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "YandexTV.DoMakeFile", Enums.ExternalSystemEventTypes.Info, , vJson);
		EndIf;	
	Except
		vErr = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "YandexTV.Error",
		Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error");
		rIsErrors = True;
	EndTry;

EndProcedure // DoMakeFile()

// -----------------------------------------------------------------------------
Procedure CallAPI(rIsErrors)
	
	// 1. Change status for active operations 
	DoProcessActiveOperations(rIsErrors);         
	
	// 2. Reset check-out stations
	DoResetStations(rIsErrors);
	
EndProcedure // CallAPI()  

// -----------------------------------------------------------------------------
Procedure DoProcessActiveOperations(rIsErrors)
	
	vErrStatus = Nstr("en = 'Runtime error'; de = 'Laufzeit Fehler'; ru = 'Ошибка выполнения'");
	
	vQuery = New Query;
	vQuery.Text = "SELECT
	              |	RoomInterfaceStatus.Ref AS Ref
	              |FROM
	              |	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	              |WHERE
	              |	RoomInterfaceStatus.DeletionMark = FALSE
	              |	AND RoomInterfaceStatus.IsProcessed = FALSE
	              |	AND RoomInterfaceStatus.IsCanceled = FALSE
	              |	AND RoomInterfaceStatus.RoomInterfaceType.ExternalSystem = &qExternalSystem
	              |	AND RoomInterfaceStatus.Room.IsUseYandexInterface";
	
	// Setting parameter values
	vQuery.SetParameter("qExternalSystem", InteractionParameters);

	vResult = vQuery.Execute();
	If Not vResult.IsEmpty() Then
		vSel = vResult.Select(); 
		If InteractionParameters.DebugMode Then      
			vMsg = Nstr("en = 'Count rows %1'; de = 'Zeilenanzahl: %1'; ru = 'Количество документов: %1'");
			// Write log
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "YandexTV.DoProcessActiveOperations", Enums.ExternalSystemEventTypes.Info, , , StrTemplate(vMsg, vSel.Count()));
		EndIf;
		While vSel.Next() Do    
			Try 
				vDocObj = vSel.Ref.GetObject();
				vDocObj.IsProcessed = True;
				vDocObj.Write(DocumentWriteMode.Write);	   
			Except
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "YandexTV.DoProcessActiveOperations", Enums.ExternalSystemEventTypes.Error, , ErrorDescription(), vErrStatus);
				rIsErrors = True;	
			EndTry;
		EndDo;   
	Else
		If InteractionParameters.DebugMode Then      
			vMsg = Nstr("en = 'No data to process'; de = 'Keine zu verarbeitenden Daten'; ru = 'Нет данных для обработки'");
			// Write log
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "YandexTV.DoProcessActiveOperations", Enums.ExternalSystemEventTypes.Info, , , vMsg);
		EndIf;	
	EndIf;
EndProcedure // DoProcessActiveOperations()

// -----------------------------------------------------------------------------
Procedure DoResetStations(rIsErrors)
	vFuncName = "YandexTV.DoResetStations";
	vErrStatus = Nstr("en = 'Runtime error'; de = 'Laufzeit Fehler'; ru = 'Ошибка выполнения'");  
	
	vRequestHeaders = New Structure;
	vRequestHeaders.Insert("Authorization", "OAuth " + InteractionParameters.OAuth_AccessToken);
	
	vQuery = New Query;
	
	vQuery.Text = "SELECT
	              |	RoomInterfaceStatus.Ref AS Ref,
	              |	RoomInterfaceStatus.Room.Description AS Room,
	              |	RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters AS TurnOnParameters,
	              |	RoomInterfaceStatus.RoomInterfaceType.TurnOffParameters AS TurnOffParameters,
	              |	RoomInterfaceStatus.Room.YandexCode AS YandexCode
	              |FROM
	              |	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	              |WHERE
	              |	RoomInterfaceStatus.DeletionMark = FALSE
	              |	AND RoomInterfaceStatus.IsCanceled = TRUE
	              |	AND RoomInterfaceStatus.RoomInterfaceType.ExternalSystem = &qExternalSystem
	              |	AND RoomInterfaceStatus.Room <> VALUE(Catalog.Rooms.EmptyRef)
	              |	AND RoomInterfaceStatus.Room.IsUseYandexInterface";
	
	// Setting parameter values
	vQuery.SetParameter("qExternalSystem", InteractionParameters);
	
	vResult = vQuery.Execute();
	If Not vResult.IsEmpty() Then
		vSel = vResult.Select(); 
		If InteractionParameters.DebugMode Then      
			vMsg = Nstr("en = 'Count rows %1'; de = 'Zeilenanzahl: %1'; ru = 'Количество документов: %1'");
			// Write log
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, vFuncName, Enums.ExternalSystemEventTypes.Info, , , StrTemplate(vMsg, vSel.Count()));
		EndIf;
		While vSel.Next() Do    
			Try      
				vRoomExtCode = TrimAll(vSel.YandexCode);
				If IsBlankString(vRoomExtCode) Then
					vRoomExtCode = TrimAll(vSel.Room);	
				EndIf;	
				vReqBody = Catalogs.DataConvertationRules.MapToJSON(New Structure("external_room_id", vRoomExtCode));
				
				vResponse = Catalogs.ExternalSystemInteractions.SendHTTPRequest(InteractionParameters, vRequestHeaders, TrimAll(vSel.TurnOffParameters), "POST", , vReqBody, "JSON");
				vDocObj = vSel.Ref.GetObject();
				If vResponse.StatusCode = 201 Then  
					vDocObj.SetDeletionMark(True);
				Else   
					vResponseMap 		= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);  
					vDocObj.ErrorMessage = vResponseMap.error.message;    
					vDocObj.Write();
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, vFuncName, Enums.ExternalSystemEventTypes.Error, vReqBody, vResponse.Body, vErrStatus); 
				EndIf;
			Except
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, vFuncName, Enums.ExternalSystemEventTypes.Error, vReqBody, ErrorDescription(), vErrStatus);
				rIsErrors = True;	
			EndTry;
		EndDo;   
	Else
		If InteractionParameters.DebugMode Then      
			vMsg = Nstr("en = 'No data to process'; de = 'Keine zu verarbeitenden Daten'; ru = 'Нет данных для обработки'");
			// Write log
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, vFuncName, Enums.ExternalSystemEventTypes.Info, , , vMsg);
		EndIf;	
	EndIf;

EndProcedure // DoResetStations()

// -----------------------------------------------------------------------------
Function GetAvailableRooms()
	
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Rooms.Room AS Room,
	|	Rooms.Room.Description AS RoomCode,
	|	Rooms.Room.SortCode AS SortCode,
	|	Rooms.RoomType AS RoomType,
	|	Rooms.Room.RoomStatus AS RoomStatus,
	|	Rooms.TotalBeds AS TotalBeds,
	|	Rooms.TotalRooms AS TotalRooms,
	|	Rooms.RoomsVacant AS RoomsVacant,
	|	CASE
	|		WHEN RoomsStopSales.RoomsStopSale IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS StopSale,
	|	CASE
	|		WHEN RoomTypesStopSales.RoomTypesStopSale IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RoomTypeStopSale
	|FROM
	|	(SELECT
	|		RoomBalance.Room AS Room,
	|		RoomBalance.RoomType AS RoomType,
	|		MAX(RoomBalance.TotalBeds) AS TotalBeds,
	|		MAX(RoomBalance.TotalRooms) AS TotalRooms,
	|		MAX(RoomBalance.BedsVacant) AS BedsVacant,
	|		MAX(RoomBalance.RoomsVacant) AS RoomsVacant
	|	FROM
	|		(SELECT
	|			RoomInventoryBalance.Room AS Room,
	|			RoomInventoryBalance.RoomType AS RoomType,
	|			MIN(RoomInventoryBalance.CounterClosingBalance) AS CounterClosingBalance,
	|			MIN(RoomInventoryBalance.TotalBedsClosingBalance) AS TotalBeds,
	|			MIN(RoomInventoryBalance.TotalRoomsClosingBalance) AS TotalRooms,
	|			MIN(RoomInventoryBalance.BedsVacantClosingBalance) AS BedsVacant,
	|			MIN(RoomInventoryBalance.RoomsVacantClosingBalance) AS RoomsVacant
	|		FROM
	|			AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|					&qDateFrom,
	|					&qDateTo,
	|					Second,
	|					RegisterRecordsAndPeriodBoundaries,
	|					(&qHotelIsFilled
	|							AND Hotel IN HIERARCHY (&qHotel)
	|						OR NOT &qHotelIsFilled)) AS RoomInventoryBalance
	|		
	|		GROUP BY
	|			RoomInventoryBalance.Room,
	|			RoomInventoryBalance.RoomType
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomQuotaSalesBalance.Room,
	|			RoomQuotaSalesBalance.RoomType,
	|			MIN(RoomQuotaSalesBalance.CounterClosingBalance),
	|			MIN(RoomQuotaSalesBalance.BedsInQuotaClosingBalance),
	|			MIN(RoomQuotaSalesBalance.RoomsInQuotaClosingBalance),
	|			MIN(RoomQuotaSalesBalance.BedsRemainsClosingBalance),
	|			MIN(RoomQuotaSalesBalance.RoomsRemainsClosingBalance)
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|					&qDateFrom,
	|					&qDateTo,
	|					Minute,
	|					RegisterRecordsAndPeriodBoundaries,
	|					&qUseRoomQuota
	|						AND RoomQuota IN HIERARCHY (&qRoomQuota)
	|						AND (&qHotelIsFilled
	|								AND Hotel IN HIERARCHY (&qHotel)
	|							OR NOT &qHotelIsFilled)) AS RoomQuotaSalesBalance
	|		
	|		GROUP BY
	|			RoomQuotaSalesBalance.Room,
	|			RoomQuotaSalesBalance.RoomType) AS RoomBalance
	|	WHERE
	|		NOT RoomBalance.Room.DeletionMark
	|	
	|	GROUP BY
	|		RoomBalance.RoomType,
	|		RoomBalance.Room
	|	
	|	HAVING
	|		MAX(RoomBalance.RoomsVacant) >= 1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VirtualRooms.Ref,
	|		VirtualRooms.RoomType,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		Catalog.Rooms AS VirtualRooms
	|	WHERE
	|		VirtualRooms.IsVirtual
	|		AND (&qHotelIsFilled
	|					AND VirtualRooms.Owner IN HIERARCHY (&qHotel)
	|				OR NOT &qHotelIsFilled)) AS Rooms
	|		LEFT JOIN (SELECT
	|			RoomsStopSalePeriods.Ref AS RoomsStopSale
	|		FROM
	|			Catalog.Rooms.StopSalePeriods AS RoomsStopSalePeriods
	|		WHERE
	|			RoomsStopSalePeriods.StopSale
	|			AND RoomsStopSalePeriods.PeriodFrom < &qDateTimeTo
	|			AND RoomsStopSalePeriods.PeriodTo > &qDateFrom
	|			AND NOT RoomsStopSalePeriods.Ref.DeletionMark
	|			AND NOT RoomsStopSalePeriods.Ref.IsFolder
	|		
	|		GROUP BY
	|			RoomsStopSalePeriods.Ref) AS RoomsStopSales
	|		ON Rooms.Room = RoomsStopSales.RoomsStopSale
	|		LEFT JOIN (SELECT
	|			RoomTypesStopSalePeriods.Ref AS RoomTypesStopSale
	|		FROM
	|			Catalog.RoomTypes.StopSalePeriods AS RoomTypesStopSalePeriods
	|		WHERE
	|			RoomTypesStopSalePeriods.StopSale
	|			AND RoomTypesStopSalePeriods.PeriodFrom < &qDateTimeTo
	|			AND RoomTypesStopSalePeriods.PeriodTo > &qDateFrom
	|			AND NOT RoomTypesStopSalePeriods.Ref.DeletionMark
	|			AND NOT RoomTypesStopSalePeriods.Ref.IsFolder
	|		
	|		GROUP BY
	|			RoomTypesStopSalePeriods.Ref) AS RoomTypesStopSales
	|		ON Rooms.RoomType = RoomTypesStopSales.RoomTypesStopSale
	|WHERE
	|	Rooms.Room.IsFolder = FALSE
	|
	|ORDER BY
	|	SortCode";
	SelRoomQuota = InteractionParameters.Allotment;   
	vQry.SetParameter("qHotel", InteractionParameters.Hotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(InteractionParameters.Hotel));
	vQry.SetParameter("qDateFrom", CurrentSessionDate());
	vQry.SetParameter("qDateTo", New Boundary(CurrentSessionDate()+2, BoundaryType.Excluding));
	vQry.SetParameter("qDateTimeTo", CurrentSessionDate()+2); 
	vQry.SetParameter("qRoomQuota", SelRoomQuota);
	vQry.SetParameter("qUseRoomQuota", ValueIsFilled(SelRoomQuota));	
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;

EndFunction // pmRun

#EndRegion
