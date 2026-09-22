
#Region Public

// -----------------------------------------------------------------------------
Procedure pmWriteToForeignerRegistryRecordChangeHistory(pPeriod, pUser) Export
	// Get channges description
	vChanges = cmGetObjectChanges(ThisObject);
	If Not IsBlankString(vChanges) Then
		// Do movement on current date
		vHistRec = InformationRegisters.ForeignerRegistryRecordChangeHistory.CreateRecordManager();
		
		FillHistoryAttributes(vHistRec, pPeriod, pUser);
		vHistRec.Changes = vChanges;
		
		// Write record
		vHistRec.Write(True);
	EndIf;
EndProcedure // pmWriteToForeignerRegistryRecordChangeHistory

// -----------------------------------------------------------------------------
Procedure pmRestoreAttributesFromHistory(pHistRec) Export
	FillPropertyValues(ThisObject, pHistRec, , "Number, Date, Author");
	If Not IsBlankString(pHistRec.Number) Then
		Number = pHistRec.Number;
	EndIf;
	If ValueIsFilled(pHistRec.Date) Then
		Date = pHistRec.Date;
	EndIf;
	If ValueIsFilled(pHistRec.Author) Then
		Author = pHistRec.Author;
	EndIf;
EndProcedure // pmRestoreAttributesFromHistory

// -----------------------------------------------------------------------------
Function pmGetPreviousObjectState(pPeriod) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.ForeignerRegistryRecordChangeHistory.SliceLast(&qPeriod, ForeignerRegistryRecord = &qDoc) AS ForeignerRegistryRecordChangeHistory";
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qDoc", Ref);
	vStates = vQry.Execute().Unload();
	If vStates.Count() > 0 Then
		Return vStates.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetPreviousObjectState

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
	// Fill check point number with empty ref
	CheckPointNumber = Catalogs.CheckPoints.EmptyRef();
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmDeleteHistoryRecords() Export
	vHstRecSel = InformationRegisters.ForeignerRegistryRecordChangeHistory.Select(, , New Structure("ForeignerRegistryRecord", Ref));
	While vHstRecSel.Next() Do
		vHstRecSel.GetRecordManager().Delete();
	EndDo;
