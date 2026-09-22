
#Region Variables

Var IsInFileMode;

#EndRegion  

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	// Fill as posted before flag
	vWasPosted = Posted;
	If AdditionalProperties.Property("WasPosted") And TypeOf(AdditionalProperties.WasPosted) = Type("Boolean") Then
		vWasPosted = AdditionalProperties.WasPosted;
	EndIf;
	// Close of day mode
	vCloseOfDayMode = False;
	If AdditionalProperties.Property("CloseOfDayMode") And AdditionalProperties.CloseOfDayMode Then
		vCloseOfDayMode = True;
	EndIf;
	// Do not check balances
	vDoNotCheckBalances = False;
	If AdditionalProperties.Property("DoNotCheckBalances") And AdditionalProperties.DoNotCheckBalances Then
		vDoNotCheckBalances = True;
	EndIf;
	// Fill execution mode
	IsInFileMode = False;
	If lower(Left(InfoBaseConnectionString(), 5)) = "file=" Then
		IsInFileMode = True;
	EndIf;
	// Post to expected reservations
	If Not pCancel And (RoomQuota.TreatAsTentativeBooking Or IsForecast) Then
		PostToExpectedGuestGroups(pCancel);
	EndIf;
	// Post to sales forecast
	vRoomRevenueAmount = 0;
	If Not IsForecast Then
		If ValueIsFilled(RoomQuota.BudgetCurrency) And 
		   RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And 
		  (RoomQuota.AllotmentType = Enums.AllotmentTypes.Definite Or 
		   RoomQuota.AllotmentType = Enums.AllotmentTypes.DefiniteNotGuaranteed Or 
		   RoomQuota.AllotmentType = Enums.AllotmentTypes.Tentative) Then
			vRoomRevenueAmount = PostToBusinessBlockForecastSales();
		EndIf;
	EndIf;
	// Set flag that forecast is used for allotment
	If Not vCloseOfDayMode And Not AdditionalProperties.Property("SkipAllotmentUpdate") Then
		// Post to room quota sales
		vRoomQuotaObj = Undefined;
		If IsForecast And ValueIsFilled(RoomQuota) And Not RoomQuota.ForecastIsUsed Then
			If vRoomQuotaObj = Undefined Then
				vRoomQuotaObj = RoomQuota.GetObject();
			EndIf;
			vRoomQuotaObj.ForecastIsUsed = True;
			If Not ValueIsFilled(vRoomQuotaObj.FirstForecastUsageTime) Then
				vRoomQuotaObj.FirstForecastUsageTime = CurrentSessionDate();
			EndIf;
		EndIf;
		// Edit number of room nights for business blocks
		If ValueIsFilled(RoomQuota) And RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And 
		   NumberOfRooms <> 0 And ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) And 
		   BegOfDay(DateTo) > BegOfDay(DateFrom) And Not vWasPosted Then
			vRoomNights = (BegOfDay(DateTo) - BegOfDay(DateFrom))/(24*3600)*NumberOfRooms;
			If vRoomNights <> 0 Then
				If vRoomQuotaObj = Undefined Then
					vRoomQuotaObj = RoomQuota.GetObject();
				EndIf;
				vRoomNightsChange = ?(SetRoomQuotaType = Enums.SetRoomQuotaTypes.Remove, -vRoomNights, vRoomNights);
				vRoomQuotaObj.RoomNights = vRoomQuotaObj.RoomNights + vRoomNightsChange;
				If vRoomQuotaObj.RoomNights < 0 Then
					vRoomQuotaObj.RoomNights = 0;
				EndIf;
				vRoomQuotaObj.BudgetReservationAmount = vRoomQuotaObj.BudgetReservationAmount + vRoomRevenueAmount;
				If vRoomQuotaObj.BudgetReservationAmount < 0 Then
					vRoomQuotaObj.BudgetReservationAmount = 0;
				EndIf;
				vRoomQuotaObj.BudgetADR = ?(vRoomQuotaObj.RoomNights > 0, Round(vRoomQuotaObj.BudgetReservationAmount/vRoomQuotaObj.RoomNights, 2), 0);
				vRoomQuotaObj.BudgetAmount = vRoomQuotaObj.BudgetReservationAmount + vRoomQuotaObj.BudgetMICEAmount;
				If vRoomQuotaObj.BudgetAmount < 0 Then
					vRoomQuotaObj.BudgetAmount = 0;
				EndIf;
			EndIf;
		EndIf;
		// Save allotment if changed
		If vRoomQuotaObj <> Undefined And vRoomQuotaObj.Modified() Then
			vRoomQuotaObj.Write();
		EndIf;
	EndIf;
	// Post to room quota sales
	If Not IsForecast Then
		PostToRoomQuotaSales(pCancel);
	EndIf;
	// Post to room inventory if necessary
	If Not pCancel And RoomQuota.DoWriteOff And Not IsForecast Then
		PostToRoomInventory(pCancel);
	EndIf;
	// Check room quota balances
	If Not vCloseOfDayMode And Not pCancel Then
		pCancel	= pmCheckDocumentAttributes(True, vMessage, vAttributeInErr, vDoNotCheckBalances);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
	EndIf;
	// Try to find reservations and accommodations that should be reposted
	If Not vCloseOfDayMode And Not IsForecast Then
		If SetRoomQuotaType = Enums.SetRoomQuotaTypes.Add Then
			RepostIntersectedDocuments();
		ElsIf SetRoomQuotaType = Enums.SetRoomQuotaTypes.Remove And Not vDoNotCheckBalances Then
			If Not cmCheckUserPermissions("HavePermissionToDoRoomQuotaOversales") Then
				CheckNegativeRoomQuotaBalances();
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Edit number of room nights for business blocks
	If Not AdditionalProperties.Property("SkipAllotmentUpdate") Then
		vRoomQuotaObj = Undefined;
		If ValueIsFilled(RoomQuota) And RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And 
		   NumberOfRooms <> 0 And ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) And 
		   BegOfDay(DateTo) > BegOfDay(DateFrom) Then
			vRoomNights = (BegOfDay(DateTo) - BegOfDay(DateFrom))/(24*3600)*NumberOfRooms;
			If vRoomNights <> 0 Then
				If vRoomQuotaObj = Undefined Then
					vRoomQuotaObj = RoomQuota.GetObject();
				EndIf;
				vRoomNightsChange = ?(SetRoomQuotaType = Enums.SetRoomQuotaTypes.Remove, -vRoomNights, vRoomNights);
				vRoomQuotaObj.RoomNights = vRoomQuotaObj.RoomNights - vRoomNightsChange;
				If vRoomQuotaObj.RoomNights < 0 Then
					vRoomQuotaObj.RoomNights = 0;
				EndIf;
				vRoomQuotaObj.BudgetReservationAmount = vRoomQuotaObj.BudgetReservationAmount - vRoomNightsChange * vRoomQuotaObj.BudgetADR;
				If vRoomQuotaObj.BudgetReservationAmount < 0 Then
					vRoomQuotaObj.BudgetReservationAmount = 0;
				EndIf;
				vRoomQuotaObj.BudgetAmount = vRoomQuotaObj.BudgetReservationAmount + vRoomQuotaObj.BudgetMICEAmount;
				If vRoomQuotaObj.BudgetAmount < 0 Then
					vRoomQuotaObj.BudgetAmount = 0;
				EndIf;
				If vRoomQuotaObj.BudgetReservationAmount = 0 Or vRoomQuotaObj.RoomNights = 0 Then
					vRoomQuotaObj.BudgetADR = 0;
				EndIf;
			EndIf;
		EndIf;
		// Save allotment if changed
		If vRoomQuotaObj <> Undefined And vRoomQuotaObj.Modified() Then
			vRoomQuotaObj.Write();
		EndIf;
	EndIf;
