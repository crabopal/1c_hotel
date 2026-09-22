
#Region EventHandlers

 // -----------------------------------------------------------------------------
Procedure OnSetNewCode(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewCode

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)      
	If DataExchange.Load Then
		Return;
	EndIf;    
	If Not IsBlankString(Identifier) And DiscountType.NumberingRule = 0 Then
		Identifier = SMS.GetValidPhoneNumber(Identifier);	
	EndIf;	
	If Not DeletionMark Then
		If Not IsBlankString(Identifier) Then
	        vDiscountCard = cmGetDiscountCardById(Identifier);
	        If ValueIsFilled(vDiscountCard) And vDiscountCard <> Ref Then
				pCancel = True;
				vErr = Nstr("en = 'A card with this identifier already exists! Code: %1, Description: %2'; de = 'Eine Karte mit dieser Kennung existiert bereits! Code: %1, Beschreibung: %2'; ru = 'Карта с таким номером уже существует! Код: %1, Наименование: %2'");
				vErr  =  StrTemplate(vErr, vDiscountCard.Code, vDiscountCard.Description); 
				tcCommonFunctionOnClientServer.TextMessage(vErr);
				Return;
			EndIf;
		EndIf;
		If Not IsBlankString(Phone) AND ValueIsFilled(DiscountType) AND DiscountType.NumberingRule = 2 Then
			// NumberingRule = 2 - means that we use both fields as identifier - card code and phone number
	        vDiscountCard = cmGetDiscountCardByPhone(Phone);
	        If ValueIsFilled(vDiscountCard) And vDiscountCard <> Ref Then
	            pCancel = True;
	            vErr = Nstr("en = 'A card with this phone number already exists! Code: %1, Description: %2'; de = 'Eine Karte mit dieser Telefon existiert bereits! Code: %1, Beschreibung: %2'; ru = 'Карта с таким телефоном уже существует! Код: %1, Наименование: %2'");
	            vErr  =  StrTemplate(vErr, vDiscountCard.Code, vDiscountCard.Description); 
	            vUM = New UserMessage;
				vUM.SetData(ThisObject);
				vUM.Field = "Phone";
				vUM.Text = vErr;
				vUM.Message();
	            Return;
			EndIf;	
		EndIf;
    EndIf;
	If IsNew() Then
		If Not ValueIsFilled(Author) Then
			Author = SessionParameters.CurrentUser;
		EndIf;
		If Not ValueIsFilled(CreateDate) Then
			CreateDate = CurrentSessionDate();
		EndIf;
		If Not ValueIsFilled(CreateHotel) Then
			CreateHotel = SessionParameters.CurrentHotel;
		EndIf;
	EndIf;
	ChangeDate = CurrentSessionDate(); 
	ChangeAuthor = SessionParameters.CurrentUser; 
	If ValueIsFilled(DiscountType) Then
		If IsBlankString(Identifier) Then
			If DiscountType.NumberingRule = 0 Or DiscountType.NumberingRule = 2 Then
				Identifier = SMS.GetValidPhoneNumber(TrimAll(Phone));
				If IsBlankString(Identifier) And ValueIsFilled(Client) And Not IsBlankString(Client.Phone) Then
					Identifier = SMS.GetValidPhoneNumber(TrimAll(Client.Phone));
				EndIf;
			ElsIf DiscountType.NumberingRule = 1 Then
				Identifier = TrimAll(Code);
			EndIf;
		EndIf;
		If IsBlankString(Description) Then
			If Not IsBlankString(DiscountType.DiscountCardDescriptionTemplate) Then
				Description = Catalogs.DiscountCards.GetCardDescription(ThisObject);
			Else
				If Constants.UseDiscountCardIdentifierAsCardDescription.Get() Then
					Description = TrimAll(Identifier);
				ElsIf ValueIsFilled(Client) Then
					Description = TrimAll(Client.FullName) + ?(ValueIsFilled(Client.DateOfBirth), ", " + Format(Client.DateOfBirth, "DF=dd.MM.yyyy"), "");
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If IsBlocked Then
		If Not ValueIsFilled(IsBlockedAuthor) Then
			IsBlockedAuthor = SessionParameters.CurrentUser;
		EndIf;
		If Not ValueIsFilled(IsBlockedDate) Then
			IsBlockedDate = CurrentSessionDate();
		EndIf;
	Else
		If ValueIsFilled(IsBlockedAuthor) Then
			IsBlockedAuthor = Catalogs.Employees.EmptyRef();
		EndIf;
		If ValueIsFilled(IsBlockedDate) Then
			IsBlockedDate = '00010101';
		EndIf;
	EndIf;
    AdditionalProperties.Insert("IsNew", IsNew());
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)   
	If DataExchange.Load Then
		Return;
	EndIf;
	If ValueIsFilled(Client) And (Not ValueIsFilled(Client.DiscountCard) Or ValueIsFilled(Client.DiscountCard) And Client.DiscountCard.IsBlocked) Then
		If Constants.ClientsDoNotHaveToShowDiscountCardsToGetDiscounts.Get() Then
			vClientObj = Client.GetObject();
			vClientObj.DiscountCard = Ref;
			If ValueIsFilled(ClientType) Then
				vClientObj.ClientType = ClientType;
			EndIf;
			vClientObj.Write();
			vClientObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
    EndIf;
	If Not pCancel Then
		If AdditionalProperties.IsNew Then
        	SendSMS();
		EndIf;
    EndIf; 
