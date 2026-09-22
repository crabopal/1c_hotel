
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill default company
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) Then
		SelCompany = SessionParameters.CurrentUser.Company;
	EndIf;
	SelHotel = SessionParameters.CurrentHotel;
	
	// Build list of cash registers by company and current user
	BuildCashRegistersListByCompany();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure XReport(pCommand)
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterXReport") Then
		i = Number(Mid(pCommand.Name, 8)) - 1;
		vCashRegister = CashRegistersList.Get(i).Value;
		vID = Format(i + 1, "NFD=0; NZ=; NG=");
		// Call external command if necessary
		vXCommand = TrimAll(tcOnServer.cmGetAttributeByRef(vCashRegister, "XReportCommand"));
		If Not IsBlankString(vXCommand) Then
			vCurDir = "";
			j = StrLen(vXCommand);  
			// ACC:561-off
			While j > 1 Do
				vFile = New File(Left(vXCommand, j));
				If tcCommonFunctionOnClientServer.cmExists(vFile) Then
					vCurDir = vFile.Path;
					Break;
				Else
					j = j - 1;
				EndIf;
			EndDo;            
			// ACC:561-on
			BeginRunningApplication(New NotifyDescription, vXCommand, vCurDir, True);
		Else
			// Open program printing form
			OpenForm("Report.PrintCashRegisterDayReport.Form.tcXReportForm", New Structure("CashRegister", vCashRegister), , vCashRegister);
		EndIf;
		// Enable Z-Report button
		Items["FormButtonZReport" + vID].Enabled = True;
	Else
		ShowMessageBox(, NStr("en='You do not have rights to print X-Report!'; ru='Нет прав на печать X-Отчета!'; de='Sie haben keine Rechte, X-Report zu drucken!'"));
	EndIf;
EndProcedure // XReport

// --------------------------------------------------------------------------------
&AtClient
Procedure ZReport(pCommand)
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterZReport") Then
		i = Number(Mid(pCommand.Name, 8)) - 1;
		vCashRegister = CashRegistersList.Get(i).Value;
		vID = Format(i + 1, "NFD=0; NZ=; NG=");
		// Call external command if necessary
		vZCommand = TrimAll(tcOnServer.cmGetAttributeByRef(vCashRegister, "ZReportCommand"));
		If Not IsBlankString(vZCommand) Then
			vRetCode = 0;
			vCurDir = "";
			j = StrLen(vZCommand); 
			// ACC:561-off
			While j > 1 Do
				vFile = New File(Left(vZCommand, j));
				If tcCommonFunctionOnClientServer.cmExists(vFile) Then
					vCurDir = vFile.Path;
					Break;
				Else
					j = j - 1;
				EndIf;
			EndDo; 
			// ACC:561-on
			BeginRunningApplication(New NotifyDescription, vZCommand, vCurDir, True);
		Else
			// Open close of cash register shift document
			OpenForm("Document.CloseOfCashRegisterDay.ObjectForm", New Structure("Basis, PostAndCloseOnOpen", vCashRegister, True), , vCashRegister);
		EndIf;
		// Disable Z-Report button
		Items["FormButtonZReport" + vID].Enabled = False;
		Items["FormDecorationNotCompleted" + vID].Visible = False;
		Items["FormDecorationCompleted" + vID].Visible = True;
		// Update number of closed shifts
		UpdateNumberOfClosedShifts(vID);
	Else
		ShowMessageBox(, NStr("en='You do not have rights to print Z-Report!'; ru='Нет прав на печать Z-Отчета!'; de='Sie haben keine Rechte, Z-Report zu drucken!'"));
	EndIf;
EndProcedure // ZReport

#EndRegion         

#Region Private

// --------------------------------------------------------------------------------
// 
// Returns:
//  Date - AccountingDate
//
&AtServer
Function GetAccountingDate()
	vAccountingDate = BegOfDay(CurrentSessionDate());
	If ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.AccountingDate) Then
		vAccountingDate = BegOfDay(SelHotel.AccountingDate);
	EndIf;
	Return vAccountingDate;
