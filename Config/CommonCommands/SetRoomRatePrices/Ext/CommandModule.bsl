#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vArray = New Array;
	vArray.Add(pCommandParameter);
	vArray.Add(GetParent(pCommandParameter));
	
	vFormParameters = New Structure("Filter", New Structure("RoomRate", vArray));
	OpenForm("Document.SetRoomRatePrices.Form.tcListForm", vFormParameters, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure // CommandProcessing

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer	
Function GetParent(pDoc)
	Return pDoc.Parent;	
EndFunction // GetParent

#EndRegion
