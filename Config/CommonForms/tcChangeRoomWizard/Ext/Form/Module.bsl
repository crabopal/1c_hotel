
#Region FormEventHandlers

// ------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Hotel = SessionParameters.CurrentHotel;
	
	If Parameters.Property("DocRef") Then
		vAccRef = Parameters.DocRef;
		
		If ValueIsFilled(vAccRef) Then
			DocRef     = vAccRef;
			GuestGroup = vAccRef.GuestGroup;
			Room       = vAccRef.Room;
			RoomType   = vAccRef.RoomType;
			RoomRate   = vAccRef.RoomRate;
			Hotel 	   = vAccRef.Hotel;
			If TypeOf(DocRef) = Type("DocumentRef.Accommodation") Then
				If ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.ReferenceHour) Then
					DateFrom = BegOfDay(CurrentSessionDate()) + (RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour));
				Else
					DateFrom = BegOfDay(CurrentSessionDate()) + 12*3600;
				EndIf;
			Else
				DateFrom = vAccRef.CheckInDate;
			EndIf;
			If DateFrom < vAccRef.CheckOutDate Then
				DateTo = vAccRef.CheckOutDate;
			EndIf;
			RoomQuota  = vAccRef.RoomQuota;
			Company	   = vAccRef.Company;
			Items.Room.Title = NStr("en = 'Room: '; ru = 'Номер: '; de = 'Zimmer: '") + Room + " - " + RoomType;
			Items.Group.Title = NStr("en = 'Group: '; ru = 'Группа: '; de = 'Gruppe: '") + GuestGroup;	
		EndIf;	
		
		If TypeOf(vAccRef) = Type("DocumentRef.Accommodation") Then
			vAccRefStatus = vAccRef.AccommodationStatus;
			If ValueIsFilled(vAccRefStatus) And vAccRefStatus.IsActive And vAccRefStatus.IsInHouse Then
				vNewRow = GuestsList.Add();
				vNewRow.Check			  = True;
				vNewRow.Guest             = vAccRef.Guest;
				vNewRow.AccommodationType =	vAccRef.AccommodationType;
				vNewRow.DocRef            = vAccRef;
				vNewRow.BottomText        = String(vAccRef.AccommodationType) + NStr("en = ' from '; ru = ' с '; de = ' von '") + Format(vAccRef.CheckInDate,"DF=dd.MM.yyyy") + NStr("en = ' to '; ru = ' по '; de = ' zu '") + Format(vAccRef.CheckOutDate,"DF=dd.MM.yyyy");
			EndIf;
		Else
			vResRefStatus = vAccRef.ReservationStatus;
			If ValueIsFilled(vResRefStatus) And (vResRefStatus.IsActive Or vResRefStatus.IsPreliminary) Then
				vNewRow = GuestsList.Add();
				vNewRow.Check			  = True;
				vNewRow.Guest             = vAccRef.Guest;
				vNewRow.AccommodationType =	vAccRef.AccommodationType;
				vNewRow.DocRef            = vAccRef;
				vNewRow.BottomText        = String(vAccRef.AccommodationType) + NStr("en = ' from '; ru = ' с '; de = ' von '") + Format(vAccRef.CheckInDate,"DF=dd.MM.yyyy") + NStr("en = ' to '; ru = ' по '; de = ' zu '") + Format(vAccRef.CheckOutDate,"DF=dd.MM.yyyy");
			EndIf;
		EndIf;
	EndIf;
	
	If Parameters.Property("GuestTable") Then
		For Each vRow In Parameters.GuestTable Do
			vAccRef = vRow.Ref;
			If GuestsList.FindRows(New Structure("DocRef", vAccRef)).Count() > 0 Then
				Continue;
			EndIf;	
			If TypeOf(vAccRef) = Type("DocumentRef.Accommodation") Then
				vAccRefStatus = vAccRef.AccommodationStatus;
				If ValueIsFilled(vAccRefStatus) And vAccRefStatus.IsActive And vAccRefStatus.IsInHouse Then
					vNewRow = GuestsList.Add();
					vNewRow.Check			  = True;
					vNewRow.Guest             = vRow.GuestRef;
					vNewRow.AccommodationType =	vRow.AccommodationType;
					vNewRow.DocRef            = vAccRef;	
					vNewRow.BottomText        = String(vAccRef.AccommodationType) + NStr("en = ' from '; ru = ' с '; de = ' von '") + Format(vAccRef.CheckInDate,"DF=dd.MM.yyyy") + NStr("en = ' to '; ru = ' по '; de = ' zu '") + Format(vAccRef.CheckOutDate,"DF=dd.MM.yyyy");
				EndIf;
			Else
				vResRefStatus = vAccRef.ReservationStatus;
				If ValueIsFilled(vResRefStatus) And (vResRefStatus.IsActive Or vResRefStatus.IsPreliminary) Then
					vNewRow = GuestsList.Add();
					vNewRow.Check			  = True;
					vNewRow.Guest             = vRow.GuestRef;
					vNewRow.AccommodationType =	vRow.AccommodationType;
					vNewRow.DocRef            = vAccRef;	
					vNewRow.BottomText        = String(vAccRef.AccommodationType) + NStr("en = ' from '; ru = ' с '; de = ' von '") + Format(vAccRef.CheckInDate,"DF=dd.MM.yyyy") + NStr("en = ' to '; ru = ' по '; de = ' zu '") + Format(vAccRef.CheckOutDate,"DF=dd.MM.yyyy");
				EndIf;
			EndIf;
		EndDo;
	Else
		If ValueIsFilled(vAccRef) Then
			If TypeOf(vAccRef) = Type("DocumentRef.Accommodation") Then
				vOneRoomDocs = cmGetOneRoomAccommodations(vAccRef.Room, vAccRef.GuestGroup, vAccRef.CheckInDate, vAccRef.CheckOutDate, vAccRef.Number);
				If vOneRoomDocs.Count() > 0 Then
					GuestsList.Clear();
					For Each vOneRoomDocsRow In vOneRoomDocs Do
						vDocRef = vOneRoomDocsRow.Ref;
						
						vNewRow = GuestsList.Add();
						vNewRow.Guest             = vDocRef.Guest;
						vNewRow.AccommodationType =	vDocRef.AccommodationType;
						vNewRow.DocRef            = vDocRef;
						vNewRow.BottomText        = String(vDocRef.AccommodationType) + NStr("en = ' from '; ru = ' с '; de = ' von '") + Format(vDocRef.CheckInDate,"DF=dd.MM.yyyy") + NStr("en = ' to '; ru = ' по '; de = ' zu '") + Format(vDocRef.CheckOutDate,"DF=dd.MM.yyyy");
						vNewRow.DocRef            = vDocRef;	
						If vDocRef = vAccRef Then
							vNewRow.Check         = True;
						Else
							vNewRow.Check         = False;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	vAccList = GuestsList.Unload( , "DocRef");
	vBalances = GetBalancesByGuests(vAccList);
	For Each vRow In GuestsList Do
		vDocRef = vRow.DocRef;
		vBalances.Reset();
		If vBalances.FindNext(New Structure("DocRef", vDocRef)) Then
			
			vCurrency = Undefined;
			If ValueIsFilled(vRow.DocRef.Hotel) Then
				vCurrency = vRow.DocRef.Hotel.FolioCurrency;
			EndIf;
			
			vRow.Balance = vBalances.ClientSumBalance;
			vRow.LimitBalance = vBalances.ClientLimitBalance;
			vBalance = ?(ValueIsFilled(vCurrency), cmFormatSum(vBalances.ClientSumBalance, vCurrency), vBalances.ClientSumBalance);
			vRow.BalancePresentation = vBalance;
			vRow.SumAndLimBalanceDef = vBalances.ClientSumBalance - vBalances.ClientLimitBalance;
			
			// Change text in BalancePresentation
			vCAItem = ConditionalAppearance.Items.Add();
			vCAItem.UserSettingID = vRow.GetID();
			vCAItem.Use = True;
			
			vFilterItem = vCAItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			vFilterItem.Use = True;
			vFilterItem.LeftValue = New DataCompositionField("GuestsList.LimitBalance");
			vFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
			vFilterItem.RightValue = 0;

			vNewField = vCAItem.Fields.Items.Add();
			vNewField.Use = True;
			vNewField.Field = New DataCompositionField("GuestsListBalancePresentation"); 
			vCAItem.Appearance.SetParameterValue("Text", ?(ValueIsFilled(vCurrency), cmFormatSum(vRow.Balance, vCurrency), vRow.Balance) 
														 + Chars.LF + 
														 ?(ValueIsFilled(vCurrency), cmFormatSum(vRow.LimitBalance, vCurrency), vRow.LimitBalance));
			
			// Repaint text in green
			vCAItem = ConditionalAppearance.Items.Add();
			vCAItem.UserSettingID = vRow.GetID();
			vCAItem.Use = True;
			
			vFilterItem = vCAItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			
			vFilterItem.Use = True;
			vFilterItem.LeftValue = New DataCompositionField("GuestsList.SumAndLimBalanceDef");
			vFilterItem.ComparisonType = DataCompositionComparisonType.LessOrEqual;
			vFilterItem.RightValue = 0;
			
			vNewField = vCAItem.Fields.Items.Add();
			vNewField.Use = True;
			vNewField.Field = New DataCompositionField("GuestsListBalancePresentation"); 
			vCAItem.Appearance.SetParameterValue("TextColor", WebColors.Green);
		EndIf;
	EndDo;

	If ValueIsFilled(Hotel) Then
		BookOutPriceCurrency = Hotel.BaseCurrency;
	EndIf;
	
	// Operation type
	If Parameters.Property("OperationType") Then
		Operations = Parameters.OperationType;
	EndIf;
	If ValueIsFilled(vAccRef) And TypeOf(vAccRef) = Type("DocumentRef.Accommodation") Then
		Items.Operations.ChoiceList.Delete(0);
		If Operations = 0 Then
			Operations = 1;
		EndIf;
	EndIf;
	
	// Do not change availability
	Items.DoNotChangeAvailability.Visible = cmCheckUserPermissions("HavePermissionToUseDoNotChangeAvailabilityFlag");
	
	OperationVisible();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// ------------------------------------------------------------------------------
&AtClient
Procedure OperationsOnChange(Item)
	If Operations = 3 Then
		For Each vRowData In GuestsList Do
			vRowData.Check = True;
		EndDo;
	EndIf;
	OperationVisible();
EndProcedure // OperationsOnChange

// ------------------------------------------------------------------------------
&AtClient
Procedure DateFromOnChange(pItem)
	DateFromOnChangeAtServer(DateFrom, RoomRate);
EndProcedure // DateFromOnChange

// ------------------------------------------------------------------------------
&AtClient
Procedure DateTo1OnChange(pItem)
	DateToOnChangeAtServer(DateFrom, RoomRate);
EndProcedure // DateFrom1OnChange

// ------------------------------------------------------------------------------
&AtClient
Procedure DateFrom2OnChange(pItem)
	DateFromOnChangeAtServer(DateFrom, RoomRate);
EndProcedure

// ------------------------------------------------------------------------------
&AtClient
Procedure DateTo2OnChange(pItem)
	DateToOnChangeAtServer(DateTo, RoomRate);
EndProcedure

// ------------------------------------------------------------------------------
&AtClient
Procedure DateTo3OnChange(pItem)
	DateToOnChangeAtServer(DateTo, RoomRate);
EndProcedure

// ------------------------------------------------------------------------------
&AtClient
Procedure RoomToStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = false;
	OpenForm("Catalog.Rooms.Form.tcChoiceForm", New Structure("Hotel, DateFrom, DateTo, RoomType, RoomQuota, Company, NumberOfRooms", Hotel, DateFrom, DateTo, RoomType, RoomQuota, Company, 1) , pItem);	
EndProcedure

// ------------------------------------------------------------------------------
&AtClient
Procedure BookedOutActionTypeOnChange(pItem)
	If BookOutActionType = 2 Then
		Items.GroupBookOutDates.Enabled = False;
		Items.BookedOutHotel.Enabled = False;
	Else
		Items.GroupBookOutDates.Enabled = True;
		Items.BookedOutHotel.Enabled = True;
	EndIf;
