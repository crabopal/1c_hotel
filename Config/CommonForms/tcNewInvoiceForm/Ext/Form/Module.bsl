
#Region FormEventHandlers

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("ParentDoc") Then
		ParentDoc = Parameters.ParentDoc;	
	EndIf;	
	If Parameters.Property("GuestGroup") Then
		GuestGroup = Parameters.GuestGroup;	
	EndIf;
	If ValueIsFilled(ParentDoc) And Not ValueIsFilled(ParentDoc.GuestGroup) Or Not ValueIsFilled(ParentDoc) And ValueIsFilled(GuestGroup) Then 
		Items.Filter.Enabled = False;	
	EndIf;  
	
	If ValueIsFilled(ParentDoc) And ValueIsFilled(ParentDoc.GuestGroup) Then 
		GuestGroup = ParentDoc.GuestGroup;	
	EndIf;
	
	NewInvoiceSum = 0;
	NewInvoiceSumPresentation = "0.00";
	
	FillFilter();     
	
	FillInvoiceList();
	
	FillNewButtonInvoice();
	
	FillHeaderDescription();
EndProcedure

#EndRegion   

#Region FormHeaderItemsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure FilterOnChange(pItem)
	FillInvoiceList(); 
	FillNewButtonInvoice();
	FillHeaderDescription();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure InvoicesOnActivateField(pItem)     
    vCurRow = Items.Invoices.CurrentData;
	If pItem.CurrentItem.Name = "Refill" And pItem.CurrentRow <> Undefined Then  
		vBasis = Undefined;
		If Filter = 0 Then // By document
			vBasis = ParentDoc;
		ElsIf Filter = 1 Then // By guest group	
			vBasis =  GuestGroup;  
		Else
			// Do not nothing
		EndIf;
		If vCurRow <> Undefined And Not IsBlankString(vCurRow.Refill) Then  
			OpenForm("Document.ProformaInvoice.ObjectForm", New Structure("Basis, Key, Refill", vBasis, vCurRow.Invoice, True), , ThisObject.UUID); 
			Close();
		EndIf;
	ElsIf pItem.CurrentItem.Name = "InvoicesInvoice" Then
		If vCurRow <> Undefined And	ValueIsFilled(vCurRow.Invoice) Then
			ShowValue(, vCurRow.Invoice);
			Close();
		EndIf;	
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure CreateNewInvoice(pCommand)    
	vBasis = Undefined;
	If Filter = 0 Then // By document
		vBasis = ParentDoc;
	ElsIf Filter = 1 Then // By guest group	
		vBasis =  GuestGroup;  
	Else
		// Do nothing
	EndIf;
	
	If ValueIsFilled(vBasis) Then
		OpenForm("Document.ProformaInvoice.ObjectForm", New Structure("Basis", vBasis), , ThisObject.UUID); 
		Close();
	Else
		ShowMessageBox(, NStr("en = 'The basis for creating an invoice is not defined'; 
							  |de = 'Die Grundlage für die Erstellung einer Rechnung ist nicht definiert'; 
							  |ru = 'Не определено основание для создание счета'"));
	EndIf;	
EndProcedure 

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure CreateNewAdditionalInvoice(pCommand)
	vBasis = Undefined;
	If Filter = 0 Then // By document
		vBasis = ParentDoc;
	ElsIf Filter = 1 Then // By guest group	
		vBasis =  GuestGroup;  
	Else
		// Do not nothing
	EndIf;
	vRow = Items.Invoices.CurrentData;
	If ValueIsFilled(vBasis) And vRow <> Undefined Then
		OpenForm("Document.ProformaInvoice.ObjectForm", New Structure("Basis, ExtraService", vBasis, vRow.Invoice), , ThisObject.UUID); 
		Close();
	Else
		ShowMessageBox(, NStr("en = 'The basis for creating an invoice is not defined'; 
							  |de = 'Die Grundlage für die Erstellung einer Rechnung ist nicht definiert'; 
							  |ru = 'Не определено основание для создание счета'"));
	EndIf;	
EndProcedure

#EndRegion   

#Region Private

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillHeaderDescription()  
	vTitleTemplateByDoc = NStr("en = 'Create proforma invoice by document: %1'; de = 'Rechnung nach Beleg erstellen: %1'; ru = 'Создание счета по документу: %1'");
	vTitleTemplateByGuestGroup = NStr("en = 'Create proforma invoice by guest group: %1'; de = 'Erstellen einer Rechnung für eine Gruppe von Gästen: %1'; ru = 'Создание счета по группе гостей: %1'");
	
	If Filter = 0 Then // By document
		Title = StrTemplate(vTitleTemplateByDoc, ParentDoc);
	ElsIf Filter = 1 Then // By guest group	
		Title = StrTemplate(vTitleTemplateByGuestGroup, GuestGroup);  
	Else
		// Do not nothing
		Title = "";
	EndIf;
EndProcedure // FillHeaderDescription()

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillInvoiceList()    
	If Filter = 0 Then // By document
   		FillByDocument();
	ElsIf Filter = 1 Then // By guest group	
	    FillByGuestGroup();  
	Else
		// Do not nothing
		Invoices.Clear();
	EndIf;	
EndProcedure // FillInvoiceList()

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillNewButtonInvoice() 
	vFullAmountTitleTemplate = NStr("en = 'Create a new proforma invoice for payment in the amount of: %1'; 
									|de = 'Erstellen Sie eine neue Rechnung zur Zahlung in Höhe von %1'; 
									|ru = 'Создать новый счет на оплату на сумму %1'");
	Items.CreteNewLablel.Title = StrTemplate(vFullAmountTitleTemplate, NewInvoiceSumPresentation);
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillFilter()
	If ValueIsFilled(ParentDoc) Then
		Filter = 0; 
	ElsIf Not ValueIsFilled(ParentDoc) And ValueIsFilled(GuestGroup) Then
		Filter = 1;  
	Else
		Filter = 2;
	EndIf;   
EndProcedure // FillFilter()

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillByDocument()  
	Invoices.Clear();
	NewInvoiceSum = 0;
	NewInvoiceSumPresentation = "0.00";
	
	If ValueIsFilled(ParentDoc) Then
		CalculateNewInvoiceByParentDoc();
		
		vQuery = New Query();
		vQuery.Text =
		"SELECT
		|	ProformaInvoice.Ref AS Invoice,
		|	ProformaInvoice.Date AS Date,
		|	ProformaInvoice.Sum AS Sum,
		|	ProformaInvoice.AccountingCurrency AS AccountingCurrency,
		|	ProformaInvoice.Number AS Number,
		|	CASE
		|		WHEN ProformaInvoice.Posted
		|			THEN CASE
		|					WHEN ProformaInvoice.CheckDate <> DATETIME(1, 1, 1, 0, 0, 0)
		|							AND BEGINOFPERIOD(ProformaInvoice.CheckDate, DAY) < BEGINOFPERIOD(&qCurrentDate, DAY)
		|							AND ISNULL(ProformaInvoice.Sum, 0) = ISNULL(InvoiceAccountsBalance.SumBalance, 0)
		|						THEN 12
		|					ELSE CASE
		|							WHEN ISNULL(ProformaInvoice.Sum, 0) - ISNULL(InvoiceAccountsBalance.SumBalance, 0) >= ProformaInvoice.Sum
		|								THEN 10
		|							ELSE CASE
		|									WHEN ISNULL(ProformaInvoice.Sum, 0) - ISNULL(InvoiceAccountsBalance.SumBalance, 0) > 0
		|										THEN 11
		|									ELSE 9
		|								END
		|						END
		|				END
		|		ELSE 0
		|	END AS Icon
		|FROM
		|	Document.ProformaInvoice AS ProformaInvoice
		|		LEFT JOIN AccumulationRegister.InvoiceAccounts.Balance(, ) AS InvoiceAccountsBalance
		|		ON ProformaInvoice.Ref = InvoiceAccountsBalance.Invoice
		|WHERE
		|	CASE
		|			WHEN &qParentDocIsFilled
		|				THEN ProformaInvoice.ParentDoc = &qDocument
		|						OR ProformaInvoice.ParentDoc = &qParentDoc
		|			ELSE ProformaInvoice.ParentDoc = &qDocument
		|		END
		|	AND ProformaInvoice.DeletionMark = FALSE
		|	AND ProformaInvoice.Posted";
		
		vQuery.SetParameter("qDocument", ParentDoc);  
		vQuery.SetParameter("qParentDoc", ParentDoc.ParentDoc);  
		vQuery.SetParameter("qParentDocIsFilled", ValueIsFilled(ParentDoc.ParentDoc)); 
		vQuery.SetParameter("qCurrentDate", CurrentSessionDate());
		vResult = vQuery.Execute().Select();
		
		While vResult.Next() Do  
			vNewRow = Invoices.Add();
			FillPropertyValues(vNewRow, vResult);
			vNewRow.Sum = cmFormatSum(vNewRow.Sum, vResult.AccountingCurrency); 
			If vResult.Sum <> NewInvoiceSum Then 
				vNewRow.Refill = NStr("en = 'Refill'; de = 'Nachfüllung'; ru = 'Перезаполнить'");
			Else
				vNewRow.Refill = "";
			EndIf;	
		EndDo; 
	EndIf;
	FillNewButtonInvoice();
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure CalculateNewInvoiceByParentDoc()
	vProformaInvoice = Documents.ProformaInvoice.CreateDocument();
	vProformaInvoice.Fill(ParentDoc);
	NewInvoiceSum = vProformaInvoice.Sum;
	NewInvoiceSumPresentation = cmFormatSum(vProformaInvoice.Sum, vProformaInvoice.AccountingCurrency);
EndProcedure // FillByDocument() 

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure CalculateNewInvoiceByGuestGroup()
	vProformaInvoice = Documents.ProformaInvoice.CreateDocument();
	vProformaInvoice.Fill(GuestGroup);
	NewInvoiceSum = vProformaInvoice.Sum;
	NewInvoiceSumPresentation = cmFormatSum(vProformaInvoice.Sum, vProformaInvoice.AccountingCurrency);
EndProcedure // FillByDocument()

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillByGuestGroup()
	Invoices.Clear();
	NewInvoiceSum = 0;
	NewInvoiceSumPresentation = "0.00";
	
	If ValueIsFilled(GuestGroup) Then
		CalculateNewInvoiceByGuestGroup();
		
		vQuery = New Query();
		vQuery.Text =
		"SELECT
		|	ProformaInvoice.Ref AS Invoice,
		|	ProformaInvoice.Date AS Date,
		|	ProformaInvoice.Sum AS Sum,
		|	ProformaInvoice.AccountingCurrency AS AccountingCurrency,
		|	ProformaInvoice.Number AS Number,
		|	CASE
		|		WHEN ProformaInvoice.Posted
		|			THEN CASE
		|					WHEN ProformaInvoice.CheckDate <> DATETIME(1, 1, 1, 0, 0, 0)
		|							AND BEGINOFPERIOD(ProformaInvoice.CheckDate, DAY) < BEGINOFPERIOD(&qCurrentDate, DAY)
		|							AND ISNULL(ProformaInvoice.Sum, 0) = ISNULL(InvoiceAccountsBalance.SumBalance, 0)
		|						THEN 12
		|					ELSE CASE
		|							WHEN ISNULL(ProformaInvoice.Sum, 0) - ISNULL(InvoiceAccountsBalance.SumBalance, 0) >= ProformaInvoice.Sum
		|								THEN 10
		|							ELSE CASE
		|									WHEN ISNULL(ProformaInvoice.Sum, 0) - ISNULL(InvoiceAccountsBalance.SumBalance, 0) > 0
		|										THEN 11
		|									ELSE 9
		|								END
		|						END
		|				END
		|		ELSE 0
		|	END AS Icon
		|FROM
		|	Document.ProformaInvoice AS ProformaInvoice
		|		LEFT JOIN AccumulationRegister.InvoiceAccounts.Balance(, ) AS InvoiceAccountsBalance
		|		ON ProformaInvoice.Ref = InvoiceAccountsBalance.Invoice
		|WHERE
		|	ProformaInvoice.GuestGroup = &qGuestGroup
		|	AND ProformaInvoice.ParentDoc = UNDEFINED
		|	AND ProformaInvoice.DeletionMark = FALSE
		|	AND ProformaInvoice.Posted";
		
		vQuery.SetParameter("qGuestGroup", GuestGroup);
		vQuery.SetParameter("qCurrentDate", CurrentSessionDate());
		
		vResult = vQuery.Execute().Select();
		
		While vResult.Next() Do  
			vNewRow = Invoices.Add();
			FillPropertyValues(vNewRow, vResult);
			vNewRow.Sum = cmFormatSum(vNewRow.Sum, vResult.AccountingCurrency); 
			If vResult.Sum <> NewInvoiceSum Then 
				vNewRow.Refill = NStr("en = 'Refill'; de = 'Nachfüllung'; ru = 'Перезаполнить'");
			Else
				vNewRow.Refill = "";
			EndIf;	
		EndDo; 
	EndIf;
	FillNewButtonInvoice();
EndProcedure // FillByGuestGroup()

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure InvoicesOnActivateRow(pItem) 
	vCurRowInvoices = Items.Invoices.CurrentData;  
	vSumPres = "";
	vInvoice = Undefined;
	If vCurRowInvoices <> Undefined Then 
		vInvoice = vCurRowInvoices.Invoice; 
		vSumPres = GetSumAdditionalInvoice(vInvoice, NewInvoiceSum);
	EndIf;	  
	
	vAddAmountTitleTemplate = NStr("en = 'Create proforma invoice for surcharge in the amount of: %1'; 
								   |de = 'Rechnung über Zuschlag in Höhe von %1 erstellen'; 
								   |ru = 'Создать счет на доплату: %1'");  
	
	vEmptyTitle = NStr("en = 'To create an invoice for a surcharge, you need to select a line with an invoice-base from the table of accounts'; 
					   |de = 'Um eine Rechnung für einen Zuschlag zu erstellen, müssen Sie im Kontenverzeichnis eine Zeile mit Rechnungsbasis auswählen'; 
					   |ru = 'Для создания счета на доплату нужно выбрать строку с счетом-основанием из таблицы уже созданных счетов'");
	
	Items.GroupCreateAdd.Enabled = False;
	If ValueIsFilled(vInvoice) Then     
		If Not IsBlankString(vSumPres) Then           
			Items.CreteNewImvoiceAdd.Title = StrTemplate(vAddAmountTitleTemplate, vSumPres);
			Items.GroupCreateAdd.Enabled = True;   
		Else
			Items.CreteNewImvoiceAdd.Title = StrTemplate(vAddAmountTitleTemplate, "0.00");	
		EndIf;   
	Else
		Items.CreteNewImvoiceAdd.Title = vEmptyTitle;	
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetSumAdditionalInvoice(pInvoice, pNewInvoiceSum)
	vSumPres = "";
	
	If ValueIsFilled(pInvoice) And pNewInvoiceSum > 0 Then     
		vSum = pNewInvoiceSum - pInvoice.Sum;
		vSumPres = cmFormatSum(vSum, pInvoice.AccountingCurrency);	
	EndIf;
	
	Return vSumPres;
EndFunction // GetSumAdditionalInvoice()

#EndRegion
