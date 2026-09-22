//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                  			 1C:HOTEL                                   //
//                          HotelLab INTERFACE                            	//
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
#Region EventHandlers

// -----------------------------------------------------------------------------
Function ChangePricesPOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("Token");
		vParamsArray.Add("Prices");

		vNonMandatoryParamsArray = New Array;
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.Error;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.Token, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "ChangePrices.Start",
				Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999);
		EndIf;
		
		vPricesWriteEror = New Array;  
		// Call API
		ChangePrices(vInteraction, vInputParameters, vPricesWriteEror);
		If vPricesWriteEror.Count() > 0 Then
			vResponseParam.Success = False;  
			vResponseParam.Insert("prices", vPricesWriteEror);
		Else	
			vResponseParam.Success = True;
		EndIf;
	Except
		vErr = ErrorInfo();
		WriteLogEvent("ChangePrices.Error", EventLogLevel.Error, , , DetailErrorDescription(vErr));

		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "ChangePrices.Error",
			Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999);

	EndTry;
	
	Return GetResponce(vResponseParam, vInteraction, "ChangePrices.Finish");

EndFunction // ChangePricesPOST

// -----------------------------------------------------------------------------
Function GetRoomRatesPOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	vResponseParam.Insert("RoomRates", New Array);
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("Token");

		vNonMandatoryParamsArray = New Array;
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.Error;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.Token, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "ChangePrices.Start",
				Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999);
		EndIf;
		
		// Call API
		vRoomRates = GetRoomRates(vInteraction.Hotel);  
		vResponseParam.RoomRates = vRoomRates;  
		vResponseParam.Success = True;
	Except
		vErr = ErrorInfo();
		WriteLogEvent("ChangePrices.Error", EventLogLevel.Error, , , DetailErrorDescription(vErr));

		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "ChangePrices.Error",
			Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999);

	EndTry;
	
	Return GetResponce(vResponseParam, vInteraction, "ChangePrices.Finish");

EndFunction // GetRoomRatesPOST

// -----------------------------------------------------------------------------
Function GetRoomTypesPOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	vResponseParam.Insert("RoomTypes", New Array);
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("Token");

		vNonMandatoryParamsArray = New Array;
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.Error;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.Token, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "ChangePrices.Start",
				Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999);
		EndIf;
		
		// Call API
		vRoomTypes = GetRoomTypes(vInteraction.Hotel);  
		vResponseParam.RoomTypes = vRoomTypes;  
		vResponseParam.Success = True;
	Except
		vErr = ErrorInfo();
		WriteLogEvent("ChangePrices.Error", EventLogLevel.Error, , , DetailErrorDescription(vErr));

		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "ChangePrices.Error",
			Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999);

	EndTry;
	
	Return GetResponce(vResponseParam, vInteraction, "ChangePrices.Finish");

