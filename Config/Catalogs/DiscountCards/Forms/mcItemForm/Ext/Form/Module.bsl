
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	WasNew = Object.Ref.IsEmpty();
	
	// Fill by input parameters
	pmFilling();
	
	// Set conditional appearance
 	SetFormAppearance();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	Title = Items.Pages.CurrentPage.Title;
EndProcedure // OnOpen

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "BonusesChanged" 
		Or pEventName = "Document.Payment.Write" 
		Or pEventName = "Document.BonusesPayment.Write" 
		Or pEventName = "Document.Return.Write" Then
		CardTransactionsRefreshRequestProcessing();
	EndIf;
EndProcedure // NotificationProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Catalog.DiscountCards.Changed", Object.Client);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolioTransactions(pCommand)
	vParamsStruct = New Structure("ParametersStructure", New Structure("ObjectRef", Object.Folio));
	OpenForm("CommonForm.tcFoliosForm", vParamsStruct, ThisObject, Object.Folio);
EndProcedure // OpenFolioTransactions

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure ClientOnChangeAtServer()
	If ValueIsFilled(Object.Client) Then
		If ValueIsFilled(Object.Client.ClientType) Then
			Object.ClientType = Object.Client.ClientType;
		EndIf;
		// Create card
		If Modified Then
			If Not Write() Then
				Return;
			EndIf;
		EndIf;
		// Get folio
		If Not ValueIsFilled(Object.Folio) Then
			Object.Folio = CreateFolio(Object.Identifier, Object.LoyaltyType, Object.Client, Object.Customer);
			Write();
		Else
			vFolioObj = Object.Folio.GetObject();
			vFolioObj.Client = Object.Client;
			vFolioObj.Customer = Object.Customer;
			vFolioObj.Write(DocumentWriteMode.Write);
		EndIf;
		If ValueIsFilled(Object.Folio) Then
			Items.FormOpenFolioTransactions.Enabled = True;
			Items.FormOpenFolioTransactions.Visible = True;
		EndIf;
	EndIf;
EndProcedure // ClientOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientOnChange(pItem)
	ClientOnChangeAtServer();
EndProcedure // ClientOnChange

// --------------------------------------------------------------------------------
&AtServer
Procedure CustomerOnChangeAtServer()
	If ValueIsFilled(Object.Customer) Then
		// Create card
		If Modified Then
			If Not Write() Then
				Return;
			EndIf;
		EndIf;
		// Get folio
		If Not ValueIsFilled(Object.Folio) Then
			Object.Folio = CreateFolio(Object.Identifier, Object.LoyaltyType, Object.Client, Object.Customer);
			Write();
		Else
			vFolioObj = Object.Folio.GetObject();
			vFolioObj.Client = Object.Client;
			vFolioObj.Customer = Object.AccountingCustomer;
			vFolioObj.Write(DocumentWriteMode.Write);
		EndIf;
		If ValueIsFilled(Object.Folio) Then
			Items.FormOpenFolioTransactions.Enabled = True;
			Items.FormOpenFolioTransactions.Visible = True;
		EndIf;
	EndIf;
EndProcedure // CustomerOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure CustomerOnChange(pItem)
	CustomerOnChangeAtServer();
EndProcedure // CustomerOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure LoyaltyTypeOnChange(Item)
	SetFormAppearance();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DiscountTypeOnChange(Item)
	SetFormAppearance();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ValidFromOnChange(Item = Undefined)     
	
	If ValueIsFilled(Object.DiscountType) And ValueIsFilled(Object.ValidFrom) Then
		vValidity = tcOnServer.cmGetAttributeByRef(Object.DiscountType, "Validity");
		If vValidity > 0 Then
			Object.ValidTo = Object.ValidFrom + vValidity * tcCommonFunctionOnClientServer.cmOneDay();
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Add(Command)
	// Write card first
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
		Modified = False;
	EndIf;
	// Open operation form
	OpenForm("Document.BonusesOperation.ObjectForm", New Structure("DiscountCard", Object.Ref));
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure Storno(Command)
	// Write card first
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
		Modified = False;
	EndIf;
	// Open operation form
	OpenForm("Document.BonusesOperation.ObjectForm", New Structure("IsExpense, DiscountCard", True, Object.Ref));
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ActivateCertificate(Command)
	// Write card first
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
		Modified = False;
	EndIf;
	// Get folio for payment
	If Not ValueIsFilled(Object.Folio) Then
		Object.Folio = CreateFolio(Object.Identifier, Object.LoyaltyType, Object.Client, Object.Customer);
		Write();
	EndIf;
	If ValueIsFilled(Object.Folio) Then
		Items.FormOpenFolioTransactions.Enabled = True;
		Items.FormOpenFolioTransactions.Visible = True;
	EndIf;
	// Open new document form
	OpenForm("Document.Payment.Form.tcDocumentForm", New Structure("Basis, DiscountCard", Object.Folio, Object.Ref), ThisObject, UUID);
