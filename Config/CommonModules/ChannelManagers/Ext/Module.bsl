
#Region Public

#Region XML_Functions

// -------------------------------------------------------------------------
Function SendQuery(pXML, pHTTPHost, pResourceAddress, pSOAPAction) Export
	// HTTP
	vHTTPHeader = New Map;
	vHTTPHeader.Insert("Content-Type", "text/xml;charset=utf-8");
	vHTTPHeader.Insert("SOAPAction", pSOAPAction);

	// HTTP connection
	ssl = New OpenSSLSecureConnection(Undefined,Undefined);       
	vHTTPConnection = New HTTPConnection(pHTTPHost, , , , , , ssl);
	
	// Send query
	vHTTPRequest = New HTTPRequest(pResourceAddress, vHTTPHeader);
	vHTTPRequest.SetBodyFromString(pXML);
	rs = vHTTPConnection.Post(vHTTPRequest);
	vHTTPConnection = Undefined;
	
	Return rs.GetBodyAsString();
EndFunction

// -------------------------------------------------------------------------
Function FormatXMLString(pXMLStr) Export
	vResult = pXMLStr;
	vResult = StrReplace(vResult,Chars.LF, "");
	vResult = StrReplace(vResult,Chars.CR, "");
	vResult = StrReplace(vResult,Chars.NBSp, "");
	vResult = StrReplace(vResult,Chars.Tab, "");
	vResult = StrReplace(vResult,Chars.VTab, "");
	vResult = StrReplace(vResult,Char(9), "");
	vResult = StrReplace(vResult,Char(10), "");
	vResult = StrReplace(vResult,Char(13), "");
	vResult = TrimAll(vResult); 
	Return vResult; 	
EndFunction

// -------------------------------------------------------------------------
Function CheckXMLAnswerForErrors(pvXMLResponse) Export
	vReadXML = New XMLReader;
	vReadXML.SetString(pvXMLResponse);
	
	vResult = New Structure("RawResponse, Success, Errors, Warnings", pvXMLResponse, False, New Array, New Array);

	Try
		While vReadXML.Read() Do
			// Errors
			If vReadXML.NodeType = XMLNodeType.StartElement And vReadXML.Name = "Success" Then
				vResult.Success = True;
			ElsIf vReadXML.NodeType = XMLNodeType.StartElement And vReadXML.Name = "Error" Then
				vError = New Structure("Code, Type, Description");
				vError.Code = vReadXML.GetAttribute("Code");
				vError.Type = vReadXML.GetAttribute("Type");
				vReadXML.Read();
				If vReadXML.NodeType = XMLNodeType.Text Then
					vError.Description = vReadXML.Value;
				EndIf;
				vResult.Errors.Add(vError);
			ElsIf vReadXML.NodeType = XMLNodeType.StartElement And vReadXML.Name = "Warning" Then
				vWarning = New Structure("Code, Type, Description");
				vWarning.Code = vReadXML.GetAttribute("Code");
				vWarning.Type = vReadXML.GetAttribute("Type");
				vReadXML.Read();
				If vReadXML.NodeType = XMLNodeType.Text Then
					vWarning.Description = vReadXML.Value;
				EndIf;
				vResult.Warnings.Add(vWarning);
			ElsIf vReadXML.NodeType = XMLNodeType.StartElement And vReadXML.Name = "SOAP-ENV:Fault" Then
				vError = New Structure("Code, Type, Description");
				While vReadXML.Read() Do
					If vReadXML.NodeType = XMLNodeType.EndElement And vReadXML.Name = "SOAP-ENV:Fault" Then
						Break;
					EndIf;
					If vReadXML.NodeType = XMLNodeType.StartElement And vReadXML.Name = "faultcode" Then
						vReadXML.Read();
						If vReadXML.NodeType = XMLNodeType.Text Then
							vError.Code = vReadXML.Value;
						EndIf;
					ElsIf vReadXML.NodeType = XMLNodeType.StartElement And vReadXML.Name = "faultstring" Then
						vReadXML.Read();
						If vReadXML.NodeType = XMLNodeType.Text Then
							vError.Description = vReadXML.Value;
						EndIf;
					ElsIf vReadXML.NodeType = XMLNodeType.StartElement And vReadXML.Name = "Message" Then
						vReadXML.Read();
						If vReadXML.NodeType = XMLNodeType.Text Then
							vError.Description = vError.Description+Chars.CR+vReadXML.Value;
						EndIf;
					EndIf;
				EndDo;
				vResult.Errors.Add(vError);
			EndIF;
		EndDo;
	Except
		vErrorDescription = ErrorDescription();
		vResult.Success = False;
		vError = New Structure("Code, Type, Description");
		vError.Code = "0";
		vError.Type = "0";
		vError.Description = vErrorDescription;
		vResult.Errors.Add(vError);
	EndTry;
	
	Return vResult;
EndFunction

#EndRegion

#Region New_API

