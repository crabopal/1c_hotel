// -----------------------------------------------------------------------------
&AtServer
Function RoundTimeToHalfAnHour(pDateTime)
	vSeconds = 0;
	vMinutes = Minute(pDateTime);
	If vMinutes < 20 Then
		vSeconds = 0;
	ElsIf vMinutes >= 40 Then
		vSeconds = 60*60;
	Else
		vSeconds = 30*60;
	EndIf;
	vDateTime = Date(Year(pDateTime), Month(pDateTime), Day(pDateTime), Hour(pDateTime), 0, 0) + vSeconds;
	Return vDateTime;
EndFunction // RoundTimeToHalfAnHour

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	IsNew = False;
	WasNew = False;
	WasPosted = False;
	WasAlreadyPrint = False;
	FunctionsAndPrintFormsWereLoaded = False;
	
	// Process parameters from the group form
	If Parameters.Property("GuestGroup") Then
		If Parameters.GuestGroup <> Catalogs.GuestGroups.EmptyRef() Then
			Object.GuestGroup = Parameters.GuestGroup;
			If Object.Hotel <> Object.GuestGroup.Owner Then
				Object.Hotel = Object.GuestGroup.Owner;
			EndIf;
		EndIf;
	EndIf;
	
	// Call initialization routines for the new document
	If Not ValueIsFilled(Object.Ref) Then
		vObj = FormAttributeToValue("Object");
		vObj.pmFillAttributesWithDefaultValues();
		ValueToFormAttribute(vObj, "Object");
		IsNew = True;
	Else
		WasPosted = True;
	EndIf;
	
	// Process parameters from the resources calendar
	If Parameters.Property("Resource") Then
		If Object.NumberOfPersons = 0 Then
			Object.NumberOfPersons = 1;
		EndIf;
		// Get params
		vResource = Parameters.Resource;
		vHotel = Parameters.Hotel;
		vDateTimeFrom = RoundTimeToHalfAnHour(Parameters.DateTimeFrom);
		vDateTimeTo = RoundTimeToHalfAnHour(Parameters.DateTimeTo);
		If vDateTimeFrom = vDateTimeTo Then
			vDateTimeTo = vDateTimeTo + 30*60;
		EndIf;
		// Check if there are automatic prices for this resource
		If ValueIsFilled(vResource) Then
			vPrices = cmGetResourcePrices(vHotel, vDateTimeFrom, vDateTimeTo, Object.ClientType, vResource.Owner, vResource, Object.ServicePackage, Object.ServicePackages, Object.ResourceTariff);
			If ValueIsFilled(Object.ClientType) And vPrices.Count() = 0 Then
				vPrices = cmGetResourcePrices(vHotel, vDateTimeFrom, vDateTimeTo, Catalogs.ClientTypes.EmptyRef(), vResource.Owner, vResource, Object.ServicePackage, Object.ServicePackages, Object.ResourceTariff);
			EndIf;
			vThereArePrices = False;
			If vPrices.Count() > 0 Then
				vPricesRow = vPrices.Get(0);
				If vPricesRow.Quantity <> 0 Then
					vThereArePrices = True;
				EndIf;
			EndIf;
			If BegOfDay(vDateTimeFrom) < BegOfDay(vDateTimeTo) Then
				vThereArePrices = True;
			EndIf;
			// Fill object
			vObj = FormAttributeToValue("Object");
			vObj.ResourceType = vResource.Owner;
			vObj.Resource = vResource;
			vObj.DoResourceReservation = True;
			vObj.DateTimeFrom = vDateTimeFrom;
			vObj.DateTimeTo = vDateTimeTo;
			vObj.Duration = vObj.pmCalculateDuration();
			vObj.pmCalculateServices();
			ValueToFormAttribute(vObj, "Object");
			// Fill table
			If Not vThereArePrices Then
				vRow = Object.Services.Add();
				vRow.ServiceId = String(New UUID());
				vRow.AccountingDate = BegOfDay(vDateTimeFrom);
				vRow.DateTimeFrom =  Date(Year(vDateTimeFrom),Month(vDateTimeFrom),Day(vDateTimeFrom),Hour(vDateTimeFrom),0,0);
				vRow.DateTimeTo = Date(Year(vDateTimeTo),Month(vDateTimeTo),Day(vDateTimeTo),Hour(vDateTimeTo),0,0);
				vRow.TimeFrom = Date(1,1,1,Hour(vDateTimeFrom),0,0);
				vRow.TimeTo = Date(1,1,1,Hour(vDateTimeTo),0,0);
				vRow.IsManual = True;
				// Recalculate 
				ServicesServiceResourceOnChangeAtServer(vRow.GetID());
				ServicesQuantityOnChangeAtServer(vRow.GetID());
			EndIf;
		Else
			vObj = FormAttributeToValue("Object");
			// Fill object
			vObj.DateTimeFrom = vDateTimeFrom;
			vObj.DateTimeTo = vDateTimeTo;
			vObj.Duration = vObj.pmCalculateDuration();
			ValueToFormAttribute(vObj, "Object");
		EndIf;
	EndIf;
	If Not ValueIsFilled(Object.Ref) Then
		FillingObjects();
	Endif;
	If Not ValueIsFilled(Object.EventActivity) And ValueIsFilled(Object.Resource) And Not Object.DoResourceReservation Then
		Object.DoResourceReservation = True;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Fill statuses list
	FillStatusesList();
	
	// Fill group description
	FillGuestGroupDescriptionAtServer();
	
	// Fill service packages presentation
	FillServicePackagesPresentation();
	
	// Credit card presentation
	If ValueIsFilled(Object.CreditCard) Then
		CreditCardPresentation = TrimAll(Object.CreditCard);
		Items.ClearCreditCard.Visible = True;
	Else
		CreditCardPresentation = NStr("en='<Credit card>'; ru='<Кредитная карта>'; de='<Kreditkarte>'");
		Items.ClearCreditCard.Visible = False;
	EndIf;
	
	// Permissions
	If ValueIsFilled(Object.ParentDoc) And 
	  (TypeOf(Object.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation")) And 
	   Object.DoNotCalculateServices Then
		ThisForm.ReadOnly = True;
		Items.TServicePackagesPresentation.ReadOnly = True;
	EndIf;
	// Check edit prohibited date
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(Object.Hotel.EditProhibitedDate) And 
		   BegOfDay(Object.Hotel.EditProhibitedDate) >= BegOfDay(Object.DateTimeTo) Then
			ThisForm.ReadOnly = True;
			Items.TServicePackagesPresentation.ReadOnly = True;
		EndIf;
	EndIf;
	// Set user rights for some controls
	If Not cmCheckUserPermissions("HavePermissionToEditClosedForEditDocuments") Then
		If Object.IsClosedForEdit Then
			ThisForm.ReadOnly = True;
			Items.TServicePackagesPresentation.ReadOnly = True;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.ResourceReservationStatus) And Object.ResourceReservationStatus.ServicesAreDelivered Then
		If Not cmCheckUserPermissions("HavePermissionToEditCompletedResourceReservations") Then
			ThisForm.ReadOnly = True;
			Items.TServicePackagesPresentation.ReadOnly = True;
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToChangeCustomerInDocuments") Then
		If ValueIsFilled(Object.Ref) Then
			Items.Customer.ReadOnly = True;
			Items.Contract.ReadOnly = True;
			Items.Agent.ReadOnly = True;
			Items.ParentDoc.ReadOnly = True;
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditGuestGroup") Then
		Items.GuestGroup.ReadOnly = True;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditResourceReservationDocumentNumberAndDate") Then
		Items.Number.Enabled = False;
		Items.Date.Enabled = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToAddManualDiscounts") Then
		Items.DiscountCard.Enabled = True;
		Items.DiscountType.Enabled = True;
		Items.Discount.Enabled = False;
		Items.DiscountServiceGroup.Enabled = False;
		Items.DiscountConfirmationText.Enabled = True;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToInputDiscountCardNumberManually") Then
		Items.DiscountCard.TextEdit = False;
		Items.DiscountCard.ChoiceButton = False;
	Else
		Items.DiscountCard.TextEdit = True;
		Items.DiscountCard.ChoiceButton = True;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToChooseClientTypeManually") Then
		Items.ClientType.Enabled = False;
		Items.ClientTypeConfirmationText.Enabled = False;
	EndIf;
	// Optimize input of analitical attributes
	If Not cmCheckUserPermissions("HavePermissionToSkipInputOfReservationMarketingCode") Then
		Items.MarketingCode.AutoChoiceIncomplete = True;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToSkipInputOfReservationSourceOfBusiness") Then
		Items.SourceOfBusiness.AutoChoiceIncomplete = True;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToSkipInputOfClientType") Then
		Items.ClientType.AutoChoiceIncomplete = True;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToViewCreditCardsData") Then
		Items.CreditCardPresentation.Visible = False;
		Items.ClearCreditCard.Visible = False;
	EndIf;
	
	// Load customer contact persons list
	LoadCustomerContactPersonsList();
	
	// Fill array of planned payment methods
	Items.PlannedPaymentMethod.ChoiceList.LoadValues(FillArrayOfPaymentMethods());
	
	// Document parameters
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	// Check charging mode
	If ValueIsFilled(Object.Hotel) And Object.Hotel.CloseOfPeriodDoChargeServices Then
		Items.DoChargingToDate.Visible = True;
	Else
		Items.DoChargingToDate.Visible = False;
	EndIf;
	
	// Printing
	If ValueIsFilled(Object.Ref) Then
		FillFunctionsButton();
		FillPrintingButton();
		FunctionsAndPrintFormsWereLoaded = True;
	Else
		WasNew = True;
	EndIf;
	
	// Show properties
	If Not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToSkipInputOfReservationMarketingCode") Or 
		   Not cmCheckUserPermissions("HavePermissionToSkipInputOfClientType") Then
			Items.GroupProperties.Show();
		EndIf;
	EndIf;
	
	// Save current accounting date
	OldAccountingDate = BegOfDay(Object.DateTimeFrom);
	
	// Fill amount without discount
	CalculateTotalServices();
		
	// Build collapsed groups title
	BuildAccountingGroupCollapsedTitle();
	BuildContactsGroupCollapsedTitle();
	BuildDiscountsGroupCollapsedTitle();
	BuildCommissionGroupCollapsedTitle();
	BuildPropertiesGroupCollapsedTitle();
	BuildRemarksGroupCollapsedTitle();
	
	// Fill period
	FillMainResourcePeriod();
	
	// Fill document orders
	FillOrders();
	
	// Fill document tasks button
	If ValueIsFilled(Object.Ref) Then
		vCount = GetNumberOfMessagesForObject(Object.Ref);
		If vCount = 0 Then
			Items.FormMessage.Title = NStr("en='Tasks';ru='Задачи';de='Aufgaben'");
		Else
			Items.FormMessage.Title = NStr("ru = 'Задачи - " + vCount + "'; en = 'Tasks - " + vCount + "'; de = 'Aufgaben - " + vCount + "'");
		EndIf;
	Else
		Items.FormMessage.Title = NStr("en='Tasks';ru='Задачи';de='Aufgaben'");
	EndIf;
	
	// Fill document tasks presentation
	FillTasksPresentation();
EndProcedure // OnCreateAtServer

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillingObjects()
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.GuestGroup) Then
		vGuestGroupRef = Object.GuestGroup;
		If ValueIsFilled(vGuestGroupRef.ClientDoc) And vGuestGroupRef.ClientDoc = Type("DocumentRef.ResourceReservation") Then
			vClientDocRef = vGuestGroupRef.ClientDoc;
			vObj.Agent = vClientDocRef.Agent;
			vObj.Customer = vClientDocRef.Customer;
			vObj.Contract = vClientDocRef.Contract;
			vObj.ContactPerson = vClientDocRef.ContactPerson;
			vObj.Company = vClientDocRef.Company;
			vObj.Client = vClientDocRef.Client;
			vObj.SourceOfBusiness = vClientDocRef.SourceOfBusiness;
			vObj.MarketingCode = vClientDocRef.MarketingCode;
			vObj.Discount = vClientDocRef.Discount;
			vObj.DiscountCard = vClientDocRef.DiscountCard;
			vObj.DiscountServiceGroup = vClientDocRef.DiscountServiceGroup;
			vObj.DiscountSum = vClientDocRef.DiscountSum;
			vObj.DiscountType = vClientDocRef.DiscountType;
			vObj.GuaranteeType = vClientDocRef.GuaranteeType;
		Else
			vObj.Agent = vGuestGroupRef.Agent;
			vObj.Customer = vGuestGroupRef.Customer;
			vObj.Contract = vGuestGroupRef.Contract;
			vObj.Client = vGuestGroupRef.Client;
			vObj.SourceOfBusiness = vGuestGroupRef.SourceOfBusiness;
			vObj.MarketingCode = vGuestGroupRef.MarketingCode;
			vObj.DiscountType = vGuestGroupRef.DiscountType;
			vObj.GuaranteeType = vGuestGroupRef.GuaranteeType;	
		EndIf;
	EndIf;
	ResourceOnChangeAtServer(vObj);
	SourceOfBusinessOnChangeAtServer(vObj);
	MarketingCodeOnChangeAtServer(vObj);
	CustomerOnChangeAtServer(vObj);
	AgentOnChangeAtServer(vObj);
	ClientOnChangeAtServer(vObj);
	DiscountTypeOnChangeAtServer(vObj);
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
EndProcedure // FillingObjects

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetNumberOfMessagesForObject(pORef)
	Return cmGetNumberOfMessagesForObject(pORef);
EndFunction // GetNumberOfMessagesForObject

// -----------------------------------------------------------------------------
&AtServer
Function FillArrayOfPaymentMethods()
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	PaymentMethods.Ref AS Ref
	|FROM
	|	Catalog.PaymentMethods AS PaymentMethods
	|WHERE
	|	NOT PaymentMethods.DeletionMark
	|	AND NOT PaymentMethods.IsForReturnOnly
	|	AND (PaymentMethods.IsByCreditCard
	|			OR PaymentMethods.IsByCash
	|			OR PaymentMethods.IsByBankTransfer
	|			OR PaymentMethods.IsByGiftCertificate
	|			OR PaymentMethods.Ref = VALUE(Catalog.PaymentMethods.Settlement))
	|
	|ORDER BY
	|	PaymentMethods.SortCode";
	vResult = vQry.Execute().Select();
	vArrayOfPaymentMethods = New Array;
	While vResult.Next() Do
		vArrayOfPaymentMethods.Add(vResult.Ref);
	EndDo;
	// Return
	Return vArrayOfPaymentMethods;
EndFunction // FillArrayOfPaymentMethods

// -----------------------------------------------------------------------------
&AtServer
Function GetResourceReservationStatusIcon(pResourceReservationStatus)
	vPicture = PictureLib.Empty;
	If ValueIsFilled(pResourceReservationStatus) Then
		If pResourceReservationStatus.IsActive Then 
			If pResourceReservationStatus.ServicesAreDelivered Then
				vPicture = PictureLib.Pin;
			ElsIf pResourceReservationStatus.IsGuaranteed Then
				vPicture = PictureLib.IsGuaranteed;
			Else
				vPicture = PictureLib.IsActive;
			EndIf;
		Else
			vPicture = PictureLib.IsNotActive;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // GetResourceReservationStatusIcon

// -----------------------------------------------------------------------------
&AtServer
Procedure FillStatusesList()
	vStatuses = cmGetAllResourceReservationStatuses();
	If vStatuses.Count() > 0 Then
		pStandardProcessing = False;
		vStatusesList = Items.ResourceReservationStatus.ChoiceList;
		vStatusesList.LoadValues(vStatuses.UnloadColumn("ResourceReservationStatus"));
		For Each vStatusesListItem In vStatusesList Do
			vStatusesListItem.Picture = GetResourceReservationStatusIcon(vStatusesListItem.Value);
		EndDo;
	Else
		Items.ResourceReservationStatus.ChoiceList.Clear();
	EndIf;
EndProcedure // FillStatusesList

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesAccountingDateOnChange(pItem)
	vCurData = CurrentItem.CurrentData;
	If vCurData <> Undefined Then
		If Not ValueIsFilled(vCurData.AccountingDate) Then
			vCurData.AccountingDate = BegOfDay(CurrentDate());
		EndIf;
		vCurData.DateTimeFrom = BegOfDay(vCurData.AccountingDate) + (vCurData.TimeFrom - BegOfDay(vCurData.TimeFrom));
		If vCurData.TimeFrom < vCurData.TimeTo Then
			vCurData.DateTimeTo = BegOfDay(vCurData.AccountingDate) + (vCurData.TimeTo - BegOfDay(vCurData.TimeTo));
		Else
			vCurData.DateTimeTo = BegOfDay(vCurData.AccountingDate) + (vCurData.TimeTo - BegOfDay(vCurData.TimeTo)) + 24*3600;
		EndIf;
		ServicesServiceOnChangeAtServer(CurrentItem.CurrentRow, True);
	EndIf;
EndProcedure // ServicesAccountingDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesDateTimeFromOnChange(pItem)
	vCurData = CurrentItem.CurrentData;
	If vCurData <> Undefined Then
		If Not ValueIsFilled(vCurData.AccountingDate) Then
			vCurData.AccountingDate = BegOfDay(CurrentDate());
		EndIf;
		vCurData.DateTimeFrom = BegOfDay(vCurData.AccountingDate) + (vCurData.TimeFrom - BegOfDay(vCurData.TimeFrom));
		If vCurData.TimeFrom < vCurData.TimeTo Then
			vCurData.DateTimeTo = BegOfDay(vCurData.AccountingDate) + (vCurData.TimeTo - BegOfDay(vCurData.TimeTo));
		Else
			vCurData.DateTimeTo = BegOfDay(vCurData.AccountingDate) + (vCurData.TimeTo - BegOfDay(vCurData.TimeTo)) + 24*3600;
		EndIf;
		ServicesServiceOnChangeAtServer(CurrentItem.CurrentRow, True);
	EndIf;
EndProcedure // ServicesDateTimeFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesDateTimeToOnChange(pItem)
	vCurData = CurrentItem.CurrentData;
	If vCurData <> Undefined Then
		If Not ValueIsFilled(vCurData.AccountingDate) Then
			vCurData.AccountingDate = BegOfDay(CurrentDate());
		EndIf;
		vCurData.DateTimeFrom = BegOfDay(vCurData.AccountingDate) + (vCurData.TimeFrom - BegOfDay(vCurData.TimeFrom));
		If vCurData.TimeFrom < vCurData.TimeTo Then
			vCurData.DateTimeTo = BegOfDay(vCurData.AccountingDate) + (vCurData.TimeTo - BegOfDay(vCurData.TimeTo));
		Else
			vCurData.DateTimeTo = BegOfDay(vCurData.AccountingDate) + (vCurData.TimeTo - BegOfDay(vCurData.TimeTo)) + 24*3600;
		EndIf;
		ServicesServiceOnChangeAtServer(CurrentItem.CurrentRow, True);
	EndIf;
EndProcedure // ServicesDateTimeToOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesOnStartEdit(pItem, pNewRow, pClone)
	vCurData = pItem.CurrentData;
	If vCurData <> Undefined Then
		If pNewRow Or IsBlankString(vCurData.ServiceId) Then
			vCurData.IsManual = True;
			vOldServiceId = vCurData.ServiceId;
			vCurData.ServiceId = String(New UUID());
			If Not pClone Then
				vCurData.Company = Object.Company;
				vCurData.AccountingDate = BegOfDay(Object.DateTimeFrom);
				vCurData.DateTimeFrom = Object.DateTimeFrom;
				vCurData.DateTimeTo =  Object.DateTimeTo;
				vCurData.TimeFrom = '00010101' + (Object.DateTimeFrom - BegOfDay(Object.DateTimeFrom));
				vCurData.TimeTo = '00010101' + (Object.DateTimeTo - BegOfDay(Object.DateTimeTo));
				vCurData.EventActivity = PredefinedValue("Catalog.EventActivities.EmptyRef");
				Items.ServicesEventActivity.ChooseType = False;
			Else
				vCurData.IsManualAuthor = Undefined;
				vCurData.IsManualDate = '00010101';
				// Copy service items
				vOldSIRows = Object.ServiceItems.FindRows(New Structure("ServiceId", vOldServiceId));
				For Each vOldSIRow In vOldSIRows Do
					vNewSIRow = Object.ServiceItems.Add();
					FillPropertyValues(vNewSIRow, vOldSIRow);
					vNewSIRow.ServiceId = vCurData.ServiceId;
				EndDo;
			EndIf;
		EndIf;
		If vCurData.EventActivity <> Undefined Then
			Items.ServicesEventActivity.ChooseType = False;
			Items.ServicesEventActivity.ChoiceButton = False;
			Items.ServicesEventActivity.DropListButton = True;
		Else
			Items.ServicesEventActivity.ChooseType = True;
			Items.ServicesEventActivity.ChoiceButton = True;
			Items.ServicesEventActivity.DropListButton = False;
		EndIf;
	EndIf;
