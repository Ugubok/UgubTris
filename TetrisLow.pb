EnableExplicit


DeclareModule TetrisLow
  ; =================================================================================
  ;-                               ОБЪЯВЛЕНИЯ СТРУКТУР                               
  ; =================================================================================
  
  ; СТАКАН
  Structure STACK
    *Matrix
    Width.a
    Height.a
  EndStructure
  
  ; КАДР - ОПИСЫВАЕТ ОДНО СОСТОЯНИЕ ФИГУРЫ
  Structure FigureFrame
    *NextFrame.FigureFrame
    *PrevFrame.FigureFrame
    *Data
    XCenter.a
    YCenter.a
    Width.a
    Height.a
  EndStructure
  
  ; ФИГУРА СОСТОИТ ИЗ НАБОРА ЗАЦИКЛЕННЫХ КАДРОВ
  ; НАБОР КАДРОВ МОЖЕТ СОСТОЯТЬ ЛИШЬ ИЗ 1 КАДРА
  ; ЗАЦИКЛЕННОСТЬ КАДРОВ ОЗНАЧАЕТ ЧТО \NextFrame ПОСЛЕДНЕГО КАДРА УКАЗЫВАЕТ НА ПЕРВЫЙ
  Structure FIGURE
    *Frame.FigureFrame
    *DefaultFrame.FigureFrame
    X.a
    Y.a
  EndStructure
  ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  ; =================================================================================
  ;-                               ОБЪЯВЛЕНИЯ ПРОЦЕДУР                               
  ; =================================================================================
  
  ; СОЗДАЕТ И ИНИЦИАЛИЗИРУЕТ СТАКАН (СТРУКУТУРУ STACK) УКАЗАННЫХ РАЗМЕРОВ
  ; @Returns: *STACK
  Declare CreateStack(Width.a, Height.a)
  
  ; ОСВОБОЖДАЕТ ПАМЯТЬ ОТ СТРУКТУРЫ STACK
  ; @Returns: None
  Declare FreeStack(*Stack.STACK)
  
  ; СОЗДАЕТ ОДНО СОСТОЯНИЕ ФИГУРЫ (КАДР) ИЗ СТРОКИ
  ; Char2ByteDict ОПРЕДЕЛЯЕТ СООТВЕТСТВИЕ СИМВОЛА В СТРОКЕ String$ БАЙТУ В КАДРЕ
  ; @Returns: *FigureFrame
  Declare CreateFrameFromS(Width.a, Height.a, Map Char2ByteDict.a(), String$)
  
  ; СОЗДАЕТ ОДНО СОСТОЯНИЕ ФИГУРЫ (КАДР) ИЗ МАССИВА
  ; @Returns: *FigureFrame
  Declare CreateFrameFromA(Width.a, Height.a, Array FrameData.a(1))
  
  ;- LinkFrames - СВЯЗЫВАЕТ И ЗАЦИКЛИВАЕ  КАДРЫ ПО ПОРЯДКУ
  ; ЗАЦИКЛИВАЕТ ПЕРВЫЙ И ПОСЛЕДНИЙ МЕЖДУ СОБОЙ
  Declare LinkFrames(*Frame0.FigureFrame, *Frame1.FigureFrame, 
                     *Frame2.FigureFrame = #Null, *Frame3.FigureFrame = #Null)
  
  ;- CreateFigureAuto - СОЗДАЕТ ФИГУРУ ИЗ ЕДИНСТВЕННОГО, "ИНИЦИАЛИЗИРУЮЩЕГО" КАДРА
  ; ИЗ НЕГО СОЗДАЕТ ВСЕ ОСТАЛЬНЫЕ КАДРЫ (ПУТЕМ ПОВОРОТА) И ЗАЦИКЛИВАЕТ ИХ
  ; ИНИЦИАЛИЗИРУЮЩИЙ КАДР СТАНОВИТСЯ ДЕФОЛЬНЫМ ДЛЯ СОЗДАВАЕМОЙ ФИГУРЫ
  ; @Returns: *FIGURE
  Declare CreateFigureAuto(*InitFrame.FigureFrame, SetCenterAuto.b = #True)
  
  ;- CreateFigure - СОЗДАЕТ ФИГУРУ ИЗ ОДНОГО ИЛИ НЕСКОЛЬКИХ ЗАЦИКЛЕННЫХ КАДРОВ
  ; ПЕРЕДАННЫЙ КАДР ИЗ ЭТОГО НАБОРА СТАНОВИТСЯ ДЕФОЛЬНЫМ ДЛЯ СОЗДАВАЕМОЙ ФИГУРЫ
  ; @Returns: *FIGURE
  Declare CreateFigure(*DefaultFrame.FigureFrame, SetCenterAuto.b = #True)
  
  ; ПОВАРАЧИВАЕТ ФИГУРУ ВЛЕВО/ВПРАВО (ТЕХНИЧЕСКИ, ПРОСТО МЕНЯЕТ ТЕКУЩИЙ КАДР)
  ; ЗАТЕМ ОБНОВЛЯЕТ КООРДИНАТУ ФИГУРЫ ТАК, ЧТОБЫ ЦЕНТРЫ КАДРОВ СОШЛИСЬ В ОДНОЙ ТОЧКЕ
  ; ДЛЯ ПРОВЕРКИ ВЫХОДА ЗА ГРАНИЦЫ ПРИШЛОСЬ ДОБАВИТЬ АРГУМЕНТ *Stack
  ; @Returns: 1 ПРИ УСПЕХЕ, 0 ЕСЛИ ПРИ ПОВОРОТЕ КООРДИНАТЫ ВЫШЛИ ЗА ПРЕДЕЛЫ СТАКАНА
  ;           (ЕСЛИ 0 - ПОВОРОТ НЕ БУДЕТ ПРОИЗВЕДЕН)
  Declare RotateWithCentering(*Figure.FIGURE, *Stack.STACK, RotateLeft.b = #True)
  
  ; ПОВОРАЧИВАЕТ ФИГУРУ ВЛЕВО/ВПРАВО, НЕ МЕНЯЯ КООРДИНАТ
  Declare RotateLow(*Figure.FIGURE, RotateLeft.b = #True)
  
  ; ПРОВЕРЯЕТ НЕ НАЛОЖИЛАСЬ ЛИ ФИГУРА НА КАКОЙ-ЛИБО БЛОК В СТАКАНЕ
  ; @Returns: 0 ЕСЛИ НЕ НАЛОЖИЛАСЬ, ЛЮБОЕ ДРУГОЕ ЗНАЧЕНИЕ ЕСЛИ НАЛОЖИЛАСЬ
  Declare CheckCollision(*Figure.FIGURE, *Stack.STACK)
  
  ; ПРОВЕРКА ВОЗМОЖНОСТИ ПОВОРОТА ФИГУРЫ
  ; @Returns: 1 ЕСЛИ ВОЗМОЖНО, 0 ЕСЛИ НЕВОЗМОЖНО ПО ПРИЧИНЕ КОЛЛИЗИИ С БЛОКОМ
  ;           -1 ЕСЛИ НЕВОЗМОЖНО ПО ПРИЧИНЕ ВЫХОДА ЗА ГРАНИЦЫ СТАКАНА
  Declare IsRotationPossible(*Figure.FIGURE, *Stack.STACK, RotateLeft.b = #True)
  
  ; ПРОВЕРЯЕТ ВОЗМОЖНОСТЬ СДВИГА ФИГУРЫ НА УКАЗАННОЕ РАССТОЯНИЕ
  ; УЧИТЫВАЕТ СТОЛКНОВЕНИЯ С БЛОКАМИ И ВЫХОД ЗА ГРАНИЦЫ СТАКАНА
  Declare IsMovePossible(*Figure.FIGURE, *Stack.STACK, DeltaX.b, DeltaY.b)
  
  ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
EndDeclareModule


Module TetrisLow
  
  ; ПРЕДСТАВЛЯЕТ МАССИВ ПАМЯТИ КАК МАТРИЦУ УКАЗАННЫХ РАЗМЕРОВ
  ; СОЗДАЕТ НОВУЮ, ПОВЕРНУЮТУЮ ВЛЕВО/ВПРАВО МАТРИЦУ
  ; @Returns: *Matrix.a
  Procedure _GetRotated90Matrix(MWidth.i, MHeight.i, *SourceMatrix, RotateLeft.a)
    Protected x.i, y.i, i.i
    Protected *Matrix.Byte = AllocateMemory(MWidth * MHeight)
    
    If RotateLeft
      For x = 0 To MWidth-1
        For y = MHeight-1 To 0 Step -1
          PokeA(*Matrix + i, PeekA(*SourceMatrix + MWidth * y + x))
          i + 1
        Next
      Next
    Else
      For x =  MWidth-1 To 0 Step -1
        For y = 0 To MHeight-1
          PokeA(*Matrix + i, PeekA(*SourceMatrix + MWidth * y + x))
          i + 1
        Next
      Next
    EndIf
    
    ProcedureReturn *Matrix
  EndProcedure
  
  
  ; СВЯЗЫВАЕТ ДВА КАДРА БЕЗ ЗАЦИКЛИВАНИЯ
  Procedure _LinkFramesSimple(*Frame0.FigureFrame, *Frame1.FigureFrame)
    *Frame0\NextFrame = *Frame1
    *Frame1\PrevFrame = *Frame0
  EndProcedure
  
  
  ; УСТАНАВЛИВАЕТ ЦЕНТР ФИГУРЕ (ВСЕМ ЕЕ КАДРАМ)
  Procedure _CalcAndSetFigureCenter(*Figure.FIGURE)
    ; КООРДИНАТЫ ЦЕНТРА НАЧИНАЮТСЯ С ЕДИНИЦЫ, 0 СЧИТАЕТСЯ ОТСУТСТВИЕМ ЗНАЧЕНИЯ
    Protected *Frame.FigureFrame = *Figure\DefaultFrame
    ; ПЕРВИЧНАЯ КООРДИНАТА "УГАДЫВАЕТСЯ", ДАЛЬНЕЙШИЕ ВЫЧИСЛЯЮТСЯ ИСХОДЯ ИЗ НЕЕ
    If *Frame\Width % 2
      *Frame\XCenter = Round(*Frame\Width / 2, #PB_Round_Up)
    Else
      *Frame\XCenter = *Frame\Width / 2 + 1
    EndIf
    
    If *Frame\Height = 2
      *Frame\YCenter = 1
    ElseIf *Frame\Height % 2
      *Frame\YCenter = Round(*Frame\Height / 2, #PB_Round_Up)
    Else
      *Frame\YCenter = *Frame\Height / 2 + 1
    EndIf
    
    
    ;While *Frame\NextFrame <> *Figure\DefaultFrame
    ;  *Frame = *Frame\NextFrame
    ;  *Frame\XCenter = *Frame\Width - (*Frame\PrevFrame\YCenter - 1)
    ;  *Frame\YCenter = *Frame\PrevFrame\XCenter
    ;Wend
    While *Frame\PrevFrame <> *Figure\DefaultFrame
     *Frame = *Frame\PrevFrame
     *Frame\XCenter = *Frame\Width - (*Frame\NextFrame\YCenter - 1)
     *Frame\YCenter = *Frame\NextFrame\XCenter
    Wend
    CompilerIf Defined(DEBUG_VERBOSITY_3, #PB_Constant)
      *Frame = *Figure\DefaultFrame
      Debug "TetrisLow::_CalcAndSetFigureCenter: Frame size: " +
            Str(*Frame\Width) + "x" + Str(*Frame\Height) + ", center is (" +
            Str(*Frame\XCenter) + ", " + Str(*Frame\YCenter) + ")"
    CompilerEndIf
  EndProcedure
  
  
  Procedure CreateStack(Width.a, Height.a)
    Protected *Stack.STACK
    *Stack = AllocateStructure(STACK)
    *Stack\Matrix = AllocateMemory(Width * Height)
    *Stack\Width = Width
    *Stack\Height = Height
    ProcedureReturn *Stack
  EndProcedure
  
  
  Procedure FreeStack(*Stack.STACK)
    FreeMemory(*Stack\Matrix)
    FreeStructure(*Stack)
  EndProcedure
  
  
  Procedure CreateFrameFromS(Width.a, Height.a, Map Char2ByteDict.a(), String$)
    Protected Dim FrameData.a(Width * Height)
    Protected i.i
    ; ТРАНСЛИРУЕМ СТРОКУ В МАССИВ БАЙТОВ
    For i = 1 To Len(String$)
      FrameData(i-1) = Char2ByteDict(Mid(String$, i, 1))
    Next
    
    ProcedureReturn CreateFrameFromA(Width, Height, FrameData())
  EndProcedure
  
  
  Procedure CreateFrameFromA(Width.a, Height.a, Array FrameData.a(1))
    Protected *Frame.FigureFrame
    
    *Frame        = AllocateStructure(FigureFrame)
    *Frame\Data   = AllocateMemory(Width * Height)
    *Frame\Width  = Width
    *Frame\Height = Height
    *Frame\NextFrame = *Frame
    *Frame\PrevFrame = *Frame
    
    CopyMemory(@FrameData(0), *Frame\Data, Width * Height)
    ProcedureReturn *Frame
  EndProcedure
  
  
  Procedure LinkFrames(*Frame0.FigureFrame, *Frame1.FigureFrame, 
                       *Frame2.FigureFrame = #Null, *Frame3.FigureFrame = #Null)
    _LinkFramesSimple(*Frame0, *Frame1)
    If *Frame2
      _LinkFramesSimple(*Frame1, *Frame2)
      If *Frame3
        _LinkFramesSimple(*Frame2, *Frame3)
        _LinkFramesSimple(*Frame3, *Frame0)
      Else
        _LinkFramesSimple(*Frame2, *Frame0)
      EndIf
    Else
      _LinkFramesSimple(*Frame1, *Frame0)
    EndIf
  EndProcedure
  
  
  Procedure CreateFigureAuto(*InitFrame.FigureFrame, SetCenterAuto.b = #True)
    Protected *Figure.FIGURE
    Protected *RotatedMatrix
    Protected W.a = *InitFrame\Width, H.a = *InitFrame\Height
    Protected *Frame90.FigureFrame, *Frame180.FigureFrame, *Frame270.FigureFrame
    Protected FrameDataSize = W * H
    
    _LinkFramesSimple(*InitFrame, *InitFrame)
    *Figure = AllocateStructure(FIGURE)
    *Figure\DefaultFrame = *InitFrame
    *Figure\Frame = *InitFrame
    ; ПАПРОБУЕМ КАДР ПОВЕРНУТЫЙ ПО ЧАСОВОЙ СТРЕЛКЕ САЗДАТЬ
    *RotatedMatrix = _GetRotated90Matrix(W, H, *InitFrame\Data, #False)
    ; СОВПАДАЮТ - ЗНАЧИТ ФИГУРА АБСОЛЮТНО СИММЕТРИЧНАЯ И МОЖНО НИЧО НЕ СОЗДАВАТЬ
    If W = H And CompareMemory(*InitFrame\Data, *RotatedMatrix, FrameDataSize)
      FreeMemory(*RotatedMatrix)
      Goto CreateFigureAuto_CreateFramesDone
    EndIf
    ; НЕ СОВПАЛИ - НАДА САЗДАТЬ
    *Frame90 = AllocateStructure(FigureFrame)
    *Frame90\Height  = W
    *Frame90\Width   = H
    *Frame90\Data    = *RotatedMatrix
    LinkFrames(*InitFrame, *Frame90)
    ; ТИПЕРЬ САЗДАДАИМ ПОВЕРНУТУЮ НА 180
    *RotatedMatrix = _GetRotated90Matrix(H, W, *Frame90\Data, #False)
    ; СОВПАДАЮТ - ЗНАЧИТ ФИГРА НАПАЛАВИНУ СИММЕТРИЧНАЯ
    If CompareMemory(*InitFrame\Data, *RotatedMatrix, FrameDataSize)
      FreeMemory(*RotatedMatrix)
      Goto CreateFigureAuto_CreateFramesDone
    EndIf
    ; НЕ СОВПАЛИ - ЗНАЧЕТ ВОПЩЕ НЕ СИММЕТРИЧНАЯ И НАДА САЗДАТЬ ВСЕ 4 КАДРА
    *Frame180 = AllocateStructure(FigureFrame)
    *Frame180\Width  = W
    *Frame180\Height = H
    *Frame180\Data   = *RotatedMatrix
    *RotatedMatrix = _GetRotated90Matrix(W, H, *Frame180\Data, #False)
    *Frame270 = AllocateStructure(FigureFrame)
    *Frame270\Width  = H
    *Frame270\Height = W
    *Frame270\Data   = *RotatedMatrix
    LinkFrames(*InitFrame, *Frame90, *Frame180, *Frame270)
    
    CreateFigureAuto_CreateFramesDone:
    If SetCenterAuto
      _CalcAndSetFigureCenter(*Figure)
    EndIf
    ProcedureReturn *Figure
  EndProcedure
  
  
  Procedure CreateFigure(*DefaultFrame.FigureFrame, SetCenterAuto.b = #True)
    Protected *Figure.FIGURE
    *Figure = AllocateStructure(FIGURE)
    *Figure\DefaultFrame = *DefaultFrame
    *Figure\Frame = *DefaultFrame
    
    If SetCenterAuto
      _CalcAndSetFigureCenter(*Figure)
    EndIf
    ProcedureReturn *Figure
  EndProcedure
  
  
  Procedure RotateWithCentering(*Figure.FIGURE, *Stack.STACK, RotateLeft.b = #True)
    Protected CurrentFrameCenter.Point, NewCoord.Point
    Protected *Last.FigureFrame, *Current.FigureFrame
    
    If (*Figure\Frame\XCenter = 0) Or (*Figure\Frame\YCenter = 0)
      _CalcAndSetFigureCenter(*Figure)
    EndIf
    
    *Last = *Figure\Frame
    RotateLow(*Figure, RotateLeft)
    *Current = *Figure\Frame
    
    ; ЕСЛИ КАДРЫ РАЗНЫЕ - СЧИТАЕМ ЦЕНТРЫ И ОБНОВЛЯЕМ КООРДИНАТУ
    If *Current <> *Last
      ; ЕСЛИ РАНЬШЕ НЕ ДЕЛАЛИ, РАСЧИТЫВАЕМ ГДЕ БУДЕТ ЦЕНТРАЛЬНАЯ ТОЧКА ПОСЛЕ ПОВОРОТА
      If (*Current\XCenter = 0) Or (*Current\YCenter = 0)
        If RotateLeft = 0
          *Current\XCenter = *Last\YCenter
          *Current\YCenter = *Last\Width - (*Last\XCenter - 1)
        Else
          *Current\XCenter = *Current\Width - (*Last\YCenter - 1)
          *Current\YCenter = *Last\XCenter
        EndIf
      EndIf
      NewCoord\x = *Figure\X + *Last\XCenter - *Current\XCenter
      NewCoord\y = *Figure\Y + *Last\YCenter - *Current\YCenter
      ; ПРОВЕРКА ВЫХОДА ФИГУРЫ ЗА ГРАНИЦЫ СТАКАНА
      If (NewCoord\x < 0 Or (NewCoord\x + *Figure\Frame\Width) > (*Stack\Width-1)) Or
         (NewCoord\y < 0) Or (NewCoord\y + *Figure\Frame\Height) > (*Stack\Height-1)
        ; ОБКАКИВАЕМСЯ И ВОЗВРАЩАЕМ ВСЕ НАЗАД
        ; СКАЖЫ ЕСЛИ ЗНАЕШ КАК ПАЛУЧШЕ СДЕЛОТЬ ОТРИЦАНИЕ
        RotateLow(*Figure, #True ! RotateLeft)
        ProcedureReturn #False
      EndIf
      
      *Figure\X = NewCoord\x
      *Figure\Y = NewCoord\y
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  
  Procedure RotateLow(*Figure.FIGURE, RotateLeft.b = #True)
    If RotateLeft
      *Figure\Frame = *Figure\Frame\PrevFrame
    Else
      *Figure\Frame = *Figure\Frame\NextFrame
    EndIf
  EndProcedure
  
  
  Procedure CheckCollision(*Figure.FIGURE, *Stack.STACK)
    Protected.a Result, x, y
    Protected.i FramePos, StackPos
    Protected *F.FigureFrame = *Figure\Frame
    
    Repeat
      For x = 0 To *F\Width-1
        FramePos = *F\Width * y + x
        StackPos = (*Figure\Y + y) * *Stack\Width + *Figure\X + x
        Result | (PeekA(*F\Data + FramePos) & PeekA(*Stack\Matrix + StackPos))
        Debug Str(FramePos) + "F is " + Str(StackPos) + "S.  Result: " + Str(Result)
        Debug "=========================="
      Next
      y + 1
    Until y = *F\Height
    ProcedureReturn Result
  EndProcedure
  
  
  Procedure IsRotationPossible(*Figure.FIGURE, *Stack.STACK, RotateLeft.b = #True)
    Protected Result.b
    ; ЕСЛИ ПОВЕРНУЛАСЬ - ПРОВЕРЯЕМ НА КОЛЛИЗИЮ; ЕСЛИ НЕТ - ЗНАЧИТ ВЫШЛА ЗА ГРАНИЦЫ
    If RotateWithCentering(*Figure, *Stack, RotateLeft)
      
      RotateWithCentering(*Figure, *Stack, #True ! RotateLeft)
    Else
      ProcedureReturn -1
    EndIf
  EndProcedure
  
  
  Procedure IsMovePossible(*Figure.FIGURE, *Stack.STACK, DeltaX.b, DeltaY.b)
    
  EndProcedure
  
EndModule












; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; CursorPosition = 384
; FirstLine = 359
; Folding = ----
; EnableUnicode
; EnableXP