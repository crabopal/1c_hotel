
#Region Public

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet, pTemplate = Undefined, pIsPersonal = False) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	If TypeOfPrintForm = 1 Then
		vTemplate = ThisObject.GetTemplate("FreeForm");
	ElsIf TypeOfPrintForm = 2 Then
		vTemplate = ThisObject.GetTemplate("Form1G");
	ElsIf TypeOfPrintForm = 3 Then
		vTemplate = ThisObject.GetTemplate("Form5");
	EndIf;
	If pTemplate <> Undefined Then
		vTemplate = pTemplate;
	EndIf;
	
	// Guest form area
	vGuestFormR = Undefined;
	If TypeOfPrintForm = 3 Then
		If Print2On1Page Then
			vGuestForm = vTemplate.GetArea("GuestForm");
		Else
			vGuestForm = vTemplate.GetArea("GuestForm|Left");
			vGuestFormR = vTemplate.GetArea("GuestForm|Right");
		EndIf;
	Else
		vGuestForm = vTemplate.GetArea("GuestForm");
	EndIf;
	
	// Fill static parameters
	FillHotelParameters(vGuestForm);
	If vGuestFormR <> Undefined Then
		FillHotelParameters(vGuestFormR);
	EndIf;
	
	// Print guest form
	If ValueIsFilled(CheckInDate) Then
		PrintGuestFormsForCheckInDate(pSpreadsheet, vGuestForm, vGuestFormR);
	ElsIf Not ValueIsFilled(GuestGroup) Then
		If pIsPersonal Then
			PrintGuestForm(pSpreadsheet, vGuestForm, Document);
		Else
			PrintGuestFormsForRoom(pSpreadsheet, vGuestForm, vGuestFormR);
		EndIf;
	Else
		PrintGuestFormsForGuestGroup(pSpreadsheet, vGuestForm, vGuestFormR);
	EndIf;
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Function pmGetHouse(pHouseStr) Export
	vHouse = "";
	For i = 1 To StrLen(pHouseStr) Do
		vChar = Mid(pHouseStr, i, 1);
		If IsBlankString(vChar) Or Not cmIsNumber(vChar) Then
			Break;
		Else
			vHouse = vHouse + vChar;
		EndIf;
	EndDo;
	Return vHouse;
EndFunction // pmGetHouse

// -----------------------------------------------------------------------------
Function pmGetBuilding(pHouseStr) Export
	vBuilding = "";
	vHouse = pmGetHouse(pHouseStr);
	If TrimAll(vHouse) <> TrimAll(pHouseStr) Then
		vBuilding = TrimAll(Mid(pHouseStr, StrLen(vHouse) + 1));
		If StrLen(vBuilding) > 1 Then
			If Left(vBuilding, 1) = "/" Or 
			   Left(vBuilding, 1) = "\" Or
			   UPPER(Left(vBuilding, 1)) = "К" Then
				vBuilding = TrimAll(Mid(vBuilding, 2));
			EndIf;
		EndIf;
	EndIf;
	Return vBuilding;
