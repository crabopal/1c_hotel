
#Region Public
// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - 	Undefined, Structure - Parametrs for fill
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// NOTHING SO FAR
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//  Run data processor in silent mode
//
// Parameters:
//  pParameter		 - Undefined - Not Use
//  pIsInteractive	 - Boolean	 - Interactive mode
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#IF CLIENT THEN
		OpenForm("DataProcessor.CalculateBonuses.Form",New Structure("DataProcessor",ThisObject.DataProcessor));
	#ELSE
		CalculateBonuses();	
	#ENDIF
EndProcedure // pmRun

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDateFrom	 - Date	 - Date from
//  pDateTo		 - Date	 - Date to
//
Procedure CalculateBonuses(pDateFrom = Undefined, pDateTo = Undefined) Export
	If NOT ValueIsFilled(ExternalInteraction) Then
		vMsg = Nstr("en = 'It is necessary to fill the interaction system'; de = 'Es ist notwendig, das Interaktionssystem zu füllen'; ru = 'Необходимо заполнить систему взаимодействия'");
		WriteLogEvent("DataProcessors.CalculateBonuses.CalculateBonuses", EventLogLevel.Error,,, vMsg);
		Raise vMsg;
	EndIf;
	If Not ExternalInteraction.IsActive Then
		vMsg = Nstr("en = 'Interaction system is off, synchronization failed'; de = 'Interaktionssystem ist ausgeschaltet, Synchronisation fehlgeschlagen'; ru = 'Cистема взаимодействия выключена'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "CalculateBonuses.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		WriteLogEvent("DataProcessors.CalculateBonuses.CalculateBonuses", EventLogLevel.Error,,, vMsg);
		Raise vMsg;
	EndIf;
	
	vStartSync = CurrentSessionDate();
	vDaysDelay = DaysDelay;   
	vDate = BegOfDay(ExternalInteraction.SessionLastActivityTime); 
	vDateTo = BegOfDay(CurrentSessionDate() - 24*60*60 * vDaysDelay);
	If pDateFrom <> Undefined And pDateTo <> Undefined Then
		vDate = BegOfDay(pDateFrom); 
		vDateTo = BegOfDay(pDateTo);	
	EndIf;
	If ExternalInteraction.DebugMode Then
		vMessage = NStr("en='Start of execution';ru='Начало выполнения';de='Ausführung starten'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "CalculateBonuses.Start", Enums.ExternalSystemEventTypes.Info, , , vMessage);
	EndIf;
	//
	While vDate <= vDateTo Do
		// Get sales
		vSales = GetCharges(vDate);
		If vSales.Count() > 0 Then
			If ExternalInteraction.DebugMode Then
				vMessage = NStr("en='Accumulations found on the date ';ru='Найдено накоплений на дату ';de='Gefunden Akkumulation auf Datum '")+ Format(vDate,"DF=dd.MM.yyyy") + ": " + vSales.Count();
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "CalculateBonuses.GetCharges", Enums.ExternalSystemEventTypes.Info, , , vMessage);
			EndIf;
		Else
			If ExternalInteraction.DebugMode Then
				vMessage = NStr("en='Accumulations found on the date ';ru='Найдено накоплений на дату ';de='Gefunden Akkumulation auf Datum '")+ Format(vDate,"DF=dd.MM.yyyy") + ": " + vSales.Count();
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "CalculateBonuses.GetCharges", Enums.ExternalSystemEventTypes.Info, , , vMessage);
			EndIf;
		EndIf;
		// Calculate sales
		vResources = GetResourcesBySales(vSales);
		vResources.Columns.Add("Remarks", New TypeDescription("String", , New StringQualifiers(999)));
		If CalculateBonusesByPayments Then
			// By payments
			CalculateBonusesByPayments(vResources);
		Else	
			// By charges
			CalculateBonusesByCharges(vResources);
		EndIf;
		vResources.GroupBy("DiscountCard, Hotel, Guest, Room, GuestGroup, Remarks", "Amount, Resource, Bonuses, PaidBonuses");
		// Create BonusesOperation
		CreateBonusesOperationDocuments(vResources, vDate);     
		vDate = vDate + 86400;
	EndDo;
    // Log
    If ExternalInteraction.DebugMode Then
		vMessage = NStr("en='End of execution';ru='Конец исполнения';de='Ende der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "CalculateBonuses.End", Enums.ExternalSystemEventTypes.Info, , , vMessage);
	EndIf; 
	If pDateFrom = Undefined And pDateTo = Undefined Then
		// Save last date sync
		vExternalInteractionObj = ExternalInteraction.GetObject();
		vExternalInteractionObj.SessionLastActivityTime = vStartSync;
		vExternalInteractionObj.Write();
	EndIf;
EndProcedure // CalculateBonuses

#EndRegion

#Region Internal

// -----------------------------------------------------------------------------
Procedure CalculateBonusesByCharges(pResources)
	If ExcludeBonusesPayments Then
		// PaidBonuses apportionment
		vTabTotals = pResources.Copy();
		vTabTotals.GroupBy("Hotel, GuestGroup, DocNumber", "Amount, Resource, Bonuses, PaidBonuses");
		For Each vCurRowTotal In vTabTotals Do
			vPaidBonuses = GetBonusesPayments(vCurRowTotal);
			If vPaidBonuses > 0 Then 
				vFilterRows =  pResources.FindRows(New Structure("Hotel, GuestGroup, DocNumber", vCurRowTotal.Hotel, vCurRowTotal.GuestGroup, vCurRowTotal.DocNumber));
				If vPaidBonuses >= vCurRowTotal.Resource Then
					For Each vCurRowBonuses In vFilterRows Do
						vCurRowBonuses.Bonuses = 0;
					EndDo;
				Else
					For Each vCurRowBonuses In vFilterRows Do
						vPercent = ?(vCurRowTotal.Resource > 0, vCurRowBonuses.Resource/vCurRowTotal.Resource, 0);
						vCurRowPaidBonuses = Round(vPaidBonuses * vPercent, 4);
						vCurRowBonuses.Bonuses = Round((vCurRowBonuses.Resource - vCurRowPaidBonuses) * vCurRowBonuses.BonusCalculationFactor, 2);
						vCurRowBonuses.PaidBonuses = vCurRowPaidBonuses;
					EndDo;
				EndIf;
			EndIf;
		EndDo;
		pResources.GroupBy("DiscountCard, DiscountType, Hotel, Guest, Room, DocNumber, GuestGroup, Remarks, BonusCalculationFactor, Service", "Amount, Resource, Bonuses, PaidBonuses");
		pResources.Sort("DocNumber, Guest");
		n = 0;
		vCurRow = Undefined;
		vTotalSum = 0;   
		vFullRemarks = "";
		While n < pResources.Count() Do
			vRow = pResources[n];
			If vCurRow <> Undefined And (vRow.DocNumber <> vCurRow.DocNumber Or vRow.Guest <> vCurRow.Guest) Then
				vCurRow.Remarks = TrimAll(vFullRemarks) + Chars.LF + NStr("en = 'Total = '; de = 'Insgesamt = '; ru = 'Всего = '") + vTotalSum;
				vCurRow = vRow;
				vTotalSum = vRow.Bonuses;
				vFullRemarks = NStr("en = 'gr.'; de = 'gr.'; ru = 'гр.'") + TrimAll(vRow.GuestGroup.Code);
			ElsIf vCurRow = Undefined Then
				vFullRemarks = NStr("en = 'gr.'; de = 'gr.'; ru = 'гр.'") + TrimAll(vRow.GuestGroup.Code);
				vTotalSum = vRow.Bonuses;
				vCurRow = vRow;
			Else
				vCurRow.Resource = vCurRow.Resource + vRow.Resource;
				vCurRow.Bonuses = vCurRow.Bonuses + vRow.Bonuses;
				vCurRow.PaidBonuses = vCurRow.PaidBonuses + vRow.PaidBonuses;
				vTotalSum = vTotalSum + vRow.Bonuses;
			EndIf;
			vFullRemarks = vFullRemarks + Chars.LF + TrimAll(vRow.Service) + ": (" + TrimAll(Format(vRow.Resource,"NFD=2")) + " - " + TrimAll(Format(vRow.PaidBonuses,"NFD=2; NZ=0")) + ") * " + TrimAll(vRow.BonusCalculationFactor) + " = " + TrimAll(Format(vRow.Bonuses,"NFD=2")) + " ";  
			If vCurRow <> vRow Then
				pResources.Delete(vRow);
			Else
				n = n +1;
			EndIf;
			If n = pResources.Count() Then
				vCurRow.Remarks = TrimAll(vFullRemarks) + Chars.LF + NStr("en = 'Total = '; de = 'Insgesamt = '; ru = 'Всего = '") + vTotalSum;
			EndIf;
		EndDo;
	Else
		pResources.GroupBy("DiscountCard, Hotel, Guest, Room, DocNumber, GuestGroup, Remarks, BonusCalculationFactor, Service", "Amount, Resource, Bonuses, PaidBonuses");
		pResources.Sort("DocNumber, Guest");
		n = 0;
		vCurRow = Undefined;
		vTotalSum = 0;
		While n < pResources.Count() Do
			vRow = pResources[n];
			If vCurRow <> Undefined And (vRow.DocNumber <> vCurRow.DocNumber Or vRow.Guest <> vCurRow.Guest) Then
				vCurRow.Remarks = TrimAll(vFullRemarks) + Chars.LF + NStr("en = 'Total = '; de = 'Insgesamt = '; ru = 'Всего = '") + vTotalSum;
				vCurRow = vRow;
				vTotalSum = vRow.Bonuses;
				vFullRemarks = NStr("en = 'gr.'; de = 'gr.'; ru = 'гр.'") + TrimAll(vRow.GuestGroup.Code);
			ElsIf vCurRow = Undefined Then
				vFullRemarks = NStr("en = 'gr.'; de = 'gr.'; ru = 'гр.'") + TrimAll(vRow.GuestGroup.Code);
				vTotalSum = vRow.Bonuses;
				vCurRow = vRow;
			Else
				vCurRow.Resource = vCurRow.Resource + vRow.Resource;
				vCurRow.Bonuses = vCurRow.Bonuses + vRow.Bonuses;
				vCurRow.PaidBonuses = vCurRow.PaidBonuses + vRow.PaidBonuses;
				vTotalSum = vTotalSum + vRow.Bonuses;
			EndIf;
			vFullRemarks = vFullRemarks + Chars.LF + TrimAll(vRow.Service) + ": " + TrimAll(Format(vRow.Resource,"NFD=2")) + " * " + TrimAll(vRow.BonusCalculationFactor) + " = " + TrimAll(Format(vRow.Bonuses,"NFD=2")) + " ";  
			If vCurRow <> vRow Then
				pResources.Delete(vRow);
			Else
				n = n +1;
			EndIf;
			If n = pResources.Count() Then
				vCurRow.Remarks = TrimAll(vFullRemarks) + Chars.LF + NStr("en = 'Total = '; de = 'Insgesamt = '; ru = 'Всего = '") + vTotalSum;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // CalculateBonusesByCharges

// -----------------------------------------------------------------------------
Procedure CalculateBonusesByPayments(pResources)
	pResources.GroupBy("DiscountCard, DiscountType, Hotel, Guest, Room, GuestGroup, DocNumber, DiscountDimension, Remarks", "Amount, Resource, Bonuses, PaidBonuses");
	If ExcludeBonusesPayments Then
		For Each vRowRes In pResources Do
			vRowRes.PaidBonuses = GetBonusesPayments(vRowRes);
		EndDo;	
	EndIf;
	vObj = DiscountType.GetObject();
	For Each vRowRes In pResources Do
		vTotalSum = 0;
		vFullRemarks = NStr("en = 'gr.'; de = 'gr.'; ru = 'гр.'") + TrimAll(vRowRes.GuestGroup.Code);
		vPaidServices = GetServicesPayments(vRowRes);
		For Each vPaidService In vPaidServices Do
			vBonusCalculationFactor = vObj.pmGetBonusCalculationFactor(,vPaidService.Service, vRowRes.Hotel);
			vTotalSum = vTotalSum + (vPaidService.Sum * vBonusCalculationFactor);
			If vBonusCalculationFactor <> 0 Then 
				vFullRemarks = vFullRemarks + Chars.LF + TrimAll(vPaidService.Service) + ": " + TrimAll(Format(vPaidService.Sum,"NFD=2")) + " * " + TrimAll(vBonusCalculationFactor) + " = " + TrimAll(Format(vPaidService.Sum * vBonusCalculationFactor,"NFD=2")) + " ";  
			EndIf;	
		EndDo;
		vRowRes.Remarks = TrimAll(vFullRemarks) + Chars.LF + NStr("en = 'Total = '; de = 'Insgesamt = '; ru = 'Всего = '") + vTotalSum;
		vRowRes.Bonuses = vTotalSum;	
	EndDo;
EndProcedure // CalculateBonusesByPayments

// -----------------------------------------------------------------------------
Function GetCharges(pDate)
    vResult = New ValueTable;
	vResult.Columns.Add("Ref");
	vResult.Columns.Add("StornoRef");
	vResult.Columns.Add("NumberOfPersons");
	vResult.Columns.Add("Folio");
	vResult.Columns.Add("DiscountCard");
	vResult.Columns.Add("Customer");
	vResult.Columns.Add("Client");
	vResult.Columns.Add("Hotel");
	vResult.Columns.Add("Sales");
	vResult.Columns.Add("DiscountSum");
	vResult.Columns.Add("DocNumber");
	vResult.Columns.Add("Room");
	vResult.Columns.Add("Service");

    
    vQuery 	= New Query;
	vQuery.Text = 
		"SELECT
		|	Accommodation.Number AS Number,
		|	Accommodation.GuestGroup AS GuestGroup,
		|	Accommodation.Guest AS Guest
		|INTO Acc
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	Accommodation.Posted
		|	AND NOT Accommodation.DeletionMark
		|	AND BEGINOFPERIOD(Accommodation.CheckOutDate, DAY) = BEGINOFPERIOD(&qCheckOutDate, DAY)
		|	AND CASE
		|			WHEN &qHotel = VALUE(Catalog.Hotels.EmptyRef)
		|				THEN TRUE
		|			ELSE Accommodation.Hotel = &qHotel
		|		END
		|	AND Accommodation.AccommodationStatus.IsActive
		|	AND NOT Accommodation.AccommodationStatus.IsInHouse
		|	AND Accommodation.Duration >= &qDuration
		|	AND Accommodation.Guest <> &qEmpyClient
		|	AND IsNull(Accommodation.Guest.ClientType.NoBonuses, False) = FALSE
		|	AND IsNull(Accommodation.ClientType.NoBonuses, False) = FALSE		
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SalesTurnovers.Client AS Guest,
		|	SUM(ISNULL(SalesTurnovers.GuestsCheckedInTurnover, 0)) AS VizitsCount
		|INTO NumberVisits
		|FROM
		|	AccumulationRegister.Sales.Turnovers(
		|			,
		|			&qCheckOutDate,
		|			Period,
		|			Client IN
		|				(SELECT
		|					Acc.Guest AS Guest
		|				FROM
		|					Acc AS Acc)) AS SalesTurnovers
		|
		|GROUP BY
		|	SalesTurnovers.Client
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Folio.Ref AS Ref,
		|	NumberVisits.VizitsCount AS VizitsCount
		|INTO FolioList
		|FROM
		|	Acc AS Acc
		|		LEFT JOIN Document.Folio AS Folio
		|		ON Acc.Number = Folio.ParentDoc.Number
		|			AND Acc.GuestGroup = Folio.GuestGroup
		|		LEFT JOIN NumberVisits AS NumberVisits
		|		ON Acc.Guest = NumberVisits.Guest
		|WHERE
		|	NumberVisits.VizitsCount >= &qVisitsCount
		|	AND CASE
		|			WHEN &qDirectSalesOnly
		|				THEN CASE
		|						WHEN &qCustomerTypeIsEmpty
		|							THEN (Folio.Customer = VALUE(Catalog.Customers.EmptyRef)
		|									OR Folio.Customer = Folio.Hotel.IndividualsCustomer
		|									OR Folio.Customer.IsIndividual)
		|									AND Folio.Agent = VALUE(Catalog.Customers.EmptyRef)
		|						ELSE Folio.Customer.CustomerType IN (&qCustomerTypeWhiteList)
		|								OR (Folio.Customer = VALUE(Catalog.Customers.EmptyRef)
		|									OR Folio.Customer = Folio.Hotel.IndividualsCustomer
		|									OR Folio.Customer.IsIndividual)
		|									AND Folio.Agent = VALUE(Catalog.Customers.EmptyRef)
		|					END
		|			ELSE CASE
		|					WHEN &qCustomerTypeIsEmpty
		|						THEN TRUE
		|					ELSE Folio.Customer.CustomerType IN (&qCustomerTypeWhiteList)
		|							OR (Folio.Customer = VALUE(Catalog.Customers.EmptyRef)
		|								OR Folio.Customer = Folio.Hotel.IndividualsCustomer
		|								OR Folio.Customer.IsIndividual)
		|				END
		|		END
		|	AND CASE
		|			WHEN &qClientTypeIsEmpty
		|				THEN TRUE
		|			ELSE Folio.Client.ClientType IN (&qClientTypeWhiteList)
		|		END
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SalesReg.Recorder.Ref AS Ref,
		|	SUM(SalesReg.NumberOfPersons) AS NumberOfPersons,
		|	SalesReg.DiscountCard AS DiscountCard,
		|	SalesReg.Folio AS Folio,
		|	SalesReg.ParentDoc.Customer AS Customer,
		|	SalesReg.Folio.Client AS Client,
		|	SalesReg.Hotel AS Hotel,
		|	SUM(SalesReg.Sales) AS Sales,
		|	SalesReg.ParentDoc.Number AS DocNumber,
		|	SalesReg.Room AS Room,
		|	SalesReg.Service AS Service,
		|	SUM(SalesReg.DiscountSum) AS DiscountSum
		|FROM
		|	AccumulationRegister.Sales AS SalesReg
		|WHERE
		|	SalesReg.Folio IN
		|			(SELECT
		|				FolioList.Ref AS Ref
		|			FROM
		|				FolioList AS FolioList)
		|	AND CASE
		|			WHEN &qExcludedServicesIsEmpty
		|				THEN TRUE
		|			ELSE NOT SalesReg.Service IN (&qExcludedServicesList)
		|		END
		|	AND CASE
		|			WHEN &qRoomRateListIsEmpty
		|				THEN TRUE
		|			ELSE SalesReg.RoomRate IN (&qRoomRateList)
		|					OR SalesReg.RoomRate = VALUE(Catalog.RoomRates.EmptyRef)
		|		END
		|
		|GROUP BY
		|	SalesReg.Recorder.Ref,
		|	SalesReg.Hotel,
		|	SalesReg.DiscountCard,
		|	SalesReg.Folio,
		|	SalesReg.ParentDoc.Customer,
		|	SalesReg.ParentDoc.Number,
		|	SalesReg.Room,
		|	SalesReg.Folio.Client,
		|	SalesReg.Service
		|
		|HAVING
		|	SUM(SalesReg.Sales) <> 0
		|
		|ORDER BY
		|	DocNumber";
	
	vQuery.SetParameter("qCheckOutDate", pDate);
	vQuery.SetParameter("qHotel", Hotel);
	vQuery.SetParameter("qDuration", MinQuantityCalculateDays);
	vQuery.SetParameter("qEmpyCustomer", Catalogs.Customers.EmptyRef());
	vQuery.SetParameter("qEmpyClient", 	Catalogs.Clients.EmptyRef());
    vQuery.SetParameter("qVisitsCount", NumberOfGuestVisits);
    vQuery.SetParameter("qDirectSalesOnly", DirectSalesOnly);
    vQuery.SetParameter("qCustomerTypeWhiteList", CustomerTypesAllowed.UnloadColumn("CustomerType"));
    vQuery.SetParameter("qCustomerTypeIsEmpty", CustomerTypesAllowed.Count() =0);
    vQuery.SetParameter("qRoomRateList", RoomRatesAllowed.UnloadColumn("RoomRate"));
    vQuery.SetParameter("qRoomRateListIsEmpty", RoomRatesAllowed.Count()=0);  
	vQuery.SetParameter("qExcludedServicesList", ExcludedServices.UnloadColumn("Service"));
    vQuery.SetParameter("qExcludedServicesIsEmpty", ExcludedServices.Count()=0);
    vQuery.SetParameter("qClientTypeWhiteList", ClientTypesAllowed.UnloadColumn("ClientType"));
    vQuery.SetParameter("qClientTypeIsEmpty", ClientTypesAllowed.Count() =0);
	vQueryResult = vQuery.Execute().Unload();
	
	For each vRow in vQueryResult Do
		vDiscountCard = GetBonusesCard(vRow.Client, vRow.DiscountCard, vRow.Hotel); 
		If UseBonusesCardFromClient And ValueIsFilled(vDiscountCard) Or UseBonusesCardFromClient= False And ValueIsFilled(vDiscountCard) Then
			vRow.DiscountCard = vDiscountCard;
			If TypeOf(vRow.Ref) = Type("DocumentRef.Charge") Then
				vNewRow = vResult.Add();
				FillPropertyValues(vNewRow, vRow); 
			ElsIf TypeOf(vRow.Ref) = Type("DocumentRef.Storno") Then
				vNewRow = vResult.Add();
				FillPropertyValues(vNewRow, vRow,,"Ref");
				vNewRow.Ref 		= vRow.Ref.ParentCharge;
				vNewRow.StornoRef 	= vRow.Ref; 
			EndIf;
		EndIf;
	EndDo;
	Return vResult;
EndFunction // GetCharges

// -----------------------------------------------------------------------------
Function GetBonusesCard(pClient, pDiscountCard, pHotel)
    vBonusesCard = Catalogs.DiscountCards.EmptyRef(); 
	If UseBonusesCardFromClient Then     
		vBonusesCard = pClient.DiscountCard;
	Else
		vBonusesCard = pDiscountCard; 
	EndIf;	
    // 1. Check the type of bonus card indicated
    If ValueIsFilled(vBonusesCard) And vBonusesCard.DiscountType.LoyaltyType = Enums.LoyaltyType.Bonuses Then
        // It's true
        Return vBonusesCard;
    EndIf; 
	// 2. Find the guest bonus card
	If UseBonusesCardFromClient = False Then
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	DiscountCards.Ref AS Ref,
		|	DiscountCards.Client AS Client
		|FROM
		|	Catalog.DiscountCards AS DiscountCards
		|WHERE
		|	NOT DiscountCards.DeletionMark
		|	AND NOT DiscountCards.IsBlocked
		|	AND (DiscountCards.ValidTo <= &qRequestDate
		|			OR DiscountCards.ValidTo = DATETIME(1, 1, 1))
		|	AND DiscountCards.Client = &qClient
		|	AND DiscountCards.CreateHotel = &qHotel
		|	AND DiscountCards.DiscountType.LoyaltyType = &qLoyaltyType
		|
		|ORDER BY
		|	DiscountCards.Code DESC";
		vQuery.SetParameter("qClient", 	pClient);
		vQuery.SetParameter("qLoyaltyType", Enums.LoyaltyType.Bonuses);
		vQuery.SetParameter("qRequestDate", CurrentSessionDate());
		vQuery.SetParameter("qHotel", pHotel);
		
		vDiscountCards = vQuery.Execute().Unload();
		If vDiscountCards.Count() > 0 Then
			vBonusesCard = vDiscountCards.Get(0).Ref;
		EndIf;
	EndIf;
    // 3. Create a bonus card
    If ValueIsFilled(DiscountType) And DiscountType.CreateDiscountCards And Not ValueIsFilled(vBonusesCard) Then
        Try
            vID = "";
            If DiscountType.NumberingRule = 0 Then  // by phone
               vID = pClient.Phone;
               If IsBlankString(vID) Then
                   // Log
                   If ExternalInteraction.DebugMode Then
                       vMessage = NStr("en = 'Discount Card Issue'; de = 'Ausgabe der Rabattkarte'; ru = 'Выпуск дисконтной карты'") + Chars.LF + Nstr("en = 'Phone number not specified'; de = 'Telefonnummer nicht angegeben'; ru = 'Не указан номер телефона'");
                       InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "CalculateBonuses.DiscountCardIssue", Enums.ExternalSystemEventTypes.Warning, , , vMessage);
                   EndIf;

                   // We don’t create a card without a phone number
                   Return vBonusesCard; 
               EndIf;
            EndIf;
             
            // Create a discount card
            vDCObj = Catalogs.DiscountCards.CreateItem();
            
            vDCObj.DiscountType = DiscountType;
            vDCObj.LoyaltyType = DiscountType.LoyaltyType;
			If DiscountType.Validity > 0 Then
				vDCObj.ValidFrom = BegOfDay(CurrentSessionDate());
				vDCObj.ValidTo = vDCObj.ValidFrom + DiscountType.Validity * 86400;
			EndIf;
            vDCObj.CreateHotel = ExternalInteraction.Hotel;
            vDCObj.Client = pClient;
            vDCObj.Identifier = TrimAll(vID);
            // Create discount card folio
            vDCObj.Folio = Catalogs.DiscountCards.CreateFolio(TrimAll(vDCObj.Identifier), vDCObj.LoyaltyType, vDCObj.Client, vDCObj.Customer);
            vDCObj.SetNewCode();
			
			If DiscountType.NumberingRule = 1 Then  // by catalog item code
                vDCObj.Identifier = vDCObj.Code;
            EndIf;

            // Save discount card
            vDCObj.Description = Catalogs.DiscountCards.GetCardDescription(vDCObj);
            vDCObj.Write();
            
            vBonusesCard = vDCObj.Ref;
            
            // Log
            If ExternalInteraction.DebugMode Then
                vMessage = NStr("en = 'Discount Card Issue'; de = 'Ausgabe der Rabattkarte'; ru = 'Выпуск дисконтной карты'") + Chars.LF + String(vBonusesCard);
                InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "CalculateBonuses.DiscountCardIssue", Enums.ExternalSystemEventTypes.Info, , , vMessage);
            EndIf;
        Except
            vErr = ErrorDescription();
            vMessage = NStr("en = 'Discount Card Issue'; de = 'Ausgabe der Rabattkarte'; ru = 'Выпуск дисконтной карты'") + Chars.LF + vErr;
            InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "CalculateBonuses.DiscountCardIssue", Enums.ExternalSystemEventTypes.Error, , , vMessage);
        EndTry;
    EndIf; 
    
    Return vBonusesCard;
