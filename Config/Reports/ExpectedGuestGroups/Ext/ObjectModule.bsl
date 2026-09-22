Var EventBackColor;

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
		PeriodFrom = BegOfDay(CurrentSessionDate()); // For today
		PeriodTo = EndOfDay(PeriodFrom);
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
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Firmengruppe ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("en='Guest group ';ru='Группа ';de='Gruppe '") + 
							 TrimAll(GuestGroup.Code) + 
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
	If ValueIsFilled(RoomQuota) Then
		If Not RoomQuota.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Allotment ';ru='Квота ';de='Allotment '") + 
			                     TrimAll(RoomQuota.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Allotements folder ';ru='Группа квот ';de='Allotmentgruppe '") + 
			                     TrimAll(RoomQuota.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(ReservationStatus) Then
		If Not ReservationStatus.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Статус брони '; en = 'Reservation status '; de = 'Reservierungsstatus '") + 
			                     TrimAll(ReservationStatus.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа статусов брони '; en = 'Reservation statuses folder '; de = 'Reservierungsstatusengruppe '") + 
			                     TrimAll(ReservationStatus.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Manager) Then
		If Not Manager.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Менеджер групп '; en = 'Group manager '; de = 'Gruppenleiter '") + 
			                     TrimAll(Manager.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа менеджеров '; en = 'Group manager folder '; de = 'Gruppenleiterengruppe '") + 
			                     TrimAll(Manager.Description) + 
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
			                     TrimAll(Hotel.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Runs report
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qReservationStatus", ReservationStatus);
	ReportBuilder.Parameters.Insert("qReservationStatusIsEmpty", Not ValueIsFilled(ReservationStatus));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qRoomTypeIsEmpty", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qRoomQuota", RoomQuota);
	ReportBuilder.Parameters.Insert("qRoomQuotaIsEmpty", Not ValueIsFilled(RoomQuota));
	ReportBuilder.Parameters.Insert("qManager", Manager);
	ReportBuilder.Parameters.Insert("qManagerIsEmpty", Not ValueIsFilled(Manager));
	
	// Always do not show totals
	ReportBuilder.PutOveralls = False;

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
	
	// Get row where to place events
	vResourcesCount = 0;
	For Each vFld In ReportBuilder.SelectedFields Do
		If pmIsResource(vFld.Name) Then
			vResourcesCount = vResourcesCount + 1;
		EndIf;
	EndDo;
	vEvents = cmGetEvents(PeriodFrom, PeriodTo, Hotel);
	
	h = 5;
	If vResourcesCount > 1 Then
		h = h + 1;
	EndIf;
	If vEvents.Count() > 0 Then
		h = h + 1;
	EndIf;
	
	// Try to find first date range searching for the date format string
	i = 1;
	While i < pSpreadsheet.TableWidth Do
		vDateArea = pSpreadsheet.Area(4, i, 4, i);
		If Not IsBlankString(vDateArea.Format) Then
			w = i;
			Break;
		EndIf;
		i = i + 1;
	EndDo;
	
	// Get events and modify report with events
	w = 0;
	If PeriodFrom > '19000101' And PeriodTo < '30000101' And 
	   pSpreadsheet.TableHeight > h Then
		// Copy this row and update it
		If vEvents.Count() > 0 Then
			vSourceRowArea = pSpreadsheet.Area(h - 1, , h - 1, );
			vTargetRowArea = pSpreadsheet.Area(h - 1, , h - 1, );
			pSpreadsheet.InsertArea(vSourceRowArea, vTargetRowArea, SpreadsheetDocumentShiftType.Vertical, True);
			vTargetRowArea = pSpreadsheet.Area(h - 1, , h - 1, );
			vTargetRowArea.Clear(True, True);
			// Add events name
			vEventsNameArea = pSpreadsheet.Area(h - 1, 2, h - 1, 2);
			vEventsNameArea.Text = NStr("en='Events';ru='Мероприятия';de='Veranstaltungen'");
			vEventsNameArea.Font = vDateArea.Font;
		EndIf;			
		// Do for each date from the report period
		vEventsRow = Undefined;
		vCommentIsPlaced = False;
		vCurDate = BegOfDay(PeriodFrom);
		vEndDate = BegOfDay(PeriodTo);
		p = 1;
		If vEvents.Count() > 0 Then
			p = 2;
		EndIf;
		While vCurDate <= vEndDate Do
			// Clear resource name
			If vResourcesCount > 1 Then
				vDayResourceArea = pSpreadsheet.Area(h - p, i, h - p, i);
				vDayResourceArea.Text = " ";
			EndIf;
			If vCurDate = vEndDate Then
				vDayDateArea = Undefined;
				If vResourcesCount > 1 Then
					vDayDateArea = pSpreadsheet.Area(h - p - 1, i, h - p - 1, i + vResourcesCount - 1);
				Else
					vDayDateArea = pSpreadsheet.Area(h - p, i, h - p, i + vResourcesCount - 1);
				EndIf;
				If vDayDateArea <> Undefined Then
					vDayDateArea.UndoMerge();
					If vResourcesCount > 1 Then
						vDayDateArea = pSpreadsheet.Area(h - p - 1, i, h - p - 1, i);
					Else
						vDayDateArea = pSpreadsheet.Area(h - p, i, h - p, i);
					EndIf;
					If vDayDateArea <> Undefined Then
						vDayDateArea.TextPlacement = SpreadsheetDocumentTextPlacementType.Wrap;
						vDayDateArea.BySelectedColumns = False;
						vDayDateArea.RightBorder = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
					EndIf;
					For k = 2 To vResourcesCount Do
						vDayResourceNameArea = pSpreadsheet.Area(h - p - 1, i + k - 1, h - p - 1, i + k - 1);
						vDayResourceArea = pSpreadsheet.Area(h - p, i + k - 1, h - p, i + k - 1);
						
						vDayResourceNameArea.Text = vDayResourceArea.Text;
						vDayResourceNameArea.TextPlacement = vDayResourceArea.TextPlacement;
						vDayResourceNameArea.BySelectedColumns = vDayResourceArea.BySelectedColumns;
						vDayResourceNameArea.RightBorder = vDayResourceArea.RightBorder;
						
						vDayResourceArea.Text = " ";
					EndDo;
					If vResourcesCount > 1 Then
						vResorcesRowArea = pSpreadsheet.Area(h - p, , h - p, );
						vResorcesRowArea.AutoRowHeight = False;
						vResorcesRowArea.RowHeight = 1;
					EndIf;
				EndIf;
			EndIf;
			If vEvents.Count() > 0 Then
				vEventArea = pSpreadsheet.Area(h - 1, i, h - 1, i);
				// Try to find event starting from this date
				vThisIsFirstPeriodOfEvent = False;
				vProbeEventsRow = vEvents.Find(vCurDate, "DateFrom");
				If vProbeEventsRow <> Undefined Then
					If vEventsRow = Undefined Then
						vEventsRow = vProbeEventsRow;
						vThisIsFirstPeriodOfEvent = True;
						vCommentIsPlaced = False;
					Else
						If vEventsRow <> vProbeEventsRow Then
							vEventsRow = vProbeEventsRow;
							vThisIsFirstPeriodOfEvent = True;
							vCommentIsPlaced = False;
						EndIf;
					EndIf;
				EndIf;
				vIsEventDate = False;
				If vEventsRow <> Undefined Then
					If vCurDate > vEventsRow.DateTo Or vCurDate < vEventsRow.DateFrom Then
						vEventsRow = Undefined;
					Else
						vIsEventDate = True;
					EndIf;
				EndIf;
				If vEventsRow <> Undefined And vIsEventDate Then
					If vThisIsFirstPeriodOfEvent Then
						vEventArea.Text = TrimAll(vEventsRow.Description);
					Else
						vEventArea.Text = "";
					EndIf;
					If vEventsRow.DateTo = BegOfDay(vCurDate) And Not vCommentIsPlaced Then
						vCommentIsPlaced = True;
						vEventArea.Comment.Text = Chars.LF + Chars.LF + TrimAll(Format(vEventsRow.DateFrom, "DF=dd.MM.yyyy") + " - " + Format(vEventsRow.DateTo, "DF=dd.MM.yyyy") + Chars.LF +
												  TrimAll(vEventsRow.Remarks));
					EndIf;
					For j = 1 To vResourcesCount Do
						vEventArea.Details = vEventsRow.Ref;
						vEventArea.TextPlacement = SpreadsheetDocumentTextPlacementType.Auto;
						vEventArea.BySelectedColumns = True;
						vEventArea.HorizontalAlign = HorizontalAlign.Left;
						vEventArea.VerticalAlign = VerticalAlign.Center;
						vEventColor = Undefined;
						If vEventsRow.Color <> Undefined Then
							vEventColor = vEventsRow.Color.Get();
						EndIf;
						vEventBackColor = EventBackColor;
						If vEventColor <> Undefined Then
							vEventBackColor = vEventColor;
						EndIf;
						vEventArea.BackColor = vEventBackColor;
						vEventArea.RightBorder = New Line(SpreadsheetDocumentCellLineType.None, 1);
						If Not vThisIsFirstPeriodOfEvent Or j > 1 Then
							vEventArea.LeftBorder = New Line(SpreadsheetDocumentCellLineType.None, 1);
							vEventArea.Clear(True);
						EndIf;
						// Next area
						i = i + 1;
						vEventArea = pSpreadsheet.Area(h - 1, i, h - 1, i);
					EndDo;
				ElsIf Not vIsEventDate Then
					For j = 1 To vResourcesCount Do
						vEventArea.Text = " ";
						vEventArea.Details = Catalogs.Events.EmptyRef();
						// Next area
						i = i + 1;
						vEventArea = pSpreadsheet.Area(h - 1, i, h - 1, i);
					EndDo;
				Else
					For j = 1 To vResourcesCount Do
						// Next area
						i = i + 1;
					EndDo;
				EndIf;
			Else
				For j = 1 To vResourcesCount Do
					// Next area
					i = i + 1;
				EndDo;
			EndIf;
			vCurDate = vCurDate + 24*3600;
		EndDo;
	EndIf;
	
	// Remove doubled hotel vacant room totals
	vGroupsCount = ReportBuilder.RowDimensions.Count();
	If vGroupsCount > 1 Then
		r1 = h + 1;
		r2 = h + 1 + vGroupsCount - 2;
		If r2 >= r1 And r2 <= pSpreadsheet.TableWidth Then
			vAreaToDelete = pSpreadsheet.Area(r1, , r2, );
			vAreaToDelete.Ungroup();
			pSpreadsheet.DeleteArea(vAreaToDelete, SpreadsheetDocumentShiftType.Vertical);
		EndIf;		
	EndIf;
	
	// Lock first h rows
	pSpreadsheet.FixedTop = h;
	
	// Add vacants name
	If h < pSpreadsheet.TableWidth And vDateArea <> Undefined Then
		vVacantsNameArea = pSpreadsheet.Area(h, 2, h, 2);
		vVacantsNameArea.FillType = SpreadsheetDocumentAreaFillType.Text;
		vVacantsNameArea.Text = NStr("en='Vacant';ru='Свободно';de='frei'");
		vVacantsNameArea.Font = vDateArea.Font;
	EndIf;
	
	// Check if we have to change width of the totals columns
	i = pSpreadsheet.TableWidth;
	While i > 0 Do
		vResourceTotalsArea = pSpreadsheet.Area(h, i, h, i);
		If vResourceTotalsArea.ColumnWidth < 1 Then
			vResourceTotalsArea.ColumnWidth = 12;
		Else
			Break;
		EndIf;
		i = i - 1;
	EndDo;
	
	// Try to place average resources data from the hidden columns 
	// to the total columns in the last report date
	If vResourcesCount > 1 Then
		vHiddenResources = New ValueList();
		For j = h To pSpreadsheet.TableHeight Do
			vHiddenResources.Clear();
			vHiddenColumnIndex = 0;
			For i = w To pSpreadsheet.TableWidth Do
				vResourceArea = pSpreadsheet.Area(j, i, j, i);
				If vResourceArea.ColumnWidth < 1 Then
					// This is hidden resource column
					vHiddenColumnIndex = vHiddenColumnIndex + 1;
					If vHiddenResources.Count() >= vHiddenColumnIndex Then 
						vHiddenResourcesItem = vHiddenResources.Get(vHiddenColumnIndex - 1);
						If ValueIsFilled(vHiddenResourcesItem.Value) Then
							If vHiddenResourcesItem.Value < TrimAll(vResourceArea.Text) Then
								vHiddenResourcesItem.Value = TrimAll(vResourceArea.Text);
							EndIf;
						Else
							vHiddenResourcesItem.Value = TrimAll(vResourceArea.Text);
						EndIf;
					Else
						vHiddenResources.Add(TrimAll(vResourceArea.Text));
					EndIf;
				Else
					vHiddenColumnIndex = 0;
				EndIf;
				If vHiddenResources.Count() > 0 And 
				   i > (pSpreadsheet.TableWidth - vHiddenResources.Count()) Then
					vTotalsColumnIndex = i - pSpreadsheet.TableWidth + vHiddenResources.Count() - 1;
					If vTotalsColumnIndex >= 0 Then
						vHiddenResourcesItem = vHiddenResources.Get(vTotalsColumnIndex);
						vResourceArea.Text = vHiddenResourcesItem.Value;
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	GuestGroupsForecast.Period AS Period,
	|	GuestGroupsForecast.Hotel AS Hotel,
	|	GuestGroupsForecast.ReservationStatus AS ReservationStatus,
	|	GuestGroupsForecast.RoomQuota AS RoomQuota,
	|	GuestGroupsForecast.RoomType AS RoomType,
	|	GuestGroupsForecast.GuestGroup AS GuestGroup,
	|	GuestGroupsForecast.GuestGroup.Customer AS Customer,
	|	GuestGroupsForecast.RoomsReserved AS RoomsReserved,
	|	GuestGroupsForecast.BedsReserved AS BedsReserved,
	|	GuestGroupsForecast.AdditionalBedsReserved AS AdditionalBedsReserved,
	|	GuestGroupsForecast.GuestsReserved AS GuestsReserved,
	|	GuestGroupsForecast.Revenue AS Revenue,
	|	GuestGroupsForecast.AveragePrice AS AveragePrice,
	|	GuestGroupsForecast.MinimumPrice AS MinimumPrice,
	|	GuestGroupsForecast.MaximumPrice AS MaximumPrice
	|{SELECT
	|	Hotel.*,
	|	RoomQuota.*,
	|	ReservationStatus.*,
	|	Customer.*,
	|	GuestGroup.*,
	|	RoomType.*,
	|	Period,
	|	RoomsReserved,
	|	BedsReserved,
	|	AdditionalBedsReserved,
	|	GuestsReserved,
	|	Revenue,
	|	AveragePrice,
	|	MinimumPrice,
	|	MaximumPrice}
	|FROM
	|	(SELECT
	|		PeriodDays.Period AS Period,
	|		ExpectedGuestGroupsTurnovers.Hotel AS Hotel,
	|		ExpectedGuestGroupsTurnovers.ReservationStatus AS ReservationStatus,
	|		ExpectedGuestGroupsTurnovers.RoomQuota AS RoomQuota,
	|		ExpectedGuestGroupsTurnovers.RoomType AS RoomType,
	|		ExpectedGuestGroupsTurnovers.GuestGroup AS GuestGroup,
	|		ExpectedGuestGroupsTurnovers.GuestGroup.Customer AS Customer,
	|		ExpectedGuestGroupsTurnovers.RoomsReservedTurnover AS RoomsReserved,
	|		ExpectedGuestGroupsTurnovers.BedsReservedTurnover AS BedsReserved,
	|		ExpectedGuestGroupsTurnovers.AdditionalBedsReservedTurnover AS AdditionalBedsReserved,
	|		ExpectedGuestGroupsTurnovers.GuestsReservedTurnover AS GuestsReserved,
	|		GroupRevenue.Revenue AS Revenue,
	|		GroupRevenue.AveragePrice AS AveragePrice,
	|		GroupRevenue.MinimumPrice AS MinimumPrice,
	|		GroupRevenue.MaximumPrice AS MaximumPrice,
	|		0 AS Dummy
	|	FROM
	|		(SELECT
	|			RoomInventoryTurnovers.Period AS Period,
	|			RoomInventoryTurnovers.Hotel AS Hotel,
	|			RoomInventoryTurnovers.CounterTurnover AS CounterTurnover
	|		FROM
	|			AccumulationRegister.RoomInventory.Turnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Day,
	|					(Hotel IN HIERARCHY (&qHotel)
	|						OR &qHotelIsEmpty)
	|						AND (RoomType IN HIERARCHY (&qRoomType)
	|							OR &qRoomTypeIsEmpty)) AS RoomInventoryTurnovers) AS PeriodDays
	|			LEFT JOIN AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Day,
	|					(Hotel IN HIERARCHY (&qHotel)
	|						OR &qHotelIsEmpty)
	|						AND CASE
	|							WHEN RoomQuota = VALUE(Catalog.RoomQuotas.EmptyRef)
	|								THEN TRUE
	|							WHEN GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|								THEN TRUE
	|							WHEN NOT ISNULL(RoomQuota.DoWriteOff, FALSE)
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|						AND (ReservationStatus IN HIERARCHY (&qReservationStatus)
	|							OR &qReservationStatusIsEmpty)
	|						AND (GuestGroup.Author IN HIERARCHY (&qManager)
	|							OR &qManagerIsEmpty)
	|						AND (RoomQuota IN HIERARCHY (&qRoomQuota)
	|							OR &qRoomQuotaIsEmpty)
	|						AND (RoomType IN HIERARCHY (&qRoomType)
	|							OR &qRoomTypeIsEmpty)
	|						AND (GuestGroup = &qGuestGroup
	|							OR &qGuestGroupIsEmpty)
	|						AND (GuestGroup.Customer IN HIERARCHY (&qCustomer)
	|							OR &qCustomerIsEmpty)) AS ExpectedGuestGroupsTurnovers
	|			ON PeriodDays.Period = ExpectedGuestGroupsTurnovers.Period
	|				AND PeriodDays.Hotel = ExpectedGuestGroupsTurnovers.Hotel
	|			LEFT JOIN (SELECT
	|				GroupSalesTotals.Hotel AS Hotel,
	|				GroupSalesTotals.GuestGroup AS GuestGroup,
	|				GroupSalesTotals.RoomQuota AS RoomQuota,
	|				GroupSalesTotals.ReservationStatus AS ReservationStatus,
	|				GroupSalesTotals.RoomType AS RoomType,
	|				GroupSalesTotals.TotalRevenue AS Revenue,
	|				CASE
	|					WHEN GroupSalesTotals.GuestGroup.Duration <> 0
	|						THEN CAST(GroupSalesTotals.TotalRevenue / GroupSalesTotals.GuestGroup.Duration AS NUMBER(17, 2))
	|					ELSE 0
	|				END AS AveragePrice,
	|				CASE
	|					WHEN GroupSalesTotals.MinimumRevenue = 999999999999
	|						THEN 0
	|					ELSE GroupSalesTotals.MinimumRevenue
	|				END AS MinimumPrice,
	|				GroupSalesTotals.MaximumRevenue AS MaximumPrice
	|			FROM
	|				(SELECT
	|					AccountsReceivableForecastTurnovers.Hotel AS Hotel,
	|					AccountsReceivableForecastTurnovers.GuestGroup AS GuestGroup,
	|					AccountsReceivableForecastTurnovers.ParentDoc.RoomQuota AS RoomQuota,
	|					AccountsReceivableForecastTurnovers.ParentDoc.ReservationStatus AS ReservationStatus,
	|					AccountsReceivableForecastTurnovers.ParentDoc.RoomType AS RoomType,
	|					SUM(AccountsReceivableForecastTurnovers.ExpectedSalesTurnover - AccountsReceivableForecastTurnovers.ExpectedCommissionSumTurnover) AS TotalRevenue,
	|					MIN(CASE
	|							WHEN AccountsReceivableForecastTurnovers.ExpectedRoomRevenueTurnover <> 0
	|								THEN AccountsReceivableForecastTurnovers.ExpectedSalesTurnover - AccountsReceivableForecastTurnovers.ExpectedCommissionSumTurnover
	|							ELSE 999999999999
	|						END) AS MinimumRevenue,
	|					MAX(CASE
	|							WHEN AccountsReceivableForecastTurnovers.ExpectedRoomRevenueTurnover <> 0
	|								THEN AccountsReceivableForecastTurnovers.ExpectedSalesTurnover - AccountsReceivableForecastTurnovers.ExpectedCommissionSumTurnover
	|							ELSE 0
	|						END) AS MaximumRevenue
	|				FROM
	|					AccumulationRegister.AccountsReceivableForecast.Turnovers(
	|							&qPeriodFrom,
	|							&qPeriodTo,
	|							Day,
	|							(Hotel IN HIERARCHY (&qHotel)
	|								OR &qHotelIsEmpty)
	|								AND (ParentDoc.ReservationStatus IN HIERARCHY (&qReservationStatus)
	|									OR &qReservationStatusIsEmpty)
	|								AND (GuestGroup.Author IN HIERARCHY (&qManager)
	|									OR &qManagerIsEmpty)
	|								AND (ParentDoc.RoomQuota IN HIERARCHY (&qRoomQuota)
	|									OR &qRoomQuotaIsEmpty)
	|								AND (ParentDoc.RoomType IN HIERARCHY (&qRoomType)
	|									OR &qRoomTypeIsEmpty)
	|								AND (GuestGroup = &qGuestGroup
	|									OR &qGuestGroupIsEmpty)
	|								AND (GuestGroup.Customer IN HIERARCHY (&qCustomer)
	|									OR &qCustomerIsEmpty)) AS AccountsReceivableForecastTurnovers
	|				
	|				GROUP BY
	|					AccountsReceivableForecastTurnovers.Hotel,
	|					AccountsReceivableForecastTurnovers.GuestGroup,
	|					AccountsReceivableForecastTurnovers.ParentDoc.RoomQuota,
	|					AccountsReceivableForecastTurnovers.ParentDoc.ReservationStatus,
	|					AccountsReceivableForecastTurnovers.ParentDoc.RoomType) AS GroupSalesTotals) AS GroupRevenue
	|			ON (GroupRevenue.GuestGroup = ExpectedGuestGroupsTurnovers.GuestGroup)
	|				AND (GroupRevenue.Hotel = ExpectedGuestGroupsTurnovers.Hotel)
	|				AND (GroupRevenue.RoomQuota = ExpectedGuestGroupsTurnovers.RoomQuota)
	|				AND (GroupRevenue.ReservationStatus = ExpectedGuestGroupsTurnovers.ReservationStatus)
	|				AND (GroupRevenue.RoomType = ExpectedGuestGroupsTurnovers.RoomType)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RIBalances.Period,
	|		RIBalances.Hotel,
	|		NULL,
	|		NULL,
	|		RIBalances.RoomType,
	|		NULL,
	|		NULL,
	|		RIBalances.RoomsVacantClosingBalance,
	|		RIBalances.BedsVacantClosingBalance,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		RIBalances.CounterClosingBalance
	|	FROM
	|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				RegisterRecordsAndPeriodBoundaries,
	|				&qRoomQuotaIsEmpty
	|					AND (Hotel IN HIERARCHY (&qHotel)
	|						OR &qHotelIsEmpty)) AS RIBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RQBalances.Period,
	|		RQBalances.Hotel,
	|		NULL,
	|		RQBalances.RoomQuota,
	|		RQBalances.RoomType,
	|		NULL,
	|		NULL,
	|		RQBalances.RoomsRemainsClosingBalance,
	|		RQBalances.BedsRemainsClosingBalance,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		RQBalances.CounterClosingBalance
	|	FROM
	|		AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				RegisterRecordsAndPeriodBoundaries,
	|				NOT &qRoomQuotaIsEmpty
	|					AND (Hotel IN HIERARCHY (&qHotel)
	|						OR &qHotelIsEmpty)) AS RQBalances) AS GuestGroupsForecast
	|{WHERE
	|	GuestGroupsForecast.Hotel.*,
	|	GuestGroupsForecast.ReservationStatus AS ReservationStatus,
	|	GuestGroupsForecast.RoomQuota.*,
	|	GuestGroupsForecast.RoomType.*,
	|	GuestGroupsForecast.GuestGroup.*,
	|	GuestGroupsForecast.GuestGroup.Customer.* AS Customer,
	|	GuestGroupsForecast.Period,
	|	GuestGroupsForecast.RoomsReserved AS RoomsReserved,
	|	GuestGroupsForecast.BedsReserved AS BedsReserved,
	|	GuestGroupsForecast.AdditionalBedsReserved AS AdditionalBedsReserved,
	|	GuestGroupsForecast.GuestsReserved AS GuestsReserved,
	|	GuestGroupsForecast.Revenue,
	|	GuestGroupsForecast.AveragePrice,
	|	GuestGroupsForecast.MinimumPrice,
	|	GuestGroupsForecast.MaximumPrice}
	|
	|ORDER BY
	|	Hotel,
	|	ReservationStatus,
	|	RoomQuota,
	|	RoomType,
	|	Customer,
	|	GuestGroup,
	|	Period
	|{ORDER BY
	|	Period,
	|	Hotel.*,
	|	ReservationStatus.*,
	|	RoomQuota.*,
	|	RoomType.*,
	|	GuestGroup.*,
	|	Customer.*,
	|	RoomsReserved,
	|	BedsReserved,
	|	AdditionalBedsReserved,
	|	GuestsReserved,
	|	Revenue,
	|	AveragePrice,
	|	MinimumPrice,
	|	MaximumPrice}
	|TOTALS
	|	SUM(RoomsReserved),
	|	SUM(BedsReserved),
	|	SUM(AdditionalBedsReserved),
	|	SUM(GuestsReserved),
	|	SUM(Revenue),
	|	MAX(AveragePrice),
	|	MIN(MinimumPrice),
	|	MAX(MaximumPrice)
	|BY
	|	Hotel,
	|	ReservationStatus,
	|	RoomQuota,
	|	RoomType,
	|	Customer,
	|	GuestGroup,
	|	Period
	|{TOTALS BY
	|	Period,
	|	ReservationStatus.*,
	|	Hotel.*,
	|	RoomQuota.*,
	|	RoomType.*,
	|	GuestGroup.*,
	|	Customer.*,
	|	Revenue,
	|	AveragePrice,
	|	MinimumPrice,
	|	MaximumPrice}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Expected guest groups';RU='Планируемые группы';de='Geplante Gruppe'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "RoomsReserved" 
	   Or pName = "BedsReserved" 
	   Or pName = "AdditionalBedsReserved" 
	   Or pName = "GuestsReserved" 
	   Or pName = "Revenue" 
	   Or pName = "AveragePrice" 
	   Or pName = "MinimumPrice" 
	   Or pName = "MaximumPrice" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// Event back color
EventBackColor = New Color(240, 240, 240);