EndProcedure // ActivateCertificate

// --------------------------------------------------------------------------------
&AtClient
Procedure CardTransactionsRefreshRequestProcessing()
	SetFormAppearance();
	Items.AccumulatingDiscount.Refresh();
	Items.CardTransactions.Refresh();
	Items.Discounts.Refresh();
EndProcedure // CardTransactionsRefreshRequestProcessing

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SetFormAppearance()
	// Set parameters
	DiscountsList.Parameters.SetParameterValue("qDiscountType", Object.DiscountType);
	AccumulatingDiscount.Parameters.SetParameterValue("qDiscountType", Object.DiscountType);
	vIsCertificate = Object.LoyaltyType = PredefinedValue("Enum.LoyaltyType.Certificate");
	If vIsCertificate Then
		Items.ClientType.Visible = False;
		Items.Client.Visible = False;
	Else
		Items.ClientType.Visible = True;
		Items.Client.Visible = True;
	EndIf;
	If Object.LoyaltyType = PredefinedValue("Enum.LoyaltyType.Discount") Then
		Items.GroupInvoice.Visible = False;
	Else
		Items.GroupInvoice.Visible = True;
	EndIf;
	Items.NominalCertificate.Visible = False;
	// Set visible
	If Not ValueIsFilled(Object.Folio) Then
		Items.FormOpenFolioTransactions.Enabled = False;
		Items.FormOpenFolioTransactions.Visible = False;
	EndIf;		
	If Object.Ref.IsEmpty() Then
		Items.CardTransactionsAdd.Enabled = False;
		Items.CardTransactionsAdd.Visible = False;
		Items.CardTransactionsStorno.Enabled = False;
		Items.CardTransactionsStorno.Visible = False;
	Else
		If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") And Not tcOnServer.cmIsInRole("Administrator") Then
			Items.CardTransactionsAdd.Enabled = False;
			Items.CardTransactionsAdd.Visible = False;
			Items.CardTransactionsStorno.Enabled = False;
			Items.CardTransactionsStorno.Visible = False;
		EndIf;
	EndIf;
	If Not Object.Ref.IsEmpty() And (Object.LoyaltyType = Enums.LoyaltyType.Bonuses Or vIsCertificate) Then
		vChangeAvailable = ChangeAvailable(Object.Ref);
		Items.LoyaltyType.ReadOnly = Not vChangeAvailable;
		If WasNew Then
			Items.GroupDecorationMessage.Visible = Not vChangeAvailable;
		EndIf;
		If Not vChangeAvailable Then
			If Not cmCheckUserPermissions("HavePermissionToChangeActivatedCards") Then
				Items.Description.ReadOnly = True;
				Items.Identifier.ReadOnly = True;
				Items.DiscountType.ReadOnly = True;
				Items.GroupCardIsValidPeriod.ReadOnly = True;
			EndIf;	
		EndIf;	
	EndIf;
	If Object.LoyaltyType = PredefinedValue("Enum.LoyaltyType.Bonuses") Or vIsCertificate Then
		Items.PageBonuses.Visible = True;
		Items.PageEmpty.Visible = False;
		Items.PageDiscount.Visible = False;
		If Not Object.Ref.IsEmpty() Then
			vCardData = GetTotalByCard(Object.Ref, Object.LoyaltyType, Object.DiscountType);
			If TypeOf(vCardData) = Type("String") Then
				TotalByCard = "";
				NominalCertificate = "";
			Else
				TotalByCard = Format(vCardData.Balance, "NFD=2; NZ=0.00");
				NominalCertificate = Format(vCardData.CertificateNominal, "NFD=2; NZ=0.00");
			EndIf;
		Else
			TotalByCard = "";
			NominalCertificate = "";
		EndIf;
		Items.TotalByCard.Title = Nstr("en = 'Balance'; de = 'Saldo'; ru = 'Баланс'");
		If Object.LoyaltyType = PredefinedValue("Enum.LoyaltyType.Bonuses") Then
			Items.NominalCertificate.Visible = False;
		Else
			Items.NominalCertificate.Visible = True;
		EndIf;
	ElsIf Object.LoyaltyType = PredefinedValue("Enum.LoyaltyType.Discount") Then
		vIsAmountDiscount = Object.DiscountType.IsAmountDiscount;
		If vIsAmountDiscount Then
			Items.TotalByCard.TitleLocation = FormItemTitleLocation.None;
		Else
			Items.TotalByCard.Title = Nstr("en = 'Discount'; de = 'Rabatt'; ru = 'Скидка'");
		EndIf;
		Items.PageDiscount.Visible = True;
		Items.PageBonuses.Visible = False;
		Items.PageEmpty.Visible = False;
		Items.NominalCertificate.Visible = False;
		If Not Object.Ref.IsEmpty() Then
			TotalByCard = GetTotalByCard(Object.Ref, Object.LoyaltyType, Object.DiscountType);
		EndIf;
		// Visible Discounts
		Items.Discounts.Visible = Not vIsAmountDiscount And Not Object.DiscountType.IsAccumulatingDiscount;
		Items.DiscountTypeDifferentDiscountPercentsForServiceGroupsAllowed.Visible = Not vIsAmountDiscount;
		// Visible ServiceGroup
		Items.DiscountsServiceGroup.Visible = Object.DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed;
		Items.AccumulatingDiscountServiceGroup.Visible = Object.DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed;
		// Visible AccumulatingDiscount
		Items.GroupAccDiscount.Visible = Object.DiscountType.IsAccumulatingDiscount;
	Else
		Items.PageEmpty.Visible = True;
		Items.PageDiscount.Visible = False;
		Items.PageBonuses.Visible = False;
	EndIf;

	// Button activate certificate
	If vIsCertificate Then
		Items.CardTransactionsActivateCertificate.Visible = True;
	Else
		Items.CardTransactionsActivateCertificate.Visible = False;
	EndIf;
	
	BonusesTransactions.Parameters.SetParameterValue("qCard", Object.Ref);
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Function ChangeAvailable(pCard)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	SUM(Bonuses.Quantity) AS Amount
	|FROM
	|	AccumulationRegister.Bonuses AS Bonuses
	|WHERE
	|	Bonuses.Card = &qCard
	|	AND Bonuses.RecordType = VALUE(AccumulationRecordType.Receipt)";
	vQuery.SetParameter("qCard", pCard);
	vQueryResult = vQuery.Execute().Unload();
	For Each vQueryResultRow In vQueryResult Do
		If vQueryResultRow.Amount = Null Or vQueryResultRow.Amount = 0 Then
			Return True;
		Else
			Return False;
		EndIf;
	EndDo;
	Return True;
