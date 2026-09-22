
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(Object.Hotel) Then
			pCancel = True;
		EndIf;
	EndIf;	
	vObj = FormAttributeToValue("Object");	
	If vObj.IsNew() Then
		// Use current time by default
		vObj.SetTime(AutoTimeMode.CurrentOrLast); 	
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;
	EndIf;
	// Set document number and date appearances
	If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
		Items.Number.ReadOnly = True;
		Items.Number.Enabled = False;
		Items.Date.ReadOnly = True;
		Items.Date.Enabled = False;
		Items.Date.ChoiceButton = False;
	EndIf;
	// Save current document date
	OldDate = vObj.Date;
	ValueToFormAttribute(vObj, "Object");
	// Set form items appearance
	RefreshDisplay();
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure // DateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	HotelOnChangeAtServer();
EndProcedure // HotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomInterfaceTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vFormParameters = New Structure("Filter", New Structure("InterfaceType", Object.InterfaceType));
	OpenForm("Catalog.RoomInterfaceTypes.Form.tcChoiceForm", vFormParameters, pItem, UUID);
EndProcedure // RoomInterfaceTypeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomInterfaceTypeOnChange(pItem)
	If ValueIsFilled(Object.RoomInterfaceType) Then
		Object.ExtraParameters = tcOnServer.cmGetAttributeByRef(Object.RoomInterfaceType, "ExtraParameters");	
	EndIf; 
	RefreshDisplay();
EndProcedure // RoomInterfaceTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InterfaceTypeOnChange(pItem)
	RefreshDisplay();
EndProcedure // InterfaceTypeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CancelCommand(pCommand)
	Object.IsCanceled = True;
	Object.IsProcessed = False;
	If Write(New Structure("WriteMode", DocumentWriteMode.Write)) Then
		Modified = False;
		Close();
	EndIf;
EndProcedure // CancelCommand

// -----------------------------------------------------------------------------
&AtClient
Procedure SetDeletionMarkAndClose(pCommand)
	Object.DeletionMark = True;
	If Write(New Structure("WriteMode", DocumentWriteMode.Write)) Then
		Modified = False;
		Close();
	EndIf;
EndProcedure // SetDeletionMarkAndClose

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeExtraParameters(pCommand)
	If Not ValueIsFilled(Object.RoomInterfaceType) Then
		Return;	
	EndIf;
	
	vExternalSystem = tcOnServer.cmGetAttributeByRef(Object.RoomInterfaceType, "ExternalSystem");  
	If Not ValueIsFilled(vExternalSystem) Then
		Return;	
	EndIf;     
	
	vDataProcessor =  tcOnServer.cmGetAttributeByRef(vExternalSystem, "DataProcessor");
	If Not ValueIsFilled(vDataProcessor) Then
		Return;	
	EndIf;
	
	vNameDataProcessor = GetNameDataProcessor(vDataProcessor, "tcExtraSettingsForm");
	If vNameDataProcessor = Undefined Then
		Return;	
	EndIf; 
	
	vParametrs = New Structure("DataProcessor, InteractionParameters, ExtraParameters, RoomInterfaceType", vDataProcessor, vExternalSystem, Object.ExtraParameters, Object.RoomInterfaceType);
	vNotifyDescription = New NotifyDescription("AfterChangeExtraParameters", ThisObject);
	OpenForm(vNameDataProcessor, vParametrs, ThisObject, UUID,,, vNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);   
EndProcedure // ChangeExtraParameters

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChangeExtraParameters(pJSON, pExtraParameters) Export 
	If pJSON <> Undefined Then  
		Object.IsProcessed = False; 
		Object.ExtraParametersChangeIsRequested = True;
		Object.ExtraParameters = TrimAll(pJSON); 		
	EndIf;
EndProcedure // AfterChangeExtraParameters

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetNameDataProcessor(pDataProcessor, pFormName = "")
	Return Catalogs.DataProcessors.GetNameDataProcessorByProcessing(pDataProcessor, pFormName);	
EndFunction // GetNameDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	// Automatically assign new document number if year has changed
	If ValueIsFilled(Object.Date) And ValueIsFilled(OldDate) Then
		If Year(OldDate) <> Year(Object.Date) Then
			vObj = FormAttributeToValue("Object");	
			vObj.SetNewNumber();
			ValueToFormAttribute(vObj, "Object");
			RefreshDisplay();
		EndIf;
		OldDate = Object.Date;
	EndIf;
EndProcedure // DateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()
	If ValueIsFilled(Object.Hotel) Then
		vObj = FormAttributeToValue("Object");	
		vObj.SetNewNumber();
		ValueToFormAttribute(vObj, "Object");
		RefreshDisplay();
	EndIf;
