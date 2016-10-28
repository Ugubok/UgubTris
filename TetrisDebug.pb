EnableExplicit

PurifierGranularity(1, 1, 1, 1) 

Procedure ErrorHandler()
	Protected DieMsg$ = GetFilePart(ErrorFile()) + " [" + ErrorLine() + "]" + #CRLF$ + 
				UCase(ErrorMessage()) + " [ 0x" + RSet(Hex(ErrorTargetAddress()), SizeOf(INTEGER) * 2, "0") + " ]" + #CRLF$ +
					RSet("", 64, " ")
	
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows 
		MessageBox_(0, DieMsg$, "FATAL ERROR", #MB_ICONSTOP | #MB_OK)
	CompilerElse
		MessageRequester("FATAL ERROR", DieMsg$)
	CompilerEndIf
EndProcedure
OnErrorCall(@ErrorHandler())


XIncludeFile "TetrisMid.pb"
IncludeFile "DefaultFigures.pb"
XIncludeFile "TetrisDebug.pbf"

UseModule TetrisLow

Structure FigureItem
  Name.s
  *Figure.FigureFrame
EndStructure

;- RENDER CONSTANTS
#SQARE_SIZE = 10
#PADDING = 1
#MARGIN = 0
#GRID_COLOR = $DDDDDD


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
  Global *Stack.STACK
  SetGadgetText(Text_0, "Frame #" + Str(GetGadgetState(TrackBar_0)) + "/" + Str(CountFigureFrames(*FigureLoaded)-1))
  SetGadgetText(Text_1, "Frame Size " + Str(*FigureLoaded\Frame\Width) + "x" + Str(*FigureLoaded\Frame\Height))
  SetGadgetText(Text_2, "X: " + Str(*FigureLoaded\X) + "; Y: " + Str(*FigureLoaded\Y))
  SetGadgetText(Text_3, "CenterPoint: " + Str(*FigureLoaded\Frame\XCenter) + "," + Str(*FigureLoaded\Frame\YCenter))
  HideGadget(Text_CollisionSign, #True ! Bool(CheckCollision(*FigureLoaded, *Stack)))
EndProcedure

Procedure.i TrueColor8bit(Color.a)
  ProcedureReturn (Color>>5 << 21) | ((Color>>2 & %000111) << 13) | ((Color&3) << 6)
EndProcedure

Procedure DrawGrid()
  Protected x.a, y.a
  StartDrawing(CanvasOutput(Canvas_0))
  For y = 0 To 19
    Box(0, (#SQARE_SIZE+#PADDING)*y - #PADDING + #MARGIN, 300, #PADDING, #GRID_COLOR)
  Next
  For x = 0 To 19
    Box((#SQARE_SIZE+#PADDING)*x - #PADDING + #MARGIN, 0, #PADDING, 300, #GRID_COLOR)
  Next
  StopDrawing()
EndProcedure

Procedure RenderStack()
  Global *Stack.STACK
  Protected.i x, y, color, RenderX, RenderY
  
  StartDrawing(CanvasOutput(Canvas_0))  
  For y = 0 To *Stack\Height-1
    For x = 0 To *Stack\Width-1
      color = TrueColor8bit(ReadStackXY(*Stack, x, y))
      RenderX = #MARGIN + #PADDING*x + #SQARE_SIZE*x
      RenderY = #MARGIN + #PADDING*y + #SQARE_SIZE*y
      If color
        Box(RenderX, RenderY, #SQARE_SIZE, #SQARE_SIZE, color)
      ;Else
      ;  Box(RenderX, RenderY, #SQARE_SIZE, #SQARE_SIZE, $DDDDDD)
      EndIf
    Next
  Next
  StopDrawing()
EndProcedure

Procedure RenderFigure()
  Global *FigureLoaded.FIGURE
  Global *Stack.STACK
  Protected.i x, y, tx, ty, i, color, RenderX, RenderY
  
  If *FigureLoaded
    StartDrawing(CanvasOutput(Canvas_0))
    
    ; FIRST OF ALL, RENDER FIGURE SHADOW
    CalcShadowCoord(*FigureLoaded, *Stack)
    For y = *FigureLoaded\ShadowY To *FigureLoaded\ShadowY + *FigureLoaded\Frame\Height - 1
      For x = 0 To *FigureLoaded\Frame\Width - 1
        color = TrueColor8bit(PeekBLOCK(*FigureLoaded\Frame\Data + i * SizeOf(BLOCK)))
        tx = x + *FigureLoaded\X
        ty = y
        RenderX = #MARGIN + #PADDING*tx + #SQARE_SIZE*tx
        RenderY = #MARGIN + #PADDING*ty + #SQARE_SIZE*ty
        If color
          Box(RenderX, RenderY, #SQARE_SIZE, #SQARE_SIZE, $C8D530)
          Box(RenderX+1, RenderY+1, #SQARE_SIZE-2, #SQARE_SIZE-2)
        EndIf
        i + 1
      Next
    Next 
    i = 0
    ; THEN RENDER FIGURE
    For y = 0 To *FigureLoaded\Frame\Height - 1
      For x = 0 To *FigureLoaded\Frame\Width - 1
        color = PeekBLOCK(*FigureLoaded\Frame\Data + i * SizeOf(BLOCK))
        tx = x + *FigureLoaded\X
        ty = y + *FigureLoaded\Y
        RenderX = #MARGIN + #PADDING*tx + #SQARE_SIZE*tx
        RenderY = #MARGIN + #PADDING*ty + #SQARE_SIZE*ty
        If color
          Box(RenderX, RenderY, #SQARE_SIZE, #SQARE_SIZE, color)
        ;Else
        ;  Box(RenderX, RenderY, #SQARE_SIZE, #SQARE_SIZE, $DDDDDD)
        EndIf
        
        If (x = *FigureLoaded\Frame\XCenter-1) And (y = *FigureLoaded\Frame\YCenter-1)
          Circle(RenderX + #SQARE_SIZE/2, RenderY + #SQARE_SIZE/2, #SQARE_SIZE/4, $800080)
        EndIf
        i + 1
      Next
    Next
    StopDrawing()
  EndIf
EndProcedure

Procedure RenderAll()
  ClearCanvas()
  DrawGrid()
  RenderStack()
  RenderFigure()
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
  RenderAll()
EndProcedure

Procedure SetDefaultFrame()
  *FigureLoaded\Frame = *FigureLoaded\DefaultFrame
  UpdateCaptions()
  RenderAll()
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
  RenderAll()
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
  Protected RandomBlock.BLOCK, i.i
  Global LastFigureWasRandom.b
  
  RandomWidth = Random(4, 1)
  RandomHeight = Random(4, 1)
  RandomBlock\id = Random(Pow($FF, SizeOf(BLOCK)), $10)
  Dim RandomDataArr.BLOCK(RandomWidth * RandomHeight - 1)
  
  For i = 0 To ArraySize(RandomDataArr())
    If Random(1) : RandomDataArr(i)\id = RandomBlock\id : EndIf
  Next
  *RandomFigure = CreateFigureAuto(CreateFrameFromA(RandomWidth, RandomHeight, RandomDataArr()))
  
  If LastFigureWasRandom
    FreeFigure(*FigureLoaded)
  Else
    LastFigureWasRandom = #True
  EndIf
  LoadFigure(*RandomFigure)
  UpdateCaptions()
  RenderAll()
EndProcedure

Procedure MoveFigure(DeltaX.i, DeltaY.i)
  If *FigureLoaded And IsMovePossible(*FigureLoaded, *Stack, DeltaX, DeltaY)
    *FigureLoaded\X + DeltaX
    *FigureLoaded\Y + DeltaY
    UpdateCaptions()
    RenderAll()
  EndIf
EndProcedure

Procedure FillStackWithShit(*Stack.STACK)
  Protected.a x, y
  For y = 5 To *Stack\Height-1
    For x = 0 To *Stack\Width-6
      If Random(4) > 2
        WriteStackXY(*Stack, x, y, 32)
      EndIf
    Next
  Next
EndProcedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Global *FigureLoaded
Global *Stack.STACK = CreateStack(16, 16)
Global LastFigureWasRandom.b = #False
NewList AllFiguresList.FigureItem()

Define Event.i
Define LastTrackBarPos.i = -1
Define LastListItem.i = -1
Define SelectedItem.i

AddElement(AllFiguresList())
AllFiguresList()\Name = "T"
AllFiguresList()\Figure = *TFigure
AddElement(AllFiguresList())
AllFiguresList()\Name = "L"
AllFiguresList()\Figure = *LFigure
AddElement(AllFiguresList())
AllFiguresList()\Name = "F"
AllFiguresList()\Figure = *FFigure
AddElement(AllFiguresList())
AllFiguresList()\Name = "Z"
AllFiguresList()\Figure = *ZFigure
AddElement(AllFiguresList())
AllFiguresList()\Name = "S"
AllFiguresList()\Figure = *SFigure
AddElement(AllFiguresList())
AllFiguresList()\Name = "I"
AllFiguresList()\Figure = *IFigure
AddElement(AllFiguresList())
AllFiguresList()\Name = "O"
AllFiguresList()\Figure = *OFigure

OpenWindow_0()
FillStackWithShit(*Stack)
LoadFigure(*TFigure)
LoadFiguresList(AllFiguresList())

Repeat
  Event = WindowEvent()
  
  If EventType() = #PB_EventType_MouseMove
    Continue
  EndIf
  
  If EventGadget() = TrackBar_0
    If GetGadgetState(TrackBar_0) <> LastTrackBarPos
      LastTrackBarPos = GetGadgetState(TrackBar_0)
      OnTrackbarUpdate()
    EndIf
  EndIf
  
  If EventType() = #PB_EventType_LeftClick
    Select EventGadget()     
      Case Button_0
        OnResetButtonDown()
        
      Case Button_2
        RotateAndRender(#False)
        
      Case Button_3
        RotateAndRender(#True)
        
      Case Button_4
        SetDefaultFrame()
        
      Case Button_8
        LoadRandomFigure()
        
      Case Button_mvUp
        MoveFigure(0, -1)
        
      Case Button_mvDown
        MoveFigure(0, 1)
        
      Case Button_mvLeft
        MoveFigure(-1, 0)
        
      Case Button_mvRight
        MoveFigure(1, 0)
        
      Case ListView_0
        SelectedItem = GetGadgetState(ListView_0)
        If SelectedItem <> -1 And SelectedItem <> LastListItem
          LastFigureWasRandom = #False
          LoadFigure(GetGadgetItemData(ListView_0, SelectedItem))
        EndIf
    EndSelect
  EndIf
  
  ;{ CONTROL FROM KEYBOARD
  If GetAsyncKeyState_(#VK_LEFT)
    MoveFigure(-1, 0)
    Delay(50)
  EndIf
  If GetAsyncKeyState_(#VK_RIGHT)
    MoveFigure(1, 0)
    Delay(50)
  EndIf
  If GetAsyncKeyState_(#VK_UP)
    MoveFigure(0, -1)
    Delay(50)
  EndIf
  If GetAsyncKeyState_(#VK_DOWN)
    MoveFigure(0, 1)
    Delay(50)
  EndIf
  If GetAsyncKeyState_(#VK_Q)
    RotateAndRender(#False)
    Delay(50)
  ElseIf GetAsyncKeyState_(#VK_E)
    RotateAndRender(#True)
    Delay(50)
  EndIf
  If GetAsyncKeyState_(#VK_R)
    LoadRandomFigure()
    Delay(50)
  EndIf
  ;}
  
  If Not Window_0_Events(Event)
    Break
  EndIf 
ForEver
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; CursorPosition = 248
; FirstLine = 231
; Folding = ----
; EnableUnicode
; EnableXP