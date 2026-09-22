
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	FillPort();
	FillBaudRate();
EndProcedure // OnCreateAtServer

#EndRegion

#Region Private

 // -----------------------------------------------------------------------------
&AtServer
Procedure FillPort()
	For i = 1 To 256 Do
		Items.Port.ChoiceList.Add("COM" + i);
	EndDo;
EndProcedure //  FillPort

// -----------------------------------------------------------------------------
&AtServer
Procedure FillBaudRate()
	Items.BaudRate.ChoiceList.Add(300);
	Items.BaudRate.ChoiceList.Add(600);
	Items.BaudRate.ChoiceList.Add(1200);
	Items.BaudRate.ChoiceList.Add(2400);
	Items.BaudRate.ChoiceList.Add(4800);
	Items.BaudRate.ChoiceList.Add(9600);
	Items.BaudRate.ChoiceList.Add(19200);
	Items.BaudRate.ChoiceList.Add(38400);
	Items.BaudRate.ChoiceList.Add(57600);
	Items.BaudRate.ChoiceList.Add(115200);
	Items.BaudRate.ChoiceList.Add(230400);
	Items.BaudRate.ChoiceList.Add(460800);
	Items.BaudRate.ChoiceList.Add(921600)
EndProcedure //  FillBaudRate

#EndRegion

