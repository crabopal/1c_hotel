
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	LanguageIsChanged = False;
	CloseApplication = False;
	
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	
	If Not CloseApplication Then
		pCancel = True;
	
		vNotification = New NotifyDescription("OnCloseQueryBoxEnding", ThisObject);
		ShowQueryBox(vNotification, 
					 NStr("en = 'It is forbidden to work with an empty database.
					 |Closing the initial filling form will close the client application.
					 |Close the form?';
					 |de = 'Es ist verboten, mit einer leeren Datenbank zu arbeiten.
					 |Durch Schließen des anfänglichen Ausfüllformulars wird die Client-Anwendung geschlossen.
					 |Formular schließen?';
					 |ru = 'Работать с пустой базой запрещено.
					 |Закрытие формы первоначального заполнения приведет к закрытию клиентского приложения.
					 |Закрыть форму?'", Object.LanguageCode),
				 	 QuestionDialogMode.YesNo, , DialogReturnCode.No);
	EndIf;
				 
EndProcedure // BeforeClose

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure LanguageOnChange(pItem)
	
	If ValueIsFilled(Object.Language) Then
		LanguageIsChanged = True;
		
	    TaxationSystemString = "";
		Object.TaxationSystem = PredefinedValue("Enum.TaxationSystems.EmptyRef");
	    Object.Currency = PredefinedValue("Catalog.Currencies.EmptyRef");
	    Object.Citizenship = PredefinedValue("Catalog.Countries.EmptyRef");
	    Object.VATRate = PredefinedValue("Catalog.VATRates.EmptyRef");
	    
	    vLanguageCode = LanguageCode();
	    
	    Title = NStr("en = 'Initial filling of the database wizard'; 
		             |de = 'Erstbefüllung des Datenbank-Assistenten'; 
		             |ru = 'Мастер первоначального заполнения базы'", vLanguageCode);
	    // Language
	    Items.DecorationLanguage.Title = NStr("en = 'Select the default language:'; 
								              |de = 'Wählen Sie die Standardsprache:'; 
								              |ru = 'Выберите язык по умолчанию:'", vLanguageCode); 
	    Items.Language.Title = NStr("en = 'Default client and customer language'; 
						            |de = 'Sprache standardmäßig für Kunden und Partner'; 
						            |ru = 'Язык по умолчанию для клиентов и контрагентов'", vLanguageCode);
	    Items.ConfirmLanguage.Title = NStr("en = 'Next'; 
								           |de = 'Nächsten'; 
								           |ru = 'Далее'", vLanguageCode);
	    // Company
	    Items.DecorationCompany.Title = NStr("en = 'Enter company parameters:'; 
								             |de = 'Unternehmensinterne Parameter:'; 
								             |ru = 'Введите параметры фирмы:'", vLanguageCode);
	    Items.CompanyDescription.Title = NStr("en = 'Company description'; 
								              |de = 'Beschreibung'; 
								              |ru = 'Наименование'", vLanguageCode);
	    Items.CompanyLegacyDescription.Title = NStr("en = 'Legacy name'; 
										            |de = 'Offizielle Bezeichnung'; 
										            |ru = 'Официальное наименование'", vLanguageCode);
	    Items.TaxationSystem.Title = NStr("en = 'Taxation system'; 
							              |de = 'Steuersystem'; 
							              |ru = 'Система налогообложения'", vLanguageCode);
	    
	    Items.TaxationSystem.ChoiceList.Clear();
	    vDesc = NStr("en = 'Common'; 
		             |de = 'Generell'; 
		             |ru = 'Общая'", vLanguageCode); 
	    Items.TaxationSystem.ChoiceList.Add(vDesc);
		
		vDesc = NStr("en = 'Simplified income'; 
		             |de = 'Vereinfachtes Einkommen'; 
		             |ru = 'Упрощенная (УСН) Доход'", vLanguageCode);
	    Items.TaxationSystem.ChoiceList.Add(vDesc);
		
		vDesc = NStr("en = 'Simplified income minus outcome'; 
		             |de = 'Vereinfachtes Einkommen minus Ausgaben'; 
		             |ru = 'Упрощенная (УСН) Доход минус Расход'", vLanguageCode);
	    Items.TaxationSystem.ChoiceList.Add(vDesc);
		
		vDesc = NStr("en = 'Unified tax on imputed income'; 
		             |de = 'Eine einzige Steuer auf unterstellte Einkommen'; 
		             |ru = 'Единый налог на вмененный доход (ЕНВД)'", vLanguageCode);
	    Items.TaxationSystem.ChoiceList.Add(vDesc);
		
		vDesc = NStr("en = 'Unified agricultural tax'; 
		             |de = 'Eine einzige landwirtschaftliche Steuer'; 
		             |ru = 'Единый сельскохозяйственный налог (ЕСН)'", vLanguageCode);
	    Items.TaxationSystem.ChoiceList.Add(vDesc);
		
		vDesc = NStr("en = 'Patent system of taxation'; 
		             |de = 'Das Patent Besteuerungssystem'; 
		             |ru = 'Патентная система налогообложения'", vLanguageCode);
	    Items.TaxationSystem.ChoiceList.Add(vDesc);
	    Items.VATRate.Title = NStr("en = 'VAT Rate %'; 
						           |de = 'Rate MwSt. %'; 
						           |ru = 'Ставка НДС %'", vLanguageCode);
	    Items.PrevCompany.Title = NStr("en = 'Prev'; 
							           |de = 'Vorherige'; 
							           |ru = 'Назад'", vLanguageCode);
	    Items.ConfirmCompany.Title = NStr("en = 'Next'; 
							              |de = 'Nächsten'; 
							              |ru = 'Далее'", vLanguageCode);
	    // Hotel
	    Items.DecorationHotel.Title = NStr("en = 'Enter hotel parameters:'; 
								           |de = 'Hotelparameter eingeben:'; 
								           |ru = 'Введите параметры отеля:'", vLanguageCode);
	    Items.HotelDescription.Title = NStr("en = 'Hotel description'; 
								            |de = 'Beschreibung'; 
								            |ru = 'Наименование'", vLanguageCode);
	    Items.HotelLegacyDescription.Title = NStr("en = 'Legacy name'; 
									              |de = 'Offizielle Bezeichnung'; 
									              |ru = 'Официальное наименование'", vLanguageCode);
	    Items.Currency.Title = NStr("en = 'Currency'; 
						            |de = 'Währung'; 
						            |ru = 'Валюта'", vLanguageCode);
	    Items.Citizenship.Title = NStr("en = 'Default guest citizenship'; 
							           |de = 'Staatsbürgerschaft lt. Standard-Einstellung'; 
							           |ru = 'Гражданство по умолчанию'", vLanguageCode);
	    Items.DocumentPrefix.Title = NStr("en = 'Prefix'; 
							              |de = 'Präfix'; 
							              |ru = 'Префикс'", vLanguageCode);
	    Items.PrevHotel.Title = NStr("en = 'Prev'; 
						             |de = 'Vorherige'; 
						             |ru = 'Назад'", vLanguageCode);
	    Items.ConfirmHotel.Title = NStr("en = 'Start filling'; 
							            |de = 'Mit dem Befüllen beginnen'; 
							            |ru = 'Начать заполнение'", vLanguageCode);
	    Items.ConfirmHotelExtendedTooltip.Title = NStr("en = 'After filling the database, a restart will be performed!'; 
											           |de = 'After filling the database, a restart will be performed!'; 
											           |ru = 'После заполнения базы будет выполнен перезапуск!'", vLanguageCode);
	    // BG operation progress
	    Items.BackgroundOperationProgress.Title = NStr("en = 'The initial filling of the database is being performed...'; 
											           |de = 'Die Erstbefüllung der Datenbank wird durchgeführt...'; 
											           |ru = 'Выполняется первоначальное заполнение базы...'", vLanguageCode);
	EndIf;

EndProcedure // LanguageOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TaxationSystemOnChange(pItem)

	vLanguageCode = Object.LanguageCode;
	
	If TaxationSystemString = NStr("en = 'Common';
						           |de = 'Generell';
						           |ru = 'Общая'", vLanguageCode) Then
    	Object.TaxationSystem = PredefinedValue("Enum.TaxationSystems.Common");
  	ElsIf TaxationSystemString = NStr("en = 'Simplified income';
						              |de = 'Vereinfachtes Einkommen';
						              |ru = 'Упрощенная (УСН) Доход'", vLanguageCode) Then
    	Object.TaxationSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncome");
  	ElsIf TaxationSystemString = NStr("en = 'Simplified income minus outcome';
						              |de = 'Vereinfachtes Einkommen minus Ausgaben';
						              |ru = 'Упрощенная (УСН) Доход минус Расход'", vLanguageCode) Then
    	Object.TaxationSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncomeMinusOutcome");
  	ElsIf TaxationSystemString = NStr("en = 'Unified tax on imputed income';
						              |de = 'Eine einzige Steuer auf unterstellte Einkommen';
						              |ru = 'Единый налог на вмененный доход (ЕНВД)'", vLanguageCode) Then
    	Object.TaxationSystem = PredefinedValue("Enum.TaxationSystems.UnifiedTaxOnImputedIncome");
  	ElsIf TaxationSystemString = NStr("en = 'Unified agricultural tax';
						              |de = 'Eine einzige landwirtschaftliche Steuer';
						              |ru = 'Единый сельскохозяйственный налог (ЕСН)'", vLanguageCode) Then
    	Object.TaxationSystem = PredefinedValue("Enum.TaxationSystems.UnifiedAgriculturalTax");
  	ElsIf TaxationSystemString = NStr("en = 'Patent system of taxation';
						              |de = 'Das Patent Besteuerungssystem';
						              |ru = 'Патентная система налогообложения'", vLanguageCode) Then
    	Object.TaxationSystem = PredefinedValue("Enum.TaxationSystems.PatentTaxationSystem");
  	EndIf;

EndProcedure // TaxationSystemOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
// 
// Returns:
//  String - Language code
//
&AtServer
Function LanguageCode()

	Object.LanguageCode = Object.Language.Code;
	Return Object.LanguageCode;

EndFunction // LanguageCode

// --------------------------------------------------------------------------------
&AtClient
Procedure ConfirmHotel(pCommand)
	
	If ValueIsFilled(Object.HotelDescription) And ValueIsFilled(Object.HotelLegacyDescription)
	   And ValueIsFilled(Object.Currency) And ValueIsFilled(Object.Citizenship) Then
		RunFirstFilling();
		Items.GroupHotel.Visible = False;
		Items.GroupProgress.Visible = True;
		AttachIdleHandler("Attachable_CheckBackgroundJobs", 1, False);
	Else
		vMessage = NStr("en = 'Fill in all required fields!';
						|de = 'Füllen Sie alle erforderlichen Felder aus!';
						|ru = 'Заполните все обязательные поля!'", Object.LanguageCode);
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
	EndIf;

EndProcedure // ConfirmHotel

// --------------------------------------------------------------------------------
&AtClient
Procedure ConfirmCompany(pCommand)
	
	If ValueIsFilled(Object.CompanyDescription) And ValueIsFilled(Object.CompanyLegacyDescription)
	   And ValueIsFilled(TaxationSystemString) And ValueIsFilled(Object.VATRate) Then
		Items.GroupCompany.Visible = False;
		Items.GroupHotel.Visible = True;
	Else
		vMessage = NStr("en = 'Fill in all required fields!';
						|de = 'Füllen Sie alle erforderlichen Felder aus!';
						|ru = 'Заполните все обязательные поля!'", Object.LanguageCode);
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
	EndIf;
	
EndProcedure // ConfirmCompany

// --------------------------------------------------------------------------------
&AtClient
Procedure ConfirmLanguage(pCommand)
	
	If ValueIsFilled(Object.Language) Then
		If LanguageIsChanged Then
			Object.LanguageCode = Object.Language;
			UpdateCountries(Object.LanguageCode);
			LanguageIsChanged = False;
			ConfirmLanguageAtServer();
		EndIf;
		
		Items.GroupLanguage.Visible = False;
		Items.GroupCompany.Visible = True;
	Else
		vMessage = NStr("en = 'Choose a language!';
						|de = 'Wählen Sie eine Sprache!';
						|ru = 'Выберите язык!'", Object.LanguageCode);
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
	EndIf;
	
EndProcedure // ConfirmLanguage

// --------------------------------------------------------------------------------
&AtClient
Procedure PrevHotel(pCommand)
	
	Items.GroupCompany.Visible = True;
	Items.GroupHotel.Visible = False;
	
EndProcedure // PrevHotel

// --------------------------------------------------------------------------------
&AtClient
Procedure PrevCompany(Command)
	
	Items.GroupCompany.Visible = False;
	Items.GroupLanguage.Visible = True;
	
EndProcedure // PrevCompany

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure OnCloseQueryBoxEnding(pResult, pParameters) Export

	If pResult = DialogReturnCode.Yes Then
		CloseApplication = True;
		Close(New Structure("Close, Restart", True, False));
		Exit();
	Else
		CloseApplication = False;
	EndIf;

EndProcedure // OnCloseQueryBoxEnding
// --------------------------------------------------------------------------------
&AtServer
Procedure ConfirmLanguageAtServer()
	
	vDPObj = FormAttributeToValue("Object");
	vDPObj.pmRunBeforeFormOpen();

EndProcedure //ConfirmLanguageAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure UpdateCountries(pLanguageCode)

	If pLanguageCode = "RU" Then
		Catalogs.Countries.UpdateCountriesList("Ru");
	Else
		Catalogs.Countries.UpdateCountriesList("En");
	Endif;

EndProcedure // UpdateCountries

// --------------------------------------------------------------------------------
&AtServer
Procedure RunFirstFilling()

	vDPObj = FormAttributeToValue("Object");
	SaveDataProcessor(vDPObj);
	
	vOperationName = NStr("en='First filling';
						  |ru='Первоначальное заполнение';
						  |de='Erste Füllung'", Object.LanguageCode);
	
	ListOfMessages.Clear();
	
	vParameters = New Array;
	vParameters.Add("FirstFilling");
	vDPParams = New Structure("Currency, VATRate", Object.Currency, Object.VATRate);
	vParameters.Add(vDPParams);
	
	vBackgroundJob = AsyncCalls.StartBackgroundJob("ProlongedOperations.RunDataProcessor", vParameters);
	CurrentBackgroundJobUUID = vBackgroundJob.UUID;

EndProcedure // RunFirstFilling

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveDataProcessor(pDPObject)

	vDPObj = Catalogs.DataProcessors.CreateItem();
	vDPObj.Processing = "FirstFilling";
	vDPObj.IsSystem = True;
	vDPObj.StaticParameters = cmGetDataProcessorStaticParametersValue(pDPObject);
	vDPObj.Write();
	
EndProcedure // SaveDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_CheckBackgroundJobs()
	
	vBackgroundJob = CheckBackgroundJobStatus(CurrentBackgroundJobUUID);
	BackgroundOperationProgress = vBackgroundJob.Progress; 
	
	For Each vMsg in vBackgroundJob.Messages Do
		If ListOfMessages.FindByValue(vMsg) = Undefined And Not StrStartsWith(vMsg, "i - ") Then
			ListOfMessages.Add(vMsg);
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
		EndIf;
	EndDo;
	
	If vBackgroundJob.Status = "Error" Then 
	    tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: '; 
				                                        |ru = 'Ошибка выполнения фонового задания: '; 
				                                        |de = 'Fehler beim Ausführen des Hintergrundjobs: '")
														+ vBackgroundJob.Error);
	    DetachIdleHandler("Attachable_CheckBackgroundJobs");
  	ElsIf vBackgroundJob.Status = "Canceled" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job - canceled'; 
				                                        |ru = 'Фоновое задание - отменено'; 
				                                        |de = 'Hintergrundjob - abgebrochen'"));
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
  	ElsIf vBackgroundJob.Status = "Completed" Then
	    DetachIdleHandler("Attachable_CheckBackgroundJobs");
	    CloseApplication = True;
		Close(New Structure("Close, Restart", True, True));
		Exit( , True);
  	EndIf;
	
EndProcedure // Attachable_CheckBackgroundJobs

// -----------------------------------------------------------------------------
//
// Parameters:
//  pBackgroundJobId - UUID	 - UUID of running background job
// 
// Returns:
//  Structure - Result of checking
//
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId);
	
EndFunction // CheckBackgroundJobStatus

#EndRegion