
#Region Form_events

&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	
	UpdateItemsVisibility();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(pCurrentObject)
	
	vValueTree = pCurrentObject.LoadRuleTreeStorage.Get();
	If vValueTree <> Undefined Then
		ValueToFormAttribute(vValueTree, "LoadRuleTree");
	EndIf;
	
	vValueTree = pCurrentObject.UploadRuleTreeStorage.Get();
	If vValueTree <> Undefined Then
		ValueToFormAttribute(vValueTree, "UploadRuleTree");
	EndIf;
	
	vValueTree = Undefined;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	
	ValueTree 								= FormAttributeToValue("LoadRuleTree"); 
	pCurrentObject.LoadRuleTreeStorage 		= New ValueStorage(ValueTree);
	
	ValueTree 								= FormAttributeToValue("UploadRuleTree"); 
	pCurrentObject.UploadRuleTreeStorage 	= New ValueStorage(ValueTree);
	
EndProcedure

#EndRegion

#Region Form_items_events

&AtClient
Procedure ReadFromFile(pCommand)
	
	If ValueIsFilled(FilePath) Then
		vTextReader = New TextReader(FilePath);
		Text		= vTextReader.Read();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConvertToTree(pCommand)
	
	ConvertToTree_AtServer();
	
EndProcedure

&AtServer
Procedure ConvertToTree_AtServer()
	
	If NOT IsBlankString(Text) Then
		vValueTree = Catalogs.DataConvertationRules.JSONtoValueTree(Text, SetDefaultParameters);
		ValueToFormAttribute(vValueTree, "LoadRuleTree");
		
		CurrentItem = Items.Page_RuleTree;
	EndIf;
	
EndProcedure

&AtClient
Procedure ConvertToText(pCommand)
	
	ConvertToText_AtServer();
	
EndProcedure

&AtServer
Procedure ConvertToText_AtServer()
	
	vParams 		= GetTestDataStructure();
	Text 			= Catalogs.DataConvertationRules.ValueTreeToJSON(Object.Ref, vParams);
	
	CurrentItem = Items.Page_Text;
	
EndProcedure

&AtClient
Procedure FilePathStartChoice(pItem, pChoiceData, pStandardProcessing)

	vFileDialog 				= New FileDialog(FileDialogMode.Open);
	vFileDialog.Filter 			= "JSON file(*.json)|*.json";
	vFileDialog.Multiselect 	= False;
	vFileDialog.Show(New NotifyDescription("AfterFileChoice", ThisForm));
	
EndProcedure

&AtClient
Procedure AfterFileChoice(pResult, pParams) Export
	
	If pResult = Undefined Then
		Return;
	EndIf;
	
	FilePath = pResult[0];
	
EndProcedure

&AtClient
Procedure ConvertationTypeOnChange(pItem)
	
	UpdateItemsVisibility();
	
EndProcedure

&AtClient
Procedure LoadRuleTree_AddArray(pCommand)
	
	If Items.LoadRuleTree.CurrentRow <> Undefined Then
		
		vCurrentTreeRow = LoadRuleTree.FindByID(Items.LoadRuleTree.CurrentRow);
		If vCurrentTreeRow.KeyType = PredefinedValue("Enum.JSONKeyTypes.Array") OR vCurrentTreeRow.KeyType = PredefinedValue("Enum.JSONKeyTypes.FixedArray") Then
			Return;
		EndIf;
		vTreeRows = vCurrentTreeRow.GetItems();
		
	Else
		
		vTreeRows = LoadRuleTree.GetItems();
		
	EndIf;
	
	vNewRow 		= vTreeRows.Add();
	vNewRow.KeyType = PredefinedValue("Enum.JSONKeyTypes.FixedArray");
	
EndProcedure


&AtClient
Procedure LoadRuleTree_AddStructure(pCommand)
	
	If Items.LoadRuleTree.CurrentRow <> Undefined Then
		
		vCurrentTreeRow = LoadRuleTree.FindByID(Items.LoadRuleTree.CurrentRow);
		If vCurrentTreeRow.KeyType = PredefinedValue("Enum.JSONKeyTypes.Array") OR vCurrentTreeRow.KeyType = PredefinedValue("Enum.JSONKeyTypes.FixedArray") Then
			Return;
		EndIf;
		vTreeRows = vCurrentTreeRow.GetItems();
		
	Else
		
		vTreeRows = LoadRuleTree.GetItems();
		
	EndIf;
	
	vNewRow 		= vTreeRows.Add();
	vNewRow.KeyType = PredefinedValue("Enum.JSONKeyTypes.Structure");

EndProcedure


