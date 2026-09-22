
#Region FormEventHandlers
// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure ListOnGetDataAtServer(ItemName, Settings, Rows)
	For Each vRow In Rows Do
		vColor = tcCommonFunctionOnClientServer.cmGetColorFromValueStorage(vRow.Key);
		If vColor <> Undefined Then
			// Code
			vCodeAppearance = vRow.Value.Appearance.Get("Code");
			vCodeAppearance.SetParameterValue("BackColor", vColor);
			// Description
			vCodeDescription = vRow.Value.Appearance.Get("Description");
			vCodeDescription.SetParameterValue("BackColor", vColor);
		EndIf;
	EndDo;	
EndProcedure

#EndRegion
