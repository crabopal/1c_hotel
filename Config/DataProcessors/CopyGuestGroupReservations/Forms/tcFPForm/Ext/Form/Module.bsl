
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)	
	// Fill parameters
	Object.GuestGroupFrom = Parameters.GuestGroupFrom;
	Object.CheckInDateFrom = Parameters.CheckInDateFrom;
	If ValueIsFilled(Object.GuestGroupFrom) Then
		Object.Hotel = Object.GuestGroupFrom.Owner;
	Else
		Object.Hotel = SessionParameters.CurrentHotel;
	EndIf;
	Object.CopyReservations = True;
	Object.CopyResourceReservations = True;
EndProcedure //  OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelClearingAtServer(pStandardProcessing)
	If Not IsInRole("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // HotelClearingAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	HotelClearingAtServer(pStandardProcessing);
EndProcedure // HotelClearing

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	// Check parameters
	If Not ValueIsFilled(Object.Hotel) Then
		ShowMessageBox(, NStr("en='Please fill hotel!';ru='Выберите гостиницу!';de='Wählen Sie das Hotel!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(Object.GuestGroupFrom) Then
		ShowMessageBox(,NStr("en = 'Please fill guest group which reservations should be copied!'; 
								|de = 'Wählen Sie die Gästegruppe, derer Reservierungen kopiert werden müssen!'; 
								|ru = 'Выберите группу гостей брони которой нужно скопировать!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(Object.CheckInDateTo) Then
		ShowMessageBox(,NStr("en = 'Please fill new check-in date to be set in new copied reservations!'; 
							 |de = 'Geben Sie das neue Anreisedatum an, welches in der kopierten Reservierung festgelegt werden muss!'; 
							 |ru = 'Укажите новую дату заезда, которую нужно установить в скопированной брони!'"));
		Return;
	EndIf;	
	CopyAtServer();
	// OK
	ShowMessageBox(, NStr("en = 'Guest group reservations were copied successfully to the group: '; 
						  |de = 'Die Rücklagen der Gästegruppen wurden erfolgreich kopiert in die Gruppe: '; 
						  |ru = 'Резервирования группы гостей были успешно скопированы в группу: '") + Format(tcOnServer.cmGetAttributeByRef(Object.GuestGroupTo, "Code"), "NFD=0; NZ="));
EndProcedure // ActionsExecute

#EndRegion        

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure CopyAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmExecute();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // CopyAtServer

#EndRegion

