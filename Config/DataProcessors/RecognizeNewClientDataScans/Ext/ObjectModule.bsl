// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Process finished resource reservations
	pmRecognize(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmRecognize(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.RecognizeNewClientDataScans';ru='Обработка.РаспознаваниеНовыхСкановДанныхКлиентов';de='DataProcessor.RecognizeNewClientDataScans'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Check parameters
	WriteLogEvent(NStr("en='DataProcessor.RecognizeNewClientDataScans';ru='Обработка.РаспознаваниеНовыхСкановДанныхКлиентов';de='DataProcessor.RecognizeNewClientDataScans'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + TrimAll(Hotel));
	// Get driver data processor object
	vDriverObj = cmGetImagesScannerDriverDataProcessor();
	vScI = Undefined;
	rMessage = "";
	vScObj = vDriverObj.pmConnect(rMessage, vScI);
	If vScObj = Undefined Then
		Raise rMessage;
	EndIf;
	// Get list of new documents
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientDataScans.Ref AS Ref
	|FROM
	|	Document.ClientDataScans AS ClientDataScans
	|WHERE
	|	ClientDataScans.Posted
	|	AND ClientDataScans.Status = &qIsNew
	|	AND (ClientDataScans.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|
	|ORDER BY
	|	ClientDataScans.PointInTime";
	vQry.SetParameter("qIsNew", Enums.ScanStatuses.IsNew);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vDocs = vQry.Execute().Unload();
	// Do recognition for each document found
	For Each vDocsRow In vDocs Do
		Try
			rMessage = "";
			// Get document object
			vDocObj = vDocsRow.Ref.GetObject();
			vDocObj.Status = Enums.ScanStatuses.IsRecognized;
			If Not vDriverObj.pmRecognizeDocument(vDocObj, rMessage, vScObj, vScI) Then
				Raise rMessage;
			EndIf;
			vDocObj.Write(DocumentWriteMode.Posting);
			
			// Log current state
			vMessage = NStr("ru = 'Обработан документ: " + String(vDocObj.Ref) + " - группа № " + TrimAll(vDocObj.GuestGroup) + "'; 
			                |de = 'Document " + String(vDocObj.Ref) + " - group N " + TrimAll(vDocObj.GuestGroup) + " was processed'; 
			                |en = 'Document " + String(vDocObj.Ref) + " - group N " + TrimAll(vDocObj.GuestGroup) + " was processed'");
			WriteLogEvent(NStr("en='DataProcessor.RecognizeNewClientDataScans';ru='Обработка.РаспознаваниеНовыхСкановДанныхКлиентов';de='DataProcessor.RecognizeNewClientDataScans'"), EventLogLevel.Information, ThisObject.Metadata(), vDocObj.Ref, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
			Endif;
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.RecognizeNewClientDataScans';ru='Обработка.РаспознаваниеНовыхСкановДанныхКлиентов';de='DataProcessor.RecognizeNewClientDataScans'"), EventLogLevel.Warning, ThisObject.Metadata(), ?(vDocObj = Undefined, Undefined, vDocObj.Ref), vMessage);
			Try
				If vDriverObj <> Undefined And vScObj <> Undefined Then
					vDriverObj.pmDisconnect(vScObj, vScI);
				EndIf;
			Except
			EndTry;
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				Return;
			EndIf;
		EndTry;
	EndDo;
	If vDriverObj <> Undefined And vScObj <> Undefined Then
		vDriverObj.pmDisconnect(vScObj, vScI);
	EndIf;
	WriteLogEvent(NStr("en='DataProcessor.RecognizeNewClientDataScans';ru='Обработка.РаспознаваниеНовыхСкановДанныхКлиентов';de='DataProcessor.RecognizeNewClientDataScans'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmRecognizeNewClientDataScans
