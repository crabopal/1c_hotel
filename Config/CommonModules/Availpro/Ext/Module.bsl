
#Region Public

//-----------------------------------------------------------------------------
Procedure SyncData(pInteractionParameters, pHotelCode, pAmountOfDaysToUpdate = 100, pSkipPricesCacheUpdate = True, pFullUpdate = False, pOnlyLoadReservations = False, pCreatePayments = False, pPaymentMethod = Undefined) Export
	
	Try
		vUpdateCachedPrices = False;
		If pFullUpdate And Not pSkipPricesCacheUpdate Then
			vUpdateCachedPrices = True;
		EndIf;
		
		If pAmountOfDaysToUpdate = 0 Then
			pAmountOfDaysToUpdate = 100;
		EndIf;

		vCurrentSessionDate = CurrentSessionDate();
		
		// Get reservations
		GetBookings(pInteractionParameters, pHotelCode, pCreatePayments, pPaymentMethod);
		
		If Not pOnlyLoadReservations Then
			// Sync data
			DataUpdate(pInteractionParameters, pHotelCode, True, True, pAmountOfDaysToUpdate, pFullUpdate, vUpdateCachedPrices);
			
			// Update interaction parameters times
			ChannelManagers.UpdateLastSyncTime(pInteractionParameters, pFullUpdate, vCurrentSessionDate, "", True, True, True);
		EndIf;
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SyncData", vLogEventType, , , vError);
	EndTry;
	
EndProcedure

