
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vObj = FormAttributeToValue("Object"); 
	// Check user rights
	If vObj.IsNew() Then
		If Not cmCheckUserPermissions("HavePermissionToIssueHotelProducts") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to create document!';ru='Нет прав на создание документов отгрузки путевок!';de='Sie haben keine Rechte, Dokumente zu erstellen!'"));
			Return;
		EndIf;
		// Use current time by default
		vObj.SetTime(AutoTimeMode.CurrentOrLast);
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;
	EndIf;
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(vObj.Hotel) And SessionParameters.CurrentHotel <> vObj.Hotel Then
			pCancel = True;
			Return;
		EndIf;
	EndIf;	
	// Check edit prohibited date
	If ValueIsFilled(vObj.Hotel) Then
		If ValueIsFilled(vObj.Hotel.EditProhibitedDate) And 
		   	BegOfDay(vObj.Hotel.EditProhibitedDate) >= BegOfDay(vObj.Date) Then
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;
	// Save current currency and rate
	SavCurrency = vObj.Currency;
	SavCurrencyExchangeRate = vObj.CurrencyExchangeRate;
	// Set document number and date appearances
	If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
		Items.Number.ReadOnly = True;
		Items.Number.Enabled = False;
		Items.Date.ReadOnly = True;
		Items.Date.Enabled = False;
		Items.Date.ChoiceButton = False;
	EndIf;
	// Save current document date
	OldDate = vObj.Date;
	// Check user rights
	If Not cmCheckUserPermissions("HavePermissionToIssueHotelProducts") Then
		ThisForm.ReadOnly = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to edit voucher shipment documents! Document will be opened read only!';ru='Нет прав на редактирование документов отгрузки путевок! Документ будет открыт на просмотр!';de='Sie haben keine Rechte, Gutsheindokumente zu redigieren! Das Dokument wird zur Ansicht geöffnet!'"));
	EndIf;
	// Set object back to form attributes
	ValueToFormAttribute(vObj, "Object");
	// Set printing forms appearance
	SetPrintingFormsAppearance();
	// Set columns and form appearance
	SetDocumentAppearance();	
	// Fill footer in tabular section
	CalculateTotalFooterAtClientServer();
	// Parameters
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	Var vMessage; 
	Var vAttributeInErr;
	// Before posting actions
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// Check document attributes 		
		pCancel = pCurrentObject.pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = vAttributeInErr;
			vUM.Text = NStr(vMessage);
			vUM.Message();
		Else
			// Always undo posting first to repost document
			If Object.Posted Then
				pCurrentObject.Write(DocumentWriteMode.UndoPosting);
			EndIf;
		EndIf;
	EndIf; 
EndProcedure // BeforeWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductsProductStartCodeOnChange(pItem)
	vCurRow = Items.HotelProducts.CurrentData;
	If vCurRow <> Undefined Then
		vCurRow.ProductEndCode = AddToNumberWithPrefixAtServer(vCurRow.ProductStartCode, vCurRow.Quantity);
	EndIf;
EndProcedure // HotelProductsProductStartCodeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductsQuantityOnChange(pItem)
	vCurRow = Items.HotelProducts.CurrentData;
	If vCurRow <> Undefined Then
		vCurRow.ProductEndCode = AddToNumberWithPrefixAtServer(vCurRow.ProductStartCode, vCurRow.Quantity);
		vCurRow.Sum = Round(vCurRow.Price*vCurRow.Quantity, 2);
		vCurRow.VATSum = CalculateVATSumAtServer(Object.VATRate, vCurRow.Sum, Object.Date);
	EndIf;   
EndProcedure // HotelProductsQuantityOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductsProductEndCodeOnChange(pItem)
	vCurRow = Items.HotelProducts.CurrentData;
	If vCurRow <> Undefined Then
		vCurRow.Quantity = SubtractNumbersWithPrefixAtServer(vCurRow.ProductEndCode, vCurRow.ProductStartCode);
		vCurRow.Sum = Round(vCurRow.Price*vCurRow.Quantity, 2);
		vCurRow.VATSum = CalculateVATSumAtServer(Object.VATRate, vCurRow.Sum, Object.Date);
	EndIf;          
EndProcedure // HotelProductsProductEndCodeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductsCheckInDateOnChange(pItem)
	vCurRow = Items.HotelProducts.CurrentData;
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.CheckInDate) Then
			vCurRow.CheckInDate = SecondShift(vCurRow.CheckInDate);
			If vCurRow.Duration > 0 Then
				vCurRow.CheckOutDate = BegOfDay(vCurRow.CheckInDate) + vCurRow.Duration*24*3600 - 3*3600;
			EndIf;
		EndIf;
	EndIf;   
EndProcedure // HotelProductsCheckInDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductsDurationOnChange(pItem)
	vCurRow = Items.HotelProducts.CurrentData;
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.CheckInDate) And vCurRow.Duration > 0 Then
			vCurRow.CheckOutDate = BegOfDay(vCurRow.CheckInDate) + vCurRow.Duration*24*3600 - 3*3600;
		EndIf;
	EndIf;    
EndProcedure // HotelProductsDurationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductsCheckOutDateOnChange(pItem)
	vCurRow = Items.HotelProducts.CurrentData;
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.CheckInDate) And ValueIsFilled(vCurRow.CheckOutDate) Then
			vCurRow.Duration = Round((EndOfDay(vCurRow.CheckOutDate) - BegOfDay(vCurRow.CheckInDate))/(24*3600), 0);
		EndIf;
	EndIf;
EndProcedure // HotelProductsCheckOutDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductsPriceOnChange(pItem)
	vCurRow = Items.HotelProducts.CurrentData;
	If vCurRow <> Undefined Then
		vCurRow.Sum = Round(vCurRow.Price*vCurRow.Quantity, 2);
		vCurRow.VATSum = CalculateVATSumAtServer(Object.VATRate, vCurRow.Sum, Object.Date);
	EndIf;
EndProcedure // HotelProductsPriceOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure HotelProductsOnEditEnd(pItem, pNewRow, pCancelEdit)
	CalculateTotalFooterAtClientServer();
EndProcedure // HotelProductsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductsSumOnChange(pItem)
	vCurRow = Items.HotelProducts.CurrentData;
	If vCurRow <> Undefined Then
		If vCurRow.Quantity > 0 Then
			vCurRow.Price = Round(vCurRow.Sum/vCurRow.Quantity, 2);
		Else
			vCurRow.Price = vCurRow.Sum;
		EndIf;
		vCurRow.VATSum = CalculateVATSumAtServer(Object.VATRate, vCurRow.Sum, Object.Date);
	EndIf; 	
EndProcedure // HotelProductsSumOnChange     

// -----------------------------------------------------------------------------
&AtClient
Procedure VATRateOnChange(pItem)
	For Each vRow In Object.HotelProducts Do
		vRow.VATSum = CalculateVATSumAtServer(Object.VATRate, vRow.Sum, Object.Date);
	EndDo;     
EndProcedure // VATRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CurrencyOnChange(pItem)
	Object.CurrencyExchangeRate = GetCurrencyExchangeRateAtServer(Object.Hotel, Object.Currency, Object.ExchangeRateDate);
	For Each vRow In Object.HotelProducts Do
		vRow.Price = Round(vRow.Price * SavCurrencyExchangeRate / Object.CurrencyExchangeRate, 2);
		vRow.Sum = Round(vRow.Price*vRow.Quantity, 2);
		vRow.VATSum = CalculateVATSumAtServer(Object.VATRate, vRow.Sum, Object.Date);
	EndDo;
	// Save current currency and rate
	SavCurrency = Object.Currency;
	SavCurrencyExchangeRate = Object.CurrencyExchangeRate;   
EndProcedure // CurrencyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ExchangeRateDateOnChange(pItem)
	Object.CurrencyExchangeRate = GetCurrencyExchangeRateAtServer(Object.Hotel, Object.Currency, Object.ExchangeRateDate);
	// Save current currency and rate
	SavCurrency = Object.Currency;
	SavCurrencyExchangeRate = Object.CurrencyExchangeRate;
EndProcedure // ExchangeRateDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CurrencyExchangeRateOnChange(pItem)
	Object.CurrencyExchangeRate = GetCurrencyExchangeRateAtServer(Object.Hotel, Object.Currency, Object.ExchangeRateDate);
	// Save current currency and rate
	SavCurrency = Object.Currency;
	SavCurrencyExchangeRate = Object.CurrencyExchangeRate;   