EndProcedure // UndoPosting

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(Posted, vMessage, vAttributeInErr, True);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		Else
			AdditionalProperties.Insert("WasPosted", Posted);
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	pmFillAttributesWithDefaultValues();
	If TypeOf(pBase) = Type("CatalogRef.RoomQuotas") Then
		RoomQuota = pBase.Ref;
		If ValueIsFilled(pBase.Hotel) Then
			Hotel = pBase.Hotel;
		EndIf;		
	ElsIf TypeOf(pBase) = Type("DocumentRef.SetRoomQuota") Then
		FillPropertyValues(ThisObject, pBase, , "Number, Date, Author, DeletionMark, Posted, ParentDoc");
		ParentDoc = pBase;
		SetRoomQuotaType = Enums.SetRoomQuotaTypes.Remove;
		// Set date from to current date
		DateFrom = cm0SecondShift(BegOfDay(CurrentSessionDate()) + (DateFrom - BegOfDay(DateFrom)));
		// Reset duration to the 1 day and recalculate date to
		Duration = 1;
		DateTo = pmCalculateDateTo();
		// Calculate quota balances for the period set
		pmGetRoomQuotaBalances();
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
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Posted Then
		UndoPosting(pCancel);
	EndIf;
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)   
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pIsPosted, pMessage, pAttributeInErr, pDoNotCheckRests = False) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
	EndIf;
	If Not ValueIsFilled(RoomQuota) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Квота номеров> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room allotment> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Room allotment> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomQuota", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room allotment> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Room allotment> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(RoomType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тип номера> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Room type> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomType", pAttributeInErr);
	EndIf;
	If ValueIsFilled(RoomQuota) Then
		If ValueIsFilled(RoomQuota.Hotel) And RoomQuota.Hotel <> Hotel Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "<Гостиница> операции отличается от гостиницы квоты!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Operation <hotel> is different from allotment hotel!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Operation <Hotel> unterscheidet sich von den Hotel im Allotment!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
		EndIf;
		If RoomQuota.IsQuotaForRooms Then
			If Not ValueIsFilled(Room) Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Реквизит <Номер> должен быть заполнен, т.к. выбрана квота по номерам!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "<Room> attribute should be filled because you have choosen allotment for rooms!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "<Room> attribute should be filled because you have choosen allotment for rooms!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
			EndIf;
		Else
			If ValueIsFilled(Room) Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Реквизит <Номер> должен быть пустой, т.к. выбрана квота по типам номеров!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "<Room> attribute should be empty because you have choosen room type allotment!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "<Room> attribute should be empty because you have choosen room type allotment!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(RoomType) And ValueIsFilled(Hotel) Then
		If RoomType.Owner <> Hotel Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "<Гостиница> операции отличается от гостиницы типа номера!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Operation <hotel> is different from room type hotel!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Operation <Hotel> unterscheidet sich von den Hotel im Zimmertyp!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
		EndIf;
	EndIf;
	If Not ValueIsFilled(SetRoomQuotaType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Вид движения> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Movement type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Movement type> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "SetRoomQuotaType", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(DateFrom) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата начала периода квоты номеров> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Start of room allotment period> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Start of room allotment period> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "DateFrom", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(DateTo) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата окончания периода квоты номеров> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<End of room allotment period> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<End of room allotment period> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "DateTo", pAttributeInErr);
	EndIf;
	If ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) And DateFrom >= DateTo Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Дата начала периода изменения квоты номеров должна быть раньше чем дата окончания периода изменения квоты!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "Start of change room allotment period should be earlier then end of change room allotment period!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Start of change room allotment period should be earlier then end of change room allotment period!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "DateFrom", pAttributeInErr);
	EndIf;
	// Check that there are priods with check-in date started from the document period from and ending with document period to
	If ValueIsFilled(RoomQuota) And RoomQuota.IsForCheckInPeriods Then
		If Not cmCheckCheckInPeriods(Hotel, RoomQuota, DateFrom, DateTo) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Указанный период не попадает на границы заездов!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Period specified is out from the check-in period dates!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Period specified is out from the check-in period dates!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "DateTo", pAttributeInErr);
		EndIf;
	EndIf;
	If ValueIsFilled(BaseRoomQuota) And BaseRoomQuota.IsForCheckInPeriods Then
		If Not cmCheckCheckInPeriods(Hotel, BaseRoomQuota, DateFrom, DateTo) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Указанный период не попадает на границы заездов квоты с которой списываются номера!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Period specified is out from the check-in period dates of the allotment to write off rooms from!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Period specified is out from the check-in period dates of the allotment to write off rooms from!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "DateTo", pAttributeInErr);
		EndIf;
	EndIf;
	// Check allotment vacant rooms balances
	If Not pDoNotCheckRests And Not IsForecast Then
		If ValueIsFilled(RoomQuota) Then
			If Not cmCheckRoomQuotaAvailability(RoomQuota.Agent, RoomQuota.Customer, RoomQuota.Contract, RoomQuota, 
			                                    Hotel, RoomType, Room, ThisObject.Ref, pIsPosted, True,
												NumberOfRooms, NumberOfBeds, 
			                                    cm1SecondShift(DateFrom), cm0SecondShift(DateTo), 
			                                    vMsgTextRu, vMsgTextEn, vMsgTextDe) Then
				vHasErrors = True; 
				pAttributeInErr = ?(pAttributeInErr = "", "DateFrom", pAttributeInErr);
			EndIf;
			If ValueIsFilled(RoomType) And Not ValueIsFilled(BaseRoomQuota) Then
				If Not cmCheckRoomAvailability(Hotel, Undefined, ?(ValueIsFilled(RoomType.BaseRoomType), RoomType.BaseRoomType, RoomType), Room, Ref, pIsPosted, Not ValueIsFilled(Room),
				                               0, NumberOfRooms, NumberOfBeds, 0, 
				                               NumberOfBedsPerRoom, NumberOfPersonsPerRoom, Max(CurrentSessionDate(), cm1SecondShift(DateFrom)), cm0SecondShift(DateTo), 
				                               vMsgTextRu, vMsgTextEn, vMsgTextDe) Then
					vHasErrors = True; 
					pAttributeInErr = ?(pAttributeInErr = "", "DateFrom", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(BaseRoomQuota) And SetRoomQuotaType = Enums.SetRoomQuotaTypes.Add Then
			If Not cmCheckRoomQuotaAvailability(BaseRoomQuota.Agent, BaseRoomQuota.Customer, BaseRoomQuota.Contract, BaseRoomQuota, 
			                                    Hotel, RoomType, Room, ThisObject.Ref, pIsPosted, True,
												NumberOfRooms, NumberOfBeds, 
			                                    cm1SecondShift(DateFrom), cm0SecondShift(DateTo), 
			                                    vMsgTextRu, vMsgTextEn, vMsgTextDe) Then
				vHasErrors = True; 
				pAttributeInErr = ?(pAttributeInErr = "", "DateFrom", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

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
	If Not ValueIsFilled(SetRoomQuotaType) Then
		SetRoomQuotaType = Enums.SetRoomQuotaTypes.Add;
	EndIf;
	If Not ValueIsFilled(DateFrom) Then
		DateFrom = BegOfday(CurrentSessionDate());
		DateFrom = pmInitializeDateFrom();
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Calculates and returns duration for giving check in and check out dates
// -----------------------------------------------------------------------------
Function pmCalculateDuration() Export
	vRoomRate = Catalogs.RoomRates.EmptyRef();
	If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.RoomRate) Then
		vRoomRate = RoomQuota.RoomRate;
	Else
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.RoomRate) Then
				vRoomRate = Hotel.RoomRate;
			EndIf;
		EndIf;
	EndIf;
	Return cmCalculateDuration(vRoomRate, DateFrom, DateTo);