//-----------------------------------------------------------------------------
Function Ping(pInteractionParameters, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw", False, "");
	vMessageName 	= "/Test";
	vResponse		= Undefined;
	vSettings		= GetSettings();
	
	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty interaction parameters!";
			Return vResult;
		EndIf;
		
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName,,,, vSettings);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function GetHotelMapping(pInteractionParameters, pHotelCode, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "/GetMapping";
	vResponse		= Undefined;
	vSettings		= GetSettings();
	
	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty interaction parameters!";
			Return vResult;
		EndIf;
		
 		vRequestBody	= GetHotelMappingRequestBody(pInteractionParameters, pHotelCode);
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/xml",, vSettings);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vBodyCheckResult 	= CheckResultBody(vResponse.Body);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If vResult.Success Then
				vParsingResult	= ParseHotelMappingToTables(vBodyCheckResult.BodyStructure);
				vResult.Success	= vParsingResult.Success;
				vResult.Error	= vParsingResult.Error;
				vResult.Result 	= vParsingResult;
			EndIf;
		EndIf;	
						
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function DataUpdate(pInteractionParameters, pHotelCode, pUpdateInventory, pUpdateRates, pAmountOfDaysToUpdate = 100, pFullUpdate = False, pUpdateCachedPrices = False, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, RawResponse, RawRequest", False, "", "", "");
	vMessageName 	= "/Update";
	vResponse		= Undefined;
	vSettings		= GetSettings();
	vRequestBody	= "";
	
	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty interaction parameters!";
			Return vResult;
		EndIf;
		
		vPeriodFrom = CurrentDate();
		vPeriodTo	= vPeriodFrom + 24 * 60 * 60 * pAmountOfDaysToUpdate;

		vRoomTypes		= Undefined;
		vRoomRates		= Undefined;
		vAvailability	= Undefined;
		
 		vRequestBody	= GetDataUpdateRequestBody(pInteractionParameters, pHotelCode, pUpdateInventory, pUpdateRates, vPeriodFrom, vPeriodTo, pFullUpdate, pUpdateCachedPrices, vRoomTypes, vRoomRates, vAvailability);
		If IsBlankString(vRequestBody) Then
			vResult.Success = False;
			vResult.Error 	= "Did not find any mapped room types!";
			Return vResult;	
		EndIf;
		
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/xml",, vSettings);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vBodyCheckResult 	= CheckResultBody(vResponse.Body);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
		EndIf;	
		
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.RawResponse = vRawValue;
		vResult.RawRequest 	= vRequestBody;
	EndIf;
	
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function GetBookings(pInteractionParameters, pHotelCode, pGetRaw = False, pCreatePayments = False, pPaymentMethod = Undefined, pDebugReservations = Undefined) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "/RetrievePending";
	vResponse		= Undefined;
	vSettings		= GetSettings();
	
	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty interaction parameters!";
			Return vResult;
		EndIf;
		
		If pDebugReservations = Undefined Then
	 		vRequestBody	= GetBookingsRequestBody(pInteractionParameters, pHotelCode);
			vURL			= pInteractionParameters.HttpAddress + vMessageName;
			vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/xml",, vSettings);
			vResponseStatus = CheckResponseStatus(vResponse);
		Else
			vResponseStatus = New Structure("Success, Error", True, "");
			vResponse		= New Structure("Body", pDebugReservations);
		EndIf;
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vBodyCheckResult 	= CheckResultBody(vResponse.Body);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If vResult.Success Then
				vResult.Result 	= ProcessBookings(pInteractionParameters, vBodyCheckResult.BodyStructure, pCreatePayments, pPaymentMethod);
				If vResult.Result.Count() > 0 Then 
					ConfirmBookings(pInteractionParameters, pHotelCode, vResult.Result);
				EndIf;
			EndIf;
		EndIf;	
						
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function ConfirmBookings(pInteractionParameters, pHotelCode, pBookings, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw", False, "", "");
	vMessageName 	= "/Confirm";
	vResponse		= Undefined;
	vSettings		= GetSettings();
	
	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty interaction parameters!";
			Return vResult;
		EndIf;
		
 		vRequestBody	= GetBookingConfirmationRequestBody(pInteractionParameters, pHotelCode, pBookings);
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/xml",, vSettings);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vBodyCheckResult 	= CheckResultBody(vResponse.Body);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
		EndIf;	
						
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function SetNewCredentials(pInteractionParameters, pHotelCode, pNewPassword, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "/SetNewCredentials";
	vResponse		= Undefined;
	vSettings		= GetSettings();
	
	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty interaction parameters!";
			Return vResult;
		EndIf;
		
		If Not ValueIsFilled(pNewPassword) Then
			vResult.Success = False;
			vResult.Error 	= "Empty password!";
			Return vResult;	
		EndIf;
		
 		vRequestBody	= GetSetNewCredentialsRequestBody(pInteractionParameters, pHotelCode, pNewPassword);
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/xml",, vSettings);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vBodyCheckResult 	= CheckResultBody(vResponse.Body);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
		EndIf;	
						
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function GetChannelPools(pInteractionParameters, pHotelCode, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "/GetChannels";
	vResponse		= Undefined;
	vSettings		= GetSettings();
	
	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty interaction parameters!";
			Return vResult;
		EndIf;
		
 		vRequestBody	= GetChannelPoolsRequestBody(pInteractionParameters, pHotelCode);
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/xml",, vSettings);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vBodyCheckResult 	= CheckResultBody(vResponse.Body);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If vResult.Success Then
				vResult.Result = ParseChannelPoolsToTable(vBodyCheckResult.BodyStructure);
			EndIf;
		EndIf;	
						
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

#EndRegion

#Region Private

//-----------------------------------------------------------------------------
Function GetSettings();
	vResult = New Structure;
	vResult.Insert("version", "B2018");
	
	Return vResult;
EndFunction

//-----------------------------------------------------------------------------
Function GetDataUpdateRequestBody(pInteractionParameters, pHotelCode, pUpdateInventory, pUpdateRates, pPeriodFrom, pPeriodTo, pFullUpdate, pUpdateCachedPrices, rRoomTypesTable = Undefined, rRoomRatesTable = Undefined, rAvailabilityTable = Undefined)
	
	// Example Full
	//	<?xml version="1.0" encoding="utf-8"?>
	// <message xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	//    <authentication login="MyLog" password="HN3hTQT7" />
	//    <inventoryUpdate hotelCode="4">
	//        <room roomCode="DB">
	//            <inventory>
	//                <availability date="2010-12-28" quantity="1" />
	//                <availability from="2010-12-29" to="2010-12-31" quantity="1" />
	//                <availability date="2011-01-01" quantity="1" />
	//                <availability from="2011-01-02" to="2011-03-31" quantity="1" />
	//                <availability from="2011-04-01" to="2011-12-30" quantity="1" />
	//            </inventory>
	//            <rate rateCode="BAR">
	//                <planning date="2010-12-28" minimumStay="1" unitPrice="210" noArrival="false" isClosed="false"
	// />
	//                <planning from="2010-12-29" to="2010-12-31" minimumStay="1" unitPrice="273"
	// noArrival="false" isClosed="false" />
	//                <planning date="2011-01-01" minimumStay="1" unitPrice="340.0000" noArrival="false"
	// isClosed="false" />
	//                <planning from="2011-01-02" to="2011-03-31" minimumStay="1" unitPrice="294"
	// noArrival="false" isClosed="false" />
	//                <planning from="2011-04-01" to="2011-12-30" minimumStay="1" unitPrice="340.0000"
	// noArrival="false" isClosed="false" />
	//            </rate>
	//            <rate rateCode="PACKAGE1">
	//                <planning date="2010-12-28" minimumStay="1" maximumStay="4" unitPrice="380.0000"
	// noArrival="false" isClosed="false" />
	//                <planning from="2010-12-29" to="2010-12-31" minimumStay="1" unitPrice="380.0000"
	// noArrival="false" noDeparture="false" isClosed="false" />
	//                <planning date="2011-01-01" minimumStay="1" unitPrice="357" noArrival="false" isClosed="false"
	// />
	//                <planning from="2011-01-02" to="2011-03-31" minimumStay="1" maximumStay="99"
	// unitPrice="340.0000" noArrival="false" isClosed="false" />
	//                <planning from="2011-04-01" to="2011-12-30" minimumStay="1" unitPrice="340.0000"
	// noArrival="false" isClosed="false" />
	//            </rate>
	//            <rate rateCode="RACKPRI">
	//                <planning date="2010-12-28" minimumStay="1" unitPrice="380.0000" noArrival="false"
	// isClosed="false" />
	//                <planning from="2010-12-29" to="2010-12-31" minimumStay="1" unitPrice="380.0000"
	// noArrival="false" isClosed="false" />
	//                <planning date="2011-01-01" minimumStay="1" unitPrice="340.0000" noArrival="false"
	// isClosed="false" />
	//                <planning from="2011-01-02" to="2011-03-31" minimumStay="1" unitPrice="340.0000"
	// noArrival="false" isClosed="false" />
	//                <planning from="2011-04-01" to="2011-12-30" minimumStay="1" unitPrice="340.0000"
	// noArrival="false" noDeparture="true" isClosed="false" />
	//            </rate>
	//        </room>
	//        <channels>
	//            <channelPool id="415241-slkjd224524-kjkjdsf455">
	//                <!--close all channels attached to this pool for the specified period-->
	//                <planning from="2011-01-01" to="2011-01-01" isClosed="true" />
	//            </channelPool>
	//        </channels>
	//    </inventoryUpdate>
	// </message>
	
	vResult = "";
	
	vRoomTypes 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes");
	vRoomRates 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates");
	vRoomMappings 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "RoomTypeAndRateMappings");
	vAvailability 	= Undefined;

	If vRoomTypes.Count() > 1 Then
		
		If pUpdateInventory Then
			vAvailability 	= ChannelManagers.GetAvailability(pInteractionParameters, pPeriodFrom, pPeriodTo, pFullUpdate);
		EndIf;
		
		vPricesByAccTypes 	= Undefined;
		vRestrictions		= Undefined;
		If pUpdateRates Then
			vRoomRatesData	= New ValueTable;
			vRoomRatesData.Columns.Add("RoomRate");
			vRoomRatesData.Columns.Add("Prices");
			vRoomRatesData.Columns.Add("Restrictions");
			For Each vRoomRate In vRoomRates Do
				If Not vRoomRate.isDerivated Then
					vRoomRateRef = vRoomRate.RefKey1;
					If vRoomRatesData.Find(vRoomRateRef, "RoomRate") = Undefined Then
						vPricesByAccTypes 	= ChannelManagers.GetPrices(pInteractionParameters, vRoomRateRef, pPeriodFrom, pPeriodTo, pFullUpdate, pUpdateCachedPrices);
						vRestrictions 		= ChannelManagers.GetRestrictions(pInteractionParameters, vRoomRateRef, pPeriodFrom, pPeriodTo, pFullUpdate);
						
						vNewRow 				= vRoomRatesData.Add();
						vNewRow.RoomRate		= vRoomRateRef;
						vNewRow.Prices			= vPricesByAccTypes;
						vNewRow.Restrictions	= vRestrictions;
					EndIf;
				EndIf;
			EndDo;
		EndIf;		
		
		vXMLWriter 		= New XMLWriter;
		vXMLSettings	= New XMLWriterSettings(, "1.0", False, False);
		vXMLWriter.SetString();
		
		vXMLWriter.WriteStartElement("message");
			vXMLWriter.WriteStartElement("authentication");
				vXMLWriter.WriteAttribute("login", pInteractionParameters.Login);
				vXMLWriter.WriteAttribute("password", pInteractionParameters.Password);
			vXMLWriter.WriteEndElement();
			
			vXMLWriter.WriteStartElement("inventoryUpdate");
				vXMLWriter.WriteAttribute("hotelCode", pHotelCode);
				For Each vRoomType In vRoomTypes Do
					If Not vRoomType.isChildRow And vRoomType.isActive Then
						vRoomTypeRef = vRoomType.RefKey1;
						vAccommodationTemplateRef = vRoomType.RefKey2;
						
						vXMLWriter.WriteStartElement("room");
						vXMLWriter.WriteAttribute("roomCode", vRoomType.ID);
						If pUpdateInventory And vAvailability <> Undefined Then
							vXMLWriter.WriteStartElement("inventory");
							vIsForFolioSplit		= vAccommodationTemplateRef.IsForFolioSplit;
							vRoomTypeAvailability 	= vAvailability.FindRows(New Structure("RoomType",vRoomTypeRef));
							For Each vRoomTypeAvailabilityRow In vRoomTypeAvailability Do
								vXMLWriter.WriteStartElement("availability");
								
								If vIsForFolioSplit = True Then
									vBalance = vRoomTypeAvailabilityRow.VacantBeds;	
								Else
									vBalance = vRoomTypeAvailabilityRow.VacantRooms;			
								EndIf;
								
								vXMLWriter.WriteAttribute("from", 		Format(vRoomTypeAvailabilityRow.PeriodFrom, "DF=yyyy-MM-dd"));
								vXMLWriter.WriteAttribute("to", 		Format(vRoomTypeAvailabilityRow.PeriodTo, "DF=yyyy-MM-dd"));
								vXMLWriter.WriteAttribute("quantity", 	String(vBalance));
								
								vXMLWriter.WriteEndElement(); // Availability
							EndDo;
							vXMLWriter.WriteEndElement(); // Inventory	
						EndIf;
						
						If pUpdateRates Then
							For Each vRoomRate In vRoomRates Do
								If Not vRoomRate.isDerivated And vRoomRate.isActive Then
									// Check if room rate mapped to room type in channel manager
									vMappings = vRoomMappings.FindRows(New Structure("RoomID, RateID", vRoomType.ID, vRoomRate.ID));
									If vMappings.Count() > 0 Then
										vRoomRateRef = vRoomRate.RefKey1;
										vRoomRateDataRow = vRoomRatesData.Find(vRoomRateRef, "RoomRate");
										
										If vRoomRateDataRow <> Undefined Then 
											vXMLWriter.WriteStartElement("rate");
											vXMLWriter.WriteAttribute("rateCode", vRoomRate.ID);
											
											vRoomTypeRef = vRoomType.RefKey1;
											vRoomTypePrices = vRoomRateDataRow.Prices.FindRows(New Structure("RoomType", vRoomTypeRef));

											vAccommodationTemplateRef = vRoomType.RefKey2;
											vAccTypes = vAccommodationTemplateRef.AccommodationTypes;
											
											vOverrides = cmGetRoomRateOverrides(vRoomRateRef, vRoomTypeRef.Owner, vAccommodationTemplateRef, vRoomTypeRef);
											
											vPeriodArray	= New Array;
											For Each vRoomTypePriceRow In vRoomTypePrices Do
												If vPeriodArray.Find(vRoomTypePriceRow.Period) = Undefined Then
													vXMLWriter.WriteStartElement("planning");
													
													//Prices
													vPrice 	= 0;
													For Each vAccTypeRow In vAccTypes Do
														vAccommodationTypeRef = vAccTypeRow.AccommodationType;
														vAccommodationTypeIndex = vAccTypes.IndexOf(vAccTypeRow);
														
														If vOverrides.Count() > 0 Then
															vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vAccommodationTypeRef, vAccommodationTypeIndex + 1));
															If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
																vAccommodationTypeRef = vOverrideRows.Get(0).ToAccommodationType;
															EndIf;
														EndIf;
														
														vPricesByAccType = vRoomRateDataRow.Prices.FindRows(New Structure("Period, RoomType, AccommodationType", vRoomTypePriceRow.Period, vRoomTypeRef, vAccommodationTypeRef));
														If vPricesByAccType.Count() > 0 Then
															vPrice = vPrice + vPricesByAccType[0].Price;
															vPeriodArray.Add(vRoomTypePriceRow.Period);
														EndIf;
													EndDo;
													vXMLWriter.WriteAttribute("date", Format(vRoomTypePriceRow.Period, "DF=yyyy-MM-dd"));
													vXMLWriter.WriteAttribute("unitPrice", Format(vPrice, "NFD=4; NDS=.; NG="));

													//Restrictions
													vIsClosed = "false";
													vRoomTypeRestrictions = vRoomRateDataRow.Restrictions.FindRows(New Structure("RoomType, Period", vRoomTypeRef, vRoomTypePriceRow.Period));
													If vRoomTypeRestrictions.Count() = 0 Then
														vRoomTypeRestrictions = vRoomRateDataRow.Restrictions.FindRows(New Structure("RoomType, Period", Catalogs.RoomTypes.EmptyRef(), vRoomTypePriceRow.Period));
													EndIf;
													
													If vRoomTypeRestrictions.Count() > 0 Then
														vRoomTypeRestrictionsRow = vRoomTypeRestrictions[vRoomTypeRestrictions.Count() - 1]; 
														
														If vRoomTypeRestrictionsRow.MLOS > 0 Then
															vXMLWriter.WriteAttribute("minimumStay", 	String(vRoomTypeRestrictionsRow.MLOS));
														Else
															vXMLWriter.WriteAttribute("minimumStay", 	"1");	
														EndIf;
														If vRoomTypeRestrictionsRow.MaxLOS > 0 Then
															vXMLWriter.WriteAttribute("maximumStay", 	String(vRoomTypeRestrictionsRow.MaxLOS));
														Else
															vXMLWriter.WriteAttribute("maximumStay", 	"99");	
														EndIf;
														vXMLWriter.WriteAttribute("noArrival", 		BooleanToString(vRoomTypeRestrictionsRow.CTA));
														vXMLWriter.WriteAttribute("noDeparture", 	BooleanToString(vRoomTypeRestrictionsRow.CTD));
														
														vIsClosed = BooleanToString(vRoomTypeRestrictionsRow.StopSale);
														vXMLWriter.WriteAttribute("isClosed", 		vIsClosed);											
													Else
														vXMLWriter.WriteAttribute("minimumStay", 	"1");	
														vXMLWriter.WriteAttribute("maximumStay", 	"99");	
														vXMLWriter.WriteAttribute("noArrival", 		"false");
														vXMLWriter.WriteAttribute("noDeparture", 	"false");
														vXMLWriter.WriteAttribute("isClosed", 		"false");		
													EndIf;

													
													vOccupancyPrices = vRoomTypes.FindRows(New Structure("RefKey1, isChildRow", vRoomTypeRef, True));
													For Each vOccupancyRow In vOccupancyPrices Do
														vXMLWriter.WriteStartElement("occupancy");
														
														vAccommodationTemplateRef = vOccupancyRow.RefKey2;
														vAccTypes = vAccommodationTemplateRef.AccommodationTypes;
														
														vOverrides = cmGetRoomRateOverrides(vRoomRateRef, vRoomTypeRef.Owner, vAccommodationTemplateRef, vRoomTypeRef);

														vPrice = 0;
														For Each vAccTypeRow In vAccTypes Do
															vAccommodationTypeRef = vAccTypeRow.AccommodationType;
															vAccommodationTypeIndex = vAccTypes.IndexOf(vAccTypeRow);
															
															If vOverrides.Count() > 0 Then
																vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vAccommodationTypeRef, vAccommodationTypeIndex + 1));
																If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
																	vAccommodationTypeRef = vOverrideRows.Get(0).ToAccommodationType;
																EndIf;
															EndIf;
															
															vPricesByAccType = vRoomRateDataRow.Prices.FindRows(New Structure("Period, RoomType, AccommodationType", vRoomTypePriceRow.Period, vRoomTypeRef, vAccommodationTypeRef));
															If vPricesByAccType.Count() > 0 Then
																vPrice = vPrice + vPricesByAccType[0].Price;
															EndIf;
														EndDo;
														
														vXMLWriter.WriteAttribute("adultCount", 	String(vAccommodationTemplateRef.NumberOfAdults));
														vXMLWriter.WriteAttribute("childCount", 	String(vAccommodationTemplateRef.NumberOfChildren + vAccommodationTemplateRef.NumberOfTeenagers));
														vXMLWriter.WriteAttribute("infantCount", 	String(vAccommodationTemplateRef.NumberOfInfants));
														vXMLWriter.WriteAttribute("unitPrice", 		Format(vPrice, "NFD=4; NDS=.; NG="));
														vXMLWriter.WriteAttribute("isClosed", 		vIsClosed);
														vXMLWriter.WriteEndElement(); // Planning	
													EndDo;

													vXMLWriter.WriteEndElement(); // Planning
												EndIf;
											EndDo;									
											
											vXMLWriter.WriteEndElement(); // Rate
										EndIf;
									EndIf;
								EndIf;
							EndDo;
						EndIf;
		            	vXMLWriter.WriteEndElement(); // Room
					EndIf;
				EndDo;
			vXMLWriter.WriteEndElement(); //IinventoryUpdate
		vXMLWriter.WriteEndElement(); // Message

		vResult = vXMLWriter.Close();
	EndIf;
	
	rRoomRatesTable 	= vRoomRates;
	rRoomTypesTable		= vRoomTypes;
	rAvailabilityTable	= vAvailability;
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function GetHotelMappingRequestBody(pInteractionParameters, pHotelCode)
	
	// Example
	// <?xml version="1.0" encoding="utf-8"?>
	// <message xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	//    <authentication login="MyLogin" password="MyPassword" />
	//    <mappingRequest hotelCode="1234" language="en-US" />
	// </message>
	
	vResult = "";
	
	vXMLWriter 		= New XMLWriter;
	vXMLSettings	= New XMLWriterSettings(, "1.0", False, False);
	vXMLWriter.SetString(vXMLSettings);
	
	vXMLWriter.WriteStartElement("message");
		vXMLWriter.WriteStartElement("authentication");
			vXMLWriter.WriteAttribute("login", pInteractionParameters.Login);
			vXMLWriter.WriteAttribute("password", pInteractionParameters.Password);
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("mappingRequest");
			vXMLWriter.WriteAttribute("hotelCode", pHotelCode);
			vXMLWriter.WriteAttribute("language", "en-US");
		vXMLWriter.WriteEndElement();
	vXMLWriter.WriteEndElement();

	vResult = vXMLWriter.Close();
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function GetBookingsRequestBody(pInteractionParameters, pHotelCode)
	
	// Example
	// <?xml version="1.0" encoding="utf-8"?>
	// <message>
	//	<authentication login="mycompany" password="azerty"/>
	//	<bookings hotelCode="4561" />
	// </message>

	
	vResult = "";
	
	vXMLWriter 		= New XMLWriter;
	vXMLSettings	= New XMLWriterSettings(, "1.0", False, False);
	vXMLWriter.SetString(vXMLSettings);
	
	vXMLWriter.WriteStartElement("message");
		vXMLWriter.WriteStartElement("authentication");
			vXMLWriter.WriteAttribute("login", pInteractionParameters.Login);
			vXMLWriter.WriteAttribute("password", pInteractionParameters.Password);
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("bookings");
			vXMLWriter.WriteAttribute("hotelCode", pHotelCode);
		vXMLWriter.WriteEndElement();
	vXMLWriter.WriteEndElement();

	vResult = vXMLWriter.Close();
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function GetBookingConfirmationRequestBody(pInteractionParameters, pHotelCode, pBookings)
	
	// Example
	// <?xml version="1.0" encoding="utf-8"?>
	// <message xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	//	<authentication login="mycompany" password="azerty"/>
	//	<bookingConfirmations hotelCode="123000">
	// 		<bookingConfirmation id="JKTJG" uniqueId="01" status="Create" providerId="Your Reference number" />
	// 		<bookingConfirmation id="JKTJG" uniqueId="02" status="Create" providerId="Your Reference number" />
	//	</bookingConfirmations>
	// </message> 
	
	vResult = "";
	
	If pBookings <> Undefined And pBookings.Count() > 0 Then
		vXMLWriter 		= New XMLWriter;
		vXMLSettings	= New XMLWriterSettings(,"1.0", False, False);
		vXMLWriter.SetString(vXMLSettings);
		
		vXMLWriter.WriteStartElement("message");
			vXMLWriter.WriteStartElement("authentication");
				vXMLWriter.WriteAttribute("login", pInteractionParameters.Login);
				vXMLWriter.WriteAttribute("password", pInteractionParameters.Password);
			vXMLWriter.WriteEndElement();
			
			vXMLWriter.WriteStartElement("bookingConfirmations");
				vXMLWriter.WriteAttribute("hotelCode", pHotelCode);
				For Each vRow In pBookings Do
					If vRow.Success Then 
						vXMLWriter.WriteStartElement("bookingConfirmation");
						vXMLWriter.WriteAttribute("id", 		vRow.id);
						vXMLWriter.WriteAttribute("uniqueId", 	vRow.uniqueId);
						vXMLWriter.WriteAttribute("status", 	vRow.status);
						vXMLWriter.WriteAttribute("providerId", vRow.providerId);
						vXMLWriter.WriteEndElement();
					EndIf;
				EndDo;
			vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement();

		vResult = vXMLWriter.Close();
	EndIf;
	
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function GetSetNewCredentialsRequestBody(pInteractionParameters, pHotelCode, pNewPassword)
	
	// Example
	// <?xml version="1.0" encoding="utf-8"?>
	// <message xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	//    <authentication login="MyLogin" password="MyPassword" />
	//    <mappingRequest hotelCode="1234" language="en-US" />
	// </message>
	
	vResult = "";
	
	vXMLWriter 		= New XMLWriter;
	vXMLSettings	= New XMLWriterSettings(, "1.0", False, False);
	vXMLWriter.SetString(vXMLSettings);
	
	vXMLWriter.WriteStartElement("message");
		vXMLWriter.WriteStartElement("authentication");
			vXMLWriter.WriteAttribute("login", pInteractionParameters.Login);
			vXMLWriter.WriteAttribute("password", pInteractionParameters.Password);
			vXMLWriter.WriteAttribute("hotelCode", pHotelCode);
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("setNewCredentials");
			vXMLWriter.WriteAttribute("login", pInteractionParameters.Login);
			vXMLWriter.WriteAttribute("password", pNewPassword);
		vXMLWriter.WriteEndElement();
	vXMLWriter.WriteEndElement();

	vResult = vXMLWriter.Close();
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function GetChannelPoolsRequestBody(pInteractionParameters, pHotelCode)
	
	// Example
	//	<?xml version="1.0" encoding="utf-8"?>
	//	<message xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	//	xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	//	<authentication login="MyLog" password="MyPass" />
	//	<channelPools hotelId="4" />
	//	</message>

	vResult = "";
	
	vXMLWriter 		= New XMLWriter;
	vXMLSettings	= New XMLWriterSettings(, "1.0", False, False);
	vXMLWriter.SetString(vXMLSettings);
	
	vXMLWriter.WriteStartElement("message");
		vXMLWriter.WriteStartElement("authentication");
			vXMLWriter.WriteAttribute("login", pInteractionParameters.Login);
			vXMLWriter.WriteAttribute("password", pInteractionParameters.Password);
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("channelPools");
			vXMLWriter.WriteAttribute("hotelId", pHotelCode);
		vXMLWriter.WriteEndElement();
	vXMLWriter.WriteEndElement();

	vResult = vXMLWriter.Close();
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function ProcessBookings(pInteractionParameters, pXMLStructure, pCreatePayments = False, pPaymentMethod = Undefined)
	
	vResult = New ValueTable;
	vResult.Columns.Add("Success");	
	vResult.Columns.Add("Error");
	vResult.Columns.Add("id");
	vResult.Columns.Add("uniqueId");
	vResult.Columns.Add("status");
	vResult.Columns.Add("providerId");
	
	vBookings = Undefined;
	
	vPaymentMethod = "ExternalPayment";
	If pPaymentMethod <> Undefined Then
		vPaymentMethod = pPaymentMethod.Code;
	EndIf;
	
	If pXMLStructure <> Undefined And pXMLStructure.Property("message") And pXMLStructure.message.Property("bookings") And pXMLStructure.message.bookings.Property("booking", vBookings) And vBookings <> Undefined Then
		
		vReservationStatuses		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "reservationstatuses", "ID");
		If vReservationStatuses.Columns.Find("ID") = Undefined Or vReservationStatuses.Count() = 0 Then
			vError			= "Failed to find reservation statuses mappings!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vError);
			Return vResult;
		EndIf;
		
		vBookingsArray = PropertyToArray(vBookings);
		For Each vBookingRow In vBookingsArray Do
			vCurrencyCode = Undefined;
			vBookingRow.Property("currency", vCurrencyCode);
			
			vBookingID = Undefined;
			vBookingRow.Property("id", vBookingID);

			vCustomer = Undefined;
			vBookingRow.Property("customer", vCustomer);
			
			vCustomerContact = Undefined;
			If vCustomer <> Undefined Then
				vCustomer.Property("contact", vCustomerContact);	
			EndIf;
			
			vSource			= Undefined;
			vSourceID		= Undefined;
			vBookingRow.Property("originId", vSourceID);			
			vSources 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "agents", , , , vSourceID);
			If vSources.Count() = 0 Then
				vError			= "Failed to find agents data by ID:" + vSourceID + "; Booking №:" + vBookingID;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vError);
			Else
				vSource = vSources[0].RefKey1;
			EndIf;
			
			vPaidAmount = 0;
			vBookingRow.Property("paidAmount", vPaidAmount);
			If ValueIsFilled(vPaidAmount) Then
				Try
					vPaidAmount = Number(vPaidAmount);
				Except
					vBookingRow.Property("paidAmount", vPaidAmount);
					vError			= "Failed to convert paid amount to number:" + vPaidAmount + "; Booking №:" + vBookingID;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vError);
					vPaidAmount = 0;
				EndTry;
			Else
				vPaidAmount = 0;	
			EndIf;
			
			vRooms = Undefined;
			If vBookingRow.Property("rooms") And vBookingRow.rooms.Property("room", vRooms) And vRooms <> Undefined Then
				vRoomsArray = PropertyToArray(vRooms);
				
				// Cancelllatons first
				For Each vRoomRow In vRoomsArray Do									
					vRoomID	= Undefined;
					vRoomRow.Property("uniqueId", vRoomID);
															
					vStatus = Undefined;
					vRoomRow.Property("status", vStatus);
					
					vStatus = TrimAll(vStatus);
					
					If vStatus = "Create" Or vStatus = "Modify" Then
						Continue;
					ElsIf vStatus = "Cancel" Then
						vNewResultRow 			= vResult.Add();
						vNewResultRow.id 		= vBookingID;
						vNewResultRow.uniqueId 	= vRoomID;
						vNewResultRow.Success 	= False;
						vNewResultRow.status 	= vStatus;
						
						vReservationStatusRow 		= vReservationStatuses.Find(vStatus, "ID");
						If vReservationStatusRow = Undefined Then
							vNewResultRow.Success = False;
							vNewResultRow.Error	= "Failed to find reservation status by ID:" + vStatus + "; Booking №:" + vBookingID + "; Room ID:" + vRoomID;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vNewResultRow.Error);
							Continue;
						Else
							vReservationStatus = vReservationStatusRow.RefKey1;
						EndIf;
						vCancelResult 				= cmCancelGroupReservation(vBookingID, TrimAll(pInteractionParameters.Hotel.Code), pInteractionParameters.Code, , , , vReservationStatus);
						vNewResultRow.Success 		= True;
						vNewResultRow.providerId 	= vBookingID;	
					EndIf;
				EndDo;
				
				// New and modify
				For Each vRoomRow In vRoomsArray Do									
					vRoomID	= Undefined;
					vRoomRow.Property("uniqueId", vRoomID);
					
					vStatus = Undefined;
					vRoomRow.Property("status", vStatus);
					If Not ValueIsFilled(vStatus) Then
						vNewResultRow 			= vResult.Add();
						vNewResultRow.id 		= vBookingID;
						vNewResultRow.uniqueId 	= vRoomID;
						vNewResultRow.Success 	= False;
					    vNewResultRow.status 	= vStatus;
						vNewResultRow.Success = False;
						vNewResultRow.Error	= "Failed to get booking status:" + vStatus + "; Booking №:" + vBookingID + "; Room ID:" + vRoomID;
						vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vNewResultRow.Error);
						Continue;
					EndIf;
					
					vStatus = TrimAll(vStatus);
					
					If vStatus = "Create" Or vStatus = "Modify" Then
						vNewResultRow 			= vResult.Add();
						vNewResultRow.id 		= vBookingID;
						vNewResultRow.uniqueId 	= vRoomID;
						vNewResultRow.Success 	= False;
					    vNewResultRow.status 	= vStatus;
						
						vRoomTypeCode = Undefined;
						vRoomRow.Property("id", vRoomTypeCode);
						If Not ValueIsFilled(vRoomTypeCode) Then
							vRoomRow.Property("roomCode", vRoomTypeCode);
						EndIf;
						
						vRoomTypesData = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes",,,, vRoomTypeCode);
						If vRoomTypesData.Count() = 0 Then
							vNewResultRow.Success = False;
							vNewResultRow.Error	= "Failed to find roomtypes data by ID:" + vRoomTypeCode + "; Booking №:" + vBookingID + "; Room ID:" + vRoomID;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vNewResultRow.Error);
							Continue;
						EndIf;
						
						vRoomRatePlanXDTO	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "RoomRatePlan"));
						vPricesXDTO 		= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
						vTotalPeriodFrom 	= Undefined;
						vTotalPeriodTo		= Undefined;
						vFirstRoomRate		= Undefined;
						vStays 				= Undefined;
						vStaysError			= False;
						If vRoomRow.Property("stays") And vRoomRow.stays.Property("stay", vStays) And vStays <> Undefined Then
							vStaysArray	= PropertyToArray(vStays);
							itsFirst 	= True;
							For Each vStaysRow In vStaysArray Do
								vRoomRateCode = Undefined;
								vStaysRow.Property("rateCode", vRoomRateCode);
								vRoomRatesData = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates", , , , vRoomRateCode);
								If vRoomRatesData.Count() = 0 Or Not ValueIsFilled(vRoomRateCode) Then
									vNewResultRow.Error		= "Failed to find roomrates data by ID:" + vRoomRateCode + "; Booking №:" + vBookingID + "; Room ID:" + vRoomID;;
									vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
									InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vNewResultRow.Error);
									vRoomRate 		= pInteractionParameters.Hotel.RoomRate;
									vFirstRoomRate 	= vRoomRate;
								Else
									vRoomRate = vRoomRatesData[0].RefKey1;
									If itsFirst Then
										vFirstRoomRate 	= vRoomRate;
									EndIf;
								EndIf;
								vPeriodFrom = Undefined;
								vPeriodTo 	= Undefined;
								vStaysRow.Property("from", vPeriodFrom);
								vStaysRow.Property("to", vPeriodTo);
								
								vPeriodFrom = StrReplace(vPeriodFrom, "-", "");
								vPeriodFrom	= Date(vPeriodFrom);
								
								vPeriodTo 	= StrReplace(vPeriodTo, "-", "");
								vPeriodTo	= Date(vPeriodTo);
								
								If Not ValueIsFilled(vPeriodFrom) Or Not ValueIsFilled(vPeriodTo) Then
									vNewResultRow.Success 	= False;
									vNewResultRow.Error		= "Failed to get booking period; Booking №:" + vBookingID + "; Room ID:" + vRoomID;;
									vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
									InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vNewResultRow.Error);
									vStaysError = True;
									Break;								
								EndIf;
								
								If vTotalPeriodFrom = Undefined Or vTotalPeriodFrom > vPeriodFrom Then
									vTotalPeriodFrom = vPeriodFrom;
								EndIf;
								
								If vTotalPeriodTo = Undefined Or vTotalPeriodTo < vPeriodTo Then
									vTotalPeriodTo = vPeriodTo;
								EndIf;
								
								If Not itsFirst Then
									vRoomRatePlanRow 				= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "RoomRatePlanRow"));
									vRoomRatePlanRow.RoomRateCode 	= vRoomRate.Code;
									vRoomRatePlanRow.Period 		= vPeriodFrom;
									vRoomRatePlanXDTO.RoomRatePlanRows.Add(vRoomRatePlanRow);
								EndIf;
								
								vUnitPriceAfterTax = Undefined;
								vStaysRow.Property("unitPriceAfterTax", vUnitPriceAfterTax);
								If ValueIsFilled(vUnitPriceAfterTax) Then
									vCurrentPeriod = vPeriodFrom;
									While vCurrentPeriod <= vPeriodTo Do 
										vPricePerDateRow 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricePerDateRow"));
										vPricePerDateRow.Date 		= vCurrentPeriod;
										vPricePerDateRow.Price 		= Round(Number(vUnitPriceAfterTax), 2, 1);
										vPricePerDateRow.Currency 	= pInteractionParameters.Currency.Code;
										vPricesXDTO.PricePerDateRow.Add(vPricePerDateRow);
										
										vCurrentPeriod = vCurrentPeriod + 24 * 60 * 60;
									EndDo;
								EndIf;
								
								itsFirst = False;
							EndDo;							
						Else
							vNewResultRow.Success 	= False;
							vNewResultRow.Error		= "Failed to get booking stays; Booking №:" + vBookingID + "; Room ID:" + vRoomID;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vNewResultRow.Error);
							Continue;	
						EndIf;
						
						If vStaysError Then
							Continue;
						EndIf;
						
						vExternalGroupReservation 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservation"));
						vReservationStatusRow 		= vReservationStatuses.Find(vStatus, "ID");
						If vReservationStatusRow = Undefined Then
							vNewResultRow.Success = False;
							vNewResultRow.Error	= "Failed to find reservation status by ID:" + vStatus + "; Booking №:" + vBookingID + "; Room ID:" + vRoomID;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vNewResultRow.Error);
							Continue;
						Else
							vReservationStatus = vReservationStatusRow.RefKey1;
						EndIf;
						
						// Extras
						vExtras = Undefined;
						vChargeExtraServicesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServices")); 
						If vRoomRow.Property("extras") And vRoomRow.extras.Property("extra", vExtras) And vExtras <> Undefined Then
							vExtrasArray 	= PropertyToArray(vExtras);
							For Each vExtraRow In vExtrasArray Do
								vService		= Undefined;
								vServiceCode 	= Undefined;
								vExtraRow.Property("extraCode", vServiceCode);
								vServicesData = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "services",,,, vServiceCode );
								If vServicesData.Count() = 0 Then
									vNewResultRow.Success 	= False;
									vNewResultRow.Error		= "Failed to find services data by ID:" + vExtraRow.extraCode + "; Booking №:" + vBookingID + "; Room ID:" + vRoomID;;
									vLogEventType 			= Enums.ExternalSystemEventTypes.Error;
									InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vNewResultRow.Error);
									Continue;;
								Else
									vService = vServicesData[0].RefKey1;
								EndIf;
								
								vPeriodFrom = Undefined;
								vPeriodTo 	= Undefined;
								vExtraRow.Property("from", vPeriodFrom);
								vExtraRow.Property("to", vPeriodTo);
								
								vPeriodFrom = StrReplace(vPeriodFrom, "-", "");
								vPeriodFrom	= Date(vPeriodFrom);
								
								vPeriodTo 	= StrReplace(vPeriodTo, "-", "");
								vPeriodTo	= Date(vPeriodTo);
								
								vPricingType = Undefined;
								vExtraRow.Property("pricingType", vPricingType);
								
								vPrice = 0;
								If vExtraRow.Property("unitPrice") Then
									vPrice = Number(vExtraRow.unitPrice);
								EndIf;
								
								If vPricingType = "PerStay" Then
									vDays 	= (vPeriodTo - vPeriodFrom) / (24 * 60 * 60);
									vPrice 	= vPrice / (vDays + 1);
								EndIf;
								
								vQuantity = 1;
								If vExtraRow.Property("quantity") Then
									vQuantity = Number(vExtraRow.quantity);
								EndIf;
								
								vCurrentPeriod = vPeriodFrom;
								While vCurrentPeriod <= vPeriodTo Do 
									vChargeExtraServiceRow 				= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServiceRow"));
									vChargeExtraServiceRow.ChargeDate 	= vCurrentPeriod;
									vChargeExtraServiceRow.Price 		= Round(vPrice, 2, 1);
									vChargeExtraServiceRow.Quantity 	= vQuantity;
									vChargeExtraServiceRow.Service 		= vService.Code;
									vChargeExtraServiceRow.Currency 	= pInteractionParameters.Currency.Code;
									vChargeExtraServicesXDTO.ChargeExtraServiceRow.Add(vChargeExtraServiceRow);
									
									vCurrentPeriod = vCurrentPeriod + (24 * 60 * 60);
								EndDo;
								
							EndDo;
						EndIf;
						
						vCheckOutTime 	= ?(ValueIsFilled(vFirstRoomRate) And ValueIsFilled(vFirstRoomRate.ReferenceHour), vFirstRoomRate.ReferenceHour, '00010101120000');
						vCheckInTime 	= ?(ValueIsFilled(vFirstRoomRate) And ValueIsFilled(vFirstRoomRate.DefaultCheckInTime), vFirstRoomRate.DefaultCheckInTime, vCheckOutTime);
						vGuests = Undefined;
						If vRoomRow.Property("guests") And vRoomRow.guests.Property("guest", vGuests) And vGuests <> Undefined Then
							vGuestsArray 	= PropertyToArray(vGuests);
							vGuestsIndex 	= 1;
							vRoomUUID		= String(New UUID);
							
							
							vAdults 	= 0;
							vChilds 	= 0;
							vInfants 	= 0;
							
							For Each vGuestRow In vGuestsArray Do
								vAgeRange = Undefined;
								// Should be:
								// Adult 	: 0
								// Child 	: 1
								// Infant 	: 2
								vGuestRow.Property("ageRange", vAgeRange);
								If vAgeRange = "0" Then
									vAdults = vAdults + 1;
								ElsIf vAgeRange = "1" Then
									vChilds = vChilds + 1;
								ElsIf vAgeRange = "2" Then
									vInfants = vInfants + 1;
								Else
									vAdults = vAdults + 1;	
								EndIf;	
							EndDo;
							
							vTotalGuests = vAdults + vChilds + vInfants;
							
							vChildAge		= pInteractionParameters.Hotel.ChildrenMaxAge;
							vInfantAge		= pInteractionParameters.Hotel.InfantsMaxAge;

							vAgesArray 		= New Array;
							
							vChildsCount 	= 1;
							While vChildsCount <= vChilds Do
								vAgesArray.Add(vChildAge);
								vChildsCount = vChildsCount + 1;
							EndDo;
							
							vInfantsCount	= 1;
							While vInfantsCount <= vInfants Do
								vAgesArray.Add(vInfantAge);
								vInfantsCount = vInfantsCount + 1;
							EndDo;
							
							vRoomType = vRoomTypesData[0].RefKey1;
							
							// Seearch template by ages
							vAccomodationTemplateList = cmGetAccommodationTemplateDetailsByGuestsQuantity(vAdults, vChilds + vInfants, vAgesArray, pInteractionParameters.Hotel);
							// Filter Templates by roomType
							vClearArray = New Array;
							For Each vTemplateRow In vAccomodationTemplateList Do
								If vTemplateRow.AccommodationTemplate.RoomTypes.Count() > 0 Then
									If vTemplateRow.AccommodationTemplate.RoomTypes.Find(vRoomType, "RoomType") = Undefined Then
										If ValueIsFilled(vRoomType) And Not vRoomType.IsFolder And ValueIsFilled(vRoomType.RoomClass) And vTemplateRow.AccommodationTemplate.RoomTypes.Find(vRoomType.RoomClass, "RoomClass") <> Undefined Then
											Continue;
										Else
											vClearArray.Add(vTemplateRow);
										EndIf;
									EndIf;
								EndIf;
							EndDo;
							For Each vClearRow In vClearArray Do
								vAccomodationTemplateList.Delete(vClearRow);
							EndDo;
							
							// Get default template
							vAccomodationTemplate 		= Undefined;
							If vAccomodationTemplateList = Undefined or vAccomodationTemplateList.Count() = 0 Then
								vAccomodationTemplate =  vRoomTypesData[0].RefKey2;
							Else
								vAccomodationTemplate =  vAccomodationTemplateList[0].AccommodationTemplate;	
							EndIf;
							
							vAccomodationTypes		= vAccomodationTemplate.AccommodationTypes;
							If vAccomodationTypes.Count() = 0 Then
								vNewResultRow.Success = False;
								vNewResultRow.Error	= "Empty accomodation template! " + vAccomodationTemplate + "; Booking №:" + vBookingID + "; Room ID:" + vRoomID;
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vNewResultRow.Error);
								Continue;
							EndIf;
							
							vCustomerIsClient = False;
							vAgesIndex	= 0;
							For Each vGuestRow In vGuestsArray Do
								
								vComment 		= "";
								vCustomerXDTO	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
								If vCustomer <> Undefined Then
									vCustomer.Property("firstName", vCustomerXDTO.ClientFirstName);
									vCustomer.Property("lastName", vCustomerXDTO.ClientLastName);
									If vCustomerContact <> Undefined Then
										vCustomerContact.Property("email", vCustomerXDTO.ClientEMail);
										vCustomerContact.Property("phone", vCustomerXDTO.ClientPhone);
										
										vAddress = Undefined;
										If vCustomerContact.Property("address", vAddress) Then
											vAddressText = "";
											vAddress.Property("__TextValue", vAddressText);
											vCity		 = "";
											vAddress.Property("city", vCity);
											vAddressText = string(vCity) + "," + vAddressText;
											
											vCitizenship = "";
											vAddress.Property("country", vCitizenship);
											
											vCustomerXDTO.Address 			= ?(IsBlankString(vAddressText), "", ", , , , " + vAddressText);
											vCustomerXDTO.ClientCitizenship = vCitizenship;
										EndIf;
									EndIf;
									If vCustomer.Property("comment") Then
										vCustomer.comment.Property("__TextValue", vComment); 	
									EndIf;
								EndIf;
								
								vClientXDTO	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
								vGuestRow.Property("firstName", vClientXDTO.ClientFirstName);
								vGuestRow.Property("lastName", vClientXDTO.ClientLastName);
								
								vTitle = "";
								vGuestRow.Property("title", vTitle);

								If StrFind(vTitle, "MRS") Then
									vClientXDTO.ClientSex = "F";	
								EndIf;
								
								vCurrentClientIsCustomer = False;
								If vClientXDTO.ClientFirstName = vCustomerXDTO.ClientFirstName And vClientXDTO.ClientLastName = vCustomerXDTO.ClientLastName Then
									vCustomerIsClient 			= True;
									vCurrentClientIsCustomer 	= True;
								EndIf;
								
								If vGuestsIndex <= vAccomodationTypes.Count() Then 
									vAccomodationType = vAccomodationTypes[vGuestsIndex-1].AccommodationType.Code;
								Else 
									vAccomodationType = vAccomodationTypes[vAccomodationTypes.Count()-1].AccommodationType.Code		
								EndIf;
								
								vExternalGroupReservationRow 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/","WriteExternalGroupReservationRow"));
								vExternalGroupReservationRow.ReservationCode 	= vBookingID + "/" + vRoomID + "/" + String(vGuestsIndex);
								vExternalGroupReservationRow.GroupCode 			= vBookingID;
								vExternalGroupReservationRow.GroupClient 		= vCustomerXDTO;
								vExternalGroupReservationRow.ReservationStatus	= vReservationStatus.Code;
								vExternalGroupReservationRow.PeriodFrom			= vTotalPeriodFrom + (vCheckInTime - BegOfDay(vCheckInTime));
								vExternalGroupReservationRow.PeriodTo			= vTotalPeriodTo + (vCheckOutTime - BegOfDay(vCheckOutTime));;
								vExternalGroupReservationRow.Hotel				= pInteractionParameters.Hotel.Code;
								vExternalGroupReservationRow.RoomType			= TrimAll(vRoomType.Code);
								vExternalGroupReservationRow.AccommodationType	= TrimAll(vAccomodationType);
								vExternalGroupReservationRow.NumberOfRooms		= 1;
								vExternalGroupReservationRow.NumberOfPersons	= 1;
								vExternalGroupReservationRow.ExternalSystemCode	= pInteractionParameters.InteractionID;
								vExternalGroupReservationRow.DoPosting			= True;
								vExternalGroupReservationRow.RoomRate			= TrimAll(vFirstRoomRate.Code);
								
								vCommentFromRoomRate = "";
								vRemarksAmenitiesList = GetAmenitiesList();
								vRemarksAmenity = vFirstRoomRate.ReservationRemarksAmenity;
								If ValueIsFilled(vRemarksAmenity) Then
									For Each vRemarksAmenitiesListItem In vRemarksAmenitiesList Do
										If vRemarksAmenitiesListItem.Value = vRemarksAmenity Then
											vRemarksAmenitiesListItem.Check = True; 
										EndIf;
									EndDo;	
								EndIf;
								vSTag = Char(8226) + " ";
								vETag = " " + Char(8226);
								If vRemarksAmenitiesList <> Undefined Then
									vAmenitiesStr = "";
									For Each vUCItem In vRemarksAmenitiesList Do
										If vUCItem.Check Then
											vAmenitiesStr = vAmenitiesStr + ?(IsBlankString(vAmenitiesStr), vSTag, ", ") + TrimAll(vUCItem.Value);
										EndIf;
									EndDo;
									If Not IsBlankString(vAmenitiesStr) Then
										vAmenitiesStr = vAmenitiesStr + vETag;
									EndIf;
									vCommentFromRoomRate = TrimAll(vAmenitiesStr);
								EndIf; 
								If vCommentFromRoomRate <> "" Then  
									vComment = vComment + Chars.LF + vCommentFromRoomRate;	
								EndIf;
								
								vExternalGroupReservationRow.ReservationRemarks = vComment; 
								vExternalGroupReservationRow.Room = vRoomUUID;
								
								If vGuestsIndex = 1 And ValueIsFilled(vAccomodationTemplate) Then
									vExternalGroupReservationRow.AccommodationTemplate = TrimR(vAccomodationTemplate.Code);
								EndIf;
								
								If vCurrentClientIsCustomer Then
									vExternalGroupReservationRow.Client = CopyXDTO(vCustomerXDTO, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
								Else
									vExternalGroupReservationRow.Client = vClientXDTO;
								EndIf;
								
								If (vTotalGuests - vGuestsIndex) < (vChilds + vInfants) Then
									vExternalGroupReservationRow.GuestAge		= vAgesArray[vAgesIndex];
									vAgesIndex = vAgesIndex + 1;
								EndIf;
								
								If Not vCustomerIsClient Then
									vExternalGroupReservationRow.ContactPerson 	= vCustomerXDTO.ClientLastName + " " + vCustomerXDTO.ClientFirstName + " " + vCustomerXDTO.ClientPhone + " " + vCustomerXDTO.ClientEMail;
								EndIf;
								
								If vSource <> Undefined Then
									vContract = vSource.Contract;
									If Not ValueIsFilled(vContract) Then
										vValidContracts = cmGetListOfValidContracts(vSource, vTotalPeriodFrom, vTotalPeriodTo, CurrentSessionDate());
										If vValidContracts.Count() = 1 Then
											vContract = vValidContracts.Get(0).Value;
										EndIf;
									EndIf;
									vExternalGroupReservationRow.Agent			= TrimAll(vSource.Code);
									vExternalGroupReservationRow.Customer		= TrimAll(vSource.Code);
									vExternalGroupReservationRow.Contract		= TrimAll(vContract.Code);
								EndIf;
								
								If vGuestsIndex = 1 Then
									vExternalGroupReservationRow.PricesPerDate			= vPricesXDTO;
									vExternalGroupReservationRow.ChargeExtraServices	= CopyXDTO(vChargeExtraServicesXDTO, 	XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServices"));
								Else										
									vPricesCopy = CopyXDTO(vPricesXDTO, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
									vPricesCopy = ResetXDTOPrices(vPricesCopy);									
									vExternalGroupReservationRow.PricesPerDate	= vPricesCopy;
								EndIf;
								
								vExternalGroupReservationRow.RoomRatePlan			= CopyXDTO(vRoomRatePlanXDTO, 			XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "RoomRatePlan"));
								vExternalGroupReservation.WriteExternalGroupReservationRow.Add(vExternalGroupReservationRow);
								
								vGuestsIndex = vGuestsIndex + 1;
							EndDo;
						EndIf;
						
						vAnswerXDTO = cmWriteExternalGroupReservation(vExternalGroupReservation, , True);
						If ValueIsFilled(vAnswerXDTO.ErrorDescription) Then
							vNewResultRow.Success = False;
							vNewResultRow.Error	= "ru = 'Неудалось создать бронь по причине: '" + vAnswerXDTO.ErrorDescription;;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vNewResultRow.Error);
							Continue;
						Else
							vNewResultRow.Success 		= True;
							vNewResultRow.providerId 	= vBookingID;
							If vPaidAmount > 0 And pCreatePayments = True Then
								Try
									vExternalPaymentData = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/","ExternalPaymentData"));
									vExternalPaymentData.ExternalPaymentCode = vBookingID;
									
									vCurrency = pInteractionParameters.Currency.Code;
									
									If Not ValueIsFilled(vCurrency) Then
										vCurrency = vAnswerXDTO.Currency; 
									EndIf;
									
									vExternalPaymentResult = cmWriteExternalPayment(,vAnswerXDTO.GuestGroup,,,,,,vPaymentMethod,vPaidAmount,vCurrency,,pInteractionParameters.Hotel,pInteractionParameters.InteractionID,,,,,,,,"XDTO",vExternalPaymentData);
									If ValueIsFilled(vExternalPaymentResult.ErrorDescription) Then
										vError	= "ru = 'Неудалось создать платеж по причине: '" + vExternalPaymentResult.ErrorDescription;
										vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
										InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vError);
										Continue;
										
									EndIf;
								Except
									vError	= "ru = 'Неудалось создать платеж по причине: '" + ErrorDescription();
									vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
									InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vError);
									Continue;								
								EndTry;
							EndIf;
							
						EndIf;
					ElsIf vStatus = "Cancel" Then
						Continue;	
					Else
						vNewResultRow 			= vResult.Add();
						vNewResultRow.id 		= vBookingID;
						vNewResultRow.uniqueId 	= vRoomID;
						vNewResultRow.Success 	= False;
					    vNewResultRow.status 	= vStatus;
						vNewResultRow.Success 	= False;
						vNewResultRow.Error		= "Unknown booking status:" + vStatus + "; Booking №:" + vBookingID + "; Room ID:" + vRoomID;
						vLogEventType 			= Enums.ExternalSystemEventTypes.Error;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ProcessBookings", vLogEventType, , , vNewResultRow.Error);
						Continue;
					EndIf;
				EndDo;
			EndIf;
			
		EndDo;
	EndIf;
	
	Return vResult;