EndFunction // ChangeAvailable

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetTotalByCard(pCard, pLoyaltyType, pDiscountType)
	vVal = "0.00";
	If pLoyaltyType = Enums.LoyaltyType.Bonuses Or pLoyaltyType = Enums.LoyaltyType.Certificate Then
		vVal = AccumulationRegisters.Bonuses.mmGetBalanceByCard(pCard);
	ElsIf pLoyaltyType = Enums.LoyaltyType.Discount Then 
		vDiscountType = pDiscountType;
		If vDiscountType.IsAmountDiscount Then
			vVal = NStr("en = 'Discount amount'; de = 'Rabattbetrag'; ru = 'Суммовая'");
		ElsIf vDiscountType.IsAccumulatingDiscount Then
			If Not ValueIsFilled(vDiscountType) Then
				Return vVal;
			EndIf;	
			Query = New Query;
			Query.Text = 
			"SELECT
			|	AccumulatingDiscountsSliceLast.Discount AS Discount
			|FROM
			|	InformationRegister.AccumulatingDiscounts.SliceLast(, DiscountType = &qDiscountType) AS AccumulatingDiscountsSliceLast
			|
			|GROUP BY
			|	AccumulatingDiscountsSliceLast.Discount";
			
			Query.SetParameter("qDiscountType", vDiscountType);
			
			QueryResult = Query.Execute();
			
			vRes = QueryResult.Select();
			vVal = "";
			While vRes.Next() Do
				If vVal = "" Then
					vVal = String(vRes.Discount) + "%";
				Else	
					vVal = vVal + ", " + String(vRes.Discount) + "%";
				EndIf;
			EndDo;
		Else 
			If Not ValueIsFilled(vDiscountType) Then
				Return vVal;
			EndIf;	
			Query = New Query;
			Query.Text = 
			"SELECT
			|	DiscountsSliceLast.Discount AS Discount
			|FROM
			|	InformationRegister.Discounts.SliceLast(, DiscountType = &qDiscountType) AS DiscountsSliceLast
			|
			|GROUP BY
			|	DiscountsSliceLast.Discount";
			
			Query.SetParameter("qDiscountType", vDiscountType);
			
			QueryResult = Query.Execute();
			
			vRes = QueryResult.Select();
			vVal = "";
			While vRes.Next() Do
				If vVal = "" Then
					vVal = String(vRes.Discount) + "%";
				Else	
					vVal = vVal + ", " + String(vRes.Discount) + "%";
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vVal;
EndFunction //  GetTotalByCard()