EndFunction // pmGetBuilding

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure SetParameters(pGuestForm, pDocument)
	// Document
	pGuestForm.Parameters.mDocument = pDocument;
	If TypeOfPrintForm <> 3 Then
		pGuestForm.Parameters.mDocumentNumber = TrimAll(pDocument.Number);
	EndIf;
	
	// Guest
	pGuestForm.Parameters.mGuest = pDocument.Guest;
	
	If ValueIsFilled(pDocument.Guest) Then
		vGuest = pDocument.Guest;
		
		// Guest names
		pGuestForm.Parameters.mGuestLastName = Upper(TrimAll(vGuest.LastName));
		pGuestForm.Parameters.mGuestFirstName = Upper(TrimAll(vGuest.FirstName));
		pGuestForm.Parameters.mGuestSecondName = Upper(TrimAll(vGuest.SecondName));
		
		// Guest birth date
		If TypeOfPrintForm = 3 Then
			vGuestDateOfBirth = Upper(Format(vGuest.DateOfBirth, "L=ru_RU; DLF=DD"));
			If vGuestDateOfBirth <> "" Then
				vGuestDateOfBirth = Left(vGuestDateOfBirth, StrLen(vGuestDateOfBirth) - 3);
			EndIf;
			pGuestForm.Parameters.mGuestDateOfBirth = vGuestDateOfBirth;
		Else
			pGuestForm.Parameters.mGuestDateOfBirth = Format(vGuest.DateOfBirth, "DF=dd.MM.yyyy");
		EndIf;
		
		// Guest place of birth
		vPlaceOfBirth = cmParseAddress(vGuest.PlaceOfBirth);
		If TypeOfPrintForm = 1 Then
			// Guest address
			vGuestAddress = cmParseAddress(vGuest.Address);
			pGuestForm.Parameters.mGuestCountry = Upper(String(vGuestAddress.Country));
			pGuestForm.Parameters.mGuestAddress = cmGetAddressPresentation(vGuest.Address);
			pGuestForm.Parameters.mGuestAddress = TrimAll(StrReplace(pGuestForm.Parameters.mGuestAddress, String(vGuestAddress.Country) + ",", ""));
		ElsIf TypeOfPrintForm = 2 Then
			// Guest birth place
			pGuestForm.Parameters.mGuestBirthPlaceRegion = Upper(TrimAll(vPlaceOfBirth.Region));
			pGuestForm.Parameters.mGuestBirthPlaceArea = Upper(TrimAll(vPlaceOfBirth.Area));
			pGuestForm.Parameters.mGuestBirthPlaceCity = Upper(TrimAll(vPlaceOfBirth.City));
			
			// Guest address
			vGuestAddress = cmParseAddress(vGuest.Address);
			pGuestForm.Parameters.mGuestCountry = Upper(String(vGuestAddress.Country));
			pGuestForm.Parameters.mGuestAddress = cmGetAddressPresentation(vGuest.Address);
			pGuestForm.Parameters.mGuestAddress = TrimAll(StrReplace(pGuestForm.Parameters.mGuestAddress, String(vGuestAddress.Country) + ",", ""));
			
			// Trip purpose
			pGuestForm.Parameters.mTripPurpose = Upper(String(pDocument.TripPurpose));
		ElsIf TypeOfPrintForm = 3 Then
			// Guest birth place
			pGuestForm.Parameters.mGuestBirthPlaceCountry = Upper(TrimAll(vPlaceOfBirth.Country));
			pGuestForm.Parameters.mGuestBirthPlaceRegion = Upper(TrimAll(vPlaceOfBirth.Region));
			pGuestForm.Parameters.mGuestBirthPlaceArea = Upper(TrimAll(vPlaceOfBirth.Area));
			vCity = Upper(TrimAll(vPlaceOfBirth.City));
			If Find(vCity, "Г.") > 0 Then
				pGuestForm.Parameters.mGuestBirthPlaceCity = vCity;
				pGuestForm.Parameters.mGuestBirthPlaceTown = "";
			ElsIf Right(vCity, 2) = " Г" Then
				pGuestForm.Parameters.mGuestBirthPlaceCity = vCity;
				pGuestForm.Parameters.mGuestBirthPlaceTown = "";
			ElsIf Left(vCity, 2) = "Г " Then
				pGuestForm.Parameters.mGuestBirthPlaceCity = vCity;
				pGuestForm.Parameters.mGuestBirthPlaceTown = "";
			Else
				pGuestForm.Parameters.mGuestBirthPlaceCity = "";
				pGuestForm.Parameters.mGuestBirthPlaceTown = vCity;
			EndIf;
			
			// Guest address
			vGuestAddress = cmParseAddress(vGuest.Address);
			vGuestAddress.Street = StrReplace(vGuestAddress.Street, " ул.", "");
			vGuestAddress.Street = StrReplace(vGuestAddress.Street, " ул", "");
			pGuestForm.Parameters.mGuestCitizenship = Upper(String(vGuest.Citizenship));
			pGuestForm.Parameters.mGuestCountry = Upper(String(vGuestAddress.Country));
			pGuestForm.Parameters.mGuestRegion  = Upper(String(vGuestAddress.Region));
			pGuestForm.Parameters.mGuestArea = Upper(String(vGuestAddress.Area));
			vCity = Upper(TrimAll(vGuestAddress.City)); 
			If Find(vCity, "Г.") > 0 Then
				pGuestForm.Parameters.mGuestCity = vCity;
				pGuestForm.Parameters.mGuestTown = "";
			ElsIf Right(vCity, 2) = " Г" Then
				pGuestForm.Parameters.mGuestCity = vCity;
				pGuestForm.Parameters.mGuestTown = "";
			ElsIf Left(vCity, 2) = "Г " Then
				pGuestForm.Parameters.mGuestCity = vCity;
				pGuestForm.Parameters.mGuestTown = "";
			Else
				pGuestForm.Parameters.mGuestCity = "";
				pGuestForm.Parameters.mGuestTown = vCity;
			EndIf;
			pGuestForm.Parameters.mGuestStreet = Upper(String(vGuestAddress.Street));
			vAddressFullHouse = Upper(vGuestAddress.House);
			vAddressHouse = pmGetHouse(vAddressFullHouse);
			vAddressBuilding = pmGetBuilding(vAddressFullHouse);
			pGuestForm.Parameters.mGuestHouse = vAddressHouse;
			pGuestForm.Parameters.mGuestBuild = vAddressBuilding;
			pGuestForm.Parameters.mGuestApt = Upper(vGuestAddress.Flat);
		    pGuestForm.Parameters.mGuestSex = Left(vGuest.Sex, 3);
		EndIf;
		
		// Guest identity document data
		If TypeOfPrintForm = 3 Then
			pGuestForm.Parameters.mGuestIDType = Upper(TrimAll(vGuest.IdentityDocumentType));
			pGuestForm.Parameters.mGuestIDIssueDate = StrReplace(Upper(Format(vGuest.IdentityDocumentIssueDate, "L=ru_RU; DLF=DD")), "Г.", "г.");
			If ValueIsFilled(vGuest.IdentityDocumentType) And TrimAll(vGuest.IdentityDocumentType.Code) = "22" And ValueIsFilled(vGuest.IdentityDocumentValidToDate) Then
				pGuestForm.Parameters.mGuestIDValidToDate = StrReplace(Upper(Format(vGuest.IdentityDocumentValidToDate, "L=ru_RU; DLF=DD")), "Г.", "г.");
			Else
				pGuestForm.Parameters.mGuestIDValidToDate = "";
			EndIf; 
			If ValueIsFilled(pDocument.LegalRepresentative) Then
				vLR = pDocument.LegalRepresentative; 
				pGuestForm.Parameters.mLegalRepresentative1 = Upper(TrimAll(vLR.LastName));   
				pGuestForm.Parameters.mLegalRepresentative2 = Upper(TrimAll(vLR.FirstName)) + " " + Upper(TrimAll(vLR.SecondName));
				If ValueIsFilled(pDocument.RelationType) Then    
					If IsBlankString(pGuestForm.Parameters.mLegalRepresentative2) Then
						pGuestForm.Parameters.mLegalRepresentative2 = TrimAll(pDocument.RelationType);	
					Else
						pGuestForm.Parameters.mLegalRepresentative2 = pGuestForm.Parameters.mLegalRepresentative2 + ", " + TrimAll(pDocument.RelationType);	
					EndIf;	
				EndIf;	
			Else	
				pGuestForm.Parameters.mLegalRepresentative1 = "";
				pGuestForm.Parameters.mLegalRepresentative2 = "";
			EndIf;
		Else
			pGuestForm.Parameters.mGuestIDIssueDate = Format(vGuest.IdentityDocumentIssueDate, "DF=dd.MM.yyyy");
		EndIf;
		pGuestForm.Parameters.mGuestIDSeries = TrimAll(vGuest.IdentityDocumentSeries);
		pGuestForm.Parameters.mGuestIDNumber = TrimAll(vGuest.IdentityDocumentNumber);
		If TypeOfPrintForm = 3 Then
			pGuestForm.Parameters.mGuestIDUnitCode = TrimAll(vGuest.IdentityDocumentUnitCode);
			vPos = 35;
			If StrLen(TrimAll(vGuest.IdentityDocumentIssuedBy)) > 35 Then
				While vPos > 1 Do
					If Mid(TrimAll(vGuest.IdentityDocumentIssuedBy), vPos, 1) = " " Then
						Break;
					Else
						vPos = vPos - 1;
					EndIf;
				EndDo;
			EndIf;
			pGuestForm.Parameters.mGuestIDIssuedBy = TrimAll(Left(TrimAll(vGuest.IdentityDocumentIssuedBy), vPos));
			pGuestForm.Parameters.mGuestIDIssuedBy2 = TrimAll(Mid(TrimAll(vGuest.IdentityDocumentIssuedBy), vPos + 1));
		Else
			pGuestForm.Parameters.mGuestIDIssuedBy = TrimAll(?(IsBlankString(TrimAll(vGuest.IdentityDocumentUnitCode)), "", TrimAll(vGuest.IdentityDocumentUnitCode) + " ") + TrimAll(vGuest.IdentityDocumentIssuedBy));
		EndIf;
		
		// Guest identification cards
		If TypeOfPrintForm = 1 Then
			vClientCards = cmGetClientIdentificationCardsByParentDoc(pDocument);
			If vClientCards.Count() > 0 Then
				pGuestForm.Parameters.mClientIdentificationCardsLabel = "Карты гостя/Guest cards:";
				For Each vClientCardsRow In vClientCards Do
					If vClientCards.Indexof(vClientCardsRow) = 0 Then
						pGuestForm.Parameters.mClientIdentificationCards = TrimAll(vClientCardsRow.Ref.Identifier);
					Else
						pGuestForm.Parameters.mClientIdentificationCards = pGuestForm.Parameters.mClientIdentificationCards + ", " + TrimAll(vClientCardsRow.Ref.Identifier);
					EndIf;
				EndDo;
			Else
				pGuestForm.Parameters.mClientIdentificationCardsLabel = "";
				pGuestForm.Parameters.mClientIdentificationCards = "";
			EndIf;
		EndIf;
	Else
		// Guest names
		pGuestForm.Parameters.mGuestLastName = "";
		pGuestForm.Parameters.mGuestFirstName = "";
		pGuestForm.Parameters.mGuestSecondName = "";
		
		// Guest birth date
		pGuestForm.Parameters.mGuestDateOfBirth = "";
		
		If TypeOfPrintForm = 1 Then
			// Guest address
			pGuestForm.Parameters.mGuestCountry = "";
			pGuestForm.Parameters.mGuestAddress = "";
		ElsIf TypeOfPrintForm = 2 Then
			// Guest address
			pGuestForm.Parameters.mGuestCountry = "";
			pGuestForm.Parameters.mGuestAddress = "";
			
			// Guest place of birth
			pGuestForm.Parameters.mGuestBirthPlaceRegion = "";
			pGuestForm.Parameters.mGuestBirthPlaceArea = "";
			pGuestForm.Parameters.mGuestBirthPlaceCity = "";
			
			// Trip purpose
			pGuestForm.Parameters.mTripPurpose = "";
		ElsIf TypeOfPrintForm = 3 Then
			// Guest address
			pGuestForm.Parameters.mGuestCitizenship = "";
			pGuestForm.Parameters.mGuestCountry = "";
			
			// Guest place of birth
			pGuestForm.Parameters.mGuestBirthPlaceCountry = "";
			pGuestForm.Parameters.mGuestBirthPlaceRegion = "";
			pGuestForm.Parameters.mGuestBirthPlaceArea = "";
			pGuestForm.Parameters.mGuestBirthPlaceCity = "";
		EndIf;
		
		// Guest identity document data
		If TypeOfPrintForm = 3 Then
			pGuestForm.Parameters.mGuestIDType = "";
		EndIf;
		pGuestForm.Parameters.mGuestIDSeries = "";
		pGuestForm.Parameters.mGuestIDNumber = "";
		pGuestForm.Parameters.mGuestIDIssuedBy = "";
		If TypeOfPrintForm = 3 Then
			pGuestForm.Parameters.mGuestIDIssuedBy2 = "";
			pGuestForm.Parameters.mGuestIDUnitCode = "";
		EndIf;
		pGuestForm.Parameters.mGuestIDIssueDate = "";
		
		// Guest identification cards
		If TypeOfPrintForm = 1 Then
			pGuestForm.Parameters.mClientIdentificationCardsLabel = "";
			pGuestForm.Parameters.mClientIdentificationCards = "";
		EndIf;
	EndIf;
		
	// Room
	pGuestForm.Parameters.mRoom = pDocument.Room;
	
	// Guest check in and check out dates
	pGuestForm.Parameters.mCheckInDate = Format(pDocument.CheckInDate, "DF=dd.MM.yyyy");
	pGuestForm.Parameters.mCheckOutDate = Format(pDocument.CheckOutDate, "DF=dd.MM.yyyy");
	If TypeOfPrintForm = 3 Then
		pGuestForm.Parameters.mCheckInDateStr = Format(pDocument.CheckInDate, "DF=dd.MM.yyyy");
		pGuestForm.Parameters.mEmployee = SessionParameters.CurrentUser;
	EndIf;
	
	If TypeOfPrintForm = 1 Then
		// Employee
		pGuestForm.Parameters.mEmployee = SessionParameters.CurrentUser;
		
		vHotel = Undefined;
		vCompany = Undefined;
		vGuest = Undefined;
		vLanguage = Undefined;
		
		vParameters = Documents.Accommodation.FillPersonalDataConsentParameters(pDocument, vHotel, vCompany, vGuest, vLanguage, True);
		
		// Personal data processing agreement text
		vAgreementText = "";
		If ValueIsFilled(vHotel.AgreementText) Then
			vAgreementText = vParameters.mConsentText;
		Else
			vAgreementText = "Я согласен на обработку персональных данных, указанных мной в данной анкете, по правилам указанным в условиях бронирования и аннуляции отеля.
			                 |   I agree with my personal data processing according to the hotel reservation/cancellation rules.";
		EndIf;
		pGuestForm.Parameters.mAgreementText = vAgreementText;
	EndIf;