EndProcedure // BookedOutActionTypeOnChange

// ------------------------------------------------------------------------------
&AtClient
Procedure RoomToOnChange(pItem)
	If ValueIsFilled(RoomTo) Then
		RoomToOnChangeAtServer();
	EndIf;
EndProcedure // RoomToOnChange

// ------------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(pItem)
	RoomTypeOnChangeAtServer();
EndProcedure // RoomTypeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------
&AtClient
Procedure ExecuteAction(pCommand)
	// Check attributes
	vThereAreCheckedGuests = False;
	vDocsToProcess = New Array();
	vDocsToPostprocess = New Array();
	For Each vRowData In GuestsList Do
		If ValueIsFilled(vRowData.DocRef) Then
			If vRowData.Check Then
				vThereAreCheckedGuests = True;
				vDocsToProcess.Add(vRowData.DocRef);
			Else
				vDocsToPostprocess.Add(vRowData.DocRef);
			EndIf;
		EndIf;
	EndDo;
	If Not vThereAreCheckedGuests Then
		ShowMessageBox(, NStr("en='There are no guests checked for processing!'; ru='Нет отмеченных гостей!'; de='Es werden keine Gäste zur Bearbeitung markiert!'"));
		Return;
	EndIf;
	If GetAllAccommodationTemplatesCount(Hotel) = 0 Then
		ShowMessageBox(, NStr("en='You have to fill <Accommodation templates> catalog to use this function!'; ru='Для использования этой функции необходимо заполнить справочник <Шаблоны размещения гостей>!'; de='Um diese Funktion nutzen zu können, müssen Sie die <Guest accommodation template> ausfüllen!'"));
		Return;
	EndIf;
	// Check actions parameters
	vThereAreErrors = False;
	If Operations = 0 Then
		If Not ValueIsFilled(DateFrom) Then
			vThereAreErrors = True;
			vUM = New UserMessage();
			vUM.Text = NStr("en='Check-in date should be filled!'; ru='Дата заезда не указана!'; de='Anreise Datum ist nicht angegeben!'");
			vUM.Field = "DateFrom";
			vUM.Message();
		EndIf;
	ElsIf Operations = 1 Then
		If TypeOf(DocRef) = Type("DocumentRef.Accommodation") Then
			If Not ValueIsFilled(RoomTo) Then
				vThereAreErrors = True;
				vUM = New UserMessage();
				vUM.Text = NStr("en='Room should be filled!'; ru='Номер для переселения не указан!'; de='Zimmer sollte gefüllt sein!'");
				vUM.Field = "RoomTo";
				vUM.Message();
			EndIf;
		Else
			If Not ValueIsFilled(RoomTo) And Not ValueIsFilled(RoomType) Then
				vThereAreErrors = True;
				vUM = New UserMessage();
				vUM.Text = NStr("en='Room or rooom type should be filled!'; ru='Номер и тип номера для переселения не указаны!'; de='Zimmer oder Zimmertyp sollte gefüllt sein!'");
				vUM.Field = "RoomType";
				vUM.Message();
			EndIf;
		EndIf;
		If Not ValueIsFilled(DateFrom) Then
			vThereAreErrors = True;
			vUM = New UserMessage();
			vUM.Text = NStr("en='Change room date should be filled!'; ru='Дата переселения не указана!'; de='Datum ist nicht angegeben!'");
			vUM.Field = "DateFrom";
			vUM.Message();
		EndIf;
	ElsIf Operations = 2 Then
		If Not ValueIsFilled(DateFrom) Then
			vThereAreErrors = True;
			vUM = New UserMessage();
			vUM.Text = NStr("en='Check-out date should be filled!'; ru='Дата выселения не указана!'; de='Check-out datum ist nicht angegeben!'");
			vUM.Field = "CheckOutDate";
			vUM.Message();
		EndIf;
		// If all guests are checked, then we have to check user rights for this check-out operation
		If vDocsToPostprocess.Count() = 0 Then
			If TypeOf(DocRef) = Type("DocumentRef.Accommodation") Then
				// Check check-out date and user rights to chnage check-out date
				If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditCheckOutDateTime") Then
					If DateFrom <> (BegOfDay(CurrentDate()) + Hour(CurrentDate())*3600 + Minute(CurrentDate())*60) Then
						vThereAreErrors = True;
						vUM = New UserMessage();
						vUM.Text = NStr("en='You have rights to check-out on current date and time only! Check-out date and time is changed to current ones.'; ru='Есть права на выселение только текущей датой и временем! Дата и время выселения изменены на текущие.'; de='Sie haben das Recht auf abreise Datum nur zum aktuellen Datum und Uhrzeit! Das abreise Datum und die Zeit werden auf aktuell Datum und Zeit geändert.'");
						vUM.Field = "CheckOutDate";
						vUM.Message();
					EndIf;
				EndIf;
				// Give warning if current date is less then expected check-out date
				If BegOfDay(DateFrom) > BegOfDay(CurrentDate()) Then
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Expected check-out date " + Format(DateFrom, "DF=dd.MM.yyyy") + " is in the future!'; 
					             |de='Expected check-out date " + Format(DateFrom, "DF=dd.MM.yyyy") + " is in the future!'; 
					             |ru='Дата планируемого выезда " + Format(DateFrom, "DF=dd.MM.yyyy") + " в будущем!'"));
				EndIf;
				// Check balances for selected accommodations
				vResult = CheckAccommodationsBalances(vDocsToProcess);
				If ValueIsFilled(vResult) Then
					tcOnServer.cmWriteLogEventAtServer(NStr("en='Accommodation.CheckBalances';ru='Размещение.ПроверкаБаланса';de='Accommodation.CheckBalances'"), Undefined, "Documents.Folio", , vResult);
					If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToCheckOutAccommodationsWithClientDebts") Then
						vThereAreErrors = True;
					EndIf;
					vUM = New UserMessage();
					vUM.Text = vResult;
					vUM.Field = "CheckOutDate";
					vUM.Message();
				EndIf;
				// Check user rights to use check-out time specified
				If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetCheckOutDateInThePast") Then
					vAllowedCheckOutDelayTime = 1;
					If ValueIsFilled(tcOnServer.cmGetCurrentUserAttribute()) Then
						vPermissionGroup = tcOnServer.cmGetEmployeePermissionGroupAtServer(tcOnServer.cmGetCurrentUserAttribute());
						If ValueIsFilled(vPermissionGroup) Then
							If tcOnServer.cmGetAttributeByRef(vPermissionGroup, "AllowedCheckOutDelayTime") > 0 Then
								vAllowedCheckOutDelayTime = tcOnServer.cmGetAttributeByRef(vPermissionGroup, "AllowedCheckOutDelayTime");
							EndIf;
						EndIf;
					EndIf;
					vTimeDiff = Round((CurrentDate() - DateFrom)/3600, 3);
					If vTimeDiff > vAllowedCheckOutDelayTime Then
						vThereAreErrors = True;
						vUM = New UserMessage();
						vUM.Text = NStr("ru='Ввели дату и время выселения в прошлом. Есть права на выселение только текущей или будущей датой!';
						                |de='Sie haben ein abreise Datum und Zeit angegeben, das in der Vergangenheit liegt. Sie sind berechtigt, eine Räumung nur am aktuellen oder künftigen Datum vorzunehmen!'; 
						                |en='You have entered check-out date in the past. You have rights to do check-out by current or future dates only!'");
						vUM.Field = "CheckOutDate";
						vUM.Message();
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	ElsIf Operations = 3 Then
		If BookOutActionType = 0 Or BookOutActionType = 1 Then
			If Not ValueIsFilled(DateFrom) Then
				vThereAreErrors = True;
				vUM = New UserMessage();
				vUM.Text = NStr("en='Date from should be filled!'; ru='Дата начала периода не указана!'; de='Das Startdatum des Zeitraums ist nicht angegeben!'");
				vUM.Field = "DateFrom2";
				vUM.Message();
			EndIf;
			If Not ValueIsFilled(DateTo) Then
				vThereAreErrors = True;
				vUM = New UserMessage();
				vUM.Text = NStr("en='Date to should be filled!'; ru='Дата окончания периода не указана!'; de='Das Eindedatum des Zeitraums ist nicht angegeben!'");
				vUM.Field = "DateTo2";
				vUM.Message();
			EndIf;
		EndIf;
	ElsIf Operations = 4 Then
		If Not ValueIsFilled(DateTo) Then
			vThereAreErrors = True;
			vUM = New UserMessage();
			vUM.Text = NStr("en='Date should be filled!'; ru='Дата не указана!'; de='Das Datum ist nicht angegeben!'");
			vUM.Field = "DateTo3";
			vUM.Message();
		EndIf;
	Else
		ShowMessageBox(, NStr("en='Please choose action type!'; ru='Выберите тип действия с гостями!'; de='Wählen Sie einen Aktionstyp mit Gästen!'"));
		Return;
	EndIf;
	// Do processing
	If Not vThereAreErrors Then
		vWarningMessage = "";   
		
		// APDEX
		vKeyOperation = "tcChangeRoomWizard.Posting";   
		vApdexRemarks = New Structure("OperationType, Room, GuestGroup", Items.Operations.ChoiceList.FindByValue(Operations).Presentation, String(Room), String(GuestGroup));
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks); 
		
		vErrorDescription = ExecuteActionAtServer(vDocsToProcess, vDocsToPostprocess, vWarningMessage);
		If Not IsBlankString(vErrorDescription) Then
			ShowMessageBox(, vErrorDescription, , NStr("en='!!! Error !!!'; ru='!!! Ошибка !!!'; de='!!! Fehler !!!'"));
		Else
			// Update open document form
			If TypeOf(DocRef) = Type("DocumentRef.Accommodation") Then
				Notify("Document.Accommodation.Write", DocRef, ThisObject);
			Else
				Notify("Document.Reservation.Write", DocRef, ThisObject);
			EndIf;
			// Close wizard form
			Close();
			// Show warning
			If Not IsBlankString(vWarningMessage) Then
				ShowMessageBox(, vWarningMessage, , NStr("en='Warning'; ru='Предупреждение'; de='Warnung'"));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ExecuteAction

// ------------------------------------------------------------------------------
&AtClient
Procedure SelectAllGuests(pCommand)
	For Each vGuestRow In GuestsList Do
		vGuestRow.Check = True;
	EndDo;
EndProcedure // SelectAllGuests

// ------------------------------------------------------------------------------
&AtClient
Procedure DeselectAllGuests(pCommand)
	For Each vGuestRow In GuestsList Do
		vGuestRow.Check = False;
	EndDo;
