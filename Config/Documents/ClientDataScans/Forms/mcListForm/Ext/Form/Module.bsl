
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Filter.Property("Hotel") Then		
		vArray = New Array;
		vArray.Add(SessionParameters.CurrentHotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel",vArray);
	EndIf;	
	SelFilter = 0;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	ChangeSelFilter();
EndProcedure // OnOpen

#EndRegion 

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFilterOnChange(pItem)
	ChangeSelFilter();
EndProcedure // SelFilterOnChange

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeSelFilter()
	vUse = True;
	If SelFilter = 0 Then
		vRightValue = PredefinedValue("Enum.ScanStatuses.IsNew");
	ElsIf SelFilter = 1 Then	
		vRightValue = PredefinedValue("Enum.ScanStatuses.IsRecognized");
	ElsIf SelFilter = 2 Then	
		vRightValue = PredefinedValue("Enum.ScanStatuses.IsProcessed");  
	Else
		vRightValue = Undefined;
		vUse = False;
	EndIf; 
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Status", vRightValue, , , vUse);
EndProcedure // ChangeSelFilter	

#EndRegion
