
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If MessagesList.Count() > 0 Then
		vError = Print();
		If Not vError = "" Then
			ShowMessageBox( ,vError);
			Close();
		EndIf;
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	ThisObject.Height = 297;
	ThisObject.Width = 210;
	cmSetSpreadsheetProtection(Items.FolioSpreadsheet);
	If Parameters.Property("InputParameter") Then
		If TypeOf(Parameters.InputParameter) = Type("ValueList") Then
			MessagesList.LoadValues(Parameters.InputParameter.UnloadValues());
		Else
			MessagesList.Add(Parameters.InputParameter);
		EndIf;
	EndIf;
	If Parameters.Property("ObjectPrintingForm") Then
		SelLanguage = Parameters.ObjectPrintingForm.Language;
		If Not ValueIsFilled(SelLanguage) Then
			SelLanguage = SessionParameters.CurrentLanguage;
		EndIf;
		SelObjectPrintForm = Parameters.ObjectPrintingForm;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButton(pCommand)
	MessageSpreadsheet.Print();
	Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	MessageSpreadsheet.Print(PrintDialogUseMode.Use);
	Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	If MessagesList.Count() > 0 Then
		vFilePath = StrReplace(StrReplace(NStr("en = 'Tasks from '; de = 'Aufgaben von '; ru = 'Задачи от '") + GetCurrentDate(), " ", "_"), ":", "");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, MessageSpreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
// 
// Returns:
//  Date - Current session date 
//
&AtServer
Function GetCurrentDate()
	Return CurrentSessionDate();
EndFunction // GetCurrentDate

// -----------------------------------------------------------------------------
&AtClient
Procedure SendByEMail(pCommand)
	vParams = GenerateParametersByEMail();
	OpenForm("CommonForm.tcSendMail", vParams, ThisObject, UUID);
EndProcedure // SendByEMail

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Message if error occured, else blank string
//
&AtServer
Function Print()
	// Basic checks
	rMessage = "";
	vHotel = SessionParameters.CurrentHotel;
	If Not ValueIsFilled(vHotel) Then
		rMessage = NStr("ru='Не задана текущая гостиница!';de='Das aktuelle Hotel ist nicht angegeben!';en='Default hotel should be selected!'");
	EndIf;
	
	SelLanguage = SelObjectPrintForm.Language;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	If ValueIsFilled(MessagesList) Then
		vTemplate = Documents.Message.GetTemplate("MessageTemplate");
		Documents.Message.PrintMessage(MessagesList, SelLanguage, SelObjectPrintForm, MessageSpreadsheet, vTemplate);	
	Else
		rMessage = NStr("en='No activity, task, or message selected!';ru='Не выбрано действие, задача или сообщение!';de='Keine Aktivität, Aufgabe oder Nachricht ausgewählt!'");
	EndIf;
	
	Return rMessage;
EndFunction // Print 

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	If MessagesList.Count() > 0 Then
		vError = Print();
		If Not vError = "" Then
			ShowMessageBox( ,vError);
			Close();
		EndIf;
	EndIf;
EndProcedure // OnReopen

// -----------------------------------------------------------------------------
// 
// Returns:
//  Structure - Email parameters
//
&AtServer
Function GenerateParametersByEMail()
	// Save current spreadsheet as PDF
	vMessagePres = tcOnServer.cmNStrAtServer("en='Tasks from " + CurrentSessionDate() + "'; 
			                           		 |de='Aufgaben von " + CurrentSessionDate() + "'; 
                                      		 |ru='Задачи от " + CurrentSessionDate() + "'", 
                                       		 SelLanguage);
	vFileName = StrReplace(vMessagePres, " ", "_");
	vFilePath = cmGetFullFileName(vFileName, TempFilesDir()) + ".pdf";
	vFileType = SpreadsheetDocumentFileType.PDF;
	MessageSpreadsheet.Write(vFilePath, vFileType);
	// Initialize message texts
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(vHotel) Then
		vHotelName = vHotel.PrintName;
	EndIf;
	MessageText = "";
	vMesageTextRow = "";
	vIsHTML = False;
	vTemplate = Undefined;
	If MessagesList.Count() = 1 Then
		vMessageNumber = MessagesList[0].Value.Number;
		vMesageTextRow = tcOnServer.cmNStrAtServer("en='Task N" + vMessageNumber + "'; 
					                           	   |de='Aufgabe N" + vMessageNumber + "'; 
	                                           	   |ru='Задача №" + vMessageNumber + "'", 
	                                           	   SelLanguage);
		MessageSubject = vHotelName + ". " + vMesageTextRow;
	ElsIf MessagesList.Count() > 0 Then
		vMessageNumbers = "";
		vInd = 0;
		For Each vItem In MessagesList Do
			vMsg = vItem.Value;
			vMessageNumbers = vMessageNumbers + ?(vInd > 0, ", ", " ") + vMsg.Number;
			vInd = vInd + 1;
		EndDo;
		vMesageTextRow = tcOnServer.cmNStrAtServer("en='Tasks N:" + vMessageNumbers + "'; 
					                           	   |de='Aufgaben N:" + vMessageNumbers + "'; 
	                                           	   |ru='Задачи №:" + vMessageNumbers + "'", 
	                                           	   	SelLanguage);
		MessageSubject = vHotelName + ". " + vMessagePres;
	Else
		Return New Structure();
	EndIf;
				
	MessageText = vMesageTextRow + Chars.LF + Chars.LF 
				  + tcOnServer.cmNStrAtServer("en='Best regards,'; 
			      |de='Best regards,'; 
		 	      |ru='С уважением,'", SelLanguage) + Chars.LF
				  + ?(ValueIsFilled(vHotel), Catalogs.Hotels.pmGetHotelPrintName(vHotel, SelLanguage), "") + Chars.LF
				  + tcOnServer.cmNStrAtServer(SessionParameters.ConfigurationName, SelLanguage);
	// Call user exit procedure to give possibility to override message subject and message text
	vUserExitProc = Catalogs.ExternalDataProcessors.SendFolioByEMail;
	If ValueIsFilled(vUserExitProc) Then
		If vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			If Not IsBlankString(vUserExitProc.Algorithm) Then
				SetSafeMode(True);
				Execute(TrimAll(vUserExitProc.Algorithm));
				SetSafeMode(False);
			EndIf;
		EndIf;
	EndIf;
	
	vParams = New Structure();
	vParams.Insert("SelMessageSubject", MessageSubject);
	vParams.Insert("SelMessageText", MessageText);
	vParams.Insert("SelEMails", "");
	vParams.Insert("SelToList", EMailList);
	vFile = New Structure();
	vFile.Insert("FileName", cmGetValidFileName(vFileName) + ".pdf");
	vFile.Insert("FullFileNameAtClient", "");
	vFile.Insert("FullFileNameAtServer", vFilePath);
	vFile.Insert("CheckRemoveAtClient",  False);
	vFile.Insert("CheckRemoveAtServer", True);
	vParams.Insert("SelFile", vFile);
	vParams.Insert("SelLanguage", SelLanguage);
	vParams.Insert("SelSenderName", "");
	vParams.Insert("SelHotel", vHotel);
	vParams.Insert("SelSMSTemplates", vTemplate);
	
	Return vParams;
EndFunction // GenerateParametersByEMail

#EndRegion
