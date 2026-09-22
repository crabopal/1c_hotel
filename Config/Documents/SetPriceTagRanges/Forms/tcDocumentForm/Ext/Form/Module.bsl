
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
	 
	// Write button appearance
	If Object.Posted Then
		Items.FormWrite.Enabled = False;
		Items.FormWrite.Visible = False;
	EndIf;
	
	vObj = FormAttributeToValue("Object");
	
	If vObj.IsNew() Then
		If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage prices!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
			Return;
		EndIf;
		vObj.pmFillAttributesWithDefaultValues();
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	Else
		// Check user rights to edit room rates
		If Not cmCheckUserPermissions("HavePermissionToApproveRoomRates") Then
			Items.RoomRatesApproved.Enabled = False;
		Else
			Items.RoomRatesApproved.Enabled = True;
		EndIf;
	EndIf;
	
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(vObj.Hotel) And SessionParameters.CurrentHotel <> vObj.Hotel Then
			pCancel = True;
			Return;
		EndIf;
	EndIf;
	
	ValueToFormAttribute(vObj, "Object");
	
	OldDate = Object.Date;
	
	FillTableHeaders();
	RoomRatesApprovedAppearance();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	WasModified = (ThisObject.Modified Or Not Object.Posted) And 
	              pWriteParameters.WriteMode = DocumentWriteMode.Posting;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	vMessage = "";
	vAttributeInErr = "";
	pCancel = pCurrentObject.pmCheckDocumentAttributes(vMessage, vAttributeInErr);
	If pCancel Then
		SetObjectAndFormAttributeConformity(pCurrentObject, "Object");
		vUM = New UserMessage();
		vUM.SetData(pCurrentObject);
		vUM.Field = vAttributeInErr;
		vUM.Text = NStr(vMessage);
		vUM.Message();
	Else
		If pCurrentObject.Date > CurrentSessionDate() Then
			pCurrentObject.IsInFuture = True;
		Else
			pCurrentObject.IsInFuture = False;
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	pCurrentObject.pmWriteToSetPriceTagRangesChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	
	// Update price cache if necessary
	vHotel = pCurrentObject.Hotel;
	If WasModified And pCurrentObject.Posted And 
	   ValueIsFilled(vHotel) And 
	   vHotel.UseRoomRateDailyPrices And 
	   Not pCurrentObject.IsInFuture Then
		vRates = pCurrentObject.pmGetListOfActiveRoomRates();
		vRatesList = New ValueList();
		vRatesList.LoadValues(vRates.UnloadColumn("RoomRate"));
		
		vDayTypes = pCurrentObject.pmGetListOfActiveCalendarDayTypes();
	
		vDateFrom = '39991231';
		vDateTo = '00010101';
		
		cmGetCacheEffectivePeriod(vRatesList, vDayTypes, vDateFrom, vDateTo);
		
		If vDateFrom <= vDateTo Then
			cmRunFillRoomRatePricesCacheAtServer(vHotel, vRatesList, vDateFrom, vDateTo);
		EndIf;
	EndIf;
	
	WasModified = False;
EndProcedure // AfterWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "SetPriceTagRangesActionRestore" Then		
		Restore(pParameter);
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure EndValueNotIncludedOnChange(pItem)
	FillTableHeaders();
EndProcedure // EndValueNotIncludedOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesApprovedOnChange(pItem)
	RoomRatesApprovedAppearance();
EndProcedure // RoomRatesApprovedOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure // DateOnChange

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	// Automatically assign new document number if year has changed
	If ValueIsFilled(Object.Date) Then
		If ValueIsFilled(OldDate) And Year(OldDate) <> Year(Object.Date) Then
			vObj = FormAttributeToValue("Object");
			vObj.SetNewNumber();
			ValueToFormAttribute(vObj, "Object");
		EndIf;
		OldDate = Object.Date;
		If Object.Date > CurrentSessionDate() Then
			Object.IsInFuture = True;
			Items.Date.ToolTip = NStr("en='Prices will be effective after the specified date and time'; 
			                          |ru='Цены вступят в силу после указанной даты и времени'; 
									  |de='Die Preise werden nach dem angegebenen Datum und der angegebenen Uhrzeit wirksam'");
			Items.Date.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		Else
			Object.IsInFuture = False;
			Items.Date.ToolTip = "";
			Items.Date.ToolTipRepresentation = ToolTipRepresentation.None;
		EndIf;
	EndIf;
EndProcedure // DateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomRatesApprovedAppearance()
	If Object.RoomRatesApproved Then
		Items.PriceTagType.ReadOnly = True;
		Items.PriceTagRanges.ReadOnly = True;
	Else
		Items.PriceTagType.ReadOnly = False;
		Items.PriceTagRanges.ReadOnly = False;
	EndIf;
EndProcedure // RoomRatesApprovedAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure Restore(pDate)
	vObj = FormAttributeToValue("Object");	
	vRChg = InformationRegisters.SetPriceTagRangesChangeHistory;
	vRChgRec = vRChg.Get(pDate, New Structure("SetPriceTagRanges", vObj.Ref));
	vObj.pmRestoreAttributesFromHistory(vRChgRec);
	ValueToFormAttribute(vObj,"Object");	
	Modified = True;
EndProcedure // Restore

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTableHeaders()
	If Not Object.EndValueNotIncluded Then
		Items.PriceTagRangesStartValue.Title = NStr("en='Start value <'; ru='Нач. знач. <'; de='Startwert <'");
		Items.PriceTagRangesEndValue.Title = NStr("en='<= End value'; ru='<= Кон. знач.'; de='<= Endwert'");
	Else
		Items.PriceTagRangesStartValue.Title = NStr("en='Start value <='; ru='Нач. знач. <='; de='Startwert <='");
		Items.PriceTagRangesEndValue.Title = NStr("en='< End value'; ru='< Кон. знач.'; de='< Endwert'");
	EndIf;
EndProcedure // FillTableHeaders

#EndRegion
