// --------------------------------------------------------------------------------
&AtClient
Procedure DiscountCardsFileStartChoice(Item, ChoiceData, StandardProcessing)
	vFileDialog = New FileDialog(FileDialogMode.Open);
	vFileDialog.Filter = "(*.csv)|*.csv";
	vFileDialog.Show(New NotifyDescription("CloseFileDialog", ThisForm));
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CloseFileDialog(pAnswer,pParametrs) Export
	If ValueIsFilled(pAnswer) Then
		Object.DiscountCardsFile = pAnswer[0];
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure Run(Command)
#IF NOT WebClient THEN
	ClearMessages();
	vError = False;
	If not ValueIsFilled(Object.DiscountCardsFile) Then
		vUserMessage = New UserMessage;
		vUserMessage.Field = "Object.DiscountCardsFile";
		vUserMessage.Text = "Поле ""Путь к файлу"" не заполнено";
		vUserMessage.Message();
		vError = True;	
	EndIf;	
	If not ValueIsFilled(Object.DiscountType) Then
		vUserMessage = New UserMessage;
		vUserMessage.Field = "Object.DiscountType";
		vUserMessage.Text = "Поле ""Тип скидки"" не заполнено";
		vUserMessage.Message();
		vError = True;	
	EndIf;
	If not ValueIsFilled(Object.ClientType) Then
		vUserMessage = New UserMessage;
		vUserMessage.Field = "Object.ClientType";
		vUserMessage.Text = "Поле ""Тип клиента"" не заполнено";
		vUserMessage.Message();
		vError = True;			
	EndIf;
	If vError Then
		Return; 
	EndIf;
	
	ProgressBar = 0;
	vCSVData = New TextDocument;
	vCSVData.Read(Object.DiscountCardsFile, TextEncoding.UTF8);
	
	vLineNumber = 1;
	AddData = 1;	
	vOneProcent = Int(vCSVData.LineCount()/200);
	While vLineNumber < vCSVData.LineCount() Do
		If AddData = 1 Then
			vNewCSVFile = GetTempFileName(".csv");	
			vCSVNewData = New TextDocument;
		EndIf;
		vLine = vCSVData.GetLine(vLineNumber);
		vCSVNewData.AddLine(vLine);
		vLineData = StrSplit(vLine,";");	
		vLineNumber = vLineNumber + 1;
		AddData = AddData + 1;
		If AddData = vOneProcent Then
			vCSVNewData.Write(vNewCSVFile,TextEncoding.UTF8);	
			AddData = 1;
			BeginPutFile(New NotifyDescription("EndRun", ThisForm), , vNewCSVFile, False, ThisForm.UUID);
		EndIf;
	EndDo;	
	vCSVNewData.Write(vNewCSVFile,TextEncoding.UTF8);	
	BeginPutFile(New NotifyDescription("EndRun", ThisForm), , vNewCSVFile, False, ThisForm.UUID);	
#ENDIF
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure EndRun(pResult, pAddress, pFilePath, pParametrs) Export
	If pResult Then
		FillCards(pAddress);
		ThisForm.RefreshDataRepresentation(Items.ProgressBar);
		ThisForm.RefreshDataRepresentation(Items.New);
		ThisForm.RefreshDataRepresentation(Items.Rewrite);
	EndIf;
	BeginDeletingFiles(New NotifyDescription, pFilePath);
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function FillCards(pAddress)
	vBinarData = GetFromTempStorage(pAddress);	
	vFilePath = GetTempFileName(".csv");
	vBinarData.Write(vFilePath);
	vCSVData = New TextDocument;
	vCSVData.Read(vFilePath,TextEncoding.UTF8);
	vLineNumber = 1;
	vTransactionLine = 1;
	While vLineNumber < vCSVData.LineCount() Do 
		If vTransactionLine = 1 Then
			BeginTransaction();
		EndIf;
		vLine = vCSVData.GetLine(vLineNumber);
		vLineData = StrSplit(vLine,";");	
		CreateCard(vLineData[0],vLineData[2]);
		vLineNumber = vLineNumber + 1;
		vTransactionLine = vTransactionLine + 1;
		If vTransactionLine = 10000 Then
			CommitTransaction();
			vTransactionLine = 1;
		EndIf;
	EndDo;
	ProgressBar = ProgressBar + 1;
	DeleteFiles(vFilePath);
EndFunction

// --------------------------------------------------------------------------------
&AtClient
Procedure EndRunAfterDeletingFiles(pExtraParams) Export
	tcCommonFunctionOnClientServer.TextMessage(NStr("en='Success!'; ru='Успешно!'; de='Erfolgreich!'"));
EndProcedure // EndRunAfterDeletingFiles

// --------------------------------------------------------------------------------
&AtServer
Function CreateCard(vNumber, pRemarks)
	vDiscountCard = Catalogs.DiscountCards.FindByDescription(vNumber);
	If ValueIsFilled(vDiscountCard) Then
		If RefreshData Then 
			If vDiscountCard.DiscountType <> Object.DiscountType or vDiscountCard.ClientType <> Object.ClientType Then
				vDiscountCardObject = vDiscountCard.GetObject();
				vDiscountCardObject.DiscountType = Object.DiscountType; 
				vDiscountCardObject.ClientType = Object.ClientType; 
				vDiscountCardObject.Write(); 
				RewriteCard = RewriteCard + 1;
			EndIf;
		EndIf;
	Else
		vDiscountCardObject = Catalogs.DiscountCards.CreateItem();
		vDiscountCardObject.Description = vNumber;
		vDiscountCardObject.Identifier = vNumber;
		vDiscountCardObject.DiscountType = Object.DiscountType; 
		vDiscountCardObject.ClientType = Object.ClientType; 
		vDiscountCardObject.TurnOffAutomaticDiscounts = True;
		vDiscountCardObject.IsBlocked = false;
		vDiscountCardObject.Remarks = pRemarks; 
		vDiscountCardObject.Write(); 
		NewCard = NewCard + 1;
	EndIf;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
		Obj.pmRun();
		pCancel = True;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveAtServer()
	Obj = FormAttributeToValue("Object");
	Obj.pmSaveDataProcessorAttributes();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure Save(Command)
	SaveAtServer();
EndProcedure
