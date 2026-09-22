
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	vPhoneNumber = Parameters.PhoneNumber;
	
	vTypePhoneNumber 		= "";
	vRegion 				= "";
	tcSimpleCallsOnServer.GetRepresentationNumber(vPhoneNumber, vRegion, vTypePhoneNumber);
	
	
	PhoneNumber = vPhoneNumber;
	Region		= vRegion;
	TypeNumber  = vTypePhoneNumber;
	
	If IsBlankString(Region) Then
		Region = NStr("en = 'could not be determined'; ru = 'не удалось определить'; de = 'konnte nicht ermittelt werden'");
	Else
		Region = " "+Region;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	AttachIdleHandler("HandlingResponse", 10, False);
	DateTimeOpenForm = CurrentDate();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveClient(Command)
	vFormData = New Structure;
	vFormData.Insert("LastName", LastName);
	vFormData.Insert("FirstName", FirstName);
	vFormData.Insert("Phone", tcSimpleCallsOnServer.ConvertPhoneNumber(PhoneNumber));       
	vFormData.Insert("EMail", EMail);
	vFormData.Insert("Phone", PhoneNumber);
	vFormData.Insert("SecondName", "");
	vFormData.Insert("DateOfBirth", Date("10000101000000"));
	vFormData.Insert("IdentityDocumentSeries", 0);
	vFormData.Insert("IdentityDocumentNumber", 0);
	vFormData.Insert("IdentityDocumentIssueDate", Date("10000101000000"));
	vParams = New Structure;
	vParams.Insert("FormData", vFormData);  
	OpenForm("Catalog.Clients.Form.tcItemForm", vParams);
	Close();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveCustomer(Command)
	OpenForm("Catalog.Customers.ObjectForm", New Structure("Key", Undefined));
	Close();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure NewReservation(Command)
	vParams = New Structure;
	vFrm = GetForm("Document.Reservation.ObjectForm");
	If ValueIsFilled(CheckInDate) Then
		vParams.Insert("CheckInDate", CheckInDate);
	EndIf;	
	If ValueIsFilled(CheckOutDate) Then
		vParams.Insert("CheckOutDate", CheckOutDate);
	EndIf;	
	OpenForm("Document.Reservation.Form.tcDocumentForm", vParams);
	Close();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcesCalendar(Command)
	OpenForm("Catalog.Resources.Form.ResourcesCalendar");
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
