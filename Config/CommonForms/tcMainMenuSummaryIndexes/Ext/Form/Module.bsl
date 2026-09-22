
#Region Variables

Var TotalPerDay;
Var ExpTotalGuests;
Var MoreThanOneRecord;
Var Tabulation; 

#EndRegion

#Region FormEventHandlers

// -------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Hotel = SessionParameters.CurrentHotel;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	// Check if hotel can be changed
	If Not IsInRole("RightsToChooseHotel") Then
		Items.Hotel.ReadOnly = True;
		Items.Hotel.ChoiceButton = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToViewHotelOccupationStatistics") Then
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	ThisForm.AutoSaveDataInSettings = AutoSaveFormDataInSettings.Use;
	ThisForm.SaveDataInSettings = SaveFormDataInSettings.UseList;
	ThisForm.SavedInSettingsDataModified = True;

	// Read default parameters
	GetHotelAndPeriod();
	
	// Set first date column caption
	Items.ColumnIndexPresentation.Title = Format(PeriodTo, "DLF=D");
	Items.ColumnSecondDateIndexPresentation.Title = Format(PeriodTo, "DLF=D");
	
	// Read data
	GetRooms();
	
	// Build chart
	ChartBuild();
	
	// Set columns visibility
	If ValueIsFilled(CompareDate) Then
		Items.ColumnSecondDateIndexPresentation.Visible = True;
		Items.ColumnIcon.Visible = True;
	Else
		Items.ColumnSecondDateIndexPresentation.Visible = False;
		Items.ColumnIcon.Visible = False;
	EndIf;
	
	#IF MobileClient Then
		ChangeAttributesAtServer();
	#ENDIF
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure CompareDateOnChange(Item)
	ChartBuild(False);
	// Fill indexes for second date
	CompareCompositionDate = CompareDate;
	If ValueIsFilled(CompareDate) Then
		Items.ColumnSecondDateIndexPresentation.Title = Format(CompareDate, "DF=dd.MM.yyyy");
		GetCompareRooms();
		ChartBuild(True);
	EndIf;
	// Set columns visibility
	If ValueIsFilled(CompareDate) Then
		Items.ColumnSecondDateIndexPresentation.Visible = True;
		Items.ColumnIcon.Visible = True;
	Else
		Items.ColumnSecondDateIndexPresentation.Visible = False;
		Items.ColumnIcon.Visible = False;
	EndIf;
EndProcedure // CompareDateOnChange

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	vSelectedValue = pItem.ChoiceList.FindByValue(pSelectedValue).Value;
	If ChoosePeriod <> vSelectedValue Then
		Items.ColumnSecondDateIndexPresentation.Visible = False;
		Items.ColumnIcon.Visible = False;
		If pSelectedValue = "0" Then
			Items.PeriodDay.Visible = True;
			Items.SelYear.Visible = False;
			Items.SelQuarter.Visible = False;
			Items.SelMonth.Visible = False;
			Items.CompareYear.Visible = False;
			Items.CompareYear.TitleLocation = FormItemTitleLocation.None;
			Items.CompareQuarter.Visible = False;
			Items.CompareMonth.Visible = False;
			PeriodToOnChange(Items.PeriodTo);
		ElsIf pSelectedValue = "1" Then
			Items.PeriodDay.Visible = False;
			Items.SelYear.Visible = True;
			Items.SelQuarter.Visible = False;
			Items.SelMonth.Visible = True;
			CompareYear = "-//-";
			Items.CompareYear.Visible = True;
			Items.CompareYear.TitleLocation = FormItemTitleLocation.None;
			Items.CompareQuarter.Visible = False;
			CompareMonth = NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'");
			Items.CompareMonth.Visible = True;
			SelMonthOnChange(Items.SelMonth);
		ElsIf pSelectedValue = "2" Then
			Items.PeriodDay.Visible = False;
			Items.SelYear.Visible = True;
			Items.SelQuarter.Visible = True;
			Items.SelMonth.Visible = False;
			CompareYear = "-//-";
			Items.CompareYear.Visible = True;
			Items.CompareYear.TitleLocation = FormItemTitleLocation.None;
			CompareQuarter = NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'");
			Items.CompareQuarter.Visible = True;
			Items.CompareMonth.Visible = False;
			SelQuarterOnChange(Items.SelQuarter);
		Else
			Items.PeriodDay.Visible = False;
			Items.SelYear.Visible = True;
			Items.SelQuarter.Visible = False;
			Items.SelMonth.Visible = False;
			CompareYear = "-//-";
			Items.CompareYear.Visible = True;
			Items.CompareYear.TitleLocation = FormItemTitleLocation.Auto;
			Items.CompareQuarter.Visible = False;
			Items.CompareMonth.Visible = False;
			SelYearOnChange(Items.SelYear, True);
		EndIf;
	EndIf;
EndProcedure // ChoosePeriodChoiceProcessing

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure SelYearChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	SelYear = pItem.ChoiceList.FindByValue(pSelectedValue).Value;
	Try
		CompositionDate = Date(Number(SelYear), Month(CompositionDate), 1,1,1,1);
		SelYearOnChange(pItem);
	Except
	EndTry;
EndProcedure // SelYearChoiceProcessing

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure SelQuarterChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	SelQuarter = pItem.ChoiceList.FindByValue(pSelectedValue).Value;
	CompositionDate = Date(Number(SelYear), Number(pSelectedValue)*3, 1,1,1,1);
	SelQuarterOnChange(pItem);
EndProcedure // SelQuarterChoiceProcessing

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure SelMonthChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	SelMonth = pItem.ChoiceList.FindByValue(pSelectedValue).Value;
	MonthNumber = pSelectedValue;
	CompositionDate = Date(Number(SelYear), Number(pSelectedValue), 1,1,1,1);
	SelMonthOnChange(pItem);
EndProcedure // SelMonthChoiceProcessing

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure SelYearOnChange(pItem, pOnChoose = False)
	If pOnChoose = Undefined Then
		pOnChoose = False;
	EndIf;
	If Not ValueIsFilled(SelYear) Then
		SelYear = Format(Year(CurrentDate()), "ND=4; NFD=0; NG=");
	EndIf;
	If Number(SelYear) < 1950 Then
		SelYear = "1950";
	EndIf;
	CompositionDate = Date(Number(SelYear), Month(CompositionDate), 1,1,1,1);
	If Not Items.SelMonth.Visible AND Not Items.SelQuarter.Visible Then
		// Set column title
		Items.ColumnIndexPresentation.Title = Format(SelYear, "ND=4; NFD=0; NG=");
	ElsIf Items.SelMonth.Visible Then
		// Set column title
		Items.ColumnIndexPresentation.Title = Items.SelMonth.ChoiceList.FindByValue(TrimAll(SelMonth)).Presentation + " " + Format(SelYear, "ND=4; NFD=0; NG=");
	ElsIf Items.SelQuarter.Visible Then
		// Set column title
		Items.ColumnIndexPresentation.Title = Items.SelQuarter.ChoiceList.FindByValue(TrimAll(SelQuarter)).Presentation + " " + Format(SelYear, "ND=4; NFD=0; NG=");
	EndIf;
	If pItem.EditText <> Format(SelYear, "ND=4; NFD=0; NG=") Or pOnChoose Then
		// Rebuild charts and tables
		vDoCompareColumn = False;
		If ChoosePeriod = TrimAll(Items.ChoosePeriod.ChoiceList.FindByValue("0").Value) Then
			If ValueIsFilled(CompareDate) Then
				vDoCompareColumn = True;
			EndIf;
		ElsIf ChoosePeriod = TrimAll(Items.ChoosePeriod.ChoiceList.FindByValue("1").Value) Then
			If ValueIsFilled(CompareYear) And CompareYear <> "-//-" And CompareMonth <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") Then
				vDoCompareColumn = True;
			EndIf;
		ElsIf ChoosePeriod = TrimAll(Items.ChoosePeriod.ChoiceList.FindByValue("2").Value) Then
			If ValueIsFilled(CompareYear) And CompareYear <> "-//-" And CompareQuarter <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") Then
				vDoCompareColumn = True;
			EndIf;
		Else 
			If ValueIsFilled(CompareYear) And CompareYear <> "-//-" Then
				vDoCompareColumn = True;
			EndIf;
		EndIf;
		ChartBuild(False);
		If vDoCompareColumn Then
			GetCompareRooms();
			ChartBuild(True);
		Else
			GetRooms();
		EndIf;
	EndIf;
EndProcedure // SelYearOnChange

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure SelMonthOnChange(pItem)
	If Not ValueIsFilled(SelYear) Then
		SelYear = Format(Year(CurrentDate()), "ND=4; NFD=0; NG=");
	EndIf;
	// Set column title
	Items.ColumnIndexPresentation.Title = Items.SelMonth.ChoiceList.FindByValue(TrimAll(SelMonth)).Presentation + " " + Format(SelYear, "ND=4; NFD=0; NG=");
	CompositionDate = Date(Number(SelYear), Number(MonthNumber), 1,1,1,1);
	If pItem.EditText <> SelMonth Then
		// Rebuild charts and tables
		vDoCompareColumn = False;
		If TrimAll(ChoosePeriod) = TrimAll(Items.ChoosePeriod.ChoiceList.FindByValue("0").Value) Then
			If ValueIsFilled(CompareDate) Then
				vDoCompareColumn = True;
			EndIf;
		ElsIf TrimAll(ChoosePeriod) = TrimAll(Items.ChoosePeriod.ChoiceList.FindByValue("1").Value) Then
			If ValueIsFilled(CompareYear) And CompareYear <> "-//-" And CompareMonth <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") Then
				vDoCompareColumn = True;
			EndIf;
		ElsIf TrimAll(ChoosePeriod) = TrimAll(Items.ChoosePeriod.ChoiceList.FindByValue("2").Value) Then
			If ValueIsFilled(CompareYear) And CompareYear <> "-//-" And CompareQuarter <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") Then
				vDoCompareColumn = True;
			EndIf;
		Else 
			If ValueIsFilled(CompareYear) And CompareYear <> "-//-" Then
				vDoCompareColumn = True;
			EndIf;
		EndIf;
		ChartBuild(False);
		If vDoCompareColumn Then
			GetCompareRooms();
			ChartBuild(True);
		Else
			GetRooms();
		EndIf;
	EndIf;  
EndProcedure // SelMonthOnChange

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure SelQuarterOnChange(pItem)
	If Not ValueIsFilled(SelYear) Then
		SelYear = Format(Year(CurrentDate()), "ND=4; NFD=0; NG=");
	EndIf;
	// Set column title
	Items.ColumnIndexPresentation.Title = Items.SelQuarter.ChoiceList.FindByValue(TrimAll(SelQuarter)).Presentation + " " + Format(SelYear, "ND=4; NFD=0; NG=");
	If pItem.EditText <> SelQuarter Then
		// Rebuild charts and tables
		vDoCompareColumn = False;
		If ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("0").Value Then
			If ValueIsFilled(CompareDate) Then
				vDoCompareColumn = True;
			EndIf;
		ElsIf ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("1").Value Then
			If ValueIsFilled(CompareYear) And CompareYear <> "-//-" And CompareMonth <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") Then
				vDoCompareColumn = True;
			EndIf;
		ElsIf ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("2").Value Then
			If ValueIsFilled(CompareYear) And CompareYear <> "-//-" And CompareQuarter <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") Then
				vDoCompareColumn = True;
			EndIf;
		Else 
			If ValueIsFilled(CompareYear) And CompareYear <> "-//-" Then
				vDoCompareColumn = True;
			EndIf;
		EndIf;
		ChartBuild(False);
		If vDoCompareColumn Then
			GetCompareRooms();
			ChartBuild(True);
		Else
			GetRooms();
		EndIf;
	EndIf;
EndProcedure // SelQuarterOnChange

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure CompareYearChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	CompareYear = pItem.ChoiceList.FindByValue(pSelectedValue).Value;
	If pSelectedValue <> "-//-" Then
		CompareCompositionDate = Date(Number(CompareYear), Month(CompareCompositionDate), 1,1,1,1);
		CompareYearOnChange(pItem);
	Else
		Items.ColumnSecondDateIndexPresentation.Visible = False;
		Items.ColumnIcon.Visible = False;
		ChartBuild(False);
	EndIf;
EndProcedure // CompareYearChoiceProcessing

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure CompareQuarterChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	CompareQuarter = pItem.ChoiceList.FindByValue(pSelectedValue).Value;
	If pSelectedValue <> "0" Then
		If CompareYear = "-//-" Then
			vCompareYear = Format(Year(CurrentDate()), "ND=4; NFD=0; NG=");
			If StrLen(vCompareYear) > 4 Then
				CompareYear = StrReplace(vCompareYear, Mid(vCompareYear, 2, 1), "");
			Else
				CompareYear = vCompareYear;
			EndIf;
		EndIf;
		CompareCompositionDate = Date(Number(CompareYear), Number(pSelectedValue)*3, 1,1,1,1);
		CompareQuarterOnChange(pItem);
	Else
		Items.ColumnSecondDateIndexPresentation.Visible = False;
		Items.ColumnIcon.Visible = False;
		ChartBuild(False);
	EndIf;
EndProcedure // CompareQuarterChoiceProcessing

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure CompareMonthChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	CompareMonth = pItem.ChoiceList.FindByValue(pSelectedValue).Value;
	If pSelectedValue <> "0" Then
		CompareMonthNumber = pSelectedValue;
		If CompareYear = "-//-" Then
			vCompareYear = Format(Year(CurrentDate()), "ND=4; NFD=0; NG=");
			If StrLen(vCompareYear) > 4 Then
				CompareYear = StrReplace(vCompareYear, Mid(vCompareYear, 2, 1), "");
			Else
				CompareYear = vCompareYear;
			EndIf;
		EndIf;
		CompareCompositionDate = Date(Number(CompareYear), Number(pSelectedValue), 1,1,1,1);
		CompareMonthOnChange(pItem);
	Else
		Items.ColumnSecondDateIndexPresentation.Visible = False;
		Items.ColumnIcon.Visible = False;
		ChartBuild(False);
	EndIf;
EndProcedure // CompareMonthChoiceProcessing

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure CompareYearOnChange(pItem)
	ChartBuild(False);
	If Number(CompareYear) < 1950 Then
		CompareYear = "1950";
	EndIf;
	CompareCompositionDate = Date(Number(CompareYear), Month(CompareCompositionDate), 1,1,1,1);
	// Fill indexes for second date
	If Items.SelMonth.Visible Then
		If CompareMonth <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") And CompareYear <> "-//-" Then
			GetCompareRooms();
			Items.ColumnSecondDateIndexPresentation.Visible = True;
			Items.ColumnIcon.Visible = True;
			Items.ColumnSecondDateIndexPresentation.Title = Items.CompareMonth.ChoiceList.FindByValue(TrimAll(CompareMonth)).Presentation + " " + CompareYear;
			ChartBuild(True);
		Else
			Items.ColumnSecondDateIndexPresentation.Visible = False;
			Items.ColumnIcon.Visible = False;
		EndIf;
	ElsIf Items.SelQuarter.Visible Then
		If CompareQuarter <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") And CompareYear <> "-//-" Then
			GetCompareRooms();
			Items.ColumnSecondDateIndexPresentation.Visible = True;
			Items.ColumnIcon.Visible = True;
			Items.ColumnSecondDateIndexPresentation.Title = Items.CompareQuarter.ChoiceList.FindByValue(TrimAll(CompareQuarter)).Presentation + " " + CompareYear;
			ChartBuild(True);
		Else
			Items.ColumnSecondDateIndexPresentation.Visible = False;
			Items.ColumnIcon.Visible = False;
		EndIf;
	Else
		If CompareYear <> "-//-" Then
			GetCompareRooms();
			Items.ColumnSecondDateIndexPresentation.Visible = True;
			Items.ColumnIcon.Visible = True;
			Items.ColumnSecondDateIndexPresentation.Title = CompareYear;
			ChartBuild(True);
		Else
			Items.ColumnSecondDateIndexPresentation.Visible = False;
			Items.ColumnIcon.Visible = False;
		EndIf;
	EndIf;
EndProcedure // CompareYearOnChange

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure CompareMonthOnChange(pItem)
	ChartBuild(False);
	If Not ValueIsFilled(CompareYear) Then
		CompareYear = Format(Year(CurrentDate()), "ND=4; NFD=0; NG=");
	EndIf;
	CompareCompositionDate = Date(Number(CompareYear), Number(CompareMonthNumber), 1,1,1,1);
	If CompareMonth <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") And CompareYear <> "-//-" Then
		GetCompareRooms();
		Items.ColumnSecondDateIndexPresentation.Visible = True;
		Items.ColumnIcon.Visible = True;
		Items.ColumnSecondDateIndexPresentation.Title = Items.CompareMonth.ChoiceList.FindByValue(TrimAll(CompareMonth)).Presentation + " " + CompareYear;
		ChartBuild(True);
	Else
		Items.ColumnSecondDateIndexPresentation.Visible = False;
		Items.ColumnIcon.Visible = False;
	EndIf;
