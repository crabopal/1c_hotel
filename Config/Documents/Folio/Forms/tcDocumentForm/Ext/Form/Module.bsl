
#Region FormEventHandlers

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
	// Check rights to edit folio system parameters	
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	// If new
	If Not ValueIsFilled(Object.Ref) Then
		Items.BillingInstructionTemplateWarning.Visible = False;

		Items.FormOpenFolioTransactions.Visible = False;
		Items.FormOpenFolioTransactions.Enabled = False;
				
		vObj = FormAttributeToValue("Object");
		If Parameters.Property("SelHotel") Then
			vObj.Hotel = Parameters.SelHotel;
		EndIf;
		vObj.pmFillAttributesWithDefaultValues();
		vObj.Description = TrimAll(vObj.Hotel.AdditionalServicesFolioCondition);
		vParentObj = Undefined;
		If Parameters.Property("ParentObj") Then
			vParentObj = Parameters.ParentObj;
		EndIf;
		If ValueIsFilled(vParentObj) Then
			If TypeOf(vParentObj) = Type("DocumentRef.Accommodation") Or 
			   TypeOf(vParentObj) = Type("DocumentRef.Reservation") Then
				vObj.ParentDoc = vParentObj;
				vObj.DateTimeFrom = vParentObj.CheckInDate;
				vObj.DateTimeTo = vParentObj.CheckOutDate;
				vObj.Room = vParentObj.Room;
				vObj.Client = vParentObj.Guest;
				vObj.GuestGroup = vParentObj.GuestGroup;
			ElsIf TypeOf(vParentObj) = Type("DocumentRef.ResourceReservation") Then
				vObj.ParentDoc = vParentObj;
				vObj.DateTimeFrom = vParentObj.DateTimeFrom;
				vObj.DateTimeTo = vParentObj.DateTimeTo;
				vObj.Client = vParentObj.Client;
				vObj.GuestGroup = vParentObj.GuestGroup;
			ElsIf TypeOf(vParentObj) = Type("CatalogRef.Clients") Then
				vObj.Client = vParentObj;
			ElsIf TypeOf(vParentObj) = Type("CatalogRef.Customers") Then
				vObj.Customer = vParentObj;
			ElsIf TypeOf(vParentObj) = Type("CatalogRef.Contracts") Then
				vObj.Customer = vParentObj.Owner;
				vObj.Contract = vParentObj;
			ElsIf TypeOf(vParentObj) = Type("CatalogRef.GuestGroups") Then
				vObj.GuestGroup = vParentObj;
				vObj.Customer = vParentObj.Customer;
				vObj.Contract = vParentObj.Contract;
				vObj.Agent = vParentObj.Agent;
			EndIf;
		Else
			If Parameters.Property("FillingValues") And TypeOf(Parameters.FillingValues) = Type("Structure") Then
				FillPropertyValues(vObj, Parameters.FillingValues);
			EndIf;
		EndIf;
		ValueToFormAttribute(vObj, "Object");
	Else
		Items.BillingInstructionTemplateWarning.Visible = False;
		
		Items.FormOpenFolioTransactions.Visible = True;
		Items.FormOpenFolioTransactions.Enabled = True;
		
		If Not Object.IsMaster And Not ValueIsFilled(Object.Hotel) And Not ValueIsFilled(Object.ParentDoc) And Not ValueIsFilled(Object.GuestGroup) Then
			vObj = FormAttributeToValue("Object");
			vTransCount = vObj.pmGetAllFolioTransactionsCount();
			If vTransCount = 0 Then
				Items.BillingInstructionTemplateWarning.Visible = True;
				
				Items.FormOpenFolioTransactions.Visible = False;
				Items.FormOpenFolioTransactions.Enabled = False;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.Hotel) And Not ValueIsFilled(Object.Company) Then
		Object.Company = Object.Hotel.Company;
	EndIf;
	
	// Vaucher
	vUseHotelProducts = GetVauchersFunctionalOption();
	Items.HotelProduct.Visible = vUseHotelProducts;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	SetObjectAndFormAttributeConformity(pCurrentObject, "Object");
	If pWriteParameters.WriteMode = DocumentWriteMode.Write Then
		// Check document attributes
		vMessage = ""; vAttributeInErr = "";
		pCancel = pCurrentObject.pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.Write';ru='Документ.Запись';de='Document.Write'"), EventLogLevel.Warning, pCurrentObject.Metadata(), pCurrentObject.Ref, NStr(vMessage));
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = vAttributeInErr;
			vUM.Text = NStr(vMessage);
			vUM.Message();
		Else
			If pCurrentObject.IsClosed And Not pCurrentObject.Ref.IsClosed Then
				If Not ValueIsFilled(pCurrentObject.Customer) Or ValueIsFilled(pCurrentObject.Customer) And pCurrentObject.Customer.IsIndividual Then
					If Not cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithClientDebts") Then
						vFolioDebt = pCurrentObject.pmGetBalance();
						If vFolioDebt <> 0 Then
							pCancel = True;
							tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to close folio with non zero individual person balance!'; 
							             |ru='Нет прав закрывать лицевой счет с не нулевым балансом на частное лицо!'; 
							             |de='Sie haben kein Recht, ein persönliches Konto mit einem Guthaben ungleich Null für eine Person zu schließen!'"));
						EndIf;
					EndIf;
				Else
					If Not cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithCustomerDebts") Then
						vFolioDebt = pCurrentObject.pmGetBalance();
						If vFolioDebt <> 0 Then
							pCancel = True;
							tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to close folio with non zero customer balance!'; 
							             |ru='Нет прав закрывать лицевой счет с не нулевым балансом на организацию!'; 
							             |de='Sie haben kein Recht, ein persönliches Konto mit einem Guthaben ungleich Null für eine Firma zu schließen!'"));
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If Not pCancel Then
			// Check should we update parent docs or not
			If pCurrentObject.Ref.Customer <> pCurrentObject.Customer Or pCurrentObject.Ref.Contract <> pCurrentObject.Contract Or pCurrentObject.Ref.PaymentMethod <> pCurrentObject.PaymentMethod Then
				pWriteParameters.Insert("UpdateParentDocs", True);
			EndIf;
			// Copy additional properties from write parameters
			If pWriteParameters.Property("AdditionalProperties") Then
				vAdditionalProperties = pWriteParameters.AdditionalProperties;
				If TypeOf(vAdditionalProperties) = Type("Structure") Then
					For Each vKeyValueItem In vAdditionalProperties Do
						pCurrentObject.AdditionalProperties.Insert(vKeyValueItem.Key, vKeyValueItem.Value);
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Write Then
		Items.BillingInstructionTemplateWarning.Visible = False;

		Items.FormOpenFolioTransactions.Visible = True;
		Items.FormOpenFolioTransactions.Enabled = True;

		If Not pCurrentObject.IsMaster And Not ValueIsFilled(pCurrentObject.Hotel) And Not ValueIsFilled(pCurrentObject.ParentDoc) And Not ValueIsFilled(pCurrentObject.GuestGroup) Then
			vTransCount = pCurrentObject.pmGetAllFolioTransactionsCount();
			If vTransCount = 0 Then
				Items.BillingInstructionTemplateWarning.Visible = True;

				Items.FormOpenFolioTransactions.Visible = False;
				Items.FormOpenFolioTransactions.Enabled = False;
			EndIf;
		EndIf;

		// Try to fix accommodation and reservation charging rules owner
		If pWriteParameters.Property("UpdateParentDocs") And pWriteParameters.UpdateParentDocs <> Undefined And pWriteParameters.UpdateParentDocs Then
			vQry = New Query();
			vQry.Text = 
			"SELECT DISTINCT
			|	AccommodationChargingRules.Ref AS Ref,
			|	AccommodationChargingRules.Ref.Date AS RefDate,
			|	AccommodationChargingRules.Ref.PointInTime AS RefPointInTime
			|FROM
			|	Document.Accommodation.ChargingRules AS AccommodationChargingRules
			|WHERE
			|	AccommodationChargingRules.ChargingFolio = &qFolio
			|	AND NOT AccommodationChargingRules.Ref.DeletionMark
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	ReservationChargingRules.Ref,
			|	ReservationChargingRules.Ref.Date,
			|	ReservationChargingRules.Ref.PointInTime
			|FROM
			|	Document.Reservation.ChargingRules AS ReservationChargingRules
			|WHERE
			|	ReservationChargingRules.ChargingFolio = &qFolio
			|	AND NOT ReservationChargingRules.Ref.DeletionMark
			|
			|ORDER BY
			|	RefDate,
			|	RefPointInTime";
			vQry.SetParameter("qFolio", pCurrentObject.Ref);
			vQryRes = vQry.Execute().Select();
			While vQryRes.Next() Do
				vDocObj = vQryRes.Ref.GetObject();
				For Each vCRRow In vDocObj.ChargingRules Do
					If vCRRow.ChargingFolio = pCurrentObject.Ref Then
						If ValueIsFilled(pCurrentObject.Contract) Then
							If vCRRow.Owner <> pCurrentObject.Contract Then
								vCRRow.Owner = pCurrentObject.Contract;
							EndIf;
						ElsIf ValueIsFilled(pCurrentObject.Customer) Then
							If vCRRow.Owner <> pCurrentObject.Customer Then
								vCRRow.Owner = pCurrentObject.Customer;
							EndIf;
						Else
							If ValueIsFilled(vCRRow.Owner) Then
								vCRRow.Owner = Undefined;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				If vDocObj.Modified() Then
					vDocObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndDo;
			// Try to fix resource reservation owner 
			vQry = New Query();
			vQry.Text = 
			"SELECT DISTINCT
			|	ResourceReservations.Ref AS Ref,
			|	ResourceReservations.Ref.Date AS RefDate,
			|	ResourceReservations.Ref.PointInTime AS RefPointInTime
			|FROM
			|	Document.ResourceReservation AS ResourceReservations
			|WHERE
			|	ResourceReservations.ChargingFolio = &qFolio
			|	AND NOT ResourceReservations.DeletionMark
			|
			|ORDER BY
			|	RefDate,
			|	RefPointInTime";
			vQry.SetParameter("qFolio", pCurrentObject.Ref);
			vQryRes = vQry.Execute().Select();
			While vQryRes.Next() Do
				vDocObj = vQryRes.Ref.GetObject();
				If ValueIsFilled(pCurrentObject.Contract) Then
					If vDocObj.Owner <> pCurrentObject.Contract Then
						vDocObj.Owner = pCurrentObject.Contract;
					EndIf;
				ElsIf ValueIsFilled(pCurrentObject.Customer) Then
					If vDocObj.Owner <> pCurrentObject.Customer Then
						vDocObj.Owner = pCurrentObject.Customer;
					EndIf;
				Else
					If ValueIsFilled(vDocObj.Hotel) Then
						If ValueIsFilled(vDocObj.Hotel.IndividualsContract) Then
							If vDocObj.Owner <> vDocObj.Hotel.IndividualsContract Then
								vDocObj.Owner = vDocObj.Hotel.IndividualsContract;
							EndIf;
						Else
							If vDocObj.Owner <> vDocObj.Hotel.IndividualsCustomer Then
								vDocObj.Owner = vDocObj.Hotel.IndividualsCustomer;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				If vDocObj.Modified() Then
					vDocObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // AfterWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Document.Folio.Edit", Object.Ref, FormOwner);
	If pWriteParameters.Property("UpdateParentDocs") And pWriteParameters.UpdateParentDocs <> Undefined And pWriteParameters.UpdateParentDocs Then
		// Notify changes in the accounts subsystem
		Notify("Subsystem.Accounts.Changed", Object.Ref);
	EndIf;
