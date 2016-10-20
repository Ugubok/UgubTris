EnableExplicit

XIncludeFile "TetrisLow.pb"
XIncludeFile "DefaultFigures.pb"
XIncludeFile "TetrisDebug.pbf"

UseModule TetrisLow

Structure FigureItem
  Name.s
  *Figure.FigureFrame
EndStructure


Procedure CountFigureFrames(*Figure.FIGURE)
  Protected Result.a
  Protected *CurrentFrame.FigureFrame = *Figure\DefaultFrame
  
  Repeat
    Result + 1
    *CurrentFrame = *CurrentFrame\NextFrame
  Until *CurrentFrame = *Figure\DefaultFrame
  
  ProcedureReturn Result
EndProcedure

Procedure ClearCanvas()
  StartDrawing(CanvasOutput(Canvas_0))
  Box(0, 0, GadgetWidth(Canvas_0), GadgetHeight(Canvas_0), $FFFFFF)
  StopDrawing()
EndProcedure

Procedure UpdateCaptions()
  Global *FigureLoaded.FIGURE
  SetGadgetText(Text_0, "Frame #" + Str(GetGadgetState(TrackBar_0)) + "/" + Str(CountFigureFrames(*FigureLoaded)-1))
  SetGadgetText(Text_1, "Frame Size " + Str(*FigureLoaded\Frame\Width) + "x" + Str(*FigureLoaded\Frame\Height))
  SetGadgetText(Text_2, "X: " + Str(*FigureLoaded\X) + "; Y: " + Str(*FigureLoaded\Y))
  SetGadgetText(Text_3, "CenterPoint: " + Str(*FigureLoaded\Frame\XCenter) + "," + Str(*FigureLoaded\Frame\YCenter))
EndProcedure