EndProcedure // ServicesOnStartEdit

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesServiceOnChangeAtServer(pRow, pDoNotRefreshServiceItems = False)
	vCurRow = Object.Services.FindByID(pRow);
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.Service) Then
			vObj = FormAttributeToValue("Object");
			vCurPrice = 0;
			vCurUnit = vCurRow.Service.Unit;
			vCurCurrency = vObj.FolioCurrency;
			vCompany = vObj.Company;
			If ValueIsFilled(vObj.ChargingFolio) And vObj.ChargingFolio.DoNotUpdateCompany Then
				vCompany = vObj.ChargingFolio.Company;
			EndIf;
			vCurVATRate = vCompany.VATRate;
			vCurRow.Company = vCompany;
			If ValueIsFilled(vCurRow.Service.Resource) Then
				vCurRow.ServiceResource = vCurRow.Service.Resource;
				If ValueIsFilled(vCurRow.AccountingDate) Then
					vResourceObj = vCurRow.ServiceResource.GetObject();
					vDefaultTimes = vResourceObj.pmGetResourceDefaultChargingTimes(vCurRow.AccountingDate);
					If ValueIsFilled(vDefaultTimes.TimeFrom) Then
						vCurRow.TimeFrom = vDefaultTimes.TimeFrom;
					EndIf;	
					If ValueIsFilled(vDefaultTimes.TimeTo) Then
						vCurRow.TimeTo = vDefaultTimes.TimeTo;
					EndIf;
				EndIf;
				If vCurRow.ServiceResource <> vObj.Resource Then
					vCurRow.DoResourceReservation = True;
				EndIf;
			EndIf;
			vSrvPrices = vCurRow.Service.GetObject().pmGetServicePrices(vObj.Hotel, vCurRow.AccountingDate, vObj.ClientType);
			For Each vSrvPricesRow In vSrvPrices Do
				vCurPrice = vSrvPricesRow.Price;
				vCurUnit = vCurRow.Service.Unit;
				vCurCurrency = vSrvPricesRow.Currency;
				If Not vCompany.IsUsingSimpleTaxSystem Then
					vCurVATRate = vSrvPricesRow.VATRate;
				Else
					vCurVATRate = vCompany.VATRate;
				EndIf;
				Break;
			EndDo;
			If vCurRow.Quantity = 0 Then
				If vCurRow.NumberOfPersons = 0 Then
					vCurRow.Quantity = 1;
				Else
					If ValueIsFilled(vCurRow.Service.ServiceType) And vCurRow.Service.ServiceType.ActualAmountIsChargedExternally Then
						vCurRow.Quantity = vCurRow.NumberOfPersons;
					Else
						vCurRow.Quantity = 1;
					EndIf;
				EndIf;
			EndIf;
			// Try to get resource price according to the resource reservation period
			If vCurRow.IsManual Then
				vCurDateTimeFrom = vCurRow.AccountingDate + (vCurRow.TimeFrom - BegOfDay(vCurRow.TimeFrom));
				vCurDateTimeTo = vCurRow.AccountingDate + (vCurRow.TimeTo - BegOfDay(vCurRow.TimeTo));
				vPrices = cmGetResourcePrices(vObj.Hotel, vCurDateTimeFrom, vCurDateTimeTo, vObj.ClientType, vCurRow.ServiceResource.Owner, vCurRow.ServiceResource, Catalogs.ServicePackages.EmptyRef(), , vObj.ResourceTariff);
				If ValueIsFilled(vObj.ClientType) And vPrices.Count() = 0 Then
					vPrices = cmGetResourcePrices(vObj.Hotel, vCurDateTimeFrom, vCurDateTimeTo, Catalogs.ClientTypes.EmptyRef(), vCurRow.ServiceResource.Owner, vCurRow.ServiceResource, Catalogs.ServicePackages.EmptyRef(), , vObj.ResourceTariff);
				EndIf;
				// Select service equal to the row service
				i = 0;
				For Each vPricesRow In vPrices Do
					If vPricesRow.Service <> vCurRow.Service Then
						Continue;
					EndIf;
					vWrkPrice = Round(cmConvertCurrencies(vPricesRow.Price, vPricesRow.Currency, , vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, ?(ValueIsFilled(vCurRow.AccountingDate), vCurRow.AccountingDate, vObj.ExchangeRateDate), vObj.Hotel), 2);
					vWrkDateTimeFrom = vPricesRow.DateTimeFrom;
					vWrkDateTimeTo = vPricesRow.DateTimeTo;
					// Calculate quantity
					vWrkQuantity = vPricesRow.Quantity;
					If vWrkQuantity = 0 Then
						If vWrkDateTimeFrom < vWrkDateTimeTo Then
							If EndOfDay(vWrkDateTimeTo) = vWrkDateTimeTo Then
								vWrkDateTimeTo = vWrkDateTimeTo + 1;
							EndIf;
							If vPricesRow.IsPricePerMinute Then
								vWrkQuantity = (vWrkDateTimeTo - cm0SecondShift(vWrkDateTimeFrom))/60;
							Else
								vWrkQuantity = (vWrkDateTimeTo - cm0SecondShift(vWrkDateTimeFrom))/3600;
							EndIf;
							// Check for free of charge quantity
							If vPricesRow.FreeOfChargeQuantity <> 0 Then
								If vWrkQuantity > vPricesRow.FreeOfChargeQuantity Then
									vWrkQuantity = vWrkQuantity - vPricesRow.FreeOfChargeQuantity;
								Else
									vWrkQuantity = 0;
								EndIf;
							EndIf;
							// Check for minimum quantity
							If vWrkQuantity < vPricesRow.MinimumQuantity Then
								vWrkQuantity = vPricesRow.MinimumQuantity;
							EndIf;
							// Check for maximum quantity
							If vWrkQuantity > vPricesRow.MaximumQuantity And vPricesRow.MaximumQuantity <> 0 Then
								vWrkQuantity = vPricesRow.MaximumQuantity;
							EndIf;
						EndIf;
					EndIf;
					// Take number of persons into account
					If vPricesRow.IsPricePerPerson Then
						vWrkQuantity = vWrkQuantity * ?(vCurRow.NumberOfPersons <> 0, vCurRow.NumberOfPersons, vObj.NumberOfPersons);
					EndIf;
					// Update service quantity
					If vWrkQuantity <> 0 Then
						vCurRow.Quantity = vWrkQuantity;
					EndIf;
					// Update service price
					If vWrkPrice <> 0 Then
						vCurPrice = vWrkPrice;
					EndIf;
					// Parameters
					If vPricesRow.IsResourceRevenue Then
						vCurRow.CalendarDayType = vPricesRow.CalendarDayType;
						vCurRow.Timetable = vPricesRow.Timetable;
						vCurRow.IsResourceRevenue = vPricesRow.IsResourceRevenue;
						vCurRow.IsPricePerMinute = vPricesRow.IsPricePerMinute;
						vCurRow.IsPricePerDay = vPricesRow.IsPricePerDay;
					EndIf;
				EndDo;
			EndIf;
			// Update service price
			If vCurPrice <> 0 Then
				vCurRow.Price = Round(cmConvertCurrencies(vCurPrice, vCurCurrency, , vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, ?(ValueIsFilled(vCurRow.AccountingDate), vCurRow.AccountingDate, vObj.ExchangeRateDate), vObj.Hotel), 2);
				vCurRow.BaseCurrencyPrice = Round(cmConvertCurrencies(vCurPrice, vCurCurrency, , vObj.Hotel.BaseCurrency, 1, ?(ValueIsFilled(vCurRow.AccountingDate), vCurRow.AccountingDate, vObj.ExchangeRateDate), vObj.Hotel), 2);
			EndIf;
			vCurRow.Unit = vCurUnit;
			vCurRow.VATRate = vCurVATRate;
			vCurRow.IsResourceRevenue = vCurRow.Service.IsResourceRevenue;
			cmPriceOnChange(vCurRow.Price, vCurRow.Quantity, vCurRow.Sum, vCurRow.VATRate, vCurRow.VATSum, vCurRow.AccountingDate);
			If ValueIsFilled(vObj.DiscountType) Or vObj.Discount <> 0 Then
				If cmIsServiceInServiceGroup(vCurRow.Service, vObj.DiscountServiceGroup) Then
					vCurRow.DiscountType = vObj.DiscountType;
					vCurRow.DiscountServiceGroup = vObj.DiscountServiceGroup;
					If vObj.DiscountType.IsAccumulatingDiscount Then
						CalculateAccumulationDiscountForAdditionalService(vObj, vCurRow);
					ElsIf vObj.DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
						vCurRow.Discount = vObj.DiscountType.GetObject().pmGetDiscount(vCurRow.AccountingDate, vCurRow.Service, vObj.Hotel);
					Else
						vCurRow.Discount = vObj.Discount;
					EndIf;
				EndIf;
			EndIf;
			vObj.pmCalculateServiceDiscounts(vCurRow);
			// Get complex commission
			vComplexCommission = vObj.pmGetComplexCommission();
			// Calculate service commissions
			vObj.pmSetServiceCommissions(vCurRow, vComplexCommission);
			If Not vCurRow.IsManual Then
				vCurRow.IsManualPrice = True;
			EndIf;
			// Calculate hours rented
			If vCurRow.IsResourceRevenue And ValueIsFilled(vCurRow.Service) Then
				If vCurRow.IsPricePerMinute Then
					vCurRow.HoursRented = vCurRow.Quantity/60;
				ElsIf vCurRow.IsPricePerDay Then
					If ValueIsFilled(vCurRow.ServiceResource) Then
						If vCurRow.ServiceResource.RoundTheClockOperation Then
							vCurRow.HoursRented = vCurRow.Quantity * 24;
						ElsIf vCurRow.ServiceResource.FullOccupancyHoursPerDay <> 0 Then
							vCurRow.HoursRented = vCurRow.Quantity * vCurRow.ServiceResource.FullOccupancyHoursPerDay;
						Else
							vCurRow.HoursRented = vCurRow.Quantity;
						EndIf;
					Else
						vCurRow.HoursRented = vCurRow.Quantity;
					EndIf;
				Else
					vCurRow.HoursRented = vCurRow.Quantity;
				EndIf;
			EndIf;
			// Fill service items
			If Not pDoNotRefreshServiceItems Then
				vItemsPrice = FillRowServiceItems(vCurRow, Object);
				If vItemsPrice <> 0 Then
					vCurRow.Price = vItemsPrice;
					vCurRow.BaseCurrencyPrice = Round(cmConvertCurrencies(vItemsPrice, vObj.FolioCurrency, , vObj.Hotel.BaseCurrency, 1, ?(ValueIsFilled(vCurRow.AccountingDate), vCurRow.AccountingDate, vObj.ExchangeRateDate), vObj.Hotel), 2);
					cmPriceOnChange(vCurRow.Price, vCurRow.Quantity, vCurRow.Sum, vCurRow.VATRate, vCurRow.VATSum, vCurRow.AccountingDate);
				EndIf;
			EndIf;
			// Apply filter 
			vFilter = New Structure();	
			vFilter.Insert("ServiceId", vCurRow.ServiceId);	
			Items.ServiceItems.RowFilter = New FixedStructure(vFilter);	
			// Check if user can edit service price
			Items.ServicesPrice.ReadOnly = False;
			If Not vCurRow.Service.AllowChangePrice Then
				If Not cmCheckUserPermissions("HavePermissionToEditServicePrices") Then
					Items.ServicesPrice.ReadOnly = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	CalculateTotalServices();
EndProcedure // ServicesServiceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesServiceOnChange(pItem)
	ServicesServiceOnChangeAtServer(CurrentItem.CurrentRow);
EndProcedure // ServicesServiceOnChange

// -----------------------------------------------------------------------------
&AtServer
Function FillRowServiceItems(pRow, pObj)
	vPrice = 0;
	If Not ValueIsFilled(pRow.Service) Then
		Return vPrice;
	EndIf;
	// Fill service composition
	If Not IsBlankString(pRow.Service.Composition) Then
		pRow.Remarks = TrimAll(pRow.Service.Composition);
	EndIf;
	// Fill service items
	If pRow.Service.ServiceItems.Count() > 0 Then
		If Not IsBlankString(pRow.ServiceId) Then
			// Delete current service items
			i = 0;
			While i < pObj.ServiceItems.Count() Do
				vSIRow = pObj.ServiceItems.Get(i);
				If vSIRow.ServiceId = pRow.ServiceId Then
					pObj.ServiceItems.Delete(i);
				Else
					i = i + 1;
				EndIf;
			EndDo;
			// Add service items from the service
			For Each vSIRow In pRow.Service.ServiceItems Do
				vRow = pObj.ServiceItems.Add();
				vRow.ServiceId = pRow.ServiceId;
				FillPropertyValues(vRow, vSIRow);
				vRow.Price = Round(cmConvertCurrencies(vRow.Price, ?(ValueIsFilled(vRow.Currency), vRow.Currency, pObj.FolioCurrency), , 
													   pObj.FolioCurrency, 
													   pObj.FolioCurrencyExchangeRate, 
													   ?(ValueIsFilled(pRow.AccountingDate), pRow.AccountingDate, pObj.ExchangeRateDate), pObj.Hotel), 2);
				vRow.Sum = Round(vRow.Price * vRow.Quantity, 2);
				vRow.CostSum = Round(vRow.CostPrice * vRow.Quantity, 2);
				vRow.Currency = pObj.FolioCurrency;
				vRow.BaseCurrencyPrice = Round(cmConvertCurrencies(vSIRow.Price, ?(ValueIsFilled(vSIRow.Currency), vSIRow.Currency, pObj.Hotel.BaseCurrency), , 
													   pObj.Hotel.BaseCurrency, 
													   1, 
													   ?(ValueIsFilled(pRow.AccountingDate), pRow.AccountingDate, pObj.ExchangeRateDate), pObj.Hotel), 2);
				vPrice = vPrice + vRow.Sum;
			EndDo;
		EndIf;
	EndIf;
	Return vPrice;
EndFunction // FillRowServiceItems

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesQuantityOnChangeAtServer(pRowID)
	If pRowID <> Undefined Then
		vCurSrv = Object.Services.FindByID(pRowID);
		If vCurSrv <> Undefined Then
			vObj = FormAttributeToValue("Object");
			cmQuantityOnChange(vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, vCurSrv.AccountingDate);
			If vCurSrv.IsResourceRevenue And ValueIsFilled(vCurSrv.Service) Then
				If vCurSrv.IsPricePerMinute Then
					vCurSrv.HoursRented = vCurSrv.Quantity/60;
				ElsIf vCurSrv.IsPricePerDay Then
					If ValueIsFilled(vCurSrv.ServiceResource) Then
						If vCurSrv.ServiceResource.RoundTheClockOperation Then
							vCurSrv.HoursRented = vCurSrv.Quantity * 24;
						ElsIf vCurSrv.ServiceResource.FullOccupancyHoursPerDay <> 0 Then
							vCurSrv.HoursRented = vCurSrv.Quantity * vCurSrv.ServiceResource.FullOccupancyHoursPerDay;
						Else
							vCurSrv.HoursRented = vCurSrv.Quantity;
						EndIf;
					Else
						vCurSrv.HoursRented = vCurSrv.Quantity;
					EndIf;
				Else
					vCurSrv.HoursRented = vCurSrv.Quantity;
				EndIf;
			EndIf;
			vCurSrv.BaseCurrencyPrice = Round(cmConvertCurrencies(vCurSrv.Price, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, vObj.Hotel.BaseCurrency, 1, ?(ValueIsFilled(vCurSrv.AccountingDate), vCurSrv.AccountingDate, vObj.ExchangeRateDate), vObj.Hotel), 2);
			vObj.pmCalculateServiceDiscounts(vCurSrv);
			vObj.pmCalculateServiceCommissions(vCurSrv);
			If Not vCurSrv.IsManual Then
				vCurSrv.IsManualPrice = True;
			EndIf;
			vCurSrv.SumWithDiscount = vCurSrv.Sum - vCurSrv.DiscountSum;
		EndIf;
		CalculateTotalServices();
	EndIf;
EndProcedure // ServicesQuantityOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesQuantityOnChange(pItem)
	ServicesQuantityOnChangeAtServer(CurService);
EndProcedure // ServicesQuantityOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesServiceResourceOnChangeAtServer(pRowID)
	If pRowID <> Undefined Then
		vCurRow = Object.Services.FindByID(pRowID);
		If vCurRow <> Undefined Then
			If ValueIsFilled(vCurRow.ServiceResource) And TypeOf(vCurRow.ServiceResource) = Type("CatalogRef.Resources") Then
				If vCurRow <> Undefined Then
					If Not ValueIsFilled(vCurRow.TimeFrom) And Not ValueIsFilled(vCurRow.TimeTo) Then
						vResourceObj = vCurRow.ServiceResource.GetObject();
						vDefaultTimes = vResourceObj.pmGetResourceDefaultChargingTimes(vCurRow.AccountingDate);
						vCurRow.TimeFrom = vDefaultTimes.TimeFrom;
						vCurRow.TimeTo = vDefaultTimes.TimeTo;
					EndIf;
					vCurRow.DoResourceReservation = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ServicesServiceResourceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesServiceResourceOnChange(pItem)
	ServicesServiceResourceOnChangeAtServer(CurrentItem.CurrentRow);
	ServicesServiceOnChangeAtServer(CurrentItem.CurrentRow, True);
EndProcedure // ServicesServiceResourceOnChange

// -----------------------------------------------------------------------------
&AtServer
Function WriteAtServer(pCurrentObject = Undefined, rWarning = "", pDoNotCloseMode = False) Export
	vMessage = "";
	// Check paramters
	vUseParametrObject = True;
	vCurrObj = pCurrentObject;
	// Get object value
	If pCurrentObject = Undefined Then
		Try
			vCurrObj = FormAttributeToValue("Object");
		Except
			Return NStr("ru='Ошибка захвата объекта! Документ сохранен не будет!';en='Transaction error! The document will not be saved!';de='Transaction error! The document will not be saved!'");
		EndTry;
		vUseParametrObject = False;
	EndIf;
	vIsResourceBlock = False;
	If ValueIsFilled(vCurrObj.EventActivity) And TypeOf(vCurrObj.EventActivity) = Type("CatalogRef.EventActivities") Then
		vIsResourceBlock = vCurrObj.EventActivity.IsResourceBlock;
	EndIf;
	// Check guarantee type
	If Not vIsResourceBlock And ValueIsFilled(vCurrObj.ResourceReservationStatus) And vCurrObj.ResourceReservationStatus.IsGuaranteed Then
		If Not ValueIsFilled(vCurrObj.GuaranteeType) And cmGetGuaranteeTypesCount() > 0 Then
			Return NStr("ru='Не указан вид гарантии!';en='Guarantee type should be filled!';de='Art der Garantie sollte ausgefüllt werden!'");
		EndIf;
	EndIf;
	// Begin transaction
	Try
		// Posting
		vCurrObj.AdditionalProperties.Insert("DoNotCloseMode", pDoNotCloseMode);
		vCurrObj.Write(DocumentWriteMode.Posting);
		vCurrObj.Read();
		// Save data to the document history
		vCurrObj.pmWriteToResourceReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		UserWorkHistory.Add(vCurrObj.Ref);
	Except
		vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
		If IsBlankString(vErrorDescription) Then
			vErrorDescription = "Error";
		EndIf;
		Return vErrorDescription;
	EndTry;
	// Form modification	
	If ThisForm.Modified Then
		ThisForm.Modified = False;
	EndIf;
	If Not vUseParametrObject Then
		// Set object value
		ValueToFormAttribute(vCurrObj, "Object");
	EndIf;
	// Hotel365
	vFrmAction = Catalogs.ObjectFormActions.ResourceReservationSendMyFolioSMS;
	If Not WasPosted And vFrmAction.IsActive And vFrmAction.AutomaticallyRunOnFirstObjectWrite And vFrmAction.ObjectType = Documents.ResourceReservation.EmptyRef() Then
		rWarning = SendWelcomeSMSAtServer();
	EndIf;
	// Was posted
	WasPosted = True;
	// Return
	Return "";
EndFunction // WriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	If pExit Then
	   Return;
	EndIf; 
	If IsInBeforeCloseEvent Then
		Return;
	EndIf;
	IsInBeforeCloseEvent = True;
	If ThisForm.ReadOnly Then
		ThisForm.Modified = False;
	EndIf;
	If ThisForm.Modified Then
		pCancel = True;
		vNotifity = New NotifyDescription("AfterAnswering", ThisForm, pCancel);
		ShowQueryBox(vNotifity, NStr("en='Data was changed! Save the changes?'; ru='Данные были изменены! Сохранить изменения?'; de='Die Daten wurden geändert! Änderungen speichern?'"), QuestionDialogMode.YesNoCancel);
	Else
		AfterAnswering(Undefined, pCancel);
		IsInBeforeCloseEvent = False;
	EndIf;
EndProcedure // BeforeClose

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterAnswering(pAnswer, pCancel) Export
	pCancel = False;
	vCancel = Undefined;
	If Not pAnswer = Undefined Then
		If pAnswer = DialogReturnCode.Yes Then
			// Check user PIN if necessary
			If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
				OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "AfterAnswering"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
				pCancel = True;
				Return;
			EndIf;
			EmployeePINCodeChecked = False;
			// Do processing
			vWarning = "";
			vResult = WriteAtServer(, vWarning, True);
			If Not IsBlankString(vWarning) Then
				tcCommonFunctionOnClientServer.TextMessage(vWarning);
			EndIf;		
			If ValueIsFilled(vResult) Then
				If vResult <> "Error" Then
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
				Else
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Documents posting error!';ru='Ошибка проводки документа!';de='Fehler bei der Durchführung des Dokuments!'"));
				EndIf;
				pCancel = True;
				IsInBeforeCloseEvent = False;
				Return;
			Else
				// Notify changes
				IsOnCloseForm = True;
				If Object.DoCharging Then
					Notify("Subsystem.Accounts.Changed", Object.Ref);
				EndIf;
				Notify("Document.ResourceReservation.Write", Object.Ref, ThisForm);
			EndIf;
		ElsIf pAnswer = DialogReturnCode.No Then
			vCancel = BeforeCloseAtServer(); 
		ElsIf pAnswer = DialogReturnCode.Cancel Then
			pCancel = True;
			IsInBeforeCloseEvent = False;
			Return;
		EndIf;
	Else
		vCancel = BeforeCloseAtServer(); 
	EndIf;
	If vCancel <> "Error" And vCancel <> "LockError" Then
		ThisForm.Modified = False;
		If vCancel <> Undefined Then
			If vCancel Then
				pCancel = True;
				// Inform user that he can not close document without save
				ShowMessageBox(Undefined, NStr("en='You do not have rights to close new reservations without save! Please choose reservation status with refusal reason and save document.'; ru='Нет прав на отказ от сохранения новой брони! Пожалуйста выберите статус брони указывающий причину отказа и сохраните документ.'; de='Sie haben keine Rechte, die Speicherung einer neuen Reservierung abzulehnen! Bitte wählen Sie den Reservierungsstatus aus, welcher den Grund für die Ablehnung anzeigt, und speichern Sie das Dokument!'"));
				// Go to the reservation status
				ThisForm.CurrentItem = Items.ResourceReservationStatus;
			ElsIf Not vCancel And Not WasAlreadyPrint And WasPosted And WasNew Then
				WasAlreadyPrint = True;
				vPrintFormsList = PerformAutomaticPrinting();
				For Each vFormType In vPrintFormsList Do
					vExternalProcessing = Undefined;
					If ValueIsFilled(vFormType.Value) Then
						vExternalProcessing = tcOnServer.cmGetAttributeByRef(vFormType.Value, "ExternalProcessing");
					EndIf;
					If ValueIsFilled(vExternalProcessing) Then
						Try
							OpenExternalProcedureForm(vExternalProcessing, vFormType.Value);
						Except
							tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
							vExternalProcessing = Undefined;
						EndTry;
						Continue;
					EndIf;
					If ValueIsFilled(vFormType.Presentation) Then
						If vFormType.Presentation = "PrintConfirmationRU" Or 
						   vFormType.Presentation = "PrintConfirmationDE" Or
						   vFormType.Presentation = "PrintConfirmationEN" Then
							OpenConfirmationPrintingForm(vFormType, False);
						ElsIf vFormType.Presentation = "PrintConfirmationByDaysRU" Or
							  vFormType.Presentation = "PrintConfirmationByDaysDE" Or
							  vFormType.Presentation = "PrintConfirmationByDaysEN" Then
							OpenConfirmationPrintingForm(vFormType, True);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		If pAnswer <> Undefined Then
			ThisForm.Close();
		EndIf;
	Else
		If vCancel <> "LockError" Then
			pCancel = True;
		EndIf;
	EndIf;
	If Not pCancel Then
		WasNew = False;
	EndIf;
	IsInBeforeCloseEvent = False;
