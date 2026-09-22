
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	vMetadata = FormAttributeToValue("Object").Metadata();
	ObjectFullName = vMetadata.FullName();

	Date     = CurrentDate();
	Hotel    = SessionParameters.CurrentHotel;
	SetDateTitle(Date);
	FillDateSwitch();
	
	Items.GroupParametersPrices.Visible = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	FillTree();	
EndProcedure

// ----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "System.Calendar.Changed" And Source = "CalendarChangeWizard" Then
		BackgroundJobUUID = Parameter.BackgroundJobUUID;
		AttachIdleHandler("CheckBackgroundJobs", 2, False);
	EndIf;
EndProcedure

// ----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If pChoiceSource.FormName = "Catalog.RoomRates.Form.tcChoiceForm" Then
		RoomRate = pSelectedValue;
		FillTreeAtServer();
		ExpandAllRowsInCalendarDaysTypes();
	EndIf;	
EndProcedure


#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ItemsOnChange(Item)
	FillTree();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(Item)
	vItemsTree = CalendarDaysTypes.GetItems();
	vItemsTree.Clear();

	FillTree();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(Item)
	ClearMessages();
	SetDateTitle(Date);
	DateSwitch = 100;
	
	FillTree();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateSwitchOnChange(Item)
	DateSwitchOnChangeAtServer();
	FillTree();
EndProcedure

// ----------------------------------------------------------------------------
&AtClient
Procedure ShowPricesOnChange(Item)
	Items.GroupParametersPrices.Visible = ShowPrices;
	If ShowPrices And Not ValueIsFilled(AccommodationTemplate) Then  
		vND = New NotifyDescription("ShowPricesAfterChooseTemplate", ThisObject);
		vFilter = New Structure("Hotel", Hotel);
		vParams = New Structure("Filter", vFilter);
		OpenForm("Catalog.AccommodationTemplates.ChoiceForm", vParams, ThisObject, UUID, , , vND, FormWindowOpeningMode.LockOwnerWindow);	
	Else	
		FillTree();     
	EndIf;
EndProcedure

#EndRegion

#Region FormTableCalendarDaysTypesItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CalendarDaysTypesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If Not pField = Undefined And StrFind(pField.Name, "PriceTableDay") > 0 Then
		vCurRow = CalendarDaysTypes.FindByID(pSelectedRow);
		If vCurRow <> Undefined And 
		  (TypeOf(vCurRow.RoomTypes) <> Type("String") Or 
		   vCurRow.GetParent() <> Undefined And TypeOf(vCurRow.GetParent().RoomTypes) <> Type("String") Or 
		   vCurRow.GetParent() <> Undefined And vCurRow.GetParent().GetParent() <> Undefined And TypeOf(vCurRow.GetParent().GetParent().RoomTypes) <> Type("String")) Then
			vId = StrReplace(pField.Name,"PriceTableDay", "");
			vSelectedDay = BegOfDay(Date+(Number(vId)-1)*24*60*60);
			vCurValue = vCurRow["Day"+vId];
			vBasis = vCurRow.RoomTypes;
			If Not (TypeOf(vCurRow.RoomTypes) = Type("CatalogRef.RoomTypes") Or TypeOf(vCurRow.RoomTypes) = Type("CatalogRef.Hotels")) Then
				vBasis = vCurRow.GetParent().RoomTypes;
			ElsIf vCurRow.GetParent() <> Undefined Then
				If Not (TypeOf(vCurRow.GetParent().RoomTypes) = Type("CatalogRef.RoomTypes") Or TypeOf(vCurRow.GetParent().RoomTypes) = Type("CatalogRef.Hotels")) Then
					vBasis = vCurRow.GetParent().GetParent().RoomTypes;
				EndIf;
			EndIf; 

			vParams = New Structure;
			vParams.Insert("DateFrom", vSelectedDay);
			vParams.Insert("DateTo", vSelectedDay);
			vParams.Insert("RoomRate", RoomRate);
			vParams.Insert("Basis", vBasis); 
			vParams.Insert("FieldName", vCurRow.FieldName);
			vParams.Insert("Hotel", Hotel);

			OpenForm(ObjectFullName + ".Form.FormFillCalendar", vParams, ThisObject, ThisForm.UUID);
		EndIf;
	EndIf; 
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure NextDate(Command)
	NextDateAtServer();
	DateSwitch = 100;
	FillTree();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PreviousDate(Command)
	PreviousDateAtServer();
	DateSwitch = 100;	
	FillTree();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Refresh(Command)
	FillTree();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure ExpandAllRowsInCalendarDaysTypes()
	vRows = CalendarDaysTypes.GetItems();
	For Each vRow In vRows Do		
		Items.CalendarDaysTypes.Expand(vRow.GetID());
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillTree()
	ClearMessages();
	
	// Fill period to be shown
	PeriodFrom = BegOfDay(Date);
	PeriodTo = EndOfDay(Date + 30*24*60*60);
	
	If ShowPrices And Not ValueIsFilled(AccommodationTemplate) Then
		Message = New UserMessage;
		Message.Text = Nstr("en = 'You must specify the placement pattern'; de = 'Sie müssen das Platzierungsmuster angeben'; ru = 'Необходимо указать шаблон размещения'");
		Message.Field = "AccommodationTemplate";
		Message.Message();
		Return;	
	EndIf; 
	If Not ValueIsFilled(RoomRate) Then
		 OpenForm("Catalog.RoomRates.ChoiceForm",,ThisForm, ThisForm.UUID);
		 Return;
	EndIf;	
	
	// Main processing
	FillTreeAtServer();
	
	ExpandAllRowsInCalendarDaysTypes();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowPricesAfterChooseTemplate(pTemplate, pParams) Export 
	If ValueIsFilled(pTemplate) Then
		AccommodationTemplate = pTemplate;
	EndIf;	
    FillTree();