Procedure RenderFigure()
  Global *FigureLoaded.FIGURE
  Protected x.a, y.a, tx.i, ty.i, i.a, color.a, RenderX.i, RenderY.i
  #SQARE_SIZE = 20
  #PADDING = 4
  #MARGIN = 4
  
  If *FigureLoaded
    ClearCanvas()
    StartDrawing(CanvasOutput(Canvas_0))
    For y = 0 To 10
      Box(0, (#SQARE_SIZE+#PADDING)*y - #PADDING + #MARGIN, 300, #PADDING, $DDDDDD)
    Next
    For x = 0 To 10
      Box((#SQARE_SIZE+#PADDING)*x - #PADDING + #MARGIN, 0, #PADDING, 300, $DDDDDD)
    Next
    For y = 0 To *FigureLoaded\Frame\Height - 1
      For x = 0 To *FigureLoaded\Frame\Width - 1
        color = PeekA(*FigureLoaded\Frame\Data + i)
        tx = x + *FigureLoaded\X
        ty = y + *FigureLoaded\Y
        RenderX = #MARGIN + #PADDING*tx + #SQARE_SIZE*tx
        RenderY = #MARGIN + #PADDING*ty + #SQARE_SIZE*ty
        If color
          Box(RenderX, RenderY, #SQARE_SIZE, #SQARE_SIZE, color << 2)
        Else
          Box(RenderX, RenderY, #SQARE_SIZE, #SQARE_SIZE, $DDDDDD)
        EndIf
        
        If (x = *FigureLoaded\Frame\XCenter-1) And (y = *FigureLoaded\Frame\YCenter-1)
          Circle(RenderX + #SQARE_SIZE/2, RenderY + #SQARE_SIZE/2, 5, $800080)
        EndIf
        i + 1
      Next
    Next
    StopDrawing()
  EndIf
EndProcedure

Procedure OnTrackbarUpdate()
  Global *FigureLoaded.FIGURE
  Global *Stack.STACK
  Protected TrackBarPos.a = GetGadgetState(TrackBar_0)
  Protected i.a
  
  *FigureLoaded\Frame = *FigureLoaded\DefaultFrame
  For i = 0 To TrackBarPos
    *FigureLoaded\Frame = *FigureLoaded\Frame\NextFrame
    ;RotateWithCentering(*FigureLoaded, *Stack)
  Next
  
  UpdateCaptions()
  RenderFigure()
EndProcedure

Procedure SetDefaultFrame()
  *FigureLoaded\Frame = *FigureLoaded\DefaultFrame
  UpdateCaptions()
  RenderFigure()
EndProcedure

Procedure LoadFigure(*Figure.FIGURE)
  Global *FigureLoaded = *Figure
  
  *FigureLoaded\X = 2
  *FigureLoaded\Y = 2
  SetGadgetAttribute(TrackBar_0, #PB_TrackBar_Maximum, CountFigureFrames(*Figure)-1)
  SetGadgetState(TrackBar_0, 0)
  SetDefaultFrame()
EndProcedure

Procedure OnResetButtonDown()
  If *FigureLoaded
    *FigureLoaded\X = 2
    *FigureLoaded\Y = 2
    OnTrackbarUpdate()
  EndIf
EndProcedure

Procedure RotateAndRender(RotateLeft.b = #True)
  RotateWithCentering(*FigureLoaded, *Stack, RotateLeft)
  UpdateCaptions()
  RenderFigure()
EndProcedure

Procedure LoadFiguresList(List FiguresList.FigureItem())
  ClearGadgetItems(ListView_0)
  ForEach FiguresList()
    AddGadgetItem(ListView_0, -1, FiguresList()\Name)
    SetGadgetItemData(ListView_0, CountGadgetItems(ListView_0)-1, FiguresList()\Figure)
  Next
EndProcedure

Procedure LoadRandomFigure()
  Protected *RandomFigure.FIGURE
  Protected RandomWidth.a, RandomHeight.a
  Protected RandomByte.a, i.i
  
  RandomWidth = Random(4, 1)
  RandomHeight = Random(4, 1)
  RandomByte = Random($FF, $10)
  Dim RandomDataArr.a(RandomWidth * RandomHeight - 1)
  
  For i = 0 To ArraySize(RandomDataArr())
    If Random(1) : RandomDataArr(i) = RandomByte : EndIf
  Next
  *RandomFigure = CreateFigureAuto(CreateFrameFromA(RandomWidth, RandomHeight, RandomDataArr()))
  
  LoadFigure(*RandomFigure)
  UpdateCaptions()
  RenderFigure()
EndProcedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Global *FigureLoaded
Global *Stack.STACK = CreateStack(10, 20)
NewList AllFiguresList.FigureItem()

Define Event.i
Define LastTrackBarPos.i = -1
Define LastListItem.i = -1
Define SelectedItem.i

AddElement(AllFiguresList())
AllFiguresList()\Name = "T"
AllFiguresList()\Figure = *TFigureA
AddElement(AllFiguresList())
AllFiguresList()\Name = "L"
AllFiguresList()\Figure = *LFigureA
AddElement(AllFiguresList())
AllFiguresList()\Name = "F"
AllFiguresList()\Figure = *FFigureA
AddElement(AllFiguresList())
AllFiguresList()\Name = "Z"
AllFiguresList()\Figure = *ZFigureA
AddElement(AllFiguresList())
AllFiguresList()\Name = "S"
AllFiguresList()\Figure = *SFigureA
AddElement(AllFiguresList())
AllFiguresList()\Name = "I"
AllFiguresList()\Figure = *IFigureA
AddElement(AllFiguresList())
AllFiguresList()\Name = "O"
AllFiguresList()\Figure = *OFigureA

OpenWindow_0()
LoadFigure(*TFigureA)
LoadFiguresList(AllFiguresList())

Repeat
  Event = WaitWindowEvent()
  
  Select EventGadget()
    Case TrackBar_0
      If GetGadgetState(TrackBar_0) <> LastTrackBarPos
        LastTrackBarPos = GetGadgetState(TrackBar_0)
        OnTrackbarUpdate()
      EndIf
      
    Case Button_0
      If EventType() = #PB_EventType_LeftClick
        OnResetButtonDown()
      EndIf
      
    Case Button_2
      If EventType() = #PB_EventType_LeftClick
        RotateAndRender(#True)
      EndIf
      
    Case Button_3
      If EventType() = #PB_EventType_LeftClick
        RotateAndRender(#False)
      EndIf
      
    Case Button_4
      If EventType() = #PB_EventType_LeftClick
        SetDefaultFrame()
      EndIf
      
    Case Button_8
      LoadRandomFigure()
      
    Case ListView_0
      If EventType() = #PB_EventType_LeftClick
        SelectedItem = GetGadgetState(ListView_0)
        If SelectedItem <> -1 And SelectedItem <> LastListItem
          LoadFigure(GetGadgetItemData(ListView_0, SelectedItem))
        EndIf
      EndIf
  EndSelect
  
  If Not Window_0_Events(Event)
    Break
  EndIf 
ForEver
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; CursorPosition = 148
; FirstLine = 130
; Folding = --
; EnableUnicode
; EnableXP