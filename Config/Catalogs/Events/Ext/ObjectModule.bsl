
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not IsFolder Then
		If Not ValueIsFilled(DateFrom) Or Not ValueIsFilled(DateTo) Then     
			vErr = NStr("en = 'Event period should be filled!'; 
						|de = 'Der Zeitraum für die Durchführung von Veranstaltungen muss ausgefüllt sein!'; 
						|ru = 'Период проведения мероприятия должен быть заполнен!'");
			Raise vErr;
		EndIf;
		If DateFrom > DateTo Then 
			vErr = NStr("en = 'Wrong event period! Date from is after date to.'; 
						|de = 'Der Zeitraum für die Durchführung von Veranstaltungen ist falsch angegeben! Das Datum des Zeitraumbeginns liegt nach dem Datum des Zeitraumendes.'; 
						|ru = 'Период проведения мероприятия указан неверно! Дата начала периода позже даты окончания периода.'");
			Raise vErr; 
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewCode(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewCode

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
// 
// Returns:
//  ValueTable - Guest group list
//
Function pmGetEventGuestGroups(pHotel = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GuestGroups.Ref
	|FROM
	|	Catalog.GuestGroups AS GuestGroups
	|WHERE
	|	GuestGroups.Event = &qEvent
	|	AND NOT GuestGroups.DeletionMark
	|	AND (NOT &qHotelIsFilled OR &qHotelIsFilled AND GuestGroups.Owner = &qHotel)
	|
	|ORDER BY
	|	GuestGroups.CheckInDate,
	|	GuestGroups.Code";
	vQry.SetParameter("qEvent", Ref);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pHotel));
	vQry.SetParameter("qHotel", pHotel);
	vGuestGroups = vQry.Execute().Unload();
	Return vGuestGroups;
EndFunction // pmGetEventGuestGroups

#EndRegion
