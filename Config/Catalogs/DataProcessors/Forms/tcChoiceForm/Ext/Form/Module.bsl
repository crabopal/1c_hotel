// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure ListOnGetDataAtServer(pItemName, pSettings, pRows)
	For Each vRow In pRows Do
		vRow.Value.Data.Description = cmNStr(vRow.Value.Data.Description, SessionParameters.CurrentLanguage);
	EndDo;
EndProcedure // ListOnGetDataAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure TreeOnGetDataAtServer(pItemName, pSettings, pRows)
	For Each vRow In pRows Do
		vRow.Value.Data.Description = cmNStr(vRow.Value.Data.Description, SessionParameters.CurrentLanguage);
	EndDo;
EndProcedure // TreeOnGetDataAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Filter.Property("Hotel") Then		
		vArray = New Array;
		vArray.Add(SessionParameters.CurrentHotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel", vArray);
	EndIf;	
EndProcedure // OnCreateAtServer
