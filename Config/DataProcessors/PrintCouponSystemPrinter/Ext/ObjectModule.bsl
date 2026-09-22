// -----------------------------------------------------------------------------
Procedure ProcessException(pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, RibbonPrinterConnectionParameters.Metadata(), RibbonPrinterConnectionParameters, "Error description: " + rMessage);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function pmPrintCoupons(pObjList, pLang, rMessage) Export
	#IF CLIENT THEN
	Try
		// Get form
		vFrm = ThisObject.GetForm("CouponPrintForm");
		vFrm.SelObjList = pObjList;
		vFrm.SelLanguage = pLang;
		// Open form
		vFrm.Open();
		Return True;
	Except
		rMessage = ErrorDescription();
		ProcessException(NStr("en='RibbonPrinterConnectionParameters.PrintCoupon'; de='RibbonPrinterConnectionParameters.PrintCoupon'; ru='ЛенточныйПринтер.ПечатьТалона'"), rMessage);
	EndTry;
	#ENDIF
	Return False;
EndFunction // pmPrintCoupons
