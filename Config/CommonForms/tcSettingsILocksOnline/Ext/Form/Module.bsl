
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("DoorLockSystemParameters") Then
		DoorLockSystemParameters = Parameters.DoorLockSystemParameters;
	EndIf;
	
	Try
		vObjDoorLocksParameters = DoorLockSystemParameters.GetObject();
		vParams = vObjDoorLocksParameters.DoorLockSystemConnectionParameters.Get();
		vParams.Property("InteractionParameters", InteractionParameters);
		vParams.Property("AddMinutes", AddMinutes);
		vParams.Property("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
		vParams.Property("ConvertCardIDToDec", ConvertCardIDToDec);
		vParams.Property("EncoderNumber", EncoderNumber);
		vParams.Property("AssignedAuthorizations", AssignedAuthorizations);
		vParams.Property("AllowDynamicAuthorizations", AllowDynamicAuthorizations);
	Except
		ResetSettings();
	EndTry;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandSaveAndClose(pCommand)
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CommandSaveAtServer();
	Notify("Catalogs.DoorLockSystemParameters.Write");
	Close();
EndProcedure // CommandSaveAndClose

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandClose(pCommand)
	Close();
EndProcedure // CommandSaveAndClose

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandSave(pCommand)
	If Not CheckFilling() Then 
		Return;
	EndIf;
	
	CommandSaveAtServer();
	Notify("Catalogs.DoorLockSystemParameters.Write");
EndProcedure // CommandSave

// -----------------------------------------------------------------------------
&AtClient
Procedure ResetSettings1(pCommand)
	ResetSettings();
EndProcedure // ResetSettings1

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AssignedAuthorizationsStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	pStandardProcessing = True;
	If Not ValueIsFilled(InteractionParameters) Then
		Return;
	EndIf;
	
	vMessage = "";
	vAssignedAuthorizationsList = GetAssignedAuthorizations(vMessage);
	If vAssignedAuthorizationsList = Undefined Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		Return;
	EndIf;
	
	If Not IsBlankString(AssignedAuthorizations) Then
		vAssignedAuthorizationsArr = StrSplit(AssignedAuthorizations, ",", False);
		For Each vAssignedAuthorizationRow In vAssignedAuthorizationsArr Do
			vAssignedAuthorizationItem = vAssignedAuthorizationsList.FindByValue(vAssignedAuthorizationRow);
			If vAssignedAuthorizationItem = Undefined Then
				Continue;
			EndIf;
			
			vAssignedAuthorizationItem.Check = True;
		EndDo;
	EndIf;
	
	vNotifyDescription = New NotifyDescription("AfterAccessZonesSelection", ThisObject);
	vParams = New Structure("ValueList, MultipleChoice, Title", vAssignedAuthorizationsList, True, NStr("en = 'Mark access zones'; de = 'Zugangsbereiche markieren'; ru = 'Отметьте зоны доступа'"));
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, ,, vNotifyDescription);
EndProcedure // AssignedAuthorizationsStartChoice

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ResetSettings()
	AddMinutes = 0;
	DoKeyCardsFromFoliosOnly = False;
	ConvertCardIDToDec = False;
	InteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	EncoderNumber = "";
	AssignedAuthorizations = "";
EndProcedure // ResetSettings

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandSaveAtServer()
	vParams = New Structure;
	vParams.Insert("InteractionParameters", InteractionParameters);
	vParams.Insert("AddMinutes", AddMinutes);
	vParams.Insert("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
	vParams.Insert("ConvertCardIDToDec", ConvertCardIDToDec);
	vParams.Insert("EncoderNumber", EncoderNumber);
	vParams.Insert("AssignedAuthorizations", AssignedAuthorizations);
	vParams.Insert("AllowDynamicAuthorizations", AllowDynamicAuthorizations);
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.InteractionParameters = InteractionParameters;
	objDoorLocksParameters.AddMinutes = AddMinutes;
	objDoorLocksParameters.DoKeyCardsFromFoliosOnly = DoKeyCardsFromFoliosOnly;
	objDoorLocksParameters.ConvertUUIDToDecimal = ConvertCardIDToDec;
	objDoorLocksParameters.EncoderNumber = EncoderNumber;
	objDoorLocksParameters.AssignedAuthorizations = AssignedAuthorizations;
	objDoorLocksParameters.AllowDynamicAuthorizations = AllowDynamicAuthorizations;
	objDoorLocksParameters.Write();
EndProcedure // CommandSaveAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetAssignedAuthorizations(rMessage)
	vDataProcessor = InteractionParameters.DataProcessor;
	If Not ValueIsFilled(vDataProcessor) Then
		rMessage = Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'");
		Return Undefined;
	EndIf;
	
	vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDataProcessor, True);
	If vDPO = Undefined Then
		rMessage = Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'");
		Return Undefined;
	EndIf;
	
	vZones = vDPO.pmGetZone(rMessage);
	If vZones = Undefined Then
		Return Undefined;
	EndIf;
	
	vZonesList = New ValueList;
	
	vData = vZones["data"];
	For Each vZone In vData["value"] Do
		vZonesList.Add(vZone["number"], vZone["name"]);
	EndDo;
	
	Return vZonesList;
EndFunction // GetAssignedAuthorizations

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterAccessZonesSelection(pValueList, pExtraParams) Export
	If pValueList = Undefined Then
		Return;
	EndIf;
	
	vAssignedAuthorizationsArr = New Array;
	For Each pValueRow In pValueList Do
		If Not pValueRow.Check Then
			Continue;
		EndIf;
		
		vAssignedAuthorizationsArr.Add(pValueRow.Value);
	EndDo;
	
	AssignedAuthorizations = StrConcat(vAssignedAuthorizationsArr, ",");
EndProcedure // AfterAccessZonesSelection

#EndRegion

