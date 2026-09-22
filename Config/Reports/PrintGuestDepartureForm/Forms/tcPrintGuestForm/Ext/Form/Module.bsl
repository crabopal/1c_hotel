// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Report.Hotel = SessionParameters.CurrentHotel;
	If Parameters.Property("InputParameter") Then 
		If ValueIsFilled(Parameters.InputParameter) And TypeOf(Parameters.InputParameter) = Type("CatalogRef.GuestGroups") Then
			Report.GuestGroup = Parameters.InputParameter; 
			If ValueIsFilled(Parameters.InputParameter.ClientDoc) Then
				Report.Document  = Parameters.InputParameter.ClientDoc;	
			EndIf; 
			Report.Hotel = Parameters.InputParameter.GuestGroup.Owner;
		ElsIf ValueIsFilled(Parameters.InputParameter) And TypeOf(Parameters.InputParameter) = Type("DocumentRef.Accommodation") Then
			Report.Document  = Parameters.InputParameter;
			Report.Hotel = Parameters.InputParameter.Hotel;
		EndIf;
	Else
		Report.CheckOutDate = BegOfDay(CurrentSessionDate());
	EndIf;
	If Parameters.Property("ObjectPrintingForm") And ValueIsFilled(Parameters.ObjectPrintingForm) Then 
		Report.ObjectPrintingForm = Parameters.ObjectPrintingForm;
	Else
		Report.ObjectPrintingForm = Catalogs.ObjectPrintingForms.AccommodationPrintDepartureNotificationForm;
	EndIf;	
	If Parameters.Property("OneGuestMode") Then 
		SelOneGuestMode = Parameters.OneGuestMode;
	EndIf;
	Report.Print2On1Page = False;   
	TypeOfPrint = 3;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GenerateReport(pButton = Undefined, rDoPrint = Undefined)
	// Check attributes
	If CheckAttributes() Then
		// Get output spreadsheet
		vSpreadsheet = GuestFormSpreadsheet;
		
		// Load external printing form template
		vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(Report.ObjectPrintingForm);
		
		// Generate report
		vReportObj = FormAttributeToValue("Report");
		vReportObj.pmGenerate(vSpreadsheet, vExtTemplate, SelOneGuestMode, TypeOfPrint);

		// Setup default attributes
		cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait);
		If Report.Print2On1Page Then
			vSpreadsheet.LeftMargin = 1;
			vSpreadsheet.RightMargin = 1;
			vSpreadsheet.TopMargin = 1;
			vSpreadsheet.BottomMargin = 1;
			vSpreadsheet.HeaderSize = 1;
			vSpreadsheet.FooterSize = 1;
		EndIf;
		// Check authorities
		cmSetSpreadsheetProtection(vSpreadsheet);
		// Get and fill workstation print form settings
		If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
			vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
			If ValueIsFilled(vWorkstationPrintSettings) Then
				// Try to find records for the current object print form
				vFilter = New Structure("ObjectPrintingForm, IsActive", Report.ObjectPrintingForm, True); 
				vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
				If vPrintSettingsSet.Count() > 0 Then
					For Each vPrintSettings In vPrintSettingsSet Do
						// Fill settings
						cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
						// Check printing direction
						If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
							vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Guest forms';ru='Формы гостя';de='Formen des Gastes'"));
							cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, , rDoPrint);
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // GenerateReport

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Generate report
	rDoPrint = Undefined;
	GenerateReport(, rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		pCancel = true;
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtServer
Function CheckAttributes()
	If Not ValueIsFilled(Report.Document) 
	   And Not ValueIsFilled(Report.GuestGroup) 
	   And Not ValueIsFilled(Report.CheckOutDate) Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("ru='Для печати не выбраны ни документ ни группа гостей ни дата выезда!';
		                                                |de='Für den Druck wurden weder das Dokument, noch die Gästegruppe oder abreise Datum gewählt!';
														|en='Neither document no guest group or check-out date is selected for printing!'"));
		Return False;
	EndIf;
	Return True;
EndFunction // CheckAttributes

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	GuestFormSpreadsheet.Print();
	ThisForm.Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	GuestFormSpreadsheet.Print(PrintDialogUseMode.Use);
	ThisForm.Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, GuestFormSpreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentOnChange(pItem)
	If ValueIsFilled(Report.Document) Then
		Report.CheckOutDate = '00010101';
		Report.Hotel = tcOnServer.cmGetAttributeByRef(Report.Document, "Hotel");
		Report.GuestGroup = tcOnServer.cmGetAttributeByRef(Report.Document, "GuestGroup");
	EndIf;
	// Generate report
	rDoPrint = Undefined;
	GenerateReport(, rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // DocumentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOnChange(pItem)
	If ValueIsFilled(Report.GuestGroup) Then
		Report.Hotel = tcOnServer.cmGetAttributeByRef(Report.GuestGroup, "Owner");
		Report.Document = tcOnServer.cmGetAttributeByRef(Report.GuestGroup, "ClientDoc");
	EndIf;
	// Generate report
	rDoPrint = Undefined;
	GenerateReport(, rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // GuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure Print2On1PageOnChange(pItem)
	// Generate report
	rDoPrint = Undefined;
	GenerateReport(, rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // Print2On1PageOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.GuestGroups.ChoiceForm", , pItem, , , , New NotifyDescription("AfterGuestGroupStartChoice", ThisForm, New Structure("Item", pItem)), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // GuestGroupStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterGuestGroupStartChoice(pResult, pParams) Export
	If pResult <> Undefined Then
		GuestGroup = pResult;
		GuestGroupOnChange(pParams.Item);
	EndIf;
EndProcedure // AfterGuestGroupStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutDateOnChange(pItem)
	// Generate report
	rDoPrint = Undefined;
	GenerateReport(, rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // CheckOutDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(pItem)
	// Generate report
	rDoPrint = Undefined;
	GenerateReport(, rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // RoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure Generate(Command)
	// Generate report
	rDoPrint = Undefined;
	GenerateReport(, rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		pCancel = true;
	EndIf;
EndProcedure // Generate

// -----------------------------------------------------------------------------
&AtClient
Procedure TypeOfPrintOnChange(Item)
	// Generate report
	rDoPrint = Undefined;
	GenerateReport(, rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // TypeOfPrintOnChange
