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
    Level.a
    Score.l
  EndStructure
  
  ; =================================================================================
  ;-                               ОБЪЯВЛЕНИЯ ПРОЦЕДУР                               
  ; =================================================================================
  
  ; СОЗДАЕТ ИГРУ
  ; @Returns: Game.GAME
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
  ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  Global Dim *FiguresList.FIGURE (6)
EndDeclareModule



Module TetrisMid
  IncludeFile "DefaultFigures.pb"
  CopyArray(*DefaultFigures(), *FiguresList())
  UseModule TetrisLow
  
  ; ПОДГОТАВЛИВАЕТ ФИГУРУ К НАЧАЛУ ПАДЕНИЯ И ДЕЛАЕТ ЕЕ ТЕКУЩЕЙ
  Procedure _LaunchFigure(*Game.GAME, *Figure.FIGURE)
    *Figure\Frame = *Figure\DefaultFrame
    *Figure\Y = #TETRIS_STACK_OVERFLOW
    *Figure\X = *Game\Stack\Width / 2  -  *Figure\Frame\Width / 2
    *Game\Figure = *Figure
  EndProcedure
  
  ; ВОЗВРАЩАЕТ СЛУЧАЙНУЮ ФИГУРУ ИЗ СПИСКА
  Procedure _GetRandomFigure()
    ProcedureReturn *FiguresList(Random(ArraySize(*FiguresList()) - 1))
  EndProcedure
  
  ; ЗАПОЛНЯЕТ ОЧЕРЕДЬ СЛУЧАЙНЫМИ ФИГУРАМИ
  Procedure _FillRandomQueue(*Game.GAME)
    Protected i.i
    
    For i = 0 To #TETRIS_QUEUE_SIZE - 1
      *Game\Queue(i) = _GetRandomFigure()
    Next
  EndProcedure
  
  
  Procedure CreateGame()
    Protected Game.GAME
    Protected StackHeight = #TETRIS_STACK_HEIGHT + #TETRIS_STACK_OVERFLOW
    
    Game\Stack = CreateStack(#TETRIS_STACK_WIDTH, StackHeight)
    With Game\RenderArea
      \top = #TETRIS_STACK_OVERFLOW
      \left = 0
      \right = #TETRIS_STACK_WIDTH - 1
      \bottom = StackHeight - 1
    EndWith
    ResetGame(Game)
    
    ProcedureReturn Game
  EndProcedure
  
  
  Procedure ResetGame(*Game.GAME)
    *Game\Level = 1
    *Game\Score = 0
    *Game\Figure = 0
    *Game\FigureInPocket = 0
    *Game\PocketIsUsed = #False
    _FillRandomQueue(*Game)
    ClearStack(*Game\Stack)
  EndProcedure
  
  
  Procedure GameAction_Rotate(*Game.GAME, RotateLeft.b = #True)
    If IsRotationPossible(*Game\Figure, *Game\Stack, RotateLeft) = 1
      RotateWithCentering(*Game\Figure, *Game\Stack, RotateLeft)
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
  
EndModule
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; CursorPosition = 13
; Folding = --
; EnableUnicode
; EnableXP
; EnablePurifier = 1,1,1,1