EndProcedure // ShowPricesAfterChooseTemplate()  

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDateTitle(pStartDate)
	CurrDate = pStartDate;
	For i = 1 To 31 Do	
		vItem = Items["PriceTableDay" + i];
		
		If WeekDay(CurrDate) = 6 Or WeekDay(CurrDate) = 7 Then
			vItem.BackColor = New Color(255, 239, 213);
		ElsIf WeekDay(CurrDate) = 2 Or WeekDay(CurrDate) = 4 Then
			vItem.BackColor = New Color(250, 250, 250);
		Else
			vItem.BackColor = New Color(255, 255, 255);
		EndIf; 
		
		vItem.Title = Format(CurrDate,"DF=dd.MM.yy") + Chars.LF + Format(CurrDate, NStr("en = 'L=en; DF=ddd'; ru = 'L=ru; DF=ddd'; de = 'L=de; DF=ddd'"));
		CurrDate = CurrDate + 24*3600;
	EndDo;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDateSwitch()
	Items.DateSwitch.ChoiceList.Clear();	
	vCurDate = CurrentSessionDate();
	Items.DateSwitch.ChoiceList.Add(0,NStr("en = 'Today'; ru = 'Сегодня'; de = 'Heute'"));
	vCurDate = BegOfMonth(vCurDate);
	x = 1;
	While x <= 12 Do
		If Month(vCurDate) = 1 Then
			Items.DateSwitch.ChoiceList.Add(x, Format(vCurDate, NStr("en = 'L=en_EN; DF=''MMMM yyyy'''; de = 'L=de_DE; DF=''MMMM yyyy'''; ru = 'L=ru_RU; DF=''MMMM yyyy'''")));
		Else
			Items.DateSwitch.ChoiceList.Add(x, Format(vCurDate, NStr("en = 'L=en_EN; DF=MMMM'; ru = 'L=ru_RU; DF=MMMM'; de = 'L=de_DE; DF=MMMM'")));
		EndIf;
		vCurDate = BegOfMonth(AddMonth(vCurDate, 1));
		x = x + 1;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure NextDateAtServer()
	Date = Date + 7 * 24 * 3600;
	SetDateTitle(Date);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure PreviousDateAtServer()
	Date = Date - 7 * 24 * 3600;
	SetDateTitle(Date);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DateSwitchOnChangeAtServer()
	If DateSwitch = 0 Then
		Date = CurrentDate();
	Else
		vDate = BegOfMonth(CurrentDate());
		x = 1;
		While x <= DateSwitch Do
			Date = BegOfMonth(vDate);
			vDate = BegOfMonth(AddMonth(vDate, 1)); 
			x = x + 1;
		EndDo;
	EndIf;
	SetDateTitle(Date);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTreeAtServer()
	// Check attributes
	If Not CheckFilling() Then
		Return
	EndIf; 
	
	// Clear tree
	vItemsTree = CalendarDaysTypes.GetItems();
	vItemsTree.Clear();
	
	ConditionalAppearance.Items.Clear();
	
	// Fill occupation percent
	FillOccupationPercent(vItemsTree);

	// Fill calendar
	If ShowPrices Then
		// By prices
		FillPrices(vItemsTree);
	Else
		// By day types
		FillCalendarDayTypes(vItemsTree);
	EndIf; 
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillOccupationPercent(Val vItemsTree)
	vOccupationPercentList = GetOccupationPercent(Hotel, PeriodFrom, PeriodTo);

	// Add row occupation percent
	vRowAvailableRooms = vItemsTree.Add();
	vRowAvailableRooms.RoomTypes = NStr("en = 'Available rooms'; de = 'Verfügbare Zimmer'; ru = 'Доступно номеров'");
	
	vRowRentedRooms = vItemsTree.Add();
	vRowRentedRooms.RoomTypes = NStr("en = 'Rented rooms'; de = 'Vermietete Zimmer'; ru = 'Продано номеров'");

	vRowOccupation = vItemsTree.Add();
	vRowOccupation.RoomTypes = NStr("en = 'Rooms rented %'; de = 'Vermietete Zimmer %'; ru = '% Продаж'");

	vCurDate = PeriodFrom;
	While vCurDate <= BegOfDay(PeriodTo) Do
		vPercent = "0%";
		vRoomsAvailable = 0;
		vRentedRooms = 0;
		
		vFilter = vOccupationPercentList.FindRows(New Structure("Period", vCurDate));
		If vFilter.Count() > 0 Then
			vRow = vFilter[0];
			vRoomsAvailable = vRow.TotalRooms + vRow.RoomsBlocked;
			vRentedRooms = vRow.RoomsRented;
			vPercent = Format(Round(?(vRoomsAvailable = 0, 0, 100 * vRentedRooms/vRoomsAvailable), 1), "NFD=1; NZ=0; NG=")+ "%";
		EndIf;	
		
		vId = Int((BegOfDay(vRow.Period) - PeriodFrom)/86400)+1; 
		vDay = "Day" + String(vId);
		
		vRowAvailableRooms[vDay] = Format(vRoomsAvailable, "NFD=0; NZ=0; NG=");
		vRowRentedRooms[vDay] = Format(vRentedRooms, "NFD=0; NZ=0; NG=");
		vRowOccupation[vDay] = vPercent;

		vCurDate = vCurDate + 86400;
	EndDo;
EndProcedure // FillOccupationPercent

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrices(pItemsTree)
	// Get prices
	vAccTemplates = New ValueList;
	vAccTemplates.Add(AccommodationTemplate);
	
	vPricesTab = cmGetCachedPricesByDays(Hotel, ClientType, PeriodFrom, PeriodTo, PriceTag, RoomRate, vAccTemplates);
	vPricesTab.GroupBy("Period,RoomType,Currency","Amount");
	
	// Fill tree by prices
	vFirstRow = FillTreePricesRows(pItemsTree, vPricesTab);

	// Get restrictions
	vTabRes = GetRestrictions();
	
	// Fill room rate restrictions
	FillRestrictions(vFirstRow, vTabRes);
EndProcedure //  FillPrices

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCalendarDayTypes(pItemsTree)
	// Get calendar days types
	vRes = GetCalendarDaysTypes();
	
	vTab = vRes.Select();

	// Fill tree
	vFirstRow = FillTreeRoomTypesRows(pItemsTree, vTab);
	
	// Fill conditional appearance for empty calendar days types
	AddConditionalAppearanceForEmptyDays(vFirstRow);
	
	// Get restrictions
	vTabRes = GetRestrictions();
	
	// Fill room rate restrictions
	FillRestrictions(vFirstRow, vTabRes);
EndProcedure //  FillCalendarDayTypes