EndProcedure // CurrencyExchangeRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductsHotelProductParentOnChange(pItem)
	HotelProductsHotelProductParentOnChangeAtServer(Items.HotelProducts.CurrentRow);
EndProcedure // HotelProductsHotelProductParentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();  
EndProcedure // DateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FixProductPeriodOnChange(pItem)
	FixProductPeriodOnChangeAtServer();
EndProcedure // FixProductPeriodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductsHotelProductParentStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.HotelProducts.Form.tcGroupChoiceForm", New Structure("ChoiceMode, Hotel, RoomQuota, RoomType, CheckInDate", True, Object.Hotel, Undefined, Undefined, Undefined), pItem);  	  
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductsAfterDeleteRow(pItem)
	HotelProductsAfterDeleteRowAtServer();
EndProcedure // HotelProductsAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure VoucherShipmentTypeOnChange(pItem)
	VoucherShipmentTypeOnChangeAtServer();
EndProcedure //VoucherShipmentTypeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionLoadHotelProductsLog(pCommand)
	ActionLoadHotelProductsLogAtServer();     
	CalculateTotalFooterAtClientServer();
EndProcedure // ActionLoadHotelProductsLog

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintHotelProductsLog(pCommand)
	// Save document first
	If ThisForm.Modified Then
		If Not ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Open printing form
	vParams = New Structure("SelHotel,  SelDoc, SelObjectPrintForm", 
	                        Object.Hotel, Object.Ref, PredefinedValue("Catalog.ObjectPrintingForms.IssueHotelProductsPrintHotelProductsLog"));
	OpenForm("Document.IssueHotelProducts.Form.tcPrintForms", vParams, ThisForm);   
EndProcedure // PrintHotelProductsLog

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintBillOfShipment(pCommand)
	// Save document first
	If ThisForm.Modified Then
		If Not ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Open printing form
	vParams = New Structure("SelHotel,  SelDoc, SelObjectPrintForm", 
	                        Object.Hotel, Object.Ref, PredefinedValue("Catalog.ObjectPrintingForms.IssueHotelProductsPrintBillOfShipment"));
	OpenForm("Document.IssueHotelProducts.Form.tcPrintForms", vParams, ThisForm); 	 
EndProcedure // PrintBillOfShipment

// -----------------------------------------------------------------------------
&AtClient
Procedure IssueHotelProductsFillInvoice(pCommand)
	vForm = GetForm("Document.ProformaInvoice.ObjectForm");
	vFormData = vForm.Object; 	
	IssueHotelProductsFillInvoiceAtServer(vFormData);
	CopyFormData(vFormData, vForm.Object);
	vForm.Open(); 
EndProcedure // IssueHotelProductsFillInvoice

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDocumentAppearance()
	vLogMode = GetOperationType();
	
	Items.GroupIssueToCounterpartyData.Visible = Not vLogMode;
	
	Items.HotelProductsActionLoadHotelProductsLog.Enabled = vLogMode;
	Items.HotelProductsActionLoadHotelProductsLog.Visible = vLogMode;

	Items.FormIssueHotelProductsFillInvoice.Enabled = Not vLogMode;
	Items.FormIssueHotelProductsFillInvoice.Visible = Not vLogMode;
	
	Items.HotelProductsAdd.Enabled = Not vLogMode;
	Items.HotelProductsAdd.Visible = Not vLogMode;
	
	Items.HotelProductsCopy.Enabled = Not vLogMode;
	Items.HotelProductsCopy.Visible = Not vLogMode;
	
	Items.HotelProductsAdd.Enabled = Not vLogMode;
	Items.HotelProductsAdd.Visible = Not vLogMode;
	
	Items.HotelProductsHotelProductParent.ReadOnly = vLogMode;
	Items.HotelProductsHotelProduct.ReadOnly = vLogMode;
	Items.HotelProductsQuantity.ReadOnly = vLogMode;
	Items.HotelProductsCheckInDate.ReadOnly = vLogMode;
	Items.HotelProductsDuration.ReadOnly = vLogMode;
	Items.HotelProductsCheckOutDate.ReadOnly = vLogMode;
	Items.HotelProductsSum.ReadOnly = vLogMode;
	Items.HotelProductsVATSum.ReadOnly = vLogMode;
	Items.HotelProductsSocialGroup.ReadOnly = vLogMode;
	Items.HotelProductsRoomType.ReadOnly = vLogMode;
	Items.HotelProductsClient.Visible = vLogMode;
	Items.HotelProductsHotelProduct.Visible = vLogMode;
	Items.HotelProductsGuestGroup.Visible = Not vLogMode;
	Items.HotelProductsParentDoc.Visible = Not vLogMode;
	Items.HotelProductsProductStartCode.Visible = Not vLogMode;
	Items.HotelProductsProductEndCode.Visible = Not vLogMode;
	Items.HotelProductsService.Visible = Not vLogMode;
	Items.HotelProductsPrice.Visible = Not vLogMode;
	
	Items.PrintHotelProductsLog.Enabled = vLogMode;
	Items.PrintBillOfShipment.Enabled = Not vLogMode;           
