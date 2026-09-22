
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If not Parameters.Filter.Property("Hotel") Then		
		vArray = New Array;
		vArray.Add(SessionParameters.CurrentHotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel",vArray);
	EndIf;	
EndProcedure

#EndRegion 

#Region FormTableListItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	pCancel = True;
	tcCommonFunctionOnClientServer.TextMessage(NStr("en='It is not allowed to delete restriction records! Open record, clear restrictions and save to delete restrictions.';
	                                                |ru='Удаление записей с ограничениями запрещено! Для того чтобы удалить ограничения откройте запись, очистите ограничения и сохраните.';
													|de='Das Löschen von Datensätzen mit Einschränkungen ist verboten! Öffnen Sie den Eintrag, löschen Sie die Einschränkungen und speichern Sie.'"));
EndProcedure // ListBeforeDeleteRow

#EndRegion

