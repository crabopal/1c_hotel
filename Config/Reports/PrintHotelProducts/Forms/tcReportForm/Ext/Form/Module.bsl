
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	rDoPrint = Undefined;
	PrintHotelProduct(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		pCancel = True;
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	rDoPrint = Undefined;
	PrintHotelProduct(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // OnReopen

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SelDocument") Then
		Report.Document = Parameters.SelDocument;	
	EndIf;
	If Parameters.Property("SelDocumentsList") Then
		Report.DocumentsList = Parameters.SelDocumentsList;	
	EndIf;
	If Parameters.Property("SelRoom") Then
		Report.Room = Parameters.SelRoom; 
	EndIf;
	If Parameters.Property("SelCheckInDate") Then
		Report.CheckInDate = Parameters.SelCheckInDate;	
	EndIf;
	If Parameters.Property("SelGuestGroup") Then
		Report.GuestGroup = Parameters.SelGuestGroup;	
	EndIf;
	If Parameters.Property("SelObjectPrintForm") Then
		SelObjectPrintForm = Parameters.SelObjectPrintForm;	
	EndIf;
	ThisForm.Height = 297;
	ThisForm.Width = 210;
	cmSetSpreadsheetProtection(Items.ReservationSpreadsheet);
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionGenerate(pCommand)
	rDoPrint = Undefined;
	PrintHotelProduct(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // ActionGenerate

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	// Choose hotel product to print
	If HotelProducts.Count() > 0 Then
		vChoiceList = New ValueList();
		For i = 0 To (HotelProducts.Count() - 1) Do
			vHPRow = HotelProducts.Get(i);
			vChoiceList.Add(i, TrimAll(TrimAll(tcOnServer.cmGetAttributeByRef(vHPRow.Value.HotelProduct,"Parent")) + " " + TrimAll(vHPRow.Value.HotelProduct) + " - " + TrimAll(vHPRow.Value.Room) + ", " + TrimAll(vHPRow.Value.Client)));
		EndDo;
		vChoiceList.FillChecks(True);
		vChoiceList.ShowCheckItems(New NotifyDescription("PrintAfterItemsCheck", ThisForm, PrintDialogUseMode.DontUse), NStr("en='Check products to print!'; ru='Отметьте путевки для печати!'"));
	EndIf;
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	vAllPages = True;
	// Choose hotel product to print
	If HotelProducts.Count() > 0 Then
		vChoiceList = New ValueList();
		For i = 0 To (HotelProducts.Count() - 1) Do
			vHPRow = HotelProducts.Get(i);
			vChoiceList.Add(i, TrimAll(TrimAll(tcOnServer.cmGetAttributeByRef(vHPRow.Value.HotelProduct,"Parent")) + " " + TrimAll(vHPRow.Value.HotelProduct) + " - " + TrimAll(vHPRow.Value.Room) + ", " + TrimAll(vHPRow.Value.Client)));
		EndDo;
		vChoiceList.FillChecks(True);
		vChoiceList.ShowCheckItems(New NotifyDescription("PrintAfterItemsCheck", ThisForm, PrintDialogUseMode.Use), NStr("en='Check products to print!'; ru='Отметьте путевки для печати!'"));
	EndIf;
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintAfterItemsCheck(pHotelProducts, pPrintDialogUseMode) Export
	If pHotelProducts = Undefined Then
		Return;
	EndIf;
	vAllPages = True;
	For Each vItem In pHotelProducts Do
		If Not vItem.Check Then
			vAllPages = False;
			Break;
		EndIf;
	EndDo;
	If Not vAllPages Then
		i = 0;
		For Each vItem In pHotelProducts Do
			If vItem.Check Then
				// Set printing area
				vAreaStart = i * 49 + 1;
				vAreaEnd = (i + 1) * 49;
				ReservationSpreadsheet.PrintArea = ReservationSpreadsheet.Area(vAreaStart, , vAreaEnd);
				// Call printing routine
				ReservationSpreadsheet.Print(pPrintDialogUseMode);
				// Reset print area
				ReservationSpreadsheet.PrintArea = Undefined;
			EndIf;
			// Next index
			i = i + 1;
		EndDo;
	Else
		ReservationSpreadsheet.Print(pPrintDialogUseMode);
	EndIf;
EndProcedure // PrintAfterItemsCheck

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintHotelProduct(rDoPrint = Undefined)
	vHotelProducts = Undefined;
	
	// Basic checks
	If Not CheckAttributes() Then
		Return;
	EndIf;

	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	
	// Print
	vRepObj = FormAttributeToValue("Report");
	vRepObj.pmGenerate(ReservationSpreadsheet, vExtTemplate, vHotelProducts);
	
	For Each vHotelProduct In vHotelProducts Do
		HotelProducts.Add(vHotelProduct);	
	EndDo;

	// Setup default attributes
	cmSetDefaultPrintFormSettings(ReservationSpreadsheet, PageOrientation.Landscape);
	// Check authorities
	cmSetSpreadsheetProtection(ReservationSpreadsheet);
	
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", SelObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(ReservationSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Products';ru='Путевки';de='Reisechecks'"));
						cmDoSpreadsheetOutput(ReservationSpreadsheet, vPrintSettings, vName, , rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintHotelProduct

// -----------------------------------------------------------------------------
&AtServer
Function CheckAttributes()
	If Not ValueIsFilled(Report.Document) 
	   And Not ValueIsFilled(Report.GuestGroup) 
	   And Not ValueIsFilled(Report.CheckInDate) 
	   And Not ValueIsFilled(Report.Room) 
	   And Report.DocumentsList.Count() = 0 Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru = 'Для печати не выбраны ни документ ни группа гостей ни номер ни дата заезда!'; 
		             |en = 'Neither document no guest group or room or check-in date are selected for printing!';
					 |de = 'Weder Dokument, noch Gästegruppe oder Zimmer oder Check-in-Datum werden zum Drucken ausgewählt!'"));
		Return False;
	EndIf;
	Return True;
EndFunction // CheckAttributes

#EndRegion
