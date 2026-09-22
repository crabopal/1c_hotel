
#Region FormEventHandlers

// ------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Hotel = SessionParameters.CurrentHotel;
	
	If Parameters.Property("DocRef") Then
		vDocRef = Parameters.DocRef;
		
		If ValueIsFilled(vDocRef) Then
			DocRef     = vDocRef;
			Hotel 	   = vDocRef.Hotel;
		EndIf;	
		
		vNewRow = GuestsList.Add();
		vNewRow.Check = True;
		vNewRow.Guest = vDocRef.Guest;
		vNewRow.AccommodationType =	vDocRef.AccommodationType;
		vNewRow.DocRef = vDocRef;
		vNewRow.BottomText = String(vDocRef.AccommodationType) + NStr("en = ' from '; ru = ' с '; de = ' von '") + Format(vDocRef.CheckInDate,"DF=dd.MM.yyyy") + NStr("en = ' to '; ru = ' по '; de = ' zu '") + Format(vDocRef.CheckOutDate,"DF=dd.MM.yyyy");
	EndIf;
	
	If Parameters.Property("GuestsToCheckInList") Then
		For Each vItem In Parameters.GuestsToCheckInList Do
			vItemRef = vItem.Value;
			If GuestsList.FindRows(New Structure("DocRef", vItemRef)).Count() > 0 Then
				Continue;
			EndIf;	
			vNewRow = GuestsList.Add();
			If ValueIsFilled(DocRef) And BegOfDay(DocRef.CheckInDate) <> BegOfDay(vItemRef.CheckInDate) Then
				vNewRow.Check = False;
			Else
				vNewRow.Check = True;
			EndIf;
			vNewRow.Guest = vItemRef.Guest;
			vNewRow.AccommodationType =	vItemRef.AccommodationType;
			vNewRow.DocRef = vItemRef;	
			vNewRow.BottomText = String(vItemRef.AccommodationType) + NStr("en = ' from '; ru = ' с '; de = ' von '") + Format(vItemRef.CheckInDate,"DF=dd.MM.yyyy") + NStr("en = ' to '; ru = ' по '; de = ' zu '") + Format(vItemRef.CheckOutDate,"DF=dd.MM.yyyy");
		EndDo;
	EndIf;
	
	vDocList = GuestsList.Unload( , "DocRef");
	vBalances = GetBalancesByGuests(vDocList);
	For Each vRow In GuestsList Do
		vDocRef = vRow.DocRef;
		vBalances.Reset();
		If vBalances.FindNext(New Structure("DocRef", vDocRef)) Then
			
			vCurrency = Undefined;
			If ValueIsFilled(vRow.DocRef.Hotel) Then
				vCurrency = vRow.DocRef.Hotel.FolioCurrency;
			EndIf;
			
			vRow.Balance = vBalances.ClientSumBalance;
			vRow.LimitBalance = vBalances.ClientLimitBalance;
			vBalance = ?(ValueIsFilled(vCurrency), cmFormatSum(vBalances.ClientSumBalance, vCurrency), vBalances.ClientSumBalance);
			vRow.BalancePresentation = vBalance;
			vRow.SumAndLimBalanceDef = vBalances.ClientSumBalance - vBalances.ClientLimitBalance;
			
			// Change text in BalancePresentation
			vCAItem = ConditionalAppearance.Items.Add();
			vCAItem.UserSettingID = vRow.GetID();
			vCAItem.Use = True;
			
			vFilterItem = vCAItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			vFilterItem.Use = True;
			vFilterItem.LeftValue = New DataCompositionField("GuestsList.LimitBalance");
			vFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
			vFilterItem.RightValue = 0;

			vNewField = vCAItem.Fields.Items.Add();
			vNewField.Use = True;
			vNewField.Field = New DataCompositionField("GuestsListBalancePresentation"); 
			vCAItem.Appearance.SetParameterValue("Text", ?(ValueIsFilled(vCurrency), cmFormatSum(vRow.Balance, vCurrency), vRow.Balance) 
														 + Chars.LF + 
														 ?(ValueIsFilled(vCurrency), cmFormatSum(vRow.LimitBalance, vCurrency), vRow.LimitBalance));
			
			// Repaint text in green
			vCAItem = ConditionalAppearance.Items.Add();
			vCAItem.UserSettingID = vRow.GetID();
			vCAItem.Use = True;
			
			vFilterItem = vCAItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			
			vFilterItem.Use = True;
			vFilterItem.LeftValue = New DataCompositionField("GuestsList.SumAndLimBalanceDef");
			vFilterItem.ComparisonType = DataCompositionComparisonType.LessOrEqual;
			vFilterItem.RightValue = 0;
			
			vNewField = vCAItem.Fields.Items.Add();
			vNewField.Use = True;
			vNewField.Field = New DataCompositionField("GuestsListBalancePresentation"); 
			vCAItem.Appearance.SetParameterValue("TextColor", WebColors.Green);
		EndIf;
	EndDo;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------
