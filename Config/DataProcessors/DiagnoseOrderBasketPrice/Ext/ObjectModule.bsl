#Region Public

// -----------------------------------------------------------------------------
// Diagnoses why GetOrderBasketPrice / cart sum may be zero.
// Parameters are taken from object attributes.
// Returns ValueTable: StepNumber, StepCode, Status, Message, Details
// Status: OK | FAIL | WARN | INFO
// -----------------------------------------------------------------------------
Function pmDiagnose() Export
	vSteps = NewDiagnosticStepsTable();
	
	If Not ValueIsFilled(Hotel) Then
		AddStep(vSteps, "INPUT", "FAIL",
			NStr("en='Hotel is empty'; ru='Не заполнена гостиница'; de='Hotel ist leer'"),
			"");
		Return vSteps;
	EndIf;
	If Not ValueIsFilled(RoomRate) Then
		AddStep(vSteps, "INPUT", "FAIL",
			NStr("en='Room rate is empty'; ru='Не заполнен тариф'; de='Tarif ist leer'"),
			"");
		Return vSteps;
	EndIf;
	If Not ValueIsFilled(RoomType) And ValueIsFilled(Room) Then
		RoomType = Room.RoomType;
	EndIf;
	If Not ValueIsFilled(RoomType) Then
		AddStep(vSteps, "INPUT", "FAIL",
			NStr("en='Room type is empty'; ru='Не заполнен тип номера'; de='Zimmertyp ist leer'"),
			"");
		Return vSteps;
	EndIf;
	If Not ValueIsFilled(CheckInDate) Or Not ValueIsFilled(CheckOutDate) Then
		AddStep(vSteps, "INPUT", "FAIL",
			NStr("en='Check-in / check-out dates are empty'; ru='Не заполнены даты заезда/выезда'; de='An-/Abreisedaten sind leer'"),
			"");
		Return vSteps;
	EndIf;
	
	vAdults = ?(Adults = 0, 1, Adults);
	vKids = Kids;
	vGuestsQuantity = vAdults + vKids;
	
	vCheckInDate = CheckInDate;
	vCheckOutDate = CheckOutDate;
	NormalizeStayDates(vCheckInDate, vCheckOutDate);
	
	AddStep(vSteps, "INPUT", "OK",
		NStr("en='Input parameters'; ru='Входные параметры'; de='Eingabeparameter'"),
		NStr("en='Hotel='; ru='Гостиница='; de='Hotel='") + String(Hotel) + "; " +
		NStr("en='Rate='; ru='Тариф='; de='Tarif='") + String(RoomRate) + "; " +
		NStr("en='RoomType='; ru='ТипНомера='; de='Zimmertyp='") + String(RoomType) + "; " +
		Format(vCheckInDate, "DF=dd.MM.yyyy HH:mm") + " - " + Format(vCheckOutDate, "DF=dd.MM.yyyy HH:mm") + "; " +
		NStr("en='Guests='; ru='Гости='; de='Gäste='") + Format(vAdults, "NG=") + "/" + Format(vKids, "NG="));
	
	// 1. Capacity
	vRoomTypes = cmGetRoomTypesByGuestQuantity(vGuestsQuantity, Catalogs.RoomTypes.EmptyRef(), Hotel);
	vCapacityRow = vRoomTypes.Find(RoomType, "RoomType");
	If vCapacityRow = Undefined Then
		AddStep(vSteps, "CAPACITY", "FAIL",
			NStr("en='Room type cannot accommodate selected guests (NumberOfPersonsPerRoom)'; ru='Тип номера не вмещает выбранное число гостей (NumberOfPersonsPerRoom)'; de='Zimmertyp fasst die Gästezahl nicht'"),
			NStr("en='Required guests='; ru='Нужно гостей='; de='Benötigte Gäste='") + Format(vGuestsQuantity, "NG=") + "; " +
			NStr("en='RoomType.NumberOfPersonsPerRoom='; ru='ТипНомера.NumberOfPersonsPerRoom='; de='NumberOfPersonsPerRoom='") +
			Format(RoomType.NumberOfPersonsPerRoom, "NG="));
		Return vSteps;
	Else
		AddStep(vSteps, "CAPACITY", "OK",
			NStr("en='Room type capacity is OK'; ru='Вместимость типа номера OK'; de='Kapazität OK'"),
			NStr("en='NumberOfPersonsPerRoom='; ru='NumberOfPersonsPerRoom='; de='NumberOfPersonsPerRoom='") +
			Format(RoomType.NumberOfPersonsPerRoom, "NG="));
	EndIf;
	
	// 2. Calendar
	If Not ValueIsFilled(RoomRate.Calendar) Then
		AddStep(vSteps, "CALENDAR", "FAIL",
			NStr("en='Room rate has empty Calendar'; ru='У тарифа не заполнен календарь'; de='Tarif hat keinen Kalender'"),
			"");
	Else
		vCalendarDays = Catalogs.Calendars.pmGetDays(RoomRate.Calendar, vCheckInDate, vCheckOutDate, vCheckInDate, vCheckOutDate, RoomType, CurrentSessionDate());
		If vCalendarDays.Count() = 0 Then
			AddStep(vSteps, "CALENDAR", "FAIL",
				NStr("en='No calendar day types for stay dates'; ru='Нет типов дней календаря на даты проживания'; de='Keine Kalendertagestypen für den Zeitraum'"),
				NStr("en='Calendar='; ru='Календарь='; de='Kalender='") + String(RoomRate.Calendar));
		Else
			vDayTypesList = "";
			For Each vCalendarDaysRow In vCalendarDays Do
				vDayTypesList = vDayTypesList + Format(vCalendarDaysRow.Period, "DF=dd.MM.yyyy") + "=" + String(vCalendarDaysRow.CalendarDayType) + "; ";
			EndDo;
			AddStep(vSteps, "CALENDAR", "OK",
				NStr("en='Calendar day types found'; ru='Типы дней календаря найдены'; de='Kalendertagestypen gefunden'"),
				vDayTypesList);
		EndIf;
	EndIf;
	
	// 3. Active SetRoomRatePrices
	vActiveOrders = cmGetActiveSetRoomRatePrices(RoomRate, CurrentSessionDate(), vCheckInDate, vCheckOutDate, , Hotel, RoomType);
	If vActiveOrders.Count() = 0 Then
		AddStep(vSteps, "ACTIVE_ORDERS", "FAIL",
			NStr("en='No active SetRoomRatePrices for rate/calendar day types/hotel'; ru='Нет активного документа установки цен тарифа для типов дней/гостиницы'; de='Kein aktives SetRoomRatePrices'"),
			"");
	Else
		vOrdersInfo = "";
		For Each vActiveOrdersRow In vActiveOrders Do
			vOrdersInfo = vOrdersInfo + String(vActiveOrdersRow.CalendarDayType) + " -> " + String(vActiveOrdersRow.SetRoomRatePrices) + "; ";
		EndDo;
		AddStep(vSteps, "ACTIVE_ORDERS", "OK",
			NStr("en='Active SetRoomRatePrices found'; ru='Активные установки цен найдены'; de='Aktive Preisdokumente gefunden'"),
			vOrdersInfo);
	EndIf;
	
	// 4. Accommodation templates / types
	vAgeArray = New Array;
	vKidsAges = GetKidsAgesArray();
	For Each vAge In vKidsAges Do
		vAgeArray.Add(vAge);
	EndDo;
	
	vAccTypesWithAgeList = cmGetAvailableAccommodationTypesWithKidsAges(vAdults, vKids, vAgeArray, "", Hotel, RoomType, , False, Not IsForFolioSplit);
	If vAccTypesWithAgeList.Count() = 0 Then
		AddStep(vSteps, "ACC_TEMPLATE", "FAIL",
			NStr("en='No accommodation template/types for guests composition'; ru='Нет шаблона/видов размещения под состав гостей'; de='Keine Unterkunftsvorlage für Gästezusammensetzung'"),
			NStr("en='Adults/Kids='; ru='Взрослые/Дети='; de='Erwachsene/Kinder='") + Format(vAdults, "NG=") + "/" + Format(vKids, "NG="));
		Return vSteps;
	Else
		vAccInfo = "";
		For Each vAccRow In vAccTypesWithAgeList Do
			vAccInfo = vAccInfo + String(vAccRow.AccTemplate) + " / " + String(vAccRow.AccommodationType) + "; ";
		EndDo;
		AddStep(vSteps, "ACC_TEMPLATE", "OK",
			NStr("en='Accommodation templates found'; ru='Шаблоны размещения найдены'; de='Unterkunftsvorlagen gefunden'"),
			vAccInfo);
	EndIf;
	
	// 5. RoomRatePrices rows for each accommodation type from first template
	vFirstTemplate = vAccTypesWithAgeList.Get(0).AccTemplate;
	If Not ValueIsFilled(vFirstTemplate) Then
		AddStep(vSteps, "ACC_TEMPLATE", "WARN",
			NStr("en='Accommodation type found, but AccommodationTemplate is empty'; ru='Вид размещения найден, но шаблон размещения пустой'; de='Unterkunftstyp gefunden, Vorlage aber leer'"),
			NStr("en='With empty template and RateChargeDirection=MergeToTheMainRoomGuest calculation may skip packages / change price path'; ru='При пустом шаблоне и направлении начисления «на основного гостя» расчёт может идти другим путём'; de='Leere Vorlage kann Berechnungspfad ändern'"));
	EndIf;
	vPricesFound = False;
	vExactTagFound = False;
	vPricesDetails = "";
	vMissingPrices = "";
	vPriceRowsDump = "";
	For Each vAccRow In vAccTypesWithAgeList Do
		If vAccRow.AccTemplate <> vFirstTemplate And ValueIsFilled(vFirstTemplate) Then
			Break;
		EndIf;
		vPriceInfo = GetMatchingRoomRatePricesInfo(vAccRow.AccommodationType, vActiveOrders);
		If vPriceInfo.TotalCount > 0 Then
			vPricesFound = True;
			vPricesDetails = vPricesDetails + String(vAccRow.AccommodationType) + "=" + Format(vPriceInfo.TotalCount, "NG=") +
				"(tagMatch=" + Format(vPriceInfo.ExactPriceTagCount, "NG=") + "); ";
			If vPriceInfo.ExactPriceTagCount > 0 Then
				vExactTagFound = True;
			EndIf;
			vPriceRowsDump = vPriceRowsDump + vPriceInfo.RowsInfo;
		Else
			vMissingPrices = vMissingPrices + String(vAccRow.AccommodationType) + "; ";
		EndIf;
	EndDo;
	If Not vPricesFound Then
		AddStep(vSteps, "ROOM_RATE_PRICES", "FAIL",
			NStr("en='No RoomRatePrices rows for room type + accommodation types'; ru='Нет строк RoomRatePrices для типа номера + видов размещения'; de='Keine RoomRatePrices-Zeilen'"),
			NStr("en='Missing accommodation types: '; ru='Нет цен для видов: '; de='Fehlende Typen: '") + vMissingPrices +
			NStr("en=' (empty AccommodationType in prices is also accepted)'; ru=' (пустой вид в ценах тоже подходит)'; de=' (leerer Typ in Preisen ist auch OK)'"));
	ElsIf Not vExactTagFound Then
		AddStep(vSteps, "ROOM_RATE_PRICES", "FAIL",
			NStr("en='RoomRatePrices exist, but PriceTag does not match active RoomRates order'; ru='RoomRatePrices есть, но PriceTag не совпадает с активным документом в RoomRates'; de='RoomRatePrices vorhanden, PriceTag stimmt nicht'"),
			NStr("en='Found: '; ru='Найдено: '; de='Gefunden: '") + vPricesDetails + " " + vPriceRowsDump +
			NStr("en=' Fix: in SetRoomRatePrices rows PriceTag must equal PriceTag from register RoomRates for the calendar day type'; ru=' Исправление: в строках установки цен PriceTag должен совпадать с PriceTag в регистре RoomRates для типа дня'; de=' PriceTag angleichen'"));
	Else
		vStatus = ?(IsBlankString(vMissingPrices), "OK", "WARN");
		AddStep(vSteps, "ROOM_RATE_PRICES", vStatus,
			NStr("en='RoomRatePrices rows found'; ru='Строки RoomRatePrices найдены'; de='RoomRatePrices gefunden'"),
			NStr("en='Found: '; ru='Найдено: '; de='Gefunden: '") + vPricesDetails +
			?(IsBlankString(vMissingPrices), "", NStr("en='; without prices: '; ru='; без цен: '; de='; ohne Preise: '") + vMissingPrices) +
			" " + vPriceRowsDump);
	EndIf;
	
	// 6. Probe calculation like GetOrderBasketPrice / cmGetRoomTypeBalancesTable
	vCustomer = Undefined;
	vContract = Undefined;
	If ValueIsFilled(GuestGroup) Then
		vCustomer = GuestGroup.Customer;
		vContract = GuestGroup.Contract;
	EndIf;
	
	vAccommodationTemplate = Undefined;
	vProbeResObj = Documents.Reservation.CreateDocument();
	vProbeResObj.Hotel = Hotel;
	vProbeResObj.pmFillAttributesWithDefaultValues(True);
	vProbeResObj.ClientType = ClientType;
	vProbeResObj.ServicePackage = ServicePackage;
	
	vRoomTypeBalances = Undefined;
	Try
		vRoomTypeBalances = cmGetRoomTypeBalancesTable(vRoomTypes, False, Hotel, vCheckInDate, vCheckOutDate, ClientType, vCustomer, vContract, DiscountType, , , , RoomType, RoomRate, , vAdults, vKids, vAgeArray, vProbeResObj, IsForFolioSplit, ServicePackage, vAccommodationTemplate);
	Except
		AddStep(vSteps, "BALANCES", "FAIL",
			NStr("en='Error in cmGetRoomTypeBalancesTable'; ru='Ошибка cmGetRoomTypeBalancesTable'; de='Fehler in cmGetRoomTypeBalancesTable'"),
			ErrorDescription());
		CleanupProbeReservation(vProbeResObj);
		Return vSteps;
	EndTry;
	
	If vRoomTypeBalances = Undefined Then
		AddStep(vSteps, "BALANCES", "FAIL",
			NStr("en='cmGetRoomTypeBalancesTable returned Undefined (usually capacity mismatch)'; ru='cmGetRoomTypeBalancesTable вернул Undefined (обычно несоответствие вместимости)'; de='cmGetRoomTypeBalancesTable gab Undefined zurück'"),
			"");
		CleanupProbeReservation(vProbeResObj);
		Return vSteps;
	EndIf;
	
	vCurRoomTypeAccTypes = vRoomTypeBalances.FindRows(New Structure("RoomType", RoomType));
	If vCurRoomTypeAccTypes.Count() = 0 Then
		vCurRoomTypeAccTypes = vRoomTypeBalances.FindRows(New Structure("RoomType", Catalogs.RoomTypes.EmptyRef()));
	EndIf;
	
	vAmount = 0;
	vCurrency = Catalogs.Currencies.EmptyRef();
	vBalancesInfo = "";
	For Each vBalancesRow In vCurRoomTypeAccTypes Do
		vAmount = vAmount + vBalancesRow.Amount;
		vCurrency = vBalancesRow.Currency;
		vBalancesInfo = vBalancesInfo + String(vBalancesRow.AccommodationType) + "=" + Format(vBalancesRow.Amount, "NG=0; NDS=.") + "; ";
	EndDo;
	
	If vCurRoomTypeAccTypes.Count() = 0 Then
		AddStep(vSteps, "BALANCES", "FAIL",
			NStr("en='No balance/price rows for selected room type after calculation'; ru='После расчёта нет строк цены по выбранному типу номера'; de='Keine Preiszeilen nach Berechnung'"),
			NStr("en='Balances rows total='; ru='Всего строк balances='; de='Balances gesamt='") + Format(vRoomTypeBalances.Count(), "NG="));
	ElsIf vAmount = 0 Then
		AddStep(vSteps, "BALANCES", "FAIL",
			NStr("en='Calculated Amount = 0 (services empty or zero price)'; ru='Рассчитанная сумма = 0 (нет услуг или нулевая цена)'; de='Berechneter Betrag = 0'"),
			vBalancesInfo);
		
		// Deep dive: probe reservation services for first accommodation type
		DiagnoseProbeServices(vSteps, vCheckInDate, vCheckOutDate, vAccTypesWithAgeList.Get(0).AccommodationType, vFirstTemplate);
	Else
		AddStep(vSteps, "RESULT", "OK",
			NStr("en='Price should fill in cart'; ru='Цена должна подставиться в корзину'; de='Preis sollte im Warenkorb erscheinen'"),
			NStr("en='Amount='; ru='Сумма='; de='Betrag='") + Format(vAmount, "NG=0; NDS=.") + " " + String(vCurrency) +
			"; " + NStr("en='Template='; ru='Шаблон='; de='Vorlage='") + String(vAccommodationTemplate) +
			"; " + vBalancesInfo);
	EndIf;
	
	CleanupProbeReservation(vProbeResObj);
	
	// 7. Optional daily prices cache (used by some map views, not GetOrderBasketPrice itself)
	If ValueIsFilled(Hotel) Then
		If Not Hotel.UseRoomRateDailyPrices Then
			AddStep(vSteps, "DAILY_CACHE", "INFO",
				NStr("en='Hotel.UseRoomRateDailyPrices is off (not used by GetOrderBasketPrice, but used by some map price labels)'; ru='У гостиницы выключен UseRoomRateDailyPrices (GetOrderBasketPrice не использует, но подписи цен на части карт — да)'; de='UseRoomRateDailyPrices ist aus'"),
				"");
		Else
			vRoomRatesList = New ValueList();
			vRoomRatesList.Add(RoomRate);
			If cmRoomRatePricesCacheIsFilled(Hotel, vRoomRatesList, ClientType, vCheckInDate, vCheckOutDate) Then
				AddStep(vSteps, "DAILY_CACHE", "OK",
					NStr("en='RoomRateDailyPrices cache is filled for period'; ru='Кэш RoomRateDailyPrices заполнен на период'; de='RoomRateDailyPrices-Cache ist gefüllt'"),
					"");
			Else
				AddStep(vSteps, "DAILY_CACHE", "WARN",
					NStr("en='RoomRateDailyPrices cache is NOT filled for period'; ru='Кэш RoomRateDailyPrices НЕ заполнен на период'; de='RoomRateDailyPrices-Cache ist NICHT gefüllt'"),
					NStr("en='Fill cache if map labels show N/A'; ru='Заполните кэш, если на карте показывается N/A'; de='Cache füllen, wenn Karte N/A zeigt'"));
			EndIf;
		EndIf;
	EndIf;
	
	Return vSteps;