EndProcedure // SetParameters
	
// -----------------------------------------------------------------------------
Procedure PrintGuestForm(pSpreadsheet, pGuestForm, pDocument, pPutPageBreak = False, pJoin = False)
	// New page
	If pPutPageBreak Then
		pSpreadsheet.PutHorizontalPageBreak();
	EndIf;
	
	// Calculate and set parameters
	SetParameters(pGuestForm, pDocument);
	
	// Put guest card
	If pJoin Then
		pSpreadsheet.Join(pGuestForm);
	Else
		pSpreadsheet.Put(pGuestForm);
	EndIf;
	
	// Create personal data processing consent document
	If TypeOfPrintForm = 1 Then
		If ValueIsFilled(pDocument.Hotel.AgreementText) Then
			If BegOfDay(pDocument.CheckOutDate) >= BegOfDay(CurrentSessionDate()) Then
				vGuest = pDocument.Guest;
				If ValueIsFilled(vGuest) Then
					vConsentDocRef = Documents.Accommodation.GetGuestConsentDocForToday(vGuest);
					If ValueIsFilled(vConsentDocRef) Then
						vConsentDocObj = vConsentDocRef.GetObject();
					Else
						vConsentDocObj = Documents.PersonalDataProcessingConsent.CreateDocument();
						vConsentDocObj.Hotel = pDocument.Hotel;
					EndIf;
					vConsentDocObj.Fill(vGuest);
					vConsentDocObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintGuestForm

// -----------------------------------------------------------------------------
Procedure PrintGuestFormsForGuestGroup(pSpreadsheet, pGuestForm, pGuestFormR)
	If ValueIsFilled(GuestGroup) Then 
		If TypeOf(Document) = Type("DocumentRef.Reservation") Then
			vAccommodations = GuestGroup.GetObject().pmGetReservations(True, True);
		Else
			vAccommodations = GuestGroup.GetObject().pmGetAccommodations();
		EndIf;
		vPutPageBreak = False;
		vJoin = False;
		vGuestForm = pGuestForm;
		For Each vRow In vAccommodations Do
			vCurDocument = Undefined;
			If TypeOf(Document) = Type("DocumentRef.Reservation") Then
				vCurDocument = vRow.Reservation;
			Else
				vCurDocument = vRow.Accommodation;
			EndIf;
			If ValueIsFilled(vCurDocument) And ValueIsFilled(vCurDocument.AccommodationType) And 
			   Not vCurDocument.AccommodationType.DoNotIssueKeyCards Then
				If TypeOfPrintForm = 3 Then
					If Print2On1Page Then
						vPutPageBreak = False;
						If (vAccommodations.IndexOf(vRow) + 1)/2 <> Int((vAccommodations.IndexOf(vRow) + 1)/2) Then
							vPutPageBreak = True;
						Else
							vPutPageBreak = False;
						EndIf;
					Else
						vPutPageBreak = False;
						If (vAccommodations.IndexOf(vRow))/4 = Int((vAccommodations.IndexOf(vRow))/4) Then
							vPutPageBreak = True;
						Else
							vPutPageBreak = False;
						EndIf;
						vJoin = False;
						If (vAccommodations.IndexOf(vRow) + 1)/2 = Int((vAccommodations.IndexOf(vRow) + 1)/2) Then
							vJoin = True;
							vGuestForm = pGuestFormR;
						Else
							vJoin = False;
							vGuestForm = pGuestForm;
						EndIf;
					EndIf;
				EndIf;
				vDoPrint = True;
				If ValueIsFilled(RoomType) Then
					If RoomType.IsFolder Then
						If Not vCurDocument.RoomType.BelongsToItem(RoomType) Then
							vDoPrint = False;
						EndIf;
					Else
						If RoomType <> vCurDocument.RoomType Then
							vDoPrint = False;
						EndIf;
					EndIf;
				EndIf;
				If vDoPrint Then
					PrintGuestForm(pSpreadsheet, vGuestForm, vCurDocument, vPutPageBreak, vJoin);
					If Not (TypeOfPrintForm = 3 And Print2On1Page) Then
						If Not vPutPageBreak Then
							vPutPageBreak = True;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // PrintGuestFormsForGuestGroup

