#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
		
	vParameters = Undefined;
	If Parameters.Property("ExtraParameters") And ValueIsFilled(TrimAll(Parameters.ExtraParameters)) Then
		vParameters = JSONToMap(TrimAll(Parameters.ExtraParameters));					
	EndIf; 
	
	vRoomInterfaceType = Catalogs.RoomInterfaceTypes.EmptyRef();
	If Parameters.Property("RoomInterfaceType", vRoomInterfaceType) Then
		RoomInterfaceType = vRoomInterfaceType;
	EndIf;
	
	vCreateRoomInterfaceTypes = False;
	If Parameters.Property("CreateRoomInterfaceTypes", vCreateRoomInterfaceTypes) Then
		CreateRoomInterfaceTypes = vCreateRoomInterfaceTypes;
	EndIf;
	
	FillCheckInChoiceList();
	FillTVRightsChoiceList();
	FillMinibarRightsChoiceList();
		
	If vParameters <> Undefined Then
		a0 = ?(vParameters["a0"] <> Undefined, vParameters["a0"], "");
		a1 = ?(vParameters["a1"] <> Undefined, vParameters["a1"], "");
		a2 = ?(vParameters["a2"] <> Undefined, vParameters["a2"], "");
		a3 = ?(vParameters["a3"] <> Undefined, vParameters["a3"], "");
		a4 = ?(vParameters["a4"] <> Undefined, vParameters["a4"], "");
		a5 = ?(vParameters["a5"] <> Undefined, vParameters["a5"], "");
		a6 = ?(vParameters["a6"] <> Undefined, vParameters["a6"], "");
		a7 = ?(vParameters["a7"] <> Undefined, vParameters["a7"], "");
		a8 = ?(vParameters["a8"] <> Undefined, vParameters["a8"], "");
		a9 = ?(vParameters["a9"] <> Undefined, vParameters["a9"], "");
		a9 = ?(vParameters["a9"] <> Undefined, vParameters["a9"], "");
		TVRights = ?(vParameters["TVRights"] <> Undefined, vParameters["TVRights"], ""); 
		MinibarRights = ?(vParameters["MinibarRights"] <> Undefined, vParameters["MinibarRights"], "");
		NoPost = ?(vParameters["NoPost"] <> Undefined, vParameters["NoPost"], "");
	Else
		SetDefaultParameters();	
	EndIf;
	RefreshDisplay();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Change(pCommand) 
	If CreateRoomInterfaceTypes Then
		vExtraParametersMap = New Map;
		
		If Items.GroupCheckIn.Visible Then
			vCheckInMap = New Map;
			vCheckInMap.Insert("a0", a0);
			vCheckInMap.Insert("a1", a1);
			vCheckInMap.Insert("a2", a2);
			vCheckInMap.Insert("a3", a3);
			vCheckInMap.Insert("a4", a4);
			vCheckInMap.Insert("a5", a5);
			vCheckInMap.Insert("a6", a6);
			vCheckInMap.Insert("a7", a7);
			vCheckInMap.Insert("a8", a8);
			vCheckInMap.Insert("a9", a9);
			vCheckInMap.Insert("NoPost", NoPost);
			vExtraParametersMap.Insert("CheckIn", MapToJSON(vCheckInMap));
		EndIf;
		If Items.GroupTV.Visible Then 
			vTVMap = New Map;
			vTVMap.Insert("TVRights", TVRights);
			vExtraParametersMap.Insert("TV", MapToJSON(vTVMap));
		EndIf;
		If Items.GroupMinibar.Visible Then   
			vMinibarMap = New Map;
			vMinibarMap.Insert("MinibarRights", MinibarRights);
			vExtraParametersMap.Insert("Minibar", MapToJSON(vMinibarMap));
		EndIf;

		Close(vExtraParametersMap);	
	Else
		vExtraParametersMap = New Map;
		
		If Items.GroupCheckIn.Visible Then
			vExtraParametersMap.Insert("a0", a0);
			vExtraParametersMap.Insert("a1", a1);
			vExtraParametersMap.Insert("a2", a2);
			vExtraParametersMap.Insert("a3", a3);
			vExtraParametersMap.Insert("a4", a4);
			vExtraParametersMap.Insert("a5", a5);
			vExtraParametersMap.Insert("a6", a6);
			vExtraParametersMap.Insert("a7", a7);
			vExtraParametersMap.Insert("a8", a8);
			vExtraParametersMap.Insert("a9", a9);
			vExtraParametersMap.Insert("NoPost", NoPost);
		EndIf;
		If Items.GroupTV.Visible Then
			vExtraParametersMap.Insert("TVRights", TVRights);
		EndIf;
		If Items.GroupMinibar.Visible Then
			vExtraParametersMap.Insert("MinibarRights", MinibarRights);	
		EndIf;

		Close(MapToJSON(vExtraParametersMap));
	EndIf;
