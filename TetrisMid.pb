XIncludeFile "TetrisLow.pb"

DeclareModule TetrisMid
  UseModule TetrisLow
  
  ;- КОНСТАНТЫ          
  #TETRIS_STACK_WIDTH = 10
  #TETRIS_STACK_HEIGHT = 20
  #TETRIS_STACK_OVERFLOW = 3
  #TETRIS_QUEUE_SIZE = 3  ; РАЗМЕР ОЧЕРЕДИ ФИГУР (МАКС. КОЛ-ВО ФИГУР В ОЧЕРЕДИ)
  ; НАПРАВЛЕНИЯ ТОЛКАНИЯ ФИГУРЫ
  #PULL_LEFT = -1
  #PULL_RIGHT = 1
  #PULL_DOWN = 0
  
  ; =================================================================================
  ;-                               ОБЪЯВЛЕНИЯ СТРУКТУР                               
  ; =================================================================================
  
  Structure GAME
    *Stack.STACK
    *Figure.FIGURE
    *FigureInPocket.FIGURE
    Array *Queue.FIGURE(#TETRIS_QUEUE_SIZE - 1)
    PocketIsUsed.b
    RenderArea.RECT
    isOver.b
    CleanedLines.a
    Level.a
    Score.l
  EndStructure
  
  ; =================================================================================
  ;-                               ОБЪЯВЛЕНИЯ ПРОЦЕДУР                               
  ; =================================================================================
  
  ; СОЗДАЕТ ИГРУ
  ; @Returns: *Game.GAME
  Declare CreateGame()
  
  ; ОБНУЛЯЕТ ВСЕ СЧЕТЧИКИ ИГРЫ (ОЧИЩАЕТ СТАКАН, ПЕРЕСОЗДАЕТ ОЧЕРЕДЬ И Т.Д.)
  ; @Returns: None
  Declare ResetGame(*Game.GAME)
  
  ; ОБРАБАТЫВАЕТ СОБЫТИЕ ВРАЩЕНИЯ
  ; @Returns: #True ЕСЛИ ВРАЩЕНИЕ УДАЛОСЬ, ИНАЧЕ #False
  Declare GameAction_Rotate(*Game.GAME, RotateLeft.b = #True)
  
  ; ОБРАБАТЫВАЕТ СОБЫТИЕ ТОЛКАНИЯ ФИГУРЫ ВЛЕВО/ВПРАВО/ВНИЗ
  ; ПАРАМЕТР Direction ПРИНИМАЕТ ЗНАЧЕНИЯ #PULL_LEFT, #PULL_RIGHT, #PULL_DOWN
  ; @Returns: #True ЕСЛИ ТОЛКАНИЕ УДАЛОСЬ, ИНАЧЕ #False
  Declare GameAction_Pull(*Game.GAME, Direction.b)
  
  ; ЗАПУСКАЕТ СЛЕДУЮЩУЮ ФИГУРУ ИЗ ОЧЕРЕДИ И ДВИГАЕТ ОЧЕРЕДЬ
  ; ДОБАВЛЯЕТ В КОНЕЦ ОЧЕРЕДИ СЛУЧАЙНУЮ ФИГУРУ
  ; УСТАНАВЛИВАЕТ *Game\PocketIsUsed В #False
  ; @Returns: None
  Declare LaunchNextAndProcessQueue(*Game.GAME)
  
  ; ОБРАБАТЫВАЕТ СОБЫТИЕ ПОМЕЩЕНИЯ ФИГУРЫ В КАРМАН
  ; @Returns: #True ЕСЛИ ФИГУРА БЫЛА ПОМЕЩЕНА В КАРМАН, ИНАЧЕ #False
  Declare GameAction_Pocket(*Game.GAME)
  
  ; ОБРАБАТЫВАЕТ СОБЫТИЕ БЫСТРОГО БРОСАНИЯ ФИГУРЫ
  ; (ТЕХНИЧЕСКИ, ПРОСТО ДЕЛАЕТ ВЫСОТУ ФИГУРЫ РАВНОЙ ВЫСОТЕ ЕЕ ТЕНИ)
  ; @Returns: #True
  Declare GameAction_HardDrop(*Game.GAME)
  
  Declare FinishFallAndBurnLines(*Game.GAME, List BurnedY.a())
  ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  Global Dim *FiguresList.FIGURE (6)
EndDeclareModule



Module TetrisMid
  UseModule TetrisLow
  
  NewMap DefaultFigureBytes.BLOCK()
  AddMapElement(DefaultFigureBytes(), "!")
  DefaultFigureBytes()\id = $4F
  AddMapElement(DefaultFigureBytes(), "@")
  DefaultFigureBytes()\id = $52
  AddMapElement(DefaultFigureBytes(), "#")
  DefaultFigureBytes()\id = $63
  AddMapElement(DefaultFigureBytes(), "$")
  DefaultFigureBytes()\id = $74
  AddMapElement(DefaultFigureBytes(), "%")
  DefaultFigureBytes()\id = $85
  AddMapElement(DefaultFigureBytes(), "^")
  DefaultFigureBytes()\id = $96
  AddMapElement(DefaultFigureBytes(), "&")
  DefaultFigureBytes()\id = $A7
  AddMapElement(DefaultFigureBytes(), "+")
  DefaultFigureBytes()\id = $DA
  
  *FiguresList(0) = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "!!! ! "))
  *FiguresList(1) = CreateFigureAuto(CreateFrameFromS(4, 1, DefaultFigureBytes(), "@@@@"))
  *FiguresList(2) = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "####  "))
  *FiguresList(3) = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "$$$  $"))
  *FiguresList(4) = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "%%  %%"))
  *FiguresList(5) = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), " ^^^^ "))
  *FiguresList(6) = CreateFigureAuto(CreateFrameFromS(2, 2, DefaultFigureBytes(), "&&&&"))
  
  ; ПОДГОТАВЛИВАЕТ ФИГУРУ К НАЧАЛУ ПАДЕНИЯ И ДЕЛАЕТ ЕЕ ТЕКУЩЕЙ
  Procedure _LaunchFigure(*Game.GAME, *Figure.FIGURE)
    *Figure\Frame = *Figure\DefaultFrame
    *Figure\Y = #TETRIS_STACK_OVERFLOW-1
    *Figure\X = *Game\Stack\Width / 2  -  *Figure\Frame\Width / 2
    *Game\Figure = *Figure
    CalcShadowCoord(*Game\Figure, *Game\Stack)
    ; СЛЕДУЮЩИЙ КОД БУДЕТ ПРИПОДНИМАТЬ ФИГУРУ В ЗОНУ ПЕРЕПОЛНЕНИЯ,
    ; ЕСЛИ СТАКАН УЖЕ ПОЧТИ ПЕРЕПОЛНЕН
    While *Figure\ShadowY = *Figure\Y
      If *Figure\Y > 0
        *Figure\Y - 1
        CalcShadowCoord(*Figure, *Game\Stack)
      Else
        Break
      EndIf
    Wend
  EndProcedure
  
  ; ВОЗВРАЩАЕТ СЛУЧАЙНУЮ ФИГУРУ ИЗ СПИСКА
  Procedure _GetRandomFigure()
    ProcedureReturn *FiguresList(Random(ArraySize(*FiguresList())))
  EndProcedure
  
  ; ЗАПОЛНЯЕТ ОЧЕРЕДЬ СЛУЧАЙНЫМИ ФИГУРАМИ
  Procedure _FillRandomQueue(*Game.GAME)
    Protected i.i
    
    For i = 0 To #TETRIS_QUEUE_SIZE - 1
      *Game\Queue(i) = _GetRandomFigure()
    Next
  EndProcedure
  
  Procedure.s _DebugStack(*Stack.STACK)
    Protected.a x, y
    Protected str$, blk.BLOCK
    
    For y = 0 To *Stack\Height-1
      For x = 0 To *Stack\Width-1
        blk\id = ReadStackXY(*Stack, x, y)
        If Len(Hex(blk\id)) = 1
          str$ + "0" + Hex(blk\id) + " "
        Else
          str$ + Hex(blk\id) + " "
        EndIf
      Next
      str$ + #CRLF$
    Next
    ProcedureReturn str$
  EndProcedure
  
  
  Procedure CreateGame()
    Protected *Game.GAME
    Protected StackHeight = #TETRIS_STACK_HEIGHT + #TETRIS_STACK_OVERFLOW
    
    *Game = AllocateStructure(*Game)
    *Game\Stack = CreateStack(#TETRIS_STACK_WIDTH, StackHeight)
    With *Game\RenderArea
      \top = #TETRIS_STACK_OVERFLOW
      \left = 0
      \right = #TETRIS_STACK_WIDTH - 1
      \bottom = StackHeight - 1
    EndWith
    ResetGame(*Game)
    
    ProcedureReturn *Game
  EndProcedure
  
  
  Procedure ResetGame(*Game.GAME)
    *Game\CleanedLines = 0
    *Game\Level = 1
    *Game\Score = 0
    *Game\Figure = 0
    *Game\FigureInPocket = 0
    *Game\PocketIsUsed = #False
    *Game\isOver = 0
    _FillRandomQueue(*Game)
    ClearStack(*Game\Stack)
  EndProcedure
  
  
  Procedure GameAction_Rotate(*Game.GAME, RotateLeft.b = #True)
    If IsRotationPossible(*Game\Figure, *Game\Stack, RotateLeft) = 1
      RotateWithCentering(*Game\Figure, *Game\Stack, RotateLeft)
      CalcShadowCoord(*Game\Figure, *Game\Stack)
      ProcedureReturn #True
    EndIf
    ProcedureReturn #False
  EndProcedure
  
  
  Procedure GameAction_Pull(*Game.GAME, Direction.b)
    Protected DeltaX.b, DeltaY.b
    
    Select Direction
      Case #PULL_LEFT
        DeltaX = -1
      Case #PULL_RIGHT
        DeltaX = 1
      Case #PULL_DOWN
        DeltaY = 1
      Default
        ProcedureReturn #False
    EndSelect
    
    If IsMovePossible(*Game\Figure, *Game\Stack, DeltaX, DeltaY)
      *Game\Figure\X + DeltaX
      *Game\Figure\Y + DeltaY
      CalcShadowCoord(*Game\Figure, *Game\Stack)
      ProcedureReturn #True
    EndIf
    ProcedureReturn #False
  EndProcedure
  
  
  Procedure LaunchNextAndProcessQueue(*Game.GAME)
    Protected i.i
    _LaunchFigure(*Game, *Game\Queue(0))
    *Game\PocketIsUsed = #False
    
    If #TETRIS_QUEUE_SIZE > 1
      For i = 0 To #TETRIS_QUEUE_SIZE - 2
        *Game\Queue(i) = *Game\Queue(i+1)
      Next
    EndIf
    *Game\Queue(#TETRIS_QUEUE_SIZE-1) = _GetRandomFigure()
  EndProcedure
  
  
  Procedure GameAction_Pocket(*Game.GAME)
    If *Game\PocketIsUsed
      ProcedureReturn #False
    Else
      *Game\PocketIsUsed = #True
      ; ЕСЛИ В КАРМАНЕ УЖЕ ЕСТЬ ФИГУРА - МЕНЯЕМ МЕСТАМИ С ТЕКУЩЕЙ
      If *Game\FigureInPocket
        Swap *Game\Figure, *Game\FigureInPocket
        _LaunchFigure(*Game, *Game\Figure)
      Else
        ; ИНАЧЕ ЛОЖИМ ТЕКУЩУЮ В КАРМАН И БЕРЕМ СЛЕДУЮЩУЮ ИЗ ОЧЕРЕДИ
        *Game\FigureInPocket = *Game\Figure
        LaunchNextAndProcessQueue(*Game)
      EndIf
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  
  Procedure GameAction_HardDrop(*Game.GAME)
    *Game\Figure\Y = *Game\Figure\ShadowY
    ProcedureReturn #True
  EndProcedure
  
  
  Procedure FinishFallAndBurnLines(*Game.GAME, List BurnedY.a())
    Protected StartY.i, EndY.i, Result.a, beforeburn$
    MergeWithStack(*Game\Figure, *Game\Stack)
    If *Game\Figure\Y + *Game\Figure\Frame\Height - 1 <= #TETRIS_STACK_OVERFLOW
      ProcedureReturn -1
    EndIf
    ; РАСЧИТЫВАЕМ НАЧАЛЬНУЮ И КОНЕЧНУЮ ЛИНИЮ ДЛЯ ПРОВЕРКИ ЗАПОЛНЕНИЯ
    StartY = *Game\Figure\Y
    EndY = StartY + *Game\Figure\Frame\Height - 1
    beforeburn$ = _DebugStack(*Game\Stack)
    Result = BurnFilledLines(*Game\Stack, BurnedY(), StartY, EndY)
;     If Result
;       Debug "BEFORE BURN: "
;       Debug beforeburn$
;       Debug "AFTER BURN: "
;       Debug _DebugStack(*Game\Stack)
;       Debug "=========================================="
;     EndIf
    ; TODO: СЛЕДУЮЩИЕ ВЫЧИСЛЕНИЯ ДОЛЖНЫ ВЫПОЛНЯТЬСЯ В ОТДЕЛЬНОЙ ПРОЦЕДУРЕ
    If Result
      *Game\CleanedLines + Result
      *Game\Score + Pow(Result, 1.5) * *Game\Level
      *Game\Level + Abs(*Game\CleanedLines / 45) + 1
      If *Game\Level > 15 : *Game\Level = 15 : EndIf
    EndIf
    LaunchNextAndProcessQueue(*Game)
    ProcedureReturn Result
  EndProcedure
  
EndModule
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; CursorPosition = 284
; FirstLine = 248
; Folding = ---
; EnableUnicode
; EnableXP
; EnablePurifier = 1,1,1,1