EndFunction //  GetBonusesCard

// -----------------------------------------------------------------------------
Function GetResourcesBySales(pSales)
	vResult = New ValueTable;
	vResult.Columns.Add("DiscountCard");
	vResult.Columns.Add("Hotel");
	vResult.Columns.Add("DiscountDimension");
	vResult.Columns.Add("Resource");
	vResult.Columns.Add("Amount");
	vResult.Columns.Add("Bonuses");
	vResult.Columns.Add("GuestGroup");
	vResult.Columns.Add("PaidBonuses");
	vResult.Columns.Add("DocNumber");
	vResult.Columns.Add("Guest");
	vResult.Columns.Add("Room");
	vResult.Columns.Add("Service");  
	vResult.Columns.Add("DiscountType");
	vResult.Columns.Add("BonusCalculationFactor");
	
	For Each vCharge in pSales Do
		vGuestGroup = Undefined; 
		vDiscountType = vCharge.DiscountCard.DiscountType;
		If ValueIsFilled(vCharge.Folio) Then
			If ValueIsFilled(vCharge.Folio.GuestGroup) Then
				vGuestGroup = vCharge.Folio.GuestGroup;
			ElsIf ValueIsFilled(vCharge.Ref.ParentDoc) Then
				vGuestGroup = vCharge.Ref.ParentDoc.GuestGroup;
			EndIf;   
		EndIf;
		If vDiscountType.DifferentBonusCalculationFactorsForServiceGroupsAllowed Then
			vDiscountTypeObj = vDiscountType.GetObject();
			vBonusCalculationFactor = vDiscountTypeObj.pmGetBonusCalculationFactor(,vCharge.Service, vCharge.Hotel);   
		Else
			vBonusCalculationFactor = vDiscountType.BonusCalculationFactor;
		EndIf;
		vResource = CalculateResource(vCharge.Ref, vCharge.NumberOfPersons, vCharge.Folio, vCharge.DiscountCard,,,vCharge.Sales);
		If vResource <> 0 And vBonusCalculationFactor <> 0 Then
			vNewRow = vResult.Add();
			vNewRow.Hotel 			= vCharge.Hotel;
			vNewRow.Resource 		= vResource;
			vNewRow.DiscountCard 	= vCharge.DiscountCard;         
			vNewRow.DiscountType	= vDiscountType;
			vNewRow.Bonuses 		= vResource * vBonusCalculationFactor;
			vNewRow.GuestGroup 		= vGuestGroup;
			vNewRow.Amount 			= vCharge.Sales;
			vNewRow.DocNumber		= vCharge.DocNumber;
			vNewRow.Room			= vCharge.Room;
			vNewRow.Guest			= vCharge.Client;
			vNewRow.Service			= vCharge.Service;
			vNewRow.BonusCalculationFactor	= vBonusCalculationFactor;
		EndIf;	
	EndDo;
	vResult.Sort("DiscountDimension");
	Return vResult;
