
#Region EventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	If Not CheckUserPermission() Then
		Raise NStr("en='You do not have rights to this function!';ru='Нет прав на эту функцию!';de='Sie haben keine Rechte für diese Funktion!'");
	EndIf;
	#If Not MobileClient Then 
		// APDEX
		vKeyOperation = "Document.Accommodation.Form.tcAccommodationListForm.Archive.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
		
		OpenForm("Document.Accommodation.Form.tcAccommodationListForm", New Structure("SelFilterStatus", 1));
	#Else
		OpenForm("Document.Accommodation.Form.mcAccommodationListForm", New Structure("SelFilterStatus", 1));	
	#EndIf
	Notify("Document.Accommodation.ListForm.Archive");
EndProcedure // CommandProcessing

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
// 
// Returns:
//  Boolean - have user permission
//
&AtServer
Function CheckUserPermission()
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If Not ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction // CheckUserPermission

#EndRegion    