EndFunction

//-----------------------------------------------------------------------------
Function GetAmenitiesList(pAvailability = 0)
	vAmenitiesList = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Amenities.Description AS Description,
	|	Amenities.Ref AS Ref
	|FROM
	|	Catalog.Amenities AS Amenities
	|WHERE
	|	NOT Amenities.DeletionMark
	|	AND (Amenities.Availability = 0
	|			OR Amenities.Availability <> 0
	|				AND Amenities.Availability = &qAvailability
	|			OR &qAvailability = 0)
	|
	|ORDER BY
	|	Description";
	vQry.SetParameter("qAvailability", pAvailability);
	vAmenities = vQry.Execute().Unload();
	For Each vAmenitiesRow In vAmenities Do
		vAmenitiesList.Add(vAmenitiesRow.Ref);
	EndDo;
	Return vAmenitiesList;
EndFunction //  GetAmenitiesList

//-----------------------------------------------------------------------------
Function ParseHotelMappingToTables(pXMLStructure)
	
	vResult = New Structure("Rooms, Rates, Extras, RoomsMapping, Agents, Success, Error", Undefined, Undefined, Undefined, Undefined, Undefined, True, "");
	Try
		vRooms	= New ValueTable;
		vRooms.Columns.Add("ID");
		vRooms.Columns.Add("Name");
		vRooms.Columns.Add("isActive");

		vRates	= New ValueTable;
		vRates.Columns.Add("ID");
		vRates.Columns.Add("Name");
		vRates.Columns.Add("isActive");
		vRates.Columns.Add("isDerivated");
		
		vRoomsMapping = New ValueTable;
		vRoomsMapping.Columns.Add("RoomID");
		vRoomsMapping.Columns.Add("RateID");

		vExtras = New ValueTable;
		vExtras.Columns.Add("ID");
		vExtras.Columns.Add("Name");
		vExtras.Columns.Add("isActive");
		
		vAgents = New ValueTable;
		vAgents.Columns.Add("ID");
		vAgents.Columns.Add("Name");
		
		vMappingResponse 	= pXMLStructure.message.mappingResponse; 
		If vMappingResponse.Property("rooms") And vMappingResponse.rooms.Property("mappedRooms") Then
			vMappedRooms	= Undefined;
			vMappingResponse.rooms.mappedRooms.Property("room", vMappedRooms);
			If vMappedRooms <> Undefined Then
				vMappedRoomsArray = PropertyToArray(vMappedRooms);
				For Each vMappedRoom In vMappedRoomsArray Do
					vNewRow				= vRooms.Add();	
					vNewRow.ID			= vMappedRoom.roomPartnerCode;
					vNewRow.isActive	= vMappedRoom.isActive;
					If vMappedRoom.Property("name") Then
						vMappedRoom.name.Property("__TextValue", vNewRow.Name);	
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		If vMappingResponse.Property("ratePlans") Then
			vRatePlans	= Undefined;
			vMappingResponse.ratePlans.Property("ratePlan", vRatePlans);
			If vRatePlans <> Undefined Then
				vRatePlansArray = PropertyToArray(vRatePlans);
				For Each vRatePlan In vRatePlansArray Do
					vNewRow				= vAgents.Add();	
					vNewRow.ID			= vRatePlan.groupId;
					vRatePlan.Property("__TextValue", vNewRow.Name);	
				EndDo;
			EndIf;
		EndIf;

		If vMappingResponse.Property("rates") And vMappingResponse.rates.Property("mappedRates") Then
			vMappedRates	= Undefined;
			vMappingResponse.rates.mappedRates.Property("rate", vMappedRates);
			If vMappedRates <> Undefined Then
				vMappedRatesArray = PropertyToArray(vMappedRates);
				For Each vMappedRate In vMappedRatesArray Do
					vNewRow				= vRates.Add();	
					vNewRow.ID			= vMappedRate.ratePartnerCode;
					vNewRow.isActive	= vMappedRate.isActive;
					vNewRow.isDerivated	= vMappedRate.isDerivated;
					If vMappedRate.Property("name") Then
						vMappedRate.name.Property("__TextValue", vNewRow.Name);	
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		If vMappingResponse.Property("extras") And vMappingResponse.extras.Property("mappedExtras") Then
			vMappedExtras	= Undefined;
			vMappingResponse.extras.mappedExtras.Property("extra", vMappedExtras);
			If vMappedExtras <> Undefined Then
				vMappedExtrasArray = PropertyToArray(vMappedExtras);
				For Each vMappedExtra In vMappedExtrasArray Do
					vNewRow				= vExtras.Add();	
					vNewRow.ID			= vMappedExtra.extraPartnerCode;
					vNewRow.isActive	= vMappedExtra.isActive;
					If vMappedExtra.Property("name") Then
						vMappedExtra.name.Property("__TextValue", vNewRow.Name);	
					EndIf;
				EndDo;
			EndIf;
		EndIf;

		vRoomMappings	= Undefined;
		If vMappingResponse.Property("roomrateextras") And vMappingResponse.roomrateextras.Property("rooms") And vMappingResponse.roomrateextras.rooms.Property("room", vRoomMappings) Then			
			If vRoomMappings <> Undefined Then
				vRoomMappingsArray = PropertyToArray(vRoomMappings);
				For Each vRoomMappingsRow In vRoomMappingsArray Do
					vRatesMapping = Undefined;
					If vRoomMappingsRow.Property("rates", vRatesMapping) And vRoomMappingsRow.rates.Property("rate", vRatesMapping)Then
						vRatesMappingArray = PropertyToArray(vRatesMapping);
						For Each vRateMappingRow In vRatesMappingArray Do
							vNewRow				= vRoomsMapping.Add();	
							vNewRow.RoomID		= vRoomMappingsRow.roomPartnerCode;
							vNewRow.RateID		= vRateMappingRow.ratePartnerCode;
						EndDo;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		vResult.Rooms			= vRooms;
		vResult.Rates			= vRates;
		vResult.RoomsMapping	= vRoomsMapping;
		vResult.Extras			= vExtras;
		vResult.Success			= True;
		vResult.Agents			= vAgents;
	Except
		vError 			= ErrorDescription();
		vResult.Success = False;
		vResult.Error	= vError;
	EndTry;
	
	Return vResult
		
