#Region FormsEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);

	If Parameters.Property("FillingValues") And Parameters.FillingValues.Count()> 0 Then
		Filling(Parameters.FillingValues);
	Else	
		SelFilterStatus = 0;
		SelPeriod = '00010101';
	EndIf;
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		SelCustomer = SessionParameters.CurrentUser.Customer;
		AttributeChangeAtServer("AccountingCustomer", SelCustomer);
		Items.SelCustomer.ReadOnly = True;
		Items.SelCustomer.ChoiceButton = False;
		Items.SelCustomer.ClearButton = False;
		Items.SelCustomer.OpenButton = False;
		Items.SelContract.ReadOnly = True;
		Items.SelContract.ChoiceButton = False;
		Items.SelContract.ClearButton = False;
		Items.SelContract.OpenButton = False;
	EndIf;
	If Parameters.Property("ChoiceMode") Then
		Items.List.ChoiceMode = Parameters.ChoiceMode;
	EndIf;
	If Parameters.Property("SelHotel") Then
		SelHotel = Parameters.SelHotel;
	Else
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Parameters.Property("SelCustomer") Then
		SelCustomer = Parameters.SelCustomer;
		If ValueIsFilled(SelCustomer) Then
			AttributeChangeAtServer("AccountingCustomer", SelCustomer);
		EndIf;
	EndIf;
	If Parameters.Property("SelContract") Then
		SelContract = Parameters.SelContract;
		If ValueIsFilled(SelContract) Then
			AttributeChangeAtServer("AccountingContract", SelContract);
		EndIf;
	EndIf;
	If Parameters.Property("SelGuestGroup") Then
		SelGuestGroup = Parameters.SelGuestGroup;
		If ValueIsFilled(SelGuestGroup) Then
			If SelGuestGroup.Owner <> SelHotel Then
				SelHotel = SelGuestGroup.Owner;
			EndIf;
		EndIf;
	EndIf;
	If Parameters.Property("SelPeriod") Then
		SelPeriod = Parameters.SelPeriod;
		If ValueIsFilled(SelPeriod) Then
			AttributeChangeAtServer("AccountingDate", SelPeriod);
		EndIf;
	EndIf;
	If Not Parameters.Property("SelCustomer") And Not Parameters.Property("SelGuestGroup") And Not Parameters.Property("SelPeriod") Then
		If Not ValueIsFilled(SelPeriod) Then
			SelPeriod = BegOfDay(CurrentSessionDate());
			AttributeChangeAtServer("AccountingDate", SelPeriod);
		EndIf;
	EndIf;		
	// Set hotel color          
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	EndIf;
	// Hotel column appearance
	If Not ValueIsFilled(SelHotel) Then
		Items.Hotel.Visible = True;
	Else
		Items.Hotel.Visible = False;
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	// Set dynamic list parameters
	SetParametersDinamicList();
	// Availability
	Items.GroupFill.Enabled = ValueIsFilled(SelHotel);
	// Printing
	FillPrintingButton();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "System.Hotel.Changed" And pParameter <> SelHotel Then
		SetParametersDinamicList();
		RefreshDataRepresentation();
	ElsIf pEventName = "Subsystem.Accounts.Changed" Then
		SetParametersDinamicList();
		RefreshDataRepresentation();
	EndIf;
EndProcedure

#EndRegion

#Region ItemsFormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure SetParametersDinamicList()
	// Set default parameters
	DocumentList.Parameters.SetParameterValue("qHotel", SelHotel);
	DocumentList.Parameters.SetParameterValue("qEmptyDate", '00010101');
	DocumentList.Parameters.SetParameterValue("qCurrentDate", CurrentSessionDate());                                             
	DocumentList.Parameters.SetParameterValue("qGuestGroup", SelGuestGroup);
	Title = NStr("en='Pro-Forma Invoices: '; ru='Счета на оплату: '; de='Pro-Forma Rechnungen: '") + ?(ValueIsFilled(SelHotel), Catalogs.Hotels.pmGetHotelPrintName(SelHotel, SessionParameters.CurrentLanguage), "");
EndProcedure //  SetParametersDinamicList()

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterStatusOnChange(pItem)
	FilterStatusOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FilterStatusOnChangeAtServer()
	If SelFilterStatus = 0 Then
		ClearingAttributeAtServer("IDStatus");	
	Else
		AttributeChangeAtServer("IDStatus", SelFilterStatus);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	SelGuestGroupOnChangeAtServer();