EndFunction // pmCalculateDuration

// -----------------------------------------------------------------------------
// Calculates and returns room quota end date based on giving duration and start date
// -----------------------------------------------------------------------------
Function pmCalculateDateTo() Export
	vDateTo = DateTo;
	If ValueIsFilled(DateFrom) And
	   Duration > 0 Then
		vRoomRate = Catalogs.RoomRates.EmptyRef();
		If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.RoomRate) Then
			vRoomRate = RoomQuota.RoomRate;
		Else
			If ValueIsFilled(Hotel) Then
				If ValueIsFilled(Hotel.RoomRate) Then
					vRoomRate = Hotel.RoomRate;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vRoomRate) Then
			vRRPer = ?(vRoomRate.PeriodInHours = 0, 24, vRoomRate.PeriodInHours);
			vRRRH = vRoomRate.ReferenceHour;
			vDateFrom = DateFrom;
			If vRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
				vDateFrom = Date(Year(vDateFrom), Month(vDateFrom), Day(vDateFrom), 
				                 Hour(vRRRH), Minute(vRRRH), 0);
			EndIf;
			vDateTo = vDateFrom + Duration*vRRPer*3600;
		Else
			vDateTo = DateFrom + Duration*24*3600;
		EndIf;
	EndIf;
	Return cm0SecondShift(vDateTo);
