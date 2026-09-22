
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	DocumentsList.Clear();
	NumberOfSelectedDocs = 0;
	NumberOfSelectedVauchers = 0;
	If Parameters.Property("DocumentsList") Then
		If TypeOf(Parameters.DocumentsList) = Type("ValueList") Then 
			For Each vPDocListItem In Parameters.DocumentsList Do
				vDoc = vPDocListItem.Value;
				If ValueIsFilled(vDoc) Then
					vCheck = vPDocListItem.Check;
					vDocPresentation = String(vDoc);
					If ValueIsFilled(vDoc.HotelProduct) Then
						vDocPresentation = TrimAll(vDoc.HotelProduct) + " - " + vDocPresentation;
						vCheck = False;
					EndIf;
					DocumentsList.Add(vPDocListItem.Value, vDocPresentation, vCheck);
					If vCheck Then
						NumberOfSelectedDocs = NumberOfSelectedDocs + 1;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If Parameters.Property("GuestGroup") Then
		GuestGroup = Parameters.GuestGroup;
	EndIf;
	If DocumentsList.Count() = 0 Then
		TMessage = NStr("en='Documents list is empty!'; ru='Список документов пуст!'; de='Dokumentenliste ist leer!'");
	Else
		TMessage = NStr("en='Select vaucher numbers range to fill...'; ru='Укажите диапазон номеров бланков путевок...'; de='Zu füllenden Gutscheinnummernbereich auswählen...'");
	EndIf;
	
	// Load printing commands
	FillPrintingButton();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure NumberFromOnChange(pItem)
	NumbersOnChangeAtServer();
EndProcedure // NumberFromOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure NumberToOnChange(pItem)
	NumbersOnChangeAtServer();
EndProcedure // NumberToOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure VaucherTypeOnChange(pItem)
	NumbersOnChangeAtServer();
EndProcedure // VaucherTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure DocumentsListOnChange(pItem)
	NumberOfSelectedDocs = 0;
	For Each vItem In DocumentsList Do
		If vItem.Check Then
			NumberOfSelectedDocs = NumberOfSelectedDocs + 1;
		EndIf;
	EndDo;
EndProcedure // DocumentsListOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure NumberOfSelectedVauchersOnChange(pItem)
	NumberOfSelectedVauchersOnChangeAtServer();
EndProcedure // NumberOfSelectedVauchersOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DocumentsListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If pField.Name = "DocumentsListValue" And pSelectedRow <> Undefined Then
		ShowValue(, DocumentsList.FindByID(pSelectedRow).Value);
	EndIf;
EndProcedure // DocumentsListSelection

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DoFillVauchers(pCommand)
	If IsBlankString(TMessage) Then
		i = 0; j = 0;
		AttachIdleHandler("ProcessDocumentsListItem", 0.1, True);
	EndIf;
EndProcedure // DoFillVauchers

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(Command)
	vPrintNumber = StrReplace(Command.Name, "Print", "");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	
	// Load external print form
	If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
		Try
			OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
		EndTry;
	ElsIf ValueIsFilled(vPrintForm.Report) Then
		Try
			OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
		EndTry;
	ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintHotelProduct" Then
		PrintHotelProduct(vPrintForm.Language, vPrintForm.Ref);
	ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestGroupHotelProducts" Then
		If ValueIsFilled(GuestGroup) Then
			PrintHotelProduct(vPrintForm.Language, vPrintForm.Ref);
		Else
			ShowMessageBox(, NStr("en='Group is not selected! Please open this form from the group item.'; ru='Не выбрана группа! Откройте эту форму из карточки группы.'; de='Keine Gruppe ausgewählt! Öffnen Sie dieses Formular von einer Gruppenkarte aus.'"));
		EndIf;
	EndIf;
