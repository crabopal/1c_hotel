
#Region EventHandlers

 // -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	ExternalCode = "";
	// Author and date
	Author = SessionParameters.CurrentUser;
	CreateDate = CurrentSessionDate();
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If AdditionalProperties.Property("CheckedAttributes") Then
		For Each vId In AdditionalProperties.CheckedAttributes Do
			CheckedAttributes.Add(vId);       
		EndDo;	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;

	If DeletionMark <> Ref.DeletionMark Then
        vEventDescription = "";
		If DeletionMark Then
			vEventDescription = StrTemplate(NStr("en = 'Deletion mark was set for contract: %1'; de = 'Löschmarke wurde für Vertrag gesetzt: %1'; ru = 'Пометили на удаление договор: %1'"), TrimAll(Ref));
		Else
			vEventDescription = StrTemplate(NStr("en = 'Deletion mark was removed for contract: %1'; de = 'Löschmarke wurde für Vertrag entfernt: %1'; ru = 'Сняли пометку на удаление у договора: %1'"), TrimAll(Ref));
		EndIf;
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vEventDescription);
		pmWriteToContractChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Clear hotel from billing instructions template folios
	If Not DeletionMark Then
		For Each vCRRow In ChargingRules Do
			// Need to clear empty values of some type (like empty Service group or Service)
			If Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
				vCRRow.ChargingRuleValue = Undefined;
			EndIf;
			// Clear hotel from template folios
			vChargingFolio = vCRRow.ChargingFolio;
			vChargingFolioObj = Undefined;
			If ValueIsFilled(vChargingFolio) And ValueIsFilled(vChargingFolio.Hotel) And Not vChargingFolio.IsMaster Then
				vChargingFolioObj = vChargingFolio.GetObject();
				vTransCount = vChargingFolioObj.pmGetAllFolioTransactionsCount();
				If vTransCount = 0 Then
					vChargingFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
				EndIf;
			EndIf;
			// Fill contract in template folios
			If ValueIsFilled(vChargingFolio) And vChargingFolio.Contract <> Ref And 
			   Not vChargingFolio.DoNotUpdateCustomer And Not vChargingFolio.IsMaster Then
				vChargingFolioObj = vChargingFolio.GetObject();
				vChargingFolioObj.Contract = Ref;
				vChargingFolioObj.Customer = Owner;
			EndIf;
			If vChargingFolioObj <> Undefined And vChargingFolioObj.Modified() Then
				vChargingFolioObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmCreateFolios(pHotel, pDate, pPayer = Undefined) Export
	ChargingRules.Clear();
	vChargingRules = Undefined;
	If pPayer = Enums.WhoPays.Agent And ValueIsFilled(Agent) And ValueIsFilled(Agent.Parent) Then
		If Agent.Parent.ChargingRules.Count() > 0 Then
			vChargingRules = Agent.Parent.ChargingRules.Unload();
		EndIf;
	ElsIf ValueIsFilled(Owner) And ValueIsFilled(Owner.Parent) Then
		If Owner.Parent.ChargingRules.Count() > 0 Then
			vChargingRules = Owner.Parent.ChargingRules.Unload();
		EndIf;
	EndIf;
	If vChargingRules = Undefined Then
		If ValueIsFilled(pHotel) Then
			If pHotel.CustomerChargingRules.Count() > 0 Then
				vChargingRules = pHotel.CustomerChargingRules.Unload();
			EndIf;
		Else
			Return;
		EndIf;
	EndIf;
	// Check list of template rules
	If vChargingRules = Undefined Then
		// Create new folio and take parameters from the hotel
		vFolioObj = Documents.Folio.CreateDocument();
		cmFillFolioFromTemplate(vFolioObj, Undefined, pHotel, pDate);
		vFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
		If pPayer = Enums.WhoPays.Agent And ValueIsFilled(Agent) Then
			vFolioObj.Customer = Agent;
			vFolioObj.Contract = Undefined;
		Else
			vFolioObj.Customer = Owner;
			vFolioObj.Contract = Ref;
		EndIf;
		If ValueIsFilled(pHotel) And ValueIsFilled(pHotel.PaymentMethodForCustomerPayments) Then
			vFolioObj.PaymentMethod = pHotel.PaymentMethodForCustomerPayments;
		ElsIf ValueIsFilled(PlannedPaymentMethod) Then
			vFolioObj.PaymentMethod = PlannedPaymentMethod;
		EndIf;
		If ValueIsFilled(AccountingCurrency) Then
			vFolioObj.FolioCurrency = AccountingCurrency;
		EndIf;
		vFolioObj.Write();
		
		// Add it to the charging rules
		vCR = ChargingRules.Add();
		vCR.ChargingRule = Enums.ChargingRuleTypes.InRate;
		vCR.ChargingFolio = vFolioObj.Ref;
	Else
		For Each vRule In vChargingRules Do
			// Create new folio from template
			vFolioObj = Documents.Folio.CreateDocument();
			cmFillFolioFromTemplate(vFolioObj, vRule.ChargingFolio, pHotel, pDate);
			vFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
			If pPayer = Enums.WhoPays.Agent And ValueIsFilled(Agent) Then
				vFolioObj.Customer = Agent;
				vFolioObj.Contract = Undefined;
			Else
				vFolioObj.Customer = Owner;
				vFolioObj.Contract = Ref;
			EndIf;
			If ValueIsFilled(AccountingCurrency) Then
				vFolioObj.FolioCurrency = AccountingCurrency;
			EndIf;
			vFolioObj.IsMaster = vRule.ChargingFolio.IsMaster;
			vFolioObj.Write();
			
			// Add it to the charging rules
			vCR = ChargingRules.Add();
			FillPropertyValues(vCR, vRule, , "ChargingFolio");
			vCR.ChargingFolio = vFolioObj.Ref;
		EndDo;
	EndIf;
