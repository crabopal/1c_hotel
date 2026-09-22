#Region FormEventHandlers

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	ReadConstants();	
	FormRefresh(); 
	If SMS.IsSMSDeliveryActive() Then
		// Check balance
		CheckBalance();
	EndIf;	
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure LinkRegistrationClick(pItem)
	If SMSGateway = PredefinedValue("Enum.SupportedSMSGateways.SMSC") Then
		#If ThinClient or WebClient Then
			GotoURL("https://smsc.ru/reg/?ad1chotel");
		#Else
			BeginRunningApplication(New NotifyDescription, "https://smsc.ru/reg/?ad1chotel");
		#EndIf	
	EndIf;
EndProcedure // LinkRegistrationClick

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure LinkRatesClick(pItem)
	#If ThinClient or WebClient Then
		GotoURL("http://sms.1chotel.ru/tariffs/");
	#Else
		BeginRunningApplication(New NotifyDescription, "http://sms.1chotel.ru/tariffs/");
	#EndIf
EndProcedure // LinkRatesClick

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure SMSGatewayOnChange(pItem)
	SMSSumBalance = "";
	FormRefresh();	
EndProcedure // SMSGatewayOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure SMSBalanceRefresh(pCommand)
	If CheckFieldsFilling() Then
		SetConstants(SMSLogin, SMSPassword, Company, SMSSenderName, SMSGateway);
	EndIf;    
	If Items.SMSBalanceGroup.Visible Then
		CheckBalance();  
	EndIf;
EndProcedure // SMSBalanceRefresh

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure OK(pCommand)
	vStatus = "";
	If CheckFieldsFilling() Then
		SetConstants(SMSLogin, SMSPassword, Company, SMSSenderName, SMSGateway); 
		vChecked = CheckBalance(vStatus);
		If OKAtServer(vStatus, vChecked) Then
			ShowMessageBox(,NStr("en='SMS delivery service is activated';ru='Подключена услуга рассылки СМС!';de='Sie wurden an den SMS-Verteiler-Dienst angeschlossen!'"),,NStr("en='Successfully!';ru='Данные успешно сохранены!';de='Die Daten wurden erfolgreich gespeichert!'"));
			ThisForm.Close();			
		Else
			ShowMessageBox(,NStr("en = 'Check if login and password is correct'; de = 'Überprüfen Sie die Richtigkeit der Dateneingabe!'; ru = 'Проверьте правильность ввода данных!'"),,NStr("en='Error!';ru='Ошибка!';de='Fehler!'"));
		EndIf;
	EndIf;
EndProcedure // OK

#EndRegion

#Region Private  

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure ReadConstants()
	SMSLogin = Constants.SMSLogin.Get();
	SMSPassword = Constants.SMSPassword.Get();
	SMSSenderName = Constants.SMSSenderName.Get();
	If Not ValueIsFilled(SMSSenderName) Then
		SMSSenderName = "hotel";
	EndIf;
	SMSGateway = Constants.SMSGateway.Get();
	If Not ValueIsFilled(SMSSenderName) Then 
		SMSGateway = Enums.SupportedSMSGateways.SMSC;
	EndIf;
	Company = Constants.SMSCompany.Get();
EndProcedure // ReadConstants

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure FormRefresh()
	Items.LinkRegistration.Visible = False;
	Items.LinkRates.Visible = False;
	Items.SMSBalanceGroup.Visible = True;
	If SMSGateway = Enums.SupportedSMSGateways.SMSESTERIALV Then
		Items.SMSBalanceGroup.Visible = False;			
	ElsIf SMSGateway = Enums.SupportedSMSGateways.SMSD Then
		Items.SMSSumBalance.Visible = False;
		Items.SMSBalance.Visible = True;
	Else     
		If SMSGateway = Enums.SupportedSMSGateways.SMS1CHOTEL Then
			Items.LinkRates.Visible = True;	
		EndIf;
		If SMSGateway = Enums.SupportedSMSGateways.SMSC Then
			Items.LinkRegistration.Visible = True;	
		EndIf;
		Items.SMSSumBalance.Visible = True;
		Items.SMSBalance.Visible = False;
	EndIf; 	
EndProcedure // FormRefresh
  
// --------------------------------------------------------------------------------------------------
&AtServer
Function CheckBalance(rStatus = "")
	vErrorDescription = "";
	vBalanceResult = SMS.GetBalance(vErrorDescription);
	vBalance = vBalanceResult.Balance;
	rStatus = vBalanceResult.Status;
	If vBalance <> Undefined And IsBlankString(rStatus) Then
		If SMSGateway = Enums.SupportedSMSGateways.SMSD Then
			SMSBalance = vBalance;
		Else
			SMSSumBalance = cmFormatSum(vBalance, Catalogs.Currencies.FindByCode(643));
		EndIf; 
		Return True;
	Else
		If SMSGateway = Enums.SupportedSMSGateways.SMSD Then
			SMSBalance = NStr("en='Error!';ru='Ошибка!';de='Fehler!'");
		Else
			SMSSumBalance = NStr("en='Error!';ru='Ошибка!';de='Fehler!'");
		EndIf;
		tcCommonFunctionOnClientServer.TextMessage(vErrorDescription);
		Return False;
	EndIf;
EndFunction // CheckBalance

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure SetConstants(pSMSLogin = "", pSMSPassword = "", pCompany = "", pSMSSenderName = "", pSMSGateway = "")
	If ValueIsFilled(pSMSLogin) Then
		Constants.SMSLogin.Set(pSMSLogin);
	EndIf;
	If ValueIsFilled(pSMSPassword) Then
		Constants.SMSPassword.Set(pSMSPassword);
	EndIf;
	If ValueIsFilled(pCompany) Then 
		Constants.SMSCompany.Set(pCompany);
	EndIf;
	If ValueIsFilled(pSMSSenderName) Then 
		Constants.SMSSenderName.Set(pSMSSenderName);
	EndIf;
	If ValueIsFilled(pSMSGateway) Then 
		Constants.SMSGateway.Set(pSMSGateway);
	EndIf;
EndProcedure // SetLoginAndPasswordConstants

// --------------------------------------------------------------------------------------------------
&AtServer
Function OKAtServer(pStatus="", pChecked)
	If pStatus = "InvalidCredentials" 
		Or pStatus = "InvalidParameters"
		Or pStatus = "UserBlocked"
		Or pStatus = "LimitOfAttemptsReached"
		Or pStatus = "Error" Then
		Items.BalanceError.Title = SMS.ServerResponseDescription(pStatus).Text;
		Items.BalanceError.Visible = True;
		Return False;
	Else
		If pChecked Then
			Items.BalanceError.Visible = False;
		Else
			Items.BalanceError.Title = NStr("en='Error';ru='Ошибка';de='Fehler'");
			Items.BalanceError.Visible = True;
			Return False;
		EndIf;
		Return True;
	EndIf; 
EndFunction // OKAtServer

// --------------------------------------------------------------------------------------------------
&AtClient
Function CheckFieldsFilling()
	vAllFilled = True;
	If NOT ValueIsFilled(SMSLogin) Then 
		vUM = New UserMessage();
		vUM.SetData(ThisObject);
		vUM.Field = "SMSLogin";
		vUM.Text = NStr("en = 'Enter login'; de = 'Geben Sie login'; ru = 'Укажите логин'");
		vUM.Message();
		vAllFilled = False;
	EndIf;		
	If NOT ValueIsFilled(SMSPassword) Then
		vUM = New UserMessage();
		vUM.SetData(ThisObject);
		vUM.Field = "SMSPassword";
		vUM.Text = NStr("en = 'Enter the password'; de = 'Geben Sie das Passwort ein'; ru = 'Укажите пароль'");
		vUM.Message();
		vAllFilled = False;
	EndIf;
	If NOT ValueIsFilled(Company) Then
		vUM = New UserMessage();
		vUM.SetData(ThisObject);
		vUM.Field = "Company";
		vUM.Text = NStr("en = 'Specify the company on whose behalf the SMS will be paid'; de = 'Geben Sie die Kompanie an, für die SMS bezahlt werden sollen'; ru = 'Укажите фирму от имени которой будут оплачиваться СМС'");
		vUM.Message();
		vAllFilled = False;
	EndIf;
	If NOT ValueIsFilled(SMSSenderName) Then
		vUM = New UserMessage();
		vUM.SetData(ThisObject);
		vUM.Field = "SMSSenderName";
		vUM.Text = NStr("en = 'Enter the sender''s name. Use HOTEL-SMS name or register your name'; de = 'Geben Sie den Namen des Absenders ein. Verwenden Sie HOTEL-SMS oder registrieren Sie Ihren Namen'; ru = 'Укажите имя отправителя. Используйте HOTEL-SMS или зарегистрируйте в личном кабинете свое имя'");
		vUM.Message();
		vAllFilled = false;
	EndIf; 
	If NOT ValueIsFilled(SMSGateway) Then
		vUM = New UserMessage();
		vUM.SetData(ThisObject);
		vUM.Field = "SMSGateway";
		vUM.Text = NStr("en = 'Specify the gateway through which SMS will be paid'; de = 'Geben Sie das Gateway an, über das SMS bezahlt werden'; ru = 'Укажите шлюз через который будут оплачиваться СМС'");
		vUM.Message();
		vAllFilled = False;
	EndIf;
	
	Return vAllFilled;		
EndFunction // CheckFieldsFilling

#EndRegion

