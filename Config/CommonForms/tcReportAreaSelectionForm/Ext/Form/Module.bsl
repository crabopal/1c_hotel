
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill form attributes
	FillPropertyValues(ThisForm, Parameters);
	
	// Check if report attribute is defined
	If Not ValueIsFilled(Report) Then
		pCancel = True;
		Return;
	EndIf;
	
	// Report name
	ReportName = TrimAll(Report.Code) + " - " + cmNStr(Report.Description);
	
	// Restore selected fields value table
	vAreas = Undefined;
	If IsBlankString(AreaAddress) Then
		vAreas = New ValueTable();
		vAreas.Columns.Add("Title", cmGetStringTypeDescription(1000));
		vAreas.Columns.Add("DataPath", cmGetStringTypeDescription(1000));
		vAreas.Columns.Add("AreaType", cmGetEnumTypeDescription("AppearanceAreaTypes"));
	Else
		vAreas = GetFromTempStorage(AreaAddress);
	EndIf;
	If vAreas = Undefined Or TypeOf(vAreas) <> Type("ValueTable") Then
		pCancel = True;
		Return;
	EndIf;
	Areas.Clear();
	For Each vAreasRow In vAreas Do
		vAreaItem = Areas.Add();
		FillPropertyValues(vAreaItem, vAreasRow);
	EndDo;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AreasTitleStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure("AvailableFieldsAddress, IsField, ChoiceMode, CloseOnChoice, CloseOnOwnerClose, ReadOnly", AvailableFieldsAddress, True, True, True, True, False);
	OpenForm("CommonForm.tcFieldChoiceForm", vParams, pItem, Report, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // AreasTitleStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure AreasTitleChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	If TypeOf(pSelectedValue) = Type("Structure") Then
		vCurData = Undefined;
		If pSelectedValue.Mode = "Field" Then
			vCurData = Items.Areas.CurrentData;
			If vCurData <> Undefined Then
				vCurData.DataPath = pSelectedValue.DataPath;
				vCurData.Title = pSelectedValue.Presentation;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // AreasTitleChoiceProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure AreasOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow And Not pClone Then
		vCurData = Items.Areas.CurrentData;
		If vCurData <> Undefined Then
			vCurData.AreaType = PredefinedValue("Enum.AppearanceAreaTypes.Field");
		EndIf;
	EndIf;
EndProcedure // AreasOnStartEdit

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(pCommand)
	vAreaPresentation = "";
	vAreaAddress = GetAreaAddressAtServer(vAreaPresentation);
	NotifyChoice(New Structure("Report, AreaAddress, AreaPresentation", Report, vAreaAddress, vAreaPresentation));
EndProcedure // SaveSettings

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function GetAreaAddressAtServer(rAreaPresentation)
	rAreaPresentation = "";
	vAreas = FormAttributeToValue("Areas");
	For Each vAreasRow In vAreas Do
		rAreaPresentation = rAreaPresentation + 
		                    ?(IsBlankString(rAreaPresentation), "", "; ") + 
							TrimAll(vAreasRow.Title);
	EndDo;
	vAreaAddress = PutToTempStorage(vAreas, ThisForm.UUID);
	Return vAreaAddress;
EndFunction // GetAreaAddressAtServer

#EndRegion
