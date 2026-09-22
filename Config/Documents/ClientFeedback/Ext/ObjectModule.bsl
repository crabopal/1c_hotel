
#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(Survey) Then
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.CheckOutSurvey) Then
			Survey = Hotel.CheckOutSurvey;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Filling(pFillingData, pStandardProcessing)
	pmFillAttributesWithDefaultValues();
	If TypeOf(pFillingData) = Type("DocumentRef.Accommodation") Or TypeOf(pFillingData) = Type("DocumentRef.Reservation") Then
		ParentDoc 	= pFillingData.Ref;
		Client 		= pFillingData.Guest;
		Room 		= pFillingData.Room;
		If Hotel <> pFillingData.Hotel Then
			Hotel   = pFillingData.Hotel;
			SetNewNumber();
		EndIf;
	ElsIf TypeOf(pFillingData) = Type("DocumentRef.ResourceReservation") Then
		ParentDoc 	= pFillingData.Ref;	
		Client 		= pFillingData.Client;
		Room        = Undefined;
		If Hotel <> pFillingData.Hotel Then
			Hotel   = pFillingData.Hotel;
			SetNewNumber();
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	// Fill author and document date
	pmFillAuthorAndDate();
	// Clear answers
	Answers.Clear();
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion
