
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelHotel = SessionParameters.CurrentHotel;
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
	EndIf;
	SelHotelOnChangeAtServer();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	FillReports(pCancel);
	ThisForm.CurrentItem = ThisForm.Items.ReportsRootPage;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ReportDescriptionClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vCodePos = Find(pItem.Name, "Code");
	If vCodePos > 0 Then
		vReportFullCode = StrReplace(StrReplace(StrReplace(Mid(pItem.Name, vCodePos + 4), "_", "/"), "0comma0", ","), "0dot0", ".");
		vReportRef = GetReportByFullCodeAtServer(vReportFullCode);
		If ValueIsFilled(vReportRef) Then
			OpenReportForm(vReportRef);
		Else
			tcCommonFunctionOnClientServer.TextMessage("Error: unknown report! - " + pItem.Name);
		EndIf;		
	Else
		tcCommonFunctionOnClientServer.TextMessage("Error: unknown report! - " + pItem.Name);
	EndIf;		
EndProcedure // ReportDescriptionClick

// -----------------------------------------------------------------------------
&AtClient
Procedure NightAuditPrecheckReportClick(pItem)
	vFrm = GetForm("DataProcessor.DoNightAuditPrecheck.Form.tcForm");
	vFrm.Spreadsheet = NightAuditPrecheckReportAtServer();
	CopyFormData(DPObject, vFrm.Object); 
	vFrm.Open();
EndProcedure // NightAuditPrecheckReportClick

// -----------------------------------------------------------------------------
&AtClient
Procedure SearchStringOnChange(pItem)
	vCancel = False;
	FillReports(vCancel);
EndProcedure // SearchStringOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	FillReports(False);
	ThisForm.CurrentItem = ThisForm.Items.ReportsRootPage;
