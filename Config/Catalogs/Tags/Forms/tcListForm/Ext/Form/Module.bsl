
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
		EndIf;
	EndDo;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure

#EndRegion
