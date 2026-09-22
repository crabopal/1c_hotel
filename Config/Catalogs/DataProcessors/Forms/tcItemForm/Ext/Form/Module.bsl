
#Region EventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Form caption
	ThisForm.AutoTitle = False;
	ThisForm.Title = cmNStr(Object.Description, SessionParameters.CurrentLanguage);
	// Report type
	DataProcessorTypeOnChangeAtServer();
	// Fill list of report attributes
	FillListOfDataProcessorAttributes();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure IsExternalOnChange(pItem)
	DataProcessorTypeOnChangeAtServer();
EndProcedure // IsExternalOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure DataProcessorOnChange(pItem)
	// Fill list of report attributes
	FillListOfDataProcessorAttributes();   
	// Fill description
	If IsBlankString(Object.Description) And Object.IsExternal = False And Not IsBlankString(Object.Processing) Then
		Object.Description = GetPresentationDataProcessor(Object.Processing) 	
	EndIf;	
EndProcedure // ReportOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure RemarksOpening(pItem, pStandardProcessing)
	pStandardProcessing = false;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.Remarks), pItem);
EndProcedure // RemarksOpening

// --------------------------------------------------------------------------------
&AtClient
Procedure AvailableAttributesDragStart(pItem, pDragParameters, pPerform)
	vRowData = AvailableAttributes.FindByID(pDragParameters.Value);
	If vRowData <> Undefined Then
		pDragParameters.Value = TrimAll(vRowData.Attribute);
	EndIf;
EndProcedure // AvailableAttributesDragStart

// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionOpening(pItem, pStandardProcessing)
	pStandardProcessing = false;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.Description), pItem);
EndProcedure // DescriptionOpening

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure GenerateUUID(Command)
	Object.Key = String(New UUID);
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure DataProcessorTypeOnChangeAtServer()
	If Object.IsExternal Then
		If TypeOf(Object.Processing) <> Type("CatalogRef.ExternalDataProcessors") Then
			Object.Processing = Catalogs.ExternalDataProcessors.EmptyRef();
		EndIf;
		Items.Processing.TextEdit = True;
		Items.Processing.ListChoiceMode = False;
		Items.Processing.DropListButton = False;
		Items.Processing.ChoiceButton = True;
		Items.Processing.OpenButton = True;
		Items.Processing.ClearButton = True;
	Else
		If TypeOf(Object.Processing) <> Type("String") Then
			Object.Processing = "";
		EndIf;
		Items.Processing.TextEdit = False;
		Items.Processing.ListChoiceMode = True;
		Items.Processing.DropListButton = True;
		Items.Processing.ChoiceButton = False;
		Items.Processing.OpenButton = False;
		Items.Processing.ClearButton = False;
		vReportsList = cmFillDataProcessorsList(); 
		Items.Processing.ChoiceList.Clear();
		For Each vRowDP In vReportsList Do
			Items.Processing.ChoiceList.Add(vRowDP.Value, vRowDP.Presentation);	
		EndDo;
	EndIf;
	AvailableAttributes.Clear();
EndProcedure // ExternalProcessingTypeOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure FillListOfDataProcessorAttributes()
	AvailableAttributes.Clear();
	// Fill list of atributes from the data processor object metadata
	Try
		vRepObj = cmBuildDataProcessorObject(Object);
		If vRepObj <> Undefined Then
			For Each vAttr In vRepObj.Metadata().Attributes Do
				vRow = AvailableAttributes.Add();
				vRow.Attribute = "DPO." + vAttr.Name;
			EndDo;
		EndIf;
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "PARM";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "SessionParameters.CurrentUser";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "SessionParameters.CurrentWorkstation";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "SessionParameters.CurrentHotel";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "CurrentSessionDate()";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "BegOfDay(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "EndOfDay(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "BegOfWeek(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "EndOfWeek(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "BegOfMonth(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "EndOfMonth(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "BegOfQuarter(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "EndOfQuarter(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "BegOfYear(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "EndOfYear(CurrentSessionDate())";
	Except
		AvailableAttributes.Clear();
		vRow = AvailableAttributes.Add();
		vRow.Attribute = NStr("en='Failed to create report object for settings specified!';ru='Ошибка создания объекта отчета по текущим параметрам!';de='Fehler bei der Erstellung des Berichtsobjekts nach aktuellen Parametern!'");
	EndTry;
EndProcedure // FillListOfReportAttributes

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetPresentationDataProcessor(pDPName)
	vDesc = "";
	vDP = Metadata.DataProcessors.Find(pDPName);
	If vDP <> Undefined Then
		vDesc = vDP.Synonym;   
	EndIf;   
	Return vDesc;
EndFunction // GetPresentationDataProcessor() 

#EndRegion
