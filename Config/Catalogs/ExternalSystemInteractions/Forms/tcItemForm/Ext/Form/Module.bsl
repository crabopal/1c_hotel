
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If	Object.IntegrationType = Enums.Integrations.ExternalLogSystem Then
		Items.DebugMode.Visible = False;
		Items.MaxLogLenght.Visible = False;
	EndIf;
	If Not ValueIsFilled(Object.IntegrationType) And Not ValueIsFilled(Object.Hotel) Then
		Object.Hotel = SessionParameters.CurrentHotel;
	EndIf;
	IsNew = Object.Ref.IsEmpty();
	RefreshDisplay();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If IsBlankString(Object.Code) Then
		  Message = New UserMessage;
		  Message.Text = Nstr("en = 'You must fill in the code'; de = 'Sie müssen den Code eingeben'; ru = 'Необходимо заполнить код'");
		  Message.Field = "Object.Code";
		  Message.Message();
		  pCancel = True;
	EndIf;	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure IntegrationTypeOnChange(pItem)
	RefreshDisplay();
	CheckIntegType();
	If ValueIsFilled(Object.IntegrationType) And IsBlankString(Object.Description) Then
		Object.Description = Object.IntegrationType;
	EndIf;
	
EndProcedure // IntegrationTypeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandSettings(Command)
	If ThisForm.Modified Then
		If Not ThisForm.Write() Then
			Return;
		EndIf;
	EndIf;
	vFormName = "";
	If CommandSettingsOnServer(Object.Ref, vFormName) Then
		ThisObject.Read();
		If StrStartsWith(vFormName, "DataProcessor") Then
			vParams = New Structure("InteractionParameters", Object.Ref);
		Else
			vParams = New Structure("Key", Object.Ref);
		EndIf;
		If ValueIsFilled(Object.DataProcessor) Then
			vParams.Insert("DataProcessor", Object.DataProcessor);
			If tcOnServer.cmGetAttributeByRef(Object.DataProcessor, "IsExternal") Then
				vFormName = GetNameDataProcessor(Object.DataProcessor);
			EndIf;
		EndIf;	
		OpenForm(vFormName, vParams, ThisForm.FormOwner);
	Else
		ShowMessageBox(, NStr("en='Integration type has to be filled!'; ru='Не заполнен тип интеграции!'; de='Integrationtyp ist nicht gefüllt!'"));
		Return;
	EndIf;
	Close();
EndProcedure // CommandSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure GenerateToken(pCommand)
	Object.InteractionID = String(New UUID);
	ThisObject.Modified = True;
EndProcedure // GenerateToken

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetNameDataProcessor(pDataProcessor)
	Return Catalogs.DataProcessors.GetNameDataProcessorByProcessing(pDataProcessor);	
EndFunction //  GetNameDataProcessor

// --------------------------------------------------------------------------------
&AtServer
Procedure CheckIntegType()
	If	Object.IntegrationType = Enums.Integrations.ExternalLogSystem Then
		Items.DebugMode.Visible = False;
		Items.MaxLogLenght.Visible = False;
	Else
		Items.DebugMode.Visible = True;
		Items.MaxLogLenght.Visible = True;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function CommandSettingsOnServer(pObjectRef, pFormName)
	Return Catalogs.ExternalSystemInteractions.GetObjetForm(pObjectRef, pFormName, IsNew);
EndFunction	

// --------------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	If Object.IntegrationType = PredefinedValue("Enum.Integrations.Roscongress") Then
		If IsBlankString(Object.InteractionID) Then
			Object.InteractionID = "Roscongress";
			ThisForm.Modified = True;
		EndIf;
		If IsBlankString(Object.Code) Then
			Object.Code = "Roscongress";
			ThisForm.Modified = True;
		EndIf;
		If IsBlankString(Object.Description) Then
			Object.Description = "Roscongress";
			ThisForm.Modified = True;
		EndIf;
		If IsBlankString(Object.WSHost) Then
			Object.WSHost = "booking.forumvostok.ru";
			ThisForm.Modified = True;
		EndIf;
	EndIf;
	
EndProcedure // RefreshDisplay

#EndRegion