EndFunction // pmCalculateDateTo

// -----------------------------------------------------------------------------
// Initialize room quota start time based on giving room rate
// -----------------------------------------------------------------------------
Function pmInitializeDateFrom() Export
	vDateFrom = DateFrom;
	If ValueIsFilled(vDateFrom) Then
		vRoomRate = Catalogs.RoomRates.EmptyRef();
		If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.RoomRate) Then
			vRoomRate = RoomQuota.RoomRate;
		Else
			If ValueIsFilled(Hotel) Then
				If ValueIsFilled(Hotel.RoomRate) Then
					vRoomRate = Hotel.RoomRate;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vRoomRate) Then
			vRRRH = vRoomRate.ReferenceHour;
			If vRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
				vDateFrom = Date(Year(vDateFrom), Month(vDateFrom), Day(vDateFrom), 
				                 Hour(vRRRH), Minute(vRRRH), 0);
			EndIf;
		EndIf;
	EndIf;
	Return cm0SecondShift(vDateFrom);
EndFunction // pmInitializeDateFrom

// -----------------------------------------------------------------------------
Procedure pmGetRoomQuotaBalances() Export
	If Not ValueIsFilled(RoomQuota) Then
		Return;
	EndIf;
	// Calculate quota balances for the period set
	vResources = cmCalculateRoomQuotaResources(RoomQuota, Hotel, RoomType, Room, cm1SecondShift(DateFrom), cm0SecondShift(DateTo));
	If vResources.Count() = 1 Then
		vResRow = vResources.Get(0);
		// Set resources
		NumberOfRooms = vResRow.RoomsRemains;
		NumberOfBeds = vResRow.BedsRemains;
	Else
		// Set resources to 0
		NumberOfRooms = 0;
		NumberOfBeds = 0;
	EndIf;
EndProcedure // pmGetRoomQuotaBalances

// -----------------------------------------------------------------------------
Procedure pmClearSalesForecastInThePast() Export
	vClearForecast = False;
	
	vHotelAccountingDate = Hotel.AccountingDate;
	If ValueIsFilled(vHotelAccountingDate) And AdditionalProperties.Property("AccountingDate") Then
		If ValueIsFilled(AdditionalProperties.AccountingDate) And TypeOf(AdditionalProperties.AccountingDate) = Type("Date") Then
			vHotelAccountingDate = AdditionalProperties.AccountingDate;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vHotelAccountingDate) Then
		vHotelAccountingDate = BegOfDay(CurrentSessionDate());
	EndIf;
	vCheckDate = vHotelAccountingDate;
	vNextCheckDate = vCheckDate + 24*3600;

	RegisterRecords.SalesForecast.Read();
	i = 0;
	While i < RegisterRecords.SalesForecast.Count() Do
		vSalesRow = RegisterRecords.SalesForecast.Get(i);
		If vSalesRow.AccountingDate < vCheckDate Then
			RegisterRecords.SalesForecast.Delete(i);
		Else
			i = i + 1;
		EndIf;
		If vSalesRow.AccountingDate > vNextCheckDate Then
			Break;
		EndIf;
	EndDo;

	RegisterRecords.SalesForecast.Write = False;;
	RegisterRecords.SalesForecast.Write();
EndProcedure // pmClearSalesForecastInThePast

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillRQInitializationAttributes(pRQRec, pPeriod)
	pRQRec.RoomQuota = RoomQuota;
	pRQRec.Hotel = Hotel;
	pRQRec.RoomType = RoomType;
	pRQRec.Room = Room;

	pRQRec.Period = pPeriod;
	
	pRQRec.InitialRoomsInQuota = 0;
	pRQRec.InitialBedsInQuota = 0;
	pRQRec.RoomsInQuota = 0;
	pRQRec.BedsInQuota = 0;
	pRQRec.RoomsRemains = 0;
	pRQRec.BedsRemains = 0;
	
	pRQRec.Counter = 1;
	
	pRQRec.IsRoomQuota = False;

	pRQRec.Timestamp = CurrentSessionDate();
EndProcedure // FillRQInitializationAttributes

