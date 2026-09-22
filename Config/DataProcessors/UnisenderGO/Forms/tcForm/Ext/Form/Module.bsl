
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf; 
	
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;     
	
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");  
	
	LoadInteractionParameters();
EndProcedure // OnCreateAtServer 

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	If Modified And Not pExit Then
		pCancel = True;
		ShowQueryBox(New NotifyDescription("AfterQueryBox", ThisForm, True), NStr("en = 'Save changes?'; de = 'Änderungen speichern?'; ru = 'Сохранить изменения?'"), QuestionDialogMode.YesNoCancel);
	EndIf;
EndProcedure // BeforeClose

#EndRegion

#Region FormHeaderItemsEventHandlers

 // -----------------------------------------------------------------------------
&AtClient
Procedure TemplatesOnChange(pItem)
	Modified = True;
	TemplatesOnActivateRow(Items.Templates);
EndProcedure // TemplatesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TemplatesBeforeDeleteRow(pItem, pCancel)
	pCancel = True;
EndProcedure // TemplatesBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure TemplatesBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
EndProcedure // TemplatesBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure TemplatesOnActivateRow(pItem)		
	Items.TemplateParametersPresentationFillParameters.Enabled = False;
	CurSMSTemplates = PredefinedValue("Catalog.SMSTemplates.EmptyRef");
	CurID = "";
	vCurData = Items.Templates.CurrentData;
	If vCurData <> Undefined Then 
		If ValueIsFilled(vCurData.SMSTemplates) Then
			Items.TemplateParametersPresentationFillParameters.Enabled = True;
			CurSMSTemplates = vCurData.SMSTemplates;
			CurID = vCurData.ID;   
		EndIf; 
	EndIf;
	FillTemplateParametersPresentation();
EndProcedure // TemplatesOnActivateRow

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
	TemplatesOnActivateRow(Items.Templates);
EndProcedure // Save

// -----------------------------------------------------------------------------
&AtClient
Procedure Refresh(pCommand)
	If Modified Then
		ShowQueryBox(New NotifyDescription("AfterQueryBox", ThisForm, False), NStr("en = 'Save changes?'; de = 'Änderungen speichern?'; ru = 'Сохранить изменения?'"), QuestionDialogMode.YesNoCancel);
	Else
		Templates.Clear();
		TemplateParameters.Clear();
		If ValueIsFilled(InteractionID) Then
			FillTemplates();
			LoadTemplatesTable(); 
			TemplatesOnActivateRow(Items.Templates);
		EndIf;	
	EndIf;  
EndProcedure // Refresh

// -----------------------------------------------------------------------------
&AtClient
Procedure FillParameters(pCommand)
	vParametersList = GetParametersList(); 
	If vParametersList.Count() > 0 Then
		For Each vItem In vParametersList Do
			vItem.Check = TemplateParameters.FindRows(New Structure("Parameter, SMSTemplates, ID", vItem.Value, CurSMSTemplates, CurID)).Count() > 0;	
		EndDo; 
		vNotifyDescription = New NotifyDescription("AfterChoiceParameters", ThisForm);
		vParams = New Structure("MultipleChoice, Title, ValueList", True, NStr("en = 'Check parameters...'; de = 'Überprüfen Sie die Optionen...'; ru = 'Отметьте параметры...'"), vParametersList);
		OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,, vNotifyDescription);
	EndIf;
EndProcedure // FillParameters

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GetParametersList()
	Return EMail.GetEMailParametersList();	
EndFunction // GetParametersList

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceParameters(pValueList, pExtraParams) Export 
	If pValueList <> Undefined Then
		vTemplateParametersArr = TemplateParameters.FindRows(New Structure("ID, SMSTemplates", CurID, CurSMSTemplates));
		For Each vTemplateParameter In vTemplateParametersArr Do  
			TemplateParameters.Delete(vTemplateParameter);
		EndDo; 
		For Each vItem In pValueList Do
			If vItem.Check Then
				vNewRow = TemplateParameters.Add();
				vNewRow.ID = CurID;
				vNewRow.SMSTemplates = CurSMSTemplates;
				vNewRow.Parameter = vItem.Value; 
			EndIf;
		EndDo; 
		TemplatesOnActivateRow(Items.Templates); 
		Modified = True;
	EndIf;
EndProcedure // AfterChoiceParameters

// -----------------------------------------------------------------------------
&AtClient
Procedure FillTemplateParametersPresentation()
	TemplateParametersPresentation.Clear();
	vTemplateParametersArr = TemplateParameters.FindRows(New Structure("ID, SMSTemplates", CurID, CurSMSTemplates));
	For Each vTemplateParameter In vTemplateParametersArr Do
		vNewRow = TemplateParametersPresentation.Add();
		vNewRow.ParameterPresentation = "{{" + vTemplateParameter.Parameter + "}}" 
	EndDo;