EndProcedure // SelGuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("GuestGroup");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerOnChange(pItem)
	If ValueIsFilled(SelCustomer) Then
		AttributeChangeAtServer("AccountingCustomer", SelCustomer);
	Else
		ClearingAttributeAtServer("AccountingCustomer");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("AccountingCustomer");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelContractOnChange(pItem)
	If ValueIsFilled(SelContract) Then
		AttributeChangeAtServer("AccountingContract", SelContract);
	Else
		ClearingAttributeAtServer("AccountingContract");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelContractClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("AccountingContract");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAuthorOnChange(pItem)
	If ValueIsFilled(SelAuthor) Then
		AttributeChangeAtServer("Author", SelAuthor);
	Else
		ClearingAttributeAtServer("Author");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAuthorClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("Author");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SelHotelOnChangeAtServer();
	Items.GroupFill.Enabled = ValueIsFilled(SelHotel);
EndProcedure //  SelHotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodOnChange(pItem)
	If ValueIsFilled(SelPeriod) Then
		AttributeChangeAtServer("AccountingDate", BegOfDay(SelPeriod));
	Else
		ClearingAttributeAtServer("AccountingDate");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("AccountingDate");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If pField.Name = "GuestGroup" Then
		pStandardProcessing = False;
		vRowData = Items.List.RowData(pSelectedRow);
		If ValueIsFilled(vRowData.GuestGroup) Then
			OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", vRowData.GuestGroup));
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(pCommand)
	If Items.List.SelectedRows.Count() > 0 Then
		vProformaInvoice = Undefined;
		vProformas = New ValueList();
		For Each vSelRow In Items.List.SelectedRows Do
			If vProformaInvoice = Undefined Then
				vProformaInvoice = vSelRow;
			EndIf;
			vProformas.Add(vSelRow);
		EndDo;
		// Choose processing type
		vPrintNumber = StrReplace(pCommand.Name, "Print", "");
		vPrintForm = GetPrintFormForNumber(vPrintNumber);
		If ValueIsFilled(vPrintForm.Ref) Then
			// Load external print form
			If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
				Try
					OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref, vProformaInvoice);
				Except
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
				EndTry;
			ElsIf ValueIsFilled(vPrintForm.Report) Then
				Try
					OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref);
				Except
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
				EndTry;
			Else
				vPrintFormType = "";
				If Left(vPrintForm.PredefinedDataName, 19) = "InvoicePrintInvoice" Then
					vPrintFormType = "PrintInvoiceForm";
				ElsIf Left(vPrintForm.PredefinedDataName, 24) = "InvoicePrintShortInvoice" Then
					vPrintFormType =  "PrintInvoiceShortForm";
				ElsIf Left(vPrintForm.PredefinedDataName, 25) = "InvoicePrintHotelProducts" Then
					vPrintFormType =  "PrintInvoiceHotelProductsForm";
				ElsIf vPrintForm.PredefinedDataName = "InvoicePrintPaymentOrder" Then
					vPrintFormType =  "PrintPaymentOrder";  
				ElsIf Left(vPrintForm.PredefinedDataName, 25) = "InvoicePrintSimpleInvoice" Then
					vPrintFormType =  "PrintInvoiceSimpleForm";  
				EndIf;
				vParams = New Structure();
				If vProformas.Count() = 1 Then 
					vParams.Insert("Invoice", vProformas.Get(0).Value);
				ElsIf vProformas.Count() > 1 Then 
					vParams.Insert("Invoices", vProformas);	
				EndIf;
				If vPrintFormType <> "PrintPaymentOrder" And vPrintFormType <> "PrintInvoiceSimpleForm" Then
					vParams.Insert("GroupBy", GetPrintGroupBy(vPrintFormType, vPrintForm.PredefinedDataName));
				EndIf;
				vParams.Insert("Language", vPrintForm.Language);
				vParams.Insert("PrintForm", vPrintForm.Ref);
				
				If vPrintFormType = "PrintInvoiceForm" Then
					OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintForm", vParams, ThisObject);
				ElsIf vPrintFormType = "PrintInvoiceShortForm" Then
					OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintShortForm", vParams, ThisObject);
				ElsIf vPrintFormType = "PrintInvoiceHotelProductsForm" Then
					OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintHotelProductsForm", vParams, ThisObject);
				ElsIf vPrintFormType = "PrintPaymentOrder" Then
					OpenForm("Document.ProformaInvoice.Form.tcPaymentOrderForm", vParams, ThisObject);  
				ElsIf vPrintFormType = "PrintInvoiceSimpleForm" Then
					OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintSimpleForm", vParams, ThisObject);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintButtonClick

#EndRegion

