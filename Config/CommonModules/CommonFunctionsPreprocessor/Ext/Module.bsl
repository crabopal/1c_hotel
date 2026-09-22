
#Region Public

// -----------------------------------------------------------------------------
//  Runs data processor
//
// Parameters:
//  pDataProcessor	 - CatalogRef.DataProcessors - Data processor catalog item
//  pParameter		 - Strucrure				 - Parameter object
//  pIsInteractive	 - Boolean					 - Is in interactive mode or not
// 
// Returns:
//  Boolean - True if data processor object runs successfully, False if any exception was raised
//
Function cmRunDataProcessor(pDataProcessor, pParameter = Undefined, pIsInteractive = False) Export
	Try
		// Initialize list of data processors to run
		vDPs = cmGetListOfDataProcessorsToRun(pDataProcessor);
		// Run each data processor from the list
		For Each vDPRow In vDPs Do
			// Check user rights to execute data processor
			If Not cmCheckUserRightsToExecuteDataProcessor(vDPRow.DataProcessor) Then
				Raise NStr("en='You do not have rights to run data processor: ';ru='Нет прав на запуск обработки: ';de='Sie haben keine Rechte, die Bearbeitung einzuschalten!'") + cmNStr(vDPRow.DataProcessor.Description) + "!";
			EndIf;
			vDPObj = cmBuildDataProcessorObject(vDPRow.DataProcessor);
			If vDPObj <> Undefined Then
				// Initialize data processor settings
				Try
					// Fill reference to the data processor catalog item
					vDPObj.DataProcessor = vDPRow.DataProcessor;
					If TypeOf(pParameter) = Type("Structure") Then
						// Load data processor catalog item attributes
						vDPObj.pmLoadDataProcessorAttributes(pParameter.InputParameter);
						// Run data processor
						vDPObj.pmRun(pParameter, pIsInteractive);
					Else
						// Load data processor catalog item attributes
						vDPObj.pmLoadDataProcessorAttributes(pParameter);
						// Run data processor
						vDPObj.pmRun(pParameter, pIsInteractive);
					EndIf;
				Except
					vErrorDescription = ErrorDescription();
					#IF ThickClientOrdinaryApplication THEN
						vMessage = StrTemplate(NStr("ru = 'Ошибка вызова метода pmRun обработки %1! Описание ошибки: %2'; 
						                |de = 'Error executing pmRun method of data processor %1! Error description: %2'; 
						                |en = 'Error executing pmRun method of data processor %1! Error description: %2'"), cmNStr(pDataProcessor.Description, SessionParameters.CurrentLanguage), vErrorDescription);
						WriteLogEvent(NStr("en='DataProcessor.Run';ru='Обработка.Выполнить';de='DataProcessor.Run'"), EventLogLevel.Warning, Metadata.Catalogs.DataProcessors, pDataProcessor, vMessage);
						tcCommonFunctionOnClientServer.UserMessage(vMessage);
						// Open data processor form
						If Not cmOpenDataProcessorForm(vDPRow.DataProcessor, pParameter) Then
							If pIsInteractive Then
								Return False;
							Else
								Raise NStr("en='Failed to open data processor object form!';ru='Не удалось открыть форму объекта обработки!';de='Das Formular des Bearbeitungsobjekts konnte nicht geöffnet werden!'");
							EndIf;
						EndIf;
					#ELSE
						Raise vErrorDescription;
					#ENDIF
				EndTry;
			EndIf;
		EndDo;
		Return True;
	Except
		vErrorDescription = ErrorDescription();
		vMessage = StrTemplate(NStr("ru = 'Ошибка выполнения обработки %1! Описание ошибки: %2'; 
		                |de = 'Ошибка выполнения обработки %1! Описание ошибки: %2'; 
		                |en = 'Error executing data processor %1! Error description: %2'"),  cmNStr(pDataProcessor.Description, SessionParameters.CurrentLanguage), vErrorDescription);
		WriteLogEvent(NStr("en='DataProcessor.Run';ru='Обработка.Выполнить';de='DataProcessor.Run'"), EventLogLevel.Warning, Metadata.Catalogs.DataProcessors, pDataProcessor, vMessage);
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		#IF CLIENT THEN
			If pIsInteractive Then
				Return False;
			Else
				Raise vErrorDescription;
			EndIf;
		#ELSE
			Raise vErrorDescription;
		#ENDIF
	EndTry;
EndFunction // cmRunDataProcessor

#IF CLIENT THEN
	
// -----------------------------------------------------------------------------
//  Opens employees working time schedule form
//
Procedure cmOpenEmployeeWorkingTimeSchedule() Export
	vFrm = InformationRegisters.EmployeeWorkingTimeSchedule.GetForm("FillForm");
	If Not vFrm.IsOpen() Then
		vFrm.WindowAppearanceMode = WindowAppearanceModeVariant.Maximized;
	EndIf;
	vFrm.Open();
EndProcedure // cmOpenEmployeeWorkingTimeSchedule
	
#ENDIF

#EndRegion




