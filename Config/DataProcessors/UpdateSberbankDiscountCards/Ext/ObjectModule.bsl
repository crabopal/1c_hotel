#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameter
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	pmFillAttributesWithDefaultValues();
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	
	If Not ValueIsFilled(CheckOutDate) Then
		CheckOutDate = BegOfDay(CurrentSessionDate()) - 24*3600;
	EndIf;	
	
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter		 - Structure - Parameter
//  pIsInteractive	 - Boolean	 - Is interactive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#IF CLIENT THEN
		OpenForm("DataProcessor.UpdateSberbankDiscountCards.Form.Form",New Structure("DataProcessor",ThisObject.DataProcessor),,,,,,FormWindowOpeningMode.Independent);
	#ELSE
		UpdateCards();
	#ENDIF
	
EndProcedure // pmRun

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure UpdateCards()
	pmLoadDataProcessorAttributes();
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Accommodation.DiscountCard,
	|	Accommodation.Guest
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	NOT Accommodation.DeletionMark
	|	AND Accommodation.CheckOutDate BETWEEN &qBegCheckOutDate AND &qEndCheckOutDate
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.DiscountType = &qDiscountType";
	
	vQuery.SetParameter("qBegCheckOutDate", BegOfDay(CheckOutDate));
	vQuery.SetParameter("qDiscountType",    DiscountType);
	vQuery.SetParameter("qEndCheckOutDate", EndOfDay(CheckOutDate));
	vQuery.SetParameter("qHotel",           Hotel);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do	
		If not ValueIsFilled(vSelectionDetailRecords.DiscountCard.Client) Then
			vDiscountCardObject = vSelectionDetailRecords.DiscountCard.GetObject();
			vDiscountCardObject.Client = vSelectionDetailRecords.Guest;
			vDiscountCardObject.Write();
		EndIf;		
	EndDo;
EndProcedure // UpdateCards

#EndRegion