EndProcedure // AfterAnswering

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenConfirmationPrintingForm(pPrintingFormItem, pByDays = False)
	vFrm = GetForm("Document.ResourceReservation.Form.tcReservationConfirmationForm", , New UUID());
	vFrm.FormOwner = ThisForm;
	vFrm.CloseOnOwnerClose = False;
	vFrm.SelReservation = Object.Ref;
	CopyFormData(Object, vFrm.SelReservationObj);
	vFrm.SelByDays = pByDays;
	vFrm.SelLanguage = tcOnServer.cmGetCatalogItemRefByCode("Languages", Right(pPrintingFormItem.Presentation, 2));
	vFrm.SelObjectPrintForm = pPrintingFormItem.Value;
	vFrm.Open();
EndProcedure // OpenConfirmationPrintingForm

// -----------------------------------------------------------------------------
&AtServer
Function BeforeCloseAtServer()
	vCancel = Undefined;
	Try
		vObj = FormAttributeToValue("Object");
	Except
		Return "LockError";
	EndTry; 
	If WasNew Then
		If Not WasPosted Then
			If Not cmCheckUserPermissions("HavePermissionToCloseNewReservationWithoutSave") Then
				vCancel = True;
				Return vCancel;
			Else
				// Delete folio used by this document
				If vCancel = Undefined Then
					// If folio left in the list do not have any transactions based on it then delete it
					vObj.pmDeleteUnusedChargingFolio();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	vCancel = False;
	// Return
	Return vCancel;
EndFunction // BeforeCloseAtServer

// -----------------------------------------------------------------------------
&AtServer
Function PerformAutomaticPrinting()
	vDocObj = FormAttributeToValue("Object");
	vPrintFormsList = New ValueList;
	// Get language
	vLanguage = vDocObj.pmGetDocumentLanguage();
	// Get list of automatic print froms for this object type
	vForms = cmGetObjectPrintingForms(Documents.ResourceReservation.EmptyRef(), vLanguage);
	vAutoForms = vForms.FindRows(New Structure("AutomaticallyPrintOnFirstObjectWrite", True));
	// Call object print forms handler for each form
	For Each vAutoForm In vAutoForms Do
		If Not ValueIsFilled(vLanguage) And ValueIsFilled(vAutoForm.ObjectPrintingForm) And ValueIsFilled(vAutoForm.ObjectPrintingForm.Language) Then
			Continue;
		EndIf;
		vTypeOfPrintForm = GetTypeOfPrintFormOnClose(vAutoForm.ObjectPrintingForm, vDocObj);
		vPrintFormsList.Add(vAutoForm.ObjectPrintingForm, vTypeOfPrintForm);
	EndDo;
	// Return
	Return vPrintFormsList;
EndFunction // PerformAutomaticPrinting

// -----------------------------------------------------------------------------
&AtServer
Function GetTypeOfPrintFormOnClose(pForm, pDocObj = Undefined)
	vTypeOfPrintForm = "";
	// Check predefined forms
	If pForm = Catalogs.ObjectPrintingForms.ResourceReservationPrintConfirmationRu Then
		vTypeOfPrintForm = "PrintConfirmationRU";
	ElsIf pForm = Catalogs.ObjectPrintingForms.ResourceReservationPrintConfirmationEn Then
		vTypeOfPrintForm = "PrintConfirmationEN";
	ElsIf pForm = Catalogs.ObjectPrintingForms.ResourceReservationPrintConfirmationByDaysRu Then
		vTypeOfPrintForm = "PrintConfirmationByDaysRU";
	ElsIf pForm = Catalogs.ObjectPrintingForms.ResourceReservationPrintConfirmationByDaysEn Then
		vTypeOfPrintForm = "PrintConfirmationByDaysEN";
	Else        
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='No print form processor found!';ru='В настройках печатной формы не задан обработчик!';de='In den Einstellungen der Druckunterlagen wurde kein Bearbeiter vorgegeben!'"));
	EndIf;
	Return vTypeOfPrintForm;
EndFunction // GetTypeOfPrintFormOnClose

// -----------------------------------------------------------------------------
&AtClient
Procedure PayerOnChange(pItem)
	vIsNeedToOpenForm = PayerOnChangeAtServer();
	If vIsNeedToOpenForm Then
		If Payer = PredefinedValue("Enum.WhoPaysInResourceReservation.Agent") Then
			vFrm = GetForm("Catalog.Customers.ChoiceForm", New Structure("CurrentRow, ChoiceMode", Object.Agent, True), Items.Agent);
			vFrm.CloseOnOwnerClose = True;
			vFrm.CloseOnChoice = True;
			vFrm.Open();
		Else
			vFrm = GetForm("Catalog.Customers.ChoiceForm", New Structure("CurrentRow, ChoiceMode", Object.Customer, True), Items.Customer);
			vFrm.CloseOnOwnerClose = True;
			vFrm.CloseOnChoice = True;
			vFrm.Open();
		EndIf;
	EndIf;
	ThisForm.Modified = True;
EndProcedure // PayerOnChange

// -----------------------------------------------------------------------------
&AtServer
Function PayerOnChangeAtServer(pObj = Undefined)
	vNeedToChooseCustomer = False;
	vObj = pObj;
	If vObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If Payer = Enums.WhoPaysInResourceReservation.Client Then
		Items.Owner.Visible = False;
		If ValueIsFilled(vObj.Hotel) Then
			If ValueIsFilled(vObj.Hotel.IndividualsContract) Then
				vObj.Owner = vObj.Hotel.IndividualsContract;
			Else
				vObj.Owner = vObj.Hotel.IndividualsCustomer;
			EndIf;
			If ValueIsFilled(vObj.Owner) And ValueIsFilled(vObj.Owner.PlannedPaymentMethod) Then
				vObj.PlannedPaymentMethod = vObj.Owner.PlannedPaymentMethod;
			Else
				vObj.PlannedPaymentMethod = vObj.Hotel.PlannedPaymentMethod;
			EndIf;
		EndIf;
		BuildAccountingGroupCollapsedTitle(vObj);
		BuildDiscountsGroupCollapsedTitle(vObj);
	ElsIf Payer = Enums.WhoPaysInResourceReservation.Customer Then
		Items.Owner.Visible = True;
		If ValueIsFilled(vObj.Customer) Then
			If ValueIsFilled(vObj.Contract) Then
				vObj.Owner = vObj.Contract;
			Else
				vObj.Owner = vObj.Customer;
			EndIf;
			If ValueIsFilled(vObj.Owner) And ValueIsFilled(vObj.Owner.PlannedPaymentMethod) Then
				vObj.PlannedPaymentMethod = vObj.Owner.PlannedPaymentMethod;
			Else
				vObj.PlannedPaymentMethod = vObj.Hotel.PaymentMethodForCustomerPayments;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vObj.Customer) Then
			BuildAccountingGroupCollapsedTitle(vObj);
			BuildDiscountsGroupCollapsedTitle(vObj);
			vNeedToChooseCustomer = True;
		Else
			BuildAccountingGroupCollapsedTitle(vObj);
			BuildDiscountsGroupCollapsedTitle(vObj);
			vNeedToChooseCustomer = False;
		EndIf;
	ElsIf Payer = Enums.WhoPaysInResourceReservation.Agent Then
		Items.Owner.Visible = True;
		If ValueIsFilled(vObj.Agent) Then
			vObj.Owner = vObj.Agent;
			If ValueIsFilled(vObj.Owner) And ValueIsFilled(vObj.Owner.PlannedPaymentMethod) Then
				vObj.PlannedPaymentMethod = vObj.Owner.PlannedPaymentMethod;
			Else
				vObj.PlannedPaymentMethod = vObj.Hotel.PaymentMethodForCustomerPayments;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vObj.Agent) Then
			BuildAccountingGroupCollapsedTitle(vObj);
			BuildDiscountsGroupCollapsedTitle(vObj);
			vNeedToChooseCustomer = True;
		Else
			BuildAccountingGroupCollapsedTitle(vObj);
			BuildDiscountsGroupCollapsedTitle(vObj);
			vNeedToChooseCustomer = False;
		EndIf;
	ElsIf Payer = Enums.WhoPaysInResourceReservation.Other Then
		Items.Owner.Visible = True;
		BuildAccountingGroupCollapsedTitle(vObj);
		BuildDiscountsGroupCollapsedTitle(vObj);
		vNeedToChooseCustomer = False;
	EndIf;
	vObj.pmCalculateServices();
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
	Return vNeedToChooseCustomer;
EndFunction // PayerOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildAccountingGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	// Get payer
	CalculatePayerAtServer(vObj);
	// Get caption
	vTitle = NStr("en='Accounting: '; ru='Взаиморасчеты: '; de='Buchhaltung: '") + 
	         NStr("en='pays: '; ru='платит: '; de='Zahler: '") + TrimAll(Payer) + 
			 ?(Payer = Enums.WhoPaysInResourceReservation.Customer, " " + TrimAll(vObj.Customer) + ?(ValueIsFilled(vObj.Contract), ", " + TrimAll(vObj.Contract), ""), ?(Payer = Enums.WhoPaysInResourceReservation.Agent, " " + TrimAll(vObj.Agent), "")) + 
	         NStr("en=' by '; ru=', '; de=', '") + TrimAll(vObj.PlannedPaymentMethod) + 
	         NStr("en=' to '; ru=' фирме: '; de=' an '") + TrimAll(vObj.Company) + 
			 ?(IsBlankString(TServicePackagesPresentation), "", ", " + TrimAll(TServicePackagesPresentation));
	Items.GroupAccounting.CollapsedRepresentationTitle = vTitle;
	If Payer = Enums.WhoPaysInResourceReservation.Customer Or Payer = Enums.WhoPaysInResourceReservation.Agent Then
		Items.DecorationGuestPays.Visible = False;
		Items.DecorationCustomerPays.Visible = True;
		Items.DecorationChargingRules.Visible = False;
	ElsIf Payer = Enums.WhoPaysInResourceReservation.Client Then 
		Items.DecorationGuestPays.Visible = False;
		Items.DecorationCustomerPays.Visible = False;
		Items.DecorationChargingRules.Visible = False;
	Else
		Items.DecorationGuestPays.Visible = False;
		Items.DecorationCustomerPays.Visible = False;
		Items.DecorationChargingRules.Visible = True;
	EndIf;
EndProcedure // BuildAccountingGroupCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildDiscountsGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	vTitle = NStr("en='Discount: '; ru='Скидка: '; de='Rabatt: '");
	If vObj.Discount <> 0 Or ValueIsFilled(vObj.DiscountType) Then
		vTitle = vTitle + TrimAll(vObj.Discount) + ?(ValueIsFilled(vObj.DiscountType), ?(vObj.DiscountType.IsAmountDiscount, " - ", "% - ") + TrimAll(vObj.DiscountType), "%");
	EndIf;
	If ValueIsFilled(vObj.DiscountCard) Then
		vTitle = vTitle + ?(IsBlankString(vTitle), "", ", ") + NStr("en='card: '; ru='карта: '; de='Karte: '") + TrimAll(vObj.DiscountCard);
	EndIf;
	If ValueIsFilled(vObj.DiscountServiceGroup) Then
		vTitle = vTitle + ?(IsBlankString(vTitle), "", ", ") + NStr("en='for services: '; ru='для услуг: '; de='für die Dienstleistungen: '") + TrimAll(vObj.DiscountServiceGroup);
	EndIf;
	Items.GroupDiscounts.CollapsedRepresentationTitle = vTitle;
EndProcedure // BuildDiscountsGroupCollapsedTitle

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure BuildCommissionGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If vObj.Agent.IsEmpty() Then
		Items.GroupAgentCommission.CollapsedRepresentationTitle = NStr("en='Agent: ';ru='Агент: ';de='Vertreter: '") + ?(ValueIsFilled(vObj.Agent), TrimAll(vObj.Agent), NStr("en='<empty>';ru='<пусто>';de='<leer>'"));
	Else
		vAgentCommissionPresentation = TrimAll(vObj.AgentCommission);
		If ValueIsFilled(vObj.Agent) Then
			If vObj.AgentCommissionType = PredefinedValue("Enum.AgentCommissionTypes.Percent") Then
				vAgentCommissionPresentation = TrimAll(vObj.AgentCommission) + NStr("en='%';ru='%';de='%'");
			ElsIf vObj.AgentCommissionType = PredefinedValue("Enum.AgentCommissionTypes.FirstDayPercent") Then
				vAgentCommissionPresentation = TrimAll(vObj.AgentCommission) + NStr("en='% for the 1-st day';ru='% за 1-ый день';de='% für den ersten Tag'");
			ElsIf vObj.AgentCommissionType = PredefinedValue("Enum.AgentCommissionTypes.AmountPerCheckInPerClient") Then
				vAgentCommissionPresentation = cmFormatSum(vObj.AgentCommission, vObj.Agent.AccountingCurrency) + NStr("en=' per guest per check-in';ru=' за гостя за заезд';de=' pro Gast pro Check-in'");
			ElsIf vObj.AgentCommissionType = PredefinedValue("Enum.AgentCommissionTypes.AmountPerCheckInPerRoom") Then
				vAgentCommissionPresentation = cmFormatSum(vObj.AgentCommission, vObj.Agent.AccountingCurrency) + NStr("en=' per room per check-in';ru=' за номер за заезд';de=' pro Zimmer pro Check-in'");
			ElsIf vObj.AgentCommissionType = PredefinedValue("Enum.AgentCommissionTypes.AmountPerDayPerClient") Then
				vAgentCommissionPresentation = cmFormatSum(vObj.AgentCommission, vObj.Agent.AccountingCurrency) + NStr("en=' per guest per night';ru=' за гостя за ночь';de=' pro Gast pro Nacht'");
			ElsIf vObj.AgentCommissionType = PredefinedValue("Enum.AgentCommissionTypes.AmountPerDayPerRoom") Then
				vAgentCommissionPresentation = cmFormatSum(vObj.AgentCommission, vObj.Agent.AccountingCurrency) + NStr("en=' per room per night';ru=' за номер за ночь';de=' pro Zimmer pro Nacht'");
			EndIf;
		EndIf;
		Items.GroupAgentCommission.CollapsedRepresentationTitle = NStr("en='Agent: ';ru='Агент: ';de='Vertreter: '") + ?(ValueIsFilled(vObj.Agent), TrimAll(vObj.Agent), NStr("en='<empty>';ru='<пусто>';de='<leer>'")) + 
		                                                          " • " + NStr("en='Commission ';ru='Комиссия ';de='Kommission '") + ?(ValueIsFilled(vObj.AgentCommission), vAgentCommissionPresentation, NStr("en='<empty>';ru='<пусто>';de='<leer>'")) + 
		                                                          NStr("en=' for ';ru=' за ';de=' für '") + ?(ValueIsFilled(vObj.AgentCommissionServiceGroup), TrimAll(vObj.AgentCommissionServiceGroup), NStr("en='all services';ru='все услуги';de='alle Dienstleistungen'"));
	EndIf;
EndProcedure // BuildCommissionGroupCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildPropertiesGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	Items.GroupProperties.CollapsedRepresentationTitle = NStr("en='Client type: ';ru='Тип клиента: ';de='Kundentyp: '") + ?(ValueIsFilled(vObj.ClientType), TrimAll(vObj.ClientType), NStr("en='<Empty client type>';ru='<Пустой тип клиента>';de='<Leerer Kundentyp>'")) + 
	                                                     " • " + NStr("en='Tariff: ';ru='Тариф: ';de='Tarif: '") + ?(ValueIsFilled(vObj.ResourceTarif), TrimAll(vObj.ResourceTarif), NStr("en='<Default tariff>';ru='<Тариф по умолчанию>';de='<Standardtarif>'"));
EndProcedure // BuildPropertiesGroupCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildContactsGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	Items.GroupContacts.CollapsedRepresentationTitle = NStr("en='Client: ';ru='Клиент: ';de='Kunde: '") + ?(ValueIsFilled(vObj.Client), TrimAll(vObj.Client.FullName), "") + 
	                                                   ?(IsBlankString(vObj.Phone), "", ", " + TrimAll(vObj.Phone)) + 
	                                                   ?(IsBlankString(vObj.Fax), "", ", " + TrimAll(vObj.Fax)) + 
													   ?(IsBlankString(vObj.EMail), "", ", " + TrimAll(vObj.EMail)) + 
	                                                   ?(IsBlankString(vObj.ContactPerson), "", NStr("en=', Contact: ';ru=', Контакт: ';de=', Kontakt: '") + TrimAll(vObj.ContactPerson));
EndProcedure // BuildPropertiesGroupCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildRemarksGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	Items.GroupRemarks.CollapsedRepresentationTitle = NStr("en='Remarks: '; ru='Примечания: '; de='Bemerkungen: '") + TrimAll(vObj.Remarks);
EndProcedure // BuildRemarksGroupCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure PlannedPaymentMethodOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmCalculateServices();
	BuildAccountingGroupCollapsedTitle(vObj);
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
EndProcedure // PlannedPaymentMethodOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure PlannedPaymentMethodOnChange(pItem)
	PlannedPaymentMethodOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CustomerOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If ValueIsFilled(vObj.Customer) Then
		// Reset contract
		If ValueIsFilled(vObj.Contract) Then
			If vObj.Contract.Owner <> vObj.Customer Then
				vObj.Contract = Catalogs.Contracts.EmptyRef();
			EndIf;
		EndIf;
		// Customer type
		vObj.CustomerType = vObj.Customer.CustomerType;
		// Contact person
		vObj.ContactPerson = "";
		If Not IsBlankString(vObj.Customer.ContactPerson) Then
			vObj.ContactPerson = TrimR(vObj.Customer.ContactPerson);
		EndIf;
		// Planned payment method
		If Not ValueIsFilled(vObj.ParentDoc) Then
			If ValueIsFilled(vObj.Customer.PlannedPaymentMethod) Then
				vObj.PlannedPaymentMethod = vObj.Customer.PlannedPaymentMethod;
				If Not ValueIsFilled(vObj.Contract) And ValueIsFilled(vObj.PlannedPaymentMethod) And vObj.PlannedPaymentMethod.IsByBankTransfer Then
					vObj.Owner = vObj.Customer;
				EndIf;
			EndIf;
		EndIf;
		// Agent
		vObj.Agent = vObj.Customer.Agent;
		If ValueIsFilled(vObj.Customer.AgentCommissionType) Then
			If Not ValueIsFilled(vObj.Agent) Then
				vObj.Agent = vObj.Customer;
			EndIf;
			vObj.AgentCommission = vObj.Agent.AgentCommission;
			vObj.AgentCommissionType = vObj.Agent.AgentCommissionType;
			vObj.AgentCommissionServiceGroup = vObj.Agent.AgentCommissionServiceGroup;
		EndIf;
		// Contract
		If Not ValueIsFilled(vObj.Contract) And ValueIsFilled(vObj.Customer.Contract) Then
			vObj.Contract = vObj.Customer.Contract;
			ContractOnChangeAtServer(vObj);
		Else
			// Marketing code
			If ValueIsFilled(vObj.Customer.MarketingCode) Then
				vObj.MarketingCode = vObj.Customer.MarketingCode;
				vObj.MarketingCodeConfirmationText = "";
			EndIf;
			// Source of business
			If ValueIsFilled(vObj.Customer.SourceOfBusiness) Then
				vObj.SourceOfBusiness = vObj.Customer.SourceOfBusiness;
			EndIf;
			// Client type
			If ValueIsFilled(vObj.Customer.ClientType) And (Not ValueIsFilled(vObj.Customer.ClientType.Hotel) Or vObj.Customer.ClientType.Hotel = vObj.Hotel) Then
				vObj.ClientType = vObj.Customer.ClientType;
				vObj.ClientTypeConfirmationText = vObj.Customer.ClientTypeConfirmationText;
			EndIf;
		EndIf;
	Else
		// Contact person
		vObj.ContactPerson = "";
		// Contract
		vObj.Contract = Catalogs.Contracts.EmptyRef();
		// Reset planned payment method and owner
		If ValueIsFilled(vObj.Hotel) Then
			If ValueIsFilled(vObj.Hotel.IndividualsContract) Then
				vObj.Owner = vObj.Hotel.IndividualsContract;
			Else
				vObj.Owner = vObj.Hotel.IndividualsCustomer;
			EndIf;
			If ValueIsFilled(vObj.Owner) And ValueIsFilled(vObj.Owner.PlannedPaymentMethod) Then
				vObj.PlannedPaymentMethod = vObj.Owner.PlannedPaymentMethod;
			Else
				vObj.PlannedPaymentMethod = vObj.Hotel.PlannedPaymentMethod;
			EndIf;
		EndIf;
	EndIf;
	// Load customer contact persons list
	LoadCustomerContactPersonsList(vObj);
	// Fill discount type and other discount parameters if filled
	vObj.pmSetDiscounts();
	// Automatic services list calculation	
	vWarnings = "";
	If vObj.pmCalculateServices(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr(vWarnings));
	EndIf;
	// Build collapsed groups title
	BuildAccountingGroupCollapsedTitle(vObj);
	BuildDiscountsGroupCollapsedTitle(vObj);
	BuildCommissionGroupCollapsedTitle(vObj);
	BuildPropertiesGroupCollapsedTitle(vObj);
	// Put object back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // CustomerOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerOnChange(pItem)
	CustomerOnChangeAtServer();
