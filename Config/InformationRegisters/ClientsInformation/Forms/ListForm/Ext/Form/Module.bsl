// ---------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelPeriodFrom = CurrentSessionDate();
	SelPeriodTo = CurrentSessionDate();
	
	SelHotelOnChangeAtServer();
	SelClientInformationTypeOnChangeAtServer();
	SetPeriodAtServer();
EndProcedure // OnCreateAtServer

// ---------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SelHotelOnChangeAtServer();
EndProcedure // SelHotelOnChange

// ---------------------------------------------------------------------
&AtServer
Procedure SelHotelOnChangeAtServer()
	If List.Filter.Items.Count() = 0 Then
		vFltItem = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vFltItem.LeftValue = New DataCompositionField("Hotel");
		vFltItem.ComparisonType = DataCompositionComparisonType.Equal;
	Else
		vFltItem = List.Filter.Items.Get(0);
	EndIf;
	vFltItem.RightValue = SelHotel;
EndProcedure // SelHotelOnChangeAtServer

// ---------------------------------------------------------------------
&AtClient
Procedure SelClientInformationTypeOnChange(pItem)
	SelClientInformationTypeOnChangeAtServer();
EndProcedure // SelClientInformationTypeOnChange

// ---------------------------------------------------------------------
&AtServer
Procedure SelClientInformationTypeOnChangeAtServer()
	If List.Filter.Items.Count() = 1 Then
		vFltItem = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vFltItem.LeftValue = New DataCompositionField("InformationType");
		vFltItem.ComparisonType = DataCompositionComparisonType.InHierarchy;
	Else
		vFltItem = List.Filter.Items.Get(1);
	EndIf;
	vFltItem.RightValue = SelClientInformationType;
EndProcedure // SelClientInformationTypeOnChangeAtServer

// ---------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodCommand(pCommand)
	vPeriod = New StandardPeriod(SelPeriodFrom, SelPeriodTo);
	vPeriodEditDlg = New StandardPeriodEditDialog();
	vPeriodEditDlg.Period = vPeriod;
	vPeriodEditDlg.Show(New NotifyDescription("ChoosePeriodCommandOnClose", ThisForm));
EndProcedure // ChoosePeriodCommand

// ---------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodCommandOnClose(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		SelPeriodFrom = pPeriod.StartDate;
		SelPeriodTo = pPeriod.EndDate;
		If Not ValueIsFilled(SelPeriodTo) Or ValueIsFilled(SelPeriodTo) And SelPeriodTo >= SelPeriodFrom Then
			// Set period at server
			SetPeriodAtServer();
		Else
			ShowMessageBox(, NStr("en='Period is wrong!'; ru='Ошибка в периоде!'; de='Zeitraum ist falsch!'"));
		EndIf;
	EndIf;
EndProcedure // ChoosePeriodCommandOnClose

// ---------------------------------------------------------------------
&AtServer
Procedure SetPeriodAtServer()
	If List.Filter.Items.Count() = 2 Then
		vFltItem1 = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vFltItem1.LeftValue = New DataCompositionField("Period");
		vFltItem1.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	Else
		vFltItem1 = List.Filter.Items.Get(2);
	EndIf;
	vFltItem1.RightValue = BegOfDay(SelPeriodFrom);
	
	If List.Filter.Items.Count() = 3 Then
		vFltItem2 = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vFltItem2.LeftValue = New DataCompositionField("Period");
		vFltItem2.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	Else
		vFltItem2 = List.Filter.Items.Get(3);
	EndIf;
	vFltItem2.RightValue = ?(ValueIsFilled(SelPeriodTo), EndOfDay(SelPeriodTo), '39991231');
EndProcedure // SetPeriodAtServer

// ---------------------------------------------------------------------
&AtClient
Procedure SelPeriodOnChange(pItem)
	If Not ValueIsFilled(SelPeriodTo) Or ValueIsFilled(SelPeriodTo) And SelPeriodTo >= SelPeriodFrom Then
		// Set period at server
		SetPeriodAtServer();
	Else
		ShowMessageBox(, NStr("en='Period is wrong!'; ru='Ошибка в периоде!'; de='Zeitraum ist falsch!'"));
	EndIf;
EndProcedure // SelPeriodOnChange
