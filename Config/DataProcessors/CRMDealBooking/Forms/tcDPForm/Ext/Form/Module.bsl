
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)  
	If Not Parameters.Property("adults") Then
		Raise НСтр("en = 'Data processor is not intended for direct use.'; 
				   |de = 'Der Datenprozessor ist nicht für den direkten Gebrauch bestimmt.'; 
				   |ru = 'Обработка не предназначена для непосредственного использования.'");
	EndIf;

	vAdults = Parameters.adults;
	If vAdults = Undefined Or vAdults = 0 Then
		vAdults = 1;	
	EndIf;	
	vNumberOfKids = Parameters.Kids1; 
	If vNumberOfKids = Undefined Then
		vNumberOfKids = 0;	
	EndIf;
	vParamsForm = New Structure();
	vParamsForm.Insert("Hotel", Parameters.hotel);
	vParamsForm.Insert("CheckInDate", Parameters.CheckInDate);
	vParamsForm.Insert("CheckOutDate", Parameters.CheckOutDate);
	vParamsForm.Insert("NumberOfAdults", vAdults);
	vParamsForm.Insert("NumberOfKids", vNumberOfKids);
	vParamsForm.Insert("Guest", Parameters.Guest);
	vParamsForm.Insert("GuestGroup", Parameters.GuestGroup);
	vParamsForm.Insert("Hotel", Parameters.hotel);
	vParamsForm.Insert("SelectRoomRateMode", True);
	
	ParamsNewForm = vParamsForm;
EndProcedure 

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)    
	OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", ParamsNewForm, Undefined, New UUID());
	AttachIdleHandler("CloseWindow", 0.1, True);
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure CloseWindow()
	Close();
EndProcedure

#EndRegion