#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Hotel = SessionParameters.CurrentHotel;
	
	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		Items.List.ChoiceMode = Parameters.ChoiceMode;
	EndIf;
	
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("GuestGroup") Then
			GuestGroup = Parameters.Filter.GuestGroup;
			If ValueIsFilled(GuestGroup) Then
				AttributeChangeAtServer("GuestGroup", GuestGroup);
			EndIf;
		EndIf;
		If Parameters.Filter.Property("Customer") Then
			Customer = Parameters.Filter.Customer;
			If ValueIsFilled(Customer) Then
				AttributeChangeAtServer("Customer", Customer);
			EndIf;
		EndIf;
		If Parameters.Filter.Property("Contract") Then
			Contract = Parameters.Filter.Contract;
			If ValueIsFilled(Contract) Then
				AttributeChangeAtServer("Contract", Contract);
			EndIf;
		EndIf;
		If Parameters.Filter.Property("CloseOfPeriod") Then
			CloseOfPeriod = Parameters.Filter.CloseOfPeriod;
		EndIf;
		If Parameters.Filter.Property("Folio") Then
			Folio = Parameters.Filter.Folio;
		EndIf;
		If Parameters.Filter.Property("Service") Then
			Service = Parameters.Filter.Service;
		EndIf;
		If Parameters.Filter.Property("Hotel") Then
			Hotel = Parameters.Filter.Hotel;
		EndIf;
		If Parameters.Filter.Property("Date") Then
			SelDateFrom = Parameters.Filter.Date;
			SelDateTo = Parameters.Filter.Date;
		EndIf;
	EndIf;
	If ValueIsFilled(GuestGroup) Then
		If GuestGroup.Owner <> Hotel Then
			Hotel = GuestGroup.Owner;
		EndIf;
	EndIf;
	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	If Not IsInRole("RightsToChooseHotel") Then
		Items.HotelFilter.ReadOnly = True;
		Items.HotelFilter.ChoiceButton = False;
		Items.HotelFilter.ClearButton = False;
	EndIf;
	
	List.Parameters.SetParameterValue("qHotel", Hotel);
	List.Parameters.SetParameterValue("qCompany", Company);
	List.Parameters.SetParameterValue("qGuestGroupIsSelected", ValueIsFilled(GuestGroup));
	List.Parameters.SetParameterValue("qFolioIsSelected", ValueIsFilled(Folio));
	List.Parameters.SetParameterValue("qServiceIsSelected", ValueIsFilled(Service));
	
	// Apply filter by period selected
	SelPeriodOnChange();
	
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If tcOnClient.IsHomePageWindow(ThisForm) Then
		vPrefix = NStr("en = 'Accounting journal: '; de = 'Buchhaltungsjournal: '; ru = 'Журнал взаиморасчетов: '");
		tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisForm, vPrefix);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Subsystem.Accounts.Changed" Then
		Items.List.Refresh();
		RecalculateBalancesAtServer();
	ElsIf pEventName = "System.Hotel.Changed" And pParameter <> Hotel Then
		If ValueIsFilled(pParameter) Then
			Hotel = pParameter;
			List.Parameters.SetParameterValue("qHotel", Hotel);
			If tcOnClient.IsHomePageWindow(ThisForm) Then
				vPrefix = NStr("en = 'Accounting journal: '; de = 'Buchhaltungsjournal: '; ru = 'Журнал взаиморасчетов: '");
				tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisForm, vPrefix);
			EndIf;	
		EndIf;	
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerFilterOnChange(pItem)
	If ValueIsFilled(Customer) Then
		AttributeChangeAtServer("Customer", Customer);
	Else
		ClearingAttributeAtServer("Customer");
	EndIf;
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupFilterOnChange(pItem)
	List.Parameters.SetParameterValue("qGuestGroupIsSelected", ValueIsFilled(GuestGroup));
	If ValueIsFilled(GuestGroup) Then
		AttributeChangeAtServer("GuestGroup", GuestGroup);
	Else
		ClearingAttributeAtServer("GuestGroup");
	EndIf;
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ContractFilterOnChange(pItem)
	If ValueIsFilled(Contract) Then
		AttributeChangeAtServer("Contract", Contract);
	Else
		ClearingAttributeAtServer("Contract");
	EndIf;
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseOfPeriodFilterOnChange(pItem)
	If ValueIsFilled(CloseOfPeriod) Then
		AttributeChangeAtServer("CloseOfPeriod", CloseOfPeriod);
	Else
		ClearingAttributeAtServer("CloseOfPeriod");
	EndIf;
