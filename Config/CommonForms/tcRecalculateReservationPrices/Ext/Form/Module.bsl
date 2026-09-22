
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Hotel") Then
		Hotel = Parameters.Hotel;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DoProcessing(pCommand)
	If ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) Then
		If DateTo < DateFrom Then
			ShowMessageBox(, NStr("en='Period is wrong!'; ru='Период указан не верно!'; de='Der Zeitraum stimmt nicht!'"));
			Return;
		EndIf;
	EndIf;
	
	vOperationName = NStr("en='Services recalculation'; ru='Пересчет услуг'; de='Neuberechnung der Services'");
	
	ListOfMessages.Clear();
	
	vParameters = New Array;
	vParameters.Add(Hotel);
	vParameters.Add(Customer);
	vParameters.Add(Contract);
	vParameters.Add(RoomRate);
	vParameters.Add(Service);
	vParameters.Add(WhatToProcess);
	vParameters.Add(RefreshPriceCalculationDate);
	vParameters.Add(RefreshChargingRules);
	vParameters.Add(tcOnServer.cmGetCurrentUserAttribute());
	vParameters.Add(DateFrom);
	vParameters.Add(DateTo);
	vParameters.Add(ReservationStatus);
	vParameters.Add(Author);
	
	vBackgroundJob = AsyncCalls.StartBackgroundJobWithRecordInRegister(Hotel, vOperationName, "ProlongedOperations.ReservationsList_RecalculateServices", vParameters);
	CurrentBackgroundJobUUID = vBackgroundJob.UUID;
	
	AttachIdleHandler("Attachable_CheckBackgroundJobs", 1, False);
	
	BlockForm_ShowProgressBar(vOperationName);
EndProcedure // DoProcessing

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_CheckBackgroundJobs()
	vBackgroundJob = CheckBackgroundJobStatus(CurrentBackgroundJobUUID);
	BackgroundOperationProgress = vBackgroundJob.Progress; 
	
	For Each vMsg in vBackgroundJob.Messages Do
		If ListOfMessages.FindByValue(vMsg) = Undefined Then
			ListOfMessages.Add(vMsg);
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
		EndIf;
	EndDo;
	
	If vBackgroundJob.Status = "Error" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: '; ru = 'Ошибка выполнения фонового задания: '; de = 'Fehler beim Ausführen des Hintergrundjobs: '") + vBackgroundJob.Error);
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Canceled" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job - canceled'; ru = 'Фоновое задание - отменено'; de = 'Hintergrundjob - abgebrochen'"));
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Completed" Then
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_Completed();
	EndIf;
EndProcedure // Attachable_CheckBackgroundJobs

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction // CheckBackgroundJobStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure BlockForm_ShowProgressBar(pOperationName)
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Title	= NStr("en = 'Background operation in progress, you can continue to work in other forms  - '; ru = 'Выполняется фоновая операция, можете продолжать работать в других формах  - '; de = 'Die Hintergrundoperation läuft, Sie können weiterhin in anderen Formen arbeiten - '") + pOperationName;
	Items.BackgroundOperationProgress.Visible = True;
	Items.FormDoProcessing.Enabled = False;
	Items.GroupFilters.Enabled = False;
	Items.GroupOptions.Enabled = False;
EndProcedure // BlockForm_ShowProgressBar

// -----------------------------------------------------------------------------
&AtClient
Procedure UnlockForm_HideProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = False;
	Items.FormDoProcessing.Enabled = True;
	Items.GroupFilters.Enabled = True;
	Items.GroupOptions.Enabled = True;
EndProcedure // UnlockForm_HideProgressBar

// -----------------------------------------------------------------------------
&AtClient
Procedure UnlockForm_Completed()
	Items.BackgroundOperationProgress.Title	= NStr("en = 'Job completed!'; ru = 'Задача выполнена!'; de = 'Die Aufgabe abgeschlossen!'");
	Items.FormDoProcessing.Enabled = True;
	Items.GroupFilters.Enabled = True;
	Items.GroupOptions.Enabled = True;
EndProcedure // UnlockForm_HideProgressBar

#EndRegion
