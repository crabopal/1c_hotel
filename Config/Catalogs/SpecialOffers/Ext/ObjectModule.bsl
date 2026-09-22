
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not IsFolder And Not ValueIsFilled(CreateDate) Then
		CreateDate = CurrentSessionDate();
		Author = SessionParameters.CurrentUser;
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure FillCheckProcessing(pCancel, pCheckedAttributes)
	If pCheckedAttributes.Find("Currency") = Undefined Then
		pCheckedAttributes.Add("Currency");
	EndIf;
EndProcedure // FillCheckProcessing

// --------------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	If Not IsFolder Then
		CreateDate = '00010101';
		Author = Undefined;
	EndIf;
EndProcedure // OnCopy

// --------------------------------------------------------------------------------
Procedure OnSetNewCode(pStandardProcessing, pPrefix)
	If IsBlankString(pPrefix) Then
		If IsBlankString(Code) Then
			vHotel = Hotel;
			If Not ValueIsFilled(vHotel) Then
				vHotel = SessionParameters.CurrentHotel;
			EndIf;
			If ValueIsFilled(vHotel) Then
				vPrefix = Catalogs.Hotels.pmGetPrefix(vHotel);
				If vPrefix <> "" Then
					pPrefix = vPrefix;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnSetNewCode

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion
