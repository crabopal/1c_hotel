
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Object.Hotel = SessionParameters.CurrentHotel;
	Object.GuestFullName = NStr("en='Read key or manually enter room and guest name...'; 
	                            |ru='Прочитайте ключ или укажите комнату и часть ФИО гостя...'; 
								|de='Lesen Sie die Karte oder geben Sie die Zimmernummer und einen Teil des Namens des Gastes ein...'");
	Items.GuestFullName.TextColor = WebColors.DarkBlue;
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
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		// Fill key ID and call processing
		Object.KeyID = vEventData.DeviceData;
		SearchByKeyIDAtServer();
		
		// Clear form in 10 seconds
		AttachIdleHandler("ClearForm", 10, True);
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure KeyIDOnChange(pItem)
	SearchByKeyIDAtServer();
	AttachIdleHandler("ClearForm", 10, True);
EndProcedure // KeyIDOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SearchRoomOnChange(pItem)
	SearchByRoomAndNameAtServer();
	If Not IsBlankString(Object.SearchRoom) And Not IsBlankString(Object.SearchName) Then
		AttachIdleHandler("ClearForm", 10, True);
	EndIf;
EndProcedure // SearchRoomOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SearchNameOnChange(pItem)
	SearchByRoomAndNameAtServer();
	If Not IsBlankString(Object.SearchRoom) And Not IsBlankString(Object.SearchName) Then
		AttachIdleHandler("ClearForm", 10, True);
	EndIf;
EndProcedure // SearchNameOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearFormCommand(pCommand)
	ClearForm();
EndProcedure // ClearFormCommand

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SearchByKeyIDAtServer()
	// Try to find client identification card with such Id
	If Not IsBlankString(Object.KeyID) Then
		vCard = cmGetClientIdentificationCardById(TrimAll(Object.KeyID));
		If ValueIsFilled(vCard) Then
			Object.Room = vCard.Room;
			Object.CheckInDate = vCard.DateTimeFrom;
			Object.CheckOutDate = vCard.DateTimeTo;
			vClient = vCard.Client;
			If ValueIsFilled(vClient) Then
				Object.GuestFullName = vClient.FullName;
				Items.GuestFullName.TextColor = WebColors.DarkGreen;
			Else
				Object.GuestFullName = NStr("en='Key active but guest empty...'; 
				                            |ru='Ключ действует, но гость не указан...'; 
											|de='Der Schlüssel ist gültig, aber der Gast ist nicht angegeben...'");
				Items.GuestFullName.TextColor = WebColors.DarkGreen;
			EndIf;
		Else
			Object.GuestFullName = NStr("en='Key not found!'; 
			                            |ru='Ключ не найден!'; 
										|de='Schlüssel nicht gefunden!'");
			Items.GuestFullName.TextColor = WebColors.Red;
			Object.Room = Undefined;
			Object.CheckInDate = '00010101';
			Object.CheckOutDate = '00010101';
		EndIf;
	Else
		Object.GuestFullName = NStr("en='Read key or manually enter room and guest name...'; 
		                            |ru='Прочитайте ключ или укажите комнату и часть ФИО гостя...'; 
									|de='Lesen Sie die Karte oder geben Sie die Zimmernummer und einen Teil des Namens des Gastes ein...'");
		Items.GuestFullName.TextColor = WebColors.DarkBlue;
		Object.Room = Undefined;
		Object.CheckInDate = '00010101';
		Object.CheckOutDate = '00010101';
	EndIf;
EndProcedure // SearchByKeyIDAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure SearchByRoomAndNameAtServer()
	Object.KeyID = "";
	If ValueIsFilled(Object.SearchRoom) And Not IsBlankString(Object.SearchName) Then
		vDocRef = FindDocByRoomAndName();
		If ValueIsFilled(vDocRef) Then
			Object.Room = vDocRef.Room;
			Object.CheckInDate = vDocRef.CheckInDate;
			Object.CheckOutDate = vDocRef.CheckOutDate;
			vClient = vDocRef.Guest;
			If ValueIsFilled(vClient) Then
				Object.GuestFullName = vClient.FullName;
				Items.GuestFullName.TextColor = WebColors.DarkGreen;
			Else
				Object.GuestFullName = NStr("en='Reservation is active but guest empty...'; 
				                            |ru='Размещение действует, но гость не указан...'; 
											|de='Die Reservierung ist aktiv, aber der Gast ist leer...'");
				Items.GuestFullName.TextColor = WebColors.DarkGreen;
			EndIf;
		Else
			Object.GuestFullName = NStr("en='Guest not found!'; 
			                            |ru='Гость не найден!'; 
										|de='Gast nicht gefunden!'");
			Items.GuestFullName.TextColor = WebColors.Red;
		EndIf;
	Else
		Object.GuestFullName = NStr("en='Read key or manually enter room and guest name...'; 
		                            |ru='Прочитайте ключ или укажите комнату и часть ФИО гостя...'; 
									|de='Lesen Sie die Karte oder geben Sie die Zimmernummer und einen Teil des Namens des Gastes ein...'");
		Items.GuestFullName.TextColor = WebColors.DarkBlue;
	EndIf;	
EndProcedure // SearchByRoomAndNameAtServer

// --------------------------------------------------------------------------------
&AtServer
Function FindDocByRoomAndName()
	vDoc = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Hotel = &qHotel
	|	AND Accommodation.Room = &qRoom
	|	AND Accommodation.GuestFullName LIKE &qName
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.Posted
	|
	|ORDER BY
	|	Accommodation.SortCode";
	vQry.SetParameter("qHotel", Object.Hotel);
	vQry.SetParameter("qRoom", Object.SearchRoom);
	vQry.SetParameter("qName", "%" + TrimAll(Object.SearchName) + "%");
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		vDoc = vDocs.Get(0).Ref;
	EndIf;
	Return vDoc;
EndFunction // FindDocByRoomAndName

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearForm() Export
	Object.KeyID = "";
	Object.SearchRoom = Undefined;
	Object.SearchName = "";
	Object.Room = Undefined;
	Object.CheckInDate = '00010101';
	Object.CheckOutDate = '00010101';
	Object.GuestFullName = NStr("en='Read key or manually enter room and guest name...'; 
	                            |ru='Прочитайте ключ или укажите комнату и часть ФИО гостя...'; 
								|de='Lesen Sie die Karte oder geben Sie die Zimmernummer und einen Teil des Namens des Gastes ein...'");
	Items.GuestFullName.TextColor = WebColors.DarkBlue;
EndProcedure // ClearForm

#EndRegion


