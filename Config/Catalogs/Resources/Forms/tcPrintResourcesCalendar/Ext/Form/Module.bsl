
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill settings
	SelHotel = Parameters.Hotel;
	SelGuestGroup = Parameters.GuestGroup;
	SelResource = Parameters.Resource;
	SelResourceType = Parameters.ResourceType;
	SelPeriodFrom = Parameters.PeriodFrom;
	SelPeriodTo = Parameters.PeriodTo;
	IsOneMonthScale = Parameters.IsOneMonthScale;
	IsOneWeekScale = Parameters.IsOneWeekScale;
	ResourceWidth = Parameters.ResourceWidth;
	ResourceHeight = Parameters.ResourceHeight;
	
	// Generate report
	GenerateReport();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeTimeScalePosition(pCommand)
	Items.FormChangeTimeScalePosition.Check = Not Items.FormChangeTimeScalePosition.Check;
	If Items.FormChangeTimeScalePosition.Check Then
		GenerateMirrorReport();	
	Else
		GenerateReport();	
	EndIf;
EndProcedure // ChangeTimeScalePosition

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GetResourceReservations()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ResourceReservations.Resource.Parent AS ResourceParent,
	|	ResourceReservations.Resource AS Resource,
	|	ResourceReservations.ResourceType AS ResourceType,
	|	ResourceReservations.Resource.Parent.SortCode AS ResourceParentSortCode,
	|	ResourceReservations.Resource AS ResourceSortCode,
	|	ResourceReservations.ResourceType.SortCode AS ResourceTypeSortCode,
	|	ResourceReservations.Recorder AS ResourceReservation,
	|	ResourceReservations.Hotel AS Hotel,
	|	ResourceReservations.Customer AS Customer,
	|	ResourceReservations.Contract AS Contract,
	|	ResourceReservations.Agent AS Agent,
	|	ResourceReservations.GuestGroup AS GuestGroup,
	|	ResourceReservations.ResourceReservationStatus AS ResourceReservationStatus,
	|	CASE
	|		WHEN ResourceReservations.DateTimeFrom < &qPeriodFrom
	|			THEN &qPeriodFrom
	|		ELSE ResourceReservations.DateTimeFrom
	|	END AS DateTimeFrom,
	|	ResourceReservations.Duration AS Duration,
	|	CASE
	|		WHEN ResourceReservations.DateTimeTo > &qPeriodTo
	|			THEN &qPeriodTo
	|		ELSE ResourceReservations.DateTimeTo
	|	END AS DateTimeTo,
	|	ResourceReservations.NumberOfPersons AS NumberOfPersons,
	|	ResourceReservations.Client AS Client,
	|	ResourceReservations.Company AS Company,
	|	ResourceReservations.ChargingFolio AS ChargingFolio,
	|	ResourceReservations.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	ResourceReservations.MarketingCode AS MarketingCode,
	|	ResourceReservations.SourceOfBusiness AS SourceOfBusiness,
	|	ResourceReservations.DiscountCard AS DiscountCard,
	|	ResourceReservations.DiscountType AS DiscountType,
	|	ResourceReservations.Discount AS Discount,
	|	ResourceReservations.CreditCard AS CreditCard,
	|	ResourceReservations.CustomerType AS CustomerType,
	|	ResourceReservations.ClientType AS ClientType,
	|	ResourceReservations.Recorder.ContactPerson AS ContactPerson,
	|	ResourceReservations.Recorder.Remarks AS Remarks,
	|	ResourceReservations.Period AS PointInTime,
	|	ResourceReservations.Recorder.ResourceTableConfiguration AS ResourceTableConfiguration,
	|	ResourceReservations.EventActivity AS EventActivity,
	|	ResourceReservations.IsPreparationTime AS IsPreparationTime,
	|	ResourceReservations.IsDisassembleTime AS IsDisassembleTime
	|FROM
	|	InformationRegister.ResourceReservationHistory AS ResourceReservations
	|WHERE
	|	NOT ResourceReservations.Resource.DeletionMark
	|	AND ISNULL(ResourceReservations.ResourceReservationStatus.IsActive, FALSE)
	|	AND (ResourceReservations.Resource.Hotel IN HIERARCHY (&qHotel)
	|			OR ResourceReservations.Resource.Hotel = &qEmptyHotel
	|			OR &qHotelIsEmpty)
	|	AND (ResourceReservations.ResourceType IN HIERARCHY (&qResourceType)
	|			OR &qResourceTypeIsEmpty)
	|	AND (ResourceReservations.Resource IN HIERARCHY (&qResource)
	|			OR &qResourceIsEmpty)
	|	AND ResourceReservations.DateTimeFrom < &qPeriodTo
	|	AND ResourceReservations.DateTimeTo > &qPeriodFrom
	|
	|ORDER BY
	|	ResourceTypeSortCode,
	|	ResourceParentSortCode,
	|	ResourceSortCode,
	|	PointInTime";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qResourceType", SelResourceType);
	vQry.SetParameter("qResourceTypeIsEmpty", Not ValueIsFilled(SelResourceType));
	vQry.SetParameter("qResource", SelResource);
	vQry.SetParameter("qResourceIsEmpty", Not ValueIsFilled(SelResource));
	vQry.SetParameter("qPeriodFrom", SelPeriodFrom);
	vQry.SetParameter("qPeriodTo", SelPeriodTo);
	vQry.SetParameter("qEmptyResource", Catalogs.Resources.EmptyRef());
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	Return vQry.Execute().Unload();
EndFunction // GetResourceReservations

// -----------------------------------------------------------------------------
&AtServer
Function GetResources()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Resources.Parent AS ResourceParent,
	|	Resources.Ref AS Resource,
	|	Resources.Owner.SortCode AS ResourceTypeSortCode,
	|	Resources.Parent.SortCode AS ResourceParentSortCode,
	|	Resources.SortCode AS ResourceSortCode
	|FROM
	|	Catalog.Resources AS Resources
	|WHERE
	|	NOT Resources.DeletionMark
	|	AND (Resources.Hotel IN HIERARCHY (&qHotel)
	|			OR Resources.Hotel = &qEmptyHotel
	|			OR &qHotelIsEmpty)
	|	AND (Resources.Owner IN HIERARCHY (&qResourceType)
	|			OR &qResourceTypeIsEmpty)
	|	AND (Resources.Ref IN HIERARCHY (&qResource)
	|			OR &qResourceIsEmpty)
	|	AND NOT Resources.Ref IN
	|				(SELECT
	|					ResourceParents.Parent
	|				FROM
	|					Catalog.Resources AS ResourceParents
	|				WHERE
	|					NOT ResourceParents.DeletionMark
	|					AND (ResourceParents.Hotel IN HIERARCHY (&qHotel)
	|						OR ResourceParents.Hotel = &qEmptyHotel
	|						OR &qHotelIsEmpty)
	|					AND (ResourceParents.Owner IN HIERARCHY (&qResourceType)
	|						OR &qResourceTypeIsEmpty)
	|					AND ResourceParents.Parent <> &qEmptyResource)
	|
	|ORDER BY
	|	ResourceTypeSortCode,
	|	ResourceParentSortCode,
	|	ResourceSortCode";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qResourceType", SelResourceType);
	vQry.SetParameter("qResourceTypeIsEmpty", Not ValueIsFilled(SelResourceType));
	vQry.SetParameter("qResource", SelResource);
	vQry.SetParameter("qResourceIsEmpty", Not ValueIsFilled(SelResource));
	vQry.SetParameter("qEmptyResource", Catalogs.Resources.EmptyRef());
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	Return vQry.Execute().Unload();
EndFunction // GetResources

// -----------------------------------------------------------------------------
&AtServer
Function GetWorkingTimes()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CalendarDays.AccountingDate AS Period,
	|	CalendarDays.Calendar AS Calendar,
	|	CalendarDays.CalendarDayType AS CalendarDayType,
	|	CalendarDays.Timetable AS Timetable,
	|	ISNULL(WorkingTimes.TimeFrom, &qEmptyDate) AS TimeFrom,
	|	ISNULL(WorkingTimes.TimeTo, &qEmptyDate) AS TimeTo
	|FROM
	|	InformationRegister.CalendarDays.SliceLast(
	|			,
	|			Calendar IN
	|					(SELECT
	|						Resources.Calendar
	|					FROM
	|						Catalog.Resources AS Resources
	|					WHERE
	|						NOT Resources.DeletionMark
	|						AND (Resources.Hotel IN HIERARCHY (&qHotel)
	|							OR &qHotelIsEmpty)
	|						AND (Resources.Owner IN HIERARCHY (&qResourceType)
	|							OR &qResourceTypeIsEmpty)
	|						AND (Resources.Ref IN HIERARCHY (&qResource)
	|							OR &qResourceIsEmpty)
	|					GROUP BY
	|						Resources.Calendar)
	|				AND AccountingDate >= &qPeriodFrom
	|				AND AccountingDate < &qPeriodTo) AS CalendarDays
	|		LEFT JOIN Catalog.Timetables.WorkingTimes AS WorkingTimes
	|		ON CalendarDays.Timetable = WorkingTimes.Ref
	|
	|ORDER BY
	|	CalendarDays.AccountingDate,
	|	Calendar,
	|	TimeFrom";
	vQry.SetParameter("qPeriodFrom", SelPeriodFrom);
	vQry.SetParameter("qPeriodTo", SelPeriodTo);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qResourceType", SelResourceType);
	vQry.SetParameter("qResourceTypeIsEmpty", Not ValueIsFilled(SelResourceType));
	vQry.SetParameter("qResource", SelResource);
	vQry.SetParameter("qResourceIsEmpty", Not ValueIsFilled(SelResource));
	Return vQry.Execute().Unload();
