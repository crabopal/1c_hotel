#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;

	// Check edit prohibited date
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(Object.Hotel.EditProhibitedDate) And 
			BegOfDay(Object.Hotel.EditProhibitedDate) >= BegOfDay(Object.Date) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.Company) Then
		If ValueIsFilled(Object.Company.EditProhibitedDate) And 
			BegOfDay(Object.Company.EditProhibitedDate) >= BegOfDay(Object.Date) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	If Object.Posted Then
		vHasRightsToEdit = cmHasRightsToEditInvoice(Object.Company, Object.Date, Object.ExternalCode);
		If Not vHasRightsToEdit Then
			ReadOnly = True;
		EndIf;  
	EndIf;
	If ReadOnly Then
		Items.FillReservations.Visible = False;
	EndIf;
	
	// Rights to edit document number and date
	If Not IsInRole("Administrator") Then
		Items.Number.ReadOnly = True;
		Items.Date.ReadOnly = True;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Actions with new document
	If Not ValueIsFilled(Object.Ref) Then
		IsNew = True;
		vObj = FormAttributeToValue("Object");
		vObj.pmFillAttributesWithDefaultValues();
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	
	RateAmountIsIncludingTax = False;
	If ValueIsFilled(Object.Hotel) And 
	   Not ValueIsFilled(Object.Hotel.TouristTaxService) And 
	   Not Object.Hotel.TouristTaxAddToRate Then
		RateAmountIsIncludingTax = True;
	EndIf;
	
	// Fill printing button
	If ValueIsFilled(Object.Ref) Then
		FillPrintingButton();
	EndIf;
	
	// List is read only if is submitted
	Items.Reservations.ReadOnly = Object.IsSubmitted;
	Items.CorrectionNumber.ReadOnly = Object.IsSubmitted;
	Items.Hotel.ReadOnly = Object.IsSubmitted;
	Items.Company.ReadOnly = Object.IsSubmitted;
	Items.DateFrom.ReadOnly = Object.IsSubmitted;
	Items.DateTo.ReadOnly = Object.IsSubmitted;
	Items.ExternalCode.ReadOnly = Object.IsSubmitted;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	// Fill printing button
	If ValueIsFilled(pCurrentObject.Ref) And IsNew Then
		FillPrintingButton();
	EndIf;
	IsNew = False;
EndProcedure // AfterWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsReservationOnChange(pItem)
	vCurRow = Items.Reservations.CurrentRow;
	If vCurRow <> Undefined Then
		ReservationsReservationOnChangeAtServer(vCurRow);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsRateAmountOnChange(pItem)
	vRowData = Items.Reservations.CurrentData;
	If vRowData <> Undefined Then
		vRateAmountIsIncludingTax = RateAmountIsIncludingTax;
		vReservation = vRowData.Reservation;
		If ValueIsFilled(vReservation) Then
			vReservationRoomRate = vReservation.RoomRate;
			If ValueIsFilled(vReservationRoomRate) And (ValueIsFilled(vReservationRoomRate.TouristTaxService) Or vReservationRoomRate.TouristTaxAddToRate) Then
				vRateAmountIsIncludingTax = False;
			EndIf;
		EndIf;
		If vRateAmountIsIncludingTax Then
			vRowData.TaxAmount = Round((vRowData.RateAmount/vRowData.DurationInDays) * vRowData.TouristTaxRate / (100 + vRowData.TouristTaxRate), 2);
		Else
			vRowData.TaxAmount = Round((vRowData.RateAmount/vRowData.DurationInDays) * vRowData.TouristTaxRate / 100, 2);
		EndIf;
		vRowData.TaxAmount = Max(vRowData.TaxAmount, vRowData.MinAmountPerDay) * vRowData.DurationInDays;
		vRowData.TaxAmountToBePaid = vRowData.TaxAmount - vRowData.PaidTaxAmount;
		If vRateAmountIsIncludingTax Then
			vRowData.TaxBaseAmount = vRowData.RateAmount - vRowData.TaxAmount;
		Else
			vRowData.TaxBaseAmount = vRowData.RateAmount;
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsTaxBaseAmountOnChange(pItem)
	vRowData = Items.Reservations.CurrentData;
	If vRowData <> Undefined Then
		vRateAmountIsIncludingTax = RateAmountIsIncludingTax;
		vReservation = vRowData.Reservation;
		If ValueIsFilled(vReservation) Then
			vReservationRoomRate = vReservation.RoomRate;
			If ValueIsFilled(vReservationRoomRate) And (ValueIsFilled(vReservationRoomRate.TouristTaxService) Or vReservationRoomRate.TouristTaxAddToRate) Then
				vRateAmountIsIncludingTax = False;
			EndIf;
		EndIf;
		vRowData.TaxAmount = Round((vRowData.TaxBaseAmount/vRowData.DurationInDays) * vRowData.TouristTaxRate / 100, 2);
		vRowData.TaxAmount = Max(vRowData.TaxAmount, vRowData.MinAmountPerDay) * vRowData.DurationInDays;
		vRowData.TaxAmountToBePaid = vRowData.TaxAmount - vRowData.PaidTaxAmount;
		If vRateAmountIsIncludingTax Then
			vRowData.RateAmount = vRowData.TaxBaseAmount + vRowData.TaxAmount;
		Else
			vRowData.RateAmount = vRowData.TaxBaseAmount;
		EndIf;
	EndIf;
EndProcedure // ReservationsTaxBaseAmountOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsTouristTaxRateOnChange(pItem)
	vRowData = Items.Reservations.CurrentData;
	If vRowData <> Undefined Then
		vRateAmountIsIncludingTax = RateAmountIsIncludingTax;
		vReservation = vRowData.Reservation;
		If ValueIsFilled(vReservation) Then
			vReservationRoomRate = vReservation.RoomRate;
			If ValueIsFilled(vReservationRoomRate) And (ValueIsFilled(vReservationRoomRate.TouristTaxService) Or vReservationRoomRate.TouristTaxAddToRate) Then
				vRateAmountIsIncludingTax = False;
			EndIf;
		EndIf;
		If vRateAmountIsIncludingTax Then
			vRowData.TaxAmount = Round((vRowData.RateAmount/vRowData.DurationInDays) * vRowData.TouristTaxRate / (100 + vRowData.TouristTaxRate), 2);
		Else
			vRowData.TaxAmount = Round((vRowData.RateAmount/vRowData.DurationInDays) * vRowData.TouristTaxRate / 100, 2);
		EndIf;
		vRowData.TaxAmount = Max(vRowData.TaxAmount, vRowData.MinAmountPerDay) * vRowData.DurationInDays;
		vRowData.TaxAmountToBePaid = vRowData.TaxAmount - vRowData.PaidTaxAmount;
		If vRateAmountIsIncludingTax Then
			vRowData.TaxBaseAmount = vRowData.RateAmount - vRowData.TaxAmount;
		Else
			vRowData.TaxBaseAmount = vRowData.RateAmount;
		EndIf;
	EndIf;
EndProcedure // ReservationsTouristTaxRateOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsMinAmountPerDayOnChange(pItem)
	vRowData = Items.Reservations.CurrentData;
	If vRowData <> Undefined Then
		vRateAmountIsIncludingTax = RateAmountIsIncludingTax;
		vReservation = vRowData.Reservation;
		If ValueIsFilled(vReservation) Then
			vReservationRoomRate = vReservation.RoomRate;
			If ValueIsFilled(vReservationRoomRate) And (ValueIsFilled(vReservationRoomRate.TouristTaxService) Or vReservationRoomRate.TouristTaxAddToRate) Then
				vRateAmountIsIncludingTax = False;
			EndIf;
		EndIf;
		If vRateAmountIsIncludingTax Then
			vRowData.TaxAmount = Round((vRowData.RateAmount/vRowData.DurationInDays) * vRowData.TouristTaxRate / (100 + vRowData.TouristTaxRate), 2);
		Else
			vRowData.TaxAmount = Round((vRowData.RateAmount/vRowData.DurationInDays) * vRowData.TouristTaxRate / 100, 2);
		EndIf;
		vRowData.TaxAmount = Max(vRowData.TaxAmount, vRowData.MinAmountPerDay) * vRowData.DurationInDays;
		vRowData.TaxAmountToBePaid = vRowData.TaxAmount - vRowData.PaidTaxAmount;
		If vRateAmountIsIncludingTax Then
			vRowData.TaxBaseAmount = vRowData.RateAmount - vRowData.TaxAmount;
		Else
			vRowData.TaxBaseAmount = vRowData.RateAmount;
		EndIf;
	EndIf;
EndProcedure // ReservationsMinAmountPerDayOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsTaxAmountOnChange(pItem)
	vRowData = Items.Reservations.CurrentData;
	If vRowData <> Undefined Then
		vRateAmountIsIncludingTax = RateAmountIsIncludingTax;
		vReservation = vRowData.Reservation;
		If ValueIsFilled(vReservation) Then
			vReservationRoomRate = vReservation.RoomRate;
			If ValueIsFilled(vReservationRoomRate) And (ValueIsFilled(vReservationRoomRate.TouristTaxService) Or vReservationRoomRate.TouristTaxAddToRate) Then
				vRateAmountIsIncludingTax = False;
			EndIf;
		EndIf;
		vRowData.TaxAmountToBePaid = vRowData.TaxAmount - vRowData.PaidTaxAmount;
		If vRateAmountIsIncludingTax Then
			vRowData.TaxBaseAmount = vRowData.RateAmount - vRowData.TaxAmount;
		Else
			vRowData.TaxBaseAmount = vRowData.RateAmount;
		EndIf;
	EndIf;
EndProcedure // ReservationsTaxAmountOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsPaidTaxAmountOnChange(pItem)
	vRowData = Items.Reservations.CurrentData;
	If vRowData <> Undefined Then
		vRowData.TaxAmountToBePaid = vRowData.TaxAmount - vRowData.PaidTaxAmount;
	EndIf;
EndProcedure // ReservationsPaidTaxAmountOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsOnChange(pItem)
	Object.TaxAmountToBePaid = Round(Object.Reservations.Total("TaxAmountToBePaid"), 0, 1);
EndProcedure // ReservationsOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationsReservationOpening(pItem, pStandardProcessing)
	vRowData = Items.Reservations.CurrentData;
	If vRowData <> Undefined Then
		If ValueIsFilled(vRowData.Reservation) Then
			If TypeOf(vRowData.Reservation) = Type("DocumentRef.Reservation") Then
				vAccRef = GetAccommodationByReservation(vRowData.Reservation);
				If ValueIsFilled(vAccRef) Then
					pStandardProcessing = False;
					OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", vAccRef), ThisObject, vAccRef);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ReservationsReservationOpening

// --------------------------------------------------------------------------------
&AtClient
Procedure IsSubmittedOnChange(pItem)
	Items.Reservations.ReadOnly = Object.IsSubmitted;
	Items.CorrectionNumber.ReadOnly = Object.IsSubmitted;
	Items.Hotel.ReadOnly = Object.IsSubmitted;
	Items.Company.ReadOnly = Object.IsSubmitted;
	Items.DateFrom.ReadOnly = Object.IsSubmitted;
	Items.DateTo.ReadOnly = Object.IsSubmitted;
	Items.ExternalCode.ReadOnly = Object.IsSubmitted;
EndProcedure // IsSubmittedOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure FillReservations(pCommand)
	FillReservationsAtServer();
EndProcedure // FillReservations

// --------------------------------------------------------------------------------
&AtServer
Procedure RecalculateTouristTaxAtServer()
	Documents.TouristTaxDeclarationRU.RecalculateTouristTax(Object.DateFrom, Object.DateTo, Object.Hotel, Object.Company);
EndProcedure // RecalculateTouristTaxAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(pCommand)
	vDoc = Object.Ref;
	If Not ValueIsFilled(vDoc) Then
		Return;
	EndIf;
	
	// Choose processing type
	vPrintNumber = StrReplace(pCommand.Name, "Print","");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	
	// Load external print form
	If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
		Try
			OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref, vDoc);
		Except
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to load external print form!'; de = 'Das externe Druckformular konnte nicht geladen werden!'; ru = 'Не удалось загрузить внешнюю печатную форму!'"));
		EndTry;
	ElsIf ValueIsFilled(vPrintForm.Report) Then
		Try
			OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref, vDoc);
		Except
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to load external print form!'; de = 'Das externe Druckformular konnte nicht geladen werden!'; ru = 'Не удалось загрузить внешнюю печатную форму!'"));
		EndTry;
	ElsIf vPrintForm.PredefinedDataName = "TouristTaxDeclarationPrintRU" Then
		OpenForm("Document.TouristTaxDeclarationRU.Form.tcPrintForm", New Structure("Document, Language, PrintForm", vDoc, vPrintForm.Language, vPrintForm.Ref), ThisObject);
	ElsIf vPrintForm.PredefinedDataName = "TouristTaxDetailingDeclarationPrintRU" Then
		OpenForm("Document.TouristTaxDeclarationRU.Form.tcDetailingPrintForm", New Structure("Document, Language, PrintForm", vDoc, vPrintForm.Language, vPrintForm.Ref), ThisObject);
	EndIf;
EndProcedure  

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName,
	|	ObjectPrintingForms.IsDefault AS IsDefault,
	|	ObjectPrintingForms.Language AS Language
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	NOT ObjectPrintingForms.DeletionMark
	|	AND ObjectPrintingForms.IsActive = TRUE
	|	AND ObjectPrintingForms.ObjectType = &ObjectType
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code
	|TOTALS BY
	|	Language";
	
	Query.SetParameter("ObjectType", Documents.TouristTaxDeclarationRU.EmptyRef());	
	QueryResult = Query.Execute();	
	SelectionRecords = QueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	vLang = SessionParameters.CurrentLanguage;
	While SelectionRecords.Next() Do
		SelectionDetailRecords = SelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = SelectionRecords.Language Or not ValueIsFilled(SelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf Not vLang = SelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtra, "Print" + SelectionRecords.Language, "FormGroup",
												  New Structure("Type,Title", FormGroupType.Popup, SelectionRecords.Language));
		EndIf;
		
		While SelectionDetailRecords.Next() Do
			If SelectionDetailRecords.PredefinedDataName = "" 
				Or SelectionDetailRecords.PredefinedDataName = "TouristTaxDetailingDeclarationPrintRU" 
				Or SelectionDetailRecords.PredefinedDataName = "TouristTaxDeclarationPrintRU"  Then 
				vNewRow = PrintForms.Add();
				vNewRow.PrintForm = SelectionDetailRecords.Ref;
				vNewRow.IsDefault = SelectionDetailRecords.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add("Print" + vID);
				vCommand.Action = "PrintButtonClick";
				If SelectionDetailRecords.IsDefault Then
					vParent = Items.FormGroupPrintingDefault;
				Else
					vParent = vParentLang;
				EndIf;
				vStructure = New Structure("Title, CommandName",
				TrimAll(SelectionDetailRecords.Code) + " " + cmNStr(SelectionDetailRecords.ref), "Print" + vID);
				        
				tcOnServer.cmCreateItem(ThisObject, vParent, "Print" + vID, "FormButton", vStructure);  
			EndIf;
		EndDo;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
//
// Parameters:
//  pActionsNumber	 - String - Choosed print form number
// 
// Returns:
// 	Structure - Print form data 
//
&AtServer
Function GetPrintFormForNumber(pActionsNumber)
	vPrintForms = PrintForms.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref", vPrintForms);
	vStruct.Insert("PredefinedDataName", vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing", vPrintForms.ExternalProcessing);
	vStruct.Insert("Report", vPrintForms.Report);
	vStruct.Insert("Language", vPrintForms.Language);
	
	Return vStruct;
EndFunction // GetPrintFormForNumber

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef, pMessagesList)
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage");
	vName = ConnectExternalDataProcessor(vURL, GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(pExtProcRef, "FileName")));
	vParams = New Structure("InputParameter, ObjectPrintingForm", pMessagesList, pPrintFormTypeRef);
	OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef, pMessagesList)
	vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef, "Report"), "ExternalProcessingStorage"); 
	vName = ConnectExternalReport(vURL, "ExternalReportForm");
	vParams = New Structure("Document, ObjectPrintingForm", pMessagesList, pPrintFormTypeRef);
	OpenForm("ExternalReport." + vName + ".Form", vParams);
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPath		 - String - Path to external data processor
//  pName		 - String - Data processor name
//  pUseSafeMode - Boolean - Use safe mode
// 
// Returns:
//  String - Name of data processor to open it
//
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
//
// Parameters:
//  pStr - String - External processing name to validate 
// 
// Returns:
//  String - Valid name
//
&AtServer
Function GetExternalProcessingValidName(Val pStr)
	Return cmGetValidName(pStr); 	
