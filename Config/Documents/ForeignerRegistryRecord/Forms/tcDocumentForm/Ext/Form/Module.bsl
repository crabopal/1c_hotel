
#Region FormEventHandlers

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	If Not ReadOnly Then
		If Not ValueIsFilled(Object.ResidencePermitDocument) And Object.Ref.IsEmpty()  Then
			Object.ResidencePermitDocument = Enums.ConfirmingDocuments.WithoutVisa;
		Else
			If Not ValueIsFilled(Object.ResidencePermitDocument) Then
				If ValueIsFilled(Object.VisaType) Then
					Object.ResidencePermitDocument = Enums.ConfirmingDocuments.Visa;
				ElsIf ValueIsFilled(Object.IdentityDocumentType) And TrimAll(Object.IdentityDocumentType.Code) = "101" Then 	
					Object.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit;
				ElsIf ValueIsFilled(Object.IdentityDocumentType) And TrimAll(Object.IdentityDocumentType.Code) = "101a" Then 	
					Object.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit;
				ElsIf ValueIsFilled(Object.IdentityDocumentType) And TrimAll(Object.IdentityDocumentType.Code) = "19" Then 	
					Object.ResidencePermitDocument = Enums.ConfirmingDocuments.PermResidencePermit;
				ElsIf ValueIsFilled(Object.IdentityDocumentType) And TrimAll(Object.IdentityDocumentType.Code) = "20" Then 	
					Object.ResidencePermitDocument = Enums.ConfirmingDocuments.PermResidencePermit;
				Else
					Object.ResidencePermitDocument = Enums.ConfirmingDocuments.WithoutVisa;
				EndIf;
			EndIf;
		EndIf;
		If TypeOf(Object.CheckPointNumber) <> Type("CatalogRef.CheckPoints") Then
			Object.CheckPointNumber = Catalogs.CheckPoints.EmptyRef();
		EndIf;
	EndIf;	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Fill fan id data
	If ValueIsFilled(Object.Guest) Then
		FillFanIDData();
	Else
		Items.FanID.Enabled = False;
		Items.FanIDNumber.Enabled = False;
	EndIf;
	// Visa entry goals list
	VisaTypeOnChangeAtServer();
	// Show or hide export guest data procedure
	vExportDPRef = GetDataProcessorForExportGuestDataToUFMS();
	If Not ValueIsFilled(vExportDPRef) Then
		Items.FormExportGuestDataToUFMSRu.Visible = False;
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	RefreshPage();
	FillListOfObjectPrintingForms();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	If pWriteParameters.WasModified Then
		WriteToForeignerRegistryRecordChangeHistoryAtServer();
	EndIf;	
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		Notify("ForeignerRegistryRecord.Write", Object.Ref, FormOwner);
	EndIf;
EndProcedure // AfterWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	pWriteParameters.Insert("WasModified", Modified)
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ResidencePermitDocumentOnChange(Item)
	RefreshPage(True);
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Function  GetPrintFormTypeRef(pItem)
	vMessage = NStr("en = 'Failed to get the printed form'; ru = 'Ошибка получения печатной формы'; de = 'Konnte die gedruckte Form zu erhalten'");
	vFnd = SelValueListButton.FindByValue(pItem);
	If vFnd.Presentation = "" Then
		Try
			vObjectPrintingForm = Catalogs.ObjectPrintingForms[pItem];
		Except
			Raise vMessage;
		EndTry;
		If Not vObjectPrintingForm = Undefined And Not vObjectPrintingForm.IsEmpty() Then
			Return vObjectPrintingForm;
		EndIf;
	Else
		Try
			GUID = New UUID(vFnd.Presentation);
			vObjectPrintingForm = Catalogs.ObjectPrintingForms.GetRef(GUID);
		Except
			Raise NStr("en = 'Failed to get the printed form'; ru = 'Ошибка получения печатной формы'; de = 'Konnte die gedruckte Form zu erhalten'");
		EndTry;
		If Not vObjectPrintingForm = Undefined And Not vObjectPrintingForm.IsEmpty() Then
			Return vObjectPrintingForm;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure FanIDOnChange(pItem)
	FanIDOnChangeAtServer();
