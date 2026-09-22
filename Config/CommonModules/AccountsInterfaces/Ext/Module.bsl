
#Region Public

// -----------------------------------------------------------------------------
//  Recalculate amount from one currency to another.
//  Function allows to substitute currency to passed as input parameter by
//  another currency taken from the external system mappings table
//
// Parameters:
//  pSum						 - 	 - 
//  pCurrencyFrom				 - 	 - 
//  pCurrencyFromExchangeRate	 - 	 - 
//  pCurrencyTo					 - 	 - 
//  pCurrencyToExchangeRate		 - 	 - 
//  pExchangeRateDate			 - 	 - 
//  pHotel						 - 	 - 
//  pExternalSystemCode			 - 	 - 
// 
// Returns:
//  Number - Amount in currency to
//
Function cmExtConvertCurrencies(pSum, pCurrencyFrom, pCurrencyFromExchangeRate = 0, pCurrencyTo, pCurrencyToExchangeRate = 0, pExchangeRateDate, pHotel = Undefined, pExternalSystemCode = "") Export
	If Not IsBlankString(pExternalSystemCode) And ValueIsFilled(pCurrencyTo) Then
		vCurrencyTo = cmGetObjectRefByExternalSystemCode(pHotel, pExternalSystemCode, "Currencies", Format(pCurrencyTo.Code, "ND=3; NFD=0; NG="));
		If ValueIsFilled(vCurrencyTo) And vCurrencyTo <> pCurrencyTo Then
			Return Round(cmConvertCurrencies(pSum, pCurrencyFrom, pCurrencyFromExchangeRate, vCurrencyTo, 0, pExchangeRateDate, pHotel), 2);
		EndIf;
	EndIf;
	Return Round(cmConvertCurrencies(pSum, pCurrencyFrom, pCurrencyFromExchangeRate, pCurrencyTo, pCurrencyToExchangeRate, pExchangeRateDate, pHotel), 2);
EndFunction // cmExtConvertCurrencies

// -----------------------------------------------------------------------------
//  Calculates room rate service quantity for the given date.
//   Function allows service price and service description change
//
// Parameters:
//  pService					 - 	 - 
//  pQuantityCalculationRule	 - 	 - 
//  pAccountingDate				 - 	 - 
//  pDateFrom					 - 	 - 
//  pDateTo						 - 	 - 
//  pDocumentObj				 - 	 - 
//  pReservationObj				 - 	 - 
//  pIsCheckIn					 - 	 - 
//  pIsReservation				 - 	 - 
//  pIsBeforeRoomChange			 - 	 - 
//  pIsRoomChange				 - 	 - 
//  pIsCheckOut					 - 	 - 
//  pIsOneTimeChargeNecessary	 - 	 - 
//  pPrice						 - 	 - 
//  pCurrency					 - 	 - 
//  rRemarks					 - 	 - 
//  rIsDayUse					 - 	 - 
//  pMinQuantity				 - 	 - 
//  pAccommodationPeriods		 - 	 - 
//  pOccParams					 - Structure - is used to return rooms rented, guest days
// 
// Returns:
//  Number - Service day quantity
//
Function cmCalculateServiceQuantity(pService, pQuantityCalculationRule, pAccountingDate, 
                                    Val pDateFrom, Val pDateTo, 
                                    pDocumentObj = Undefined, pReservationObj = Undefined, 
                                    pIsCheckIn = True, pIsReservation = False, 
                                    pIsBeforeRoomChange = False, pIsRoomChange = False, pIsCheckOut = True, pIsOneTimeChargeNecessary = True, 
                                    pPrice = 0, pCurrency = Undefined, rRemarks = "", rIsDayUse = False, pMinQuantity = 0, pAccommodationPeriods = Undefined, 
                                    pOccParams = Undefined) Export
	// Common checks	
	If Not ValueIsFilled(pService) Then
		Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
		|CAUSE: Empty pService parameter value was passed to the function.
		|DESC: Mandatory parameter pService should be filled.';
		|ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
		|CAUSE: В функцию передано пустое значение параметра pSevice.
		|DESC: Обязательный параметр pService должен быть явно указан.';
		|de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
		|CAUSE: In die Funktion wurde ein leerer Wert des pService übertragen.
		|DESC: Das Pflichtparameter pService muss eindeutig angegeben sein.'"));
	EndIf;
	If Not ValueIsFilled(pAccountingDate) Then
		Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
		|CAUSE: Empty pAccountingDate parameter value was passed to the function.
		|DESC: Mandatory parameter pAccountingDate should be filled.';
		|ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
		|CAUSE: В функцию передано пустое значение параметра pAccountingDate.
		|DESC: Обязательный параметр pAccountingDate должен быть явно указан.';
		|de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
		|CAUSE: In die Funktion wurde ein leerer Wert des pAccountingDate übertragen.
		|DESC: Das Pflichtparameter pAccountingDate muss eindeutig angegeben sein.'"));
	EndIf;
	If pDateTo < pDateFrom Then
		Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
		|CAUSE: pDateTo parameter date time value is less then pDateFrom parameter value.
		|DESC: Reservation/Accommodation period end is earlier then period start.';
		|ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
		|CAUSE: Дата и время pDateTo меньше даты и времени pDateFrom.
		|DESC: У периода бронирования/проживания окончание периода раньше начала.';
		|de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
		|CAUSE: Datum und Zeit pDateTo liegen vor Datum und Zeit pDateFrom.
		|DESC: In dem Buchungs-/(Keine Vorschläge) liegt das Zeitraumende vor dem Zeitraumbeginn.'"));
	EndIf;
	// Init return parameters
	rRemarks = "";
	rIsDayUse = False;
	// Check quantity calculation rule
	If Not ValueIsFilled(pQuantityCalculationRule) Then
		Return 1;
	EndIf;
	// Retrieve all parameters
	vSrvPH = pQuantityCalculationRule.PeriodInHours;
	vSrvRHIsUsed = pQuantityCalculationRule.ReferenceHourIsUsed;
	vSrvRH = pQuantityCalculationRule.ReferenceHour;
	vSrvQCR = pQuantityCalculationRule.QuantityCalculationRuleType;
	vSrvECRR = pQuantityCalculationRule.EarlyCheckInRoundingRule;
	vSrvLCRR = pQuantityCalculationRule.CheckOutDelayRoundingRule;
	vSrvCRR = pQuantityCalculationRule.CheckInRoundingRule;
	vSrvMRH = pQuantityCalculationRule.RoomChangeAlwaysAtReferenceHourTime;
	// Calculate additional parameters
	vAD = BegOfDay(pAccountingDate);
	vDF = BegOfDay(pDateFrom);
	vDT = BegOfDay(pDateTo);
	// Check period length in hours
	vPL = (pDateTo - pDateFrom)/3600;
	If vPL <= pQuantityCalculationRule.RoomExaminationFreeOfChargeTime Then
		Return 0;
	ElsIf (pIsBeforeRoomChange Or pIsRoomChange) And vPL <= pQuantityCalculationRule.FreeOfChargeChangeRoomTime Then
		Return 0;
	ElsIf vPL <= pQuantityCalculationRule.ChargeByHoursTime Then
		If vAD = vDF Then
			If vSrvCRR = Enums.QuantityRoundingRules.Int Then
				vPL = Int(vPL);
			ElsIf vSrvCRR = Enums.QuantityRoundingRules.Round Then
				vPL = Round(vPL, 0);
			ElsIf vSrvCRR = Enums.QuantityRoundingRules.Full Then
				If Int(vPL) <> vPL Then
					vPL = Int(vPL) + 1;
				EndIf;
			EndIf;
			Return Round(vPL / 24, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
		ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.Accommodation Then
			Return 0;
		EndIf;
	ElsIf vPL <= pQuantityCalculationRule.ChargeByQuarterOfADayTime Then
		If vAD = vDF Then
			Return Round(6 / 24, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
		ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.Accommodation Then
			Return 0;
		EndIf;
	ElsIf vPL <= pQuantityCalculationRule.ChargeByHalfOfADayTime And vAD = vDF Then
		If vAD = vDF Then
			Return Round(12 / 24, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
		ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.Accommodation Then
			Return 0;
		EndIf;
	EndIf;
	// Split algorithms by quantity calculation rules
	If vSrvQCR = Enums.QuantityCalculationRuleTypes.Accommodation Then
		If Not vSrvRHIsUsed Then
			vSrvRH = '00010101' + (pDateFrom - BegOfDay(pDateFrom));
		EndIf;
		If vSrvPH <> 24 Then
			Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
			|CAUSE: Service period in hours is wrong for quantity calculation rule <Accommodation>.
			|DESC: Service period in hours should be equal 24 hours for quantity calculation rule <Accommodation>.';
			|ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
			|CAUSE: Не верно задана периодичность услуги для вида расчета <Проживание>.
			|DESC: У услуги, для которой количество рассчитывается по виду расчета <Проживание>, период должен быть равен 24 часам.';
			|de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
			|CAUSE: Falsche Eingabe der Regelmäßigkeit für die Abrechnungsart <Unterbringung>.
			|DESC: Bei einer Dienstleistung, für die die Quantität nach der Abrechnungsart <Unterbringung> berechnet wird, muss der Zeitraum 24 Stunden betragen.'"));
		EndIf;
		// Calculate day price if hotel product with fixed cost is choosen
		If pDocumentObj <> Undefined And ValueIsFilled(pDocumentObj.HotelProduct) And pPrice > 0 Then
			vProductSum = pDocumentObj.HotelProduct.Sum;
			If pDocumentObj.HotelProduct.FixProductCost And
				vProductSum > 0 Then
				If pDocumentObj.HotelProduct.FixProductPeriod Or pDocumentObj.HotelProduct.FixPlannedPeriod Then
					// Get duration from the product 
					vDuration = pDocumentObj.HotelProduct.Duration;
				Else
					// Get duration from the document
					If TypeOf(pDocumentObj) = Type("DocumentObject.Accommodation") And pDocumentObj.FixReservationConditions And pReservationObj <> Undefined Then
						vDuration = pReservationObj.Duration;
					Else
						vDuration = pDocumentObj.Duration;
					EndIf;
				EndIf;
				If vDuration > 0 Then
					vQ = 0;
					// Calculate effective day price
					vDayPrice = Int(vProductSum / vDuration);
					// Set last day price to the rest of the product cost
					vLastDayPrice = vProductSum - vDayPrice*(vDuration - 1);
					// Get check-out date based on duration
					vDT = vDF + (vDuration-1) * 24 * 3600;
					// Update current room rate price
					If vAD = vDT Then
						pPrice = vLastDayPrice;
						If ValueIsFilled(pDocumentObj.HotelProduct.Currency) Then
							pCurrency = pDocumentObj.HotelProduct.Currency;
						EndIf;
						vQ = 1;
						// Check for minimum quantity
						If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
							vQ = pMinQuantity;
						EndIf;
					ElsIf vAD < vDT Then
						pPrice = vDayPrice;
						If ValueIsFilled(pDocumentObj.HotelProduct.Currency) Then
							pCurrency = pDocumentObj.HotelProduct.Currency;
						EndIf;
						vQ = 1;
						// Check for minimum quantity
						If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
							vQ = pMinQuantity;
						EndIf;
					Else
						pPrice = 0;
						vQ = 0;
					EndIf;
					// Return
					Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
				EndIf;
			EndIf;
		EndIf;
		// Normal calculation
		vQ = 0;
		// Check if this is room change
		If vSrvMRH And pIsRoomChange Then
			// Move check-in date to the nearest next/previous reference hour
			vDateFrom = Date(Year(pDateFrom), Month(pDateFrom), Day(pDateFrom), Hour(vSrvRH), Minute(vSrvRH), Second(vSrvRH));
			If vDateFrom < pDateTo Then
				pDateFrom = vDateFrom;
				vDF = BegOfDay(pDateFrom);
			EndIf;
		EndIf;
		// Calculate 3 numbers: 
		vDFRH = Date(Year(pDateFrom), Month(pDateFrom), Day(pDateFrom), Hour(vSrvRH), Minute(vSrvRH), Second(vSrvRH));
		// 1. Early check in part if accounting date equals check in date
		If vAD = vDF And pIsCheckIn Then
			vSkipEarlyCheckIn = False;
			vIsOneDay = False;
			vTQ = (pDateTo - pDateFrom) / (24 * 3600);
			If vTQ <= 1 Then
				vIsOneDay = True;
			EndIf;
			If vIsOneDay Then
				If Not pQuantityCalculationRule.FirstDayStartsAtReferenceHourTime Then
					// No early check-in at all
					vSkipEarlyCheckIn = True;
				EndIf;
			EndIf;
			If Not vSkipEarlyCheckIn Then
				If pDateFrom < vDFRH Then
					vEQ = (vDFRH - pDateFrom)/3600;
					If vEQ <= pQuantityCalculationRule.FreeOfChargeEarlyCheckInTime Then
						vEQ = 0;
						vQ = vQ + Round(vEQ/24, 7);
					ElsIf vEQ <= pQuantityCalculationRule.ChargeByHoursEarlyCheckInTime Then
						If vSrvECRR = Enums.QuantityRoundingRules.Int Then
							vEQ = Int(vEQ);
						ElsIf vSrvECRR = Enums.QuantityRoundingRules.Round Then
							vEQ = Round(vEQ, 0);
						ElsIf vSrvECRR = Enums.QuantityRoundingRules.Full Then
							If Int(vEQ) <> vEQ Then
								vEQ = Int(vEQ) + 1;
							EndIf;
						EndIf;
						rRemarks = NStr("ru='Ранний заезд на " + Round(vEQ, 0) + " часов';en='Early check in for " + Round(vEQ, 0) + " hours';de='Early check in for " + Round(vEQ, 0) + " hours'");
						vQ = vQ + Round(vEQ / 24, 7);
						rIsDayUse = True;
					ElsIf vEQ <= pQuantityCalculationRule.ChargeByQuarterOfADayEarlyCheckInTime Then
						vEQ = 6;
						rRemarks = NStr("ru='Ранний заезд на " + vEQ + " часов';en='Early check in for " + vEQ + " hours';de='Early check in for " + vEQ + " hours'");
						vQ = vQ + Round(vEQ / 24, 7);
						rIsDayUse = True;
					ElsIf vEQ <= pQuantityCalculationRule.ChargeByHalfOfADayEarlyCheckInTime Then
						vEQ = 12;
						rRemarks = NStr("en='Early check in for half of a day';ru='Ранний заезд на полсуток';de='Um 12 Stunden frühere Anreise'");
						vQ = vQ + Round(vEQ / 24, 7);
						rIsDayUse = True;
					ElsIf pQuantityCalculationRule.Do1DayEarlyCheckInCharge Then
						vEQ = 24;
						vQ = vQ + Round(vEQ / 24, 7);
						rIsDayUse = True;
					EndIf;
				EndIf;
			EndIf;
			If vIsOneDay And vSrvRHIsUsed Then
				vHotel = pDocumentObj.Hotel;
				If ValueIsFilled(vHotel.AccountingDate) And ValueIsFilled(vHotel.CloseOfDayDefaultTime) Then
					If (pDateFrom - BegOfDay(pDateFrom)) < (vHotel.CloseOfDayDefaultTime - BegOfDay(vHotel.CloseOfDayDefaultTime)) Then
						pAccountingDate = pAccountingDate - 24 * 3600;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// 2. Main part (which is 1 or less actually)
		If vDF = vDT Then
			If vAD = vDF And Not pIsRoomChange Then
				vQ = vQ + 1;
			EndIf;
		Else
			If (vAD >= vDF) And (vAD < vDT) Then
				vQ = vQ + 1;
			EndIf;
		EndIf;
		// 3. Late check out part if accounting date equals check out date
		If vAD = vDT And (pIsCheckOut Or Not vSrvMRH) Then
			// Check should we add check out delay time to the quantity if guest took only 1 night
			vIsOneDay = False;
			vIsBetween1And2 = False;
			vTQ = (pDateTo - pDateFrom) / (3600 * 24);
			If vTQ <= 1 Then
				vIsOneDay = True;
			ElsIf vTQ < 1.5 Then
				vIsBetween1And2 = True;
			EndIf;
			vSkipDelayCalculation = False;
			If vIsOneDay And pIsCheckIn Then
				If Not pQuantityCalculationRule.FirstDayEndsAtReferenceHourTime Or 
					pQuantityCalculationRule.FirstDayEndsAtReferenceHourTime And 
					vAD = vDF And pDateFrom > (vDFRH - pQuantityCalculationRule.FreeOfChargeEarlyCheckInTime * 3600) Then
					// No late check out at all
					vSkipDelayCalculation = True;
				EndIf;
			EndIf;
			If Not vSkipDelayCalculation Then
				// Calculate base for delay time
				vDFRH = Date(Year(pDateFrom), Month(pDateFrom), Day(pDateFrom), Hour(vSrvRH), Minute(vSrvRH), Second(vSrvRH));
				vDTRH = Date(Year(pDateTo), Month(pDateTo), Day(pDateTo), Hour(vSrvRH), Minute(vSrvRH), Second(vSrvRH));
				If pQuantityCalculationRule.CalculateDelayFromCheckOutTimeForFirstDay And 
					vIsBetween1And2 And pIsCheckIn And pDateFrom > vDFRH Then
					vDTB = Date(Year(pDateTo), Month(pDateTo), Day(pDateTo), Hour(pDateFrom), Minute(pDateFrom), Second(pDateFrom));
				Else
					vDTB = vDTRH;
				EndIf;
				// Calculate delay time
				If pDateTo > vDTB Then
					vLQ = (pDateTo - vDTB) / 3600;
					If vLQ <= pQuantityCalculationRule.FreeOfChargeCheckOutDelayTime Then
						vLQ = 0;
						vQ = vQ + Round(vLQ / 24, 7);
					ElsIf vLQ <= pQuantityCalculationRule.ChargeByHoursCheckOutDelayTime Then
						If vSrvLCRR = Enums.QuantityRoundingRules.Int Then
							vLQ = Int(vLQ);
						ElsIf vSrvLCRR = Enums.QuantityRoundingRules.Round Then
							vLQ = Round(vLQ, 0);
						ElsIf vSrvLCRR = Enums.QuantityRoundingRules.Full Then
							If Int(vLQ) <> vLQ Then
								vLQ = Int(vLQ) + 1;
							EndIf;
						EndIf;
						rRemarks = NStr("ru='Задержка выезда на " + Round(vLQ, 0) + " часов';en='Late check out for " + Round(vLQ, 0) + " hours';de='Late check out for " + Round(vLQ, 0) + " hours'");
						vQ = vQ + Round(vLQ / 24, 7);
						rIsDayUse = True;
					ElsIf vLQ <= pQuantityCalculationRule.ChargeByQuarterOfADayCheckOutDelayTime Then
						vLQ = 6;
						rRemarks = NStr("ru='Задержка выезда на " + vLQ + " часов';en='Late check out for " + vLQ + " hours';de='Late check out for " + vLQ + " hours'");
						vQ = vQ + Round(vLQ / 24, 7);
						rIsDayUse = True;
					ElsIf vLQ <= pQuantityCalculationRule.ChargeByHalfOfADayCheckOutDelayTime Then
						vLQ = 12;
						rRemarks = NStr("en='Late check out for half a day';ru='Задержка выезда на полсуток';de='Abreiseverzögerung um 12 Stunden'");
						vQ = vQ + Round(vLQ/24, 7);
						rIsDayUse = True;
					ElsIf pQuantityCalculationRule.Do1DayCheckOutDelayCharge Then
						vLQ = 24;
						vQ = vQ + Round(vLQ / 24, 7);
						rIsDayUse = True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Check for minimum quantity
		If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
			vQ = pMinQuantity;
			If vQ >= 1 Then
				rRemarks = "";
			EndIf;
		EndIf;
		Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.LateCheckOut Then
		If Not vSrvRHIsUsed Then
			vSrvRH = '00010101' + (pDateFrom - BegOfDay(pDateFrom));
		EndIf;
		If vSrvPH = 0 Then
			Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
			|CAUSE: Service period in hours is not specified for quantity calculation rule <late check-out>.
			|DESC: Service period in hours should not be equal 0 hours for quantity calculation rule <Late check-out>.';
			|ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
			|CAUSE: Не задана периодичность услуги для вида расчета <Поздний выезд>.
			|DESC: У услуги, для которой количество рассчитывается по виду расчета <Поздний выезд>, период должен быть указан.';
			|de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
			|CAUSE: Die Regelmäßigkeit für die Abrechnungsart <Späte Abreise> ist nicht angegeben.
			|DESC: Bei einer Dienstleistung, für die die Quantität nach der Abrechnungsart <Unterbringung> berechnet wird, muss der Zeitraum angegeben sein.'"));
		EndIf;
		// Check if we should move check-in or check-out times to the reference hour
		If Not pIsCheckOut Then
			Return 0;
		EndIf;
		// Late check out part if accounting date equals check out date
		vQ = 0;
		If vAD = vDT Then
			// Check should we add check out delay time to the quantity if guest took only 1 night
			vIsOneDay = False;
			vIsBetween1And2 = False;
			vTQ = (pDateTo - pDateFrom) / (24 * 3600);
			If vTQ <= 1 Then
				vIsOneDay = True;
			ElsIf vTQ < 1.5 Then
				vIsBetween1And2 = True;
			EndIf;
			If vIsOneDay And pIsCheckIn Then
				vDFRH = Date(Year(pDateFrom), Month(pDateFrom), Day(pDateFrom), Hour(vSrvRH), Minute(vSrvRH), Second(vSrvRH));
				If Not pQuantityCalculationRule.FirstDayEndsAtReferenceHourTime Or 
					pQuantityCalculationRule.FirstDayEndsAtReferenceHourTime And 
					vAD = vDF And pDateFrom > (vDFRH - pQuantityCalculationRule.FreeOfChargeEarlyCheckInTime*3600) Then
					// No late check out at all
					Return 0;
				EndIf;
			EndIf;
			// Calculate base for delay time
			vDFRH = Date(Year(pDateFrom), Month(pDateFrom), Day(pDateFrom), Hour(vSrvRH), Minute(vSrvRH), Second(vSrvRH));
			vDTRH = Date(Year(pDateTo), Month(pDateTo), Day(pDateTo), Hour(vSrvRH), Minute(vSrvRH), Second(vSrvRH));
			If pQuantityCalculationRule.CalculateDelayFromCheckOutTimeForFirstDay And 
				vIsBetween1And2 And pIsCheckIn And pDateFrom > vDFRH Then
				vDTB = Date(Year(pDateTo), Month(pDateTo), Day(pDateTo), Hour(pDateFrom), Minute(pDateFrom), Second(pDateFrom));
			Else
				vDTB = vDTRH;
			EndIf;
			// Calculate delay time
			If pDateTo > vDTB Then
				vLQ = (pDateTo - vDTB) / 3600;
				If vLQ <= pQuantityCalculationRule.FreeOfChargeCheckOutDelayTime Then
					vLQ = 0;
					vQ = vQ + Round(vLQ / 24, 7);
				ElsIf vLQ <= pQuantityCalculationRule.ChargeByHoursCheckOutDelayTime Then
					If vSrvLCRR = Enums.QuantityRoundingRules.Int Then
						vLQ = Int(vLQ);
					ElsIf vSrvLCRR = Enums.QuantityRoundingRules.Round Then
						vLQ = Round(vLQ, 0);
					ElsIf vSrvLCRR = Enums.QuantityRoundingRules.Full Then
						If Int(vLQ) <> vLQ Then
							vLQ = Int(vLQ) + 1;
						EndIf;
					EndIf;
					rRemarks = NStr("ru = 'Задержка выезда на " + Round(vLQ, 0) + " часов'; en = 'Late check out for " + Round(vLQ, 0) + " hours'; de = 'Late check out for " + Round(vLQ, 0) + " hours'");
					vQ = vQ + Round(vLQ / 24, 7);
					rIsDayUse = True;
				ElsIf vLQ <= pQuantityCalculationRule.ChargeByQuarterOfADayCheckOutDelayTime Then
					vLQ = 6;
					rRemarks = NStr("ru = 'Задержка выезда на " + vLQ + " часов'; en = 'Late check out for " + vLQ + " hours'; de = 'Late check out for " + vLQ + " hours'");
					vQ = vQ + Round(vLQ / 24, 7);
					rIsDayUse = True;
				ElsIf vLQ <= pQuantityCalculationRule.ChargeByHalfOfADayCheckOutDelayTime Then
					vLQ = 12;
					rRemarks = NStr("en='Late check out for half a day';ru='Задержка выезда на полсуток';de='Abreiseverzögerung um 12 Stunden'");
					vQ = vQ + Round(vLQ / 24, 7);
					rIsDayUse = True;
				ElsIf pQuantityCalculationRule.Do1DayCheckOutDelayCharge Then
					vLQ = 24;
					vQ = vQ + Round(vLQ/24, 7);
					rIsDayUse = True;
				EndIf;
			EndIf;
		EndIf;
		If vSrvPH <> 24 Then
			// Recalculate late check-out
			vQ = Round(vQ * (24 / vSrvPH), 0);
		EndIf;
		// Check for minimum quantity
		If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
			vQ = pMinQuantity;
			If vQ >= 1 Then
				rRemarks = "";
			EndIf;
		EndIf;
		Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.EarlyCheckIn Or 
	      vSrvQCR = Enums.QuantityCalculationRuleTypes.EarlyCheckInNoDateShift Then
		If Not vSrvRHIsUsed Then
			vSrvRH = '00010101' + (pDateFrom - BegOfDay(pDateFrom));
		EndIf;
		If vSrvPH = 0 Then
			Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
			|CAUSE: Service period in hours is not specified for quantity calculation rule <Early check-in>.
			|DESC: Service period in hours should not be equal 0 hours for quantity calculation rule <Early check-in>.';
			|ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
			|CAUSE: Не задана периодичность услуги для вида расчета <Ранний заезд>.
			|DESC: У услуги, для которой количество рассчитывается по виду расчета <Ранний заезд>, период должен быть указан.';
			|de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
			|CAUSE: Die Regelmäßigkeit für die Abrechnungsart <Frühe Anreise> ist nicht angegeben.
			|DESC: Bei einer Dienstleistung, für die die Quantität nach der Abrechnungsart <Frühe Anreise> berechnet wird, muss der Zeitraum angegeben sein.'"));
		EndIf;
		If Not pIsCheckIn Then
			Return 0;
		EndIf;
		// Early check in part if accounting date equals check in date
		vQ = 0;
		If vAD = vDF Then
			vSkipEarlyCheckIn = False;
			vIsOneDay = False;
			vTQ = (pDateTo - pDateFrom)/(3600 * 24);
			If vTQ <= 1 Then
				vIsOneDay = True;
			EndIf;
			If vIsOneDay Then
				If Not pQuantityCalculationRule.FirstDayStartsAtReferenceHourTime Then
					// No early check-in at all
					vSkipEarlyCheckIn = True;
				EndIf;
			EndIf;
			If Not vSkipEarlyCheckIn Then
				vDFRH = Date(Year(pDateFrom), Month(pDateFrom), Day(pDateFrom), Hour(vSrvRH), Minute(vSrvRH), Second(vSrvRH));
				If pDateFrom < vDFRH Then
					vEQ = (vDFRH - pDateFrom) / 3600;
					If vEQ <= pQuantityCalculationRule.FreeOfChargeEarlyCheckInTime Then
						vEQ = 0;
						vQ = vQ + Round(vEQ / 24, 7);
					ElsIf vEQ <= pQuantityCalculationRule.ChargeByHoursEarlyCheckInTime Then
						If vSrvECRR = Enums.QuantityRoundingRules.Int Then
							vEQ = Int(vEQ);
						ElsIf vSrvECRR = Enums.QuantityRoundingRules.Round Then
							vEQ = Round(vEQ, 0);
						ElsIf vSrvECRR = Enums.QuantityRoundingRules.Full Then
							If Int(vEQ) <> vEQ Then
								vEQ = Int(vEQ) + 1;
							EndIf;
						EndIf;
						rRemarks = NStr("ru = 'Ранний заезд на " + Round(vEQ, 0) + " часов'; en = 'Early check in for " + Round(vEQ, 0) + " hours'; de = 'Early check in for " + Round(vEQ, 0) + " hours'");
						vQ = vQ + Round(vEQ / 24, 7);
						rIsDayUse = True;
					ElsIf vEQ <= pQuantityCalculationRule.ChargeByQuarterOfADayEarlyCheckInTime Then
						vEQ = 6;
						rRemarks = NStr("ru = 'Ранний заезд на " + vEQ + " часов'; en = 'Early check in for " + vEQ + " hours'; de = 'Early check in for " + vEQ + " hours'");
						vQ = vQ + Round(vEQ / 24, 7);
						rIsDayUse = True;
					ElsIf vEQ <= pQuantityCalculationRule.ChargeByHalfOfADayEarlyCheckInTime Then
						vEQ = 12;
						rRemarks = NStr("en='Early check in for half of a day';ru='Ранний заезд на полсуток';de='Um 12 Stunden frühere Anreise'");
						vQ = vQ + Round(vEQ / 24, 7);
						rIsDayUse = True;
					ElsIf pQuantityCalculationRule.Do1DayEarlyCheckInCharge Then
						vEQ = 24;
						vQ = vQ + Round(vEQ / 24, 7);
						rIsDayUse = True;
					EndIf;
				EndIf;
			EndIf;
			If vSrvRHIsUsed And vSrvQCR = Enums.QuantityCalculationRuleTypes.EarlyCheckInNoDateShift Then
				vHotel = pDocumentObj.Hotel;
				If ValueIsFilled(vHotel.AccountingDate) And ValueIsFilled(vHotel.CloseOfDayDefaultTime) Then
					If (pDateFrom - BegOfDay(pDateFrom)) < (vHotel.CloseOfDayDefaultTime - BegOfDay(vHotel.CloseOfDayDefaultTime)) Then
						pAccountingDate = pAccountingDate - 24 * 3600;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If vSrvPH <> 24 Then
			// Recalculate early check-in
			vQ = Round(vQ * (24 / vSrvPH), 0);
		EndIf;
		// Check for minimum quantity
		If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
			vQ = pMinQuantity;
			If vQ >= 1 Then
				rRemarks = "";
			EndIf;
		EndIf;
		// Move accounting date one day back
		If vQ <> 0 And vSrvQCR = Enums.QuantityCalculationRuleTypes.EarlyCheckIn Then
			pAccountingDate = pAccountingDate - 24 * 3600;
		EndIf;			
		Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.ReferenceHourTransfers Then
		If Not vSrvRHIsUsed Then
			vSrvRH = '00010101' + (pDateFrom - BegOfDay(pDateFrom));
		EndIf;
		If vSrvPH <> 24 Then
			Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
			|CAUSE: Service period in hours is wrong for quantity calculation rule <Reference hour transfers>.
			|DESC: Service period in hours should be equal 24 hours for quantity calculation rule <Reference hour transfers>.';
			|ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
			|CAUSE: Не верно задана периодичность услуги для вида расчета <Переходы через расчетный час>.
			|DESC: У услуги, для которой количество рассчитывается по виду расчета <Переходы через расчетный час>, период должен быть равен 24 часам.';
			|de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
			|CAUSE: Falsche Eingabe der Regelmäßigkeit für die Abrechnungsart <Größer als die Abrechnungsstunde>.
			|DESC: Bei einer Dienstleistung, für die die Quantität nach der Abrechnungsart <Größer als die Abrechnungsstunde> berechnet wird, muss der Zeitraum 24 Stunden betragen.'"));
		EndIf;
		vQ = 0;
		vD = Date(Year(vDF), Month(vDF), Day(vDF), Hour(vSrvRH), Minute(vSrvRH), Second(vSrvRH));
		vNDRH = vD + 24 * 3600;
		While vD < pDateTo Do
			If vD >= pDateFrom Then
				If vAD = BegOfDay(vD) Then
					vQ = 1;
					// Check for minimum quantity
					If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
						vQ = pMinQuantity;
					EndIf;
					Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
				EndIf;
			EndIf;
			vD = vD + 24 * 3600;
		EndDo;
		If pDateTo <= vNDRH And vAD = BegOfDay(pDateFrom) And 
			pIsCheckIn And pIsCheckOut And 
			pQuantityCalculationRule.ChargeMealsAtFirstDay Then
			vQ = 1;
			// Check for minimum quantity
			If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
				vQ = pMinQuantity;
			EndIf;
			Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
		EndIf;
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.Breakfast Or 
	      vSrvQCR = Enums.QuantityCalculationRuleTypes.BreakfastServiceDateShift Then
		If Not vSrvRHIsUsed Then
			Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
			           |CAUSE: Reference hour is not defined for quantity calculation rule <Breakfast>.
			           |DESC: Reference hour is mandatory parameter for quantity calculation rule <Breakfast> and should be filled.';
			           |ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
			           |CAUSE: Не определен расчетный час для вида расчета <Завтрак>.
			           |DESC: У услуги, для которой количество рассчитывается по виду расчета <Завтрак>, должен быть указан расчетный час.';
			           |de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
			           |CAUSE: Die Abrechnungsstunde für die Abrechnungsart <Frühstück> ist nicht festgelegt.
			           |DESC: Bei einer Dienstleistung, für die die Quantität nach der Abrechnungsart <Frühstück> berechnet wird, muss die Abrechnungsstunde angegeben sein.'"));
		EndIf;
		If vSrvPH <> 24 Then
			Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
			           |CAUSE: Service period in hours is wrong for quantity calculation rule <Breakfast>.
			           |DESC: Service period in hours should be equal 24 hours for quantity calculation rule <Breakfast>.';
			           |ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
			           |CAUSE: Не верно задана периодичность услуги для вида расчета <Завтрак>.
			           |DESC: У услуги, для которой количество рассчитывается по виду расчета <Завтрак>, период должен быть равен 24 часам.';
			           |de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
			           |CAUSE: Falsche Eingabe der Regelmäßigkeit für die Abrechnungsart <Frühstück>.
			           |DESC: Bei einer Dienstleistung, für die die Quantität nach der Abrechnungsart <Frühstück> berechnet wird, muss der Zeitraum 24 Stunden betragen.'"));
		EndIf;
		vQ = 0;
		// The only difference between ReferenceHourTransfers and Breakfast is
		// that first day is not calculated for breakfast
		vAD = vAD + 24 * 3600;
		vD = Date(Year(vDF), Month(vDF), Day(vDF), Hour(vSrvRH), Minute(vSrvRH), Second(vSrvRH));
		vFDRH = vD;
		vNDRH = vD + 24 * 3600;
		While vD < pDateTo Do
			If vD > pDateFrom Then
				If BegOfDay(vD) <> vDF Then
					If vAD = BegOfDay(vD) Then
						vQ = 1;
						// Check for minimum quantity
						If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
							vQ = pMinQuantity;
						EndIf;
						If vSrvQCR = Enums.QuantityCalculationRuleTypes.Breakfast Then
							pAccountingDate = pAccountingDate + 24 * 3600;
						EndIf;
						Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
					EndIf;
				EndIf;
			EndIf;
			vD = vD + 24 * 3600;
		EndDo;
		If pDateTo <= vNDRH And BegOfDay(pAccountingDate) = BegOfDay(pDateFrom) And 
			pIsCheckIn And pIsCheckOut Then
			If pDateFrom <= vFDRH Then
				If vSrvQCR = Enums.QuantityCalculationRuleTypes.Breakfast Then
					pAccountingDate = pAccountingDate - 24 * 3600;
				EndIf;
				vQ = 1;
			ElsIf pQuantityCalculationRule.ChargeMealsAtFirstDay Then
				If vSrvQCR = Enums.QuantityCalculationRuleTypes.Breakfast Then
					pAccountingDate = pAccountingDate - 24 * 3600;
				EndIf;
				vQ = 1;
			EndIf;
			// Check for minimum quantity
			If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
				vQ = pMinQuantity;
			EndIf;
		EndIf;
		If vSrvQCR = Enums.QuantityCalculationRuleTypes.Breakfast Then
			pAccountingDate = pAccountingDate + 24 * 3600;
		EndIf;
		Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.NumberOfDays Then
		// Calculate day price if hotel product with fixed cost is choosen
		If pDocumentObj <> Undefined And ValueIsFilled(pDocumentObj.HotelProduct) And pPrice > 0 Then
			vProductSum = pDocumentObj.HotelProduct.Sum;
			If pDocumentObj.HotelProduct.FixProductCost And vProductSum > 0 Then
				If pDocumentObj.HotelProduct.FixProductPeriod Or pDocumentObj.HotelProduct.FixPlannedPeriod Then
					// Get duration from the product 
					vDuration = pDocumentObj.HotelProduct.Duration;
				Else
					// Get duration from the document
					If TypeOf(pDocumentObj) = Type("DocumentObject.Accommodation") And pDocumentObj.FixReservationConditions And pReservationObj <> Undefined Then
						vDuration = pReservationObj.Duration;
					Else
						vDuration = pDocumentObj.Duration;
					EndIf;
				EndIf;
				If vDuration > 0 Then
					vQ = 0;
					// Calculate effective day price
					vDayPrice = Int(vProductSum/vDuration);
					// Set last day price to the rest of the product cost
					vLastDayPrice = vProductSum - vDayPrice*(vDuration - 1);
					// Get check-out date based on duration
					vDT = vDF + (vDuration - 1) * 24 * 3600;
					// Update current room rate price
					If vAD = vDT Then
						pPrice = vLastDayPrice;
						If ValueIsFilled(pDocumentObj.HotelProduct.Currency) Then
							pCurrency = pDocumentObj.HotelProduct.Currency;
						EndIf;
						vQ = 1;
						// Check for minimum quantity
						If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
							vQ = pMinQuantity;
						EndIf;
					ElsIf vAD < vDT Then
						pPrice = vDayPrice;
						If ValueIsFilled(pDocumentObj.HotelProduct.Currency) Then
							pCurrency = pDocumentObj.HotelProduct.Currency;
						EndIf;
						vQ = 1;
						// Check for minimum quantity
						If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
							vQ = pMinQuantity;
						EndIf;
					Else
						pPrice = 0;
						vQ = 0;
					EndIf;
					// Return
					Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
				EndIf;
			EndIf;
		EndIf;
		// Normal calculation
		vQ = 0;
		If vDF = vDT Then
			If vAD = vDF Then
				vQ = 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
				Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
			EndIf;
		Else
			If (vAD >= vDF) And (vAD < vDT) Then
				vQ = 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
				Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
			EndIf;
		EndIf;
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.HotelProduct Then
		// Calculate day price if hotel product with fixed cost is choosen
		If pDocumentObj <> Undefined And ValueIsFilled(pDocumentObj.HotelProduct) And pPrice > 0 Then
			vProductSum = pDocumentObj.HotelProduct.Sum;
			If pDocumentObj.HotelProduct.FixProductCost And
				vProductSum > 0 Then
				If pDocumentObj.HotelProduct.FixProductPeriod Or pDocumentObj.HotelProduct.FixPlannedPeriod Then
					// Get duration from the product 
					vDuration = pDocumentObj.HotelProduct.Duration;
				Else
					// Get duration from the document
					If TypeOf(pDocumentObj) = Type("DocumentObject.Accommodation") And pDocumentObj.FixReservationConditions And pReservationObj <> Undefined Then
						vDuration = pReservationObj.Duration;
					Else
						vDuration = pDocumentObj.Duration;
					EndIf;
				EndIf;
				If vDuration > 0 Then
					vQ = 0;
					// Calculate effective day price
					vDayPrice = Int(vProductSum/vDuration);
					// Set last day price to the rest of the product cost
					vLastDayPrice = vProductSum - vDayPrice * (vDuration - 1);
					// Get check-out date based on duration
					vDT = vDF + (vDuration-1) * 24 * 3600;
					// Update current room rate price
					If vAD = vDT Then
						pPrice = vLastDayPrice;
						If ValueIsFilled(pDocumentObj.HotelProduct.Currency) Then
							pCurrency = pDocumentObj.HotelProduct.Currency;
						EndIf;
						vQ = 1;
						// Check for minimum quantity
						If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
							vQ = pMinQuantity;
						EndIf;
					ElsIf vAD < vDT Then
						pPrice = vDayPrice;
						If ValueIsFilled(pDocumentObj.HotelProduct.Currency) Then
							pCurrency = pDocumentObj.HotelProduct.Currency;
						EndIf;
						vQ = 1;
						// Check for minimum quantity
						If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
							vQ = pMinQuantity;
						EndIf;
					Else
						pPrice = 0;
						vQ = 0;
					EndIf;
					// Return
					Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
				EndIf;
			EndIf;
		EndIf;
		// Normal calculation
		vQ = 0;		
		// 1. Main part which is 1 actually
		If vDF = vDT Then
			If vAD = vDF And Not pIsRoomChange Then
				vQ = 1;
			EndIf;
		Else
			If vAD >= vDF And vAD < vDT Then
				vQ = 1;
			EndIf;
		EndIf;
		// 2. Late check out part if accounting date equals check out date
		If vAD = vDT And pIsCheckOut And vAD > vDF Then
			// Calculate base for delay time
			vDTB = Date(Year(pDateTo), Month(pDateTo), Day(pDateTo), Hour(pDateFrom), Minute(pDateFrom), Second(pDateFrom));
			// Calculate delay time
			vLQ = Int((pDateTo - vDTB) / 3600);
			If vLQ >= 0 Then
				If vLQ <= pQuantityCalculationRule.FreeOfChargeCheckOutDelayTime Then
					vLQ = 0;
					vQ = 0;
				ElsIf vLQ <= pQuantityCalculationRule.ChargeByHalfOfADayCheckOutDelayTime Then
					vLQ = 12;
					rRemarks = NStr("en='Late check out for half a day';ru='Задержка выезда на полсуток';de='Abreiseverzögerung um 12 Stunden'");
					vQ = vQ + Round(vLQ / 24, 7);
					rIsDayUse = True;
				Else
					vLQ = 24;
					vQ = vQ + Round(vLQ / 24, 7);
					rIsDayUse = True;
				EndIf;
			EndIf;
		EndIf;
		Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.Daily Then
		vQ = 0;
		// Function returns 1 for all days inside accommodation period
		If vSrvPH <> 24 Then
			Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
			|CAUSE: Service period in hours is wrong for quantity calculation rule <Daily>.
			|DESC: Service period in hours should be equal 24 hours for quantity calculation rule <Daily>.';
			|ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
			|CAUSE: Не верно задана периодичность услуги для вида расчета <Ежедневно>.
			|DESC: У услуги, для которой количество рассчитывается по виду расчета <Ежедневно>, период должен быть равен 24 часам.';
			|de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
			|CAUSE: Falsche Eingabe der Regelmäßigkeit für die Abrechnungsart <Täglich>.
			|DESC: Bei einer Dienstleistung, für die die Quantität nach der Abrechnungsart <Täglich> berechnet wird, muss der Zeitraum 24 Stunden betragen.'"));
		EndIf;
		If vAD >= vDF And vAD <= vDT Then
			vQ = 1;
		EndIf;
		If vAD = vDT Then
			If (pDateTo - BegOfDay(pDateTo))/3600 <= pQuantityCalculationRule.FreeOfChargeCheckOutDelayTime Then
				vQ = 0;
			EndIf;
		EndIf;
		Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.Monthly Then
		vQ = 0;
		// Monthly is a calculation rule where price is specified per month
		// Function always returns 1 and recalculate price as 
		// Price/(Number of days in accounting date month)
		If vSrvPH <> 24 Then
			Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
			|CAUSE: Service period in hours is wrong for quantity calculation rule <Monthly>.
			|DESC: Service period in hours should be equal 24 hours for quantity calculation rule <Monthly>.';
			|ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
			|CAUSE: Не верно задана периодичность услуги для вида расчета <Помесячно>.
			|DESC: У услуги, для которой количество рассчитывается по виду расчета <Помесячно>, период должен быть равен 24 часам.';
			|de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
			|CAUSE: Falsche Eingabe der Regelmäßigkeit für die Abrechnungsart <Monatlich>.
			|DESC: Bei einer Dienstleistung, für die die Quantität nach der Abrechnungsart <Monatlich> berechnet wird, muss der Zeitraum 24 Stunden betragen.'"));
		EndIf;
		vProbeDate = vDF;
		If Day(vAD) >= Day(vDF) Then
			vProbeDate = vAD;
		Else
			vProbeDate = BegOfDay(BegOfMonth(vAD) - 1);
		EndIf;			
		vNumDaysPerMonth = Round((EndOfMonth(vProbeDate) - BegOfMonth(vProbeDate)) / (24 * 3600), 0);
		vPrice = Round(pPrice / vNumDaysPerMonth, 2);
		vMonthes = Month(vAD) - Month(vDF);
		If vMonthes < 0 Then
			vMonthes = vMonthes + 12;
		EndIf;
		If vMonthes = 0 Then
			vMonthes = 1;
		EndIf;
		If vDF = vDT Then
			If vAD = vDF Then
				pPrice = vPrice;
				vQ = 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
				Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
			EndIf;
		Else
			If vAD < vDT Then
				// To get per month price exactly as it was in room rate we calculate it
				// special way for the last day of month
				// If BegOfDay(vAD) = (BegOfDay(AddMonth(vDF, vMonthes)) - 24 * 3600) Then
				If Day(vAD) = vNumDaysPerMonth Then
					pPrice = pPrice - vPrice*(vNumDaysPerMonth - 1);
				Else
					pPrice = vPrice;
				EndIf;
				vQ = 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
				Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
			EndIf;
		EndIf;
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.VaucherWithDurationFixedInRate Then
		vQ = 0;
		// This is calculation rule where price is specified for the given number of days
		// Function always returns 1 and recalculate price as 
		// Price/(Duration specified in quantity calculation rule)
		If vSrvPH <> 24 Then
			Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
			|CAUSE: Service period in hours is wrong for quantity calculation rule <Monthly>.
			|DESC: Service period in hours should be equal 24 hours for quantity calculation rule <Monthly>.';
			|ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
			|CAUSE: Не верно задана периодичность услуги для вида расчета <Помесячно>.
			|DESC: У услуги, для которой количество рассчитывается по виду расчета <Помесячно>, период должен быть равен 24 часам.';
			|de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
			|CAUSE: Falsche Eingabe der Regelmäßigkeit für die Abrechnungsart <Größer als die Abrechnungsstunde>.
			|DESC: Bei einer Dienstleistung, für die die Quantität nach der Abrechnungsart <Größer als die Abrechnungsstunde> berechnet wird, muss der Zeitraum 24 Stunden betragen.'"));
		EndIf;
		vRateDuration = pQuantityCalculationRule.Duration;
		If vRateDuration = 0 Then
			Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
			|CAUSE: Quantity calculation rule duration in days is not specified.
			|DESC: Quantity calculation rule duration in days should be specified and equal to the vaucher default duration.';
			|ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
			|CAUSE: В правиле вычисления количества не указана продолжительность в днях.
			|DESC: В правиле вычисления количества продолжительность в днях должна быть указана и равна продолжительности путевки.';
			|de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
			|CAUSE: In der Regel zur Berechnung des Betrags wird die Dauer nicht in Tagen angegeben.
			|DESC: Die Regel für die Berechnung der Dauer in Tagen muss angegeben werden und entspricht der Dauer des Vaucher.'"));
		EndIf;
		vED = vDF + 24 * 3600 *(vRateDuration - 1);
		vPrice = Round(pPrice / vRateDuration, 2);
		If vAD < vED Then
			pPrice = vPrice;
			vQ = 1;
			Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
		Else
			pPrice = pPrice - vPrice * (vRateDuration - 1);
			vQ = 1;
			Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
		EndIf;
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.OneTimeCharge Then
		vQ = 0;
		// Returns 1 for the first day only
		If pIsOneTimeChargeNecessary And pIsCheckIn Then
			If vDF = vAD Then
				vQ = 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
				Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
			EndIf;
		EndIf;
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.Reservation Then
		vQ = 0;
		// Returns 1 for the first day only if this function is called from reservation or
		// Accommodation is filled based on reservation
		If pIsReservation And pIsCheckIn Then
			If vDF = vAD Then
				vQ = 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
				Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
			EndIf;
		EndIf;
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.Int Then
		// Calculates int number of periods for the specified period.
		// Returns this number devided by number of days for the specified period
		vQ = Int((pDateTo - cm0SecondShift(pDateFrom))/(3600*vSrvPH));
		If vSrvPH <> 24 Or vQ < 1 Then
			If vAD <> vDF Then
				vQ = 0;
			Else
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			EndIf;
		Else
			vCurQ = (vAD - vDF)/(24 * 3600) + 1;
			If vCurQ <= Int(vQ) Then
				vQ = 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			ElsIf vQ > (vCurQ - 1) Then
				vQ = vQ - vCurQ + 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			Else
				vQ = 0;
			EndIf;
		EndIf;
		Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.Precise Then
		// Calculates number of periods for the specified period.
		// Returns this number devided by number of days for the specified period
		vQ = (pDateTo - cm0SecondShift(pDateFrom))/(3600*vSrvPH);
		If (vQ - Int(vQ)) > pQuantityCalculationRule.RoomExaminationFreeOfChargeTime Then
			vQ = Round(vQ, 7);
		Else
			vQ = Int(vQ);
		EndIf;
		If vSrvPH <> 24 Or vQ < 1 Then
			If vAD <> vDF Then
				vQ = 0;
			Else
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			EndIf;
		Else
			vCurQ = (vAD - vDF)/(24 * 3600) + 1;
			If vCurQ <= Int(vQ) Then
				vQ = 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			ElsIf vQ > (vCurQ - 1) Then
				vQ = vQ - vCurQ + 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			Else
				vQ = 0;
			EndIf;
		EndIf;
		Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.Round Then
		// Calculates rounded number of periods for the specified period.
		// Returns this number devided by number of days for the specified period
		vQ = (pDateTo - cm0SecondShift(pDateFrom))/(3600*vSrvPH);
		If (vQ - Int(vQ)) > pQuantityCalculationRule.RoomExaminationFreeOfChargeTime Then
			vQ = Round(vQ, 0);
		Else
			vQ = Int(vQ);
		EndIf;
		If vSrvPH <> 24 Or vQ < 1 Then
			If vAD <> vDF Then
				vQ = 0;
			Else
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			EndIf;
		Else
			vCurQ = (vAD - vDF) / (24 * 3600) + 1;
			If vCurQ <= Int(vQ) Then
				vQ = 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			ElsIf vQ > (vCurQ - 1) Then
				vQ = vQ - vCurQ + 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			Else
				vQ = 0;
			EndIf;
		EndIf;
		Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.Full Then
		// Calculates full number of periods for the specified period.
		// Returns this number devided by number of days for the specified period
		vQ = (pDateTo - cm0SecondShift(pDateFrom))/(3600 * vSrvPH);
		If (vQ - Int(vQ)) > pQuantityCalculationRule.RoomExaminationFreeOfChargeTime Then
			vQ = Int(vQ) + 1;
		Else
			vQ = Int(vQ);
		EndIf;
		If vSrvPH <> 24 Or vQ < 1 Then
			If vAD <> vDF Then
				vQ = 0;
			Else
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			EndIf;
		Else
			vCurQ = (vAD - vDF) / (24 * 3600) + 1;
			If vCurQ <= Int(vQ) Then
				vQ = 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			ElsIf vQ > (vCurQ - 1) Then
				vQ = vQ - vCurQ + 1;
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			Else
				vQ = 0;
			EndIf;
		EndIf;
		Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.Hostel Then
		// Calculates number of days of accommodation for the given month and charge it by one service at check-in or the first day of month
		If vSrvPH <> 24 Then
			Raise(NStr("en='ERR: Error calling cmCalculateServiceQuantity function.
			|CAUSE: Service period in hours is wrong for quantity calculation rule <Hostel>.
			|DESC: Service period in hours should be equal 24 hours for quantity calculation rule <Hostel>.';
			|ru='ERR: Ошибка вызова функции cmCalculateServiceQuantity.
			|CAUSE: Не верно задана периодичность услуги для вида расчета <Общежитие>.
			|DESC: У услуги, для которой количество рассчитывается по виду расчета <Общежитие>, период должен быть равен 24 часам.';
			|de='ERR: Fehler bei Aufruf der Funktion cmCalculateServiceQuantity.
			|CAUSE: Falsche Eingabe der Regelmäßigkeit für die Abrechnungsart <Wohnheim>.
			|DESC: Bei einer Dienstleistung, für die die Quantität nach der Abrechnungsart <Wohnheim> berechnet wird, muss der Zeitraum 24 Stunden betragen.'"));
		EndIf;
		If pAccommodationPeriods = Undefined Then
			If vAD = vDF Or vAD = BegOfMonth(vAD) Then
				vED = Min(BegOfDay(EndOfMonth(vAD) + 1), BegOfDay(vDT));
				vQ = (vED - vAD)/(3600*vSrvPH);
				// Check for minimum quantity
				If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
					vQ = pMinQuantity;
				EndIf;
			Else
				vQ = 0;
			EndIf;
		Else
			vQ = 0;
			For Each vAccommodationPeriodsRow In pAccommodationPeriods Do
				vDF = BegOfDay(vAccommodationPeriodsRow.CheckInDate);
				vDT = BegOfDay(vAccommodationPeriodsRow.CheckOutDate);
				If vAD >= vDF And vAD < vDT And vDF < vDT Or vAD = vDF And vAD = vDT And vDF = vDT Then
					If vAD = vDF Or vAD = BegOfMonth(vAD) Then
						vED = Min(BegOfDay(EndOfMonth(vAD) + 1), vDT);
						vQ = (vED - vAD)/(3600*vSrvPH);
						// Check for minimum quantity
						If vQ <> 0 And pMinQuantity <> 0 And vQ < pMinQuantity Then
							vQ = pMinQuantity;
						EndIf;
					EndIf;
					Break;
				EndIf;
			EndDo;
		EndIf;
		Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 Or 
	      vSrvQCR = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO Or
	      vSrvQCR = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022 Then
		vDF = BegOfDay(pDocumentObj.CheckInDate);
		vDT = BegOfDay(pDocumentObj.CheckOutDate);
		vQ = 0;
		If (vDT - vDF)/(24 * 3600) > 1 Then
			If (vSrvQCR = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 And vAD >= vDF And vAD < vDT) Or 
			   (vSrvQCR = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO And vAD > vDF And vAD <= vDT) Or 
			   (vSrvQCR = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022 And vAD > vDF And vAD < vDT) Then
				If pDocumentObj <> Undefined And ValueIsFilled(pDocumentObj.Hotel) And ValueIsFilled(pDocumentObj.Guest) Then
					vHotel = pDocumentObj.Hotel;
					vGuest = pDocumentObj.Guest;
					If vGuest.Age > 17 Then
						If vGuest.Citizenship <> vHotel.Citizenship Then
							vQ = 1;
						Else
							If Not IsBlankString(vHotel.Cities) Then
								If Not IsBlankString(vGuest.City) Then
									If StrFind(TrimAll(vHotel.Cities), TrimAll(vGuest.City)) = 0 Then
										vQ = 1;
									Else
										vQ = 1;
										pPrice = 0;
										rRemarks = "17. Проживающий в домашнем регионе";
									EndIf;
								Else
									vQ = 1;
								EndIf;
							ElsIf ValueIsFilled(vHotel.Region) Then
								If Not IsBlankString(vGuest.Region) Then
									If StrFind(TrimAll(vHotel.Region), TrimAll(vGuest.Region)) = 0 Then
										vQ = 1;
									Else
										vQ = 1;
										pPrice = 0;
										rRemarks = "17. Проживающий в домашнем регионе";
									EndIf;
								Else
									vQ = 1;
								EndIf;
							Else
								vQ = 1;
							EndIf;
						EndIf;
					Else
						If ValueIsFilled(vGuest.DateOfBirth) Or pDocumentObj.GuestAge <> 0 And pDocumentObj.GuestAge < 18 Then
							vQ = 1;
							pPrice = 0;
							rRemarks = "Лицо не достигшее 18 лет";
						Else
							If vGuest.Citizenship <> vHotel.Citizenship Then
								vQ = 1;
							Else
								If Not IsBlankString(vHotel.Cities) Then
									If Not IsBlankString(vGuest.City) Then
										If StrFind(TrimAll(vHotel.Cities), TrimAll(vGuest.City)) = 0 Then
											vQ = 1;
										Else
											vQ = 1;
											pPrice = 0;
											rRemarks = "17. Проживающий в домашнем регионе";
										EndIf;
									Else
										vQ = 1;
									EndIf;
								ElsIf ValueIsFilled(vHotel.Region) Then
									If Not IsBlankString(vGuest.Region) Then
										If StrFind(TrimAll(vHotel.Region), TrimAll(vGuest.Region)) = 0 Then
											vQ = 1;
										Else
											vQ = 1;
											pPrice = 0;
											rRemarks = "17. Проживающий в домашнем регионе";
										EndIf;
									Else
										vQ = 1;
									EndIf;
								Else
									vQ = 1;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		Else
			If (vSrvQCR = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 And vAD = vDF) Or 
			   (vSrvQCR = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO And vAD = vDT) Or 
			   (vSrvQCR = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022 And vAD = vDF) Then
				If pDocumentObj <> Undefined And ValueIsFilled(pDocumentObj.Hotel) And ValueIsFilled(pDocumentObj.Guest) Then
					vQ = 1;
					pPrice = 0;
					rRemarks = "Срок проживания менее суток";
				EndIf;
			EndIf;
		EndIf;
		// COVID 2020
		If vQ <> 0 Then
			If vAD >= '20200601' And vAD <= '20201231' Then
				pPrice = 0;
			EndIf;
		EndIf;
		Return Round(vQ, ?(pQuantityCalculationRule.RoundQuantity, pQuantityCalculationRule.RoundQuantityDigits, 7));
	ElsIf vSrvQCR = Enums.QuantityCalculationRuleTypes.External Then
		// Calculates quantity according to the external algorithm
		SetSafeMode(True);
		Execute(TrimR(pQuantityCalculationRule.ExternalAlgorithm.Algorithm));
		SetSafeMode(False);
		Return vQ;
	EndIf;	
	Return 0;
EndFunction // cmCalculateServiceQuantity

// -----------------------------------------------------------------------------
// Description: Returns client balance by client identification card code.
//              Function can return XDTO object or comma separated values string and 
//              could be called as web-service or thru COM connection
// Parameters: Card identifier, Type of function output
// Return value: XDTO or String
// -----------------------------------------------------------------------------
Function cmGetClientIdentificationCardBalance(pIdentifier, pOutputType = "CSV", pExternalSystemCode = "TraktirFO3") Export
	// Log input parameters
	vInputParameters = NStr("en='Card identifier: ';ru='Идентификатор карты: ';de='Kartenidentifikator: '") + pIdentifier + Chars.LF + 
						NStr("en='OutputType: ';ru='OutputType: ';de='OutputType: '") + pOutputType + Chars.LF + 
						NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode;
	
	vWriteDebug = False;
	If Not IsBlankString(pExternalSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExternalSystemCode);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	vFuncLog = NStr("en='Get client identification card balance';ru='Получение баланса по карте идентификации клиента';de='Erhalten der Bilanz nach der Kundenidentifikationskarte'");
	If vWriteDebug Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vInputParameters);
	EndIf;

	// Initialize return string
	vNoPost = False;
	vRetStr = "";
	vBalance = 0;
	vLimit = 0;
	vClientFullName = "";
	vHotelName = "";
	vRoomCode = "";
	vCheckInDate = '00010101';
	vCheckOutDate = '00010101';
	vIsCheckedOut = False;
	vIsBlocked = False;
	vBlockReason = "";
	vCreditLimit = 0;
	vGuestGroupCode	= 0;
	vCustomerName = "";
	vPaymentMethodName = "";
	vFolioCurrencyCode = "";
	vRoomRateCode = "";
	vRoomRateName = "";
	vDiscount = 0;
	vDiscountType = Undefined;
	vDiscountCard = Undefined;
	vClientCode = "";	
	vOrdersXDTO = Undefined;
	vPhone = Undefined;
	vDateOfBirth = Undefined;

	// Try to find client identification card by identifier
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	IdentificationCards.Ref AS Ref,
	|	IdentificationCards.CreateDate AS CreateDate,
	|	IdentificationCards.Code AS Code,
	|	IdentificationCards.Description AS Description,
	|	IdentificationCards.IsBlocked AS IsBlocked,
	|	IdentificationCards.IsCheckedOut AS IsCheckedOut,
	|	IdentificationCards.Identifier AS Identifier,
	|	IdentificationCards.ParentDoc AS ParentDoc,
	|	IdentificationCards.Folio AS Folio,
	|	IdentificationCards.GuestGroup AS GuestGroup,
	|	IdentificationCards.Client AS Client,
	|	IdentificationCards.Room AS Room,
	|	IdentificationCards.DateTimeFrom AS DateTimeFrom,
	|	IdentificationCards.DateTimeTo AS DateTimeTo,
	|	IdentificationCards.Hotel AS Hotel,
	|	IdentificationCards.BlockReason AS BlockReason,
	|	ISNULL(IdentificationCards.IdentificationCardType.DoNotUseChargingRules, FALSE) AS DoNotUseChargingRules,
	|	ISNULL(IdentificationCards.IdentificationCardType.ExternalSystemsAllowed, &qEmptyString) AS ExternalSystemsAllowed,
	|	NULL AS DiscountType,
	|	1 AS SortCode
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	NOT IdentificationCards.DeletionMark
	|	AND (IdentificationCards.Identifier = &qIdentifier
	|			OR IdentificationCards.CardUID = &qIdentifier)
	|	AND IdentificationCards.Hotel IN HIERARCHY(&qCurrentHotel)
	|
	|UNION ALL
	|
	|SELECT
	|	DiscountCards.Ref,
	|	ISNULL(Folios.Date, DiscountCards.ValidFrom),
	|	DiscountCards.Code,
	|	DiscountCards.Description,
	|	DiscountCards.IsBlocked,
	|	ISNULL(NOT Folios.ParentDoc.AccommodationStatus.IsInHouse, TRUE),
	|	DiscountCards.Identifier,
	|	Folios.ParentDoc,
	|	Folios.Ref,
	|	Folios.GuestGroup,
	|	DiscountCards.Client,
	|	Folios.Room,
	|	ISNULL(Folios.DateTimeFrom, &qEmptyDate),
	|	ISNULL(Folios.DateTimeTo, &qEmptyDate),
	|	ISNULL(Folios.Hotel, &qCurrentHotel),
	|	DiscountCards.Remarks,
	|	FALSE,
	|	&qEmptyString,
	|	DiscountCards.DiscountType,
	|	CASE
	|		WHEN Folios.Ref IS NULL
	|			THEN 3
	|		ELSE 2
	|	END
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|		LEFT JOIN Document.Folio AS Folios
	|		ON (NOT Folios.IsClosed)
	|			AND (NOT Folios.DeletionMark)
	|			AND (Folios.Client = DiscountCards.Client
	|					AND Folios.Client <> &qEmptyClient
	|				OR Folios.ParentDoc.DiscountCard = DiscountCards.Ref)
	|			AND (Folios.Customer = &qEmptyCustomer
	|				OR Folios.Customer <> &qEmptyCustomer
	|					AND Folios.Customer.IsIndividual)
	|			AND (Folios.Hotel.AdditionalServicesFolioCondition = &qEmptyString
	|				OR Folios.Hotel.AdditionalServicesFolioCondition <> &qEmptyString
	|					AND Folios.Description LIKE ""%"" + Folios.Hotel.AdditionalServicesFolioCondition + ""%"")
	|WHERE
	|	NOT DiscountCards.DeletionMark
	|	AND (DiscountCards.Identifier = &qIdentifier
	|			OR DiscountCards.Phone = &qIdentifier)
	|	AND DiscountCards.ValidFrom <= &qCurrentDate
	|	AND (DiscountCards.ValidTo = &qEmptyDate
	|			OR DiscountCards.ValidTo <> &qEmptyDate
	|				AND DiscountCards.ValidTo >= &qCurrentDate)
	|
	|ORDER BY
	|	SortCode,
	|	CreateDate DESC,
	|	Code DESC";
	vQry.SetParameter("qIdentifier", TrimAll(pIdentifier));
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qEmptyString", "                                                  ");
	vQry.SetParameter("qCurrentDate", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qCurrentHotel", SessionParameters.CurrentHotel);
	vCards = vQry.Execute().Unload();
	If vCards.Count() > 0 Then
		vCardRow = vCards.Get(0);
		
		// Check if external system is allowed
		If Not IsBlankString(pExternalSystemCode) And Not IsBlankString(vCardRow.ExternalSystemsAllowed) Then
			If Find(vCardRow.ExternalSystemsAllowed, TrimAll(pExternalSystemCode)) = 0 Then
				vErrorMessage = TrimAll(vCardRow.Ref.IdentificationCardType) + NStr("en=' card is not allowed!'; ru=' карта не принимается!'; de=' Karte ist nicht erlaubt!'");
				If pOutputType = "CSV" Then
					If vWriteDebug Then
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , , vErrorMessage, vInteraction.MaxLogLenght);
					Else
						WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vErrorMessage);
					EndIf;

					Raise vErrorMessage;
				Else
					vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ClientIdentificationCardBalance"));
					vRetXDTO.Balance = 0;
					vRetXDTO.Client = cmRemoveUTFControlSymbols(vClientFullName);
					vRetXDTO.Hotel = vHotelName;
					vRetXDTO.Room = vRoomCode;
					vRetXDTO.CheckInDate = vCheckInDate;
					vRetXDTO.CheckOutDate = vCheckOutDate;
					vRetXDTO.IsCheckedOut = vIsCheckedOut;
					vRetXDTO.IsBlocked = True;
					vRetXDTO.BlockReason = Left(vErrorMessage, 100);
					vRetXDTO.CreditLimit = vCreditLimit;
					vRetXDTO.GuestGroup = vGuestGroupCode;
					vRetXDTO.Customer = cmRemoveUTFControlSymbols(vCustomerName);
					vRetXDTO.PaymentMethod = vPaymentMethodName;
					vRetXDTO.FolioCurrency = vFolioCurrencyCode;
					vRetXDTO.RoomRate = vRoomRateCode;
					vRetXDTO.Discount = vDiscount;
					vRetXDTO.DiscountType = ?(ValueIsFilled(vDiscountType), vDiscountType.Description, "");
					vRetXDTO.DiscountCard = ?(ValueIsFilled(vDiscountCard), TrimAll(vDiscountCard.Identifier), "");
					vRetXDTO.ClientCode = vClientCode;
					vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
					If vWriteDebug Then
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vRetXDTO, vErrorMessage, vInteraction.MaxLogLenght);
					Else
						WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vExtraXML);
					EndIf;
					Return vRetXDTO;
				EndIf;
			EndIf;
		EndIf;
		
		// Get folio from the client identification card
		vFolioCondition = ?(ValueIsFilled(vCardRow.Hotel), TrimAll(vCardRow.Hotel.AdditionalServicesFolioCondition), "");
		vFolioRef = vCardRow.Folio;
		vHotel = Undefined;
		If ValueIsFilled(vFolioRef) Then
			vParentDoc = vFolioRef.ParentDoc;
			vHotel = vFolioRef.Hotel;
			vIsCheckedOut = vFolioRef.IsClosed;
			If vFolioRef.IsClosed Then
				vCreditLimit = 0;
			ElsIf ValueIsFilled(vParentDoc) And TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") And vParentDoc.NoPost Then
				vNoPost = True;
				vCreditLimit = 0;
			ElsIf ValueIsFilled(vFolioRef.Hotel) Then
				If vFolioRef.Hotel.NoCreditLimit Then
					vCreditLimit = 999999999;
				Else
					vCreditLimit = vFolioRef.CreditLimit;
				EndIf;
			EndIf;
			vCustomerName = ?(ValueIsFilled(vFolioRef.Customer), TrimAll(vFolioRef.Customer.Description), "");
			vPaymentMethodName = ?(ValueIsFilled(vFolioRef.PaymentMethod), TrimAll(vFolioRef.PaymentMethod.Description), "");
			vFolioCurrencyCode = ?(ValueIsFilled(vFolioRef.FolioCurrency), TrimAll(vFolioRef.FolioCurrency.Code), "");
			If vCardRow.DoNotUseChargingRules Or IsBlankString(vFolioCondition) Or Not IsBlankString(vFolioCondition) And Find(Upper(vFolioRef.Description), Upper(vFolioCondition)) > 0 Then
				vBalance = vFolioRef.GetObject().pmGetBalance('39991231235959', , , vLimit);
				vBalance = vBalance - vLimit;
			EndIf;
			If ValueIsFilled(vParentDoc) And TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") And vParentDoc.NoPost Then
				vBalance = 0;
			EndIf;
			If ValueIsFilled(vFolioRef.ParentDoc) And 
				(TypeOf(vFolioRef.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolioRef.ParentDoc) = Type("DocumentRef.Reservation")) Then
				vRoomRateCode = ?(ValueIsFilled(vFolioRef.ParentDoc.RoomRate), TrimAll(vFolioRef.ParentDoc.RoomRate.Description), "");
			EndIf;
		EndIf;
		vClientFullName = ?(ValueIsFilled(vCardRow.Client), TrimAll(vCardRow.Client.FullName), "");
		vPhone = ?(ValueIsFilled(vCardRow.Client), TrimAll(vCardRow.Client.Phone),Undefined);
		vDateOfBirth = ?(ValueIsFilled(vCardRow.Client), vCardRow.Client.DateOfBirth,Undefined);
		vClientCode = ?(ValueIsFilled(vCardRow.Client), TrimAll(vCardRow.Client.Code), "");
		vHotelName = ?(ValueIsFilled(vCardRow.Hotel), TrimAll(vCardRow.Hotel.Description), "");
		vRoomCode = ?(ValueIsFilled(vCardRow.Room), TrimAll(vCardRow.Room.Description), "");
		vCheckInDate = vCardRow.DateTimeFrom;
		vCheckOutDate = vCardRow.DateTimeTo;
		vIsBlocked = vCardRow.IsBlocked;
		vBlockReason = TrimAll(vCardRow.BlockReason);
		vGuestGroupCode	= ?(ValueIsFilled(vCardRow.GuestGroup), Number(vCardRow.GuestGroup.Code), 0);
		If vHotel = Undefined Then
			vHotel = vCardRow.Hotel;
		EndIf;
		// Get discount data
		If ValueIsFilled(vCardRow.DiscountType) And TypeOf(vCardRow.Ref) = Type("CatalogRef.DiscountCards") Then
			vDiscountCard = vCardRow.Ref;
			vDiscountType = vCardRow.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		ElsIf ValueIsFilled(vCardRow.Folio) And ValueIsFilled(vCardRow.Folio.FolioDiscountCard) And Not ValueIsFilled(vCardRow.ParentDoc) Then
			vDiscountCard = vCardRow.Folio.FolioDiscountCard;
			vDiscountType = vDiscountCard.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		ElsIf ValueIsFilled(vCardRow.Folio) And ValueIsFilled(vCardRow.Folio.FolioDiscountType) And Not ValueIsFilled(vCardRow.ParentDoc) Then
			vDiscountType = vCardRow.Folio.FolioDiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		ElsIf ValueIsFilled(vCardRow.ParentDoc) And 
			(TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
			ValueIsFilled(vCardRow.ParentDoc.DiscountCard) Then
			vDiscountCard = vCardRow.ParentDoc.DiscountCard;
			vDiscountType = vDiscountCard.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		ElsIf ValueIsFilled(vCardRow.ParentDoc) And 
			(TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
			ValueIsFilled(vCardRow.ParentDoc.DiscountType) Then
			vDiscountType = vCardRow.ParentDoc.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		Else
			If ValueIsFilled(vCardRow.Client) Then
				If ValueIsFilled(vCardRow.Client.DiscountType) Then
					vDiscountType = vCardRow.Client.DiscountType;
					vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
				Else
					vDiscountCard = cmGetDiscountCardByClient(vCardRow.Client);
					If ValueIsFilled(vDiscountCard) And ValueIsFilled(vDiscountCard.DiscountType) Then
						vDiscountType = vDiscountCard.DiscountType;
						vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vDiscountType) And vDiscountType.DoNotExportToExternalInterfaces Then
			vDiscount = 0;
			vDiscountType = Undefined;
			vDiscountCard = Undefined;
		EndIf;
		
		// Add balances from the other parent document client folios
		If ValueIsFilled(vCardRow.ParentDoc) And ValueIsFilled(vFolioRef) And Not vCardRow.DoNotUseChargingRules Then
			// Check if this folio is in charging rules
			vChargingRulesFolios = New ValueList();
			vCardFolioIsInChargingRules = False;
			vCardParentDoc = vCardRow.ParentDoc;
			If Not (ValueIsFilled(vCardParentDoc) And TypeOf(vCardParentDoc) = Type("DocumentRef.Accommodation") And vCardParentDoc.NoPost) Then
				If TypeOf(vCardParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCardParentDoc) = Type("DocumentRef.Reservation") Then
					vCardParentDocGuestGroup = vCardParentDoc.GuestGroup;
					vChargingRules = vCardParentDoc.ChargingRules;
					If vChargingRules.Find(vFolioRef, "ChargingFolio") <> Undefined Then
						vCardFolioIsInChargingRules = True;
					Else
						If ValueIsFilled(vCardParentDocGuestGroup) And vCardParentDocGuestGroup.ChargingRules.Count() > 0 Then
							vCardParentDocGuestGroupChargingRules = vCardParentDocGuestGroup.ChargingRules;
							If vCardParentDocGuestGroupChargingRules.Find(vFolioRef, "ChargingFolio") <> Undefined Then
								vCardFolioIsInChargingRules = True;
							EndIf;
						EndIf;
					EndIf;
					For Each vPDCRRow In vChargingRules Do
						If vChargingRulesFolios.FindByValue(vPDCRRow.ChargingFolio) = Undefined Then
							vChargingRulesFolios.Add(vPDCRRow.ChargingFolio);
						EndIf;
					EndDo;
					If ValueIsFilled(vCardParentDocGuestGroup) And vCardParentDocGuestGroup.ChargingRules.Count() > 0 Then
						vCardParentDocGuestGroupChargingRules = vCardParentDocGuestGroup.ChargingRules;
						For Each vPDGGCRRow In vCardParentDocGuestGroupChargingRules Do
							If vChargingRulesFolios.FindByValue(vPDGGCRRow.ChargingFolio) = Undefined Then
								vChargingRulesFolios.Add(vPDGGCRRow.ChargingFolio);
							EndIf;
						EndDo;
					EndIf;
				ElsIf TypeOf(vCardParentDoc) = Type("DocumentRef.ResourceReservation") Then
					If vFolioRef = vCardParentDoc.ChargingFolio Then
						vCardFolioIsInChargingRules = True;
					EndIf;
					If ValueIsFilled(vCardParentDoc.ChargingFolio) Then
						If vChargingRulesFolios.FindByValue(vCardParentDoc.ChargingFolio) = Undefined Then
							vChargingRulesFolios.Add(vCardParentDoc.ChargingFolio);
						EndIf;
					EndIf;
				EndIf;
				If vCardFolioIsInChargingRules Then
					vQryBalances =  New Query();
					vQryBalances.Text = 
					"SELECT
					|	ClientAccountsBalance.Folio AS Folio,
					|	ClientAccountsBalance.FolioCurrency AS FolioCurrency,
					|	ISNULL(ClientAccountsBalance.Folio.Hotel.NoCreditLimit, FALSE) AS NoCreditLimit,
					|	ClientAccountsBalance.Folio.IsClosed AS IsClosed,
					|	ClientAccountsBalance.Folio.CreditLimit AS CreditLimit,
					|	ISNULL(ClientAccountsBalance.SumBalance, 0) + ISNULL(ClientAccountsBalance.LimitBalance, 0) AS ClientBalance
					|FROM
					|	AccumulationRegister.Accounts.Balance(
					|			&qBalancesPeriod,
					|			Folio <> &qFolio
					|				AND Folio IN (&qChargingRulesFolios)
					|				AND Folio.ParentDoc = &qParentDoc
					|				AND (Folio.Customer = &qEmptyCustomer
					|					OR Folio.Customer <> &qEmptyCustomer AND Folio.Customer.IsIndividual)
					|				AND (Folio.Description LIKE &qFolioDescription
					|					OR &qFolioDescriptionIsEmpty)) AS ClientAccountsBalance";
					vQryBalances.SetParameter("qBalancesPeriod", '39991231235959');
					vQryBalances.SetParameter("qFolio", vFolioRef);
					vQryBalances.SetParameter("qChargingRulesFolios", vChargingRulesFolios);
					vQryBalances.SetParameter("qParentDoc", vCardRow.ParentDoc);
					vQryBalances.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
					vQryBalances.SetParameter("qFolioDescription", "%" + ?(ValueIsFilled(vCardRow.Hotel), TrimAll(vCardRow.Hotel.AdditionalServicesFolioCondition), "") + "%");
					vQryBalances.SetParameter("qFolioDescriptionIsEmpty", ?(ValueIsFilled(vCardRow.Hotel), IsBlankString(vCardRow.Hotel.AdditionalServicesFolioCondition), True));
					vFolios = vQryBalances.Execute().Unload();
					For Each vFoliosRow In vFolios Do
						If vFoliosRow.FolioCurrency = vFolioRef.FolioCurrency Then
							vBalance = vBalance + vFoliosRow.ClientBalance;
							If Not vFoliosRow.IsClosed Then
								If vFoliosRow.NoCreditLimit Then
									vCreditLimit = 999999999;
								Else
									vCreditLimit = Max(vCreditLimit, vFoliosRow.CreditLimit);
								EndIf;
							EndIf;
						Else
							vBalance = vBalance + cmConvertCurrencies(vFoliosRow.ClientBalance, vFoliosRow.FolioCurrency, , vFolioRef.FolioCurrency, , CurrentSessionDate(), ?(ValueIsFilled(vCardRow.Hotel), vCardRow.Hotel, vFolioRef.Hotel));
							If Not vFoliosRow.IsClosed Then
								If vFoliosRow.NoCreditLimit Then
									vCreditLimit = 999999999;
								Else
									vCreditLimit = Max(vCreditLimit, cmConvertCurrencies(vFoliosRow.CreditLimit, vFoliosRow.FolioCurrency, , vFolioRef.FolioCurrency, , CurrentSessionDate(), ?(ValueIsFilled(vCardRow.Hotel), vCardRow.Hotel, vFolioRef.Hotel)));
								EndIf;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vCardRow.ParentDoc) Then
	
			vOrdersXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Orders"));				
			Query = New Query;
			Query.Text = 
			"SELECT
			|	Order.Number AS Number,
			|	Order.Type AS Type,
			|	Order.Quantity AS Quantity,
			|	Order.GuestsQuantity AS GuestsQuantity,
			|	Order.Sum AS Sum,
			|	Order.OrderTime AS OrderTime
			|FROM
			|	Document.Order AS Order
			|WHERE
			|	NOT Order.DeletionMark
			|	AND Order.ParentDoc = &ParentDoc
			|	AND NOT Order.Status.isOrderComplete
			|	AND NOT Order.Status.isOrderCancel
			|	AND NOT Order.Status.isNewOrder";
			Query.SetParameter("ParentDoc",vCardRow.ParentDoc);
			QueryResult = Query.Execute();
			
			SelectionDetailRecords = QueryResult.Select();
			
			While SelectionDetailRecords.Next() Do
				vOrderXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Order"));
				vOrderXDTO.id             = SelectionDetailRecords.Number;
				vOrderXDTO.Description    = cmGetObjectExternalSystemCodeByRef(vHotel, pExternalSystemCode, "OrderTypes", SelectionDetailRecords.Type);
				vOrderXDTO.GuestsQuantity = SelectionDetailRecords.GuestsQuantity;
				vOrderXDTO.OrderDate      = SelectionDetailRecords.OrderTime;
				vOrderXDTO.Quantity       = SelectionDetailRecords.Quantity;
				vOrderXDTO.Sum            = SelectionDetailRecords.Sum;
				vOrdersXDTO.Order.Add(vOrderXDTO);
			EndDo;
		
		EndIf;
		// Add client bonuses
		vDocDiscountCard = Undefined;
		vCardParentDoc = vCardRow.ParentDoc;
		If ValueIsFilled(vCardParentDoc) Then
			If ValueIsFilled(vCardParentDoc.DiscountCard) Then
				vDocDiscountCard = vCardParentDoc.DiscountCard;
			EndIf;
		EndIf;
		If Not (ValueIsFilled(vCardParentDoc) And TypeOf(vCardParentDoc) = Type("DocumentRef.Accommodation") And vCardParentDoc.NoPost) Then
			If ValueIsFilled(vCardRow.Client) And ValueIsFilled(vFolioRef) Then
				vClientObj = vCardRow.Client.GetObject();
				vBonus = 0;
				vBonusAmount = vClientObj.pmGetBonusesAmount(vFolioRef.Hotel, vFolioRef.FolioCurrency, vDocDiscountCard, vBonus);
				If vCreditLimit < 999999999 Then
					vCreditLimit = vCreditLimit + vBonusAmount;
				EndIf;
			EndIf;
		Else
			vNoPost = True;
		EndIf;
	Else
		vIsBlocked = True;
		vBlockReason = NStr("en='Unknown card!';ru='Неизвестная карта!';de='Unbekannte Karte!'");
	EndIf;
	
	// Build return string in CSV format
	vRetStr = Format(vBalance, "ND=17; NFD=2; NDS=.; NZ=; NG=") + "," + 
	"""" + cmRemoveUTFControlSymbols(cmRemoveComma(vClientFullName)) + """" + "," + 
	"""" + cmRemoveComma(vHotelName) + """" + "," + 
	"""" + vRoomCode + """" + "," + 
	"""" + Format(vCheckInDate, "DF='dd.MM.yyyy HH:mm'") + """" + "," + 
	"""" + Format(vCheckOutDate, "DF='dd.MM.yyyy HH:mm'") + """" + "," + 
	?(vIsCheckedOut, 1, 0) + "," + 
	?(vIsBlocked, 1, 0) + "," + 
	"""" + cmRemoveUTFControlSymbols(cmRemoveComma(vBlockReason)) + """" + "," + 
	Format(vCreditLimit, "ND=17; NFD=2; NDS=.; NZ=; NG=") + "," + 
	Format(vGuestGroupCode, "ND=12; NFD=0; NZ=; NG=") + "," + 
	"""" + cmRemoveUTFControlSymbols(cmRemoveComma(vCustomerName)) + """" + "," + 
	"""" + cmRemoveComma(vPaymentMethodName) + """" + "," + 
	"""" + vFolioCurrencyCode + """" + "," + 
	"""" + vRoomRateCode + """" + "," + 
	?(vDiscount <> 0, Format(vDiscount, "ND=6; NFD=2; NDS=.; NZ=; NG="), "0") + "," +
	"""" + ?(ValueIsFilled(vDiscountType), cmRemoveComma(vDiscountType.Description), "") + """" + "," + 
	"""" + ?(ValueIsFilled(vDiscountCard), cmRemoveComma(vDiscountCard.Identifier), "") + """" + "," + 
	"""" + vClientCode + """";
	
	vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
	If pOutputType = "CSV" Then
		vResp = NStr("en='Return string: ';ru='Строка возврата: ';de='Zeilenrücklauf: '") + vRetStr;
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , vResp, vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vResp);
		EndIf;

		Return vRetStr;
	Else
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ClientIdentificationCardBalance"));
		vRetXDTO.Balance = vBalance;
		vRetXDTO.Client = cmRemoveUTFControlSymbols(vClientFullName);
		vRetXDTO.Hotel = vHotelName;
		vRetXDTO.Room = vRoomCode;
		vRetXDTO.CheckInDate = vCheckInDate;
		vRetXDTO.CheckOutDate = vCheckOutDate;
		vRetXDTO.IsCheckedOut = vIsCheckedOut;
		vRetXDTO.IsBlocked = vIsBlocked;
		vRetXDTO.BlockReason = cmRemoveUTFControlSymbols(Left(vBlockReason, 100));
		vRetXDTO.CreditLimit = vCreditLimit;
		vRetXDTO.GuestGroup = vGuestGroupCode;
		vRetXDTO.Customer = cmRemoveUTFControlSymbols(vCustomerName);
		vRetXDTO.PaymentMethod = vPaymentMethodName;
		vRetXDTO.FolioCurrency = vFolioCurrencyCode;
		vRetXDTO.RoomRate = vRoomRateCode;
		vRetXDTO.Discount = vDiscount;
		vRetXDTO.Orders = vOrdersXDTO;
		vRetXDTO.ClientBirthDate = vDateOfBirth;		
		vRetXDTO.ClientPhone = cmRemoveUTFControlSymbols(vPhone);
		vRetXDTO.DiscountType = ?(ValueIsFilled(vDiscountType), cmGetObjectExternalSystemCodeByRef(vHotel, pExternalSystemCode, "DiscountTypes", vDiscountType, False), "");
		vRetXDTO.DiscountCard = ?(ValueIsFilled(vDiscountCard), TrimAll(vDiscountCard.Identifier), "");
		If vCardRow <> Undefined And ValueIsFilled(vCardRow.Ref) And TypeOf(vCardRow.Ref) = Type("CatalogRef.DiscountCards") Then
			vDiscountCardInfo = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vCardRow.Ref);
			vDiscountCardInfoXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "DiscountCardInfo"));
			vDiscountCardInfoXDTO.CardBalance             	 = vDiscountCardInfo.Balance;
			vDiscountCardInfoXDTO.MaxPercentPayment			 = vDiscountCardInfo.MaxPercentPayment;
			vDiscountCardInfoXDTO.TypeCard 				  	 = vDiscountCardInfo.TypeCard;
			vDiscountCardInfoXDTO.CertificateNominal      	 = vDiscountCardInfo.CertificateNominal;
			vDiscountCardInfoXDTO.BonusRate       			 = vDiscountCardInfo.BonusRate;
			vDiscountCardInfoXDTO.ValidFrom					 = vCardRow.Ref.ValidFrom;
			vDiscountCardInfoXDTO.ValidTo					 = vCardRow.Ref.ValidTo;
			vRetXDTO.DiscountCardInfo 			   			 = vDiscountCardInfoXDTO;
		Else
			vDiscountCardInfoXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "DiscountCardInfo"));
			vDiscountCardInfoXDTO.CardBalance             	 = 0;
			vDiscountCardInfoXDTO.MaxPercentPayment			 = 0;
			vDiscountCardInfoXDTO.TypeCard 				  	 = "";
			vDiscountCardInfoXDTO.CertificateNominal      	 = 0;
			vDiscountCardInfoXDTO.BonusRate       			 = 1;
			vDiscountCardInfoXDTO.ValidFrom					 = Date(1, 1, 1);
			vDiscountCardInfoXDTO.ValidTo					 = Date(1, 1, 1);

			vRetXDTO.DiscountCardInfo 			   			 = vDiscountCardInfoXDTO;	
		EndIf;
		vRetXDTO.ClientCode = vClientCode;
		vRetXDTO.NoPost = vNoPost;
		vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , vExtraXML, vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vExtraXML);
		EndIf;
		Return vRetXDTO;
	EndIf;
EndFunction // cmGetClientIdentificationCardBalance

// -----------------------------------------------------------------------------
// Description: Returns client balance by client identification card code.
//              Function can return XDTO object 
// Parameters: Card identifier
// Return value: XDTO or String
// -----------------------------------------------------------------------------
Function cmGetCardGuestsList(pIdentifier, pExternalSystemCode) Export
	vWriteDebug = False;
	If Not IsBlankString(pExternalSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExternalSystemCode);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	vFuncLog = NStr("en='Get clients by identification card';ru='Получение гостя по карте идентификации клиента';de='Erhalten der Gaste nach der Kundenidentifikationskarte'");

	// Initialize return string
	vNoPost = False;
	vRetStr = "";
	vBalance = 0;
	vLimit = 0;
	vClientFullName = "";
	vHotelName = "";
	vRoomCode = "";
	vCheckInDate = '00010101';
	vCheckOutDate = '00010101';
	vIsCheckedOut = False;
	vIsBlocked = False;
	vBlockReason = "";
	vCreditLimit = 0;
	vGuestGroupCode	= 0;
	vCustomerName = "";
	vPaymentMethodName = "";
	vFolioCurrencyCode = "";
	vRoomRateCode = "";
	vRoomRateName = "";
	vDiscount = 0;
	vDiscountType = Undefined;
	vDiscountCard = Undefined;
	vClientCode = "";	
	vOrdersXDTO = Undefined;
	vPhone = Undefined;
	vDateOfBirth = Undefined;
	vAccommodationCode = "";
	vIsRoomShare = False;
	vMealBoardTerm = ""; 
	vMealBoardTermName = "";
	vServicePackagesXDTO = Undefined;
	vReservationRemarks = "";
	
	// Try to find client identification card by identifier
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	IdentificationCards.Ref AS Ref,
	|	IdentificationCards.CreateDate AS CreateDate,
	|	IdentificationCards.Code AS Code,
	|	IdentificationCards.Description AS Description,
	|	IdentificationCards.IsBlocked AS IsBlocked,
	|	IdentificationCards.IsCheckedOut AS IsCheckedOut,
	|	IdentificationCards.Identifier AS Identifier,
	|	IdentificationCards.ParentDoc AS ParentDoc,
	|	IdentificationCards.Folio AS Folio,
	|	IdentificationCards.GuestGroup AS GuestGroup,
	|	IdentificationCards.Client AS Client,
	|	IdentificationCards.Room AS Room,
	|	IdentificationCards.DateTimeFrom AS DateTimeFrom,
	|	IdentificationCards.DateTimeTo AS DateTimeTo,
	|	IdentificationCards.Hotel AS Hotel,
	|	IdentificationCards.BlockReason AS BlockReason,
	|	ISNULL(IdentificationCards.IdentificationCardType.DoNotUseChargingRules, FALSE) AS DoNotUseChargingRules,
	|	ISNULL(IdentificationCards.IdentificationCardType.ExternalSystemsAllowed, &qEmptyString) AS ExternalSystemsAllowed,
	|	NULL AS DiscountType,
	|	1 AS SortCode
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	NOT IdentificationCards.DeletionMark
	|	AND (IdentificationCards.Identifier = &qIdentifier
	|			OR IdentificationCards.CardUID = &qIdentifier)
	|
	|UNION ALL
	|
	|SELECT
	|	DiscountCards.Ref,
	|	ISNULL(Folios.Date, DiscountCards.ValidFrom),
	|	DiscountCards.Code,
	|	DiscountCards.Description,
	|	DiscountCards.IsBlocked,
	|	ISNULL(NOT Folios.ParentDoc.AccommodationStatus.IsInHouse, TRUE),
	|	DiscountCards.Identifier,
	|	Folios.ParentDoc,
	|	Folios.Ref,
	|	Folios.GuestGroup,
	|	DiscountCards.Client,
	|	Folios.Room,
	|	ISNULL(Folios.DateTimeFrom, &qEmptyDate),
	|	ISNULL(Folios.DateTimeTo, &qEmptyDate),
	|	ISNULL(Folios.Hotel, &qCurrentHotel),
	|	DiscountCards.Remarks,
	|	FALSE,
	|	&qEmptyString,
	|	DiscountCards.DiscountType,
	|	CASE
	|		WHEN Folios.Ref IS NULL
	|			THEN 3
	|		ELSE 2
	|	END
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|		LEFT JOIN Document.Folio AS Folios
	|		ON (NOT Folios.IsClosed)
	|			AND (NOT Folios.DeletionMark)
	|			AND (Folios.Client = DiscountCards.Client
	|					AND Folios.Client <> &qEmptyClient
	|				OR Folios.ParentDoc.DiscountCard = DiscountCards.Ref)
	|			AND (Folios.Customer = &qEmptyCustomer
	|				OR Folios.Customer <> &qEmptyCustomer
	|					AND Folios.Customer.IsIndividual)
	|			AND (Folios.Hotel.AdditionalServicesFolioCondition = &qEmptyString
	|				OR Folios.Hotel.AdditionalServicesFolioCondition <> &qEmptyString
	|					AND Folios.Description LIKE ""%"" + Folios.Hotel.AdditionalServicesFolioCondition + ""%"")
	|WHERE
	|	NOT DiscountCards.DeletionMark
	|	AND (DiscountCards.Identifier = &qIdentifier
	|			OR DiscountCards.Phone = &qIdentifier)
	|	AND DiscountCards.ValidFrom <= &qCurrentDate
	|	AND (DiscountCards.ValidTo = &qEmptyDate
	|			OR DiscountCards.ValidTo <> &qEmptyDate
	|				AND DiscountCards.ValidTo >= &qCurrentDate)
	|
	|ORDER BY
	|	SortCode,
	|	CreateDate DESC,
	|	Code DESC";
	vQry.SetParameter("qIdentifier", TrimAll(pIdentifier));
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qEmptyString", "                                                  ");
	vQry.SetParameter("qCurrentDate", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qCurrentHotel", SessionParameters.CurrentHotel);
	
	vCards = vQry.Execute().Unload();
	
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestsList"));
	vGuestItemType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestItem");
	vGuestItemsType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestItems");
	vRetXDTO.GuestItems = XDTOFactory.Create(vGuestItemsType);

	
	If vCards.Count() > 0 Then
		vCardRow = vCards.Get(0);
		
		// Check if external system is allowed
		If Not IsBlankString(pExternalSystemCode) And Not IsBlankString(vCardRow.ExternalSystemsAllowed) Then
			If Find(vCardRow.ExternalSystemsAllowed, TrimAll(pExternalSystemCode)) = 0 Then
				vErrorMessage = TrimAll(vCardRow.Ref.IdentificationCardType) + NStr("en=' card is not allowed!'; ru=' карта не принимается!'; de=' Karte ist nicht erlaubt!'");
				vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ClientIdentificationCardBalance"));
				
				vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vRetXDTO, vErrorMessage, vInteraction.MaxLogLenght);
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vExtraXML);
				EndIf;
				Return vRetXDTO;
			EndIf;
		EndIf;
		
		// Get folio from the client identification card
		vFolioCondition = ?(ValueIsFilled(vCardRow.Hotel), TrimAll(vCardRow.Hotel.AdditionalServicesFolioCondition), "");
		vFolioRef = vCardRow.Folio;
		vHotel = Undefined;
		If ValueIsFilled(vFolioRef) Then
			vParentDoc = vFolioRef.ParentDoc;
			vHotel = vFolioRef.Hotel;
			vIsCheckedOut = vFolioRef.IsClosed;
			If vFolioRef.IsClosed Then
				vCreditLimit = 0;
			ElsIf ValueIsFilled(vParentDoc) And TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") And vParentDoc.NoPost Then
				vNoPost = True;
				vCreditLimit = 0;
			ElsIf ValueIsFilled(vFolioRef.Hotel) Then
				If vFolioRef.Hotel.NoCreditLimit Then
					vCreditLimit = 999999999;
				Else
					vCreditLimit = vFolioRef.CreditLimit;
				EndIf;
			EndIf;
			vCustomerName = ?(ValueIsFilled(vFolioRef.Customer), TrimAll(vFolioRef.Customer.Description), "");
			vPaymentMethodName = ?(ValueIsFilled(vFolioRef.PaymentMethod), TrimAll(vFolioRef.PaymentMethod.Description), "");
			vFolioCurrencyCode = ?(ValueIsFilled(vFolioRef.FolioCurrency), TrimAll(vFolioRef.FolioCurrency.Code), "");
			If vCardRow.DoNotUseChargingRules Or IsBlankString(vFolioCondition) Or Not IsBlankString(vFolioCondition) And Find(Upper(vFolioRef.Description), Upper(vFolioCondition)) > 0 Then
				vBalance = vFolioRef.GetObject().pmGetBalance('39991231235959', , , vLimit);
				vBalance = vBalance - vLimit;
			EndIf;
			
			If ValueIsFilled(vParentDoc) And TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") And vParentDoc.NoPost Then
				vBalance = 0;
			EndIf;
			
			If ValueIsFilled(vFolioRef.ParentDoc) And 
				(TypeOf(vFolioRef.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolioRef.ParentDoc) = Type("DocumentRef.Reservation")) Then
				vRoomRateCode = ?(ValueIsFilled(vFolioRef.ParentDoc.RoomRate), TrimAll(vFolioRef.ParentDoc.RoomRate.Code), "");
				vRoomRateName = ?(ValueIsFilled(vFolioRef.ParentDoc.RoomRate), TrimAll(vFolioRef.ParentDoc.RoomRate.Description), "");
				vAccommodationCode = vFolioRef.ParentDoc.Number;
				If ValueIsFilled(vFolioRef.ParentDoc.AccommodationType) And vFolioRef.ParentDoc.AccommodationType.Type <> Enums.AccomodationTypes.Room Then
					vIsRoomShare = True;
				EndIf;
				If ValueIsFilled(vFolioRef.ParentDoc.ServicePackage) And vFolioRef.ParentDoc.ServicePackage.IsMealBoardTerm Then
					vMealBoardTerm = vFolioRef.ParentDoc.ServicePackage.Code; 
					vMealBoardTermName = vFolioRef.ParentDoc.ServicePackage.Description;
				EndIf;
			EndIf;
		EndIf;
		vGuest = vCardRow.Client;
		If ValueIsFilled(vGuest) Then
			vClientFullName = TrimAll(vGuest.FullName);
			vPhone = TrimAll(vGuest.Phone);
			vDateOfBirth = vGuest.DateOfBirth;
			vClientCode = vGuest.Code;
		EndIf;
		vHotelName = ?(ValueIsFilled(vCardRow.Hotel), TrimAll(vCardRow.Hotel.Description), "");
		vRoomCode = ?(ValueIsFilled(vCardRow.Room), TrimAll(vCardRow.Room.Description), "");
		vCheckInDate = vCardRow.DateTimeFrom;
		vCheckOutDate = vCardRow.DateTimeTo;
		vIsBlocked = vCardRow.IsBlocked;
		vBlockReason = TrimAll(vCardRow.BlockReason);
		vGuestGroupCode	= ?(ValueIsFilled(vCardRow.GuestGroup), Number(vCardRow.GuestGroup.Code), 0);
		If vHotel = Undefined Then
			vHotel = vCardRow.Hotel;
		EndIf;
		// Get discount data
		If ValueIsFilled(vCardRow.DiscountType) And TypeOf(vCardRow.Ref) = Type("CatalogRef.DiscountCards") Then
			vDiscountCard = vCardRow.Ref;
			vDiscountType = vCardRow.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		ElsIf ValueIsFilled(vCardRow.Folio) And ValueIsFilled(vCardRow.Folio.FolioDiscountCard) And Not ValueIsFilled(vCardRow.ParentDoc) Then
			vDiscountCard = vCardRow.Folio.FolioDiscountCard;
			vDiscountType = vDiscountCard.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		ElsIf ValueIsFilled(vCardRow.Folio) And ValueIsFilled(vCardRow.Folio.FolioDiscountType) And Not ValueIsFilled(vCardRow.ParentDoc) Then
			vDiscountType = vCardRow.Folio.FolioDiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		ElsIf ValueIsFilled(vCardRow.ParentDoc) And 
			(TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
			ValueIsFilled(vCardRow.ParentDoc.DiscountCard) Then
			vDiscountCard = vCardRow.ParentDoc.DiscountCard;
			vDiscountType = vDiscountCard.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		ElsIf ValueIsFilled(vCardRow.ParentDoc) And 
			(TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
			ValueIsFilled(vCardRow.ParentDoc.DiscountType) Then
			vDiscountType = vCardRow.ParentDoc.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		Else
			If ValueIsFilled(vCardRow.Client) Then
				If ValueIsFilled(vCardRow.Client.DiscountType) Then
					vDiscountType = vCardRow.Client.DiscountType;
					vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
				Else
					vDiscountCard = cmGetDiscountCardByClient(vCardRow.Client);
					If ValueIsFilled(vDiscountCard) And ValueIsFilled(vDiscountCard.DiscountType) Then
						vDiscountType = vDiscountCard.DiscountType;
						vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vDiscountType) And vDiscountType.DoNotExportToExternalInterfaces Then
			vDiscount = 0;
			vDiscountType = Undefined;
			vDiscountCard = Undefined;
		EndIf;
		
		// Add balances from the other parent document client folios
		If ValueIsFilled(vCardRow.ParentDoc) And ValueIsFilled(vFolioRef) And Not vCardRow.DoNotUseChargingRules Then
			// Check if this folio is in charging rules
			vChargingRulesFolios = New ValueList();
			vCardFolioIsInChargingRules = False;
			vCardParentDoc = vCardRow.ParentDoc;
			If Not (ValueIsFilled(vCardParentDoc) And TypeOf(vCardParentDoc) = Type("DocumentRef.Accommodation") And vCardParentDoc.NoPost) Then
				If TypeOf(vCardParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCardParentDoc) = Type("DocumentRef.Reservation") Then
					vCardParentDocGuestGroup = vCardParentDoc.GuestGroup;
					vChargingRules = vCardParentDoc.ChargingRules;
					If vChargingRules.Find(vFolioRef, "ChargingFolio") <> Undefined Then
						vCardFolioIsInChargingRules = True;
					Else
						If ValueIsFilled(vCardParentDocGuestGroup) And vCardParentDocGuestGroup.ChargingRules.Count() > 0 Then
							vCardParentDocGuestGroupChargingRules = vCardParentDocGuestGroup.ChargingRules;
							If vCardParentDocGuestGroupChargingRules.Find(vFolioRef, "ChargingFolio") <> Undefined Then
								vCardFolioIsInChargingRules = True;
							EndIf;
						EndIf;
					EndIf;
					For Each vPDCRRow In vChargingRules Do
						If vChargingRulesFolios.FindByValue(vPDCRRow.ChargingFolio) = Undefined Then
							vChargingRulesFolios.Add(vPDCRRow.ChargingFolio);
						EndIf;
					EndDo;
					If ValueIsFilled(vCardParentDocGuestGroup) And vCardParentDocGuestGroup.ChargingRules.Count() > 0 Then
						vCardParentDocGuestGroupChargingRules = vCardParentDocGuestGroup.ChargingRules;
						For Each vPDGGCRRow In vCardParentDocGuestGroupChargingRules Do
							If vChargingRulesFolios.FindByValue(vPDGGCRRow.ChargingFolio) = Undefined Then
								vChargingRulesFolios.Add(vPDGGCRRow.ChargingFolio);
							EndIf;
						EndDo;
					EndIf;
				ElsIf TypeOf(vCardParentDoc) = Type("DocumentRef.ResourceReservation") Then
					If vFolioRef = vCardParentDoc.ChargingFolio Then
						vCardFolioIsInChargingRules = True;
					EndIf;
					If ValueIsFilled(vCardParentDoc.ChargingFolio) Then
						If vChargingRulesFolios.FindByValue(vCardParentDoc.ChargingFolio) = Undefined Then
							vChargingRulesFolios.Add(vCardParentDoc.ChargingFolio);
						EndIf;
					EndIf;
				EndIf;
				If vCardFolioIsInChargingRules Then
					vQryBalances =  New Query();
					vQryBalances.Text = 
					"SELECT
					|	ClientAccountsBalance.Folio AS Folio,
					|	ClientAccountsBalance.FolioCurrency AS FolioCurrency,
					|	ISNULL(ClientAccountsBalance.Folio.Hotel.NoCreditLimit, FALSE) AS NoCreditLimit,
					|	ClientAccountsBalance.Folio.IsClosed AS IsClosed,
					|	ClientAccountsBalance.Folio.CreditLimit AS CreditLimit,
					|	ISNULL(ClientAccountsBalance.SumBalance, 0) + ISNULL(ClientAccountsBalance.LimitBalance, 0) AS ClientBalance
					|FROM
					|	AccumulationRegister.Accounts.Balance(
					|			&qBalancesPeriod,
					|			Folio <> &qFolio
					|				AND Folio IN (&qChargingRulesFolios)
					|				AND Folio.ParentDoc = &qParentDoc
					|				AND (Folio.Customer = &qEmptyCustomer
					|					OR Folio.Customer <> &qEmptyCustomer AND Folio.Customer.IsIndividual)
					|				AND (Folio.Description LIKE &qFolioDescription
					|					OR &qFolioDescriptionIsEmpty)) AS ClientAccountsBalance";
					vQryBalances.SetParameter("qBalancesPeriod", '39991231235959');
					vQryBalances.SetParameter("qFolio", vFolioRef);
					vQryBalances.SetParameter("qChargingRulesFolios", vChargingRulesFolios);
					vQryBalances.SetParameter("qParentDoc", vCardRow.ParentDoc);
					vQryBalances.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
					vQryBalances.SetParameter("qFolioDescription", "%" + ?(ValueIsFilled(vCardRow.Hotel), TrimAll(vCardRow.Hotel.AdditionalServicesFolioCondition), "") + "%");
					vQryBalances.SetParameter("qFolioDescriptionIsEmpty", ?(ValueIsFilled(vCardRow.Hotel), IsBlankString(vCardRow.Hotel.AdditionalServicesFolioCondition), True));
					vFolios = vQryBalances.Execute().Unload();
					For Each vFoliosRow In vFolios Do
						If vFoliosRow.FolioCurrency = vFolioRef.FolioCurrency Then
							vBalance = vBalance + vFoliosRow.ClientBalance;
							If Not vFoliosRow.IsClosed Then
								If vFoliosRow.NoCreditLimit Then
									vCreditLimit = 999999999;
								Else
									vCreditLimit = Max(vCreditLimit, vFoliosRow.CreditLimit);
								EndIf;
							EndIf;
						Else
							vBalance = vBalance + cmConvertCurrencies(vFoliosRow.ClientBalance, vFoliosRow.FolioCurrency, , vFolioRef.FolioCurrency, , CurrentSessionDate(), ?(ValueIsFilled(vCardRow.Hotel), vCardRow.Hotel, vFolioRef.Hotel));
							If Not vFoliosRow.IsClosed Then
								If vFoliosRow.NoCreditLimit Then
									vCreditLimit = 999999999;
								Else
									vCreditLimit = Max(vCreditLimit, cmConvertCurrencies(vFoliosRow.CreditLimit, vFoliosRow.FolioCurrency, , vFolioRef.FolioCurrency, , CurrentSessionDate(), ?(ValueIsFilled(vCardRow.Hotel), vCardRow.Hotel, vFolioRef.Hotel)));
								EndIf;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			
		EndIf;
	
		vOrdersXDTO = GetOrdersXDTO(vCardRow.ParentDoc, pExternalSystemCode);
		vServicePackagesXDTO = GetServicePackagesXDTO(vCardRow.ParentDoc);
		vReservationRemarks = ?(ValueIsFilled(vCardRow.ParentDoc),vCardRow.ParentDoc.Remarks,""); 

		// Add client bonuses
		vDocDiscountCard = Undefined;
		vCardParentDoc = vCardRow.ParentDoc;
		If ValueIsFilled(vCardParentDoc) Then
			If ValueIsFilled(vCardParentDoc.DiscountCard) Then
				vDocDiscountCard = vCardParentDoc.DiscountCard;
			EndIf;
		EndIf;
		If Not (ValueIsFilled(vCardParentDoc) And TypeOf(vCardParentDoc) = Type("DocumentRef.Accommodation") And vCardParentDoc.NoPost) Then
			If ValueIsFilled(vCardRow.Client) And ValueIsFilled(vFolioRef) Then
				vClientObj = vCardRow.Client.GetObject();
				vBonus = 0;
				vBonusAmount = vClientObj.pmGetBonusesAmount(vFolioRef.Hotel, vFolioRef.FolioCurrency, vDocDiscountCard, vBonus);
				If vCreditLimit < 999999999 Then
					vCreditLimit = vCreditLimit + vBonusAmount;
				EndIf;
			EndIf;
		Else
			vNoPost = True;
		EndIf;
	Else
		vIsBlocked = True;
		vBlockReason = NStr("en='Unknown card!';ru='Неизвестная карта!';de='Unbekannte Karte!'");
	EndIf;
	
	// Build return string in CSV format
	
	vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
	
	vGuestItem = XDTOFactory.Create(vGuestItemType);
	
	If ValueIsFilled(vGuest) Then
		vGuestItem.Guest 			= cmRemoveUTFControlSymbols(cmRemoveComma(vGuest.FullName)) + ?(ValueIsFilled(vDiscountCard), "(DC " + TrimAll(vDiscountCard.Identifier) + ")", "");
		vGuestItem.GuestCode 		= vGuest.Code;
		vGuestItem.GuestSex 		= Upper(Left(TrimAll(vGuest.Sex), 1));
		vGuestItem.GuestDateOfBirth = vGuest.DateOfBirth;
		vGuestItem.GuestAge 		= vGuest.Age;
		If ValueIsFilled(vGuest.Citizenship) Then
			vGuestItem.GuestCitizenship = TrimAll(vGuest.Citizenship.ISOCode3);
		Else
			vGuestItem.GuestCitizenship = "";
		EndIf;
		vGuestItem.GuestLanguage 	= Upper(TrimAll(vGuest.Language.Code));
		vGuestItem.GuestLocale = ?(IsBlankString(vGuest.Language.LocalizationCode), "ru_RU", TrimAll(vGuest.Language.LocalizationCode));
		vGuestItem.GuestRemarks     = cmRemoveUTFControlSymbols(TrimAll(vGuest.Remarks));
	Else
		vGuestItem.Guest 			= "";
		vGuestItem.GuestCode 		= "";
		vGuestItem.GuestSex 		= "";
		vGuestItem.GuestAge 		= 0;
		vGuestItem.GuestCitizenship = "";
		vGuestItem.GuestLanguage 	= "";
		vGuestItem.GuestLocale = "";
		vGuestItem.GuestRemarks     = "";
	EndIf;
	vGuestItem.Hotel 			= cmRemoveComma(vHotelName);
	vGuestItem.Room 			= vRoomCode;
	vGuestItem.CheckInDate 		= vCheckInDate;
	vGuestItem.CheckOutDate 	= vCheckOutDate;
	vGuestItem.GuestGroup 		= vGuestGroupCode;
	vGuestItem.Customer 		= cmRemoveUTFControlSymbols(cmRemoveComma(vCustomerName));
	vGuestItem.PaymentMethod 	= TrimAll(vPaymentMethodName);
	vGuestItem.ClientBalance 	= vBalance;
	vGuestItem.CreditLimit 		= vCreditLimit;
	vGuestItem.FolioCurrency 	= vFolioCurrencyCode;
	vGuestItem.RoomRateCode		= vRoomRateCode;
	vGuestItem.RoomRate 		= vRoomRateName;
	vGuestItem.Discount 		= vDiscount;
	vGuestItem.DiscountType 	= ?(ValueIsFilled(vDiscountType), cmGetObjectExternalSystemCodeByRef(vHotel, pExternalSystemCode, "DiscountTypes", vDiscountType, False),"");
	vGuestItem.DiscountCard 	= ?(ValueIsFilled(vDiscountCard), TrimAll(vDiscountCard.Identifier), "");
	vGuestItem.NoPost           = vNoPost;
	
	vGuestItem.AccommodationCode= vAccommodationCode;
	vGuestItem.IsRoomShare 		= vIsRoomShare;
	vGuestItem.GuestPhone       = vPhone;
	vGuestItem.MealBoardTerm    = vMealBoardTerm;
	vGuestItem.MealBoardName    = vMealBoardTermName;
	
	vGuestItem.Orders = vOrdersXDTO;
	vGuestItem.ServicePackages = vServicePackagesXDTO;
	vGuestItem.ReservationRemarks = cmRemoveUTFControlSymbols(Left(cmRemoveComma(vReservationRemarks), 1024));
	
	If vCardRow <> Undefined And ValueIsFilled(vCardRow.Ref) And TypeOf(vCardRow.Ref) = Type("CatalogRef.DiscountCards") Then
		vDiscountCardInfo = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vCardRow.Ref);
		vDiscountCardInfoXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "DiscountCardInfo"));
		vDiscountCardInfoXDTO.CardBalance             	 = vDiscountCardInfo.Balance;
		vDiscountCardInfoXDTO.MaxPercentPayment			 = vDiscountCardInfo.MaxPercentPayment;
		vDiscountCardInfoXDTO.TypeCard 				  	 = vDiscountCardInfo.TypeCard;
		vDiscountCardInfoXDTO.CertificateNominal      	 = vDiscountCardInfo.CertificateNominal;
		vDiscountCardInfoXDTO.BonusRate       			 = vDiscountCardInfo.BonusRate;
		vDiscountCardInfoXDTO.ValidFrom					 = vCardRow.Ref.ValidFrom;
		vDiscountCardInfoXDTO.ValidTo					 = vCardRow.Ref.ValidTo;
		vGuestItem.DiscountCardInfo 			   		 = vDiscountCardInfoXDTO;
	Else
		vDiscountCardInfoXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "DiscountCardInfo"));
		vDiscountCardInfoXDTO.CardBalance             	 = 0;
		vDiscountCardInfoXDTO.MaxPercentPayment			 = 0;
		vDiscountCardInfoXDTO.TypeCard 				  	 = "";
		vDiscountCardInfoXDTO.CertificateNominal      	 = 0;
		vDiscountCardInfoXDTO.BonusRate       			 = 1;
		vDiscountCardInfoXDTO.ValidFrom					 = Date(1,1,1);
		vDiscountCardInfoXDTO.ValidTo					 = Date(1,1,1);

		vGuestItem.DiscountCardInfo 			   		 = vDiscountCardInfoXDTO;	
	EndIf;
	
	vGuestItem.IsCheckedOut = vIsCheckedOut;
	vGuestItem.IsBlocked = vIsBlocked;
	vGuestItem.BlockReason = cmRemoveUTFControlSymbols(Left(vBlockReason, 100));
	
	vGuestItem.GuestPhoto = "";
	If ValueIsFilled(vGuest) Then
		vGuestPhoto = vGuest.Photo.Get();
		If TypeOf(vGuestPhoto) = Type("Picture") Then
			vGuestItem.GuestPhoto = Base64String(vGuestPhoto.GetBinaryData());
		ElsIf TypeOf(vGuestPhoto) = Type("BinaryData") Then
			vGuestItem.GuestPhoto = Base64String(vGuestPhoto);
		Else
			vGuestItem.GuestPhoto = "";
		EndIf;
	EndIf;
	
	vRetXDTO.GuestItems.GuestItem.Add(vGuestItem);
		
	vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
	If vWriteDebug Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , vExtraXML, vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vExtraXML);
	EndIf;
	Return vRetXDTO;
EndFunction // cmGetCardGuestsList

// -----------------------------------------------------------------------------
// Description: Function returns client photo by code
// Parameters: Client code as string
// Return value: Picture object or Undefined
// -----------------------------------------------------------------------------
Function cmGetClientPhoto(pCode) Export
	vCode = TrimAll(pCode);
	If Not IsBlankString(vCode) Then
		vClt = Catalogs.Clients.FindByCode(vCode);
		If vClt.Photo <> Undefined Then
			Return vClt.Photo.Get();
		Else
			Return Undefined;
		EndIf;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetClientPhoto

// -----------------------------------------------------------------------------
// Description: Function returns client details by code
// Parameters: Client code as string
// Return value: XDTO
// -----------------------------------------------------------------------------
Function cmGetGuestDetails(pCode, pOutputType = "CSV") Export
	// Log input parameters
	WriteLogEvent(NStr("en='Get guest details';ru='Получить данные гостя';de='Daten des Gastes erhalten'"), EventLogLevel.Information, , , 
	NStr("en='Guest code: ';ru='Код гостя: ';de='Code des Gastes: '") + pCode);
	
	// Initialize return parameters				  
	vRetStr = "";
	vRetXDTO = Undefined;
	If pOutputType <> "CSV" Then
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestDetails"));
	EndIf;
	
	vGuest = Catalogs.Clients.FindByCode(TrimAll(pCode));
	If vGuest = Undefined Then
		WriteLogEvent(NStr("en='Guest not be found';ru='Гость не найден';de='Gast nicht gefunden'"), EventLogLevel.Information, , , 
		NStr("en='Guest code: ';ru='Код гостя: ';de='Code des Gastes: '") + pCode);
		Return Undefined;
	EndIf;
	vGuestPhoto = cmGetClientPhoto(pCode);
	If Not vGuestPhoto = Undefined Then 
		vFileName = TempFilesDir()+"clientphoto";
		vGuestPhoto.Write(vFileName);
		vBinData = New BinaryData(vFileName);
	EndIf;
	vRetStr = cmRemoveUTFControlSymbols(cmRemoveComma(TrimAll(vGuest.LastName))) + "," + 
	"""" + cmRemoveUTFControlSymbols(cmRemoveComma(TrimAll(vGuest.FirstName))) + """" + "," + 
	"""" + cmRemoveUTFControlSymbols(cmRemoveComma(TrimAll(vGuest.SecondName))) + """" + "," + 
	"""" + Format(vGuest.DateOfBirth, "DF='dd.MM.yyyy HH:mm'") + """" + "," + 
	"""" + ?(ValueIsFilled(vBinData), Base64String(vBinData), "") + """"; 
	// Return based on output type
	If pOutputType = "CSV" Then
		Return vRetStr;
	Else
		vRetXDTO.GuestLastName = cmRemoveUTFControlSymbols(TrimAll(vGuest.LastName));
		vRetXDTO.GuestFirstName = cmRemoveUTFControlSymbols(TrimAll(vGuest.FirstName));
		vRetXDTO.GuestSecondName = cmRemoveUTFControlSymbols(TrimAll(vGuest.SecondName));
		vRetXDTO.GuestDateOfBirth = vGuest.DateOfBirth;
		vRetXDTO.GuestPhoto = ?(ValueIsFilled(vBinData), Base64String(vBinData), "");
		Return vRetXDTO;
	EndIf;
EndFunction // cmGetGuestDetails

// -----------------------------------------------------------------------------
// Description: Function returns in-house accommodation for the given discount card
// Parameters: Discount card item ref
// Return value: Accommodation document ref
// -----------------------------------------------------------------------------
Function cmGetDiscountCardAccommodation(pDiscountCard) Export
	If Not ValueIsFilled(pDiscountCard) Then
		Return Documents.Accommodation.EmptyRef();
	EndIf;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.DiscountCard = &qDiscountCard
	|TOTALS BY
	|	Accommodation.Date,
	|	Accommodation.PointInTime,
	|	Accommodation.Room.SortCode,
	|	Accommodation.AccommodationType.SortCode";
	vQry.SetParameter("qDiscountCard", pDiscountCard);
	vAccommodations = vQry.Execute().Unload();
	If vAccommodations.Count() > 0 Then
		Return vAccommodations.Get(0).Ref;
	Else
		Return Documents.Accommodation.EmptyRef();
	EndIf;
EndFunction // cmGetDiscountCardAccommodation

// -----------------------------------------------------------------------------
// Description: Function returns in-house accommodation for the given client
// Parameters: Client item ref
// Return value: Accommodation document ref
// -----------------------------------------------------------------------------
Function cmGetClientAccommodation(pClient) Export
	If Not ValueIsFilled(pClient) Then
		Return Documents.Accommodation.EmptyRef();
	EndIf;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.Guest = &qGuest
	|
	|ORDER BY
	|	Accommodation.Date,
	|	Accommodation.PointInTime,
	|	Accommodation.Room.SortCode,
	|	Accommodation.AccommodationType.SortCode";
	vQry.SetParameter("qGuest", pClient);
	vAccommodations = vQry.Execute().Unload();
	If vAccommodations.Count() > 0 Then
		Return vAccommodations.Get(0).Ref;
	Else
		Return Documents.Accommodation.EmptyRef();
	EndIf;
EndFunction // cmGetClientAccommodation

// -----------------------------------------------------------------------------
//  Charges service by client identification card code.
//
// Parameters:
//  pIdentifier			 - 	 - 
//  pServiceCode		 - 	 - 
//  pSum				 - 	 - 
//  pQuantity			 - 	 - 
//  pRemarks			 - 	 - 
//  pChargeDetails		 - 	 - 
//  pCurrencyCode		 - 	 - 
//  pExternalSystemCode	 - 	 - 
//  pVATRate			 - 	 - 
//  pSentSms			 - 	 - 
//  pPhone				 - 	 - 
//  rCharge				 - 	 - 
// 
// Returns:
//  String - Empty string if charge was done successfully or error description 
//
Function cmChargeExternalService(pIdentifier, pServiceCode = "", pSum, pQuantity = 1, pRemarks = "", pChargeDetails = "", pCurrencyCode = "", pExternalSystemCode = "TraktirFO3", pVATRate = Undefined, pSentSms=False,pPhone = "", rCharge = Undefined) Export
	vInputParameters =  NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode + Chars.LF + 
						NStr("en='Card identifier: ';ru='Идентификатор карты: ';de='Kartenidentifikator: '") + pIdentifier + Chars.LF + 
						NStr("en='Service code: ';ru='Код услуги: ';de='Dienstleistungscode: '") + pServiceCode + Chars.LF + 
						NStr("en='Sum: ';ru='Сумма: ';de='Summe: '") + pSum + Chars.LF + 
						NStr("en='Quantity: ';ru='Количество: ';de='Anzahl: '") + pQuantity + Chars.LF + 
						NStr("en='Currency: ';ru='Валюта: ';de='Währung: '") + pCurrencyCode + Chars.LF + 
						NStr("en='Remarks: ';ru='Описание: ';de='Beschreibung: '") + pRemarks + Chars.LF + 
						NStr("en='Phone: ';ru='Телефон: ';de='Phone: '") + pPhone + Chars.LF + 
						NStr("en='Charge: ';ru='Начисление: ';de='Charge: '") + rCharge + Chars.LF +
						NStr("en = 'Sent SMS: '; de = 'Sent SMS: '; ru = 'Отправлять смс: '") + pSentSms;
	vWriteDebug = False;
	vExtSystemCode = "TraktirFO3";
	If Not IsBlankString(pExternalSystemCode) Then
		vExtSystemCode = TrimR(pExternalSystemCode);
	EndIf;
	If Not IsBlankString(vExtSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vExtSystemCode);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	vFuncLog = NStr("en='Charge external service by guest cart';ru='Начисление услуги из внешней системы по карте гостя';de='Anrechnung von Dienstleistungen aus dem externen System'");
	If vWriteDebug Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vInputParameters);
	EndIf;

	Try
		// Get card reference by card identifier
		vDiscountCard = Undefined;
		vCard = cmGetClientIdentificationCardById(pIdentifier);
		If Not ValueIsFilled(vCard) Then
			// Try to find discount card
			vDiscountCard = cmGetDiscountCardById(pIdentifier);
			If Not ValueIsFilled(vDiscountCard) Then
				vMsg = NStr("en='Client identification card was not found!';ru='Не найдена карта клиента!';de='Kundenkarte nicht gefunden!'");
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
				EndIf;
				pSentSms = False;
				Return NStr("en='Client identification card was not found!';ru='Не найдена карта клиента!';de='Kundenkarte nicht gefunden!'");
			EndIf;
			vAccommodation = cmGetDiscountCardAccommodation(vDiscountCard);
			If Not ValueIsFilled(vAccommodation) Then
				If Not ValueIsFilled(vDiscountCard.Client) Then
					vMsg = NStr("en='Card client not filled!';ru='У карты не заполнен клиент!';de='Card client not filled!'");
					If vWriteDebug Then
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
					Else
						WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
					EndIf;
					pSentSms = False;
					Return vMsg;
				EndIf;
				vAccommodation = cmGetClientAccommodation(vDiscountCard.Client);
			EndIf;
			If Not ValueIsFilled(vAccommodation) Then
				vMsg = NStr("en='Parent doc card not filled!';ru='У карты не заполнен документ основание!';de='Parent doc card not filled!'");
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
				EndIf;
				pSentSms = False;
				Return vMsg;
			EndIf;
			If vDiscountCard.IsBlocked Then
				vMsg = NStr("en='Attempt to charge by the blocked card! Operation is canceled:';ru='Попытка выполнить начисление по заблокированной карте! Операция прервана:';de='Der Versuch, die Abgrenzung von einer gesperrten Karte durchführen! Die Operation ist abgebrochen:'") + " " + TrimAll(vDiscountCard.Remarks);
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
				EndIf;
				pSentSms = False;
				Return vMsg;
			EndIf;
			vCard = New Structure("Hotel, ParentDoc, Folio, IdentificationCardType", vAccommodation.Hotel, vAccommodation, Documents.Folio.EmptyRef(), Catalogs.IdentificationCardTypes.EmptyRef());
		Else
			If ValueIsFilled(vCard.IdentificationCardType) And Not IsBlankString(vCard.IdentificationCardType.ExternalSystemsAllowed) And Not IsBlankString(pExternalSystemCode) Then
				If Find(TrimAll(vCard.IdentificationCardType.ExternalSystemsAllowed), TrimAll(pExternalSystemCode)) = 0 Then
					Return NStr("en='It is forbidden to use this card in ';ru='Использовать эту карту в ';de='Benutzen Sie diese Karte im '") + TrimAll(pExternalSystemCode) + NStr("en=' system!';ru=' запрещено!';de=' ist verboten!'");
				EndIf;
			EndIf;
			If vCard.IsBlocked Then
				vMsg = NStr("en='Attempt to charge by the blocked card! Operation is canceled:';
							|ru='Попытка выполнить начисление по заблокированной карте! Операция прервана:';
							|de='Der Versuch, die Abgrenzung von einer gesperrten Karte durchführen! Die Operation ist abgebrochen:'") + " " + TrimAll(vCard.BlockReason);
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
				EndIf;
				pSentSms = False;
				Return vMsg;
			EndIf;
		EndIf;
		// Get hotel
		vHotel = Undefined;
		If ValueIsFilled(vCard.Hotel) Then
			vHotel = vCard.Hotel;
		ElsIf ValueIsFilled(vCard.ParentDoc) Then
			vHotel = vCard.ParentDoc.Hotel;
		ElsIf ValueisFilled(vCard.Folio) Then
			vHotel = vCard.Folio.Hotel;
		EndIf;
		If Not ValueIsFilled(vHotel) Then
			vMsg = NStr("en='Hotel is not set!';ru='Не удалось определить гостиницу!';de='Das Hotel konnte nicht bestimmt werden!'");
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		vRemarks = TrimAll(pRemarks);
		// Get service to be charged by service code or hotel
		vService = Catalogs.Services.EmptyRef();
		If Upper(TrimAll(pExternalSystemCode)) = "RKEEPER" Or Upper(TrimAll(pExternalSystemCode)) = "R-KEEPER" Then
			If Not IsBlankString(vRemarks) Then
				vRestoranCode = "";
				vRestoranStartPos = Find(Lower(vRemarks), "ресторан:");
				vRestoranEndPos = 0;
				If vRestoranStartPos > 0 Then
					vRestoranEndPos = Find(Mid(vRemarks, vRestoranStartPos + 9), ";");
					If vRestoranEndPos > 0 Then
						vRestoranCode = TrimAll(Mid(vRemarks, vRestoranStartPos + 9, vRestoranEndPos - 1));
					EndIf;
				EndIf;
				vKassaCode = "";
				vKassaStartPos = Find(Lower(vRemarks), "номер кассы:");
				vKassaEndPos = 0;
				If vKassaStartPos > 0 Then
					vKassaEndPos = Find(Mid(vRemarks, vKassaStartPos + 12), ";");
					If vKassaEndPos > 0 Then
						vKassaCode = TrimAll(Mid(vRemarks, vKassaStartPos + 12, vKassaEndPos - 1));
						vKassaEndPos = vKassaStartPos + 12 + vKassaEndPos;
					EndIf;
				EndIf;
				If Not IsBlankString(vRestoranCode) Or Not IsBlankString(vKassaCode) Then
					If Not IsBlankString(vRestoranCode) And IsBlankString(vKassaCode) Then
						vService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", vRestoranCode);
					ElsIf IsBlankString(vRestoranCode) And Not IsBlankString(vKassaCode) Then
						vService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", vKassaCode);
					ElsIf Not IsBlankString(vRestoranCode) And Not IsBlankString(vKassaCode) Then
						vService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", vRestoranCode + "/" + vKassaCode);
					EndIf;
				EndIf;
				If vKassaEndPos > 0 Then
					vRemarks = Mid(vRemarks, vKassaEndPos + 1);
				EndIf;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vService) Then
			If IsBlankString(pServiceCode) Then
				vService = vHotel.CateringService;
			Else
				vService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", TrimAll(pServiceCode));
				If Not ValueIsFilled(vService) Then
					vService = cmGetServiceByCode(TrimAll(pServiceCode));
				EndIf;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vService) Then
			vService = vHotel.CateringService;
		EndIf;		
		If Not ValueIsFilled(vService) Then
			vMsg = NStr("en='Service is not set!';ru='Не удалось определить услугу!';de='Die Dienstleistung konnte nicht bestimmt werden!'");
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		// Get folio by card
		vFolio = Documents.Folio.EmptyRef();
		If ValueIsFilled(vCard.IdentificationCardType) And vCard.IdentificationCardType.DoNotUseChargingRules Then
			vFolio = vCard.Folio;
		Else
			If ValueIsFilled(vCard.ParentDoc) Then
				vCardParentDoc = vCard.ParentDoc;
				vCardFolioIsInChargingRules = False;
				If TypeOf(vCardParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCardParentDoc) = Type("DocumentRef.Reservation") Then
					vChargingRules = vCardParentDoc.ChargingRules;
					If vChargingRules.Find(vCard.Folio, "ChargingFolio") <> Undefined Then
						vCardFolioIsInChargingRules = True;
					Else
						vCardParentDocGuestGroup = vCardParentDoc.GuestGroup;
						If ValueIsFilled(vCardParentDocGuestGroup) And vCardParentDocGuestGroup.ChargingRules.Count() > 0 Then
							vCardParentDocGuestGroupChargingRules = vCardParentDocGuestGroup.ChargingRules;
							If vCardParentDocGuestGroupChargingRules.Find(vCard.Folio, "ChargingFolio") <> Undefined Then
								vCardFolioIsInChargingRules = True;
							EndIf;
						EndIf;
					EndIf;
				ElsIf TypeOf(vCardParentDoc) = Type("DocumentRef.ResourceReservation") Then
					If vCard.Folio = vCardParentDoc.ChargingFolio Then
						vCardFolioIsInChargingRules = True;
					EndIf;
				EndIf;
				If vCardFolioIsInChargingRules Then
					vFolio = cmGetDocumentChargingFolioForService(vCardParentDoc, vService, CurrentSessionDate());
				Else
					vFolio = vCard.Folio;
				EndIf;
			Else
				vFolio = vCard.Folio;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vFolio) Then
			vMsg = NStr("en='Folio is not set for the client identification card!';ru='У карты клиента не указано фолио!';de='Bei der Kundenkarte ist kein Folio angegeben!'");
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		If vFolio.DeletionMark Then
			vMsg = NStr("en='Attempt to charge to the marked for deletion folio! Operation is canceled.';ru='Попытка выполнить начисление на помеченный на удаление счет! Операция прервана.';de='Versuch, eine Einzahlung auf ein zum Löschen markiertes Konto zu tätigen! Die Operation ist abgebrochen.'");
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		If vFolio.IsClosed Then
			vMsg = NStr("en='Attempt to charge to the closed folio! Operation is canceled.';ru='Попытка выполнить начисление на закрытый счет! Операция прервана.';de='Versuch, eine Einzahlung auf ein geschlossenes Konto zu tätigen! Die Operation ist abgebrochen.'") + " N " + String(vFolio.Number);
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		vFolioParentDoc = vFolio.ParentDoc;
		If ValueIsFilled(vFolioParentDoc) And TypeOf(vFolioParentDoc) = Type("DocumentRef.Accommodation") And vFolioParentDoc.NoPost Then
			vMsg = NStr("en='Attempt to charge to the folio of the document with No post flag turned on! Operation is canceled.';ru='Попытка выполнить начисление на счет документа с включенным флагом запрета начислений! Операция прервана.';de='Es wird versucht, ein Dokument mit aktiviertem Kennzeichen für abrechnungsverbot auf ein Konto zu übertragen! Die Operation ist abgebrochen.'") + " N " + String(vFolio.Number);
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		// Check folio balance
		vLimit = 0;
		vBonusAmount = 0;
		vFolioObj = vFolio.GetObject();
		vBalance = vFolioObj.pmGetBalance('39991231235959', , Undefined, vLimit);
		If ValueIsFilled(vFolioObj.Client) Then
			vBonus = 0;
			vBonusAmount = vFolioObj.Client.GetObject().pmGetBonusesAmount(vFolioObj.Hotel, vFolioObj.FolioCurrency, vDiscountCard, vBonus);
		EndIf;
		If pSum <> 0 And (vBalance + pSum) > (vFolio.CreditLimit + vBonusAmount) And Not vHotel.NoCreditLimit Then
			vMsg = NStr("en='Sum of charge amount with folio debt is greater then folio credit limit! Operation is canceled.'; 
			             |de='Sum of charge amount with folio debt is greater then folio credit limit! Operation is canceled.'; 
			             |ru='После начисления услуги долг на лицевом счете " + cmFormatSum((vBalance + pSum), vFolio.FolioCurrency) + " превысит установленную глубину кредита " + cmFormatSum(vFolio.CreditLimit + vBonusAmount, vFolio.FolioCurrency) + "! Операция прервана.'");
			
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;		
		// Create charge document
		vChargeObj = Documents.Charge.CreateDocument();
		vChargeObj.pmFillAttributesWithDefaultValues();
		If ValueIsFilled(vFolio.Hotel) Then
			If vChargeObj.Hotel <> vFolio.Hotel Then
				vChargeObj.Hotel = vFolio.Hotel;
				vChargeObj.SetNewNumber(Catalogs.Hotels.pmGetPrefix(vChargeObj.Hotel));
			EndIf;
		EndIf;
		If Not ValueIsFilled(vChargeObj.Hotel) Then
			vMsg = NStr("en='Hotel is not set!';ru='Не удалось установить гостиницу у документа начисление!';de='Das Hotel konnte nicht festgelegt werden!'");
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		// Get currency by code
		vCurrency = Catalogs.Currencies.EmptyRef();
		If Not IsBlankString(pCurrencyCode) Then
			vCurrency = cmGetObjectRefByExternalSystemCode(vChargeObj.Hotel, pExternalSystemCode, "Currencies", pCurrencyCode);
		EndIf;
		// VAT rate may come from interface
		vVATRate = Catalogs.VATRates.EmptyRef();
		If pVATRate <> Undefined Then
			vQ = New Query("SELECT
			               |	VATRates.Ref AS Ref
			               |FROM
			               |	Catalog.VATRates AS VATRates
			               |WHERE
			               |	VATRates.TaxRate = &qTaxRate
			               |	AND NOT VATRates.DeletionMark");
			vQ.SetParameter("qTaxRate", pVATrate);
			vQRes = vQ.Execute().Select();
			If vQRes.Next() Then
				vVATRate = vQRes.Ref;
			EndIf;			
		EndIf;
		If vVATRate = Catalogs.VATRates.EmptyRef() Then
			If ValueIsFilled(vFolio.Company) Then
				vVATRate = vFolio.Company.VATRate;
			EndIf;
			vServicePrices = vService.GetObject().pmGetServicePrices(vFolio.Hotel, CurrentSessionDate());
			If vServicePrices.Count() > 0 Then
				vVATRate = vServicePrices.Get(0).VATRate;
			EndIf;
		EndIf;		
		If ValueIsFilled(vFolio.Company) And vFolio.Company.IsUsingSimpleTaxSystem Then
			vVATRate = vFolio.Company.VATRate;
		EndIf;
		// Post this document
		vChargeObj.ParentDoc = vFolio.ParentDoc;
		vChargeObj.IsFixedCharge = False;
		vChargeObj.Hotel = vFolio.Hotel;
		If ValueIsFilled(vFolio.ParentDoc) And TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation") And
			ValueIsFilled(vFolio.ParentDoc.ExchangeRateDate) And 
			ValueIsFilled(vChargeObj.Service) And ValueIsFilled(vChargeObj.Service.ServiceType) And 
			vChargeObj.Service.ServiceType.ActualAmountIsChargedExternally Then
			vChargeObj.ExchangeRateDate = vFolio.ParentDoc.ExchangeRateDate;
		EndIf;
		vChargeObj.FolioCurrency = vFolio.FolioCurrency;
		vChargeObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.FolioCurrency, vChargeObj.ExchangeRateDate);
		vChargeObj.ReportingCurrency = vFolio.Hotel.ReportingCurrency;
		vChargeObj.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.ReportingCurrency, vChargeObj.ExchangeRateDate);
		vChargeObj.Folio = vFolio;
		vChargeObj.Service = vService;
		vChargeObj.PaymentSection = vChargeObj.Service.PaymentSection;
		// Discounts
		vParentDoc = vChargeObj.ParentDoc;
		If ValueIsFilled(vParentDoc) Then
			If ValueIsFilled(vParentDoc.DiscountType) And Not vParentDoc.DiscountType.DoNotApplyToExternalInterfaces Or 
				Not ValueIsFilled(vParentDoc.DiscountType) And vParentDoc.Discount <> 0 Then
				vChargeObj.DiscountCard = vParentDoc.DiscountCard;
				vChargeObj.DiscountType = vParentDoc.DiscountType;
				vChargeObj.DiscountConfirmationText = vParentDoc.DiscountConfirmationText;
				vChargeObj.Discount = vParentDoc.Discount;
				vChargeObj.DiscountServiceGroup = vParentDoc.DiscountServiceGroup;
			EndIf;
		Else
			If ValueIsFilled(vFolio.FolioDiscountType) And Not vFolio.FolioDiscountType.DoNotApplyToExternalInterfaces Then
				vChargeObj.DiscountCard = vFolio.FolioDiscountCard;
				vChargeObj.DiscountType = vFolio.FolioDiscountType;
				vChargeObj.DiscountConfirmationText = "";
				If ValueIsFilled(vChargeObj.DiscountType) Then
					vChargeObj.DiscountConfirmationText = vChargeObj.DiscountType.ConfirmationPattern;
					vChargeObj.DiscountServiceGroup = vChargeObj.DiscountType.DiscountServiceGroup;
				EndIf;
				If Not vChargeObj.DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					vChargeObj.Discount = vChargeObj.DiscountType.GetObject().pmGetDiscount(vChargeObj.Date, vChargeObj.Service, vChargeObj.Hotel);
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vChargeObj.DiscountType) Then
			If vChargeObj.DiscountType.IsAccumulatingDiscount Then
				vChargeObj.pmCalculateAccumulationDiscount();
			ElsIf vChargeObj.DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
				vChargeObj.Discount = vChargeObj.DiscountType.GetObject().pmGetDiscount(vChargeObj.Date, vChargeObj.Service, vChargeObj.Hotel);
			EndIf;
		EndIf;
		// Amount
		vSum = Number(pSum);
		vQuantity = Number(pQuantity);
		vQuantity = ?(vQuantity = 0, 1, vQuantity);
		If vSum < 0 And vQuantity > 0 Then
			vQuantity = -vQuantity;
		EndIf;
		If Not ValueIsFilled(vCurrency) Or vCurrency = vChargeObj.FolioCurrency Then
			vChargeObj.Price = cmRecalculatePrice(vSum, vQuantity);
		Else
			vSum = cmExtConvertCurrencies(vSum, vCurrency, , vChargeObj.FolioCurrency, vChargeObj.FolioCurrencyExchangeRate, vChargeObj.ExchangeRateDate, vChargeObj.Hotel, pExternalSystemCode);
			vChargeObj.Price = cmRecalculatePrice(vSum, vQuantity);
		EndIf;
		vChargeObj.Unit = vService.Unit;
		vChargeObj.Quantity = vQuantity;
		vChargeObj.Sum = vSum;
		vChargeObj.VATRate = vVATRate;
		vChargeObj.VATSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.Sum, vChargeObj.Date);
		vChargeObj.Remarks = TrimAll(vRemarks);
		vChargeObj.IsRoomRevenue = vService.IsRoomRevenue;
		vChargeObj.Company = vFolio.Company;
		vChargeObj.IsAdditional = True;
		vChargeObj.Details = TrimAll(pChargeDetails);
		// Discount amount
		vChargeObj.DiscountSum = 0;
		vChargeObj.VATDiscountSum = 0;
		If ValueIsFilled(vChargeObj.Service) Then
			If cmIsServiceInServiceGroup(vChargeObj.Service, vChargeObj.DiscountServiceGroup) Then
				If Not ValueIsFilled(vChargeObj.DiscountType) 
					Or ValueIsFilled(vChargeObj.DiscountType) 
					And (Not vChargeObj.DiscountType.IsForRackRatesOnly Or vChargeObj.DiscountType.IsForRackRatesOnly And ValueIsFilled(vChargeObj.RoomRate) 
					And vChargeObj.RoomRate.IsRackRate Or vChargeObj.IsAdditional) Then
					vChargeObj.DiscountSum = Round(vChargeObj.Sum * vChargeObj.Discount / 100, 2);
					vChargeObj.VATDiscountSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.DiscountSum, vChargeObj.Date);
				EndIf;
			EndIf;
		EndIf;
		// Write and post document
		vChargeObj.Write(DocumentWriteMode.Posting);
		rCharge = vChargeObj.Ref;
        
		// Send SMS
		If pSentSms Then
			vSMSTamlate = GetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "SMSTemplates", TrimAll(pServiceCode));
			If Not vSMSTamlate = Undefined And ValueIsFilled(vSMSTamlate) Then
				WriteLogEvent(NStr("en='Charge service';ru='Начисление услуги';de='Anrechnung der Dienstleistung'"), EventLogLevel.Information, , , 
								"Найден шаблон " + vSMSTamlate.Description + " по коду услуги: " + TrimAll(pServiceCode));
				vCharge =  vChargeObj.Ref;
				vGuestUUID = SMS.GetMyFolioGuestIdByClient(vCharge.Folio.Client);
				If IsBlankString(vGuestUUID) Then
					pSentSms = False;
				Else	
					vError = "";
					If Not SMS.SendChargeMessage(vCharge,vSMSTamlate,vCharge.Folio.Client,vError,pPhone) Then
						WriteLogEvent(NStr("en='Charge room service';ru='Начисление услуги по номеру комнаты';de='Anrechnung der Dienstleistung nach Zimmernummer'"), EventLogLevel.Error, , , 
							NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + vError);
						pSentSms = False;
					EndIf;	
				EndIf;
			Else
				vMsg = NStr("en='SMS template not found for service: ';ru='Не найден шаблон по коду услуги для отправки смс: ';de='SMS template not found for service: '") + TrimAll(pServiceCode);
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , , vMsg, vInteraction.MaxLogLenght);
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vMsg);
				EndIf;
				pSentSms = False;
			EndIf;
		EndIf;

		vMsg = NStr("en='Charge was posted - OK!';ru='Транзакция записана в БД!';de='Transaktion ist in die Datenbank eingetragen!'");
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , , vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vMsg);
		EndIf;
	Except
		vMsg = NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + ErrorDescription();
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , , vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vMsg);
		EndIf;
		pSentSms = False;
		Return vMsg;
	EndTry;
	Return "";
EndFunction // cmChargeExternalService

// -----------------------------------------------------------------------------
// Searches folio by it's number
// -----------------------------------------------------------------------------
Function cmFindFolioByNumber(pFolioNumber, pHotel) Export
	vFolioNumber = TrimR(cmGetDocumentNumberFromPresentation(pFolioNumber, pHotel));
	vFolio = Documents.Folio.FindByNumber(vFolioNumber);
	If Not ValueIsFilled(vFolio) Then
		// Extract folio prefix and try to find folio with different prefix but with the same number
		vFolioNumberPart = "";
		vNumberLen = 0;
		vFolioNumberLen = StrLen(vFolioNumber);
		For i = 0 To (vFolioNumberLen - 1) Do
			vChar = Mid(vFolioNumber, (vFolioNumberLen - i), 1);
			If Not cmIsNumber(vChar) Then
				Break;
			Else
				vNumberLen = vNumberLen + 1;
			EndIf;
		EndDo;
		If vNumberLen > 0 Then
			vFolioNumberPart = Right(vFolioNumber, vNumberLen);
		EndIf;
		If Not IsBlankString(vFolioNumberPart) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Folio.Ref AS Ref
			|FROM
			|	Document.Folio AS Folio
			|WHERE
			|	Folio.Number LIKE &qFolioNumber
			|	AND Folio.Hotel = &qHotel
			|	AND NOT Folio.DeletionMark";
			vQry.SetParameter("qHotel", pHotel);
			vQry.SetParameter("qFolioNumber", "%" + vFolioNumberPart);
			vFolios = vQry.Execute().Unload();
			If vFolios.Count() = 1 Then
				vFolio = vFolios.Get(0).Ref;
			EndIf;
		EndIf;
	EndIf;				
	Return vFolio;
EndFunction // cmFindFolioByNumber

// -----------------------------------------------------------------------------
Function GetObjectRefByExternalSystemCode(pHotelRef, pExternalSystemCode, pObjectTypeName, pObjectExternalCode)
	vObjectRef = Undefined;
	// Try to find reference to the object in the program by external code
	If Not IsBlankString(pExternalSystemCode) And Not IsBlankString(pObjectExternalCode) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
		|	AND ExternalSystemsObjectCodesMappings.ObjectExternalCode = &qObjectExternalCode";
		vQry.SetParameter("qHotel", pHotelRef);
		vQry.SetParameter("qExternalSystemCode", TrimAll(pExternalSystemCode));
		vQry.SetParameter("qObjectTypeName", TrimAll(pObjectTypeName));
		vQry.SetParameter("qObjectExternalCode", TrimAll(pObjectExternalCode));
		vObjects = vQry.Execute().Unload();
		If vObjects.Count() = 1 Then
			vObjectRef = vObjects.Get(0).ObjectRef;
		EndIf;
	EndIf;
	Return vObjectRef;
EndFunction

// -----------------------------------------------------------------------------
//  Charges service by folio number.
//
// Parameters:
//  pFolioNumber			 - 	 - 
//  pServiceCode			 - 	 - 
//  pSum					 - 	 - 
//  pQuantity				 - 	 - 
//  pRemarks				 - 	 - 
//  pChargeDetails			 - 	 - 
//  pHotelCode				 - 	 - 
//  pExternalSystemCode		 - 	 - 
//  pCurrencyCode			 - 	 - 
//  pVATRate				 - 	 - 
//  pSentSms				 - 	 - 
//  pPhone					 - 	 - 
//  pDoNotCheckCreditLimit	 - 	 - 
//  rCharge					 - 	 - 
//  pClientTypeCode			 - 	 - 
// 
// Returns:
//  String - Empty string if charge was done successfully or error description
//
Function cmChargeExternalServiceByFolio(pFolioNumber, pServiceCode = "", pSum, pQuantity = 1, pRemarks = "", pChargeDetails = "", pHotelCode = "", pExternalSystemCode = "TraktirFO3", pCurrencyCode = "", pVATRate = Undefined, pSentSms = False, pPhone = "", pDoNotCheckCreditLimit = False, rCharge = Undefined, pClientTypeCode = "") Export
	vInputParameters = NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode + Chars.LF + 
						NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + pHotelCode + Chars.LF + 
						NStr("en='Folio number: ';ru='Номер фолио: ';de='Folionummer: '") + pFolioNumber + Chars.LF + 
						NStr("en='Service code: ';ru='Код услуги: ';de='Dienstleistungscode: '") + pServiceCode + Chars.LF + 
						NStr("en='Sum: ';ru='Сумма: ';de='Summe: '") + pSum + Chars.LF + 
						NStr("en='Quantity: ';ru='Количество: ';de='Anzahl: '") + pQuantity + Chars.LF + 
						NStr("en='Currency: ';ru='Валюта: ';de='Währung: '") + pCurrencyCode + Chars.LF + 
						NStr("en='Remarks: ';ru='Описание: ';de='Beschreibung: '") + pRemarks + Chars.LF + 
						NStr("en='Details: ';ru='Детали: ';de='Details: '") + pChargeDetails + Chars.LF +
						NStr("en='Client type: ';ru='Тип клиента: ';de='Kundetyp: '") + pClientTypeCode + Chars.LF +
						NStr("en='Sent SMS: ';de='Sent SMS: ';ru='Отправлять смс: '") + pSentSms;
	vWriteDebug = False;
	vExtSystemCode = "TraktirFO3";
	If Not IsBlankString(pExternalSystemCode) Then
		vExtSystemCode = TrimR(pExternalSystemCode);
	EndIf;
	vHotel = cmGetHotelByCode(pHotelCode, vExtSystemCode);
	If Not IsBlankString(vExtSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vExtSystemCode, vHotel);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	vFuncLog = NStr("en='Charge external service by folio';ru='Начисление услуги из внешней системы по лицевому счету';de='Anrechnung von Dienstleistungen aus dem externen System nach dem Personenkonto'");
	If vWriteDebug Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vInputParameters);
	EndIf;

	Try
		// Get hotel
		vHotel = SessionParameters.CurrentHotel;
		If Not IsBlankString(pHotelCode) Then
			vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
		EndIf;
		// Get currency by code
		vCurrency = Catalogs.Currencies.EmptyRef();
		If Not IsBlankString(pCurrencyCode) Then
			vCurrency = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Currencies", pCurrencyCode);
		EndIf;
		// Get client type by code
		vClientType = Catalogs.ClientTypes.EmptyRef();
		If Not IsBlankString(pClientTypeCode) Then
			vClientType = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "ClientTypes", pClientTypeCode);
		EndIf;
		// Get folio reference by folio number
		vFolio = cmFindFolioByNumber(pFolioNumber, vHotel);
		If Not ValueIsFilled(vFolio) Then
			vMsg = NStr("en='Folio was not found!';ru='Фолио не найдено по номеру!';de='Folio wurde nach der Nummer nicht gefunden!'") + pFolioNumber;
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		If ValueIsFilled(vFolio.Hotel) Then
			vHotel = vFolio.Hotel;
		EndIf;
		If vFolio.DeletionMark Then
			vMsg = NStr("en='Attempt to charge to the marked for deletion folio! Operation is canceled.';
						|ru='Попытка выполнить начисление на помеченный на удаление счет! Операция прервана.';
						|de='Versuch, eine Einzahlung auf ein zum Löschen markiertes Konto zu tätigen! Die Operation ist abgebrochen.'");
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		If vFolio.IsClosed Then
			If Not (ValueIsFilled(vFolio.ParentDoc) And TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) Then
				vMsg = NStr("en='Attempt to charge to the closed folio resource reservation! Operation is canceled.';
							|ru='Попытка выполнить начисление на закрытый лицевой счет брони ресурсов! Операция прервана.';
							|de='Versuch, eine Einzahlung auf ein zum Löschen markiertes Konto zu tätigen! Die Operation ist abgebrochen.'");
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
				EndIf;
				pSentSms = False;
				Return vMsg;
			Else
				If (BegOfDay(CurrentSessionDate()) - BegOfDay(vFolio.ParentDoc.DateTimeTo)) > (24 * 3600) Then
					vMsg = NStr("en = 'Attempt to charge to the closed folio after 24 hours! Operation is canceled.'; 
								|de = 'Versuch, eine Einzahlung auf ein geschlossenes Konto zu tätigen! Die Operation ist abgebrochen.'; 
								|ru = 'Попытка выполнить начисление на закрытый лицевой счет, дата выезда превышает 24 часа! Операция прервана.'");
					If vWriteDebug Then
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
					Else
						WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
					EndIf;
					pSentSms = False;
					Return vMsg;
				EndIf;
			EndIf;
		EndIf;
		vFolioParentDoc = vFolio.ParentDoc;
		If ValueIsFilled(vFolioParentDoc) And TypeOf(vFolioParentDoc) = Type("DocumentRef.Accommodation") And vFolioParentDoc.NoPost Then
			vMsg = NStr("en='Attempt to charge to the folio of the document with No post flag turned on! Operation is canceled.';
						|ru='Попытка выполнить начисление на счет документа с включенным флагом запрета начислений! Операция прервана.';
						|de='Es wird versucht, ein Dokument mit aktiviertem Kennzeichen für abrechnungsverbot auf ein Konto zu übertragen! Die Operation ist abgebrochen.'") + " N " + String(vFolio.Number);
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		// Create charge document
		vChargeObj = Documents.Charge.CreateDocument();
		vChargeObj.pmFillAttributesWithDefaultValues();
		If ValueIsFilled(vFolio.Hotel) Then
			If vChargeObj.Hotel <> vFolio.Hotel Then
				vChargeObj.Hotel = vFolio.Hotel;
				vChargeObj.SetNewNumber(Catalogs.Hotels.pmGetPrefix(vChargeObj.Hotel));
			EndIf;
		EndIf;
		If Not ValueIsFilled(vChargeObj.Hotel) Then
			vMsg = NStr("en='Hotel is not set!';ru='Не удалось установить гостиницу!';de='Das Hotel konnte nicht festgelegt werden!'");
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		// Get service to be charged by service code or hotel
		vService = Catalogs.Services.EmptyRef();
		If IsBlankString(pServiceCode) Then
			vService = vChargeObj.Hotel.CateringService;
		Else
			vService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", TrimAll(pServiceCode));
			If Not ValueIsFilled(vService) Then
				vService = cmGetServiceByCode(TrimAll(pServiceCode));
			EndIf;
		EndIf;
		If Not ValueIsFilled(vService) Then
			vService = vChargeObj.Hotel.CateringService;
		EndIf;		
		If Not ValueIsFilled(vService) Then
			vMsg = NStr("en='Service is not set!';ru='Не удалось определить услугу!';de='Die Dienstleistung konnte nicht bestimmt werden!'");
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		// VAT rate may come from interface
		vVATRate = Catalogs.VATRates.EmptyRef();
		If pVATRate <> Undefined Then
			vQ = New Query("SELECT
			               |	VATRates.Ref AS Ref
			               |FROM
			               |	Catalog.VATRates AS VATRates
			               |WHERE
			               |	VATRates.TaxRate = &qTaxRate
			               |	AND NOT VATRates.DeletionMark");
			vQ.SetParameter("qTaxRate", pVATrate);
			vVATRates = vQ.Execute().Unload();
			If vVATRates.Count() = 1 Then
				vVATRate = vVATRates.Get(0).Ref;
			EndIf;
		EndIf;
		If vVATRate = Catalogs.VATRates.EmptyRef() Then
			If ValueIsFilled(vFolio.Company) Then
				vVATRate = vFolio.Company.VATRate;
			EndIf;
			vServicePrices = vService.GetObject().pmGetServicePrices(vFolio.Hotel, CurrentSessionDate(), vClientType);
			If vServicePrices.Count() > 0 Then
				vVATRate = vServicePrices.Get(0).VATRate;
			EndIf;
		EndIf;
		If ValueIsFilled(vFolio.Company) And vFolio.Company.IsUsingSimpleTaxSystem Then
			vVATRate = vFolio.Company.VATRate;
		EndIf;
		// Fill change attributes
		vChargeObj.ParentDoc = vFolio.ParentDoc;
		vChargeObj.IsFixedCharge = False;
		vChargeObj.Hotel = vFolio.Hotel;
		vChargeObj.Folio = vFolio;
		vChargeObj.ClientType = vClientType;
		vChargeObj.Service = vService;
		vChargeObj.PaymentSection = vChargeObj.Service.PaymentSection;
		If ValueIsFilled(vFolio.ParentDoc) Then
			vFolioParentDoc = vFolio.ParentDoc;
			If TypeOf(vFolioParentDoc) = Type("DocumentRef.ResourceReservation") And ValueIsFilled(vFolioParentDoc.ExchangeRateDate) And 
			   ValueIsFilled(vChargeObj.Service) And ValueIsFilled(vChargeObj.Service.ServiceType) And 
			   vChargeObj.Service.ServiceType.ActualAmountIsChargedExternally Then
				vChargeObj.ExchangeRateDate = vFolioParentDoc.ExchangeRateDate;
			EndIf;
			If TypeOf(vFolioParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolioParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolioParentDoc) = Type("DocumentRef.ResourceReservation") Then
				If vChargeObj.MarketingCode <> vFolioParentDoc.MarketingCode Then
					vChargeObj.MarketingCode = vFolioParentDoc.MarketingCode;
					vChargeObj.MarketingCodeConfirmationText = vFolioParentDoc.MarketingCodeConfirmationText;
				EndIf;
				If vChargeObj.SourceOfBusiness <> vFolioParentDoc.SourceOfBusiness Then
					vChargeObj.SourceOfBusiness = vFolioParentDoc.SourceOfBusiness;
				EndIf;
			EndIf;
		EndIf;
		vChargeObj.FolioCurrency = vFolio.FolioCurrency;
		vChargeObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.FolioCurrency, vChargeObj.ExchangeRateDate);
		vChargeObj.ReportingCurrency = vFolio.Hotel.ReportingCurrency;
		vChargeObj.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.ReportingCurrency, vChargeObj.ExchangeRateDate);
		vSum = Number(pSum);
		vQuantity = Number(pQuantity);
		vQuantity = ?(vQuantity = 0, 1, vQuantity);
		If vSum < 0 And vQuantity > 0 Then
			vQuantity = -vQuantity;
		EndIf;
		If Not ValueIsFilled(vCurrency) Or vCurrency = vChargeObj.FolioCurrency Then
			vChargeObj.Price = cmRecalculatePrice(vSum, vQuantity);
		Else
			vSum = cmExtConvertCurrencies(vSum, vCurrency, , vChargeObj.FolioCurrency, vChargeObj.FolioCurrencyExchangeRate, vChargeObj.ExchangeRateDate, vHotel, pExternalSystemCode);
			vChargeObj.Price = cmRecalculatePrice(vSum, vQuantity);
		EndIf;
		// Check folio balance
		If vSum > 0 And Not pDoNotCheckCreditLimit And (Not ValueIsFilled(vFolio.ParentDoc) Or ValueIsFilled(vFolio.ParentDoc) And TypeOf(vFolio.ParentDoc) <> Type("DocumentRef.ResourceReservation")) Then 
			vLimit = 0;
			vFolioObj = vFolio.GetObject();
			vBalance = vFolioObj.pmGetBalance('39991231235959', , Undefined, vLimit);
			If vSum <> 0 And (vBalance + vSum) > vFolio.CreditLimit And Not vHotel.NoCreditLimit Then
				vMsg = NStr("en='Sum of charge amount with folio debt is greater then folio credit limit! Operation is canceled.'; 
				             |de='Sum of charge amount with folio debt is greater then folio credit limit! Operation is canceled.'; 
				             |ru='После начисления услуги долг на лицевом счете " + cmFormatSum((vBalance + vSum), vFolio.FolioCurrency) + " превысит установленную глубину кредита " + cmFormatSum(vFolio.CreditLimit, vFolio.FolioCurrency) + "! Операция прервана.'");
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
				EndIf;
				pSentSms = False;
				Return vMsg;
			EndIf;		
		EndIf;		
		vChargeObj.Unit = vService.Unit;
		vChargeObj.Quantity = vQuantity;
		vChargeObj.Sum = vSum;
		vChargeObj.VATRate = vVATRate;
		vChargeObj.VATSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.Sum, vChargeObj.Date);
		vChargeObj.Remarks = TrimAll(pRemarks);
		vChargeObj.IsRoomRevenue = vService.IsRoomRevenue;
		vChargeObj.Company = vFolio.Company;
		vChargeObj.IsAdditional = True;
		vChargeObj.Details = TrimAll(pChargeDetails);
		// Discounts
		vParentDoc = vChargeObj.ParentDoc;
		If ValueIsFilled(vParentDoc) Then
			If ValueIsFilled(vParentDoc.DiscountType) And Not vParentDoc.DiscountType.DoNotApplyToExternalInterfaces Or 
				Not ValueIsFilled(vParentDoc.DiscountType) And vParentDoc.Discount <> 0 Then
				vChargeObj.DiscountCard = vParentDoc.DiscountCard;
				vChargeObj.DiscountType = vParentDoc.DiscountType;
				vChargeObj.DiscountConfirmationText = vParentDoc.DiscountConfirmationText;
				vChargeObj.Discount = vParentDoc.Discount;
				vChargeObj.DiscountServiceGroup = vParentDoc.DiscountServiceGroup;
			EndIf;
		Else
			If ValueIsFilled(vFolio.FolioDiscountType) And Not vFolio.FolioDiscountType.DoNotApplyToExternalInterfaces Then
				vChargeObj.DiscountCard = vFolio.FolioDiscountCard;
				vChargeObj.DiscountType = vFolio.FolioDiscountType;
				vChargeObj.DiscountConfirmationText = "";
				If ValueIsFilled(vChargeObj.DiscountType) Then
					vChargeObj.DiscountConfirmationText = vChargeObj.DiscountType.ConfirmationPattern;
					vChargeObj.DiscountServiceGroup = vChargeObj.DiscountType.DiscountServiceGroup;
				EndIf;
				If Not vChargeObj.DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					vChargeObj.Discount = vChargeObj.DiscountType.GetObject().pmGetDiscount(vChargeObj.Date, vChargeObj.Service, vChargeObj.Hotel);
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vChargeObj.DiscountType) Then
			If vChargeObj.DiscountType.IsAccumulatingDiscount Then
				vChargeObj.pmCalculateAccumulationDiscount();
			ElsIf vChargeObj.DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
				vChargeObj.Discount = vChargeObj.DiscountType.GetObject().pmGetDiscount(vChargeObj.Date, vChargeObj.Service, vChargeObj.Hotel);
			EndIf;
		EndIf;
		// Discount amount
		vChargeObj.DiscountSum = 0;
		vChargeObj.VATDiscountSum = 0;
		If ValueIsFilled(vChargeObj.Service) Then
			If cmIsServiceInServiceGroup(vChargeObj.Service, vChargeObj.DiscountServiceGroup) Then
				If Not ValueIsFilled(vChargeObj.DiscountType) Or 
				   ValueIsFilled(vChargeObj.DiscountType) And (Not vChargeObj.DiscountType.IsForRackRatesOnly Or 
				                                               vChargeObj.DiscountType.IsForRackRatesOnly And ValueIsFilled(vChargeObj.RoomRate) And vChargeObj.RoomRate.IsRackRate Or
															   vChargeObj.IsAdditional) Then
					vChargeObj.DiscountSum = Round(vChargeObj.Sum * vChargeObj.Discount / 100, 2);
					vChargeObj.VATDiscountSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.DiscountSum, vChargeObj.Date);
				EndIf;
			EndIf;
		EndIf;
		// Resource
		If ValueIsFilled(vChargeObj.Service) And ValueIsFilled(vChargeObj.Service.Resource) Then
			vChargeObj.Resource = vChargeObj.Service.Resource;
		EndIf;
		// Write and post document
		vChargeObj.Write(DocumentWriteMode.Posting);
		
		rCharge = vChargeObj.Ref;
		
		// Send SMS
		If pSentSms Then
			vSMSTamlate = GetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "SMSTemplates", TrimAll(pServiceCode));
			If Not vSMSTamlate = Undefined And ValueIsFilled(vSMSTamlate) Then
				WriteLogEvent(NStr("en = 'Charge service'; de = 'Anrechnung der Dienstleistung'; ru = 'Начисление услуги'"), EventLogLevel.Information, , , "Найден шаблон " + vSMSTamlate.Description + " по коду услуги: " + TrimAll(pServiceCode));
				vCharge =  vChargeObj.Ref;
				vGuestUUID = SMS.GetMyFolioGuestIdByClient(vCharge.Folio.Client);
				If IsBlankString(vGuestUUID) Then
					pSentSms = False;
				Else	
					vError = "";
					If Not SMS.SendChargeMessage(vCharge,vSMSTamlate,vCharge.Folio.Client,vError,pPhone) Then
						vMsg = NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + vError;
						If vWriteDebug Then
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
						Else
							WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
						EndIf;
						pSentSms = False;
					EndIf;	
				EndIf;
			Else
				vMsg = NStr("en='SMS template not found for service: ';ru='Не найден шаблон по коду услуги для отправки смс: ';de='SMS template not found for service: '") + TrimAll(pServiceCode);
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , , vMsg, vInteraction.MaxLogLenght);
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vMsg);
				EndIf;
				pSentSms = False;
			EndIf;
		EndIf;

		vMsg = NStr("en='Charge was posted - OK!';ru='Транзакция записана в БД!';de='Transaktion ist in die Datenbank eingetragen!'");
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , , vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vMsg);
		EndIf;
	Except
		vMsg = NStr("en = 'Error description: '; de = 'Fehlerbeschreibung: '; ru = 'Описание ошибки: '") + ErrorDescription();
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , , vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vMsg);
		EndIf;
		pSentSms = False;
		Return vMsg;
	EndTry;
	Return "";
EndFunction // cmChargeExternalServiceByFolio

// -----------------------------------------------------------------------------
//  Charges service by room code.
//
// Parameters:
//  pRoomCode				 - 	 - 
//  pOrderTime				 - 	 - 
//  pSum					 - 	 - 
//  pClientCode				 - 	 - 
//  pCurrencyCode			 - 	 - 
//  pServiceCode			 - 	 - 
//  pQuantity				 - 	 - 
//  pChargeType				 - 	 - 
//  pRemarks				 - 	 - 
//  pChargeDetails			 - 	 - 
//  pHotelName				 - 	 - 
//  pExternalSystemCode		 - 	 - 
//  pVATrate				 - 	 - 
//  pExtCode				 - 	 - 
//  rRoomServiceRef			 - 	 - 
//  pSentSms				 - 	 - 
//  pPhone					 - 	 - 
//  pDoNotCheckCreditLimit	 - 	 - 
//  rCharge					 - 	 - 
//  pClientTypeCode			 - 	 - 
// 
// Returns:
//  String - Empty string if charge was done successfully or error description 
//
Function cmChargeRoomService(pRoomCode, pOrderTime, pSum, pClientCode = "", pCurrencyCode = "", pServiceCode = "", pQuantity = 1, pChargeType = "", pRemarks = "", pChargeDetails = "", pHotelName = "", pExternalSystemCode = "TraktirFO3", pVATrate = Undefined, pExtCode = "", rRoomServiceRef = Undefined, pSentSms = False, pPhone = "", pDoNotCheckCreditLimit = False, rCharge = Undefined, pClientTypeCode = "") Export
	vInputParameters = NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode + Chars.LF + 
						NStr("en='Hotel name: ';ru='Гостиница: ';de='Hotel: '") + pHotelName + Chars.LF + 
						NStr("en='Room code: ';ru='Номер комнаты: ';de='Zimmernummer: '") + pRoomCode + Chars.LF + 
						NStr("en='Order date and time: ';ru='Дата и время заказа: ';de='Datum und Zeit der Bestellung: '") + pOrderTime + Chars.LF + 
						NStr("en='Client code: ';ru='Код клиента: ';de='Kundencode: '") + pClientCode + Chars.LF + 
						NStr("en='Currency code: ';ru='Код валюты: ';de='Währungscode: '") + pCurrencyCode + Chars.LF + 
						NStr("en='Service code: ';ru='Код услуги: ';de='Dienstleistungscode: '") + pServiceCode + Chars.LF + 
						NStr("en='Sum: ';ru='Сумма: ';de='Summe: '") + pSum + Chars.LF + 
						NStr("en='Quantity: ';ru='Количество: ';de='Anzahl: '") + pQuantity + Chars.LF + 
						NStr("en='Charge type: ';ru='Тип начисления: ';de='Art der Berechnung: '") + pChargeType + Chars.LF + 
						NStr("en='Remarks: ';ru='Описание: ';de='Beschreibung: '") + pRemarks + Chars.LF + 
						NStr("en='Details: ';ru='Детали: ';de='Details: '") + pChargeDetails + Chars.LF +
						NStr("en='Client type: ';ru='Тип клиента: ';de='Kundetyp: '") + pClientTypeCode + Chars.LF +
						NStr("en='Sent SMS: ';de='Sent SMS: ';ru='Отправлять смс: '") + pSentSms;
	vWriteDebug = False;
	vExtSystemCode = "TraktirFO3";
	If Not IsBlankString(pExternalSystemCode) Then
		vExtSystemCode = TrimR(pExternalSystemCode);
	EndIf;
	vHotel = cmGetHotelByCode(pHotelName, vExtSystemCode);
	If Not IsBlankString(vExtSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vExtSystemCode, vHotel);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	vFuncLog = NStr("en='Charge room service';ru='Начисление услуги по номеру комнаты';de='Anrechnung der Dienstleistung nach Zimmernummer'");
	If vWriteDebug Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vInputParameters);
	EndIf;
					
	rRoomServiceRef = Undefined;
	Try
		// Get room by room code
		vRoom = Catalogs.Rooms.EmptyRef();
		If Not IsBlankString(pRoomCode) Then
			vRoom = cmGetRoomByCode(pRoomCode, pHotelName, pExternalSystemCode);
		EndIf;
		If Not ValueIsFilled(vRoom) Then
			vMsg =  NStr("en='Room is not set!';ru='Не удалось определить номер!';de='Die Nummer konnte nicht bestimmt werden!'");
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		vHotel = vRoom.Owner;
		
		// Get client type by code
		vClientType = Catalogs.ClientTypes.EmptyRef();
		If Not IsBlankString(pClientTypeCode) Then
			vClientType = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "ClientTypes", pClientTypeCode);
		EndIf;
		
		// Create new interface document object
		vRoomServiceRef = Documents.RecordRoomService.EmptyRef();
		If Not IsBlankString(pExtCode) Then
			vQ = New Query("SELECT
			               |	RecordRoomService.Ref AS Ref
			               |FROM
			               |	Document.RecordRoomService AS RecordRoomService
			               |WHERE
			               |	NOT RecordRoomService.DeletionMark
			               |	AND RecordRoomService.ExternalCode = &qExternalCode");
			vQ.SetParameter("qExternalCode",pExtCode);
			qRes = vQ.Execute().Select();
			If qRes.Next() Then
				vRoomServiceRef = qRes.Ref;
			Else
				vRoomServiceRef = Documents.RecordRoomService.EmptyRef();
			EndIf;
		EndIf;
		If vRoomServiceRef = Documents.RecordRoomService.EmptyRef() Then
			vRoomServiceObj = Documents.RecordRoomService.CreateDocument();
		Else
			vRoomServiceObj = vRoomServiceRef.GetObject();
		EndIf;
		
		vRoomServiceObj.Hotel = vHotel;
		vRoomServiceObj.pmFillAuthorAndDate();
		vRoomServiceObj.SetNewNumber();
		vRoomServiceObj.pmFillAttributesWithDefaultValues();
		vRoomServiceObj.ExternalCode = pExtCode;
		
		// Get service to be charged by service code or hotel
		vService = Catalogs.Services.EmptyRef();
		If IsBlankString(pServiceCode) Then
			vService = vRoomServiceObj.Hotel.CateringService;
		Else
			vService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", TrimAll(pServiceCode));
			If Not ValueIsFilled(vService) Then
				vService = cmGetServiceByCode(TrimAll(pServiceCode));
			EndIf;
		EndIf;
		If Not ValueIsFilled(vService) Then
			vService = vRoomServiceObj.Hotel.CateringService;
		EndIf;		
		If Not ValueIsFilled(vService) Then
			vMsg =  NStr("en='Service is not set!';ru='Не удалось определить услугу!';de='Die Dienstleistung konnte nicht bestimmt werden!'");
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		vRoomServiceObj.ClientType = vClientType;
		// VAT rate may come from interface
		vVATRate = Catalogs.VATRates.EmptyRef();
		If pVATRate <> Undefined Then
			vQ = New Query("SELECT
			               |	VATRates.Ref AS Ref
			               |FROM
			               |	Catalog.VATRates AS VATRates
			               |WHERE
			               |	VATRates.TaxRate = &qTaxRate
			               |	AND NOT VATRates.DeletionMark");
			vQ.SetParameter("qTaxRate", pVATrate);
			vVATRates = vQ.Execute().Unload();
			If vVATRates.Count() = 1 Then
				vVATRate = vVATRates.Get(0).Ref;
			EndIf;
		EndIf;
		If vVATRate = Catalogs.VATRates.EmptyRef() Then
			vServicePrices = vService.GetObject().pmGetServicePrices(vRoomServiceObj.Hotel, CurrentSessionDate(), vClientType);
			If vServicePrices.Count() > 0 Then
				vVATRate = vServicePrices.Get(0).VATRate;
			EndIf;
		EndIf;		
		// Get client by client code
		vClient = Catalogs.Clients.EmptyRef();
		If Not IsBlankString(pClientCode) Then
			vClient = Catalogs.Clients.FindByCode(pClientCode);
		EndIf;
		
		// Get currency by currency code
		vCurrency = Catalogs.Currencies.EmptyRef();
		If Not IsBlankString(pCurrencyCode) Then
			vCurrency = cmGetObjectRefByExternalSystemCode(vRoomServiceObj.Hotel, pExternalSystemCode, "Currencies", pCurrencyCode);
		EndIf;
		If Not ValueIsFilled(vCurrency) And ValueIsFilled(vRoomServiceObj.Hotel) Then
			vCurrency = vRoomServiceObj.Hotel.FolioCurrency;
		EndIf;
		If Not ValueIsFilled(vCurrency) Then
			vMsg = NStr("en='Currency is not set!';ru='Не удалось определить валюту начисления!';de='Die Währung der Anrechnung konnte nicht bestimmt werden!'");
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
		EndIf;
		
		// Check sum
		vSum = Number(pSum);
		vQuantity = Number(pQuantity);
		vQuantity = ?(vQuantity = 0, 1, vQuantity);
		If vSum < 0 And vQuantity > 0 Then
			vQuantity = -vQuantity;
		EndIf;
		
		// Fill order sum
		vRoomServiceObj.RoomService = vService;
		vRoomServiceObj.VATRate = vVATRate;
		vRoomServiceObj.FixedServiceVATRate = vVATRate;
		vRoomServiceObj.Unit = vService.Unit;
		vRoomServiceObj.RoomServiceChargeType = ?(IsBlankString(pChargeType), NStr("en='Restaurant';ru='Ресторан';de='Restaurant'"), pChargeType);
		vRoomServiceObj.Quantity = vQuantity;
		vRoomServiceObj.Sum = vSum;
		vRoomServiceObj.Price = Round(vRoomServiceObj.Sum/vRoomServiceObj.Quantity, 2);
		
		// Fill currency attributes
		vRoomServiceObj.Currency = vCurrency;
		vRoomServiceObj.CurrencyExchangeRate = cmGetCurrencyExchangeRate(vRoomServiceObj.Hotel, vRoomServiceObj.Currency, vRoomServiceObj.ExchangeRateDate);
		
		// Fill call attributes
		vRoomServiceObj.ServiceDate = Date(pOrderTime);
		
		// Try to find folio to charge to
		vRoomServiceObj.Room = vRoom;
		If ValueIsFilled(vRoomServiceObj.Room) Then
			If ValueIsFilled(vRoomServiceObj.Room.Company) Then
				vRoomServiceObj.Company = vRoomServiceObj.Room.Company;
				If Not ValueIsFilled(vRoomServiceObj.RoomService) Then
					vRoomServiceObj.VATRate = vRoomServiceObj.Company.VATRate;
				EndIf;
				If Not ValueIsFilled(vRoomServiceObj.FixedService) Then
					vRoomServiceObj.FixedServiceVATRate = vRoomServiceObj.Company.VATRate;
				EndIf;
			EndIf;
			vRoomServiceObj.Client = vClient; 
			vRoomServiceObj.Folio = vRoomServiceObj.pmGetFolioToChargeTo();
		EndIf;
		
		// Cancel operation if folio is closed or not found and this is not phone calls
		If ValueIsFilled(vHotel) And ValueIsFilled(vRoomServiceObj.RoomService) Then
			If vRoomServiceObj.RoomService <> vHotel.PhoneCallService Then
				If Not ValueIsFilled(vRoomServiceObj.Folio) Or ValueIsFilled(vRoomServiceObj.Folio) And vRoomServiceObj.Folio.IsClosed Then
					vMsg = NStr("en='There are no suitable open folios for the guest!';ru='У гостя нет подходящих открытых лицевых счетов!';de='Der Gast hat keine passenden offenen Personenkonten!'");
					If vWriteDebug Then
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
					Else
						WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
					EndIf;
					pSentSms = False;
					Return vMsg;
				EndIf;
			EndIf;
		EndIf;
		
		// Try to find active room folio
		If Not ValueIsFilled(vRoomServiceObj.Folio) Then
			vFolios = cmGetActiveRoomFolios(vRoomServiceObj.Hotel, vRoomServiceObj.Room, vRoomServiceObj.Currency);
			If vFolios.Count() > 0 Then
				vRow = vFolios.Get(0);
				vRoomServiceObj.Folio = vRow.Folio;
			EndIf;
		EndIf;
		
		// Create new empty one
		If Not ValueIsFilled(vRoomServiceObj.Folio) Then
			vMsg = NStr("en='There are no suitable open folios for the guest!';ru='У гостя нет подходящих открытых лицевых счетов!';de='Der Gast hat keine passenden offenen Personenkonten!'");
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
			EndIf;
			pSentSms = False;
			Return vMsg;
			
		ElsIf Not IsBlankString(pExternalSystemCode) Then
			vFolioParentDoc = vRoomServiceObj.Folio.ParentDoc;
			If ValueIsFilled(vFolioParentDoc) And TypeOf(vFolioParentDoc) = Type("DocumentRef.Accommodation") And vFolioParentDoc.NoPost Then
				vMsg = NStr("en = 'Attempt to charge to the folio of the document with No post flag turned on! Operation is canceled.'; 
							|de = 'Es wird versucht, ein Dokument mit aktiviertem Kennzeichen für abrechnungsverbot auf ein Konto zu übertragen! Die Operation ist abgebrochen.'; 
							|ru = 'Попытка выполнить начисление на счет документа с включенным флагом запрета начислений! Операция прервана.'") + " N " + String(vRoomServiceObj.Folio.Number);
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
				EndIf;
				pSentSms = False;
				Return vMsg;
			EndIf;
		EndIf;
		
		// Process folio
		vRoomServiceObj.pmFillByFolio();
		vRoomServiceObj.pmRecalculateSums();
		
		// Fill remarks & details
		vRoomServiceObj.Remarks = TrimAll(pRemarks);
		vRoomServiceObj.Details = TrimAll(pChargeDetails);
		
		// Post current document
		vRoomServiceObj.Write(DocumentWriteMode.Posting);
		
		rRoomServiceRef = vRoomServiceObj.Ref;
        
        vCharges = vRoomServiceObj.pmGetRoomServiceCharges();
		If vCharges.Count() > 0 Then
			rCharge = vCharges[0].Charge;
		EndIf;	
        
        // Send SMS
		If pSentSms Then
			vSMSTamlate = GetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "SMSTemplates", TrimAll(pServiceCode));
			If Not vSMSTamlate = Undefined And ValueIsFilled(vSMSTamlate) Then
				WriteLogEvent(NStr("en='Charge service';ru='Начисление услуги';de='Anrechnung der Dienstleistung'"), EventLogLevel.Information, , , "Найден шаблон " + vSMSTamlate.Description + " по коду услуги: " + TrimAll(pServiceCode));
				vCharges = vRoomServiceObj.pmGetRoomServiceCharges();
				If vCharges.Count() = 0 Then
					pSentSms = False;	
				Else
					vCharge =  vCharges.Get(0).Charge;
					vGuestUUID = SMS.GetMyFolioGuestIdByClient(vCharge.Folio.Client);
					If IsBlankString(vGuestUUID) Then
						pSentSms = False;
					Else	
						vError = "";
						If Not SMS.SendChargeMessage(vCharge,vSMSTamlate,vCharge.Folio.Client,vError,pPhone) Then
							vMsg = NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + vError;
							If vWriteDebug Then
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
							Else
								WriteLogEvent(vFuncLog, EventLogLevel.Warning, , , vMsg);
							EndIf;
							pSentSms = False;
						EndIf;	
					EndIf;
				EndIf;
			Else
				vMsg = NStr("en='SMS template not found for service: ';ru='Не найден шаблон по коду услуги для отправки смс: ';de='SMS template not found for service: '") + TrimAll(pServiceCode);
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , , vMsg, vInteraction.MaxLogLenght);
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vMsg);
				EndIf;
				pSentSms = False;
			EndIf;
		EndIf;
		vMsg = NStr("en='Charge was posted - OK!';ru='Транзакция записана в БД!';de='Transaktion ist in die Datenbank eingetragen!'");
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , , vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vMsg);
		EndIf;
	Except
		vMsg = NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + ErrorDescription();
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , , vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vMsg);
		EndIf;
		pSentSms = False;
		Return vMsg;
	EndTry;
	Return "";
EndFunction // cmChargeRoomService

// -----------------------------------------------------------------------------
//  Return guests information for POS system depending on Client input parameter
//
// Parameters:
//  pClient			 - CatalogRef.Clients	 - Ref
//  pHotel			 - CatalogRef.Hotels	 - Ref
//  pExtSystemCode	 - String				 - External system code
// 
// Returns:
//  XDTO - XDTO object
//
Function cmGetHotelGuestsListExt(pClient, pHotel, pExtSystemCode = "TraktirFO3") Export

	// Log input parameters
	vClientXML 	= cmGetXMLStringFromXDTO(pClient);
	vInputParameters = "ClientXDTO: " + Chars.LF + vClientXML + Chars.LF + "Hotel: " + pHotel + ", ExtSystem: " + pExtSystemCode; 

	vWriteDebug = False;
	If Not IsBlankString(pExtSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	vFuncLog = NStr("en='Get list of hotel guests';ru='Получить список гостей гостиницы';de='Liste der Hotelgäste erhalten'");
	If vWriteDebug Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vInputParameters);
	EndIf;

	// 1. If client card is filled - get client and folio by card id
	// 2. If folio number is filled - get folio
	// 3. if room is filled - get active accomodation for the room and use client code if there are more than one
	vCard = pClient.Get("Card");
	vFolioNumber = pClient.Get("FolioNumber");
	vRoom = pClient.Get("Room");
	vClientCode = pClient.Get("ClientID");
	
	If Not IsBlankString(vCard) Then
		Return cmGetCardGuestsList(vCard, pExtSystemCode);
	ElsIf Not IsBlankString(vFolioNumber) Then
		Return cmGetFolioGuestsList(vFolioNumber, pHotel, pExtSystemCode);
	Else
		Return cmGetHotelGuestsList(vClientCode, vRoom, pHotel, "XDTO", pExtSystemCode);
	EndIf;
EndFunction

// -----------------------------------------------------------------------------
//  Returns list of guests by name and room.
//  Function could be called as web-service or thru COM connection
//
// Parameters:
//  pGuestName		 - 	 - 
//  pRoomCode		 - 	 - 
//  pHotelName		 - 	 - 
//  pOutputType		 - 	 - 
//  pExtSystemCode	 - 	 - 
// 
// Returns:
//  XDTO - XDTO object or CSV strings separated by line feed character
//
Function cmGetHotelGuestsList(pGuestName = "", pRoomCode = "", pHotelName = "", pOutputType = "CSV", pExtSystemCode = "TraktirFO3") Export
	// Log input parameters
	vInputParameters = NStr("en='Guest name: ';ru='Имя гостя: ';de='Name des Gastes: '") + pGuestName + Chars.LF +
	NStr("en='Room code: ';ru='Код номера: ';de='Zimmercode: '") + pRoomCode + Chars.LF +
	NStr("en='Hotel name: ';ru='Название гостиницы: ';de='Bezeichnung des Hotels: '") + pHotelName + Chars.LF +
	NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExtSystemCode; 
	vWriteDebug = False;
	If pHotelName = Undefined Then
		pHotelName = "";
	EndIf;
	vExtSystemCode = "TraktirFO3";
	If Not IsBlankString(pExtSystemCode) Then
		vExtSystemCode = TrimR(pExtSystemCode);
	EndIf;
	vHotel = cmGetHotelByCode(pHotelName, vExtSystemCode);
	If Not IsBlankString(vExtSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vExtSystemCode, vHotel);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	vFuncLog = NStr("en='Get list of hotel guests';ru='Получить список гостей гостиницы';de='Liste der Hotelgäste erhalten'");
	If vWriteDebug Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vInputParameters);
	EndIf;
	
	// Initialize return parameters
	vRetStr = "";
	vRetXDTO = Undefined;
	vGuestItemType = Undefined;
	If pOutputType <> "CSV" Then
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestsList"));
		vGuestItemType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestItem");
		vGuestItemsType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestItems");
		vRetXDTO.GuestItems = XDTOFactory.Create(vGuestItemsType);
		// Temporary solution
		vRetXDTO.GuestGroupDescription = "Test Description for get client";
	EndIf;
	
	// Initialize input parameters
	If pGuestName = Undefined Then
		pGuestName = "";
	EndIf;
	If pRoomCode = Undefined Then
		pRoomCode = "";
	EndIf;
	
	// Find room by code
	vRoomCode = TrimR(pRoomCode);
	vRoom = cmGetRoomByCode(pRoomCode, pHotelName, vExtSystemCode);
	If ValueIsFilled(vRoom) Then
		vRoomCode = TrimR(vRoom.Description);
		vHotel = vRoom.Owner;
	EndIf;		
	
	// Try to find guests by input parameters
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	RoomInventory.Guest AS Guest,
	|	RoomInventory.Guest.FullName AS GuestFullName,
	|	ISNULL(RoomInventory.Guest.Code, &qEmptyString) AS GuestCode,
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.Hotel.Description AS HotelDescription,
	|	RoomInventory.Room.Description AS RoomDescription,
	|	RoomInventory.Room.SortCode AS RoomSortCode,
	|	RoomInventory.Recorder AS ParentDoc,
	|	ISNULL(RoomInventory.Recorder.NoPost, FALSE) AS NoPost,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.Recorder.RoomRate.Code AS RoomRateCode,
	|	RoomInventory.Recorder.RoomRate.Description AS RoomRateName,
	|	CAST(RoomInventory.Recorder.Remarks AS STRING(1024)) AS ReservationRemarks,
	|	RoomInventory.Recorder.AccommodationType AS AccommodationType,
	|	RoomInventory.Recorder.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomInventory.Recorder.Number AS AccommodationCode,
	|	RoomInventory.Recorder.DiscountCard AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType AS DiscountType,
	|	CASE
	|		WHEN ISNULL(RoomInventory.Recorder.ServicePackage.IsMealBoardTerm, FALSE)
	|			THEN RoomInventory.Recorder.ServicePackage
	|		ELSE UNDEFINED
	|	END AS MealBoardTerm,
	|	ISNULL(RoomInventory.GuestGroup.Code, 0) AS GuestGroupCode,
	|	RoomInventory.Customer.Description AS CustomerDescription,
	|	RoomInventory.PlannedPaymentMethod.Description AS PlannedPaymentMethodDescription,
	|	ISNULL(ClientBalances.ClientBalance, 0) + ISNULL(ClientBalances.ClientLimit, 0) AS ClientBalance,
	|	ISNULL(ClientCreditLimit.CreditLimit, 0) AS CreditLimit,
	|	CASE
	|		WHEN ClientBalances.FolioCurrency IS NULL
	|			THEN ClientCreditLimit.FolioCurrency
	|		ELSE ClientBalances.FolioCurrency
	|	END AS FolioCurrency,
	|	CASE
	|		WHEN ClientBalances.FolioCurrency IS NULL
	|			THEN ClientCreditLimit.FolioCurrency.Code
	|		ELSE ClientBalances.FolioCurrency.Code
	|	END AS FolioCurrencyCode
	|FROM
	|	(SELECT
	|		RoomInventoryMovements.Guest AS Guest,
	|		RoomInventoryMovements.Hotel AS Hotel,
	|		RoomInventoryMovements.Room AS Room,
	|		RoomInventoryMovements.Recorder AS Recorder,
	|		RoomInventoryMovements.GuestGroup AS GuestGroup,
	|		RoomInventoryMovements.Customer AS Customer,
	|		RoomInventoryMovements.PlannedPaymentMethod AS PlannedPaymentMethod
	|	FROM
	|		AccumulationRegister.RoomInventory AS RoomInventoryMovements
	|	WHERE
	|		RoomInventoryMovements.IsAccommodation
	|		AND RoomInventoryMovements.IsInHouse
	|		AND RoomInventoryMovements.RecordType = &qRecordType
	|		AND RoomInventoryMovements.PeriodFrom <= &qCurrentDate
	|		AND (RoomInventoryMovements.PeriodTo >= &qCurrentDate
	|				OR RoomInventoryMovements.PeriodTo = RoomInventoryMovements.Recorder.CheckOutDate)
	|		AND RoomInventoryMovements.Guest <> &qEmptyClient
	|		AND (RoomInventoryMovements.Hotel.Description = &qHotelName
	|				OR RoomInventoryMovements.Hotel.Code = &qHotelName
	|				OR &qEmptyHotel)
	|		AND (RoomInventoryMovements.Room.Description = &qRoomCode
	|				OR &qEmptyRoomCode)
	|		AND (RoomInventoryMovements.Guest.Description LIKE &qGuestName
	|				OR RoomInventoryMovements.Guest.FullName LIKE &qGuestName
	|				OR RoomInventoryMovements.Guest.Code LIKE &qGuestName
	|				OR &qEmptyGuestName)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VirtualGuests.Guest,
	|		VirtualGuests.Hotel,
	|		VirtualGuests.Room,
	|		VirtualGuests.Ref,
	|		VirtualGuests.GuestGroup,
	|		VirtualGuests.Customer,
	|		VirtualGuests.PlannedPaymentMethod
	|	FROM
	|		Document.Accommodation AS VirtualGuests
	|	WHERE
	|		VirtualGuests.Posted
	|		AND VirtualGuests.AccommodationStatus.IsActive
	|		AND VirtualGuests.AccommodationStatus.IsInHouse
	|		AND VirtualGuests.Room.IsVirtual
	|		AND VirtualGuests.CheckInDate <= &qCurrentDate
	|		AND VirtualGuests.CheckOutDate >= &qCurrentDate
	|		AND VirtualGuests.Guest <> &qEmptyClient
	|		AND (VirtualGuests.Hotel.Description = &qHotelName
	|				OR VirtualGuests.Hotel.Code = &qHotelName
	|				OR &qEmptyHotel)
	|		AND (VirtualGuests.Room.Description = &qRoomCode
	|				OR &qEmptyRoomCode)
	|		AND (VirtualGuests.Guest.Description LIKE &qGuestName
	|				OR VirtualGuests.Guest.FullName LIKE &qGuestName
	|				OR VirtualGuests.Guest.Code LIKE &qGuestName
	|				OR &qEmptyGuestName)) AS RoomInventory
	|		LEFT JOIN (SELECT
	|			ClientAccountsBalance.FolioCurrency AS FolioCurrency,
	|			ClientAccountsBalance.Folio.ParentDoc AS FolioParentDoc,
	|			SUM(ClientAccountsBalance.SumBalance) AS ClientBalance,
	|			SUM(ClientAccountsBalance.LimitBalance) AS ClientLimit
	|		FROM
	|			AccumulationRegister.Accounts.Balance(
	|					&qBalancesPeriod,
	|					NOT Folio.IsClosed
	|						AND (Folio.Customer = &qEmptyCustomer
	|							OR Folio.Customer <> &qEmptyCustomer
	|								AND Folio.Customer.IsIndividual
	|							OR Folio.Description LIKE &qFolioDescription
	|								AND NOT &qFolioDescriptionIsEmpty)
	|						AND (Folio.Description LIKE &qFolioDescription
	|							OR &qFolioDescriptionIsEmpty)) AS ClientAccountsBalance
	|		
	|		GROUP BY
	|			ClientAccountsBalance.FolioCurrency,
	|			ClientAccountsBalance.Folio.ParentDoc) AS ClientBalances
	|		ON RoomInventory.Recorder = ClientBalances.FolioParentDoc
	|			AND RoomInventory.Recorder.Hotel.FolioCurrency = ClientBalances.FolioCurrency
	|		LEFT JOIN (SELECT
	|			ClientFolios.FolioCurrency AS FolioCurrency,
	|			ClientFolios.ParentDoc AS FolioParentDoc,
	|			MAX(CASE
	|					WHEN ClientFolios.Hotel.NoCreditLimit
	|						THEN 999999999
	|					WHEN ClientFolios.Customer <> &qEmptyCustomer
	|							AND NOT ClientFolios.Customer.IsIndividual
	|							AND ClientFolios.Description LIKE &qFolioDescription
	|							AND NOT &qFolioDescriptionIsEmpty
	|						THEN 999999999
	|					ELSE ClientFolios.CreditLimit
	|				END) AS CreditLimit
	|		FROM
	|			Document.Folio AS ClientFolios
	|		WHERE
	|			NOT ClientFolios.IsClosed
	|			AND (ClientFolios.Customer = &qEmptyCustomer
	|					OR ClientFolios.Customer <> &qEmptyCustomer
	|						AND ClientFolios.Customer.IsIndividual
	|					OR ClientFolios.Description LIKE &qFolioDescription
	|						AND NOT &qFolioDescriptionIsEmpty)
	|			AND (ClientFolios.Description LIKE &qFolioDescription
	|					OR &qFolioDescriptionIsEmpty)
	|			AND ClientFolios.DeletionMark = FALSE
	|		
	|		GROUP BY
	|			ClientFolios.FolioCurrency,
	|			ClientFolios.ParentDoc) AS ClientCreditLimit
	|		ON RoomInventory.Recorder = ClientCreditLimit.FolioParentDoc
	|			AND RoomInventory.Recorder.Hotel.FolioCurrency = ClientCreditLimit.FolioCurrency
	|
	|ORDER BY
	|	HotelDescription,
	|	RoomSortCode,
	|	AccommodationTypeSortCode,
	|	GuestFullName";
	vQry.SetParameter("qBalancesPeriod", '39991231235959');
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qRecordType", AccumulationRecordType.Expense);
	vQry.SetParameter("qHotelName", TrimR(pHotelName));
	vQry.SetParameter("qEmptyHotel", IsBlankString(pHotelName));
	vQry.SetParameter("qGuestName", Upper(TrimR(pGuestName)) + "%");
	vQry.SetParameter("qEmptyGuestName", IsBlankString(pGuestName));
	vQry.SetParameter("qRoomCode", TrimR(vRoomCode));
	vQry.SetParameter("qEmptyRoomCode", IsBlankString(vRoomCode));
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qFolioDescription", "%" + TrimAll(vHotel.AdditionalServicesFolioCondition) + "%");
	vQry.SetParameter("qFolioDescriptionIsEmpty", IsBlankString(vHotel.AdditionalServicesFolioCondition));
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vGuests = vQry.Execute().Unload();
	For Each vGuestsRow In vGuests Do
		vGuest = vGuestsRow.Guest;
		vBonusCardRef = Undefined;
		
		// Get discount data
		vDiscount = 0;
		vDiscountType = Undefined;
		vDiscountCard = Undefined;
		If ValueIsFilled(vGuestsRow.DiscountCard) Then
			vDiscountCard = vGuestsRow.DiscountCard;
			vDiscountType = vDiscountCard.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		ElsIf ValueIsFilled(vGuestsRow.DiscountType) Then
			vDiscountType = vGuestsRow.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		Else
			If ValueIsFilled(vGuest) Then
				If ValueIsFilled(vGuest.DiscountType) Then
					vDiscountType = vGuest.DiscountType;
					vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
				Else
					vDiscountCard = cmGetDiscountCardByClient(vGuest);
					If ValueIsFilled(vDiscountCard) And ValueIsFilled(vDiscountCard.DiscountType) Then
						vDiscountType = vDiscountCard.DiscountType;
						vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vDiscountType) And vDiscountType.DoNotExportToExternalInterfaces Then
			vDiscount = 0;
			vDiscountType = Undefined;
			vDiscountCard = Undefined;
		EndIf;
		
		vIsRoomShare = False;
		If ValueIsFilled(vGuestsRow.AccommodationType) And vGuestsRow.AccommodationType.Type <> Enums.AccomodationTypes.Room Then
			vIsRoomShare = True;
		EndIf;
		
		// Document discount card
		vDocDiscountCard = Undefined;
		If ValueIsFilled(vGuestsRow.DiscountCard) Then
			vDocDiscountCard = vGuestsRow.DiscountCard;
		EndIf;
		
		// Add client bonuses
		If ValueIsFilled(vGuest) And ValueIsFilled(vGuestsRow.FolioCurrency) Then
			vClientObj = vGuest.GetObject();
			vBonus = 0;
			vBonusAmount = vClientObj.pmGetBonusesAmount(vGuestsRow.Hotel, vGuestsRow.FolioCurrency, vDocDiscountCard, vBonus);
			If vGuestsRow.CreditLimit < 999999999 Then
				vGuestsRow.CreditLimit = vGuestsRow.CreditLimit + vBonusAmount;
			EndIf;
			vBonusCardRef = cmGetClientBonusCard(vGuest);
		EndIf;
		If vGuestsRow.NoPost Then
			vGuestsRow.ClientBalance = 0;
			vGuestsRow.CreditLimit = 0;
		EndIf;
		vReservationRemarks = "";
		
		// Add client profile data
		vClientProfileXDTO = Undefined;
		If ValueIsFilled(vGuest) Then
			vClientProfileXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ClientProfile"));
			
			vClientSexCode = Left(vGuest.Sex, 1);
			vClientCitizenshipCode = TrimAll(?(ValueIsFilled(vGuest.Citizenship), vGuest.Citizenship.ISOCode3, ""));
			
			vClientProfileXDTO.ClientCode			 = vGuest.Code;
			vClientProfileXDTO.ClientLastName		 = cmRemoveUTFControlSymbols(vGuest.LastName);
			vClientProfileXDTO.ClientFirstName		 = cmRemoveUTFControlSymbols(vGuest.FirstName);
			vClientProfileXDTO.ClientSecondName		 = cmRemoveUTFControlSymbols(vGuest.SecondName);
			vClientProfileXDTO.ClientBirthDate		 = vGuest.DateOfBirth;
			vClientProfileXDTO.ClientSex			 = vClientSexCode; 
			vClientProfileXDTO.ClientCitizenship	 = vClientCitizenshipCode;
			
			vGuestPlaceOfBirth = TrimAll(vGuest.PlaceOfBirth);
			If Upper(TrimAll(pExtSystemCode)) = "LOGISOFT_POS" And Not IsBlankString(vGuestPlaceOfBirth) Then
				vGuestPlaceOfBirth = cmParseAddress(vGuestPlaceOfBirth).Country;
			EndIf;
			vClientProfileXDTO.PlaceOfBirth			 = cmRemoveUTFControlSymbols(vGuestPlaceOfBirth);
			
			vClientProfileXDTO.ClientPhone = cmRemoveUTFControlSymbols(vGuest.Phone);
			vClientProfileXDTO.ClientEmail = vGuest.Email;
			vClientProfileXDTO.ClientFax = cmRemoveUTFControlSymbols(vGuest.Fax);
			
			vGuestAddress = TrimAll(vGuest.Address);
			If Upper(TrimAll(pExtSystemCode)) = "LOGISOFT_POS" And Not IsBlankString(vGuestAddress) Then
				vGuestAddress = cmParseAddress(vGuestAddress).Country;
			EndIf;
			vClientProfileXDTO.Address = cmRemoveUTFControlSymbols(vGuestAddress);
			
			vClientProfileXDTO.ClientIdentityDocumentCode			 = TrimAll(vGuest.IdentityDocumentType.Code);
			vClientProfileXDTO.ClientIdentityDocumentType			 = vGuest.IdentityDocumentType.Description;
			vClientProfileXDTO.ClientIdentityDocumentSeries			 = vGuest.IdentityDocumentSeries;
			vClientProfileXDTO.ClientIdentityDocumentNumber			 = vGuest.IdentityDocumentNumber;
			vClientProfileXDTO.ClientIdentityDocumentIssueDate		 = vGuest.IdentityDocumentIssueDate; 
			vClientProfileXDTO.ClientIdentityDocumentValidToDate	 = vGuest.IdentityDocumentValidToDate; 
			vClientProfileXDTO.ClientIdentityDocumentIssuedBy		 = cmRemoveUTFControlSymbols(vGuest.IdentityDocumentIssuedBy);
			vClientProfileXDTO.CIientIdentityDocumentUnitCode		 = cmRemoveUTFControlSymbols(vGuest.IdentityDocumentUnitCode);
			
			vClientProfileXDTO.ClientSendSMS = Not vGuest.NoSMSDelivery;
			vClientProfileXDTO.IsIndividual = True;
		EndIf;
		
		// Add bonuses card info
		vDiscountCardInfoXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "DiscountCardInfo"));
		If ValueIsFilled(vBonusCardRef) Then
			vDiscountCardInfo = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vBonusCardRef);
			vDiscountCardInfoXDTO.CardBalance             	 = vDiscountCardInfo.Balance;
			vDiscountCardInfoXDTO.MaxPercentPayment			 = vDiscountCardInfo.MaxPercentPayment;
			vDiscountCardInfoXDTO.TypeCard 				  	 = vDiscountCardInfo.TypeCard;
			vDiscountCardInfoXDTO.CertificateNominal      	 = vDiscountCardInfo.CertificateNominal;
			vDiscountCardInfoXDTO.BonusRate       			 = vDiscountCardInfo.BonusRate;
			vDiscountCardInfoXDTO.ValidFrom					 = vBonusCardRef.ValidFrom;
			vDiscountCardInfoXDTO.ValidTo					 = vBonusCardRef.ValidTo;
		Else
			vDiscountCardInfoXDTO.CardBalance             	 = 0;
			vDiscountCardInfoXDTO.MaxPercentPayment			 = 0;
			vDiscountCardInfoXDTO.TypeCard 				  	 = "";
			vDiscountCardInfoXDTO.CertificateNominal      	 = 0;
			vDiscountCardInfoXDTO.BonusRate       			 = 1;
			vDiscountCardInfoXDTO.ValidFrom					 = Date(1, 1, 1);
			vDiscountCardInfoXDTO.ValidTo					 = Date(1, 1, 1);
		EndIf;
		
		// Add orders and service packages
		vOrdersXDTO = GetOrdersXDTO(vGuestsRow.ParentDoc, pExtSystemCode);
		vServicePackagesXDTO = GetServicePackagesXDTO(vGuestsRow.ParentDoc);
		
		// Build return string in CSV format
		vRetStr = vRetStr + """" + cmRemoveUTFControlSymbols(cmRemoveComma(vGuestsRow.GuestFullName)) + ?(ValueIsFilled(vDocDiscountCard), "(DC " + TrimAll(vDocDiscountCard.Identifier) + ")", "") + """" + "," + 
		"""" + TrimAll(vGuestsRow.GuestCode) + """" + "," + 
		"""" + cmRemoveComma(vGuestsRow.HotelDescription) + """" + "," + 
		"""" + cmRemoveComma(vGuestsRow.RoomDescription) + """" + "," + 
		"""" + Format(Date(vGuestsRow.CheckInDate), "DF='dd.MM.yyyy HH:mm'") + """" + "," + 
		"""" + Format(Date(vGuestsRow.CheckOutDate), "DF='dd.MM.yyyy HH:mm'") + """" + "," + 
		Format(vGuestsRow.GuestGroupCode, "ND=12; NFD=0; NZ=; NG=") + "," + 
		"""" + cmRemoveUTFControlSymbols(cmRemoveComma(vGuestsRow.CustomerDescription)) + """" + "," + 
		"""" + cmRemoveComma(vGuestsRow.PlannedPaymentMethodDescription) + """" + "," + 
		Format(vGuestsRow.ClientBalance, "ND=17; NFD=2; NDS=.; NZ=; NG=") + "," + 
		Format(vGuestsRow.CreditLimit, "ND=17; NFD=2; NDS=.; NZ=; NG=") + "," + 
		"""" + TrimAll(vGuestsRow.FolioCurrencyCode) + """" + "," + 
		?(vDiscount <> 0, Format(vDiscount, "ND=6; NFD=2; NDS=.; NZ=; NG="), "0") + "," +
		"""" + ?(ValueIsFilled(vDiscountType), cmRemoveComma(vDiscountType.Description), "") + """" + "," + 
		"""" + ?(ValueIsFilled(vDiscountCard), cmRemoveComma(vDiscountCard.Identifier), "") + """" + "," + 
		"""" + TrimAll(vGuestsRow.AccommodationCode) + """" + "," + 
		"""" + TrimAll(vIsRoomShare) + """" + Chars.LF;
		
		// Build XDTO return object
		If pOutputType <> "CSV" Then
			vGuestItem = XDTOFactory.Create(vGuestItemType);
			vGuestItem.Guest 			= cmRemoveUTFControlSymbols(cmRemoveComma(vGuestsRow.GuestFullName)) + ?(ValueIsFilled(vDocDiscountCard), "(DC " + TrimAll(vDocDiscountCard.Identifier) + ")", "");
			vGuestItem.GuestCode 		= vGuestsRow.GuestCode;
			vGuestItem.GuestSex 		= Upper(Left(TrimAll(vGuest.Sex), 1));
			vGuestItem.GuestDateOfBirth = vGuest.DateOfBirth;
			vGuestItem.GuestAge 		= vGuest.Age;
			If ValueIsFilled(vGuest.Citizenship) Then
				vGuestItem.GuestCitizenship = TrimAll(vGuest.Citizenship.ISOCode3);
			Else
				vGuestItem.GuestCitizenship = "";
			EndIf;
			vGuestItem.GuestLanguage 	= TrimAll(vGuest.Language);
			vGuestItem.GuestLocale 		= ?(ValueIsFilled(vGuest.Language),?(IsBlankString(vGuest.Language.LocalizationCode), "ru_RU", TrimAll(vGuest.Language.LocalizationCode)),"");
			vGuestItem.Hotel 			= cmRemoveComma(vGuestsRow.HotelDescription);
			vGuestItem.Room 			= TrimAll(vGuestsRow.RoomDescription);
			vGuestItem.CheckInDate 		= Date(vGuestsRow.CheckInDate);
			vGuestItem.CheckOutDate 	= Date(vGuestsRow.CheckOutDate);
			vGuestItem.GuestGroup 		= vGuestsRow.GuestGroupCode;
			vGuestItem.Customer 		= cmRemoveUTFControlSymbols(cmRemoveComma(vGuestsRow.CustomerDescription));
			vGuestItem.PaymentMethod 	= TrimAll(vGuestsRow.PlannedPaymentMethodDescription);
			vGuestItem.ClientBalance 	= vGuestsRow.ClientBalance;
			vGuestItem.CreditLimit 		= vGuestsRow.CreditLimit;
			vGuestItem.FolioCurrency 	= TrimAll(vGuestsRow.FolioCurrencyCode);
			vGuestItem.Discount 		= vDiscount;
			vGuestItem.DiscountType 	= ?(ValueIsFilled(vDiscountType), cmGetObjectExternalSystemCodeByRef(vHotel, pExtSystemCode, "DiscountTypes", vDiscountType), "");
			vGuestItem.DiscountCard 	= ?(ValueIsFilled(vDiscountCard), TrimAll(vDiscountCard.Identifier), "");
			vGuestItem.AccommodationCode= TrimAll(vGuestsRow.AccommodationCode);
			vGuestItem.IsRoomShare 		= vIsRoomShare;
			vGuestItem.GuestPhone       = cmRemoveUTFControlSymbols(TrimAll(vGuest.Phone));
			vGuestItem.GuestRemarks     = cmRemoveUTFControlSymbols(TrimAll(vGuest.Remarks));
			vGuestItem.MealBoardTerm    = ?(ValueIsFilled(vGuestsRow.MealBoardTerm), TrimAll(vGuestsRow.MealBoardTerm.Code), "");
			vGuestItem.MealBoardName    = ?(ValueIsFilled(vGuestsRow.MealBoardTerm), TrimAll(vGuestsRow.MealBoardTerm.Description), "");
			vGuestItem.NoPost           = vGuestsRow.NoPost;
			
			vGuestItem.RoomRateCode     = TrimAll(vGuestsRow.RoomRateCode);
			vGuestItem.RoomRate         = TrimAll(vGuestsRow.RoomRateName);
			
			vGuestItem.IsCheckedOut     = False;
			vGuestItem.IsBlocked        = False;
			vGuestItem.BlockReason      = "";
			vGuestItem.DiscountCardInfo = vDiscountCardInfoXDTO;
			vGuestItem.Orders		    = vOrdersXDTO;
			vGuestItem.ServicePackages  = vServicePackagesXDTO;
			
			vGuestItem.ReservationRemarks = cmRemoveUTFControlSymbols(cmRemoveComma(vGuestsRow.ReservationRemarks));
			
			// Client profile
			If vClientProfileXDTO <> Undefined Then
				vGuestItem.ClientProfile = vClientProfileXDTO;
			EndIf;
			
			vGuestItem.GuestPhoto = "";
			If ValueIsFilled(vGuest) Then
				vGuestPhoto = vGuest.Photo.Get();
				If TypeOf(vGuestPhoto) = Type("Picture") Then
					vGuestItem.GuestPhoto = Base64String(vGuestPhoto.GetBinaryData());
				ElsIf TypeOf(vGuestPhoto) = Type("BinaryData") Then
					vGuestItem.GuestPhoto = Base64String(vGuestPhoto);
				Else
					vGuestItem.GuestPhoto = "";
				EndIf;
			EndIf;
			
			vRetXDTO.GuestItems.GuestItem.Add(vGuestItem);
			vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
		Else
			vExtraXML = NStr("en='Return string: ';ru='Строка возврата: ';de='Zeilenrücklauf: '") + vRetStr;
		EndIf;
	EndDo;
	vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
	If vWriteDebug Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , vExtraXML, vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vExtraXML);
	EndIf;
	If pOutputType = "CSV" Then
		Return vRetStr;
	Else
		Return vRetXDTO;
	EndIf;
EndFunction // cmGetHotelGuestsList

// -----------------------------------------------------------------------------
// Description: Returns folio parameters including folio balance.
//              Function could be called as web-service or thru COM connection
// Parameters: Folio number, Hotel code, External system code, Output type (XDTO or CSV)
// Return value: XDTO object or Comma Separated Values string
// -----------------------------------------------------------------------------
Function cmGetFolioDescription(pFolioNumber, pHotelCode = "", pExternalSystemCode = "TraktirFO3", pOutputType = "CSV") Export
	// Log input parameters
	vInputParameters = NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode + Chars.LF + 
						NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + pHotelCode + Chars.LF + 
						NStr("en='Folio number: ';ru='Номер фолио: ';de='Folionummer: '") + pFolioNumber;
	
	vWriteDebug = False;
	If Not IsBlankString(pExternalSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExternalSystemCode);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	vFuncLog = NStr("en='Get folio description';ru='Получить данные лицевого счета';de='Daten der Personenkontos erhalten'");
	If vWriteDebug Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vInputParameters);
	EndIf;

	// Initialize return parameters				  
	vRetStr = "";
	vRetXDTO = Undefined;
	If pOutputType <> "CSV" Then
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Folio"));
	EndIf;
	
	// Get hotel
	vHotel = SessionParameters.CurrentHotel;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
	EndIf;
	
	// Get folio reference by folio number
	vFolio = cmFindFolioByNumber(pFolioNumber, vHotel);
	If Not ValueIsFilled(vFolio) Then
		vMsg = NStr("en='Folio was not found!';ru='Лицевой счет не найден по номеру!';de='Das Personenkonto wurde nach der Nummer nicht gefunden!'");
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , , vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vMsg);
		EndIf;

		If pOutputType <> "CSV" Then
			Raise vMsg;
		Else
			Return vMsg;
		EndIf;
	EndIf;
	If ValueIsFilled(vFolio.Hotel) Then
		vHotel = vFolio.Hotel;
	EndIf;
	If vFolio.IsClosed Then
		vMsg = NStr("en='Folio is closed!';ru='Лицевой счет закрыт!';de='Das Personenkonto ist geschlossen!'");
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , , vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vMsg);
		EndIf;

		If pOutputType <> "CSV" Then
			Raise vMsg;
		Else
			Return vMsg;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vFolio.Customer) And Not ValueIsFilled(vFolio.Client) Then
		vMsg = NStr("en='It is not allowed to charge this folio. Folio owner is not specified.';ru='Лицевой счет нельзя использовать для данного способа закрытия заказа! Не задан владелец фолио.';de='Das Personenkonto darf nicht für diese Art der Bestellschließung verwendet werden! Der Folio-Besitzer ist nicht angegeben.'");
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , , vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vMsg);
		EndIf;
		If pOutputType <> "CSV" Then
			Raise vMsg;
		Else
			Return vMsg;
		EndIf;
	EndIf;
	vClientRef = vFolio.Client;
	
	// Get folio balance
	vLimit = 0;
	vFolioBalance = vFolio.GetObject().pmGetBalance( , , , vLimit);
	vFolioBalance = vFolioBalance + vLimit;
	
	// Get discount data
	vDiscount = 0;
	vDiscountType = Undefined;
	vDiscountCard = Undefined;
	If ValueIsFilled(vFolio.FolioDiscountCard) Then
		vDiscountCard = vFolio.FolioDiscountCard;
		vDiscountType = vDiscountCard.DiscountType;
		If ValueIsFilled(vDiscountType) Then
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		EndIf;
	ElsIf ValueIsFilled(vFolio.FolioDiscountType) Then
		vDiscountType = vFolio.FolioDiscountType;
		vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
	ElsIf ValueIsFilled(vFolio.ParentDoc) And 
		(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
		ValueIsFilled(vFolio.ParentDoc.DiscountCard) Then
		vDiscountCard = vFolio.ParentDoc.DiscountCard;
		vDiscountType = vDiscountCard.DiscountType;
		vDiscount = vFolio.ParentDoc.Discount;
	ElsIf ValueIsFilled(vFolio.ParentDoc) And 
		(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
		ValueIsFilled(vFolio.ParentDoc.DiscountType) Then
		vDiscountType = vFolio.ParentDoc.DiscountType;
		vDiscount = vFolio.ParentDoc.Discount;
	ElsIf ValueIsFilled(vFolio.Client) Then
		If ValueIsFilled(vFolio.Client.DiscountType) Then
			vDiscountType = vFolio.Client.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		Else
			vDiscountCard = cmGetDiscountCardByClient(vFolio.Client);
			If ValueIsFilled(vDiscountCard) And ValueIsFilled(vDiscountCard.DiscountType) Then
				vDiscountType = vDiscountCard.DiscountType;
				vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(vDiscountType) And vDiscountType.DoNotExportToExternalInterfaces Then
		vDiscount = 0;
		vDiscountType = Undefined;
		vDiscountCard = Undefined;
	EndIf;
	
	vCreditLimit = vFolio.CreditLimit;
	If vFolio.IsClosed Then
		vCreditLimit = 0;
	Else
		If ValueIsFilled(vHotel) And vHotel.NoCreditLimit Then
			vCreditLimit = 999999999;
		EndIf;
		If ValueIsFilled(vFolio.Customer) 
			And (Not ValueIsFilled(vFolio.ParentDoc) Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) Then
			vCreditLimit = 999999999;
		EndIf;
	EndIf;
	
	// Add CustomerProfile data
	vCustomerRef = vFolio.Customer;
	vCustomerProfileXDTO = Undefined;
	If ValueIsFilled(vCustomerRef) Then
		vCustomerProfileXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "CustomerProfile"));
		
		vCustomerProfileXDTO.CustomerCode = TrimR(vCustomerRef.Code); 
		vCustomerProfileXDTO.CustomerName = cmRemoveUTFControlSymbols(TrimAll(vCustomerRef.Description));
		vCustomerProfileXDTO.CustomerLegacyName = cmRemoveUTFControlSymbols(vCustomerRef.LegacyName);
		vCustomerProfileXDTO.CustomerEmail = cmRemoveUTFControlSymbols(vCustomerRef.Email);
		vCustomerProfileXDTO.CustomerPhone = cmRemoveUTFControlSymbols(vCustomerRef.Phone);
		vCustomerProfileXDTO.CustomerRemarks = cmRemoveUTFControlSymbols(vCustomerRef.Remarks);
		vCustomerProfileXDTO.CustomerFax = cmRemoveUTFControlSymbols(vCustomerRef.Fax);
		vCustomerProfileXDTO.CustomerKPP = vCustomerRef.KPP;
		vCustomerProfileXDTO.CustomerTIN = vCustomerRef.TIN;
		vCustomerProfileXDTO.CustomerOGRN = vCustomerRef.OGRN; 
		vCustomerProfileXDTO.CustomerDirector = cmRemoveUTFControlSymbols(vCustomerRef.Director);
		vCustomerProfileXDTO.CustomerLegacyAddres = cmRemoveUTFControlSymbols(vCustomerRef.LegacyAddress);
		vCustomerProfileXDTO.CustomerPostAddres = cmRemoveUTFControlSymbols(vCustomerRef.PostAddress);
		vCustomerProfileXDTO.IsIndividual = False;
	EndIf;
	
	vClientProfileXDTO = Undefined;
	If ValueIsFilled(vClientRef) Then
    	vClientProfileXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ClientProfile"));
			
	   	vClientSexCode = Left(vClientRef.Sex, 1);
	    vClientCitizenshipCode = ?(ValueIsFilled(vClientRef.Citizenship), TrimAll(vClientRef.Citizenship.ISOCode3), "");
		  
		vClientProfileXDTO.ClientCode = vClientRef.Code;
		vClientProfileXDTO.ClientLastName = cmRemoveUTFControlSymbols(vClientRef.LastName);
		vClientProfileXDTO.ClientFirstName = cmRemoveUTFControlSymbols(vClientRef.FirstName);
		vClientProfileXDTO.ClientSecondName = cmRemoveUTFControlSymbols(vClientRef.SecondName);
		vClientProfileXDTO.ClientFullName = cmRemoveUTFControlSymbols(vClientRef.FullName);
		vClientProfileXDTO.ClientBirthDate = vClientRef.DateOfBirth;
		vClientProfileXDTO.ClientSex = vClientSexCode; 
		vClientProfileXDTO.ClientCitizenship = vClientCitizenshipCode;

		vClientPlaceOfBirth = TrimAll(vClientRef.PlaceOfBirth);
		If Upper(TrimAll(pExternalSystemCode)) = "LOGISOFT_POS" And Not IsBlankString(vClientPlaceOfBirth) Then
			vClientPlaceOfBirth = cmParseAddress(vClientPlaceOfBirth).Country;
		EndIf;
		vClientProfileXDTO.PlaceOfBirth = cmRemoveUTFControlSymbols(vClientPlaceOfBirth);
		
		vClientProfileXDTO.ClientPhone = cmRemoveUTFControlSymbols(vClientRef.Phone);
		vClientProfileXDTO.ClientEmail = vClientRef.Email;
		vClientProfileXDTO.ClientFax = cmRemoveUTFControlSymbols(vClientRef.Fax);

		vClientAddress = TrimAll(vClientRef.Address);
		If Upper(TrimAll(pExternalSystemCode)) = "LOGISOFT_POS" And Not IsBlankString(vClientAddress) Then
			vClientAddress = cmParseAddress(vClientAddress).Country;
		EndIf;
		vClientProfileXDTO.Address = cmRemoveUTFControlSymbols(vClientAddress);	
		
		vIdentityDocumentType = vClientRef.IdentityDocumentType;
		vClientProfileXDTO.ClientIdentityDocumentCode			 = TrimAll(vIdentityDocumentType.Code);
		vClientProfileXDTO.ClientIdentityDocumentType			 = TrimAll(vIdentityDocumentType.Description);
	    vClientProfileXDTO.ClientIdentityDocumentSeries			 = vClientRef.IdentityDocumentSeries;
		vClientProfileXDTO.ClientIdentityDocumentNumber			 = vClientRef.IdentityDocumentNumber;
		vClientProfileXDTO.ClientIdentityDocumentIssueDate		 = vClientRef.IdentityDocumentIssueDate; 
		vClientProfileXDTO.ClientIdentityDocumentValidToDate	 = vClientRef.IdentityDocumentValidToDate; 
		vClientProfileXDTO.ClientIdentityDocumentIssuedBy		 = cmRemoveUTFControlSymbols(vClientRef.IdentityDocumentIssuedBy);
		vClientProfileXDTO.CIientIdentityDocumentUnitCode        = cmRemoveUTFControlSymbols(vClientRef.IdentityDocumentUnitCode);
	
		
		vClientProfileXDTO.ClientSendSMS = Not vClientRef.NoSMSDelivery;
		vClientProfileXDTO.IsIndividual = True;
	EndIf;
	
	// Add client bonuses
	If ValueIsFilled(vClientRef) Then
		vDocDiscountCard = Undefined;
		If ValueIsFilled(vFolio.ParentDoc) And 
			(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
			ValueIsFilled(vFolio.ParentDoc.DiscountCard) Then
			vDocDiscountCard = vFolio.ParentDoc.DiscountCard;
		EndIf;
		vClientObj = vClientRef.GetObject();
		vBonus = 0;
		vBonusAmount = vClientObj.pmGetBonusesAmount(vFolio.Hotel, vFolio.FolioCurrency, vDocDiscountCard, vBonus);
		If vCreditLimit < 999999999 Then
			vCreditLimit = vCreditLimit + vBonusAmount;
		EndIf;
	EndIf;
	
	vNoPost = False;
	vFolioParentDoc = vFolio.ParentDoc;
	If ValueIsFilled(vFolioParentDoc) And TypeOf(vFolioParentDoc) = Type("DocumentRef.Accommodation") And vFolioParentDoc.NoPost Then
		vNoPost = True;
		vCreditLimit = 0;
		vFolioBalance = 0;
	EndIf;
	
	// Build return string in CSV format
	vRetStr = """" + "" + """" + ","; //Error description 
	vRetStr = vRetStr + """" + TrimAll(TrimAll(vFolio.Number)) + """" + ",";
	vRetStr = vRetStr + """" + cmRemoveUTFControlSymbols(cmRemoveComma(vFolio.Description)) + """" + ",";
	vRetStr = vRetStr + """" + cmRemoveComma(vHotel.Description) + """" + ","; 
	vRetStr = vRetStr + """" + TrimAll(vFolio.Room) + """" + ",";
	vRetStr = vRetStr + """" + Format(vFolio.DateTimeFrom, "DF='dd.MM.yyyy HH:mm'") + """" + ",";
	vRetStr = vRetStr + """" + Format(vFolio.DateTimeTo, "DF='dd.MM.yyyy HH:mm'") + """" + ",";
	vRetStr = vRetStr + ?(ValueIsFilled(vFolio.GuestGroup), Format(vFolio.GuestGroup.Code, "ND=12; NFD=0; NZ=; NG="), 0) + ",";
	vRetStr = vRetStr + """" + cmRemoveUTFControlSymbols(cmRemoveComma(vFolio.Customer)) + """" + ",";
	vRetStr = vRetStr + """" + ?(ValueIsFilled(vFolio.Customer), TrimAll(vFolio.Customer.Code),"") + """" + ",";
	vRetStr = vRetStr + """" + cmRemoveComma(vFolio.PaymentMethod) + """" + ",";
	vRetStr = vRetStr + Format(vFolioBalance, "ND=17; NFD=2; NDS=.; NZ=; NG=") + ",";
	vRetStr = vRetStr + """" + TrimAll(vFolio.FolioCurrency.Code) + """" + ",";
	vRetStr = vRetStr + Format(vCreditLimit, "ND=17; NFD=2; NDS=.; NZ=; NG=") + ",";
	vRetStr = vRetStr + """" + ?(ValueIsFilled(vClientRef), cmRemoveUTFControlSymbols(cmRemoveComma(vClientRef.FullName)), "") + """" + ",";
	vRetStr = vRetStr + """" + ?(ValueIsFilled(vClientRef), TrimAll(vClientRef.Code), "") + """" + ",";
	vRetStr = vRetStr + ?(vDiscount <> 0, Format(vDiscount, "ND=6; NFD=2; NDS=.; NZ=; NG="), "0") + ",";
	vRetStr = vRetStr + """" + ?(ValueIsFilled(vDiscountType), cmRemoveComma(vDiscountType.Description), "") + """" + ",";
	vRetStr = vRetStr + """" + ?(ValueIsFilled(vDiscountCard), cmRemoveComma(vDiscountCard.Identifier), "") + """";

	// Build XDTO return object
	If pOutputType <> "CSV" Then
		vRetXDTO.FolioNumber = TrimAll(vFolio.Number);
		vRetXDTO.FolioDescription = cmRemoveUTFControlSymbols(Left(TrimAll(vFolio.Description), 4096));
		vRetXDTO.Hotel = TrimAll(vHotel.Description);
		vRetXDTO.Room = TrimAll(vFolio.Room);
		vRetXDTO.CheckInDate = vFolio.DateTimeFrom;
		vRetXDTO.CheckOutDate = vFolio.DateTimeTo;
		vRetXDTO.GuestGroup = ?(ValueIsFilled(vFolio.GuestGroup), vFolio.GuestGroup.Code, 0);
		vRetXDTO.Customer = cmRemoveUTFControlSymbols(TrimAll(vFolio.Customer));
		vRetXDTO.PaymentMethod = TrimAll(vFolio.PaymentMethod);
		vRetXDTO.FolioBalance = vFolioBalance;
		vRetXDTO.FolioCurrency = TrimAll(vFolio.FolioCurrency.Code);
		vRetXDTO.CreditLimit = vCreditLimit;
		vRetXDTO.Client = ?(ValueIsFilled(vClientRef), cmRemoveUTFControlSymbols(TrimAll(vClientRef.FullName)), "");
		vRetXDTO.ClientCode = ?(ValueIsFilled(vClientRef), TrimAll(vClientRef.Code), "");
		vRetXDTO.CustomerCode = ?(ValueIsFilled(vFolio.Customer), TrimAll(vFolio.Customer.Code), "");
		vRetXDTO.Discount = vDiscount;
		vRetXDTO.DiscountType = ?(ValueIsFilled(vDiscountType), cmGetObjectExternalSystemCodeByRef(vHotel,pExternalSystemCode,"DiscountTypes",vDiscountType), "");
		vRetXDTO.DiscountCard = ?(ValueIsFilled(vDiscountCard), TrimAll(vDiscountCard.Identifier), "");
		vRetXDTO.NoPost = vNoPost;
		
		vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);

		If vClientProfileXDTO <> Undefined Then
			vRetXDTO.ClientProfile = vClientProfileXDTO;	
		EndIf;
	
		If vCustomerProfileXDTO <> Undefined Then
			vRetXDTO.CustomerProfile = vCustomerProfileXDTO;
		EndIf;
	Else
		vExtraXML = NStr("en='Return string: ';ru='Строка возврата: ';de='Zeilenrücklauf: '") + vRetStr;
	EndIf;
	vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
	If vWriteDebug Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , vExtraXML, vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vExtraXML);
	EndIf;
	
	// Return based on output type
	If pOutputType = "CSV" Then
		Return vRetStr;
	Else
		Return vRetXDTO;
	EndIf;
EndFunction // cmGetFolioDescription 

// -----------------------------------------------------------------------------
// Description: Returns Guest Structure by folio number
//              Function could be called as web-service
// Parameters: Folio number, Hotel code, External system code
// Return value: XDTO object with the list of guests with 1 item in the same format as by room or by card
// -----------------------------------------------------------------------------
Function cmGetFolioGuestsList(pFolioNumber, pHotelCode = "", pExternalSystemCode = "TraktirFO3") Export
	// Log input parameters
	vInputParameters = NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode + Chars.LF + 
						NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + pHotelCode + Chars.LF + 
						NStr("en='Folio number: ';ru='Номер фолио: ';de='Folionummer: '") + pFolioNumber;
	// Get hotel
	vHotel = SessionParameters.CurrentHotel;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
	EndIf;

	vWriteDebug = False;
	If Not IsBlankString(pExternalSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExternalSystemCode, vHotel);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	vFuncLog = NStr("en='Get folio description';ru='Получить данные лицевого счета';de='Daten der Personenkontos erhalten'");
	If vWriteDebug Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vInputParameters);
	EndIf;
		
	// Get folio reference by folio number
	vFolio = cmFindFolioByNumber(pFolioNumber, vHotel);
	If Not ValueIsFilled(vFolio) Then
		vMsg = NStr("en='Folio was not found!';ru='Лицевой счет не найден по номеру!';de='Das Personenkonto wurde nach der Nummer nicht gefunden!'");
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , , vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vMsg);
		EndIf;

		Raise vMsg;
	EndIf;
	If ValueIsFilled(vFolio.Hotel) Then
		vHotel = vFolio.Hotel;
	EndIf;
	If vFolio.IsClosed Then
		vMsg = NStr("en='Folio is closed!';ru='Лицевой счет закрыт!';de='Das Personenkonto ist geschlossen!'");
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , , vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vMsg);
		EndIf;

		Raise vMsg;
	EndIf;
	If Not ValueIsFilled(vFolio.Customer) And Not ValueIsFilled(vFolio.Client) Then
		vMsg = NStr("en='It is not allowed to charge this folio. Folio owner is not specified.';ru='Лицевой счет нельзя использовать для данного способа закрытия заказа! Не задан владелец фолио.';de='Das Personenkonto darf nicht für diese Art der Bestellschließung verwendet werden! Der Folio-Besitzer ist nicht angegeben.'");
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , , vMsg, vInteraction.MaxLogLenght);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vMsg);
		EndIf;
		
		Raise vMsg;
	EndIf;
	
	// Init variables
	vRoomRateCode = "";
	vRoomRateName = "";
	vMealBoardTerm    = "";
	vMealBoardName    = "";
	vReservationRemarks = "";
	vIsCheckedOut = False;
	vIsRoomShare = False;
	vAccommodationCode = "";
	// Get folio balance
	vLimit = 0;
	vFolioBalance = vFolio.GetObject().pmGetBalance( , , , vLimit);
	vFolioBalance = vFolioBalance + vLimit;
	
	// Get discount data
	vDiscount = 0;
	vDiscountType = Undefined;
	vDiscountCard = Undefined;
	If ValueIsFilled(vFolio.FolioDiscountCard) Then
		vDiscountCard = vFolio.FolioDiscountCard;
		vDiscountType = vDiscountCard.DiscountType;
		If ValueIsFilled(vDiscountType) Then
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		EndIf;
	ElsIf ValueIsFilled(vFolio.FolioDiscountType) Then
		vDiscountType = vFolio.FolioDiscountType;
		vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
	ElsIf ValueIsFilled(vFolio.ParentDoc) And 
		(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
		ValueIsFilled(vFolio.ParentDoc.DiscountCard) Then
		vDiscountCard = vFolio.ParentDoc.DiscountCard;
		vDiscountType = vDiscountCard.DiscountType;
		vDiscount = vFolio.ParentDoc.Discount;
	ElsIf ValueIsFilled(vFolio.ParentDoc) And 
		(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
		ValueIsFilled(vFolio.ParentDoc.DiscountType) Then
		vDiscountType = vFolio.ParentDoc.DiscountType;
		vDiscount = vFolio.ParentDoc.Discount;
	ElsIf ValueIsFilled(vFolio.Client) Then
		If ValueIsFilled(vFolio.Client.DiscountType) Then
			vDiscountType = vFolio.Client.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		Else
			vDiscountCard = cmGetDiscountCardByClient(vFolio.Client);
			If ValueIsFilled(vDiscountCard) And ValueIsFilled(vDiscountCard.DiscountType) Then
				vDiscountType = vDiscountCard.DiscountType;
				vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(vDiscountType) And vDiscountType.DoNotExportToExternalInterfaces Then
		vDiscount = 0;
		vDiscountType = Undefined;
		vDiscountCard = Undefined;
	EndIf;
	
	vCreditLimit = vFolio.CreditLimit;
	If vFolio.IsClosed Then
		vCreditLimit = 0;
	Else
		If ValueIsFilled(vHotel) And vHotel.NoCreditLimit Then
			vCreditLimit = 999999999;
		EndIf;
		If ValueIsFilled(vFolio.Customer) And
			(Not ValueIsFilled(vFolio.ParentDoc) Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) Then
			vCreditLimit = 999999999;
		EndIf;
	EndIf;
	
	// Add client bonuses
	If ValueIsFilled(vFolio.Client) Then
		vDocDiscountCard = Undefined;
		If ValueIsFilled(vFolio.ParentDoc) And 
			(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
			ValueIsFilled(vFolio.ParentDoc.DiscountCard) Then
			vDocDiscountCard = vFolio.ParentDoc.DiscountCard;
		EndIf;
		vClientObj = vFolio.Client.GetObject();
		vBonus = 0;
		vBonusAmount = vClientObj.pmGetBonusesAmount(vFolio.Hotel, vFolio.FolioCurrency, vDocDiscountCard, vBonus);
		If vCreditLimit < 999999999 Then
			vCreditLimit = vCreditLimit + vBonusAmount;
		EndIf;
	EndIf;
	
	vNoPost = False;
	vIsCheckedOut = vFolio.IsClosed;
	vFolioParentDoc = vFolio.ParentDoc;
	If ValueIsFilled(vFolioParentDoc) Then
		If TypeOf(vFolioParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolioParentDoc) = Type("DocumentRef.Accommodation") Then
			vRoomRateCode = ?(ValueIsFilled(vFolioParentDoc.RoomRate), vFolioParentDoc.RoomRate.Code, "");
			vRoomRateName = ?(ValueIsFilled(vFolioParentDoc.RoomRate), vFolioParentDoc.RoomRate.Description, "");;
			vAccommodationCode = vFolioParentDoc.Number;
			If ValueIsFilled(vFolioParentDoc.ServicePackage) And vFolioParentDoc.ServicePackage.IsMealBoardTerm Then
				vMealBoardTerm = vFolioParentDoc.ServicePackage.Code; 
				vMealBoardTermName = vFolioParentDoc.ServicePackage.Description;
			EndIf;
			If ValueIsFilled(vFolioParentDoc.AccommodationType) And vFolioParentDoc.AccommodationType.Type <> Enums.AccomodationTypes.Room Then
				vIsRoomShare = True;
			EndIf;	
		EndIf;
		If TypeOf(vFolioParentDoc) = Type("DocumentRef.Accommodation") Then
			If vFolioParentDoc.NoPost Then
				vNoPost = True;
				vCreditLimit = 0;
				vFolioBalance = 0;
			EndIf;
		EndIf;
		vReservationRemarks = vFolioParentDoc.Remarks;
	EndIf;
	vOrdersXDTO = GetOrdersXDTO(vFolioParentDoc, pExternalSystemCode);
	vServicePackagesXDTO = GetServicePackagesXDTO(vFolioParentDoc);
	
	// Initialize return parameters				  
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestsList"));
	vGuestItemType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestItem");
	vGuestItemsType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestItems");
	
	vRetXDTO.GuestItems = XDTOFactory.Create(vGuestItemsType);
				
	vGuestItem = XDTOFactory.Create(vGuestItemType);
		
	vGuestItem.FolioNumber = TrimAll(vFolio.Number);
	vGuestItem.FolioDescription = Left(TrimAll(vFolio.Description), 4096);
	
	vGuest = vFolio.Client;
	
	If ValueIsFilled(vGuest) Then
		vGuestItem.Guest 			= cmRemoveUTFControlSymbols(cmRemoveComma(vGuest.FullName) + ?(ValueIsFilled(vDiscountCard), "(DC " + TrimAll(vDiscountCard.Identifier) + ")", ""));
		vGuestItem.GuestCode 		= vGuest.Code;
		vGuestItem.GuestSex 		= Upper(Left(TrimAll(vGuest.Sex), 1));
		vGuestItem.GuestDateOfBirth = vGuest.DateOfBirth;
		vGuestItem.GuestAge 		= vGuest.Age;
		If ValueIsFilled(vGuest.Citizenship) Then
			vGuestItem.GuestCitizenship = TrimAll(vGuest.Citizenship.ISOCode3);
		Else
			vGuestItem.GuestCitizenship = "";
		EndIf;
		vGuestItem.GuestLanguage 	= Upper(TrimAll(vGuest.Language.Code));
		vGuestItem.GuestLocale = ?(IsBlankString(vGuest.Language.LocalizationCode), "ru_RU", TrimAll(vGuest.Language.LocalizationCode));
		vGuestItem.GuestRemarks     = TrimAll(vGuest.Remarks);
		vGuestItem.GuestPhone       = vGuest.Phone;
	Else
		vGuestItem.Guest 			= "";
		vGuestItem.GuestCode 		= "";
		vGuestItem.GuestSex 		= "";
		vGuestItem.GuestAge 		= 0;
		vGuestItem.GuestCitizenship = "";
		vGuestItem.GuestLanguage 	= "";
		vGuestItem.GuestLocale = "";
		vGuestItem.GuestRemarks     = "";
		vGuestItem.GuestPhone       = "";
	EndIf;
	vGuestItem.Hotel 			= cmRemoveComma(vFolio.Hotel);
	vGuestItem.Room 			= ?(ValueIsFilled(vFolio.Room),TrimAll(vFolio.Room.Description),"");
	vGuestItem.CheckInDate 		= vFolio.DateTimeFrom;
	vGuestItem.CheckOutDate 	= vFolio.DateTimeTo;
	vGuestItem.GuestGroup 		= ?(ValueIsFilled(vFolio.GuestGroup),vFolio.GuestGroup.Code,0);
	vGuestItem.Customer 		= cmRemoveComma(vFolio.Customer);
	vGuestItem.PaymentMethod 	= TrimAll(vFolio.PaymentMethod);
	vGuestItem.ClientBalance 	= vFolioBalance;
	vGuestItem.CreditLimit 		= vLimit;
	vGuestItem.FolioCurrency 	= ?(ValueIsFilled(vFolio.FolioCurrency),vFolio.FolioCurrency.Code,"");
	vGuestItem.RoomRateCode		= vRoomRateCode;
	vGuestItem.RoomRate 		= vRoomRateName;
	vGuestItem.Discount 		= vDiscount;
	vGuestItem.DiscountType 	= ?(ValueIsFilled(vDiscountType), cmGetObjectExternalSystemCodeByRef(vHotel, pExternalSystemCode, "DiscountTypes", vDiscountType, False),"");
	vGuestItem.DiscountCard 	= ?(ValueIsFilled(vDiscountCard), TrimAll(vDiscountCard.Identifier), "");
	vGuestItem.NoPost           = vNoPost;
	
	vGuestItem.AccommodationCode= vAccommodationCode;
	vGuestItem.IsRoomShare 		= vIsRoomShare;
	vGuestItem.MealBoardTerm    = vMealBoardTerm;
	vGuestItem.MealBoardName    = vMealBoardTermName;
	
	vGuestItem.Orders = vOrdersXDTO;
	vGuestItem.ServicePackages = vServicePackagesXDTO;
	vGuestItem.ReservationRemarks = Left(cmRemoveComma(vReservationRemarks),1024);
	
	If ValueIsFilled(vDiscountCard) And TypeOf(vDiscountCard) = Type("CatalogRef.DiscountCards") Then
		vDiscountCardInfo = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vDiscountCard);
		vDiscountCardInfoXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "DiscountCardInfo"));
		vDiscountCardInfoXDTO.CardBalance             	 = vDiscountCardInfo.Balance;
		vDiscountCardInfoXDTO.MaxPercentPayment			 = vDiscountCardInfo.MaxPercentPayment;
		vDiscountCardInfoXDTO.TypeCard 				  	 = vDiscountCardInfo.TypeCard;
		vDiscountCardInfoXDTO.CertificateNominal      	 = vDiscountCardInfo.CertificateNominal;
		vDiscountCardInfoXDTO.BonusRate       			 = vDiscountCardInfo.BonusRate;
		vDiscountCardInfoXDTO.ValidFrom					 = vDiscountCard.ValidFrom;
		vDiscountCardInfoXDTO.ValidTo					 = vDiscountCard.ValidTo;
		
		vGuestItem.DiscountCardInfo = vDiscountCardInfoXDTO;
	Else
		vDiscountCardInfoXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "DiscountCardInfo"));
		vDiscountCardInfoXDTO.CardBalance             	 = 0;
		vDiscountCardInfoXDTO.MaxPercentPayment			 = 0;
		vDiscountCardInfoXDTO.TypeCard 				  	 = "";
		vDiscountCardInfoXDTO.CertificateNominal      	 = 0;
		vDiscountCardInfoXDTO.BonusRate       			 = 1;
		vDiscountCardInfoXDTO.ValidFrom					 = Date(1, 1, 1);
		vDiscountCardInfoXDTO.ValidTo					 = Date(1, 1, 1);

		vGuestItem.DiscountCardInfo 			   			 = vDiscountCardInfoXDTO;	
	EndIf;
	
	vGuestItem.IsCheckedOut = vIsCheckedOut;
	vGuestItem.IsBlocked = False;
	vGuestItem.BlockReason = "";
	
	vGuestItem.GuestPhoto = "";
	If ValueIsFilled(vGuest) Then
		vGuestPhoto = vGuest.Photo.Get();
		If TypeOf(vGuestPhoto) = Type("Picture") Then
			vGuestItem.GuestPhoto = Base64String(vGuestPhoto.GetBinaryData());
		ElsIf TypeOf(vGuestPhoto) = Type("BinaryData") Then
			vGuestItem.GuestPhoto = Base64String(vGuestPhoto);
		Else
			vGuestItem.GuestPhoto = "";
		EndIf;
	EndIf;
	
	vRetXDTO.GuestItems.GuestItem.Add(vGuestItem);

	// log
	vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
	vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
	If vWriteDebug Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , vExtraXML, vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vExtraXML);
	EndIf;

	// Return based on output type
	Return vRetXDTO;
EndFunction // cmGetFolioDescription 

// -----------------------------------------------------------------------------
Function cmGetInvoiceList(pPeriodFrom, pPeriodTo, pCompanyCode="") Export 
	WriteLogEvent(NStr("en='GetInvoiceList'; ru='ИнтерфейсСБухгалтерией.Получение счетов на оплату, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom+Chars.LF+NStr("en='Date to: '; ru='Дата окончания: '")+pPeriodTo
	+Chars.LF+NStr("en='Company code: '; ru='Код фирмы: '")+pCompanyCode);
	
	vInvoiceTableType 				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "InvoiceTable");
	vInvoiceTableRowType			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "InvoiceTableRow");
	vInvoiceListType 				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "InvoiceList");
	vInvoiceTableServicesType 		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "InvoiceTableServices");
	vInvoiceTableServicesRowType	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "InvoiceTableServicesRow");
	vServicesItemRowType			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "ServicesItemRow");
	vAccountingCustomerType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow");
	vAccountingContractType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AccountingContract");
	vCompanyType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CompanyItemRow");
	vHotelType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "HotelParameters");
	vAccountingCurrencyType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AccountingCurrency");
	vVATRateType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "VATRate");
	vGuestGroupType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "GuestGroup");
	vClientType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Client");
	vRoomType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Room");
	vFolioType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Folio");
	vParentDocType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "ParentDoc");
	
	vRetXDTO 						= XDTOFactory.Create(vInvoiceListType);
	vRetXDTO.InvoiceTable			= XDTOFactory.Create(vInvoiceTableType);
	vRetXDTO.ErrorDescription 	= "";
	
	Try
		vQry = New Query;
		vQry.Text = 
		"SELECT DISTINCT
		|	InvoiceServices.Ref AS Ref
		|FROM
		|	Document.ProformaInvoice.Services AS InvoiceServices
		|WHERE
		|	InvoiceServices.Ref.ChangeDate >= &qPeriodFrom
		|	AND InvoiceServices.Ref.ChangeDate <= &qEndOfTimes
		|	AND InvoiceServices.Ref.Posted
		|	AND InvoiceServices.Sum <> 0
		|	AND CASE
		|			WHEN &qCompanyCode = """"
		|				THEN TRUE
		|			ELSE InvoiceServices.Ref.Company.ExternalCode = &qCompanyCode
		|		END
		|
		|ORDER BY
		|	InvoiceServices.Ref.Date";
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qEndOfTimes",pPeriodTo);
		vQry.SetParameter("qCompanyCode",pCompanyCode);
		vTrans = vQry.Execute().Unload();
		For Each mRow In vTrans Do
			vInvoiceRow  		= XDTOFactory.Create(vInvoiceTableRowType);
			vAccountingCustomer = XDTOFactory.Create(vAccountingCustomerType);
			vAccountingContract = XDTOFactory.Create(vAccountingContractType); 
			vCompany			= XDTOFactory.Create(vCompanyType);
			vHotel              = XDTOFactory.Create(vHotelType);
			vGuestGroup			= XDTOFactory.Create(vGuestGroupType);
			vAccountingCurrency	= XDTOFactory.Create(vAccountingCurrencyType);
			
			vInvoiceRef                                 =  mRow.Ref;
			vInvoiceCustomer                            =  vInvoiceRef.AccountingCustomer;
			
			FillPropertyValues(vAccountingCustomer,	vInvoiceCustomer); 
			vSourcesOfBusiness = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "SourcesOfBusiness"));
			vSB = vInvoiceCustomer.SourceOfBusiness;
			If ValueIsFilled(vSB) Then
				vSourcesOfBusiness.Code = TrimAll(vSB.Code);	
				vSourcesOfBusiness.Description = TrimAll(vSB.Description);	
			Else
				vSourcesOfBusiness.Code = "";	
				vSourcesOfBusiness.Description = "";
			EndIf;	 
			vAccountingCustomer.SourcesOfBusiness = vSourcesOfBusiness;

			
			vAccountingContract.Code 					=  ?(ValueIsFilled(vInvoiceRef.AccountingContract),vInvoiceRef.AccountingContract.Code, "");
			vAccountingContract.Description 			=  vInvoiceRef.AccountingContract.Description;
			vAccountingContract.ExternalCode 			=  vInvoiceRef.AccountingContract.ExternalCode;
			
			vCompany.Code 								=  ?(ValueIsFilled(vInvoiceRef.Company), vInvoiceRef.Company.Code, "");
			vCompany.Description 						=  vInvoiceRef.Company.Description;
			vCompany.ExternalCode 						=  vInvoiceRef.Company.ExternalCode;
			
			vAccountingCurrency.Code 					=  ?(ValueIsFilled(vInvoiceRef.AccountingCurrency),vInvoiceRef.AccountingCurrency.Code, "");
			vAccountingCurrency.Description 			=  vInvoiceRef.AccountingCurrency.Description;
			
			//Fill Hotel
			FillPropertyValues(vHotel,vInvoiceRef.Hotel);
			
			vGuestGroupRef                                 = vInvoiceRef.GuestGroup;
			vGuestGroup.Code 							=  ?(ValueIsFilled(vGuestGroupRef), Format(vGuestGroupRef.Code, "NG=0"), "");
			vGuestGroup.Description 					=  vGuestGroupRef.Description;
			vGuestGroup.ExternalCode 					=  vGuestGroupRef.ExternalCode;
			vGuestGroup.CheckInDate 					=  vGuestGroupRef.CheckInDate;
			vGuestGroup.CheckOutDate 					=  vGuestGroupRef.CheckOutDate;
			
			vTableServices	= XDTOFactory.Create(vInvoiceTableServicesType);
			For Each vRow In vInvoiceRef.Services Do
				If vRow.Service.DoNotExportToTheAccountingSystem Then
					Continue;
				EndIf;
				vService			= XDTOFactory.Create(vServicesItemRowType);
				vServiceRow  		= XDTOFactory.Create(vInvoiceTableServicesRowType);
				vVATRate            = XDTOFactory.Create(vVATRateType); 
				vClient				= XDTOFactory.Create(vClientType);
				vRoom				= XDTOFactory.Create(vRoomType);
				vFolio				= XDTOFactory.Create(vFolioType);
				vParentDoc			= XDTOFactory.Create(vParentDocType);
				
				vClient.Code 								=  ?(ValueIsFilled(vRow.Client),vRow.Client.Code, "");
				vClient.Description 						=  vRow.Client.Description;
				
				vRoom.Code 									=  "";
				vRoom.Description 							=  ?(TypeOf(vRow.Room) = Type("CatalogRef.Rooms"), vRow.Room.Description, vRow.Room);;
				
				vFolioGuestGroup                       		=  XDTOFactory.Create(vGuestGroupType);  
				vFolioGuestGroup.Code 						=  ?(ValueIsFilled(vRow.GuestGroup), vRow.GuestGroup.Code, "");
				vFolioGuestGroup.Description 				=  vRow.GuestGroup.Description;
				vFolioGuestGroup.ExternalCode 				=  vRow.GuestGroup.ExternalCode;
				
				vFolio.DateTimeFrom 						=  vRow.DateTimeFrom;
				vFolio.DateTimeTo 							=  vRow.DateTimeTo;
				vFolio.Number 								=  "N\A";
				vFolio.Description 							=  "N\A";
				vFolio.GuestGroup 							=  vFolioGuestGroup;
				vFolio.ParentDoc 							=  vParentDoc;
				
				vService.Code							=  vRow.Service.Code;
				vService.Description  					=  vRow.Service.Description;
				vService.ExternalCode       			=  vRow.Service.ExternalCode;
				vService.IsRoomRevenue       			=  vRow.Service.IsRoomRevenue;
				vService.ServiceTypeDescription   		=  ?(ValueIsFilled(vRow.Service.ServiceType),vRow.Service.ServiceType.Description, "");
				vService.ServiceTypeCode   		 		=  ?(ValueIsFilled(vRow.Service.ServiceType),vRow.Service.ServiceType.Code, "");
				vService.IsAgentService					=  vRow.Service.IsAgentService;
				vService.HotelDescription 				=  vInvoiceRef.Hotel.Description;
				vService.HotelCode 						=  vInvoiceRef.Hotel.Code;
				
				vVATRate.TaxRate                        =  vRow.VATRate.TaxRate;
				vVATRate.Description                    =  vRow.VATRate.Description;
				
				vServiceRow.Service                     =  vService;
				vServiceRow.Quantity                    =  ?(vRow.Quantity > 0, vRow.Quantity, 1);
				vServiceRow.VATRate                     =  vVATRate;
				vServiceRow.Client						=  vClient;
				vServiceRow.Folio						=  vFolio;
				vServiceRow.Room						=  vRoom;
				
				If ValueIsFilled(vInvoiceCustomer) And vInvoiceCustomer.DoNotPostCommission Then
					vServiceRow.Sum                     =  vRow.Sum;
					vServiceRow.VatSum                  =  vRow.VATSum;
				Else
					If vRow.CommissionSum <> 0 Then 
						vServiceRow.Sum                 =  vRow.Sum - vRow.CommissionSum; 
						vServiceRow.VatSum              =  vRow.VATSum - vRow.VATCommissionSum;
					Else	
						vServiceRow.Sum                 =  vRow.Sum;
						vServiceRow.VatSum              =  vRow.VATSum;
					EndIf;
				EndIf;
				
				vServiceRow.Price                    	=  Round(vServiceRow.Sum / vServiceRow.Quantity, 2);
				vServiceRow.Remarks                     =  vRow.Remarks;
				
				vTableServices.InvoiceTableServicesRow.Add(vServiceRow);	
			EndDo;
			
			vInvoiceRow.Number							=  vInvoiceRef.Number;
			vInvoiceRow.AccountingCustomer				=  vAccountingCustomer;
			vInvoiceRow.AccountingContract				=  vAccountingContract;
			vInvoiceRow.ExternalCode					=  vInvoiceRef.ExternalCode;
			vInvoiceRow.Period							=  vInvoiceRef.Date;
			vInvoiceRow.AccountingCurrency   			=  vAccountingCurrency;
			vInvoiceRow.Company							=  vCompany;
			vInvoiceRow.Hotel							=  vHotel;
			vInvoiceRow.GuestGroup						=  vGuestGroup;
			vInvoiceRow.TableServices					=  vTableServices;
			
			vRetXDTO.InvoiceTable.InvoiceTableRow.Add(vInvoiceRow);
		EndDo;
		
		Return vRetXDTO;
		
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Runtime Error'; ru='ИнтерфейсСБухгалтерией.Ошибка получения счетов на оплату'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") +vError);
		vRetXDTO.ErrorDescription = vError;
		Return  vRetXDTO;
	EndTry;
EndFunction	  //cmGetInvoiceList

// -----------------------------------------------------------------------------
Function cmGetServices(pPeriodFrom,pPeriodTo,pCompanyCode="") Export 
	WriteLogEvent(NStr("en='Get services list'; ru='ИнтерфейсСБухгалтерией.Получение списка услуг, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom+Chars.LF+NStr("en='Date to: '; ru='Дата окончания: '") + pPeriodTo
	+Chars.LF+NStr("en='Company code: '; ru='Код фирмы: '")+pCompanyCode);
	
	vServiceType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Services");
	vServiceItemRowType 	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "ServicesItemRow");
	vServiceListType 		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "ServicesList");
	
	vRetXDTO 				= XDTOFactory.Create(vServiceListType);
	vRetXDTO.Services   	= XDTOFactory.Create(vServiceType);
	vRetXDTO.ErrorDescription 	= "";
	
	Try
		vQry = New Query;
		vQry.Text = "SELECT
		|	UsedServices.Service.Code AS Code,
		|	UsedServices.Service.Description AS Description,
		|	UsedServices.Service.ExternalCode AS ExternalCode,
		|	UsedServices.Service
		|FROM
		|	(SELECT
		|		AccountsReceivableTurnovers.Service AS Service,
		|		AccountsReceivableTurnovers.Company AS Company
		|	FROM
		|		AccumulationRegister.AccountsReceivable.Turnovers(&qPeriodFrom, &qPeriodTo, Period, ) AS AccountsReceivableTurnovers
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		InvoiceServices.Service,
		|		InvoiceServices.Ref.Company
		|	FROM
		|		Document.ProformaInvoice.Services AS InvoiceServices
		|	WHERE
		|		InvoiceServices.Ref.Posted
		|		AND InvoiceServices.Ref.ChangeDate >= &qPeriodFrom
		|		AND InvoiceServices.Ref.ChangeDate <= &qPeriodTo) AS UsedServices
		|WHERE
		|	CASE
		|			WHEN &qCompanyCode = """"
		|				THEN TRUE
		|			ELSE UsedServices.Company.ExternalCode = &qCompanyCode
		|		END
		|
		|GROUP BY
		|	UsedServices.Service.Code,
		|	UsedServices.Service.Description,
		|	UsedServices.Service.ExternalCode,
		|	UsedServices.Service";
		
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", pPeriodTo);
		vQry.SetParameter("qCompanyCode", pCompanyCode);
		vTrans = vQry.Execute().Unload();
		
		WriteLogEvent(NStr("en='Get services list'; ru='ИнтерфейсСБухгалтерией.Получение списка услуг, инфо'"), EventLogLevel.Information, 
		, , NStr("en='Services count: '; ru='Количество полученных услуг: '") +vTrans.Count());
		
		
		For Each mRow In vTrans Do
			If Not ValueIsFilled(mRow.Service) Then
				Continue;
			EndIf;
			vServiceItemRow = XDTOFactory.Create(vServiceItemRowType);
			
			vServiceItemRow.Code					 =  mRow.Code;
			vServiceItemRow.Description  			 =  mRow.Description;
			vServiceItemRow.ExternalCode    		 =  mRow.ExternalCode;
			vServiceItemRow.IsRoomRevenue   		 =  mRow.Service.IsRoomRevenue;
			vServiceItemRow.ServiceTypeDescription   =  ?(ValueIsFilled(mRow.Service.ServiceType), mRow.Service.ServiceType.Description, "");
			vServiceItemRow.ServiceTypeCode   		 =  ?(ValueIsFilled(mRow.Service.ServiceType), mRow.Service.ServiceType.Code, "");
			vServiceItemRow.IsAgentService			 =  mRow.Service.IsAgentService;
			vRetXDTO.Services.ServicesItemRow.Add(vServiceItemRow);
		EndDo;
		
		Return vRetXDTO;	
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Runtime Error'; ru='ИнтерфейсСБухгалтерией.Ошибка получения списка услуг'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") + vError);
		vRetXDTO.ErrorDescription = vError;
		Return  vRetXDTO;
	EndTry;
EndFunction  //cmGetServices

// -----------------------------------------------------------------------------
Function cmGetHotelServices(pPeriodFrom,pPeriodTo,pCompanyCode="", pHotelCode="") Export 
	WriteLogEvent(NStr("en='Get services list'; ru='ИнтерфейсСБухгалтерией.Получение списка услуг, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom+Chars.LF+NStr("en='Date to: '; ru='Дата окончания: '")+ pPeriodTo
	+Chars.LF+NStr("en='Company code: '; ru='Код фирмы: '")+pCompanyCode
	+Chars.LF+NStr("en='Hotel code: '; ru='Гостиница: '")+pHotelCode);
	
	vServiceType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Services");
	vServiceItemRowType 	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "ServicesItemRow");
	vServiceListType 		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "ServicesList");
	
	vRetXDTO 				= XDTOFactory.Create(vServiceListType);
	vRetXDTO.Services   	= XDTOFactory.Create(vServiceType);
	vRetXDTO.ErrorDescription 	= "";
	
	Try
		vQry = New Query;
		vQry.Text = "SELECT
		|	UsedServices.Hotel AS Hotel,
		|	UsedServices.Service.Code AS Code,
		|	UsedServices.Service.Description AS Description,
		|	UsedServices.Service.ExternalCode AS ExternalCode,
		|	UsedServices.Service
		|FROM
		|	(SELECT
		|		AccountsReceivableTurnovers.Hotel AS Hotel,
		|		AccountsReceivableTurnovers.Service AS Service,
		|		AccountsReceivableTurnovers.Company AS Company
		|	FROM
		|		AccumulationRegister.AccountsReceivable.Turnovers(&qPeriodFrom, &qPeriodTo, Period, ) AS AccountsReceivableTurnovers
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		InvoiceServices.Ref.Hotel,
		|		InvoiceServices.Service,
		|		InvoiceServices.Ref.Company
		|	FROM
		|		Document.ProformaInvoice.Services AS InvoiceServices
		|	WHERE
		|		InvoiceServices.Ref.Posted
		|		AND InvoiceServices.Ref.ChangeDate >= &qPeriodFrom
		|		AND InvoiceServices.Ref.ChangeDate <= &qPeriodTo) AS UsedServices
		|WHERE
		|	CASE
		|			WHEN &qCompanyCode = """"
		|				THEN TRUE
		|			ELSE UsedServices.Company.ExternalCode = &qCompanyCode
		|			END
		|
		|GROUP BY
		|	UsedServices.Hotel,
		|	UsedServices.Service.Code,
		|	UsedServices.Service.Description,
		|	UsedServices.Service.ExternalCode,
		|	UsedServices.Service";
		
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", pPeriodTo);
		vQry.SetParameter("qCompanyCode", pCompanyCode);
		vTrans = vQry.Execute().Unload();
		
		WriteLogEvent(NStr("en='Get services list'; ru='ИнтерфейсСБухгалтерией.Получение списка услуг, инфо'"), EventLogLevel.Information, 
		, , NStr("en='Services count: '; ru='Количество полученных услуг: '") + vTrans.Count());
		
		
		For Each mRow In vTrans Do
			If Not ValueIsFilled(mRow.Service) Then
				Continue;
			EndIf;
			vServiceItemRow = XDTOFactory.Create(vServiceItemRowType);
			
			vServiceItemRow.Code					 =  mRow.Code;
			vServiceItemRow.Description  			 =  mRow.Description;
			vServiceItemRow.ExternalCode    		 =  mRow.ExternalCode;
			vServiceItemRow.IsRoomRevenue   		 =  mRow.Service.IsRoomRevenue;
			vServiceItemRow.ServiceTypeDescription   =  ?(ValueIsFilled(mRow.Service.ServiceType), mRow.Service.ServiceType.Description, "");
			vServiceItemRow.ServiceTypeCode   		 =  ?(ValueIsFilled(mRow.Service.ServiceType), mRow.Service.ServiceType.Code, "");
			vServiceItemRow.IsAgentService			 =  mRow.Service.IsAgentService;
			vServiceItemRow.HotelDescription		 =  ?(ValueIsFilled(mRow.Hotel), mRow.Hotel.Description, "");
			vServiceItemRow.HotelCode   		 	 =  ?(ValueIsFilled(mRow.Hotel), mRow.Hotel.Code, "");
			vRetXDTO.Services.ServicesItemRow.Add(vServiceItemRow);
		EndDo;
		
		Return vRetXDTO;	
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Runtime Error'; ru='ИнтерфейсСБухгалтерией.Ошибка получения списка услуг'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") + vError);
		vRetXDTO.ErrorDescription = vError;
		Return  vRetXDTO;
	EndTry;
EndFunction  //cmGetHotelServices

// -----------------------------------------------------------------------------
Function cmGetCustomers(pPeriodFrom, pPeriodTo, pCompanyCode = "") Export
	WriteLogEvent(NStr("en='Get customers list'; ru='ИнтерфейсСБухгалтерией.Получение списка контрагентов, входящие параметры'"), EventLogLevel.Information, , , 
	NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom + Chars.LF + 
	NStr("en='Date to: '; ru='Дата окончания: '") + pPeriodTo + Chars.LF + 
	NStr("en='Company code: '; ru='Код фирмы: '") + pCompanyCode);
	
	vCustomers 				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Customers");
	vCustomersItemRowType 	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow");
	vCustomersListType 		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersList");
	
	vRetXDTO 				= XDTOFactory.Create(vCustomersListType);
	vRetXDTO.Customers   	= XDTOFactory.Create(vCustomers);
	vRetXDTO.ErrorDescription 	= "";
	
	Try
		vQry = New Query;
		vQry.Text = 
		"SELECT
		|	Common.Customer.Code AS Code,
		|	Common.Customer.Description AS Description,
		|	Common.Customer.TIN AS TIN,
		|	Common.Customer.KPP AS KPP,
		|	Common.Customer.ExternalCode AS ExternalCode,
		|	Common.Customer AS Customer
		|FROM
		|	(SELECT
		|		CashRegisterDailyReceiptsTurnovers.Customer AS Customer
		|	FROM
		|		AccumulationRegister.CashRegisterDailyReceipts.Turnovers(&qPeriodFrom, &qPeriodTo, Period, ) AS CashRegisterDailyReceiptsTurnovers
		|	WHERE
		|		(&qCompanyCodeIsEmpty
		|				OR NOT &qCompanyCodeIsEmpty
		|					AND CashRegisterDailyReceiptsTurnovers.Company.ExternalCode = &qCompanyCode)
		|	
		|	GROUP BY
		|		CashRegisterDailyReceiptsTurnovers.Customer
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		AccountsReceivableTurnovers.AccountingCustomer
		|	FROM
		|		AccumulationRegister.AccountsReceivable.Turnovers(
		|				,
		|				,
		|				Period,
		|				&qCompanyCodeIsEmpty
		|					OR NOT &qCompanyCodeIsEmpty
		|						AND Company.ExternalCode = &qCompanyCode
		|						AND (Settlement.ChangeDate >= &qPeriodFrom
		|							AND Settlement.ChangeDate <= &qPeriodTo)) AS AccountsReceivableTurnovers
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		InvoiceServices.Ref.AccountingCustomer
		|	FROM
		|		Document.ProformaInvoice.Services AS InvoiceServices
		|	WHERE
		|		InvoiceServices.Ref.ChangeDate >= &qPeriodFrom
		|		AND InvoiceServices.Ref.ChangeDate <= &qPeriodTo
		|		AND (&qCompanyCodeIsEmpty
		|				OR NOT &qCompanyCodeIsEmpty
		|					AND InvoiceServices.Ref.Company.ExternalCode = &qCompanyCode)
		|		AND InvoiceServices.Ref.DeletionMark = FALSE
		|		AND InvoiceServices.Ref.Posted = TRUE) AS Common
		|WHERE
		|	NOT Common.Customer.Code IS NULL
		|
		|GROUP BY
		|	Common.Customer.ExternalCode,
		|	Common.Customer.TIN,
		|	Common.Customer.KPP,
		|	Common.Customer.Code,
		|	Common.Customer.Description,
		|	Common.Customer
		|
		|ORDER BY
		|	Common.Customer.Description";
		vQry.SetParameter("qCompanyCode", pCompanyCode);
		vQry.SetParameter("qCompanyCodeIsEmpty", IsBlankString(pCompanyCode));
		vQry.SetParameter("qPeriodFrom", 	pPeriodFrom);
		vQry.SetParameter("qPeriodTo", 		pPeriodTo);
		vTrans = vQry.Execute().Unload();
		For Each mRow In vTrans Do
			vCustomersItemRow = XDTOFactory.Create(vCustomersItemRowType);
			FillPropertyValues(vCustomersItemRow,mRow.Customer);    
			vSourcesOfBusiness = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "SourcesOfBusiness"));
			vSB = mRow.Customer.SourceOfBusiness;
			If ValueIsFilled(vSB) Then
				vSourcesOfBusiness.Code = TrimAll(vSB.Code);	
				vSourcesOfBusiness.Description = TrimAll(vSB.Description);
			Else
				vSourcesOfBusiness.Code = "";	
				vSourcesOfBusiness.Description = "";	
			EndIf;	 
			vCustomersItemRow.SourcesOfBusiness = vSourcesOfBusiness;
			vRetXDTO.Customers.CustomersItemRow.Add(vCustomersItemRow);
		EndDo;
		Return vRetXDTO;	
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Runtime Error'; ru='ИнтерфейсСБухгалтерией.Ошибка получения списка контрагентов'"), EventLogLevel.Error, , , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") + vError);
		vRetXDTO.ErrorDescription = vError;
		Return  vRetXDTO;
	EndTry;
EndFunction  // cmGetCustomers

// -----------------------------------------------------------------------------
Function cmGetCompany(pPeriodFrom, pPeriodTo) Export
	WriteLogEvent(NStr("en='Get customers list'; ru='ИнтерфейсСБухгалтерией.Получение списка фирм, входящие параметры'"), EventLogLevel.Information, , , 
	NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom + Chars.LF + 
	NStr("en='Date to: '; ru='Дата окончания: '") + pPeriodTo);
	
	vCompanyType 				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Company");
	vCompanyItemRowType 		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CompanyItemRow");
	vCompanyListType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CompanyList");
	
	vRetXDTO 					= XDTOFactory.Create(vCompanyListType);
	vRetXDTO.Company   			= XDTOFactory.Create(vCompanyType);
	vRetXDTO.ErrorDescription 	= "";
	
	Try
		vQry = New Query;
		vQry.Text =
		"SELECT
		|	Common.Company.Description AS Description,
		|	Common.Company.ExternalCode AS ExternalCode,
		|	Common.Company.Code AS Code
		|FROM
		|	(SELECT
		|		CashRegisterDailyReceiptsTurnovers.Company AS Company
		|	FROM
		|		AccumulationRegister.CashRegisterDailyReceipts.Turnovers(&qPeriodFrom, &qPeriodTo, Period, ) AS CashRegisterDailyReceiptsTurnovers
		|	
		|	GROUP BY
		|		CashRegisterDailyReceiptsTurnovers.Company
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		AccountsReceivableTurnovers.Company
		|	FROM
		|		AccumulationRegister.AccountsReceivable.Turnovers(&qPeriodFrom, &qPeriodTo, Period, ) AS AccountsReceivableTurnovers
		|	
		|	GROUP BY
		|		AccountsReceivableTurnovers.Company) AS Common
		|
		|GROUP BY
		|	Common.Company.Description,
		|	Common.Company.ExternalCode,
		|	Common.Company.Code
		|
		|ORDER BY
		|	Common.Company.Description";
		
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", pPeriodTo);
		vTrans = vQry.Execute().Unload();
		
		
		For Each mRow In vTrans Do
			vCompanyItemRow = XDTOFactory.Create(vCompanyItemRowType);
			
			FillPropertyValues(vCompanyItemRow,mRow);
			
			vRetXDTO.Company.CompanyItemRow.Add(vCompanyItemRow);
		EndDo;
		
		Return vRetXDTO;	
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Runtime Error'; ru='ИнтерфейсСБухгалтерией.Ошибка получения данных по фирмам'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") + vError);
		vRetXDTO.ErrorDescription = vError;
		Return  vRetXDTO;
		
	EndTry;
	
EndFunction  // cmGetCompany

// -----------------------------------------------------------------------------
Function cmGetSettlement(pCompanyCode="",pPeriodFrom,pPeriodTo) Export
	WriteLogEvent(NStr("en='AccountingInterfaces.Get settlement list'; ru='ИнтерфейсСБухгалтерией.Получение списка актов, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom + Chars.LF + NStr("en='Date to: '; ru='Дата окончания: '") + pPeriodTo
	+ Chars.LF + NStr("en='Company code: '; ru='Код фирмы: '")+ pCompanyCode);
	
	vSettlementType 				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Settlement");
	vSettlementItemRowType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "SettlementItemRow");
	vSettlementListType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "SettlementList");
	vAccountingCustomerType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow");
	vAccountingContractType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AccountingContract");
	vCompanyType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CompanyItemRow");
	vHotelType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "HotelParameters");
	vGuestGroupType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "GuestGroup");
	vAccountingCurrencyType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AccountingCurrency");
	vPaymentSectionType				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentSectionsRow");
	
	vRetXDTO 					= XDTOFactory.Create(vSettlementListType);
	vRetXDTO.Settlement   		= XDTOFactory.Create(vSettlementType);
	vRetXDTO.ErrorDescription 	= "";
	Try	
		vQry = New Query;
		vQry.Text = 
		"SELECT
		|	Settlement.CorrectionForSettlement AS Ref
		|INTO CorrectionRefs
		|FROM
		|	Document.Settlement AS Settlement
		|WHERE
		|	Settlement.ChangeDate >= &qDateFrom
		|	AND Settlement.ChangeDate <= &qDateTo
		|	AND CASE
		|			WHEN &qCompanyCode = """"
		|				THEN TRUE
		|			ELSE Settlement.Company.ExternalCode = &qCompanyCode
		|		END
		|	AND NOT Settlement.CorrectionForSettlement.Ref IS NULL
		|	AND NOT Settlement.DoNotExportToTheAccountingSystem
		|	AND Settlement.Posted
		|
		|GROUP BY
		|	Settlement.CorrectionForSettlement
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Settlement.Ref,
		|	Settlement.Date,
		|	Settlement.Number,
		|	Settlement.Posted,
		|	Settlement.Hotel,
		|	Settlement.Company,
		|	Settlement.AccountingCustomer,
		|	Settlement.AccountingContract,
		|	Settlement.GuestGroup,
		|	Settlement.Sum,
		|	Settlement.AccountingCurrency,
		|	Settlement.InvoiceNumber,
		|	Settlement.ExternalCode,
		|	Settlement.Remarks,
		|	CASE
		|		WHEN Settlement.CorrectionForSettlement.Ref IS NULL
		|			THEN """"
		|		ELSE Settlement.CorrectionForSettlement.Number
		|	END AS Parent,
		|	Settlement.PaymentSection
		|FROM
		|	Document.Settlement AS Settlement
		|WHERE
		|	Settlement.ChangeDate >= &qDateFrom
		|	AND Settlement.ChangeDate <= &qDateTo
		|	AND CASE
		|			WHEN &qCompanyCode = """"
		|				THEN TRUE
		|			ELSE Settlement.Company.ExternalCode = &qCompanyCode
		|		END
		|	AND NOT Settlement.Ref IN
		|				(SELECT
		|					CorrectionRefs.Ref
		|				FROM
		|					CorrectionRefs AS CorrectionRefs)
		|	AND NOT Settlement.DoNotExportToTheAccountingSystem
		|	AND Settlement.Posted
		|
		|UNION ALL
		|
		|SELECT
		|	SettlementCorrections.Ref,
		|	SettlementCorrections.Date,
		|	SettlementCorrections.Number,
		|	SettlementCorrections.Posted,
		|	SettlementCorrections.Hotel,
		|	SettlementCorrections.Company,
		|	SettlementCorrections.AccountingCustomer,
		|	SettlementCorrections.AccountingContract,
		|	SettlementCorrections.GuestGroup,
		|	SettlementCorrections.Sum,
		|	SettlementCorrections.AccountingCurrency,
		|	SettlementCorrections.InvoiceNumber,
		|	SettlementCorrections.ExternalCode,
		|	SettlementCorrections.Remarks,
		|	CASE
		|		WHEN SettlementCorrections.CorrectionForSettlement.Ref IS NULL
		|			THEN """"
		|		ELSE SettlementCorrections.CorrectionForSettlement.Number
		|	END,
		|	SettlementCorrections.PaymentSection
		|FROM
		|	Document.Settlement AS SettlementCorrections
		|WHERE
		|	SettlementCorrections.Ref IN
		|			(SELECT
		|				CorrectionRefs.Ref
		|			FROM
		|				CorrectionRefs AS CorrectionRefs)
		|	AND NOT SettlementCorrections.DoNotExportToTheAccountingSystem
		|	AND SettlementCorrections.Posted
		|
		|ORDER BY
		|	Parent";
		
		vQry.SetParameter("qDateFrom", pPeriodFrom);
		vQry.SetParameter("qDateTo", pPeriodTo);	
		vQry.SetParameter("qCompanyCode", pCompanyCode);
		vTrans = vQry.Execute().Unload();	
		
		For Each mRow In vTrans Do
			vSettlementItemRow  = XDTOFactory.Create(vSettlementItemRowType);
			vAccountingCustomer = XDTOFactory.Create(vAccountingCustomerType);
			vAccountingContract = XDTOFactory.Create(vAccountingContractType); 
			vCompany			= XDTOFactory.Create(vCompanyType);
			vGuestGroup			= XDTOFactory.Create(vGuestGroupType);
			vAccountingCurrency	= XDTOFactory.Create(vAccountingCurrencyType);
			vHotel              = XDTOFactory.Create(vHotelType);
			vPaymentSection		= XDTOFactory.Create(vPaymentSectionType);
			
			// Fill Accounting Customer
			FillPropertyValues(vAccountingCustomer,mRow.AccountingCustomer);   
			vSourcesOfBusiness = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "SourcesOfBusiness"));
			vSB = mRow.AccountingCustomer.SourceOfBusiness;
			If ValueIsFilled(vSB) Then
				vSourcesOfBusiness.Code = TrimAll(vSB.Code);	
				vSourcesOfBusiness.Description = TrimAll(vSB.Description);	
			Else
				vSourcesOfBusiness.Code = "";	
				vSourcesOfBusiness.Description = "";
			EndIf;	 
			vAccountingCustomer.SourcesOfBusiness = vSourcesOfBusiness;
			// Fill Accounting Contract
			FillPropertyValues(vAccountingContract,mRow.AccountingContract);
			// Fill Company
			FillPropertyValues(vCompany,mRow.Company);
			// Fill Guest Group
			FillPropertyValues(vGuestGroup,mRow.GuestGroup);
			// Fill Accounting Currency
			FillPropertyValues(vAccountingCurrency,mRow.AccountingCurrency);
			// Fill Hotel
			FillPropertyValues(vHotel,mRow.Hotel);
			// Fill PaymentSection
			FillPropertyValues(vPaymentSection,mRow.PaymentSection);
			
			
			vSettlementItemRow.AccountingCustomer		=  vAccountingCustomer;
			vSettlementItemRow.AccountingContract		=  vAccountingContract;
			vSettlementItemRow.GuestGroup				=  vGuestGroup;
			vSettlementItemRow.ExternalCode				=  mRow.ExternalCode;
			vSettlementItemRow.Number					=  mRow.Number;
			vSettlementItemRow.Date						=  mRow.Date;
			vSettlementItemRow.Sum						=  mRow.Sum;
			vSettlementItemRow.AccountingCurrency   	=  vAccountingCurrency;
			vSettlementItemRow.Company					=  vCompany;
			vSettlementItemRow.Hotel					=  vHotel;
			vSettlementItemRow.Parent					=  TrimAll(mRow.Parent);
			vSettlementItemRow.PaymentSection			=  vPaymentSection;
			
			vRetXDTO.Settlement.SettlementItemRow.Add(vSettlementItemRow);
		EndDo;
		Return vRetXDTO;	
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Runtime Error'; ru='Ошибка получения данных'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") +vError);
		vRetXDTO.ErrorDescription = vError;
		Return  vRetXDTO;
		
	EndTry;
EndFunction  // cmGetSettlement

// -----------------------------------------------------------------------------
Function cmGetSettlementTable(pDocNumber,pPeriodFrom,pPeriodTo) Export
	WriteLogEvent(NStr("en='Get services settlement table, input parameters'; ru='ИнтерфейсСБухгалтерией.Получение списка услуг по акту, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom+Chars.LF+NStr("en='Date to: '; ru='Дата окончания: '")+pPeriodTo
	+Chars.LF+NStr("en='Doc Number: '; ru='Номер акта: '")+pDocNumber);
	
	vSettlementServicesTableType 	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "SettlementServicesTable");
	vSettlementServicesTableRowType	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "SettlementServicesTableRow");
	vSettlementServicesListType 	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "SettlementServicesList");
	vAccountingCustomerType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow");
	vAccountingContractType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AccountingContract");
	vCompanyType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CompanyItemRow");
	vGuestGroupType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "GuestGroup");
	vAccountingCurrencyType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AccountingCurrency");
	vClientType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Client");
	vRoomType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Room");
	vFolioType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Folio");
	vVATRateType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "VATRate");
	vParentDocType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "ParentDoc");
	vServicesType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "ServicesItemRow");
	vPaymentSectionType				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentSectionsRow");
	
	vRetXDTO 						= XDTOFactory.Create(vSettlementServicesListType);
	vRetXDTO.SettlementServicesTable= XDTOFactory.Create(vSettlementServicesTableType);
	vRetXDTO.ErrorDescription 	= "";
	Try
		vQry = New Query;
		vQry.Text = 
		"SELECT
		|	AccountsReceivable.Period AS Period,
		|	AccountsReceivable.Recorder AS Recorder,
		|	AccountsReceivable.Recorder.Number AS RecorderNumber,
		|	AccountsReceivable.Recorder.ExternalCode AS ExternalCode,
		|	AccountsReceivable.LineNumber AS LineNumber,
		|	AccountsReceivable.Active AS Active,
		|	AccountsReceivable.Company AS Company,
		|	AccountsReceivable.AccountingCustomer AS AccountingCustomer,
		|	AccountsReceivable.AccountingContract AS AccountingContract,
		|	AccountsReceivable.GuestGroup AS GuestGroup,
		|	AccountsReceivable.AccountingCurrency AS AccountingCurrency,
		|	AccountsReceivable.Service AS Service,
		|	AccountsReceivable.Hotel AS Hotel,
		|	AccountsReceivable.Hotel.Description AS HotelDescription,
		|	AccountsReceivable.Hotel.Code AS HotelCode,
		|	AccountsReceivable.Sum AS Sum,
		|	AccountsReceivable.VATSum AS VATSum,
		|	AccountsReceivable.Quantity AS Quantity,
		|	AccountsReceivable.Folio AS Folio,
		|	AccountsReceivable.Client AS Client,
		|	AccountsReceivable.Room AS Room,
		|	ISNULL(AccountsReceivable.Room.RoomType.Code, """") AS RoomTypeCode,
		|	AccountsReceivable.AccountingDate AS AccountingDate,
		|	AccountsReceivable.Price AS Price,
		|	AccountsReceivable.VATRate AS VATRate,
		|	AccountsReceivable.Recorder.PaymentSection AS PaymentSection,
		|	ISNULL(AccountsReceivable.HotelProduct.Code, """") AS HotelProduct
		|FROM
		|	AccumulationRegister.AccountsReceivable AS AccountsReceivable
		|WHERE
		|	AccountsReceivable.Recorder.ChangeDate >= &qDateFrom
		|	AND AccountsReceivable.Recorder.ChangeDate <= &qDateTo
		|	AND AccountsReceivable.Recorder.Number = &qDocNumber
		|
		|ORDER BY
		|	RecorderNumber,
		|	AccountsReceivable.PointInTime";
		vQry.SetParameter("qDateFrom", pPeriodFrom);
		vQry.SetParameter("qDateTo", pPeriodTo);
		vQry.SetParameter("qDocNumber", pDocNumber);
		
		vTrans = vQry.Execute().Unload();
		WriteLogEvent(NStr("en='Get services settlement table'; ru='ИнтерфейсСБухгалтерией.Получение списка услуг по акту'"), EventLogLevel.Information, 
		, , NStr("en='Services count: '; ru='Количество полученных услуг: '") +vTrans.Count());
		
		For Each mRow In vTrans Do
			vSetServiceItemRow  = XDTOFactory.Create(vSettlementServicesTableRowType);
			vAccountingCustomer = XDTOFactory.Create(vAccountingCustomerType);
			vAccountingContract = XDTOFactory.Create(vAccountingContractType); 
			vCompany			= XDTOFactory.Create(vCompanyType);
			vGuestGroup			= XDTOFactory.Create(vGuestGroupType);
			vAccountingCurrency	= XDTOFactory.Create(vAccountingCurrencyType);
			vClient				= XDTOFactory.Create(vClientType);
			vRoom				= XDTOFactory.Create(vRoomType);
			vFolio				= XDTOFactory.Create(vFolioType);
			vParentDoc			= XDTOFactory.Create(vParentDocType);
			vVATRate			= XDTOFactory.Create(vVATRateType);
			vServices           = XDTOFactory.Create(vServicesType);
			vPaymentSection		= XDTOFactory.Create(vPaymentSectionType);
			
			//Fill PaymentSection
			FillPropertyValues(vPaymentSection,mRow.PaymentSection);
			
			FillPropertyValues(vAccountingCustomer,	mRow.AccountingCustomer);
			vSourcesOfBusiness = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "SourcesOfBusiness"));
			vSB = mRow.AccountingCustomer.SourceOfBusiness;
			If ValueIsFilled(vSB) Then
				vSourcesOfBusiness.Code = TrimAll(vSB.Code);	
				vSourcesOfBusiness.Description = TrimAll(vSB.Description);	
			Else
				vSourcesOfBusiness.Code = "";	
				vSourcesOfBusiness.Description = "";
			EndIf;	 
			vAccountingCustomer.SourcesOfBusiness = vSourcesOfBusiness;
			
			vAccountingContract.Code 					=  ?(ValueIsFilled(mRow.AccountingContract),mRow.AccountingContract.Code,"");
			vAccountingContract.Description 			=  mRow.AccountingContract.Description;
			vAccountingContract.ExternalCode 			=  mRow.AccountingContract.ExternalCode;
			
			vCompany.Code 								=  ?(ValueIsFilled(mRow.Company),mRow.Company.Code,"");
			vCompany.Description 						=  mRow.Company.Description;
			vCompany.ExternalCode 						=  mRow.Company.ExternalCode;
			
			vGuestGroup.Code 							=  ?(ValueIsFilled(mRow.GuestGroup),mRow.GuestGroup.Code,"");
			vGuestGroup.Description 					=  mRow.GuestGroup.Description;
			vGuestGroup.ExternalCode 					=  mRow.GuestGroup.ExternalCode;
			
			vAccountingCurrency.Code 					=  ?(ValueIsFilled(mRow.AccountingCurrency),mRow.AccountingCurrency.Code,"");
			vAccountingCurrency.Description 			=  mRow.AccountingCurrency.Description;
			
			vClient.Code 								=  ?(ValueIsFilled(mRow.Client),mRow.Client.Code,"");
			vClient.Description 						=  mRow.Client.Description;
			
			vRoom.Code 									=  "";
			vRoom.Description 							=  ?(TypeOf(mRow.Room)=Type("CatalogRef.Rooms"),mRow.Room.Description,mRow.Room);
			vRoom.RoomTypeCode							=  mRow.RoomTypeCode;
			
			vFolio.DateTimeFrom 						=  mRow.Folio.DateTimeFrom;
			vFolio.DateTimeTo 							=  mRow.Folio.DateTimeTo;
			vFolio.Number 								=  mRow.Folio.Number;
			vFolio.Description 							=  mRow.Folio.Description;
			vParentDoc.HasOfficialLetter            	=  False;
			
			//Fill VATRate
			FillPropertyValues(vVATRate,mRow.VATRate);
			//Fill Service
			FillPropertyValues(vServices,mRow.Service);
			vServices.HotelDescription = mRow.HotelDescription;
			vServices.HotelCode = mRow.HotelCode;
			
			If  ValueIsFilled(mRow.Folio.ParentDoc) Then
				vParentDoc.HasOfficialLetter            =  ?(mRow.Folio.ParentDoc.Metadata().Attributes.Find("HasOfficialLetter")<>Undefined,mRow.Folio.ParentDoc.HasOfficialLetter,False);
				vGuest									=  XDTOFactory.Create(vClientType);
				
				If mRow.Folio.ParentDoc.Metadata().Attributes.Find("Guest")<>Undefined  Then
					vGuest.Code 							=  ?(ValueIsFilled(mRow.Folio.ParentDoc.Guest),mRow.Folio.ParentDoc.Guest.Code,"");
					vGuest.Description 						=  ?(ValueIsFilled(mRow.Folio.ParentDoc.Guest),mRow.Folio.ParentDoc.Guest.Description,"");
				ElsIf mRow.Folio.ParentDoc.Metadata().Attributes.Find("Client")<>Undefined  Then
					vGuest.Code 						=  ?(ValueIsFilled(mRow.Folio.ParentDoc.Client),mRow.Folio.ParentDoc.Client.Code,"");
					vGuest.Description 					=  ?(ValueIsFilled(mRow.Folio.ParentDoc.Client),mRow.Folio.ParentDoc.Client.Description,"");
				Else
					vGuest.Code 						=  "";
					vGuest.Description 					=  "";
				EndIf;
				vParentDoc.Guest            			=  vGuest;
			EndIf;	
			vFolioGuestGroup                       		=  XDTOFactory.Create(vGuestGroupType);  
			vFolioGuestGroup.Code 						=  ?(ValueIsFilled(mRow.Folio.GuestGroup),mRow.Folio.GuestGroup.Code,"");
			vFolioGuestGroup.Description 				=  mRow.Folio.GuestGroup.Description;
			vFolioGuestGroup.ExternalCode 				=  mRow.Folio.GuestGroup.ExternalCode;
			vFolio.GuestGroup							=  vFolioGuestGroup;
			vFolio.ParentDoc 							=  vParentDoc;
			
			vSetServiceItemRow.AccountingCustomer		=  vAccountingCustomer;
			vSetServiceItemRow.AccountingDate			=  mRow.AccountingDate;
			vSetServiceItemRow.AccountingContract		=  vAccountingContract;
			vSetServiceItemRow.GuestGroup				=  vGuestGroup;
			vSetServiceItemRow.Folio					=  vFolio;
			vSetServiceItemRow.RecorderNumber			=  mRow.RecorderNumber;
			vSetServiceItemRow.Period					=  mRow.Period;
			vSetServiceItemRow.AccountingCurrency   	=  vAccountingCurrency;
			vSetServiceItemRow.Company					=  vCompany;
			vSetServiceItemRow.Sum						=  mRow.Sum;
			vSetServiceItemRow.Price					=  mRow.Price;
			vSetServiceItemRow.Quantity					=  mRow.Quantity;
			vSetServiceItemRow.VATRate					=  vVATRate;
			vSetServiceItemRow.VATSum					=  mRow.VATSum;
			vSetServiceItemRow.Client					=  vClient;
			vSetServiceItemRow.Services					=  vServices;
			vSetServiceItemRow.Room						=  vRoom;
			vSetServiceItemRow.ExternalCode				=  mRow.ExternalCode;
			vSetServiceItemRow.IsAgentService			=  mRow.Service.IsAgentService;
			vSetServiceItemRow.PaymentSection			=  vPaymentSection;
			vSetServiceItemRow.HotelProduct				=  mRow.HotelProduct;
			
			vRetXDTO.SettlementServicesTable.SettlementServicesTableRow.Add(vSetServiceItemRow);
		EndDo;
		Return vRetXDTO;
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Runtime Error'; ru='ИнтерфейсСБухгалтерией.Ошибка получения списка услуг по акту'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") +vError);
		vRetXDTO.ErrorDescription = vError;
		Return  vRetXDTO;
		
	EndTry;
	
EndFunction  //cmGetSettlementTable

// -----------------------------------------------------------------------------
Function cmWriteSettlementExtCode(pNumber, pExternalCode, pPeriodFrom, pPeriodTo) Export
	WriteLogEvent(NStr("en='WriteSettlementExtCode'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Акт, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom+Chars.LF+NStr("en='Date to: '; ru='Дата окончания: '")+pPeriodTo
	+Chars.LF+NStr("en='Number: '; ru='Number: '")+pNumber+Chars.LF+NStr("en='ExternalCode: '; ru='ExternalCode: '")+pExternalCode);
	
	vError = "";
	Try
		vQry = New Query;
		vQry.Text = 
		"SELECT
		|	AccountsReceivable.Recorder AS Recorder
		|FROM
		|	AccumulationRegister.AccountsReceivable AS AccountsReceivable
		|WHERE
		|	AccountsReceivable.Recorder.ChangeDate >= &qDateFrom
		|	AND AccountsReceivable.Recorder.ChangeDate <= &qDateTo
		|	AND AccountsReceivable.Recorder.Number = &qDocNumber
		|
		|ORDER BY
		|	AccountsReceivable.PointInTime";
		vQry.SetParameter("qDateFrom", pPeriodFrom);
		vQry.SetParameter("qDateTo", pPeriodTo);
		vQry.SetParameter("qDocNumber", pNumber);
		
		vTrans = vQry.Execute().Unload();
		If vTrans.Count()>0 Then
			WriteLogEvent(NStr("en='Error write document'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Поиск Акта'"), EventLogLevel.Information, 
			, ,NStr("en = 'Document found: '; ru = 'Документ найден: '; de = 'Document found: '") + vTrans[0].Recorder);
			
			vDoc = vTrans[0].Recorder.GetObject();
			vDoc.ExternalCode = pExternalCode;
			vDoc.write();
		Else
			vError = NStr("en = 'The document was not found on the incoming parameters'; ru = 'Документ не найден по входящим параметрам'; de = 'Das Dokument wurde nicht auf die eingehenden Parameter gefunden'");
			WriteLogEvent(NStr("en='Error write document'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Поиск Акта'"), EventLogLevel.Error, 
			, , vError);
			
		EndIf;	
		Return vError;
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Error write document'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Ошибка записи Акта'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") + vError);
		
		Return vError;
	EndTry;
	
EndFunction  //cmWriteSettlementExtCode

// -----------------------------------------------------------------------------
Function cmWriteCashRegisterExtCode(pNumber, pExternalCode, pPeriodFrom, pPeriodTo) Export
	WriteLogEvent(NStr("en='WriteCashRegisterExtCode'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Закрытие кассовой смены, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom+Chars.LF+NStr("en='Date to: '; ru='Дата окончания: '")+pPeriodTo
	+Chars.LF+NStr("en='Number: '; ru='Number: '")+pNumber+Chars.LF+NStr("en='ExternalCode: '; ru='ExternalCode: '")+pExternalCode);
	
	Try
		vQry = New Query;
		vQry.Text = 
		"SELECT
		|	CloseOfCashRegisterDay.Ref
		|FROM
		|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
		|WHERE
		|	CloseOfCashRegisterDay.Date >= &qDateFrom
		|	AND CloseOfCashRegisterDay.Date <= &qDateTo
		|	AND CloseOfCashRegisterDay.Number = &qDocNumber
		|
		|ORDER BY
		|	CloseOfCashRegisterDay.PointInTime";
		vQry.SetParameter("qDateFrom", pPeriodFrom);
		vQry.SetParameter("qDateTo", pPeriodTo);
		vQry.SetParameter("qDocNumber", pNumber);
		
		vTrans = vQry.Execute().Unload();
		If vTrans.Count()>0 Then
			vDoc = vTrans[0].Ref.GetObject();
			vDoc.ExternalCode = pExternalCode;
			vDoc.write();
		EndIf;	
		Return "";
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Error write document'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Закрытие кассовой смены, ошибка записи'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") +vError);
		
		Return vError;
	EndTry;
	
EndFunction  //cmWriteCashRegisterExtCode

// -----------------------------------------------------------------------------
Function cmWriteCustomerExtCode(pCode,pExternalCode) Export
	WriteLogEvent(NStr("en='GetCloseOfCashRegisterDay'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Контрагенты, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Customer Code: '; ru='Код контрагента: '") + TrimAll(pCode)+Chars.LF+NStr("en='ExternalCode: '; ru='Код во внешней системе: '")+pExternalCode);
	
	Try
		vCustomer = Catalogs.Customers.FindByCode(pCode).GetObject();
		vCustomer.ExternalCode = pExternalCode;
		vCustomer.Write();
		Return "";
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Error write'; ru=''ИнтерфейсСБухгалтерией.СохранениеСоответствий.Контрагенты, ошибка записи'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") +vError);
		
		Return vError;
	EndTry;
EndFunction   //cmWriteCustomerExtCode

// -----------------------------------------------------------------------------
Function cmWriteCompanyExtCode(pCode,pExternalCode) Export
	WriteLogEvent(NStr("en='GetCloseOfCashRegisterDay'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Фирмы, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Company Code: '; ru='Код фирмы: '") + TrimAll(pCode)+Chars.LF+NStr("en='ExternalCode: '; ru='Код во внешней системе: '")+pExternalCode);
	
	Try
		vCompany = Catalogs.Companies.FindByCode(pCode).GetObject();
		vCompany.ExternalCode = pExternalCode;
		vCompany.Write();
		Return "";
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Error write'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Фирмы, ошибка записи'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") +vError);
		
		Return vError;
	EndTry;
EndFunction  //cmWriteCompanyExtCode

// -----------------------------------------------------------------------------
Function cmWriteServicesExtCode(pCode,pExternalCode) Export
	WriteLogEvent(NStr("en='GetCloseOfCashRegisterDay'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Услуги, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Service Code: '; ru='Код услуги: '") + TrimAll(pCode)+Chars.LF+NStr("en='ExternalCode: '; ru='Код во внешней системе: '")+pExternalCode);
	
	Try
		vService = Catalogs.Services.FindByCode(pCode).GetObject();
		vService.ExternalCode = pExternalCode;
		vService.Write();
		Return "";
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Error write'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Услуги,ошибка записи '"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") +vError);
		
		Return vError;
	EndTry;
EndFunction  //cmWriteServicesExtCode

// -----------------------------------------------------------------------------
Function cmWriteInvoiceExtCode(pNumber, pExternalCode, pPeriodFrom, pPeriodTo) Export 
	WriteLogEvent(NStr("en='WriteInvoiceExtCode'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Счет, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom+Chars.LF+NStr("en='Date to: '; ru='Дата окончания: '")+pPeriodTo
	+Chars.LF+NStr("en='Number: '; ru='Number: '")+pNumber+Chars.LF+NStr("en='ExternalCode: '; ru='ExternalCode: '")+pExternalCode);
	Try
		vQry = New Query;
		vQry.Text = 
		"SELECT
		|	Invoice.Ref
		|FROM
		|	Document.ProformaInvoice AS Invoice
		|WHERE
		|	Invoice.ChangeDate >= &qPeriodFrom
		|	AND Invoice.ChangeDate <= &qPeriodTo
		|	AND Invoice.Number = &Number";
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", pPeriodTo);
		vQry.SetParameter("Number", pNumber);
		
		vTrans = vQry.Execute().Unload();
		If vTrans.Count()>0 Then
			vDoc = vTrans[0].Ref.GetObject();
			
			WriteLogEvent(NStr("en='WriteInvoiceExtCode'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Инфо, найден счет'"), EventLogLevel.Information,vTrans[0].Ref.Metadata(),
			vTrans[0].Ref, NStr("en='Documents found, N: '; ru='Документ найден, N'")+String(vTrans[0].Ref.Number));
			
			vDoc = vTrans[0].Ref.GetObject();
			vDoc.ExternalCode = pExternalCode;
			vDoc.Write();
		EndIf;	
		Return "";
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Error write document'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Счет, ошибка записи'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") +vError);
		
		Return vError;
	EndTry;
	
EndFunction	 //cmWriteInvoiceExtCode

// -----------------------------------------------------------------------------
Procedure cmWriteInvoicePayment(pHotelCode = Undefined, pCompanyCode = Undefined, pPaymentExternalCode, pPaymentDate, 
								pPaymentNumber, pCustomer, pIsPosted, pIsMarkedDeleted, pPaymentDetails, pRemarks, 
								pExtSystemCode = "",pAccountingCurrencyCode, pUseNewMapping = False, pPaymentMethod = "") Export
	vInputParameters = "Код отеля: " +TrimR(pHotelCode) + ", " + Chars.LF +
					   "Код Фирмы: " + TrimR(pCompanyCode) + ", " + Chars.LF +
	   				   "Гуид платежа: " + pPaymentExternalCode + ", "+ Chars.LF +
					   "Дата платежа: " + TrimR(pPaymentDate) + ", " + Chars.LF +
					   "Номер документа: "+ TrimR(pPaymentNumber) + ", " + Chars.LF +
					   "Проведен: " + TrimR(pIsPosted) + ", " + Chars.LF +
					   "Помечен на удаление: " + pIsMarkedDeleted + ", "	+ Chars.LF +
					   "Примечание: " + pRemarks + ", " + Chars.LF +
					   "Код внешней системы: " + TrimR(pExtSystemCode) + Chars.LF +
					   "Код валюты: " + TrimR(pAccountingCurrencyCode) + Chars.LF +
					   "Код способа оплаты: " + TrimR(pPaymentMethod);
	
	vFunc = "cmWriteInvoicePayment";
	
	vWriteDebug = False;
	vInteraction = Undefined;
	If Not IsBlankString(pExtSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	If vWriteDebug Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, vInputParameters, , "Start");
	Else
		WriteLogEvent(NStr("en = 'AccountingInterfaces.WriteInvoicePayment'; ru = 'ИнтерфейсСБухгалтерией.Записать платеж по счету, входящие параметры'; de = 'AccountingInterfaces.WriteInvoicePayment'"), 
					  EventLogLevel.Information, , ,vInputParameters);
	EndIf;
	
	Try
		// Initialize error description
		vErrorDescription = "";
		vHotel = Catalogs.Hotels.EmptyRef();
		vCompany = Catalogs.Companies.EmptyRef(); 
		vInvoce = Undefined;
		If pHotelCode = Undefined Then
			For Each Str In pPaymentDetails.PaymentDetailsRow Do
				vInvoce = Documents.ProformaInvoice.FindByAttribute("ExternalCode", Str.ExternalCode);
				If vInvoce = Documents.ProformaInvoice.EmptyRef() Then
					// Invoice is not from the hotel database
					Continue;
				Else
					vHotel = vInvoce.Hotel;
					vCompany = vInvoce.Company;
					If Not vHotel.IsEmpty() Then
						If vWriteDebug Then
							vDesc = NStr("en = 'Hotel and company selected from invoice'; de = 'Hotel und Firma aus Rechnung ausgewählt'; ru = 'Гостиница и фирма выбраны из счета'");
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, , , vDesc);
						EndIf;	
						Break;
					EndIf;	
				EndIf;	
			EndDo;
		Else	
			If pUseNewMapping And ValueIsFilled(vInteraction) Then
				If Not IsBlankString(pHotelCode) Then
					vRes = InformationRegisters.ExternalSystemIntegrationData.GetData(vInteraction, "Hotels", , , , , pHotelCode);
					If vRes.Count() > 0 Then
						vHotel = vRes[0].RefKey1;
					EndIf;
				EndIf;
				// Try to find company
				If Not IsBlankString(pCompanyCode) Then
					vRes = InformationRegisters.ExternalSystemIntegrationData.GetData(vInteraction, "Companies", , , , , pCompanyCode);
					If vRes.Count() > 0 Then
						vCompany = vRes[0].RefKey1;
					EndIf;
				EndIf;
				If vCompany = Catalogs.Companies.EmptyRef() And ValueIsFilled(vHotel) Then
					vCompany = vHotel.Company;
				EndIf;
			Else	
				// Try to find hotel by name or code
				vHotel = cmGetHotelByCode(pHotelCode, pExtSystemCode);
				// Try to find company
				If Not IsBlankString(pCompanyCode) Then
					vCompany = cmGetObjectRefByExternalSystemCode(vHotel, pExtSystemCode, "Companies", pCompanyCode);
				EndIf;
				If vCompany = Catalogs.Companies.EmptyRef() Then
					vCompany = vHotel.Company;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vHotel) Then
			// Use "Customer payment".
			vDok = Documents.CustomerPayment.FindByAttribute("ExternalCode", pPaymentExternalCode);
			
			// If not found, then we will create
			If vDok = Documents.CustomerPayment.EmptyRef() Then
				vDok = Documents.CustomerPayment.CreateDocument();
				vDok.pmFillAuthorAndDate();
			Else
				vDesc = NStr("en='Find Payment by ExternalCode: '; ru='Документ платеж найден по коду во внешней системе: '; de='Find Payment by ExternalCode: '") + pPaymentExternalCode;
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, , , vDesc);
				Else
					WriteLogEvent(NStr("en = 'AccountingInterfaces.WriteInvoicePayment'; ru = 'ИнтерфейсСБухгалтерией.Записать платеж по счету, ошибка'; de = 'AccountingInterfaces.WriteInvoicePayment'"), EventLogLevel.Information, 	,vDok, vDesc);
				EndIf;
				vDok = vDok.GetObject();
				
				// Check boxes according to the source
				vDok.DeletionMark 				= pIsMarkedDeleted;
				vDok.Posted	      				= pIsPosted;
			EndIf; 
			If pUseNewMapping And ValueIsFilled(vInteraction) Then
				If Not IsBlankString(pCustomer.Code) Then
					vRes = InformationRegisters.ExternalSystemIntegrationData.GetData(vInteraction, "Customers", , , , , pCustomer.Code);
					If vRes.Count() > 0 Then
						vCustomer = vRes[0].RefKey1;
					EndIf;
				EndIf;
			Else
				vCustomer = cmFindCustomers(pCustomer);
			EndIf;	 
			If ValueIsFilled(vInvoce) And Not ValueIsFilled(vCustomer) Then
				vCustomer = vInvoce.AccountingCustomer;
			EndIf;
			// Refill all payment details, maybe someone changed the details
			vDok.Hotel          				= vHotel;
			vDok.Company						= vCompany;
			vDok.Date 							= pPaymentDate;
			vDok.ExchangeRateDate				= pPaymentDate;
			vDok.AccountingCustomer				= vCustomer;
			vDok.Remarks						= pRemarks;
			
			qPaymentCurrency 					= Catalogs.Currencies.FindByCode(TrimAll(pAccountingCurrencyCode));
			
			vPaymentMethod 						= vHotel.PaymentMethodForCustomerPayments;
			If Not IsBlankString(pPaymentMethod) Then
				vPaymentMethod = cmGetObjectRefByExternalSystemCode(vHotel, pExtSystemCode, "PaymentMethods", pPaymentMethod, , vInteraction);
			EndIf;

			vDok.PaymentMethod					= vPaymentMethod;
			vDok.PaymentDocNumber				= pPaymentNumber;
			vDok.PaymentCurrency				= qPaymentCurrency;
			vDok.AccountingCurrency  			= ?(ValueIsFilled(vDok.AccountingCustomer.AccountingCurrency), vDok.AccountingCustomer.AccountingCurrency, qPaymentCurrency);
			vDok.PaymentCurrencyExchangeRate  	= cmGetCurrencyExchangeRate(vHotel, qPaymentCurrency, pPaymentDate);
			vDok.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vHotel, vDok.AccountingCurrency, pPaymentDate);
			vDok.ExternalCode					= pPaymentExternalCode;
			
			vDok.Contracts.Clear();
			vDok.Invoices.Clear();
			
			// Fill Invoices table
			For Each Str In pPaymentDetails.PaymentDetailsRow Do
				vInvoce = Documents.ProformaInvoice.FindByAttribute("ExternalCode", Str.ExternalCode);
				If vInvoce = Documents.ProformaInvoice.EmptyRef() Then
					// The account is not ours, you do not need to upload
					Continue;
				EndIf;	
				
				WriteLogEvent(NStr("en = 'AccountingInterfaces.WriteInvoicePayment'; ru = 'ИнтерфейсСБухгалтерией.Записать платеж по счету'; de = 'AccountingInterfaces.WriteInvoicePayment'"), EventLogLevel.Information, ,vInvoce, NStr("en='Find Invoice: '; ru='Счет найден: '; de='Find Invoice: '") +vInvoce.Number);
				
				strInv = vDok.Invoices.Add();
				strInv.Invoice  						=  vInvoce;
				strInv.Sum 								=  Str.Sum;
				strInv.SumInAccountingCurrency			=  Str.Sum;
				strInv.AccountingCurrency      			=  qPaymentCurrency;
				strInv.AccountingCurrencyExchangeRate	=  vDok.AccountingCurrencyExchangeRate;
				vDok.pmCalculateCustomerAccountsMapForInvoice(strInv);
			EndDo;
			
			If vDok.Invoices.Count() = 0 And vDok.Contracts.Count() = 0 Then
				Sum = Round(cmConvertCurrencies(vDok.SumInAccountingCurrency, vDok.AccountingCurrency, vDok.AccountingCurrencyExchangeRate, vDok.PaymentCurrency, vDok.PaymentCurrencyExchangeRate, vDok.ExchangeRateDate, vDok.Hotel), 2);
			EndIf;
			
			// Recalculate invoices
			For Each vRow In vDok.Invoices Do
				vRow.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vDok.Hotel, vRow.AccountingCurrency, vDok.ExchangeRateDate);
				vRow.Sum = Round(cmConvertCurrencies(vRow.SumInAccountingCurrency, vRow.AccountingCurrency, vRow.AccountingCurrencyExchangeRate, vDok.PaymentCurrency, vDok.PaymentCurrencyExchangeRate, vDok.ExchangeRateDate, vDok.Hotel), 2);
				vRow.Balance = vRow.Invoice.Sum; 
			EndDo;
			
			// Recalculate contracts
			For Each vRow In vDok.Contracts Do
				vRow.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vDok.Hotel, vRow.AccountingCurrency, vDok.ExchangeRateDate);
				vRow.Sum = Round(cmConvertCurrencies(vRow.SumInAccountingCurrency, vRow.AccountingCurrency, vRow.AccountingCurrencyExchangeRate, vDok.PaymentCurrency, vDok.PaymentCurrencyExchangeRate, vDok.ExchangeRateDate, vDok.Hotel), 2);
				vRow.Balance =  vRow.Sum;
			EndDo;
			
			// Recalculate totals
			vDok.pmCalculateSums();
			
			If vDok.Invoices.Count() > 0  Then
				vDok.Write();
				WriteLogEvent(NStr("en = 'AccountingInterfaces.WriteInvoicePayment'; ru = 'ИнтерфейсСБухгалтерией.Записать платеж по счету'; de = 'AccountingInterfaces.WriteInvoicePayment'"), EventLogLevel.Information, 
				,vDok.ref, NStr("en='Document write: '; ru='Документ записан: '; de='Document write: '") +vDok.ref.Number);
				
				vDok.Write(DocumentWriteMode.Posting);
			EndIf;
			
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Error, , , NStr("en='Document posting: '; ru='Документ проведен: '; de='Document posting: '") +vDok.Number);
			Else
				WriteLogEvent(NStr("en = 'AccountingInterfaces.WriteInvoicePayment'; ru = 'ИнтерфейсСБухгалтерией.Записать платеж по счету'; de = 'AccountingInterfaces.WriteInvoicePayment'"), EventLogLevel.Information, 
									, , NStr("en='Document posting: '; ru='Документ проведен: '; de='Document posting: '") +vDok.Number);
			
			EndIf;
		Else 
			vDesc = NStr("en='Hotel is not find!!!'; ru='Гостиница не найдена, платеж не загружен!'; de='Hotel is not find'");
			WriteLogEvent(NStr("en = 'AccountingInterfaces.WriteInvoicePayment'; ru = 'ИнтерфейсСБухгалтерией.Записать платеж по счету'; de = 'AccountingInterfaces.WriteInvoicePayment'"), EventLogLevel.Error, 
			, , vDesc);
			If ValueIsFilled(vInteraction) Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Error, , , vDesc);
			EndIf;
		EndIf;
		
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en = 'AccountingInterfaces.WriteInvoicePayment'; ru = 'ИнтерфейсСБухгалтерией.Записать платеж по счету, ошибка'; de = 'AccountingInterfaces.WriteInvoicePayment'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '; de='Runtime Error: '") +vError);
		If ValueIsFilled(vInteraction) Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Error, , , vError);
		EndIf;
	EndTry;
EndProcedure  // cmWriteInvoicePayment

// -----------------------------------------------------------------------------
Function cmWritePaymentSectionsExtCode(pCode, pExternalCode) Export
	WriteLogEvent(NStr("en='GetCloseOfCashRegisterDay'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Кассовые секции, входящие параметры'"), EventLogLevel.Information, , , 
	NStr("en='Payment section Code: '; ru='Код кассовой секции: '") + TrimAll(pCode) + Chars.LF + NStr("en='ExternalCode: '; ru='Код во внешней системе: '") + pExternalCode);
	Try
		vService = Catalogs.PaymentSections.FindByCode(pCode).GetObject();
		vService.ExternalCode = pExternalCode;
		vService.Write();
		Return "";
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Error write'; ru='ИнтерфейсСБухгалтерией.СохранениеСоответствий.Кассовые секции,ошибка записи'"), EventLogLevel.Error, , , 
		NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") + vError);
		
		Return vError;
	EndTry;
EndFunction  //cmWritePaymentSectionsExtCode

// -----------------------------------------------------------------------------
Function cmWritePaymentMethodsExtCode(pCode, pExternalCode) Export
	Try
		vService = Catalogs.PaymentMethods.FindByCode(pCode).GetObject();
		vService.ExternalCode = pExternalCode;
		vService.Write();
		Return "";
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Error write'; ru='Ошибка записи'"), EventLogLevel.Error, , , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") + vError);
		Return vError;
	EndTry;
EndFunction  //cmWritePaymentSectionsExtCode

// -----------------------------------------------------------------------------
Function cmGetCloseOfCashRegisterDay(pPeriodFrom, pPeriodTo) Export
	WriteLogEvent(NStr("en='GetCloseOfCashRegisterDay'; ru='ИнтерфейсСБухгалтерией.Получение списка смен, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom+Chars.LF+NStr("en='Date to: '; ru='Дата окончания: '")+pPeriodTo);
	
	vCashRegisterDayType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CashRegisterDay");
	vCashRegisterDayItemType		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CashRegisterDayItem");
	vCashRegisterDayListType 		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CashRegisterDayList");
	vCashRegisterType	        	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CashRegister");
	vHotelType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "HotelParameters");

	vRetXDTO 						= XDTOFactory.Create(vCashRegisterDayListType);
	vRetXDTO.CashRegisterDay		= XDTOFactory.Create(vCashRegisterDayType);
	vRetXDTO.ErrorDescription 	= "";
	
	Try
		vQry = New Query;
		vQry.Text = 
		"SELECT *
		|FROM
		|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
		|WHERE
		|	CloseOfCashRegisterDay.AccountingDate >= &qDateFrom
		|	AND CloseOfCashRegisterDay.AccountingDate <= &qDateTo
		|	AND CloseOfCashRegisterDay.Posted
		|	AND CloseOfCashRegisterDay.DeletionMark = FALSE
		|
		|ORDER BY
		|	CloseOfCashRegisterDay.Date";	
		
		vQry.SetParameter("qDateFrom", pPeriodFrom);
		vQry.SetParameter("qDateTo", pPeriodTo);
		
		vTrans = vQry.Execute().Unload();
		
		For Each mRow In vTrans Do
			vCashRegisterDay 	= XDTOFactory.Create(vCashRegisterDayItemType); 
			vCashRegister       = XDTOFactory.Create(vCashRegisterType);
			vHotel 				= XDTOFactory.Create(vHotelType);
			If ValueIsFilled(mRow.CashRegister.Hotel) Then
				FillPropertyValues(vHotel,	mRow.CashRegister.Hotel);
			Else
				vHotel.Code = "";
				vHotel.LegacyName = "";
				vHotel.ExternalCode = "";
			EndIf;
			vCashRegister.Hotel = vHotel;

			FillPropertyValues(vCashRegister, mRow.CashRegister,,"Hotel");

			FillPropertyValues(vCashRegisterDay, mRow,,"CashRegister, Author");
			vCashRegisterDay.Author             = TrimAll(mRow.Author);
			
			vCashRegisterDay.CashRegister 		=  vCashRegister;
			
			vRetXDTO.CashRegisterDay.CashRegisterDayItem.Add(vCashRegisterDay);
		EndDo;
		
		Return vRetXDTO;
		
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Runtime Error'; ru='ИнтерфейсСБухгалтерией.Ошибка получения списка смен'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") +vError);
		vRetXDTO.ErrorDescription = vError;
		Return  vRetXDTO;
	EndTry;
	
EndFunction   //cmGetCloseOfCashRegisterDay

// -----------------------------------------------------------------------------
Function cmGetPaymentList(pPeriodFrom, pPeriodTo, pDocNumber,pCashRegisterCode) Export
	WriteLogEvent(NStr("en='CashRegisterDailyReceipts'; ru='ИнтерфейсСБухгалтерией.Получение данных по кассе, входящие параметры'"), EventLogLevel.Information, , , 
	NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom+Chars.LF+NStr("en='Date to: '; ru='Дата окончания: '")+pPeriodTo+Chars.LF+NStr("en='Doc Number: '; ru='Номер смены: '")+pDocNumber+Chars.LF+NStr("en='Code KKM: '; ru='Код ККМ: '")+pCashRegisterCode);
	
	vPaymentTableType 				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentTable");
	vPaymentRowType					= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentRow");
	vPaymentListType 				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentList");
	vAccountingCustomerType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow");
	vAccountingContractType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AccountingContract");
	vCompanyType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CompanyItemRow");
	vHotelType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "HotelParameters");
	vGuestGroupType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "GuestGroup");
	vAccountingCurrencyType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AccountingCurrency");
	vClientType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Client");
	vCashRegisterType	        	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CashRegister");
	vPaymentMethodType	        	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentMethod");
	vPaymentSectionType	        	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentSectionsRow");
	vFolioType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Folio");
	vVATRateType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "VATRate");
	vParentDocType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "ParentDoc");
	vServiceType 					= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "ServicesItemRow");
	
	vRetXDTO 						= XDTOFactory.Create(vPaymentListType);
	vRetXDTO.PaymentTable			= XDTOFactory.Create(vPaymentTableType);
	vRetXDTO.ErrorDescription	 	= "";
	
	Try
		vQry = New Query;
		vQry.Text = 
		"SELECT
		|	CashRegisterDailyReceipts.Period AS Period,
		|	CashRegisterDailyReceipts.Recorder AS Recorder,
		|	CashRegisterDailyReceipts.Recorder.Hotel AS Hotel,
		|	CashRegisterDailyReceipts.LineNumber AS LineNumber,
		|	CashRegisterDailyReceipts.Active AS Active,
		|	CashRegisterDailyReceipts.RecordType AS RecordType,
		|	CashRegisterDailyReceipts.Company AS Company,
		|	CashRegisterDailyReceipts.CashRegister AS CashRegister,
		|	CashRegisterDailyReceipts.Currency AS Currency,
		|	CashRegisterDailyReceipts.PaymentSection AS PaymentSection,
		|	CashRegisterDailyReceipts.PaymentMethod AS PaymentMethod,
		|	CashRegisterDailyReceipts.Customer AS Customer,
		|	CashRegisterDailyReceipts.Contract AS Contract,
		|	CashRegisterDailyReceipts.GuestGroup AS GuestGroup,
		|	CashRegisterDailyReceipts.Payment AS Payment,
		|	CashRegisterDailyReceipts.Sum AS Sum,
		|	CashRegisterDailyReceipts.VATSum AS VATSum,
		|	CashRegisterDailyReceipts.PaymentSum AS PaymentSum,
		|	CashRegisterDailyReceipts.VATPaymentSum AS VATPaymentSum,
		|	CashRegisterDailyReceipts.ReturnSum AS ReturnSum,
		|	CashRegisterDailyReceipts.VATReturnSum AS VATReturnSum,
		|	CashRegisterDailyReceipts.Payer AS Payer,
		|	CashRegisterDailyReceipts.Folio AS Folio,
		|	CashRegisterDailyReceipts.VATRate AS VATRate
		|FROM
		|	AccumulationRegister.CashRegisterDailyReceipts AS CashRegisterDailyReceipts
		|WHERE
		|	CashRegisterDailyReceipts.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND CashRegisterDailyReceipts.Period >= &qDateFrom
		|	AND CashRegisterDailyReceipts.Period <= &qDateTo
		|	AND CashRegisterDailyReceipts.CashRegister.Code = &qCashRegisterCode
		|	AND CashRegisterDailyReceipts.PaymentMethod.DoNotExportToTheAccountingSystem = FALSE
		|
		|ORDER BY
		|	CashRegisterDailyReceipts.PointInTime";	
		vQry.SetParameter("qDateFrom", pPeriodFrom);
		vQry.SetParameter("qDateTo",pPeriodTo);
		vQry.SetParameter("qCashRegisterCode", pDocNumber);
		vTrans = vQry.Execute().Unload();
		
		For Each mRow In vTrans Do
			vPaymentRow  		= XDTOFactory.Create(vPaymentRowType);
			vAccountingCustomer = XDTOFactory.Create(vAccountingCustomerType);
			vAccountingContract = XDTOFactory.Create(vAccountingContractType); 
			vCompany			= XDTOFactory.Create(vCompanyType);
			vHotel				= XDTOFactory.Create(vHotelType);
			vGuestGroup			= XDTOFactory.Create(vGuestGroupType);
			vAccountingCurrency	= XDTOFactory.Create(vAccountingCurrencyType);
			vClient				= XDTOFactory.Create(vClientType);
			vFolio				= XDTOFactory.Create(vFolioType);
			vParentDoc			= XDTOFactory.Create(vParentDocType);
			vVATRate			= XDTOFactory.Create(vVATRateType);
			vCashRegister       = XDTOFactory.Create(vCashRegisterType);
			vPaymentMethod      = XDTOFactory.Create(vPaymentMethodType);
			vPaymentSection     = XDTOFactory.Create(vPaymentSectionType);
			
			FillPropertyValues(vAccountingCustomer,	mRow.Customer);
			vSourcesOfBusiness = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "SourcesOfBusiness"));
			vSB = mRow.Customer.SourceOfBusiness;
			If ValueIsFilled(vSB) Then
				vSourcesOfBusiness.Code = TrimAll(vSB.Code);	
				vSourcesOfBusiness.Description = TrimAll(vSB.Description);
			Else
				vSourcesOfBusiness.Code = "";	
				vSourcesOfBusiness.Description = "";	
			EndIf;	 
			vAccountingCustomer.SourcesOfBusiness = vSourcesOfBusiness;

			vAccountingContract.Code 					=  ?(ValueIsFilled(mRow.Contract),mRow.Contract.Code,"");
			vAccountingContract.Description 			=  mRow.Contract.Description;
			vAccountingContract.ExternalCode 			=  mRow.Contract.ExternalCode;
			
			vCompany.Code 								=  ?(ValueIsFilled(mRow.Company),mRow.Company.Code,"");
			vCompany.Description 						=  mRow.Company.Description;
			vCompany.ExternalCode 						=  mRow.Company.ExternalCode;
			
			//Fill Hotel
			vHotelRow = mRow.CashRegister.Hotel;
			If ValueIsFilled(mRow.CashRegister.Hotel) Then
				vHotel.Code = TrimAll(vHotelRow.Code);
				vHotel.LegacyName = TrimAll(vHotelRow.LegacyName);
				vHotel.ExternalCode = TrimAll(vHotelRow.ExternalCode);
			Else
				vHotel.Code = "";
				vHotel.LegacyName = "";
				vHotel.ExternalCode = "";
			EndIf;
			
			vGuestGroup.Code 							=  ?(ValueIsFilled(mRow.GuestGroup),mRow.GuestGroup.Code,"");
			vGuestGroup.Description 					=  mRow.GuestGroup.Description;
			vGuestGroup.ExternalCode 					=  mRow.GuestGroup.ExternalCode;
			
			vAccountingCurrency.Code 					=  ?(ValueIsFilled(mRow.Currency),mRow.Currency.Code,"");
			vAccountingCurrency.Description 			=  mRow.Currency.Description;
			
			vClient.Code 								=  ?(ValueIsFilled(mRow.Payer),mRow.Payer.Code,"");
			vClient.Description 						=  ?(ValueIsFilled(mRow.Payer),mRow.Payer.Description,"");
			
			vCashRegister.Code 							=  ?(ValueIsFilled(mRow.CashRegister), mRow.CashRegister.Code,"");
			vCashRegister.Description 					=  mRow.CashRegister.Description;
			vCashRegister.Remarks 						=  mRow.CashRegister.Remarks;

			vCashRegister.Hotel 						= vHotel;
			
			vHotel2				= XDTOFactory.Create(vHotelType);
	        FillPropertyValues(vHotel2, vHotel);

			FillPropertyValues(vPaymentMethod,	mRow.PaymentMethod);
			
			vPaymentSection.Code 						=  ?(ValueIsFilled(mRow.PaymentSection),mRow.PaymentSection.Code,"");
			vPaymentSection.Description 				=  mRow.PaymentSection.Description;
			vPaymentSection.ExternalCode 				=  mRow.PaymentSection.ExternalCode;
			
			vFolio.DateTimeFrom 						=  mRow.Folio.DateTimeFrom;
			vFolio.DateTimeTo 							=  mRow.Folio.DateTimeTo;
			vFolio.Number 								=  mRow.Folio.Number;
			vFolio.Description 							=  mRow.Folio.Description;
			
			vVATRate.TaxRate                            =  mRow.VATRate.TaxRate;
			vVATRate.Description                        =  mRow.VATRate.Description;
			
			vParentDoc.HasOfficialLetter            	=  False;
			                                      
			If ValueIsFilled(mRow.Folio.ParentDoc) Then
				vParentDoc.HasOfficialLetter            =  ?(mRow.Folio.ParentDoc.Metadata().Attributes.Find("HasOfficialLetter")<>Undefined,mRow.Folio.ParentDoc.HasOfficialLetter,False);
				vGuest									=  XDTOFactory.Create(vClientType);
				
				If mRow.Folio.ParentDoc.Metadata().Attributes.Find("Guest")<>Undefined  Then
					vGuest.Code 							=  ?(ValueIsFilled(mRow.Folio.ParentDoc.Guest),mRow.Folio.ParentDoc.Guest.Code,"");
					vGuest.Description 						=  ?(ValueIsFilled(mRow.Folio.ParentDoc.Guest),mRow.Folio.ParentDoc.Guest.Description,"");
				ElsIf mRow.Folio.ParentDoc.Metadata().Attributes.Find("Client")<>Undefined  Then
					vGuest.Code 						=  ?(ValueIsFilled(mRow.Folio.ParentDoc.Client),mRow.Folio.ParentDoc.Client.Code,"");
					vGuest.Description 					=  ?(ValueIsFilled(mRow.Folio.ParentDoc.Client),mRow.Folio.ParentDoc.Client.Description,"");
				Else
					vGuest.Code 						=  "";
					vGuest.Description 					=  "";
				EndIf;
				vParentDoc.Guest            			=  vGuest;
			EndIf;	
			vFolioGuestGroup                       		=  XDTOFactory.Create(vGuestGroupType);  
			vFolioGuestGroup.Code 						=  ?(ValueIsFilled(mRow.Folio.GuestGroup),mRow.Folio.GuestGroup.Code,"");
			vFolioGuestGroup.Description 				=  mRow.Folio.GuestGroup.Description;
			vFolioGuestGroup.ExternalCode 				=  mRow.Folio.GuestGroup.ExternalCode;
			vFolio.GuestGroup							=  vFolioGuestGroup;
			vFolio.ParentDoc 							=  vParentDoc;
			
			// Fill service
			vSerice										= XDTOFactory.Create(vServiceType);
			If mRow.Payment.PaymentSections.Count() > 0 Then 
				vRowService = mRow.Payment.PaymentSections[0];
				If ValueIsFilled(vRowService.ChequeService) Then
					FillPropertyValues(vSerice, vRowService.ChequeService); 
				Else
					vSerice.Code = "";
					vSerice.Description = "";
					vSerice.ExternalCode = "";
					vSerice.ServiceTypeDescription = "";
					vSerice.ServiceTypeCode = "";
					vSerice.IsRoomRevenue = False;
					vSerice.IsAgentService = False;	
				EndIf;	
			Else
				vSerice.Code = "";
				vSerice.Description = "";
				vSerice.ExternalCode = "";
				vSerice.ServiceTypeDescription = "";
				vSerice.ServiceTypeCode = "";
				vSerice.IsRoomRevenue = False;
				vSerice.IsAgentService = False;
			EndIf;

			vPaymentRow.RecorderNumber					=  mRow.Recorder.Number;
			vPaymentRow.AccountingCustomer				=  vAccountingCustomer;
			vPaymentRow.AccountingContract				=  vAccountingContract;
			vPaymentRow.GuestGroup						=  vGuestGroup;
			vPaymentRow.Folio							=  vFolio;
			vPaymentRow.Period							=  mRow.Period;
			vPaymentRow.AccountingCurrency   			=  vAccountingCurrency;
			vPaymentRow.Company							=  vCompany;
			vPaymentRow.Hotel							=  vHotel2;
			vPaymentRow.Sum								=  Round(mRow.Sum, 2);
			vPaymentRow.VATSum							=  mRow.VATSum;
			vPaymentRow.VATRate							=  vVATRate;
			vPaymentRow.Client							=  vClient;
			vPaymentRow.PaymentMethod					=  vPaymentMethod;
			vPaymentRow.PaymentSection					=  vPaymentSection;
			vPaymentRow.CashRegister					=  vCashRegister;
			vPaymentRow.Quantity						=  1;
			vPaymentRow.Service							=  vSerice;
			vRetXDTO.PaymentTable.PaymentRow.Add(vPaymentRow);
		EndDo;
		WriteLogEvent("Debug3", EventLogLevel.Error, ,,cmGetXMLStringFromXDTO(vRetXDTO));
		Return vRetXDTO;
		
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Runtime Error'; ru='ИнтерфейсСБухгалтерией.Ошибка получения данных по кассе'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") +vError);
		vRetXDTO.ErrorDescription = vError;
		Return  vRetXDTO;
		
	EndTry;
	
EndFunction  //cmGetPaymentList

// -----------------------------------------------------------------------------
Function cmGetPaymentMethods(pPeriodFrom, pPeriodTo) Export
	WriteLogEvent(NStr("en='Payment methods list'; ru='ИнтерфейсСБухгалтерией.Получение списка методов оплат, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom+Chars.LF+NStr("en='Date to: '; ru='Дата окончания: '")+pPeriodTo);
	
	vPaymentMethodsType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentMethods");
	vPaymentMethodRowType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentMethod");
	vPaymentMethodsListType 		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentMethodsList");
	
	vRetXDTO 						= XDTOFactory.Create(vPaymentMethodsListType);
	vRetXDTO.PaymentMethods   		= XDTOFactory.Create(vPaymentMethodsType);
	vRetXDTO.ErrorDescription 		= "";
	
	Try
		vQry = New Query;
		vQry.Text = 
		"SELECT
		|	CashRegisterDailyReceiptsTurnovers.PaymentMethod AS PaymentMethod
		|FROM
		|	(SELECT
		|		CloseOfCashRegisterDay.Ref AS Ref,
		|		CloseOfCashRegisterDay.Date AS Date,
		|		CloseOfCashRegisterDay.DateFrom AS DateFrom
		|	FROM
		|		Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
		|	WHERE
		|		CloseOfCashRegisterDay.Date <= &qPeriodTo
		|		AND CloseOfCashRegisterDay.Date >= &qPeriodFrom
		|		AND CloseOfCashRegisterDay.DeletionMark = FALSE) AS UsedServices
		|		LEFT JOIN AccumulationRegister.CashRegisterDailyReceipts.Turnovers(, , Record, ) AS CashRegisterDailyReceiptsTurnovers
		|		ON (CashRegisterDailyReceiptsTurnovers.Period >= UsedServices.DateFrom)
		|			AND (CashRegisterDailyReceiptsTurnovers.Period <= UsedServices.Date)
		|WHERE
		|	CashRegisterDailyReceiptsTurnovers.PaymentMethod.Code IS NOT NULL 
		|	AND NOT CashRegisterDailyReceiptsTurnovers.PaymentMethod.DoNotExportToTheAccountingSystem
		|
		|GROUP BY
		|	CashRegisterDailyReceiptsTurnovers.PaymentMethod";
		
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", pPeriodTo);
		vTrans = vQry.Execute().Unload();
		
		For Each mRow In vTrans Do
			vPaymentMethodRow = XDTOFactory.Create(vPaymentMethodRowType);
			
			FillPropertyValues(vPaymentMethodRow, mRow.PaymentMethod);
			
			vRetXDTO.PaymentMethods.PaymentMethod.Add(vPaymentMethodRow);
		EndDo;
		
		Return vRetXDTO;	
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Runtime Error'; ru='ИнтерфейсСБухгалтерией.Ошибка получения методов оплат'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") + vError);
		vRetXDTO.ErrorDescription = vError;
		Return  vRetXDTO;
	EndTry;
	
EndFunction	//cmGetPaymentMethods

// -----------------------------------------------------------------------------
Function cmGetPaymentSections(pPeriodFrom, pPeriodTo,pCompanyCode="") Export
	WriteLogEvent(NStr("en='Payment sections list'; ru='ИнтерфейсСБухгалтерией.Получение списка секций, входящие параметры'"), EventLogLevel.Information, , , NStr("en='Date from: '; ru='Дата начала: '") + pPeriodFrom+Chars.LF+NStr("en='Date to: '; ru='Дата окончания: '")+pPeriodTo+Chars.LF+NStr("en='Company code: '; ru='Код фирмы: '")+pCompanyCode);
	
	vPaymentSectionsType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentSections");
	vPaymentSectionsRowType 		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentSectionsRow");
	vPaymentSectionsListType 		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentSectionsList");
	
	vRetXDTO 						= XDTOFactory.Create(vPaymentSectionsListType);
	vRetXDTO.PaymentSections   		= XDTOFactory.Create(vPaymentSectionsType);
	vRetXDTO.ErrorDescription 		= "";
	
	Try
		vQry = New Query;
		vQry.Text = "SELECT
		            |	UsedServices.Ref,
		            |	UsedServices.Date,
		            |	UsedServices.DateFrom
		            |INTO CCRD
		            |FROM
		            |	(SELECT
		            |		CloseOfCashRegisterDay.Ref AS Ref,
		            |		CloseOfCashRegisterDay.Date AS Date,
		            |		CloseOfCashRegisterDay.DateFrom AS DateFrom
		            |	FROM
		            |		Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
		            |	WHERE
		            |		CloseOfCashRegisterDay.Date <= &qPeriodTo
		            |		AND CloseOfCashRegisterDay.Date >= &qPeriodFrom
		            |		AND CloseOfCashRegisterDay.DeletionMark = FALSE
		            |		AND CASE
		            |				WHEN &qCompanyCode = """"""""
		            |					THEN TRUE
		            |				ELSE CloseOfCashRegisterDay.Company.ExternalCode = &qCompanyCode
		            |			END) AS UsedServices
		            |;
		            |
		            |////////////////////////////////////////////////////////////////////////////////
		            |SELECT
		            |	PaymentSections.PaymentSection.Code AS Code,
		            |	PaymentSections.PaymentSection.Description AS Description,
		            |	PaymentSections.PaymentSection.ExternalCode AS ExternalCode,
		            |	TRUE AS IsPaymentSection
		            |FROM
		            |	CCRD AS CCRD
		            |		LEFT JOIN AccumulationRegister.CashRegisterDailyReceipts.Turnovers(, , Record, ) AS PaymentSections
		            |		ON (PaymentSections.Period >= CCRD.DateFrom)
		            |			AND (PaymentSections.Period <= CCRD.Date)
		            |WHERE
		            |	PaymentSections.PaymentSection.Code IS NOT NULL 
		            |
		            |GROUP BY
		            |	PaymentSections.PaymentSection.Code,
		            |	PaymentSections.PaymentSection.Description,
		            |	PaymentSections.PaymentSection.ExternalCode
		            |
		            |UNION ALL
		            |
		            |SELECT
		            |	Accounts.ChequeService.Code,
		            |	Accounts.ChequeService.Description,
		            |	Accounts.ChequeService.ExternalCode,
		            |	FALSE
		            |FROM
		            |	CCRD AS CCRD
		            |		LEFT JOIN AccumulationRegister.CashRegisterDailyReceipts.Turnovers(, , Record, ) AS PaymentSections
		            |			LEFT JOIN AccumulationRegister.Accounts AS Accounts
		            |			ON PaymentSections.Payment = Accounts.Recorder
		            |		ON (PaymentSections.Period >= CCRD.DateFrom)
		            |			AND (PaymentSections.Period <= CCRD.Date)
		            |WHERE
		            |	Accounts.ChequeService.Code IS NOT NULL 
		            |
		            |GROUP BY
		            |	Accounts.ChequeService.Code,
		            |	Accounts.ChequeService.Description,
		            |	Accounts.ChequeService.ExternalCode";
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", pPeriodTo);
		vQry.SetParameter("qCompanyCode", pCompanyCode);
		
		vTrans = vQry.Execute().Unload();
		
		WriteLogEvent(NStr("en='Get services list'; ru='ИнтерфейсСБухгалтерией.Получение списка секций'"), EventLogLevel.Information, , , NStr("en='Services count: '; ru='Количество полученных секций: '") + vTrans.Count());
		
		For Each mRow In vTrans Do
			vPaymentSectionsItemRow = XDTOFactory.Create(vPaymentSectionsRowType);
			
			FillPropertyValues(vPaymentSectionsItemRow, mRow);
			
			vRetXDTO.PaymentSections.PaymentSectionsRow.Add(vPaymentSectionsItemRow);
		EndDo;
		
		Return vRetXDTO;	
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en='Runtime Error'; ru='ИнтерфейсСБухгалтерией.Ошибка получения списка секций'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") + vError);
		vRetXDTO.ErrorDescription = vError;
		Return  vRetXDTO;
	EndTry;
EndFunction  //cmGetPaymentSections

// -----------------------------------------------------------------------------
Function cmPayByDiscountCard(pCardNumber, pSum, pRemarks="", pExternalCode = "", pExternalSystemCode, pHotelCode="", pSource = "") Export
	vInputParams = NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode + Chars.LF +
	NStr("en='External code: ';ru='Внешний код: ';de='Externen code: '") + pExternalCode + Chars.LF +
	NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + pHotelCode + Chars.LF + 
	NStr("en='Card number: ';ru='Номер карты: ';de='Card number: '") + pCardNumber + Chars.LF + 
	NStr("en='Sum: ';ru='Сумма: ';de='Summe: '") + pSum + Chars.LF + 
	NStr("en='Remarks: ';ru='Описание: ';de='Beschreibung: '") + pRemarks; 
	
	WriteLogEvent(NStr("en='Pay by Card';ru='Оплата картой';de='Pay by Card'"), EventLogLevel.Information, , vInputParams);

	vInteraction = Undefined;
	vInteractions = cmGetInteractionByID(pExternalSystemCode, True);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteraction = vInteractions.Get(0).Ref;
		If Not vInteraction.IsActive Then
			Raise NStr("en='Interaction with given interaction ID is not active!'; de='Interaction with given interaction ID is not active!'; ru='Взаимодействие с переданным идентификатором не активно!'");
		EndIf;
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	If vInteraction.DebugMode Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmPayByDiscountCard.Start", Enums.ExternalSystemEventTypes.Info,vInputParams , , vMsg);
	EndIf;
	Try
	vDiscountCard = cmGetDiscountCardById(pCardNumber);
	If Not ValueIsFilled(vDiscountCard) Then
		vMsg = NStr("en='The discount card is not found';ru='Дисконтная карта не найдена';de='Rabattkarte nicht gefunden'");
		If vInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmPayByDiscountCard.GetDiscountCardById", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		EndIf;
		Return vMsg;
	Else
		vMsg = NStr("en='The discount card is found %1';ru='Дисконтная карта найдена %1';de='Rabattkarte gefunden %1'");
		vMsg = StrTemplate(vMsg,vDiscountCard.Description);
		If vInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmPayByDiscountCard.GetDiscountCardById", Enums.ExternalSystemEventTypes.Info, , vMsg);
		EndIf;
	EndIf;
	If ValueIsFilled(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);  	
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = vDiscountCard.Hotel;			
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = vInteraction.Hotel;			
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;			
	EndIf;
	If ValueIsFilled(vHotel) Then
		If vInteraction.DebugMode Then
			vMsg = NStr("en='Document creation bonuses operation';ru='Создание документа операция с бонусами';de='Erstellen eines Dokuments Prämienbetrieb'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmPayByDiscountCard.GetHotel", Enums.ExternalSystemEventTypes.Info, , , vMsg);
		EndIf;
		// Find operation, if it's double call - update old operation rather than create a new one
		vBonusesPaymentRef = Documents.BonusesPayment.EmptyRef();
		If Not IsBlankString(pExternalCode) Then 
			vQ = New Query("SELECT
			               |	BonusesPayment.Card AS Card,
			               |	BonusesPayment.Ref AS Ref,
			               |	BonusesPayment.ExternalCode AS ExternalCode
			               |FROM
			               |	Document.BonusesPayment AS BonusesPayment
			               |WHERE
			               |	NOT BonusesPayment.DeletionMark
			               |	AND BonusesPayment.Card = &qCard
			               |	AND BonusesPayment.ExternalCode = &qExternalCode");
			vQ.SetParameter("qCard",vDiscountCard.Ref);
			vQ.SetParameter("qExternalCode",TrimAll(pExternalCode));
			qRes = vQ.Execute().Select();
			If qRes.Next() Then
				vBonusesPaymentRef = qRes.Ref;
			EndIf;
		EndIf;
		
		If ValueIsFilled(vBonusesPaymentRef) Then
			vBonusesPaymentObj = vBonusesPaymentRef.GetObject();
		Else
			vBonusesPaymentObj = Documents.BonusesPayment.CreateDocument();
			vBonusesPaymentObj.Hotel = vHotel;
		EndIf;
		vBonusesPaymentObj.Fill(vDiscountCard.Ref);
		vBonusesPaymentObj.OperationType = Enums.BonusesPaymentTypes.Expense;
		
		vBonusesPaymentObj.BonusesAmount = pSum;
		vBonusesPaymentObj.BonusesQuantity = Round(pSum * vBonusesPaymentObj.BonusRate, 2);
		
		vBonusesPaymentObj.Source = TrimAll(pSource);
		vBonusesPaymentObj.ExternalCode = TrimAll(pExternalCode);
		vBonusesPaymentObj.Remarks = ?(IsBlankString(TrimAll(pSource)), "", TrimAll(pSource) + " - ") + ?(IsBlankString(TrimAll(pExternalCode)), "", TrimAll(pExternalCode) + " - ") + TrimAll(pRemarks);
		vBonusesPaymentObj.Write(DocumentWriteMode.Posting);
	Else
		vMsg = NStr("en='The hotel cannot be empty';ru='Отель не может быть пустым';de='Das Hotel darf nicht leer sein'");
		If vInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmPayByDiscountCard.GetHotel", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		EndIf;
		Return vMsg
	EndIf;
	If vInteraction.DebugMode Then
		vMsg = NStr("en='End of processing';ru='Конец выполнения';de='Ende der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmPayByDiscountCard.End", Enums.ExternalSystemEventTypes.Info,String(vBonusesPaymentObj.Ref), , vMsg);
	EndIf;
	Except
		vErrorD = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmPayByDiscountCard.Error", Enums.ExternalSystemEventTypes.Warning, , , DetailErrorDescription(vErrorD));
		WriteLogEvent(NStr("en='Payment card from an external system';ru='Оплата картой из внешней системы';de='Zahlungskarte von einem externen System'"), EventLogLevel.Error, , , 
		NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + DetailErrorDescription(vErrorD));
		Return BriefErrorDescription(vErrorD);
	EndTry;
	Return "";
EndFunction // cmPayByDiscountCard

// -----------------------------------------------------------------------------
//  Adds amount to the balance of the discount card.
//  The discount card has to be bonuses or certificate loyalty type
//
// Parameters:
//  pCardNumber			 - 	 - 
//  pSum				 - 	 - 
//  pRemarks			 - 	 - 
//  pExternalCode		 - 	 - 
//  pExternalSystemCode	 - 	 - 
//  pHotelCode			 - 	 - 
//  pSource				 - 	 - 
// 
// Returns:
//  String - Message
//
Function cmAddAmountToDiscountCard(pCardNumber, pSum, pRemarks="", pExternalCode = "", pExternalSystemCode, pHotelCode="", pSource="") Export
	vInputParams = NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode + Chars.LF +
	NStr("en='External code: ';ru='Внешний код: ';de='Externen code: '") + pExternalCode + Chars.LF +
	NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + pHotelCode + Chars.LF + 
	NStr("en='Card number: ';ru='Номер карты: ';de='Card number: '") + pCardNumber + Chars.LF + 
	NStr("en='Sum: ';ru='Сумма: ';de='Summe: '") + pSum + Chars.LF + 
	NStr("en='Remarks: ';ru='Описание: ';de='Beschreibung: '") + pRemarks; 
	
	WriteLogEvent(NStr("en='Activate certificate by discount card';ru='Активация сертификата по дисконтной карте';de='Activate certificate by discount card'"), EventLogLevel.Information, , vInputParams);

	vInteraction = Undefined;
	vInteractions = cmGetInteractionByID(pExternalSystemCode, True);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteraction = vInteractions.Get(0).Ref;
		If Not vInteraction.IsActive Then
			Raise NStr("en='Interaction with given interaction ID is not active!'; de='Interaction with given interaction ID is not active!'; ru='Взаимодействие с переданным идентификатором не активно!'");
		EndIf;
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	If vInteraction.DebugMode Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmActivateCertificateByDiscountCard.Start", Enums.ExternalSystemEventTypes.Info,vInputParams , , vMsg);
	EndIf;
	Try
	vDiscountCard = cmGetDiscountCardById(pCardNumber);
	If Not ValueIsFilled(vDiscountCard) Then
		vMsg = NStr("en='The discount card is not found';ru='Дисконтная карта не найдена';de='Rabattkarte nicht gefunden'");
		If vInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmActivateCertificateByDiscountCard.GetDiscountCardById", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		EndIf;
		Return vMsg;
	Else
		// Discount card is found
		If vInteraction.DebugMode Then
			vMsg = NStr("en='The discount card is found %1';ru='Дисконтная карта найдена %1';de='Rabattkarte gefunden %1'");
			vMsg = StrTemplate(vMsg,vDiscountCard.Description);
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmActivateCertificateByDiscountCard.GetDiscountCardById", Enums.ExternalSystemEventTypes.Info, , vMsg);
		EndIf;
	EndIf;
	If ValueIsFilled(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);  	
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = vDiscountCard.Hotel;			
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = vInteraction.Hotel;			
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;			
	EndIf;
	vBonusesPayment = GetBonusesPaymentByDiscountCard(vDiscountCard);
	If ValueIsFilled(vHotel) Then
		If vBonusesPayment.Count() = 0 Then 
			If vInteraction.DebugMode Then
				vMsg = NStr("en='Document creation bonuses operation';ru='Создание документа операция с бонусами';de='Erstellen eines Dokuments Prämienbetrieb'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmActivateCertificateByDiscountCard.GetHotel", Enums.ExternalSystemEventTypes.Info, , , vMsg);
			EndIf;
			vBonusesPaymentObj = Documents.BonusesPayment.CreateDocument();
			vBonusesPaymentObj.Fill(vDiscountCard.Ref);
			vBonusesPaymentObj.Hotel = vHotel;
			vBonusesPaymentObj.OperationType = Enums.BonusesPaymentTypes.Receipt;
			vBonusesPaymentObj.BonusesAmount = pSum;
			vBonusesPaymentObj.BonusesQuantity = Round(pSum * vBonusesPaymentObj.BonusRate, 2);
			vBonusesPaymentObj.Source = TrimAll(pSource);
			vBonusesPaymentObj.ExternalCode = TrimAll(pExternalCode);
			vBonusesPaymentObj.Remarks = ?(IsBlankString(TrimAll(pSource)), "", TrimAll(pSource) + " - ") + ?(IsBlankString(TrimAll(pExternalCode)), "", TrimAll(pExternalCode) + " - ") + TrimAll(pRemarks);
			vBonusesPaymentObj.IsActivateCertificate = False;
			vBonusesPaymentObj.Write(DocumentWriteMode.Posting);
		Else
			vMsg = NStr("en='The certificate for this card is already activated';ru='Сертификат по данной карте уже активирован';de='Das Zertifikat für diese Karte ist bereits aktiviert'");
			If vInteraction.DebugMode Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmActivateCertificateByDiscountCard.GetHotel", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
			EndIf;
			Return vMsg		
		EndIf;
	Else
		vMsg = NStr("en='The hotel cannot be empty';ru='Отель не может быть пустым';de='Das Hotel darf nicht leer sein'");
		If vInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmActivateCertificateByDiscountCard.GetHotel", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		EndIf;
		Return vMsg
	EndIf;
	If vInteraction.DebugMode Then
		vMsg = NStr("en='End of processing';ru='Конец выполнения';de='Ende der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmActivateCertificateByDiscountCard.End", Enums.ExternalSystemEventTypes.Info,String(vBonusesPaymentObj.Ref), , vMsg);
	EndIf;
	Except
		vErrorD = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmActivateCertificateByDiscountCard.Error", Enums.ExternalSystemEventTypes.Warning, , , DetailErrorDescription(vErrorD));
		WriteLogEvent(NStr("en='Activating a certificate from an external system';ru='Активация сертификата из внешней системы';de='Aktivieren eines Zertifikats von einem externen System'"), EventLogLevel.Error, , , 
		NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + DetailErrorDescription(vErrorD));
		Return BriefErrorDescription(vErrorD);
	EndTry;
	Return "";
EndFunction // cmActivateCertificateByDiscountCard

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDiscountCard	 - CatalogRef.DiscountCards	 - Ref
// 
// Returns:
//  ValueTable - List of Bonuses payment
//
Function GetBonusesPaymentByDiscountCard(pDiscountCard)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BonusesPayment.Ref AS Ref
	|FROM
	|	Document.BonusesPayment AS BonusesPayment
	|WHERE
	|	NOT BonusesPayment.DeletionMark
	|	AND BonusesPayment.Card = &qCard
	|	AND BonusesPayment.IsActivateCertificate";
	vQry.SetParameter("qCard", pDiscountCard);
	vInteractionObj = Undefined;
	Return vQry.Execute().Unload();	
EndFunction // GetBonusesPaymentByDiscountCard

// -----------------------------------------------------------------------------
//  Description: Pay by certificate.
//  Function could be called as web-service or thru COM connection
//
// Parameters:
//  pCertificateNumber	 - 	 - 
//  pSum				 - 	 - 
//  pRemarks			 - 			 - 
//  pDetails			 - 			 - 
//  pExternalSystemCode	 - 			 - 
//  pHotelCode			 - 			 - 
//  pCurrency			 - 			 - 
//  pVatRate			 - 			 - 
// 
// Returns:
//  String - Empty string if charge was done successfully or error description
//
Function cmPayByCertificate(pCertificateNumber, pSum, pRemarks="", pDetails="", pExternalSystemCode="",pHotelCode="", pCurrency="", pVatRate=Undefined) Export 
	WriteLogEvent(NStr("en='Pay by certificate';ru='Оплата сертификатом';de='Pay by certificate'"), EventLogLevel.Information, , , 
	NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode + Chars.LF + 
	NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + pHotelCode + Chars.LF + 
	NStr("en='VatRate: ';ru='НДС: ';de='VatRate: '") + pVatRate + Chars.LF + 
	NStr("en='Certificate number: ';ru='Номер сертификата: ';de='Certificate number: '") + pCertificateNumber + Chars.LF + 
	NStr("en='Sum: ';ru='Сумма: ';de='Summe: '") + pSum + Chars.LF + 
	NStr("en='Currency: ';ru='Валюта: ';de='Währung: '") + pCurrency + Chars.LF + 
	NStr("en='Remarks: ';ru='Описание: ';de='Beschreibung: '") + pRemarks + Chars.LF + 
	NStr("en='Details: ';ru='Детали: ';de='Details: '") + pDetails);
	Try
		// Get hotel
		vHotel = SessionParameters.CurrentHotel;
		If Not IsBlankString(pHotelCode) Then
			vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
		EndIf;
		// Get currency by code
		vCurrency = Catalogs.Currencies.EmptyRef();
		If Not IsBlankString(pCurrency) Then
			vCurrency = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Currencies", pCurrency);
		EndIf;
		
		//1. CREATE FOLIO
		FolioObj = Documents.Folio.CreateDocument();
		FolioObj.pmFillAttributesWithDefaultValues();
		FolioObj.Date = CurrentSessionDate();
		FolioObj.DateTimeFrom = BegOfDay(CurrentSessionDate());
		FolioObj.DateTimeTo = EndOfDay(CurrentSessionDate());
		FolioObj.Description = NStr("en='Charge from Traktir';ru='Начисление из Трактира';de='Laden aus Traktir'");
		FolioObj.CreditLimit = pSum;
		FolioObj.Write();
		
		vFolio =  FolioObj.Ref;
		
		//2.CHARGE SERVICE BY FOLIO
		vServiceCode = "";
		vError = cmChargeExternalServiceByFolio(vFolio.Number, vServiceCode, pSum, 1, pRemarks, pDetails, pHotelCode, pExternalSystemCode, pCurrency, pVATRate);
		
		FolioObj.CreditLimit = 0;
		FolioObj.Write();

		If Not vError="" Then
			Return vError;
		EndIf;
		
				
		vQr = New Query("SELECT
		|	PaymentMethods.Ref
		|FROM
		|	Catalog.PaymentMethods AS PaymentMethods
		|WHERE
		|	NOT PaymentMethods.DeletionMark
		|	AND PaymentMethods.IsByGiftCertificate");
		vRes = vQr.Execute().Unload();
		If vRes.Count()>0 Then
			vPaymentMethod = vRes[0].Ref;
		Else 
			vPaymentMethod = vHotel.PlannedPaymentMethod;
		EndIf;
		
		//3. CREATE PAYMENT FOR THE FOLIO
		vPaymentObj = Documents.Payment.CreateDocument();
		vPaymentObj.Fill(vFolio);
		vPaymentObj.PaymentCurrency = vCurrency;
		vPaymentObj.PaymentMethod = vPaymentMethod;
		// Payment sections
		vPaymentSection = Undefined;
		If ValueIsFilled(vPaymentObj.Hotel) And vPaymentObj.Hotel.SplitFolioBalanceByPaymentSections Then
			// Update payment object
			vRestOfAmount = pSum;
			For Each vPSRow In vPaymentObj.PaymentSections Do
				If vRestOfAmount > 0 Then
					If vPSRow.Sum <= vRestOfAmount Then
						vRestOfAmount = vRestOfAmount - vPSRow.Sum;
					Else
						vPSRow.Sum = vRestOfAmount;
						vRestOfAmount = 0;
						
						vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vPaymentObj.Date);
						vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
						vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vPaymentObj.Date);
					EndIf;
				Else
					vPSRow.Sum = 0;
					vPSRow.VATSum = 0;
					vPSRow.SumInFolioCurrency = 0;
					vPSRow.VATSumInFolioCurrency = 0;
				EndIf;
			EndDo;
			If vRestOfAmount > 0 Then
				vPSRow = vPaymentObj.PaymentSections.Add();
				vPSRow.PaymentSection = vPaymentSection;
				vPSRow.Sum = vRestOfAmount;
				vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
				If ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.VATRate) Then
					vPSRow.VATRate = vPaymentSection.VATRate;
				Else
					vPSRow.VATRate = vPaymentObj.VATRate;
				EndIf;
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vPaymentObj.Date);
				vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vPaymentObj.Date);
			EndIf;
			vPaymentObj.pmCalculateTotalsByPaymentSections();
		ElsIf ValueIsFilled(vPaymentObj.Hotel) And vPaymentObj.Hotel.SplitFolioBalanceByServicesAndPrices Then
			// Try to find service
			vService = Catalogs.Services.EmptyRef();
			If IsBlankString(vServiceCode) Then
				vService = vPaymentObj.Hotel.CateringService;
			Else
				vService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", TrimAll(vServiceCode));
				If Not ValueIsFilled(vService) Then
					vService = cmGetServiceByCode(TrimAll(vServiceCode));
				EndIf;
			EndIf;
			If Not ValueIsFilled(vService) Then
				vService = vPaymentObj.Hotel.CateringService;
			EndIf;		
			
			// Update payment object
			vRestOfAmount = pSum;
			For Each vPSRow In vPaymentObj.PaymentSections Do
				If vRestOfAmount > 0 Then
					If vPSRow.Sum <= vRestOfAmount Then
						vRestOfAmount = vRestOfAmount - vPSRow.Sum;
					Else
						vPSRow.Sum = vRestOfAmount;
						vRestOfAmount = 0;
						
						vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vPaymentObj.Date);
						vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
						vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vPaymentObj.Date);
					EndIf;
				Else
					vPSRow.Sum = 0;
					vPSRow.VATSum = 0;
					vPSRow.SumInFolioCurrency = 0;
					vPSRow.VATSumInFolioCurrency = 0;
				EndIf;
			EndDo;
			If vRestOfAmount > 0 Then
				vPSRow = vPaymentObj.PaymentSections.Add();
				vPSRow.PaymentSection = vPaymentSection;
				vPSRow.ChequeService = vService;
				vPSRow.ChequeServicePrice = vRestOfAmount;
				vPSRow.ChequeServiceQuantity = 1;
				vPSRow.Sum = vRestOfAmount;
				vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
				If ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.VATRate) Then
					vPSRow.VATRate = vPaymentSection.VATRate;
				Else
					vPSRow.VATRate = vPaymentObj.VATRate;
				EndIf;
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vPaymentObj.Date);
				vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vPaymentObj.Date);
			EndIf;
			vPaymentObj.pmCalculateTotalsByPaymentSections();
		Else
			// Build payment object
			vPaymentObj.PaymentSection = vPaymentSection;
			vPaymentObj.Sum = pSum;
			If TypeOf(vPaymentObj) = Type("DocumentObject.Payment") Then
				vPaymentObj.pmRecalculateSums();
			ElsIf TypeOf(vPaymentObj) = Type("DocumentObject.CustomerPayment") Then
				vPaymentObj.SumInAccountingCurrency = Round(cmConvertCurrencies(vPaymentObj.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.AccountingCurrency, vPaymentObj.AccountingCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
			EndIf;
		EndIf;
		// Reference and authorization codes
		vPaymentObj.ReferenceNumber = "";
		vPaymentObj.AuthorizationCode = "";
		// Payment remarks
		vPaymentObj.SlipText = "";
		// External system payment code
		vPaymentObj.ExternalCode = TrimR(pExternalSystemCode);
		// Gift Certificate
		vPaymentObj.GiftCertificate = TrimR(pCertificateNumber);
		// Set customer as payer
		If ValueIsFilled(vPaymentObj.AccountingCustomer) And ValueIsFilled(vPaymentObj.PaymentMethod) And vPaymentObj.PaymentMethod.IsByBankTransfer Then
			If ValueIsFilled(vPaymentObj.Hotel) And vPaymentObj.AccountingCustomer <> vPaymentObj.Hotel.IndividualsCustomer Then
				vPaymentObj.Payer = vPaymentObj.AccountingCustomer;
			EndIf;
		EndIf;
		// Post payment
		vPaymentObj.Write(DocumentWriteMode.Posting);
		
		// 4.Close folio
		FolioObj.IsClosed = True;
		FolioObj.Write();
	Except
		WriteLogEvent(NStr("en='Payment certificate from an external system';ru='Оплата сертификатом из внешней системы';de='Zahlung Zertifikat von einem externen System'"), EventLogLevel.Error, , , 
		NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + ErrorDescription());
		Return ErrorDescription();
	EndTry;
	Return "";
EndFunction //  cmPayByCertificate()

// -----------------------------------------------------------------------------
Function cmGetCloseOfCashRegisterDayPaymentList(qPeriodFrom, qPeriodTo, pCompanyCode="") Export
	WriteLogEvent(NStr("en='GetCloseOfCashRegisterDay'; ru='ИнтерфейсСБухгалтерией.Получение списка платежей по сменам, входящие параметры'"), EventLogLevel.Information, 
	, , NStr("en='Date from: '; ru='Дата начала: '") + qPeriodFrom+Chars.LF+NStr("en='Date to: '; ru='Дата окончания: '")+qPeriodTo+Chars.LF+NStr("en = 'Company code: '; ru = 'Код фирмы: '; de = 'Company code: '")+pCompanyCode);
	
	vCashRegisterDayPaymentsType 				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CashRegisterDayPayments");
	vCloseOfCashRegisterDayPaymentListType		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CloseOfCashRegisterDayPaymentList");
	vCloseOfCashRegisterDayPaymentListRowType	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CloseOfCashRegisterDayPaymentListRow");
	vAccountingCustomerType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow");
	vAccountingCurrencyType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AccountingCurrency");
	vPaymentMethodType	        				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentMethod");
	vCompanyType	        					= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CompanyItemRow");
	vCashRegisterType	        				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CashRegister");
	
	// Detail payment table
	vPaymentTableType 				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentTable");
	vPaymentRowType					= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentRow");
	vAccountingContractType	        = XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AccountingContract");
	vHotelType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "HotelParameters");
	vGuestGroupType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "GuestGroup");
	vClientType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Client");
	vPaymentSectionType	        	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "PaymentSectionsRow");
	vFolioType	        			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Folio");
	vVATRateType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "VATRate");
	vParentDocType	        		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "ParentDoc");
	vServiceType					= XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "ServicesItemRow");
	
	vRetXDTO 										= XDTOFactory.Create(vCashRegisterDayPaymentsType);
	vRetXDTO.CloseOfCashRegisterDayPaymentList		= XDTOFactory.Create(vCloseOfCashRegisterDayPaymentListType);
	vRetXDTO.ErrorDescription 						= "";
	
	Try
		vQry = New Query;
		vQry.Text = 
		"SELECT
		|	CCRDAccountingTotals.Ref AS Ref,
		|	CCRDAccountingTotals.Currency AS Currency,
		|	CCRDAccountingTotals.PaymentMethod AS PaymentMethod,
		|	CCRDAccountingTotals.Customer AS Customer,
		|	CCRDAccountingTotals.Sum AS Sum,
		|	CCRDAccountingTotals.ExternalCode AS ExternalCode,
		|	CCRDAccountingTotals.Ref.Company AS Company,
		|	CCRDAccountingTotals.Ref.CashRegister AS CashRegister,
		|	CCRDAccountingTotals.IsPayment AS IsPayment
		|FROM
		|	Document.CloseOfCashRegisterDay.AccountingTotals AS CCRDAccountingTotals
		|WHERE
		|	CCRDAccountingTotals.Ref.Date >= &qDateFrom
		|	AND CCRDAccountingTotals.Ref.Date <= &qDateTo
		|	AND CASE
		|			WHEN &qCompany <> """"
		|				THEN CCRDAccountingTotals.Ref.Company.ExternalCode = &qCompany
		|			ELSE TRUE
		|		END
		|	AND CCRDAccountingTotals.Ref.DeletionMark = FALSE
		|	AND CCRDAccountingTotals.Ref.Posted";
		vQry.SetParameter("qDateFrom", qPeriodFrom+1);
		vQry.SetParameter("qDateTo", qPeriodTo);
		vQry.SetParameter("qCompany", pCompanyCode);
		vQryResAccountingTotals = vQry.Execute();
		
		vQry = New Query;
		vQry.Text = 
		"SELECT DISTINCT
		|	CCRDAccountingTotals.ExternalCode AS ExternalCode,
		|	CCRDAccountingTotals.Ref AS CCRDRef,
		|	CCRDAccountingTotals.Customer AS Customer,
		|	CCRDAccountingTotals.Currency AS Currency,
		|	CCRDAccountingTotals.PaymentMethod AS PaymentMethod
		|INTO CCRD
		|FROM
		|	Document.CloseOfCashRegisterDay.AccountingTotals AS CCRDAccountingTotals
		|WHERE
		|	CCRDAccountingTotals.Ref.Date >= &qDateFrom
		|	AND CCRDAccountingTotals.Ref.Date <= &qDateTo
		|	AND CASE
		|			WHEN &qCompany <> """"""""
		|				THEN CCRDAccountingTotals.Ref.Company.ExternalCode = &qCompany
		|			ELSE TRUE
		|		END
		|	AND CCRDAccountingTotals.Ref.DeletionMark = FALSE
		|	AND CCRDAccountingTotals.Ref.Posted
		|
		|GROUP BY
		|	CCRDAccountingTotals.ExternalCode,
		|	CCRDAccountingTotals.Ref,
		|	CCRDAccountingTotals.PaymentMethod,
		|	CCRDAccountingTotals.Customer,
		|	CCRDAccountingTotals.Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CashRegisterDailyReceipts.Payment AS Payment,
		|	CCRD.ExternalCode AS ExternalCode,
		|	CCRD.CCRDRef AS CCRDRef,
		|	CCRD.Customer AS Customer,
		|	CCRD.Currency AS Currency,
		|	CCRD.PaymentMethod AS PaymentMethod
		|INTO PaymentsTab
		|FROM
		|	AccumulationRegister.CashRegisterDailyReceipts AS CashRegisterDailyReceipts
		|		LEFT JOIN CCRD AS CCRD
		|		ON CashRegisterDailyReceipts.Recorder = CCRD.CCRDRef
		|			AND CashRegisterDailyReceipts.Payment.AccountingCustomer = CCRD.Customer
		|			AND CashRegisterDailyReceipts.Currency = CCRD.Currency
		|			AND CashRegisterDailyReceipts.PaymentMethod = CCRD.PaymentMethod
		|WHERE
		|	CashRegisterDailyReceipts.Recorder IN
		|			(SELECT
		|				CCRD.CCRDRef AS CCRDRef
		|			FROM
		|				CCRD AS CCRD)
		|	AND CashRegisterDailyReceipts.Payment.Date >= CCRD.CCRDRef.DateFrom
		|	AND CashRegisterDailyReceipts.Payment.Date <= CCRD.CCRDRef.Date
		|
		|GROUP BY
		|	CashRegisterDailyReceipts.Payment,
		|	CCRD.ExternalCode,
		|	CCRD.CCRDRef,
		|	CCRD.Customer,
		|	CCRD.Currency,
		|	CCRD.PaymentMethod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Accounts.Period AS Period,
		|	PaymentsTab.Payment AS Recorder,
		|	Accounts.Hotel AS Hotel,
		|	Accounts.FolioCurrency AS Currency,
		|	Accounts.PaymentSection AS PaymentSection,
		|	Accounts.PaymentMethod AS PaymentMethod,
		|	PaymentsTab.Payment.AccountingCustomer AS Customer,
		|	PaymentsTab.Payment.AccountingContract AS Contract,
		|	PaymentsTab.Payment.GuestGroup AS GuestGroup,
		|	PaymentsTab.Payment.Payer AS Payer,
		|	Accounts.Folio AS Folio,
		|	Accounts.VATRate AS VATRate,
		|	Accounts.ChequeService AS ChequeService,
		|	CASE
		|		WHEN ISNULL(Accounts.ChequeServiceQuantity, 1) = 0
		|			THEN 1
		|		ELSE ISNULL(Accounts.ChequeServiceQuantity, 1)
		|	END AS Quantity,
		|	Accounts.ChequeServicePrice AS ChequeServicePrice,
		|	Accounts.VATSum AS VATSum,
		|	Accounts.Sum AS Sum,
		|	PaymentsTab.CCRDRef AS CCRDRef,
		|	PaymentsTab.ExternalCode AS ExternalCode,
		|	PaymentsTab.CCRDRef.Company AS Company,
		|	PaymentsTab.CCRDRef.CashRegister AS CashRegister,
		|	CASE
		|		WHEN PaymentsTab.Payment REFS Document.Payment
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS IsPayment
		|FROM
		|	PaymentsTab AS PaymentsTab
		|		LEFT JOIN AccumulationRegister.Accounts AS Accounts
		|		ON PaymentsTab.Payment = Accounts.Recorder
		|			AND PaymentsTab.PaymentMethod = Accounts.PaymentMethod
		|			AND PaymentsTab.Currency = Accounts.FolioCurrency
		|			AND PaymentsTab.Customer = Accounts.Recorder.AccountingCustomer
		|WHERE
		|	Accounts.Recorder IN
		|			(SELECT
		|				PaymentsTab.Payment AS Payment
		|			FROM
		|				PaymentsTab AS PaymentsTab)
		|	AND PaymentsTab.PaymentMethod.DoNotExportToTheAccountingSystem = FALSE
		|
		|GROUP BY
		|	Accounts.ChequeService,
		|	Accounts.ChequeServicePrice,
		|	Accounts.Period,
		|	Accounts.Hotel,
		|	Accounts.FolioCurrency,
		|	Accounts.VATRate,
		|	Accounts.VATSum,
		|	Accounts.PaymentMethod,
		|	Accounts.PaymentSection,
		|	PaymentsTab.Payment.AccountingCustomer,
		|	PaymentsTab.Payment.AccountingContract,
		|	PaymentsTab.Payment.GuestGroup,
		|	PaymentsTab.Payment.Payer,
		|	PaymentsTab.Payment,
		|	Accounts.Folio,
		|	CASE
		|		WHEN ISNULL(Accounts.ChequeServiceQuantity, 1) = 0
		|			THEN 1
		|		ELSE ISNULL(Accounts.ChequeServiceQuantity, 1)
		|	END,
		|	PaymentsTab.CCRDRef,
		|	PaymentsTab.ExternalCode,
		|	PaymentsTab.CCRDRef.Company,
		|	PaymentsTab.CCRDRef.CashRegister,
		|	Accounts.Sum
		|TOTALS
		|	SUM(Sum)
		|BY
		|	CCRDRef,
		|	PaymentMethod";
		
		vQry.SetParameter("qDateFrom", qPeriodFrom);
		vQry.SetParameter("qDateTo", qPeriodTo);
		vQry.SetParameter("qCompany", pCompanyCode);
		
		vQryRes = vQry.Execute().Unload();
		
		If vQryResAccountingTotals.IsEmpty() Then
			vError = NStr("en = 'There is no payment for the period'; ru = 'Нет платежей за указанный период'; de = 'Es gibt keine Zahlung für den Zeitraum'");
			WriteLogEvent(NStr("en = 'Runtime Error'; ru = 'ИнтерфейсСБухгалтерией.Ошибка получения списка платежей по сменам'"), EventLogLevel.Error, 
			, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") +vError);
			vRetXDTO.ErrorDescription = vError;
			Return  vRetXDTO;
		Else	
			vTrans = vQryResAccountingTotals.Select();
			While vTrans.Next() Do
				
				vCloseOfCashRegisterDayPaymentListRow 	= XDTOFactory.Create(vCloseOfCashRegisterDayPaymentListRowType); 
				vAccountingCustomer       				= XDTOFactory.Create(vAccountingCustomerType);
				vAccountingCurrency       				= XDTOFactory.Create(vAccountingCurrencyType);
				vPaymentMethod		       				= XDTOFactory.Create(vPaymentMethodType);
				vCompany 	                            = XDTOFactory.Create(vCompanyType);
				vCashRegister 	                        = XDTOFactory.Create(vCashRegisterType);
				vHotel 									= XDTOFactory.Create(vHotelType);
				
				FillPropertyValues(vPaymentMethod,		vTrans.PaymentMethod);
				FillPropertyValues(vAccountingCurrency,	vTrans.Currency);
				
				FillPropertyValues(vAccountingCustomer,	vTrans.Customer); 
				vSourcesOfBusiness = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "SourcesOfBusiness"));
				vSB = vTrans.Customer.SourceOfBusiness;
				If ValueIsFilled(vSB) Then
					vSourcesOfBusiness.Code = TrimAll(vSB.Code);	
					vSourcesOfBusiness.Description = TrimAll(vSB.Description);
				Else
					vSourcesOfBusiness.Code = "";	
					vSourcesOfBusiness.Description = "";	
				EndIf;	 
				vAccountingCustomer.SourcesOfBusiness = vSourcesOfBusiness;
				
				FillPropertyValues(vCompany,			vTrans.Company);
				FillPropertyValues(vCashRegister,		vTrans.CashRegister,,"Hotel");
				If ValueIsFilled(vTrans.CashRegister.Hotel) Then
					FillPropertyValues(vHotel,				vTrans.CashRegister.Hotel);
				Else
					vHotel.Code = "";
					vHotel.LegacyName = "";
					vHotel.ExternalCode = "";
				EndIf;
				vCashRegister.Hotel = vHotel;
				
				vCloseOfCashRegisterDayPaymentListRow.CCRDPeriodFrom 		= vTrans.ref.DateFrom;
				vCloseOfCashRegisterDayPaymentListRow.CCRDPeriodTo 			= vTrans.ref.Date;
				vCloseOfCashRegisterDayPaymentListRow.AccountingDate		= vTrans.ref.AccountingDate;
				vCloseOfCashRegisterDayPaymentListRow.AccountingCustomer 	= vAccountingCustomer;
				vCloseOfCashRegisterDayPaymentListRow.AccountingCurrency	= vAccountingCurrency;
				vCloseOfCashRegisterDayPaymentListRow.PaymentMethod 		= vPaymentMethod;
				vCloseOfCashRegisterDayPaymentListRow.Sum 					= vTrans.Sum;
				vCloseOfCashRegisterDayPaymentListRow.ExternalCode			= vTrans.ExternalCode;
				vCloseOfCashRegisterDayPaymentListRow.Company				= vCompany;
				vCloseOfCashRegisterDayPaymentListRow.CashRegister			= vCashRegister;
				vCloseOfCashRegisterDayPaymentListRow.CCRDGUID				= String(vTrans.ref.UUID());
				vCloseOfCashRegisterDayPaymentListRow.CCRDNumber			= vTrans.ref.Number;
				vCloseOfCashRegisterDayPaymentListRow.CCRDExternalCode		= vTrans.ref.ExternalCode;
				vCloseOfCashRegisterDayPaymentListRow.Author				= TrimAll(vTrans.ref.Author);

				
				vFilter = New Structure("Currency,PaymentMethod,Customer,CCRDRef,ExternalCode,IsPayment",vTrans.Currency,vTrans.PaymentMethod,vTrans.Customer,vTrans.ref,vTrans.ExternalCode, vTrans.IsPayment);
				vFilterRows = vQryRes.FindRows(vFilter);
				
				vPaymentTable			= XDTOFactory.Create(vPaymentTableType);
				For Each mRow In vFilterRows Do
					
					vAccountingCustomerRow       				= XDTOFactory.Create(vAccountingCustomerType);
					vAccountingCurrencyRow       				= XDTOFactory.Create(vAccountingCurrencyType);
					vPaymentMethodRow		       				= XDTOFactory.Create(vPaymentMethodType);
					vCompanyRow 	                            = XDTOFactory.Create(vCompanyType);
					vCashRegisterRow 	                        = XDTOFactory.Create(vCashRegisterType);
					vHotel 										= XDTOFactory.Create(vHotelType);

					FillPropertyValues(vPaymentMethodRow,		mRow.PaymentMethod);
					FillPropertyValues(vAccountingCurrencyRow,	mRow.Currency);
					FillPropertyValues(vAccountingCustomerRow,	mRow.Customer);
					FillPropertyValues(vCompanyRow,				mRow.Company);
					FillPropertyValues(vCashRegisterRow,		mRow.CashRegister,,"Hotel");
					If ValueIsFilled(mRow.CashRegister.Hotel) Then
						FillPropertyValues(vHotel,				mRow.CashRegister.Hotel);
					Else
					    vHotel.Code = "";
						vHotel.LegacyName = "";
						vHotel.ExternalCode = "";
					EndIf;
					vCashRegisterRow.Hotel = vHotel;

					
					vPaymentRow  		= XDTOFactory.Create(vPaymentRowType);
					vAccountingContract = XDTOFactory.Create(vAccountingContractType); 
					vHotel				= XDTOFactory.Create(vHotelType);
					vGuestGroup			= XDTOFactory.Create(vGuestGroupType);
					vClient				= XDTOFactory.Create(vClientType);
					vFolio				= XDTOFactory.Create(vFolioType);
					vParentDoc			= XDTOFactory.Create(vParentDocType);
					vVATRate			= XDTOFactory.Create(vVATRateType);
					vPaymentSection     = XDTOFactory.Create(vPaymentSectionType);
					vService			= XDTOFactory.Create(vServiceType);
					
					vAccountingContract.Code 					=  ?(ValueIsFilled(mRow.Contract),mRow.Contract.Code,"");
					vAccountingContract.Description 			=  mRow.Contract.Description;
					vAccountingContract.ExternalCode 			=  mRow.Contract.ExternalCode;
					
					//Fill Hotel
					FillPropertyValues(vHotel,mRow.Hotel);
					
					vGuestGroup.Code 							=  ?(ValueIsFilled(mRow.GuestGroup),mRow.GuestGroup.Code,"");
					vGuestGroup.Description 					=  mRow.GuestGroup.Description;
					vGuestGroup.ExternalCode 					=  mRow.GuestGroup.ExternalCode;
					
					vClient.Code 								=  ?(ValueIsFilled(mRow.Payer),mRow.Payer.Code,"");
					vClient.Description 						=  ?(ValueIsFilled(mRow.Payer),mRow.Payer.Description,"");
					
					vPaymentSection.Code 						=  ?(ValueIsFilled(mRow.PaymentSection),mRow.PaymentSection.Code,"");
					vPaymentSection.Description 				=  mRow.PaymentSection.Description;
					vPaymentSection.ExternalCode 				=  mRow.PaymentSection.ExternalCode;
					
					vFolio.DateTimeFrom 						=  mRow.Folio.DateTimeFrom;
					vFolio.DateTimeTo 							=  mRow.Folio.DateTimeTo;
					vFolio.Number 								=  mRow.Folio.Number;
					vFolio.Description 							=  mRow.Folio.Description;
					
					vVATRate.TaxRate                            =  mRow.VATRate.TaxRate;
					vVATRate.Description                        =  mRow.VATRate.Description;
					
					If ValueIsFilled(mRow.ChequeService) Then
						vService.Code								=  mRow.ChequeService.Code;
						vService.Description  						=  mRow.ChequeService.Description;
						vService.ExternalCode       				=  mRow.ChequeService.ExternalCode;
						vService.IsRoomRevenue       				=  mRow.ChequeService.IsRoomRevenue;
						vService.ServiceTypeDescription   			=  ?(ValueIsFilled(mRow.ChequeService.ServiceType),mRow.ChequeService.ServiceType.Description,"");
						vService.ServiceTypeCode   		 			=  ?(ValueIsFilled(mRow.ChequeService.ServiceType),mRow.ChequeService.ServiceType.Code,"");
						vService.IsAgentService					    =  mRow.ChequeService.IsAgentService;
					Else
						vService.Code								=  "";
						vService.Description  						=  "";
						vService.ExternalCode       				=  "";
						vService.IsRoomRevenue       				=  False;
						vService.ServiceTypeDescription   			=  "";
						vService.ServiceTypeCode   		 			=  "";
						vService.IsAgentService					    =  False;
					EndIf;
					vParentDoc.HasOfficialLetter            	=  False;
					
					If  ValueIsFilled(mRow.Folio.ParentDoc) Then
						vParentDoc.HasOfficialLetter            =  ?(mRow.Folio.ParentDoc.Metadata().Attributes.Find("HasOfficialLetter")<>Undefined,mRow.Folio.ParentDoc.HasOfficialLetter,False);
						vGuest									=  XDTOFactory.Create(vClientType);
						
						If mRow.Folio.ParentDoc.Metadata().Attributes.Find("Guest")<>Undefined  Then
							vGuest.Code 							=  ?(ValueIsFilled(mRow.Folio.ParentDoc.Guest),mRow.Folio.ParentDoc.Guest.Code,"");
							vGuest.Description 						=  ?(ValueIsFilled(mRow.Folio.ParentDoc.Guest),mRow.Folio.ParentDoc.Guest.Description,"");
						ElsIf mRow.Folio.ParentDoc.Metadata().Attributes.Find("Client")<>Undefined  Then
							vGuest.Code 						=  ?(ValueIsFilled(mRow.Folio.ParentDoc.Client),mRow.Folio.ParentDoc.Client.Code,"");
							vGuest.Description 					=  ?(ValueIsFilled(mRow.Folio.ParentDoc.Client),mRow.Folio.ParentDoc.Client.Description,"");
						Else
							vGuest.Code 						=  "";
							vGuest.Description 					=  "";
						EndIf;
						vParentDoc.Guest            			=  vGuest;
					EndIf;	
					vFolioGuestGroup                       		=  XDTOFactory.Create(vGuestGroupType);  
					vFolioGuestGroup.Code 						=  ?(ValueIsFilled(mRow.Folio.GuestGroup),mRow.Folio.GuestGroup.Code,"");
					vFolioGuestGroup.Description 				=  mRow.Folio.GuestGroup.Description;
					vFolioGuestGroup.ExternalCode 				=  mRow.Folio.GuestGroup.ExternalCode;
					vFolio.GuestGroup							=  vFolioGuestGroup;
					vFolio.ParentDoc 							=  vParentDoc;
					
					vPaymentRow.RecorderNumber					=  mRow.Recorder.Number;
					vPaymentRow.AccountingCustomer				=  vAccountingCustomerRow;
					vPaymentRow.AccountingContract				=  vAccountingContract;
					vPaymentRow.GuestGroup						=  vGuestGroup;
					vPaymentRow.Folio							=  vFolio;
					vPaymentRow.Period							=  mRow.Period;
					vPaymentRow.AccountingCurrency   			=  vAccountingCurrencyRow;
					vPaymentRow.Company							=  vCompanyRow;
					vPaymentRow.Hotel							=  vHotel;
					vPaymentRow.Sum								=  Round(mRow.Sum,2);
					vPaymentRow.VATSum							=  mRow.VATSum;
					vPaymentRow.VATRate							=  vVATRate;
					vPaymentRow.Client							=  vClient;
					vPaymentRow.PaymentMethod					=  vPaymentMethodRow;
					vPaymentRow.PaymentSection					=  vPaymentSection;
					vPaymentRow.CashRegister					=  vCashRegisterRow;
					vPaymentRow.Service							=  vService;
					vPaymentRow.Quantity						=  mRow.Quantity;
					vPaymentTable.PaymentRow.Add(vPaymentRow);
					
					
				EndDo;
				vCloseOfCashRegisterDayPaymentListRow.PaymentTable =  vPaymentTable;
				
				vRetXDTO.CloseOfCashRegisterDayPaymentList.CloseOfCashRegisterDayPaymentListRow.Add(vCloseOfCashRegisterDayPaymentListRow)
			EndDo;
		EndIf;
		
		Return vRetXDTO;
		
	Except
		vError = ErrorDescription();
		WriteLogEvent(NStr("en = 'Runtime Error'; ru = 'ИнтерфейсСБухгалтерией.Ошибка получения списка платежей по сменам'"), EventLogLevel.Error, 
		, , NStr("en='Runtime Error: '; ru='Ошибка выполнения: '") +vError);
		vRetXDTO.ErrorDescription = vError;
		Return  vRetXDTO;
	EndTry;
	
EndFunction   //cmGetCloseOfCashRegisterDay

// -----------------------------------------------------------------------------
Function cmWriteCloseOfCashRegisterDayPaymentListExtCode(pGUID, pExternalCode, pAccountingCustomerCode, pAccountingCurrencyCode, pPaymentMethodCode, pIsPayment = False) Export 
	
	WriteLogEvent(NStr("en = 'AccountingInterfaces.WritePaymentExternalCode'; ru = 'ИнтерфейсСБухгалтерией.Записать соответствие платежа, входящие параметры'; de = 'AccountingInterfaces.WritePaymentExternalCode'"), EventLogLevel.Information, , , 
	"GUID закрытия смены: "+ pGUID + ", " 
	+Chars.LF+"GUID платежа: " + TrimR(pExternalCode) + ", " 
	+Chars.LF+"Код контрагента: "+ TrimR(pAccountingCustomerCode) + ", "
	+Chars.LF+"Код валюты: "+ TrimR(pAccountingCurrencyCode) + ", " 
	+Chars.LF+"Код способа оплаты: "+ TrimR(pPaymentMethodCode));
	
	vCustomer = Catalogs.Customers.FindByCode(TrimAll(pAccountingCustomerCode));
	vCurr = Catalogs.Currencies.FindByCode(TrimAll(pAccountingCurrencyCode));
	vPaymentMethod = Catalogs.PaymentMethods.FindByCode(TrimAll(pPaymentMethodCode));
	
	vError = "";
	
	vCCRD = Documents.CloseOfCashRegisterDay.GetRef(New UUID(TrimAll(pGUID)));
	
	
	If vCCRD.IsEmpty() Then
		vError = NStr("en = 'According to the document closing cash change input parameters can not be found!'; ru = 'По входящим параметрам документ закрытие кассовой смены не найден!'; de = 'Nach dem Schließen des Dokuments Geldwechsel kann Eingabeparameter nicht gefunden werden!'");
		
		WriteLogEvent(NStr("en = 'AccountingInterfaces.WritePaymentExternalCode'; ru = 'ИнтерфейсСБухгалтерией.Записать соответствие платежа'; de = 'AccountingInterfaces.WritePaymentExternalCode'"), 
		EventLogLevel.Error, , ,vError); 
		
	Else
		vObj = vCCRD.GetObject();
		vFilter = New Structure("Currency,PaymentMethod,Customer, IsPayment",vCurr,vPaymentMethod,vCustomer, pIsPayment);
		vFilterRows = vObj.AccountingTotals.FindRows(vFilter);
		If vFilterRows.Count()>0 Then
			// Update ExternalCode
			vFilterRows[0].ExternalCode = pExternalCode;
			vObj.Write();
		Else
			vError = NStr("en = 'Compliance is not recorded because the corresponding row is not found'; ru = 'Соответствие не записано, т.к. не найдена соответствующая строка'; de = 'Die Einhaltung wird nicht aufgezeichnet, da wird die entsprechende Zeile nicht gefunden'");
			
			WriteLogEvent(NStr("en = 'AccountingInterfaces.WritePaymentExternalCode'; ru = 'ИнтерфейсСБухгалтерией.Записать соответствие платежа'; de = 'AccountingInterfaces.WritePaymentExternalCode'"), 
			EventLogLevel.Error, , ,vError); 
		EndIf;	
	EndIf;
	Return vError;
EndFunction	

// -----------------------------------------------------------------------------
Function cmWriteCloseOfCashRegisterDayExtCode(pGUID, pExternalCode) Export 
	
	WriteLogEvent(NStr("en = 'AccountingInterfaces.WritePaymentExternalCode'; ru = 'ИнтерфейсСБухгалтерией.Записать соответствие платежа, входящие параметры'; de = 'AccountingInterfaces.WritePaymentExternalCode'"), EventLogLevel.Information, , , 
	"GUID закрытия смены: "+ pGUID + ", " +Chars.LF +"GUID документа БУХ: " + TrimR(pExternalCode));
	
	vError = "";
	
	vCCRD = Documents.CloseOfCashRegisterDay.GetRef(New UUID(TrimAll(pGUID)));
	
	
	If vCCRD.IsEmpty() Then
		vError = NStr("en = 'According to the document closing cash change input parameters can not be found!'; ru = 'По входящим параметрам документ закрытие кассовой смены не найден!'; de = 'Nach dem Schließen des Dokuments Geldwechsel kann Eingabeparameter nicht gefunden werden!'");
		
		WriteLogEvent(NStr("en = 'AccountingInterfaces.WritePaymentExternalCode'; ru = 'ИнтерфейсСБухгалтерией.Записать соответствие платежа'; de = 'AccountingInterfaces.WritePaymentExternalCode'"), 
		EventLogLevel.Error, , ,vError); 
		
	Else
		Try
			vObj = vCCRD.GetObject();
			vObj.ExternalCode = pExternalCode;
			vObj.Write();
		Except
			vError = ErrorDescription();
			
			WriteLogEvent(NStr("en = 'AccountingInterfaces.WritePaymentExternalCode'; 
								|ru = 'ИнтерфейсСБухгалтерией.Записать соответствие платежа'; 
								|de = 'AccountingInterfaces.WritePaymentExternalCode'"), 
						EventLogLevel.Error, , ,vError); 
		EndTry;
	EndIf;
	Return vError;
EndFunction	

// -----------------------------------------------------------------------------
Function cmGetGuestGroupDescription(pGuestGroup, pIncludeClient = False) Export
	If Not ValueIsFilled(pGuestGroup) Then
		Return "";
	EndIf;
	Return ""+Format(pGuestGroup.Code, "ND=12; NFD=; NG=") + ?(pIncludeClient," " + pGuestGroup.Client, "") +" ("+pGuestGroup.GuestsCheckedIn+NStr("en = ' pers.) '; ru = ' чел.) '; de = ' pers.) '") + cmShortPeriodPresentation(pGuestGroup.CheckInDate, pGuestGroup.CheckOutDate);
EndFunction

// -----------------------------------------------------------------------------
Function cmShortPeriodPresentation(pDateFrom,pDateTo) Export
	If Not ValueIsFilled(pDateFrom) Then
		Return NStr("en = 'to '; ru = 'по '; de = 'bis '") + pDateTo;
	EndIf;
	If Not ValueIsFilled(pDateTo) Then
		Return NStr("en = 'from '; ru = 'c '; de = 'von '") + pDateFrom;
	EndIf;
	If BegOfMonth(pDateFrom) = BegOfMonth(pDateTo) Then
		Return "" + Day(pDateFrom) + " - " + Format(pDateTo, "DF='dd MMMyy'");
	ElsIf BegOfYear(pDateFrom) = BegOfYear(pDateTo) Then
		Return "" + Format(pDateFrom, "DF='dd MMM'") + " - " + Format(pDateTo, "DF='dd MMMyy'");
	Else
		Return PeriodPresentation(pDateFrom, pDateTo, "DF='dd MMMyy'");
	Endif;
EndFunction

// -----------------------------------------------------------------------------
Function cmZPOS(pPOSCode, pDateTime, pSum, pCurrencyCode, pHotelCode, pExternalSystemCode) Export
	WriteLogEvent(NStr("en='Close POS shift'; de='Close POS shift'; ru='Закрыть смену POS'"), EventLogLevel.Information, , , 
	              NStr("en='External system code: '; de='External system code: '; ru='Код внешней системы: '") + pExternalSystemCode + Chars.LF + 
	              NStr("en='Hotel code: '; de='Hotel code: '; ru='Код гостиницы: '") + pHotelCode + Chars.LF + 
	              NStr("en='POS code: '; de='POS code: '; ru='Код POS: '") + pPOSCode + Chars.LF + 
	              NStr("en='Shift close date: '; de='Shift close date: '; ru='Дата закрытия смены: '") + pDateTime + Chars.LF + 
	              NStr("en='Currency code: '; de='Currency code: '; ru='Код валюты: '") + pCurrencyCode + Chars.LF + 
	              NStr("en='POS shift total amount: '; de='POS shift total amount: '; ru='Итог по смене: '") + Format(pSum, "ND=17; NFD=2; NZ="));
	// Initialize error description
	vErrorDescription = "";
	
	// Try to find hotel by name or code
	vHotel = SessionParameters.CurrentHotel;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
	EndIf;
	
	// Try to find cash register by code
	vCashRegister = Undefined;
	If Not IsBlankString(pPOSCode) Then
		vCashRegister = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "CashRegisters", pPOSCode);
	EndIf;
	If Not ValueIsFilled(vCashRegister) Then
		Raise NStr("en='Failed to get POS cash register by code!'; ru='Ошибка получения ККМ по коду POS системы!' de='Fehler beim Abrufen der POS-Kasse per Code!'");
	EndIf;
	
	// Get currency by code
	vCurrency = Catalogs.Currencies.EmptyRef();
	If Not IsBlankString(pCurrencyCode) Then
		vCurrency = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Currencies", pCurrencyCode);
	EndIf;
	If pSum <> 0 And Not ValueIsFilled(vCurrency) Then
		Raise NStr("en='Failed to find shift total amount currency by code!'; ru='Ошибка получения валюты итога смены по коду!' de='Der Gesamtbetrag der POS-Kasse konnte nicht nach Code gefunden werden!'");
	EndIf;
	
	// Do shift close
	vCloseOfCRD = Documents.CloseOfCashRegisterDay.CreateDocument();
	vCloseOfCRD.Company = vCashRegister.Owner;
	vCloseOfCRD.pmFillAttributesWithDefaultValues();
	vCloseOfCRD.Date = ?(ValueIsFilled(pDateTime), pDateTime, CurrentSessionDate());
	If Year(vCloseOfCRD.Date) <> Year(CurrentSessionDate()) Then
		vCloseOfCRD.SetNewNumber();
	EndIf;
	vCloseOfCRD.AccountingDate = ?(ValueIsFilled(vHotel), vHotel.AccountingDate, '00010101');
	vCloseOfCRD.CashRegister = vCashRegister;
	vCloseOfCRD.ZReportType = vCashRegister.ZReportType;
	If Not ValueIsFilled(vCloseOfCRD.ZReportType) Then
		vCloseOfCRD.ZReportType = Enums.ZReportTypes.Transactions;
	EndIf;
	vDateFrom = vCloseOfCRD.pmCalculateDateFrom(vCloseOfCRD.Date);
	If Not ValueIsFilled(vDateFrom) Then
		vCloseOfCRD.DateFrom = '20000101';
	Else
		vCloseOfCRD.DateFrom = vDateFrom;
	EndIf;
	If BegOfDay(vCloseOfCRD.DateFrom) = BegOfDay(vCloseOfCRD.Date) Then
		vCloseOfCRD.Remarks = Format(vCloseOfCRD.DateFrom, "DF=dd.MM.yyyy") + NStr("en=' - Load orders from POS'; ru=' - Загрузка заказов из POS'; de=' - Load orders from POS'");
	Else
		vCloseOfCRD.Remarks = Format(vCloseOfCRD.DateFrom, "DF=dd.MM.yyyy") + " - " + Format(vCloseOfCRD.Date, "DF=dd.MM.yyyy") + NStr("en=' - Load orders from POS'; ru=' - Загрузка заказов из POS'; de=' - Load orders from POS'");
	EndIf;
	vCloseOfCRD.Write(DocumentWriteMode.Posting);
	
	// Check shift amount
	If ValueIsFilled(vHotel) And pSum <> 0 And Not IsBlankString(pCurrencyCode) Then
		vShiftAmount = 0;
		For Each vTRow In vCloseOfCRD.AccountingTotals Do
			vShiftAmount = vShiftAmount + cmConvertCurrencies(vTRow.Sum, vTRow.Currency, , vCurrency, , vCloseOfCRD.Date, vHotel);
		EndDo;
		If vShiftAmount <> pSum Then
			Return NStr("en='Total shift amount in PMS differs from POS amount! '; ru='Итог по смене в PMS отличается от итога смены в POS! '; de='Der Gesamtverschiebungsbetrag in PMS unterscheidet sich vom POS-Betrag! '") + "PMS: " + cmFormatSum(vShiftAmount, vCurrency) + ", POS: " + cmFormatSum(pSum, vCurrency);
		EndIf;
	EndIf;
	
	// OK
	Return "";
EndFunction // cmZPOS

// -----------------------------------------------------------------------------
// check if the shift number has changed
// if it has changed that post previous shift close and write current shift number as not posted document
// pHotel - Ref to the Hotel catalog
// pExternalSystemCode - the code of the external system used for mapping attributes
// pShiftDate - accounting date of the oreder
// pShitNumber - string with shift number of current oreder
// pOrderDate - date and time of the order
Procedure cmCheckAndClosePOSShift(pPOSCode, pShiftDate, pShiftNumber, pOrderDate, pHotelCode, pExternalSystemCode) Export
	WriteLogEvent(NStr("en='Check and close POS shift'; de='Check and close POS shift'; ru='Проверка и закрытие смены POS'"), EventLogLevel.Information, , , 
	              NStr("en='External system code: '; de='External system code: '; ru='Код внешней системы: '") + pExternalSystemCode + Chars.LF + 
	              NStr("en='Hotel code: '; de='Hotel code: '; ru='Код гостиницы: '") + pHotelCode + Chars.LF + 
	              NStr("en='POS code: '; de='POS code: '; ru='Код POS: '") + pPOSCode + Chars.LF + 
	              NStr("en='Current shift date: '; de='Current shift date: '; ru='Дата текущей смены: '") + pShiftDate + Chars.LF + 
	              NStr("en='Current shift number: '; de='Current shift number: '; ru='Номер текущей смены: '") + pShiftNumber + Chars.LF + 
	              NStr("en='Current order time: '; de='Current order time: '; ru='Время закрытия заказа: '") + pOrderDate);
	// Try to find hotel by name or code
	vHotel = SessionParameters.CurrentHotel;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		Raise NStr("en='Failed to get hotel by code!'; ru='Ошибка определения гостиницы!' de='Hoteldefinitionsfehler!'");
	EndIf;
	
	// Try to find cash register by code
	vCashRegister = Undefined;
	If Not IsBlankString(pPOSCode) Then
		vCashRegister = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "CashRegisters", pPOSCode);
	EndIf;
	If Not ValueIsFilled(vCashRegister) Then
		Raise NStr("en='Failed to get POS cash register by code!'; ru='Ошибка получения ККМ по коду POS системы!' de='Fehler beim Abrufen der POS-Kasse per Code!'");
	ElsIf vCashRegister.AutoCloseCashRegisterDay Then
		Return;
	EndIf;
	If Not ValueIsFilled(pShiftDate) Then
		Raise NStr("en='POS shift date is empty!'; ru='Дата смены не указана!' de='Das POS-Schichtdatum ist leer!'");
	EndIf;
	If IsBlankString(pShiftNumber) Then
		Raise NStr("en='POS shift number is empty!'; ru='Номер смены не указан!' de='Das POS-Schichtnummer ist leer!'");
	EndIf;
	vTimestamp = ?(ValueIsFilled(pOrderDate), pOrderDate + 2, CurrentSessionDate());
	
	// Try to find close of shift document for given shift date and number
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	CloseOfCashRegisterDay.Ref AS Ref,
	|	CloseOfCashRegisterDay.Date AS Date,
	|	CloseOfCashRegisterDay.Posted AS Posted
	|FROM
	|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
	|WHERE
	|	CloseOfCashRegisterDay.CashRegister = &qCashRegister
	|	AND CloseOfCashRegisterDay.AccountingDate = &qAccountingDate
	|	AND CloseOfCashRegisterDay.ExternalCode = &qExternalCode
	|	AND CloseOfCashRegisterDay.Date <= &qTimestamp
	|
	|ORDER BY
	|	CloseOfCashRegisterDay.Date DESC";
	vQry.SetParameter("qCashRegister", vCashRegister);
	vQry.SetParameter("qAccountingDate", BegOfDay(pShiftDate));
	vQry.SetParameter("qExternalCode", TrimAll(pShiftNumber));
	vQry.SetParameter("qTimestamp", vTimestamp);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() = 0 Then
		// New shift is found. We have to close previous shift and open a new one
		vPrevShiftQry = New Query();
		vPrevShiftQry.Text = 
		"SELECT TOP 1
		|	CloseOfCashRegisterDay.Ref AS Ref,
		|	CloseOfCashRegisterDay.Date AS Date,
		|	CloseOfCashRegisterDay.Posted AS Posted
		|FROM
		|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
		|WHERE
		|	CloseOfCashRegisterDay.CashRegister = &qCashRegister
		|	AND CloseOfCashRegisterDay.AccountingDate <= &qAccountingDate
		|	AND CloseOfCashRegisterDay.Date <= &qTimestamp
		|	AND NOT CloseOfCashRegisterDay.Posted 
		|
		|ORDER BY
		|	CloseOfCashRegisterDay.Date DESC";
		vPrevShiftQry.SetParameter("qCashRegister", vCashRegister);
		vPrevShiftQry.SetParameter("qAccountingDate", BegOfDay(pShiftDate));
		vPrevShiftQry.SetParameter("qTimestamp", vTimestamp);
		vPrevShiftDocs = vQry.Execute().Unload();
		If vPrevShiftDocs.Count() > 0 Then
			vPrevShiftDoc = vPrevShiftDocs.Get(0).Ref;
			vPrevShiftDoc.Write(DocumentWriteMode.Posting);
			// Open new shift
			vNewShiftDoc = Documents.CloseOfCashRegisterDay.CreateDocument();
			vNewShiftDoc.SetTime(AutoTimeMode.DontUse);
			vNewShiftDoc.DateFrom = vPrevShiftDoc.Date;
			vNewShiftDoc.Date = vTimestamp;
			vNewShiftDoc.AccountingDate = BegOfDay(pShiftDate);
			vNewShiftDoc.Author = SessionParameters.CurrentUser;
			vNewShiftDoc.Company = vCashRegister.Owner;
			vNewShiftDoc.CashRegister = vCashRegister;
			vNewShiftDoc.ExternalCode = TrimAll(pShiftNumber);
			vNewShiftDoc.ZReportType = vCashRegister.ZReportType;
			vNewShiftDoc.Remarks = pExternalSystemCode + " - " + "POS: " + pPOSCode + " - " + Format(pShiftDate, "DF=dd.MM.yyyy") + " N " + TrimAll(pShiftNumber);
			vNewShiftDoc.Write(DocumentWriteMode.Write);
		EndIf;
	Else
		// Update shift date to the last closed order date
		vDocsRow = vDocs.Get(0);
		If vDocsRow.Date < vTimestamp And Not vDocsRow.Posted Then
			vShiftDoc = vDocsRow.Ref.GetObject();
			vShiftDoc.Date = vTimestamp;
			vShiftDoc.Write(DocumentWriteMode.Write);
		EndIf;
	EndIf;		
EndProcedure // cmCheckAndClosePOSShift

// -----------------------------------------------------------------------------
Function cmWritePOSOrder(pClient, pOrder, pSource) Export
	pExternalSystemCode = pSource.ExternalSystemCode;
	pHotelCode = "";
	
	vClientXML 	= cmGetXMLStringFromXDTO(pClient);
	vOrderXML 	= cmGetXMLStringFromXDTO(pOrder);
	vSourceXML 	= cmGetXMLStringFromXDTO(pSource);
	vInputParameters = "ClientXDTO: " + Chars.LF + vClientXML + Chars.LF + "OrderXDTO: " + Chars.LF + vOrderXML + Chars.LF + "SourceXDTO: " + Chars.LF + vSourceXML; 
	
	vWriteDebug = False;
	If Not IsBlankString(pExternalSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExternalSystemCode);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	vFuncLog = NStr("en='Write POS Order';ru='Записать заказ из POS';de='Write POS Order'");
	If vWriteDebug Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg, vInteraction.MaxLogLenght);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vInputParameters);
	EndIf;
    // If Interaction is not set OR the interaction is not active - stop the processing and return error
	
	// Initialize error description
	vErrorDescription = "";
	vSentSms = True;
	vPhone = "";
	
	vReplyType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ErrorDescriptionArray");
	vRetXDTO 			= XDTOFactory.Create(vReplyType);
	vRetXDTO.Error   	= "";
	vRetXDTO.SentSms 	= vSentSms;
	vRetXDTO.ClientPhone= vPhone;
	
	vExternalTransactionIsActive = True;
	Try
		If Not TransactionActive() Then
			vExternalTransactionIsActive = False;
			BeginTransaction(DataLockControlMode.Managed);
		EndIf;
		
		// Try to find hotel by name or code
		pHotelCode = pOrder.Get("Hotel");
		vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
		
		// POS code
		vPOSCode = pSource.Get("POS");
		
		// Order date
		vOrderTimestamp = CurrentSessionDate();
		// Find order to update. If not found create new
		vExtOrderID = TrimAll(pOrder.Get("OrderID"));
		If Not IsBlankString(vPOSCode) And Upper(pExternalSystemCode) = "LOGISOFT_POS" Then
			If cmIsNumber(vExtOrderID) Then
				vExtOrderID = vPOSCode + vExtOrderID;
			EndIf;
		EndIf;
		
		docOrder = GetOrderDoc(vExtOrderID, pExternalSystemCode);
		If ValueIsFilled(docOrder.Date) Then
			vOrderTimestamp = docOrder.Date;
		EndIf;
		vOrderDate = pOrder.Get("OrderDate");
		If vOrderDate = Undefined Then
			vOrderDate = CurrentSessionDate();
		EndIf;
		docOrder.ExternalCode = vExtOrderID;

		vDocDate = vOrderDate;
		
		If ValueIsFilled(vHotel.AccountingDate) And 
		  (Not ValueIsFilled(vHotel.NewAccountingDateCutOffTimeForPOS) Or 
		   ValueIsFilled(vHotel.NewAccountingDateCutOffTimeForPOS) And ('00010101' + (vDocDate - BegOfDay(vDocDate))) <= vHotel.NewAccountingDateCutOffTimeForPOS) Then
			If vDocDate > EndOfDay(vHotel.AccountingDate) Then
				vDocDate = EndOfDay(vHotel.AccountingDate);
			EndIf;
		EndIf;
		
		docOrder.Date = vDocDate; // Document date (when the POS order was closed)
		docOrder.OrderTime = vOrderDate; // Delivery time (usually in the future) when this order has to be delivered. Used in online services

		docOrder.Remarks = pOrder.Get("Remarks"); // ExtOrderID;
		
		// Payment data
		vPayment = pOrder.Get("Payment");
		If vPayment <> Undefined Then
			vPaymentMethods = vPayment.Get("OrderPaymentMethods");
		EndIf;
		
		// Create list of payments that was created for this order
		vPaymentsList = New ValueList();
		
		// Get payments bound to this order based on payment methods 
		If vPayment <> Undefined Then
			If vPaymentMethods <> Undefined Then
				vPM = 0;
				For Each vPaymentMethodStruct In vPaymentMethods.OrderPaymentMethod Do
					vPM = vPM + 1;
					vPaymentExtCode = TrimAll(vPaymentMethodStruct.PaymentExternalCode);
					If IsBlankString(vPaymentExtCode) Then
						If ValueIsFilled(vExtOrderID) Then
							vPaymentExtCode = TrimAll(vExtOrderID) + "/" + Format(vPM, "NFD=0; NZ=; NG=");
						ElsIf ValueIsFilled(vOrderTimestamp) Then
							vPaymentExtCode = Format(vOrderTimestamp, "DF=yyyy-MM-ddTHH:mm:ss") + "/" + Format(vPM, "NFD=0; NZ=; NG=");
						EndIf;
					ElsIf vPaymentExtCode = vExtOrderID Then
						vPaymentExtCode = vPaymentExtCode + "/1";
					EndIf;
					If Not IsBlankString(vPaymentExtCode) Then
						vPaymentRef = cmGetPaymentByExternalSystemCode(vHotel, vPaymentExtCode);
						If ValueIsFilled(vPaymentRef) Then
							If vPaymentsList.FindByValue(vPaymentRef) = Undefined Then
								vPaymentsList.Add(vPaymentRef);
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		vInt = 0;
		While vInt < 3 Do
			vInt = vInt + 1;
			
			// Build payment external code
			vPaymentExtCode = "";
			If ValueIsFilled(vExtOrderID) Then
				vPaymentExtCode = TrimAll(vExtOrderID) + "/" + Format(vInt, "NFD=0; NZ=; NG=");
			ElsIf ValueIsFilled(vOrderTimestamp) Then
				vPaymentExtCode = Format(vOrderTimestamp, "DF=yyyy-MM-ddTHH:mm:ss") + "/" + Format(vInt, "NFD=0; NZ=; NG=");
			EndIf;
			
			If Not IsBlankString(vPaymentExtCode) Then
				vPaymentRef = cmGetPaymentByExternalSystemCode(vHotel, vPaymentExtCode);
				If ValueIsFilled(vPaymentRef) Then
					If vPaymentsList.FindByValue(vPaymentRef) = Undefined Then
						vPaymentsList.Add(vPaymentRef);
					EndIf;
				EndIf;
			Else
				Break;
			EndIf;
		EndDo;
		
		// Order type
		vOrderTypeRef = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "OrderTypes", TrimAll(pOrder.Get("OrderType")));
		If Not ValueIsFilled(vOrderTypeRef) Then
			vOrderTypeRef = Catalogs.OrderTypes.RoomService;
		EndIf;
		docOrder.Type = vOrderTypeRef;
		
		// Check if order was canceled
		vOrderStatus = pOrder.Get("OrderStatus");
		vOrderStatusRef = GetOrderStatus(vOrderStatus, pExternalSystemCode, vHotel, docOrder.Type);
		docOrder.Status = vOrderStatusRef;
		If ValueIsFilled(docOrder.Ref) And ValueIsFilled(vOrderStatusRef) And vOrderStatusRef.isOrderCancel Then
			
			// Cancel order charge
			If ValueIsFilled(docOrder.Charge) Then
				vChargeObject = docOrder.Charge.GetObject();
				If Not vChargeObject.DeletionMark Then
					vChargeObject.SetDeletionMark(True);
				EndIf;
			EndIf;
			
			// Delete all payments bound to this order
			For Each vPaymentsListItem In vPaymentsList Do
				vPaymentRef = vPaymentsListItem.Value;
				If ValueIsFilled(vPaymentRef) Then
					vPaymentObj = vPaymentRef.GetObject();
					If Not vPaymentObj.DeletionMark Then
						vPaymentObj.SetDeletionMark(True);
					EndIf;
				EndIf;
			EndDo;
			
			// Update order
			docOrder.Write(DocumentWriteMode.Posting);
			
			vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
			If vWriteDebug Then
				vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , vExtraXML, vMsg, vInteraction.MaxLogLenght);
			Else
				// Write log event
				WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vExtraXML);
			EndIf;	

			// Return success
			Return vRetXDTO;
		EndIf;
		
		// Order payment method
		docOrder.OrderPaymentType = Enums.OrderPaymentType.Room;
		If vPayment <> Undefined Then
			If vPaymentMethods <> Undefined Then
				For Each vPaymentMethodStruct In vPaymentMethods.OrderPaymentMethod Do
					docOrder.OrderPaymentType = Enums.OrderPaymentType.Cash;
					Break;
				EndDo;
			EndIf;
		EndIf;
		
		// Get service to be charged by service code or hotel
		vService = Catalogs.Services.EmptyRef();
		
		// 1. get service according to POS code. Different POS can be matched for to different services
		If Not IsBlankString(vPOSCode) Then
			vService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", TrimAll(vPOSCode));
		EndIf;
		
		// 2. in case mapping to POS code is not set use mapping to the Service code
		pServiceCode = pOrder.Get("Service");
		
		If Not ValueIsFilled(vService) and pServiceCode <> Undefined Then
			vService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", TrimAll(pServiceCode), True);
		EndIf;
		
		// 3. If service not found use mapping to Order type
		If Not ValueIsFilled(vService) Then
			// try to get Service mapping for OrderType
			vService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", TrimAll(pOrder.Get("OrderType")));
		EndIf;		
		
		// 4. no mappings at all use constant from hotel settings
		If Not ValueIsFilled(vService) and ValueIsFilled(vHotel) Then
			vService = vHotel.CateringService;
		EndIf;		
		If Not ValueIsFilled(vService) Then
			vErrorDescription = NStr("en = 'Service is not set!'; de = 'Die Dienstleistung konnte nicht bestimmt werden!'; ru = 'Не удалось определить услугу!'");
			
			vSentSms = False;
			
			vRetXDTO.Error = vErrorDescription;
			vRetXDTO.SentSMS = False;
			
			vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
			If vWriteDebug Then
				vMsg =  NStr("en = 'End of processing'; de = 'Ende des Ausführung'; ru = 'Конец выполнения'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vExtraXML, vErrorDescription, vInteraction.MaxLogLenght);
			Else
				// Write log event
				WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vExtraXML);
			EndIf;	

			Return vRetXDTO;
		EndIf;
		
		// Get POS cash register
		If vPOSCode <> Undefined And Not IsBlankString(vPOSCode) Then
			vCashRegister = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "CashRegisters", TrimAll(vPOSCode));
			If ValueIsFilled(vCashRegister) Then
				docOrder.CashRegister = vCashRegister;
			EndIf;
		EndIf;
		
		// Get input parameters and find guest folio
		vCard = "";
		vFolioNumber = "";
		vRoom = "";
		vClientCode = "";
		
		// Find order parent doc or folio to charge to
		// 1. If client card is filled - get client and folio by card id
		// 2. If folio number is filled - get folio
		// 3. if room is filled - get active accomodation for the room and use client code if there are more than one
		// 4. clientID - is used for "my folio" service. ID generated on check in can be used to write order from external POS system
		// 5. If no ID parameter is set is used to write statistics and expected that Order total amount is equal to payments amount.
		vCard = pClient.Get("Card");
		vFolioNumber = pClient.Get("FolioNumber");
		vRoom = pClient.Get("Room");
		vClientCode = pClient.Get("ClientID");
		
		vFolioData = Undefined;
		vRoomRef = Undefined;
		
		If Not IsBlankString(vCard) Then
			vRemarks = pOrder.Get("Remarks");
			vFolioData = GetCardFolio(vCard, vService, pExternalSystemCode, vRemarks);
		ElsIf Not IsBlankString(vFolioNumber) Then
			vFolioData = GetFolio(vFolioNumber, vHotel);
			If Not IsBlankString(vRoom) Then
				// Convert room code to room ref
				vRoomRef = cmGetRoomByCode(vRoom, vHotel, pExternalSystemCode);
			EndIf;
		ElsIf Not IsBlankString(vRoom) Then
			// Convert room code to room ref
			vRoomRef = cmGetRoomByCode(vRoom, vHotel, pExternalSystemCode);
			If ValueIsFilled(vRoomRef) Then
				vRoom = TrimAll(vRoomRef.Description);
			EndIf;
			vFolioData = GetFolioByRoom(vRoom, vClientCode, vService, vHotel, vOrderDate);
		ElsIf Not IsBlankString(vClientCode) Then
			vFolioData = GetFolioByClientId(vClientCode, vService, vHotel, vOrderDate);
		ElsIf IsBlankString(vCard) AND IsBlankString(vFolioNumber) And IsBlankString(vRoom) And IsBlankString(vClientCode) Then
			// This is a case when order is fully paied on the external POS and has to loaded for the statistics
			// it's expected that Order sum is equal to the payments sum but the interfaces does not control it yet.
			vFolioData = GetPOSFolio(vHotel, vInteraction, vOrderDate, vService, vPOSCode);
		EndIf;
		If Not IsBlankString(vFolioData.ErrorDescription) Then
			vRetXDTO.Error = vFolioData.ErrorDescription;
			vRetXDTO.SentSMS = False;
			vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
			If vWriteDebug Then
				vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vExtraXML, vFolioData.ErrorDescription, vInteraction.MaxLogLenght);
			Else
				// Write log event
				WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vExtraXML);
			EndIf;	

			Return vRetXDTO;
		EndIf;
		If vFolioData = Undefined Or Not ValueIsFilled(vFolioData.Folio) Then
			vErrorDescription = NStr("en='Folio not found!';ru='Фолио не найдено!';de='Folio nicht gefunden!'");
			vSentSms = False;
			
			vRetXDTO.Error = vErrorDescription;
			vRetXDTO.SentSMS = False;
			vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
			If vWriteDebug Then
				vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vExtraXML, vErrorDescription, vInteraction.MaxLogLenght);
			Else
				// Write log event
				WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vExtraXML);
			EndIf;	

			Return vRetXDTO;
		EndIf;
		
		// Fill order details
		docOrder.Folio = vFolioData.Folio;
		vFolioNumber = vFolioData.Folio.Number;
		
		docOrder.ParentDoc = vFolioData.ParentDoc;
		docOrder.Hotel = vHotel;
		
		docOrder.GuestGroup = vFolioData.Folio.GuestGroup;
		docOrder.Client = vFolioData.Client;
		
		If ValueIsFilled(docOrder.ParentDoc) Then
			If TypeOf(docOrder.ParentDoc) = Type("DocumentRef.Accommodation") Or
				TypeOf(docOrder.ParentDoc) = Type("DocumentRef.Reservation") Then
				If Not ValueIsFilled(docOrder.Room) Then
					docOrder.Room = docOrder.ParentDoc.Room;
				EndIf;
			EndIf;
			If TypeOf(docOrder.ParentDoc) <> Type("DocumentRef.Folio") Then
				docOrder.Phone = docOrder.ParentDoc.Phone;
			EndIf;
		EndIf;
		If ValueIsFilled(vRoomRef) Then
			docOrder.Room = vRoomRef;
		EndIf;
		If ValueIsFilled(docOrder.Client) Then
			docOrder.ClientType = docOrder.Client.ClientType;
			docOrder.Phone = docOrder.Client.Phone;
		EndIf;
		docOrder.GuestsQuantity = pOrder.Get("GuestsQuantity");
		
		vDepartment = pOrder.Get("Department");
		If vDepartment <> Undefined Then
			docOrder.Department = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Departments", pOrder.Department);	
		EndIf;
		
		// Services modificator
		vExtCodeType = "";
		If ValueIsFilled(docOrder.Folio) Then
			If docOrder.Folio.IsComplimentary Then
				vExtCodeType = "/FC";
			ElsIf docOrder.Folio.IsHouseUse Then
				vExtCodeType = "/HU";
			EndIf;
		EndIf;
		If IsBlankString(vExtCodeType) Then
			vOrderParentDoc = docOrder.ParentDoc;
			If ValueIsFilled(vOrderParentDoc) And (TypeOf(vOrderParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vOrderParentDoc) = Type("DocumentRef.Reservation")) Then
				If ValueIsFilled(vOrderParentDoc.ServicePackage) Then
					vSP = vOrderParentDoc.ServicePackage;
					If vSP.IsAI Then
						vExtCodeType = "/" + TrimAll(vSP.Code);
					ElsIf vSP.IsFC Then
						vExtCodeType = "/FC";
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		// Try to get modified service if modificator is not empty
		If Not IsBlankString(pServiceCode) And Not IsBlankString(vExtCodeType) Then
			vNewService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", TrimAll(pServiceCode) + vExtCodeType);
			If ValueIsFilled(vNewService) Then
				vService = vNewService;
			EndIf;
		EndIf;
		
		docOrder.Service = vService;
		docOrder.Unit = vService.Unit;
		vQty = pOrder.Get("Quantity");
		If vQty = Undefined Or vQty = 0 Then
			docOrder.Quantity = 1;
		Else
			docOrder.Quantity = vQty;
		EndIf;
		docOrder.Sum = pOrder.Sum;
		docOrder.Price = Round(docOrder.Sum / docOrder.Quantity, 2);
			
		// Get currency by code
		pCurrencyCode = pOrder.Get("Currency");
		vCurrency = Catalogs.Currencies.EmptyRef();
		If Not IsBlankString(pCurrencyCode) Then
			vCurrency = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Currencies", pCurrencyCode);
		EndIf;
		If Not ValueIsFilled(vCurrency) Then
			vCurrency = docOrder.Folio.FolioCurrency;	
		EndIf;
		docOrder.Currency = vCurrency;
		vRemarks = pOrder.Get("Remarks");
		If vRemarks <> Undefined And Not IsBlankString(TrimAll(vRemarks)) Then
			If IsBlankString(docOrder.Remarks) Then
				docOrder.Remarks = vRemarks;
			Else
				If lower(pExternalSystemCode) = "r_keeper" Or 
				   lower(pExternalSystemCode) = "r-keeper" Or 
				   lower(pExternalSystemCode) = "rkeeper" Or 
				   lower(pExternalSystemCode) = "spa" Then
					docOrder.Remarks = vRemarks;
				Else
					If StrFind(TrimAll(docOrder.Remarks), vRemarks) = 0 Then
						docOrder.Remarks = TrimAll(docOrder.Remarks) + Chars.LF + vRemarks;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		// Order items
		docOrder.Items.Clear();
		For Each OrderItem In pOrder.OrderItems.OrderItem Do
			item = docOrder.Items.Add();
			vItemExtCode = TrimAll(pServiceCode) + "/" + TrimAll(OrderItem.Service);
			itemService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", vItemExtCode + vExtCodeType);
			If Not ValueIsFilled(itemService) And Not IsBlankString(vExtCodeType) Then
				itemService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", vItemExtCode);
			EndIf;
			If Not ValueIsFilled(itemService) Then
				itemService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", TrimAll(OrderItem.Service));
			EndIf;
			item.Item = GetOrderItem(OrderItem, itemService, vHotel);
			item.Price = OrderItem.Price; 
			item.Quantity = OrderItem.Quantity;
			item.Service = itemService;
			item.Sum = OrderItem.Sum;
			
			vOrderItemMarkingCode = OrderItem.Get("MarkingCode");
			If vOrderItemMarkingCode <> Undefined Then
				item.MarkingCode = TrimAll(vOrderItemMarkingCode);
			Else
				item.MarkingCode = "";
			EndIf;
		EndDo;
		
		// If it's transfer - fill transfer details
		vTransfer = pOrder.Get("Transfer");
		If pOrder.Transfer <> Undefined Then
			docOrder.PickupFrom = ?(IsBlankString(vTransfer.PickupFrom), TrimAll(vHotel), TrimAll(vTransfer.PickupFrom));
			docOrder.Destination = ?(IsBlankString(vTransfer.Destination), TrimAll(vHotel), TrimAll(vTransfer.Destination));
			docOrder.TransferType = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "TransferTypes", TrimAll(vTransfer.CarType));
			docOrder.ChildSeatsNumber = vTransfer.ChildSeatsNumber;
			docOrder.GuestsQuantity = vTransfer.PassengersNumber;
			If docOrder.PickupFrom = TrimAll(vHotel) Then
				docOrder.RouteType = Enums.RouteType.Departure;
			ElsIf docOrder.Destination = TrimAll(vHotel) Then
				docOrder.RouteType = Enums.RouteType.Arrive;
			Else
				docOrder.RouteType = Enums.RouteType.Route;
			EndIf;
		EndIf;
		
		// Save order
		If docOrder.DeletionMark Then
			docOrder.DeletionMark = False;
		EndIf;
		docOrder.Write(DocumentWriteMode.Posting);
		
		vRetXDTO.ChargeNumber = XMLString(docOrder.Number);
		
		// Save order external code
		If Not IsBlankString(vExtOrderID) Then
			vEOCMgr = InformationRegisters.ExternalOrderCodes.CreateRecordManager();
			vEOCMgr.Order = docOrder.Ref;
			vEOCMgr.ExternalSystemCode = pExternalSystemCode;
			vEOCMgr.ExternalOrderCode = vExtOrderID;
			vEOCMgr.Write(True);
		EndIf;
		
		// Check if payment data was specified
		vInt = 0;
		If vPayment <> Undefined Then
			vPaymentRemarks = TrimAll(vPayment.PaymentRemarks);
			If vPaymentMethods <> Undefined Then
				// Write payment for each payment method used to pay for the order
				For Each vPaymentMethodStruct In vPaymentMethods.OrderPaymentMethod Do
					vInt = vInt + 1;
					
					// Build payment external code
					vPaymentExtCode = TrimAll(vPaymentMethodStruct.PaymentExternalCode);
					If IsBlankString(vPaymentExtCode) Then
						If ValueIsFilled(vExtOrderID) Then
							vPaymentExtCode = TrimAll(vExtOrderID) + "/" + Format(vInt, "NFD=0; NZ=; NG=");
						ElsIf ValueIsFilled(vOrderDate) Then
							vPaymentExtCode = Format(vOrderDate, "DF=yyyy-MM-ddTHH:mm:ss") + "/" + Format(vInt, "NFD=0; NZ=; NG=");
						EndIf;
					ElsIf vPaymentExtCode = vExtOrderID Then
						vPaymentExtCode = vPaymentExtCode + "/1";
					EndIf;
					If vPaymentMethodStruct.Sum >= 0 Then
						// Call API
						vPaymentError = cmWritePaymentExternalFOSystem(pHotelCode, ?(ValueIsFilled(docOrder.Client), TrimAll(docOrder.Client.Code), ""), 
						                                               (vOrderTimestamp + 1), pExternalSystemCode, 
						                                               vCard, vFolioNumber, vRoom, vPaymentMethodStruct.PaymentMethod, 
																	   vPaymentMethodStruct.Currency, vPaymentMethodStruct.Sum, vPaymentRemarks,  
						                                               vPaymentExtCode, "XDTO", vPaymentMethodStruct.PaymentSection, vPOSCode, vExtOrderID, vDocDate, docOrder.Ref);
					
					Else
						vPaymentError = cmWriteReturnExternalFOSystem(pHotelCode, ?(ValueIsFilled(docOrder.Client), TrimAll(docOrder.Client.Code), ""), 
						                                               (vOrderTimestamp + 1), pExternalSystemCode, 
						                                               vCard, vFolioNumber, vRoom, vPaymentMethodStruct.PaymentMethod, 
																	   vPaymentMethodStruct.Currency, -vPaymentMethodStruct.Sum, vPaymentRemarks,  
						                                               vPaymentExtCode, "XDTO", vPaymentMethodStruct.PaymentSection, vPOSCode, vExtOrderID, vDocDate, docOrder.Ref);
																	   
					EndIf;
					If Not IsBlankString(vPaymentError) Then
						If vWriteDebug Then
							vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , , vPaymentError, vInteraction.MaxLogLenght);
						Else
							// Write log event
							WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vPaymentError);
						EndIf;	

						Raise vPaymentError;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		// Delete old payments
		If vPaymentsList.Count() > vInt Then
			While vInt < vPaymentsList.Count() Do
				vInt = vInt + 1;
				
				// Build payment external code
				vPaymentExtCode = "";
				If ValueIsFilled(vExtOrderID) Then
					vPaymentExtCode = TrimAll(vExtOrderID) + "/" + Format(vInt, "NFD=0; NZ=; NG=");
				ElsIf ValueIsFilled(vOrderDate) Then
					vPaymentExtCode = Format(vOrderDate, "DF=yyyy-MM-ddTHH:mm:ss") + "/" + Format(vInt, "NFD=0; NZ=; NG=");
				EndIf;
				
				vPaymentRef = cmGetPaymentByExternalSystemCode(vHotel, vPaymentExtCode);
				If ValueIsFilled(vPaymentRef) Then
					vPaymentObj = vPaymentRef.GetObject();
					If Not vPaymentObj.DeletionMark Then
						vPaymentObj.SetDeletionMark(True);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		// Check order folio credit limit
		If ValueIsFilled(docOrder.Folio) And ValueIsFilled(vInteraction) And Not vInteraction.DoNotCheckFolioCreditLimitAtWritePOSOrders Then
			vFolio = docOrder.Folio;
			vLimit = 0;
			vBonusAmount = 0;
			vFolioObj = vFolio.GetObject();
			vBalance = vFolioObj.pmGetBalance('39991231235959', , Undefined, vLimit);
			vOrderSumInFolioCurrency = Round(cmConvertCurrencies(docOrder.Sum, docOrder.Currency, , vFolio.FolioCurrency, , docOrder.Date), 2);
			If vOrderSumInFolioCurrency <> 0 And vBalance > vFolio.CreditLimit And Not vHotel.NoCreditLimit Then
				vMsg = NStr("en='Sum of order amount " + cmFormatSum(vOrderSumInFolioCurrency, vFolio.FolioCurrency, "NZ=") + " and folio N " + vFolio.Number + " balance " + cmFormatSum((vBalance - vOrderSumInFolioCurrency), vFolio.FolioCurrency, "NZ=") + " is greater then folio credit limit " + cmFormatSum(vFolio.CreditLimit, vFolio.FolioCurrency, "NZ=") + "! Operation is canceled.'; 
				            |de='Summe des Bestellbetrags " + cmFormatSum(vOrderSumInFolioCurrency, vFolio.FolioCurrency, "NZ=") + " und Folio N " + vFolio.Number + " Restbetrag " + cmFormatSum((vBalance - vOrderSumInFolioCurrency), vFolio.FolioCurrency, "NZ=") + " ist größer als das Foliokreditlimit " + cmFormatSum(vFolio.CreditLimit, vFolio.FolioCurrency, "NZ=") + "! Vorgang wird abgebrochen.'; 
				            |ru='После начисления услуг заказа на сумму " + cmFormatSum(vOrderSumInFolioCurrency, vFolio.FolioCurrency, "NZ=") + " на фолио № " + vFolio.Number + " с балансом " + cmFormatSum((vBalance - vOrderSumInFolioCurrency), vFolio.FolioCurrency, "NZ=") + " долг на лицевом счете " + cmFormatSum(vBalance, vFolio.FolioCurrency, "NZ=") + " превысит установленную глубину кредита " + cmFormatSum(vFolio.CreditLimit, vFolio.FolioCurrency, "NZ=") + "! Операция прервана.'");
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg, vInteraction.MaxLogLenght);
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Warning, , vFolio, vMsg);
				EndIf;
				Raise vMsg;
			EndIf;
		EndIf;
		
		// Save order binary data to the order attachments
		If pOrder.TicketBinaryData <> Undefined And pOrder.TicketBinaryData.Size() > 0 Then
			vBinaryData = pOrder.TicketBinaryData;
			
			vFileName = TrimAll(pOrder.TicketFileName);
			vTicketFileExtension = TrimAll(pOrder.TicketFileExtension);
			If Not IsBlankString(vTicketFileExtension) Then
				vTicketFileExtension = lower(StrReplace(vTicketFileExtension, ".", ""));
			EndIf;
			vOrderDateStr = "";
			If pOrder.OrderDate <> Undefined Then
				vOrderDateStr = Format(pOrder.OrderDate, "DF=yyyy_MM_dd");
			EndIf;
			If IsBlankString(vFileName) Then
				vFileName = "Ticket_" + TrimAll(pOrder.Hotel) + "_" + TrimAll(pOrder.Service) + "_" + TrimAll(pOrder.OrderID) + "_" + vOrderDateStr;
			EndIf;
			If lower(Right(vFileName, StrLen(vTicketFileExtension))) <> vTicketFileExtension Then
				vFileName = vFileName + "." + vTicketFileExtension;
			EndIf;
			
			vCurrentDate = CurrentSessionDate();
			
			vRegMng = InformationRegisters.OrderAttachments.CreateRecordManager();
			vRegMng.Order = docOrder.Ref;
			vRegMng.Author = SessionParameters.CurrentUser;
			vRegMng.FileName = vFileName;
			vRegMng.FileLoadTime = vCurrentDate;
			vRegMng.FileLastChangeTime = vCurrentDate;
			vRegMng.Period = vCurrentDate;
			vRegMng.ExtFile = New ValueStorage(vBinaryData);
			vRegMng.Write(True);
		EndIf;
		
		If Not vExternalTransactionIsActive Then
			CommitTransaction();
		EndIf;
	Except
		vErrorText = cmGetRootErrorDescription(ErrorInfo());
		
		If Not vExternalTransactionIsActive Then
			vRetXDTO.Error = vErrorText;

			If TransactionActive() Then
				Try
					RollbackTransaction();
				Except
				EndTry;
			EndIf;
		Else
			Raise vErrorText;
		EndIf;
	EndTry;

	// Log end of processing
	vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
	If vWriteDebug Then
		vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , vExtraXML, vMsg, vInteraction.MaxLogLenght);
	Else
		// Write log event
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vExtraXML);
	EndIf;	

	// Return result
	Return vRetXDTO;
EndFunction // cmWritePOSOrder

// --------------------------------------------------------------------------------
// is used for writing paied POS order exported form POS system for statistics
// create and use one folio for one POSCode for a date
// Input parameters:
// pHotel - Hotel Ref
// pInteraction - ref to the externalsystem interaction is user to link POS code and CashRegister ref
// pService - Service description is user to create a folio description
// pPOS - pos code is used to map to cash register
// Return: structure whith folio data which cam be used to write Order and its payments
Function GetPOSFolio(pHotel, pInteraction, pShiftdate, pService, pPOS) Export
	// Try to find folio by description. 
	// We will have one folio for all reciepts for one shift date and staion code from
	vFolioData = New Structure("Folio, ParentDoc, Client, ErrorDescription, SentSms");
	If ValueIsFilled(pShiftdate) Then
		strShiftDate = Format(BegOfDay(pShiftdate), "DF=dd.MM.yyyy");
	Else
		If ValueIsFilled(pHotel) And ValueIsFilled(pHotel.AccountingDate) Then
			strShiftDate = Format(pHotel.AccountingDate, "DF=dd.MM.yyyy");
		Else
			strShiftDate = Format(BegOfDay(CurrentSessionDate()), "DF=dd.MM.yyyy");
		EndIf;
	EndIf;
	
	vFolioDescription = strShiftDate + " - " + TrimAll(pInteraction) + " (" + TrimAll(pService) + "/" + TrimAll(pPOS) + ")";
	
	vQ = New Query("SELECT
	               |	Folio.Ref AS Ref,
	               |	Folio.Number AS FolioNumber
	               |FROM
	               |	Document.Folio AS Folio
	               |WHERE
	               |	Folio.Description = &qDescription
	               |	AND Folio.Hotel = &qHotel
	               |	AND NOT Folio.IsClosed
	               |	AND NOT Folio.DeletionMark");
	vQ.SetParameter("qDescription",vFolioDescription);
	vQ.SetParameter("qHotel",pHotel);
	
	qRes = vQ.Execute().Select();
	If qRes.Next() Then   
		vFolioData.Folio = qRes.Ref;
		Return vFolioData;
	Endif;
	
	// Folio not found  - create new one
	vCashRegister = cmGetObjectRefByExternalSystemCode(pHotel, "", "CashRegisters", pPOS, True, pInteraction, False);
	vCompany = pHotel.Company;
	
	If ValueIsFilled(vCashRegister) Then
		vCompany = vCashRegister.Owner;
	Endif;
	
	vFolioObj = Documents.Folio.CreateDocument();
	vFolioObj.pmFillAttributesWithDefaultValues();
	vFolioObj.Company = vCompany;
	vFolioObj.Date = CurrentSessionDate();
	vFolioObj.DateTimeFrom = BegOfDay(pShiftdate);
	vFolioObj.DateTimeTo = EndOfDay(pShiftdate);
	vFolioObj.Description = vFolioDescription;
	vFolioObj.Customer = cmGetObjectRefByExternalSystemCode(pHotel, "", "Customers", pPOS, False, pInteraction);
	If ValueIsFilled(vFolioObj.Customer) Then
		vFolioObj.Contract = vFolioObj.Customer.Contract;
	EndIf;
	vFolioObj.Write();
	vFolioData.Folio = vFolioObj.Ref;
	Return vFolioData;
EndFunction // GetPOSFolio

// -----------------------------------------------------------------------------
//  For the given card returns a stucture with folio, parentDoc od ErrorDescription in case of error
//
// Parameters:
//  pIdentifier			 - String	 - 
//  pService			 - String	 - 
//  pExternalSystemCode	 - String	 - 
//  pRemarks			 - String	 - 
// 
// Returns:
//  Structure - Folio data 
//
Function GetCardFolio(pIdentifier, pService,pExternalSystemCode, pRemarks = "") Export
	
	pErrorDescription = "";
	vFolioData = New Structure("Folio, ParentDoc, Client, ErrorDescription, SentSms");
	// Get card reference by card identifier
	vDiscountCard = Undefined;
	vCard = cmGetClientIdentificationCardById(pIdentifier);
	If Not ValueIsFilled(vCard) Then
		vDiscountCard = cmGetDiscountCardById(pIdentifier);
		If ValueIsFilled(vDiscountCard) And vDiscountCard.LoyaltyType = Enums.LoyaltyType.Bonuses Or vDiscountCard.LoyaltyType = Enums.LoyaltyType.Certificate Then
			// For payments by bonuses we need to create a folio
			vNewFolioObj = Documents.Folio.CreateDocument();
			vNewFolioObj.pmFillAttributesWithDefaultValues();
			vNewFolioObj.DateTimeFrom = BegOfDay(vNewFolioObj.Hotel.AccountingDate);
			vNewFolioObj.DateTimeTo = EndOfDay(vNewFolioObj.DateTimeFrom);
			vNewFolioObj.Remarks = TrimAll(pRemarks);
		 	vNewFolioObj.Write();
			
			vFolioData.Folio  = vNewFolioObj.Ref; 
			vFolioData.Client = vDiscountCard.Client; 
			vFolioData.ErrorDescription = ""; 
			vFolioData.SentSms = False;
			Return vFolioData;
		EndIf;
	EndIf;
	vFolio = Undefined;
	vEvent = "RestaurantInterfaces.WritePOSOrder";
	If Not ValueIsFilled(vCard) Then
		// Try to find discount card
		vDiscountCard = cmGetDiscountCardById(pIdentifier);
		If Not ValueIsFilled(vDiscountCard) Then
			pErrorDescription = NStr("en='Client identification card was not found!';ru='Не найдена карта клиента!';de='Kundenkarte nicht gefunden!'");
			WriteLogEvent(vEvent, EventLogLevel.Warning, , , pErrorDescription);
			vFolioData.ErrorDescription = pErrorDescription;
			vFolioData.SentSms = False;
			Return vFolioData;
		EndIf;
		vAccommodation = cmGetDiscountCardAccommodation(vDiscountCard);
		If Not ValueIsFilled(vAccommodation) Then
			If Not ValueIsFilled(vDiscountCard.Client) Then
				pErrorDescription = NStr("en='Client identification card was not found!';ru='Не найдена карта клиента!';de='Kundenkarte nicht gefunden!'");
				WriteLogEvent(vEvent, EventLogLevel.Warning, , , pErrorDescription);
				vFolioData.ErrorDescription = pErrorDescription;
				vFolioData.SentSms = False;
				Return vFolioData;
			EndIf;
			vAccommodation = cmGetClientAccommodation(vDiscountCard.Client);
			vFolioData.Client = vDiscountCard.Client;
		EndIf;
		If Not ValueIsFilled(vAccommodation) Then
			pErrorDescription = NStr("en='Client identification card was not found!';ru='Не найдена карта клиента!';de='Kundenkarte nicht gefunden!'");
			WriteLogEvent(vEvent, EventLogLevel.Warning, , , pErrorDescription);
			vFolioData.ErrorDescription = pErrorDescription;
			vFolioData.SentSms = False;
			Return vFolioData;
		EndIf;
		If vDiscountCard.IsBlocked Then
			pErrorDescription = NStr("en='Attempt to charge by the blocked card! Operation is canceled:';ru='Попытка выполнить начисление по заблокированной карте! Операция прервана:';de='Der Versuch, die Abgrenzung von einer gesperrten Karte durchführen! Die Operation ist abgebrochen:'") + " " + TrimAll(vDiscountCard.Remarks);
			WriteLogEvent(vEvent, EventLogLevel.Warning, , , pErrorDescription);
			vFolioData.ErrorDescription = pErrorDescription;
			vFolioData.SentSms = False;
			Return vFolioData;
		EndIf;
		vCard = New Structure("Hotel, ParentDoc, Folio, IdentificationCardType", vAccommodation.Hotel, vAccommodation, Documents.Folio.EmptyRef(), Catalogs.IdentificationCardTypes.EmptyRef());
	Else
		vFolioData.Client = vCard.Client;
		If ValueIsFilled(vCard.IdentificationCardType) And Not IsBlankString(vCard.IdentificationCardType.ExternalSystemsAllowed) And Not IsBlankString(pExternalSystemCode) Then
			If Find(TrimAll(vCard.IdentificationCardType.ExternalSystemsAllowed), TrimAll(pExternalSystemCode)) = 0 Then
				pErrorDescription = NStr("en='It is forbidden to use this card in ';ru='Использовать эту карту в ';de='Benutzen Sie diese Karte im '") + TrimAll(pExternalSystemCode) + NStr("en=' system!';ru=' запрещено!';de=' ist verboten!'");
				WriteLogEvent(vEvent, EventLogLevel.Warning, , , pErrorDescription);
				vFolioData.ErrorDescription = pErrorDescription;
				vFolioData.SentSms = False;
				Return vFolioData;
			EndIf;
		EndIf;
		If vCard.IsBlocked Then
			pErrorDescription = NStr("en='Attempt to charge by the blocked card! Operation is canceled:';ru='Попытка выполнить начисление по заблокированной карте! Операция прервана:';de='Der Versuch, die Abgrenzung von einer gesperrten Karte durchführen! Die Operation ist abgebrochen:'") + " " + TrimAll(vCard.BlockReason);
			WriteLogEvent(vEvent, EventLogLevel.Warning, , , pErrorDescription);
			vFolioData.ErrorDescription = pErrorDescription;
			vFolioData.SentSms = False;
			Return vFolioData;
		EndIf;
	EndIf;
	
	// Get folio by card
	vFolio = Documents.Folio.EmptyRef();
	vFolioData.ParentDoc = vCard.ParentDoc;
	If ValueIsFilled(vCard.IdentificationCardType) And vCard.IdentificationCardType.DoNotUseChargingRules Then
		vFolio = vCard.Folio;
	Else
		If ValueIsFilled(vCard.ParentDoc) Then
			vCardParentDoc = vCard.ParentDoc;
			vCardFolioIsInChargingRules = False;
			If TypeOf(vCardParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCardParentDoc) = Type("DocumentRef.Reservation") Then
				vChargingRules = vCardParentDoc.ChargingRules;
				If vChargingRules.Find(vCard.Folio, "ChargingFolio") <> Undefined Then
					vCardFolioIsInChargingRules = True;
				Else
					vCardParentDocGuestGroup = vCardParentDoc.GuestGroup;
					If ValueIsFilled(vCardParentDocGuestGroup) And vCardParentDocGuestGroup.ChargingRules.Count() > 0 Then
						vCardParentDocGuestGroupChargingRules = vCardParentDocGuestGroup.ChargingRules;
						If vCardParentDocGuestGroupChargingRules.Find(vCard.Folio, "ChargingFolio") <> Undefined Then
							vCardFolioIsInChargingRules = True;
						EndIf;
					EndIf;
				EndIf;
			ElsIf TypeOf(vCardParentDoc) = Type("DocumentRef.ResourceReservation") Then
				If vCard.Folio = vCardParentDoc.ChargingFolio Then
					vCardFolioIsInChargingRules = True;
				EndIf;
			EndIf;
			If vCardFolioIsInChargingRules Then
				vFolio = cmGetDocumentChargingFolioForService(vCardParentDoc, pService, CurrentSessionDate());
			Else
				vFolio = vCard.Folio;
			EndIf;
		Else
			vFolio = vCard.Folio;
		EndIf;
	EndIf;
	vFolioData.ErrorDescription = pErrorDescription;
	vFolioData.Folio = vFolio;
	Return vFolioData;
EndFunction

// -----------------------------------------------------------------------------
Function cmGetClientStats(pRef, pDBLink = "") Export
	// Init return struct
	vRet = New Structure("CurrentReservation,CurrentReservationRemarks,ReservationLink,GuestReservationLink, ReservationCheckInDate,ReservationCheckOutDate,ReservationStatus, Nights, Visits, AvgDepth, BonusesSumm, MemberLevel", );
	If Not ValueIsFilled(pRef) Then
		Return vRet;
	EndIf;
		
	// Get Next Reservation
	vResRef = Undefined;
	vQry = New Query;
	vQry.Text = 
	"SELECT TOP 1
	|	Reservation.Ref AS Ref,
	|	Reservation.CheckInDate AS CheckInDate,
	|	Reservation.CheckOutDate AS CheckOutDate,
	|	Reservation.Remarks AS Remarks,
	|	Reservation.ReservationStatus.Description AS ReservationStatus,
	|	Reservation.Number AS DocNumber,
	|	Reservation.Hotel.Description AS HotelDescription
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	NOT Reservation.DeletionMark
	|	AND Reservation.Posted
	|	AND Reservation.ReservationStatus.IsActive
	|	AND Reservation.CheckInDate >= &qCheckInDate
	|	AND Reservation.Guest = &qGuest
	|
	|ORDER BY
	|	Reservation.CheckInDate DESC";
	vQry.SetParameter("qCheckInDate", CurrentSessionDate());
	vQry.SetParameter("qGuest", pRef);
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vResRef = vQryRes.Ref;
		vRet.CurrentReservation = TrimAll(vQryRes.ReservationStatus) +" № " + TrimAll(vQryRes.DocNumber) + " c " + Format(vQryRes.CheckInDate, "DF=dd.MM.yyyy") + ", " + TrimAll(vQryRes.HotelDescription);
		vRet.ReservationStatus = TrimAll(vQryRes.ReservationStatus);
		vRet.CurrentReservationRemarks = vQryRes.Remarks;
		If Not IsBlankString(pDBLink) Then
			vRet.ReservationLink = pDBLink + "#" + GetURL(vResRef);
		EndIf;
		vRet.ReservationCheckInDate = vQryRes.CheckInDate;
		vRet.ReservationCheckOutDate = vQryRes.CheckOutDate;
		// Get external system interactions
		vIntegration = Undefined;
		vRet.GuestReservationLink = Catalogs.ExternalSystemInteractions.GetReservationGuestURL(vResRef, vIntegration);
		Break;
	EndDo;
	guestObj 			= pRef.GetObject();
	vRet.Nights 		= Round(guestObj.pmCountNumberOfNights(), 0);
	vRet.Visits 		= guestObj.pmCountNumberOfCheckIns();
	vRet.AvgDepth 		= GetAverageDepthOfReservations(pRef);
	vRet.BonusesSumm 	= AccumulationRegisters.Bonuses.mmGetBalanceByCard(pRef.DiscountCard).BalanceAmount;
	vRet.MemberLevel 	= TrimAll(pRef.DiscountType);
	Return vRet;
EndFunction

// -----------------------------------------------------------------------------
//  Description: Activate gift certificate.
//  Function could be called as web-service or thru COM connection
//
// Parameters:
//  pCertificateNumber	 - String	 - 
//  pAmount				 - Number	 - 
//  pRemarks			 - String	 - 
//  pCurrency			 - String	 - 
//  pVatRate			 - Number	 - 
//  pHotelCode			 - String	 - 
//  pExternalCode		 - String	 - 
//  pExternalSystemCode	 - String	 - 
// 
// Returns:
//  String - Empty string  or error description
//
Function cmActivateGiftCertificate(pCertificateNumber, pAmount, pRemarks, pCurrency, pVatRate, pHotelCode, pExternalCode, pExternalSystemCode) Export 
	WriteLogEvent(NStr("en='Activate gift certificate';ru='Активация сертификата';de='Activate gift certificate'"), EventLogLevel.Information, , , 
	NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode + Chars.LF + 
	NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + pHotelCode + Chars.LF + 
	NStr("en='VatRate: ';ru='НДС: ';de='VatRate: '") + pVatRate + Chars.LF + 
	NStr("en='Certificate number: ';ru='Номер сертификата: ';de='Certificate number: '") + pCertificateNumber + Chars.LF + 
	NStr("en='Sum: ';ru='Сумма: ';de='Summe: '") + pAmount + Chars.LF + 
	NStr("en='Currency: ';ru='Валюта: ';de='Währung: '") + pCurrency + Chars.LF + 
	NStr("en='Remarks: ';ru='Описание: ';de='Beschreibung: '") + pRemarks + Chars.LF + 
	NStr("en='Ext.code: ';ru='Внеш.код: ';de='Ext.code: '") + pExternalCode);
	Try
		// Get hotel
		vHotel = SessionParameters.CurrentHotel;
		If Not IsBlankString(pHotelCode) Then
			vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
		EndIf;
		// Get currency by code
		vCurrency = Catalogs.Currencies.EmptyRef();
		If Not IsBlankString(pCurrency) Then
			vCurrency = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Currencies", pCurrency);
		EndIf;
		
		vServiceCode = "";
		
		// 1. CREATE FOLIO
		FolioObj = Documents.Folio.CreateDocument();
		FolioObj.pmFillAttributesWithDefaultValues();
		FolioObj.Date = CurrentSessionDate();
		FolioObj.DateTimeFrom = BegOfDay(CurrentSessionDate());
		FolioObj.DateTimeTo = EndOfDay(CurrentSessionDate());
		FolioObj.Description = NStr("en='Charge from ext.system';ru='Начисление из внеш. системы';de='Laden aus ext.system'");
		FolioObj.Write();
		
		vFolio = FolioObj.Ref;
		
		vPaymentMethod = vHotel.PlannedPaymentMethod;
		
		//3. CREATE PAYMENT FOR THE FOLIO
		vPaymentObj = Documents.Payment.CreateDocument();
		vPaymentObj.Fill(vFolio);
		vPaymentObj.PaymentCurrency = vCurrency;
		vPaymentObj.PaymentMethod = vPaymentMethod;
		// Payment sections
		vPaymentSection = Undefined;
		If ValueIsFilled(vPaymentObj.Hotel) And vPaymentObj.Hotel.SplitFolioBalanceByPaymentSections Then
			// Update payment object
			vRestOfAmount = pAmount;
			For Each vPSRow In vPaymentObj.PaymentSections Do
				If vRestOfAmount > 0 Then
					If vPSRow.Sum <= vRestOfAmount Then
						vRestOfAmount = vRestOfAmount - vPSRow.Sum;
					Else
						vPSRow.Sum = vRestOfAmount;
						vRestOfAmount = 0;
						
						vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vPaymentObj.Date);
						vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
						vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vPaymentObj.Date);
					EndIf;
				Else
					vPSRow.Sum = 0;
					vPSRow.VATSum = 0;
					vPSRow.SumInFolioCurrency = 0;
					vPSRow.VATSumInFolioCurrency = 0;
				EndIf;
			EndDo;
			If vRestOfAmount > 0 Then
				vPSRow = vPaymentObj.PaymentSections.Add();
				vPSRow.PaymentSection = vPaymentSection;
				vPSRow.Sum = vRestOfAmount;
				vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
				If ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.VATRate) Then
					vPSRow.VATRate = vPaymentSection.VATRate;
				Else
					vPSRow.VATRate = vPaymentObj.VATRate;
				EndIf;
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vPaymentObj.Date);
				vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vPaymentObj.Date);
			EndIf;
			vPaymentObj.pmCalculateTotalsByPaymentSections();
		ElsIf ValueIsFilled(vPaymentObj.Hotel) And vPaymentObj.Hotel.SplitFolioBalanceByServicesAndPrices Then
			// Try to find service
			vService = Catalogs.Services.EmptyRef();
			If IsBlankString(vServiceCode) Then
				vService = vPaymentObj.Hotel.CateringService;
			Else
				vService = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Services", TrimAll(vServiceCode));
				If Not ValueIsFilled(vService) Then
					vService = cmGetServiceByCode(TrimAll(vServiceCode));
				EndIf;
			EndIf;
			If Not ValueIsFilled(vService) Then
				vService = vPaymentObj.Hotel.CateringService;
			EndIf;		
			
			// Update payment object
			vRestOfAmount = pAmount;
			For Each vPSRow In vPaymentObj.PaymentSections Do
				If vRestOfAmount > 0 Then
					If vPSRow.Sum <= vRestOfAmount Then
						vRestOfAmount = vRestOfAmount - vPSRow.Sum;
					Else
						vPSRow.Sum = vRestOfAmount;
						vRestOfAmount = 0;
						
						vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vPaymentObj.Date);
						vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
						vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vPaymentObj.Date);
					EndIf;
				Else
					vPSRow.Sum = 0;
					vPSRow.VATSum = 0;
					vPSRow.SumInFolioCurrency = 0;
					vPSRow.VATSumInFolioCurrency = 0;
				EndIf;
			EndDo;
			If vRestOfAmount > 0 Then
				vPSRow = vPaymentObj.PaymentSections.Add();
				vPSRow.PaymentSection = vPaymentSection;
				vPSRow.ChequeService = vService;
				vPSRow.ChequeServicePrice = vRestOfAmount;
				vPSRow.ChequeServiceQuantity = 1;
				vPSRow.Sum = vRestOfAmount;
				vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
				If ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.VATRate) Then
					vPSRow.VATRate = vPaymentSection.VATRate;
				Else
					vPSRow.VATRate = vPaymentObj.VATRate;
				EndIf;
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vPaymentObj.Date);
				vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vPaymentObj.Date);
			EndIf;
			vPaymentObj.pmCalculateTotalsByPaymentSections();
		Else
			// Build payment object
			vPaymentObj.PaymentSection = vPaymentSection;
			vPaymentObj.Sum = pAmount;
			If TypeOf(vPaymentObj) = Type("DocumentObject.Payment") Then
				vPaymentObj.pmRecalculateSums();
			ElsIf TypeOf(vPaymentObj) = Type("DocumentObject.CustomerPayment") Then
				vPaymentObj.SumInAccountingCurrency = Round(cmConvertCurrencies(vPaymentObj.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, vPaymentObj.AccountingCurrency, vPaymentObj.AccountingCurrencyExchangeRate, vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
			EndIf;
		EndIf;
		// Reference and authorization codes
		vPaymentObj.ReferenceNumber = "";
		vPaymentObj.AuthorizationCode = "";
		// Payment remarks
		vPaymentObj.SlipText = "";
		// External system payment code
		vPaymentObj.ExternalCode = TrimR(pExternalSystemCode);
		//Gift Certificate
		vPaymentObj.GiftCertificate = TrimR(pCertificateNumber);
		// Set customer as payer
		If ValueIsFilled(vPaymentObj.AccountingCustomer) And ValueIsFilled(vPaymentObj.PaymentMethod) And vPaymentObj.PaymentMethod.IsByBankTransfer Then
			If ValueIsFilled(vPaymentObj.Hotel) And vPaymentObj.AccountingCustomer <> vPaymentObj.Hotel.IndividualsCustomer Then
				vPaymentObj.Payer = vPaymentObj.AccountingCustomer;
			EndIf;
		EndIf;
		// Post payment
		vPaymentObj.Write(DocumentWriteMode.Posting);
		
		// 4.Close folio
		FolioObj.IsClosed = True;
		FolioObj.Write();
	
	Except
		WriteLogEvent(NStr("en='Activate gift certificate';ru='Активация сертификата';de='Activate gift certificate'"), EventLogLevel.Error, , , 
						NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + ErrorDescription());
		Return ErrorDescription();
	EndTry;
	Return "";
EndFunction //  cmPayByCertificate()

// -----------------------------------------------------------------------------
//  Description: Returns list of guests by name and room.
//  Function could be called as web-service or thru COM connection
//
// Parameters:
//  pGuestName		 - String	 - Guest name or part of guest name
//  pRoomCode		 - String	 - Room code
//  pHotelName		 - String	 - Hotel code
//  pOutputType		 - String	 - Output type (XDTO or CSV)
//  pExtSystemCode	 - String	 - SystemCode
// 
// Returns:
//  XDTO - XDTO object or CSV strings separated by line feed character
//
Function cmGetReservationsList(pGuestName = "", pRoomCode = "", pHotelName = "", pOutputType = "CSV", pExtSystemCode = "") Export
	// Initialize return parameters				  
	vRetStr = "";
	vRetXDTO = Undefined;
	vGuestItemType = Undefined;
	If pOutputType <> "CSV" Then
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestsList"));
		vGuestItemType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestItem");
		vGuestItemsType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestItems");
		vRetXDTO.GuestItems = XDTOFactory.Create(vGuestItemsType);
	EndIf;
	
	// Initialize input parameters
	If pGuestName = Undefined Then
		pGuestName = "";
	EndIf;
	If pRoomCode = Undefined Then
		pRoomCode = "";
	EndIf;
	If pHotelName = Undefined Then
		pHotelName = "";
	EndIf;
	
	vExtSystemCode = "TraktirFO3";
	If Not IsBlankString(pExtSystemCode) Then
		vExtSystemCode = TrimR(pExtSystemCode);
	EndIf;
	vHotel = cmGetHotelByCode(pHotelName, vExtSystemCode);
	
	// Find room by code
	vRoomCode = TrimR(pRoomCode);
	vRoom = cmGetRoomByCode(pRoomCode, pHotelName, vExtSystemCode);
	If ValueIsFilled(vRoom) Then
		vRoomCode = TrimR(vRoom.Description);
		vHotel = vRoom.Owner;
	EndIf;		
	
	// Log input parameters
	WriteLogEvent(NStr("en='Get reservation list';ru='Получить список броней';de='Liste der Hotelgäste erhalten'"), EventLogLevel.Information, , , 
	NStr("en='Guest name: ';ru='Имя гостя: ';de='Name des Gastes: '") + pGuestName + Chars.LF +
	NStr("en='Room code: ';ru='Код номера: ';de='Zimmercode: '") + pRoomCode + " (" + vRoom + ")" + Chars.LF +
	NStr("en='Hotel name: ';ru='Название гостиницы: ';de='Bezeichnung des Hotels: '") + pHotelName + " (" + TrimAll(vHotel) + ")" + Chars.LF + 
	NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExtSystemCode + " (" + TrimAll(vExtSystemCode) + ")");
	
	// Try to find guests by input parameters
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	RoomInventory.Guest AS Guest,
	|	RoomInventory.Guest.FullName AS GuestFullName,
	|	ISNULL(RoomInventory.Guest.Code, &qEmptyString) AS GuestCode,
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.Hotel.Description AS HotelDescription,
	|	RoomInventory.Room.Description AS RoomDescription,
	|	RoomInventory.Room.SortCode AS RoomSortCode,
	|	ISNULL(RoomInventory.Recorder.NoPost, FALSE) AS NoPost,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.Recorder.AccommodationType AS AccommodationType,
	|	RoomInventory.Recorder.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomInventory.Recorder.Number AS AccommodationCode,
	|	RoomInventory.Recorder.DiscountCard AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType AS DiscountType,
	|	CASE
	|		WHEN ISNULL(RoomInventory.Recorder.ServicePackage.IsMealBoardTerm, FALSE)
	|			THEN RoomInventory.Recorder.ServicePackage
	|		ELSE UNDEFINED
	|	END AS MealBoardTerm,
	|	ISNULL(RoomInventory.GuestGroup.Code, 0) AS GuestGroupCode,
	|	RoomInventory.Customer.Description AS CustomerDescription,
	|	RoomInventory.PlannedPaymentMethod.Description AS PlannedPaymentMethodDescription,
	|	ISNULL(ClientBalances.ClientBalance, 0) + ISNULL(ClientBalances.ClientLimit, 0) AS ClientBalance,
	|	ISNULL(ClientCreditLimit.CreditLimit, 0) AS CreditLimit,
	|	CASE
	|		WHEN ClientBalances.FolioCurrency IS NULL
	|			THEN ClientCreditLimit.FolioCurrency
	|		ELSE ClientBalances.FolioCurrency
	|	END AS FolioCurrency,
	|	CASE
	|		WHEN ClientBalances.FolioCurrency IS NULL
	|			THEN ClientCreditLimit.FolioCurrency.Code
	|		ELSE ClientBalances.FolioCurrency.Code
	|	END AS FolioCurrencyCode,
	|	RoomInventory.Status.Description AS Status,
	|	ISNULL(RoomInventory.Recorder.RoomRate.Description, """") AS RoomRate
	|FROM
	|	(SELECT
	|		Acc.Guest AS Guest,
	|		Acc.Hotel AS Hotel,
	|		Acc.Room AS Room,
	|		Acc.Recorder AS Recorder,
	|		Acc.GuestGroup AS GuestGroup,
	|		Acc.Customer AS Customer,
	|		Acc.PlannedPaymentMethod AS PlannedPaymentMethod,
	|		Acc.AccommodationStatus AS Status
	|	FROM
	|		AccumulationRegister.RoomInventory AS Acc
	|	WHERE
	|		Acc.IsAccommodation
	|		AND Acc.IsInHouse
	|		AND Acc.RecordType = &qRecordType
	|		AND Acc.PeriodFrom <= &qCurrentDate
	|		AND (Acc.PeriodTo >= &qCurrentDate
	|				OR Acc.PeriodTo = Acc.Recorder.CheckOutDate)
	|		AND Acc.Guest <> &qEmptyClient
	|		AND (Acc.Hotel.Description = &qHotelName
	|				OR Acc.Hotel.Code = &qHotelName
	|				OR &qEmptyHotel)
	|		AND (Acc.Room.Description = &qRoomCode
	|				OR &qEmptyRoomCode)
	|		AND (Acc.Guest.Description LIKE &qGuestName
	|				OR Acc.Guest.FullName LIKE &qGuestName
	|				OR &qEmptyGuestName)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VirtualGuests.Guest,
	|		VirtualGuests.Hotel,
	|		VirtualGuests.Room,
	|		VirtualGuests.Ref,
	|		VirtualGuests.GuestGroup,
	|		VirtualGuests.Customer,
	|		VirtualGuests.PlannedPaymentMethod,
	|		VirtualGuests.AccommodationStatus
	|	FROM
	|		Document.Accommodation AS VirtualGuests
	|	WHERE
	|		VirtualGuests.Posted
	|		AND VirtualGuests.AccommodationStatus.IsActive
	|		AND VirtualGuests.AccommodationStatus.IsInHouse
	|		AND VirtualGuests.Room.IsVirtual
	|		AND VirtualGuests.CheckInDate <= &qCurrentDate
	|		AND VirtualGuests.CheckOutDate >= &qCurrentDate
	|		AND VirtualGuests.Guest <> &qEmptyClient
	|		AND (VirtualGuests.Hotel.Description = &qHotelName
	|				OR VirtualGuests.Hotel.Code = &qHotelName
	|				OR &qEmptyHotel)
	|		AND (VirtualGuests.Room.Description = &qRoomCode
	|				OR &qEmptyRoomCode)
	|		AND (VirtualGuests.Guest.Description LIKE &qGuestName
	|				OR VirtualGuests.Guest.FullName LIKE &qGuestName
	|				OR &qEmptyGuestName)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Reserv.Guest,
	|		Reserv.Hotel,
	|		Reserv.Room,
	|		Reserv.Recorder,
	|		Reserv.GuestGroup,
	|		Reserv.Customer,
	|		Reserv.PlannedPaymentMethod,
	|		Reserv.ReservationStatus
	|	FROM
	|		AccumulationRegister.RoomInventory AS Reserv
	|	WHERE
	|		Reserv.IsReservation
	|		AND Reserv.ReservationStatus.IsActive
	|		AND Reserv.RecordType = &qRecordType
	|		AND Reserv.Guest <> &qEmptyClient
	|		AND (Reserv.Hotel.Description = &qHotelName
	|				OR Reserv.Hotel.Code = &qHotelName
	|				OR &qEmptyHotel)
	|		AND (Reserv.Room.Description = &qRoomCode
	|				OR &qEmptyRoomCode)
	|		AND (Reserv.Guest.Description LIKE &qGuestName
	|				OR Reserv.Guest.FullName LIKE &qGuestName
	|				OR &qEmptyGuestName)
	|		AND Reserv.CheckOutDate >= &qCurrentDate) AS RoomInventory
	|		LEFT JOIN (SELECT
	|			ClientAccountsBalance.FolioCurrency AS FolioCurrency,
	|			ClientAccountsBalance.Folio.ParentDoc AS FolioParentDoc,
	|			SUM(ClientAccountsBalance.SumBalance) AS ClientBalance,
	|			SUM(ClientAccountsBalance.LimitBalance) AS ClientLimit
	|		FROM
	|			AccumulationRegister.Accounts.Balance(
	|					&qBalancesPeriod,
	|					NOT Folio.IsClosed
	|						AND (Folio.Customer = &qEmptyCustomer
	|							OR Folio.Customer <> &qEmptyCustomer
	|								AND Folio.Customer.IsIndividual
	|							OR Folio.Description LIKE &qFolioDescription
	|								AND NOT &qFolioDescriptionIsEmpty)
	|						AND (Folio.Description LIKE &qFolioDescription
	|							OR &qFolioDescriptionIsEmpty)) AS ClientAccountsBalance
	|		
	|		GROUP BY
	|			ClientAccountsBalance.FolioCurrency,
	|			ClientAccountsBalance.Folio.ParentDoc) AS ClientBalances
	|		ON RoomInventory.Recorder = ClientBalances.FolioParentDoc
	|			AND RoomInventory.Recorder.Hotel.FolioCurrency = ClientBalances.FolioCurrency
	|		LEFT JOIN (SELECT
	|			ClientFolios.FolioCurrency AS FolioCurrency,
	|			ClientFolios.ParentDoc AS FolioParentDoc,
	|			MAX(CASE
	|					WHEN ClientFolios.Hotel.NoCreditLimit
	|						THEN 999999999
	|					WHEN ClientFolios.Customer <> &qEmptyCustomer
	|							AND NOT ClientFolios.Customer.IsIndividual
	|							AND ClientFolios.Description LIKE &qFolioDescription
	|							AND NOT &qFolioDescriptionIsEmpty
	|						THEN 999999999
	|					ELSE ClientFolios.CreditLimit
	|				END) AS CreditLimit
	|		FROM
	|			Document.Folio AS ClientFolios
	|		WHERE
	|			NOT ClientFolios.IsClosed
	|			AND (ClientFolios.Customer = &qEmptyCustomer
	|					OR ClientFolios.Customer <> &qEmptyCustomer
	|						AND ClientFolios.Customer.IsIndividual
	|					OR ClientFolios.Description LIKE &qFolioDescription
	|						AND NOT &qFolioDescriptionIsEmpty)
	|			AND (ClientFolios.Description LIKE &qFolioDescription
	|					OR &qFolioDescriptionIsEmpty)
	|		
	|		GROUP BY
	|			ClientFolios.FolioCurrency,
	|			ClientFolios.ParentDoc) AS ClientCreditLimit
	|		ON RoomInventory.Recorder = ClientCreditLimit.FolioParentDoc
	|			AND RoomInventory.Recorder.Hotel.FolioCurrency = ClientCreditLimit.FolioCurrency
	|
	|ORDER BY
	|	HotelDescription,
	|	RoomSortCode,
	|	AccommodationTypeSortCode,
	|	GuestFullName";
	vQry.SetParameter("qBalancesPeriod", '39991231235959');
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qRecordType", AccumulationRecordType.Expense);
	vQry.SetParameter("qHotelName", TrimR(pHotelName));
	vQry.SetParameter("qEmptyHotel", IsBlankString(pHotelName));
	vQry.SetParameter("qGuestName", Upper(TrimR(pGuestName)) + "%");
	vQry.SetParameter("qEmptyGuestName", IsBlankString(pGuestName));
	vQry.SetParameter("qRoomCode", TrimR(vRoomCode));
	vQry.SetParameter("qEmptyRoomCode", IsBlankString(vRoomCode));
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qFolioDescription", "%" + TrimAll(vHotel.AdditionalServicesFolioCondition) + "%");
	vQry.SetParameter("qFolioDescriptionIsEmpty", IsBlankString(vHotel.AdditionalServicesFolioCondition));
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vGuests = vQry.Execute().Unload();
	For Each vGuestsRow In vGuests Do
		vGuest = vGuestsRow.Guest;
		
		// Get discount data
		vDiscount = 0;
		vDiscountType = Undefined;
		vDiscountCard = Undefined;
		If ValueIsFilled(vGuestsRow.DiscountCard) Then
			vDiscountCard = vGuestsRow.DiscountCard;
			vDiscountType = vDiscountCard.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		ElsIf ValueIsFilled(vGuestsRow.DiscountType) Then
			vDiscountType = vGuestsRow.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		Else
			If ValueIsFilled(vGuest) Then
				If ValueIsFilled(vGuest.DiscountType) Then
					vDiscountType = vGuest.DiscountType;
					vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
				Else
					vDiscountCard = cmGetDiscountCardByClient(vGuest);
					If ValueIsFilled(vDiscountCard) And ValueIsFilled(vDiscountCard.DiscountType) Then
						vDiscountType = vDiscountCard.DiscountType;
						vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vDiscountType) And vDiscountType.DoNotExportToExternalInterfaces Then
			vDiscount = 0;
			vDiscountType = Undefined;
			vDiscountCard = Undefined;
		EndIf;
		
		vIsRoomShare = False;
		If ValueIsFilled(vGuestsRow.AccommodationType) And vGuestsRow.AccommodationType.Type <> Enums.AccomodationTypes.Room Then
			vIsRoomShare = True;
		EndIf;
		
		// Document discount card
		vDocDiscountCard = Undefined;
		If ValueIsFilled(vGuestsRow.DiscountCard) Then
			vDocDiscountCard = vGuestsRow.DiscountCard;
		EndIf;
		
		// Add client bonuses
		If ValueIsFilled(vGuest) And ValueIsFilled(vGuestsRow.FolioCurrency) Then
			vClientObj = vGuest.GetObject();
			vBonus = 0;
			vBonusAmount = vClientObj.pmGetBonusesAmount(vGuestsRow.Hotel, vGuestsRow.FolioCurrency, vDocDiscountCard, vBonus);
			If vGuestsRow.CreditLimit < 999999999 Then
				vGuestsRow.CreditLimit = vGuestsRow.CreditLimit + vBonusAmount;
			EndIf;
		EndIf;
		If vGuestsRow.NoPost Then
			vGuestsRow.ClientBalance = 0;
			vGuestsRow.CreditLimit = 0;
		EndIf;
		
		// Build return string in CSV format
		vRetStr = vRetStr + """" + cmRemoveComma(vGuestsRow.GuestFullName) + ?(ValueIsFilled(vDocDiscountCard), "(DC " + TrimAll(vDocDiscountCard.Identifier) + ")", "") + """" + "," + 
		"""" + TrimAll(vGuestsRow.GuestCode) + """" + "," + 
		"""" + cmRemoveComma(vGuestsRow.HotelDescription) + """" + "," + 
		"""" + cmRemoveComma(vGuestsRow.RoomDescription) + """" + "," + 
		"""" + Format(Date(vGuestsRow.CheckInDate), "DF='dd.MM.yyyy HH:mm'") + """" + "," + 
		"""" + Format(Date(vGuestsRow.CheckOutDate), "DF='dd.MM.yyyy HH:mm'") + """" + "," + 
		Format(vGuestsRow.GuestGroupCode, "ND=12; NFD=0; NZ=; NG=") + "," + 
		"""" + cmRemoveComma(vGuestsRow.CustomerDescription) + """" + "," + 
		"""" + cmRemoveComma(vGuestsRow.PlannedPaymentMethodDescription) + """" + "," + 
		Format(vGuestsRow.ClientBalance, "ND=17; NFD=2; NDS=.; NZ=; NG=") + "," + 
		Format(vGuestsRow.CreditLimit, "ND=17; NFD=2; NDS=.; NZ=; NG=") + "," + 
		"""" + TrimAll(vGuestsRow.FolioCurrencyCode) + """" + "," + 
		?(vDiscount <> 0, Format(vDiscount, "ND=6; NFD=2; NDS=.; NZ=; NG="), "0") + "," +
		"""" + ?(ValueIsFilled(vDiscountType), cmRemoveComma(vDiscountType.Description), "") + """" + "," + 
		"""" + ?(ValueIsFilled(vDiscountCard), cmRemoveComma(vDiscountCard.Identifier), "") + """" + "," + 
		"""" + TrimAll(vGuestsRow.AccommodationCode) + """" + "," + 
		"""" + TrimAll(vGuestsRow.Status) + """" + "," + 
		"""" + TrimAll(vGuestsRow.RoomRate) + """" + "," + 
		"""" + TrimAll(vIsRoomShare) + """" + Chars.LF;
		
		// Build XDTO return object
		If pOutputType <> "CSV" Then
			vGuestItem = XDTOFactory.Create(vGuestItemType);
			vGuestItem.Guest 			= cmRemoveUTFControlSymbols(cmRemoveComma(vGuestsRow.GuestFullName) + ?(ValueIsFilled(vDocDiscountCard), "(DC " + TrimAll(vDocDiscountCard.Identifier) + ")", ""));
			vGuestItem.GuestCode 		= vGuestsRow.GuestCode;
			vGuestItem.GuestSex 		= Upper(Left(TrimAll(vGuest.Sex), 1));
			vGuestItem.GuestDateOfBirth = vGuest.DateOfBirth;
			vGuestItem.GuestAge 		= vGuest.Age;
			If ValueIsFilled(vGuest.Citizenship) Then
				vGuestItem.GuestCitizenship = TrimAll(vGuest.Citizenship.ISOCode3);
			Else
				vGuestItem.GuestCitizenship = "";
			EndIf;
			vGuestItem.GuestLanguage 	= TrimAll(vGuest.Language);
			vGuestItem.Hotel 			= cmRemoveComma(vGuestsRow.HotelDescription);
			vGuestItem.Room 			= TrimAll(vGuestsRow.RoomDescription);
			vGuestItem.CheckInDate 		= Date(vGuestsRow.CheckInDate);
			vGuestItem.CheckOutDate 	= Date(vGuestsRow.CheckOutDate);
			vGuestItem.GuestGroup 		= vGuestsRow.GuestGroupCode;
			vGuestItem.Customer 		= cmRemoveUTFControlSymbols(cmRemoveComma(vGuestsRow.CustomerDescription));
			vGuestItem.PaymentMethod 	= TrimAll(vGuestsRow.PlannedPaymentMethodDescription);
			vGuestItem.ClientBalance 	= vGuestsRow.ClientBalance;
			vGuestItem.CreditLimit 		= vGuestsRow.CreditLimit;
			vGuestItem.FolioCurrency 	= TrimAll(vGuestsRow.FolioCurrencyCode);
			vGuestItem.Discount 		= vDiscount;
			vGuestItem.DiscountType 	= ?(ValueIsFilled(vDiscountType), TrimAll(vDiscountType.Description), "");
			vGuestItem.DiscountCard 	= ?(ValueIsFilled(vDiscountCard), TrimAll(vDiscountCard.Identifier), "");
			vGuestItem.AccommodationCode= TrimAll(vGuestsRow.AccommodationCode);
			vGuestItem.IsRoomShare 		= vIsRoomShare;
			vGuestItem.GuestPhone       = TrimAll(vGuest.Phone);
			vGuestItem.GuestRemarks     = TrimAll(vGuest.Remarks);
			vGuestItem.MealBoardTerm    = ?(ValueIsFilled(vGuestsRow.MealBoardTerm), TrimAll(vGuestsRow.MealBoardTerm.Code), "");
			vGuestItem.ReservationStatus= TrimAll(vGuestsRow.Status);  
			vGuestItem.RoomRate			= TrimAll(vGuestsRow.RoomRate);
			vGuestItem.NoPost			= vGuestsRow.NoPost;
			
			vRetXDTO.GuestItems.GuestItem.Add(vGuestItem);
		EndIf;
	EndDo;
	
	// Return based on output type
	WriteLogEvent(NStr("en='Get reservation list of hotel';ru='Получить список броней гостиницы';de='Liste der Hotelgäste erhalten'"), EventLogLevel.Information, , , NStr("en='Return string: ';ru='Строка возврата: ';de='Zeilenrücklauf: '") + vRetStr);
	If pOutputType = "CSV" Then
		Return vRetStr;
	Else
		Return vRetXDTO;
	EndIf;
EndFunction // cmGetHotelGuestsList

// -----------------------------------------------------------------------------
//  Issue a new discount card from an external system.
//
// Parameters:
//  pCard	 - String	 - 
//  pSource	 - String	 - 
//  pHotel	 - String	 - 
//  pRemarks - String	 - 
// 
// Returns:
//  String - Empty string  or error description
//
Function cmIssueDiscountCardExt(pCard, pSource, pHotel, pRemarks) Export
	vInputParams = NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pSource.ExternalSystemCode + Chars.LF +
						NStr("en='External code: ';ru='Внешний код: ';de='Externen code: '") + pSource.POS + Chars.LF +
						NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + pHotel + Chars.LF + 
						NStr("en='Card number: ';ru='Номер карты: ';de='Card number: '") + pCard.ID + Chars.LF +
						NStr("en='Card type: ';ru='Тип карты: ';de='Card type: '") + pCard.CardType + Chars.LF +
						NStr("en='Card description: ';ru='Наименование карты: ';de='Card description: '") + pCard.Description + Chars.LF +
						NStr("en='Sum: ';ru='Сумма: ';de='Summe: '") + pCard.Amount + Chars.LF + 
						NStr("en='Remarks: ';ru='Описание: ';de='Beschreibung: '") + pRemarks; 
	
	WriteLogEvent(NStr("en = 'Discount Card Issue'; de = 'Ausgabe der Rabattkarte'; ru = 'Выпуск дисконтной карты'"), EventLogLevel.Information, , vInputParams);

	If IsBlankString(pSource.ExternalSystemCode) Then
		Raise NStr("en = 'ExternalSystemCode cannot be empty'; 
						|de = 'ExternalSystemCode darf nicht leer sein'; 
						|ru = 'ExternalSystemCode не может быть пустым'");
	EndIf;	
	// Check interaction
	vInteraction = Undefined;
	vInteractions = cmGetInteractionByID(pSource.ExternalSystemCode, True);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; 
					|de='More then one interactions found with given interaction ID!'; 
					|ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteraction = vInteractions.Get(0).Ref;
		If Not vInteraction.IsActive Then
			Raise NStr("en='Interaction with given interaction ID is not active!'; 
						|de='Interaction with given interaction ID is not active!'; 
						|ru='Взаимодействие с переданным идентификатором не активно!'");
		EndIf;
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; 
					|de='Interaction with given interaction ID is not found!'; 
					|ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	If vInteraction.DebugMode Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmIssueDiscountCardExt.Start", Enums.ExternalSystemEventTypes.Info, vInputParams , , vMsg);
	EndIf;
	
	// Discount card search
	vDiscountCard = cmGetDiscountCardById(TrimAll(pCard.ID));
	If Not ValueIsFilled(vDiscountCard) Then
		vMsg = NStr("en='The discount card is not found by ID %1';ru='Дисконтная карта не найдена по ID %1';de='Rabattkarte nicht gefunden by ID %1'");
		vMsg = StrTemplate(vMsg, pCard.ID);
		If vInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmIssueDiscountCardExt.GetDiscountCardById", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		EndIf;
	Else
		// Discount card is found
		If vInteraction.DebugMode Then
			vMsg = NStr("en='The discount card is found %1';ru='Дисконтная карта найдена %1';de='Rabattkarte gefunden %1'");
			vMsg = StrTemplate(vMsg, vDiscountCard.Description);
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmIssueDiscountCardExt.GetDiscountCardById", Enums.ExternalSystemEventTypes.Info, , vMsg);
		EndIf;
		vMsg = NStr("en = 'A card with this number has already been issued'; 
					|de = 'Eine Karte mit dieser Nummer wurde bereits ausgestellt'; 
					|ru = 'Карта с таким номером уже выпущена'");
		If vInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmIssueDiscountCardExt.End", Enums.ExternalSystemEventTypes.Info, , , vMsg);
		EndIf;
		Return vMsg	
	EndIf;

	// Search hotel
	If ValueIsFilled(pHotel) Then
		vHotel = cmGetHotelByCode(pHotel, vInteraction.InteractionID);  	
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = vDiscountCard.Hotel;			
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = vInteraction.Hotel;			
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;			
	EndIf;

	vBonusesOperationObj = Undefined;
	If ValueIsFilled(vHotel) Then
		// Search discount type
		vDicountType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "DiscountTypes", pCard.CardType);
		If ValueIsFilled(vDicountType) Then
			Try
				// Create a discount card
				If vInteraction.DebugMode Then
					vMsg = NStr("en = 'Create a discount card'; de = 'Erstellen Sie eine Rabattkarte'; ru = 'Создание дисконтной карты'");
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmActivateCertificateByDiscountCard.CreateDiscountCard", Enums.ExternalSystemEventTypes.Info, , , vMsg);
				EndIf;
				vDCObj = Catalogs.DiscountCards.CreateItem();
				vDCObj.DiscountType = vDicountType;
				vDCObj.LoyaltyType = vDicountType.LoyaltyType;
				If vDicountType.Validity > 0 Then
					vDCObj.ValidFrom = BegOfDay(CurrentSessionDate());
					vDCObj.ValidTo = vDCObj.ValidFrom + vDicountType.Validity * 86400;
				EndIf;
				vDCObj.CreateHotel = vHotel;
				vDCObj.Description = TrimAll(pCard.ID);
				vDCObj.Identifier = TrimAll(pCard.ID);
				vDCObj.Remarks = TrimAll(pRemarks);
				// Create discount card folio
				vDCObj.Folio = Catalogs.DiscountCards.CreateFolio(TrimAll(vDCObj.Identifier), vDCObj.LoyaltyType, vDCObj.Client, vDCObj.Customer);
				// Save discount card
				vDCObj.Write();
				// Add bonuses payment	
				If vInteraction.DebugMode Then
					vMsg = NStr("en = 'Activation operation'; de = 'Aktivierungsvorgang'; ru = 'Операция активации'");
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmActivateCertificateByDiscountCard.AddBonusesPayment", Enums.ExternalSystemEventTypes.Info, , , vMsg);
				EndIf;
				vBonusesOperationObj = Documents.BonusesOperation.CreateDocument();
				vBonusesOperationObj.Fill(vDCObj.Ref);
				vBonusesOperationObj.Hotel = vHotel;
				vBonusesOperationObj.OperationType = Enums.BonusesOperationTypes.Receipt;
				vBonusesOperationObj.BonusesQuantity = pCard.Amount;
				vBonusesOperationObj.Source = TrimAll(pSource.POS);
				vBonusesOperationObj.ExternalCode = TrimAll(pSource.TransactionID);
				vBonusesOperationObj.Remarks = ?(IsBlankString(TrimAll(pSource.POS)), "", TrimAll(pSource.POS) + " - ") + ?(IsBlankString(TrimAll(pSource.TransactionID)), "", TrimAll(pSource.TransactionID) + " - ") + TrimAll(pRemarks);
				vBonusesOperationObj.Write(DocumentWriteMode.Posting);
			Except
				vErrorD = ErrorInfo();
				vErr = NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + DetailErrorDescription(vErrorD);
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmIssueDiscountCardExt.Error", Enums.ExternalSystemEventTypes.Warning, , , DetailErrorDescription(vErrorD));
				WriteLogEvent(NStr("en = 'Discount Card Issue'; de = 'Ausgabe der Rabattkarte'; ru = 'Выпуск дисконтной карты'"), EventLogLevel.Error, , , vErr);
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmIssueDiscountCardExt.Issue", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
				Return BriefErrorDescription(vErrorD);
			EndTry;
		Else
			vMsg = NStr("en = 'The discount type not found'; de = 'Der Rabatttyp wurde nicht gefunden'; ru = 'Тип карты не найден'");
			If vInteraction.DebugMode Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmIssueDiscountCardExt.GetDicountType", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
			EndIf;
			Return vMsg
		EndIf;
	Else
		vMsg = NStr("en='The hotel cannot be empty';ru='Отель не может быть пустым';de='Das Hotel darf nicht leer sein'");
		If vInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmIssueDiscountCardExt.GetHotel", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		EndIf;
		Return vMsg
	EndIf;
	If vInteraction.DebugMode And vBonusesOperationObj <> Undefined Then
		vMsg = NStr("en='End of processing';ru='Конец выполнения';de='Ende der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "cmIssueDiscountCardExt.End", Enums.ExternalSystemEventTypes.Info, String(vBonusesOperationObj.Ref), , vMsg);
	EndIf;
	
	Return "";
EndFunction	

// ---------------------------------------------------------------------------
//  Returns Service package XDTO for the web-service functions
//
// Parameters:
//  pDocRef	 - DocumentRef.Accommodation - Accommodation Or Reservation
// 
// Returns:
//  XDTO - XDTO the list of ServicePackages
//
Function GetServicePackagesXDTO(pDocRef) Export
	
	vServicePackagesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ServicePackages"));
	
	If ValueIsFilled(pDocRef) And (TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation")) Then
		// Add service packages info
		vQ = New Query("SELECT
		               |	AccommodationServicePackages.ServicePackage.Code AS ServicePackageCode,
		               |	AccommodationServicePackages.ServicePackage.Description AS ServicePackageDescription,
		               |	AccommodationServicePackages.ServicePackage.DescriptionTranslations AS ServicePackageTranslations
		               |FROM
		               |	Document.Accommodation.ServicePackages AS AccommodationServicePackages
		               |WHERE
		               |	AccommodationServicePackages.Ref = &qParentDoc
		               |
		               |ORDER BY
		               |	AccommodationServicePackages.LineNumber");
		vQ.SetParameter("qParentDoc",pDocRef);
		qRes = vQ.Execute().Select();
		
		While qRes.Next() Do
			
			vServiceXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ServicePackage"));
			vServiceXDTO.ServicePackageCode = qRes.ServicePackageCode;
			
			If Not IsBlankString(qRes.ServicePackageTranslations) Then
				vServiceXDTO.ServicePackageDescription  = NStr(qRes.ServicePackageTranslations);
			Else
				vServiceXDTO.ServicePackageDescription = qRes.ServicePackageDescription;	
			EndIf;
			
			vServicePackagesXDTO.ServicePackage.Add(vServiceXDTO);
			
		EndDo;
		// Add document service package
		If ValueIsFilled(pDocRef.ServicePackage) Then
			
			vServiceXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ServicePackage"));
			vServiceXDTO.ServicePackageCode = pDocRef.ServicePackage.Code;
			
			If Not IsBlankString(pDocRef.ServicePackage.DescriptionTranslations) Then
				vServiceXDTO.ServicePackageDescription  = NStr(pDocRef.ServicePackage.DescriptionTranslations);
			Else
				vServiceXDTO.ServicePackageDescription = pDocRef.ServicePackage.Description;
			EndIf;
			
			vServicePackagesXDTO.ServicePackage.Add(vServiceXDTO);
			
		EndIf;
	EndIf;
	
	Return vServicePackagesXDTO;

EndFunction

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetAverageDepthOfReservations(pClientRef)
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	AVG(DATEDIFF(Reservation.Date, Reservation.CheckInDate, DAY)) AS AvgDepth
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	NOT Reservation.DeletionMark
	|	AND Reservation.Posted
	|	AND Reservation.Guest = &qGuest";
	
	vQry.SetParameter("qGuest", pClientRef);
	vQryResult = vQry.Execute().Select();
	While vQryResult.Next() Do
		Return vQryResult.AvgDepth;
	EndDo;
	Return 0;
EndFunction

// -----------------------------------------------------------------------------
Function GetItemFolder(pService, pHotel)
	vFolderRef = Catalogs.OrderItems.EmptyRef();
	vQ = New Query("SELECT
	               |	OrderItems.Ref AS Ref
	               |FROM
	               |	Catalog.OrderItems AS OrderItems
	               |WHERE
	               |	OrderItems.IsFolder
	               |	AND (OrderItems.Hotel = &qHotel
	               |			OR OrderItems.Hotel = &qEmptyHotel)
	               |	AND (OrderItems.Description = &qDescription
	               |			OR OrderItems.Service = &qService)
	               |	AND NOT OrderItems.DeletionMark");
	vQ.SetParameter("qHotel", pHotel);
	vQ.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQ.SetParameter("qService", pService);
	vQ.SetParameter("qDescription", TrimAll(pService));
	vFolders = vQ.Execute().Select();
	If vFolders.Next() Then
		vFolderRef = vFolders.Ref;
	EndIf;
	If Not ValueIsFilled(vFolderRef) Then
		vFolderObj = Catalogs.OrderItems.CreateFolder();
		vFolderObj.Hotel = pHotel;
		vFolderObj.Service = pService;
		vFolderObj.Description = Upper(TrimAll(pService));
		vFolderObj.Write();
		vFolderRef = vFolderObj.Ref;
	ElsIf Upper(TrimAll(vFolderRef.Description)) <> Upper(TrimAll(pService)) Then
		vFolderObj = vFolderRef.GetObject();
		vFolderObj.Service = pService;
		vFolderObj.Description = Upper(TrimAll(pService));
		vFolderObj.Write();
		vFolderRef = vFolderObj.Ref;
	EndIf;
	Return vFolderRef;
EndFunction // GetItemFolder

// -----------------------------------------------------------------------------
Function GetOrderStatus(pOrderStatus, pExternalSystemCode, pHotel, pOrderType = Undefined)
	If pOrderStatus = Undefined Then
		Return Catalogs.OrderStatuses.Complete;
	EndIf;
	vOrderStatus = cmGetObjectRefByExternalSystemCode(pHotel, pExternalSystemCode, "OrderStatuses", TrimAll(pOrderStatus));
	
	If ValueIsFilled(vOrderStatus) Then
		Return vOrderStatus;
	Else
		If ValueIsFilled(pOrderType) Then
			// get order status from order type
			vOrderTypeObj = pOrderType.GetObject();
			If vOrderTypeObj.StatusesCourse.Count() > 0 Then
				// use the first in line
				Return vOrderTypeObj.StatusesCourse[0].Status;
			EndIf;	
		EndIf;
	EndIf;
	Return Catalogs.OrderStatuses.Complete;
EndFunction // GetOrderStatus

// -----------------------------------------------------------------------------
Function GetOrderDoc(pExtOrderID, pExternalSystemCode)
	If Not IsBlankString(pExtOrderID) Then
		vQ = New Query("SELECT
		               |	ExternalOrderCodes.Order AS Order,
		               |	ExternalOrderCodes.ExternalSystemCode AS ExternalSystemCode,
		               |	ExternalOrderCodes.ExternalOrderCode AS ExternalOrderCode
		               |FROM
		               |	InformationRegister.ExternalOrderCodes AS ExternalOrderCodes
		               |WHERE
		               |	ExternalOrderCodes.ExternalSystemCode = &qExternalSystemCode
		               |	AND ExternalOrderCodes.ExternalOrderCode = &qExternalOrderCode
		               |	AND NOT ISNULL(ExternalOrderCodes.Order.DeletionMark, TRUE)");
		vQ.SetParameter("qExternalSystemCode", pExternalSystemCode);
		vQ.SetParameter("qExternalOrderCode", pExtOrderID);
		vQ.Execute();
		qRes = vQ.Execute().Select();
		If qRes.Next() Then
			If ValueIsFilled(qRes.Order) Then
				vOrderObj = qRes.Order.GetObject();
				Return vOrderObj;
			EndIf;
		EndIf;
	EndIf;
	vOrderObj = Documents.Order.CreateDocument();
	vOrderObj.pmFillAuthorAndDate();
	Return vOrderObj;
EndFunction // GetOrderDoc

// -----------------------------------------------------------------------------
Function GetFolioByRoom(pRoom, pGuestCode, pService, pHotelName, pServiceDate)
	vRoomRef = "";
	vOrderDate = "";
	vClientRef = "";
	vFolioData = New Structure("Folio, ParentDoc, Client, ErrorDescription, SentSms");
	
	// Try to find guests by input parameters
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	RoomInventory.Guest AS Guest,
	|	RoomInventory.Guest.FullName AS GuestFullName,
	|	ISNULL(RoomInventory.Guest.Code, &qEmptyString) AS GuestCode,
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.Hotel.Description AS HotelDescription,
	|	RoomInventory.Room.Description AS RoomDescription,
	|	RoomInventory.Room.SortCode AS RoomSortCode,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.Recorder.AccommodationType AS AccommodationType,
	|	RoomInventory.Recorder.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomInventory.Recorder.Ref AS AccommodationRef,
	|	RoomInventory.Recorder.DiscountCard AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType AS DiscountType,
	|	ISNULL(RoomInventory.GuestGroup.Code, 0) AS GuestGroupCode,
	|	RoomInventory.Customer.Description AS CustomerDescription,
	|	RoomInventory.PlannedPaymentMethod.Description AS PlannedPaymentMethodDescription
	|FROM
	|	(SELECT
	|		RoomInventoryMovements.Guest AS Guest,
	|		RoomInventoryMovements.Hotel AS Hotel,
	|		RoomInventoryMovements.Room AS Room,
	|		RoomInventoryMovements.Recorder AS Recorder,
	|		RoomInventoryMovements.GuestGroup AS GuestGroup,
	|		RoomInventoryMovements.Customer AS Customer,
	|		RoomInventoryMovements.PlannedPaymentMethod AS PlannedPaymentMethod
	|	FROM
	|		AccumulationRegister.RoomInventory AS RoomInventoryMovements
	|	WHERE
	|		RoomInventoryMovements.IsAccommodation
	|		AND RoomInventoryMovements.RecordType = &qRecordType
	|		AND RoomInventoryMovements.PeriodFrom <= &qServiceDate
	|		AND (RoomInventoryMovements.PeriodTo >= &qServiceDate
	|				OR RoomInventoryMovements.PeriodTo = RoomInventoryMovements.Recorder.CheckOutDate
	|					AND RoomInventoryMovements.IsInHouse)
	|		AND RoomInventoryMovements.Guest <> &qEmptyClient
	|		AND (RoomInventoryMovements.Hotel.Description = &qHotelName
	|				OR RoomInventoryMovements.Hotel.Code = &qHotelName
	|				OR &qEmptyHotel)
	|		AND (RoomInventoryMovements.Room.Description = &qRoomCode
	|				OR &qEmptyRoomCode)
	|		AND (RoomInventoryMovements.Guest.Code = &qGuestCode
	|				OR &qEmptyGuestName)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VirtualGuests.Guest,
	|		VirtualGuests.Hotel,
	|		VirtualGuests.Room,
	|		VirtualGuests.Ref,
	|		VirtualGuests.GuestGroup,
	|		VirtualGuests.Customer,
	|		VirtualGuests.PlannedPaymentMethod
	|	FROM
	|		Document.Accommodation AS VirtualGuests
	|	WHERE
	|		VirtualGuests.Posted
	|		AND VirtualGuests.AccommodationStatus.IsActive
	|		AND VirtualGuests.Room.IsVirtual
	|		AND VirtualGuests.CheckInDate <= &qServiceDate
	|		AND VirtualGuests.CheckOutDate >= &qServiceDate
	|		AND VirtualGuests.Guest <> &qEmptyClient
	|		AND (VirtualGuests.Hotel.Description = &qHotelName
	|				OR VirtualGuests.Hotel.Code = &qHotelName
	|				OR &qEmptyHotel)
	|		AND (VirtualGuests.Room.Description = &qRoomCode
	|				OR &qEmptyRoomCode)
	|		AND (VirtualGuests.Guest.Code = &qGuestCode
	|				OR &qEmptyGuestName)) AS RoomInventory
	|
	|ORDER BY
	|	HotelDescription,
	|	RoomSortCode,
	|	CheckInDate,
	|	AccommodationTypeSortCode,
	|	GuestFullName";
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qRecordType", AccumulationRecordType.Expense);
	vQry.SetParameter("qHotelName", TrimR(pHotelName));
	vQry.SetParameter("qEmptyHotel", IsBlankString(pHotelName));
	vQry.SetParameter("qGuestCode", pGuestCode);
	vQry.SetParameter("qEmptyGuestName", IsBlankString(pGuestCode));
	vQry.SetParameter("qRoomCode", TrimR(pRoom));
	vQry.SetParameter("qEmptyRoomCode", IsBlankString(pRoom));
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qServiceDate", ?(ValueIsFilled(pServiceDate), pServiceDate, CurrentSessionDate()));
	vGuests = vQry.Execute().Select();
	If vGuests.Next() Then
		vFolioData.Folio = cmGetDocumentChargingFolioForService(vGuests.AccommodationRef, pService, pServiceDate);
		vFolioData.ParentDoc = vGuests.AccommodationRef;
		vFolioData.Client = vGuests.Guest;
	EndIf;
	Return vFolioData;
EndFunction

// -----------------------------------------------------------------------------
Function GetFolioByClientId(pClientID, pService, pHotel, pOrderDate)
	vFolioData = New Structure("Folio, ParentDoc, Client, ErrorDescription, SentSms");
	vAccRef = SMS.GetClientDocumentByMyFolioId(pClientID);
	// Check that accommodation is in-house or check-out was today
	If TypeOf(vAccRef) = Type("DocumentRef.Accommodation") Then
		If Not vAccRef.Posted Or Not vAccRef.AccommodationStatus.IsActive Or Not vAccRef.AccommodationStatus.IsInHouse And BegOfDay(vAccRef.CheckOutDate) < BegOfDay(CurrentSessionDate()) Then
			vFolioData.ErrorDescription =  NStr("en='Guest is not in-house!'; ru='Гость не проживает!'; de='Gast nicht in-house!'");
			Return vFolioData;
		EndIf;
		vFolioData.Client = vAccRef.Guest;
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.Reservation") Then
		If Not vAccRef.Posted Or Not vAccRef.ReservationStatus.IsActive Then
			vFolioData.ErrorDescription =   NStr("en='Reservation is canceled!'; ru='Бронь не активна!'; de='Die Reservierung ist storniert!'");
			Return vFolioData;
		EndIf;
		vFolioData.Client = vAccRef.Guest;
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.ResourceReservation") Then
		If Not vAccRef.Posted Or Not vAccRef.ResourceReservationStatus.IsActive Or vAccRef.ResourceReservationStatus.ServicesAreDelivered And BegOfDay(vAccRef.DateTimeTo) < BegOfDay(CurrentSessionDate()) Then
			vFolioData.ErrorDescription =  NStr("en='Clinet is not in-house!'; ru='Мероприятие уже закончено!'; de='Kunde nicht in-house!'");
			Return vFolioData;
		EndIf;
		vFolioData.Client = vAccRef.Client;
	EndIf;
	vFolioData.ParentDoc = vAccRef;
	vFolioData.Folio = cmGetDocumentChargingFolioForService(vAccRef, pService,pOrderDate);
	Return vFolioData;
EndFunction

// -----------------------------------------------------------------------------
// Used in WritePOSOrder function to find folio by give folio short number
Function GetFolio(pFolioNumber, pHotel)
	vFolioData = New Structure("Folio, ParentDoc, Client, ErrorDescription, SentSms");
	vFolioData.Folio = cmFindFolioByNumber(pFolioNumber, pHotel);
	If ValueIsFilled(vFolioData.Folio) Then
		vParentDoc = vFolioData.Folio.ParentDoc;
		If ValueIsFilled(vFolioData.Folio.Client) Then
			vFolioData.Client = vFolioData.Folio.Client;
		ElsIf ValueIsFilled(vParentDoc) Then
			If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation")  
			  Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
				vFolioData.Client = vParentDoc.Guest;
			ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation")  
			     Or TypeOf(vParentDoc) = Type("DocumentRef.Folio") Then
				vFolioData.Client = vParentDoc.Client;
			EndIf;
		EndIf;
	EndIf;
	Return vFolioData;
EndFunction

// -----------------------------------------------------------------------------
Function GetOrderItem(pOrderItem, pItemService, pHotel)
	vItemService = ?(ValueIsFilled(pItemService),pItemService,Catalogs.Services.EmptyRef());
	// Find by code
	vQ = New Query("SELECT
	               |	OrderItems.Ref AS Ref,
	               |	OrderItems.Code AS Code,
	               |	OrderItems.Description AS Description
	               |FROM
	               |	Catalog.OrderItems AS OrderItems
	               |WHERE
	               |	NOT OrderItems.IsFolder
	               |	AND OrderItems.Code = &qCode
	               |	AND (OrderItems.Service = &qService
	               |			OR OrderItems.Service = &qEmptyService)
	               |	AND (OrderItems.Hotel = &qHotel
	               |			OR OrderItems.Hotel = &qEmptyHotel)");
	vQ.SetParameter("qCode", TrimAll(pOrderItem.ItemId));
	vQ.SetParameter("qHotel", pHotel);
	vQ.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQ.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
	vQ.SetParameter("qService", vItemService);
	
	qRes = vQ.Execute().Select();
	If qRes.Next() Then
		If qRes.Description <> TrimAll(pOrderItem.ItemName) Then
			itemObj = qRes.Ref.GetObject();
			itemObj.Description = TrimAll(pOrderItem.ItemName);
			itemObj.Write();
		EndIf;
		Return qRes.Ref;
	EndIf;
	
	// If not found by code - find by decription
	vQ = New Query("SELECT
	               |	OrderItems.Ref AS Ref
	               |FROM
	               |	Catalog.OrderItems AS OrderItems
	               |WHERE
	               |	NOT OrderItems.IsFolder
	               |	AND OrderItems.Description = &qDescription
	               |	AND (OrderItems.Service = &qService
	               |			OR OrderItems.Service = &qEmptyService)
	               |	AND (OrderItems.Hotel = &qHotel
	               |			OR OrderItems.Hotel = &qEmptyHotel)");
	vQ.SetParameter("qDescription", TrimAll(pOrderItem.ItemName));
	vQ.SetParameter("qHotel", pHotel);
	vQ.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQ.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
	vQ.SetParameter("qService", vItemService);
	
	qRes = vQ.Execute().Select();
	If qRes.Next() Then
		Return qRes.Ref;
	EndIf;
	
	// Not found - create a new one
	vItem = Catalogs.OrderItems.CreateItem();
	vItem.Parent = GetItemFolder(pItemService, pHotel);
	vItem.Code = TrimAll(pOrderItem.ItemId);
	vItem.Description = TrimAll(pOrderItem.ItemName);
	vItem.Hotel = pHotel;
	vItem.Service = vItemService;
	vItem.Write();
	Return vItem.Ref;
EndFunction // GetOrderItem

// --------------------------------------------------------------------------
// Input: Client ref
// Return: Active Discount card wtih bonuses or gift certificate type.
//		if more than one active card - use the new card
Function cmGetClientBonusCard(pClientRef)
	If Not ValueIsFilled(pClientRef) Then
		Return Catalogs.DiscountCards.EmptyRef();
	EndIf;
	vQ = New Query("SELECT
	               |	DiscountCards.Ref AS Ref
	               |FROM
	               |	Catalog.DiscountCards AS DiscountCards
	               |WHERE
	               |	NOT DiscountCards.DeletionMark
	               |	AND (DiscountCards.LoyaltyType = &qBonusLoyaltyType
	               |			OR DiscountCards.LoyaltyType = &qCertificateLoyaltyType)
	               |	AND (DiscountCards.ValidFrom <= &qDate
	               |			OR DiscountCards.ValidFrom = &qEmptyDate)
	               |	AND (DiscountCards.ValidTo >= &qDate
	               |			OR DiscountCards.ValidTo = &qEmptyDate)
	               |	AND DiscountCards.Client = &qClient
	               |
	               |ORDER BY
	               |	DiscountCards.CreateDate DESC");
	vQ.SetParameter("qBonusLoyaltyType", Enums.LoyaltyType.Bonuses);
	vQ.SetParameter("qCertificateLoyaltyType", Enums.LoyaltyType.Certificate);
	vQ.SetParameter("qDate", BegOfDay(CurrentSessionDate()));
	vQ.SetParameter("qEmptyDate", Date(1,1,1));
	vQ.SetParameter("qClient", pClientRef);
	
	qRes = vQ.Execute().Select();
	If qRes.Next() Then
		Return qRes.Ref;
	EndIf;	
EndFunction // cmGetClientBonusCard

// ---------------------------------------------------------------------------
// Returns Orders list XDTO for the web-service functions
// Input: Document Ref - Accommodation Or Reservation
// Return XDTO the list of orders
Function GetOrdersXDTO(pDocRef, pExtSystemCode)
	vOrdersXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Orders"));
	If ValueIsFilled(pDocRef) And (TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation")) Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Order.Number AS Number,
		|	Order.Type AS Type,
		|	Order.Quantity AS Quantity,
		|	Order.GuestsQuantity AS GuestsQuantity,
		|	Order.Sum AS Sum,
		|	Order.OrderTime AS OrderTime
		|FROM
		|	Document.Order AS Order
		|WHERE
		|	NOT Order.DeletionMark
		|	AND Order.ParentDoc = &ParentDoc
		|	AND NOT Order.Status.isOrderComplete
		|	AND NOT Order.Status.isOrderCancel
		|	AND NOT Order.Status.isNewOrder";
		Query.SetParameter("ParentDoc",pDocRef);
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		
		While SelectionDetailRecords.Next() Do
			vOrderXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Order"));
			vOrderXDTO.id             = SelectionDetailRecords.Number;
			vOrderXDTO.Description    = cmGetObjectExternalSystemCodeByRef(pDocRef.Hotel, pExtSystemCode, "OrderTypes", SelectionDetailRecords.Type);
			vOrderXDTO.GuestsQuantity = SelectionDetailRecords.GuestsQuantity;
			vOrderXDTO.OrderDate      = SelectionDetailRecords.OrderTime;
			vOrderXDTO.Quantity       = SelectionDetailRecords.Quantity;
			vOrderXDTO.Sum            = SelectionDetailRecords.Sum;
			vOrdersXDTO.Order.Add(vOrderXDTO);
		EndDo;
	EndIf;
	Return vOrdersXDTO;
EndFunction  

#EndRegion
