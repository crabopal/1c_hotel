
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Release date
	ProgramVersionDate = "N/A";
	vReleaseDateStr = cmGetProgramVersionAsDateString();
	If Not IsBlankString(vReleaseDateStr) And StrLen(vReleaseDateStr) = 6 Then
		ProgramVersionDate = Right(vReleaseDateStr, 2) + "-" + Mid(vReleaseDateStr, 3, 2) + "-20" + Left(vReleaseDateStr, 2);
	EndIf;
	// Fill time zones list
	vZonesArray = GetAvailableTimeZones();
	For Each vTimeZone In vZonesArray Do
		vTimeZonePresentation = TimeZonePresentation(vTimeZone);
		Items.InfoBaseTimeZone.ChoiceList.Add(TrimAll(vTimeZone), TrimAll(vTimeZone) + ?(IsBlankString(vTimeZonePresentation), "", " - " + vTimeZonePresentation));
	EndDo;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	RefreshReusableValues();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure EditableFileExtensionsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	ConstantsSet.EditableFileExtensions = "xls, xlsx, doc, docx, txt, rtf, odt, odf, eml";
EndProcedure // EditableFileExtensionsOpening

// --------------------------------------------------------------------------------
&AtServer
Procedure SetPreviousVersionAtServer()
	vPreviousVersion = TrimAll(Constants.PreviousProgramVersionNumber.Get());
	If IsBlankString(vPreviousVersion) Then
		vPreviousVersion = "9.0.4.4";
	EndIf;
	Constants.ProgramVersionNumber.Set(vPreviousVersion);
	ProgramVersionDate = "";
EndProcedure // SetPreviousVersionAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure SetPreviousVersion(pCommand)
	ShowQueryBox(New NotifyDescription("SetPreviousVersionConfirmation", ThisForm), 
	             NStr("en='Program will be forcibly	 restarted! Agree?'; ru='Программа будет принудительно перезапущена! Согласны?'; de='Programm wird zwangsweise neu gestartet! Einverstanden?'"),
				 QuestionDialogMode.YesNo, , 
				 DialogReturnCode.No);
EndProcedure // SetPreviousVersion

// --------------------------------------------------------------------------------
&AtClient
Procedure SetPreviousVersionConfirmation(pRetCode, pExtraParams) Export
	If pRetCode = DialogReturnCode.Yes Then
		SetPreviousVersionAtServer();
		Exit(False, True);
	EndIf;
EndProcedure // SetPreviousVersionConfirmation

#EndRegion