EndFunction //  GetResourcesBySales

// -----------------------------------------------------------------------------
Procedure CreateBonusesOperationDocuments(pResources, pDate)
	If pResources.Count() = 0 Then
		Return;
	EndIf;
	For Each vRow in pResources Do
		If vRow.Bonuses = 0 Or Not ValueIsFilled(vRow.DiscountCard) Then
			Continue;	
		EndIf;
		vDocObj = getDoc(pDate, vRow.DiscountCard, vRow.GuestGroup, vRow.Room);
		Try   
			If vDocObj = Undefined Then
				vDocObj = Documents.BonusesOperation.CreateDocument();
			EndIf;
			
			vDocObj.OperationType	= Enums.BonusesOperationTypes.Receipt;
			vDocObj.Date 			= BegOfDay(pDate);
			vDocObj.Author 			= SessionParameters.CurrentUser;
			vDocObj.Hotel 			= vRow.Hotel;

			vDocObj.Guest           = vRow.Guest;
			vDocObj.GuestGroup 		= vRow.GuestGroup;
			vDocObj.Card 			= vRow.DiscountCard;
			vDocObj.Room            = vRow.Room;
			vDocObj.BonusesQuantity	= vRow.Bonuses;
			vDocObj.Remarks			= vRow.Remarks; 
			vDocObj.Source			= Source;
			
			vDocObj.Write(DocumentWriteMode.Posting);
		Except
			vErr = ErrorDescription();
            InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "CalculateBonuses.CreateBonusesOperation", Enums.ExternalSystemEventTypes.Error, , , vErr);
		EndTry;
	EndDo;                      
