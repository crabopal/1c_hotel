
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	OnCreateAtServerExport(pCancel);
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vHotel = tcOnServer.cmGetAttributeByRef(ReservationRef1, "Hotel");
	If Not ValueIsFilled(vHotel) Then
		vHotel = tcOnServer.cmGetCurrentHotelAttribute();
	EndIf;
	vRoomType = tcOnServer.cmGetAttributeByRef(ReservationRef1, "RoomType");
	vRoomQuota = tcOnServer.cmGetAttributeByRef(ReservationRef1, "RoomQuota");
	vNumberOfBeds = tcOnServer.cmGetAttributeByRef(ReservationRef1, "NumberOfBeds");
	vNumberOfRooms = tcOnServer.cmGetAttributeByRef(ReservationRef1, "NumberOfRooms");
	vCheckInDate = tcOnServer.cmGetAttributeByRef(ReservationRef1, "CheckInDate");
	vCheckOutDate = tcOnServer.cmGetAttributeByRef(ReservationRef1, "CheckOutDate");
	vBedsSetup = tcOnServer.cmGetAttributeByRef(ReservationRef1, "BedsSetup");
	#IF ThickClientOrdinaryApplication THEN
		vRoomQuantity = 1;
		vNumberOfBeds = Max(vNumberOfBeds, GuestCount);
		vFrm = GetForm("Catalog.Rooms.Form.ChoiceForm", , pItem);
		vFrm.SelDateFrom = vCheckInDate;
		vFrm.SelDateTo = vCheckOutDate;
		If ValueIsFilled(vRoomQuota) Then
			vFrm.SelRoomQuota = vRoomQuota;
		Else
			vFrm.SelRoomQuota = Undefined;
		EndIf;
		If ValueIsFilled(vRoomType) Then
			vFrm.SelRoomType = vRoomType;
		Else
			vFrm.SelRoomType = Undefined;
		EndIf;
		vFrm.SelNumberOfBeds = ?(vRoomQuantity>0, Int(vNumberOfBeds/vRoomQuantity), 0);
		vFrm.SelNumberOfRooms = ?(vRoomQuantity>0, Int(vNumberOfRooms/vRoomQuantity), 0);
		vFrm.Hotel = vHotel;
		vFrm.ChoiceMode = True;
		vFrm.Open();
	#Else
		OpenForm("Catalog.Rooms.Form.tcChoiceForm", New Structure("Hotel, DateFrom, DateTo, RoomType, RoomQuota, Company, NumberOfRooms, NumberOfBeds, BedsSetup", vHotel, vCheckInDate, vCheckOutDate, vRoomType, vRoomQuota, Undefined, vNumberOfRooms, vNumberOfBeds, vBedsSetup), pItem);
	#EndIf
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeGuestItem(pCommand)
	vID = Right(ThisForm.CurrentItem.Name, StrLen(ThisForm.CurrentItem.Name)-6);
	ChangeTypeOfFields(vID, True);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeOK(pCommand)
	vID = Right(ThisForm.CurrentItem.Name, StrLen(ThisForm.CurrentItem.Name)-8);
	ChangeTypeOfFields(vID);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeCancel(pCommand)
	vID = Right(ThisForm.CurrentItem.Name, StrLen(ThisForm.CurrentItem.Name)-12);
	ChangeTypeOfFields(vID);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IssueKeyCardCommand(pCommand)
	vCheckResult = CheckUserPermissionToIssueKeyCards();
	If vCheckResult Then
		vAccList = CheckIn();
		// Print forms that should be printed for check-in
		#IF ThickClientOrdinaryApplication THEN
			For Each vAccItem In vAccList Do
				vFrm = vAccItem.Value.GetForm();
				vFrm.InitializeGroupFormsAndActions();
				vFrm.PerformAutomaticPrinting(vAccItem.Value.GetObject());
			EndDo;
		#ENDIF
		// Issue key cards
		vDeviceArr = IsReadyToIssueKeyCards();
		If TypeOf(vDeviceArr) = Type("Structure")  Then
			vIndex = 1;
			For Each vAccItem In vAccList Do
				Items.HelpMessageGroup.Visible = True;
				Items.HelpMessageDecoration.Title = NStr("ru='Приложите ключ для гостя №'; en='Put a key for the guest #'; de='Legte einen schlüssel für den Gast #'")+String(vIndex)+" ("+tcOnServer.cmGetAttributeByRef(vAccItem.Value, "GuestFullName")+")";
				vParametersKeyCard = FillParametersKeyCard(vAccItem.Value);
				IssueKeyCards(vIndex, vDeviceArr,vParametersKeyCard);
				vIndex = vIndex + 1;
			EndDo;
		EndIf;
		ThisForm.Close();
	ElsIf vCheckResult = Undefined Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='You have to issue key cards from the folios list of the current accommodation!';ru='Необходимо выдавать ключи из списка лицевых счетов гостя!';de='Sie müssen Schlüssel aus der Liste der Personenkonten des Gastes ausgeben!'"));
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Door lock system is not configurated properly for the current workstation!';ru='Система электронных замков на данном рабочем месте не настроена!';de='Das System für elektronische Schlösser ist auf diesem Arbeitsplatz nicht eingestellt!'"));
	EndIf;
