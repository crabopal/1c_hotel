#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameter
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

//  -----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	vInteractionObj = InteractionParameters.GetObject();
	vInteractionObj.HttpUseSsl = True;
	vInteractionObj.HttpServer = "www.igloorooms.com";
	vInteractionObj.HttpAddress = "/x/AppWCF.svc";
	vInteractionObj.Write();
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter		 - Structure - Parameter
//  pIsInteractive	 - Boolean	 - IsInteractive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	HTTPQuery();
EndProcedure // pmRun

// -----------------------------------------------------------------------------
//
// Parameters:
//  pTemplatesTable	 - FormDataCollection - Form attribute that contains names of object templates
//
Procedure GetTemplates(pTemplatesTable) Export
	vTemplates = Metadata().Templates;
	For Each vTemplate In vTemplates Do
		vNewRow = pTemplatesTable.Add();
		vNewRow.Description = vTemplate.Name;
	EndDo;
EndProcedure // GetTemplates

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
//
// Parameters:
//  pTX_ID	 - Number - id of reservation transaction
// 
// Returns:
//  JSON - JSON for request
//
Function BuildJSON(pTX_ID = Undefined)
	vStruct = New Structure();
	vStruct.Insert("CODE", HotelCode);
	vStruct.Insert("USER_NAME", UserName);
	vStruct.Insert("PASSWORD", Password);
	If pTX_ID <> Undefined Then
		vStruct.Insert("TX_ID", pTX_ID);
	EndIf;
	
	Return Catalogs.DataConvertationRules.MapToJSON(vStruct);
EndFunction // BuildJSON

// -----------------------------------------------------------------------------
//
// Parameters:
//  pTX_ID	 - Number	 - id of reservation transaction
// 
// Returns:
//  Boolean - result of http request
//
Function HTTPQuery(pTX_ID = Undefined)
	vRequestBody = BuildJSON(pTX_ID);
	If pTX_ID = Undefined Then
		vRequestURL = InteractionParameters.HttpAddress + "/Get_PMS_Tx";	
	Else
		vRequestURL = InteractionParameters.HttpAddress + "/Acknowledge_PMS_TX";	
	EndIf;
	
	vRes = Catalogs.ExternalSystemInteractions.SendHTTPRequest(InteractionParameters, , vRequestURL, "POST", , vRequestBody, "JSON", , , , , , , , False, "HTTPQuery");
	
	vErr = "";
	If vRes.Error = Undefined Then
		vStatuscode = vRes.StatusCode;
		If vStatuscode = 200 Then
			Try
				vResMap = Catalogs.DataConvertationRules.JSONtoMap(vRes.Body);
				
				vExceptionMsg = vResMap.Get("ExceptionMsg");
				If vExceptionMsg <> Undefined And Not IsBlankString(vExceptionMsg) Then
					vErr = GetExceptionMsgDescription(vExceptionMsg);
				Else
					vPathArray = New Array;
					vPathArray.Add("My_Result");
					vResultBody	= Catalogs.DataConvertationRules.GetMapValueByArrayPath(vResMap, vPathArray);
					vMy_ResultArray = vResMap.Get("My_Result");
				EndIf;
			Except
				vErr = ErrorDescription();
			EndTry;
		Else
			vErr = GetErrorMessage(vStatuscode);
		EndIf;
	EndIf;
	If Not IsBlankString(vErr) Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "HTTPQuery", 
																	Enums.ExternalSystemEventTypes.Error, vRequestBody, vRes, vErr);
		Return False;
	Else
		If pTX_ID = Undefined Then
			WriteReservation(vMy_ResultArray);
		EndIf;																
	EndIf;
	
	Return True;
EndFunction // HTTPQuery