// --------------------------------------------------------------------------------
&AtServerNoContext
Function CreateFolio(pIdentifier, pLoyaltyType, pClient, pCustomer)
	Return Catalogs.DiscountCards.CreateFolio(pIdentifier, pLoyaltyType, pClient, pCustomer);
EndFunction // CreateFolio

// --------------------------------------------------------------------------------
&AtServer
Procedure pmFilling()
	If Parameters.FillingValues.Property("LoyaltyType") Then
		If ValueIsFilled(Parameters.FillingValues.LoyaltyType) Then
			Object.LoyaltyType = Parameters.FillingValues.LoyaltyType;
			Object.DiscountType = GetDiscountTypeByLoyaltyType();
		EndIf;
	EndIf;
	If Parameters.FillingValues.Property("Identifier") Then
		If Not IsBlankString(Parameters.FillingValues.Identifier) Then
			Object.Identifier = TrimAll(Parameters.FillingValues.Identifier);
		EndIf;
	EndIf;
	If Parameters.FillingValues.Property("Client") Then
		If ValueIsFilled(Parameters.FillingValues.Client) Then
			Object.Client = Parameters.FillingValues.Client;
			If ValueIsFilled(Object.Client.ClientType) Then
				Object.ClientType = Object.Client.ClientType;
				If ValueIsFilled(Object.ClientType.DiscountType) Then
					Object.DiscountType = Object.ClientType.DiscountType;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure  // pmFilling

// --------------------------------------------------------------------------------
&AtServer
Function GetDiscountTypeByLoyaltyType()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DiscountTypes.Ref AS Ref
	|FROM
	|	Catalog.DiscountTypes AS DiscountTypes
	|WHERE
	|	NOT DiscountTypes.DeletionMark
	|	AND NOT DiscountTypes.IsFolder
	|	AND DiscountTypes.LoyaltyType = &qLoyaltyType
	|
	|ORDER BY
	|	DiscountTypes.SortCode,
	|	DiscountTypes.Description";
	vQry.SetParameter("qLoyaltyType", Object.LoyaltyType);
	vTypes = vQry.Execute().Unload();
	If vTypes.Count() > 0 Then
		Return vTypes.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetDiscountTypeByLoyaltyType

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Or tcOnServer.cmIsInRole("Administrator") Then
		Items.CardTransactionsAdd.Enabled = True;
		Items.CardTransactionsAdd.Visible = True;
		Items.CardTransactionsStorno.Enabled = True;
		Items.CardTransactionsStorno.Visible = True;
	EndIf;
	If ValueIsFilled(Object.Folio) Then
		Items.FormOpenFolioTransactions.Enabled = True;
		Items.FormOpenFolioTransactions.Visible = True;
	EndIf;
EndProcedure // AfterWriteAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure CardTransactionsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vCurData = Items.CardTransactions.CurrentData;
	If vCurData <> Undefined And pField.Name = "CardTransactionsRecorderSource" Then
		pStandardProcessing = False;
		If ValueIsFilled(vCurData.RecorderSource) Then
			If TypeOf(vCurData.RecorderSource) = Type("DocumentRef.Payment") Then
				OpenForm("Document.Payment.ObjectForm", New Structure("Key", vCurData.RecorderSource), ThisObject, vCurData.RecorderSource);
			ElsIf TypeOf(vCurData.RecorderSource) = Type("DocumentRef.Return") Then
				OpenForm("Document.Return.ObjectForm", New Structure("Key", vCurData.RecorderSource), ThisObject, vCurData.RecorderSource);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CardTransactionsSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure PagesOnCurrentPageChange(pItem, pCurrentPage)
	Title = pCurrentPage.Title;
EndProcedure // PagesOnCurrentPageChange

#EndRegion