EndProcedure // PrintButtonClick

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServerNoContext
Function FillVaucherAtServer(pNumberStr, pItemValue, pItemPresentation, pVaucherType)
	vItemPresentation = pItemPresentation;
	
	vNumberStr = Catalogs.HotelProducts.SetVaucherNumberPresentation(pNumberStr, pVaucherType);
	
	vDoc = pItemValue;
	vVaucherRef = GetVaucher(vNumberStr, pVaucherType, vDoc);
	If ValueIsFilled(vVaucherRef) Then
		vDocObj = vDoc.GetObject();
		vDocObj.HotelProduct = vVaucherRef;
		vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
		vDocObj.Write(DocumentWriteMode.Posting);
		
		If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
			vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		ElsIf TypeOf(vDocObj) = Type("DocumentObject.Reservation") Then
			vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
		
		vItemPresentation = TrimAll(vDocObj.HotelProduct) + " - " + String(vDocObj.Ref);
	Else
		Raise NStr("en='Failed to create vaucher with number '; ru='Ошибка регистрации путевки с номером бланка '; de='Fehler beim Registrieren eines Gutschein mit einer Nummer '") + vNumberStr + "!";
	EndIf;
	
	Return vItemPresentation;
EndFunction // FillVaucherAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetVaucher(pVaucherNumber, pVaucherType, pDoc)
	vVaucherRef = Undefined;
	If Not IsBlankString(pVaucherNumber) Then
		vVaucherRef = FindVaucherByDescription(pVaucherNumber, pVaucherType, pDoc.Hotel);
		If Not ValueIsFilled(vVaucherRef) Then
			vVaucherObj = Catalogs.HotelProducts.CreateItem();
			vVaucherObj.Hotel = pDoc.Hotel; 
			vVaucherObj.pmFillAttributesWithDefaultValues();
			vVaucherObj.Code = pVaucherNumber;
			vVaucherObj.Description = pVaucherNumber;
			vVaucherObj.Parent = pVaucherType;
			vVaucherObj.Write();
			
			vVaucherRef = vVaucherObj.Ref
		Else
			If vVaucherRef.DeletionMark Then
				vVaucherRef.GetObject().SetDeletionMark(False, False);
			EndIf;
		EndIf;
	EndIf;
	Return vVaucherRef;
EndFunction // GetVaucher

// --------------------------------------------------------------------------------
&AtServerNoContext
Function FindVaucherByDescription(pDescription, pVaucherType, pHotel)
	vVaucher = Undefined;
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	HotelProducts.Ref AS Ref
	|FROM
	|	Catalog.HotelProducts AS HotelProducts
	|WHERE
	|	NOT HotelProducts.IsFolder
	|	AND HotelProducts.Description = &qDescription
	|	AND HotelProducts.Parent = &qVaucherType
	|	AND HotelProducts.Hotel = &qHotel";
	vQuery.SetParameter("qDescription", pDescription);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qVaucherType", pVaucherType);
	
	vQueryResult = vQuery.Execute();
	If Not vQueryResult.IsEmpty() Then
		vData = vQueryResult.Select();
		vData.Next();
		vVaucher = vData.Ref;
	EndIf;

	Return vVaucher;
EndFunction // FindVaucherByDescription

// --------------------------------------------------------------------------------
&AtClient
Procedure ProcessDocumentsListItem() Export
	If i < DocumentsList.Count() Then
		vItem = DocumentsList.Get(i);
		
		If vItem.Check Then
			vNumber = Number(TrimAll(NumberFrom)) + j;
			vNumberDigits = StrLen(TrimAll(NumberFrom));
			vNumberStr = Format(vNumber, "ND=" + String(vNumberDigits) + "; NFD=0; NZ=; NLZ=; NG=");
			
			If vNumberStr > TrimAll(NumberTo) Then
				Notify("Catalog.GuestGroups.Changed", GuestGroup);
				Return;
			EndIf;
			
			vItem.Presentation = FillVaucherAtServer(vNumberStr, vItem.Value, vItem.Presentation, VaucherType);
			vItem.Check = False;

			j = j + 1;
		EndIf;
		
		i = i + 1;
		AttachIdleHandler("ProcessDocumentsListItem", 0.1, True);
	Else
		Notify("Catalog.GuestGroups.Changed", GuestGroup);
	EndIf;
EndProcedure // ProcessDocumentsListItem