EndProcedure // IssueKeyCardCommand

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function CheckIn()
	vSuccess = True;
	vAccList = New ValueList;
	// Write
	BeginTransaction(DataLockControlMode.Managed);
	For vInd = 1 To GuestCount Do
		Try
			vReservationRef = ThisForm["ReservationRef"+String(vInd)];
			If vReservationRef.Room <> Room And ValueIsFilled(Room) Then
				Try
					vResObj = vReservationRef.GetObject();
					vResObj.Room = Room;
					vResObj.Write();
				Except
					vSuccess = False;
					vErrInfo = ErrorInfo();
					// Rollback any transaction if active
					If TransactionActive() Then
						RollbackTransaction();
					EndIf;
					// Log and show error information
					WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, vResObj.Metadata(), vReservationRef, cmGetRootErrorDescription(vErrInfo));
					tcCommonFunctionOnClientServer.UserMessage(vErrInfo.Description);
					Break;
				EndTry;
			EndIf;
			vAccObject = Documents.Accommodation.CreateDocument();
			vAccObject.Fill(vReservationRef);
			vAccObject.Write(DocumentWriteMode.Posting);
			vAccList.Add(vAccObject.Ref);
		Except
			vSuccess = False;
			vErrInfo = ErrorInfo();
			// Rollback any transaction if active
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			// Log and show error information
			WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, vAccObject.Metadata(), vAccObject.Ref, cmGetRootErrorDescription(vErrInfo));
			tcCommonFunctionOnClientServer.UserMessage(vErrInfo.Description);
			Break;
		EndTry;
	EndDo;
	If vSuccess Then
		CommitTransaction();
	EndIf;
	Return vAccList;
EndFunction // CheckIn

// -----------------------------------------------------------------------------
&AtServer
Function CheckUserPermissionToIssueKeyCards()
	// Check parameters
	vWstn = SessionParameters.CurrentWorkstation;
	If Not ValueIsFilled(vWstn) Then
		Return False;
	EndIf;
	If Not vWstn.HasConnectionToDoorLockSystem Then
		Return False;
	EndIf;
	If Not ValueIsFilled(vWstn.DoorLockSystemParameters) Then
		Return False;
	EndIf;
	vDLST = vWstn.DoorLockSystemParameters.DoorLockSystemType;
	If Not ValueIsFilled(vDLST) Then
		Return False;
	EndIf;
	// Chek user permission to issue key cards from the accommodations list
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		If SessionParameters.CurrentWorkstation.HasConnectionToDoorLockSystem And 
			ValueIsFilled(SessionParameters.CurrentWorkstation.DoorLockSystemParameters) Then
			If SessionParameters.CurrentWorkstation.DoorLockSystemParameters.DoKeyCardsFromFoliosOnly Then
				Return Undefined;
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction // CheckUserPermissionToIssueKeyCards

