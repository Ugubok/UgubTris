EnableExplicit

XIncludeFile "TetrisMid.pb"
XIncludeFile "TetroRender.pb"

UseModule TetrisMid
UseModule TetroRender


Define *Game.GAME = CreateGame()
Define StartTime.q = ElapsedMilliseconds()
Define.i IterStart, IterTime, TimeFromLastStep, LastInputTime
Define.b NextStepIsFinal, FallFinished, isPaused
Define.b BurningResult, LastLevel=1
NewList BurnedY.a()
;- RATES
Define.w StepRate = 400  ; ВРЕМЯ В МС, ЗА КОТОРОЕ ФИГУРА ОПУСТИТСЯ ВНИЗ
Define.w MaxCorrectionTime = 2000  ; МАКСИМАЛЬНОЕ ВРЕМЯ НА КОРРЕКТИРОВАНИЕ КОГДА ФИГУРА УЖЕ ПРИЗЕМЛИЛАСЬ

InitTetroRender()
RenderQueue(*Game)
Repeat
  If *Game\isOver
    RenderGameOver()
    If GetAsyncKeyState_(#VK_RETURN)
      ResetGame(*Game)
      LastLevel = 1
      StepRate = 400
      RenderStack(*Game\Stack)
      RenderQueue(*Game)
      RenderPocket(*Game)
      Continue
    EndIf
    Delay(300)
    Continue
  EndIf
  
  If isPaused
    If GetAsyncKeyState_(#VK_PAUSE)
      isPaused = 0
    EndIf
    Delay(300)
    Continue
  EndIf
  
  IterStart = ElapsedMilliseconds()
  If Not *Game\Figure
    LaunchNextAndProcessQueue(*Game)
    RenderQueue(*Game)
    RenderCaptions(*Game)
  EndIf
  ;{  KEYBOARD CONTROLS
  If GetAsyncKeyState_(#VK_SHIFT)
    RenderFigure(*Game\Figure, #BL_EMPTY)
    If GameAction_Pocket(*Game)
      RenderPocket(*Game)
      RenderQueue(*Game)
      Continue
    EndIf
  EndIf
  If GetAsyncKeyState_(#VK_PAUSE)
    isPaused = 1
    Continue
  EndIf
  If GetAsyncKeyState_(#VK_LEFT)
    LastInputTime = ElapsedMilliseconds()
    RenderFigure(*Game\Figure, #BL_EMPTY)
    GameAction_Pull(*Game, #PULL_LEFT)
  EndIf
  If GetAsyncKeyState_(#VK_RIGHT)
    LastInputTime = ElapsedMilliseconds()
    RenderFigure(*Game\Figure, #BL_EMPTY)
    GameAction_Pull(*Game, #PULL_RIGHT)
  EndIf
  If GetAsyncKeyState_(#VK_DOWN)
    LastInputTime = ElapsedMilliseconds()
    RenderFigure(*Game\Figure, #BL_EMPTY)
    GameAction_Pull(*Game, #PULL_DOWN)
  EndIf
  If GetAsyncKeyState_(#VK_UP)
    LastInputTime = ElapsedMilliseconds()
    RenderFigure(*Game\Figure, #BL_EMPTY)
    GameAction_Rotate(*Game, #False)
  EndIf
  If GetAsyncKeyState_(#VK_Z)
    LastInputTime = ElapsedMilliseconds()
    RenderFigure(*Game\Figure, #BL_EMPTY)
    GameAction_Rotate(*Game)
  EndIf
  If GetAsyncKeyState_(#VK_SPACE)
    LastInputTime = ElapsedMilliseconds()
    RenderFigure(*Game\Figure, #BL_EMPTY)
    GameAction_HardDrop(*Game)
    FallFinished = 1
  EndIf
  ;}
  
  TimeFromLastStep + IterTime
  If TimeFromLastStep > StepRate
    RenderFigure(*Game\Figure, #BL_EMPTY)
    If GameAction_Pull(*Game, #PULL_DOWN)  ; УСПЕШНО ПАДАЕМ БЕЗ СТОЛКНОВЕНИЙ
      TimeFromLastStep = 0
      NextStepIsFinal = 0
    Else  ; СТОЛКНУЛИСЬ
      If NextStepIsFinal
        ; ЧЮВАК ПЫТАЕТСЯ КОРРЕКТИРОВАТЬ
        If (ElapsedMilliseconds() - LastInputTime) < StepRate
          ; ВРЕМЯ НА КОРРЕКТИРОВКУ ВЫШЛО
          If TimeFromLastStep > MaxCorrectionTime
            FallFinished = 1
          EndIf
        Else  ; ЧЮВАК НЕ ПЫТАЛСЯ КОРРЕКТИРОВАТЬ
          FallFinished = 1
        EndIf
      Else
        NextStepIsFinal = 1
      EndIf
    EndIf
  EndIf
  
  If FallFinished
    FallFinished = 0
    NextStepIsFinal = 0
    TimeFromLastStep = 0
    RenderFigure(*Game\Figure)
    BurningResult = FinishFallAndBurnLines(*Game, BurnedY())
    If BurningResult > 0
      AnimateLinesBurning(BurnedY())
      RenderCaptions(*Game)
      ClearList(BurnedY())
      If *Game\Level > LastLevel
        LastLevel = *Game\Level
        StepRate - 20
      EndIf
    ElseIf BurningResult < 0
      *Game\isOver = 1
    EndIf
    RenderQueue(*Game)
    RenderFigure(*Game\Figure, #BL_EMPTY)
    RenderStack(*Game\Stack)
  EndIf
  RenderFigure(*Game\Figure)
  Delay(100)
  IterTime = ElapsedMilliseconds() - IterStart
ForEver
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; CursorPosition = 27
; FirstLine = 18
; Folding = -
; EnableUnicode
; EnableXP