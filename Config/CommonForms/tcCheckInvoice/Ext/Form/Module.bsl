#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ParentDoc = Parameters.Folio;
	ItemName = Parameters.ItemName;
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	ProformaInvoice.Ref AS Invoice,
	|	ProformaInvoice.Date AS Date,
	|	ProformaInvoice.Sum AS Sum
	|FROM
	|	Document.ProformaInvoice AS ProformaInvoice
	|WHERE
	|	ProformaInvoice.ParentDoc = &qParentDoc
	|	AND ProformaInvoice.DeletionMark = FALSE";
	
	vQuery.SetParameter("qParentDoc", ParentDoc);
	vResult = vQuery.Execute().Unload();

	Invoices.Load(vResult);
	For Each Row in Invoices Do
		Row.Sum = cmFormatSum(Row.Sum, Parameters.Currency);
		Row.Refill = NStr("en = 'Refill'; de = 'Nachfüllung'; ru = 'Перезаполнить'");
	EndDo;
	Items.ListLabel.Title = StrReplace(Items.ListLabel.Title, "%1", String(ParentDoc));
	Items.ListLabel.Title = StrReplace(Items.ListLabel.Title, "%2", String(Parameters.Number));
	Items.ListLabel.Title = StrReplace(Items.ListLabel.Title, "%3", cmFormatSum(Parameters.Sum, Parameters.Currency)); 
	Items.CreteNewLablel.Title = StrReplace(Items.CreteNewLablel.Title, "%1", cmFormatSum(Parameters.Sum, Parameters.Currency));	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure InvoicesOnActivateField(Item)
	If Item.CurrentItem.Name = "Refill" Then
		NotifyChoice(New Structure("Invoice, RefillInvoice, ItemName", Invoices[Item.CurrentRow].Invoice, True, ItemName));
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CreateNewInvoice(Command)
	NotifyChoice(New Structure("Invoice, RefillInvoice, ItemName", GetEmptyInvoiceRef(), True, ItemName));
EndProcedure 

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetEmptyInvoiceRef()
	Return Documents.ProformaInvoice.EmptyRef()
EndFunction;

#EndRegion



