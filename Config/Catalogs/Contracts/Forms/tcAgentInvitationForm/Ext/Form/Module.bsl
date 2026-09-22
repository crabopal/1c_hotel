
#Region FormEventHandlers

// -----------------------------------------------------------------------------   
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing) 
	ExternalSystemInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionType(Enums.Integrations.HotelOnlineBooking);
	FillExternalParameters(); 
	If IsBlankString(Email) Then 
		Email = Object.Owner.EMail;	
	EndIf;	
EndProcedure //  OnCreateAtServer()

#EndRegion
   
#Region FormHeaderItemsEventHandlers
   
// -----------------------------------------------------------------------------   
&AtClient
Procedure EmailOnChange(pItem)
	FillAgentLinks();
EndProcedure //  EmailOnChange()
  
#EndRegion
   
#Region FormCommandsEventHandlers
   
// -----------------------------------------------------------------------------   
&AtClient
Procedure Save(pCommand)
	SaveAgentParams();
EndProcedure //  Save 

// -----------------------------------------------------------------------------   
&AtClient
Procedure Send(pCommand)   
	If CheckFilling() Then
		vParams = GenerateParametersByEMail();
		OpenForm("CommonForm.tcSendMail", vParams, ThisObject, UUID);    
	EndIf;
EndProcedure //  Send()

// -----------------------------------------------------------------------------   
&AtClient
Procedure GenerateAgentCode(pCommand)
	GenerateCode();  
	FillAgentLinks(); 
	SaveAgentParams();
EndProcedure //  GenerateAgentCode()

#EndRegion
   
#Region Private

// -----------------------------------------------------------------------------   
&AtServer
Procedure FillExternalParameters()
	If ValueIsFilled(ExternalSystemInteraction) Then 
		If ValueIsFilled(Object.Ref) Then
			vResTab = InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalSystemInteraction, "Agent", , Object.Ref);  
			If vResTab.Count() > 0 Then  
				AgentCode = vResTab[0].AgentCode;
				Email 	  = vResTab[0].Email;
			EndIf;
		EndIf;	
	EndIf;  
	FillAgentLinks();
EndProcedure //  FillExternalParameters()

// --------------------------------------------------------------------------------
&AtServer
Procedure FillAgentLinks() 
	vErr = CheckAgentEMail();
	If Not IsBlankString(vErr) Then
		Message = New UserMessage;
		Message.Text = vErr;
		Message.Field = "Email";
		Message.Message();	
		LinkRegastration = "";
		LinkAutorisation = "";
		Return;
	EndIf;	
	If Not IsBlankString(AgentCode) And Not IsBlankString(Email) And ValueIsFilled(ExternalSystemInteraction) Then 
		vHotelRef = SessionParameters.CurrentHotel;
		// Registration
		LinkRegastration = ExternalSystemInteraction.HttpAddress + "areg.php?email=" + TrimAll(Email) + "&hcode=" + TrimAll(vHotelRef.Code);	
		// Autorisation
		LinkAutorisation = ExternalSystemInteraction.HttpAddress + "?agent_code=" + TrimAll(AgentCode);  
		SaveAgentParams();
	EndIf;
EndProcedure //  FillExternalParameters() 

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveAgentParams() 
	vErr = CheckAgentEMail();
	If Not IsBlankString(vErr) Then
		Message = New UserMessage;
		Message.Text = vErr;
		Message.Field = "Email";
		Message.Message();	 
		Return;
	EndIf;	
	If ValueIsFilled(Object.Ref) And Not IsBlankString(AgentCode) And Not IsBlankString(Email) And ValueIsFilled(ExternalSystemInteraction) Then 
		vContract = Object.Ref; 
		InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(ExternalSystemInteraction, "Agent");
		InformationRegisters.ExternalSystemIntegrationData.WriteData(ExternalSystemInteraction, "Agent", "Email", vContract, Undefined, Email);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(ExternalSystemInteraction, "Agent", "AgentCode", vContract, Undefined, AgentCode);  
		
		// Try to update existing mapping or create new one  
		vMgrObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vMgrObj.Hotel = Object.Hotel;
		vMgrObj.ExternalSystemCode = "1CBITRIX";
		vMgrObj.ObjectTypeName = "Contracts";
		vMgrObj.ObjectExternalCode = TrimAll(Email);
		vMgrObj.ObjectRef = vContract;
		vMgrObj.Write(True);
		
		// Try to update existing mapping or create new one
		vMgrObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vMgrObj.Hotel = Object.Hotel;
		vMgrObj.ExternalSystemCode = "1CBITRIX";
		vMgrObj.ObjectTypeName = "Contracts";
		vMgrObj.ObjectExternalCode = TrimAll(AgentCode);
		vMgrObj.ObjectRef = vContract;
		vMgrObj.Write(True);
	EndIf;
EndProcedure //  SaveAgentParams()

// --------------------------------------------------------------------------------
&AtServer
Procedure GenerateCode()
	vRndGen = New RandomNumberGenerator();
	vCode = "";
	vExceptions = ":<=>?@;,\/|^[]#ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ_`"; 
	While StrLen(vCode) < 5 Do
		vChar = Char(vRndGen.RandomNumber(48, 122));
		If Find(vExceptions, vChar) > 0 Then
			Continue;
		EndIf;
		vCode = vCode + vChar;
	EndDo;
	AgentCode = vCode;
EndProcedure //  GenerateCode()