// -------------------------------------------------------------------------
Function GetPrices(pInteractionParameters, pRoomRate, pPeriodFrom, pPeriodTo, pFullUpdate = False, pUpdateCachedPrices = False, pCurrency = Undefined, pPriceTag = Undefined, pMealBoardTerms = Undefined) Export
	If pUpdateCachedPrices Then
		FillDailyPrices(pInteractionParameters, pInteractionParameters.Hotel, pRoomRate, Undefined, pPeriodFrom, pPeriodTo);
	EndIf;
	
	vPriceCalculationDate = CurrentSessionDate();
	vInteractionParametersCurrency = pInteractionParameters.Currency;
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
	|	RoomRatesSliceLast.RoomRate AS RoomRate
	|INTO ActiveSetRoomRateFormulas
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPriceCalculationDate,
	|			RoomRate = &qRoomRate
	|				AND Hotel = &qHotel
	|				AND IsFormula) AS RoomRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRateFormulas.RoomRate.BasedOnRoomRate AS BasedOnRoomRate,
	|	RoomRateFormulas.RoomRate.BasedOnPriceTag AS BasedOnPriceTag,
	|	RoomRateFormulas.RoomRate AS RoomRate,
	|	RoomRateFormulas.Hotel AS Hotel,
	|	RoomRateFormulas.IsFormula AS IsFormula,
	|	RoomRateFormulas.Service AS Service,
	|	RoomRateFormulas.RoomType AS RoomType,
	|	RoomRateFormulas.AccommodationType AS AccommodationType,
	|	RoomRateFormulas.ClientType AS ClientType,
	|	RoomRateFormulas.CalendarDayType AS CalendarDayType,
	|	RoomRateFormulas.Recorder AS Recorder,
	|	RoomRateFormulas.Period AS Period,
	|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
	|	RoomRateFormulas.Constant AS Constant,
	|	RoomRateFormulas.Multiplier AS Multiplier,
	|	RoomRateFormulas.ReplaceWithService AS ReplaceWithService
	|INTO RoomRateFormulas
	|FROM
	|	InformationRegister.RoomRateFormulas AS RoomRateFormulas
	|		INNER JOIN ActiveSetRoomRateFormulas AS ActiveSetRoomRateFormulas
	|		ON RoomRateFormulas.Recorder = ActiveSetRoomRateFormulas.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRateDailyPrices.Period AS Period,
	|	RoomRateDailyPrices.RoomType AS RoomType,
	|	RoomRateDailyPrices.AccommodationType AS AccommodationType,
	|	RoomRateDailyPrices.PriceTag AS PriceTag,
	|	(RoomRateDailyPrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0) AS Price,
	|	RoomRateDailyPrices.Currency AS Currency,
	|	RoomRateDailyPrices.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomRateDailyPrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPrices.PriceTag.Description AS PriceTagDescription,
	|	RoomRateDailyPrices.Currency.Code AS CurrencyCode
	|FROM
	|	InformationRegister.RoomRateDailyPrices AS RoomRateDailyPrices
	|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, ) AS CalendarDays
	|		ON RoomRateDailyPrices.RoomRate.Calendar = CalendarDays.Calendar
	|			AND RoomRateDailyPrices.Period = CalendarDays.AccountingDate
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(&qPriceCalculationDate, ) AS CalendarDaysByRoomTypes
	|		ON RoomRateDailyPrices.RoomRate.Calendar = CalendarDaysByRoomTypes.Calendar
	|			AND RoomRateDailyPrices.Period = CalendarDaysByRoomTypes.AccountingDate
	|			AND RoomRateDailyPrices.RoomType = CalendarDaysByRoomTypes.RoomType
	|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
	|		ON (RoomRateFormulas.RoomRate = &qRoomRate)
	|			AND RoomRateDailyPrices.Hotel = RoomRateFormulas.Hotel
	|			AND (NOT RoomRateFormulas.IsFormula
	|				OR RoomRateFormulas.IsFormula
	|					AND RoomRateDailyPrices.RoomType = RoomRateFormulas.RoomType
	|					AND RoomRateDailyPrices.ClientType = &qClientType
	|					AND RoomRateDailyPrices.AccommodationType = RoomRateFormulas.AccommodationType
	|					AND (CalendarDaysByRoomTypes.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|							AND CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|						OR CalendarDays.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDays.CalendarDayType IS NULL
	|							AND (CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|								OR CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
	|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)))
	|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				OR RoomRateDailyPrices.PriceTag = RoomRateFormulas.BasedOnPriceTag
	|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
	|WHERE
	|	RoomRateDailyPrices.Hotel = &qHotel
	|	AND RoomRateDailyPrices.RoomRate = &qRoomRateInCache
	|	AND RoomRateDailyPrices.ClientType = &qClientType
	|	AND RoomRateDailyPrices.Period >= &qPeriodFrom
	|	AND RoomRateDailyPrices.Period <= &qPeriodTo
	|	AND CASE
	|			WHEN &qCurrencyFilled
	|				THEN RoomRateDailyPrices.Currency = &qCurrency
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qPriceTagFilled
	|				THEN RoomRateDailyPrices.PriceTag = &qPriceTag
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	Period,
	|	RoomTypeSortCode,
	|	AccommodationTypeSortCode,
	|	CurrencyCode";
	vQuery.SetParameter("qClientType", pInteractionParameters.ClientType);
	vQuery.SetParameter("qHotel", pInteractionParameters.Hotel);
	vQuery.SetParameter("qRoomRate", pRoomRate);
	If ValueIsFilled(pRoomRate) Then
		vQuery.SetParameter("qRoomRateInCache", ?(ValueIsFilled(pRoomRate.BasedOnRoomRate), pRoomRate.BasedOnRoomRate, pRoomRate));
	Else
		vQuery.SetParameter("qRoomRateInCache", Catalogs.RoomRates.EmptyRef());
	EndIf;
	vQuery.SetParameter("qPeriodFrom", pPeriodFrom);
	vQuery.SetParameter("qPeriodTo", pPeriodTo);
	vQuery.SetParameter("qCurrencyFilled", ValueIsFilled(pCurrency));
	vQuery.SetParameter("qCurrency", pCurrency);
	vQuery.SetParameter("qPriceTag", pPriceTag);
	vQuery.SetParameter("qPriceTagFilled", ValueIsFilled(pPriceTag));
	vQuery.SetParameter("qPriceCalculationDate", vPriceCalculationDate);
	vResult = vQuery.Execute().Unload();
	
	// Add indexes used outside this procedure
	vResult.Indexes.Add("Period, RoomTypeSortCode, AccommodationTypeSortCode, CurrencyCode");
	vResult.Indexes.Add("RoomTypeSortCode, AccommodationTypeSortCode, CurrencyCode, Period");
	vResult.Indexes.Add("RoomTypeSortCode, Period, AccommodationTypeSortCode, CurrencyCode");
	vResult.Indexes.Add("Period, RoomType, AccommodationType, Currency");
	vResult.Indexes.Add("RoomType");
	
	// Process price tags by occupancy percents
	If pRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercent Or
	   pRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomType Or
	   pRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomClass Or
	   pRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType Then
		vResult.Sort("RoomTypeSortCode, Period");
	   
		vRoomType = Undefined;
		vPriceTags = New ValueTable();
		
		r = 0;
		While r < vResult.Count() Do
			vResultRow = vResult.Get(r);
			
			If vResultRow.RoomType <> vRoomType Then
				vRoomType = vResultRow.RoomType;
				
			    // Get price tags for each date
				vPriceTagsList = New ValueList();
				vPriceTags = cmGetEffectivePriceTags(pInteractionParameters.Hotel, pRoomRate, vRoomType, pPeriodFrom, pPeriodTo, vPriceTagsList, , vPriceCalculationDate);
			EndIf;
			
			If vPriceTags.Count() > 0 Then
				vPriceTagsRow = vPriceTags.Find(BegOfDay(vResultRow.Period), "Period");
				If vPriceTagsRow <> Undefined Then
					If vResultRow.PriceTag <> vPriceTagsRow.PriceTag Then
						vResult.Delete(r);
						Continue;
					EndIf;
				Else
					If vResultRow.PriceTag <> Catalogs.PriceTags.EmptyRef() Then
						vResult.Delete(r);
						Continue;
					EndIf;
				EndIf;
			Else
				If vResultRow.PriceTag <> Catalogs.PriceTags.EmptyRef() Then
					vResult.Delete(r);
					Continue;
				EndIf;
			EndIf;
			
			r = r + 1;
		EndDo;
		
		vResult.Sort("Period, RoomTypeSortCode, AccommodationTypeSortCode, CurrencyCode");
	// Process price tags by duration of stay
	ElsIf ValueIsFilled(pRoomRate.PriceTagType) And Not (ValueIsFilled(pPriceTag) And pRoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByPeriod) Then
		r = 0;
		While r < vResult.Count() Do
			vResultRow = vResult.Get(r);
			
			If vResultRow.PriceTag <> Catalogs.PriceTags.EmptyRef() Then
				vResult.Delete(r);
				Continue;
			EndIf;
			r = r + 1;
		EndDo;
	EndIf;
	
	If Not pFullUpdate Then
		vClearArray = New Array;
		vChangedRates = GetPeriodsOfChangedRates(pInteractionParameters, pInteractionParameters.Hotel, pRoomRate, pPeriodFrom, pPeriodTo, pPriceTag);
		For Each vResultRow In vResult Do
			vChanged = False;
			If vChangedRates.Count() > 0 Then
				vChanged = True;
				vChangedRateRows = vChangedRates.FindRows(New Structure("RoomType, Period", vResultRow.RoomType, vResultRow.Period));
				If vChangedRateRows.Count() = 0 Then
					vChanged = False;
				EndIf;
			EndIf;
			If Not vChanged Then
				vClearArray.Add(vResultRow);
			Else
				If pInteractionParameters.ConvertCurrency And vResultRow.Currency <> vInteractionParametersCurrency Then 
					vResultRow.Price = Round(cmConvertCurrencies(vResultRow.Price, vResultRow.Currency,, vInteractionParametersCurrency, , vResultRow.Period, pInteractionParameters.Hotel), 2);
					vResultRow.Currency = vInteractionParametersCurrency;
					vResultRow.CurrencyCode = vInteractionParametersCurrency.Code;
				EndIf;
			EndIf;
		EndDo;
		
		For Each vClearRow In vClearArray Do
			vResult.Delete(vClearRow);	
		EndDo;
	Else
		For Each vResultRow In vResult Do
			If pInteractionParameters.ConvertCurrency And vResultRow.Currency <> vInteractionParametersCurrency Then 
				vResultRow.Price = Round(cmConvertCurrencies(vResultRow.Price, vResultRow.Currency,, vInteractionParametersCurrency, , vResultRow.Period, pInteractionParameters.Hotel), 2);
				vResultRow.Currency = vInteractionParametersCurrency;
				vResultRow.CurrencyCode = vInteractionParametersCurrency.Code;
			EndIf;	
		EndDo;
	EndIf;
	
	If pInteractionParameters.ConvertCurrency Then
		vResult.Sort("Period, RoomTypeSortCode, AccommodationTypeSortCode, CurrencyCode");
	EndIf;
	
	// Add price rounding
	If ValueIsFilled(pRoomRate) And pRoomRate.RoundPrice Then
		For Each vPriceRow In vResult Do
			vPriceRow.Price = Round(vPriceRow.Price, pRoomRate.RoundPriceDigits);
		EndDo;
	EndIf;
	
	// Process service packages for dependent rates and special dates
	vServicePackagesList = New ValueList();
	vServicePackagesCache = Undefined;
	If ValueIsFilled(pRoomRate.BasedOnRoomRate) Then
		// We have to take differencies in the packages into account only
		vServicePackagesListForBasedOnRoomRate = pRoomRate.BasedOnRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
		vServicePackagesList = pRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);

		// Add to the current rate service packages list service packages that were removed from the base room rate
		i = 0;
		While i < vServicePackagesListForBasedOnRoomRate.Count() Do
			vSPRemovedFromBasedRR = vServicePackagesListForBasedOnRoomRate.Get(i).Value;
			If vServicePackagesList.FindByValue(vSPRemovedFromBasedRR) = Undefined Then
				vServicePackagesList.Add(vSPRemovedFromBasedRR, , True);
			EndIf;
			i = i + 1;
		EndDo;
		
		// Delete service packages that are present in the based on room rate list of service packages
		If vServicePackagesListForBasedOnRoomRate.Count() > 0 Then
			i = 0;
			While i < vServicePackagesList.Count() Do
				vServicePackagesListItem = vServicePackagesList.Get(i);
				If Not vServicePackagesListItem.Check Then
					vCurServicePackage = vServicePackagesListItem.Value;
					If vServicePackagesListForBasedOnRoomRate.FindByValue(vCurServicePackage) <> Undefined Then
						vDeleteSP = True;
						For Each vSPRow In vCurServicePackage.Services Do
							If vSPRow.IsInPrice And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
								vDeleteSP = False;
								Break;
							EndIf;
						EndDo;
						If vDeleteSP Then
							vServicePackagesList.Delete(i);
						Else
							vServicePackagesListItem.Presentation = "<<DO_NOT_PROCESS>>";
							i = i + 1;
						EndIf;
					Else
						i = i + 1;
					EndIf;
				Else
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	Else
		vServicePackagesList = pRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
		i = 0;
		While i < vServicePackagesList.Count() Do
			vCurServicePackage = vServicePackagesList.Get(i).Value;
			vDeleteSP = True;
			For Each vSPRow In vCurServicePackage.Services Do
				If vSPRow.IsInPrice And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
					vDeleteSP = False;
					Break;
				EndIf;
			EndDo;
			If vDeleteSP Then
				vServicePackagesList.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	If ValueIsFilled(pMealBoardTerms) Then
		If vServicePackagesList.FindByValue(pMealBoardTerms) = Undefined Then
			vServicePackagesList.Add(pMealBoardTerms);
		EndIf;
	EndIf;
	For Each vPriceRow In vResult Do
		vCurDate = BegOfDay(vPriceRow.Period);
		vCurCalendarDayType = Undefined;
		For Each vServicePackagesItem In vServicePackagesList Do
			vCurServicePackage = vServicePackagesItem.Value;
			// Check if service package is valid
			If vCurServicePackage.DateValidFrom <= vCurDate And (vCurServicePackage.DateValidTo >= vCurDate Or Not ValueIsFilled(vCurServicePackage.DateValidTo)) Then
				// Get service package services
				vCurServicePackageServices = Undefined;
				If vServicePackagesCache <> Undefined Then
					vCurServicePackageServices = vServicePackagesCache.FindRows(New Structure("ServicePackage, Period", vCurServicePackage, vCurDate));
					If vCurServicePackageServices.Count() = 0 Then
						vCurServicePackageServices = Undefined;
					EndIf;
				EndIf;
				If vCurServicePackageServices = Undefined Then
					vCurServicePackageServices = Catalogs.ServicePackages.GetServices(vCurServicePackage, vCurDate, vPriceCalculationDate);
					If vServicePackagesCache = Undefined Then
						vServicePackagesCache = vCurServicePackageServices.Copy();
					Else
						For Each vCurServicePackageServicesRow In vCurServicePackageServices Do
							vServicePackagesCacheRow = vServicePackagesCache.Add();
							FillPropertyValues(vServicePackagesCacheRow, vCurServicePackageServicesRow);
						EndDo;
					EndIf;
				EndIf;
				For Each vSPRow In vCurServicePackageServices Do
					If vSPRow.IsInPrice And ValueIsFilled(pRoomRate) And 
					  (ValueIsFilled(vSPRow.AccountingDate) And vSPRow.AccountingDate = vCurDate Or
					   vSPRow.AccountingDayNumber = 0 And Not ValueIsFilled(vSPRow.AccountingDate) And ValueIsFilled(pRoomRate.BasedOnRoomRate) And vServicePackagesItem.Presentation <> "<<DO_NOT_PROCESS>>" Or
					   vSPRow.AccountingDayNumber = 0 And Not ValueIsFilled(vSPRow.AccountingDate) And ValueIsFilled(pMealBoardTerms) And vCurServicePackage = pMealBoardTerms) Then
						If vServicePackagesItem.Check And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
						   Continue;
						EndIf;
						
						// Check current client type
						If pInteractionParameters.ClientType <> vSPRow.ClientType Then
							Continue;
						EndIf;
											
						// Get and check date calendar day type
						If ValueIsFilled(vSPRow.CalendarDayType) Then
							If vCurCalendarDayType = Undefined Then
								vPriceTag = Undefined;
								vCurCalendarDayType = cmGetCalendarDayType(pRoomRate, vCurDate, Undefined, Undefined, vPriceTag, vPriceRow.RoomType);
							EndIf;
							If vSPRow.CalendarDayType <> vCurCalendarDayType Then
								Continue;
							EndIf;
						EndIf;
						
						// Update price rows in prices
						If (Not ValueIsFilled(vSPRow.RoomType) Or ValueIsFilled(vSPRow.RoomType) And vSPRow.RoomType = vPriceRow.RoomType) And 
						   (Not ValueIsFilled(vSPRow.AccommodationType) Or ValueIsFilled(vSPRow.AccommodationType) And vSPRow.AccommodationType = vPriceRow.AccommodationType) Then
							vPrice = Round(cmConvertCurrencies(vSPRow.Price * ?(vSPRow.Quantity > 0, vSPRow.Quantity, 1), vSPRow.Currency, , vPriceRow.Currency, , vCurDate, pInteractionParameters.Hotel), 2);

							// Apply room rate price rounding rule
							If pRoomRate.RoundPrice Then
								If Not ValueIsFilled(pRoomRate.RoundPriceServiceGroup) Or 
								   ValueIsFilled(pRoomRate.RoundPriceServiceGroup) And cmIsServiceInServiceGroup(vSPRow.Service, pRoomRate.RoundPriceServiceGroup) Then
									vPrice = Round(vPrice, pRoomRate.RoundPriceDigits);
								EndIf;
							EndIf;

							vPriceRow.Price = vPriceRow.Price + ?(vServicePackagesItem.Check, -vPrice, vPrice);
						EndIf;
					EndIf;
				EndDo; // by service package services
			EndIf;
		EndDo; // by service packages
	EndDo; // by prices
	
	Return vResult;
