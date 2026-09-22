
#Region EventHandlers

Procedure ChoiceDataGetProcessing(pChoiceData, pParameters, pStandardProcessing)
	If Not pParameters.Filter.Property("Hotel") Then
		vHotelFilter = New Array;
		vHotelFilter.Add(SessionParameters.CurrentHotel);
		vHotelFilter.Add(Catalogs.Hotels.EmptyRef());
		
		pParameters.Filter.Insert("Hotel", vHotelFilter);
	EndIf;
EndProcedure

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// -----------------------------------------------------------------------------
//  Write to the service package records register
//
// Parameters:
//  pServicePackage	 - CatalogRef.ServicePackages	 - Ref
//  pDate			 - Date							 - Calculate date
// 
// Returns:
//  ValueTable - Package services
//
Function GetServices(pServicePackage, pDate, pPriceCalculationDate = Undefined) Export
	vPriceCalculationDate = pPriceCalculationDate;
	If pPriceCalculationDate = Undefined Then
		vPriceCalculationDate = CurrentSessionDate();
	EndIf;
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	ServicePackagePeriods.ServicePackage AS ServicePackage,
	|	MAX(ServicePackagePeriods.Period) AS ActivePeriod
	|INTO ServicePackagesActivePeriods
	|FROM
	|	InformationRegister.ServicePackageRecords.SliceLast(&qPriceCalculationDate, ServicePackage = &qServicePackage) AS ServicePackagePeriods
	|
	|GROUP BY
	|	ServicePackagePeriods.ServicePackage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServicePackageRecordsSliceLast.ServicePackage AS ServicePackage,
	|	ServicePackageRecordsSliceLast.ClientType AS ClientType,
	|	ServicePackageRecordsSliceLast.PeriodFrom AS PeriodFrom,
	|	ServicePackageRecordsSliceLast.PeriodTo AS PeriodTo,
	|	ServicePackageRecordsSliceLast.Service AS Service,
	|	ServicePackageRecordsSliceLast.RoomType AS RoomType,
	|	ServicePackageRecordsSliceLast.RoomClass AS RoomClass,
	|	ServicePackageRecordsSliceLast.AccommodationType AS AccommodationType,
	|	ServicePackageRecordsSliceLast.QuantityCalculationRule AS QuantityCalculationRule,
	|	ServicePackageRecordsSliceLast.CalendarDayType AS CalendarDayType,
	|	ServicePackageRecordsSliceLast.AccountingDate AS AccountingDate,
	|	ServicePackageRecordsSliceLast.AccountingDayNumber AS AccountingDayNumber,
	|	ServicePackageRecordsSliceLast.Price AS Price,
	|	ServicePackageRecordsSliceLast.Currency AS Currency,
	|	ServicePackageRecordsSliceLast.Quantity AS Quantity,
	|	ServicePackageRecordsSliceLast.Unit AS Unit,
	|	ServicePackageRecordsSliceLast.VATRate AS VATRate,
	|	ServicePackageRecordsSliceLast.Remarks AS Remarks,
	|	ServicePackageRecordsSliceLast.IsInPrice AS IsInPrice,
	|	ServicePackageRecordsSliceLast.IsServicePerPerson AS IsServicePerPerson,
	|	ServicePackageRecordsSliceLast.RowNumber AS RowNumber,
	|	&qDate AS Period
	|FROM
	|	InformationRegister.ServicePackageRecords AS ServicePackageRecordsSliceLast
	|		INNER JOIN ServicePackagesActivePeriods AS ServicePackagesActivePeriods
	|		ON ServicePackageRecordsSliceLast.ServicePackage = ServicePackagesActivePeriods.ServicePackage
	|			AND ServicePackageRecordsSliceLast.Period = ServicePackagesActivePeriods.ActivePeriod
	|		LEFT JOIN Catalog.RoomTypes AS RoomTypes
	|		ON ServicePackageRecordsSliceLast.RoomClass = RoomTypes.RoomClass
	|			AND (NOT RoomTypes.DeletionMark)
	|			AND (NOT RoomTypes.IsFolder)
	|			AND (NOT ServicePackageRecordsSliceLast.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
	|WHERE
	|	ServicePackageRecordsSliceLast.PeriodFrom <= &qDate
	|	AND (ServicePackageRecordsSliceLast.PeriodTo = &qEmptyDate
	|			OR ServicePackageRecordsSliceLast.PeriodTo >= &qDate)
	|
	|ORDER BY
	|	ServicePackageRecordsSliceLast.RowNumber";
	vQry.SetParameter("qServicePackage", pServicePackage);
	vQry.SetParameter("qDate", BegOfDay(pDate));
	vQry.SetParameter("qPriceCalculationDate", vPriceCalculationDate);
	vQry.SetParameter("qEmptyDate", '00010101');
	vServices = vQry.Execute().Unload();
	Return vServices;
EndFunction // pmGetServices

// -----------------------------------------------------------------------------
//
// Parameters:
//  pServicePackage	 - CatalogRef.ServicePackages	 - Ref
//  pLang	 - CatalogRef.Languages	 - Ref 
// 
// Returns:
//  String - Service package description 
//
Function GetServicePackageDescription(pServicePackage, pLang) Export
	vDescr = "";
	If Not ValueIsFilled(pLang) Then
		vDescr = TrimAll(pServicePackage.Description);
	Else
		If IsBlankString(pServicePackage.DescriptionTranslations) Then
			vDescr = TrimAll(pServicePackage.Description);
		Else
			vDescr = TrimAll(cmNStr(pServicePackage.DescriptionTranslations, pLang));
		EndIf;
	EndIf;
	Return vDescr;
EndFunction // GetServicePackageDescription

#EndRegion