EndProcedure // CloseOfPeriodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FolioFilterOnChange(pItem)
	List.Parameters.SetParameterValue("qFolioIsSelected", ValueIsFilled(Folio));
	If ValueIsFilled(Folio) Then
		AttributeChangeAtServer("Folio", Folio);
	Else
		ClearingAttributeAtServer("Folio");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceFilterOnChange(pItem)
	List.Parameters.SetParameterValue("qServiceIsSelected", ValueIsFilled(Service));
	If ValueIsFilled(Service) Then
		AttributeChangeAtServer("Service", Service);
	Else
		ClearingAttributeAtServer("Service");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ContractFilterClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("Contract");
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerFilterClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("Customer");
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupFilterClearing(pItem, pStandardProcessing)
	List.Parameters.SetParameterValue("qGuestGroupIsSelected", ValueIsFilled(GuestGroup));
	ClearingAttributeAtServer("GuestGroup");	
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseOfPeriodFilterClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("CloseOfPeriod");	
EndProcedure // CloseOfPeriodClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceFilterClearing(pItem, pStandardProcessing)
	List.Parameters.SetParameterValue("qServiceIsSelected", ValueIsFilled(Service));
	ClearingAttributeAtServer("Service");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FolioFilterClearing(pItem, pStandardProcessing)
	List.Parameters.SetParameterValue("qFolioIsSelected", ValueIsFilled(Folio));
	ClearingAttributeAtServer("Folio");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateFromOnChange(pItem)
	SelPeriodOnChange();
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure // SelDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateToOnChange(pItem)
	SelPeriodOnChange();
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure // SelDateToOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If Not Items.List.ChoiceMode Then
		If pField.Name = "ListGuestGroup" Then
			pStandardProcessing = False;
			vRowData = Items.List.RowData(pSelectedRow);
			If ValueIsFilled(vRowData.GuestGroup) Then
				OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", vRowData.GuestGroup));
			EndIf;
		Else
			vCurRow = Items.List.CurrentData;
			If vCurRow <> Undefined And ValueIsFilled(vCurRow.Ref) Then
				ShowValue(, vCurRow.Ref); 
			EndIf;	
		EndIf;
	Else
		vRowData = Items.List.RowData(pSelectedRow);
		NotifyChoice(vRowData.Ref);
	EndIf;
EndProcedure // ListSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure ListOnActivateRow(pItem)
	vCurRow = Items.List.CurrentData;
	If vCurRow <> Undefined And ValueIsFilled(vCurRow.Ref) Then
		If CheckDocumentToEdit(vCurRow.Ref) Then
			Items.ListPostDocument.Enabled = True;	
			Items.ListUndoPostDocument.Enabled = True;
			Items.ListSetDeletionMark.Enabled = True;
			Items.ListContextMenuPostDocument.Enabled = True;	
			Items.ListContextMenuUndoPostDocument.Enabled = True;
			Items.ListContextMenuSetDeletionMark.Enabled = True;
		Else	
			Items.ListPostDocument.Enabled = False;	
			Items.ListUndoPostDocument.Enabled = False;
			Items.ListSetDeletionMark.Enabled = False;
			Items.ListContextMenuPostDocument.Enabled = False;	
			Items.ListContextMenuUndoPostDocument.Enabled = False;
			Items.ListContextMenuSetDeletionMark.Enabled = False;
		EndIf;	
	EndIf;	
	AttachIdleHandler("ChangeCommandTitles", 0.5, True);
