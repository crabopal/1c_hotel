// -----------------------------------------------------------------------------
Procedure SetParameters(pTemplate, pDocument, pSpreadsheet)
	pGuestForm = pTemplate.GetArea("RegistrationForm");
	FillHotelParameters(pGuestForm);
	// Get hotel
	vHotel = pDocument.Hotel;
	vRoomRate = pDocument.RoomRate;
	If Not IsBlankString(vRoomRate.ReservationConditions) Then
		pGuestForm.Parameters.mReservationConditions = cmNStr(vRoomRate.ReservationConditions, SessionParameters.CurrentLanguage);
	Else
		pGuestForm.Parameters.mReservationConditions = cmNStr(vHotel.ReservationConditions, SessionParameters.CurrentLanguage);
	EndIf;
	
	// Personal data processing agreement text
	vHotelP = Undefined;
	vCompanyP = Undefined;
	vGuestP = Undefined;
	vLanguageP = Undefined;
	
	vParameters = Documents.Accommodation.FillPersonalDataConsentParameters(pDocument, vHotelP, vCompanyP, vGuestP, vLanguageP, True);
	pGuestForm.Parameters.mAgreementText = vParameters.mConsentText;
	
	// Document
	pGuestForm.Parameters.mGuestGroup = Format(pDocument.GuestGroup.Code, "ND=12; NFD=; NG=");
	pGuestForm.Parameters.mDateAndTime = Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'");
	
	// Guest
	If ValueIsFilled(pDocument.Guest) Then
		vGuest = pDocument.Guest;
		vGuestObj = vGuest.GetObject();
		
		// Title
		vTitle = "";
		If Not IsBlankString(TrimAll(vGuest.Title)) And Not IsBlankString(TrimAll(vGuest.Salutation)) And 
		   Left(UPPER(TrimAll(vGuest.Title)), 2) = Left(UPPER(TrimAll(vGuest.Salutation)), 2) Then
			vTitle = TrimAll(vGuest.Title);
		Else
			vTitle = TrimAll(TrimAll(vGuest.Title) + " " + TrimAll(vGuest.Salutation));
		EndIf;
		If Not IsBlankString(vTitle) Then
			pGuestForm.Parameters.mTitle = vTitle + " ";
		Else
			pGuestForm.Parameters.mTitle = "";
		EndIf;
		
		// Guest names
		pGuestForm.Parameters.mLastName = Title(TrimAll(vGuest.LastName));
		pGuestForm.Parameters.mFirstName = Title(TrimAll(vGuest.FirstName));
		pGuestForm.Parameters.mSecondName = Title(TrimAll(vGuest.SecondName));
		
		// Guest birth date
		pGuestForm.Parameters.mBirthDate = Format(vGuest.DateOfBirth, "DF=dd.MM.yyyy");
		
		// Guest identity document data
		If ValueIsFilled(vGuest.IdentityDocumentType) Then
			pGuestForm.Parameters.mIDType = TrimAll(vGuest.IdentityDocumentType);
		Else
			pGuestForm.Parameters.mIDType = cmNStr("en='Passport'; ru='Паспорт'; de='Pass'", SessionParameters.CurrentLanguage);
		EndIf;
		vIDNumber = TrimAll(TrimAll(vGuest.IdentityDocumentSeries) + " " + TrimAll(vGuest.IdentityDocumentNumber));
		If IsBlankString(vIDNumber) Then
			pGuestForm.Parameters.mIDNumber = "                              ";
		Else
			pGuestForm.Parameters.mIDNumber = vIDNumber;
		EndIf;
		pGuestForm.Parameters.mIDIssuedBy = TrimAll(vGuest.IdentityDocumentIssuedBy);
		pGuestForm.Parameters.mIDIssueDate = Format(vGuest.IdentityDocumentIssueDate, "DF=dd.MM.yyyy");
		
		// Address
		pGuestForm.Parameters.mAddress = cmGetAddressPresentation(vGuest.Address);
		pGuestForm.Parameters.mCitizenship = TrimAll(vGuest.Citizenship);
		
		// Profession
		pGuestForm.Parameters.mProfession = TrimAll(vGuest.PlaceOfEmployment);
		
		// Contacts
		pGuestForm.Parameters.mPhone = TrimAll(vGuest.Phone);
		pGuestForm.Parameters.mEMail = TrimAll(vGuest.EMail);
		
		// Number of previous visits
		vNumberOfPrevVisits = vGuestObj.pmCountNumberOfCheckIns('00010101', BegOfDay(pDocument.CheckInDate)-1);
		pGuestForm.Parameters.mNumberOfCheckIns = Format(vNumberOfPrevVisits, "NFD=; NG=");
	Else
		// Title
		pGuestForm.Parameters.mTitle = "";
		
		// Guest names
		pGuestForm.Parameters.mLastName = "";
		pGuestForm.Parameters.mFirstName = "";
		pGuestForm.Parameters.mSecondName = "";
		
		// Guest birth date
		pGuestForm.Parameters.mBirthDate = "";
		
		// Guest identity document data
		pGuestForm.Parameters.mIDType = cmNStr("en='Passport'; ru='Паспорт'; de='Pass'", SessionParameters.CurrentLanguage);
		pGuestForm.Parameters.mIDNumber = "                              ";
		pGuestForm.Parameters.mIDIssuedBy = "";
		pGuestForm.Parameters.mIDIssueDate = "";
		
		// Address
		pGuestForm.Parameters.mAddress = "";
		pGuestForm.Parameters.mCitizenship = "";
		
		// Profession
		pGuestForm.Parameters.mProfession = "";
		
		// Contacts
		pGuestForm.Parameters.mPhone = "";
		pGuestForm.Parameters.mEMail = "";
		
		// Number of previous visits
		pGuestForm.Parameters.mNumberOfCheckIns = "";
	EndIf;
	
	// Add room
	If ValueIsFilled(pDocument.Room) Then
		pGuestForm.Parameters.mRoom = TrimAll(pDocument.Room);
	Else
		pGuestForm.Parameters.mRoom = "";
	EndIf;
	
	// Add terms
	If ValueIsFilled(pDocument.ServicePackage) Then
		pGuestForm.Parameters.mTerms = TrimAll(pDocument.ServicePackage);
	Else
		pGuestForm.Parameters.mTerms = "";
	EndIf;
	
	// Guest check in and check out dates
	pGuestForm.Parameters.mCheckInDate = Format(pDocument.CheckInDate, "DF=dd.MM.yyyy");
	pGuestForm.Parameters.mCheckOutDate = Format(pDocument.CheckOutDate, "DF=dd.MM.yyyy");
	
	// Add other room guests
	If TypeOf(pDocument) = Type("DocumentRef.Reservation") Then
		vOtherGuests = cmGetOneRoomReservations(pDocument.Number, pDocument.GuestGroup, pDocument.CheckInDate, pDocument.CheckOutDate, False);
	Else
		vOtherGuests = cmGetOneRoomAccommodations(pDocument.Room, pDocument.GuestGroup, pDocument.CheckInDate, pDocument.CheckOutDate);
	EndIf;
	i = 0;
	For Each vGuestRow In vOtherGuests Do
		vDoc = vGuestRow.Ref;
		If vDoc <> pDocument Then
			i = i + 1;
			If i > 8 Then
				Break;
			EndIf;
			vGuestN = vDoc.Guest;
			If ValueIsFilled(vGuestN) Then
				pGuestForm.Parameters["mLastName"+i] = TrimAll(vGuestN.LastName);
				pGuestForm.Parameters["mFirstName"+i] = TrimAll(TrimAll(vGuestN.FirstName) + " " + TrimAll(vGuestN.SecondName));
				If ValueIsFilled(vGuestN.DateOfBirth) Then
					pGuestForm.Parameters["mBirthDate"+i] = Format(vGuestN.DateOfBirth, "DF=dd.MM.yyyy");
				Else
					pGuestForm.Parameters["mBirthDate"+i] = "";
				EndIf;
				pGuestForm.Parameters["mIDNumber"+i] = TrimAll(TrimAll(vGuestN.IdentityDocumentSeries) + " " + TrimAll(vGuestN.IdentityDocumentNumber));
				If ValueIsFilled(vGuestN.Sex) Then
					If vGuestN.Sex = Enums.Sex.Male Then
						pGuestForm.Parameters["mSex"+i] = cmNStr("en='M'; ru='М'; de='M'", SessionParameters.CurrentLanguage);
					Else
						pGuestForm.Parameters["mSex"+i] = cmNStr("en='F'; ru='Ж'; de='F'", SessionParameters.CurrentLanguage);
					EndIf;
				Else
					pGuestForm.Parameters["mSex"+i] = "";
				EndIf;
			Else
				pGuestForm.Parameters["mLastName"+i] = "";
				pGuestForm.Parameters["mFirstName"+i] = "";
				pGuestForm.Parameters["mBirthDate"+i] = "";
				pGuestForm.Parameters["mIDNumber"+i] = "";
				pGuestForm.Parameters["mSex"+i] = "";
			EndIf;
		EndIf;
	EndDo; 
	// Put guest card
	pSpreadsheet.Put(pGuestForm);