EndFunction

//-----------------------------------------------------------------------------
Function ParseChannelPoolsToTable(pXMLStructure)
	
	vResult = New ValueTable;
	vResult.Columns.Add("ID");
	vResult.Columns.Add("Name");
	
	vMappingResponse = pXMLStructure.message.channelPools;
	If vMappingResponse.Property("channelPool") Then
		vChannelPools	= Undefined;
		vMappingResponse.extras.mappedExtras.Property("channelPool", vChannelPools);
		If vChannelPools <> Undefined Then
			vChannelPoolsArray = PropertyToArray(vChannelPools);
			For Each vChannelPool In vChannelPoolsArray Do
				vChannel = Undefined;
				vChannelPool.Property("channel", vChannel);
				If vChannel <> Undefined Then
					vChannelsArray = PropertyToArray(vChannel);
					For Each vChannelData In vChannelsArray Do 
						vNewRow				= vResult.Add();	
						vNewRow.ID			= vChannelData.id;
						vNewRow.Name	= vChannelData.name;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndIf;

	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function CheckResultBody(pResponseBody)
	
	vResult = New Structure("Success, Error, BodyStructure");
	
	Try
		vXMLStructure 			= Catalogs.DataConvertationRules.XMLtoMap(pResponseBody, True);
		vResult.BodyStructure 	= vXMLStructure; 
		If vXMLStructure.Property("message") Then
			If vXMLStructure.message.Property("success") Then
				vResult.Success = True;
			Else
				vFailure = Undefined;
				If vXMLStructure.message.Property("failure", vFailure) Or vXMLStructure.message.Property("warning", vFailure) Then
					vResult.Success = False;
					vErrorType		= "";
					vErrorMessagee	= "";
					vErrorComment	= "";
					If TypeOf(vFailure) = Type("Array") Then
						// Array errors to do
						vFailure = vFailure[0];
						vFailure.Property("type", vErrorType);
						vFailure.Property("message", vErrorMessagee);
						If vFailure.Property("comment") Then
							vFailure.comment.Property("__TextValue", vErrorComment);	
						EndIf;
						 
						vResult.Error	= 	"Error:
											|type:" + vErrorType + "
											|message:" + vErrorMessagee + "
											|comment:" + vErrorComment;	
					Else						
						vFailure.Property("type", vErrorType);
						vFailure.Property("message", vErrorMessagee);
						If vFailure.Property("comment") Then
							vFailure.comment.Property("__TextValue", vErrorComment);	
						EndIf;
						 
						vResult.Error	= 	"Error:
											|type:" + vErrorType + "
											|message:" + vErrorMessagee + "
											|comment:" + vErrorComment;	
					EndIf;
				Else
					vResult.Error	= "Cant get request result! Missing success, error and warning properties!";
					vResult.Success = False;	
				EndIf;
			EndIf;
		Else
			vResult.Success = False;
			vResult.Error	= "Cant get request result! Missing message property";
		EndIf;
	Except
		vError			= ErrorDescription();
		vResult.Success = False;
		vResult.Error	= "Can't read XML to structure: " + vError;
	EndTry;
	
	Return vResult;