EndFunction // GetPrices

// -------------------------------------------------------------------------
Procedure FillDailyPrices(pInteractionParameters, pHotel, pRoomRate, pRoomType = Undefined, pPeriodFrom, pPeriodTo)
	Try
		vObj 			= DataProcessors.FillRoomRateDailyPrices.Create();
		vObj.Hotel 		= pHotel;
		vObj.RoomType 	= pRoomType;
		vObj.RoomRate 	= pRoomRate;
		vObj.PeriodFrom = BegOfDay(pPeriodFrom);
		vObj.PeriodTo 	= EndOfDay(pPeriodTo);
		vObj.pmDoFill(True);
	Except
		vError 		= ErrorDescription();
		vParameters = New Structure("Hotel, RoomRate, RoomType, PeriodFrom, PeriodTo", pHotel, pRoomRate, pRoomType, pPeriodFrom, pPeriodTo);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "FillDailyPrices", Enums.ExternalSystemEventTypes.Error, vParameters, , vError);	
	EndTry;
EndProcedure

// -------------------------------------------------------------------------
Function GetAvailability(pInteractionParameters, pPeriodFrom, pPeriodTo, pFullUpdate = False, pAllotment = Undefined, pGetVacantRoomsAtMidnight = False) Export
	If pAllotment <> Undefined Then
		vAllotment 	= pAllotment;
	Else
		vAllotment	= pInteractionParameters.Allotment;	
	EndIf;
	
	vDailyBalances = GetDailyBalances(pInteractionParameters.Hotel, vAllotment, Undefined, pPeriodFrom, pPeriodTo, pGetVacantRoomsAtMidnight);
	
	If Not pFullUpdate Then
		vChangedBalances = GetRoomInventoryChanges(vDailyBalances, pInteractionParameters, pInteractionParameters.Hotel, vAllotment, Undefined, pPeriodFrom, pPeriodTo);
		vBalances = GetBalances(vChangedBalances, pInteractionParameters.Hotel, vAllotment, pPeriodFrom , pPeriodTo, TrimAll(pInteractionParameters.InteractionID), Undefined, "", "RoomTypes", True);
	Else
		vBalances = GetBalances(vDailyBalances, pInteractionParameters.Hotel, vAllotment, pPeriodFrom , pPeriodTo, TrimAll(pInteractionParameters.InteractionID), Undefined, "", "RoomTypes", True);	
	EndIf;
	
	Return vBalances;
EndFunction

// -------------------------------------------------------------------------
Function GetRestrictions(pInteractionParameters, pRoomRate, pPeriodFrom, pPeriodTo, pFullUpdate = False) Export
	If Not pFullUpdate Then
		vClearArray = New Array;
		vChangedRestrictions = GetPeriodsOfChangedRestrictions(pInteractionParameters, pInteractionParameters.Hotel, pRoomRate, pPeriodFrom, pPeriodTo);
		If vChangedRestrictions.Count() > 0 Then 
			vResult = GetRestrictionsByRoomRate(pInteractionParameters.Hotel, pPeriodFrom, pPeriodTo, pRoomRate);
			For Each vResultRow In vResult Do
				vChanged = False;
				vChangedRestrictionRows = vChangedRestrictions.FindRows(New Structure("RoomType, Period", vResultRow.RoomType, vResultRow.Period));
				If vChangedRestrictionRows.Count() > 0 Then
					vChanged = True;
				EndIf;
				If Not vChanged Then
					vClearArray.Add(vResultRow);
				EndIf;
			EndDo;
			
			For Each vClearRow In vClearArray Do
				vResult.Delete(vClearRow);	
			EndDo;   
		Else
			vResult = New ValueTable;
			vResult.Columns.Add("RoomType");
			vResult.Columns.Add("Period"); 
			Return vResult;
		EndIf;
	Else
		vResult = GetRestrictionsByRoomRate(pInteractionParameters.Hotel, pPeriodFrom, pPeriodTo, pRoomRate);	
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT DISTINCT
		|	Restrictions.RoomType AS RoomType
		|INTO AllRoomTypes
		|FROM
		|	&Restrictions AS Restrictions
		|WHERE
		|	Restrictions.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllRoomTypes.RoomType AS RoomType
		|FROM
		|	AllRoomTypes AS AllRoomTypes";
	vQuery.SetParameter("Restrictions", vResult);
	vRoomTypes = vQuery.Execute().Unload().UnloadColumn("RoomType");
	
	If vRoomTypes.Count() > 0 Then
		vAllRoomTypesRestrictions = vResult.FindRows(New Structure("RoomType", Catalogs.RoomTypes.EmptyRef()));
		For Each vRoomType In vRoomTypes Do
			vCurrentRoomTypeRestrictions = vResult.FindRows(New Structure("RoomType", vRoomType));
			For Each vRestriction In vCurrentRoomTypeRestrictions Do
				For Each vAllResriction In vAllRoomTypesRestrictions Do
					If vRestriction.Period = vAllResriction.Period Then
						vRestriction.StopSale 				= Max(vRestriction.StopSale, vAllResriction.StopSale);
						vRestriction.MLOS 					= Max(vRestriction.MLOS, vAllResriction.MLOS);
						vRestriction.MaxLOS 				= Max(vRestriction.MaxLOS, vAllResriction.MaxLOS);
						vRestriction.CTA 					= Max(vRestriction.CTA, vAllResriction.CTA);
						vRestriction.CTD 					= Max(vRestriction.CTD, vAllResriction.CTD);
						vRestriction.MinDaysBeforeCheckIn 	= Max(vRestriction.MinDaysBeforeCheckIn, vAllResriction.MinDaysBeforeCheckIn);
						vRestriction.MaxDaysBeforeCheckIn 	= Max(vRestriction.MaxDaysBeforeCheckIn, vAllResriction.MaxDaysBeforeCheckIn);
						vRestriction.IsForOnlineOnly 		= Max(vRestriction.IsForOnlineOnly, vAllResriction.IsForOnlineOnly);
					EndIf;
				EndDo;
			EndDo;
		EndDo;
	EndIf;
	
	vResult.Sort("Period Asc, RoomType Asc");
	
	Return vResult;
EndFunction

// -------------------------------------------------------------------------
Function GetRestrictionsByRoomRate(Val pHotel, Val pPeriodFrom, Val pPeriodTo, Val pRoomRate)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	RoomRateRestrictions.RoomType AS RoomType,
	|	RoomRateRestrictions.AccountingDate AS Period,
	|	MAX(RoomRateRestrictions.StopSale) AS StopSale,
	|	MAX(RoomRateRestrictions.MLOS) AS MLOS,
	|	MAX(RoomRateRestrictions.MaxLOS) AS MaxLOS,
	|	MIN(RoomRateRestrictions.CTA) AS CTA,
	|	MAX(RoomRateRestrictions.CTD) AS CTD,
	|	MAX(RoomRateRestrictions.MinDaysBeforeCheckIn) AS MinDaysBeforeCheckIn,
	|	MAX(RoomRateRestrictions.MaxDaysBeforeCheckIn) AS MaxDaysBeforeCheckIn,
	|	MAX(RoomRateRestrictions.IsForOnlineOnly) AS IsForOnlineOnly
	|FROM
	|	InformationRegister.RoomRateRestrictions AS RoomRateRestrictions
	|WHERE
	|	RoomRateRestrictions.Hotel = &qHotel
	|	AND (RoomRateRestrictions.RoomRate = &qRoomRate
	|			OR RoomRateRestrictions.RoomRate = VALUE(Catalog.RoomRates.EmptyRef))
	|	AND RoomRateRestrictions.AccountingDate >= &qPeriodFrom
	|	AND RoomRateRestrictions.AccountingDate <= &qPeriodTo
	|
	|GROUP BY
	|	RoomRateRestrictions.RoomType,
	|	RoomRateRestrictions.AccountingDate";
	vQuery.SetParameter("qRoomRate", 	pRoomRate);
	vQuery.SetParameter("qHotel", 		pHotel);
	vQuery.SetParameter("qPeriodFrom", 	pPeriodFrom);
	vQuery.SetParameter("qPeriodTo", 	pPeriodTo);
	vResult = vQuery.Execute().Unload();
	Return vResult;
EndFunction

// -------------------------------------------------------------------------
Function CopyXDTO(pXDTO, pXDTOType) Export
	vResult = Undefined;
	
	vXMLWriter = New XMLWriter;
	vXMLWriter.SetString();
	XDTOFactory.WriteXML(vXMLWriter, pXDTO); 
	vXML = vXMLWriter.Close();
	
	vXMLReader = New XMLReader;
	vXMLReader.SetString(vXML);
	vResult = XDTOFactory.ReadXML(vXMLReader, pXDTOType);
	
	Return vResult;
EndFunction

#EndRegion