EndFunction // pmDiagnose

#EndRegion

#Region Private

Function NewDiagnosticStepsTable()
	vSteps = New ValueTable();
	vSteps.Columns.Add("StepNumber", New TypeDescription("Number", , , New NumberQualifiers(5, 0)));
	vSteps.Columns.Add("StepCode", New TypeDescription("String", , New StringQualifiers(50)));
	vSteps.Columns.Add("Status", New TypeDescription("String", , New StringQualifiers(10)));
	vSteps.Columns.Add("Message", New TypeDescription("String", , New StringQualifiers(500)));
	vSteps.Columns.Add("Details", New TypeDescription("String", , New StringQualifiers(2000)));
	Return vSteps;
EndFunction

Procedure AddStep(pSteps, pStepCode, pStatus, pMessage, pDetails)
	vRow = pSteps.Add();
	vRow.StepNumber = pSteps.Count();
	vRow.StepCode = pStepCode;
	vRow.Status = pStatus;
	vRow.Message = pMessage;
	vRow.Details = pDetails;
EndProcedure

Procedure NormalizeStayDates(rCheckInDate, rCheckOutDate)
	If ValueIsFilled(RoomRate) And RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
		vCheckInTime = 9 * 3600;
		vCheckOutTime = 22 * 3600;
		If ValueIsFilled(RoomRate.DefaultCheckInTime) Or ValueIsFilled(RoomRate.DefaultCheckOutTime) Then
			vCheckInTime = RoomRate.DefaultCheckInTime - BegOfDay(RoomRate.DefaultCheckInTime);
		Else
			vCheckInTime = RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour);
		EndIf;
		vCheckOutTime = RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour);
		If ValueIsFilled(RoomRate.DefaultCheckOutTime) Then
			vCheckOutTime = RoomRate.DefaultCheckOutTime - BegOfDay(RoomRate.DefaultCheckOutTime);
		EndIf;
		If rCheckInDate = BegOfDay(rCheckInDate) Then
			rCheckInDate = cm1SecondShift(BegOfDay(rCheckInDate) + vCheckInTime);
		EndIf;
		If rCheckOutDate = BegOfDay(rCheckOutDate) Or rCheckOutDate = EndOfDay(BegOfDay(rCheckOutDate)) Then
			rCheckOutDate = cm0SecondShift(BegOfDay(rCheckOutDate) + vCheckOutTime);
		EndIf;
		If BegOfDay(rCheckOutDate) <= BegOfDay(rCheckInDate) Then
			rCheckOutDate = rCheckOutDate + 24 * 3600;
		EndIf;
	Else
		If rCheckInDate = BegOfDay(rCheckInDate) Then
			rCheckInDate = cm1SecondShift(rCheckInDate);
		EndIf;
		If rCheckOutDate = BegOfDay(rCheckOutDate) Then
			rCheckOutDate = cm0SecondShift(rCheckOutDate);
		EndIf;
	EndIf;
