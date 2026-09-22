
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
	vHavePermissionToManageRoomInventory = cmCheckUserPermissions("HavePermissionToManageRoomInventory");
	vObject = FormAttributeToValue("Object");
	If vObject.IsNew() Then
		If Not vHavePermissionToManageRoomInventory Then
			pCancel = True;
			vUM = New UserMessage();
			vUM.SetData(vObject);
			vUM.Text = NStr("en='You do not have rights for room inventory management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'");
			vUM.Message();
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
		EndIf;
	EndIf;
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(vObject.Hotel) And SessionParameters.CurrentHotel <> vObject.Hotel Then
			pCancel = True;
			Return;
		EndIf;
	EndIf;	
	// User rights to see and edit document number and room ref
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	If Parameters.Property("RoomGroup") Then
		vObject.RoomGroup = Parameters.RoomGroup;
	EndIf;
	ValueToFormAttribute(vObject, "Object");
EndProcedure //  OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		pCancel = PostDocument(pCurrentObject);
	EndIf;
EndProcedure //  BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// Repost change room documents created later
		If ValueIsFilled(pCurrentObject.Room) Then
			pCurrentObject.pmRepostChangeRoomDocumentsCreatedLater();
		EndIf;
	EndIf;
EndProcedure // AfterWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Subsystem.Rooms.Changed", Object.Room);
EndProcedure //  AfterWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(Item)
	RoomTypeOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure // DateOnChange

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomTypeOnChangeAtServer()
	If ValueIsFilled(Object.RoomType) Then
		Object.IsVirtual = Object.RoomType.IsVirtual;
		Object.NumberOfBedsPerRoom = Object.RoomType.NumberOfBedsPerRoom;
		Object.NumberOfPersonsPerRoom = Object.RoomType.NumberOfPersonsPerRoom;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function PostDocument(pObject)
	Var vErrorMessage, vAttributeInErr;
	vCancel = False;
	Try
		vCancel = pObject.pmCheckDocumentAttributes(vErrorMessage, vAttributeInErr);
		If vCancel Then
			WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, pObject.Metadata(), pObject.Ref, cmNStr(vErrorMessage));
			vUM = New UserMessage();
			vUM.SetData(pObject);
			vUM.Field = vAttributeInErr;
			vUM.Text = cmNStr(vErrorMessage);
			vUM.Message();
		Else
			If Modified Or Not pObject.Posted Then
				pObject.AdditionalProperties.Insert("DoNotCheckAttributes", True);
			EndIf;
		EndIf;
	Except
		vCancel = True;
		vErrorMessage = cmGetRootErrorDescription(ErrorInfo());
		// Log and show error information
		WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, pObject.Metadata(), pObject.Ref, vErrorMessage);
		vUM = New UserMessage();
		vUM.SetData(pObject);
		vUM.Text = vErrorMessage;
		vUM.Message();
	EndTry;
	Return vCancel;
EndFunction // PostDocument

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	If Not vObj.IsNew() Then
		If Year(vObj.Ref.Date) <> Year(vObj.Date) Then
			vObj.SetNewNumber();
		EndIf;
	Else
		If Not IsBlankString(vObj.Number) Then
			vObj.SetNewNumber();
		EndIf;
	EndIf;
	ValueToFormAttribute(vObj, "Object");
EndProcedure // DateOnChangeAtServer

#EndRegion