// -----------------------------------------------------------------------------
Procedure FillRQAttributes(pRQRec, pRoomQuota, pPeriod)
	FillPropertyValues(pRQRec, pRoomQuota);
	FillPropertyValues(pRQRec, ThisObject);

	pRQRec.RoomQuota = pRoomQuota;
	pRQRec.Period = pPeriod;
	
	If ValueIsFilled(pRoomQuota) And ValueIsFilled(pRoomQuota.RoomRate) Then
		pRQRec.RoomRateType = RoomQuota.RoomRate.RoomRateType;
	EndIf;
	
	If SetRoomQuotaType = Enums.SetRoomQuotaTypes.Add Then
		pRQRec.RoomsInQuota = NumberOfRooms;
		pRQRec.BedsInQuota = NumberOfBeds;
		pRQRec.RoomsRemains = NumberOfRooms;
		pRQRec.BedsRemains = NumberOfBeds;
	ElsIf SetRoomQuotaType = Enums.SetRoomQuotaTypes.Remove Then
		pRQRec.RoomsInQuota = -NumberOfRooms;
		pRQRec.BedsInQuota = -NumberOfBeds;
		pRQRec.RoomsRemains = -NumberOfRooms;
		pRQRec.BedsRemains = -NumberOfBeds;
	EndIf;
	If IsInitial Then
		pRQRec.InitialRoomsInQuota = pRQRec.RoomsInQuota;
		pRQRec.InitialBedsInQuota = pRQRec.BedsInQuota;
	Else
		pRQRec.InitialRoomsInQuota = 0;
		pRQRec.InitialBedsInQuota = 0;
	EndIf;
	
	pRQRec.Counter = 0;
	
	pRQRec.IsRoomQuota = True;

	pRQRec.Timestamp = CurrentSessionDate();
EndProcedure // FillRQAttributes

// -----------------------------------------------------------------------------
Procedure PostToRoomQuotaSales(pCancel)
	// Add data locks
	vDataLock = New DataLock();
	vRQSItem = vDataLock.Add("AccumulationRegister.RoomQuotaSales");
	vRQSItem.Mode = DataLockMode.Exclusive;
	vRQSItem.SetValue("RoomQuota", RoomQuota);
	vRQSItem.SetValue("RoomType", RoomType);
	vRQSItem.SetValue("Period", New Range(cm0SecondShift(DateFrom), cm0SecondShift(DateTo)));
	vDataLock.Lock();

	// Do receipt movement on begin of time to initialize room quota balances
	vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
	FillRQInitializationAttributes(vRQRec, '20000101');
	
	// Do receipt movement on date from
	vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
	FillRQAttributes(vRQRec, RoomQuota, cm0SecondShift(DateFrom));
		
	// Do expense movement on date to
	vRQRec = RegisterRecords.RoomQuotaSales.AddExpense();
	FillRQAttributes(vRQRec, RoomQuota, cm0SecondShift(DateTo));
	
	// Do receipt initialization movements on each day from the room quota period
	vCurDate = DateFrom;
	While vCurDate < DateTo Do
		vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
		FillRQInitializationAttributes(vRQRec, vCurDate);
		vCurDate = vCurDate + 24*3600;
	EndDo;		
	
	// Do inverted movements for the base allotment
	If ValueIsFilled(BaseRoomQuota) Then
		// Do expense movement on date from
		vRQRec = RegisterRecords.RoomQuotaSales.AddExpense();
		FillRQAttributes(vRQRec, BaseRoomQuota, cm0SecondShift(DateFrom));
			
		// Do receipt movement on date to
		vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
		FillRQAttributes(vRQRec, BaseRoomQuota, cm0SecondShift(DateTo));
	EndIf;
			
	// Write RegisterRecords	
	RegisterRecords.RoomQuotaSales.Write();
	RegisterRecords.RoomQuotaSales.Write = False;
EndProcedure // PostToRoomQuotaSales

// -----------------------------------------------------------------------------
Function PostToBusinessBlockForecastSales()
	vHotelAccountingDate = Hotel.AccountingDate;
	If ValueIsFilled(vHotelAccountingDate) And AdditionalProperties.Property("AccountingDate") Then
		If ValueIsFilled(AdditionalProperties.AccountingDate) And TypeOf(AdditionalProperties.AccountingDate) = Type("Date") Then
			vHotelAccountingDate = AdditionalProperties.AccountingDate;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vHotelAccountingDate) Then
		vHotelAccountingDate = BegOfDay(CurrentSessionDate());
	EndIf;
	vRoomRevenueAmount = 0;
	vMessage = "";
	vAllotmentForecastSales = RoomQuota.GetObject().pmCalculateBusinessBlockForecastSales(Hotel, RoomType, DateFrom, DateTo, ?(SetRoomQuotaType = Enums.SetRoomQuotaTypes.Add, NumberOfRooms, -NumberOfRooms), ?(SetRoomQuotaType = Enums.SetRoomQuotaTypes.Add, NumberOfBeds, -NumberOfBeds), NumberOfBedsPerRoom, vMessage);
	For Each vSalesRow In vAllotmentForecastSales Do
		If ValueIsFilled(vSalesRow.AccountingDate) And ValueIsFilled(vSalesRow.Service) And (vSalesRow.Sales <> 0 Or vSalesRow.RoomsRented <> 0) Then
			If vSalesRow.AccountingDate >= vHotelAccountingDate Then
				vSFRec = RegisterRecords.SalesForecast.Add();
				FillPropertyValues(vSFRec, RoomQuota);
				FillPropertyValues(vSFRec, vSalesRow);
			EndIf;
				
			vRoomRevenueAmount = vRoomRevenueAmount + Round(cmConvertCurrencies(vSalesRow.RoomRevenue, Hotel.ReportingCurrency, , RoomQuota.BudgetCurrency, , Date, Hotel), 2);
		EndIf;
	EndDo;
	Return vRoomRevenueAmount;