EndProcedure // pmCreateFolios

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Author and date
	Author = SessionParameters.CurrentUser;
	CreateDate = CurrentSessionDate();
	// Initialization based on hotel
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(vHotel) Then
		// Currency
		If Not ValueIsFilled(AccountingCurrency) Then
			AccountingCurrency = vHotel.FolioCurrency;
		EndIf;
		// Planned payment method
		PlannedPaymentMethod = vHotel.PlannedPaymentMethod;
		// Default charging rules
		If vHotel.AlwaysCreateDefaultChargingRulesForNewCustomers Then
			pmCreateFolios(vHotel, CreateDate);
		ElsIf ValueIsFilled(Owner) Then
			vParent = Owner.Parent;
			While ValueIsFilled(vParent) Do
				If vParent.AlwaysCreateDefaultChargingRulesForNewCustomers Then
					pmCreateFolios(vHotel, CreateDate);
					Break;
				EndIf;
				vParent = vParent.Parent;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmCheckContractAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	If IsBlankString(Code) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Код> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Code> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Code", pAttributeInErr);
	EndIf;
	If IsBlankString(Description) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Наименование> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Description> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Description", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Owner) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Контрагент> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Customer> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Owner", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(AccountingCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта взаиморасчетов> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Accounting currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCurrency", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckContractAttributes

// -----------------------------------------------------------------------------
Procedure FillCChgAttributes(pCChgRec, pPeriod, pUser)
	FillPropertyValues(pCChgRec, ThisObject);
	
	pCChgRec.Period = pPeriod;
	pCChgRec.Contract = ThisObject.Ref;
	pCChgRec.User = pUser;
	
	// Store tabular parts
	vChargingRules = New ValueStorage(ChargingRules.Unload());
	pCChgRec.ChargingRules = vChargingRules;
	vRoomRates = New ValueStorage(RoomRates.Unload());
	pCChgRec.RoomRates = vRoomRates;
	vMealBoardTerms = New ValueStorage(MealBoardTerms.Unload());
	pCChgRec.MealBoardTerms = vMealBoardTerms;
EndProcedure // FillCChgAttributes

// -----------------------------------------------------------------------------
Procedure pmWriteToContractChangeHistory(pPeriod, pUser) Export
	// Get channges description
	vChanges = cmGetObjectChanges(ThisObject);
	If Not IsBlankString(vChanges) Then
		vCChgRec = InformationRegisters.ContractChangeHistory.CreateRecordManager();
		
		FillCChgAttributes(vCChgRec, pPeriod, pUser);
		vCChgRec.Changes = vChanges;
		
		// Write record
		vCChgRec.Write(True);  
		
		// User activity history
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vChanges, , pUser, pPeriod);
	EndIf;
EndProcedure // pmWriteToContractChangeHistory

// -----------------------------------------------------------------------------
Function pmGetPreviousObjectState(pPeriod) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.ContractChangeHistory.SliceLast(&qPeriod, Contract = &qRef) AS ContractChangeHistory";
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qRef", Ref);
	vStates = vQry.Execute().Unload();
	If vStates.Count() > 0 Then
		Return vStates.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetPreviousObjectState

// -----------------------------------------------------------------------------
Procedure pmRestoreAttributesFromHistory(pChgRec) Export
	FillPropertyValues(ThisObject, pChgRec, , "Code, Description");
	If Not IsBlankString(pChgRec.Code) Then
		Code = pChgRec.Code;
	EndIf;
	If Not IsBlankString(pChgRec.Description) Then
		Description = pChgRec.Description;
	EndIf;
	// Restore tabular parts
	vChargingRules = pChgRec.ChargingRules.Get();
	If vChargingRules <> Undefined Then
		ChargingRules.Load(vChargingRules);
	Else
		ChargingRules.Clear();
	EndIf;
	vRoomRates = pChgRec.RoomRates.Get();
	If vRoomRates <> Undefined Then
		RoomRates.Load(vRoomRates);
	Else
		RoomRates.Clear();
	EndIf;
	vMealBoardTerms = pChgRec.MealBoardTerms.Get();
	If vMealBoardTerms <> Undefined Then
		MealBoardTerms.Load(vMealBoardTerms);
	Else
		MealBoardTerms.Clear();
	EndIf;
