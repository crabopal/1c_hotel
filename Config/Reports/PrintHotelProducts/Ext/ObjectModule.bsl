// -----------------------------------------------------------------------------
Procedure SetParameters(pArea, pHotelProduct, pGuest, pAddGuests, pRoom, pRoomType, pPaymentMethod, 
                               pCheckInDate, pCheckOutDate, pCompany, pAmount, pHotelProductSum, pSeller)
	// Guest
	If ValueIsFilled(pGuest) Then
		vGuestFullName = TrimAll(pGuest.FullName);
		pArea.Parameters.mGuestFullName = vGuestFullName;
		pArea.Parameters.mGuestName1 = vGuestFullName;
		pArea.Parameters.mGuestName2 = "";
		// Split guest name to 2 parts
		vBlankPos = Find(vGuestFullName, " ");
		If vBlankPos > 0 Then
			pArea.Parameters.mGuestName1 = TrimAll(Left(vGuestFullName, vBlankPos - 1));
			pArea.Parameters.mGuestName2 = TrimAll(Mid(vGuestFullName, vBlankPos + 1));
		EndIf;
	Else
		pArea.Parameters.mGuestFullName = "";
		pArea.Parameters.mGuestName1 = "";
		pArea.Parameters.mGuestName2 = "";
	EndIf;
	
	// Room and room parent
	If ValueIsFilled(pRoom) Then
		pArea.Parameters.mRoom = TrimAll(pRoom);
		vRoomParent = pRoom.Parent;
		While ValueIsFilled(vRoomParent) Do
			If Not ValueIsFilled(vRoomParent.Parent) Then
				Break;
			EndIf;
			vRoomParent = vRoomParent.Parent;
		EndDo;
		If ValueIsFilled(vRoomParent) Then
			pArea.Parameters.mRoomParent = TrimAll(vRoomParent);
		Else
			pArea.Parameters.mRoomParent = "";
		EndIf;
	Else
		pArea.Parameters.mRoom = "";
		pArea.Parameters.mRoomParent = "";
	EndIf;
	
	// Room type
	pArea.Parameters.mRoomType = TrimAll(pRoomType);
	
	// Additional guests
	vNumberOfAdditionalGuests = 0;
	vNamesOfAdditionalGuests = "";
	If TypeOf(pAddGuests) = Type("ValueList") Then
		If pAddGuests.Count() > 0 Then
			For Each pAddGuestsItem In pAddGuests Do
				vAddGuest = pAddGuestsItem.Value;
				If ValueIsFilled(vAddGuest) And vAddGuest <> pGuest Then
					If IsBlankString(vNamesOfAdditionalGuests) Then
						vNamesOfAdditionalGuests = TrimAll(vAddGuest.FullName);
					Else
						vNamesOfAdditionalGuests = vNamesOfAdditionalGuests + ", " + TrimAll(vAddGuest.FullName);
					EndIf;
					vNumberOfAdditionalGuests = vNumberOfAdditionalGuests + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	pArea.Parameters.mAdditionalGuests = vNamesOfAdditionalGuests;
	pArea.Parameters.mAdditionalGuests1 = "";
	pArea.Parameters.mAdditionalGuests2 = "";
	If Not IsBlankString(vNamesOfAdditionalGuests) Then
		// Split additional guest names to 2 parts
		vBlankPos = Find(vNamesOfAdditionalGuests, " ");
		If vBlankPos > 0 Then
			pArea.Parameters.mAdditionalGuests1 = TrimAll(Left(vNamesOfAdditionalGuests, vBlankPos - 1));
			pArea.Parameters.mAdditionalGuests2 = TrimAll(Mid(vNamesOfAdditionalGuests, vBlankPos + 1));
		EndIf;
	EndIf;
	
	// Accommodation period
	If ValueIsFilled(pCheckInDate) Then
		pArea.Parameters.mCheckInDate = Format(pCheckInDate, "DF=dd.MM.yyyy");
	Else
		pArea.Parameters.mCheckInDate = "";
	EndIf;
	If ValueIsFilled(pCheckOutDate) Then
		pArea.Parameters.mCheckOutDate = Format(pCheckOutDate, "DF=dd.MM.yyyy");
	Else
		pArea.Parameters.mCheckOutDate = "";
	EndIf;
	
	// Number of guests
	pArea.Parameters.mNumberOfGuests = Format(1 + vNumberOfAdditionalGuests, "ND=6; NFD=0; NG=");
	
	// Sum in words
	vSumInWords = pAmount;
	vSumInWords = cmSumInWords(pAmount, pHotelProduct.Currency, SessionParameters.CurrentLanguage);
	// Split sum in words by first blank after 40 symbol
	pArea.Parameters.mProductSumInWords1 = vSumInWords;
	pArea.Parameters.mProductSumInWords2 = "";
	If StrLen(vSumInWords) > 40 Then
		vBlankPos = Find(Mid(vSumInWords, 41), " ");
		If vBlankPos > 0 Then
			pArea.Parameters.mProductSumInWords1 = TrimAll(Left(vSumInWords, 40 + vBlankPos - 1));
			pArea.Parameters.mProductSumInWords2 = TrimAll(Mid(vSumInWords, 40 + vBlankPos + 1));
		EndIf;
	EndIf;
	
	// Sell date
	pArea.Parameters.mSellDate = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");
	
	// Manager name
	pArea.Parameters.mManagerName = TrimAll(pSeller);