EndProcedure // CompareMonthOnChange

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure CompareQuarterOnChange(pItem)
	ChartBuild(False);
	If Not ValueIsFilled(CompareYear) Then
		CompareYear = Format(Year(CurrentDate()), "ND=4; NFD=0; NG=");
	EndIf;
	If CompareQuarter <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") And CompareYear <> "-//-" Then
		GetCompareRooms();
		Items.ColumnSecondDateIndexPresentation.Visible = True;
		Items.ColumnIcon.Visible = True;
		Items.ColumnSecondDateIndexPresentation.Title = Items.CompareQuarter.ChoiceList.FindByValue(TrimAll(CompareQuarter)).Presentation + " " + CompareYear;
		ChartBuild(True);
	Else
		Items.ColumnSecondDateIndexPresentation.Visible = False;
		Items.ColumnIcon.Visible = False;
	EndIf;
EndProcedure // CompareQuarterOnChange

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // HotelClearing

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure HotelOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // HotelOpening

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure PeriodToOnChange(Item)
	// Set column title
	Items.ColumnIndexPresentation.Title = Format(PeriodTo, "DLF=D");
	
	CompositionDate = PeriodTo;
	
	// Rebuild charts and tables
	vDoCompareColumn = False;
	If ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("0").Value Then
		If ValueIsFilled(CompareDate) Then
			vDoCompareColumn = True;
		EndIf;
	ElsIf ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("1").Value Then
		If ValueIsFilled(CompareYear) And CompareYear <> "-//-" And CompareMonth <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") Then
			vDoCompareColumn = True;
		EndIf;
	ElsIf ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("2").Value Then
		If ValueIsFilled(CompareYear) And CompareYear <> "-//-" And CompareQuarter <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") Then
			vDoCompareColumn = True;
		EndIf;
	Else 
		If ValueIsFilled(CompareYear) And CompareYear <> "-//-" Then
			vDoCompareColumn = True;
		EndIf;
	EndIf;
	ChartBuild(False);
	If vDoCompareColumn Then
		GetCompareRooms();
		ChartBuild(True);
	Else
		GetRooms();
	EndIf;
	
	// Set columns visibility
	If ValueIsFilled(CompareDate) Then
		Items.ColumnSecondDateIndexPresentation.Visible = True;
		Items.ColumnIcon.Visible = True;
	Else
		Items.ColumnSecondDateIndexPresentation.Visible = False;
		Items.ColumnIcon.Visible = False;
	EndIf;
EndProcedure // PeriodToOnChange

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(Item)
	// Rebuild charts and tables
	vDoCompareColumn = False;
	If ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("0").Value Then
		If ValueIsFilled(CompareDate) Then
			vDoCompareColumn = True;
		EndIf;
	ElsIf ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("1").Value Then
		If ValueIsFilled(CompareYear) And CompareYear <> "-//-" And CompareMonth <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") Then
			vDoCompareColumn = True;
		EndIf;
	ElsIf ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("2").Value Then
		If ValueIsFilled(CompareYear) And CompareYear <> "-//-" And CompareQuarter <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") Then
			vDoCompareColumn = True;
		EndIf;
	Else 
		If ValueIsFilled(CompareYear) And CompareYear <> "-//-" Then
			vDoCompareColumn = True;
		EndIf;
	EndIf;
	ChartBuild(False);
	If vDoCompareColumn Then
		GetCompareRooms();
		ChartBuild(True);
	Else
		GetRooms();
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
EndProcedure // HotelOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowFiletGroup(pCommand)
	Items.TabulationGroup.Visible = Not Items.TabulationGroup.Visible; 
	Items.FormButtonShowFiletGroup.Check = Items.TabulationGroup.Visible;
 EndProcedure // ShowFiletGroup

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandRefresh(pCommand)
	// Rebuild charts and tables
	vDoCompareColumn = False;
	If ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("0").Value Then
		If ValueIsFilled(CompareDate) Then
			vDoCompareColumn = True;
		EndIf;
	ElsIf ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("1").Value Then
		If ValueIsFilled(CompareYear) And CompareYear <> "-//-" And CompareMonth <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") Then
			vDoCompareColumn = True;
		EndIf;
	ElsIf ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("2").Value Then
		If ValueIsFilled(CompareYear) And CompareYear <> "-//-" And CompareQuarter <> NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'") Then
			vDoCompareColumn = True;
		EndIf;
	Else 
		If ValueIsFilled(CompareYear) And CompareYear <> "-//-" Then
			vDoCompareColumn = True;
		EndIf;
	EndIf;
	ChartBuild(False);
	If vDoCompareColumn Then
		GetCompareRooms();
		ChartBuild(True);
	Else
		GetRooms();
	EndIf;
EndProcedure // CommandRefresh

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandGenerateReports(Command)
	// Open report form
	GetReport();
EndProcedure // CommandGenerateReports

#EndRegion

#Region Private

// -------------------------------------------------------------------------------------------------
&AtServer
Procedure GetQResultTableTotals(pPeriod, pTbl, pTemplate, pResources, pConvertToTurnover = True)
	// Convert pTbl to the value table if necessary
	vTbl = pTbl;
	If TypeOf(pTbl) = Type("Array") Then                 
		vTbl = pTemplate.CopyColumns();
		For Each vRow In pTbl Do
			vTblRow = vTbl.Add();
			FillPropertyValues(vTblRow, vRow);
		EndDo;
	EndIf;
	
	If vTbl.Count() = 0 Then
		vTbl.Add();
	EndIf;
	
	vTbl.GroupBy(, pResources);
	TotalPerDay = vTbl.Get(0);
EndProcedure // GetQResultTableTotals

// -------------------------------------------------------------------------------------------------
&AtServer
Procedure GetHotelAndPeriod()
	Hotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
		PeriodTo = Hotel.AccountingDate;
	Else
		PeriodTo = CurrentSessionDate();
	EndIf;
	ChartPeriod = PeriodTo;
	ChoosePeriod = TrimAll(Items.ChoosePeriod.ChoiceList.FindByValue("0").Value);
	SelYear = Format(Year(PeriodTo), "ND=4; NFD=0; NG=");
	CompareYear = Format(Year(PeriodTo), "ND=4; NFD=0; NG=");
	Items.SelYear.ChoiceList.Add("-//-", "-//-");
	Items.CompareYear.ChoiceList.Add("-//-", "-//-");
	For vInd = -1 To 9 Do
		Items.SelYear.ChoiceList.Add(Format(Year(PeriodTo)-vInd, "ND=4; NFD=0; NG="), Format(Year(PeriodTo)-vInd, "ND=4; NFD=0; NG="));
		Items.CompareYear.ChoiceList.Add(Format(Year(PeriodTo)-vInd, "ND=4; NFD=0; NG="), Format(Year(PeriodTo)-vInd, "ND=4; NFD=0; NG="));
	EndDo;
	vQuarterNumber = String(Int(Month(EndOfQuarter(PeriodTo))/3));
	SelQuarter = Items.SelQuarter.ChoiceList.FindByValue(vQuarterNumber).Value;
	CompareQuarter = NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'");
	SelMonth = Items.SelMonth.ChoiceList.FindByValue(String(Month(PeriodTo))).Value;
	CompareMonth = NStr("en='-Not selected-';ru='-Не выбран-';de='-Nicht ausgewählt-'");
	MonthNumber = String(Month(PeriodTo));
	CompareMonthNumber = String(Month(PeriodTo));
	CompositionDate = PeriodTo;
EndProcedure // GetHotelAndPeriod