EndFunction

//-----------------------------------------------------------------------------
Function CheckResponseStatus(pResponse)
	
	vResult = New Structure("Success, StatusDescription");
	
	If pResponse.StatusCode = 200 Then
		vResult.Success 			= True;
		vResult.StatusDescription 	= "OK";
	ElsIf pResponse.StatusCode = 401 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Error 401";
	ElsIf pResponse.StatusCode = 404 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Error 404";
	ElsIf pResponse.StatusCode = 406 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Error 406";
	ElsIf pResponse.StatusCode = 500 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Error 500";
	Else
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Unknown status";
	EndIf;
	
	Return vResult;
EndFunction

//-----------------------------------------------------------------------------
Function PropertyToArray(pValue)
	
	vResult  = New Array;
	
	If TypeOf(pValue) = Type("Array") Then
		vResult = pValue;
	Else
		vResult.Add(pValue);
	EndIf;
	
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function CopyXDTO(pXDTO, pXDTOType)
	
	vResult = Undefined;
	
	vXMLWriter = New XMLWriter;
	vXMLWriter.SetString();
	XDTOFactory.WriteXML(vXMLWriter, pXDTO); 
	vXML = vXMLWriter.Close();
	
	vXMLReader = New XMLReader;
	vXMLReader.SetString(vXML);
	vResult = XDTOFactory.ReadXML(vXMLReader, pXDTOType);
	
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function BooleanToString(pBoolean)
	
	vResult = "false";
	
	If pBoolean = True Then
		vResult = "true";
	Else
		vResult = "false";	
	EndIf;
	
	Return vResult;
	
EndFunction

//-----------------------------------------------------------------------------
Function ResetXDTOPrices(pPrices)
	For Each vPricePerDate In pPrices.PricePerDateRow Do 
		vPricePerDate.Price = 0;
	EndDo;
	
	Return pPrices;
EndFunction

#EndRegion 