EndProcedure // DeselectAllGuests

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetBalancesByGuests(pList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Ref,
	|	Folio.ParentDoc AS ParentDoc,
	|	ISNULL(Customers.IsIndividual, TRUE) AS IsIndividual
	|INTO FolioListByAllGuests
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|WHERE
	|	NOT Folio.DeletionMark
	|	AND Folio.ParentDoc IN(&qList)
	|
	|UNION
	|
	|SELECT
	|	Folio.Ref,
	|	Folio.ParentDoc,
	|	ISNULL(Customers.IsIndividual, TRUE)
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|WHERE
	|	NOT Folio.DeletionMark
	|	AND CAST(Folio.ParentDoc AS Document.Accommodation).ParentDoc IN (&qList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.FolioParentDoc AS DocRef,
	|	SUM(AccountsBalance.ClientSumBalance) AS ClientSumBalance,
	|	SUM(AccountsBalance.ClientLimitBalance) AS ClientLimitBalance,
	|	SUM(AccountsBalance.CustomerSumBalance) AS CustomerSumBalance
	|FROM
	|	(SELECT
	|		FolioListByAllGuests.ParentDoc AS FolioParentDoc,
	|		CASE
	|			WHEN FolioListByAllGuests.IsIndividual
	|				THEN ClientAccountsBalance.SumBalance
	|			ELSE 0
	|		END AS ClientSumBalance,
	|		CASE
	|			WHEN FolioListByAllGuests.IsIndividual
	|				THEN -ClientAccountsBalance.LimitBalance
	|			ELSE 0
	|		END AS ClientLimitBalance,
	|		CASE
	|			WHEN FolioListByAllGuests.IsIndividual
	|				THEN 0
	|			ELSE ClientAccountsBalance.SumBalance
	|		END AS CustomerSumBalance
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				,
	|				FolioCurrency = Hotel.FolioCurrency
	|					AND Folio IN
	|						(SELECT
	|							FolioListByAllGuests.Ref AS Ref
	|						FROM
	|							FolioListByAllGuests AS FolioListByAllGuests)) AS ClientAccountsBalance
	|			INNER JOIN FolioListByAllGuests AS FolioListByAllGuests
	|			ON ClientAccountsBalance.Folio = FolioListByAllGuests.Ref) AS AccountsBalance
	|
	|GROUP BY
	|	AccountsBalance.FolioParentDoc";
	vQry.SetParameter("qList", pList);
	vBalances = vQry.Execute().Select();
	vBalances.Reset();
	Return vBalances;
EndFunction // GetBalancesByGuests

// ------------------------------------------------------------------------------
Procedure OperationVisible()
	If Operations = 0 Then
		Items.GroupOperationsCheckIn.Visible = True;
		Items.GroupOperationsChangeRoom.Visible = False;
		Items.GroupOperationsCheckOut.Visible = False;
		Items.GroupOperationsBookedOut.Visible = False;
		Items.GroupOperationsStayOver.Visible = False;
	ElsIf Operations = 1 Then
		Items.GroupOperationsCheckIn.Visible = False;
		Items.GroupOperationsChangeRoom.Visible = True;
		Items.GroupOperationsCheckOut.Visible = False;
		Items.GroupOperationsBookedOut.Visible = False;
		Items.GroupOperationsStayOver.Visible = False;
		If TypeOf(DocRef) = Type("DocumentRef.Accommodation") Then
			Items.RoomType.ReadOnly = True;
		Else
			Items.RoomType.ReadOnly = False;
		EndIf;
	ElsIf Operations = 2 Then
		Items.GroupOperationsCheckIn.Visible = False;
		Items.GroupOperationsChangeRoom.Visible = False;
		Items.GroupOperationsCheckOut.Visible = True;
		Items.GroupOperationsBookedOut.Visible = False;
		Items.GroupOperationsStayOver.Visible = False;	
	ElsIf Operations = 3 Then
		Items.GroupOperationsCheckIn.Visible = False;
		Items.GroupOperationsChangeRoom.Visible = False;
		Items.GroupOperationsCheckOut.Visible = False;
		Items.GroupOperationsBookedOut.Visible = True;
		Items.GroupOperationsStayOver.Visible = False;
	ElsIf Operations = 4 Then
		Items.GroupOperationsCheckIn.Visible = False;
		Items.GroupOperationsChangeRoom.Visible = False;
		Items.GroupOperationsCheckOut.Visible = False;
		Items.GroupOperationsBookedOut.Visible = False;
		Items.GroupOperationsStayOver.Visible = True;
	Else
		Items.GroupOperationsCheckIn.Visible = False;
		Items.GroupOperationsChangeRoom.Visible = False;
		Items.GroupOperationsCheckOut.Visible = False;
		Items.GroupOperationsBookedOut.Visible = False;
		Items.GroupOperationsStayOver.Visible = False;	
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------
&AtServer
Function GetAccommodationTemplate(pDocsArray, pRoomType, pIsForFolioSplit)
	Return cmGetAccommodationTemplateByDocsArray(pDocsArray, pRoomType, Hotel, pIsForFolioSplit);
EndFunction // GetAccommodationTemplate

// ------------------------------------------------------------------------------
&AtServer
Function ChangeRoomOperationAtServer(pDocsToProcess, pDocsToPostprocess, rWarningMessage = "")
	rWarningMessage = "";
	vErrorDescription = "";
	// Check if this is room split
	vThisIsRoomSplit = False;
	If pDocsToPostprocess.Count() > 0 Then
		vThisIsRoomSplit = True;
	EndIf;
	// Get new room room type
	vRoomToRoomType = RoomType;  
	vBoardPlace = Undefined;
	If ValueIsFilled(RoomTo) Then    
		vBoardPlace = RoomTo.BoardPlace;
		vRoomToRoomType = RoomTo.RoomType;
		vRoomObj = RoomTo.GetObject();
		vRoomAttrs = vRoomObj.pmGetRoomAttributes(DateFrom);
		For Each vRoomAttrsRow In vRoomAttrs Do
			If ValueIsFilled(vRoomAttrsRow.RoomType) Then
				vRoomToRoomType = vRoomAttrsRow.RoomType;
			EndIf; 
			Break;
		EndDo;
	Else
		vRoomToRoomType = RoomType;
	EndIf;
	// Try to get accommodation template for the given new number of guests
	vIsForFolioSplitNew = False;
	If pDocsToProcess.Count() > 0 Then
		vIsForFolioSplitNew = pDocsToProcess.Get(0).IsForFolioSplit;
	EndIf;
	vAccTemplateNew = GetAccommodationTemplate(pDocsToProcess, vRoomToRoomType, vIsForFolioSplitNew);
	// Try to get accommodation template for the guests in the old room
	vIsForFolioSplitOld = False;
	If pDocsToPostprocess.Count() > 0 Then
		vIsForFolioSplitOld = pDocsToPostprocess.Get(0).IsForFolioSplit;
	EndIf;
	If vThisIsRoomSplit Then
		vAccTemplateOld = GetAccommodationTemplate(pDocsToPostprocess, RoomType, vIsForFolioSplitOld);
	EndIf;
	// Do processing
	Try
		BeginTransaction(DataLockControlMode.Managed);
		
		// New room
		vNewDocumentNumber = Undefined;
		
		i = 0;
		vOverrides1 = New ValueTable();
		vOverrides2 = New ValueTable();
		For Each vDoc In pDocsToProcess Do
			// Get document object
			vDocObj = vDoc.GetObject();
			If BegOfDay(vDocObj.CheckInDate) = BegOfDay(DateFrom) Then
				DateFrom = vDocObj.CheckInDate;
			EndIf;
			If BegOfDay(vDocObj.CheckInDate) > BegOfDay(DateFrom) Then
				Raise NStr("en='Check-in date is later then change room date! '; ru='Дата заезда позже даты переселения! '; de='Das Anreisedatum ist nach dem Umsiedlungsdatum angegeben! '") + TrimAll(vDoc);
			EndIf;
			If cm0SecondShift(vDocObj.CheckInDate) > cm0SecondShift(DateFrom) Then
				Raise NStr("en='Check-in date is later then change room date! '; ru='Дата заезда позже даты переселения! '; de='Das Anreisedatum ist nach dem Umsiedlungsdatum angegeben! '") + TrimAll(vDoc);
			EndIf;
			If cm0SecondShift(vDocObj.CheckOutDate) < cm0SecondShift(DateFrom) Then
				Raise NStr("en='Check-out date is earlier then change room date! '; ru='Дата выезда раньше даты переселения! '; de='Das Abreisedatum ist vor dem Umsiedlungsdatum angegeben! '") + TrimAll(vDoc);
			EndIf;
			
			If vThisIsRoomSplit Then
				If vNewDocumentNumber = Undefined Then
					vDocObj.SetNewNumber();
					vNewDocumentNumber = vDocObj.Number;
				Else
					vDocObj.Number = vNewDocumentNumber;
				EndIf;
			EndIf;

			vDoRecalculateResources = False;
			
			vRRRow = vDocObj.RoomRates.Find(BegOfDay(vDocObj.CheckInDate), "AccountingDate");
			If vRRRow = Undefined Then
				vRRRow = vDocObj.RoomRates.Add();
				vRRRow.AccountingDate = BegOfDay(vDocObj.CheckInDate);
				vRRRow.Room = vDocObj.Room;
				vRRRow.RoomType = vDocObj.RoomType;
				vRRRow.AccommodationType = vDocObj.AccommodationType; 
				vRRRow.BoardPlace = vDocObj.BoardPlace;
				If i = 0 Then
					vRRRow.AccommodationTemplate = ?(ValueIsFilled(vDocObj.AccommodationTemplate), vDocObj.AccommodationTemplate, Catalogs.AccommodationTemplates.NoTemplate);
				EndIf;
			Else
				If Not ValueIsFilled(vRRRow.Room) Then
					vRRRow.Room = vDocObj.Room;
				EndIf;
				If Not ValueIsFilled(vRRRow.RoomType) Then
					vRRRow.RoomType = vDocObj.RoomType;
				EndIf;
				If Not ValueIsFilled(vRRRow.AccommodationType) Then
					vRRRow.AccommodationType = vDocObj.AccommodationType;
				EndIf;  
				If Not ValueIsFilled(vRRRow.BoardPlace) Then
					vRRRow.BoardPlace = vDocObj.BoardPlace;
				EndIf;
				If i = 0 Then
					vRRRow.AccommodationTemplate = ?(ValueIsFilled(vDocObj.AccommodationTemplate), vDocObj.AccommodationTemplate, Catalogs.AccommodationTemplates.NoTemplate);
				EndIf;
			EndIf;
			
			vRRRow = vDocObj.RoomRates.Find(BegOfDay(DateFrom), "AccountingDate");
			If vRRRow = Undefined Then
				vRRRow = vDocObj.RoomRates.Add();
				vRRRow.AccountingDate = BegOfDay(DateFrom);
			EndIf;
			vRRRow.ChangeTime = '00010101' + (DateFrom - BegOfDay(DateFrom));
			vRRRow.Room = RoomTo;
			vRRRow.RoomType = vRoomToRoomType; 
			vRRRow.BoardPlace = vBoardPlace;
			If ValueIsFilled(vAccTemplateNew) Then
				If vAccTemplateNew.IsForFolioSplit = vIsForFolioSplitNew Then
					If vAccTemplateNew.AccommodationTypes.Count() > i Then
						vRRRow.AccommodationType = vAccTemplateNew.AccommodationTypes.Get(i).AccommodationType;
						If vOverrides1.Columns.Count() = 0 Then
							vOverrides1 = cmGetRoomRateOverrides(?(ValueIsFilled(vRRRow.RoomRate), vRRRow.RoomRate, vDocObj.RoomRate), vDocObj.Hotel, vAccTemplateNew, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, ?(ValueIsFilled(vRRRow.RoomType), vRRRow.RoomType, vDocObj.RoomType)));
						EndIf;
						If vOverrides1.Count() > 0 Then
							vOverrideRows = vOverrides1.FindRows(New Structure("AccommodationType, TemplateLineNumber", vRRRow.AccommodationType, i + 1));
							If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
								vRRRow.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				If i = 0 Then
					vRRRow.AccommodationTemplate = vAccTemplateNew;
				EndIf;
			EndIf;
			vRRRow.DoNotChangeAvailability = DoNotChangeAvailability;
			
			vDocObj.RoomRates.Sort("AccountingDate, ChangeTime");
			
			// Update main document attributes if this change is today
			If BegOfDay(DateFrom) <= BegOfDay(CurrentSessionDate()) Then
				vDocObj.Room = RoomTo;
				vDocObj.RoomType = vRoomToRoomType;
				If ValueIsFilled(vAccTemplateNew) Then
					If vAccTemplateNew.IsForFolioSplit = vIsForFolioSplitNew Then
						If vAccTemplateNew.AccommodationTypes.Count() > i Then
							vDocObj.AccommodationType = vAccTemplateNew.AccommodationTypes.Get(i).AccommodationType;
							If vOverrides2.Columns.Count() = 0 Then
								vOverrides2 = cmGetRoomRateOverrides(vDocObj.RoomRate, vDocObj.Hotel, vAccTemplateNew, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, vDocObj.RoomType));
							EndIf;
							If vOverrides2.Count() > 0 Then
								vOverrideRows = vOverrides2.FindRows(New Structure("AccommodationType, TemplateLineNumber", vDocObj.AccommodationType, i + 1));
								If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
									vDocObj.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If i = 0 Then
						vDocObj.AccommodationTemplate = vAccTemplateNew;
					EndIf;
				EndIf;
				vDoRecalculateResources = True;
			EndIf;
			
			// Recalculate resources
			If vDoRecalculateResources Then
				vDocObj.pmCalculateResources();
			EndIf;
			
			// Recalculate services
			vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
			
			// Save document
			vDocObj.AdditionalProperties.Insert("CheckFolioDebts", False);
			vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
			vDocObj.Write(DocumentWriteMode.Posting);
			
			// Go to the next document
			i = i + 1;
		EndDo;
		
		// Old room
		If vThisIsRoomSplit Then
			vIsFirstDoc = True;
			
			i = 0;
			vOverrides1 = New ValueTable();
			vOverrides2 = New ValueTable();
			For Each vDoc In pDocsToPostprocess Do
				// Get document object
				vDocObj = vDoc.GetObject();
				If vDocObj.CheckInDate > DateFrom Then
					Raise NStr("en='Check-in date is later then change room date! '; ru='Дата заезда позже даты переселения! '; de='Das Anreisedatum ist nach dem Umsiedlungsdatum angegeben! '") + TrimAll(vDoc);
				EndIf;
				If vDocObj.CheckOutDate < DateFrom Then
					Raise NStr("en='Check-out date is earlier then change room date! '; ru='Дата выезда раньше даты переселения! '; de='Das Abreisedatum ist vor dem Umsiedlungsdatum angegeben! '") + TrimAll(vDoc);
				EndIf;

				vDoRecalculateResources = False;
				
				vRRRow = vDocObj.RoomRates.Find(BegOfDay(vDocObj.CheckInDate), "AccountingDate");
				If vRRRow = Undefined Then
					vRRRow = vDocObj.RoomRates.Add();
					vRRRow.AccountingDate = BegOfDay(vDocObj.CheckInDate);
					vRRRow.AccommodationType = vDocObj.AccommodationType;
				ElsIf Not ValueIsFilled(vRRRow.AccommodationType) Then 
					vRRRow.AccommodationType = vDocObj.AccommodationType;
				EndIf;
				If vIsFirstDoc Then
					vRRRow.AccommodationTemplate = ?(ValueIsFilled(vDocObj.AccommodationTemplate), vDocObj.AccommodationTemplate, Catalogs.AccommodationTemplates.NoTemplate);
				EndIf;
				
				vRRRow = vDocObj.RoomRates.Find(BegOfDay(DateFrom), "AccountingDate");
				If vRRRow = Undefined Then
					vRRRow = vDocObj.RoomRates.Add();
					vRRRow.AccountingDate = BegOfDay(DateFrom);
				EndIf;
				vRRRow.ChangeTime = '00010101' + (DateFrom - BegOfDay(DateFrom));
				If ValueIsFilled(vAccTemplateOld) Then
					If vAccTemplateOld.IsForFolioSplit = vIsForFolioSplitOld Then
						If vAccTemplateOld.AccommodationTypes.Count() > i Then
							vRRRow.AccommodationType = vAccTemplateOld.AccommodationTypes.Get(i).AccommodationType;
							If vOverrides1.Columns.Count() = 0 Then
								vOverrides1 = cmGetRoomRateOverrides(?(ValueIsFilled(vRRRow.RoomRate), vRRRow.RoomRate, vDocObj.RoomRate), vDocObj.Hotel, vAccTemplateOld, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, ?(ValueIsFilled(vRRRow.RoomType), vRRRow.RoomType, vDocObj.RoomType)));
							EndIf;
							If vOverrides1.Count() > 0 Then
								vOverrideRows = vOverrides1.FindRows(New Structure("AccommodationType, TemplateLineNumber", vRRRow.AccommodationType, i + 1));
								If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
									vRRRow.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If vIsFirstDoc Then
						vRRRow.AccommodationTemplate = vAccTemplateOld;
					EndIf;
				EndIf;
				
				vDocObj.RoomRates.Sort("AccountingDate, ChangeTime");
				
				// Update main document attributes if this change is today
				If BegOfDay(DateFrom) = BegOfDay(CurrentSessionDate()) Then
					If ValueIsFilled(vAccTemplateOld) And vAccTemplateOld.IsForFolioSplit = vIsForFolioSplitOld Then
						If vAccTemplateOld.AccommodationTypes.Count() > i Then
							vDocObj.AccommodationType = vAccTemplateOld.AccommodationTypes.Get(i).AccommodationType;
							If vOverrides2.Columns.Count() = 0 Then
								vOverrides2 = cmGetRoomRateOverrides(vDocObj.RoomRate, vDocObj.Hotel, vAccTemplateOld, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, vDocObj.RoomType));
							EndIf;
							If vOverrides2.Count() > 0 Then
								vOverrideRows = vOverrides2.FindRows(New Structure("AccommodationType, TemplateLineNumber", vDocObj.AccommodationType, i + 1));
								If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
									vDocObj.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
							vDoRecalculateResources = True;
						EndIf;
					EndIf;
				EndIf;

				// Recalculate resources
				If vDoRecalculateResources Then
					vDocObj.pmCalculateResources();
				EndIf;
				
				// Recalculate services
				vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
				
				// Save document
				vDocObj.AdditionalProperties.Insert("CheckFolioDebts", False);
				vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
				vDocObj.Write(DocumentWriteMode.Posting);
				
				// Go to the next document
				vIsFirstDoc = False;
				i = i + 1;
			EndDo;
		EndIf;
		
		// Check processing results
		For Each vDoc In pDocsToProcess Do
			vDocObj = vDoc.GetObject();
			vDocObj.AdditionalProperties.Insert("WarningMessage", "");
			// Build value table of accommodation periods
			vPeriods = vDocObj.pmGetAccommodationPeriods(True);
			// Process each accommodation period separately
			vCancel = False;
			For Each vPeriodsRow In vPeriods Do
				vMessage = ""; vAttributeInErr = "";
				vCancel	= vDocObj.pmCheckDocumentAttributes(vPeriodsRow, vDocObj.Posted, vMessage, vAttributeInErr, False, True);
				If vCancel Then
					WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, vDocObj.Metadata(), vDocObj.Ref, NStr(vMessage));
					Raise String(vDocObj.Ref) + " - " + NStr(vMessage);
				Else
					If Not IsBlankString(vDocObj.AdditionalProperties.WarningMessage) Then
						rWarningMessage = rWarningMessage + ?(IsBlankString(rWarningMessage), "", Chars.LF + Chars.LF) + TrimAll(vDocObj.AdditionalProperties.WarningMessage);
					EndIf;
				EndIf;
			EndDo;
			If Not vCancel Then
				If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
					vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				Else
					vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndDo;

		For Each vDoc In pDocsToPostprocess Do
			vDocObj = vDoc.GetObject();
			vDocObj.AdditionalProperties.Insert("WarningMessage", "");
			// Build value table of accommodation periods
			vPeriods = vDocObj.pmGetAccommodationPeriods(True);
			// Process each accommodation period separately
			vCancel = False;
			For Each vPeriodsRow In vPeriods Do
				vMessage = ""; vAttributeInErr = ""; 
				vCancel	= vDocObj.pmCheckDocumentAttributes(vPeriodsRow, vDocObj.Posted, vMessage, vAttributeInErr, False, True);
				If vCancel Then
					WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, vDocObj.Metadata(), vDocObj.Ref, NStr(vMessage));
					Raise String(vDocObj.Ref) + " - " + NStr(vMessage);
				Else
					If Not IsBlankString(vDocObj.AdditionalProperties.WarningMessage) Then
						rWarningMessage = rWarningMessage + ?(IsBlankString(rWarningMessage), "", Chars.LF + Chars.LF) + TrimAll(vDocObj.AdditionalProperties.WarningMessage);
					EndIf;
				EndIf;
			EndDo;
			If Not vCancel Then
				If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
					vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				Else
					vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndDo;
		
		// Commit all changes
		CommitTransaction();
	Except
		vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	Return vErrorDescription;