// -----------------------------------------------------------------------------
Procedure PrintGuestFormsForCheckInDate(pSpreadsheet, pGuestForm, pGuestFormR)
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
		|	AND NOT Reservation.AccommodationType.DoNotIssueKeyCards
		|	AND Reservation.CheckInDate >= &qBegOfDate
		|	AND Reservation.CheckInDate <= &qEndOfDate
		|	AND Reservation.Guest <> &qEmptyClient
		|	AND Reservation.Guest.Citizenship = Reservation.Hotel.Citizenship
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
		|	AND NOT Accommodation.AccommodationType.DoNotIssueKeyCards
		|	AND Accommodation.CheckInDate >= &qBegOfDate
		|	AND Accommodation.CheckInDate <= &qEndOfDate
		|	AND Accommodation.Guest <> &qEmptyClient
		|	AND Accommodation.Guest.Citizenship = Accommodation.Hotel.Citizenship
		|	AND Accommodation.Hotel = &qHotel
		|
		|ORDER BY
		|	Accommodation.CheckInDate,
		|	Accommodation.GuestGroup.Code,
		|	Accommodation.Room.SortCode,
		|	Accommodation.GuestFullName";
	EndIf;
	vQry.SetParameter("qBegOfDate", BegOfDay(CheckInDate));
	vQry.SetParameter("qEndOfDate", EndOfDay(CheckInDate));
	vQry.SetParameter("qRoomType", RoomType);
	vQry.SetParameter("qGuestGroup", GuestGroup);
	vQry.SetParameter("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qHotel", ?(ValueIsFilled(Document), Document.Hotel, SessionParameters.CurrentHotel));
	vDocs = vQry.Execute().Unload();
	vPutPageBreak = False;
	vJoin = False;
	vGuestForm = pGuestForm;
	For Each vRow In vDocs Do
		If TypeOfPrintForm = 3 Then
			If Print2On1Page Then
				vPutPageBreak = False;
				If (vDocs.IndexOf(vRow) + 1)/2 <> Int((vDocs.IndexOf(vRow) + 1)/2) Then
					vPutPageBreak = True;
				Else
					vPutPageBreak = False;
				EndIf;
			Else
				vPutPageBreak = False;
				If (vDocs.IndexOf(vRow))/4 = Int((vDocs.IndexOf(vRow))/4) Then
					vPutPageBreak = True;
				Else
					vPutPageBreak = False;
				EndIf;
				vJoin = False;
				If (vDocs.IndexOf(vRow) + 1)/2 = Int((vDocs.IndexOf(vRow) + 1)/2) Then
					vJoin = True;
					vGuestForm = pGuestFormR;
				Else
					vJoin = False;
					vGuestForm = pGuestForm;
				EndIf;
			EndIf;
		EndIf;
		PrintGuestForm(pSpreadsheet, vGuestForm, vRow.Document, vPutPageBreak, vJoin);
		If Not TypeOfPrintForm = 3 Then
			If Not vPutPageBreak Then
				vPutPageBreak = True;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // PrintGuestFormsForCheckInDate

