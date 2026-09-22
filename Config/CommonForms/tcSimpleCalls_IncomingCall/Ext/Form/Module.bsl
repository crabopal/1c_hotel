
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	vPhoneNumber = Parameters.PhoneNumber;
	
	vTypePhoneNumber 		= "";
	vRegion 				= "";
	tcSimpleCallsOnServer.GetRepresentationNumber(vPhoneNumber,vRegion,vTypePhoneNumber);
	
	PhoneNumber = vPhoneNumber;
	Region		= vRegion;
	TypeNumber  = vTypePhoneNumber;
	
	If IsBlankString(Region) Then
		Region = NStr("en = 'could not be determined'; ru = 'не удалось определить'; de = 'konnte nicht ermittelt werden'");
	Else
		Region = " "+Region;
	EndIf;
	
	If ValueIsFilled(Parameters.Room) Then
		Region 		= NStr("en = 'The call from the room'; ru = 'Звонок из номера'; de = 'Der Anruf aus dem Zimmer'");
		TypeNumber  = Parameters.Room;
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	AttachIdleHandler("HandlingResponse", 10, False);
	DateTimeOpenForm = CurrentDate();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientClick(Item, StandardProcessing)
	StandardProcessing = False;
	OpenForm("Catalog.Clients.ObjectForm", New Structure("Key", Client));
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CustomerClick(Item, StandardProcessing)
	StandardProcessing = False;
	OpenForm("Catalog.Customers.ObjectForm", New Structure("Key", Customer));
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Reservation(Command)
	vParams = New Structure;
	vParams.Insert("Customer", Customer);
	vParams.Insert("CheckInDate", CheckInDate);
	vParams.Insert("CheckOutDate", CheckOutDate);
	vParams.Insert("GuestGroup", CheckOutGroup);
	OpenForm("Document.Reservation.Form.tcDocumentForm", vParams);
	Close();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcesCalendar(Command)
	OpenForm("Catalog.Resources.Form.tcResourcesCalendar");
	Close();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure HandlingResponse()
	vCloseForm = tcSimpleCallsOnServer.CheckAnswer(IDCall);
	If vCloseForm Then
		Close();
	EndIf;	
	
	If tcSimpleCallsOnServer.TimeOff(DateTimeOpenForm, amSimpleCallsParameters.CloseWindows) Then
		Close();
	EndIf;	
EndProcedure	

#EndRegion
