#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelHotel = SessionParameters.CurrentHotel;
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	EndIf;
	SelHotelOnChangeAtServer();	
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Document.Charge.Write" Or 
	   pEventName = "Document.Payment.Write" Or
	   pEventName = "Document.Preauthorisation.Write" Or
	   pEventName = "Document.DepositTransfer.Write" Or
	   pEventName = "Document.Return.Write" Then
		Items.List.Refresh();
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		If Not IsBlankString(vEventData.DeviceData) Then
			// Try to find client identification card by Id
			vCard = tcOnServer.GetClientIdentificationCardById(vEventData.DeviceData);
			If ValueIsFilled(vCard) Then
				vFolio = tcOnServer.cmGetAttributeByRef(vCard, "Folio");
				If ValueIsFilled(vFolio) Then
					tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Ref", vFolio, DataCompositionComparisonType.Equal, , True);
				EndIf;
			EndIf;
		Else
			tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Ref", , , , False);
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SelHotelOnChangeAtServer();
EndProcedure // SelHotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(pItem)
	If ValueIsFilled(SelClient) Then
		AttributeChangeAtServer("Client", SelClient);
	Else
		ClearingAttributeAtServer("Client");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerOnChange(pItem)
	If ValueIsFilled(SelCustomer) Then
		AttributeChangeAtServer("Customer", SelCustomer);
	Else
		ClearingAttributeAtServer("Customer");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	If ValueIsFilled(SelGuestGroup) Then
		SelOnlyFAFolios = False;
		AttributeChangeAtServer("GuestGroup", SelGuestGroup);
	Else
		ClearingAttributeAtServer("GuestGroup");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(pItem)
	If ValueIsFilled(SelRoom) Then
		AttributeChangeAtServer("Room", SelRoom);
	Else
		ClearingAttributeAtServer("Room");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFolioNumberOnChange(pItem)
	If ValueIsFilled(SelFolioNumber) Then
		AttributeChangeAtServer("Number", SelFolioNumber, DataCompositionComparisonType.Contains);
	Else
		ClearingAttributeAtServer("Number");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCheckInDateOnChange(pItem)
	If ValueIsFilled(SelCheckInDate) Then
		AttributeChangeAtServer("DateTimeFrom.BeginDates.BegOfDay", BegOfDay(SelCheckInDate));
	Else
		ClearingAttributeAtServer("DateTimeFrom.BeginDates.BegOfDay");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCheckOutDateOnChange(pItem)
	If ValueIsFilled(SelCheckOutDate) Then
		AttributeChangeAtServer("DateTimeTo.BeginDates.BegOfDay", BegOfDay(SelCheckOutDate));
	Else
		ClearingAttributeAtServer("DateTimeTo.BeginDates.BegOfDay");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelOnlyFAFoliosOnChange(Item)
	If SelOnlyFAFolios Then
		SelGuestGroup = Undefined;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "GuestGroup", 0, DataCompositionComparisonType.NotFilled, , True);
	Else
		ClearingAttributeAtServer("GuestGroup");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelOnlyOpenFoliosOnChange(Item)
	If SelOnlyOpenFolios Then
		AttributeChangeAtServer("IsClosed", False);
	Else
		ClearingAttributeAtServer("IsClosed");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelNonZeroBalanceOnChange(Item)
	If SelNonZeroBalance Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "SumBalance", 0, DataCompositionComparisonType.NotEqual, , True);
	Else
		ClearingAttributeAtServer("SumBalance");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDiscountTypeOnChange(Item)
	If ValueIsFilled(SelDiscountType) Then
		AttributeChangeAtServer("FolioDiscountType", SelDiscountType);
	Else
		ClearingAttributeAtServer("FolioDiscountType");
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolioTransactions(pCommand)
	vCurFolio = Items.List.CurrentRow;
	If ValueIsFilled(vCurFolio) Then
		// APDEX
		vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
		
		vParamsStruct = New Structure("ParametersStructure", New Structure("ObjectRef", vCurFolio));
		OpenForm("CommonForm.tcFoliosForm", vParamsStruct, ThisForm, vCurFolio);
	EndIf;
EndProcedure // OpenFolioTransactions

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateFolio(pCommand)
	If CheckFilling() Then
		OpenForm("Document.Folio.ObjectForm", New Structure("SelHotel", SelHotel), ThisForm, UUID); 
	EndIf;
EndProcedure // CreateFolio

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SelHotelOnChangeAtServer()
	List.Parameters.SetParameterValue("qHotel", SelHotel);
	// Hotel column appearance
	If Not ValueIsFilled(SelHotel) Then
		Items.Hotel.Visible = True;
	Else
		Items.Hotel.Visible = False;
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");	
EndProcedure // SelHotelOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	If ValueIsFilled(pValue) Then
		vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, pValue, vComparisonType, , True);
	EndIf;
EndProcedure // AttributeChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, , , , False);
EndProcedure // ClearingAttributeAtServer

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