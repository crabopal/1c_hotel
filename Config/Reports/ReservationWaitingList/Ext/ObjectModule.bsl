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
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период c '; en = 'Period from '; de = 'Periode von '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Zimmertypengruppe '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If Ready Then
		vParamPresentation = vParamPresentation + NStr("en='Show reservations that could be confirmed only';ru='Показывать только бронь, которую можно подтвердить';de='Nur Reservierungen anzeigen, die bestätigt werden können'") + 
							 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), PeriodTo, '39991231235959'));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qReady", Ready);
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
	
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
	|	WaitingList.Reservation.GuestGroup AS ReservationGuestGroup,
	|	WaitingList.Reservation.CheckInDate AS ReservationCheckInDate,
	|	WaitingList.Reservation.CheckOutDate AS ReservationCheckOutDate,
	|	WaitingList.Reservation.RoomType AS ReservationRoomType,
	|	WaitingList.Reservation.NumberOfPersons AS ReservationNumberOfPersons,
	|	WaitingList.Reservation.NumberOfRooms AS ReservationNumberOfRooms,
	|	WaitingList.Reservation.NumberOfBeds AS ReservationNumberOfBeds,
	|	WaitingList.Reservation.NumberOfAdditionalBeds AS ReservationNumberOfAdditionalBeds,
	|	WaitingList.Reservation AS Reservation,
	|	WaitingList.Rating AS Rating,
	|	WaitingList.Ready AS Ready,
	|	1 AS ReservationsCount
	|{SELECT
	|	Reservation.*,
	|	Rating,
	|	Ready,
	|	ReservationsCount}
	|FROM
	|	InformationRegister.ReservationWaitingList AS WaitingList
	|WHERE
	|	WaitingList.Reservation.CheckInDate >= &qPeriodFrom
	|	AND WaitingList.Reservation.CheckInDate < &qPeriodTo
	|	AND WaitingList.Reservation.Hotel IN HIERARCHY(&qHotel)
	|	AND (WaitingList.Reservation.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND ((NOT &qReady)
	|			OR &qReady
	|				AND WaitingList.Ready)
	|{WHERE
	|	WaitingList.Reservation.*,
	|	WaitingList.Reservation.GuestGroup AS ReservationGuestGroup,
	|	WaitingList.Reservation.CheckInDate AS ReservationCheckInDate,
	|	WaitingList.Reservation.CheckOutDate AS ReservationCheckOutDate,
	|	WaitingList.Reservation.RoomType AS ReservationRoomType,
	|	WaitingList.Rating,
	|	WaitingList.Ready}
	|
	|ORDER BY
	|	Rating DESC,
	|	WaitingList.Reservation.RoomType.SortCode,
	|	ReservationCheckInDate,
	|	ReservationCheckOutDate
	|{ORDER BY
	|	Reservation.*,
	|	ReservationGuestGroup.*,
	|	ReservationCheckInDate,
	|	ReservationCheckOutDate,
	|	ReservationRoomType.*,
	|	Rating,
	|	Ready}
	|TOTALS
	|	SUM(ReservationNumberOfPersons),
	|	SUM(ReservationNumberOfRooms),
	|	SUM(ReservationNumberOfBeds),
	|	SUM(ReservationNumberOfAdditionalBeds),
	|	SUM(ReservationsCount)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Reservation.*,
	|	ReservationGuestGroup.*,
	|	ReservationCheckInDate,
	|	ReservationCheckOutDate,
	|	ReservationRoomType.*,
	|	Rating,
	|	Ready}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Reservation waiting list';de='Buchung Warteliste';ru='Лист ожидания брони'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "ReservationNumberOfPersons" 
	   Or pName = "ReservationNumberOfRooms" 
	   Or pName = "ReservationNumberOfBeds" 
	   Or pName = "ReservationNumberOfAdditionalBeds" 
	   Or pName = "ReservationsCount" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
