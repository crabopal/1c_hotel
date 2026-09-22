// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet, pTemplate = Undefined) Export
	// Get list of all accommodations in the group
	vAccommodations = GuestGroup.GetObject().pmGetAccommodations();
	
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("ApplicationForm");
	If pTemplate <> Undefined Then
		vTemplate = pTemplate;
	EndIf;
	
	// Header form area
	vHeader = vTemplate.GetArea("Header");
	
	// Fill header parameters
	vCompany = Undefined;
	If ValueIsFilled(Document) Then
		If ValueIsFilled(Document.Company) Then
			vCompany = Document.Company;
		EndIf;
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vCompany = SessionParameters.CurrentHotel.Company;
	EndIf;
	If ValueIsFilled(vCompany) Then
		// Company name
		vCompanyName = TrimAll(vCompany.LegacyName);
		If IsBlankString(vCompanyName) Then
			vCompanyName = TrimAll(vCompany.Description);
		EndIf;
		vHeader.Parameters.mCompanyName = vCompanyName;
	
		// Company director
		vHeader.Parameters.mCompanyDirector = TrimAll(vCompany.Director);
	Else
		// Company name
		vHeader.Parameters.mCompanyName = "";
	
		// Company director
		vHeader.Parameters.mCompanyDirector = "";
	EndIf;
	
	// Today
	vHeader.Parameters.mToday = Format(CurrentSessionDate(), "DF='dd MMMM yyyy'");
	
	// Guest
	vHeader.Parameters.mGuest = Document.Guest;
	
	// Document
	vHeader.Parameters.mDocument = Document;
	
	If ValueIsFilled(Document.Guest) Then
		// Guest name
		vHeader.Parameters.mGuestName = TrimAll(Document.Guest.LastName) + " " + 
		                                TrimAll(Document.Guest.FirstName) + " " + 
		                                TrimAll(Document.Guest.SecondName);
		
		// Guest date of birth
		vHeader.Parameters.mGuestDateOfBirth = Format(Document.Guest.DateOfBirth, "DF=dd.MM.yyyy");
		
		// Guest place of birth
		vHeader.Parameters.mGuestPlaceOfBirth = cmGetAddressPresentation(Document.Guest.PlaceOfBirth);
			
		// Guest address
		vGuestAddress = cmParseAddress(Document.Guest.Address);
		
		vHeader.Parameters.mGuestAddress1 = cmGetAddressPresentation(" " + vGuestAddress.PostCode + ", " + vGuestAddress.Region);
		vHeader.Parameters.mGuestAddress2 = cmGetAddressPresentation(" " + vGuestAddress.Area + ", " + vGuestAddress.City + ", " + 
		                                                             vGuestAddress.Street + ", " + vGuestAddress.House + ", " + vGuestAddress.Flat);
		
		// Guest identity document data
		vHeader.Parameters.mGuestIDSeries = TrimAll(Document.Guest.IdentityDocumentSeries);
		vHeader.Parameters.mGuestIDNumber = TrimAll(Document.Guest.IdentityDocumentNumber);
		vHeader.Parameters.mGuestIDIssued = Format(Document.Guest.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + " " + 
		                                    TrimAll(Document.Guest.IdentityDocumentIssuedBy);
	Else
		// Guest name
		vHeader.Parameters.mGuestName = "";
		
		// Guest date of birth
		vHeader.Parameters.mGuestDateOfBirth = "";
		
		// Guest place of birth
		vHeader.Parameters.mGuestPlaceOfBirth = "";
			
		// Guest address
		vHeader.Parameters.mGuestAddress1 = "";
		vHeader.Parameters.mGuestAddress2 = "";
		
		// Guest identity document data
		vHeader.Parameters.mGuestIDSeries = "";
		vHeader.Parameters.mGuestIDNumber = "";
		vHeader.Parameters.mGuestIDIssued = "";
	EndIf;
		
	// Room type
	vHeader.Parameters.mRoomType = Document.RoomType;
		
	// Number of persons
	vNumberOfPersons = 0;
	For Each vRow In vAccommodations Do
		vNumberOfPersons = vNumberOfPersons + vRow.Accommodation.NumberOfPersons;
	EndDo;
	vHeader.Parameters.mNumberOfPersons = vNumberOfPersons;
	
	// Guest check in and check out dates
	vHeader.Parameters.mCheckInDate = Format(Document.CheckInDate, "DF=dd.MM.yyyy");
	vHeader.Parameters.mCheckOutDate = Format(Document.CheckOutDate, "DF=dd.MM.yyyy");
	
	// Duration
	vHeader.Parameters.mDuration = Format(Document.Duration, "ND=4; NZ=");
	
	// Put header
	pSpreadsheet.Put(vHeader);
	
	// Process all other documents in the group	
	If vAccommodations.Count() > 1 Then
		// Guest group header
		vGuestGroup = vTemplate.GetArea("GuestGroup");
		
		// Put guest group header
		pSpreadsheet.Put(vGuestGroup);
		
		// Guest in group
		vGuest = vTemplate.GetArea("Guest");
		
		// Process documents in guest group
		vLineNumber = 0;
		For Each vRow In vAccommodations Do
			vDocument = vRow.Accommodation;
			// Skip document on a form
			If vDocument <> Document Then
				// Line number
				vLineNumber = vLineNumber + 1;
				vGuest.Parameters.mLineNumber = vLineNumber;
				
				// Document
				vGuest.Parameters.mDocument = vDocument;
				
				// Guest
				vGuest.Parameters.mGuest = vDocument.Guest;
				
				If ValueIsFilled(vDocument.Guest) Then
					vGuest.Parameters.mGuestName = TrimAll(vDocument.Guest.LastName) + " " + 
												   TrimAll(vDocument.Guest.FirstName) + " " + 
												   TrimAll(vDocument.Guest.SecondName);
				Else
					vGuest.Parameters.mGuestName = "";
				EndIf;
				
				// Put guest in guest group
				pSpreadsheet.Put(vGuest);
			EndIf;
		EndDo;
	EndIf;
	
	// Header form area
	vFooter = vTemplate.GetArea("Footer");
	
	// Today
	vFooter.Parameters.mToday = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");
	
	// Put footer
	pSpreadsheet.Put(vFooter);
EndProcedure // pmGenerate