EndProcedure // FillTemplateParametersPresentation

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterQueryBox(pResult, pIsClose) Export 
	If pResult = DialogReturnCode.Yes Then
		Save_AtServer(); 
		TemplatesOnActivateRow(Items.Templates);
		If pIsClose Then
			Close(); 
		EndIf;
	ElsIf pResult = DialogReturnCode.No Then
		Modified = False;
		If pIsClose Then
			Close();
		Else
			Templates.Clear();
			TemplateParameters.Clear();
			If ValueIsFilled(InteractionID) Then
				FillTemplates();
				LoadTemplatesTable();
				TemplatesOnActivateRow(Items.Templates);
			EndIf;	
		EndIf;				
	EndIf;
EndProcedure // AfterQueryBox

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	vInteractionParameters = Object.InteractionParameters;
	
	If Not ValueIsFilled(vInteractionParameters) Then
		Return;
	EndIf;       
	
	Hotel 			= vInteractionParameters.Hotel;
	InteractionID	= vInteractionParameters.InteractionID; 
	HttpServer 		= vInteractionParameters.HttpServer;
	Active			= vInteractionParameters.IsActive; 
	HttpUseSsl		= vInteractionParameters.HttpUseSsl;
	Debug			= vInteractionParameters.DebugMode;
	MaxLogLenght	= vInteractionParameters.MaxLogLenght;
	
	Templates.Clear();
	TemplateParameters.Clear();
	If ValueIsFilled(InteractionID) Then
		FillTemplates();
		LoadTemplatesTable();
	EndIf;
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
		
	vIntParObj					= Object.InteractionParameters.GetObject();
    vIntParObj.Hotel			= Hotel;
	vIntParObj.InteractionID	= InteractionID;
	vIntParObj.HttpServer		= HttpServer;
	vIntParObj.IsActive			= Active;
	vIntParObj.HttpUseSsl		= HttpUseSsl;
	vIntParObj.DebugMode		= Debug;
	vIntParObj.MaxLogLenght		= MaxLogLenght;
	vIntParObj.Write();
EndProcedure // SaveInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTemplates()
	Obj = FormAttributeToValue("Object");
	vTemplateList = Obj.GetTemplateList();
	For Each vItem In vTemplateList Do
		vNewRow = Templates.Add();
		vNewRow.Name = vItem["name"];
		vNewRow.ID = vItem["id"];
	EndDo;
EndProcedure // FillTemplates

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	
	If NOT CheckFilling() Then
		Return;
	EndIf;
		
	Try 
		BeginTransaction();
		SaveInteractionParameters();
		SaveTemplatesTable();
		
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
		CommitTransaction(); 
		Modified = False;
	Except
		RollbackTransaction();
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vError);
	EndTry;
	LoadInteractionParameters();
EndProcedure // Save_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveTemplatesTable()	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "SMSTemplates", "SMSTemplates");
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "String", "Parameter");
	For Each vItem In Templates Do
		If ValueIsFilled(vItem.SMSTemplates) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "SMSTemplates", "SMSTemplates", vItem.SMSTemplates, Undefined, vItem.ID, vItem.ID);
			vTemplateParametersArr = TemplateParameters.FindRows(New Structure("SMSTemplates, ID", vItem.SMSTemplates, vItem.ID));
			For Each vTemplateParameter In vTemplateParametersArr Do
				If ValueIsFilled(vTemplateParameter.Parameter) Then
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "String", "Parameter", vItem.SMSTemplates, vTemplateParameter.Parameter, vTemplateParameter.Parameter, vItem.ID);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure // SaveTemplatesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadTemplatesTable()
	vTemplates = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "SMSTemplates", "SMSTemplates");
	For Each vItem In vTemplates Do
		vTemplateArr = Templates.FindRows(New Structure("ID", vItem.ExternalSystemDataCode));
		If vTemplateArr.Count() > 0 Then
			vTemplateArr[0].SMSTemplates = vItem.RefKey1; 
			vTemplateParameters = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "String", "Parameter", vItem.RefKey1,,, vItem.ExternalSystemDataCode); 
			For Each vTemplateParameter In vTemplateParameters Do
				vNewRow = TemplateParameters.Add();
				vNewRow.Parameter = vTemplateParameter.RefKey2;
				vNewRow.SMSTemplates = vItem.RefKey1; 
				vNewRow.ID = vItem.ExternalSystemDataCode;
			EndDo;
		EndIf;
	EndDo;
EndProcedure // LoadTemplatesTable	
	
#EndRegion