// -----------------------------------------------------------------------------
Procedure PrintGuestFormsForRoom(pSpreadsheet, pGuestForm, pGuestFormR)
	vAccommodations = New ValueList();
	vAccommodations.Add(Document);
	If TypeOf(Document) = Type("DocumentRef.Reservation") Then
		AddOneRoomReservations(vAccommodations);
	Else		
		AddOneRoomAccommodations(vAccommodations);
	EndIf;
	vPutPageBreak = False;
	vJoin = False;
	vGuestForm = pGuestForm;
	For Each vDocItem In vAccommodations Do
		If ValueIsFilled(vDocItem.Value) And ValueIsFilled(vDocItem.Value.AccommodationType) And 
		   Not vDocItem.Value.AccommodationType.DoNotIssueKeyCards Then
			If TypeOfPrintForm = 3 Then
				If Print2On1Page Then
					vPutPageBreak = False;
					If (vAccommodations.IndexOf(vDocItem) + 1)/2 <> Int((vAccommodations.IndexOf(vDocItem) + 1)/2) Then
						vPutPageBreak = True;
					Else
						vPutPageBreak = False;
					EndIf;
				Else
					vPutPageBreak = False;
					If (vAccommodations.IndexOf(vDocItem))/4 = Int((vAccommodations.IndexOf(vDocItem))/4) Then
						vPutPageBreak = True;
					Else
						vPutPageBreak = False;
					EndIf;
					vJoin = False;
					If (vAccommodations.IndexOf(vDocItem))/2 <> Int((vAccommodations.IndexOf(vDocItem))/2) Then
						vJoin = True;
						vGuestForm = pGuestFormR;
					Else
						vJoin = False;
						vGuestForm = pGuestForm;
					EndIf;
				EndIf;
			EndIf;
			PrintGuestForm(pSpreadsheet, vGuestForm, vDocItem.Value, vPutPageBreak, vJoin);
			If Not TypeOfPrintForm = 3 Then
				If Not vPutPageBreak Then
					vPutPageBreak = True;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // PrintGuestFormsForRoom