// -------------------------------------------------------------------------
Function GetDateTablesToSync(pInteractionParameters, pSyncRates, pSyncRestrictions, pSyncPeriod = 0, pGetVacantRoomsAtMidnight = False) Export
	vCurrentDate = CurrentSessionDate();
	
	If pSyncPeriod = 0 Then
		pSyncPeriod = 400;
	EndIf;
	vPeriodFrom = BegOfDay(vCurrentDate);
	vPeriodTo = EndOfDay(vPeriodFrom + 24 * 3600 * pSyncPeriod);
	
	vResult = New Structure("RoomInventory, RoomRate, RoomRestriction, SyncDate", New ValueTable, New ValueTable, New ValueTable, vCurrentDate);
	vResult.RoomInventory.Columns.Add("Hotel");
	vResult.RoomInventory.Columns.Add("RoomType");
	vResult.RoomInventory.Columns.Add("PeriodFrom");
	vResult.RoomInventory.Columns.Add("PeriodTo");
	
	vResult.RoomRate.Columns.Add("Hotel");
	vResult.RoomRate.Columns.Add("RoomRate");
	vResult.RoomRate.Columns.Add("RoomType");
	vResult.RoomRate.Columns.Add("PeriodFrom");
	vResult.RoomRate.Columns.Add("PeriodTo");
	vResult.RoomRate.Columns.Add("RateCode");
	
	vResult.RoomRestriction.Columns.Add("Hotel");
	vResult.RoomRestriction.Columns.Add("RoomRate");
	vResult.RoomRestriction.Columns.Add("RoomType");
	vResult.RoomRestriction.Columns.Add("PeriodFrom");
	vResult.RoomRestriction.Columns.Add("PeriodTo");
	vResult.RoomRestriction.Columns.Add("RateCode");

	#Region RoomInventory
		vDailyBalances = GetDailyBalances(pInteractionParameters.Hotel, pInteractionParameters.Allotment, Undefined, vPeriodFrom, vPeriodTo, pGetVacantRoomsAtMidnight);
		vChangedBalances = GetRoomInventoryChanges(vDailyBalances, pInteractionParameters, pInteractionParameters.Hotel, pInteractionParameters.Allotment, Undefined, vPeriodFrom, vPeriodTo);
		If vChangedBalances.Count() > 0 Then
			vBalances = GetBalances(vChangedBalances, pInteractionParameters.Hotel, pInteractionParameters.Allotment, vPeriodFrom, vPeriodTo, TrimAll(pInteractionParameters.InteractionID), Undefined, "", "RoomTypes");
			For Each vBalancesRow In vBalances Do
				vRow = vResult.RoomInventory.Add();
				vRow.Hotel = pInteractionParameters.Hotel;
				vRow.RoomType = vBalancesRow.RoomType;
				vRow.PeriodFrom = vBalancesRow.PeriodFrom;
				vRow.PeriodTo = vBalancesRow.PeriodTo;
			EndDo;
		EndIf;
	#EndRegion
	
	#Region RoomRates
	If pSyncRates Then 
		vRoomRatesQryRes = GetMappedObjects(pInteractionParameters.Hotel, TrimAll(pInteractionParameters.InteractionID), "RoomRates");
		While vRoomRatesQryRes.Next() Do
			vRoomRate = vRoomRatesQryRes.ObjectRef;
			vRoomRateCode = TrimAll(vRoomRatesQryRes.ObjectExternalCode);
			vChangedRates = GetPeriodsOfChangedRates(pInteractionParameters, pInteractionParameters.Hotel, vRoomRate, vPeriodFrom, vPeriodTo);
			For Each vChangedRatesRow In vChangedRates Do
				vRow = vResult.RoomRate.Add();
				vRow.Hotel = pInteractionParameters.Hotel;
				vRow.RoomRate = vRoomRate;
				vRow.RoomType = vChangedRatesRow.RoomType;
				vRow.PeriodFrom = vChangedRatesRow.Period;
				vRow.PeriodTo = vChangedRatesRow.Period;
				vRow.RateCode = vRoomRateCode;
			EndDo;
		EndDo;
	EndIf;
	#EndRegion
	
	#Region RoomRateRestrictions
	If pSyncRestrictions Then 
		vRoomRatesQryRes = GetMappedObjects(pInteractionParameters.Hotel, TrimAll(pInteractionParameters.InteractionID), "RoomRates");
		While vRoomRatesQryRes.Next() Do
			vRoomRate = vRoomRatesQryRes.ObjectRef;
			vRoomRateCode = TrimAll(vRoomRatesQryRes.ObjectExternalCode);
			vChangedRestrictions = GetPeriodsOfChangedRestrictions(pInteractionParameters, pInteractionParameters.Hotel, vRoomRate, vPeriodFrom, vPeriodTo);
			For Each vChangedRestrictionsRow In vChangedRestrictions Do
				vRow = vResult.RoomRestriction.Add();
				vRow.Hotel = pInteractionParameters.Hotel;
				vRow.RoomRate = vRoomRate;
				vRow.RoomType = vChangedRestrictionsRow.RoomType;
				vRow.PeriodFrom = vChangedRestrictionsRow.Period;
				vRow.PeriodTo = vChangedRestrictionsRow.Period;
				vRow.RateCode = vRoomRateCode;
			EndDo;
		EndDo;
	EndIf;
	#EndRegion
	
	Return vResult;
EndFunction // GetDateTablesToSync

// -------------------------------------------------------------------------
// Retrieve actual daily balances
// -------------------------------------------------------------------------
Function GetDailyBalances(pHotel, pAllotment, pRoomType, pPeriodFrom, pPeriodTo, pGetVacantRoomsAtMidnight = False) Export
	// Call API to get value table with balances
	vBalances = cmGetRoomQuotaBalances(pHotel, pRoomType , , , , pAllotment, pPeriodFrom, pPeriodTo, pGetVacantRoomsAtMidnight);
	// Remove dates not in period and replace values if allotment is used
	vClearArray = New Array;
	For Each vRow In vBalances Do
		If vRow.Period = Null Then
			vClearArray.Add(vRow);
			Continue;
		EndIf;
		If (BegOfDay(vRow.Period) < BegOfDay(pPeriodFrom)) Then
			vClearArray.Add(vRow);
		EndIf;
		If ValueIsFilled(pAllotment) Then
			vRow.RoomsVacant = ?(vRow.RoomsRemains = Null, 0, ?(vRow.RoomsRemains > 0, vRow.RoomsRemains, 0));
			vRow.BedsVacant = ?(vRow.BedsRemains = Null, 0, ?(vRow.BedsRemains > 0, vRow.BedsRemains, 0));
		Else
			vRow.RoomsVacant = ?(vRow.RoomsVacant = Null, 0, ?(vRow.RoomsVacant > 0, vRow.RoomsVacant, 0));
			vRow.BedsVacant = ?(vRow.BedsVacant = Null, 0, ?(vRow.BedsVacant > 0, vRow.BedsVacant, 0));
		EndIf;
	EndDo;
	For Each vRow In vClearArray Do
		vBalances.Delete(vRow);	
	EndDo;
	Return vBalances;
EndFunction // GetDailyBalances