EndProcedure // pmDeleteHistoryRecords

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	If AdditionalProperties.Property("LinksRestoreMode") And AdditionalProperties.LinksRestoreMode Then
		Return;
	EndIf;
	// Update guest data if there are changes
	If ValueIsFilled(Guest) Then
		vGuestObj = Guest.GetObject();
		If ValueIsFilled(Sex) Then
			If vGuestObj.Sex <> Sex Then
				vGuestObj.Sex = Sex;
			EndIf;
		EndIf;
		If ValueIsFilled(Citizenship) Then
			If vGuestObj.Citizenship <> Citizenship Then
				vGuestObj.Citizenship = Citizenship;
			EndIf;
		EndIf;
		If ValueIsFilled(DateOfBirth) Then
			If vGuestObj.DateOfBirth <> DateOfBirth Then
				vGuestObj.DateOfBirth = DateOfBirth;
			EndIf;
		EndIf;
		If Not IsBlankString(PlaceOfBirth) Then
			If TrimAll(vGuestObj.PlaceOfBirth) <> TrimAll(PlaceOfBirth) Then
				vGuestObj.PlaceOfBirth = PlaceOfBirth;
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
		// Check that guest object was changed
		If vGuestObj.Modified() Then
			vGuestObj.Write();
			// Write to guest change history
			vGuestObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndIf;
	// Update accommodation data if there are changes
	If ValueIsFilled(ParentDoc) Then
		vAccObj = ParentDoc.GetObject();
		If ValueIsFilled(TripPurpose) Then
			If vAccObj.TripPurpose <> TripPurpose Then
				vAccObj.TripPurpose = TripPurpose;
			EndIf;
		EndIf;
		// Check that guest object was changed
		If vAccObj.Modified() Then
			vAccObj.AdditionalProperties.Insert("OperationSource", "ForeignerRegistryRecord");
			vAccObj.Write(DocumentWriteMode.Posting);
			// Write to accommodation change history
			vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndIf;
	// Add record to accommodation foreigner registry records register
	If ValueIsFilled(ParentDoc) Then
		Movement = RegisterRecords.AccommodationForeignerRegistryRecords.Add();
		
		Movement.Period = Date;
		Movement.Recorder = Ref;
		
		Movement.Accommodation = ParentDoc;
		Movement.ForeignerRegistryRecord = Ref;
		
		// Write record
		RegisterRecords.AccommodationForeignerRegistryRecords.Write();
	EndIf;
	// Update client data scans
	If Not AdditionalProperties.Property("OperationSource") Or AdditionalProperties.Property("OperationSource") And AdditionalProperties.OperationSource <> "ClientDataScans" Then
		vScansDoc = GetDataScansDocument();
		If ValueIsFilled(vScansDoc) Then
			vScansObj = vScansDoc.GetObject();
			If Not IsBlankString(LastName) And Not cmIsInLat(LastName) Then
				If vScansObj.LastNameRu <> LastName Then
					vScansObj.LastNameRu = LastName;
				EndIf;
			EndIf;
			If Not IsBlankString(FirstName) And Not cmIsInLat(FirstName) Then
				If vScansObj.FirstNameRu <> FirstName Then
					vScansObj.FirstNameRu = FirstName;
				EndIf;
			EndIf;
			If Not IsBlankString(SecondName) And Not cmIsInLat(SecondName) Then
				If vScansObj.SecondNameRu <> SecondName Then
					vScansObj.SecondNameRu = SecondName;
				EndIf;
			EndIf;
			If ValueIsFilled(TripPurpose) Then
				If vScansObj.TripPurpose <> TripPurpose Then
					vScansObj.TripPurpose = TripPurpose;
				EndIf;
			EndIf;
			If Not IsBlankString(Profession) Then
				If vScansObj.Profession = Profession Then
					vScansObj.Profession = Profession;
				EndIf;
			EndIf;
			If Not IsBlankString(Standing) Then
				If vScansObj.Standing <> Standing Then
					vScansObj.Standing = Standing;
				EndIf;
			EndIf;
			If Not IsBlankString(ArrivedFrom) Then
				If vScansObj.ArrivedFrom <> ArrivedFrom Then
					vScansObj.ArrivedFrom = ArrivedFrom;
				EndIf;
			EndIf;
			If IsFromAbroad Then
				If vScansObj.IsFromAbroad <> IsFromAbroad Then
					vScansObj.IsFromAbroad = IsFromAbroad;
				EndIf;
			EndIf;
			If Not IsBlankString(MigrationCardNumber) Then
				If vScansObj.MigrationCardNumber <> MigrationCardNumber Then
					vScansObj.MigrationCardNumber = MigrationCardNumber;
				EndIf;
			EndIf;
			If ValueIsFilled(MigrationCardDateFrom) Then
				If vScansObj.MigrationCardDateFrom <> MigrationCardDateFrom Then
					vScansObj.MigrationCardDateFrom = MigrationCardDateFrom;
				EndIf;
			EndIf;
			If ValueIsFilled(MigrationCardDateTo) Then
				If vScansObj.MigrationCardDateTo <> MigrationCardDateTo Then
					vScansObj.MigrationCardDateTo = MigrationCardDateTo;
				EndIf;
			EndIf;
			If Not IsBlankString(ReceivingParty) Then
				If vScansObj.ReceivingParty <> ReceivingParty Then
					vScansObj.ReceivingParty = ReceivingParty;
				EndIf;
			EndIf;
			If ValueIsFilled(StateProgramMember) Then
				If vScansObj.StateProgramMember <> StateProgramMember Then
					vScansObj.StateProgramMember = StateProgramMember;
				EndIf;
			EndIf;
			If ValueIsFilled(ResidencePermitDocument) Then
				If vScansObj.ResidencePermitDocument <> ResidencePermitDocument Then
					vScansObj.ResidencePermitDocument = ResidencePermitDocument;
				EndIf;
				If vScansObj.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit And vScansObj.ForEducationPurposes <> ForEducationPurposes Then
					vScansObj.ForEducationPurposes = ForEducationPurposes;
				EndIf;
			EndIf;
			If Not IsBlankString(VisaNumber) Then
				If vScansObj.VisaNumber <> VisaNumber Then
					vScansObj.VisaNumber = VisaNumber;
				EndIf;
			EndIf;
			If ValueIsFilled(VisaType) Then
				If vScansObj.VisaType <> VisaType Then
					vScansObj.VisaType = VisaType;
				EndIf;
			EndIf;
			If ValueIsFilled(VisaMultiplicity) Then
				If vScansObj.VisaMultiplicity <> VisaMultiplicity Then
					vScansObj.VisaMultiplicity = VisaMultiplicity;
				EndIf;
			EndIf;
			If ValueIsFilled(VisaEntryGoal) Then
				If vScansObj.VisaEntryGoal <> VisaEntryGoal Then
					vScansObj.VisaEntryGoal = VisaEntryGoal;
				EndIf;
			EndIf;
			If ValueIsFilled(VisaIdentifier) Then
				If vScansObj.VisaIdentifier <> VisaIdentifier Then
					vScansObj.VisaIdentifier = VisaIdentifier;
				EndIf;
			EndIf;
			If ValueIsFilled(VisaIssuedDate) Then
				If vScansObj.VisaIssuedDate <> VisaIssuedDate Then
					vScansObj.VisaIssuedDate = VisaIssuedDate;
				EndIf;
			EndIf;
			If ValueIsFilled(VisaFromDate) Then
				If vScansObj.VisaFromDate <> VisaFromDate Then
					vScansObj.VisaFromDate = VisaFromDate;
				EndIf;
			EndIf;
			If ValueIsFilled(VisaToDate) Then
				If vScansObj.VisaToDate <> VisaToDate Then
					vScansObj.VisaToDate = VisaToDate;
				EndIf;
			EndIf;
			If Not IsBlankString(VisaIssuedBy) Then
				If vScansObj.VisaIssuedBy <> VisaIssuedBy Then
					vScansObj.VisaIssuedBy = VisaIssuedBy;
				EndIf;
			EndIf;
			If VisaDays <> 0 Then
				If vScansObj.VisaDays <> VisaDays Then
					vScansObj.VisaDays = VisaDays;
				EndIf;
			EndIf;
			If ValueIsFilled(BorderCrossingDate) Then
				If vScansObj.BorderCrossingDate <> BorderCrossingDate Then
					vScansObj.BorderCrossingDate = BorderCrossingDate;
				EndIf;
			EndIf;
			If Not IsBlankString(CheckPointNumber) Then
				If vScansObj.CheckPointNumber <> CheckPointNumber Then
					vScansObj.CheckPointNumber = CheckPointNumber;
				EndIf;
			EndIf;
			If Not IsBlankString(Route) Then
				If vScansObj.Route <> Route Then
					vScansObj.Route = Route;
				EndIf;
			EndIf;
			If Not IsBlankString(LegalRepresentatives) Then
				If vScansObj.LegalRepresentatives <> LegalRepresentatives Then
					vScansObj.LegalRepresentatives = LegalRepresentatives;
				EndIf;
			EndIf;
			If ValueIsFilled(LegalRepresentative) Then
				If vScansObj.LegalRepresentative <> LegalRepresentative Then
					vScansObj.LegalRepresentative = LegalRepresentative;
				EndIf;
			EndIf;
			If Not IsBlankString(LegalRepresentativeLastName) Then
				If vScansObj.LegalRepresentativeLastName <> LegalRepresentativeLastName Then
					vScansObj.LegalRepresentativeLastName = LegalRepresentativeLastName;
				EndIf;
			EndIf;
			If Not IsBlankString(LegalRepresentativeFirstName) Then
				If vScansObj.LegalRepresentativeFirstName <> LegalRepresentativeFirstName Then
					vScansObj.LegalRepresentativeFirstName = LegalRepresentativeFirstName;
				EndIf;
			EndIf;
			If Not IsBlankString(LegalRepresentativeSecondName) Then
				If vScansObj.LegalRepresentativeSecondName <> LegalRepresentativeSecondName Then
					vScansObj.LegalRepresentativeSecondName = LegalRepresentativeSecondName;
				EndIf;
			EndIf;
			If vScansObj.Modified() Then
				vScansObj.AdditionalProperties.Insert("OperationSource", "ForeignerRegistryRecord");
				vScansObj.Write(DocumentWriteMode.Posting);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.Accommodation") Then
			ParentDoc = pBase;
			Room = pBase.Room;
			Guest = pBase.Guest;
			CheckInDate = pBase.CheckInDate;
			CheckOutDate = cmGetLastCheckOutDateInChain(pBase, True);
			If Not ValueIsFilled(BorderCrossingDate) Then
				If ValueIsFilled(CheckInDate) Then
					BorderCrossingDate = BegOfDay(CheckInDate);
				Else
					BorderCrossingDate = BegOfDay(CurrentSessionDate());
				EndIf;
			EndIf;
			MigrationCardDateFrom = BorderCrossingDate;
			If ValueIsFilled(CheckOutDate) Then
				MigrationCardDateTo = BegOfDay(CheckOutDate);
			Else
				MigrationCardDateTo = MigrationCardDateFrom + 90 * 24 * 3600;
			EndIf;
			TripPurpose = pBase.TripPurpose;
			If ValueIsFilled(Guest) Then
				FillPropertyValues(ThisObject, Guest, , "Author, Remarks");
				ArrivedFrom = Guest.Citizenship;
				IsFromAbroad = True;
			EndIf;
			If ValueIsFilled(pBase.Hotel) Then
				If Hotel <> pBase.Hotel Then
					Hotel = pBase.Hotel;
					SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
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
	// Identity document data presentation
	IdentityDocumentPresentation = TrimAll(TrimAll(IdentityDocumentType) + " " + 
	                               TrimAll(IdentityDocumentSeries) + " " + TrimAll(IdentityDocumentNumber) + " " + 
								   ?(IsBlankString(IdentityDocumentUnitCode), "", TrimAll(IdentityDocumentUnitCode) + " ") + 
								   ?(IsBlankString(IdentityDocumentIssuedBy), "", TrimAll(IdentityDocumentIssuedBy) + " ") + 
								   ?(ValueIsFilled(IdentityDocumentIssueDate), Format(IdentityDocumentIssueDate, "DF=dd.MM.yyyy"), ""));
	// Migration card data presentation
	MigrationCardPresentation = TrimAll(TrimAll(MigrationCardNumber) + 
								   ?(ValueIsFilled(MigrationCardDateFrom), " " + Format(MigrationCardDateFrom, "DF=dd.MM.yyyy"), "") +
								   ?(ValueIsFilled(MigrationCardDateTo), " - " + Format(MigrationCardDateTo, "DF=dd.MM.yyyy"), "") + 
	                               ?(IsBlankString(CheckPointNumber), "", ", " + TrimAll(CheckPointNumber)) + 
	                               ?(IsBlankString(ArrivedFrom), "", ", " + TrimAll(ArrivedFrom)) + 
	                               ?(IsBlankString(ReceivingParty), "", ", " + TrimAll(ReceivingParty)) + 
	                               ?(IsBlankString(Route), "", ", " + TrimAll(Route)) + 
	                               ?(ValueIsFilled(TripPurpose), ", " + TrimAll(TripPurpose), ""));
	// Visa data presentation
	VisaPresentation = TrimAll(TrimAll(VisaType) + " " + TrimAll(VisaNumber) + 
	                               ?(VisaDays > 0, ", " + Format(VisaDays, "ND=6; NFD=0; NG="), "") + 
								   ?(ValueIsFilled(VisaIssuedDate), ", " + Format(VisaIssuedDate, "DF=dd.MM.yyyy"), "") +
	                               ?(IsBlankString(VisaIssuedBy), "", " " + TrimAll(VisaIssuedBy)) + 
								   ?(ValueIsFilled(VisaFromDate), ", " + Format(VisaFromDate, "DF=dd.MM.yyyy"), "") +
								   ?(ValueIsFilled(VisaToDate), " - " + Format(VisaToDate, "DF=dd.MM.yyyy"), ""));
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)       
	If DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetDataScansDocument()
	vDocRef = Documents.ClientDataScans.EmptyRef();
	If ValueIsFilled(Guest) And ValueIsFilled(ParentDoc) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ClientDataScans.Ref AS Ref
		|FROM
		|	Document.ClientDataScans AS ClientDataScans
		|WHERE
		|	ClientDataScans.Posted
		|	AND ClientDataScans.Hotel = &qHotel
		|	AND ClientDataScans.Guest = &qGuest
		|	AND ClientDataScans.ParentDoc = &qParentDoc
		|
		|ORDER BY
		|	ClientDataScans.PointInTime DESC";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qGuest", Guest);
		vQry.SetParameter("qParentDoc", ParentDoc);
		vDocs = vQry.Execute().Unload();
		For Each vDocsRow In vDocs Do
			vDocRef = vDocsRow.Ref;
			Break;
		EndDo;
	EndIf;
	Return vDocRef;
EndFunction // GetDataScansDocument

// -----------------------------------------------------------------------------
Procedure FillHistoryAttributes(pHistRec, pPeriod, pUser)
	FillPropertyValues(pHistRec, ThisObject);
	
	pHistRec.Period = pPeriod;
	pHistRec.ForeignerRegistryRecord = Ref;
	pHistRec.User = pUser;
EndProcedure // FillHistoryAttributes

#EndRegion
