
#Region FormEventHandlers

// --------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("ObjectRef", ObjectRef) And ObjectRef <> Undefined Then
		FillChargingRulesAtServer();
	Else
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If TypeOf(ObjectRef) = Type("DocumentRef.Accommodation") Or TypeOf(ObjectRef) = Type("DocumentRef.Reservation") Then
		Items.ChargingRulesIsMaster.Visible = True;
		Items.ChargingRulesIsPersonal.Visible = True;
		Items.ChargingRulesIsTransfer.Visible = True;
		Items.ChargingRulesOwner.Visible = True;
	ElsIf TypeOf(ObjectRef) = Type("CatalogRef.GuestGroups") Then
		Items.ChargingRulesIsMaster.Visible = False;
		Items.ChargingRulesIsPersonal.Visible = True;
		Items.ChargingRulesIsTransfer.Visible = False;
		Items.ChargingRulesOwner.Visible = False;
	Else
		Items.ChargingRulesIsMaster.Visible = False;
		Items.ChargingRulesIsPersonal.Visible = False;
		Items.ChargingRulesIsTransfer.Visible = False;
		Items.ChargingRulesOwner.Visible = False;
	EndIf;
EndProcedure // OnOpen

// --------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pParameter = ObjectRef Then
		FillChargingRulesAtServer();
	EndIf;
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------
&AtServer
Procedure FillChargingRulesAtServer()
	If TypeOf(ObjectRef) = Type("DocumentRef.Accommodation") Or TypeOf(ObjectRef) = Type("DocumentRef.Reservation") Then
		vChargingRules = ObjectRef.ChargingRules.Unload(, "ChargingRule, ChargingRuleValue, ChargingFolio, ValidFromDate, ValidToDate, Owner, IsMaster, IsPersonal, IsTransfer");
	ElsIf TypeOf(ObjectRef) = Type("CatalogRef.GuestGroups") Then
		vChargingRules = ObjectRef.ChargingRules.Unload(, "ChargingRule, ChargingRuleValue, ChargingFolio, ValidFromDate, ValidToDate");
		vChargingRules.Columns.Add("IsMaster");
		vChargingRules.Columns.Add("IsTransfer");
		vChargingRules.Columns.Add("IsPersonal");
		vChargingRules.Columns.Add("Owner");
	Else
		vChargingRules = ObjectRef.ChargingRules.Unload(, "ChargingRule, ChargingRuleValue, ChargingFolio, ValidFromDate, ValidToDate, IsPersonal");
		vChargingRules.Columns.Add("IsMaster");
		vChargingRules.Columns.Add("IsTransfer");
		vChargingRules.Columns.Add("Owner");
	EndIf;
	ValueToFormAttribute(vChargingRules, "ChargingRules");
EndProcedure

#EndRegion
