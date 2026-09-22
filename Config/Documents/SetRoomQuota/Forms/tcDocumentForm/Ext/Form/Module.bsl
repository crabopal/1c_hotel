
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	vObject = FormAttributeToValue("Object");
	
	If vObject.IsNew() Then
		// Use current time by default
		vObject.SetTime(AutoTimeMode.CurrentOrLast);
		// Fill attributes with default values
		If Not ValueIsFilled(vObject.Author) Then
			vObject.pmFillAttributesWithDefaultValues();
		Else
			vObject.pmFillAuthorAndDate();
		EndIf;	
	EndIf;
	
	If Parameters.Property("RoomQuota") And ValueIsFilled(Parameters.RoomQuota) Then
		vObject.RoomQuota = Parameters.RoomQuota;
		vObject.BaseRoomQuota = Parameters.RoomQuota.BaseRoomQuota;
		If ValueIsFilled(vObject.RoomQuota.Hotel) Then
			vObject.Hotel = vObject.RoomQuota.Hotel;
		EndIf;		
	EndIf;
	
	If Parameters.Property("RoomType") And ValueIsFilled(Parameters.RoomType) Then
		vObject.RoomType = Parameters.RoomType;
		vObject.NumberOfBedsPerRoom = vObject.RoomType.NumberOfBedsPerRoom;
		vObject.NumberOfPersonsPerRoom = vObject.RoomType.NumberOfPersonsPerRoom;	
		If Not ValueIsFilled(vObject.Hotel) Then
			vObject.Hotel = vObject.RoomType.Owner;
		EndIf;	
	EndIf;
	
	If Parameters.Property("DateFrom") Then
		vObject.DateFrom = Parameters.DateFrom;	
	EndIf;
	
	If Parameters.Property("DateTo") Then	
		vObject.DateTo = Parameters.DateTo;
		vObject.Duration = vObject.pmCalculateDuration();
	EndIf;
	
	If Parameters.Property("SetRoomQuotaType") Then	
		vObject.SetRoomQuotaType = Parameters.SetRoomQuotaType;
	EndIf;
	
	If Parameters.Property("NumberOfRooms") Then	
		vObject.NumberOfRooms = Parameters.NumberOfRooms;
		vObject.NumberOfBeds = vObject.NumberOfRooms * vObject.NumberOfBedsPerRoom;
	EndIf;
	
	ValueToFormAttribute(vObject, "Object");

	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(Object.Hotel) And SessionParameters.CurrentHotel <> Object.Hotel Then
			pCancel = True;
		EndIf;
	EndIf;	
	
	// Check user rights to use item
	If ValueIsFilled(Object.RoomQuota) And Object.RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
		If Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Then
			If Not ValueIsFilled(Object.Ref) Then
				pCancel = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage business blocks!';ru='Нет прав на управление бизнес-блоками!';de='Sie haben keine Rechte, Geschäftsblocken zu verwalten!'"));
			Else
				ReadOnly = True;
			EndIf;
		EndIf;
	Else
		If Not cmCheckUserPermissions("HavePermissionToManageAllotments") Then
			If Not ValueIsFilled(Object.Ref) Then
				pCancel = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage allotments!';ru='Нет прав на управление квотами!';de='Sie haben keine Rechte, Allotmenten zu verwalten!'"));
			Else
				ReadOnly = True;
			EndIf;
		EndIf;
	EndIf;
	
	// Check edit prohibited date
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(Object.Hotel.EditProhibitedDate) And ValueIsFilled(Object.DateTo) And 
			BegOfDay(Object.Hotel.EditProhibitedDate) >= BegOfDay(Object.DateTo) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	
	SetRoomAppearance();
	
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	Var vMessage, vAttributeInErr;
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		SetObjectAndFormAttributeConformity(pCurrentObject, "Object");
		// Check document attributes
		pCancel = pCurrentObject.pmCheckDocumentAttributes(pCurrentObject.Posted, vMessage, vAttributeInErr, True);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, pCurrentObject.Metadata(), pCurrentObject.Ref, NStr(vMessage));
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = vAttributeInErr;
			vUM.Text = NStr(vMessage);
			vUM.Message();
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	// Notify changes in the room quota sales subsystem
	Notify("Subsystem.Rooms.RoomQuotaSales.Changed", Object.Ref, ThisObject);
