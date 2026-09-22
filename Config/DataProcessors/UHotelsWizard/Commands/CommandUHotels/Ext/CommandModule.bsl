
#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	vDatProc = ReturnDataProcessor();
	If TypeOf(vDatProc) = Type("ValueList") Then
		vNotifyDescription = New NotifyDescription("AfterMarkingTheElements", ThisObject);	
		vDatProc.ShowChooseItem(vNotifyDescription,NStr("en='Select processing'; ru='Выберите обработку'; de='Wählen Sie Bearbeitung'"));
	ElsIf TypeOf(vDatProc) = Type("CatalogRef.DataProcessors") Then
		FormParameters = New Structure("DataProcessor", vDatProc);
	    OpenForm("DataProcessor.UHotelsWizard.Form.tcWizardForm", FormParameters, vDatProc);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='The wizard has to be registered in the data processors catalog!'; ru='Создайте обработку в справочнике ""Обработки""!'; de='Der Assistent muss im Katalog der Datenprozessoren registriert sein!'"));
		Return;
	EndIf;
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterMarkingTheElements(pSelectedElement, pParameters) Export 
	If pSelectedElement = Undefined Then
		Return;
	Else
		vDatProc = pSelectedElement.Value;
		vFormParameters = New Structure("DataProcessor", vDatProc);
	    OpenForm("DataProcessor.UHotelsWizard.Form.tcWizardForm", vFormParameters, vDatProc);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function ReturnDataProcessor()
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	DataProcessors.Ref
		|FROM
		|	Catalog.DataProcessors AS DataProcessors
		|WHERE
		|	(CAST(DataProcessors.Processing AS STRING(15))) = ""UHotelsWizard""
		|	AND NOT DataProcessors.DeletionMark";
	vQueryResult = vQuery.Execute().Unload();
	If vQueryResult.Count() = 1 Then
		Return vQueryResult[0].Ref;
	ElsIf vQueryResult.Count() > 1 Then
		aR = vQueryResult.UnloadColumn("Ref");
		vL = New ValueList;
		vL.LoadValues(aR);
		Return vL;
	Else
		Return Undefined;
	EndIf;
EndFunction

#EndRegion
