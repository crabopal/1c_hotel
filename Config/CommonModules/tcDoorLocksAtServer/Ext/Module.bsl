#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pCardType			 - String	 - Card type
//  pCardCode			 - String	 - Card code
//  pRoom				 - CatalogRef.Rooms	 - Room
//  pEventDescription	 - String			 - Event description
//  pPeriodFrom			 - Date				 - Period from
//  pPeriodTo			 - Date				 - Period to
//  pDoc				 - DocumentRef.Accommodation - Document
//  pGuest				 - CatalogRef.Guest			 - Guest
//  pNumberOfKeys		 - Number					 - Number of keys
//  pGroupOfKeys		 - Number					 - Group of keys
//
Procedure WriteKeyCardSecuritySystemEvent(pCardType, pCardCode, pRoom, pEventDescription, pPeriodFrom, pPeriodTo, pDoc, pGuest, pNumberOfKeys = 1, pGroupOfKeys = 0) Export
	cmWriteKeyCardSecuritySystemEvent(pCardType, pCardCode, pRoom, pEventDescription, pPeriodFrom, pPeriodTo, pDoc, pGuest, pNumberOfKeys, pGroupOfKeys);
EndProcedure // WriteKeyCardSecuritySystemEvent

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel					 - CatalogRef.Hotels - Hotel
//  pAssignedAuthorizations	 - String			 - Assigned authorizations
// 
// Returns:
//  CatalogRef.DoorLockSystemAuthorizations - Result
//
Function FindAuthorizations(pHotel, pAssignedAuthorizations) Export
	vAuthRef = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DoorLockSystemAuthorizations.Ref
	|FROM
	|	Catalog.DoorLockSystemAuthorizations AS DoorLockSystemAuthorizations
	|WHERE
	|	DoorLockSystemAuthorizations.AssignedAuthorizations = &qAssignedAuthorizations
	|	AND (DoorLockSystemAuthorizations.Hotel = &qHotel
	|			OR &qIsEmptyHotel)
	|	AND (NOT DoorLockSystemAuthorizations.DeletionMark)
	|	AND (NOT DoorLockSystemAuthorizations.IsFolder)
	|ORDER BY
	|	DoorLockSystemAuthorizations.Code";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qAssignedAuthorizations", pAssignedAuthorizations);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() = 1 Then
		vAuthRef = vQryRes.Get(0).Ref;
	EndIf;
	Return vAuthRef;
EndFunction // FindAuthorizations

// -----------------------------------------------------------------------------
//
// Parameters:
//  pFolio		 - DocumentRef.Folio - Folio
//  pIsMaster	 - Boolean			 - Is master
//
Procedure UpdateMasterFolioFlag(pFolio, pIsMaster) Export
	If ValueIsFilled(pFolio) Then
		If pFolio.IsMaster <> pIsMaster Then
			vFolioObj = pFolio.GetObject();
			vFolioObj.IsMaster = pIsMaster;
			vFolioObj.Write(DocumentWriteMode.Write);
			// Try to set folio client default charging rules
			If ValueIsFilled(pFolio.Client) And Not ValueIsFilled(pFolio.Room) And Not ValueIsFilled(pFolio.GuestGroup) Then
				vClientObj = pFolio.Client.GetObject();
				If ValueIsFilled(pFolio.Hotel) Then
					vClientObj.ChargingRules.Clear();
					vClientObj.pmCreateFolios(pFolio.Hotel, CurrentSessionDate());
					If vClientObj.ChargingRules.Count() > 0 Then
						vCRRow = vClientObj.ChargingRules.Get(0);
						vOldFolio = vCRRow.ChargingFolio;
						vCRRow.ChargingFolio = pFolio;
						vClientObj.Write();
						// Try to mark old folio as deleted
						If ValueIsFilled(vOldFolio) Then
							vOldFolioObj = vOldFolio.GetObject();
							vOldFolioObj.SetDeletionMark(True);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // UpdateMasterFolioFlag

// -----------------------------------------------------------------------------
//
// Parameters:
//  pStr - String	 - String
// 
// Returns:
//  String - Result
//
Function HexLRC(pStr) Export
	Return cmHexLRC(pStr);
EndFunction // HexLRC

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDoorLockSystemConnectionParameters	 - CatalogRef.DoorLockSystemParameters	 - DoorLockSystemParameters
// 
// Returns:
//  Structure - Result
//
Function GetDoorLockSystemConnectionParameters(pDoorLockSystemConnectionParameters) Export
	Return pDoorLockSystemConnectionParameters.Get();