EndFunction // GetWorkingTimes

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckIfHourIsWorking(pWorkingTimes, pCalendar, pPeriod, pHour, rIsWorkingHour, rIsWorkingHalfHour)
	rIsWorkingHour = False;
	rIsWorkingHalfHour = False;
	vDayWorkingTimes = pWorkingTimes.FindRows(New Structure("Calendar, Period", pCalendar, pPeriod));
	For Each vDayWorkingTimesRow In vDayWorkingTimes Do
		If ValueIsFilled(vDayWorkingTimesRow.Timetable) Then
			vStartOfCurWorkingPeriod = pPeriod + (vDayWorkingTimesRow.TimeFrom - BegOfDay(vDayWorkingTimesRow.TimeFrom));
			vEndOfCurWorkingPeriod = pPeriod + (vDayWorkingTimesRow.TimeTo - BegOfDay(vDayWorkingTimesRow.TimeTo));
			If pHour >= vStartOfCurWorkingPeriod And 
			   pHour < vEndOfCurWorkingPeriod Then
				rIsWorkingHour = True;
			EndIf;
			If (pHour + 30*60) >= vStartOfCurWorkingPeriod And 
			   (pHour + 30*60) < vEndOfCurWorkingPeriod Then
				rIsWorkingHalfHour = True;
			EndIf;
			If rIsWorkingHour Or rIsWorkingHalfHour Then
				Break;
			EndIf;
		Else
			Break;
		EndIf;
	EndDo;
EndProcedure // CheckIfHourIsWorking

// -----------------------------------------------------------------------------
&AtServer
Procedure GetResourceReservationAreaJoinParameters(pQryRow, pResources, rNumberOfResourcesToJoin, rDurationInFullHours, rDurationInHalfHours, rTriggerResource, rTriggerResourceIndex)
	// Duration in full hours
	rDurationInFullHours = 1;
	vDuration = cmCalculateDurationInHours(pQryRow.DateTimeFrom, pQryRow.DateTimeTo);
	If Int(vDuration) <> vDuration Then
		rDurationInFullHours = Int(vDuration) + 1;
	Else
		rDurationInFullHours = Int(vDuration);
	EndIf;
	// Duration in half hours
	rDurationInHalfHours = 2;
	If Int(vDuration) <> vDuration Then
		If (vDuration - Int(vDuration)) <= 0.5 Then
			rDurationInHalfHours = Int(vDuration)*2 + 1;
		Else
			rDurationInHalfHours = (Int(vDuration) + 1)*2;
		EndIf;
	Else
		rDurationInHalfHours = Int(vDuration)*2;
	EndIf;
	// Trigger resource and number of resources to join
	rNumberOfResourcesToJoin = 1;
	rTriggerResource = pQryRow.Resource;
	vParentResourceChildren = pResources.FindRows(New Structure("ResourceParent", pQryRow.Resource));
	If vParentResourceChildren.Count() > 0 Then
		rNumberOfResourcesToJoin = vParentResourceChildren.Count();
		rTriggerResource = vParentResourceChildren.Get(rNumberOfResourcesToJoin-1).Resource;
	EndIf;
	// Get trigger resource index
	rTriggerResourceIndex = pResources.Count();
	vTriggerResourceRow = pResources.Find(rTriggerResource, "Resource");
	If vTriggerResourceRow <> Undefined Then
		rTriggerResourceIndex = pResources.IndexOf(vTriggerResourceRow);
	EndIf;
EndProcedure // GetResourceReservationAreaJoinParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure ResourceReservationDescriptionReplace(pText, pQryRow)
	pText = StrReplace(pText, "&EventActivity", TrimAll(pQryRow.EventActivity)); 
	vGuestGroup = pQryRow.GuestGroup; 
	If ValueIsFilled(vGuestGroup) Then
		pText = StrReplace(pText, "&GuestGroupCode", TrimAll(vGuestGroup.Code));
		pText = StrReplace(pText, "&GuestGroupDescription", TrimAll(vGuestGroup.Description));
		If ValueIsFilled(vGuestGroup.Allotment) Then
			pText = StrReplace(pText, "&RoomQuotas", TrimAll(vGuestGroup.Allotment));
		Else
			pText = StrReplace(pText, "&RoomQuotas", "");	
		EndIf;
	Else
		pText = StrReplace(pText, "&GuestGroupCode", "");
		pText = StrReplace(pText, "&GuestGroupDescription", "");
		pText = StrReplace(pText, "&RoomQuotas", "");
	EndIf;
	pText = StrReplace(pText, "&NumberOfPersons", Format(pQryRow.NumberOfPersons, "NG="));
	pText = StrReplace(pText, "&Client", TrimAll(pQryRow.Client.FullName));
	pText = StrReplace(pText, "&Customer", TrimAll(pQryRow.Customer));
	pText = StrReplace(pText, "&DateTimeFrom", Format(pQryRow.DateTimeFrom, "DF='dd.MM.yyyy HH:mm'"));
	pText = StrReplace(pText, "&DateTimeTo", Format(pQryRow.DateTimeTo, "DF='dd.MM.yyyy HH:mm'"));
EndProcedure // ResourceReservationDescriptionReplace

// -----------------------------------------------------------------------------
&AtServer
Function GetResourceReservationDescription(vQryRow) 
	vDescription = "";
	
	If ValueIsFilled(vQryRow.ResourceType) Then
		vDescription = TrimAll(vQryRow.ResourceType.ResourceReservationDescriptionTemplate); 			
	EndIf;
	
	If ValueIsFilled(vDescription) Then
		ResourceReservationDescriptionReplace(vDescription, vQryRow);		
	Else
		vEventActivity = vQryRow.EventActivity;
		If ValueIsFilled(vEventActivity) Then
			vDescription = TrimAll(vEventActivity); 	
		EndIf;
		vGuestGroup = vQryRow.GuestGroup;      
		If ValueIsFilled(vGuestGroup) Then 
			vDescription = vDescription + ?(ValueIsFilled(vDescription), " - ", "") + NStr("en='Gr. '; ru='Гр. '; de='Gr. '") + TrimAll(vGuestGroup.Code) + ?(IsBlankString(vGuestGroup.Description), "", " - " + TrimAll(vGuestGroup.Description));
			If ValueIsFilled(vGuestGroup.Allotment) Then
				vDescription = vDescription + ?(ValueIsFilled(vDescription), " - ", "") + TrimAll(vGuestGroup.Allotment);	
			EndIf;	
		EndIf; 
	EndIf;
	Return vDescription;
EndFunction // GetResourceReservationDescription

// -----------------------------------------------------------------------------
&AtServer
Procedure AddResourceMaximumNumberOfPersonsAndPrice(pResourceDescription, pResource)
	// Add maximum number of persons for the resource
	If pResource.ShowNumberOfPersonsPerResource And pResource.NumberOfPersonsPerResource > 0 Then
		pResourceDescription = pResourceDescription + ", " + 
		                       Format(pResource.NumberOfPersonsPerResource, "ND=6; NFD=0; NZ=; NG=") + 
		                       NStr("en=' prs.';ru=' чел.';de=' prs.'");
	EndIf;
	// Add resource price
	If pResource.ShowPrice Then
		vPrices = cmGetResourcePrices(SelHotel, SelPeriodFrom, SelPeriodTo, Catalogs.ClientTypes.EmptyRef(), pResource.Owner, pResource, Undefined);
		For Each vPricesRow In vPrices Do
			If vPricesRow.Price <> Null And vPricesRow.Price > 0 Then
				pResourceDescription = pResourceDescription + ", " + 
				                       cmFormatSum(vPricesRow.Price, vPricesRow.Currency);
				Break;
			Else
				Break;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // AddResourceMaximumNumberOfPersonsAndPrice 

