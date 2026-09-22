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
	pmWriteOffBonuses(pIsInteractive);	
EndProcedure // pmRun

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDateFrom	 - Date	 - Date from
//  pDateTo		 - Date	 - Date to
//
Procedure pmWriteOffBonuses(pIsInteractive = False) Export
	If Not ValueIsFilled(DiscountType) Then
		vMsg = Nstr("en = 'It is necessary to select the loyalty program!'; de = 'Es ist notwendig, das Treueprogramm auszuwählen!'; ru = 'Необходимо указать программу лояльности!'");
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMsg, MessageStatus.Attention);
		Else
			WriteLogEvent("DataProcessors.WriteOffExpiredBonuses", EventLogLevel.Warning, , , vMsg);
		EndIf;
		Raise vMsg;
	EndIf;
	If Not ValueIsFilled(AccountingDate) Then
		vMsg = Nstr("en = 'Accounting date should be filled!'; de = 'Rechnungsdatum sollte ausgefüllt werden!'; ru = 'Учетная дата должна быть заполнена!'");
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMsg, MessageStatus.Attention);
		Else
			WriteLogEvent("DataProcessors.WriteOffExpiredBonuses", EventLogLevel.Warning, , , vMsg);
		EndIf;
		Raise vMsg;
	EndIf;

	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BonusesBalance.Card AS Card,
	|	BonusesBalance.ExpiryDate AS ExpiryDate,
	|	BonusesBalance.QuantityBalance AS QuantityBalance
	|FROM
	|	AccumulationRegister.Bonuses.Balance(
	|			&qPeriod,
	|			Card.DiscountType IN HIERARCHY (&qLoyaltyProgram)
	|				AND (&qHotelIsFilled
	|						AND Card.CreateHotel IN HIERARCHY (&qHotel)
	|					OR NOT &qHotelIsFilled)
	|				AND ExpiryDate > &qEmptyDate) AS BonusesBalance
	|
	|ORDER BY
	|	BonusesBalance.Card.Identifier";
	vQry.SetParameter("qLoyaltyProgram", DiscountType);
	vQry.SetParameter("qPeriod", New Boundary(AccountingDate, BoundaryType.Excluding));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(Hotel));
	vQry.SetParameter("qEmptyDate", '00010101');
	vExpiredBonuses = vQry.Execute().Unload();
	// Create bonuses operations to write-off bonuses expired
	For Each vExpiredBonusesRow In vExpiredBonuses Do
		CreateBonusesOperationDocument(vExpiredBonusesRow);     
	EndDo;
EndProcedure // pmWriteOffBonuses

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure CreateBonusesOperationDocument(pExpiredBonusesRow)
	vDocObj = Documents.BonusesOperation.CreateDocument();
			
	vDocObj.OperationType = Enums.BonusesOperationTypes.Expense;

	vDocObj.Date = CurrentSessionDate();
	vDocObj.Author = SessionParameters.CurrentUser;
	
	vDocObj.Card = pExpiredBonusesRow.Card;
	vDocObj.ExpiryDate = pExpiredBonusesRow.ExpiryDate;

	vDocObj.BonusesQuantity = pExpiredBonusesRow.QuantityBalance;
	
	vDocObj.Hotel = pExpiredBonusesRow.Hotel;

	vDocObj.Guest = pExpiredBonusesRow.DiscountCard.Client;
	vDocObj.GuestGroup = Catalogs.GuestGroups.EmptyRef();
	vDocObj.Room = Catalogs.Rooms.EmptyRef();
	
	vDocObj.Source = Source;
	If ValueIsFilled(vDocObj.Source) Then
		vDocObj.Remarks = "";
	Else
		vDocObj.Remarks = NStr("en='Auto write-off by expiry date'; ru='Автосписание по истечению срока действия'; de='Automatische Abschreibung nach Ablaufdatum'");
	EndIf;
	
	vDocObj.Write(DocumentWriteMode.Posting);
EndProcedure //  CreateBonusesOperationDocuments

#EndRegion

