
#Region FormEventHandlers

// --------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Try
		InfoLink = Parameters.InfoLink;
	Except
		InfoLink = "";
	EndTry;
	Try
		PictureLink = Parameters.PictureLink;
	Except
		PictureLink = "";
	EndTry;
	Try
		RoomType = Parameters.RoomType;
	Except
		RoomType = "";
	EndTry;
	If ValueIsFilled(RoomType) Then
		Title = NStr("en='Information about the type of room: ';ru='Информация о типе номера: ';de='Zimmertypinformation: '") + String(RoomType);
	Else
		Title = NStr("en='Information';ru='Информация';de='Information'");
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If ValueIsFilled(PictureLink) Then
		vStorageAddress = "";
		
		BeginPutFile(New NotifyDescription("OnOpenEnd", ThisObject, New Structure("vStorageAddress", vStorageAddress)), vStorageAddress, PictureLink, False, UUID);
        Return;
	Else
		Items.PictureField.Visible = False;
	EndIf;
	OnOpenPart();
EndProcedure

#EndRegion

#Region Internal

// --------------------------------------------------------------------------
&AtClient
Procedure OnOpenEnd(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	vStorageAddress = AdditionalParameters.vStorageAddress;
	
	
	If Result Then
		vFileInTempStorage = vStorageAddress;
	EndIf;
	PictureField = vFileInTempStorage;
	
	OnOpenPart();

EndProcedure

// --------------------------------------------------------------------------
&AtClient
Procedure OnOpenPart()
	
	If ValueIsFilled(InfoLink) Then
		HTMLDocument = InfoLink;
	Else
		Items.HTMLDocument.Visible = False;
	EndIf;
	vRemarks = tcOnServer.cmGetAttributeByRef(RoomType, "Remarks");
	If ValueIsFilled(vRemarks) Then
		Remarks = vRemarks;
	ElsIf Not ValueIsFilled(InfoLink) Then
		Items.Remarks.Visible = False;
	Else
		Items.Remarks.Visible = True;
	EndIf;
	
EndProcedure

#EndRegion