// -----------------------------------------------------------------------------
&AtServer
Procedure GenerateReport()
	Var vIsWorkingHour;
	Var vIsWorkingHalfHour;
	Var vNumberOfResourcesToJoin;
	Var vTriggerResource;
	Var vTriggerResourceIndex;
	Var vDurationInFullHours;
	Var vDurationInHalfHours;
	// Clear spreadsheet
	vSpreadsheet = ReportSpreadsheet;
	vSpreadsheet.Clear();
	// Retrieve resources
	vResources = GetResources();
	// Retrieve resource reservations
	vResourceReservations = GetResourceReservations();
	// Retrieve resources count
	vResourcesCount = vResources.Count();
	// Fill value table with working periods for the all resource calendars
	vWorkingTimes = GetWorkingTimes();
	// Get report template
	vTemplate = Catalogs.Resources.GetTemplate("ResourcesCalendar");
	// Filter
	vArea = vTemplate.GetArea("Filter");
	vArea.Parameters.mFilter = NStr("en='Filter: ';ru='Отбор: ';de='Auswahl: '") + GetReportParametersPresentation();
	vSpreadsheet.Put(vArea);
	// Resources header
	vArea = vTemplate.GetArea("Header|Times");
	vArea.Parameters.mPeriodFrom = cmGetDayOfWeekName(WeekDay(SelPeriodFrom)) + " - " + Format(SelPeriodFrom, "DF=dd.MM.yyyy");
	vSpreadsheet.Put(vArea);
	// Print report header with resource names
	vCurResourceParent = Catalogs.Resources.EmptyRef();
	vCurResource = Catalogs.Resources.EmptyRef();
	For Each vQryRow In vResources Do
		// Print period header if necessary
		If vQryRow.Resource <> vCurResource Then
			vCurResource = vQryRow.Resource;
			vArea = vTemplate.GetArea("Header|Resource");
			If ValueIsFilled(vQryRow.ResourceParent) Then
				If vQryRow.ResourceParent <> vCurResourceParent Then
					vCurResourceParent = vQryRow.ResourceParent;
					// Fill resource parent name
					vArea.Parameters.mResourceParent = TrimAll(vQryRow.ResourceParent.Description);
					AddResourceMaximumNumberOfPersonsAndPrice(vArea.Parameters.mResourceParent, vQryRow.ResourceParent);
					vArea.Parameters.mResourceParentDetail = vQryRow.ResourceParent;
					// Remove right border line
					vResourceParentArea = vArea.Area("ResourceParent");
					vResourceParentArea.RightBorder = New Line(SpreadsheetDocumentDrawingLineType.None);
					// Add comments with resource messages
					vMessages = cmGetMessagesForObject(vQryRow.ResourceParent);
					If vMessages.Count() > 0 Then
						vMessagesStr = cmGetMessagesPresentationForObject(vMessages, vQryRow.ResourceParent);
						vArea.Area("ResourceParent").Comment.Text = vMessagesStr;
					EndIf;
					// Fill resource item name
					vArea.Parameters.mResource = TrimAll(vQryRow.Resource.Description);
					AddResourceMaximumNumberOfPersonsAndPrice(vArea.Parameters.mResource, vQryRow.Resource);
					vArea.Parameters.mResourceDetail = vQryRow.Resource;
					// Add comments with resource messages
					vMessages = cmGetMessagesForObject(vQryRow.Resource);
					If vMessages.Count() > 0 Then
						vMessagesStr = cmGetMessagesPresentationForObject(vMessages, vQryRow.Resource);
						vArea.Area("ResourceItem").Comment.Text = vMessagesStr;
					EndIf;
				Else
					// Get last resource for the given parent
					vLastResource = Undefined;
					vParentResourceChildren = vResources.FindRows(New Structure("ResourceParent", vQryRow.ResourceParent));
					If vParentResourceChildren.Count() > 0 Then
						vLastResource = vParentResourceChildren.Get(vParentResourceChildren.Count()-1).Resource;
					EndIf;
					// Remove border lines
					vResourceParentArea = vArea.Area("ResourceParent");
					vResourceParentArea.LeftBorder = New Line(SpreadsheetDocumentDrawingLineType.None);
					If vQryRow.Resource <> vLastResource Then
						vResourceParentArea.RightBorder = New Line(SpreadsheetDocumentDrawingLineType.None);
					EndIf;
					// Fill resource item name
					vArea.Parameters.mResource = TrimAll(vQryRow.Resource.Description);
					AddResourceMaximumNumberOfPersonsAndPrice(vArea.Parameters.mResource, vQryRow.Resource);
					vArea.Parameters.mResourceDetail = vQryRow.Resource;
					vArea.Parameters.mResourceParentDetail = vQryRow.ResourceParent;
					// Add comments with resource messages
					vMessages = cmGetMessagesForObject(vQryRow.Resource);
					If vMessages.Count() > 0 Then
						vMessagesStr = cmGetMessagesPresentationForObject(vMessages, vQryRow.Resource);
						vArea.Area("ResourceItem").Comment.Text = vMessagesStr;
					EndIf;
					// Clear resource parent area text to force group by selected columns flag to work
					vResourceParentArea.Clear();
				EndIf;
			Else
				// Join parent and item areas
				vResourceMergedArea = vArea.Area("ResourceMerged");
				vResourceMergedArea.Merge();
				// Fill resource item name
				vArea.Parameters.mResourceParent = TrimAll(vQryRow.Resource.Description);
				AddResourceMaximumNumberOfPersonsAndPrice(vArea.Parameters.mResourceParent, vQryRow.Resource);
				vArea.Parameters.mResourceParentDetail = vQryRow.Resource;
				// Add comments with resource messages
				vMessages = cmGetMessagesForObject(vQryRow.Resource);
				If vMessages.Count() > 0 Then
					vMessagesStr = cmGetMessagesPresentationForObject(vMessages, vQryRow.Resource);
					vArea.Area("ResourceMerged").Comment.Text = vMessagesStr;
				EndIf;
			EndIf;
			vSpreadsheet.Join(vArea);
		EndIf;
	EndDo;
	// Choose different drawing styles for month scale and others
	If IsOneMonthScale Then
		// Iterate thru all hours of the period selected
		vCurPeriod = SelPeriodFrom;
		While vCurPeriod < SelPeriodTo Do
			// Hour header
			vArea = vTemplate.GetArea("MonthDay|Times");
			If vCurPeriod = SelPeriodFrom Or vCurPeriod = BegOfMonth(vCurPeriod) Then
				vArea.Parameters.mMonthName = cmGetMonthName(Month(vCurPeriod)) + " " + Format(vCurPeriod, "DF=yyyy");
			Else
				vArea.Parameters.mMonthName = "";
			EndIf;
			vArea.Parameters.mDate = cmGetDayOfWeekName(WeekDay(vCurPeriod)) + " " + Format(vCurPeriod, "DF=dd");
			vArea.Parameters.mCalendarDate = vCurPeriod;
			// Fill weekends color
			If WeekDay(vCurPeriod) > 5 Then
				vArea.Area("WeekDayRange").BackColor = WindowsColors.ButtonHighlight;
			EndIf;
			// Put area
			vSpreadsheet.Put(vArea);
			// Join month name column
			vNumDays = 0;
			If EndOfDay(vCurPeriod) = SelPeriodTo Then
				vNumDays = Round((SelPeriodTo - BegOfMonth(SelPeriodTo))/(24*3600), 0);
			ElsIf EndOfDay(vCurPeriod) = EndOfMonth(vCurPeriod) Then
				vNumDays = Round((EndOfMonth(vCurPeriod) - BegOfDay(SelPeriodFrom))/(24*3600), 0);
			EndIf;
			If vNumDays > 1 Then
				vMonthArea = vSpreadsheet.Area(vSpreadsheet.TableHeight - vNumDays + 1, 1, vSpreadsheet.TableHeight, 1);
				vMonthArea.Merge();
			EndIf;
			// Print current day and resource reservations started on it
			vArea = vTemplate.GetArea("MonthDay|Resource");
			vCurResource = Catalogs.Resources.EmptyRef();
			For Each vQryRow In vResources Do
				// Build current date resource reservations description
				If vQryRow.Resource <> vCurResource Then
					vCurResource = vQryRow.Resource;
					vResourceDay = "";
					vResourceDayHeight = 0;
					// Check an print resource reservations ending here
					vReservationsPerResource = vResourceReservations.FindRows(New Structure("Resource", vCurResource));
					vReservationsPerResourceParent = vResourceReservations.FindRows(New Structure("Resource", vCurResource.Parent));
					For Each vReservationsPerResourceParentRow In vReservationsPerResourceParent Do
						vReservationsPerResource.Add(vReservationsPerResourceParentRow);
					EndDo;
					For Each vReservationsPerResourceRow In vReservationsPerResource Do
						// Build short resource reservation description
						If ValueIsFilled(vReservationsPerResourceRow.ResourceReservation) Then
							If vReservationsPerResourceRow.DateTimeFrom > vCurPeriod And vReservationsPerResourceRow.DateTimeFrom <= EndOfDay(vCurPeriod) Or 
							   vReservationsPerResourceRow.DateTimeTo > vCurPeriod And vReservationsPerResourceRow.DateTimeTo <= EndOfDay(vCurPeriod) Then
								// Get number of columns to join and resource to trigger joining
								GetResourceReservationAreaJoinParameters(vReservationsPerResourceRow, vResources, vNumberOfResourcesToJoin, vDurationInFullHours, vDurationInHalfHours, vTriggerResource, vTriggerResourceIndex);
								// Fill resource reservation description
								If vTriggerResource = vCurResource Then
									vResourceDay = vResourceDay + GetResourceReservationDescription(vReservationsPerResourceRow) + Chars.LF;
									vResourceDayHeight = vResourceDayHeight + 1;
								EndIf;
							EndIf;
						EndIf;
					EndDo;
					vResourceDay = TrimAll(vResourceDay);
					If vResourceDayHeight < 2 Then
						If vResourceDayHeight = 0 Then
							vResourceDay = vResourceDay + Chars.LF + Chars.LF;
						ElsIf vResourceDayHeight = 1 Then
							vResourceDay = vResourceDay + Chars.LF;
						EndIf;
					EndIf;
					// Join resource date
					vArea.Parameters.mResourceDay = vResourceDay;
					vSpreadsheet.Join(vArea);
				EndIf;
			EndDo; // By resources and resource reservations
			// Go to the next day
			vCurPeriod = vCurPeriod + 24*3600;
		EndDo; // By days
		// Add delimeter line at the end of the report
		vArea = vTemplate.GetArea("DayDelimeter|Times");
		vSpreadsheet.Put(vArea);
		For i = 1 To vResourcesCount Do
			vArea = vTemplate.GetArea("DayDelimeter|Resource");
			vSpreadsheet.Join(vArea);
		EndDo;
	Else
		vUse24Hours = False;
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
				If SessionParameters.CurrentUser.EmployeePreferences.Use24ForMidnightInResourcesCalendar Then
					vUse24Hours = True;
				EndIf;
			EndIf;
		EndIf;
		// Iterate thru all hours of the period selected
		vCurHour = SelPeriodFrom;
		While vCurHour < SelPeriodTo Do
			vCurPeriod = BegOfDay(vCurHour);
			vCurHourNumber = Int((vCurHour - BegOfDay(vCurHour))/3600);
			vRemoveTopBorder = False;
			// Hour header
			If IsOneWeekScale Then
				vArea = vTemplate.GetArea("WeekHour|Times");
				If Int(vCurHourNumber/3) = vCurHourNumber/3 Then
					If vUse24Hours Then
						vArea.Parameters.mHour = Format((vCurHourNumber + 3), "ND=2; NFD=0; NZ=; NLZ=");
					Else
						vArea.Parameters.mHour = Format(vCurHourNumber, "ND=2; NFD=0; NZ=; NLZ=");
					EndIf;
					vArea.Parameters.mMinutes = "00";
				Else
					vArea.Parameters.mHour = "";
					vArea.Parameters.mMinutes = "";
					vRemoveTopBorder = True;
				EndIf;
			Else
				vArea = vTemplate.GetArea("DayHour|Times");
				vArea.Parameters.mHour = Format(vCurHourNumber, "ND=2; NFD=0; NZ=; NLZ=");
				vArea.Parameters.mMinutes = "00";
				vArea.Parameters.mMinutes30 = "";
			EndIf;
			If vCurHour = vCurPeriod Then
				vArea.Parameters.mDate = cmGetDayOfWeekName(WeekDay(vCurPeriod)) + " - " + Format(vCurPeriod, "L=" + TrimAll(SessionParameters.CurrentLanguage.LocalizationCode) + "; DLF=DD");
				vArea.Parameters.mCalendarDate = vCurPeriod;
			Else
				vArea.Parameters.mDate = "";
				vArea.Parameters.mCalendarDate = vCurPeriod;
			EndIf;
			If WeekDay(vCurHour) > 5 Then
				If IsOneWeekScale Then
					vArea.Area("WeekHourRange").BackColor = WindowsColors.ButtonHighlight;
				Else
					vArea.Area("DayHourRange").BackColor = WindowsColors.ButtonHighlight;
				EndIf;
			EndIf;
			vSpreadsheet.Put(vArea);
			// Join hours
			If IsOneWeekScale Then
				If Int((vCurHourNumber+1)/3) = (vCurHourNumber+1)/3 Then
					vSpreadsheet.Area(vSpreadsheet.TableHeight - 2, 4, vSpreadsheet.TableHeight, 4).Merge();
					vSpreadsheet.Area(vSpreadsheet.TableHeight - 2, 5, vSpreadsheet.TableHeight, 5).Merge();
				EndIf;
			EndIf;
			// Join day column
			If vCurHourNumber = 23 Then
				If IsOneWeekScale Then
					vDayArea = vSpreadsheet.Area(vSpreadsheet.TableHeight - 23, 1, vSpreadsheet.TableHeight, 1);
					vDayArea.Merge();
				Else
					vDayArea = vSpreadsheet.Area(vSpreadsheet.TableHeight - 47, 1, vSpreadsheet.TableHeight, 1);
					vDayArea.Merge();
				EndIf;
				If WeekDay(vCurHour) > 5 Then
					vDayArea.BackColor = WindowsColors.ButtonHighlight;
				EndIf;
			EndIf;
			// Print current hour and resource reservations started on it
			vCurResource = Catalogs.Resources.EmptyRef();
			For Each vQryRow In vResources Do
				// Print resource hour
				If vQryRow.Resource <> vCurResource Then
					vCurResource = vQryRow.Resource;
					// Check if current hour is working one
					If Not vCurResource.RoundTheClockOperation Then
						CheckIfHourIsWorking(vWorkingTimes, vCurResource.Calendar, vCurPeriod, vCurHour, vIsWorkingHour, vIsWorkingHalfHour);
					Else
						vIsWorkingHour = True;
						vIsWorkingHalfHour = True;
					EndIf;
					// Get resource hour template area
					If IsOneWeekScale Then
						vArea = vTemplate.GetArea("WeekHour|Resource");
						// Change area color if this hour is not working
						If Not vIsWorkingHour Or Not vIsWorkingHalfHour Then
							vArea.Area("ResourceHour").BackColor = WebColors.LightGoldenRodYellow;
						EndIf;
					Else
						vArea = vTemplate.GetArea("DayHour|Resource");
						// Change area color if this hour is not working
						If Not vIsWorkingHour Then
							vArea.Area("ResourceHour00").BackColor = WebColors.LightGoldenRodYellow;
						EndIf;
						If Not vIsWorkingHalfHour Then
							vArea.Area("ResourceHour30").BackColor = WebColors.LightGoldenRodYellow;
						EndIf;
					EndIf;
					vOutputArea = vSpreadsheet.Join(vArea);
					If vRemoveTopBorder Then
						vOutputArea.TopBorder = New Line(SpreadsheetDocumentCellLineType.None);
					EndIf;
					// Check an print resource reservations ending here
					vReservationsPerResource = vResourceReservations.FindRows(New Structure("Resource", vCurResource));
					vReservationsPerResourceParent = vResourceReservations.FindRows(New Structure("Resource", vCurResource.Parent));
					For Each vReservationsPerResourceParentRow In vReservationsPerResourceParent Do
						vReservationsPerResource.Add(vReservationsPerResourceParentRow);
					EndDo;
					For Each vReservationsPerResourceRow In vReservationsPerResource Do
						// Print resource reservation
						If ValueIsFilled(vReservationsPerResourceRow.ResourceReservation) Then
							vResourceReservationArea = Undefined;
							If IsOneWeekScale Then
								If vReservationsPerResourceRow.DateTimeTo > vCurHour And vReservationsPerResourceRow.DateTimeTo <= (vCurHour + 3600) Then
									// Get number of columns to join and resource to trigger joining
									GetResourceReservationAreaJoinParameters(vReservationsPerResourceRow, vResources, vNumberOfResourcesToJoin, vDurationInFullHours, vDurationInHalfHours, vTriggerResource, vTriggerResourceIndex);
									// Correct duration in full hous if reservation period start and reservation period end are in different days
									vDayDiff = Round((BegOfDay(vReservationsPerResourceRow.DateTimeTo) - BegOfDay(vReservationsPerResourceRow.DateTimeFrom))/(24*3600), 0);
									If vDayDiff > 0 Then
										vDurationInFullHours = vDurationInFullHours + vDayDiff*2;
									EndIf;
									// Join resource reservation period
									If vTriggerResource = vCurResource Then
										vResourceReservationArea = vSpreadsheet.Area(vSpreadsheet.TableHeight - vDurationInFullHours + 1, vTriggerResourceIndex + 8 - vNumberOfResourcesToJoin + 1, vSpreadsheet.TableHeight, vTriggerResourceIndex + 8);
										vResourceReservationArea.Merge();
									EndIf;
								EndIf;
							Else
								If vReservationsPerResourceRow.DateTimeTo > vCurHour And vReservationsPerResourceRow.DateTimeTo <= (vCurHour + 1800) Then
									// Get number of columns to join and resource to trigger joining
									GetResourceReservationAreaJoinParameters(vReservationsPerResourceRow, vResources, vNumberOfResourcesToJoin, vDurationInFullHours, vDurationInHalfHours, vTriggerResource, vTriggerResourceIndex);
									// Correct duration in full hous if reservation period start and reservation period end are in different days
									vDayDiff = Round((BegOfDay(vReservationsPerResourceRow.DateTimeTo) - BegOfDay(vReservationsPerResourceRow.DateTimeFrom))/(24*3600), 0);
									If vDayDiff > 0 Then
										vDurationInHalfHours = vDurationInHalfHours + vDayDiff*2;
									EndIf;
									// Join resource reservation period
									If vTriggerResource = vCurResource Then
										vResourceReservationArea = vSpreadsheet.Area(vSpreadsheet.TableHeight - vDurationInHalfHours, vTriggerResourceIndex + 8 - vNumberOfResourcesToJoin + 1, vSpreadsheet.TableHeight - 1, vTriggerResourceIndex + 8);
										vResourceReservationArea.Merge();
									EndIf;
								ElsIf vReservationsPerResourceRow.DateTimeTo > (vCurHour + 1800) And vReservationsPerResourceRow.DateTimeTo <= (vCurHour + 3600) Then
									// Get number of columns to join and resource to trigger joining
									GetResourceReservationAreaJoinParameters(vReservationsPerResourceRow, vResources, vNumberOfResourcesToJoin, vDurationInFullHours, vDurationInHalfHours, vTriggerResource, vTriggerResourceIndex);
									// Correct duration in full hous if reservation period start and reservation period end are in different days
									vDayDiff = Round((BegOfDay(vReservationsPerResourceRow.DateTimeTo) - BegOfDay(vReservationsPerResourceRow.DateTimeFrom))/(24*3600), 0);
									If vDayDiff > 0 Then
										vDurationInHalfHours = vDurationInHalfHours + vDayDiff*2;
									EndIf;
									// Join resource reservation period
									If vTriggerResource = vCurResource Then
										vResourceReservationArea = vSpreadsheet.Area(vSpreadsheet.TableHeight - vDurationInHalfHours + 1, vTriggerResourceIndex + 8 - vNumberOfResourcesToJoin + 1, vSpreadsheet.TableHeight, vTriggerResourceIndex + 8);
										vResourceReservationArea.Merge();
									EndIf;
								EndIf;
							EndIf;
							If vResourceReservationArea <> Undefined Then
								vResourceReservationArea.Details = vReservationsPerResourceRow.ResourceReservation;
								vResourceReservationArea.TopBorder = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
								vResourceReservationArea.RightBorder = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
								vResourceReservationArea.BottomBorder = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
								vResourceReservationArea.LeftBorder = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
								vResourceReservationArea.BorderColor = StyleColors.ResourceReservationBorderColor;
								If vReservationsPerResourceRow.IsPreparationTime Or vReservationsPerResourceRow.IsDisassembleTime Then
									vResourceReservationArea.Text = "";
									vResourceReservationArea.BackColor = WebColors.DimGray;
								Else
									vResourceReservationArea.Text = GetResourceReservationDescription(vReservationsPerResourceRow);
									vResourceReservationArea.BackColor = StyleColors.ResourceReservationBackColor;
									If ValueIsFilled(vReservationsPerResourceRow.ResourceReservationStatus) Then
										If vReservationsPerResourceRow.ResourceReservationStatus.IsGuaranteed Then
											vResourceReservationArea.BorderColor = StyleColors.GuaranteedResourceReservationBorderColor;
										EndIf;
										If vReservationsPerResourceRow.ResourceReservationStatus.ServicesAreDelivered Then
											vResourceReservationArea.Pattern = SpreadsheetDocumentPatternType.Pattern3;
										EndIf;
										If vReservationsPerResourceRow.ResourceReservationStatus.Color <> Undefined Then
											vResourceReservationStatusColor = vReservationsPerResourceRow.ResourceReservationStatus.Color.Get();
											If TypeOf(vResourceReservationStatusColor) = Type("Color") Then
												vResourceReservationArea.BackColor = vResourceReservationStatusColor;
											EndIf;
										EndIf;
										If vReservationsPerResourceRow.ClientType.Color <> Undefined Then
											vClientTypeColor = vReservationsPerResourceRow.ClientType.Color.Get();
											If TypeOf(vClientTypeColor) = Type("Color") Then
												vResourceReservationArea.BackColor = vClientTypeColor;
											EndIf;
										EndIf;
									EndIf;
									If ValueIsFilled(vReservationsPerResourceRow.Customer) Then
										If vReservationsPerResourceRow.Customer.Color <> Undefined Then
											vCustomerColor = vReservationsPerResourceRow.Customer.Color.Get();
											If TypeOf(vCustomerColor) = Type("Color") Then
												vResourceReservationArea.BackColor = vCustomerColor;
											EndIf;
										EndIf;
									EndIf;
									If ValueIsFilled(vReservationsPerResourceRow.Contract) Then
										If vReservationsPerResourceRow.Contract.Color <> Undefined Then
											vContractColor = vReservationsPerResourceRow.Contract.Color.Get();
											If TypeOf(vContractColor) = Type("Color") Then
												vResourceReservationArea.BackColor = vContractColor;
											EndIf;
										EndIf;
									EndIf;
									If ValueIsFilled(vReservationsPerResourceRow.GuestGroup) Then
										If vReservationsPerResourceRow.GuestGroup.Color <> Undefined Then
											vGuestGroupColor = vReservationsPerResourceRow.GuestGroup.Color.Get();
											If TypeOf(vGuestGroupColor) = Type("Color") Then
												vResourceReservationArea.BackColor = vGuestGroupColor;
											EndIf;
										EndIf;
									EndIf;
									// Add comment with resource reservation messages
									vMessages = cmGetMessagesForObject(vReservationsPerResourceRow.ResourceReservation);
									If vMessages.Count() > 0 Then
										vMessagesStr = cmGetMessagesPresentationForObject(vMessages, vReservationsPerResourceRow.ResourceReservation);
										vResourceReservationArea.Comment.Text = vMessagesStr;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndDo; // By resources and resource reservations
			// Go to the next hour
			vCurHour = vCurHour + 3600;
			// Add delimeter line at the end of the day
			If vCurHourNumber = 23 Then
				vArea = vTemplate.GetArea("DayDelimeter|Times");
				vSpreadsheet.Put(vArea);
				For i = 1 To vResourcesCount Do
					vArea = vTemplate.GetArea("DayDelimeter|Resource");
					vSpreadsheet.Join(vArea);
				EndDo;
			EndIf;
		EndDo; // By hours
	EndIf;
	// Set resource columns width
	vResourceIndex = 7;
	For i = 1 To vResourcesCount Do
		// Set column width
		vSpreadsheet.Area(, vResourceIndex + i, , vResourceIndex + i).ColumnWidth = ResourceWidth; 
	EndDo;
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait);
	// Set report protection
	cmSetSpreadsheetProtection(Items.ReportSpreadsheet);
	// Fix top 4 rows and 1 left column
	vSpreadsheet.FixedTop = 4;
	vSpreadsheet.FixedLeft = 7;
	// Set report header and footer
	cmApplyReportHeader(vSpreadsheet);
	cmApplyReportFooter(vSpreadsheet);
	// Try to position spreadsheet to the 08:00 in daily scale
	If Not IsOneWeekScale And Not IsOneMonthScale Then
		If vSpreadsheet.SelectedAreas.Count() > 0 Then
			vFirstSelArea = vSpreadsheet.SelectedAreas.Get(0);
			If vFirstSelArea.Top = 1 And vFirstSelArea.Left = 1 Then
				vSpreadsheet.SelectedAreas.Clear();
				vWrkArea = vSpreadsheet.Area(63, 2, 63, 2);
				vSpreadsheet.SelectedAreas.Insert(vWrkArea, 0);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // GenerateReport

