
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
	GetRooms("FirstColumn");
	
	// Build chart
	ChartBuild();
	
	// Set compare columns visibility off
	Items.ColumnSecondDateIndexPresentation.Visible = False;
	Items.ColumnIcon.Visible = False;
	
	#IF MobileClient Then
		ChangeAttributesAtServer();
	#ENDIF
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure ShowInBedsOnChange(pItem)
	CommandRefresh(Items.CommandRefresh);
EndProcedure

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure CompareDateOnChange(Item)
	ChartBuild(False);
	// Fill indexes for second date
	CompareCompositionDate = CompareDate;
	If ValueIsFilled(CompareDate) Then
		Items.ColumnSecondDateIndexPresentation.Title = Format(CompareDate, "DF=dd.MM.yyyy");
		GetRooms("SecondColumn");
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
			GetRooms("FirstRefresh");
			ChartBuild(True);
		Else
			GetRooms("FirstColumn");
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
			GetRooms("FirstRefresh");
			ChartBuild(True);
		Else
			GetRooms("FirstColumn");
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
			GetRooms("FirstRefresh");
			ChartBuild(True);
		Else
			GetRooms("FirstColumn");
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
			GetRooms("SecondColumn");
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
			GetRooms("SecondColumn");
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
			GetRooms("SecondColumn");
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
		GetRooms("SecondColumn");
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
		GetRooms("SecondColumn");
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
		GetRooms("FirstRefresh");
		ChartBuild(True);
	Else
		GetRooms("FirstColumn");
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
		GetRooms("FirstColumn");
		GetRooms("SecondColumn");
		ChartBuild(True);
	Else
		GetRooms("FirstColumn");
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
		GetRooms("FirstRefresh");
		GetRooms("SecondColumn");
		ChartBuild(True);
	Else
		GetRooms("FirstRefresh");
	EndIf;
EndProcedure // CommandRefresh

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandGenerateReports(pCommand)
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
EndProcedure // CommandGenerateReports

#EndRegion

#Region Private

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
&AtServerNoContext
Function GetAllDaysQResultTableTotals(pPeriod, pTbl, pTemplate, pResources, pConvertToTurnover = True)
	// Convert pTbl to the value table if necessary
	vTbl = pTemplate.CopyColumns();
	vCurDate = '00010101';
	vCurTblRow = Undefined;
	For Each vRow In pTbl Do
		If vCurDate = '00010101' Then
			vCurDate = vRow.Period;
			vTblRow = vTbl.Add();
			FillPropertyValues(vTblRow, vRow);
			vCurTblRow = vRow;
		Else
			While (vCurDate + 24*3600) < vRow.Period Do
				vTblRow = vTbl.Add();
				FillPropertyValues(vTblRow, vCurTblRow);
				vTblRow.Period = vCurDate + 24*3600;
				vCurDate = vCurDate + 24*3600;
			EndDo;
			vCurDate = vRow.Period;
			vTblRow = vTbl.Add();
			FillPropertyValues(vTblRow, vRow);
			vCurTblRow = vRow;
		EndIf;
	EndDo;
	
	If vTbl.Count() = 0 Then
		vTbl.Add();
	EndIf;
	
	vTbl.GroupBy(, pResources);
	Return vTbl.Get(0);
EndFunction // GetQResultTableTotals

// -------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetQResultTableTotals(pPeriod, pTbl, pTemplate, pResources, pConvertToTurnover = True)
	// Convert pTbl to the value table if necessary
	vTbl = pTbl.Copy();
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
	Return vTbl.Get(0);
EndFunction // GetQResultTableTotals

// -------------------------------------------------------------------------------------------------
&AtServerNoContext
Function OutputWithCurrency(pValue)
	Return ?(pValue = 0, pValue, cmFormatSum(pValue, SessionParameters.CurrentHotel.ReportingCurrency));	
EndFunction // OutputWithCurrency

// -------------------------------------------------------------------------------------------------
&AtServerNoContext
Procedure InsertTableValues(pInsArea, pTmpInd, pTable, pText = Undefined, pValue, pPresentation = Undefined)	
   	If pPresentation = Undefined Then
		pPresentation = pValue;
	EndIf;
	
	If pInsArea = "FirstColumn" Then
		pNewStr = pTable.Add();
		pNewStr.IndexName = "       " + NStr(pText);
		pNewStr.IndexKey = pNewStr.IndexName;
		pNewStr.IndexValue = pValue;
		pNewStr.IndexPresentation = pPresentation;	
	ElsIf pInsArea = "FirstRefresh" Then
		pStr = pTable.Get(pTmpInd);
		pStr.IndexValue = pValue;
		pStr.IndexPresentation = pPresentation;
		pTmpInd = pTmpInd + 1;
	Else 
		pStr = pTable.Get(pTmpInd);
		pStr.SecondDateIndexValue = pValue;
		pStr.SecondDateIndexPresentation = pPresentation;
		pTmpInd = pTmpInd + 1;
	Endif;	
EndProcedure // InsertFirstColumn

// -------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GenerateSubQuery(pQuery, pParam)
	vQrySubResultArray = pQuery.FindRows(pParam);
	vQrySubResult = pQuery.CopyColumns();
	For Each vRow In vQrySubResultArray Do
		vTabRow = vQrySubResult.Add();
		FillPropertyValues(vTabRow, vRow);
	EndDo;
	Return vQrySubResult; 
EndFunction // GenerateSubQuery

// -------------------------------------------------------------------------------------------------  
&AtServerNoContext
Procedure CalculateCompareIcons(pTable);
// Insert compare results into column CompareIcon
	For vRow = 1 to pTable.Count() - 1 Do
		If (pTable.Get(vRow).IndexPresentation = "") Or (pTable.Get(vRow).SecondDateIndexPresentation = "") Then
			Continue;
		Else
			If pTable.Get(vRow).IndexValue < pTable.Get(vRow).SecondDateIndexValue Then
				pTable.Get(vRow).SecondDateIcon = PictureLib.ArrowRedDown;
			ElsIf pTable.Get(vRow).IndexValue > pTable.Get(vRow).SecondDateIndexValue Then
				pTable.Get(vRow).SecondDateIcon = PictureLib.ArrowGreenUp;
			ElsIf pTable.Get(vRow).IndexValue = pTable.Get(vRow).SecondDateIndexValue Then
				pTable.Get(vRow).SecondDateIcon = PictureLib.YellowCube;	
			EndIf;
		EndIf;
	EndDo;
EndProcedure // CalculateCompareIcons