// -------------------------------------------------------------------------------------------------
&AtServer
Procedure GetRooms()
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	
	// Clear pages
	If IndexesTable.Count() > 0 Then
		IndexesTable.Clear();
	EndIf;
	
	// Check period choosen
	If Items.PeriodDay.Visible Then
		vBegOfPeriod = BegOfDay(PeriodTo);
		vEndOfPeriod = EndOfDay(PeriodTo);
	ElsIf Items.SelQuarter.Visible Then
		vBegOfPeriod = BegOfQuarter(CompositionDate);
		vEndOfPeriod = EndOfQuarter(CompositionDate);
	ElsIf Items.SelMonth.Visible Then
		vBegOfPeriod = BegOfMonth(CompositionDate);
		vEndOfPeriod = EndOfMonth(CompositionDate);
	Else
		vBegOfPeriod = BegOfYear(CompositionDate);
		vEndOfPeriod = EndOfYear(CompositionDate);
	EndIf;
	// Initialize typesof data to show
	vInRooms = True;
	vWithVAT = True;
	If ValueIsFilled(Hotel) Then
		vInRooms = Not Hotel.ShowReportsInBeds;
		vWithVAT = Hotel.ShowSalesInReportsWithVAT;
	EndIf;
	
	// Initialize reporting currency
	vReportingCurrency = Hotel.ReportingCurrency;
	If Not ValueIsFilled(Hotel) Then
		Return;
	EndIf;
	
	// Add header
	vNewStr = IndexesTable.Add();
	vNewStr.IndexPicture = PictureLib.Rooms;
	vNewStr.IndexName = NStr("en='ROOMS OCCUPATION';ru='СТАТИСТИКА ПО ЗАГРУЗКЕ';de='STATISTIK NACH AUSLASTUNG'");
	vNewStr.IndexKey = vNewStr.IndexName;
	
	// Run query to get total number of rooms, rooms blocked, vacant number of rooms
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalanceAndTurnovers.Period AS Period,
	|	SUM(RoomInventoryBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRoomsClosingBalance,
	|	SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBedsClosingBalance,
	|	-SUM(RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlockedClosingBalance,
	|	-SUM(RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlockedClosingBalance
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalanceAndTurnovers
	|GROUP BY
	|	RoomInventoryBalanceAndTurnovers.Period
	|ORDER BY
	|	Period";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	vResources = "TotalRoomsClosingBalance, TotalBedsClosingBalance, RoomsBlockedClosingBalance, BedsBlockedClosingBalance";
	GetQResultTableTotals(PeriodTo, vQryResult, vQryResult, vResources);
	vTotalRooms = cmCastToNumber(TotalPerDay.TotalRoomsClosingBalance);
	vTotalBeds = cmCastToNumber(TotalPerDay.TotalBedsClosingBalance);
	
	If vInRooms then
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Total Rooms';ru='Всего номеров';de='Gesamt Zimmer'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vTotalRooms;
		vNewStr.IndexPresentation = vTotalRooms;
	Else
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Total Beds';ru='Всего мест';de='Gesamt Betten'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vTotalBeds;
		vNewStr.IndexPresentation = vTotalBeds;
	EndIf;
	
	vBlockedRooms = cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);
	vBlockedBeds = cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
	vRoomsForSale = vTotalRooms - vBlockedRooms;
	vBedsForSale = vTotalBeds - vBlockedBeds;
	
	// Run query to get number of blocked rooms per room block types
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomBlocksBalanceAndTurnovers.RoomBlockType AS RoomBlockType,
	|	RoomBlocksBalanceAndTurnovers.Period AS Period,
	|	SUM(RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlockedClosingBalance,
	|	SUM(RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlockedClosingBalance
	|FROM
	|	AccumulationRegister.RoomBlocks.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS RoomBlocksBalanceAndTurnovers
	|
	|GROUP BY
	|	RoomBlocksBalanceAndTurnovers.RoomBlockType,
	|	RoomBlocksBalanceAndTurnovers.Period
	|
	|ORDER BY
	|	RoomBlocksBalanceAndTurnovers.RoomBlockType.SortCode,
	|	Period";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// Get list of room block types
	vSpecRoomsBlocked = 0;
	vSpecBedsBlocked = 0;
	vRoomBlockTypes = vQryResult.Copy();
	vRoomBlockTypes.GroupBy("RoomBlockType", );
	If vQryResult.Count()>0 Then
		
		// Put room blocks per room block type
		For Each vRow In vRoomBlockTypes Do
			vRoomBlockType = vRow.RoomBlockType;
			
			// Get records for the current room block type only
			vQrySubresult = vQryResult.FindRows(New Structure("RoomBlockType", vRoomBlockType));
			GetQResultTableTotals(PeriodTo, vQrySubresult, vQryResult, "RoomsBlockedClosingBalance, BedsBlockedClosingBalance");
			
			If vInRooms Then
				vBlockedRooms = cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);		
				
				vNewStr = IndexesTable.Add();
				vNewStr.IndexName = Tabulation + vRoomBlockType;
				vNewStr.IndexKey = vRoomBlockType;
				vNewStr.IndexValue = vBlockedRooms;
				vNewStr.IndexPresentation = vBlockedRooms;
				
				If vRoomBlockType.AddToRoomsRentedInSummaryIndexes Then
					vSpecRoomsBlocked = vSpecRoomsBlocked + cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);
				EndIf;
			Else
				vBlockedBeds = cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
				
				vNewStr = IndexesTable.Add();
				vNewStr.IndexName = Tabulation + vRoomBlockType;
				vNewStr.IndexKey = vRoomBlockType;
				vNewStr.IndexValue = vBlockedBeds;
				vNewStr.IndexPresentation = vBlockedBeds;
				
				If vRoomBlockType.AddToRoomsRentedInSummaryIndexes Then
					vSpecBedsBlocked = vSpecBedsBlocked + cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
				EndIf;
			EndIf;
		EndDo;
	Else 
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Repaired';ru='Ремонт';de='Reparatur'");
		vNewStr.IndexKey = NStr("en='Repaired';ru='Ремонт';de='Reparatur'");
		vNewStr.IndexValue = 0;
		vNewStr.IndexPresentation = 0;
	EndIf;
	
	// Put rooms for sale
	If vInRooms Then
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Rooms For Sale';ru='Номеров к продаже';de='Zimmer im Verkauf'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vRoomsForSale + vSpecRoomsBlocked;
		vNewStr.IndexPresentation = vRoomsForSale + vSpecRoomsBlocked;
	Else
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Beds For Sale';ru='Мест к продаже';de='Betten für den Verkauf'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vBedsForSale + vSpecBedsBlocked;
		vNewStr.IndexPresentation = vBedsForSale + vSpecBedsBlocked;
	EndIf;
	
	// Run query to get room sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.Period AS Period,
	|	RoomSalesTurnovers.RoomRate.IsComplimentary AS RoomRateIsComplimentary,
	|	RoomSalesTurnovers.RoomRate.IsHouseUse AS RoomRateIsHouseUse,
	|	SUM(RoomSalesTurnovers.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSalesTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSalesTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSalesTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesTurnovers.BedsRentedTurnover) AS BedsRentedTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel) AND NOT IsCorrection) AS RoomSalesTurnovers
	|GROUP BY
	|	RoomSalesTurnovers.Period,
	|	RoomSalesTurnovers.RoomRate.IsComplimentary,
	|	RoomSalesTurnovers.RoomRate.IsHouseUse
	|ORDER BY
	|	Period,
	|	RoomRateIsComplimentary,
	|	RoomRateIsHouseUse";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// Add forecast sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesForecastTurnovers.Period AS Period,
	|	RoomSalesForecastTurnovers.RoomRate.IsComplimentary AS RoomRateIsComplimentary,
	|	RoomSalesForecastTurnovers.RoomRate.IsHouseUse AS RoomRateIsHouseUse,
	|	SUM(RoomSalesForecastTurnovers.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSalesForecastTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSalesForecastTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSalesForecastTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSalesForecastTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesForecastTurnovers.BedsRentedTurnover) AS BedsRentedTurnover
	|FROM
	|	AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, Day, &qUseForecast AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesForecastTurnovers
	|GROUP BY
	|	RoomSalesForecastTurnovers.Period,
	|	RoomSalesForecastTurnovers.RoomRate.IsComplimentary,
	|	RoomSalesForecastTurnovers.RoomRate.IsHouseUse
	|ORDER BY
	|	Period,
	|	RoomRateIsComplimentary,
	|	RoomRateIsHouseUse";
	vQry.SetParameter("qPeriodFrom", Max(vForecastStartDate, vBegOfPeriod));
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qUseForecast", ?(vForecastStartDate > vEndOfPeriod, False, True));
	vQry.SetParameter("qHotel", Hotel);
	vForecastQryResult = vQry.Execute().Unload();
	
	// Merge forecast sales with real ones
	For Each vForecastRow In vForecastQryResult Do
		vFound = False;
		For Each vRow In vQryResult Do
			If vRow.Period = vForecastRow.Period And
				vRow.RoomRateIsComplimentary = vForecastRow.RoomRateIsComplimentary And
				vRow.RoomRateIsHouseUse = vForecastRow.RoomRateIsHouseUse Then
				vFound = True;
				Break;
			EndIf;
		EndDo;
		If Not vFound Then
			vRow = vQryResult.Add();
			vRow.Period = vForecastRow.Period;
			vRow.RoomRateIsComplimentary = vForecastRow.RoomRateIsComplimentary;
			vRow.RoomRateIsHouseUse = vForecastRow.RoomRateIsHouseUse;
			vRow.SalesTurnover = 0;
			vRow.SalesWithoutVATTurnover = 0;
			vRow.RoomRevenueTurnover = 0;
			vRow.RoomRevenueWithoutVATTurnover = 0;
			vRow.RoomsRentedTurnover = 0;
			vRow.BedsRentedTurnover = 0;
		EndIf;
		vRow.SalesTurnover = vRow.SalesTurnover + vForecastRow.SalesTurnover;
		vRow.SalesWithoutVATTurnover = vRow.SalesWithoutVATTurnover + vForecastRow.SalesWithoutVATTurnover;
		vRow.RoomRevenueTurnover = vRow.RoomRevenueTurnover + vForecastRow.RoomRevenueTurnover;
		vRow.RoomRevenueWithoutVATTurnover = vRow.RoomRevenueWithoutVATTurnover + vForecastRow.RoomRevenueWithoutVATTurnover;
		vRow.RoomsRentedTurnover = vRow.RoomsRentedTurnover + vForecastRow.RoomsRentedTurnover;
		vRow.BedsRentedTurnover = vRow.BedsRentedTurnover + vForecastRow.BedsRentedTurnover;
	EndDo;
	
	vResources = "SalesTurnover, SalesWithoutVATTurnover, RoomRevenueTurnover, RoomRevenueWithoutVATTurnover, RoomsRentedTurnover, BedsRentedTurnover";
	
	// Get complimentary only
	vQryResultComplArray = vQryResult.Copy().FindRows(New Structure("RoomRateIsComplimentary", True));
	vQryResultCompl = vQryResult.CopyColumns();
	For Each vRow In vQryResultComplArray Do
		vTabRow = vQryResultCompl.Add();
		FillPropertyValues(vTabRow, vRow);
	EndDo;
	vQryResultCompl.GroupBy("Period", vResources);
	
	// Put complimentary rooms rented
	GetQResultTableTotals(PeriodTo, vQryResultCompl, vQryResultCompl, vResources, False);
	If vInRooms Then
		vRoomsRentedComp = cmCastToNumber(TotalPerDay.RoomsRentedTurnover);
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Complimentary rooms';ru='Бесплатных номеров';de='Gratis Zimmer'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vRoomsRentedComp;
		vNewStr.IndexPresentation = Round(vRoomsRentedComp);
	Else
		vBedsRentedComp = cmCastToNumber(TotalPerDay.BedsRentedTurnover);
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Complimentary beds';ru='Бесплатных мест';de='Gratis Betten'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vBedsRentedComp;
		vNewStr.IndexPresentation = Round(vBedsRentedComp);
	EndIf;
	
	// Get house use only
	vQryResultHUArray = vQryResult.Copy().FindRows(New Structure("RoomRateIsHouseUse", True));
	vQryResultHU = vQryResult.CopyColumns();
	For Each vRow In vQryResultHUArray Do
		vTabRow = vQryResultHU.Add();
		FillPropertyValues(vTabRow, vRow);
	EndDo;
	vQryResultHU.GroupBy("Period", vResources);
	
	// Put house use rooms rented
	GetQResultTableTotals(PeriodTo, vQryResultHU, vQryResultHU, vResources, False);
	If vInRooms Then
		vRoomsRentedHU = cmCastToNumber(TotalPerDay.RoomsRentedTurnover);
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='House Use rooms';ru='Номеров для внутреннего использования';de='Hausgebrauch Zimmer'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vRoomsRentedHU;
		vNewStr.IndexPresentation = Round(vRoomsRentedHU);
	Else
		vBedsRentedHU = cmCastToNumber(TotalPerDay.BedsRentedTurnover);
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='House Use beds';ru='Мест для внутреннего использования';de='Hausgebrauch Betten'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vBedsRentedHU;
		vNewStr.IndexPresentation = Round(vBedsRentedHU);
	EndIf;
	
	// Put rooms rented
	vQryResult.GroupBy("Period, RoomRateIsComplimentary, RoomRateIsHouseUse", vResources);
	vQryResult.Sort("Period, RoomRateIsComplimentary, RoomRateIsHouseUse");
	GetQResultTableTotals(PeriodTo, vQryResult, vQryResult, vResources, False);
	If vInRooms Then
		vRoomsRented = cmCastToNumber(TotalPerDay.RoomsRentedTurnover);
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Rooms Rented';ru='Продано номеров';de='Verkaufte Zimmer'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vRoomsRented;
		vNewStr.IndexPresentation = Round(vRoomsRented);
	Else
		vBedsRented = cmCastToNumber(TotalPerDay.BedsRentedTurnover);
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Beds Rented';ru='Продано мест';de='Verkaufte Betten'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vBedsRented;
		vNewStr.IndexPresentation = Round(vBedsRented);
	EndIf;
	
	// Save total sale amounts
	If vWithVAT Then
		vRoomsIncome = cmCastToNumber(TotalPerDay.RoomRevenueTurnover);		
		vTotalIncome = cmCastToNumber(TotalPerDay.SalesTurnover);
	Else
		vRoomsIncome = cmCastToNumber(TotalPerDay.RoomRevenueWithoutVATTurnover);		
		vTotalIncome = cmCastToNumber(TotalPerDay.SalesWithoutVATTurnover);
	EndIf;
	vOtherIncome = vTotalIncome - vRoomsIncome;
	
	// Put occupation percents	
	If vInRooms Then
		vOccupationRooms = Round(?((vRoomsForSale + vSpecRoomsBlocked) <> 0, 100*(vRoomsRented + vSpecRoomsBlocked)/(vRoomsForSale + vSpecRoomsBlocked), 0), 2);
		
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("ru = '% Загрузки по проданным номерам'; en = 'Occupation % by rooms rented'; de = 'Occupation % by rooms rented'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vOccupationRooms;
		vNewStr.IndexPresentation = String(vOccupationRooms)+"%";
		
		vAvgRoomPrice = Round(?(vRoomsRented <> 0, vRoomsIncome/vRoomsRented, 0), 2);
		vAvgRoomPriceInclAddSrv = Round(?(vRoomsRented <> 0, vTotalIncome/vRoomsRented, 0), 2);
		vAvgRoomIncome = Round(?((vRoomsForSale + vSpecRoomsBlocked) <> 0, vRoomsIncome/(vRoomsForSale + vSpecRoomsBlocked), 0), 2);
		
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Average room price';ru='Средняя цена номера';de='Durchschnittspreis eines Zimmers'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vAvgRoomPrice;
		vNewStr.IndexPresentation = ?(vAvgRoomPrice = 0, vAvgRoomPrice, cmFormatSum(vAvgRoomPrice, vReportingCurrency));			
		
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Avg. price incl. add. services';ru='Ср. цена с доп. услугами';de='Durchschnittspreis mit zusätzlichen Dienstleistungen'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vAvgRoomPriceInclAddSrv;
		vNewStr.IndexPresentation = ?(vAvgRoomPriceInclAddSrv = 0, vAvgRoomPriceInclAddSrv, cmFormatSum(vAvgRoomPriceInclAddSrv, vReportingCurrency));
		
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Revenue per available room';ru='Средняя доходность номера';de='Durchschnittliche Rentabilität des Zimmers'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vAvgRoomIncome;
		vNewStr.IndexPresentation = ?(vAvgRoomIncome = 0, vAvgRoomIncome, cmFormatSum(vAvgRoomIncome, vReportingCurrency));
	Else
		vOccupationBeds = Round(?((vBedsForSale + vSpecBedsBlocked) <> 0, 100*(vBedsRented + vSpecBedsBlocked)/(vBedsForSale + vSpecBedsBlocked), 0), 2);
		
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("ru = '% Загрузки по проданным местам'; en = 'Occupation % by beds rented'; de = 'Occupation % by beds rented'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vOccupationBeds;
		vNewStr.IndexPresentation = String(vOccupationBeds)+"%";		
		
		vAvgBedPrice = Round(?(vBedsRented <> 0, vRoomsIncome/vBedsRented, 0), 2);	
		vAvgBedPriceInclAddSrv = Round(?(vBedsRented <> 0, vTotalIncome/vBedsRented, 0), 2);		
		vAvgBedIncome = Round(?((vBedsForSale + vSpecBedsBlocked) <> 0, vRoomsIncome/(vBedsForSale + vSpecBedsBlocked), 0), 2);	
		
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Average bed price';ru='Средняя цена места';de='Durchschnittspreis eines Platzes'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vAvgBedPrice;
		vNewStr.IndexPresentation = ?(vAvgBedPrice = 0, vAvgBedPrice, cmFormatSum(vAvgBedPrice, vReportingCurrency));
		
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Avg. price incl. add. services';ru='Ср. цена с доп. услугами';de='Durchschnittspreis mit zusätzlichen Dienstleistungen'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vAvgBedPriceInclAddSrv;
		vNewStr.IndexPresentation = ?(vAvgBedPriceInclAddSrv = 0, vAvgBedPriceInclAddSrv, cmFormatSum(vAvgBedPriceInclAddSrv, vReportingCurrency));
		
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='Revenue per available bed';ru='Средняя доходность места';de='Durchschnittliche Rentabilität des Platzes'");
		vNewStr.IndexKey = vNewStr.IndexName;
		vNewStr.IndexValue = vAvgBedIncome;
		vNewStr.IndexPresentation = ?(vAvgBedIncome = 0, vAvgBedIncome, cmFormatSum(vAvgBedIncome, vReportingCurrency));
	EndIf;
	
	// 2. Guests summary indexes
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexPicture = PictureLib.Clients;
	vNewStr.IndexName = NStr("en='GUESTS SUMMARY INDEXES';ru='СТАТИСТИКА ПО ГОСТЯМ';de='STATISTIK NACH GÄSTEN'");
	vNewStr.IndexKey = vNewStr.IndexName;
	
	// Run query to get number of guest days
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.Period AS Period,
	|	RoomSalesTurnovers.ClientType AS ClientType,
	|	SUM(RoomSalesTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(RoomSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel) AND NOT IsCorrection) AS RoomSalesTurnovers
	|GROUP BY
	|	RoomSalesTurnovers.Period,
	|	RoomSalesTurnovers.ClientType
	|ORDER BY
	|	Period,
	|	ClientType";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// Add forecast guests if period is set in the future
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesForecastTurnovers.Period AS Period,
	|	RoomSalesForecastTurnovers.ClientType AS ClientType,
	|	SUM(RoomSalesForecastTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(RoomSalesForecastTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, Day, &qUseForecast AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesForecastTurnovers
	|GROUP BY
	|	RoomSalesForecastTurnovers.Period,
	|	RoomSalesForecastTurnovers.ClientType
	|ORDER BY
	|	Period,
	|	ClientType";
	vQry.SetParameter("qPeriodFrom", Max(vForecastStartDate, vBegOfPeriod));
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qUseForecast", ?(vForecastStartDate > vEndOfPeriod, False, True));
	vQry.SetParameter("qHotel", Hotel);
	vForecastQryResult = vQry.Execute().Unload();
	
	// Merge forecast guests with real ones
	For Each vForecastRow In vForecastQryResult Do
		vFound = False;
		For Each vRow In vQryResult Do
			If vRow.Period = vForecastRow.Period And
				vRow.ClientType = vForecastRow.ClientType Then
				vFound = True;
				Break;
			EndIf;
		EndDo;
		If Not vFound Then
			vRow = vQryResult.Add();
			vRow.Period = vForecastRow.Period;
			vRow.ClientType = vForecastRow.ClientType;
			vRow.GuestDaysTurnover = 0;
			vRow.GuestsCheckedInTurnover = 0;
		EndIf;
		vRow.GuestDaysTurnover = vRow.GuestDaysTurnover + vForecastRow.GuestDaysTurnover;
		vRow.GuestsCheckedInTurnover = vRow.GuestsCheckedInTurnover + vForecastRow.GuestsCheckedInTurnover;
	EndDo;
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexName = Tabulation + NStr("en='Guest days';ru='Человеко-дни';de='Personentage'");
	vNewStr.IndexKey = vNewStr.IndexName;
	
	// Put client types
	vClientTypes = vQryResult.Copy();
	vClientTypes.GroupBy("ClientType", );
	vTotalCheckedInGuests = 0;
	vTotalGuests = 0;
	ExpTotalGuests = 0;
	MoreThanOneRecord = False;
	For Each vRow In vClientTypes Do
		vClientType = vRow.ClientType;
		
		// Get records for the current client type only
		vQrySubresult = vQryResult.FindRows(New Structure("ClientType", vClientType));
		GetQResultTableTotals(PeriodTo, vQrySubresult, vQryResult, "GuestDaysTurnover, GuestsCheckedInTurnover", False);
		vGuests = cmCastToNumber(TotalPerDay.GuestDaysTurnover);
		vTotalCheckedInGuests = vTotalCheckedInGuests + cmCastToNumber(TotalPerDay.GuestsCheckedInTurnover);
		vTotalGuests = vTotalGuests + cmCastToNumber(TotalPerDay.GuestDaysTurnover);
		
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + "   " + vClientType;
		vNewStr.IndexKey = vClientType;
		vNewStr.IndexValue = vGuests;
		vNewStr.IndexPresentation = Round(vGuests);
		vNewStr.SecondDateIndexValue = 0;
		vNewStr.SecondDateIndexPresentation = 0;
	EndDo;
	ExpTotalGuests = Round(vTotalGuests);
	// Put client type totals
	If vClientTypes.Count() > 1 Then
		MoreThanOneRecord = True;
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation + NStr("en='TOTAL';ru='ВСЕГО';de='GESAMT'");
		vNewStr.IndexKey = NStr("en='Total guest days';ru='Всего человеко-дней';de='Gesamt Manntage'");
		vNewStr.IndexValue = vTotalGuests;
		vNewStr.IndexPresentation = Round(vTotalGuests);
	EndIf;
	
	// Put guests statistics
	If vInRooms Then
		vAvgNumberOfGuests = Round(?(vRoomsRented <> 0, vTotalGuests/vRoomsRented, 0), 2);
	Else
		vAvgNumberOfGuests = Round(?(vBedsRented <> 0, vTotalGuests/vBedsRented, 0), 2);
	EndIf;
	vAvgGuestLengthOfStay = Round(?(vTotalCheckedInGuests <> 0, vTotalGuests/vTotalCheckedInGuests, 0), 2);
	vAvgGuestPrice = Round(?(vTotalGuests <> 0, vRoomsIncome/vTotalGuests, 0), 2);
	vAvgGuestIncome = Round(?(vTotalGuests <> 0, vTotalIncome/vTotalGuests, 0), 2);
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexName = Tabulation + NStr("en='Average number of guests per room';ru='Среднее число гостей в номере';de='Durchschnittliche Gästezahl im Zimmer'");
	vNewStr.IndexKey = vNewStr.IndexName;
	vNewStr.IndexValue = vAvgNumberOfGuests;
	vNewStr.IndexPresentation = vAvgNumberOfGuests;
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexName = Tabulation + NStr("en='Average guest length of stay in days';ru='Средняя прод. прож. в днях';de='Durchschnittliche Aufenthaltsdauer in Tagen'");
	vNewStr.IndexKey = vNewStr.IndexName;
	vNewStr.IndexValue = vAvgGuestLengthOfStay;
	vNewStr.IndexPresentation = vAvgGuestLengthOfStay;
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexName = Tabulation + NStr("en='Average guest price';ru='Средняя цена на гостя';de='Durchschnittspreis pro Gast'");
	vNewStr.IndexKey = vNewStr.IndexName;
	vNewStr.IndexValue = vAvgGuestPrice;
	vNewStr.IndexPresentation = ?(vAvgGuestPrice = 0, vAvgGuestPrice, cmFormatSum(vAvgGuestPrice, vReportingCurrency));
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexName = Tabulation + NStr("en='Average guest income';ru='Средний доход с гостя';de='Durchschnittliche Einnahmen pro Gast'");
	vNewStr.IndexKey = vNewStr.IndexName;
	vNewStr.IndexValue = vAvgGuestIncome;
	vNewStr.IndexPresentation = ?(vAvgGuestIncome = 0, vAvgGuestIncome, cmFormatSum(vAvgGuestIncome, vReportingCurrency));
	
	// 3. Check-in summary indexes
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexPicture = PictureLib.Empty;
	vNewStr.IndexName = NStr("en='CHECK-IN SUMMARY INDEXES';ru='СТАТИСТИКА ПО ЗАЕЗДУ';de='STATISTIK NACH ANREISE'");
	vNewStr.IndexKey = vNewStr.IndexName;
	// Run query to get number of checked-in guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.Period AS Period,
	|	RoomSalesTurnovers.ParentDoc.IsByReservation AS ParentDocIsByReservation,
	|	SUM(RoomSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel) AND NOT IsCorrection) AS RoomSalesTurnovers
	|GROUP BY
	|	RoomSalesTurnovers.Period,
	|	RoomSalesTurnovers.ParentDoc.IsByReservation
	|ORDER BY
	|	Period,
	|	ParentDocIsByReservation";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// Add forecast guests if period is set in the future
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesForecastTurnovers.Period AS Period,
	|	TRUE AS ParentDocIsByReservation,
	|	SUM(RoomSalesForecastTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, Day, &qUseForecast AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesForecastTurnovers
	|GROUP BY
	|	RoomSalesForecastTurnovers.Period
	|ORDER BY
	|	Period,
	|	ParentDocIsByReservation";
	vQry.SetParameter("qPeriodFrom", Max(vForecastStartDate, vBegOfPeriod));
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qUseForecast", ?(vForecastStartDate > vEndOfPeriod, False, True));
	vQry.SetParameter("qHotel", Hotel);
	vForecastQryResult = vQry.Execute().Unload();
	
	// Merge forecast guests with real ones
	For Each vForecastRow In vForecastQryResult Do
		vFound = False;
		For Each vRow In vQryResult Do
			If vRow.Period = vForecastRow.Period And
				vRow.ParentDocIsByReservation = vForecastRow.ParentDocIsByReservation Then
				vFound = True;
				Break;
			EndIf;
		EndDo;
		If Not vFound Then
			vRow = vQryResult.Add();
			vRow.Period = vForecastRow.Period;
			vRow.ParentDocIsByReservation = vForecastRow.ParentDocIsByReservation;
			vRow.GuestsCheckedInTurnover = 0;
		EndIf;
		vRow.GuestsCheckedInTurnover = vRow.GuestsCheckedInTurnover + vForecastRow.GuestsCheckedInTurnover;
	EndDo;
	
	// Split table to walk-in and check-in by reservation
	vQryResultWalkInArray = vQryResult.Copy().FindRows(New Structure("ParentDocIsByReservation", False));
	vQryResultResArray = vQryResult.Copy().FindRows(New Structure("ParentDocIsByReservation", True));
	vQryResultWalkIn = vQryResult.CopyColumns();
	For Each vRow In vQryResultWalkInArray Do
		vTabRow = vQryResultWalkIn.Add();
		FillPropertyValues(vTabRow, vRow);
	EndDo;
	vQryResultWalkIn.GroupBy("Period", "GuestsCheckedInTurnover");
	vQryResultRes = vQryResult.CopyColumns();
	For Each vRow In vQryResultResArray Do
		vTabRow = vQryResultRes.Add();
		FillPropertyValues(vTabRow, vRow);
	EndDo;
	vQryResultRes.GroupBy("Period", "GuestsCheckedInTurnover");
	GetQResultTableTotals(PeriodTo, vQryResultRes, vQryResultRes, "GuestsCheckedInTurnover", False);
	vGuestsReserved = cmCastToNumber(TotalPerDay.GuestsCheckedInTurnover);
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexName = Tabulation + NStr("en='Guests reserved and checked-in';ru='Заезд гостей по брони';de='Anreise der Gäste nach der Reservierung'");
	vNewStr.IndexKey = vNewStr.IndexName;
	vNewStr.IndexValue = vGuestsReserved;
	vNewStr.IndexPresentation = vGuestsReserved;
	
	// Put walk-in
	GetQResultTableTotals(PeriodTo, vQryResultWalkIn, vQryResultWalkIn, "GuestsCheckedInTurnover", False);
	vGuestsWalkIn = cmCastToNumber(TotalPerDay.GuestsCheckedInTurnover);
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexName = Tabulation + NStr("en='Guests walk-in';ru='Заезд без брони';de='Anreise ohne Reservierung'");
	vNewStr.IndexKey = vNewStr.IndexName;
	vNewStr.IndexValue = vGuestsWalkIn;
	vNewStr.IndexPresentation = vGuestsWalkIn;
	
	// 4. Income summary indexes
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexPicture = PictureLib.Totals;
	vNewStr.IndexName = NStr("en='INCOME SUMMARY INDEXES';ru='СТАТИСТИКА ПО ДОХОДАМ';de='STATISTIK NACH EINNAHMEN'");
	vNewStr.IndexKey = vNewStr.IndexName;
	
	// Put total sales
	vNewStr = IndexesTable.Add();
	vNewStr.IndexName = Tabulation + NStr("en='Rooms Revenue';ru='Доход от продажи номеров';de='Erlös aus den Zimmerverkauf'");
	vNewStr.IndexKey = vNewStr.IndexName;
	vNewStr.IndexValue = vRoomsIncome;
	vNewStr.IndexPresentation = ?(vRoomsIncome = 0, vRoomsIncome, cmFormatSum(vRoomsIncome, vReportingCurrency));
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexName = Tabulation + NStr("en='Other Income';ru='Прочий доход';de='Sonstige Einnahmen'");
	vNewStr.IndexKey = vNewStr.IndexName;
	vNewStr.IndexValue = vOtherIncome;	
	vNewStr.IndexPresentation = ?(vOtherIncome = 0, vOtherIncome, cmFormatSum(vOtherIncome, vReportingCurrency));
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexPicture = PictureLib.Empty;
	vNewStr.IndexName = NStr("en='SERVICE TYPES SUMMARY INDEXES';ru='СТАТИСТИКА ПО ТИПАМ УСЛУГ';de='STATISTIK NACH DIENSTLEISTUNGSSTYPEN'");
	vNewStr.IndexKey = vNewStr.IndexName;
	
	// Put sales by service types
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServiceSales.Period AS Period,
	|	ServiceSales.ServiceType AS ServiceType,
	|	SUM(ServiceSales.SumTurnover) AS SumTurnover,
	|	SUM(ServiceSales.SumWithoutVATTurnover) AS SumWithoutVATTurnover
	|FROM
	|	(SELECT
	|		ServiceSalesTurnovers.Period AS Period,
	|		ServiceSalesTurnovers.Service.ServiceType AS ServiceType,
	|		ServiceSalesTurnovers.SalesTurnover AS SumTurnover,
	|		ServiceSalesTurnovers.SalesWithoutVATTurnover AS SumWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel) AND NOT IsCorrection) AS ServiceSalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ServiceSalesForecastTurnovers.Period,
	|		ServiceSalesForecastTurnovers.Service.ServiceType,
	|		ServiceSalesForecastTurnovers.SalesTurnover,
	|		ServiceSalesForecastTurnovers.SalesWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(&qForecastPeriodFrom, &qForecastPeriodTo, Day, &qUseForecast AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesForecastTurnovers) AS ServiceSales
	|
	|GROUP BY
	|	ServiceSales.Period,
	|	ServiceSales.ServiceType
	|
	|ORDER BY
	|	Period,
	|	ServiceSales.ServiceType.SortCode";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qForecastPeriodFrom", Max(vForecastStartDate, vBegOfPeriod));
	vQry.SetParameter("qForecastPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qUseForecast", ?(vForecastStartDate > vEndOfPeriod, False, True));
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// Get list of service types
	vServiceTypes = vQryResult.Copy();
	vServiceTypes.GroupBy("ServiceType", );
	
	If vServiceTypes.Count() > 1 Then
		// Put service types summary
		For Each vRow In vServiceTypes Do
			vServiceType = vRow.ServiceType;
			
			vNewStr = IndexesTable.Add();
			vNewStr.IndexName = Tabulation + "   "+vServiceType;
			vNewStr.IndexKey = vNewStr.IndexName;
			// Get records for the current service type only
			vQrySubresult = vQryResult.FindRows(New Structure("ServiceType", vServiceType));
			GetQResultTableTotals(PeriodTo, vQrySubresult, vQryResult, "SumTurnover, SumWithoutVATTurnover", False);
			If vWithVAT Then
				vServiceTypeIncome = cmCastToNumber(TotalPerDay.SumTurnover);
			Else
				vServiceTypeIncome = cmCastToNumber(TotalPerDay.SumWithoutVATTurnover);
			EndIf;
			vNewStr.IndexValue = vServiceTypeIncome;
			vNewStr.IndexPresentation = ?(vServiceTypeIncome = 0, vServiceTypeIncome, cmFormatSum(vServiceTypeIncome, vReportingCurrency));
			vNewStr.SecondDateIndexValue = 0;
			vNewStr.SecondDateIndexPresentation = 0;
		EndDo;
	EndIf;
	vNewStr = IndexesTable.Add();
	vNewStr.IndexName = Tabulation + NStr("en='Total Income';ru='Общий доход';de='Gesamteinkommen'");
	vNewStr.IndexKey = NStr("en='SEVICE TYPE TOTALS';ru='ИТОГИ ПО ТИПАМ УСЛУГ';de='ERGEBNISSE NACH DIENSTLEISTUNGSTYPEN'");
	vNewStr.IndexValue = vTotalIncome;
	vNewStr.IndexPresentation = ?(vTotalIncome = 0, vTotalIncome, cmFormatSum(vTotalIncome, vReportingCurrency));
	
	// 5. Payments summary indexes
	
	vNewStr = IndexesTable.Add();
	vNewStr.IndexPicture = PictureLib.ToBePaid;
	vNewStr.IndexName = NStr("en='PAYMENTS SUMMARY INDEXES';ru='СТАТИСТИКА ПО ПЛАТЕЖАМ';de='STATISTIK NACH ZAHLUNGEN'");
	vNewStr.IndexKey = vNewStr.IndexName;
	
	// Run query to get payments by payment method
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PaymentsTurnovers.PaymentMethod AS PaymentMethod,
	|	PaymentsTurnovers.Period AS Period,
	|	SUM(PaymentsTurnovers.SumTurnover) AS SumTurnover,
	|	SUM(PaymentsTurnovers.VATSumTurnover) AS VATSumTurnover
	|FROM
	|	AccumulationRegister.Payments.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS PaymentsTurnovers
	|GROUP BY
	|	PaymentsTurnovers.Period,
	|	PaymentsTurnovers.PaymentMethod
	|ORDER BY
	|	PaymentMethod,
	|	Period";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// Get list of payment methods
	vPaymentMethods = vQryResult.Copy();
	vPaymentMethods.GroupBy("PaymentMethod", );
	
	// Put payment methods summary
	vTotalPaymentsPerDay = 0;
	For Each vRow In vPaymentMethods Do
		vPaymentMethod = vRow.PaymentMethod;
		If vPaymentMethod = Catalogs.PaymentMethods.Settlement Then
			Continue;
		EndIf;
		
		// Get records for the current payment method only
		vQrySubresult = vQryResult.FindRows(New Structure("PaymentMethod", vPaymentMethod));
		GetQResultTableTotals(PeriodTo, vQrySubresult, vQryResult, "SumTurnover, VATSumTurnover", False);
		vSumTurnover = cmCastToNumber(TotalPerDay.SumTurnover);
		
		vNewStr = IndexesTable.Add();
		vNewStr.IndexName = Tabulation+vPaymentMethod;
		vNewStr.IndexKey = vPaymentMethod;
		vNewStr.IndexValue = vSumTurnover;
		vNewStr.IndexPresentation = ?(vSumTurnover = 0, vSumTurnover, cmFormatSum(vSumTurnover, vReportingCurrency));
		vNewStr.SecondDateIndexValue = 0;
		vNewStr.SecondDateIndexPresentation = 0;
		
		vTotalPaymentsPerDay = vTotalPaymentsPerDay + cmCastToNumber(TotalPerDay.SumTurnover);
	EndDo;
	
	// Payments footer
	vNewStr = IndexesTable.Add();
	vNewStr.IndexName = Tabulation + NStr("en='Total payments';ru='Всего платежей';de='Gesamt Zahlungen'");
	vNewStr.IndexKey = vNewStr.IndexName;
	vNewStr.IndexValue = vTotalPaymentsPerDay;
	vNewStr.IndexPresentation = ?(vTotalPaymentsPerDay = 0, vTotalPaymentsPerDay, cmFormatSum(vTotalPaymentsPerDay, vReportingCurrency));
EndProcedure // GetRooms

// -------------------------------------------------------------------------------------------------
&AtServer
Procedure GetCompareRooms()
	GetRooms();
	
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	
	// Check period choosen now
	If Items.PeriodDay.Visible Then
		vBegOfPeriodNow = BegOfDay(PeriodTo);
		vEndOfPeriodNow = EndOfDay(PeriodTo);
	ElsIf Items.SelQuarter.Visible Then
		vBegOfPeriodNow = BegOfQuarter(CompositionDate);
		vEndOfPeriodNow = EndOfQuarter(CompositionDate);
	ElsIf Items.SelMonth.Visible Then
		vBegOfPeriodNow = BegOfMonth(CompositionDate);
		vEndOfPeriodNow = EndOfMonth(CompositionDate);
	Else
		vBegOfPeriodNow = BegOfYear(CompositionDate);
		vEndOfPeriodNow = EndOfYear(CompositionDate);
	EndIf;
	
	// Check period choosen
	If Items.PeriodDay.Visible Then
		vBegOfPeriod = BegOfDay(CompareDate);
		vEndOfPeriod = EndOfDay(CompareDate);
	ElsIf Items.CompareQuarter.Visible Then
		vBegOfPeriod = BegOfQuarter(CompareCompositionDate);
		vEndOfPeriod = EndOfQuarter(CompareCompositionDate);
	ElsIf Items.CompareMonth.Visible Then
		vBegOfPeriod = BegOfMonth(CompareCompositionDate);
		vEndOfPeriod = EndOfMonth(CompareCompositionDate);
	Else
		vBegOfPeriod = BegOfYear(CompareCompositionDate);
		vEndOfPeriod = EndOfYear(CompareCompositionDate);
	EndIf;
	
	// Initialize reporting currency
	vReportingCurrency = Hotel.ReportingCurrency;
	If Not ValueIsFilled(Hotel) Then
		Return;
	EndIf;
	
	vInRooms = True;
	vWithVAT = True;
	If ValueIsFilled(Hotel) Then
		vInRooms = Not Hotel.ShowReportsInBeds;
		vWithVAT = Hotel.ShowSalesInReportsWithVAT;
	EndIf;
	
	// Run query to get total number of rooms, rooms blocked, vacant number of rooms
	vTempInd = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalanceAndTurnovers.Period AS Period,
	|	SUM(RoomInventoryBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRoomsClosingBalance,
	|	SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBedsClosingBalance,
	|	-SUM(RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlockedClosingBalance,
	|	-SUM(RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlockedClosingBalance
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalanceAndTurnovers
	|GROUP BY
	|	RoomInventoryBalanceAndTurnovers.Period
	|ORDER BY
	|	Period";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	vResources = "TotalRoomsClosingBalance, TotalBedsClosingBalance, RoomsBlockedClosingBalance, BedsBlockedClosingBalance";
	GetQResultTableTotals(CompareDate, vQryResult, vQryResult, vResources);
	vTotalRooms = cmCastToNumber(TotalPerDay.TotalRoomsClosingBalance);
	vTotalBeds = cmCastToNumber(TotalPerDay.TotalBedsClosingBalance);
	
	// Put total rooms/beds
	vTempInd = 1;
	vStr = IndexesTable.Get(vTempInd);
	If vInRooms Then
		vStr.SecondDateIndexValue = vTotalRooms;
		vStr.SecondDateIndexPresentation = vTotalRooms;
	Else
		vStr.SecondDateIndexValue = vTotalBeds;
		vStr.SecondDateIndexPresentation = vTotalBeds;
	EndIf;
	vBlockedRooms = cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);
	vBlockedBeds = cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
	vRoomsForSale = vTotalRooms - vBlockedRooms;
	vBedsForSale = vTotalBeds - vBlockedBeds;
	
	// Run query to get number of blocked rooms per room block types
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomBlocksBalanceAndTurnovers.RoomBlockType AS RoomBlockType,
	|	RoomBlocksBalanceAndTurnovers.Period AS Period,
	|	SUM(RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlockedClosingBalance,
	|	SUM(RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlockedClosingBalance
	|FROM
	|	AccumulationRegister.RoomBlocks.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS RoomBlocksBalanceAndTurnovers
	|
	|GROUP BY
	|	RoomBlocksBalanceAndTurnovers.RoomBlockType,
	|	RoomBlocksBalanceAndTurnovers.Period
	|
	|ORDER BY
	|	RoomBlocksBalanceAndTurnovers.RoomBlockType.SortCode,
	|	Period";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// Get list of room block types
	vRoomBlockTypes = vQryResult.Copy();
	vRoomBlockTypes.GroupBy("RoomBlockType", );
	
	// Do for each room block type
	vSpecRoomsBlocked = 0;
	vSpecBedsBlocked = 0;
	If vQryResult.Count() > 0 Then
		// Put room blocks per room block type
		For Each vRow In vRoomBlockTypes Do
			vRoomBlockType = vRow.RoomBlockType;
			
			vExistingStr = Undefined;
			vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", vRoomBlockType.Description));
			If vExistingRows.Count() > 0 Then
				vExistingStr = vExistingRows.Get(0);
			EndIf;
			
			// Get records for the current room block type only
			vQrySubresult = vQryResult.FindRows(New Structure("RoomBlockType", vRoomBlockType));
			GetQResultTableTotals(CompareDate, vQrySubresult, vQryResult, "RoomsBlockedClosingBalance, BedsBlockedClosingBalance");
			If vExistingStr = Undefined Then
				vTempInd = vTempInd + 1;
				
				vNewStr = IndexesTable.Insert(vTempInd);
				vNewStr.IndexName = Tabulation + vRoomBlockType;
				vNewStr.IndexKey = vRoomBlockType;
				vNewStr.IndexValue = 0;
				vNewStr.IndexPresentation = 0;
				
				If vInRooms Then
					vBlockedRooms = cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);
					vNewStr.SecondDateIndexValue = vBlockedRooms;
					vNewStr.SecondDateIndexPresentation = vBlockedRooms;
					If vRoomBlockType.AddToRoomsRentedInSummaryIndexes Then
						vSpecRoomsBlocked = vSpecRoomsBlocked + cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);
					EndIf;
				Else
					vBlockedBeds = cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
					vNewStr.SecondDateIndexValue = vBlockedBeds;
					vNewStr.SecondDateIndexPresentation = vBlockedBeds;
					If vRoomBlockType.AddToRoomsRentedInSummaryIndexes Then
						vSpecBedsBlocked = vSpecBedsBlocked + cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
					EndIf;
				EndIf;
			Else
				vTempInd = IndexesTable.IndexOf(vExistingStr);
				
				If vInRooms Then
					vBlockedRooms = cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);
					vExistingStr.SecondDateIndexValue = vBlockedRooms;
					vExistingStr.SecondDateIndexPresentation = vBlockedRooms;
					If vRoomBlockType.AddToRoomsRentedInSummaryIndexes Then
						vSpecRoomsBlocked = vSpecRoomsBlocked + cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);
					EndIf;
				Else
					vBlockedBeds = cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
					vExistingStr.SecondDateIndexValue = vBlockedBeds;
					vExistingStr.SecondDateIndexPresentation = vBlockedBeds;
					If vRoomBlockType.AddToRoomsRentedInSummaryIndexes Then
						vSpecBedsBlocked = vSpecBedsBlocked + cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	Else
		vExistingStr = Undefined;
		vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", NStr("en='Repaired';ru='Ремонт';de='Reparatur'")));
		If vExistingRows.Count() > 0 Then
			vExistingStr = vExistingRows.Get(0);
		EndIf;
		If vExistingStr = Undefined Then
			vTempInd = 2;
			vNewStr = IndexesTable.Insert(vTempInd);
			vNewStr.IndexName = Tabulation + NStr("en='Repaired';ru='Ремонт';de='Reparatur'");
			vNewStr.IndexKey = NStr("en='Repaired';ru='Ремонт';de='Reparatur'");
			vNewStr.IndexValue = 0;
			vNewStr.IndexPresentation = 0;
			vNewStr.SecondDateIndexValue = 0;
			vNewStr.SecondDateIndexPresentation = 0;
		Else
			vTempInd = IndexesTable.IndexOf(vExistingStr);
			
			vExistingStr.SecondDateIndexValue = 0;
			vExistingStr.SecondDateIndexPresentation = 0;
		EndIf;
	EndIf;
	
	// Put rooms for sale
	vIndexKey = ?(vInRooms, Tabulation + NStr("en='Rooms For Sale';ru='Номеров к продаже';de='Zimmer im Verkauf'"), Tabulation + NStr("en='Beds For Sale';ru='Мест к продаже';de='Betten für den Verkauf'"));
	vIndexValue = ?(vInRooms, vRoomsForSale + vSpecRoomsBlocked, vBedsForSale + vSpecBedsBlocked);
	vExistingStr = Undefined;
	vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", vIndexKey));
	If vExistingRows.Count() > 0 Then
		vExistingStr = vExistingRows.Get(0);
	EndIf;
	If vExistingStr = Undefined Then
		vTempInd = vTempInd + 1;
		
		vNewStr = IndexesTable.Insert(vTempInd);
		vNewStr.IndexName = vIndexKey;
		vNewStr.IndexKey = vIndexKey;
		vNewStr.IndexValue = 0;
		vNewStr.IndexPresentation = 0;
		vNewStr.SecondDateIndexValue = vIndexValue;
		vNewStr.SecondDateIndexPresentation = vIndexValue;
	Else
		vTempInd = IndexesTable.IndexOf(vExistingStr);
		
		vExistingStr.SecondDateIndexValue = vIndexValue;
		vExistingStr.SecondDateIndexPresentation = vIndexValue;
	EndIf;
	
	// Run query to get room sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.Period AS Period,
	|	RoomSalesTurnovers.RoomRate.IsComplimentary AS RoomRateIsComplimentary,
	|	RoomSalesTurnovers.RoomRate.IsHouseUse AS RoomRateIsHouseUse,
	|	SUM(RoomSalesTurnovers.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSalesTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSalesTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSalesTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesTurnovers.BedsRentedTurnover) AS BedsRentedTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel) AND NOT IsCorrection) AS RoomSalesTurnovers
	|GROUP BY
	|	RoomSalesTurnovers.Period,
	|	RoomSalesTurnovers.RoomRate.IsComplimentary,
	|	RoomSalesTurnovers.RoomRate.IsHouseUse
	|ORDER BY
	|	Period,
	|	RoomRateIsComplimentary,
	|	RoomRateIsHouseUse";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// Add forecast sales if period is set in the future
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesForecastTurnovers.Period AS Period,
	|	RoomSalesForecastTurnovers.RoomRate.IsComplimentary AS RoomRateIsComplimentary,
	|	RoomSalesForecastTurnovers.RoomRate.IsHouseUse AS RoomRateIsHouseUse,
	|	SUM(RoomSalesForecastTurnovers.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSalesForecastTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSalesForecastTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSalesForecastTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSalesForecastTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesForecastTurnovers.BedsRentedTurnover) AS BedsRentedTurnover
	|FROM
	|	AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, Day, &qUseForecast AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesForecastTurnovers
	|GROUP BY
	|	RoomSalesForecastTurnovers.Period,
	|	RoomSalesForecastTurnovers.RoomRate.IsComplimentary,
	|	RoomSalesForecastTurnovers.RoomRate.IsHouseUse
	|ORDER BY
	|	Period,
	|	RoomRateIsComplimentary,
	|	RoomRateIsHouseUse";
	vQry.SetParameter("qPeriodFrom", Max(vForecastStartDate, vBegOfPeriod));
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qUseForecast", ?(vForecastStartDate > vEndOfPeriod, False, True));
	vQry.SetParameter("qHotel", Hotel);
	vForecastQryResult = vQry.Execute().Unload();
	
	// Merge forecast sales with real ones
	For Each vForecastRow In vForecastQryResult Do
		vFound = False;
		For Each vRow In vQryResult Do
			If vRow.Period = vForecastRow.Period And
				vRow.RoomRateIsComplimentary = vForecastRow.RoomRateIsComplimentary And
				vRow.RoomRateIsComplimentary = vForecastRow.RoomRateIsHouseUse Then
				vFound = True;
				Break;
			EndIf;
		EndDo;
		If Not vFound Then
			vRow = vQryResult.Add();
			vRow.Period = vForecastRow.Period;
			vRow.RoomRateIsComplimentary = vForecastRow.RoomRateIsComplimentary;
			vRow.RoomRateIsHouseUse = vForecastRow.RoomRateIsHouseUse;
			vRow.SalesTurnover = 0;
			vRow.SalesWithoutVATTurnover = 0;
			vRow.RoomRevenueTurnover = 0;
			vRow.RoomRevenueWithoutVATTurnover = 0;
			vRow.RoomsRentedTurnover = 0;
			vRow.BedsRentedTurnover = 0;
		EndIf;
		vRow.SalesTurnover = vRow.SalesTurnover + vForecastRow.SalesTurnover;
		vRow.SalesWithoutVATTurnover = vRow.SalesWithoutVATTurnover + vForecastRow.SalesWithoutVATTurnover;
		vRow.RoomRevenueTurnover = vRow.RoomRevenueTurnover + vForecastRow.RoomRevenueTurnover;
		vRow.RoomRevenueWithoutVATTurnover = vRow.RoomRevenueWithoutVATTurnover + vForecastRow.RoomRevenueWithoutVATTurnover;
		vRow.RoomsRentedTurnover = vRow.RoomsRentedTurnover + vForecastRow.RoomsRentedTurnover;
		vRow.BedsRentedTurnover = vRow.BedsRentedTurnover + vForecastRow.BedsRentedTurnover;
	EndDo;
	
	vResources = "SalesTurnover, SalesWithoutVATTurnover, RoomRevenueTurnover, RoomRevenueWithoutVATTurnover, RoomsRentedTurnover, BedsRentedTurnover";
	
	// Split table to total and complimentary only
	vQryResultComplArray = vQryResult.Copy().FindRows(New Structure("RoomRateIsComplimentary", True));
	vQryResultCompl = vQryResult.CopyColumns();
	For Each vRow In vQryResultComplArray Do
		vTabRow = vQryResultCompl.Add();
		FillPropertyValues(vTabRow, vRow);
	EndDo;
	vQryResultCompl.GroupBy("Period", vResources);
	
	// Put complimentary rooms rented
	GetQResultTableTotals(PeriodTo, vQryResultCompl, vQryResultCompl, vResources, False);
	If vInRooms Then
		vIndexKey = Tabulation + NStr("en='Complimentary rooms';ru='Бесплатных номеров';de='Gratis Zimmer'");
		vIndexValue = cmCastToNumber(TotalPerDay.RoomsRentedTurnover);
	Else
		vIndexKey = Tabulation + NStr("en='Complimentary beds';ru='Бесплатных мест';de='Gratis Betten'");
		vIndexValue = cmCastToNumber(TotalPerDay.BedsRentedTurnover);
	EndIf;
	vExistingStr = Undefined;
	vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", vIndexKey));
	If vExistingRows.Count() > 0 Then
		vExistingStr = vExistingRows.Get(0);
	EndIf;
	If vExistingStr = Undefined Then
		vTempInd = vTempInd + 1;
		
		vNewStr = IndexesTable.Insert(vTempInd);
		vNewStr.IndexName = vIndexKey;
		vNewStr.IndexKey = vIndexKey;
		vNewStr.IndexValue = 0;
		vNewStr.IndexPresentation = 0;
		vNewStr.SecondDateIndexValue = vIndexValue;
		vNewStr.SecondDateIndexPresentation = Round(vIndexValue);
	Else
		vTempInd = IndexesTable.IndexOf(vExistingStr);
		
		vExistingStr.SecondDateIndexValue = vIndexValue;
		vExistingStr.SecondDateIndexPresentation = Round(vIndexValue);
	EndIf;
	
	// Get houseuse only
	vQryResultHUArray = vQryResult.Copy().FindRows(New Structure("RoomRateIsHouseUse", True));
	vQryResultHU = vQryResult.CopyColumns();
	For Each vRow In vQryResultHUArray Do
		vTabRow = vQryResultHU.Add();
		FillPropertyValues(vTabRow, vRow);
	EndDo;
	vQryResultHU.GroupBy("Period", vResources);
	
	// Put house use rooms rented
	GetQResultTableTotals(PeriodTo, vQryResultHU, vQryResultHU, vResources, False);
	If vInRooms Then
		vIndexKey = Tabulation + NStr("en='House Use rooms';ru='Номеров для внутреннего использования';de='Hausgebrauch Zimmer'");
		vIndexValue = cmCastToNumber(TotalPerDay.RoomsRentedTurnover);
	Else
		vIndexKey = Tabulation + NStr("en='House Use beds';ru='Мест для внутреннего использования';de='Hausgebrauch Betten'");
		vIndexValue = cmCastToNumber(TotalPerDay.BedsRentedTurnover);
	EndIf;
	vExistingStr = Undefined;
	vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", vIndexKey));
	If vExistingRows.Count() > 0 Then
		vExistingStr = vExistingRows.Get(0);
	EndIf;
	If vExistingStr = Undefined Then
		vTempInd = vTempInd + 1;
		
		vNewStr = IndexesTable.Insert(vTempInd);
		vNewStr.IndexName = vIndexKey;
		vNewStr.IndexKey = vIndexKey;
		vNewStr.IndexValue = 0;
		vNewStr.IndexPresentation = 0;
		vNewStr.SecondDateIndexValue = vIndexValue;
		vNewStr.SecondDateIndexPresentation = Round(vIndexValue);
	Else
		vTempInd = IndexesTable.IndexOf(vExistingStr);
		
		vExistingStr.SecondDateIndexValue = vIndexValue;
		vExistingStr.SecondDateIndexPresentation = Round(vIndexValue);
	EndIf;
	
	// Get rooms rented
	vQryResult.GroupBy("Period, RoomRateIsComplimentary, RoomRateIsHouseUse", vResources);
	vQryResult.Sort("Period, RoomRateIsComplimentary, RoomRateIsHouseUse");
	GetQResultTableTotals(CompareDate, vQryResult, vQryResult, vResources, False);
	vRoomsRented = cmCastToNumber(TotalPerDay.RoomsRentedTurnover);
	vBedsRented = cmCastToNumber(TotalPerDay.BedsRentedTurnover);
	vIndexKey = ?(vInRooms, Tabulation + NStr("en='Rooms Rented';ru='Продано номеров';de='Verkaufte Zimmer'"), Tabulation + NStr("en='Beds Rented';ru='Продано мест';de='Verkaufte Betten'"));
	vIndexValue = ?(vInRooms, vRoomsRented, vBedsRented);
	
	vExistingStr = Undefined;
	vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", vIndexKey));
	If vExistingRows.Count() > 0 Then
		vExistingStr = vExistingRows.Get(0);
	EndIf;
	If vExistingStr = Undefined Then
		vTempInd = vTempInd + 1;
		
		vNewStr = IndexesTable.Insert(vTempInd);
		vNewStr.IndexName = vIndexKey;
		vNewStr.IndexKey = vIndexKey;
		vNewStr.IndexValue = 0;
		vNewStr.IndexPresentation = 0;
		vNewStr.SecondDateIndexValue = vIndexValue;
		vNewStr.SecondDateIndexPresentation = Round(vIndexValue);
	Else
		vTempInd = IndexesTable.IndexOf(vExistingStr);
		
		vExistingStr.SecondDateIndexValue = vIndexValue;
		vExistingStr.SecondDateIndexPresentation = Round(vIndexValue);
	EndIf;
	
	// Save total sale amounts
	If vWithVAT Then
		vRoomsIncome = cmCastToNumber(TotalPerDay.RoomRevenueTurnover);		
		vTotalIncome = cmCastToNumber(TotalPerDay.SalesTurnover);
	Else
		vRoomsIncome = cmCastToNumber(TotalPerDay.RoomRevenueWithoutVATTurnover);		
		vTotalIncome = cmCastToNumber(TotalPerDay.SalesWithoutVATTurnover);
	EndIf;
	vOtherIncome = vTotalIncome - vRoomsIncome;
	
	// Put occupation percent
	vIndexKey = Tabulation + NStr("ru = '% Загрузки по проданным номерам'; en = 'Occupation % by rooms rented'; de = 'Occupation % by rooms rented'");
	vExistingStr = Undefined;
	vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", vIndexKey));
	If vExistingRows.Count() > 0 Then
		vExistingStr = vExistingRows.Get(0);
		vTempInd = IndexesTable.IndexOf(vExistingStr);
	EndIf;
	If vExistingStr <> Undefined Then
		If vInRooms Then
			vOccupationRooms = Round(?((vRoomsForSale + vSpecRoomsBlocked) <> 0, 100*(vRoomsRented + vSpecRoomsBlocked)/(vRoomsForSale + vSpecRoomsBlocked), 0), 2);
			vExistingStr.SecondDateIndexValue = vOccupationRooms;
			vExistingStr.SecondDateIndexPresentation = String(vOccupationRooms)+"%";
			
			vAvgRoomPrice = Round(?(vRoomsRented <> 0, vRoomsIncome/vRoomsRented, 0), 2);
			vAvgRoomPriceInclAddSrv = Round(?(vRoomsRented <> 0, vTotalIncome/vRoomsRented, 0), 2);
			vAvgRoomIncome = Round(?((vRoomsForSale + vSpecRoomsBlocked) <> 0, vRoomsIncome/(vRoomsForSale + vSpecRoomsBlocked), 0), 2);
			
			vTempInd = vTempInd + 1;
			vExistingStr = IndexesTable.Get(vTempInd);
			vExistingStr.SecondDateIndexValue = vAvgRoomPrice;
			vExistingStr.SecondDateIndexPresentation = ?(vAvgRoomPrice = 0, vAvgRoomPrice, cmFormatSum(vAvgRoomPrice, vReportingCurrency));
			
			vTempInd = vTempInd + 1;
			vExistingStr = IndexesTable.Get(vTempInd);
			vExistingStr.SecondDateIndexValue = vAvgRoomPriceInclAddSrv;
			vExistingStr.SecondDateIndexPresentation = ?(vAvgRoomPriceInclAddSrv = 0, vAvgRoomPriceInclAddSrv, cmFormatSum(vAvgRoomPriceInclAddSrv, vReportingCurrency));
			
			vTempInd = vTempInd + 1;
			vExistingStr = IndexesTable.Get(vTempInd);
			vExistingStr.SecondDateIndexValue = vAvgRoomIncome;
			vExistingStr.SecondDateIndexPresentation = ?(vAvgRoomIncome = 0, vAvgRoomIncome, cmFormatSum(vAvgRoomIncome, vReportingCurrency));
		Else
			vOccupationBeds = Round(?((vBedsForSale + vSpecBedsBlocked) <> 0, 100*(vBedsRented + vSpecBedsBlocked)/(vBedsForSale + vSpecBedsBlocked), 0), 2);
			vExistingStr.SecondDateIndexValue = vOccupationBeds;
			vExistingStr.SecondDateIndexPresentation = String(vOccupationBeds)+"%";
			
			vAvgBedPrice = Round(?(vBedsRented <> 0, vRoomsIncome/vBedsRented, 0), 2);	
			vAvgBedPriceInclAddSrv = Round(?(vBedsRented <> 0, vTotalIncome/vBedsRented, 0), 2);		
			vAvgBedIncome = Round(?((vBedsForSale + vSpecBedsBlocked) <> 0, vRoomsIncome/(vBedsForSale + vSpecBedsBlocked), 0), 2);	
			
			vTempInd = vTempInd + 1;
			vExistingStr = IndexesTable.Get(vTempInd);
			vExistingStr.SecondDateIndexValue = vAvgBedPrice;
			vExistingStr.SecondDateIndexPresentation = ?(vAvgBedPrice = 0, vAvgBedPrice, cmFormatSum(vAvgBedPrice, vReportingCurrency));
			
			vTempInd = vTempInd + 1;
			vExistingStr = IndexesTable.Get(vTempInd);
			vExistingStr.SecondDateIndexValue = vAvgBedPriceInclAddSrv;
			vExistingStr.SecondDateIndexPresentation = ?(vAvgBedPriceInclAddSrv = 0, vAvgBedPriceInclAddSrv, cmFormatSum(vAvgBedPriceInclAddSrv, vReportingCurrency));
			
			vTempInd = vTempInd + 1;
			vExistingStr = IndexesTable.Get(vTempInd);
			vExistingStr.SecondDateIndexValue = vAvgBedIncome;
			vExistingStr.SecondDateIndexPresentation = ?(vAvgBedIncome = 0, vAvgBedIncome, cmFormatSum(vAvgBedIncome, vReportingCurrency));
		EndIf;
	EndIf;
	
	// 2. Guests summary indexes
	
	// Run query to get number of guest days
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.Period AS Period,
	|	RoomSalesTurnovers.ClientType AS ClientType,
	|	SUM(RoomSalesTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(RoomSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel) AND NOT IsCorrection) AS RoomSalesTurnovers
	|GROUP BY
	|	RoomSalesTurnovers.Period,
	|	RoomSalesTurnovers.ClientType
	|ORDER BY
	|	Period,
	|	ClientType";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// Add forecast guests if period is set in the future
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesForecastTurnovers.Period AS Period,
	|	RoomSalesForecastTurnovers.ClientType AS ClientType,
	|	SUM(RoomSalesForecastTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(RoomSalesForecastTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, Day, &qUseForecast AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesForecastTurnovers
	|GROUP BY
	|	RoomSalesForecastTurnovers.Period,
	|	RoomSalesForecastTurnovers.ClientType
	|ORDER BY
	|	Period,
	|	ClientType";
	vQry.SetParameter("qPeriodFrom", Max(vForecastStartDate, vBegOfPeriod));
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qUseForecast", ?(vForecastStartDate > vEndOfPeriod, False, True));
	vQry.SetParameter("qHotel", Hotel);
	vForecastQryResult = vQry.Execute().Unload();
	
	// Merge forecast guests with real ones
	For Each vForecastRow In vForecastQryResult Do
		vFound = False;
		For Each vRow In vQryResult Do
			If vRow.Period = vForecastRow.Period And
				vRow.ClientType = vForecastRow.ClientType Then
				vFound = True;
				Break;
			EndIf;
		EndDo;
		If Not vFound Then
			vRow = vQryResult.Add();
			vRow.Period = vForecastRow.Period;
			vRow.ClientType = vForecastRow.ClientType;
			vRow.GuestDaysTurnover = 0;
			vRow.GuestsCheckedInTurnover = 0;
		EndIf;
		vRow.GuestDaysTurnover = vRow.GuestDaysTurnover + vForecastRow.GuestDaysTurnover;
		vRow.GuestsCheckedInTurnover = vRow.GuestsCheckedInTurnover + vForecastRow.GuestsCheckedInTurnover;
	EndDo;
	
	// Get list of client types
	vClientTypes = vQryResult.Copy();
	vClientTypes.GroupBy("ClientType", );
	vTheOneCT = false;
	
	vExistingStrTitle = Undefined;
	vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", Tabulation + NStr("en='Guest days';ru='Человеко-дни';de='Personentage'")));
	If vExistingRows.Count() > 0 Then
		vExistingStrTitle = vExistingRows.Get(0);
	EndIf;	
	If vExistingStrTitle = Undefined Then
		vTempInd = vTempInd + 1;
		vNewStr = IndexesTable.Insert(vTempInd);
		vNewStr.IndexName = Tabulation + NStr("en='Guest days';ru='Человеко-дни';de='Personentage'");
	Else
		vTempInd = IndexesTable.IndexOf(vExistingStrTitle);
	EndIf;
	
	// Put client types
	vCheckedInGuests = 0;
	For Each vRow In vClientTypes Do
		vClientType = vRow.ClientType;
		// Get records for the current client type only
		vQrySubresult = vQryResult.FindRows(New Structure("ClientType", vClientType));
		GetQResultTableTotals(CompareDate, vQrySubresult, vQryResult, "GuestDaysTurnover, GuestsCheckedInTurnover", False);
		vGuests = cmCastToNumber(TotalPerDay.GuestDaysTurnover);
		
		// Initialize number of checked in guests
		vCheckedInGuests = vCheckedInGuests + cmCastToNumber(TotalPerDay.GuestsCheckedInTurnover);
		
		If vExistingStrTitle = Undefined Then
			vTempInd = vTempInd + 1;
			vNewStr = IndexesTable.Insert(vTempInd);
			vNewStr.IndexName = Tabulation + "   "+vClientType;
			vNewStr.IndexKey = Tabulation + "   "+vClientType;
			vNewStr.IndexValue = 0;
			vNewStr.IndexPresentation = 0;
			vNewStr.SecondDateIndexValue = vGuests;
			vNewStr.SecondDateIndexPresentation = Round(vGuests);
		Else
			vExistingStr = Undefined;
			vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", vClientType.Description));
			If vExistingRows.Count() > 0 Then
				vExistingStr = vExistingRows.Get(0);
			EndIf;
			If vExistingStr = Undefined Then
				vTempInd = vTempInd + 1;
				vNewStr = IndexesTable.Insert(vTempInd);
				vNewStr.IndexName = Tabulation + "   " + vClientType;
				vNewStr.IndexKey = vClientType;
				vNewStr.IndexValue = 0;	
				vNewStr.IndexPresentation = 0;
				vNewStr.SecondDateIndexValue = vGuests;
				vNewStr.SecondDateIndexPresentation = Round(vGuests);
			Else
				vTempInd = IndexesTable.IndexOf(vExistingStr);
				
				vExistingStr.SecondDateIndexValue = vGuests;
				vExistingStr.SecondDateIndexPresentation = Round(vGuests);
			EndIf;
		EndIf;
		
	EndDo;	
	
	vClientTypesTotals = vQryResult.Copy();
	vClientTypesTotals.GroupBy("Period", "GuestDaysTurnover, GuestsCheckedInTurnover");
	GetQResultTableTotals(CompareDate, vClientTypesTotals, vClientTypesTotals, "GuestDaysTurnover, GuestsCheckedInTurnover", False);
	vGuests = cmCastToNumber(TotalPerDay.GuestDaysTurnover);
	If vClientTypes.Count() > 1 or MoreThanOneRecord Then
		vExistingStr = Undefined;
		vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", NStr("en='Total guest days';ru='Всего человеко-дней';de='Gesamt Manntage'")));
		If vExistingRows.Count() > 0 Then
			vExistingStr = vExistingRows.Get(0);
		EndIf;
		If vExistingStr = Undefined Then
			vTempInd = vTempInd + 1;
			vNewStr = IndexesTable.Insert(vTempInd);
			vNewStr.IndexName = Tabulation + NStr("en='TOTAL';ru='ВСЕГО';de='GESAMT'");
			vNewStr.IndexKey = NStr("en='Total guest days';ru='Всего человеко-дней';de='Gesamt Manntage'");
			vNewStr.IndexValue = ExpTotalGuests;	
			vNewStr.IndexPresentation = ExpTotalGuests;
			vNewStr.SecondDateIndexValue = vGuests;
			vNewStr.SecondDateIndexPresentation = Round(vGuests);
		Else
			vTempInd = IndexesTable.IndexOf(vExistingStr);
			
			vExistingStr.SecondDateIndexValue = vGuests;
			vExistingStr.SecondDateIndexPresentation = Round(vGuests);
		EndIf;
	EndIf;	
	
	// Put guests statistics
	If vInRooms Then
		vAvgNumberOfGuests = Round(?(vRoomsRented <> 0, vGuests/vRoomsRented, 0), 2);
	Else
		vAvgNumberOfGuests = Round(?(vBedsRented <> 0, vGuests/vBedsRented, 0), 2);
	EndIf;
	vAvgGuestLengthOfStay = Round(?(vCheckedInGuests <> 0, vGuests/vCheckedInGuests, 0), 2);
	vAvgGuestPrice = Round(?(vGuests <> 0, vRoomsIncome/vGuests, 0), 2);
	vAvgGuestIncome = Round(?(vGuests <> 0, vTotalIncome/vGuests, 0), 2);
	vExistingStr = Undefined;
	vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", Tabulation + NStr("en='Average number of guests per room';ru='Среднее число гостей в номере';de='Durchschnittliche Gästezahl im Zimmer'")));
	If vExistingRows.Count() > 0 Then
		vExistingStr = vExistingRows.Get(0);
	EndIf;
	If vExistingStr <> Undefined Then
		vTempInd = IndexesTable.IndexOf(vExistingStr);
		IndexesTable.Get(vTempInd).SecondDateIndexValue = vAvgNumberOfGuests;
		IndexesTable.Get(vTempInd).SecondDateIndexPresentation = vAvgNumberOfGuests;
		IndexesTable.Get(vTempInd + 1).SecondDateIndexValue = vAvgGuestLengthOfStay;
		IndexesTable.Get(vTempInd + 1).SecondDateIndexPresentation = vAvgGuestLengthOfStay;
		IndexesTable.Get(vTempInd + 2).SecondDateIndexValue = vAvgGuestPrice;
		IndexesTable.Get(vTempInd + 2).SecondDateIndexPresentation = ?(vAvgGuestPrice = 0, vAvgGuestPrice, cmFormatSum(vAvgGuestPrice, vReportingCurrency));
		IndexesTable.Get(vTempInd + 3).SecondDateIndexValue = vAvgGuestIncome;
		IndexesTable.Get(vTempInd + 3).SecondDateIndexPresentation = ?(vAvgGuestIncome = 0, vAvgGuestIncome, cmFormatSum(vAvgGuestIncome, vReportingCurrency));
		vTempInd = vTempInd + 3;
	EndIf;
	
	// 3. Check-in summary indexes
	
	// Run query to get number of checked-in guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.Period AS Period,
	|	RoomSalesTurnovers.ParentDoc.IsByReservation AS ParentDocIsByReservation,
	|	SUM(RoomSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel) AND NOT IsCorrection) AS RoomSalesTurnovers
	|GROUP BY
	|	RoomSalesTurnovers.Period,
	|	RoomSalesTurnovers.ParentDoc.IsByReservation
	|ORDER BY
	|	Period,
	|	ParentDocIsByReservation";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// Add forecast guests if period is set in the future
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesForecastTurnovers.Period AS Period,
	|	TRUE AS ParentDocIsByReservation,
	|	SUM(RoomSalesForecastTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, Day, &qUseForecast AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesForecastTurnovers
	|GROUP BY
	|	RoomSalesForecastTurnovers.Period
	|ORDER BY
	|	Period,
	|	ParentDocIsByReservation";
	vQry.SetParameter("qPeriodFrom", Max(vForecastStartDate, vBegOfPeriod));
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qUseForecast", ?(vForecastStartDate > vEndOfPeriod, False, True));
	vQry.SetParameter("qHotel", Hotel);
	vForecastQryResult = vQry.Execute().Unload();
	
	// Merge forecast guests with real ones
	For Each vForecastRow In vForecastQryResult Do
		vFound = False;
		For Each vRow In vQryResult Do
			If vRow.Period = vForecastRow.Period And
				vRow.ParentDocIsByReservation = vForecastRow.ParentDocIsByReservation Then
				vFound = True;
				Break;
			EndIf;
		EndDo;
		If Not vFound Then
			vRow = vQryResult.Add();
			vRow.Period = vForecastRow.Period;
			vRow.ParentDocIsByReservation = vForecastRow.ParentDocIsByReservation;
			vRow.GuestsCheckedInTurnover = 0;
		EndIf;
		vRow.GuestsCheckedInTurnover = vRow.GuestsCheckedInTurnover + vForecastRow.GuestsCheckedInTurnover;
	EndDo;
	
	// Split table to walk-in and check-in by reservation
	vQryResultWalkInArray = vQryResult.Copy().FindRows(New Structure("ParentDocIsByReservation", False));
	vQryResultResArray = vQryResult.Copy().FindRows(New Structure("ParentDocIsByReservation", True));
	vQryResultWalkIn = vQryResult.CopyColumns();
	For Each vRow In vQryResultWalkInArray Do
		vTabRow = vQryResultWalkIn.Add();
		FillPropertyValues(vTabRow, vRow);
	EndDo;
	vQryResultWalkIn.GroupBy("Period", "GuestsCheckedInTurnover");
	vQryResultRes = vQryResult.CopyColumns();
	For Each vRow In vQryResultResArray Do
		vTabRow = vQryResultRes.Add();
		FillPropertyValues(vTabRow, vRow);
	EndDo;
	vQryResultRes.GroupBy("Period", "GuestsCheckedInTurnover");
	GetQResultTableTotals(CompareDate, vQryResultRes, vQryResultRes, "GuestsCheckedInTurnover", False);
	vExistingStr = Undefined;
	vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", Tabulation + NStr("en='Guests reserved and checked-in';ru='Заезд гостей по брони';de='Anreise der Gäste nach der Reservierung'")));
	If vExistingRows.Count() > 0 Then
		vExistingStr = vExistingRows.Get(0);
	EndIf;
	If vExistingStr<>Undefined Then
		vGuestsReserved = cmCastToNumber(TotalPerDay.GuestsCheckedInTurnover);
		vExistingStr.SecondDateIndexValue = vGuestsReserved;
		vExistingStr.SecondDateIndexPresentation = vGuestsReserved;
		vTempInd = IndexesTable.IndexOf(vExistingStr)
	EndIf;
	
	// Put walk-in
	GetQResultTableTotals(CompareDate, vQryResultWalkIn, vQryResultWalkIn, "GuestsCheckedInTurnover", False);
	vGuestsWalkIn = cmCastToNumber(TotalPerDay.GuestsCheckedInTurnover);
	IndexesTable.Get(vTempInd+1).SecondDateIndexValue = vGuestsWalkIn;
	IndexesTable.Get(vTempInd+1).SecondDateIndexPresentation = vGuestsWalkIn;
	
	// 4. Income summary indexes
	vExistingStr = Undefined;
	vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", Tabulation + NStr("en='Rooms Revenue';ru='Доход от продажи номеров';de='Erlös aus den Zimmerverkauf'")));
	If vExistingRows.Count() > 0 Then
		vExistingStr = vExistingRows.Get(0);
	EndIf;
	// Put total sales
	If vExistingStr <> Undefined Then
		vExistingStr.SecondDateIndexValue = vRoomsIncome;
		vExistingStr.SecondDateIndexPresentation = ?(vRoomsIncome = 0, vRoomsIncome, cmFormatSum(vRoomsIncome, vReportingCurrency));
		vTempInd = IndexesTable.IndexOf(vExistingStr);
		IndexesTable.Get(vTempInd+1).SecondDateIndexValue = vOtherIncome;
		IndexesTable.Get(vTempInd+1).SecondDateIndexPresentation = ?(vOtherIncome = 0, vOtherIncome, cmFormatSum(vOtherIncome, vReportingCurrency));
		vTempInd = vTempInd + 1;
	EndIf;
	// Put sales by service types
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServiceSales.Period AS Period,
	|	ServiceSales.ServiceType AS ServiceType,
	|	SUM(ServiceSales.SumTurnover) AS SumTurnover,
	|	SUM(ServiceSales.SumWithoutVATTurnover) AS SumWithoutVATTurnover
	|FROM
	|	(SELECT
	|		ServiceSalesTurnovers.Period AS Period,
	|		ServiceSalesTurnovers.Service.ServiceType AS ServiceType,
	|		ServiceSalesTurnovers.SalesTurnover AS SumTurnover,
	|		ServiceSalesTurnovers.SalesWithoutVATTurnover AS SumWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel) AND NOT IsCorrection) AS ServiceSalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ServiceSalesForecastTurnovers.Period,
	|		ServiceSalesForecastTurnovers.Service.ServiceType,
	|		ServiceSalesForecastTurnovers.SalesTurnover,
	|		ServiceSalesForecastTurnovers.SalesWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(&qForecastPeriodFrom, &qForecastPeriodTo, Day, &qUseForecast AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesForecastTurnovers) AS ServiceSales
	|
	|GROUP BY
	|	ServiceSales.Period,
	|	ServiceSales.ServiceType
	|
	|ORDER BY
	|	Period,
	|	ServiceSales.ServiceType.SortCode";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qForecastPeriodFrom", Max(vForecastStartDate, vBegOfPeriod));
	vQry.SetParameter("qForecastPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qUseForecast", ?(vForecastStartDate > vEndOfPeriod, False, True));
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	vQry.SetParameter("qPeriodFrom", vBegOfPeriodNow);
	vQry.SetParameter("qPeriodTo", vEndOfPeriodNow);
	vQry.SetParameter("qForecastPeriodFrom", Max(vForecastStartDate, vBegOfPeriodNow));
	vQry.SetParameter("qForecastPeriodTo", vEndOfPeriodNow);
	vQry.SetParameter("qUseForecast", ?(vForecastStartDate > vEndOfPeriodNow, False, True));
	vQry.SetParameter("qHotel", Hotel);
	vQryResultNow = vQry.Execute().Unload();
	
	// Get list of service types
	vServiceTypes = vQryResult.Copy();
	vServiceTypes.GroupBy("ServiceType", );
	
	vServiceTypesNow = vQryResultNow.Copy();
	vServiceTypesNow.GroupBy("ServiceType", );	
	If vServiceTypes.Count() > 1 Then	
		// Put service types summary
		For Each vRow In vServiceTypes Do
			vServiceType = vRow.ServiceType;
			
			vExistingStr = Undefined;
			vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", Tabulation + "   "+vServiceType));
			If vExistingRows.Count() > 0 Then
				vExistingStr = vExistingRows.Get(0);
			EndIf;
			
			If vExistingStr = Undefined Then
				vTempInd = vTempInd + 1;
				vNewStr = IndexesTable.Insert(vTempInd);
				vNewStr.IndexName = Tabulation + "   " + vServiceType;
				vNewStr.IndexKey = vNewStr.IndexName;
				vNewStr.IndexValue = 0;
				vNewStr.IndexPresentation = 0;
				
				// Get records for the current payment method only
				vQrySubresult = vQryResult.FindRows(New Structure("ServiceType", vServiceType));
				GetQResultTableTotals(CompareDate, vQrySubresult, vQryResult, "SumTurnover, SumWithoutVATTurnover", False);
				If vWithVAT Then
					vServiceTypeIncome = cmCastToNumber(TotalPerDay.SumTurnover);
				Else
					vServiceTypeIncome = cmCastToNumber(TotalPerDay.SumWithoutVATTurnover);
				EndIf;
				vNewStr.SecondDateIndexValue = vServiceTypeIncome;
				vNewStr.SecondDateIndexPresentation = ?(vServiceTypeIncome = 0, vServiceTypeIncome, cmFormatSum(vServiceTypeIncome, vReportingCurrency));
			Else
				vQrySubresult = vQryResult.FindRows(New Structure("ServiceType", vServiceType));
				GetQResultTableTotals(CompareDate, vQrySubresult, vQryResult, "SumTurnover, SumWithoutVATTurnover", False);
				If vWithVAT Then
					vServiceTypeIncome = cmCastToNumber(TotalPerDay.SumTurnover);
				Else
					vServiceTypeIncome = cmCastToNumber(TotalPerDay.SumWithoutVATTurnover);
				EndIf;
				vExistingStr.SecondDateIndexValue = vServiceTypeIncome;
				vExistingStr.SecondDateIndexPresentation = ?(vServiceTypeIncome = 0, vServiceTypeIncome, cmFormatSum(vServiceTypeIncome, vReportingCurrency));
				vTempInd = IndexesTable.IndexOf(vExistingStr);
			EndIf;
		EndDo;
	EndIf; 
	vExistingStr = Undefined;
	vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", NStr("en='SEVICE TYPE TOTALS';ru='ИТОГИ ПО ТИПАМ УСЛУГ';de='ERGEBNISSE NACH DIENSTLEISTUNGSTYPEN'")));
	If vExistingRows.Count() > 0 Then
		vExistingStr = vExistingRows.Get(0);
	EndIf;
	
	If vExistingStr <> Undefined Then
		vExistingStr.SecondDateIndexValue = vTotalIncome;
		vExistingStr.SecondDateIndexPresentation = ?(vTotalIncome = 0, vTotalIncome, cmFormatSum(vTotalIncome, vReportingCurrency));
		vTempInd = IndexesTable.IndexOf(vExistingStr);
	EndIf;
	
	// 5. Payments summary indexes
	
	// Run query to get payments by payment method
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PaymentsTurnovers.PaymentMethod AS PaymentMethod,
	|	PaymentsTurnovers.Period AS Period,
	|	SUM(PaymentsTurnovers.SumTurnover) AS SumTurnover,
	|	SUM(PaymentsTurnovers.VATSumTurnover) AS VATSumTurnover
	|FROM
	|	AccumulationRegister.Payments.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS PaymentsTurnovers
	|GROUP BY
	|	PaymentsTurnovers.Period,
	|	PaymentsTurnovers.PaymentMethod
	|ORDER BY
	|	PaymentMethod,
	|	Period";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// Get list of payment methods
	vPaymentMethods = vQryResult.Copy();
	vPaymentMethods.GroupBy("PaymentMethod", );
	
	vExistingStr = Undefined;
	vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", NStr("en='PAYMENTS SUMMARY INDEXES';ru='СТАТИСТИКА ПО ПЛАТЕЖАМ';de='STATISTIK NACH ZAHLUNGEN'")));
	If vExistingRows.Count() > 0 Then
		vExistingStr = vExistingRows.Get(0);
		vTempInd = IndexesTable.IndexOf(vExistingStr);
	EndIf;
	
	// Put payment methods summary
	vTotalPaymentsPerDay = 0;
	For Each vRow In vPaymentMethods Do
		vPaymentMethod = vRow.PaymentMethod;
		If vPaymentMethod = Catalogs.PaymentMethods.Settlement Then
			Continue;
		EndIf;
		
		// Get records for the current payment method only
		vQrySubresult = vQryResult.FindRows(New Structure("PaymentMethod", vPaymentMethod));
		GetQResultTableTotals(CompareDate, vQrySubresult, vQryResult, "SumTurnover, VATSumTurnover", False);
		vSumTurnover = cmCastToNumber(TotalPerDay.SumTurnover);
		
		vExistingStr = Undefined;
		vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", vPaymentMethod.Description));
		If vExistingRows.Count() > 0 Then
			vExistingStr = vExistingRows.Get(0);
		EndIf;
		If vExistingStr = Undefined Then
			vTempInd = vTempInd + 1;
			vNewStr = IndexesTable.Insert(vTempInd);
			vNewStr.IndexName = Tabulation+vPaymentMethod;
			vNewStr.IndexKey = vPaymentMethod;
			vNewStr.IndexValue = 0;
			vNewStr.IndexPresentation = 0;
			vNewStr.SecondDateIndexValue = vSumTurnover;
			vNewStr.SecondDateIndexPresentation = ?(vSumTurnover = 0, vSumTurnover, cmFormatSum(vSumTurnover, vReportingCurrency));
		Else
			vExistingStr.SecondDateIndexValue = vSumTurnOver;
			vExistingStr.SecondDateIndexPresentation = ?(vSumTurnOver = 0, vSumTurnOver, cmFormatSum(vSumTurnOver, vReportingCurrency));
			IndexesTable.IndexOf(vExistingStr);
		EndIf;
		vTotalPaymentsPerDay = vTotalPaymentsPerDay + cmCastToNumber(TotalPerDay.SumTurnover);
	EndDo;
	
	// Payments footer
	vExistingStr = Undefined;
	vExistingRows = IndexesTable.FindRows(New Structure("IndexKey", Tabulation + NStr("en='Total payments';ru='Всего платежей';de='Gesamt Zahlungen'")));
	If vExistingRows.Count() > 0 Then
		vExistingStr = vExistingRows.Get(0);
	EndIf;
	If vExistingStr <> Undefined Then
		vExistingStr.SecondDateIndexValue = vTotalPaymentsPerDay;
		vExistingStr.SecondDateIndexPresentation = ?(vTotalPaymentsPerDay = 0, vTotalPaymentsPerDay, cmFormatSum(vTotalPaymentsPerDay, vReportingCurrency));
	EndIf;
	For vInd=1 to IndexesTable.Count()-1 Do
		If (IndexesTable.Get(vInd).IndexPresentation = "") or (IndexesTable.Get(vInd).SecondDateIndexPresentation = "") Then
			Continue;
		Else
			If IndexesTable.Get(vInd).IndexValue < IndexesTable.Get(vInd).SecondDateIndexValue Then
				IndexesTable.Get(vInd).SecondDateIcon = PictureLib.ArrowRedDown;
			ElsIf IndexesTable.Get(vInd).IndexValue > IndexesTable.Get(vInd).SecondDateIndexValue Then
				IndexesTable.Get(vInd).SecondDateIcon = PictureLib.ArrowGreenUp;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // GetCompareRooms

