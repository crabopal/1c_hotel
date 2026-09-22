
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel, pReplacing)
	If DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite

Procedure BeforeWrite(pCancel, pReplacing)
	If DataExchange.Load Then
		Return;
	EndIf;  
	
	vChanges = New Array;
	// Check delete or change record  
	If ThisObject.Count() = 0 Then      
		vCode = ThisObject.Filter.Code.Value;
		If ValueIsFilled(vCode) Then
			If cmCheckUserPermissions("HavePermissionToForbiddenChangeLostAndFound") Then 
				pCancel = True;                                   
				vErrMsg = NStr("en = 'No permission to change and delete lost item records (152)'; 
							   |de = 'Keine Berechtigung zum Ändern und Löschen von Datensätzen zu verlorenen Gegenständen (152)'; 
							   |ru = 'Нет прав на изменение и удаление записей о потерянных вещах (152)'");
				tcCommonFunctionOnClientServer.UserMessage(vErrMsg);     
				Return;
			EndIf;	
			// It`s delete row  
			vChanges.Add(NStr("en = 'Lost and found, Deleting an entry:'; de = 'Verlorene Sachen, Eintrag löschen:'; ru = 'Потерянные вещи, удаление записи:'"));   
			
			vChanges.Add(StrTemplate(NStr("en = 'Code: %1'; de = 'Code: %1'; ru = 'Код записи: %1'"), vCode));                                             
			vChanges.Add(StrTemplate(NStr("en = 'Date when found: %1'; de = 'Datum der Entdeckung: %1'; ru = 'Дата обнаружения: %1'"), ThisObject.Filter.DateWhenFound.Value));	
			vChanges.Add(StrTemplate(NStr("en = 'Room: %1'; de = 'Room: %1'; ru = 'Комната: %1'"), ThisObject.Filter.Room.Value));
			vChanges.Add(StrTemplate(NStr("en = 'Guest: %1'; de = 'Gast: %1'; ru = 'Гость: %1'"), ThisObject.Filter.Guest.Value));
		EndIf;  
	Else   
		If IsChangeRow() And cmCheckUserPermissions("HavePermissionToForbiddenChangeLostAndFound") Then 
			pCancel = True;                                   
			vErrMsg = NStr("en = 'No permission to change and delete lost item records (152)'; 
						   |de = 'Keine Berechtigung zum Ändern und Löschen von Datensätzen zu verlorenen Gegenständen (152)'; 
						   |ru = 'Нет прав на изменение и удаление записей о потерянных вещах (152)'");			
			tcCommonFunctionOnClientServer.UserMessage(vErrMsg);     
			Return;
		EndIf;
		// It`s change row  
		vChanges.Add(NStr("en = 'Lost and found, change an entry:'; de = 'Fundbüro, Eintrag ändern:'; ru = 'Потерянные вещи, изменение записи:'"));      
		For Each vRcd In ThisObject Do                                             
			vChanges.Add(StrTemplate(NStr("en = 'What found: %1'; de = 'Was gefunden: %1'; ru = 'Что найдено: %1'"), vRcd.Remarks));
			vChanges.Add(StrTemplate(NStr("en = 'Date when found: %1'; de = 'Datum der Entdeckung: %1'; ru = 'Дата обнаружения: %1'"), vRcd.DateWhenFound));	
			vChanges.Add(StrTemplate(NStr("en = 'Store place: %1'; de = 'Speicherort: %1'; ru = 'Место хранения: %1'"), vRcd.StorePlace));
			vChanges.Add(StrTemplate(NStr("en = 'Room: %1'; de = 'Room: %1'; ru = 'Комната: %1'"), vRcd.Room));
			vChanges.Add(StrTemplate(NStr("en = 'Guest: %1'; de = 'Gast: %1'; ru = 'Гость: %1'"), vRcd.Guest));
			vChanges.Add(StrTemplate(NStr("en = 'Code: %1'; de = 'Code: %1'; ru = 'Код записи: %1'"), vRcd.Code));	
			vChanges.Add(StrTemplate(NStr("en = 'Is returned: %1'; de = 'Zurückgegeben: %1'; ru = 'Возвращено: %1'"), vRcd.IsReturned));	
		EndDo;
	EndIf;    
	If vChanges.Count() > 0 Then
		vChangesRow = StrConcat(vChanges, Chars.LF);   
		// User activity history
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(SessionParameters.CurrentUser, vChangesRow, SessionParameters.CurrentHotel, SessionParameters.CurrentUser, CurrentSessionDate());	
	EndIf;	
EndProcedure

#EndRegion

#Region Private
	
//-----------------------------------------------------------------------------	
Function IsChangeRow()
	vRcrd = InformationRegisters.LostAndFound.CreateRecordManager();
	vRcrd.Code = ThisObject.Filter.Code.Value;
	vRcrd.Room = ThisObject.Filter.Room.Value;  
	vRcrd.Guest = ThisObject.Filter.Guest.Value; 
	vRcrd.Author = ThisObject.Filter.Author.Value;
	vRcrd.CreateDate = ThisObject.Filter.CreateDate.Value;
	vRcrd.Hotel = ThisObject.Filter.Hotel.Value;     
	vRcrd.DateWhenFound = ThisObject.Filter.DateWhenFound.Value;
	
	vRcrd.Read();
	
	vRes = vRcrd.Selected();
	Return vRes;
EndFunction	

#EndRegion   
	