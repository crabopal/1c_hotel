#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("ChoiceMode") and Parameters.ChoiceMode Then
		Items.List.ChoiceMode = True;
		Items.Tree.ChoiceMode = True;
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "MergeAnyRefs.Change" Then
		Items.List.Refresh();
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionMergeSources(pCommand)
	vCurRow = Items.List.CurrentRow;
	If vCurRow = Undefined Then
		ShowMessageBox(,NStr("en = 'Choose at least one sources first!'; de = 'Wählen Sie zuerst mindestens einen Quelle!'; ru = 'Выберите как минимум один источник!'"));
		Return;
	EndIf;
	If tcOnServer.cmGetAttributeByRef(vCurRow, "IsFolder") Then
		ShowMessageBox(,NStr("en = 'Do not choose source folders!'; de = 'Wählen Sie keine Quelleordner!'; ru = 'Нельзя выбирать группу источников!'"));
		Return;
	EndIf;
	vParam = new Structure();
	vParam.Insert("SelDefaultTypeDescription", New TypeDescription("CatalogRef.SourcesOfBusiness"));
	vParam.Insert("SelMergedRef", vCurRow);
	If Items.List.SelectedRows.Count() > 1 Then
		vFirstSelRow = Items.List.SelectedRows.Get(0);
		If Not tcOnServer.cmGetAttributeByRef(vFirstSelRow, "IsFolder") Then
			vParam.Insert("SelMergedRef", vFirstSelRow);
		EndIf;
		vLastSelRow = Items.List.SelectedRows.Get(Items.List.SelectedRows.Count() - 1);
		If Not tcOnServer.cmGetAttributeByRef(vLastSelRow, "IsFolder") And vLastSelRow <> vFirstSelRow Then
			vParam.Insert("SelMainRef", vLastSelRow);
		EndIf;
	EndIf;
	OpenForm("DataProcessor.MergeAnyRefs.Form", vParam, ThisForm, UUID);
EndProcedure // ActionMergeSources

#EndRegion

