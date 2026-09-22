
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Check user rights to use document
	vObject = FormAttributeToValue("Object");
	vHavePermissionToManageRoomInventory = cmCheckUserPermissions("HavePermissionToManageRoomInventory");
	If vObject.IsNew() Then
		If Not vHavePermissionToManageRoomInventory Then
			pCancel = True;    
			vMsg = NStr("en='You do not have rights for room inventory management!';
			                |ru='Нет прав на управление номерным фондом!';
			                |de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'");
			tcCommonFunctionOnClientServer.UserMessage(vMsg, vObject, , , True); 
			Return;
		EndIf;
		// Use 00:00:00 time by default
		vObject.SetTime(AutoTimeMode.DontUse);
		// Fill attributes with default values
		If Not ValueIsFilled(vObject.Hotel) Then
			vObject.pmFillAttributesWithDefaultValues();
		Else
			vObject.pmFillAuthorAndDate();
		EndIf;
	Else
		// Check user rights to edit document
		If Not vHavePermissionToManageRoomInventory Then
			ReadOnly = True;
		Else
			If Not vObject.IsRoomAttributesChange And Not vObject.IsRoomOutOfService Then
				vObject.IsRoomAttributesChange = True;
				If ValueIsFilled(vObject.OperationEndDate) Then
					vObject.IsRoomOutOfService = True;
				EndIf;
				ThisObject.Modified = True;
			EndIf;
		EndIf;
	EndIf;
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(vObject.Hotel) And SessionParameters.CurrentHotel <> Object.Hotel Then
			pCancel = True;
			Return;
		EndIf;
	EndIf;	
	// User rights to see and edit document number and room ref
	If Not IsInRole("Administrator") Then
		If vObject.IsNew() Then
			vObject.IsRoomAttributesChange = True;
			vObject.IsRoomOutOfService = False;
		EndIf;
		Items.GroupOutOfService.Visible = False;
		Items.GroupParameters.Visible = False;
		Items.RoomGroup.Visible = False;
		Items.RoomNumber.Visible = False;
		Items.SortCode.Visible = False;
		Items.NumberOfBedsPerRoom.Visible = False;
		Items.NumberOfPersonsPerRoom.Visible = False;
		Items.IsVirtual.ReadOnly = True;
	EndIf;
	OldDate = vObject.Date;
	ValueToFormAttribute(vObject, "Object");
	SetFormAppearanceAtServer();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		If Not pCurrentObject.IsRoomAttributesChange And Not pCurrentObject.IsRoomOutOfService Then
			pCancel = True;
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Choose action type: room attributes change or room out of service!'; 
			                                                |ru='Выберите тип действия: изменение параметров номера или вывод номера из эксплуатации!'; 
															|de='Wählen Sie den Aktionstyp aus: Zimmerparameter ändern oder Zimmer außer Betrieb setzen!'"), 
			                                           pCurrentObject, "IsRoomAttributesChange", , True);
		EndIf;
		If Not pCancel Then
			pCancel = PostDocument(pCurrentObject);
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// Repost change room documents created later
		If ValueIsFilled(pCurrentObject.Room) Then
			pCurrentObject.pmRepostChangeRoomDocumentsCreatedLater();
		EndIf;
	EndIf;
EndProcedure //  AfterWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Subsystem.Rooms.Changed", Object.Room);
EndProcedure //  AfterWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure //  DateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(Item)
	RoomTypeOnChangeAtServer();
EndProcedure //  RoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsRoomAttributesChangeOnChange(pItem)
	SetFormAppearanceAtServer();
EndProcedure // IsRoomAttributesChangeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsRoomOutOfServiceOnChange(pItem)
	If Not Object.IsRoomOutOfService And ValueIsFilled(Object.OperationEndDate) Then
		Object.OperationEndDate = '00010101';
		ThisObject.Modified = True;
	EndIf;
	SetFormAppearanceAtServer();
EndProcedure // IsRoomOutOfServiceOnChange

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetFormAppearanceAtServer()
	If ValueIsFilled(Object.Ref) Then
		Items.Hotel.ReadOnly = True;
		Items.Hotel.ChoiceButton = False;
	EndIf;
	Items.RoomGroup.Enabled = Object.IsRoomAttributesChange;
	Items.GroupRoom.Enabled = Object.IsRoomAttributesChange;
	Items.GroupRoomType.Enabled = Object.IsRoomAttributesChange;
	Items.GroupPaxNumbers.Enabled = Object.IsRoomAttributesChange;
	Items.OperationEndDate.Enabled = Object.IsRoomOutOfService;
EndProcedure // SetFormAppearanceAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomTypeOnChangeAtServer()
	If ValueIsFilled(Object.RoomType) Then
		Object.IsVirtual = Object.RoomType.IsVirtual;
		Object.NumberOfBedsPerRoom = Object.RoomType.NumberOfBedsPerRoom;
		Object.NumberOfPersonsPerRoom = Object.RoomType.NumberOfPersonsPerRoom;
	EndIf;
EndProcedure //  RoomTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function PostDocument(pObject)
	Var vErrorMessage, vAttributeInErr;
	vCancel = False;
	Try
		vCancel = pObject.pmCheckDocumentAttributes(vErrorMessage, vAttributeInErr);
		If vCancel Then
			WriteLogEvent(NStr("en = 'Document.Posting'; de = 'Document.Posting'; ru = 'Документ.Проведение'"), EventLogLevel.Warning, pObject.Metadata(), pObject.Ref, cmNStr(vErrorMessage));   
			
			tcCommonFunctionOnClientServer.UserMessage(cmNStr(vErrorMessage), pObject, vAttributeInErr, , True);
		Else
			If Modified Or Not pObject.Posted Then
				pObject.AdditionalProperties.Insert("DoNotCheckAttributes", True);
			EndIf;
		EndIf;
	Except
		vCancel = True;
		vErrorMessage = cmGetRootErrorDescription(ErrorInfo());
		// Log and show error information
		WriteLogEvent(NStr("en = 'Document.Posting'; de = 'Document.Posting'; ru = 'Документ.Проведение'"), EventLogLevel.Warning, pObject.Metadata(), pObject.Ref, vErrorMessage);  
		
		tcCommonFunctionOnClientServer.UserMessage(cmNStr(vErrorMessage), pObject, , , True);
	EndTry;
	Return vCancel;
EndFunction //  PostDocument

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.Date) Then
		vObj.Date = cm0SecondShift(vObj.Date);
		If Not vObj.IsNew() Then
			If Year(OldDate) <> Year(vObj.Date) Then
				vObj.SetNewNumber();
			EndIf;	
		Else
			If Not IsBlankString(vObj.Number) Then
				vObj.SetNewNumber();
			EndIf;
		EndIf;
		OldDate = vObj.Date;
	EndIf;
	ValueToFormAttribute(vObj, "Object");
EndProcedure //  DateOnChangeAtServer

&AtServer
Procedure OperationEndDateOnChangeAtServer()
	Object.OperationEndDate = cm0SecondShift(Object.OperationEndDate);
EndProcedure // OperationEndDateOnChangeAtServer

&AtClient
Procedure OperationEndDateOnChange(Item)
	OperationEndDateOnChangeAtServer();
EndProcedure

#EndRegion
