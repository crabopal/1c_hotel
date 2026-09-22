
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

	If Not ValueIsFilled(Object.Ref) And Not ValueIsFilled(Object.Hotel) Then
		Object.Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Object.Hotel) Then
		Items.Hotel.ReadOnly = True;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If vEventData.DeviceType = "MagneticStripeCardReader" And Not ReadOnly Then
		Object.Identifier = vEventData.DeviceData;
	EndIf;
EndProcedure // ExternalEvent

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	CurrentObject.ChangeAuthor = SessionParameters.CurrentUser;
	CurrentObject.ChangeDate = CurrentSessionDate();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure FolioOnChange(pItem)
	FolioOnChangeAtServer();
EndProcedure // FolioOnChange

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure FolioOnChangeAtServer()
	If ValueIsFilled(Object.Folio) Then
		Object.GuestGroup = Object.Folio.GuestGroup;
		Object.Client = Object.Folio.Client;
		Object.Room = Object.Folio.Room;
		Object.DateTimeFrom = Object.Folio.DateTimeFrom;
		Object.DateTimeTo = Object.Folio.DateTimeTo;
		Object.Hotel = Object.Folio.Hotel;
	EndIf;
EndProcedure // FolioOnChangeAtServer

#EndRegion
