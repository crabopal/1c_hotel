// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelDateNew = CurrentSessionDate();
	If Parameters.Property("SelDate") Then
		SelDate = Parameters.SelDate;	
	EndIf;
	If Parameters.Property("SelService") Then
		SelService = Parameters.SelService;	
	EndIf;
	If Parameters.Property("SelHotel") Then
		SelHotel = Parameters.SelHotel;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionExecute(pCommand)
	If ValueIsFilled(SelDate) And ValueIsFilled(SelDateNew) Then  
		If SelDate <> SelDateNew Then
			If ExecuteAtServer() Then
				Notify("BreakDownListSettings.Update", , ThisForm);
				ShowMessageBox(, NStr("en='Completed!'; ru='Выполнено!'; de='Fertiggestellt!'"));
			Else
				ShowMessageBox(, NStr("en='Nothing to copy!'; ru='Нет строк для копирования!'; de='Nichts zu kopieren!'"));
			EndIf;
		Else
			ShowMessageBox(, NStr("en='The dates are the same!'; ru='Даты одинаковые!'; de='Die Daten sind gleich!'"));
		EndIf;
	Else
		ShowMessageBox(, NStr("en='All dates should be filled!'; ru='Все даты должны быть заполнены!'; de='Alle Daten müssen ausgefüllt werden!'"));
	EndIf;
EndProcedure // ActionExecute

// -----------------------------------------------------------------------------
&AtServer
Function ExecuteAtServer()
	vSettingsWereFound = False;
	vBreakDownList = InformationRegisters.BreakDownListSettings.CreateRecordSet();
	vBreakDownList.Filter.Hotel.Set(SelHotel);
	vBreakDownList.Filter.Service.Set(SelService);
	vBreakDownList.Filter.Period.Set(SelDate);
	vBreakDownList.Read();
	If vBreakDownList.Count() > 0 Then
		vBreakDownList.Filter.Period.Set(SelDateNew);
		For Each vBreakDownListRow In vBreakDownList Do
			vBreakDownListRow.Period = SelDateNew;
		EndDo;
		vBreakDownList.Write(True);
		vSettingsWereFound = True;
	EndIf;
	vBreakDownList = InformationRegisters.BreakDownListSettings.CreateRecordSet();
	vBreakDownList.Filter.Hotel.Set(Catalogs.Hotels.EmptyRef());
	vBreakDownList.Filter.Service.Set(SelService);
	vBreakDownList.Filter.Period.Set(SelDate);
	vBreakDownList.Read();
	If vBreakDownList.Count() > 0 Then
		vBreakDownList.Filter.Period.Set(SelDateNew);
		For Each vBreakDownListRow In vBreakDownList Do
			vBreakDownListRow.Period = SelDateNew;
		EndDo;
		vBreakDownList.Write(True);
		vSettingsWereFound = True;
	EndIf;
	Return vSettingsWereFound;
EndFunction // ExecuteAtServer