EndFunction // GetAccountingDate 

// --------------------------------------------------------------------------------
&AtServer
Procedure BuildCashRegistersListByCompany()
	Items.GroupRightColumn.Visible = False;
	vHasRightsForXReport = cmCheckUserPermissions("HavePermissionToPrintCashRegisterXReport");
	vAccountingDate = GetAccountingDate();
	
	// Get list of cash registers allowed for the current user
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		vCashRegistersList = cmGetListOfAllCashRegisters(SelCompany);
	Else
		vCashRegistersList = cmGetListOfCashRegistersAllowed(SelCompany, SessionParameters.CurrentWorkstation, Undefined);
	EndIf;
	
	// Get number of already closed shifts for the current date
	vClosedShifts = GetNumberOfClosedShiftsPerDay(vCashRegistersList, vAccountingDate);
	
	// Fill form
	If vCashRegistersList.Count() = 0 Then
		Items.GroupCashRegister1.Visible = False;
		Items.DecorationNoCashRegistersWasFound.Visible = True;
	Else
		Items.GroupCashRegister1.Visible = True;
		Items.DecorationNoCashRegistersWasFound.Visible = False;
		Items.FormDecorationNotCompleted1.Visible = True;
		Items.FormDecorationCompleted1.Visible = False;
		
		// First cash register
		CashRegister1 = vCashRegistersList.Get(0).Value;
		CashRegisterPresentation1 = "";
		FillNumberOfCloseShiftsPerDay(CashRegister1, CashRegisterPresentation1, vClosedShifts);
		
		// Commands appearance
		If vHasRightsForXReport Then
			Items.FormButtonXReport1.Enabled = True;
			Items.FormButtonZReport1.Enabled = False;
		Else
			Items.FormButtonXReport1.Enabled = False;
			Items.FormButtonZReport1.Enabled = True;
		EndIf;
	EndIf;
	If vCashRegistersList.Count() > 1 Then
		vPerColumn = Int(vCashRegistersList.Count() / 2);
		If Int(vCashRegistersList.Count() / 2) <> vCashRegistersList.Count() / 2 Then
			vPerColumn = vPerColumn + 1;
		EndIf;
		If vCashRegistersList.Count() < 6 Then
			vPerColumn = 5;
		EndIf;
		If vCashRegistersList.Count() <= vPerColumn Then
			Items.GroupRightColumn.Visible = False;
		Else
			Items.GroupRightColumn.Visible = True;
		EndIf;
		
		vFormatID = "NFD=0; NZ=; NG=";   
		vItemName = "CashRegister"; 
		vItemNamePres = "CashRegisterPresentation";
		// Create custom fields form attributes
		vAttrArray = New Array();
		For vInt = 1 To (vCashRegistersList.Count() - 1) Do
			vID = Format(vInt + 1, vFormatID);
			vAttrArray.Add(New FormAttribute(vItemName + vID, cmGetCatalogTypeDescription("CashRegisters")));
			vAttrArray.Add(New FormAttribute(vItemNamePres + vID, cmGetStringTypeDescription(10)));
		EndDo;		
		ChangeAttributes(vAttrArray);
		
		// Fill attributes  
		For vInt = 1 To (vCashRegistersList.Count() - 1) Do
			vID = Format(vInt + 1, vFormatID);
			ThisObject[vItemName + vID] = vCashRegistersList.Get(vInt).Value;
			ThisObject[vItemNamePres + vID] = "";
			FillNumberOfCloseShiftsPerDay(ThisObject[vItemName + vID], ThisObject[vItemNamePres + vID], vClosedShifts);
		EndDo;
		
		// Create form items for all cash registers
		For vInt = 1 To (vCashRegistersList.Count() - 1) Do
			vID = Format(vInt + 1, vFormatID);
			
			// Create cash register vertical group
			vGroupCashRegister = tcOnServer.cmCreateItem(ThisObject, ?((vInt + 1) > vPerColumn, Items.GroupRightColumn, Items.GroupLeftColumn), "GroupCashRegister" + vID, "FormGroup",
												         New Structure("Type, Title, Width, Group, ShowTitle",
												                       FormGroupType.UsualGroup, NStr("en='POS '; ru='ККМ '; de='Kasse '") + vID, 0, ChildFormItemsGroup.Vertical, False));
																	   
			// Create cash register horizontal actions group
			vGroupCashRegisterActions = tcOnServer.cmCreateItem(ThisObject, vGroupCashRegister, "GroupShiftActions" + vID, "FormGroup",
												                New Structure("Type, Title, Width, Group, ShowTitle",
												                              FormGroupType.UsualGroup, NStr("en='Shift actions '; ru='Действия смены '; de='Shift-Aktionen '") + vID, 0, ChildFormItemsGroup.AlwaysHorizontal, False));
			// Create item for splitter
			vDecoration = tcOnServer.cmCreateItem(ThisObject, vGroupCashRegister, "Decoration" + vID, "FormDecoration", 
			                                      New Structure("Type, Title, AutoMaxWidth, HorizontalStretch", 
			                                                    FormDecorationType.Label, "", False, True));
			vDecoration.Border = tcCommonFunctionOnClientServer.BorderConstructor(ControlBorderType.Underline, 1);
			
			// Create item for cash register attribute
			tcOnServer.cmCreateItem(ThisObject, vGroupCashRegisterActions, vItemName + vID, "FormField",
			                        New Structure("Type, DataPath, Title, TitleLocation",
			                                      FormFieldType.LabelField, vItemName + vID, "", FormItemTitleLocation.None));
			
			// Create cash register commands
			vXCommand = Commands.Add("XReport" + vID);
			vXCommand.Action = "XReport";
			vXCommand.ToolTip = NStr("en = 'X-Report'; de = 'X-Bericht'; ru = 'X-Отчет'");
			vXCommandStruct = New Structure("Title, CommandName, Representation, Type", 
			                                vXCommand.ToolTip, "XReport" + vID, ButtonRepresentation.Auto, FormButtonType.UsualButton);
			vXReportItem = tcOnServer.cmCreateItem(ThisObject, vGroupCashRegisterActions, "XReport" + vID, "FormButton", vXCommandStruct);
			If vHasRightsForXReport Then
				vXReportItem.Enabled = True;
			Else
				vXReportItem.Enabled = False;
			EndIf;
			
			vZCommand = Commands.Add("ZReport" + vID);
			vZCommand.Action = "ZReport";
			vZCommand.ToolTip = NStr("en = 'Z-Report'; de = 'Z-Bericht'; ru = 'Z-Отчет'");
			vZCommandStruct = New Structure("Title, CommandName, Representation, Type", 
			                                vZCommand.ToolTip, "ZReport" + vID, ButtonRepresentation.Auto, FormButtonType.UsualButton);
			vZReportItem = tcOnServer.cmCreateItem(ThisObject, vGroupCashRegisterActions, "ZReport" + vID, "FormButton", vZCommandStruct);
			If vHasRightsForXReport Then
				vZReportItem.Enabled = False;
			Else
				vZReportItem.Enabled = True;
			EndIf;
			
			// Create item for cash register number of closed shifts
			tcOnServer.cmCreateItem(ThisObject, vGroupCashRegisterActions, vItemNamePres + vID, "FormField",
			                        New Structure("Type, DataPath, Title, TitleLocation, Width",
			                                      FormFieldType.LabelField, vItemNamePres + vID, "", FormItemTitleLocation.None, 7));
			
			// Create empty picture
			vNotChecked = tcOnServer.cmCreateItem(ThisObject, vGroupCashRegisterActions, "NotCompleted" + vID, "FormDecoration", 
			                                      New Structure("Type, Title, Picture", 
			                                                    FormDecorationType.Picture, "", PictureLib.Empty));
			vNotChecked.VerticalAlignInGroup = ItemVerticalAlign.Center;
			vNotChecked.Visible = True;
			
			// Create checked picture
			vChecked = tcOnServer.cmCreateItem(ThisObject, vGroupCashRegisterActions, "Completed" + vID, "FormDecoration", 
			                                   New Structure("Type, Title, Picture", 
			                                                 FormDecorationType.Picture, "", PictureLib.CheckMark));
			vChecked.VerticalAlignInGroup = ItemVerticalAlign.Center;
			vChecked.Visible = False;
		EndDo;
	EndIf;
	
	// Save cash registers list to form attribute
	CashRegistersList.Clear();
	CashRegistersList.LoadValues(vCashRegistersList.UnloadValues());
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Function GetNumberOfClosedShiftsPerDay(pCashRegistersList, pDate)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CloseOfCashRegisterDay.CashRegister AS CashRegister,
	|	CloseOfCashRegisterDay.CashRegister.MaximumNumberOfZReportsPerDay AS MaximumNumberOfZReportsPerDay,
	|	COUNT(CloseOfCashRegisterDay.Ref) AS NumberOfClosedShifts
	|FROM
	|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
	|WHERE
	|	CloseOfCashRegisterDay.CashRegister IN(&qCashRegistersList)
	|	AND (CloseOfCashRegisterDay.AccountingDate <> &qEmptyDate
	|				AND CloseOfCashRegisterDay.AccountingDate = &qAccountingDate
	|			OR CloseOfCashRegisterDay.AccountingDate = &qEmptyDate
	|				AND BEGINOFPERIOD(CloseOfCashRegisterDay.Date, DAY) = &qAccountingDate)
	|	AND CloseOfCashRegisterDay.Posted
	|
	|GROUP BY
	|	CloseOfCashRegisterDay.CashRegister,
	|	CloseOfCashRegisterDay.CashRegister.MaximumNumberOfZReportsPerDay";
	vQry.SetParameter("qCashRegistersList", pCashRegistersList);
	vQry.SetParameter("qAccountingDate", BegOfDay(pDate));
	vQry.SetParameter("qEmptyDate", '00010101');
	Return vQry.Execute().Unload();	