// -----------------------------------------------------------------------------
&AtServer
Procedure GenerateMirrorReport()
	Var vIsWorkingHour;
	Var vIsWorkingHalfHour;
	Var vNumberOfResourcesToJoin;
	Var vTriggerResource;
	Var vTriggerResourceIndex;
	Var vDurationInFullHours;
	Var vDurationInHalfHours;
	// Clear spreadsheet
	vSpreadsheet = ReportSpreadsheet;
	vSpreadsheet.Clear();
	// Retrieve resources
	vResources = GetResources();
	// Retrieve resource reservations
	vResourceReservations = GetResourceReservations();
	// Retrieve resources count
	vResourcesCount = vResources.Count();
	// Fill value table with working periods for the all resource calendars
	vWorkingTimes = GetWorkingTimes();
	// Get report template
	vTemplate = Catalogs.Resources.GetTemplate("MirrorResourceCalendar");
	// Filter
	vArea = vTemplate.GetArea("Filter|Header");
	vArea.Parameters.mFilter = NStr("en='Filter: ';ru='Отбор: ';de='Auswahl: '") + GetReportParametersPresentation();
	vSpreadsheet.Put(vArea);
	// Resources header
	vArea = vTemplate.GetArea("Times|Header");
	vArea.Parameters.mPeriodFrom = cmGetDayOfWeekName(WeekDay(SelPeriodFrom)) + " - " + Format(SelPeriodFrom, "DF=dd.MM.yyyy");
	vSpreadsheet.Put(vArea);
	vResourceReservationsList = New ValueTable;
	vResourceReservationsList.Columns.Add("Resource", New TypeDescription("CatalogRef.Resources")); 
	vResourceReservationsList.Columns.Add("Area");
	vResourceReservationsList.Columns.Add("RemoveRightBorder", New TypeDescription("Boolean")); 
	vResourceReservationsList.Columns.Add("CurHour", New TypeDescription("Date"));
	vResourceReservationsList.Columns.Add("TableWidth", New TypeDescription("Number",,, New NumberQualifiers(10, 0)));
	// Choose different drawing styles for month scale and others
	If IsOneMonthScale Then
		// Iterate thru all hours of the period selected
		vCurPeriod = SelPeriodFrom;
		While vCurPeriod < SelPeriodTo Do
			// Hour header
			vArea = vTemplate.GetArea("Times|MonthDay");
			If vCurPeriod = SelPeriodFrom Or vCurPeriod = BegOfMonth(vCurPeriod) Then
				vArea.Parameters.mMonthName = cmGetMonthName(Month(vCurPeriod)) + " " + Format(vCurPeriod, "DF=yyyy");
			Else
				vArea.Parameters.mMonthName = "";
			EndIf;
			vArea.Parameters.mDate = cmGetDayOfWeekName(WeekDay(vCurPeriod)) + " " + Format(vCurPeriod, "DF=dd");
			vArea.Parameters.mCalendarDate = vCurPeriod;
			// Fill weekends color
			If WeekDay(vCurPeriod) > 5 Then
				vArea.Area("WeekDayRange").BackColor = WindowsColors.ButtonHighlight;
			EndIf;
			// Put area
			vSpreadsheet.Join(vArea);
			// Join month name column
			vNumDays = 0;
			If EndOfDay(vCurPeriod) = SelPeriodTo Then
				vNumDays = Round((SelPeriodTo - BegOfMonth(SelPeriodTo))/(24*3600), 0);
			ElsIf EndOfDay(vCurPeriod) = EndOfMonth(vCurPeriod) Then
				vNumDays = Round((EndOfMonth(vCurPeriod) - BegOfDay(SelPeriodFrom))/(24*3600), 0);
			EndIf;
			If vNumDays > 1 Then
				vMonthArea = vSpreadsheet.Area(2, vSpreadsheet.TableWidth - vNumDays + 1, 2, vSpreadsheet.TableWidth);
				vMonthArea.Merge();
			EndIf;
			// Print current day and resource reservations started on it
			vCurResource = Catalogs.Resources.EmptyRef();
			For Each vQryRow In vResources Do
				// Build current date resource reservations description
				If vQryRow.Resource <> vCurResource Then 
					vArea = vTemplate.GetArea("Resource|MonthDay");	
					vNewRow = vResourceReservationsList.Add();
					vNewRow.Resource = vQryRow.Resource;
					vNewRow.TableWidth = vSpreadsheet.TableWidth;
					vCurResource = vQryRow.Resource;
					vResourceDay = "";
					vResourceDayHeight = 0;
					// Check an print resource reservations ending here
					vReservationsPerResource = vResourceReservations.FindRows(New Structure("Resource", vCurResource));
					vReservationsPerResourceParent = vResourceReservations.FindRows(New Structure("Resource", vCurResource.Parent));
					For Each vReservationsPerResourceParentRow In vReservationsPerResourceParent Do
						vReservationsPerResource.Add(vReservationsPerResourceParentRow);
					EndDo;
					For Each vReservationsPerResourceRow In vReservationsPerResource Do
						// Build short resource reservation description
						If ValueIsFilled(vReservationsPerResourceRow.ResourceReservation) Then
							If vReservationsPerResourceRow.DateTimeFrom > vCurPeriod And vReservationsPerResourceRow.DateTimeFrom <= EndOfDay(vCurPeriod) Or 
							   vReservationsPerResourceRow.DateTimeTo > vCurPeriod And vReservationsPerResourceRow.DateTimeTo <= EndOfDay(vCurPeriod) Then
								// Get number of columns to join and resource to trigger joining
								GetResourceReservationAreaJoinParameters(vReservationsPerResourceRow, vResources, vNumberOfResourcesToJoin, vDurationInFullHours, vDurationInHalfHours, vTriggerResource, vTriggerResourceIndex);
								// Fill resource reservation description
								If vTriggerResource = vCurResource Then
									vResourceDay = vResourceDay + GetResourceReservationDescription(vReservationsPerResourceRow) + Chars.LF;
									vResourceDayHeight = vResourceDayHeight + 1;
								EndIf;
							EndIf;
						EndIf;
					EndDo;
					vResourceDay = TrimAll(vResourceDay);
					If vResourceDayHeight < 2 Then
						If vResourceDayHeight = 0 Then
							vResourceDay = vResourceDay + Chars.LF + Chars.LF;
						ElsIf vResourceDayHeight = 1 Then
							vResourceDay = vResourceDay + Chars.LF;
						EndIf;
					EndIf;
					// Join resource date
					vArea.Parameters.mResourceDay = vResourceDay;
					vNewRow.Area = vArea;
				EndIf;
			EndDo; // By resources and resource reservations
			// Go to the next day
			vCurPeriod = vCurPeriod + 24*3600;
		EndDo; // By days
	Else
		vUse24Hours = False;
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
				If SessionParameters.CurrentUser.EmployeePreferences.Use24ForMidnightInResourcesCalendar Then
					vUse24Hours = True;
				EndIf;
			EndIf;
		EndIf;
		// Iterate thru all hours of the period selected
		vCurHour = SelPeriodFrom;
		While vCurHour < SelPeriodTo Do
			vCurPeriod = BegOfDay(vCurHour);
			vCurHourNumber = Int((vCurHour - BegOfDay(vCurHour))/3600);
			vRemoveRightBorder = False;
			// Hour header 
			If IsOneWeekScale Then
				vArea = vTemplate.GetArea("Times|WeekHour");
				If Int(vCurHourNumber/3) = vCurHourNumber/3 Then
					If vUse24Hours Then
						vArea.Parameters.mHour = Format((vCurHourNumber + 3), "ND=2; NFD=0; NZ=; NLZ=");
					Else
						vArea.Parameters.mHour = Format(vCurHourNumber, "ND=2; NFD=0; NZ=; NLZ=");
					EndIf;
					vArea.Parameters.mMinutes = "00";
				Else
					vArea.Parameters.mHour = "";
					vArea.Parameters.mMinutes = "";
				EndIf;
			Else
				vArea = vTemplate.GetArea("Times|DayHour");
				vArea.Parameters.mHour = Format(vCurHourNumber, "ND=2; NFD=0; NZ=; NLZ=");
				vArea.Parameters.mMinutes = "00";
				vArea.Parameters.mMinutes30 = "30";
			EndIf;
			If vCurHour = vCurPeriod Then
				vArea.Parameters.mDate = cmGetDayOfWeekName(WeekDay(vCurPeriod)) + " - " + Format(vCurPeriod, "L=" + TrimAll(SessionParameters.CurrentLanguage.LocalizationCode) + "; DLF=DD");
				vArea.Parameters.mCalendarDate = vCurPeriod;
			Else
				vArea.Parameters.mDate = "";
				vArea.Parameters.mCalendarDate = vCurPeriod;
			EndIf;
			If WeekDay(vCurHour) > 5 Then
				If IsOneWeekScale Then
					vArea.Area("WeekHourRange").BackColor = WindowsColors.ButtonHighlight;
				Else
					vArea.Area("DayHourRange").BackColor = WindowsColors.ButtonHighlight;
				EndIf;
			EndIf;
			vSpreadsheet.Join(vArea);
			// Join hours
			If IsOneWeekScale Then 
				If Int((vCurHourNumber + 1)/3) = (vCurHourNumber + 1)/3 Then
					vSpreadsheet.Area(3, vSpreadsheet.TableWidth - 2, 3, vSpreadsheet.TableWidth).Merge();
					vSpreadsheet.Area(4, vSpreadsheet.TableWidth - 2, 4, vSpreadsheet.TableWidth).Merge(); 
				Else	
					vRemoveRightBorder = True;
				EndIf;
			EndIf;
			// Join day column
			If vCurHourNumber = 23 Then
				If IsOneWeekScale Then
					vDayArea = vSpreadsheet.Area(2, vSpreadsheet.TableWidth - 23, 2, vSpreadsheet.TableWidth);
					vDayArea.Merge();
				Else
					vDayArea = vSpreadsheet.Area(2, vSpreadsheet.TableWidth - 47, 2, vSpreadsheet.TableWidth);
					vDayArea.Merge();
				EndIf;
				If WeekDay(vCurHour) > 5 Then
					vDayArea.BackColor = WindowsColors.ButtonHighlight;
				EndIf;
			EndIf;      
			// Print current hour and resource reservations started on it
			vCurResource = Catalogs.Resources.EmptyRef();
			For Each vQryRow In vResources Do
				// Print resource hour
				If vQryRow.Resource <> vCurResource Then
					vCurResource = vQryRow.Resource;
					// Check if current hour is working one
					If Not vCurResource.RoundTheClockOperation Then
						CheckIfHourIsWorking(vWorkingTimes, vCurResource.Calendar, vCurPeriod, vCurHour, vIsWorkingHour, vIsWorkingHalfHour);
					Else
						vIsWorkingHour = True;
						vIsWorkingHalfHour = True;
					EndIf;
					// Get resource hour template area
					If IsOneWeekScale Then
						vArea = vTemplate.GetArea("Resource|WeekHour");
						// Change area color if this hour is not working
						If Not vIsWorkingHour Or Not vIsWorkingHalfHour Then
							vArea.Area("ResourceHour").BackColor = WebColors.LightGoldenRodYellow;
						EndIf;
					Else
						vArea = vTemplate.GetArea("Resource|DayHour");
						// Change area color if this hour is not working
						If Not vIsWorkingHour Then
							vArea.Area("ResourceHour00").BackColor = WebColors.LightGoldenRodYellow;
						EndIf;
						If Not vIsWorkingHalfHour Then
							vArea.Area("ResourceHour30").BackColor = WebColors.LightGoldenRodYellow;
						EndIf;
					EndIf;    
					vNewRow = vResourceReservationsList.Add();
					vNewRow.Resource = vQryRow.Resource;
                    vNewRow.Area = vArea;
					vNewRow.RemoveRightBorder = vRemoveRightBorder; 
					vNewRow.CurHour = vCurHour;
					vNewRow.TableWidth = vSpreadsheet.TableWidth;
				EndIf; 
			EndDo; // By resources and resource reservations 		
			// Go to the next hour
			vCurHour = vCurHour + 3600;
			// Add delimeter line at the end of the day
			If vCurHourNumber = 23 And vCurHour < SelPeriodTo Then
				vArea = vTemplate.GetArea("Times|DayDelimeter");
				vSpreadsheet.Join(vArea);
				For Each vQryRow In vResources Do
					vNewRow = vResourceReservationsList.Add();
					vNewRow.Resource = vQryRow.Resource;
                    vNewRow.Area = vTemplate.GetArea("Resource|DayDelimeter");;
					vNewRow.TableWidth = vSpreadsheet.TableWidth;
				EndDo;
			EndIf;
		EndDo; // By hours
	EndIf; 
	// Print report header with resource names
	vCurResourceParent = Catalogs.Resources.EmptyRef();
	vCurResource = Catalogs.Resources.EmptyRef();
	For Each vQryRow In vResources Do
		// Print period header if necessary
		If vQryRow.Resource <> vCurResource Then
			vCurResource = vQryRow.Resource;
			vArea = vTemplate.GetArea("Resource|Header");
			If ValueIsFilled(vQryRow.ResourceParent) Then
				If vQryRow.ResourceParent <> vCurResourceParent Then
					vCurResourceParent = vQryRow.ResourceParent;
					// Fill resource parent name
					vArea.Parameters.mResourceParent = TrimAll(vQryRow.ResourceParent.Description);
					AddResourceMaximumNumberOfPersonsAndPrice(vArea.Parameters.mResourceParent, vQryRow.ResourceParent);
					vArea.Parameters.mResourceParentDetail = vQryRow.ResourceParent;
					// Remove right border line
					vResourceParentArea = vArea.Area("ResourceParent");
					vResourceParentArea.RightBorder = New Line(SpreadsheetDocumentDrawingLineType.None);
					// Add comments with resource messages
					vMessages = cmGetMessagesForObject(vQryRow.ResourceParent);
					If vMessages.Count() > 0 Then
						vMessagesStr = cmGetMessagesPresentationForObject(vMessages, vQryRow.ResourceParent);
						vArea.Area("ResourceParent").Comment.Text = vMessagesStr;
					EndIf;
					// Fill resource item name
					vArea.Parameters.mResource = TrimAll(vQryRow.Resource.Description);
					AddResourceMaximumNumberOfPersonsAndPrice(vArea.Parameters.mResource, vQryRow.Resource);
					vArea.Parameters.mResourceDetail = vQryRow.Resource;
					// Add comments with resource messages
					vMessages = cmGetMessagesForObject(vQryRow.Resource);
					If vMessages.Count() > 0 Then
						vMessagesStr = cmGetMessagesPresentationForObject(vMessages, vQryRow.Resource);
						vArea.Area("ResourceItem").Comment.Text = vMessagesStr;
					EndIf;
				Else
					// Get last resource for the given parent
					vLastResource = Undefined;
					vParentResourceChildren = vResources.FindRows(New Structure("ResourceParent", vQryRow.ResourceParent));
					If vParentResourceChildren.Count() > 0 Then
						vLastResource = vParentResourceChildren.Get(vParentResourceChildren.Count()-1).Resource;
					EndIf;
					// Remove border lines
					vResourceParentArea = vArea.Area("ResourceParent");
					vResourceParentArea.LeftBorder = New Line(SpreadsheetDocumentDrawingLineType.None);
					If vQryRow.Resource <> vLastResource Then
						vResourceParentArea.RightBorder = New Line(SpreadsheetDocumentDrawingLineType.None);
					EndIf;
					// Fill resource item name
					vArea.Parameters.mResource = TrimAll(vQryRow.Resource.Description);
					AddResourceMaximumNumberOfPersonsAndPrice(vArea.Parameters.mResource, vQryRow.Resource);
					vArea.Parameters.mResourceDetail = vQryRow.Resource;
					vArea.Parameters.mResourceParentDetail = vQryRow.ResourceParent;
					// Add comments with resource messages
					vMessages = cmGetMessagesForObject(vQryRow.Resource);
					If vMessages.Count() > 0 Then
						vMessagesStr = cmGetMessagesPresentationForObject(vMessages, vQryRow.Resource);
						vArea.Area("ResourceItem").Comment.Text = vMessagesStr;
					EndIf;
					// Clear resource parent area text to force group by selected columns flag to work
					vResourceParentArea.Clear();
				EndIf;
			Else
				// Join parent and item areas
				vResourceMergedArea = vArea.Area("ResourceMerged");
				vResourceMergedArea.Merge();
				// Fill resource item name
				vArea.Parameters.mResourceParent = TrimAll(vQryRow.Resource.Description);
				AddResourceMaximumNumberOfPersonsAndPrice(vArea.Parameters.mResourceParent, vQryRow.Resource);
				vArea.Parameters.mResourceParentDetail = vQryRow.Resource;
				// Add comments with resource messages
				vMessages = cmGetMessagesForObject(vQryRow.Resource);
				If vMessages.Count() > 0 Then
					vMessagesStr = cmGetMessagesPresentationForObject(vMessages, vQryRow.Resource);
					vArea.Area("ResourceMerged").Comment.Text = vMessagesStr;
				EndIf;
			EndIf;
			vSpreadsheet.Put(vArea);
			vResourceReservationsArr = vResourceReservationsList.FindRows(New Structure("Resource", vCurResource));
			For Each vRow In vResourceReservationsArr Do
				vOutputArea = vSpreadsheet.Join(vRow.Area);
				If Not IsOneMonthScale Then
					If vRow.RemoveRightBorder Then
						vOutputArea.RightBorder = New Line(SpreadsheetDocumentCellLineType.None);
					EndIf;
					// Check an print resource reservations ending here
					vReservationsPerResource = vResourceReservations.FindRows(New Structure("Resource", vCurResource));
					vReservationsPerResourceParent = vResourceReservations.FindRows(New Structure("Resource", vCurResource.Parent));
					For Each vReservationsPerResourceParentRow In vReservationsPerResourceParent Do
						vReservationsPerResource.Add(vReservationsPerResourceParentRow);
					EndDo;
					For Each vReservationsPerResourceRow In vReservationsPerResource Do
						// Print resource reservation
						If ValueIsFilled(vReservationsPerResourceRow.ResourceReservation) Then
							vResourceReservationArea = Undefined;
							If IsOneWeekScale Then
								If vReservationsPerResourceRow.DateTimeTo > vRow.CurHour And vReservationsPerResourceRow.DateTimeTo <= (vRow.CurHour + 3600) Then
									// Get number of columns to join and resource to trigger joining
									GetResourceReservationAreaJoinParameters(vReservationsPerResourceRow, vResources, vNumberOfResourcesToJoin, vDurationInFullHours, vDurationInHalfHours, vTriggerResource, vTriggerResourceIndex);
									// Correct duration in full hous if reservation period start and reservation period end are in different days
									vDayDiff = Round((BegOfDay(vReservationsPerResourceRow.DateTimeTo) - BegOfDay(vReservationsPerResourceRow.DateTimeFrom))/(24*3600), 0);
									If vDayDiff > 0 Then
										vDurationInFullHours = vDurationInFullHours + vDayDiff*2;
									EndIf;
									// Join resource reservation period
									If vTriggerResource = vCurResource Then
										vResourceReservationArea = vSpreadsheet.Area(vTriggerResourceIndex + 5 - vNumberOfResourcesToJoin + 1, vRow.TableWidth - vDurationInFullHours + 1, vTriggerResourceIndex + 5, vRow.TableWidth);
										vResourceReservationArea.Merge();
									EndIf;
								EndIf;
							Else
								If vReservationsPerResourceRow.DateTimeTo > vRow.CurHour And vReservationsPerResourceRow.DateTimeTo <= (vRow.CurHour + 1800) Then
									// Get number of columns to join and resource to trigger joining
									GetResourceReservationAreaJoinParameters(vReservationsPerResourceRow, vResources, vNumberOfResourcesToJoin, vDurationInFullHours, vDurationInHalfHours, vTriggerResource, vTriggerResourceIndex);
									// Correct duration in full hous if reservation period start and reservation period end are in different days
									vDayDiff = Round((BegOfDay(vReservationsPerResourceRow.DateTimeTo) - BegOfDay(vReservationsPerResourceRow.DateTimeFrom))/(24*3600), 0);
									If vDayDiff > 0 Then
										vDurationInHalfHours = vDurationInHalfHours + vDayDiff*2;
									EndIf;
									// Join resource reservation period
									If vTriggerResource = vCurResource Then
										vResourceReservationArea = vSpreadsheet.Area(vTriggerResourceIndex + 5 - vNumberOfResourcesToJoin + 1, vRow.TableWidth - vDurationInHalfHours, vTriggerResourceIndex + 5, vRow.TableWidth - 1);
										vResourceReservationArea.Merge();
									EndIf;
								ElsIf vReservationsPerResourceRow.DateTimeTo > (vRow.CurHour + 1800) And vReservationsPerResourceRow.DateTimeTo <= (vRow.CurHour + 3600) Then
									// Get number of columns to join and resource to trigger joining
									GetResourceReservationAreaJoinParameters(vReservationsPerResourceRow, vResources, vNumberOfResourcesToJoin, vDurationInFullHours, vDurationInHalfHours, vTriggerResource, vTriggerResourceIndex);
									// Correct duration in full hous if reservation period start and reservation period end are in different days
									vDayDiff = Round((BegOfDay(vReservationsPerResourceRow.DateTimeTo) - BegOfDay(vReservationsPerResourceRow.DateTimeFrom))/(24*3600), 0);
									If vDayDiff > 0 Then
										vDurationInHalfHours = vDurationInHalfHours + vDayDiff*2;
									EndIf;
									// Join resource reservation period
									If vTriggerResource = vCurResource Then
										vResourceReservationArea = vSpreadsheet.Area(vTriggerResourceIndex + 5 - vNumberOfResourcesToJoin + 1, vRow.TableWidth - vDurationInHalfHours + 1, vTriggerResourceIndex + 5, vRow.TableWidth);
										vResourceReservationArea.Merge();
									EndIf;
								EndIf;
							EndIf;
							If vResourceReservationArea <> Undefined Then
								vResourceReservationArea.Details = vReservationsPerResourceRow.ResourceReservation;
								vResourceReservationArea.TopBorder = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
								vResourceReservationArea.RightBorder = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
								vResourceReservationArea.BottomBorder = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
								vResourceReservationArea.LeftBorder = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
								vResourceReservationArea.BorderColor = StyleColors.ResourceReservationBorderColor;
								If vReservationsPerResourceRow.IsPreparationTime Or vReservationsPerResourceRow.IsDisassembleTime Then
									vResourceReservationArea.Text = "";
									vResourceReservationArea.BackColor = WebColors.DimGray;
								Else
									vResourceReservationArea.Text = GetResourceReservationDescription(vReservationsPerResourceRow);
									vResourceReservationArea.BackColor = StyleColors.ResourceReservationBackColor;
									If ValueIsFilled(vReservationsPerResourceRow.ResourceReservationStatus) Then
										If vReservationsPerResourceRow.ResourceReservationStatus.IsGuaranteed Then
											vResourceReservationArea.BorderColor = StyleColors.GuaranteedResourceReservationBorderColor;
										EndIf;
										If vReservationsPerResourceRow.ResourceReservationStatus.ServicesAreDelivered Then
											vResourceReservationArea.Pattern = SpreadsheetDocumentPatternType.Pattern3;
										EndIf;
										If vReservationsPerResourceRow.ResourceReservationStatus.Color <> Undefined Then
											vResourceReservationStatusColor = vReservationsPerResourceRow.ResourceReservationStatus.Color.Get();
											If TypeOf(vResourceReservationStatusColor) = Type("Color") Then
												vResourceReservationArea.BackColor = vResourceReservationStatusColor;
											EndIf;
										EndIf;
										If vReservationsPerResourceRow.ClientType.Color <> Undefined Then
											vClientTypeColor = vReservationsPerResourceRow.ClientType.Color.Get();
											If TypeOf(vClientTypeColor) = Type("Color") Then
												vResourceReservationArea.BackColor = vClientTypeColor;
											EndIf;
										EndIf;
									EndIf;
									If ValueIsFilled(vReservationsPerResourceRow.Customer) Then
										If vReservationsPerResourceRow.Customer.Color <> Undefined Then
											vCustomerColor = vReservationsPerResourceRow.Customer.Color.Get();
											If TypeOf(vCustomerColor) = Type("Color") Then
												vResourceReservationArea.BackColor = vCustomerColor;
											EndIf;
										EndIf;
									EndIf;
									If ValueIsFilled(vReservationsPerResourceRow.Contract) Then
										If vReservationsPerResourceRow.Contract.Color <> Undefined Then
											vContractColor = vReservationsPerResourceRow.Contract.Color.Get();
											If TypeOf(vContractColor) = Type("Color") Then
												vResourceReservationArea.BackColor = vContractColor;
											EndIf;
										EndIf;
									EndIf;
									If ValueIsFilled(vReservationsPerResourceRow.GuestGroup) Then
										If vReservationsPerResourceRow.GuestGroup.Color <> Undefined Then
											vGuestGroupColor = vReservationsPerResourceRow.GuestGroup.Color.Get();
											If TypeOf(vGuestGroupColor) = Type("Color") Then
												vResourceReservationArea.BackColor = vGuestGroupColor;
											EndIf;
										EndIf;
									EndIf;
									// Add comment with resource reservation messages
									vMessages = cmGetMessagesForObject(vReservationsPerResourceRow.ResourceReservation);
									If vMessages.Count() > 0 Then
										vMessagesStr = cmGetMessagesPresentationForObject(vMessages, vReservationsPerResourceRow.ResourceReservation);
										vResourceReservationArea.Comment.Text = vMessagesStr;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndDo;	
				EndIf;
			EndDo;
		EndIf;
	EndDo;  
	// Set resource columns width
	vResourceIndex = 4;
	For i = 1 To vResourcesCount Do
		// Set column width
		vSpreadsheet.Area(vResourceIndex + i, , vResourceIndex + i, ).RowHeight = ResourceHeight; 
	EndDo;
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait);
	// Set report protection
	cmSetSpreadsheetProtection(Items.ReportSpreadsheet);
	// Fix top 4 rows and 1 left column
	vSpreadsheet.FixedTop = 4;
	vSpreadsheet.FixedLeft = 4;
	// Set report header and footer
	cmApplyReportHeader(vSpreadsheet);
	cmApplyReportFooter(vSpreadsheet);
	// Try to position spreadsheet to the 08:00 in daily scale
	If Not IsOneWeekScale And Not IsOneMonthScale Then
		If vSpreadsheet.SelectedAreas.Count() > 0 Then
			vFirstSelArea = vSpreadsheet.SelectedAreas.Get(0);
			If vFirstSelArea.Top = 1 And vFirstSelArea.Left = 1 Then
				vSpreadsheet.SelectedAreas.Clear();
				vWrkArea = vSpreadsheet.Area(63, 2, 63, 2);
				vSpreadsheet.SelectedAreas.Insert(vWrkArea, 0);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // GenerateMirrorReport