EndFunction // GetExternalProcessingValidName

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPath		 - String - Path to external report
//  pName		 - String - Report name
//  pUseSafeMode - Boolean - Use safe mode
// 
// Returns:
//  String - Name of report to open it 
//
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// --------------------------------------------------------------------------------
&AtServer
Procedure ReservationsReservationOnChangeAtServer(pRowID)
	vRowData = Object.Reservations.FindByID(pRowID);
	If vRowData <> Undefined Then
		vReservation = vRowData.Reservation;
		If ValueIsFilled(vReservation) Then
			vRowData.GuestGroup = vReservation.GuestGroup;
			If TypeOf(vReservation) = Type("DocumentRef.Accommodation") Then
				vRowData.Reservation = vReservation.Reservation;
			EndIf;
			vRowData.CheckInDate = vReservation.CheckInDate;
			vRowData.CheckOutDate = vReservation.CheckOutDate;
			vRowData.DurationInDays = vReservation.DurationInDays;
			vRowData.RateAmount = vReservation.RateSumInBaseCurrency;
			vRowData.TouristTaxRate = vReservation.TouristTaxRate;
			vRowData.MinAmountPerDay = vReservation.MinAmountPerDay;
			vRowData.TouristicTaxExemptionReason = vReservation.TouristicTaxExemptionReason;
			vRowData.TaxAmount = vReservation.TouristTaxSumInBaseCurrency;
			vRowData.PaidTaxAmount = 0;
			vRowData.TaxAmountToBePaid = vRowData.TaxAmount - vRowData.PaidTaxAmount;
			vRateAmountIsIncludingTax = RateAmountIsIncludingTax;
			vReservationRoomRate = vReservation.RoomRate;
			If ValueIsFilled(vReservationRoomRate) And (ValueIsFilled(vReservationRoomRate.TouristTaxService) Or vReservationRoomRate.TouristTaxAddToRate) Then
				vRateAmountIsIncludingTax = False;
			EndIf;
			If vRateAmountIsIncludingTax Then
				vRowData.TaxBaseAmount = vRowData.RateAmount - vRowData.TaxAmount;
			Else
				vRowData.TaxBaseAmount = vRowData.RateAmount;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ReservationsReservationOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure FillReservationsAtServer()
	vObj = FormAttributeToValue("Object");
	vMessage = "";
	vAttributeInErr = "";
	If Not vObj.pmCheckDocumentAttributes(vMessage, vAttributeInErr) Then
		vObj.pmFillReservations();
	Else
		SetObjectAndFormAttributeConformity(vObj, "Object");
		vUM = New UserMessage();
		vUM.SetData(vObj);
		If Not IsBlankString(vAttributeInErr) Then
			vUM.Field = vAttributeInErr;
		EndIf;
		vUM.Text = cmNStr(vMessage);
		vUM.Message();
	EndIf;
	ValueToFormAttribute(vObj, "Object");

	Items.Reservations.ReadOnly = Object.IsSubmitted;
	Items.CorrectionNumber.ReadOnly = Object.IsSubmitted;
	Items.Hotel.ReadOnly = Object.IsSubmitted;
	Items.Company.ReadOnly = Object.IsSubmitted;
	Items.DateFrom.ReadOnly = Object.IsSubmitted;
	Items.DateTo.ReadOnly = Object.IsSubmitted;
	Items.ExternalCode.ReadOnly = Object.IsSubmitted;
EndProcedure // FillReservationsAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetAccommodationByReservation(pReservation)
	Return cmGetAccommodationByReservation(pReservation);
EndFunction // GetAccommodationByReservation

// --------------------------------------------------------------------------------
&AtClient
Procedure RecalculateTouristTax(pCommand)
	RecalculateTouristTaxAtServer();
	ShowMessageBox(, NStr("en='Done!'; ru='Выполнено!'; de='Fertig!'"));
EndProcedure // RecalculateTouristTax

#EndRegion
