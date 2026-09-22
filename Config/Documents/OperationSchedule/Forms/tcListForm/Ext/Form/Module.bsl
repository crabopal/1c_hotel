
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Filter by current hotel
	SelHotel = SessionParameters.CurrentHotel;	
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	EndIf;
	SelHotelOnChangeAtServer();

	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

#EndRegion


#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeRowChange(pItem, pCancel)
	// APDEX
	vKeyOperation = "Document.OperationSchedule.Form.tcDocumentForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
EndProcedure // ListBeforeRowChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SelHotelOnChangeAtServer();
EndProcedure // SelHotelOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CreateOperationSchedule(pCommand)
	If CheckFilling() Then
		OpenForm("Document.OperationSchedule.ObjectForm", New Structure("SelHotel", SelHotel), ThisObject, UUID); 
	EndIf;
EndProcedure // CreateOperationSchedule

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SelHotelOnChangeAtServer()
	List.Parameters.SetParameterValue("qHotel", SelHotel);   
		
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");		
EndProcedure // SelHotelOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	If Not IsInRoleAtServer("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // SelHotelClearing

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRoleName)
	Return IsInRole(pRoleName);
EndFunction // IsInRoleAtServer

#EndRegion
