
#Region Public

// -----------------------------------------------------------------------------
// Description: Standard client type control on change event processing routine
// Parameters: Client type, Client type confirmation text, Client type control, 
//             Whether to show default confirmation text pattern or not
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmClientTypeOnChange(pClientType, pClientTypeConfirmationText, 
                               pControl, pShowConfirmationText = False) Export
	If ValueIsFilled(pClientType) Then
		If pClientType.AskForConfirmation Then
			If Not pShowConfirmationText Then
				pClientTypeConfirmationText = pClientType.ConfirmationPattern;
			EndIf;
			vRes = InputString(pClientTypeConfirmationText,
			                   NStr("ru='Заполните шаблон строки подтверждения!';
							        |de='Vorlage der Bestätigungszeile ausfüllen!';
			                        |en='Please fill confirmation text pattern!'"),
			                   100, False);
			If vRes Then
				If Upper(TrimAll(pClientTypeConfirmationText)) = Upper(TrimAll(pClientType.ConfirmationPattern)) Then
					DoMessageBox(NStr("ru='Строка подтверждения совпадает с шаблоном! Выбор типа клиента будет отменен.';
					                  |de='Zeile für die Bestätigung stimmt mit Vorlage überein! Die Auswahl des Kundentyps wird zurückgesetzt!'; 
					                  |en='Confirmation text is the same as confirmation pattern! Client type will be cleared.'"));
					pClientType = Catalogs.ClientTypes.EmptyRef();
					pClientTypeConfirmationText = "";
				ElsIf IsBlankString(pClientTypeConfirmationText) Then
					DoMessageBox(NStr("ru='Строка подтверждения не введена! Выбор типа клиента будет отменен.';
					                  |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl des Kundentyps wird zurückgesetzt.'; 
									  |en='Confirmation text is not entered! Client type will be cleared.'"));
					pClientType = Catalogs.ClientTypes.EmptyRef();
					pClientTypeConfirmationText = "";
				EndIf;
			Else
				If Not pShowConfirmationText Then
					DoMessageBox(NStr("ru='Строка подтверждения не введена! Выбор типа клиента будет отменен.';
					                  |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl des Kundentyps wird zurückgesetzt.'; 
									  |en='Confirmation text is not entered! Client type will be cleared.'"));
					pClientType = Catalogs.ClientTypes.EmptyRef();
					pClientTypeConfirmationText = "";
				EndIf;
			EndIf;
		Else
			pClientTypeConfirmationText = "";
		EndIf;
	Else
		pClientTypeConfirmationText = "";
	EndIf;
	If IsBlankString(pClientTypeConfirmationText) Then
		If ValueIsFilled(pClientType) Then
			If pClientType.AskForConfirmation Then
				If pControl <> Undefined Then
					pControl.Caption = NStr("ru='< введите строку подтверждения > ';
					                        |de='< führen Sie die Bestätigungszeile ein > '; 
					                        |en='< enter confirmation string > '");
				EndIf;
			EndIf;
		EndIf;
	Else
		If pControl <> Undefined Then
			pControl.Caption = TrimAll(pClientTypeConfirmationText);
		EndIf;
	EndIf;
EndProcedure // cmClientTypeOnChange

// -----------------------------------------------------------------------------
// Description: Standard marketing code control on change event processing routine
// Parameters: Marketing code, Marketing code confirmation text, Marketing code control, 
//             Whether to show default confirmation text pattern or not
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmMarketingCodeOnChange(pMarketingCode, pMarketingCodeConfirmationText, 
                                  pControl, pShowConfirmationText = False) Export
	If ValueIsFilled(pMarketingCode) Then
		If pMarketingCode.AskForConfirmation Then
			If Not pShowConfirmationText Then
				pMarketingCodeConfirmationText = pMarketingCode.ConfirmationPattern;
			EndIf;
			vRes = InputString(pMarketingCodeConfirmationText,
			                   NStr("ru='Заполните шаблон строки подтверждения!';
							        |de='Vorlage der Bestätigungszeile ausfüllen!'; 
			                        |en = 'Please fill confirmation text pattern!'"),
			                   100, False);
			If vRes Then
				If Upper(TrimAll(pMarketingCodeConfirmationText)) = Upper(TrimAll(pMarketingCode.ConfirmationPattern)) Then
					DoMessageBox(NStr("ru='Строка подтверждения совпадает с шаблоном! Выбор направления маркетинга будет отменен.';
					                  |de='Zeile für die Bestätigung stimmt mit Vorlage überein! Die Auswahl der Marketingrichtung wird zurückgesetzt!'; 
					                  |en='Confirmation text is the same as confirmation pattern! Marketing code will be cleared.'"));
					pMarketingCode = Catalogs.MarketingCodes.EmptyRef();
					pMarketingCodeConfirmationText = "";
				ElsIf IsBlankString(pMarketingCodeConfirmationText) Then
					DoMessageBox(NStr("ru='Строка подтверждения не введена! Выбор направления маркетинга будет отменен.';
					                  |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl der Marketingrichtung wird zurückgesetzt.'; 
									  |en='Confirmation text is not entered! Marketing code will be cleared.'"));
					pMarketingCode = Catalogs.MarketingCodes.EmptyRef();
					pMarketingCodeConfirmationText = "";
				EndIf;
			Else
				If Not pShowConfirmationText Then
					DoMessageBox(NStr("ru='Строка подтверждения не введена! Выбор направления маркетинга будет отменен.';
					                  |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl der Marketingrichtung wird zurückgesetzt.'; 
									  |en='Confirmation text is not entered! Marketing code will be cleared.'"));
					pMarketingCode = Catalogs.MarketingCodes.EmptyRef();
					pMarketingCodeConfirmationText = "";
				EndIf;
			EndIf;
		Else
			pMarketingCodeConfirmationText = "";
		EndIf;
	Else
		pMarketingCodeConfirmationText = "";
	EndIf;
	If IsBlankString(pMarketingCodeConfirmationText) Then
		If ValueIsFilled(pMarketingCode) Then
			If pMarketingCode.AskForConfirmation Then
				If pControl <> Undefined Then
					pControl.Caption = NStr("ru='< введите строку подтверждения > ';
					                        |de='< führen Sie die Bestätigungszeile ein > '; 
					                        |en='< enter confirmation string > '");
				EndIf;
			EndIf;
		EndIf;
	Else
		If pControl <> Undefined Then
			pControl.Caption = TrimAll(pMarketingCodeConfirmationText);
		EndIf;
	EndIf;
EndProcedure // cmMarketingCodeOnChange

// -----------------------------------------------------------------------------
// Description: Standard dicount type control on change event processing routine
// Parameters: Discount percent number, Discount type, Discount type confiramtion text, 
//             Discount type control, Whether to show default confirmation text pattern or not, 
//             Whether to ask for the confirmation text or not
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmDiscountTypeOnChange(pDiscount, pDiscountType, pDiscountConfirmationText, pControl, 
                                 pShowConfirmationText = False, pAskForConfirmation = True) Export
	If pAskForConfirmation = Undefined Then
		pAskForConfirmation = True;
	EndIf;
	If ValueIsFilled(pDiscountType) Then
		If pAskForConfirmation Then
			If pDiscountType.AskForConfirmation Then
				If Not pShowConfirmationText Then
					pDiscountConfirmationText = pDiscountType.ConfirmationPattern;
				EndIf;
				vRes = InputString(pDiscountConfirmationText,
				                   NStr("ru='Заполните шаблон строки подтверждения!';
								        |de='Vorlage der Bestätigungszeile ausfüllen!'; 
				                        |en='Please fill confirmation text pattern!'"),
				                   100, False);
				If vRes Then
					If Upper(TrimAll(pDiscountConfirmationText)) = Upper(TrimAll(pDiscountType.ConfirmationPattern)) Then
						DoMessageBox(NStr("ru='Строка подтверждения совпадает с шаблоном! Выбор типа скидки будет отменен.';
						                  |de='Zeile für die Bestätigung stimmt mit Vorlage überein! Die Auswahl der Art des Preisnachlasses wird zurückgesetzt!'; 
						                  |en='Confirmation text is the same as confirmation pattern! Discount type will be cleared.'"));
						pDiscount = 0;
						pDiscountType = Catalogs.DiscountTypes.EmptyRef();
						pDiscountConfirmationText = "";
					ElsIf IsBlankString(pDiscountConfirmationText) Then
						DoMessageBox(NStr("ru='Строка подтверждения не введена! Выбор типа скидки будет отменен.';
						                  |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl der Art des Preisnachlasses wird zurückgesetzt.'; 
										  |en='Confirmation text is not entered! Discount type will be cleared.'"));
						pDiscount = 0;
						pDiscountType = Catalogs.DiscountTypes.EmptyRef();
						pDiscountConfirmationText = "";
					EndIf;
				Else
					If Not pShowConfirmationText Then
						DoMessageBox(NStr("ru='Строка подтверждения не введена! Выбор типа скидки будет отменен.';
						                  |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl der Art des Preisnachlasses wird zurückgesetzt.'; 
										  |en='Confirmation text is not entered! Discount type will be cleared.'"));
						pDiscount = 0;
						pDiscountType = Catalogs.DiscountTypes.EmptyRef();
						pDiscountConfirmationText = "";
					EndIf;
				EndIf;
			Else
				pDiscountConfirmationText = "";
			EndIf;
		EndIf;
	Else
		If pAskForConfirmation Then
			InputString(pDiscountConfirmationText,
			            NStr("ru='Заполните шаблон строки подтверждения!';
						     |de='Vorlage der Bestätigungszeile ausfüllen!'; 
			                 |en='Please fill confirmation text pattern!'"),
			            100, False);
		Else
			pDiscountConfirmationText = "";
		EndIf;
	EndIf;
	If pControl <> Undefined Then
		If IsBlankString(pDiscountConfirmationText) Then
			pControl.Caption = NStr("ru='< введите строку подтверждения > ';
			                        |de='< führen Sie die Bestätigungszeile ein > '; 
			                        |en='< enter confirmation string > '");
		Else
			pControl.Caption = TrimAll(pDiscountConfirmationText);
		EndIf;
	EndIf;
EndProcedure // cmDiscountTypeOnChange

// -----------------------------------------------------------------------------
// Description: Standard client control start choice event processing routine
// Parameters: Object ref, Form, Client control, Default clients folder where to create new client, 
//             Document ref
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmClientStartChoice(pObjectRef, pForm, pControl, pDefaultFolder, pDocRef = Undefined) Export
	// Get clients search form
	vFrm = Catalogs.Clients.GetChoiceForm("SearchForm", pControl);
	vFrm.ChoiceMode = True;
	vFrm.ChoiceInitialValue = pObjectRef;
	vFrm.MultipleChoice = False;
	vFrm.DefaultFolder = pDefaultFolder;
	If ValueIsFilled(pObjectRef) And 
	   TypeOf(pObjectRef) = Type("CatalogRef.Clients") Then
		vFrm.SelTemplateClient = pObjectRef;
	ElsIf ValueIsFilled(pDocRef) And 
	      TypeOf(pDocRef) = Type("CatalogRef.Clients") Then
		vFrm.SelTemplateClient = pDocRef;
	ElsIf ValueIsFilled(pDocRef) And 
	     (TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation")) Then 
		vFrm.SelTemplateClient = pDocRef.Guest;
	EndIf;
	If Not vFrm.IsOpen() Then
		vFrm.WindowAppearanceMode = WindowAppearanceModeVariant.Maximized;
	EndIf;
	vFrm.Open();
EndProcedure // cmClientTextEditEnd

// -----------------------------------------------------------------------------
// Description: Standard client control text edit end event processing routine
// Parameters: Object ref, Form, Client control, Text entered, Default clients 
//             folder where to create new client, Document ref
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmClientTextEditEnd(pObjectRef, pForm, pControl, pText, pDefaultFolder, pDocRef = Undefined) Export
	// Get clients search form
	vFrm = Catalogs.Clients.GetChoiceForm("SearchForm", pControl);
	vFrm.ChoiceMode = True;
	vFrm.ChoiceInitialValue = pObjectRef;
	vFrm.MultipleChoice = False;
	// Fill form attributes
	vText = TrimAll(pText);
	// Check that identity document number is entered
	vWrk = cmCharRepl("0123456789", vText, "          ");
	If IsBlankString(vWrk) Then
		// Identity document number is entered
		vFrm.SelLastName = "";
		vFrm.SelFirstName = "";
		vFrm.SelSecondName = "";
		vFrm.SelIdentityDocumentNumber = vText;
	Else
		rLastName = "";
		rFirstName = "";
		rSecondName = "";
		rSex = Undefined;
		// Try to parse text to last name, first name and second name
		cmParseClientFullName(vText, rLastName, rFirstName, rSecondName, rSex);
		// Guest description is entered
		vFrm.SelLastName = rLastName;
		vFrm.SelFirstName = rFirstName;
		vFrm.SelSecondName = rSecondName;
		vFrm.SelIdentityDocumentNumber = "";
	EndIf;
	vFrm.DefaultFolder = pDefaultFolder;
	If ValueIsFilled(pObjectRef) And 
	   TypeOf(pObjectRef) = Type("CatalogRef.Clients") Then
		vFrm.SelTemplateClient = pObjectRef;
	ElsIf ValueIsFilled(pDocRef) And 
	      TypeOf(pDocRef) = Type("CatalogRef.Clients") Then
		vFrm.SelTemplateClient = pDocRef;
	ElsIf ValueIsFilled(pDocRef) And 
	     (TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation")) Then 
		vFrm.SelTemplateClient = pDocRef.Guest;
	EndIf;
	If Not vFrm.IsOpen() Then
		vFrm.WindowAppearanceMode = WindowAppearanceModeVariant.Maximized;
	EndIf;
	vFrm.Open();
EndProcedure // cmClientTextEditEnd

// -----------------------------------------------------------------------------
// Description: Asks user to enter guest check-out date
// Parameters: Guest check-in date, Guest planned check-out date
// Return value: Check-out date
// -----------------------------------------------------------------------------
Function cmGetCheckOutDate(pCheckInDate, pCheckOutDate) Export
	vCheckOutDateTime = CurrentSessionDate();
	If vCheckOutDateTime < pCheckInDate Then
		vCheckOutDateTime = pCheckInDate;
	EndIf;
	vFrm = GetCommonForm("InputDateTime");
	If cmCheckUserPermissions("HavePermissionToUseReferenceHourAsDefaultCheckOutTime") Then
		vFrm.SelDate = BegOfDay(CurrentSessionDate());
		If BegOfDay(pCheckOutDate) = BegOfDay(CurrentSessionDate()) Then
			If CurrentSessionDate() < pCheckOutDate Then
				vFrm.SelTime = cmExtractTime(CurrentSessionDate());
			Else
				vFrm.SelTime = cmExtractTime(pCheckOutDate);
			EndIf;
		Else
			vFrm.SelTime = cmExtractTime(pCheckOutDate);
		EndIf;
	Else
		vFrm.SelDate = BegOfDay(CurrentSessionDate());
		vFrm.SelTime = cmExtractTime(CurrentSessionDate());
	EndIf;
	vFrm.SelDescription = NStr("ru='Укажите дату и время выселения...';
	                           |de='Geben Sie das Datum und die Zeit der Ausweisung an…'; 
							   |en='Input check-out date and time please...'");
	If Not cmCheckUserPermissions("HavePermissionToEditCheckOutDateTime") Then
		vFrm.SelIsProtected = True;
	EndIf;
	vCheckOutDateTime = vFrm.DoModal();
	// Check check out date and time entered
	If Not ValueIsFilled(vCheckOutDateTime) Then
		DoMessageBox(NStr("ru='Процедура выселения отменена!';
		                  |de='Das Ausweisungsverfahren wurde abgebrochen'; 
						  |en='Check-out procedure is canceled!'"));
		Return vCheckOutDateTime;
	EndIf;
	While vCheckOutDateTime < pCheckInDate Do
		DoMessageBox(NStr("ru='Ввели дату и время выселения, которые раньше чем дата и время заезда!';
		                  |de='Sie haben ein Abreisedatum und eine Abreisezeit eingegeben, die vor dem Anreisedatum und der Anreisezeit liegen!'; 
						  |en='You have entered check-out date and time that are earlier then check-in date and time!'"));
		vCheckOutDateTime = cmGetCheckOutDate(pCheckInDate, pCheckOutDate);
		If Not ValueIsFilled(vCheckOutDateTime) Then
			Return vCheckOutDateTime;
		EndIf;
	EndDo;
	If Not cmCheckUserPermissions("HavePermissionToSetCheckOutDateInThePast") Then
		vAllowedCheckOutDelayTime = 1;
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
			If ValueIsFilled(vPermissionGroup) Then
				If vPermissionGroup.AllowedCheckOutDelayTime > 0 Then
					vAllowedCheckOutDelayTime = vPermissionGroup.AllowedCheckOutDelayTime;
				EndIf;
			EndIf;
		EndIf;
		vTimeDiff = Round((CurrentSessionDate() - vCheckOutDateTime)/3600, 3);
		While vTimeDiff > vAllowedCheckOutDelayTime Do
			DoMessageBox(NStr("ru='Ввели дату выселения в прошлом. Есть права на выселение только текущей или будущей датой!';
			                  |de='Sie haben ein Räumungsdatum angegeben, das in der Vergangenheit liegt. Sie sind berechtigt, eine Räumung nur am aktuellen oder künftigen Datum vorzunehmen!'; 
			                  |en='You have entered check-out date in the past. You have rights to do check-out by current or future dates only!'"));
			vCheckOutDateTime = cmGetCheckOutDate(pCheckInDate, pCheckOutDate);
			If Not ValueIsFilled(vCheckOutDateTime) Then
				Return vCheckOutDateTime;
			EndIf;
			vTimeDiff = Round((CurrentSessionDate() - vCheckOutDateTime)/3600, 3);
		EndDo;
	EndIf;
	Return vCheckOutDateTime; 
EndFunction // cmGetCheckOutDate

// -----------------------------------------------------------------------------
// Description: Checks user permission to issue door lock key card for the room
// Parameters: Door lock system driver data processor object
// Return value: True if operation is allowed, false if not
// -----------------------------------------------------------------------------
Function cmCheckPermissionsToIssueKeyCards(pDriverObj) Export
	If Not cmCheckUserPermissions("HavePermissionToChangeCheckOutDateInDoorLockSystem") Then
		vParentDoc = pDriverObj.ParentDoc;
		If ValueIsFilled(vParentDoc) And TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
			If Not ValueIsFilled(vParentDoc.AccommodationStatus) Or ValueIsFilled(vParentDoc.AccommodationStatus) And (Not vParentDoc.AccommodationStatus.IsInHouse And vParentDoc.AccommodationStatus.IsActive Or Not vParentDoc.AccommodationStatus.IsActive) Then
				vMessage = NStr("en='You do not have rights to issue key cards for checked-out guests!'; 
				                |de='Sie haben keine Rechte an Schlüsselkarten für die checked-out Gäste ausgeben!'; 
								|ru='Нет прав выписывать ключи выехавшим гостям!'");
				WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, pDriverObj.Metadata(), pDriverObj.Guest, vMessage);
				DoMessageBox(vMessage + Chars.LF + NStr("en='Operation will be canceled!';ru='Операция будет отменена!';de='Die Operation wird abgebrochen!'"));
				Return False;
			EndIf;
		EndIf;
	EndIf;
	vBalances = cmGetClientRoomBalances(New Boundary(BegOfDay(pDriverObj.CheckOutDate), BoundaryType.Excluding), pDriverObj.Room, pDriverObj.Guest);
	For Each vBalancesRow In vBalances Do
		If (vBalancesRow.ClientSumBalance + vBalancesRow.ClientLimitBalance) > 0 Then
			vMessage = NStr("en='Client has debt on " + Format(pDriverObj.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + " date for the " + TrimAll(pDriverObj.Room) + " room!'; 
			                |de='Client has debt on " + Format(pDriverObj.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + " date for the " + TrimAll(pDriverObj.Room) + " room!'; 
							|ru='На дату " + Format(pDriverObj.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + " у гостя в номере " + TrimAll(pDriverObj.Room) + " есть задолженность!'");
			If Not cmCheckUserPermissions("HavePermissionToIssueKeyCardsForGuestsWithDebtsOnKeyValidToDate") Then
				WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, pDriverObj.Metadata(), pDriverObj.Guest, vMessage);
				DoMessageBox(vMessage + Chars.LF + NStr("en='Operation will be canceled!';ru='Операция будет отменена!';de='Die Operation wird abgebrochen!'"));
				Return False;
			Else
				// User activity history   
				vEventDescription = NStr("en = 'Issue of a key without payment'; de = 'Schlüsselübergabe ohne Bezahlung'; ru = 'Выдача ключа без оплаты'") + Chars.LF + vMessage;
				InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription);
				Break;
			EndIf;
		EndIf;
	EndDo;
	If Not cmCheckUserPermissions("HavePermissionToIssueKeyCardsForGuestsWithDebtsOnKeyValidToDate") Then
		If ValueIsFilled(pDriverObj.AccommodationType) Then
			If pDriverObj.AccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Or
			   pDriverObj.AccommodationType.Type = Enums.AccomodationTypes.Together Then
				vMessage = NStr("en='You do not have rights to issue keys to guests with " + TrimAll(pDriverObj.AccommodationType) + " accommodation type! Operation will be canceled!'; 
				                |de='You do not have rights to issue keys to guests with " + TrimAll(pDriverObj.AccommodationType) + " accommodation type! Operation will be canceled!'; 
				                |ru='Нет прав выписывать ключи гостям с видом размещения " + TrimAll(pDriverObj.AccommodationType) + "! Операция будет отменена!'");
				WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, pDriverObj.Metadata(), pDriverObj.Guest, vMessage);
				DoMessageBox(vMessage);
				Return False;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(pDriverObj.Folio) And pDriverObj.Folio.IsClosed Then
		vMessage = TrimAll(pDriverObj.Guest) + ", " + TrimAll(pDriverObj.Room) + ", " + Format(pDriverObj.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pDriverObj.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
		// User activity history   
		vEventDescription = NStr("en = 'Request a key for a closed folio'; de = 'Fordern Sie einen Schlüssel für ein geschlossenes Folio an'; ru = 'Запрос на выдачу ключа по закрытому фолио'") + Chars.LF + vMessage;
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription);
	EndIf;
	WriteLogEvent(NStr("en='KeyCardEvents.IssueKeyRequest'; de='KeyCardEvents.IssueKeyRequest'; ru='СигналыПоКлючам.ЗапросНаВыдачуКлюча'"), EventLogLevel.Information, pDriverObj.Metadata(), pDriverObj.Guest, TrimAll(pDriverObj.Guest) + ", " + TrimAll(pDriverObj.Room) + ", " + Format(pDriverObj.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pDriverObj.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
	Return True;
EndFunction // cmCheckPermissionsToIssueKeyCards

// -----------------------------------------------------------------------------
// Description: Check should we turn "Fix reservation conditions" flag on while
//              checking-in guest
// Parameters: Accommodation object where to turn flag on, Reservation document reference
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmCheckFixReservationConditionsAtCheckIn(pAccObj, pResRef) Export 
	If Not pAccObj.FixReservationConditions And ValueIsFilled(pAccObj.Hotel) And Not pAccObj.Hotel.UseReservationTimeForCheckIn Then
		If ValueIsFilled(pResRef.ReservationStatus) And Not pResRef.ReservationStatus.FixReservationConditions Then
			vDoAskAboutFixReservationConditions = True;
			If ValueIsFilled(pAccObj.HotelProduct) And (pAccObj.HotelProduct.FixProductPeriod Or pAccObj.HotelProduct.FixPlannedPeriod) Then
				vDoAskAboutFixReservationConditions = False;
			EndIf;
			If vDoAskAboutFixReservationConditions Then
				If BegOfDay(CurrentSessionDate()) > BegOfDay(pResRef.CheckInDate) Then
					vQueryText = NStr("en='Guest has late check-in (was expected on " + Format(pResRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + ")! Should we charge for this delay?';
					                  |de='Guest has late check-in (was expected on " + Format(pResRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + ")! Should we charge for this delay?';
									  |ru='Гость заезжает позже чем планировал (ожидаемые дата и время заезда " + Format(pResRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + ")! Нужно ли начислить штраф за опоздание?'");
					If DoQueryBox(vQueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No) = DialogReturnCode.Yes Then
						pAccObj.FixReservationConditions = True;
						pAccObj.pmCalculateServices();
					EndIf;
				ElsIf BegOfDay(CurrentSessionDate()) < BegOfDay(pResRef.CheckInDate) Then
					If ValueIsFilled(pResRef.PlannedPaymentMethod) And pResRef.PlannedPaymentMethod.IsByBankTransfer Then
						If ValueIsFilled(pResRef.RoomRate) Then
							If Not pResRef.RoomRate.IsRackRate Then
								vQueryText = NStr("en='Guest has early check-in (is expected on " + Format(pResRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + ")! Should we charge early check-in days by rack rate?';
								                  |de='Guest has early check-in (is expected on " + Format(pResRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + ")! Should we charge early check-in days by rack rate?';
												  |ru='Гость заезжает раньше чем планировал (дата и время заезда " + Format(pResRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + ")! Нужно ли начислить стоимость дней проживания до даты планируемого заезда по базовому тарифу?'");
								If DoQueryBox(vQueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No) = DialogReturnCode.Yes Then
									pAccObj.FixReservationConditions = True;
									pAccObj.pmCalculateServices();
								EndIf;
							Else
								vQueryText = NStr("en='Guest has early check-in (is expected on " + Format(pResRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + ", reservation is expected to be paid by bank transfer)! Should we charge guest for early check-in days or let those days be paid by customer?';
								                  |de='Guest has early check-in (is expected on " + Format(pResRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + ", reservation is expected to be paid by bank transfer)! Should we charge guest for early check-in days or let those days be paid by customer?';
												  |ru='Гость заезжает раньше чем планировал (дата и время заезда " + Format(pResRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + ", бронь оплачивается организацией)! Нужно ли начислить стоимость дней проживания до даты планируемого заезда на самого гостя? Если ответить <Нет>, то стоимость дней раннего заезда попадет в счет организации.'");
								If DoQueryBox(vQueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No) = DialogReturnCode.Yes Then
									pAccObj.FixReservationConditions = True;
									pAccObj.pmCalculateServices();
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // cmCheckFixReservationConditionsAtCheckIn

// -----------------------------------------------------------------------------
// Description: Check should we turn "Fix reservation conditions" flag on while
//              checking-out guest
// Parameters: Accommodation object where to turn flag on, Reservation document reference
// Return value: None
// -----------------------------------------------------------------------------
Function cmCheckFixReservationConditionsAtCheckOut(pCheckOutDate, pResRef) Export 
	vFixReservationConditions = False;
	If ValueIsFilled(pResRef.ReservationStatus) And Not pResRef.ReservationStatus.FixReservationConditions Then
		If ValueIsFilled(pResRef.PlannedPaymentMethod) And pResRef.PlannedPaymentMethod.IsByBankTransfer Then
			If BegOfDay(pCheckOutDate) < BegOfDay(pResRef.CheckOutDate) Then
				vQueryText = NStr("en='Guest has early check-out (is expected on " + Format(pResRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ")! Should we charge early check-out days according to the reservation?';
				                  |de='Guest has early check-out (is expected on " + Format(pResRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ")! Should we charge early check-out days according to the reservation?';
								  |ru='Гость выезжает раньше чем ожидалось по брони (дата и время выезда по брони " + Format(pResRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ")! Нужно ли начислить стоимость дней проживания до даты планируемого выезда?'");
				If DoQueryBox(vQueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No) = DialogReturnCode.Yes Then
					vFixReservationConditions = True;
				EndIf;
			ElsIf (pCheckOutDate - pResRef.CheckOutDate) > 3600 Then
				vQueryText = NStr("en='Guest has late check-out (was expected on " + Format(pResRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ")! Should we charge late check-out by rack rate?';
				                  |de='Guest has late check-out (was expected on " + Format(pResRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ")! Should we charge late check-out by rack rate?';
								  |ru='Гость выезжает позже чем ожидалось по брони (дата и время выезда по брони " + Format(pResRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ")! Нужно ли начислить стоимость позднего выезда по базовому тарифу?'");
				If DoQueryBox(vQueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No) = DialogReturnCode.Yes Then
					vFixReservationConditions = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vFixReservationConditions;
EndFunction // cmCheckFixReservationConditionsAtCheckOut

// -----------------------------------------------------------------------------
// Description: Extends period of stay of all hotel in-house guests to the next 
//              hour from current time. I.e. if current time is 15:23 then period 
//              of stay will be extended to 16:00
// Parameters: Hotel, period of stay of all in-house guests from this hotel will 
//             be extended
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmExtendInHouseGuestsPeriodOfStay(Val pHotel = Undefined, Val pFreeOfChargeMinutes = 0, pIsInteractive = True) Export
	// Fill hotel
	If pHotel = Undefined Then
		If Not ValueIsFilled(SessionParameters.CurrentHotel) Then
			Return;
		EndIf;
		pHotel = SessionParameters.CurrentHotel;
	EndIf;
	// Check interactive mode
	If pIsInteractive = Undefined Then
		pIsInteractive = True;
	EndIf;
	// Fill target check-out time 
	vCheckOutDate = CurrentSessionDate();
	// Check free of charge minutes
	If pFreeOfChargeMinutes = 0 Then
		pFreeOfChargeMinutes = 20;
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
			If ValueIsFilled(vPermissionGroup) Then
				If vPermissionGroup.AllowedCheckOutDelayTime > 0 And vPermissionGroup.AllowedCheckOutDelayTime < 1 Then
					pFreeOfChargeMinutes = Round(vPermissionGroup.AllowedCheckOutDelayTime * 60, 0);
				ElsIf vPermissionGroup.RoomExaminationFreeOfChargeTime <> 0 Then
					pFreeOfChargeMinutes = Round(vPermissionGroup.RoomExaminationFreeOfChargeTime * 60, 0);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Build list of accommodations to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE (&qHotelIsEmpty
	|			OR Accommodation.Hotel = &qHotel)
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND DATEDIFF(Accommodation.CheckOutDate, &qCheckOutDate, MINUTE) >= &qFreeOfChargePeriodInMinutes
	|
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qCheckOutDate", vCheckOutDate);
	vQry.SetParameter("qFreeOfChargePeriodInMinutes", pFreeOfChargeMinutes);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		Try
			BeginTransaction(DataLockControlMode.Managed);
			vAccObj = vDocsRow.Ref.GetObject();
			If vAccObj.pmGetNextAccommodationInChain() = Undefined Then
				vAccObj.CheckOutDate = BegOfDay(vAccObj.CheckOutDate) + (Hour(vAccObj.CheckOutDate) + 1) * 3600 + Minute(vAccObj.CheckOutDate) * 60;
				vAccObj.Duration = vAccObj.pmCalculateDuration();
				vAccObj.pmCalculateServices();
				vAccObj.Write(DocumentWriteMode.Posting);
				vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
			CommitTransaction();
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.ExtendInHouseGuestsPeriodOfStay';ru='Обработка.ПродлитьПериодПроживанияГостей';de='DataProcessor.ExtendInHouseGuestsPeriodOfStay'"), EventLogLevel.Warning, vAccObj.Metadata(), vAccObj.Ref, vMessage);
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
			EndIf;
		EndTry;
	EndDo;
	// Build list of accommodations to checking out
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref,
	|	Accommodation.Room AS Room,
	|	Accommodation.Guest.FullName AS Guest,
	|	Accommodation.CheckInDate AS CheckInDate,
	|	Accommodation.CheckOutDate AS CheckOutDate
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	(&qHotelIsEmpty
	|			OR Accommodation.Hotel = &qHotel)
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND (Accommodation.AccommodationType.Type = &qRoom
	|			OR Accommodation.AccommodationType.Type = &qBeds)
	|	AND Accommodation.CheckOutDate < &qCheckOutDate
	|
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qCheckOutDate", vCheckOutDate+900);
	vQry.SetParameter("qRoom", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qBeds", Enums.AccomodationTypes.Beds);
	vAccDocs = vQry.Execute().Unload();
	If vAccDocs.Count()>0 Then
		vFrm = GetForm("CommonForm.tcGuestsReadyToBeCheckedOut", , , "tcGuestsReadyToBeCheckedOut");
		If Not vFrm.IsOpen() Then
			For Each vDocsRow In vAccDocs Do
				vNewStr = vFrm.Docs.Add();
				vNewStr.Ref = vDocsRow.Ref;
				vNewStr.Room = vDocsRow.Room;
				vNewStr.Guest = vDocsRow.Guest;
				vNewStr.CheckInDate = vDocsRow.CheckInDate;
				vNewStr.CheckOutDate = vDocsRow.CheckOutDate;
				If vDocsRow.CheckOutDate < CurrentSessionDate() Then
					vNewStr.Icon = PictureLib.RedCube;
				Else
					vNewStr.Icon = PictureLib.YellowCube;
				EndIf;
			EndDo;
			vFrm.Open();
		EndIf;
	EndIf;
EndProcedure // cmExtendInHouseGuestsPeriodOfStay

// -----------------------------------------------------------------------------
// Description: Checks if guest has to get its discount card according to the hotel rules
// Parameters: Client reference, Accommodation document object
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmIssueDiscountCard(pGuest, pDocObj) Export
	// Initialize some vars
	vPeriodTo = CurrentSessionDate();
	If ValueIsFilled(pDocObj.Hotel) And ValueIsFilled(pDocObj.Hotel.DateToGetBonusBalance) Then
		If pDocObj.Hotel.DateToGetBonusBalance = Enums.DatesToGetBonusBalance.CheckInDate Then
			If TypeOf(pDocObj) = Type("DocumentObject.ResourceReservation") Then
				vPeriodTo = BegOfDay(pDocObj.DateTimeFrom) - 1;
			Else
				vPeriodTo = BegOfDay(pDocObj.CheckInDate) - 1;
			EndIf;
		ElsIf pDocObj.Hotel.DateToGetBonusBalance = Enums.DatesToGetBonusBalance.CheckOutDate Then
			If TypeOf(pDocObj) = Type("DocumentObject.ResourceReservation") Then
				vPeriodTo = EndOfDay(pDocObj.DateTimeTo);
			Else
				vPeriodTo = EndOfDay(pDocObj.CheckOutDate);
			EndIf;
		EndIf;
	EndIf;
	// Try to find rule suitable for the client
	vClientResource = 0;
	vClientRule = Undefined;
	// Check should we call web service to get client resource from the master node database
	vExchangePlan = ExchangePlans.CentralOfficeExchangePlan;      
	vThisNode = vExchangePlan.ThisNode();
	vMasterNode = vExchangePlan.FindByAttribute("IsMaster", True);
	If Not vThisNode.DeletionMark And vMasterNode <> vThisNode And 
		Not IsBlankString(vMasterNode.DataExchangeWSDLHost) And vMasterNode.OnlineSyncIsActive  Then
		Try
			// Get client statistics from the master node
			vWSDef = New WSDefinitions(vMasterNode.DataExchangeWSDLHost);
			vWSProxy = New WSProxy(vWSDef, "http://www.1chotel.ru/ws/interfaces/dataexchange/", "DataExchangeInterfaces", "DataExchangeInterfacesSoap");
			// Build structure with some document data
			vDocumentDataStruct = New Structure("RoomRateCode, ClientTypeCode", "", "");
			If ValueIsFilled(pDocObj.RoomRate) Then
				vDocumentDataStruct.RoomRateCode = TrimAll(pDocObj.RoomRate.Code);
			EndIf;
			If ValueIsFilled(pDocObj.ClientType) Then
				vDocumentDataStruct.ClientTypeCode = TrimAll(pDocObj.ClientType.Code);
			EndIf;
			// Call web-service to get client statistics
			vResult = vWSProxy.CheckIfDiscountCardNeedToBeIssued(TrimAll(pGuest.Code), TrimAll(pDocObj.Hotel.Code), vPeriodTo, TrimAll(SessionParameters.CurrentLanguage.Code), vDocumentDataStruct);
			If IsBlankString(vResult.ErrorDescription) Then
				vClientResource = vResult.ClientResource;
				If vClientResource >= 0 Then
					vClientRule = New Structure("ClientType, DiscountType, ValidFrom, ValidTo, Notification", 
					                            Catalogs.ClientTypes.EmptyRef(), 
												Catalogs.DiscountTypes.EmptyRef(), 
												'00010101', '00010101', "");
					If Not IsBlankString(vResult.ClientType) Then
						vClientRule.ClientType = Catalogs.ClientTypes.FindByCode(TrimAll(vResult.ClientType));
					EndIf;
					If Not IsBlankString(vResult.DiscountType) Then
						vClientRule.DiscountType = Catalogs.DiscountTypes.FindByCode(TrimAll(vResult.DiscountType));
					EndIf;
					vClientRule.ValidFrom = vResult.ValidFrom;
					vClientRule.ValidTo = vResult.ValidTo;
					vClientRule.Notification = TrimAll(vResult.Notification);
				EndIf;
			Else
				tcCommonFunctionOnClientServer.UserMessage(vResult.ErrorDescription);
				Return;
			EndIf;
		Except
			tcCommonFunctionOnClientServer.UserMessage(ErrorDescription());
			Return;
		EndTry;
	Else
		// Run query to get discount card issue rules
		vQry = New Query();
		vQry.Text = 
		"SELECT
        |   DiscountCardIssueRules.AccumulatingDiscountType AS AccumulatingDiscountType,
        |   DiscountCardIssueRules.ResourceFrom AS ResourceFrom,
        |   DiscountCardIssueRules.ResourceTo AS ResourceTo,
        |   DiscountCardIssueRules.DiscountType AS DiscountType,
        |   DiscountCardIssueRules.ClientType AS ClientType,
        |   DiscountCardIssueRules.ValidFrom AS ValidFrom,
        |   DiscountCardIssueRules.ValidTo AS ValidTo,
        |   DiscountCardIssueRules.Notification AS Notification,
        |   DiscountCardIssueRules.ExternalAlgorithm AS ExternalAlgorithm,
        |   DiscountCardIssueRules.UseResourcesPayedAsIndividual AS UseResourcesPayedAsIndividual,
        |   DiscountCardIssueRules.UseResourcesPayedByRackRates AS UseResourcesPayedByRackRates,
        |   DiscountCardIssueRules.IssueOnlyUponCheckIn AS IssueOnlyUponCheckIn
        |FROM
        |   InformationRegister.DiscountCardIssueRules AS DiscountCardIssueRules
        |
        |ORDER BY
        |   DiscountCardIssueRules.AccumulatingDiscountType.Order,
        |   ResourceFrom,
        |   ResourceTo";
		vRules = vQry.Execute().Unload();
		If vRules.Count() = 0 Then
			// No rules found
			Return;
		EndIf;
		// Get client object
		vClientObj = pGuest.GetObject();
		// Process rules
		vCurAccumulatingDiscountType = Undefined;
		Payer = Undefined;
		If TypeOf(pDocObj) = Type("DocumentObject.Accommodation") Or TypeOf(pDocObj) = Type("DocumentObject.Reservation") Then
			vPayer = pDocObj.pmSetPlannedPaymentMethod();
		EndIf;
		
		For Each vRulesRow In vRules Do
			If Not TypeOf(pDocObj) = Type("DocumentObject.Accommodation") And vRulesRow.IssueOnlyUponCheckIn Or
				(TypeOf(pDocObj) = Type("DocumentObject.Accommodation") And vRulesRow.UseResourcesPayedAsIndividual And ValueIsFilled(pDocObj.Customer) And Not vPayer = Enums.WhoPays.Guest) Then
				Continue;
			EndIf;   
			// Get type of client stats to check
			If Not ValueIsFilled(vRulesRow.AccumulatingDiscountType) Then
				// Wrong rule record
				Continue;
			EndIf;
			If vCurAccumulatingDiscountType <> vRulesRow.AccumulatingDiscountType Then
				vCurAccumulatingDiscountType = vRulesRow.AccumulatingDiscountType;
				vClientResource = 0;
				// Check for an external algorithm
				vExternalDataProcessor = vRulesRow.ExternalAlgorithm;
				If ValueIsFilled(vExternalDataProcessor) Then
					If vExternalDataProcessor.ExternalProcessingType <> Enums.ExternalProcessingTypes.Algorithm Then
						tcCommonFunctionOnClientServer.UserMessage(NStr("en='Wrong external extension type! Should be <algorithm>';
						           |ru='Неверно указан тип внешнего модуля! Должен быть <Алгоритм>';
								   |de='Der Typ des externen Moduls ist falsch angegeben! Es muss einen <Algorithmus> geben'"));
						Return;
					Else
						vExternalAlgorithm = TrimR(vExternalDataProcessor.Algorithm);
						If IsBlankString(vExternalAlgorithm) Then
							tcCommonFunctionOnClientServer.UserMessage(NStr("en='External algorithm is empty!';ru='Внешний алгоритм не указан!';de='Externer Algorithmus nicht angegeben!'"));
							Return;
						Else
							Execute(vExternalAlgorithm);
						EndIf;
					EndIf;
				Else
					// Get client statistics
					If vCurAccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByNumberOfGuestVisits Then
						vClientResource = vClientObj.pmCountNumberOfCheckIns(, vPeriodTo, vRulesRow.UseResourcesPayedAsIndividual, vRulesRow.UseResourcesPayedByRackRates);
					ElsIf vCurAccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByAccommodationDuration Then
						vClientResource = vClientObj.pmCountNumberOfNights(, vPeriodTo, vRulesRow.UseResourcesPayedAsIndividual, vRulesRow.UseResourcesPayedByRackRates);
					ElsIf vCurAccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByServicesTotalSum Then
						vRevenues = vClientObj.pmGetClientRevenueStatistics(, vPeriodTo, vRulesRow.UseResourcesPayedAsIndividual, vRulesRow.UseResourcesPayedByRackRates);
						vClientResource = vRevenues.Total("SalesTurnover");
					EndIf;
				EndIf;
			EndIf;
			If vRulesRow.ResourceFrom <= vClientResource And (vRulesRow.ResourceTo = 0 Or vRulesRow.ResourceTo > vClientResource) Then
				If vClientRule = Undefined Then
					vClientRule = vRulesRow;
				Else
					If ValueIsFilled(vClientRule.DiscountType) And ValueIsFilled(vRulesRow.DiscountType) And vRulesRow.DiscountType.SortCode > vClientRule.DiscountType.SortCode Then
						vClientRule = vRulesRow;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If vClientRule = Undefined Then
		// Rule was not found
		Return;
	EndIf;
	// Try to find discount card that was already issued to this guest
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DiscountCards.Ref
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	NOT DiscountCards.DeletionMark
	|	AND DiscountCards.Client = &qClient
	|	AND DiscountCards.ClientType = &qClientType
	|	AND DiscountCards.ValidFrom = &qValidFrom
	|	AND DiscountCards.ValidTo = &qValidTo
	|
	|ORDER BY
	|	DiscountCards.Code";
	vQry.SetParameter("qClient", pGuest);
	vQry.SetParameter("qClientType", vClientRule.ClientType);
	vQry.SetParameter("qValidFrom", vClientRule.ValidFrom);
	vQry.SetParameter("qValidTo", vClientRule.ValidTo);
	vClientDiscountCards = vQry.Execute().Unload();
	// Check should we show notification or not
	vDiscountCard = Undefined;
	vDoNotify = False;
	If vClientDiscountCards.Count() = 0 Then
		vDoNotify = True;
	Else
		vDiscountCard = vClientDiscountCards.Get(0).Ref;
		If vDiscountCard.DiscountType <> vClientRule.DiscountType Then
			vCardSortCode = 0;
			If ValueIsFilled(vDiscountCard.DiscountType) Then
				vCardSortCode = vDiscountCard.DiscountType.SortCode;
			EndIf;
			vRuleSortCode = 0;
			If ValueIsFilled(vClientRule.DiscountType) Then
				vRuleSortCode = vClientRule.DiscountType.SortCode;
			EndIf;
			If vRuleSortCode > vCardSortCode Then
				vDoNotify = True;
			EndIf;
		EndIf;
	EndIf;
	// Open form with "You have to issue discount card!" message notification
	If vDoNotify Then
		If vDiscountCard <> Undefined Then
			vFrm = vDiscountCard.GetForm("IssueDiscountCard", , pGuest);
		Else			
			vFrm = Catalogs.DiscountCards.GetForm("IssueDiscountCard", , pGuest);
		EndIf;
		vFrm.Client = pGuest;
		vFrm.DiscountType = vClientRule.DiscountType;
		vFrm.ClientType = vClientRule.ClientType;
		vFrm.ValidFrom = vClientRule.ValidFrom;
		vFrm.ValidTo = vClientRule.ValidTo;
		vFrm.Notification = cmNStr(vClientRule.Notification, SessionParameters.CurrentLanguage);
		vDiscountCard = vFrm.DoModal();
		If vDiscountCard <> Undefined Then
			If TypeOf(pDocObj) = Type("DocumentObject.Accommodation") And ValueIsFilled(pDocObj.AccommodationStatus) And pDocObj.AccommodationStatus.IsInHouse Or
			   TypeOf(pDocObj) = Type("DocumentObject.Reservation") And ValueIsFilled(pDocObj.ReservationStatus) And pDocObj.ReservationStatus.IsActive Or 
			   TypeOf(pDocObj) = Type("DocumentObject.ResourceReservation") And ValueIsFilled(pDocObj.ResourceReservationStatus) And pDocObj.ResourceReservationStatus.IsActive Then
				pDocObj.DiscountCard = vDiscountCard;
				// Set discounts
				pDocObj.pmSetDiscounts();
				// Automatic services list calculation	
				If TypeOf(pDocObj) = Type("DocumentObject.ResourceReservation") Then
					pDocObj.pmCalculateServices();
				Else
					pDocObj.pmCalculateServices();
				EndIf;
				// Save document
				pDocObj.Write(DocumentWriteMode.Posting);
				// Save to document change history
				If TypeOf(pDocObj) = Type("DocumentObject.ResourceReservation") Then
					pDocObj.pmWriteToResourceReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				ElsIf TypeOf(pDocObj) = Type("DocumentObject.Accommodation") Then
					pDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				Else
					pDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndIf;
		// Notify change in discount cards
		Notify("DiscountCard.Write", vDiscountCard);
	Else
		If vClientDiscountCards.Count() > 0 Then
			DoMessageBox(NStr("en='Discount card has already been issued to the guest!'; ru='Дисконтная карта гостю уже выдана!'; de='Rabatt-Karte bereits zu Gast ausgestellt worden!'"));
		EndIf;
	EndIf;
EndProcedure // cmIssueDiscountCard

#EndRegion

