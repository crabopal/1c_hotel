
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pReplacing)
	If DataExchange.Load Then
		Return;
	EndIf;
	For Each vRecRow In ThisObject Do
		If Not ValueIsFilled(vRecRow.Author) Then
			vRecRow.Author = SessionParameters.CurrentUser;
		EndIf;
		vFileExtension = lower(Right(TrimAll(vRecRow.FileName), 4));
		If vFileExtension = ".jpg" Or vFileExtension = ".jpeg" Then
			vRecRow.ExtFilePreview = vRecRow.ExtFile;
		ElsIf vFileExtension = ".pdf" Then
			vPath = cmConvertPDFtoJPG(vRecRow.ExtFile, vRecRow.FileName);
			If vPath <> Undefined Then
				vBinary = GetFromTempStorage(vPath);
				vRecRow.ExtFilePreview = New ValueStorage(vBinary);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // BeforeWrite

#EndRegion