EndFunction // ChangeRoomOperationAtServer

// ------------------------------------------------------------------------------
&AtServer
Function CheckInOperationAtServer(pDocsToProcess, pDocsToPostprocess, rWarningMessage = "")
	rWarningMessage = "";
	vErrorDescription = "";
	// We have to define if checked guests will check-in earlier or later then guests left unchecked
	vEarlier = False;
	vOldCheckInDate = '00010101';
	If pDocsToPostprocess.Count() > 0 Then
		For Each vDoc In pDocsToPostprocess Do
			If cm0SecondShift(DateFrom) < cm0SecondShift(vDoc.CheckInDate) Then
				vOldCheckInDate = cm1SecondShift(vDoc.CheckInDate);
				vEarlier = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	// Build array of all accommodations in room
	vAllDocs = New Array();
	For Each vGuestsRow In GuestsList Do
		vAllDocs.Add(vGuestsRow.DocRef);
	EndDo;
	
	// Do processing
	Try
		BeginTransaction(DataLockControlMode.Managed);
		
		If vEarlier Then
			// Try to get accommodation template for the checked guests
			vIsForFolioSplitNew = False;
			If pDocsToProcess.Count() > 0 Then
				vIsForFolioSplitNew = pDocsToProcess.Get(0).IsForFolioSplit;
			EndIf;
			vAccTemplateNew = GetAccommodationTemplate(pDocsToProcess, RoomType, vIsForFolioSplitNew);
			// Try to get accommodation template for the guests all guests
			vIsForFolioSplitOld = False;
			If vAllDocs.Count() > 0 Then
				vIsForFolioSplitOld = vAllDocs.Get(0).IsForFolioSplit;
			EndIf;
			vAccTemplateOld = GetAccommodationTemplate(vAllDocs, RoomType, vIsForFolioSplitOld);
			
			// Process guests with new check-in date
			i = 0;
			vOverrides = New ValueTable();
			vOldOverrides = New ValueTable();
			While i < pDocsToProcess.Count() Do
				vDoc = pDocsToProcess.Get(i);
				
				// Get document object
				vDocObj = vDoc.GetObject();
				If cm0SecondShift(vDocObj.CheckOutDate) <= cm0SecondShift(DateFrom) Then
					Raise NStr("en='Check-in date is later or equal to the check-out date! '; ru='Дата заезда позже или равна дате выселения! '; de='Das Anreisedatum ist nach dem Abreisedatum angegeben! '") + TrimAll(vDoc);
				EndIf;

				vDoRecalculateResources = False;
				
				// Change check-in date
				vDocObj.CheckInDate = cm1SecondShift(DateFrom);
				vDocObj.Duration = vDocObj.pmCalculateDuration();
				
				// Template
				If i = 0 Then
					If ValueIsFilled(vAccTemplateNew) Then
						vDocObj.AccommodationTemplate = vAccTemplateNew;
					EndIf;
				Else
					vDocObj.AccommodationTemplate = Undefined;
				EndIf;
				
				// Accommodation type
				If ValueIsFilled(vAccTemplateNew) And vAccTemplateNew.IsForFolioSplit = vIsForFolioSplitNew Then
					If vAccTemplateNew.AccommodationTypes.Count() > i Then
						vDocObj.AccommodationType = vAccTemplateNew.AccommodationTypes.Get(i).AccommodationType;
						If vOverrides.Columns.Count() = 0 Then
							vOverrides = cmGetRoomRateOverrides(vDocObj.RoomRate, vDocObj.Hotel, vAccTemplateNew, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, vDocObj.RoomType));
						EndIf;
						If vOverrides.Count() > 0 Then
							vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vDocObj.AccommodationType, i + 1));
							If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
								vDocObj.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
							EndIf;
						EndIf;
						vDoRecalculateResources = True;
					EndIf;
				EndIf;
				
				// Changes for old check-in date
				If pDocsToPostprocess.Count() > 0 Then
					vRRRow = vDocObj.RoomRates.Find(BegOfDay(vOldCheckInDate), "AccountingDate");
					If vRRRow = Undefined Then
						vRRRow = vDocObj.RoomRates.Add();
						vRRRow.AccountingDate = BegOfDay(vOldCheckInDate);
					EndIf;
					
					If ValueIsFilled(vAccTemplateOld) And vAccTemplateOld.IsForFolioSplit = vIsForFolioSplitOld Then
						If vAccTemplateOld.AccommodationTypes.Count() > i Then
							vRRRow.AccommodationType = vAccTemplateOld.AccommodationTypes.Get(i).AccommodationType;
							If vOldOverrides.Columns.Count() = 0 Then
								vOldOverrides = cmGetRoomRateOverrides(?(ValueIsFilled(vRRRow.RoomRate), vRRRow.RoomRate, vDocObj.RoomRate), vDocObj.Hotel, vAccTemplateOld, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, ?(ValueIsFilled(vRRRow.RoomType), vRRRow.RoomType, vDocObj.RoomType)));
							EndIf;
							If vOldOverrides.Count() > 0 Then
								vOverrideRows = vOldOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vRRRow.AccommodationType, i + 1));
								If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
									vRRRow.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
						
					If i = 0 Then
						If ValueIsFilled(vAccTemplateOld) Then
							vDocObj.AccommodationTemplate = vAccTemplateOld;
						EndIf;
					Else
						vRRRow.AccommodationTemplate = Undefined;
					EndIf;
					
					vDocObj.RoomRates.Sort("AccountingDate, ChangeTime");
				EndIf;
				
				// Update price calculation dates if necessary
				vDocObj.pmUpdatePriceCalculationDate();

				// Recalculate resources
				If vDoRecalculateResources Then
					vDocObj.pmCalculateResources();
				EndIf;
				
				// Recalculate services
				vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
				
				// Save changes
				vDocObj.AdditionalProperties.Insert("CheckFolioDebts", False);
				vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
				vDocObj.Write(DocumentWriteMode.Posting);
				
				// Go to the next document
				i = i + 1;
			EndDo;
			
			// Process guests with old check-in date
			i = 0;
			vOverrides = New ValueTable();
			While i < pDocsToPostprocess.Count() Do
				vDoc = pDocsToPostprocess.Get(i);
				
				// Get document object
				vDocObj = vDoc.GetObject();
				
				vDoRecalculateResources = False;
				
				// Accommodation type
				If ValueIsFilled(vAccTemplateOld) And vAccTemplateOld.IsForFolioSplit = vIsForFolioSplitOld Then
					If vAccTemplateOld.AccommodationTypes.Count() > (i + pDocsToProcess.Count()) Then
						vDocObj.AccommodationType = vAccTemplateOld.AccommodationTypes.Get(i + pDocsToProcess.Count()).AccommodationType;
						If vOverrides.Columns.Count() = 0 Then
							vOverrides = cmGetRoomRateOverrides(vDocObj.RoomRate, vDocObj.Hotel, vAccTemplateOld, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, vDocObj.RoomType));
						EndIf;
						If vOverrides.Count() > 0 Then
							vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vDocObj.AccommodationType, i + 1));
							If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
								vDocObj.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
							EndIf;
						EndIf;
						vDoRecalculateResources = True;
					EndIf;
				EndIf;
				
				// Template
				vDocObj.AccommodationTemplate = Undefined;

				// Recalculate resources
				If vDoRecalculateResources Then
					vDocObj.pmCalculateResources();
				EndIf;
				
				// Recalculate services
				vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
				
				// Save document
				vDocObj.AdditionalProperties.Insert("CheckFolioDebts", False);
				vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
				vDocObj.Write(DocumentWriteMode.Posting);
				
				// Go to the next document
				i = i + 1;
			EndDo;
		Else
			// Try to get accommodation template for the checked guests
			vIsForFolioSplitOld = False;
			If pDocsToPostprocess.Count() > 0 Then
				vIsForFolioSplitOld = pDocsToPostprocess.Get(0).IsForFolioSplit;
				vAccTemplateOld = GetAccommodationTemplate(pDocsToPostprocess, RoomType, vIsForFolioSplitOld);
			Else
				vAccTemplateOld = GetAccommodationTemplate(vAllDocs, RoomType, vIsForFolioSplitOld);
			EndIf;
			
			// Try to get accommodation template for the all guests
			vIsForFolioSplitNew = False;
			If vAllDocs.Count() > 0 Then
				vIsForFolioSplitNew = vAllDocs.Get(0).IsForFolioSplit;
			EndIf;
			vAccTemplateNew = GetAccommodationTemplate(vAllDocs, RoomType, vIsForFolioSplitNew);
			
			// Process guests with old check-in date
			i = 0;
			vOverrides = New ValueTable();
			vNewOverrides = New ValueTable();
			While i < pDocsToPostprocess.Count() Do
				vDoc = pDocsToPostprocess.Get(i);
				
				// Get document object
				vDocObj = vDoc.GetObject();
				
				vDoRecalculateResources = False;
				
				// Template
				If i = 0 Then
					If ValueIsFilled(vAccTemplateOld) Then
						vDocObj.AccommodationTemplate = vAccTemplateOld;
					EndIf;
				Else
					vDocObj.AccommodationTemplate = Undefined;
				EndIf;
				
				// Accommodation type
				If ValueIsFilled(vAccTemplateOld) And vAccTemplateOld.IsForFolioSplit = vIsForFolioSplitOld Then
					If vAccTemplateOld.AccommodationTypes.Count() > i Then
						vDocObj.AccommodationType = vAccTemplateOld.AccommodationTypes.Get(i).AccommodationType;
						If vOverrides.Columns.Count() = 0 Then
							vOverrides = cmGetRoomRateOverrides(vDocObj.RoomRate, vDocObj.Hotel, vAccTemplateOld, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, vDocObj.RoomType));
						EndIf;
						If vOverrides.Count() > 0 Then
							vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vDocObj.AccommodationType, i + 1));
							If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
								vDocObj.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
							EndIf;
						EndIf;
						vDoRecalculateResources = True;
					EndIf;
				EndIf;
				
				// Changes for old check-in date
				If pDocsToProcess.Count() > 0 Then
					vRRRow = vDocObj.RoomRates.Find(BegOfDay(DateFrom), "AccountingDate");
					If vRRRow = Undefined Then
						vRRRow = vDocObj.RoomRates.Add();
						vRRRow.AccountingDate = BegOfDay(DateFrom);
					EndIf;
					
					If ValueIsFilled(vAccTemplateNew) And vAccTemplateNew.IsForFolioSplit = vIsForFolioSplitNew Then
						If vAccTemplateNew.AccommodationTypes.Count() > i Then
							vRRRow.AccommodationType = vAccTemplateNew.AccommodationTypes.Get(i).AccommodationType;
							If vNewOverrides.Columns.Count() = 0 Then
								vNewOverrides = cmGetRoomRateOverrides(?(ValueIsFilled(vRRRow.RoomRate), vRRRow.RoomRate, vDocObj.RoomRate), vDocObj.Hotel, vAccTemplateNew, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, ?(ValueIsFilled(vRRRow.RoomType), vRRRow.RoomType, vDocObj.RoomType)));
							EndIf;
							If vNewOverrides.Count() > 0 Then
								vOverrideRows = vNewOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vRRRow.AccommodationType, i + 1));
								If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
									vRRRow.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
						
					If i = 0 Then
						If ValueIsFilled(vAccTemplateNew) Then
							vDocObj.AccommodationTemplate = vAccTemplateNew;
						EndIf;
					Else
						vRRRow.AccommodationTemplate = Undefined;
					EndIf;
					
					vDocObj.RoomRates.Sort("AccountingDate, ChangeTime");
				EndIf;

				// Recalculate resources
				If vDoRecalculateResources Then
					vDocObj.pmCalculateResources();
				EndIf;
				
				// Recalculate services
				vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
				
				// Save changes
				vDocObj.AdditionalProperties.Insert("CheckFolioDebts", False);
				vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
				vDocObj.Write(DocumentWriteMode.Posting);
				
				// Go to the next document
				i = i + 1;
			EndDo;
			
			// Process guests with new check-in date
			i = 0;
			vOverrides = New ValueTable();
			While i < pDocsToProcess.Count() Do
				vDoc = pDocsToProcess.Get(i);
				
				// Get document object
				vDocObj = vDoc.GetObject();

				vDoRecalculateResources = False;
				
				// Change check-in date
				vDocObj.CheckInDate = cm1SecondShift(DateFrom);
				vDocObj.Duration = vDocObj.pmCalculateDuration();
				
				If pDocsToPostprocess.Count() > 0 Then
					// Accommodation type
					If ValueIsFilled(vAccTemplateNew) And vAccTemplateNew.IsForFolioSplit = vIsForFolioSplitNew Then
						If vAccTemplateNew.AccommodationTypes.Count() > (i + pDocsToPostprocess.Count()) Then
							vDocObj.AccommodationType = vAccTemplateNew.AccommodationTypes.Get(i + pDocsToPostprocess.Count()).AccommodationType;
							If vOverrides.Columns.Count() = 0 Then
								vOverrides = cmGetRoomRateOverrides(vDocObj.RoomRate, vDocObj.Hotel, vAccTemplateNew, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, vDocObj.RoomType));
							EndIf;
							If vOverrides.Count() > 0 Then
								vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vDocObj.AccommodationType, i + 1));
								If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
									vDocObj.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
							vDoRecalculateResources = True;
						EndIf;
					EndIf;
					
					// Template
					vDocObj.AccommodationTemplate = Undefined;
				EndIf;
				
				// Update price calculation dates if necessary
				vDocObj.pmUpdatePriceCalculationDate();

				// Recalculate resources
				If vDoRecalculateResources Then
					vDocObj.pmCalculateResources();
				EndIf;
				
				// Recalculate services
				vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
				
				// Save document
				vDocObj.AdditionalProperties.Insert("CheckFolioDebts", False);
				vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
				vDocObj.Write(DocumentWriteMode.Posting);
				
				// Go to the next document
				i = i + 1;
			EndDo;
		EndIf;

		// Check operation results		
		For Each vDoc In pDocsToProcess Do
			vDocObj = vDoc.GetObject();
			vDocObj.AdditionalProperties.Insert("WarningMessage", "");
			// Build value table of accommodation periods
			vPeriods = vDocObj.pmGetAccommodationPeriods(True);
			// Process each accommodation period separately
			vCancel = False;
			For Each vPeriodsRow In vPeriods Do
				vMessage = ""; vAttributeInErr = ""; 
				vCancel	= vDocObj.pmCheckDocumentAttributes(vPeriodsRow, vDocObj.Posted, vMessage, vAttributeInErr, False, True);
				If vCancel Then
					WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, vDocObj.Metadata(), vDocObj.Ref, NStr(vMessage));
					Raise String(vDocObj.Ref) + " - " + NStr(vMessage);
				Else
					If Not IsBlankString(vDocObj.AdditionalProperties.WarningMessage) Then
						rWarningMessage = rWarningMessage + ?(IsBlankString(rWarningMessage), "", Chars.LF + Chars.LF) + TrimAll(vDocObj.AdditionalProperties.WarningMessage);
					EndIf;
				EndIf;
			EndDo;
			If Not vCancel Then
				vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
		EndDo;
		
		For Each vDoc In pDocsToPostprocess Do
			vDocObj = vDoc.GetObject();
			vDocObj.AdditionalProperties.Insert("WarningMessage", "");
			// Build value table of accommodation periods
			vPeriods = vDocObj.pmGetAccommodationPeriods(True);
			// Process each accommodation period separately
			vCancel = False;
			For Each vPeriodsRow In vPeriods Do
				vMessage = ""; vAttributeInErr = ""; 
				vCancel	= vDocObj.pmCheckDocumentAttributes(vPeriodsRow, vDocObj.Posted, vMessage, vAttributeInErr, False, True);
				If vCancel Then
					WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, vDocObj.Metadata(), vDocObj.Ref, NStr(vMessage));
					Raise String(vDocObj.Ref) + " - " + NStr(vMessage);
				Else
					If Not IsBlankString(vDocObj.AdditionalProperties.WarningMessage) Then
						rWarningMessage = rWarningMessage + ?(IsBlankString(rWarningMessage), "", Chars.LF + Chars.LF) + TrimAll(vDocObj.AdditionalProperties.WarningMessage);
					EndIf;
				EndIf;
			EndDo;
			If Not vCancel Then
				vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
		EndDo;

		// Commit all changes
		CommitTransaction();
	Except
		vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	Return vErrorDescription;