EndProcedure // Change

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckInChoiceList()
	For vNumber = 0 To 9 Do
		Items["a" + Format(vNumber, "NFD=0; NZ=0; NG=")].ChoiceList.Add("Phone", NStr("en = 'Phone'; de = 'Telefon'; ru = 'Телефон'"));
		Items["a" + Format(vNumber, "NFD=0; NZ=0; NG=")].ChoiceList.Add("EMail", NStr("en = 'E-mail'; de = 'E-mail'; ru = 'E-mail'"));
	EndDo;
EndProcedure // FillCheckInChoiceList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTVRightsChoiceList()
	Items.TVRights.ChoiceList.Add("0", NStr("en = 'Full'; de = 'Full'; ru = 'Полный'"));
	Items.TVRights.ChoiceList.Add("1", NStr("en = 'No payable'; de = 'No payable'; ru = 'Без платных'"));
	Items.TVRights.ChoiceList.Add("2", NStr("en = 'No XXX'; de = 'No XXX'; ru = 'Без XXX'"));
	Items.TVRights.ChoiceList.Add("3", NStr("en = 'Unavailable'; de = 'Unavailable'; ru = 'Недоступен'"));
EndProcedure // FillCheckInChoiceList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillMinibarRightsChoiceList()
	Items.MinibarRights.ChoiceList.Add("0", NStr("en = 'Available'; ru = 'Доступен'; de = 'Available'"));
	Items.MinibarRights.ChoiceList.Add("1", NStr("en = 'Vending'; ru = 'Режим  торг. автомата'; de = 'Vending'"));
	Items.MinibarRights.ChoiceList.Add("2", NStr("en = 'Unavailable'; ru = 'Не доступен'; de = 'Unavailable'"));	
EndProcedure // FillCheckInChoiceList

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDefaultParameters()
	a0 = "";
	a1 = "";
	a2 = "";
	a3 = "";
	a4 = "";
	a5 = "";
	a6 = "";
	a7 = "";
	a8 = "";
	a9 = "";
	TVRights = "3";
	MinibarRights = "2";
	NoPost = False;
EndProcedure // SetDefaultParameters 

// -----------------------------------------------------------------------------
&AtClient
Function MapToJSON(pMap)
	#IF NOT WebClient Then
		Try
			vJSONWriter = New JSONWriter;
			vJSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
			WriteJSON(vJSONWriter, pMap);
			Return vJSONWriter.Close();	
		Except
			Return "";
		EndTry; 
	#ELSE
		Return "";	
	#ENDIF
EndFunction // MapToJSON

// -----------------------------------------------------------------------------
&AtServer
Function JSONToMap(pJSON)
	#IF NOT WebClient Then
		Try
			vJSONReader = New JSONReader();
			vJSONReader.SetString(pJSON);
			Return ReadJSON(vJSONReader, True);	
		Except
			Return Undefined;	
		EndTry;
	#ELSE
		Return Undefined;	
	#ENDIF
EndFunction // JSONToMap

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	If ValueIsFilled(RoomInterfaceType) Then
		If RoomInterfaceType.TurnOnParameters = "CheckIn" Then
			Items.GroupCheckIn.Visible = True;	
			Items.GroupTV.Visible = False;
			Items.GroupMinibar.Visible = False;
		ElsIf RoomInterfaceType.TurnOnParameters = "Rights_TV" Then
			Items.GroupTV.Visible = True;	
			Items.GroupCheckIn.Visible = False;	
			Items.GroupMinibar.Visible = False;	
		ElsIf RoomInterfaceType.TurnOnParameters = "Rights_Minibar" Then
			Items.GroupMinibar.Visible = True;	
			Items.GroupCheckIn.Visible = False;	
			Items.GroupTV.Visible = False;	
		EndIf;
	EndIf;
EndProcedure // RefreshDisplay

#EndRegion 
