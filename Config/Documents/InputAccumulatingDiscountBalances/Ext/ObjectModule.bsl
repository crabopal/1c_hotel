
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Accumulating discount resources
	If ValueIsFilled(DiscountType) Then 
		If Not DiscountType.ExternalBonusSystemIsUsed Then
			If DiscountType.IsAccumulatingDiscount Then
				PostAccumulatingDiscountResources();
			EndIf;
			If DiscountType.LoyaltyType = Enums.LoyaltyType.Bonuses And ValueIsFilled(Source) Then
				CreateBonusesOperations(pCancel);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Posting

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
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		Else
			vThereAreChanges = False;
			If Ref.Balances.Count() = Balances.Count() Then
				For i = 0 To (Balances.Count() - 1) Do
					vOldRow = Ref.Balances.Get(i);
					vNewRow = Balances.Get(i);
					If vOldRow.DiscountDimension <> vNewRow.DiscountDimension Or vOldRow.Resource <> vNewRow.Resource Or vOldRow.Bonus <> vNewRow.Bonus Then
						vThereAreChanges = True;
						Break;
					EndIf;
				Enddo;
			Else
				vThereAreChanges = True;
			EndIf;
			If vThereAreChanges Then
				If Not ValueIsFilled(ChangeDate) And ValueIsFilled(Date) Then
					ChangeDate = Date;
				Else
					ChangeDate = CurrentSessionDate();
				EndIf;
				ChangeAuthor = SessionParameters.CurrentUser;
				IsChanged = True;
			EndIf;
		EndIf;
	Else
		If Ref.Posted And (pWriteMode = DocumentWriteMode.UndoPosting Or DeletionMark) Then
			ChangeAuthor = SessionParameters.CurrentUser;
			ChangeDate = CurrentSessionDate();
			IsChanged = True;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

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
Procedure OnWrite(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf;  
EndProcedure // OnWrite

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	DeleteBonusesOperations(pCancel);
EndProcedure // UndoPosting

#EndRegion

#Region Public

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
	// Check that attributes are filled
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Attribut <Hotel> sollte ausgefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(DiscountType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тип скидки> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Discount type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Attribut <Rabatttyp> sollte ausgefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "DiscountType", pAttributeInErr);
	EndIf;
	If ValueIsFilled(DiscountType) And Not DiscountType.IsAccumulatingDiscount And DiscountType.LoyaltyType <> Enums.LoyaltyType.Bonuses Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Вид лояльности должен быть Бонусы или тип скидки должен быть накопительным!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "Loyalty type should be Bonuses or discount type should be accumulating!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Treuetyp sollte Boni sein oder Rabatttyp sollte akkumulieren sein!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "DiscountType", pAttributeInErr);
	EndIf;
	If ValueIsFilled(DiscountType) And DiscountType.IsAccumulatingDiscount And Not ValueIsFilled(DiscountType.AccumulatingDiscountDimension) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Измерение накопительной скидки> у типа скидки должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "Discount type <Accumulating discount dimension> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Rabatttyp Attribut <Kumulierende Rabattdimension> sollte ausgefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "DiscountType", pAttributeInErr);
	EndIf;
	// Check rows
	For Each vRow In Balances Do
		If Not ValueIsFilled(vRow.DiscountDimension) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В строке " + Format(vRow.LineNumber, "ND=6; NFD=0; NG=") + " реквизит <Измерение накопительной скидки> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Accumulating discount dimension type> attribute should be filled in row " + Format(vRow.LineNumber, "ND=6; NFD=0; NG=") + "!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Accumulating discount dimension type> attribute should be filled in row " + Format(vRow.LineNumber, "ND=6; NFD=0; NG=") + "!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Balances", pAttributeInErr);
			Break;
		EndIf;
	EndDo;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckDocumentAttributes

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
	Hotel = SessionParameters.CurrentHotel;
EndProcedure // pmFillAttributesWithDefaultValues

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure PostAccumulatingDiscountResources()
	RegisterRecords.AccumulatingDiscountResources.Clear();
	For Each vRow In Balances Do
		Movement = RegisterRecords.AccumulatingDiscountResources.AddReceipt();
		FillPropertyValues(Movement, ThisObject);
		FillPropertyValues(Movement, vRow);
		Movement.Period = Date;
		If ValueIsFilled(DiscountType) And DiscountType.BonusCalculationFactor <> 0 Then
			Movement.Resource = 0;
		Else
			Movement.Bonus = 0;
		EndIf;
	EndDo;
	RegisterRecords.AccumulatingDiscountResources.Write();
EndProcedure // PostAccumulatingDiscountResources

// -----------------------------------------------------------------------------
Procedure CreateBonusesOperations(pCancel)
	vDocsList = GetListOfBonusesOperations();
	
	i = 0;
	For Each vBalRow In Balances Do
		If ValueIsFilled(vBalRow.DiscountDimension) And 
		   TypeOf(vBalRow.DiscountDimension) = Type("CatalogRef.DiscountCards") And 
		   vBalRow.Bonus <> 0 Then
			vBOObj = Undefined;
			If i < vDocsList.Count() Then
				vBOObj = vDocsList.Get(i).Ref.GetObject();
			Else
				vBOObj = Documents.BonusesOperation.CreateDocument();
			EndIf;
			vBOObj.Fill(vBalRow.DiscountDimension);
			vBOObj.Author = Author;
			vBOObj.Date = Date;
			vBOObj.Hotel = Hotel;
			vBOObj.Source = Source;
			vBOObj.GuestGroup = vBalRow.GuestGroup;
			vBOObj.ParentDoc = Ref;
			vBOObj.DeletionMark = False;
			vBOObj.BonusesQuantity = vBalRow.Bonus;
			vBOObj.Write(DocumentWriteMode.Posting);
			
			i = i + 1;
		EndIf;
	EndDo;
EndProcedure // CreateBonusesOperations

// -----------------------------------------------------------------------------
Procedure DeleteBonusesOperations(pCancel)
	vDocsList = GetListOfBonusesOperations();
	For Each vDocsListRow In vDocsList Do
		If Not vDocsListRow.DeletionMark Then
			vBOObj = vDocsListRow.Ref.GetObject();
			vBOObj.SetDeletionMark(True);
		EndIf;
	EndDo;
EndProcedure // DeleteBonusesOperations

// -----------------------------------------------------------------------------
Function GetListOfBonusesOperations()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BonusesOperation.Ref AS Ref,
	|	BonusesOperation.DeletionMark AS DeletionMark
	|FROM
	|	Document.BonusesOperation AS BonusesOperation
	|WHERE
	|	BonusesOperation.ParentDoc = &qParentDoc
	|
	|ORDER BY
	|	BonusesOperation.PointInTime";
	vQry.SetParameter("qParentDoc", Ref);
	vDocsList = vQry.Execute().Unload();
	Return vDocsList;
EndFunction // GetListOfBonusesOperations

#EndRegion