// -----------------------------------------------------------------------------
&AtServer
Function GetRestrictions()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	RoomRateRestrictions.RoomRate AS RoomRate,
	|	CASE
	|		WHEN RoomRateRestrictions.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|			THEN RoomRateRestrictions.Hotel
	|		ELSE RoomRateRestrictions.RoomType
	|	END AS RoomType,
	|	RoomRateRestrictions.AccountingDate AS AccountingDate,
	|	RoomRateRestrictions.StopSale AS StopSale,
	|	RoomRateRestrictions.MLOS AS MLOS,
	|	RoomRateRestrictions.MaxLOS AS MaxLOS,
	|	RoomRateRestrictions.CTA AS CTA,
	|	RoomRateRestrictions.CTD AS CTD,
	|	RoomRateRestrictions.MinDaysBeforeCheckIn AS MinDaysBeforeCheckIn,
	|	RoomRateRestrictions.MaxDaysBeforeCheckIn AS MaxDaysBeforeCheckIn,
	|	RoomRateRestrictions.IsForOnlineOnly AS IsForOnlineOnly
	|INTO Restrictions
	|FROM
	|	InformationRegister.RoomRateRestrictions AS RoomRateRestrictions
	|WHERE
	|	RoomRateRestrictions.Hotel = &qHotel
	|	AND (RoomRateRestrictions.RoomRate = &qRoomRate
	|			OR RoomRateRestrictions.RoomRate = VALUE(Catalog.RoomRates.EmptyRef))
	|	AND RoomRateRestrictions.AccountingDate BETWEEN &qDateFrom AND &qDateTo
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&qRoomRate AS RoomRate,
	|	&qHotel AS RoomType,
	|	ManualPriceTagsForHotel.AccountingDate AS AccountingDate,
	|	ManualPriceTagsForHotel.PriceTag AS PriceTag
	|INTO ManualPriceTagsForHotel
	|FROM
	|	InformationRegister.CalendarDays.SliceLast(
	|			&qPriceCalculationDate,
	|			AccountingDate BETWEEN &qDateFrom AND &qDateTo
	|				AND Calendar = &qCalendar) AS ManualPriceTagsForHotel
	|WHERE
	|	ManualPriceTagsForHotel.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&qRoomRate AS RoomRate,
	|	ManualPriceTagsForRoomTypes.RoomType AS RoomType,
	|	ManualPriceTagsForRoomTypes.AccountingDate AS AccountingDate,
	|	ManualPriceTagsForRoomTypes.PriceTag AS PriceTag
	|INTO ManualPriceTagsForRoomTypes
	|FROM
	|	InformationRegister.CalendarDaysByRoomTypes.SliceLast(
	|			&qPriceCalculationDate,
	|			AccountingDate BETWEEN &qDateFrom AND &qDateTo
	|				AND Calendar = &qCalendar
	|				AND Hotel = &qHotel) AS ManualPriceTagsForRoomTypes
	|WHERE
	|	ManualPriceTagsForRoomTypes.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllDates.RoomRate AS RoomRate,
	|	AllDates.RoomType AS RoomType,
	|	AllDates.AccountingDate AS AccountingDate
	|INTO AllDates
	|FROM
	|	(SELECT
	|		Restrictions.RoomRate AS RoomRate,
	|		Restrictions.RoomType AS RoomType,
	|		Restrictions.AccountingDate AS AccountingDate
	|	FROM
	|		Restrictions AS Restrictions
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ManualPriceTagsForHotel.RoomRate,
	|		ManualPriceTagsForHotel.RoomType,
	|		ManualPriceTagsForHotel.AccountingDate
	|	FROM
	|		ManualPriceTagsForHotel AS ManualPriceTagsForHotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ManualPriceTagsForRoomTypes.RoomRate,
	|		ManualPriceTagsForRoomTypes.RoomType,
	|		ManualPriceTagsForRoomTypes.AccountingDate
	|	FROM
	|		ManualPriceTagsForRoomTypes AS ManualPriceTagsForRoomTypes) AS AllDates
	|
	|GROUP BY
	|	AllDates.RoomRate,
	|	AllDates.RoomType,
	|	AllDates.AccountingDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllDates.RoomRate AS RoomRate,
	|	AllDates.RoomType AS RoomType,
	|	AllDates.AccountingDate AS AccountingDate,
	|	Restrictions.StopSale AS StopSale,
	|	Restrictions.MLOS AS MLOS,
	|	Restrictions.MaxLOS AS MaxLOS,
	|	Restrictions.CTA AS CTA,
	|	Restrictions.CTD AS CTD,
	|	Restrictions.MinDaysBeforeCheckIn AS MinDaysBeforeCheckIn,
	|	Restrictions.MaxDaysBeforeCheckIn AS MaxDaysBeforeCheckIn,
	|	Restrictions.IsForOnlineOnly AS IsForOnlineOnly,
	|	CASE
	|		WHEN NOT ManualPriceTagsForRoomTypes.PriceTag IS NULL
	|			THEN ManualPriceTagsForRoomTypes.PriceTag
	|		WHEN NOT ManualPriceTagsForHotel.PriceTag IS NULL
	|			THEN ManualPriceTagsForHotel.PriceTag
	|		ELSE VALUE(Catalog.PriceTags.EmptyRef)
	|	END AS PriceTag
	|FROM
	|	AllDates AS AllDates
	|		LEFT JOIN Restrictions AS Restrictions
	|		ON AllDates.RoomRate = Restrictions.RoomRate
	|			AND AllDates.RoomType = Restrictions.RoomType
	|			AND AllDates.AccountingDate = Restrictions.AccountingDate
	|		LEFT JOIN ManualPriceTagsForHotel AS ManualPriceTagsForHotel
	|		ON AllDates.RoomRate = ManualPriceTagsForHotel.RoomRate
	|			AND AllDates.RoomType = ManualPriceTagsForHotel.RoomType
	|			AND AllDates.AccountingDate = ManualPriceTagsForHotel.AccountingDate
	|		LEFT JOIN ManualPriceTagsForRoomTypes AS ManualPriceTagsForRoomTypes
	|		ON AllDates.RoomRate = ManualPriceTagsForRoomTypes.RoomRate
	|			AND AllDates.RoomType = ManualPriceTagsForRoomTypes.RoomType
	|			AND AllDates.AccountingDate = ManualPriceTagsForRoomTypes.AccountingDate
	|
	|ORDER BY
	|	AllDates.RoomType,
	|	AllDates.AccountingDate";
	vQuery.SetParameter("qDateFrom", PeriodFrom);
	vQuery.SetParameter("qDateTo", PeriodTo);
	vQuery.SetParameter("qHotel", Hotel);
	vQuery.SetParameter("qRoomRate", RoomRate);
	vQuery.SetParameter("qCalendar", RoomRate.Calendar);
	vQuery.SetParameter("qPriceCalculationDate", CurrentSessionDate());
	
	vTabRes = vQuery.Execute();

	vTab = vTabRes.Select();
	Return vTab;
