
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
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	// Set services table appearance
	SetServicesAppearance();
	
	// Check permissions
	If Not Catalogs.ServiceGroups.UserHasPermissionToManageServiceGroups() Then
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = True;
		Else
			ThisObject.ReadOnly = True;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure IncludeAllOnChange(pItem)
	SetServicesAppearance();
EndProcedure // IncludeAllOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ServicesChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	vNewRow = Object.Services.Add();
	vNewRow.Service = pSelectedValue; 
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Selection(pCommand)
	// APDEX
	vKeyOperation = "Catalog.Services.Form.tcChoiceForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
	
	OpenForm("Catalog.Services.Form.tcChoiceForm", New Structure("CloseOnChoice, Hotel", False, Object.Hotel), Items.Services);
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SetServicesAppearance()
	If Object.IncludeAll Then
		Items.Services.Enabled = False;
	Else
		Items.Services.Enabled = True;
	EndIf;
EndProcedure // SetServicesAppearance

#EndRegion