// -------------------------------------------------------------------------
// Get dates where balances are different
// -------------------------------------------------------------------------
Function GetRoomInventoryChanges(pBalances, pInteractionParameters, pHotel, pAllotment = Undefined, pRoomType = Undefined, pPeriodFrom, pPeriodTo) Export 
	// APDEX
	vKeyOperation = "ChannelManagers.GetRoomInventoryChanges";
	vUUID = New UUID;
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, vUUID);

	vRIChanges = New ValueTable;
	vRIChanges.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels"));
	vRIChanges.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vRIChanges.Columns.Add("Period");
	vRIChanges.Columns.Add("RoomsVacant", cmGetNumberTypeDescription(6, 0));
	vRIChanges.Columns.Add("BedsVacant", cmGetNumberTypeDescription(6, 0));	
	vRIChanges.Columns.Add("HotelCode", cmGetStringTypeDescription(5));
	vRIChanges.Columns.Add("RoomTypeSortCode", cmGetNumberTypeDescription(8, 0, True));
	
	// Run query to get changed dates
	vChangedDates = New ValueTable();
	vQry = New Query();
	If ValueIsFilled(pAllotment) Then
		vQry.Text = 
		"SELECT
		|	RoomInventoryBalanceAndTurnovers.Period AS Period,
		|	RoomInventoryBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance
		|INTO PeriodDates
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFRom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel = &qHotel) AS RoomInventoryBalanceAndTurnovers
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	RQMovements.RoomType AS RoomType,
		|	BEGINOFPERIOD(RQMovements.DateFrom, DAY) AS PeriodFrom,
		|	BEGINOFPERIOD(RQMovements.DateTo, DAY) AS PeriodTo
		|INTO RawChangedPeriods
		|FROM
		|	AccumulationRegister.RoomQuotaSales AS RQMovements
		|WHERE
		|	RQMovements.Timestamp > &qTimestampFrom
		|	AND RQMovements.Hotel = &qHotel
		|	AND RQMovements.RoomQuota IN(&qAllotmentsList)
		|	AND (RQMovements.RoomType = &qRoomType
		|				AND &qRoomTypeIsFilled
		|			OR NOT &qRoomTypeIsFilled)
		|	AND (RQMovements.IsRoomQuota
		|			OR RQMovements.IsReservation
		|			OR RQMovements.IsAccommodation)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RawChangedPeriods.RoomType AS RoomType,
		|	CASE
		|		WHEN RawChangedPeriods.PeriodFrom < &qPeriodFrom
		|			THEN &qPeriodFrom
		|		ELSE RawChangedPeriods.PeriodFrom
		|	END AS PeriodFrom,
		|	CASE
		|		WHEN RawChangedPeriods.PeriodTo > &qPeriodTo
		|			THEN &qPeriodTo
		|		ELSE RawChangedPeriods.PeriodTo
		|	END AS PeriodTo
		|INTO ChangedPeriods
		|FROM
		|	RawChangedPeriods AS RawChangedPeriods
		|WHERE
		|	RawChangedPeriods.PeriodFrom < &qPeriodTo
		|	AND RawChangedPeriods.PeriodTo > &qPeriodFrom
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ChangedReservations.Reservation AS Reservation
		|INTO ChangedReservations
		|FROM
		|	InformationRegister.ReservationChangeHistory AS ChangedReservations
		|WHERE
		|	ChangedReservations.Period > &qTimestampFrom
		|	AND ChangedReservations.Hotel = &qHotel
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationStatesBeforeChange.RoomType AS RoomType,
		|	BEGINOFPERIOD(ReservationStatesBeforeChange.CheckInDate, DAY) AS PeriodFrom,
		|	BEGINOFPERIOD(ReservationStatesBeforeChange.CheckOutDate, DAY) AS PeriodTo
		|INTO ReservationStatesBeforeChange
		|FROM
		|	InformationRegister.ReservationChangeHistory.SliceLast(&qTimestampFrom, Hotel = &qHotel) AS ReservationStatesBeforeChange
		|		INNER JOIN ChangedReservations AS ChangedReservations
		|		ON ReservationStatesBeforeChange.Reservation = ChangedReservations.Reservation
		|WHERE
		|	ReservationStatesBeforeChange.Hotel = &qHotel
		|	AND ReservationStatesBeforeChange.RoomQuota IN(&qAllotmentsList)
		|	AND (ReservationStatesBeforeChange.RoomType = &qRoomType
		|				AND &qRoomTypeIsFilled
		|			OR NOT &qRoomTypeIsFilled)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CancelledReservations.RoomType AS RoomType,
		|	BEGINOFPERIOD(CancelledReservations.CheckInDate, DAY) AS PeriodFrom,
		|	BEGINOFPERIOD(CancelledReservations.CheckOutDate, DAY) AS PeriodTo
		|INTO CancelledReservations
		|FROM
		|	InformationRegister.ReservationChangeHistory AS CancelledReservations
		|WHERE
		|	CancelledReservations.Period > &qTimestampFrom
		|	AND CancelledReservations.Hotel = &qHotel
		|	AND CancelledReservations.RoomQuota IN(&qAllotmentsList)
		|	AND (CancelledReservations.RoomType = &qRoomType
		|				AND &qRoomTypeIsFilled
		|			OR NOT &qRoomTypeIsFilled)
		|	AND (NOT ISNULL(CancelledReservations.Reservation.ReservationStatus.IsActive, TRUE)
		|			OR ISNULL(CancelledReservations.Reservation.ReservationStatus.IsCheckIn, FALSE))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ChangedAccommodations.Accommodation AS Accommodation
		|INTO ChangedAccommodations
		|FROM
		|	InformationRegister.AccommodationChangeHistory AS ChangedAccommodations
		|WHERE
		|	ChangedAccommodations.Period > &qTimestampFrom
		|	AND ChangedAccommodations.Hotel = &qHotel
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AccommodationStatesBeforeChange.RoomType AS RoomType,
		|	BEGINOFPERIOD(AccommodationStatesBeforeChange.CheckInDate, DAY) AS PeriodFrom,
		|	BEGINOFPERIOD(AccommodationStatesBeforeChange.CheckOutDate, DAY) AS PeriodTo
		|INTO AccommodationStatesBeforeChange
		|FROM
		|	InformationRegister.AccommodationChangeHistory.SliceLast(&qTimestampFrom, Hotel = &qHotel) AS AccommodationStatesBeforeChange
		|		INNER JOIN ChangedAccommodations AS ChangedAccommodations
		|		ON AccommodationStatesBeforeChange.Accommodation = ChangedAccommodations.Accommodation
		|WHERE
		|	AccommodationStatesBeforeChange.Hotel = &qHotel
		|	AND AccommodationStatesBeforeChange.RoomQuota IN(&qAllotmentsList)
		|	AND (AccommodationStatesBeforeChange.RoomType = &qRoomType
		|				AND &qRoomTypeIsFilled
		|			OR NOT &qRoomTypeIsFilled)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CancelledAccommodations.RoomType AS RoomType,
		|	BEGINOFPERIOD(CancelledAccommodations.CheckInDate, DAY) AS PeriodFrom,
		|	BEGINOFPERIOD(CancelledAccommodations.CheckOutDate, DAY) AS PeriodTo
		|INTO CancelledAccommodations
		|FROM
		|	InformationRegister.AccommodationChangeHistory AS CancelledAccommodations
		|WHERE
		|	CancelledAccommodations.Period > &qTimestampFrom
		|	AND CancelledAccommodations.Hotel = &qHotel
		|	AND CancelledAccommodations.RoomQuota IN(&qAllotmentsList)
		|	AND (CancelledAccommodations.RoomType = &qRoomType
		|				AND &qRoomTypeIsFilled
		|			OR NOT &qRoomTypeIsFilled)
		|	AND NOT ISNULL(CancelledAccommodations.Accommodation.AccommodationStatus.IsActive, TRUE)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ChangedDates.RoomType.Owner AS Hotel,
		|	ChangedDates.RoomType.Owner.Code AS HotelCode,
		|	ChangedDates.RoomType AS RoomType,
		|	ChangedDates.RoomTypeSortCode AS RoomTypeSortCode,
		|	ChangedDates.Period AS Period
		|FROM
		|	(SELECT
		|		ChangedPeriods.RoomType AS RoomType,
		|		ChangedPeriods.RoomType.SortCode AS RoomTypeSortCode,
		|		PeriodDates.Period AS Period
		|	FROM
		|		PeriodDates AS PeriodDates
		|			INNER JOIN ChangedPeriods AS ChangedPeriods
		|			ON PeriodDates.Period >= ChangedPeriods.PeriodFrom
		|				AND PeriodDates.Period <= ChangedPeriods.PeriodTo
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReservationStatesBeforeChange.RoomType,
		|		ReservationStatesBeforeChange.RoomType.SortCode,
		|		PeriodDates.Period
		|	FROM
		|		PeriodDates AS PeriodDates
		|			INNER JOIN ReservationStatesBeforeChange AS ReservationStatesBeforeChange
		|			ON PeriodDates.Period >= ReservationStatesBeforeChange.PeriodFrom
		|				AND PeriodDates.Period <= ReservationStatesBeforeChange.PeriodTo
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CancelledReservations.RoomType,
		|		CancelledReservations.RoomType.SortCode,
		|		PeriodDates.Period
		|	FROM
		|		PeriodDates AS PeriodDates
		|			INNER JOIN CancelledReservations AS CancelledReservations
		|			ON PeriodDates.Period >= CancelledReservations.PeriodFrom
		|				AND PeriodDates.Period <= CancelledReservations.PeriodTo
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		AccommodationStatesBeforeChange.RoomType,
		|		AccommodationStatesBeforeChange.RoomType.SortCode,
		|		PeriodDates.Period
		|	FROM
		|		PeriodDates AS PeriodDates
		|			INNER JOIN AccommodationStatesBeforeChange AS AccommodationStatesBeforeChange
		|			ON PeriodDates.Period >= AccommodationStatesBeforeChange.PeriodFrom
		|				AND PeriodDates.Period <= AccommodationStatesBeforeChange.PeriodTo
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CancelledAccommodations.RoomType,
		|		CancelledAccommodations.RoomType.SortCode,
		|		PeriodDates.Period
		|	FROM
		|		PeriodDates AS PeriodDates
		|			INNER JOIN CancelledAccommodations AS CancelledAccommodations
		|			ON PeriodDates.Period >= CancelledAccommodations.PeriodFrom
		|				AND PeriodDates.Period <= CancelledAccommodations.PeriodTo) AS ChangedDates
		|
		|ORDER BY
		|	ChangedDates.RoomTypeSortCode,
		|	ChangedDates.Period";
		If TypeOf(pAllotment) = Type("ValueList") Or TypeOf(pAllotment) = Type("Array") Then
			vQry.SetParameter("qAllotmentsList", pAllotment);
		Else
			vList = New ValueList();
			vList.Add(pAllotment);
			vQry.SetParameter("qAllotmentsList", vList);
		EndIf;
	Else
		vQry.Text = 
		"SELECT
		|	RoomInventoryBalanceAndTurnovers.Period AS Period,
		|	RoomInventoryBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance
		|INTO PeriodDates
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFRom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel = &qHotel) AS RoomInventoryBalanceAndTurnovers
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	RIMovements.RoomType AS RoomType,
		|	CASE
		|		WHEN RIMovements.IsRoomInventory
		|			THEN BEGINOFPERIOD(RIMovements.Recorder.Date, DAY)
		|		ELSE BEGINOFPERIOD(RIMovements.PeriodFrom, DAY)
		|	END AS PeriodFrom,
		|	CASE
		|		WHEN RIMovements.IsRoomInventory
		|			THEN BEGINOFPERIOD(RIMovements.Recorder.OperationEndDate, DAY)
		|		ELSE BEGINOFPERIOD(RIMovements.PeriodTo, DAY)
		|	END AS PeriodTo
		|INTO RawChangedPeriods
		|FROM
		|	AccumulationRegister.RoomInventory AS RIMovements
		|WHERE
		|	RIMovements.Timestamp > &qTimestampFrom
		|	AND RIMovements.Hotel = &qHotel
		|	AND (RIMovements.RoomType = &qRoomType
		|				AND &qRoomTypeIsFilled
		|			OR NOT &qRoomTypeIsFilled)
		|	AND (RIMovements.IsRoomInventory
		|			OR RIMovements.IsBlocking
		|			OR RIMovements.IsRoomQuota
		|			OR RIMovements.IsReservation
		|			OR RIMovements.IsAccommodation)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RawChangedPeriods.RoomType AS RoomType,
		|	CASE
		|		WHEN RawChangedPeriods.PeriodFrom < &qPeriodFrom
		|			THEN &qPeriodFrom
		|		ELSE RawChangedPeriods.PeriodFrom
		|	END AS PeriodFrom,
		|	CASE
		|		WHEN RawChangedPeriods.PeriodTo > &qPeriodTo
		|			THEN &qPeriodTo
		|		WHEN RawChangedPeriods.PeriodTo = &qEmptyDate
		|			THEN &qPeriodTo
		|		ELSE RawChangedPeriods.PeriodTo
		|	END AS PeriodTo
		|INTO CuttedChangedPeriods
		|FROM
		|	RawChangedPeriods AS RawChangedPeriods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CuttedChangedPeriods.RoomType AS RoomType,
		|	CuttedChangedPeriods.PeriodFrom AS PeriodFrom,
		|	CuttedChangedPeriods.PeriodTo AS PeriodTo
		|INTO ChangedPeriods
		|FROM
		|	CuttedChangedPeriods AS CuttedChangedPeriods
		|WHERE
		|	CuttedChangedPeriods.PeriodFrom < &qPeriodTo
		|	AND CuttedChangedPeriods.PeriodTo > &qPeriodFrom
		|	AND CuttedChangedPeriods.PeriodFrom <= CuttedChangedPeriods.PeriodTo
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ChangedReservations.Reservation AS Reservation
		|INTO ChangedReservations
		|FROM
		|	InformationRegister.ReservationChangeHistory AS ChangedReservations
		|WHERE
		|	ChangedReservations.Period > &qTimestampFrom
		|	AND ChangedReservations.Hotel = &qHotel
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationStatesBeforeChange.RoomType AS RoomType,
		|	BEGINOFPERIOD(ReservationStatesBeforeChange.CheckInDate, DAY) AS PeriodFrom,
		|	BEGINOFPERIOD(ReservationStatesBeforeChange.CheckOutDate, DAY) AS PeriodTo
		|INTO ReservationStatesBeforeChange
		|FROM
		|	InformationRegister.ReservationChangeHistory.SliceLast(&qTimestampFrom, Hotel = &qHotel) AS ReservationStatesBeforeChange
		|		INNER JOIN ChangedReservations AS ChangedReservations
		|		ON ReservationStatesBeforeChange.Reservation = ChangedReservations.Reservation
		|WHERE
		|	ReservationStatesBeforeChange.Hotel = &qHotel
		|	AND (ReservationStatesBeforeChange.RoomType = &qRoomType
		|				AND &qRoomTypeIsFilled
		|			OR NOT &qRoomTypeIsFilled)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CancelledReservations.RoomType AS RoomType,
		|	BEGINOFPERIOD(CancelledReservations.CheckInDate, DAY) AS PeriodFrom,
		|	BEGINOFPERIOD(CancelledReservations.CheckOutDate, DAY) AS PeriodTo
		|INTO CancelledReservations
		|FROM
		|	InformationRegister.ReservationChangeHistory AS CancelledReservations
		|WHERE
		|	CancelledReservations.Period > &qTimestampFrom
		|	AND CancelledReservations.Hotel = &qHotel
		|	AND (CancelledReservations.RoomType = &qRoomType
		|				AND &qRoomTypeIsFilled
		|			OR NOT &qRoomTypeIsFilled)
		|	AND (NOT ISNULL(CancelledReservations.Reservation.ReservationStatus.IsActive, TRUE)
		|			OR ISNULL(CancelledReservations.Reservation.ReservationStatus.IsCheckIn, FALSE))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ChangedAccommodations.Accommodation AS Accommodation
		|INTO ChangedAccommodations
		|FROM
		|	InformationRegister.AccommodationChangeHistory AS ChangedAccommodations
		|WHERE
		|	ChangedAccommodations.Period > &qTimestampFrom
		|	AND ChangedAccommodations.Hotel = &qHotel
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AccommodationStatesBeforeChange.RoomType AS RoomType,
		|	BEGINOFPERIOD(AccommodationStatesBeforeChange.CheckInDate, DAY) AS PeriodFrom,
		|	BEGINOFPERIOD(AccommodationStatesBeforeChange.CheckOutDate, DAY) AS PeriodTo
		|INTO AccommodationStatesBeforeChange
		|FROM
		|	InformationRegister.AccommodationChangeHistory.SliceLast(&qTimestampFrom, Hotel = &qHotel) AS AccommodationStatesBeforeChange
		|		INNER JOIN ChangedAccommodations AS ChangedAccommodations
		|		ON AccommodationStatesBeforeChange.Accommodation = ChangedAccommodations.Accommodation
		|WHERE
		|	AccommodationStatesBeforeChange.Hotel = &qHotel
		|	AND (AccommodationStatesBeforeChange.RoomType = &qRoomType
		|				AND &qRoomTypeIsFilled
		|			OR NOT &qRoomTypeIsFilled)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CancelledAccommodations.RoomType AS RoomType,
		|	BEGINOFPERIOD(CancelledAccommodations.CheckInDate, DAY) AS PeriodFrom,
		|	BEGINOFPERIOD(CancelledAccommodations.CheckOutDate, DAY) AS PeriodTo
		|INTO CancelledAccommodations
		|FROM
		|	InformationRegister.AccommodationChangeHistory AS CancelledAccommodations
		|WHERE
		|	CancelledAccommodations.Period > &qTimestampFrom
		|	AND CancelledAccommodations.Hotel = &qHotel
		|	AND (CancelledAccommodations.RoomType = &qRoomType
		|				AND &qRoomTypeIsFilled
		|			OR NOT &qRoomTypeIsFilled)
		|	AND NOT ISNULL(CancelledAccommodations.Accommodation.AccommodationStatus.IsActive, TRUE)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ChangedDates.RoomType.Owner AS Hotel,
		|	ChangedDates.RoomType.Owner.Code AS HotelCode,
		|	ChangedDates.RoomType AS RoomType,
		|	ChangedDates.RoomTypeSortCode AS RoomTypeSortCode,
		|	ChangedDates.Period AS Period
		|FROM
		|	(SELECT
		|		ChangedPeriods.RoomType AS RoomType,
		|		ChangedPeriods.RoomType.SortCode AS RoomTypeSortCode,
		|		PeriodDates.Period AS Period
		|	FROM
		|		PeriodDates AS PeriodDates
		|			INNER JOIN ChangedPeriods AS ChangedPeriods
		|			ON PeriodDates.Period >= ChangedPeriods.PeriodFrom
		|				AND PeriodDates.Period <= ChangedPeriods.PeriodTo
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReservationStatesBeforeChange.RoomType,
		|		ReservationStatesBeforeChange.RoomType.SortCode,
		|		PeriodDates.Period
		|	FROM
		|		PeriodDates AS PeriodDates
		|			INNER JOIN ReservationStatesBeforeChange AS ReservationStatesBeforeChange
		|			ON PeriodDates.Period >= ReservationStatesBeforeChange.PeriodFrom
		|				AND PeriodDates.Period <= ReservationStatesBeforeChange.PeriodTo
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CancelledReservations.RoomType,
		|		CancelledReservations.RoomType.SortCode,
		|		PeriodDates.Period
		|	FROM
		|		PeriodDates AS PeriodDates
		|			INNER JOIN CancelledReservations AS CancelledReservations
		|			ON PeriodDates.Period >= CancelledReservations.PeriodFrom
		|				AND PeriodDates.Period <= CancelledReservations.PeriodTo
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		AccommodationStatesBeforeChange.RoomType,
		|		AccommodationStatesBeforeChange.RoomType.SortCode,
		|		PeriodDates.Period
		|	FROM
		|		PeriodDates AS PeriodDates
		|			INNER JOIN AccommodationStatesBeforeChange AS AccommodationStatesBeforeChange
		|			ON PeriodDates.Period >= AccommodationStatesBeforeChange.PeriodFrom
		|				AND PeriodDates.Period <= AccommodationStatesBeforeChange.PeriodTo
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CancelledAccommodations.RoomType,
		|		CancelledAccommodations.RoomType.SortCode,
		|		PeriodDates.Period
		|	FROM
		|		PeriodDates AS PeriodDates
		|			INNER JOIN CancelledAccommodations AS CancelledAccommodations
		|			ON PeriodDates.Period >= CancelledAccommodations.PeriodFrom
		|				AND PeriodDates.Period <= CancelledAccommodations.PeriodTo) AS ChangedDates
		|
		|ORDER BY
		|	ChangedDates.RoomTypeSortCode,
		|	ChangedDates.Period";
	EndIf;
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoomTypeIsFilled", ValueIsFilled(pRoomType));
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", BegOfDay(pPeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qTimestampFrom", pInteractionParameters.LastExportTimestampForInventory);
	vChangedDates = vQry.Execute().Unload();
	
	// Filter balances by changed dates
	For Each vR In pBalances Do
		If vR.Period = Null Then
			vC = vRIChanges.Add();
			FillPropertyValues(vC, vR);
		ElsIf vChangedDates.Count() > 0 Then
			vChangedDatesRows = vChangedDates.FindRows(New Structure("RoomType, Period", vR.RoomType, vR.Period));
			If vChangedDatesRows.Count() > 0 Then
				vC = vRIChanges.Add();
				FillPropertyValues(vC, vR);
			EndIf;
		EndIf;
	EndDo;
	
	// APDEX
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	
	Return vRIChanges;