#Region SystemEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure SelHotelOnChangeAtServer()
	SetParametersDinamicList();
	// Hotel column appearance
	If Not ValueIsFilled(SelHotel) Then
		Items.Hotel.Visible = True;
	Else
		Items.Hotel.Visible = False;
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");	
EndProcedure // SelHotelOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	If Not IsInRoleAtServer("RightsToChooseHotel") Then
		pStandardProcessing = False;
	ENdIf;
EndProcedure //  SelHotelClearing

// -----------------------------------------------------------------------------
&AtServer
Procedure SelGuestGroupOnChangeAtServer()
	SetParametersDinamicList();
EndProcedure // SelGuestGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRoleName)
	Return IsInRole(pRoleName);
EndFunction //  IsInRoleAtServer

// -----------------------------------------------------------------------------
// Procedure - Attribute change at server
// 
// Parameters:
//  pAttribute	 - as string name DataCompositionField 
//  pValue		 - ref item 
//  pComparisonType - Data Composition Comparison Type 
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	vComparisonType =  ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
	vValue = pValue;	
	If ValueIsFilled(vValue) Then
		vFilter = DocumentList.Filter;
		vField = New DataCompositionField(pAttribute);
		If vFilter.Items.Count()=0 Then	
			vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
			vFilterItem.LeftValue = vField;
			vFilterItem.ComparisonType = vComparisonType;
			vFilterItem.RightValue = vValue;
			vFilterItem.Use = True;
		Else
			// Find field
			vCancel = False;
			For Each int In  vFilter.Items Do
				If  int.LeftValue = vField  Then
					// Field delete
					vFilter.Items.Delete(int);	
					// Add a new
					vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
					vFilterItem.LeftValue = vField;
					vFilterItem.ComparisonType = vComparisonType;
					vFilterItem.RightValue = vValue;
					vFilterItem.Use = True;
					vCancel = True;
					Break;
				EndIf;	
			EndDo;
			If Not vCancel Then
				// The field is not found, we add a new
				vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
				vFilterItem.LeftValue = vField;
				vFilterItem.ComparisonType = vComparisonType;
				vFilterItem.RightValue = vValue;
				vFilterItem.Use = True;
			EndIf;
		EndIf;
	EndIf;
	Items.List.Refresh();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	vFilter = DocumentList.Filter;
	vValue = New DataCompositionField(pAttribute);
	For Each int In vFilter.Items Do
		If  int.LeftValue = vValue  Then
			// Field delete
			vFilter.Items.Delete(int);	
			// Refresh page
			Items.List.Refresh();
			Break;
		EndIf;	
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure Filling(pParameters)
	If pParameters.Property("SelFilterStatus") Then
		SelFilterStatus = pParameters.SelFilterStatus;
		FilterStatusOnChangeAtServer();
	EndIf;	
	If pParameters.Property("SelPeriod") Then
		SelPeriod = pParameters.SelPeriod;
		If ValueIsFilled(SelPeriod) Then 
			AttributeChangeAtServer("AccountingDate", BegOfDay(SelPeriod));	
		EndIf;	
	EndIf;	
	If pParameters.Property("SelGuestGroup") And ValueIsFilled(pParameters.SelGuestGroup) Then
		SelGuestGroup = pParameters.SelGuestGroup;
	EndIf;	
	If pParameters.Property("SelCustomer") And ValueIsFilled(pParameters.SelCustomer) Then
		SelCustomer = pParameters.SelCustomer;
		AttributeChangeAtServer("AccountingCustomer", SelCustomer);
	EndIf;	
	If pParameters.Property("SelContract") And ValueIsFilled(pParameters.SelContract) Then
		SelContract = pParameters.SelContract;
		AttributeChangeAtServer("AccountingContract", SelContract);
	EndIf;	
EndProcedure //  Filling()

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref AS Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName AS PredefinedDataName,
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
	
	Query.SetParameter("ObjectType", Documents.ProformaInvoice.EmptyRef());	
	QueryResult = Query.Execute();	
	SelectionRecords = QueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	vLang = SessionParameters.CurrentLanguage;
	While SelectionRecords.Next() Do
		SelectionDetailRecords = SelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = SelectionRecords.Language Or Not ValueIsFilled(SelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf Not vLang = SelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtra, "Print" + SelectionRecords.Language, "FormGroup",
			                                      New Structure("Type, Title", FormGroupType.Popup, SelectionRecords.Language));
		EndIf;
		
		While SelectionDetailRecords.Next() Do
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
			        
			tcOnServer.cmCreateItem(ThisObject, vParent, "Print" + vID,"FormButton", vStructure);
		EndDo;
	EndDo;
