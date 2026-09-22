
#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandSettings(Command)
	If Items.List.SelectedRows.Count() > 0 Then
		vRef = Items.List.CurrentRow;
	Else
		ShowMessageBox(, NStr("en = 'It is necessary to highlight the interaction system!'; de = 'Es ist notwendig, das Interaktionssystem hervorzuheben!'; ru = 'Необходимо выделить систему взаимодействия!'"));
		Return;
	EndIf;	
	vFormName = "";
	If CommandSettingsOnServer(vRef, vFormName) Then
		If StrStartsWith(vFormName, "DataProcessor") Then
			vParams = New Structure("InteractionParameters", vRef);
		Else
			vParams = New Structure("Key", vRef);
		EndIf;
		vDataProcessor = tcOnServer.cmGetAttributeByRef(vRef, "DataProcessor");
		If ValueIsFilled(vDataProcessor) Then
			vParams.Insert("DataProcessor", vDataProcessor);
			If tcOnServer.cmGetAttributeByRef(vDataProcessor, "IsExternal") Then
				vFormName = GetNameDataProcessor(vDataProcessor);
			EndIf;
		EndIf;	
		OpenForm(vFormName, vParams);
	Else
		ShowMessageBox(, NStr("en='Integration type has to be filled!'; ru='Не заполнен тип интеграции!'; de='Integrationtyp ist nicht gefüllt!'"));
		Return;
	EndIf;
EndProcedure


#EndRegion 

#Region Private

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetNameDataProcessor(pDataProcessor)
	Return Catalogs.DataProcessors.GetNameDataProcessorByProcessing(pDataProcessor);	
EndFunction //  GetNameDataProcessor

// --------------------------------------------------------------------------------
&AtServerNoContext
Function CommandSettingsOnServer(pObjectRef, pFormName)
	Return Catalogs.ExternalSystemInteractions.GetObjetForm(pObjectRef, pFormName, Not ValueIsFilled(pObjectRef.DataProcessor));
EndFunction

#EndRegion

	