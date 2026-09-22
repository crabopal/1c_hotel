
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);

	If Parameters.Property("FillingValues") And Parameters.FillingValues.Count() > 0 Then
		Filling(Parameters.FillingValues);
	Else	
		SelPeriod = '00010101';
	EndIf;
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		SelCustomer = SessionParameters.CurrentUser.Customer;
		AttributeChangeAtServer("AccountingCustomer", SelCustomer);
		Items.SelCustomer.ReadOnly = True;
		Items.SelCustomer.ChoiceButton = False;
		Items.SelCustomer.ClearButton = False;
		Items.SelCustomer.OpenButton = False;
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
			AttributeChangeAtServer("Date", SelPeriod);
		EndIf;
	EndIf;
	If Not Parameters.Property("SelCustomer") And Not Parameters.Property("SelGuestGroup") And Not Parameters.Property("SelPeriod") Then
		SelPeriod = BegOfDay(CurrentSessionDate()) - 24 * 3600;
		AttributeChangeAtServer("Date", SelPeriod);
	EndIf;
	If Parameters.Property("ChoiceMode") Then
		Items.List.ChoiceMode = Parameters.ChoiceMode;
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	SetParametersDinamicList();
	FillPrintingButton();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "System.Hotel.Changed" And Parameter <> SelHotel Then
		SetParametersDinamicList();
		RefreshDataRepresentation();
	ElsIf EventName = "Subsystem.Accounts.Changed" Then
		SetParametersDinamicList();
		RefreshDataRepresentation();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerOnChange(pItem)
	If ValueIsFilled(SelCustomer) Then
		AttributeChangeAtServer("AccountingCustomer", SelCustomer);
	Else
		SelCustomerClearing(pItem, True);
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
		SelContractClearing(pItem, True);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelContractClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("AccountingContract");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	SelGuestGroupOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("GuestGroup");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("Date");
	ClearingAttributeAtServer("ChangeDate");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodOnChange(pItem)
	If ValueIsFilled(SelPeriod) Then
		If SelFilterChangeDate Then
			ClearingAttributeAtServer("Date");
			AttributeChangeAtServer("ChangeDate", BegOfDay(SelPeriod));
		Else
			ClearingAttributeAtServer("ChangeDate");
			AttributeChangeAtServer("Date", BegOfDay(SelPeriod));
		EndIf;
	Else
		SelPeriodClearing(pItem, True);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFilterChangeDateOnChange(pItem)
	SelPeriodOnChange(Items.SelPeriod);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If Not Items.List.ChoiceMode Then
		If pField.Name = "GuestGroup" Then
			pStandardProcessing = False;
			vRowData = Items.List.RowData(pSelectedRow);
			If ValueIsFilled(vRowData.GuestGroup) Then
				OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", vRowData.GuestGroup));
			EndIf;
		ElsIf pField.Name = "IsChecked" Then
			pStandardProcessing = False;
			vRowData = Items.List.RowData(pSelectedRow);
			If ValueIsFilled(vRowData.Ref) Then
				If Not vRowData.DeletionMark Then
					UpdateInvoiceIsCheckedFlagAtServer(vRowData.Ref);
					Items.List.Refresh();
				Else
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Invoice is marked for deletion!'; ru='Акт помечен на удаление!'; de='Rechnung ist zum Löschen vorgemerkt!'"));
				EndIf;
			EndIf;
		EndIf;
	Else
		vRowData = Items.List.RowData(pSelectedRow);
		NotifyChoice(vRowData.Ref);
	EndIf;
EndProcedure // ListSelection

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(pCommand)
	vInvoices = New ValueList();
	For Each vSelRow In Items.List.SelectedRows Do
		vInvoices.Add(vSelRow);
	EndDo;
	// Choose processing type
	vPrintNumber = StrReplace(pCommand.Name,"Print","");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	// Load external print form
		vPrintFormType = "";
		If Left(vPrintForm.PredefinedDataName, 22) = "SettlementPrintInvoice" Then
			vPrintFormType = "Invoice";
		ElsIf Left(vPrintForm.PredefinedDataName, 25) = "SettlementPrintSettlement" Then
			vPrintFormType =  "Settlement";
		ElsIf Left(vPrintForm.PredefinedDataName, 25) = "SettlementPrintVATInvoice" Then
			vPrintFormType =  "VATInvoice";
		ElsIf Left(vPrintForm.PredefinedDataName, 17) = "SettlementPrint7G" Then
			vPrintFormType =  "Settlement7G";
		ElsIf vPrintForm.PredefinedDataName = "SettlementPrintHotelProducts" Then
			vPrintFormType =  "SettlementHotelProduct";
		EndIf;
		If vInvoices.Count() > 1 Then
			OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoices, Language, PrintForm, PrintFormType", vInvoices, vPrintForm.Language, vPrintForm.Ref, vPrintFormType), ThisObject);
		ElsIf vInvoices.Count() = 1 Then 
			OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm, PrintFormType", vInvoices.Get(0).Value, vPrintForm.Language, vPrintForm.Ref, vPrintFormType), ThisObject);	
		EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BulkCheckOfInvoices(pCommand)
	OpenForm("Document.Settlement.Form.tcBulkCheckOfInvoices", , ThisObject);
