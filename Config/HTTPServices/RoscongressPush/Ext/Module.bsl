#Region EventHandlers

// --------------------------------------------------------------------------------
Function ReservationsPOST(pRequest)
	
	vExternalSystemCode 	= "Roscongress";

	vInteractionParameters 	= ProlongedOperations.Roscongress_GetInteractionParametersRefByID(vExternalSystemCode);
	
	vRequeuestBody 	= pRequest.GetBodyAsString();	
	vJSONText		= "";
	
	If vRequeuestBody <> Undefined Then
		                              
		vSuccess 			= True;
		vErrorDescription 	= Undefined;
		
		vJSON = new JSONReader;
		vJSON.SetString(vRequeuestBody);
		Try
			vTable = ReadJSON(vJSON);
		Except
			vSuccess 			= False;
			vErrorDescription 	= "Can't read request body as JSON";
		EndTry;
		
		If vSuccess and vTable <> Undefined and TypeOf(vTable) = Type("Structure") Then
			If vTable.Property("Reservations") Then
				For each vReservation in vTable.Reservations Do
					If vReservation.Property("IsActive") Then
					Else
						AddErrorDescription(vErrorDescription, "Missing <IsActive>");
						vSuccess = False;
					EndIf;
					If vReservation.Property("IsPayed") Then
					Else
						AddErrorDescription(vErrorDescription, "Missing <IsPaid>");
						vSuccess = False;
					EndIf;
					If vReservation.Property("Rooms") Then
						For each vRoom in vReservation.Rooms Do
							If vRoom.Property("ID") Then
							Else
								AddErrorDescription(vErrorDescription, "Missing <Rooms>");
								vSuccess = False;
							EndIf;
							If vRoom.Property("RoomNumber") Then
							Else
								AddErrorDescription(vErrorDescription, "Missing <RoomNumber>");
								vSuccess = False;
							EndIf;
							If vRoom.Property("RoomType") Then
							Else
								AddErrorDescription(vErrorDescription, "Missing <RoomType>");
								vSuccess = False;
							EndIf;
							If vRoom.Property("AccommodationType") Then
							Else
								AddErrorDescription(vErrorDescription, "Missing <AccommodationType>");
								vSuccess = False;
							EndIf;
							If vRoom.Property("CheckInDate") Then
							Else
								AddErrorDescription(vErrorDescription, "Missing <CheckInDate>");
								vSuccess = False;
							EndIf;
							If vRoom.Property("CheckOutDate") Then
							Else
								AddErrorDescription(vErrorDescription, "Missing <CheckOutDate>");
								vSuccess = False;
							EndIf;
							If vRoom.Property("IsEarlyCheckIn") Then
							Else
								AddErrorDescription(vErrorDescription, "Missing <IsEarlyCheckIn>");
								vSuccess = False;
							EndIf;
							If vRoom.Property("IsLateCheckOut") Then
							Else
								AddErrorDescription(vErrorDescription, "Missing <IsLateCheckOut>");
								vSuccess = False;
							EndIf;
							If vRoom.Property("CheckInTime") Then
							Else
								AddErrorDescription(vErrorDescription, "Missing <CheckInTime>");
								vSuccess = False;
							EndIf;
							If vRoom.Property("CheckOutTime") Then
							Else
								AddErrorDescription(vErrorDescription, "Missing <CheckOutTime>");
								vSuccess = False;
							EndIf;
							If vRoom.Property("ConfirmFromHotel") Then
							Else
								AddErrorDescription(vErrorDescription, "Missing <ConfirmFromHotel>");
								vSuccess = False;
							EndIf;
							If vRoom.Property("Annulated") Then
							Else
								AddErrorDescription(vErrorDescription, "Missing <Annulated>");
								vSuccess = False;
							EndIf;
							If vRoom.Property("Guests") Then
								For each vGuestRow in vRoom.Guests Do
									If TypeOf(vGuestRow) = Type("Structure") Then
										If Not vGuestRow.Property("FullName") Then
											AddErrorDescription(vErrorDescription, "Missing <FullName>");
											vSuccess = False;
										EndIf;	
									Else
										AddErrorDescription(vErrorDescription, "<Guests> should be array of objects");
										vSuccess = False;
										Break;
									EndIf;
								EndDo;
							Else
								AddErrorDescription(vErrorDescription, "Missing <Guests>");
								vSuccess = False;
							EndIf;
						EndDo;
					Else
						vSuccess = False;
					EndIf;
				EndDo;
			Else            
				AddErrorDescription(vErrorDescription, "Missing <Reservations>");
				vSuccess = False;
			EndIf;
		ElsIf vSuccess Then
			vSuccess 			= False;
			vErrorDescription 	= "Cant read request body as JSON";	
		EndIf;

		If NOT vSuccess Then
			vResponse 		= New HTTPServiceResponse(400);
		Else
			vParametrsArray = New Array;
			vParametrsArray.Add(vTable);
			
			If AsyncCalls.CheckForExistingBackgroundJobsInRegister("HTTPService_RoscongressPush").Count() = 0 Then 
				AsyncCalls.StartBackgroundJobWithRecordInRegister("HTTPService_RoscongressPush", "ReservationsPOST", "ProlongedOperations.Roscongress_LoadReservations", vParametrsArray);
			EndIf;
			
			vResponse 		= New HTTPServiceResponse(202);
		EndIf;
		vJSONResponse 	= New JSONWriter;
		vJSONResponse.ValidateStructure = False;
		vJSONResponse.SetString();
		
		vJSONResponse.WriteStartObject();			
			vJSONResponse.WritePropertyName("Success");
			vJSONResponse.WriteValue(vSuccess);
			 
			vJSONResponse.WritePropertyName("ErrorDescription");
			vJSONResponse.WriteValue(vErrorDescription);
		vJSONResponse.WriteEndObject();
		
		vJSONText = vJSONResponse.Close();
		
		vResponse.SetBodyFromString(vJSONText);
		
		Try
			If vSuccess = True Then
				vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
			Else
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;	
			EndIf;
			
			If vInteractionParameters.DebugMode Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "Roscongress_request", vLogEventType, vRequeuestBody, vJSONText, vErrorDescription);
			EndIf;
			
		Except
			WriteLogEvent(vInteractionParameters.InteractionID + "_ ReservationsPOST", EventLogLevel.Warning,,CurrentSessionDate(),"Неудалось сделать запись в лог по причине: " + ErrorDescription());
		EndTry;
	
		Return vResponse;
	EndIf;	
EndFunction // ReservationsPOST

// --------------------------------------------------------------------------------
Function GetReservationsCheckInGET(pRequest)
	vResponseCode = 200;
	vResponseBody = "";
	
	vParamsArray = New Array;
	vParamsArray.Add("from");
	
	vNonMandatoryParamsArray = New Array;
	vNonMandatoryParamsArray.Add("to");
	
	// Read request body
	vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
	
	If ValueIsFilled(vRequestParams.Error) Then
		vRequestParams 	= cmCheckRequestParameters("QueryOptions", vParamsArray, vNonMandatoryParamsArray, pRequest);	
	EndIf;
	
	If Not ValueIsFilled(vRequestParams.Error) Then	
		vInteractionParameters 	= ProlongedOperations.Roscongress_GetInteractionParametersRefByID("Roscongress");
		If ValueIsFilled(vInteractionParameters) Then 	
			vReservationsArr = New Array;
			
			vReservations = GetReservationsList(vInteractionParameters, vRequestParams.from, vRequestParams.to);
			For Each vReservationRow In vReservations Do 
				vCodeArr = StrSplit(vReservationRow.ExternalCode, "/", True);
				If IsBlankString(vCodeArr[1]) Or Not cmIsNumber(vCodeArr[1]) Then
					Continue;
				EndIf;				
				vReservationsArr.Add(New Structure("id, checkIn, checkInUpdateDateTime", Number(vCodeArr[1]), vReservationRow.IsCheckIn, vReservationRow.UpdateDateTime));
			EndDo;
				
			vResponseBody = Catalogs.DataConvertationRules.MapToJSON(vReservationsArr, "DF=yyyy-MM-ddTHH:mm:ss");
			
			If vInteractionParameters.DebugMode Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "Roscongress_request_GetReservationsCheckIn", Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), vResponseBody);
			EndIf;
		Else
			vResponseCode = 401;
			vResponseBody = "Failed to find interaction parameters";
		EndIf;
	Else      
		vResponseCode = 400;
		vResponseBody = vRequestParams.Error; 	
	EndIf;
	
	vResponse = New HTTPServiceResponse(vResponseCode);
	vResponse.Headers.Insert("Content-Type", "application/json;charset=utf-8");
	vResponse.SetBodyFromString(vResponseBody);
		
	Return vResponse;
EndFunction // GetReservationsCheckInGET

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function GetReservationsList(pInteractionParameters, pDateFrom, pDateTo)
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	ReservationChangeHistorySliceLast.ExternalCode AS ExternalCode,
	|	ReservationChangeHistorySliceLast.Period AS UpdateDateTime,
	|	ReservationChangeHistorySliceLast.ReservationStatus.IsCheckIn AS IsCheckIn
	|FROM
	|	InformationRegister.ReservationChangeHistory.SliceLast(
	|			&qDateTo,
	|			RoomQuota = &qRoomQuota
	|				AND ExternalCode LIKE ""%/%/%""
	|				AND (AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|					OR AccommodationTemplate = VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|						AND (AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
	|							OR AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds)))
	|				AND Period >= &qDateFrom) AS ReservationChangeHistorySliceLast"; 
	vQuery.SetParameter("qRoomQuota", pInteractionParameters.Allotment);
	vQuery.SetParameter("qDateFrom", XMLValue(Type("Date"), pDateFrom));
	vQuery.SetParameter("qDateTo", ?(pDateTo <> Undefined, XMLValue(Type("Date"), pDateTo), '00010101'));	
	Return vQuery.Execute().Unload();
EndFunction // GetReservationsList

// --------------------------------------------------------------------------------
Function AddErrorDescription(pErrorDescription, pErrorText)
	If pErrorDescription = Undefined Then
		pErrorDescription = pErrorText;
	Else
		pErrorDescription = pErrorDescription + "; " + pErrorText; 
	EndIf;
	Return pErrorDescription;    
EndFunction // AddErrorDescription

#EndRegion