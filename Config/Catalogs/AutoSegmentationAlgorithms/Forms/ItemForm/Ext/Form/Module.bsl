#Region FormEventHandlers
// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Object.Predefined And IsBlankString(Object.ExternalQueryText) Then
		Object.ExternalQueryText = GetPredefinedQueryAtServer(Object);
		If Not IsBlankString(Object.ExternalQueryText) Then
			FillInTheOptionsAtServer(TrimAll(Object.ExternalQueryText));
		EndIf;
	EndIf;	
EndProcedure

#EndRegion 

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pResult		 - String - Query text
//  pExtraParam	 - Structure - Additional properties 
//
&AtClient
Procedure AfterEditQuery(pResult, pExtraParam) Export 
	If Not IsBlankString(pResult) Then
		Object.ExternalQueryText = pResult;
		FillInTheOptionsAtServer(pResult);
	EndIf;	
EndProcedure	

#EndRegion 

#Region Internal

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetPredefinedQueryAtServer(pObject)
	Return Catalogs.AutoSegmentationAlgorithms.GetPredefinedQuery(pObject);
EndFunction	 

// -----------------------------------------------------------------------------
&AtServer
Procedure FillInTheOptionsAtServer(vQueryText)
	Object.Parameters.Clear();
	vQuery = New Query();
	vQuery.Text = vQueryText;
	vQueryParameters = vQuery.FindParameters();
	For Each vParameter In vQueryParameters Do
		If TrimAll(vParameter.Name) = "qTag" Then
			Continue;
		EndIf;
		vFilter = New Structure;
		vFilter.Insert("Parameter", vParameter.Name);
		vLines = Object.Parameters.FindRows(vFilter);
		vLine = Undefined;
		If vLines.Count() = 0 Then 
			vLine = Object.Parameters.Add();
		Else
			vLine = vLines[0];
		EndIf;
		vLine.Parameter = vParameter.Name;
		vLine.Description = NStr("en='Type: '; ru='Тип: '; de='Typ: '") + String(vParameter.ValueType);
	EndDo;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FillInTheOptions(pCommand)
	vQueryText = TrimAll(Object.ExternalQueryText);
	If IsBlankString(vQueryText) Then
		If Object.Predefined Then
			vFrmDataStruct = New Structure("Predefined, PredefinedDataName", Object.Predefined, Object.PredefinedDataName);
			vQueryText = GetPredefinedQueryAtServer(vFrmDataStruct);
		EndIf;
		Object.ExternalQueryText = vQueryText;
	EndIf;
	If Not IsBlankString(vQueryText) Then
		FillInTheOptionsAtServer(vQueryText);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure QueryWizard(pCommand)
	#If Not MobileClient Then
		vQueryWizard = New QueryWizard;
		If Not IsBlankString(Object.ExternalQueryText) Then
			vQueryWizard.Text = Object.ExternalQueryText;
		EndIf;
		vQueryWizard.Show(New NotifyDescription("AfterEditQuery", ThisObject));
	#EndIf
EndProcedure

#EndRegion