EndFunction // GetRestrictions

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRestrictions(pFirstRow, pTab)
	While pTab.Next() Do
		vRoomType = pTab.RoomType;
		
		If vRoomType = Hotel Then
			// Restrictions for all room types
			vParentRow = pFirstRow;
			vParentRowItems = vParentRow.GetItems();
			vNameRestrictions = NStr("en = 'Restrictions'; de = 'Beschränkungen'; ru = 'Ограничения'");
			If vParentRowItems.Count() = 0 Then
				// Row not found, add new
				// It's first row
				vRow = vParentRowItems.Add();
				vRow.RoomTypes = vNameRestrictions;
			Else
				vCurRow  = vParentRowItems[0];
				If vCurRow.RoomTypes = vNameRestrictions Then
				    vParentRow = vCurRow;
				Else	
				    // Row not found, add new                     
					vRow = vParentRowItems.Insert(0);
					vRow.RoomTypes = vNameRestrictions;
					vParentRow = vRow; 
				EndIf; 
			EndIf;
			// Add conditional appearance for main restrictions
			// Set parameters
			vParams = New Structure;
			vParams.Insert("BackColor", New Color(192,192,192));
			vParams.Insert("Font", New Font(,,,True));
			
			// Set filter field
			vFilters = New ValueTable;
			vFilters.Columns.Add("Name");
			vFilters.Columns.Add("ComparisonType");
			vFilters.Columns.Add("Value");
			
			vStrFilter = vFilters.Add();
			vStrFilter.Name = "CalendarDaysTypes.RoomTypes";
			vStrFilter.ComparisonType = DataCompositionComparisonType.Equal;
			vStrFilter.Value = vNameRestrictions;
			
			// Format fields
			vFields = New Array;
			vFields.Add("PriceTableRoomTypes");
			
			tcCommonFunctionOnClientServer.cmAddConditionalAppearance(ThisForm.ConditionalAppearance, vParams, vFilters, vFields);
		Else
			// Find the row by value
			vFirstRowItems = pFirstRow.GetItems();
			If vFirstRowItems.Count() = 0 Then
				vParentRow = vFirstRowItems.Add();
			Else	
				vParentRow = Undefined;
				For Each vRowTree In vFirstRowItems Do
					If vRoomType = vRowTree.RoomTypes Then
						vParentRow = vRowTree;
						Break;
					EndIf; 
				EndDo;
				If vParentRow = Undefined Then
					// Row not found
					vParentRow = vFirstRowItems.Add();
					vParentRow.RoomTypes = vRoomType;
					vParentRow.FieldName = ?(ValueIsFilled(RoomRate) And RoomRate.UsePricesFromCalendar, "RoomPrice", "CalendarDayType");
				EndIf; 
			EndIf; 
		EndIf; 
		
		vParentRowItems = vParentRow.GetItems();
		
		For i = 1 To 9 Do
			vColumnsName = "";
            vColumnsPres = "";
			
			GetNameItem(i, vColumnsName, vColumnsPres);
			
			If vParentRowItems.Count() = 0 Then
				vRow = vParentRowItems.Add();
			Else	
				vRow = Undefined;
				For Each vRowTree In vParentRowItems Do
					If vColumnsPres = vRowTree.RoomTypes Then
						vRow = vRowTree;
						Break;
					EndIf; 
				EndDo;
				If vRow = Undefined Then
					// Row not found
					vRow = vParentRowItems.Add();
				EndIf; 
			EndIf; 
			vRow.RoomTypes = vColumnsPres;
			vRow.FieldName = vColumnsName;
			vAccountingDate = pTab.AccountingDate;
			If ValueIsFilled(vAccountingDate) Then
				vId = Int((BegOfDay(vAccountingDate) - BegOfDay(Date))/86400)+1; 
				vDay = "Day"+String(vId);
				vRow[vDay] = pTab[vColumnsName];
				If TypeOf(pTab[vColumnsName]) = Type("Boolean") And pTab[vColumnsName] Or 
				   TypeOf(pTab[vColumnsName]) = Type("Number") And pTab[vColumnsName] > 0 Or
				   TypeOf(pTab[vColumnsName]) = Type("CatalogRef.PriceTags") And ValueIsFilled(pTab[vColumnsName]) Then
					If TypeOf(vParentRow.RoomTypes) = Type("String") Then
						vParentRow[vDay] = "●";
					EndIf;
				EndIf;
			EndIf; 
		EndDo;	
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GetNameItem(Val i, vColumnsName, vColumnsPres)
	If i = 1 Then
		vColumnsName = "StopSale";
		vColumnsPres = "StopSale";
	ElsIf i = 2 Then
		vColumnsName = "MLOS";
		vColumnsPres = "MinLOS";
	ElsIf i = 3 Then
		vColumnsName = "MaxLOS";
		vColumnsPres = "MaxLOS";
	ElsIf i = 4 Then
		vColumnsName = "CTA";
		vColumnsPres = "CTA";
	ElsIf i = 5 Then
		vColumnsName = "CTD";
		vColumnsPres = "CTD";
	ElsIf i = 6 Then
		vColumnsName = "MinDaysBeforeCheckIn";
		vColumnsPres = "MinAdvOffset";
	ElsIf i = 7 Then
		vColumnsName = "MaxDaysBeforeCheckIn";
		vColumnsPres = "MaxAdvOffset";
	ElsIf i = 8 Then
		vColumnsName = "IsForOnlineOnly";
		vColumnsPres = "Online";	
	ElsIf i = 9 Then
		vColumnsName = "PriceTag";
		vColumnsPres = NStr("en='Price tag'; ru='Признак цены'; de='Preistag'");	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function FillTreePricesRows(pItemsTree, pPrices)
	// Add first row as hotel for all days
	vFirstRow = pItemsTree.Add();
	vFirstRow.RoomTypes = Hotel;
	vFirstRow.FieldName = ?(ValueIsFilled(RoomRate) And RoomRate.UsePricesFromCalendar, "RoomPrice", "CalendarDayType");
	
	vArrDaysTypes = New Array;
	
	vCalendarDaysTypes = GetCalendarDaysTypes().Unload();
	
	For Each vRowPrices In pPrices Do
		vRoomType = vRowPrices.RoomType;
		If vRoomType = Hotel Then
			vRow = vFirstRow;
		Else
			// Find the row by value
			vFirstRowItems = vFirstRow.GetItems();
			If vFirstRowItems.Count() = 0 Then
				vRow = vFirstRowItems.Add();
			Else	
				vRow = Undefined;
				For Each vRowTree In vFirstRowItems Do
					If vRoomType = vRowTree.RoomTypes Then
						vRow = vRowTree;
						Break;
					EndIf; 
				EndDo;
				If vRow = Undefined Then
					// Row not found
					vRow = vFirstRowItems.Add();
				EndIf; 
			EndIf; 
		EndIf; 
		
		vRow.RoomTypes = vRoomType;
		vRow.FieldName = ?(ValueIsFilled(RoomRate) And RoomRate.UsePricesFromCalendar, "RoomPrice", "CalendarDayType");
		
		vAmount = vRowPrices.Amount;		
		
		If ValueIsFilled(vRowPrices.Period) And ValueIsFilled(vAmount) Then
			vId = Int((BegOfDay(vRowPrices.Period) - BegOfDay(Date))/86400)+1; 
			vDay = "Day" + String(vId);
			vRow[vDay] = cmFormatSum(vAmount, vRowPrices.Currency, "NZ=");
			
			vFilter = vCalendarDaysTypes.FindRows(New Structure("RoomType, Period", vRoomType, BegOfDay(vRowPrices.Period)));
			If vFilter.Count() > 0 Then
				AddConditionalAppearanceForPriceDay(vFilter[0].CalendarDayType, String(vId), vRoomType, vRow[vDay]);
			EndIf;
		EndIf; 
	EndDo;
	
	Return vFirstRow;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function FillTreeRoomTypesRows(pItemsTree, pTab)
	vShowRoomPricesFromCalendar = False;
	If ValueIsFilled(RoomRate) Then
		vShowRoomPricesFromCalendar = RoomRate.UsePricesFromCalendar;
	EndIf;
	
	// Add first row as hotel for all days
	vFirstRow = pItemsTree.Add();
	vFirstRow.RoomTypes = Hotel;
	vFirstRow.FieldName = ?(ValueIsFilled(RoomRate) And RoomRate.UsePricesFromCalendar, "RoomPrice", "CalendarDayType");
	
	vArrDaysTypes = New Array;
	
	While pTab.Next() Do
		vRoomType = pTab.RoomType;
		If vRoomType  = Hotel Then
			vRow = vFirstRow;
		Else
			// Find the row by value
			vFirstRowItems = vFirstRow.GetItems();
			If vFirstRowItems.Count() = 0 Then
				vRow = vFirstRowItems.Add();
			Else	
				vRow = Undefined;
				For Each vRowTree In vFirstRowItems Do
					If vRoomType = vRowTree.RoomTypes Then
						vRow = vRowTree;
						Break;
					EndIf; 
				EndDo;
				If vRow = Undefined Then
					// Row not found
					vRow = vFirstRowItems.Add();
				EndIf; 
			EndIf; 
		EndIf; 
		
		vRow.RoomTypes = vRoomType;
		vRow.FieldName = ?(ValueIsFilled(RoomRate) And RoomRate.UsePricesFromCalendar, "RoomPrice", "CalendarDayType");
		
		vCalendarDayType = pTab.CalendarDayType;		
		
		If ValueIsFilled(pTab.Period) Then
			vId = Int((BegOfDay(pTab.Period) - BegOfDay(Date))/86400)+1; 
			vDay = "Day"+String(vId);
			If vShowRoomPricesFromCalendar Then
				vRow[vDay] = cmFormatSum(pTab.RoomPrice, pTab.RoomPriceCurrency, "NZ=");
			Else
				vRow[vDay] = vCalendarDayType;
			EndIf;
		EndIf; 
		
		// Fill color conditional appearance
		If ValueIsFilled(vCalendarDayType) And vArrDaysTypes.Find(vCalendarDayType) = Undefined Then
			vArrDaysTypes.Add(vCalendarDayType);
			AddConditionalAppearance(vCalendarDayType);
		EndIf; 
	EndDo;
	
	Return vFirstRow;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function GetCalendarDaysTypes()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	qRoomTypes.RoomType.SortCode AS SortCode,
	|	qRoomTypes.RoomType AS RoomType,
	|	ISNULL(CalendarDaysByRoomTypes.CalendarDayType, VALUE(Catalog.CalendarDayTypes.EmptyRef)) AS CalendarDayType,
	|	ISNULL(CalendarDaysByRoomTypes.RoomPrice, 0) AS RoomPrice,
	|	ISNULL(CalendarDaysByRoomTypes.RoomPriceCurrency, VALUE(Catalog.Currencies.EmptyRef)) AS RoomPriceCurrency,
	|	CalendarDaysByRoomTypes.AccountingDate AS Period
	|FROM
	|	(SELECT
	|		RoomInventoryBalance.RoomType AS RoomType
	|	FROM
	|		AccumulationRegister.RoomInventory.Balance(&qDateTo, ) AS RoomInventoryBalance
	|	WHERE
	|		RoomInventoryBalance.TotalRoomsBalance > 0
	|		AND RoomInventoryBalance.Hotel = &qHotel
	|		AND NOT RoomInventoryBalance.RoomType.DeletionMark
	|		AND RoomInventoryBalance.RoomType.BaseRoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomTypes.Ref
	|	FROM
	|		Catalog.RoomTypes AS RoomTypes
	|	WHERE
	|		RoomTypes.Owner = &qHotel
	|		AND NOT RoomTypes.DeletionMark
	|		AND NOT RoomTypes.IsFolder
	|		AND RoomTypes.BaseRoomType <> VALUE(Catalog.RoomTypes.EmptyRef)) AS qRoomTypes
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(
	|				&qPriceCalculationDate,
	|				AccountingDate BETWEEN &qDateFrom AND &qDateTo
	|					AND Calendar = &qCalendar) AS CalendarDaysByRoomTypes
	|		ON qRoomTypes.RoomType = CalendarDaysByRoomTypes.RoomType
	|
	|UNION ALL
	|
	|SELECT
	|	0.1,
	|	&qHotel,
	|	CalendarDays.CalendarDayType,
	|	CalendarDays.RoomPrice,
	|	CalendarDays.RoomPriceCurrency,
	|	CalendarDays.AccountingDate
	|FROM
	|	InformationRegister.CalendarDays.SliceLast(
	|			&qPriceCalculationDate,
	|			Calendar = &qCalendar
	|				AND (AccountingDate BETWEEN &qDateFrom AND &qDateTo)) AS CalendarDays
	|
	|ORDER BY
	|	SortCode";
	
	vQuery.SetParameter("qPriceCalculationDate", ?(ValueIsFilled(PriceCalculationDate), New Boundary(PriceCalculationDate, BoundaryType.Including), CurrentSessionDate()));
	vQuery.SetParameter("qCalendar", RoomRate.Calendar);
	vQuery.SetParameter("qRoomRate", RoomRate);
	vQuery.SetParameter("qDateFrom", PeriodFrom);
	vQuery.SetParameter("qDateTo", PeriodTo);
	vQuery.SetParameter("qHotel", Hotel);
	
	vRes = vQuery.Execute();
	
	Return vRes;
EndFunction // GetCalendarDayTypes

// -----------------------------------------------------------------------------
&AtServer
Procedure AddConditionalAppearanceForEmptyDays(pFirstRow)
	vFirstRowItems = pFirstRow.GetItems(); 
	For Each vRowTree In vFirstRowItems Do
		For i = 1 To 31 Do
			vDay = "Day"+i;
			vCalendarDayTypeFirstRow = pFirstRow[vDay];
			vCurCalendarDayType = vRowTree[vDay];
			If ValueIsFilled(vCalendarDayTypeFirstRow) 
				And Not ValueIsFilled(vCurCalendarDayType) 
				And pFirstRow <> vRowTree Then
				
				// Set parameters
				vParams = New Structure;
				vParams.Insert("TextColor", New Color(204,204,204));
				If TypeOf(vCalendarDayTypeFirstRow) = Type("String") Then
					vParams.Insert("Text", vCalendarDayTypeFirstRow);
				Else
					vParams.Insert("Text", vCalendarDayTypeFirstRow.Description);
				EndIf;
				
				// Set filter field
				vFilters = New ValueTable;
				vFilters.Columns.Add("Name");
				vFilters.Columns.Add("ComparisonType");
				vFilters.Columns.Add("Value");
				
				vStrFilter = vFilters.Add();
				vStrFilter.Name = "CalendarDaysTypes.RoomTypes";
				vStrFilter.ComparisonType = DataCompositionComparisonType.Equal;
				vStrFilter.Value = vRowTree.RoomTypes;
				
				// Format fields
				vFields = New Array;
				vFields.Add("PriceTableDay" + i);
				
				tcCommonFunctionOnClientServer.cmAddConditionalAppearance(ThisForm.ConditionalAppearance, vParams, vFilters, vFields);
			EndIf; 
		EndDo;
	EndDo;
EndProcedure 

// -----------------------------------------------------------------------------
&AtServer
Procedure AddConditionalAppearance(pCalendarDayType)
	vColor = GetColorFromValueStorage(pCalendarDayType);
	If vColor <> Undefined Then
		// Back color for calendar days types
		For i = 1 to 31 Do
			// Set parameters
			vParams = New Structure;
			vParams.Insert("BackColor", vColor);
			
			// Set filter field
			vFilters = New ValueTable;
			vFilters.Columns.Add("Name");
			vFilters.Columns.Add("ComparisonType");
			vFilters.Columns.Add("Value");
			
			vStrFilter = vFilters.Add();
			vStrFilter.Name = "CalendarDaysTypes.Day" + i;
			vStrFilter.ComparisonType = DataCompositionComparisonType.Equal;
			vStrFilter.Value = pCalendarDayType;
			
			// Format fields
			vFields = New Array;
			vFields.Add("PriceTableDay" + i);
			
			tcCommonFunctionOnClientServer.cmAddConditionalAppearance(ThisForm.ConditionalAppearance, vParams, vFilters, vFields);
		EndDo
	EndIf;
EndProcedure //  AddConditionalAppearance()

// -----------------------------------------------------------------------------
&AtServer
Procedure AddConditionalAppearanceForPriceDay(pCalendarDayType, pDayNumber, pRoomType, pPrice)
	vColor = GetColorFromValueStorage(pCalendarDayType);
	If vColor <> Undefined Then
		// Back color for calendar days types
		// Set parameters
		vParams = New Structure;
		vParams.Insert("BackColor", vColor);
		
		// Set filter field
		vFilters = New ValueTable;
		vFilters.Columns.Add("Name");
		vFilters.Columns.Add("ComparisonType");
		vFilters.Columns.Add("Value");
		
		vStrFilter = vFilters.Add();
		vStrFilter.Name = "CalendarDaysTypes.Day" + pDayNumber;
		vStrFilter.ComparisonType = DataCompositionComparisonType.Equal;
		vStrFilter.Value = pPrice;
		
		vStrFilter = vFilters.Add();
		vStrFilter.Name = "CalendarDaysTypes.RoomTypes";
		vStrFilter.ComparisonType = DataCompositionComparisonType.Equal;
		vStrFilter.Value = pRoomType;
		
		// Format fields
		vFields = New Array;
		vFields.Add("PriceTableDay" + pDayNumber);
		
		tcCommonFunctionOnClientServer.cmAddConditionalAppearance(ThisForm.ConditionalAppearance, vParams, vFilters, vFields);
	EndIf;
EndProcedure //  AddConditionalAppearance()

// -------------------------------------------------------------------------
&AtClient
Procedure CheckBackgroundJobs()
	vProcessing = True;
	vBackgroundJob 	= CheckBackgroundJobStatus(BackgroundJobUUID);
	vMsg = "";
	vJobName = "FillRoomRateDailyPrices";
	
	If vBackgroundJob <> Undefined Then 
		If  vBackgroundJob.Status = "Error" Then 
			vProcessing = False;
			Status(NStr("en = 'Updating prices'; de = 'Preise aktualisieren'; ru = 'Обновление цен'"), , NStr("en = 'Error in background job'; de = 'Fehler im Hintergrundjob'; ru = 'Ошибка выполнения фонового задания'"), PictureLib.DialogStop); 
		ElsIf vBackgroundJob.Status = "Canceled" Then 
			vProcessing = False;	
			Status(NStr("en = 'Updating prices'; de = 'Preise aktualisieren'; ru = 'Обновление цен'"), , NStr("en = 'Error in background job'; de = 'Fehler im Hintergrundjob'; ru = 'Ошибка выполнения фонового задания'"), PictureLib.DialogStop); 
		ElsIf vBackgroundJob.Status = "Completed" Then 
			vProcessing = False;
			
			vMsg = Nstr("en = 'Filling prices completed'; de = 'Füllpreise abgeschlossen'; ru = 'Заполнение цен выполнено'");
			Status(NStr("en = 'Updating prices'; de = 'Preise aktualisieren'; ru = 'Обновление цен'"), , vMsg, PictureLib.DialogInformation); 
			
			FillTree();
		Else
			Status(NStr("en = 'Updating prices'; de = 'Preise aktualisieren'; ru = 'Обновление цен'"), , NStr("en = 'Job in progress ...'; de = 'Job in Bearbeitung ...'; ru = 'Задание выполняется...'"), PictureLib.DialogInformation); 
		EndIf;
	Else
		Status(NStr("en = 'Updating prices'; de = 'Preise aktualisieren'; ru = 'Обновление цен'"), , NStr("en = 'Error in background job'; de = 'Fehler im Hintergrundjob'; ru = 'Ошибка выполнения фонового задания'"), PictureLib.DialogStop); 
	EndIf;
	
	If NOT vProcessing Then
		BackgroundJobUUID = Undefined;
		DetachIdleHandler("CheckBackgroundJobs");
	EndIf;
EndProcedure	