// -----------------------------------------------------------------------------
&AtClient
Procedure IssueKeyCards(pIndex, pDeviceArr, pParametersKeyCard)
	vModul = pDeviceArr.Modul;
	
	// Call API
	If pIndex = 1 Then
		vRC = vModul.pmNewKey(pDeviceArr, pParametersKeyCard);
	Else
		vRC = vModul.pmAddKey(pDeviceArr, pParametersKeyCard);
	EndIf;
	If vRC = -1 Then  //RC_NO_CONNECTION
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Connection error!';ru='Ошибка подключения!';de='Anschlussfehler!'"));
	ElsIf vRC <> 0 Then //RC_OK
		vErrorDescription = vModul.pmGetErrorDescription(vRC, pDeviceArr.SystemName);
		tcCommonFunctionOnClientServer.UserMessage(NStr("ru = 'Ошибка выдачи новой карты! Код ошибки: " + vRC + ". Описание ошибки: ';  
		|en = 'Error making new card! Error code: " + vRC + ". Error description: ';
		|de = 'Error making new card! Error code: " + vRC + ". Error description: '") +	vErrorDescription);
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Success';ru='Успешно';de='Erfolgreich'"));
	EndIf;
EndProcedure // IssueKeyCards

// -----------------------------------------------------------------------------
&AtClient
Function IsReadyToIssueKeyCards()
	vDriver = Undefined;
	vCurWstn = tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation");
	If ValueIsFilled(vCurWstn) Then
		vCurWstnArr = tcOnServer.cmGetAtributeAsArray(vCurWstn);	
		If vCurWstnArr.HasConnectionToDoorLockSystem And ValueIsFilled(vCurWstnArr.DoorLockSystemParameters) Then
			vDevice = vCurWstnArr.DoorLockSystemParameters;
		Else	
			ShowMessageBox(,Nstr("en='Door lock system is not configurated properly for the current workstation!';ru='Система электронных замков на данном рабочем месте не настроена!';de='Das System für elektronische Schlösser ist auf diesem Arbeitsplatz nicht eingestellt!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
			Return False;
		EndIf;
		
		vDriver = tcOnClient.cmGetModulTO(vDevice);
	Else
		ShowMessageBox(,Nstr("en = 'The workstation is not defined'; ru = 'Рабочее место не определено'; de = 'Die Workstation ist nicht definiert'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return  False;
	EndIf;
	If Not vDriver = Undefined Then
		Return vDriver;
	Else
		ShowMessageBox(,Nstr("en = 'Work with driver this device is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;	
	Return  False;
EndFunction //  IsReadyToPrintCheque()

// -----------------------------------------------------------------------------
&AtServer
Function FillParametersKeyCard(pAccRef)
	// Fill parameters
	vParameters = new Structure;
	vParameters.Insert("Room");
	vParameters.Insert("CheckInDate");
	vParameters.Insert("CheckOutDate");
	vParameters.Insert("Guest");
	vParameters.Insert("AccommodationType");
	vParameters.Insert("ParentDoc");
	vParameters.Insert("Folio");
	vParameters.Insert("DoorLockSystemAuthorization");
	vParameters.Insert("CurrentUser",SessionParameters.CurrentUser);
	vParameters.Insert("EmployeePreferences",SessionParameters.CurrentUser.EmployeePreferences);
	vParameters.Insert("EmployeePreferencesDoorLockSystemLogin",SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin);
	vParameters.Insert("NumberOfKeys", 1);
	vParameters.Insert("IdentificationCard", Catalogs.IdentificationCards.EmptyRef());

	vCurDoc = pAccRef;
	
	If ValueIsFilled(vCurDoc.Room) Then
		vParameters.Room = vCurDoc.Room;
	EndIf;
	vParameters.CheckInDate = cmGetKeyCardCheckInTime(vCurDoc.CheckInDate);
	vParameters.CheckOutDate = cmGetLastCheckOutDateInChain(vCurDoc);
	vParameters.Guest = vCurDoc.Guest;
	vParameters.AccommodationType = vCurDoc.AccommodationType;
	vParameters.ParentDoc = vCurDoc;
	If ValueIsFilled(vParameters.Room) And ValueIsFilled(vParameters.Room.DoorLockSystemAuthorization) Then
		vParameters.DoorLockSystemAuthorization = vParameters.Room.DoorLockSystemAuthorization;
	ElsIf (TypeOf(vCurDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCurDoc) = Type("DocumentRef.Reservation")) And 
		ValueIsFilled(vCurDoc.BoardPlace) And ValueIsFilled(vCurDoc.BoardPlace.DoorLockSystemAuthorization) Then 
		vParameters.DoorLockSystemAuthorization = vCurDoc.BoardPlace.DoorLockSystemAuthorization;
	EndIf;
	// Fill folio from the last charging rule
	vParameters.Folio = Documents.Folio.EmptyRef();
	If vCurDoc.ChargingRules.Count() > 0 Then
		vParameters.Folio = vCurDoc.ChargingRules.Get(vCurDoc.ChargingRules.Count()-1).ChargingFolio;
	EndIf;
	Return vParameters;
EndFunction // IssueKeyCards

// -----------------------------------------------------------------------------
&AtServer
Procedure AddNewGuestFields(pIndex)
	Try
		Try
			Items["GuestGroup"+String(pIndex)].Visible=True;
		Except
		EndTry;
		vTempArray = New Array;	
		vTempArray.Add(New FormAttribute("ReservationRef"+String(pIndex), New TypeDescription("DocumentRef.Reservation")));
		vTempArray.Add(New FormAttribute("GuestRef"+String(pIndex), New TypeDescription("CatalogRef.Clients")));
		vTempArray.Add(New FormAttribute("GuestAddressInformation"+String(pIndex), New TypeDescription("String")));
		vTempArray.Add(New FormAttribute("GuestDateOfBirth"+String(pIndex), New TypeDescription("String")));
		vTempArray.Add(New FormAttribute("GuestDocumentInformation"+String(pIndex), New TypeDescription("String")));
		vTempArray.Add(New FormAttribute("GuestMainInformation"+String(pIndex), New TypeDescription("String")));
		vTempArray.Add(New FormAttribute("GuestMessagesInformation"+String(pIndex), New TypeDescription("String")));
		vTempArray.Add(New FormAttribute("GuestPhoto"+String(pIndex), New TypeDescription("String")));
		ChangeAttributes(vTempArray);
		
		// Guest group
		vGuestGroup = Items.Add("GuestGroup"+String(pIndex), Type("FormGroup"), Items.GuestsGroup);
		vGuestGroup.Title = NStr("en='""Guest №';ru='Группа ""Гость №';de='Gruppe ""Gast Nr.'")+String(pIndex)+NStr("ru='""';en='"" group';de='""'");
		vGuestGroup.Type = FormGroupType.UsualGroup;
		vGuestGroup.Representation = UsualGroupRepresentation.StrongSeparation;
		vGuestGroup.Group = ChildFormItemsGroup.Horizontal;
		vGuestGroup.ShowTitle = False;
		// Guest photo
		vGuestPhotoField = Items.Add("GuestPhoto"+String(pIndex), Type("FormField"), vGuestGroup);
		vGuestPhotoField.Type = FormFieldType.PictureField;
		vGuestPhotoField.DataPath = "GuestPhoto"+String(pIndex);
		vGuestPhotoField.Title = NStr("en='Photo';ru='Фотография';de='Foto'");
		vGuestPhotoField.TitleLocation = FormItemTitleLocation.None; 
		vGuestPhotoField.Width = 12;
		vGuestPhotoField.Height = 5;
		vGuestPhotoField.HorizontalStretch = False;
		vGuestPhotoField.PictureSize = PictureSize.Proportionally;
		vGuestPhotoField.Border = New Border(ControlBorderType.WithoutBorder);
		// Main guest information group
		vMainInfoGroup = Items.Add("MainGuestInformationGroup"+String(pIndex), Type("FormGroup"), vGuestGroup);
		vMainInfoGroup.Title = NStr("en='Group ""Main guest information""';ru='Группа ""Основная информация""';de='Gruppe ""Hauptgästeinformation""'");
		vMainInfoGroup.Type = FormGroupType.UsualGroup;
		vMainInfoGroup.Representation = UsualGroupRepresentation.None;
		vMainInfoGroup.Group = ChildFormItemsGroup.Vertical;
		vMainInfoGroup.ShowTitle = False;
	    // Guest main information field
		vGuestMainInformationField = Items.Add("GuestMainInformation"+String(pIndex), Type("FormField"), vMainInfoGroup);
		vGuestMainInformationField.Type = FormFieldType.LabelField;
		vGuestMainInformationField.DataPath = "GuestMainInformation"+String(pIndex);
		vGuestMainInformationField.Title = NStr("en='Guest main information';ru='Основная информация о госте';de='Hauptgästeinformation'");
		vGuestMainInformationField.TitleLocation = FormItemTitleLocation.None; 
		vGuestMainInformationField.Font = New Font(,,True);
		// Date of birth and document information group
		vDoBAndDocInformationGroup = Items.Add("DateOfBirthAndDocumentInformationGroup"+String(pIndex), Type("FormGroup"), vMainInfoGroup);
		vDoBAndDocInformationGroup.Title = NStr("en='Group ""Date of birth and document information""';ru='Группа ""Дата рождения и информация о документе""';de='Gruppe ""Geburtsdatum und Dokumentinformationen""'");
		vDoBAndDocInformationGroup.Type = FormGroupType.UsualGroup;
		vDoBAndDocInformationGroup.Representation = UsualGroupRepresentation.None;
		vDoBAndDocInformationGroup.Group = ChildFormItemsGroup.Horizontal;
		vDoBAndDocInformationGroup.ShowTitle = False;
		// Guest date of birth field
		vGuestDateOfBirthField = Items.Add("GuestDateOfBirth"+String(pIndex), Type("FormField"), vDoBAndDocInformationGroup);
		vGuestDateOfBirthField.Type = FormFieldType.LabelField;
		vGuestDateOfBirthField.DataPath = "GuestDateOfBirth"+String(pIndex);
		vGuestDateOfBirthField.Title = NStr("en='Date of birth';ru='Дата рождения';de='Geburtsdatum'");
		vGuestDateOfBirthField.TitleLocation = FormItemTitleLocation.None; 
		vGuestDateOfBirthField.Width = 8;
		vGuestDateOfBirthField.HorizontalStretch = False;
		// Guest document information field
		vGuestDocumentInformationField = Items.Add("GuestDocumentInformation"+String(pIndex), Type("FormField"), vDoBAndDocInformationGroup);
		vGuestDocumentInformationField.Type = FormFieldType.LabelField;
		vGuestDocumentInformationField.DataPath = "GuestDocumentInformation"+String(pIndex);
		vGuestDocumentInformationField.Title = NStr("en='Room';ru='Номер';de='Zimmer'");
		vGuestDocumentInformationField.TitleLocation = FormItemTitleLocation.None; 
		// Guest address information field
		vGuestAddressInformationField = Items.Add("GuestAddressInformation"+String(pIndex), Type("FormField"), vMainInfoGroup);
		vGuestAddressInformationField.Type = FormFieldType.LabelField;
		vGuestAddressInformationField.DataPath = "GuestAddressInformation"+String(pIndex);
		vGuestAddressInformationField.Title = NStr("en='Address';ru='Адрес';de='Adresse'");
		vGuestAddressInformationField.TitleLocation = FormItemTitleLocation.None; 
		// Guest messages field
		vGuestMessagesInformationField = Items.Add("GuestMessagesInformation"+String(pIndex), Type("FormField"), vMainInfoGroup);
		vGuestMessagesInformationField.Type = FormFieldType.InputField;
		vGuestMessagesInformationField.SkipOnInput = True;
		vGuestMessagesInformationField.MultiLine = True;
		vGuestMessagesInformationField.ReadOnly = True;
		vGuestMessagesInformationField.TextEdit = False;
		vGuestMessagesInformationField.BackColor = StyleColors.FormBackColor;
		vGuestMessagesInformationField.BorderColor = StyleColors.FormBackColor;
		vGuestMessagesInformationField.DataPath = "GuestMessagesInformation"+String(pIndex);
		vGuestMessagesInformationField.Title = NStr("en='Messages';ru='Сообщения';de='Nachrichten'");
		vGuestMessagesInformationField.TitleLocation = FormItemTitleLocation.None; 
	Except
	EndTry;
EndProcedure // AddNewGuestFields

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeTypeOfFields(pID, pIsInput = False)
	Try
		If pIsInput Then
			Items["GuestFirstName"+pID].Enabled = True;
			Items["GuestSecondName"+pID].Enabled = True;
			Items["GuestLastName"+pID].Enabled = True;
			Items["GuestDateOfBirth"+pID].Enabled = True;
			Items["GuestEMail"+pID].Enabled = True;
			Items["GuestPhone"+pID].Enabled = True;
			Items["GuestCitizenship"+pID].Enabled = True;
			Items["GuestIdentityDocumentType"+pID].Enabled = True;
			Items["GuestIdentityDocumentNumber"+pID].Enabled = True;
			Items["GuestIdentityDocumentSeries"+pID].Enabled = True;
			Items["GuestIdentityDocumentIssueDate"+pID].Enabled = True;
			Items["GuestAddress"+pID].Enabled = True;
			Items["Change"+pID].Visible = False;
			Items["ChangeOK"+pID].Visible = True;
			Items["ChangeCancel"+pID].Visible = True;
		Else
			Items["GuestFirstName"+pID].Enabled = False;
			Items["GuestSecondName"+pID].Enabled = False;
			Items["GuestLastName"+pID].Enabled = False;
			Items["GuestDateOfBirth"+pID].Enabled = False;
			Items["GuestEMail"+pID].Enabled = False;
			Items["GuestPhone"+pID].Enabled = False;
			Items["GuestCitizenship"+pID].Enabled = False;
			Items["GuestIdentityDocumentType"+pID].Enabled = False;
			Items["GuestIdentityDocumentNumber"+pID].Enabled = False;
			Items["GuestIdentityDocumentSeries"+pID].Enabled = False;
			Items["GuestIdentityDocumentIssueDate"+pID].Enabled = False;
			Items["GuestAddress"+pID].Enabled = False;
			Items["Change"+pID].Visible = True;
			Items["ChangeOK"+pID].Visible = False;
			Items["ChangeCancel"+pID].Visible = False;
		EndIf;
	Except
	EndTry;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServerExport(pCancel = False, pParameter = Undefined) 
	vReservation = Documents.Reservation.EmptyRef();
	If ValueIsFilled(pParameter) And TypeOf(pParameter) = Type("DocumentRef.Reservation") Then
		vReservation = pParameter;
	Else
		Parameters.Property("Key", vReservation);
	EndIf;
	If Not ValueIsFilled(vReservation) Or Not TypeOf(vReservation) = Type("DocumentRef.Reservation") Then
		pCancel = True;
	EndIf;
	If Not pCancel Then
		If Not ValueIsFilled(GuestCount) Then
			GuestCount = 1;
		ElsIf GuestCount > 1 Then
			For vInd = 2 To GuestCount Do
				Try
					Items["GuestGroup"+String(vInd)].Visible = False;
				Except
				EndTry;
			EndDo;
			GuestCount = 1;
		EndIf;
		// Fill one room guests
		vQry = New Query;
		vQry.Text = 
		"SELECT
		|	Reservation.Ref AS Ref,
		|	Reservation.Guest AS GuestRef
		|FROM
		|	Document.Reservation AS Reservation
		|WHERE
		|	Reservation.GuestGroup = &qGroup
		|	AND (Reservation.Room = &qRoom
		|				AND &qRoomIsFilled
		|			OR Reservation.Number = &qNumber
		|				AND NOT &qRoomIsFilled)
		|	AND Reservation.Posted
		|	AND NOT Reservation.DeletionMark
		|	AND (Reservation.ReservationStatus.IsActive
		|			OR Reservation.ReservationStatus.IsPreliminary
		|			OR Reservation.ReservationStatus.IsInWaitingList)
		|	AND BEGINOFPERIOD(Reservation.CheckInDate, DAY) = &qCheckInDateBegOfPeriod
		|
		|ORDER BY
		|	Reservation.AccommodationType.SortCode";
		vQry.SetParameter("qGroup", vReservation.GuestGroup);
		vQry.SetParameter("qRoom", vReservation.Room);
		vQry.SetParameter("qCheckInDateBegOfPeriod", BegOfDay(CurrentSessionDate()));
		vQry.SetParameter("qRoomIsFilled", ValueIsFilled(vReservation.Room));
		vQry.SetParameter("qNumber", vReservation.Number);
		vQry.SetParameter("qEmptyReservationStatusRef", Catalogs.ReservationStatuses.EmptyRef());
		vQry.SetParameter("qCurrentDateBegOfDay", BegOfDay(CurrentSessionDate()));
		vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
		vReservations = vQry.Execute().Unload();
		vIndex = 1;
		GuestCount = vReservations.Count();
		If vReservations.Count() > 0 Then
			For Each vReservRow In vReservations Do
				Try
					If vIndex <> 1 Then
						AddNewGuestFields(vIndex);
					EndIf;
					ThisForm["ReservationRef"+String(vIndex)] = vReservRow.Ref;
					// Guest info
					ThisForm["GuestRef"+String(vIndex)] = vReservRow.GuestRef;
					ThisForm["GuestMainInformation"+String(vIndex)] = TrimAll(vReservRow.GuestRef.LastName)+" "+TrimAll(vReservRow.GuestRef.FirstName)+" "+TrimAll(vReservRow.GuestRef.SecondName);
					ThisForm["GuestDateOfBirth"+String(vIndex)] = Format(vReservRow.GuestRef.DateOfBirth, "DF=dd.MM.yyyy");
					ThisForm["GuestDocumentInformation"+String(vIndex)] = String(vReservRow.GuestRef.IdentityDocumentType)+", "+TrimAll(vReservRow.GuestRef.IdentityDocumentSeries)+" "+TrimAll(vReservRow.GuestRef.IdentityDocumentNumber);
					ThisForm["GuestAddressInformation"+String(vIndex)] = TrimAll(vReservRow.GuestRef.Address);
					ThisForm["GuestMessagesInformation"+String(vIndex)] = TrimAll(vReservRow.GuestRef.Remarks)+Chars.LF;
					If vReservRow.GuestRef.IsInBlackList Then
						Items["GuestMessagesInformation"+String(vIndex)].TextColor = New Color(255, 0, 0);
					ElsIf vReservRow.GuestRef.IsInWhiteList Then
						Items["GuestMessagesInformation"+String(vIndex)].TextColor = New Color(0, 255, 0);
					EndIf;
					Items.RoomTypeDecoration.Title = String(vReservRow.Ref.RoomType)+"; "+Format(vReservRow.Ref.CheckInDate, "DF=dd.MM.yyyy")+"-"+Format(vReservRow.Ref.CheckOutDate, "DF=dd.MM.yyyy");
					vMessages = cmGetMessagesForObject(vReservRow.GuestRef);
					For Each vMessage In vMessages Do
						ThisForm["GuestMessagesInformation"+String(vIndex)] = ThisForm["GuestMessagesInformation"+String(vIndex)] + TrimAll(vMessage.Remarks) + "; " + Chars.LF;
					EndDo;
					// Room
					If ValueIsFilled(vReservRow.Ref.Room) Then
						Items.FooterDecoration.Title = NStr("ru='Номер: '; en='Room: '; de='Zimmer: '") + String(vReservRow.Ref.Room);
						Items.Room.Visible = False;
					Else
						Items.FooterDecoration.Title = NStr("ru='Номер: '; en='Room: '; de='Zimmer: '");
						Items.Room.Visible = True;
					EndIf;
					// Load client photo
					vPicture = vReservRow.GuestRef.Photo.Get();
					If vPicture = Undefined Then
						vPictureAddress = PutToTempStorage(PictureLib.Empty);
					Else    
						vPictureAddress = PutToTempStorage(vPicture);
					EndIf;
					ThisForm["GuestPhoto"+String(vIndex)] = vPictureAddress;
					vIndex = vIndex + 1;
				Except
				EndTry;
			EndDo;
		Else
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServerExport

#EndRegion