EndProcedure // SetParameters

// -----------------------------------------------------------------------------
Procedure SetParameters3(pTemplate, pDocument, pSpreadsheet) 
	pGuestForm = pTemplate.GetArea("RegistrationForm");
	FillHotelParameters(pGuestForm);
	// Get hotel
	vHotel = Undefined;
	If ValueIsFilled(pDocument) Then
		If ValueIsFilled(pDocument.Hotel) Then
			vHotel = pDocument.Hotel;
		EndIf;
	ElsIf ValueIsFilled(GuestGroup) Then
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			vHotel = SessionParameters.CurrentHotel;
		EndIf;
	EndIf;
	
	// Document
	pGuestForm.Parameters.mDocNumber = cmGetDocumentNumberPresentation(pDocument.Number);
	pGuestForm.Parameters.mDocDate = Format(pDocument.Date, "DLF=DD");
	
	// Guest
	If ValueIsFilled(pDocument.Guest) Then
		// Guest names
		pGuestForm.Parameters.mLastName = Upper(TrimAll(pDocument.Guest.LastName));
		pGuestForm.Parameters.mFirstName = Upper(TrimAll(pDocument.Guest.FirstName));
		pGuestForm.Parameters.mSecondName = Upper(TrimAll(pDocument.Guest.SecondName));
		
		// Guest birth date
		pGuestForm.Parameters.mBirthDate = Format(pDocument.Guest.DateOfBirth, "DF=dd.MM.yyyy");
		
		// Guest place of birth
		pGuestForm.Parameters.mBirthPlace = cmGetAddressPresentation(pDocument.Guest.PlaceOfBirth);
		
		// Children
		pGuestForm.Parameters.mChildren = TrimAll(pDocument.Guest.Children);
		
		// Guest identity document data
		pGuestForm.Parameters.mIDType = TrimAll(pDocument.Guest.IdentityDocumentType);
		pGuestForm.Parameters.mIDSeries = TrimAll(pDocument.Guest.IdentityDocumentSeries);
		pGuestForm.Parameters.mIDNumber = TrimAll(pDocument.Guest.IdentityDocumentNumber);
		pGuestForm.Parameters.mIDIssuedBy = TrimAll(pDocument.Guest.IdentityDocumentIssuedBy);
		pGuestForm.Parameters.mIDIssueDate = Format(pDocument.Guest.IdentityDocumentIssueDate, "DF=dd.MM.yyyy");
	Else
		// Guest names
		pGuestForm.Parameters.mLastName = "";
		pGuestForm.Parameters.mFirstName = "";
		pGuestForm.Parameters.mSecondName = "";
		
		// Guest birth date
		pGuestForm.Parameters.mBirthDate = "";
		
		// Guest place of birth
		pGuestForm.Parameters.mBirthPlace = "";
		
		// Children
		pGuestForm.Parameters.mChildren = "";
		
		// Guest identity document data
		pGuestForm.Parameters.mIDType = "";
		pGuestForm.Parameters.mIDSeries = "";
		pGuestForm.Parameters.mIDNumber = "";
		pGuestForm.Parameters.mIDIssuedBy = "";
		pGuestForm.Parameters.mIDIssueDate = "";
	EndIf;
	
	// Hotel address
	vHotelAddressRU = cmNStr(vHotel.PostAddressTranslations, Catalogs.Languages.RU);
	If IsBlankString(vHotelAddressRU) Then
		vHotelAddressRU = TrimAll(vHotel.PostAddress);
	EndIf;
	vHotelAddressRU = cmGetAddressPresentation(vHotelAddressRU);
	
	// Add room
	If ValueIsFilled(pDocument.Room) Then
		vHotelAddressRU = vHotelAddressRU + ", комната " + TrimAll(pDocument.Room);
	EndIf;
	
	// Set hotel address and room
	pGuestForm.Parameters.mHotelAddressAndRoom = vHotelAddressRU;
	
	// Guest check in and check out dates
	pGuestForm.Parameters.mCheckInDate = Format(pDocument.CheckInDate, "DLF=DD");
	pGuestForm.Parameters.mCheckOutDate = Format(pDocument.CheckOutDate, "DLF=DD");
	
	// Employee
	pGuestForm.Parameters.mEmployee = SessionParameters.CurrentUser;
	// Put guest card
	pSpreadsheet.Put(pGuestForm);