EndProcedure //  FillPrintingButton

// -----------------------------------------------------------------------------
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
EndFunction //  GetPrintFormForNumber

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintGroupBy(pTypeOfPrintForm, pPredefinedDataName)
	vForm = Catalogs.ObjectPrintingForms;
	vGroupBy = "";
	If ValueIsFilled(pTypeOfPrintForm) Then
		If pTypeOfPrintForm = "PrintInvoiceForm" Then
			If pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerClientPerDayRu" Or
			   pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerClientPerDayEn" Or
			   pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerClientPerDayDe" Then
				vGroupBy = "InPricePerClientPerDay";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerDayRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerDayEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerDayDe" Then
				vGroupBy = "InPricePerDay";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupPerClientRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupPerClientEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupPerClientDe" Then
				vGroupBy = "PerClient";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupByServiceRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupByServiceEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupByServiceDe" Then
				vGroupBy = "ByService";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerClientPerDayRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerClientPerDayEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerClientPerDayDe" Then
				vGroupBy = "AllPerClientPerDay";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerDayRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerDayEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerDayDe" Then
				vGroupBy = "AllPerDay";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerClientRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerClientEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerClientDe" Then
				vGroupBy = "InPricePerClient";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupInPriceRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupInPriceEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupInPriceDe" Then
				vGroupBy = "InPrice";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerClientRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerClientEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerClientDe" Then
				vGroupBy = "AllPerClient";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupAllRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllDe" Then
				vGroupBy = "All";
			EndIf;
		ElsIf pTypeOfPrintForm = "PrintInvoiceShortForm" Then
			If pPredefinedDataName = "InvoicePrintShortInvoiceGroupInPriceRu" Or
			   pPredefinedDataName = "InvoicePrintShortInvoiceGroupInPriceEn" Or
			   pPredefinedDataName = "InvoicePrintShortInvoiceGroupInPriceDe" Then
				vGroupBy = "InPrice";
			ElsIf pPredefinedDataName = "InvoicePrintShortInvoiceGroupAllRu" Or
			      pPredefinedDataName = "InvoicePrintShortInvoiceGroupAllEn" Or
			      pPredefinedDataName = "InvoicePrintShortInvoiceGroupAllDe" Then
				vGroupBy = "All";
			ElsIf pPredefinedDataName = "InvoicePrintShortInvoiceGroupByServiceRu" Or
			      pPredefinedDataName = "InvoicePrintShortInvoiceGroupByServiceEn" Or
			      pPredefinedDataName = "InvoicePrintShortInvoiceGroupByServiceDe" Then
				vGroupBy = "ByService";
			EndIf;
		ElsIf pTypeOfPrintForm = "PrintInvoiceHotelProductsForm" Then
			If pPredefinedDataName = "InvoicePrintHotelProductsGroupInPriceRu" Or
			   pPredefinedDataName = "InvoicePrintHotelProductsGroupInPriceEn" Or
			   pPredefinedDataName = "InvoicePrintHotelProductsGroupInPriceDe" Then
				vGroupBy = "InPrice";
			ElsIf pPredefinedDataName = "InvoicePrintHotelProductsGroupAllRu" Or
			      pPredefinedDataName = "InvoicePrintHotelProductsGroupAllEn" Or
			      pPredefinedDataName = "InvoicePrintHotelProductsGroupAllDe" Then
				vGroupBy = "All";
			ElsIf pPredefinedDataName = "InvoicePrintHotelProductsGroupByServiceRu" Or
			      pPredefinedDataName = "InvoicePrintHotelProductsGroupByServiceEn" Or
			      pPredefinedDataName = "InvoicePrintHotelProductsGroupByServiceDe" Then
				vGroupBy = "ByService";
			EndIf;
		EndIf;
	EndIf;	
	Return vGroupBy;
EndFunction // GetPrintGroupBy

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef, pProformaRef)
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage");
	vName = ConnectExternalDataProcessor(vURL, GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(pExtProcRef,"FileName")));
	vParams = New Structure("InputParameter, ObjectPrintingForm", pProformaRef, pPrintFormTypeRef);
	OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef)
	ShowMessageBox(, NStr("en='Not supported in thin or web client mode!'; ru='Не поддерживается в режиме тонкого и WEB клиента!'; de='Nicht in Dünnen-Client-Modus oder Web-Client-Modus unterstützt!'"));
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Function GetExternalProcessingValidName(Val pStr)
	Return cmGetValidName(pStr); 	
EndFunction // GetExternalProcessingValidName

#EndRegion