// ------------------------------------------------------------------------------------------------- 
&AtServer
Function GetQuarterNum(pQ)
	If pQ = "1" Then
		Return "I";
	ElsIf pQ = "2" Then
		Return "II";
	ElsIf pQ = "3" Then
		Return "III";
	ElsIf pQ = "4" Then
		Return "IV";
	Else
		Return pQ;
	EndIf;
EndFunction // GetQuarterNum

// -------------------------------------------------------------------------------------------------
&AtServer
Procedure ChartBuild(pUseComparePeriod = False)
	vQrySalesArray = New Array;
	vQryRoomsForSaleArray = New Array;
	vQryRoomsIncomeArray = New Array;
	vQryRoomsRentedArray = New Array;
	vInRooms = True;
	vWithVAT = True;
	If ValueIsFilled(Hotel) Then
		vInRooms = Not Hotel.ShowReportsInBeds;
		vWithVAT = Hotel.ShowSalesInReportsWithVAT;
	EndIf;
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	
	// Check period choosen
	If Not pUseComparePeriod Then
		If Items.PeriodDay.Visible Then
			vBegOfPeriod = BegOfMonth(PeriodTo);
			vEndOfPeriod = EndOfMonth(PeriodTo);
			vPeriodicity = "Day";
		ElsIf Items.SelQuarter.Visible Then
			vBegOfPeriod = BegOfQuarter(CompositionDate);
			vEndOfPeriod = EndOfQuarter(CompositionDate);
			vPeriodicity = "Month";
			vFormat = SelQuarter + " " + SelYear + NStr("en=' year';ru=' года';de=' Jahr'");
		ElsIf Items.SelMonth.Visible Then
			vBegOfPeriod = BegOfMonth(CompositionDate);
			vEndOfPeriod = EndOfMonth(CompositionDate);
			vPeriodicity = "Day";
		Else
			vBegOfPeriod = BegOfYear(CompositionDate);
			vEndOfPeriod = EndOfYear(CompositionDate);
			vPeriodicity = "Month";
			vFormat = SelYear + NStr("en=' year';ru=' год';de=' Jahr'");
		EndIf;
		
		If vPeriodicity = "Day" Then
			Items.ChartGist.Title = NStr("en='Rented rooms';ru='Продано номеров';de='Verkaufte Zimmern'") + " ("+Format(CompositionDate, NStr("en = 'L = en; '; de = 'L = de; '; ru = 'L = ru; '")+ "DF = 'MMMM yyyy'")+NStr("ru=' год';de=' Jahr';en=' year'")+")";
			Items.ChartForSale.Title = NStr("en='Room Revenue';ru='Доход';de='Erlös'") + " ("+Format(CompositionDate, NStr("en = 'L = en; '; de = 'L = de; '; ru = 'L = ru; '")+ "DF = 'MMMM yyyy'")+NStr("ru=' год';de=' Jahr';en = ' year'")+")";
		ElsIf vPeriodicity = "Month" Then
			Items.ChartGist.Title = NStr("en='Rented rooms';ru='Продано номеров';de='Verkaufte Zimmern'") + " ("+vFormat+")";
			Items.ChartForSale.Title = NStr("en='Room Revenue';ru='Доход';de='Erlös'") + " ("+vFormat+")";
		EndIf;
		
		// Clear charts
		ChartForSale.Clear();
		ChartForSale.ChartType = ChartType.Column;
		ChartForSale.RefreshEnabled = True;
		ChartForSale.Series.Add();
		ChartForSale.Series[0].Marker = ChartMarkerType.None;
		ChartForSale.Series[0].Text = Items.ChartForSale.Title;
		
		ChartGist.Clear();
		ChartGist.ChartType = ChartType.Column;
		ChartGist.Series.Add();
		ChartGist.Series[0].Text = Items.ChartGist.Title;
		ChartGist.Series.Add();
		ChartGist.Series[1].Indicator=True;
		ChartGist.Series[1].Marker = ChartMarkerType.None;
		If vPeriodicity = "Day" Then
			ChartGist.Series[1].Text = NStr("en='Rooms for sale';ru='Номера к продаже';de='Zimmer für den Verkauf'") + " ("+Format(CompositionDate, NStr("en = 'L = en; '; de = 'L = de; '; ru = 'L = ru; '")+ "DF = 'MMMM yyyy'")+NStr("ru=' год';de=' Jahr';en=' year'")+")";
		ElsIf vPeriodicity = "Month" Then
			ChartGist.Series[1].Text = NStr("en='Rooms for sale';ru='Номера к продаже';de='Zimmer für den Verkauf'") + " ("+vFormat+")";
		EndIf;
		ChartGist.PlotArea.ScaleColor = WebColors.WhiteSmoke;
		ChartGist.PlotArea.BackColor = WebColors.White;
		ChartGist.LegendArea.BackColor = WebColors.White;
		ChartGist.TitleArea.BackColor = WebColors.White;
		
		ChartForSale.TitleArea.BackColor  = WebColors.White;
		ChartForSale.LegendArea.BackColor  = WebColors.White;
		ChartForSale.PlotArea.BackColor  = WebColors.White;
		ChartForSale.PlotArea.ScaleColor  = WebColors.WhiteSmoke;
		
		ChartGist.Series[0].Color = WebColors.DeepSkyBlue;
		ChartGist.Series[1].Color = WebColors.IndianRed;
		ChartForSale.Series[0].Color = WebColors.DodgerBlue;
	Else
		If Items.PeriodDay.Visible Then
			vBegOfPeriod = BegOfMonth(CompareCompositionDate);
			vEndOfPeriod = EndOfMonth(CompareCompositionDate);
			vPeriodicity = "Day";
		ElsIf Items.SelQuarter.Visible Then
			vBegOfPeriod = BegOfQuarter(CompareCompositionDate);
			vEndOfPeriod = EndOfQuarter(CompareCompositionDate);
			vPeriodicity = "Month";
			vFormat = GetQuarterNum(Format(CompareCompositionDate, "DF=q")) + NStr("en=' quarter '; ru=' квартал '; de=' Quartal '") + Format(Year(CompareCompositionDate), "ND=4; NFD=; NG=") + NStr("en=' year';ru=' года';de=' Jahr'");
		ElsIf Items.SelMonth.Visible Then
			vBegOfPeriod = BegOfMonth(CompareCompositionDate);
			vEndOfPeriod = EndOfMonth(CompareCompositionDate);
			vPeriodicity = "Day";
		Else
			vBegOfPeriod = BegOfYear(CompareCompositionDate);
			vEndOfPeriod = EndOfYear(CompareCompositionDate);
			vPeriodicity = "Month";
			vFormat = Format(Year(CompareCompositionDate), "ND=4; NFD=; NG=") + NStr("en=' year';ru=' год';de=' Jahr'");
		EndIf;
		
		// Compare title
		vChartGistCompareTitle = "";
		vChartForSaleCompareTitle = "";
		If vPeriodicity = "Day" Then
			vChartGistCompareTitle = NStr("en='Rented rooms';ru='Продано номеров';de='Verkaufte Zimmern'") + " ("+Format(CompareCompositionDate, NStr("en = 'L = en; '; de = 'L = de; '; ru = 'L = ru; '")+ "DF = 'MMMM yyyy'")+NStr("ru=' год';de=' Jahr';en=' year'")+")";
			vChartForSaleCompareTitle = NStr("en='Room Revenue';ru='Доход';de='Erlös'") + " ("+Format(CompareCompositionDate, NStr("en = 'L = en; '; de = 'L = de; '; ru = 'L = ru; '")+ "DF = 'MMMM yyyy'")+NStr("ru=' год';de=' Jahr';en = ' year'")+")";
		ElsIf vPeriodicity = "Month" Then
			vChartGistCompareTitle = NStr("en='Rented rooms';ru='Продано номеров';de='Verkaufte Zimmern'") + " ("+vFormat+")";
			vChartForSaleCompareTitle = NStr("en='Room Revenue';ru='Доход';de='Erlös'") + " ("+vFormat+")";
		EndIf;
		
		// Add compare series
		ChartForSale.Series.Add();
		ChartForSale.Series[ChartForSale.SeriesCount - 1].Marker = ChartMarkerType.None;
		ChartForSale.Series[ChartForSale.SeriesCount - 1].Text = vChartForSaleCompareTitle;
		ChartForSale.Series[ChartForSale.SeriesCount - 1].Color = WebColors.BlueViolet;
		
		ChartGist.Series.Add();
		ChartGist.Series[ChartGist.SeriesCount - 1].Text = vChartGistCompareTitle;
		ChartGist.Series[ChartGist.SeriesCount - 1].Color = WebColors.DarkBlue;
	EndIf;
	
	// Run query to get room sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSales.Period AS Period,
	|	SUM(ISNULL(RoomSales.SalesTurnover, 0)) AS SalesTurnover,
	|	SUM(ISNULL(RoomSales.SalesWithoutVATTurnover, 0)) AS SalesWithoutVATTurnover,
	|	SUM(ISNULL(RoomSales.RoomRevenueTurnover, 0)) AS RoomRevenueTurnover,
	|	SUM(ISNULL(RoomSales.RoomRevenueWithoutVATTurnover, 0)) AS RoomRevenueWithoutVATTurnover,
	|	SUM(ISNULL(RoomSales.RoomsRentedTurnover, 0)) AS RoomsRentedTurnover,
	|	SUM(ISNULL(RoomSales.BedsRentedTurnover, 0)) AS BedsRentedTurnover
	|FROM (
	|SELECT
	|	BEGINOFPERIOD(RoomSalesTurnovers.Period, "+vPeriodicity+") AS Period,
	|	ISNULL(RoomSalesTurnovers.SalesTurnover, 0) AS SalesTurnover,
	|	ISNULL(RoomSalesTurnovers.SalesWithoutVATTurnover, 0) AS SalesWithoutVATTurnover,
	|	ISNULL(RoomSalesTurnovers.RoomRevenueTurnover, 0) AS RoomRevenueTurnover,
	|	ISNULL(RoomSalesTurnovers.RoomRevenueWithoutVATTurnover, 0) AS RoomRevenueWithoutVATTurnover,
	|	ISNULL(RoomSalesTurnovers.RoomsRentedTurnover, 0) AS RoomsRentedTurnover,
	|	ISNULL(RoomSalesTurnovers.BedsRentedTurnover, 0) AS BedsRentedTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, "+vPeriodicity+", Hotel IN HIERARCHY (&qHotel) AND NOT IsCorrection) AS RoomSalesTurnovers
	|UNION ALL
	|SELECT
	|	BEGINOFPERIOD(RoomSalesTurnoversForecast.Period, "+vPeriodicity+"),
	|	ISNULL(RoomSalesTurnoversForecast.SalesTurnover, 0),
	|	ISNULL(RoomSalesTurnoversForecast.SalesWithoutVATTurnover, 0),
	|	ISNULL(RoomSalesTurnoversForecast.RoomRevenueTurnover, 0),
	|	ISNULL(RoomSalesTurnoversForecast.RoomRevenueWithoutVATTurnover, 0),
	|	ISNULL(RoomSalesTurnoversForecast.RoomsRentedTurnover, 0),
	|	ISNULL(RoomSalesTurnoversForecast.BedsRentedTurnover, 0)
	|FROM
	|	AccumulationRegister.SalesForecast.Turnovers(&qForecastPeriodFrom, &qForecastPeriodTo, "+vPeriodicity+", &qUseForecast AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesTurnoversForecast) AS RoomSales
	|GROUP BY
	|	RoomSales.Period
	|ORDER BY
	|	Period";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qForecastPeriodFrom", Max(vForecastStartDate, vBegOfPeriod));
	vQry.SetParameter("qForecastPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qUseForecast", ?(vForecastStartDate > vEndOfPeriod, False, True));
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// <Counter>
	vDateNow = vBegOfPeriod;
	vQryCount = vQryResult.Count();
	vIndCount = 0;
	For Each vQryResultRow In vQryResult Do
		vIndCount = vIndCount + 1;
		If vPeriodicity = "Day" Then
			If vQryResultRow.Period>vDateNow Then
				vDaysCount = (vQryResultRow.Period - vDateNow)/86400;
				For vDays = 0 To vDaysCount-1 Do
					vQryRoomsRentedArray.Add(0);
					vQryRoomsRentedArray.Add(vDateNow+vDays*86400);
					vQryRoomsIncomeArray.Add(0);
					vQryRoomsIncomeArray.Add(vDateNow+vDays*86400);
				EndDo;
			EndIf;
		ElsIf vPeriodicity = "Month" Then
			If Month(vQryResultRow.Period)>Month(vDateNow) Then
				vMonthsCount = Month(vQryResultRow.Period) - Month(vDateNow);
				For vMonths = 0 To vMonthsCount-1 Do
					vQryRoomsRentedArray.Add(0);
					vQryRoomsRentedArray.Add(AddMonth(vDateNow, vMonths));
					vQryRoomsIncomeArray.Add(0);
					vQryRoomsIncomeArray.Add(AddMonth(vDateNow, vMonths));
				EndDo;
			EndIf;
		EndIf;
		vQryRoomsRentedArray.Add(cmCastToNumber(vQryResultRow.RoomsRentedTurnover));
		vQryRoomsRentedArray.Add(vQryResultRow.Period);
		If vWithVAT Then
			vRoomsIncome = cmCastToNumber(vQryResultRow.RoomRevenueTurnover);
			vQryRoomsIncomeArray.Add(vRoomsIncome);
			vQryRoomsIncomeArray.Add(vQryResultRow.Period);
		Else
			vRoomsIncome = cmCastToNumber(vQryResultRow.RoomRevenueWithoutVATTurnover);
			vQryRoomsIncomeArray.Add(vRoomsIncome);
			vQryRoomsIncomeArray.Add(vQryResultRow.Period);
		EndIf;
		If vPeriodicity = "Day" Then
			vDateNow = vQryResultRow.Period+86400;
		ElsIf vPeriodicity = "Month" Then
			vDateNow = AddMonth(vQryResultRow.Period, 1);
		EndIf;
	EndDo;	
	// </Counter>
	
	// Run query to get rooms available
	If Not pUseComparePeriod Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CASE
		|		WHEN &qByMonth
		|			THEN BEGINOFPERIOD(RoomInventoryBalanceAndTurnovers.Period, MONTH)
		|		ELSE RoomInventoryBalanceAndTurnovers.Period
		|	END AS Period,
		|	SUM(RoomInventoryBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
		|	SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRoomsClosingBalance,
		|	SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBedsClosingBalance,
		|	-SUM(RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlockedClosingBalance,
		|	-SUM(RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlockedClosingBalance
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalanceAndTurnovers
		|
		|GROUP BY
		|	CASE
		|		WHEN &qByMonth
		|			THEN BEGINOFPERIOD(RoomInventoryBalanceAndTurnovers.Period, MONTH)
		|		ELSE RoomInventoryBalanceAndTurnovers.Period
		|	END
		|
		|ORDER BY
		|	Period";
		vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
		vQry.SetParameter("qPeriodTo", vEndOfPeriod);
		vQry.SetParameter("qByMonth", ?(vPeriodicity = "Month", True, False));
		vQry.SetParameter("qHotel", Hotel);
		vQryResult = vQry.Execute().Unload();
		
		vDateNow = vBegOfPeriod;
		vQryCount = vQryResult.Count();
		vIndCount = 0;
		For Each vQryResultRow in vQryResult Do
			vTotalRooms = cmCastToNumber(vQryResultRow.TotalRoomsClosingBalance);		
			vBlockedRooms = cmCastToNumber(vQryResultRow.RoomsBlockedClosingBalance);
			vRoomsForSale=vTotalRooms-vBlockedRooms;
			vIndCount = vIndCount + 1;
			If vPeriodicity = "Day" Then
				If vQryResultRow.Period>vDateNow Then
					vDaysCount = (vQryResultRow.Period - vDateNow)/86400;
					For vDays = 0 To vDaysCount-1 Do
						vQryRoomsForSaleArray.Add(0);
						vQryRoomsForSaleArray.Add(vDateNow+vDays*86400);
					EndDo;
				EndIf;
			ElsIf vPeriodicity = "Month" Then
				If Month(vQryResultRow.Period)>Month(vDateNow) Then
					vMonthsCount = Month(vQryResultRow.Period) - Month(vDateNow);
					For vMonths = 0 To vMonthsCount-1 Do
						vQryRoomsForSaleArray.Add(0);
						vQryRoomsForSaleArray.Add(AddMonth(vDateNow, vMonths));
					EndDo;
				EndIf;
			EndIf;
			vQryRoomsForSaleArray.Add(vRoomsForSale);
			vQryRoomsForSaleArray.Add(vQryResultRow.Period);
			If vPeriodicity = "Day" Then
				If (vQryResultRow.Period<(vEndOfPeriod)) and (vQryCount=vIndCount) Then
					vDaysCount = (vEndOfPeriod - vQryResultRow.Period)/86400;
					For vDays = 1 To vDaysCount Do
						vQryRoomsForSaleArray.Add(0);
						vQryRoomsForSaleArray.Add(vDateNow+vDays*86400);
					EndDo;
				EndIf;
			ElsIf vPeriodicity = "Month" Then
				If (Month(vQryResultRow.Period)<Month(vEndOfPeriod)) and (vQryCount=vIndCount) Then
					vMonthsCount = Month(vQryResultRow.Period) - Month(vDateNow);
					For vMonths = 0 To vMonthsCount-1 Do
						vQryRoomsForSaleArray.Add(0);
						vQryRoomsForSaleArray.Add(AddMonth(vDateNow, vMonths));
					EndDo;
				EndIf;
			EndIf;
			If vPeriodicity = "Day" Then
				vDateNow = vQryResultRow.Period+86400;
			ElsIf vPeriodicity = "Month" Then
				vDateNow = AddMonth(vQryResultRow.Period, 1);
			EndIf;	
		EndDo;
		
		If (vQryRoomsRentedArray.Count()=0) or (vQryRoomsIncomeArray.Count()=0) Then
			ChartGist.Clear();
		Else
			If vQryRoomsRentedArray.Count()<vQryRoomsIncomeArray.Count() Then
				vMinCount = vQryRoomsRentedArray.Count();
			Else
				vMinCount = vQryRoomsIncomeArray.Count();
			EndIf;
			For vInd=0 To (vMinCount/2-1) Do
				vNewPoint = ChartGist.Points.Add(String(Format(vQryRoomsIncomeArray.Get(vInd*2+1), ?(vPeriodicity = "Day", "DF = 'dd'", "DF = 'MMMM'"))));
				ChartGist.SetValue(vNewPoint,0,vQryRoomsRentedArray.Get(vInd*2));
				ChartGist.SetValue(vNewPoint,1,vQryRoomsForSaleArray.Get(vInd*2));
				
				vNewPoint = ChartForSale.Points.Add(String(Format(vQryRoomsIncomeArray.Get(vInd*2+1), ?(vPeriodicity = "Day", "DF = 'dd'", "DF = 'MMMM'"))));
				ChartForSale.SetValue(vNewPoint,0,vQryRoomsIncomeArray.Get(vInd*2));
			EndDo;
		EndIf;
	Else
		If Not (vQryRoomsRentedArray.Count()=0) And Not (vQryRoomsIncomeArray.Count()=0) Then
			vMinCount = vQryRoomsIncomeArray.Count();
			For vInd=0 To (vMinCount/2-1) Do
				vPointName = Format(vQryRoomsIncomeArray.Get(vInd*2+1), ?(vPeriodicity = "Day", "DF = 'dd'", "DF = 'MMMM'"));
				For Each vPoint In ChartGist.Points Do
					If vPoint.Text = vPointName Then
						ChartGist.SetValue(vPoint,2,vQryRoomsRentedArray.Get(vInd*2));
						Break;
					EndIf;
				EndDo;
				For Each vPoint In ChartForSale.Points Do
					If vPoint.Text = vPointName Then
						ChartForSale.SetValue(vPoint,1,vQryRoomsIncomeArray.Get(vInd*2));
						Break;
					EndIf;
				EndDo;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // ChartBuild

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure GetReport()
	vParameters = New Structure("Hotel, BegOfPeriod, EndOfPeriod");
	If ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("0").Value Then
		vParameters.BegOfPeriod = BegOfDay(PeriodTo);
		vParameters.EndOfPeriod = EndOfDay(PeriodTo);
	ElsIf ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("1").Value Then
		vParameters.BegOfPeriod = BegOfMonth(CompositionDate);
		vParameters.EndOfPeriod = EndOfMonth(CompositionDate);
	ElsIf ChoosePeriod = Items.ChoosePeriod.ChoiceList.FindByValue("2").Value Then
		vParameters.BegOfPeriod = BegOfQuarter(CompositionDate);
		vParameters.EndOfPeriod = EndOfQuarter(CompositionDate);
	Else 
		vParameters.BegOfPeriod = BegOfYear(CompositionDate);
		vParameters.EndOfPeriod = EndOfYear(CompositionDate);
	EndIf;

	vParameters.Hotel = Hotel;
	GetForm("Report.MainMenuSummaryIndexesReport.Form.ReportForm", vParameters).Open();
EndProcedure // GetReport

// -------------------------------------------------------------------------------------------------
&AtServer
Procedure ChangeAttributesAtServer()
	CommandBarLocation = FormCommandBarLabelLocation.Top;
	Items.HeadPicture.Visible = False;  
	Items.CommandPanelGroup.Visible = False;
	vStructure = New Structure("Type, PagesRepresentation", FormGroupType.Pages, FormPagesRepresentation.Swipe);		
	tcOnServer.cmCreateItem(ThisForm, ThisForm, "Pages", "FormGroup", vStructure);
	vStructure = New Structure("Type", FormGroupType.Page);		
	tcOnServer.cmCreateItem(ThisForm, Items["FormGroupPages"], "PageIndex", "FormGroup", vStructure);
	vStructure = New Structure("Type", FormGroupType.Page);		
	tcOnServer.cmCreateItem(ThisForm, Items["FormGroupPages"], "PageChartGist", "FormGroup", vStructure);
	vStructure = New Structure("Type", FormGroupType.Page);		
	tcOnServer.cmCreateItem(ThisForm, Items["FormGroupPages"], "PageChartForSale", "FormGroup", vStructure);
	vCommand = Commands.Add("ShowFiletGroup");
	vCommand.Action = "ShowFiletGroup";
	vStructure = New Structure("CommandName, Representation, Picture, LocationInCommandBar", "ShowFiletGroup", ButtonRepresentation.Picture, PictureLib.FilterCriterion, ButtonLocationInCommandBar.InCommandBarAndInAdditionalSubmenu);
	tcOnServer.cmCreateItem(ThisForm, CommandBar, "ShowFiletGroup", "FormButton", vStructure);
	Items.Move(Items.CommandRefresh, CommandBar);
	Items.Move(Items.ReportCaller, CommandBar);
	Items.Move(Items.Help, CommandBar);
	Items.CommandRefresh.DefaultButton = True;
	Items.CommandRefresh.Representation = ButtonRepresentation.Picture;
	Items.ReportCaller.LocationInCommandBar = ButtonLocationInCommandBar.InAdditionalSubmenu;
	Items.Move(Items.MainTable, Items["FormGroupPageIndex"]);
	Items.Move(Items.ChartGist, Items["FormGroupPageChartGist"]);
	Items.Move(Items.ChartForSale, Items["FormGroupPageChartForSale"]);
	Items.GroupIndexes.Visible = False;
	Items.TabulationGroup.Visible = False;
	For Each vItem In Items.MainTableContextMenu.ChildItems Do
		vItem.Visible = False;
	EndDo;
EndProcedure // ChangeAttributesAtServer

#EndRegion 

#Region Initialize

// -------------------------------------------------------------------------------------------------
Tabulation = "       ";

#EndRegion
