
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("CatalogRef.Services") Then
		If tcOnServer.cmGetAttributeByRef(pSelectedValue,"IsFolder") Then
			FillServiceByGroup(pSelectedValue);
		Else	
			If Object.ServicesAllowed.FindRows(New Structure("Service",pSelectedValue)).Count()=0 Then
				vNewRow = Object.ServicesAllowed.Add();
				vNewRow.Service = pSelectedValue;
			EndIf;
		EndIf;
	EndIf;	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectServices(Command)
	// APDEX
	vKeyOperation = "Catalog.Services.Form.tcChoiceForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

	OpenForm("Catalog.Services.Form.tcChoiceForm", New Structure("CloseOnChoice", False), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChooseFolderServices(Command)
	OpenForm("Catalog.Services.Form.tcGroupChoiceForm", New Structure("CloseOnChoice", True), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillServiceByGroup(pServiceGroup)
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Services.Ref AS Ref
		|FROM
		|	Catalog.Services AS Services
		|WHERE
		|	Services.DeletionMark = FALSE
		|	AND Services.Parent IN HIERARCHY(&qParent)
		|	AND Services.IsFolder = FALSE";
	
	Query.SetParameter("qParent", pServiceGroup);
	
	QueryResult = Query.Execute();
	
	vRes = QueryResult.Select();
	
	While vRes.Next() Do
		vNewRow = Object.ServicesAllowed.Add();
		vNewRow.Service = vRes.Ref;
	EndDo;
	// GroupBy rows
	vTab = Object.ServicesAllowed.Unload();
	vTab.GroupBy("Service");
	Object.ServicesAllowed.Load(vTab);
EndProcedure

#EndRegion


	