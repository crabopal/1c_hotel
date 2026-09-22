// -----------------------------------------------------------------------------
Procedure SetParameters(pGuestCard, pDocument)
	// Document
	pGuestCard.Parameters.mDocument = pDocument;
	
	// Guest
	pGuestCard.Parameters.mGuest = pDocument.Guest;
	
	// Room
	pGuestCard.Parameters.mRoom = pDocument.Room;
	
	If TypeOfPrintForm = 1 Then
		// Guest group
		If ValueIsFilled(pDocument.GuestGroup) Then
			pGuestCard.Parameters.mGuestGroupCode = TrimAll(pDocument.GuestGroup.Code);
		Else
			pGuestCard.Parameters.mGuestGroupCode = "";
		EndIf;
		
		// Guest check in and check out dates
		pGuestCard.Parameters.mCheckInDate = Format(pDocument.CheckInDate, "DF=dd.MM.yyyy");
		pGuestCard.Parameters.mCheckOutDate = Format(pDocument.CheckOutDate, "DF=dd.MM.yyyy");
		pGuestCard.Parameters.mCheckInTime = Format(pDocument.CheckInDate, "DF=HH:mm; DE=00:00");
		pGuestCard.Parameters.mFinalCheckOutDate = "";
		
		// Room type
		pGuestCard.Parameters.mRoomType = pDocument.RoomType;
		
		// Room rate
		pGuestCard.Parameters.mRoomRate = pDocument.RoomRate;
		
		// Number of persons
		pGuestCard.Parameters.mNumberOfPersons = pDocument.NumberOfPersons;
		
		// Rates
		vRates = "";
		If pDocument.DoNotPrintRate Then
			If ValueIsFilled(pDocument.RoomRate) Then
				vRates = TrimAll(pDocument.RoomRate.Code);
			EndIf;
		Else
			vRates = pDocument.GetObject().pmCalculatePricePresentation();
		EndIf;
		pGuestCard.Parameters.mRates = vRates;
		
		// Deposit
		pGuestCard.Parameters.mDeposit = "";
		vDocList = New ValueList();
		vDocList.Add(pDocument);
		vBalances = cmGetDocumentListBalances(vDocList, pDocument.Hotel);
		For Each vBalancesRow In vBalances Do
			vDeposit = -vBalancesRow.ClientSumBalance + vBalancesRow.ClientLimitBalance;
			pGuestCard.Parameters.mDeposit = pGuestCard.Parameters.mDeposit + cmFormatSum(vDeposit, vBalancesRow.FolioCurrency) + Chars.LF;
		EndDo;
		pGuestCard.Parameters.mDeposit = TrimAll(pGuestCard.Parameters.mDeposit);
		
		// Guest info
		vGuestInfo = "";
		If ValueIsFilled(pDocument.Guest) Then
			vGuestInfo = vGuestInfo + Upper(TrimAll(pDocument.Guest.LastName) + " " + 
			                                TrimAll(pDocument.Guest.FirstName) + " " + 
			                                TrimAll(pDocument.Guest.SecondName)) + Chars.LF;
			vGuestInfo = vGuestInfo + cmNStr("EN = ' Address: '; RU = ' Адрес: '", pDocument.Guest.Language) + 
			                          cmGetAddressPresentation(pDocument.Guest.Address) + Chars.LF;
			vGuestInfo = vGuestInfo + cmNStr("EN = ' Passport: '; RU = ' Паспорт: '", pDocument.Guest.Language) + 
			                          TrimAll(pDocument.Guest.IdentityDocumentSeries) + " " +
			                          TrimAll(pDocument.Guest.IdentityDocumentNumber);
			If ValueIsFilled(pDocument.Guest.IdentityDocumentIssueDate) Then
				vGuestInfo = vGuestInfo + cmNStr("EN = ', issued '; RU = ', выдан '", pDocument.Guest.Language) + 
				                          Format(pDocument.Guest.IdentityDocumentIssueDate, "DF=dd.MM.yy");
			EndIf;
			If Not IsBlankString(pDocument.Guest.IdentityDocumentIssuedBy) Then
				vGuestInfo = vGuestInfo + " " + TrimAll(pDocument.Guest.IdentityDocumentIssuedBy);
			EndIf;
			vGuestInfo = vGuestInfo + Chars.LF;
			If ValueIsFilled(pDocument.Customer) Then
				vGuestInfo = vGuestInfo + cmNStr("EN=' Customer: ';RU=' Компания: ';de=' Partner:'", pDocument.Guest.Language) + 
				                          Upper(TrimAll(pDocument.Customer));
			EndIf;
		EndIf;
		pGuestCard.Parameters.mGuestInfo = vGuestInfo;
	EndIf;