EndFunction // CheckInOperationAtServer

// ------------------------------------------------------------------------------
&AtServer
Function CheckOutOperationAtServer(pDocsToProcess, pDocsToPostprocess, rWarningMessage = "")
	rWarningMessage = "";
	vErrorDescription = "";

	vAccTemplateOld = Undefined;
	vIsForFolioSplitOld = False;
	If pDocsToPostprocess.Count() > 0 Then
		// All docs left in the room should have check-out date later or equal to the current check-out date
		i = 0;
		While i < pDocsToPostprocess.Count() Do
			vDoc = pDocsToPostprocess.Get(i);
			If TypeOf(vDoc) = Type("DocumentRef.Accommodation") Then
				If ValueIsFilled(vDoc.AccommodationStatus) And 
				  (Not vDoc.AccommodationStatus.IsActive Or Not vDoc.AccommodationStatus.IsInHouse) Then
					pDocsToPostprocess.Delete(i);
					Continue;
				EndIf;
			EndIf;
			If cm0SecondShift(vDoc.CheckOutDate) <= cm0SecondShift(DateFrom) Then
				pDocsToPostprocess.Delete(i);
				Continue;
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;

	// Try to get accommodation template for the not changing guests
	If pDocsToPostprocess.Count() > 0 Then
		vIsForFolioSplitOld = pDocsToPostprocess.Get(0).IsForFolioSplit;
		vAccTemplateOld = GetAccommodationTemplate(pDocsToPostprocess, RoomType, vIsForFolioSplitOld);
	EndIf;
	
	// Do processing
	Try
		If pDocsToPostprocess.Count() > 0 Then
			BeginTransaction(DataLockControlMode.Managed);
		EndIf;
		
		For Each vDoc In pDocsToProcess Do
			// Get document object
			vDocObj = vDoc.GetObject();
			If cm0SecondShift(vDocObj.CheckInDate) >= cm0SecondShift(DateFrom) Then
				Raise NStr("en='Check-in date is later or equal to the check-out date! '; ru='Дата заезда позже или равна дате выселения! '; de='Das Anreisedatum ist nach dem Abreisedatum angegeben! '") + TrimAll(vDoc);
			EndIf;
			
			// Do processing
			vDoCheckOut = False;
			If TypeOf(vDocObj) = Type("DocumentObject.Reservation") Then
				// This is not real check-out. It is change of planned check-out date
				If cm0SecondShift(vDocObj.CheckOutDate) <> cm0SecondShift(DateFrom) Then
					vDocObj.CheckOutDate = cm0SecondShift(DateFrom);
					vDocObj.Duration = vDocObj.pmCalculateDuration();
					
					// Update price calculation dates if necessary
					vDocObj.pmUpdatePriceCalculationDate();

					// Recalculate services
					vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
				EndIf;
			Else
				If BegOfDay(DateFrom) > BegOfDay(CurrentSessionDate()) Then
					// This is not real check-out. It is change of planned check-out date
					If cm0SecondShift(vDocObj.CheckOutDate) <> cm0SecondShift(DateFrom) Then
						vDocObj.CheckOutDate = cm0SecondShift(DateFrom);
						vDocObj.Duration = vDocObj.pmCalculateDuration();
						
						// Update price calculation dates if necessary
						vDocObj.pmUpdatePriceCalculationDate();

						// Recalculate services
						vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
					EndIf;
				Else
					vDoCheckOut = True;
					// Do real check-out
					vDocObj.pmCheckOut(DateFrom, , vDocObj.IsForFolioSplit);
				EndIf;
			EndIf;
			
			// Save changes
			vDocObj.AdditionalProperties.Insert("CheckFolioDebts", False);
			vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
			vDocObj.Write(DocumentWriteMode.Posting);
			If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
				// Hide client name data if necessary
				vDocObj.pmHideClientNameAndNameHistory();
			EndIf;
		EndDo;
		
		// Guests left in the room
		If pDocsToPostprocess.Count() > 0 Then
			i = 0;
			vOverrides1 = New ValueTable();
			vOverrides2 = New ValueTable();
			For Each vDoc In pDocsToPostprocess Do
				vDocObj = vDoc.GetObject();
				If cm0SecondShift(vDocObj.CheckInDate) > cm0SecondShift(DateFrom) Then
					Raise NStr("en='Check-in date is later then check-out date! '; ru='Дата заезда позже даты выселения! '; de='Das Anreisedatum ist nach dem Abreisedatum angegeben! '") + TrimAll(vDoc);
				EndIf;
				If cm0SecondShift(vDocObj.CheckOutDate) <= cm0SecondShift(DateFrom) Then
					// Save document
					vDocObj.AdditionalProperties.Insert("CheckFolioDebts", False);
					vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
					vDocObj.Write(DocumentWriteMode.Posting);
					
					// Go to the next document
					i = i + 1;
					Continue;
				EndIf;

				vDoRecalculateResources = False;
				
				vRRRow = vDocObj.RoomRates.Find(BegOfDay(vDocObj.CheckInDate), "AccountingDate");
				If vRRRow = Undefined Then
					vRRRow = vDocObj.RoomRates.Add();
					vRRRow.AccountingDate = BegOfDay(vDocObj.CheckInDate);
					vRRRow.AccommodationType = vDocObj.AccommodationType;
				ElsIf Not ValueIsFilled(vRRRow.AccommodationType) Then 
					vRRRow.AccommodationType = vDocObj.AccommodationType;
				EndIf;
				vRRRow.AccommodationTemplate = ?(ValueIsFilled(vDocObj.AccommodationTemplate), vDocObj.AccommodationTemplate, Catalogs.AccommodationTemplates.NoTemplate);
				
				vRRRow = vDocObj.RoomRates.Find(BegOfDay(DateFrom), "AccountingDate");
				If vRRRow = Undefined Then
					vRRRow = vDocObj.RoomRates.Add();
					vRRRow.AccountingDate = BegOfDay(DateFrom);
				EndIf;
				vRRRow.ChangeTime = '00010101' + (DateFrom - BegOfDay(DateFrom));
				If ValueIsFilled(vAccTemplateOld) Then
					If vAccTemplateOld.IsForFolioSplit = vIsForFolioSplitOld Then
						If vAccTemplateOld.AccommodationTypes.Count() > i Then
							vRRRow.AccommodationType = vAccTemplateOld.AccommodationTypes.Get(i).AccommodationType;
							If vOverrides1.Columns.Count() = 0 Then
								vOverrides1 = cmGetRoomRateOverrides(?(ValueIsFilled(vRRRow.RoomRate), vRRRow.RoomRate, vDocObj.RoomRate), vDocObj.Hotel, vAccTemplateOld, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, ?(ValueIsFilled(vRRRow.RoomType), vRRRow.RoomType, vDocObj.RoomType)));
							EndIf;
							If vOverrides1.Count() > 0 Then
								vOverrideRows = vOverrides1.FindRows(New Structure("AccommodationType, TemplateLineNumber", vRRRow.AccommodationType, i + 1));
								If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
									vRRRow.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If i = 0 Then
						vRRRow.AccommodationTemplate = vAccTemplateOld;
					EndIf;
				EndIf;
				
				vDocObj.RoomRates.Sort("AccountingDate, ChangeTime");
				
				// Update main document attributes if this change is today
				If BegOfDay(DateFrom) = BegOfDay(CurrentSessionDate()) Then
					If ValueIsFilled(vAccTemplateOld) And vAccTemplateOld.IsForFolioSplit = vIsForFolioSplitOld Then
						If vAccTemplateOld.AccommodationTypes.Count() > i Then
							vDocObj.AccommodationType = vAccTemplateOld.AccommodationTypes.Get(i).AccommodationType;
							If vOverrides2.Columns.Count() = 0 Then
								vOverrides2 = cmGetRoomRateOverrides(vDocObj.RoomRate, vDocObj.Hotel, vAccTemplateOld, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, vDocObj.RoomType));
							EndIf;
							If vOverrides2.Count() > 0 Then
								vOverrideRows = vOverrides2.FindRows(New Structure("AccommodationType, TemplateLineNumber", vDocObj.AccommodationType, i + 1));
								If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
									vDocObj.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
							vDoRecalculateResources = True;
						EndIf;
					EndIf;
				EndIf;

				// Recalculate resources
				If vDoRecalculateResources Then
					vDocObj.pmCalculateResources();
				EndIf;
				
				// Recalculate services
				vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
				
				// Save document
				vDocObj.AdditionalProperties.Insert("CheckFolioDebts", False);
				vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
				vDocObj.Write(DocumentWriteMode.Posting);
				
				// Go to the next document
				i = i + 1;
			EndDo;
		EndIf;

		// Check processing results
		For Each vDoc In pDocsToProcess Do
			vDocObj = vDoc.GetObject();
			
			// Define if it was room full check-out
			vDoCheckOut = False;
			vCheckFolioDebts = False;
			If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
				If BegOfDay(DateFrom) <= BegOfDay(CurrentSessionDate()) Then
					vDoCheckOut = True;
					vCheckFolioDebts = True;
				EndIf;
			EndIf;
			If vDoCheckOut And pDocsToPostprocess.Count() > 0 And Not vIsForFolioSplitOld Then
				vCheckFolioDebts = False;
			EndIf;
			
			// Build value table of accommodation periods
			vPeriods = vDocObj.pmGetAccommodationPeriods(True);
			// Process each accommodation period separately
			vCancel = False;
			If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") And vCheckFolioDebts Then
				vDocObj.pmCheckFolioDebts(vCancel, DocumentPostingMode.RealTime);
			EndIf;
			If Not vCancel Then
				vDocObj.AdditionalProperties.Insert("WarningMessage", "");
				For Each vPeriodsRow In vPeriods Do
					vMessage = ""; vAttributeInErr = ""; 
					vCancel	= vDocObj.pmCheckDocumentAttributes(vPeriodsRow, vDocObj.Posted, vMessage, vAttributeInErr, False, True);
					If vCancel Then
						WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, vDocObj.Metadata(), vDocObj.Ref, NStr(vMessage));
						Raise String(vDocObj.Ref) + " - " + NStr(vMessage);
					Else
						If Not IsBlankString(vDocObj.AdditionalProperties.WarningMessage) Then
							rWarningMessage = rWarningMessage + ?(IsBlankString(rWarningMessage), "", Chars.LF + Chars.LF) + TrimAll(vDocObj.AdditionalProperties.WarningMessage);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			If Not vCancel Then
				If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
					vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				Else
					vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndDo;

		For Each vDoc In pDocsToPostprocess Do
			vDocObj = vDoc.GetObject();
			vDocObj.AdditionalProperties.Insert("WarningMessage", "");
			// Build value table of accommodation periods
			vPeriods = vDocObj.pmGetAccommodationPeriods(True);
			// Process each accommodation period separately
			vCancel = False;
			For Each vPeriodsRow In vPeriods Do
				vMessage = ""; vAttributeInErr = ""; 
				vCancel	= vDocObj.pmCheckDocumentAttributes(vPeriodsRow, vDocObj.Posted, vMessage, vAttributeInErr, False, True);
				If vCancel Then
					WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, vDocObj.Metadata(), vDocObj.Ref, NStr(vMessage));
					Raise String(vDocObj.Ref) + " - " + NStr(vMessage);
				Else
					If Not IsBlankString(vDocObj.AdditionalProperties.WarningMessage) Then
						rWarningMessage = rWarningMessage + ?(IsBlankString(rWarningMessage), "", Chars.LF + Chars.LF) + TrimAll(vDocObj.AdditionalProperties.WarningMessage);
					EndIf;
				EndIf;
			EndDo;
			If Not vCancel Then
				If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
					vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				Else
					vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndDo;
		
		// Commit all changes
		If pDocsToPostprocess.Count() > 0 Then
			CommitTransaction();
		EndIf;
	Except
		vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	Return vErrorDescription;