EndProcedure // SetParameters
	
// -----------------------------------------------------------------------------
Procedure PrintProduct(pSpreadsheet, pArea, pHotelProduct, pPutPageBreak = False, pHotelProducts)
	If Not ValueIsFilled(pHotelProduct) Then
		Return;
	EndIf;
	
	// New page
	If pPutPageBreak Then
		pSpreadsheet.PutHorizontalPageBreak();
	EndIf;
	
	// Find main document for the hotel product
	vDocument = Undefined;
	// Fill list of additional guests (children e.t.c.) 
	vAdditionalGuests = New ValueList();
	// Get list of documents for the product
	vHPDocs = pHotelProduct.GetObject().pmGetHotelProductDocuments();
	If vHPDocs.Count() > 0 Then
		vDocument = vHPDocs.Get(0).Document;
		vHPDocs.GroupBy("Guest",);
		vAdditionalGuests.LoadValues(vHPDocs.UnloadColumn("Guest"));
	EndIf;
	
	// Calculate and set parameters
	vAmount = pHotelProduct.GetObject().pmGetHotelProductAmount();
	vClient = Catalogs.Clients.EmptyRef();
	vRoom = Catalogs.Rooms.EmptyRef();
	vRoomType = Catalogs.RoomTypes.EmptyRef();
	vPaymentMethod = Undefined;
	If ValueIsFilled(vDocument) Then
		If TypeOf(vDocument) = Type("DocumentRef.Folio") Then
			vClient = vDocument.Client;
			vRoom = vDocument.Room;
			If ValueIsFilled(vDocument.Room) Then
				vRoomType = vDocument.Room.RoomType;
			EndIf;
			vPaymentMethod = vDocument.PaymentMethod;
		Else
			vClient = vDocument.Guest;
			vRoom = vDocument.Room;
			vRoomType = vDocument.RoomType;
			vPaymentMethod = vDocument.PlannedPaymentMethod;
		EndIf;
	EndIf;
	SetParameters(pArea, pHotelProduct, vClient, vAdditionalGuests, vRoom, vRoomType, vPaymentMethod, 
                         pHotelProduct.CheckInDate, pHotelProduct.CheckOutDate, vDocument.Company, 
						 vAmount, pHotelProduct.Sum, vDocument.Author);
	
	// Put hotel product
	pSpreadsheet.Put(pArea);
	
	// Add row to the hotel products value table
	vHPRow = New Structure("HotelProduct, Client, Room", pHotelProduct, vClient, vRoom);
	pHotelProducts.Add(vHPRow);
EndProcedure // PrintProduct

