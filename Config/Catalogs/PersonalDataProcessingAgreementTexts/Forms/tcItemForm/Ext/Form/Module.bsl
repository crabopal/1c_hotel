
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;

	If ValueIsFilled(Object.Ref) Then
		If ThereArePersonalDataProcessingConsentDocuments() Then
			Items.AgreementText.ReadOnly = True;
			Items.ShortAgreementText.ReadOnly = True;
			Items.ConsentDuration.ReadOnly = True;
			Items.GroupClear.ReadOnly = True;
			WarningText = NStr("en='Edit the text of the agreement is prohibited, since there are customers who signed this version of the agreement!'; 
			                   |ru='Редактировать текст соглашения запрещено, так как есть клиенты, которые подписали эту версию соглашения!'; 
							   |de='Bearbeiten Sie den Text der Vereinbarung ist verboten, da es Kunden gibt, die diese Version der Vereinbarung unterzeichnet haben!'");
			Items.WarningText.Visible = True;
		EndIf;
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	AgreementText.Add(Object.AgreementText);
	ShortAgreementText.Add(Object.ShortAgreementText);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	pCurrentObject.AgreementText = AgreementText.GetText();
	pCurrentObject.ShortAgreementText = ShortAgreementText.GetText();
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If AttributeName = "AgreementText" Then
		AgreementText.Delete();
		AgreementText.Add(pSelectedValue);
	ElsIf AttributeName = "ShortAgreementText" Then
		ShortAgreementText.Delete();
		ShortAgreementText.Add(pSelectedValue);
	EndIf;
	AttributeName = "";
EndProcedure // ChoiceProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure AgreementTextOpening(pCommand)
	AttributeName = "AgreementText";
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text, ReadOnly", AgreementText.GetText(), Items.AgreementText.ReadOnly), ThisObject);
EndProcedure // AgreementTextOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure ShortAgreementTextOpening(pCommand)
	AttributeName = "ShortAgreementText";
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text, ReadOnly", ShortAgreementText.GetText(), Items.ShortAgreementText.ReadOnly), ThisObject);
EndProcedure // ShortAgreementTextOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationAgreementTextURLProcessing(pItem, pFormattedStringURL, pStandardProcessing)
	pStandardProcessing = False;
	vItemName = StrReplace(pItem.Name, "Decoration", "");
	
	If Items[vItemName].ReadOnly Then
		Return;
	EndIf;
	
	vBegin = Undefined;
	vEnd = Undefined;
	
	Items[vItemName].GetTextSelectionBounds(vBegin, vEnd);
	ThisObject[vItemName].Delete(vBegin, vEnd);
	ThisObject[vItemName].Insert(vBegin, pFormattedStringURL);
EndProcedure // Decoration4URLProcessing

#EndRegion 

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function ThereArePersonalDataProcessingConsentDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	COUNT(PersonalDataProcessingConsent.Ref) AS DocsCount
	|FROM
	|	Document.PersonalDataProcessingConsent AS PersonalDataProcessingConsent
	|WHERE
	|	PersonalDataProcessingConsent.AgreementText = &qAgreementText
	|	AND NOT PersonalDataProcessingConsent.DeletionMark";
	vQry.SetParameter("qAgreementText", Object.Ref);
	vRows = vQry.Execute().Unload();
	If vRows.Count() = 0 Then
		Return False;
	Else
		vRow = vRows.Get(0);
		If vRow.DocsCount = Null Then
			Return False;
		Else
			If vRow.DocsCount = 0 Then
				Return False;
			Else
				Return True;
			EndIf;
		EndIf;
	EndIf;
EndFunction // ThereArePersonalDataProcessingConsentDocuments

#EndRegion 