EndFunction // GetRoomInventoryChanges

// -------------------------------------------------------------------------
// Prepare balances table to upload to channel
// -------------------------------------------------------------------------
Function GetBalances(pBalances, pHotel, pAllotment, pPeriodFrom, pPeriodTo, pExtSystemCode = Undefined, pRoomType, pRoomTypeCode, pRoomTypesMappingName = "RoomTypes", pIgnoreMappingCheck = False) Export
	TRooms = New ValueTable;
	TRooms.Columns.Add("RoomType");
	TRooms.Columns.Add("RoomTypeCode");
	TRooms.Columns.Add("Allotment");
	TRooms.Columns.Add("PeriodFrom");
	TRooms.Columns.Add("PeriodTo");
	TRooms.Columns.Add("VacantRooms");
	TRooms.Columns.Add("VacantBeds");
	TRooms.Columns.Add("StopSale");
	TRooms.Columns.Add("Hotel");

	// Check for stop internet sales
	For Each vRow In pBalances Do
		r = TRooms.Add();
		r.Hotel			= pHotel;
		r.RoomType 		= vRow.RoomType;
		r.RoomTypeCode 	= pRoomTypeCode;
		If vRow.Period = Null Then
			r.PeriodFrom = BegOfDay(pPeriodFrom);
			r.PeriodTo = BegOfDay(pPeriodTo);
			r.VacantRooms = 0;
			r.VacantBeds = 0;
		Else
			r.PeriodFrom = BegOfDay(vRow.Period);
			r.PeriodTo = r.PeriodFrom;
			r.VacantRooms = vRow.RoomsVacant;
			r.VacantBeds = vRow.BedsVacant;
		EndIf;
	EndDo;
	TRooms.Sort("RoomType, Allotment, PeriodFrom, PeriodTo");
	
	// Merge identical values in consequent days to one row
	If TRooms.Count() > 1 Then
		vPrev = TRooms.Get(0);
		vInd = 1;
		While vInd < TRooms.Count() Do
			vCurr = TRooms.Get(vInd);
			If vCurr.RoomType = vPrev.RoomType Then
				If vCurr.VacantRooms = vPrev.VacantRooms And
					vCurr.VacantBeds = vPrev.VacantBeds And
					vCurr.StopSale = vPrev.StopSale And
					(vCurr.PeriodFrom - vPrev.PeriodTo) = 24 * 3600 Then
					// Nothing has changed but period, then merge rows - just move PeriodTo to next date
					vPrev.PeriodTo = vCurr.PeriodFrom;
					TRooms.Delete(vCurr);
				Else
					// Move previous row 
					vPrev = vCurr;
					vInd=vInd + 1;
				EndIf;
			Else
				// Move previous row 
				vPrev = vCurr;
				vInd=vInd + 1;
			EndIf;				
		EndDo;
	EndIf;
	
	If Not pIgnoreMappingCheck Then
		// Remove room types without mappings
		vRoomTypesWithoutMappings = New ValueList();
		If pExtSystemCode <> Undefined Then
			vInd = 0;
			While vInd < TRooms.Count() Do
				row = TRooms.Get(vInd);                                                                          
				If vRoomTypesWithoutMappings.FindByValue(row.RoomType) <> Undefined Then
					TRooms.Delete(vInd);
				ElsIf Not cmCheckExternalSystemCodeMapping(pHotel, pExtSystemCode, row.RoomType, pRoomTypesMappingName) Then
					vRoomTypesWithoutMappings.Add(row.RoomType);
					TRooms.Delete(vInd);
				Else
					vInd = vInd + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// Check for stop internet sales
	For Each row In TRooms Do
		vRemarks = "";
		row.StopSale = cmIsStopInternetSalePeriod(row.RoomType, row.PeriodFrom, EndOfDay(row.PeriodTo), vRemarks);
	EndDo;
	
	Return TRooms;
EndFunction // GetBalances

