
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not IsFolder Then
		If Left(TrimAll(Description), StrLen(TrimAll(Code))) <> TrimAll(Code) Then
			Description = TrimAll(Code) + ?(IsBlankString(Description), "", " - " + TrimAll(Description));
		EndIf;
		If ConnectedRoomTypes.Count() Then
			If Not DoesNotAffectRoomRevenueStatistics And IsVirtual Then
				DoesNotAffectRoomRevenueStatistics = True;
			EndIf;
			If IsVirtual Then
				IsVirtual = False;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Current hotel
	If Not ValueIsFilled(Owner) Then
		Owner = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//
// Parameters:
//  pMessage		 - String	 - Message
//  pAttributeInErr	 - String	 - Attributes with error
// 
// Returns:
//  Boolean - Has errors
//
Function pmCheckRoomTypeAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If Not ValueIsFilled(Owner) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Owner", pAttributeInErr);
	EndIf;
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
	If SortCode <> 0 Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	COUNT(*) AS Counter
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	RoomTypes.SortCode = &qSortCode
		|	AND RoomTypes.Ref <> &qRef";
		vQry.SetParameter("qSortCode", SortCode);		
		vQry.SetParameter("qRef", Ref);
		vQryRes = vQry.Execute().Unload();
		If vQryRes.Count() > 0 Then
			vRow = vQryRes.Get(0);
			If vRow.Counter > 0 Then 
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Реквизит <Порядок сортировки> не уникален! Укажите другой код." + Chars.LF;
				vMsgTextEn = vMsgTextEn + "<Sort code> attribute is not unique! Please, enter another code." + Chars.LF;
				vMsgTextDe = vMsgTextDe + "<Sort code> Attribut ist nicht einzigartig! Bitte geben Sie einen anderen Code." + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "SortCode", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If Not IsVirtual And Not IsFolder Then
		If NumberOfBedsPerRoom = 0 Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Реквизит <Количество мест в номере> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Number of beds per room> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "NumberOfBedsPerRoom", pAttributeInErr);
		EndIf;
		If NumberOfPersonsPerRoom = 0 Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Реквизит <Максимальное количество гостей в номере> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Number of persons per room> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "NumberOfPersonsPerRoom", pAttributeInErr);
		EndIf;	
	EndIf;
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckRoomTypeAttributes

// See Catalogs.RoomTypes. -----------------------------------------------------
//
// Parameters:
//  pLang	 - CatalogRef.Languages	 - Language
// 
// Returns:
//  String - Room type description
//
Function pmGetRoomTypeDescription(pLang) Export
	Return Catalogs.RoomTypes.pmGetRoomTypeDescription(Ref, pLang);
EndFunction // pmGetRoomTypeDescription

#EndRegion