EndProcedure // CustomerOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ContractOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If ValueIsFilled(vObj.Contract) Then
		vContract = vObj.Contract;
		// Planned payment method
		If Not ValueIsFilled(vObj.ParentDoc) Then
			If ValueIsFilled(vContract.PlannedPaymentMethod) Then
				vObj.PlannedPaymentMethod = vContract.PlannedPaymentMethod;
				If ValueIsFilled(vObj.PlannedPaymentMethod) And vObj.PlannedPaymentMethod.IsByBankTransfer Then
					vObj.Owner = vContract;
				EndIf;
			EndIf;
		EndIf;
		// Agent commission
		If Not vContract.IsSubagent Then
			vObj.Agent = vContract.Agent;
			If ValueIsFilled(vObj.Customer) And ValueIsFilled(vContract.AgentCommissionType) Then
				If Not ValueIsFilled(vObj.Agent) Then
					vObj.Agent = vObj.Customer;
				EndIf;
				vObj.AgentCommission = vContract.AgentCommission;
				vObj.AgentCommissionType = vContract.AgentCommissionType;
				vObj.AgentCommissionServiceGroup = vContract.AgentCommissionServiceGroup;
			EndIf;
		EndIf;
		// Contract company
		If ValueIsFilled(vContract.Company) Then
			vObj.Company = vContract.Company;
		EndIf;
		// Marketing code
		If ValueIsFilled(vContract.MarketingCode) Then
			vObj.MarketingCode = vContract.MarketingCode;
			vObj.MarketingCodeConfirmationText = "";
		EndIf;
		// Source of business
		If ValueIsFilled(vContract.SourceOfBusiness) Then
			vObj.SourceOfBusiness = vContract.SourceOfBusiness;
		EndIf;
		// Client type
		If ValueIsFilled(vContract.ClientType) And (Not ValueIsFilled(vContract.ClientType.Hotel) Or vContract.ClientType.Hotel = vObj.Hotel) Then
			vObj.ClientType = vContract.ClientType;
			vObj.ClientTypeConfirmationText = vContract.ClientTypeConfirmationText;
		EndIf;
	Else
		If ValueIsFilled(vObj.Agent) And Payer = Enums.WhoPaysInResourceReservation.Agent Then
			vObj.Owner = vObj.Agent;
		ElsIf ValueIsFilled(vObj.Customer) And Payer = Enums.WhoPaysInResourceReservation.Customer Then
			vObj.Owner = vObj.Customer;
		EndIf;
	EndIf;
	// Load customer contact persons list
	LoadCustomerContactPersonsList(vObj);
	// Fill discount type and other discount parameters if filled
	vObj.pmSetDiscounts();
	// Automatic services list calculation	
	vWarnings = "";
	If vObj.pmCalculateServices(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr(vWarnings));
	EndIf;
	// Build collapsed groups title
	BuildAccountingGroupCollapsedTitle(vObj);
	BuildDiscountsGroupCollapsedTitle(vObj);
	BuildCommissionGroupCollapsedTitle(vObj);
	BuildPropertiesGroupCollapsedTitle(vObj);
	// Put object back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // ContractOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ContractOnChange(pItem)
	ContractOnChangeAtServer();
EndProcedure // ContractOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CompanyOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmCalculateServices();
	BuildAccountingGroupCollapsedTitle(vObj);
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
EndProcedure // CompanyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	CompanyOnChangeAtServer();
EndProcedure // CompanyOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ClientOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If ValueIsFilled(vObj.Client) Then
		// Marketing code
		If ValueIsFilled(vObj.Client.MarketingCode) Then
			If vObj.MarketingCode <> vObj.Client.MarketingCode Then
				vObj.MarketingCode = vObj.Client.MarketingCode;
				vObj.MarketingCodeConfirmationText = "";
			EndIf;
		EndIf;
		// Source of business
		If ValueIsFilled(vObj.Client.SourceOfBusiness) Then
			If vObj.SourceOfBusiness <> vObj.Client.SourceOfBusiness Then
				vObj.SourceOfBusiness = vObj.Client.SourceOfBusiness;
			EndIf;
		EndIf;
		// Client type
		If ValueIsFilled(vObj.Client.ClientType) And (Not ValueIsFilled(vObj.Client.ClientType.Hotel) Or vObj.Client.ClientType.Hotel = vObj.Hotel) Then
			If vObj.ClientType <> vObj.Client.ClientType Then
				vObj.ClientType = vObj.Client.ClientType;
				vObj.ClientTypeConfirmationText = vObj.Client.ClientTypeConfirmationText;
			EndIf;
		EndIf;
		// Client contact data
		If Not IsBlankString(vObj.Client.Phone) Then
			vObj.Phone = vObj.Client.Phone;
		EndIf;
		If Not IsBlankString(vObj.Client.Fax) Then
			vObj.Fax = vObj.Client.Fax;
		EndIf;
		If Not IsBlankString(vObj.Client.EMail) Then
			vObj.EMail = vObj.Client.EMail;
		EndIf;
		// Check if client has master charging rules
		vClientMasterFolio = Undefined;
		For Each vCRRow In vObj.Client.ChargingRules Do
			If ValueIsFilled(vCRRow.ChargingFolio) And vCRRow.ChargingFolio.IsMaster Then
				If vCRRow.ChargingFolio.Client = vObj.Client Then
					vClientMasterFolio = vCRRow.ChargingFolio;
					Break;
				EndIf;
			EndIf;
		EndDo;
		If ValueIsFilled(vClientMasterFolio) And vClientMasterFolio <> vObj.ChargingFolio Then
			vObj.ChargingFolio = vClientMasterFolio;
			vObj.FolioCurrency = vObj.ChargingFolio.FolioCurrency;
			vObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vObj.Hotel, vObj.ReportingCurrency, vObj.ExchangeRateDate);
		EndIf;
	EndIf;
	// Fill discount type and other discount parameters if filled
	vObj.pmSetDiscounts();
	// Automatic services list calculation	
	vObj.pmCalculateServices();
	// Build collapsed groups title
	BuildDiscountsGroupCollapsedTitle(vObj);
	BuildPropertiesGroupCollapsedTitle(vObj);
	BuildContactsGroupCollapsedTitle(vObj);
	// Put object back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // ClientOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientOnChange(pItem)
	ClientOnChangeAtServer();
EndProcedure // ClientOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure PhoneOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If Not IsBlankString(vObj.Phone) Then
		vObj.Phone = SMS.GetValidPhoneNumber(vObj.Phone);
		If Not ValueIsFilled(vObj.Client) Then
			vClient = cmGetClientByPhone(vObj.Phone);
			If ValueIsFilled(vClient) Then
				vObj.Client = vClient;
				ClientOnChangeAtServer(vObj);
			EndIf;
		EndIf;
	EndIf;
	// Build collapsed groups title
	BuildContactsGroupCollapsedTitle();
	// Put object back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // PhoneOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure PhoneOnChange(pItem)
	PhoneOnChangeAtServer();
EndProcedure // PhoneOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure EMailOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If Not IsBlankString(vObj.EMail) And Not ValueIsFilled(vObj.Client) Then
		vClient = cmGetClientByEMail(vObj.EMail);
		If ValueIsFilled(vClient) Then
			vObj.Client = vClient;
			ClientOnChangeAtServer(vObj);
		EndIf;
	EndIf;
	// Build collapsed groups title
	BuildContactsGroupCollapsedTitle();
	// Put object back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // EMailOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure EMailOnChange(pItem)
	EMailOnChangeAtServer();
EndProcedure // EMailOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure FaxOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If Not IsBlankString(vObj.Fax) Then
		vObj.Fax = SMS.GetValidPhoneNumber(vObj.Fax);
	EndIf;
	// Build collapsed groups title
	BuildContactsGroupCollapsedTitle();
	// Put object back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // FaxOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure FaxOnChange(pItem)
	FaxOnChangeAtServer();
EndProcedure // FaxOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ContactPersonOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Build collapsed groups title
	BuildContactsGroupCollapsedTitle();
	// Put object back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // ContactPersonOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ContactPersonOnChange(pItem)
	ContactPersonOnChangeAtServer();
