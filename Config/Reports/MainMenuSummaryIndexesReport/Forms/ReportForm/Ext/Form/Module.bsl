// ----------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Report.PeriodFrom = Report.SettingsComposer.Settings.DataParameters.Items.Find("BeginOfPeriod").Value.Date;
	Report.PeriodTo = Report.SettingsComposer.Settings.DataParameters.Items.Find("EndOfPeriod").Value.Date;
	vHotel = Undefined;
	ThisForm.Parameters.Property("Hotel", vHotel);
	If ValueIsFilled(vHotel) Then
		Report.Hotel = vHotel;
	Else
		Report.Hotel = SessionParameters.CurrentHotel;
	EndIf;
	cmSetSpreadsheetProtection(Items.Result);
	vBegOfPeriod = Undefined;
	ThisForm.Parameters.Property("BegOfPeriod", vBegOfPeriod);
	If ValueIsFilled(vBegOfPeriod) Then
		Report.PeriodFrom = vBegOfPeriod;
	EndIf;
	vEndOfPeriod = Undefined;
	ThisForm.Parameters.Property("EndOfPeriod", vEndOfPeriod);
	If ValueIsFilled(vEndOfPeriod) Then
		Report.PeriodTo = vEndOfPeriod;
	EndIf;
	
	// Check if hotels folder could be selected
	If Not tcOnServer.CheckIfHotelCouldBeCleared() Then
		Items.Hotel.ChoiceFoldersAndItems = FoldersAndItems.Items;
	EndIf;
EndProcedure // OnCreateAtServer

// ----------------------------------------------------------------------
&AtClient
Procedure PeriodFromOnChange(pItem)
	Report.SettingsComposer.Settings.DataParameters.SetParameterValue("BeginOfPeriod", Report.PeriodFrom);
	ChangePeriodFromAtServer();
EndProcedure // PeriodFromOnChange

// ----------------------------------------------------------------------
&AtServer
Procedure ChangePeriodFromAtServer()
	Report.SettingsComposer.Settings.DataParameters.SetParameterValue("BeginOfPeriod", Report.PeriodFrom);
	OnChangingParameters();
EndProcedure // ChangePeriodFromAtServer

// ----------------------------------------------------------------------
&AtClient
Procedure PeriodToOnChange(pItem)
	Report.SettingsComposer.Settings.DataParameters.SetParameterValue("EndOfPeriod", Report.PeriodTo);
	ChangePeriodToAtServer();
EndProcedure // PeriodToOnChange

// ----------------------------------------------------------------------
&AtServer
Procedure ChangePeriodToAtServer()
	Report.SettingsComposer.Settings.DataParameters.SetParameterValue("EndOfPeriod", Report.PeriodTo);
	OnChangingParameters();
EndProcedure // ChangePeriodToAtServer

// ----------------------------------------------------------------------
&AtServer
Procedure OnChangingParameters()
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	Items.Result.StatePresentation.Text = NStr("en='Parameters have been changed. Please, click on ""Generate"" button';ru='Параметры были изменены. Нажмите на кнопку ""Сформировать""';de='Parameter wurden verändert. Betätigen Sie die Schaltfläche ""Erzeugen""'");
	Items.Result.StatePresentation.Visible = True;
EndProcedure // OnChangingParameters

// ----------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	Report.SettingsComposer.Settings.DataParameters.SetParameterValue("Hotel", Report.Hotel);
	ChangeHotelAtServer();
EndProcedure // HotelOnChange

// ----------------------------------------------------------------------
&AtServer
Procedure ChangeHotelAtServer()
	Report.SettingsComposer.Settings.DataParameters.SetParameterValue("Hotel", Report.Hotel);
	OnChangingParameters();
EndProcedure // ChangeHotelAtServer

// ----------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	Report.SettingsComposer.Settings.DataParameters.SetParameterValue("BeginOfPeriod", Report.PeriodFrom);
	Report.SettingsComposer.Settings.DataParameters.SetParameterValue("EndOfPeriod", Report.PeriodTo);
	Report.SettingsComposer.Settings.DataParameters.SetParameterValue("Hotel", Report.Hotel);
EndProcedure // OnOpen

// ----------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	VariantModified = False;
EndProcedure // BeforeClose

// -----------------------------------------------------------------------------
&AtServer 
Function GetFileName()
	vFilePath = NStr("en='Summary_indexes'; ru='Сводные_показатели'; de='Zusammenfassung'") + "_" + Format(CurrentDate(),"DF=dd.MM.yyyy_HH.mm");
	Return vFilePath;
EndFunction // GetFileName

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = GetFileName();
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, Result);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsXLSX(pCommand)
	vFilePath = GetFileName();
	vFileType = SpreadsheetDocumentFileType.XLSX;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, Result);
EndProcedure // SaveAsPDF

#Region ReportAttributesEvents

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = Report.PeriodFrom;
	vChoosePeriodDialog.Period.EndDate = Report.PeriodTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		Report.PeriodFrom = pPeriod.StartDate;
		PeriodFromOnChange(Items.PeriodFrom);
		Report.PeriodTo = pPeriod.EndDate;
		PeriodToOnChange(Items.PeriodTo);
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure HotelClearingAtServer(pStandardProcessing)
	pStandardProcessing = tcOnServer.CheckIfHotelCouldBeCleared();
EndProcedure // HotelClearingAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	HotelClearingAtServer(pStandardProcessing);
EndProcedure // HotelClearing

#EndRegion
