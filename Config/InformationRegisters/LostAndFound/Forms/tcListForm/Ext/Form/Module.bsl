
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		pCancel = True;
		Return;
	EndIf;
	
	SelHotel = SessionParameters.CurrentHotel;
	SelFilter = 1;
	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant"); 
	
	SelListMode = 0;
	
	ListModes.Clear();
	ListModes.Add(0, NStr("en='Date when found'; ru='Дата обнаружения'; de='Datum der Entdeckung'") + "...");
	ListModes.Add(1, NStr("en='Date when returned'; ru='Дата возврата'; de='Datum der Rückgabe'") + "...");
	ListModes.Add(2, NStr("en='Disposed date'; ru='Дата утилизации'; de='Entsorgungsdatum'") + "...");
	
	// Apply filter
	ChangeFilter();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SelFilterOnChange(pItem)
	ChangeFilter();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelPassedDaysOnChange(pItem)
	If SelPassedDays <> 0 Then
		If SelListMode <> 0 Then
			SelListMode = 0;

			Items.ChangeListMode.Title = ListModes.Get(SelListMode).Presentation;
			Items.ChangeListMode.Picture = ListModes.Get(SelListMode).Picture;     
		EndIf;
	EndIf;
	ChangeFilter();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelPeriodFromOnChange(pItem)
	ChangeFilter();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelPeriodToOnChange(pItem)
	ChangeFilter();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure PrintItemsRegistrationList(pCommand)      
	vParameters = New Structure("ChosenRows, Owner", Items.List.SelectedRows, SelHotel);
	vParameters.Insert("Type", "Register");
	OpenForm("InformationRegister.LostAndFound.Form.tcPrintForm", vParameters, ThisObject, , , , , FormWindowOpeningMode.Independent);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PrintItemsReturnList(pCommand)      
	vParameters = New Structure("ChosenRows, Owner", Items.List.SelectedRows, SelHotel);
	vParameters.Insert("Type", "Return");
	OpenForm("InformationRegister.LostAndFound.Form.tcPrintForm", vParameters, ThisObject, , , , , FormWindowOpeningMode.Independent);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeListMode(pCommand)                               
	ShowChooseFromMenu(New NotifyDescription("ListModesAfterChoice", ThisObject), ListModes, Items.ChangeListMode);
EndProcedure // ChangeListMode

// -----------------------------------------------------------------------------
&AtClient
Procedure Dispose(pCommand)    
	ClearMessages();
	ShowQueryBox(New NotifyDescription("OnDisposeConfirmation", ThisObject), 
	             NStr("en='Mark selected records as disposed?'; ru='Пометить выделенные записи как утилизированные?'; de='Ausgewählte Datensätze als entsorgt markieren?'"), 
				 QuestionDialogMode.YesNo, , DialogReturnCode.No);
EndProcedure // Dispose

// -----------------------------------------------------------------------------
&AtClient
Procedure OnDisposeConfirmation(pUC, pExtraParams) Export
	If pUC = DialogReturnCode.Yes Then
		DisposeAtServer();  
		ChangeFilter();
	EndIf;
EndProcedure // OnDisposeConfirmation

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = SelPeriodFrom;
	vChoosePeriodDialog.Period.EndDate = SelPeriodTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod

#EndRegion    

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure ChangeFilter()
	List.Parameters.SetParameterValue("qHotel", SelHotel);
	List.Parameters.SetParameterValue("qCurrentDate", BegOfDay(CurrentSessionDate()));
	List.Parameters.SetParameterValue("qPeriodFrom", ?(ValueIsFilled(SelPeriodFrom), BegOfDay(SelPeriodFrom), '00010101'));
	List.Parameters.SetParameterValue("qPeriodTo", ?(ValueIsFilled(SelPeriodTo), EndOfDay(SelPeriodTo), EndOfDay('39991231')));
	List.Parameters.SetParameterValue("qByDateWhenFound", SelListMode = 0);
	List.Parameters.SetParameterValue("qByDateWhenReturned", SelListMode = 1);
	List.Parameters.SetParameterValue("qByDateWhenDisposed", SelListMode = 2);
    List.Parameters.SetParameterValue("qAll", SelFilter = 0);
    List.Parameters.SetParameterValue("qActiveOnly", SelFilter = 1);
    List.Parameters.SetParameterValue("qReturnedOnly", SelFilter = 2);
    List.Parameters.SetParameterValue("qDisposedOnly", SelFilter = 3);
	List.Parameters.SetParameterValue("qDaysPassed", SelPassedDays);
	
	Items.ChangeListMode.Title = ListModes.Get(SelListMode).Presentation;
	Items.ChangeListMode.Picture = ListModes.Get(SelListMode).Picture;     
EndProcedure	

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		SelPeriodFrom = pPeriod.StartDate;
		SelPeriodTo = pPeriod.EndDate;
	EndIf;
	ChangeFilter();
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ListModesAfterChoice(pItem, pExtraParameters) Export
	If pItem <> Undefined Then
		SelListMode = pItem.Value;
		If SelListMode > 0 Then
			SelPassedDays = 0;
		EndIf;
		ChangeFilter();
	EndIf;
EndProcedure // ChangeListMode

// -----------------------------------------------------------------------------
&AtServer
Procedure DisposeAtServer()
	vSelRows = Items.List.SelectedRows; 
	For Each vRowKey In vSelRows Do
		If Not vRowKey.IsEmpty() Then
			vRcrdMgr = InformationRegisters.LostAndFound.CreateRecordManager();
			FillPropertyValues(vRcrdMgr, vRowKey);
			vRcrdMgr.Read();
			If vRcrdMgr.Selected() And vRcrdMgr.IsDisposaled = False Then 
				If vRcrdMgr.IsReturned Then               
					vMsg = NStr("en = 'Item %1 №%2 has already been returned, it cannot be disposed of.'; 
									  |de = 'Das Objekt %1 Nr. %2 wurde bereits zurückgegeben, es kann nicht entsorgt werden.'; 
									  |ru = 'Вещь %1 №%2 уже вернули, ее нельзя утилизировать.'");
					vMsg = StrTemplate(vMsg, vRcrdMgr.Remarks, vRcrdMgr.Code); 
					tcCommonFunctionOnClientServer.UserMessage(vMsg);
					Continue;
				EndIf;	
				vRcrdMgr.IsDisposaled = True;    
				vRcrdMgr.DisposedDate = CurrentSessionDate();
				vRcrdMgr.DisposedBy = SessionParameters.CurrentUser;  
				vRcrdMgr.Write(True);
			EndIf;	
		EndIf;	
	EndDo;
EndProcedure

#EndRegion
