
#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
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
	// Fill parameters with default values
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	MedicineSystemWSDLConnectionString = "http://localhost/poliklinika/ws/1CMedicineHotelInterfaces.1cws?wsdl";
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//  Run data processor in silent mode
//
// Parameters:
//  pParameter		 - Structure - Params
//  pIsInteractive	 - Boolean	 - IsInteractive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	NumberOfExportedPersons = 0;
	// Check attributes
	If Not ValueIsFilled(Hotel) Then
		Raise NStr("en='Fill hotel!'; 
		           |ru='Укажите гостиницу!'");
	EndIf;
	If IsBlankString(MedicineSystemWSDLConnectionString) Then
		Raise NStr("en='1C Medicine interface service address should be specified!'; 
		           |ru='Укажите адрес к WSDL службе гостиничного интерфейса 1С:Медицины!'");
	EndIf;
	// 1. Get clients to be exported
	If ExportGuestsWithMedicinePackagesOnly Then
		// Only guests with medicine service packages attached will be exported
		vClients = GetExportedClientsWithMedicinePackagesOnly();
	Else	
		// Guests with room assigned or medicine service packages attached will be exported
		vClients = GetExportedClients();
	EndIf;
	// Get clients without reservations with folios only
	vExternalClients = GetExternalClients();
	// Add clients with service packages removed or discounts removed
	FillRemoveItems(vClients);
	// Start export procedure
	vLastExportPeriod = CurrentSessionDate();
	// 2. Write to 1C Medicine
	BeginTransaction();         
	Try
		vClients.GroupBy("Client, DiscountType, Doc, ExternalCode, GuestCode, IsDeleteDiscount, IsDeletePackage, Number, OperationType, Quantity, Room, ServicePackage, IsCancelled"); 
		If vClients.Count() > 0 Then
			Write2Medicine(vClients);
		EndIf;
		If vExternalClients.Count() > 0 Then
			WriteExternalClients2Medicine(vExternalClients);
		EndIf;
		// 3. Save current data processor's attributes
		LastExportPeriod = vLastExportPeriod;
		pmSaveDataProcessorAttributes();
		CommitTransaction();   
	Except
		RollbackTransaction();
		tcCommonFunctionOnClientServer.UserMessage(ErrorDescription());
	EndTry;
EndProcedure // pmRun

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillRemoveItems(pClients)
	// Add removed service packages and discounts from normal documents
	AddRemovePackagesDiscounts(pClients.Copy(), pClients);
	
	// Check all reservations for removing packages
	vReservationsChanges = GetReservationsChanges(pClients.UnloadColumn("Doc"));
	AddRemovePackagesDiscounts(vReservationsChanges, pClients);	
	
	// Add annulation docs
	AnnulationPackages = GetExportedAnnulationClients();
	For Each vPack In AnnulationPackages Do
		vStr = pClients.Add();
		FillPropertyValues(vStr, vPack);
	EndDo;	
	
	// Add remove discounts
	vClientsHistoryChanges = GetClientsHistoryChanges();
	For Each vClient In vClientsHistoryChanges Do
		vHistoryDoc = InformationRegisters.ClientChangeHistory.GetLast(LastExportPeriod, New Structure("Client", vClient.Client));
		
		If ValueIsFilled(vHistoryDoc.FullName) Then
			If ValueIsFilled(vHistoryDoc.DiscountType) And Not ValueIsFilled(vClient.DiscountType) Then
				vStr = pClients.Add();
				vStr.Doc = Documents.Accommodation.EmptyRef();
				vStr.ServicePackage	  = Catalogs.ServicePackages.EmptyRef();	
				vStr.DiscountType	  = vHistoryDoc.DiscountType;
				vStr.Client			  = vClient.Client;
				vStr.GuestCode		  = vClient.Client.Code;
				vStr.Quantity		  = 0;
				vStr.OperationType	  = "NEW";
				vStr.ExternalCode     = "";
				vStr.Room			  = Catalogs.Rooms.EmptyRef();
				vStr.Number           = "";
				vStr.IsDeletePackage  = False;
				vStr.IsDeleteDiscount = True;
				vStr.IsCancelled	  = False;
			EndIf;	
		EndIf;	
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
Function GetHistoryChanges(pDoc) 
	vHistory = Undefined;
	If ValueIsFilled(pDoc) Then
		If TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
			vHistoryDoc = InformationRegisters.AccommodationChangeHistory.GetLast(LastExportPeriod, New Structure("Accommodation", pDoc));
			If Not vHistoryDoc.AccommodationStatus.IsEmpty() Then
				vHistory = vHistoryDoc;
			EndIf;	
		ElsIf TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
			vHistoryDoc = InformationRegisters.ReservationChangeHistory.GetLast(LastExportPeriod, New Structure("Reservation", pDoc));
			If Not vHistoryDoc.ReservationStatus.IsEmpty() Then
				vHistory = vHistoryDoc;
			EndIf;	
		EndIf;
	EndIf;	
	Return vHistory;
EndFunction // GetHistoryChanges()

// -----------------------------------------------------------------------------
Procedure AddRemovePackagesDiscounts(pTabDocsIn, pTabDocsOut) 
	For Each vIndClient In pTabDocsIn Do
		// For each line we get a history of changes
		vHistoryLine = GetHistoryChanges(vIndClient.Doc);
		If Not vHistoryLine = Undefined Then
			// Old table packages
			vHistoryPackages = New Array();
			If ValueIsFilled(vHistoryLine.ServicePackage) And vHistoryLine.ServicePackage.IsMedicine Then
				vHistoryPackages.Add(vHistoryLine.ServicePackage);
			EndIf;
			For Each vPack In vHistoryLine.ServicePackages.Get() Do
				If vPack.ServicePackage.IsMedicine Then
					vHistoryPackages.Add(vPack.ServicePackage);
				EndIf;
			EndDo;	
			If ValueIsFilled(vHistoryLine.RoomRate.ServicePackage) And vHistoryLine.RoomRate.ServicePackage.IsMedicine Then
				vHistoryPackages.Add(vHistoryLine.ServicePackage);
			EndIf;
			For Each vPack In vHistoryLine.RoomRate.ServicePackages Do
				If vPack.ServicePackage.IsMedicine Then
					vHistoryPackages.Add(vPack.ServicePackage);
				EndIf;
			EndDo;
			// New table packages
			vCurrPackages    = New Array();
			If ValueIsFilled(vIndClient.Doc.ServicePackage) And vIndClient.Doc.ServicePackage.IsMedicine Then
				vCurrPackages.Add(vIndClient.Doc.ServicePackage);
			EndIf;
			For Each vPack In vIndClient.Doc.ServicePackages Do
				If vPack.ServicePackage.IsMedicine Then
					vCurrPackages.Add(vPack.ServicePackage);
				EndIf;
			EndDo;	
			If ValueIsFilled(vIndClient.Doc.RoomRate.ServicePackage) And vIndClient.Doc.RoomRate.ServicePackage.IsMedicine Then
				vCurrPackages.Add(vIndClient.Doc.RoomRate.ServicePackage);
			EndIf;
			For Each vPack In vIndClient.Doc.RoomRate.ServicePackages Do
				If vPack.ServicePackage.IsMedicine Then
					vCurrPackages.Add(vPack.ServicePackage);
				EndIf;
			EndDo;
			For Each vPack In vHistoryPackages Do
				vIsDeletePackage = vCurrPackages.Find(vPack) = Undefined;
				If vIsDeletePackage Then
					vStr = pTabDocsOut.Add();
					FillPropertyValues(vStr, vIndClient);
					vStr.ServicePackage  = vPack;
					vStr.IsDeletePackage = vIsDeletePackage;
				EndIf;
			EndDo;	
			If ValueIsFilled(vHistoryLine.DiscountType) And Not ValueIsFilled(vIndClient.DiscountType) Then
				vStr = pTabDocsOut.Add();
				FillPropertyValues(vStr, vIndClient);
				vStr.DiscountType	  = vHistoryLine.DiscountType;
				vStr.IsDeleteDiscount = True;
			EndIf;	
		EndIf;	
	EndDo;	
EndProcedure	

// -----------------------------------------------------------------------------
Function GetClientsHistoryChanges()
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ClientChangeHistory.Client AS Client,
		|	ClientChangeHistory.DiscountType AS DiscountType
		|INTO ChangesClients
		|FROM
		|	InformationRegister.ClientChangeHistory AS ClientChangeHistory
		|WHERE
		|	ClientChangeHistory.Period > &qPeriodFrom
		|	AND ClientChangeHistory.DiscountType = VALUE(Catalog.DiscountTypes.EmptyRef)
		|
		|GROUP BY
		|	ClientChangeHistory.Client,
		|	ClientChangeHistory.DiscountType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ChangesClients.Client AS Client,
		|	ClientChangeHistorySliceLast.DiscountType AS DiscountType
		|FROM
		|	ChangesClients AS ChangesClients
		|		LEFT JOIN InformationRegister.ClientChangeHistory.SliceLast(
		|				&qPeriodFrom,
		|				Client IN
		|					(SELECT
		|						ChangesClients.Client
		|					FROM
		|						ChangesClients AS ChangesClients)) AS ClientChangeHistorySliceLast
		|		ON ChangesClients.Client = ClientChangeHistorySliceLast.Client
		|WHERE
		|	NOT ClientChangeHistorySliceLast.DiscountType.Ref IS NULL
		|	AND (NOT &qDateOfBirthIsFilled
		|			OR &qDateOfBirthIsFilled
		|				AND ISNULL(ChangesClients.Client.DateOfBirth, &qEmptyDate) > &qEmptyDate)";
	vQuery.SetParameter("qPeriodFrom", LastExportPeriod);
	vQuery.SetParameter("qEmptyDate", '00010101');
	vQuery.SetParameter("qDateOfBirthIsFilled", ExportGuestsWithDateOfBirthOnly);
	vQueryResult = vQuery.Execute().Unload();
    Return vQueryResult;
EndFunction // GetClientsHistoryChanges()

// -----------------------------------------------------------------------------
Function GetReservationsChanges(pTadDocs)
	vQry = New Query;
	vQry.Text = 
		"SELECT
		|	ReservationChangeHistory.Reservation AS Doc,
		|	ReservationChangeHistory.ServicePackage AS ServicePackage,
		|	ReservationChangeHistory.DiscountType AS DiscountType,
		|	&q3BytesString AS OperationType,
		|	ReservationChangeHistory.Reservation.Number AS Number,
		|	ReservationChangeHistory.Room AS Room,
		|	ReservationChangeHistory.Guest AS Client,
		|	ReservationChangeHistory.Guest.Code AS GuestCode,
		|	ReservationChangeHistory.Reservation.ExternalCode AS ExternalCode,
		|	1 AS Quantity,
		|	TRUE AS IsDeletePackage,
		|	FALSE AS IsDeleteDiscount,
		|	NOT(ISNULL(ReservationChangeHistory.Reservation.ReservationStatus.IsActive, FALSE)
		|			OR ISNULL(ReservationChangeHistory.Reservation.ReservationStatus.IsPreliminary, FALSE)) AS IsCancelled
		|FROM
		|	InformationRegister.ReservationChangeHistory AS ReservationChangeHistory
		|		LEFT JOIN Document.Accommodation AS Accommodation
		|		ON ReservationChangeHistory.Reservation = Accommodation.Reservation
		|WHERE
		|	ReservationChangeHistory.Period > &qPeriodFrom
		|	AND NOT ReservationChangeHistory.Reservation.ReservationStatus.IsCheckIn
		|	AND ReservationChangeHistory.Guest <> VALUE(Catalog.Clients.EmptyRef)
		|	AND ReservationChangeHistory.Reservation.Guest <> VALUE(Catalog.Clients.EmptyRef)
		|	AND ReservationChangeHistory.Reservation.Guest.LastName <> &qEmptyString
		|	AND ReservationChangeHistory.Reservation.Guest.FirstName <> &qEmptyString
		|	AND ReservationChangeHistory.Hotel = &qHotel
		|	AND NOT ReservationChangeHistory.Reservation.Ref IN (&qTadDocs)
		|	AND Accommodation.Ref IS NULL
		|	AND (NOT &qDateOfBirthIsFilled
		|			OR &qDateOfBirthIsFilled
		|				AND ISNULL(ReservationChangeHistory.Guest.DateOfBirth, &qEmptyDate) > &qEmptyDate)
		|
		|GROUP BY
		|	ReservationChangeHistory.Reservation,
		|	ReservationChangeHistory.Guest,
		|	ReservationChangeHistory.Room,
		|	ReservationChangeHistory.ServicePackage,
		|	ReservationChangeHistory.DiscountType,
		|	ReservationChangeHistory.Reservation.Number,
		|	ReservationChangeHistory.Guest.Code,
		|	ReservationChangeHistory.Reservation.ExternalCode,
		|	NOT(ISNULL(ReservationChangeHistory.Reservation.ReservationStatus.IsActive, FALSE)
		|			OR ISNULL(ReservationChangeHistory.Reservation.ReservationStatus.IsPreliminary, FALSE))";
	vQry.SetParameter("qPeriodFrom", LastExportPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qTadDocs", pTadDocs);
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("q3BytesString", "   ");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qDateOfBirthIsFilled", ExportGuestsWithDateOfBirthOnly);
	vClients = vQry.Execute().Unload();
	For Each vClientsRow In vClients Do
		vIsNewClient = IsBlankString(vClientsRow.ExternalCode);
		If vIsNewClient Then
			vClientsRow.OperationType = "NEW";
			vClientsRow.ExternalCode = ""; 
		Else
			vClientsRow.OperationType = "UPD";
		EndIf;		
	EndDo;
	Return vClients;
EndFunction	// GetReservationsChanges

// -----------------------------------------------------------------------------
Function GetExportedClients()
	// Run query based on documents change history
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AllReservations.Doc AS Doc
	|INTO AllRes
	|FROM
	|	(SELECT
	|		ReservationChangeHistory.Reservation AS Doc
	|	FROM
	|		InformationRegister.ReservationChangeHistory AS ReservationChangeHistory
	|			LEFT JOIN Document.Accommodation AS Accommodations
	|			ON ReservationChangeHistory.Reservation = Accommodations.Reservation
	|				AND (Accommodations.Posted)
	|				AND (ISNULL(Accommodations.AccommodationStatus.IsActive, FALSE))
	|	WHERE
	|		ReservationChangeHistory.Period > &qPeriodFrom
	|		AND ReservationChangeHistory.Reservation.Posted
	|		AND NOT ReservationChangeHistory.Reservation.ReservationStatus.IsCheckIn
	|		AND ReservationChangeHistory.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|		AND ReservationChangeHistory.Reservation.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|		AND ReservationChangeHistory.Reservation.Guest.LastName <> &qEmptyString
	|		AND ReservationChangeHistory.Reservation.Guest.FirstName <> &qEmptyString
	|		AND ReservationChangeHistory.Hotel = &qHotel
	|		AND Accommodations.Ref IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ClientReservations.Ref
	|	FROM
	|		InformationRegister.ClientChangeHistory AS ClientChangeHistory
	|			INNER JOIN Document.Reservation AS ClientReservations
	|			ON ClientChangeHistory.Client = ClientReservations.Guest
	|				AND (ClientReservations.Posted)
	|				AND (ClientReservations.Hotel = &qHotel)
	|				AND (ClientReservations.ReservationStatus.IsActive
	|					OR ClientReservations.ReservationStatus.IsPreliminary)
	|	WHERE
	|		ClientChangeHistory.Period > &qPeriodFrom
	|		AND ClientChangeHistory.Client.LastName <> &qEmptyString
	|		AND ClientChangeHistory.Client.FirstName <> &qEmptyString) AS AllReservations
	|
	|GROUP BY
	|	AllReservations.Doc
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllAccommodations.Doc AS Doc
	|INTO AllAcc
	|FROM
	|	(SELECT
	|		AccommodationChangeHistory.Accommodation AS Doc
	|	FROM
	|		InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|	WHERE
	|		AccommodationChangeHistory.Period > &qPeriodFrom
	|		AND AccommodationChangeHistory.Accommodation.AccommodationStatus.IsActive
	|		AND AccommodationChangeHistory.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|		AND AccommodationChangeHistory.Accommodation.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|		AND AccommodationChangeHistory.Accommodation.Guest.LastName <> &qEmptyString
	|		AND AccommodationChangeHistory.Accommodation.Guest.FirstName <> &qEmptyString
	|		AND AccommodationChangeHistory.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|		AND AccommodationChangeHistory.Hotel = &qHotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ClientAccommodations.Ref
	|	FROM
	|		InformationRegister.ClientChangeHistory AS ClientChangeHistory
	|			INNER JOIN Document.Accommodation AS ClientAccommodations
	|			ON ClientChangeHistory.Client = ClientAccommodations.Guest
	|				AND (ClientAccommodations.Posted)
	|				AND (ClientAccommodations.AccommodationStatus.IsActive)
	|				AND (ClientAccommodations.AccommodationStatus.IsInHouse)
	|				AND (ClientAccommodations.Hotel = &qHotel)
	|	WHERE
	|		ClientChangeHistory.Period > &qPeriodFrom
	|		AND ClientChangeHistory.Client.LastName <> &qEmptyString
	|		AND ClientChangeHistory.Client.FirstName <> &qEmptyString) AS AllAccommodations
	|
	|GROUP BY
	|	AllAccommodations.Doc
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangeHistory.Doc AS Document,
	|	ChangeHistory.Doc.Guest AS Guest,
	|	ChangeHistory.Doc.DiscountType AS DiscountType
	|INTO AllDoc
	|FROM
	|	(SELECT
	|		AllRes.Doc AS Doc
	|	FROM
	|		AllRes AS AllRes
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AllAcc.Doc
	|	FROM
	|		AllAcc AS AllAcc) AS ChangeHistory
	|
	|GROUP BY
	|	ChangeHistory.Doc,
	|	ChangeHistory.Doc.Guest,
	|	ChangeHistory.Doc.DiscountType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Doks.Doc AS Doc,
	|	Doks.ServicePackage AS ServicePackage,
	|	Doks.Doc.DiscountType AS DiscountType,
	|	&q3BytesString AS OperationType,
	|	Doks.Doc.Number AS Number,
	|	Doks.Doc.Room AS Room,
	|	Doks.Doc.Guest AS Client,
	|	Doks.Doc.Guest.Code AS GuestCode,
	|	Doks.Doc.ExternalCode AS ExternalCode,
	|	CASE
	|		WHEN Doks.ServicePackage.Ref IS NULL
	|			THEN 0
	|		ELSE 1
	|	END AS Quantity,
	|	FALSE AS IsDeletePackage,
	|	FALSE AS IsDeleteDiscount,
	|	CASE
	|		WHEN Doks.Doc REFS Document.Reservation
	|			THEN NOT(Doks.Doc.ReservationStatus.IsActive
	|						OR Doks.Doc.ReservationStatus.IsPreliminary)
	|		ELSE FALSE
	|	END AS IsCancelled
	|FROM
	|	(SELECT
	|		History.Document AS Doc,
	|		History.ServicePackage AS ServicePackage
	|	FROM
	|		(SELECT
	|			AccommodationServicePackages.Ref AS Document,
	|			AccommodationServicePackages.ServicePackage AS ServicePackage
	|		FROM
	|			Document.Accommodation.ServicePackages AS AccommodationServicePackages
	|		WHERE
	|			AccommodationServicePackages.Ref IN
	|					(SELECT
	|						AllDoc.Document
	|					FROM
	|						AllDoc AS AllDoc)
	|			AND ISNULL(AccommodationServicePackages.ServicePackage.IsMedicine, FALSE)
	|		
	|		GROUP BY
	|			AccommodationServicePackages.Ref,
	|			AccommodationServicePackages.ServicePackage
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			ReservationServicePackages.Ref,
	|			ReservationServicePackages.ServicePackage
	|		FROM
	|			Document.Reservation.ServicePackages AS ReservationServicePackages
	|		WHERE
	|			ReservationServicePackages.Ref IN
	|					(SELECT
	|						AllDoc.Document
	|					FROM
	|						AllDoc AS AllDoc)
	|			AND ISNULL(ReservationServicePackages.ServicePackage.IsMedicine, FALSE)
	|		
	|		GROUP BY
	|			ReservationServicePackages.Ref,
	|			ReservationServicePackages.ServicePackage
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllDoc.Document,
	|			RoomRatesServicePackages.ServicePackage
	|		FROM
	|			AllDoc AS AllDoc
	|				INNER JOIN Catalog.RoomRates.ServicePackages AS RoomRatesServicePackages
	|				ON AllDoc.Document.RoomRate = RoomRatesServicePackages.Ref
	|					AND (ISNULL(RoomRatesServicePackages.ServicePackage.IsMedicine, FALSE))
	|		
	|		GROUP BY
	|			AllDoc.Document,
	|			RoomRatesServicePackages.ServicePackage
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllDoc.Document,
	|			AllDoc.Document.RoomRate.ServicePackage
	|		FROM
	|			AllDoc AS AllDoc
	|		WHERE
	|			ISNULL(AllDoc.Document.RoomRate.ServicePackage.IsMedicine, FALSE)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllDoc.Document,
	|			AllDoc.Document.ServicePackage
	|		FROM
	|			AllDoc AS AllDoc
	|		WHERE
	|			ISNULL(AllDoc.Document.ServicePackage.IsMedicine, FALSE)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllRoomDoc.Document,
	|			VALUE(Catalog.ServicePackages.EmptyRef)
	|		FROM
	|			AllDoc AS AllRoomDoc
	|		WHERE
	|			ISNULL(AllRoomDoc.Document.Room, VALUE(Catalog.Rooms.EmptyRef)) <> VALUE(Catalog.Rooms.EmptyRef)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllDoc.Document,
	|			AllDoc.Document.ServicePackage
	|		FROM
	|			AllDoc AS AllDoc
	|				LEFT JOIN Document.Order AS Order
	|				ON AllDoc.Document = Order.ParentDoc
	|					AND (Order.Type.Type = VALUE(Enum.TypesOfOrder.AdditionalServices))
	|		WHERE
	|			NOT Order.Number IS NULL
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllRoomDoc.Document,
	|			VALUE(Catalog.ServicePackages.EmptyRef)
	|		FROM
	|			AllDoc AS AllRoomDoc
	|		WHERE
	|			(ISNULL(AllRoomDoc.Guest.DiscountType, VALUE(Catalog.DiscountTypes.EmptyRef)) <> VALUE(Catalog.DiscountTypes.EmptyRef)
	|					OR ISNULL(AllRoomDoc.Guest.ClientType.DiscountType, VALUE(Catalog.DiscountTypes.EmptyRef)) <> VALUE(Catalog.DiscountTypes.EmptyRef)
	|					OR ISNULL(AllRoomDoc.DiscountType, VALUE(Catalog.DiscountTypes.EmptyRef)) <> VALUE(Catalog.DiscountTypes.EmptyRef))) AS History
	|	
	|	GROUP BY
	|		History.Document,
	|		History.ServicePackage) AS Doks
	|WHERE
	|	(NOT &qDateOfBirthIsFilled
	|			OR &qDateOfBirthIsFilled
	|				AND ISNULL(Doks.Doc.Guest.DateOfBirth, &qEmptyDate) > &qEmptyDate)";
	vQry.SetParameter("qPeriodFrom", LastExportPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("q3BytesString", "   ");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qDateOfBirthIsFilled", ExportGuestsWithDateOfBirthOnly);
	vClients = vQry.Execute().Unload();
	For Each vClientsRow In vClients Do
		vIsNewClient = IsBlankString(vClientsRow.ExternalCode);
		If vIsNewClient Then
			vClientsRow.OperationType = "NEW";
			vClientsRow.ExternalCode = ""; 
		Else
			vClientsRow.OperationType = "UPD";
		EndIf;		
	EndDo;
	Return vClients;
EndFunction // GetExportedClients

// -----------------------------------------------------------------------------
Function GetExportedAnnulationClients()
	// Run query based on documents change history
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AllReservations.Doc AS Doc
	|INTO AllRes
	|FROM
	|	(SELECT
	|		ReservationChangeHistory.Reservation AS Doc
	|	FROM
	|		InformationRegister.ReservationChangeHistory AS ReservationChangeHistory
	|			LEFT JOIN Document.Accommodation AS Accommodations
	|			ON ReservationChangeHistory.Reservation = Accommodations.Reservation
	|				AND (ISNULL(Accommodations.AccommodationStatus.IsActive, FALSE))
	|	WHERE
	|		ReservationChangeHistory.Period > &qPeriodFrom
	|		AND (NOT ReservationChangeHistory.Reservation.ReservationStatus.IsActive
	|				OR ReservationChangeHistory.Reservation.DateOfAnnulation >= &qPeriodFrom
	|				OR ReservationChangeHistory.Reservation.DeletionMark)
	|		AND NOT ReservationChangeHistory.Reservation.ReservationStatus.IsCheckIn
	|		AND ReservationChangeHistory.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|		AND ReservationChangeHistory.Reservation.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|		AND ReservationChangeHistory.Reservation.Guest.LastName <> &qEmptyString
	|		AND ReservationChangeHistory.Reservation.Guest.FirstName <> &qEmptyString
	|		AND ReservationChangeHistory.Hotel = &qHotel
	|		AND Accommodations.Ref IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ClientReservations.Ref
	|	FROM
	|		InformationRegister.ClientChangeHistory AS ClientChangeHistory
	|			INNER JOIN Document.Reservation AS ClientReservations
	|			ON ClientChangeHistory.Client = ClientReservations.Guest
	|				AND (ClientReservations.Hotel = &qHotel)
	|				AND (ClientReservations.DeletionMark
	|					OR ClientReservations.DateOfAnnulation >= &qPeriodFrom)
	|				AND (ClientReservations.ReservationStatus.IsActive
	|					OR ClientReservations.ReservationStatus.IsPreliminary)
	|	WHERE
	|		ClientChangeHistory.Period > &qPeriodFrom
	|		AND ClientChangeHistory.Client.LastName <> &qEmptyString
	|		AND ClientChangeHistory.Client.FirstName <> &qEmptyString) AS AllReservations
	|
	|GROUP BY
	|	AllReservations.Doc
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllAccommodations.Doc AS Doc
	|INTO AllAcc
	|FROM
	|	(SELECT
	|		AccommodationChangeHistory.Accommodation AS Doc
	|	FROM
	|		InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|	WHERE
	|		AccommodationChangeHistory.Period > &qPeriodFrom
	|		AND (NOT AccommodationChangeHistory.Accommodation.AccommodationStatus.IsActive
	|				OR AccommodationChangeHistory.Accommodation.DeletionMark)
	|		AND AccommodationChangeHistory.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|		AND AccommodationChangeHistory.Accommodation.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|		AND AccommodationChangeHistory.Accommodation.Guest.LastName <> &qEmptyString
	|		AND AccommodationChangeHistory.Accommodation.Guest.FirstName <> &qEmptyString
	|		AND AccommodationChangeHistory.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|		AND AccommodationChangeHistory.Hotel = &qHotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ClientAccommodations.Ref
	|	FROM
	|		InformationRegister.ClientChangeHistory AS ClientChangeHistory
	|			INNER JOIN Document.Accommodation AS ClientAccommodations
	|			ON ClientChangeHistory.Client = ClientAccommodations.Guest
	|				AND (ClientAccommodations.Hotel = &qHotel)
	|				AND (ClientAccommodations.DeletionMark
	|					OR NOT ClientAccommodations.AccommodationStatus.IsActive)
	|	WHERE
	|		ClientChangeHistory.Period > &qPeriodFrom
	|		AND ClientChangeHistory.Client.LastName <> &qEmptyString
	|		AND ClientChangeHistory.Client.FirstName <> &qEmptyString) AS AllAccommodations
	|
	|GROUP BY
	|	AllAccommodations.Doc
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangeHistory.Doc AS Document,
	|	ChangeHistory.Doc.Guest AS Guest,
	|	ChangeHistory.Doc.DiscountType AS DiscountType
	|INTO AllDoc
	|FROM
	|	(SELECT
	|		AllRes.Doc AS Doc
	|	FROM
	|		AllRes AS AllRes
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AllAcc.Doc
	|	FROM
	|		AllAcc AS AllAcc) AS ChangeHistory
	|
	|GROUP BY
	|	ChangeHistory.Doc,
	|	ChangeHistory.Doc.Guest,
	|	ChangeHistory.Doc.DiscountType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Doks.Doc AS Doc,
	|	Doks.ServicePackage AS ServicePackage,
	|	Doks.Doc.DiscountType AS DiscountType,
	|	&q3BytesString AS OperationType,
	|	Doks.Doc.Number AS Number,
	|	Doks.Doc.Room AS Room,
	|	Doks.Doc.Guest AS Client,
	|	Doks.Doc.Guest.Code AS GuestCode,
	|	Doks.Doc.ExternalCode AS ExternalCode,
	|	CASE
	|		WHEN Doks.ServicePackage.Ref IS NULL
	|			THEN 0
	|		ELSE 1
	|	END AS Quantity,
	|	TRUE AS IsDeletePackage,
	|	FALSE AS IsDeleteDiscount,
	|	CASE
	|		WHEN Doks.Doc REFS Document.Reservation
	|			THEN NOT(Doks.Doc.ReservationStatus.IsActive
	|						OR Doks.Doc.ReservationStatus.IsPreliminary)
	|		ELSE FALSE
	|	END AS IsCancelled
	|FROM
	|	(SELECT
	|		History.Document AS Doc,
	|		History.ServicePackage AS ServicePackage
	|	FROM
	|		(SELECT
	|			AccommodationServicePackages.Ref AS Document,
	|			AccommodationServicePackages.ServicePackage AS ServicePackage
	|		FROM
	|			Document.Accommodation.ServicePackages AS AccommodationServicePackages
	|		WHERE
	|			AccommodationServicePackages.Ref IN
	|					(SELECT
	|						AllDoc.Document
	|					FROM
	|						AllDoc AS AllDoc)
	|			AND ISNULL(AccommodationServicePackages.ServicePackage.IsMedicine, FALSE)
	|		
	|		GROUP BY
	|			AccommodationServicePackages.Ref,
	|			AccommodationServicePackages.ServicePackage
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			ReservationServicePackages.Ref,
	|			ReservationServicePackages.ServicePackage
	|		FROM
	|			Document.Reservation.ServicePackages AS ReservationServicePackages
	|		WHERE
	|			ReservationServicePackages.Ref IN
	|					(SELECT
	|						AllDoc.Document
	|					FROM
	|						AllDoc AS AllDoc)
	|			AND ISNULL(ReservationServicePackages.ServicePackage.IsMedicine, FALSE)
	|		
	|		GROUP BY
	|			ReservationServicePackages.Ref,
	|			ReservationServicePackages.ServicePackage
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllDoc.Document,
	|			RoomRatesServicePackages.ServicePackage
	|		FROM
	|			AllDoc AS AllDoc
	|				INNER JOIN Catalog.RoomRates.ServicePackages AS RoomRatesServicePackages
	|				ON AllDoc.Document.RoomRate = RoomRatesServicePackages.Ref
	|					AND (ISNULL(RoomRatesServicePackages.ServicePackage.IsMedicine, FALSE))
	|		
	|		GROUP BY
	|			AllDoc.Document,
	|			RoomRatesServicePackages.ServicePackage
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllDoc.Document,
	|			AllDoc.Document.RoomRate.ServicePackage
	|		FROM
	|			AllDoc AS AllDoc
	|		WHERE
	|			ISNULL(AllDoc.Document.RoomRate.ServicePackage.IsMedicine, FALSE)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllDoc.Document,
	|			AllDoc.Document.ServicePackage
	|		FROM
	|			AllDoc AS AllDoc
	|		WHERE
	|			ISNULL(AllDoc.Document.ServicePackage.IsMedicine, FALSE)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllRoomDoc.Document,
	|			VALUE(Catalog.ServicePackages.EmptyRef)
	|		FROM
	|			AllDoc AS AllRoomDoc
	|		WHERE
	|			ISNULL(AllRoomDoc.Document.Room, VALUE(Catalog.Rooms.EmptyRef)) <> VALUE(Catalog.Rooms.EmptyRef)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllRoomDoc.Document,
	|			VALUE(Catalog.ServicePackages.EmptyRef)
	|		FROM
	|			AllDoc AS AllRoomDoc
	|		WHERE
	|			(ISNULL(AllRoomDoc.Guest.DiscountType, VALUE(Catalog.DiscountTypes.EmptyRef)) <> VALUE(Catalog.DiscountTypes.EmptyRef)
	|					OR ISNULL(AllRoomDoc.Guest.ClientType.DiscountType, VALUE(Catalog.DiscountTypes.EmptyRef)) <> VALUE(Catalog.DiscountTypes.EmptyRef)
	|					OR ISNULL(AllRoomDoc.DiscountType, VALUE(Catalog.DiscountTypes.EmptyRef)) <> VALUE(Catalog.DiscountTypes.EmptyRef))) AS History
	|	
	|	GROUP BY
	|		History.Document,
	|		History.ServicePackage) AS Doks
	|WHERE
	|	NOT Doks.ServicePackage = VALUE(Catalog.ServicePackages.EmptyRef)
	|	AND (NOT &qDateOfBirthIsFilled
	|			OR &qDateOfBirthIsFilled
	|				AND ISNULL(Doks.Doc.Guest.DateOfBirth, &qEmptyDate) > &qEmptyDate)";
	vQry.SetParameter("qPeriodFrom", LastExportPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("q3BytesString", "   ");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qDateOfBirthIsFilled", ExportGuestsWithDateOfBirthOnly);
	vClients = vQry.Execute().Unload();
	For Each vClientsRow In vClients Do
		vIsNewClient = IsBlankString(vClientsRow.ExternalCode);
		If vIsNewClient Then
			vClientsRow.OperationType = "NEW";
			vClientsRow.ExternalCode = ""; 
		Else
			vClientsRow.OperationType = "UPD";
		EndIf;		
	EndDo;
	Return vClients;
EndFunction // GetExportedAnnulationClients

// -----------------------------------------------------------------------------
Function GetExportedClientsWithMedicinePackagesOnly()
	// Run query based on documents change history
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AllReservations.Doc AS Doc
	|INTO AllRes
	|FROM
	|	(SELECT
	|		ReservationChangeHistory.Reservation AS Doc
	|	FROM
	|		InformationRegister.ReservationChangeHistory AS ReservationChangeHistory
	|			LEFT JOIN Document.Accommodation AS Accommodations
	|			ON ReservationChangeHistory.Reservation = Accommodations.Reservation
	|				AND (Accommodations.Posted)
	|				AND (ISNULL(Accommodations.AccommodationStatus.IsActive, FALSE))
	|	WHERE
	|		ReservationChangeHistory.Period > &qPeriodFrom
	|		AND ReservationChangeHistory.Reservation.Posted
	|		AND NOT ReservationChangeHistory.Reservation.ReservationStatus.IsCheckIn
	|		AND ReservationChangeHistory.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|		AND ReservationChangeHistory.Reservation.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|		AND ReservationChangeHistory.Reservation.Guest.LastName <> &qEmptyString
	|		AND ReservationChangeHistory.Reservation.Guest.FirstName <> &qEmptyString
	|		AND ReservationChangeHistory.Hotel = &qHotel
	|		AND Accommodations.Ref IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ClientReservations.Ref
	|	FROM
	|		InformationRegister.ClientChangeHistory AS ClientChangeHistory
	|			INNER JOIN Document.Reservation AS ClientReservations
	|			ON ClientChangeHistory.Client = ClientReservations.Guest
	|				AND (ClientReservations.Posted)
	|				AND (ClientReservations.ReservationStatus.IsActive
	|					OR ClientReservations.ReservationStatus.IsPreliminary)
	|				AND (ClientReservations.Hotel = &qHotel)
	|	WHERE
	|		ClientChangeHistory.Period > &qPeriodFrom
	|		AND ClientChangeHistory.Client.LastName <> &qEmptyString
	|		AND ClientChangeHistory.Client.FirstName <> &qEmptyString) AS AllReservations
	|
	|GROUP BY
	|	AllReservations.Doc
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllAccommodations.Doc AS Doc
	|INTO AllAcc
	|FROM
	|	(SELECT
	|		AccommodationChangeHistory.Accommodation AS Doc
	|	FROM
	|		InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|	WHERE
	|		AccommodationChangeHistory.Period > &qPeriodFrom
	|		AND AccommodationChangeHistory.Accommodation.AccommodationStatus.IsActive
	|		AND AccommodationChangeHistory.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|		AND AccommodationChangeHistory.Accommodation.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|		AND AccommodationChangeHistory.Accommodation.Guest.LastName <> &qEmptyString
	|		AND AccommodationChangeHistory.Accommodation.Guest.FirstName <> &qEmptyString
	|		AND AccommodationChangeHistory.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|		AND AccommodationChangeHistory.Hotel = &qHotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ClientAccommodations.Ref
	|	FROM
	|		InformationRegister.ClientChangeHistory AS ClientChangeHistory
	|			INNER JOIN Document.Accommodation AS ClientAccommodations
	|			ON ClientChangeHistory.Client = ClientAccommodations.Guest
	|				AND (ClientAccommodations.Posted)
	|				AND (ClientAccommodations.AccommodationStatus.IsActive)
	|				AND (ClientAccommodations.AccommodationStatus.IsInHouse)
	|				AND (ClientAccommodations.Hotel = &qHotel)
	|	WHERE
	|		ClientChangeHistory.Period > &qPeriodFrom
	|		AND ClientChangeHistory.Client.LastName <> &qEmptyString
	|		AND ClientChangeHistory.Client.FirstName <> &qEmptyString) AS AllAccommodations
	|
	|GROUP BY
	|	AllAccommodations.Doc
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangeHistory.Doc AS Document,
	|	ChangeHistory.Doc.Guest AS Guest,
	|	ChangeHistory.Doc.DiscountType AS DiscountType
	|INTO AllDoc
	|FROM
	|	(SELECT
	|		AllRes.Doc AS Doc
	|	FROM
	|		AllRes AS AllRes
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AllAcc.Doc
	|	FROM
	|		AllAcc AS AllAcc) AS ChangeHistory
	|
	|GROUP BY
	|	ChangeHistory.Doc,
	|	ChangeHistory.Doc.Guest,
	|	ChangeHistory.Doc.DiscountType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Doks.Doc AS Doc,
	|	&q3BytesString AS OperationType,
	|	Doks.Doc.Number AS Number,
	|	Doks.Doc.Room AS Room,
	|	Doks.Doc.Guest AS Client,
	|	Doks.Doc.Guest.Code AS GuestCode,
	|	Doks.Doc.ExternalCode AS ExternalCode,
	|	Doks.ServicePackage AS ServicePackage,
	|	Doks.Doc.DiscountType AS DiscountType,
	|	CASE
	|		WHEN NOT Doks.ServicePackage.Ref IS NULL
	|			THEN 1
	|		ELSE 0
	|	END AS Quantity,
	|	FALSE AS IsDeletePackage,
	|	FALSE AS IsDeleteDiscount,
	|	CASE
	|		WHEN Doks.Doc REFS Document.Reservation
	|			THEN NOT(Doks.Doc.ReservationStatus.IsActive
	|						OR Doks.Doc.ReservationStatus.IsPreliminary)
	|		ELSE FALSE
	|	END AS IsCancelled
	|FROM
	|	(SELECT
	|		History.Document AS Doc,
	|		History.ServicePackage AS ServicePackage
	|	FROM
	|		(SELECT
	|			AccommodationServicePackages.Ref AS Document,
	|			AccommodationServicePackages.ServicePackage AS ServicePackage
	|		FROM
	|			Document.Accommodation.ServicePackages AS AccommodationServicePackages
	|		WHERE
	|			AccommodationServicePackages.Ref IN
	|					(SELECT
	|						AllDoc.Document
	|					FROM
	|						AllDoc AS AllDoc)
	|			AND ISNULL(AccommodationServicePackages.ServicePackage.IsMedicine, FALSE)
	|		
	|		GROUP BY
	|			AccommodationServicePackages.Ref,
	|			AccommodationServicePackages.ServicePackage
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			ReservationServicePackages.Ref,
	|			ReservationServicePackages.ServicePackage
	|		FROM
	|			Document.Reservation.ServicePackages AS ReservationServicePackages
	|		WHERE
	|			ReservationServicePackages.Ref IN
	|					(SELECT
	|						AllDoc.Document
	|					FROM
	|						AllDoc AS AllDoc)
	|			AND ISNULL(ReservationServicePackages.ServicePackage.IsMedicine, FALSE)
	|		
	|		GROUP BY
	|			ReservationServicePackages.Ref,
	|			ReservationServicePackages.ServicePackage
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllDoc.Document,
	|			RoomRatesServicePackages.ServicePackage
	|		FROM
	|			AllDoc AS AllDoc
	|				INNER JOIN Catalog.RoomRates.ServicePackages AS RoomRatesServicePackages
	|				ON AllDoc.Document.RoomRate = RoomRatesServicePackages.Ref
	|					AND (ISNULL(RoomRatesServicePackages.ServicePackage.IsMedicine, FALSE))
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllDoc.Document,
	|			AllDoc.Document.RoomRate.ServicePackage
	|		FROM
	|			AllDoc AS AllDoc
	|		WHERE
	|			ISNULL(AllDoc.Document.RoomRate.ServicePackage.IsMedicine, FALSE)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllDoc.Document,
	|			AllDoc.Document.ServicePackage
	|		FROM
	|			AllDoc AS AllDoc
	|		WHERE
	|			ISNULL(AllDoc.Document.ServicePackage.IsMedicine, FALSE)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllDoc.Document,
	|			AllDoc.Document.ServicePackage
	|		FROM
	|			AllDoc AS AllDoc
	|				LEFT JOIN Document.Order AS Order
	|				ON AllDoc.Document = Order.ParentDoc
	|					AND (Order.Type.Type = VALUE(Enum.TypesOfOrder.AdditionalServices))
	|		WHERE
	|			NOT Order.Number IS NULL
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AllRoomDoc.Document,
	|			VALUE(Catalog.ServicePackages.EmptyRef)
	|		FROM
	|			AllDoc AS AllRoomDoc
	|		WHERE
	|			(ISNULL(AllRoomDoc.Guest.DiscountType, VALUE(Catalog.DiscountTypes.EmptyRef)) <> VALUE(Catalog.DiscountTypes.EmptyRef)
	|					OR ISNULL(AllRoomDoc.Guest.ClientType.DiscountType, VALUE(Catalog.DiscountTypes.EmptyRef)) <> VALUE(Catalog.DiscountTypes.EmptyRef)
	|					OR ISNULL(AllRoomDoc.DiscountType, VALUE(Catalog.DiscountTypes.EmptyRef)) <> VALUE(Catalog.DiscountTypes.EmptyRef))) AS History
	|	
	|	GROUP BY
	|		History.Document,
	|		History.ServicePackage) AS Doks
	|WHERE
	|	(NOT &qDateOfBirthIsFilled
	|			OR &qDateOfBirthIsFilled
	|				AND ISNULL(Doks.Doc.Guest.DateOfBirth, &qEmptyDate) > &qEmptyDate)";
	vQry.SetParameter("qPeriodFrom", LastExportPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("q3BytesString", "   ");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qDateOfBirthIsFilled", ExportGuestsWithDateOfBirthOnly);
	vClients = vQry.Execute().Unload();
	For Each vClientsRow In vClients Do
		vIsNewClient = IsBlankString(vClientsRow.ExternalCode);
		If vIsNewClient Then
			vClientsRow.OperationType = "NEW";
			vClientsRow.ExternalCode = ""; 
		Else
			vClientsRow.OperationType = "UPD";
		EndIf;		
	EndDo;
	Return vClients;
EndFunction // GetExportedClientsWithMedicinePackagesOnly

// -----------------------------------------------------------------------------
Function GetExternalClients()
	// Run query based on documents change history
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AllFolios.Doc AS Doc,
	|	&q3BytesString AS OperationType,
	|	AllFolios.Doc.Number AS Number,
	|	AllFolios.Doc.Room AS Room,
	|	AllFolios.Doc.Client AS Client,
	|	&qEmptyString AS ExternalCode,
	|	VALUE(Catalog.ServicePackages.EmptyRef) AS ServicePackage,
	|	SUM(1) AS Quantity,
	|	AllFolios.Doc.Client.Code AS ClientCode,
	|	FALSE AS IsDeletePackage,
	|	FALSE AS IsDeleteDiscount,
	|	FALSE AS IsCancelled
	|FROM
	|	(SELECT
	|		Folios.Ref AS Doc
	|	FROM
	|		Document.Folio AS Folios
	|	WHERE
	|		Folios.Client <> VALUE(Catalog.Clients.EmptyRef)
	|		AND NOT Folios.IsClosed
	|		AND NOT Folios.DeletionMark
	|		AND Folios.Date > &qPeriodFrom
	|		AND Folios.Client.LastName <> &qEmptyString
	|		AND Folios.Client.FirstName <> &qEmptyString
	|		AND Folios.Hotel = &qHotel
	|		AND Folios.ParentDoc.Number IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ClientFolios.Ref
	|	FROM
	|		InformationRegister.ClientChangeHistory AS ClientChangeHistory
	|			INNER JOIN Document.Folio AS ClientFolios
	|			ON ClientChangeHistory.Client = ClientFolios.Client
	|				AND (NOT ClientFolios.IsClosed)
	|				AND (NOT ClientFolios.DeletionMark)
	|				AND (ClientFolios.Client.LastName <> &qEmptyString)
	|				AND (ClientFolios.Client.FirstName <> &qEmptyString)
	|				AND (ClientFolios.Hotel = &qHotel)
	|				AND (ClientFolios.ParentDoc.Number IS NULL)
	|	WHERE
	|		ClientChangeHistory.Period > &qPeriodFrom
	|		AND ClientChangeHistory.Client.LastName <> &qEmptyString
	|		AND ClientChangeHistory.Client.FirstName <> &qEmptyString) AS AllFolios
	|WHERE
	|	(NOT &qDateOfBirthIsFilled
	|			OR &qDateOfBirthIsFilled
	|				AND ISNULL(AllFolios.Doc.Client.DateOfBirth, &qEmptyDate) > &qEmptyDate)
	|
	|GROUP BY
	|	AllFolios.Doc,
	|	AllFolios.Doc.Number,
	|	AllFolios.Doc.Room,
	|	AllFolios.Doc.Client,
	|	AllFolios.Doc.Client.Code";
	vQry.SetParameter("qPeriodFrom", LastExportPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("q3BytesString", "   ");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qDateOfBirthIsFilled", ExportGuestsWithDateOfBirthOnly);
	vClients = vQry.Execute().Unload();
	For Each vClientsRow In vClients Do
		vIsNewClient = IsBlankString(vClientsRow.ExternalCode);
		If vIsNewClient Then
			vClientsRow.OperationType = "NEW";
			vClientsRow.ExternalCode = ""; 
		Else
			vClientsRow.OperationType = "UPD";
		EndIf;		
	EndDo;
	Return vClients;
EndFunction // GetExternalClients

// -----------------------------------------------------------------------------
Procedure Write2Medicine(pClients)
	vDebugMessage = StrReplace(TrimAll(MedicineSystemWSDLConnectionString), "\", "/") + Chars.LF;
	vNameSpaseUri = "http://www.1chotel.ru/interfaces/medicine/";
	vNameSpaseWSUri = "http://www.1chotel.ru/ws/interfaces/medicine/";
	vSSL = Undefined;
	If HttpUseSSL Then
		vSSL = New OpenSSLSecureConnection(Undefined, Undefined); 
	EndIf;
	// Open connection to the 1C Medicine hotel interfaces 
	If Not IsBlankString(User) Then
		vMedConnWSDef = New WSDefinitions(StrReplace(TrimAll(MedicineSystemWSDLConnectionString), "\", "/"), TrimAll(User), TrimAll(Password), , , vSSL);
		vMedConnWSProxy = New WSProxy(vMedConnWSDef, vNameSpaseWSUri, "HotelInterfaces", "HotelInterfacesSoap", , 120);
		vMedConnWSProxy.User = TrimAll(User);
		vMedConnWSProxy.Password = TrimAll(Password);
	Else
		vMedConnWSDef = New WSDefinitions(StrReplace(TrimAll(MedicineSystemWSDLConnectionString), "\", "/"), , , , , vSSL);
		vMedConnWSProxy = New WSProxy(vMedConnWSDef, vNameSpaseWSUri, "HotelInterfaces", "HotelInterfacesSoap", , 120);
	EndIf;

	// Build parameters object
	vParamXDTO = vMedConnWSProxy.XDTOFactory.Create(vMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "ImportHotelGuestsParam"));
	vParamXDTO.Hotel = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), "1CMEDICINE", "Hotels", Hotel);
	vParamXDTO.ExternalSystem = "1CHOTEL";
	vParamXDTO.MedicalCardType = TrimAll(MedicalCardType);
	vParamXDTO.AgreementCode = TrimAll(AgreementCode);
	vDebugMessage = vDebugMessage + vParamXDTO.Hotel + Chars.Tab + vParamXDTO.ExternalSystem + Chars.Tab + vParamXDTO.MedicalCardType;
	
	// Send each client
	vGuests = vMedConnWSProxy.XDTOFactory.Create(vMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "Guests"));
	vCountRow = 0;
	vRowInPackage = 10;
	For Each vClientsRow In pClients Do
		vGuestInfo = vMedConnWSProxy.XDTOFactory.Create(vMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "GuestInfo"));
		FillGuestInfoObject(vMedConnWSProxy, vClientsRow, vGuestInfo, vDebugMessage);
		
		// add medicine packages
		If ValueIsFilled(vClientsRow.ServicePackage) Then
			objPackage 			= vMedConnWSProxy.XDTOFactory.Create(vMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "ServicePackage"));
			vPackageRef 		= vClientsRow.ServicePackage; 
			vPackagePrice		= vPackageRef.Services.Total("Price");
			vPackageQuantity	= vClientsRow.Quantity;
			vPackageSum			= Round(vPackagePrice * vPackageQuantity, 2);
			
			FillPropertyValues(objPackage, vPackageRef, , "DiscountType");
			
			objPackage.Quantity 	= vPackageQuantity;
			objPackage.PackageSum 	= vPackageSum; 
			objPackage.Price 		= vPackagePrice;
			objPackage.DiscountType = ?(ValueIsFilled(vPackageRef.DiscountType), vPackageRef.DiscountType.Description, "");
			
			vGuestInfo.ServicePackage = objPackage;
		EndIf;	
		
		vGuests.GuestInfo.Add(vGuestInfo);
		
		vCountRow = vCountRow + 1;
		
		If vCountRow = vRowInPackage Then
			vParamXDTO.Guests = vGuests;
			
			// Write debug string to the events log
			If IsDebugMode Then
				WriteLogEvent(NStr("en = 'ExportClientsTo1CMedicine.Data'; de = 'ExportClientsTo1CMedicine.Data'; ru = 'ВыгрузкаДанныхКлиентовВ1СМедицину.Данные'"), EventLogLevel.Information, , , vDebugMessage);
				#If Client Then 
					tcCommonFunctionOnClientServer.TextMessage(vDebugMessage);
				#EndIf
			EndIf;
			
			// Call API
			vRetXDTO = vMedConnWSProxy.ImportHotelGuests(vParamXDTO);
			If vRetXDTO = Undefined Then
				vMessage = NStr("ru = 'Ошибка отправки данных в 1С:Медицину: Не получен ответ от интерфейсного сервера медицины!'; en = 'Error sending data to 1C Medicine: No reply from medicine interface server!'");
				PrintError(vMessage);
				Raise vMessage;
			Else
				If Not vRetXDTO.Success Then
					vMessage = NStr("ru = 'Ошибка отправки данных в 1С:Медицину: '; en = 'Error sending data to 1C Medicine: '") + vRetXDTO.ResultDescription + Chars.LF;
					PrintError(vMessage);
					For Each vGuestInError In vRetXDTO.GuestsInError.GuestInError Do
						vMessage = NStr("ru = 'Гость с ошибками: '; en = 'Guest with errors: '") + vGuestInError.LastName + " " + vGuestInError.FirstName + " " + vGuestInError.SecondName + " " + vGuestInError.Sex + " " + Format(vGuestInError.DateOfBirth, "DF=dd.MM.yyyy") + Chars.LF + vGuestInError.ErrorText;
						PrintError(vMessage);
					EndDo;
				Else
					// Write debug string to the events log
					If IsDebugMode Then
						PrintSuccess(vRetXDTO.ResultDescription);
					EndIf;
				EndIf;
			EndIf;
			
			vGuests = vMedConnWSProxy.XDTOFactory.Create(vMedConnWSProxy.XDTOFactory.Type("http://www.1chotel.ru/interfaces/medicine/", "Guests"));
			vCountRow = 0;
		EndIf;	
	EndDo;
	vParamXDTO.Guests 			= vGuests;
	
	// Write debug string to the events log
	If IsDebugMode Then
		WriteLogEvent(NStr("en='ExportClientsTo1CMedicine.Data'; ru='ВыгрузкаДанныхКлиентовВ1СМедицину.Данные'"), EventLogLevel.Information, , , vDebugMessage);
		#If Client Then 
			tcCommonFunctionOnClientServer.TextMessage(vDebugMessage);
		#EndIf
	EndIf;
	
	// Call API
	If pClients.Count() > 0 Then
		vRetXDTO = vMedConnWSProxy.ImportHotelGuests(vParamXDTO);
		If vRetXDTO = Undefined Then
			vMessage = NStr("ru = 'Ошибка отправки данных в 1С:Медицину: Не получен ответ от интерфейсного сервера медицины!'; en = 'Error sending data to 1C Medicine: No reply from medicine interface server!'");
			PrintError(vMessage);
			Raise vMessage;
		Else
			If Not vRetXDTO.Success Then
				vMessage = NStr("ru = 'Ошибка отправки данных в 1С:Медицину: '; en = 'Error sending data to 1C Medicine: '") + vRetXDTO.ResultDescription + Chars.LF;
				PrintError(vMessage);
				For Each vGuestInError In vRetXDTO.GuestsInError.GuestInError Do
					vMessage = NStr("ru = 'Гость с ошибками: '; en = 'Guest with errors: '") + vGuestInError.LastName + " " + vGuestInError.FirstName + " " + vGuestInError.SecondName + " " + vGuestInError.Sex + " " + Format(vGuestInError.DateOfBirth, "DF=dd.MM.yyyy") + Chars.LF + vGuestInError.ErrorText;
					PrintError(vMessage);
				EndDo;
			Else
				// Write debug string to the events log
				If IsDebugMode Then
					PrintSuccess(vRetXDTO.ResultDescription);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Disconnect from Medicine interface server
	vMedConnWSProxy = Undefined;
	vMedConnWSDef = Undefined;
EndProcedure // Write2Medicine 

// -----------------------------------------------------------------------------
Procedure WriteExternalClients2Medicine(pClients)
	vDebugMessage = StrReplace(TrimAll(MedicineSystemWSDLConnectionString), "\", "/") + Chars.LF;
	vNameSpaseUri = "http://www.1chotel.ru/interfaces/medicine/";
	vNameSpaseWSUri = "http://www.1chotel.ru/ws/interfaces/medicine/";
	// Open connection to the 1C Medicine hotel interfaces 
	If Not IsBlankString(User) Then
		vMedConnWSDef = New WSDefinitions(StrReplace(TrimAll(MedicineSystemWSDLConnectionString), "\", "/"), TrimAll(User), TrimAll(Password));
		vMedConnWSProxy = New WSProxy(vMedConnWSDef, vNameSpaseWSUri, "HotelInterfaces", "HotelInterfacesSoap", , 120);
		vMedConnWSProxy.User = TrimAll(User);
		vMedConnWSProxy.Password = TrimAll(Password);
	Else
		vMedConnWSDef = New WSDefinitions(StrReplace(TrimAll(MedicineSystemWSDLConnectionString), "\", "/"));
		vMedConnWSProxy = New WSProxy(vMedConnWSDef, vNameSpaseWSUri, "HotelInterfaces", "HotelInterfacesSoap", , 120);
	EndIf;

	// Build parameters object
	vParamXDTO = vMedConnWSProxy.XDTOFactory.Create(vMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "ImportHotelGuestsParam"));
	vParamXDTO.Hotel = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), "1CMEDICINE", "Hotels", Hotel);
	vParamXDTO.ExternalSystem = "1CHOTEL";
	vParamXDTO.MedicalCardType = TrimAll(MedicalCardType);
	vParamXDTO.AgreementCode = TrimAll(AgreementCode);
	vDebugMessage = vDebugMessage + vParamXDTO.Hotel + Chars.Tab + vParamXDTO.ExternalSystem + Chars.Tab + vParamXDTO.MedicalCardType;
	
	// Send each client
	vGuests = vMedConnWSProxy.XDTOFactory.Create(vMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "Guests"));
	vCountRow = 0; 
	vRowInPackage = 10;
	For Each vClientsRow In pClients Do
		vGuestInfo = vMedConnWSProxy.XDTOFactory.Create(vMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "GuestInfo"));
		FillExternalClientInfoObject(vMedConnWSProxy, vClientsRow, vGuestInfo, vDebugMessage);
		vGuests.GuestInfo.Add(vGuestInfo);
		If vCountRow = vRowInPackage Then
			vParamXDTO.Guests 	= vGuests;
			
			// Write debug string to the events log
			If IsDebugMode Then
				WriteLogEvent(NStr("en = 'ExportClientsTo1CMedicine.Data'; de = 'ExportClientsTo1CMedicine.Data'; ru = 'ВыгрузкаДанныхКлиентовВ1СМедицину.Данные'"), EventLogLevel.Information, , , vDebugMessage);
				#If  Client Then 
					tcCommonFunctionOnClientServer.TextMessage(vDebugMessage);
				#EndIf
			EndIf;
			
				// Call API
				vRetXDTO = vMedConnWSProxy.ImportHotelGuests(vParamXDTO);
				If vRetXDTO = Undefined Then
					vMessage = NStr("en = 'Error sending data to 1C Medicine: No reply from medicine interface server!'; de = 'Error sending data to 1C Medicine: No reply from medicine interface server!'; ru = 'Ошибка отправки данных в 1С:Медицину: Не получен ответ от интерфейсного сервера медицины!'");
					PrintError(vMessage);
					Raise vMessage;
				Else
					If Not vRetXDTO.Success Then
						vMessage = NStr("en = 'Error sending data to 1C Medicine: '; de = 'Error sending data to 1C Medicine: '; ru = 'Ошибка отправки данных в 1С:Медицину: '") + vRetXDTO.ResultDescription + Chars.LF;
						PrintError(vMessage);
						For Each vGuestInError In vRetXDTO.GuestsInError.GuestInError Do
							vMessage = NStr("en = 'Guest with errors: '; de = 'Guest with errors: '; ru = 'Гость с ошибками: '") + vGuestInError.LastName + " " 
											+ vGuestInError.FirstName + " " + vGuestInError.SecondName + " " + vGuestInError.Sex + " " + Format(vGuestInError.DateOfBirth, "DF=dd.MM.yyyy") + Chars.LF + vGuestInError.ErrorText;
							PrintError(vMessage);
						EndDo;
					Else
						// Write debug string to the events log
						If IsDebugMode Then
							PrintSuccess(vRetXDTO.ResultDescription);
						EndIf;
					EndIf;
				EndIf;
			vGuests = vMedConnWSProxy.XDTOFactory.Create(vMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "Guests"));
			vCountRow = 0;
		EndIf;
		vCountRow = vCountRow + 1;
	EndDo;
	vParamXDTO.Guests = vGuests;
	
	// Write debug string to the events log
	If IsDebugMode Then
		WriteLogEvent(NStr("en='ExportClientsTo1CMedicine.Data'; ru='ВыгрузкаДанныхКлиентовВ1СМедицину.Данные'"), EventLogLevel.Information, , , vDebugMessage);
		#If Client Then
			tcCommonFunctionOnClientServer.TextMessage(vDebugMessage);
		#EndIf
	EndIf;
	
	// Call API
	If pClients.Count() > 0 Then
		vRetXDTO = vMedConnWSProxy.ImportHotelGuests(vParamXDTO);
		If vRetXDTO = Undefined Then
			vMessage = NStr("ru = 'Ошибка отправки данных в 1С:Медицину: Не получен ответ от интерфейсного сервера медицины!'; en = 'Error sending data to 1C Medicine: No reply from medicine interface server!'");
			PrintError(vMessage);
			Raise vMessage;
		Else
			If Not vRetXDTO.Success Then
				vMessage = NStr("ru = 'Ошибка отправки данных в 1С:Медицину: '; en = 'Error sending data to 1C Medicine: '") + vRetXDTO.ResultDescription + Chars.LF;
				PrintError(vMessage);
				For Each vGuestInError In vRetXDTO.GuestsInError.GuestInError Do
					vMessage = NStr("ru = 'Гость с ошибками: '; en = 'Guest with errors: '") + vGuestInError.LastName + " " + vGuestInError.FirstName + " " + vGuestInError.SecondName + " " 
									+ vGuestInError.Sex + " " + Format(vGuestInError.DateOfBirth, "DF=dd.MM.yyyy") + Chars.LF + vGuestInError.ErrorText;
					PrintError(vMessage);
				EndDo;
			Else
				// Write debug string to the events log
				If IsDebugMode Then
					PrintSuccess(vRetXDTO.ResultDescription);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Disconnect from Medicine interface server
	vMedConnWSProxy = Undefined;
	vMedConnWSDef = Undefined;
EndProcedure // WriteExternalClients2Medicine 

// -----------------------------------------------------------------------------
Function GetExtraServicesFolio(pDoc)
	vFolio = Undefined;
	For vInd = 1 To pDoc.ChargingRules.Count() Do
		vCRRow = pDoc.ChargingRules.Get(pDoc.ChargingRules.Count() - vInd);
		If ValueIsFilled(vCRRow.ChargingFolio) Then
			vFolio = vCRRow.ChargingFolio;
			Break;
		EndIf;
	EndDo;
	Return vFolio;
EndFunction // GetExtraServicesFolio

// -----------------------------------------------------------------------------
Procedure FillGuestInfoObject(pMedConnWSProxy, pClientsRow, pGuestInfo, pDebugMessage)
	vClient = pClientsRow.Client;  
	vNameSpaseUri = "http://www.1chotel.ru/interfaces/medicine/";
	vDoc = pClientsRow.Doc;
	pDebugMessage = pDebugMessage + Chars.LF;
	
	pGuestInfo.OperationType = pClientsRow.OperationType;
	pDebugMessage = pDebugMessage + pGuestInfo.OperationType + Chars.Tab;
	
	pGuestInfo.LastName = TrimAll(vClient.LastName);
	pGuestInfo.FirstName = TrimAll(vClient.FirstName);
	pGuestInfo.SecondName = TrimAll(vClient.SecondName);
	pGuestInfo.Sex = Left(TrimAll(vClient.Sex), 1);
	pGuestInfo.DateOfBirth = vClient.DateOfBirth;
	pGuestInfo.IsDeletePackage	= pClientsRow.IsDeletePackage;
	pGuestInfo.IsDeleteDiscount	= pClientsRow.IsDeleteDiscount;
	vDiscountType = pClientsRow.DiscountType;
	pGuestInfo.NoSMSDelivery = vClient.NoSMSDelivery; 
	If Not ValueIsFilled(vDiscountType) Then
		vDiscountType = vClient.DiscountType;
		If Not ValueIsFilled(vDiscountType) Then
			If ValueIsFilled(vClient.ClientType) And ValueIsFilled(vClient.ClientType.DiscountType) Then
				vDiscountType = vClient.ClientType.DiscountType;
				pGuestInfo.IsDeleteDiscount = False;
			EndIf;
		EndIf;
	EndIf;
	pGuestInfo.DiscountType = ?(ValueIsFilled(vDiscountType), vDiscountType.Description, "");
	pDebugMessage = pDebugMessage + pGuestInfo.LastName + " " + pGuestInfo.FirstName + " " + pGuestInfo.SecondName + " " + pGuestInfo.Sex + " " + Format(pGuestInfo.DateOfBirth, "DF=dd.MM.yyyy") + Chars.Tab;
	
	vGuestIdentificationData = pMedConnWSProxy.XDTOFactory.Create(pMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "GuestIdentificationData"));
	vGuestIdentificationData.IDType = ""; 
	Try
		vGuestIdentificationData.IDDescription = "";
		If ValueIsFilled(vClient.IdentityDocumentType) Then
			vGuestIdentificationData.IDDescription = TrimAll(vClient.IdentityDocumentType);	
		EndIf; 
	Except
	EndTry;
	If ValueIsFilled(vClient.IdentityDocumentType) Then
		vGuestIdentificationData.IDType = TrimAll(vClient.IdentityDocumentType.Code);
	EndIf;
	vGuestIdentificationData.IDSeries = "";
	If vGuestIdentificationData.IDType = "21" And Not IsBlankString(vClient.IdentityDocumentSeries) And StrLen(TrimAll(vClient.IdentityDocumentSeries)) = 4 Then
		vGuestIdentificationData.IDSeries = Left(TrimAll(vClient.IdentityDocumentSeries), 2) + " " + Right(TrimAll(vClient.IdentityDocumentSeries), 2);
	Else
		vGuestIdentificationData.IDSeries = TrimAll(vClient.IdentityDocumentSeries);
	EndIf;
	vGuestIdentificationData.IDNumber = TrimAll(vClient.IdentityDocumentNumber);
	vGuestIdentificationData.IDIssueDate = vClient.IdentityDocumentIssueDate;
	vGuestIdentificationData.IDIssuedByUnitCode = vClient.IdentityDocumentUnitCode;
	vGuestIdentificationData.IDIssuedBy = vClient.IdentityDocumentIssuedBy;
	vGuestIdentificationData.SocialSecurityNumber = vClient.SocialSecurityNumber;
	pGuestInfo.IdentificationData = vGuestIdentificationData;
		
	vGuestRegistrationData = pMedConnWSProxy.XDTOFactory.Create(pMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "GuestRegistrationAddress"));
	vGuestRegistrationData.Country = "";
	If ValueIsFilled(vClient.Citizenship) Then
		Try
			vGuestRegistrationData.Country = TrimAll(vClient.Citizenship.ISOCode3);
		Except
		EndTry;	 
	EndIf; 
	Try
		vGuestRegistrationData.CitizenshipDescription = TrimAll(vClient.Citizenship);
	Except
	EndTry;	 
	Try
		vGuestRegistrationData.PlaceOfBirth = TrimAll(vClient.PlaceOfBirth);
	Except
	EndTry;
	vGuestRegistrationData.AddressPresentation = TrimAll(vClient.Address);
	pGuestInfo.RegistrationData = vGuestRegistrationData;
	
	vGuestContactsData = pMedConnWSProxy.XDTOFactory.Create(pMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "GuestContactsData"));
	vGuestContactsData.Phone = vClient.Phone;
	vGuestContactsData.EMail = vClient.EMail;
	pGuestInfo.ContactsData = vGuestContactsData;
	
	vGuestMedicalInsurancePolicyData = pMedConnWSProxy.XDTOFactory.Create(pMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "GuestMedicalInsurancePolicyData"));
	vGuestMedicalInsurancePolicyData.PolicyType = "";
	vGuestMedicalInsurancePolicyData.PolicySeries = "";
	vGuestMedicalInsurancePolicyData.PolicyNumber = "";
	vGuestMedicalInsurancePolicyData.Insurer = "";
	vGuestMedicalInsurancePolicyData.PolicyContract = "";
	pGuestInfo.MedicalInsurancePolicyData = vGuestMedicalInsurancePolicyData;
	
	vGuestHotelAccommodationData = pMedConnWSProxy.XDTOFactory.Create(pMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "GuestHotelAccommodationData"));
	vGuestHotelAccommodationData.ReservationCode = Format(vDoc.GuestGroup.Code, "ND=12; NFD=0; NZ=; NG=");
	vGuestHotelAccommodationData.ClientCode = pClientsRow.GuestCode;
	vGuestHotelAccommodationData.Customer = TrimAll(vDoc.Customer);
	vGuestHotelAccommodationData.ArrivalDate = vDoc.Date;
	vGuestHotelAccommodationData.CheckInDate = vDoc.CheckInDate;
	vGuestHotelAccommodationData.Duration = vDoc.Duration;
	vGuestHotelAccommodationData.CheckOutDate = vDoc.CheckOutDate;
	vGuestHotelAccommodationData.Room = TrimAll(vDoc.Room);
	vGuestHotelAccommodationData.RoomType = TrimAll(vDoc.RoomType);
	vGuestHotelAccommodationData.RoomRate = TrimAll(vDoc.RoomRate);
	vGuestHotelAccommodationData.AccommodationType = TrimAll(vDoc.AccommodationType);
	vGuestHotelAccommodationData.CardCode = StrReplace(GetClientCardCode(vDoc), Char(0), "");
	vExtraSrvFolio = GetExtraServicesFolio(vDoc);
	vGuestHotelAccommodationData.FolioNumber = "";
	If ValueIsFilled(vExtraSrvFolio) Then
		vGuestHotelAccommodationData.FolioNumber = TrimAll(vExtraSrvFolio.Number);
	EndIf;
	vGuestHotelAccommodationData.VoucherNumber = TrimAll(vDoc.HotelProduct);
	vGuestHotelAccommodationData.IsCheckedIn = False;
	vGuestHotelAccommodationData.IsCheckedOut = False;
	If TypeOf(vDoc) = Type("DocumentRef.Accommodation") Then
		vAccommodationStatus = vDoc.AccommodationStatus;
		vGuestHotelAccommodationData.IsCheckedIn = vAccommodationStatus.IsInHouse;
		vGuestHotelAccommodationData.IsCheckedOut = (Not vAccommodationStatus.IsInHouse And vAccommodationStatus.IsCheckOut) Or Not vAccommodationStatus.IsActive;
		
		// Get full accommodation period for this row
		vAccObj = vDoc.GetObject();
		vLastAcc = vAccObj.pmGetLastAccommodationInChain();
		vAccCheckInDate = vAccObj.pmGetCheckInDate();
		If ValueIsFilled(vLastAcc) Then
			vAccCheckOutDate = vLastAcc.CheckOutDate;
		Else
			vAccCheckOutDate = vAccObj.CheckOutDate;
		EndIf;
		vFirstAcc = vAccObj.pmGetFirstAccommodationInChain();
		
		// Get full reservation period for this row
		vResCheckInDate = vAccCheckInDate;
		vResCheckOutDate = vAccCheckOutDate;
		If ValueIsFilled(vDoc.Reservation) Then
			vResObj = vDoc.Reservation.GetObject();
			vLastRes = vResObj.pmGetLastReservationInChain();
			vResCheckInDate = vResObj.pmGetCheckInDate();
			vResCheckOutDate = vLastRes.CheckOutDate;
		EndIf;
		
		vGuestHotelAccommodationData.ArrivalDate = vFirstAcc.Date;
		vGuestHotelAccommodationData.CheckInDate = vAccCheckInDate;
		vGuestHotelAccommodationData.CheckOutDate = Max(vResCheckOutDate, vAccCheckOutDate);
		vGuestHotelAccommodationData.Duration = cmCalculateDuration(vDoc.RoomRate, vAccCheckInDate, Max(vResCheckOutDate, vAccCheckOutDate));
		
		vGuestHotelAccommodationData.IsCancelled = False;
	ElsIf TypeOf(vDoc) = Type("DocumentRef.Reservation") Then
		// Get full reservation period for this row
		vResObj = vDoc.GetObject();
		vLastRes = vResObj.pmGetLastReservationInChain();
		vResCheckInDate = vResObj.pmGetCheckInDate();
		If ValueIsFilled(vLastRes) Then
			vResCheckOutDate = vLastRes.CheckOutDate;
		Else
			vResCheckOutDate = vResObj.CheckOutDate;
		EndIf;
		
		vGuestHotelAccommodationData.CheckInDate = vResCheckInDate;
		vGuestHotelAccommodationData.CheckOutDate = vResCheckOutDate;
		vGuestHotelAccommodationData.Duration = cmCalculateDuration(vDoc.RoomRate, vResCheckInDate, vResCheckOutDate);
		
		vGuestHotelAccommodationData.IsCancelled = pClientsRow.IsCancelled;
	EndIf;
	pGuestInfo.HotelAccommodationData = vGuestHotelAccommodationData;
	pDebugMessage = pDebugMessage + vGuestHotelAccommodationData.ReservationCode + Chars.Tab + vGuestHotelAccommodationData.ClientCode + Chars.Tab + vGuestHotelAccommodationData.CardCode + Chars.Tab 
					+ vGuestHotelAccommodationData.Customer + Chars.Tab + Format(vGuestHotelAccommodationData.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + Chars.Tab + vGuestHotelAccommodationData.Duration 
					+ Chars.Tab + Format(vGuestHotelAccommodationData.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + Chars.Tab 
					+ vGuestHotelAccommodationData.Room + Chars.Tab + vGuestHotelAccommodationData.RoomType + Chars.Tab + vGuestHotelAccommodationData.AccommodationType + Chars.Tab 
					+ vGuestHotelAccommodationData.IsCheckedIn + Chars.Tab + vGuestHotelAccommodationData.IsCheckedOut + Chars.Tab + vGuestHotelAccommodationData.IsCancelled;
EndProcedure // FillGuestInfoObject

// -----------------------------------------------------------------------------
Procedure FillExternalClientInfoObject(pMedConnWSProxy, pClientsRow, pGuestInfo, pDebugMessage)
	vClient = pClientsRow.Client;    
	vNameSpaseUri = "http://www.1chotel.ru/interfaces/medicine/";
	vDoc = pClientsRow.Doc;
	pDebugMessage = pDebugMessage + Chars.LF;
	
	pGuestInfo.OperationType = pClientsRow.OperationType;
	pDebugMessage = pDebugMessage + pGuestInfo.OperationType + Chars.Tab;
	
	pGuestInfo.LastName = TrimAll(vClient.LastName);
	pGuestInfo.FirstName = TrimAll(vClient.FirstName);
	pGuestInfo.SecondName = TrimAll(vClient.SecondName);
	pGuestInfo.Sex = Left(TrimAll(vClient.Sex), 1);
	pGuestInfo.DateOfBirth = vClient.DateOfBirth;
	pGuestInfo.IsDeletePackage	= pClientsRow.IsDeletePackage;
	pGuestInfo.IsDeleteDiscount	= pClientsRow.IsDeleteDiscount;
	vDiscountType = vClient.DiscountType;
	pGuestInfo.NoSMSDelivery = vClient.NoSMSDelivery;
	If Not ValueIsFilled(vDiscountType) Then
		If ValueIsFilled(vClient.ClientType) And ValueIsFilled(vClient.ClientType.DiscountType) Then
			vDiscountType = vClient.ClientType.DiscountType;
		EndIf;
	EndIf;
	pGuestInfo.DiscountType = ?(ValueIsFilled(vDiscountType), vDiscountType.Description, "");
	pDebugMessage = pDebugMessage + pGuestInfo.LastName + " " + pGuestInfo.FirstName + " " + pGuestInfo.SecondName + " " + pGuestInfo.Sex + " " + Format(pGuestInfo.DateOfBirth, "DF=dd.MM.yyyy") + Chars.Tab;
	
	vGuestIdentificationData = pMedConnWSProxy.XDTOFactory.Create(pMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "GuestIdentificationData"));
	vGuestIdentificationData.IDType = "";
	If ValueIsFilled(vClient.IdentityDocumentType) Then
		vGuestIdentificationData.IDType = TrimAll(vClient.IdentityDocumentType.Code);
	EndIf;
	vGuestIdentificationData.IDSeries = "";
	If vGuestIdentificationData.IDType = "21" And Not IsBlankString(vClient.IdentityDocumentSeries) And StrLen(TrimAll(vClient.IdentityDocumentSeries)) = 4 Then
		vGuestIdentificationData.IDSeries = Left(TrimAll(vClient.IdentityDocumentSeries), 2) + " " + Right(TrimAll(vClient.IdentityDocumentSeries), 2);
	Else
		vGuestIdentificationData.IDSeries = TrimAll(vClient.IdentityDocumentSeries);
	EndIf;
	vGuestIdentificationData.IDNumber = TrimAll(vClient.IdentityDocumentNumber);
	vGuestIdentificationData.IDIssueDate = vClient.IdentityDocumentIssueDate;
	vGuestIdentificationData.IDIssuedByUnitCode = vClient.IdentityDocumentUnitCode;
	vGuestIdentificationData.IDIssuedBy = vClient.IdentityDocumentIssuedBy;
	pGuestInfo.IdentificationData = vGuestIdentificationData;
		
	vGuestRegistrationData = pMedConnWSProxy.XDTOFactory.Create(pMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "GuestRegistrationAddress"));
	vGuestRegistrationData.Country = "";
	If ValueIsFilled(vClient.Citizenship) Then
		vGuestRegistrationData.Country = TrimAll(vClient.Citizenship.ISOCode3);
	EndIf;
	vGuestRegistrationData.AddressPresentation = TrimAll(vClient.Address);
	pGuestInfo.RegistrationData = vGuestRegistrationData;
	
	vGuestContactsData = pMedConnWSProxy.XDTOFactory.Create(pMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "GuestContactsData"));
	vGuestContactsData.Phone = vClient.Phone;
	vGuestContactsData.EMail = vClient.EMail;
	pGuestInfo.ContactsData = vGuestContactsData;
	
	vGuestMedicalInsurancePolicyData = pMedConnWSProxy.XDTOFactory.Create(pMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "GuestMedicalInsurancePolicyData"));
	vGuestMedicalInsurancePolicyData.PolicyType = "";
	vGuestMedicalInsurancePolicyData.PolicySeries = "";
	vGuestMedicalInsurancePolicyData.PolicyNumber = "";
	vGuestMedicalInsurancePolicyData.Insurer = "";
	vGuestMedicalInsurancePolicyData.PolicyContract = "";
	pGuestInfo.MedicalInsurancePolicyData = vGuestMedicalInsurancePolicyData;
	
	vGuestHotelAccommodationData = pMedConnWSProxy.XDTOFactory.Create(pMedConnWSProxy.XDTOFactory.Type(vNameSpaseUri, "GuestHotelAccommodationData"));
	If ValueIsFilled(vDoc.GuestGroup) Then
		vGuestHotelAccommodationData.ReservationCode = Format(vDoc.GuestGroup.Code, "ND=12; NFD=0; NZ=; NG=");
	Else
		vGuestHotelAccommodationData.ReservationCode = "";
	EndIf;     
	vDay = 24 * 3600;
	vGuestHotelAccommodationData.ClientCode = pClientsRow.ClientCode;
	vGuestHotelAccommodationData.Customer = TrimAll(vDoc.Customer);
	vGuestHotelAccommodationData.ArrivalDate = vDoc.Date;
	vGuestHotelAccommodationData.CheckInDate = vDoc.DateTimeFrom;
	If ValueIsFilled(vDoc.DateTimeTo) And ValueIsFilled(vDoc.DateTimeFrom) Then
		vGuestHotelAccommodationData.Duration = (BegOfDay(vDoc.DateTimeTo) - BegOfDay(vDoc.DateTimeFrom)) / vDay;
	Else
		vGuestHotelAccommodationData.Duration = 0;
	EndIf;
	vGuestHotelAccommodationData.CheckOutDate = vDoc.DateTimeTo;
	vGuestHotelAccommodationData.Room = TrimAll(vDoc.Room);
	If ValueIsFilled(vDoc.Room) Then
		vGuestHotelAccommodationData.RoomType = TrimAll(vDoc.Room.RoomType);
	Else
		vGuestHotelAccommodationData.RoomType = "";
	EndIf;
	vGuestHotelAccommodationData.RoomRate = "";
	vGuestHotelAccommodationData.AccommodationType = "";
	vGuestHotelAccommodationData.CardCode = TrimAll(StrReplace(GetClientCardCode(vDoc), Char(0), ""));
	vGuestHotelAccommodationData.FolioNumber = TrimAll(pClientsRow.Number);
	vGuestHotelAccommodationData.VoucherNumber = TrimAll(vDoc.HotelProduct);
	vGuestHotelAccommodationData.IsCheckedIn = True;
	vGuestHotelAccommodationData.IsCheckedOut = False;
	vGuestHotelAccommodationData.IsCancelled = pClientsRow.IsCancelled;
	pGuestInfo.HotelAccommodationData = vGuestHotelAccommodationData;
	pDebugMessage = pDebugMessage + vGuestHotelAccommodationData.ReservationCode + Chars.Tab + vGuestHotelAccommodationData.ClientCode + Chars.Tab 
					+ vGuestHotelAccommodationData.CardCode + Chars.Tab + vGuestHotelAccommodationData.Customer + Chars.Tab + Format(vGuestHotelAccommodationData.CheckInDate, "DF='dd.MM.yyyy HH:mm'") 
					+ Chars.Tab + vGuestHotelAccommodationData.Duration + Chars.Tab + Format(vGuestHotelAccommodationData.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + Chars.Tab 
					+ vGuestHotelAccommodationData.Room + Chars.Tab + vGuestHotelAccommodationData.RoomType + Chars.Tab + vGuestHotelAccommodationData.AccommodationType + Chars.Tab 
					+ vGuestHotelAccommodationData.IsCheckedIn + Chars.Tab + vGuestHotelAccommodationData.IsCheckedOut + Chars.Tab + vGuestHotelAccommodationData.IsCancelled;
EndProcedure // FillExternalClientInfoObject

// -----------------------------------------------------------------------------
Procedure PrintError(pErrorText)
	WriteLogEvent(NStr("en = 'ExportClientsTo1CMedicine.Error'; de = 'ExportClientsTo1CMedicine.Error'; ru = 'ВыгрузкаДанныхКлиентовВ1СМедицину.Ошибка'"), EventLogLevel.Warning, , , pErrorText);
	tcCommonFunctionOnClientServer.TextMessage(pErrorText, MessageStatus.Attention);
EndProcedure // PrintError

// -----------------------------------------------------------------------------
Procedure PrintSuccess(pReply)
	WriteLogEvent(NStr("en = 'ExportClientsTo1CMedicine.Reply'; de = 'ExportClientsTo1CMedicine.Reply'; ru = 'ВыгрузкаДанныхКлиентовВ1СМедицину.Ответ'"), EventLogLevel.Information, , , pReply);
	tcCommonFunctionOnClientServer.TextMessage(pReply, MessageStatus.Information);
EndProcedure // PrintSuccess

// -----------------------------------------------------------------------------
Function GetClientCardCode(pDoc)
	If TypeOf(pDoc) = Type("DocumentRef.Folio") Then
		vCards = cmGetClientIdentificationCardsByFolio(pDoc);
	Else
		vCards = cmGetClientIdentificationCardsByParentDoc(pDoc);
	EndIf;
	For Each vCardsRow In vCards Do
		Return vCardsRow.Ref.Identifier;
	EndDo;
	Return "";
EndFunction // GetClientCardCode

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
If SafeMode() = True Then
	SetSafeMode(False);
EndIf;

#EndRegion