EndProcedure // SetParameters3

// -----------------------------------------------------------------------------
Procedure SetParameters9(pTemplate, pDocument, pSpreadsheet)
	pGuestForm = pTemplate.GetArea("RegistrationForm");
	FillHotelParameters(pGuestForm);
	// Document
	pGuestForm.Parameters.mDocNumber = cmGetDocumentNumberPresentation(pDocument.Number);
	pGuestForm.Parameters.mDocDate = Format(pDocument.Date, "DLF=DD");
	
	// Guest
	If ValueIsFilled(pDocument.Guest) Then
		// Guest names
		pGuestForm.Parameters.mLastName = Upper(TrimAll(pDocument.Guest.LastName));
		pGuestForm.Parameters.mFirstName = Upper(TrimAll(pDocument.Guest.FirstName));
		pGuestForm.Parameters.mSecondName = Upper(TrimAll(pDocument.Guest.SecondName));
		
		// Guest birth date
		pGuestForm.Parameters.mBirthDate = Format(pDocument.Guest.DateOfBirth, "DF=dd.MM.yyyy");
	Else
		// Guest names
		pGuestForm.Parameters.mLastName = "";
		pGuestForm.Parameters.mFirstName = "";
		pGuestForm.Parameters.mSecondName = "";
		
		// Guest birth date
		pGuestForm.Parameters.mBirthDate = "";
	EndIf;
	
	// Add room
	If ValueIsFilled(pDocument.Room) Then
		pGuestForm.Parameters.mRoom = TrimAll(pDocument.Room);
	Else
		pGuestForm.Parameters.mRoom = "";
	EndIf;
	
	// Guest check in and check out dates
	pGuestForm.Parameters.mRegistrationType = "";
	pGuestForm.Parameters.mCheckInDate = Format(pDocument.CheckInDate, "DLF=DD");
	pGuestForm.Parameters.mCheckOutDate = Format(pDocument.CheckOutDate, "DLF=DD");
	
	// Current date
	pGuestForm.Parameters.mCurrentDate = Format(CurrentSessionDate(), "DLF=DD");
	
	// Employee
	pGuestForm.Parameters.mEmployee = SessionParameters.CurrentUser;
	// Put guest card
	pSpreadsheet.Put(pGuestForm);