EndProcedure // BulkCheckOfInvoices

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetParametersDinamicList()
	// Set default parameters
	List.Parameters.SetParameterValue("qHotel", SelHotel);
	List.Parameters.SetParameterValue("qGuestGroup", SelGuestGroup);
	Title = NStr("en='Debit notes: '; ru='Дебетовые корректировки: '; de='Lastschriften: '") + ?(ValueIsFilled(SelHotel), Catalogs.Hotels.pmGetHotelPrintName(SelHotel, SessionParameters.CurrentLanguage), "");
EndProcedure //  SetParametersDinamicList()

// -----------------------------------------------------------------------------
&AtServer
Procedure Filling(pParameters)
	If pParameters.Property("SelPeriod") Then
		SelPeriod = pParameters.SelPeriod;
		If ValueIsFilled(SelPeriod) Then 
			AttributeChangeAtServer("Date", BegOfDay(SelPeriod));	
		EndIf;	
	EndIf;	
	If pParameters.Property("SelGuestGroup") Then
		SelGuestGroup = pParameters.SelGuestGroup;
	EndIf;	
	If pParameters.Property("SelCustomer") Then
		SelCustomer = pParameters.SelCustomer;
		AttributeChangeAtServer("AccountingCustomer", SelCustomer);
	EndIf;	
EndProcedure //  Filling()

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	vComparisonType = ?(pComparisonType=Undefined, DataCompositionComparisonType.Equal, pComparisonType);
	vValue = pValue;	
	If ValueIsFilled(vValue) Then
		vFilter = List.Filter;
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
			For Each int In vFilter.Items Do
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
	vFilter = List.Filter;
	vValue = New DataCompositionField(pAttribute);
	For Each int In vFilter.Items Do
		If int.LeftValue = vValue Then
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
Procedure SelGuestGroupOnChangeAtServer()
	SetParametersDinamicList();
EndProcedure // SelGuestGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure UpdateInvoiceIsCheckedFlagAtServer(pInvoice)
	vInvObj = pInvoice.GetObject();
	vInvObj.IsChecked = Not vInvObj.IsChecked;
	If Not ValueIsFilled(vInvObj.ChangeDate) And ValueIsFilled(vInvObj.Date) Then
		vInvObj.ChangeDate = vInvObj.Date;
	Else
		vInvObj.ChangeDate = CurrentSessionDate();
	EndIf;
	vInvObj.ChangeAuthor = SessionParameters.CurrentUser;
	If Not vInvObj.Posted Then
		vInvObj.Write(DocumentWriteMode.Posting);
	Else
		vInvObj.Write(DocumentWriteMode.Write);
	EndIf;
EndProcedure // UpdateInvoiceIsCheckedFlagAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	vQuery = New Query;
	vQuery.Text = 
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
	
	vQuery.SetParameter("ObjectType", Documents.DebitNote.EmptyRef());	
	QueryResult = vQuery.Execute();	
	vSel = QueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	vLang = SessionParameters.CurrentLanguage;
	While vSel.Next() Do
		vSelDetails = vSel.Select(QueryResultIteration.ByGroups);
		
		If vLang = vSel.Language Or not ValueIsFilled(vSel.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf Not vLang = vSel.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtra, "Print" + vSel.Language, "FormGroup",
												  New Structure("Type, Title", FormGroupType.Popup, vSel.Language));
		EndIf;
		
		While vSelDetails.Next() Do
			vNewRow = PrintForms.Add();
			vNewRow.PrintForm = vSelDetails.Ref;
			vNewRow.IsDefault = vSelDetails.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("Print" + vID);
			vCommand.Action = "PrintButtonClick";
			If vSelDetails.IsDefault Then
				vParent = Items.FormGroupPrintingDefault;
			Else
				vParent = vParentLang;
			EndIf;
			vStructure = New Structure("Title, CommandName", TrimAll(vSelDetails.Code) + " " + cmNStr(vSelDetails.ref), "Print" + vID);
			        
			tcOnServer.cmCreateItem(ThisObject, vParent, "Print" + vID, "FormButton", vStructure);
		EndDo;
	EndDo;
EndProcedure

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
EndFunction // GetPrintFormForNumber

#EndRegion