EndFunction // GetRoomTypesPOST

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure ChangePrices(pInteraction, pInputParameters, pPricesWriteEror)
	vPrices = pInputParameters.Prices; 
	vHotel = pInteraction.Hotel;
	vCurDateTime = CurrentSessionDate();
	For Each vRowPrice In vPrices Do  
		vRowPrice.Insert("Error", "");  
		// Date
		If Not ValueIsFilled(vRowPrice.date) Then
			vRowPrice.Error = "Date is empty";
			pPricesWriteEror.Add(vRowPrice);
			Continue;
		EndIf;     
		vDate = ReadJSONDate(vRowPrice.date, JSONDateFormat.ISO);  
		If Not ValueIsFilled(vDate) Then
			vRowPrice.Error = "Date is empty";
			pPricesWriteEror.Add(vRowPrice);
			Continue;
		EndIf;   
		// Room type
		vExtCategoryCode = TrimAll(vRowPrice.category);
		If IsBlankString(vExtCategoryCode) Then
			vRowPrice.Error = "Category is empty";
			pPricesWriteEror.Add(vRowPrice);
			Continue;
		EndIf;
		vRoomType = cmGetObjectRefByExternalSystemCode(vHotel, pInteraction.InteractionID, "RoomTypes", vExtCategoryCode, True); 
		If Not ValueIsFilled(vRoomType) Then
			vRowPrice.Error = "Room type not found";
			pPricesWriteEror.Add(vRowPrice);
			Continue;
		EndIf;  
		// Room rate  
		vExtRoomRateCode = TrimAll(vRowPrice.ratecode);
		If IsBlankString(vExtRoomRateCode) Then
			vRowPrice.Error = "Ratecode is empty";
			pPricesWriteEror.Add(vRowPrice);
			Continue;
		EndIf;
		vRoomRate = cmGetObjectRefByExternalSystemCode(vHotel, pInteraction.InteractionID, "RoomRates", vExtRoomRateCode, True); 
		If Not ValueIsFilled(vRoomRate) Then
			vRowPrice.Error = "Room rate not found";
			pPricesWriteEror.Add(vRowPrice);
			Continue;
		EndIf;  
        // Calendar day type  
		vExtCalendarDayTypeCode = TrimAll(vRowPrice.price);
		If IsBlankString(vExtCalendarDayTypeCode) Then
			vRowPrice.Error = "Price is empty";
			pPricesWriteEror.Add(vRowPrice);
			Continue;
		EndIf;
		If vRoomRate.UsePricesFromCalendar = False Then
			vCalendarDayType = GetCalendarDayTypeByExtCode(vHotel, vRoomRate, vExtCalendarDayTypeCode); 
			If Not ValueIsFilled(vCalendarDayType) Then
				vRowPrice.Error = "Price match not found";
				pPricesWriteEror.Add(vRowPrice);
				Continue;
			EndIf;   
		Else
			vCalendarDayType = Undefined;
		EndIf;
		Try
			vRmg = InformationRegisters.CalendarDaysByRoomTypes.CreateRecordManager();
			vRmg.Calendar = vRoomRate.Calendar;  
			vRmg.RoomType = vRoomType;
			vRmg.Hotel = vHotel;	 
			vRmg.Period = vCurDateTime; 
			vRmg.AccountingDate = BegOfDay(vDate); 
			vRmg.CalendarDayType = vCalendarDayType;
			vRmg.Author = SessionParameters.CurrentUser;
			vRmg.Remarks = "HotelLab";  
			If vRoomRate.UsePricesFromCalendar Then
				vRmg.RoomPrice = vExtCalendarDayTypeCode; 
			EndIf;	
			vRmg.RoomPriceCurrency = vHotel.BaseCurrency;
			vRmg.Write(True);
		Except 
			vErrInfo = ErrorInfo();
			vRowPrice.Error = BriefErrorDescription(vErrInfo);
			pPricesWriteEror.Add(vRowPrice);
		EndTry;
	EndDo;
EndProcedure // ChangePrices

// -----------------------------------------------------------------------------
Function GetResponce(pParams, pInteraction = Undefined, pRequestDescription = "AccountingDataExchange")
    // Check result
	If pParams.Success Then
		vResponse = New HTTPServiceResponse(200);
		vEventType = Enums.ExternalSystemEventTypes.Info;
	Else
		vResponse = New HTTPServiceResponse(400);
		vEventType = Enums.ExternalSystemEventTypes.Error;
	EndIf;
    // Generate json
	vJson = Catalogs.DataConvertationRules.MapToJSON(pParams);
    // Log
	If Not pInteraction = Undefined And pInteraction.DebugMode Then
		vMsg = NStr("en = 'Response'; de = 'Antwort'; ru = 'Ответ'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteraction, pRequestDescription, vEventType, ,
			vJson, vMsg, 999999999);
	EndIf;
	vResponse.Headers.Insert("Content-type", "application/JSON; charset=utf-8");	
    // Set response
	vResponse.SetBodyFromString(vJson);
	Return vResponse;