EndFunction // GetNumberOfClosedShiftsPerDay

// --------------------------------------------------------------------------------
&AtServer
Procedure FillNumberOfCloseShiftsPerDay(pCashRegister, pCashRegisterPresentation, pClosedShifts)
	vShiftsRow = pClosedShifts.Find(pCashRegister, "CashRegister");              
	vFormatID = "NFD=0; NZ=; NG="; 
	If vShiftsRow <> Undefined Then
		If vShiftsRow.NumberOfClosedShifts <> Null And vShiftsRow.NumberOfClosedShifts > 0 Then
			If vShiftsRow.MaximumNumberOfZReportsPerDay > 0 Then
				pCashRegisterPresentation = "(" + Format(vShiftsRow.NumberOfClosedShifts, vFormatID) + "/" + Format(vShiftsRow.MaximumNumberOfZReportsPerDay, vFormatID) + ")";
			Else
				pCashRegisterPresentation = "(" + Format(vShiftsRow.NumberOfClosedShifts, vFormatID) + ")";
			EndIf;
		Else
			If vShiftsRow.MaximumNumberOfZReportsPerDay > 0 Then
				pCashRegisterPresentation = "(0/" + Format(vShiftsRow.MaximumNumberOfZReportsPerDay, vFormatID) + ")";
			Else
				pCashRegisterPresentation = "(0)";
			EndIf;
		EndIf;
	Else
		If pCashRegister.MaximumNumberOfZReportsPerDay > 0 Then
			pCashRegisterPresentation = "(0/" + Format(pCashRegister.MaximumNumberOfZReportsPerDay, vFormatID) + ")";
		Else
			pCashRegisterPresentation = "(0)";
		EndIf;
	EndIf;
EndProcedure // FillNumberOfCloseShiftsPerDay

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdateNumberOfClosedShifts(pID)
	vAccountingDate = GetAccountingDate();
	vClosedShifts = GetNumberOfClosedShiftsPerDay(CashRegistersList, vAccountingDate);
	FillNumberOfCloseShiftsPerDay(ThisObject["CashRegister" + pID], ThisObject["CashRegisterPresentation" + pID], vClosedShifts);
EndProcedure // UpdateNumberOfClosedShifts

#EndRegion