EndFunction // PostToBusinessBlockForecastSales

// -----------------------------------------------------------------------------
Procedure FillRIAttributes(pRIRec, pRoomQuota, pPeriod)
	FillPropertyValues(pRIRec, ThisObject);
	
	pRIRec.RoomQuota = pRoomQuota;
	pRIRec.Period = pPeriod;
	pRIRec.PeriodFrom = cm0SecondShift(DateFrom);
	pRIRec.PeriodTo = cm0SecondShift(DateTo);
	
	If ValueIsFilled(RoomType) And ValueIsFilled(RoomType.BaseRoomType) Then
		pRIRec.RoomType = RoomType.BaseRoomType;
	EndIf;		
	
	If ValueIsFilled(pRoomQuota.RoomRate) Then
		pRIRec.RoomRateType = pRoomQuota.RoomRate.RoomRateType;
	EndIf;
	
	pRIRec.CheckInDate = cm0SecondShift(DateFrom);
	pRIRec.CheckInAccountingDate = BegOfDay(DateFrom);
	pRIRec.CheckOutDate = cm0SecondShift(DateTo);
	pRIRec.CheckOutAccountingDate = BegOfDay(DateTo);
	
	pRIRec.PricePresentation = "";
	
	If SetRoomQuotaType = Enums.SetRoomQuotaTypes.Add Then
		pRIRec.RoomsInQuota = NumberOfRooms;
		pRIRec.BedsInQuota = NumberOfBeds;
		pRIRec.RoomsVacant = NumberOfRooms;
		pRIRec.BedsVacant = NumberOfBeds;
	ElsIf SetRoomQuotaType = Enums.SetRoomQuotaTypes.Remove Then
		pRIRec.RoomsInQuota = -NumberOfRooms;
		pRIRec.BedsInQuota = -NumberOfBeds;
		pRIRec.RoomsVacant = -NumberOfRooms;
		pRIRec.BedsVacant = -NumberOfBeds;
	EndIf;
	
	pRIRec.IsRoomQuota = True;

	pRIRec.Timestamp = CurrentSessionDate();
EndProcedure // FillRIAttributes

// -----------------------------------------------------------------------------
Procedure WriteRoomInitializationRecords()
	// Check if there are initialization records for the current room type
	vAddInitRecords = True;
	If ValueIsFilled(RoomType) And RoomType.IsVirtual Then
		vAddInitRecords = False;
	EndIf;
	If vAddInitRecords Then
		vCurDate = BegOfDay(Min(Date, CurrentSessionDate() - 24*3600));

		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	AccumulationRegister.RoomInventory AS RoomInventory
		|WHERE
		|	RoomInventory.Counter > 0
		|	AND RoomInventory.Hotel = &qHotel
		|	AND RoomInventory.RoomType = &qRoomType
		|	AND RoomInventory.Period = &qInitializationDate";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qRoomType", RoomType);
		vQry.SetParameter("qInitializationDate", vCurDate);
		vQryRes = vQry.Execute().Unload();
		If vQryRes.Count() > 0 Then
			vQryResRow = vQryRes.Get(0);
			If vQryResRow.Count > 0 Then
				vAddInitRecords = False;
			EndIf;
		EndIf;
	EndIf;
	
	// Write initialization records for all dates in the room type next N years
	vN = 15;
	If IsInFileMode Then
		vN = 3;
	EndIf;
	If vAddInitRecords Then
		// Write first initialization record to the 1st of january of year 2000
		vRIRec = RegisterRecords.RoomInventory.AddReceipt();
		
		vRIRec.Period = '20000101';
		vRIRec.Hotel = Hotel;
		vRIRec.RoomType = RoomType;
		vRIRec.Room = Room;
		
		vRIRec.TotalRooms = 0;
		vRIRec.TotalBeds = 0;
		vRIRec.TotalGuests = 0;
		vRIRec.RoomsVacant = 0;
		vRIRec.BedsVacant = 0;
		vRIRec.GuestsVacant = 0;
		
		vRIRec.Counter = 1;
		
		vRIRec.ParentDoc = Ref;
		vRIRec.NumberOfBedsPerRoom = 0;
		vRIRec.NumberOfPersonsPerRoom = 0;
		vRIRec.Remarks = "";
		vRIRec.Author = Catalogs.Employees.EmptyRef();
		vRIRec.IsRoomInventory = False;

		vRIRec.Timestamp = CurrentSessionDate();
		
		// Write initialization records for all dates in the room type next N years
		vEndOfInitializationPeriod = vCurDate + 366*vN*24*3600;
		While vCurDate < vEndOfInitializationPeriod Do
			vRIRec = RegisterRecords.RoomInventory.AddReceipt();
			
			vRIRec.Period = vCurDate;
			vRIRec.Hotel = Hotel;
			vRIRec.RoomType = RoomType;
			vRIRec.Room = Catalogs.Rooms.EmptyRef();
			
			vRIRec.TotalRooms = 0;
			vRIRec.TotalBeds = 0;
			vRIRec.TotalGuests = 0;
			vRIRec.RoomsVacant = 0;
			vRIRec.BedsVacant = 0;
			vRIRec.GuestsVacant = 0;
			
			vRIRec.Counter = 1;
			
			vRIRec.ParentDoc = Ref;
			vRIRec.NumberOfBedsPerRoom = 0;
			vRIRec.NumberOfPersonsPerRoom = 0;
			vRIRec.Remarks = "";
			vRIRec.Author = Catalogs.Employees.EmptyRef();
			vRIRec.IsRoomInventory = False;

			vRIRec.Timestamp = CurrentSessionDate();
			
			vCurDate = vCurDate + 24*3600;
		EndDo;
	EndIf;
