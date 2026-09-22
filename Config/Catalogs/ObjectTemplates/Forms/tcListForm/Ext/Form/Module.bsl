// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Not Parameters.Filter.Property("Hotel") Then		
		vArray = New Array;
		vArray.Add(SessionParameters.CurrentHotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel", vArray);
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure ListOnGetDataAtServer(pItemName, pSettings, pRows)
	// Colors and other appearances
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		vTypeAppearance = vRowValue.Appearance.Get("ObjectType");
		If vTypeAppearance <> Undefined Then
			vTypeText = String(TypeOf(vRowValue.Data.ObjectType));
			vTypeAppearance.SetParameterValue("Text", vTypeText);
		EndIf;
	EndDo;
EndProcedure // ListOnGetDataAtServer
