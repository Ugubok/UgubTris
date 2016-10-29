XIncludeFile "TetrisMid.pb"
XIncludeFile "TetrisLow.pb"

DeclareModule TetroRender
  UseModule TetrisMid
  UseModule TetrisLow
  
  Enumeration CON_CL
    #CL_BLACK
    #CL_BLUE
    #CL_GREEN
    #CL_CYAN
    #CL_RED
    #CL_MAGENTA
    #CL_BROWN
    #CL_LIGHT_GRAY
    #CL_DARK_GRAY
    #CL_BRIGHT_BLUE
    #CL_BRIGHT_GREEN
    #CL_BRIGHT_CYAN
    #CL_BRIGHT_RED
    #CL_BRIGHT_MAGENTA
    #CL_YELLOW
    #CL_WHITE
  EndEnumeration
  
  Enumeration B_TEX
    #BL_EMPTY
    #BL_PUPIRKA
    #BL_GLASS
    #BL_STRONG
    #BL_CHESS
    #BL_WEAK
    #BL_SHADOW
    #BL_RANDOM
  EndEnumeration
  
  #STACK_X = 4
  #STACK_Y = 2
  #POCKETWIN_X = #STACK_X + 24
  #POCKETWIN_Y = #STACK_Y
  #POCKETWIN_H = 2
  #POCKETWIN_W = 12
  #QUEUEWIN_X  = #STACK_X + 24
  #QUEUEWIN_Y  = #STACK_Y + 5
  #QUEUEWIN_H  = 8
  #QUEUEWIN_W  = 12
  
  #SMALL_BLK$ = "■ "  
  
  ;- PROC DECLARATIONS
  Declare InitTetroRender()
  Declare RenderFigure(*Figure.FIGURE, Texture.a = #BL_RANDOM)
  Declare RenderStack(*Stack.STACK)
  Declare RenderQueue(*Game.GAME)
  Declare RenderPocket(*Game.GAME)
  Declare AnimateLinesBurning(List BurnedY.a())
EndDeclareModule




Module TetroRender
  UseModule TetrisMid
  UseModule TetrisLow
  
  Global Dim _BlockTexture.s{2}(7)
  _BlockTexture(#BL_EMPTY)   = "  "
  _BlockTexture(#BL_PUPIRKA) = "▄▓"
  _BlockTexture(#BL_GLASS)   = "▓▒"
  _BlockTexture(#BL_STRONG)  = "█▓"
  _BlockTexture(#BL_CHESS)   = "▄▀"
  _BlockTexture(#BL_WEAK)    = "▒▒"
  _BlockTexture(#BL_SHADOW)  = "┌┐"
  
  Global NewMap blk2Texture.a()
  
  Procedure _DrawRect(X.a, Y.a, Width.a, Height.a, Color.a=#CL_WHITE, bgColor.a=#CL_BLACK)
    Protected i.i
    
    ConsoleColor(Color, bgColor)
    ConsoleLocate(X, Y)
    Print("╔")
    For i = 1 To Width : Print("═") : Next
    Print("╗")
    For i = 0 To Height
      ConsoleLocate(X, Y+i+1)
      Print("║")
      ConsoleLocate(X+Width+1, Y+i+1)
      Print("║")
    Next
    ConsoleLocate(X, Y+i+1)
    Print("╚")
    For i = 1 To Width : Print("═") : Next
    Print("╝")
  EndProcedure
  
  Procedure _DrawWindow(X.a, Y.a, Width.a, Height.a, Title$, Color.a=#CL_WHITE)
    Protected.a i, j
    ConsoleLocate(X+1, Y+Height+2)
    ConsoleColor(#CL_DARK_GRAY, #CL_BLACK)
    For i = 0 To Width+1 : Print("▀") : Next
    For i = Y To Y+Height+1
      ConsoleLocate(X+Width+2, i)
      If i = Y
        Print("▄")
      Else
        Print("█")
      EndIf
    Next
    ConsoleColor(#CL_BLACK, Color)
    For i = Y To Y+Height
      ConsoleLocate(X, i)
      For j = 0 To Width : Print(" ") : Next
    Next
    _DrawRect(X, Y, Width, Height-1, #CL_BLACK, Color)
    
    ConsoleLocate(X + Width/2 - Len(Title$)/2 + 1, Y)
    Print(Title$)
  EndProcedure
  
  Procedure _CleanWindow(X.a, Y.a, Width.a, Height.a, Color.a=#CL_WHITE)
    Protected.a i, j
    
    ConsoleColor(#CL_BLACK, Color)
    For i = Y+1 To Y+Height
      ConsoleLocate(X+1, i)
      For j = 0 To Width-1 : Print(" ") : Next
    Next
  EndProcedure
  
  Procedure _DrawStackBlock(X.a, Y.i, Texture.a, Color.a, bgColor.a=#CL_BLACK)
    If Y < #TETRIS_STACK_OVERFLOW-1
      ProcedureReturn
    EndIf
    Y - (#TETRIS_STACK_OVERFLOW-1)
    ConsoleColor(Color, bgColor)
    ConsoleLocate(#STACK_X + X*2, #STACK_Y + Y)
    Print(_BlockTexture(Texture))
  EndProcedure
  
  
  Procedure _DrawWindowBorders()
    Protected.a i, x, y, RenderX, RenderY
    
    _DrawRect(#STACK_X-1, #STACK_Y-1, 20, 20)
    _DrawRect(#STACK_X + 22, #STACK_Y-1, 16, 20, #CL_DARK_GRAY)
    _DrawWindow(#POCKETWIN_X, #POCKETWIN_Y, #POCKETWIN_W, #POCKETWIN_H, "[ POCKET ]")
    _DrawWindow(#QUEUEWIN_X, #QUEUEWIN_Y, #QUEUEWIN_W, #QUEUEWIN_H, "[ NEXT ]")
  EndProcedure
  
  
  Procedure _DrawSmallFigureFrame(*Frame.FigureFrame, X.a, Y.a, Color.a=#CL_BLACK, bgColor.a=#CL_WHITE)
    Protected.a i, j
    Protected blk.BLOCK
    
    ConsoleColor(Color, bgColor)
    For i = 0 To *Frame\Height-1
      For j = 0 To *Frame\Width-1
        blk\id = ReadFrameXY(*Frame, j, i)
        If blk\id
          ConsoleLocate(X+j*Len(#SMALL_BLK$), Y+i)
          Print(#SMALL_BLK$)
        EndIf
      Next
    Next
  EndProcedure
  
  
  Procedure InitTetroRender()
    OpenConsole("UGUBTRIS 0.0000009e-1337")
    EnableGraphicalConsole(1)
    _DrawWindowBorders()
  EndProcedure
  
  
  Procedure RenderQueue(*Game.GAME)
    Protected.a i, x, y
    Protected *F.FIGURE
    
    _CleanWindow(#QUEUEWIN_X, #QUEUEWIN_Y, #QUEUEWIN_W, #QUEUEWIN_H)
    For i = 0 To #TETRIS_QUEUE_SIZE-1
      *F = *Game\Queue(i)
      x = #QUEUEWIN_X + #QUEUEWIN_W/2 - *F\DefaultFrame\Width/2
      _DrawSmallFigureFrame(*F\DefaultFrame, x, #QUEUEWIN_Y+1+y)
      y + *F\DefaultFrame\Height + 1
    Next
  EndProcedure
  
  
  Procedure RenderPocket(*Game.GAME)
    Protected x.a
    If *Game\FigureInPocket
      _CleanWindow(#POCKETWIN_X, #POCKETWIN_Y, #POCKETWIN_W, #POCKETWIN_H)
      x = #POCKETWIN_X + #POCKETWIN_W/2 - *Game\FigureInPocket\Frame\Width/2
      _DrawSmallFigureFrame(*Game\FigureInPocket\DefaultFrame, x, #POCKETWIN_Y + 1)
    EndIf
  EndProcedure
  
  
  Procedure RenderFigure(*Figure.FIGURE, Texture.a = #BL_RANDOM)
    Protected.a x, y, Color, bgColor, blk2texChecked
    Protected blk.BLOCK
    Static NewMap RndTextureCache.a()
    
    If Texture = #BL_RANDOM
      If Not RndTextureCache(Hex(*Figure))
        Texture = Random(#BL_RANDOM-1, #BL_EMPTY+1)
        RndTextureCache(Hex(*Figure)) = Texture
      Else
        Texture = RndTextureCache(Hex(*Figure))
      EndIf
    EndIf
    If Texture = #BL_EMPTY
      Color = #CL_BLACK
      bgColor = #CL_BLACK
    EndIf
    For y = 0 To *Figure\Frame\Height-1
      For x = 0 To *Figure\Frame\Width-1
        blk\id = ReadFrameXY(*Figure\Frame, x, y)
        If blk\id
          If Texture <> #BL_EMPTY
            Color = blk\id & $0F
            bgColor = (blk\id & $F0) >> 4
            If Not blk2texChecked
              If Not blk2Texture(Hex(blk\id))
                blk2Texture(Hex(blk\id)) = Texture
              EndIf
              blk2texChecked = 1
            EndIf
          EndIf
          ; SHADOW FIRST!
          _DrawStackBlock(*Figure\X+x, *Figure\ShadowY+y, #BL_SHADOW, Color)
          _DrawStackBlock(*Figure\X+x, *Figure\Y+y, Texture, Color, bgColor)
        EndIf
      Next
    Next
  EndProcedure
  
  
  Procedure RenderStack(*Stack.STACK)
    Protected.a x, y, Texture, Color, bgColor
    Protected blk.BLOCK
    
    For y = #TETRIS_STACK_OVERFLOW-1 To *Stack\Height-1
      For x = 0 To *Stack\Width-1
        blk\id = ReadStackXY(*Stack, x, y)
        If blk\id
          Texture = blk2Texture(Hex(blk\id))
          If Not Texture : Texture = #BL_STRONG : EndIf
          Color = blk\id & $0F
          bgColor = (blk\id & $F0) >> 4
          _DrawStackBlock(x, y, Texture, Color, bgColor)
        Else
          _DrawStackBlock(x, y, #BL_EMPTY, #CL_BLACK)
        EndIf
      Next
    Next
  EndProcedure
  
  
  Procedure AnimateLinesBurning(List BurnedY.a())
    Protected.a x, y
    For x = 0 To 18
      ForEach BurnedY()
        If BurnedY() < #TETRIS_STACK_OVERFLOW-1
          Break
        EndIf
        y = BurnedY() - (#TETRIS_STACK_OVERFLOW-1)
        ConsoleColor(#CL_YELLOW, #CL_RED)
        ConsoleLocate(#STACK_X + X, #STACK_Y + Y)
        Print("▒▓")
      Next
      Delay(20)
    Next
  EndProcedure
  
EndModule
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; CursorPosition = 273
; FirstLine = 237
; Folding = ---
; EnableUnicode
; EnableXP