EndProcedure // OnWrite

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	If Not IsFolder Then
		Folio = Documents.Folio.EmptyRef();
		CreateDate = CurrentSessionDate();
		Author = SessionParameters.CurrentUser;
		IsBlocked = False;
		IsBlockedAuthor = Catalogs.Employees.EmptyRef();
		IsBlockedDate = '00010101';
		Identifier = "";
		Description = "";
	EndIf;
EndProcedure // OnCopy

#EndRegion

#Region Internal

 // -----------------------------------------------------------------------------
Procedure SendSMS()
    vDiscountType = DiscountType;
    If vDiscountType.InformClientWhenCreationCard And ValueIsFilled(vDiscountType.DeliveryTypeInformClientWhenCreationCard) And ValueIsFilled(vDiscountType.SMSTemplateInformClientWhenCreationCard) Then
        vLanguage = Catalogs.Languages.RU;
        vDeliveryType = vDiscountType.DeliveryType;
        If ValueIsFilled(Client) Then
            vLanguage = Client.Language;
        EndIf;
        vSMSTemplate = vDiscountType.SMSTemplateInformClientWhenCreationCard;
        vSMSTemplateText = SMS.GetSMSTextByLanguage(vSMSTemplate, vLanguage);
        vSMSText = SMS.ReplaceSMSParameters(vSMSTemplateText, Documents.BonusesOperation.EmptyRef(), Client,,Ref);
        vOperationParametrs = New Array;
        vReceiversA = New Array();
        vReceiversA.Add(New Structure("LineNumber, Phone, EMail, Client, Customer, SMSText, Cost, IsSent, Result, MessageID, ClientDoc, ParentDoc, AmountStr, DiscountCard",
				        1,
				        Client.Phone,
				        Client.EMail,
				        Client,
				        Undefined,
				        vSMSText,
				        0,
				        False,
				        "",
				        "",
				        Ref,
						Documents.BonusesOperation.EmptyRef(),
						"",
						Ref));		
				        
				        vOperationParametrs.Add(vReceiversA);
				        vOperationParametrs.Add(vDiscountType.DeliveryType);
				        vOperationParametrs.Add(0);     // DistributionListId
				        vOperationParametrs.Add("");    // AttachmentPath
				        vOperationParametrs.Add(False); // IsByCustomers
				        vOperationParametrs.Add(vSMSTemplate);
				        vOperationParametrs.Add(vSMSTemplate.Sender);
        
        AsyncCalls.StartBackgroundJobWithRecordInRegister(Ref, "SMSDelivery_CreateDiscountCard", "ProlongedOperations.MessagesDeliverySend", vOperationParametrs);          
    EndIf;

EndProcedure

#EndRegion
