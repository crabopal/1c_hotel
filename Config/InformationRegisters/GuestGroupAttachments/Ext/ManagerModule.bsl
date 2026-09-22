// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vGuestGroup = pData.Filter.GuestGroup.Value;
	If ValueIsFilled(vGuestGroup) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vGuestGroup.Owner, pReceiverNode);
	EndIf;	
EndProcedure // ExchangePlansRecordChanges

// -----------------------------------------------------------------------------
Procedure WriteData(rPeriod = '00010101', pGuestGroup, pReservationNumber = "", pClient = Undefined, pDocumentType = Undefined, 
					pDocumentNumber = Undefined, pIsIncoming = False, pEMail = Undefined, pFax = Undefined, pAttachmentType = Undefined, 
					pAttachmentStatus = Undefined, pDocumentText = "", pSMSTemplates = Undefined, pParentDoc = Undefined, pDiscountCard = Undefined, 
					pAmountStr = "", pFullFileName = "", pFileName = "", pDeleteFile = False, pRemarks = "", pAuthor = Undefined) Export
	
	If Not ValueIsFilled(pGuestGroup) Then
		Return;
	EndIf;
	
	vEMail = pEMail;
	If vEMail = Undefined Then
		If ValueIsFilled(pGuestGroup.ClientDoc) And TypeOf(pGuestGroup.ClientDoc) <> Type("DocumentRef.Folio") Then
			vEMail = pGuestGroup.ClientDoc.EMail;		
		ElsIf ValueIsFilled(pGuestGroup.Client) Then
			vEMail = pGuestGroup.Client.EMail;	
		ElsIf ValueIsFilled(pGuestGroup.Customer) Then
			vEMail = pGuestGroup.Customer.EMail;	
		EndIf;
	EndIf;
	
	vFax = pFax;
	If vFax = Undefined Then
		If ValueIsFilled(pGuestGroup.ClientDoc) And TypeOf(pGuestGroup.ClientDoc) <> Type("DocumentRef.Folio") Then
			vFax = pGuestGroup.ClientDoc.Fax;		
		ElsIf ValueIsFilled(pGuestGroup.Client) Then
			vFax = pGuestGroup.Client.Fax;	
		ElsIf ValueIsFilled(pGuestGroup.Customer) Then
			vFax = pGuestGroup.Customer.Fax;	
		EndIf;
	EndIf;
	
	If pAttachmentType = Enums.AttachmentTypes.EMail And Not ValueIsFilled(TrimAll(vEMail)) Then
		Return;	
	EndIf;
	
	vPeriod = rPeriod;
	If Not ValueIsFilled(vPeriod) Then
		vPeriod = CurrentSessionDate();
	EndIf;

	vGrpAttachmentsRecMgr		 								= InformationRegisters.GuestGroupAttachments.CreateRecordManager();
	
	// Try to find period without other attachments
	vGrpAttachmentsRecMgr.Period 								= vPeriod;
	vGrpAttachmentsRecMgr.GuestGroup 							= pGuestGroup;
	vGrpAttachmentsRecMgr.Read();
	While vGrpAttachmentsRecMgr.Selected() Do
		vPeriod = vPeriod + 1;
		vGrpAttachmentsRecMgr.Period 							= vPeriod;
		vGrpAttachmentsRecMgr.GuestGroup	 					= pGuestGroup;
		vGrpAttachmentsRecMgr.Read();
	EndDo;	
	
	vGrpAttachmentsRecMgr.Period 								= vPeriod;
	vGrpAttachmentsRecMgr.GuestGroup 							= pGuestGroup;
	vGrpAttachmentsRecMgr.ReservationNumber 					= pReservationNumber;
	vGrpAttachmentsRecMgr.Client 								= pClient;
	vGrpAttachmentsRecMgr.DocumentType 							= pDocumentType;
	vGrpAttachmentsRecMgr.DocumentNumber 						= pDocumentNumber;
	vGrpAttachmentsRecMgr.IsIncoming 							= pIsIncoming;
	vGrpAttachmentsRecMgr.EMail 								= vEMail;
	vGrpAttachmentsRecMgr.Fax 									= vFax;
	vGrpAttachmentsRecMgr.AttachmentType 						= pAttachmentType;
	vGrpAttachmentsRecMgr.AttachmentStatus 						= pAttachmentStatus;
	vGrpAttachmentsRecMgr.DocumentText 							= pDocumentText;
	vGrpAttachmentsRecMgr.SMSTemplates 							= pSMSTemplates;
	vGrpAttachmentsRecMgr.ParentDoc 							= pParentDoc;
	vGrpAttachmentsRecMgr.DiscountCard 							= pDiscountCard;
	vGrpAttachmentsRecMgr.AmountStr 							= pAmountStr;
	
	If pFullFileName <> Undefined Then
		If TypeOf(pFullFileName) = Type("String") Then 
			If ValueIsFilled(pFullFileName) Then
				vFile = New File(pFullFileName);	
				If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() Then
					vGrpAttachmentsRecMgr.ExtFile 				= New ValueStorage(New BinaryData(pFullFileName));
					If ValueIsFilled(pFileName) Then
						vGrpAttachmentsRecMgr.FileName 			= pFileName;
					Else
						vGrpAttachmentsRecMgr.FileName 			= vFile.Name;
					EndIf;
					vGrpAttachmentsRecMgr.FileLoadTime 			= vPeriod;
					vGrpAttachmentsRecMgr.FileLastChangeTime 	= vFile.GetModificationTime();
					If pDeleteFile Then
						DeleteFiles(pFullFileName);
					EndIf;
				EndIf;
			EndIf;
		Else
			vGrpAttachmentsRecMgr.ExtFile 						= pFullFileName;
			vGrpAttachmentsRecMgr.FileName 						= pFileName;
			vGrpAttachmentsRecMgr.FileLoadTime 					= vPeriod;
			vGrpAttachmentsRecMgr.FileLastChangeTime 			= vPeriod;
		EndIf;
	EndIf;
		
	vGrpAttachmentsRecMgr.Remarks 								= pRemarks;
	vGrpAttachmentsRecMgr.Author 								= pAuthor;
	vGrpAttachmentsRecMgr.Write(True);
	
	rPeriod = vPeriod;
EndProcedure // WriteData

// -----------------------------------------------------------------------------
Procedure UpdateDataByPeriodAndGuestGroup(pPeriod, pGuestGroup, pReservationNumber = Undefined, pClient = Undefined, pDocumentType = Undefined, 
					pDocumentNumber = Undefined, pIsIncoming = Undefined, pEMail = Undefined, pFax = Undefined, pAttachmentType = Undefined, 
					pAttachmentStatus = Undefined, pDocumentText = Undefined, pSMSTemplates = Undefined, pParentDoc = Undefined, pDiscountCard = Undefined, 
					pAmountStr = Undefined, pFullFileName = Undefined, pFileName = Undefined, pDeleteFile = False, pRemarks = Undefined, pAuthor = Undefined) Export
	
	If Not ValueIsFilled(pPeriod) OR Not ValueIsFilled(pGuestGroup) Then
		Return;
	EndIf;
	
	vRecSet 													= InformationRegisters.GuestGroupAttachments.CreateRecordSet();
	vRecSet.Filter.Period.Use									= True;
	vRecSet.Filter.Period.Value									= pPeriod;
	vRecSet.Filter.GuestGroup.Use								= True;
	vRecSet.Filter.GuestGroup.Value								= pGuestGroup;
	vRecSet.Read();
	If vRecSet.Count() > 0 Then
		For Each vRow In vRecSet Do	
			If pReservationNumber <> Undefined Then
				vRow.ReservationNumber 							= pReservationNumber;
			EndIf;
			If pClient <> Undefined Then
				vRow.Client 									= pClient; 
			EndIf;
			If pDocumentType <> Undefined Then
				vRow.DocumentType 								= pDocumentType;
			EndIf;
			If pDocumentNumber <> Undefined Then
				vRow.DocumentNumber 							= pDocumentNumber;
			EndIf;
			If pIsIncoming <> Undefined Then
				vRow.IsIncoming 								= pIsIncoming;
			EndIf;
			If pEMail <> Undefined Then
				vRow.EMail 										= pEMail;
			EndIf;
			If pFax <> Undefined Then
				vRow.Fax 										= pFax; 
			EndIf;
			If pAttachmentType <> Undefined Then       	
				vRow.AttachmentType 							= pAttachmentType;
			EndIf;
			If pAttachmentStatus <> Undefined Then
				vRow.AttachmentStatus 							= pAttachmentStatus;
			EndIf;
			If pDocumentText <> Undefined Then
				vRow.DocumentText 								= pDocumentText; 
			EndIf;
			If pSMSTemplates <> Undefined Then
				vRow.SMSTemplates 								= pSMSTemplates;
			EndIf;
			If pParentDoc <> Undefined Then
				vRow.ParentDoc 									= pParentDoc;
			EndIf;
			If pDiscountCard <> Undefined Then
				vRow.DiscountCard 								= pDiscountCard; 
			EndIf;
			If pAmountStr <> Undefined Then
				vRow.AmountStr 									= pAmountStr;
			EndIf;
			
			If pFullFileName <> Undefined Then 
				If TypeOf(pFullFileName) = Type("String") Then
					If ValueIsFilled(pFullFileName) Then
						vFile = New File(pFullFileName);	
						If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() Then
							vRow.ExtFile 						= New ValueStorage(New BinaryData(pFullFileName));
							If ValueIsFilled(pFileName) Then
								vRow.FileName 					= pFileName;
							Else
								vRow.FileName 					= vFile.Name;	
							EndIf;
							vRow.FileLoadTime 					= CurrentSessionDate();
							vRow.FileLastChangeTime 			= vFile.GetModificationTime();	
							If pDeleteFile Then
								DeleteFiles(pFullFileName);
							EndIf;
						EndIf;
					EndIf; 
				Else
					vRow.ExtFile 								= pFullFileName;
					vRow.FileName 								= pFileName; 
					vCurDate 									= CurrentSessionDate();
					vRow.FileLoadTime		 					= vCurDate;
					vRow.FileLastChangeTime						= vCurDate;		
				EndIf;
			EndIf;
			
			If pRemarks <> Undefined Then
				vRow.Remarks						 			= pRemarks;
			EndIf;
			If pAuthor <> Undefined Then
				vRow.Author 									= pAuthor;
			EndIf;
		EndDo;
		vRecSet.Write(True);
	EndIf;
	
EndProcedure // WriteData