EndProcedure // AfterWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomQuotaOnChange(pItem)
	RoomQuotaOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	HotelOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateFromOnChange(pItem)
	DateFromOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(pItem)
	DurationOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateToOnChange(pItem)
	DateToOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(pItem)
	RoomTypeOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfRoomsOnChange(pItem)
	Object.NumberOfBeds = Object.NumberOfRooms * Object.NumberOfBedsPerRoom;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfBedsOnChange(pItem)
	If Object.NumberOfBedsPerRoom = 0 Then
		Object.NumberOfRooms = 0;
	Else
		If Int(Object.NumberOfBeds/Object.NumberOfBedsPerRoom) < Object.NumberOfBeds/Object.NumberOfBedsPerRoom Then
			Object.NumberOfRooms = Int(Object.NumberOfBeds/Object.NumberOfBedsPerRoom) + 1;
		Else
			Object.NumberOfRooms = Int(Object.NumberOfBeds/Object.NumberOfBedsPerRoom);
		EndIf;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomOnChange(pItem)
	RoomOnChangeAtServer();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure MoveOneDayBefore(pCommand)
	MoveOneDayBeforeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MoveOneDayLater(pCommand)
	MoveOneDayLaterAtServer();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetRoomAppearance()
	If ValueIsFilled(Object.RoomQuota) Then
		If Object.RoomQuota.IsQuotaForRooms Then
			Items.Room.Visible = True;
			Items.NumberOfRooms.Enabled = False;
			Items.NumberOfBeds.Enabled = False;
		Else
			Items.Room.Visible = False;
			Items.NumberOfRooms.Enabled = True;
			Items.NumberOfBeds.Enabled = True;
		EndIf;
	Else
		Items.Room.Visible = False;
		Items.NumberOfRooms.Enabled = True;
		Items.NumberOfBeds.Enabled = True;
	EndIf;
EndProcedure // SetRoomAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure SetBaseRoomQuotaAppearance()
	If ValueIsFilled(Object.RoomQuota) And ValueIsFilled(Object.RoomQuota.BaseRoomQuota) Then
		Items.BaseRoomQuota.Visible = True;
	Else
		Items.BaseRoomQuota.Visible = False;
	EndIf;
EndProcedure // SetBaseRoomQuotaAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomQuotaOnChangeAtServer()
	If ValueIsFilled(Object.RoomQuota) Then
		If ValueIsFilled(Object.RoomQuota.Hotel) Then
			Object.Hotel = Object.RoomQuota.Hotel;
		EndIf;
		If Not Object.RoomQuota.IsQuotaForRooms Then
			If ValueIsFilled(Object.Room) Then
				Object.Room = Catalogs.Rooms.EmptyRef();
			EndIf;
		Else
			If Object.NumberOfRooms <> 1 Then
				Object.NumberOfRooms = 1;
				RoomTypeOnChangeAtServer();
			EndIf;
		EndIf;
	EndIf;
	// Set room attribute appearance
	SetRoomAppearance();	
	// Set base room quota appearance
	SetBaseRoomQuotaAppearance();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(Object.RoomType) Then
			If Object.Hotel <> Object.RoomType.Owner Then
				Object.RoomType = Catalogs.RoomTypes.EmptyRef();
				Object.NumberOfBedsPerRoom = 0;
				Object.NumberOfPersonsPerRoom = 0;
				Object.NumberOfBeds = 0;
			EndIf;
		EndIf;
	Else
		Object.RoomType = Catalogs.RoomTypes.EmptyRef();	
		Object.NumberOfBedsPerRoom = 0;
		Object.NumberOfPersonsPerRoom = 0;
		Object.NumberOfBeds = 0;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DateFromOnChangeAtServer()
	vObject = FormAttributeToValue("Object");
	vObject.DateFrom = vObject.pmInitializeDateFrom();
	vObject.Duration = vObject.pmCalculateDuration();	
	ValueToFormAttribute(vObject,"Object");	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DurationOnChangeAtServer()
	vObject = FormAttributeToValue("Object");
	vObject.DateTo = vObject.pmCalculateDateTo();	
	ValueToFormAttribute(vObject, "Object");		
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DateToOnChangeAtServer()
	Object.DateTo = cm0SecondShift(BegOfDay(Object.DateTo) + (Object.DateFrom - BegOfDay(Object.DateFrom)));
	vObject = FormAttributeToValue("Object");
	vObject.Duration = vObject.pmCalculateDuration();
	ValueToFormAttribute(vObject, "Object");			
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure MoveOneDayBeforeAtServer()
	Object.DateFrom = cm0SecondShift(Object.DateFrom - 24 * 3600);
	Object.DateTo = cm0SecondShift(Object.DateTo - 24 * 3600);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure MoveOneDayLaterAtServer()
	Object.DateFrom = cm0SecondShift(Object.DateFrom + 24 * 3600);
	Object.DateTo = cm0SecondShift(Object.DateTo + 24 * 3600);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomTypeOnChangeAtServer()
	If ValueIsFilled(Object.RoomType) Then
		Object.NumberOfBedsPerRoom = Object.RoomType.NumberOfBedsPerRoom;
		Object.NumberOfPersonsPerRoom = Object.RoomType.NumberOfPersonsPerRoom;
		
		Object.NumberOfBeds = Object.NumberOfRooms * Object.NumberOfBedsPerRoom;
		
		If ValueIsFilled(Object.Room) And Object.Room.RoomType <> Object.RoomType Then
			Object.Room = Catalogs.Rooms.EmptyRef();
		EndIf;
	Else
		Object.NumberOfBedsPerRoom = 0;
		Object.NumberOfPersonsPerRoom = 0;		
		Object.NumberOfBeds = 0;	
		Object.Room = Catalogs.Rooms.EmptyRef();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomOnChangeAtServer()
	Object.RoomType = Object.Room.RoomType;
	RoomTypeOnChangeAtServer();
EndProcedure

#EndRegion