// -------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function GetOccupationPercent(pHotel = Undefined, pPeriodFrom = Undefined, pPeriodTo = Undefined)
	vHotel = pHotel; 
	If vHotel = Undefined Then 
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	
	vForecastStartDate = tcOnServer.GetForecastStartDate(vHotel);
	
	vPeriodFrom = pPeriodFrom; 
	If vPeriodFrom = Undefined Then 
		vPeriodFrom = BegOfDay(CurrentSessionDate());
	EndIf;

	vPeriodTo = pPeriodTo; 
	If vPeriodTo = Undefined Then
		vPeriodTo = EndOfDay(CurrentSessionDate());
	EndIf;
	
	// Run query to get room inventory
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SalesTurnovers.Period AS Period,
	|	SUM(SalesTurnovers.RoomsRented) AS RoomsRented
	|INTO SalesTurnovers
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Period AS Period,
	|		RoomSalesTurnovers.RoomsRentedTurnover AS RoomsRented
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, DAY, Hotel IN HIERARCHY (&qHotel)) AS RoomSalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomSalesForecastTurnovers.Period,
	|		RoomSalesForecastTurnovers.RoomsRentedTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(&qForecastPeriodFrom, &qForecastPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS RoomSalesForecastTurnovers) AS SalesTurnovers
	|
	|GROUP BY
	|	SalesTurnovers.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalance.Period AS Period,
	|	ISNULL(SalesTurnovers.RoomsRented, 0) AS RoomsRented,
	|	RoomInventoryBalance.TotalRoomsClosingBalance AS TotalRooms,
	|	RoomInventoryBalance.RoomsBlockedClosingBalance AS RoomsBlocked,
	|	RoomInventoryBalance.CounterClosingBalance AS Counter
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, DAY, , Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalance
	|		LEFT JOIN SalesTurnovers AS SalesTurnovers
	|		ON RoomInventoryBalance.Period = SalesTurnovers.Period
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qPeriodFrom", vPeriodFrom);
	vQry.SetParameter("qPeriodTo", vPeriodTo);
	vQry.SetParameter("qForecastPeriodFrom", Max(vForecastStartDate, vPeriodFrom));
	vQry.SetParameter("qForecastPeriodTo", Max(vForecastStartDate, vPeriodTo));
	vQry.SetParameter("qHotel", vHotel);
	vInvResult = vQry.Execute().Unload();
	
	Return vInvResult;
EndFunction	

// -----------------------------------------------------------------------------
&AtServer
Function GetColorFromValueStorage(pRef)
	vColor = Undefined;
	If TypeOf(pRef["Color"]) = Type("ValueStorage") Then
		vColor = pRef["Color"].Get();
	EndIf;
	If vColor <> Undefined And TypeOf(vColor) <> Type("Color") Then
		vColor = Undefined;
	EndIf;
	Return vColor;
EndFunction //  cmGetColorFromValueStorage

#EndRegion

#Region History

// -----------------------------------------------------------------------------
&AtServer
Procedure GetHistoryYears()
	Items.HistoryPeriodYear.ChoiceList.Clear();
	Items.HistoryPeriodMonth.ChoiceList.Clear();
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();
	
	If Not ValueIsFilled(RoomRate) Then
		Return;
	EndIf;
	
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Years.Year AS Year
	|FROM
	|	(SELECT DISTINCT
	|		YEAR(CalendarDaysByRoomTypes.Period) AS Year
	|	FROM
	|		InformationRegister.CalendarDaysByRoomTypes AS CalendarDaysByRoomTypes
	|	WHERE
	|		CalendarDaysByRoomTypes.Calendar = &qCalendar
	|		AND CalendarDaysByRoomTypes.AccountingDate BETWEEN &qBegDate AND &qEndDate
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		YEAR(CalendarDays.Period)
	|	FROM
	|		InformationRegister.CalendarDays AS CalendarDays
	|	WHERE
	|		CalendarDays.Calendar = &qCalendar
	|		AND CalendarDays.AccountingDate BETWEEN &qBegDate AND &qEndDate) AS Years
	|
	|ORDER BY
	|	Year";	
	vQry.SetParameter("qCalendar", RoomRate.Calendar);
	vQry.SetParameter("qBegDate", PeriodFrom);
	vQry.SetParameter("qEndDate", PeriodTo);
	
	vHistoryYears = vQry.Execute().Unload();
	For Each vHistoryYearsRow In vHistoryYears Do
		Items.HistoryPeriodYear.ChoiceList.Add(vHistoryYearsRow.Year, Format(vHistoryYearsRow.Year, "ND=4; NFD=0; NLZ=; NG="));
	EndDo;
EndProcedure // GetHistoryYears

// -----------------------------------------------------------------------------
&AtServer
Procedure GetHistoryMonths()
	Items.HistoryPeriodMonth.ChoiceList.Clear();
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();

	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Monthes.Month AS Month
	|FROM
	|	(SELECT DISTINCT
	|		MONTH(CalendarDaysByRoomTypes.Period) AS Month
	|	FROM
	|		InformationRegister.CalendarDaysByRoomTypes AS CalendarDaysByRoomTypes
	|	WHERE
	|		CalendarDaysByRoomTypes.Calendar = &qCalendar
	|		AND CalendarDaysByRoomTypes.AccountingDate BETWEEN &qBegDate AND &qEndDate
	|		AND YEAR(CalendarDaysByRoomTypes.Period) = &qYear
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		MONTH(CalendarDays.Period)
	|	FROM
	|		InformationRegister.CalendarDays AS CalendarDays
	|	WHERE
	|		CalendarDays.Calendar = &qCalendar
	|		AND CalendarDays.AccountingDate BETWEEN &qBegDate AND &qEndDate
	|		AND YEAR(CalendarDays.Period) = &qYear) AS Monthes
	|
	|ORDER BY
	|	Month";
	vQry.SetParameter("qCalendar", RoomRate.Calendar);
	vQry.SetParameter("qBegDate", PeriodFrom);
	vQry.SetParameter("qEndDate", PeriodTo);
	vQry.SetParameter("qYear", HistoryPeriodYear);
	
	vHistoryMonths = vQry.Execute().Unload();
	For Each vHistoryMonthsRow In vHistoryMonths Do
		vDate = Date(HistoryPeriodYear, vHistoryMonthsRow.Month, 1);
		Items.HistoryPeriodMonth.ChoiceList.Add(vHistoryMonthsRow.Month, Format(vHistoryMonthsRow.Month, "ND=2; NFD=0; NLZ=; NG=") + " - " + cmGetMonthName(vHistoryMonthsRow.Month, False) + " " + Format(HistoryPeriodYear, "ND=4; NFD=0; NLZ=; NG="));
	EndDo;
