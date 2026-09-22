
#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
//
// Parameters:
//  pMessageNo		 - Number		 - Message number
//  pSenderNode		 - ExchangePlanRef	 - Sender node
//  pReceiverNode	 - ExchangePlanRef	 - Receiver node
//  pXMLValue		 - BinaryData		 - XML value
//  pIsSent			 - Boolean			 - Is sent
//  pDateSent		 - Date				 - Date sent
//  pIsReceived		 - Boolean			 - Is received
//  pDateReceived	 - Date				 - Date received
//  pIsLoaded		 - Boolean			 - Is loaded
//  pDateLoaded		 - Date				 - Date loaded
//
Procedure WriteData(pMessageNo, pSenderNode, pReceiverNode, pXMLValue, pFileSize, pIsSent = False, pDateSent = '00010101', 
					pIsReceived = False, pDateReceived = '00010101', pIsLoaded = False, pDateLoaded = '00010101') Export 
					
	If Not ValueIsFilled(pMessageNo) Or Not ValueIsFilled(pSenderNode) Or Not ValueIsFilled(pReceiverNode) Or pXMLValue = Undefined Then
		Return;
	EndIf;					
					
	vExchangePlanDataRecMgr = InformationRegisters.ExchangePlanData.CreateRecordManager();
	
	vExchangePlanDataRecMgr.MessageNo		= pMessageNo;
	vExchangePlanDataRecMgr.SenderNode		= pSenderNode;
	vExchangePlanDataRecMgr.ReceiverNode	= pReceiverNode;
	vExchangePlanDataRecMgr.XMLValue		= New ValueStorage(pXMLValue);
	vExchangePlanDataRecMgr.FileSize		= pFileSize;
	vExchangePlanDataRecMgr.IsSent			= pIsSent;
	vExchangePlanDataRecMgr.DateSent		= pDateSent;
	vExchangePlanDataRecMgr.IsReceived		= pIsReceived;
	vExchangePlanDataRecMgr.DateReceived	= pDateReceived;
	vExchangePlanDataRecMgr.IsLoaded		= pIsLoaded;
	vExchangePlanDataRecMgr.DateLoaded		= pDateLoaded;
	
	vExchangePlanDataRecMgr.Write(True);
EndProcedure // WriteData 
                          
// --------------------------------------------------------------------------------
//
// Parameters:
//  pMessageNo		 - Number					- Message number
//  pSenderNode		 - ExchangePlanRef			- Sender node
//  pReceiverNode	 - ExchangePlanRef			- Receiver node
//  pXMLValue		 - BinaryData, Undefined	- XML value
//  pMessageID		 - UUID, Undefined			- Message ID
//  pIsSentToESB	 - Boolean, Undefined		- Is sent to ESB
//  pDateSentToESB	 - Date, Undefined			- Date sent to ESB
//  pIsSent			 - Boolean, Undefined		- Is sent
//  pDateSent		 - Date, Undefined			- Date sent
//  pIsReceived		 - Boolean, Undefined		- Is received
//  pDateReceived	 - Date, Undefined			- Date received
//  pIsLoaded		 - Boolean, Undefined		- Is loaded
//  pDateLoaded		 - Date, Undefined			- Date loaded
//
Procedure UpdateData(pMessageNo, pSenderNode, pReceiverNode, pMessageID = Undefined, pIsSentToESB = Undefined, pDateSentToESB = Undefined, 
					 pIsSent = Undefined, pDateSent = Undefined, pIsReceived = Undefined, pDateReceived = Undefined, 
					 pIsLoaded = Undefined, pDateLoaded = Undefined) Export 
					
	If Not ValueIsFilled(pMessageNo) Or Not ValueIsFilled(pSenderNode) Or Not ValueIsFilled(pReceiverNode) Then
		Return;
	EndIf;					
					
	vExchangePlanDataRecSet = InformationRegisters.ExchangePlanData.CreateRecordSet(); 
	
	vExchangePlanDataRecSet.Filter.MessageNo.Use		= True;
	vExchangePlanDataRecSet.Filter.MessageNo.Value		= pMessageNo;	
	vExchangePlanDataRecSet.Filter.SenderNode.Use		= True;
	vExchangePlanDataRecSet.Filter.SenderNode.Value		= pSenderNode;
	vExchangePlanDataRecSet.Filter.ReceiverNode.Use		= True;
	vExchangePlanDataRecSet.Filter.ReceiverNode.Value	= pReceiverNode;
	
	vExchangePlanDataRecSet.Read();
	If vExchangePlanDataRecSet.Count() > 0 Then
		For Each vExchangePlanDataRow In vExchangePlanDataRecSet Do
			If pMessageID <> Undefined Then
				vExchangePlanDataRow.MessageID		= pMessageID;
			EndIf;
			If pIsSentToESB <> Undefined Then
				vExchangePlanDataRow.IsSentToESB	= pIsSentToESB;
			EndIf;
			If pDateSentToESB <> Undefined Then
				vExchangePlanDataRow.DateSentToESB	= pDateSentToESB;
			EndIf;
			If pIsSent <> Undefined Then
				vExchangePlanDataRow.IsSent			= pIsSent;
			EndIf;
			If pDateSent <> Undefined Then
				vExchangePlanDataRow.DateSent		= pDateSent;
			EndIf;
			If pIsReceived <> Undefined Then
				vExchangePlanDataRow.IsReceived		= pIsReceived;
			EndIf;
			If pDateReceived <> Undefined Then
				vExchangePlanDataRow.DateReceived	= pDateReceived;
			EndIf;
			If pIsLoaded <> Undefined Then
				vExchangePlanDataRow.IsLoaded		= pIsLoaded;
			EndIf;
			If pDateLoaded <> Undefined Then
				vExchangePlanDataRow.DateLoaded		= pDateLoaded;
			EndIf;
		EndDo;
		vExchangePlanDataRecSet.Write(True);	
	EndIf;