EndProcedure // AfterWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerOnChange(pItem)
	If Not ValueIsFilled(Object.Customer) Then
		If ValueIsFilled(Object.Contract) Then
			Object.Contract = Undefined;
		EndIf;
	EndIf;
EndProcedure // CustomerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ContractOnChange(Item)
	ContractOnChangeAtServer();
EndProcedure // ContractOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolioTransactions(pCommand)
	// APDEX
	vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
	
	vParamsStruct = New Structure("ParametersStructure", New Structure("ObjectRef", Object.Ref));
	OpenForm("CommonForm.tcFoliosForm", vParamsStruct, ThisObject, Object.Ref);
EndProcedure // OpenFolioTransactions

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseFolio(pCommand)
	ThisObject.Read();
	Object.IsClosed = True;
	If Write(New Structure("WriteMode, AdditionalProperties", DocumentWriteMode.Write, New Structure("SkipCheckOfAnaliticalParametersChange", True))) Then
		Modified = False;
		FolioStateAppearance();
		ShowQueryBox(New NotifyDescription("CloseFolioForm", ThisObject), NStr("en='Close form?'; ru='Закрыть форму?'; de='Formular schließen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	EndIf;
EndProcedure // CloseFolio

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolio(pCommand)
	ThisObject.Read();
	Object.IsClosed = False;
	If Write(New Structure("WriteMode, AdditionalProperties", DocumentWriteMode.Write, New Structure("SkipCheckOfAnaliticalParametersChange", True))) Then
		Modified = False;
		FolioStateAppearance();
		ShowQueryBox(New NotifyDescription("CloseFolioForm", ThisObject), NStr("en='Close form?'; ru='Закрыть форму?'; de='Formular schließen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	EndIf;
EndProcedure // OpenFolio

// -----------------------------------------------------------------------------
&AtClient
Procedure ArchiveFolio(pCommand)
	ThisObject.Read();
	Object.IsArchived = True;
	If Write(New Structure("WriteMode, AdditionalProperties", DocumentWriteMode.Write, New Structure("SkipCheckOfAnaliticalParametersChange", True))) Then
		Modified = False;
		FolioStateAppearance();
		ShowQueryBox(New NotifyDescription("CloseFolioForm", ThisObject), NStr("en='Close form?'; ru='Закрыть форму?'; de='Formular schließen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	EndIf;
EndProcedure // ArchiveFolio

// -----------------------------------------------------------------------------
&AtClient
Procedure UnarchiveFolio(pCommand)
	ThisObject.Read();
	Object.IsArchived = False;
	If Write(New Structure("WriteMode, AdditionalProperties", DocumentWriteMode.Write, New Structure("SkipCheckOfAnaliticalParametersChange", True))) Then
		Modified = False;
		FolioStateAppearance();
		ShowQueryBox(New NotifyDescription("CloseFolioForm", ThisObject), NStr("en='Close form?'; ru='Закрыть форму?'; de='Formular schließen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	EndIf;
EndProcedure // UnarchiveFolio

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearParentDoc(pCommand)
	Object.ParentDoc = Undefined;
	Modified = True;
EndProcedure // ClearParentDoc

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GetVauchersFunctionalOption()
	vUseVauchers = False;
	vHotel = Object.Hotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		vUseVauchers = GetFunctionalOption("Vauchers", New Structure("Hotel", vHotel));
	EndIf;
	Return vUseVauchers;
EndFunction // CheckVauchersFunctionalOption

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpenAtServer()
	If Not cmCheckUserPermissions("HavePermissionToEditFolioDocumentForm") Then
		Items.FolioCurrency.ReadOnly = True;
		Items.Owner.ReadOnly = True;
		Items.GroupAccounting.ReadOnly = True;
		Items.GroupPanels.ReadOnly = True;
		Items.IsMaster.ReadOnly = True;
	EndIf;
	If ValueIsFilled(Object.Ref) And Object.IsClosed And Not cmCheckUserPermissions("HavePermissionToEditClosedFolios") Then
		// Get parent document state
		vParentDocIsActive = False;
		If ValueIsFilled(Object.ParentDoc) Then
			If TypeOf(Object.ParentDoc) = Type("DocumentRef.Reservation") And ValueIsFilled(Object.ParentDoc.ReservationStatus) Then
				vStatus = Object.ParentDoc.ReservationStatus;
				vParentDocIsActive = vStatus.IsActive Or vStatus.IsPreliminary;
			ElsIf TypeOf(Object.ParentDoc) = Type("DocumentRef.ResourceReservation") And ValueIsFilled(Object.ParentDoc.ResourceReservationStatus) Then
				vStatus = Object.ParentDoc.ResourceReservationStatus;
				vParentDocIsActive = vStatus.IsActive And Not vStatus.ServicesAreDelivered;
			ElsIf TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation") And ValueIsFilled(Object.ParentDoc.AccommodationStatus) Then
				vStatus = Object.ParentDoc.AccommodationStatus;
				vParentDocIsActive = vStatus.IsActive And vStatus.IsInHouse;
			EndIf;
		EndIf;
		If Not vParentDocIsActive Then
			Items.FormCloseFolio.Enabled = False;
			ReadOnly = True;
			vAccountingDate = tcOnServer.GetForecastStartDate(Object.Hotel);
			If vAccountingDate > BegOfDay(Object.IsClosedDate) Then
				Items.FormOpenFolio.Enabled = False;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to change closed folios! Document will be opened read only.';ru='Нет прав на изменение закрытых лицевых счетов! Документ будет открыт на просмотр.';de='Sie haben keine Rechte, geschlossene Personenkonten zu bearbeiten! Das Dokument wird zur Ansicht geöffnet!'"));
			EndIf;
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditFoliosCreditLimit") Then
		Items.CreditLimit.ReadOnly = True;
	EndIf;
	// Check user rights to edit folio debt decision
	If Not cmCheckUserPermissions("HavePermissionToTakeFolioDebtDecisions") Then
		Items.FolioDebtDecision.ReadOnly = True;
	EndIf;
	// Collapsed title
	If ValueIsFilled(Object.DebtDecision) Then
		Items.FolioDebtDecision.Title = NStr("en='Folio debt decision: '; ru='Решение по долгу на лицевом счете: '; de='Folio Schulden-Entscheidung: '") + TrimAll(Object.DebtDecision);
	Else
		Items.FolioDebtDecision.Title = NStr("en='Folio debt decision'; ru='Решение по долгу на лицевом счете'; de='Folio Schulden-Entscheidung'");
	EndIf;
	// Folio state appearance
	FolioStateAppearance();
EndProcedure // OnOpenAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure IsComplimentaryOnChange(pItem)
	If Object.IsComplimentary Then
		If Object.IsHouseUse Then
			Object.IsHouseUse = False;
		EndIf;
	EndIf;
EndProcedure // IsComplimentaryOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsHouseUseOnChange(pItem)
	If Object.IsHouseUse Then
		If Object.IsComplimentary Then
			Object.IsComplimentary = False;
		EndIf;
	EndIf;
EndProcedure // IsHouseUseOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DebtDecisionOnChange(pItem)
	If ValueIsFilled(Object.DebtDecision) Then
		If Not ValueIsFilled(Object.DebtDecisionDate) Then
			Object.DebtDecisionAuthor = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
			Object.DebtDecisionDate = CurrentDate();
		EndIf;
		Items.FolioDebtDecision.Title = NStr("en='Folio debt decision: '; ru='Решение по долгу на лицевом счете: '; de='Folio Schulden-Entscheidung: '") + TrimAll(Object.DebtDecision);
	Else
		Object.DebtDecisionAuthor = PredefinedValue("Catalog.Employees.EmptyRef");
		Object.DebtDecisionDate = '00010101';
		Items.FolioDebtDecision.Title = NStr("en='Folio debt decision'; ru='Решение по долгу на лицевом счете'; de='Folio Schulden-Entscheidung'");
	EndIf;
EndProcedure // DebtDecisionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseFolioForm(pButton, pExtraParams) Export
	If pButton = DialogReturnCode.Yes Then
		Close();
	EndIf;
EndProcedure // CloseFolioForm

// -----------------------------------------------------------------------------
&AtServer
Procedure FolioStateAppearance()
	If Object.IsArchived Then
		Items.FormCloseFolio.Visible = False;
		Items.FormOpenFolio.Visible = False;
		Items.FormArchiveFolio.Visible = False;
		Items.FormUnarchiveFolio.Visible = True;
	ElsIf Object.IsClosed Then
		Items.FormCloseFolio.Visible = False;
		If cmCheckUserPermissions("HavePermissionToEditClosedFolios") Then
			Items.FormOpenFolio.Visible = True;
		Else
			vAccountingDate = tcOnServer.GetForecastStartDate(Object.Hotel);
			If vAccountingDate > BegOfDay(Object.IsClosedDate) Then
				Items.FormOpenFolio.Visible = False;
			Else
				Items.FormOpenFolio.Visible = True;
			EndIf;
		EndIf;
		Items.FormArchiveFolio.Visible = True;
		Items.FormUnarchiveFolio.Visible = False;
	Else
		Items.FormCloseFolio.Visible = True;
		Items.FormOpenFolio.Visible = False;
		Items.FormArchiveFolio.Visible = False;
		Items.FormUnarchiveFolio.Visible = False;
	EndIf;
EndProcedure // FolioStateAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure ContractOnChangeAtServer()
	If ValueIsFilled(Object.Contract) Then
		If Object.Contract.Owner <> Object.Customer Then
			Object.Customer = Object.Contract.Owner;
		EndIf;
	EndIf;
EndProcedure // ContractOnChangeAtServer

#EndRegion
