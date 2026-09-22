
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pSurvey	 - CatalogRef.Surveys	 -  Ref
//  pLang	 - CatalogRef.Languages	 -  куа
// 
// Returns:
//  SpreadsheetDocument - SpreadsheetDocument
//
Function GetSurveySpreadsheet(pSurvey, pLang = Undefined) Export
	vSpreadsheet 	= New SpreadsheetDocument;
	vTemplate 		= Catalogs.Surveys.GetTemplate("Survey");
	vDelimiterArea	= vTemplate.GetArea("Delimiter");
	vArea			= vTemplate.GetArea("Header");
	vArea.Parameters.Description 	= cmNStr(pSurvey.Description, pLang);
	vArea.Parameters.HeaderText		= cmNStr(pSurvey.HeaderText, pLang);
	vSpreadsheet.Put(vArea);
	vQuestionID = 1;
	For each vQuestion in pSurvey.Questions Do
		If vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.String Then
			vArea	= vTemplate.GetArea("RowString");
	        vArea.Parameters.Question 	= String(vQuestionID) + ") " + cmNStr(vQuestion.FeedbackQuestion.QuestionText, pLang);
			vSpreadsheet.Put(vArea);
			vSpreadsheet.Put(vDelimiterArea);
		ElsIf vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.Number Then
			vArea	= vTemplate.GetArea("RowNumber");
	        vArea.Parameters.Question 	= String(vQuestionID) + ") " + cmNStr(vQuestion.FeedbackQuestion.QuestionText, pLang);
			vSpreadsheet.Put(vArea);
			vSpreadsheet.Put(vDelimiterArea);
		ElsIf vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.Boolean Then
			vArea	= vTemplate.GetArea("RowBoolean");
	        vArea.Parameters.Question 	= String(vQuestionID) + ") " + cmNStr(vQuestion.FeedbackQuestion.QuestionText, pLang);
			vSpreadsheet.Put(vArea);
			vSpreadsheet.Put(vDelimiterArea);
		ElsIf vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.List Then
			vArea	= vTemplate.GetArea("RowList");
	        vArea.Parameters.Question 	= String(vQuestionID) + ") " + cmNStr(vQuestion.FeedbackQuestion.QuestionText, pLang);
			vSpreadsheet.Put(vArea);
			vAnswerID = 1;
			For each vAnswer in vQuestion.FeedbackQuestion.AnswerVariants Do
				vArea	= vTemplate.GetArea("RowListAnswer");
	       		vArea.Parameters.Answer 	= String(vAnswerID) + " - " + cmNStr(vAnswer.AnswerText, pLang);
				vSpreadsheet.Put(vArea);
				vAnswerID = vAnswerID + 1;
			EndDo;
			vSpreadsheet.Put(vDelimiterArea);
		EndIf;
		
		vQuestionID = vQuestionID + 1;
	EndDo;
	
	vArea			= vTemplate.GetArea("Footer");
	vArea.Parameters.FooterText		= cmNStr(pSurvey.FooterText, pLang);
	vSpreadsheet.Put(vArea);
	Return vSpreadsheet;
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
