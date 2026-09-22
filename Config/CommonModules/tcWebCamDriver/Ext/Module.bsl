
#Region Public

//-----------------------------------------------------------------------------
// Function - Make a photo
//
// Parameters:
//  pSettingsTwain		 - String	 - Contains the number of the connected webcamera
//  pSettingsFocusTime	 - Number	 - The number of frame to make a photo
// 
// Returns:
//  BinaryData - Photo from WebCamera in format of binary data
//
Function MakeAPhoto(pSettingsTwain, pSettingsFocusTime) Export 
	vResult = Undefined;
	#If Not WebClient And Not MobileClient Then
		vCompObject = Connect();
		If vCompObject <> Undefined Then
			vResult = vCompObject.GetPicture(Number(pSettingsTwain), 2, 75, , pSettingsFocusTime);
		EndIf;
	#EndIf
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
// 
// Returns:
// AddIn  - the external component to work with web-camera 
//
Function Connect() Export
	// Fill system name
	vDLSys = Undefined;
	#If Not WebClient And Not MobileClient Then
		vSystemName = "WebCamDriver";
		vDLSys = GetPersistentObject("WebCamDriver");
		If vDLSys = Undefined Then 
			Try
				// ACC:561-off
				vConnected = AttachAddIn("CommonTemplate.WebCamDriver", "WebCamDriver", AddInType.Native);
				If Not vConnected Then
					InstallAddIn("CommonTemplate.WebCamDriver");
					vConnected = AttachAddIn("CommonTemplate.WebCamDriver", "WebCamDriver", AddInType.Native);
				EndIf;
				// ACC:561-on
				
				If Not vConnected Then
					tcCommonFunctionOnClientServer.TextMessage(StrTemplate(NStr("en = '%1 connection error.'; de = '%1 connection error.'; ru = 'Ошибка подключения %1.'"), vSystemName));
					Return Undefined;
				EndIf;
				
				vDLSys = New("AddIn.WebCamDriver.WMFPictures");
				
				If vDLSys <> Undefined Then
					SetPersistentObject("WebCamDriver", vDLSys);
				EndIf;
			Except
				tcCommonFunctionOnClientServer.TextMessage(StrTemplate(NStr("ru = 'Ошибка подключения %1: %2'; en = '%1 connection error: %2'; de = '%1 connection error: %2'"), vSystemName, ErrorDescription()));
				Return Undefined;
			EndTry;
		EndIf;
	#EndIf
	Return vDLSys;
EndFunction // pmConnect

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
//
// Parameters:
//  pName	 - String - Name of the system 
// 
// Returns:
// vObject - Undefined or CommonModule 
//
Function GetPersistentObject(pName)
	vObject = Undefined;
	amPersistentObjects.Property(pName, vObject);
	If vObject = Undefined Then
		amPersistentObjects.Insert(pName, vObject);
	EndIf;
	Return vObject;
EndFunction // GetPersistentObject 

// -----------------------------------------------------------------------------
Procedure SetPersistentObject(pName, pValue)
	amPersistentObjects.Insert(pName, pValue);
EndProcedure // SetPersistentObject

#EndRegion