EndFunction // CheckOutOperationAtServer

// ------------------------------------------------------------------------------
&AtServer
Function BookedOutOperationAtServer(pDocsToProcess, pDocsToPostprocess, rWarningMessage = "")
	rWarningMessage = "";
	vErrorDescription = "";
	// Do processing
	Try
		// All guests in room should be checked for booked out operation
		If pDocsToPostprocess.Count() > 0 Then
			Raise NStr("en='All guests in room should be checked!'; ru='Должны быть отмечены все гости номера!'; de='Alle Gäste sollen häkchen werden!'");
		EndIf;

		BeginTransaction(DataLockControlMode.Managed);
		
		i = 0;
		For Each vDoc In pDocsToProcess Do
			// Get document object
			vDocObj = vDoc.GetObject();
			If BookOutActionType = 0 Or BookOutActionType = 1 Then
				If cm0SecondShift(vDocObj.CheckInDate) > cm0SecondShift(DateFrom) Then
					Raise NStr("en='Check-in date is later then booked out date! '; ru='Дата заезда позже даты начала периода вне отеля! '; de='Das Anreisedatum ist nach dem Bookedoutdatum angegeben! '") + TrimAll(vDoc);
				EndIf;
				If cm0SecondShift(vDocObj.CheckOutDate) < cm0SecondShift(DateFrom) Then
					Raise NStr("en='Check-out date is earlier then booked out date! '; ru='Дата выезда раньше даты начала периода вне отеля! '; de='Das Abreisedatum ist vor dem Bookedoutdatum angegeben! '") + TrimAll(vDoc);
				EndIf;
				If cm0SecondShift(vDocObj.CheckInDate) > cm0SecondShift(DateTo) Then
					Raise NStr("en='Check-in date is later then end of booked out period date! '; ru='Дата заезда позже даты окончания периода вне отеля! '; de='Das Anreisedatum ist nach dem Bookedouteindedatum angegeben! '") + TrimAll(vDoc);
				EndIf;
				If cm0SecondShift(vDocObj.CheckOutDate) < cm0SecondShift(DateTo) Then
					Raise NStr("en='Check-out date is earlier then end of booked out period date! '; ru='Дата выезда раньше даты окончания периода вне отеля! '; de='Das Abreisedatum ist vor dem Bookedouteindedatum angegeben! '") + TrimAll(vDoc);
				EndIf;
			EndIf;
			
			// Clear existing booked out periods
			If BookOutActionType = 0 Or BookOutActionType = 2 Then
				For Each vRRRow In vDocObj.RoomRates Do
					If vRRRow.IsBookedOut Then
						vRRRow.IsBookedOut = False;
						vRRRow.BookOutHotel = "";
						vRRRow.BookOutPrice = 0;
						vRRRow.BookOutPriceCurrency = Undefined;
					EndIf;
				EndDo;
			EndIf;
			
			// Add new booked out period
			If BookOutActionType = 0 Or BookOutActionType = 1 Then
				vCurDate = BegOfDay(DateFrom);
				While vCurDate < BegOfDay(DateTo) Do
					vRRRow = vDocObj.RoomRates.Find(vCurDate, "AccountingDate");
					If vRRRow = Undefined Then
						vRRRow = vDocObj.RoomRates.Add();
						vRRRow.AccountingDate = vCurDate;
					EndIf;
					
					If vCurDate = BegOfDay(DateFrom) Then
						vRRRow.ChangeTime = '00010101' + (DateFrom - BegOfDay(DateFrom));
					EndIf;
					vRRRow.IsBookedOut = True;
					vRRRow.BookOutHotel = BookOutHotel;
					If i = 0 Then
						vRRRow.BookOutPrice = BookOutPrice;
						vRRRow.BookOutPriceCurrency = BookOutPriceCurrency;
					EndIf;
					
					vCurDate = vCurDate + 24*3600;
				EndDo;
			EndIf;
			
			vDocObj.RoomRates.Sort("AccountingDate, ChangeTime");
			
			// Booked out remarks
			If BookOutActionType = 0 Or BookOutActionType = 2 Then
				While True Do
					vBOPos = StrFind(vDocObj.Remarks, "BO: ");
					If vBOPos = 0 Then
						Break;
					Else
						vLFPos = StrFind(vDocObj.Remarks, Chars.LF);
						If vLFPos = 0 Then
							vDocObj.Remarks = "";
							Break;
						Else
							If vLFPos > vBOPos Then
								vDocObj.Remarks = Mid(vDocObj.Remarks, vLFPos + 1);
							Else
								Break;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			If BookOutActionType = 0 Or BookOutActionType = 1 Then
				If Not IsBlankString(BookOutHotel) Then
					vDocObj.Remarks = "BO: " + TrimAll(BookOutHotel) + " (" + Format(DateFrom, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(DateTo, "DF='dd.MM.yyyy HH:mm'") + ")" + Chars.LF + TrimAll(vDocObj.Remarks);
				Else
					vDocObj.Remarks = "BO:" + " (" + Format(DateFrom, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(DateTo, "DF='dd.MM.yyyy HH:mm'") + ")" + Chars.LF + TrimAll(vDocObj.Remarks);
				EndIf;
			EndIf;
			
			// Save document
			vDocObj.AdditionalProperties.Insert("CheckFolioDebts", False);
			vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
			vDocObj.Write(DocumentWriteMode.Posting);
			
			// Go to the next document
			i = i + 1;
		EndDo;
		
		// Check processing results
		For Each vDoc In pDocsToProcess Do
			vDocObj = vDoc.GetObject();
			vDocObj.AdditionalProperties.Insert("WarningMessage", "");
			// Build value table of accommodation periods
			vPeriods = vDocObj.pmGetAccommodationPeriods(True);
			// Process each accommodation period separately
			vCancel = False;
			For Each vPeriodsRow In vPeriods Do
				vMessage = ""; vAttributeInErr = ""; 
				vCancel	= vDocObj.pmCheckDocumentAttributes(vPeriodsRow, vDocObj.Posted, vMessage, vAttributeInErr, False, True);
				If vCancel Then
					WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, vDocObj.Metadata(), vDocObj.Ref, NStr(vMessage));
					Raise String(vDocObj.Ref) + " - " + NStr(vMessage);
				Else
					If Not IsBlankString(vDocObj.AdditionalProperties.WarningMessage) Then
						rWarningMessage = rWarningMessage + ?(IsBlankString(rWarningMessage), "", Chars.LF + Chars.LF) + TrimAll(vDocObj.AdditionalProperties.WarningMessage);
					EndIf;
				EndIf;
			EndDo;
			If Not vCancel Then
				If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
					vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				Else
					vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndDo;
		
		// Commit all changes
		CommitTransaction();
	Except
		vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	Return vErrorDescription;
EndFunction // BookedOutOperationAtServer

// ------------------------------------------------------------------------------
&AtServer
Function StayOverOperationAtServer(pDocsToProcess, pDocsToPostprocess, rWarningMessage = "")
	rWarningMessage = "";
	vErrorDescription = "";
		
	// All docs left in the room should have check-out date eqrlier or equal to the current check-out date
	If pDocsToPostprocess.Count() > 0 Then
		i = 0;
		While i < pDocsToPostprocess.Count() Do
			vDoc = pDocsToPostprocess.Get(i);
			If TypeOf(vDoc) = Type("DocumentRef.Accommodation") Then
				If ValueIsFilled(vDoc.AccommodationStatus) And 
				  (Not vDoc.AccommodationStatus.IsActive Or Not vDoc.AccommodationStatus.IsInHouse) Then
					pDocsToPostprocess.Delete(i);
					Continue;
				EndIf;
			EndIf;
			If vDoc.CheckOutDate > cm0SecondShift(DateTo) Then
				Raise NStr("en='Check-out date specified should be later or equal to the current check-out date! Use check-out function instead.'; 
				           |ru='Указанная дата выезда должна быть позже или равна текущей дате выселения гостей! Используйте функцию выселения.'; 
						   |de='Das angegebene Abreisedatum muss später oder gleich dem aktuellen Abreisedatum der Gäste sein! Verwenden Sie die Check-out-Funktion.'") + 
				      Chars.LF + TrimAll(vDoc);
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;
	
	// Try to get accommodation template for the staying over guests
	vIsForFolioSplitNew = False;
	If pDocsToProcess.Count() > 0 Then
		vIsForFolioSplitNew = pDocsToProcess.Get(0).IsForFolioSplit;
	EndIf;
	vAccTemplateNew = GetAccommodationTemplate(pDocsToProcess, RoomType, vIsForFolioSplitNew);
	
	// Do processing
	Try
		BeginTransaction(DataLockControlMode.Managed);
		
		// New room
		i = 0;
		vOverrides1 = New ValueTable();
		vOverrides2 = New ValueTable();
		For Each vDoc In pDocsToProcess Do
			// Get document object
			vDocObj = vDoc.GetObject();
			If vDocObj.CheckInDate > DateTo Then
				Raise NStr("en='Check-in date is later then new check-out date! '; ru='Дата заезда позже новой даты выселения! '; de='Das Anreisedatum ist nach dem neue Abreisedatum angegeben! '") + TrimAll(vDoc);
			EndIf;
			If vDocObj.CheckOutDate > DateTo Then
				Raise NStr("en='Current check-out date is later then new check-out date! '; ru='Текущая дата выезда позже новой даты выселения! '; de='Das Aktuelles Abreisedatum ist nach dem neuen Abreisedatum angegeben! '") + TrimAll(vDoc);
			EndIf;
			
			vDoRecalculateResources = True;
			
			If pDocsToPostprocess.Count() > 0 Then
				vRRRow = vDocObj.RoomRates.Find(BegOfDay(vDocObj.CheckInDate), "AccountingDate");
				If vRRRow = Undefined Then
					vRRRow = vDocObj.RoomRates.Add();
					vRRRow.AccountingDate = BegOfDay(vDocObj.CheckInDate);
					vRRRow.AccommodationType = vDocObj.AccommodationType;
				ElsIf Not ValueIsFilled(vRRRow.AccommodationType) Then 
					vRRRow.AccommodationType = vDocObj.AccommodationType;
				EndIf;
				vRRRow.AccommodationTemplate = ?(ValueIsFilled(vDocObj.AccommodationTemplate), vDocObj.AccommodationTemplate, Catalogs.AccommodationTemplates.NoTemplate);
				
				vRRRow = vDocObj.RoomRates.Find(BegOfDay(vDocObj.CheckOutDate), "AccountingDate");
				If vRRRow = Undefined Then
					vRRRow = vDocObj.RoomRates.Add();
					vRRRow.AccountingDate = BegOfDay(vDocObj.CheckOutDate);
				EndIf;
				If ValueIsFilled(vAccTemplateNew) Then
					If vAccTemplateNew.IsForFolioSplit = vIsForFolioSplitNew Then
						If vAccTemplateNew.AccommodationTypes.Count() > i Then
							vRRRow.AccommodationType = vAccTemplateNew.AccommodationTypes.Get(i).AccommodationType;
							If vOverrides1.Columns.Count() = 0 Then
								vOverrides1 = cmGetRoomRateOverrides(?(ValueIsFilled(vRRRow.RoomRate), vRRRow.RoomRate, vDocObj.RoomRate), vDocObj.Hotel, vAccTemplateNew, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, ?(ValueIsFilled(vRRRow.RoomType), vRRRow.RoomType, vDocObj.RoomType)));
							EndIf;
							If vOverrides1.Count() > 0 Then
								vOverrideRows = vOverrides1.FindRows(New Structure("AccommodationType, TemplateLineNumber", vRRRow.AccommodationType, i + 1));
								If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
									vRRRow.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If i = 0 Then
						vRRRow.AccommodationTemplate = vAccTemplateNew;
					EndIf;
				EndIf;
			EndIf;
			
			vDocObj.RoomRates.Sort("AccountingDate, ChangeTime");
			
			vDocObj.CheckOutDate = DateTo;
			vDocObj.Duration = vDocObj.pmCalculateDuration();
			
			// Update main document attributes if this change is today
			If pDocsToPostprocess.Count() > 0 Then
				If BegOfDay(DateTo) = BegOfDay(CurrentSessionDate()) Then
					If ValueIsFilled(vAccTemplateNew) And vAccTemplateNew.IsForFolioSplit = vIsForFolioSplitNew Then
						If vAccTemplateNew.AccommodationTypes.Count() > i Then
							vDocObj.AccommodationType = vAccTemplateNew.AccommodationTypes.Get(i).AccommodationType;
							If vOverrides2.Columns.Count() = 0 Then
								vOverrides2 = cmGetRoomRateOverrides(vDocObj.RoomRate, vDocObj.Hotel, vAccTemplateNew, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, vDocObj.RoomType));
							EndIf;
							If vOverrides2.Count() > 0 Then
								vOverrideRows = vOverrides2.FindRows(New Structure("AccommodationType, TemplateLineNumber", vDocObj.AccommodationType, i + 1));
								If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
									vDocObj.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
							vDoRecalculateResources = True;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			// Update price calculation dates if necessary
			vDocObj.pmUpdatePriceCalculationDate();

			// Recalculate resources
			If vDoRecalculateResources Then
				vDocObj.pmCalculateResources();
			EndIf;
			
			// Recalculate services
			vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
			
			// Save document
			vDocObj.AdditionalProperties.Insert("CheckFolioDebts", False);
			vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
			vDocObj.Write(DocumentWriteMode.Posting);
			
			// Go to the next document
			i = i + 1;
		EndDo;
		
		// Check processing results
		For Each vDoc In pDocsToProcess Do
			vDocObj = vDoc.GetObject();
			vDocObj.AdditionalProperties.Insert("WarningMessage", "");
			// Build value table of accommodation periods
			vPeriods = vDocObj.pmGetAccommodationPeriods(True);
			// Process each accommodation period separately
			vCancel = False;
			For Each vPeriodsRow In vPeriods Do
				vMessage = ""; vAttributeInErr = ""; 
				vCancel	= vDocObj.pmCheckDocumentAttributes(vPeriodsRow, vDocObj.Posted, vMessage, vAttributeInErr, False, True);
				If vCancel Then
					WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, vDocObj.Metadata(), vDocObj.Ref, NStr(vMessage));
					Raise String(vDocObj.Ref) + " - " + NStr(vMessage);
				Else
					If Not IsBlankString(vDocObj.AdditionalProperties.WarningMessage) Then
						rWarningMessage = rWarningMessage + ?(IsBlankString(rWarningMessage), "", Chars.LF + Chars.LF) + TrimAll(vDocObj.AdditionalProperties.WarningMessage);
					EndIf;
				EndIf;
			EndDo;
			If Not vCancel Then
				If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
					vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				Else
					vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndDo;
		
		// Commit all changes
		CommitTransaction();
	Except
		vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	Return vErrorDescription;