EndProcedure // SetDocumentAppearance

// -----------------------------------------------------------------------------
&AtServer
Function GetOperationType()
	vLogMode = False;
	If ValueIsFilled(Object.VoucherShipmentType) Then
		If Object.VoucherShipmentType = Enums.VoucherShipmentTypes.RegistrationOfVouchersIssuedInTheHotel Then
			vLogMode = True;
		EndIf;
	Else
		If Object.HotelProducts.Count() > 0 Then
			If ValueIsFilled(Object.HotelProducts.Get(0).HotelProduct) Then
				vLogMode = True;
				Object.VoucherShipmentType = Enums.VoucherShipmentTypes.RegistrationOfVouchersIssuedInTheHotel;
			EndIf;
		EndIf;
		If Not ValueIsFilled(Object.VoucherShipmentType) Then
			Object.VoucherShipmentType = Enums.VoucherShipmentTypes.RegistrationOfVauchersShippedToTheCounterparty;
		EndIf;
	EndIf;
	Return vLogMode;
EndFunction //GetOperationType

// -----------------------------------------------------------------------------
&AtServerNoContext
Function AddToNumberWithPrefixAtServer(pProductStartCode, pQuantity)
	 Return cmAddToNumberWithPrefix(pProductStartCode, pQuantity);
EndFunction // AddToNumberWithPrefixAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CalculateVATSumAtServer(pVATRate, pSum, pDate)
	Return cmCalculateVATSum(pVATRate, pSum, pDate);  
EndFunction // CalculateVATSumAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function SubtractNumbersWithPrefixAtServer(pProductEndCode, pProductStartCode)
	Return cmSubtractNumbersWithPrefix(pProductEndCode, pProductStartCode);
EndFunction // SubtractNumbersWithPrefixAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelProductsHotelProductParentOnChangeAtServer(pCurRow)
	If pCurRow <> Undefined Then
		vCurRow = Object.HotelProducts.FindByID(pCurRow);
		If vCurRow <> Undefined Then
			If ValueIsFilled(vCurRow.HotelProductParent) Then
				If ValueIsFilled(vCurRow.HotelProductParent.Service) Then
					vCurRow.Service = vCurRow.HotelProductParent.Service;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // HotelProductsHotelProductParentOnChangeAtServer

// -----------------------------------------------------------------------------
Procedure CalculateTotalFooterAtClientServer()
	vSum = 0;
	vQuantity =0;
	For Each vRow In Object.HotelProducts Do
		vSum = vSum + vRow.Sum;
		vQuantity = vQuantity + vRow.Quantity;
	EndDo;  	
	TotalSum = vSum;
	TotalQuantity = vQuantity;
EndProcedure // CalculateTotalFooterAtClientServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCurrencyExchangeRateAtServer(pHotel, pCurrency, pExchangeRateDate)
	Return cmGetCurrencyExchangeRate(pHotel, pCurrency, pExchangeRateDate);   
EndFunction // GetCurrencyExchangeRateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Automatically assign new document number if year has changed
	If ValueIsFilled(vObj.Date) And ValueIsFilled(OldDate) Then
		If Year(OldDate) <> Year(vObj.Date) Then
			vObj.SetNewNumber();
		EndIf;
		OldDate = vObj.Date;
	EndIf; 
	// Set object back to form attributes
	ValueToFormAttribute(vObj, "Object");  
EndProcedure // DateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FixProductPeriodOnChangeAtServer()
	If Object.FixProductPeriod Then
		If Object.FixPlannedPeriod Then
			Object.FixPlannedPeriod = False;
		EndIf;
	EndIf;
EndProcedure // FixProductPeriodOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionLoadHotelProductsLogAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.HotelProducts.Clear();
	// Fill hotel products
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	HotelProductLogBalance.HotelProduct,
	|	HotelProductLogBalance.FolioCurrency,
	|	HotelProductLogBalance.SumBalance
	|FROM
	|	AccumulationRegister.HotelProductLog.Balance(
	|			&qPeriod,
	|			Hotel = &qHotel
	|				AND FolioCurrency = &qCurrency) AS HotelProductLogBalance
	|
	|ORDER BY
	|	HotelProductLogBalance.HotelProduct.Parent.Code,
	|	HotelProductLogBalance.HotelProduct.Code";
	vQry.SetParameter("qHotel", vObj.Hotel);
	vQry.SetParameter("qCurrency", vObj.Currency);
	vQry.SetParameter("qPeriod", New Boundary(vObj.Date, BoundaryType.Excluding));
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vRow = vObj.HotelProducts.Add();
		vRow.HotelProduct = vQryResRow.HotelProduct;
		vRow.Price = vQryResRow.SumBalance;
		vRow.Quantity = 1;
		vRow.Sum = vQryResRow.SumBalance;
		vRow.VATSum = 0;
		vRow.CheckInDate = vRow.HotelProduct.CheckInDate;
		vRow.CheckOutDate = vRow.HotelProduct.CheckOutDate;
		vRow.Duration = vRow.HotelProduct.Duration;
		vRow.Client = vRow.HotelProduct.Client;
		vRow.GuestGroup = Catalogs.GuestGroups.EmptyRef();
		vRow.HotelProductParent = vRow.HotelProduct.Parent;
		vRow.ParentDoc = Undefined;
		vRow.RoomType = vRow.HotelProduct.RoomType;
		vRow.SocialGroup = vRow.HotelProduct.SocialGroup;
		If ValueIsFilled(vRow.HotelProductParent) Then
			vRow.Service = vRow.HotelProductParent.Service;
		Else
			vRow.Service = Catalogs.Services.EmptyRef();
		EndIf;
	EndDo;
	// Set object back to form attributes
	ValueToFormAttribute(vObj, "Object");
	ThisForm.Modified = True;
EndProcedure // ActionLoadHotelProductsLogAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelProductsAfterDeleteRowAtServer()
	CalculateTotalFooterAtClientServer();
EndProcedure // HotelProductsAfterDeleteRowAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetPrintingFormsAppearance()
	If Not Catalogs.ObjectPrintingForms.IssueHotelProductsPrintHotelProductsLog.IsActive Then
		Items.PrintHotelProductsLog.Visible = False;
	EndIf;
	If Not Catalogs.ObjectPrintingForms.IssueHotelProductsPrintBillOfShipment.IsActive Then
		Items.PrintBillOfShipment.Visible = False;
	EndIf;  	
EndProcedure // SetPrintingFormsAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure IssueHotelProductsFillInvoiceAtServer(pFormData)      
	vInvObj = FormDataToValue(pFormData, Type("DocumentObject.ProformaInvoice"));
	vInvObj.Fill(Object.Ref);
	ValueToFormData(vInvObj, pFormData);  		
EndProcedure // IssueHotelProductsFillInvoiceAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure VoucherShipmentTypeOnChangeAtServer()
	// Clear list of vouchers
	If Object.HotelProducts.Count() > 0 Then
		Object.HotelProducts.Clear();
	EndIf;
	CalculateTotalFooterAtClientServer();
	// Set columns and items appearance
	SetDocumentAppearance();	
EndProcedure //VoucherShipmentTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function SecondShift(pDate)
	Return cm1SecondShift(pDate);
EndFunction // SecondShift

#EndRegion