// -----------------------------------------------------------------------------
Procedure AddOneRoomAccommodations(pDocsList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Ref <> &qDoc
	|	AND Accommodation.Room = &qRoom
	|	AND Accommodation.GuestGroup = &qGuestGroup
	|	AND Accommodation.CheckOutDate > &qCheckInDate
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|
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
	|	Reservation.Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Ref <> &qDoc
	|	AND (Reservation.Room = &qRoom
	|			OR Reservation.Number = &qNumber)
	|	AND Reservation.GuestGroup = &qGuestGroup
	|	AND Reservation.CheckOutDate > &qCheckInDate
	|	AND Reservation.Posted
	|	AND Reservation.ReservationStatus.IsActive
	|
	|ORDER BY
	|	Reservation.PointInTime";
	vQry.SetParameter("qDoc", Document);
	vQry.SetParameter("qRoom", Document.Room);
	vQry.SetParameter("qNumber", Document.Number);
	vQry.SetParameter("qGuestGroup", Document.GuestGroup);
	vQry.SetParameter("qCheckInDate", Document.CheckInDate);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		pDocsList.Add(vQryResRow.Ref);
	EndDo;
EndProcedure // AddOneRoomReservations

// -----------------------------------------------------------------------------
Procedure FillHotelParameters(pGuestForm)
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
		If TypeOfPrintForm = 1 Then
			pGuestForm.Parameters.mHotelNameRU = Upper(vHotelNameRU);
			pGuestForm.Parameters.mHotelNameEN = Upper(cmNStr(vHotel.PrintNameTranslations, Catalogs.Languages.EN));
		ElsIf TypeOfPrintForm = 3 Then
			pGuestForm.Parameters.mHotelNameRU = Upper(vHotelNameRU);
			pGuestForm.Parameters.mHotelAddress = cmGetAddressPresentation(vHotel.PostAddress);
		EndIf;
	Else
		// Hotel name
		If TypeOfPrintForm = 1 Then
			pGuestForm.Parameters.mHotelNameRU = "";
			pGuestForm.Parameters.mHotelNameEN = "";
		ElsIf TypeOfPrintForm = 3 Then
			pGuestForm.Parameters.mHotelNameRU = "";
		EndIf;
	EndIf;
EndProcedure // FillHotelParameters

#EndRegion 
