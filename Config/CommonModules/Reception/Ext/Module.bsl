
#Region Public

// -----------------------------------------------------------------------------
// Description: Returns customers with description starting from the given text
// Parameters: First letters of customer name to be searched, Maximum number of 
//             customers to return
// Return value: Value table with customers found
// -----------------------------------------------------------------------------
Function cmGetCustomersList(pText, pMaxNumber = 10) Export
	// Build and run query
	qGetList = New Query;
	qGetList.Text = 
	"SELECT DISTINCT TOP " + pMaxNumber + "
	|	Customers.Code,
	|	Customers.Description,
	|	Customers.LegacyName,
	|	Customers.TIN,
	|	Customers.Ref
	|FROM
	|	Catalog.Customers AS Customers
	|WHERE
	|	Customers.IsFolder = False AND
	|	Customers.DeletionMark = False AND
	|	Customers.Description LIKE &qName
	|ORDER BY Description";
	qGetList.SetParameter("qName", "%" + pText + "%");
	vList = qGetList.Execute().Unload();
	Return vList;
EndFunction // cmGetCustomersList

// -----------------------------------------------------------------------------
// Description: Returns customers presentation string that is composed of 
//              Customer legacy name and customer TIN
// Parameters: Value table row or structure with customer's data 
// Return value: String, customer presentation
// -----------------------------------------------------------------------------
Function cmGetCustomerPresentation(pRow) Export
	vD = TrimAll(pRow.Description);
	vLN = TrimAll(pRow.LegacyName);
	vTIN = TrimAll(pRow.TIN);
	vN = ?(IsBlankString(vLN), vD, vLN) + " (" + cmGetDocumentNumberPresentation(pRow.Code) + " - " + TrimAll(pRow.Description) + ")";
	Return vN + ?(IsBlankString(vTIN), "", NStr("ru = ', ИНН: '; en = ', TIN: '; de = ', TIN: '") + vTIN);
EndFunction // cmGetCustomerPresentation

// -----------------------------------------------------------------------------
// Description: Standard customer control text edit end event processing routine
// Parameters: Object, Form, Customer control, Text being entered, Customer 
//             reference to return, Standard processing flag
// Return value: True if customer was found and was set to the control value, 
//               False if not
// -----------------------------------------------------------------------------
Function cmCustomerTextEditEnd(pObject, pForm, pControl, pText, pValue, pStandardProcessing) Export
	vIsChanged = False;
	vText = TrimAll(pText);
	vTab = cmGetCustomersList(vText, 10);
	If vTab.Count() = 1 Then
		pStandardProcessing = False;
		vRow = vTab.Get(0);
		pValue = vRow.Ref;
		vIsChanged = True;
	ElsIf vTab.Count() > 1 Then
		pStandardProcessing = False;
		vList = New ValueList;
		For Each vRow In vTab Do
			vList.Add(vRow.Ref, cmGetCustomerPresentation(vRow));
		EndDo;
		vRef = pForm.ChooseFromList(vList, pControl);
		If vRef <> Undefined Then
			pValue = vRef.Value;
			vIsChanged = True;
		EndIf;
	EndIf;
	Return vIsChanged;
EndFunction // cmCustomerTextEditEnd

// -----------------------------------------------------------------------------
// Description: Returns list of guest groups found by code or hotel
// Parameters: Guest group code as Number or String, Hotel, Maximum number of records to return
// Return value: Value table of guest groups found
// -----------------------------------------------------------------------------
Function cmGetGuestGroupsList(pCode, pHotel, pMaxNumber = 10) Export
	// Build and run query
	qGetList = New Query;
	qGetList.Text = 
	"SELECT DISTINCT TOP " + pMaxNumber + "
	|	GuestGroups.Code,
	|	GuestGroups.Description,
	|	GuestGroups.Parent,
	|	GuestGroups.Ref
	|FROM
	|	Catalog.GuestGroups AS GuestGroups
	|WHERE
	|	GuestGroups.Owner = &qHotel AND 
	|	GuestGroups.Code = &qCode AND 
	|	GuestGroups.IsFolder = False AND
	|	GuestGroups.DeletionMark = False
	|ORDER BY Description";
	qGetList.SetParameter("qHotel", pHotel);
	qGetList.SetParameter("qCode", Number(pCode));
	vList = qGetList.Execute().Unload();
	Return vList;
EndFunction // cmGetGuestGroupsList

// -----------------------------------------------------------------------------
// Description: Returns guest group presentation string being built from code, 
//              group description and group remarks
// Parameters: Value table row or Structure with guest group data
// Return value: Guest group presentation string
// -----------------------------------------------------------------------------
Function cmGetGuestGroupPresentation(pRow) Export
	vP = "";
	If ValueIsFilled(pRow.Parent) Then
		vP = TrimAll(pRow.Parent.Description);
	EndIf;
	vC = TrimAll(pRow.Code);
	vD = TrimAll(pRow.Description);
	vR = TrimAll(pRow.Ref.Remarks);
	vN = ?(IsBlankString(vP), "", vP + "/") + vC + ?(vD="", "", " (" + vD + ")") + ?(vR="", "", ", " + vR);
	Return vN;
EndFunction // cmGetGuestGroupPresentation

// -----------------------------------------------------------------------------
Function cmGetGuestGroupDocuments(pGuestGroup) Export
	vQry = New Query;  
	vQry.Text =
	"SELECT
	|	Accommodations.Ref AS Reservation,
	|	Accommodations.HotelProduct AS HotelProduct,
	|	Accommodations.CheckInDate AS CheckInDate,
	|	Accommodations.CheckOutDate AS CheckOutDate,
	|	Accommodations.Duration AS Duration,
	|	Accommodations.RoomType AS RoomType,
	|	Accommodations.RoomType.IsVirtual AS IsVirtual,
	|	Accommodations.AccommodationType AS AccommodationType,
	|	Accommodations.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	NULL AS RoomQuantity,
	|	0 AS CheckInRoomQuantity,
	|	CASE
	|		WHEN Accommodations.Room = &qEmptyRoom
	|			THEN ""#"" + SUBSTRING(Accommodations.Number, 7, 6)
	|		ELSE Accommodations.Room
	|	END AS Room,
	|	CASE
	|		WHEN Accommodations.Room = &qEmptyRoom
	|			THEN ISNULL(SUBSTRING(Accommodations.Number, 7, 6), 0)
	|		ELSE Accommodations.Room.SortCode
	|	END AS RoomSortCode,
	|	CASE
	|		WHEN Accommodations.Room = &qEmptyRoom
	|			THEN VALUE(Catalog.RoomStatuses.EmptyRef)
	|		ELSE Accommodations.Room.RoomStatus
	|	END AS RoomRoomStatus,
	|	Accommodations.NumberOfPersons AS NumberOfPersons,
	|	Accommodations.NumberOfAdults AS NumberOfAdults,
	|	Accommodations.NumberOfTeenagers AS NumberOfTeenagers,
	|	Accommodations.NumberOfChildren AS NumberOfChildren,
	|	Accommodations.NumberOfInfants AS NumberOfInfants,
	|	Accommodations.AccommodationTemplate AS AccommodationTemplate,
	|	ISNULL(Accommodations.AccommodationTemplate.Code, """") AS AccommodationTemplateCode,
	|	Accommodations.Guest AS Guest,
	|	Accommodations.GuestFullName AS GuestFullName,
	|	Accommodations.IsMaster AS IsMaster,
	|	Accommodations.AccommodationStatus AS ReservationStatus,
	|	Accommodations.Number AS Number,
	|	Accommodations.RoomRate AS RoomRate,
	|	Accommodations.RoomRateServiceGroup AS RoomRateServiceGroup,
	|	Accommodations.Remarks AS Remarks,
	|	Accommodations.ParentDoc AS ParentDoc,
	|	0 AS LineNumber,
	|	13 AS Picture,
	|	"""" AS RowTotals,
	|	Accommodations.CheckInDate AS CheckInTime,
	|	Accommodations.CheckOutDate AS CheckOutTime,
	|	Accommodations.GuestGroup AS GuestGroup,
	|	Accommodations.Customer AS Customer,
	|	FALSE AS IsChanged,
	|	Accommodations.Hotel AS Hotel,
	|	Accommodations.Posted AS Posted,
	|	Accommodations.DeletionMark AS DeletionMark,
	|	Accommodations.Reservation AS ReservationRef,
	|	Accommodations.HousekeepingRemarks AS HousekeepingRemarks,
	|	Accommodations.BedsSetup AS BedsSetup
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.GuestGroup = &qGuestGroup AND Accommodations.AccommodationStatus.IsActive AND Accommodations.Posted" 
	+ ?(ValueIsFilled(SessionParameters.CurrentUser.Customer), " AND Accommodations.Customer = &qCustomer ", " ") +
	"UNION ALL
	|
	|SELECT
	|	Reservations.Ref,
	|	Reservations.HotelProduct,
	|	Reservations.CheckInDate,
	|	Reservations.CheckOutDate,
	|	Reservations.Duration,
	|	Reservations.RoomType,
	|	Reservations.RoomType.IsVirtual,
	|	Reservations.AccommodationType,
	|	Reservations.AccommodationType.SortCode,
	|	Reservations.RoomQuantity,
	|	(Reservations.RoomQuantity - ISNULL(CheckIns.CheckInRoomQuantity, 0)) AS CheckInRoomQuantity,
	|	CASE
	|		WHEN Reservations.Room = &qEmptyRoom
	|			THEN ""#"" + SUBSTRING(Reservations.Number, 7, 6)
	|		ELSE Reservations.Room
	|	END,
	|	CASE
	|		WHEN Reservations.Room = &qEmptyRoom
	|			THEN ISNULL(SUBSTRING(Reservations.Number, 7, 6), 0)
	|		ELSE Reservations.Room.SortCode
	|	END,
	|	CASE
	|		WHEN Reservations.Room = &qEmptyRoom
	|			THEN VALUE(Catalog.RoomStatuses.EmptyRef)
	|		ELSE Reservations.Room.RoomStatus
	|	END,
	|	Reservations.NumberOfPersons,
	|	Reservations.NumberOfAdults AS NumberOfAdults,
	|	Reservations.NumberOfTeenagers AS NumberOfTeenagers,
	|	Reservations.NumberOfChildren AS NumberOfChildren,
	|	Reservations.NumberOfInfants AS NumberOfInfants,
	|	Reservations.AccommodationTemplate,
	|	ISNULL(Reservations.AccommodationTemplate.Code, """"),
	|	Reservations.Guest,
	|	Reservations.GuestFullName,
	|	Reservations.IsMaster,
	|	Reservations.ReservationStatus,
	|	Reservations.Number,
	|	Reservations.RoomRate,
	|	Reservations.RoomRateServiceGroup,
	|	Reservations.Remarks,
	|	Reservations.ParentDoc,
	|	0,
	|	13,
	|	"""",
	|	Reservations.CheckInDate,
	|	Reservations.CheckOutDate,
	|	Reservations.GuestGroup,
	|	Reservations.Customer,
	|	FALSE,
	|	Reservations.Hotel,
	|	Reservations.Posted,
	|	Reservations.DeletionMark,
	|	NULL,
	|	Reservations.HousekeepingRemarks,
	|	Reservations.BedsSetup
	|FROM
	|	Document.Reservation AS Reservations
	|	LEFT JOIN (SELECT
	|		Accommodations.ParentDoc,
	|		COUNT(Accommodations.Ref) AS CheckInRoomQuantity
	|	FROM
	|		Document.Accommodation AS Accommodations
	|	WHERE
	|		Accommodations.GuestGroup = &qGuestGroup
	|		AND Accommodations.Posted
	|		AND Accommodations.AccommodationStatus.IsActive
	|	GROUP BY
	|		Accommodations.ParentDoc) AS CheckIns
	|	ON Reservations.Ref = CheckIns.ParentDoc
	|WHERE
	|	Reservations.GuestGroup = &qGuestGroup AND (Reservations.ReservationStatus.IsActive OR Reservations.ReservationStatus.IsPreliminary) AND Reservations.Posted" 
	+ ?(ValueIsFilled(SessionParameters.CurrentUser.Customer), " AND Reservations.Customer = &qCustomer ", " ") +	
	"	AND (Reservations.RoomQuantity = 1 AND NOT Reservations.Ref IN
	|				(SELECT
	|					AccommodationReservations.Reservation
	|				FROM
	|					Document.Accommodation AS AccommodationReservations
	|				WHERE
	|					AccommodationReservations.GuestGroup = &qGuestGroup
	|					AND AccommodationReservations.Posted
	|					AND AccommodationReservations.AccommodationStatus.IsActive)
	|		OR Reservations.RoomQuantity > 1 AND 
	|			(Reservations.RoomQuantity - ISNULL(CheckIns.CheckInRoomQuantity, 0)) > 0)
	|ORDER BY
	|	RoomSortCode,
	|	CheckInDate,
	|	AccommodationTemplateCode DESC, 
	|	AccommodationTypeSortCode,
	|	GuestFullName";
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		vQry.SetParameter("qCustomer", SessionParameters.CurrentUser.Customer);
	EndIf;
	Return vQry.Execute().Unload();
EndFunction // cmGetGuestGroupDocuments

// -----------------------------------------------------------------------------
// Description: Standard guest group control text edit end event processing routine
// Parameters: Object, Form, Guest group control, Text being entered, Guest group 
//             reference to return, Standard processing flag
// Return value: True if Guest group was found and was set to the control value, 
//               False if not
// -----------------------------------------------------------------------------
Function cmGuestGroupTextEditEnd(pObject, pForm, pControl, pText, pValue, pStandardProcessing) Export
	vIsChanged = False;
	pStandardProcessing = False;
	vText = TrimAll(pText);
	vTab = cmGetGuestGroupsList(vText, pObject.Hotel, 10);
	If vTab.Count() = 1 Then
		vRow = vTab.Get(0);
		pValue = vRow.Ref;
		vIsChanged = True;
	ElsIf vTab.Count() > 1 Then
		vList = New ValueList;
		For Each vRow In vTab Do
			vList.Add(vRow.Ref, cmGetGuestGroupPresentation(vRow));
		EndDo;
		vRef = pForm.ChooseFromList(vList, pControl);
		If vRef <> Undefined Then
			pValue = vRef.Value;
			vIsChanged = True;
		EndIf;
	ElsIf ValueIsFilled(pObject.Hotel) And pObject.Hotel.AssignReservationGuestGroupsManually Then
		Try
			vGroupObj = Catalogs.GuestGroups.CreateItem();
			vGroupObj.Code = Number(pText);
			vGroupObj.Owner = pObject.Hotel;
			vGuestGroupFolder = pObject.Hotel.GetObject().pmGetGuestGroupFolder();
			If ValueIsFilled(vGuestGroupFolder) Then
				vGroupObj.Parent = vGuestGroupFolder;
			EndIf;
			If ValueIsFilled(vGroupObj.Owner) Then
				vGroupObj.OneCustomerPerGuestGroup = vGroupObj.Owner.OneCustomerPerGuestGroup;
			EndIf;
			vGroupObj.Write();
			pValue = vGroupObj.Ref;
			vIsChanged = True;
		Except
		EndTry;
	Else
		pStandardProcessing = True;
	EndIf;
	Return vIsChanged;
EndFunction // cmGuestGroupTextEditEnd

// -----------------------------------------------------------------------------
// Description: Returns client's list filtered by client name, identity document 
//              data and phone number
// Parameters: Client last name string, Client first name string, Client second name string,
//             Identity document number string, Identity document series string, Phone number string,
//             Boolean - Whether to use substring search for the client name (search requested string 
//             in any part of the name) or use search comparing first letters of name with requested 
//             string
// Return value: Value table with clients found
// -----------------------------------------------------------------------------
Function cmGetClientsList(pLastName, pFirstName, pSecondName, pIdentityDocNumber, pIdentityDocSeries, pPhone, pEMail, pUseSubstringSearch = False) Export
	// Build and run query
	qGetList = New Query;
	qGetList.Text = 
	"SELECT 
	|	Clients.Ref,
	|	Clients.Description,
	|	Clients.LastName,
	|	Clients.FirstName,
	|	Clients.SecondName,
	|	Clients.Sex,
	|	Clients.DateOfBirth,
	|	Clients.IdentityDocumentType,
	|	Clients.IdentityDocumentSeries,
	|	Clients.IdentityDocumentNumber,
	|	Clients.IdentityDocumentIssueDate,
	|	Clients.Author,
	|	Clients.CreateDate
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	Clients.IsFolder = FALSE AND " + 
		?(IsBlankString(pIdentityDocNumber), "", "Clients.IdentityDocumentNumber = &qIdentityDocNumber AND ") + 
		?(IsBlankString(pIdentityDocSeries), "", "Clients.IdentityDocumentSeries = &qIdentityDocSeries AND ") + 
		?(pUseSubstringSearch,
		?(IsBlankString(pLastName), "", "(Clients.Description LIKE &qDescription OR Clients.Description LIKE &qDescriptionTrans OR Clients.FirstName LIKE &qFirstName OR Clients.FirstName LIKE &qFirstNameTrans OR Clients.SecondName LIKE &qSecondName OR Clients.SecondName LIKE &qSecondNameTrans) AND "), 
		?(IsBlankString(pLastName), "", "(Clients.Description LIKE &qDescription OR Clients.Description LIKE &qDescriptionTrans) AND ") + 
		?(IsBlankString(pFirstName), "", "(Clients.FirstName LIKE &qFirstName OR Clients.FirstName LIKE &qFirstNameTrans) AND ") + 
		?(IsBlankString(pSecondName), "", "(Clients.SecondName LIKE &qSecondName OR Clients.SecondName LIKE &qSecondNameTrans) AND ")) + 
		?(IsBlankString(pPhone), "", "Clients.Phone LIKE &qPhone AND ") + 
		?(IsBlankString(pEMail), "", "Clients.EMail LIKE &qEMail AND ") + 
		"Clients.DeletionMark = FALSE
	|ORDER BY 
	|	Description, 
	|	CreateDate";
	If pUseSubstringSearch Then
		qGetList.SetParameter("qDescription", "%"+pLastName+"%");
		If IsBlankString(pFirstName) Then
			qGetList.SetParameter("qFirstName", "%"+pLastName+"%");
		Else
			qGetList.SetParameter("qFirstName", "%"+pFirstName+"%");
		EndIf;
		If IsBlankString(pSecondName) Then
			qGetList.SetParameter("qSecondName", "%"+pLastName+"%");
		Else
			qGetList.SetParameter("qSecondName", "%"+pSecondName+"%");
		EndIf;
		// Transliterate names
		qGetList.SetParameter("qDescriptionTrans", "%"+cmTransliterate(pLastName)+"%");
		If IsBlankString(pFirstName) Then
			qGetList.SetParameter("qFirstNameTrans", "%"+cmTransliterate(pLastName)+"%");
		Else
			qGetList.SetParameter("qFirstNameTrans", "%"+cmTransliterate(pFirstName)+"%");
		EndIf;
		If IsBlankString(pSecondName) Then
			qGetList.SetParameter("qSecondNameTrans", "%"+cmTransliterate(pLastName)+"%");
		Else
			qGetList.SetParameter("qSecondNameTrans", "%"+cmTransliterate(pSecondName)+"%");
		EndIf;
	Else
		qGetList.SetParameter("qDescription", pLastName+"%");
		qGetList.SetParameter("qFirstName", pFirstName+"%");
		qGetList.SetParameter("qSecondName", pSecondName+"%");
		// Transliterate names
		qGetList.SetParameter("qDescriptionTrans", cmTransliterate(pLastName)+"%");
		qGetList.SetParameter("qFirstNameTrans", cmTransliterate(pFirstName)+"%");
		qGetList.SetParameter("qSecondNameTrans", cmTransliterate(pSecondName)+"%");
	EndIf;
	qGetList.SetParameter("qIdentityDocNumber", pIdentityDocNumber);
	qGetList.SetParameter("qIdentityDocSeries", pIdentityDocSeries);
	qGetList.SetParameter("qPhone", "%"+pPhone+"%");
	qGetList.SetParameter("qEMail", "%"+pEMail+"%");
	vList = qGetList.Execute().Unload();
	Return vList;
EndFunction // cmGetClientsList

// -----------------------------------------------------------------------------
// Description: Returns client's list filtered by client name, identity document 
//              data and phone number. Additionaly for each client found program 
//              checks whether there are any clients reserved together with this client 
//              in the same room and from the same guest group. If yes then those clients
//              are also being added to the return list
// Parameters: Client last name string, Client first name string, Client second name string,
//             Identity document number string, Identity document series string, Phone number string,
//             Boolean - Whether to use substring search for the client name (search requested string 
//             in any part of the name) or use search comparing first letters of name with requested 
//             string
// Return value: Value table with clients found
// -----------------------------------------------------------------------------
Function cmGetOneRoomResClientsList(pLastName, pFirstName, pSecondName, pIdentityDocNumber, pIdentityDocSeries, pPhone, pUseSubstringSearch = False) Export
	// Build and run query
	qGetList = New Query;
	qGetList.Text = 
	"SELECT
	|	Clients.Ref
	|INTO Clients
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	Clients.IsFolder = FALSE AND " + 
		?(IsBlankString(pIdentityDocNumber), "", "Clients.IdentityDocumentNumber = &qIdentityDocNumber AND ") + 
		?(IsBlankString(pIdentityDocSeries), "", "Clients.IdentityDocumentSeries = &qIdentityDocSeries AND ") + 
		?(pUseSubstringSearch,
			?(IsBlankString(pLastName), "", "(Clients.Description LIKE &qDescription OR Clients.Description LIKE &qDescriptionTrans OR Clients.FullName LIKE &qDescription OR Clients.FullName LIKE &qDescriptionTrans OR Clients.FirstName LIKE &qFirstName OR Clients.FirstName LIKE &qFirstNameTrans OR Clients.SecondName LIKE &qSecondName OR Clients.SecondName LIKE &qSecondNameTrans) AND "), 
			?(IsBlankString(pLastName), "", "(Clients.Description LIKE &qDescription OR Clients.Description LIKE &qDescriptionTrans OR Clients.FullName LIKE &qDescription OR Clients.FullName LIKE &qDescriptionTrans) AND ") + 
			?(IsBlankString(pFirstName), "", "(Clients.FirstName LIKE &qFirstName OR Clients.FirstName LIKE &qFirstNameTrans) AND ") + 
			?(IsBlankString(pSecondName), "", "(Clients.SecondName LIKE &qSecondName OR Clients.SecondName LIKE &qSecondNameTrans) AND ")) + 
		?(IsBlankString(pPhone), "", "Clients.Phone LIKE &qPhone AND ") + "
	|	Clients.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Reservations.Number,
	|	Reservations.Room,
	|	Reservations.GuestGroup
	|INTO Reservations
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Guest <> &qEmptyClient AND
	|	Reservations.Guest IN
	|			(SELECT
	|				Clients.Ref
	|			FROM
	|				Clients AS Clients)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ResClients.Ref AS Reservation,
	|	ResClients.Guest AS Ref,
	|	ResClients.Guest.Description AS Description,
	|	ResClients.Guest.LastName AS LastName,
	|	ResClients.Guest.FirstName AS FirstName,
	|	ResClients.Guest.SecondName AS SecondName,
	|	ResClients.Guest.Sex AS Sex,
	|	ResClients.Guest.DateOfBirth AS DateOfBirth,
	|	ResClients.Guest.IdentityDocumentType AS IdentityDocumentType,
	|	ResClients.Guest.IdentityDocumentSeries AS IdentityDocumentSeries,
	|	ResClients.Guest.IdentityDocumentNumber AS IdentityDocumentNumber,
	|	ResClients.Guest.IdentityDocumentIssueDate AS IdentityDocumentIssueDate,
	|	ResClients.Guest.Author AS Author,
	|	ResClients.Guest.CreateDate AS CreateDate
	|FROM
	|	Document.Reservation AS ResClients
	|WHERE
	|	ResClients.Number IN
	|		(SELECT
	|			Reservations.Number
	|		FROM
	|			Reservations AS Reservations)
	|		AND ResClients.GuestGroup IN 
	|			(SELECT
	|				Reservations.GuestGroup
	|			FROM
	|				Reservations AS Reservations
	|			WHERE
	|				Reservations.Room = &qEmptyRoom)
	|	OR ResClients.Room IN
	|		(SELECT
	|			Reservations.Room
	|		FROM
	|			Reservations AS Reservations
	|		WHERE
	|			Reservations.Room <> &qEmptyRoom)
	|		AND ResClients.GuestGroup IN
	|		(SELECT
	|			Reservations.GuestGroup
	|		FROM
	|			Reservations AS Reservations
	|		WHERE
	|			Reservations.Room <> &qEmptyRoom)
	|
	|ORDER BY
	|	Description,
	|	CreateDate";
	If pUseSubstringSearch Then
		qGetList.SetParameter("qDescription", pLastName+"%");
		If IsBlankString(pFirstName) Then
			qGetList.SetParameter("qFirstName", pLastName+"%");
		Else
			qGetList.SetParameter("qFirstName", pFirstName+"%");
		EndIf;
		If IsBlankString(pSecondName) Then
			qGetList.SetParameter("qSecondName", pLastName+"%");
		Else
			qGetList.SetParameter("qSecondName", pSecondName+"%");
		EndIf;
		// Transliterate names
		qGetList.SetParameter("qDescriptionTrans", cmTransliterate(pLastName)+"%");
		If IsBlankString(pFirstName) Then
			qGetList.SetParameter("qFirstNameTrans", cmTransliterate(pLastName)+"%");
		Else
			qGetList.SetParameter("qFirstNameTrans", cmTransliterate(pFirstName)+"%");
		EndIf;
		If IsBlankString(pSecondName) Then
			qGetList.SetParameter("qSecondNameTrans", cmTransliterate(pLastName)+"%");
		Else
			qGetList.SetParameter("qSecondNameTrans", cmTransliterate(pSecondName)+"%");
		EndIf;
	Else
		qGetList.SetParameter("qDescription", pLastName+"%");
		qGetList.SetParameter("qFirstName", pFirstName+"%");
		qGetList.SetParameter("qSecondName", pSecondName+"%");
		// Transliterate names
		qGetList.SetParameter("qDescriptionTrans", cmTransliterate(pLastName)+"%");
		qGetList.SetParameter("qFirstNameTrans", cmTransliterate(pFirstName)+"%");
		qGetList.SetParameter("qSecondNameTrans", cmTransliterate(pSecondName)+"%");
	EndIf;
	qGetList.SetParameter("qIdentityDocNumber", pIdentityDocNumber);
	qGetList.SetParameter("qIdentityDocSeries", pIdentityDocSeries);
	qGetList.SetParameter("qPhone", "%"+pPhone+"%");
	qGetList.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	qGetList.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vList = qGetList.Execute().Unload();
	Return vList;
EndFunction // cmGetOneRoomResClientsList

// -----------------------------------------------------------------------------
// Description: Returns client's list filtered by client name, identity document 
//              data and phone number. Additionaly for each client found program 
//              checks whether there are any clients living together with this client 
//              in the same room and from the same guest group. If yes then those clients
//              are also being added to the return list
// Parameters: Client last name string, Client first name string, Client second name string,
//             Identity document number string, Identity document series string, Phone number string,
//             Boolean - Whether to use substring search for the client name (search requested string 
//             in any part of the name) or use search comparing first letters of name with requested 
//             string
// Return value: Value table with clients found
// -----------------------------------------------------------------------------
Function cmGetOneRoomAccClientsList(pLastName, pFirstName, pSecondName, pIdentityDocNumber, pIdentityDocSeries, pPhone, pUseSubstringSearch = False) Export
	// Build and run query
	qGetList = New Query;
	qGetList.Text = 
	"SELECT
	|	Accommodations.Room,
	|	Accommodations.GuestGroup
	|INTO RoomsByGuestData
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Guest <> &qEmptyClient AND 
	|	Accommodations.Guest IN
	|		(SELECT
	|			Clients.Ref
	|		FROM
	|			Catalog.Clients AS Clients
	|		WHERE
	|			Clients.IsFolder = FALSE AND " + 
		?(IsBlankString(pIdentityDocNumber), "", "Clients.IdentityDocumentNumber = &qIdentityDocNumber AND ") + 
		?(IsBlankString(pIdentityDocSeries), "", "Clients.IdentityDocumentSeries = &qIdentityDocSeries AND ") + 
		?(pUseSubstringSearch,
			?(IsBlankString(pLastName), "", "(Clients.Description LIKE &qDescription OR Clients.Description LIKE &qDescriptionTrans OR Clients.FullName LIKE &qDescription OR Clients.FullName LIKE &qDescriptionTrans OR Clients.FirstName LIKE &qFirstName OR Clients.FirstName LIKE &qFirstNameTrans OR Clients.SecondName LIKE &qSecondName OR Clients.SecondName LIKE &qSecondNameTrans) AND "), 
			?(IsBlankString(pLastName), "", "(Clients.Description LIKE &qDescription OR Clients.Description LIKE &qDescriptionTrans OR Clients.FullName LIKE &qDescription OR Clients.FullName LIKE &qDescriptionTrans) AND ") + 
			?(IsBlankString(pFirstName), "", "(Clients.FirstName LIKE &qFirstName OR Clients.FirstName LIKE &qFirstNameTrans) AND ") + 
			?(IsBlankString(pSecondName), "", "(Clients.SecondName LIKE &qSecondName OR Clients.SecondName LIKE &qSecondNameTrans) AND ")) + 
		?(IsBlankString(pPhone), "", "Clients.Phone LIKE &qPhone AND ") + 
									 "Clients.DeletionMark = FALSE) 
	|GROUP BY
	|	Accommodations.Room,
	|	Accommodations.GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccClients.Ref AS Accommodation,
	|	AccClients.Guest AS Ref,
	|	AccClients.Guest.Description AS Description,
	|	AccClients.Guest.LastName AS LastName,
	|	AccClients.Guest.FirstName AS FirstName,
	|	AccClients.Guest.SecondName AS SecondName,
	|	AccClients.Guest.Sex AS Sex,
	|	AccClients.Guest.DateOfBirth AS DateOfBirth,
	|	AccClients.Guest.IdentityDocumentType AS IdentityDocumentType,
	|	AccClients.Guest.IdentityDocumentSeries AS IdentityDocumentSeries,
	|	AccClients.Guest.IdentityDocumentNumber AS IdentityDocumentNumber,
	|	AccClients.Guest.IdentityDocumentIssueDate AS IdentityDocumentIssueDate,
	|	AccClients.Guest.Author AS Author,
	|	AccClients.Guest.CreateDate AS CreateDate
	|FROM
	|	Document.Accommodation AS AccClients
	|INNER JOIN
	|	RoomsByGuestData
	|	ON RoomsByGuestData.Room = AccClients.Room
	|		AND RoomsByGuestData.GuestGroup = AccClients.GuestGroup
	|ORDER BY 
	|	AccClients.Guest.Description, 
	|	AccClients.Guest.CreateDate";
	If pUseSubstringSearch Then
		qGetList.SetParameter("qDescription", pLastName+"%");
		If IsBlankString(pFirstName) Then
			qGetList.SetParameter("qFirstName", pLastName+"%");
		Else
			qGetList.SetParameter("qFirstName", pFirstName+"%");
		EndIf;
		If IsBlankString(pSecondName) Then
			qGetList.SetParameter("qSecondName", pLastName+"%");
		Else
			qGetList.SetParameter("qSecondName", pSecondName+"%");
		EndIf;
		// Transliterate names
		qGetList.SetParameter("qDescriptionTrans", cmTransliterate(pLastName)+"%");
		If IsBlankString(pFirstName) Then
			qGetList.SetParameter("qFirstNameTrans", cmTransliterate(pLastName)+"%");
		Else
			qGetList.SetParameter("qFirstNameTrans", cmTransliterate(pFirstName)+"%");
		EndIf;
		If IsBlankString(pSecondName) Then
			qGetList.SetParameter("qSecondNameTrans", cmTransliterate(pLastName)+"%");
		Else
			qGetList.SetParameter("qSecondNameTrans", cmTransliterate(pSecondName)+"%");
		EndIf;
	Else
		qGetList.SetParameter("qDescription", pLastName+"%");
		qGetList.SetParameter("qFirstName", pFirstName+"%");
		qGetList.SetParameter("qSecondName", pSecondName+"%");
		// Transliterate names
		qGetList.SetParameter("qDescriptionTrans", cmTransliterate(pLastName)+"%");
		qGetList.SetParameter("qFirstNameTrans", cmTransliterate(pFirstName)+"%");
		qGetList.SetParameter("qSecondNameTrans", cmTransliterate(pSecondName)+"%");
	EndIf;
	qGetList.SetParameter("qIdentityDocNumber", pIdentityDocNumber);
	qGetList.SetParameter("qIdentityDocSeries", pIdentityDocSeries);
	qGetList.SetParameter("qPhone", "%"+pPhone+"%");
	qGetList.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vList = qGetList.Execute().Unload();
	Return vList;
EndFunction // cmGetOneRoomAccClientsList

// -----------------------------------------------------------------------------
// Description: Room main reservation for the given reservation number and guest group
// Parameters: Reservation number as string, Guest group item reference
// Return value: Room main reservation document reference or undefined if nothing is found
// -----------------------------------------------------------------------------
Function cmGetOneRoomReservation(pReservationNumber, pGuestGroup, pRoom = Undefined, pCheckInDate = '00010101', pCheckOutDate = '00010101') Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	(NOT &qRoomIsFilled
	|				AND Reservation.Number = &qNumber
	|			OR &qRoomIsFilled
	|				AND Reservation.Room = &qRoom)
	|	AND Reservation.GuestGroup = &qGuestGroup
	|	AND Reservation.Posted
	|	AND Reservation.ReservationStatus.IsActive
	|	AND Reservation.AccommodationType.Type = &qRoomAccommodationType
	|	AND (NOT &qCheckPeriod
	|			OR &qCheckPeriod
	|				AND Reservation.CheckInDate < &qCheckOutDate
	|				AND Reservation.CheckOutDate > &qCheckInDate)
	|
	|ORDER BY
	|	Reservation.Date,
	|	Reservation.PointInTime";
	vQry.SetParameter("qNumber", TrimAll(pReservationNumber));
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRoom));
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qRoomAccommodationType", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qCheckPeriod", (ValueIsFilled(pCheckInDate) And ValueIsFilled(pCheckOutDate) And pCheckOutDate > pCheckInDate));
	vQry.SetParameter("qCheckInDate", pCheckInDate);
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vOneRoomDocs = vQry.Execute().Unload();
	If vOneRoomDocs.Count() > 0 Then
		Return vOneRoomDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetOneRoomReservation

// -----------------------------------------------------------------------------
// Description: Room main reservation for the given reservation number and guest group
// Parameters: Reservation number as string, Guest group item referenc, Roome
// Return value: Room main reservation document reference or undefined if nothing is found
// -----------------------------------------------------------------------------
Function cmGetMainRoomReservation(pReservationNumber, pGuestGroup, pRoom = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Reservations.Ref AS Ref
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Number = &qNumber
	|	AND (NOT &qRoomIsFilled
	|			OR &qRoomIsFilled
	|				AND Reservations.Room = &qRoom)
	|	AND Reservations.GuestGroup = &qGuestGroup
	|	AND Reservations.Posted
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary)
	|
	|ORDER BY
	|	ISNULL(Reservations.AccommodationTemplate.Code, """") DESC,
	|	Reservations.AccommodationType.SortCode,
	|	Reservations.Date,
	|	Reservations.PointInTime";
	vQry.SetParameter("qNumber", TrimAll(pReservationNumber));
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRoom));
	vQry.SetParameter("qRoom", pRoom);
	vOneRoomDocs = vQry.Execute().Unload();
	If vOneRoomDocs.Count() > 0 Then
		Return vOneRoomDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetMainRoomReservation

// -----------------------------------------------------------------------------
// Description: Room main accommodation for the given reservation number and guest group
// Parameters: Reservation number as string, Guest group item reference, Room
// Return value: Room main accommodation document reference or undefined if nothing is found
// -----------------------------------------------------------------------------
Function cmGetMainRoomAccommodation(pReservationNumber, pGuestGroup, pRoom) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Accommodations.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Number = &qNumber
	|	AND Accommodations.Room = &qRoom
	|	AND Accommodations.GuestGroup = &qGuestGroup
	|	AND Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|
	|ORDER BY
	|	ISNULL(Accommodations.AccommodationTemplate.Code, """") DESC,
	|	Accommodations.AccommodationType.SortCode,
	|	Accommodations.Date,
	|	Accommodations.PointInTime";
	vQry.SetParameter("qNumber", TrimAll(pReservationNumber));
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qRoom", pRoom);
	vOneRoomDocs = vQry.Execute().Unload();
	If vOneRoomDocs.Count() > 0 Then
		Return vOneRoomDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetMainRoomAccommodation

// -----------------------------------------------------------------------------
// Description: Return room main reservation or accommodation for the given reservation number and guest group
// Parameters: Reservation number as string, Guest group item reference
// Return value: Room main accommodation or reservation document reference or undefined if nothing is found
// -----------------------------------------------------------------------------
Function cmGetMainRoomDocument(pReservationNumber, pGuestGroup) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Accommodations.Ref AS Ref,
	|	ISNULL(Accommodations.AccommodationTemplate.Code, """") AS AccommodationTemplateCode,
	|	Accommodations.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	Accommodations.Date AS DocDate,
	|	Accommodations.PointInTime AS DocPointInTime
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Number = &qNumber
	|	AND Accommodations.GuestGroup = &qGuestGroup
	|	AND Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Reservations.Ref,
	|	ISNULL(Reservations.AccommodationTemplate.Code, """"),
	|	Reservations.AccommodationType.SortCode,
	|	Reservations.Date,
	|	Reservations.PointInTime
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Number = &qNumber
	|	AND Reservations.GuestGroup = &qGuestGroup
	|	AND Reservations.Posted
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary)
	|
	|ORDER BY
	|	AccommodationTemplateCode DESC,
	|	AccommodationTypeSortCode,
	|	DocDate,
	|	DocPointInTime";
	vQry.SetParameter("qNumber", TrimAll(pReservationNumber));
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vOneRoomDocs = vQry.Execute().Unload();
	If vOneRoomDocs.Count() > 0 Then
		Return vOneRoomDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetMainRoomDocument

// -----------------------------------------------------------------------------
// Description: Returns list of one room reservations for the given reservation number and guest group
// Parameters: Reservation number as string, Guest group item reference, Accommodation period
// Return value: Value table with one room reservations
// -----------------------------------------------------------------------------
Function cmGetOneRoomReservations(pReservationNumber, pGuestGroup, pCheckInDate, pCheckOutDate, pGetInactive = False, pPosted = True) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.Ref AS Ref,
	|	Docs.Ref AS Reservation,
	|	Docs.ReservationStatus AS Status,
	|	Docs.AccommodationTemplate AS AccommodationTemplate,
	|	Docs.AccommodationType AS AccommodationType,
	|	Docs.AccommodationType.Type AS AccommodationTypeType,
	|	Docs.SortCode AS SortCode
	|FROM
	|	Document.Reservation AS Docs
	|WHERE
	|	Docs.Number = &qNumber
	|	AND Docs.GuestGroup = &qGuestGroup
	|	AND Docs.Posted
	|	AND (NOT &qGetInactive
	|				AND (Docs.ReservationStatus.IsActive
	|					OR Docs.ReservationStatus.IsPreliminary)
	|			OR &qGetInactive
	|				AND NOT(Docs.ReservationStatus.IsActive
	|						OR Docs.ReservationStatus.IsPreliminary))
	|	AND Docs.CheckInDate < &qCheckOutDate
	|	AND Docs.CheckOutDate > &qCheckInDate
	|	AND NOT Docs.RoomType.IsVirtual
	|
	|ORDER BY
	|	Docs.SortCode,
	|	Docs.PointInTime";
	vQry.SetParameter("qNumber", TrimAll(pReservationNumber));
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qCheckInDate", pCheckInDate);
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vQry.SetParameter("qGetInactive", pGetInactive);
	vOneRoomDocs = vQry.Execute().Unload();
	If vOneRoomDocs.Count() = 0 And Not pPosted Then
		vQry.Text = 
		"SELECT
		|	Docs.Ref AS Ref,
		|	Docs.Ref AS Reservation,
		|	Docs.ReservationStatus AS Status,
		|	Docs.AccommodationTemplate AS AccommodationTemplate,
		|	Docs.AccommodationType AS AccommodationType,
		|	Docs.AccommodationType.Type AS AccommodationTypeType,
		|	Docs.SortCode AS SortCode
		|FROM
		|	Document.Reservation AS Docs
		|WHERE
		|	Docs.Number = &qNumber
		|	AND Docs.GuestGroup = &qGuestGroup
		|	AND NOT Docs.Posted
		|	AND (NOT &qGetInactive
		|				AND (Docs.ReservationStatus.IsActive
		|					OR Docs.ReservationStatus.IsPreliminary)
		|			OR &qGetInactive
		|				AND NOT(Docs.ReservationStatus.IsActive
		|						OR Docs.ReservationStatus.IsPreliminary))
		|	AND Docs.CheckInDate < &qCheckOutDate
		|	AND Docs.CheckOutDate > &qCheckInDate
		|	AND NOT Docs.RoomType.IsVirtual
		|
		|ORDER BY
		|	Docs.SortCode,
		|	Docs.PointInTime";
		vQry.SetParameter("qNumber", TrimAll(pReservationNumber));
		vQry.SetParameter("qGuestGroup", pGuestGroup);
		vQry.SetParameter("qCheckInDate", pCheckInDate);
		vQry.SetParameter("qCheckOutDate", pCheckOutDate);
		vQry.SetParameter("qGetInactive", pGetInactive);
		vOneRoomDocs = vQry.Execute().Unload();
	EndIf;
	Return vOneRoomDocs;
EndFunction // cmGetOneRoomReservations

// -----------------------------------------------------------------------------
// Description: Returns number of one room reservation guests
// Parameters: Reservation number as string, Room item reference, Guest group item reference, Accommodation period
// Return value: Number of one room guests
// -----------------------------------------------------------------------------
Function cmGetNumberOfOneRoomReservationPersons(pReservationNumber, pRoom, pGuestGroup, pCheckInDate, pCheckOutDate) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(SUM(Docs.NumberOfPersons), 0) AS NumberOfPersons
	|FROM
	|	Document.Reservation AS Docs
	|WHERE
	|	Docs.Posted
	|	AND Docs.GuestGroup = &qGuestGroup
	|	AND (&qRoomIsEmpty AND Docs.Number = &qNumber OR NOT &qRoomIsEmpty AND Docs.Room = &qRoom)
	|	AND Docs.ReservationStatus.IsActive
	|	AND Docs.CheckInDate < &qCheckOutDate
	|	AND Docs.CheckOutDate > &qCheckInDate";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qNumber", TrimAll(pReservationNumber));
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qRoomIsEmpty", Not ValueIsFilled(pRoom));
	vQry.SetParameter("qCheckInDate", pCheckInDate);
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vOneRoomDocs = vQry.Execute().Unload();
	If vOneRoomDocs.Count() > 0 Then
		Return vOneRoomDocs.Get(0).NumberOfPersons;
	Else
		Return 0;
	EndIf;
EndFunction // cmGetNumberOfOneRoomReservationPersons

// -----------------------------------------------------------------------------
// Description: Returns one room accommodation with room accommodation type for 
//              the given room and guest group
// Parameters: Room item reference, Guest group item reference, Accommodation period
// Return value: Accommodation document reference
// -----------------------------------------------------------------------------
Function cmGetOneRoomAccommodation(pRoom, pGuestGroup, pCheckInDate, pCheckOutDate, pNumber = "") Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.Ref
	|FROM
	|	Document.Accommodation AS Docs
	|WHERE
	|	Docs.Room = &qRoom
	|	AND (&qNumberIsEmpty OR NOT &qNumberIsEmpty AND Docs.Number = &qNumber)
	|	AND Docs.GuestGroup = &qGuestGroup
	|	AND Docs.Posted
	|	AND Docs.AccommodationStatus.IsActive
	|	AND Docs.CheckInDate < &qCheckOutDate
	|	AND Docs.CheckOutDate > &qCheckInDate
	|	AND Docs.AccommodationType.Type = &qRoomAccommodationType
	|ORDER BY
	|	Docs.Date,
	|	Docs.PointInTime";
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qNumber", pNumber);
	vQry.SetParameter("qNumberIsEmpty", IsBlankString(pNumber));
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qCheckInDate", pCheckInDate);
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vQry.SetParameter("qRoomAccommodationType", Enums.AccomodationTypes.Room);
	vOneRoomDocs = vQry.Execute().Unload();
	If vOneRoomDocs.Count() > 0 Then
		Return vOneRoomDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetOneRoomAccommodation

// -----------------------------------------------------------------------------
// Description: Returns list of one room accommodations for the given room and guest group
// Parameters: Room item reference, Guest group item reference, Accommodation period
// Return value: Value table with one room accommodations
// -----------------------------------------------------------------------------
Function cmGetOneRoomAccommodations(pRoom, pGuestGroup, pCheckInDate, pCheckOutDate, pNumber = "", pPosted = True, pMaxNumberOfBedsPerRoom = 7) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.Ref AS Ref,
	|	Docs.AccommodationTemplate AS AccommodationTemplate,
	|	Docs.AccommodationType AS AccommodationType,
	|	Docs.AccommodationType.Type AS AccommodationTypeType,
	|	Docs.SortCode AS SortCode
	|FROM
	|	Document.Accommodation AS Docs
	|WHERE
	|	Docs.GuestGroup = &qGuestGroup
	|	AND (&qRoomIsFilled
	|				AND Docs.Room = &qRoom
	|			OR NOT &qRoomIsFilled)
	|	AND (&qNumberIsFilled
	|				AND Docs.Number = &qNumber
	|			OR NOT &qNumberIsFilled)
	|	AND Docs.Posted
	|	AND Docs.AccommodationStatus.IsActive
	|	AND Docs.CheckInDate < &qCheckOutDate
	|	AND Docs.CheckOutDate > &qCheckInDate
	|	AND NOT Docs.RoomType.IsVirtual
	|	AND Docs.RoomType.NumberOfBedsPerRoom < &qMaxNumberOfBedsPerRoom
	|
	|ORDER BY
	|	Docs.SortCode,
	|	Docs.PointInTime";
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRoom));
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qCheckInDate", pCheckInDate);
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vQry.SetParameter("qNumber", pNumber);
	vQry.SetParameter("qNumberIsFilled", ValueIsFilled(pNumber));
	vQry.SetParameter("qMaxNumberOfBedsPerRoom", pMaxNumberOfBedsPerRoom);
	vOneRoomDocs = vQry.Execute().Unload();
	If vOneRoomDocs.Count() = 0 And Not pPosted Then
		vQry.Text = 
		"SELECT
		|	Docs.Ref AS Ref,
		|	Docs.AccommodationTemplate AS AccommodationTemplate,
		|	Docs.AccommodationType AS AccommodationType,
		|	Docs.AccommodationType.Type AS AccommodationTypeType,
		|	Docs.SortCode AS SortCode
		|FROM
		|	Document.Accommodation AS Docs
		|WHERE
		|	Docs.GuestGroup = &qGuestGroup
		|	AND (&qRoomIsFilled
		|				AND Docs.Room = &qRoom
		|			OR NOT &qRoomIsFilled)
		|	AND (&qNumberIsFilled
		|				AND Docs.Number = &qNumber
		|			OR NOT &qNumberIsFilled)
		|	AND NOT Docs.Posted
		|	AND Docs.AccommodationStatus.IsActive
		|	AND Docs.CheckInDate < &qCheckOutDate
		|	AND Docs.CheckOutDate > &qCheckInDate
		|	AND NOT Docs.RoomType.IsVirtual
		|	AND Docs.RoomType.NumberOfBedsPerRoom < &qMaxNumberOfBedsPerRoom
		|
		|ORDER BY
		|	Docs.SortCode,
		|	Docs.PointInTime";
		vQry.SetParameter("qRoom", pRoom);
		vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRoom));
		vQry.SetParameter("qGuestGroup", pGuestGroup);
		vQry.SetParameter("qCheckInDate", pCheckInDate);
		vQry.SetParameter("qCheckOutDate", pCheckOutDate);
		vQry.SetParameter("qNumber", pNumber);
		vQry.SetParameter("qNumberIsFilled", ValueIsFilled(pNumber));
		vQry.SetParameter("qMaxNumberOfBedsPerRoom", pMaxNumberOfBedsPerRoom);
		vOneRoomDocs = vQry.Execute().Unload();
	EndIf;
	Return vOneRoomDocs;
EndFunction // cmGetOneRoomAccommodations

// -----------------------------------------------------------------------------
// Description: Returns client's presentation string being built from client  
//              full name, birth date, identity document data and client remarks
// Parameters: Value table row or Structure with client data
// Return value: Client presentation string
// -----------------------------------------------------------------------------
Function cmGetClientPresentation(pRow) Export
	vD = TrimAll(pRow.Description);
	vLN = TrimAll(pRow.LastName);
	vFN = TrimAll(pRow.FirstName);
	vSN = TrimAll(pRow.SecondName);
	vDB = pRow.DateOfBirth;
	vIT = TrimAll(pRow.IdentityDocumentType);
	vIS = TrimAll(pRow.IdentityDocumentSeries);
	vIN = TrimAll(pRow.IdentityDocumentNumber);
	vID = pRow.IdentityDocumentIssueDate;
	vR = TrimAll(pRow.Ref.Remarks);
	vN = vLN + ?(vFN="", "", " " + vFN) + ?(vSN="", "", " " + vSN) + 
	     ?(ValueIsFilled(vDB), NStr("ru = ', р.'; en = ', b.'; de = ', g.d.'") + Format(vDB, "DF='dd-MM-yyyy'"), "") + 
	     ?(vIN="", "", ", " + vIT + NStr("ru = ' №'; en = ' N'; de = ' Nr.'") + vIS + " " + vIN) + 
	     ?(vR="", "", ", " + vR) + 
	     "               ";
	Return vN;
EndFunction // cmGetClientPresentation

// -----------------------------------------------------------------------------
// Description: Calculates number of guests/rooms being already checked-in by  
//              given reservation
// Parameters: Reservation document reference
// Return value: Value table with one row for the given reservation
// -----------------------------------------------------------------------------
Function cmGetWriteOffsForReservation(pReservation) Export
	// Calculate write off done by accommodations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventory.ParentDoc,
	|	SUM(RoomInventory.RoomsCheckedIn) AS RoomsCheckedIn,
	|	SUM(RoomInventory.BedsCheckedIn) AS BedsCheckedIn,
	|	SUM(RoomInventory.AdditionalBedsCheckedIn) AS AdditionalBedsCheckedIn,
	|	SUM(RoomInventory.GuestsCheckedIn) AS GuestsCheckedIn
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.ParentDoc = &qParentDoc
	|	AND RoomInventory.RecordType = &qRecordType
	|GROUP BY
	|	RoomInventory.ParentDoc";
	vQry.SetParameter("qParentDoc", pReservation);
	vQry.SetParameter("qRecordType", AccumulationRecordType.Expense);
	vWriteOffs = vQry.Execute().Unload();
	Return vWriteOffs;
EndFunction // cmGetWriteOffsForReservation

// -----------------------------------------------------------------------------
// Description: Calculates number of guests/rooms being already checked-in for  
//              the given reservation's value list
// Parameters: Value list with reservations
// Return value: Value table with rows for each reservation from the input list
// -----------------------------------------------------------------------------
Function cmGetCheckedInGuestsForReservationsList(pResList) Export
	// Calculate write off done by accommodations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventory.ParentDoc AS ParentDoc,
	|	RoomInventory.ParentDoc.AccommodationType AS AccommodationType,
	|	SUM(RoomInventory.RoomsCheckedIn) AS RoomsCheckedIn,
	|	SUM(RoomInventory.BedsCheckedIn) AS BedsCheckedIn,
	|	SUM(RoomInventory.AdditionalBedsCheckedIn) AS AdditionalBedsCheckedIn,
	|	SUM(RoomInventory.GuestsCheckedIn) AS GuestsCheckedIn
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.ParentDoc IN(&qDocList)
	|	AND RoomInventory.RecordType = &qRecordType
	|	AND RoomInventory.Period = RoomInventory.CheckInDate
	|
	|GROUP BY
	|	RoomInventory.ParentDoc,
	|	RoomInventory.ParentDoc.AccommodationType";
	vQry.SetParameter("qDocList", pResList);
	vQry.SetParameter("qRecordType", AccumulationRecordType.Expense);
	vCheckedInGuests = vQry.Execute().Unload();
	Return vCheckedInGuests;
EndFunction // cmGetCheckedInGuestsForReservationsList

// -----------------------------------------------------------------------------
// Description: Returns value table of accommodations being already checked-in for  
//              the given reservation's value list
// Parameters: Value list with reservations
// Return value: Value table with rows of accommodations for each reservation 
//               from the input list
// -----------------------------------------------------------------------------
Function cmGetCheckedInAccommodationsForReservationsList(pResList) Export
	// Calculate write off done by accommodations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodations.ParentDoc AS ParentDoc,
	|	Accommodations.Ref AS Accommodation,
	|	Accommodations.RoomType AS RoomType,
	|	Accommodations.RoomType.Code AS RoomTypeCode,
	|	Accommodations.RoomType.Description AS RoomTypeDescription,
	|	Accommodations.RoomRate AS RoomRate,
	|	Accommodations.RoomRate.Description AS RoomRateDescription,
	|	Accommodations.ServicePackage AS ServicePackage,
	|	Accommodations.ServicePackage.Description AS ServicePackageDescription,
	|	Accommodations.AccommodationType AS AccommodationType,
	|	Accommodations.AccommodationType.Description AS AccommodationTypeDescription,
	|	Accommodations.CheckInDate AS CheckInDate,
	|	Accommodations.Duration AS Duration,
	|	Accommodations.CheckOutDate AS CheckOutDate,
	|	Accommodations.Guest AS Guest,
	|	Accommodations.Guest.FullName AS GuestFullName,
	|	Accommodations.Guest.Description AS GuestDescription
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.ParentDoc IN(&qDocList)
	|	AND Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|
	|ORDER BY
	|	Accommodations.Date,
	|	Accommodations.PointInTime";
	vQry.SetParameter("qDocList", pResList);
	vQry.SetParameter("qRecordType", AccumulationRecordType.Expense);
	vCheckedInGuests = vQry.Execute().Unload();
	Return vCheckedInGuests;
EndFunction // cmGetCheckedInAccommodationsForReservationsList

// -----------------------------------------------------------------------------
// Description: Returns minimum number of vacant rooms/beds for the period given  
// Parameters: Hotel, Room type to filter output, Room to filter output,
//             Begin of period date, End of period date
// Return value: Value table with one row for the hotel with numbers of vacant 
//               rooms and beds
// -----------------------------------------------------------------------------
Function cmGetRestOfVacantRooms(pHotel, pRoomType, pRoom, pDateFrom, pDateTo) Export
	// Common checks	
	If Not ValueIsFilled(pHotel) Then
		Raise(NStr("en='ERR: Error calling cmGetRestOfVacantRooms function.
		               |CAUSE: Empty pHotel parameter value was passed to the function.
					   |DESC: Mandatory parameter pHotel should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetRestOfVacantRooms.
				       |CAUSE: В функцию передано пустое значение параметра pHotel.
					   |DESC: Обязательный параметр pHotel должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetOfVacantRooms.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pHotel übertragen.
					   |DESC: Das Pflichtparameter pHotel muss eindeutig angegeben sein.'"));
	EndIf;
	
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	MIN(RoomInventoryBalance.CounterClosingBalance) AS CounterClosingBalance,
	|	MIN(RoomInventoryBalance.TotalBedsClosingBalance) AS TotalBeds,
	|	MIN(RoomInventoryBalance.TotalRoomsClosingBalance) AS TotalRooms,
	|	MIN(RoomInventoryBalance.RoomsVacantClosingBalance) AS RoomsVacant,
	|	MIN(RoomInventoryBalance.BedsVacantClosingBalance) AS BedsVacant
	|
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qDateFrom, &qDateTo, 
	|	                                                       Second, 
	|	                                                       RegisterRecordsAndPeriodBoundaries, 
	|	                                                       Hotel = &qHotel" +
		                                                       ?(ValueIsFilled(pRoomType), " AND RoomType = &qRoomType", "") + 
		                                                       ?(ValueIsFilled(pRoom), " AND Room = &qRoom", "") + "
	|) AS RoomInventoryBalance
	|
	|GROUP BY
	|	RoomInventoryBalance.Hotel";
	
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qDateTo", New Boundary(pDateTo, BoundaryType.Excluding));
	
	vQryTab = vQry.Execute().Unload();
	
	Return vQryTab;
EndFunction // cmGetRestOfVacantRooms

// -----------------------------------------------------------------------------
// Description: Returns value table. Each value table row has period with number 
//              of rooms/beds vacant for this period. All periods are inside period
//              being specified as input parameter
// Parameters: Hotel, Room type to filter output, Room to filter output,
//             Begin of period date, End of period date
// Return value: Value table with numbers of vacant rooms and beds
// -----------------------------------------------------------------------------
Function cmGetVacantRoomsByPeriodsForAccommodation(pHotel, pRoomType, pRoom, pDateFrom, pDateTo) Export
	// Common checks	
	If Not ValueIsFilled(pHotel) Then
		Raise(NStr("en='ERR: Error calling cmGetVacantRoomsByPeriods function.
		               |CAUSE: Empty pHotel parameter value was passed to the function.
					   |DESC: Mandatory parameter pHotel should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetVacantRoomsByPeriods.
				       |CAUSE: В функцию передано пустое значение параметра pHotel.
					   |DESC: Обязательный параметр pHotel должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetVacantRoomsByPeriods.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pHotel übertragen.
					   |DESC: Das Pflichtparameter pHotel muss eindeutig angegeben sein.'"));
	EndIf;
	
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	RoomInventoryBalance.Period AS PeriodFrom,
	|	RoomInventoryBalance.Period AS PeriodTo,
	|	RoomInventoryBalance.CounterClosingBalance AS CounterClosingBalance,
	|	RoomInventoryBalance.TotalBedsClosingBalance AS TotalBeds,
	|	RoomInventoryBalance.TotalRoomsClosingBalance AS TotalRooms,
	|	RoomInventoryBalance.RoomsVacantClosingBalance AS RoomsVacant,
	|	RoomInventoryBalance.BedsVacantClosingBalance AS BedsVacant
	|
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qDateFrom, &qDateTo, 
	|	                                                       Second, 
	|	                                                       RegisterRecordsAndPeriodBoundaries, 
	|	                                                       Hotel = &qHotel" +
		                                                       ?(ValueIsFilled(pRoomType), ?(pRoomType.IsFolder, " AND RoomType IN HIERARCHY(&qRoomType)", " AND RoomType = &qRoomType"), "") + 
		                                                       ?(ValueIsFilled(pRoom), ?(pRoom.IsFolder, " AND Room IN HIERARCHY(&qRoom)", " AND Room = &qRoom"), "") + "
	|) AS RoomInventoryBalance
	|ORDER BY
	|	RoomInventoryBalance.RoomType.SortCode,
	|	RoomInventoryBalance.Period";
	
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qDateTo", New Boundary(pDateTo, BoundaryType.Excluding));
	
	vQryTab = vQry.Execute().Unload();
	
	// Process query tab joining adjacent rows into the one with period from and period to columns
	i = 0;
	While i < (vQryTab.Count() - 1) Do
		vCurRow = vQryTab.Get(i);
		vNextRow = vQryTab.Get(i + 1);
		If vCurRow.RoomType = vNextRow.RoomType Then
			vCurRow.PeriodTo = vNextRow.PeriodFrom;
			If vCurRow.RoomsVacant = vNextRow.RoomsVacant And 
			   vCurRow.BedsVacant = vNextRow.BedsVacant Then
				vQryTab.Delete(i + 1);
			Else
				i = i + 1;
			EndIf;
		Else
			i = i + 1;
		EndIf;
	EndDo;
	
	// Remove not joined rows 
	i = 0;
	While i < vQryTab.Count() Do
		vCurRow = vQryTab.Get(i);
		If vCurRow.PeriodFrom = vCurRow.PeriodTo Then
			vQryTab.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	
	// Return resulting table
	Return vQryTab;
EndFunction // cmGetVacantRoomsByPeriodsForAccommodation

// -----------------------------------------------------------------------------
// Description: Returns value table. Each value table row has period with number 
//              of rooms/beds vacant for this period. All periods are inside period
//              being specified as input parameter
// Parameters: Hotel, Room type to filter output, Room to filter output, Room quota to filter output
//             Begin of period date, End of period date
// Return value: Value table with numbers of vacant rooms and beds
// -----------------------------------------------------------------------------
Function cmGetVacantRoomsByPeriodsForReservation(pHotel, pRoomType, pRoom, pRoomQuota, pDateFrom, pDateTo) Export
	// Common checks	
	If Not ValueIsFilled(pHotel) Then
		Raise(NStr("en='ERR: Error calling cmGetVacantRoomsByPeriods function.
		               |CAUSE: Empty pHotel parameter value was passed to the function.
					   |DESC: Mandatory parameter pHotel should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetVacantRoomsByPeriods.
				       |CAUSE: В функцию передано пустое значение параметра pHotel.
					   |DESC: Обязательный параметр pHotel должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetVacantRoomsByPeriods.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pHotel übertragen.
					   |DESC: Das Pflichtparameter pHotel muss eindeutig angegeben sein.'"));
				   EndIf;
	// Initialize room
	vRoom = pRoom;
	
	// Build and run query
	vQry = New Query;
	If Not ValueIsFilled(pRoomQuota) Or ValueIsFilled(pRoomQuota) And Not pRoomQuota.IsQuotaForRooms And ValueIsFilled(vRoom) Then
		vQry.SetParameter("qRoom", vRoom);
		vQry.Text = 
		"SELECT
		|	RoomInventoryBalance.Hotel AS Hotel,
		|	RoomInventoryBalance.RoomType AS RoomType,
		|	RoomInventoryBalance.Period AS PeriodFrom,
		|	RoomInventoryBalance.Period AS PeriodTo,
		|	RoomInventoryBalance.CounterClosingBalance AS CounterClosingBalance,
		|	RoomInventoryBalance.TotalBedsClosingBalance AS TotalBeds,
		|	RoomInventoryBalance.TotalRoomsClosingBalance AS TotalRooms,
		|	RoomInventoryBalance.RoomsVacantClosingBalance AS RoomsVacant,
		|	RoomInventoryBalance.BedsVacantClosingBalance AS BedsVacant
		|
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qDateFrom, &qDateTo, 
		|	                                                       Second, 
		|	                                                       RegisterRecordsAndPeriodBoundaries, 
		|	                                                       Hotel = &qHotel" +
			                                                       ?(ValueIsFilled(pRoomType), ?(pRoomType.IsFolder, " AND RoomType IN HIERARCHY(&qRoomType)", " AND RoomType = &qRoomType"), "") + 
			                                                       ?(ValueIsFilled(vRoom), ?(vRoom.IsFolder, " AND Room IN HIERARCHY(&qRoom)", " AND Room = &qRoom"), "") + "
		|) AS RoomInventoryBalance
		|ORDER BY
		|	RoomInventoryBalance.RoomType.SortCode,
		|	RoomInventoryBalance.Period";
	Else
		vQry.SetParameter("qRoomQuota", pRoomQuota);
		If ValueIsFilled(vRoom) Then
			If vRoom.IsFolder Then
				vQry.SetParameter("qRoom", vRoom);
			Else
				If pRoomQuota.IsQuotaForRooms Then
					vQry.SetParameter("qRoom", vRoom);
				Else
					vRoom = Undefined;
				EndIf;
			EndIf;
		EndIf;
		vQry.Text = 
		"SELECT
		|	RoomQuotaBalance.Hotel AS Hotel,
		|	RoomQuotaBalance.RoomType AS RoomType,
		|	RoomQuotaBalance.Period AS PeriodFrom,
		|	RoomQuotaBalance.Period AS PeriodTo,
		|	RoomQuotaBalance.CounterClosingBalance AS CounterClosingBalance,
		|	RoomQuotaBalance.BedsInQuotaClosingBalance AS TotalBeds,
		|	RoomQuotaBalance.RoomsInQuotaClosingBalance AS TotalRooms,
		|	RoomQuotaBalance.RoomsRemainsClosingBalance AS RoomsVacant,
		|	RoomQuotaBalance.BedsRemainsClosingBalance AS BedsVacant
		|
		|FROM
		|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(&qDateFrom, &qDateTo, 
		|	                                                       Minute, 
		|	                                                       RegisterRecordsAndPeriodBoundaries, 
		|	                                                       Hotel = &qHotel 
		|	                                                       AND RoomQuota = &qRoomQuota" + 
			                                                       ?(ValueIsFilled(pRoomType), ?(pRoomType.IsFolder, " AND RoomType IN HIERARCHY(&qRoomType)", " AND RoomType = &qRoomType"), "") + 
			                                                       ?(ValueIsFilled(vRoom), ?(vRoom.IsFolder, " AND Room IN HIERARCHY(&qRoom)", " AND Room = &qRoom"), "") + "
		|) AS RoomQuotaBalance
		|ORDER BY
		|	RoomQuotaBalance.RoomType.SortCode,
		|	RoomQuotaBalance.Period";
	EndIf;
	
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qDateTo", New Boundary(pDateTo, BoundaryType.Excluding));
	
	vQryTab = vQry.Execute().Unload();
	
	// Process query tab joining adjacent rows into the one with period from and period to columns
	i = 0;
	While i < (vQryTab.Count() - 1) Do
		vCurRow = vQryTab.Get(i);
		vNextRow = vQryTab.Get(i + 1);
		If vCurRow.RoomType = vNextRow.RoomType Then
			vCurRow.PeriodTo = vNextRow.PeriodFrom;
			If vCurRow.RoomsVacant = vNextRow.RoomsVacant And 
			   vCurRow.BedsVacant = vNextRow.BedsVacant Then
				vQryTab.Delete(i + 1);
			Else
				i = i + 1;
			EndIf;
		Else
			i = i + 1;
		EndIf;
	EndDo;
	
	// Remove not joined rows 
	i = 0;
	While i < vQryTab.Count() Do
		vCurRow = vQryTab.Get(i);
		If vCurRow.PeriodFrom = vCurRow.PeriodTo Then
			vQryTab.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	
	// Return resulting table
	Return vQryTab;
EndFunction // cmGetVacantRoomsByPeriodsForReservation

// -----------------------------------------------------------------------------
// Description: Returns accommodations or reservations intersecting by period 
//              with given document
// Parameters: Accommodation or reservation reference, Whether to check intersection 
//             for the documents from the same room only or not
// Return value: Value table with list of intersected documents
// -----------------------------------------------------------------------------
Function cmGetTableOfIntersectedDocs(pPeriod, pRoomIntersectionOnly = False) Export
	// Build and run main query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	BaseSetOfRecords.Recorder AS Recorder,
	|	BaseSetOfRecords.PeriodFrom AS PeriodFrom,
	|	BaseSetOfRecords.PeriodTo AS PeriodTo,
	|	BaseSetOfRecords.Room AS Room
	|INTO BaseSetOfRecords
	|FROM
	|	AccumulationRegister.RoomInventory AS BaseSetOfRecords
	|WHERE
	|	BaseSetOfRecords.PeriodFrom >= &qPeriodFrom
	|	AND BaseSetOfRecords.PeriodFrom <= &qPeriodTo
	|	AND BaseSetOfRecords.RoomType = &qRoomType
	|	AND BaseSetOfRecords.RoomType.IsVirtual = FALSE
	|	AND BaseSetOfRecords.RecordType = &qExpense
	|	AND BaseSetOfRecords.RoomsVacant <> 0
	|	AND BaseSetOfRecords.BedsVacant <> 0
	|	AND BaseSetOfRecords.BedsVacant < BaseSetOfRecords.NumberOfBedsPerRoom
	|	AND BaseSetOfRecords.Recorder <> &qCurDoc
	|	AND (BaseSetOfRecords.Recorder REFS Document.Accommodation
	|			OR BaseSetOfRecords.Recorder REFS Document.Reservation)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(MinCheckInDates1.PeriodFrom) AS NextPeriodFrom1
	|INTO AfterCheckIn1Room
	|FROM
	|	BaseSetOfRecords AS MinCheckInDates1
	|WHERE
	|	MinCheckInDates1.Room = &qRoom
	|	AND &qRoomIsFilled = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(MinCheckInDates2.PeriodFrom) AS NextPeriodFrom2
	|INTO AfterCheckIn1EmptyRoom
	|FROM
	|	BaseSetOfRecords AS MinCheckInDates2
	|WHERE
	|	MinCheckInDates2.Room = &qEmptyRoom
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(MinCheckInDates3.PeriodFrom) AS NextPeriodFrom3
	|INTO AfterCheckIn0Room
	|FROM
	|	BaseSetOfRecords AS MinCheckInDates3
	|WHERE
	|	MinCheckInDates3.Room = &qRoom
	|	AND &qRoomIsFilled = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(MinCheckInDates4.PeriodFrom) AS NextPeriodFrom4
	|INTO AfterCheckIn0EmptyRoom
	|FROM
	|	BaseSetOfRecords AS MinCheckInDates4
	|WHERE
	|	MinCheckInDates4.Room = &qEmptyRoom
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(MaxCheckOutDates5.PeriodFrom) AS PrevPeriodFrom5
	|INTO BeforeCheckIn1Room
	|FROM
	|	BaseSetOfRecords AS MaxCheckOutDates5
	|WHERE
	|	MaxCheckOutDates5.Room = &qRoom
	|	AND &qRoomIsFilled = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(MaxCheckOutDates6.PeriodFrom) AS PrevPeriodFrom6
	|INTO BeforeCheckIn1EmptyRoom
	|FROM
	|	BaseSetOfRecords AS MaxCheckOutDates6
	|WHERE
	|	MaxCheckOutDates6.Room = &qEmptyRoom
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(MaxCheckOutDates7.PeriodFrom) AS PrevPeriodFrom7
	|INTO BeforeCheckIn0Room
	|FROM
	|	BaseSetOfRecords AS MaxCheckOutDates7
	|WHERE
	|	MaxCheckOutDates7.Room = &qRoom
	|	AND &qRoomIsFilled = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(MaxCheckOutDates8.PeriodFrom) AS PrevPeriodFrom8
	|INTO BeforeCheckIn0EmptyRoom
	|FROM
	|	BaseSetOfRecords AS MaxCheckOutDates8
	|WHERE
	|	MaxCheckOutDates8.Room = &qEmptyRoom
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.Ref AS Ref,
	|	RoomInventory.Room AS Room,
	|	RoomInventory.CheckInDate AS CheckInDate,
	|	RoomInventory.CheckOutDate AS CheckOutDate,
	|	RoomInventory.Ref.PointInTime AS PointInTime,
	|	RoomInventory.SortCode AS SortCode,
	|	FALSE AS Reposted,
	|	FALSE AS Cleared
	|FROM
	|	(SELECT
	|		AfterCheckInDocs1Room.Recorder AS Ref,
	|		AfterCheckInDocs1Room.Room AS Room,
	|		AfterCheckInDocs1Room.PeriodFrom AS CheckInDate,
	|		AfterCheckInDocs1Room.PeriodTo AS CheckOutDate,
	|		1 AS SortCode
	|	FROM
	|		BaseSetOfRecords AS AfterCheckInDocs1Room
	|			INNER JOIN AfterCheckIn1Room AS AfterCheckIn1Room
	|			ON AfterCheckInDocs1Room.PeriodFrom = AfterCheckIn1Room.NextPeriodFrom1
	|	WHERE
	|		AfterCheckInDocs1Room.Room = &qRoom
	|		AND &qRoomIsFilled = TRUE
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AfterCheckInDocs1EmptyRoom.Recorder,
	|		AfterCheckInDocs1EmptyRoom.Room,
	|		AfterCheckInDocs1EmptyRoom.PeriodFrom,
	|		AfterCheckInDocs1EmptyRoom.PeriodTo,
	|		2
	|	FROM
	|		BaseSetOfRecords AS AfterCheckInDocs1EmptyRoom
	|			INNER JOIN AfterCheckIn1EmptyRoom AS AfterCheckIn1EmptyRoom
	|			ON AfterCheckInDocs1EmptyRoom.PeriodFrom = AfterCheckIn1EmptyRoom.NextPeriodFrom2
	|	WHERE
	|		AfterCheckInDocs1EmptyRoom.Room = &qEmptyRoom
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AfterCheckInDocs0Room.Recorder,
	|		AfterCheckInDocs0Room.Room,
	|		AfterCheckInDocs0Room.PeriodFrom,
	|		AfterCheckInDocs0Room.PeriodTo,
	|		3
	|	FROM
	|		BaseSetOfRecords AS AfterCheckInDocs0Room
	|			INNER JOIN AfterCheckIn0Room AS AfterCheckIn0Room
	|			ON AfterCheckInDocs0Room.PeriodFrom = AfterCheckIn0Room.NextPeriodFrom3
	|	WHERE
	|		AfterCheckInDocs0Room.Room = &qRoom
	|		AND &qRoomIsFilled = TRUE
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AfterCheckInDocs0EmptyRoom.Recorder,
	|		AfterCheckInDocs0EmptyRoom.Room,
	|		AfterCheckInDocs0EmptyRoom.PeriodFrom,
	|		AfterCheckInDocs0EmptyRoom.PeriodTo,
	|		4
	|	FROM
	|		BaseSetOfRecords AS AfterCheckInDocs0EmptyRoom
	|			INNER JOIN AfterCheckIn0EmptyRoom AS AfterCheckIn0EmptyRoom
	|			ON AfterCheckInDocs0EmptyRoom.PeriodFrom = AfterCheckIn0EmptyRoom.NextPeriodFrom4
	|	WHERE
	|		AfterCheckInDocs0EmptyRoom.Room = &qEmptyRoom
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BeforeCheckInDocs1Room.Recorder,
	|		BeforeCheckInDocs1Room.Room,
	|		BeforeCheckInDocs1Room.PeriodFrom,
	|		BeforeCheckInDocs1Room.PeriodTo,
	|		5
	|	FROM
	|		BaseSetOfRecords AS BeforeCheckInDocs1Room
	|			INNER JOIN BeforeCheckIn1Room AS BeforeCheckIn1Room
	|			ON BeforeCheckInDocs1Room.PeriodFrom = BeforeCheckIn1Room.PrevPeriodFrom5
	|	WHERE
	|		BeforeCheckInDocs1Room.Room = &qRoom
	|		AND &qRoomIsFilled = TRUE
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BeforeCheckInDocs1EmptyRoom.Recorder,
	|		BeforeCheckInDocs1EmptyRoom.Room,
	|		BeforeCheckInDocs1EmptyRoom.PeriodFrom,
	|		BeforeCheckInDocs1EmptyRoom.PeriodTo,
	|		6
	|	FROM
	|		BaseSetOfRecords AS BeforeCheckInDocs1EmptyRoom
	|			INNER JOIN BeforeCheckIn1EmptyRoom AS BeforeCheckIn1EmptyRoom
	|			ON BeforeCheckInDocs1EmptyRoom.PeriodFrom = BeforeCheckIn1EmptyRoom.PrevPeriodFrom6
	|	WHERE
	|		BeforeCheckInDocs1EmptyRoom.Room = &qEmptyRoom
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BeforeCheckInDocs0Room.Recorder,
	|		BeforeCheckInDocs0Room.Room,
	|		BeforeCheckInDocs0Room.PeriodFrom,
	|		BeforeCheckInDocs0Room.PeriodTo,
	|		7
	|	FROM
	|		BaseSetOfRecords AS BeforeCheckInDocs0Room
	|			INNER JOIN BeforeCheckIn0Room AS BeforeCheckIn0Room
	|			ON BeforeCheckInDocs0Room.PeriodFrom = BeforeCheckIn0Room.PrevPeriodFrom7
	|	WHERE
	|		BeforeCheckInDocs0Room.Room = &qRoom
	|		AND &qRoomIsFilled = TRUE
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BeforeCheckInDocs0EmptyRoom.Recorder,
	|		BeforeCheckInDocs0EmptyRoom.Room,
	|		BeforeCheckInDocs0EmptyRoom.PeriodFrom,
	|		BeforeCheckInDocs0EmptyRoom.PeriodTo,
	|		8
	|	FROM
	|		BaseSetOfRecords AS BeforeCheckInDocs0EmptyRoom
	|			INNER JOIN BeforeCheckIn0EmptyRoom AS BeforeCheckIn0EmptyRoom
	|			ON BeforeCheckInDocs0EmptyRoom.PeriodFrom = BeforeCheckIn0EmptyRoom.PrevPeriodFrom8
	|	WHERE
	|		BeforeCheckInDocs0EmptyRoom.Room = &qEmptyRoom) AS RoomInventory
	|
	|GROUP BY
	|	RoomInventory.Ref,
	|	RoomInventory.Room,
	|	RoomInventory.CheckInDate,
	|	RoomInventory.CheckOutDate,
	|	RoomInventory.Ref.PointInTime,
	|	RoomInventory.SortCode
	|
	|ORDER BY
	|	RoomInventory.SortCode,
	|	RoomInventory.CheckInDate,
	|	RoomInventory.Ref.PointInTime";
	vQry.SetParameter("qRoom", pPeriod.Room);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pPeriod.Room));
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qRoomType", pPeriod.RoomType);
	vQry.SetParameter("qBeds", Enums.AccomodationTypes.Beds);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qPeriodFrom", pPeriod.CheckInDate);
	vQry.SetParameter("qPeriodTo", pPeriod.CheckOutDate);
	vQry.SetParameter("qCurDoc", pPeriod.Ref);
	vQryTab = vQry.Execute().Unload();
	
	// Resume only one document of each search type (1 - 8)
	i = 0;
	vPrevTypeProcessed = 0;
	While i < vQryTab.Count() Do
		vQryRow = vQryTab.Get(i);
		If vPrevTypeProcessed <> vQryRow.SortCode Then
			vPrevTypeProcessed = vQryRow.SortCode;
		Else
			vQryTab.Delete(i);
			Continue;
		EndIf;
		i = i + 1;
	EndDo;
	vQryTab.GroupBy("Ref, Room, CheckInDate, CheckOutDate, PointInTime, Reposted, Cleared", );
	
	// Check if current room is in connect room
	If ValueIsFilled(pPeriod.Room) Then
		vConnectRoom = cmGetConnectRoom(pPeriod.Room);
		If ValueIsFilled(vConnectRoom) Then
			vConnectQry = New Query;
			vConnectQry.Text = 
			"SELECT
			|	ConnectedRooms.Room AS Room
			|INTO RoomsInConnect
			|FROM
			|	Catalog.Rooms.ConnectedRooms AS ConnectedRooms
			|WHERE
			|	ConnectedRooms.Ref = &qConnectRoom
			|	AND ConnectedRooms.Room <> &qRoom
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	BaseSetOfRecords.Recorder AS Ref,
			|	BaseSetOfRecords.Room AS Room,
			|	BaseSetOfRecords.PeriodFrom AS CheckInDate,
			|	BaseSetOfRecords.PeriodTo AS CheckOutDate,
			|	BaseSetOfRecords.Recorder.PointInTime AS PointInTime,
			|	BaseSetOfRecords.Recorder.SortCode AS SortCode,
			|	FALSE AS Reposted,
			|	FALSE AS Cleared
			|FROM
			|	AccumulationRegister.RoomInventory AS BaseSetOfRecords
			|		INNER JOIN RoomsInConnect AS RoomsInConnect
			|		ON (RoomsInConnect.Room = BaseSetOfRecords.Room)
			|WHERE
			|	BaseSetOfRecords.PeriodFrom < &qPeriodTo
			|	AND BaseSetOfRecords.PeriodTo > &qPeriodFrom
			|	AND BaseSetOfRecords.RoomType.IsVirtual = FALSE
			|	AND BaseSetOfRecords.RecordType = &qExpense
			|	AND BaseSetOfRecords.Recorder.NumberOfBeds <> 0
			|	AND BaseSetOfRecords.Recorder <> &qCurDoc
			|	AND (BaseSetOfRecords.Recorder REFS Document.Accommodation
			|			OR BaseSetOfRecords.Recorder REFS Document.Reservation)
			|
			|ORDER BY
			|	BaseSetOfRecords.Room.SortCode,
			|	BaseSetOfRecords.PeriodFrom,
			|	BaseSetOfRecords.Recorder.PointInTime";
			vConnectQry.SetParameter("qConnectRoom", vConnectRoom);
			vConnectQry.SetParameter("qRoom", ValueIsFilled(pPeriod.Room));
			vConnectQry.SetParameter("qExpense", AccumulationRecordType.Expense);
			vConnectQry.SetParameter("qPeriodFrom", pPeriod.CheckInDate);
			vConnectQry.SetParameter("qPeriodTo", pPeriod.CheckOutDate);
			vConnectQry.SetParameter("qCurDoc", pPeriod.Ref);
			vConnectQryTab = vConnectQry.Execute().Unload();
			For Each vConnectQryTabRow In vConnectQryTab Do
				vQryTabRow = vQryTab.Add();
				FillPropertyValues(vQryTabRow, vConnectQryTabRow); 
			EndDo;
			vQryTab.GroupBy("Ref, Room, CheckInDate, CheckOutDate, PointInTime, Reposted, Cleared", );
		EndIf;
	EndIf;
	
	// Add column to store document objects
	vQryTab.Columns.Add("DocObj");
	
	// Return resulting table
	Return vQryTab;
EndFunction // cmGetTableOfIntersectedDocs

// -----------------------------------------------------------------------------
// Description: Returns string with description of documents (accommodations and reservations) 
//              in the given room for the period specified
// Parameters: Hotel, Room type, Room, Document reference, Start of period to check, End of period to check
// Return value: String with description
// -----------------------------------------------------------------------------
Function cmGetDescriptionOfRoomDocuments(pHotel, pRoomType, pRoom, pDoc, pPeriodFrom, pPeriodTo) Export
	vStr = "";
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryByRoom.Recorder,
	|	RoomInventoryByRoom.GuestGroup,
	|	RoomInventoryByRoom.Guest AS Guest,
	|	CASE
	|		WHEN (NOT(RoomInventoryByRoom.AccommodationStatus IS NULL 
	|					OR RoomInventoryByRoom.AccommodationStatus = &qEmptyAccommodationStatus))
	|			THEN RoomInventoryByRoom.AccommodationStatus
	|		WHEN (NOT(RoomInventoryByRoom.ReservationStatus IS NULL 
	|					OR RoomInventoryByRoom.ReservationStatus = &qEmptyReservationStatus))
	|			THEN RoomInventoryByRoom.ReservationStatus
	|		WHEN (NOT(RoomInventoryByRoom.RoomBlockType IS NULL 
	|					OR RoomInventoryByRoom.RoomBlockType = &qEmptyRoomBlockType))
	|			THEN RoomInventoryByRoom.RoomBlockType
	|		ELSE NULL
	|	END AS Status,
	|	MIN(RoomInventoryByRoom.CheckInDate) AS CheckInDate,
	|	MAX(RoomInventoryByRoom.CheckOutDate) AS CheckOutDate
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryByRoom
	|WHERE
	|	RoomInventoryByRoom.Hotel = &qHotel
	|	AND RoomInventoryByRoom.Room = &qRoom
	|	AND RoomInventoryByRoom.RoomType = &qRoomType
	|	AND RoomInventoryByRoom.RecordType = &qExpense
	|	AND RoomInventoryByRoom.CheckInDate < &qPeriodTo
	|	AND (RoomInventoryByRoom.CheckOutDate > &qPeriodFrom
	|			OR RoomInventoryByRoom.Recorder.DateTo = &qEmptyDate)
	|	AND RoomInventoryByRoom.Recorder <> &qDoc
	|
	|GROUP BY
	|	RoomInventoryByRoom.Recorder,
	|	RoomInventoryByRoom.GuestGroup,
	|	RoomInventoryByRoom.Guest,
	|	CASE
	|		WHEN (NOT(RoomInventoryByRoom.AccommodationStatus IS NULL 
	|					OR RoomInventoryByRoom.AccommodationStatus = &qEmptyAccommodationStatus))
	|			THEN RoomInventoryByRoom.AccommodationStatus
	|		WHEN (NOT(RoomInventoryByRoom.ReservationStatus IS NULL 
	|					OR RoomInventoryByRoom.ReservationStatus = &qEmptyReservationStatus))
	|			THEN RoomInventoryByRoom.ReservationStatus
	|		WHEN (NOT(RoomInventoryByRoom.RoomBlockType IS NULL 
	|					OR RoomInventoryByRoom.RoomBlockType = &qEmptyRoomBlockType))
	|			THEN RoomInventoryByRoom.RoomBlockType
	|		ELSE NULL
	|	END
	|
	|ORDER BY
	|	CheckInDate,
	|	CheckOutDate";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qDoc", pDoc);
	vQry.SetParameter("qEmptyAccommodationStatus", Catalogs.AccommodationStatuses.EmptyRef());
	vQry.SetParameter("qEmptyReservationStatus", Catalogs.ReservationStatuses.EmptyRef());
	vQry.SetParameter("qEmptyRoomBlockType", Catalogs.RoomBlockTypes.EmptyRef());
	vQryTab = vQry.Execute().Unload();
	For Each vRow In vQryTab Do
		vStr = vStr + TrimAll(vRow.Status) + ", " + Format(vRow.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vRow.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + TrimAll(vRow.GuestGroup) + " - " + TrimAll(vRow.Guest) + Chars.LF;
	EndDo;
	Return vStr;		
EndFunction // cmGetDescriptionOfRoomDocuments

// -----------------------------------------------------------------------------
// Description: Checks if it is possible to check-in to the given room
// Parameters: Hotel, Room type, Room, Document reference, Whether document is 
//             posted or not, Whether to check room availability only or also
//             check number of vacant rooms for the room type given,
//             Number of persons in the document being checked,
//             Number of rooms in the document being checked,
//             Number of beds in the document being checked,
//             Number of additional beds in the document being checked,
//             Number of beds per room, Number of persons per room, 
//             Start of period to check, End of period to check,
//             Message text in russian language to be returned in case of error,
//             Message text in english language to be returned in case of error,
//             Whether current user has permission to check-in to the occupied rooms or not,
//             Whether current user has permission to do overbooking or not,
//             Whether current user has permission to ignore maximum number of 
//             guests per room limitation or not
// Return value: True if rooms are available, False if not
// -----------------------------------------------------------------------------
Function cmCheckRoomAvailability(pHotel, pRoomQuota, pRoomType, pRoom, pDoc, pIsPosted, pCheckRoomTypeBalances, 
                                 pNumberOfPersons, pNumberOfRooms, pNumberOfBeds, pNumberOfAdditionalBeds, 
                                 pNumberOfBedsPerRoom, pNumberOfPersonsPerRoom, 
                                 pDateFrom, pDateTo, rMsgTextRu, rMsgTextEn, rMsgTextDe, 
								 pHavePermissionToUseOccupiedRooms = Undefined, 
								 pHavePermissionToDoOverbooking = Undefined,
								 pHavePermissionToIgnoreNumberOfGuestsPerRoomLimits = Undefined) Export
	// Check period
	If pDateFrom >= pDateTo Then
		Return True;
	EndIf;
								 
	// Initialize working variables
	vOK = True;
	vRoomsVacant = 0;
	vBedsVacant = 0;
	vGuestsVacant = 0;
	
	// Retrieve all necessary permissions
	vHavePermissionToUseOccupiedRooms = cmCheckUserPermissions("HavePermissionToUseOccupiedRooms");
	vHavePermissionToDoOverbooking = cmCheckUserPermissions("HavePermissionToDoOverbooking");
	vHavePermissionToIgnoreNumberOfGuestsPerRoomLimits = cmCheckUserPermissions("HavePermissionToIgnoreNumberOfGuestsPerRoomLimits");
	
	// Take permissions from parameters
	If pHavePermissionToUseOccupiedRooms <> Undefined Then
		vHavePermissionToUseOccupiedRooms = pHavePermissionToUseOccupiedRooms;
	EndIf;
	If pHavePermissionToDoOverbooking <> Undefined Then
		vHavePermissionToDoOverbooking = pHavePermissionToDoOverbooking;
	EndIf;
	If pHavePermissionToIgnoreNumberOfGuestsPerRoomLimits <> Undefined Then
		vHavePermissionToIgnoreNumberOfGuestsPerRoomLimits = pHavePermissionToIgnoreNumberOfGuestsPerRoomLimits;
	EndIf;
	
	// Build and run query to check room inventory
	If ValueIsFilled(pRoom) And Not pRoom.IsVirtual Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomInventoryBalance.Hotel AS Hotel,
		|	RoomInventoryBalance.RoomType AS RoomType,
		|	RoomInventoryBalance.Room AS Room,
		|	MIN(RoomInventoryBalance.CounterClosingBalance) AS CounterClosingBalance,
		|	MIN(RoomInventoryBalance.TotalBedsClosingBalance) AS TotalBeds,
		|	MIN(RoomInventoryBalance.TotalRoomsClosingBalance) AS TotalRooms,
		|	MIN(RoomInventoryBalance.RoomsVacantClosingBalance) AS RoomsVacant,
		|	MIN(RoomInventoryBalance.BedsVacantClosingBalance) AS BedsVacant,
		|	MIN(RoomInventoryBalance.GuestsVacantClosingBalance) AS GuestsVacant
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
		|			&qDateFrom,
		|			&qDateTo,
		|			Second,
		|			RegisterRecordsAndPeriodBoundaries,
		|			Hotel = &qHotel
		|				AND RoomType = &qRoomType
		|				AND Room = &qRoom) AS RoomInventoryBalance
		|
		|GROUP BY
		|	RoomInventoryBalance.Hotel,
		|	RoomInventoryBalance.RoomType,
		|	RoomInventoryBalance.Room";
		
		vQry.SetParameter("qHotel", pHotel);
		vQry.SetParameter("qRoomType", pRoomType);
		vQry.SetParameter("qRoom", pRoom);
		vQry.SetParameter("qDateFrom", pDateFrom);
		vQry.SetParameter("qDateTo", New Boundary(pDateTo, BoundaryType.Excluding));
		
		vQryTab = vQry.Execute().Unload();
		For Each vQryTabRow In vQryTab Do
			vRoomsVacant = vQryTabRow.RoomsVacant;
			vBedsVacant = vQryTabRow.BedsVacant;
			vGuestsVacant = vQryTabRow.GuestsVacant;
			Break;
		EndDo;

		// Check room inventory
		vNotEnoughRooms = 0;
		vNotEnoughBeds = 0;
		vNotEnoughGuests = 0;
		If pIsPosted Then
			vNotEnoughRooms = -vRoomsVacant;
			vNotEnoughBeds = -vBedsVacant;
			vNotEnoughGuests = -vGuestsVacant;
		Else
			vNotEnoughRooms = pNumberOfRooms - vRoomsVacant;
			vNotEnoughBeds = pNumberOfBeds - vBedsVacant;
			vNotEnoughGuests = pNumberOfPersons - vGuestsVacant;
		EndIf;
		
		vMsgTextRu = "Номер " + TrimAll(pRoom) + " занят!";
		vMsgTextEn = "Room " + TrimAll(pRoom) + " is occupied!";
		vMsgTextDe = "Room " + TrimAll(pRoom) + " is occupied!";
		
		If pNumberOfRooms > 0 Then
			If vNotEnoughRooms > 0 Then
				vDesc = Chars.LF + Chars.LF + cmGetDescriptionOfRoomDocuments(pHotel, pRoomType, pRoom, pDoc, pDateFrom, pDateTo);
				vMsgTextRu = vMsgTextRu + vDesc;
				vMsgTextEn = vMsgTextEn + vDesc;
				vMsgTextDe = vMsgTextDe + vDesc;
				vMessage = NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
				If Not vHavePermissionToUseOccupiedRooms And ValueIsFilled(pRoom) Then
					If ValueIsFilled(pDoc) Then
						WriteLogEvent(NStr("en='RoomInventory.RoomIsOccupied';ru='НомернойФонд.НомерЗанят';de='RoomInventory.RoomIsOccupied'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
					Else
						WriteLogEvent(NStr("en='RoomInventory.RoomIsOccupied';ru='НомернойФонд.НомерЗанят';de='RoomInventory.RoomIsOccupied'"), EventLogLevel.Warning, , , vMessage);
					EndIf;
					vOK = False;
					rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
					rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
					rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
				Else
					If ValueIsFilled(pDoc) Then
						WriteLogEvent(NStr("en='RoomInventory.RoomIsOccupied';ru='НомернойФонд.НомерЗанят';de='RoomInventory.RoomIsOccupied'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
						If cmShowNotEnoughRoomsMessages() Then
							tcCommonFunctionOnClientServer.UserMessage(cmGetMessageHeader(pDoc) + vMessage);
							rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
							rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
							rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
						EndIf;
					Else
						WriteLogEvent(NStr("en='RoomInventory.RoomIsOccupied';ru='НомернойФонд.НомерЗанят';de='RoomInventory.RoomIsOccupied'"), EventLogLevel.Warning, , , vMessage);
					EndIf;
				EndIf;
			ElsIf vNotEnoughBeds > 0 Then
				vMsgTextRu = vMsgTextRu + Chars.LF + "В номере не хватает " + vNotEnoughBeds + " свободных мест!";
				vMsgTextEn = vMsgTextEn + Chars.LF + vNotEnoughBeds + " vacant beds are not available!";
				vMsgTextDe = vMsgTextDe + Chars.LF + vNotEnoughBeds + " vacant beds are not available!";
				vDesc = Chars.LF + Chars.LF + cmGetDescriptionOfRoomDocuments(pHotel, pRoomType, pRoom, pDoc, pDateFrom, pDateTo);
				vMsgTextRu = vMsgTextRu + vDesc;
				vMsgTextEn = vMsgTextEn + vDesc;
				vMsgTextDe = vMsgTextDe + vDesc;
				vMessage = NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
				If Not vHavePermissionToUseOccupiedRooms And ValueIsFilled(pRoom) Then
					If ValueIsFilled(pDoc) Then
						WriteLogEvent(NStr("en='RoomInventory.RoomIsOccupied';ru='НомернойФонд.НомерЗанят';de='RoomInventory.RoomIsOccupied'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
					Else
						WriteLogEvent(NStr("en='RoomInventory.RoomIsOccupied';ru='НомернойФонд.НомерЗанят';de='RoomInventory.RoomIsOccupied'"), EventLogLevel.Warning, , , vMessage);
					EndIf;
					vOK = False;
					rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
					rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
					rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
				Else
					If ValueIsFilled(pDoc) Then
						WriteLogEvent(NStr("en='RoomInventory.RoomIsOccupied';ru='НомернойФонд.НомерЗанят';de='RoomInventory.RoomIsOccupied'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
						If cmShowNotEnoughRoomsMessages() Then
							tcCommonFunctionOnClientServer.UserMessage(cmGetMessageHeader(pDoc) + vMessage);
							rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
							rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
							rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
						EndIf;
					Else
						WriteLogEvent(NStr("en='RoomInventory.RoomIsOccupied';ru='НомернойФонд.НомерЗанят';de='RoomInventory.RoomIsOccupied'"), EventLogLevel.Warning, , , vMessage);
					EndIf;
				EndIf;
			EndIf;
		ElsIf pNumberOfBeds > 0 Then
			If vNotEnoughBeds > 0 Then
				vMsgTextRu = vMsgTextRu + Chars.LF + "В номере не хватает " + vNotEnoughBeds + " свободных мест!";
				vMsgTextEn = vMsgTextEn + Chars.LF + vNotEnoughBeds + " vacant beds are not available!";
				vMsgTextDe = vMsgTextDe + Chars.LF + vNotEnoughBeds + " vacant beds are not available!";
				vDesc = Chars.LF + Chars.LF + cmGetDescriptionOfRoomDocuments(pHotel, pRoomType, pRoom, pDoc, pDateFrom, pDateTo);
				vMsgTextRu = vMsgTextRu + vDesc;
				vMsgTextEn = vMsgTextEn + vDesc;
				vMsgTextDe = vMsgTextDe + vDesc;
				vMessage = NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
				If Not vHavePermissionToUseOccupiedRooms And ValueIsFilled(pRoom) Then
					If ValueIsFilled(pDoc) Then
						WriteLogEvent(NStr("en='RoomInventory.RoomIsOccupied';ru='НомернойФонд.НомерЗанят';de='RoomInventory.RoomIsOccupied'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
					Else
						WriteLogEvent(NStr("en='RoomInventory.RoomIsOccupied';ru='НомернойФонд.НомерЗанят';de='RoomInventory.RoomIsOccupied'"), EventLogLevel.Warning, , , vMessage);
					EndIf;
					vOK = False;
					rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
					rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
					rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
				Else
					If ValueIsFilled(pDoc) Then
						WriteLogEvent(NStr("en='RoomInventory.RoomIsOccupied';ru='НомернойФонд.НомерЗанят';de='RoomInventory.RoomIsOccupied'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
						If cmShowNotEnoughRoomsMessages() Then
							tcCommonFunctionOnClientServer.UserMessage(cmGetMessageHeader(pDoc) + vMessage);
							rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
							rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
							rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
						EndIf;
					Else
						WriteLogEvent(NStr("en='RoomInventory.RoomIsOccupied';ru='НомернойФонд.НомерЗанят';de='RoomInventory.RoomIsOccupied'"), EventLogLevel.Warning, , , vMessage);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	
		// Check number of guests per room
		If vNotEnoughGuests > 0 Then
			vMsgTextRu = "В номере " + TrimAll(pRoom);
			vMsgTextEn = "Room " + TrimAll(pRoom) + " is occupied!";
			vMsgTextDe = "Room " + TrimAll(pRoom) + " is occupied!";
			vMsgTextRu = vMsgTextRu + " невозможно разместить " + vNotEnoughGuests + " гостей!" + Chars.LF + 
			             "Максимальное число гостей в номере " + pNumberOfPersonsPerRoom + Chars.LF + 
			             "Уже размещено в номере " + (pNumberOfPersonsPerRoom - pNumberOfPersons + vNotEnoughGuests) + Chars.LF + 
			             "Необходимо разместить " + pNumberOfPersons + " гостей";
			vMsgTextEn = vMsgTextEn + " Unable to check-in " + vNotEnoughGuests + " guests!" + Chars.LF +  
			             "Maximum number of guests per room is " + pNumberOfPersonsPerRoom + Chars.LF + 
			             "Guests already in room " + (pNumberOfPersonsPerRoom - pNumberOfPersons + vNotEnoughGuests) + Chars.LF + 
			             "It is necessary to check in " + pNumberOfPersons + " guests!";
			vMsgTextDe = vMsgTextDe + " Unable to check-in " + vNotEnoughGuests + " guests!" + Chars.LF +  
			             "Maximum number of guests per room is " + pNumberOfPersonsPerRoom + Chars.LF + 
			             "Guests already in room " + (pNumberOfPersonsPerRoom - pNumberOfPersons + vNotEnoughGuests) + Chars.LF + 
			             "It is necessary to check in " + pNumberOfPersons + " guests!";
			vDesc = Chars.LF + Chars.LF + cmGetDescriptionOfRoomDocuments(pHotel, pRoomType, pRoom, pDoc, pDateFrom, pDateTo);
			vMsgTextRu = vMsgTextRu + vDesc;
			vMsgTextEn = vMsgTextEn + vDesc;
			vMsgTextDe = vMsgTextDe + vDesc;
			vMessage = NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
			If Not vHavePermissionToIgnoreNumberOfGuestsPerRoomLimits Then
				vOK = False;
				rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
				rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
				rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
			Else
				If ValueIsFilled(pDoc) Then
					WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
					If cmShowNotEnoughRoomsMessages() Then
						tcCommonFunctionOnClientServer.UserMessage(cmGetMessageHeader(pDoc) + vMessage);
						rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
						rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
						rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
					EndIf;
				Else
					WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, , , vMessage);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Check room type balances
	If Not ValueIsFilled(pRoomQuota) And ValueIsFilled(pRoomType) And Not pRoomType.IsVirtual Then
		vQry = New Query;
		vQry.Text = 
		"SELECT
		|	RoomInventoryBalance.Hotel AS Hotel,
		|	RoomInventoryBalance.RoomType AS RoomType,
		|	MIN(RoomInventoryBalance.CounterClosingBalance) AS CounterClosingBalance,
		|	MIN(RoomInventoryBalance.TotalBedsClosingBalance) AS TotalBeds,
		|	MIN(RoomInventoryBalance.TotalRoomsClosingBalance) AS TotalRooms,
		|	MIN(RoomInventoryBalance.RoomsVacantClosingBalance) AS RoomsVacant,
		|	MIN(RoomInventoryBalance.BedsVacantClosingBalance) AS BedsVacant,
		|	MIN(RoomInventoryBalance.GuestsVacantClosingBalance) AS GuestsVacant
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
		|			&qDateFrom,
		|			&qDateTo,
		|			Second,
		|			RegisterRecordsAndPeriodBoundaries,
		|			Hotel = &qHotel
		|				AND RoomType = &qRoomType) AS RoomInventoryBalance
		|
		|GROUP BY
		|	RoomInventoryBalance.Hotel,
		|	RoomInventoryBalance.RoomType";
		
		vQry.SetParameter("qHotel", pHotel);
		vQry.SetParameter("qRoomType", pRoomType);
		vQry.SetParameter("qDateFrom", pDateFrom);
		vQry.SetParameter("qDateTo", New Boundary(pDateTo, BoundaryType.Excluding));
		
		vQryTab = vQry.Execute().Unload();
		For Each vQryTabRow In vQryTab Do
			vRoomsVacant = vQryTabRow.RoomsVacant;
			vBedsVacant = vQryTabRow.BedsVacant;
			vGuestsVacant = vQryTabRow.GuestsVacant;
			Break;
		EndDo;

		// Check room type inventory
		vNotEnoughRooms = 0;
		vNotEnoughBeds = 0;
		If pIsPosted Then
			vNotEnoughRooms = -vRoomsVacant;
			vNotEnoughBeds = -vBedsVacant;
		Else
			vNotEnoughRooms = pNumberOfRooms - vRoomsVacant;
			vNotEnoughBeds = pNumberOfBeds - vBedsVacant;
		EndIf;
		
		vMsgTextRu = "";
		vMsgTextEn = "";
		vMsgTextDe = "";
		If ValueIsFilled(pRoomType) Then
			vMsgTextRu = "По типу номера " + TrimAll(pRoomType) + " на периоде с " + Format(pDateFrom, "DF='dd.MM.yyyy HH:mm'") + " по "+ Format(pDateTo, "DF='dd.MM.yyyy HH:mm'");
			vMsgTextEn = "For room type " + TrimAll(pRoomType) + " for period from " + Format(pDateFrom, "DF='dd.MM.yyyy HH:mm'") + " to "+ Format(pDateTo, "DF='dd.MM.yyyy HH:mm'");
			vMsgTextDe = "Für Zimmertyp " + TrimAll(pRoomType) + "für den Zeitraum von " + Format(pDateFrom, "DF='dd.MM.yyyy HH:mm'") + " bis "+ Format(pDateTo, "DF='dd.MM.yyyy HH:mm'");
		Else
			vMsgTextRu = "Всего";
			vMsgTextEn = "Total";
			vMsgTextDe = "Total";
		EndIf;
		
		If pNumberOfRooms > 0 Then
			If vNotEnoughRooms > 0 Then
				vMsgTextRu = vMsgTextRu + " не хватает " + vNotEnoughRooms + " свободных номеров!";
				vMsgTextEn = vMsgTextEn + " " + vNotEnoughRooms + " vacant rooms are not available!";
				vMsgTextDe = vMsgTextDe + " " + vNotEnoughRooms + " freie Zimmer sind nicht verfügbar!";
				vMessage = NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
				If Not vHavePermissionToDoOverbooking And pCheckRoomTypeBalances Then
					If ValueIsFilled(pDoc) Then
						WriteLogEvent(NStr("en='RoomInventory.NoVacantRooms';ru='НомернойФонд.НетСвободныхНомеров';de='RoomInventory.NoVacantRooms'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
					Else
						WriteLogEvent(NStr("en='RoomInventory.NoVacantRooms';ru='НомернойФонд.НетСвободныхНомеров';de='RoomInventory.NoVacantRooms'"), EventLogLevel.Warning, , , vMessage);
					EndIf;
					vOK = False;
					rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
					rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
					rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
				Else
					If ValueIsFilled(pDoc) Then
						WriteLogEvent(NStr("en='RoomInventory.NoVacantRooms';ru='НомернойФонд.НетСвободныхНомеров';de='RoomInventory.NoVacantRooms'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
						If cmShowNotEnoughRoomsMessages() Then
							tcCommonFunctionOnClientServer.UserMessage(cmGetMessageHeader(pDoc) + vMessage);
							rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
							rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
							rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
						EndIf;
					Else
						WriteLogEvent(NStr("en='RoomInventory.NoVacantRooms';ru='НомернойФонд.НетСвободныхНомеров';de='RoomInventory.NoVacantRooms'"), EventLogLevel.Warning, , , vMessage);
					EndIf;
				EndIf;
			ElsIf vNotEnoughBeds > 0 Then
				vMsgTextRu = vMsgTextRu + " не хватает " + vNotEnoughBeds + " свободных мест!";
				vMsgTextEn = vMsgTextEn + " " + vNotEnoughBeds + " vacant beds are not available!";
				vMsgTextDe = vMsgTextDe + " " + vNotEnoughBeds + " vacant beds are not available!";
				vMessage = NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
				If Not vHavePermissionToDoOverbooking And pCheckRoomTypeBalances Then
					If ValueIsFilled(pDoc) Then
						WriteLogEvent(NStr("en='RoomInventory.NoVacantRooms';ru='НомернойФонд.НетСвободныхНомеров';de='RoomInventory.NoVacantRooms'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
					Else
						WriteLogEvent(NStr("en='RoomInventory.NoVacantRooms';ru='НомернойФонд.НетСвободныхНомеров';de='RoomInventory.NoVacantRooms'"), EventLogLevel.Warning, , , vMessage);
					EndIf;						
					vOK = False;
					rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
					rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
					rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
				Else
					If ValueIsFilled(pDoc) Then
						WriteLogEvent(NStr("en='RoomInventory.NoVacantRooms';ru='НомернойФонд.НетСвободныхНомеров';de='RoomInventory.NoVacantRooms'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
						If cmShowNotEnoughRoomsMessages() Then
							tcCommonFunctionOnClientServer.UserMessage(cmGetMessageHeader(pDoc) + vMessage);
							rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
							rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
							rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
						EndIf;
					Else
						WriteLogEvent(NStr("en='RoomInventory.NoVacantRooms';ru='НомернойФонд.НетСвободныхНомеров';de='RoomInventory.NoVacantRooms'"), EventLogLevel.Warning, , , vMessage);
					EndIf;						
				EndIf;
			EndIf;
		ElsIf pNumberOfBeds > 0 Then
			If vNotEnoughBeds > 0 Then
				vMsgTextRu = vMsgTextRu + " не хватает " + vNotEnoughBeds + " свободных мест!";
				vMsgTextEn = vMsgTextEn + " " + vNotEnoughBeds + " vacant beds are not available!";
				vMsgTextDe = vMsgTextDe + " " + vNotEnoughBeds + " vacant beds are not available!";
				vMessage = NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
				If Not vHavePermissionToDoOverbooking And pCheckRoomTypeBalances Then
					If ValueIsFilled(pDoc) Then
						WriteLogEvent(NStr("en='RoomInventory.NoVacantRooms';ru='НомернойФонд.НетСвободныхНомеров';de='RoomInventory.NoVacantRooms'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
					Else
						WriteLogEvent(NStr("en='RoomInventory.NoVacantRooms';ru='НомернойФонд.НетСвободныхНомеров';de='RoomInventory.NoVacantRooms'"), EventLogLevel.Warning, , , vMessage);
					EndIf;
					vOK = False;
					rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
					rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
					rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
				Else
					If ValueIsFilled(pDoc) Then
						WriteLogEvent(NStr("en='RoomInventory.NoVacantRooms';ru='НомернойФонд.НетСвободныхНомеров';de='RoomInventory.NoVacantRooms'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
						If cmShowNotEnoughRoomsMessages() Then
							tcCommonFunctionOnClientServer.UserMessage(cmGetMessageHeader(pDoc) + vMessage);
							rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
							rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
							rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
						EndIf;
					Else
						WriteLogEvent(NStr("en='RoomInventory.NoVacantRooms';ru='НомернойФонд.НетСвободныхНомеров';de='RoomInventory.NoVacantRooms'"), EventLogLevel.Warning, , , vMessage);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// OK
	Return vOK;
EndFunction // cmCheckRoomAvailability

// -----------------------------------------------------------------------------
// Description: Returns value table with active room blocks
// Parameters: Hotel, Room type, Room, Start of period, End of period
//             Rooms value list
// Return value: Value table with room block documents found
// -----------------------------------------------------------------------------
Function cmGetRoomBlocks(pHotel, pRoomType, pRoom, pDateFrom, pDateTo, pRooms = Undefined) Export
	// Build and run query to check room blocks
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomInventory.Recorder AS SetRoomBlock,
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.RoomType AS RoomType, 
	|	RoomInventory.Room AS Room, 
	|	RoomInventory.RoomBlockType AS RoomBlockType, 
	|	RoomInventory.RoomBlockType.SortCode AS RoomBlockTypeSortCode, 
	|	RoomInventory.CheckInDate AS DateFrom, 
	|	RoomInventory.CheckOutDate AS DateTo, 
	|	RoomInventory.Remarks AS Remarks 
	|
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|
	|WHERE
	|	RoomInventory.IsBlocking = TRUE AND " +
		?(ValueIsFilled(pHotel), "RoomInventory.Hotel IN HIERARCHY(&qHotel) AND ", "") +
		?(ValueIsFilled(pRoomType), "RoomInventory.RoomType IN HIERARCHY(&qRoomType) AND ", "") +
		?(ValueIsFilled(pRoom), "RoomInventory.Room IN HIERARCHY(&qRoom) AND ", "") + 
		?(pRooms <> Undefined, "RoomInventory.Room IN (&qRooms) AND ", "") + "
	|	RoomInventory.RecordType = &qExpense AND " + 
		?(ValueIsFilled(pDateTo), "RoomInventory.CheckInDate < &qDateTo AND ", "") + "
	|	(RoomInventory.CheckOutDate > &qDateFrom OR RoomInventory.CheckOutDate = &qEmptyDate)
	|
	|ORDER BY
	|	RoomBlockTypeSortCode";
	
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qRooms", pRooms);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qDateTo", pDateTo);
	vQry.SetParameter("qEmptyDate", Date(1, 1, 1));
	
	vQryTab = vQry.Execute().Unload();
	
	// Return
	Return vQryTab;
EndFunction // cmGetRoomBlocks

// -----------------------------------------------------------------------------
// Description: Returns value table with accommodations intersecting by period with
//              input parameter period and for the given hotel, room type,
//              room or rooms list
// Parameters: Hotel, Room type, Room, Start of period, End of period,
//             Rooms value list
// Return value: Value table with accommodations found
// -----------------------------------------------------------------------------
Function cmGetRoomGuests(pHotel, pRoomType, pRoom, pDateFrom, pDateTo, pRooms = Undefined) Export
	// Build and run query to get room guests
	vQry = New Query;
	vQry.Text = 
	"SELECT DISTINCT
	|	RoomInventory.Recorder AS Accommodation,
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.RoomType AS RoomType, 
	|	RoomInventory.AccommodationType AS AccommodationType, 
	|	RoomInventory.AccommodationType.Type AS AccommodationTypeType, 
	|	RoomInventory.AccommodationType.SortCode AS AccommodationTypeSortCode, 
	|	RoomInventory.Room AS Room, 
	|	RoomInventory.Guest AS Guest, 
	|	RoomInventory.Customer AS Customer, 
	|	RoomInventory.GuestGroup.Description AS GuestGroupDescription, 
	|	RoomInventory.PeriodFrom AS DateFrom, 
	|	RoomInventory.PeriodTo AS DateTo, 
	|	RoomInventory.NumberOfPersons AS NumberOfPersons,
	|	RoomInventory.RoomRate AS RoomRate
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.IsAccommodation = TRUE AND " +
		?(ValueIsFilled(pHotel), "RoomInventory.Hotel IN HIERARCHY(&qHotel) AND ", "") +
		?(ValueIsFilled(pRoomType), "RoomInventory.RoomType IN HIERARCHY(&qRoomType) AND ", "") +
		?(ValueIsFilled(pRoom), "RoomInventory.Room IN HIERARCHY(&qRoom) AND ", "") + 
		?(pRooms <> Undefined, "RoomInventory.Room IN (&qRooms) AND ", "") + "
	|	RoomInventory.RecordType = &qExpense AND 
	|	RoomInventory.PeriodFrom < &qDateTo AND 
	|	RoomInventory.PeriodTo > &qDateFrom
	|ORDER BY
	|	RoomInventory.Room.SortCode,
	|	RoomInventory.PeriodFrom,
	|	RoomInventory.AccommodationType.SortCode";
	
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qRooms", pRooms);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qDateTo", pDateTo);
	
	vQryTab = vQry.Execute().Unload();
	
	// Return
	Return vQryTab;
EndFunction // cmGetRoomGuests

// -----------------------------------------------------------------------------
// Description: Returns value table with in-house accommodations with check-in 
//              date after specified one
// Parameters: Hotel, Room type, Room, Period
// Return value: Value table with accommodations found
// -----------------------------------------------------------------------------
Function cmGetRoomNextGuests(pHotel, pRoomType, pRoom, pDate, pAccRef) Export
	// Build and run query to get room guests
	vQry = New Query;
	vQry.Text = 
	"SELECT DISTINCT
	|	RoomInventory.Recorder AS Accommodation,
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.Room AS Room,
	|	RoomInventory.Guest AS Guest,
	|	RoomInventory.Customer AS Customer,
	|	RoomInventory.GuestGroup.Description AS GuestGroupDescription,
	|	RoomInventory.CheckInDate AS DateFrom,
	|	RoomInventory.CheckOutDate AS DateTo,
	|	RoomInventory.NumberOfPersons AS NumberOfPersons
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.IsAccommodation
	|	AND RoomInventory.IsInHouse
	|	AND RoomInventory.Hotel = &qHotel
	|	AND RoomInventory.Room = &qRoom
	|	AND RoomInventory.RecordType = &qExpense
	|	AND RoomInventory.Recorder <> &qAccRef
	|	AND RoomInventory.CheckInDate > &qDate
	|
	|ORDER BY
	|	RoomInventory.Room.SortCode,
	|	RoomInventory.CheckInDate,
	|	RoomInventory.Guest.Description";
	
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qAccRef", pAccRef);
	
	vQryTab = vQry.Execute().Unload();
	
	// Return
	Return vQryTab;
EndFunction // cmGetRoomNextGuests

// -----------------------------------------------------------------------------
// Description: Returns room presentation string consisting of number of in-house
//              guests for the giving period per guest sex and citizenship
// Parameters: Hotel, Room, Date & time, Returns number of occupied beds in the room, 
//             Returns number of in-house persons
// Return value: Room presentation string
// -----------------------------------------------------------------------------
Function cmGetRoomPresentation(pHotel, pRoom, Val pPeriod = Undefined, rOccupiedBeds = 0, rOccupiedPersons = 0, pNumber = "") Export
	If pPeriod = Undefined Then
		pPeriod = CurrentSessionDate();
	EndIf;
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventory.Guest.Sex AS Sex,
	|	RoomInventory.Guest.Citizenship.ISOCode AS Country,
	|	SUM(RoomInventory.NumberOfPersons) AS NumberOfPersons,
	|	SUM(RoomInventory.NumberOfBeds) AS NumberOfBeds
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Hotel = &qHotel
	|	AND RoomInventory.Room = &qRoom
	|	AND RoomInventory.RecordType = &qExpense
	|	AND RoomInventory.Period = RoomInventory.PeriodFrom
	|	AND RoomInventory.PeriodFrom <= &qPeriod
	|	AND RoomInventory.PeriodTo > &qPeriod
	|	AND (RoomInventory.IsAccommodation
	|			OR RoomInventory.IsReservation)
	|	AND RoomInventory.Recorder.Number <> &qNumber
	|
	|GROUP BY
	|	RoomInventory.Guest.Sex,
	|	RoomInventory.Guest.Citizenship.ISOCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qNumber", pNumber);
	vQryTab = vQry.Execute().Unload();
	
	rOccupiedBeds = 0;
	rOccupiedPersons = 0;
	vRoomStr = TrimAll(pRoom);
	
	If vQryTab.Count() > 0 Then
		rOccupiedBeds = vQryTab.Total("NumberOfBeds");
		rOccupiedPersons = vQryTab.Total("NumberOfPersons");
		vRoomStr = vRoomStr + " -";
		
		For Each vRow In vQryTab Do
			vRoomStr = vRoomStr + " " + Format(vRow.NumberOfPersons, "ND=6; NFD=0") + ?(ValueIsFilled(vRow.Country), "(" + vRow.Country + ")", "") + ?(ValueIsFilled(vRow.Sex), Left(String(vRow.Sex), 1), "?");
		EndDo;
	EndIf;
	
	Return vRoomStr;
EndFunction // cmGetRoomPresentation

// -----------------------------------------------------------------------------
// Description: Returns hotel by external system hotel code
// Parameters: Hotel code, External system code 
// Return value: Hotel reference
// -----------------------------------------------------------------------------
Function cmGetHotelByCode(pHotel, pExternalSystemCode = "") Export
	vHotel = Catalogs.Hotels.EmptyRef();
	If pHotel = Undefined Then
		pHotel = "";
	EndIf;
	If Not IsBlankString(pHotel) Then
		// Try to find hotel in the mapping information register
		If Not IsBlankString(pExternalSystemCode) Then
			vHotel = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pExternalSystemCode, "Hotels", pHotel);
		EndIf;
		// Find hotel by code
		If Not ValueIsFilled(vHotel) Then
			vHotel = Catalogs.Hotels.FindByCode(pHotel);
			If Not ValueIsFilled(vHotel) Then
				vHotel = Catalogs.Hotels.FindByDescription(pHotel, True);
			EndIf;
		EndIf;
	EndIf;
	// Take hotel from the system parameters
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	Return vHotel;
EndFunction // cmGetHotelByCode

// -----------------------------------------------------------------------------
// Description: Returns room by room description and hotel
// Parameters: Room description, Hotel
// Return value: Room reference
// -----------------------------------------------------------------------------
Function cmGetRoomByCode(pRoomCode, Val pHotel = "", pExtSystemCode = "") Export
	// Find hotel by code
	vHotel = cmGetHotelByCode(pHotel, pExtSystemCode);
	// Find room by code
	vRoom = Catalogs.Rooms.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Rooms.Ref
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	Rooms.Description = &qRoomCode
	|	AND (NOT Rooms.DeletionMark)
	|	AND (NOT Rooms.IsFolder)
	|	AND Rooms.Owner = &qHotel";
	vQry.SetParameter("qRoomCode", pRoomCode);
	vQry.SetParameter("qHotel", vHotel);
	vRooms = vQry.Execute().Unload();
	If vRooms.Count() > 0 Then
		vRoom = vRooms.Get(0).Ref;
	Else
		vRoom = cmGetObjectRefByExternalSystemCode(vHotel, pExtSystemCode, "Rooms", TrimR(pRoomCode));
		If Not ValueIsFilled(vRoom) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Rooms.Ref
			|FROM
			|	Catalog.Rooms AS Rooms
			|WHERE
			|	Rooms.Description = &qRoomCode
			|	AND (NOT Rooms.DeletionMark)
			|	AND (NOT Rooms.IsFolder)";
			vQry.SetParameter("qRoomCode", pRoomCode);
			vRooms = vQry.Execute().Unload();
			If vRooms.Count() > 0 Then
				vRoom = vRooms.Get(0).Ref;
			EndIf;
		EndIf;
	EndIf;
	Return vRoom;
EndFunction // cmGetRoomByCode

// -----------------------------------------------------------------------------
// Description: Sets catalog list control owner filter to the current hotel
// Parameters: Form
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSetDefaultOwnerHotel(pForm) Export
	vCurHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(vCurHotel) Then
		vFlt = pForm.Controls.CatalogList.Value.Filter.Owner;
		vFlt.ComparisonType = ComparisonType.Equal;
		vFlt.Value = vCurHotel;
		vFlt.Use = True;
	EndIf;
EndProcedure // cmSetDefaultOwnerHotel

// -----------------------------------------------------------------------------
// Description: Returns value table with all hotels
// Parameters: None
// Return value: Value table with hotels
// -----------------------------------------------------------------------------
Function cmGetAllHotels() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	Hotels.Ref AS Hotel
	|FROM
	|	Catalog.Hotels AS Hotels
	|WHERE
	|	Hotels.DeletionMark = FALSE AND 
	|	Hotels.IsFolder = FALSE
	|ORDER BY Hotels.SortCode";
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllHotels

// -----------------------------------------------------------------------------
// Description: Returns value table with all companies
// Parameters: None
// Return value: Value table with companies
// -----------------------------------------------------------------------------
Function cmGetAllCompanies() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Companies.Ref AS Company
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.DeletionMark = FALSE
	|	AND Companies.IsFolder = FALSE
	|ORDER BY
	|	Companies.SortCode";
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllCompanies

// -----------------------------------------------------------------------------
// Description: Returns number of companies
// Parameters: None
// Return value: Number
// -----------------------------------------------------------------------------
Function cmGetCompaniesCount() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	COUNT(*) AS Count
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.DeletionMark = FALSE
	|	AND Companies.IsFolder = FALSE";
	vList = vQry.Execute().Unload();
	Return vList.Get(0).Count;
EndFunction // cmGetCompaniesCount

// -----------------------------------------------------------------------------
// Description: Returns value table with all countries
// Parameters: None
// Return value: Value table with countries
// -----------------------------------------------------------------------------
Function cmGetAllCountries() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	Countries.Ref AS Country
	|FROM
	|	Catalog.Countries AS Countries
	|WHERE
	|	Countries.DeletionMark = FALSE AND 
	|	Countries.IsFolder = FALSE
	|ORDER BY Countries.Description";
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllCountries

// -----------------------------------------------------------------------------
// Description: Returns value table with all tags
// Parameters: None
// Return value: Value table with countries
// -----------------------------------------------------------------------------
Function cmGetAllTagsList() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Tags.Ref AS Ref,
	|	Tags.Description AS Description
	|FROM
	|	Catalog.Tags AS Tags
	|WHERE
	|	Tags.DeletionMark = FALSE
	|
	|ORDER BY
	|	Tags.Description";
	vList = vQry.Execute().Unload();
	vTagsList = New ValueList();
	For Each vListRow In vList Do
		vTagsList.Add(vListRow.Ref,vListRow.Description);	
	EndDo;	
	Return vTagsList;
EndFunction // cmGetAllTags

// -----------------------------------------------------------------------------
// Description: Returns value table with all room types
// Parameters: Hotel, Room types folder to return items from
// Return value: Value table with room types
// -----------------------------------------------------------------------------
Function cmGetAllRoomTypes(pHotel, pRoomTypeFolder = Undefined, pRoomClass = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	RoomTypes.Ref AS RoomType,
	|	RoomTypes.RoomClass AS RoomClass,
	|	RoomTypes.IsVirtual AS IsVirtual
	|FROM
	|	Catalog.RoomTypes AS RoomTypes
	|WHERE
	|	(RoomTypes.Owner = &qHotel AND &qHotel <> VALUE(Catalog.Hotels.EmptyRef) OR &qHotel = VALUE(Catalog.Hotels.EmptyRef)) AND
	|	RoomTypes.IsFolder = FALSE AND " +
		?(ValueIsFilled(pRoomTypeFolder), "RoomTypes.Ref IN HIERARCHY(&qRoomTypeFolder) AND ", "") + 
		?(ValueIsFilled(pRoomClass), "RoomTypes.RoomClass = &qRoomClass AND ", "") + "
	|	NOT RoomTypes.DeletionMark
	|ORDER BY RoomTypes.Owner.SortCode, RoomTypes.Owner.Code, RoomTypes.SortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomTypeFolder", pRoomTypeFolder);
	vQry.SetParameter("qRoomClass", pRoomClass);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllRoomTypes

// -----------------------------------------------------------------------------
// Description: Returns value table with all calendar day types
// Parameters: Calendar day types folder to return items from
// Return value: Value table with calendar day types
// -----------------------------------------------------------------------------
Function cmGetAllCalendarDayTypes(pCalendarDayTypeFolder = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	CalendarDayTypes.Ref AS CalendarDayType
	|FROM
	|	Catalog.CalendarDayTypes AS CalendarDayTypes
	|WHERE 
	|	(CalendarDayTypes.Hotel = &qHotel OR CalendarDayTypes.Hotel = &qEmptyHotel) AND
	|	CalendarDayTypes.IsFolder = FALSE AND " +
		?(ValueIsFilled(pCalendarDayTypeFolder), "CalendarDayTypes.Ref IN HIERARCHY(&qCalendarDayTypeFolder) AND ", "") + "
	|	CalendarDayTypes.DeletionMark = FALSE
	|ORDER BY CalendarDayTypes.SortCode";
	vQry.SetParameter("qCalendarDayTypeFolder", pCalendarDayTypeFolder);
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllCalendarDayTypes

// -----------------------------------------------------------------------------
// Description: Returns value table with all price tags
// Parameters: Price tags folder to return items from
// Return value: Value table with price tags
// -----------------------------------------------------------------------------
Function cmGetAllPriceTags(pPriceTagFolder = Undefined, pPriceTagType = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	PriceTags.Ref AS PriceTag,
	|	PriceTags.Code AS Code,
	|	PriceTags.Description AS Description,
	|	PriceTags.Discount AS Discount,
	|	PriceTags.SortCode AS SortCode
	|FROM
	|	Catalog.PriceTags AS PriceTags
	|WHERE 
	|	(PriceTags.Hotel = &qHotel OR PriceTags.Hotel = &qEmptyHotel) AND
	|	PriceTags.IsFolder = FALSE AND " +
		?(ValueIsFilled(pPriceTagFolder), "PriceTags.Ref IN HIERARCHY(&qPriceTagFolder) AND ", "") + 
		?(ValueIsFilled(pPriceTagType), "(PriceTags.Type = &qPriceTagType OR PriceTags.Type = UNDEFINED) AND ", "") + "
	|	PriceTags.DeletionMark = FALSE
	|ORDER BY PriceTags.SortCode";
	vQry.SetParameter("qPriceTagFolder", pPriceTagFolder);
	vQry.SetParameter("qPriceTagType", pPriceTagType);
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllPriceTags

// -----------------------------------------------------------------------------
// Description: Returns value table with all schedule day types
// Parameters: Schedule day types folder to return items from
// Return value: Value table with schedule day types
// -----------------------------------------------------------------------------
Function cmGetAllScheduleDayTypes(pScheduleDayTypeFolder = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	ScheduleDayTypes.Ref AS ScheduleDayType
	|FROM
	|	Catalog.ScheduleDayTypes AS ScheduleDayTypes
	|WHERE 
	|	ScheduleDayTypes.IsFolder = FALSE AND " +
		?(ValueIsFilled(pScheduleDayTypeFolder), "ScheduleDayTypes.Ref IN HIERARCHY(&qScheduleDayTypeFolder) AND ", "") + "
	|	ScheduleDayTypes.DeletionMark = FALSE
	|ORDER BY ScheduleDayTypes.SortCode";
	vQry.SetParameter("qScheduleDayTypeFolder", pScheduleDayTypeFolder);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllScheduleDayTypes

// -----------------------------------------------------------------------------
// Description: Returns value table with all room rates
// Parameters: Hotel, Room rates folder to return items from
// Return value: Value table with room rates
// -----------------------------------------------------------------------------
Function cmGetAllRoomRates(pHotel, pRoomRateFolder = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	RoomRates.Ref AS RoomRate,
	|	RoomRates.RoomRateType AS RoomRateType
	|FROM
	|	Catalog.RoomRates AS RoomRates
	|WHERE
	|	(RoomRates.Hotel = &qHotel OR RoomRates.Hotel = &qEmptyHotel OR &qHotel = &qEmptyHotel) AND
	|	RoomRates.IsFolder = FALSE AND " +
		?(ValueIsFilled(pRoomRateFolder), "RoomRates.Ref IN HIERARCHY(&qRoomRateFolder) AND ", "") + "
	|	RoomRates.DeletionMark = FALSE
	|ORDER BY RoomRates.SortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qRoomRateFolder", pRoomRateFolder);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllRoomRates

// -----------------------------------------------------------------------------
// Description: Returns value table with all payment sections
// Parameters: None
// Return value: Value table with payment sections
// -----------------------------------------------------------------------------
Function cmGetAllPaymentSections(pHotel = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	PaymentSections.Ref AS PaymentSection
	|FROM
	|	Catalog.PaymentSections AS PaymentSections
	|WHERE
	|	(PaymentSections.Hotel = &qHotel
	|			OR PaymentSections.Hotel = &qEmptyHotel)
	|	AND PaymentSections.DeletionMark = FALSE
	|
	|ORDER BY
	|	PaymentSections.Code";
	If pHotel = Undefined Then
		vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	Else
		vQry.SetParameter("qHotel", pHotel);
	EndIf;		
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllPaymentSections

// -----------------------------------------------------------------------------
// Description: Returns value table with all services
// Parameters: Services folder to return items from
// Return value: Value table with services
// -----------------------------------------------------------------------------
Function cmGetAllServices(pServicesFolder = Undefined, pDoNotCheckHotel = False) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	Services.Ref AS Service
	|FROM
	|	Catalog.Services AS Services
	|WHERE
	|	Services.IsFolder = FALSE AND " +
		?(ValueIsFilled(pServicesFolder), "Services.Ref IN HIERARCHY(&qServicesFolder) AND ", "") + "
	|	Services.DeletionMark = FALSE AND 
	|	(Services.Hotel = &qHotel
	|			OR Services.Hotel = &qEmptyHotel
	|			OR &qDoNotCheckHotel)
	|ORDER BY 
	|	Services.SortCode,
	|	Services.Description";
	vQry.SetParameter("qServicesFolder", pServicesFolder);
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qDoNotCheckHotel", pDoNotCheckHotel);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllServices

// -----------------------------------------------------------------------------
// Description: Returns value table with all services
// Parameters: Services folder to return items from
// Return value: Value table with services
// -----------------------------------------------------------------------------
Function cmGetAllServicePackages(pFolder = Undefined, pHotel = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	ServicePackages.Ref AS ServicePackage
	|FROM
	|	Catalog.ServicePackages AS ServicePackages
	|WHERE
	|	ServicePackages.IsFolder = FALSE AND " +
		?(ValueIsFilled(pFolder), "ServicePackages.Ref IN HIERARCHY(&qFolder) AND ", "") + 
		?(ValueIsFilled(pHotel), "(ServicePackages.Hotel IN HIERARCHY(&qHotel) OR ServicePackages.Hotel = VALUE(Catalog.Hotels.EmptyRef)) AND ", "") + "
	|	ServicePackages.DeletionMark = FALSE
	|ORDER BY 
	|	ServicePackages.SortCode,
	|	ServicePackages.Description";
	vQry.SetParameter("qFolder", pFolder);
	vQry.SetParameter("qHotel", ?(pHotel = Undefined, SessionParameters.CurrentHotel, pHotel));
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllServicePackages

// -----------------------------------------------------------------------------
// Description: Returns value list with all room properties valid for the given hotel
// Parameters: Room properties folder to return items from, Hotel
// Return value: Value table with room properties
// -----------------------------------------------------------------------------
Function cmGetAllRoomProperties(pRoomPropertiesFolder = Undefined, pHotel = Undefined, pShowInPropertiesList = Undefined) Export
	vList = New ValueList();
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomProperties.Ref AS RoomProperty,
	|	RoomProperties.Code AS Code,
	|	RoomProperties.Description AS Description
	|FROM
	|	Catalog.RoomProperties AS RoomProperties
	|WHERE
	|	NOT RoomProperties.DeletionMark
	|	AND NOT RoomProperties.IsFolder
	|	AND (RoomProperties.Ref IN HIERARCHY (&qRoomPropertiesFolder)
	|			OR &qRoomPropertiesFolderIsEmpty)
	|	AND (RoomProperties.Hotel = &qHotel
	|				AND &qHotel <> &qEmptyHotel
	|			OR RoomProperties.Hotel = &qEmptyHotel
	|			OR &qHotel = &qEmptyHotel)
	|	AND (&qFilterByShowInPropertiesList
	|				AND RoomProperties.ShowInPropertiesList = &qShowInPropertiesList
	|			OR NOT &qFilterByShowInPropertiesList)
	|
	|ORDER BY
	|	RoomProperties.SortCode,
	|	RoomProperties.Description";
	vQry.SetParameter("qRoomPropertiesFolder", pRoomPropertiesFolder);
	vQry.SetParameter("qRoomPropertiesFolderIsEmpty", Not ValueIsFilled(pRoomPropertiesFolder));
	vQry.SetParameter("qHotel", ?(pHotel = Undefined, Catalogs.Hotels.EmptyRef(), pHotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qFilterByShowInPropertiesList", ?(pShowInPropertiesList = Undefined, False, True));
	vQry.SetParameter("qShowInPropertiesList", pShowInPropertiesList);
	vQryResults = vQry.Execute().Unload();
	For Each vQryResultsRow In vQryResults Do
		vList.Add(vQryResultsRow.RoomProperty, TrimAll(vQryResultsRow.Code) + " - " + TrimAll(vQryResultsRow.Description));
	EndDo;
	Return vList;
EndFunction // cmGetAllRoomProperties

// -----------------------------------------------------------------------------
// Description: Returns query selection with room properties
// Parameters: Room
// -----------------------------------------------------------------------------
Function cmGetRoomPropertiesForRoom(pRoom) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomProperties.Room AS Room,
	|	RoomProperties.RoomProperty AS RoomProperty,
	|	RoomProperties.Remarks AS Remarks,
	|	RoomProperties.Author AS Author
	|FROM
	|	InformationRegister.RoomProperties AS RoomProperties
	|WHERE
	|	RoomProperties.Room = &qRoom
	|
	|ORDER BY
	|	RoomProperties.RoomProperty.SortCode,
	|	RoomProperties.RoomProperty.Description";
	vQry.SetParameter("qRoom", pRoom);
	Return vQry.Execute().Select();
EndFunction // cmGetRoomPropertiesForRoom

// -----------------------------------------------------------------------------
// Description: Returns value table with all accommodation templates
// Parameters: Hotel, Accommodation templates folder to return items from
// Return value: Value table with accommodation templates
// -----------------------------------------------------------------------------
Function cmGetAllAccommodationTemplates(pHotel, pAccTemplFolder = Undefined, pNoFolioSplit = False) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	AccommodationTemplates.Ref AS AccommodationTemplate
	|FROM
	|	Catalog.AccommodationTemplates AS AccommodationTemplates
	|WHERE
	|	(AccommodationTemplates.Hotel = &qHotel
	|			OR AccommodationTemplates.Hotel = &qEmptyHotel)
	|	AND AccommodationTemplates.DeletionMark = FALSE
	|	AND (NOT &qNoFolioSplit
	|			OR &qNoFolioSplit
	|				AND NOT AccommodationTemplates.IsForFolioSplit)
	|
	|ORDER BY
	|	AccommodationTemplates.Code";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qAccTemplFolder", pAccTemplFolder);
	vQry.SetParameter("qNoFolioSplit", pNoFolioSplit);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllAccommodationTemplates

// -----------------------------------------------------------------------------
// Description: Returns value table with all accommodation types
// Parameters: Accommodation types folder to return items from
// Return value: Value table with accommodation types
// -----------------------------------------------------------------------------
Function cmGetAllAccommodationTypes(pAccommodationTypeFolder = Undefined, pHotel = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	AccommodationTypes.Ref AS AccommodationType
	|FROM
	|	Catalog.AccommodationTypes AS AccommodationTypes
	|WHERE 
	|	AccommodationTypes.IsFolder = FALSE AND " +
		?(ValueIsFilled(pAccommodationTypeFolder), "AccommodationTypes.Ref IN HIERARCHY(&qAccommodationTypeFolder) AND ", "") + "
	|	AccommodationTypes.DeletionMark = FALSE
	|	AND (NOT &qHotelIsEmptyRef AND (AccommodationTypes.Hotel = &qHotel
	|			OR AccommodationTypes.Hotel = &qEmptyHotel) OR &qHotelIsEmptyRef)
	|ORDER BY AccommodationTypes.SortCode";
	vQry.SetParameter("qAccommodationTypeFolder", pAccommodationTypeFolder);
	vQry.SetParameter("qHotel", ?(pHotel = Undefined, SessionParameters.CurrentHotel, pHotel));
	vQry.SetParameter("qHotelIsEmptyRef", ?(pHotel = Catalogs.Hotels.EmptyRef(), True, False));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllAccommodationTypes

// -----------------------------------------------------------------------------
Function cmGetAllBusinessBlockCancellationReasons() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BusinessBlockCancellationReasons.Ref AS CancellationReason,
	|	BusinessBlockCancellationReasons.Code AS Code,
	|	BusinessBlockCancellationReasons.Description AS Description
	|FROM
	|	Catalog.BusinessBlockCancellationReasons AS BusinessBlockCancellationReasons
	|WHERE
	|	BusinessBlockCancellationReasons.DeletionMark = FALSE
	|
	|ORDER BY
	|	Code";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllBusinessBlockCancellationReasons

// -----------------------------------------------------------------------------
// Description: Returns value list with all main room guests accommodation types
// Parameters: Hotel 
// Return value: Value list with accommodation types
// -----------------------------------------------------------------------------
Function cmGetMainRoomGuestAccommodationTypes(pHotel) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	AccommodationTypes.Ref AS Ref
	|FROM
	|	Catalog.AccommodationTypes AS AccommodationTypes
	|WHERE
	|	AccommodationTypes.IsFolder = FALSE
	|	AND AccommodationTypes.DeletionMark = FALSE
	|	AND (AccommodationTypes.Type = &qRoom
	|			OR AccommodationTypes.Type = &qBeds)
	|	AND (AccommodationTypes.Hotel = &qHotel
	|			OR AccommodationTypes.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	AccommodationTypes.SortCode";
	vQry.SetParameter("qRoom", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qBeds", Enums.AccomodationTypes.Beds);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQryRes = vQry.Execute().Unload();
	vList = New ValueList();
	vList.LoadValues(vQryRes.UnloadColumn("Ref"));
	Return vList;
EndFunction // cmGetMainRoomGuestAccommodationTypes

// -----------------------------------------------------------------------------
// Description: Returns first reference to the "Together" accommodation type
// Parameters: None
// Return value: Accommodation type or empty ref
// -----------------------------------------------------------------------------
Function cmGetAccommodationTypeTogether(pHotel = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	AccommodationTypes.Ref AS AccommodationType
	|FROM
	|	Catalog.AccommodationTypes AS AccommodationTypes
	|WHERE
	|	NOT AccommodationTypes.IsFolder
	|	AND NOT AccommodationTypes.DeletionMark
	|	AND AccommodationTypes.Type = &qTogether
	|	AND (AccommodationTypes.Hotel = &qHotel
	|			OR AccommodationTypes.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	AccommodationTypes.SortCode";
	vQry.SetParameter("qTogether", Enums.AccomodationTypes.Together);
	vQry.SetParameter("qHotel", ?(ValueIsFilled(pHotel), pHotel, SessionParameters.CurrentHotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vList = vQry.Execute().Unload();
	If vList.Count() > 0 Then
		Return vList.Get(0).AccommodationType;
	Else
		Return Catalogs.AccommodationTypes.EmptyRef();
	EndIf;
EndFunction // cmGetAccommodationTypeTogether

// -----------------------------------------------------------------------------
// Description: Returns first reference to the "Room" accommodation type
// Parameters: None
// Return value: Accommodation type or empty ref
// -----------------------------------------------------------------------------
Function cmGetAccommodationTypeRoom(pHotel = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	AccommodationTypes.Ref AS AccommodationType
	|FROM
	|	Catalog.AccommodationTypes AS AccommodationTypes
	|WHERE
	|	NOT AccommodationTypes.IsFolder
	|	AND NOT AccommodationTypes.DeletionMark
	|	AND AccommodationTypes.Type = &qRoom
	|	AND (AccommodationTypes.Hotel = &qHotel
	|			OR AccommodationTypes.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	AccommodationTypes.SortCode";
	vQry.SetParameter("qRoom", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qHotel", ?(ValueIsFilled(pHotel), pHotel, SessionParameters.CurrentHotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vList = vQry.Execute().Unload();
	If vList.Count() > 0 Then
		Return vList.Get(0).AccommodationType;
	Else
		Return Catalogs.AccommodationTypes.EmptyRef();
	EndIf;
EndFunction // cmGetAccommodationTypeRoom

// -----------------------------------------------------------------------------
// Description: Returns first reference to the "Bed" accommodation type
// Parameters: None
// Return value: Accommodation type or empty ref
// -----------------------------------------------------------------------------
Function cmGetAccommodationTypeBed(pHotel = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	AccommodationTypes.Ref AS AccommodationType
	|FROM
	|	Catalog.AccommodationTypes AS AccommodationTypes
	|WHERE
	|	NOT AccommodationTypes.IsFolder
	|	AND NOT AccommodationTypes.DeletionMark
	|	AND AccommodationTypes.Type = &qBed
	|	AND (AccommodationTypes.Hotel = &qHotel
	|			OR AccommodationTypes.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	AccommodationTypes.SortCode";
	vQry.SetParameter("qBed", Enums.AccomodationTypes.Beds);
	vQry.SetParameter("qHotel", ?(ValueIsFilled(pHotel), pHotel, SessionParameters.CurrentHotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vList = vQry.Execute().Unload();
	If vList.Count() > 0 Then
		Return vList.Get(0).AccommodationType;
	Else
		Return Catalogs.AccommodationTypes.EmptyRef();
	EndIf;
EndFunction // cmGetAccommodationTypeBed

// -----------------------------------------------------------------------------
// Description: Calculates reservation and accommodation resources like 
//              number of beds, number of rooms, number of additional beds, 
//              number or persons, number of beds per room, number of persons per room
// Parameters: Date & time, Room type, accommodation type, Room, Number of rooms, 
//             Whether to recalculate number of persons resource in the document or not
// Return value: None, Input parameters are calculated and returned
// -----------------------------------------------------------------------------
Procedure cmCalculateResources(pDate, pRoomType, pAccommodationType, pRoom = Undefined, 
                               pRoomQuantity, rNumberOfRooms, rNumberOfBeds, 
                               rNumberOfAdditionalBeds, rNumberOfPersons, 
                               rNumberOfBedsPerRoom, rNumberOfPersonsPerRoom,
							   pRecalculateNumberOfPersonsInReservation = False) Export
	vIsVirtual = False;
	rNumberOfBedsPerRoom = 0;
	If ValueIsFilled(pRoom) Then
		vRoomObj = pRoom.GetObject();
		vRoomAttr = vRoomObj.pmGetRoomAttributes(pDate);
		For Each vRoomAttrRow In vRoomAttr Do
			rNumberOfBedsPerRoom = vRoomAttrRow.NumberOfBedsPerRoom;
			rNumberOfPersonsPerRoom = vRoomAttrRow.NumberOfPersonsPerRoom;
			vIsVirtual = vRoomAttrRow.IsVirtual;
			Break;
		EndDo;
	ElsIf ValueIsFilled(pRoomType) Then
		rNumberOfBedsPerRoom = pRoomType.NumberOfBedsPerRoom;
		rNumberOfPersonsPerRoom = pRoomType.NumberOfPersonsPerRoom;
		vIsVirtual = pRoomType.IsVirtual;
	EndIf;
	If ValueIsFilled(pAccommodationType) And Not vIsVirtual Then
		If pAccommodationType.Type = Enums.AccomodationTypes.Room Then
			rNumberOfRooms = pRoomQuantity * pAccommodationType.NumberOfRooms;
			rNumberOfBeds = ?(pAccommodationType.NumberOfRooms = 0, 0, pRoomQuantity * rNumberOfBedsPerRoom);
			rNumberOfAdditionalBeds = pRoomQuantity * pAccommodationType.NumberOfAdditionalBeds;
			vNumberOfPersons = pRoomQuantity * pAccommodationType.NumberOfPersons;
			If Not pRecalculateNumberOfPersonsInReservation Or pAccommodationType.NumberOfPersons4Reservation = 0 Then
				If rNumberOfPersons = 0 Then
					rNumberOfPersons = vNumberOfPersons;
				EndIf;
			Else
				rNumberOfPersons = pRoomQuantity * pAccommodationType.NumberOfPersons4Reservation;
			EndIf;
		ElsIf pAccommodationType.Type = Enums.AccomodationTypes.Beds Then
			rNumberOfRooms = 0;
			rNumberOfBeds = pRoomQuantity * pAccommodationType.NumberOfBeds;
			rNumberOfAdditionalBeds = pRoomQuantity * pAccommodationType.NumberOfAdditionalBeds;
			vNumberOfPersons = pRoomQuantity * pAccommodationType.NumberOfPersons;
			If Not pRecalculateNumberOfPersonsInReservation Or pAccommodationType.NumberOfPersons4Reservation = 0 Then
				If rNumberOfPersons = 0 Then
					rNumberOfPersons = vNumberOfPersons;
				EndIf;
			Else
				rNumberOfPersons = pRoomQuantity * pAccommodationType.NumberOfPersons4Reservation;
			EndIf;
		ElsIf pAccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Then
			rNumberOfRooms = 0;
			rNumberOfBeds = 0;
			rNumberOfAdditionalBeds = pRoomQuantity * pAccommodationType.NumberOfAdditionalBeds;
			vNumberOfPersons = pRoomQuantity * pAccommodationType.NumberOfPersons;
			If Not pRecalculateNumberOfPersonsInReservation Or pAccommodationType.NumberOfPersons4Reservation = 0 Then
				If rNumberOfPersons = 0 Then
					rNumberOfPersons = vNumberOfPersons;
				EndIf;
			Else
				rNumberOfPersons = pRoomQuantity * pAccommodationType.NumberOfPersons4Reservation;
			EndIf;
		ElsIf pAccommodationType.Type = Enums.AccomodationTypes.Together Then
			rNumberOfRooms = 0;
			rNumberOfBeds = 0;
			rNumberOfAdditionalBeds = pRoomQuantity * pAccommodationType.NumberOfAdditionalBeds;
			vNumberOfPersons = pRoomQuantity * pAccommodationType.NumberOfPersons;
			If Not pRecalculateNumberOfPersonsInReservation Or pAccommodationType.NumberOfPersons4Reservation = 0 Then
				If rNumberOfPersons = 0 Then
					rNumberOfPersons = vNumberOfPersons;
				EndIf;
			Else
				rNumberOfPersons = pRoomQuantity * pAccommodationType.NumberOfPersons4Reservation;
			EndIf;
		EndIf;
		If pAccommodationType.NumberOfPersons = 0 Then
			rNumberOfPersons = 0;
		EndIf;
	Else
		rNumberOfRooms = 0;
		rNumberOfBeds = 0;
		rNumberOfAdditionalBeds = 0;
	EndIf;
EndProcedure // cmCalculateResources

// -----------------------------------------------------------------------------
// Description: Returns value table with all day times 
// Parameters: None
// Return value: Value table with day times
// -----------------------------------------------------------------------------
Function cmGetDayTimes() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DayTimes.Ref AS DayTime,
	|	DayTimes.Code AS Code,
	|	DayTimes.Description,
	|	DayTimes.Time,
	|	DayTimes.Time4CheckOutDate,
	|	DayTimes.Presentation
	|FROM
	|	Catalog.DayTimes AS DayTimes
	|WHERE
	|	DayTimes.DeletionMark = FALSE
	|
	|ORDER BY
	|	Code";
	vDayTimes = vQry.Execute().Unload();
	REturn vDayTimes;
EndFunction // cmGetDayTimes

// -----------------------------------------------------------------------------
// Description: Returns value table with client accommodations and active 
//              reservations 
// Parameters: Client
// Return value: Value table with client accommodations/reservations data
// -----------------------------------------------------------------------------
Function cmLoadClientAccommodationHistory(pClient) Export
    vCheckUserRightsForHotel = False;
	vAllowedHotels = New ValueList();
	If Not IsInRole("RightsToChooseHotel") Then
	    vCheckUserRightsForHotel = True;
		vAllowedHotels.Add(SessionParameters.CurrentHotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentUser) Then
		vPermissionGroup = SessionParameters.CurrentUser.PermissionGroup;
		vNonReplAttrs = CachedSettings.сmGetEmployeeNonReplicatingAttributes(SessionParameters.CurrentUser);
		If vNonReplAttrs.Count() > 0 Then
			If ValueIsFilled(vNonReplAttrs.Get(0).PermissionGroup) Then
				vPermissionGroup = vNonReplAttrs.Get(0).PermissionGroup;
			EndIf;
		EndIf;
		If ValueIsFilled(vPermissionGroup) Then
			If vPermissionGroup.HotelAllowed.Count() > 0 Then
			    vCheckUserRightsForHotel = True;
				If ValueIsFilled(SessionParameters.CurrentHotel) Then
					If vAllowedHotels.FindByValue(SessionParameters.CurrentHotel) = Undefined Then
						vAllowedHotels.Add(SessionParameters.CurrentHotel);
					EndIf;
				EndIf;
				For Each vHotelAllowedRow In vPermissionGroup.HotelAllowed Do
					If ValueIsFilled(vHotelAllowedRow.Hotel) Then
						If vAllowedHotels.FindByValue(vHotelAllowedRow.Hotel) = Undefined Then
							vAllowedHotels.Add(vHotelAllowedRow.Hotel);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		Else
		    vCheckUserRightsForHotel = True;
		EndIf;
	Else
	    vCheckUserRightsForHotel = True;
	EndIf;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Accommodations.GuestGroup AS GuestGroup,
	|	Accommodations.GuestGroup.Description AS GuestGroupDescription,
	|	Accommodations.CheckInDate AS CheckInDate,
	|	Accommodations.CheckOutDate AS CheckOutDate,
	|	Accommodations.Room AS Room,
	|	Accommodations.RoomType AS RoomType,
	|	Accommodations.RoomRate AS RoomRate,
	|	Accommodations.AccommodationType AS AccommodationType,
	|	1 AS AccommodationCount,
	|	0 AS ReservationCount,
	|	Accommodations.Ref AS Document,
	|	Accommodations.Remarks AS Remarks
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Guest = &qClient
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.Posted
	|	AND (&qCheckUserRightsForHotel
	|				AND Accommodations.Hotel IN (&qAllowedHotels)
	|			OR NOT &qCheckUserRightsForHotel)
	|
	|UNION ALL
	|
	|SELECT
	|	Reservations.GuestGroup,
	|	Reservations.GuestGroup.Description,
	|	Reservations.CheckInDate,
	|	Reservations.CheckOutDate,
	|	Reservations.Room,
	|	Reservations.RoomType,
	|	Reservations.RoomRate,
	|	Reservations.AccommodationType,
	|	0,
	|	1,
	|	Reservations.Ref,
	|	Reservations.Remarks
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Guest = &qClient
	|	AND Reservations.ReservationStatus.ShowInClientsSearchForm = TRUE
	|	AND Reservations.Posted
	|	AND (&qCheckUserRightsForHotel
	|				AND Reservations.Hotel IN (&qAllowedHotels)
	|			OR NOT &qCheckUserRightsForHotel)
	|
	|ORDER BY
	|	CheckInDate";
	vQry.SetParameter("qClient", pClient);
	vQry.SetParameter("qCheckUserRightsForHotel", vCheckUserRightsForHotel);
	vQry.SetParameter("qAllowedHotels", vAllowedHotels);
	vQryTab = vQry.Execute().Unload();
	Return vQryTab;
EndFunction // cmLoadClientAccommodationHistory

// -----------------------------------------------------------------------------
// Description: Returns value table with all room properties
// Parameters: None
// Return value: Value table with room properties
// -----------------------------------------------------------------------------
Function cmGetAllProperties(pShowInListOnly = False) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomProperties.Ref AS RoomProperty,
	|	RoomProperties.Code AS Code,
	|	RoomProperties.Description AS Description,
	|	RoomProperties.SortCode AS SortCode
	|FROM
	|	Catalog.RoomProperties AS RoomProperties
	|WHERE
	|	RoomProperties.DeletionMark = FALSE
	|	AND RoomProperties.IsFolder = FALSE
	|	AND (RoomProperties.Hotel = &qHotel
	|			OR RoomProperties.Hotel = &qEmptyHotel)
	|	AND (NOT &qShowInListOnly
	|			OR &qShowInListOnly
	|				AND RoomProperties.ShowInPropertiesList)
	|
	|ORDER BY
	|	SortCode";
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qShowInListOnly", pShowInListOnly);
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllProperties

// -----------------------------------------------------------------------------
// Description: Returns value table with all reservation statuses
// Parameters: None
// Return value: Value table with reservation statuses
// -----------------------------------------------------------------------------
Function cmGetAllReservationStatuses(pSkipCheckIn = False) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReservationStatuses.Ref AS ReservationStatus,
	|	ReservationStatuses.Code AS Code,
	|	ReservationStatuses.Description AS Description,
	|	ReservationStatuses.SortCode AS SortCode,
	|	ReservationStatuses.IsActive AS IsActive
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	NOT ReservationStatuses.DeletionMark
	|	AND NOT ReservationStatuses.IsFolder
	|	AND (NOT ReservationStatuses.IsCheckIn
	|				AND &qSkipCheckIn
	|			OR NOT &qSkipCheckIn)
	|	AND (ReservationStatuses.Hotel = &qHotel
	|			OR ReservationStatuses.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	SortCode";
	vQry.SetParameter("qSkipCheckIn", pSkipCheckIn);
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vElements = vQry.Execute().Unload();
	vElements.Columns.Add("Color");
	For Each vRow In vElements Do
		vReservationStatus = vRow.ReservationStatus;
		vColor = vReservationStatus.Color.Get();
		If vColor <> Undefined And TypeOf(vColor) <> Type("Color") Then
			vColor = Undefined;
		EndIf;
		vRow.Color = vColor;
	EndDo;
	Return vElements;
EndFunction // cmGetAllReservationStatuses

// -----------------------------------------------------------------------------
Function cmGetDefaultGuaranteedReservationStatus(pHotel) Export
	If ValueIsFilled(pHotel) And ValueIsFilled(pHotel.GuaranteedReservationStatus) Then
		Return pHotel.GuaranteedReservationStatus;
	Else
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ReservationStatuses.Ref AS ReservationStatus
		|FROM
		|	Catalog.ReservationStatuses AS ReservationStatuses
		|WHERE
		|	NOT ReservationStatuses.DeletionMark
		|	AND NOT ReservationStatuses.IsFolder
		|	AND NOT ReservationStatuses.IsCheckIn
		|	AND ReservationStatuses.IsActive
		|	AND ReservationStatuses.IsGuaranteed
		|	AND (ReservationStatuses.Hotel = &qHotel
		|			OR ReservationStatuses.Hotel = &qEmptyHotel)
		|
		|ORDER BY
		|	ReservationStatuses.SortCode,
		|	ReservationStatuses.Code";
		vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
		vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
		vElements = vQry.Execute().Unload();
		For Each vRow In vElements Do
			Return vRow.ReservationStatus;
		EndDo;
	EndIf;
	Return Undefined;
EndFunction // cmGetDefaultGuaranteedReservationStatus

// -----------------------------------------------------------------------------
Function cmGetDefaultNotGuaranteedReservationStatus(pHotel) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReservationStatuses.Ref AS ReservationStatus
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	NOT ReservationStatuses.DeletionMark
	|	AND NOT ReservationStatuses.IsFolder
	|	AND NOT ReservationStatuses.IsCheckIn
	|	AND ReservationStatuses.IsActive
	|	AND NOT ReservationStatuses.IsGuaranteed
	|	AND (ReservationStatuses.Hotel = &qHotel
	|			OR ReservationStatuses.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	ReservationStatuses.SortCode,
	|	ReservationStatuses.Code";
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vElements = vQry.Execute().Unload();
	For Each vRow In vElements Do
		Return vRow.ReservationStatus;
	EndDo;
	Return Undefined;
EndFunction // cmGetDefaultNotGuaranteedReservationStatus

// -----------------------------------------------------------------------------
// Description: Returns value table with all accommodation statuses
// Parameters: None
// Return value: Value table with accommodation statuses
// -----------------------------------------------------------------------------
Function cmGetAllAccommodationStatuses() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccommodationStatuses.Ref AS AccommodationStatus,
	|	AccommodationStatuses.Code AS Code,
	|	AccommodationStatuses.Description AS Description,
	|	AccommodationStatuses.IsActive AS IsActive,
	|	AccommodationStatuses.SortCode AS SortCode
	|FROM
	|	Catalog.AccommodationStatuses AS AccommodationStatuses
	|WHERE
	|	AccommodationStatuses.DeletionMark = FALSE
	|	AND AccommodationStatuses.IsFolder = FALSE
	|
	|ORDER BY
	|	SortCode";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllAccommodationStatuses

// -----------------------------------------------------------------------------
// Description: Returns value list with all checked in accommodation statuses
// Parameters: None
// Return value: Value list with accommodation statuses
// -----------------------------------------------------------------------------
Function cmGetCheckedInAccommodationStatuses() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccommodationStatuses.Ref AS AccommodationStatus
	|FROM
	|	Catalog.AccommodationStatuses AS AccommodationStatuses
	|WHERE
	|	NOT AccommodationStatuses.DeletionMark
	|	AND NOT AccommodationStatuses.IsFolder
	|	AND AccommodationStatuses.IsActive
	|	AND AccommodationStatuses.IsInHouse
	|
	|ORDER BY
	|	AccommodationStatuses.SortCode";
	vElements = vQry.Execute().Unload();
	vElementsList = New ValueList();
	vElementsList.LoadValues(vElements.UnloadColumn("AccommodationStatus"));
	Return vElementsList;
EndFunction // cmGetCheckedInAccommodationStatuses

// -----------------------------------------------------------------------------
// Description: Returns value list with all checked out accommodation statuses
// Parameters: None
// Return value: Value list with accommodation statuses
// -----------------------------------------------------------------------------
Function cmGetCheckedOutAccommodationStatuses() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccommodationStatuses.Ref AS AccommodationStatus
	|FROM
	|	Catalog.AccommodationStatuses AS AccommodationStatuses
	|WHERE
	|	NOT AccommodationStatuses.DeletionMark
	|	AND NOT AccommodationStatuses.IsFolder
	|	AND AccommodationStatuses.IsActive
	|	AND AccommodationStatuses.IsCheckOut
	|	AND NOT AccommodationStatuses.IsInHouse
	|
	|ORDER BY
	|	AccommodationStatuses.SortCode";
	vElements = vQry.Execute().Unload();
	vElementsList = New ValueList();
	vElementsList.LoadValues(vElements.UnloadColumn("AccommodationStatus"));
	Return vElementsList;
EndFunction // cmGetCheckedOutAccommodationStatuses

// -----------------------------------------------------------------------------
// Description: Returns value table with all room statuses
// Parameters: None
// Return value: Value table with room statuses
// -----------------------------------------------------------------------------
Function cmGetAllRoomStatuses(pHotel = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomStatuses.Ref AS RoomStatus,
	|	RoomStatuses.Code AS Code,
	|	RoomStatuses.RoomStatusIcon AS RoomStatusIcon,
	|	RoomStatuses.Description AS Description,
	|	RoomStatuses.SortCode AS SortCode,
	|	RoomStatuses.ColorHexString AS ColorHexString
	|FROM
	|	Catalog.RoomStatuses AS RoomStatuses
	|WHERE
	|	RoomStatuses.DeletionMark = FALSE
	|	AND RoomStatuses.IsFolder = FALSE
	|	AND (RoomStatuses.Hotel = &qHotel
	|			OR RoomStatuses.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQry.SetParameter("qHotel", ?(ValueIsFilled(pHotel), pHotel, SessionParameters.CurrentHotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vElements = vQry.Execute().Unload();
	vElements.Columns.Add("Color");
	For Each vRow In vElements Do
		If Not IsBlankString(vRow.ColorHexString) Then
			vRow.Color = tcOnServer.HexToColor(vRow.ColorHexString);
		Else
			vRow.Color = Undefined;
		EndIf;
	EndDo;
	Return vElements;
EndFunction // cmGetAllRoomStatuses

// -----------------------------------------------------------------------------
// Description: Returns value table with all room interface types
// Parameters: None
// Return value: Value table with room interface types
// -----------------------------------------------------------------------------
Function cmGetAllRoomInterfaceTypes() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInterfaceTypes.Ref AS RoomStatus,
	|	RoomInterfaceTypes.Code AS Code,
	|	RoomInterfaceTypes.Description AS Description
	|FROM
	|	Catalog.RoomInterfaceTypes AS RoomInterfaceTypes
	|WHERE
	|	RoomInterfaceTypes.DeletionMark = FALSE
	|	AND (RoomInterfaceTypes.Hotel = &qHotel
	|			OR RoomInterfaceTypes.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	Code";
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllRoomInterfaceTypes

// -----------------------------------------------------------------------------
// Description: Returns value table with all relation types
// Parameters: None
// Return value: Value table with relation types
// -----------------------------------------------------------------------------
Function cmGetAllRelationTypes() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RelationTypes.Ref AS Ref,
	|	RelationTypes.Code AS Code,
	|	RelationTypes.Description AS Description
	|FROM
	|	Catalog.RelationTypes AS RelationTypes
	|WHERE
	|	RelationTypes.DeletionMark = FALSE
	|
	|ORDER BY
	|	Code";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllRelationTypes

// -----------------------------------------------------------------------------
// Description: Returns value table with room statuses allowed to the current user
// Parameters: None
// Return value: Value table with room statuses
// -----------------------------------------------------------------------------
Function cmGetAllowedRoomStatuses(pEmployee = Undefined, pCurrentRoomStatus = Undefined) Export
	// Initialize table
	vElements = New ValueTable();
	vElements.Columns.Add("RoomStatus", cmGetCatalogTypeDescription("RoomStatuses"));
	// Try to get current user permission group
	vEmployee = SessionParameters.CurrentUser;
	If ValueIsFilled(pEmployee) Then
		vEmployee = pEmployee;
	EndIf;
	If ValueIsFilled(vEmployee) Then
		vPermissionGroup = cmGetEmployeePermissionGroup(vEmployee);
		If ValueIsFilled(vPermissionGroup) Then
			For Each vRoomStatusRow In vPermissionGroup.RoomStatusesAllowed Do
				If Not vRoomStatusRow.RoomStatus.DeletionMark Then
					vElementsRow = vElements.Add();
					vElementsRow.RoomStatus = vRoomStatusRow.RoomStatus;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If ValueIsFilled(pCurrentRoomStatus) And pCurrentRoomStatus.TransitionsAllowed.Count() > 0 Then
		vTransitionsAllowed = pCurrentRoomStatus.TransitionsAllowed;
		i = 0;
		While i < vElements.Count() Do
			vElementsRow = vElements.Get(i);
			If vTransitionsAllowed.Find(vElementsRow.RoomStatus, "RoomStatus") = Undefined Then
				vElements.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	Return vElements;
EndFunction // cmGetAllowedRoomStatuses

// -----------------------------------------------------------------------------
// Description: Returns value table with door lock system authorizations 
//              allowed to the current user
// Parameters: None
// Return value: Value table with door lock system authorizations
// -----------------------------------------------------------------------------
Function cmGetAllowedDoorLockSystemAuthorizations() Export
	// Initialize table
	vElements = New ValueTable();
	vElements.Columns.Add("DoorLockSystemAuthorization", cmGetCatalogTypeDescription("DoorLockSystemAuthorizations"));
	// Try to get current user permission group
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
		If ValueIsFilled(vPermissionGroup) Then
			For Each vAuthRow In vPermissionGroup.DoorLockSystemAuthorizations Do
				vElementsRow = vElements.Add();
				vElementsRow.DoorLockSystemAuthorization = vAuthRow.DoorLockSystemAuthorization;
			EndDo;
		EndIf;
	EndIf;
	Return vElements;
EndFunction // cmGetAllowedDoorLockSystemAuthorizations

// -----------------------------------------------------------------------------
// Description: Returns value table with all client types
// Parameters: None
// Return value: Value table with client types
// -----------------------------------------------------------------------------
Function cmGetAllClientTypes(pHotel = Undefined, pClientTypeFolder = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientTypes.Ref AS ClientType,
	|	ClientTypes.Code AS Code,
	|	ClientTypes.Description AS Description,
	|	ClientTypes.SortCode AS SortCode,
	|	ClientTypes.ColorHexString AS ColorHexString
	|FROM
	|	Catalog.ClientTypes AS ClientTypes
	|WHERE
	|	ClientTypes.DeletionMark = FALSE
	|	AND ClientTypes.IsFolder = FALSE
	|	AND (NOT &qHotelIsEmptyRef
	|				AND (ClientTypes.Hotel IN HIERARCHY (&qHotel)
	|					OR ClientTypes.Hotel = &qEmptyHotel)
	|			OR &qHotelIsEmptyRef)
	|	AND (&qClientTypeFolderIsFilled
	|				AND ClientTypes.Ref IN HIERARCHY (&qClientTypeFolder)
	|			OR NOT &qClientTypeFolderIsFilled)
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQry.SetParameter("qHotel", ?(pHotel = Undefined, SessionParameters.CurrentHotel, pHotel));
	vQry.SetParameter("qHotelIsEmptyRef", ?(pHotel = Catalogs.Hotels.EmptyRef(), True, False));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qClientTypeFolder", pClientTypeFolder);
	vQry.SetParameter("qClientTypeFolderIsFilled", ValueIsFilled(pClientTypeFolder));
	vElements = vQry.Execute().Unload();
	// Check user permissions
	vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vPermissionGroup) Then
		If vPermissionGroup.ClientTypesAllowed.Count() > 0 Then
			i = 0;
			While i < vElements.Count() Do
				vRow = vElements.Get(i);
				If vPermissionGroup.ClientTypesAllowed.Find(vRow.ClientType, "ClientType") = Undefined Then
					vElements.Delete(i);
				Else
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;	
	vElements.Columns.Add("Color");
	For Each vRow In vElements Do
		If Not IsBlankString(vRow.ColorHexString) Then
			vRow.Color = tcOnServer.HexToColor(vRow.ColorHexString);
		Else
			vRow.Color = Undefined;
		EndIf;
	EndDo;
	Return vElements;
EndFunction // cmGetAllClientTypes

// -----------------------------------------------------------------------------
// Description: Returns value table with all trip purposes
// Parameters: None
// Return value: Value table with trip purposes
// -----------------------------------------------------------------------------
Function cmGetAllTripPurposes() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	TripPurposes.Ref AS TripPurpose,
	|	TripPurposes.Code AS Code,
	|	TripPurposes.Description AS Description,
	|	TripPurposes.SortCode AS SortCode
	|FROM
	|	Catalog.TripPurposes AS TripPurposes
	|WHERE
	|	NOT TripPurposes.DeletionMark
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllTripPurposes

// -----------------------------------------------------------------------------
// Description: Returns value table with all sources of business
// Parameters: None
// Return value: Value table with sources of business
// -----------------------------------------------------------------------------
Function cmGetAllSourcesOfBusiness() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SourcesOfBusiness.Ref AS SourceOfBusiness,
	|	SourcesOfBusiness.Code AS Code,
	|	SourcesOfBusiness.Description AS Description,
	|	SourcesOfBusiness.SortCode AS SortCode
	|FROM
	|	Catalog.SourcesOfBusiness AS SourcesOfBusiness
	|WHERE
	|	SourcesOfBusiness.DeletionMark = FALSE
	|	AND SourcesOfBusiness.IsFolder = FALSE
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllSourcesOfBusiness

// -----------------------------------------------------------------------------
// Description: Returns value table with all customer types
// Parameters: None
// Return value: Value table with customer types
// -----------------------------------------------------------------------------
Function cmGetAllCustomerTypes() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CustomerTypes.Ref AS CustomerType,
	|	CustomerTypes.Code AS Code,
	|	CustomerTypes.Description AS Description,
	|	CustomerTypes.SortCode AS SortCode
	|FROM
	|	Catalog.CustomerTypes AS CustomerTypes
	|WHERE
	|	CustomerTypes.DeletionMark = FALSE
	|	AND CustomerTypes.IsFolder = FALSE
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllCustomerTypes

// -----------------------------------------------------------------------------
// Description: Returns value table with all marketing codes
// Parameters: Hotel
// Return value: Value table with marketing codes
// -----------------------------------------------------------------------------
Function cmGetAllMarketingCodes(pHotel = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	MarketCodes.Ref AS MarketingCode,
	|	MarketCodes.Code AS Code,
	|	MarketCodes.Description AS Description,
	|	MarketCodes.SortCode AS SortCode
	|FROM
	|	Catalog.MarketingCodes AS MarketCodes
	|WHERE
	|	(MarketCodes.Hotel = &qHotel
	|			OR MarketCodes.Hotel = VALUE(Catalog.Hotels.EmptyRef)
	|			OR &qHotel = VALUE(Catalog.Hotels.EmptyRef)
	|			OR &qHotel = UNDEFINED)
	|	AND MarketCodes.DeletionMark = FALSE
	|	AND MarketCodes.IsFolder = FALSE
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQry.SetParameter("qHotel", pHotel);
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllSourcesOfBusiness

// -----------------------------------------------------------------------------
// Description: Returns value table with all sources of business
// Parameters: None
// Return value: Value table with sources of business
// -----------------------------------------------------------------------------
Function cmGetAllPriceChangeReasons() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PriceChangeReasons.Ref AS PriceChangeReason,
	|	PriceChangeReasons.Code AS Code,
	|	PriceChangeReasons.Description AS Description
	|FROM
	|	Catalog.ReasonsForPriceChange AS PriceChangeReasons
	|WHERE
	|	PriceChangeReasons.DeletionMark = FALSE
	|
	|ORDER BY
	|	Code";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllPriceChangeReasons

// -----------------------------------------------------------------------------
// Description: Returns value table with all guarantee types
// Parameters: None
// Return value: Value table with guarantee types
// -----------------------------------------------------------------------------
Function cmGetAllGuaranteeTypes() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GuaranteeTypes.Ref AS SourceOfBusiness,
	|	GuaranteeTypes.Code AS Code,
	|	GuaranteeTypes.Description AS Description
	|FROM
	|	Catalog.GuaranteeTypes AS GuaranteeTypes
	|WHERE
	|	NOT GuaranteeTypes.DeletionMark
	|ORDER BY
	|	Description";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllGuaranteeTypes

// -----------------------------------------------------------------------------
// Description: Returns count of guarantee types
// Parameters: None
// Return value: Number of active guarantee types
// -----------------------------------------------------------------------------
Function cmGetGuaranteeTypesCount() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	COUNT(*) AS Count
	|FROM
	|	Catalog.GuaranteeTypes AS GuaranteeTypes
	|WHERE
	|	NOT GuaranteeTypes.DeletionMark";
	vElements = vQry.Execute().Unload();
	If vElements.Count() > 0 Then
		Return vElements.Get(0).Count;
	Else
		Return 0;
	EndIf;
EndFunction // cmGetGuaranteeTypesCount

// -----------------------------------------------------------------------------
// Description: Returns value table with folios suitable for charging room service.
//              First folio returned is the newest one
// Parameters: Room, Service registration date, Client
// Return value: Value table with folios
// -----------------------------------------------------------------------------
Function cmGetFoliosToChargeRoomService(pRoom, pDate, pClient = Undefined, pSort = "DESC") Export
	// Select all active folios for the room specified
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Folio,
	|	Folio.IsMaster AS IsMaster,
	|	Folio.FolioCurrency AS FolioCurrency
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	(NOT Folio.IsClosed)
	|	AND (NOT Folio.DeletionMark)
	|	AND NOT Folio.ParentDoc REFS Document.Reservation
	|	AND Folio.Room = &qRoom
	|	AND Folio.DateTimeFrom <= &qDate " +
		?(ValueIsFilled(pClient), "AND Folio.Client = &qClient ", "") + "
	|ORDER BY
	|	IsMaster DESC,
	|	Folio.DateTimeFrom " + pSort + ",
	|	Folio.PointInTime " + pSort;
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qClient", pClient);
	vFolios = vQry.Execute().Unload();
	// Remove client filter and try again if nothing was found
	If ValueIsFilled(pClient) And vFolios.Count() = 0 Then
		vQry.Text = 
		"SELECT
		|	Folio.Ref AS Folio,
		|	Folio.IsMaster AS IsMaster,
		|	Folio.FolioCurrency AS FolioCurrency
		|FROM
		|	Document.Folio AS Folio
		|WHERE
		|	(NOT Folio.IsClosed)
		|	AND (NOT Folio.DeletionMark)
		|	AND NOT Folio.ParentDoc REFS Document.Reservation
		|	AND Folio.Room = &qRoom
		|	AND Folio.DateTimeFrom <= &qDate
		|
		|ORDER BY
		|	IsMaster DESC,
		|	Folio.DateTimeFrom " + pSort + ",
		|	Folio.PointInTime " + pSort;
		vQry.SetParameter("qRoom", pRoom);
		vQry.SetParameter("qDate", pDate);
		vFolios = vQry.Execute().Unload();
	EndIf;
	// Try again to search by accommodation period if nothing was found
	If vFolios.Count() = 0 Then
		vQry.Text = 
		"SELECT
		|	Folio.Ref AS Folio,
		|	Folio.IsMaster AS IsMaster,
		|	Folio.FolioCurrency AS FolioCurrency
		|FROM
		|	Document.Folio AS Folio
		|WHERE
		|	(NOT Folio.DeletionMark)
		|	AND NOT Folio.ParentDoc REFS Document.Reservation
		|	AND Folio.Room = &qRoom
		|	AND Folio.DateTimeFrom <= &qDate
		|	AND Folio.DateTimeTo >= &qDate
		|	AND (&qClientIsFilled AND Folio.Client = &qClient OR NOT &qClientIsFilled)
		|
		|ORDER BY
		|	IsMaster DESC,
		|	Folio.DateTimeFrom " + pSort + ",
		|	Folio.PointInTime " + pSort;
		vQry.SetParameter("qRoom", pRoom);
		vQry.SetParameter("qDate", pDate);
		vQry.SetParameter("qClient", pClient);
		vQry.SetParameter("qClientIsFilled", ValueIsFilled(pClient));
		vFolios = vQry.Execute().Unload();
	EndIf;
	// Add master folios from document charging rules
	i = 0;
	vUsedParentDocs = New ValueList();
	vCopyFolios = vFolios.Copy();
	For Each vFoliosRow In vCopyFolios Do
		vParentDoc = vFoliosRow.Folio.ParentDoc;
		If vUsedParentDocs.FindByValue(vParentDoc) = Undefined Then
			vUsedParentDocs.Add(vParentDoc);
			If ValueIsFilled(vParentDoc) And 
			  (TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation")) Then
				For Each vCRRow In vParentDoc.ChargingRules Do
					vChargingFolio = vCRRow.ChargingFolio;
					If ValueIsFilled(vChargingFolio) And vChargingFolio.IsMaster And Not vChargingFolio.IsClosed And Not vChargingFolio.DeletionMark Then
						If vFolios.Find(vChargingFolio, "Folio") = Undefined Then
							vMasterFoliosRow = vFolios.Insert(i);
							vMasterFoliosRow.Folio = vChargingFolio;
							vMasterFoliosRow.IsMaster = vChargingFolio.IsMaster;
							vMasterFoliosRow.FolioCurrency = vChargingFolio.FolioCurrency;
							i = i + 1;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	Return vFolios;
EndFunction // cmGetFoliosToChargeRoomService

// -----------------------------------------------------------------------------
// Description: Returns value table with employees with rights to sign foreigner
//              notification form
// Parameters: None
// Return value: Value table with employees
// -----------------------------------------------------------------------------
Function cmGetEmployeesWithPermissionToSignNotificationForm(pHotel = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	EmployeesAllowedToSign.Employee AS Employee
	|FROM
	|	(SELECT
	|		Employees.Ref AS Employee
	|	FROM
	|		Catalog.Employees AS Employees
	|	WHERE
	|		Employees.PermissionGroup.HavePermissionToSignForeignerNotificationForm
	|		AND (Employees.Hotel = &qEmptyHotel
	|				OR Employees.Hotel = &qHotel)
	|		AND NOT Employees.DeletionMark
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		EmployeeNonReplicatingAttributes.Employee
	|	FROM
	|		InformationRegister.EmployeeNonReplicatingAttributes AS EmployeeNonReplicatingAttributes
	|	WHERE
	|		EmployeeNonReplicatingAttributes.PermissionGroup.HavePermissionToSignForeignerNotificationForm
	|		AND (EmployeeNonReplicatingAttributes.Employee.Hotel = &qEmptyHotel
	|				OR EmployeeNonReplicatingAttributes.Employee.Hotel = &qHotel)
	|		AND NOT EmployeeNonReplicatingAttributes.Employee.DeletionMark) AS EmployeesAllowedToSign
	|
	|GROUP BY
	|	EmployeesAllowedToSign.Employee
	|
	|ORDER BY
	|	EmployeesAllowedToSign.Employee.SortCode,
	|	EmployeesAllowedToSign.Employee.Description";
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qHotel", pHotel);
	vEmps = vQry.Execute().Unload();
	Return vEmps;
EndFunction // cmGetEmployeesWithPermissionToSignNotificationForm

// -----------------------------------------------------------------------------
// Description: Creates new reservation or accommodation charging rules based on 
//              charging rules from the given document
// Parameters: Object, Template document
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmCreateChargingRulesBasedOnParent(pObj, pBase) Export
	pObj.ChargingRules.Clear();
	// Load default charging rules
	i = pBase.ChargingRules.Count() - 1;
	While i >= 0 Do
		vBaseCRRow = pBase.ChargingRules.Get(i);
		// Create new folio as copy of base one if it is not master one
		vNewFolio = vBaseCRRow.ChargingFolio;
		If Not vBaseCRRow.IsMaster Then
			If ValueIsFilled(vNewFolio) And Not vNewFolio.IsMaster Then
				vNewFolioObj = vNewFolio.GetObject().Copy();
				vNewFolioObj.Date = CurrentSessionDate();
				vNewFolioObj.Author = SessionParameters.CurrentUser;
				vNewFolioObj.ParentDoc = pObj.pmGetThisDocumentRef();
				vNewFolioObj.Write(DocumentWriteMode.Write);
				vNewFolio = vNewFolioObj.Ref;
			EndIf;
		EndIf;
		vCRRow = pObj.ChargingRules.Insert(0);
		FillPropertyValues(vCRRow, vBaseCRRow, , "ChargingFolio");
		vCRRow.ChargingFolio = vNewFolio;
		i = i - 1;
	EndDo;
EndProcedure // cmCreateChargingRulesBasedOnParent

// -----------------------------------------------------------------------------
// Description: Fills new reservation or accommodation charging rules by
//              charging rules from the given document and mark all of them as transfer
// Parameters: Object, Template document
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmLoadMainRoomGuestChargingRules(pObj, pBase) Export
	// Use folios from the base document
	pObj.ChargingRules.Load(pBase.ChargingRules.Unload());
	// Mark charging rules as transfer
	For Each vCRRow In pObj.ChargingRules Do
		vCRRow.IsPersonal = False;
		vCRRow.IsTransfer = True;
	EndDo;
EndProcedure // cmLoadMainRoomGuestChargingRules

// -----------------------------------------------------------------------------
Procedure cmCompareAndUpdateDocumentChargingRules(vObject, vCurrObj, vPostToRoomMainFolio) Export
	// Compare current document charging rules with target document ones
	For i = 0 To vCurrObj.ChargingRules.Count() - 1 Do
		vCRRow = vCurrObj.ChargingRules.Get(i);
		// Skip master document rules
		If vCRRow.IsPersonal Or vCRRow.IsMaster Then
			Continue;
		EndIf;
		vIsFound = False;
		For j = 0 To vObject.ChargingRules.Count() - 1 Do
			vDocCRRow = vObject.ChargingRules.Get(j);
			// Skip master and personal document rules
			If vDocCRRow.IsPersonal Or vDocCRRow.IsMaster Then
				Continue;
			EndIf;
			// Compare
			If vCRRow.ChargingRule = vDocCRRow.ChargingRule And vCRRow.ChargingRuleValue = vDocCRRow.ChargingRuleValue And 
			   vCRRow.ValidFromDate = vDocCRRow.ValidFromDate And vCRRow.ValidToDate = vDocCRRow.ValidToDate And 
			   ValueIsFilled(vCRRow.ChargingFolio) And ValueIsFilled(vDocCRRow.ChargingFolio) And 
			   vCRRow.ChargingFolio.FolioCurrency = vDocCRRow.ChargingFolio.FolioCurrency And 
			   vCRRow.ChargingFolio.IsMaster = vDocCRRow.ChargingFolio.IsMaster Then
				vIsFound = True;
				Break;
			EndIf;
		EndDo;
		If Not vIsFound Then
			vDocCRRow = vObject.ChargingRules.Insert(i);
			cmUpdateChargingRulesFoliosLineNumbers(vObject.ChargingRules);
			FillPropertyValues(vDocCRRow, vCRRow, , "LineNumber");
			If Not vCRRow.ChargingFolio.IsMaster And Not vCRRow.IsTransfer And Not vPostToRoomMainFolio Then
				vFolioObj = vCRRow.ChargingFolio.Copy();
				vFolioObj.pmFillAuthorAndDate();
				vFolioObj.ParentDoc = vObject.Ref;
				vFolioObj.Write(DocumentWriteMode.Write);
				vDocCRRow.ChargingFolio = vFolioObj.Ref;
			ElsIf vPostToRoomMainFolio Then
				vDocCRRow.IsTransfer = True;
			EndIf;
		Else
			If vCRRow.IsTransfer Then
				FillPropertyValues(vDocCRRow, vCRRow, , "LineNumber");
			Else
				vFolioObj = vDocCRRow.ChargingFolio.GetObject();
				vFolioObj.Customer = vCRRow.ChargingFolio.Customer;
				vFolioObj.Contract = vCRRow.ChargingFolio.Contract;
				vFolioObj.Agent = vCRRow.ChargingFolio.Agent;
				vFolioObj.PaymentMethod = vCRRow.ChargingFolio.PaymentMethod;
				vFolioObj.Write(DocumentWriteMode.Write);
				vDocCRRow.Owner = vCRRow.Owner;
			EndIf;
			If i <> j And vCurrObj.ChargingRules.Count() = vObject.ChargingRules.Count() Then
				vObject.ChargingRules.Move(j, i - j);
			EndIf;
		EndIf;
	EndDo;
	// Compare target document charging rules with current document ones
	i = 0;
	While i < vObject.ChargingRules.Count() Do
		vDocCRRow = vObject.ChargingRules.Get(i);
		// Skip master and personal document rules
		If vDocCRRow.IsPersonal Or vDocCRRow.IsMaster Then
			i = i + 1;
			Continue;
		EndIf;
		vIsFound = False;
		For j = 0 To vCurrObj.ChargingRules.Count() - 1 Do
			vCRRow = vCurrObj.ChargingRules.Get(j);
			// Skip master document rules
			If vCRRow.IsPersonal Or vCRRow.IsMaster Then
				Continue;
			EndIf;
			// Compare
			If vCRRow.ChargingRule = vDocCRRow.ChargingRule And vCRRow.ChargingRuleValue = vDocCRRow.ChargingRuleValue And 
			   vCRRow.ValidFromDate = vDocCRRow.ValidFromDate And vCRRow.ValidToDate = vDocCRRow.ValidToDate And 
			   ValueIsFilled(vCRRow.ChargingFolio) And ValueIsFilled(vDocCRRow.ChargingFolio) And 
			   vCRRow.ChargingFolio.FolioCurrency = vDocCRRow.ChargingFolio.FolioCurrency And 
			   vCRRow.ChargingFolio.IsMaster = vDocCRRow.ChargingFolio.IsMaster Then
				vIsFound = True;
				Break;
			EndIf;
		EndDo;
		If Not vIsFound Then
			vObject.ChargingRules.Delete(i);
			Continue;
		EndIf;
		i = i + 1;
	EndDo;
	cmUpdateChargingRulesFoliosLineNumbers(vObject.ChargingRules);
EndProcedure // cmCompareAndUpdateDocumentChargingRules

// -----------------------------------------------------------------------------
// Description: Fills new reservation or accommodation charging rules based on 
//              charging rules from the given document
// Parameters: Object, Template document
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmUseParentChargingRules(pObj, pBase, pIsTransfer = False) Export
	// Use folios from the base document
	pObj.ChargingRules.Load(pBase.ChargingRules.Unload());
	// Delete personal charging rules
	i = 0;
	While i < pObj.ChargingRules.Count() Do
		vCRRow = pObj.ChargingRules.Get(i);
		If vCRRow.IsPersonal And pIsTransfer Then
			pObj.ChargingRules.Delete(i);
		Else
			If pIsTransfer Then
				vCRRow.IsTransfer = pIsTransfer;
			EndIf;
			i = i + 1;
		EndIf;
	EndDo;
	// Load hotel personal charging rules
	If ValueIsFilled(pBase.Hotel) And pIsTransfer Then
		For Each vHotelCRRow In pBase.Hotel.ChargingRules Do
			If vHotelCRRow.IsPersonal Then
				vNewCRRowFolio = vHotelCRRow.ChargingFolio.GetObject();
				If Not vNewCRRowFolio.IsMaster Then
					vNewCRRowFolio = vNewCRRowFolio.Copy();
					vNewCRRowFolio.Date = CurrentSessionDate();
					vNewCRRowFolio.Author = SessionParameters.CurrentUser;
				EndIf;
				vNewCRRowFolio.ParentDoc = ?(ValueIsFilled(pObj.Ref), pObj.Ref, pObj.GetNewObjectRef());
				vNewCRRowFolio.Client = pObj.Guest;
				vNewCRRowFolio.Room = pObj.Room;
				vNewCRRowFolio.DateTimeFrom = pObj.CheckInDate;
				vNewCRRowFolio.DateTimeTo = pObj.CheckOutDate;
				vNewCRRowFolio.GuestGroup = pObj.GuestGroup;
				If Not vNewCRRowFolio.DoNotUpdateCompany Then
					vNewCRRowFolio.Company = pObj.Company;
				EndIf;
				vNewCRRowFolio.Write(DocumentWriteMode.Write);
				// Fill charging rule
				vPrsCRRow = pObj.ChargingRules.Add();
				FillPropertyValues(vPrsCRRow, vHotelCRRow, , "LineNumber");
				vPrsCRRow.ChargingFolio = vNewCRRowFolio.Ref;
				vPrsCRRow.IsTransfer = False;
			EndIf;
		EndDo;
	EndIf;
	// Check if there are at least one charging rule
	If pObj.ChargingRules.Count() = 0 Then
		// Create default document charging rules
		pObj.pmCreateFolios();
	EndIf;
EndProcedure // cmUseParentChargingRules

// -----------------------------------------------------------------------------
// Description: Checks if client identification document is in the list of 
//              forbidden identification documents
// Parameters: Type of identification document, Series of the identification document,
//             Number of the identification document, Returns description of forbidden
//             document if it is found
// Return value: True if document was found in the forbidden list, False if not
// -----------------------------------------------------------------------------
Function cmIsClientIdentityDocumentInForbiddenList(pIDType, pIDSeries, pIDNumber, rIDRemarks) Export
	rIDRemarks = "";
	If IsBlankString(pIDSeries) And IsBlankString(pIDNumber) Then
		Return False;
	EndIf;
	vQry = New Query();
	vQry.Text = "SELECT
	            |	ForbiddenIdentificationDocuments.Remarks
	            |FROM
	            |	InformationRegister.ForbiddenIdentificationDocuments AS ForbiddenIdentificationDocuments
	            |WHERE
	            |	ForbiddenIdentificationDocuments.IdentityDocumentType = &qIDType
	            |	AND ForbiddenIdentificationDocuments.IdentityDocumentSeries = &qIDSeries
	            |	AND ForbiddenIdentificationDocuments.IdentityDocumentNumber = &qIDNumber";
	vQry.SetParameter("qIDType", pIDType);
	vQry.SetParameter("qIDSeries", pIDSeries);
	vQry.SetParameter("qIDNumber", pIDNumber);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vRow = vQryRes.Get(0);
		rIDRemarks = TrimAll(vRow.Remarks);
		Return True;
	EndIf;
	Return False;
EndFunction // cmIsClientIdentityDocumentInForbiddenList

// -----------------------------------------------------------------------------
// Description: Calculates effective number of rooms that accommodation should 
//              write off from the vacant rooms
// Parameters: Accommodation object
// Return value: Number of rooms to write off
// -----------------------------------------------------------------------------
Function cmCalculateEffectiveNumberOfRoomsForAccommodation(pAccObj) Export
	// Calculate the effective number of rooms to write off
	vEffectiveNumberOfRooms = New ValueTable();
	vEffectiveNumberOfRooms.Columns.Add("EffectiveNumberOfRooms", cmGetNumberTypeDescription(10, 0));
	vEffectiveNumberOfRooms.Columns.Add("PeriodFrom", cmGetDateTimeTypeDescription());
	vEffectiveNumberOfRooms.Columns.Add("PeriodTo", cmGetDateTimeTypeDescription());
	If pAccObj.NumberOfRooms <> 0 Then
		vEffectiveNumberOfRoomsRow = vEffectiveNumberOfRooms.Add();
		vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = pAccObj.NumberOfRooms;
		vEffectiveNumberOfRoomsRow.PeriodFrom = cm1SecondShift(pAccObj.CheckInDate);
		vEffectiveNumberOfRoomsRow.PeriodTo = cm0SecondShift(pAccObj.CheckOutDate);
	Else
		If pAccObj.NumberOfBedsPerRoom = 0 Then
			vEffectiveNumberOfRoomsRow = vEffectiveNumberOfRooms.Add();
			vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = 0;
			vEffectiveNumberOfRoomsRow.PeriodFrom = cm1SecondShift(pAccObj.CheckInDate);
			vEffectiveNumberOfRoomsRow.PeriodTo = cm0SecondShift(pAccObj.CheckOutDate);
		Else
			// Run query to get periods where number of vacant rooms has changed
			vVacantPeriods = cmGetVacantRoomsByPeriodsForAccommodation(pAccObj.Hotel, pAccObj.RoomType, pAccObj.Room, pAccObj.CheckInDate, pAccObj.CheckOutDate);
			// Process each period
			For Each vVacantPeriodsRow In vVacantPeriods Do
				vEffectiveNumberOfRoomsRow = vEffectiveNumberOfRooms.Add();
				vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = 0;
				If cm1SecondShift(pAccObj.CheckInDate) = cm1SecondShift(vVacantPeriodsRow.PeriodFrom) Then
					vEffectiveNumberOfRoomsRow.PeriodFrom = cm1SecondShift(vVacantPeriodsRow.PeriodFrom);
				Else
					vEffectiveNumberOfRoomsRow.PeriodFrom = vVacantPeriodsRow.PeriodFrom;
				EndIf;
				If cm0SecondShift(pAccObj.CheckOutDate) = cm0SecondShift(vVacantPeriodsRow.PeriodTo) Then
					vEffectiveNumberOfRoomsRow.PeriodTo = cm0SecondShift(vVacantPeriodsRow.PeriodTo);
				Else
					vEffectiveNumberOfRoomsRow.PeriodTo = vVacantPeriodsRow.PeriodTo;
				EndIf;
				// Calculation
				vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = Int(pAccObj.NumberOfBeds/pAccObj.NumberOfBedsPerRoom);
				vRestOfNumberOfBeds = pAccObj.NumberOfBeds - vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms * pAccObj.NumberOfBedsPerRoom;
				If vRestOfNumberOfBeds <> 0 Then
					// Get the total number of occupied beds
					vNumberOfOccupiedBeds = vVacantPeriodsRow.TotalBeds - vVacantPeriodsRow.BedsVacant;
					vNumberOfOccupiedRooms = vVacantPeriodsRow.TotalRooms - vVacantPeriodsRow.RoomsVacant;
					// If this accommodation is in room quota and room quota is written off then we should 
					// correct results with number of rooms/beds reserved or checked-in already
					If ValueIsFilled(pAccObj.RoomQuota) And 
					   pAccObj.RoomQuota.DoWriteOff And pAccObj.RoomQuota.IsQuotaForRooms Then
						vEffCheckInDate = cmMovePeriodFromToReferenceHour(vVacantPeriodsRow.PeriodFrom, pAccObj.RoomRate);
						vEffCheckOutDate = cmMovePeriodToToReferenceHour(vVacantPeriodsRow.PeriodTo, pAccObj.RoomRate);
						If vEffCheckInDate < vEffCheckOutDate Then
							vQuotaRests = cmCalculateRoomQuotaResources(pAccObj.RoomQuota, pAccObj.Hotel, pAccObj.RoomType, pAccObj.Room, vEffCheckInDate, vEffCheckOutDate);
							For Each vQuotaRestsRow In vQuotaRests Do
								vNumberOfOccupiedBeds = vNumberOfOccupiedBeds - vQuotaRestsRow.BedsInQuota - vQuotaRestsRow.BedsReserved - vQuotaRestsRow.InHouseBeds;
								vNumberOfOccupiedRooms = vNumberOfOccupiedRooms - vQuotaRestsRow.RoomsInQuota - vQuotaRestsRow.RoomsReserved - vQuotaRestsRow.InHouseRooms;
							EndDo;
						EndIf;
					EndIf;
					// Calculate should we add 1 to the effective number of occupied rooms
					If ValueIsFilled(pAccObj.Room) Then
						If vNumberOfOccupiedRooms = 0 Then
							vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms + 1;
						EndIf;
					Else
						vRestOfNumberOfBeds = vNumberOfOccupiedRooms * pAccObj.NumberOfBedsPerRoom - vNumberOfOccupiedBeds - vRestOfNumberOfBeds;
						If vRestOfNumberOfBeds < 0 Then
							vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms + 1;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	// Join rows
	i = 1;
	While i < vEffectiveNumberOfRooms.Count() Do
		vRow = vEffectiveNumberOfRooms.Get(i);
		vPrevRow = vEffectiveNumberOfRooms.Get(i - 1);
		If vPrevRow.EffectiveNumberOfRooms = vRow.EffectiveNumberOfRooms Then
			vPrevRow.PeriodTo = vRow.PeriodTo;
			vEffectiveNumberOfRooms.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	Return vEffectiveNumberOfRooms;
EndFunction // cmCalculateEffectiveNumberOfRoomsForAccommodation

// -----------------------------------------------------------------------------
// Description: Calculates effective number of rooms that reservation should 
//              write off from the vacant rooms
// Parameters: Accommodation object
// Return value: Number of rooms to write off
// -----------------------------------------------------------------------------
Function cmCalculateEffectiveNumberOfRoomsForReservation(pAccObj, pEffectiveNumberOfRooms, pEffectiveNumberOfBeds, pEffectiveNumberOfAddBeds, pEffectiveNumberOfPersons) Export
	// Calculate the effective number of rooms to write off
	vEffectiveNumberOfRooms = New ValueTable();
	vEffectiveNumberOfRooms.Columns.Add("EffectiveNumberOfRooms", cmGetNumberTypeDescription(10, 0));
	vEffectiveNumberOfRooms.Columns.Add("PeriodFrom", cmGetDateTimeTypeDescription());
	vEffectiveNumberOfRooms.Columns.Add("PeriodTo", cmGetDateTimeTypeDescription());
	If pAccObj.NumberOfRooms <> 0 Then
		vEffectiveNumberOfRoomsRow = vEffectiveNumberOfRooms.Add();
		vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = Min(pAccObj.NumberOfRooms, pEffectiveNumberOfRooms);
		vEffectiveNumberOfRoomsRow.PeriodFrom = cm1SecondShift(pAccObj.CheckInDate);
		vEffectiveNumberOfRoomsRow.PeriodTo = cm0SecondShift(pAccObj.CheckOutDate);
	Else
		If pAccObj.NumberOfBedsPerRoom = 0 Then
			vEffectiveNumberOfRoomsRow = vEffectiveNumberOfRooms.Add();
			vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = 0;
			vEffectiveNumberOfRoomsRow.PeriodFrom = cm1SecondShift(pAccObj.CheckInDate);
			vEffectiveNumberOfRoomsRow.PeriodTo = cm0SecondShift(pAccObj.CheckOutDate);
		Else
			// Run query to get periods where number of vacant rooms has changed
			vVacantPeriods = cmGetVacantRoomsByPeriodsForReservation(pAccObj.Hotel, pAccObj.RoomType, pAccObj.Room, pAccObj.RoomQuota, pAccObj.CheckInDate, pAccObj.CheckOutDate);
			// Process each period
			If vVacantPeriods.Count() = 0 Then
				vEffectiveNumberOfRoomsRow = vEffectiveNumberOfRooms.Add();
				vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = Min(pAccObj.NumberOfRooms, pEffectiveNumberOfRooms);
				vEffectiveNumberOfRoomsRow.PeriodFrom = cm1SecondShift(pAccObj.CheckInDate);
				vEffectiveNumberOfRoomsRow.PeriodTo = cm0SecondShift(pAccObj.CheckOutDate);
			Else
				For Each vVacantPeriodsRow In vVacantPeriods Do
					vEffectiveNumberOfRoomsRow = vEffectiveNumberOfRooms.Add();
					vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = 0;
					If cm1SecondShift(pAccObj.CheckInDate) = cm1SecondShift(vVacantPeriodsRow.PeriodFrom) Then
						vEffectiveNumberOfRoomsRow.PeriodFrom = cm1SecondShift(vVacantPeriodsRow.PeriodFrom);
					Else
						vEffectiveNumberOfRoomsRow.PeriodFrom = vVacantPeriodsRow.PeriodFrom;
					EndIf;
					If cm0SecondShift(pAccObj.CheckOutDate) = cm0SecondShift(vVacantPeriodsRow.PeriodTo) Then
						vEffectiveNumberOfRoomsRow.PeriodTo = cm0SecondShift(vVacantPeriodsRow.PeriodTo);
					Else
						vEffectiveNumberOfRoomsRow.PeriodTo = vVacantPeriodsRow.PeriodTo;
					EndIf;
					// Calculation
					vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = Int(pAccObj.NumberOfBeds/pAccObj.NumberOfBedsPerRoom);
					vRestOfNumberOfBeds = pAccObj.NumberOfBeds - vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms * pAccObj.NumberOfBedsPerRoom;
					If vRestOfNumberOfBeds <> 0 Then
						// Get the total number of occupied beds
						vNumberOfOccupiedBeds = vVacantPeriodsRow.TotalBeds - vVacantPeriodsRow.BedsVacant;
						vNumberOfOccupiedRooms = vVacantPeriodsRow.TotalRooms - vVacantPeriodsRow.RoomsVacant;
						// If this accommodation is in room quota and room quota is written off then we should 
						// correct results with number of rooms/beds reserved or checked-in already
						If ValueIsFilled(pAccObj.RoomQuota) And 
						   pAccObj.RoomQuota.DoWriteOff And pAccObj.RoomQuota.IsQuotaForRooms Then
							vEffCheckInDate = cmMovePeriodFromToReferenceHour(vVacantPeriodsRow.PeriodFrom, pAccObj.RoomRate);
							vEffCheckOutDate = cmMovePeriodToToReferenceHour(vVacantPeriodsRow.PeriodTo, pAccObj.RoomRate);
							If vEffCheckInDate < vEffCheckOutDate Then
								vQuotaRests = cmCalculateRoomQuotaResources(pAccObj.RoomQuota, pAccObj.Hotel, pAccObj.RoomType, pAccObj.Room, vEffCheckInDate, vEffCheckOutDate);
								For Each vQuotaRestsRow In vQuotaRests Do
									vNumberOfOccupiedBeds = vNumberOfOccupiedBeds - vQuotaRestsRow.BedsInQuota - vQuotaRestsRow.BedsReserved - vQuotaRestsRow.InHouseBeds;
									vNumberOfOccupiedRooms = vNumberOfOccupiedRooms - vQuotaRestsRow.RoomsInQuota - vQuotaRestsRow.RoomsReserved - vQuotaRestsRow.InHouseRooms;
								EndDo;
							EndIf;
						EndIf;
						// Calculate should we add 1 to the effective number of occupied rooms
						If ValueIsFilled(pAccObj.Room) And (Not ValueIsFilled(pAccObj.RoomQuota) Or ValueIsFilled(pAccObj.RoomQuota) And Not pAccObj.RoomQuota.IsQuotaForRooms) Then
							If vNumberOfOccupiedRooms = 0 Then
								vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms + 1;
							EndIf;
						Else
							vRestOfNumberOfBeds = vNumberOfOccupiedRooms * pAccObj.NumberOfBedsPerRoom - vNumberOfOccupiedBeds - vRestOfNumberOfBeds;
							If vRestOfNumberOfBeds < 0 Then
								vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = vEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms + 1;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	// Join rows
	i = 1;
	While i < vEffectiveNumberOfRooms.Count() Do
		vRow = vEffectiveNumberOfRooms.Get(i);
		vPrevRow = vEffectiveNumberOfRooms.Get(i - 1);
		If vPrevRow.EffectiveNumberOfRooms = vRow.EffectiveNumberOfRooms Then
			vPrevRow.PeriodTo = vRow.PeriodTo;
			vEffectiveNumberOfRooms.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	Return vEffectiveNumberOfRooms;
EndFunction // cmCalculateEffectiveNumberOfRoomsForReservation

// -----------------------------------------------------------------------------
// Description: Calculates effective number of rooms, beds, number of persons that 
//              reservation should write off from the vacant rooms
// Parameters: Reservation object
// Return value: Structure with rooms, beds, persons to write off
// -----------------------------------------------------------------------------
Function cmCalculateEffectiveResourcesForReservation(pResObj) Export
	// Initialize effective resources structure
	vEffectiveResources = New Structure("EffectiveNumberOfBeds, EffectiveNumberOfAddBeds, EffectiveNumberOfPersons, EffectiveNumberOfRooms", 0, 0, 0, 0);
	
	// Initialize working variables for reservation resources
	vNumberOfRooms = pResObj.NumberOfRooms;
	vNumberOfBeds = pResObj.NumberOfBeds;
	vNumberOfAdditionalBeds = pResObj.NumberOfAdditionalBeds;
	vNumberOfPersons = pResObj.NumberOfPersons;
	
	// Calculate write offs done by accommodations based on this reservation
	vWriteOffs = cmGetWriteOffsForReservation(pResObj.Ref);
	
	// Correct resources according to the write offs
	If vWriteOffs.Count() > 0 Then
		For Each vWriteOffRow In vWriteOffs Do
			vNumberOfRooms = vNumberOfRooms - vWriteOffRow.RoomsCheckedIn;
			vNumberOfBeds = vNumberOfBeds - vWriteOffRow.BedsCheckedIn;
			vNumberOfAdditionalBeds = vNumberOfAdditionalBeds - vWriteOffRow.AdditionalBedsCheckedIn;
			vNumberOfPersons = vNumberOfPersons - vWriteOffRow.GuestsCheckedIn;
		EndDo;
		
		If vNumberOfRooms < 0 Then
			vNumberOfRooms = 0;
		EndIf;
		If vNumberOfBeds < 0 Then
			vNumberOfBeds = 0;
		EndIf;
		If vNumberOfAdditionalBeds < 0 Then
			vNumberOfAdditionalBeds = 0;
		EndIf;
		If vNumberOfPersons < 0 Then
			vNumberOfPersons = 0;
		EndIf;
	EndIf;
	
	// Set effective resources to be used by the document
	vEffectiveNumberOfBeds = vNumberOfBeds;
	vEffectiveNumberOfAddBeds = vNumberOfAdditionalBeds;
	vEffectiveNumberOfPersons = vNumberOfPersons;
	
	// Calculate the effective number of rooms to write off
	vEffectiveNumberOfRooms = 0;
	If vNumberOfRooms <> 0 Then
		vEffectiveNumberOfRooms = vNumberOfRooms;
	Else
		If pResObj.NumberOfBedsPerRoom <> 0 Then
			vEffectiveNumberOfRooms = Int(vNumberOfBeds/pResObj.NumberOfBedsPerRoom);
			vRestOfNumberOfBeds = vNumberOfBeds - vEffectiveNumberOfRooms * pResObj.NumberOfBedsPerRoom;
			If vRestOfNumberOfBeds <> 0 Then
				// Get the total number of occupied beds
				vNumberOfOccupiedBeds = 0;
				vNumberOfOccupiedRooms = 0;
				vRestsTab = cmGetRestOfVacantRooms(pResObj.Hotel, pResObj.RoomType, pResObj.Room, pResObj.CheckInDate, pResObj.CheckOutDate);
				For Each vRestsTabRow In vRestsTab Do
					vNumberOfOccupiedBeds = vNumberOfOccupiedBeds + vRestsTabRow.TotalBeds - vRestsTabRow.BedsVacant;
					vNumberOfOccupiedRooms = vNumberOfOccupiedRooms + vRestsTabRow.TotalRooms - vRestsTabRow.RoomsVacant;
				EndDo;
				// If this reservation is in room quota and room quota is written off then we should 
				// correct results with number of rooms/beds reserved or checked-in already
				If ValueIsFilled(pResObj.RoomQuota) And pResObj.RoomQuota.DoWriteOff And 
				   (pResObj.RoomQuota.IsQuotaForRooms And ValueIsFilled(pResObj.Room) Or (Not ValueIsFilled(pResObj.Room))) Then
					vEffCheckInDate = cmMovePeriodFromToReferenceHour(pResObj.CheckInDate, pResObj.RoomRate);
					vEffCheckOutDate = cmMovePeriodToToReferenceHour(pResObj.CheckOutDate, pResObj.RoomRate);
					If vEffCheckInDate < vEffCheckOutDate Then
						vQuotaRests = cmCalculateRoomQuotaResources(pResObj.RoomQuota, pResObj.Hotel, pResObj.RoomType, pResObj.Room, vEffCheckInDate, vEffCheckOutDate);
						For Each vQuotaRestsRow In vQuotaRests Do
							vNumberOfOccupiedBeds = vNumberOfOccupiedBeds - vQuotaRestsRow.BedsInQuota - vQuotaRestsRow.BedsReserved - vQuotaRestsRow.InHouseBeds;
							vNumberOfOccupiedRooms = vNumberOfOccupiedRooms - vQuotaRestsRow.RoomsInQuota - vQuotaRestsRow.RoomsReserved - vQuotaRestsRow.InHouseRooms;
						EndDo;
					EndIf;
				EndIf;
				// Calculate should we add 1 to the effective number of occupied rooms
				If ValueIsFilled(pResObj.Room) Then
					If vNumberOfOccupiedRooms = 0 Then
						vEffectiveNumberOfRooms = vEffectiveNumberOfRooms + 1;
					EndIf;
				Else
					If (vNumberOfOccupiedRooms * pResObj.NumberOfBedsPerRoom) >= vNumberOfOccupiedBeds Then
						vRestOfNumberOfBeds = vNumberOfOccupiedRooms * pResObj.NumberOfBedsPerRoom - vNumberOfOccupiedBeds - vRestOfNumberOfBeds;
						If vRestOfNumberOfBeds < 0 Then
							vEffectiveNumberOfRooms = vEffectiveNumberOfRooms + 1;
						EndIf;
					Else
						vEffectiveNumberOfRooms = vEffectiveNumberOfRooms + 1;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Fill resources structure with calculated values
	vEffectiveResources.EffectiveNumberOfBeds = vEffectiveNumberOfBeds;
	vEffectiveResources.EffectiveNumberOfAddBeds = vEffectiveNumberOfAddBeds;
	vEffectiveResources.EffectiveNumberOfPersons = vEffectiveNumberOfPersons;
	vEffectiveResources.EffectiveNumberOfRooms = vEffectiveNumberOfRooms;
	
	// Return resources
	Return vEffectiveResources;
EndFunction // cmCalculateEffectiveResourcesForReservation

// -----------------------------------------------------------------------------
// Description: Returns reference hour for the given room rate
// Parameters: Room rate
// Return value: Reference hour time 
// -----------------------------------------------------------------------------
Function cmGetReferenceHour(Val pRoomRate) Export
	vRefHour = '00010101120000';
	vRoomRate = pRoomRate;
	If Not ValueIsFilled(vRoomRate) And ValueIsFilled(SessionParameters.CurrentHotel) And 
	   ValueIsFilled(SessionParameters.CurrentHotel.RoomRate) Then
		vRoomRate = SessionParameters.CurrentHotel.RoomRate;
	EndIf;
	If ValueIsFilled(vRoomRate) Then
		If vRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			vRefHour = vRoomRate.ReferenceHour;
		EndIf;
	EndIf;
	Return vRefHour;
EndFunction // cmGetReferenceHour

// -----------------------------------------------------------------------------
// Description: Returns default check-in time for the given room rate
// Parameters: Room rate
// Return value: Default check-in time 
// -----------------------------------------------------------------------------
Function cmGetDefaultCheckInTime(pRoomRate) Export
	vCheckInTime = '00010101120000';
	If ValueIsFilled(pRoomRate) Then
		If ValueIsFilled(pRoomRate.DefaultCheckInTime) Or ValueIsFilled(pRoomRate.DefaultCheckOutTime) Then
			vCheckInTime = pRoomRate.DefaultCheckInTime;
		EndIf;
	EndIf;
	Return vCheckInTime;
EndFunction // cmGetDefaultCheckInTime

// -----------------------------------------------------------------------------
// Description: Returns default check-in time for the given room rate
// Parameters: Room rate
// Return value: Default check-in time 
// -----------------------------------------------------------------------------
Function cmGetDefaultCheckOutTime(pRoomRate) Export
	vCheckOutTime = '00010101120000';
	If ValueIsFilled(pRoomRate) Then
		If ValueIsFilled(pRoomRate.DefaultCheckOutTime) Then
			vCheckOutTime = pRoomRate.DefaultCheckOutTime;
		ElsIf ValueIsFilled(pRoomRate.ReferenceHour) Then
			vCheckOutTime = pRoomRate.ReferenceHour;
		EndIf;
	EndIf;
	Return vCheckOutTime;
EndFunction // cmGetDefaultCheckOutTime

// -----------------------------------------------------------------------------
// Description: Moves check-in date to the nearest reference hour
// Parameters: Check-in date, Room rate
// Return value: Check-in date with time set to the reference hour
// -----------------------------------------------------------------------------
Function cmMovePeriodFromToReferenceHour(pPeriodFrom, pRoomRate) Export
	vRefHour = cmGetReferenceHour(pRoomRate);
	Return cm1SecondShift(BegOfDay(pPeriodFrom) + (vRefHour - BegOfDay(vRefHour)));
EndFunction // cmMovePeriodFromToReferenceHour

// -----------------------------------------------------------------------------
// Description: Moves check-out date to the nearest reference hour
// Parameters: Check-out date, Room rate
// Return value: Check-out date with time set to the reference hour
// -----------------------------------------------------------------------------
Function cmMovePeriodToToReferenceHour(pPeriodTo, pRoomRate) Export
	vRefHour = cmGetReferenceHour(pRoomRate);
	Return cm0SecondShift(BegOfDay(pPeriodTo) + (vRefHour - BegOfDay(vRefHour)));
EndFunction // cmMovePeriodToToReferenceHour

// -----------------------------------------------------------------------------
// Description: Returns value table with room attributes changes 
// Parameters: Room, Period from date, Period to date
// Return value: Value table with room changes
// -----------------------------------------------------------------------------
Function cmGetChangeRoomAttributes(pRoom, pPeriodFrom, pPeriodTo) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventory.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Hotel = &qHotel
	|	AND RoomInventory.Room = &qRoom
	|	AND RoomInventory.Period > &qPeriodFrom
	|	AND RoomInventory.Period < &qPeriodTo
	|	AND RoomInventory.IsRoomInventory
	|
	|ORDER BY
	|	RoomInventory.Period";
	vQry.SetParameter("qHotel", pRoom.Owner);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(pPeriodTo), pPeriodTo, '39991231'));
	Return vQry.Execute().Unload();
EndFunction // cmGetChangeRoomAttributes

// -----------------------------------------------------------------------------
// Description: Checks if there is stop sale set for the room type given for the 
//              period given
// Parameters: Room type, Period from date, Period to date, Returns stop sale 
//             description if found
// Return value: True if room type is on stop sale for the given period, False if not
// -----------------------------------------------------------------------------
Function cmIsStopSalePeriod(pRoomType, pPeriodFrom, pPeriodTo, rRemarks = "", pShowPeriod = False) Export
	rRemarks = "";
	vIsStopSale = False;
	For Each vRow In pRoomType.StopSalePeriods Do
		If vRow.StopSale Then
			If ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) And vRow.PeriodFrom < pPeriodTo And vRow.PeriodTo > pPeriodFrom And pPeriodTo <> pPeriodFrom Or 
			   ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) And vRow.PeriodFrom <= pPeriodFrom And vRow.PeriodTo > pPeriodTo And pPeriodTo = pPeriodFrom Or 
			   Not ValueIsFilled(vRow.PeriodFrom) And Not ValueIsFilled(vRow.PeriodTo) Or
			   Not ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) And vRow.PeriodTo > pPeriodFrom Or
			   ValueIsFilled(vRow.PeriodFrom) And Not ValueIsFilled(vRow.PeriodTo) And vRow.PeriodFrom < pPeriodTo Then
				vIsStopSale = True;
				If pShowPeriod Then
					rRemarks = Format(vRow.PeriodFrom, "DF='dd.MM.yy HH:mm'") + " - " + Format(vRow.PeriodTo, "DF='dd.MM.yy HH:mm'") + Chars.LF + Chars.Tab + TrimAll(vRow.Remarks);
				Else
					rRemarks = TrimAll(vRow.Remarks);
				EndIf;
				Break;
			EndIf;
		EndIf;
	EndDo;
	Return vIsStopSale;
EndFunction // cmIsStopSalePeriod

// -----------------------------------------------------------------------------
// Description: Checks if there is internet stop sale set for the room type given for the 
//              period given
// Parameters: Room type, Period from date, Period to date, Returns stop sale 
//             description if found
// Return value: True if room type is on internet stop sale for the given period, False if not
// -----------------------------------------------------------------------------
Function cmIsStopInternetSalePeriod(pRoomType, pPeriodFrom, pPeriodTo, rRemarks = "") Export
	rRemarks = "";
	vIsStopSale = False;
	For Each vRow In pRoomType.StopSalePeriods Do
		If vRow.StopSale Or vRow.StopInternetSale Then
			If ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) And vRow.PeriodFrom < pPeriodTo And vRow.PeriodTo > pPeriodFrom And pPeriodTo <> pPeriodFrom Or 
			   ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) And vRow.PeriodFrom <= pPeriodFrom And vRow.PeriodTo > pPeriodTo And pPeriodTo = pPeriodFrom Or
			   Not ValueIsFilled(vRow.PeriodFrom) And Not ValueIsFilled(vRow.PeriodTo) Or
			   Not ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) And vRow.PeriodTo > pPeriodFrom Or
			   ValueIsFilled(vRow.PeriodFrom) And Not ValueIsFilled(vRow.PeriodTo) And vRow.PeriodFrom < pPeriodTo Then
				vIsStopSale = True;
				rRemarks = TrimAll(vRow.Remarks);
				Break;
			EndIf;
		EndIf;
	EndDo;
	Return vIsStopSale;
EndFunction // cmIsStopInternetSalePeriod

// -----------------------------------------------------------------------------
// Description: Checks if there is stop sale set for the room given for the 
//              period given
// Parameters: Room, Period from date, Period to date, Returns stop sale 
//             description if found
// Return value: True if room is on stop sale for the given period, False if not
// -----------------------------------------------------------------------------
Function cmIsRoomStopSalePeriod(pRoom, pPeriodFrom, pPeriodTo, rRemarks = "", pShowPeriod = False) Export
	rRemarks = "";
	vIsStopSale = False;
	For Each vRow In pRoom.StopSalePeriods Do
		If vRow.StopSale Then
			If ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) And vRow.PeriodFrom < pPeriodTo And vRow.PeriodTo > pPeriodFrom And pPeriodTo <> pPeriodFrom Or 
			   ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) And vRow.PeriodFrom <= pPeriodFrom And vRow.PeriodTo > pPeriodTo And pPeriodTo = pPeriodFrom Or 
			   Not ValueIsFilled(vRow.PeriodFrom) And Not ValueIsFilled(vRow.PeriodTo) Or
			   Not ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) And vRow.PeriodTo > pPeriodFrom Or
			   ValueIsFilled(vRow.PeriodFrom) And Not ValueIsFilled(vRow.PeriodTo) And vRow.PeriodFrom < pPeriodTo Then
				vIsStopSale = True;
				If pShowPeriod Then
					rRemarks = Format(vRow.PeriodFrom, "DF='dd.MM.yy HH:mm'") + " - " + Format(vRow.PeriodTo, "DF='dd.MM.yy HH:mm'") + Chars.LF + Chars.Tab + TrimAll(vRow.Remarks);
				Else
					rRemarks = TrimAll(vRow.Remarks);
				EndIf;
				Break;
			EndIf;
		EndIf;
	EndDo;
	Return vIsStopSale;
EndFunction // cmIsRoomStopSalePeriod

// -----------------------------------------------------------------------------
// Description: Returns list of default hotel charging rule owners. 
// Parameters: Hotel
// Return value: Value list of customers/contracts
// -----------------------------------------------------------------------------
Function cmGetHotelDefaultChargingRuleOwners(pHotel) Export
	vOwners = New ValueList();
	If ValueIsFilled(pHotel) Then
		For Each vCRRow In pHotel.ChargingRules Do
			vFolio = vCRRow.ChargingFolio;
			If ValueIsFilled(vFolio) Then
				If ValueIsFilled(vFolio.Contract) Then
					vOwners.Add(vFolio.Contract);
				ElsIf ValueIsFilled(vFolio.Customer) Then
					vOwners.Add(vFolio.Customer);
				EndIf;
				If ValueIsFilled(vFolio.Agent) Then
					vOwners.Add(vFolio.Agent);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return vOwners;
EndFunction // cmGetHotelDefaultChargingRuleOwners

// -----------------------------------------------------------------------------
// Description: Returns list of vacant rooms for accommodation 
// Parameters: Number of vacant beds that room should have, Hotel, Company, 
//             Room quota, Room type, Room status, Period from date, Period to date
// Return value: Value table with vacant rooms
// -----------------------------------------------------------------------------
Function cmGetVacantRoomsList(pNumberOfBeds, pHotel, pCompany, pRoomQuota, pRoomType, pRoomStatus = Undefined, pDateFrom, pDateTo) Export
	// Clear resulting table
	vTableBoxRooms = New ValueTable();
	vTableBoxRooms.Columns.Add("Room", cmGetCatalogTypeDescription("Rooms"));
	vTableBoxRooms.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vTableBoxRooms.Columns.Add("Company", cmGetCatalogTypeDescription("Companies"));
	vTableBoxRooms.Columns.Add("VacantFrom", cmGetDateTimeTypeDescription());
	vTableBoxRooms.Columns.Add("VacantTo", cmGetDateTimeTypeDescription());
	vTableBoxRooms.Columns.Add("BedsVacant", cmGetNumberTypeDescription(10, 0));
	vTableBoxRooms.Columns.Add("SortCode", cmGetNumberTypeDescription(8, 0));
	vTableBoxRooms.Columns.Add("IsFolder", cmGetBooleanTypeDescription());
	
	If Not ValueIsFilled(pHotel) Then
		Return vTableBoxRooms;
	EndIf;
	
	// Initialize working array
	vRoomsArray = New Array();
	
	// Run query to get rooms in room quota if filled
	vUseRoomQuota = False;
	vRoomsInQuota = New ValueList();
	If ValueIsFilled(pRoomQuota) Then
		If Not pRoomQuota.DeletionMark And pRoomQuota.IsQuotaForRooms Then
			vUseRoomQuota = True;
			vQry = New Query();
			vQry.Text = "SELECT
			            |	RoomQuotaSales.Room,
			            |	RoomQuotaSales.RoomType,
			            |	MIN(RoomQuotaSales.RoomsInQuotaClosingBalance) AS RoomsInQuotaClosingBalance,
			            |	MIN(RoomQuotaSales.BedsInQuotaClosingBalance) AS BedsInQuotaClosingBalance,
			            |	MIN(RoomQuotaSales.CounterClosingBalance)
			            |FROM
			            |	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
			            |			&qDateFrom,
			            |			&qDateTo,
			            |			Minute,
			            |			RegisterRecordsAndPeriodBoundaries, " + 
										?(ValueIsFilled(pHotel), "Hotel IN HIERARCHY (&qHotel)", "TRUE") + 
										?(ValueIsFilled(pRoomType), " AND RoomType IN HIERARCHY (&qRoomType)", "") + "
			            |				AND RoomQuota IN HIERARCHY (&qRoomQuota)) AS RoomQuotaSales
						|WHERE " + 
							?(ValueIsFilled(pCompany), "(RoomQuotaSales.RoomType.Company = &qCompany) OR (RoomQuotaSales.Room.Company = &qCompany) OR (RoomQuotaSales.RoomType.Company = &qEmptyCompany AND RoomQuotaSales.Room.Company = &qEmptyCompany)", "TRUE") + "
			            |
			            |GROUP BY
			            |	RoomQuotaSales.Room,
			            |	RoomQuotaSales.RoomType
			            |
			            |ORDER BY
			            |	RoomQuotaSales.Room.SortCode";
			vQry.SetParameter("qRoomQuota", pRoomQuota);
			vQry.SetParameter("qHotel", pHotel);
			vQry.SetParameter("qRoomType", pRoomType);
			vQry.SetParameter("qDateFrom", pDateFrom);
			vQry.SetParameter("qDateTo", New Boundary(pDateTo, BoundaryType.Excluding));
			vQry.SetParameter("qCompany", pCompany);
			vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
			vQryResults = vQry.Execute().Unload();
			For Each vQryResultsRow In vQryResults Do
				vRoomsInQuota.Add(vQryResultsRow.Room);
			EndDo;
		EndIf;
	EndIf;
	
	// Run query to get number of vacant rooms for room types
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomTypes.RoomType AS RoomType,
	|	RoomTypes.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomTypes.BedsVacant AS BedsVacant,
	|	RoomTypes.RoomsVacant AS RoomsVacant,
	|	RoomTypes.RoomType.Company AS Company
	|
	|FROM(
	|	SELECT
	|		RoomTypesBalance.RoomType AS RoomType,
	|		MAX(RoomTypesBalance.TotalBeds) AS TotalBeds,
	|		MAX(RoomTypesBalance.TotalRooms) AS TotalRooms,
	|		MAX(RoomTypesBalance.BedsVacant) AS BedsVacant,
	|		MAX(RoomTypesBalance.RoomsVacant) AS RoomsVacant
	|	FROM (
	|		SELECT
	|			RoomInventoryBalance.RoomType AS RoomType,
	|			MIN(RoomInventoryBalance.CounterClosingBalance) AS CounterClosingBalance,
	|			MIN(RoomInventoryBalance.TotalBedsClosingBalance) AS TotalBeds,
	|			MIN(RoomInventoryBalance.TotalRoomsClosingBalance) AS TotalRooms,
	|			MIN(RoomInventoryBalance.BedsVacantClosingBalance) AS BedsVacant,
	|			MIN(RoomInventoryBalance.RoomsVacantClosingBalance) AS RoomsVacant
	|		FROM
	|			AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qDateFrom, &qDateTo, 
	|		    	                                                   Second, 
	|		        	                                               RegisterRecordsAndPeriodBoundaries, " +
			        	                                               ?(ValueIsFilled(pHotel), "Hotel IN HIERARCHY (&qHotel)", "TRUE") + 
			        	                                               ?(ValueIsFilled(pRoomType), " AND RoomType IN HIERARCHY (&qRoomType)", "") + 
			        	                                               ?(vUseRoomQuota, " AND Room IN (&qRoomsInQuota)", "") + "
	|		) AS RoomInventoryBalance
	|		GROUP BY
	|			RoomInventoryBalance.RoomType
	|		UNION ALL
	|		SELECT
	|			RoomQuotaSalesBalance.RoomType AS RoomType,
	|			MIN(RoomQuotaSalesBalance.CounterClosingBalance),
	|			MIN(RoomQuotaSalesBalance.BedsInQuotaClosingBalance),
	|			MIN(RoomQuotaSalesBalance.RoomsInQuotaClosingBalance),
	|			MIN(RoomQuotaSalesBalance.BedsRemainsClosingBalance),
	|			MIN(RoomQuotaSalesBalance.RoomsRemainsClosingBalance)
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(&qDateFrom, &qDateTo, 
	|		    	                                                    Minute, 
	|		           	                                                RegisterRecordsAndPeriodBoundaries, &qUseRoomQuota" +
				                                                        ?(ValueIsFilled(pRoomQuota), " AND RoomQuota IN HIERARCHY(&qRoomQuota)", "") + 
			      	                                                    ?(ValueIsFilled(pHotel), " AND Hotel IN HIERARCHY (&qHotel)", "") + 
			        	                                                ?(ValueIsFilled(pRoomType), " AND RoomType IN HIERARCHY (&qRoomType)", "") + 
			        	                                                ?(vUseRoomQuota, " AND Room IN (&qRoomsInQuota)", "") + "
	|		) AS RoomQuotaSalesBalance
	|		GROUP BY
	|			RoomQuotaSalesBalance.RoomType
	|	) AS RoomTypesBalance
	|	WHERE
	|		RoomTypesBalance.RoomType.DeletionMark = FALSE 
	|	GROUP BY
	|		RoomTypesBalance.RoomType
	|	) AS RoomTypes
	|
	|WHERE " + 
		?(ValueIsFilled(pCompany), "(RoomTypes.RoomType.Company = &qCompany) OR (RoomTypes.RoomType.Company = &qEmptyCompany)", "TRUE") + "
	|
	|ORDER BY
	|	RoomTypeSortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qDateTo", New Boundary(pDateTo, BoundaryType.Excluding));
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qRoomQuota", pRoomQuota);
	vQry.SetParameter("qRoomsInQuota", vRoomsInQuota);
	vQry.SetParameter("qUseRoomQuota", ValueIsFilled(pRoomQuota));
	vQryResult = vQry.Execute();
	vRoomTypes = vQryResult.Unload();
	
	// Run query to get list of available rooms
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Rooms.Room AS Room,
	|	Rooms.Room.SortCode AS SortCode,
	|	Rooms.RoomType AS RoomType,
	|	Rooms.TotalBeds AS TotalBeds,
	|	Rooms.TotalRooms AS TotalRooms,
	|	Rooms.BedsVacant AS BedsVacant,
	|	Rooms.RoomsVacant AS RoomsVacant,
	|	Rooms.Room.Company AS Company
	|
	|FROM(
	|	
	|	SELECT
	|		RoomBalance.Room AS Room,
	|		RoomBalance.RoomType AS RoomType,
	|		MAX(RoomBalance.TotalBeds) AS TotalBeds,
	|		MAX(RoomBalance.TotalRooms) AS TotalRooms,
	|		MAX(RoomBalance.BedsVacant) AS BedsVacant,
	|		MAX(RoomBalance.RoomsVacant) AS RoomsVacant
	|	FROM (
	|		SELECT
	|			RoomInventoryBalance.Room AS Room,
	|			RoomInventoryBalance.RoomType AS RoomType,
	|			MIN(RoomInventoryBalance.CounterClosingBalance) AS CounterClosingBalance,
	|			MIN(RoomInventoryBalance.TotalBedsClosingBalance) AS TotalBeds,
	|			MIN(RoomInventoryBalance.TotalRoomsClosingBalance) AS TotalRooms,
	|			MIN(RoomInventoryBalance.BedsVacantClosingBalance) AS BedsVacant,
	|			MIN(RoomInventoryBalance.RoomsVacantClosingBalance) AS RoomsVacant
	|		FROM
	|			AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qDateFrom, &qDateTo, 
	|		    	                                                   Second, 
	|		        	                                               RegisterRecordsAndPeriodBoundaries, " +
			            	                                           ?(ValueIsFilled(pHotel), "Hotel IN HIERARCHY(&qHotel)", "TRUE") + 
			                	                                       ?(ValueIsFilled(pRoomType), " AND RoomType IN HIERARCHY(&qRoomType)", "") + 
			                    	                                   ?(vUseRoomQuota, " AND Room IN (&qRoomsInQuota)", "") + "
	|		) AS RoomInventoryBalance
	|		GROUP BY
	|			RoomInventoryBalance.Room,
	|			RoomInventoryBalance.RoomType 
	|		UNION ALL
	|		SELECT
	|			RoomQuotaSalesBalance.Room,
	|			RoomQuotaSalesBalance.RoomType,
	|			MIN(RoomQuotaSalesBalance.CounterClosingBalance),
	|			MIN(RoomQuotaSalesBalance.BedsInQuotaClosingBalance),
	|			MIN(RoomQuotaSalesBalance.RoomsInQuotaClosingBalance),
	|			MIN(RoomQuotaSalesBalance.BedsRemainsClosingBalance),
	|			MIN(RoomQuotaSalesBalance.RoomsRemainsClosingBalance)
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(&qDateFrom, &qDateTo, 
	|			                                                        Minute, 
	|			                                                        RegisterRecordsAndPeriodBoundaries, &qUseRoomQuota" +
				                                                        ?(ValueIsFilled(pRoomQuota), " AND RoomQuota IN HIERARCHY(&qRoomQuota)", "") + 
				                                                        ?(ValueIsFilled(pHotel), " AND Hotel IN HIERARCHY(&qHotel)", "") + 
				                                                        ?(ValueIsFilled(pRoomType), " AND RoomType IN HIERARCHY(&qRoomType)", "") + 
				                                                        ?(vUseRoomQuota, " AND Room IN (&qRoomsInQuota)", "") + "
	|		) AS RoomQuotaSalesBalance
	|		GROUP BY
	|			RoomQuotaSalesBalance.Room,
	|			RoomQuotaSalesBalance.RoomType 
	|	) AS RoomBalance
	|
	|	WHERE
	|		RoomBalance.Room.DeletionMark = FALSE" +
			?(pRoomStatus <> Undefined, " AND RoomBalance.Room.RoomStatus = &qRoomStatus", "") + "
	|
	|	GROUP BY
	|		RoomBalance.RoomType,
	|		RoomBalance.Room
	|	HAVING  
	|		MAX(RoomBalance.BedsVacant) >= &qNumberOfBeds 
	|	) AS Rooms
	|
	|WHERE " + 
		?(ValueIsFilled(pCompany), "(Rooms.RoomType.Company = &qCompany) OR (Rooms.Room.Company = &qCompany) OR (Rooms.RoomType.Company = &qEmptyCompany AND Rooms.Room.Company = &qEmptyCompany)", "TRUE") + "
	|
	|ORDER BY
	|	SortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qDateTo", New Boundary(pDateTo, BoundaryType.Excluding));
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qNumberOfBeds", pNumberOfBeds);
	vQry.SetParameter("qRoomQuota", pRoomQuota);
	vQry.SetParameter("qRoomsInQuota", vRoomsInQuota);
	vQry.SetParameter("qUseRoomQuota", ValueIsFilled(pRoomQuota));
	vQry.SetParameter("qRoomStatus", pRoomStatus);
	vQryResult = vQry.Execute();
	vRooms = vQryResult.Unload();
	
	// Get the value list of all vacant rooms
	vRoomsList = New ValueList();
	For Each vRoom In vRooms Do
		vCurRoom = vRoom.Room;
		If ValueIsFilled(vCurRoom) Then
			If vRoomsList.FindByValue(vCurRoom) = Undefined Then
				vRoomsList.Add(vCurRoom);
			EndIf;
		EndIf;
	EndDo;
	
	// Get the table of nearest dates when rooms became busy
	vQryReserv = New Query();
	vQryReserv.Text = 
	"SELECT
	|	RoomInventory.Room,
	|	MIN(RoomInventory.PeriodFrom) AS CheckInDate,
	|	RoomInventory.Room.SortCode AS SortCode
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Room IN(&qRooms)
	|	AND RoomInventory.RecordType = &qExpense
	|	AND RoomInventory.PeriodFrom >= &qDateTo
	|	AND RoomInventory.PeriodFrom < &qNextDateTo
	|	AND (RoomInventory.IsReservation OR RoomInventory.IsAccommodation)
	|GROUP BY
	|	RoomInventory.Room
	|ORDER BY
	|	SortCode";
	vQryReserv.SetParameter("qRooms", vRoomsList);
	vQryReserv.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQryReserv.SetParameter("qDateTo", pDateTo);
	vQryReserv.SetParameter("qNextDateTo", pDateTo + 7*24*3600); // Look only for 7 days in the future
	vReserves = vQryReserv.Execute().Unload();
	
	// Get table of nearest times when rooms became vacant
	vNumDays = 100;
	vQryVacant = New Query();
	vQryVacant.Text = 
	"SELECT
	|	RoomInventory.Room,
	|	MAX(RoomInventory.PeriodTo) AS CheckOutDate,
	|	RoomInventory.Room.SortCode AS SortCode
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Room IN(&qRooms)
	|	AND RoomInventory.RecordType = &qReceipt
	|	AND RoomInventory.PeriodTo <= &qDateFrom
	|	AND RoomInventory.PeriodTo > &qPrevDateFrom
	|	AND (RoomInventory.IsReservation OR RoomInventory.IsAccommodation)
	|GROUP BY
	|	RoomInventory.Room
	|ORDER BY
	|	SortCode";
	vQryVacant.SetParameter("qRooms", vRoomsList);
	vQryVacant.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vQryVacant.SetParameter("qDateFrom", pDateFrom);
	vQryVacant.SetParameter("qPrevDateFrom", pDateFrom - vNumDays*24*3600); // Look for 100 days in the past
	vVacants = vQryVacant.Execute().Unload();

	// Fill result table
	For Each vRoom In vRooms Do
		vCurRoomType = vRoom.RoomType;
		vCurRoom = vRoom.Room;
		
		// Ignore duplicated totals
		If Not ValueIsFilled(vCurRoom) Then
			Continue;
		Else
			If Not ValueIsFilled(vCurRoomType) Then
				Continue;
			EndIf;
		EndIf;
		If vRoomsArray.Find(vCurRoom) = Undefined Then
			vRoomsArray.Add(vCurRoom);
		Else
			Continue;
		EndIf;
		
		// Add new row
		vTableRow = vTableBoxRooms.Add();
		vRowIndex = vTableBoxRooms.IndexOf(vTableRow);
		
		// Fill main parameters
		vTableRow.Room = vCurRoom;
		vTableRow.RoomType = vCurRoomType;
		vTableRow.SortCode = vRoom.SortCode;
		vTableRow.BedsVacant = vRoom.BedsVacant;
		vTableRow.IsFolder = vCurRoom.IsFolder;
		vTableRow.Company = vCurRoom.Company;
		
		// Fill vacant from
		If Not vCurRoom.IsFolder Then
			If vTableRow.BedsVacant > 0 Then
				vRow = vVacants.Find(vCurRoom, "Room");
				If vRow <> Undefined Then
					vTableRow.VacantFrom = vRow.CheckOutDate;
				EndIf;
			EndIf;
		EndIf;
		
		// Fill vacant to
		If Not vCurRoom.IsFolder Then
			If vTableRow.BedsVacant > 0 Then
				vRow = vReserves.Find(vCurRoom, "Room");
				If vRow <> Undefined Then
					vTableRow.VacantTo = vRow.CheckInDate;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	Return vTableBoxRooms;
EndFunction // cmGetVacantRoomsList

// -----------------------------------------------------------------------------
// Description: Returns default vacant room for check-in
// Parameters: Number of vacant beds that room should have, Hotel, Company, 
//             Room quota, Room type, Room status, Period from date, Period to date
// Return value: Room
// -----------------------------------------------------------------------------
Function cmGetDefaultRoom(pNumberOfBeds, pHotel, pCompany, pRoomQuota, pRoomType, pDateFrom, pDateTo, pGuest) Export
	WriteLogEvent(NStr("en='Get default room';ru='Получить номер по умолчанию';de='Get default room'"), EventLogLevel.Information, , , 
	              NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + pHotel + Chars.LF + 
	              NStr("en='Company: ';ru='Фирма: ';de='Kompanie: '") + pCompany + Chars.LF + 
	              NStr("en='Allotment: ';ru='Квота: ';de='Allotment: '") + pRoomQuota + Chars.LF + 
	              NStr("en='Room type: ';ru='Тип номера: ';de='Zimmertyp: '") + pRoomType + Chars.LF + 
	              NStr("en='Number of beds: ';ru='Кол-во мест: ';de='Number of beds: '") + pNumberOfBeds + Chars.LF + 
	              NStr("en='Period from: ';ru='Период с: ';de='Period von: '") + pDateFrom + Chars.LF + 
	              NStr("en='Period to: ';ru='Период по: ';de='Period zu: '") + pDateTo); 
	
	vDftRoom = Catalogs.Rooms.EmptyRef();
	If Not ValueIsFilled(pHotel) Then
		Return vDftRoom;
	EndIf;
	
	// Get search default room policy
	vFillDefaultRoomPolicy = Enums.FillDefaultRoomPolicies.NoDefaultRoom;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
		If ValueIsFilled(vPermissionGroup) Then
			If ValueIsFilled(vPermissionGroup.FillDefaultRoomPolicy) Then
				vFillDefaultRoomPolicy = vPermissionGroup.FillDefaultRoomPolicy;
			EndIf;
		EndIf;
	EndIf;
	
	// Search default room if necessary
	WriteLogEvent(NStr("en='Get default room';ru='Получить номер по умолчанию';de='Get default room'"), EventLogLevel.Information, , , TrimAll(vFillDefaultRoomPolicy));
	If vFillDefaultRoomPolicy <> Enums.FillDefaultRoomPolicies.NoDefaultRoom Then
		// Fill room status filter
		vRoomStatus = Undefined;
		If BegOfDay(pDateFrom) <= BegOfDay(CurrentSessionDate()) Then
			vRoomStatus = pHotel.VacantRoomStatus;
		EndIf;
		// Get list of vacant rooms
		If vFillDefaultRoomPolicy = Enums.FillDefaultRoomPolicies.UseRoomFromGuestPreviousCheckin Then
			If ValueIsFilled(pGuest) Then
				vLastGuestAcc = cmGetClientLastAccommodation(pGuest, pHotel);
				If ValueIsFilled(vLastGuestAcc) Then
					vDftRoom = vLastGuestAcc.Room;
				EndIf;
			EndIf;
		ElsIf pNumberOfBeds > 0 Then
			vVacantRooms = cmGetVacantRoomsList(pNumberOfBeds, pHotel, pCompany, pRoomQuota, pRoomType, vRoomStatus, pDateFrom, pDateTo);
			If vVacantRooms.Count() = 0 Then
				WriteLogEvent(NStr("en='Get default room';ru='Получить номер по умолчанию';de='Get default room'"), EventLogLevel.Information, , , "No vacant rooms was found!");
			Else
				WriteLogEvent(NStr("en='Get default room';ru='Получить номер по умолчанию';de='Get default room'"), EventLogLevel.Information, , , "Vacant rooms count is " + vVacantRooms.Count());
			EndIf;
			If vFillDefaultRoomPolicy = Enums.FillDefaultRoomPolicies.UseMaximumCapacityPolicy Then
				// Try to find room with minimum period from last check-out date to current check-in date
				If vVacantRooms.Count() > 0 Then
					vVacantRooms.Sort("VacantFrom Desc, SortCode Desc");
					// We will use randomly one of first 5 most suitable rooms
					vRndGen = New RandomNumberGenerator(CurrentSessionDate() - '00010101');
					i = vRndGen.RandomNumber(0, Min(4, vVacantRooms.Count() - 1));
					vDftRoom = vVacantRooms.Get(i).Room;
				EndIf;
			ElsIf vFillDefaultRoomPolicy = Enums.FillDefaultRoomPolicies.UseBalancedCapacityPolicy Then
				// Try to find room with maximum period from last check-out date to current check-in date
				If vVacantRooms.Count() > 0 Then
					vVacantRooms.Sort("VacantFrom Asc, SortCode Desc");
					// We will use randomly one of first 5 most suitable rooms
					vRndGen = New RandomNumberGenerator(CurrentSessionDate() - '00010101');
					i = vRndGen.RandomNumber(0, Min(4, vVacantRooms.Count() - 1));
					vDftRoom = vVacantRooms.Get(i).Room;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Return room being found
	If ValueIsFilled(vFillDefaultRoomPolicy) Then
		WriteLogEvent(NStr("en='Get default room';ru='Получить номер по умолчанию';de='Get default room'"), EventLogLevel.Information, , , "Room found " + vDftRoom);
	EndIf;
	Return vDftRoom;
EndFunction // cmGetDefaultRoom

// -----------------------------------------------------------------------------
// Description: Returns client's last checked-out accommodation
// Parameters: Hotel, Guest 
// Return value: Accommodation document reference
// -----------------------------------------------------------------------------
Function cmGetClientLastAccommodation(pGuest, pHotel) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Hotel = &qHotel
	|	AND Accommodation.Guest = &qGuest
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsCheckOut
	|	AND NOT Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.AccommodationStatus.IsActive
	|
	|ORDER BY
	|	Accommodation.CheckOutDate DESC";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qGuest", pGuest);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		Return vDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetClientLastAccommodation

// -----------------------------------------------------------------------------
// Description: Returns list of vacant rooms for reservation
// Parameters: Number of vacant beds that room should have, Hotel, Company, 
//             Room quota, Room type, Period from date, Period to date
// Return value: Value table with vacant rooms
// -----------------------------------------------------------------------------
Function cmGetListOfVacantRoomsForReservation(pNumberOfBeds, pHotel, pCompany, pRoomQuota, pRoomType, pDateFrom, pDateTo) Export
	vRoomsList = New ValueList();
	If Not ValueIsFilled(pHotel) Then
		Return vRoomsList;
	EndIf;
	
	// Get search default room policy
	vFillDefaultRoomPolicy = Enums.FillDefaultRoomPolicies.NoDefaultRoom;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
		If ValueIsFilled(vPermissionGroup) Then
			If ValueIsFilled(vPermissionGroup.FillDefaultRoomPolicy) Then
				vFillDefaultRoomPolicy = vPermissionGroup.FillDefaultRoomPolicy;
			EndIf;
		EndIf;
	EndIf;
	
	// Get list of vacant rooms
	If pNumberOfBeds > 0 Then
		// Get list of vacant rooms
		vRoomsList = cmGetVacantRoomsList(pNumberOfBeds, pHotel, pCompany, pRoomQuota, pRoomType, Undefined, pDateFrom, pDateTo);
	
		// Sort rooms according to the default room search policy
		If vFillDefaultRoomPolicy = Enums.FillDefaultRoomPolicies.NoDefaultRoom Then
			// Try to find rooms with minimum period from last check-out date to current expected check-in date
			If vRoomsList.Count() > 0 Then
				vRoomsList.Sort("SortCode");
			EndIf;
		ElsIf vFillDefaultRoomPolicy = Enums.FillDefaultRoomPolicies.UseMaximumCapacityPolicy Then
			// Try to find rooms with minimum period from last check-out date to current expected check-in date
			If vRoomsList.Count() > 0 Then
				vRoomsList.Sort("VacantFrom Desc, SortCode");
			EndIf;
		ElsIf vFillDefaultRoomPolicy = Enums.FillDefaultRoomPolicies.UseBalancedCapacityPolicy Then
			// Try to find room with maximum period from last check-out date to current expected check-in date
			If vRoomsList.Count() > 0 Then
				vRoomsList.Sort("VacantFrom Asc, SortCode Desc");
			EndIf;
		EndIf;
	EndIf;
	
	// Return list of vacant rooms
	Return vRoomsList;
EndFunction // cmGetListOfVacantRoomsForReservation

// -----------------------------------------------------------------------------
// Description: Checks accommodation for the suspicious events and writes them 
//              to the system log file
// Parameters: Document object (Accommodation or Reservation)
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmWriteSuspiciousAccommodationEvents(pDocObj) Export
	// Try to read last record from document change history
	vLastDocAttrs = pDocObj.pmGetAccommodationAttributes();
	If vLastDocAttrs.Count() > 0 Then
		vLastDocAttrsRow = vLastDocAttrs.Get(0);
		
		// Compare customer and write event if changed
		If vLastDocAttrsRow.Customer <> pDocObj.Customer Then
			vEventDescription = StrTemplate(NStr("en = 'Customer change: %1 -> %2'; de = 'Kundenwechsel: %1 -> %2'; ru = 'Изменение контрагента: %1 -> %2'"), TrimAll(vLastDocAttrsRow.Customer), TrimAll(pDocObj.Customer));    
			// User activity history    
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(pDocObj.Ref, vEventDescription, pDocObj.Hotel);
		EndIf;
		
		// Compare agent and write event if changed
		If vLastDocAttrsRow.Agent <> pDocObj.Agent Then
			vEventDescription = StrTemplate(NStr("en = 'Agent change: %1 -> %2'; de = 'Agentenwechsel: %1 -> %2'; ru = 'Изменение агента: %1 -> %2'"), TrimAll(vLastDocAttrsRow.Agent), TrimAll(pDocObj.Agent));    
			// User activity history    
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(pDocObj.Ref, vEventDescription, pDocObj.Hotel);
		EndIf;
		
		// Compare room and write event if changed
		If vLastDocAttrsRow.Room <> pDocObj.Room Then
			vEventDescription = StrTemplate(NStr("en = 'Room change: %1 -> %2'; de = 'Zimmerwechsel: %1 -> %2'; ru = 'Изменение номера: %1 -> %2'"), TrimAll(vLastDocAttrsRow.Room), TrimAll(pDocObj.Room));    
			// User activity history    
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(pDocObj.Ref, vEventDescription, pDocObj.Hotel);
		EndIf;
		
		// Write event if accommodation was canceled
		If ValueIsFilled(vLastDocAttrsRow.AccommodationStatus) And ValueIsFilled(pDocObj.AccommodationStatus) And 
		   vLastDocAttrsRow.AccommodationStatus.IsActive And Not pDocObj.AccommodationStatus.IsActive Then
			vEventDescription = StrTemplate(NStr("en = 'Cancel accommodation: %1 -> %2'; de = 'Unterkunft stornieren: %1 -> %2'; ru = 'Отмена размещения: %1 -> %2'"), TrimAll(vLastDocAttrsRow.AccommodationStatus), TrimAll(pDocObj.AccommodationStatus));    
			// User activity history    
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(pDocObj.Ref, vEventDescription, pDocObj.Hotel);
		EndIf;
		
		// Write event if late check-out
		If ValueIsFilled(vLastDocAttrsRow.AccommodationStatus) And ValueIsFilled(pDocObj.AccommodationStatus) And 
		   vLastDocAttrsRow.AccommodationStatus.IsInHouse And Not pDocObj.AccommodationStatus.IsInHouse And 
		   pDocObj.AccommodationStatus.IsCheckOut And pDocObj.AccommodationStatus.IsActive Then
			If (CurrentSessionDate() - pDocObj.CheckOutDate) > 2 * 3600 Then
				vEventDescription = NStr("en='Late check-out: " + Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pDocObj.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + " = " + Format(Round((CurrentSessionDate() - pDocObj.CheckOutDate) / 3600, 1), "ND=10; NFD=1; NZ=; NG=") + "h.'; 
				                         |de='Late check-out: " + Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pDocObj.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + " = " + Format(Round((CurrentSessionDate() - pDocObj.CheckOutDate) / 3600, 1), "ND=10; NFD=1; NZ=; NG=") + "h.'; 
				                         |ru='Позднее выселение: " + Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pDocObj.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + " = " + Format(Round((CurrentSessionDate() - pDocObj.CheckOutDate) / 3600, 1), "ND=10; NFD=1; NZ=; NG=") + "ч.'");
				// User activity history    
				InformationRegisters.UserActionsHistory.WriteUserActivityRecord(pDocObj.Ref, vEventDescription, pDocObj.Hotel);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // cmWriteSuspiciousAccommodationEvents

// -----------------------------------------------------------------------------
// Description: Checks if document has master charging rules
// Parameters: Document reference
// Return value: True if document has master charging rules, false if not
// -----------------------------------------------------------------------------
Function cmCheckMasterChargingRulesArePresent(pDoc) Export
	// Check if there are already master charging rules
	vMasterChargingRulesFound = False;
	vMasterChargingRules = pDoc.ChargingRules.FindRows(New Structure("IsMaster", True));
	For Each vMasterChargingRulesRow In vMasterChargingRules Do
		If ValueIsFilled(vMasterChargingRulesRow.Owner) Then
			If TypeOf(vMasterChargingRulesRow.Owner) = Type("DocumentRef.Reservation") Or 
			   TypeOf(vMasterChargingRulesRow.Owner) = Type("DocumentRef.Accommodation") Then
				vMasterChargingRulesFound = True;
				Break;
			EndIf;
		EndIf;
	EndDo;
	Return vMasterChargingRulesFound;
EndFunction // cmCheckMasterChargingRulesArePresent 

// -----------------------------------------------------------------------------
// Description: Returns list of room interface status documents for the given room
// Parameters: Room, Period from date, Period to date
// Return value: Value table with room interface status documents
// -----------------------------------------------------------------------------
Function cmGetRoomInterfaceStatuses(pRoom, pPeriodFrom, pPeriodTo = Undefined, pParentDoc = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInterfaceStatus.Ref AS Ref,
	|	RoomInterfaceStatus.Hotel AS Hotel,
	|	RoomInterfaceStatus.Room AS Room,
	|	RoomInterfaceStatus.InterfaceType AS InterfaceType,
	|	RoomInterfaceStatus.RoomInterfaceType AS RoomInterfaceType,
	|	RoomInterfaceStatus.RoomInterfaceType.ApplyToAllRoomGuests AS ApplyToAllRoomGuests,
	|	RoomInterfaceStatus.RoomInterfaceType.TurnOffParameters AS TurnOffParameters,
	|	RoomInterfaceStatus.Remarks AS Remarks,
	|	RoomInterfaceStatus.IsProcessed AS IsProcessed,
	|	RoomInterfaceStatus.IsCanceled AS IsCanceled,
	|	RoomInterfaceStatus.MessageDateTime AS MessageDateTime,
	|	RoomInterfaceStatus.MessageIsDelivered AS MessageIsDelivered,
	|	RoomInterfaceStatus.MessageDeliveryDateTime AS MessageDeliveryDateTime,
	|	RoomInterfaceStatus.Number AS Number,
	|	RoomInterfaceStatus.Date AS Date,
	|	RoomInterfaceStatus.ParentDoc AS ParentDoc,
	|	RoomInterfaceStatus.Author AS Author,
	|	RoomInterfaceStatus.CancellationAuthor AS CancellationAuthor,
	|	RoomInterfaceStatus.CancellationDate AS CancellationDate,
	|	RoomInterfaceStatus.RoomInterfaceType.PeriodOfStayExtentionParameters AS PeriodOfStayExtentionParameters,
	|	RoomInterfaceStatus.RoomInterfaceType.GuestNameChangeParameters AS GuestNameChangeParameters,
	|	RoomInterfaceStatus.RoomInterfaceType.RoomChangeParameters AS RoomChangeParameters,
	|	RoomInterfaceStatus.RoomInterfaceType.CommandToChangeExtraParameters AS CommandToChangeExtraParameters,
	|	RoomInterfaceStatus.PeriodOfStayExtensionIsRequested AS PeriodOfStayExtensionIsRequested,
	|	RoomInterfaceStatus.GuestNameChangeIsRequested AS GuestNameChangeIsRequested,
	|	RoomInterfaceStatus.RoomChangeIsRequested AS RoomChangeIsRequested,
	|	RoomInterfaceStatus.ExtraParametersChangeIsRequested AS ExtraParametersChangeIsRequested
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|WHERE
	|	RoomInterfaceStatus.Room = &qRoom
	|	AND RoomInterfaceStatus.Date >= &qPeriodFrom
	|	AND (RoomInterfaceStatus.Date < &qPeriodTo
	|			OR &qPeriodToIsEmpty)
	|	AND (RoomInterfaceStatus.ParentDoc = &qParentDoc
	|				AND &qParentDocIsFilled
	|			OR NOT &qParentDocIsFilled)
	|	AND NOT RoomInterfaceStatus.DeletionMark
	|
	|ORDER BY
	|	RoomInterfaceStatus.PointInTime";
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qPeriodToIsEmpty", Not ValueIsFilled(pPeriodTo));
	vQry.SetParameter("qParentDoc", pParentDoc);
	vQry.SetParameter("qParentDocIsFilled", ValueIsFilled(pParentDoc));
	Return vQry.Execute().Unload();
EndFunction // cmGetRoomInterfaceStatuses

// -----------------------------------------------------------------------------
// Description: Returns number of hours allowed for a guest to examine a room 
//              without a charge
// Parameters: None
// Return value: Number of hours allowed
// -----------------------------------------------------------------------------
Function cmGetRoomExaminationFreeOfChargeTime() Export
	vHrs = 0;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vCurUsr = SessionParameters.CurrentUser;
		If ValueIsFilled(vCurUsr) Then
			vCurUsrPermGrp = cmGetEmployeePermissionGroup(vCurUsr);
			If ValueIsFilled(vCurUsrPermGrp) Then
				vHrs = vCurUsrPermGrp.RoomExaminationFreeOfChargeTime;
			EndIf;
		EndIf;
	EndIf;
	Return vHrs;
EndFunction // cmGetRoomExaminationFreeOfChargeTime

// -----------------------------------------------------------------------------
// Description: Returns value table with reservation services
// Parameters: Reservation reference
// Return value: Value table with services
// -----------------------------------------------------------------------------
Function cmGetReservationServices(pResRef) Export
	// Unload document services
	i = 0;
	vServices = pResRef.Services.Unload();
	While i < vServices.Count() Do
		vSrvRow = vServices.Get(i);
		vSrvRowFolio = vSrvRow.Folio;
		vResRefReservationStatus = pResRef.ReservationStatus;
		If Not pResRef.DoCharging And ValueIsFilled(vResRefReservationStatus) And Not vResRefReservationStatus.IsCheckIn And (vResRefReservationStatus.IsActive Or vResRefReservationStatus.IsPreliminary) And 
		   ValueIsFilled(vSrvRowFolio) And ValueIsFilled(vSrvRowFolio.PaymentMethod) And vSrvRowFolio.PaymentMethod.ChargeServicesInAdvance Then
			vServices.Delete(i);
		ElsIf pResRef.DoCharging And ValueIsFilled(vResRefReservationStatus) And vResRefReservationStatus.AlwaysChargeInAdvanceServicesOnly And Not vSrvRow.Service.AlwaysChargeInAdvance Then
			i = i + 1;
		ElsIf pResRef.DoCharging Then
			vServices.Delete(i);
		ElsIf ValueIsFilled(pResRef.DoChargingToDate) And vSrvRow.AccountingDate <= pResRef.DoChargingToDate Then
			vServices.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	
	// Get reservation charges for the folios
	vCharges = cmGetDocumentCharges(pResRef, pResRef.Customer, pResRef.Contract, pResRef.Hotel, Undefined, True);
	For Each vChargesRow In vCharges Do
		vSrvRow = vServices.Add();
		FillPropertyValues(vSrvRow, vChargesRow);
		vSrvRow.Sum = vSrvRow.Sum + vSrvRow.DiscountSum;
	EndDo;
	
	// Update room type if necessary
	vRoomTypeToPrint = pResRef.RoomType;
	If ValueIsFilled(vRoomTypeToPrint) And ValueIsFilled(pResRef.RoomTypeUpgrade) And pResRef.RoomTypeUpgrade.BaseRoomType = vRoomTypeToPrint Then
		vRoomTypeToPrint = pResRef.RoomTypeUpgrade;
		For Each vSrvRow In vServices Do
			If vSrvRow.RoomType = pResRef.RoomType Then
				vSrvRow.RoomType = vRoomTypeToPrint;
			EndIf;
		EndDo;
	EndIf;
	
	// Return value table
	Return vServices;
EndFunction // cmGetReservationServices

// -----------------------------------------------------------------------------
// Returns value table with services for all room reservations
// -----------------------------------------------------------------------------
Function cmGetReservationRoomServices(pResRef) Export
	If ValueIsFilled(pResRef.AccommodationType) And pResRef.AccommodationType.Type = Enums.AccomodationTypes.Room Then
		vServices = cmGetReservationServices(pResRef);
		vOneRoomReservations = cmGetOneRoomReservations(pResRef.Number, pResRef.GuestGroup, pResRef.CheckInDate, pResRef.CheckOutDate);
		For Each vResRow In vOneRoomReservations Do
			vResRef = vResRow.Ref;
			If vResRef <> pResRef Then
				vAddServices = cmGetReservationServices(vResRef);
				For Each vAddServicesRow In vAddServices Do
					If vAddServicesRow.IsInPrice Then
						vSrvRow = vServices.Add();
						FillPropertyValues(vSrvRow, vAddServicesRow); 
						vSrvRow.Quantity = 0;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		Return vServices;
	ElsIf ValueIsFilled(pResRef.AccommodationType) And pResRef.AccommodationType.Type = Enums.AccomodationTypes.Beds Then
		Return cmGetReservationServices(pResRef);
	Else
		vServices = cmGetReservationServices(pResRef);
		vOneRoomReservations = cmGetOneRoomReservations(pResRef.Number, pResRef.GuestGroup, pResRef.CheckInDate, pResRef.CheckOutDate);
		If vOneRoomReservations.Count() > 1 Then
			vMainRoomDoc = vOneRoomReservations.Get(0).Ref;
			If vMainRoomDoc.RoomQuantity = 1 Then
				For Each vServicesRow In vServices Do
					If vServicesRow.IsInPrice Then
						vServicesRow.Price = 0;
						vServicesRow.Sum = 0;
						vServicesRow.DiscountSum = 0;
						vServicesRow.VATSum = 0;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		Return vServices;
	EndIf;
EndFunction // cmGetReservationRoomServices

// -----------------------------------------------------------------------------
// Description: Returns string to be used to sort selected accommodations or reservations
// Parameters: Reservation or accommodation reference
// Return value: String
// -----------------------------------------------------------------------------
Function cmBuildAccommodationSortingPresentation(pDoc) Export
	vStr = "";
	If ValueIsFilled(pDoc.Room) Then
		vStr = vStr + Format(pDoc.Room.SortCode, "ND=8; NFD=0; NZ=; NLZ=; NG=");
	Else
		vStr = vStr + Format(0, "ND=8; NFD=0; NZ=; NLZ=; NG=");
	EndIf;
	If ValueIsFilled(pDoc.RoomType) Then
		vStr = vStr + Format(pDoc.RoomType.SortCode, "ND=8; NFD=0; NZ=; NLZ=; NG=");
	Else
		vStr = vStr + Format(0, "ND=8; NFD=0; NZ=; NLZ=; NG=");
	EndIf;
	If Not IsBlankString(pDoc.Number) Then
		vStr = vStr + pDoc.Number;
	Else
		vStr = vStr + "            ";
	EndIf;
	If ValueIsFilled(pDoc.Date) Then
		vStr = vStr + Format(pDoc.Date, "DF=yyyyMMddHHmmss");
	Else
		vStr = vStr + "              ";
	EndIf;
	If ValueIsFilled(pDoc.AccommodationType) Then
		vStr = vStr + Format(pDoc.AccommodationType.SortCode, "ND=4; NFD=0; NZ=; NLZ=; NG=");
	Else
		vStr = vStr + Format(0, "ND=4; NFD=0; NZ=; NLZ=; NG=");
	EndIf;
	If ValueIsFilled(pDoc.CheckInDate) Then
		vStr = vStr + Format(pDoc.CheckInDate, "DF=yyyyMMddHHmmss");
	Else
		vStr = vStr + "              ";
	EndIf;
	vStr = vStr + String(pDoc.PointInTime());
	Return vStr;
EndFunction // cmBuildAccommodationSortingPresentation

// -----------------------------------------------------------------------------
// Description: Returns first available "together" accommodation type
// Parameters: None
// Return value: Reference to the "Accommodation types" catalog item
// -----------------------------------------------------------------------------
Function cmGetTogetherAccommodationType() Export
	vTogether = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccommodationTypes.Ref
	|FROM
	|	Catalog.AccommodationTypes AS AccommodationTypes
	|WHERE
	|	(NOT AccommodationTypes.DeletionMark)
	|	AND (NOT AccommodationTypes.IsFolder)
	|	AND AccommodationTypes.Type = &qTogether
	|
	|ORDER BY
	|	AccommodationTypes.SortCode,
	|	AccommodationTypes.Description";
	vQry.SetParameter("qTogether", Enums.AccomodationTypes.Together);
	vTypes = vQry.Execute().Unload();
	If vTypes.Count() > 0 Then
		vTogether = vTypes.Get(0).Ref;
	EndIf;
	Return vTogether;
EndFunction // cmGetTogetherAccommodationType 

// -----------------------------------------------------------------------------
// Description: Returns starting date and time for key card to open door lock
// Parameters: Guest check-in date and time
// Return value: Date and time to start opening door lock
// -----------------------------------------------------------------------------
Function cmGetKeyCardCheckInTime(pCheckInDate, pIsReservation = False) Export
	vCheckInDate = pCheckInDate;
	If BegOfDay(CurrentSessionDate()) = BegOfDay(pCheckInDate) And CurrentSessionDate() < pCheckInDate Then
		If Not pIsReservation Then
			vCheckInDate = CurrentSessionDate();
		EndIf;
	ElsIf BegOfDay(CurrentSessionDate()) > BegOfDay(pCheckInDate) Then
		vCheckInDate = CurrentSessionDate();
	ElsIf Not pIsReservation Then
		vCheckInDate = CurrentSessionDate();
	EndIf;
	Return vCheckInDate;
EndFunction // cmGetKeyCardCheckInTime

// -----------------------------------------------------------------------------
// Description: Returns guest group status according to the guest group document statuses
// Parameters: Guest group catalog item reference
// Return value: Guest group status reference
// -----------------------------------------------------------------------------
Function cmGetGuestGroupStatus(pGuestGroup) Export
	vGroupStatus = Undefined;
	If ValueIsFilled(pGuestGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT TOP 1
		|	GroupDocuments.Status AS Status,
		|	GroupDocuments.Order AS Order,
		|	GroupDocuments.SortCode AS SortCode
		|FROM
		|	(SELECT
		|		Reservation.ReservationStatus AS Status,
		|		CASE
		|			WHEN Reservation.ReservationStatus.IsPreliminary
		|				THEN 1
		|			WHEN Reservation.ReservationStatus.IsActive
		|				THEN 2
		|			WHEN Reservation.ReservationStatus.IsNoShow
		|				THEN 13
		|			WHEN Reservation.ReservationStatus.IsCheckIn
		|				THEN 12
		|			WHEN Reservation.ReservationStatus.IsAnnulation
		|				THEN 15
		|			ELSE 90
		|		END AS Order,
		|		Reservation.ReservationStatus.SortCode AS SortCode
		|	FROM
		|		Document.Reservation AS Reservation
		|	WHERE
		|		Reservation.Posted
		|		AND Reservation.GuestGroup = &qGuestGroup
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ResourceReservation.ResourceReservationStatus,
		|		CASE
		|			WHEN ResourceReservation.ResourceReservationStatus.ServicesAreDelivered
		|				THEN 55
		|			WHEN NOT ResourceReservation.ResourceReservationStatus.IsActive
		|				THEN 99
		|			ELSE 50
		|		END,
		|		ResourceReservation.ResourceReservationStatus.SortCode
		|	FROM
		|		Document.ResourceReservation AS ResourceReservation
		|	WHERE
		|		ResourceReservation.Posted
		|		AND ResourceReservation.GuestGroup = &qGuestGroup
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CASE
		|			WHEN Accommodation.AccommodationStatus.IsActive
		|					AND Accommodation.AccommodationStatus.IsInHouse
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.CheckInAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.ChangeRoomAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.CheckOutAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.CheckInAndMoveAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.MoveAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.MoveAndCheckOutAccommodationStatus
		|				THEN Accommodation.AccommodationStatus
		|			WHEN Accommodation.AccommodationStatus.IsActive
		|					AND Accommodation.AccommodationStatus.IsInHouse
		|				THEN &qCheckInStatus
		|			WHEN Accommodation.AccommodationStatus.IsActive
		|					AND NOT Accommodation.AccommodationStatus.IsInHouse
		|				THEN &qCheckOutAccommodationStatus
		|		END,
		|		CASE
		|			WHEN Accommodation.AccommodationStatus.IsActive
		|					AND Accommodation.AccommodationStatus.IsInHouse
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.CheckInAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.ChangeRoomAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.CheckOutAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.CheckInAndMoveAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.MoveAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.MoveAndCheckOutAccommodationStatus
		|				THEN 8
		|			WHEN Accommodation.AccommodationStatus.IsActive
		|					AND Accommodation.AccommodationStatus.IsInHouse
		|				THEN 9
		|			WHEN Accommodation.AccommodationStatus.IsActive
		|					AND NOT Accommodation.AccommodationStatus.IsInHouse
		|				THEN 11
		|			ELSE 95
		|		END,
		|		CASE
		|			WHEN Accommodation.AccommodationStatus.IsActive
		|					AND Accommodation.AccommodationStatus.IsInHouse
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.CheckInAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.ChangeRoomAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.CheckOutAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.CheckInAndMoveAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.MoveAccommodationStatus
		|					AND Accommodation.AccommodationStatus <> Accommodation.Hotel.MoveAndCheckOutAccommodationStatus
		|				THEN &qCheckInStatusSortCode
		|			WHEN Accommodation.AccommodationStatus.IsActive
		|					AND Accommodation.AccommodationStatus.IsInHouse
		|				THEN &qCheckInStatusSortCode
		|			WHEN Accommodation.AccommodationStatus.IsActive
		|					AND NOT Accommodation.AccommodationStatus.IsInHouse
		|				THEN &qCheckOutAccommodationStatusSortCode
		|		END
		|	FROM
		|		Document.Accommodation AS Accommodation
		|	WHERE
		|		Accommodation.Posted
		|		AND Accommodation.AccommodationStatus.IsActive
		|		AND Accommodation.GuestGroup = &qGuestGroup) AS GroupDocuments
		|
		|ORDER BY
		|	Order,
		|	SortCode";
		vQry.SetParameter("qGuestGroup", pGuestGroup);
		vQry.SetParameter("qCheckInStatus", pGuestGroup.Owner.CheckInReservationStatus);
		vQry.SetParameter("qCheckInStatusSortCode", ?(ValueIsFilled(pGuestGroup.Owner.CheckInReservationStatus), pGuestGroup.Owner.CheckInReservationStatus.SortCode, 0));
		vQry.SetParameter("qCheckOutAccommodationStatus", pGuestGroup.Owner.CheckOutAccommodationStatus);
		vQry.SetParameter("qCheckOutAccommodationStatusSortCode", ?(ValueIsFilled(pGuestGroup.Owner.CheckOutAccommodationStatus), pGuestGroup.Owner.CheckOutAccommodationStatus.SortCode, 0));
		vQryRes = vQry.Execute().Unload();
		If vQryRes.Count() > 0 Then
			vGroupStatus = vQryRes.Get(0).Status;
		EndIf;
	EndIf;
	Return vGroupStatus;
EndFunction // cmGetGuestGroupStatus

// -----------------------------------------------------------------------------
// Description: Returns value list of guest group statuses that are interesting 
//              to the sales manager
// Parameters: None
// Return value: Value list of group status references
// -----------------------------------------------------------------------------
Function cmGetSalesGuestGroupStatuses() Export
	vStatusesList = New ValueList();
	// Build list of active or preliminary group statuses
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReservationStatuses.Ref AS Ref,
	|	ReservationStatuses.SortCode AS SortCode,
	|	ReservationStatuses.Description AS Description
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	(NOT ReservationStatuses.DeletionMark)
	|	AND (NOT ReservationStatuses.IsFolder)
	|	AND (ReservationStatuses.IsActive
	|			OR ReservationStatuses.IsPreliminary)
	|
	|UNION ALL
	|
	|SELECT
	|	ResourceReservationStatuses.Ref,
	|	ResourceReservationStatuses.SortCode,
	|	ResourceReservationStatuses.Description
	|FROM
	|	Catalog.ResourceReservationStatuses AS ResourceReservationStatuses
	|WHERE
	|	(NOT ResourceReservationStatuses.DeletionMark)
	|	AND (NOT ResourceReservationStatuses.IsFolder)
	|	AND ResourceReservationStatuses.IsActive
	|	AND (NOT ResourceReservationStatuses.ServicesAreDelivered)
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vStatuses = vQry.Execute().Unload();
	For Each vStatusesRow In vStatuses Do
		vStatusesList.Add(vStatusesRow.Ref);
	EndDo;
	Return vStatusesList;
EndFunction // cmGetSalesGuestGroupStatuses

// -----------------------------------------------------------------------------
// Description: Returns value list of events that are not marked for deletion and
//              with periods intersecting with period requested
// Parameters: Period starting date, Period ending date, Hotel (could be empty)
// Return value: Value table with events
// -----------------------------------------------------------------------------
Function cmGetEvents(pPeriodFrom, pPeriodTo, pHotel) Export
	// Build and run query to get events
	vEventsQry = New Query();
	vEventsQry.Text = 
	"SELECT
	|	Events.Ref AS Ref,
	|	Events.Code AS Code,
	|	Events.Description AS Description,
	|	CASE
	|		WHEN Events.DateFrom < &qDateFrom
	|			THEN &qDateFrom
	|		ELSE Events.DateFrom
	|	END AS DateFrom,
	|	CASE
	|		WHEN Events.DateTo > &qDateTo
	|			THEN &qDateTo
	|		ELSE Events.DateTo
	|	END AS DateTo,
	|	Events.Remarks AS Remarks,
	|	Events.Hotel AS Hotel,
	|	Events.Color AS Color
	|FROM
	|	Catalog.Events AS Events
	|WHERE
	|	NOT Events.DeletionMark
	|	AND (Events.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty
	|			OR Events.Hotel = &qEmptyHotel)
	|	AND Events.DateFrom <= &qDateTo
	|	AND Events.DateTo >= &qDateFrom
	|	AND NOT Events.DoNotShowInRoomsGanttChart
	|
	|ORDER BY
	|	DateFrom,
	|	Description";
	vEventsQry.SetParameter("qHotel", pHotel);
	vEventsQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vEventsQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vEventsQry.SetParameter("qDateFrom", BegOfDay(pPeriodFrom));
	vEventsQry.SetParameter("qDateTo", BegOfDay(pPeriodTo));
	vEvents = vEventsQry.Execute().Unload();
	Return vEvents;
EndFunction //  cmGetEvents

// -----------------------------------------------------------------------------
//  Room phone numbers
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels, ValueTable - CatalogRef.Hotels - Phone numbers of the hotel selected
// 
// Returns:
//   - ValueTable - list events
//
Function cmGetPhoneNumbers(pHotel) Export
	// Build and run query to get events
	vPhonesQry = New Query();
	vPhonesQry.Text = 
	"SELECT
	|	Phones.PhoneNumber AS PhoneNumber,
	|	Phones.Room AS Room
	|FROM
	|	Catalog.PhoneNumbers AS Phones
	|WHERE
	|	NOT Phones.DeletionMark
	|	AND NOT Phones.IsFolder
	|	AND (Phones.Owner IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty
	|			OR Phones.Owner = &qEmptyHotel)
	|
	|ORDER BY
	|	PhoneNumber";
	vPhonesQry.SetParameter("qHotel", pHotel);
	vPhonesQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vPhonesQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vPhones = vPhonesQry.Execute().Unload();
	Return vPhones;
EndFunction // cmGetPhoneNumbers

// -----------------------------------------------------------------------------
// Description: Returns value list of accommodation templates valid for then
//              room type given
// Parameters: Room type reference
// Return value: Value list with accommodation templates
// -----------------------------------------------------------------------------
Function cmGetAccommodationTemplatesValidForRoomType(pRoomType = Undefined, pNumberOfPersons = 0) Export
	vAccTmplates = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccommodationTemplates.Ref
	|FROM
	|	Catalog.AccommodationTemplates AS AccommodationTemplates
	|WHERE
	|	(NOT AccommodationTemplates.DeletionMark)
	|
	|ORDER BY
	|	AccommodationTemplates.Code";
	vAccTmplatesRows = vQry.Execute().Unload();
	For Each vAccTmplatesRow In vAccTmplatesRows Do
		vAccTemplateRef = vAccTmplatesRow.Ref;
		If vAccTemplateRef.RoomTypes.Count() = 0 Or Not ValueIsFilled(pRoomType) Then
			If ValueIsFilled(pRoomType) Then
				If ValueIsFilled(vAccTemplateRef.Hotel) Then
					If vAccTemplateRef.Hotel = pRoomType.Owner Then
						If pNumberOfPersons = 0 Then
							vAccTmplates.Add(vAccTemplateRef);
						ElsIf vAccTemplateRef.AccommodationTypes.Count() = pNumberOfPersons Then
							vAccTmplates.Add(vAccTemplateRef);
						EndIf;							
					EndIf;
				Else
					If pNumberOfPersons = 0 Then
						vAccTmplates.Add(vAccTemplateRef);
					ElsIf vAccTemplateRef.AccommodationTypes.Count() = pNumberOfPersons Then
						vAccTmplates.Add(vAccTemplateRef);
					EndIf;							
				EndIf;
			Else
				If pNumberOfPersons = 0 Then
					vAccTmplates.Add(vAccTemplateRef);
				ElsIf vAccTemplateRef.AccommodationTypes.Count() = pNumberOfPersons Then
					vAccTmplates.Add(vAccTemplateRef);
				EndIf;							
			EndIf;
		Else
			If vAccTemplateRef.RoomTypes.Find(pRoomType, "RoomType") <> Undefined Then
				If pNumberOfPersons = 0 Then
					vAccTmplates.Add(vAccTemplateRef);
				ElsIf vAccTemplateRef.AccommodationTypes.Count() = pNumberOfPersons Then
					vAccTmplates.Add(vAccTemplateRef);
				EndIf;
			ElsIf ValueIsFilled(pRoomType) And Not pRoomType.IsFolder And ValueIsFilled(pRoomType.RoomClass) And 
			      vAccTemplateRef.RoomTypes.Find(pRoomType.RoomClass, "RoomClass") <> Undefined Then
				If pNumberOfPersons = 0 Then
					vAccTmplates.Add(vAccTemplateRef);
				ElsIf vAccTemplateRef.AccommodationTypes.Count() = pNumberOfPersons Then
					vAccTmplates.Add(vAccTemplateRef);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	Return vAccTmplates;
EndFunction // cmGetAccommodationTemplatesValidForRoomType

// -----------------------------------------------------------------------------
// Description: Checks if accommodation period starts and ends on the same dates 
//              as check-in periods for the allotment given
// Parameters: Hotel item reference, allotment item reference, 
//             check-in date, check-out date
// Return value: True if check is OK, False if not
// -----------------------------------------------------------------------------
Function cmCheckCheckInPeriods(pHotel, pRoomQuota, pCheckInDate, pCheckOutDate) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRateCheckInPeriods.Hotel,
	|	RoomRateCheckInPeriods.RoomQuota,
	|	RoomRateCheckInPeriods.CheckInDate,
	|	RoomRateCheckInPeriods.Duration,
	|	RoomRateCheckInPeriods.CheckOutDate
	|FROM
	|	InformationRegister.RoomQuotaCheckInPeriods AS RoomRateCheckInPeriods
	|WHERE
	|	RoomRateCheckInPeriods.Hotel = &qHotel
	|	AND RoomRateCheckInPeriods.RoomQuota = &qRoomQuota
	|	AND (BEGINOFPERIOD(RoomRateCheckInPeriods.CheckInDate, DAY) = &qCheckInDate
	|			OR BEGINOFPERIOD(RoomRateCheckInPeriods.CheckOutDate, DAY) = &qCheckOutDate)
	|	AND (NOT RoomRateCheckInPeriods.IsNotActive)";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomQuota", pRoomQuota);
	vQry.SetParameter("qCheckInDate", BegOfDay(pCheckInDate));
	vQry.SetParameter("qCheckOutDate", BegOfDay(pCheckOutDate));
	vPeriods = vQry.Execute().Unload();
	vStartIsFound = False;
	vEndIsFound = False;
	For Each vPeriodsRow In vPeriods Do
		If BegOfDay(vPeriodsRow.CheckInDate) = BegOfDay(pCheckInDate) Then
			vStartIsFound = True;
		EndIf;
		If BegOfDay(vPeriodsRow.CheckOutDate) = BegOfDay(pCheckOutDate) Then
			vEndIsFound = True;
		EndIf;
		If vStartIsFound And vEndIsFound Then
			Break;
		EndIf;
	EndDo;
	If vStartIsFound And vEndIsFound Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmCheckCheckInPeriods

// -----------------------------------------------------------------------------
// Description: Returns list of check-in periods suitable for accommodation or reservation
// Parameters: Hotel item reference, allotments folder reference, room type item reference, 
//             check-in date, check-out date
// Return value: Value table with list of check-in periods
// -----------------------------------------------------------------------------
Function cmGetCheckInPeriodsWithBalances(pHotel, pRoomQuota, pRoomType, pCustomer, pCheckInDate, pCheckOutDate) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalances.Period AS PeriodDate,
	|	RoomInventoryBalances.Hotel AS Hotel,
	|	RoomInventoryBalances.RoomType AS RoomType,
	|	RoomInventoryBalances.RoomType.SortCode AS RoomTypeSortCode,
	|	&qEmptyRoomQuota AS RoomQuota,
	|	&qEmptyString AS RoomQuotaDescription,
	|	0 AS RoomQuotaSortCode,
	|	RoomInventoryBalances.CounterClosingBalance,
	|	RoomInventoryBalances.RoomsVacantClosingBalance AS RoomsVacant,
	|	RoomInventoryBalances.BedsVacantClosingBalance AS BedsVacant
	|INTO RoomInventoryBalances
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qRoomQuotaIsEmpty
	|				AND Hotel = &qHotel
	|				AND RoomType = &qRoomType) AS RoomInventoryBalances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentBalances.Period AS PeriodDate,
	|	AllotmentBalances.Hotel AS Hotel,
	|	AllotmentBalances.RoomType AS RoomType,
	|	AllotmentBalances.RoomType.SortCode AS RoomTypeSortCode,
	|	AllotmentBalances.RoomQuota AS RoomQuota,
	|	AllotmentBalances.RoomQuota.Description AS RoomQuotaDescription,
	|	AllotmentBalances.RoomQuota.SortCode AS RoomQuotaSortCode,
	|	AllotmentBalances.CounterClosingBalance AS CounterClosingBalance,
	|	AllotmentBalances.RoomsInQuotaClosingBalance AS RoomsInQuota,
	|	AllotmentBalances.BedsInQuotaClosingBalance AS BedsInQuota,
	|	AllotmentBalances.RoomsRemainsClosingBalance AS RoomsRemains,
	|	AllotmentBalances.BedsRemainsClosingBalance AS BedsRemains
	|INTO AllotmentBalances
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			NOT &qRoomQuotaIsEmpty
	|				AND RoomQuota <> &qEmptyRoomQuota
	|				AND Hotel = &qHotel
	|				AND RoomType = &qRoomType
	|				AND (RoomQuota IN HIERARCHY (&qRoomQuota)
	|					OR &qRoomQuotaIsEmpty
	|					OR RoomQuota = &qBaseRoomQuota
	|						AND &qBaseRoomQuotaIsFilled)
	|				AND (RoomQuota.Customer = &qCustomer
	|					OR RoomQuota.Customer = &qEmptyCustomer
	|					OR &qCustomerIsEmpty)) AS AllotmentBalances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomQuotaCheckInPeriods.Hotel AS Hotel,
	|	RoomQuotaCheckInPeriods.RoomQuota AS RoomQuota,
	|	RoomQuotaCheckInPeriods.RoomQuota.Description AS RoomQuotaDescription,
	|	RoomQuotaCheckInPeriods.RoomQuota.SortCode AS RoomQuotaSortCode,
	|	RoomQuotaCheckInPeriods.CheckInDate AS CheckInDate,
	|	RoomQuotaCheckInPeriods.Duration AS Duration,
	|	RoomQuotaCheckInPeriods.CheckOutDate AS CheckOutDate,
	|	BEGINOFPERIOD(RoomQuotaCheckInPeriods.CheckInDate, DAY) AS BegOfCheckInDate,
	|	BEGINOFPERIOD(RoomQuotaCheckInPeriods.CheckOutDate, DAY) AS BegOfCheckOutDate
	|INTO CheckInPeriods
	|FROM
	|	InformationRegister.RoomQuotaCheckInPeriods AS RoomQuotaCheckInPeriods
	|WHERE
	|	NOT RoomQuotaCheckInPeriods.IsNotActive
	|	AND RoomQuotaCheckInPeriods.Hotel = &qHotel
	|	AND (RoomQuotaCheckInPeriods.RoomQuota IN HIERARCHY (&qRoomQuota)
	|			OR &qRoomQuotaIsEmpty
	|			OR RoomQuotaCheckInPeriods.RoomQuota = &qBaseRoomQuota
	|				AND &qBaseRoomQuotaIsFilled)
	|	AND (RoomQuotaCheckInPeriods.RoomQuota.Customer = &qCustomer
	|			OR RoomQuotaCheckInPeriods.RoomQuota = &qEmptyRoomQuota
	|			OR RoomQuotaCheckInPeriods.RoomQuota.Customer = &qEmptyCustomer
	|			OR &qCustomerIsEmpty)
	|	AND (BEGINOFPERIOD(RoomQuotaCheckInPeriods.CheckInDate, DAY) >= BEGINOFPERIOD(&qPeriodFrom, DAY)
	|			AND BEGINOFPERIOD(RoomQuotaCheckInPeriods.CheckOutDate, DAY) <= BEGINOFPERIOD(&qPeriodTo, DAY))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalancesByDates.PeriodDate AS PeriodDate,
	|	BalancesByDates.Hotel AS Hotel,
	|	BalancesByDates.RoomType AS RoomType,
	|	BalancesByDates.RoomTypeSortCode AS RoomTypeSortCode,
	|	BalancesByDates.RoomQuota AS RoomQuota,
	|	BalancesByDates.RoomQuotaDescription AS RoomQuotaDescription,
	|	BalancesByDates.RoomQuotaSortCode AS RoomQuotaSortCode,
	|	SUM(BalancesByDates.RoomsVacant) AS RoomsVacant,
	|	SUM(BalancesByDates.BedsVacant) AS BedsVacant,
	|	SUM(BalancesByDates.RoomsInQuota) AS RoomsInQuota,
	|	SUM(BalancesByDates.BedsInQuota) AS BedsInQuota,
	|	SUM(BalancesByDates.RoomsRemains) AS RoomsRemains,
	|	SUM(BalancesByDates.BedsRemains) AS BedsRemains
	|INTO BalancesByDates
	|FROM
	|	(SELECT
	|		InventoryBalances.PeriodDate AS PeriodDate,
	|		InventoryBalances.Hotel AS Hotel,
	|		InventoryBalances.RoomType AS RoomType,
	|		InventoryBalances.RoomTypeSortCode AS RoomTypeSortCode,
	|		InventoryBalances.RoomQuota AS RoomQuota,
	|		InventoryBalances.RoomQuotaDescription AS RoomQuotaDescription,
	|		InventoryBalances.RoomQuotaSortCode AS RoomQuotaSortCode,
	|		InventoryBalances.RoomsVacant AS RoomsVacant,
	|		InventoryBalances.BedsVacant AS BedsVacant,
	|		0 AS RoomsInQuota,
	|		0 AS BedsInQuota,
	|		0 AS RoomsRemains,
	|		0 AS BedsRemains
	|	FROM
	|		RoomInventoryBalances AS InventoryBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AllotmentBalances.PeriodDate,
	|		AllotmentBalances.Hotel,
	|		AllotmentBalances.RoomType,
	|		AllotmentBalances.RoomTypeSortCode,
	|		AllotmentBalances.RoomQuota,
	|		AllotmentBalances.RoomQuotaDescription,
	|		AllotmentBalances.RoomQuotaSortCode,
	|		0,
	|		0,
	|		AllotmentBalances.RoomsInQuota,
	|		AllotmentBalances.BedsInQuota,
	|		AllotmentBalances.RoomsRemains,
	|		AllotmentBalances.BedsRemains
	|	FROM
	|		AllotmentBalances AS AllotmentBalances) AS BalancesByDates
	|
	|GROUP BY
	|	BalancesByDates.PeriodDate,
	|	BalancesByDates.Hotel,
	|	BalancesByDates.RoomType,
	|	BalancesByDates.RoomTypeSortCode,
	|	BalancesByDates.RoomQuota,
	|	BalancesByDates.RoomQuotaDescription,
	|	BalancesByDates.RoomQuotaSortCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalancesByDates.Hotel AS Hotel,
	|	BalancesByDates.RoomType AS RoomType,
	|	BalancesByDates.RoomTypeSortCode AS RoomTypeSortCode,
	|	BalancesByDates.RoomQuota AS RoomQuota,
	|	BalancesByDates.RoomQuotaDescription AS RoomQuotaDescription,
	|	BalancesByDates.RoomQuotaSortCode AS RoomQuotaSortCode,
	|	CASE
	|		WHEN NOT ISNULL(BalancesByDates.RoomQuota.IsForCheckInPeriods, FALSE)
	|			THEN ISNULL(CheckInPeriods.Duration, 1)
	|		ELSE CheckInPeriods.Duration
	|	END AS Duration,
	|	ISNULL(CheckInPeriods.CheckInDate, DATEADD(BalancesByDates.PeriodDate, SECOND, &qCheckInHourSeconds)) AS CheckInDate,
	|	ISNULL(CheckInPeriods.CheckOutDate, DATEADD(BalancesByDates.PeriodDate, SECOND, &qNextDayCheckInHourSeconds)) AS CheckOutDate,
	|	MIN(BalancesByDates.RoomsVacant) AS RoomsVacant,
	|	MIN(BalancesByDates.BedsVacant) AS BedsVacant,
	|	MIN(BalancesByDates.RoomsInQuota) AS RoomsInQuota,
	|	MIN(BalancesByDates.BedsInQuota) AS BedsInQuota,
	|	MIN(BalancesByDates.RoomsRemains) AS RoomsRemains,
	|	MIN(BalancesByDates.BedsRemains) AS BedsRemains
	|FROM
	|	BalancesByDates AS BalancesByDates
	|		LEFT JOIN CheckInPeriods AS CheckInPeriods
	|		ON BalancesByDates.Hotel = CheckInPeriods.Hotel
	|			AND BalancesByDates.RoomQuota = CheckInPeriods.RoomQuota
	|			AND BalancesByDates.PeriodDate >= CheckInPeriods.BegOfCheckInDate
	|			AND BalancesByDates.PeriodDate < CheckInPeriods.BegOfCheckOutDate
	|WHERE
	|	NOT CheckInPeriods.Duration IS NULL 
	|	AND BalancesByDates.Hotel = &qHotel
	|	AND BalancesByDates.RoomType = &qRoomType
	|	AND (BalancesByDates.RoomQuota IN HIERARCHY (&qRoomQuota)
	|			OR &qRoomQuotaIsEmpty
	|			OR BalancesByDates.RoomQuota = &qBaseRoomQuota
	|				AND &qBaseRoomQuotaIsFilled)
	|	AND ISNULL(CheckInPeriods.CheckOutDate, DATEADD(BalancesByDates.PeriodDate, SECOND, &qNextDayCheckInHourSeconds)) <= &qPeriodTo
	|
	|GROUP BY
	|	BalancesByDates.Hotel,
	|	BalancesByDates.RoomType,
	|	BalancesByDates.RoomTypeSortCode,
	|	BalancesByDates.RoomQuota,
	|	BalancesByDates.RoomQuotaDescription,
	|	BalancesByDates.RoomQuotaSortCode,
	|	CASE
	|		WHEN NOT ISNULL(BalancesByDates.RoomQuota.IsForCheckInPeriods, FALSE)
	|			THEN ISNULL(CheckInPeriods.Duration, 1)
	|		ELSE CheckInPeriods.Duration
	|	END,
	|	ISNULL(CheckInPeriods.CheckInDate, DATEADD(BalancesByDates.PeriodDate, SECOND, &qCheckInHourSeconds)),
	|	ISNULL(CheckInPeriods.CheckOutDate, DATEADD(BalancesByDates.PeriodDate, SECOND, &qNextDayCheckInHourSeconds))
	|
	|ORDER BY
	|	RoomTypeSortCode,
	|	RoomQuotaSortCode,
	|	RoomQuotaDescription,
	|	CheckInDate,
	|	Duration";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(pCustomer));
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qRoomQuota", pRoomQuota);
	vQry.SetParameter("qEmptyRoomQuota", Catalogs.RoomQuotas.EmptyRef());
	vQry.SetParameter("qRoomQuotaIsEmpty", Not ValueIsFilled(pRoomQuota));
	If ValueIsFilled(pRoomQuota) And Not pRoomQuota.IsFolder Then
		If ValueIsFilled(pRoomQuota.BaseRoomQuota) And Not pRoomQuota.BaseRoomQuota.IsFolder Then
			vQry.SetParameter("qBaseRoomQuota", pRoomQuota.BaseRoomQuota);
			vQry.SetParameter("qBaseRoomQuotaIsFilled", True);
		Else
			vQry.SetParameter("qBaseRoomQuota", Catalogs.RoomQuotas.EmptyRef());
			vQry.SetParameter("qBaseRoomQuotaIsFilled", False);
		EndIf;
	Else
		vQry.SetParameter("qBaseRoomQuota", Catalogs.RoomQuotas.EmptyRef());
		vQry.SetParameter("qBaseRoomQuotaIsFilled", False);
	EndIf;
	vQry.SetParameter("qPeriodFrom", pCheckInDate);
	vQry.SetParameter("qPeriodTo", pCheckOutDate);
	vQry.SetParameter("qEmptyString", "");
	vRefHour = cmGetReferenceHour(pHotel.RoomRate);
	vCheckInHourSeconds = vRefHour - BegOfDay(vRefHour);
	vQry.SetParameter("qCheckInHourSeconds", vCheckInHourSeconds + 1);
	vQry.SetParameter("qNextDayCheckInHourSeconds", vCheckInHourSeconds + (24*3600));
	Return vQry.Execute().Unload();
EndFunction // cmGetCheckInPeriodsWithBalances

// -----------------------------------------------------------------------------
// Description: Returns list of check-in periods suitable for accommodation or reservation
// Parameters: Hotel item reference, allotments folder reference, room type item reference, 
//             check-in date, check-out date
// Return value: Value table with list of check-in periods
// -----------------------------------------------------------------------------
Function cmGetSuitableAllotments(pCheckInPeriods, pCheckInDate, pCheckOutDate) Export
	// Process table of check-in periods
	If pCheckInPeriods.Count() > 1 Then
		i = 0;
		While i < (pCheckInPeriods.Count() - 1) Do
			vCheckInPeriodsRow = pCheckInPeriods.Get(i);
			vNextCheckInPeriodsRow = pCheckInPeriods.Get(i + 1);
			If vCheckInPeriodsRow.Hotel = vNextCheckInPeriodsRow.Hotel And 
			   vCheckInPeriodsRow.RoomType = vNextCheckInPeriodsRow.RoomType And 
			   vCheckInPeriodsRow.RoomQuota = vNextCheckInPeriodsRow.RoomQuota Then
				If vCheckInPeriodsRow.CheckOutDate < vNextCheckInPeriodsRow.CheckInDate Then
                	vNewCheckInPeriodsRow = pCheckInPeriods.Insert(i + 1);
					FillPropertyValues(vNewCheckInPeriodsRow, vNextCheckInPeriodsRow);
					vNewCheckInPeriodsRow.CheckInDate = vCheckInPeriodsRow.CheckOutDate;
					vNewCheckInPeriodsRow.CheckOutDate = vNextCheckInPeriodsRow.CheckInDate;
					vNewCheckInPeriodsRow.RoomsVacant = 0;
					vNewCheckInPeriodsRow.BedsVacant = 0;
					vNewCheckInPeriodsRow.RoomsInQuota = 0;
					vNewCheckInPeriodsRow.BedsInQuota = 0;
					vNewCheckInPeriodsRow.RoomsRemains = 0;
					vNewCheckInPeriodsRow.BedsRemains = 0;
					i = i + 1;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Allotments.Hotel AS Hotel,
	|	Allotments.RoomType AS RoomType,
	|	Allotments.RoomTypeSortCode AS RoomTypeSortCode,
	|	Allotments.RoomQuota AS RoomQuota,
	|	Allotments.RoomQuotaDescription AS RoomQuotaDescription,
	|	Allotments.RoomQuotaSortCode AS RoomQuotaSortCode,
	|	Allotments.CheckInDate AS CheckInDate,
	|	Allotments.CheckOutDate AS CheckOutDate,
	|	Allotments.RoomsVacant AS RoomsVacant,
	|	Allotments.BedsVacant AS BedsVacant,
	|	Allotments.RoomsInQuota AS RoomsInQuota,
	|	Allotments.BedsInQuota AS BedsInQuota,
	|	Allotments.RoomsRemains AS RoomsRemains,
	|	Allotments.BedsRemains AS BedsRemains
	|INTO SuitableAllotments
	|FROM
	|	&qSuitableAllotments AS Allotments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SuitableAllotments.Hotel AS Hotel,
	|	SuitableAllotments.RoomType AS RoomType,
	|	SuitableAllotments.RoomTypeSortCode AS RoomTypeSortCode,
	|	SuitableAllotments.RoomQuota AS RoomQuota,
	|	SuitableAllotments.RoomQuotaDescription AS RoomQuotaDescription,
	|	SuitableAllotments.RoomQuotaSortCode AS RoomQuotaSortCode,
	|	MIN(SuitableAllotments.CheckInDate) AS CheckInDate,
	|	MAX(SuitableAllotments.CheckOutDate) AS CheckOutDate,
	|	MIN(SuitableAllotments.RoomsVacant) AS RoomsVacant,
	|	MIN(SuitableAllotments.BedsVacant) AS BedsVacant,
	|	MIN(SuitableAllotments.RoomsInQuota) AS RoomsInQuota,
	|	MIN(SuitableAllotments.BedsInQuota) AS BedsInQuota,
	|	MIN(SuitableAllotments.RoomsRemains) AS RoomsRemains,
	|	MIN(SuitableAllotments.BedsRemains) AS BedsRemains
	|FROM
	|	SuitableAllotments AS SuitableAllotments
	|
	|GROUP BY
	|	SuitableAllotments.Hotel,
	|	SuitableAllotments.RoomType,
	|	SuitableAllotments.RoomTypeSortCode,
	|	SuitableAllotments.RoomQuota,
	|	SuitableAllotments.RoomQuotaDescription,
	|	SuitableAllotments.RoomQuotaSortCode
	|
	|HAVING
	|	(MIN(SuitableAllotments.RoomsVacant) > 0
	|		OR MIN(SuitableAllotments.RoomsRemains) > 0) AND
	|	BEGINOFPERIOD(MIN(SuitableAllotments.CheckInDate), DAY) = BEGINOFPERIOD(&qPeriodFrom, DAY) AND
	|	BEGINOFPERIOD(MAX(SuitableAllotments.CheckOutDate), DAY) = BEGINOFPERIOD(&qPeriodTo, DAY)
	|
	|ORDER BY
	|	RoomTypeSortCode,
	|	RoomsRemains DESC,
	|	RoomsVacant DESC,
	|	RoomQuotaSortCode,
	|	RoomQuotaDescription";
	vQry.SetParameter("qSuitableAllotments", pCheckInPeriods);
	vQry.SetParameter("qPeriodFrom", pCheckInDate);
	vQry.SetParameter("qPeriodTo", pCheckOutDate);
	Return vQry.Execute().Unload();
EndFunction // cmGetSuitableAllotments

// -----------------------------------------------------------------------------
// Description: Returns list of document resource reservations 
// Parameters: Parent document
// Return value: Value table with resource reservation references
// -----------------------------------------------------------------------------
Function cmGetChildResourceReservations(pDoc, pPostedOnly = False) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ResourceReservation.Ref,
	|	ResourceReservation.Resource,
	|	ResourceReservation.ResourceType,
	|	ResourceReservation.DateTimeFrom,
	|	ResourceReservation.DateTimeTo
	|FROM
	|	Document.ResourceReservation AS ResourceReservation
	|WHERE
	|	ResourceReservation.ParentDoc = &qParentDoc
	|	AND (NOT &qPostedOnly
	|			OR &qPostedOnly
	|				AND ResourceReservation.Posted)
	|
	|ORDER BY
	|	ResourceReservation.Date,
	|	ResourceReservation.PointInTime";
	vQry.SetParameter("qParentDoc", pDoc);
	vQry.SetParameter("qPostedOnly", pPostedOnly);
	Return vQry.Execute().Unload();
EndFunction // cmGetChildResourceReservations

// -----------------------------------------------------------------------------
// Description: Completely deletes accommodations and reservations in the parameter value 
//              list from the database. All folios, charges and payments will be saved but folios
//              will be anonymized
// Parameters: Value list with references to documents to delete
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmDeleteAccommodationsLeavingCharges(pAccList) Export
	// Build value list of parent and child documents that should be deleted
	vDocsList = New ValueList();
	For Each vAccListItem In pAccList Do
		vCurAcc = vAccListItem.Value;
		vCurAccObj = vCurAcc.GetObject();
		vDocsList.Add(vCurAcc);
		vPrevDoc = vCurAcc;
		While ValueIsFilled(vPrevDoc.ParentDoc) Do
			If vDocsList.FindByValue(vPrevDoc.ParentDoc) = Undefined Then
				vDocsList.Insert(0, vPrevDoc.ParentDoc);
				vResResDocs = cmGetChildResourceReservations(vPrevDoc.ParentDoc);
				For Each vResResDocsRow In vResResDocs Do
					If vDocsList.FindByValue(vResResDocsRow.Ref) = Undefined Then
						vDocsList.Add(vResResDocsRow.Ref);
					EndIf;
				EndDo;
			EndIf;
			vPrevDoc = vPrevDoc.ParentDoc;
		EndDo;
		vNextDoc = vCurAccObj.pmGetNextAccommodationInChain();
		While ValueIsFilled(vNextDoc) Do
			If vDocsList.FindByValue(vNextDoc) = Undefined Then
				vDocsList.Add(vNextDoc);
				vResResDocs = cmGetChildResourceReservations(vNextDoc);
				For Each vResResDocsRow In vResResDocs Do
					If vDocsList.FindByValue(vResResDocsRow.Ref) = Undefined Then
						vDocsList.Add(vResResDocsRow.Ref);
					EndIf;
				EndDo;
			EndIf;
			vNextDoc = vNextDoc.GetObject().pmGetNextAccommodationInChain();
		EndDo;
		vChildReservations = vCurAccObj.pmGetChildReservations();
		For Each vChildReservationsRow In vChildReservations Do
			If vDocsList.FindByValue(vChildReservationsRow.Reservation) = Undefined Then
				vDocsList.Add(vChildReservationsRow.Reservation);
				vResResDocs = cmGetChildResourceReservations(vChildReservationsRow.Reservation);
				For Each vResResDocsRow In vResResDocs Do
					If vDocsList.FindByValue(vResResDocsRow.Ref) = Undefined Then
						vDocsList.Add(vResResDocsRow.Ref);
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		vResResDocs = cmGetChildResourceReservations(vCurAcc);
		For Each vResResDocsRow In vResResDocs Do
			If vDocsList.FindByValue(vResResDocsRow.Ref) = Undefined Then
				vDocsList.Add(vResResDocsRow.Ref);
			EndIf;
		EndDo;
	EndDo;
	
	// Try to find folios, preauthorizations, payments, returns, deposit transfers, charges, storno and charge transfers bound to this document
	For Each vDocsListItem In vDocsList Do
		vDocRef = vDocsListItem.Value;
		vDocObj = vDocRef.GetObject();
		
		// Find folios
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Folio.Ref
		|FROM
		|	Document.Folio AS Folio
		|WHERE
		|	Folio.ParentDoc = &qParentDoc
		|
		|ORDER BY
		|	Folio.Date,
		|	Folio.PointInTime";
		vQry.SetParameter("qParentDoc", vDocRef);
		vDocFolios = vQry.Execute().Unload();
		For Each vDocFoliosRow In vDocFolios Do
			vDocFolio = vDocFoliosRow.Ref;
			vDocFolioObj = vDocFolio.GetObject();
			
			// Update folio
			vDocFolioObj.ParentDoc = Undefined;
			vDocFolioObj.Client = Catalogs.Clients.EmptyRef();
			vDocFolioObj.Write(DocumentWriteMode.Write);
			
			// Repost folio transactions
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Charges.Ref AS Ref
			|FROM
			|	Document.Charge AS Charges
			|WHERE
			|	Charges.Folio = &qFolio
			|
			|UNION ALL
			|
			|SELECT
			|	Storno.Ref
			|FROM
			|	Document.Storno AS Storno
			|WHERE
			|	Storno.ParentCharge.Folio = &qFolio
			|
			|UNION ALL
			|
			|SELECT
			|	ChargeTransfers.Ref
			|FROM
			|	Document.ChargeTransfer AS ChargeTransfers
			|WHERE
			|	(ChargeTransfers.FolioFrom = &qFolio
			|			OR ChargeTransfers.FolioTo = &qFolio)
			|
			|UNION ALL
			|
			|SELECT
			|	DepositTransfers.Ref
			|FROM
			|	Document.DepositTransfer AS DepositTransfers
			|WHERE
			|	(DepositTransfers.FolioFrom = &qFolio
			|			OR DepositTransfers.FolioTo = &qFolio)
			|
			|UNION ALL
			|
			|SELECT
			|	Preauthorisations.Ref
			|FROM
			|	Document.Preauthorisation AS Preauthorisations
			|WHERE
			|	Preauthorisations.Folio = &qFolio
			|
			|UNION ALL
			|
			|SELECT
			|	Payments.Ref
			|FROM
			|	Document.Payment AS Payments
			|WHERE
			|	Payments.Folio = &qFolio
			|
			|UNION ALL
			|
			|SELECT
			|	Returns.Ref
			|FROM
			|	Document.Return AS Returns
			|WHERE
			|	Returns.Folio = &qFolio
			|
			|UNION ALL
			|
			|SELECT
			|	ServiceRegistrations.Ref
			|FROM
			|	Document.ServiceRegistration AS ServiceRegistrations
			|WHERE
			|	ServiceRegistrations.Folio = &qFolio";
			vQry.SetParameter("qFolio", vDocFolio);
			vFolioDocs = vQry.Execute().Unload();
			For Each vFolioDocsRow In vFolioDocs Do
				vFolioDoc = vFolioDocsRow.Ref;
				vFolioDocObj = vFolioDoc.GetObject();
				If TypeOf(vFolioDoc) = Type("DocumentRef.Charge") Then
					vFolioDocObj.ParentDoc = Undefined;
				ElsIf TypeOf(vFolioDoc) = Type("DocumentRef.Storno") Then
					vFolioDocObj.ParentDoc = Undefined;
				ElsIf TypeOf(vFolioDoc) = Type("DocumentRef.ChargeTransfer") Then
					vFolioDocObj.ParentDoc = Undefined;
				ElsIf TypeOf(vFolioDoc) = Type("DocumentRef.DepositTransfer") Then
					vFolioDocObj.ParentDoc = Undefined;
				ElsIf TypeOf(vFolioDoc) = Type("DocumentRef.Preauthorisation") Then
					vFolioDocObj.ParentDoc = Undefined;
					vFolioDocObj.Payer = Undefined;
				ElsIf TypeOf(vFolioDoc) = Type("DocumentRef.Payment") Then
					vFolioDocObj.ParentDoc = Undefined;
					vFolioDocObj.Payer = Undefined;
				ElsIf TypeOf(vFolioDoc) = Type("DocumentRef.Return") Then
					vFolioDocObj.ParentDoc = Undefined;
					vFolioDocObj.Payer = Undefined;
				ElsIf TypeOf(vFolioDoc) = Type("DocumentRef.ServiceRegistration") Then
					vFolioDocObj.ParentDoc = Undefined;
					vFolioDocObj.Client = Undefined;
				EndIf;
				If vFolioDocObj.Posted Then
					vFolioDocObj.Write(DocumentWriteMode.Posting);
				Else
					vFolioDocObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndDo;
		EndDo;
		
		// Update bound documents
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Charges.Ref AS Ref
		|FROM
		|	Document.Charge AS Charges
		|WHERE
		|	Charges.ParentDoc = &qParentDoc
		|
		|UNION ALL
		|
		|SELECT
		|	Storno.Ref
		|FROM
		|	Document.Storno AS Storno
		|WHERE
		|	Storno.ParentDoc = &qParentDoc
		|
		|UNION ALL
		|
		|SELECT
		|	ChargeTransfers.Ref
		|FROM
		|	Document.ChargeTransfer AS ChargeTransfers
		|WHERE
		|	ChargeTransfers.ParentDoc = &qParentDoc
		|
		|UNION ALL
		|
		|SELECT
		|	DepositTransfers.Ref
		|FROM
		|	Document.DepositTransfer AS DepositTransfers
		|WHERE
		|	DepositTransfers.ParentDoc = &qParentDoc
		|
		|UNION ALL
		|
		|SELECT
		|	Preauthorisations.Ref
		|FROM
		|	Document.Preauthorisation AS Preauthorisations
		|WHERE
		|	Preauthorisations.ParentDoc = &qParentDoc
		|
		|UNION ALL
		|
		|SELECT
		|	Payments.Ref
		|FROM
		|	Document.Payment AS Payments
		|WHERE
		|	Payments.ParentDoc = &qParentDoc
		|
		|UNION ALL
		|
		|SELECT
		|	Returns.Ref
		|FROM
		|	Document.Return AS Returns
		|WHERE
		|	Returns.ParentDoc = &qParentDoc
		|
		|UNION ALL
		|
		|SELECT
		|	RoomInterfaceStatuses.Ref
		|FROM
		|	Document.RoomInterfaceStatus AS RoomInterfaceStatuses
		|WHERE
		|	RoomInterfaceStatuses.ParentDoc = &qParentDoc
		|
		|UNION ALL
		|
		|SELECT
		|	ServiceRegistrations.Ref
		|FROM
		|	Document.ServiceRegistration AS ServiceRegistrations
		|WHERE
		|	ServiceRegistrations.ParentDoc = &qParentDoc";
		vQry.SetParameter("qParentDoc", vDocRef);
		vBoundDocs = vQry.Execute().Unload();
		For Each vBoundDocsRow In vBoundDocs Do
			vBoundDoc = vBoundDocsRow.Ref;
			vBoundDocObj = vBoundDoc.GetObject();
			If TypeOf(vBoundDoc) = Type("DocumentRef.Charge") Then
				vBoundDocObj.ParentDoc = Undefined;
			ElsIf TypeOf(vBoundDoc) = Type("DocumentRef.Storno") Then
				vBoundDocObj.ParentDoc = Undefined;
			ElsIf TypeOf(vBoundDoc) = Type("DocumentRef.ChargeTransfer") Then
				vBoundDocObj.ParentDoc = Undefined;
			ElsIf TypeOf(vBoundDoc) = Type("DocumentRef.DepositTransfer") Then
				vBoundDocObj.ParentDoc = Undefined;
			ElsIf TypeOf(vBoundDoc) = Type("DocumentRef.Preauthorisation") Then
				vBoundDocObj.ParentDoc = Undefined;
				vBoundDocObj.Payer = Undefined;
			ElsIf TypeOf(vBoundDoc) = Type("DocumentRef.Payment") Then
				vBoundDocObj.ParentDoc = Undefined;
				vBoundDocObj.Payer = Undefined;
			ElsIf TypeOf(vBoundDoc) = Type("DocumentRef.Return") Then
				vBoundDocObj.ParentDoc = Undefined;
				vBoundDocObj.Payer = Undefined;
			ElsIf TypeOf(vBoundDoc) = Type("DocumentRef.RoomInterfaceStatus") Then
				vBoundDocObj.ParentDoc = Undefined;
			ElsIf TypeOf(vBoundDoc) = Type("DocumentRef.ServiceRegistration") Then
				vBoundDocObj.ParentDoc = Undefined;
				vBoundDocObj.Client = Undefined;
			EndIf;
			If vBoundDocObj.Posted Then
				vBoundDocObj.Write(DocumentWriteMode.Posting);
			Else
				vBoundDocObj.Write(DocumentWriteMode.Write);
			EndIf;
			If TypeOf(vBoundDoc) = Type("DocumentRef.RoomInterfaceStatus") Then
				vBoundDocObj.Delete();
			EndIf;
		EndDo;
		
		// Clear document parent, charging rules and services
		vDocObj.ParentDoc = Undefined;
		If TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Then
			vDocObj.Reservation = Undefined;
			vDocObj.ChargingRules.Clear();
			vDocObj.Services.Clear();
		ElsIf TypeOf(vDocRef) = Type("DocumentRef.Reservation") Then
			vDocObj.ChargingRules.Clear();
			vDocObj.Services.Clear();
		ElsIf TypeOf(vDocRef) = Type("DocumentRef.ResourceReservation") Then
			vDocObj.Services.Clear();
		EndIf;
		vDocObj.Write(DocumentWriteMode.Write);
		
		// Delete client identification cards
		vIDCards = cmGetClientIdentificationCardsByParentDoc(vDocRef, True);
		For Each vIDCardsRow In vIDCards Do
			vIDCardsRow.Ref.GetObject().Delete();
		EndDo;
		
		// Update guest groups
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	GuestGroups.Ref
		|FROM
		|	Catalog.GuestGroups AS GuestGroups
		|WHERE
		|	GuestGroups.ClientDoc = &qParentDoc
		|
		|ORDER BY
		|	GuestGroups.Owner.Code,
		|	GuestGroups.Code";
		vQry.SetParameter("qParentDoc", vDocRef);
		vGuestGroups = vQry.Execute().Unload();
		For Each vGuestGroupsRow In vGuestGroups Do
			vGuestGroupObj = vGuestGroupsRow.Ref.GetObject();
			vGuestGroupObj.Client = Undefined;
			vGuestGroupObj.ClientDoc = Undefined;
			vGuestGroupObj.Write();
		EndDo;			
		
		// Update invoices
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Invoice.Ref
		|FROM
		|	Document.ProformaInvoice AS Invoice
		|WHERE
		|	Invoice.ParentDoc = &qParentDoc
		|
		|ORDER BY
		|	Invoice.Date,
		|	Invoice.PointInTime";
		vQry.SetParameter("qParentDoc", vDocRef);
		vInvoices = vQry.Execute().Unload();
		For Each vInvoicesRow In vInvoices Do
			vInvoiceObj = vInvoicesRow.Ref.GetObject();
			vInvoiceObj.ParentDoc = Undefined;
			If vInvoiceObj.Posted Then
				vInvoiceObj.Write(DocumentWriteMode.Posting);
			Else
				vInvoiceObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndDo;			
		
		// Delete document client data scans
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ClientDataScans.Ref
		|FROM
		|	Document.ClientDataScans AS ClientDataScans
		|WHERE
		|	ClientDataScans.ParentDoc = &qParentDoc
		|
		|ORDER BY
		|	ClientDataScans.Date,
		|	ClientDataScans.PointInTime";
		vQry.SetParameter("qParentDoc", vDocRef);
		vDataScans = vQry.Execute().Unload();
		For Each vDataScansRow In vDataScans Do
			vDataScansRow.Ref.GetObject().Delete();
		EndDo;			
		
		// Delete foreigner registry records
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ForeignerRegistryRecord.Ref
		|FROM
		|	Document.ForeignerRegistryRecord AS ForeignerRegistryRecord
		|WHERE
		|	ForeignerRegistryRecord.ParentDoc = &qParentDoc
		|
		|ORDER BY
		|	ForeignerRegistryRecord.Date,
		|	ForeignerRegistryRecord.PointInTime";
		vQry.SetParameter("qParentDoc", vDocRef);
		vFRecs = vQry.Execute().Unload();
		For Each vFRecsRow In vFRecs Do
			vFRecsRow.Ref.GetObject().Delete();
		EndDo;			
		
		// Delete messages
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Message.Ref
		|FROM
		|	Document.Message AS Message
		|WHERE
		|	(Message.ParentDoc = &qParentDoc
		|			OR Message.ByObject = &qParentDoc)
		|
		|ORDER BY
		|	Message.Date,
		|	Message.PointInTime";
		vQry.SetParameter("qParentDoc", vDocRef);
		vMessages = vQry.Execute().Unload();
		For Each vMessagesRow In vMessages Do
			vMessagesRow.Ref.GetObject().Delete();
		EndDo;			
		
		// Delete room interface statuses
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomInterfaceStatus.Ref
		|FROM
		|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
		|WHERE
		|	RoomInterfaceStatus.ParentDoc = &qParentDoc
		|
		|ORDER BY
		|	RoomInterfaceStatus.Date,
		|	RoomInterfaceStatus.PointInTime";
		vQry.SetParameter("qParentDoc", vDocRef);
		vRIStatuses = vQry.Execute().Unload();
		For Each vRIStatusesRow In vRIStatuses Do
			vRIStatusesRow.Ref.GetObject().Delete();
		EndDo;			
		
		// Clear document from operation schedules
		vQry = New Query();
		vQry.Text = 
		"SELECT DISTINCT
		|	OperationScheduleOperations.Ref
		|FROM
		|	Document.OperationSchedule.Operations AS OperationScheduleOperations
		|WHERE
		|	OperationScheduleOperations.ParentDoc = &qParentDoc
		|
		|ORDER BY
		|	OperationScheduleOperations.Ref.Date";
		vQry.SetParameter("qParentDoc", vDocRef);
		vSchedules = vQry.Execute().Unload();
		For Each vSchedulesRow In vSchedules Do
			vScheduleObj = vSchedulesRow.Ref.GetObject();
			For Each vOprRow In vScheduleObj.Operations Do
				If vOprRow.ParentDoc = vDocRef Then
					vOprRow.ParentDoc = Undefined;
				EndIf;
			EndDo;
			vScheduleObj.Write(DocumentWriteMode.Write);
		EndDo;			
		
		// Update and repost settlements
		vQry = New Query();
		vQry.Text = 
		"SELECT DISTINCT
		|	SettlementServices.Ref
		|FROM
		|	Document.Settlement.Services AS SettlementServices
		|WHERE
		|	(SettlementServices.ParentDoc = &qParentDoc
		|			OR SettlementServices.Ref.ParentDoc = &qParentDoc)
		|
		|ORDER BY
		|	SettlementServices.Ref.Date,
		|	SettlementServices.Ref.PointInTime";
		vQry.SetParameter("qParentDoc", vDocRef);
		vSettlements = vQry.Execute().Unload();
		For Each vSettlementsRow In vSettlements Do
			vSettlementObj = vSettlementsRow.Ref.GetObject();
			If vSettlementObj.ParentDoc = vDocRef Then
				vSettlementObj.ParentDoc = Undefined;
			EndIf;
			For Each vSrvRow In vSettlementObj.Services Do
				If vSrvRow.ParentDoc = vDocRef Then
					vSrvRow.Client = Undefined;
					vSrvRow.ParentDoc = Undefined;
				EndIf;
			EndDo;
			If vSettlementObj.Posted Then
				vSettlementObj.Write(DocumentWriteMode.Posting);
			Else
				vSettlementObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndDo;			
		
		// Set deletion mark to the document
		If Not vDocRef.DeletionMark Then
			vDocObj.SetDeletionMark(True);
		EndIf;
		
		// Clear document change history
		vMgr = Undefined;
		vDimensionName = "";
		If TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Then
			vDimensionName = "Accommodation";
			vMgr = InformationRegisters.AccommodationChangeHistory;
		ElsIf TypeOf(vDocRef) = Type("DocumentRef.Reservation") Then
			vDimensionName = "Reservation";
			vMgr = InformationRegisters.ReservationChangeHistory;
		ElsIf TypeOf(vDocRef) = Type("DocumentRef.ResourceReservation") Then
			vDimensionName = "ResourceReservation";
			vMgr = InformationRegisters.ResourceReservationChangeHistory;
		EndIf;
		If vMgr <> Undefined Then
			vSel = vMgr.Select(,, New Structure(vDimensionName, vDocRef));
			While vSel.Next() Do
				vRecMgr = vSel.GetRecordManager();
				vRecMgr.Delete();
			EndDo;
		EndIf;
		
		// Clear safety system events
		vSSERcdMgr = InformationRegisters.SafetySystemEvents.CreateRecordManager();
		vSSEQry = New Query();
		vSSEQry.Text = 
		"SELECT
		|	SafetySystemEvents.Period AS Period,
		|	SafetySystemEvents.Room,
		|	SafetySystemEvents.EventType,
		|	SafetySystemEvents.Hotel,
		|	SafetySystemEvents.ParentDoc
		|FROM
		|	InformationRegister.SafetySystemEvents AS SafetySystemEvents
		|WHERE
		|	SafetySystemEvents.ParentDoc = &qParentDoc
		|
		|ORDER BY
		|	Period";
		vSSEQry.SetParameter("qParentDoc", vDocRef);
		vSSEvents = vSSEQry.Execute().Unload();
		For Each vSSEventsRow In vSSEvents Do
			vSSERcdMgr.Period = vSSEventsRow.Period;
			vSSERcdMgr.Room = vSSEventsRow.Room;
			vSSERcdMgr.EventType = vSSEventsRow.EventType;
			vSSERcdMgr.Hotel = vSSEventsRow.Hotel;
			vSSERcdMgr.Read();
			If vSSERcdMgr.Selected() Then
				vSSERcdMgr.Delete();
			EndIf;
		EndDo;
		
		// Clear room status change history
		vRSCHRcdMgr = InformationRegisters.RoomStatusChangeHistory.CreateRecordManager();
		vRSCHQry = New Query();
		vRSCHQry.Text = 
		"SELECT
		|	RoomStatusChangeHistory.Period,
		|	RoomStatusChangeHistory.Room,
		|	RoomStatusChangeHistory.RoomStatus,
		|	RoomStatusChangeHistory.Remarks,
		|	RoomStatusChangeHistory.User
		|FROM
		|	InformationRegister.RoomStatusChangeHistory AS RoomStatusChangeHistory
		|WHERE
		|	RoomStatusChangeHistory.Remarks LIKE &qRemarks
		|
		|ORDER BY
		|	RoomStatusChangeHistory.Room.SortCode,
		|	RoomStatusChangeHistory.Period";
		vRSCHQry.SetParameter("qRemarks", "%" + String(vDocRef) + "%");
		vRSCHEvents = vRSCHQry.Execute().Unload();
		For Each vRSCHEventsRow In vRSCHEvents Do
			vRSCHRcdMgr.Period = vRSCHEventsRow.Period;
			vRSCHRcdMgr.Room = vRSCHEventsRow.Room;
			vRSCHRcdMgr.Read();
			If vRSCHRcdMgr.Selected() Then
				vRSCHRcdMgr.Delete();
			EndIf;
		EndDo;
		
		// Clear reservation custom attributes
		vRCARcdSet = InformationRegisters.ReservationCustomAttributeValues.CreateRecordSet();
		vOwnerFilter = vRCARcdSet.Filter.Owner;
		vOwnerFilter.ComparisonType = ComparisonType.Equal;
		vOwnerFilter.Value = vDocRef;
		vOwnerFilter.Use = True;
		vRCARcdSet.Read();
		vRCARcdSet.Clear();
		vRCARcdSet.Write(True);
	EndDo;
		
	// Check references and delete document completely
	For Each vDocsListItem In vDocsList Do
		vDocRef = vDocsListItem.Value;
		vDocObj = vDocRef.GetObject();
		
		// Check references to the document
		vDocsArray = New Array();
		vDocsArray.Add(vDocRef);
		vRefsTab = FindByRef(vDocsArray);
		If vRefsTab.Count() > 0 Then
			vMessage = NStr("en='Found references that could not be processed automatically!';ru='Найдены ссылки, которые не могут быть автоматически обработаны!';de='Es wurden Links gefunden, die nicht automatisch bearbeitet werden können!'");
			For Each vRefsTabRow In vRefsTab Do
				vMessage = vMessage + Chars.LF + TrimAll(vRefsTabRow[0]) + " - " + TrimAll(vRefsTabRow[1]);
			EndDo;
			Raise vMessage;
		EndIf;
		
		// Delete document completely from the database
		vDocObj.Delete();
	EndDo;
		
	// Clear employee actions history
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Employees.Ref
	|FROM
	|	Catalog.Employees AS Employees
	|WHERE
	|	NOT Employees.IsFolder
	|
	|ORDER BY
	|	Employees.Code";
	vEmployees = vQry.Execute().Unload();
	For Each vEmployeesRow In vEmployees Do
		vEmployeeObj = vEmployeesRow.Ref.GetObject();
		vEmployeeObj.LastVisitedObjects = Undefined;
		vEmployeeObj.Write();
	EndDo;
EndProcedure // cmDeleteAccommodationsLeavingCharges

// -----------------------------------------------------------------------------
//  Returns reservation that could be used as parent for the current one
//
// Parameters:
//  pGuestGroup			 - 	 - 
//  pCheckInDate		 - 	 - 
//  pAccommodationType	 - 	 - 
//  pParentDocsList		 - 	 - 
//  pGuest				 - 	 - 
//  pCustomer			 - 	 - 
// 
// Returns:
//  DocumentRef.Reservation - Reservation document reference or undefined
//
Function cmGetPreviousReservation(pGuestGroup, pCheckInDate, pAccommodationType, pParentDocsList = Undefined, pGuest = Undefined, pCustomer = Undefined) Export
	If pParentDocsList = Undefined Then
		pParentDocsList = New ValueList();
	EndIf;
	vReservation = Undefined;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	UsedReservations.ParentDoc AS Ref
	|INTO UsedReservations
	|FROM
	|	Document.Reservation AS UsedReservations
	|WHERE
	|	UsedReservations.ParentDoc <> &qUndefined
	|	AND UsedReservations.Posted
	|	AND (UsedReservations.ReservationStatus.IsActive
	|			OR UsedReservations.ReservationStatus.IsPreliminary)
	|	AND NOT UsedReservations.ReservationStatus.IsCheckIn
	|	AND UsedReservations.GuestGroup = &qGuestGroup
	|	AND UsedReservations.AccommodationType = &qAccommodationType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Reservation.Ref AS Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND (Reservation.ReservationStatus.IsActive
	|			OR Reservation.ReservationStatus.IsPreliminary)
	|	AND NOT Reservation.ReservationStatus.IsCheckIn
	|	AND NOT Reservation.ReservationStatus.IsArrivalSchedule
	|	AND Reservation.GuestGroup = &qGuestGroup
	|	AND (NOT &qDoNotCheckGuest
	|			OR &qDoNotCheckGuest
	|				AND Reservation.AccommodationType = &qAccommodationType)
	|	AND (Reservation.GuestFullName = &qGuestFullName
	|			OR Reservation.Guest = &qGuest
	|			OR &qDoNotCheckGuest)
	|	AND (Reservation.Customer = &qCustomer
	|			OR &qDoNotCheckCustomer)
	|	AND BEGINOFPERIOD(Reservation.CheckOutDate, DAY) = &qDate
	|	AND Reservation.CheckInDate < &qCheckInDate
	|	AND (NOT &qDoNotCheckGuest
	|			OR &qDoNotCheckGuest
	|				AND NOT Reservation.Ref IN
	|						(SELECT
	|							UsedReservations.Ref
	|						FROM
	|							UsedReservations AS UsedReservations))
	|	AND NOT Reservation.Ref IN (&qParentDocsList)
	|
	|ORDER BY
	|	Reservation.Date,
	|	Reservation.PointInTime";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qDate", BegOfDay(pCheckInDate));
	vQry.SetParameter("qCheckInDate", pCheckInDate);
	vQry.SetParameter("qAccommodationType", pAccommodationType);
	vQry.SetParameter("qUndefined", Undefined);
	vQry.SetParameter("qParentDocsList", pParentDocsList);
	vQry.SetParameter("qGuestFullName", ?(ValueIsFilled(pGuest), TrimR(pGuest.FullName), ""));
	vQry.SetParameter("qGuest", pGuest);
	vQry.SetParameter("qDoNotCheckGuest", Not ValueIsFilled(pGuest));
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qDoNotCheckCustomer", pCustomer = Undefined);
	vReservations = vQry.Execute().Unload();
	If vReservations.Count() > 0 Then
		vReservationsRow = vReservations.Get(0);
		vReservation = vReservationsRow.Ref;
	EndIf;
	Return vReservation;
EndFunction // cmGetPreviousReservation

// -----------------------------------------------------------------------------
//  Returns reservation that is next in guest reservation chain
//
// Parameters:
//  pGuestGroup			 - CatalogRef.GuestGroups	 - Guest group ref where to search for
//  pCheckOutDate		 - Date						 - Check-out date of the current reservation
//  pAccommodationType	 - String					 - Accommodation type of the current reservation
//  pGuest				 - CatalogRef.Clients		 - Guest of the current reservation
// 
// Returns:
//  DocumentRef.Reservation - Reservation document reference or undefined
//
Function cmGetNextReservation(pGuestGroup, pCheckOutDate, pAccommodationType, pGuest = Undefined) Export
	vReservation = Undefined;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND (Reservation.ReservationStatus.IsActive
	|			OR Reservation.ReservationStatus.IsCheckIn)
	|	AND Reservation.GuestGroup = &qGuestGroup
	|	AND (NOT &qDoNotCheckGuest
	|			OR &qDoNotCheckGuest
	|				AND Reservation.AccommodationType = &qAccommodationType)
	|	AND (Reservation.GuestFullName = &qGuestFullName
	|			OR Reservation.Guest = &qGuest
	|			OR &qDoNotCheckGuest)
	|	AND BEGINOFPERIOD(Reservation.CheckInDate, DAY) = &qDate
	|	AND Reservation.CheckOutDate > &qCheckOutDate
	|
	|ORDER BY
	|	Reservation.Date,
	|	Reservation.PointInTime";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qDate", BegOfDay(pCheckOutDate));
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vQry.SetParameter("qAccommodationType", pAccommodationType);
	vQry.SetParameter("qGuestFullName", ?(ValueIsFilled(pGuest), TrimR(pGuest.FullName), ""));
	vQry.SetParameter("qGuest", pGuest);
	vQry.SetParameter("qDoNotCheckGuest", Not ValueIsFilled(pGuest));
	vReservations = vQry.Execute().Unload();
	If vReservations.Count() > 0 Then
		vReservationsRow = vReservations.Get(0);
		vReservation = vReservationsRow.Ref;
	EndIf;
	Return vReservation;
EndFunction // cmGetNextReservation

// -----------------------------------------------------------------------------
Function cmGetNextReservationInChain(pParentDoc) Export
	vNextDoc = Undefined;
	If Not ValueIsFilled(pParentDoc) Then
		Return vNextDoc;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservations.Ref AS Ref
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.ParentDoc = &qParentDoc
	|	AND Reservations.Posted
	|	AND Reservations.CheckInDate >= &qCheckInDate
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary)
	|
	|ORDER BY
	|	Reservations.CheckInDate,
	|	Reservations.SortCode";
	vQry.SetParameter("qParentDoc", pParentDoc);
	vQry.SetParameter("qCheckInDate", BegOfDay(pParentDoc.CheckInDate));
	vNextDocs = vQry.Execute().Unload();
	If vNextDocs.Count() > 0 Then
		vNextDoc = vNextDocs.Get(0).Ref;
	EndIf;
	Return vNextDoc;
EndFunction // cmGetNextReservationInChain

// -----------------------------------------------------------------------------
Function cmGetPrevAccommodationInChain(pDoc) Export
	If ValueIsFilled(pDoc) And ValueIsFilled(pDoc.ParentDoc) And 
	   TypeOf(pDoc.ParentDoc) = Type("DocumentRef.Accommodation") Then
		Return pDoc.ParentDoc;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetPrevAccommodationInChain

// -----------------------------------------------------------------------------
//  Returns accommodation that could be used as parent for the current one
//
// Parameters:
//  pGuestGroup			 - CatalogRef.GuestGroups	 - Guest group ref where to search for
//  pCheckInDate		 - Date						 - Check-in date of the current accommodation
//  pAccommodationType	 - String					 - Accommodation type of the current accommodation
//  pParentDocsList		 - Array					 - Document list
//  pGuest				 - CatalogRef.Clients		 - Guest of the current accommodation
// 
// Returns:
//  DocumentRef.Accommodation - Accommodation document reference or undefined
//
Function cmGetPreviousAccommodation(pGuestGroup, pCheckInDate, pAccommodationType, pParentDocsList = Undefined, pGuest = Undefined) Export
	If pParentDocsList = Undefined Then
		pParentDocsList = New ValueList();
	EndIf;
	vAccommodation = Undefined;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	UsedAccommodations.ParentDoc AS Ref
	|INTO UsedAccommodations
	|FROM
	|	Document.Accommodation AS UsedAccommodations
	|WHERE
	|	UsedAccommodations.ParentDoc <> &qUndefined
	|	AND UsedAccommodations.Posted
	|	AND UsedAccommodations.AccommodationStatus.IsActive
	|	AND UsedAccommodations.GuestGroup = &qGuestGroup
	|	AND UsedAccommodations.AccommodationType = &qAccommodationType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.GuestGroup = &qGuestGroup
	|	AND (NOT &qDoNotCheckGuest
	|			OR &qDoNotCheckGuest
	|				AND Accommodation.AccommodationType = &qAccommodationType)
	|	AND (Accommodation.GuestFullName = &qGuestFullName
	|			OR Accommodation.Guest = &qGuest
	|			OR &qDoNotCheckGuest)
	|	AND BEGINOFPERIOD(Accommodation.CheckOutDate, DAY) = &qDate
	|	AND Accommodation.CheckInDate < &qCheckInDate
	|	AND (NOT &qDoNotCheckGuest
	|			OR &qDoNotCheckGuest
	|				AND NOT Accommodation.Ref IN
	|						(SELECT
	|							UsedAccommodations.Ref
	|						FROM
	|							UsedAccommodations AS UsedAccommodations))
	|	AND NOT Accommodation.Ref IN (&qParentDocsList)
	|
	|ORDER BY
	|	Accommodation.Date,
	|	Accommodation.PointInTime";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qDate", BegOfDay(pCheckInDate));
	vQry.SetParameter("qCheckInDate", pCheckInDate);
	vQry.SetParameter("qAccommodationType", pAccommodationType);
	vQry.SetParameter("qUndefined", Undefined);
	vQry.SetParameter("qGuest", pGuest);
	vQry.SetParameter("qGuestFullName", ?(ValueIsFilled(pGuest), TrimR(pGuest.FullName), ""));
	vQry.SetParameter("qDoNotCheckGuest", Not ValueIsFilled(pGuest));
	vQry.SetParameter("qParentDocsList", pParentDocsList);
	vAccommodations = vQry.Execute().Unload();
	If vAccommodations.Count() > 0 Then
		vAccommodationsRow = vAccommodations.Get(0);
		vAccommodation = vAccommodationsRow.Ref;
	EndIf;
	Return vAccommodation;
EndFunction // cmGetPreviousAccommodation

// -----------------------------------------------------------------------------
//  Returns accommodation that is next in guest accommodation chain
//
// Parameters:
//  pGuestGroup			 - CatalogRef.GuestGroups	 - Guest group ref where to search for
//  pCheckOutDate		 - Date						 - Check-out date of the current accommodation
//  pAccommodationType	 - String					 - Accommodation type of the current accommodation
//  pGuest				 - CatalogRef.Clients		 - Guest of the current accommodation
// 
// Returns:
//  DocumentRef.Accommodation - Accommodation document reference or undefined
//
Function cmGetNextAccommodation(pGuestGroup, pCheckOutDate, pAccommodationType, pGuest = Undefined) Export
	vAccommodation = Undefined;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.GuestGroup = &qGuestGroup
	|	AND (NOT &qDoNotCheckGuest
	|			OR &qDoNotCheckGuest
	|				AND Accommodation.AccommodationType = &qAccommodationType)
	|	AND (Accommodation.GuestFullName = &qGuestFullName
	|			OR Accommodation.Guest = &qGuest
	|			OR &qDoNotCheckGuest)
	|	AND BEGINOFPERIOD(Accommodation.CheckInDate, DAY) = &qDate
	|	AND Accommodation.CheckOutDate > &qCheckOutDate
	|
	|ORDER BY
	|	Accommodation.Date,
	|	Accommodation.PointInTime";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qDate", BegOfDay(pCheckOutDate));
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vQry.SetParameter("qAccommodationType", pAccommodationType);
	vQry.SetParameter("qGuest", pGuest);
	vQry.SetParameter("qGuestFullName", ?(ValueIsFilled(pGuest), TrimR(pGuest.FullName), ""));
	vQry.SetParameter("qDoNotCheckGuest", Not ValueIsFilled(pGuest));
	vAccommodations = vQry.Execute().Unload();
	If vAccommodations.Count() > 0 Then
		vAccommodationsRow = vAccommodations.Get(0);
		vAccommodation = vAccommodationsRow.Ref;
	EndIf;
	Return vAccommodation;
EndFunction // cmGetNextAccommodation

// -----------------------------------------------------------------------------
// Description: Fills document (reservation or accommodation) attributes from the parent document
// Parameters: Document object to update, Refrence to the parent document
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillAttributesFromParentDocument(pDocObj, pParentDoc, pDoNotFillGuest = False) Export
	If pDocObj.Ref = pParentDoc Then
		Return;
	EndIf;
	If Not pDoNotFillGuest Then
		pDocObj.Guest = pParentDoc.Guest;
		pDocObj.GuestFullName = pParentDoc.GuestFullName;
		pDocObj.Car = pParentDoc.Car;
		pDocObj.Remarks = pParentDoc.Remarks;
		pDocObj.ContactPerson = pParentDoc.ContactPerson;
		pDocObj.Phone = pParentDoc.Phone;
		pDocObj.Fax = pParentDoc.Fax;
		pDocObj.EMail = pParentDoc.EMail;
		pDocObj.CreditCard = pParentDoc.CreditCard;
	EndIf;
	If ValueIsFilled(pDocObj.GuestGroup) And pDocObj.GuestGroup.OneCustomerPerGuestGroup Then
		pDocObj.Customer = pParentDoc.Customer;
		pDocObj.CustomerType = pParentDoc.CustomerType;
		pDocObj.Contract = pParentDoc.Contract;
		pDocObj.Agent = pParentDoc.Agent;
		pDocObj.AgentCommissionType = pParentDoc.AgentCommissionType;
		pDocObj.AgentCommission = pParentDoc.AgentCommission;
		pDocObj.AgentCommissionServiceGroup = pParentDoc.AgentCommissionServiceGroup;
		pDocObj.PlannedPaymentMethod = pParentDoc.PlannedPaymentMethod;
		pDocObj.ClientType = pParentDoc.ClientType;
		pDocObj.ClientTypeConfirmationText = pParentDoc.ClientTypeConfirmationText;
		pDocObj.Company = pParentDoc.Company;
		pDocObj.ChargingRules.Load(pParentDoc.ChargingRules.Unload());
	EndIf;   	
	pDocObj.ParentDoc = pParentDoc;
EndProcedure // cmFillAttributesFromParentDocument

// -----------------------------------------------------------------------------
// Description: Returns value table with active guest group documents
// Parameters: Refrence to the guest group item
// Return value: Value table with document references
// -----------------------------------------------------------------------------
Function cmGetActiveGuestGroupDocuments(pGuestGroup) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref,
	|	Reservation.PointInTime AS PointInTime,
	|	Reservation.Date AS Date
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	(Reservation.ReservationStatus.IsActive
	|			OR Reservation.ReservationStatus.IsPreliminary)
	|	AND Reservation.Posted
	|	AND Reservation.GuestGroup = &qGuestGroup
	|
	|UNION ALL
	|
	|SELECT
	|	ResourceReservation.Ref,
	|	ResourceReservation.PointInTime,
	|	ResourceReservation.Date
	|FROM
	|	Document.ResourceReservation AS ResourceReservation
	|WHERE
	|	ResourceReservation.ResourceReservationStatus.IsActive
	|	AND ResourceReservation.Posted
	|	AND ResourceReservation.GuestGroup = &qGuestGroup
	|
	|UNION ALL
	|
	|SELECT
	|	Accommodation.Ref,
	|	Accommodation.PointInTime,
	|	Accommodation.Date
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.Posted
	|	AND Accommodation.GuestGroup = &qGuestGroup
	|
	|ORDER BY
	|	Date,
	|	PointInTime";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // cmGetActiveGuestGroupDocuments 

// -----------------------------------------------------------------------------
// Description: Returns hash code used to sort documents
// Parameters: Document (accommodation or reservation) object
// Return value: Number used as sort code
// -----------------------------------------------------------------------------
Function cmCalculateReservationSortCode(pObj) Export
	// Hotel
	vHotelSortCode = "0000"; //4
	If ValueIsFilled(pObj.Hotel) Then
		vHotelSortCode = Format(pObj.Hotel.SortCode, "ND=4; NFD=0; NZ=; NLZ=; NG=");
	EndIf;
	// Guest group
	vGroupSortCode = "000000000000"; //12
	If ValueIsFilled(pObj.GuestGroup) Then
		vGroupSortCode = Format(pObj.GuestGroup.Code, "ND=12; NFD=0; NZ=; NLZ=; NG=");
	EndIf;
	// Room
	vRoomSortCode = "00000000"; //8
	If ValueIsFilled(pObj.Room) Then
		vRoomSortCode = Format(pObj.Room.SortCode, "ND=8; NFD=0; NZ=; NLZ=; NG=");
	EndIf;
	// Room type
	vRoomTypeSortCode = "00000000"; //8
	If ValueIsFilled(pObj.RoomType) Then
		vRoomTypeSortCode = Format(pObj.RoomType.SortCode, "ND=8; NFD=0; NZ=; NLZ=; NG=");
	EndIf;
	// Number
	vDocNumberSortCode = "000000000000"; //12
	If Not IsBlankString(pObj.Number) Then
		vDocNumber = 0;
		Try
			vDocNumber = Number(cmGetDocumentNumberPresentation(pObj.Number));
		Except
		EndTry;
		vDocNumberSortCode = Format(vDocNumber, "ND=12; NFD=0; NZ=; NLZ=; NG=");
	EndIf;
	// Check in date
	vCheckInDateSortCode = "000000000000"; //12
	If ValueIsFilled(pObj.CheckInDate) Then
		vCheckInDateSortCode = Format(Year(pObj.CheckInDate)*10000000 + DayOfYear(pObj.CheckInDate)*10000 + Int((pObj.CheckInDate - BegOfDay(pObj.CheckInDate))/60), "ND=12; NFD=0; NZ=; NLZ=; NG=");
	EndIf;
	// Accommodation type
	vAccommodationTypeSortCode = "0000"; //4
	If ValueIsFilled(pObj.AccommodationType) Then
		vAccommodationTypeSortCode = Format(pObj.AccommodationType.SortCode, "ND=4; NFD=0; NZ=; NLZ=; NG=");
	EndIf;
	// Build sort code as 60 chars hash
	vSortCode = vHotelSortCode + vGroupSortCode + vRoomSortCode + vRoomTypeSortCode + vDocNumberSortCode + vCheckInDateSortCode + vAccommodationTypeSortCode;
	Return vSortCode;
EndFunction // cmCalculateReservationSortCode

// -----------------------------------------------------------------------------
// Description: Function returns date to be used as default check-out date for accommodation
// Parameters: Document (accommodation or reservation) reference
// Return value: Check-out date
// -----------------------------------------------------------------------------
Function cmGetLastCheckOutDateInChain(pDocRef, pIgnoreRoomTypeChange = False) Export
	vCheckOutDate = pDocRef.CheckOutDate;
	If TypeOf(pDocRef) = Type("DocumentObject.Accommodation") Then
		vDocObj = pDocRef;
		vDocRef = pDocRef.Ref;
	Else
		vDocObj = pDocRef.GetObject();
		vDocRef = pDocRef;
	EndIf;
	If TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Then
		vParentReservation = vDocObj.pmGetParentReservation();
	Else
		vParentReservation = vDocRef;
	EndIf;
	If ValueIsFilled(vParentReservation) Then
		vParentReservationObj = vParentReservation.GetObject();
		vNextReservationInChain = vParentReservationObj.pmGetNextReservationInChain();
		While ValueIsFilled(vNextReservationInChain) Do
			If (vNextReservationInChain.RoomType = vDocRef.RoomType And Not pIgnoreRoomTypeChange) Or pIgnoreRoomTypeChange Then
				If vNextReservationInChain.CheckOutDate > vCheckOutDate Then
					vCheckOutDate = vNextReservationInChain.CheckOutDate;
				EndIf;
			Else
				Break;   
			EndIf;
			vNextReservationInChain = vNextReservationInChain.GetObject().pmGetNextReservationInChain();
		EndDo;
	EndIf;
	Return vCheckOutDate;
EndFunction // cmGetLastCheckOutDateInChain

// -----------------------------------------------------------------------------
// Description: Function returns reservation conditions for the given document
// Parameters: Document (accommodation or reservation) object
// Return value: String. Reservation conditions
// -----------------------------------------------------------------------------
Function cmGetReservationConditions(pDocObj, pLanguage) Export
	vResCond = "";
	If (TypeOf(pDocObj) = Type("DocumentObject.Reservation") Or TypeOf(pDocObj) = Type("DocumentObject.Accommodation")) And ValueIsFilled(pDocObj.RoomRate) Then
		If Not IsBlankString(pDocObj.RoomRate.ReservationConditions) Then
			vResCond = cmNStr(pDocObj.RoomRate.ReservationConditions, pLanguage);
		EndIf;
	ElsIf ValueIsFilled(pDocObj.Hotel) Then
		If Not IsBlankString(pDocObj.Hotel.ReservationConditions) Then
			vResCond = cmNStr(pDocObj.Hotel.ReservationConditions, pLanguage);
		EndIf;
	EndIf;
	If TypeOf(pDocObj) = Type("DocumentObject.Reservation") Then
		If ValueIsFilled(pDocObj.ReservationStatus) And Not IsBlankString(pDocObj.ReservationStatus.ReservationConditions) Then
			vResCond = vResCond + Chars.LF + cmNStr(pDocObj.ReservationStatus.ReservationConditions, pLanguage);
		EndIf;
	EndIf;
	Return vResCond;
EndFunction // cmGetReservationConditions

// -----------------------------------------------------------------------------
// Description: Stores information about key card being issued
// Parameters: Card type as string (New - new card, Add - additional card), 
//             Room item reference, Card issue period, 
//             Accommodation or Reservation referece, Guest item reference
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmWriteKeyCardSecuritySystemEvent(pCardType, pCardCode, pRoom, pEventDescription, pPeriodFrom, pPeriodTo, pDoc, pGuest, pNumberOfKeys = 1, pGroupOfKeys = 0) Export
	vRecMgr = InformationRegisters.SafetySystemEvents.CreateRecordManager();
	If pCardType <> "CANCEL" Then
		// Update IsActive flag if new key card is being issued
		If Upper(pCardType) = "NEW" Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	SafetySystemEvents.Period AS Period,
			|	SafetySystemEvents.Room,
			|	SafetySystemEvents.EventType,
			|	SafetySystemEvents.Hotel
			|FROM
			|	InformationRegister.SafetySystemEvents AS SafetySystemEvents
			|WHERE
			|	(SafetySystemEvents.Room = &qRoom
			|			OR SafetySystemEvents.CardCode = &qCardCode)
			|	AND SafetySystemEvents.EventType = &qEventType
			|	AND SafetySystemEvents.Hotel = &qHotel
			|	AND SafetySystemEvents.IsActive
			|
			|ORDER BY
			|	Period";
			vQry.SetParameter("qHotel", pRoom.Owner);
			vQry.SetParameter("qRoom", pRoom);
			vQry.SetParameter("qEventType", "IssueKeyCard");
			vQry.SetParameter("qCardCode", pCardCode);
			
			vActiveRows = vQry.Execute().Select();
			While vActiveRows.Next() Do
				vRecMgr.Period = vActiveRows.Period;
				vRecMgr.Room = vActiveRows.Room;
				vRecMgr.EventType = vActiveRows.EventType;
				vRecMgr.Hotel = vActiveRows.Hotel;
				vRecMgr.Read();
				If vRecMgr.Selected() Then
					vRecMgr.IsActive = False;
					vRecMgr.Write();
				EndIf;
			EndDo;
		EndIf;
		// Write record to the information register
		vRecMgr = InformationRegisters.SafetySystemEvents.CreateRecordManager();
		vRecMgr.Period = CurrentSessionDate();
		vRecMgr.Author = SessionParameters.CurrentUser;
		vRecMgr.Hotel = pRoom.Owner;
		vRecMgr.Room = pRoom;
		vRecMgr.EventType = "IssueKeyCard";
		vRecMgr.CardType = Upper(pCardType);
		vRecMgr.CardCode = pCardCode;
		vRecMgr.EventDescription = pEventDescription;
		vRecMgr.IsActive = True;
		vRecMgr.Guest = pGuest;
		vRecMgr.ParentDoc = pDoc;
		vRecMgr.PeriodFrom = pPeriodFrom;
		vRecMgr.PeriodTo = pPeriodTo;
		vRecMgr.NumberOfKeys = pNumberOfKeys;
		vRecMgr.KeysSet = pGroupOfKeys;
		vRecMgr.Write();
	Else
		// Cancel all previously issued active cards
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SafetySystemEvents.Period AS Period,
		|	SafetySystemEvents.Room,
		|	SafetySystemEvents.EventType,
		|	SafetySystemEvents.Hotel,
		|	SafetySystemEvents.IsActive
		|FROM
		|	InformationRegister.SafetySystemEvents AS SafetySystemEvents
		|WHERE
		|	(SafetySystemEvents.Room = &qRoom
		|			OR SafetySystemEvents.CardCode = &qCardCode)
		|	AND SafetySystemEvents.Hotel = &qHotel
		|	AND SafetySystemEvents.IsActive
		|
		|ORDER BY
		|	Period";
		vQry.SetParameter("qHotel", pRoom.Owner);
		vQry.SetParameter("qRoom", pRoom);
		vQry.SetParameter("qCardCode", pCardCode);
		vActiveRows = vQry.Execute().Select();
		While vActiveRows.Next() Do
			vRecMgr.Period = vActiveRows.Period;
			vRecMgr.Room = vActiveRows.Room;
			vRecMgr.EventType = vActiveRows.EventType;
			vRecMgr.Hotel = vActiveRows.Hotel;
			vRecMgr.Read();
			If vRecMgr.Selected() Then
				If vRecMgr.PeriodFrom < CurrentSessionDate() And vRecMgr.PeriodTo > CurrentSessionDate() Then
					vRecMgr.PeriodTo = CurrentSessionDate();
				EndIf;
				vRecMgr.IsActive = False;
				vRecMgr.Write();
			EndIf;
		EndDo;
		
		// Write record to the information register
		vRecMgr = InformationRegisters.SafetySystemEvents.CreateRecordManager();
		vRecMgr.Period = CurrentSessionDate();
		vRecMgr.Author = SessionParameters.CurrentUser;
		vRecMgr.Hotel = pRoom.Owner;
		vRecMgr.Room = pRoom;
		vRecMgr.EventType = "IssueKeyCard";
		vRecMgr.CardType = Upper(pCardType);
		vRecMgr.CardCode = pCardCode;
		vRecMgr.EventDescription = pEventDescription;
		vRecMgr.IsActive = False;
		vRecMgr.Guest = pGuest;
		vRecMgr.ParentDoc = pDoc;
		vRecMgr.PeriodFrom = pPeriodFrom;
		vRecMgr.PeriodTo = pPeriodTo;
		vRecMgr.NumberOfKeys = pNumberOfKeys;
		vRecMgr.KeysSet = pGroupOfKeys;
		vRecMgr.Write();
	EndIf;
EndProcedure // cmWriteKeyCardSecuritySystemEvent

// -----------------------------------------------------------------------------
// Description: This function checks character if it is valid e-mail character
// Parameters: Character
// Return value: contact person e-mail as string
// -----------------------------------------------------------------------------
Function cmIsValidEMailChar(pChar) Export
	vValidChars = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890._~!#$%&?*+-=^";
	If Find(vValidChars, pChar) > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmIsValidEMailChar

// -----------------------------------------------------------------------------
// Description: This function extracts e-mail from the contact person data
// Parameters: Contact person data as string
// Return value: contact person e-mail as string
// -----------------------------------------------------------------------------
Function cmGetContactPersonEMail(pContactPerson) Export
	vEMail = "";
	vContactPerson = TrimAll(pContactPerson);
	vAtPos = Find(vContactPerson, "@");
	If vAtPos > 1 Then
		vStart = 1;
		i = vAtPos - 1;
		While i > 0 Do
			vChar = Mid(vContactPerson, i, 1);
			If Not cmIsValidEMailChar(vChar) Then
				vStart = i + 1;
				Break;
			Else
				vStart = i;
			EndIf;
			i = i - 1;
		EndDo;
		vEnd = vAtPos + 1;
		i = vAtPos + 1;
		While i <= StrLen(vContactPerson) Do
			vChar = Mid(pContactPerson, i, 1);
			If Not cmIsValidEMailChar(vChar) Then
				vEnd = i - 1;
				Break;
			Else
				vEnd = i;
			EndIf;
			i = i + 1;
		EndDo;
		vLen = vEnd - vStart + 1;
		vEMail = Mid(vContactPerson, vStart, vLen);
	EndIf;
	Return vEMail;
EndFunction // cmGetContactPersonEMail

// -----------------------------------------------------------------------------
// Description: Returns icon of the given room status
// Parameters: Room status 
// Return value: Picture object
// -----------------------------------------------------------------------------
Function cmGetRoomStatusIcon(pRoomStatus) Export
	vPicture = PictureLib.Empty;
	If ValueIsFilled(pRoomStatus) Then
		If ValueIsFilled(pRoomStatus.RoomStatusIcon) Then
			If pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.None Then
				vPicture = PictureLib.Empty;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Reserved Then
				vPicture = PictureLib.RoomStatusReserved;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
				vPicture = PictureLib.Occupied;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
				vPicture = PictureLib.OccupiedDirty;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
				vPicture = PictureLib.Waiting;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
				vPicture = PictureLib.RoomStatusCleaning;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Then
				vPicture = PictureLib.TidyingUp;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
				vPicture = PictureLib.Vacant;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
				vPicture = PictureLib.RoomStatusRepair;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Luggage Then
				vPicture = PictureLib.RoomStatusLuggage;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Then
				vPicture = PictureLib.RoomStatusMalfunction;
			EndIf;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // cmGetRoomStatusIcon

// -----------------------------------------------------------------------------
// Description: Returns default accommodation type for the given room type and hotel
// Parameters: Hotel item reference, Room type item reference  
// Return value: Accommodation type reference
// -----------------------------------------------------------------------------
Function cmGetDefaultAccommodationType(pHotel, pRoomType) Export
	vAccommodationType = Catalogs.AccommodationTypes.EmptyRef();
	If ValueIsFilled(pRoomType) And Not pRoomType.IsFolder And ValueIsFilled(pRoomType.AccommodationType) Then
		vAccommodationType = pRoomType.AccommodationType;
	ElsIf ValueIsFilled(pHotel) And Not pHotel.IsFolder And ValueIsFilled(pHotel.AccommodationType) Then
		vAccommodationType = pHotel.AccommodationType;
	Else
		vAccommodationType = cmGetAccommodationTypeRoom(pHotel);
	EndIf;
	Return vAccommodationType;
EndFunction // cmGetDefaultAccommodationType

// -----------------------------------------------------------------------------
// Returns earliest active reservation check-in date for the given hotel
// -----------------------------------------------------------------------------
Function cmGetMinCheckInDate(pHotel) Export
	vMinDate = BegOfDay(CurrentSessionDate());
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	MIN(Reservation.CheckInDate) AS CheckInDate
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.CheckInDate <= &qEndOfToday
	|	AND Reservation.Hotel IN HIERARCHY (&qHotel)
	|	AND Reservation.Posted
	|	AND Reservation.ReservationStatus.IsActive";
	vQry.SetParameter("qEndOfToday", EndOfDay(CurrentSessionDate()));
	vQry.SetParameter("qHotel", pHotel);
	vResults = vQry.Execute().Unload();
	If vResults.Count() > 0 Then
		vMinCheckInDate = vResults.Get(0).CheckInDate;
		If TypeOf(vMinCheckInDate) = Type("Date") And ValueIsFilled(vMinCheckInDate) Then
			vMinDate = BegOfDay(vMinCheckInDate);
		EndIf;
	EndIf;
	Return vMinDate;
EndFunction // cmGetMinCheckInDate 

// -----------------------------------------------------------------------------
// Returns reservation create date for given accommodation or reservation
// -----------------------------------------------------------------------------
Function cmGetReservationCreateDate(pDocRef) Export
	vCreateDate = '00010101';
	If ValueIsFilled(pDocRef) Then
		If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") And ValueIsFilled(pDocRef.Reservation) Then
			vCreateDate = pDocRef.Reservation.Date;
		Else
			vCreateDate = pDocRef.Date;
		EndIf;
	EndIf;
	Return vCreateDate;
EndFunction // cmGetReservationCreateDate

// -----------------------------------------------------------------------------
// Returns value list with all active rooms for the given hotel ref
// -----------------------------------------------------------------------------
Function cmGetActiveRoomsList(pHotel = Undefined) Export
	vList = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Rooms.Ref
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.IsFolder
	|	AND NOT Rooms.DeletionMark
	|	AND Rooms.OperationStartDate <= &qDate
	|	AND (Rooms.OperationEndDate >= &qDate
	|			OR Rooms.OperationEndDate = &qEmptyDate)
	|	AND (NOT &qHotelIsEmpty
	|				AND Rooms.Owner = &qHotel
	|			OR &qHotelIsEmpty)
	|
	|ORDER BY
	|	Rooms.SortCode";
	vQry.SetParameter("qDate", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vRooms = vQry.Execute().Unload();
	If vRooms.Count() > 0 Then
		vList.LoadValues(vRooms.UnloadColumn("Ref"));
	EndIf;
	Return vList;
EndFunction // cmGetActiveRoomsList

// -----------------------------------------------------------------------------
// Returns remarks presentation for the reservation
// -----------------------------------------------------------------------------
Function cmGetRemarks(pRemarks, pRoomType, rIsHousekeepingRemarks) Export
	vRemarks = "";
	rIsHousekeepingRemarks = False;
	vGetFromXML = False;
	If Lower(Left(pRemarks, 9)) = Lower("<Remarks>") Then
		vGetFromXML = True;
	ElsIf Lower(Left(pRemarks, 21)) = Lower("<HousekeepingRemarks>") Then
		vGetFromXML = True;
		rIsHousekeepingRemarks = True;
	EndIf;
	If vGetFromXML Then
		vReader = New XMLReader;
		vReader.SetString(pRemarks);
		vDOMBuilder = New DOMBuilder;
		vDOMRemarks = vDOMBuilder.Read(vReader);
		If ValueIsFilled(pRoomType) Then
			vRTRemarks = vDOMRemarks.GetElementByTagName(TrimAll(pRoomType.Code));
			If vRTRemarks.Count() = 1 Then 
				vRemarks = TrimAll(vRTRemarks.Item(0).TextContent);
			Else
				vRTRemarks = vDOMRemarks.GetElementByTagName("Other");
				If vRTRemarks.Count() = 1 Then 
					vRemarks = TrimAll(vRTRemarks.Item(0).TextContent);
				EndIf;
			EndIf;
		Else
			vRTRemarks = vDOMRemarks.GetElementByTagName("Other");
			If vRTRemarks.Count() = 1 Then 
				vRemarks = TrimAll(vRTRemarks.Item(0).TextContent);
			EndIf;
		EndIf;
	Else
		vRemarks = TrimAll(pRemarks);
	EndIf;
	Return vRemarks;
EndFunction // cmGetRemarks

// -----------------------------------------------------------------------------
// Returns vindow views for the hotel
// -----------------------------------------------------------------------------
Function cmGetWindowViews(pHotel) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomProperties.Ref
	|FROM
	|	Catalog.RoomProperties AS RoomProperties
	|WHERE
	|	RoomProperties.IsView
	|	AND (RoomProperties.Hotel = &qHotel
	|			OR RoomProperties.Hotel = &qEmptyHotel)
	|	AND NOT RoomProperties.DeletionMark
	|	AND NOT RoomProperties.IsFolder
	|
	|ORDER BY
	|	RoomProperties.SortCode,
	|	RoomProperties.Description";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vViews = vQry.Execute().Unload();
	Return vViews;
EndFunction // cmGetWindowViews

// -----------------------------------------------------------------------------
// Returns room types with vindow views for the hotel
// -----------------------------------------------------------------------------
Function cmGetRoomTypesWithViews(pHotel) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomTypes.Ref
	|FROM
	|	Catalog.RoomTypes AS RoomTypes
	|WHERE
	|	RoomTypes.WindowView <> &qEmptyWindowView
	|	AND RoomTypes.Owner = &qHotel
	|	AND NOT RoomTypes.DeletionMark
	|	AND NOT RoomTypes.IsFolder
	|
	|ORDER BY
	|	RoomTypes.SortCode,
	|	RoomTypes.Description";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyWindowView", Catalogs.RoomProperties.EmptyRef());
	vRoomTypes = vQry.Execute().Unload();
	Return vRoomTypes;
EndFunction // cmGetRoomTypesWithViews

// -----------------------------------------------------------------------------
Function cmGetClientAge(pDateOfBirth, pCheckInDate) Export
	If Not ValueIsFilled(pDateOfBirth) Then
		Return 0;
	EndIf;
	If Not ValueIsFilled(pCheckInDate) Then
		Return 0;
	EndIf;
	vAge = Year(pCheckInDate) - Year(pDateOfBirth) - 1;
	vBirthDateDayOfYear = DayOfYear(pDateOfBirth);
	vDateDayOfYear = DayOfYear(pCheckInDate);
	If vDateDayOfYear >= vBirthDateDayOfYear Then
		vAge = vAge + 1;
	EndIf;
	If vAge < 0 Then
		vAge = 0;
	EndIf;
	Return vAge;
EndFunction // cmGetClientAge

// -----------------------------------------------------------------------------
Function cmGetAccommodationByReservation(pReservation) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodations.Ref
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Reservation = &qReservation
	|	AND Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|ORDER BY
	|	Accommodations.PointInTime DESC";
	vQry.SetParameter("qReservation", pReservation);
	vAccDocs = vQry.Execute().Unload();
	If vAccDocs.Count() > 0 Then
		Return vAccDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetAccommodations

// -----------------------------------------------------------------------------
Function cmGetPendingSpecialOffersForReservation(pReservation, pRoomTypeUpgradeOffersOnly = False) Export
	If Not ValueIsFilled(pReservation) Then
		Return New ValueTable();
	EndIf;
	vReservation = Undefined;
	vAccommodation = Undefined;
	If TypeOf(pReservation) = Type("DocumentRef.Accommodation") Then
		vAccommodation = pReservation;
		If ValueIsFilled(vAccommodation.Reservation) Then
			vReservation = vAccommodation.Reservation;
		EndIf;
	Else
		vReservation = pReservation;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	SpecialOffers.SpecialOffer AS SpecialOffer
	|FROM
	|	(SELECT
	|		SpecialOffersForReservations.SpecialOffer AS SpecialOffer
	|	FROM
	|		InformationRegister.SpecialOffersForReservations AS SpecialOffersForReservations
	|	WHERE
	|		SpecialOffersForReservations.OfferStatus = VALUE(Enum.OfferStatuses.Pending)
	|		AND (SpecialOffersForReservations.GuestGroup = &qGuestGroup
	|					AND SpecialOffersForReservations.GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|				OR SpecialOffersForReservations.ParentDoc = &qReservation
	|					AND NOT SpecialOffersForReservations.ParentDoc.Number IS NULL
	|				OR SpecialOffersForReservations.ParentDoc = &qAccommodation
	|					AND NOT SpecialOffersForReservations.ParentDoc.Number IS NULL)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SpecialOffersForClients.SpecialOffer
	|	FROM
	|		InformationRegister.SpecialOffersForClients AS SpecialOffersForClients
	|	WHERE
	|		SpecialOffersForClients.OfferStatus = VALUE(Enum.OfferStatuses.Pending)
	|		AND (&qCustomerIsFilled
	|					AND SpecialOffersForClients.Customer = &qCustomer
	|				OR &qClientIsFilled
	|					AND SpecialOffersForClients.Client = &qClient)) AS SpecialOffers
	|		INNER JOIN InformationRegister.SpecialOfferPeriods AS SpecialOfferPeriods
	|		ON SpecialOffers.SpecialOffer = SpecialOfferPeriods.SpecialOffer
	|			AND (SpecialOfferPeriods.Hotel = &qHotel
	|				OR SpecialOfferPeriods.Hotel = &qHotelParent
	|					AND &qHotelParent <> VALUE(Catalog.Hotels.EmptyRef)
	|				OR SpecialOfferPeriods.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|			AND (SpecialOfferPeriods.DateValidFrom <= &qDate)
	|			AND (SpecialOfferPeriods.DateValidTo = &qEmptyDate
	|				OR SpecialOfferPeriods.DateValidTo >= &qDate)
	|			AND (SpecialOfferPeriods.CheckInDateFrom <= &qCheckInDate)
	|			AND (SpecialOfferPeriods.CheckInDateTo = &qEmptyDate
	|				OR SpecialOfferPeriods.CheckInDateTo >= &qCheckInDate)
	|			AND (NOT SpecialOfferPeriods.ApplyToDatesInsidePeriodOfStayOnly
	|					AND SpecialOfferPeriods.PeriodOfStayFrom <= &qCheckInDate
	|					AND (SpecialOfferPeriods.PeriodOfStayTo = &qEmptyDate
	|						OR SpecialOfferPeriods.PeriodOfStayTo >= &qCheckOutDate)
	|				OR SpecialOfferPeriods.ApplyToDatesInsidePeriodOfStayOnly
	|					AND SpecialOfferPeriods.PeriodOfStayFrom < &qCheckOutDate
	|					AND (SpecialOfferPeriods.PeriodOfStayTo = &qEmptyDate
	|						OR SpecialOfferPeriods.PeriodOfStayTo > &qCheckInDate))
	|WHERE
	|	NOT SpecialOffers.SpecialOffer.DeletionMark
	|	AND NOT SpecialOffers.SpecialOffer.IsFolder
	|
	|GROUP BY
	|	SpecialOffers.SpecialOffer
	|
	|ORDER BY
	|	SpecialOffers.SpecialOffer.Code";
	vQry.SetParameter("qHotel", vReservation.Hotel);
	vQry.SetParameter("qHotelParent", vReservation.Hotel.Parent);
	vQry.SetParameter("qReservation", vReservation);
	vQry.SetParameter("qAccommodation", vAccommodation);
	vQry.SetParameter("qGuestGroup", vReservation.GuestGroup);
	vQry.SetParameter("qCustomer", vReservation.Customer);
	vQry.SetParameter("qCustomerIsFilled", ValueIsFilled(vReservation.Customer));
	vQry.SetParameter("qClient", vReservation.Customer);
	vQry.SetParameter("qClientIsFilled", ValueIsFilled(vReservation.Guest));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qDate", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qCheckInDate", BegOfDay(vReservation.CheckInDate));
	vQry.SetParameter("qCheckOutDate", BegOfDay(vReservation.CheckOutDate));
	vOffers = vQry.Execute().Unload();
	// Leave room type upgrade offers only
	If pRoomTypeUpgradeOffersOnly Then
		i = 0;
		While i < vOffers.Count() Do
			If vOffers.Get(i).SpecialOffer.RoomTypeUpgrades.Count() = 0 Then
				vOffers.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	Return vOffers;	
EndFunction // cmGetPendingSpecialOffersForReservation

// -----------------------------------------------------------------------------
Function cmGetConfirmedSpecialOffersForReservation(pParentDoc, pHotel, pRoomRate, pRoomRateType, pClient, pClientType, pCustomer, pCustomerType, pGuestGroup, pSourceOfBusiness, pMarketingCode, pTripPurpose, pCheckInDate, pDuration, pCheckOutDate, pReservationDate, pRoomType, pAccommodationType = Undefined) Export
	// Call cached function
	Return CachedAccounts.GetConfirmedSpecialOffersForReservation(pParentDoc, pHotel, pRoomRate, pRoomRateType, pClient, pClientType, pCustomer, pCustomerType, pGuestGroup, pSourceOfBusiness, pMarketingCode, pTripPurpose, pCheckInDate, pDuration, pCheckOutDate, pReservationDate, pRoomType, pAccommodationType);
EndFunction // cmGetConfirmedSpecialOffersForReservation

// -----------------------------------------------------------------------------
Function cmGetDataProcessorForExportGuestDataToUFMS(pHotel) Export
	vDPRef = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	DataProcessors.Ref AS Ref
	|FROM
	|	Catalog.DataProcessors AS DataProcessors
	|WHERE
	|	DataProcessors.Processing = ""ExportGuestsToUFMSTerritoryApp""
	|	AND NOT DataProcessors.IsFolder
	|	AND NOT DataProcessors.DeletionMark
	|	AND (DataProcessors.Hotel = &qHotel
	|			OR DataProcessors.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|
	|ORDER BY
	|	DataProcessors.Code DESC";
	vQry.SetParameter("qHotel", pHotel);
	vDPs = vQry.Execute().Unload();
	If vDPs.Count() > 0 Then
		vDPRef = vDPs.Get(0).Ref;
	EndIf;
	Return vDPRef;
EndFunction // cmGetDataProcessorForExportGuestDataToUFMS

// -----------------------------------------------------------------------------
Function cmGetAccommodationTemplateByDocsArray(pDocsArray, pRoomType, pHotel, pIsForFolioSplit = Undefined) Export
	vAccTemplate = Undefined;
	vIsForFolioSplit = False;
	If pIsForFolioSplit <> Undefined Then
		vIsForFolioSplit = pIsForFolioSplit;
	EndIf;
	vFirstDoc = Undefined;
	vAdults = 0;
	vChildren = 0;
	vChildrenAges = New Array();
	For Each vDoc In pDocsArray Do
		If vFirstDoc = Undefined Then
			vFirstDoc = vDoc;
		EndIf;
		If vDoc.GuestAge <> 0 Then
			vChildren = vChildren + 1;
			vChildrenAges.Add(vDoc.GuestAge);
		Else
			vAdults = vAdults + 1;
		EndIf;
		If pIsForFolioSplit = Undefined Then
			If ValueIsFilled(vDoc.AccommodationType) And vDoc.AccommodationType.Type = Enums.AccomodationTypes.Beds Then
				vIsForFolioSplit = True;
			EndIf;
		EndIf;
	EndDo;
	// Children ages structure
	vAgesStruct = Undefined;
	If ValueIsFilled(vFirstDoc) Then
		If ValueIsFilled(vFirstDoc.Contract) Then
			vAllotmentContract = vFirstDoc.Contract;
			If vAllotmentContract.TeenagersMaxAge <> 0 Or vAllotmentContract.ChildrenMaxAge <> 0 Or vAllotmentContract.InfantsMaxAge <> 0 Then
				vAgesStruct = vAllotmentContract;
			EndIf;
		EndIf;
		// Get active special offers
		If pHotel.TeenagersMaxAge <> 0 Or pHotel.ChildrenMaxAge <> 0 Or pHotel.InfantsMaxAge <> 0 Then
			vOffers = cmGetConfirmedSpecialOffersForReservation(vFirstDoc, vFirstDoc.Hotel, vFirstDoc.RoomRate, vFirstDoc.RoomRateType, vFirstDoc.Guest, vFirstDoc.ClientType, vFirstDoc.Customer, vFirstDoc.CustomerType, vFirstDoc.GuestGroup, vFirstDoc.SourceOfBusiness, vFirstDoc.MarketingCode, vFirstDoc.TripPurpose, vFirstDoc.CheckInDate, vFirstDoc.Duration, vFirstDoc.CheckOutDate, ?(ValueIsFilled(vFirstDoc.GuestGroup), vFirstDoc.GuestGroup.CreateDate, vFirstDoc.Date), vFirstDoc.RoomType);
			For Each vOffersRow In vOffers Do
				vOffer = vOffersRow.SpecialOffer;
				If vOffer.TeenagersMaxAge <> 0 Or vOffer.ChildrenMaxAge <> 0 Or vOffer.InfantsMaxAge <> 0 Then
					vAgesStruct = vOffer;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	// Get template taking "Is for folio split" flag into account
	vAccTemplates = cmGetAccommodationTemplateDetailsByGuestsQuantity(vAdults, vChildren, vChildrenAges, pHotel, False, vAgesStruct);
	For Each vAccTemplatesRow In vAccTemplates Do
		vCurAccTemplate = vAccTemplatesRow.AccommodationTemplate;
		If vCurAccTemplate.IsForFolioSplit = vIsForFolioSplit Then
			If ValueIsFilled(pRoomType) And vCurAccTemplate.RoomTypes.Count() > 0 Then
				If vCurAccTemplate.RoomTypes.Find(pRoomType, "RoomType") = Undefined Then
					If ValueIsFilled(pRoomType.RoomClass) Then
						If vCurAccTemplate.RoomTypes.Find(pRoomType.RoomClass, "RoomClass") = Undefined Then
							Continue;
						EndIf;
					Else
						Continue;
					EndIf;
				EndIf;
			EndIf;
			vAccTemplate = vCurAccTemplate;
			Break;
		EndIf;
	EndDo;
	If Not ValueIsFilled(vAccTemplate) And vIsForFolioSplit Then
		For Each vAccTemplatesRow In vAccTemplates Do
			vCurAccTemplate = vAccTemplatesRow.AccommodationTemplate;
			If ValueIsFilled(pRoomType) And vCurAccTemplate.RoomTypes.Count() > 0 Then
				If vCurAccTemplate.RoomTypes.Find(pRoomType, "RoomType") = Undefined Then
					If ValueIsFilled(pRoomType.RoomClass) Then
						If vCurAccTemplate.RoomTypes.Find(pRoomType.RoomClass, "RoomClass") = Undefined Then
							Continue;
						EndIf;
					Else
						Continue;
					EndIf;
				EndIf;
			EndIf;
			vAccTemplate = vCurAccTemplate;
			Break;
		EndDo;
	EndIf;
	Return vAccTemplate;
EndFunction // cmGetAccommodationTemplateByDocsArray

// -----------------------------------------------------------------------------
Function cmGetAccommodationTemplateForSkippedExtraBeds(pAccommodationTemplate) Export
	vAccommodationTemplate = pAccommodationTemplate;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BaseTemplateAccTypes.Ref AS Ref,
	|	BaseTemplateAccTypes.AccommodationType AS AccommodationType,
	|	1 AS Count
	|INTO BaseTemplateAccTypes
	|FROM
	|	Catalog.AccommodationTemplates.AccommodationTypes AS BaseTemplateAccTypes
	|WHERE
	|	BaseTemplateAccTypes.Ref = &qAccommodationTemplate
	|	AND BaseTemplateAccTypes.AccommodationType.Type <> VALUE(Enum.AccomodationTypes.AdditionalBed)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TargetTemplateAccTypesCount.Ref AS Ref,
	|	SUM(TargetTemplateAccTypesCount.Count) AS TargetCount
	|INTO TargetTemplateAccTypesCount
	|FROM
	|	BaseTemplateAccTypes AS TargetTemplateAccTypesCount
	|
	|GROUP BY
	|	TargetTemplateAccTypesCount.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllTemplatesAccTypes.Ref AS Ref,
	|	AllTemplatesAccTypes.AccommodationType AS AccommodationType,
	|	1 AS Count
	|INTO AllTemplatesAccTypes
	|FROM
	|	Catalog.AccommodationTemplates.AccommodationTypes AS AllTemplatesAccTypes
	|WHERE
	|	NOT AllTemplatesAccTypes.Ref.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllTemplatesAccTypesCount.Ref AS Ref,
	|	SUM(AllTemplatesAccTypesCount.Count) AS AllCount
	|INTO AllTemplatesAccTypesCount
	|FROM
	|	AllTemplatesAccTypes AS AllTemplatesAccTypesCount
	|
	|GROUP BY
	|	AllTemplatesAccTypesCount.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SuitableTemplatesByCount.Ref AS Ref,
	|	SuitableTemplatesByCount.AllCount AS AllCount
	|INTO SuitableTemplatesByCount
	|FROM
	|	AllTemplatesAccTypesCount AS SuitableTemplatesByCount
	|		INNER JOIN TargetTemplateAccTypesCount AS TargetTemplateAccTypesCount
	|		ON (TargetTemplateAccTypesCount.TargetCount = SuitableTemplatesByCount.AllCount)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SuitableTemplatesAccTypes.Ref AS Ref,
	|	SuitableTemplatesAccTypes.AccommodationType AS AccommodationType,
	|	BaseTemplateAccTypes.AccommodationType AS AccommodationType1
	|INTO SuitableTemplatesAccTypes
	|FROM
	|	Catalog.AccommodationTemplates.AccommodationTypes AS SuitableTemplatesAccTypes
	|		LEFT JOIN BaseTemplateAccTypes AS BaseTemplateAccTypes
	|		ON SuitableTemplatesAccTypes.AccommodationType = BaseTemplateAccTypes.AccommodationType
	|		INNER JOIN SuitableTemplatesByCount AS SuitableTemplatesByCount
	|		ON (SuitableTemplatesByCount.Ref = SuitableTemplatesAccTypes.Ref)
	|WHERE
	|	NOT BaseTemplateAccTypes.AccommodationType IS NULL
	|;
	|
	|SELECT 
	|	SuitableTemplates.Ref
	|FROM
	|	SuitableTemplatesAccTypes AS SuitableTemplates
	|GROUP BY
	|	SuitableTemplates.Ref";
	vQry.SetParameter("qAccommodationTemplate", pAccommodationTemplate);
	vTemplates = vQry.Execute().Unload();
	For Each vTemplatesRow In vTemplates Do
		vTemplate = vTemplatesRow.Ref;
		If vTemplate.RoomTypes.Count() = 0 Then
			vAccommodationTemplate = vTemplate;
			Break;
		Else
			If vTemplate.RoomTypes.Count() = pAccommodationTemplate.RoomTypes.Count() Then
				vGood = True;
				For Each vATRTRow In pAccommodationTemplate.RoomTypes Do
					vFound = False;
					For Each vTRTRow In vTemplate.RoomTypes Do
						If vTRTRow.RoomClass = vATRTRow.RoomClass And vTRTRow.RoomType = vATRTRow.RoomType Then
							vFound = True;
							Break;
						EndIf;
					EndDo;
					If Not vFound Then
						vGood = False;
						Break;
					EndIf;
				EndDo;
				If vGood Then
					vAccommodationTemplate = vTemplate;
					Break;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	Return vAccommodationTemplate;
EndFunction // cmGetAccommodationTemplateForSkippedExtraBeds

// ------------------------------------------------------------------------------------------------
Function cmGetLastProformaForTheGroup(pGuestGroup) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Proformas.GuestGroup AS GuestGroup,
	|	MAX(Proformas.Number) AS MaxNumber
	|INTO MaxProformaNumber
	|FROM
	|	Document.ProformaInvoice AS Proformas
	|WHERE
	|	Proformas.GuestGroup = &qGuestGroup
	|	AND Proformas.Posted
	|
	|GROUP BY
	|	Proformas.GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LastProforma.GuestGroup AS GuestGroup,
	|	LastProforma.Ref AS Ref
	|FROM
	|	Document.ProformaInvoice AS LastProforma
	|		INNER JOIN MaxProformaNumber AS MaxProformaNumber
	|		ON LastProforma.GuestGroup = MaxProformaNumber.GuestGroup
	|			AND LastProforma.Number = MaxProformaNumber.MaxNumber
	|
	|ORDER BY
	|	LastProforma.GuestGroup.Code,
	|	LastProforma.Number";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vProformas = vQry.Execute().Unload();
	If vProformas.Count() > 0 Then
		Return vProformas.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetLastProformaForTheGroup

// -----------------------------------------------------------------------------
// Description: Returnes value table with periods when room is vacant (number of vacant beds greater then 0)
// Parameters: Room,
//             Period from date, period to date
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetRoomVacantPeriods(pRoom, pPeriodFrom, pPeriodTo) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalanceAndTurnovers.Hotel AS Hotel,
	|	RoomInventoryBalanceAndTurnovers.Room AS Room,
	|	RoomInventoryBalanceAndTurnovers.RoomType AS RoomType,
	|	RoomInventoryBalanceAndTurnovers.Period AS PeriodFrom,
	|	RoomInventoryBalanceAndTurnovers.Period AS PeriodTo,
	|	RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance AS RoomsVacant,
	|	RoomInventoryBalanceAndTurnovers.BedsVacantClosingBalance AS BedsVacant
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Minute, RegisterRecordsAndPeriodBoundaries, Room = &qRoom) AS RoomInventoryBalanceAndTurnovers
	|
	|ORDER BY
	|	RoomInventoryBalanceAndTurnovers.Period";
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qRoom", pRoom);
	vPeriods = vQry.Execute().Unload();
	i = 0;
	While i < vPeriods.Count() Do
		vPeriodsRow = vPeriods.Get(i);
		If i > 0 Then
			vPrevPeriodsRow = vPeriods.Get(i - 1);
			vPrevPeriodsRow.PeriodTo = cm0SecondShift(vPeriodsRow.PeriodFrom);
			If vPrevPeriodsRow.PeriodTo <= vPrevPeriodsRow.PeriodFrom Then
				vPeriods.Delete(vPrevPeriodsRow);
			Else
				i = i + 1;
			EndIf;
		Else
			i = i + 1;
		EndIf;
	EndDo;
	If vPeriods.Count() > 0 Then
		vPeriods.Delete(vPeriods.Count() - 1);
	EndIf;
	i = 0;
	While i < vPeriods.Count() Do
		vPeriodsRow = vPeriods.Get(i);
		If vPeriodsRow.BedsVacant <= 0 And vPeriodsRow.RoomsVacant <= 0 Then
			vPeriods.Delete(vPeriodsRow);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	Return vPeriods;
EndFunction // cmGetRoomVacantPeriods

// -----------------------------------------------------------------------------
// Description: Returnes main connect room for the given room
// Parameters: Room
// Return value: Connect room
// -----------------------------------------------------------------------------
Function cmGetConnectRoom(pRoom) Export
	vConnectRoom = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomsConnectedRooms.Ref AS Ref
	|FROM
	|	Catalog.Rooms.ConnectedRooms AS RoomsConnectedRooms
	|WHERE
	|	RoomsConnectedRooms.Room = &qRoom
	|	AND NOT RoomsConnectedRooms.Ref.DeletionMark
	|
	|ORDER BY
	|	RoomsConnectedRooms.Ref.SortCode";
	vQry.SetParameter("qRoom", pRoom);
	vRooms = vQry.Execute().Unload();
	For Each vRoomsRow In vRooms Do
		vConnectRoom = vRoomsRow.Ref;
		Break;
	EndDo;
	Return vConnectRoom;
EndFunction // cmGetConnectRoom

// -----------------------------------------------------------------------------
Function cmGetChargingRuleDescription(pChargingRuleRow, pLanguage) Export
	vCRName = "";
	If pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.InRate Then
		vCRName = cmNStr("en='Room rate services'; ru='Услуги включенные в тариф'; de='Zimmerpreis Dienstleistungen'", pLanguage);
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.InServiceGroup Then
		vCRName = cmNStr("en='Services in '; ru='Услуги в наборе '; de='Dienstleistungen im Set '", pLanguage);
		If ValueIsFilled(pChargingRuleRow.ChargingRuleValue) And TypeOf(pChargingRuleRow.ChargingRuleValue) = Type("CatalogRef.ServiceGroups") Then
			If Not IsBlankString(pChargingRuleRow.ChargingRuleValue.Remarks) And cmNStr(TrimAll(pChargingRuleRow.ChargingRuleValue.Remarks), pLanguage) <> TrimAll(pChargingRuleRow.ChargingRuleValue.Remarks) Then
				vCRName = vCRName + " " + cmNStr(TrimAll(pChargingRuleRow.ChargingRuleValue.Remarks), pLanguage);
			Else
				vCRName = vCRName + " " + TrimAll(pChargingRuleRow.ChargingRuleValue);
			EndIf;
		EndIf;
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.One Then
		vCRName = cmNStr("en='Service '; ru='Услуга '; de='Dienstleistung '", pLanguage);
		If ValueIsFilled(pChargingRuleRow.ChargingRuleValue) And TypeOf(pChargingRuleRow.ChargingRuleValue) = Type("CatalogRef.Services") Then
			vCRName = vCRName + " " + pChargingRuleRow.ChargingRuleValue.GetObject().pmGetServiceDescription(pLanguage);
		EndIf;
	EndIf;
	Return TrimAll(vCRName);
EndFunction // cmGetChargingRuleDescription

// -----------------------------------------------------------------------------
Procedure cmAddRoomsToAllotment(pRoomQuota, pRoomRate, pRoomType, pPeriodFrom, pPeriodTo, pRoomQuantity) Export
	// Create new "Set room quota" document and fill it's parameters for each period in chain
	vDocObj = Documents.SetRoomQuota.CreateDocument();
	
	vDocObj.RoomQuota = pRoomQuota;
	vDocObj.BaseRoomQuota = pRoomQuota.BaseRoomQuota;
	If ValueIsFilled(vDocObj.RoomQuota.Hotel) Then
		vDocObj.Hotel = vDocObj.RoomQuota.Hotel;
	EndIf;
	vDocObj.RoomType = pRoomType;
	If Not ValueIsFilled(vDocObj.Hotel) Or vDocObj.Hotel <> vDocObj.RoomType.Owner Then
		vDocObj.Hotel = vDocObj.RoomType.Owner;
	EndIf;
	vDocObj.SetRoomQuotaType = ?(pRoomQuantity < 0, Enums.SetRoomQuotaTypes.Remove, Enums.SetRoomQuotaTypes.Add);
	vDocObj.DateFrom = cm0SecondShift(pPeriodFrom);
	vDocObj.pmFillAttributesWithDefaultValues();
	vDocObj.NumberOfBedsPerRoom = vDocObj.RoomType.NumberOfBedsPerRoom;
	vDocObj.NumberOfPersonsPerRoom = vDocObj.RoomType.NumberOfPersonsPerRoom;
	vDocObj.DateTo = cm0SecondShift(pPeriodTo);
	vDocObj.Duration = vDocObj.pmCalculateDuration();
	vDocObj.NumberOfRooms = ?(pRoomQuantity < 0, -pRoomQuantity, pRoomQuantity);
	vDocObj.NumberOfBeds = vDocObj.NumberOfRooms * vDocObj.NumberOfBedsPerRoom;
	vDocObj.IsForecast = False;
	
	vDocObj.Write(DocumentWriteMode.Posting);
EndProcedure // cmAddRoomsToAllotment

// -----------------------------------------------------------------------------
Function cmGetOtherGroupDocumentsRateSum(pGuestGroup) Export
	vRateSum = 0;
	If ValueIsFilled(pGuestGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(GroupDocs.RateSumInBaseCurrency) AS RateSumInBaseCurrency
		|FROM
		|	(SELECT
		|		Accommodations.RateSumInBaseCurrency AS RateSumInBaseCurrency
		|	FROM
		|		Document.Accommodation AS Accommodations
		|	WHERE
		|		Accommodations.GuestGroup = &qGuestGroup
		|		AND Accommodations.Posted
		|		AND Accommodations.AccommodationStatus.IsActive
		|		AND Accommodations.Ref <> &qGroupClientDoc
		|		AND Accommodations.Reservation <> &qGroupClientDoc
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Reservations.RateSumInBaseCurrency
		|	FROM
		|		Document.Reservation AS Reservations
		|	WHERE
		|		Reservations.GuestGroup = &qGuestGroup
		|		AND Reservations.Posted
		|		AND (Reservations.ReservationStatus.IsActive
		|				OR Reservations.ReservationStatus.IsPreliminary)
		|		AND NOT Reservations.ReservationStatus.IsCheckIn
		|		AND Reservations.Ref <> &qGroupClientDoc) AS GroupDocs";
		vQry.SetParameter("qGuestGroup", pGuestGroup);
		vQry.SetParameter("qGroupClientDoc", pGuestGroup.ClientDoc);
		vRes = vQry.Execute().Unload();
		For Each vResRow In vRes Do
			If vResRow.RateSumInBaseCurrency <> Null Then
				vRateSum = vRateSum + vResRow.RateSumInBaseCurrency;
			EndIf;
		EndDo;
	EndIf;
	Return vRateSum;
EndFunction // cmGetOtherGroupDocumentsRateSum

// -----------------------------------------------------------------------------
Function cmGetOtherRoomDocumentsRateSum(pRoomDoc) Export
	vRateSum = 0;
	If ValueIsFilled(pRoomDoc) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomDocs.RateSumInBaseCurrency, 0)) AS RateSumInBaseCurrency
		|FROM
		|	(SELECT
		|		Accommodations.RateSumInBaseCurrency AS RateSumInBaseCurrency
		|	FROM
		|		Document.Accommodation AS Accommodations
		|	WHERE
		|		Accommodations.GuestGroup = &qGuestGroup
		|		AND Accommodations.Number = &qNumber
		|		AND NOT Accommodations.IsForFolioSplit
		|		AND Accommodations.Posted
		|		AND Accommodations.AccommodationStatus.IsActive
		|		AND NOT ISNULL(Accommodations.AccommodationType.DoNotMergeTouristTaxBaseToTheMainRoomGuest, FALSE)
		|		AND NOT ISNULL(Accommodations.RoomRate.DoNotMergeTouristTaxBaseToTheMainRoomGuest, FALSE)
		|		AND NOT ISNULL(Accommodations.RoomRateType.DoNotMergeTouristTaxBaseToTheMainRoomGuest, FALSE)
		|		AND Accommodations.Ref <> &qRoomDoc
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Reservations.RateSumInBaseCurrency
		|	FROM
		|		Document.Reservation AS Reservations
		|	WHERE
		|		Reservations.GuestGroup = &qGuestGroup
		|		AND Reservations.Number = &qNumber
		|		AND NOT Reservations.IsForFolioSplit
		|		AND Reservations.Posted
		|		AND (Reservations.ReservationStatus.IsActive
		|				OR Reservations.ReservationStatus.IsPreliminary)
		|		AND NOT Reservations.ReservationStatus.IsCheckIn
		|		AND NOT ISNULL(Reservations.AccommodationType.DoNotMergeTouristTaxBaseToTheMainRoomGuest, FALSE)
		|		AND NOT ISNULL(Reservations.RoomRate.DoNotMergeTouristTaxBaseToTheMainRoomGuest, FALSE)
		|		AND NOT ISNULL(Reservations.RoomRateType.DoNotMergeTouristTaxBaseToTheMainRoomGuest, FALSE)
		|		AND Reservations.Ref <> &qRoomDoc) AS RoomDocs";
		vQry.SetParameter("qGuestGroup", pRoomDoc.GuestGroup);
		vQry.SetParameter("qNumber", pRoomDoc.Number);
		vQry.SetParameter("qRoomDoc", pRoomDoc);
		vRes = vQry.Execute().Unload();
		For Each vResRow In vRes Do
			If vResRow.RateSumInBaseCurrency <> Null Then
				vRateSum = vRateSum + vResRow.RateSumInBaseCurrency;
			EndIf;
		EndDo;
	EndIf;
	Return vRateSum;
EndFunction // cmGetOtherRoomDocumentsRateSum

#EndRegion
