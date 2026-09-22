
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Hotel = SessionParameters.CurrentHotel;
	DateFrom = BegOfDay(CurrentSessionDate());
	DateTo = BegOfDay(CurrentSessionDate());
	Action = True;
	ProcessInvoices = True;
	ProcessCreditNotes = True;
	ProcessDebitNotes = True;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = DateFrom;
	vChoosePeriodDialog.Period.EndDate = DateTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure DoProcessing(pCommand)
	If DoProcessingAtServer() Then
		Notify("Subsystem.Accounts.Changed", , ThisForm);
		ShowMessageBox(, NStr("en='Completed!'; de='Vollendet'; ru='Выполнено!'"));
	EndIf;
EndProcedure // DoProcessing

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		DateFrom = pPeriod.StartDate;
		DateTo = pPeriod.EndDate;
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure HotelClearingAtServer(pStandardProcessing)
	If Not IsInRole("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // HotelClearingAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	HotelClearingAtServer(pStandardProcessing);
EndProcedure // HotelClearing

// -----------------------------------------------------------------------------
&AtServer
Function DoProcessingAtServer()
	vMessage = "";
	// Check period
	If Not ValueIsFilled(DateTo) Then
		vMessage = NStr("en='Period end date must be specified!'; ru='Дата окончания периода должна быть указана!'; de='Das Enddatum der Periode muss angegeben werden!'");
		vUM = New UserMessage();
		vUM.Field = "DateTo";
		vUM.Text = vMessage;
		vUM.Message();
	EndIf;
	If DateTo < DateFrom Then
		vMessage = NStr("en='Period is wrong!'; ru='Период указан неправильно!'; de='Periode ist falsch!'");
		vUM = New UserMessage();
		vUM.Field = "DateTo";
		vUM.Text = vMessage;
		vUM.Message();
	EndIf;
	// Check document types
	If Not ProcessInvoices And Not ProcessCreditNotes And Not ProcessDebitNotes Then
		vMessage = NStr("en='Choose at least one document type to process!'; ru='Выберите хотя бы один тип документа для обработки!'; de='Wählen Sie mindestens einen zu verarbeitenden Dokumenttyp!'");
		vUM = New UserMessage();
		vUM.Field = "DateTo";
		vUM.Text = vMessage;
		vUM.Message();
	EndIf;
	If Not IsBlankString(vMessage) Then
		Return False;
	EndIf;
	
	// Process documents
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Invoices.Ref AS Ref,
	|	Invoices.PointInTime AS PointInTime
	|FROM
	|	Document.Settlement AS Invoices
	|WHERE
	|	&qProcessInvoices
	|	AND Invoices.Date >= &qPeriodFrom
	|	AND Invoices.Date <= &qPeriodTo
	|	AND (Invoices.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (Invoices.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND (Invoices.AccountingCustomer = &qCustomer
	|			OR &qCustomerIsEmpty)
	|	AND Invoices.IsChecked <> &qIsChecked
	|	AND Invoices.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	CreditNotes.Ref,
	|	CreditNotes.PointInTime
	|FROM
	|	Document.CreditNote AS CreditNotes
	|WHERE
	|	&qProcessCreditNotes
	|	AND CreditNotes.Date >= &qPeriodFrom
	|	AND CreditNotes.Date <= &qPeriodTo
	|	AND (CreditNotes.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (CreditNotes.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND (CreditNotes.AccountingCustomer = &qCustomer
	|			OR &qCustomerIsEmpty)
	|	AND CreditNotes.IsChecked <> &qIsChecked
	|	AND CreditNotes.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	DebitNotes.Ref,
	|	DebitNotes.PointInTime
	|FROM
	|	Document.DebitNote AS DebitNotes
	|WHERE
	|	&qProcessDebitNotes
	|	AND DebitNotes.Date >= &qPeriodFrom
	|	AND DebitNotes.Date <= &qPeriodTo
	|	AND (DebitNotes.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (DebitNotes.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND (DebitNotes.AccountingCustomer = &qCustomer
	|			OR &qCustomerIsEmpty)
	|	AND DebitNotes.IsChecked <> &qIsChecked
	|	AND DebitNotes.Posted
	|
	|ORDER BY
	|	PointInTime";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qCustomer", Customer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	vQry.SetParameter("qPeriodFrom", BegOfDay(DateFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(DateTo));
	vQry.SetParameter("qIsChecked", Action);
	vQry.SetParameter("qProcessInvoices", ProcessInvoices);
	vQry.SetParameter("qProcessCreditNotes", ProcessCreditNotes);
	vQry.SetParameter("qProcessDebitNotes", ProcessDebitNotes);
	vDocs = vQry.Execute().Unload();
	
	BeginTransaction(DataLockControlMode.Managed);
	For Each vDocsRow In vDocs Do
		vDocObj = vDocsRow.Ref.GetObject();
		vDocObj.IsChecked = Action;
		If Not ValueIsFilled(vDocObj.ChangeDate) And ValueIsFilled(vDocObj.Date) Then
			vDocObj.ChangeDate = vDocObj.Date;
		Else
			vDocObj.ChangeDate = CurrentSessionDate();
		EndIf;
		vDocObj.ChangeAuthor = SessionParameters.CurrentUser;
		vDocObj.Write(DocumentWriteMode.Write);
	EndDo;
	CommitTransaction();
	
	Return True;
EndFunction // DoProcessingAtServer

#EndRegion
