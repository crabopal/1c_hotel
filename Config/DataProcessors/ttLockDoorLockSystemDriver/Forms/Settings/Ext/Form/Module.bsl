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
		Obj.ExternalInteraction = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	LoadInteractionParameters();
	LoadRoomsList();
	LoadRoomsListMapping();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DebugOnChange(pItem)
	If Debug Then
		Active = True;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActiveOnChange(pItem)
	If NOT Active Then
		Debug = False;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure // Save

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateAccessToken(pCommand)
	UpdateAccessTokenAtServer();	
EndProcedure // UpdateAccessToken

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectAllKeyCard(pCommand)
	For Each vRow In RoomsList Do
		vRow.UseKeyCard = True;
	EndDo;
EndProcedure // SelectAllKeyCard

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectAllPassCode(pCommand)
	For Each vRow In RoomsList Do
		vRow.UsePassCode = True;
	EndDo;
EndProcedure // SelectAllPassCode

// -----------------------------------------------------------------------------
&AtClient
Procedure UnSelectAllKeyCard(pCommand)
	For Each vRow In RoomsList Do
		vRow.UseKeyCard = False;
	EndDo;
EndProcedure // UnSelectAllKeyCard

// -----------------------------------------------------------------------------
&AtClient
Procedure UnSelectAllPassCode(pCommand)
	For Each vRow In RoomsList Do
		vRow.UsePassCode = False;
	EndDo;
EndProcedure // UnSelectAllPassCode

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	
	If NOT CheckFilling() Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		SaveInteractionParameters();
		SaveRoomsListMapping();
		
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		
		Obj.pmSaveDataProcessorAttributes();
		CommitTransaction();
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage("Failed to save:" + vError);
		RollbackTransaction();
	EndTry;	
EndProcedure // Save_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If NOT ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
	
	vIntParObj						= Object.ExternalInteraction.GetObject();
	vIntParObj.IsActive				= Active;
	vIntParObj.Hotel				= Hotel;
	vIntParObj.DebugMode			= Debug;
	vIntParObj.OAuth_ClientID		= OAuth_ClientID;
	vIntParObj.OAuth_ClientSecret	= OAuth_ClientSecret;
	vIntParObj.OAuth_AccessToken	= OAuth_AccessToken;
	vIntParObj.OAuth_RefreshToken	= OAuth_RefreshToken; 
	vIntParObj.Login				= Login;
	vIntParObj.Password				= Password;
	vIntParObj.HttpServer			= HttpServer;
	vIntParObj.HttpUseSsl			= HttpUseSsl;
	vIntParObj.MaxLogLenght			= MaxLogLenght;
	vIntParObj.Write();
EndProcedure // SaveInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	
	If NOT ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
	
	Hotel				= Object.ExternalInteraction.Hotel;
	Active				= Object.ExternalInteraction.IsActive;
	Debug				= Object.ExternalInteraction.DebugMode;
	OAuth_ClientID		= Object.ExternalInteraction.OAuth_ClientID;
	OAuth_ClientSecret	= Object.ExternalInteraction.OAuth_ClientSecret;
	OAuth_AccessToken	= Object.ExternalInteraction.OAuth_AccessToken;
	OAuth_RefreshToken	= Object.ExternalInteraction.OAuth_RefreshToken;
	Login				= Object.ExternalInteraction.Login;
	Password			= Object.ExternalInteraction.Password;
	HttpServer			= Object.ExternalInteraction.HttpServer;
	HttpUseSsl			= Object.ExternalInteraction.HttpUseSsl;
	MaxLogLenght		= Object.ExternalInteraction.MaxLogLenght;    
	ActiveToDate		= Object.ExternalInteraction.SessionStartTime + Object.ExternalInteraction.SessionTimeout;
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateAccessTokenAtServer()
	Obj = FormAttributeToValue("Object");
	vMessage = "";
	If Obj.CheckAuth_AccessToken(CurrentSessionDate(), vMessage) Then 
		LoadInteractionParameters();
	Else
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // UpdateAccessToken

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadRoomsList()
	RoomsList.Clear();
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	Rooms.Ref AS Room
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND Rooms.Owner = &qHotel
	|
	|ORDER BY
	|	Rooms.SortCode";
	vQ.SetParameter("qHotel", Hotel);
	
	vSelect = vQ.Execute().Select();
	While vSelect.Next() Do
		vNewRow = RoomsList.Add();
		FillPropertyValues(vNewRow, vSelect);
	EndDo;
EndProcedure // LoadRoomsList

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadRoomsListMapping()
	
	vRooms = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.ExternalInteraction, "rooms");
	
	Try
		For Each vRoomRow In vRooms Do
			vRoomListArr = RoomsList.FindRows(New Structure("Room", vRoomRow.RefKey1));
			If vRoomListArr.Count() <= 0 Then
				Continue;
			EndIf;
			
			vRoomListArr[0].Building = vRoomRow.Building;
			vRoomListArr[0].Floor = vRoomRow.Floor;
			vRoomListArr[0].Mac = vRoomRow.Mac;
			vRoomListArr[0].UsePassCode = vRoomRow.UsePassCode;
			vRoomListArr[0].UseKeyCard = vRoomRow.UseKeyCard;
		EndDo;
		
	Except
		tcCommonFunctionOnClientServer.TextMessage("Failed to load room mappings!");
	EndTry;
	
EndProcedure // LoadRoomsListMapping

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveRoomsListMapping()
	vDataType = "rooms";
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.ExternalInteraction, vDataType);
	
	For Each vRoomRow In RoomsList Do
		If ValueIsFilled(vRoomRow.Room) Then
			vRoomUUID = TrimAll(vRoomRow.Room.UUID());
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.ExternalInteraction, vDataType, "Building",			vRoomRow.Room, Undefined, vRoomRow.Building,		vRoomUUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.ExternalInteraction, vDataType, "Floor",				vRoomRow.Room, Undefined, vRoomRow.Floor,			vRoomUUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.ExternalInteraction, vDataType, "Mac",				vRoomRow.Room, Undefined, vRoomRow.Mac,			vRoomUUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.ExternalInteraction, vDataType, "UsePassCode",		vRoomRow.Room, Undefined, vRoomRow.UsePassCode,	vRoomUUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.ExternalInteraction, vDataType, "UseKeyCard",		vRoomRow.Room, Undefined, vRoomRow.UseKeyCard,	vRoomUUID);
		EndIf;
	EndDo;
EndProcedure // LoadRoomsListMapping

#EndRegion