// -----------------------------------------------------------------------------
&AtServer
Function GetReportParametersPresentation()
	vParamPresentation = "";
	If ValueIsFilled(SelResourceType) Then
		If Not SelResourceType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Resource type ';ru='Тип ресурса ';de='Ressourcentyp '") + 
			                     TrimAll(SelResourceType.Description) + 
			                     "; ";
		Else
			vParamPresentation = vParamPresentation + NStr("en='Resource types folder ';ru='Группа типов ресурсов ';de='Gruppe Ressourcentypen '") + 
			                     TrimAll(SelResourceType.Description) + 
			                     "; ";
		EndIf;
	EndIf;
	If ValueIsFilled(SelResource) Then
		If Not SelResource.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Resource ';ru='Ресурс ';de='Ressource '") + 
			                     TrimAll(SelResource.Description) + 
			                     "; ";
		Else
			vParamPresentation = vParamPresentation + NStr("en='Resources folder ';ru='Группа ресурсов ';de='Gruppe Ressourcen '") + 
			                     TrimAll(SelResource.Description) + 
			                     "; ";
		EndIf;
	EndIf;
	If ValueIsFilled(SelHotel) Then
		If Not SelHotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     TrimAll(SelHotel.Description) + 
			                     "; ";
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Gruppe Hotels '") + 
			                     TrimAll(SelHotel.Description) + 
			                     "; ";
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // GetReportParametersPresentation

#EndRegion