EndProcedure // GetHistoryMonths

// -----------------------------------------------------------------------------
&AtServer
Procedure GetHistoryDays()
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();

	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Days.Day AS Day
	|FROM
	|	(SELECT DISTINCT
	|		DAY(CalendarDaysByRoomTypes.Period) AS Day
	|	FROM
	|		InformationRegister.CalendarDaysByRoomTypes AS CalendarDaysByRoomTypes
	|	WHERE
	|		CalendarDaysByRoomTypes.Calendar = &qCalendar
	|		AND CalendarDaysByRoomTypes.AccountingDate BETWEEN &qBegDate AND &qEndDate
	|		AND YEAR(CalendarDaysByRoomTypes.Period) = &qYear
	|		AND MONTH(CalendarDaysByRoomTypes.Period) = &qMonth
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		DAY(CalendarDays.Period)
	|	FROM
	|		InformationRegister.CalendarDays AS CalendarDays
	|	WHERE
	|		CalendarDays.Calendar = &qCalendar
	|		AND CalendarDays.AccountingDate BETWEEN &qBegDate AND &qEndDate
	|		AND YEAR(CalendarDays.Period) = &qYear
	|		AND MONTH(CalendarDays.Period) = &qMonth) AS Days
	|
	|ORDER BY
	|	Day";	
	vQry.SetParameter("qCalendar", RoomRate.Calendar);
	vQry.SetParameter("qBegDate", PeriodFrom);
	vQry.SetParameter("qEndDate", PeriodTo);
	vQry.SetParameter("qYear", HistoryPeriodYear);
	vQry.SetParameter("qMonth", HistoryPeriodMonth);
	
	vHistoryDays = vQry.Execute().Unload();
	For Each vHistoryDaysRow In vHistoryDays Do
		vDate = Date(HistoryPeriodYear, HistoryPeriodMonth, vHistoryDaysRow.Day);
		Items.HistoryPeriodDay.ChoiceList.Add(vHistoryDaysRow.Day, Format(vDate, "DF=dd.MM.yyyy") + " - " + cmGetDayOfWeekName(WeekDay(vDate), True));
	EndDo;
EndProcedure // GetHistoryDays

// -----------------------------------------------------------------------------
&AtServer
Procedure GetHistoryPeriods()
	Items.HistoryPeriod.ChoiceList.Clear();

	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	DayPeriods.Period AS Period,
	|	DayPeriods.Author AS Author
	|FROM
	|	(SELECT DISTINCT
	|		CalendarDaysByRoomTypes.Period AS Period,
	|		CalendarDaysByRoomTypes.Author AS Author
	|	FROM
	|		InformationRegister.CalendarDaysByRoomTypes AS CalendarDaysByRoomTypes
	|	WHERE
	|		CalendarDaysByRoomTypes.Calendar = &qCalendar
	|		AND CalendarDaysByRoomTypes.AccountingDate BETWEEN &qBegDate AND &qEndDate
	|		AND YEAR(CalendarDaysByRoomTypes.Period) = &qYear
	|		AND MONTH(CalendarDaysByRoomTypes.Period) = &qMonth
	|		AND DAY(CalendarDaysByRoomTypes.Period) = &qDay
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		CalendarDays.Period,
	|		CalendarDays.Author
	|	FROM
	|		InformationRegister.CalendarDays AS CalendarDays
	|	WHERE
	|		CalendarDays.Calendar = &qCalendar
	|		AND CalendarDays.AccountingDate BETWEEN &qBegDate AND &qEndDate
	|		AND YEAR(CalendarDays.Period) = &qYear
	|		AND MONTH(CalendarDays.Period) = &qMonth
	|		AND DAY(CalendarDays.Period) = &qDay) AS DayPeriods
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qCalendar", RoomRate.Calendar);
	vQry.SetParameter("qBegDate", PeriodFrom);
	vQry.SetParameter("qEndDate", PeriodTo);
	vQry.SetParameter("qYear", HistoryPeriodYear);
	vQry.SetParameter("qMonth", HistoryPeriodMonth);
	vQry.SetParameter("qDay", HistoryPeriodDay);
	
	vHistoryPeriods = vQry.Execute().Unload();
	For Each vHistoryPeriodsRow In vHistoryPeriods Do
		Items.HistoryPeriod.ChoiceList.Add(vHistoryPeriodsRow.Period, Format(vHistoryPeriodsRow.Period, "DF=HH:mm:ss") + " - " + TrimAll(vHistoryPeriodsRow.Author));
	EndDo;
EndProcedure // GetHistoryPeriods

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowHistoryOnChange(pItem)
	PriceCalculationDate = '00010101';
	Items.HistoryPeriodYear.ChoiceList.Clear();
	Items.HistoryPeriodMonth.ChoiceList.Clear();
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();
	Items.GroupHistoryData.Enabled = ShowHistory;

	If ShowHistory Then
		CalendarDaysTypes.GetItems().Clear();
		
		GetHistoryYears();
	Else
		HistoryPeriodYear = 0;
		HistoryPeriodMonth = 0;
		HistoryPeriodDay = 0;
		HistoryPeriod = '00010101';
		PriceCalculationDate = '00010101';
		
		FillTree();
	EndIf;
EndProcedure // ShowHistoryOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HistoryPeriodYearOnChange(pItem)
	CalendarDaysTypes.GetItems().Clear();
	HistoryPeriod = '00010101';
	Items.HistoryPeriodMonth.ChoiceList.Clear();
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();
	If HistoryPeriodYear > 0 Then
		GetHistoryMonths();
	EndIf;
EndProcedure // HistoryPeriodYearOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HistoryPeriodMonthOnChange(pItem)
	CalendarDaysTypes.GetItems().Clear();
	HistoryPeriod = '00010101';
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();
	If HistoryPeriodYear > 0 And HistoryPeriodMonth > 0 Then
		GetHistoryDays();
	EndIf;
EndProcedure // HistoryPeriodMonthOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HistoryPeriodDayOnChange(pItem)
	CalendarDaysTypes.GetItems().Clear();
	HistoryPeriod = '00010101';
	Items.HistoryPeriod.ChoiceList.Clear();
	If HistoryPeriodYear > 0 And HistoryPeriodMonth > 0 And HistoryPeriodDay > 0 Then
		GetHistoryPeriods();
	EndIf;
EndProcedure // HistoryPeriodDayOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HistoryPeriodOnChange(pItem)
	CalendarDaysTypes.GetItems().Clear();
	If ValueIsFilled(HistoryPeriod) Then
		PriceCalculationDate = HistoryPeriod;
		FillTree();
	EndIf;
EndProcedure // HistoryPeriodOnChange

#EndRegion