EndProcedure //  CreateBonusesOperationDocuments

// -----------------------------------------------------------------------------
Function getDoc(Val pDate, pDiscountCard, pGuestGroup, pRoom)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Bonuses.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.Bonuses AS Bonuses
	|WHERE
	|	Bonuses.Recorder.GuestGroup = &qGuestGroup
	|	AND Bonuses.Card = &qCard
	|	AND Bonuses.Period = &qDate
	|	AND Bonuses.Recorder.Room = &qRoom";
	
	vQuery.SetParameter("qDate", BegOfDay(pDate));
	vQuery.SetParameter("qCard", pDiscountCard);
	vQuery.SetParameter("qGuestGroup", pGuestGroup);
	vQuery.SetParameter("qRoom", pRoom);
	
	vRes = vQuery.Execute();
	If vRes.IsEmpty() Then
		Return Undefined;
	Else
		Return vRes.Unload()[0].Recorder.GetObject();
	EndIf;	
EndFunction //  getDoc       

// -----------------------------------------------------------------------------
Function GetBonusesPayments(pRow)
	vSumBonuses = 0;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SUM(ISNULL(Payments.Sum, 0)) AS Sum
		|FROM
		|	AccumulationRegister.Payments AS Payments
		|WHERE
		|	Payments.Hotel = &qHotel
		|	AND Payments.PaymentMethod.IsByBonuses
		|	AND Payments.ParentDoc.GuestGroup = &qGuestGroup
		|	AND Payments.ParentDoc.Number = &qDocNumber
		|
		|HAVING
		|	SUM(ISNULL(Payments.Sum, 0)) > 0";
	
	Query.SetParameter("qDocNumber", pRow.DocNumber);
	Query.SetParameter("qGuestGroup", pRow.GuestGroup);
	Query.SetParameter("qHotel", pRow.Hotel);
	
	QueryResult = Query.Execute();
	
	vRes = QueryResult.Select();
	
	While vRes.Next() Do
		vSumBonuses = vRes.Sum;
	EndDo;
	
	Return vSumBonuses;	