EndFunction // StayOverOperationAtServer

// ------------------------------------------------------------------------------
&AtServer
Function ExecuteActionAtServer(pDocsToProcess, pDocsToPostprocess, rWarningMessage = "")
	rWarningMessage = "";
	vErrorDescription = "";
	If Operations = 0 Then
		vErrorDescription = CheckInOperationAtServer(pDocsToProcess, pDocsToPostprocess, rWarningMessage);
	ElsIf Operations = 1 Then
		vErrorDescription = ChangeRoomOperationAtServer(pDocsToProcess, pDocsToPostprocess, rWarningMessage);
	ElsIf Operations = 2 Then
		vErrorDescription = CheckOutOperationAtServer(pDocsToProcess, pDocsToPostprocess, rWarningMessage);
	ElsIf Operations = 3 Then
		vErrorDescription = BookedOutOperationAtServer(pDocsToProcess, pDocsToPostprocess, rWarningMessage);
	ElsIf Operations = 4 Then
		vErrorDescription = StayOverOperationAtServer(pDocsToProcess, pDocsToPostprocess, rWarningMessage);
	EndIf;
	Return vErrorDescription;
EndFunction // ExecuteActionAtServer

// ------------------------------------------------------------------------------
&AtServer
Function GetAllAccommodationTemplatesCount(pHotel)
	vAccTemplates = cmGetAllAccommodationTemplates(pHotel);
	Return vAccTemplates.Count();