EndProcedure // WriteRoomInitializationRecords

// -----------------------------------------------------------------------------
Procedure PostToRoomInventory(pCancel)
	// Add room inventory initialization records
	WriteRoomInitializationRecords();
	
	// Do expense movement on date from
	vRIRec = RegisterRecords.RoomInventory.AddExpense();
	FillRIAttributes(vRIRec, RoomQuota, cm0SecondShift(DateFrom));
		
	// Do receipt movement on date to
	vRIRec = RegisterRecords.RoomInventory.AddReceipt();
	FillRIAttributes(vRIRec, RoomQuota, cm0SecondShift(DateTo));
	
	// Do inverted movements for the base allotment
	If ValueIsFilled(BaseRoomQuota) Then
		// Do receipt movement on date from
		vRIRec = RegisterRecords.RoomInventory.AddReceipt();
		FillRIAttributes(vRIRec, BaseRoomQuota, cm0SecondShift(DateFrom));
			
		// Do expense movement on date to
		vRIRec = RegisterRecords.RoomInventory.AddExpense();
		FillRIAttributes(vRIRec, BaseRoomQuota, cm0SecondShift(DateTo));
	EndIf;		
			
	// Write RegisterRecords	
	RegisterRecords.RoomInventory.Write();
	RegisterRecords.RoomInventory.Write = False;
EndProcedure // PostToRoomInventory

// -----------------------------------------------------------------------------
Procedure PostToExpectedGuestGroups(pCancel)
	// Do movements for each day from the reservation period
	vEndOfDay = EndOfDay(DateFrom);
	While vEndOfDay <= DateTo Do
		vEGGRec = RegisterRecords.ExpectedGuestGroups.Add();
		
		FillPropertyValues(vEGGRec, ThisObject);
		
		vEGGRec.Period = vEndOfDay;
		vEGGRec.Recorder = Ref;
		
		// Resources
		If SetRoomQuotaType = Enums.SetRoomQuotaTypes.Add Then
			vEGGRec.RoomsReserved = ?(NumberOfRooms <> 0, NumberOfRooms, ?(NumberOfBedsPerRoom <> 0, NumberOfBeds/NumberOfBedsPerRoom, 0));
			vEGGRec.BedsReserved = NumberOfBeds;
		ElsIf SetRoomQuotaType = Enums.SetRoomQuotaTypes.Remove Then
			vEGGRec.RoomsReserved = -?(NumberOfRooms <> 0, NumberOfRooms, ?(NumberOfBedsPerRoom <> 0, NumberOfBeds/NumberOfBedsPerRoom, 0));
			vEGGRec.BedsReserved = -NumberOfBeds;
		EndIf;
		vEGGRec.AdditionalBedsReserved = 0;
		vEGGRec.GuestsReserved = 0;
		
		// Next date
		vEndOfDay = vEndOfDay + 24*3600;
	EndDo;
			
	// Write movements
	RegisterRecords.ExpectedGuestGroups.Write();
	RegisterRecords.ExpectedGuestGroups.Write = False;
EndProcedure // PostToExpectedGuestGroups

