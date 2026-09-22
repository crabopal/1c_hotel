
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("ExternalSystemInteraction") Then
		ExternalSystemInteraction = Parameters.ExternalSystemInteraction;
	EndIf;
	If ValueIsFilled(ExternalSystemInteraction) And Parameters.Property("RoomRatesForMatch") And Not IsBlankString(Parameters.RoomRatesForMatch) Then
		vTab = GetFromTempStorage(Parameters.RoomRatesForMatch); 
		For Each vRow In vTab Do
			FillPropertyValues(RoomRatesForMatch.Add(), vRow);
		EndDo;
		// Fill ISD room rates
		vRes = ISD.GetTariffs(ExternalSystemInteraction);
		If vRes.Success = True Then
			vListTariffs = vRes.MapResponse.get("tariffs");
			For Each vIdRow In vListTariffs Do
				vId = Format(vIdRow[0], "NZ=0; NG=");
				vRateDescr = TrimAll(vIdRow[1]);
				Items.RoomRatesForMatchISDDescription.ChoiceList.Add(New Structure("RoomRatesISDCode, RoomRatesISDDescription", vId, vRateDescr), vRateDescr);
			EndDo;
		Else
			tcCommonFunctionOnClientServer.TextMessage(vRes.StatusDescription);
		EndIf;	
		// Fill ISD parking tariffs
		If vRes.Success = True Then
			vRes = ISD.getParking(ExternalSystemInteraction);
			If vRes.Success = True Then
				vListTariffs = vRes.MapResponse.get("tariffs");
				For Each vIdRow In vListTariffs Do
					vId = Format(vIdRow["tariff_id"], "NZ=0; NG=");
					vISDParkingDescr = TrimAll(vIdRow["descr"]);
					Items.RoomRatesForMatchISDParkingDescription.ChoiceList.Add(New Structure("ParkingISDCode, ParkingISDDescription", vId, vISDParkingDescr), vISDParkingDescr);
				EndDo;
			Else
				tcCommonFunctionOnClientServer.TextMessage(vRes.StatusDescription);
			EndIf;	
		EndIf;

	EndIf;	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesForMatchISDDescriptionChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If Not pSelectedValue = Undefined Then
		pStandardProcessing = False;
		vRow = Items.RoomRatesForMatch.CurrentData;
		If Not vRow = Undefined Then
			vRow.ISDCode = pSelectedValue.RoomRatesISDCode;
			vRow.ISDDescription = pSelectedValue.RoomRatesISDDescription;
		EndIf;	
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesForMatchISDParkingDescriptionChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If Not pSelectedValue = Undefined Then
		pStandardProcessing = False;
		vRow = Items.RoomRatesForMatch.CurrentData;
		If Not vRow = Undefined Then
			vRow.ISDParkingCode = pSelectedValue.ParkingISDCode;
			vRow.ISDParkingDescription = pSelectedValue.ParkingISDDescription;
		EndIf;	
	EndIf;	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)  
	SaveMapping();
	Close(True);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveMapping()    
	vTariffType = "Tariffs";
	For Each vRow In RoomRatesForMatch Do
	    vUUID = vRow.UUIDRowMapping;
		InformationRegisters.ExternalSystemIntegrationData.WriteData(ExternalSystemInteraction, vTariffType, "ISDCode",  vUUID, Undefined, vRow.ISDCode);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(ExternalSystemInteraction, vTariffType, "ISDDescription",  vUUID, Undefined, vRow.ISDDescription);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(ExternalSystemInteraction, vTariffType, "ISDParkingCode",  vUUID, Undefined, vRow.ISDParkingCode);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(ExternalSystemInteraction, vTariffType, "ISDParkingDescription",  vUUID, Undefined, vRow.ISDParkingDescription);
	EndDo;
EndProcedure
  
#EndRegion
