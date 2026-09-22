
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Post to service registration
	If ValueIsFilled(Service) Then
		PostToServiceRegistration();
	EndIf;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.Folio") Then
			pmFillByFolio(pBase);
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			Raise NStr(vMessage);
		EndIf;
	ElsIf DeletionMark Then
		If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
			vMessage = NStr("en='You have no rights for this operation!'; ru='Нет прав на это действие!'; de='Sie haben keine Rechte für diese operation!'");
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	EndIf;
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)  
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillByFolio(pFolio) Export
	If pFolio = Documents.Folio.EmptyRef() Then
		Return;
	EndIf;
	// Folio and folio currency
	Folio = pFolio;
	FolioCurrency = Folio.FolioCurrency;
	If ValueIsFilled(Folio.Hotel) Then
		If Hotel <> Folio.Hotel Then
			Hotel = Folio.Hotel;
			SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		EndIf;
	EndIf;
	// Guest group, client, room
	GuestGroup = pFolio.GuestGroup;
	Client = pFolio.Client;
	Room = pFolio.Room;
	// Fill parent document
	ParentDoc = pFolio.ParentDoc;
	// Fill resource
	If ValueIsFilled(ParentDoc) Then
		If TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
			Resource = ParentDoc.Resource;
		EndIf;
	EndIf;
EndProcedure // pmFillByFolio

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(MealType) Then
		If Not ValueIsFilled(Folio) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Реквизит <Лицевой счет> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Folio> attribute should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Folio> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Folio", pAttributeInErr);
		EndIf;
		If Not ValueIsFilled(Service) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Реквизит <Услуга> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Service> attribute should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Service> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Service", pAttributeInErr);
		EndIf;
	EndIf;
	If Not ValueIsFilled(FolioCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта фолио> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Folio currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Folio currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "FolioCurrency", pAttributeInErr);
	EndIf;
	// Check that only one service per day per guest is allowed
	If ValueIsFilled(Service) And Service.ServiceRegistrationIsTurnedOn And Service.MaxOneServicePerDayIsAllowed Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ServiceRegistration.Ref
		|FROM
		|	Document.ServiceRegistration AS ServiceRegistration
		|WHERE
		|	ServiceRegistration.Ref <> &qDoc
		|	AND ServiceRegistration.Posted
		|	AND ServiceRegistration.AccountingDate = &qAccountingDate
		|	AND ServiceRegistration.Client = &qClient
		|	AND ServiceRegistration.Service = &qService
		|
		|ORDER BY
		|	ServiceRegistration.PointInTime";
		vQry.SetParameter("qDoc", Ref);
		vQry.SetParameter("qAccountingDate", AccountingDate);
		vQry.SetParameter("qClient", Client);
		vQry.SetParameter("qService", Service);
		vDocs = vQry.Execute().Unload();
		If vDocs.Count() > 0 Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Разрешено использовать только одну услугу в день!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "One service per day is allowed only!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Ein Service pro Tag ist erlaubt!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Client", pAttributeInErr);
		EndIf;
	EndIf;
	// Call external algorithm if any
	vUserExitProc = Catalogs.ExternalDataProcessors.ServiceRegistrationDocumentAttributesCheck;
	If vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm And Not IsBlankString(vUserExitProc.Algorithm) Then
		SetSafeMode(True);
		Execute(TrimAll(vUserExitProc.Algorithm));
		SetSafeMode(False);
	EndIf;
	// Check results
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
	AccountingDate = BegOfDay(Date);
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		FolioCurrency  = Hotel.FolioCurrency;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure PostToServiceRegistration()
	Movement = RegisterRecords.ServiceRegistration.Add();
	
	Movement.RecordType = AccumulationRecordType.Expense;
	Movement.Period = Date;
	
	// Fill properties
	FillPropertyValues(Movement, Folio);
	FillPropertyValues(Movement, ThisObject);
	
	// Fill accounting date
	Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
	
	// Fill resource
	If ValueIsFilled(ParentDoc) Then
		If TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
			Movement.Resource = ParentDoc.Resource;
		EndIf;
	EndIf;
	
	// Resources
	Movement.Sum = Sum;
	
	// Attributes
	Movement.Price = cmRecalculatePrice(Movement.Sum, Movement.Quantity);
	
	RegisterRecords.ServiceRegistration.Write();
EndProcedure // PostToServiceRegistration

#EndRegion