// -----------------------------------------------------------------------------
Procedure RepostIntersectedDocuments()
	// If this document is referenced by allotment room types then skip reposting
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomQuotasRoomTypes.SetRoomQuota
	|FROM
	|	Catalog.RoomQuotas.RoomTypes AS RoomQuotasRoomTypes
	|WHERE
	|	RoomQuotasRoomTypes.SetRoomQuota = &qRef";
	vQry.SetParameter("qRef", Ref);
	vAllotments = vQry.Execute().Unload();
	If vAllotments.Count() > 0 Then
		Return;
	EndIf;
	// Run query to get list of documents to be reposted
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventory.Recorder
	|INTO RecordersWithRoomQuotaWriteOffs
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.RoomQuota = &qRoomQuota
	|	AND RoomInventory.IsRoomQuota
	|	AND RoomInventory.Period >= &qPeriodFrom
	|	AND RoomInventory.Period <= &qPeriodTo
	|	AND RoomInventory.RoomType = &qRoomType
	|	AND (RoomInventory.Room = &qRoom
	|			OR &qRoomIsEmpty)
	|	AND RoomInventory.Hotel = &qHotel
	|	AND RoomInventory.BedsVacant = RoomInventory.BedsInQuota
	|	AND RoomInventory.BedsVacant < 0
	|	AND (NOT RoomInventory.Recorder REFS Document.SetRoomQuota)
	|
	|GROUP BY
	|	RoomInventory.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomQuotaDocs.Recorder
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomQuotaDocs
	|WHERE
	|	RoomQuotaDocs.RoomQuota = &qRoomQuota
	|	AND (RoomQuotaDocs.IsReservation
	|			OR RoomQuotaDocs.IsAccommodation)
	|	AND RoomQuotaDocs.Period >= &qPeriodFrom
	|	AND RoomQuotaDocs.Period <= &qPeriodTo
	|	AND RoomQuotaDocs.RoomType = &qRoomType
	|	AND (RoomQuotaDocs.Room = &qRoom
	|			OR &qRoomIsEmpty)
	|	AND RoomQuotaDocs.Hotel = &qHotel
	|	AND (RoomQuotaDocs.AccommodationType.Type = &qRoom OR RoomQuotaDocs.AccommodationType.Type = &qBeds)
	|	AND (NOT RoomQuotaDocs.Recorder IN
	|				(SELECT
	|					RecordersWithRoomQuotaWriteOffs.Recorder
	|				FROM
	|					RecordersWithRoomQuotaWriteOffs AS RecordersWithRoomQuotaWriteOffs))
	|
	|GROUP BY
	|	RoomQuotaDocs.Recorder";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRoomQuota", RoomQuota);
	vQry.SetParameter("qRoomType", RoomType);
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qRoomIsEmpty", Not ValueIsFilled(Room));
	vQry.SetParameter("qPeriodFrom", cm0SecondShift(DateFrom));
	vQry.SetParameter("qPeriodTo", cm0SecondShift(DateTo));
	vQry.SetParameter("qRoom", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qBeds", Enums.AccomodationTypes.Beds);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDocObj = vDocsRow.Recorder.GetObject();
		vDocObj.Write(DocumentWriteMode.Posting);
	EndDo;
EndProcedure // RepostIntersectedDocuments

// -----------------------------------------------------------------------------
Procedure CheckNegativeRoomQuotaBalances()
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomQuotaSales.Hotel,
	|	RoomQuotaSales.RoomQuota,
	|	RoomQuotaSales.RoomType, " + 
	?((RoomQuota.IsQuotaForRooms And ValueIsFilled(Room)), "RoomQuotaSales.Room, ", "") + "
	|	MIN(RoomQuotaSales.RoomsInQuotaClosingBalance) AS RoomsInQuota,
	|	MIN(RoomQuotaSales.BedsInQuotaClosingBalance) AS BedsInQuota,
	|	MIN(RoomQuotaSales.RoomsRemainsClosingBalance) AS RoomsRemains,
	|	MIN(RoomQuotaSales.BedsRemainsClosingBalance) AS BedsRemains
	|FROM (
	|SELECT
	|	RoomQuotaSalesBalanceAndTurnovers.Hotel,
	|	RoomQuotaSalesBalanceAndTurnovers.RoomQuota,
	|	RoomQuotaSalesBalanceAndTurnovers.RoomType, " + 
	?((RoomQuota.IsQuotaForRooms And ValueIsFilled(Room)), "RoomQuotaSalesBalanceAndTurnovers.Room, ", "") + "
	|	BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) AS Period,
	|	RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance,
	|	RoomQuotaSalesBalanceAndTurnovers.RoomsInQuotaClosingBalance,
	|	RoomQuotaSalesBalanceAndTurnovers.BedsInQuotaClosingBalance,
	|	RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance,
	|	RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(&qDateFrom, &qBoundaryTo, 
	|	                                                        DAY, 
	|	                                                        RegisterRecordsAndPeriodBoundaries, 
	|	                                                        RoomQuota = &qRoomQuota AND 
	|	                                                        Hotel = &qHotel AND 
	|	                                                        RoomType = &qRoomType" +
																?((RoomQuota.IsQuotaForRooms And ValueIsFilled(Room)), " AND Room = &qRoom", "") + "
	|) AS RoomQuotaSalesBalanceAndTurnovers
	|WHERE
	|	BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) < &qDateTo
	|) AS RoomQuotaSales
	|
	|GROUP BY
	|	RoomQuotaSales.Hotel,
	|	RoomQuotaSales.RoomQuota,
	|	RoomQuotaSales.RoomType" + ?((RoomQuota.IsQuotaForRooms And ValueIsFilled(Room)), ", RoomQuotaSales.Room", "");
	vQry.SetParameter("qRoomQuota", RoomQuota);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRoomType", RoomType);
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qBoundaryTo", New Boundary(DateTo, BoundaryType.Excluding));
	vQry.SetParameter("qDateTo", BegOfDay(DateTo));
	vQryTab = vQry.Execute().Unload();
	If vQryTab.Count() = 1 Then
		vQryRow = vQryTab.Get(0);
		If vQryRow.RoomsInQuota < 0 Or vQryRow.BedsInQuota < 0 Then
			Raise NStr("en='Not enough rooms in the allotment!';ru='Невозможно снять запрошенное кол-во номеров, т.к. квота будет выведена в минус!';de='Die Buchung der angegebenen Anzahl von Zimmern ist nicht möglich, da die Quote einen negativen Wert erreichen wird!'");
		EndIf;
	EndIf;
EndProcedure // CheckNegativeRoomQuotaBalances

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
IsInFileMode = False;

#EndRegion