// --------------------------------------------------------------------------------
&AtServer
Function GenerateParametersByEMail()
	vHotel = SessionParameters.CurrentHotel; 
	vLanguage = SessionParameters.CurrentLanguage; 
	vTemplate = vHotel.NewAgentInvitationMessageTemplate;  
	vEMailList = New ValueList();
	vEMailList.Add(TrimAll(Email));

	// Sender name
	vSenderName = ?(ValueIsFilled(vHotel), Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLanguage), "");
	vIsHTML = False;  
	vMessageText = "";
	If ValueIsFilled(vTemplate) Then
		If ValueIsFilled(vTemplate.HTMLTextRu) Or ValueIsFilled(vTemplate.HTMLTextEn) Or ValueIsFilled(vTemplate.HTMLTextDe) Then
			vMessageText = SMS.GetHTMLTextByLanguage(vTemplate, vLanguage);
			If Not IsBlankString(vMessageText) Then
				vIsHTML = True;
			EndIf;
		EndIf;
		If IsBlankString(vMessageText) Then
			vMessageText = SMS.GetSMSTextByLanguage(vTemplate, vLanguage);
		EndIf;
	EndIf;
		
	If Not IsBlankString(vMessageText) Then 
		vMessageSubject = cmNStr(TrimAll(vTemplate.Description), vLanguage);
		// Fill text template    
		vMessageText = StrReplace(vMessageText, "&AgentEmail", TrimAll(Email));
		vMessageText = StrReplace(vMessageText, "&AgentCode", TrimAll(AgentCode));
		vMessageText = StrReplace(vMessageText, "&AgentContractNumber", TrimAll(Object.Code)); 
		vMessageText = StrReplace(vMessageText, "&AgentContractDesc", TrimAll(Object.Description));
		vMessageText = StrReplace(vMessageText, "&AgentCustomerDesc", TrimAll(Object.Owner.Description));
		vMessageText = StrReplace(vMessageText, "&HotelName", TrimAll(vSenderName));
		vMessageText = StrReplace(vMessageText, "&AgentRegLink", LinkRegastration);
		vMessageText = StrReplace(vMessageText, "&AgentAuthLink", LinkAutorisation);
	Else 
		// Initialize message texts
		vMessageSubject = NStr("en='New agent registration'; de='New agent registration'; ru='Регистрация нового агента'");
	   
		vMessageText = Nstr("en = 'Agent ID: %1
		                    |Contract number: %2
		                    |Contract name: %3
		                    |Registration link: %4
		                    |Booking link: %5'; de = 'Agenten-ID: %1
		                    |Vertragsnummer: %2
		                    |Vertragsname: %3
		                    |Registrierungslink: %4
		                    |Buchungslink: %5'; ru = 'Код агента: %1
		                    |Номер договора : %2
		                    |Наименование договора: %3
		                    |Ссылка для регистрации: %4
		                    |Ссылка для бронирования: %5'");    
	   
		vMessageText = StrTemplate(vMessageText, AgentCode, TrimAll(Object.Code), TrimAll(Object.Description), LinkRegastration, LinkAutorisation); 
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'The hotel settings do not specify a new agent invitation template or the invitation text is empty. The text of the letter is formed by default.'; 
		                                                |de = 'Die Hoteleinstellungen geben keine neue Einladungsvorlage für Agenten an oder der Einladungstext ist leer. Der Text des Briefes wird standardmäßig gebildet.'; 
		                                                |ru = 'В настройках гостиницы не указан шаблон приглашения нового агента или текст приглашения пустой. Текст письма сформирован по умолчанию.'"));
	EndIf;	
	
	vParams = New Structure();
	vParams.Insert("SelMessageSubject", vMessageSubject);
	vParams.Insert("SelMessageText", vMessageText);
	vParams.Insert("SelEMails", "");
	vParams.Insert("SelToList", vEMailList);
	vParams.Insert("SelLanguage", vLanguage);
	vParams.Insert("SelSenderName", vSenderName);
	vParams.Insert("SelHotel", vHotel);
	vParams.Insert("IsHTML", vIsHTML); 
	vParams.Insert("SelDocument", Documents.Reservation.EmptyRef());
	vParams.Insert("SelSMSTemplates", vTemplate);

	Return vParams;
EndFunction //  GenerateParametersRequestByEMail()

// --------------------------------------------------------------------------------
&AtServer
Function CheckAgentEMail()
	vError = "";
	vTmpMsg = Nstr("en = 'This EMail is already linked to contract: %1, agent: %2'; 
				   |de = 'Diese E-Mail ist bereits mit Vertrag %1 verknüpft, agent: %2'; 
				   |ru = 'Данный EMail уже привязан к договору: %1, агента: %2'");
	
	vQuery = New Query;
	vQuery.Text = "SELECT
	              |	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
	              |FROM
	              |	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	              |WHERE
	              |	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	              |	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
	              |	AND ExternalSystemsObjectCodesMappings.ObjectExternalCode = &qObjectExternalCode
	              |	AND ExternalSystemsObjectCodesMappings.ObjectRef <> &qContract
	              |
	              |GROUP BY
	              |	ExternalSystemsObjectCodesMappings.ObjectRef";
	
	vQuery.SetParameter("qExternalSystemCode", "1CBITRIX");
	vQuery.SetParameter("qObjectTypeName", "Contracts");
	vQuery.SetParameter("qObjectExternalCode", TrimAll(Email));
	vQuery.SetParameter("qContract", Object.Ref);
	
	vResult = vQuery.Execute();
	vSelection = vResult.Select();
	
	While vSelection.Next() Do
		If IsBlankString(vError) Then
			vError = StrTemplate(vTmpMsg, vSelection.ObjectRef, vSelection.ObjectRef.Owner);	
		Else
			vError = vError + Chars.LF + vError = StrTemplate(vTmpMsg, vSelection.ObjectRef, vSelection.ObjectRef.Owner);	
		EndIf;	
	EndDo;
    Return vError;
EndFunction //  CheckAgentEMail()

#EndRegion  
