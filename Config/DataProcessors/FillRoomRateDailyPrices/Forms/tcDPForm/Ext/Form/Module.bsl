#Region FormEventHandlers

//-----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj, "Object");
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
		Obj.pmRun();
		pCancel = True;
	EndIf;
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

//-----------------------------------------------------------------------------
&AtClient
Procedure Save(Command)
	SaveAtServer();
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure RunDP(Command)
	ClearMessages();
	Items.GroupExecute.Visible = True;
	Items.GroupError.Visible = False;
	
	// After switching on, you need to perform a full synchronization.
	vParametersDataProcessor = New Structure;
	vParametersDataProcessor.Insert("Hotel", Object.Hotel);
	vParametersDataProcessor.Insert("PeriodFrom", Object.PeriodFrom);
	vParametersDataProcessor.Insert("PeriodTo", Object.PeriodTo);
	vParametersDataProcessor.Insert("RoomRate", Object.RoomRate);
	vParametersDataProcessor.Insert("RoomType", Object.RoomType);
	
	vProcedureParametrs = New Array;
	vTempStorageAdress = PutToTempStorage(Null);
	vProcedureParametrs.Add("FillRoomRateDailyPrices");
	vProcedureParametrs.Add(vParametersDataProcessor);
	
	vBackgroundJob = StartBackgroundJob("ProlongedOperations.RunDataProcessor", vProcedureParametrs, vTempStorageAdress);
	
	BackgroundJobUUID = vBackgroundJob.UUID;
	
	AttachIdleHandler("CheckBackgroundJobs", 1, False);
EndProcedure

#EndRegion

#Region Private

//-----------------------------------------------------------------------------
&AtServer
Procedure SaveAtServer()
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	Obj.pmSaveDataProcessorAttributes();
	ValueToFormAttribute(Obj, "Object");
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure CheckBackgroundJobs()
	vProcessing = True;
	vBackgroundJob 	= CheckBackgroundJobStatus(BackgroundJobUUID);
	vMsg = "";
	vJobName = "FillRoomRateDailyPrices";
	
	If vBackgroundJob <> Undefined Then 
		If  vBackgroundJob.Status = "Error" Then 
			vMsg = NStr("en = 'Error in background job: " + vJobName + "'; ru = 'Ошибка выполнения фонового задания: " + vJobName + "'")
					+ Chars.LF + vBackgroundJob.Error;		 	
					
			vProcessing = False;
			
			Items.GroupExecute.Visible = False;
			Items.GroupError.Visible = True;
			Items.DecorationErrorText.Title = vMsg;
		ElsIf vBackgroundJob.Status = "Canceled" Then 
			vMsg = NStr("en = 'Background job: " + vJobName + " - canceled.'; ru = 'Фоновое задание: " + vJobName + " - отменено.'")
					+ Chars.LF + vBackgroundJob.Error;		    
			vProcessing = False;	
			Items.GroupExecute.Visible = False;
			Items.GroupError.Visible = True;
			Items.DecorationErrorText.Title = vMsg;
		ElsIf vBackgroundJob.Status = "Completed" Then 
			vProcessing = False;
			
			Items.GroupExecute.Visible = False;
			Items.GroupError.Visible = False;
			
			vMsg = Nstr("en = 'Filling prices completed'; de = 'Füllpreise abgeschlossen'; ru = 'Заполнение цен выполнено'");
			
			Message = New UserMessage;
			Message.Text = Nstr("en = 'Done'; de = 'Erledigt'; ru = 'Готово'");
			Message.TargetID = UUID;
			Message.Message();
			
			ShowUserNotification(Nstr("en = 'Done'; de = 'Erledigt'; ru = 'Готово'"), , vMsg, PictureLib.CheckMark, UserNotificationStatus.Important, UUID);
		EndIf;
	Else
		vMsg = NStr("en = 'Error in checking background job: " + vJobName + "'; ru = 'Ошибка проверки фонового задания: " + vJobName + "'");		
		Items.GroupExecute.Visible = False;
		Items.GroupError.Visible = True;
	EndIf;
	
	If Not vProcessing Then
		BackgroundJobUUID = Undefined;
		DetachIdleHandler("CheckBackgroundJobs");
	EndIf;
EndProcedure	

// -------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction

// -------------------------------------------------------------------------
&AtServer                               
Function StartBackgroundJob(pProcedureName, pProcedureParametrs, pTempStorageAddress = Undefined)
	Return AsyncCalls.StartBackgroundJob(pProcedureName, pProcedureParametrs, , , pTempStorageAddress);	
EndFunction

#EndRegion