EndProcedure // SelHotelOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelHotelClearing

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SearchReports(pCommand)
	vCancel = False;
	FillReports(vCancel);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillReports(pCancel)
	// Build list of attributes to delete
	vAttributesToDeleteArray = New Array();
	For Each vFormItem In ThisForm.Items Do
		If Left(vFormItem.Name, 15) = "ReportsItemCode" And vFormItem.Type = FormFieldType.LabelField Then
			vAttributesToDeleteArray.Add(vFormItem.Name);
		EndIf;
	EndDo;
	i = 0;
	While i < ThisForm.Items.GroupPages.ChildItems.Count() Do
		vPageItem = ThisForm.Items.GroupPages.ChildItems[i];
		If vPageItem.Name <> "ReportsRootPage" And vPageItem.Name <> "RoutineOperationsPage" Then
			ThisForm.Items.Delete(vPageItem);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	i = 0;
	While i < ThisForm.Items.ReportsRootPageColumn1.ChildItems.Count() Do
		If ThisForm.Items.ReportsRootPageColumn1.ChildItems[i].Name <> "WebClientDecoration" Then
			ThisForm.Items.Delete(ThisForm.Items.ReportsRootPageColumn1.ChildItems[i]);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	i = 0;
	While i < ThisForm.Items.ReportsRootPageColumn2.ChildItems.Count() Do
		If ThisForm.Items.ReportsRootPageColumn2.ChildItems[i].Name <> "WebClientDecoration" Then
			ThisForm.Items.Delete(ThisForm.Items.ReportsRootPageColumn2.ChildItems[i]);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	i = 0;
	While i < ThisForm.Items.ReportsRootPageColumn3.ChildItems.Count() Do
		If ThisForm.Items.ReportsRootPageColumn3.ChildItems[i].Name <> "WebClientDecoration" Then
			ThisForm.Items.Delete(ThisForm.Items.ReportsRootPageColumn3.ChildItems[i]);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	ThisForm.Items.WebClientDecoration.Visible = False;
	
	// Build list of reports allowed for the employee
	vShowAllReports = True;
	If Not cmCheckUserPermissions("HavePermissionToRunAllReports") Then
		vShowAllReports = False;
		vAllowedReportsList = New ValueList();
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
			vAllowedReportsList = cmGetListOfAllowedReports(vPermissionGroup);
		EndIf;
		If vAllowedReportsList.Count() = 0 Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='There are no reports you have permission to generate!';ru='Не авторизованы на выполнение каких-либо отчетов!';de='Sie sind nicht für die Erfüllung von Berichten ermächtigt!'"), MessageStatus.Attention);
			Return;
		EndIf;
	EndIf;
	
	// Query reports
	vAllowedReportsQuery = New Query();
	vAllowedReportsQuery.Text = 
	"SELECT
	|	Reports.Ref AS Ref,
	|	Reports.Code AS Code,
	|	Reports.Parent AS Parent,
	|	Reports.IsFolder AS IsFolder,
	|	Reports.Description AS Description,
	|	Reports.Remarks AS Remarks
	|FROM
	|	Catalog.Reports AS Reports
	|WHERE
	|	NOT Reports.DeletionMark
	|	AND (Reports.Hotel = VALUE(Catalog.Hotels.EmptyRef)
	|			OR Reports.Hotel = &qHotel)
	|	AND (Reports.IsFolder
	|			OR &ShowAllReports
	|			OR Reports.Ref IN (&AllowedReportsList))
	|	AND (Reports.IsFolder
	|			OR &SearchCode = 0
	|			OR &SearchCode <> 0
	|				AND Reports.Code = &SearchCode)
	|	AND (Reports.IsFolder
	|			OR &SearchCode <> 0
	|			OR &SearchDescription = ""%%""
	|			OR &SearchDescription <> ""%%""
	|				AND Reports.Description LIKE &SearchDescription)
	|	AND CASE
	|			WHEN Reports.IsFolder
	|				THEN TRUE
	|			ELSE Reports.IsSystem = FALSE
	|		END
	|
	|ORDER BY
	|	Reports.IsFolder DESC,
	|	ISNULL(Reports.Parent.Parent.Parent.Code, 0),
	|	ISNULL(Reports.Parent.Parent.Code, 0),
	|	ISNULL(Reports.Parent.Code, 0),
	|	Reports.Code";
	vAllowedReportsQuery.SetParameter("AllowedReportsList", vAllowedReportsList);
	vAllowedReportsQuery.SetParameter("qHotel", SelHotel);
	vAllowedReportsQuery.SetParameter("ShowAllReports", vShowAllReports);
	vAllowedReportsQuery.SetParameter("SearchDescription", "%" + TrimAll(SearchString) + "%");
	vAllowedReportsQuery.SetParameter("SearchCode", ?(IsBlankString(SearchString), 0, ?(cmIsNumber(TrimAll(SearchString)), Number(TrimAll(SearchString)), 0)));
	vAllowedReportsQueryResult = vAllowedReportsQuery.Execute();
	vAllowedReportsList = vAllowedReportsQueryResult.Unload();
	
	// Create dynamic list of attributes
	vAttributesArray = New Array();
	For Each vAllowedReports In vAllowedReportsList Do
		If Not vAllowedReports.IsFolder Then
			vAttributeName = "ReportsItemCode" + GetFullCodePresentation(vAllowedReports.Ref);
			vFormAttribute = New FormAttribute(vAttributeName, New TypeDescription("String"), , cmNStr(TrimAll(vAllowedReports.Description)));
			vAttributesArray.Add(vFormAttribute);
		EndIf;
	EndDo;
	
	// Add attributes to the form
	ThisForm.ChangeAttributes(vAttributesArray, vAttributesToDeleteArray);
	
	vReportsPages = ThisForm.Items.Find("GroupPages");
	
	vReportRootPage = ThisForm.Items.Find("ReportsRootPage");
	
	// Add form items
	vCurParent = Undefined;
	vColumnIndex = 1;
	For Each vAllowedReports In vAllowedReportsList Do
		
		vLevel = vAllowedReports.Ref.Level();
		
		If vLevel = 0 Then
			If Not vAllowedReports.IsFolder Then
				vColumnIndex = vColumnIndex + 1;
				If vColumnIndex > 3 Then
					vColumnIndex = 1;
				EndIf;
			EndIf;
		ElsIf vLevel = 1 Then
			If vCurParent <> vAllowedReports.Parent Then
				vCurParent = vAllowedReports.Parent;
				vColumnIndex = 1;
			Else
				vColumnIndex = vColumnIndex + 1;
				If vColumnIndex > 3 Then
					vColumnIndex = 1;
				EndIf;
			EndIf;
		Else
			vColumnIndex = 1;
		EndIf;
		
		If vAllowedReports.IsFolder Then
			
			// Create groups for folders
			If vLevel = 0 Then
				vParent = vReportsPages;
				
				vItemName = "ReportsFolderCode" + GetFullCodePresentation(vAllowedReports.Ref);
				vItemGroup = ThisForm.Items.Add(vItemName, Type("FormGroup"), vParent);
				vItemGroup.Title = cmNStr(TrimAll(vAllowedReports.Description));
				vItemGroup.Type = FormGroupType.Page;
				vItemGroup.Group = ChildFormItemsGroup.Horizontal;
				vItemGroup.HorizontalStretch = True;
			
				For i = 1 To 3 Do
					vColumnName = "ReportsFolderCode" + GetFullCodePresentation(vAllowedReports.Ref) + "Column" + i;
					vColumnItem = ThisForm.Items.Add(vColumnName, Type("FormGroup"), vItemGroup);
					vColumnItem.Title = "Column " + i;
					vColumnItem.Type = FormGroupType.UsualGroup;
					vColumnItem.ShowTitle = False;
					vColumnItem.Representation = UsualGroupRepresentation.None;
					vColumnItem.Group = ChildFormItemsGroup.Vertical;
					vColumnItem.HorizontalStretch = True;
					vColumnItem.BackColor = StyleColors.BackgroundColorSpecial;
				EndDo;
			ElsIf vLevel = 1 Then
				vColumnName = "ReportsFolderCode" + GetFullCodePresentation(vAllowedReports.Parent) + "Column" + vColumnIndex;
				vParent = ThisForm.Items.Find(vColumnName);
				If vParent = Undefined Then
					tcCommonFunctionOnClientServer.TextMessage("Error: parent folder is missing! - " + cmNStr(TrimAll(vAllowedReports.Description)));
					Continue;
				EndIf;
				
				vItemName = "ReportsFolderCode" + GetFullCodePresentation(vAllowedReports.Ref);
				vItemGroup = ThisForm.Items.Add(vItemName, Type("FormGroup"), vParent);
				vItemGroup.Title = cmNStr(TrimAll(vAllowedReports.Description));
				vItemGroup.Type = FormGroupType.UsualGroup;
				vItemGroup.ShowTitle = True;
				vItemGroup.Representation = UsualGroupRepresentation.StrongSeparation;
				vItemGroup.Group = ChildFormItemsGroup.Vertical;
				vItemGroup.HorizontalStretch = True;
			Else
				vGroupName = "ReportsFolderCode" + GetFullCodePresentation(vAllowedReports.Parent);
				vParent = ThisForm.Items.Find(vGroupName);
				If vParent = Undefined Then
					tcCommonFunctionOnClientServer.TextMessage("Error: parent folder is missing! - " + cmNStr(TrimAll(vAllowedReports.Description)));
					Continue;
				EndIf;
				
				vItemName = "ReportsFolderCode" + GetFullCodePresentation(vAllowedReports.Ref);
				vItemGroup = ThisForm.Items.Add(vItemName, Type("FormGroup"), vParent);
				vItemGroup.Title = cmNStr(TrimAll(vAllowedReports.Description));
				vItemGroup.Type = FormGroupType.UsualGroup;
				vItemGroup.ShowTitle = True;
				vItemGroup.Representation = UsualGroupRepresentation.WeakSeparation;
				vItemGroup.Group = ChildFormItemsGroup.Vertical;
				vItemGroup.HorizontalStretch = True;
			EndIf;
				
		Else
			
			// Add report items
			If vLevel = 0 Then
				vColumnName = "ReportsRootPageColumn" + vColumnIndex;
				vParent = ThisForm.Items.Find(vColumnName);
			ElsIf vLevel = 1 Then
				vColumnName = "ReportsFolderCode" + GetFullCodePresentation(vAllowedReports.Parent) + "Column" + vColumnIndex;
				vParent = ThisForm.Items.Find(vColumnName);
			Else
				vColumnName = "ReportsFolderCode" + GetFullCodePresentation(vAllowedReports.Parent);
				vParent = ThisForm.Items.Find(vColumnName);
			EndIf;
			If vParent = Undefined Then
				tcCommonFunctionOnClientServer.TextMessage("Error: parent folder is missing! - " + cmNStr(TrimAll(vAllowedReports.Description)));
				Continue;
			EndIf;
			
			vItemName = "ReportsItemCode" + GetFullCodePresentation(vAllowedReports.Ref);
			
			ThisForm[vItemName] = Format(vAllowedReports.Code, "ND=6; NFD=; NG=") + " - " + cmNStr(TrimAll(vAllowedReports.Description));
				
			vItem = ThisForm.Items.Add(vItemName, Type("FormField"), vParent);
			vItem.Title = ThisForm[vItemName];
			vItem.Type = FormFieldType.LabelField;
			vItem.DataPath = vItemName;
			vItem.TitleLocation = FormItemTitleLocation.None;
			vItem.ToolTip = cmNStr(vAllowedReports.Remarks);
			If Not IsBlankString(vItem.ToolTip) Then
				vItem.ToolTipRepresentation = ToolTipRepresentation.Button;
			Else
				vItem.ToolTipRepresentation = ToolTipRepresentation.None;
			EndIf;
			vItem.Hyperlink = True;
			vItem.SetAction("Click", "ReportDescriptionClick");
			
		EndIf;
	EndDo;
	
	// Move routines page to the end
	ThisForm.Items.Move(ThisForm.Items.RoutineOperationsPage, ThisForm.Items.RoutineOperationsPage.Parent); 
	
	// Check user right to see end of day audit report
	If Not IsInRole("SubsystemFrontOffice") And 
	   Not IsInRole("Administrator") And 
	   Not IsInRole("InternalControllerDivisionUser") And 
	   Not IsInRole("Accountant") Then
		Items.GroupNightAuditPrecheck.Visible = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetReportByFullCodeAtServer(pFullCode)
	Return Catalogs.Reports.FindByCode(pFullCode, True);