// --------------------------------------------------------------------------------
&AtServer
Procedure NumbersOnChangeAtServer()
	NumberOfSelectedVauchers = 0;
	If DocumentsList.Count() = 0 Then
		TMessage = NStr("en='Documents list is empty!'; ru='Список документов пуст!'; de='Dokumentenliste ist leer!'");
	Else
		If IsBlankString(NumberFrom) Then
			TMessage = NStr("en='The beginning of the range of vaucher numbers must be filled!'; ru='Номер бланка начала диапазона должен быть указан!'; de='Der Beginn des Gutscheinnummernbereichs muss angegeben werden!'");
		ElsIf Not cmIsNumber(NumberFrom) Then
			TMessage = NStr("en='The beginning of the range of vaucher numbers must be number!'; ru='Номер бланка начала диапазона должен быть числом!'; de='Der Beginn des Gutscheinnummernbereichs muss eine Zahl sein!'");
		ElsIf IsBlankString(NumberTo) Then
			TMessage = NStr("en='The end of the range of vaucher numbers must be filled!'; ru='Номер бланка окончания диапазона должен быть указан!'; de='Der Einde des Gutscheinnummernbereichs muss angegeben werden!'");
		ElsIf Not cmIsNumber(NumberTo) Then
			TMessage = NStr("en='The end of the range of vaucher numbers must be number!'; ru='Номер бланка окончания диапазона должен быть числом!'; de='Der Einde des Gutscheinnummernbereichs muss eine Zahl sein!'");
		ElsIf NumberTo < NumberFrom Then
			TMessage = NStr("en='The range of vaucher numbers is wrong!'; ru='Диапазон номеров бланков указан неверно!'; de='Der Bereich der Formularnummern ist falsch!'");
		Else
			TMessage = "";
			NumberOfSelectedVauchers = Number(NumberTo) - Number(NumberFrom) + 1;
			i = 0;
			For Each vItem In DocumentsList Do
				vDoc = vItem.Value;
				If ValueIsFilled(vDoc.HotelProduct) Then
					vItem.Presentation = TrimAll(vDoc.HotelProduct) + " - " + String(vDoc);
				Else
					vItem.Presentation = String(vDoc);
				EndIf;
				If vItem.Check Then
					vNumber = Number(TrimAll(NumberFrom)) + i;
					vNumberDigits = StrLen(TrimAll(NumberFrom));
					vNumberStr = Format(vNumber, "ND=" + String(vNumberDigits) + "; NFD=0; NZ=; NLZ=; NG=");
					If vNumberStr > TrimAll(NumberTo) Then
						Continue;
					EndIf;
					vNumberStr = Catalogs.HotelProducts.SetVaucherNumberPresentation(vNumberStr, VaucherType);
					vItem.Presentation = "* " + TrimAll(vNumberStr) + " - " + String(vItem.Value);
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // NumbersOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure NumberOfSelectedVauchersOnChangeAtServer()
	If NumberOfSelectedVauchers = 0 Then
		NumberTo = "";
	Else
		If Not IsBlankString(NumberFrom) And cmIsNumber(NumberFrom) Then
			vNumberFrom = Number(NumberFrom);
			vNumberTo = vNumberFrom + NumberOfSelectedVauchers - 1;
			vNumberDigits = StrLen(TrimAll(NumberFrom));
			NumberTo = Format(vNumberTo, "ND=" + String(vNumberDigits) + "; NFD=0; NZ=; NLZ=; NG=");
		Else
			NumberOfSelectedVauchers = 0;
		EndIf;
	EndIf;
	NumbersOnChangeAtServer();
EndProcedure // NumberOfSelectedVauchersOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	vLang = Catalogs.Languages.RU;
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vLang = SessionParameters.CurrentHotel.Language;
	EndIf;		
	
	PrintForms.Clear();
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName,
	|	ObjectPrintingForms.IsDefault AS IsDefault,
	|	ObjectPrintingForms.Language AS Language
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	NOT ObjectPrintingForms.DeletionMark
	|	AND ObjectPrintingForms.IsActive = TRUE
	|	AND ObjectPrintingForms.ObjectType = &ObjectType
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code
	|TOTALS BY
	|	Language";
	vQuery.SetParameter("ObjectType", Documents.Accommodation.EmptyRef());	
	vQueryResult = vQuery.Execute();	
	vSelectionRecords = vQueryResult.Select(QueryResultIteration.ByGroups);
	While vSelectionRecords.Next() Do
		vSelectionDetailRecords = vSelectionRecords.Select(QueryResultIteration.ByGroups);
		If vLang = vSelectionRecords.Language or not ValueIsFilled(vSelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf not vLang = vSelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisForm, Items.FormGroupPrintingNotDefaultExtra, "Print" + vSelectionRecords.Language, "FormGroup", New Structure("Type, Title", FormGroupType.Popup, vSelectionRecords.Language));
		EndIf;
		
		While vSelectionDetailRecords.Next() Do
			If vSelectionDetailRecords.PredefinedDataName = "" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintHotelProduct" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestGroupHotelProducts" Then
				vNewRow = PrintForms.Add();
				vNewRow.PrintForm = vSelectionDetailRecords.Ref;
				vNewRow.IsDefault = vSelectionDetailRecords.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add("Print"+vID);
				vCommand.Action = "PrintButtonClick";
				If vSelectionDetailRecords.IsDefault Then
					vParent = Items.FormGroupPrintingDefault;
				Else
					vParent = vParentLang;
				EndIf;
				vStructure = New Structure("Title, CommandName",
				                            TrimAll(vSelectionDetailRecords.Code) + " " + cmNStr(vSelectionDetailRecords.Ref),
											"Print" + vID);
				
				tcOnServer.cmCreateItem(ThisForm, vParent, "Print" + vID, "FormButton", vStructure);
			EndIf;
		EndDo;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumber(pActionsNumber)
	vPrintForms = PrintForms.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vPrintForms);
	vStruct.Insert("PredefinedDataName",vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vPrintForms.ExternalProcessing);
	vStruct.Insert("Report",vPrintForms.Report);
	vStruct.Insert("Language",vPrintForms.Language);
	
	Return vStruct;
EndFunction // GetPrintFormForNumber

// -----------------------------------------------------------------------------
&AtClient
Function GetSelectedDocumentsList()
	vDocsList = New ValueList();
	For Each vDLItem In DocumentsList Do
		If vDLItem.Check Then
			vDocsList.Add(vDLItem.Value);
		EndIf;
	EndDo;
	Return vDocsList;
EndFunction // GetSelectedDocumentsList

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintHotelProduct(pLang, pForm, pDocObj = Undefined)
	If pForm = PredefinedValue("Catalog.ObjectPrintingForms.AccommodationPrintHotelProduct") Then
		vParams = new Structure("SelDocumentsList, SelObjectPrintForm", 
		                         GetSelectedDocumentsList(),
								 pForm);	
	ElsIf pForm = PredefinedValue("Catalog.ObjectPrintingForms.AccommodationPrintGuestGroupHotelProducts") Then
		vParams = new Structure("SelGuestGroup, SelCheckInDate, SelObjectPrintForm", 
		                         GuestGroup,
								 tcOnServer.cmGetAttributeByRef(GuestGroup, "CheckInDate"),
								 pForm);
	EndIf;
	OpenForm("Report.PrintHotelProducts.Form.tcReportForm", vParams, ThisForm, ThisForm.UUID);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef)
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage"); 
	vName = ConnectExternalDataProcessor(vURL, GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(pExtProcRef, "FileName")));
	vParams = New Structure("InputParameter, ObjectPrintingForm", GetSelectedDocumentsList(), pPrintFormTypeRef);
    vFrm = GetForm("ExternalDataProcessor." + vName + ".Form", vParams);
	vFrm.Open();
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtServer
Function GetExternalProcessingValidName(Val pStr)
	Return cmGetValidName(pStr); 	
EndFunction // GetExternalProcessingValidName

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef)
	vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef, "Report"), "ExternalProcessingStorage"); 
	vName = ConnectExternalReport(vURL, "ExternalReportForm");
	vParams = New Structure("DocumentsList, ObjectPrintingForm", GetSelectedDocumentsList(), pPrintFormTypeRef);
	OpenForm("ExternalReport." + vName + ".Form", vParams);
EndProcedure // OpenExternalReportForm

#EndRegion