// -------------------------------------------------------------------------------------------------
&AtServer
Procedure GetRooms(pInsArea)
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	
	// Clear pages
	If pInsArea = "FirstColumn" And IndexesTable.Count() > 0 Then
		IndexesTable.Clear();
	EndIf;
	
	// Check period choosen
	If pInsArea = "SecondColumn" Then
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
	Else
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
	EndIf;
	
	// Initialize typesof data to show
	vInRooms = True;
	vWithVAT = True;
	If ValueIsFilled(Hotel) Then
		vInRooms = Not Hotel.ShowReportsInBeds;
		vWithVAT = Hotel.ShowSalesInReportsWithVAT;
	EndIf;
	
	If Not vInRooms Then
		Items.ShowIn.Title = NStr("en='Generate for Rooms';ru='Сформировать для номеров';de='STATISTIK NACH AUSLASTUNG'");
	Endif;
	
	// Setup Rooms/Beds option
	If ShowIn And vInRooms Then
		vInRooms = False;
	ElsIf ShowIn And Not vInRooms Then
		vInRooms = True;
	EndIf;
	
	If Not ValueIsFilled(Hotel) Then
		Return;
	EndIf;
	
	// Run query to get total number of rooms, rooms blocked, vacant number of rooms
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	RoomInventoryBalanceAndTurnovers.Period AS Period,
	|	SUM(RoomInventoryBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRoomsClosingBalance,
	|	SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBedsClosingBalance
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
	
	// Total Rooms in Hotel
	vResources = "TotalRoomsClosingBalance, TotalBedsClosingBalance";
	vTotalValues = GetQResultTableTotals(PeriodTo, vQryResult, vQryResult, vResources);
	vTotalRooms = cmCastToNumber(vTotalValues.TotalRoomsClosingBalance);
	vTotalBeds = cmCastToNumber(vTotalValues.TotalBedsClosingBalance);	
	
	// Run query to get room sales, numbers of guest days, checked-in rooms, checked-in guests, rooms rented
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	SalesTurnovers.Period AS Period,
	|	SalesTurnovers.RoomRateIsComplimentary AS RoomRateIsComplimentary,
	|	SalesTurnovers.RoomRateIsHouseUse AS RoomRateIsHouseUse,
	|	SalesTurnovers.ClientIsInWhiteList AS ClientIsInWhiteList,
	|	SalesTurnovers.ClientDiscountCardDescription AS ClientDiscountCardDescription,
	|	SalesTurnovers.GuestGroupGroupTypeDescription AS GuestGroupGroupTypeDescription,
	|	SalesTurnovers.ParentDocNumberOfAdults AS ParentDocNumberOfAdults,
	|	SalesTurnovers.ParentDocNumberOfTeenagers AS ParentDocNumberOfTeenagers,
	|	SalesTurnovers.ParentDocNumberOfChildren AS ParentDocNumberOfChildren,
	|	SalesTurnovers.ParentDocNumberOfInfants AS ParentDocNumberOfInfants,
	|	SalesTurnovers.AgentDescription AS AgentDescription,
	|	SalesTurnovers.ParentDocIsByReservation AS ParentDocIsByReservation,
	|	SalesTurnovers.ParentDocGuaranteeTypeDescription AS ParentDocGuaranteeTypeDescription,
	|	SUM(SalesTurnovers.SalesTurnover) AS SalesTurnover,
	|	SUM(SalesTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(SalesTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(SalesTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(SalesTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(SalesTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(SalesTurnovers.BedsRentedTurnover) AS BedsRentedTurnover,
	|	SUM(SalesTurnovers.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|	SUM(SalesTurnovers.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
	|	SUM(SalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		SalesTurnovers.Period AS Period,
	|		SalesTurnovers.RoomRate.IsComplimentary AS RoomRateIsComplimentary,
	|		SalesTurnovers.RoomRate.IsHouseUse AS RoomRateIsHouseUse,
	|		SalesTurnovers.Client.IsInWhiteList AS ClientIsInWhiteList,
	|		SalesTurnovers.Client.DiscountCard.Description AS ClientDiscountCardDescription,
	|		SalesTurnovers.GuestGroup.GroupType.Description AS GuestGroupGroupTypeDescription,
	|		SalesTurnovers.ParentDoc.NumberOfAdults AS ParentDocNumberOfAdults,
	|		SalesTurnovers.ParentDoc.NumberOfTeenagers AS ParentDocNumberOfTeenagers,
	|		SalesTurnovers.ParentDoc.NumberOfChildren AS ParentDocNumberOfChildren,
	|		SalesTurnovers.ParentDoc.NumberOfInfants AS ParentDocNumberOfInfants,
	|		SalesTurnovers.Agent.Description AS AgentDescription,
	|		SalesTurnovers.ParentDoc.IsByReservation AS ParentDocIsByReservation,
	|		SalesTurnovers.ParentDoc.GuaranteeType.Description AS ParentDocGuaranteeTypeDescription,
	|		SUM(SalesTurnovers.SalesTurnover) AS SalesTurnover,
	|		SUM(SalesTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|		SUM(SalesTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|		SUM(SalesTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|		SUM(SalesTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
	|		SUM(SalesTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|		SUM(SalesTurnovers.BedsRentedTurnover) AS BedsRentedTurnover,
	|		SUM(SalesTurnovers.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|		SUM(SalesTurnovers.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
	|		SUM(SalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel) AND NOT IsCorrection) AS SalesTurnovers
	|
	|	GROUP BY
	|		SalesTurnovers.Period,
	|		SalesTurnovers.RoomRate.IsComplimentary,
	|		SalesTurnovers.RoomRate.IsHouseUse,
	|		SalesTurnovers.Client.IsInWhiteList,
	|		SalesTurnovers.Client.DiscountCard.Description,
	|		SalesTurnovers.GuestGroup.GroupType.Description,
	|		SalesTurnovers.ParentDoc.NumberOfAdults,
	|		SalesTurnovers.ParentDoc.NumberOfTeenagers,
	|		SalesTurnovers.ParentDoc.NumberOfChildren,
	|		SalesTurnovers.ParentDoc.NumberOfInfants,
	|		SalesTurnovers.Agent.Description,
	|		SalesTurnovers.ParentDoc.IsByReservation,
	|		SalesTurnovers.ParentDoc.GuaranteeType.Description
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTurnovers.Period AS Period,
	|		SalesForecastTurnovers.RoomRate.IsComplimentary,
	|		SalesForecastTurnovers.RoomRate.IsHouseUse,
	|		SalesForecastTurnovers.Client.IsInWhiteList,
	|		SalesForecastTurnovers.Client.DiscountCard.Description,
	|		SalesForecastTurnovers.GuestGroup.GroupType.Description,
	|		SalesForecastTurnovers.ParentDoc.NumberOfAdults,
	|		SalesForecastTurnovers.ParentDoc.NumberOfTeenagers,
	|		SalesForecastTurnovers.ParentDoc.NumberOfChildren,
	|		SalesForecastTurnovers.ParentDoc.NumberOfInfants,
	|		SalesForecastTurnovers.Agent.Description,
	|		SalesForecastTurnovers.ParentDoc.IsByReservation,
	|		SalesForecastTurnovers.ParentDoc.GuaranteeType.Description,
	|		SUM(SalesForecastTurnovers.SalesTurnover) AS SalesTurnover,
	|		SUM(SalesForecastTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|		SUM(SalesForecastTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|		SUM(SalesForecastTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|		SUM(SalesForecastTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
	|		SUM(SalesForecastTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|		SUM(SalesForecastTurnovers.BedsRentedTurnover) AS BedsRentedTurnover,
	|		SUM(SalesForecastTurnovers.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|		SUM(SalesForecastTurnovers.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
	|		SUM(SalesForecastTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(&qForecastPeriodFrom, &qForecastPeriodTo, Day, &qUseForecast AND Hotel IN HIERARCHY (&qHotel)) AS SalesForecastTurnovers
	|
	|	GROUP BY
	|		SalesForecastTurnovers.Period,
	|		SalesForecastTurnovers.RoomRate.IsComplimentary,
	|		SalesForecastTurnovers.RoomRate.IsHouseUse,
	|		SalesForecastTurnovers.Client.IsInWhiteList,
	|		SalesForecastTurnovers.Client.DiscountCard.Description,
	|		SalesForecastTurnovers.GuestGroup.GroupType.Description,
	|		SalesForecastTurnovers.ParentDoc.NumberOfAdults,
	|		SalesForecastTurnovers.ParentDoc.NumberOfTeenagers,
	|		SalesForecastTurnovers.ParentDoc.NumberOfChildren,
	|		SalesForecastTurnovers.ParentDoc.NumberOfInfants,
	|		SalesForecastTurnovers.Agent.Description,
	|		SalesForecastTurnovers.ParentDoc.IsByReservation,
	|		SalesForecastTurnovers.ParentDoc.GuaranteeType.Description) AS SalesTurnovers
	|	
	|GROUP BY
	|	SalesTurnovers.Period,
	|	SalesTurnovers.RoomRateIsComplimentary,
	|	SalesTurnovers.RoomRateIsHouseUse,
	|	SalesTurnovers.ClientIsInWhiteList,
	|	SalesTurnovers.ClientDiscountCardDescription,
	|	SalesTurnovers.GuestGroupGroupTypeDescription,
	|	SalesTurnovers.ParentDocNumberOfAdults,
	|	SalesTurnovers.ParentDocNumberOfTeenagers,
	|	SalesTurnovers.ParentDocNumberOfChildren,
	|	SalesTurnovers.ParentDocNumberOfInfants,
	|	SalesTurnovers.AgentDescription,
	|	SalesTurnovers.ParentDocIsByReservation,
	|	SalesTurnovers.ParentDocGuaranteeTypeDescription
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod + 1 * 86400);
	vQry.SetParameter("qForecastPeriodFrom", Max(vForecastStartDate, vBegOfPeriod));
	vQry.SetParameter("qForecastPeriodTo", vEndOfPeriod + 1 * 86400);
	vQry.SetParameter("qUseForecast", ?(vForecastStartDate > vEndOfPeriod, False, True));
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();   
	
	// Arrival Rooms/Beds and Guests for Tomorrow
	vQrySubResult = GenerateSubQuery(vQryResult, New Structure("Period", vEndOfPeriod + 1 * 86400));
	vTotalSubValues = GetQResultTableTotals(PeriodTo, vQrySubResult, vQrySubResult, "RoomsCheckedInTurnover, BedsCheckedInTurnover, GuestsCheckedInTurnover");
	vArrivalRoomsTomorrow = cmCastToNumber(vTotalSubValues.RoomsCheckedInTurnover);
	vArrivalBedsTomorrow = cmCastToNumber(vTotalSubValues.BedsCheckedInTurnover);
	vArrivalGuestsTomorrow = cmCastToNumber(vTotalSubValues.GuestsCheckedInTurnover);
	
	// Delete Row With Values for Tomorrow 
	If vQryResult.Find(vEndOfPeriod + 1, "Period") <> Undefined Then
		vQryResult.Delete(vQryResult.Find(vEndOfPeriod + 1, "Period"));
	EndIf;;
		
	vResources = "ParentDocNumberOfAdults, ParentDocNumberOfTeenagers, ParentDocNumberOfChildren, ParentDocNumberOfInfants, SalesTurnover, SalesWithoutVATTurnover, RoomRevenueTurnover, ";
	VResources = vResources + "RoomRevenueWithoutVATTurnover, GuestDaysTurnover, RoomsRentedTurnover, BedsRentedTurnover, RoomsCheckedInTurnover, BedsCheckedInTurnover, GuestsCheckedInTurnover";
	
	vTotalValues = GetQResultTableTotals(PeriodTo, vQryResult, vQryResult, vResources);
		
	// Complimentary Rooms
	vQryResultCompl = GenerateSubQuery(vQryResult, New Structure("RoomRateIsComplimentary", True));
			//vQryResultCompl.GroupBy("Period", vResources);
	vTotalCompRented = GetQResultTableTotals(PeriodTo, vQryResultCompl, vQryResultCompl, "RoomsRentedTurnover, BedsRentedTurnover", False);
	vRoomsRentedComp = cmCastToNumber(vTotalCompRented.RoomsRentedTurnover);
	vBedsRentedComp = cmCastToNumber(vTotalCompRented.BedsRentedTurnover);
	
	// House use Rooms
	vQryResultHouse = GenerateSubQuery(vQryResult, New Structure("RoomRateIsHouseUse", True));
			//vQryResultCompl.GroupBy("Period", vResources);
	vTotalHouseRented = GetQResultTableTotals(PeriodTo, vQryResultCompl, vQryResultCompl, "RoomsRentedTurnover, BedsRentedTurnover", False);
	vRoomsRentedHouse = cmCastToNumber(vTotalHouseRented.RoomsRentedTurnover);
	vBedsRentedHouse = cmCastToNumber(vTotalHouseRented.BedsRentedTurnover);

	// Rooms Rented (Sold)
			//vQryResult.Sort("Period, RoomRateIsComplimentary, RoomRateIsHouseUse");
	vRoomsRented = cmCastToNumber(vTotalValues.RoomsRentedTurnover);
	vBedsRented = cmCastToNumber(vTotalValues.BedsRentedTurnover);
	
	// Run query to get number of blocked rooms
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	RoomBlocksBalanceAndTurnovers.Period AS Period,
	|	RoomBlocksBalanceAndTurnovers.RoomBlockType.IsRoomRepair AS IsRoomRepair,
	|	SUM(RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlockedClosingBalance,
	|	SUM(RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlockedClosingBalance
	|FROM
	|	AccumulationRegister.RoomBlocks.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)) AS RoomBlocksBalanceAndTurnovers
	|
	|GROUP BY
	|	RoomBlocksBalanceAndTurnovers.Period,
	|	RoomBlocksBalanceAndTurnovers.RoomBlockType,
	|	RoomBlocksBalanceAndTurnovers.RoomBlockType.IsRoomRepair
	|ORDER BY
	|	Period";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vRoomsBlockQryResult = vQry.Execute().Unload();
	
	vResources = "RoomsBlockedClosingBalance, BedsBlockedClosingBalance";

	// Rooms Repair
	vQryResultRepair = GenerateSubQuery(vRoomsBlockQryResult, New Structure("IsRoomRepair", True));
				//vQryResultRepair.GroupBy("Period", vResources);

	vRepairValues = GetAllDaysQResultTableTotals(PeriodTo, vRoomsBlockQryResult, vRoomsBlockQryResult, vResources);
	vRoomsRepaired = cmCastToNumber(vRepairValues.RoomsBlockedClosingBalance);
	vBedsRepaired = cmCastToNumber(vRepairValues.BedsBlockedClosingBalance);  
	
	vTotalBlockValues = GetAllDaysQResultTableTotals(PeriodTo, vRoomsBlockQryResult, vRoomsBlockQryResult, vResources);
	vRoomsBlocked = cmCastToNumber(vTotalBlockValues.RoomsBlockedClosingBalance);
	vBedsBlocked = cmCastToNumber(vTotalBlockValues.BedsBlockedClosingBalance);
	
	// Rooms for Sale
	vRoomsForSale = vTotalRooms - vRoomsBlocked;
	vBedsForSale = vTotalBeds - vBedsBlocked;
	
	// Rooms Occupied minus Comp and House Use
	vRoomsPaidOnly = vRoomsRented - vRoomsRentedComp - vRoomsRentedHouse;
	vBedsPaidOnly = vBedsRented - vBedsRentedComp - vBedsRentedHouse;
	
	// Block Persons In-House
	vGroupResources = "GuestDaysTurnover, RoomsRentedTurnover, BedsRentedTurnover, SalesTurnover, SalesWithoutVATTurnover, RoomRevenueTurnover, RoomRevenueWithoutVATTurnover";
	vQrySubResult = GenerateSubQuery(vQryResult, New Structure("GuestGroupGroupTypeDescription", NULL));	
	vTotalSubValues = GetQResultTableTotals(PeriodTo, vQrySubResult, vQrySubResult, vGroupResources);
	vIndividualGuests = cmCastToNumber(vTotalSubValues.GuestDaysTurnover);
	vGroupGuests = cmCastToNumber(vTotalValues.GuestDaysTurnover) - vIndividualGuests;
	
	// Get (Total&(Individual/Group))(Total/Room) and Other Income 
	If vWithVAT Then
		vRoomsIncome = cmCastToNumber(vTotalValues.RoomRevenueTurnover);
		vTotalIncome = cmCastToNumber(vTotalValues.SalesTurnover);
		
		vIndividualRoomsIncome = cmCastToNumber(vTotalSubValues.RoomRevenueTurnover);
		vGroupRoomsIncome = vRoomsIncome - vIndividualRoomsIncome;	
		vIndividualTotalIncome= cmCastToNumber(vTotalSubValues.SalesTurnover);
		vGroupTotalIncome = vTotalIncome - vIndividualTotalIncome;  
	Else
		vRoomsIncome = cmCastToNumber(vTotalValues.RoomRevenueWithoutVATTurnover);
		vTotalIncome = cmCastToNumber(vTotalValues.SalesWithoutVATTurnover);
		
		vIndividualRoomsIncome = cmCastToNumber(vTotalSubValues.RoomRevenueWithoutVATTurnover);
		vGroupRoomsIncome = vRoomsIncome - vIndividualRoomsIncome;
		vIndividualTotalIncome= cmCastToNumber(vTotalSubValues.SalesWithoutVATTurnover);
		vGroupTotalIncome = vTotalIncome - vIndividualTotalIncome;
	EndIf;
	vOtherIncome = vTotalIncome - vRoomsIncome;
	
	// In-House Adults/Children
	vAdultsGuests = cmCastToNumber(vTotalValues.ParentDocNumberOfAdults);
	vChildrenGuests = cmCastToNumber(vTotalValues.ParentDocNumberOfTeenagers) + cmCastToNumber(vTotalValues.ParentDocNumberOfChildren) + cmCastToNumber(vTotalValues.ParentDocNumberOfInfants);
	vTotalGuests = cmCastToNumber(vTotalValues.GuestDaysTurnover);
	
	// Individual Rooms In-House
	vIndividualRooms = cmCastToNumber(vTotalSubValues.RoomsRentedTurnover);
	vGroupRooms = cmCastToNumber(vTotalValues.RoomsRentedTurnover) - vIndividualRooms;
	
	vIndividualBeds = cmCastToNumber(vTotalSubValues.BedsRentedTurnover);
	vGroupBeds = cmCastToNumber(vTotalValues.BedsRentedTurnover) - vIndividualBeds;
	
	// Member Persons In-House
	vQrySubResult = GenerateSubQuery(vQryResult, New Structure("ClientDiscountCardDescription", NULL));
	vTotalSubValues = GetQResultTableTotals(PeriodTo, vQrySubResult, vQrySubResult, "GuestDaysTurnover, SalesTurnover, SalesWithoutVATTurnover, RoomRevenueTurnover, RoomRevenueWithoutVATTurnover");
	vNotClubMembGuests = cmCastToNumber(vTotalSubValues.GuestDaysTurnover);
	vClubMembGuests = cmCastToNumber(vTotalValues.GuestDaysTurnover) - vNotClubMembGuests;
	
	// Get Member Income 
	If vWithVAT Then
		vNotMemberRoomsIncome = cmCastToNumber(vTotalSubValues.RoomRevenueTurnover);
		vMemberRoomsincome = vRoomsIncome - vNotMemberRoomsIncome;
		vNotMemberTotalIncome = cmCastToNumber(vTotalSubValues.SalesTurnover);
		vMemberTotalIncome = vTotalIncome - vNotMemberTotalIncome;
	Else
		vNotMemberRoomsIncome = cmCastToNumber(vTotalSubValues.RoomRevenueWithoutVATTurnover);
		vMemberRoomsincome = vRoomsIncome - vNotMemberRoomsIncome;
		vNotMemberTotalIncome = cmCastToNumber(vTotalSubValues.SalesWithoutVATTurnover);
		vMemberTotalIncome = vTotalIncome - vNotMemberTotalIncome;
	EndIf;
	
	// VIP Persons In-House
	vQrySubResult = GenerateSubQuery(vQryResult, New Structure("ClientIsInWhiteList", True));
	vTotalSubValues = GetQResultTableTotals(PeriodTo, vQrySubResult, vQrySubResult, "GuestDaysTurnover");
	vVIPGuests = cmCastToNumber(vTotalSubValues.GuestDaysTurnover);
	
	// Travel Agent Rooms In-House
	vQrySubResult = GenerateSubQuery(vQryResult, New Structure("AgentDescription", NULL));
	vTotalSubValues = GetQResultTableTotals(PeriodTo, vQrySubResult, vQrySubResult, "RoomsRentedTurnover, BedsRentedTurnover");
	vNotTravelAgentRooms = cmCastToNumber(vTotalSubValues.RoomsRentedTurnover);
	vTravelAgentRooms = cmCastToNumber(vTotalValues.RoomsRentedTurnover) - vNotTravelAgentRooms;

	vNotTravelAgentBeds = cmCastToNumber(vTotalSubValues.BedsRentedTurnover);
	vTravelAgentBeds = cmCastToNumber(vTotalValues.BedsRentedTurnover) - vNotTravelAgentBeds; 
	
	// Arrival Rooms/Beds
	vArrivalRooms = cmCastToNumber(vTotalValues.RoomsCheckedInTurnover);
	vArrivalBeds = cmCastToNumber(vTotalValues.BedsCheckedInTurnover);
	
	// Arrival Guests
	vArrivalGuests = cmCastToNumber(vTotalValues.GuestsCheckedInTurnover);
	
	// Arrival Rooms/Beds and Guests for Tomorrow
	vQrySubResult = GenerateSubQuery(vQryResult, New Structure("Period", vForecastStartDate + 1 * 86400));
	vTotalSubValues = GetQResultTableTotals(PeriodTo, vQrySubResult, vQrySubResult, "RoomsCheckedInTurnover, BedsCheckedInTurnover, GuestsCheckedInTurnover");
	vArrivalRoomsTomorrow = cmCastToNumber(vTotalSubValues.RoomsCheckedInTurnover);
	vArrivalBedsTomorrow = cmCastToNumber(vTotalSubValues.BedsCheckedInTurnover);
	vArrivalGuestsTomorrow = cmCastToNumber(vTotalSubValues.GuestsCheckedInTurnover);
	
	// Reserved/Walk-In Rooms Arrivals 
	vQrySubResult = GenerateSubQuery(vQryResult, New Structure("ParentDocIsByReservation", False));
	vTotalSubValues = GetQResultTableTotals(PeriodTo, vQrySubResult, vQrySubResult, "RoomsCheckedInTurnover, BedsCheckedInTurnover, GuestsCheckedInTurnover");
	vRoomsWalkInArrivals = cmCastToNumber(vTotalSubValues.RoomsCheckedInTurnover);
	
	// Reserved/Walk-In Beds Arrivals
	vBedsWalkInArrivals = cmCastToNumber(vTotalSubValues.BedsCheckedInTurnover);
	
	// Walk-In Persons
	vPersWalkInArrivals = cmCastToNumber(vTotalSubValues.GuestsCheckedInTurnover);
	
	// Deducted/Non-Deducted Rooms Arrivals
	vQrySubResult = GenerateSubQuery(vQryResult, New Structure("ParentDocGuaranteeTypeDescription", NULL));
	vTotalSubValues = GetQResultTableTotals(PeriodTo, vQrySubResult, vQrySubResult, "RoomsCheckedInTurnover, BedsCheckedInTurnover");
	vRoomsNonDeductedArr = cmCastToNumber(vTotalSubValues.RoomsCheckedInTurnover);
	vRoomsDeductedArr = cmCastToNumber(vTotalValues.RoomsCheckedInTurnover) - vRoomsNonDeductedArr;
	
	// Deducted/Non-Deducted Beds Arrivals
	vBedsNonDeductedArr = cmCastToNumber(vTotalSubValues.BedsCheckedInTurnover);
	vBedsDeductedArr = cmCastToNumber(vTotalValues.BedsCheckedInTurnover) - vBedsNonDeductedArr;
	
	// % Rooms Occupied
	vOccupationRooms = Round(?((vRoomsForSale + vRoomsBlocked) <> 0, 100*(vRoomsRented + vRoomsBlocked)/(vRoomsForSale + vRoomsBlocked), 0), 2);
	vOccupationBeds = Round(?((vBedsForSale + vBedsBlocked) <> 0, 100*(vBedsRented + vBedsBlocked)/(vBedsForSale + vBedsBlocked), 0), 2);
	
	// % Rooms Occupied minus Comp and House (???) вычитать ли из условия
	vOccupRoomsWOCompHouse = Round(?((vRoomsForSale + vRoomsBlocked) <> 0, 100*(vRoomsPaidOnly + vRoomsBlocked)/(vRoomsForSale + vRoomsBlocked), 0), 2);
	vOccupBedsWOCompHouse= Round(?((vBedsForSale + vBedsBlocked) <> 0, 100*(vBedsPaidOnly + vBedsBlocked)/(vBedsForSale + vBedsBlocked), 0), 2);
	
	// % Rooms Occupied minus Comp, House and OOO (???) вычитать ли из условия
	vOccupRoomsWOCompHouseRep = Round(?((vRoomsForSale + vRoomsBlocked) <> 0, 100*(vRoomsPaidOnly + vRoomsBlocked - vRoomsRepaired)/(vRoomsForSale + vRoomsBlocked - vRoomsRepaired), 0), 2);
	vOccupBedsWOCompHouseRep = Round(?((vBedsForSale + vBedsBlocked) <> 0, 100*(vBedsPaidOnly + vBedsBlocked - vBedsRepaired)/(vBedsForSale + vBedsBlocked - vBedsRepaired), 0), 2);
	
	// % Rooms Occupied minus Comp (???) вычитать ли из условия
	vOccupRoomsWOComp = Round(?((vRoomsForSale + vRoomsBlocked) <> 0, 100*(vRoomsRented - vRoomsRentedComp + vRoomsBlocked)/(vRoomsForSale + vRoomsBlocked), 0), 2);
	vOccupBedsWOComp = Round(?((vBedsForSale + vBedsBlocked) <> 0, 100*(vBedsRented - vRoomsRentedComp + vBedsBlocked)/(vBedsForSale + vBedsBlocked), 0), 2);
	
	// % Rooms Occupied minus House (???) вычитать ли из условия
	vOccupRoomsWOHouse = Round(?((vRoomsForSale + vRoomsBlocked) <> 0, 100*(vRoomsRented - vRoomsRentedHouse + vRoomsBlocked)/(vRoomsForSale + vRoomsBlocked), 0), 2);
	vOccupBedsWOHouse = Round(?((vBedsForSale + vBedsBlocked) <> 0, 100*(vBedsRented - vRoomsRentedHouse + vBedsBlocked)/(vBedsForSale + vBedsBlocked), 0), 2);
	
	// % Rooms Occupied minus Comp and OOO (???) вычитать ли из условия
	vOccupRoomsWOCompRep = Round(?((vRoomsForSale + vRoomsBlocked) <> 0, 100*(vRoomsRented - vRoomsRentedComp + vRoomsBlocked - vRoomsRepaired)/(vRoomsForSale + vRoomsBlocked - vRoomsRepaired), 0), 2);
	vOccupBedsWOCompRep = Round(?((vBedsForSale + vBedsBlocked) <> 0, 100*(vBedsRented - vRoomsRentedComp + vBedsBlocked - vBedsRepaired)/(vBedsForSale + vBedsBlocked - vBedsRepaired), 0), 2);
	
	// % Rooms Ooccupied minus House and OOO (???) вычитать ли из условия
	vOccupRoomsWOHouseRep = Round(?((vRoomsForSale + vRoomsBlocked) <> 0, 100*(vRoomsRented - vRoomsRentedHouse + vRoomsBlocked - vRoomsRepaired)/(vRoomsForSale + vRoomsBlocked - vRoomsRepaired), 0), 2);
	vOccupBedsWOHouseRep = Round(?((vBedsForSale + vBedsBlocked) <> 0, 100*(vBedsRented - vRoomsRentedHouse + vBedsBlocked - vBedsRepaired)/(vBedsForSale + vBedsBlocked - vBedsRepaired), 0), 2);
	
	// % Rooms Occupied Minus OOO (???) вычитать ли из условия
	vOccupRoomsWORep = Round(?((vRoomsForSale + vRoomsBlocked) <> 0, 100*(vRoomsRented + vRoomsBlocked - vRoomsRepaired)/(vRoomsForSale + vRoomsBlocked - vRoomsRepaired), 0), 2);
	vOccupBedsWORep = Round(?((vBedsForSale + vBedsBlocked) <> 0, 100*(vBedsRented + vBedsBlocked - vBedsRepaired)/(vBedsForSale + vBedsBlocked - vBedsRepaired), 0), 2);
	
	// Run query to get check-outs
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	RoomInventoryTurnovers.Period AS Period,
	|	RoomInventoryTurnovers.Recorder.ParentDoc.GuestGroup.GroupType.Description AS GuestGroupGroupTypeDescription,
	|	RoomInventoryTurnovers.Recorder.ParentDoc.Guest.DiscountCard.Description AS GuestDiscountCardDescription,
	|	SUM(RoomInventoryTurnovers.RoomsCheckedOutTurnover) AS RoomsCheckedOutTurnover,
	|	SUM(RoomInventoryTurnovers.BedsCheckedOutTurnover) AS BedsCheckedOutTurnover,
	|	SUM(RoomInventoryTurnovers.GuestsCheckedOutTurnover) AS GuestsCheckedOutTurnover
	|FROM
	|	AccumulationRegister.RoomInventory.Turnovers(&qPeriodFrom, &qPeriodTo, Recorder, Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryTurnovers
	|
	|GROUP BY
	|	RoomInventoryTurnovers.Period,
	|	RoomInventoryTurnovers.Recorder.ParentDoc.GuestGroup.GroupType.Description,
	|	RoomInventoryTurnovers.Recorder.ParentDoc.Guest.DiscountCard.Description";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	vResources = "GuestGroupGroupTypeDescription, GuestDiscountCardDescription, RoomsCheckedOutTurnover, BedsCheckedOutTurnover, GuestsCheckedOutTurnover";
	
	vTotalValues = GetQResultTableTotals(PeriodTo, vQryResult, vQryResult, vResources);
	
	// Departure Rooms/Beds Guests
	vRoomsDep = cmCastToNumber(vTotalValues.RoomsCheckedOutTurnover);
	vBedsDep = cmCastToNumber(vTotalValues.BedsCheckedOutTurnover);
	vGuestsDep = cmCastToNumber(vTotalValues.GuestsCheckedOutTurnover);

	vResources = "RoomsCheckedOutTurnover, BedsCheckedOutTurnover, GuestsCheckedOutTurnover";
	
	// Individual Departure Rooms/Beds and Guests
	vQryIndivResult = GenerateSubQuery(vQryResult, New Structure("GuestGroupGroupTypeDescription", NULL));
	vTotalSubValues = GetQResultTableTotals(PeriodTo, vQryIndivResult, vQryIndivResult, vResources);
	vIndividualRoomsDep = cmCastToNumber(vTotalSubValues.RoomsCheckedOutTurnover);
	vGroupRoomsDep = vRoomsDep - vIndividualRoomsDep;
	
	vIndividualBedsDep = cmCastToNumber(vTotalSubValues.BedsCheckedOutTurnover);
	vGroupBedsDep = vBedsDep - vIndividualBedsDep;
	
	vIndividualGuestsDep = cmCastToNumber(vTotalSubValues.GuestsCheckedOutTurnover);
	vGroupGuestsDep = vGuestsDep - vIndividualGuestsDep;
	
	// Individual Member Rooms/Beds and Guests Department
	vQrySubResult = GenerateSubQuery(vQryIndivResult, New Structure("GuestDiscountCardDescription", NULL));
	vTotalSubValues = GetQResultTableTotals(PeriodTo, vQrySubResult, vQrySubResult, vResources);
	vIndivNotMembRoomsDep = cmCastToNumber(vTotalSubValues.RoomsCheckedOutTurnover);
	vIndivMembRoomsDep = vRoomsDep - vIndivNotMembRoomsDep;
	
	vIndivNotMembBedsDep = cmCastToNumber(vTotalSubValues.BedsCheckedOutTurnover);
	vIndivMembBedsDep = vBedsDep - vIndivNotMembBedsDep;
	
	vIndivNotMembGuestsDep = cmCastToNumber(vTotalSubValues.GuestsCheckedOutTurnover);
	vIndivMembGuestsDep = vGuestsDep - vIndivNotMembGuestsDep;
	
	// Member Rooms/Beds and Guests Department
	vQrySubResult = GenerateSubQuery(vQryResult, New Structure("GuestDiscountCardDescription", NULL));
	vTotalSubValues = GetQResultTableTotals(PeriodTo, vQrySubResult, vQrySubResult, vResources);
	NotMembRoomsDep = cmCastToNumber(vTotalSubValues.RoomsCheckedOutTurnover);
	vMembRoomsDep = vRoomsDep - NotMembRoomsDep;
	
	NotMembBedsDep = cmCastToNumber(vTotalSubValues.BedsCheckedOutTurnover);
	vMembBedsDep = vBedsDep - NotMembBedsDep;
	
	NotMembGuestsDep = cmCastToNumber(vTotalSubValues.GuestsCheckedOutTurnover);
	vMembGuestsDep = vGuestsDep - NotMembGuestsDep;
	
	// Day Use Rooms
	vQry = New Query();
	vQry.Text =
		"SELECT
		|	SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
		|	SUM(RoomSalesTurnovers.BedsRentedTurnover) AS BedsRentedTurnover
		|FROM
		|	AccumulationRegister.Sales.Turnovers(
		|			&qPeriodFrom,
		|			&qPeriodTo,
		|			Day,
		|			Hotel IN HIERARCHY (&qHotel)
		|				AND NOT IsCorrection
		|				AND BEGINOFPERIOD(ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(ParentDoc.CheckOutDate, DAY)) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	
	// Day Use Rooms
	vRoomsDayUse = cmCastToNumber(vQryResult[0].RoomsRentedTurnover);
	vBedsDayUse = cmCastToNumber(vQryResult[0].BedsRentedTurnover);
	
	// Average Daily Room Rate  
	vAvgRoomPrice = Round(?(vRoomsRented <> 0, vRoomsIncome/vRoomsRented, 0), 2);
	vAvgBedPrice = Round(?(vBedsRented <> 0, vRoomsIncome/vBedsRented, 0), 2);
	// Average Daily Room Rate minus Comp
	vAvgRoomPriceWOComp = Round(?(vRoomsRented <> 0, vRoomsIncome/vRoomsRented - vRoomsRentedComp, 0), 2);
	vAvgBedPriceWOComp = Round(?(vBedsRented <> 0, vRoomsIncome/vBedsRented - vBedsRentedComp, 0), 2);
	// Average Daily Room Rate minus House Use
	vAvgRoomPriceWOHouse = Round(?(vRoomsRented <> 0, vRoomsIncome/vRoomsRented - vRoomsRentedHouse, 0), 2);
	vAvgBedPriceWOHouse = Round(?(vBedsRented <> 0, vRoomsIncome/vBedsRented - vBedsRentedHouse, 0), 2);
	// Average Daily Room Rate minus Comp and House Use
	vAvgRoomPriceWOCompHouse = Round(?(vRoomsRented <> 0, vRoomsIncome/vRoomsPaidOnly, 0), 2);
	vAvgBedPriceWOCompHouse = Round(?(vBedsRented <> 0, vRoomsIncome/vBedsPaidOnly, 0), 2);
	// Average Person Rate 
	vAvgPersonRate = Round(?(vTotalGuests <> 0, vRoomsIncome/vTotalGuests, 0), 2); 
	//Average Persons Per Block Rooms
	vAvgPersonsGroupRooms = Round(?(vGroupRooms <> 0, vArrivalGuests/vGroupRooms, 0), 2);
	vAvgPersonsGroupBeds = Round(?(vGroupBeds <> 0, vArrivalGuests/vGroupBeds, 0), 2);
	//Average Revenue Per Block Rooms
	vAvgRevenueGroupRooms = Round(?(vGroupRooms <> 0, vGroupTotalIncome/vGroupRooms, 0), 2);
	vAvgRevenueGroupBeds = Round(?(vGroupBeds <> 0, vGroupTotalIncome/vGroupBeds, 0), 2);
	//Average Room Revenue Per Block Rooms
	vAvgRevenueRoomGroupRooms = Round(?(vGroupRooms <> 0, vGroupRoomsIncome/vGroupRooms, 0), 2);
	vAvgRevenueRoomGroupBeds = Round(?(vGroupBeds <> 0, vGroupRoomsIncome/vGroupBeds, 0), 2);
	
	// Revenue Per Available Room
	vRevPAR = Round(?((vRoomsForSale) <> 0, vRoomsIncome/(vRoomsForSale), 0), 2);
	vRevPAB = Round(?((vBedsForSale) <> 0, vRoomsIncome/(vBedsForSale), 0), 2);
	// Revenue Per Available Room minus OOO
	vRevPARWORep = Round(?((vRoomsForSale + vRoomsBlocked - vRoomsRepaired) <> 0, vRoomsIncome/(vRoomsForSale + vRoomsBlocked - vRoomsRepaired), 0), 2);
	vRevPABWORep = Round(?((vBedsForSale + vBedsBlocked - vBedsRepaired) <> 0, vRoomsIncome/(vBedsForSale + vBedsBlocked - vBedsRepaired), 0), 2);
	
	// Total Revenue per Person
	vTotalRevenuePerson = Round(?(vTotalGuests <> 0, vTotalIncome/vTotalGuests, 0), 2);
	
	vTmpInd = 0;
	
	If vInRooms Then
		If pInsArea = "FirstColumn" Then
			// Add header
			vNewStr = IndexesTable.Add();
			vNewStr.IndexPicture = PictureLib.Rooms;
			vNewStr.IndexName = NStr("en='ROOMS OCCUPATION';ru='СТАТИСТИКА ПО ЗАГРУЗКЕ';de='STATISTIK NACH AUSLASTUNG'");
			vNewStr.IndexKey = vNewStr.IndexName;
		Else
			vTmpInd = vTmpind + 1;
		Endif;
		
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Total Rooms in Hotel';ru='Всего номеров в отеле';de='Gesamtzahl der Zimmer im Hotel'", vTotalRooms);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Rooms Occupied';ru='Продано номеров';de='Verkaufte Zimmer'", vRoomsRented, Round(vRoomsRented));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Available Rooms';ru='Доступные номера';de='Gesamtzahl der Zimmer im Hotel'", (vRoomsForSale));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Available Rooms minus OOO Rooms';ru='Всего номеров минус ""на ремонте""';de='Gesamtzahl der Zimmer im Hotel'", (vTotalRooms - vRoomsRepaired));	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Available Rooms minus OOO';ru='@Доступные номера минус ""на ремонте""';de='Gesamtzahl der Zimmer im Hotel'", (vRoomsForSale - vRoomsRepaired));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Complimentary Rooms';ru='Бесплатных номеров';de='Gratis Zimmer'", vRoomsRentedComp, Round(vRoomsRentedComp));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='House Use Rooms';ru='Служебных номеров';de='Gratis Zimmer'", vRoomsRentedComp, Round(vRoomsRentedComp));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Rooms Occupied minus Comp and House Use';ru='Занятые номера минус бесплатные и служебные';de='Gratis Zimmer'", vRoomsPaidOnly, Round(vRoomsPaidOnly));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Rooms Occupied minus House Use';ru='Занятые номера минус служебные';de='Gratis Zimmer'", vRoomsRented - vRoomsRentedHouse, Round(vRoomsRented - vRoomsRentedHouse));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Rooms Occupied minus Comp';ru='Занятые номера минус бесплатные';de='Gratis Zimmer'", vRoomsRented - vRoomsRentedComp, Round(vRoomsRented - vRoomsRentedComp));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Day Use Rooms';ru='Номера на полсуток';de='Gratis Zimmer'", vRoomsDayUse);	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Out Of Order Rooms';ru='Номера со статусом ""на ремонте""';de='Gratis Zimmer'", vRoomsRepaired); 
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Out Of Service Rooms';ru='Номера со статусом ""не сдаётся""';de='Gratis Zimmer'", vRoomsBlocked);
		
		If pInsArea = "FirstColumn" Then
			// Add header
			vNewStr = IndexesTable.Add();
			vNewStr.IndexPicture = PictureLib.Clients;
			vNewStr.IndexName = NStr("en='ROOMS OCCUPATION';ru='СТАТИСТИКА ПО ГОСТЯМ';de='STATISTIK NACH AUSLASTUNG'");
			vNewStr.IndexKey = vNewStr.IndexName;
		Else
			vTmpInd = vTmpind + 1;
		Endif;
	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='In-House Adults';ru='@Взрослые - проживающие';de='Gratis Zimmer'", vAdultsGuests);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='In-House Children';ru='@Дети - проживающие';de='Gratis Zimmer'", vChildrenGuests);	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Total In-House Persons';ru='Всего проживающих';de='Gratis Zimmer'", vTotalGuests, Round(vTotalGuests));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Persons In-House';ru='Проживающие индивидуалы';de='Gratis Zimmer'", vIndividualGuests, Round(vIndividualGuests));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Block Persons In-House';ru='Проживающие гости по блокам';de='Gratis Zimmer'", vGroupGuests, Round(vGroupGuests));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Member Persons In-House';ru='Проживающие с клубными программами';de='Gratis Zimmer'", vClubMembGuests, Round(vClubMembGuests));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='VIP Persons In-House';ru='Проживающие VIP гости';de='Gratis Zimmer'", vVIPGuests, Round(vVIPGuests));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Rooms In-House';ru='Номера по проживающим индивидуалам';de='Gratis Zimmer'", vIndividualRooms, Round(vIndividualRooms));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Block Rooms In-House';ru='Номера проживающих по блокам';de='Gratis Zimmer'", vGroupRooms, Round(vGroupRooms));		
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Source Rooms In-House';ru='@Номера проживающих от турагентов';de='Gesamtzahl der Zimmer im Hotel'", vTravelAgentRooms, Round(vTravelAgentRooms));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Rooms Occupied';ru='% загрузки номеров';de='Gesamtzahl der Zimmer im Hotel'", vOccupationRooms, String(vOccupationRooms)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Rooms Occupied minus Comp and House';ru='% загрузки номеров минус бесплатные и служебные';de='Gesamtzahl der Zimmer im Hotel'", vOccupRoomsWOCompHouse, String(vOccupRoomsWOCompHouse)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Rooms Occupied minus Comp, House and OOO';ru='% загрузки номеров минус беспл., служ. и ""на ремонте""';de='Gesamtzahl der Zimmer im Hotel'", vOccupRoomsWOCompHouseRep, String(vOccupRoomsWOCompHouseRep)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Rooms Occupied minus Comp';ru='% загрузки номеров минус бесплатные';de='Gesamtzahl der Zimmer im Hotel'", vOccupRoomsWOComp, String(vOccupRoomsWOComp)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Rooms Occupied minus House';ru='% загрузки номеров минус служебные';de='Gesamtzahl der Zimmer im Hotel'", vOccupRoomsWOHouse, String(vOccupRoomsWOHouse)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Rooms Occupied minus Comp and OOO';ru='% загрузки номеров минус бесплатные и ""на ремонте""';de='Gesamtzahl der Zimmer im Hotel'", vOccupRoomsWOCompRep, String(vOccupRoomsWOCompRep)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Rooms Occupied minus House and OOO';ru='% загрузки номеров минус служебные и ""на ремонте""';de='Gesamtzahl der Zimmer im Hotel'", vOccupRoomsWOHouseRep, String(vOccupRoomsWOHouseRep)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Rooms Occupied Minus OOO';ru='% загрузки номеров минус ""на ремонте""';de='Gesamtzahl der Zimmer im Hotel'", vOccupRoomsWORep, String(vOccupRoomsWORep)+"%");
		
		If pInsArea = "FirstColumn" Then
			// Add header
			vNewStr = IndexesTable.Add();
			vNewStr.IndexPicture = PictureLib.CheckIn32;
			vNewStr.IndexName = NStr("en='CHECK-IN SUMMARY INDEXES';ru='СТАТИСТИКА ПО ЗАЕЗДУ';de='STATISTIK NACH ANREISE'");
			vNewStr.IndexKey = vNewStr.IndexName;
		Else
			vTmpInd = vTmpind + 1;
		Endif;
		
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Arrival Rooms';ru='Заезды - номера';de='Gesamtzahl der Zimmer im Hotel'", vArrivalRooms, Round(vArrivalRooms));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Arrival Persons';ru='Заезды - гости';de='Gesamtzahl der Zimmer im Hotel'", vArrivalGuests, Round(vArrivalGuests));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Deducted Rooms Arrivals';ru='Заезды в номера по подтверждённым броням';de='Gesamtzahl der Zimmer im Hotel'", vRoomsDeductedArr, Round(vRoomsDeductedArr));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Non-Deducted Rooms Arrivals';ru='Заезды в номера по неподтверждённым броням';de='Gesamtzahl der Zimmer im Hotel'", vRoomsNonDeductedArr, Round(vRoomsNonDeductedArr));	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Walk-In Rooms';ru='От стойки - номера';de='Gesamtzahl der Zimmer im Hotel'", vRoomsWalkInArrivals, Round(vRoomsWalkInArrivals));	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Walk-In Persons';ru='От стойки - гости';de='Gesamtzahl der Zimmer im Hotel'", vPersWalkInArrivals, Round(vPersWalkInArrivals));
		
		If pInsArea = "FirstColumn" Then
			// Add header
			vNewStr = IndexesTable.Add();
			vNewStr.IndexPicture = PictureLib.CheckIn32;
			vNewStr.IndexName = NStr("en='CHECK-IN SUMMARY INDEXES';ru='СТАТИСТИКА ПО ВЫЕЗДУ';de='STATISTIK NACH ANREISE'");
			vNewStr.IndexKey = vNewStr.IndexName;
		Else
			vTmpInd = vTmpind + 1;
		Endif;

		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Departure Rooms';ru='Выезды - номера';de='Durchschnittliche Rentabilität des Zimmers'", vRoomsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Departure Persons';ru='Выехавшие гости';de='Durchschnittliche Rentabilität des Zimmers'", vGuestsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Departure Rooms';ru='Выехавшие номера по индивидуалам';de='Durchschnittliche Rentabilität des Zimmers'", vIndividualRoomsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Departure Persons';ru='Выехавшие индивидуалы';de='Durchschnittliche Rentabilität des Zimmers'", vIndividualGuestsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Member Departure Rooms';ru='Номера выехавших индивидуалов с клуб. прог.';de='Durchschnittliche Rentabilität des Zimmers'", vIndivMembRoomsDep); 
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Individual Member Departures';ru='% выездов индивидуалов с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vIndivMembRoomsDep/vRoomsDep*100, Round(vIndivMembRoomsDep/vRoomsDep*100)); 
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Member Departure Persons';ru='Выехавшие индивидуалы с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vIndivMembGuestsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Member Departure Rooms';ru='Номера выехавших гостей с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vMembRoomsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Member Departure Persons';ru='Выехавшие гости с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vMembGuestsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Member Departures';ru='% выездов гостей с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vMembRoomsDep/vRoomsDep*100, Round(vMembRoomsDep/vRoomsDep*100)); 
		
		If pInsArea = "FirstColumn" Then
			// Add header
			vNewStr = IndexesTable.Add();
			vNewStr.IndexPicture = PictureLib.Totals;
			vNewStr.IndexName = NStr("en='INCOME SUMMARY INDEXES';ru='СТАТИСТИКА ПО ДОХОДАМ';de='STATISTIK NACH EINNAHMEN'");
			vNewStr.IndexKey = vNewStr.IndexName;
		Else
			vTmpInd = vTmpind + 1;
		Endif;

		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Daily Room Rate';ru='Средний тариф на номер';de='Gesamtzahl der Zimmer im Hotel'", vAvgRoomPrice, OutputWithCurrency(vAvgRoomPrice));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Daily Room Rate minus Comp';ru='Средний тариф на номер минус бесплатные';de='Gesamtzahl der Zimmer im Hotel'", vAvgRoomPriceWOComp, OutputWithCurrency(vAvgRoomPriceWOComp));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Daily Room Rate minus House';ru='Средний тариф на номер минус служебные';de='Gesamtzahl der Zimmer im Hotel'", vAvgRoomPriceWOHouse, OutputWithCurrency(vAvgRoomPriceWOHouse));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Daily Room Rate minus Comp and House';ru='Средний тариф на номер минус бесплатные и служебные';de='Gesamtzahl der Zimmer im Hotel'", vAvgRoomPriceWOCompHouse, OutputWithCurrency(vAvgRoomPriceWOCompHouse));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Person Rate';ru='Средний тариф на человека';de='Durchschnittliche Rentabilität des Zimmers'", vAvgPersonRate, OutputWithCurrency(vAvgPersonRate));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Persons per Block Rooms';ru='Среднее кол-во человек на номер в блоке';de='Durchschnittliche Rentabilität des Zimmers'", vAvgPersonsGroupRooms, Round(vAvgPersonsGroupRooms, 0));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Revenue per Block Rooms';ru='Средний доход на номер в блоке';de='Durchschnittliche Rentabilität des Zimmers'", vAvgRevenueGroupRooms, OutputWithCurrency(vAvgRevenueGroupRooms));	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Room Revenue per Block Rooms';ru='Средний доход с номера на номер в блоке';de='Durchschnittliche Rentabilität des Zimmers'", vAvgRevenueRoomGroupRooms, OutputWithCurrency(vAvgRevenueRoomGroupRooms));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Room Revenue';ru='Доход номеров';de='Durchschnittliche Rentabilität des Zimmers'", vRoomsIncome, OutputWithCurrency(vRoomsIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Other Revenue';ru='Прочий доход';de='Durchschnittliche Rentabilität des Zimmers'", vOtherIncome, OutputWithCurrency(vOtherIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Total Revenue';ru='Общий доход';de='Durchschnittliche Rentabilität des Zimmers'", vTotalIncome, OutputWithCurrency(vTotalIncome)); 
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Block Revenue';ru='Доход от блоков';de='Durchschnittliche Rentabilität des Zimmers'", vGroupTotalIncome, OutputWithCurrency(vGroupTotalIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Block Room Revenue';ru='@Доход от номеров по блокам';de='Durchschnittliche Rentabilität des Zimmers'", vGroupRoomsIncome, OutputWithCurrency(vGroupRoomsIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Revenue';ru='Доход по индивидуалам';de='Durchschnittliche Rentabilität des Zimmers'", vIndividualTotalIncome, OutputWithCurrency(vIndividualTotalIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Room Revenue';ru='@Доход от номеров индивидуалов';de='Durchschnittliche Rentabilität des Zimmers'", vIndividualRoomsIncome, OutputWithCurrency(vIndividualRoomsIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Member Revenue';ru='Доход по гостям с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vMemberTotalIncome, OutputWithCurrency(vMemberTotalIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Member Room Revenue';ru='@Доход от номеров по гостям с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vMemberRoomsincome, OutputWithCurrency(vMemberRoomsincome)); 
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Total Revenue per Person';ru='Общий доход на гостя';de='Durchschnittliche Rentabilität des Zimmers'", vTotalRevenuePerson, OutputWithCurrency(vTotalRevenuePerson));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Revenue Per Available Room';ru='Средний доход с действующего номера (RevPAR)';de='Durchschnittliche Rentabilität des Zimmers'", vRevPAR, OutputWithCurrency(vRevPAR));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='@Revenue Per Available Room minus OOO';ru='Средний доход с действующего номера минус ""на ремонте""';de='Durchschnittliche Rentabilität des Zimmers'", vRevPARWORep, OutputWithCurrency(vRevPARWORep));

		If pInsArea = "FirstColumn" Then
			// Add header
			vNewStr = IndexesTable.Add();
			vNewStr.IndexPicture = PictureLib.Totals;
			vNewStr.IndexName = NStr("en='INCOME SUMMARY INDEXES';ru='СТАТИСТИКА НА ЗАВТРА';de='STATISTIK NACH EINNAHMEN'");
			vNewStr.IndexKey = vNewStr.IndexName; 
		Else
			vTmpInd = vTmpind + 1;
		Endif;

		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Arrival Rooms for Tomorrow';ru='Заезды завтра - номера';de='Durchschnittliche Rentabilität des Zimmers'", vArrivalRoomsTomorrow);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Arrival Guests for Tomorrow';ru='Заезды завтра - гости';de='Durchschnittliche Rentabilität des Zimmers'", vArrivalGuestsTomorrow);
		
	Else
		If pInsArea = "FirstColumn" Then
			// Add header
			vNewStr = IndexesTable.Add();
			vNewStr.IndexPicture = PictureLib.Rooms;
			vNewStr.IndexName = NStr("en='ROOMS OCCUPATION';ru='СТАТИСТИКА ПО ЗАГРУЗКЕ';de='STATISTIK NACH AUSLASTUNG'");
			vNewStr.IndexKey = vNewStr.IndexName;
		Else
			vTmpInd = vTmpind + 1;
		Endif;
		
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Total Beds in Hotel';ru='Всего мест в отеле';de='Gesamtzahl der Betten im Hotel'", vTotalBeds);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Beds Occupied';ru='Продано мест';de='Verkaufte Betten'", vBedsRented, Round(vBedsRented));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Available Beds';ru='Доступные места';de='Gesamtzahl der Betten im Hotel'", (vBedsForSale));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Available Beds minus OOO Beds';ru='Всего мест минус ""на ремонте""';de='Gesamtzahl der Betten im Hotel'", (vTotalBeds - vBedsRepaired));	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Available Beds minus OOO';ru='@Доступные места минус ""на ремонте""';de='Gesamtzahl der Betten im Hotel'", (vBedsForSale - vBedsRepaired));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Complimentary Beds';ru='Бесплатных мест';de='Gratis Betten'", vBedsRentedComp, Round(vBedsRentedComp));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='House Use Beds';ru='Служебных мест';de='Gratis Betten'", vBedsRentedHouse, Round(vBedsRentedHouse));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Beds Occupied minus Comp and House Use';ru='Занятые места минус бесплатные и служебные';de='Gratis Betten'", vBedsPaidOnly, Round(vBedsPaidOnly));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Beds Occupied minus House Use';ru='Занятые места минус служебные';de='Gratis Betten'", vBedsRented - vBedsRentedHouse, Round(vBedsRented - vBedsRentedHouse));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Beds Occupied minus Comp';ru='Занятые места минус бесплатные';de='Gratis Betten'", vBedsRented - vBedsRentedComp, Round(vBedsRented - vBedsRentedComp));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Day Use Beds';ru='Места на полсуток';de='Gratis Betten'", vBedsDayUse);	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Out Of Order Beds';ru='Места со статусом ""на ремонте""';de='Gratis Zimmer'", vBedsRepaired);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Out Of Service Beds';ru='Места со статусом ""не сдаётся""';de='Gratis Zimmer'", vBedsBlocked);
		
		If pInsArea = "FirstColumn" Then
			// Add header
			vNewStr = IndexesTable.Add();
			vNewStr.IndexPicture = PictureLib.Clients;
			vNewStr.IndexName = NStr("en='ROOMS OCCUPATION';ru='СТАТИСТИКА ПО ГОСТЯМ';de='STATISTIK NACH AUSLASTUNG'");
			vNewStr.IndexKey = vNewStr.IndexName;
		Else
			vTmpInd = vTmpind + 1;
		Endif;
		
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='In-House Adults';ru='@Взрослые - проживающие';de='Gratis Zimmer'", vAdultsGuests);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='In-House Children';ru='@Дети - проживающие';de='Gratis Zimmer'", vChildrenGuests);	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Total In-House Persons';ru='Всего проживающих';de='Gratis Zimmer'", vTotalGuests, Round(vTotalGuests));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Persons In-House';ru='Проживающие индивидуалы';de='Gratis Zimmer'", vIndividualGuests, Round(vIndividualGuests));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Block Persons In-House';ru='Проживающие гости по блокам';de='Gratis Zimmer'", vGroupGuests, Round(vGroupGuests));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Member Persons In-House';ru='Проживающие с клубными программами';de='Gratis Zimmer'", vClubMembGuests, Round(vClubMembGuests));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='VIP Persons In-House';ru='Проживающие VIP гости';de='Gratis Zimmer'", vVIPGuests, Round(vVIPGuests));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Beds In-House';ru='Места по проживающим индивидуалам';de='Gesamtzahl der Betten im Hotel'", vIndividualBeds, Round(vIndividualBeds));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Block Beds In-House';ru='Места проживающих по блокам';de='Gesamtzahl der Betten im Hotel'", vGroupBeds, Round(vGroupBeds));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Source Beds In-House';ru='Места проживающих от турагентов';de='Gesamtzahl der Betten im Hotel'", vTravelAgentBeds, Round(vTravelAgentBeds));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Beds Occupied';ru='% загрузки мест';de='Gesamtzahl der Betten im Hotel'", vOccupationBeds, String(vOccupationBeds)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Beds Occupied minus Comp and House';ru='% загрузки мест минус бесплатные и служебные';de='Gesamtzahl der Betten im Hotel'", vOccupBedsWOCompHouse, String(vOccupBedsWOCompHouse)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Beds Occupied minus Comp, House and OOO';ru='% загрузки мест минус беспл., служ. и ""на ремонте""';de='Gesamtzahl der Betten im Hotel'", vOccupBedsWOCompHouseRep, String(vOccupBedsWOCompHouseRep)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Beds Occupied minus Comp';ru='% загрузки мест минус бесплатные';de='Gesamtzahl der Betten im Hotel'", vOccupBedsWOComp, String(vOccupBedsWOComp)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Beds Occupied minus House';ru='% загрузки мест минус служебные';de='Gesamtzahl der Betten im Hotel'", vOccupBedsWOHouse, String(vOccupBedsWOHouse)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Beds Occupied minus Comp and OOO';ru='% загрузки мест минус бесплатные и ""на ремонте""';de='Gesamtzahl der Betten im Hotel'", vOccupBedsWOCompRep, String(vOccupBedsWOCompRep)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Beds Occupied minus House and OOO';ru='% загрузки мест минус служебные и ""на ремонте""';de='Gesamtzahl der Betten im Hotel'", vOccupBedsWOHouseRep, String(vOccupBedsWOHouseRep)+"%");
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Beds Occupied Minus OOO';ru='% загрузки мест минус ""на ремонте""';de='Gesamtzahl der Betten im Hotel'", vOccupBedsWORep, String(vOccupBedsWORep)+"%");

		If pInsArea = "FirstColumn" Then
			// Add header
			vNewStr = IndexesTable.Add();
			vNewStr.IndexPicture = PictureLib.CheckIn32;
			vNewStr.IndexName = NStr("en='CHECK-IN SUMMARY INDEXES';ru='СТАТИСТИКА ПО ЗАЕЗДУ';de='STATISTIK NACH ANREISE'");
			vNewStr.IndexKey = vNewStr.IndexName;
		Else
		vTmpInd = vTmpind + 1;
		Endif;

		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Arrival Beds';ru='Заезд - места';de='Gesamtzahl der Betten im Hotel'", vArrivalBeds, Round(vArrivalBeds));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Arrival Persons';ru='Заезд - гости';de='Gesamtzahl der Zimmer im Hotel'", vArrivalGuests, Round(vArrivalGuests));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Deducted Beds Arrivals';ru='Заезды на места по подтверждённым броням';de='Gesamtzahl der Betten im Hotel'", vBedsDeductedArr, Round(vBedsDeductedArr));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Non-Deducted Beds Arrivals';ru='Заезды на места по подтверждённым броням';de='Gesamtzahl der Betten im Hotel'", vBedsNonDeductedArr, Round(vBedsNonDeductedArr));	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Walk-In Beds';ru='От стойки - места';de='Gesamtzahl der Betten im Hotel'", vBedsWalkInArrivals, Round(vBedsWalkInArrivals));	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Walk-In Persons';ru='От стойки - гости';de='Gesamtzahl der Zimmer im Hotel'", vPersWalkInArrivals, Round(vPersWalkInArrivals));
		
		If pInsArea = "FirstColumn" Then
			// Add header
			vNewStr = IndexesTable.Add();
			vNewStr.IndexPicture = PictureLib.CheckIn32;
			vNewStr.IndexName = NStr("en='CHECK-IN SUMMARY INDEXES';ru='СТАТИСТИКА ПО ВЫЕЗДУ';de='STATISTIK NACH ANREISE'");
			vNewStr.IndexKey = vNewStr.IndexName;
		Else
			vTmpInd = vTmpind + 1;
		Endif;
		
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Departure Beds';ru='Выезды - места';de='Durchschnittliche Rentabilität des Zimmers'", vBedsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Departure Persons';ru='Выехавшие гости';de='Durchschnittliche Rentabilität des Zimmers'", vGuestsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Departure Beds';ru='Выехавшие места по индивидуалам';de='Durchschnittliche Rentabilität des Zimmers'", vIndividualBedsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Departure Persons';ru='Выехавшие индивидуалы';de='Durchschnittliche Rentabilität des Zimmers'", vIndividualGuestsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Member Departure Beds';ru='Места выехавших индивидуалов с клуб. прог.';de='Durchschnittliche Rentabilität des Zimmers'", vIndivMembBedsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Individual Member Departures';ru='% выездов индивидуалов с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vIndivMembRoomsDep/vRoomsDep*100, Round(vIndivMembRoomsDep/vRoomsDep*100)); 
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Member Departure Persons';ru='Выехавшие индивидуалы с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vIndivMembGuestsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Member Departure Beds';ru='Места выехавших гостей с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vMembBedsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Member Departure Persons';ru='Выехавшие гости с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vMembGuestsDep);
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='% Member Departures';ru='% выездов гостей с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vMembRoomsDep/vRoomsDep*100, Round(vMembRoomsDep/vRoomsDep*100)); 

		If pInsArea = "FirstColumn" Then
			// Add header
			vNewStr = IndexesTable.Add();
			vNewStr.IndexPicture = PictureLib.Totals;
			vNewStr.IndexName = NStr("en='INCOME SUMMARY INDEXES';ru='СТАТИСТИКА ПО ДОХОДАМ';de='STATISTIK NACH EINNAHMEN'");
			vNewStr.IndexKey = vNewStr.IndexName; 
		Else
			vTmpInd = vTmpind + 1;
		Endif;
		
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Daily Bed Rate';ru='Средний тариф на место';de='Gesamtzahl der Betten im Hotel'", vAvgBedPrice, OutputWithCurrency(vAvgBedPrice));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Daily Bed Rate minus Comp';ru='Средний тариф на место минус бесплатные';de='Gesamtzahl der Betten im Hotel'", vAvgBedPriceWOComp, OutputWithCurrency(vAvgBedPriceWOComp));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Daily Bed Rate minus House';ru='Средний тариф на место минус служебные';de='Gesamtzahl der Betten im Hotel'", vAvgBedPriceWOHouse, OutputWithCurrency(vAvgBedPriceWOHouse));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Daily Bed Rate minus Comp and House';ru='Средний тариф на место минус бесплатные и служебные';de='Gesamtzahl der Betten im Hotel'", vAvgBedPriceWOCompHouse, OutputWithCurrency(vAvgBedPriceWOCompHouse));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Person Rate';ru='Средний тариф на человека';de='Durchschnittliche Rentabilität des Zimmers'", vAvgPersonRate, OutputWithCurrency(vAvgPersonRate));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Persons per Block Beds';ru='Среднее кол-во человек на место в блоке';de='Durchschnittliche Rentabilität des Zimmers'", vAvgPersonsGroupBeds, OutputWithCurrency(vAvgPersonsGroupBeds));	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Revenue per Block Beds';ru='Средний доход на место в блоке';de='Durchschnittliche Rentabilität des Zimmers'", vAvgRevenueGroupBeds, OutputWithCurrency(vAvgRevenueGroupBeds));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Average Room Revenue per Block Beds';ru='Средний доход с места на место в блоке';de='Durchschnittliche Rentabilität des Zimmers'", vAvgRevenueRoomGroupBeds, OutputWithCurrency(vAvgRevenueRoomGroupBeds));	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Room Revenue';ru='Доход номеров';de='Durchschnittliche Rentabilität des Zimmers'", vRoomsIncome, OutputWithCurrency(vRoomsIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Other Revenue';ru='Прочий доход';de='Durchschnittliche Rentabilität des Zimmers'", vOtherIncome, OutputWithCurrency(vOtherIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Total Revenue';ru='Общий доход';de='Durchschnittliche Rentabilität des Zimmers'", vTotalIncome, OutputWithCurrency(vTotalIncome)); 
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Block Revenue';ru='Доход от блоков';de='Durchschnittliche Rentabilität des Zimmers'", vGroupTotalIncome, OutputWithCurrency(vGroupTotalIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Block Room Revenue';ru='@Доход от номеров по блокам';de='Durchschnittliche Rentabilität des Zimmers'", vGroupRoomsIncome, OutputWithCurrency(vGroupRoomsIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Revenue';ru='Доход по индивидуалам';de='Durchschnittliche Rentabilität des Zimmers'", vIndividualTotalIncome, OutputWithCurrency(vIndividualTotalIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Individual Room Revenue';ru='@Доход от номеров индивидуалов';de='Durchschnittliche Rentabilität des Zimmers'", vIndividualRoomsIncome, OutputWithCurrency(vIndividualRoomsIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Member Revenue';ru='Доход по гостям с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vMemberTotalIncome, OutputWithCurrency(vMemberTotalIncome));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Member Room Revenue';ru='@Доход от номеров по гостям с клубными программами';de='Durchschnittliche Rentabilität des Zimmers'", vMemberRoomsincome, OutputWithCurrency(vMemberRoomsincome)); 
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Total Revenue per Person';ru='Общий доход на гостя';de='Durchschnittliche Rentabilität des Zimmers'", vTotalRevenuePerson, OutputWithCurrency(vTotalRevenuePerson));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Revenue Per Available Bed minus OOO';ru='Средний доход с действующего места (RevPAB)';de='Durchschnittliche Rentabilität des Platzes'", vRevPAB, OutputWithCurrency(vRevPAB));
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='@Revenue Per Available Bed minus OOO';ru='Средний доход с действующего места (RevPAB) минус ""на ремонте""';de='Durchschnittliche Rentabilität des Zimmers'", vRevPABWORep, OutputWithCurrency(vRevPABWORep));	

		If pInsArea = "FirstColumn" Then
		// Add header
		vNewStr = IndexesTable.Add();
		vNewStr.IndexPicture = PictureLib.Totals;
		vNewStr.IndexName = NStr("en='INCOME SUMMARY INDEXES';ru='СТАТИСТИКА НА ЗАВТРА';de='STATISTIK NACH EINNAHMEN'");
		vNewStr.IndexKey = vNewStr.IndexName; 
		Else 
			vTmpInd = vTmpind + 1;
		Endif;

		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Arrival Beds for Tomorrow';ru='Заезды завтра - места';de='Durchschnittliche Rentabilität des Zimmers'", vArrivalBedsTomorrow);	
		InsertTableValues(pInsArea, vTmpInd, IndexesTable, "en='Arrival Guests for Tomorrow';ru='Заезды завтра - гости';de='Durchschnittliche Rentabilität des Zimmers'", vArrivalGuestsTomorrow);
	EndIf;
	
	If pInsArea <> "FirstColumn" Then
		CalculateCompareIcons(IndexesTable);
	EndIf;

EndProcedure // GetRooms

// ------------------------------------------------------------------------------------------------- 
&AtServerNoContext
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
		ChartGist.Series[1].GraphicalRepresentationType = ChartSeriesGraphicalRepresentationType.Line;
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
		ChartForSale.Series[1].Marker = ChartMarkerType.None;
		ChartForSale.Series[1].Text = vChartForSaleCompareTitle;
		
		ChartGist.Series.Add();
		ChartGist.Series[2].Text = vChartGistCompareTitle;
		
		ChartGist.Series[2].Color = WebColors.DarkBlue;
		ChartForSale.Series[1].Color = WebColors.BlueViolet;
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
			If vQryResultRow.Period > vDateNow Then
				vDaysCount = (vQryResultRow.Period - vDateNow)/86400;
				For vDays = 0 To vDaysCount - 1 Do
					vQryRoomsRentedArray.Add(0);
					vQryRoomsRentedArray.Add(vDateNow+vDays*86400);
					vQryRoomsIncomeArray.Add(0);
					vQryRoomsIncomeArray.Add(vDateNow+vDays*86400);
				EndDo;
			EndIf;
		ElsIf vPeriodicity = "Month" Then
			If Month(vQryResultRow.Period) > Month(vDateNow) Then
				vMonthsCount = Month(vQryResultRow.Period) - Month(vDateNow);
				For vMonths = 0 To vMonthsCount - 1 Do
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
			vRoomsForSale = vTotalRooms - vBlockedRooms;
			vIndCount = vIndCount + 1;
			If vPeriodicity = "Day" Then
				If vQryResultRow.Period > vDateNow Then
					vDaysCount = (vQryResultRow.Period - vDateNow)/86400;
					For vDays = 0 To vDaysCount - 1 Do
						vQryRoomsForSaleArray.Add(0);
						vQryRoomsForSaleArray.Add(vDateNow+vDays*86400);
					EndDo;
				EndIf;
			ElsIf vPeriodicity = "Month" Then
				If Month(vQryResultRow.Period) > Month(vDateNow) Then
					vMonthsCount = Month(vQryResultRow.Period) - Month(vDateNow);
					For vMonths = 0 To vMonthsCount - 1 Do
						vQryRoomsForSaleArray.Add(0);
						vQryRoomsForSaleArray.Add(AddMonth(vDateNow, vMonths));
					EndDo;
				EndIf;
			EndIf;
			vQryRoomsForSaleArray.Add(vRoomsForSale);
			vQryRoomsForSaleArray.Add(vQryResultRow.Period);
			If vPeriodicity = "Day" Then
				If (vQryResultRow.Period < (vEndOfPeriod)) And (vQryCount = vIndCount) Then
					vDaysCount = (vEndOfPeriod - vQryResultRow.Period)/86400;
					For vDays = 1 To vDaysCount Do
						vQryRoomsForSaleArray.Add(0);
						vQryRoomsForSaleArray.Add(vDateNow+vDays*86400);
					EndDo;
				EndIf;
			ElsIf vPeriodicity = "Month" Then
				If (Month(vQryResultRow.Period) < Month(vEndOfPeriod)) And (vQryCount = vIndCount) Then
					vMonthsCount = Month(vQryResultRow.Period) - Month(vDateNow);
					For vMonths = 0 To vMonthsCount - 1 Do
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
		
		If Not (vQryRoomsRentedArray.Count() = 0) Or Not (vQryRoomsIncomeArray.Count() = 0) Then
				If vQryRoomsRentedArray.Count() < vQryRoomsIncomeArray.Count() Then
				vMinCount = vQryRoomsRentedArray.Count();
			Else
				vMinCount = vQryRoomsIncomeArray.Count();
			EndIf;
			For vInd = 0 To (vMinCount/2 - 1) Do
				vNewPoint = ChartGist.Points.Add(String(Format(vQryRoomsIncomeArray.Get(vInd * 2 + 1), ?(vPeriodicity = "Day", "DF = 'dd'", "DF = 'MMMM'"))));
				ChartGist.SetValue(vNewPoint, 0, vQryRoomsRentedArray.Get(vInd * 2));
				ChartGist.SetValue(vNewPoint, 1, vQryRoomsForSaleArray.Get(vInd * 2));
				
				vNewPoint = ChartForSale.Points.Add(String(Format(vQryRoomsIncomeArray.Get(vInd * 2 + 1), ?(vPeriodicity = "Day", "DF = 'dd'", "DF = 'MMMM'"))));
				ChartForSale.SetValue(vNewPoint,0,vQryRoomsIncomeArray.Get(vInd * 2));
			EndDo;
		EndIf;
	Else
		If Not (vQryRoomsRentedArray.Count() = 0) And Not (vQryRoomsIncomeArray.Count() = 0) Then
			vMinCount = vQryRoomsIncomeArray.Count();
			For vInd = 0 To (vMinCount/2 - 1) Do
				vPointName = Format(vQryRoomsIncomeArray.Get(vInd * 2 + 1), ?(vPeriodicity = "Day", "DF = 'dd'", "DF = 'MMMM'"));
				For Each vPoint In ChartGist.Points Do
					If vPoint.Text = vPointName Then
						ChartGist.SetValue(vPoint, 2, vQryRoomsRentedArray.Get(vInd * 2));
						Break;
					EndIf;
				EndDo;
				For Each vPoint In ChartForSale.Points Do
					If vPoint.Text = vPointName Then
						ChartForSale.SetValue(vPoint, 1, vQryRoomsIncomeArray.Get(vInd * 2));
						Break;
					EndIf;
				EndDo;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // ChartBuild

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