&AtClient
Procedure ExecuteAction(pCommand)
	// Check attributes
	vThereAreCheckedGuests = False;
	vGuestsToCheckInList = New ValueList();
	For Each vRowData In GuestsList Do
		If ValueIsFilled(vRowData.DocRef) Then
			If vRowData.Check Then
				vThereAreCheckedGuests = True;
			EndIf;
			If DocRef = vRowData.DocRef Then
				vRowData.Check = True;
			EndIf;
			If vRowData.Check Then
				vGuestsToCheckInList.Add(vRowData.DocRef);
			EndIf;
		EndIf;
	EndDo;
	
	If vThereAreCheckedGuests Then
		// APDEX
		vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
		vApdexRemarks = GetRemarksForAPDEX(DocRef);
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

		// Open new accommodation and fill group table from the given list
		If ValueIsFilled(tcOnServer.cmGetAttributeByRef(DocRef, "AccommodationTemplate")) Then
			OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList, DoNotCheckDatesAtCheckIn", vGuestsToCheckInList, True));
		Else
			OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList, DoNotCheckDatesAtCheckIn, DoNotChangeNumberOfGuestsMode", vGuestsToCheckInList, True, True));
		EndIf;
	EndIf;
	
	// Close form
	ThisObject.Close();
EndProcedure // ExecuteAction

// ------------------------------------------------------------------------------
&AtClient
Procedure SelectAllGuests(pCommand)
	For Each vGuestRow In GuestsList Do
		vGuestRow.Check = True;
	EndDo;
EndProcedure // SelectAllGuests

// ------------------------------------------------------------------------------
&AtClient
Procedure DeselectAllGuests(pCommand)
	For Each vGuestRow In GuestsList Do
		If DocRef <> vGuestRow.DocRef Then 
			vGuestRow.Check = False;
		EndIf;
	EndDo;
EndProcedure // DeselectAllGuests

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetBalancesByGuests(pList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Ref,
	|	Folio.ParentDoc AS ParentDoc,
	|	ISNULL(Customers.IsIndividual, TRUE) AS IsIndividual
	|INTO FolioListByAllGuests
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|WHERE
	|	NOT Folio.DeletionMark
	|	AND Folio.ParentDoc IN(&qList)
	|
	|UNION
	|
	|SELECT
	|	Folio.Ref,
	|	Folio.ParentDoc,
	|	ISNULL(Customers.IsIndividual, TRUE)
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|WHERE
	|	NOT Folio.DeletionMark
	|	AND CAST(Folio.ParentDoc AS Document.Accommodation).ParentDoc IN (&qList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.FolioParentDoc AS DocRef,
	|	SUM(AccountsBalance.ClientSumBalance) AS ClientSumBalance,
	|	SUM(AccountsBalance.ClientLimitBalance) AS ClientLimitBalance,
	|	SUM(AccountsBalance.CustomerSumBalance) AS CustomerSumBalance
	|FROM
	|	(SELECT
	|		FolioListByAllGuests.ParentDoc AS FolioParentDoc,
	|		CASE
	|			WHEN FolioListByAllGuests.IsIndividual
	|				THEN ClientAccountsBalance.SumBalance
	|			ELSE 0
	|		END AS ClientSumBalance,
	|		CASE
	|			WHEN FolioListByAllGuests.IsIndividual
	|				THEN -ClientAccountsBalance.LimitBalance
	|			ELSE 0
	|		END AS ClientLimitBalance,
	|		CASE
	|			WHEN FolioListByAllGuests.IsIndividual
	|				THEN 0
	|			ELSE ClientAccountsBalance.SumBalance
	|		END AS CustomerSumBalance
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				,
	|				FolioCurrency = Hotel.FolioCurrency
	|					AND Folio IN
	|						(SELECT
	|							FolioListByAllGuests.Ref AS Ref
	|						FROM
	|							FolioListByAllGuests AS FolioListByAllGuests)) AS ClientAccountsBalance
	|			INNER JOIN FolioListByAllGuests AS FolioListByAllGuests
	|			ON ClientAccountsBalance.Folio = FolioListByAllGuests.Ref) AS AccountsBalance
	|
	|GROUP BY
	|	AccountsBalance.FolioParentDoc";
	vQry.SetParameter("qList", pList);
	vBalances = vQry.Execute().Select();
	vBalances.Reset();
	Return vBalances;
EndFunction // GetBalancesByGuests

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRemarksForAPDEX(pObject, pIsAccommodation = False)
	
	vAPDEXParams = New Structure;         
	vAPDEXParams.Insert("Number", pObject.Number); 
	If pIsAccommodation Then
		vAPDEXParams.Insert("Status", String(pObject.AccommodationStatus));
	Else	
		vAPDEXParams.Insert("Status", String(pObject.ReservationStatus));
	EndIf;
	vAPDEXParams.Insert("CheckInDate", String(pObject.CheckInDate));
	vAPDEXParams.Insert("CheckOutDate", String(pObject.CheckOutDate));
	vAPDEXParams.Insert("RoomType", String(pObject.RoomType));
	vAPDEXParams.Insert("RoomRate", String(pObject.RoomRate)); 
	vAPDEXParams.Insert("GuestGroup", String(pObject.GuestGroup));
	vAPDEXParams.Insert("Guest", String(pObject.Guest));  
	vAPDEXParams.Insert("RoomQuota", String(pObject.RoomQuota));
	
	Return vAPDEXParams;
EndFunction // GetRemarksForAPDEX

#EndRegion
