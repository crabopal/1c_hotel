// -----------------------------------------------------------------------------
// Reports framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
EndProcedure // pmLoadReportAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
    //// Fill parameters with default values
    //If Not ValueIsFilled(Hotel) Then
    //	Hotel = SessionParameters.CurrentHotel;
    //EndIf;
    //If Not ValueIsFilled(PeriodFrom) Then
    //	PeriodFrom = BegOfMonth(BegOfMonth(CurrentSessionDate()) - 1);
    //EndIf;
    //If Not ValueIsFilled(PeriodTo) Then
    //	PeriodTo = EndOfMonth(PeriodFrom);
    //EndIf;
EndProcedure // pmFillAttributesWithDefaultValues