EndFunction // GetAllAccommodationTemplatesCount

// -----------------------------------------------------------------------------
// Description: Function checks balances for the given accommodations value list
// Parameters: Value list of accommodations
// Return value: True if balances are zero or False if not
// -----------------------------------------------------------------------------
&AtServer
Function CheckAccommodationsBalances(pAccList)
	vFolios = cmGetDocumentFoliosWithDebts(pAccList);
	If vFolios.Count() > 0 Then
		vDoQuery = False;
		vThereAreDebts = False;
		vThereAreDeposits = False;
		vDebtsMessage = NStr("en='Folios: ';ru='По лицевым счетам: ';de='Nach Personenkonten: '") + Chars.LF;
		For Each vFoliosRow In vFolios Do
			If vFoliosRow.SumBalance < 0 Then
				vThereAreDeposits = True;
			ElsIf vFoliosRow.SumBalance > 0 Then
				vThereAreDebts = True;
			EndIf;
			If ValueIsFilled(vFoliosRow.Folio) Then
				If ValueIsFilled(vFoliosRow.Folio.PaymentMethod) Then
					If Not vFoliosRow.Folio.PaymentMethod.BookByCashRegister Or
					   (vFoliosRow.Folio.PaymentMethod.IsByBankTransfer And ValueIsFilled(vFoliosRow.Folio.Customer))Then
						Continue;
					EndIf;
				EndIf;
				vDoQuery = True;
				vDebtsMessage = vDebtsMessage + Chars.LF + "#" + TrimAll(vFoliosRow.Folio.Number) + " " + 
				                TrimAll(vFoliosRow.Folio.Client) + NStr("ru = ', номер '; en = ', room '; de = ', zimmer '") + 
				                TrimAll(vFoliosRow.Folio.Room) + NStr("ru = ', период '; en = ', period '; de = ', period '") + 
				                Format(vFoliosRow.Folio.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
				                Format(vFoliosRow.Folio.DateTimeTo, "DF='dd.MM.yy HH:mm'") + " = " + 
				                cmFormatSum(vFoliosRow.SumBalance, vFoliosRow.Folio.FolioCurrency, "NZ=");
			Else
				vDoQuery = True;
				vDebtsMessage = vDebtsMessage + Chars.LF + NStr("en='<Empty folio>';ru='<Пустое фолио>';de='<Leeres Blatt>'") + " = " + cmFormatSum(vFoliosRow.SumBalance, "NZ=", , True);
			EndIf;
		EndDo;
		If vDoQuery Then
			If vThereAreDebts And Not vThereAreDeposits Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEBTS!';ru='ЕСТЬ ЗАДОЛЖЕННОСТЬ!';de='ES LIEGT EINE SCHULD VOR!'");
			ElsIf Not vThereAreDebts And vThereAreDeposits Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEPOSITS!';ru='ЕСТЬ ПЕРЕПЛАТА!';de='ES LIEGT EINE ÜBERZAHLUNG VOR!'");
			Else
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEBTS AND DEPOSITS!';ru='ЕСТЬ ЗАДОЛЖЕННОСТЬ И ПЕРЕПЛАТА!';de='ES LIEGT EINE SCHULD oder ÜBERZAHLUNG vor!'");
			EndIf;
			Return vDebtsMessage;
		EndIf;
	EndIf;
	Return "";
EndFunction // CheckAccommodationsBalances

// ------------------------------------------------------------------------------
&AtServerNoContext
Procedure DateFromOnChangeAtServer(rDate, pRoomRate)
	If ValueIsFilled(pRoomRate) Then
		If ValueIsFilled(pRoomRate.DefaultCheckInTime) Or ValueIsFilled(pRoomRate.DefaultCheckOutTime) Then
			rDate = BegOfDay(rDate) + (pRoomRate.DefaultCheckInTime - BegOfDay(pRoomRate.DefaultCheckInTime));
		ElsIf ValueIsFilled(pRoomRate.ReferenceHour) Then
			rDate = BegOfDay(rDate) + (pRoomRate.ReferenceHour - BegOfDay(pRoomRate.ReferenceHour));
		EndIf;
	EndIf;
EndProcedure // DateFromOnChangeAtServer

// ------------------------------------------------------------------------------
&AtServerNoContext
Procedure DateToOnChangeAtServer(rDate, pRoomRate)
	If ValueIsFilled(pRoomRate) Then
		If ValueIsFilled(pRoomRate.ReferenceHour) Then
			rDate = BegOfDay(rDate) + (pRoomRate.ReferenceHour - BegOfDay(pRoomRate.ReferenceHour));
		EndIf;
	EndIf;
EndProcedure // DateToOnChangeAtServer

// ------------------------------------------------------------------------------
&AtServer
Procedure RoomToOnChangeAtServer()
	If ValueIsFilled(RoomTo) Then
		If RoomTo.StopSale And ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) And DateTo > DateFrom Then
			vRemarks = "";
			If cmIsRoomStopSalePeriod(RoomTo, DateFrom, DateTo, vRemarks) Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='You choose room with stop sale flag turned on!';ru='Выбрали номер снятый с продажи!';de='Sie haben ein Zimmer gewählt, das aus dem Angebot genommen wurde!'") + Chars.LF + vRemarks);
				If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
					RoomTo = Undefined;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(RoomTo) And ValueIsFilled(DateFrom) Then
			vRoomAttrs = RoomTo.GetObject().pmGetRoomAttributes(cm1SecondShift(DateFrom));
			For Each vRoomAttrsRow In vRoomAttrs Do
				RoomType = vRoomAttrsRow.RoomType;
				Break;
			EndDo;
		EndIf;
	EndIf;
	If ValueIsFilled(RoomType) Then
		If RoomType.StopSale And ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) And DateTo > DateFrom Then
			vRemarks = "";
			If cmIsStopSalePeriod(RoomType, DateFrom, DateTo, vRemarks) Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='You choose room type with stop sale flag turned on!';ru='Выбрали тип номера снятый с продажи!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde!'") + Chars.LF + vRemarks);
				If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
					RoomTo = Undefined;
					RoomType = Undefined;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // RoomToOnChangeAtServer

// ------------------------------------------------------------------------------
&AtServer
Procedure RoomTypeOnChangeAtServer()
	If ValueIsFilled(RoomType) Then
		If ValueIsFilled(RoomTo) And ValueIsFilled(DateFrom) Then
			vRoomToType = Undefined;
			vRoomAttrs = RoomTo.GetObject().pmGetRoomAttributes(cm1SecondShift(DateFrom));
			For Each vRoomAttrsRow In vRoomAttrs Do
				vRoomToType = vRoomAttrsRow.RoomType;
				Break;
			EndDo;
			If ValueIsFilled(vRoomToType) Then
				If RoomType <> vRoomToType Then
					RoomTo = Undefined;
				EndIf;
			EndIf;
		EndIf;
		If RoomType.StopSale And ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) And DateTo > DateFrom Then
			vRemarks = "";
			If cmIsStopSalePeriod(RoomType, DateFrom, DateTo, vRemarks) Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='You choose room type with stop sale flag turned on!';ru='Выбрали тип номера снятый с продажи!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde!'") + Chars.LF + vRemarks);
				If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
					RoomTo = Undefined;
					RoomType = Undefined;
				EndIf;
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(RoomTo) Then
			RoomToOnChangeAtServer();
		EndIf;
	EndIf;
EndProcedure // RoomTypeOnChangeAtServer

#EndRegion
