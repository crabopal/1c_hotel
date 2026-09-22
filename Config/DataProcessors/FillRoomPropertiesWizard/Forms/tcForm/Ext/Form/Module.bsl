
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Object.Hotel = SessionParameters.CurrentHotel;	
EndProcedure

&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	If Not CheckHotelViewAccess() Then
		pStandardProcessing = False;
	EndIf;
EndProcedure

&AtServerNoContext
Function CheckHotelViewAccess()
	Return AccessRight("View", Metadata.Catalogs.Hotels);
EndFunction

&AtClient
Procedure RoomsChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	RoomsChoiceProcessing_AtServer(pSelectedValue);
EndProcedure

&AtServer
Procedure RoomsChoiceProcessing_AtServer(pSelectedValue)
	If ValueIsFilled(pSelectedValue) And 
		TypeOf(pSelectedValue) = Type("CatalogRef.Rooms") And 
		Not pSelectedValue.IsFolder Then
		If Object.Rooms.FindRows(New Structure("Room", pSelectedValue)).Count() = 0 Then
			vRow = Object.Rooms.Add();
			vRow.Room = pSelectedValue;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ChooseRoomsAction(pCommand)
	vParams 				= New Structure("ChoiceMode, Filter");
	vParams.ChoiceMode		= True;
	If ValueIsFilled(Object.Hotel) Then
		vParams.Filter		= New Structure("Owner", Object.Hotel);
	EndIf;
	vForm 					= GetForm("Catalog.Rooms.ChoiceForm", vParams, Items.Rooms, ThisForm);
	vForm.CloseOnChoice 	= False;
	vForm.CloseOnOwnerClose = True;
	vForm.WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow; 
	vForm.Open();
EndProcedure

&AtServer
Procedure FormExecuteAtServer()
	vObj = FormAttributeToValue("Object", Type("DataProcessorObject.FillRoomPropertiesWizard"));
	vObj.pmExecute();
EndProcedure

&AtClient
Procedure FormExecute(pCommand)
	FormExecuteAtServer();
	ShowMessageBox(, NStr("en='Done!'; ru='Выполнено!'; de='Fertig!'"));
EndProcedure
