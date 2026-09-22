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
	FillDataProcessors(pCancel);
	ThisForm.CurrentItem = ThisForm.Items.ReportsRootPage;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SearchStringOnChange(pItem)
	vCancel = False;
	FillDataProcessors(vCancel);
EndProcedure // SearchStringOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SearchDP(pCommand)
	vCancel = False;
	FillDataProcessors(vCancel);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDataProcessors(pCancel)
	// Build list of attributes to delete
	vAttributesToDeleteArray = New Array();
	For Each vFormItem In ThisForm.Items Do
		If Left(vFormItem.Name, 15) = "ReportsItemCode" And vFormItem.Type = FormFieldType.LabelField Then
			vAttributesToDeleteArray.Add(vFormItem.Name);
		EndIf;
	EndDo;
	vInd = 0;
	While vInd < ThisForm.Items.GroupPages.ChildItems.Count() Do
		vPageItem = ThisForm.Items.GroupPages.ChildItems[vInd];
		If vPageItem.Name <> "ReportsRootPage" And vPageItem.Name <> "RoutineOperationsPage" Then
			ThisForm.Items.Delete(vPageItem);
		Else
			vInd = vInd + 1;
		EndIf;
	EndDo;
	vInd = 0;
	While vInd < ThisForm.Items.ReportsRootPageColumn1.ChildItems.Count() Do
		If ThisForm.Items.ReportsRootPageColumn1.ChildItems[vInd].Name <> "WebClientDecoration" Then
			ThisForm.Items.Delete(ThisForm.Items.ReportsRootPageColumn1.ChildItems[vInd]);
		Else
			vInd = vInd + 1;
		EndIf;
	EndDo;
	vInd = 0;
	While vInd < ThisForm.Items.ReportsRootPageColumn2.ChildItems.Count() Do
		If ThisForm.Items.ReportsRootPageColumn2.ChildItems[vInd].Name <> "WebClientDecoration" Then
			ThisForm.Items.Delete(ThisForm.Items.ReportsRootPageColumn2.ChildItems[vInd]);
		Else
			vInd = vInd + 1;
		EndIf;
	EndDo;
	vInd = 0;
	While vInd < ThisForm.Items.ReportsRootPageColumn3.ChildItems.Count() Do
		If ThisForm.Items.ReportsRootPageColumn3.ChildItems[vInd].Name <> "WebClientDecoration" Then
			ThisForm.Items.Delete(ThisForm.Items.ReportsRootPageColumn3.ChildItems[vInd]);
		Else
			vInd = vInd + 1;
		EndIf;
	EndDo;
	ThisForm.Items.WebClientDecoration.Visible = False;
	
	// Build list of reports allowed for the employee
	vShowAllDP = True;
	If Not cmCheckUserPermissions("HavePermissionToRunAllDataProcessors") Then
		vShowAllDP = False;
		vAllowedDPList = New ValueList();
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
			vAllowedDPList = cmGetListOfAllowedDataProcessors(vPermissionGroup);
		EndIf;
		If vAllowedDPList.Count() = 0 Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='There are no data processors you have permission to generate!';ru='Не авторизованы на выполнение каких-либо обработок!';de='Es gibt keine Datenprozessoren, für die Sie eine Berechtigung haben!'"), MessageStatus.Attention);
			Return;
		EndIf;
	EndIf;
	
	// Query reports
	vAllowedReportsQuery = New Query();
	vAllowedReportsQuery.Text = 
	"SELECT
	|	DP.Ref AS Ref,
	|	DP.Code AS Code,
	|	DP.Parent AS Parent,
	|	DP.IsFolder AS IsFolder,
	|	DP.Description AS Description,
	|	DP.Remarks AS Remarks
	|FROM
	|	Catalog.DataProcessors AS DP
	|WHERE
	|	NOT DP.DeletionMark
	|	AND (DP.Hotel = VALUE(Catalog.Hotels.EmptyRef)
	|			OR DP.Hotel = &qHotel)
	|	AND (DP.IsFolder
	|			OR &ShowAllReports
	|			OR DP.Ref IN (&AllowedReportsList))
	|	AND (DP.IsFolder
	|			OR &SearchCode = 0
	|			OR &SearchCode <> 0
	|				AND DP.Code = &SearchCode)
	|	AND (DP.IsFolder
	|			OR &SearchCode <> 0
	|			OR &SearchDescription = ""%%""
	|			OR &SearchDescription <> ""%%""
	|				AND DP.Description LIKE &SearchDescription)
	|	AND CASE
	|			WHEN DP.IsFolder
	|				THEN TRUE
	|			ELSE DP.IsSystem = FALSE
	|		END
	|
	|ORDER BY
	|	DP.IsFolder DESC,
	|	ISNULL(DP.Parent.Parent.Parent.Code, 0),
	|	ISNULL(DP.Parent.Parent.Code, 0),
	|	ISNULL(DP.Parent.Code, 0),
	|	DP.Code";
	vAllowedReportsQuery.SetParameter("AllowedReportsList", vAllowedDPList);
	vAllowedReportsQuery.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vAllowedReportsQuery.SetParameter("ShowAllReports", vShowAllDP);
	vAllowedReportsQuery.SetParameter("SearchDescription", "%" + TrimAll(SearchString) + "%");
	vAllowedReportsQuery.SetParameter("SearchCode", ?(IsBlankString(SearchString), 0, ?(cmIsNumber(TrimAll(SearchString)), Number(TrimAll(SearchString)), 0)));
	vAllowedReportsQueryResult = vAllowedReportsQuery.Execute();
	vAllowedDPList = vAllowedReportsQueryResult.Unload();
	
	// Create dynamic list of attributes
	vAttributesArray = New Array();
	For Each vAllowedReports In vAllowedDPList Do
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
	For Each vAllowedReports In vAllowedDPList Do
		
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
			
				For vInd = 1 To 3 Do
					vColumnName = "ReportsFolderCode" + GetFullCodePresentation(vAllowedReports.Ref) + "Column" + vInd;
					vColumnItem = ThisForm.Items.Add(vColumnName, Type("FormGroup"), vItemGroup);
					vColumnItem.Title = "Column " + vInd;
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
			vItem.Hyperlink = True;
			vItem.SetAction("Click", "DPClick");
		EndIf;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetDPByFullCodeAtServer(pFullCode)
	Return Catalogs.DataProcessors.FindByCode(pFullCode, True);