EndFunction //  GetBonusesPayments

// -----------------------------------------------------------------------------
Function GetServicesPayments(pRow)
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SUM(ISNULL(Accounts.Sum, 0)) AS Sum,
	|	Accounts.ChequeService AS Service
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	NOT Accounts.PaymentMethod.IsByBonuses
	|	AND Accounts.Hotel = &qHotel
	|	AND Accounts.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND Accounts.Recorder.ParentDoc.GuestGroup = &qGuestGroup
	|	AND Accounts.Recorder.ParentDoc.Number = &qDocNumber
	|
	|GROUP BY
	|	Accounts.ChequeService";
	
	Query.SetParameter("qDocNumber", pRow.DocNumber);
	Query.SetParameter("qGuestGroup", pRow.GuestGroup);
	Query.SetParameter("qHotel", pRow.Hotel);
	
	vRes = Query.Execute().Unload();
	
	Return vRes;	
EndFunction //  GetServicesPayments

// -----------------------------------------------------------------------------
Function CalculateResource(pSrvRec, pNumberOfPersons, pFolio, pDiscountCard, rDiscountDimension = Undefined, pIsResourceReservation = False, pSum = 0) 
	vRes = 0;
	rDiscountDimension = Undefined;
	vFolio = pFolio;
	vAccumulatingDiscountDimension = pDiscountCard.DiscountType.AccumulatingDiscountDimension;
	vAccumulatingDiscountType = pDiscountCard.DiscountType.AccumulatingDiscountType;
	vNumberOfPersons = ?(pNumberOfPersons > 0, pNumberOfPersons, 1);
	If ValueIsFilled(vAccumulatingDiscountDimension) Then
		If vAccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Client Then
			If ValueIsFilled(vFolio.Client) Then
				rDiscountDimension = vFolio.Client;
			Else
				rDiscountDimension = Catalogs.Clients.EmptyRef();
			EndIf;
		ElsIf vAccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Customer Then
			If Not ValueIsFilled(vFolio.Customer) Then
				Return 0;
			Else
				rDiscountDimension = vFolio.Customer;
			EndIf;
		ElsIf vAccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Contract Then
			If Not ValueIsFilled(vFolio.Contract) Then
				Return 0;
			Else
				rDiscountDimension = vFolio.Contract;
			EndIf;
		ElsIf vAccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Agent Then
			If Not ValueIsFilled(vFolio.Agent) Then
				Return 0;
			Else
				rDiscountDimension = vFolio.Agent;
			EndIf;
		ElsIf vAccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.DiscountCard Then
			If Not ValueIsFilled(pDiscountCard) Then
				Return 0;
			Else
				rDiscountDimension = pDiscountCard;
			EndIf;
		EndIf;
	Else
		Return 0;
	EndIf;
	If vAccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByAccommodationDuration Then
		If Not pIsResourceReservation Then
			If pSrvRec.IsRoomRevenue Then
				If pSrvRec.RoomsRented <> 0 Or pSrvRec.BedsRented <> 0 Then
					vRes = pSrvRec.GuestDays/vNumberOfPersons;
				EndIf;
			EndIf;
		EndIf;
	ElsIf vAccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByNumberOfGuestVisits Then
		If Not pIsResourceReservation Then
			If pSrvRec.IsRoomRevenue Then
				If pSrvRec.RoomsRented <> 0 Or pSrvRec.BedsRented <> 0 Then
					vRes = pSrvRec.GuestsCheckedIn/vNumberOfPersons;
				EndIf;
			EndIf;
		EndIf;
	ElsIf vAccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByServicesTotalSum Then
		vRes = pSum;
	ElsIf vAccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByServiceQuantity Then
		vRes = pSrvRec.Quantity;
	ElsIf vAccumulatingDiscountType = Enums.AccumulatingDiscountTypes.External Then
		Execute(TrimR(pDiscountCard.DiscountType.ExternalAlgorithm.Algorithm));
	EndIf;
	Return vRes;
EndFunction //  pmCalculateResource

#EndRegion