EndProcedure // FanIDOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FanIDNumberOnChange(pItem)
	FanIDNumberOnChangeAtServer();
EndProcedure // FanIDNumberOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PreviousPlaceOfStayOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vParameters = New Structure("Country, Address, AddressType", tcOnServer.cmGetAttributeByRef(Object.Hotel, "Citizenship"), TrimAll(Object.PreviousPlaceOfStay), "Address");
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Ref, , , New NotifyDescription("PreviousPlaceOfStayEditEnd", ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // PreviousPlaceOfStayOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure PlaceOfBirthOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vParameters = New Structure("Country, Address, AddressType", Object.Citizenship, TrimAll(Object.PlaceOfBirth), "PlaceOfBirth");
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Ref, , , New NotifyDescription("PlaceOfBirthEditEnd", ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // PlaceOfBirthOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure VisaIssuedDateOnChange(pItem)
	If ValueIsFilled(Object.VisaIssuedDate) And Not ValueIsFilled(Object.VisaFromDate) Then
		Object.VisaFromDate = Object.VisaIssuedDate + 24*3600;
	EndIf;
EndProcedure // VisaIssuedDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure VisaDaysOnChange(pItem)
	If Object.VisaDays > 0 Then
		If ValueIsFilled(Object.VisaFromDate) And Not ValueIsFilled(Object.VisaToDate) Then
			Object.VisaToDate = Object.VisaFromDate + (Object.VisaDays - 1)*24*3600;
		EndIf;
	EndIf;
EndProcedure // VisaDaysOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure VisaFromDateOnChange(pItem)
	If Object.VisaDays > 0 Then
		If ValueIsFilled(Object.VisaFromDate) And Not ValueIsFilled(Object.VisaToDate) Then
			Object.VisaToDate = Object.VisaFromDate + (Object.VisaDays - 1)*24*3600;
		EndIf;
	EndIf;
EndProcedure // VisaFromDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure VisaTypeOnChange(pItem)
	VisaTypeOnChangeAtServer();
EndProcedure // VisaTypeOnChange

// ----------------------------------------------------------------------------------
&AtClient
Procedure AddressChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If pSelectedValue <> Undefined Then
		Object[pItem.Name] = pSelectedValue.Address;     
		If pItem.Name = "PreviousPlaceOfStay" Then
			Object.StreetFiasId = pSelectedValue.StreetFiasId;   
		EndIf;
		pSelectedValue = pSelectedValue.Address;	
	EndIf;
EndProcedure

// ----------------------------------------------------------------------------------
&AtClient
Procedure AddressAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	pStandardProcessing = False;
	#If Not WebClient And Not MobileClient Then
		FillAddresDadata(pText, pChoiceData);
		If pChoiceData = Undefined Or TypeOf(pChoiceData) = Type("ValueList") And pChoiceData.Count() = 0 Then
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;	
	#Else
		pStandardProcessing = True;
		pChoiceData = Undefined;
	#EndIf
	Modified = True;
EndProcedure

// ----------------------------------------------------------------------------------
&AtClient
Procedure AddressTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	pStandardProcessing = False;
	#If Not WebClient And Not MobileClient Then
		FillAddresDadata(pText, pChoiceData);
		If pChoiceData = Undefined Or TypeOf(pChoiceData) = Type("ValueList") And pChoiceData.Count() = 0 Then
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;	
	#Else
		pStandardProcessing = True;
		pChoiceData = Undefined;
	#EndIf
	Modified = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure Post(pCommand)
	Write(New Structure("WriteMode", DocumentWriteMode.Posting));
EndProcedure //  Post

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure Print(Command)
	If Object.Ref.IsEmpty() Then
		Write(New Structure("DocumentWriteMode",DocumentWriteMode.Posting));		
	EndIf;	
	vName = Command.Name;
	vPrintFormTypeRef = GetPrintFormTypeRef(vName);
	
	vExternalProcessing = Undefined;
	If ValueIsFilled(vPrintFormTypeRef) Then
		vExternalProcessing = tcOnServer.cmGetAttributeByRef(vPrintFormTypeRef, "ExternalProcessing");
	EndIf;
	If ValueIsFilled(vExternalProcessing) Then
		Try
			OpenExternalProcedureForm(vExternalProcessing, vPrintFormTypeRef, Object.Ref);						
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'")+Chars.LF+ErrorDescription(), MessageStatus.Attention);
			vExternalProcessing = Undefined;                                                                                                                                         
		EndTry;
	Else
		vParams = New Structure("SelForeignerRegistryRecord, ObjectPrintingForm", Object.Ref, vPrintFormTypeRef);
		OpenForm("Document.ForeignerRegistryRecord.Form.tcPrintForm", vParams, ThisObject, New UUID);
	EndIf;
EndProcedure //  Print()

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodOfStayExtension(pCommand)
	If ValueIsFilled(Object.ParentDoc) And TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation") Then
		If BegOfDay(tcOnServer.cmGetAttributeByRef(Object.ParentDoc, "CheckOutDate")) > BegOfDay(Object.CheckOutDate) Then
			// Update current record by switching on "Is checked-out" flag
			Object.IsCheckedOut = True;
			If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
				Return;
			EndIf;
			vNewDocRef = PeriodOfStayExtensionAtServer();
			OpenForm("Document.ForeignerRegistryRecord.ObjectForm", New Structure("Key", vNewDocRef), FormOwner);
			Close();
		Else;
			ShowMessageBox(, NStr("ru='Дата выезда в текущей записи журнала регистрации совпадает или раньше даты планируемого выезда гостя!';de='Datum des aktuellen Eintrags im Registrierbuch entspricht oder liegt vor dem Datum der geplanten Abreise des Gastes!';en='Check-out date in the foreigner registry record is the same or earlier then planned guest check-out date!'"));
		EndIf;
	Else;
		ShowMessageBox(, NStr("ru='Не указано размещение, по которому создана текущая запись в журнал регистрации иностранцев!';de='Die Unterbringung, zu der der aktuelle Eintrag ins Buch für die Registrierung von ausländischen Bürgern gemacht wurde, ist nicht angegeben!';en='Accommodation for the current guest foregner registry record is not specified!'"));
	EndIf;
EndProcedure // PeriodOfStayExtension

// -----------------------------------------------------------------------------
&AtClient
Procedure ExportGuestDataToUFMSRu(pCommand)
	If Object.Ref.IsEmpty() Or Modified Then
		ShowMessageBox(, NStr("ru='Документ должен быть записан!';
		                      |de='Das Dokument muss aufgezeichnet sein!'; 
		                      |en='Please write document first!'"));
		Return;
	EndIf;
	vDPRef = GetDataProcessorForExportGuestDataToUFMS();
	If Not ValueIsFilled(vDPRef) Then
		ShowMessageBox(, NStr("en='Data processor for export is not configured!'; ru='Не настроена обработка экспорта!'; de='Exportverarbeitung nicht konfiguriert!'"));
	ElsIf ValueIsFilled(Object.ParentDoc) Then
		OpenForm("DataProcessor.ExportGuestsToUFMSTerritoryApp.Form.tcDPForm", New Structure("DataProcessor, Accommodation, GenerateOnOpen", vDPRef, Object.ParentDoc, True), , Object.ParentDoc);
	EndIf;
EndProcedure // ExportGuestDataToUFMSRu

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFanIDData()
	// Fan id
	vRcdMgr = InformationRegisters.LimitsAndSpecialConditions.CreateRecordManager();
	vRcdMgr.Owner = Object.Guest;
	vRcdMgr.Characteristic = ChartsOfCharacteristicTypes.LimitsAndSpecialConditionTypes.FindByAttribute("XMLElementName", "fan_id");
	If ValueIsFilled(vRcdMgr.Characteristic) Then
		vRcdMgr.Read();
		If vRcdMgr.Selected() Then
			FanID = TrimAll(vRcdMgr.CharacteristicValue);
		EndIf;
	EndIf;
	// Fan id number
	vRcdMgr = InformationRegisters.LimitsAndSpecialConditions.CreateRecordManager();
	vRcdMgr.Owner = Object.Guest;
	vRcdMgr.Characteristic = ChartsOfCharacteristicTypes.LimitsAndSpecialConditionTypes.FindByAttribute("XMLElementName", "fan_id_number");
	If ValueIsFilled(vRcdMgr.Characteristic) Then
		vRcdMgr.Read();
		If vRcdMgr.Selected() Then
			FanIDNumber = TrimAll(vRcdMgr.CharacteristicValue);
		EndIf;
	EndIf;
EndProcedure // FillFanIDData

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure RefreshPage(pFormEdit = False)
	Items.GroupPermitDocumentPages.ChildItems.GroupVisaPage.ShowTitle = False;
	Items.GroupPermitDocumentPages.ChildItems.GroupTemporaryResidencePage.ShowTitle = False;	
	Items.GroupPermitDocumentPages.ChildItems.GroupPermResidencePermitPage.ShowTitle = False;

	If Object.ResidencePermitDocument = PredefinedValue("Enum.ConfirmingDocuments.Visa") Or Object.ResidencePermitDocument = PredefinedValue("Enum.ConfirmingDocuments.ElectronicVisa") Then
		Items.GroupPermitDocumentPages.ChildItems.GroupTemporaryResidencePage.Visible = False;	
		Items.GroupPermitDocumentPages.ChildItems.GroupPermResidencePermitPage.Visible = False;
		Items.GroupPermitDocumentPages.ChildItems.GroupVisaPage.Visible = True;
		
		If pFormEdit Then
			Object.ForEducationPurposes = False;
		EndIf;
	ElsIf Object.ResidencePermitDocument = PredefinedValue("Enum.ConfirmingDocuments.PermResidencePermit") Then
		Items.GroupPermitDocumentPages.ChildItems.GroupTemporaryResidencePage.Visible = False;	
		Items.GroupPermitDocumentPages.ChildItems.GroupPermResidencePermitPage.Visible = True;
		Items.GroupPermitDocumentPages.ChildItems.GroupVisaPage.Visible = False;
		
		If pFormEdit Then
			Object.VisaType = Undefined;
			Object.VisaEntryGoal = Undefined;
			Object.VisaMultiplicity = Undefined;
			Object.VisaDays = 0;
			Object.ForEducationPurposes = False;
		EndIf;
	ElsIf Object.ResidencePermitDocument = PredefinedValue("Enum.ConfirmingDocuments.TempResidencePermit") Then	
		Items.GroupPermitDocumentPages.ChildItems.GroupTemporaryResidencePage.Visible = True;	
		Items.GroupPermitDocumentPages.ChildItems.GroupPermResidencePermitPage.Visible = False;
		Items.GroupPermitDocumentPages.ChildItems.GroupVisaPage.Visible = False;
		
		If pFormEdit Then
			Object.VisaNumber = "";
			Object.VisaType = Undefined;
			Object.VisaEntryGoal = Undefined;
			Object.VisaMultiplicity = Undefined;
			Object.VisaDays = 0;
		EndIf;
	Else  
		// Without Visa and other
		Items.GroupPermitDocumentPages.ChildItems.GroupTemporaryResidencePage.Visible = False;	
		Items.GroupPermitDocumentPages.ChildItems.GroupPermResidencePermitPage.Visible = False;
		Items.GroupPermitDocumentPages.ChildItems.GroupVisaPage.Visible = False;
		
		If pFormEdit Then
			Object.VisaNumber = "";
			Object.VisaIssuedDate = '00010101';
			Object.VisaFromDate = '00010101';
			Object.VisaToDate = '00010101';
			Object.VisaType = Undefined;
			Object.VisaIdentifier = "";
			Object.VisaIssuedBy = "";
			Object.VisaEntryGoal = Undefined;
			Object.VisaMultiplicity = Undefined;
			Object.VisaDays = 0;
			Object.ForEducationPurposes = False;
		EndIf;
	EndIf;
	If pFormEdit Then
		Modified = True;
	EndIf;
EndProcedure //  RefreshPage()

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillListOfObjectPrintingForms()
	If SelValueListButton.Count()>0 Then
		For Each vInd In SelValueListButton Do
			vButton = Items.Find(vInd.Value);
			If TypeOf(vButton) = Type("FormButton") Then
				Items.Delete(vButton);
			EndIf;	
		EndDo;
	EndIf;	
	vLanguage = Catalogs.Languages.EmptyRef();
		
	vQry = New Query;
	vQry.Text = "SELECT
	|	ObjectPrintingForms.Ref AS Ref,
	|	ObjectPrintingForms.Description AS Description,
	|	ObjectPrintingForms.ExternalProcessing
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	ObjectPrintingForms.ObjectType = &qObjectType
	|	AND ObjectPrintingForms.IsActive
	|	AND NOT ObjectPrintingForms.DeletionMark
	|	AND NOT ObjectPrintingForms.IsFolder
	|	AND CASE
	|			WHEN &pLanguage <> VALUE(Catalog.Languages.EmptyRef)
	|				THEN ObjectPrintingForms.Language = &pLanguage
	|						OR ObjectPrintingForms.Language = VALUE(Catalog.Languages.EmptyRef)
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	ObjectPrintingForms.Code";
	vQry.SetParameter("qObjectType", Documents.ForeignerRegistryRecord.EmptyRef());
	vQry.SetParameter("pLanguage", vLanguage);
	vQryResult = vQry.Execute().Unload();
	For Each vRow in vQryResult Do
		vObjectPrintingForm = vRow.Ref;
		vObjectPrintingFormDescription = cmNStr(vRow.Description); 
		
		// Add command
		vCommandName 	= vObjectPrintingForm.PredefinedDataName; 
		vPredName 		= "";
		If vCommandName = "" Then
			vPredName 	 = String(vObjectPrintingForm.UUID());
			vCommandName = StrReplace(vPredName,"-","");
		EndIf;
		If Commands.Find(vCommandName) = Undefined Then
			vCmd = Commands.Add(vCommandName);
			vCmd.Action = "Print"; 
			vCmd.Title = vObjectPrintingForm.Code+vObjectPrintingFormDescription;
		EndIf;
		// Add button
		vItem = Items.Add(vCommandName, Type("FormButton"),Items.GroupPrint);
		vItem.Type = FormButtonType.UsualButton;
		vItem.CommandName = vCommandName; 	
		SelValueListButton.Add(vCommandName,vPredName);
	EndDo;
EndProcedure // FillListOfObjectPrintingForms

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef, pDocRef)
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage"); 
	vName = ConnectExternalDataProcessor(vURL, "ExternalPrintFolioForm");
	vParams = New Structure("SelForeignerRegistryRecord, ObjectPrintingForm", pDocRef, pPrintFormTypeRef);
	vFrm = GetForm("ExternalDataProcessor." + vName + ".Form", vParams);
	vFrm.Open();
EndProcedure // OpenExternalProcedureForm

// ------------------------------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Procedure FanIDOnChangeAtServer()
	If ValueIsFilled(Object.Guest) Then
		vRcdMgr = InformationRegisters.LimitsAndSpecialConditions.CreateRecordManager();
		vRcdMgr.Characteristic = ChartsOfCharacteristicTypes.LimitsAndSpecialConditionTypes.FindByAttribute("XMLElementName", "fan_id");
		If ValueIsFilled(vRcdMgr.Characteristic) Then
			vRcdMgr.CharacteristicValue = TrimAll(FanID);
			vRcdMgr.Owner = Object.Guest;
			vRcdMgr.Write(True);
		EndIf;
	EndIf;
EndProcedure // FanIDOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FanIDNumberOnChangeAtServer()
	If ValueIsFilled(Object.Guest) Then
		vRcdMgr = InformationRegisters.LimitsAndSpecialConditions.CreateRecordManager();
		vRcdMgr.Characteristic = ChartsOfCharacteristicTypes.LimitsAndSpecialConditionTypes.FindByAttribute("XMLElementName", "fan_id_number");
		If ValueIsFilled(vRcdMgr.Characteristic) Then
			vRcdMgr.CharacteristicValue = TrimAll(FanIDNumber);
			vRcdMgr.Owner = Object.Guest;
			vRcdMgr.Write(True);
		EndIf;
	EndIf;
EndProcedure // FanIDNumberOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function PeriodOfStayExtensionAtServer()
	// Create new foreigner registry record as copy of the current one but with new period of stay
	vNewRecordObj = Object.Ref.Copy();
	vNewRecordObj.pmFillAuthorAndDate();
	vNewRecordObj.CheckInDate = BegOfDay(Object.CheckOutDate);
	vNewRecordObj.CheckOutDate = BegOfDay(Object.ParentDoc.CheckOutDate);
	If BegOfDay(vNewRecordObj.CheckOutDate) > BegOfDay(vNewRecordObj.MigrationCardDateTo) Then
		vNewRecordObj.MigrationCardDateTo = vNewRecordObj.CheckOutDate;
	EndIf;
	vNewRecordObj.Room = Object.ParentDoc.Room;
	vNewRecordObj.Remarks = NStr("en='Period of stay extension';ru='Продление';de='Verlängerung'");
	vNewRecordObj.IsCheckedOut = False;
	vNewRecordObj.Write(DocumentWriteMode.Posting);
	Return vNewRecordObj.Ref;
EndFunction // PeriodOfStayExtensionAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure PreviousPlaceOfStayEditEnd(pResult, pAdditionalParameters) Export
	If Not pResult = Undefined Then
		If TypeOf(pResult) = Type("Structure") Then
			Object.PreviousPlaceOfStay = pResult.Address;	
		Else	
			Object.PreviousPlaceOfStay = pResult;
		EndIf;
	EndIf;
EndProcedure // PreviousPlaceOfStayEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure PlaceOfBirthEditEnd(pResult, pAdditionalParameters) Export
	If Not pResult = Undefined Then
		If TypeOf(pResult) = Type("Structure") Then
			Object.PlaceOfBirth = pResult.Address;	
		Else	
			Object.PlaceOfBirth = pResult;
		EndIf;
	EndIf;
EndProcedure // PlaceOfBirthEditEnd

// -----------------------------------------------------------------------------
&AtServer
Procedure VisaTypeOnChangeAtServer()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	EntryGoals.Ref
	|FROM
	|	Catalog.EntryGoals AS EntryGoals
	|WHERE
	|	NOT EntryGoals.DeletionMark
	|	AND (EntryGoals.VisaType = &qVisaType
	|			OR EntryGoals.VisaType = &qEmptyVisaType)
	|
	|ORDER BY
	|	EntryGoals.Code";
	vQry.SetParameter("qVisaType", Object.VisaType);
	vQry.SetParameter("qEmptyVisaType", Catalogs.VisaTypes.EmptyRef());
	vEntryGoals = vQry.Execute().Unload();
	Items.VisaEntryGoal.ChoiceList.LoadValues(vEntryGoals.UnloadColumn("Ref"));
EndProcedure // VisaTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure WriteToForeignerRegistryRecordChangeHistoryAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmWriteToForeignerRegistryRecordChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
EndProcedure //  WriteToForeignerRegistryRecordChangeHistoryAtServer()

// ----------------------------------------------------------------------------------
&AtClient
Procedure FillAddresDadata(Val pText, pList)
	If StrLen(pText) >= 4 Then
		pList = GetAddressFromDadata(pText);
	EndIf;
EndProcedure

// ----------------------------------------------------------------------------------
&AtServerNoContext
Function GetAddressFromDadata(pText)
	Return cmGetDataFromDadata(TrimAll(pText),,);
EndFunction	 

// -----------------------------------------------------------------------------
&AtServer
Function GetDataProcessorForExportGuestDataToUFMS()
	Return cmGetDataProcessorForExportGuestDataToUFMS(Object.Hotel);
EndFunction // GetDataProcessorForExportGuestDataToUFMS

#EndRegion