EndFunction // GetResponce

// -----------------------------------------------------------------------------
Function GetEmptyResponceStructure()
	vResponseParam = New Structure;
	vResponseParam.Insert("ErrorDescription", "");
	vResponseParam.Insert("Success", False);
	Return vResponseParam;
EndFunction // GetEmptyResponceStructure

// -----------------------------------------------------------------------------
Function GetEmptyRoomRateStructure()
	vRates = New Structure;
	vRates.Insert("Description", "");
	vRates.Insert("Code", "");
	vRates.Insert("DateValidFrom", ""); 
	vRates.Insert("DateValidTo", "");
	Return vRates;
EndFunction // GetEmptyRoomRateStructure

// -----------------------------------------------------------------------------
Function GetEmptyRoomTypeStructure()
	vRoomTypes = New Structure;
	vRoomTypes.Insert("Description", "");
	vRoomTypes.Insert("Code", "");
	vRoomTypes.Insert("IsVirtual", ""); 
	vRoomTypes.Insert("StopSale", "");
	Return vRoomTypes;
EndFunction // GetEmptyRoomTypeStructure

// -----------------------------------------------------------------------------
Function CheckFilling(pCheckParams, pSource, pErr = "")
	vCheck = True;
	vMsg = NStr("en = 'Parameter %1 is empty';de = 'Parameter %1 fehlt';ru = 'Параметр %1 не заполнен'");
	For Each vId In pCheckParams Do  
		vItem = pSource[vId];
		If (TypeOf(vItem) = Type("Map") Or TypeOf(vItem) = Type("Array") Or TypeOf(vItem) = Type("ValueTable") Or TypeOf(vItem) = Type("ValueList")) And vItem.Count() = 0 Then
			pErr = pErr + Chars.LF + StrTemplate(vMsg, vId);
			vCheck = False;
		ElsIf Not ValueIsFilled(vItem) Then
			pErr = pErr + Chars.LF + StrTemplate(vMsg, vId);
			vCheck = False;
		EndIf;
	EndDo;
	Return vCheck;
EndFunction // CheckFilling

// -----------------------------------------------------------------------------
Function GetInteraction(pExternalCode, pMsg = "")
	vInteraction =  Undefined;
	If pExternalCode = Undefined Or IsBlankString(pExternalCode) Then
		pMsg = NStr(
			"en = 'External system code(token) not set'; de = 'Externer Systemcode(token) nicht festgelegt'; ru = 'Код внешней системы(token) не задан'");
	Else
		vInteractions = GetInteractionByOAuth_AccessToken(pExternalCode, True);
		If vInteractions.Count() > 1 Then
			pMsg = NStr(
				"en='More then one interactions found with given token!'; de='More then one interactions found with given token!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным token!'");
		ElsIf vInteractions.Count() = 1 Then
			vInteraction = vInteractions.Get(0).Ref;
			If Not vInteraction.IsActive Then
				pMsg = NStr(
					"en='Interaction with given token is not active!'; de='Interaction with given token is not active!'; ru='Взаимодействие с переданным идентификатором не активно!'");
			EndIf;
		Else
			pMsg = NStr(
				"en='Interaction with given token is not found!'; de='Interaction with given token is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным token!'");
		EndIf;
	EndIf;
	Return vInteraction;
EndFunction // GetInteraction

// -----------------------------------------------------------------------------
//
// Parameters:
//  pInteractionID	 - String	 - Interaction ID
//  pAllInteractions - Boolean	 - All interactions
// 
// Returns:
//  CatalogRef.ExternalSystemInteractions - External system interactions
//
Function GetInteractionByOAuth_AccessToken(pInteractionID, pAllInteractions = False) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExternalSystemInteractions.Ref AS Ref
	|FROM
	|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	|WHERE
	|	NOT ExternalSystemInteractions.DeletionMark
	|	AND ExternalSystemInteractions.OAuth_AccessToken = &qInteractionID
	|	AND NOT ExternalSystemInteractions.IsFolder
	|	AND CASE
	|			WHEN &qAllInteractions
	|				THEN TRUE
	|			ELSE ExternalSystemInteractions.IsActive
	|		END";
	vQry.SetParameter("qInteractionID", pInteractionID);
	vQry.SetParameter("qAllInteractions", pAllInteractions);
	vInteractionObj = Undefined;
	Return vQry.Execute().Unload();
EndFunction // GetInteractionByOAuth_AccessToken

// -----------------------------------------------------------------------------
Function GetCalendarDayTypeByExtCode(pHotel, pRoomRate, pExtCalendarDayTypeCode)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	RoomRatesSliceLast.CalendarDayType AS CalendarDayType
		|FROM
		|	InformationRegister.RoomRates.SliceLast AS RoomRatesSliceLast
		|WHERE
		|	RoomRatesSliceLast.RoomRate = &qRoomRate
		|	AND RoomRatesSliceLast.Hotel = &qHotel
		|	AND RoomRatesSliceLast.CalendarDayType.Description = &qCalendarDayType
		|	AND NOT RoomRatesSliceLast.IsFormula";
	
	vQuery.SetParameter("qCalendarDayType", pExtCalendarDayTypeCode);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qRoomRate", pRoomRate);
	
	vQueryResult = vQuery.Execute();
	If vQueryResult.IsEmpty() Then
		Return Undefined;
	Else	
		vRowResult = vQueryResult.Select();
		vRowResult.Next();
		Return vRowResult.CalendarDayType;
	EndIf;
EndFunction // GetCalendarDayTypeByExtCode

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - 	Catalog.Hotels - Ref on catalog item
// 
// Returns:
//  Array - List room rates
//
Function GetRoomRates(pHotel)  
	vRoomRates = New Array;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	RoomRates.Code AS Code,
		|	RoomRates.Description AS Description,
		|	RoomRates.DateValidFrom AS DateValidFrom,
		|	RoomRates.DateValidTo AS DateValidTo
		|FROM
		|	Catalog.RoomRates AS RoomRates
		|WHERE
		|	RoomRates.DeletionMark = FALSE
		|	AND RoomRates.Hotel = &qHotel";
	
	vQuery.SetParameter("qHotel", pHotel);
	
	vQueryResult = vQuery.Execute();
	
	vRec = vQueryResult.Select();
	
	While vRec.Next() Do
		vRate = GetEmptyRoomRateStructure();
		vRate.Code = TrimAll(vRec.Code);
		vRate.Description = TrimAll(vRec.Description);
		vRate.DateValidFrom = vRec.DateValidFrom;
		vRate.DateValidTo = vRec.DateValidTo;
		vRoomRates.Add(vRate);
	EndDo;
	Return vRoomRates; 
EndFunction // GetRoomRates

// -----------------------------------------------------------------------------
Function GetRoomTypes(pHotel)  
	vRoomTypes = New Array;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	RoomTypes.Code AS Code,
		|	RoomTypes.Description AS Description,
		|	RoomTypes.IsVirtual AS IsVirtual,
		|	RoomTypes.StopSale AS StopSale
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	RoomTypes.DeletionMark = FALSE
		|	AND RoomTypes.Owner = &qHotel";
	
	vQuery.SetParameter("qHotel", pHotel);
	
	vQueryResult = vQuery.Execute();
	
	vRec = vQueryResult.Select();
	
	While vRec.Next() Do
		vRoomType = GetEmptyRoomTypeStructure();
		vRoomType.Code = TrimAll(vRec.Code);
		vRoomType.Description = TrimAll(vRec.Description);
		vRoomType.IsVirtual = vRec.IsVirtual;
		vRoomType.StopSale = vRec.StopSale;
		vRoomTypes.Add(vRoomType);
	EndDo;
	Return vRoomTypes; 
EndFunction // GetRoomTypes

#EndRegion