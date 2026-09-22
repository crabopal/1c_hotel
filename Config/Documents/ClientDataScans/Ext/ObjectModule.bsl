
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	If AdditionalProperties.Property("LinksRestoreMode") And AdditionalProperties.LinksRestoreMode Then
		Return;
	EndIf;
	// Update reservation if it is checked-in already
	If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
		vAccRef = cmGetAccommodationByReservation(ParentDoc);
		If ValueIsFilled(vAccRef) Then
			ParentDoc = vAccRef;
		EndIf;
	EndIf;
	// Create guest if it is missing
	If Not ValueIsFilled(Guest) And ValueIsFilled(ParentDoc) Then
		vCltObj = Catalogs.Clients.CreateItem();
		vCltObj.pmFillAttributesWithDefaultValues();
		vCltObj.Parent = Catalogs.Clients.CheckedInGuests;
		vCltObj.Write();
		Guest = vCltObj.Ref;
	EndIf;
	If Modified() Then
		Write(DocumentWriteMode.Write);
	EndIf;
	// Update guest data if there are changes
	vNeedToRecalculateServices = False;
	If ValueIsFilled(Guest) Then
		vGuestObj = Guest.GetObject();
		If Not IsBlankString(LastName) Then
			If vGuestObj.LastName <> LastName Then
				vGuestObj.LastName = LastName;
				vGuestObj.FullName = vGuestObj.pmGetFullName();
			EndIf;
		EndIf;
		If Not IsBlankString(FirstName) Then
			If vGuestObj.FirstName <> FirstName Then
				vGuestObj.FirstName = FirstName;
				vGuestObj.FullName = vGuestObj.pmGetFullName();
			EndIf;
		EndIf;
		If Not IsBlankString(SecondName) Then
			If vGuestObj.SecondName <> SecondName Then
				vGuestObj.SecondName = SecondName;
				vGuestObj.FullName = vGuestObj.pmGetFullName();
			EndIf;
		EndIf;
		If ValueIsFilled(Sex) Then
			If vGuestObj.Sex <> Sex Then
				vGuestObj.Sex = Sex;
			EndIf;
		EndIf;
		If ValueIsFilled(Citizenship) Then
			If vGuestObj.Citizenship <> Citizenship Then
				vGuestObj.Citizenship = Citizenship;
				vNeedToRecalculateServices = True;
			EndIf;
		EndIf;
		If ValueIsFilled(DateOfBirth) Then
			If vGuestObj.DateOfBirth <> DateOfBirth Then
				vGuestObj.DateOfBirth = DateOfBirth;
				vNeedToRecalculateServices = True;
			EndIf;
		EndIf;
		If Not IsBlankString(PlaceOfBirth) Then
			If TrimAll(vGuestObj.PlaceOfBirth) <> TrimAll(PlaceOfBirth) Then
				vGuestObj.PlaceOfBirth = PlaceOfBirth;
			EndIf;
		EndIf;
		If Not IsBlankString(Address) Then
			If TrimAll(vGuestObj.Address) <> TrimAll(Address) Then
				vGuestObj.Address = Address;    
				vGuestObj.StreetFiasId = StreetFiasId;
				vNeedToRecalculateServices = True;
			EndIf;
		EndIf;
		If ValueIsFilled(IdentityDocumentType) Then
			If vGuestObj.IdentityDocumentType <> IdentityDocumentType Then
				vGuestObj.IdentityDocumentType = IdentityDocumentType;
			EndIf;
		EndIf;
		If Not IsBlankString(IdentityDocumentNumber) Then
			If TrimAll(vGuestObj.IdentityDocumentNumber) <> TrimAll(IdentityDocumentNumber) Then
				vGuestObj.IdentityDocumentNumber = IdentityDocumentNumber;
			EndIf;
		EndIf;
		If Not IsBlankString(IdentityDocumentSeries) Then
			If TrimAll(vGuestObj.IdentityDocumentSeries) <> TrimAll(IdentityDocumentSeries) Then
				vGuestObj.IdentityDocumentSeries = IdentityDocumentSeries;
			EndIf;
		EndIf;
		If Not IsBlankString(IdentityDocumentUnitCode) Then
			If TrimAll(vGuestObj.IdentityDocumentUnitCode) <> TrimAll(IdentityDocumentUnitCode) Then
				vGuestObj.IdentityDocumentUnitCode = IdentityDocumentUnitCode;
			EndIf;
		EndIf;
		If Not IsBlankString(IdentityDocumentIssuedBy) Then
			If TrimAll(vGuestObj.IdentityDocumentIssuedBy) <> TrimAll(IdentityDocumentIssuedBy) Then
				vGuestObj.IdentityDocumentIssuedBy = IdentityDocumentIssuedBy;
			EndIf;
		EndIf;
		If ValueIsFilled(IdentityDocumentIssueDate) Then
			If vGuestObj.IdentityDocumentIssueDate <> IdentityDocumentIssueDate Then
				vGuestObj.IdentityDocumentIssueDate = IdentityDocumentIssueDate;
			EndIf;
		EndIf;
		If ValueIsFilled(IdentityDocumentValidToDate) Then
			If vGuestObj.IdentityDocumentValidToDate <> IdentityDocumentValidToDate Then
				vGuestObj.IdentityDocumentValidToDate = IdentityDocumentValidToDate;
			EndIf;
		EndIf;
		If ValueIsFilled(AddressRegistrationDate) Then
			If vGuestObj.AddressRegistrationDate <> AddressRegistrationDate Then
				vGuestObj.AddressRegistrationDate = AddressRegistrationDate;
			EndIf;
		EndIf;
		vPhoto = Photo.Get();
		vGuestPhoto = vGuestObj.Photo.Get();
		If vPhoto <> vGuestPhoto Then
			If vPhoto <> Undefined Then
				vGuestObj.Photo = New ValueStorage(vPhoto);
			Else
				vGuestObj.Photo = Undefined;
			EndIf;
		EndIf;
		vSignature = Signature.Get();
		vGuestSignature = vGuestObj.Signature.Get();
		If vSignature <> vGuestSignature Then
			If vSignature <> Undefined Then
				vGuestObj.Signature = New ValueStorage(vSignature);
			Else
				vGuestObj.Signature = Undefined;
			EndIf;
		EndIf;
		// Check that guest object was changed
		If vGuestObj.Modified() Then
			vGuestObj.Write();
			// Write to guest change history
			vGuestObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndIf;
	If Not AdditionalProperties.Property("OperationSource") Or 
	   AdditionalProperties.Property("OperationSource") And AdditionalProperties.OperationSource <> "ForeignerRegistryRecord" Then
		// Update accommodation data if there are changes
		If ValueIsFilled(ParentDoc) Then
			vAccObj = ParentDoc.GetObject();
			// Guest full name
			If ValueIsFilled(Guest) Then
				If vAccObj.Guest <> Guest Then
					vAccObj.Guest = Guest;
				EndIf;
				If vAccObj.GuestFullName <> Guest.FullName Then
					vAccObj.GuestFullName = Guest.FullName;
				EndIf;
			EndIf;
			// Trip purpose
			If ValueIsFilled(TripPurpose) Then
				If vAccObj.TripPurpose <> TripPurpose Then
					vAccObj.TripPurpose = TripPurpose;
				EndIf;
			EndIf;
			// Recalculate transactions if status is processed
			If Status = Enums.ScanStatuses.IsProcessed Then
				If TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
					// Let's try to find accommodation and recalculate services.
					vQry = New Query();
					vQry.Text = 
					"SELECT
					|	Accommodation.Ref AS Ref
					|FROM
					|	Document.Accommodation AS Accommodation
					|WHERE
					|	Accommodation.ParentDoc = &qParentDoc
					|	AND Accommodation.Posted = TRUE
					|	AND Accommodation.AccommodationStatus.IsActive = TRUE
					|	AND Accommodation.AccommodationStatus.IsInHouse = TRUE
					|
					|ORDER BY
					|	Accommodation.PointInTime";
					vQry.SetParameter("qParentDoc", ParentDoc);
					vAccs = vQry.Execute();
					If Not vAccs.IsEmpty() Then
						vListvAcc = vAccs.Select();
						While vListvAcc.Next() Do
						    vObj = vListvAcc.Ref.GetObject();
							If ValueIsFilled(Guest) Then
								If vObj.Guest <> Guest Then
									vObj.Guest = Guest;
								EndIf;
								If vObj.GuestFullName <> Guest.FullName Then
									vObj.GuestFullName = Guest.FullName;
								EndIf;
							EndIf;
							If ValueIsFilled(TripPurpose) Then
								If vObj.TripPurpose <> TripPurpose Then
									vObj.TripPurpose = TripPurpose;
								EndIf;
							EndIf;
							If vNeedToRecalculateServices Then
								vObj.pmCalculateServices();
							ENdIf;
							vObj.AdditionalProperties.Insert("OperationSource", "ClientDataScans");
							vObj.Write(DocumentWriteMode.Posting);
							// Write to accommodation change history
							vObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
						EndDo; 
					EndIf;	
				EndIf;
			EndIf;
			// Check that accommodation object was changed
			If vAccObj.Modified() Then
				If vNeedToRecalculateServices Then
					vAccObj.pmCalculateServices();
				ENdIf;
				vAccObj.AdditionalProperties.Insert("OperationSource", "ClientDataScans");
				vAccObj.Write(DocumentWriteMode.Posting);
				If TypeOf(vAccObj.Ref) = Type("DocumentRef.Reservation") Then
					// Write to accommodation change history
					vAccObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				Else
					// Write to accommodation change history
					vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndIf;
		// Update foreigner registry records
		If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") And Status = Enums.ScanStatuses.IsProcessed Then
			vFRRs = ParentDoc.GetObject().pmGetForeignerRegistryRecords();
			If vFRRs <> Undefined And vFRRs.Count() > 0 Then
				j = vFRRs.Count() - 1;
				vFRRsRow = vFRRs.Get(j);
				vFRRObj = vFRRsRow.ForeignerRegistryRecord.GetObject();
				If ValueIsFilled(Guest) Then
					vFRRObj.Guest = Guest;
					FillPropertyValues(vFRRObj, Guest, , "LastName, FirstName, SecondName, Author, Remarks");
				EndIf;
				If Not IsBlankString(LastNameRu) And Not cmIsInLat(LastNameRu) Then
					vFRRObj.LastName = LastNameRu;
				EndIf;
				If Not IsBlankString(FirstNameRu) And Not cmIsInLat(FirstNameRu) Then
					vFRRObj.FirstName = FirstNameRu;
				EndIf;
				If Not IsBlankString(SecondNameRu) And Not cmIsInLat(SecondNameRu) Then
					vFRRObj.SecondName = SecondNameRu;
				EndIf;
				If ValueIsFilled(TripPurpose) Then
					vFRRObj.TripPurpose = TripPurpose;
				EndIf;
				If Not IsBlankString(Profession) Then
					vFRRObj.Profession = Profession;
				EndIf;
				If Not IsBlankString(Standing) Then
					vFRRObj.Standing = Standing;
				EndIf;
				If Not IsBlankString(ArrivedFrom) Then
					vFRRObj.ArrivedFrom = ArrivedFrom;
				EndIf;
				If IsFromAbroad Then
					vFRRObj.IsFromAbroad = IsFromAbroad;
				EndIf;
				If Not IsBlankString(MigrationCardNumber) Then
					vFRRObj.MigrationCardNumber = MigrationCardNumber;
				EndIf;
				If ValueIsFilled(MigrationCardDateFrom) Then
					vFRRObj.MigrationCardDateFrom = MigrationCardDateFrom;
				EndIf;
				If ValueIsFilled(MigrationCardDateTo) Then
					vFRRObj.MigrationCardDateTo = MigrationCardDateTo;
				EndIf;
				If Not IsBlankString(ReceivingParty) Then
					vFRRObj.ReceivingParty = ReceivingParty;
				EndIf;
				If ValueIsFilled(StateProgramMember) Then
					vFRRObj.StateProgramMember = StateProgramMember;
				EndIf;
				If ValueIsFilled(ResidencePermitDocument) Then
					vFRRObj.ResidencePermitDocument = ResidencePermitDocument;
					If vFRRObj.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit And vFRRObj.ForEducationPurposes <> ForEducationPurposes Then
						vFRRObj.ForEducationPurposes = ForEducationPurposes;
					EndIf;
				EndIf;
				If Not IsBlankString(VisaNumber) Then
					vFRRObj.VisaNumber = VisaNumber;
				EndIf;
				If ValueIsFilled(VisaType) Then
					vFRRObj.VisaType = VisaType;
				EndIf;
				If ValueIsFilled(VisaMultiplicity) Then
					vFRRObj.VisaMultiplicity = VisaMultiplicity;
				EndIf;
				If ValueIsFilled(VisaEntryGoal) Then
					vFRRObj.VisaEntryGoal = VisaEntryGoal;
				EndIf;
				If ValueIsFilled(VisaIdentifier) Then
					vFRRObj.VisaIdentifier = VisaIdentifier;
				EndIf;
				If ValueIsFilled(VisaIssuedDate) Then
					vFRRObj.VisaIssuedDate = VisaIssuedDate;
				EndIf;
				If ValueIsFilled(VisaFromDate) Then
					vFRRObj.VisaFromDate = VisaFromDate;
				EndIf;
				If ValueIsFilled(VisaToDate) Then
					vFRRObj.VisaToDate = VisaToDate;
				EndIf;
				If Not IsBlankString(VisaIssuedBy) Then
					vFRRObj.VisaIssuedBy = VisaIssuedBy;
				EndIf;
				If VisaDays <> 0 Then
					vFRRObj.VisaDays = VisaDays;
				EndIf;
				If ValueIsFilled(BorderCrossingDate) Then
					vFRRObj.BorderCrossingDate = BorderCrossingDate;
				EndIf;
				If Not IsBlankString(CheckPointNumber) Then
					vFRRObj.CheckPointNumber = CheckPointNumber;
				EndIf;
				If Not IsBlankString(Route) Then
					vFRRObj.Route = Route;
				EndIf;
				If Not IsBlankString(LegalRepresentatives) Then
					vFRRObj.LegalRepresentatives = LegalRepresentatives;
				EndIf;
				If ValueIsFilled(LegalRepresentative) Then
					vFRRObj.LegalRepresentative = LegalRepresentative;
				EndIf;
				If Not IsBlankString(LegalRepresentativeLastName) Then
					vFRRObj.LegalRepresentativeLastName = LegalRepresentativeLastName;
				EndIf;
				If Not IsBlankString(LegalRepresentativeFirstName) Then
					vFRRObj.LegalRepresentativeFirstName = LegalRepresentativeFirstName;
				EndIf;
				If Not IsBlankString(LegalRepresentativeSecondName) Then
					vFRRObj.LegalRepresentativeSecondName = LegalRepresentativeSecondName;
				EndIf;
				If vFRRObj.Modified() Then
					vFRRObj.AdditionalProperties.Insert("OperationSource", "ClientDataScans");
					vFRRObj.Write(DocumentWriteMode.Posting);
					vFRRObj.pmWriteToForeignerRegistryRecordChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			Else
				If ValueIsFilled(Guest) And ValueIsFilled(Citizenship) And ValueIsFilled(Hotel) And 
				   Citizenship <> Hotel.Citizenship Then
					vFRRObj = Documents.ForeignerRegistryRecord.CreateDocument();
					vFRRObj.Fill(ParentDoc);
					FillPropertyValues(vFRRObj, ThisObject, , "Number, Date, Author, Remarks, Room, ParentDoc, Guest, Hotel, LastName, FirstName, SecondName"); 
					If Not IsBlankString(LastNameRu) And Not cmIsInLat(LastNameRu) Then
						vFRRObj.LastName = LastNameRu;
					EndIf;
					If Not IsBlankString(FirstNameRu) And Not cmIsInLat(FirstNameRu) Then
						vFRRObj.FirstName = FirstNameRu;
					EndIf;
					If Not IsBlankString(SecondNameRu) And Not cmIsInLat(SecondNameRu) Then
						vFRRObj.SecondName = SecondNameRu;
					EndIf;
					vFRRObj.AdditionalProperties.Insert("OperationSource", "ClientDataScans");
					vFRRObj.Write(DocumentWriteMode.Posting);
					vFRRObj.pmWriteToForeignerRegistryRecordChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();   
	vMaxMigDate = 90 * 24 * 3600;
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.Accommodation") Then
			ParentDoc = pBase;
			GuestGroup = pBase.GuestGroup;
			Room = pBase.Room;
			Guest = pBase.Guest;
			TripPurpose = pBase.TripPurpose;
			If ValueIsFilled(Guest) Then
				FillPropertyValues(ThisObject, Guest, , "Author, Remarks");
				PlaceOfBirth = TrimAll(Guest.Citizenship);
				If ValueIsFilled(pBase.Hotel) And 
				   ValueIsFilled(Guest.Citizenship) And 
				   ValueIsFilled(pBase.Hotel.Citizenship) And 
				   Guest.Citizenship <> pBase.Hotel.Citizenship Then
					ArrivedFrom = Guest.Citizenship;
					IsFromAbroad = True;
					If ValueIsFilled(pBase.CheckInDate) Then
						BorderCrossingDate = BegOfDay(pBase.CheckInDate);
					Else
						BorderCrossingDate = BegOfDay(CurrentSessionDate());
					EndIf;
					MigrationCardDateFrom = BorderCrossingDate;
					If ValueIsFilled(pBase.CheckOutDate) Then
						MigrationCardDateTo = BegOfDay(pBase.CheckOutDate);
					Else
						MigrationCardDateTo = MigrationCardDateFrom + vMaxMigDate;
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(pBase.Hotel) Then
				If Hotel <> pBase.Hotel Then
					Hotel = pBase.Hotel;
					SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
				EndIf;
			EndIf;
		ElsIf TypeOf(pBase) = Type("DocumentRef.Reservation") Then
			ParentDoc = pBase;
			GuestGroup = pBase.GuestGroup;
			Room = pBase.Room;
			Guest = pBase.Guest;
			TripPurpose = pBase.TripPurpose;
			If ValueIsFilled(Guest) Then
				FillPropertyValues(ThisObject, Guest, , "Author, Remarks");
				PlaceOfBirth = TrimAll(Guest.Citizenship);
				If ValueIsFilled(pBase.Hotel) And 
				   ValueIsFilled(Guest.Citizenship) And 
				   ValueIsFilled(pBase.Hotel.Citizenship) And 
				   Guest.Citizenship <> pBase.Hotel.Citizenship Then
					ArrivedFrom = Guest.Citizenship;
					IsFromAbroad = True;
					If ValueIsFilled(pBase.CheckInDate) Then
						BorderCrossingDate = BegOfDay(pBase.CheckInDate);
					Else
						BorderCrossingDate = BegOfDay(CurrentSessionDate());
					EndIf;
					MigrationCardDateFrom = BorderCrossingDate;
					If ValueIsFilled(pBase.CheckOutDate) Then
						MigrationCardDateTo = BegOfDay(pBase.CheckOutDate);
					Else
						MigrationCardDateTo = MigrationCardDateFrom + vMaxMigDate;
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(pBase.Hotel) Then
				If Hotel <> pBase.Hotel Then
					Hotel = pBase.Hotel;   
					vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
					SetNewNumber(vPrefix);
				EndIf;
			EndIf;
		ElsIf TypeOf(pBase) = Type("CatalogRef.Clients") Then
			ParentDoc = Undefined;
			GuestGroup = Catalogs.GuestGroups.EmptyRef();
			Room = Catalogs.Rooms.EmptyRef();
			Guest = pBase;
			TripPurpose = Catalogs.TripPurposes.EmptyRef();
			If ValueIsFilled(Guest) Then
				FillPropertyValues(ThisObject, Guest, , "Author, Remarks");
				PlaceOfBirth = TrimAll(Guest.Citizenship);
				If ValueIsFilled(Hotel) And 
				   ValueIsFilled(Guest.Citizenship) And 
				   ValueIsFilled(Hotel.Citizenship) And 
				   Guest.Citizenship <> Hotel.Citizenship Then
					ArrivedFrom = Guest.Citizenship;
					IsFromAbroad = True;
					BorderCrossingDate = BegOfDay(CurrentSessionDate());
					MigrationCardDateFrom = BorderCrossingDate;
					MigrationCardDateTo = MigrationCardDateFrom + vMaxMigDate;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	If AdditionalProperties.Property("LinksRestoreMode") And AdditionalProperties.LinksRestoreMode Then
		Return;
	EndIf;
	If pWriteMode <> DocumentWriteMode.UndoPosting Then
		If ValueIsFilled(Hotel) And Not IsBlankString(Hotel.BLOBRootFolder) Then
			If Not ValueIsFilled(Number) Then
				SetNewNumber();	
			EndIf;
			For Each vPictRow In ScanPictures Do
				vPicture = vPictRow.ScanPicture.Get();
				If TypeOf(vPicture) = Type("Picture") Then
					Try
						vCatalogName = "";
						vFileName = pmGetImageFileName(vPictRow, vCatalogName);
						vCatalog = New File(vCatalogName);
						If Not tcCommonFunctionOnClientServer.cmExists(vCatalog) Then
							CreateDirectory(vCatalogName);
						EndIf;
						vPicture.Write(vCatalogName + vFileName);
						vPictRow.ScanPicture = New ValueStorage(vFileName);
					Except
						vPictRow.ScanPicture = New ValueStorage(vPicture);
					EndTry;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(Status) Then
		Status = Enums.ScanStatuses.IsNew;
	EndIf;
	CheckPointNumber = Catalogs.CheckPoints.EmptyRef();
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetImageCatalogName(pRow) Export
	If Not ValueIsFilled(Hotel) Then
		Raise NStr("en = 'Hotel is not filled! '; de = 'Bei dem Dokument ist das Hotel nicht eingetragen! '; ru = 'У документа не заполнена гостиница! '") + Ref;
	EndIf;
	vBLOBRootFolder = TrimAll(Hotel.BLOBRootFolder);
	vNonReplicatingAttributes = Catalogs.Hotels.pmGetNonReplicatingAttributes(Hotel);
	If vNonReplicatingAttributes.Count() > 0 Then
		vBLOBRootFolder = TrimAll(vNonReplicatingAttributes.Get(0).BLOBRootFolder);
	EndIf;
	vDelimeter = "\";
	If Find(vBLOBRootFolder, "/") > 0 Then
		vDelimeter = "/";
	EndIf;
	If Right(vBLOBRootFolder, 1) <> vDelimeter Then
		vBLOBRootFolder = vBLOBRootFolder + vDelimeter;
	EndIf;
	rCatalogName = vBLOBRootFolder + "ClientDataScans" + vDelimeter + TrimAll(Number) + "_" + Format(Date, "DF=yyyy-MM-dd") + vDelimeter;
	Return rCatalogName;
EndFunction // pmGetImageCatalogName

// -----------------------------------------------------------------------------
Function pmGetImageFileName(pRow, rCatalogName) Export
	rCatalogName = pmGetImageCatalogName(pRow);
	vFileName = Format(pRow.LineNumber, "ND=4; NFD=0; NG=") + "_" + cmGetValidFileName(StrReplace(TrimAll(pRow.ScanConfiguration), " ", "_")) + ".jpg";
	Return vFileName;
EndFunction // pmGetImageFileName

#EndRegion
