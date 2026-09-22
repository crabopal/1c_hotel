
#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure UseAPDEXOnChange(Item)
	If ConstantsSet.UseAPDEX Then
		APDEXLoadCall();
	EndIf;
EndProcedure

#EndRegion    

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure APDEXLoadCall()
	APDEXPerformanceSystemFullRights.FillAPDEXKeyOperation();	
EndProcedure

#EndRegion    
