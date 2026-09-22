
#Region Public

// -----------------------------------------------------------------------------
//  Description: Returns value table with all room quotas
//
// Parameters:
//  pRoomQuotaFolder - CatalogRef.RoomQuotas - Ref RoomQuotaFolder
//  pTop			 - Number				 - Top rows
// 
// Returns:
//  ValueTable - Value table with room quotas
//
Function cmGetAllRoomQuotas(pRoomQuotaFolder = Undefined, pTop = 0) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT " + ?(pTop = 0, "", "TOP " + pTop) + "
	|	RoomQuotas.Ref AS RoomQuota
	|FROM
	|	Catalog.RoomQuotas AS RoomQuotas
	|WHERE 
	|	RoomQuotas.IsFolder = FALSE AND " +
		?(ValueIsFilled(pRoomQuotaFolder), "RoomQuotas.Ref IN HIERARCHY(&qRoomQuotaFolder) AND ", "") + "
	|	RoomQuotas.DeletionMark = FALSE
	|ORDER BY RoomQuotas.SortCode";
	vQry.SetParameter("qRoomQuotaFolder", pRoomQuotaFolder);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllRoomQuotas

// -----------------------------------------------------------------------------
//  Description: Returns value table with all room quotas for rooms
//
// Parameters:
//  pRoomQuotaFolder - CatalogRef.RoomQuotas - Ref RoomQuotaFolder
//  pTop			 - Number				 - Top rows
// 
// Returns:
//  ValueTable - Value table with room quotas
//
Function cmGetAllRoomQuotasForRooms(pRoomQuotaFolder = Undefined, pTop = 0) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT " + ?(pTop = 0, "", "TOP " + pTop) + "
	|	RoomQuotas.Ref AS RoomQuota
	|FROM
	|	Catalog.RoomQuotas AS RoomQuotas
	|WHERE 
	|	RoomQuotas.IsFolder = FALSE AND 
	|	RoomQuotas.IsQuotaForRooms = TRUE AND " +
		?(ValueIsFilled(pRoomQuotaFolder), "RoomQuotas.Ref IN HIERARCHY(&qRoomQuotaFolder) AND ", "") + "
	|	RoomQuotas.DeletionMark = FALSE
	|ORDER BY RoomQuotas.SortCode";
	vQry.SetParameter("qRoomQuotaFolder", pRoomQuotaFolder);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllRoomQuotasForRooms

// -----------------------------------------------------------------------------
//  Description: Checks if reservation or accommodation could be done in the given
//  room quota
//
// Parameters:
//  pAgent									 - CatalogRef.Customers	 - Ref
//  pCustomer								 - CatalogRef.Customers	 - Ref
//  pContract								 - CatalogRef.Contracts	 - Ref
//  pRoomQuota								 - CatalogRef.RoomQuotas - Ref
//  pHotel									 - CatalogRef.Hotels	 - Ref
//  pRoomType								 - CatalogRef.RoomTypes	 - Ref
//  pRoom									 - CatalogRef.Rooms		 - Ref
//  pDoc									 - DocumentRef			 - Reservation or accommodation document
//  pIsPosted								 - Boolean				 - IsPosted
//  pIsReservation							 - Boolean				 - IsReservation
//  pNumberOfRooms							 - Number				 - NumberOfRooms
//  pNumberOfBeds							 - Number				 - NumberOfBeds
//  pDateFrom								 - Date					 - DateFrom
//  pDateTo									 - Date					 - DateTo
//  rMsgTextRu								 - String				 - MsgTextRu
//  rMsgTextEn								 - String				 - MsgTextEn
//  rMsgTextDe								 - String				 - MsgTextDe
//  pHavePermissionToDoRoomQuotaOverbooking	 - Boolean				 - HavePermissionToDoRoomQuotaOverbooking
// 
// Returns:
//  Boolean - True if there are vacant rooms in room quota, False if not
//
Function cmCheckRoomQuotaAvailability(pAgent, pCustomer, pContract, pRoomQuota, pHotel, pRoomType, pRoom, pDoc, pIsPosted, pIsReservation, 
                                      pNumberOfRooms, pNumberOfBeds, Val pDateFrom, Val pDateTo, rMsgTextRu, rMsgTextEn, rMsgTextDe, 
									  pHavePermissionToDoRoomQuotaOverbooking = Undefined) Export
	// Initialize working variables
	vOK = True;
	vRoomsRemains = 0;
	vBedsRemains = 0;
	
	vRoomsInQuota = 0;
	vBedsInQuota = 0;
	
	// Check period
	vDoPeriodCorrection = False;
	If Not pRoomQuota.DoWriteOff Or pRoomQuota.DoWriteOff And pRoomQuota.IsForCheckInPeriods Then
		vDoPeriodCorrection = True;
	EndIf;
	If vDoPeriodCorrection Then
		If ValueIsFilled(pDoc) And (TypeOf(pDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pDoc) = Type("DocumentRef.Reservation")) Then
		    pDateFrom = cmMovePeriodFromToReferenceHour(pDateFrom, pDoc.RoomRate);
		    pDateTo = cmMovePeriodToToReferenceHour(pDateTo, pDoc.RoomRate);
		ElsIf ValueIsFilled(pHotel) And ValueIsFilled(pHotel.RoomRate) Then
		    pDateFrom = cmMovePeriodFromToReferenceHour(pDateFrom, pHotel.RoomRate);
		    pDateTo = cmMovePeriodToToReferenceHour(pDateTo, pHotel.RoomRate);
		EndIf;
	EndIf;
	If pDateFrom >= BegOfDay(pDateTo) Then
		Return vOK;
	EndIf;
	
	// Retrieve all necessary permissions
	vHavePermissionToDoRoomQuotaOverbooking = cmCheckUserPermissions("HavePermissionToDoRoomQuotaOverbooking");
	vHavePermissionToDoRoomQuotaOversales = cmCheckUserPermissions("HavePermissionToDoRoomQuotaOversales");
	
	// Take permissions from parameters
	If pHavePermissionToDoRoomQuotaOverbooking <> Undefined Then
		vHavePermissionToDoRoomQuotaOverbooking = pHavePermissionToDoRoomQuotaOverbooking;
	EndIf;
	
	// Build and run query to check room quota sales
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomQuotaSales.RoomQuota.Agent AS Agent,
	|	RoomQuotaSales.RoomQuota.Customer AS Customer,
	|	RoomQuotaSales.RoomQuota.Contract AS Contract,
	|	RoomQuotaSales.RoomQuota AS RoomQuota,
	|	RoomQuotaSales.Hotel AS Hotel,
	|	RoomQuotaSales.RoomType AS RoomType,
	|	RoomQuotaSales.Room AS Room,
	|	MIN(RoomQuotaSales.Period) AS Period,
	|	MIN(RoomQuotaSales.CounterClosingBalance) AS CounterClosingBalance,
	|	MIN(RoomQuotaSales.RoomsInQuotaClosingBalance) AS RoomsInQuota,
	|	MIN(RoomQuotaSales.BedsInQuotaClosingBalance) AS BedsInQuota,
	|	MIN(RoomQuotaSales.RoomsRemainsClosingBalance) AS RoomsRemains,
	|	MIN(RoomQuotaSales.BedsRemainsClosingBalance) AS BedsRemains
	|FROM (
	|SELECT
	|	RoomQuotaSalesBalanceAndTurnovers.RoomQuota AS RoomQuota,
	|	RoomQuotaSalesBalanceAndTurnovers.Hotel AS Hotel,
	|	RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType,
	|	RoomQuotaSalesBalanceAndTurnovers.Room AS Room,
	|	BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) AS Period,
	|	RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|	RoomQuotaSalesBalanceAndTurnovers.RoomsInQuotaClosingBalance AS RoomsInQuotaClosingBalance,
	|	RoomQuotaSalesBalanceAndTurnovers.BedsInQuotaClosingBalance AS BedsInQuotaClosingBalance,
	|	RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemainsClosingBalance,
	|	RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemainsClosingBalance
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(&qDateFrom, &qBoundaryTo, 
	|	                                                        DAY, 
	|	                                                        RegisterRecordsAndPeriodBoundaries, 
	|	                                                        RoomQuota = &qRoomQuota AND 
	|	                                                        Hotel = &qHotel AND 
	|	                                                        RoomType = &qRoomType" + 
																?((pRoomQuota.IsQuotaForRooms And ValueIsFilled(pRoom)), " AND Room = &qRoom", "") + "
	|) AS RoomQuotaSalesBalanceAndTurnovers
	|WHERE 
	|	BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) < &qDateTo
	|) AS RoomQuotaSales
	|
	|GROUP BY
	|	RoomQuotaSales.RoomQuota,
	|	RoomQuotaSales.RoomQuota.Agent,
	|	RoomQuotaSales.RoomQuota.Customer,
	|	RoomQuotaSales.RoomQuota.Contract,
	|	RoomQuotaSales.Hotel,
	|	RoomQuotaSales.RoomType,
	|	RoomQuotaSales.Room";
	
	vQry.SetParameter("qRoomQuota", pRoomQuota);
	vQry.SetParameter("qAgent", pAgent);
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qBoundaryTo", New Boundary(pDateTo, BoundaryType.Excluding));
	vQry.SetParameter("qDateTo", BegOfDay(pDateTo));
	
	vQryTab = vQry.Execute().Unload();
	
	vErrorPeriod = '00010101';
	If vQryTab.Count() > 0 Then
		For Each vQryTabRow In vQryTab Do
			If Not ValueIsFilled(vErrorPeriod) Then
				vErrorPeriod = vQryTabRow.Period;
			EndIf;
			
			vRoomsInQuota = vRoomsInQuota + vQryTabRow.RoomsInQuota;
			vBedsInQuota = vBedsInQuota + vQryTabRow.BedsInQuota;
			
			vRoomsRemains = vRoomsRemains + vQryTabRow.RoomsRemains;
			vBedsRemains = vBedsRemains + vQryTabRow.BedsRemains;
		EndDo;
	Else
		vErrorPeriod = pDateFrom;
		
		If pIsPosted Then
			vRoomsRemains = -pNumberOfRooms;
			vBedsRemains = -pNumberOfBeds;
		EndIf;
	EndIf;
	If ValueIsFilled(vErrorPeriod) Then
		vErrorPeriod = Max(vErrorPeriod, pDateFrom);
		vErrorPeriod = Min(vErrorPeriod, pDateTo);
	EndIf;
	
	// Check room quota rests
	vNotEnoughRooms = 0;
	vNotEnoughBeds = 0;
	If pIsPosted Then
		vNotEnoughRooms = -vRoomsRemains;
		vNotEnoughBeds = -vBedsRemains;
	Else
		vNotEnoughRooms = pNumberOfRooms - vRoomsRemains;
		vNotEnoughBeds = pNumberOfBeds - vBedsRemains;
	EndIf;
	
	If pNumberOfRooms > 0 Then
		If vNotEnoughRooms > 0 Then
			vMsgTextRu = "По типу номера " + pRoomType + " на " + Format(vErrorPeriod, "DF=dd.MM.yyyy") + " по квоте " + pRoomQuota + " не хватает " + vNotEnoughRooms + " свободных номеров!";
			vMsgTextEn = "" + vNotEnoughRooms + " vacant rooms are not available for allotment " + pRoomQuota + " and room type " + pRoomType + " on " + Format(vErrorPeriod, "DF=dd.MM.yyyy") + "!";
			vMsgTextDe = "" + vNotEnoughRooms + " vacant rooms are not available for allotment " + pRoomQuota + " and room type " + pRoomType + " on " + Format(vErrorPeriod, "DF=dd.MM.yyyy") + "!";
			vMessage = NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
			If Not vHavePermissionToDoRoomQuotaOversales And Not pIsReservation Then
				WriteLogEvent(NStr("en='Allotments.NoVacantRooms';ru='Квоты.НетСвободныхНомеров';de='Quote.KeineFreienZimmer'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
				vOK = False;
				rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
				rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
				rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
			ElsIf Not vHavePermissionToDoRoomQuotaOverbooking And pIsReservation Then
				WriteLogEvent(NStr("en='Allotments.NoVacantRooms';ru='Квоты.НетСвободныхНомеров';de='Quote.KeineFreienZimmer'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
				vOK = False;
				rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
				rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
				rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
			ElsIf pRoomQuota.OverbookingIsNotAllowed Then
				WriteLogEvent(NStr("en='Allotments.NoVacantRooms';ru='Квоты.НетСвободныхНомеров';de='Quote.KeineFreienZimmer'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
				vOK = False;
				rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
				rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
				rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
			Else
				WriteLogEvent(NStr("en='Allotments.NoVacantRooms';ru='Квоты.НетСвободныхНомеров';de='Quote.KeineFreienZimmer'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
				If cmShowNotEnoughRoomsMessages() Then
					tcCommonFunctionOnClientServer.TextMessage(cmGetMessageHeader(pDoc) + vMessage, MessageStatus.Attention);
					rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
					rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
					rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
				EndIf;
			EndIf;
		ElsIf vNotEnoughBeds > 0 Then
			vMsgTextRu = "По типу номера " + pRoomType + " на " + Format(vErrorPeriod, "DF=dd.MM.yyyy") + " по квоте " + pRoomQuota + " не хватает " + vNotEnoughBeds + " свободных мест!";
			vMsgTextEn = "" + vNotEnoughBeds + " vacant beds are not available for allotment " + pRoomQuota + " and room type " + pRoomType + " on " + Format(vErrorPeriod, "DF=dd.MM.yyyy") + "!";
			vMsgTextDe = "" + vNotEnoughBeds + " vacant beds are not available for allotment " + pRoomQuota + " and room type " + pRoomType + " on " + Format(vErrorPeriod, "DF=dd.MM.yyyy") + "!";
			vMessage = NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
			If Not vHavePermissionToDoRoomQuotaOversales And Not pIsReservation Then
				WriteLogEvent(NStr("en='Allotments.NoVacantRooms';ru='Квоты.НетСвободныхНомеров';de='Quote.KeineFreienZimmer'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
				vOK = False;
				rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
				rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
				rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
			ElsIf Not vHavePermissionToDoRoomQuotaOverbooking And pIsReservation Then
				WriteLogEvent(NStr("en='Allotments.NoVacantRooms';ru='Квоты.НетСвободныхНомеров';de='Quote.KeineFreienZimmer'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
				vOK = False;
				rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
				rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
				rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
			ElsIf pRoomQuota.OverbookingIsNotAllowed Then
				WriteLogEvent(NStr("en='Allotments.NoVacantRooms';ru='Квоты.НетСвободныхНомеров';de='Quote.KeineFreienZimmer'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
				vOK = False;
				rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
				rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
				rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
			Else
				WriteLogEvent(NStr("en='Allotments.NoVacantRooms';ru='Квоты.НетСвободныхНомеров';de='Quote.KeineFreienZimmer'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
				If cmShowNotEnoughRoomsMessages() Then
					tcCommonFunctionOnClientServer.TextMessage(cmGetMessageHeader(pDoc) + vMessage, MessageStatus.Attention);
					rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
					rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
					rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
				EndIf;
			EndIf;
		EndIf;
	ElsIf vNotEnoughBeds > 0 Then
		vMsgTextRu = "По типу номера " + pRoomType + " на " + Format(vErrorPeriod, "DF=dd.MM.yyyy") + " по квоте " + pRoomQuota + " не хватает " + vNotEnoughBeds + " свободных мест!";
		vMsgTextEn = "" + vNotEnoughBeds + " vacant beds are not available for allotment " + pRoomQuota + " and room type " + pRoomType + " on " + Format(vErrorPeriod, "DF=dd.MM.yyyy") + "!";
		vMsgTextDe = "" + vNotEnoughBeds + " vacant beds are not available for allotment " + pRoomQuota + " and room type " + pRoomType + " on " + Format(vErrorPeriod, "DF=dd.MM.yyyy") + "!";
		vMessage = NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
		If Not vHavePermissionToDoRoomQuotaOversales And Not pIsReservation Then
			WriteLogEvent(NStr("en='Allotments.NoVacantRooms';ru='Квоты.НетСвободныхНомеров';de='Quote.KeineFreienZimmer'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
			vOK = False;
			rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
			rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
			rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
		ElsIf Not vHavePermissionToDoRoomQuotaOverbooking And pIsReservation Then
			WriteLogEvent(NStr("en='Allotments.NoVacantRooms';ru='Квоты.НетСвободныхНомеров';de='Quote.KeineFreienZimmer'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
			vOK = False;
			rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
			rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
			rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
		ElsIf pRoomQuota.OverbookingIsNotAllowed Then
			WriteLogEvent(NStr("en='Allotments.NoVacantRooms';ru='Квоты.НетСвободныхНомеров';de='Quote.KeineFreienZimmer'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
			vOK = False;
			rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
			rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
			rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
		Else
			WriteLogEvent(NStr("en='Allotments.NoVacantRooms';ru='Квоты.НетСвободныхНомеров';de='Quote.KeineFreienZimmer'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
			If cmShowNotEnoughRoomsMessages() Then
				tcCommonFunctionOnClientServer.TextMessage(cmGetMessageHeader(pDoc) + vMessage, MessageStatus.Attention);
				rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
				rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
				rMsgTextDe = rMsgTextDe + vMsgTextDe + Chars.LF;
			EndIf;
		EndIf;
	EndIf;
	
	// OK
	Return vOK;
EndFunction // cmCheckRoomQuotaAvailability

// -----------------------------------------------------------------------------
//  Description: Returns value table with room quota available resources
//
// Parameters:
//  pRoomQuota	 - CatalogRef.RoomQuotas - Ref
//  pAgent		 - CatalogRef.Customers	 - Ref
//  pCustomer	 - CatalogRef.Customers	 - Ref
//  pContract	 - CatalogRef.Contracts	 - Ref
//  pHotel		 - CatalogRef.Hotels	 - Ref
//  pRoomType	 - CatalogRef.RoomTypes	 - Ref
//  pRoom		 - CatalogRef.Rooms		 - Ref
//  pDateFrom	 - Date					 - DateFrom
//  pDateTo		 - Date					 - DateTo
// 
// Returns:
//  ValueTable - Value table with vacant room quota rooms by room types
//
Function cmCalculateRoomQuotaResources(pRoomQuota, pHotel, pRoomType = Undefined, pRoom = Undefined, pDateFrom, pDateTo) Export
	
	// Build and run query to check room quota sales
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomQuotaSales.RoomQuota.Agent AS Agent,
	|	RoomQuotaSales.RoomQuota.Customer AS Customer,
	|	RoomQuotaSales.RoomQuota.Contract AS Contract,
	|	RoomQuotaSales.RoomQuota AS RoomQuota,
	|	RoomQuotaSales.Hotel AS Hotel,
	|	RoomQuotaSales.RoomType AS RoomType, " + ?((pRoomQuota.IsQuotaForRooms And ValueIsFilled(pRoom)), "RoomQuotaSales.Room AS Room, ", "") + "
	|	MIN(RoomQuotaSales.CounterClosingBalance) AS CounterClosingBalance,
	|	MIN(RoomQuotaSales.InitialRoomsInQuotaClosingBalance) AS InitialRoomsInQuota,
	|	MIN(RoomQuotaSales.InitialBedsInQuotaClosingBalance) AS InitialBedsInQuota,
	|	MIN(RoomQuotaSales.RoomsInQuotaClosingBalance) AS RoomsInQuota,
	|	MIN(RoomQuotaSales.BedsInQuotaClosingBalance) AS BedsInQuota,
	|	MIN(RoomQuotaSales.RoomsReservedClosingBalance) AS RoomsReserved,
	|	MIN(RoomQuotaSales.BedsReservedClosingBalance) AS BedsReserved,
	|	MIN(RoomQuotaSales.InHouseRoomsClosingBalance) AS InHouseRooms,
	|	MIN(RoomQuotaSales.InHouseBedsClosingBalance) AS InHouseBeds,
	|	MIN(RoomQuotaSales.RoomsRemainsClosingBalance) AS RoomsRemains,
	|	MIN(RoomQuotaSales.BedsRemainsClosingBalance) AS BedsRemains
	|FROM (
	|	SELECT
	|		RoomQuotaSalesBalanceAndTurnovers.RoomQuota AS RoomQuota,
	|		RoomQuotaSalesBalanceAndTurnovers.Hotel AS Hotel,
	|		RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType, " + ?((pRoomQuota.IsQuotaForRooms And ValueIsFilled(pRoom)), "RoomQuotaSalesBalanceAndTurnovers.Room AS Room, ", "") + "
	|		BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) AS Period,
	|		RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|		RoomQuotaSalesBalanceAndTurnovers.InitialRoomsInQuotaClosingBalance AS InitialRoomsInQuotaClosingBalance,
	|		RoomQuotaSalesBalanceAndTurnovers.InitialBedsInQuotaClosingBalance AS InitialBedsInQuotaClosingBalance,
	|		RoomQuotaSalesBalanceAndTurnovers.RoomsInQuotaClosingBalance AS RoomsInQuotaClosingBalance,
	|		RoomQuotaSalesBalanceAndTurnovers.BedsInQuotaClosingBalance AS BedsInQuotaClosingBalance,
	|		RoomQuotaSalesBalanceAndTurnovers.RoomsReservedClosingBalance AS RoomsReservedClosingBalance,
	|		RoomQuotaSalesBalanceAndTurnovers.BedsReservedClosingBalance AS BedsReservedClosingBalance,
	|		RoomQuotaSalesBalanceAndTurnovers.InHouseRoomsClosingBalance AS InHouseRoomsClosingBalance,
	|		RoomQuotaSalesBalanceAndTurnovers.InHouseBedsClosingBalance AS InHouseBedsClosingBalance,
	|		RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemainsClosingBalance,
	|		RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemainsClosingBalance
	|	FROM
	|		AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(&qDateFrom, &qBoundaryTo, 
	|	                                                        DAY, 
	|	                                                        RegisterRecordsAndPeriodBoundaries, 
	|	                                                        RoomQuota = &qRoomQuota AND 
	|	                                                        Hotel = &qHotel AND 
	|	                                                        (RoomType = &qRoomType OR NOT &qRoomTypeIsFilled)" +
																?((pRoomQuota.IsQuotaForRooms And ValueIsFilled(pRoom)), " AND Room = &qRoom", "") + "
	|	) AS RoomQuotaSalesBalanceAndTurnovers
	|	WHERE
	|		BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) < &qDateTo
	|) AS RoomQuotaSales
	|GROUP BY
	|	RoomQuotaSales.RoomQuota,
	|	RoomQuotaSales.RoomQuota.Agent,
	|	RoomQuotaSales.RoomQuota.Customer,
	|	RoomQuotaSales.RoomQuota.Contract,
	|	RoomQuotaSales.Hotel,
	|	RoomQuotaSales.RoomType" + ?((pRoomQuota.IsQuotaForRooms And ValueIsFilled(pRoom)), ", RoomQuotaSales.Room", "");

	vQry.SetParameter("qRoomQuota", pRoomQuota);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoomTypeIsFilled", ValueIsFilled(pRoomType));
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qBoundaryTo", New Boundary(pDateTo, BoundaryType.Excluding));
	vQry.SetParameter("qDateTo", BegOfDay(pDateTo));
	
	vQryTab = vQry.Execute().Unload();
	
	Return vQryTab;
EndFunction // cmCalculateRoomQuotaResources

// -----------------------------------------------------------------------------
Function cmCalculateRoomQuotaForecastResources(pRoomQuota, pHotel, pRoomType = Undefined, pDateFrom, pDateTo) Export
	// Build and run query to check room quota sales
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomQuotaForecast.RoomQuota AS RoomQuota,
	|	RoomQuotaForecast.Hotel AS Hotel,
	|	RoomQuotaForecast.RoomType AS RoomType,
	|	SUM(RoomQuotaForecast.RoomsReservedTurnover) AS RoomsRemains,
	|	MIN(RoomQuotaForecast.BedsReservedTurnover) AS BedsRemains
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qDateFrom,
	|			&qDateTo,
	|			PERIOD,
	|			RoomQuota = &qRoomQuota
	|				AND Hotel = &qHotel
	|				AND (RoomType = &qRoomType
	|					OR NOT &qRoomTypeIsFilled)) AS RoomQuotaForecast
	|
	|GROUP BY
	|	RoomQuotaForecast.RoomQuota,
	|	RoomQuotaForecast.Hotel,
	|	RoomQuotaForecast.RoomType";
	vQry.SetParameter("qRoomQuota", pRoomQuota);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoomTypeIsFilled", ValueIsFilled(pRoomType));
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qDateTo", New Boundary(pDateTo, BoundaryType.Excluding));
	vQryTab = vQry.Execute().Unload();
	Return vQryTab;
EndFunction // cmCalculateRoomQuotaForecastResources

// -----------------------------------------------------------------------------
//  Description: Returns value table with set room quota documents active for the
//  given filters and period
//
// Parameters:
//  pHotel			 - CatalogRef.Hotels - Ref
//  pCheckInDate	 - Date				 - CheckInDate
//  pCheckOutDate	 - Date				 - CheckOutDate
//  pRoomType		 - CatalogRef.RoomTypes	 - Ref
//  pAgent			 - CatalogRef.Customers	 - Ref
//  pCustomer		 - CatalogRef.Customers	 - Ref
//  pContract		 - CatalogRef.Contracts	 - Ref
//  pShowNoContract	 - Boolean				 - ShowNoContract
// 
// Returns:
//  ValueTable - Value table with documents
//
Function cmGetRoomQuotaDocuments(pHotel, pCheckInDate, pCheckOutDate, pRoomType, 
                                 pAgent, pCustomer, pContract, pShowNoContract = False) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SetRoomQuota.Ref AS SetRoomQuota
	|FROM
	|	Document.SetRoomQuota AS SetRoomQuota
	|WHERE SetRoomQuota.Posted" + 
		?(ValueIsFilled(pHotel), " AND SetRoomQuota.Hotel = &qHotel ", "") + 
		?(ValueIsFilled(pCheckOutDate), " AND SetRoomQuota.DateFrom < &qCheckOutDate ", "") + 
		?(ValueIsFilled(pCheckInDate), " AND SetRoomQuota.DateTo > &qCheckInDate ", "") + 
		?(ValueIsFilled(pRoomType), " AND SetRoomQuota.RoomType = &qRoomType ", "") + 
		?(ValueIsFilled(pAgent), " AND SetRoomQuota.RoomQuota.Agent = &qAgent ", "") + 
		?(ValueIsFilled(pCustomer), " AND SetRoomQuota.RoomQuota.Customer = &qCustomer ", "") + 
		?(pShowNoContract, ?(ValueIsFilled(pContract), " AND (SetRoomQuota.RoomQuota.Contract = &qContract OR SetRoomQuota.RoomQuota.Contract = &qEmptyContract) ", ""), 
		                   ?(ValueIsFilled(pContract), " AND SetRoomQuota.RoomQuota.Contract = &qContract ", "")) + "
	|ORDER BY
	|	SetRoomQuota.PointInTime";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCheckInDate", pCheckInDate);
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qAgent", pAgent);
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	If pShowNoContract Then
		vQry.SetParameter("qEmptyContract", Catalogs.Contracts.EmptyRef());
	EndIf;
	vDocs = vQry.Execute().Unload();
	
	Return vDocs;
EndFunction // cmGetRoomQuotaDocuments

// -----------------------------------------------------------------------------
//  Description: Calculates resources to write off from the room quota vacat rooms
//  for the given reservation document based on number of guets being
//  checked-in already
//
// Parameters:
//  pDoc		 - DocumentRef			 - Recorder
//  pRoomQuota	 - CatalogRef.RoomQuotas - Ref
//  pHotel		 - CatalogRef.Hotels	 - Ref
//  pRoomType	 - CatalogRef.RoomTypes	 - Ref
//  pRoom		 - CatalogRef.Rooms		 - Ref
//  pDateFrom	 - Date					 - DateFrom
//  pDateTo		 - Date					 - DateTo
// 
// Returns:
//  ValueTable - Value table with resources to write off
//
Function cmGetDocumentRoomQuotaWriteOffs(pDoc, pRoomQuota, pHotel, pRoomType, pRoom, pDateFrom, pDateTo) Export
	
	// Build and run query to check room quota sales
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomInventory.Recorder,
	|	-SUM(RoomInventory.RoomsInQuota) AS RoomsWrittenOff,
	|	-SUM(RoomInventory.BedsInQuota) AS BedsWrittenOff
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.IsRoomQuota
	|	AND RoomInventory.CheckInDate < &qDateTo
	|	AND RoomInventory.CheckOutDate > &qDateFrom
	|	AND RoomInventory.RecordType = &qExpense
	|	AND RoomInventory.Recorder = &qDoc
	|	AND RoomInventory.RoomQuota = &qRoomQuota
	|	AND RoomInventory.Hotel = &qHotel
	|	AND RoomInventory.RoomType = &qRoomType" 
		+ ?(pRoomQuota.IsQuotaForRooms, " AND RoomInventory.Room = &qRoom", "") + "
	|GROUP BY
	|	RoomInventory.Recorder";
	
	vQry.SetParameter("qRoomQuota", pRoomQuota);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qDateTo", pDateTo);
	vQry.SetParameter("qDoc", pDoc);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	
	vQryTab = vQry.Execute().Unload();
	
	Return vQryTab;
EndFunction // cmGetDocumentRoomQuotaWriteOffs

// -----------------------------------------------------------------------------
//  Description: Returns value table of room quotas for the given room type and
//  room
//
// Parameters:
//  pHotel		 - CatalogRef.Hotels - Ref
//  pRoomType	 - CatalogRef.RoomTypes	 - Ref
//  pRoom		 - CatalogRef.Rooms		 - Ref
//  pDateFrom	 - Date					 - DateFrom
//  pDateTo		 - Date					 - DateTo
// 
// Returns:
//  ValueTable - Value table with room quotas and vacant room resources
//
Function cmGetRoomQuotasForRoom(pHotel, pRoomType, pRoom, pDateFrom, pDateTo) Export
	// Build and run query to find room quotas for the room given
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomQuotaSales.RoomQuota AS RoomQuota,
	|	RoomQuotaSales.Hotel AS Hotel,
	|	RoomQuotaSales.RoomType AS RoomType,
	|	RoomQuotaSales.Room AS Room,
	|	MIN(RoomQuotaSales.CounterClosingBalance) AS CounterClosingBalance,
	|	MIN(RoomQuotaSales.RoomsInQuotaClosingBalance) AS RoomsInQuota,
	|	MIN(RoomQuotaSales.BedsInQuotaClosingBalance) AS BedsInQuota,
	|	MIN(RoomQuotaSales.RoomsReservedClosingBalance) AS RoomsReserved,
	|	MIN(RoomQuotaSales.BedsReservedClosingBalance) AS BedsReserved,
	|	MIN(RoomQuotaSales.InHouseRoomsClosingBalance) AS InHouseRooms,
	|	MIN(RoomQuotaSales.InHouseBedsClosingBalance) AS InHouseBeds,
	|	MIN(RoomQuotaSales.RoomsRemainsClosingBalance) AS RoomsRemains,
	|	MIN(RoomQuotaSales.BedsRemainsClosingBalance) AS BedsRemains
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qDateFrom,
	|			&qDateTo,
	|			Minute,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel = &qHotel
	|				AND RoomType = &qRoomType
	|				AND RoomQuota.IsQuotaForRooms
	|				AND Room = &qRoom) AS RoomQuotaSales
	|
	|GROUP BY
	|	RoomQuotaSales.RoomQuota,
	|	RoomQuotaSales.Hotel,
	|	RoomQuotaSales.RoomType,
	|	RoomQuotaSales.Room";
	
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qDateTo", New Boundary(pDateTo, BoundaryType.Excluding));
	
	vQryTab = vQry.Execute().Unload();
	
	Return vQryTab;
EndFunction // cmGetRoomQuotasForRoom

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel			 - CatalogRef.Hotels - Ref
//  pAllotment		 - CatalogRef.RoomQuotas - Ref
//  pCheckinDate	 - Date					 - CheckInDate
//  pCheckOutDate	 - Date					 - CheckOutDate
//  pByRooms		 - Boolean				 - ByRooms
// 
// Returns:
//  ValueList - List rooms
//
Function cmGetAllotmentRooms(pHotel, pAllotment, pCheckinDate, pCheckOutDate, pByRooms = True) Export
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomQuotaSales.Room AS Room,
	|	MIN(RoomQuotaSales.CounterClosingBalance) AS CounterClosingBalance,
	|	MIN(RoomQuotaSales.RoomsInQuotaClosingBalance) AS RoomsInQuota,
	|	MIN(RoomQuotaSales.BedsInQuotaClosingBalance) AS BedsInQuota,
	|	MIN(RoomQuotaSales.RoomsReservedClosingBalance) AS RoomsReserved,
	|	MIN(RoomQuotaSales.BedsReservedClosingBalance) AS BedsReserved,
	|	MIN(RoomQuotaSales.InHouseRoomsClosingBalance) AS InHouseRooms,
	|	MIN(RoomQuotaSales.InHouseBedsClosingBalance) AS InHouseBeds,
	|	MIN(RoomQuotaSales.RoomsRemainsClosingBalance) AS RoomsRemains,
	|	MIN(RoomQuotaSales.BedsRemainsClosingBalance) AS BedsRemains
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qDateFrom,
	|			&qDateTo,
	|			Minute,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel = &qHotel
	|				AND RoomQuota.IsQuotaForRooms
	|				AND RoomQuota = &qRoomQuota) AS RoomQuotaSales
	|
	|GROUP BY
	|	RoomQuotaSales.Room
	|
	|HAVING
	|	(&qByRooms
	|			AND MIN(RoomQuotaSales.RoomsRemainsClosingBalance) > 0
	|		OR NOT &qByRooms
	|			AND MIN(RoomQuotaSales.BedsRemainsClosingBalance) > 0)";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomQuota", pAllotment);
	vQry.SetParameter("qDateFrom", pCheckInDate);
	vQry.SetParameter("qDateTo", New Boundary(pCheckOutDate, BoundaryType.Excluding));
	vQry.SetParameter("qByRooms", pByRooms);
	vQryTab = vQry.Execute().Unload();
	vRoomsList = New ValueList();
	vRoomsList.LoadValues(vQryTab.UnloadColumn("Room"));
	Return vRoomsList;
EndFunction // cmGetAllotmentRooms

// -----------------------------------------------------------------------------
Procedure cmWriteOffAllotmentRooms(pAllotment, pRoomType, pPeriodFrom, pPeriodTo) Export
	// Check attributes
	If Not ValueIsFilled(pPeriodFrom) Or Not ValueIsFilled(pPeriodTo) Or pPeriodTo <= pPeriodFrom Then
		Raise NStr("en='Period is wrong!';ru='Период указан не верно!';de='Der Zeitraum ist falsch angegeben!'");
	EndIf;
	If Not ValueIsFilled(pAllotment) Then
		Raise NStr("en='Allotment is not set!';ru='Не выбрана квота!';de='Keine Quote ist gewählt!'");
	EndIf;
	If Not ValueIsFilled(pRoomType) Then
		Raise NStr("en='Room type is not set!';ru='Не выбран тип номера!';de='Kein Zimmertyp ist gewählt!'");
	EndIf;
	// Build list of days in the period choosen
	vDays = New ValueTable();
	vDays.Columns.Add("PeriodFrom", cmGetDateTimeTypeDescription());
	vDays.Columns.Add("PeriodTo", cmGetDateTimeTypeDescription());
	vCurDay = pPeriodFrom;
	While vCurDay < pPeriodTo Do
		vDay = vDays.Add();
		vDay.PeriodFrom = cm0SecondShift(vCurDay);
		vDay.PeriodTo = cm0SecondShift(vCurDay + 24*3600);
		vCurDay = vCurDay + 24*3600;
	EndDo;
	// Build chain of periods with the same number of rooms to write off
	vCurNumberOfRooms = 0;
	vPeriod = Undefined;
	vPeriodsChain = New ValueTable();
	vPeriodsChain.Columns.Add("PeriodFrom", cmGetDateTimeTypeDescription());
	vPeriodsChain.Columns.Add("PeriodTo", cmGetDateTimeTypeDescription());
	vPeriodsChain.Columns.Add("NumberOfRooms", cmGetNumberTypeDescription(6, 0));
	For Each vDay In vDays Do
		vRemains = cmCalculateRoomQuotaResources(pAllotment, pRoomType.Owner, pRoomType, Undefined, vDay.PeriodFrom, vDay.PeriodTo);
		vNumberOfRooms = 0;
		If vRemains.Count() > 0 Then
			vNumberOfRooms = vRemains.Get(0).RoomsRemains;
		EndIf;
		If vCurNumberOfRooms <> vNumberOfRooms Then
			If vPeriod <> Undefined Then
				vPeriod.PeriodTo = cm0SecondShift(vDay.PeriodFrom);
			EndIf;
			vPeriod = vPeriodsChain.Add();
			vPeriod.PeriodFrom = vDay.PeriodFrom;
			vPeriod.NumberOfRooms = vNumberOfRooms;
			vCurNumberOfRooms = vNumberOfRooms;
		EndIf;
	EndDo;
	If vPeriod <> Undefined Then
		vPeriod.PeriodTo = cm0SecondShift(vDay.PeriodTo);
	EndIf;
	// Create new "Set room quota" document and fill it's parameters for each period in chain
	vWereChanges = False;
	For Each vPeriod In vPeriodsChain Do
		If vPeriod.NumberOfRooms = 0 Then
			Continue;
		EndIf;
		vDocObj = Documents.SetRoomQuota.CreateDocument();
		vDocObj.RoomQuota = pAllotment;
		If ValueIsFilled(vDocObj.RoomQuota.Hotel) Then
			vDocObj.Hotel = vDocObj.RoomQuota.Hotel;
		EndIf;
		vDocObj.RoomType = pRoomType;
		If Not ValueIsFilled(vDocObj.Hotel) Then
			vDocObj.Hotel = vDocObj.RoomType.Owner;
		EndIf;
		If vPeriod.NumberOfRooms < 0 Then
			vDocObj.SetRoomQuotaType = Enums.SetRoomQuotaTypes.Add;
			vPeriod.NumberOfRooms = -vPeriod.NumberOfRooms;
		Else
			vDocObj.SetRoomQuotaType = Enums.SetRoomQuotaTypes.Remove;
		EndIf;
		vDocObj.DateFrom = cm0SecondShift(vPeriod.PeriodFrom);
		vDocObj.pmFillAttributesWithDefaultValues();
		vDocObj.NumberOfBedsPerRoom = vDocObj.RoomType.NumberOfBedsPerRoom;
		vDocObj.NumberOfPersonsPerRoom = vDocObj.RoomType.NumberOfPersonsPerRoom;
		vDocObj.DateTo = cm0SecondShift(vPeriod.PeriodTo);
		vDocObj.Duration = vDocObj.pmCalculateDuration();
		vDocObj.NumberOfRooms = vPeriod.NumberOfRooms;
		vDocObj.NumberOfBeds = vDocObj.NumberOfRooms * vDocObj.NumberOfBedsPerRoom;
		vDocObj.Write(DocumentWriteMode.Posting);
	EndDo;
EndProcedure // WriteOffRoomsAction

#EndRegion