EndFunction // GetDoorLockSystemConnectionParameters

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCodeRoom	 - String	 - Code room
// 
// Returns:
//  CatalogRef.Room - Result
//
Function GetRoomRefByCode(pCodeRoom) Export
	vRoomRef = Catalogs.Rooms.EmptyRef();
	vQuery =  New Query();
	vQuery.Text = 
	"SELECT
	|	Rooms.Ref AS Ref,
	|	Rooms.Description AS Description
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND Rooms.LockCode = &qLockCode
	|	AND NOT Rooms.IsFolder
	|
	|UNION ALL
	|
	|SELECT
	|	Rooms.Ref,
	|	Rooms.Description
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND Rooms.Description = &qLockCode";
	vQuery.SetParameter("qLockCode", pCodeRoom);
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		vRoomRef = vResult[0].Ref;
	EndIf;
	Return vRoomRef;
EndFunction // GetRoomRefByCode

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRoom		 - CatalogRef.Rooms	 - Room
//  pCheckInDate - Date				 - Check in date
// 
// Returns:
//  Date - Result
//
Function GetLastKeyDate(pRoom, pCheckInDate) Export
	If ValueIsFilled(pRoom) Then
		vQ = New Query("SELECT TOP 1
		               |	SafetySystemEvents.PeriodFrom
		               |FROM
		               |	InformationRegister.SafetySystemEvents AS SafetySystemEvents
		               |WHERE
		               |	SafetySystemEvents.Room = &qRoom
		               |
		               |ORDER BY
		               |	SafetySystemEvents.PeriodFrom DESC");
		vQ.SetParameter("qRoom", pRoom);
		qRes = vQ.Execute().Select();
		If qRes.Next() Then
			Return qRes.PeriodFrom;
		EndIf;
	EndIf;
	Return pCheckInDate;
EndFunction // GetLastKeyDate

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardUID		 - String	 - Card UUID
//  pDateTimeFrom	 - Date		 - Date time from
//  pDateTimeTo		 - Date		 - Date time to
//  pRoom			 - CatalogRef.Rooms	 - Room
// 
// Returns:
//  CatalogRef.Guests - Result
//
Function GetClientRefByCardUID(pCardUID, pDateTimeFrom = Undefined, pDateTimeTo = Undefined, pRoom = Undefined) Export
	vClients = Catalogs.Clients.EmptyRef();
	vQuery =  New Query();
	vQuery.Text = "SELECT
	              |	IdentificationCards.Client AS Client
	              |FROM
	              |	Catalog.IdentificationCards AS IdentificationCards
	              |WHERE
	              |	NOT IdentificationCards.DeletionMark
	              |	AND IdentificationCards.CardUID = &qCardUID
	              |	AND (NOT &qDateTimeFromIsEmpty
	              |				AND IdentificationCards.DateTimeFrom = &qDateTimeFrom
	              |			OR &qDateTimeFromIsEmpty)
	              |	AND (NOT &qDateTimeToIsEmpty
	              |				AND IdentificationCards.DateTimeTo = &qDateTimeTo
	              |			OR &qDateTimeToIsEmpty)
	              |	AND (NOT &qRoomIsEmpty
	              |				AND IdentificationCards.Room = &qRoom
	              |			OR &qRoomIsEmpty)";
	vQuery.SetParameter("qCardUID", pCardUID);
	vQuery.SetParameter("qDateTimeFromIsEmpty", Not ValueIsFilled(pDateTimeFrom));
	vQuery.SetParameter("qDateTimeFrom", pDateTimeFrom);
	vQuery.SetParameter("qDateTimeToIsEmpty", Not ValueIsFilled(pDateTimeTo));
	vQuery.SetParameter("qDateTimeTo", pDateTimeTo);
	vQuery.SetParameter("qRoomIsEmpty", Not ValueIsFilled(pRoom));
	vQuery.SetParameter("qRoom", pRoom);
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		vClients = vResult[0].Client;
	EndIf;
	Return vClients;
EndFunction // GetLastKeyDate

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRoom	 - CatalogRef.Room	 - Room 
// 
// Returns:
//  Number - Key Count
//
Function GetCountKeys(pRoom) Export
	vKeyCount = 0;
	vQuery = New Query;
	vQuery.Text =
	"SELECT
	|	COUNT(SafetySystemEvents.Period) AS CountList
	|FROM
	|	InformationRegister.SafetySystemEvents AS SafetySystemEvents
	|WHERE
	|	SafetySystemEvents.Hotel = &qHotel";
	vQuery.SetParameter("qHotel", pRoom.Owner);
	vSelect = vQuery.Execute().Select(); 
	If vSelect.Next() Then
		vKeyCount = vSelect.CountList;	
	EndIf;
	Return vKeyCount;
EndFunction // GetCountKeys

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRoom			 - CatalogRef.Rooms	 - Room
//  pIsOnlyActive	 - Boolean			 - Is only active
// 
// Returns:
//  Number - Result
//
Function GetLastKeysSet(pRoom, pIsOnlyActive = True) Export
	vLastKeysSet = 0;
	vQuery =  New Query();
	vQuery.Text = 
	"SELECT TOP 1
	|	SafetySystemEvents.KeysSet AS KeysSet
	|FROM
	|	InformationRegister.SafetySystemEvents AS SafetySystemEvents
	|WHERE
	|	SafetySystemEvents.CardType = ""NEW""
	|	AND CASE
	|			WHEN &qIsOnlyActive
	|				THEN SafetySystemEvents.IsActive = &qIsOnlyActive
	|			ELSE TRUE
	|		END
	|	AND SafetySystemEvents.Room = &qRoom
	|
	|ORDER BY
	|	SafetySystemEvents.Period DESC";
	vQuery.SetParameter("qRoom", pRoom);
	vQuery.SetParameter("qIsOnlyActive", pIsOnlyActive);
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		vLastKeysSet = vResult[0].KeysSet;
	EndIf;	
	Return vLastKeysSet;
EndFunction // GetLastDaiCard

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRoom	 - CatalogRef.Rooms	 - Room
//  pKeysSet - Number			 - Keys set
// 
// Returns:
//  Number - Result
//
Function GetLastNumberOfKeys(pRoom, pKeysSet) Export
	vLastNumberOfKeys = 0;
	vQuery =  New Query();
	vQuery.Text = 
	"SELECT TOP 1
	|	SafetySystemEvents.NumberOfKeys AS NumberOfKeys
	|FROM
	|	InformationRegister.SafetySystemEvents AS SafetySystemEvents
	|WHERE
	|	SafetySystemEvents.CardType = ""ADD""
	|	AND SafetySystemEvents.IsActive
	|	AND SafetySystemEvents.Room = &qRoom
	|	AND SafetySystemEvents.KeysSet = &qKeysSet
	|
	|ORDER BY
	|	SafetySystemEvents.Period DESC";
	vQuery.SetParameter("qRoom", pRoom);
	vQuery.SetParameter("qKeysSet", pKeysSet);
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		vLastNumberOfKeys = vResult[0].NumberOfKeys;
	EndIf;
	Return vLastNumberOfKeys;
EndFunction // GetLastNumberOfKeys

// -----------------------------------------------------------------------------
// 
// Returns:
// String  - Result
//
Function GetCSWSOCK6LicenseKey() Export
	Return cmGetCSWSOCK6LicenseKey();
EndFunction // GetCSWSOCK6LicenseKey

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Result
//
Function GetCSWSOCK10LicenseKey() Export
	Return cmGetCSWSOCK10LicenseKey();
EndFunction // GetCSWSOCK6LicenseKey

// -----------------------------------------------------------------------------
//
// Parameters:
//  pIDCardRef	 - CatalogRef.DoorLockSystemParameters	 - Door lock system parameter
//
Procedure UpdateCardIdentifier(pIDCardRef) Export
	If Left(pIDCardRef.Identifier, 1) = "0" Then
		vIDCardObj = pIDCardRef.GetObject();
		vIDCardObj.Identifier = "1" + Mid(vIDCardObj.Identifier, 2);
		vIDCardObj.Write();
		pIDCardRef = vIDCardObj.Ref;
	EndIf;
EndProcedure // UpdateCardIdentifier

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardID	 - String	 - Card ID
// 
// Returns:
//  CatalogRef.IdentificationCards - Result
//
Function GetIdentificationCardsRefByCardID(pCardID) Export
	Return Catalogs.IdentificationCards.FindByAttribute("Identifier", pCardID);
EndFunction // GetIdentificationCardsRefByCardID

#EndRegion