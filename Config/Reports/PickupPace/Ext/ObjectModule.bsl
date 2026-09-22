
#Region Public

// -----------------------------------------------------------------------------
// Reports framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
EndProcedure // pmLoadReportAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill parameters with default values
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate());
		PeriodTo = AddMonth(BegOfDay(CurrentSessionDate()), 12);
	EndIf;
	If Not ValueIsFilled(DateFrom) Then
		DateFrom = AddMonth(BegOfMonth(CurrentSessionDate()), -12);
		DateTo = BegOfDay(CurrentSessionDate());
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If PaceReportMode Then
		vParamPresentation = vParamPresentation + NStr("en='Pace report mode';ru='Режим отчета накопленным итогом (Pace)';de='Pace-Berich-Modus'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Pickup report mode';ru='Режим отчета по дням (Pickup)';de='Pickup-Berich-Modus'") + 
		                     ";" + Chars.LF;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Period of stay is not set';ru='Период проживания не установлен';de='Aufenthaltsdauer nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период проживания c '; en = 'Period of stay from '; de = 'Aufenthaltsdauer von '") + 
		                     Format(PeriodFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период проживания по '; en = 'Period of stay to '; de = 'Aufenthaltsdauer zu '") + 
		                     Format(PeriodTo, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период проживания на '; en = 'Period of stay on '; de = 'Aufenthaltsdauer '") + 
		                     Format(PeriodFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период проживания '; en = 'Period of stay '; de = 'Aufenthaltsdauer '") + StrReplace(PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()), " 0:00:00", "") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period of stay is wrong!';ru='Неправильно задан период проживания!';de='Der Aufenthaltsdauer wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If Not ValueIsFilled(DateFrom) And Not ValueIsFilled(DateTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Reservation period is not set';ru='Период бронирования не установлен';de='Der Buchungszeitraum ist nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(DateFrom) And Not ValueIsFilled(DateTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период бронирования c '; en = 'Reservation period from '; de = 'Der Buchungszeitraum von '") + 
		                     Format(DateFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период бронирования по '; en = 'Reservation period to '; de = 'Der Buchungszeitraum zu '") + 
		                     Format(DateTo, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf DateFrom = DateTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период бронирования на '; en = 'Reservation period on '; de = 'Der Buchungszeitraum '") + 
		                     Format(DateFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf DateFrom < DateTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период бронирования '; en = 'Reservation period '; de = 'Der Buchungszeitraum '") + StrReplace(PeriodPresentation(DateFrom, DateTo, cmLocalizationCode()), " 0:00:00", "") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Reservation period is wrong!';ru='Неправильно задан период бронирования!';de='Der Buchungszeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Firmen ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Agent) Then
		If Not Agent.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Agent ';en='Agent ';ru='Агент '") + 
			                     TrimAll(Agent.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Agenten ';en='Agents folder ';ru='Группа агентов '") + 
			                     TrimAll(Agent.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Группа гостей '; en = 'Guest group '; de = 'Gastgruppe '") + 
							 TrimAll(TrimAll(GuestGroup.Code) + " " + TrimAll(GuestGroup.Description)) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Zimmertyp ';en='Room type ';ru='Тип номера '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Zimmertypen ';en='Room types folder ';ru='Группа типов номеров '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(SourceOfBusiness) Then
		If Not SourceOfBusiness.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Quelle ';en='Source ';ru='Источник '") + 
			                     TrimAll(SourceOfBusiness.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Quellen ';en='Sources folder ';ru='Группа источников '") + 
			                     TrimAll(SourceOfBusiness.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(MarketingCode) Then
		If Not MarketingCode.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Market ';en='Market ';ru='Сегмент '") + 
			                     TrimAll(MarketingCode.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Marketen ';en='Markets folder ';ru='Группа сегментов '") + 
			                     TrimAll(MarketingCode.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Mitarbeiter ';en='Employee ';ru='Сотрудник '") + 
			                     TrimAll(Employee.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Mitarbeiteren ';en='Employees folder ';ru='Группа сотрудников '") + 
			                     TrimAll(Employee.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Gruppe Hotels '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Runs report
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	If ReportBuilder.RowDimensions.Find("Hotel") = Undefined And ReportBuilder.ColumnDimensions.Find("Hotel") = Undefined Then
		ReportBuilder.Parameters.Insert("qHotelIsNotUsed", True);
	Else
		ReportBuilder.Parameters.Insert("qHotelIsNotUsed", False);
	EndIf;
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), PeriodTo, '39991231'));
	ReportBuilder.Parameters.Insert("qDateFrom", DateFrom);
	ReportBuilder.Parameters.Insert("qDateTo", ?(ValueIsFilled(DateTo), DateTo, '39991231'));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	If ReportBuilder.RowDimensions.Find("RoomType") = Undefined And ReportBuilder.ColumnDimensions.Find("RoomType") = Undefined Then
		ReportBuilder.Parameters.Insert("qRoomTypeIsNotUsed", True);
	Else
		ReportBuilder.Parameters.Insert("qRoomTypeIsNotUsed", False);
	EndIf;
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	If ReportBuilder.RowDimensions.Find("Customer") = Undefined And ReportBuilder.ColumnDimensions.Find("Customer") = Undefined Then
		ReportBuilder.Parameters.Insert("qCustomerIsNotUsed", True);
	Else
		ReportBuilder.Parameters.Insert("qCustomerIsNotUsed", False);
	EndIf;
	ReportBuilder.Parameters.Insert("qAgent", Agent);
	ReportBuilder.Parameters.Insert("qIsEmptyAgent", Not ValueIsFilled(Agent));
	If ReportBuilder.RowDimensions.Find("Agent") = Undefined And ReportBuilder.ColumnDimensions.Find("Agent") = Undefined Then
		ReportBuilder.Parameters.Insert("qAgentIsNotUsed", True);
	Else
		ReportBuilder.Parameters.Insert("qAgentIsNotUsed", False);
	EndIf;
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
	If ReportBuilder.RowDimensions.Find("GuestGroup") = Undefined And ReportBuilder.ColumnDimensions.Find("GuestGroup") = Undefined Then
		ReportBuilder.Parameters.Insert("qGuestGroupIsNotUsed", True);
	Else
		ReportBuilder.Parameters.Insert("qGuestGroupIsNotUsed", False);
	EndIf;
	ReportBuilder.Parameters.Insert("qSourceOfBusiness", SourceOfBusiness);
	ReportBuilder.Parameters.Insert("qIsEmptySourceOfBusiness", Not ValueIsFilled(SourceOfBusiness));
	If ReportBuilder.RowDimensions.Find("SourceOfBusiness") = Undefined And ReportBuilder.ColumnDimensions.Find("SourceOfBusiness") = Undefined Then
		ReportBuilder.Parameters.Insert("qSourceOfBusinessIsNotUsed", True);
	Else
		ReportBuilder.Parameters.Insert("qSourceOfBusinessIsNotUsed", False);
	EndIf;
	ReportBuilder.Parameters.Insert("qMarketingCode", MarketingCode);
	ReportBuilder.Parameters.Insert("qIsEmptyMarketingCode", Not ValueIsFilled(MarketingCode));
	If ReportBuilder.RowDimensions.Find("MarketingCode") = Undefined And ReportBuilder.ColumnDimensions.Find("MarketingCode") = Undefined Then
		ReportBuilder.Parameters.Insert("qMarketingCodeIsNotUsed", True);
	Else
		ReportBuilder.Parameters.Insert("qMarketingCodeIsNotUsed", False);
	EndIf;
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qIsEmptyEmployee", Not ValueIsFilled(Employee));
	ReportBuilder.Parameters.Insert("qPaceMode", PaceReportMode);
	If ReportBuilder.RowDimensions.Find("RoomRate") = Undefined And ReportBuilder.ColumnDimensions.Find("RoomRate") = Undefined Then
		ReportBuilder.Parameters.Insert("qRoomRateIsNotUsed", True);
	Else
		ReportBuilder.Parameters.Insert("qRoomRateIsNotUsed", False);
	EndIf;
	If ReportBuilder.RowDimensions.Find("ClientType") = Undefined And ReportBuilder.ColumnDimensions.Find("ClientType") = Undefined Then
		ReportBuilder.Parameters.Insert("qClientTypeIsNotUsed", True);
	Else
		ReportBuilder.Parameters.Insert("qClientTypeIsNotUsed", False);
	EndIf;
	If ReportBuilder.RowDimensions.Find("ReportingCurrency") = Undefined And ReportBuilder.ColumnDimensions.Find("ReportingCurrency") = Undefined Then
		ReportBuilder.Parameters.Insert("qReportingCurrencyIsNotUsed", True);
	Else
		ReportBuilder.Parameters.Insert("qReportingCurrencyIsNotUsed", False);
	EndIf;
	If ReportBuilder.RowDimensions.Find("Company") = Undefined And ReportBuilder.ColumnDimensions.Find("Company") = Undefined Then
		ReportBuilder.Parameters.Insert("qCompanyIsNotUsed", True);
	Else
		ReportBuilder.Parameters.Insert("qCompanyIsNotUsed", False);
	EndIf;
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	Try
		ReportBuilder.Put(pSpreadsheet);
	Except
		tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(ErrorInfo()), MessageStatus.Attention);
	EndTry;
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
	
	// Remove reservation period totals from report in pace mode
	If PaceReportMode And Not ReportDoNotPutOveralls Then
		If ReportBuilder.RowDimensions.Find("Period") <> Undefined Or
		   ReportBuilder.RowDimensions.Find("PeriodWeek") <> Undefined Or
		   ReportBuilder.RowDimensions.Find("PeriodMonth") <> Undefined Or
		   ReportBuilder.RowDimensions.Find("PeriodQuarter") <> Undefined Or
		   ReportBuilder.RowDimensions.Find("PeriodYear") <> Undefined Then
			pSpreadsheet.Area(pSpreadsheet.TableHeight - 1, , pSpreadsheet.TableHeight - 1, ).Clear(True, True, True);
		ElsIf ReportBuilder.ColumnDimensions.Find("Period") <> Undefined Or
		      ReportBuilder.ColumnDimensions.Find("PeriodWeek") <> Undefined Or
		      ReportBuilder.ColumnDimensions.Find("PeriodMonth") <> Undefined Or
		      ReportBuilder.ColumnDimensions.Find("PeriodQuarter") <> Undefined Or
		      ReportBuilder.ColumnDimensions.Find("PeriodYear") <> Undefined Then
			vNumberOfResources = 0;
			For Each vFld In ReportBuilder.SelectedFields Do
				If pmIsResource(vFld.Name) Then
					vNumberOfResources = vNumberOfResources + 1;
				EndIf;
			EndDo;
			If vNumberOfResources > 0 Then
				pSpreadsheet.Area(4, pSpreadsheet.TableWidth - vNumberOfResources + 1, pSpreadsheet.TableHeight - 1, pSpreadsheet.TableWidth).Clear(True, True, True);
			EndIf;
		EndIf;
	EndIf;
	
	// Add chart 
	If pAddChart Then
		cmAddReportChart(pSpreadsheet, ThisObject);
	EndIf;
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	PickupTurnovers.AccountingDate AS AccountingDate,
	|	PickupTurnovers.Period AS Period,
	|	CASE
	|		WHEN &qPaceMode
	|				AND &qRoomTypeIsNotUsed
	|			THEN NULL
	|		ELSE PickupTurnovers.RoomType
	|	END AS RoomType,
	|	CASE
	|		WHEN &qPaceMode
	|				AND &qCustomerIsNotUsed
	|			THEN NULL
	|		ELSE PickupTurnovers.Customer
	|	END AS Customer,
	|	CASE
	|		WHEN &qPaceMode
	|				AND &qAgentIsNotUsed
	|			THEN NULL
	|		ELSE PickupTurnovers.Agent
	|	END AS Agent,
	|	CASE
	|		WHEN &qPaceMode
	|				AND &qSourceOfBusinessIsNotUsed
	|			THEN NULL
	|		ELSE PickupTurnovers.SourceOfBusiness
	|	END AS SourceOfBusiness,
	|	CASE
	|		WHEN &qPaceMode
	|				AND &qMarketingCodeIsNotUsed
	|			THEN NULL
	|		ELSE PickupTurnovers.MarketingCode
	|	END AS MarketingCode,
	|	CASE
	|		WHEN &qPaceMode
	|				AND &qGuestGroupIsNotUsed
	|			THEN NULL
	|		ELSE PickupTurnovers.GuestGroup
	|	END AS GuestGroup,
	|	CASE
	|		WHEN &qPaceMode
	|				AND &qRoomRateIsNotUsed
	|			THEN NULL
	|		ELSE PickupTurnovers.RoomRate
	|	END AS RoomRate,
	|	CASE
	|		WHEN &qPaceMode
	|				AND &qClientTypeIsNotUsed
	|			THEN NULL
	|		ELSE PickupTurnovers.ClientType
	|	END AS ClientType,
	|	CASE
	|		WHEN &qPaceMode
	|				AND &qReportingCurrencyIsNotUsed
	|			THEN NULL
	|		ELSE PickupTurnovers.ReportingCurrency
	|	END AS ReportingCurrency,
	|	CASE
	|		WHEN &qPaceMode
	|				AND &qCompanyIsNotUsed
	|			THEN NULL
	|		ELSE PickupTurnovers.Company
	|	END AS Company,
	|	CASE
	|		WHEN &qPaceMode
	|				AND &qHotelIsNotUsed
	|			THEN NULL
	|		ELSE PickupTurnovers.Hotel
	|	END AS Hotel,
	|	CASE
	|		WHEN &qPaceMode
	|			THEN NULL
	|		ELSE PickupTurnovers.Author
	|	END AS Author,
	|	PickupTurnovers.IsCancel AS IsCancel,
	|	PickupTurnovers.IsNoShow AS IsNoShow,
	|	PickupTurnovers.RevenueTurnover AS RevenueTurnover,
	|	CASE
	|		WHEN NOT PickupTurnovers.IsCancel
	|			THEN PickupTurnovers.RevenueTurnover
	|		ELSE 0
	|	END AS RevenueReserved,
	|	CASE
	|		WHEN PickupTurnovers.IsCancel
	|			THEN -PickupTurnovers.RevenueTurnover
	|		ELSE 0
	|	END AS RevenueCancelled,
	|	CASE
	|		WHEN PickupTurnovers.IsCancel
	|				AND PickupTurnovers.IsNoShow
	|			THEN -PickupTurnovers.RevenueTurnover
	|		ELSE 0
	|	END AS RevenueNoShow,
	|	PickupTurnovers.RevenueWithoutVATTurnover AS RevenueWithoutVATTurnover,
	|	CASE
	|		WHEN NOT PickupTurnovers.IsCancel
	|			THEN PickupTurnovers.RevenueWithoutVATTurnover
	|		ELSE 0
	|	END AS RevenueWithoutVATReserved,
	|	CASE
	|		WHEN PickupTurnovers.IsCancel
	|			THEN -PickupTurnovers.RevenueWithoutVATTurnover
	|		ELSE 0
	|	END AS RevenueWithoutVATCancelled,
	|	CASE
	|		WHEN PickupTurnovers.IsCancel
	|				AND PickupTurnovers.IsNoShow
	|			THEN -PickupTurnovers.RevenueWithoutVATTurnover
	|		ELSE 0
	|	END AS RevenueWithoutVATNoShow,
	|	PickupTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
	|	CASE
	|		WHEN NOT PickupTurnovers.IsCancel
	|			THEN PickupTurnovers.RoomsRentedTurnover
	|		ELSE 0
	|	END AS RoomsRentedReserved,
	|	CASE
	|		WHEN PickupTurnovers.IsCancel
	|			THEN -PickupTurnovers.RoomsRentedTurnover
	|		ELSE 0
	|	END AS RoomsRentedCancelled,
	|	CASE
	|		WHEN PickupTurnovers.IsCancel
	|				AND PickupTurnovers.IsNoShow
	|			THEN -PickupTurnovers.RoomsRentedTurnover
	|		ELSE 0
	|	END AS RoomsRentedNoShow,
	|	PickupTurnovers.BedsRentedTurnover AS BedsRentedTurnover,
	|	CASE
	|		WHEN NOT PickupTurnovers.IsCancel
	|			THEN PickupTurnovers.BedsRentedTurnover
	|		ELSE 0
	|	END AS BedsRentedReserved,
	|	CASE
	|		WHEN PickupTurnovers.IsCancel
	|			THEN -PickupTurnovers.BedsRentedTurnover
	|		ELSE 0
	|	END AS BedsRentedCancelled,
	|	CASE
	|		WHEN PickupTurnovers.IsCancel
	|				AND PickupTurnovers.IsNoShow
	|			THEN -PickupTurnovers.BedsRentedTurnover
	|		ELSE 0
	|	END AS BedsRentedNoShow,
	|	PickupTurnovers.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|	CASE
	|		WHEN NOT PickupTurnovers.IsCancel
	|			THEN PickupTurnovers.AdditionalBedsRentedTurnover
	|		ELSE 0
	|	END AS AdditionalBedsRentedReserved,
	|	CASE
	|		WHEN PickupTurnovers.IsCancel
	|			THEN -PickupTurnovers.AdditionalBedsRentedTurnover
	|		ELSE 0
	|	END AS AdditionalBedsRentedCancelled,
	|	CASE
	|		WHEN PickupTurnovers.IsCancel
	|				AND PickupTurnovers.IsNoShow
	|			THEN -PickupTurnovers.AdditionalBedsRentedTurnover
	|		ELSE 0
	|	END AS AdditionalBedsRentedNoShow,
	|	PickupTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|	CASE
	|		WHEN NOT PickupTurnovers.IsCancel
	|			THEN PickupTurnovers.GuestDaysTurnover
	|		ELSE 0
	|	END AS GuestDaysReserved,
	|	CASE
	|		WHEN PickupTurnovers.IsCancel
	|			THEN -PickupTurnovers.GuestDaysTurnover
	|		ELSE 0
	|	END AS GuestDaysCancelled,
	|	CASE
	|		WHEN PickupTurnovers.IsCancel
	|				AND PickupTurnovers.IsNoShow
	|			THEN -PickupTurnovers.GuestDaysTurnover
	|		ELSE 0
	|	END AS GuestDaysNoShow
	|INTO PickupTurnovers
	|FROM
	|	AccumulationRegister.Pickup.Turnovers(
	|			&qDateFrom,
	|			&qDateTo,
	|			Day,
	|			AccountingDate >= &qPeriodFrom
	|				AND AccountingDate <= &qPeriodTo
	|				AND (Customer IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|				AND (Agent IN HIERARCHY (&qAgent)
	|					OR &qIsEmptyAgent)
	|				AND (GuestGroup = &qGuestGroup
	|					OR &qIsEmptyGuestGroup)
	|				AND GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|				AND (SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
	|					OR &qIsEmptySourceOfBusiness)
	|				AND (MarketingCode IN HIERARCHY (&qMarketingCode)
	|					OR &qIsEmptyMarketingCode)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND (Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|				AND (Author IN HIERARCHY (&qEmployee)
	|					OR &qIsEmptyEmployee)) AS PickupTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PickupTurnovers.AccountingDate AS AccountingDate,
	|	PickupTurnovers.Period AS Period,
	|	PickupTurnovers.RoomType AS RoomType,
	|	PickupTurnovers.Customer AS Customer,
	|	PickupTurnovers.Agent AS Agent,
	|	PickupTurnovers.SourceOfBusiness AS SourceOfBusiness,
	|	PickupTurnovers.MarketingCode AS MarketingCode,
	|	PickupTurnovers.RoomRate AS RoomRate,
	|	PickupTurnovers.ClientType AS ClientType,
	|	PickupTurnovers.GuestGroup AS GuestGroup,
	|	PickupTurnovers.ReportingCurrency AS ReportingCurrency,
	|	PickupTurnovers.Company AS Company,
	|	PickupTurnovers.Hotel AS Hotel,
	|	PickupTurnovers.Author AS Author,
	|	SUM(PickupTurnovers.RevenueTurnover) AS RevenueTurnover,
	|	SUM(PickupTurnovers.RevenueReserved) AS RevenueReserved,
	|	SUM(PickupTurnovers.RevenueCancelled) AS RevenueCancelled,
	|	SUM(PickupTurnovers.RevenueNoShow) AS RevenueNoShow,
	|	SUM(PickupTurnovers.RevenueWithoutVATTurnover) AS RevenueWithoutVATTurnover,
	|	SUM(PickupTurnovers.RevenueWithoutVATReserved) AS RevenueWithoutVATReserved,
	|	SUM(PickupTurnovers.RevenueWithoutVATCancelled) AS RevenueWithoutVATCancelled,
	|	SUM(PickupTurnovers.RevenueWithoutVATNoShow) AS RevenueWithoutVATNoShow,
	|	SUM(PickupTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(PickupTurnovers.RoomsRentedReserved) AS RoomsRentedReserved,
	|	SUM(PickupTurnovers.RoomsRentedCancelled) AS RoomsRentedCancelled,
	|	SUM(PickupTurnovers.RoomsRentedNoShow) AS RoomsRentedNoShow,
	|	SUM(PickupTurnovers.BedsRentedTurnover) AS BedsRentedTurnover,
	|	SUM(PickupTurnovers.BedsRentedReserved) AS BedsRentedReserved,
	|	SUM(PickupTurnovers.BedsRentedCancelled) AS BedsRentedCancelled,
	|	SUM(PickupTurnovers.BedsRentedNoShow) AS BedsRentedNoShow,
	|	SUM(PickupTurnovers.AdditionalBedsRentedTurnover) AS AdditionalBedsRentedTurnover,
	|	SUM(PickupTurnovers.AdditionalBedsRentedReserved) AS AdditionalBedsRentedReserved,
	|	SUM(PickupTurnovers.AdditionalBedsRentedCancelled) AS AdditionalBedsRentedCancelled,
	|	SUM(PickupTurnovers.AdditionalBedsRentedNoShow) AS AdditionalBedsRentedNoShow,
	|	SUM(PickupTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(PickupTurnovers.GuestDaysReserved) AS GuestDaysReserved,
	|	SUM(PickupTurnovers.GuestDaysCancelled) AS GuestDaysCancelled,
	|	SUM(PickupTurnovers.GuestDaysNoShow) AS GuestDaysNoShow
	|INTO PickupData
	|FROM
	|	PickupTurnovers AS PickupTurnovers
	|
	|GROUP BY
	|	PickupTurnovers.AccountingDate,
	|	PickupTurnovers.Period,
	|	PickupTurnovers.RoomType,
	|	PickupTurnovers.Customer,
	|	PickupTurnovers.Agent,
	|	PickupTurnovers.SourceOfBusiness,
	|	PickupTurnovers.MarketingCode,
	|	PickupTurnovers.RoomRate,
	|	PickupTurnovers.ClientType,
	|	PickupTurnovers.Author,
	|	PickupTurnovers.GuestGroup,
	|	PickupTurnovers.ReportingCurrency,
	|	PickupTurnovers.Company,
	|	PickupTurnovers.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PickupData.AccountingDate AS AccountingDate,
	|	PickupData.Period AS Period,
	|	PickupData.RoomType AS RoomType,
	|	PickupData.Customer AS Customer,
	|	PickupData.Agent AS Agent,
	|	PickupData.SourceOfBusiness AS SourceOfBusiness,
	|	PickupData.MarketingCode AS MarketingCode,
	|	PickupData.RoomRate AS RoomRate,
	|	PickupData.ClientType AS ClientType,
	|	PickupData.Author AS Author,
	|	PickupData.GuestGroup AS GuestGroup,
	|	PickupData.ReportingCurrency AS ReportingCurrency,
	|	PickupData.Company AS Company,
	|	PickupData.Hotel AS Hotel,
	|	SUM(PaceData.RevenueTurnover) AS RevenueTurnover,
	|	SUM(PaceData.RevenueReserved) AS RevenueReserved,
	|	SUM(PaceData.RevenueCancelled) AS RevenueCancelled,
	|	SUM(PaceData.RevenueNoShow) AS RevenueNoShow,
	|	SUM(PaceData.RevenueWithoutVATTurnover) AS RevenueWithoutVATTurnover,
	|	SUM(PaceData.RevenueWithoutVATReserved) AS RevenueWithoutVATReserved,
	|	SUM(PaceData.RevenueWithoutVATCancelled) AS RevenueWithoutVATCancelled,
	|	SUM(PaceData.RevenueWithoutVATNoShow) AS RevenueWithoutVATNoShow,
	|	SUM(PaceData.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(PaceData.RoomsRentedReserved) AS RoomsRentedReserved,
	|	SUM(PaceData.RoomsRentedCancelled) AS RoomsRentedCancelled,
	|	SUM(PaceData.RoomsRentedNoShow) AS RoomsRentedNoShow,
	|	SUM(PaceData.BedsRentedTurnover) AS BedsRentedTurnover,
	|	SUM(PaceData.BedsRentedReserved) AS BedsRentedReserved,
	|	SUM(PaceData.BedsRentedCancelled) AS BedsRentedCancelled,
	|	SUM(PaceData.BedsRentedNoShow) AS BedsRentedNoShow,
	|	SUM(PaceData.AdditionalBedsRentedTurnover) AS AdditionalBedsRentedTurnover,
	|	SUM(PaceData.AdditionalBedsRentedReserved) AS AdditionalBedsRentedReserved,
	|	SUM(PaceData.AdditionalBedsRentedCancelled) AS AdditionalBedsRentedCancelled,
	|	SUM(PaceData.AdditionalBedsRentedNoShow) AS AdditionalBedsRentedNoShow,
	|	SUM(PaceData.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(PaceData.GuestDaysReserved) AS GuestDaysReserved,
	|	SUM(PaceData.GuestDaysCancelled) AS GuestDaysCancelled,
	|	SUM(PaceData.GuestDaysNoShow) AS GuestDaysNoShow
	|INTO PickupPaceData
	|FROM
	|	PickupData AS PickupData
	|		LEFT JOIN PickupData AS PaceData
	|		ON PickupData.AccountingDate = PaceData.AccountingDate
	|			AND (&qPaceMode
	|					AND PickupData.Period >= PaceData.Period
	|				OR NOT &qPaceMode
	|					AND PickupData.Period = PaceData.Period)
	|			AND (PickupData.RoomType = PaceData.RoomType
	|				OR PaceData.RoomType IS NULL)
	|			AND (PickupData.Customer = PaceData.Customer
	|				OR PaceData.Customer IS NULL)
	|			AND (PickupData.Agent = PaceData.Agent
	|				OR PaceData.Agent IS NULL)
	|			AND (PickupData.SourceOfBusiness = PaceData.SourceOfBusiness
	|				OR PaceData.SourceOfBusiness IS NULL)
	|			AND (PickupData.MarketingCode = PaceData.MarketingCode
	|				OR PaceData.MarketingCode IS NULL)
	|			AND (PickupData.RoomRate = PaceData.RoomRate
	|				OR PaceData.RoomRate IS NULL)
	|			AND (PickupData.ClientType = PaceData.ClientType
	|				OR PaceData.ClientType IS NULL)
	|			AND (PickupData.GuestGroup = PaceData.GuestGroup
	|				OR PaceData.GuestGroup IS NULL)
	|			AND (PickupData.ReportingCurrency = PaceData.ReportingCurrency
	|				OR PaceData.ReportingCurrency IS NULL)
	|			AND (PickupData.Company = PaceData.Company
	|				OR PaceData.Company IS NULL)
	|			AND (PickupData.Hotel = PaceData.Hotel
	|				OR PaceData.Hotel IS NULL)
	|			AND (&qPaceMode
	|				OR NOT &qPaceMode
	|					AND PickupData.Author = PaceData.Author)
	|
	|GROUP BY
	|	PickupData.AccountingDate,
	|	PickupData.Period,
	|	PickupData.RoomType,
	|	PickupData.Customer,
	|	PickupData.Agent,
	|	PickupData.SourceOfBusiness,
	|	PickupData.MarketingCode,
	|	PickupData.RoomRate,
	|	PickupData.ClientType,
	|	PickupData.Author,
	|	PickupData.GuestGroup,
	|	PickupData.ReportingCurrency,
	|	PickupData.Company,
	|	PickupData.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PickupPaceData.Period AS Period,
	|	PickupPaceData.AccountingDate AS AccountingDate,
	|	PickupPaceData.RoomType AS RoomType,
	|	PickupPaceData.Customer AS Customer,
	|	PickupPaceData.Agent AS Agent,
	|	PickupPaceData.SourceOfBusiness AS SourceOfBusiness,
	|	PickupPaceData.MarketingCode AS MarketingCode,
	|	PickupPaceData.RoomRate AS RoomRate,
	|	PickupPaceData.ClientType AS ClientType,
	|	PickupPaceData.Author AS Author,
	|	PickupPaceData.GuestGroup AS GuestGroup,
	|	PickupPaceData.ReportingCurrency AS ReportingCurrency,
	|	PickupPaceData.Company AS Company,
	|	PickupPaceData.Hotel AS Hotel,
	|	PickupPaceData.RevenueTurnover AS RevenueTurnover,
	|	PickupPaceData.RevenueReserved AS RevenueReserved,
	|	PickupPaceData.RevenueCancelled AS RevenueCancelled,
	|	PickupPaceData.RevenueNoShow AS RevenueNoShow,
	|	PickupPaceData.RevenueWithoutVATTurnover AS RevenueWithoutVATTurnover,
	|	PickupPaceData.RevenueWithoutVATReserved AS RevenueWithoutVATReserved,
	|	PickupPaceData.RevenueWithoutVATCancelled AS RevenueWithoutVATCancelled,
	|	PickupPaceData.RevenueWithoutVATNoShow AS RevenueWithoutVATNoShow,
	|	PickupPaceData.RoomsRentedTurnover AS RoomsRentedTurnover,
	|	PickupPaceData.RoomsRentedReserved AS RoomsRentedReserved,
	|	PickupPaceData.RoomsRentedCancelled AS RoomsRentedCancelled,
	|	PickupPaceData.RoomsRentedNoShow AS RoomsRentedNoShow,
	|	PickupPaceData.BedsRentedTurnover AS BedsRentedTurnover,
	|	PickupPaceData.BedsRentedReserved AS BedsRentedReserved,
	|	PickupPaceData.BedsRentedCancelled AS BedsRentedCancelled,
	|	PickupPaceData.BedsRentedNoShow AS BedsRentedNoShow,
	|	PickupPaceData.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|	PickupPaceData.AdditionalBedsRentedReserved AS AdditionalBedsRentedReserved,
	|	PickupPaceData.AdditionalBedsRentedCancelled AS AdditionalBedsRentedCancelled,
	|	PickupPaceData.AdditionalBedsRentedNoShow AS AdditionalBedsRentedNoShow,
	|	PickupPaceData.GuestDaysTurnover AS GuestDaysTurnover,
	|	PickupPaceData.GuestDaysReserved AS GuestDaysReserved,
	|	PickupPaceData.GuestDaysCancelled AS GuestDaysCancelled,
	|	PickupPaceData.GuestDaysNoShow AS GuestDaysNoShow,
	|	CASE
	|		WHEN ISNULL(PickupPaceData.RoomsRentedTurnover, 0) <> 0
	|			THEN ISNULL(PickupPaceData.RevenueTurnover, 0) / ISNULL(PickupPaceData.RoomsRentedTurnover, 0)
	|		ELSE 0
	|	END AS ADR,
	|	CASE
	|		WHEN ISNULL(PickupPaceData.RoomsRentedTurnover, 0) <> 0
	|			THEN ISNULL(PickupPaceData.RevenueWithoutVATTurnover, 0) / ISNULL(PickupPaceData.RoomsRentedTurnover, 0)
	|		ELSE 0
	|	END AS ADRWithoutVAT
	|{SELECT
	|	Period,
	|	AccountingDate,
	|	(WEEK(PickupPaceData.Period)) AS PeriodWeek,
	|	(BEGINOFPERIOD(PickupPaceData.Period, MONTH)) AS PeriodMonth,
	|	(BEGINOFPERIOD(PickupPaceData.Period, QUARTER)) AS PeriodQuarter,
	|	(YEAR(PickupPaceData.Period)) AS PeriodYear,
	|	(WEEK(PickupPaceData.AccountingDate)) AS AccountingWeek,
	|	(BEGINOFPERIOD(PickupPaceData.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(PickupPaceData.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(PickupPaceData.AccountingDate)) AS AccountingYear,
	|	RoomType.*,
	|	Customer.*,
	|	Agent.*,
	|	SourceOfBusiness.*,
	|	MarketingCode.*,
	|	RoomRate.*,
	|	ClientType.*,
	|	Author.*,
	|	GuestGroup.*,
	|	ReportingCurrency.*,
	|	Company.*,
	|	Hotel.*,
	|	RevenueTurnover,
	|	RevenueReserved,
	|	RevenueCancelled,
	|	RevenueNoShow,
	|	RevenueWithoutVATTurnover,
	|	RevenueWithoutVATReserved,
	|	RevenueWithoutVATCancelled,
	|	RevenueWithoutVATNoShow,
	|	RoomsRentedTurnover,
	|	RoomsRentedReserved,
	|	RoomsRentedCancelled,
	|	RoomsRentedNoShow,
	|	BedsRentedTurnover,
	|	BedsRentedReserved,
	|	BedsRentedCancelled,
	|	BedsRentedNoShow,
	|	AdditionalBedsRentedTurnover,
	|	AdditionalBedsRentedReserved,
	|	AdditionalBedsRentedCancelled,
	|	AdditionalBedsRentedNoShow,
	|	GuestDaysTurnover,
	|	GuestDaysReserved,
	|	GuestDaysCancelled,
	|	GuestDaysNoShow,
	|	ADR,
	|	ADRWithoutVAT}
	|FROM
	|	PickupPaceData AS PickupPaceData
	|{WHERE
	|	PickupPaceData.Period,
	|	PickupPaceData.AccountingDate,
	|	(WEEK(PickupPaceData.Period)) AS PeriodWeek,
	|	(BEGINOFPERIOD(PickupPaceData.Period, MONTH)) AS PeriodMonth,
	|	(BEGINOFPERIOD(PickupPaceData.Period, QUARTER)) AS PeriodQuarter,
	|	(YEAR(PickupPaceData.Period)) AS PeriodYear,
	|	(WEEK(PickupPaceData.AccountingDate)) AS AccountingWeek,
	|	(BEGINOFPERIOD(PickupPaceData.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(PickupPaceData.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(PickupPaceData.AccountingDate)) AS AccountingYear,
	|	PickupPaceData.RoomType.*,
	|	PickupPaceData.Customer.*,
	|	PickupPaceData.Agent.*,
	|	PickupPaceData.SourceOfBusiness.*,
	|	PickupPaceData.MarketingCode.*,
	|	PickupPaceData.RoomRate.*,
	|	PickupPaceData.ClientType.*,
	|	PickupPaceData.Author.*,
	|	PickupPaceData.GuestGroup.*,
	|	PickupPaceData.ReportingCurrency.*,
	|	PickupPaceData.Company.*,
	|	PickupPaceData.Hotel.*,
	|	PickupPaceData.RevenueTurnover,
	|	PickupPaceData.RevenueReserved AS RevenueReserved,
	|	PickupPaceData.RevenueCancelled AS RevenueCancelled,
	|	PickupPaceData.RevenueNoShow AS RevenueNoShow,
	|	PickupPaceData.RevenueWithoutVATTurnover,
	|	PickupPaceData.RevenueWithoutVATReserved AS RevenueWithoutVATReserved,
	|	PickupPaceData.RevenueWithoutVATCancelled AS RevenueWithoutVATCancelled,
	|	PickupPaceData.RevenueWithoutVATNoShow AS RevenueWithoutVATNoShow,
	|	PickupPaceData.RoomsRentedTurnover,
	|	PickupPaceData.RoomsRentedReserved AS RoomsRentedReserved,
	|	PickupPaceData.RoomsRentedCancelled AS RoomsRentedCancelled,
	|	PickupPaceData.RoomsRentedNoShow AS RoomsRentedNoShow,
	|	PickupPaceData.BedsRentedTurnover AS BedsRentedTurnover,
	|	PickupPaceData.BedsRentedReserved AS BedsRentedReserved,
	|	PickupPaceData.BedsRentedCancelled AS BedsRentedCancelled,
	|	PickupPaceData.BedsRentedNoShow AS BedsRentedNoShow,
	|	PickupPaceData.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|	PickupPaceData.AdditionalBedsRentedReserved AS AdditionalBedsRentedReserved,
	|	PickupPaceData.AdditionalBedsRentedCancelled AS AdditionalBedsRentedCancelled,
	|	PickupPaceData.AdditionalBedsRentedNoShow AS AdditionalBedsRentedNoShow,
	|	PickupPaceData.GuestDaysTurnover AS GuestDaysTurnover,
	|	PickupPaceData.GuestDaysReserved AS GuestDaysReserved,
	|	PickupPaceData.GuestDaysCancelled AS GuestDaysCancelled,
	|	PickupPaceData.GuestDaysNoShow AS GuestDaysNoShow,
	|	(CASE
	|			WHEN ISNULL(PickupPaceData.RoomsRentedTurnover, 0) <> 0
	|				THEN ISNULL(PickupPaceData.RevenueTurnover, 0) / ISNULL(PickupPaceData.RoomsRentedTurnover, 0)
	|			ELSE 0
	|		END) AS ADR,
	|	(CASE
	|			WHEN ISNULL(PickupPaceData.RoomsRentedTurnover, 0) <> 0
	|				THEN ISNULL(PickupPaceData.RevenueWithoutVATTurnover, 0) / ISNULL(PickupPaceData.RoomsRentedTurnover, 0)
	|			ELSE 0
	|		END) AS ADRWithoutVAT}
	|
	|ORDER BY
	|	Period,
	|	AccountingDate
	|{ORDER BY
	|	Period,
	|	AccountingDate,
	|	(WEEK(PickupPaceData.Period)) AS PeriodWeek,
	|	(BEGINOFPERIOD(PickupPaceData.Period, MONTH)) AS PeriodMonth,
	|	(BEGINOFPERIOD(PickupPaceData.Period, QUARTER)) AS PeriodQuarter,
	|	(YEAR(PickupPaceData.Period)) AS PeriodYear,
	|	(WEEK(PickupPaceData.AccountingDate)) AS AccountingWeek,
	|	(BEGINOFPERIOD(PickupPaceData.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(PickupPaceData.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(PickupPaceData.AccountingDate)) AS AccountingYear,
	|	RoomType.*,
	|	Customer.*,
	|	Agent.*,
	|	SourceOfBusiness.*,
	|	MarketingCode.*,
	|	RoomRate.*,
	|	ClientType.*,
	|	Author.*,
	|	GuestGroup.*,
	|	ReportingCurrency.*,
	|	Company.*,
	|	Hotel.*,
	|	ADR,
	|	ADRWithoutVAT}
	|TOTALS
	|	SUM(RevenueTurnover),
	|	SUM(RevenueReserved),
	|	SUM(RevenueCancelled),
	|	SUM(RevenueNoShow),
	|	SUM(RevenueWithoutVATTurnover),
	|	SUM(RevenueWithoutVATReserved),
	|	SUM(RevenueWithoutVATCancelled),
	|	SUM(RevenueWithoutVATNoShow),
	|	SUM(RoomsRentedTurnover),
	|	SUM(RoomsRentedReserved),
	|	SUM(RoomsRentedCancelled),
	|	SUM(RoomsRentedNoShow),
	|	SUM(BedsRentedTurnover),
	|	SUM(BedsRentedReserved),
	|	SUM(BedsRentedCancelled),
	|	SUM(BedsRentedNoShow),
	|	SUM(AdditionalBedsRentedTurnover),
	|	SUM(AdditionalBedsRentedReserved),
	|	SUM(AdditionalBedsRentedCancelled),
	|	SUM(AdditionalBedsRentedNoShow),
	|	SUM(GuestDaysTurnover),
	|	SUM(GuestDaysReserved),
	|	SUM(GuestDaysCancelled),
	|	SUM(GuestDaysNoShow),
	|	CASE
	|		WHEN SUM(RoomsRentedTurnover) <> 0
	|			THEN SUM(RevenueTurnover) / SUM(RoomsRentedTurnover)
	|		ELSE 0
	|	END AS ADR,
	|	CASE
	|		WHEN SUM(RoomsRentedTurnover) <> 0
	|			THEN SUM(RevenueWithoutVATTurnover) / SUM(RoomsRentedTurnover)
	|		ELSE 0
	|	END AS ADRWithoutVAT
	|BY
	|	OVERALL,
	|	Period,
	|	AccountingDate
	|{TOTALS BY
	|	Period,
	|	AccountingDate,
	|	(WEEK(PickupPaceData.Period)) AS PeriodWeek,
	|	(BEGINOFPERIOD(PickupPaceData.Period, MONTH)) AS PeriodMonth,
	|	(BEGINOFPERIOD(PickupPaceData.Period, QUARTER)) AS PeriodQuarter,
	|	(YEAR(PickupPaceData.Period)) AS PeriodYear,
	|	(WEEK(PickupPaceData.AccountingDate)) AS AccountingWeek,
	|	(BEGINOFPERIOD(PickupPaceData.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(PickupPaceData.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(PickupPaceData.AccountingDate)) AS AccountingYear,
	|	RoomType.*,
	|	Customer.*,
	|	Agent.*,
	|	SourceOfBusiness.*,
	|	MarketingCode.*,
	|	RoomRate.*,
	|	ClientType.*,
	|	Author.*,
	|	GuestGroup.*,
	|	ReportingCurrency.*,
	|	Company.*,
	|	Hotel.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en = 'Pickup/Pace report'; de = 'Pickup/Pace Bericht'; ru = 'Динамика продаж (Pickup/Pace)'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "RevenueTurnover" 
	   Or pName = "RevenueReserved" 
	   Or pName = "RevenueCancelled" 
	   Or pName = "RevenueNoShow" 
	   Or pName = "RevenueWithoutVATTurnover" 
	   Or pName = "RevenueWithoutVATReserved" 
	   Or pName = "RevenueWithoutVATCancelled" 
	   Or pName = "RevenueWithoutVATNoShow" 
	   Or pName = "RoomsRentedTurnover" 
	   Or pName = "RoomsRentedReserved" 
	   Or pName = "RoomsRentedCancelled" 
	   Or pName = "RoomsRentedNoShow" 
	   Or pName = "BedsRentedTurnover" 
	   Or pName = "BedsRentedReserved" 
	   Or pName = "BedsRentedCancelled" 
	   Or pName = "BedsRentedNoShow" 
	   Or pName = "AdditionalBedsRentedTurnover" 
	   Or pName = "AdditionalBedsRentedReserved" 
	   Or pName = "AdditionalBedsRentedCancelled" 
	   Or pName = "AdditionalBedsRentedNoShow" 
	   Or pName = "GuestDaysTurnover" 
	   Or pName = "GuestDaysReserved" 
	   Or pName = "GuestDaysCancelled"
	   Or pName = "GuestDaysNoShow" 
	   Or pName = "ADR"
	   Or pName = "ADRWithoutVAT" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

#EndRegion
 