EndProcedure // SetParameters9
	
// -----------------------------------------------------------------------------
Procedure PrintGuestRegistrationForm(pSpreadsheet, pTemplate, pDocument, pPutPageBreak = False)
	// New page
	If pPutPageBreak Then
		pSpreadsheet.PutHorizontalPageBreak();
	EndIf;
	
	// Calculate and set parameters
	If TypeOfPrintForm = 9 Then
		SetParameters9(pTemplate, pDocument, pSpreadsheet);
	ElsIf TypeOfPrintForm = 3 Then
		SetParameters3(pTemplate, pDocument, pSpreadsheet);
	Else
		SetParameters(pTemplate, pDocument, pSpreadsheet);
	EndIf;
	
	// Create personal data processing consent document
	If TypeOfPrintForm = 0 Then
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
EndProcedure // PrintGuestRegistrationForm

// -----------------------------------------------------------------------------
Procedure PrintGuestFormsForCheckInDate(pSpreadsheet, pTemplate)
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
		|	AND Reservation.AccommodationType.Type = &qRoom
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
		|	AND Accommodation.AccommodationType.Type = &qRoom
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
	vQry.SetParameter("qRoom", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qHotel", ?(ValueIsFilled(Document), Document.Hotel, SessionParameters.CurrentHotel));
	vDocs = vQry.Execute().Unload();
	vIsFirstDoc = True;
	For Each vRow In vDocs Do
		PrintGuestRegistrationForm(pSpreadsheet, pTemplate, vRow.Document, Not vIsFirstDoc);
		If vIsFirstDoc Then
			vIsFirstDoc = False;
		EndIf;
	EndDo;
EndProcedure // PrintGuestFormsForCheckInDate

// -----------------------------------------------------------------------------
Procedure PrintGuestFormsForGuestGroup(pSpreadsheet, pTemplate)
	If ValueIsFilled(GuestGroup) Then
		If TypeOf(Document) = Type("DocumentRef.Accommodation") Then
			vAccommodations = GuestGroup.GetObject().pmGetAccommodations();
			vIsFirstDoc = True;
			For Each vRow In vAccommodations Do
				If ValueIsFilled(vRow.Accommodation) And ValueIsFilled(vRow.Accommodation.AccommodationType) And 
				   vRow.Accommodation.AccommodationType.Type = Enums.AccomodationTypes.Room Then
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
						PrintGuestRegistrationForm(pSpreadsheet, pTemplate, vRow.Accommodation, Not vIsFirstDoc);
						If vIsFirstDoc Then
							vIsFirstDoc = False;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		Else
			vReservations = GuestGroup.GetObject().pmGetReservations(True, True);
			vIsFirstDoc = True;
			For Each vRow In vReservations Do
				If ValueIsFilled(vRow.Reservation) And ValueIsFilled(vRow.Reservation.AccommodationType) And 
				   vRow.Reservation.AccommodationType.Type = Enums.AccomodationTypes.Room Then
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
						PrintGuestRegistrationForm(pSpreadsheet, pTemplate, vRow.Reservation, Not vIsFirstDoc);
						If vIsFirstDoc Then
							vIsFirstDoc = False;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // PrintGuestFormsForGuestGroup

// -----------------------------------------------------------------------------
Procedure FillHotelParameters(pGuestForm)
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(Document) Then
		If ValueIsFilled(Document.Hotel) Then
			vHotel = Document.Hotel;
		EndIf;
	ElsIf ValueIsFilled(GuestGroup) Then
		vHotel = GuestGroup.Owner;
	EndIf;
	If TypeOfPrintForm = 9 Then
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
			pGuestForm.Parameters.mHotelName = vHotelNameRU;
			
			// Hotel phones
			vHotelPhonesRU = TrimAll(vHotel.Phones);
			
			// Hotel address
			vHotelAddress = cmParseAddress(vHotel.PostAddress);
			pGuestForm.Parameters.mHotelAddress = cmGetAddressPresentation(TrimAll(vHotelAddress.PostCode) + ", " + TrimAll(vHotelAddress.Region) + ", " + TrimAll(vHotelAddress.Area) + ", " + TrimAll(vHotelAddress.City) + ", " + TrimAll(vHotelAddress.Street));
			pGuestForm.Parameters.mHotelAddressHouse = TrimAll(vHotelAddress.House);
			pGuestForm.Parameters.mHotelAddressBuilding = "";
			pGuestForm.Parameters.mHotelPhones = vHotelPhonesRU;
		Else
			pGuestForm.Parameters.mHotelName = "";
			pGuestForm.Parameters.mHotelAddress = "";
			pGuestForm.Parameters.mHotelAddressHouse = "";
			pGuestForm.Parameters.mHotelAddressBuilding = "";
			pGuestForm.Parameters.mHotelPhones = "";
		EndIf;
	ElsIf TypeOfPrintForm = 3 Then
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
			
			// Hotel phones
			vHotelPhonesRU = TrimAll(vHotel.Phones);
			
			pGuestForm.Parameters.mHotelName = vHotelNameRU;
			pGuestForm.Parameters.mHotelPhones = vHotelPhonesRU;
		Else
			pGuestForm.Parameters.mHotelName = "";
			pGuestForm.Parameters.mHotelPhones = "";
		EndIf;
	Else
		If ValueIsFilled(vHotel) Then
			// Hotel name
			vHotelName = cmNStr(vHotel.PrintNameTranslations, SessionParameters.CurrentLanguage);
			If IsBlankString(vHotelName) Then
				vHotelName = TrimAll(vHotel.PrintName);
			EndIf;
			If IsBlankString(vHotelName) Then
				vHotelName = TrimAll(vHotel.LegacyName);
			EndIf;
			If IsBlankString(vHotelName) Then
				vHotelName = TrimAll(vHotel.Description);
			EndIf;
			pGuestForm.Parameters.mHotelName = vHotelName;
		Else
			pGuestForm.Parameters.mHotelName = "";
		EndIf;
	EndIf;
EndProcedure // FillHotelParameters

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet, pTemplate = Undefined) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = Undefined;
	If TypeOfPrintForm = 3 Then
		vTemplate = ThisObject.GetTemplate("RegistrationFormRu3");
	ElsIf TypeOfPrintForm = 9 Then
		vTemplate = ThisObject.GetTemplate("RegistrationFormRu9");
	Else
		vTemplate = ThisObject.GetTemplate("RegistrationForm");
	EndIf;
	If pTemplate <> Undefined Then
		vTemplate = pTemplate;
	EndIf;
	
	// Call processings	
	If ValueIsFilled(CheckInDate) Then
		PrintGuestFormsForCheckInDate(pSpreadsheet, vTemplate);
	ElsIf ValueIsFilled(GuestGroup) Then
		PrintGuestFormsForGuestGroup(pSpreadsheet, vTemplate);
	ElsIf ValueIsFilled(Document) Then
		PrintGuestRegistrationForm(pSpreadsheet, vTemplate, Document, False);
	EndIf;
EndProcedure // pmGenerate
