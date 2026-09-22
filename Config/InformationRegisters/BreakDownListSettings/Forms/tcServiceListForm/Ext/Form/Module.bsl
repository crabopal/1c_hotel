// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		Items.List.ChangeRowSet = False;
	EndIf;
	SelService = Parameters.Filter.Service;
	SelHotel = SessionParameters.CurrentHotel;
	BreakDownListSettingsUpdate();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SelDateOnChangeAtServer()
	vDate = GetDate(SelDate);
	If ValueIsFilled(vDate) Then
		vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Get(1);  
		vNewFilter.LeftValue		= New DataCompositionField("Period");
		vNewFilter.ComparisonType	= DataCompositionComparisonType.Equal;
		vNewFilter.RightValue		= vDate;
		vNewFilter.Use				= True;
		vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
EndProcedure // SelDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateOnChange(pItem)
	SelDateOnChangeAtServer();
EndProcedure // SelDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyWithNewDate(pCommand)
	vDate = GetDate(SelDate);
	If ValueIsFilled(vDate) Then
		OpenForm("InformationRegister.BreakDownListSettings.Form.tcCopyWithNewDate", New Structure("SelDate, SelService, SelHotel", vDate, SelService, SelHotel), ThisForm, ThisForm.UUID);
	Else
		ShowMessageBox(, NStr("en='Nothing to copy!'; ru='Нечего копировать!'; de='Es gibt nichts zu kopieren!'"));
	EndIf;
EndProcedure // CopyWithNewDate

// -----------------------------------------------------------------------------
&AtServer
Procedure BreakDownListSettingsUpdate()
	List.SettingsComposer.Settings.Filter.Items.Clear();
	
	// Filter by hotel
	vFilterList	= New ValueList;
	vFilterList.Add(Catalogs.Hotels.EmptyRef());
	If ValueIsFilled(SelHotel) Then
		vFilterList.Add(SelHotel);
	EndIf;
	
	vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilter.LeftValue		= New DataCompositionField("Hotel");
	vNewFilter.ComparisonType	= DataCompositionComparisonType.InList;
	vNewFilter.RightValue		= vFilterList;
	vNewFilter.Use				= True;
	vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;

	SelDate = "";
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BreakDownListSettings.Period AS Period
	|FROM
	|	InformationRegister.BreakDownListSettings AS BreakDownListSettings
	|WHERE
	|	BreakDownListSettings.Service = &qService
	|
	|GROUP BY
	|	BreakDownListSettings.Period
	|
	|ORDER BY
	|	BreakDownListSettings.Period";
	vQry.SetParameter("qService", SelService);
	vDates = vQry.Execute().Unload();
	If vDates.Count() > 0 Then
		vDate = vDates.Get(vDates.Count()-1).Period;
		SelDate = Format(vDate, "DF=yyyyMMdd");
		
		vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vNewFilter.LeftValue		= New DataCompositionField("Period");
		vNewFilter.ComparisonType	= DataCompositionComparisonType.Equal;
		vNewFilter.RightValue		= vDate;
		vNewFilter.Use				= True;
		vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
		
		For Each vDatesRow In vDates Do
			If Items.SelDate.ChoiceList.FindByValue(Format(vDatesRow.Period, "DF=yyyyMMdd")) = Undefined Then
				Items.SelDate.ChoiceList.Add(Format(vDatesRow.Period, "DF=yyyyMMdd"), Format(vDatesRow.Period, "DF=dd.MM.yyyy"));
			EndIf;
		EndDo;
	EndIf;
	
	If Not IsBlankString(SelDate) Then
		Items.SelDate.Visible = True;
	Else
		Items.SelDate.Visible = False;
	EndIf;
EndProcedure // BreakDownListSettingsUpdate

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "BreakDownListSettings.Update" Then
		BreakDownListSettingsUpdate();	
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetDate(pDateStr)
	vDate = '00010101';
	If Not IsBlankString(pDateStr) And StrLen(pDateStr) = 8 And cmIsNumber(pDateStr) Then
		Try
			vDate = Date(Number(Left(pDateStr, 4)), Number(Mid(pDateStr, 5, 2)), Number(Right(pDateStr, 2)));
		Except
		EndTry;
	EndIf;
	Return vDate;
EndFunction // GetDate
