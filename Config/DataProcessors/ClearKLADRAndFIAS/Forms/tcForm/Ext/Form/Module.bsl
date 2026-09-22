
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	FillFIAS_KLADR_Elements();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FIAS_KLADR_ElementsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.FIAS_KLADR_Elements.CurrentData;
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.Name) Then
			OpenForm("Catalog." + vCurData.Name + ".ListForm");	
		EndIf;
	EndIf;
EndProcedure // FIAS_KLADR_ElementsSelection

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Refresh(pCommand)
	FillFIAS_KLADR_Elements();
EndProcedure // Refresh

// -----------------------------------------------------------------------------
&AtClient
Procedure Clear(pCommand)
	Items.DecorationDescriptionBackgroundJobs.Title = NStr("en = 'Database cleanup in progress'; de = 'Datenbankbereinigung läuft'; ru = 'Выполняется очистка базы данных'");
	StartProlongedOperation("ProlongedOperations.ClearKLADRAndFIAS", Nstr("en = 'CLADR cleaning'; de = 'Reinigung von KLADR'; ru = 'Очистка адресного классификатора'"));
EndProcedure // Clear

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFIAS_KLADR_Elements()
	FIAS_KLADR_Elements.Clear();
	FillElementsByMetadata(Metadata.Catalogs.Regions);
	FillElementsByMetadata(Metadata.Catalogs.Areas);
	FillElementsByMetadata(Metadata.Catalogs.Cities);
	FillElementsByMetadata(Metadata.Catalogs.Streets);
EndProcedure // FillFIAS_KLADR_Elements

// -----------------------------------------------------------------------------
&AtServer
Procedure FillElementsByMetadata(pMetadata)
	vNewRow = FIAS_KLADR_Elements.Add();
	vNewRow.Catalogs = pMetadata.Synonym; 
	vNewRow.Count = GetCountElementsByCatalogName(pMetadata.Name);
	vNewRow.Name = pMetadata.Name;	
EndProcedure // FillElementsByMetadata

// -----------------------------------------------------------------------------
&AtServer
Function GetCountElementsByCatalogName(pCatalogName)
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	COUNT(" + pCatalogName + ".Ref) AS Count
	|FROM
	|	Catalog." + pCatalogName + " AS " + pCatalogName;
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		Return vResult[0].Count;	
	Else
		Return 0;
	EndIf;
EndFunction // GetCountElementsByCatalog  

// -----------------------------------------------------------------------------
&AtClient
Procedure StartProlongedOperation(pFunctionName, pOperationName, pOperationParametrs = Undefined)	
	BlockForm_ShowProgressBar();
	vBackgroundJob = StartBackgroundJob(pOperationName, pFunctionName, pOperationParametrs);
	CurrentBackgroundJobUUID = vBackgroundJob.UUID;
	AttachIdleHandler("Attachable_CheckBackgroundJobs", 1, True);
EndProcedure // StartProlongedOperation

// -----------------------------------------------------------------------------
&AtServer                               
Function StartBackgroundJob(pOperationName, pProcedureName, pProcedureParametrs = Undefined, pTempStorageAddress = Undefined)
	ListOfMessages = new ValueList;
	Return AsyncCalls.StartBackgroundJobWithRecordInRegister(Undefined, pOperationName, pProcedureName, pProcedureParametrs,,,pTempStorageAddress);	
EndFunction // StartBackgroundJob

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId, pDeleteReadedMessages)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId, pDeleteReadedMessages); 
EndFunction // CheckBackgroundJobStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_CheckBackgroundJobs()
	vBackgroundJob = CheckBackgroundJobStatus(CurrentBackgroundJobUUID, True);             
	
	vCount = vBackgroundJob.Messages.Count();	
	If vCount > 0 Then
		Items.DecorationDescriptionBackgroundJobs.Title = NStr("en = 'Background operation in progress, you can continue to work in other forms'; ru = 'Выполняется фоновая операция, можете продолжать работать в других формах'; de = 'Die Hintergrundoperation läuft, Sie können weiterhin in anderen Formen arbeiten'") + Chars.LF + vBackgroundJob.Messages[vCount - 1];
		Items.DecorationDescriptionBackgroundJobs.TextColor = WebColors.Red;
	EndIf;
	
	If vBackgroundJob.Status = "Error" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: '; ru = 'Ошибка выполнения фонового задания: '; de = 'Fehler beim Ausführen des Hintergrundjobs: '") + vBackgroundJob.Error);
		BlockForm_ShowProgressBar(True);
	ElsIf vBackgroundJob.Status = "Canceled" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job - canceled.'; ru = 'Фоновое задание - отменено.'; de = 'Hintergrundjob - abgebrochen.'"));
		BlockForm_ShowProgressBar(True);
	ElsIf vBackgroundJob.Status = "Completed" Then
		BlockForm_ShowProgressBar(True);
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Completed'; ru = 'Завершено'; de = 'Abgeschlossen'"));
		FillFIAS_KLADR_Elements();
	Else
		AttachIdleHandler("Attachable_CheckBackgroundJobs", 10, True);
	EndIf;
EndProcedure // Attachable_CheckBackgroundJobs

// -----------------------------------------------------------------------------
&AtClient
Procedure BlockForm_ShowProgressBar(pStop = False)
	ReadOnly = Not pStop;
	Items.Group_Page_LoadingScheduledJobs.Visible = Not pStop;
	Items.Group_Page_ExternalBonusesTransactions.Visible = pStop;
EndProcedure // BlockForm_ShowProgressBar

#EndRegion