// -----------------------------------------------------------------------------
Procedure WriteReservation(pMy_ResultArray)
	vTX_ID = Undefined;
	Try
		For Each vMy_ResultMap In pMy_ResultArray Do				
			vPathArray = New Array;
			vPathArray.Add("Rooms");
			vRoomsArray	= Catalogs.DataConvertationRules.GetMapValueByArrayPath(vMy_ResultMap, vPathArray);
			If TypeOf(vRoomsArray) = Type("Array") And vRoomsArray.Count() > 0 Then
				For Each vRoomMap In vRoomsArray Do
					// RESERVATION
					vExternalGroupReservation = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservation"));
					
					// CLIENT
					vMainGuest 					 = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
					vMainGuest.ClientCitizenship = vMy_ResultMap.Get("GUEST_COUNTRY");
					vMainGuest.ClientEMail 		 = vMy_ResultMap.Get("GUEST_EMAIL");
					vMainGuest.ClientFirstName 	 = vMy_ResultMap.Get("GUEST_FIRST_NAME");
					vMainGuest.ClientLastName 	 = vMy_ResultMap.Get("GUEST_LAST_NAME");
					vMainGuest.ClientPhone 		 = vMy_ResultMap.Get("GUEST_PHONE");
					vMainGuest.ClientRemarks 	 = vMy_ResultMap.Get("GUEST_REMARK");
					
					vRooms_Occupancy = vRoomMap.Get("ROOMS_OCCUPANCY");
					vNumberOfAdults = 0;
					vNumberOfChildren = 0;
					vGuestCount = 0;
					If vRooms_Occupancy <> Undefined Then
						vROStagesOfMature = StrSplit(vRooms_Occupancy, "-");
						For vInd_Stages = 0 To vROStagesOfMature.Count() - 1 Do
							vCount = Number(TrimAll(StrSplit(vROStagesOfMature[vInd_Stages], ":")[1]));
							If vInd_Stages = 0 Then
								vNumberOfAdults = vCount;
							Else
								vNumberOfChildren = vCount;
							EndIf;
							vGuestCount = vGuestCount + vCount;
						EndDo;
					Else
						vNumberOfAdults = vRoomMap.Get("ADULTS_NBR");
						vNumberOfChildren = vRoomMap.Get("CHILD_NBR");
						vGuestCount = vNumberOfAdults + vNumberOfChildren;
					EndIf;
						
					vAccommodationTemplate = cmGetAccommodationTemplateByGuestsQuantityAndRoomType(vNumberOfAdults, , vNumberOfChildren, , vRoomMap.Get("PMS_ROOM_TYPE_CODE"),
																								   InteractionParameters.Hotel, , True, InteractionParameters.InteractionID);
					vAccommodationTypes	= Undefined;
					If ValueIsFilled(vAccommodationTemplate) Then																				   
						vAccommodationTypes = vAccommodationTemplate.AccommodationTypes;
					EndIf;
					
					For vIndRT_NBR = 1 To Number(vRoomMap.Get("RT_NBR")) Do
						vRoomUUID = New UUID;
						For vInd_GuestCount = 0 To vGuestCount - 1 Do
							// RESERVATION ROW
							vExternalGroupReservationRow 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservationRow"));
							
							vReservationID 									= vMy_ResultMap.Get("BOOK_NBR") + "_" + StrReplace(String(vRoomMap.Get("BSA_ID")), Chars.NBSp, "");
							
							vRoomRateAndServPackage = InformationRegisters.ExternalSystemIntegrationData.GetData(InteractionParameters, "RoomRates", "id", , , vRoomMap.Get("PMS_RATE_PLAN_CODE"));
							vRoomRate = Undefined;
							If vRoomRateAndServPackage.Count() > 0 Then
								vResult = vRoomRateAndServPackage[0];
								If ValueIsFilled(vResult.RefKey1) Then
									vRoomRate = vResult.RefKey1;
									vExternalGroupReservationRow.RoomRate 	   = vRoomRate.Code;
								EndIf;
								If ValueIsFilled(vResult.RefKey2) Then
									vExternalGroupReservationRow.MealBoardTerm = vResult.RefKey2.Code;
								EndIf;
							EndIf;
							If Not ValueIsFilled(vExternalGroupReservationRow.RoomRate) Then
								vExternalGroupReservationRow.RoomRate 	   = vRoomMap.Get("PMS_RATE_PLAN_CODE");
							EndIf;
							If Not ValueIsFilled(vExternalGroupReservationRow.MealBoardTerm) Then
								vExternalGroupReservationRow.MealBoardTerm = vRoomMap.Get("FOOD_ARRANGMENT_PLAN");
							EndIf;
							vExternalGroupReservationRow.Room 			   = String(vRoomUUID);
							vExternalGroupReservationRow.RoomType 		   = vRoomMap.Get("PMS_ROOM_TYPE_CODE");							
							
							If Not ValueIsFilled(vRoomRate) And ValueIsFilled(vExternalGroupReservationRow.RoomRate) Then
								vRoomRate = cmGetObjectRefByExternalSystemCode(InteractionParameters.Hotel, InteractionParameters.InteractionID, "RoomRates", vExternalGroupReservationRow.RoomType);
							EndIf;
							
							// Check in and check out
							If ValueIsFilled(vRoomRate) Then
								If ValueIsFilled(vRoomRate.DefaultCheckInTime) Then
									vCheckInTime = vRoomRate.DefaultCheckInTime;
								Else
									vCheckInTime = vRoomRate.ReferenceHour;
								EndIf;
								
								If ValueIsFilled(vRoomRate.DefaultCheckOutTime) Then
									vCheckOutTime = vRoomRate.DefaultCheckOutTime;
								Else
									vCheckOutTime = vRoomRate.ReferenceHour;
								EndIf;
							EndIf;
							
							vExternalGroupReservationRow.PeriodFrom	= vMy_ResultMap.Get("BOOK_FROM") + Format(vCheckInTime, "DF=THH:mm:ss");
							vExternalGroupReservationRow.PeriodTo = vMy_ResultMap.Get("BOOK_TO") + Format(vCheckOutTime, "DF=THH:mm:ss");
							
							vBookStatusCodeExt = vMy_ResultMap.Get("BOOK_STATUS_CODE");
							vBookStatusCodeInt = vMy_ResultMap.Get("BOOK_STATUS");
							vBookCurrency = vMy_ResultMap.Get("BOOK_CURRENCY");
							vResStatusInt = cmGetObjectRefByExternalSystemCode(InteractionParameters.Hotel, InteractionParameters.InteractionID, "ReservationStatuses", vBookStatusCodeInt);
							
							If vResStatusInt <> Undefined Then
								vBookStatusCode = vBookStatusCodeInt;
							Else
								vBookStatusCode = vBookStatusCodeExt;
							EndIf;
							vExternalGroupReservationRow.ReservationStatus	= vBookStatusCode;
							vExternalGroupReservationRow.GroupDescription	= vMy_ResultMap.Get("CHM_BOOK_NBR");
							vExternalGroupReservationRow.GroupCode 			= vMy_ResultMap.Get("BOOK_NBR");
							vCustomer = vMy_ResultMap.Get("SOURCE");
							vExternalGroupReservationRow.Customer		 	= vCustomer;
							
							vExternalGroupReservationRow.NumberOfRooms		= 1;
							vExternalGroupReservationRow.NumberOfPersons	= 1;
							vExternalGroupReservationRow.ExternalSystemCode	= InteractionParameters.InteractionID;
							vExternalGroupReservationRow.DoPosting			= True;
							
							If vInd_GuestCount = 0 Then
								// Fill client, remarks and template for the first guest row
								vExternalGroupReservationRow.ReservationCode    = vReservationID;
								vExternalGroupReservationRow.Client 		 	= ChannelManagers.CopyXDTO(vMainGuest, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
								
								vArrival_Time		 = ReplaceTags(vMy_ResultMap.Get("ARRIVAL_TIME"));
								vCancellation_Policy = ReplaceTags(vMy_ResultMap.Get("CANCELATION_POLICY"));
								vPrepayment_Amount	 = ReplaceTags(vMy_ResultMap.Get("PREPAYMENT_AMOUNT"));
								vPrepayment_Policy   = ReplaceTags(vMy_ResultMap.Get("PREPAYMENT_POLICY"));
								vExternalGroupReservationRow.ReservationRemarks = ?(Not IsBlankString(vCustomer), NStr("en = 'Customer: ';
																				  									   |de = 'Kunde: ';
																													   |ru = 'Заказчик: '") + vCustomer + Chars.LF, "")
																				  + ?(Not IsBlankString(vArrival_Time), vArrival_Time + Chars.LF, "")
																				  + ?(Not IsBlankString(vCancellation_Policy), vCancellation_Policy + Chars.LF, "")
																				  + ?(Not IsBlankString(vPrepayment_Policy), NStr("en = 'Prepayment amount: ';
																				  											 	  |de = 'Vorauszahlungsbetrag:';
																															 	  |ru = 'Сумма предоплаты: '") + vPrepayment_Amount + " " + vBookCurrency + Chars.LF, "")
																				  + vPrepayment_Policy;
								If ValueIsFilled(vAccommodationTemplate) Then
									vExternalGroupReservationRow.AccommodationTemplate = vAccommodationTemplate.Code;
								EndIf;
							Else
								vExternalGroupReservationRow.ReservationCode    = vReservationID + "/" + vInd_GuestCount;
								vExternalGroupReservationRow.Client 	  		= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
							EndIf;
						 	
							If vAccommodationTypes <> Undefined And vAccommodationTypes.Count() > 0 Then
								If vAccommodationTypes.Count() = vGuestCount Then																									   
									vExternalGroupReservationRow.AccommodationType = vAccommodationTypes[vInd_GuestCount].AccommodationType.Code;
								EndIf;
							Else
								Raise NStr("en = 'No accommodation template found!'; de = 'Keine Unterkunftsvorlage gefunden!'; ru = 'Не найден шаблон размещения!'");
							EndIf;

							vPathArray = New Array;
							vPathArray.Add("PMS_Room_Nights");
							vPMS_Room_NightArray = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vRoomMap, vPathArray);
							If TypeOf(vPMS_Room_NightArray) = Type("Array") And vPMS_Room_NightArray.Count() > 0 Then
								vPricesPerDate = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
								For Each vPMS_Room_NightMap In vPMS_Room_NightArray Do
									vNightPrice = vPMS_Room_NightMap.Get("NIGHT_COST");
									If cmIsNumber(vNightPrice) Then
										vNightPrice = Round(vNightPrice, 2);

										vPricePerDateRow	   = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricePerDateRow"));
										vPricePerDateRow.Date  = vPMS_Room_NightMap.Get("NIGHT_DATE");
										vPricePerDateRow.Price = vNightPrice;
										vPricePerDateRow.Currency = vBookCurrency;
										vPricesPerDate.PricePerDateRow.Add(vPricePerDateRow);
									EndIf;
								EndDo;
							EndIf;
							vExternalGroupReservationRow.PricesPerDate = vPricesPerDate;
							vExternalGroupReservation.WriteExternalGroupReservationRow.Add(vExternalGroupReservationRow);
						EndDo;
					EndDo;
					vAnswerXDTO = cmWriteExternalGroupReservation(vExternalGroupReservation, , True);
					
					If ValueIsFilled(vAnswerXDTO.ErrorDescription) Then
						vError	= "Failed to create reservation: " + vAnswerXDTO.ErrorDescription + "; Booking №:" + vReservationID;
						vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "HTTPQuery", vLogEventType, , , vError);
						
						Break;
					EndIf;
				EndDo;
			EndIf;
			If Not ValueIsFilled(vAnswerXDTO.ErrorDescription) And ValueIsFilled(vAnswerXDTO.GuestGroup) Then
				vBookedOnHour = String(vMy_ResultMap.Get("BOOKED_ON_HOUR"));
				If StrLen(vBookedOnHour) = 1 Then
					vBookedOnHour = "0" + vBookedOnHour;
				EndIf;
				vBookedOnMinute = String(vMy_ResultMap.Get("BOOKED_ON_MINUTE"));
				If StrLen(vBookedOnMinute) = 1 Then
					vBookedOnMinute = "0" + vBookedOnMinute;
				EndIf;
				If Not IsBlankString(vAnswerXDTO.GuestGroup) And Number(vAnswerXDTO.GuestGroup) <> 0 Then
					vGuestGroupRef = Catalogs.GuestGroups.FindByCode(Number(vAnswerXDTO.GuestGroup), , , InteractionParameters.Hotel);
					If ValueIsFilled(vGuestGroupRef) Then
						vGuestGroupObj = vGuestGroupRef.GetObject();
						vDateString = vMy_ResultMap.Get("BOOKED_ON_DATE") + "T" + vBookedOnHour + ":" + vBookedOnMinute + ":00";
						vCreateDate = ReadJSONDate(vDateString, JSONDateFormat.ISO);
						vGuestGroupObj.CreateDate = vCreateDate;
						vGuestGroupObj.Write();
					EndIf;
				EndIf;
				// Acknowledge transaction
				vTX_ID = vMy_ResultMap.Get("TX_ID");
				If Not HTTPQuery(vTX_ID) Then
					Break;
				EndIf;
			Else
				Raise NStr("en = 'The guest group is not filled'; de = 'Die Gästegruppe ist nicht besetzt'; ru = 'Не заполнена группа гостей'");
			EndIf;
		EndDo;
	Except
		vErrorDescription = ErrorDescription();
		vLogEventType = Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "WriteReservation", vLogEventType, , , vErrorDescription);
	EndTry;
EndProcedure // WriteReservation

// -----------------------------------------------------------------------------
//
// Parameters:
//  pText	 - String - html text with tags
// 
// Returns:
//  String - Text without tags
//
Function ReplaceTags(pText)
	vNoTags = StrReplace(pText, "<u><b>", "");
	vNoTags = StrReplace(vNoTags, "</b></u>", "");
	
	Return vNoTags;
EndFunction // ReplaceTags

// -----------------------------------------------------------------------------
//
// Parameters:
//  pMsg - String - Exception message code from iglooroms responce 
// 
// Returns:
//  String - Understandable exception message 
//
Function GetExceptionMsgDescription(pMsg)
	vExcMsg = "";
	If pMsg = "PMSInvCD" Then
		vExcMsg = NStr("en = 'PMS Invalid Code';
					|de = 'PMS Ungültiger Code';
					|ru = 'Неверный код PMS'"); 		
	ElsIf pMsg = "PMSNotAct" Then
		vExcMsg = NStr("en = 'PMS Not Active (property not allowed to use API)';
					|de = 'PMS nicht aktiv (Eigenschaft darf API nicht verwenden)';
					|ru = 'PMS не активен (свойству не разрешено использовать API)'"); 		
	ElsIf pMsg = "PMSInvUserPwd" Then
		vExcMsg = NStr("en = 'Invalid User and/or Password';
					|de = 'Ungültiger Benutzer und/oder Passwort';
					|ru = 'Недействительный пользователь и/или пароль'"); 
	ElsIf pMsg = "ValidUserPwdButDifferentPMS" Then
		vExcMsg = NStr("en = 'Valid credentials but for different PMS';
					|de = 'Gültige Anmeldeinformationen, jedoch für verschiedene PMS';
					|ru = 'Действительные учетные данные, но для другой PMS'"); 		
	ElsIf pMsg = "InvTXID" Then
		vExcMsg = NStr("en = 'Invalid Transaction ID (when acknowledging)';
					|de = 'Ungültige Transaktions-ID (bei Bestätigung)';
					|ru = 'Неверный идентификатор транзакции (при подтверждении)'"); 		
	ElsIf pMsg = "NotRelTXID2PMS" Then
		vExcMsg = NStr("en = 'Transaction ID not related to the connected PMS';
					|de = 'Transaktions-ID, die nicht mit dem verbundenen PMS zusammenhängt';
					|ru = 'Идентификатор транзакции не связан с подключенным PMS'"); 		
	ElsIf pMsg = "TXAlreadyAck" Then
		vExcMsg = NStr("en = 'Transaction ID already acknowledged';
					|de = 'Transaktions-ID bereits bestätigt';
					|ru = 'Идентификатор транзакции уже подтвержден'");
	Else
		vExcMsg = pMsg;
	EndIf;
	
	Return vExcMsg;
EndFunction // GetExceptionMsgDescription

// -----------------------------------------------------------------------------
//
// Parameters:
//  pStatusCode	 - Number - Exception code from hhtp responce
// 
// Returns:
//  String - Understandable exception message
//
Function GetErrorMessage(pStatusCode)
	If pStatusCode = 400 Then
		vMessage = NStr("en='Bad request!';
						|ru='Неверный запрос!';
						|de='Ungültige Anfrage!'");
	ElsIf pStatusCode = 401 Then
		vMessage = NStr("en='Not valid authentication credentials for the operation!';
						|ru='Недопустимые учетные данные для проверки подлинности для операции!';
						|de='Ungültige Authentifizierungsdaten für den Vorgang!'");
	ElsIf pStatusCode = 403 Then
		vMessage = NStr("en='No access the specified operation!';
						|ru='Нет доступа к указанной операции!';
						|de='Kein Zugriff auf die angegebene Operation!'");
	ElsIf pStatusCode = 404 Then
		vMessage = NStr("en='Resource was not found!';
						|ru='Ресурс не найден!';
						|de='Ressource wurde nicht gefunden!'");
	ElsIf pStatusCode = 409 Then
		vMessage = NStr("en='Operation aborted!';
						|ru='Операция прервана!';
						|de='Vorgang abgebrochen!'");
	ElsIf pStatusCode = 429 Then
		vMessage = NStr("en='Too many requests!';
						|ru='Cлишком много запросов!';
						|de='Zu viele Anfragen!'");
	ElsIf pStatusCode = 499 Then
		vMessage = NStr("en='The user canceled the operation!';
						|ru='Пользователь отменил операцию!';
						|de='Der Benutzer hat den Vorgang abgebrochen!'");
	ElsIf pStatusCode = 500 Then
		vMessage = NStr("en='Unknown error!';
						|ru='Неизвестная ошибка!';
						|de='Unbekannter Fehler!'");
	ElsIf pStatusCode = 501 Then
		vMessage = NStr("en='Operation not supported!';
						|ru='Операция не поддерживается!';
						|de='Betrieb wird nicht unterstützt!'");
	ElsIf pStatusCode = 503 Then
		vMessage = NStr("en='Service is unavailable!';
						|ru='Сервис недоступен!';
						|de='Service ist nicht verfügbar!'");
	ElsIf pStatusCode = 504 Then
		vMessage = NStr("en='Timeout expired!';
						|ru='Время ожидания истекло!';
						|de='Timeout abgelaufen!'");
	Else
		vMessage = "";
	EndIf;
	vMessage = NStr("en='Failed to exchange!';
					|ru='Не удалось выполнить обмен!';
					|de='Austausch fehlgeschlagen!'") + ?(Not IsBlankString(vMessage), " " + vMessage, "");
	
	Return vMessage;
EndFunction // GetErrorMessage

#EndRegion