EndFunction // GetReportByFullCodeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetFullCodePresentation(pRef)
	Return StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(pRef.FullCode(), Chars.NBSp, ""), "/", "_"), " ", ""), ",", "0comma0"), ".", "0dot0");
EndFunction // GetFullCodePresentation 

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenDPForm(pDPRef)
	vManagedReportForm = Undefined;  
	Try  
		vDPObj = tcOnServer.cmGetAtributeAsArray(pDPRef);
		If vDPObj.IsExternal Then  
			vExtDPO = tcOnServer.cmGetAtributeAsArray(vDPObj.Processing); 
			If vExtDPO.ExternalProcessingType = PredefinedValue("Enum.ExternalProcessingTypes.Algorithm") Then
				ExecuteAlgoritm(vExtDPO);
			Else	
				vURL = GetURL(vDPObj.Processing, "ExternalProcessingStorage"); 
				vName = ConnectExternalDataProcessor(vURL, StrReplace(tcOnServer.cmGetAttributeByRef(vDPObj.Processing,"FileName"),".epf",""));
				vParams = New Structure("DataProcessor", pDPRef);
				OpenForm("ExternalDataProcessor." + vName + ".Form", vParams, ThisForm, pDPRef);     
			EndIf;
		Else
			If vDPObj.Processing = Undefined Then
				Raise Nstr("en = 'You must fill the handler in the processing settings'; de = 'Sie müssen den Handler in den Verarbeitungseinstellungen angeben'; ru = 'Необходимо заполнить обработчик в настройках обработки'");
			Else
				OpenForm("DataProcessor." + vDPObj.Processing + ".Form", New Structure("DataProcessor", pDPRef), ThisForm, pDPRef);
			EndIf;
		EndIf; 
	Except
		ClearMessages();
		vErr = ErrorInfo();
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='This data processor could not be executed in thin client mode yet!'; 
		             |ru='Эта обработка пока не может быть запущена в режиме тонкого клиента!'; 
					 |de='Dieser Bearbeitung kann noch nicht in Thin-Client-Modus gestartet werden!'") + Chars.LF + BriefErrorDescription(vErr), MessageStatus.Attention);
		
	EndTry;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ExecuteAlgoritm(pDPO)
	vAlgorithm = TrimAll(pDPO.Algorithm);
	Execute(vAlgorithm);
EndProcedure // OpenReportForm

// -----------------------------------------------------------------------------
&AtClient
Procedure DPClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vCodePos = Find(pItem.Name, "Code");
	If vCodePos > 0 Then
		vDPFullCode = StrReplace(StrReplace(StrReplace(Mid(pItem.Name, vCodePos + 4), "_", "/"), "0comma0", ","), "0dot0", ".");
		vDPRef = GetDPByFullCodeAtServer(vDPFullCode);
		If ValueIsFilled(vDPRef) Then
			OpenDPForm(vDPRef);
		Else
			tcCommonFunctionOnClientServer.TextMessage("Error: unknown data processor! - " + pItem.Name);
		EndIf;		
	Else
		tcCommonFunctionOnClientServer.TextMessage("Error: unknown data processor! - " + pItem.Name);
	EndIf;		
EndProcedure // DataProcessorsClick

// --------------------------------------------------------------------------------
&AtServer
Procedure SelHotelOnChangeAtServer()        	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");	
EndProcedure // SelHotelOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SelHotelOnChangeAtServer(); 
	FillDataProcessors(False);
	ThisForm.CurrentItem = ThisForm.Items.ReportsRootPage;
EndProcedure // SelHotelOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelHotelClearing

#EndRegion



