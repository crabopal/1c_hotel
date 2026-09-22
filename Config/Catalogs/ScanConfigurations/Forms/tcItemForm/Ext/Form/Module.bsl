
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	vWstn = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vWstn.ImagesScannerConnectionParameters) Then
		ImageScannerDriver = vWstn.ImagesScannerConnectionParameters.ImageScannerDriver;
		If ImageScannerDriver = Enums.ImageScannerDrivers.SmartPassportBoxEngine Then
			Items.ScanConfigurationName.Enabled = False;
			Items.ColorDepth.Enabled = False;
			Items.Rotation.Enabled = False;
			Items.PaperSize.Enabled = False;
			Items.LanguageID.Enabled = False;
			Items.ExternalNames.Enabled = False;
		ElsIf ImageScannerDriver = Enums.ImageScannerDrivers.Regula Then
			Items.ScanConfigurationName.Enabled = False;
			Items.ColorDepth.Enabled = False;
			Items.Rotation.Enabled = False;
			Items.PaperSize.Enabled = False;
		Else
			Items.LanguageID.Enabled = False;
			Items.ExternalNames.Enabled = False;
		EndIf;
	EndIf;
	If Not IsBlankString(Object.ScanConfigurationName) Then
	    Items.ScanConfigurationName.ChoiceList.Add(Object.ScanConfigurationName,Object.ScanConfigurationName);
	EndIf; 
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ScanConfigurationNameStartChoice(Item, ChoiceData, StandardProcessing)
	vMsg = "";
	If amImageScanner = Undefined Then
		// Connection images scaner
		vModuleName = tcDevicesConnection.cmGetImagesScannerDriverModule(vMsg);
		If Not IsBlankString(vMsg) Then
			ShowMessageBox(,vMsg);
			Return;
		Else
			If Not vModuleName = Undefined Then
				amImageScanner  = tcCommonFunctions.cmGetCommonModule(vModuleName);;
			EndIf; 
		EndIf; 
	EndIf;
	If amImageScanner = Undefined Then
		ShowMessageBox(, NStr("en = 'Could not connect to image scanner!'; de = 'Verbindung zum Bildscanner konnte nicht hergestellt werden!'; ru = 'Не удалось подключиться к сканеру изображений!'"));
		Return;
	EndIf;

	rMessage = "";
	vList = amImageScanner.pmGetListOfAllowedConfigurations(rMessage);
	If Not IsBlankString(rMessage) Then
		ShowMessageBox(,rMessage);
		Return;
	Else
		Items.ScanConfigurationName.ChoiceList.Clear();
		For Each vIS In vList Do
		  Items.ScanConfigurationName.ChoiceList.Add(vIS.Value, vIS.Value);
		EndDo; 
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IdentityDocumentTypeOnChange(Item)
	If ValueIsFilled(Object.IdentityDocumentType) And IsBlankString(Object.Description) Then
		Object.Description = Object.IdentityDocumentType;
	EndIf;	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Edit(pCommand)
	vDocumentTypeList = GetDocumentTypeList();
	If vDocumentTypeList.Count() > 0 Then
		vNotifyDescription = New NotifyDescription("AfterExternalNamesEdit", ThisObject);
		vParams = New Structure("ValueList, MultipleChoice, Title", vDocumentTypeList, True, NStr("en = 'Choose document types'; de = 'Dokumenttypen auswählen'; ru = 'Отметьте типы документов'"));
		OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , vNotifyDescription); 	
	EndIF;
EndProcedure // Edit

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GetDocumentTypeList()
	vResult = New ValueList();
	
	vDocumentTypeList = Catalogs.ScanConfigurations.GetTemplate("RegulaDocumentType");

	For i = 2 To vDocumentTypeList.TableHeight Do
		Try
			vResult.Add(TrimAll(vDocumentTypeList.Area(i, 2, i, 2).Text), TrimAll(vDocumentTypeList.Area(i, 1, i, 1).Text) + " (" + vDocumentTypeList.Area(i, 2, i, 2).Text + ")", Object.ExternalNames.FindRows(New Structure("ExternalName", TrimAll(vDocumentTypeList.Area(i, 2, i, 2).Text))).Count() > 0); 	
		Except
		EndTry;
	EndDo;
	
	Return vResult;
EndFunction // GetDocumentTypeList

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterExternalNamesEdit(pValueList, pExtraParams) Export
	If pValueList = Undefined Then
		Return;
	EndIf;
	
	Object.ExternalNames.Clear();
	For Each vItem In pValueList Do
		If Not vItem.Check Then
			Continue;
		EndIf;
		
		vNewRow = Object.ExternalNames.Add();
		vNewRow.ExternalName = vItem.Value;
	EndDo;
	
	Modified = True;
EndProcedure // AfterExternalNamesEdit

#EndRegion    
