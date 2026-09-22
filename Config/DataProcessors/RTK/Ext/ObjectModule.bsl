// ----------------------------------------------------------------------------
// Data processors framework start
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// ----------------------------------------------------------------------------
//  Save data processor attributes
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//  -----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
		
EndProcedure // pmFillAttributesWithDefaultValues

// ----------------------------------------------------------------------------
//  Run data processor in silent mode
//
// Parameters:
//  pParameter		 - 	 - 
//  pIsInteractive	 - 	 - 
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	ProcessesEvents();	
EndProcedure //  pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------

#Region StructureObject 

// -----------------------------------------------------------------------------
Function GetCheckIn(pRoomInterfaceStatus, pHotelId, pDateTime, pDocument, pRoom, pGuestIndexInRoom, pAdditional, pIsSync = False) 
	vDocNumber = cmGetDocumentNumberPresentation(pDocument.Number); 
	vCommandMap = New Map;
	vCommandMap.Insert("hotelId", Left(pHotelId, 20));
	vCommandMap.Insert("roomNumber", Left(cmGetObjectExternalSystemCodeByRef(pDocument.Hotel, InteractionParameters.InteractionID, "Rooms", pRoom), 10));
	vCommandMap.Insert("guestName", Left(pDocument.Guest.LastName, 40));
	vCommandMap.Insert("guestFirstName", Left(pDocument.Guest.FirstName, 40));
	vCommandMap.Insert("guestTitle", Left(pDocument.Guest.Salutation.Title, 10));
	vCommandMap.Insert("pmsRegNum", Right(vDocNumber + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="), 20));
	vCommandMap.Insert("arrivalDate", GetFormatDateByDate(pDocument.CheckInDate)); 
	vCommandMap.Insert("departureDate", GetFormatDateByDate(pDocument.CheckOutDate));
	vCommandMap.Insert("arrivalDateTS", GetTimestampByDate(pDocument.CheckInDate));
	vCommandMap.Insert("departureDateTS", GetTimestampByDate(pDocument.CheckOutDate));
	vCommandMap.Insert("dateTime", Format(pDateTime, "DF='yyyy-MM-dd HH:mm:ss'"));
	vCommandMap.Insert("guestLanguage", Lower(Left(pDocument.Guest.Language.Code, 2)));
	vCommandMap.Insert("roomShare", CheckRoomShare(pRoom, pRoomInterfaceStatus));
	vCommandMap.Insert("swapFlag", ?(pIsSync, "Y", "N")); 
	vCommandMap.Insert("noPost", ?(pDocument.NoPost, "Y", "N"));
	vCommandMap.Insert("profileNum", Right(cmGetDocumentNumberPresentation(pDocument.Guest.Code), 10));
	
	vAdditional = New Map;
	vAdditional.Insert("a0", Right(vDocNumber + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="), 1000));
	vAdditional.Insert("a1", ?(pAdditional["a1"] <> Undefined, Format(pAdditional["a1"], "NFD=0; NZ=0; NG=0"), "0"));
	vAdditional.Insert("a2", ?(pAdditional["a2"] <> Undefined, pAdditional["a2"], "deny"));
	vAdditional.Insert("a3", ?(pAdditional["a3"] <> Undefined, Format(pAdditional["a3"], "NFD=0; NZ=0; NG=0"), "0")); 
	vAdditional.Insert("a4", Right(Format(Number(vDocNumber), "ND=12; NZ=0000; NLZ=; NG="), 4));	
	vAdditional.Insert("a5", SMS.GetValidPhoneNumber(?(ValueIsFilled(pDocument.Phone), pDocument.Phone, pDocument.Guest.Phone)));
	vAdditional.Insert("a6", "");
	vAdditional.Insert("a7", "");
	vAdditional.Insert("a8", ?(pAdditional["a8"] <> Undefined, Format(pAdditional["a8"], "NFD=0; NZ=0; NG=0"), "3"));
	vAdditional.Insert("a9", "");
	vCommandMap.Insert("additional", vAdditional);
	Return MapToJSON(vCommandMap);
EndFunction // GetGuestCheckIn

// -----------------------------------------------------------------------------
Function GetChange(pRoomInterfaceStatus, pHotelId, pDateTime, pDocument, pRoom, pRoomOld, pGuestIndexInRoom, pAdditional, pIsRoomChange) 
	vDocNumber = cmGetDocumentNumberPresentation(pDocument.Number); 
	vCommandMap = New Map;
	vCommandMap.Insert("hotelId", Left(pHotelId, 20));
	vCommandMap.Insert("roomNumber", Left(cmGetObjectExternalSystemCodeByRef(pDocument.Hotel, InteractionParameters.InteractionID, "Rooms", pRoom), 10));
	vCommandMap.Insert("roomShare", CheckRoomShare(pRoom, pRoomInterfaceStatus));
	If pIsRoomChange Then  
		vCommandMap.Insert("oldRoom", Left(cmGetObjectExternalSystemCodeByRef(pDocument.Hotel, InteractionParameters.InteractionID, "Rooms", pRoomOld), 10)); 
		vCommandMap.Insert("oldRoomShare", CheckRoomShare(pRoomOld, pRoomInterfaceStatus));  
	EndIf;
	vCommandMap.Insert("guestName", Left(pDocument.Guest.LastName, 40));
	vCommandMap.Insert("guestFirstName", Left(pDocument.Guest.FirstName, 40));
	vCommandMap.Insert("guestTitle", Left(pDocument.Guest.Salutation.Title, 10));
	vCommandMap.Insert("pmsRegNum", Right(vDocNumber + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="), 20));
	vCommandMap.Insert("arrivalDate", GetFormatDateByDate(pDocument.CheckInDate)); 
	vCommandMap.Insert("departureDate", GetFormatDateByDate(pDocument.CheckOutDate));
	vCommandMap.Insert("arrivalDateTS", GetTimestampByDate(pDocument.CheckInDate));
	vCommandMap.Insert("departureDateTS", GetTimestampByDate(pDocument.CheckOutDate));
	vCommandMap.Insert("dateTime", Format(pDateTime, "DF='yyyy-MM-dd HH:mm:ss'"));
	vCommandMap.Insert("guestLanguage", Lower(Left(pDocument.Guest.Language.Code, 2))); 
	vCommandMap.Insert("noPost", ?(pDocument.NoPost, "Y", "N"));
	vCommandMap.Insert("profileNum", Right(cmGetDocumentNumberPresentation(pDocument.Guest.Code), 10));
	
	vAdditional = New Map;
	vAdditional.Insert("a0", Right(vDocNumber + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="), 1000));
	vAdditional.Insert("a1", ?(pAdditional["a1"] <> Undefined, Format(pAdditional["a1"], "NFD=0; NZ=0; NG=0"), "0"));
	vAdditional.Insert("a2", ?(pAdditional["a2"] <> Undefined, pAdditional["a2"], "deny"));
	vAdditional.Insert("a3", ?(pAdditional["a3"] <> Undefined, Format(pAdditional["a3"], "NFD=0; NZ=0; NG=0"), "0")); 
	vAdditional.Insert("a4", Right(Format(Number(vDocNumber), "ND=12; NZ=0000; NLZ=; NG="), 4));	
	vAdditional.Insert("a5", SMS.GetValidPhoneNumber(?(ValueIsFilled(pDocument.Phone), pDocument.Phone, pDocument.Guest.Phone)));
	vAdditional.Insert("a6", "");
	vAdditional.Insert("a7", "");
	vAdditional.Insert("a8", ?(pAdditional["a8"] <> Undefined, Format(pAdditional["a8"], "NFD=0; NZ=0; NG=0"), "3"));
	vAdditional.Insert("a9", "");
	vCommandMap.Insert("additional", vAdditional);
	Return MapToJSON(vCommandMap);		
EndFunction // GetGuestChange

// -----------------------------------------------------------------------------
Function GetCheckOut(pRoomInterfaceStatus, pHotelId, pDateTime, pDocument, pRoom, pGuestIndexInRoom, pIsSync = False) 
	vCommandMap = New Map;
	vCommandMap.Insert("hotelId", Left(pHotelId, 20));
	vCommandMap.Insert("roomNumber", Left(cmGetObjectExternalSystemCodeByRef(?(ValueIsFilled(pDocument), pDocument.Hotel, pRoom.Owner), InteractionParameters.InteractionID, "Rooms", pRoom), 10));
	If Not pIsSync Then
		vCommandMap.Insert("pmsRegNum", Right(cmGetDocumentNumberPresentation(pDocument.Number) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="), 20));
	EndIf;   
	vCommandMap.Insert("roomShare", ?(pIsSync, CheckRoomShare(pRoom, pRoomInterfaceStatus), "N"));
	vCommandMap.Insert("swapFlag", ?(pIsSync, "Y", "N"));
	vCommandMap.Insert("dateTime", GetFormatDateByDate(pDateTime));
	Return MapToJSON(vCommandMap);
EndFunction // GetGuestCheckOut

// -----------------------------------------------------------------------------
Function GetSendMessage(pHotelId, pDateTime, pDocument, pRoom, pGuestIndexInRoom, pMessageID, pMessage, pMessageDateTime) 
	vCommandMap = New Map;
	vCommandMap.Insert("hotelId", Left(pHotelId, 20));
	vCommandMap.Insert("roomNumber", Left(cmGetObjectExternalSystemCodeByRef(pDocument.Hotel, InteractionParameters.InteractionID, "Rooms", pRoom), 10));
	vCommandMap.Insert("pmsRegNum", Right(cmGetDocumentNumberPresentation(pDocument.Number) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="), 20));
	vMessages = New Array;
	vMessagesMap = New Map;
	vMessagesMap.Insert("messageId", Right(cmGetDocumentNumberPresentation(pMessageID), 8));
	vMessagesMap.Insert("text", Left(pMessage, 2000)); 
	vMessagesMap.Insert("dateTime", GetFormatDateByDate(?(ValueIsFilled(pMessageDateTime), pMessageDateTime, pDateTime)));
	vMessagesMap.Insert("dateTimeTS", GetTimestampByDate(?(ValueIsFilled(pMessageDateTime), pMessageDateTime, pDateTime)));
	vMessages.Add(vMessagesMap);	
	vCommandMap.Insert("messages", vMessages);
	Return MapToJSON(vCommandMap);
EndFunction // GetGuestCheckOut

// -----------------------------------------------------------------------------
Function GetResyncStartAndEnd(pHotelId, pDateTime)
	vCommandMap = New Map;
	vCommandMap.Insert("hotelId", pHotelId); 
	vCommandMap.Insert("eventDateTime", GetFormatDateByDate(pDateTime)); 			 
	vCommandMap.Insert("eventDateTimeTS", GetTimestampByDate(pDateTime));
	Return MapToJSON(vCommandMap);
EndFunction // GetResyncStartAndEnd

#EndRegion  

#Region GetData 

// -----------------------------------------------------------------------------
Function GetRoomInterfaceStatus(pNumber, pGuestGroup, pGuestIndexInRoom, pTurnOnParameters)
	vResult = Undefined;
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	RoomInterfaceStatus.Ref AS Ref
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|WHERE
	|	RoomInterfaceStatus.ParentDoc.Number = &qNumber
	|	AND RoomInterfaceStatus.ParentDoc.GuestGroup = &qGuestGroup
	|	AND RoomInterfaceStatus.GuestIndexInRoom = &qGuestIndexInRoom
	|	AND CASE
	|			WHEN &qTurnOnFilled
	|				THEN RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters LIKE &qTurnOnParameters
	|			ELSE TRUE
	|		END
	|	AND NOT RoomInterfaceStatus.DeletionMark";
	
	vQuery.SetParameter("qNumber", 				pNumber);
	vQuery.SetParameter("qGuestGroup", 			pGuestGroup);
	vQuery.SetParameter("qGuestIndexInRoom", 	Number(pGuestIndexInRoom));
	vQuery.SetParameter("qTurnOnParameters", 	pTurnOnParameters);
	vQuery.SetParameter("qTurnOnFilled", 		ValueIsFilled(pTurnOnParameters));
	vQueryResult = vQuery.Execute().Unload();
	
	For each vRow in vQueryResult Do
		vResult = vRow.Ref;
		Break;
	EndDo;
	
	Return vResult;
EndFunction // GetRoomInterfaceStatus

// -----------------------------------------------------------------------------
Function CheckRoomShare(pRoom, pRoomInterfaceStatus)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInterfaceTypes.Ref AS Ref
	|INTO RoomInterfaceTypes
	|FROM
	|	Catalog.RoomInterfaceTypes AS RoomInterfaceTypes
	|WHERE
	|	NOT RoomInterfaceTypes.DeletionMark
	|	AND RoomInterfaceTypes.ExternalSystem = &qExternalSystem
	|	AND RoomInterfaceTypes.TurnOnParameters LIKE ""checkin%""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	RoomInterfaceStatus.Ref AS Ref
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|		INNER JOIN RoomInterfaceTypes AS RoomInterfaceTypes
	|		ON RoomInterfaceStatus.RoomInterfaceType = RoomInterfaceTypes.Ref
	|WHERE
	|	NOT RoomInterfaceStatus.DeletionMark
	|	AND (RoomInterfaceStatus.IsProcessed
	|				AND RoomInterfaceStatus.Room = &qRoom
	|			OR NOT RoomInterfaceStatus.IsProcessed
	|				AND RoomInterfaceStatus.RoomChangeIsRequested
	|				AND RoomInterfaceStatus.OldRoom = &qRoom)
	|	AND NOT RoomInterfaceStatus.IsCanceled
	|	AND RoomInterfaceStatus.Ref <> &qRoomInterfaceStatus";
	vQry.SetParameter("qExternalSystem", InteractionParameters);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qRoomInterfaceStatus", pRoomInterfaceStatus);
	Return ?(vQry.Execute().IsEmpty(), "N", "Y"); 	
EndFunction // CheckRoomShare

// -----------------------------------------------------------------------------
Function GetActiveRoomInterfaceEvents() 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInterfaceTypes.Ref AS Ref,
	|	RoomInterfaceTypes.TurnOnParameters AS TurnOnParameters,
	|	RoomInterfaceTypes.PeriodOfStayExtentionParameters AS PeriodOfStayExtentionParameters,
	|	RoomInterfaceTypes.GuestNameChangeParameters AS GuestNameChangeParameters,
	|	RoomInterfaceTypes.CommandToChangeExtraParameters AS CommandToChangeExtraParameters,
	|	RoomInterfaceTypes.TurnOffParameters AS TurnOffParameters,
	|	RoomInterfaceTypes.RoomChangeParameters AS RoomChangeParameters
	|INTO RoomInterfaceTypes
	|FROM
	|	Catalog.RoomInterfaceTypes AS RoomInterfaceTypes
	|WHERE
	|	NOT RoomInterfaceTypes.DeletionMark
	|	AND RoomInterfaceTypes.ExternalSystem = &qExternalSystem
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInterfaceStatus.Ref AS Ref,
	|	RoomInterfaceStatus.ParentDoc AS ParentDoc,
	|	RoomInterfaceStatus.Room AS Room,
	|	RoomInterfaceStatus.GuestIndexInRoom AS GuestIndexInRoom,
	|	CASE
	|		WHEN NOT RoomInterfaceStatus.IsCanceled
	|			THEN CASE
	|					WHEN RoomInterfaceStatus.PeriodOfStayExtensionIsRequested
	|						THEN CAST(RoomInterfaceTypes.PeriodOfStayExtentionParameters AS STRING(100))
	|					WHEN RoomInterfaceStatus.GuestNameChangeIsRequested
	|						THEN CAST(RoomInterfaceTypes.GuestNameChangeParameters AS STRING(100))
	|					WHEN RoomInterfaceStatus.RoomChangeIsRequested
	|						THEN CAST(RoomInterfaceTypes.RoomChangeParameters AS STRING(100))
	|					WHEN RoomInterfaceStatus.ExtraParametersChangeIsRequested
	|						THEN CAST(RoomInterfaceTypes.CommandToChangeExtraParameters AS STRING(100))
	|					ELSE CAST(RoomInterfaceTypes.TurnOnParameters AS STRING(100))
	|				END
	|		ELSE CAST(RoomInterfaceTypes.TurnOffParameters AS STRING(100))
	|	END AS Command,
	|	RoomInterfaceStatus.ExtraParameters AS ExtraParameters,
	|	RoomInterfaceStatus.MessageDateTime AS MessageDateTime,
	|	RoomInterfaceStatus.Remarks AS Remarks,
	|	RoomInterfaceStatus.Number AS Number,
	|	RoomInterfaceStatus.RoomChangeIsRequested AS IsRoomChange,
	|	RoomInterfaceStatus.OldRoom AS OldRoom
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|		INNER JOIN RoomInterfaceTypes AS RoomInterfaceTypes
	|		ON RoomInterfaceStatus.RoomInterfaceType = RoomInterfaceTypes.Ref
	|WHERE
	|	NOT RoomInterfaceStatus.DeletionMark
	|	AND NOT RoomInterfaceStatus.IsProcessed
	|	AND RoomInterfaceStatus.ParentDoc <> VALUE(Document.Accommodation.EmptyRef)
	|	AND RoomInterfaceStatus.ParentDoc <> VALUE(Document.Reservation.EmptyRef)
	|	AND NOT RoomInterfaceStatus.IsProcessingError
	|	AND RoomInterfaceStatus.ParentDoc.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|	AND RoomInterfaceStatus.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|
	|ORDER BY
	|	RoomInterfaceStatus.PointInTime";
	vQry.SetParameter("qExternalSystem", InteractionParameters);
	Return vQry.Execute().Unload();
EndFunction // GetActiveRoomInterfaceEvents

// -------------------------------------------------------------------------
Function GetDocsToSync(pHotel)
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomInterfaceTypes.Ref AS Ref
	|INTO RoomInterfaceTypes
	|FROM
	|	Catalog.RoomInterfaceTypes AS RoomInterfaceTypes
	|WHERE
	|	NOT RoomInterfaceTypes.DeletionMark
	|	AND RoomInterfaceTypes.ExternalSystem = &qExternalSystem
	|	AND RoomInterfaceTypes.TurnOnParameters LIKE ""checkin%""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInterfaceStatus.ParentDoc AS ParentDoc,
	|	RoomInterfaceStatus.Room AS Room,
	|	RoomInterfaceStatus.GuestIndexInRoom AS GuestIndexInRoom,
	|	RoomInterfaceStatus.ExtraParameters AS ExtraParameters,
	|	RoomInterfaceStatus.PointInTime AS PointInTime,
	|	RoomInterfaceStatus.Ref AS Ref
	|INTO RoomsInterfaceStatus
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|		INNER JOIN RoomInterfaceTypes AS RoomInterfaceTypes
	|		ON RoomInterfaceStatus.RoomInterfaceType = RoomInterfaceTypes.Ref
	|WHERE
	|	NOT RoomInterfaceStatus.DeletionMark
	|	AND (RoomInterfaceStatus.PeriodOfStayExtensionIsRequested
	|			OR RoomInterfaceStatus.GuestNameChangeIsRequested
	|			OR RoomInterfaceStatus.RoomChangeIsRequested
	|			OR RoomInterfaceStatus.ExtraParametersChangeIsRequested
	|			OR RoomInterfaceStatus.IsProcessed)
	|	AND NOT RoomInterfaceStatus.IsCanceled
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Rooms.Ref AS Room,
	|	RoomsInterfaceStatus.ParentDoc AS ParentDoc,
	|	RoomsInterfaceStatus.GuestIndexInRoom AS GuestIndexInRoom,
	|	RoomsInterfaceStatus.ExtraParameters AS ExtraParameters,
	|	RoomsInterfaceStatus.Ref AS Ref
	|FROM
	|	Catalog.Rooms AS Rooms
	|		LEFT JOIN RoomsInterfaceStatus AS RoomsInterfaceStatus
	|		ON Rooms.Ref = RoomsInterfaceStatus.Room
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND Rooms.Owner = &qHotel
	|	AND NOT Rooms.IsFolder
	|	AND Rooms.IsUseTVInterface
	|
	|ORDER BY
	|	Rooms.SortCode,
	|	RoomsInterfaceStatus.PointInTime";	
	vQry.SetParameter("qExternalSystem", InteractionParameters); 
	vQry.SetParameter("qHotel", pHotel);

	Return vQry.Execute().Unload();
EndFunction // GetDocsToSync

// -----------------------------------------------------------------------------
Function GetDocument(pHotel, vParameters)
	vAccommodation = Documents.Accommodation.EmptyRef();
	
	If vParameters["pmsRegNum"] <> Undefined Then
		vQ = New Query;
		vQ.Text =
		"SELECT TOP 1
		|	RoomInterfaceStatus.ParentDoc AS Ref
		|FROM
		|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
		|WHERE
		|	NOT RoomInterfaceStatus.DeletionMark
		|	AND RoomInterfaceStatus.ParentDoc.Number = &qDocNumber
		|	AND RoomInterfaceStatus.ParentDoc.Hotel = &qHotel
		|	AND RoomInterfaceStatus.GuestIndexInRoom = &qGuestIndexInRoom";
		vQ.SetParameter("qHotel", pHotel);
		vQ.SetParameter("qDocNumber", cmGetDocumentNumberFromPresentation(Left(vParameters["pmsRegNum"], StrLen(vParameters["pmsRegNum"]) - 2), pHotel));
		vQ.SetParameter("qGuestIndexInRoom", Number(Right(vParameters["pmsRegNum"], 2)));
		vAccommodationsList = vQ.Execute().Unload();
		For Each vAccommodationRow In vAccommodationsList Do
			vAccommodation = vAccommodationRow.Ref;
			Break;
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(vAccommodation) And vParameters["roomNumber"] <> Undefined Then
		vAccommodation = GetAccommodationByRoomAndDate(pHotel, vParameters["roomNumber"], vParameters["date"]);
	EndIf;
	
	Return vAccommodation;
EndFunction // GetDocument

// -----------------------------------------------------------------------------
Function GetAccommodationByRoomAndDate(pHotel, pRoom, pDate = Undefined)	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	Accommodation.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	NOT Accommodation.DeletionMark
	|	AND Accommodation.Posted
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.Room = &qRoom
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND CASE
	|			WHEN &qDateFilled
	|				THEN &qDate BETWEEN Accommodation.CheckInDate AND Accommodation.CheckOutDate
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	Accommodation.PointInTime";
	
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qDate", pDate);
	vQuery.SetParameter("qDateFilled", ValueIsFilled(pDate));
	vQuery.SetParameter("qRoom", cmGetObjectRefByExternalSystemCode(pHotel, InteractionParameters.InteractionID, "Rooms", pRoom));
	
	vQueryResult = vQuery.Execute().Unload();
	For Each vRow In vQueryResult Do
		Return vRow.Ref;
	EndDo;	
EndFunction // GetAccommodationByRoomAndDate

// -----------------------------------------------------------------------------
Function Bill(pDocument, pParameters)
	vResponse = New Map;
	vResponse.Insert("hotelId", pParameters["hotelId"]);
	vResponse.Insert("roomNumber", pParameters["roomNumber"]);
	vResponse.Insert("pmsRegNum", pParameters["pmsRegNum"]);
	
	vBills = GetGuestFoliosWithTransactions(pDocument); 
	
	vResponse.Insert("billTotal", vBills.billTotal * 100);  
	
	vDateTime = CurrentSessionDate();
	vResponse.Insert("date", GetFormatDateByDate(vDateTime));
	vResponse.Insert("dateTS", GetTimestampByDate(vDateTime));
	
	vBillItemsArr = New Array;
	
	If vBills.billItems <> Undefined Then
		For Each vBill In vBills.billItems Do
			vBillItems = New Map;
			vBillItems.Insert("posId", vBill.posId);
			vBillItems.Insert("itemAmount", vBill.itemAmount * 100); 
			vBillItems.Insert("itemDateTime", GetFormatDateByDate(vBill.itemDateTime));
			vBillItems.Insert("itemDateTimeTS", GetTimestampByDate(vBill.itemDateTime));
			vBillItems.Insert("itemDescription", Left(vBill.itemDescription, 255));
			vBillItemsArr.Add(vBillItems);
		EndDo;
	EndIf;
	
	vResponse.Insert("billItems", vBillItemsArr);
	
	Return vResponse;
EndFunction // Bill

// -----------------------------------------------------------------------------
Function GetGuestFoliosWithTransactions(pDocument)
	vResult = New Structure("billTotal, billItems", 0, Undefined);
	
	vGuest = Catalogs.Clients.EmptyRef();
	
	// Check that accommodation is in-house or check-out was today
	If TypeOf(pDocument) = Type("DocumentRef.Accommodation") Then
		If Not pDocument.Posted Or Not pDocument.AccommodationStatus.IsActive Or Not pDocument.AccommodationStatus.IsInHouse And BegOfDay(pDocument.CheckOutDate) < BegOfDay(CurrentSessionDate()) Then
			Return vResult;
		EndIf;
		vGuest = pDocument.Guest;
	ElsIf TypeOf(pDocument) = Type("DocumentRef.Reservation") Then
		If Not pDocument.Posted Or Not pDocument.ReservationStatus.IsActive Then
			Return vResult;
		EndIf;
		vGuest = pDocument.Guest;
	ElsIf TypeOf(pDocument) = Type("DocumentRef.ResourceReservation") Then
		If Not pDocument.Posted Or Not pDocument.ResourceReservationStatus.IsActive Or pDocument.ResourceReservationStatus.ServicesAreDelivered And BegOfDay(pDocument.DateTimeTo) < BegOfDay(CurrentSessionDate()) Then
			Return vResult;
		EndIf;
		vGuest = pDocument.Client;
	EndIf;  
	
	If Not ValueIsFilled(vGuest) Then
		Return vResult;
	EndIf;
	
	
	vFolioTransactionItems 	= New ValueTable;
	vFolioTransactionItems.Columns.Add("posId");
	vFolioTransactionItems.Columns.Add("itemAmount");
	vFolioTransactionItems.Columns.Add("itemDateTime");
	vFolioTransactionItems.Columns.Add("itemDescription");
	
	vLanguage = vGuest.Language;
	// Fill guest info
	vClientBalance = 0;
	
	// Get document folios
	vFoliosCounter = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Folio
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.ParentDoc.Number = &qDocNumber
	|	AND Folio.GuestGroup = &qGuestGroup
	|	AND NOT Folio.DeletionMark
	|
	|ORDER BY
	|	Folio.PointInTime";
	vQry.SetParameter("qDocNumber", pDocument.Number);
	vQry.SetParameter("qGuestGroup", pDocument.GuestGroup);
	vAccFolios = vQry.Execute().Unload();
	For Each vAccFoliosRow In vAccFolios Do
		
		vFolioRef = vAccFoliosRow.Folio;
		If TypeOf(pDocument) = Type("DocumentRef.Accommodation") Or TypeOf(pDocument) = Type("DocumentRef.Reservation") Then
			If ValueIsFilled(vFolioRef.Customer) And Not vFolioRef.Customer.IsIndividual Then
				Continue;
			EndIf;
		EndIf;
		
		vFolioObj = vFolioRef.GetObject();
		vFolioPreauthLimit = 0;
		vFolioBalance = 0;
		vFoliosCounter = vFoliosCounter + 1;
		
		vTrans = vFolioObj.pmGetAllFolioTransactions();
		For Each vTransRow In vTrans Do
			If vTransRow.RecordType = AccumulationRecordType.Receipt And vTransRow.Sum = 0 Then
				Continue;
			ElsIf vTransRow.RecordType = AccumulationRecordType.Expense And vTransRow.PaymentMethod = Catalogs.PaymentMethods.Settlement Then
				Continue;
			EndIf;
			
			vFolioTransactionItem = New Structure("Type, Date, Description, Quantity, Unit, Price, Discount, DiscountSum, Sum, Details");
			
			If vTransRow.RecordType = AccumulationRecordType.Expense Then
				If vTransRow.PaymentMethod = Catalogs.PaymentMethods.Settlement Then
					vFolioTransactionItem.Type = "Settlement";
				ElsIf vTransRow.Limit <> 0 Then
					vFolioTransactionItem.Type = "Preauthorization";
				ElsIf TypeOf(vTransRow.Document) = Type("DocumentRef.DepositTransfer") Then
					vFolioTransactionItem.Type = "DepositTransfer";
				ElsIf vTransRow.Sum < 0 Then
					vFolioTransactionItem.Type = "Return";
				Else
					vFolioTransactionItem.Type = "Payment";
				EndIf;
			Else
				If vTransRow.Sum < 0 Then
					vFolioTransactionItem.Type = "Storno";
				Else
					vFolioTransactionItem.Type = "Charge";
				EndIf;
			EndIf;
			vFolioTransactionItem.Date = vTransRow.Period;
			vFolioTransactionItem.Description = "";
			If vTransRow.RecordType = AccumulationRecordType.Expense Then
				If vTransRow.Limit <> 0 Then
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + cmNStr("en='Preauthorization - '; ru='Преавторизация - '; de='Preauthorization - '", vLanguage);
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + vTransRow.PaymentMethod.GetObject().pmGetPaymentMethodDescription(vLanguage);
				ElsIf vFolioTransactionItem.Type = "DepositTransfer" Then
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + cmNStr("en='Money transfer'; ru='Перенос денег'; de='Geldtransfer'", vLanguage);
				ElsIf vTransRow.Sum < 0 Then
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + cmNStr("en='Return - '; ru='Возврат - '; de='Rückzahlung - '", vLanguage);
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + vTransRow.PaymentMethod.GetObject().pmGetPaymentMethodDescription(vLanguage);
				Else
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + vTransRow.PaymentMethod.GetObject().pmGetPaymentMethodDescription(vLanguage);
				EndIf;
				vFolioTransactionItem.Description = vFolioTransactionItem.Description + ?(IsBlankString(vTransRow.Remarks), "", " - " + TrimAll(vTransRow.Remarks));
				vFolioTransactionItem.Quantity = 0;
				vFolioTransactionItem.Unit = "";
				vFolioTransactionItem.Price = 0;
				vFolioTransactionItem.Discount = 0;
				vFolioTransactionItem.DiscountSum = 0;
				vFolioTransactionItem.Sum = ?(vTransRow.Limit <> 0, -vTransRow.Limit, -vTransRow.Sum);
				If vFolioTransactionItem.Type <> "DepositTransfer" Then
					vFolioTransactionItem.Details = ?(vTransRow.PaymentSum <> 0, ?(Not IsBlankString(vTransRow.Document.SlipText), TrimAll(vTransRow.Document.SlipText), ""), "");
				EndIf;
			Else
				If vTransRow.Sum < 0 Then
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + cmNStr("en='Cancel - '; ru='Отмена - '; de='Storno - '", vLanguage);
				EndIf;
				vFolioTransactionItem.Description = vFolioTransactionItem.Description + vTransRow.Service.GetObject().pmGetServiceDescription(vLanguage);
				vFolioTransactionItem.Description = vFolioTransactionItem.Description + ?(IsBlankString(vTransRow.Remarks), "", " - " + TrimAll(vTransRow.Remarks));
				vFolioTransactionItem.Quantity = vTransRow.Quantity;
				vFolioTransactionItem.Unit = vTransRow.Service.GetObject().pmGetServiceUnitDescription(vLanguage);
				vFolioTransactionItem.Price = vTransRow.Price;
				vFolioTransactionItem.Discount = ?(ValueIsFilled(vTransRow.Charge), vTransRow.Charge.Discount, 0);
				vFolioTransactionItem.DiscountSum = vTransRow.Discount;
				vFolioTransactionItem.Sum = vTransRow.Sum;
				vFolioTransactionItem.Details = ?(ValueIsFilled(vTransRow.Charge), TrimAll(vTransRow.Charge.Details), "");
			EndIf;
			
			vNewResultRow = vFolioTransactionItems.Add();
			
			If vTransRow.RecordType = AccumulationRecordType.Expense Then
				vNewResultRow.posId = 1; 
				If vTransRow.Limit <> 0 Then
					vFolioBalance = vFolioBalance - vTransRow.Limit;
					vNewResultRow.itemAmount 	= - vTransRow.Limit;
				Else
					vFolioBalance = vFolioBalance - vTransRow.Sum;
					vNewResultRow.itemAmount 	= - vTransRow.Sum;
				EndIf;
			Else
				vNewResultRow.posId = 1; 
				vFolioBalance = vFolioBalance + vTransRow.Sum;
				vNewResultRow.itemAmount 		= vFolioTransactionItem.Price;
			EndIf;
			
			vNewResultRow.itemDateTime 		= vFolioTransactionItem.Date;
			vNewResultRow.itemDescription 	= vFolioTransactionItem.Description;
		EndDo;
		
		vFolioBalanceInRepCur = cmConvertCurrencies(vFolioBalance, vFolioObj.FolioCurrency, , pDocument.ReportingCurrency, , pDocument.ExchangeRateDate, pDocument.Hotel);
		
		vClientBalance 	= vClientBalance + vFolioBalanceInRepCur;
	EndDo;
	vResult.billItems = vFolioTransactionItems;
	vResult.billTotal = vClientBalance;
	
	Return vResult;
EndFunction // GetGuestFoliosWithTransactions

// -----------------------------------------------------------------------------
Function GetPhoneNumber(pHotel, pRoom, pPhoneNumber)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PhoneNumbers.Ref AS Ref
	|FROM
	|	Catalog.PhoneNumbers AS PhoneNumbers
	|WHERE
	|	NOT PhoneNumbers.IsFolder
	|	AND NOT PhoneNumbers.DeletionMark
	|	AND PhoneNumbers.Owner = &qHotel
	|	AND PhoneNumbers.PhoneNumber = &qPhoneNumber
	|	AND PhoneNumbers.Room = &qRoom";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qPhoneNumber", TrimAll(pPhoneNumber));
	vQry.SetParameter("qRoom", pRoom);
	Result = vQry.Execute().Unload();
	
	vPhoneNumberRef = Catalogs.PhoneNumbers.EmptyRef();
	If Result.Count() > 0 Then
		vPhoneNumberRef = Result.Get(0).Ref;
	EndIf;
	
	Return vPhoneNumberRef;
EndFunction // GetPhoneNumber

#EndRegion

#Region OtherFunctions

// -----------------------------------------------------------------------------
Function Sale(pHotel, pRoomNumber, pPosId, pCheckNum, pArticle = Undefined, pQuantity = Undefined, pTotalAmount = Undefined, pText = Undefined) 	
	vDate = CurrentSessionDate();
	If ValueIsFilled(pArticle) and ValueIsFilled(pQuantity) Then
		Return cmChargeRoomService(pRoomNumber, vDate, pTotalAmount, , , pArticle, pQuantity, , , , pHotel.Description, InteractionParameters.InteractionID, , pCheckNum);
	ElsIf ValueIsFilled(pTotalAmount) and ValueIsFilled(pText) Then
		Return cmChargeRoomService(pRoomNumber, vDate, pTotalAmount, , ,pPosId , 1, , pText, , pHotel.Description, InteractionParameters.InteractionID, , pCheckNum);
	Else
		Return "Article, amount, totalAmount or text parameters are missing!";
	EndIf;
EndFunction // Sale

// ----------------------------------------------------------------------------
Function WritePhoneCall(pHotel, pRoomNumber, pCallTime, pCallDuration, pCallTo, pCallSum, pCallDescription)	
	Try
		vRoom = cmGetRoomByCode(pRoomNumber, pHotel.Description, InteractionParameters.InteractionID);
		vPhoneNumber = GetPhoneNumber(pHotel, vRoom, pRoomNumber);
		If Not ValueIsFilled(vPhoneNumber) Then
			vPhoneNumberObj = Catalogs.PhoneNumbers.CreateItem();
			vPhoneNumberObj.Room = vRoom;
			vPhoneNumberObj.Description = pRoomNumber;
			vPhoneNumberObj.PhoneNumber = pRoomNumber;
			vPhoneNumberObj.Remarks = NStr("en='New! Created by load phone calls procedure.';ru='Новый! Добавлен при загрузке.';de='Neu! Hinzugefügt beim Lasen.'");
			vPhoneNumberObj.Owner = pHotel;
			vPhoneNumberObj.Write();
			vPhoneNumber = vPhoneNumberObj.Ref;
		EndIf;
		
		// Calculate price
		vCallPrice = 0;
		If pCallDuration = 0 Then
			If pCallSum > 0 Тогда
				vCallPrice = pCallSum;
				pCallDuration = 1;
			EndIf;
		Else
			vCallPrice = Round(pCallSum/pCallDuration, 2);
		EndIf;
		pCallSum = Round(vCallPrice * pCallDuration, 2);
		
		// Create new interface document object
		vRecordPhoneCallObj = Documents.RecordPhoneCall.CreateDocument();
		vRecordPhoneCallObj.Hotel = pHotel;
		vRecordPhoneCallObj.pmFillAuthorAndDate();
		vRecordPhoneCallObj.SetNewNumber();
		vRecordPhoneCallObj.pmFillAttributesWithDefaultValues();
		
		// Fill default phone calls service
		If ValueIsFilled(PhoneCallsService) Then
			vRecordPhoneCallObj.PhoneCallService = PhoneCallsService;
		EndIf;
		
		// Fill call sum, duration and price
		vRecordPhoneCallObj.Sum = pCallSum;
		vRecordPhoneCallObj.Price = vCallPrice;
		vRecordPhoneCallObj.Quantity = pCallDuration;
		
		// Fill currency attributes
		vRecordPhoneCallObj.Currency = DataExchangeFileCurrency;
		vRecordPhoneCallObj.CurrencyExchangeRate = cmGetCurrencyExchangeRate(vRecordPhoneCallObj.Hotel, vRecordPhoneCallObj.Currency, vRecordPhoneCallObj.ExchangeRateDate);
		
		// Fill call attributes
		vRecordPhoneCallObj.PhoneCallDate = pCallTime;
		vRecordPhoneCallObj.TargetPhoneNumber = pCallTo;
		
		// Try to find folio to charge to
		vRecordPhoneCallObj.PhoneNumber = vPhoneNumber;
		If ValueIsFilled(vPhoneNumber) Then 
			If ValueIsFilled(vPhoneNumber.PhoneCallService) Then
				vRecordPhoneCallObj.PhoneCallService = vPhoneNumber.PhoneCallService;
			EndIf;
			If ValueIsFilled(vPhoneNumber.PerCallService) Then
				vRecordPhoneCallObj.PerCallService = vPhoneNumber.PerCallService;
			EndIf;
		EndIf;
		vRecordPhoneCallObj.Room = vRecordPhoneCallObj.PhoneNumber.Room;
		If ValueIsFilled(vRecordPhoneCallObj.Room) Then
			If ValueIsFilled(vRecordPhoneCallObj.Room.Company) Then
				vRecordPhoneCallObj.Company = vRecordPhoneCallObj.Room.Company;
				If Not ValueIsFilled(vRecordPhoneCallObj.PhoneCallService) Then
					vRecordPhoneCallObj.VATRate = vRecordPhoneCallObj.Company.VATRate;
				EndIf;
				If Not ValueIsFilled(vRecordPhoneCallObj.PerCallService) Then
					vRecordPhoneCallObj.PerCallServiceVATRate = vRecordPhoneCallObj.Company.VATRate;
				EndIf;
			EndIf;
			vRecordPhoneCallObj.Folio = vRecordPhoneCallObj.pmGetFolioToChargeTo();
		EndIf;
		
		// Try to find active room folio
		If Not ValueIsFilled(vRecordPhoneCallObj.Folio) Then
			vFolios = cmGetActiveRoomFolios(pHotel, vRecordPhoneCallObj.Room, pHotel.FolioCurrency);
			If vFolios.Count() > 0 Then
				vRow = vFolios.Get(0);
				vRecordPhoneCallObj.Folio = vRow.Folio;
			EndIf;
		EndIf;
		// Create new empty one
		If Not ValueIsFilled(vRecordPhoneCallObj.Folio) Then
			vFolioObj = Documents.Folio.CreateDocument();
			vFolioObj.Hotel = pHotel;
			vFolioObj.pmFillAttributesWithDefaultValues();
			vFolioObj.Room = vRecordPhoneCallObj.Room;
			vFolioObj.Description = NStr("en='Phone calls from vacant rooms';ru='Телефонные разговоры из свободных номеров';de='Telefongespräche aus freien Zimmern'");
			vFolioObj.Write(DocumentWriteMode.Write);
			
			vRecordPhoneCallObj.Folio = vFolioObj.Ref;
			
			vMessage = NStr("ru = 'Создано фолио: " + String(vRecordPhoneCallObj.Folio) + "'; 
			|de = 'Folio " + String(vRecordPhoneCallObj.Folio) + " was created'; 
			|en = 'Folio " + String(vRecordPhoneCallObj.Folio) + " was created'");
			DoMessage(vMessage, MessageStatus.Information, "RTK.WritePhoneCall");
		EndIf;
		
		// Process folio
		vRecordPhoneCallObj.pmFillByFolio();
		vRecordPhoneCallObj.pmRecalculateSums();
		
		// Fill call type and region
		vRecordPhoneCallObj.pmFillPhoneCallRegion();
		
		vRecordPhoneCallObj.pmFillPhoneCallType();
		
		// Fill remarks
		vRecordPhoneCallObj.Remarks = pCallDescription;
		
		// Post current document
		vRecordPhoneCallObj.Write(DocumentWriteMode.Posting);
	Except
		vErrorDescription = ErrorDescription();
		Return vErrorDescription;
	EndTry;
	Return "";
EndFunction // WritePhoneCall

// ----------------------------------------------------------------------------
Function MapToJSON(pMap)	
	Try
		vJSONWriter = New JSONWriter;
		vJSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
		WriteJSON(vJSONWriter, pMap);
		Return vJSONWriter.Close();	
	Except
		Return "";
	EndTry;	
EndFunction // MapToJSON

// ----------------------------------------------------------------------------
Function JSONToMap(pJSON)
	Try
		vJSONReader = New JSONReader();
		vJSONReader.SetString(pJSON);
		Return ReadJSON(vJSONReader, True);	
	Except
		Return New Map;	
	EndTry;	
EndFunction // MapToJSON

// ----------------------------------------------------------------------------
Function GetFormatDateByDate(pDate)
	Return Format(pDate, "DF='yyyy-MM-dd HH:mm:ss'");
EndFunction // GetTimestampByDate

// ----------------------------------------------------------------------------
Function GetTimestampByDate(pDate)
	Return Format(pDate - Date("19700101"), "NZ=0; NG=0");
EndFunction // GetTimestampByDate

// ----------------------------------------------------------------------------
Function GetDateByTimestamp(pTimestamp)
	Return Date("19700101") + pTimestamp;
EndFunction // GetDateByTimestamp

// ----------------------------------------------------------------------------
Procedure DoMessage(pMsg, pMsgStatus = Undefined, pFunctionName = "")
	vFunctionName = "RTK";
	If ValueIsFilled(pFunctionName) Then
		vFunctionName = pFunctionName; 	
	EndIf;
	vMsgStatus = MessageStatus.Information;
	If pMsgStatus <> Undefined Then
		vMsgStatus = pMsgStatus;
	EndIf;
	If ValueIsFilled(InteractionParameters) Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, vFunctionName, ?(vMsgStatus = MessageStatus.Attention, Enums.ExternalSystemEventTypes.Error, Enums.ExternalSystemEventTypes.Info),,, pMsg);
	EndIf;
EndProcedure // DoMessage

// ----------------------------------------------------------------------------
Function CheckParameters(pName, pParameters)
	If pName = "charge" Then
		If pParameters["type"] = "M" Then
			If pParameters["article"] = Undefined Or pParameters["total"] = Undefined Then
				Return False;
			EndIf;
		ElsIf pParameters["type"] = "C" Then
			If pParameters["total"] = Undefined Or pParameters["text"] = Undefined Then
				Return False;	
			EndIf;
		ElsIf pParameters["type"] = "T" Then
			If pParameters["total"] = Undefined Or pParameters["total"] <= 0 Then
				Return False;	
			EndIf;
		Else
			Return False;	
		EndIf;
	EndIf;
	Return True;
EndFunction // CheckParameters

#EndRegion

#Region ProcessHTTP

// ----------------------------------------------------------------------------
Procedure ProcessesEvents()
	vActiveRoomInterfaceEvents = GetActiveRoomInterfaceEvents();
	For Each vActiveRoomInterfaceEvent In vActiveRoomInterfaceEvents Do
		vCommand = TrimAll(vActiveRoomInterfaceEvent.Command);
		vDocument = vActiveRoomInterfaceEvent.ParentDoc; 
		vHotelId = TrimAll(cmGetObjectExternalSystemCodeByRef(vDocument.Hotel, InteractionParameters.InteractionID, "Hotels", vDocument.Hotel));
		
		If Not ValueIsFilled(vHotelId) Then
			Continue;	
		EndIf;
		
		vRequest = "";
		If vCommand = "checkin" Then
			vRequest = GetCheckIn(vActiveRoomInterfaceEvent.Ref, vHotelId, CurrentSessionDate(), vDocument, vActiveRoomInterfaceEvent.Room, 
								  vActiveRoomInterfaceEvent.GuestIndexInRoom, JSONToMap(vActiveRoomInterfaceEvent.ExtraParameters), 
								  False);   	
		ElsIf vCommand = "guestchange" Then
			vRequest = GetChange(vActiveRoomInterfaceEvent.Ref, vHotelId, CurrentSessionDate(), vDocument, vActiveRoomInterfaceEvent.Room, 
								 vActiveRoomInterfaceEvent.OldRoom, vActiveRoomInterfaceEvent.GuestIndexInRoom, JSONToMap(vActiveRoomInterfaceEvent.ExtraParameters), 
								 vActiveRoomInterfaceEvent.IsRoomChange);    	
		ElsIf vCommand = "checkout" Then
			vRequest = GetCheckOut(vActiveRoomInterfaceEvent.Ref, vHotelId, CurrentSessionDate(), vDocument, vActiveRoomInterfaceEvent.Room, 
								   vActiveRoomInterfaceEvent.GuestIndexInRoom, False);   	
		ElsIf vCommand = "sendmessage" Then
			vRequest = GetSendMessage(vHotelId, CurrentSessionDate(), vDocument, vActiveRoomInterfaceEvent.Room, 
									  vActiveRoomInterfaceEvent.GuestIndexInRoom, cmGetDocumentNumberPresentation(vActiveRoomInterfaceEvent.Number), 
									  vActiveRoomInterfaceEvent.Remarks, vActiveRoomInterfaceEvent.MessageDateTime)        	
		EndIf; 
		
		If Not ValueIsFilled(vRequest) Then 
			vErrorMsg = NStr("en = 'Command error'; de = 'Befehlsfehler'; ru = 'Ошибка команды'");
			DoMessage(vErrorMsg + " - " + vActiveRoomInterfaceEvent.Ref, MessageStatus.Attention, "RTK.pmRun");
			vRIEObj = vActiveRoomInterfaceEvent.Ref.GetObject();
			vRIEObj.IsProcessingError = True;
			vRIEObj.ErrorMessage = vErrorMsg; 
			vRIEObj.Write(DocumentWriteMode.Write);
			Continue;	
		EndIf;
		
		If SendQuery(vRequest, vCommand) Then
			vRIEObj = vActiveRoomInterfaceEvent.Ref.GetObject();
			vRIEObj.IsProcessed = True;
			vRIEObj.PeriodOfStayExtensionIsRequested = False;
			vRIEObj.GuestNameChangeIsRequested = False;
			vRIEObj.RoomChangeIsRequested = False;
			vRIEObj.ExtraParametersChangeIsRequested = False;
			vRIEObj.ErrorMessage = "";
			vRIEObj.Write(DocumentWriteMode.Write);
			If vRIEObj.IsProcessed And vRIEObj.IsCanceled Then
				vRIEObj.SetDeletionMark(True);	
			EndIf;
		EndIf;		                                                                                    
	EndDo;	
EndProcedure // ProcessesEvents

// ----------------------------------------------------------------------------
Procedure ProcessesResyncEvents(pHotel)
	vActiveRoomInterfaceEvents = GetDocsToSync(pHotel);
	For Each vActiveRoomInterfaceEvent In vActiveRoomInterfaceEvents Do	
		vHotelId = TrimAll(cmGetObjectExternalSystemCodeByRef(pHotel, InteractionParameters.InteractionID, "Hotels", pHotel));
		vCommand = "checkout";
		
		vRequest = "";
		If ValueIsFilled(vActiveRoomInterfaceEvent.Ref) Then
			vCommand = "checkin"; 
			vRequest = GetCheckIn(vActiveRoomInterfaceEvent.Ref, vHotelId, CurrentSessionDate(), vActiveRoomInterfaceEvent.ParentDoc, vActiveRoomInterfaceEvent.Room, 
								  vActiveRoomInterfaceEvent.GuestIndexInRoom, JSONToMap(vActiveRoomInterfaceEvent.ExtraParameters), 
								  True); 	
		Else
			vRequest = GetCheckOut(Undefined, vHotelId, CurrentSessionDate(), Undefined, vActiveRoomInterfaceEvent.Room, Undefined, True); 	
		EndIf;
		
		If SendQuery(vRequest, vCommand) Then
			If ValueIsFilled(vActiveRoomInterfaceEvent.Ref) Then 
				vRIEObj = vActiveRoomInterfaceEvent.Ref.GetObject();
				vRIEObj.IsProcessed = True;
				vRIEObj.PeriodOfStayExtensionIsRequested = False;
				vRIEObj.GuestNameChangeIsRequested = False;
				vRIEObj.RoomChangeIsRequested = False;
				vRIEObj.ExtraParametersChangeIsRequested = False;
				vRIEObj.ErrorMessage = "";
				vRIEObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;		                                                                                    
	EndDo;	
EndProcedure // ProcessesResyncEvents

// -----------------------------------------------------------------------------
//
// Parameters:
//  pName			 - String	 - Method description
//  pJSON			 - String	 - Json
//  rResponseCode	 - Number	 - Response code
//  rMessage		 - String	 - Error decription
// 
// Returns:
//  String - Json
//
Function pmHTTPRequest(Val pName, Val pJSON, rResponseCode, rMessage) Export
	vParameters = JSONToMap(pJSON);
	
	vResponse = New Map;
	vResponse.Insert("code", "0");
	Try
		If vParameters["hotelId"] <> Undefined Then
			vHotel = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), InteractionParameters.InteractionID, "Hotels", vParameters["hotelId"]); 
			
			If ValueIsFilled(vHotel) Then
				If pName = "resyncrequest" Or pName = "charge" Then
					If CheckParameters(pName, vParameters) Then
						vAsyncParams = New Array;
						vAsyncParams.Add(pName);
						vAsyncParams.Add(vHotel);
						vAsyncParams.Add(vParameters);
						AsyncCalls.StartBackgroundJob("ProlongedOperations.RTKBackgroundJobRequest", vAsyncParams);
					Else
						vResponse.Insert("code", "9");	
					EndIf;
				Else
					vDocument = GetDocument(vHotel, vParameters);	
					
					If ValueIsFilled(vDocument) Then
						If pName = "bill" Then
							vResponse.Insert("response", Bill(vDocument, vParameters));	
						ElsIf pName = "messageretrieved" Then
							vRoomInterfaceStatusRef = GetRoomInterfaceStatus(vDocument.Number, vDocument.GuestGroup, Right(vParameters["pmsRegNum"], 2), "sendmessage");
							If ValueIsFilled(vRoomInterfaceStatusRef) Then
								vRoomInterfaceStatusObj 			= vRoomInterfaceStatusRef.GetObject();
								vRoomInterfaceStatusObj.IsCanceled 	= True;
								vRoomInterfaceStatusObj.IsProcessed = True;
								vRoomInterfaceStatusObj.Write();
							Else
								vResponse.Insert("code", "9");	
							EndIf;	
						ElsIf pName = "sendmessage" Then
							For Each vMessage In vParameters["messages"] Do
								vMessageObj 				= Documents.Message.CreateDocument();
								vMessageObj.Type			= Enums.MessageTypes.Message;
								vMessageObj.Date			= CurrentSessionDate();
								vMessageObj.ByObject 		= vDocument;
								If ValueIsFilled(vHotel.ReservationDepartment) Then
									vMessageObj.ForDepartment = vHotel.ReservationDepartment;
								EndIf;
								vMessageObj.Remarks = vMessage["Text"];
								vMessageObj.Write(DocumentWriteMode.Posting);
							EndDo;
						EndIf;
					Else
						vResponse.Insert("code", "2");	
					EndIf;  
				EndIf;
			Else
				vResponse.Insert("code", "1");	
			EndIf;
		Else   
			If pName = "resyncrequest" Then   
				vResponse.Insert("code", "2");	
			Else
				vResponse.Insert("code", "9");
			EndIf;
		EndIf;
	Except
		If pName = "resyncrequest" Then   
			vResponse.Insert("code", "2");	
		Else
			vResponse.Insert("code", "9");
		EndIf;
		vError = ErrorInfo(); 
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "pmHTTPRequest." + pName, Enums.ExternalSystemEventTypes.Error, pJSON, MapToJSON(vResponse), "HTTP request processing error! " + DetailErrorDescription(vError), InteractionParameters.MaxLogLenght);
	EndTry;
	
	Return MapToJSON(vResponse); 
EndFunction // pmHTTPRequest

// -----------------------------------------------------------------------------
//
// Parameters:
//  pName		 - String		 - Method description
//  pHotel		 - CatalogRef.Hotels - Catalog ref
//  pParameters	 - Map				 - Parameters
//
Procedure pmBackgroundJobRequest(Val pName, Val pHotel, Val pParameters) Export
	If pName = "charge" Then
		vSale 					 = New Structure("hotelId, postingSequenceNum, dateTime, dateTimeTS, roomNumber, status, posId, dateTime, checkNum, text");
		vSale.hotelId 			 = TrimAll(cmGetObjectExternalSystemCodeByRef(pHotel, InteractionParameters.InteractionID, "Hotels", pHotel));
		vSale.roomNumber 		 = pParameters["roomNumber"];
		vSale.posId 			 = pParameters["posId"];
		vSale.checkNum 			 = pParameters["checkNum"]; 
		vSale.postingSequenceNum = pParameters["postingSequenceNum"];
		vDateTime = CurrentSessionDate();
		vSale.dateTime 			 = GetFormatDateByDate(vDateTime);
		vSale.dateTimeTS 		 = GetTimestampByDate(vDateTime);
		
		vResult = "";
		
		Try
			If pParameters["type"] = "M" Then
				vResult = Sale(pHotel, pParameters["roomNumber"], pParameters["posId"], pParameters["checkNum"], pParameters["article"], pParameters["quantity"], pParameters["total"] / 100);
			ElsIf pParameters["type"] = "C" Then
				vResult = Sale(pHotel, pParameters["roomNumber"], pParameters["posId"], pParameters["checkNum"], , , pParameters["total"] / 100, pParameters["text"]);
			ElsIf pParameters["type"] = "T" Then
				vResult = WritePhoneCall(pHotel, pParameters["roomNumber"], GetDateByTimestamp(pParameters["checkNum"]), pParameters["duration"], pParameters["dialedDigits"], pParameters["total"] / 100, pParameters["text"]);	 
			EndIf; 
		Except
			vErrorInfo = ErrorInfo();
			vResult = BriefErrorDescription(vErrorInfo); 
		EndTry;

		If IsBlankString(vResult) Then
			vSale.status 	= 0;
			vSale.text 		= "Posting successful.";
		Else
			vSale.status = 9;
			vSale.text 		= vResult;
		EndIf;  
		
		SendQuery(MapToJSON(vSale), "saledone");
	ElsIf pName = "resyncrequest" Then
		If SendQuery(GetResyncStartAndEnd(pParameters["hotelId"], CurrentSessionDate()), "resyncstart") Then
			ProcessesResyncEvents(pHotel); 
			SendQuery(GetResyncStartAndEnd(pParameters["hotelId"], CurrentSessionDate()), "resyncend"); 
		EndIf;	
	EndIf;
EndProcedure // pmHTTPRequest

// ----------------------------------------------------------------------------
Function SendQuery(pJSON, pName)
	vHttp = StrReplace(StrReplace(InteractionParameters.WSHost, "https://", ""), "http://", "");
	
	vHTTPServer = Left(vHttp, StrFind(vHttp, "/") - 1); 
	vRequestURL = Right(vHttp, StrLen(vHttp) - StrFind(vHttp, "/") + 1) + ?(Right(vHttp, 1) = "/", TrimAll(pName), "/" + TrimAll(pName));	
	Try     
		// HTTP header
		vHTTPHeader = New Map();
		vHTTPHeader.Insert("Content-Type", "application/json");
		
		// Set SSL
		vSSL = Undefined;
		If InteractionParameters.HttpUseSsl Then
			vSSL = New OpenSSLSecureConnection(Undefined, Undefined);       	
		EndIf;
		
		// HTTP connection
		vHTTPConnection = New HTTPConnection(vHTTPServer,,,,, 15, vSSL);
		vHTTPRequest = New HTTPRequest(vRequestURL, vHTTPHeader);
		
		vRequestBody = pJSON;
		vHTTPRequest.SetBodyFromString(vRequestBody);
		
		vRs = vHTTPConnection.CallHTTPMethod("POST", vHTTPRequest);
		
		vRSString = vRs.GetBodyAsString(TextEncoding.UTF8); 
				
		Try
			vResponse = JSONToMap(vRSString);
			If vResponse["code"] = 0 Then
				If InteractionParameters.DebugMode Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, pName, Enums.ExternalSystemEventTypes.Info, pJSON, vRSString,, InteractionParameters.MaxLogLenght); 
				EndIf;
				Return True;	
			Else     
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, pName, Enums.ExternalSystemEventTypes.Error, pJSON, vRSString,, InteractionParameters.MaxLogLenght);
				Return False;
			EndIf;
		Except   
			vError = ErrorInfo(); 
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "SendQuery." + pName, Enums.ExternalSystemEventTypes.Error, pJSON, vRSString, "Cant read request body as JSON " + DetailErrorDescription(vError), InteractionParameters.MaxLogLenght);
			Return False;	
		EndTry;
	Except
		vError = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "SendQuery" + pName, Enums.ExternalSystemEventTypes.Error, pJSON, "", "Failed to send post query! " + DetailErrorDescription(vError), InteractionParameters.MaxLogLenght);
		Return False;
	EndTry;
EndFunction // SendQuery

#EndRegion