EndProcedure // pmRestoreAttributesFromHistory

// -----------------------------------------------------------------------------
// Get characteristics
// Returns ValueTable 
// -----------------------------------------------------------------------------
Function pmGetLimitsAndConditions() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	LimitsAndSpecialConditions.Owner AS Contract,
	|	LimitsAndSpecialConditions.Hotel AS Hotel,
	|	LimitsAndSpecialConditions.Characteristic AS Characteristic,
	|	LimitsAndSpecialConditions.CharacteristicValue AS CharacteristicValue
	|FROM
	|	InformationRegister.LimitsAndSpecialConditions AS LimitsAndSpecialConditions
	|WHERE
	|	LimitsAndSpecialConditions.Owner = &qContract
	|	AND (LimitsAndSpecialConditions.Hotel = &qHotel
	|			OR LimitsAndSpecialConditions.Hotel = &qEmptyHotel
	|			OR LimitsAndSpecialConditions.Hotel = &qCurrentHotel)
	|	AND LimitsAndSpecialConditions.Characteristic.DeletionMark = FALSE
	|
	|ORDER BY
	|	LimitsAndSpecialConditions.Characteristic.Code";
	vQry.SetParameter("qContract", Ref);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qCurrentHotel", SessionParameters.CurrentHotel);
	vChars = vQry.Execute().Unload();
	Return vChars;
EndFunction // pmGetLimitsAndConditions

// -----------------------------------------------------------------------------
// Get characteristic value
// Returns Value
// -----------------------------------------------------------------------------
Function pmGetLimitsAndConditionsValue(pCharacteristic, pHotel) Export
	vCharValue = Undefined;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	LimitsAndSpecialConditions.CharacteristicValue AS CharacteristicValue
	|FROM
	|	InformationRegister.LimitsAndSpecialConditions AS LimitsAndSpecialConditions
	|WHERE
	|	LimitsAndSpecialConditions.Owner = &qContract
	|	AND (LimitsAndSpecialConditions.Hotel = &qHotel
	|			OR LimitsAndSpecialConditions.Hotel = &qEmptyHotel)
	|	AND LimitsAndSpecialConditions.Characteristic = &qCharacteristic
	|
	|ORDER BY
	|	LimitsAndSpecialConditions.Characteristic.Code";
	vQry.SetParameter("qContract", Ref);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qCharacteristic", pCharacteristic);
	vChars = vQry.Execute().Select();
	While vChars.Next() Do
		vCharValue = vChars.CharacteristicValue;
		Break;
	EndDo;
	Return vCharValue;
EndFunction // pmGetLimitsAndConditionsValue

// -----------------------------------------------------------------------------
Procedure pmSaveLimitsAndConditionsValue(pCharacteristic, pCharacteristicValue, pHotel) Export
	vCharsMgr = InformationRegisters.LimitsAndSpecialConditions.CreateRecordManager();
	vCharsMgr.Owner = Ref;
	vCharsMgr.Characteristic = pCharacteristic;
	vCharsMgr.Hotel = pHotel;
	vCharsMgr.Read();
	If vCharsMgr.Selected() Then
		vCharsMgr.Owner = Ref;
		vCharsMgr.Characteristic = pCharacteristic;
		vCharsMgr.CharacteristicValue = pCharacteristicValue;
		vCharsMgr.Hotel = pHotel;
		vCharsMgr.Write();
	EndIf;
EndProcedure // pmSaveLimitsAndConditionsValue

// -----------------------------------------------------------------------------
Procedure pmGetNewCode() Export
	// Use current number as search prefix
	vPrefix = TrimAll(Code);
	// Try to find last contract with such contract code prefix
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Contracts.Code AS Code,
	|	Contracts.Ref AS Ref
	|FROM
	|	Catalog.Contracts AS Contracts
	|WHERE
	|	Contracts.Code LIKE &qCode
	|	AND NOT Contracts.DeletionMark
	|
	|ORDER BY
	|	Contracts.CreateDate DESC";
	vQry.SetParameter("qCode", vPrefix + "%");
	vContracts = vQry.Execute().Unload();
	If vContracts.Count() > 0 Then
		vContractCode = TrimAll(vContracts.Get(0).Code);
		Code = vContractCode;
	Else
		Code = "1";
	EndIf;

	
EndProcedure

#EndRegion