&AtClient
Procedure LoadRuleTree_AddValue(pCommand)
	
	vPredefinedValue 	= "Enum.JSONKeyTypes.String";
	vKey				= "";
	
	If Items.LoadRuleTree.CurrentRow <> Undefined Then
		
		vCurrentTreeRow = LoadRuleTree.FindByID(Items.LoadRuleTree.CurrentRow);
		If vCurrentTreeRow.KeyType = PredefinedValue("Enum.JSONKeyTypes.String") Then
			Return;
		ElsIf vCurrentTreeRow.KeyType = PredefinedValue("Enum.JSONKeyTypes.Array") Then
			If vCurrentTreeRow.GetItems().Count() > 0 Then
				Return;
			EndIf;
			vPredefinedValue 	= "Enum.JSONKeyTypes.ArrayElement";
			vKey				= vCurrentTreeRow.GetItems().Count();
		ElsIf vCurrentTreeRow.KeyType = PredefinedValue("Enum.JSONKeyTypes.FixedArray") Then
			vPredefinedValue 	= "Enum.JSONKeyTypes.ArrayElement";
			vKey				= vCurrentTreeRow.GetItems().Count();
		EndIf;
		

		vTreeRows = vCurrentTreeRow.GetItems();
		
	Else
		
		vTreeRows = LoadRuleTree.GetItems();
		
	EndIf;
	
	vNewRow 		= vTreeRows.Add();
	vNewRow.Key		= vKey;
	vNewRow.KeyType = PredefinedValue(vPredefinedValue);

EndProcedure


&AtClient
Procedure LoadRuleTree_Delete(pCommand)
	
	If Items.LoadRuleTree.CurrentRow <> Undefined Then
		
		vNeedRecount 	= False;
		vCurrentRow 	= LoadRuleTree.FindByID(Items.LoadRuleTree.CurrentRow);
		vParent 		= vCurrentRow.GetParent();
		If vParent = Undefined Then
			vParentElements = LoadRuleTree.GetItems();
			If vCurrentRow.KeyType = PredefinedValue("Enum.JSONKeyTypes.ArrayElement") Then
				vNeedRecount = True;
			EndIf;
		Else
			vParentElements = vParent.GetItems();	
		EndIf;
		vParentElements.Delete(vCurrentRow);
		
		If vNeedRecount Then
			RecountArrayElements(vParent);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadRuleTreeKeyTypeChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	
	If Items.LoadRuleTree.CurrentRow <> Undefined Then
		
		vCurrentTreeRow = LoadRuleTree.FindByID(Items.LoadRuleTree.CurrentRow);
		If pSelectedValue = PredefinedValue("Enum.JSONKeyTypes.Array") Then
			vTreeRows 		= vCurrentTreeRow.GetItems();
			vFirstRow 		= True;
			vDeleteArray 	= New Array;
			
			For each vArrayElement in  vTreeRows Do
				If vFirstRow Then
					vFirstRow = False;
					Continue;
				EndIf;
				vDeleteArray.Add(vArrayElement);				
			EndDo;
			
			For each vRow in vDeleteArray Do
				vTreeRows.Delete(vRow);	
			EndDo;
			
			RecountArrayElements(vCurrentTreeRow);
		EndIf;
	
	EndIf;

EndProcedure

#EndRegion


&AtClient
Procedure RecountArrayElements(pTreeRow)
	
	vTreeRows = pTreeRow.GetItems();
	i = 0;
	For each vArrayElement in vTreeRows Do
		vArrayElement.Key 	= i;
		i 					= i + 1;
	EndDo;
	
EndProcedure

&AtServer
Function GetTestDataStructure()
	
	vResult = Undefined;
	
	If NOT IsBlankString(FunctionTestData) Then
		
		SetSafeMode(True);
		vResult = Eval(FunctionTestData);
		SetSafeMode(False);
		
	Else
		vResult = New Structure;
		For each vRow in TestData Do
			vParamValue = Catalogs.DataConvertationRules.GetTreeRowValue(vRow, Undefined, vRow.ValueCalculatingRule, Undefined);
			vResult.Insert(vRow.Key, vParamValue); 
		EndDo;
	EndIf;
	
	Return vResult;
	
EndFunction

&AtServer
Procedure UpdateItemsVisibility()
	
	If Object.ConvertationType = Enums.DataConvertationTypes.JSONLoad Then
		
		Items.Pages_Settings.Visible 	= True;
		Items.UploadRuleTree.Visible 	= False;
		Items.LoadRuleTree.Visible 		= True;
		
	ElsIf Object.ConvertationType = Enums.DataConvertationTypes.JSONUpload Then
		
		Items.Pages_Settings.Visible 	= True;
		Items.UploadRuleTree.Visible 	= True;
		Items.LoadRuleTree.Visible 		= True;
		
	Else
		
		Items.Pages_Settings.Visible = False;
		
	EndIf;
	
EndProcedure