// -----------------------------------------------------------------------------
Procedure PrintProducts(pSpreadsheet, pArea, pHotelProducts)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.HotelProduct
	|FROM
	|	(SELECT
	|		Accommodations.HotelProduct AS HotelProduct
	|	FROM
	|		Document.Accommodation AS Accommodations
	|	WHERE
	|		Accommodations.Posted
	|		AND Accommodations.HotelProduct <> &qEmptyHotelProduct
	|		AND (Accommodations.GuestGroup = &qGuestGroup OR &qGuestGroupIsEmpty)
	|		AND (Accommodations.Room IN HIERARCHY (&qRoom) OR &qRoomIsEmpty)
	|		AND (BEGINOFPERIOD(Accommodations.CheckInDate, DAY) >= &qBegOfCheckInDate
	|				OR &qCheckInDateIsEmpty)
	|		AND (ENDOFPERIOD(Accommodations.CheckInDate, DAY) <= &qEndOfCheckInDate
	|				OR &qCheckInDateIsEmpty)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Reservations.HotelProduct
	|	FROM
	|		Document.Reservation AS Reservations
	|	WHERE
	|		Reservations.Posted
	|		AND Reservations.HotelProduct <> &qEmptyHotelProduct
	|		AND (Reservations.GuestGroup = &qGuestGroup OR &qGuestGroupIsEmpty)
	|		AND (Reservations.Room IN HIERARCHY (&qRoom) OR &qRoomIsEmpty)
	|		AND (BEGINOFPERIOD(Reservations.CheckInDate, DAY) >= &qBegOfCheckInDate
	|				OR &qCheckInDateIsEmpty)
	|		AND (ENDOFPERIOD(Reservations.CheckInDate, DAY) <= &qEndOfCheckInDate
	|				OR &qCheckInDateIsEmpty)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Charges.HotelProduct
	|	FROM
	|		Document.Charge AS Charges
	|	WHERE
	|		Charges.Posted
	|		AND Charges.HotelProduct <> &qEmptyHotelProduct
	|		AND (Charges.Folio.GuestGroup = &qGuestGroup OR &qGuestGroupIsEmpty)
	|		AND (Charges.Folio.Room = &qRoom OR &qRoomIsEmpty)
	|		AND (BEGINOFPERIOD(Charges.Folio.DateTimeFrom, DAY) >= &qBegOfCheckInDate
	|				OR &qCheckInDateIsEmpty)
	|		AND (ENDOFPERIOD(Charges.Folio.DateTimeFrom, DAY) <= &qEndOfCheckInDate
	|				OR &qCheckInDateIsEmpty)) AS Docs
	|
	|GROUP BY
	|	Docs.HotelProduct
	|
	|ORDER BY
	|	Docs.HotelProduct.Code";
	vQry.SetParameter("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
	vQry.SetParameter("qGuestGroup", GuestGroup);
	vQry.SetParameter("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qRoomIsEmpty", Not ValueIsFilled(Room));
	vQry.SetParameter("qBegOfCheckInDate", BegOfDay(CheckInDate));
	vQry.SetParameter("qEndOfCheckInDate", EndOfDay(CheckInDate));
	vQry.SetParameter("qCheckInDateIsEmpty", Not ValueIsFilled(CheckInDate));
	vHotelProducts = vQry.Execute().Unload();
	vIsFirstDoc = True;
	For Each vRow In vHotelProducts Do
		PrintProduct(pSpreadsheet, pArea, vRow.HotelProduct, Not vIsFirstDoc, pHotelProducts);
		If vIsFirstDoc Then
			vIsFirstDoc = False;
		EndIf;
	EndDo;
EndProcedure // PrintProducts

// -----------------------------------------------------------------------------
Procedure PrintProductsList(pSpreadsheet, pArea, pHotelProducts)
	vIsFirstDoc = True;
	For Each vItem In DocumentsList Do
		PrintProduct(pSpreadsheet, pArea, vItem.Value.HotelProduct, Not vIsFirstDoc, pHotelProducts);
		If vIsFirstDoc Then
			vIsFirstDoc = False;
		EndIf;
	EndDo;
EndProcedure // PrintProducts

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet, pTemplate = Undefined, pHotelProducts) Export
	// Initialize value table with hotel products to print
	pHotelProducts = New Array();
	
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Product");
	If pTemplate <> Undefined Then
		vTemplate = pTemplate;
	EndIf;
	
	// Guest card area
	vArea = vTemplate.GetArea("Product");
	
	// Call processings	
	If ValueIsFilled(Document) Then
		PrintProduct(pSpreadsheet, vArea, Document.HotelProduct, False, pHotelProducts);
	ElsIf ValueIsFilled(GuestGroup) Or ValueIsFilled(CheckInDate) Or ValueIsFilled(Room) Then
		PrintProducts(pSpreadsheet, vArea, pHotelProducts);
	ElsIf DocumentsList.Count() > 0 Then
		PrintProductsList(pSpreadsheet, vArea, pHotelProducts);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru = 'Для печати не выбраны ни документ ни группа гостей ни номер ни дата заезда!'; 
		             |en = 'Neither document no guest group or room or check-in date are selected for printing!';
					 |de = 'Weder Dokument, noch Gästegruppe oder Zimmer oder Check-in-Datum werden zum Drucken ausgewählt!'"));
	EndIf;
EndProcedure // pmGenerate
