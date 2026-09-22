
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Check user rights
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	EndIf;
	// Fill items
	LastModificationTime = Object.FileLastChangeTime;
	FileName 			 = Object.FileName;
	If Not Object.Ref.IsEmpty() Then
	   vBinaryData = tcOnServer.cmGetBinaryDataByRef(Object.Ref, "PrintFormTemplate");
	   PrintFormTemplate = PutToTempStorage(vBinaryData, UUID);	
	EndIf; 
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If Not IsBlankString(PrintFormTemplate) Then 
		pCurrentObject.PrintFormTemplate 	= New ValueStorage(GetFromTempStorage(PrintFormTemplate));
		pCurrentObject.FileLoadTime     	= CurrentSessionDate();
		pCurrentObject.FileLastChangeTime 	= LastModificationTime;
		pCurrentObject.FileName 			= FileName;
	Else
		pCurrentObject.PrintFormTemplate 	= Undefined;
		pCurrentObject.FileLoadTime     	= Date(1, 1, 1);
		pCurrentObject.FileLastChangeTime 	= Date(1, 1, 1);
		pCurrentObject.FileName 			= "";
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Clear(pCommand)
	PrintFormTemplate = "";
	// Clear file name, load time and last modification time
	FileName = "";
	Object.FileLoadTime = Date(1, 1, 1);
	LastModificationTime = Date(1, 1, 1);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure Load(pCommand)
	vParams = tcOnClientWorkWithFiles.cmGetEmptyParamsForLoadFiles();
	vParams.Form = ThisForm;
	vParams.Item = "PrintFormTemplate";
	vParams.Filter = tcOnClientWorkWithFiles.cmGetChooseFilterAnyRef();
	vFillingValues = vParams.FillingValues;
	vFillingValues.Insert("FileName", "");
	vFillingValues.Insert("LastModificationTime", "");
	tcOnClientWorkWithFiles.LoadFile(vParams);
EndProcedure

#EndRegion