EndProcedure // SetParameters
	
// -----------------------------------------------------------------------------
Procedure PrintGuestCard(pSpreadsheet, pGuestCard, pDocument, pPutPageBreak = False)
	// New page
	If pPutPageBreak Then
		pSpreadsheet.PutHorizontalPageBreak();
	EndIf;
	
	// Calculate and set parameters
	SetParameters(pGuestCard, pDocument);
	
	// Put guest card
	pSpreadsheet.Put(pGuestCard);
EndProcedure // PrintGuestCard

// -----------------------------------------------------------------------------
Procedure PrintGuestCardsForCheckInDate(pSpreadsheet, pGuestCard)
	vQry = New Query();
	If TypeOf(Document) = Type("DocumentRef.Reservation") Then
		vQry.Text = 
		"SELECT
		|	Reservation.Ref AS Document
		|FROM
		|	Document.Reservation AS Reservation
		|WHERE
		|	Reservation.Posted
		|	AND Reservation.RoomType IN HIERARCHY(&qRoomType)
		|	AND (&qGuestGroupIsEmpty
		|			OR NOT &qGuestGroupIsEmpty
		|				AND Reservation.GuestGroup = &qGuestGroup)
		|	AND Reservation.ReservationStatus.IsActive
		|	AND Reservation.CheckInDate >= &qBegOfDate
		|	AND Reservation.CheckInDate <= &qEndOfDate
		|	AND Reservation.Hotel = &qHotel
		|
		|ORDER BY
		|	Reservation.CheckInDate,
		|	Reservation.GuestGroup.Code,
		|	Reservation.Room.SortCode,
		|	Reservation.GuestFullName";
	Else
		vQry.Text = 
		"SELECT
		|	Accommodation.Ref AS Document
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	Accommodation.Posted
		|	AND Accommodation.RoomType IN HIERARCHY(&qRoomType)
		|	AND (&qGuestGroupIsEmpty
		|			OR NOT &qGuestGroupIsEmpty
		|				AND Accommodation.GuestGroup = &qGuestGroup)
		|	AND Accommodation.AccommodationStatus.IsActive
		|	AND Accommodation.AccommodationStatus.IsCheckIn
		|	AND Accommodation.CheckInDate >= &qBegOfDate
		|	AND Accommodation.CheckInDate <= &qEndOfDate
		|	AND Accommodation.Hotel = &qHotel
		|
		|ORDER BY
		|	Accommodation.CheckInDate,
		|	Accommodation.GuestGroup.Code,
		|	Accommodation.Room.SortCode,
		|	Accommodation.GuestFullName";
	EndIf;
	vQry.SetParameter("qRoomType", RoomType);
	vQry.SetParameter("qGuestGroup", GuestGroup);
	vQry.SetParameter("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	vQry.SetParameter("qBegOfDate", BegOfDay(CheckInDate));
	vQry.SetParameter("qEndOfDate", EndOfDay(CheckInDate));
	vQry.SetParameter("qHotel", ?(ValueIsFilled(Document), Document.Hotel, SessionParameters.CurrentHotel));
	vDocs = vQry.Execute().Unload();
	vIsFirstDoc = True;
	For Each vRow In vDocs Do
		If ValueIsFilled(vRow.Document) And ValueIsFilled(vRow.Document.AccommodationType) And 
		   Not vRow.Document.AccommodationType.DoNotIssueKeyCards Then
			PrintGuestCard(pSpreadsheet, pGuestCard, vRow.Document, Not vIsFirstDoc);
			If vIsFirstDoc Then
				vIsFirstDoc = False;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // PrintGuestCardsForCheckInDate

// -----------------------------------------------------------------------------
Procedure PrintGuestCardsForGuestGroup(pSpreadsheet, pGuestCard)
	If TypeOf(Document) = Type("DocumentRef.Reservation") Then
		vReservations = GuestGroup.GetObject().pmGetReservations();
		vIsFirstDoc = True;
		For Each vRow In vReservations Do
			If ValueIsFilled(vRow.Reservation) And ValueIsFilled(vRow.Reservation.AccommodationType) And 
			   Not vRow.Reservation.AccommodationType.DoNotIssueKeyCards Then
				vDoPrint = True;
				If ValueIsFilled(RoomType) Then
					If RoomType.IsFolder Then
						If Not vRow.Reservation.RoomType.BelongsToItem(RoomType) Then
							vDoPrint = False;
						EndIf;
					Else
						If RoomType <> vRow.Reservation.RoomType Then
							vDoPrint = False;
						EndIf;
					EndIf;
				EndIf;
				If vDoPrint Then
					PrintGuestCard(pSpreadsheet, pGuestCard, vRow.Reservation, Not vIsFirstDoc);
					If vIsFirstDoc Then
						vIsFirstDoc = False;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	Else
		vAccommodations = GuestGroup.GetObject().pmGetAccommodations();
		vIsFirstDoc = True;
		For Each vRow In vAccommodations Do
			If ValueIsFilled(vRow.Accommodation) And ValueIsFilled(vRow.Accommodation.AccommodationType) And 
			   Not vRow.Accommodation.AccommodationType.DoNotIssueKeyCards Then
				vDoPrint = True;
				If ValueIsFilled(RoomType) Then
					If RoomType.IsFolder Then
						If Not vRow.Accommodation.RoomType.BelongsToItem(RoomType) Then
							vDoPrint = False;
						EndIf;
					Else
						If RoomType <> vRow.Accommodation.RoomType Then
							vDoPrint = False;
						EndIf;
					EndIf;
				EndIf;
				If vDoPrint Then
					PrintGuestCard(pSpreadsheet, pGuestCard, vRow.Accommodation, Not vIsFirstDoc);
					If vIsFirstDoc Then
						vIsFirstDoc = False;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // PrintGuestCardsForGuestGroup

// -----------------------------------------------------------------------------
Procedure PrintGuestCardsForRoom(pSpreadsheet, pGuestCard)
	If TypeOf(Document) = Type("DocumentRef.Reservation") Then
		vReservations = New ValueList();
		vReservations.Add(Document);
		AddOneRoomReservations(vReservations);
		vIsFirstDoc = True;
		For Each vDocItem In vReservations Do
			If ValueIsFilled(vDocItem.Value) And ValueIsFilled(vDocItem.Value.AccommodationType) And 
			   Not vDocItem.Value.AccommodationType.DoNotIssueKeyCards Then
				PrintGuestCard(pSpreadsheet, pGuestCard, vDocItem.Value, Not vIsFirstDoc);
				If vIsFirstDoc Then
					vIsFirstDoc = False;
				EndIf;
			EndIf;
		EndDo;
	Else
		vAccommodations = New ValueList();
		vAccommodations.Add(Document);
		AddOneRoomAccommodations(vAccommodations);
		vIsFirstDoc = True;
		For Each vDocItem In vAccommodations Do
			If ValueIsFilled(vDocItem.Value) And ValueIsFilled(vDocItem.Value.AccommodationType) And 
			   Not vDocItem.Value.AccommodationType.DoNotIssueKeyCards Then
				PrintGuestCard(pSpreadsheet, pGuestCard, vDocItem.Value, Not vIsFirstDoc);
				If vIsFirstDoc Then
					vIsFirstDoc = False;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // PrintGuestCardsForRoom

// -----------------------------------------------------------------------------
Procedure AddOneRoomAccommodations(pDocsList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Ref <> &qDoc
	|	AND Accommodation.Room = &qRoom
	|	AND Accommodation.GuestGroup = &qGuestGroup
	|	AND Accommodation.CheckOutDate > &qCheckInDate
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qDoc", Document);
	vQry.SetParameter("qRoom", Document.Room);
	vQry.SetParameter("qGuestGroup", Document.GuestGroup);
	vQry.SetParameter("qCheckInDate", Document.CheckInDate);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		pDocsList.Add(vQryResRow.Ref);
	EndDo;
EndProcedure // AddOneRoomAccommodations 

// -----------------------------------------------------------------------------
Procedure AddOneRoomReservations(pDocsList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservations.Ref
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Ref <> &qDoc
	|	AND Reservations.Number = &qDocNumber
	|	AND Reservations.Posted
	|	AND Reservations.ReservationStatus.IsActive
	|ORDER BY
	|	Reservations.PointInTime";
	vQry.SetParameter("qDoc", Document);
	vQry.SetParameter("qDocNumber", Document.Number);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		pDocsList.Add(vQryResRow.Ref);
	EndDo;
EndProcedure // AddOneRoomReservations

// -----------------------------------------------------------------------------
Procedure FillHotelParameters(pGuestCard)
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(Document) Then
		If ValueIsFilled(Document.Hotel) Then
			vHotel = Document.Hotel;
		EndIf;
	ElsIf ValueIsFilled(GuestGroup) Then
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			vHotel = SessionParameters.CurrentHotel;
		EndIf;
	EndIf;
	If ValueIsFilled(vHotel) Then
		// Hotel name
		vHotelNameRU = cmNStr(vHotel.PrintNameTranslations, Catalogs.Languages.RU);
		If IsBlankString(vHotelNameRU) Then
			vHotelNameRU = TrimAll(vHotel.PrintName);
		EndIf;
		If IsBlankString(vHotelNameRU) Then
			vHotelNameRU = TrimAll(vHotel.LegacyName);
		EndIf;
		If IsBlankString(vHotelNameRU) Then
			vHotelNameRU = TrimAll(vHotel.Description);
		EndIf;
		pGuestCard.Parameters.mHotelNameRU = Upper(vHotelNameRU);
		
		If TypeOfPrintForm = 1 Then
			pGuestCard.Parameters.mHotelNameEN = Upper(cmNStr(vHotel.PrintNameTranslations, Catalogs.Languages.EN));
		EndIf;
		
		If TypeOfPrintForm = 2 Then
			// Hotel address
			vHotelAddressRU = cmNStr(cmGetAddressPresentation(vHotel.PostAddressTranslations), Catalogs.Languages.RU);
			If IsBlankString(vHotelAddressRU) Then
				vHotelAddressRU = TrimAll(cmGetAddressPresentation(vHotel.PostAddress));
			EndIf;
			pGuestCard.Parameters.mHotelAddressRU = vHotelAddressRU;
		
			// How to drive to the hotel
			vHotelHowToDriveRU = cmNStr(vHotel.HowToDriveToTheHotelTranslations, Catalogs.Languages.RU);
			If IsBlankString(vHotelHowToDriveRU) Then
				vHotelHowToDriveRU = TrimAll(vHotel.HowToDriveToTheHotel);
			EndIf;
			pGuestCard.Parameters.mHotelHowToDriveRU = vHotelHowToDriveRU;
		
			// Hotel phones
			pGuestCard.Parameters.mHotelPhones = TrimAll(vHotel.Phones);
		EndIf;
		
		If TypeOfPrintForm = 1 Then
			// Reference hour
			vDefaultRoomRate = vHotel.RoomRate;
			If ValueIsFilled(vDefaultRoomRate) Then
				If vDefaultRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
					pGuestCard.Parameters.mReferenceHourRU = "РАСЧЕТНЫЙ ЧАС " + Format(vDefaultRoomRate.ReferenceHour, "DF=HH:mm; DE=00:00") + "/";
					pGuestCard.Parameters.mReferenceHourEN = "CHECK-OUT TIME " + Format(vDefaultRoomRate.ReferenceHour, "DF=HH:mm; DE=00:00");
				Else
					pGuestCard.Parameters.mReferenceHourRU = "";
					pGuestCard.Parameters.mReferenceHourEN = "";
				EndIf;
			Else
				pGuestCard.Parameters.mReferenceHourRU = "РАСЧЕТНЫЙ ЧАС 12:00/";
				pGuestCard.Parameters.mReferenceHourEN = "CHECK-OUT TIME 12:00";
			EndIf;
		EndIf;
	Else
		pGuestCard.Parameters.mHotelNameRU = "";
		If TypeOfPrintForm = 1 Then
			pGuestCard.Parameters.mHotelNameEN = "";
		EndIf;
		If TypeOfPrintForm = 2 Then
			pGuestCard.Parameters.mHotelAddressRU = "";
			pGuestCard.Parameters.mHotelHowToDriveRU = "";
			pGuestCard.Parameters.mHotelPhones = "";
		EndIf;
		If TypeOfPrintForm = 1 Then
			pGuestCard.Parameters.mReferenceHourRU = "";
			pGuestCard.Parameters.mReferenceHourEN = "";
		EndIf;
	EndIf;
EndProcedure // FillHotelParameters

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet, pTemplate = Undefined) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate(?(TypeOfPrintForm = 1, "FreeForm", "Form4G"));
	If pTemplate <> Undefined Then
		vTemplate = pTemplate;
	EndIf;
	
	// Guest card area
	vGuestCard = vTemplate.GetArea("GuestCard");
	
	// Fill static parameters
	FillHotelParameters(vGuestCard);
	
	// Call processings	
	If ValueIsFilled(CheckInDate) Then
		PrintGuestCardsForCheckInDate(pSpreadsheet, vGuestCard);
	ElsIf ValueIsFilled(GuestGroup) Then
		PrintGuestCardsForGuestGroup(pSpreadsheet, vGuestCard);
	Else
		PrintGuestCardsForRoom(pSpreadsheet, vGuestCard);
	EndIf;
EndProcedure // pmGenerate
