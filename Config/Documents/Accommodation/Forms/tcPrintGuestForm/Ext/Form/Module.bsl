
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Hotel = SessionParameters.CurrentHotel;
	If Parameters.Property("Document") Then
		Document = Parameters.Document;
		If ValueIsFilled(Document) Then
			Hotel = Document.Hotel;
		EndIf;
	EndIf;
	If Parameters.Property("GuestGroup") Then
		GuestGroup = Parameters.GuestGroup;
		If ValueIsFilled(GuestGroup) Then
			Hotel = GuestGroup.Owner;
		EndIf;
	EndIf;
	If Parameters.Property("CheckInDate") Then
		CheckInDate = Parameters.CheckInDate;
	EndIf;
	If Parameters.Property("ObjectPrintingForm") Then
		SelObjectPrintForm = Parameters.ObjectPrintingForm;
	EndIf;
	// Fill form type based on object printing form
	FillFormType();
	// Check what type of forms to show
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.Citizenship) And Hotel.Citizenship.Code <> 643 Then
		If TypeOfPrintForm = 0 Then
			Items.PrintSettingsGroup.Visible = False;
		EndIf;
	EndIf;
	If TypeOfPrintForm = 5 Then
		Items.Print2On1Page.Enabled = True;
	Else
		Items.Print2On1Page.Enabled = False;
		If Print2On1Page Then
			Print2On1Page = False;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer()

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Generate report
	rDoPrint = Undefined;
	GenerateReport(, rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		pCancel = True;
	EndIf;
EndProcedure // OnOpen()

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure TypeOfPrintFormOnChange(pItem)
	If TypeOfPrintForm = 5 Then
		Items.Print2On1Page.Enabled = True;
	Else
		Items.Print2On1Page.Enabled = False;
		If Print2On1Page Then
			Print2On1Page = False;
		EndIf;
	EndIf;
	// Generate report
	rDoPrint = Undefined;
	GenerateReport(, rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // TypeOfPrintFormOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentOnChange(pItem)
	If ValueIsFilled(Document) Then
		CheckInDate = '00010101';
		Hotel = tcOnServer.cmGetAttributeByRef(Document, "Hotel");
		GuestGroup = tcOnServer.cmGetAttributeByRef(Document, "GuestGroup");
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
	If ValueIsFilled(GuestGroup) Then
		Hotel = tcOnServer.cmGetAttributeByRef(GuestGroup, "Owner");
		Document = tcOnServer.cmGetAttributeByRef(GuestGroup, "ClientDoc");
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
Procedure CheckInDateOnChange(pItem)
	// Generate report
	rDoPrint = Undefined;
	GenerateReport(, rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // CheckInDateOnChange

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
Procedure GuestGroupStartChoice(pItem, pChoiceData, pStandardProcessing)
  pStandardProcessing = False;
  OpenForm("Catalog.GuestGroups.ChoiceForm",, pItem,,,, New NotifyDescription("AfterGuestGroupStartChoice", ThisForm, New Structure("Item", pItem)), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // GuestGroupStartChoice

#EndRegion

#Region FormCommandsEventHandlers

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

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure GenerateReport(pButton = Undefined, rDoPrint = Undefined)
	// Check attributes
	If CheckAttributes() Then
		// Get output spreadsheet
		vSpreadsheet = GuestFormSpreadsheet;
		
		// Load external printing form template
		vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
		
		// Create temp object
		If TypeOfPrintForm = 0 Or TypeOfPrintForm = 3 Or TypeOfPrintForm = 9 Then
		    vRepObject = Reports.PrintGuestRegistration.Create();
			vRepObject.CheckInDate = CheckInDate;
			vRepObject.Document = Document;
			vRepObject.GuestGroup = GuestGroup;
			vRepObject.RoomType = RoomType;
			vRepObject.TypeOfPrintForm = TypeOfPrintForm;
		ElsIf TypeOfPrintForm = 10 Then
			If ValueIsFilled(Document) Then
				vRepObject = Reports.PrintGuestApplicationForm.Create();
				vRepObject.Document = Document;
				vRepObject.GuestGroup = GuestGroup;
				If Not ValueIsFilled(GuestGroup) Then
					vRepObject.GuestGroup = Document.GuestGroup;
				EndIf;
			Else
				vSpreadsheet.Clear();
				Return;
			EndIf;
		ElsIf TypeOfPrintForm = 4 Or TypeOfPrintForm = 11 Then
		    vRepObject = Reports.PrintGuestCard.Create();
			vRepObject.CheckInDate = CheckInDate;
			vRepObject.Document = Document;
			vRepObject.GuestGroup = GuestGroup;
			vRepObject.RoomType = RoomType;
			If TypeOfPrintForm = 4 Then
				vRepObject.TypeOfPrintForm = 2;
			Else
				vRepObject.TypeOfPrintForm = 1;
			EndIf;
		Else
			vRepObject = Reports.PrintGuestForm.Create();
			vRepObject.CheckInDate = CheckInDate;
			vRepObject.Document = Document;
			vRepObject.GuestGroup = GuestGroup;
			vRepObject.RoomType = RoomType;
			vRepObject.Print2On1Page = Print2On1Page;
			If TypeOfPrintForm = 1 Then
				vRepObject.TypeOfPrintForm = 2;
			ElsIf TypeOfPrintForm = 5 Then
				vRepObject.TypeOfPrintForm = 3;
			Else
				vRepObject.TypeOfPrintForm = 1;
			EndIf;
		EndIf;
		// Generate report
		vRepObject.pmGenerate(vSpreadsheet, vExtTemplate);

		// Setup default attributes
		cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait);
		If TypeOfPrintForm = 5 And Print2On1Page Then
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
				vFilter = New Structure("ObjectPrintingForm, IsActive", SelObjectPrintForm, True); 
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
//  Set up print form type based on object printing form. Returns True if success
//  otherwise returns False
//
&AtServer
Procedure FillFormType()
	If SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestRegistrationForm
	   Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestRegistrationForms
	   Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintGuestRegistrationForm
	   Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintGuestRegistrationForms Then
		TypeOfPrintForm = 0;
		Print2On1Page = False;
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestFormForm1G 
	   Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestsFormsForm1G Then
		TypeOfPrintForm = 1;
		Print2On1Page = False;
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestFormFreeForm 
	   Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestsFormsFreeForm Then
		TypeOfPrintForm = 2;
		Print2On1Page = False;
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestCardForm4G Or 
	      SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestsCardsForm4G Or 
	      SelObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintGuestsCardsForm4G Then
		TypeOfPrintForm = 4;
		Print2On1Page = False;
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestFormForm5 
	   Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestsFormsForm5 
	   Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintGuestFormForm5 
	   Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintGuestsFormsForm5 Then
		TypeOfPrintForm = 5;
		Print2On1Page = False;
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestForm2Forms5 
	   Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestsForms2Forms5 
	   Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintGuestForm2Forms5
	   Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintGuestsForms2Forms5 Then
		TypeOfPrintForm = 5;
		Print2On1Page = True;
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestApplicationForm Then 
		TypeOfPrintForm = 10;
		Print2On1Page = False;
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestCardFreeForm Or 
	      SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestsCardsFreeForm Or 
	      SelObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintGuestsCardsFreeForm Then
		TypeOfPrintForm = 11;
		Print2On1Page = False;
	EndIf;
EndProcedure // FillFormType

// -----------------------------------------------------------------------------
&AtServer
Function CheckAttributes()
	If Not ValueIsFilled(Document) 
	   And Not ValueIsFilled(GuestGroup) 
	   And Not ValueIsFilled(CheckInDate) Then   
	   vMsg = NStr("en = 'Neither document no guest group or check-in date is selected for printing!'; 
	   			   |de = 'Für den Druck wurden weder das Dokument, noch die Gästegruppe oder anreise Datum gewählt!'; 
				   |ru = 'Для печати не выбраны ни документ ни группа гостей ни дата заезда!'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg);
		Return False;
	EndIf;
	Return True;
EndFunction // CheckAttributes

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterGuestGroupStartChoice(pResult, pParams) Export
  If pResult <> Undefined Then
    GuestGroup = pResult;
    GuestGroupOnChange(pParams.Item);
  EndIf;
EndProcedure

#EndRegion