EndProcedure // ContactPersonOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardOnChange(pItem)
	If ValueIsFilled(Object.DiscountCard) Then
		If GetDiscountCardIsBlocked(Object.DiscountCard) Then
			vMessage = NStr("en='Discount card is blocked!';ru='Дисконтная карта заблокирована!';de='Die Diskontkarte ist blockiert!'");
			ShowMessageBox(, vMessage);
			DiscountCardsEmptyRef();
		ElsIf GetDiscountCheckInDate(Object.DiscountCard) Then
			vMessage = NStr("en='Discount card is not valid on guest check in date!';ru='Дисконтная карта не действует на дату заезда гостя!';de='Die Diskontkarte gilt nicht am Anreisetag des Gastes!'");
			ShowMessageBox(, vMessage);
			DiscountCardsEmptyRef();
		Else
			vClient = GetDiscountCardClient(Object.DiscountCard);
			If ValueIsFilled(vClient) Then
				If Not ValueIsFilled(Object.Client) Then
					Object.Client = vClient;
					ClientOnChange(Items.Client);
				Else
					If Object.Client <> vClient Then
						If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt") Then
							vMessage = NStr("en='This discount card was issued for another client! You do not have rights to use this discount card.';
							                |ru='Дисконтная карта выдана другому клиенту. Нет прав на использование этой дисконтной карты.';
							                |de='Die Rabatt-Karte von einem anderen Kunde ausgegeben. Sie sind nicht berechtigt, diese Rabatt-Karte zu verwenden.'");
							ShowMessageBox(, vMessage);
							DiscountCardsEmptyRef();
						Else
							vMessage = NStr("ru='Дисконтная карта выдана на другого клиента: '; 
							                |de='Discount card was issued to the different client: ';
							                |en='Discount card was issued to the different client: '") + TrimAll(vClient) + "!";
							tcCommonFunctionOnClientServer.TextMessage(vMessage);
						EndIf;
					Else
						DiscountCardOnChangeAtServer();
					EndIf;
				EndIf;
			Else
				DiscountCardOnChangeAtServer();
			EndIf;
		EndIf;
	Else
		DiscountCardOnChangeAtServer();
	EndIf;
EndProcedure // DiscountCardOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardCreating(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(Object.Client) Then
		OpenForm("Catalog.DiscountCards.ObjectForm", New Structure("FillingValues", New Structure("Client, Identifier", Object.Client, pItem.EditText)), pItem, , , , , FormWindowOpeningMode.LockOwnerWindow);
	Else
		vUM = New UserMessage();
		vUM.Field = "Client";
		vUM.Text = NStr("en='Please create client profile first!'; ru='Пожалуйста создайте профайл клиента!'; de='Bitte erstellen Sie ein Kundeprofil!'");
		vUM.Message();
	EndIf;
EndProcedure // DiscountCardCreating

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountCardOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmSetDiscounts();
	vObj.pmCalculateServices();
	// Build collapsed groups title
	BuildDiscountsGroupCollapsedTitle(vObj);
	BuildContactsGroupCollapsedTitle();
	// Put object value back to the form attribute
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
EndProcedure // DiscountCardOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCheckInDate(vDiscountCard) 
	If BegOfDay(Object.CheckInDate) < vDiscountCard.ValidFrom Or
	   BegOfDay(Object.CheckInDate) >= ?(ValueIsFilled(vDiscountCard.ValidTo), vDiscountCard.ValidTo, EndOfDay(Object.CheckInDate)) Then
		Return True;
	Else 
		Return False;
	EndIf;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCardClient(vDiscountCard) 
	Return vDiscountCard.Client;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCardIsBlocked(vDiscountCard) 
	Return vDiscountCard.IsBlocked;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountCardsEmptyRef()
	  Object.DiscountCard = Catalogs.DiscountCards.EmptyRef();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardStartChoice(pItem, pChoiceData, pStandardProcessing)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToInputDiscountCardNumberManually") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // DiscountCardStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		// Try to find client identification card
		vCard = GetClientIdentificationCardById(vEventData.DeviceData);
		// Set client from the card data
		If ValueIsFilled(vCard) Then
			vClient = GetClient(vCard);
			If ValueIsFilled(vClient) Then
				If Parameters.Key.IsEmpty() Or Not ValueIsFilled(Object.Client) Then
					Object.Client = vClient;
					ClientOnChange(Items.Client);
				Else
					ShowMessageBox(, NStr("en='This card does not belong to the client! You may clear client field and try to slip card again.';ru='Чужая карта! Можете очистить поле клиента и заново прокатать карту.';de='Fremde Karte! Sie können das Kundefeld löschen und die Karte neu durchziehen.'"));
				EndIf;
				// Activate form
				Activate();
			EndIf;
		EndIf;
		// Try to search discount card
		vDiscountCard = GetDiscountCardById(vEventData.DeviceData);
		If ValueIsFilled(vDiscountCard) Then
			vDiscountCardClient = GetClient(vDiscountCard);
			If ValueIsFilled(vDiscountCardClient) Then
				If vDiscountCardClient = Object.Client Or Not ValueIsFilled(Object.Client) Or Parameters.Key.IsEmpty() Then
					Object.DiscountCard = vDiscountCard;
					DiscountCardOnChange(Items.DiscountCard);
				Else
					If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt") Then
						ShowMessageBox(, NStr("en='This card does not belong to the client! You may clear client field and try to slip card again.';ru='Чужая карта! Можете очистить поле клиента и заново прокатать карту.';de='Fremde Karte! Sie können das Kundefeld löschen und die Karte neu durchziehen.'"));
					Else
						Object.DiscountCard = vDiscountCard;
						DiscountCardOnChange(Items.DiscountCard);
					EndIf;
				EndIf;
			ElsIf Parameters.Key.IsEmpty() Then
				Object.DiscountCard = vDiscountCard;
				DiscountCardOnChange(Items.DiscountCard);
			EndIf;
			// Activate form
			Activate();
		EndIf;
		// Check if something was found
		If Not ValueIsFilled(vCard) And Not ValueIsFilled(vDiscountCard) Then
			ShowMessageBox(, NStr("en='Card was not found!';ru='Карта не найдена!';de='Die Karte wurde nicht gefunden!'"), 3);
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

// -----------------------------------------------------------------------------
&AtServer
Function GetClient(vCard)
	If ValueIsFilled(vCard.Client) Then
		Return vCard.Client;
	Else
		Return Catalogs.Clients.EmptyRef();
	EndIf;
EndFunction // GetClient

// -----------------------------------------------------------------------------
// Description: Function tries to find and return client identification card by card identifier
// Parameters: Card identifier
// Return value: Client identification card reference or empty reference
// -----------------------------------------------------------------------------
&AtServer
Function GetClientIdentificationCardById(pIdentifier, pUseDeleted = False) 
    Return cmGetClientIdentificationCardById(pIdentifier);
EndFunction // cmGetClientIdentificationCardById

// -----------------------------------------------------------------------------
// Description: Function tries to find and return discount card by card identifier
// Parameters: Card identifier
// Return value: Discount card reference or empty reference
// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCardById(pIdentifier, pSearchMarkedForDeletion = False) 
	Return cmGetDiscountCardById(pIdentifier);
EndFunction // cmGetDiscountCardById

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountTypeOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Set discounts
	vObj.pmSetDiscounts();
	// Discount
	If ValueIsFilled(vObj.DiscountType) Then
		vObj.DiscountServiceGroup = vObj.DiscountType.DiscountServiceGroup;
		If vObj.DiscountType.IsAccumulatingDiscount Then
			For Each vSrvRow In vObj.Services Do
				If vSrvRow.IsManual Then
					If cmIsServiceInServiceGroup(vSrvRow.Service, vObj.DiscountServiceGroup) Then
						vSrvRow.DiscountType = vObj.DiscountType;
						vSrvRow.DiscountServiceGroup = vObj.DiscountServiceGroup;
						CalculateAccumulationDiscountForAdditionalService(vObj, vSrvRow);
					EndIf;
				EndIf;
			EndDo;
		Else
			vDiscountTypeObj = vObj.DiscountType.GetObject();
			vObj.Discount = vDiscountTypeObj.pmGetDiscount(vObj.DateTimeFrom, , vObj.Hotel);
		EndIf;
	Else
		vObj.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		vObj.Discount = 0;
		vObj.DiscountConfirmationText = "";
	EndIf;
	// Automatic services list calculation	
	vObj.pmCalculateServices();
	// Build collapsed groups title
	BuildDiscountsGroupCollapsedTitle(vObj);
	BuildContactsGroupCollapsedTitle(vObj);
	// Put object back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // DiscountTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateAccumulationDiscountForAdditionalService(pObj, pSrvRow)
	vAccDiscounts = pObj.pmGetAccumulatingDiscountResources();
	If vAccDiscounts.Count() > 0 Then
		vAccDiscountsRow = vAccDiscounts.Get(0);
		vDiscountType = vAccDiscountsRow.DiscountType;
		If Not ValueIsFilled(vDiscountType) Then
			Return;
		EndIf;
		If pSrvRow.AccountingDate < vDiscountType.DateValidFrom Or
		   (pSrvRow.AccountingDate > vDiscountType.DateValidTo And ValueIsFilled(vDiscountType.DateValidTo)) Then
			Return;
		EndIf;
		vDiscountDimension = vAccDiscountsRow.DiscountDimension;
		If cmIsServiceInServiceGroup(pSrvRow.Service, pObj.DiscountServiceGroup) Then
			vDiscountTypeObj = vDiscountType.GetObject();
			For i = 1 To pSrvRow.LineNumber Do
				vWrkSrvRow = pObj.Services.Get(i - 1);
				If vWrkSrvRow.AccountingDate <= pSrvRow.AccountingDate Then
					vSrvDiscountDimension = Undefined;
					vSrvResource = vDiscountTypeObj.pmCalculateResource(vWrkSrvRow, ?(vWrkSrvRow.NumberOfPersons <> 0, vWrkSrvRow.NumberOfPersons, pObj.NumberOfPersons), vWrkSrvRow.Folio, pObj.DiscountCard, vSrvDiscountDimension);
					If TypeOf(vSrvDiscountDimension) = TypeOf(vDiscountDimension) Then
						If vSrvResource <> 0 Then
							vAccDiscountsRow.Resource = vAccDiscountsRow.Resource + vSrvResource;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			vResource = vAccDiscountsRow.Resource;
			vDiscountConfirmationText = "";
			vDiscount = vDiscountTypeObj.pmGetAccumulatingDiscount(pSrvRow.Service, pSrvRow.AccountingDate, 
																   vResource, 
																   vDiscountConfirmationText);
			If vDiscount <> 0 Then
				pSrvRow.DiscountType = vDiscountType;
				pSrvRow.Discount = vDiscount;
				pSrvRow.DiscountServiceGroup = pObj.DiscountServiceGroup;
				pSrvRow.DiscountConfirmationText = vDiscountConfirmationText;
			EndIf;
		EndIf;
	EndIf;						
EndProcedure // CalculateAccumulationDiscountForAdditionalService

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountTypeOnChange(pItem)
	DiscountTypeOnChangeAtServer();
EndProcedure // DiscountTypeOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Set discounts
	vObj.pmSetDiscounts();
	// Automatic services list calculation	
	vObj.pmCalculateServices();
	// Build collapsed groups title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Put object value back to the form attribute
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
EndProcedure // DiscountOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountOnChange(pItem)
	DiscountOnChangeAtServer();
EndProcedure // DiscountOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountSumOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Set discounts
	vObj.pmSetDiscounts();
	// Automatic services list calculation	
	vObj.pmCalculateServices();
	// Build collapsed groups title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Put object value back to the form attribute
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
EndProcedure // DiscountSumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountSumOnChange(pItem)
	DiscountSumOnChangeAtServer();
EndProcedure // DiscountSumOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountServiceGroupOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Set discounts
	vObj.pmSetDiscounts();
	// Automatic services list calculation	
	vObj.pmCalculateServices();
	// Build collapsed groups title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Put object value back to the form attribute
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
EndProcedure // DiscountServiceGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountServiceGroupOnChange(pItem)
	DiscountServiceGroupOnChangeAtServer();
EndProcedure // DiscountServiceGroupOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure TurnOffAutomaticDiscountsOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Automatic services list calculation	
	vObj.pmCalculateServices();
	// Build collapsed groups title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Put object value back to the form attribute
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
EndProcedure // TurnOffAutomaticDiscountsOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure TurnOffAutomaticDiscountsOnChange(pItem)
	TurnOffAutomaticDiscountsOnChangeAtServer();
EndProcedure // TurnOffAutomaticDiscountsOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure AgentOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If ValueIsFilled(vObj.Agent) Then
		// Agent commission
		If vObj.Agent.AgentCommission <> 0 Then
			vObj.AgentCommission = vObj.Agent.AgentCommission;
			vObj.AgentCommissionType = vObj.Agent.AgentCommissionType;
			vObj.AgentCommissionServiceGroup = vObj.Agent.AgentCommissionServiceGroup;
		EndIf;
		// Check should we show agent related message or not
		If vObj.Agent.ShowRemarksInReservations And Not IsBlankString(vObj.Agent.Remarks) And vObj.Agent <> vObj.Customer Then
			tcCommonFunctionOnClientServer.TextMessage(TrimR(vObj.Agent.Remarks));
		EndIf;
	Else
		// Reset agent commission
		vObj.AgentCommission = 0;
		vObj.AgentCommissionType = Undefined;
		vObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
	EndIf;
	// Automatic services list calculation	
	vWarnings = "";
	If vObj.pmCalculateServices(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
	// Build collapsed groups title
	BuildCommissionGroupCollapsedTitle(vObj);
	// Put object value back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // AgentOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentOnChange(pItem)
	AgentOnChangeAtServer();
EndProcedure // AgentOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure AgentCommissionOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Automatic services list calculation	
	vWarnings = "";
	If vObj.pmCalculateServices(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
	// Build collapsed groups title
	BuildCommissionGroupCollapsedTitle(vObj);
	// Put object value back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // AgentCommissionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionOnChange(pItem)
	AgentCommissionOnChangeAtServer();
EndProcedure // AgentCommissionOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure AgentCommissionTypeOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If Not ValueIsFilled(vObj.AgentCommissionType) Then
		If vObj.AgentCommission <> 0 Then
			vObj.AgentCommission = 0;
		EndIf;
	EndIf;
	// Automatic services list calculation	
	vWarnings = "";
	If vObj.pmCalculateServices(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
	// Build collapsed groups title
	BuildCommissionGroupCollapsedTitle(vObj);
	// Put object value back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // AgentCommissionTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionTypeOnChange(pItem)
	AgentCommissionTypeOnChangeAtServer();
EndProcedure // AgentCommissionTypeOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure AgentCommissionServiceGroupOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Automatic services list calculation	
	vWarnings = "";
	If vObj.pmCalculateServices(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
	// Build collapsed groups title
	BuildCommissionGroupCollapsedTitle(vObj);
	// Put object value back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // AgentCommissionServiceGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionServiceGroupOnChange(pItem)
	AgentCommissionServiceGroupOnChangeAtServer();
EndProcedure // AgentCommissionServiceGroupOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SourceOfBusinessOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Set discounts
	vObj.pmSetDiscounts();
	// Automatic services list calculation	
	vWarnings = "";
	If vObj.pmCalculateServices(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
	// Put object value back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // SourceOfBusinessOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SourceOfBusinessOnChange(pItem)
	SourceOfBusinessOnChangeAtServer();
EndProcedure // SourceOfBusinessOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure MarketingCodeOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Set discounts
	vObj.pmSetDiscounts();
	// Automatic services list calculation	
	vWarnings = "";
	If vObj.pmCalculateServices(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
	// Put object value back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // MarketingCodeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure MarketingCodeOnChange(pItem)
	MarketingCodeOnChangeAtServer();
EndProcedure // MarketingCodeOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ClientTypeOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Set discounts
	vObj.pmSetDiscounts();
	// Automatic services list calculation	
	vWarnings = "";
	If vObj.pmCalculateServices(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
	// Build collapsed groups title
	BuildPropertiesGroupCollapsedTitle(vObj);
	// Put object value back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // ClientTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	ClientTypeOnChangeAtServer();
EndProcedure // ClientTypeOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ResourceTariffOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Set discounts
	vObj.pmSetDiscounts();
	// Automatic services list calculation	
	vWarnings = "";
	If vObj.pmCalculateServices(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
	// Build collapsed groups title
	BuildPropertiesGroupCollapsedTitle(vObj);
	// Put object value back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // ResourceTariffOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ResourceTariffOnChange(pItem)
	ResourceTariffOnChangeAtServer();
EndProcedure // ResourceTariffOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RemarksOnChange(pItem)
	// Build collapsed groups title
	BuildRemarksGroupCollapsedTitle();
EndProcedure // RemarksOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculatePayerAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	// Calculate payer
	Payer = Enums.WhoPaysInResourceReservation.Client;
	If ValueIsFilled(vObj.Owner) Then
		Items.Owner.Visible = True;
		If vObj.Owner = vObj.Agent Then
			Payer = Enums.WhoPaysInResourceReservation.Agent;
		ElsIf vObj.Owner = vObj.Customer Or vObj.Owner = vObj.Contract Then
			Payer = Enums.WhoPaysInResourceReservation.Customer;
		ElsIf ValueIsFilled(vObj.Hotel) And (vObj.Owner = vObj.Hotel.IndividualsCustomer Or vObj.Owner = vObj.Hotel.IndividualsContract) Then
			Payer = Enums.WhoPaysInResourceReservation.Client;
		Else
			Payer = Enums.WhoPaysInResourceReservation.Other;
		EndIf;
	Else
		Items.Owner.Visible = False;
	EndIf;		
EndProcedure // CalculatePayerAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ResourceReservationStatusOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Update services
	If ValueIsFilled(vObj.ResourceReservationStatus) Then
		vObj.DoCharging = vObj.ResourceReservationStatus.DoCharging;
		If ValueIsFilled(vObj.ResourceReservationStatus.GuaranteeType) Then
			vObj.GuaranteeType = vObj.ResourceReservationStatus.GuaranteeType;
		EndIf;
		// Automatic services list calculation	
		vObj.pmCalculateServices();
	EndIf;
	// Put object value back to the form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // ResourceReservationStatusOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ResourceReservationStatusOnChange(pItem)
	ResourceReservationStatusOnChangeAtServer();
EndProcedure // ResourceReservationStatusOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure TGuestGroupDescriptionOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If ValueIsFilled(vObj.GuestGroup) Then
		vGuestGroupObj = vObj.GuestGroup.GetObject();
		vGuestGroupObj.Description = TrimR(TGuestGroupDescription);
		Try
			vGuestGroupObj.Write();
		Except
			// Fill guest group description
			FillGuestGroupDescriptionAtServer(vObj);
		EndTry;
	Else
		TGuestGroupDescription = "";
	EndIf;
EndProcedure // TGuestGroupDescriptionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure TGuestGroupDescriptionOnChange(Item)
	TGuestGroupDescriptionOnChangeAtServer();
EndProcedure // TGuestGroupDescriptionOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure FillGuestGroupDescriptionAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If ValueIsFilled(vObj.GuestGroup) Then
		TGuestGroupDescription = TrimR(vObj.GuestGroup.Description);
	Else
		TGuestGroupDescription = "";
	EndIf;
EndProcedure // FillGuestGroupDescriptionAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GuestGroupOnChangeAtServer()
	FillGuestGroupDescriptionAtServer();
EndProcedure // GuestGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOnChange(pItem)
	GuestGroupOnChangeAtServer();
	FillingObjects();
EndProcedure // GuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(pItem)
	If (WasPosted = False Or ThisForm.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "OpenFolios"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vResult = ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting));
		If Not vResult Then
			Return;
		EndIf;         
	EndIf;
	
	vParametersStructure = New Structure("IsNew, WasPosted, IsFormModified, DocRef", IsNew, WasPosted, ThisForm.Modified, Object.Ref);
	OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure",vParametersStructure), , Object.Ref);
EndProcedure // OpenFolios

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	// Was posted
	WasPosted = True;
EndProcedure // AfterWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Function CheckAttributes()
	vCancel = CheckAttributesAtServer();
	If Not vCancel Then
		vCancel = Not CheckFilling();
	EndIf;
	Return Not vCancel;
EndFunction // CheckAttributes

// -----------------------------------------------------------------------------
&AtServer
Function CheckAttributesAtServer()
	vCancel = False;
	vObj = FormAttributeToValue("Object");
	SetObjectAndFormAttributeConformity(vObj, "Object");
	vMessage = "";
	vAttributeInErr = "";
	vCancel	= vObj.pmCheckDocumentAttributes(vObj.Posted, vMessage, vAttributeInErr, True);
	If vCancel Then
		vUM = New UserMessage();
		vUM.SetData(vObj);
		vUM.Field = vAttributeInErr;
		vUM.Text = NStr(vMessage);
		vUM.Message();
	Else
		If IsNew Then
			vIsResourceBlock = False;
			If ValueIsFilled(vObj.EventActivity) And TypeOf(vObj.EventActivity) = Type("CatalogRef.EventActivities") Then
				vIsResourceBlock = vObj.EventActivity.IsResourceBlock;
			EndIf;
			If Not vIsResourceBlock Then
				// Check if contact person is entered
				If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSkipInputOfReservationContactPerson") Then
					If IsBlankString(vObj.ContactPerson) Then
						vMessage = NStr("ru='Не указано контактное лицо!';en='Contact person should be filled!';de='Contact person should be filled!'");
						vUM = New UserMessage();
						vUM.SetData(vObj);
						vUM.Field = "ContactPerson";
						vUM.Text = vMessage;
						vUM.Message();
						vCancel = True;
					EndIf;
				EndIf;
				// Check if client type is entered
				If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSkipInputOfClientType") Then
					If Not ValueIsFilled(vObj.ClientType) Then
						vMessage = NStr("ru='Не указан тип клиента!';en='Client type should be filled!';de='Client type should be filled!'");
						vUM = New UserMessage();
						vUM.SetData(vObj);
						vUM.Field = "ClientType";
						vUM.Text = vMessage;
						vUM.Message();
						vCancel = True;
					EndIf;
				EndIf;
				// Check if marketing code is entered
				If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSkipInputOfReservationMarketingCode") Then
					If Not ValueIsFilled(vObj.MarketingCode) Then
						vMessage = NStr("ru='Не указано направление маркетинга!';en='Marketing code should be filled!';de='Marketing code should be filled!'");
						vUM = New UserMessage();
						vUM.SetData(vObj);
						vUM.Field = "MarketingCode";
						vUM.Text = vMessage;
						vUM.Message();
						vCancel = True;
					EndIf;
				EndIf;
				// Check if source of business is entered
				If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSkipInputOfReservationSourceOfBusiness") Then
					If Not ValueIsFilled(vObj.SourceOfBusiness) Then
						vMessage = NStr("ru='Не указан источник информации о гостинице!';en='Source of business should be filled!';de='Source of business should be filled!'");
						vUM = New UserMessage();
						vUM.SetData(vObj);
						vUM.Field = "SourceOfBusiness";
						vUM.Text = vMessage;
						vUM.Message();
						vCancel = True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle(vObj);
	// Client decoration
	BuildContactsGroupCollapsedTitle(vObj);
	// Build commission group hidden title
	BuildCommissionGroupCollapsedTitle(vObj);
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Build properties group hidden title
	BuildPropertiesGroupCollapsedTitle(vObj);
	// Return
	Return vCancel;
EndFunction // CheckAttributesAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "SessionParameters.CurrentUser.Change" Then
		EmployeePINCodeChecked = True;
		If pParameter.ModeAfterCheck = "WriteAndClose" Then
			vResult = ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting));
			If vResult Then
				ThisForm.Close();
			EndIf;
		ElsIf pParameter.ModeAfterCheck = "OpenFolios" Then
			OpenFolios(Undefined);
		ElsIf pParameter.ModeAfterCheck = "CreateProformaInvoice" Then
			CreateProformaInvoice(Undefined);
		ElsIf pParameter.ModeAfterCheck = "CreateGroupResume" Then
			CreateGroupResume(Undefined);
		Else
			vResult = ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting));
		EndIf;
	ElsIf pEventName = "CreditCard.Write" Then
		If pSource = ThisForm Then
			CreditCardAfterUserInput(pParameter);
		EndIf;
	ElsIf pEventName = "Document.Order.Write" Then
		FillOrders();
	ElsIf pEventName = "Document.ResourceReservation.Write" Then
		If pParameter = Object.Ref Then
			ThisForm.Read();
			
			// Save current accounting date
			OldAccountingDate = BegOfDay(Object.DateTimeFrom);
			
			// Fill amount without discount
			CalculateTotalServices();
			
			// Build collapsed groups title
			BuildAccountingGroupCollapsedTitle();
			BuildContactsGroupCollapsedTitle();
			BuildDiscountsGroupCollapsedTitle();
			BuildCommissionGroupCollapsedTitle();
			BuildPropertiesGroupCollapsedTitle();
			BuildRemarksGroupCollapsedTitle();
		EndIf;
	ElsIf pEventName = "MessageWrite" Then
		FillTasksPresentation();
	ElsIf pEventName = "CommonForm.tcSendMail.Send" And pSource = Object.Ref Then
		If ValueIsFilled(pParameter) And Not ValueIsFilled(Object.EMail) Then 
			Object.EMail = pParameter; 	
		EndIf;
	ElsIf pEventName = "System.Hotel.Changed" And pParameter <> Object.Hotel Then
		If ThisForm.Modified Then
			PostAndClose(Commands.PostAndClose);
		Else
			ThisForm.Close();
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure CreateProformaInvoice(pCommand)
	If (WasPosted = False Or ThisForm.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "CreateGroupInvoice"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vResult = ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting));
		If Not vResult Then
			Return;
		EndIf;
	EndIf;
	vForm = GetForm("Document.ProformaInvoice.ObjectForm");
	vFormData = vForm.Object;
	NewGroupInvoice(vFormData);
	CopyFormData(vFormData, vForm.Object);
	vForm.Open();
EndProcedure // CreateProformaInvoice

// ------------------------------------------------------------------------------------------------
&AtServer
Function NewGroupInvoice(pFormData)
	vInvObj = FormDataToValue(pFormData, Type("DocumentObject.ProformaInvoice"));
	vInvObj.Fill(Object.Ref);
	vInvObj.ParentDoc = Documents.ResourceReservation.EmptyRef();
	vInvObj.Fill(Object.GuestGroup);
	ValueToFormData(vInvObj, pFormData);
EndFunction // NewGroupInvoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditCardPresentationClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(Object.CreditCard) Then
		OpenForm("Catalog.CreditCards.ObjectForm", New Structure("Key", Object.CreditCard), ThisForm, Object.CreditCard, , , , FormWindowOpeningMode.LockOwnerWindow);
	Else
	 	OpenForm("Catalog.CreditCards.ObjectForm", New Structure("FillingValues", New Structure("CardOwner", Object.Client)), ThisForm);
	EndIf;
EndProcedure // CreditCardPresentationClick

// -----------------------------------------------------------------------------
Procedure CreditCardAfterUserInput(pCreditCard) Export
	If ValueIsFilled(pCreditCard) Then
		Object.CreditCard = pCreditCard;
		CreditCardPresentation = TrimAll(Object.CreditCard);
		Items.ClearCreditCard.Visible = True;
		ThisForm.Modified = True;
	Else
		CreditCardPresentation = NStr("en='<Credit card>'; ru='<Кредитная карта>'; de='<Kreditkarte>'");
		Items.ClearCreditCard.Visible = False;
	EndIf;
EndProcedure // CreditCardAfterUserInput

// -----------------------------------------------------------------------------
&AtServer
Procedure DateTimeFromOnChangeAtServer(rWarnings)
	vObj = FormAttributeToValue("Object");
	// Calculate check out date
	vObj.DateTimeTo = vObj.pmCalculateDateTimeTo();
	// Automatic services list calculation	
	vObj.pmCalculateServices(rWarnings);
	// Put object back to form data
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
EndProcedure // DateTimeFromOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DateTimeFromOnChange(pItem)
	vWarnings = "";
	DateTimeFromOnChangeAtServer(vWarnings);
	If Not IsBlankString(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
EndProcedure // DateTimeFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(pItem)
	vWarnings = "";
	DateTimeFromOnChangeAtServer(vWarnings);
	If Not IsBlankString(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DateTimeToOnChangeAtServer(rWarnings)
	vObj = FormAttributeToValue("Object");
	// Calculate check out date
	vObj.Duration = vObj.pmCalculateDuration();
	// Automatic services list calculation	
	vObj.pmCalculateServices(rWarnings);
	// Put object back to form data
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
EndProcedure // DateTimeToOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DateTimeToOnChange(pItem)
	vWarnings = "";
	DateTimeToOnChangeAtServer(vWarnings);
	If Not IsBlankString(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
EndProcedure // DateTimeToOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ResourceTypeOnChangeAtServer(pObj = Undefined, rWarnings = "")
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Do processing
	If ValueIsFilled(vObj.ResourceType) Then
		// Check resource
		If Not vObj.ResourceType.IsFolder Then
			If ValueIsFilled(vObj.Resource) Then
				If vObj.ResourceType <> vObj.Resource.Owner Then
					vObj.Resource = Catalogs.Resources.EmptyRef();
				EndIf;
			EndIf;
		EndIf;
		// Check if hotel was changed
		If ValueIsFilled(vObj.ResourceType.Hotel) And vObj.ResourceType.Hotel <> vObj.Hotel Then
			vObj.Hotel = vObj.ResourceType.Hotel;
			vObj.pmProcessHotelChange();
		EndIf;
		// Company
		If ValueIsFilled(vObj.ResourceType.Company) Then
			If vObj.Company <> vObj.ResourceType.Company Then
				vObj.Company = vObj.ResourceType.Company;
			EndIf;
		EndIf;
		// Check resource type template folio
		If ValueIsFilled(vObj.ResourceType.TemplateFolio) Then
			vObj.pmCreateFolio();
		EndIf;
	EndIf;
	// Automatic services list calculation
	vObj.pmCalculateServices(rWarnings);
	// Back to form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // ResourceTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ResourceTypeOnChange(Item)
	vWarnings = "";
	ResourceTypeOnChangeAtServer(, vWarnings);
	If Not IsBlankString(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
EndProcedure // ResourceTypeOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ResourceOnChangeAtServer(pObj = Undefined, rWarnings = "")
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Do processing
	If ValueIsFilled(vObj.Resource) Then
		// Resource type
		vObj.ResourceType = vObj.Resource.Owner;
		// Check if hotel was changed
		If ValueIsFilled(vObj.ResourceType) Then
			If ValueIsFilled(vObj.ResourceType.Hotel) And vObj.ResourceType.Hotel <> vObj.Hotel Then
				vObj.Hotel = vObj.ResourceType.Hotel;
				vObj.pmProcessHotelChange();
			EndIf;
		EndIf;
		// Set resource type company
		If ValueIsFilled(vObj.ResourceType) Then
			If ValueIsFilled(vObj.ResourceType.Company) Then
				If vObj.Company <> vObj.ResourceType.Company Then
					vObj.Company = vObj.ResourceType.Company;
				EndIf;
			EndIf;
		EndIf;
		// Set resource company
		If ValueIsFilled(vObj.Resource.Company) Then
			If vObj.Company <> vObj.Resource.Company Then
				vObj.Company = vObj.Resource.Company;
			EndIf;
		EndIf;
		// Service package
		vObj.ServicePackage = vObj.Resource.ServicePackage;
		// Check resource template folio
		If ValueIsFilled(vObj.Resource.TemplateFolio) Then
			vObj.pmCreateFolio();
		EndIf;
	EndIf;
	// Automatic services list calculation
	vObj.pmCalculateServices(rWarnings);
	// Back to form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
		// Service packages presentation
		FillServicePackagesPresentation();
	EndIf;
EndProcedure // ResourceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ResourceOnChange(pItem)
	vWarnings = "";
	ResourceOnChangeAtServer(, vWarnings);
	If Not IsBlankString(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
EndProcedure // ResourceOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure NumberOfPersonsOnChangeAtServer(pObj = Undefined, rWarnings = "")
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Save old number of persons
	OldNumberOfPersons = vObj.NumberOfPersons;
	// Automatic services list calculation	
	vObj.pmCalculateServices();
	// Back to form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // NumberOfPersonsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfPersonsOnChange(pItem)
	vWarnings = "";
	NumberOfPersonsOnChangeAtServer(, vWarnings);
	If Not IsBlankString(vWarnings) Then
		tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
	EndIf;
EndProcedure // NumberOfPersonsOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure FillServicePackagesPresentation()
	// Service packages
	TServicePackagesPresentation = "";
	If ValueIsFilled(Object.ServicePackage) And Not Object.ServicePackage.IsMealBoardTerm Then
		TServicePackagesPresentation = TrimAll(Object.ServicePackage.Description);
	EndIf;
	For Each vServicePackageRow In Object.ServicePackages Do
		If ValueIsFilled(vServicePackageRow.ServicePackage) Then
			If IsBlankString(TServicePackagesPresentation) Then
				TServicePackagesPresentation = TrimAll(vServicePackageRow.ServicePackage.Description);
			Else
				TServicePackagesPresentation = TServicePackagesPresentation + ", " + TrimAll(vServicePackageRow.ServicePackage.Description);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillServicePackagesPresentation

// -----------------------------------------------------------------------------
&AtServer
Function GetServicePackagesListAtServer()
	// Get all service packages available for use
	vServicePackagesList = cmGetAllowedServicePackages(Object.Hotel, BegOfDay(Object.DateTimeFrom), BegOfDay(Object.DateTimeTo), , True);
	// Check service packages already being selected
	If ValueIsFilled(Object.ServicePackage) Then
		vSPItem = vServicePackagesList.FindByValue(Object.ServicePackage);
		If vSPItem <> Undefined Then
			vSPItem.Check = True;
		EndIf;
	EndIf;
	For Each vSPRow In Object.ServicePackages Do
		If ValueIsFilled(vSPRow.ServicePackage) Then
			vSPItem = vServicePackagesList.FindByValue(vSPRow.ServicePackage);
			If vSPItem <> Undefined Then
				vSPItem.Check = True;
			EndIf;
		EndIf;
	EndDo;
	Return vServicePackagesList;
EndFunction // GetServicePackagesListAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveServicePackagesListAtServer(pServicePackagesList)
	If ValueIsFilled(Object.ServicePackage) Then
		Object.ServicePackage = Catalogs.ServicePackages.EmptyRef();
	EndIf;
	If Object.ServicePackages.Count() > 0 Then
		Object.ServicePackages.Clear();
	EndIf;
	If pServicePackagesList.Count() > 0 Then
		vIsFirstItem = True;
		For Each vSPItem In pServicePackagesList Do
			If vSPItem.Check Then
				If vIsFirstItem Then
					vIsFirstItem = False;
					Object.ServicePackage = vSPItem.Value;
				Else
					vSPRow = Object.ServicePackages.Add();
					vSPRow.ServicePackage = vSPItem.Value;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Fill service packages presentation
	FillServicePackagesPresentation();
	// Calculate services
	vObj = FormAttributeToValue("Object");
	vObj.pmCalculateServices();
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
EndProcedure // SaveServicePackagesListAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicePackagesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vServicePackagesList = GetServicePackagesListAtServer();
	// Ask user to check what he needs
	vServicePackagesList.ShowCheckItems(New NotifyDescription("ServicePackagesStartChoice_AfterInput", ThisForm, New Structure()), NStr("en='Check service packages...'; ru='Отметьте пакеты услуг...'; de='Markieren Dienstleistungspakete...'"));
EndProcedure // ServicePackagesStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicePackagesStartChoice_AfterInput(pValue, pParametrs) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	SaveServicePackagesListAtServer(pValue);
	RefreshDataRepresentation();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicePackagesClearingAtServer(pStandardProcessing)
	Object.ServicePackage = Catalogs.ServicePackages.EmptyRef();
	Object.ServicePackages.Clear();
	// Calculate services
	vObj = FormAttributeToValue("Object");
	vObj.pmCalculateServices();
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
	// Fill service packages presentation
	FillServicePackagesPresentation();
EndProcedure // ServicePackagesClearingAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicePackagesClearing(pItem, pStandardProcessing)
	ServicePackagesClearingAtServer(pStandardProcessing);
	RefreshDataRepresentation();
EndProcedure // ServicePackagesClearing

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateTotalServices()
	// Fill calculated columns in Object.Services
	vTotalSumWithDiscount = 0;
	For Each vSrvRow In Object.Services Do
		vSrvRow.SumWithDiscount = vSrvRow.Sum - vSrvRow.DiscountSum;
		vTotalSumWithDiscount = vTotalSumWithDiscount + vSrvRow.SumWithDiscount;
	EndDo;
	TTotalAmount = cmFormatSum(vTotalSumWithDiscount, Object.FolioCurrency);
	vTotalStr = tcOnServer.cmFormattedSumString(vTotalSumWithDiscount, Object.FolioCurrency);
	If IsBlankString(vTotalStr) Then
		If Object.Services.Count() > 0 Then
			vTotalStr = "---";
		Else
			vTotalStr = "N/A";
		EndIf;
	EndIf;	
	Items.DecorationTotalSum.Title = vTotalStr;
EndProcedure // CalculateTotalServices

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef)
	#If ThickClientOrdinaryApplication Then
		vExtProcData = pExtProcRef.ExternalProcessingStorage.Get();
		vExtProcPath = GetTempFileName(".efd");
		vExtProcData.Write(vExtProcPath);
		vExtProcObj = ExternalDataProcessors.Create(vExtProcPath, False);
		vStruct = New Structure("InputParameter, ObjectPrintingForm", FormDataToValue(Object, Type("DocumentObject.ResourceReservation")), pPrintFormTypeRef);
		FillPropertyValues(vExtProcObj, vStruct);
		vFrm = vExtProcObj.GetForm();
		vFrm.Open();
		BeginDeletingFiles(Undefined, vExtProcPath);
	#Else
		vURL = GetURL(pExtProcRef, "ExternalProcessingStorage"); 
		vName = ConnectExternalDataProcessor(vURL, "ExternalReservationConfirmationForm");
		vParams = New Structure("InputParameter, ObjectPrintingForm", Object.Ref, pPrintFormTypeRef);
		OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
	#EndIf
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef)
	#If ThickClientOrdinaryApplication Then
		vExtRepData = pExtRepRef.ExternalProcessingStorage.Get();
		vExtRepPath = GetTempFileName(".erf");
		vExtRepData.Write(vExtRepPath);
		vExtRepObj = ExternalReports.Create(vExtRepPath, False);
		vStruct = New Structure("Document, ObjectPrintingForm", FormDataToValue(Object, Type("DocumentObject.ResourceReservation")), pPrintFormTypeRef);
		FillPropertyValues(vExtRepObj, vStruct);
		// Fill reference to the report catalog item
		vExtRepObj.Report = pPrintFormTypeRef.Report;
		// Load report catalog item attributes
		vExtRepObj.pmLoadReportAttributes(Object.Ref);
		// Open report's default form
		vExtRepFrm = vExtRepObj.GetForm();
		vExtRepFrm.GenerateOnFormOpen = True;
		vExtRepFrm.Open();
		BeginDeletingFiles(New NotifyDescription, vExtRepPath);
	#Else
		vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef, "Report"), "ExternalProcessingStorage"); 
		vName = ConnectExternalReport(vURL, "ExternalReportForm");
		vParams = New Structure("Document, ObjectPrintingForm", Object.Ref, pPrintFormTypeRef);
		OpenForm("ExternalReport." + vName + ".Form", vParams);
	#EndIf
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFunctionsButton()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectFormActions.Ref,
	|	ObjectFormActions.Code AS Code,
	|	ObjectFormActions.PredefinedDataName,
	|	ObjectFormActions.IsDefault AS IsDefault
	|FROM
	|	Catalog.ObjectFormActions AS ObjectFormActions
	|WHERE
	|	NOT ObjectFormActions.DeletionMark
	|	AND ObjectFormActions.ObjectType = &ObjectType
	|	AND ObjectFormActions.IsActive = TRUE
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code";
	
	Query.SetParameter("ObjectType", Documents.ResourceReservation.EmptyRef());	
	QueryResult = Query.Execute();	
	SelectionRecords = QueryResult.Select();
	Actions.Clear();
	While SelectionRecords.Next() Do
		If SelectionRecords.PredefinedDataName = "" 
			or SelectionRecords.PredefinedDataName = "ResourceReservationFillSettlement"
			or SelectionRecords.PredefinedDataName = "ResourceReservationGuestGroupFillSettlement"
			or SelectionRecords.PredefinedDataName = "ResourceReservationFillInvoice"
			or SelectionRecords.PredefinedDataName = "ResourceReservationSendMyFolioSMS"
			or SelectionRecords.PredefinedDataName = "ResourceReservationEventFillInvoice"
			//or SelectionRecords.PredefinedDataName = "ResourceReservationFillOrder" 
			Then
			vNewRow = Actions.Add();
			vNewRow.Action = SelectionRecords.Ref;
			vNewRow.IsDefault = SelectionRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("Func"+vID);
			vCommand.Action = "FuncButtonClick";
			If SelectionRecords.IsDefault Then
				vStructure = New Structure("Title,CommandName",
				TrimAll(SelectionRecords.Code) + " " + cmNStr(SelectionRecords.ref),"Func"+vID);
			Else
				vStructure = New Structure("Title,CommandName",
				TrimAll(SelectionRecords.Code) + " " + cmNStr(SelectionRecords.ref),"Func"+vID);
			EndIf;
			
			tcOnServer.cmCreateItem(ThisForm,?( SelectionRecords.IsDefault,Items.FormGroupFunctionsDefault,Items.FormGroupFunctionsNotDefault),"Func"+vID,"FormButton",vStructure);
		EndIf;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FuncButtonClick(Command)
	If ThisForm.IsNew Or ThisForm.Modified Then
		ShowMessageBox(Undefined, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	
	vActionsNumber = StrReplace(Command.Name,"Func","");
	vAction = GetActionForNumber(vActionsNumber);
	
	If ValueIsFilled(vAction.ExternalProcessing) Then
		#IF ThickClientOrdinaryApplication THEN
			If Not cmLoadExternalDataProcessor(vAction.ExternalProcessing, FormAttributeToValue("Object", Type("DocumentObject.Reservation")), , Undefined) Then
				ShowMessageBox(, NStr("en='Failed to load external action!';ru='Не удалось загрузить внешнюю операцию!';de='Die externe Operation konnte nicht geladen werden!'"));
			EndIf;
		#ENDIF
	Else
		If vAction.PredefinedDataName = "ResourceReservationFillSettlement" Then
			vParam = New Structure;
			vParam.Insert("basis", Object.Ref);
			OpenForm("Document.Settlement.ObjectForm", vParam, ThisForm, Object.Ref);
		ElsIf vAction.PredefinedDataName = "ResourceReservationGuestGroupFillSettlement" Then
			vParam = New Structure;
			vParam.Insert("basis", Object.GuestGroup);
			OpenForm("Document.Settlement.ObjectForm", vParam, ThisForm, Object.GuestGroup);
		ElsIf vAction.PredefinedDataName = "ResourceReservationFillInvoice" Then
			vParam = New Structure;
			vParam.Insert("basis", Object.Ref);
			OpenForm("Document.ProformaInvoice.ObjectForm", vParam, ThisForm, True);	
		ElsIf vAction.PredefinedDataName = "ResourceReservationSendMyFolioSMS" Then
			SendWelcomeSMS(Commands.SendWelcomeToMyFolioSystemSMS);
		ElsIf vAction.PredefinedDataName = "ResourceReservationEventFillInvoice" Then
			vEvent = tcOnServer.cmGetAttributeByRef(Object.GuestGroup, "Event");
			If ValueIsFilled(vEvent) Then
				vParam = New Structure;
				vParam.Insert("basis", vEvent);
				OpenForm("Document.ProformaInvoice.ObjectForm", vParam, ThisForm, vEvent);
			Else
				ShowMessageBox(, NStr("en='No event for this group!'; ru='Мероприятие у группы не указано!'; de='Die Veranstaltung bei der Gruppe ist nicht angegeben!'"));
			EndIf;
		ElsIf vAction.PredefinedDataName = "ResourceReservationFillOrder" Then
			vParam = New Structure;
			vParam.Insert("basis", Object.Ref);
			OpenForm("Document.Order.ObjectForm", vParam, ThisForm, True);
		// Run data processor
		ElsIf ValueIsFilled(vAction.DataProcessor) Then     
			vReturnParameter = New Structure("Action, Data, FileName");
			If Not RunDataProcessor(vAction.DataProcessor, Object.Ref, True, vReturnParameter) Then
				ShowMessageBox(, NStr("en='Failed to run data processor!';ru='Не удалось выполнить обработку!';de='Die Bearbeitung ist fehlgeschlagen!'"));
			Else
				If vReturnParameter <> Undefined And TypeOf(vReturnParameter) = Type("Structure") Then
					If vReturnParameter.Property("Action") And vReturnParameter.Action <> Undefined Then
						If vReturnParameter.Action = "ShowFile" Then
							vFileData = vReturnParameter.Data;
							GetFromTempStorage(vFileData).Write(TempFilesDir() + vReturnParameter.FileName);
							BeginRunningApplication(New NotifyDescription, TempFilesDir() + vReturnParameter.FileName);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		Else
			ShowMessageBox(, NStr("en='No data processor found for action!';ru='У действия не указан обработчик!';de='Bei der Aktion ist kein Bearbeiter angegeben!'"));
		EndIf;
	EndIf;   
EndProcedure // FuncButtonClick

// -----------------------------------------------------------------------------
&AtServer
Function GetActionForNumber(pActionsNumber)
	vActions = Actions.FindByID(Number(pActionsNumber)).Action;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vActions);
	vStruct.Insert("PredefinedDataName",vActions.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vActions.ExternalProcessing);
	vStruct.Insert("DataProcessor",vActions.DataProcessor);
	
	Return vStruct;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function RunDataProcessor(pDataProcessor, pParameter, pIsInteractive = False, rReturnParameter)
	vPARAM = New Structure("InputParameter, OutputParameter", pParameter, rReturnParameter);
	vResult = cmRunDataProcessor(pDataProcessor, vPARAM, pIsInteractive);
	rReturnPameter = vPARAM.OutputParameter;
	Return vResult;
EndFunction // RunDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Function SendWelcomeSMSAtServer()
	vMessage = "";
	
	If ValueIsFilled(Object.ResourceReservationStatus) And Object.ResourceReservationStatus.IsActive Then
		
		vExtSys = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(Object.Hotel);
		If NOT ValueIsFilled(vExtSys) Then
			// The integration with hotel365 is not set
			Return NStr("en = 'Integration with the hotel365 service is not configured'; de = 'Die Integration mit hotel365 ist nicht konfiguriert'; ru = 'Не настроена интеграция с сервисом hotel365'");
		EndIf;
		If NOT vExtSys.IsActive Then
			// The integration with hotel365 is switched off
			Return NStr("en = 'The Integration with hotel365 is switched off'; de = 'Die Integration mit hotel365 ist ausgeschaltet'; ru = 'Интеграция с hotel365 отключена'");
		EndIf;
		
		// Get list of reservations to send message to
		vDocsList = New ValueList();
		vDocsList.Add(Object.Ref);
		// Send SMS to every client in the list
		For Each vDocItem In vDocsList Do
			vDoc = vDocItem.Value;
			vHotel = vDoc.Hotel;
			vGuest = vDoc.Client;
			vPhone = ?(Not IsBlankString(vDoc.Phone), TrimAll(vDoc.Phone), TrimAll(vGuest.Phone));
			If Not IsBlankString(vPhone) Then
				vResult = SMS.Hotel365_SendSMS(vHotel, vDoc, vPhone, vGuest);
				If Not vResult.Success Then
					For Each vErrorText In vResult.Errors Do
						vMessage = vMessage + ?(IsBlankString(vMessage), "", Chars.LF) + vErrorText;
					EndDo;
				EndIf;
			Else
				vMessage = vMessage + ?(IsBlankString(vMessage), "", Chars.LF) + NStr("en='Client phone is not filled!'; ru='В брони не указан телефон клиента!'; de='Kunde-Telefon ist nicht gefüllt!'");
			EndIf;
		EndDo;
	EndIf;
	Return vMessage;
EndFunction // SendWelcomeSMSAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SendWelcomeSMS(pCommand)
	vMessage = SendWelcomeSMSAtServer();
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // SendWelcomeSMS

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
	Query.SetParameter("ObjectType", Documents.ResourceReservation.EmptyRef());	
	QueryResult = Query.Execute();	
	SelectionRecords = QueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	vLang = Object.Client.Language;
	While SelectionRecords.Next() Do
		SelectionDetailRecords = SelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = SelectionRecords.Language or not ValueIsFilled(SelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf not vLang = SelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisForm,Items.FormGroupPrintingNotDefaultExtra,"Print"+SelectionRecords.Language,"FormGroup",
			New Structure("Type,Title",
			FormGroupType.Popup,SelectionRecords.Language));
		EndIf;
		
		While SelectionDetailRecords.Next() Do
			If SelectionDetailRecords.PredefinedDataName = "" 
				//or SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintPaymentOrder"
				or SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationRu"  
				or SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationEn"  
				or SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationDe"  
				or SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysRu"  
				or SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysEn"  		
				or SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysDe" Then 
				vNewRow = PrintForms.Add();
				vNewRow.PrintForm = SelectionDetailRecords.Ref;
				vNewRow.IsDefault = SelectionDetailRecords.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add("Print"+vID);
				vCommand.Action = "PrintButtonClick";
				If SelectionDetailRecords.IsDefault Then
					vParent = Items.FormGroupPrintingDefault;
				Else
					vParent = vParentLang;
				EndIf;
				vStructure = New Structure("Title,CommandName",
				TrimAll(SelectionDetailRecords.Code) + " " + cmNStr(SelectionDetailRecords.ref),"Print"+vID);
				
				tcOnServer.cmCreateItem(ThisForm,vParent,"Print"+vID,"FormButton",vStructure);
			EndIf;
		EndDo;
	EndDo;
EndProcedure // FillPrintingButton

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(pCommand)
	If ThisForm.IsNew Or ThisForm.Modified Then
		ShowMessageBox(Undefined, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	
	vPrintNumber = StrReplace(pCommand.Name,"Print","");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	
	// Load external print form
	If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
		Try
			OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
			vExternalProcessing = Undefined;
		EndTry;
	ElsIf ValueIsFilled(vPrintForm.Report) Then
		Try
			OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
		EndTry;
	ElsIf vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationRu" Or
	      vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationEn" Or
		  vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationDe" Then
		WasAlreadyPrint = True;
		OpenForm("Document.ResourceReservation.Form.tcReservationConfirmationForm", New Structure("SelReservation, SelLanguage, SelObjectPrintForm, SelByDays, CloseOnOwnerClose", Object.Ref, tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"), vPrintForm.Ref, False, False), ThisForm, Object.Ref);
	ElsIf vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysRu" Or
	      vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysEn" Or
		  vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysDe" Then
		WasAlreadyPrint = True;
		OpenForm("Document.ResourceReservation.Form.tcReservationConfirmationForm", New Structure("SelReservation, SelLanguage, SelObjectPrintForm, SelByDays, CloseOnOwnerClose", Object.Ref, tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"), vPrintForm.Ref, True, False), ThisForm, Object.Ref);
	EndIf;
EndProcedure // PrintButtonClick

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumber(pActionsNumber)
	vPrintForms = PrintForms.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vPrintForms);
	vStruct.Insert("PredefinedDataName",vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vPrintForms.ExternalProcessing);
	vStruct.Insert("Report",vPrintForms.Report);
	vStruct.Insert("Language",vPrintForms.Language);
	
	Return vStruct;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure FillOrders()
	If ValueIsFilled(Object.Ref) Then
		vObject	= Object;
		vDocs = New ValueTable;
		vDocs.Columns.Add("Doc");
		vDocRow = vDocs.Add();
		vDocRow.Doc = vObject.Ref;
		While ValueIsFilled(vObject.ParentDoc) Do
			vFindDoc = vDocs.Find(vObject.ParentDoc,"Doc");
			If ValueIsFilled(vFindDoc) then
				Break;
			Else
				vDocRow = vDocs.Add();
				vDocRow.Doc = vObject.ParentDoc;
				vObject = vObject.ParentDoc; 
			EndIf;
		EndDo;	
		vQuery = New Query;
		vQuery.Text = 
		"SELECT TOP 5
		|	SUM(Orders.Sum) AS Sum,
		|	Orders.Type AS Type,
		|	Orders.Service AS Service,
		|	Orders.PointInTime AS PointInTime
		|FROM
		|	Document.Order AS Orders
		|WHERE
		|	Orders.ParentDoc IN(&ParentDoc)
		|	AND NOT Orders.Status.isOrderCancel
		|	AND NOT Orders.DeletionMark
		|
		|GROUP BY
		|	Orders.Type,
		|	Orders.Service,
		|	Orders.PointInTime
		|
		|ORDER BY
		|	Orders.PointInTime DESC";
		vQuery.SetParameter("ParentDoc", vDocs.UnloadColumn("Doc"));	
		vQueryResult = vQuery.Execute();	
		vSelectionDetailRecords = vQueryResult.Select();
		TOrders = "";	
		While vSelectionDetailRecords.Next() Do
			TOrders = TOrders + "• " + ?(ValueIsFilled(vSelectionDetailRecords.Service), String(vSelectionDetailRecords.Service), String(vSelectionDetailRecords.Type)) + " - " + vSelectionDetailRecords.Sum + Chars.LF;
		EndDo;
		TOrders = TrimAll(TOrders);
		Items.DecorationOrders.Title = TOrders;
		If IsBlankString(TOrders) Then
			Items.DecorationOrders.Visible = False;
		Else
			Items.DecorationOrders.Visible = True;
		EndIf;
	Else
		TOrders = "";	
		Items.DecorationOrders.Title = TOrders;
		Items.DecorationOrders.Visible = False;
	EndIf;	
EndProcedure // FillOrders

// -----------------------------------------------------------------------------
&AtClient
Procedure OrdersClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If IsBlankString(TOrders) Then
		vParam = New Structure();
		vParam.Insert("basis", Object.Ref);
		OpenForm("Document.Order.ObjectForm", vParam, ThisForm, True);	
	Else	
		vParam = New Structure;
		vParam.Insert("ParentDoc", Object.Ref);
		OpenForm("Document.Order.ListForm", vParam, ThisForm, True);
	EndIf;
EndProcedure // OrdersClick

// -----------------------------------------------------------------------------
&AtClient
Procedure NewOrder(pCommand)
	If ValueIsFilled(Object.Ref) Then
		vParam = New Structure();
		vParam.Insert("basis", Object.Ref);
		OpenForm("Document.Order.ObjectForm", vParam, ThisForm, True);	
	EndIf;
EndProcedure // NewOrder

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	If Not FunctionsAndPrintFormsWereLoaded Then
		FillFunctionsButton();
		FillPrintingButton();
		FunctionsAndPrintFormsWereLoaded = True;
	EndIf;
	// Notify changes in the accounts subsystem
	Notify("Subsystem.Accounts.Changed");
EndProcedure // AfterWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure Post(pCommand)
	If ThisForm.ReadOnly Then
		Return;
	EndIf;
	// Clear messages left from previous run
	ClearMessages();
	// Check attributes
	If Not CheckAttributes() Then
		Return;
	EndIf;
	// Check user PIN if necessary
	If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
		OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "Write"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
		Return;
	EndIf;
	EmployeePINCodeChecked = False;
	// Do write procedure
	#If Not WebClient And Not MobileClient Then
		Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 10, NStr("en='Posting...';ru='Проводка документа...';de='Ausführen des Dokuments...'"), PictureLib.LongOperation); 
	#EndIf
	vWarning = "";
	vResult = WriteAtServer(, vWarning, True);
	If Not IsBlankString(vWarning) Then
		tcCommonFunctionOnClientServer.TextMessage(vWarning);
	EndIf;		
	If ValueIsFilled(vResult) And vResult <> "Error" Then
		#If ThickClientOrdinaryApplication Then
			ShowMessageBox(Undefined,NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
		#Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
		#EndIf
	ElsIf Not ValueIsFilled(vResult) Then
		#If Not WebClient And Not MobileClient Then
			Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 90, NStr("en='Posting...';ru='Проводка документа...';de='Ausführen des Dokuments...'"), PictureLib.LongOperation); 
		#EndIf
		AfterWrite(New Structure());
		// Remove form close button
		ThisForm.ShowCloseButton = False;
		// Notify changes
		If Object.DoCharging Then
			Notify("Subsystem.Accounts.Changed", Object.Ref);
		EndIf;
		Notify("Document.ResourceReservation.Write", Object.Ref, ThisForm);
		IsNew = False;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Documents posting error!';ru='Ошибка проводки документа!';de='Fehler bei der Durchführung des Dokuments!'"));
	EndIf;
EndProcedure // Post

// -----------------------------------------------------------------------------
&AtClient
Procedure PostAndClose(pCommand)
	If ThisForm.ReadOnly Then
		Return;
	EndIf;
	// Clear messages left from previous run
	ClearMessages();
	// Check attributes
	If Not CheckAttributes() Then
		Return;
	EndIf;
	// Check user PIN if necessary
	If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
		OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "WriteAndClose"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
		Return;
	EndIf;
	EmployeePINCodeChecked = False;
	// Do write procedure
	#If Not WebClient And Not MobileClient Then
		Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 10, NStr("en='Posting...';ru='Проводка документа...';de='Ausführen des Dokuments...'"), PictureLib.LongOperation); 
	#EndIf
	vWarning = "";
	vResult = WriteAtServer(, vWarning);
	If Not IsBlankString(vWarning) Then
		tcCommonFunctionOnClientServer.TextMessage(vWarning);
	EndIf;		
	If ValueIsFilled(vResult) And vResult <> "Error" Then
		#If ThickClientOrdinaryApplication Then
			ShowMessageBox(Undefined,NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
		#Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
		#EndIf
	ElsIf Not ValueIsFilled(vResult) Then
		#If Not WebClient And Not MobileClient Then
			Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 90, NStr("en='Posting...';ru='Проводка документа...';de='Ausführen des Dokuments...'"), PictureLib.LongOperation); 
		#EndIf
		AfterWrite(New Structure());
		IsOnCloseForm = True;
		// Notify changes in the accounts subsystem
		If Object.DoCharging Then
			Notify("Subsystem.Accounts.Changed", Object.Ref);
		EndIf;
		Notify("Document.ResourceReservation.Write", Object.Ref, ThisForm);
		Close();
	EndIf;
EndProcedure // PostAndClose

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesRemarksOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Object.Services.FindByID(CurService);
	If vCurData <> Undefined Then
		OpenForm("CommonForm.tcInputText", New Structure("Text", TrimR(vCurData.Remarks)), ThisForm, , , , New NotifyDescription("ServiceRemarksAfterEdit", ThisForm), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // ServicesRemarksOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceRemarksAfterEdit(pText, pExtraParams) Export
	If pText <> Undefined Then
		vCurData = Object.Services.FindByID(CurService);
		If vCurData <> Undefined Then
			vCurData.Remarks = TrimR(pText);
		EndIf;
	EndIf;
EndProcedure // ServiceRemarksAfterEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesRemarksStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Object.Services.FindByID(CurService);
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.Service) Then
			vComposition = TrimAll(tcOnServer.cmGetAttributeByRef(vCurData.Service, "Composition"));
			If Not IsBlankString(vComposition) Then
				vCurData.Remarks = vComposition;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ServicesRemarksStartChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesPriceOnChangeAtServer(pRowID)
	If pRowID <> Undefined Then
		vRow = Object.Services.FindByID(pRowID);
		vObj = FormAttributeToValue("Object");
		cmPriceOnChange(vRow.Price, vRow.Quantity, vRow.Sum, vRow.VATRate, vRow.VATSum, vRow.AccountingDate);
		vRow.BaseCurrencyPrice = Round(cmConvertCurrencies(vRow.Price, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, 
												  vObj.Hotel.BaseCurrency, 
												  1, 
												  ?(ValueIsFilled(vRow.AccountingDate), vRow.AccountingDate, vObj.ExchangeRateDate), vObj.Hotel), 2);
		vObj.pmCalculateServiceDiscounts(vRow);
		vObj.pmCalculateServiceCommissions(vRow);
		If Not vRow.IsManual Then
			vRow.IsManualPrice = True;
		EndIf;
		vRow.SumWithDiscount = vRow.Sum - vRow.DiscountSum;
		CalculateTotalServices();
	EndIf;
EndProcedure // ServicesPriceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesPriceOnChange(pItem)
	ServicesPriceOnChangeAtServer(CurService);
EndProcedure // ServicesPriceOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesSumOnChangeAtServer(pRowID)
	If pRowID <> Undefined Then
		vRow = Object.Services.FindByID(pRowID);
		vObj = FormAttributeToValue("Object");
		cmSumOnChange(vRow.Service, vRow.Price, vRow.Quantity, vRow.Sum, vRow.VATRate, vRow.VATSum, , vRow.AccountingDate);
		If vRow.IsResourceRevenue And ValueIsFilled(vRow.Service) Then
			If vRow.Service.IsPricePerMinute Then
				vRow.HoursRented = vRow.Quantity/60;
			Else
				vRow.HoursRented = vRow.Quantity;
			EndIf;
		EndIf;
		vObj.pmCalculateServiceDiscounts(vRow);
		vObj.pmCalculateServiceCommissions(vRow);
		If Not vRow.IsManual Then
			vRow.IsManualPrice = True;
		EndIf;
		vRow.SumWithDiscount = vRow.Sum - vRow.DiscountSum;
		CalculateTotalServices();
	EndIf;
EndProcedure // ServicesSumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesSumOnChange(pItem)
	ServicesSumOnChangeAtServer(CurService);
EndProcedure // ServicesSumOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesDiscountOnChangeAtServer(pRowID)
	If pRowID <> Undefined Then
		vRow = Object.Services.FindByID(pRowID);
		vObj = FormAttributeToValue("Object");
		vRow.BaseCurrencyPrice = Round(cmConvertCurrencies(vRow.Price, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, vObj.Hotel.BaseCurrency, 1, ?(ValueIsFilled(vRow.AccountingDate), vRow.AccountingDate, vObj.ExchangeRateDate), vObj.Hotel), 2);
		vObj.pmCalculateServiceDiscounts(vRow);
		vObj.pmCalculateServiceCommissions(vRow);
		If Not vRow.IsManual Then
			vRow.IsManualPrice = True;
			vRow.DiscountIsChanged = True;
		EndIf;
		vRow.SumWithDiscount = vRow.Sum - vRow.DiscountSum;
		CalculateTotalServices();
	EndIf;
EndProcedure // ServicesDiscountOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesDiscountOnChange(pItem)
	ServicesDiscountOnChangeAtServer(CurService);
EndProcedure // ServicesDiscountOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesDiscountSumOnChangeAtServer(pRowID)
	If pRowID <> Undefined Then
		vRow = Object.Services.FindByID(pRowID);
		vObj = FormAttributeToValue("Object");
		vRow.VATDiscountSum = cmCalculateVATSum(vRow.VATRate, vRow.DiscountSum, vRow.AccountingDate);
		vObj.pmCalculateServiceCommissions(vRow);
		If Not vRow.IsManual Then
			vRow.IsManualPrice = True;
			vRow.DiscountIsChanged = True;
		EndIf;
		vRow.SumWithDiscount = vRow.Sum - vRow.DiscountSum;
		CalculateTotalServices();
	EndIf;
EndProcedure // ServicesDiscountSumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesDiscountSumOnChange(pItem)
	ServicesDiscountSumOnChangeAtServer(CurService);
EndProcedure // ServicesDiscountSumOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesAgentCommissionOnChangeAtServer(pRowID)
	If pRowID <> Undefined Then
		vRow = Object.Services.FindByID(pRowID);
		vObj = FormAttributeToValue("Object");
		vObj.pmCalculateServiceCommissions(vRow);
		If Not vRow.IsManual Then
			vRow.IsManualPrice = True;
			vRow.CommissionIsChanged = True;
		EndIf;
	EndIf;
EndProcedure // ServicesAgentCommissionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesAgentCommissionOnChange(pItem)
	ServicesAgentCommissionOnChangeAtServer(CurService);
EndProcedure // ServicesAgentCommissionOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesCommissionSumOnChangeAtServer(pRowID)
	If pRowID <> Undefined Then
		vRow = Object.Services.FindByID(pRowID);
		vRow.VATCommissionSum = cmCalculateVATSum(vRow.VATRate, vRow.CommissionSum, vRow.AccountingDate);
		If Not vRow.IsManual Then
			vRow.IsManualPrice = True;
			vRow.CommissionIsChanged = True;
		EndIf;
	EndIf;
EndProcedure // ServicesCommissionSumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesCommissionSumOnChange(pItem)
	ServicesCommissionSumOnChangeAtServer(CurService);
EndProcedure // ServicesCommissionSumOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesVATRateOnChangeAtServer(pRowID)
	If pRowID <> Undefined Then
		vRow = Object.Services.FindByID(pRowID);
		vObj = FormAttributeToValue("Object");
		vRow.VATSum = cmCalculateVATSum(vRow.VATRate, vRow.Sum, vRow.AccountingDate);
		vRow.VATDiscountSum = cmCalculateVATSum(vRow.VATRate, vRow.DiscountSum, vRow.AccountingDate);
		vObj.pmCalculateServiceCommissions(vRow);
		If Not vRow.IsManual Then
			vRow.IsManualPrice = True;
		EndIf;
		CalculateTotalServices();
	EndIf;
EndProcedure // ServicesVATRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesVATRateOnChange(pItem)
	ServicesVATRateOnChangeAtServer(CurService);
EndProcedure // ServicesVATRateOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ChargingFolioOnChangeAtServer()
	If ValueIsFilled(Object.ChargingFolio) Then
		vObj = FormAttributeToValue("Object");
		vObj.FolioCurrency = vObj.ChargingFolio.FolioCurrency;
		vObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vObj.Hotel, vObj.ReportingCurrency, vObj.ExchangeRateDate);
		vObj.pmCalculateServices();
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	// Calculate totals
	CalculateTotalServices();
EndProcedure // ChargingFolioOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingFolioOnChange(pItem)
	ChargingFolioOnChangeAtServer();
EndProcedure // ChargingFolioOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure OwnerOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.Owner) Then
		If TypeOf(vObj.Owner) = Type("CatalogRef.Contracts") Then
			If ValueIsFilled(vObj.Owner.Company) Then
				vObj.Company = vObj.Owner.Company;
			EndIf;
		EndIf;
	EndIf;
	vObj.pmCalculateServices();
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	CalculateTotalServices();
EndProcedure // OwnerOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OwnerOnChange(pItem)
	OwnerOnChangeAtServer();
EndProcedure // OwnerOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ExchangeRateDateOnChangeAtServer()
	If ValueIsFilled(Object.ExchangeRateDate) Then
		vObj = FormAttributeToValue("Object");
		vObj.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vObj.Hotel, vObj.ReportingCurrency, vObj.ExchangeRateDate);
		vObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vObj.Hotel, vObj.FolioCurrency, vObj.ExchangeRateDate);
		// Automatic services list calculation	
		vObj.pmCalculateServices();
		// Recalculate manual services
		For Each vSrvRow In vObj.Services Do
			If vSrvRow.IsManual Then
				// Recalculate base currency price
				vSrvRow.BaseCurrencyPrice = Round(cmConvertCurrencies(vSrvRow.Price, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, 
														  vObj.Hotel.BaseCurrency, 
														  1, 
														  ?(ValueIsFilled(vSrvRow.AccountingDate), vSrvRow.AccountingDate, vObj.ExchangeRateDate), vObj.Hotel), 2);
				// Calculate discounts if applicable
				vObj.pmCalculateServiceDiscounts(vSrvRow);
			EndIf;
		EndDo;
		// Recalculate service items services
		For Each vSIRow In vObj.ServiceItems Do
			vSrvRowAccountingDate = Undefined;
			If Not IsBlankString(vSIRow.ServiceId) Then
				vSrvRow = vObj.Services.Find(vSIRow.ServiceId, "ServiceID");
				If vSrvRow <> Undefined Then
					vSrvRowAccountingDate = vSrvRow.AccountingDate;
				EndIf;
			EndIf;
			
			// Recalculate base currency price
			vSIRow.BaseCurrencyPrice = Round(cmConvertCurrencies(vSIRow.Price, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, 
													  vObj.Hotel.BaseCurrency, 
													  1, 
													  ?(ValueIsFilled(vSrvRowAccountingDate), vSrvRowAccountingDate, vObj.ExchangeRateDate), vObj.Hotel), 2);
		EndDo;
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		CalculateTotalServices();
	EndIf;
EndProcedure // ExchangeRateDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ExchangeRateDateOnChange(pItem)
	ExchangeRateDateOnChangeAtServer();
EndProcedure // ExchangeRateDateOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesAfterDeleteRowAtServer()
	// Delete service items for the deleted row
	i = 0;
	While i < Object.ServiceItems.Count() Do
		vSIRow = Object.ServiceItems.Get(i);
		vRows = Object.Services.FindRows(New Structure("ServiceId", vSIRow.ServiceId));
		If vRows.Count() = 0 Then
			Object.ServiceItems.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Calculate totals
	CalculateTotalServices();
EndProcedure // ServicesAfterDeleteRowAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesAfterDeleteRow(pItem)
	ServicesAfterDeleteRowAtServer();
EndProcedure // ServicesAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesOnActivateRow(pItem)
	If IsInServicesOnActivateRow Then
		Return;
	EndIf;
	IsInServicesOnActivateRow = True;
	CurService = Items.Services.CurrentRow;
	If CurService <> Undefined Then
		vRow = Object.Services.FindByID(CurService);
		If vRow <> Undefined Then
			vFilter = New Structure();	
			vFilter.Insert("ServiceId", vRow.ServiceId);	
			Items.ServiceItems.RowFilter = New FixedStructure(vFilter);	
			// Recalculate items totals
			RecalculateServiceItemsTotalsAtClient(vRow);
		EndIf;
	EndIf;
	IsInServicesOnActivateRow = False;
EndProcedure // ServicesOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateServiceItemsTotalsAtClient(pCurSrv)
	vSumTotals = 0;
	vCostSumTotals = 0;
	If pCurSrv <> Undefined Then
		vCurItems = Object.ServiceItems.FindRows(New Structure("ServiceId", pCurSrv.ServiceId));
		For Each vCurItem In vCurItems Do
			vSumTotals = vSumTotals + vCurItem.Sum;
			vCostSumTotals = vCostSumTotals + vCurItem.CostSum;
		EndDo;
	EndIf;
	Items.ServiceItemsSum.FooterText = FormatSumAtServer(vSumTotals, Object.FolioCurrency);
	Items.ServiceItemsCostSum.FooterText = FormatSumAtServer(vCostSumTotals, Object.FolioCurrency);
EndProcedure // RecalculateServiceItemsTotalsAtClient

// -----------------------------------------------------------------------------
&AtServerNoContext
Function FormatSumAtServer(pSum, pCurrency)
	Return cmFormatSum(pSum, pCurrency);
EndFunction // FormatSumAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsOnStartEdit(pItem, pNewRow, pClone)
	vCurData = pItem.CurrentData;
	If vCurData <> Undefined Then
		If pNewRow Then
			vCurService = Object.Services.FindByID(CurService);
			If vCurService <> Undefined Then
				vCurData.ServiceId = vCurService.ServiceId;
			EndIf;
			vCurData.ServiceItem = PredefinedValue("Catalog.ServiceItems.EmptyRef");
		EndIf;
		If vCurData.ServiceItem <> Undefined Then
			Items.ServiceItemsServiceItem.ChooseType = False;
			Items.ServiceItemsServiceItem.ChoiceButton = True;
			Items.ServiceItemsServiceItem.DropListButton = Undefined;
		Else
			Items.ServiceItemsServiceItem.ChooseType = True;
			Items.ServiceItemsServiceItem.ChoiceButton = True;
			Items.ServiceItemsServiceItem.DropListButton = False;
		EndIf;
	EndIf;
EndProcedure // ServiceItemsOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsServiceItemOnChange(pItem)
	vCurRow = Items.ServiceItems.CurrentData;
	If vCurRow <> Undefined Then
		vServiceItem = vCurRow.ServiceItem;
		If vServiceItem <> Undefined Then
			Items.ServiceItemsServiceItem.ChooseType = False;
			Items.ServiceItemsServiceItem.ChoiceButton = True;
			Items.ServiceItemsServiceItem.DropListButton = False;
			If TypeOf(vServiceItem) = Type("CatalogRef.ServiceItems") Then
				If ValueIsFilled(vServiceItem) Then
					vServiceItemArr = tcOnServer.cmGetAtributeAsArray(vServiceItem);
					vCurRow.Output = vServiceItemArr.Output;
					If vCurRow.Quantity = 0 Then
						vCurRow.Quantity = vServiceItemArr.Quantity;
					EndIf;
					If vCurRow.Quantity = 0 Then
						vCurRow.Quantity = 1;
					EndIf;
					vCurRow.Unit = vServiceItemArr.Unit;
					vCurRow.Price = Round(tcOnServer.ConvertCurrencies(vServiceItemArr.Price, vServiceItemArr.Currency, , 
					                                                   Object.FolioCurrency, Object.FolioCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
					vCurRow.Currency = Object.FolioCurrency;
					vCurRow.BaseCurrencyPrice = Round(tcOnServer.ConvertCurrencies(vServiceItemArr.Price, vServiceItemArr.Currency, , 
					                                                               tcOnServer.cmGetAttributeByRef(Object.Hotel, "BaseCurrency"), 1, Object.ExchangeRateDate, Object.Hotel), 2);
					vCurRow.CostPrice = Round(tcOnServer.ConvertCurrencies(vServiceItemArr.CostPrice, vServiceItemArr.Currency, , 
					                                                       Object.FolioCurrency, Object.FolioCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
				EndIf;
			EndIf;
		Else
			Items.ServiceItemsServiceItem.ChooseType = True;
			Items.ServiceItemsServiceItem.ChoiceButton = True;
			Items.ServiceItemsServiceItem.DropListButton = False;
			vCurRow.Currency = Object.FolioCurrency;
			vCurRow.Quantity = 1;
		EndIf;
		vCurRow.Sum = Round(vCurRow.Quantity * vCurRow.Price, 2);
		vCurRow.CostSum = Round(vCurRow.Quantity * vCurRow.CostPrice, 2);
	EndIf;
EndProcedure // ServiceItemsServiceItemOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsServiceItemClearing(pItem, pStandardProcessing)
	vCurData = Items.ServiceItems.CurrentData;
	If vCurData <> Undefined Then
		pStandardProcessing = False;
		vCurData.ServiceItem = Undefined;
		Items.ServiceItemsServiceItem.ChooseType = True;
		Items.ServiceItemsServiceItem.ChoiceButton = True;
		Items.ServiceItemsServiceItem.DropListButton = False;
	EndIf;
EndProcedure // ServiceItemsServiceItemClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsPriceOnChange(pItem)
	vCurRow = Items.ServiceItems.CurrentData;
	vCurRow.Sum = Round(vCurRow.Quantity * vCurRow.Price, 2);
	vCurRow.CostSum = Round(vCurRow.Quantity * vCurRow.CostPrice, 2);
	// Recalculate items totals
	RecalculateServiceItemsTotals();
EndProcedure // ServiceItemsPriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsQuantityOnChange(pItem)
	vCurRow = Items.ServiceItems.CurrentData;
	vCurRow.Sum = Round(vCurRow.Quantity * vCurRow.Price, 2);
	vCurRow.CostSum = Round(vCurRow.Quantity * vCurRow.CostPrice, 2);
	// Recalculate items totals
	RecalculateServiceItemsTotals();
EndProcedure // ServiceItemsQuantityOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsSumOnChange(pItem)
	vCurRow = Items.ServiceItems.CurrentData;
	If vCurRow.Price = 0 Then
		vCurRow.Price = vCurRow.Sum;
	EndIf;
	vCurRow.Quantity = Round(vCurRow.Sum / vCurRow.Price, 2);
	vCurRow.CostSum = Round(vCurRow.Quantity * vCurRow.CostPrice, 2);
	// Recalculate items totals
	RecalculateServiceItemsTotals();
EndProcedure // ServiceItemsSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsCostPriceOnChange(pItem)
	vCurRow = Items.ServiceItems.CurrentData;
	vCurRow.CostSum = Round(vCurRow.Quantity * vCurRow.CostPrice, 2);
	// Recalculate items totals
	RecalculateServiceItemsTotals();
EndProcedure // ServiceItemsCostPriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsCostSumOnChange(pItem)
	vCurRow = Items.ServiceItems.CurrentData;
	If vCurRow.Quantity = 0 Then
		vCurRow.Quantity = 1;
	EndIf;
	vCurRow.CostPrice = Round(vCurRow.CostSum / vCurRow.Quantity, 2);
	// Recalculate items totals
	RecalculateServiceItemsTotals();
EndProcedure // ServiceItemsCostSumOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateServiceItemsTotals()
	vSumTotals = 0;
	vCostSumTotals = 0;
	If CurService <> Undefined Then
		vCurSrv = Object.Services.FindById(CurService);
		If vCurSrv <> Undefined Then
			vCurItems = Object.ServiceItems.FindRows(New Structure("ServiceId", vCurSrv.ServiceId));
			For Each vCurItem In vCurItems Do
				vSumTotals = vSumTotals + vCurItem.Sum;
				vCostSumTotals = vCostSumTotals + vCurItem.CostSum;
			EndDo;
			If vCurItems.Count() > 0 And vSumTotals <> 0 Then
				vCurSrv.Price = vSumTotals;
				ServicesPriceOnChangeAtServer(CurService);
			Endif;
		EndIf;
		Items.ServiceItemsSum.FooterText = cmFormatSum(vSumTotals, Object.FolioCurrency);
		Items.ServiceItemsCostSum.FooterText = cmFormatSum(vCostSumTotals, Object.FolioCurrency);
	EndIf;
EndProcedure // RecalculateServiceItemsTotals

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsAfterDeleteRow(pItem)
	// Recalculate items totals
	RecalculateServiceItemsTotals();
EndProcedure // ServiceItemsAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure DateFromOnChange(pItem)
	If DateFrom < '20000101' Or DateFrom > '21000101' Then
		DateFrom = BegOfDay(CurrentDate());
	EndIf;
	Object.DateTimeFrom = BegOfDay(DateFrom) + (TimeFrom - BegOfDay(TimeFrom));
	DateTimeFromOnChange(Items.DateTimeFrom);
	FillMainResourcePeriod();
	// Ask user if it is necessary to change service accounting date
	vManualServices = Object.Services.FindRows(New Structure("IsManual", True));
	If vManualServices.Count() > 0 Then
		ShowQueryBox(New NotifyDescription("AfterUserReplyAboutChangeDate", ThisForm), NStr("en='Need to change the accounting date on the document lines?'; ru='Нужно изменить учетную дату в строках документа?'; de='Müssen Sie das Rechnungsdatum in den Zeilen des Dokuments ändern?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	Else
		// Save current accounting date
		OldAccountingDate = BegOfDay(Object.DateTimeFrom);
	EndIf;
EndProcedure // DateFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterUserReplyAboutChangeDate(vAnswer, pExtraParams) Export
	If vAnswer = DialogReturnCode.Yes Then
		UpdateAccountingDateAtServer();
	EndIf;
	// Save current accounting date
	OldAccountingDate = BegOfDay(Object.DateTimeFrom);
EndProcedure // AfterUserReplyAboutChangeDate

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateAccountingDateAtServer()
	vShift = BegOfDay(Object.DateTimeFrom) - OldAccountingDate;
	For Each vSrvRow In Object.Services Do
		If vSrvRow.IsManual Then
			vSrvRow.AccountingDate = vSrvRow.AccountingDate + vShift;
			vSrvRow.DateTimeFrom = vSrvRow.DateTimeFrom + vShift;
			vSrvRow.DateTimeTo = vSrvRow.DateTimeTo + vShift;
		EndIf;
	EndDo;
EndProcedure // UpdateAccountingDateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure TimeFromOnChange(pItem)
	Object.DateTimeFrom = BegOfDay(DateFrom) + (TimeFrom - BegOfDay(TimeFrom));
	DateTimeFromOnChange(Items.DateTimeFrom);
	FillMainResourcePeriod();
EndProcedure // TimeFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DateToOnChange(pItem)
	If DateTo < '20000101' Or DateTo > '21000101' Then
		DateTo = BegOfDay(CurrentDate());
	EndIf;
	Object.DateTimeTo = BegOfDay(DateTo) + (TimeTo - BegOfDay(TimeTo));
	DateTimeToOnChange(Items.DateTimeTo);
	FillMainResourcePeriod();
EndProcedure // DateToOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TimeToOnChange(pItem)
	Object.DateTimeTo = BegOfDay(DateTo) + (TimeTo - BegOfDay(TimeTo));
	DateTimeToOnChange(Items.DateTimeTo);
	FillMainResourcePeriod();
EndProcedure // TimeToOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationAsTimeOnChange(pItem)
	If DurationAsTime = '00010101' Then
		DurationAsTime = DurationAsTime + 3600;
	EndIf;
	Object.Duration = Hour(DurationAsTime) + Round(Minute(DurationAsTime)/60, 7);
	DurationOnChange(Items.Duration);
	FillMainResourcePeriod();
EndProcedure // DurationAsTimeOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure FillMainResourcePeriod()
	DateFrom = BegOfDay(Object.DateTimeFrom);
	TimeFrom = '00010101' + (Object.DateTimeFrom - BegOfDay(Object.DateTimeFrom));
	PeriodFromDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(Object.DateTimeFrom)));
	DateTo = BegOfDay(Object.DateTimeTo);
	TimeTo = '00010101' + (Object.DateTimeTo - BegOfDay(Object.DateTimeTo));
	PeriodToDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(Object.DateTimeTo)));
	DurationAsTime = '00010101' + (cm0SecondShift(Object.DateTimeTo) - cm0SecondShift(Object.DateTimeFrom));
EndProcedure // FillMainResourcePeriod

// -----------------------------------------------------------------------------
&AtServer
Procedure GuaranteeTypeOnChangeAtServer()
	vDoSearch = False;
	vIsGuaranteed = True;
	If ValueIsFilled(Object.GuaranteeType) Then
		If ValueIsFilled(Object.ResourceReservationStatus) And Not Object.ResourceReservationStatus.IsGuaranteed Then
			vDoSearch = True;
			vIsGuaranteed = True;
		EndIf;
	EndIf;
	If vDoSearch Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ResourceReservationStatuses.Ref AS Ref
		|FROM
		|	Catalog.ResourceReservationStatuses AS ResourceReservationStatuses
		|WHERE
		|	ResourceReservationStatuses.IsGuaranteed = &qIsGuaranteed
		|	AND ResourceReservationStatuses.IsActive
		|	AND NOT ResourceReservationStatuses.DeletionMark
		|	AND NOT ResourceReservationStatuses.IsFolder
		|	AND (ResourceReservationStatuses.Hotel = &qHotel
		|			OR ResourceReservationStatuses.Hotel = &qEmptyHotel)
		|
		|ORDER BY
		|	ResourceReservationStatuses.SortCode,
		|	ResourceReservationStatuses.Code";
		vQry.SetParameter("qIsGuaranteed", vIsGuaranteed);
		vQry.SetParameter("qHotel", Object.Hotel);
		vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
		vStatuses = vQry.Execute().Unload();
		If vStatuses.Count() > 0 Then
			Object.ResourceReservationStatus = vStatuses.Get(0).Ref;
			ResourceReservationStatusOnChangeAtServer();
		EndIf;
	EndIf;
EndProcedure // GuaranteeTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GuaranteeTypeOnChange(pItem)
	GuaranteeTypeOnChangeAtServer();
EndProcedure // GuaranteeTypeOnChange

// --------------------------------------------------------------------------------
&AtServerNoContext
Function IsFileEditable(pExtension)
	Return cmIsFileEditable(pExtension);
EndFunction // IsFileEditable

// -----------------------------------------------------------------------------
&AtServer
Function CreateGroupResumeAtServer()
	// Try to find group resume document in group attachments
	vFileType = "docx";
	// Check if MS Word is installed
	#IF NOT WebClient AND NOT MobileClient THEN
		vWSH = New COMObject("WScript.Shell");
		vAppName = vWSH.RegRead("HKEY_CLASSES_ROOT\\.doc\\");
		If Find(vAppName, "OpenOffice.Doc") > 0 Then
			vFileType = "odt";
		EndIf;
	#ENDIF
	// Group object
	vGroupObj = Object.GuestGroup.GetObject();
	// Get group resume document
	vRow = Undefined;
	vRows = vGroupObj.pmGetGuestGroupResumeRecords();
	If vRows.Count() > 0 Then
		// Get group resume row
		vRow = vRows.Get(0);
	Else
		// Create group resume document and add record for it
		vRcdMgr = InformationRegisters.GuestGroupAttachments.CreateRecordManager();
		vRcdMgr.GuestGroup = Object.GuestGroup;
		vRcdMgr.Period = CurrentSessionDate();
		vRcdMgr.Author = SessionParameters.CurrentUser;
		vRcdMgr.AttachmentStatus = Enums.AttachmentStatuses.Ready;
		vRcdMgr.AttachmentType = Enums.AttachmentTypes.GroupResume;
		vRcdMgr.Remarks = Format(Object.GuestGroup.Code, "ND=12; NFD=0; NG=") + " " + TrimAll(Object.GuestGroup.Description);
		vRcdMgr.FileLoadTime = CurrentSessionDate();
		vRcdMgr.FileLastChangeTime = CurrentSessionDate();
		vRcdMgr.FileName = "GroupResume" + TrimAll(SessionParameters.CurrentLanguage.Code) + "." + vFileType;
		// Build file object
		vResumeFilePath = TempFilesDir() + vRcdMgr.FileName;
		// Get file template
		vFileBinData = Catalogs.GuestGroups.GetTemplate("GroupResume" + TrimAll(SessionParameters.CurrentLanguage.Code) + vFileType);
		vFileBinData.Write(vResumeFilePath);
		// Fill document fields
		vGroupObj.pmGenerateGuestGroupResume(vResumeFilePath, vFileType);
		// Read file data back
		vFileBinData = New BinaryData(vResumeFilePath);
		vRcdMgr.ExtFile = New ValueStorage(vFileBinData);
		// Save row
		vRcdMgr.Write(True);
		// Get row back 
		vRows = vGroupObj.pmGetGuestGroupResumeRecord(vRcdMgr.Period);
		// Get selected row
		If vRows.Count() > 0 Then
			vRow = vRows.Get(0);
		EndIf;
	EndIf;
	If vRow <> Undefined Then
		// Read file binary data from the register
		vReader = InformationRegisters.GuestGroupAttachments.CreateRecordManager();
		vReader.GuestGroup = vRow.GuestGroup;
		vReader.Period = vRow.Period;
		vReader.Read();
		If vReader.Selected() Then
			vFileName = TrimAll(vReader.FileName);
			vBinary = vReader.ExtFile.Get();
			vTempAddr = PutToTempStorage(vBinary);
			Return New Structure("FileName, FileTempStorageAddress", vFileName, vTempAddr);
		EndIf;
	EndIf;
	Return Undefined;
EndFunction // CreateGroupResumeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateGroupResume(pCommand)
	If (WasPosted = False Or ThisForm.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "CreateGroupResume"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vResult = ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting));
		If Not vResult Then
			Return;
		EndIf;
	EndIf;
	vParam = CreateGroupResumeAtServer();
	If vParam <> Undefined Then
		BeginAttachingFileSystemExtension(New NotifyDescription("OpenFileAttachingFileSystemExtensionResult", ThisForm, vParam));
	EndIf;
EndProcedure // CreateGroupResume

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		// Getting temp files dir
		BeginGettingTempFilesDir(New NotifyDescription("OpenFileGettingTempFilesDirCompleted", ThisForm, pParam));
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("OpenFileFileSystemExtensionInstallCompleted", ThisForm));
	EndIf;
EndProcedure // OpenFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("OpenFileInstallingFileSystemExtensionResult", ThisForm));
EndProcedure // OpenFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileRunningApplicationCompleted(pReturnCode, pLocalFullFileName) Export
	// If file is editable then ask user to save it back
	vFile = New File(pLocalFullFileName);
	If IsFileEditable(vFile.Extension) Then
		ShowQueryBox(New NotifyDescription("AfterClosedQueryBox", ThisForm, pLocalFullFileName),
		             NStr("en='Save document changes to the database?';ru='Сохранить измененный документ в базу данных?';de='Das geänderte Dokument in der Datenbank speichern?'"), QuestionDialogMode.YesNo);
	EndIf;
EndProcedure // OpenFileRunningApplicationCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileGettingFilesCompleted(pTransferredFiles, pTempFilesDir) Export
	vLocalFullFileName = pTransferredFiles.Get(0).Name;
	// Open temp file in application
	BeginRunningApplication(New NotifyDescription("OpenFileRunningApplicationCompleted", ThisForm, vLocalFullFileName), vLocalFullFileName, pTempFilesDir, False);
EndProcedure // OpenFileGettingFilesCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileGettingTempFilesDirCompleted(pTempFilesDir, pParam) Export
	// Build local temp file name
	vLocalFullFileName = pTempFilesDir + pParam.FileName;
	// Get temp storage address with file data
	vTemStorageAddress = pParam.FileTempStorageAddress;
	// Create array of files to transfer from server to the client
	vFilesToBeObtained = New Array();
	vFileToBeObtained = New TransferableFileDescription(vLocalFullFileName, vTemStorageAddress);
	vFilesToBeObtained.Add(vFileToBeObtained);
	BeginGettingFiles(New NotifyDescription("OpenFileGettingFilesCompleted", ThisForm, pTempFilesDir), vFilesToBeObtained, , False);
EndProcedure // OpenFileGettingTempFilesDirCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileInstallingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		// Getting temp files dir
		BeginGettingTempFilesDir(New NotifyDescription("OpenFileGettingTempFilesDirCompleted", ThisForm, pParam));
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // OpenFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterClosedQueryBox(pResult, pFullFileName) Export
	If pResult = DialogReturnCode.Yes Then
		vFile = New File(pFullFileName);
		vFilesArray = New Array();
		vFileDescription = New TransferableFileDescription(pFullFileName);
		vFilesArray.Add(vFileDescription);
		BeginPuttingFiles(New NotifyDescription("UpdatedFileDownloadToServerCompleted", ThisForm), vFilesArray, , False);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdatedFileDownloadToServerCompletedAtServer(pTempStorageFileAddress, pParam)
	vBinaryData = GetFromTempStorage(pTempStorageFileAddress);
	AfterClosedQueryBoxAtServer(vBinaryData);
EndProcedure // UpdatedFileDownloadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterClosedQueryBoxAtServer(pBinaryData) 
	// Get group resume document
	vRow = Undefined;
	vGroupObj = Object.GuestGroup.GetObject();
	vRows = vGroupObj.pmGetGuestGroupResumeRecords();
	If vRows.Count() > 0 Then
		// Get group resume row
		vRow = vRows.Get(0);
		If vRow <> Undefined Then
			vRcd = InformationRegisters.GuestGroupAttachments.CreateRecordManager();
			FillPropertyValues(vRcd, vRow);
			vRcd.ExtFile = New ValueStorage(pBinaryData);
			vRcd.FileLastChangeTime = CurrentSessionDate();
			vRcd.Write();
		EndIf;
	EndIf;
EndProcedure // AfterClosedQueryBoxAtServer

// --------------------------------------------------------------------------------
&AtClient 
Procedure UpdatedFileDownloadToServerCompleted(pTransferredFiles, pParam) Export
	vTempStorageFileAddress = pTransferredFiles.Get(0).Location;
	UpdatedFileDownloadToServerCompletedAtServer(vTempStorageFileAddress, pParam);
EndProcedure // UpdatedFileDownloadToServerCompleted

// --------------------------------------------------------------------------------
&AtServer
Procedure ChargingFolioClearingAtServer()
	// Create new folio to charge document services to
	vObj = FormAttributeToValue("Object");
	vObj.ChargingFolio = Undefined;
	vObj.pmCreateFolio();
	ValueToFormAttribute(vObj, "Object");
	ChargingFolioOnChangeAtServer();
EndProcedure // ChargingFolioClearingAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ChargingFolioClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	// Create new folio to charge document services to
	ChargingFolioClearingAtServer();
EndProcedure // ChargingFolioClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure MenuItemsSelection(pCommand)
	vRowID = CurService;
	If vRowID <> Undefined Then
		vRow = Object.Services.FindByID(vRowID);
		If vRow <> Undefined Then
			OpenForm("Catalog.ServiceItems.ChoiceForm", New Structure("CloseOnChoice", False), ThisForm, vRow.ServiceID, , , , FormWindowOpeningMode.LockOwnerWindow);
		EndIf;	
	EndIf;	
EndProcedure // MenuItemsSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("CatalogRef.ServiceItems") Then
		vRowID = CurService;
		If vRowID <> Undefined Then
			vRow = Object.Services.FindByID(vRowID);
			If vRow <> Undefined Then
				vSIRow = Object.ServiceItems.Add();
				vSIRow.ServiceId = vRow.ServiceId;
				vSIRow.ServiceItem = pSelectedValue;
				vServiceItemArr = tcOnServer.cmGetAtributeAsArray(pSelectedValue);
				vSIRow.Output = vServiceItemArr.Output;
				If vSIRow.Quantity = 0 Then
					vSIRow.Quantity = vServiceItemArr.Quantity;
				EndIf;
				vSIRow.Unit = vServiceItemArr.Unit;
				vSIRow.Price = Round(tcOnServer.ConvertCurrencies(vServiceItemArr.Price, vServiceItemArr.Currency, , 
			                                                      Object.FolioCurrency, Object.FolioCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
				vSIRow.Currency = Object.FolioCurrency;
				vSIRow.BaseCurrencyPrice = Round(tcOnServer.ConvertCurrencies(vServiceItemArr.Price, vServiceItemArr.Currency, , 
			                                                                  tcOnServer.cmGetAttributeByRef(Object.Hotel, "BaseCurrency"), 1, Object.ExchangeRateDate, Object.Hotel), 2);
				vSIRow.CostPrice = Round(tcOnServer.ConvertCurrencies(vServiceItemArr.CostPrice, vServiceItemArr.Currency, , 
			                                                          Object.FolioCurrency, Object.FolioCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
				vSIRow.Sum = Round(vSIRow.Quantity * vSIRow.Price, 2);
				vSIRow.CostSum = Round(vSIRow.Quantity * vSIRow.CostPrice, 2);
				// Recalculate items totals
				RecalculateServiceItemsTotals();
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ChoiceProcessing

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTasksPresentation()
	TTasks = "";
	If ValueIsFilled(Object.Ref) Then
		vTasks = cmGetMessagesForObject(Object.Ref);
		vGroupTasks = cmGetMessagesForObject(Object.GuestGroup);
		If vGroupTasks.Count() > 0 Then
			For Each vGroupTasksRow In vGroupTasks Do
				vTasksRow = vTasks.Add();
				FillPropertyValues(vTasksRow, vGroupTasksRow);
			EndDo;
		EndIf;
		For Each vTasksRow In vTasks Do
			TTasks = TTasks + "• " + TrimAll(vTasksRow.Remarks) + Chars.LF;
		EndDo;
	EndIf;
	TTasks = TrimAll(TTasks);
	Items.DecorationTasks.Title = TTasks;
	If IsBlankString(TTasks) Then
		Items.DecorationTasks.Visible = False;
	Else
		Items.DecorationTasks.Visible = True;
	EndIf;
EndProcedure // FillTasksPresentation

// -----------------------------------------------------------------------------
&AtClient
Procedure NewTask(Command)
	If ValueIsFilled(Object.Ref) Then
		stParam = New Structure("SetParamObject, Type", Object.Ref, PredefinedValue("Enum.MessageTypes.Task"));
		OpenForm("Document.Message.Form.tcDocumentForm", stParam);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationTasksClick(pItem)
	Task(Commands.Task);
EndProcedure // DecorationVerticalSpacingClick

// -----------------------------------------------------------------------------
&AtClient
Procedure Task(pCommand)
	stParam = New Structure("SetParamObject", Object.Ref);
	OpenForm("DataProcessor.Messages.Form.tcForm", stParam);
	Notify("DataProcessor.Messages.Form.Open", stParam);
EndProcedure // Task

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInHouseGuests(pCommand)	
	#IF NOT MobileClient THEN 
		vFrm = GetForm("Document.Accommodation.ListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisForm);
		vFrm.SelGuestGroup = Object.GuestGroup;
		vFrm.Open();
	#ELSE
		OpenForm("Document.Accommodation.Form.mcAccommodationListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisForm);	
	#ENDIF
EndProcedure // OpenInHouseGuests

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenReservations(pCommand)
	#IF NOT MobileClient THEN 
		vFrm = GetForm("Document.Reservation.ListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisForm);
		vFrm.SelGuestGroup = Object.GuestGroup;
		vFrm.Open();
	#ELSE
		OpenForm("Document.Reservation.Form.mcReservationListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisForm);	
	#ENDIF
EndProcedure // OpenReservations

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenProformaInvoiceList(pCommand)
	vFrm = GetForm("Document.ProformaInvoice.ListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisForm);
	vFrm.SelGuestGroup = Object.GuestGroup;
	vFrm.Open();
EndProcedure // OpenProformaInvoiceList

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenResourceReservations(pCommand)
	vFrm = GetForm("Document.ResourceReservation.ListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisForm);
	vFrm.Open();
EndProcedure // OpenResourceReservations

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesActivityRemarksOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Object.Services.FindByID(CurService);
	If vCurData <> Undefined Then
		OpenForm("CommonForm.tcInputText", New Structure("Text", TrimR(vCurData.ActivityRemarks)), ThisForm, , , , New NotifyDescription("ActivityRemarksAfterEdit", ThisForm), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // ServicesActivityRemarksOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure ActivityRemarksAfterEdit(pText, pExtraParams) Export
	If pText <> Undefined Then
		vCurData = Object.Services.FindByID(CurService);
		If vCurData <> Undefined Then
			vCurData.ActivityRemarks = TrimR(pText);
		EndIf;
	EndIf;
EndProcedure // ServiceRemarksAfterEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesBeforeDeleteRow(pItem, pCancel)
	pCancel = True;
	// Ask for confirmation
	ShowQueryBox(New NotifyDescription("ServicesDeleteAfterAnswer", ThisForm, New Structure("RowIDs", CurService)), NStr("en='Do you want to delete selected rows?'; ru='Удалить выделенные строки?'; de='Möchten Sie ausgewählte Zeilen löschen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
EndProcedure // ServicesBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesDeleteAfterAnswer(pReply, pExtraParams) Export
	If pReply = DialogReturnCode.Yes Then
		If pExtraParams.RowIDs <> Undefined Then
			j = 0;
			While j < pExtraParams.RowIDs.Count() Do
				vRowID = pExtraParams.RowIDs.Get(j);
				vSrvRow = Object.Services.FindByID(vRowID);
				If vSrvRow <> Undefined Then
					vServiceId = vSrvRow.ServiceId;
					Object.Services.Delete(Object.Services.IndexOf(vSrvRow));
					// Delete service items for the deleted row
					i = 0;
					While i < Object.ServiceItems.Count() Do
						vSIRow = Object.ServiceItems.Get(i);
						If vSIRow.ServiceID = vServiceId Then
							Object.ServiceItems.Delete(i);
						Else
							i = i + 1;
						EndIf;
					EndDo;
					// Mark form as modified
					ThisForm.Modified = True;
				Else
					j = j + 1;
				EndIf;
			EndDo;
			// Calculate totals
			CalculateTotalServices();
		EndIf;
	EndIf;
EndProcedure // ServicesDeleteAfterAnswer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsBeforeDeleteRow(pItem, pCancel)
	pCancel = True;
	// Ask for confirmation
	ShowQueryBox(New NotifyDescription("ServiceItemsDeleteAfterAnswer", ThisForm, New Structure("RowIDs", Items.ServiceItems.SelectedRows)), NStr("en='Do you want to delete selected rows?'; ru='Удалить выделенные строки?'; de='Möchten Sie ausgewählte Zeilen löschen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
EndProcedure // ServiceItemsBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsDeleteAfterAnswer(pReply, pExtraParams) Export
	If pReply = DialogReturnCode.Yes Then
		If pExtraParams.RowIDs <> Undefined Then
			j = 0;
			While j < pExtraParams.RowIDs.Count() Do
				vRowID = pExtraParams.RowIDs.Get(j);
				vSrvItemRow = Object.ServiceItems.FindByID(vRowID);
				If vSrvItemRow <> Undefined Then
					Object.ServiceItems.Delete(Object.ServiceItems.IndexOf(vSrvItemRow));
				Else
					j = j + 1;
				EndIf;
			EndDo;
			// Mark form as modified
			ThisForm.Modified = True;
			// Recalculate items totals
			RecalculateServiceItemsTotals();
		EndIf;
	EndIf;
EndProcedure // ServiceItemsDeleteAfterAnswer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesEventActivityOnChange(pItem)
	vCurData = Object.Services.FindByID(CurService);
	If vCurData <> Undefined Then
		If vCurData.EventActivity <> Undefined Then
			Items.ServicesEventActivity.ChooseType = False;
			Items.ServicesEventActivity.ChoiceButton = False;
			Items.ServicesEventActivity.DropListButton = True;
		Else
			Items.ServicesEventActivity.ChooseType = True;
			Items.ServicesEventActivity.ChoiceButton = True;
			Items.ServicesEventActivity.DropListButton = False;
		EndIf;
	EndIf;
EndProcedure // ServicesEventActivityOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesEventActivityClearing(pItem, pStandardProcessing)
	vCurData = Object.Services.FindByID(CurService);
	If vCurData <> Undefined Then
		pStandardProcessing = False;
		vCurData.EventActivity = Undefined;
		Items.ServicesEventActivity.ChooseType = True;
		Items.ServicesEventActivity.ChoiceButton = True;
		Items.ServicesEventActivity.DropListButton = False;
	EndIf;
EndProcedure // ServicesEventActivityClearing

// -----------------------------------------------------------------------------
&AtServer
Procedure GuestGroupOpeningAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmCreateGuestGroup();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // GuestGroupOpeningAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOpening(pItem, pStandardProcessing)
	If Not ValueIsFilled(Object.GuestGroup) Then
		pStandardProcessing = False;
		GuestGroupOpeningAtServer();
	EndIf;
EndProcedure // GuestGroupOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsOnEditEnd(pItem, pNewRow, pCancelEdit)
	// Recalculate items totals
	RecalculateServiceItemsTotals();
EndProcedure // ServiceItemsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure MoveItemUp(pCommand)
	vSelRows = New ValueList();
	For Each vRowId In Items.ServiceItems.SelectedRows Do
		vCurItemRow = Object.ServiceItems.FindByID(vRowID);
		vSelRows.Add(vRowId, Format(vCurItemRow.LineNumber, "ND=10; NFD=0; NZ=; NLZ=; NG="));
	EndDo;
	vSelRows.SortByPresentation(SortDirection.Asc);
	For Each vSelRowsItem In vSelRows Do
		vRowId = vSelRowsItem.Value;
		vCurItemRow = Object.ServiceItems.FindByID(vRowID);
		If vCurItemRow <> Undefined Then
			If vCurItemRow.LineNumber > 1 Then
				Object.ServiceItems.Move(Object.ServiceItems.IndexOf(vCurItemRow), -1);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // MoveItemUp

// -----------------------------------------------------------------------------
&AtClient
Procedure MoveItemDown(pCommand)
	vSelRows = New ValueList();
	For Each vRowId In Items.ServiceItems.SelectedRows Do
		vCurItemRow = Object.ServiceItems.FindByID(vRowID);
		vSelRows.Add(vRowId, Format(vCurItemRow.LineNumber, "ND=10; NFD=0; NZ=; NLZ=; NG="));
	EndDo;
	vSelRows.SortByPresentation(SortDirection.Desc);
	For Each vSelRowsItem In vSelRows Do
		vRowId = vSelRowsItem.Value;
		vCurItemRow = Object.ServiceItems.FindByID(vRowID);
		If vCurItemRow <> Undefined Then
			If vCurItemRow.LineNumber > 1 Then
				Object.ServiceItems.Move(Object.ServiceItems.IndexOf(vCurItemRow), 1);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // MoveItemDown

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearCreditCard(pCommand)
	Object.CreditCard = Undefined;
	CreditCardPresentation = NStr("en='<Credit card>'; ru='<Кредитная карта>'; de='<Kreditkarte>'");
	Items.ClearCreditCard.Visible = False;
	ThisForm.Modified = True;
EndProcedure // ClearCreditCard

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	vTasksStructure = GetTasksStructure();
	
	For Each vTasks In vTasksStructure Do
		If	vTasks.Value.PopUp Then
			ShowMessageBox(,vTasks.Value.Remarks,,NStr("en = 'Task'; de = 'Aufgabe'; ru = 'Задача'"));
		EndIf;
	EndDo;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtServer
Function  GetTasksStructure()
	vTasksStructure = New Structure();
	If ValueIsFilled(Object.Ref) Then
		vTasks = cmGetMessagesForObject(Object.Ref);
		vNumber = 0;
		For Each vTasksRow In vTasks Do
			vTasksStructure.Insert(TrimAll("Tasks" + vNumber), New Structure("PopUp, Remarks", vTasksRow.PopUp, vTasksRow.Remarks));
			vNumber = vNumber + 1;
		EndDo;
	EndIf;
	Return vTasksStructure;
EndFunction // GetTasksStructure

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowServiceItems(pCommand)
	Items.Pages.Visible = False;
	Items.Back.Visible = True;
	Items.ServiceItems.Visible = True;
EndProcedure // ShowServiceItems

// -----------------------------------------------------------------------------
&AtClient
Procedure Back(Command)
	Items.Pages.Visible = True;
	Items.Back.Visible = False;
	Items.ServiceItems.Visible = False;
	CurrentRow = Undefined;
EndProcedure // Back

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadCustomerContactPersonsList(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	Items.ContactPerson.ChoiceList.Clear();
	If ValueIsFilled(vObj.Customer) Then
		vCPList = vObj.Customer.GetObject().pmLoadCustomerContactPersonsList();
		If vCPList.Count() > 0 Then
			Items.ContactPerson.ChoiceListButton = True;
			Items.ContactPerson.ChoiceList.LoadValues(vCPList.UnloadValues());
		Else
			Items.ContactPerson.ChoiceListButton = False;
		EndIf;
	Else
		Items.ContactPerson.ChoiceListButton = False;
	EndIf;
EndProcedure // LoadCustomerContactPersonsList	