// -------------------------------------------------------------------------
Function GetInteractionParameters(pHotel, pAllotment, pChannelManagerSettings, pForceInteractionID = Undefined) Export
	If Not ValueIsFilled(pHotel) Then
		Return Catalogs.ExternalSystemInteractions.EmptyRef();
	EndIf;
	
	Try	
		If ValueIsFilled(pChannelManagerSettings) And pChannelManagerSettings.Property("ExternalSystemCode") And pChannelManagerSettings.Property("WSHost") Then
			vInteractionID = "";
			If Not ValueIsFilled(pForceInteractionID) Then 
				If ValueIsFilled(pAllotment) Then
					vInteractionID = pChannelManagerSettings.ExternalSystemCode + "-" + TrimAll(pHotel.Code) + "-" + TrimAll(pAllotment.Code);
				Else
					vInteractionID = pChannelManagerSettings.ExternalSystemCode + "-" + TrimAll(pHotel.Code);
				EndIf;
			Else
				vInteractionID = pForceInteractionID;
			EndIf;		
			// Find intercation
			vQ = New Query("SELECT
			|	ExternalSystemInteractions.Ref
			|FROM
			|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
			|WHERE
			|	ExternalSystemInteractions.Hotel = &qHotel
			|	AND ExternalSystemInteractions.InteractionID = &qInteractionID
			|	AND NOT ExternalSystemInteractions.DeletionMark
			|	AND NOT ExternalSystemInteractions.IsFolder");
			vQ.SetParameter("qHotel",pHotel);
			vQ.SetParameter("qInteractionID", vInteractionID);
			vQSerach = vQ.Execute().Select();
			If vQSerach.Next() Then
				Return vQSerach.Ref; 
			Else
				// If does not exist - create one
				vExtSystemInteractionObj 				= Catalogs.ExternalSystemInteractions.CreateItem();
				vExtSystemInteractionObj.Description 	= pChannelManagerSettings.ExternalSystemCode + " - " + TrimAll(pHotel.Description) + ?(ValueIsFilled(pAllotment), " - " + TrimAll(pAllotment.Description), "");
				vExtSystemInteractionObj.Code 			= pChannelManagerSettings.ExternalSystemCode +  TrimAll(pHotel.Code);
				vExtSystemInteractionObj.InteractionID 	= vInteractionID;
				vExtSystemInteractionObj.Hotel 			= pHotel;
				vExtSystemInteractionObj.Allotment 		= pAllotment;
				vExtSystemInteractionObj.WSHost 		= pChannelManagerSettings.WSHost;
				vExtSystemInteractionObj.Write();
			EndIf;
			Return vExtSystemInteractionObj.Ref;
		Else
			Return Catalogs.ExternalSystemInteractions.EmptyRef();
		EndIf;
	Except
		Return Catalogs.ExternalSystemInteractions.EmptyRef();
	EndTry;
EndFunction // GetInteractionParameters

// -------------------------------------------------------------------------
Function GetPeriodsOfChangedRates(pInteractionParameters, pHotel, pRoomRate, pPeriodFrom, pPeriodTo, pPriceTag = Undefined) Export   
	// APDEX
	vKeyOperation = "ChannelManagers.GetPeriodsOfChangedRates";
	vUUID = New UUID;
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, vUUID);
	
	// Read all data exported for the previous time
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
	|	RoomRatesSliceLast.RoomRate AS RoomRate
	|INTO ActiveSetRoomRateFormulas
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPriceCalculationDate,
	|			RoomRate = &qRoomRate
	|				AND Hotel = &qHotel
	|				AND IsFormula) AS RoomRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRateFormulas.RoomRate.BasedOnRoomRate AS BasedOnRoomRate,
	|	RoomRateFormulas.RoomRate.BasedOnPriceTag AS BasedOnPriceTag,
	|	RoomRateFormulas.RoomRate AS RoomRate,
	|	RoomRateFormulas.Hotel AS Hotel,
	|	RoomRateFormulas.IsFormula AS IsFormula,
	|	RoomRateFormulas.Service AS Service,
	|	RoomRateFormulas.RoomType AS RoomType,
	|	RoomRateFormulas.AccommodationType AS AccommodationType,
	|	RoomRateFormulas.ClientType AS ClientType,
	|	RoomRateFormulas.CalendarDayType AS CalendarDayType,
	|	RoomRateFormulas.Recorder AS Recorder,
	|	RoomRateFormulas.Period AS Period,
	|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
	|	RoomRateFormulas.Constant AS Constant,
	|	RoomRateFormulas.Multiplier AS Multiplier,
	|	RoomRateFormulas.ReplaceWithService AS ReplaceWithService
	|INTO RoomRateFormulas
	|FROM
	|	InformationRegister.RoomRateFormulas AS RoomRateFormulas
	|		INNER JOIN ActiveSetRoomRateFormulas AS ActiveSetRoomRateFormulas
	|		ON RoomRateFormulas.Recorder = ActiveSetRoomRateFormulas.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DifferencePeriods.Hotel AS Hotel,
	|	DifferencePeriods.Hotel.Code AS HotelCode,
	|	DifferencePeriods.RoomRate AS RoomRate,
	|	DifferencePeriods.RoomRate.SortCode AS RoomRateSortCode,
	|	DifferencePeriods.RoomRate.Code AS RoomRateCode,
	|	DifferencePeriods.RoomType AS RoomType,
	|	DifferencePeriods.RoomType.SortCode AS RoomTypeSortCode,
	|	DifferencePeriods.Period AS Period,
	|	DifferencePeriods.PriceTag AS PriceTag
	|FROM
	|	(SELECT
	|		RoomRateDailyPrices.Hotel AS Hotel,
	|		RoomRateDailyPrices.RoomRate AS RoomRate,
	|		RoomRateDailyPrices.RoomType AS RoomType,
	|		RoomRateDailyPrices.Period AS Period,
	|		RoomRateDailyPrices.AccommodationType AS AccommodationType,
	|		(RoomRateDailyPrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0) AS Price,
	|		RoomRateDailyPrices.Currency AS Currency,
	|		RoomRateDailyPrices.PriceTag AS PriceTag
	|	FROM
	|		InformationRegister.RoomRateDailyPrices AS RoomRateDailyPrices
	|			LEFT JOIN InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, ) AS CalendarDays
	|			ON RoomRateDailyPrices.RoomRate.Calendar = CalendarDays.Calendar
	|				AND RoomRateDailyPrices.Period = CalendarDays.AccountingDate
	|			LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(&qPriceCalculationDate, ) AS CalendarDaysByRoomTypes
	|			ON RoomRateDailyPrices.RoomRate.Calendar = CalendarDaysByRoomTypes.Calendar
	|				AND RoomRateDailyPrices.Period = CalendarDaysByRoomTypes.AccountingDate
	|				AND RoomRateDailyPrices.RoomType = CalendarDaysByRoomTypes.RoomType
	|			LEFT JOIN RoomRateFormulas AS RoomRateFormulas
	|			ON (RoomRateFormulas.RoomRate = &qRoomRate)
	|				AND RoomRateDailyPrices.Hotel = RoomRateFormulas.Hotel
	|				AND (NOT RoomRateFormulas.IsFormula
	|					OR RoomRateFormulas.IsFormula
	|						AND RoomRateDailyPrices.RoomType = RoomRateFormulas.RoomType
	|						AND RoomRateDailyPrices.ClientType = &qClientType
	|						AND RoomRateDailyPrices.AccommodationType = RoomRateFormulas.AccommodationType
	|						AND (CalendarDaysByRoomTypes.CalendarDayType = RoomRateFormulas.CalendarDayType
	|								AND NOT CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|								AND CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|							OR CalendarDays.CalendarDayType = RoomRateFormulas.CalendarDayType
	|								AND NOT CalendarDays.CalendarDayType IS NULL
	|								AND (CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|									OR CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
	|							OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)))
	|				AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|					OR RoomRateDailyPrices.PriceTag = RoomRateFormulas.BasedOnPriceTag
	|						AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
	|	WHERE
	|		RoomRateDailyPrices.Timestamp > &qTimestampFrom
	|		AND RoomRateDailyPrices.Hotel = &qHotel
	|		AND RoomRateDailyPrices.RoomRate = &qRoomRateInCache
	|		AND RoomRateDailyPrices.Period >= &qPeriodFrom
	|		AND RoomRateDailyPrices.Period <= &qPeriodTo
	|		AND RoomRateDailyPrices.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef)
	|		AND CASE
	|				WHEN &qClientTypeFilled
	|					THEN RoomRateDailyPrices.ClientType = &qClientType
	|				ELSE RoomRateDailyPrices.ClientType = VALUE(Catalog.ClientTypes.EmptyRef)
	|			END
	|		AND CASE
	|				WHEN &qPriceTagFilled
	|					THEN RoomRateDailyPrices.PriceTag = &qPriceTag
	|				ELSE RoomRateDailyPrices.PriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|			END) AS DifferencePeriods
	|
	|ORDER BY
	|	DifferencePeriods.Hotel.Code,
	|	DifferencePeriods.RoomRate.SortCode,
	|	DifferencePeriods.RoomRate.Code,
	|	DifferencePeriods.RoomType.SortCode,
	|	DifferencePeriods.Period";
	vQry.SetParameter("qChannelManager", pInteractionParameters);
	vQry.SetParameter("qTimestampFrom", pInteractionParameters.LastExportTimestampForPrices);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomRate", pRoomRate);
	If ValueIsFilled(pRoomRate) Then
		vQry.SetParameter("qRoomRateInCache", ?(ValueIsFilled(pRoomRate.BasedOnRoomRate), pRoomRate.BasedOnRoomRate, pRoomRate));
	Else
		vQry.SetParameter("qRoomRateInCache", Catalogs.RoomRates.EmptyRef());
	EndIf;
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(pPeriodTo));
	vQry.SetParameter("qClientTypeFilled", ValueIsFilled(pInteractionParameters.ClientType));
	vQry.SetParameter("qClientType", pInteractionParameters.ClientType);
	vQry.SetParameter("qPriceTag", pPriceTag);
	vQry.SetParameter("qPriceTagFilled", ValueIsFilled(pPriceTag));
	vQry.SetParameter("qPriceCalculationDate", CurrentSessionDate());

	vRates = vQry.Execute().Unload();
	
    // Add changes in room inventory for dynamic rates
	If pRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercent Or
	   pRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomType Or
	   pRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomClass Or
	   pRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType Then
		vDailyBalances = GetDailyBalances(pInteractionParameters.Hotel, pInteractionParameters.Allotment, Undefined, pPeriodFrom, pPeriodTo);
		vChangedBalances = GetRoomInventoryChanges(vDailyBalances, pInteractionParameters, pInteractionParameters.Hotel, pInteractionParameters.Allotment, Undefined, pPeriodFrom, pPeriodTo);
		For Each vChangedBalancesRow In vChangedBalances Do
			vRatesRows = vRates.FindRows(New Structure("RoomType, Period", vChangedBalancesRow.RoomType, vChangedBalancesRow.Period));
			If vRatesRows.Count() = 0 Then
				vRatesRow = vRates.Add();
				vRatesRow.Hotel = vChangedBalancesRow.Hotel;
				vRatesRow.HotelCode = vChangedBalancesRow.HotelCode;
				vRatesRow.RoomRate = pRoomRate;
				vRatesRow.RoomRateSortCode = pRoomRate.SortCode;
				vRatesRow.RoomRateCode = pRoomRate.Code;
				vRatesRow.RoomType = vChangedBalancesRow.RoomType;
				vRatesRow.RoomTypeSortCode = vChangedBalancesRow.RoomTypeSortCode;
				vRatesRow.Period = vChangedBalancesRow.Period;
				vRatesRow.PriceTag = pPriceTag;
			EndIf;
		EndDo;
		vRates.Sort("HotelCode, RoomRateSortCode, RoomRateCode, RoomTypeSortCode, Period");
	EndIf;
	
	// APDEX
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	
	// Return value table with changed dates by room types
	Return vRates;