EndProcedure // WriteData

// --------------------------------------------------------------------------------
//
// Parameters:
//  pIsSent		 - Boolean	 - Is sent
//  pIsReceived	 - Boolean	 - Is received
//  pIsLoaded	 - Boolean	 - Is loaded
// 
// Returns:
//  QueryResultSelection - Exchange plan data list
//
Function GetData(pSenderNode = Undefined, pReceiverNode = Undefined, pIsSent = False, pIsReceived = False, pIsLoaded = False, pIsUnload = False) Export 
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	ExchangePlanData.MessageNo AS MessageNo,
	|	ExchangePlanData.SenderNode AS SenderNode,
	|	ExchangePlanData.ReceiverNode AS ReceiverNode,
	|	ExchangePlanData.XMLValue AS XMLValue,
	|	ExchangePlanData.IsSent AS IsSent,
	|	ExchangePlanData.DateSent AS DateSent,
	|	ExchangePlanData.IsReceived AS IsReceived,
	|	ExchangePlanData.DateReceived AS DateReceived,
	|	ExchangePlanData.IsLoaded AS IsLoaded,
	|	ExchangePlanData.DateLoaded AS DateLoaded,
	|	ExchangePlanData.FileSize AS FileSize,
	|	ExchangePlanData.MessageID AS MessageID,
	|	ExchangePlanData.IsSentToESB AS IsSentToESB,
	|	ExchangePlanData.DateSentToESB AS DateSentToESB
	|FROM
	|	InformationRegister.ExchangePlanData AS ExchangePlanData
	|WHERE
	|	ExchangePlanData.IsSent = &qIsSent
	|	AND ExchangePlanData.IsReceived = &qIsReceived
	|	AND ExchangePlanData.IsLoaded = &qIsLoaded
	|	AND CASE
	|			WHEN NOT &qSenderNodeIsEmpty
	|				THEN ExchangePlanData.SenderNode = &qSenderNode
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT &qReceiverNodeIsEmpty
	|				THEN ExchangePlanData.ReceiverNode = &qReceiverNode
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	MessageNo"; 
	vQuery.SetParameter("qSenderNodeIsEmpty", Not ValueIsFilled(pSenderNode));
	vQuery.SetParameter("qSenderNode", pSenderNode);
	vQuery.SetParameter("qReceiverNodeIsEmpty", Not ValueIsFilled(pReceiverNode));
	vQuery.SetParameter("qReceiverNode", pReceiverNode);
	vQuery.SetParameter("qIsSent", pIsSent);
	vQuery.SetParameter("qIsReceived", pIsReceived);
	vQuery.SetParameter("qIsLoaded", pIsLoaded); 
	If Not pIsUnload Then
		Return vQuery.Execute().Select();
	Else
		Return vQuery.Execute().Unload();	
	EndIf;
EndFunction // GetData

// --------------------------------------------------------------------------------
//
// Parameters:
//  pMessageNo		 - Number			- Message number
//  pSenderNode		 - ExchangePlanRef	- Sender node
//  pReceiverNode	 - ExchangePlanRef	- Receiver node
//
Procedure DeleteData(pMessageNo, pSenderNode, pReceiverNode) Export 
	If Not ValueIsFilled(pMessageNo) Or Not ValueIsFilled(pSenderNode) Or Not ValueIsFilled(pReceiverNode) Then
		Return;
	EndIf;
	
	vExchangePlanDataRecSet = InformationRegisters.ExchangePlanData.CreateRecordSet();
	
	vExchangePlanDataRecSet.Filter.MessageNo.Set(pMessageNo);
	vExchangePlanDataRecSet.Filter.SenderNode.Set(pSenderNode);
	vExchangePlanDataRecSet.Filter.ReceiverNode.Set(pReceiverNode);
	
	vExchangePlanDataRecSet.Write();
EndProcedure //DeleteData

#EndRegion