EndFunction // GetReportByFullCodeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetFullCodePresentation(pRef)
	Return StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(pRef.FullCode(), Chars.NBSp, ""), "/", "_"), " ", ""), ",", "0comma0"), ".", "0dot0");
EndFunction // GetFullCodePresentation 

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenReportForm(pReportRef)
	vManagedReportForm = Undefined;
	vReportObj = tcOnServer.cmGetAtributeAsArray(pReportRef);
	If vReportObj.IsExternal Then
		vURL = GetURL(vReportObj.Report, "ExternalProcessingStorage"); 
		vName = ConnectExternalReport(vURL, StrReplace(tcOnServer.cmGetAttributeByRef(vReportObj.Report,"FileName"),".erf",""));
		vParams = New Structure("FillingValues, GenerateOnOpen", New Structure("ReportRef", pReportRef), Not vReportObj.DoNotGenerateOnOpen);
		OpenForm("ExternalReport." + vName + ".Form", vParams, ThisForm, New UUID());
	Else	
		If vReportObj.Report = Undefined Then
			Raise Nstr("en = 'You must fill the handler in the report settings'; de = 'Sie müssen den Handler in den Berichteinstellungen ausfüllen'; ru = 'Необходимо заполнить обработчик в настройках отчета'");
		Else
			OpenForm("Report." + vReportObj.Report + ".Form", New Structure("FillingValues, GenerateOnOpen", New Structure("ReportRef", pReportRef), Not vReportObj.DoNotGenerateOnOpen), ThisForm, New UUID());
		EndIf; 
	EndIf;	
EndProcedure // OpenReportForm

// -----------------------------------------------------------------------------
&AtServer
Function NightAuditPrecheckReportAtServer()
	vDPObj = DataProcessors.DoNightAuditPrecheck.Create();
	vDPObj.DataProcessor = Catalogs.DataProcessors.DoNightAuditPrecheck;
	vDPObj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(vDPObj, "DPObject");
	vSpreadsheet = new SpreadsheetDocument;
	vDPObj.pmDoNightAuditPrecheck(False, vSpreadsheet);
	Return vSpreadsheet;
EndFunction // NightAuditPrecheckReportAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure SelHotelOnChangeAtServer()        	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");	
EndProcedure // SelHotelOnChangeAtServer

#EndRegion