EndFunction // GetPeriodsOfChangedRates

// -------------------------------------------------------------------------
Function GetPeriodsOfChangedRestrictions(pInteractionParameters, pHotel, pRoomRate, pPeriodFrom, pPeriodTo) Export    
	// APDEX
	vKeyOperation = "ChannelManagers.GetPeriodsOfChangedRestrictions";
	vUUID = New UUID;
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, vUUID);

	// Read all data exported for the previous time
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRateRestrictions.Hotel AS Hotel,
	|	RoomRateRestrictions.RoomRate AS RoomRate,
	|	RoomRateRestrictions.RoomType AS RoomType,
	|	RoomRateRestrictions.AccountingDate AS Period
	|FROM
	|	InformationRegister.RoomRateRestrictions AS RoomRateRestrictions
	|WHERE
	|	RoomRateRestrictions.Timestamp > &qTimestampFrom
	|	AND RoomRateRestrictions.Hotel = &qHotel
	|	AND (RoomRateRestrictions.RoomRate = &qRoomRate
	|			OR RoomRateRestrictions.RoomRate = VALUE(Catalog.RoomRates.EmptyRef))
	|	AND RoomRateRestrictions.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|	AND RoomRateRestrictions.AccountingDate >= &qAccountingDateFrom
	|	AND RoomRateRestrictions.AccountingDate <= &qAccountingDateTo
	|
	|GROUP BY
	|	RoomRateRestrictions.Hotel,
	|	RoomRateRestrictions.RoomRate,
	|	RoomRateRestrictions.RoomType,
	|	RoomRateRestrictions.AccountingDate
	|
	|ORDER BY
	|	RoomRateRestrictions.Hotel.Code,
	|	RoomRateRestrictions.RoomRate.SortCode,
	|	RoomRateRestrictions.RoomRate.Code,
	|	RoomRateRestrictions.RoomType.SortCode,
	|	RoomRateRestrictions.RoomType.Code,
	|	RoomRateRestrictions.AccountingDate";
	vQry.SetParameter("qChannelManager", pInteractionParameters);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomRate", pRoomRate);
	vQry.SetParameter("qAccountingDateFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qAccountingDateTo", EndOfDay(pPeriodTo));
	vQry.SetParameter("qTimestampFrom", pInteractionParameters.LastExportTimestampForRestrictions);
	vRestrictions = vQry.Execute().Unload();  
	
	// APDEX
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	
	Return vRestrictions;
EndFunction // GetPeriodsOfChangedRestrictions

// -------------------------------------------------------------------------
Function GetDailyRestrictions(pHotel, pRoomRate, pPeriodFrom, pPeriodTo, pExtSystemCode = Undefined, pRoomRateCode) Export
	vRestrictions = New ValueTable();
	vRestrictions.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels"));
	vRestrictions.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vRestrictions.Columns.Add("RoomRateCode", cmGetStringTypeDescription(5));
	vRestrictions.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vRestrictions.Columns.Add("RoomTypeCode", cmGetStringTypeDescription(5));
	vRestrictions.Columns.Add("Period", cmGetDateTypeDescription());
	vRestrictions.Columns.Add("StopSale", cmGetBooleanTypeDescription());
	vRestrictions.Columns.Add("CTA", cmGetBooleanTypeDescription());
	vRestrictions.Columns.Add("CTD", cmGetBooleanTypeDescription());
	vRestrictions.Columns.Add("MLOS", cmGetNumberTypeDescription(10, 0));
	vRestrictions.Columns.Add("MaxLOS", cmGetNumberTypeDescription(10, 0));
	vRestrictions.Columns.Add("MinDaysBeforeCheckIn", cmGetNumberTypeDescription(10, 0));
	vRestrictions.Columns.Add("MaxDaysBeforeCheckIn", cmGetNumberTypeDescription(10, 0));
	
	// Do for each date and for each room type
	vRoomTypes = GetMappedObjects(pHotel, pExtSystemCode, "RoomTypes");
	While vRoomTypes.Next() Do
		vD = BegOfDay(pPeriodFrom);
		vED = EndOfDay(pPeriodTo);
		While vD <= vED Do
			vRestrStruct = cmGetRoomRateRestrictions(pHotel, pRoomRate, vD, vRoomTypes.ObjectRef, False, True);
			
			vRestrictionsRow = vRestrictions.Add();
			vRestrictionsRow.Period = vD;
			vRestrictionsRow.RoomRate = pRoomRate;
			vRestrictionsRow.RoomRateCode = pRoomRateCode;
			vRestrictionsRow.RoomType = vRoomTypes.ObjectRef;
			vRestrictionsRow.RoomTypeCode = vRoomTypes.ObjectExternalCode;
			vRestrictionsRow.StopSale = vRestrStruct.StopSale;
			vRestrictionsRow.CTA  = vRestrStruct.CTA;
			vRestrictionsRow.CTD = vRestrStruct.CTD;
			vRestrictionsRow.MLOS = vRestrStruct.MLOS;
			vRestrictionsRow.MaxLOS = vRestrStruct.MaxLOS;
			vRestrictionsRow.MinDaysBeforeCheckIn = vRestrStruct.MinDaysBeforeCheckIn;
			vRestrictionsRow.MaxDaysBeforeCheckIn = vRestrStruct.MaxDaysBeforeCheckIn;
			
			vD = vD + 24 * 3600;
		EndDo;
	EndDo;
	
	Return vRestrictions;
EndFunction // GetDailyRestrictions

// -----------------------------------------------------------------------------
Function GetMappedObjects(pHotel, pInteractionID, pTypeName) Export
	vQ = New Query("SELECT
	               |	ExternalSystemsObjectCodesMappings.ObjectRef,
	               |	ExternalSystemsObjectCodesMappings.ObjectExternalCode
	               |FROM
	               |	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	               |WHERE
	               |	ExternalSystemsObjectCodesMappings.Hotel = &Hotel
	               |	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &ExternalSystemCode
	               |	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &ObjectTypeName");
	vQ.SetParameter("Hotel", pHotel);
	vQ.SetParameter("ExternalSystemCode", pInteractionID);
	vQ.SetParameter("ObjectTypeName", pTypeName);
	Return vQ.Execute().Select();
EndFunction // GetMappedObjects

// -----------------------------------------------------------------------------
Function GetMappedListObjects(pHotel, pInteractionID, pTypeName) Export
	vRes = New Array;
	vQ = New Query("SELECT
	               |	ExternalSystemsObjectCodesMappings.ObjectRef,
	               |	ExternalSystemsObjectCodesMappings.ObjectExternalCode
	               |FROM
	               |	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	               |WHERE
	               |	ExternalSystemsObjectCodesMappings.Hotel = &Hotel
	               |	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &ExternalSystemCode
	               |	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &ObjectTypeName");
	vQ.SetParameter("Hotel", pHotel);
	vQ.SetParameter("ExternalSystemCode", pInteractionID);
	vQ.SetParameter("ObjectTypeName", pTypeName);
	Return  vQ.Execute().Unload();
EndFunction // GetMappedObjects

// -----------------------------------------------------------------------------
Function CheckFullSyncTime(pChannelManager, pIsInteractive = False, Val pFull = False) Export
	vFull = pFull;
	If Not pIsInteractive And Not pFull Then
		If ValueIsFilled(pChannelManager.FullSynchronizationTime) And ValueIsFilled(pChannelManager.SessionLastActivityTime) Then
			vLastSyncDateTime = pChannelManager.SessionLastActivityTime;
			If BegOfDay(pChannelManager.FullSynchronizationTime) < BegOfDay(CurrentSessionDate()) Then
				vFullSyncDateTime = BegOfDay(CurrentSessionDate()) + (pChannelManager.FullSynchronizationTime - BegOfDay(pChannelManager.FullSynchronizationTime));
				If vLastSyncDateTime < vFullSyncDateTime And CurrentSessionDate() >= vFullSyncDateTime Then
					vFull = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vFull;
EndFunction // CheckFullSyncTime

// -----------------------------------------------------------------------------
Function UpdateLastSyncTime(pInteractionParameters, pFull = False, pLastSyncDate, pErrors = "", pUpdateInventory = False, pUpdatePrices = False, pUpdateRestrictions = False) Export
	vErrorText = "";
	Try
		vIPObject = Undefined;
		If TypeOf(pInteractionParameters) = Type("CatalogObject.ExternalSystemInteractions") Then
			vIPObject = pInteractionParameters;
			vIPObject.Read();
		Else
			vIPObject = pInteractionParameters.GetObject();
		EndIf;
		If pLastSyncDate <> vIPObject.SessionStartTime Then
			vIPObject.SessionLastActivityTime = pLastSyncDate;
			If IsBlankString(pErrors) Then
				vIPObject.Status = Enums.IntegrationStatuses.Success;
				If pFull Then
					vIPObject.SessionStartTime = pLastSyncDate;
					vIPObject.LastFullSynchronizationTime = pLastSyncDate;
				EndIf;
				If pFull Or pUpdateInventory Then
					vIPObject.LastExportTimestampForInventory = pLastSyncDate;
				EndIf;
				If pFull Or pUpdatePrices Then
					vIPObject.LastExportTimestampForPrices = pLastSyncDate;
				EndIf;
				If pFull Or pUpdateRestrictions Then
					vIPObject.LastExportTimestampForRestrictions = pLastSyncDate;
				EndIf;
				vIPObject.ErrorDescription = "";
			Else
				vIPObject.Status = Enums.IntegrationStatuses.Error;
				vIPObject.ErrorDescription = pErrors;
			EndIf;
			vIPObject.Write();
		EndIf;
	Except
		vErrorText = cmGetRootErrorDescription(ErrorInfo());
		WriteLogEvent(pInteractionParameters.InteractionID + ?(pFull, "_FullUpdate", "_SyncChanges"), EventLogLevel.Warning, , pLastSyncDate, "Could not save last sync timestamps! Error: " + vErrorText);
	EndTry;
	Return vErrorText;
EndFunction // UpdateLastSyncTime

#EndRegion