EndProcedure // ListOnActivateRow

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterCustomerAdvanceDistribution(pCommand)
	AttributeChangeAtServer("Type", Type("DocumentRef.CustomerAdvanceDistribution"));	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterCustomerPayment(pCommand)
	AttributeChangeAtServer("Type", Type("DocumentRef.CustomerPayment"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterPayment(pCommand)
	AttributeChangeAtServer("Type", Type("DocumentRef.Payment"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterProformaInvoice(pCommand)
	AttributeChangeAtServer("Type", Type("DocumentRef.ProformaInvoice"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterReturn(pCommand)
	AttributeChangeAtServer("Type", Type("DocumentRef.Return"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterSettlement(pCommand)
	AttributeChangeAtServer("Type", Type("DocumentRef.Settlement"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterCreditNote(pCommand)
	AttributeChangeAtServer("Type", Type("DocumentRef.CreditNote"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterDebitNotes(pCommand)
	AttributeChangeAtServer("Type", Type("DocumentRef.DebitNote"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterAll(pCommand)
	ClearingAttributeAtServer("Type");		
	ClearingAttributeAtServer("AccountingSum");		
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterAllExceptProformaInvoices(pCommand)
	AttributeChangeAtServer("AccountingSum", 0, DataCompositionComparisonType.NotEqual);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeDocumentOnClient(pCommand)
	If Items.List.SelectedRows.Count() > 0 Then
		For Each vCurRowID In Items.List.SelectedRows Do
			If vCurRowID <> Undefined Then
				vCurRow = Items.List.RowData(vCurRowID);
				If vCurRow <> Undefined And ValueIsFilled(vCurRow.Ref) Then
					vRef = vCurRow.Ref;
					If CheckDocumentToEdit(vRef) Then
						ChangeDocument(vRef, pCommand.Name);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		Items.List.Refresh();
	EndIf;
EndProcedure // ChangeDocumentOnClient

// -----------------------------------------------------------------------------
&AtClient
Procedure DepositPayment(pCommand)
	If ValueIsFilled(Contract) Then
		OpenForm("Document.CustomerPayment.ObjectForm", New Structure("AccountingContract, GuestGroup", Contract, GuestGroup), Contract);
	ElsIf ValueIsFilled(Customer) Then
		OpenForm("Document.CustomerPayment.ObjectForm", New Structure("AccountingCustomer, GuestGroup", Customer, GuestGroup), Customer);
	Else
		ClearMessages();
		vMsg = New UserMessage;
		vMsg.Text = NStr("en = 'Please select a customer'; de = 'Bitte wählen Sie einen Firma'; ru = 'Укажите контрагента'");
		vMsg.Field = "Customer";
		vMsg.Message();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DepositClearing(pCommand)
	If ValueIsFilled(Contract) Then
		OpenForm("Document.CustomerAdvanceDistribution.ObjectForm", New Structure("AccountingContract", Contract), Contract);
	ElsIf ValueIsFilled(Customer) Then
		OpenForm("Document.CustomerAdvanceDistribution.ObjectForm", New Structure("AccountingCustomer", Customer), Customer);
	Else
		ClearMessages();
		vMsg = New UserMessage;
		vMsg.Text = NStr("en = 'Please select a customer'; de = 'Bitte wählen Sie einen Firma'; ru = 'Укажите контрагента'");
		vMsg.Field = "Customer";
		vMsg.Message();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DepositClearingByInvoices(pCommand)
	If Not ValueIsFilled(Contract) And Not ValueIsFilled(Customer) Then
		ClearMessages();
		vMsg = New UserMessage;
		vMsg.Text = NStr("en = 'Please select a customer!'; de = 'Bitte wählen Sie einen Firma!'; ru = 'Укажите контрагента!'");
		vMsg.Field = "Customer";
		vMsg.Message();
		Return;
	EndIf;
	vInvoicesList = New ValueList();
	For Each vRow In Items.List.SelectedRows Do
		vRowData = Items.List.RowData(vRow);
		If vRowData.Type = Type("DocumentRef.Settlement") Then
			If vInvoicesList.FindByValue(vRowData.Ref) = Undefined Then
				vInvoicesList.Add(vRowData.Ref);
			EndIf;
		EndIf;
	EndDo;
	If vInvoicesList.Count() > 0 Then
		If ValueIsFilled(Contract) Then
			OpenForm("Document.CustomerAdvanceDistribution.ObjectForm", New Structure("AccountingContract, Invoices", Contract), Contract, vInvoicesList);
		ElsIf ValueIsFilled(Customer) Then
			OpenForm("Document.CustomerAdvanceDistribution.ObjectForm", New Structure("AccountingCustomer, Invoices", Customer, vInvoicesList), Customer);
		EndIf;
	Else
		ClearMessages();
		vMsg = New UserMessage;
		vMsg.Text = NStr("en = 'Please select one or more invoices!'; de = 'Bitte wählen Sie eine oder mehrere Rechnungen aus!'; ru = 'Пожалуйста выберите один или несколько актов!'");
		vMsg.Field = "List";
		vMsg.Message();
	EndIf;
EndProcedure // DepositClearingByInvoices

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditNote(pCommand)
	If ValueIsFilled(GuestGroup) Then
		OpenForm("Document.CreditNote.ObjectForm", New Structure("Basis", GuestGroup), ThisForm, GuestGroup); 
	ElsIf ValueIsFilled(Contract) Then
		OpenForm("Document.CreditNote.ObjectForm", New Structure("Basis", Contract), ThisForm, Contract); 
	ElsIf ValueIsFilled(Customer) Then
		OpenForm("Document.CreditNote.ObjectForm", New Structure("Basis", Customer), ThisForm, Customer); 
	Else
		OpenForm("Document.CreditNote.ObjectForm", , ThisForm); 
	EndIf;
EndProcedure // CreditNote

// -----------------------------------------------------------------------------
&AtClient
Procedure DebitNote(pCommand)
	If ValueIsFilled(GuestGroup) Then
		OpenForm("Document.DebitNote.ObjectForm", New Structure("Basis", GuestGroup), ThisForm, GuestGroup); 
	ElsIf ValueIsFilled(Contract) Then
		OpenForm("Document.DebitNote.ObjectForm", New Structure("Basis", Contract), ThisForm, Contract); 
	ElsIf ValueIsFilled(Customer) Then
		OpenForm("Document.DebitNote.ObjectForm", New Structure("Basis", Customer), ThisForm, Customer); 
	Else
		OpenForm("Document.DebitNote.ObjectForm", , ThisForm); 
	EndIf;
EndProcedure // DebitNote

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = SelDateFrom;
	vChoosePeriodDialog.Period.EndDate = SelDateTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	vFilter = ThisForm.List.Filter;
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
EndProcedure // ClearingAttributeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeCommandTitles()
	vTitle = NStr("en='Payment by selected document'; ru='Платеж по выбранному документу'; de='Zahlung per ausgewähltem Dokument'");
	vCurData = Items.List.CurrentData;
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.Ref) And TypeOf(vCurData.Ref) = Type("DocumentRef.CustomerPayment") Then
			vTitle = NStr("en='Refund by selected document'; ru='Возврат по выбранному документу'; de='Rückerstattung per ausgewähltem Dokument'");
		EndIf;
	EndIf;
	If Items.Find("ListDocumentCustomerPaymentCreateBasedOn") <> Undefined Then
		If Items.ListDocumentCustomerPaymentCreateBasedOn.Title <> vTitle Then
			Items.ListDocumentCustomerPaymentCreateBasedOn.Title = vTitle;
		EndIf;
	EndIf;
EndProcedure // ListOnActivateRow

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure ChangeDocument(pRef, pCMDName = "")
	If pCMDName = "PostDocument" Then
		vObj = pRef.GetObject();
		vObj.Write(DocumentWriteMode.Posting);
	ElsIf pCMDName = "UndoPostDocument" Then
		vObj = pRef.GetObject();
		vObj.Write(DocumentWriteMode.UndoPosting);
	ElsIf pCMDName = "SetDeletionMark" Then
		vObj = pRef.GetObject();
		vObj.SetDeletionMark(Not pRef.DeletionMark);	
	EndIf;	 
EndProcedure // ChangeDocument

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckDocumentToEdit(pRef)
	If (TypeOf(pRef) = Type("DocumentRef.Payment") Or 
		TypeOf(pRef) = Type("DocumentRef.Return") Or 
	    TypeOf(pRef) = Type("DocumentRef.DepositTransfer") Or 
	    TypeOf(pRef) = Type("DocumentRef.CustomerAdvanceDistribution") Or 
	    TypeOf(pRef) = Type("DocumentRef.CustomerPayment")) Then
		If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
			Return False;
		EndIf;
		vHotel = pRef.Hotel;
		If ValueIsFilled(vHotel) And vHotel.DoNotEditClosedDateDocs Then
			If cmIfChargeIsInClosedDay(pRef) Then
				Return False;
			Endif;
		EndIf;	
	EndIf;	
	Return True;
EndFunction	//CheckDocumentToEdit

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	vComparisonType = ?(pComparisonType=Undefined,DataCompositionComparisonType.Equal,pComparisonType);
	vValue = pValue;	
	If vValue <> Undefined Then
		vFilter = ThisForm.List.Filter;
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
EndProcedure // AttributeChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRoleName)
	Return IsInRole(pRoleName);
EndFunction // IsInRoleAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelFilterOnChange(pItem)
	List.Parameters.SetParameterValue("qHotel", Hotel);
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure // HotelFilterOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyFilterOnChange(pItem)
	List.Parameters.SetParameterValue("qCompany", Company);
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure // CompanyFilterOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelFilterClearing(pItem, pStandardProcessing)
	If Not IsInRoleAtServer("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure // HotelFilterClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		SelDateFrom = pPeriod.StartDate;
		SelDateTo = pPeriod.EndDate;
		SelPeriodOnChange();
	EndIf;
	// Recalculate balances and turnovers
	RecalculateBalancesAtServer();
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
Procedure SelPeriodOnChange()
	List.Parameters.SetParameterValue("qPeriodIsFilled", ValueIsFilled(SelDateFrom) Or ValueIsFilled(SelDateTo));
	If ValueIsFilled(SelDateFrom) Then
		List.Parameters.SetParameterValue("qPeriodFrom", BegOfDay(SelDateFrom));
	EndIf;
	If ValueIsFilled(SelDateTo) Then
		List.Parameters.SetParameterValue("qPeriodTo", EndOfDay(SelDateTo));
	Else
		List.Parameters.SetParameterValue("qPeriodTo", EndOfDay('39991231'));
	EndIf;
	If Not ValueIsFilled(SelDateFrom) And Not ValueIsFilled(SelDateTo) Then
		List.Parameters.SetParameterValue("qPeriodFrom", '00010101');
		List.Parameters.SetParameterValue("qPeriodTo", '00010101');
	EndIf;
EndProcedure // SelPeriodOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateBalancesAtServer()
	// Reset current values
	OpeningBalanceAmountStr = "";
	ClosingBalanceAmountStr = "";
	InvoicedAmountStr = "";
	PayedAmountStr = "";
	// Captions
	Items.OpeningBalanceAmountStr.Title = NStr("en='Opening balance'; ru='Баланс на начало периода'; de='Eröffnungsbilanz'");
	Items.ClosingBalanceAmountStr.Title = NStr("en='Closing balance'; ru='Баланс на конец периода'; de='Schlussbilanz'");
	// Check filters
	If ValueIsFilled(Hotel) And ValueIsFilled(Customer) Then
		If ValueIsFilled(SelDateFrom) And ValueIsFilled(SelDateTo) And SelDateTo < SelDateFrom Then
			Return;
		EndIf;
		// Run qery to get balance
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CustomerAccountsBalanceAndTurnovers.AccountingCurrency AS AccountingCurrency,
		|	CustomerAccountsBalanceAndTurnovers.SumOpeningBalance AS OpeningBalanceAmount,
		|	CustomerAccountsBalanceAndTurnovers.SumReceipt AS InvoicedAmount,
		|	CustomerAccountsBalanceAndTurnovers.SumExpense AS PayedAmount,
		|	CustomerAccountsBalanceAndTurnovers.SumClosingBalance AS ClosingBalanceAmount
		|FROM
		|	AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
		|			&qPeriodFrom,
		|			&qPeriodTo,
		|			Period,
		|			RegisterRecordsAndPeriodBoundaries,
		|			AccountingCustomer = &qAccountingCustomer
		|				AND (AccountingContract = &qAccountingContract
		|					OR &qAccountingContract = VALUE(Catalog.Contracts.EmptyRef))
		|				AND (Company = &qCompany
		|					OR &qCompany = VALUE(Catalog.Companies.EmptyRef))
		|				AND (GuestGroup = &qGuestGroup
		|					OR &qGuestGroup = VALUE(Catalog.GuestGroups.EmptyRef))
		|				AND Hotel = &qHotel) AS CustomerAccountsBalanceAndTurnovers
		|
		|ORDER BY
		|	CustomerAccountsBalanceAndTurnovers.AccountingCurrency.SortCode,
		|	CustomerAccountsBalanceAndTurnovers.AccountingCurrency.Description";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qPeriodFrom", BegOfDay(SelDateFrom));
		vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(SelDateTo), EndOfDay(SelDateTo), SelDateTo));
		vQry.SetParameter("qAccountingCustomer", Customer);
		vQry.SetParameter("qAccountingContract", Contract);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qGuestGroup", GuestGroup);
		vBalances = vQry.Execute().Unload();
		For Each vBalancesRow In vBalances Do
			If ValueIsFilled(vBalancesRow.AccountingCurrency) Then
				OpeningBalanceAmountStr = ?(IsBlankString(OpeningBalanceAmountStr), "", ", ") + cmFormatSum(?(vBalancesRow.OpeningBalanceAmount = Null, 0, vBalancesRow.OpeningBalanceAmount), vBalancesRow.AccountingCurrency);
				ClosingBalanceAmountStr = ?(IsBlankString(ClosingBalanceAmountStr), "", ", ") + cmFormatSum(?(vBalancesRow.ClosingBalanceAmount = Null, 0, vBalancesRow.ClosingBalanceAmount), vBalancesRow.AccountingCurrency);
				InvoicedAmountStr = ?(IsBlankString(InvoicedAmountStr), "", ", ") + cmFormatSum(?(vBalancesRow.InvoicedAmount = Null, 0, vBalancesRow.InvoicedAmount), vBalancesRow.AccountingCurrency);
				PayedAmountStr = ?(IsBlankString(PayedAmountStr), "", ", ") + cmFormatSum(?(vBalancesRow.PayedAmount = Null, 0, vBalancesRow.PayedAmount), vBalancesRow.AccountingCurrency);

				If ValueIsFilled(SelDateFrom) Then
					Items.OpeningBalanceAmountStr.Title = NStr("en='Opening balance for '; ru='Баланс на начало '; de='Eröffnungsbilanz für '") + Format(SelDateFrom, "DF=dd.MM.yyyy");
				EndIf;
				If ValueIsFilled(SelDateTo) Then
					Items.ClosingBalanceAmountStr.Title = NStr("en='Closing balance for '; ru='Баланс на конец '; de='Schlussbilanz für '") + Format(SelDateTo, "DF=dd.MM.yyyy");
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // RecalculateBalancesAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateBalances(pCommand)
	RecalculateBalancesAtServer();
EndProcedure // RecalculateBalances

#EndRegion