EndProcedure

Function GetKidsAgesArray()
	vAges = New Array;
	If Kids <= 0 Then
		Return vAges;
	EndIf;
	vAges.Add(KidAge1);
	If Kids >= 2 Then
		vAges.Add(KidAge2);
	EndIf;
	If Kids >= 3 Then
		vAges.Add(KidAge3);
	EndIf;
	If Kids >= 4 Then
		vAges.Add(KidAge4);
	EndIf;
	Return vAges;
EndFunction

Function CountMatchingRoomRatePrices(pAccommodationType, pActiveOrders)
	Return GetMatchingRoomRatePricesInfo(pAccommodationType, pActiveOrders).TotalCount;
EndFunction

Function GetMatchingRoomRatePricesInfo(pAccommodationType, pActiveOrders)
	vResult = New Structure("TotalCount, ExactPriceTagCount, RowsInfo", 0, 0, "");
	If pActiveOrders = Undefined Or pActiveOrders.Count() = 0 Then
		Return vResult;
	EndIf;
	
	vSetDocs = New ValueList();
	vDayTypes = New ValueList();
	vPriceTags = New ValueList();
	For Each vOrderRow In pActiveOrders Do
		If ValueIsFilled(vOrderRow.SetRoomRatePrices) And vSetDocs.FindByValue(vOrderRow.SetRoomRatePrices) = Undefined Then
			vSetDocs.Add(vOrderRow.SetRoomRatePrices);
		EndIf;
		If ValueIsFilled(vOrderRow.CalendarDayType) And vDayTypes.FindByValue(vOrderRow.CalendarDayType) = Undefined Then
			vDayTypes.Add(vOrderRow.CalendarDayType);
		EndIf;
		If vPriceTags.FindByValue(vOrderRow.PriceTag) = Undefined Then
			vPriceTags.Add(vOrderRow.PriceTag);
		EndIf;
	EndDo;
	
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	RoomRatePrices.CalendarDayType AS CalendarDayType,
	|	RoomRatePrices.PriceTag AS PriceTag,
	|	RoomRatePrices.Hotel AS Hotel,
	|	RoomRatePrices.RoomType AS RoomType,
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.ClientType AS ClientType,
	|	RoomRatePrices.Service AS Service,
	|	RoomRatePrices.Price AS Price,
	|	CASE
	|		WHEN RoomRatePrices.PriceTag IN (&qPriceTags)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS PriceTagMatchesOrder
	|FROM
	|	InformationRegister.RoomRatePrices AS RoomRatePrices
	|WHERE
	|	RoomRatePrices.RoomRate = &qRoomRate
	|	AND RoomRatePrices.SetRoomRatePrices IN (&qSetDocs)
	|	AND RoomRatePrices.CalendarDayType IN (&qDayTypes)
	|	AND (RoomRatePrices.Hotel = &qHotel
	|		OR RoomRatePrices.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND (RoomRatePrices.RoomType = &qRoomType
	|		OR RoomRatePrices.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
	|	AND (RoomRatePrices.AccommodationType = &qAccommodationType
	|		OR RoomRatePrices.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
	|	AND (RoomRatePrices.ClientType = &qClientType
	|		OR RoomRatePrices.ClientType = VALUE(Catalog.ClientTypes.EmptyRef))
	|	AND RoomRatePrices.IsRoomRevenue = TRUE
	|	AND RoomRatePrices.IsInPrice = TRUE
	|	AND RoomRatePrices.Price <> 0";
	vQry.SetParameter("qRoomRate", ?(ValueIsFilled(RoomRate.BasedOnRoomRate), RoomRate.BasedOnRoomRate, RoomRate));
	vQry.SetParameter("qSetDocs", vSetDocs);
	vQry.SetParameter("qDayTypes", vDayTypes);
	vQry.SetParameter("qPriceTags", vPriceTags);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRoomType", RoomType);
	vQry.SetParameter("qAccommodationType", pAccommodationType);
	vQry.SetParameter("qClientType", ClientType);
	vTable = vQry.Execute().Unload();
	vResult.TotalCount = vTable.Count();
	vExact = 0;
	vInfo = "";
	For Each vRow In vTable Do
		If vRow.PriceTagMatchesOrder Then
			vExact = vExact + 1;
		EndIf;
		vInfo = vInfo + String(vRow.Service) + " Price=" + Format(vRow.Price, "NG=0; NDS=.") +
			" DayType=" + String(vRow.CalendarDayType) +
			" PriceTag=" + ?(ValueIsFilled(vRow.PriceTag), String(vRow.PriceTag), "<empty>") +
			" AccType=" + ?(ValueIsFilled(vRow.AccommodationType), String(vRow.AccommodationType), "<empty>") +
			" RoomType=" + ?(ValueIsFilled(vRow.RoomType), String(vRow.RoomType), "<empty>") +
			" MatchTag=" + ?(vRow.PriceTagMatchesOrder, "Y", "N") + "; ";
	EndDo;
	vResult.ExactPriceTagCount = vExact;
	vResult.RowsInfo = vInfo;
	Return vResult;
EndFunction

Procedure DiagnoseProbeServices(pSteps, pCheckInDate, pCheckOutDate, pAccommodationType, pAccommodationTemplate)
	vProbe = Documents.Reservation.CreateDocument();
	vProbe.Hotel = Hotel;
	vProbe.pmFillAttributesWithDefaultValues(True);
	vProbe.RoomRate = RoomRate;
	If ValueIsFilled(RoomRate) Then
		vProbe.RoomRateType = RoomRate.RoomRateType;
	EndIf;
	vProbe.ClientType = ClientType;
	vProbe.ServicePackage = ServicePackage;
	vProbe.RoomType = RoomType;
	vProbe.AccommodationType = pAccommodationType;
	vProbe.AccommodationTemplate = pAccommodationTemplate;
	vProbe.CheckInDate = pCheckInDate;
	vProbe.CheckOutDate = pCheckOutDate;
	vProbe.Duration = vProbe.pmCalculateDuration();
	If ValueIsFilled(DiscountType) And ValueIsFilled(RoomRate) And Not RoomRate.NoDiscounts Then
		vProbe.DiscountType = DiscountType;
		vProbe.DiscountServiceGroup = DiscountType.DiscountServiceGroup;
		vProbe.Discount = DiscountType.GetObject().pmGetDiscount(vProbe.CheckInDate, , Hotel);
	EndIf;
	
	AddStep(pSteps, "PROBE_PARAMS", "INFO",
		NStr("en='Probe reservation parameters'; ru='Параметры пробной брони'; de='Probe-Reservierungsparameter'"),
		NStr("en='CheckIn='; ru='Заезд='; de='Anreise='") + Format(vProbe.CheckInDate, "DF=dd.MM.yyyy HH:mm:ss") +
		"; " + NStr("en='CheckOut='; ru='Выезд='; de='Abreise='") + Format(vProbe.CheckOutDate, "DF=dd.MM.yyyy HH:mm:ss") +
		"; " + NStr("en='Duration='; ru='Длит.='; de='Dauer='") + Format(vProbe.Duration, "NG=") +
		"; " + NStr("en='Status='; ru='Статус='; de='Status='") + String(vProbe.ReservationStatus) +
		"; " + NStr("en='RateChargeDirection='; ru='НаправлениеНачисления='; de='RateChargeDirection='") +
		?(ValueIsFilled(RoomRate), String(RoomRate.RateChargeDirection), "") +
		"; " + NStr("en='Template filled='; ru='Шаблон заполнен='; de='Vorlage gefüllt='") +
		?(ValueIsFilled(pAccommodationTemplate), "Y", "N"));
	
	// Direct prices API used by pmCalculateServices
	vPriceCalculationDate = CurrentSessionDate();
	If vPriceCalculationDate = BegOfDay(vPriceCalculationDate) Then
		vPriceCalculationDate = vPriceCalculationDate + 1;
	EndIf;
	vBasePricesCount = 0;
	vBasePricesInfo = "";
	Try
		vBasePrices = RoomRate.GetObject().pmGetRoomRatePrices(pCheckInDate, vPriceCalculationDate, ClientType, RoomType, pAccommodationType, , , pCheckInDate, pCheckOutDate, , , , , pAccommodationTemplate, IsForFolioSplit);
		vBasePricesCount = vBasePrices.Count();
		For Each vPriceRow In vBasePrices Do
			If vPriceRow.IsRoomRevenue Then
				vBasePricesInfo = vBasePricesInfo + String(vPriceRow.Service) + " Price=" + Format(vPriceRow.Price, "NG=0; NDS=.") +
					" DayType=" + String(vPriceRow.CalendarDayType) +
					" AccType=" + String(vPriceRow.AccommodationType) +
					" PriceTag=" + String(vPriceRow.PriceTag) + "; ";
			EndIf;
		EndDo;
	Except
		AddStep(pSteps, "GET_PRICES", "FAIL",
			NStr("en='pmGetRoomRatePrices error'; ru='Ошибка pmGetRoomRatePrices'; de='Fehler pmGetRoomRatePrices'"),
			ErrorDescription());
		CleanupProbeReservation(vProbe);
		Return;
	EndTry;
	
	If vBasePricesCount = 0 Then
		AddStep(pSteps, "GET_PRICES", "FAIL",
			NStr("en='pmGetRoomRatePrices returned 0 rows — calculation has nothing to charge'; ru='pmGetRoomRatePrices вернул 0 строк — рассчитывать нечего'; de='pmGetRoomRatePrices lieferte 0 Zeilen'"),
			NStr("en='Usually PriceTag in RoomRatePrices does not match active RoomRates order, or AccommodationType/Hotel/RoomType filter excludes rows'; ru='Чаще всего PriceTag в RoomRatePrices не совпадает с активным RoomRates, либо отбор по виду/отелю/типу номера отсекает строки'; de='Meist stimmt PriceTag nicht mit aktivem RoomRates überein'"));
	Else
		AddStep(pSteps, "GET_PRICES", "OK",
			NStr("en='pmGetRoomRatePrices returned rows'; ru='pmGetRoomRatePrices вернул строки'; de='pmGetRoomRatePrices lieferte Zeilen'"),
			NStr("en='Count='; ru='Кол-во='; de='Anzahl='") + Format(vBasePricesCount, "NG=") + "; " + vBasePricesInfo);
	EndIf;
	
	Try
		vProbe.pmCalculateResources(True);
		vProbe.pmCalculateServices(, , , , , IsForFolioSplit, True);
	Except
		AddStep(pSteps, "SERVICES", "FAIL",
			NStr("en='pmCalculateServices raised an error'; ru='Ошибка pmCalculateServices'; de='Fehler in pmCalculateServices'"),
			ErrorDescription());
		CleanupProbeReservation(vProbe);
		Return;
	EndTry;
	
	If vProbe.Services.Count() = 0 Then
		AddStep(pSteps, "SERVICES", "FAIL",
			NStr("en='pmCalculateServices returned empty Services table'; ru='pmCalculateServices вернул пустую таблицу Services'; de='pmCalculateServices lieferte leere Services'"),
			NStr("en='AccommodationType='; ru='ВидРазмещения='; de='Unterkunftstyp='") + String(pAccommodationType) + "; " +
			NStr("en='Template='; ru='Шаблон='; de='Vorlage='") + String(pAccommodationTemplate) + "; " +
			NStr("en='pmGetRoomRatePrices rows='; ru='Строк pmGetRoomRatePrices='; de='Zeilen pmGetRoomRatePrices='") + Format(vBasePricesCount, "NG="));
	Else
		vSrvInfo = "";
		vTotal = 0;
		For Each vSrv In vProbe.Services Do
			vTotal = vTotal + vSrv.Sum - vSrv.DiscountSum;
			If vSrv.IsRoomRevenue Then
				vSrvInfo = vSrvInfo + Format(vSrv.AccountingDate, "DF=dd.MM.yyyy") + " " + String(vSrv.Service) +
					" Price=" + Format(vSrv.Price, "NG=0; NDS=.") +
					" Sum=" + Format(vSrv.Sum, "NG=0; NDS=.") +
					" Qty=" + Format(vSrv.Quantity, "NG=0; NDS=.") +
					" DayType=" + String(vSrv.CalendarDayType) + "; ";
			EndIf;
		EndDo;
		If vTotal = 0 Then
			AddStep(pSteps, "SERVICES", "FAIL",
				NStr("en='Services exist but total sum is 0'; ru='Услуги есть, но итоговая сумма 0'; de='Leistungen vorhanden, Summe aber 0'"),
				vSrvInfo);
		Else
			AddStep(pSteps, "SERVICES", "OK",
				NStr("en='Probe services calculated'; ru='Пробные услуги рассчитаны'; de='Probe-Leistungen berechnet'"),
				NStr("en='Total='; ru='Итого='; de='Summe='") + Format(vTotal, "NG=0; NDS=.") + "; " + vSrvInfo);
		EndIf;
	EndIf;
	
	CleanupProbeReservation(vProbe);
EndProcedure

Procedure CleanupProbeReservation(pProbeResObj)
	If pProbeResObj = Undefined Then
		Return;
	EndIf;
	Try
		For Each vCRRow In pProbeResObj.ChargingRules Do
			If ValueIsFilled(vCRRow.ChargingFolio) Then
				vFolioObj = vCRRow.ChargingFolio.GetObject();
				If vFolioObj <> Undefined Then
					vFolioObj.Delete();
				EndIf;
			EndIf;
		EndDo;
	Except
	EndTry;
EndProcedure

#EndRegion
