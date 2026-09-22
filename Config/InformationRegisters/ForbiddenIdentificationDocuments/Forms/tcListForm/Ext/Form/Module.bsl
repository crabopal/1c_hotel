#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FillListWizardAction(pCommand)
	// Clear messages window
	DoMessage(NStr("en='Fill list of forbidden identity documents wizard...';ru='Начало работы мастера по заполнению списка запрещенных документов удостоверяющих личность...';de='Arbeitsbeginn des Assistenten für die Ausfüllung der Liste nicht zulässiger Personalausweise...'"));
	vParams = New Structure();
	    		
	// Document type
	vIDType = PredefinedValue("Catalog.IdentityDocumentTypes.EmptyRef");
	vIDTypeMessage = NStr("en='1. Please input document type!';ru='1. Пожалуйста введите тип ДУЛ!';de='1. Bitte geben Sie den Typ des Personalausweises ein!'");
	DoMessage(vIDTypeMessage);
	ShowInputValue(New NotifyDescription("DocumentTypeWasChoosen", ThisForm, vParams), vIDType, vIDTypeMessage);
EndProcedure // FillListWizardAction

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ProcessUserInput(pIDType, pIDSeries, pIDNumberFrom, pIDNumberTo, pRemarks)
	vIDs = InformationRegisters.ForbiddenIdentificationDocuments.CreateRecordSet();
	vIDNumber = pIDNumberFrom;
	While vIDNumber <= pIDNumberTo Do
		vIDRec = vIDs.Add();
		vIDRec.IdentityDocumentType = pIDType;
		vIDRec.IdentityDocumentSeries = pIDSeries;
		vIDRec.IdentityDocumentNumber = Format(vIDNumber, "ND=14; NFD=0; NG=");
		vIDRec.Remarks = pRemarks;
		vIDRec.Active = True;		
		// Go to the next number
		vIDNumber = vIDNumber + 1;
	EndDo;
	If vIDs.Count() > 0 Then
		vIDs.Write(False);
	EndIf;
	Items.List.Refresh(); 
EndProcedure // ProcessUserInput

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentTypeWasChoosen(pIDType, pParams) Export
	If pIDType = Undefined Then
		DoMessage(NStr("en='Wizard was closed by user!';ru='Работа мастера прервана пользователем!';de='Die Arbeit des Masters wurde vom Nutzer unterbrochen!'"));
		Return;
	ElsIf Not ValueIsFilled(pIDType) Then
		DoMessage(NStr("en='Document type has to be choosen! Wizard was stopped.'; ru='Тип документа удостоверяющего личность должен быть указан! Мастер остановлен.'; de='Dokumenttyp muss ausgewählt werden! Die Verarbeitung wurde gestoppt.'"));
		Return;
	Else
		DoMessage(NStr("ru = '	Выбран Тип ДУЛ: '; en = '	Identity document type choosen: '") + pIDType);
	EndIf;
	pParams.Insert("IDType", pIDType);
	
	// Document series
	vIDSeries = "";
	vIDSeriesMessage = NStr("en='2. Please input document series!';ru='2. Пожалуйста введите серию ДУЛ!';de='2. Bitte geben Sie die Seriennummer des Personalausweises ein!'");
	DoMessage(vIDSeriesMessage);
	ShowInputString(New NotifyDescription("SeriesWasChoosen", ThisForm, pParams), vIDSeries, vIDSeriesMessage, 14, False);
EndProcedure // DocumentTypeWasChoosen

// -----------------------------------------------------------------------------
&AtClient
Procedure SeriesWasChoosen(pIDSeries, pParams) Export
	If pIDSeries = Undefined Then
		DoMessage(NStr("en='Wizard was closed by user!';ru='Работа мастера прервана пользователем!';de='Die Arbeit des Masters wurde vom Nutzer unterbrochen!'"));
		Return;
	Else
		DoMessage(NStr("ru = '	Введена Серия ДУЛ: '; en = '	Identity document series is: '") + pIDSeries);
	EndIf;
	pParams.Insert("IDSeries", pIDSeries);
		
	// Starting document number
	vIDNumberFrom = 0;
	vIDNumberFromMessage = NStr("en='3. Please input starting document number!';ru='3. Пожалуйста введите первый номер ДУЛ из диапазона запрещенных номеров!';de='3. Bitte geben Sie die erste Nummer des Personalausweises aus dem Bereich verbotener Nummern ein!'");
	DoMessage(vIDNumberFromMessage);
	ShowInputNumber(New NotifyDescription("NumberFromWasChoosen", ThisForm, pParams), vIDNumberFrom, vIDNumberFromMessage, 14, 0);
EndProcedure // SeriesWasChoosen

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberFromWasChoosen(pIDNumberFrom, pParams) Export
	If pIDNumberFrom = Undefined Then
		DoMessage(NStr("en='Wizard was closed by user!';ru='Работа мастера прервана пользователем!';de='Die Arbeit des Masters wurde vom Nutzer unterbrochen!'"));
		Return;
	ElsIf pIDNumberFrom = 0 Then
		DoMessage(NStr("en='Initial ID document number has to be filled! Wizard was stopped.'; ru='Начальный номер диапазона номеров документов удостоверяющих личность должен быть указан! Мастер остановлен.'; de='Die Anfangsnummer des Bereichs der Ausweisdokumente muss angegeben werden! Die Verarbeitung wurde gestoppt.'"));
		Return;
	Else
		DoMessage(NStr("ru = '	Введен первый номер ДУЛ: '; en = '	Identity document number to start is: '") + Format(pIDNumberFrom, "ND=14; NFD=0; NG="));
	EndIf;
	pParams.Insert("IDNumberFrom", pIDNumberFrom);
	
	// Ending document number
	vIDNumberTo = 0;
	vIDNumberToMessage = NStr("en='4. Please input ending document number!';ru='4. Пожалуйста введите последний номер ДУЛ из диапазона запрещенных номеров!';de='4. Bitte geben Sie die letzte Nummer des Personalausweises aus dem Bereich verbotener Nummern ein!'");
	DoMessage(vIDNumberToMessage);
	ShowInputNumber(New NotifyDescription("NumberToWasChoosen", ThisForm, pParams), vIDNumberTo, vIDNumberToMessage, 14, 0);
EndProcedure // NumberFromWasChoosen

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberToWasChoosen(pIDNumberTo, pParams) Export
	If pIDNumberTo = Undefined Then
		DoMessage(NStr("en='Wizard was closed by user!';ru='Работа мастера прервана пользователем!';de='Die Arbeit des Masters wurde vom Nutzer unterbrochen!'"));
		Return;
	ElsIf pIDNumberTo = 0 Then
		DoMessage(NStr("en='The final number of the range of identity document numbers must be specified!'; ru='Конечный номер диапазона номеров документов удостоверяющих личность должен быть указан! Мастер остановлен.'; de='Die Endnummer des Bereichs der Ausweisdokumente muss angegeben werden! Die Verarbeitung wurde gestoppt.'"));
		Return;
	ElsIf pIDNumberTo < pParams.IDNumberFrom Then
		DoMessage(NStr("en='The final number of the range of identity document numbers must be greater then the initial number!'; ru='Конечный номер диапазона номеров документов удостоверяющих личность должен быть больше начального номера! Мастер остановлен.'; de='Die Endnummer des Ausweisdokumentbereichs muss größer sein als die Startnummer! Die Verarbeitung wurde gestoppt.'"));
		Return;
	Else
		DoMessage(NStr("ru = '	Введен последний номер ДУЛ: '; en = '	Last Identity document number is: '") + Format(pIDNumberTo, "ND=14; NFD=0; NG="));
	EndIf;
	pParams.Insert("IDNumberTo", pIDNumberTo);
	
	// Comment
	vRemarks = "";
	vRemarksMessage = NStr("en='5. Please input comments!';ru='5. Пожалуйста укажите комментарий к запрещенным ДУЛ!';de='5. Bitte geben Sie Kommentare zu verbotenen Personalausweisen ab!'");
	DoMessage(vRemarksMessage);
	ShowInputString(New NotifyDescription("RemarksWereChoosen", ThisForm, pParams), vRemarks, vRemarksMessage, 0, True);
EndProcedure // NumberToWasChoosen

// -----------------------------------------------------------------------------
&AtClient
Procedure RemarksWereChoosen(pRemarks, pParams) Export
	If pRemarks = Undefined Then
		DoMessage(NStr("en='Wizard was closed by user!';ru='Работа мастера прервана пользователем!';de='Die Arbeit des Masters wurde vom Nutzer unterbrochen!'"));
		Return;
	ElsIf IsBlankString(pRemarks) Then
		DoMessage(NStr("en='The reason for adding document numbers to the prohibited list must be specified!'; ru='Причина добавления номеров документов в список запрещенных должна быть указана! Мастер остановлен.'; de='Der Grund für das Hinzufügen von Dokumentnummern zur Liste der verbotenen Dokumente muss angegeben sein! Die Verarbeitung wurde gestoppt.'"));
		Return;
	Else
		DoMessage(NStr("ru = '	Введен комментарий: '; en = '	Remarks are: '; de = '	Kommentar eingegeben: '") + pRemarks);
	EndIf;
	pParams.Insert("Remarks", pRemarks);
	
	// Process user input
	DoMessage(NStr("en='Processing...';ru='Добавление ДУЛ в список...';de='Hinzufügen des Personalausweises in die Liste'"));
	ProcessUserInput(pParams.IDType, pParams.IDSeries, pParams.IDNumberFrom, pParams.IDNumberTo, pParams.Remarks);
	
	// Finish
	DoMessage(NStr("en='Wizard has finished!';ru='Мастер закончил выполнение!';de='Verarbeitung erfolgt!'"));
EndProcedure // RemarksWereChoosen

// -----------------------------------------------------------------------------
&AtClient
Procedure DoMessage(pText)
	vUM = New UserMessage();
	vUM.TargetID = ThisForm.UUID;
	vUM.Text = pText;
	vUM.Message();
EndProcedure // DoMessage

#EndRegion
