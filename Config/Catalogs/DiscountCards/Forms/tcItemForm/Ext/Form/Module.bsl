
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	WasNew = Object.Ref.IsEmpty();
	
	// Fill by input parameters
	pmFilling();
	
	If Not WasNew Then
		UpdateCardFromISD(); 
	EndIf;   

	// Set conditional appearance
 	SetFormAppearance();   
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If ValueIsFilled(ExternalSystem) Then
		StartProlongedOperations();	
	EndIf;
EndProcedure // OnOpen

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "BonusesChanged" Or 
	   pEventName = "Document.Payment.Write" Or 
	   pEventName = "Document.BonusesPayment.Write" Or 
	   pEventName = "Document.Return.Write" Then
		Refresh(Commands.Refresh);
	EndIf;
EndProcedure // NotificationProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Catalog.DiscountCards.Changed", Object.Client);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	If ValueIsFilled(ExternalSystem) And tcOnServer.cmGetAttributeByRef(ExternalSystem, "IntegrationType") = PredefinedValue("Enum.Integrations.ISD") Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		Object.Identifier = vEventData.DeviceData
	EndIf;
EndProcedure // ExternalEvent

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolioTransactions(pCommand)
	// APDEX
	vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

	vParamsStruct = New Structure("ParametersStructure", New Structure("ObjectRef", Object.Folio));
	OpenForm("CommonForm.tcFoliosForm", vParamsStruct, ThisObject, Object.Folio);
EndProcedure // OpenFolioTransactions

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure ClientOnChangeAtServer()
	If ValueIsFilled(Object.Client) Then
		If IsBlankString(Object.Phone) Then
			Object.Phone = Object.Client.Phone;
		EndIf;
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
Procedure Refresh(pCommand)
	SetFormAppearance();   
	If Items.GroupAccDiscount.Visible Then
		Items.AccumulatingDiscount.Refresh();
	EndIf; 
	If Items.CardTransactions.Visible Then
		Items.CardTransactions.Refresh();
	EndIf;       
	If Items.Discounts.Visible Then
		Items.Discounts.Refresh();     
	EndIf; 
	If ValueIsFilled(ExternalSystem) Then
		StartProlongedOperations();	
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ExternalBonusesRefresh(pCommand)
	If ValueIsFilled(ExternalSystem) Then
		StartProlongedOperations();    
	EndIf;
EndProcedure // ExternalBonusesRefresh

// --------------------------------------------------------------------------------
&AtClient
Procedure RefreshBonusesExpiryDates(pCommand)
	RefreshBonusesExpiryDatesAtServer();
EndProcedure

#EndRegion

#Region Wallet

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetWalletParamsForSMS(pRef)
	vParams = New Structure();
	
	// 1. get interaction parameters
	vExtSys = Catalogs.ExternalSystemInteractions.GetWalletSystem(pRef.CreateHotel);
	If Not ValueIsFilled(vExtSys) Then
		Return Undefined;
	EndIf;
	
	// 2. get wallet card or create new
	wcURL = Wallet.GetWalletURL(vExtSys, pRef);
	
	// 3. make a url and sms text from template
	If Not IsBlankString(wcURL) Then
		vSMSTemplate = vExtSys.SMSTemplate;
		If ValueIsFilled(vSMSTemplate) And (Not IsBlankString(vSMSTemplate.SMSTextRu) Or Not IsBlankString(vSMSTemplate.SMSTextEn) Or Not IsBlankString(vSMSTemplate.SMSTextDe)) Then
			vSMSText = SMS.GetSMSTextByLanguage(vSMSTemplate);
		Else
			vSMSText = "&WalletURL";
		EndIf;
		vSMSText = SMS.ReplaceSMSParameters(vSMSText, Undefined, pRef.Client, , pRef);
		vSMSText = StrReplace(vSMSText, "&WalletURL", SMS.GetShortLink(wcURL, vExtSys.URLShortener));
		
		vParams.Insert("SMSText", vSMSText);
		vParams.Insert("Reciever", pRef.Client);
		vParams.Insert("Phone", pRef.Phone);
		vParams.Insert("ReadOnlyReciever", False);
	
		Return vParams;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetParametersForSMS

// -----------------------------------------------------------------------------
&AtClient
Procedure SendWalletLink(Command)
	vParams = GetWalletParamsForSMS(Object.Ref);
	If ValueIsFilled(vParams) AND TypeOf(vParams) = Type("Structure") Then
		OpenForm("CommonForm.tcSMSSending", vParams, ThisObject, UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

#EndRegion 

#Region Background_Jobs

// -----------------------------------------------------------------------------
&AtClient
Procedure StartProlongedOperations(pUpdateQuietly = False)	
	
	vTempStorageAdress = PutToTempStorage(Null);
	
	vProcedureParametrs = New Array;
	vProcedureParametrs.Add(vTempStorageAdress);
	vProcedureParametrs.Add(Object.Ref);
	vProcedureParametrs.Add(ExternalSystem);
	                                             
	vBackgroundJob          = StartBackgroundJob("ProlongedOperations.GetListTransactionsFromExternalSystem", vProcedureParametrs, "Update bonuses transactions list", vTempStorageAdress);
	vNewRow 				= BackgroundJobsIsActive.Add();
	vNewRow.Name 		 	= "GetListTransactionsFromExternalSystem";
	vNewRow.UUID 		 	= vBackgroundJob.UUID;
	vNewRow.ResultAddress 	= vBackgroundJob.TempStorageAddress;
	vNewRow.Status 		 	= "Processing";
	Items.Group_Page_LoadingScheduledJobs.Visible = Not pUpdateQuietly;
	Items.Group_Page_ExternalBonusesTransactions.Visible = pUpdateQuietly;
	Items.DecorationProlongedOperation1.Visible = Not pUpdateQuietly;  
	Items.TotalByCard.Visible = pUpdateQuietly;
	
	AttachIdleHandler("CheckBackgroundJobs", 1, False);
EndProcedure // StartProlongedOperations

// -----------------------------------------------------------------------------
&AtServer                               
Function StartBackgroundJob(pProcedureName, pProcedureParametrs, pBacgroundJobName, pTempStorageAddress)
	Return AsyncCalls.StartBackgroundJob(pProcedureName, pProcedureParametrs, , pBacgroundJobName, pTempStorageAddress);	
EndFunction // StartBackgroundJob

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckBackgroundJobs()
	ProcessingBackgroundJobs = False;
	For Each vJob In BackgroundJobsIsActive Do 
		If vJob.Status = "Processing" Then
			ProcessingBackgroundJobs = True;
			vBackgroundvJob = CheckBackgroundJobStatus(vJob.UUID);
			
			If vBackgroundvJob <> Undefined Then 
				
				If vBackgroundvJob.Status = "Processing" Then 
					vJob.Status = "Processing"; 				
				ElsIf vBackgroundvJob.Status = "Error" Then 
					vJob.Status = "Error";
					tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: " + vJob.Name + "'; ru = 'Ошибка выполнения фонового задания: " + vJob.Name + "'"));					
					ChangeIsDeactivatedJob(vJob);
				ElsIf vBackgroundvJob.Status = "Canceled" Then 
					vJob.Status = "Canceled";
					tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job: " + vJob.Name + " - canceled.'; ru = 'Фоновое задание: " + vJob.Name + " - отменено.'"));   		
					ChangeIsDeactivatedJob(vJob);
				ElsIf vBackgroundvJob.Status = "Completed" Then 
					vJob.Status = "Completed";
					If TypeOf(vBackgroundvJob.Messages) = Type("Array") Then
						If vBackgroundvJob.Messages.Count() > 0 Then
							vMessages = StrConcat(vBackgroundvJob.Messages, "; ");
						EndIf;
					Else
						vMessages = vBackgroundvJob.Messages;
					EndIf;
					vJob.Messages = vMessages; 
					ProcessBackgroundJob(vJob);
					ChangeIsDeactivatedJob(vJob);
				EndIf;
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in checking background job: " + vJob.Name + "'; ru = 'Ошибка проверки фонового задания: " + vJob.Name + "'"));		
			EndIf;
		EndIf;
	EndDo;
	
	If NOT ProcessingBackgroundJobs Then
		BackgroundJobsIsActive.Clear();
		DetachIdleHandler("CheckBackgroundJobs");
	EndIf;
EndProcedure // CheckBackgroundJobs

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeIsDeactivatedJob(pBackgroundJob)
	If pBackgroundJob.Name = "GetListTransactionsFromExternalSystem" Then
		Items.Group_Page_LoadingScheduledJobs.Visible = False; 
		Items.DecorationProlongedOperation1.Visible = False;  
		Items.Group_Page_ExternalBonusesTransactions.Visible = True; 
		Items.TotalByCard.Visible = True;		
	EndIf;
EndProcedure // ChangeIsDeactivatedJob

// -----------------------------------------------------------------------------
&AtClient
Procedure ProcessBackgroundJob(pBackgroundJob)
	If pBackgroundJob.Name = "GetListTransactionsFromExternalSystem" Then
		Try
			UpdateExternalBonusesTransactions(pBackgroundJob.ResultAddress, pBackgroundJob.Messages);
		Except
		EndTry;		
	EndIf;
EndProcedure // ProcessBackgroundJob

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction // CheckBackgroundJobStatus

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
		If Not cmCheckUserPermissions("HavePermissionToAddManualBonusesOperation") Then
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
		Items.Pages.CurrentPage = Items.PageBonuses;
		If Object.DiscountType.ExternalBonusSystemIsUsed And Not ValueIsFilled(ExternalSystem) Then
			ExternalSystem = GetExternalSystemByDiscountType(Object.DiscountType);	
		EndIf;
		If Not Object.Ref.IsEmpty() Then
			If ValueIsFilled(ExternalSystem) Then 
				Items.CardTransactions.Visible = False;
				Items.PagesScheduledJobs.Visible = True;
			Else   
				Items.CardTransactions.Visible = True;
				Items.PagesScheduledJobs.Visible = False;
				vCardData = GetTotalByCard(Object.Ref, Object.LoyaltyType, Object.DiscountType);
				If TypeOf(vCardData) = Type("String") Then
					TotalByCard = "";
					NominalCertificate = "";
				Else
					TotalByCard = Format(vCardData.Balance, "NFD=2; NZ=0.00");
					NominalCertificate = Format(vCardData.CertificateNominal, "NFD=2; NZ=0.00");
				EndIf;  
			EndIf;
		Else
			TotalByCard = "";
			NominalCertificate = "";
		EndIf;
		Items.TotalByCard.Title = Nstr("en = 'Balance'; de = 'Saldo'; ru = 'Баланс'");
		If Object.LoyaltyType = PredefinedValue("Enum.LoyaltyType.Bonuses") Then
			Items.NominalCertificate.Visible = False;
			Items.TotalByCard.TitleLocation = FormItemTitleLocation.Left;
		Else
			Items.NominalCertificate.Visible = True;
		EndIf;
		
		// Wallet
		vExtSys = Catalogs.ExternalSystemInteractions.GetWalletSystem(Object.CreateHotel);
		If Not ValueIsFilled(vExtSys) Then
			Items.SendWalletLink.Visible = False;
		Else
			Items.SendWalletLink.Visible = True;
		EndIf;
	ElsIf Object.LoyaltyType = PredefinedValue("Enum.LoyaltyType.Discount") Then
		vIsAmountDiscount = Object.DiscountType.IsAmountDiscount;
		If vIsAmountDiscount Then
			Items.TotalByCard.TitleLocation = FormItemTitleLocation.None;
		Else
			Items.TotalByCard.Title = Nstr("en = 'Discount'; de = 'Rabatt'; ru = 'Скидка'");
		EndIf;
		Items.Pages.CurrentPage = Items.PageDiscount;
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
		Items.Pages.CurrentPage = Items.PageEmpty;
	EndIf;

	// Button activate certificate
	If vIsCertificate Then
		Items.CardTransactionsActivateCertificate.Visible = True;
	Else
		Items.CardTransactionsActivateCertificate.Visible = False;
	EndIf;
	
	BonusesTransactions.Parameters.SetParameterValue("qCard", Object.Ref);
	
	Items.BonusesExpiryDates.Visible = False;
	BonusesExpiryDates.Clear();
	If ValueIsFilled(Object.DiscountType) Then
		If Object.DiscountType.ExternalBonusSystemIsUsed Then
			Items.GroupNames.ReadOnly = True; 
			Items.Pages.ReadOnly = False; 
			Items.CardTransactions.CommandBar.Enabled = False;
		EndIf;
		If Object.DiscountType.BonusesValidity <> 0 Then
			Items.BonusesExpiryDates.Visible = True;
			RefreshBonusesExpiryDatesAtServer();
		EndIf;
	EndIf;		
EndProcedure // SetFormAppearance

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetExternalSystemByDiscountType(pDiscountType)
	vExternalSystem = Undefined;
	
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(vHotel) Then
		vQ = New Query;
		vQ.Text =
		"SELECT
		|	ExternalSystemIntegrationData.ExternalSystem AS ExternalSystem
		|FROM
		|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
		|WHERE
		|	ExternalSystemIntegrationData.RefKey1 = &qDiscountType
		|	AND ExternalSystemIntegrationData.DataType = ""DiscountTypes""
		|	AND ExternalSystemIntegrationData.ExternalSystem.Hotel = &qHotel";
		
		vQ.SetParameter("qDiscountType", pDiscountType);
		vQ.SetParameter("qHotel", vHotel);
		vResult = vQ.Execute().Unload();
		
		For Each vExternalSystemRow In vResult Do
			vExternalSystem = vExternalSystemRow.ExternalSystem;
			Break;
		EndDo;
		
		If Not ValueIsFilled(vExternalSystem) Then
			vParameters = New Array;
			vParameters.Add(New Structure("Name, Value, OR", "DiscountType", pDiscountType, False));   
			vParameters.Add(New Structure("Name, Value, OR", "Hotel", vHotel, False));
			vExternalSystem = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByParameters(vParameters);
		EndIf; 
	EndIf;
	Return vExternalSystem;	
EndFunction // GetExternalSystemByDiscountType

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
	If cmCheckUserPermissions("HavePermissionToAddManualBonusesOperation") Then
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
	If vCurData <> Undefined And pField.Name = "CardTransactionsSource" Then
		pStandardProcessing = False;
		If ValueIsFilled(vCurData.Source) Then
			If TypeOf(vCurData.Source) = Type("DocumentRef.Payment") Then
				OpenForm("Document.Payment.ObjectForm", New Structure("Key", vCurData.Source), ThisObject, vCurData.Source);
			ElsIf TypeOf(vCurData.Source) = Type("DocumentRef.Return") Then
				OpenForm("Document.Return.ObjectForm", New Structure("Key", vCurData.Source), ThisObject, vCurData.Source);
			EndIf;
		EndIf; 
	Else
		ShowValue(, vCurData.Recorder);		
	EndIf;
EndProcedure // CardTransactionsSelection

// -----------------------------------------------------------------------------
&AtServer
Function PhoneOnChangeAtServer(rPhone)
	rPhone = SMS.GetValidPhoneNumber(rPhone);
	vQry = New Query;
	vQry.Text =
	"SELECT TOP 10
	|	Clients.Ref AS Ref,
	|	Clients.FullName AS FullName,
	|	Clients.DateOfBirth AS DateOfBirth,
	|	Clients.Phone AS Phone
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	NOT Clients.IsFolder
	|	AND NOT Clients.DeletionMark
	|	AND Clients.Phone = &qPhone
	|
	|ORDER BY
	|	Clients.FullName,
	|	Clients.Code";
	vQry.SetParameter("qPhone", rPhone);
	vQryResult = vQry.Execute().Unload();
	vResultList = New ValueList();
	For Each vQryResultRow In vQryResult Do
		vResultStructure = New Structure("Client, ClientFullName, Phone");
		vResultStructure.Client = vQryResultRow.Ref;
		vResultStructure.ClientFullName = TrimAll(vQryResultRow.FullName);
		vResultStructure.Phone = TrimAll(vQryResultRow.Phone);
		vResultList.Add(vResultStructure, TrimAll(vQryResultRow.FullName) + " (" + Format(vQryResultRow.DateOfBirth, "DF=dd.MM.yyyy") + ")");
	EndDo;
	Return vResultList;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure PhoneOnChange(pItem)
	If ValueIsFilled(Object.Phone) Then
		vList = PhoneOnChangeAtServer(Object.Phone);
		If vList.Count() > 0 And Not ValueIsFilled(Object.Client) Then
			If vList.Count() = 1 Then
				vStructure = vList.Get(0).Value;
				Object.Client = vStructure.Client;
				ClientOnChangeAtServer();
				Modified = True;
			Else
				ShowChooseFromList(New NotifyDescription("AfterClientChoiceByPhone", ThisObject), vList, pItem);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterClientChoiceByPhone(pChoiceItem, pExtraParams) Export
	If pChoiceItem <> Undefined Then
		vStructure = pChoiceItem .Value;
		Object.Client = vStructure.Client;
		ClientOnChangeAtServer();
		Modified = True;
	EndIf;
EndProcedure // AfterClientChoiceByPhoneOrEMail

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateCardFromISD()
	If ValueIsFilled(Object.DiscountType) And Object.DiscountType.ExternalBonusSystemIsUsed And ValueIsFilled(Object.DiscountType.ExternalInteraction)
		And Object.DiscountType.ExternalInteraction.IntegrationType = Enums.Integrations.ISD Then
		
		// visible and description
		Items.ExternalBonusesTransactionsStatus.Visible = False; 
		Items.ExternalBonusesTransactionsAuthor.Visible = False;  
		Items.ExternalBonusesTransactionsPaymentAmount.Visible = False; 
		Items.ExternalBonusesTransactionsGroupBonuses.Visible = False;
		Items.ExternalBonusesTransactionsSalePoint.Title = Nstr("en = 'Details'; de = 'Einzelheiten'; ru = 'Подробно'");   
		Items.ExternalBonusesTransactionsPurchaseAmount.Title = Nstr("en = 'Amount'; de = 'Menge'; ru = 'Сумма'");
        Items.CardTransactionsAdd1.Visible = True;
		
		ExternalSystem = Object.DiscountType.ExternalInteraction; 
		
		vKeyParams = New Structure;   
		vKeyParams.Insert("media_num", Object.Identifier);
		vKeyParams.Insert("pointsale", ISD.GetPSALID(ExternalSystem));
		vKeyParams.Insert("Workstation",  String(SessionParameters.CurrentWorkstation));
		vKeyParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
		vKeyParams.Insert("User", String(SessionParameters.CurrentUser));
		
		vRes = ISD.CardInfo(ExternalSystem, vKeyParams);
		vCardChange = False;
		If vRes.Success Then
			vParams = Catalogs.DataConvertationRules.JSONtoStructure(vRes.RawResponse);   
			vDiscountTypeRef = Undefined;
			// update propery
			If vParams.Property("diskt_id") Then
				vDiscountType = Format(vParams.diskt_id, "NG=0"); 
				vTariffs = InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalSystem, "BonusesCardTypes");  
				If vTariffs.Count() > 0 Then 
					vFilter = vTariffs.FindRows(New Structure("ISDCode", vDiscountType)); 	
					If vFilter.Count() > 0 Then   
						vDiscountTypeRef = ?(IsBlankString(vFilter[0].DiscountType), Undefined, Catalogs.DiscountTypes.GetRef(New UUID(vFilter[0].DiscountType)));	
					EndIf;	
				EndIf;	
			EndIf;     
			vDiscountCardObj = FormAttributeToValue("Object"); 
			If ValueIsFilled(vDiscountTypeRef) And vDiscountCardObj.DiscountType <> vDiscountTypeRef Then
				vDiscountCardObj.DiscountType = vDiscountTypeRef;
				vCardChange = True;	
			EndIf;	
			If vParams.Property("client_phone") Then
				vPhone = SMS.GetValidPhoneNumber(vParams.client_phone);   
				If vDiscountCardObj.Phone <> vPhone Then
					vDiscountCardObj.Phone = vPhone;
					vCardChange = True;  
				EndIf;
			EndIf; 
			If vParams.Property("release") Then     
				vValidFrom = BegOfDay(Date(vParams.release + ":00")); 
				If vDiscountCardObj.ValidFrom <> vValidFrom Then
					vDiscountCardObj.ValidFrom = vValidFrom;    
					vCardChange = True;       
				EndIf;
			EndIf;
			If vParams.Property("validto") Then  
				vValidTo = BegOfDay(Date(vParams.validto + ":00")); 
				If vDiscountCardObj.ValidTo <> vValidTo Then  
					vDiscountCardObj.ValidTo = vValidTo;
					vCardChange = True;                          
				EndIf;
			EndIf;      
			If vParams.Property("bonus_bal") Then
				TotalByCard = Format(Number(vParams.bonus_bal), "NFD=2; NZ=0.00");
			EndIf;
			If vCardChange Then
				vDiscountCardObj.Description = Catalogs.DiscountCards.GetCardDescription(vDiscountCardObj);
				vDiscountCardObj.Write();
				ValueToFormAttribute(vDiscountCardObj, "Object");
			EndIf;
		EndIf;	
		If vCardChange = False Then
			vDiscountCardObj = FormAttributeToValue("Object");
			vDescription = Catalogs.DiscountCards.GetCardDescription(vDiscountCardObj);
			If vDescription <> vDiscountCardObj.Description Then
				vDiscountCardObj.Description = vDescription;
				vDiscountCardObj.Write();
				ValueToFormAttribute(vDiscountCardObj, "Object");
			EndIf;	
		EndIf;
    EndIf;
EndProcedure //  UpdateCardFromISD() 

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateExternalBonusesTransactions(pResultAddress, pMessages)
	vResult = GetFromTempStorage(pResultAddress);
	If TypeOf(vResult) = Type("Structure") Then
		TotalByCard = Format(vResult.Balance, "NFD=2; NZ=0.00");
		ExternalBonusesTransactions.Clear();
		ExternalBonusesTransactions.Load(vResult.Transactions);
	Else    
		If TypeOf(pMessages) = Type("String") Then
			tcCommonFunctionOnClientServer.TextMessage(pMessages);	
		ElsIf TypeOf(pMessages) = Type("Array") Then  
			For Each vMsg In pMessages Do
				tcCommonFunctionOnClientServer.TextMessage(vMsg);
			EndDo; 	
		EndIf;
	EndIf;
EndProcedure // UpdateBackgroundJobsTable

// -----------------------------------------------------------------------------
&AtClient
Procedure ReplaceCard(Command)
	vParam = New Structure;
	vParam.Insert("DiscountCard", Object.Ref); 
	OpenForm("Catalog.DiscountCards.Form.tcReplaceCardForm", vParam, , UUID, , , , FormWindowOpeningMode.LockOwnerWindow); 
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure RefreshBonusesExpiryDatesAtServer()
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	vDate = CurrentSessionDate();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BonusesBalance.Card AS Card,
	|	BonusesBalance.ExpiryDate AS ExpiryDate,
	|	BonusesBalance.QuantityBalance AS QuantityBalance,
	|	CASE
	|		WHEN BonusesBalance.ExpiryDate <> &qEmptyDate
	|			THEN DATEDIFF(&qDate, BonusesBalance.ExpiryDate, DAY)
	|		ELSE 0
	|	END AS DaysLeft
	|FROM
	|	AccumulationRegister.Bonuses.Balance(&qPeriod, Card = &qCard) AS BonusesBalance
	|
	|ORDER BY
	|	ExpiryDate";
	vQry.SetParameter("qCard", Object.Ref);
	vQry.SetParameter("qPeriod", New Boundary(vDate, BoundaryType.Excluding));
	vQry.SetParameter("qDate", BegOfDay(vDate));
	vQry.SetParameter("qEmptyDate", '00010101');
	BonusesExpiryDates.Load(vQry.Execute().Unload());
EndProcedure // RefreshBonusesExpiryDatesAtServer

#EndRegion
