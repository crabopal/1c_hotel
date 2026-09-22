
#Region Variables

// -----------------------------------------------------------------------------
&AtClient
Var WebCamDriver;

// -----------------------------------------------------------------------------
&AtClient
Var Compobject;

#EndRegion

#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Object.FocusTime = Max(1, Object.FocusTime);
	Object.Scale = Max(10, Object.Scale);
	Object.Panoram = Max(-180, Object.Panoram);
	Object.Slope = Max(-180, Object.Slope);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	WebCamDriver = tcCommonFunctions.cmGetCommonModule("tcWebCamDriver");
	Compobject = WebCamDriver.Connect();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure TwainDeviceNameStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	TwainDeviceNameStartChoiceAsync(pItem);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Reset(pCommand)
	Object.Scale = 100;
	Object.Panoram = 0;
	Object.Slope = 0;
	Object.FocusTime = 30;
EndProcedure // Reset

// -----------------------------------------------------------------------------
&AtClient
Async Procedure StartShowcase(pCommand)
	If IsBlankString(Object.TwainDeviceName) Then
		Return;
	EndIf;
	
	If Not Await SetSettingsAsync() Then
		Return;
	EndIf;
	
	vPhoto = WebCamDriver.MakeAPhoto(Number(Object.TwainDeviceName), Object.FocusTime);
	If vPhoto = Undefined Then
		Return;
	EndIf;
	
	PhotoPreview = StrTemplate("<!DOCTYPE html><html><center><img src=""data:image/bmp;base64, %1 "" style=""max-width:98vw; height:auto; align-items:center;""; /></center></html>", Base64String(vPhoto));
EndProcedure
#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Async Procedure TwainDeviceNameStartChoiceAsync(pItem)
	vDevicesCount = Compobject.GetDevicesCount();
	vList = New ValueList;
	
	If vDevicesCount = 0 Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Web Camera device was not detected'; de = 'Web Camera device was not detected'; ru = 'Веб-камера не обнаружена'"));
		Return;
	EndIf;
	
	For vDevNumber = 0 To vDevicesCount - 1 Do
		vList.Add(Format(vDevNumber, "NFD=0; NZ=0; NG="), Compobject.GetDeviceName(vDevNumber));
	EndDo;
	
	vListItem = Await ChooseFromListAsync(vList, pItem, vList.FindByValue(TrimAll(Object.TwainDeviceName)));
	If vListItem <> Undefined Then
		Object.TwainDeviceName = vListItem.Value;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Async Function SetSettingsAsync()
	Try
		Await Compobject.ControlSetAsync(Number(Object.TwainDeviceName), 3, Object.Scale);
	Except
		tcCommonFunctionOnClientServer.UserMessage(BriefErrorDescription(ErrorInfo()));
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'This device does not support this scaling value'; de = 'This device does not support this scaling value'; ru = 'Данное устройство не поддерживает такое значение масштабирования'"));
		Return False;
	EndTry;
	
	Try
		Await Compobject.ControlSetAsync(Number(Object.TwainDeviceName), 1, Object.Slope);
	Except
		tcCommonFunctionOnClientServer.UserMessage(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	Try
		Await Compobject.ControlSetAsync(Number(Object.TwainDeviceName), 0, Object.Panoram);
	Except
		tcCommonFunctionOnClientServer.UserMessage(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	Return True;
EndFunction // SetSettingsAsync

#EndRegion