EndProcedure // HotelOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	If ValueIsFilled(Object.RoomInterfaceType) Then
		If Object.InterfaceType <> Object.RoomInterfaceType.InterfaceType Then
			Object.InterfaceType = Object.RoomInterfaceType.InterfaceType;
		EndIf;
		Items.ExtraParameters.TextEdit = Not ValueIsFilled(Object.RoomInterfaceType.ExternalSystem); 
		Items.FormChangeExtraParameters.Enabled = CheckFormChangeExtraParameters(Object.RoomInterfaceType.ExternalSystem);	
		Items.DecorationRoomInterfaceType.Picture = GetInterfaceTypePicture(Object.RoomInterfaceType.InterfaceType);
		Items.InterfaceType.ChoiceButton = False;
		Items.InterfaceType.TextEdit = False;
		Items.InterfaceType.ReadOnly = True;
	Else 
		Items.ExtraParameters.TextEdit = True; 
		Items.FormChangeExtraParameters.Enabled = False;
		Items.DecorationRoomInterfaceType.Picture = PictureLib.Empty;
		Items.InterfaceType.ChoiceButton = True;
		Items.InterfaceType.TextEdit = True;
		Items.InterfaceType.ReadOnly = False;
	EndIf;
	If Not ValueIsFilled(Object.Ref) Then
		Items.FormCancelCommand.Enabled = False;
		Items.FormCancelCommand.Visible = False;
		Items.DeletionMark.Visible = False;
		Items.IsCanceled.Visible = False;
		Items.CancellationDate.Visible = False;
		Items.CancellationAuthor.Visible = False;
		Items.IsProcessed.Visible = False;
		Items.MessageIsDelivered.Visible = False;
		Items.MessageDeliveryDateTime.Visible = False;
		Items.PeriodOfStayExtensionIsRequested.Visible = False;
		Items.GuestNameChangeIsRequested.Visible = False;
	Else
		If Object.DeletionMark Then
			ReadOnly = True;
			Items.FormCancelCommand.Enabled = False;
			Items.FormCancelCommand.Visible = False;
			Items.FormSetDeletionMark.Enabled = False;
			Items.FormSetDeletionMark.Visible = False;
			Items.PeriodOfStayExtensionIsRequested.Enabled = False;
			Items.GuestNameChangeIsRequested.Enabled = False;
		ElsIf Object.IsCanceled Then
			ReadOnly = True;
			Items.FormCancelCommand.Enabled = False;
			Items.FormCancelCommand.Visible = False;
			Items.FormSetDeletionMark.Enabled = False;
			Items.FormSetDeletionMark.Visible = False;
			Items.PeriodOfStayExtensionIsRequested.Enabled = False;
			Items.GuestNameChangeIsRequested.Enabled = False;
		ElsIf Object.IsProcessed Then
			Items.FormSetDeletionMark.Enabled = False;
			Items.FormSetDeletionMark.Visible = False;
			If ValueIsFilled(Object.RoomInterfaceType) And Object.RoomInterfaceType.ManualCancelIsForbidden Then
				Items.FormCancelCommand.Enabled = False;
				Items.FormCancelCommand.Visible = False;
			EndIf;
		EndIf;
		Items.PeriodOfStayExtensionIsRequested.Visible = False;
		Items.GuestNameChangeIsRequested.Visible = False;
		If ValueIsFilled(Object.RoomInterfaceType) Then
			If Not IsBlankString(Object.RoomInterfaceType.PeriodOfStayExtentionParameters) Then
				Items.PeriodOfStayExtensionIsRequested.Visible = True;
			EndIf;
			If Not IsBlankString(Object.RoomInterfaceType.GuestNameChangeParameters) Then
				Items.GuestNameChangeIsRequested.Visible = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // RefreshDisplay

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckFormChangeExtraParameters(pExternalSystem)
	If Not ValueIsFilled(pExternalSystem) Then
		Return False;	
	EndIf;   
	
	vDataProcessor = pExternalSystem.DataProcessor;
	If Not ValueIsFilled(vDataProcessor) Then
		Return False;	
	EndIf;
	
	vObjDataProcessor = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDataProcessor);
	If vObjDataProcessor = Undefined Then
		Return False;	
	EndIf;
	
	vFormExists = vObjDataProcessor.Metadata().Forms.Find("tcExtraSettingsForm"); 
	If vFormExists = Undefined Then
		Return False;
	EndIf;  
	
	Return True;
EndFunction // CheckFormChangeExtraParameters

// -----------------------------------------------------------------------------
&AtServer
Function GetInterfaceTypePicture(pInterfaceType) Export
	If pInterfaceType = Enums.InterfaceTypes.Internet Then
		Return PictureLib.HTMLPage;
	ElsIf pInterfaceType = Enums.InterfaceTypes.Minibar Then
		Return PictureLib.Minibar;
	ElsIf pInterfaceType = Enums.InterfaceTypes.Phone Then
		Return PictureLib.Phone;
	ElsIf pInterfaceType = Enums.InterfaceTypes.TV Then
		Return PictureLib.TV;
	Else
		Return PictureLib.Empty;
	EndIf;
EndFunction // GetInterfaceTypePicture

#EndRegion
