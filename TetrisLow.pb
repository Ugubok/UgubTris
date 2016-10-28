EnableExplicit


DeclareModule TetrisLow
  
  ; =================================================================================
  ;-                               ОБЪЯВЛЕНИЯ СТРУКТУР                               
  ; =================================================================================
  
  ; ИЗ ЭТИХ БЛОКОВ СОСТОЯТ МАТРИЦЫ СТАКАНА И ФИГУР
  ; ЭТА СТРУКТУРА СОЗДАНА ДЛЯ ПРОСТОГО ИЗМЕНЕНИЯ РАЗМЕРА ЭЛЕМЕНТОВ МАТРИЦЫ
  ; (НЕТ СМЫСЛА ИСПОЛЬЗОВАТЬ ЕЕ ДЛЯ ЧЕГО-ТО КРОМЕ ИЗМЕРЕНИЯ РАЗМЕРА ЭЛЕМЕНТА МАТРИЦЫ)
  Structure BLOCK
    id.i
  EndStructure
  
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
    ShadowY.a
  EndStructure
  
  ; =================================================================================
  ;-                                     МАКРОСЫ                                     
  ; =================================================================================
  
  CompilerSelect SizeOf(BLOCK)
    CompilerCase 1
      Macro PeekBLOCK : PeekA : EndMacro
      Macro PokeBLOCK : PokeA : EndMacro
    CompilerCase 2
      Macro PeekBLOCK : PeekU : EndMacro
      Macro PokeBLOCK : PokeU : EndMacro
    CompilerCase 4
      Macro PeekBLOCK : PeekL : EndMacro
      Macro PokeBLOCK : PokeL : EndMacro
    CompilerCase 8
      Macro PeekBLOCK : PeekQ : EndMacro
      Macro PokeBLOCK : PokeQ : EndMacro
    CompilerDefault
      CompilerError "Unsupported matrix element size"
  CompilerEndSelect
  
  Macro ReadStackXY(Stack, x, y)
    PeekBLOCK(Stack\Matrix + (Stack\Width * (y) + (x)) * SizeOf(BLOCK))
  EndMacro
  
  Macro ReadFrameXY(Frame, x, y)
    PeekBLOCK(Frame\Data + (Frame\Width * (y) + (x)) * SizeOf(BLOCK))
  EndMacro
  
  Macro WriteStackXY(Stack, x, y, Value)
    PokeBLOCK(Stack\Matrix + (Stack\Width * (y) + (x)) * SizeOf(BLOCK), Value)
  EndMacro
  
  Macro WriteFrameXY(Frame, x, y, Value)
    PokeBLOCK(Frame\Data + (Frame\Width * (y) + (x)) * SizeOf(BLOCK), Value)
  EndMacro
  
  ; =================================================================================
  ;-                               ОБЪЯВЛЕНИЯ ПРОЦЕДУР                               
  ; =================================================================================
  
  ; СОЗДАЕТ И ИНИЦИАЛИЗИРУЕТ СТАКАН (СТРУКУТУРУ STACK) УКАЗАННЫХ РАЗМЕРОВ
  ; @Returns: *STACK
  Declare CreateStack(Width.a, Height.a)
  
  ; ОЧИЩАЕТ СТАКАН (ЗАПОЛНЯЕТ ЕГО МАТРИЦУ НУЛЯМИ)
  ; @Returns: None
  Declare ClearStack(*Stack.STACK)
  
  ; ОСВОБОЖДАЕТ ПАМЯТЬ ОТ СТРУКТУРЫ STACK
  ; @Returns: None
  Declare FreeStack(*Stack.STACK)
  
  ; СОЗДАЕТ ОДНО СОСТОЯНИЕ ФИГУРЫ (КАДР) ИЗ СТРОКИ
  ; Char2ByteDict ОПРЕДЕЛЯЕТ СООТВЕТСТВИЕ СИМВОЛА В СТРОКЕ String$ БАЙТУ В КАДРЕ
  ; @Returns: *FigureFrame
  Declare CreateFrameFromS(Width.a, Height.a, Map Char2ByteDict.BLOCK(), String$)
  
  ; СОЗДАЕТ ОДНО СОСТОЯНИЕ ФИГУРЫ (КАДР) ИЗ МАССИВА
  ; @Returns: *FigureFrame
  Declare CreateFrameFromA(Width.a, Height.a, Array FrameData.BLOCK(1))
  
  ; ОСВОБОЖДАЕТ ПАМЯТЬ ОТ СТРУКТУРЫ FigureFrame
  ; @Returns: None
  Declare FreeFrame(*Frame.FigureFrame)
  
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
  
  ; ОСВОБОЖДАЕТ ПАМЯТЬ ОТ ФИГУРЫ И ВСЕХ ЕЕ КАДРОВ
  ; @Returns: None
  Declare FreeFigure(*Figure.FIGURE)
  
  ; ПОВАРАЧИВАЕТ ФИГУРУ ВЛЕВО/ВПРАВО (ТЕХНИЧЕСКИ, ПРОСТО МЕНЯЕТ ТЕКУЩИЙ КАДР)
  ; ЗАТЕМ ОБНОВЛЯЕТ КООРДИНАТУ ФИГУРЫ ТАК, ЧТОБЫ ЦЕНТРЫ КАДРОВ СОШЛИСЬ В ОДНОЙ ТОЧКЕ
  ; ДЛЯ ПРОВЕРКИ ВЫХОДА ЗА ГРАНИЦЫ ПРИШЛОСЬ ДОБАВИТЬ АРГУМЕНТ *Stack
  ; @Returns: 1 ПРИ УСПЕХЕ, 0 ЕСЛИ ПРИ ПОВОРОТЕ КООРДИНАТЫ ВЫШЛИ ЗА ПРЕДЕЛЫ СТАКАНА
  ;           (ЕСЛИ 0 - ПОВОРОТ НЕ БУДЕТ ПРОИЗВЕДЕН)
  Declare RotateWithCentering(*Figure.FIGURE, *Stack.STACK, RotateLeft.b = #True)
  
  ; ПОВОРАЧИВАЕТ ФИГУРУ ВЛЕВО/ВПРАВО, НЕ МЕНЯЯ КООРДИНАТ
  Declare RotateLow(*Figure.FIGURE, RotateLeft.b = #True)
  
  ; ПРОВЕРЯЕТ НЕ НАЛОЖИЛАСЬ ЛИ ФИГУРА НА КАКОЙ-ЛИБО БЛОК В СТАКАНЕ
  ; НАЛОЖЕНИЕМ ТАКЖЕ СЧИТАЕТСЯ ВЫХОД ЗА ГРАНИЦЫ СТАКАНА
  ; @Returns: 0 ЕСЛИ НЕ НАЛОЖИЛАСЬ, ЛЮБОЕ ДРУГОЕ ЗНАЧЕНИЕ ЕСЛИ НАЛОЖИЛАСЬ
  Declare CheckCollision(*Figure.FIGURE, *Stack.STACK)
  
  ; ПРОВЕРЯЕТ НАХОДИТСЯ ЛИ ФИГУРА В ПРЕДЕЛАХ СТАКАНА
  ; @Returns: #True ЕСЛИ ФИГУРА НЕ ВЫХОДИТ ЗА ПРЕДЕЛЫ СТАКАНА, ИНАЧЕ #False
  Declare IsFigureInStackBounds(*Figure.FIGURE, *Stack.STACK)
  
  ; ПРОВЕРКА ВОЗМОЖНОСТИ ПОВОРОТА ФИГУРЫ
  ; @Returns: 1 ЕСЛИ ВОЗМОЖНО, 0 ЕСЛИ НЕВОЗМОЖНО ПО ПРИЧИНЕ КОЛЛИЗИИ С БЛОКОМ
  ;           -1 ЕСЛИ НЕВОЗМОЖНО ПО ПРИЧИНЕ ВЫХОДА ЗА ГРАНИЦЫ СТАКАНА
  Declare IsRotationPossible(*Figure.FIGURE, *Stack.STACK, RotateLeft.b = #True)
  
  ; ПРОВЕРЯЕТ ВОЗМОЖНОСТЬ СДВИГА ФИГУРЫ НА УКАЗАННОЕ РАССТОЯНИЕ
  ; УЧИТЫВАЕТ СТОЛКНОВЕНИЯ С БЛОКАМИ И ВЫХОД ЗА ГРАНИЦЫ СТАКАНА
  ; @Returns: #True ЕСЛИ СДВИГ ВОЗМОЖЕН, ИНАЧЕ #False
  Declare IsMovePossible(*Figure.FIGURE, *Stack.STACK, DeltaX.b, DeltaY.b)
  
  ; РАСЧИТЫВАЕТ КООРДИНАТУ ТЕНИ ФИГУРЫ (ShadowY)
  ; @Returns: None
  Declare CalcShadowCoord(*Figure.FIGURE, *Stack.STACK)
  
  ; ДЕЛАЕТ "ОТПЕЧАТОК" ФИГУРЫ НА СТАКАНЕ (КОПИРУЕТ МАТРИЦУ ФИГУРЫ В СТАКАН)
;   Declare MergeWithStack(*Figure.FIGURE, *Stack.STACK)
  
  ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
EndDeclareModule

;- ========== РЕАЛИЗАЦИЯ ==========

Module TetrisLow
  
  ; ПРЕДСТАВЛЯЕТ МАССИВ ПАМЯТИ КАК МАТРИЦУ УКАЗАННЫХ РАЗМЕРОВ
  ; СОЗДАЕТ НОВУЮ, ПОВЕРНУЮТУЮ ВЛЕВО/ВПРАВО МАТРИЦУ
  ; MWidth, MHeight  -  ШИРИНА, ВЫСОТА МАТРИЦЫ
  ; elSize           -  РАЗМЕР ЭЛЕМЕНТА МАТРИЦЫ В БАЙТАХ
  ; *Matrix          -  УКАЗАТЕЛЬ НА ДАННЫЕ МАТРИЦЫ
  ; RotateLeft       -  ЕСЛИ НЕ 0, МАТРИЦА ВРАЩАЕТСЯ ВЛЕВО; ИНАЧЕ ВПРАВО
  ; @Returns: *Matrix.a
  Procedure _GetRotated90Matrix(MWidth.i, MHeight.i, elSize.a, *Matrix, RotateLeft.a)
    Protected x.i, y.i, i.i
    Protected *Rotated = AllocateMemory(MWidth * MHeight * elSize)
    
    If RotateLeft = 0
      For x = 0 To MWidth-1
        For y = MHeight-1 To 0 Step -1
          CopyMemory(*Matrix + (MWidth * y + x) * elSize, *Rotated + i * elSize, elSize)
;           PokeA(*Rotated + i * elSize, PeekA(*Matrix + (MWidth * y + x) * elSize))
          i + 1
        Next
      Next
    Else
      For x =  MWidth-1 To 0 Step -1
        For y = 0 To MHeight-1
          CopyMemory(*Matrix + (MWidth * y + x) * elSize, *Rotated + i * elSize, elSize)
;           PokeA(*Rotated + i * elSize, PeekA(*Matrix + (MWidth * y + x) * elSize))
          i + 1
        Next
      Next
    EndIf
    
    ProcedureReturn *Rotated
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
    
    ; ПРЕРОТАЦИЯ ВЛЕВО ЯВЛЯЕТСЯ НЕЖЕЛАТЕЛЬНОЙ, Т.К. С НЕЙ ЦЕНТР ВЕРТИКАЛЬНОЙ ФИГУРЫ I
    ; СТАНОВИТСЯ СМЕЩЕННЫМ ВВЕРХ, ЧТО ОТЛИЧАЕТСЯ ОТ ПОВЕДЕНИЯ В СТАНДАРТНОМ ТЕТРИСЕ
    CompilerIf Defined(TETRIS_PREROTATION_LEFT, #PB_Constant)
      While *Frame\PrevFrame <> *Figure\DefaultFrame
        *Frame = *Frame\PrevFrame
        *Frame\XCenter = *Frame\NextFrame\YCenter
        *Frame\YCenter = *Frame\Height - (*Frame\NextFrame\XCenter - 1)
      Wend
    CompilerElse
      While *Frame\NextFrame <> *Figure\DefaultFrame
        *Frame = *Frame\NextFrame
        *Frame\XCenter = *Frame\Width - (*Frame\PrevFrame\YCenter - 1)
        *Frame\YCenter = *Frame\PrevFrame\XCenter
      Wend
    CompilerEndIf
    
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
    *Stack\Matrix = AllocateMemory(Width * Height * SizeOf(BLOCK))
    *Stack\Width = Width
    *Stack\Height = Height
    ProcedureReturn *Stack
  EndProcedure
  
  
  Procedure ClearStack(*Stack.STACK)
    FillMemory(*Stack\Matrix, *Stack\Width * *Stack\Height * SizeOf(BLOCK), 0)
  EndProcedure
  
  
  Procedure FreeStack(*Stack.STACK)
    FreeMemory(*Stack\Matrix)
    FreeStructure(*Stack)
  EndProcedure
  
  
  Procedure CreateFrameFromS(Width.a, Height.a, Map Char2ByteDict.BLOCK(), String$)
    Protected Dim FrameData.BLOCK(Width * Height)
    Protected i.i
    ; ТРАНСЛИРУЕМ СТРОКУ В МАССИВ БАЙТОВ
    For i = 1 To Len(String$)
      FrameData(i-1) = Char2ByteDict(Mid(String$, i, 1))
    Next
    
    ProcedureReturn CreateFrameFromA(Width, Height, FrameData())
  EndProcedure
  
  
  Procedure CreateFrameFromA(Width.a, Height.a, Array FrameData.BLOCK(1))
    Protected *Frame.FigureFrame
    
    *Frame        = AllocateStructure(FigureFrame)
    *Frame\Data   = AllocateMemory(Width * Height * SizeOf(BLOCK))
    *Frame\Width  = Width
    *Frame\Height = Height
    *Frame\NextFrame = *Frame
    *Frame\PrevFrame = *Frame
    
    CopyMemory(@FrameData(0), *Frame\Data, Width * Height * SizeOf(BLOCK))
    ProcedureReturn *Frame
  EndProcedure
  
  
  Procedure FreeFrame(*Frame.FigureFrame)
    FreeMemory(*Frame\Data)
    FreeStructure(*Frame)
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
    Protected FrameDataSize = W * H * SizeOf(BLOCK)
    
    _LinkFramesSimple(*InitFrame, *InitFrame)
    *Figure = AllocateStructure(FIGURE)
    *Figure\DefaultFrame = *InitFrame
    *Figure\Frame = *InitFrame
    ; ПАПРОБУЕМ КАДР ПОВЕРНУТЫЙ ПО ЧАСОВОЙ СТРЕЛКЕ САЗДАТЬ
    *RotatedMatrix = _GetRotated90Matrix(W, H, SizeOf(BLOCK), *InitFrame\Data, #False)
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
    *RotatedMatrix = _GetRotated90Matrix(H, W, SizeOf(BLOCK), *Frame90\Data, #False)
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
    *RotatedMatrix = _GetRotated90Matrix(W, H, SizeOf(BLOCK), *Frame180\Data, #False)
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
  
  
  Procedure FreeFigure(*Figure.FIGURE)
    Protected *CurrentFrame.FigureFrame = *Figure\DefaultFrame
    Repeat
      *CurrentFrame = *CurrentFrame\NextFrame
      FreeFrame(*CurrentFrame\PrevFrame)
    Until *CurrentFrame = *Figure\DefaultFrame
    FreeStructure(*Figure)
  EndProcedure
  
  
  Procedure RotateWithCentering(*Figure.FIGURE, *Stack.STACK, RotateLeft.b = #True)
    Protected CurrentFrameCenter.Point, LastCoord.Point
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
        If RotateLeft
          *Current\XCenter = *Last\YCenter
          *Current\YCenter = *Current\Height - (*Last\XCenter - 1)
        Else
          *Current\XCenter = *Current\Width - (*Last\YCenter - 1)
          *Current\YCenter = *Last\XCenter
        EndIf
      EndIf
      LastCoord\x = *Figure\X
      LastCoord\y = *Figure\Y
      *Figure\X = *Figure\X + *Last\XCenter - *Current\XCenter
      *Figure\Y = *Figure\Y + *Last\YCenter - *Current\YCenter
      ; ПРОВЕРКА ВЫХОДА ФИГУРЫ ЗА ГРАНИЦЫ СТАКАНА
      If Not IsFigureInStackBounds(*Figure, *Stack)
        ; ОБКАКИВАЕМСЯ И ВОЗВРАЩАЕМ ВСЕ НАЗАД
        *Figure\X = LastCoord\x
        *Figure\Y = LastCoord\y
        RotateLow(*Figure, Bool(Not RotateLeft))
        ProcedureReturn #False
      EndIf
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
    Protected.a x, y
    Protected Result.BLOCK
    Protected StackByte.BLOCK
    Protected *F.FigureFrame = *Figure\Frame
    
    ; НУЖНО ПРОВЕРИТЬ НЕ ВЫХОДИТ ЛИ ФИГУРА ЗА РАМКИ СТАКАНА
    ; ИНАЧЕ МОЖЕМ ОБРАТИТЬСЯ К ПАМЯТИ ЗА ПРЕДЕЛАМИ СТАКАНА
    If Not IsFigureInStackBounds(*Figure, *Stack)
      ProcedureReturn 1
    EndIf
    
    For y = 0 To *F\Height - 1
      For x = 0 To *F\Width-1
        StackByte\id = ReadStackXY(*Stack, *Figure\X + x, *Figure\Y + y)
        Result\id | (Bool(ReadFrameXY(*F, x, y)) & Bool(StackByte\id))
      Next
    Next
    ProcedureReturn Result\id
  EndProcedure
  
  
  Procedure IsFigureInStackBounds(*Figure.FIGURE, *Stack.STACK)
    Protected.w RX, RY  ; ЕСЛИ ПОСТАВИТЬ 1-БАЙТОВЫЙ ТИП ТО ПРОИЗОЙДЕТ ПЕРЕПОЛНЕНИЕ
    
    RX = *Figure\X + *Figure\Frame\Width - 1
    RY = *Figure\Y + *Figure\Frame\Height - 1
    If *Figure\Y >= 0 And *Figure\X >= 0 And RY < *Stack\Height And RX < *Stack\Width
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  
  Procedure IsRotationPossible(*Figure.FIGURE, *Stack.STACK, RotateLeft.b = #True)
    Protected Result.b
    ; ЕСЛИ ПОВЕРНУЛАСЬ - ПРОВЕРЯЕМ НА КОЛЛИЗИЮ; ЕСЛИ НЕТ - ЗНАЧИТ ВЫШЛА ЗА ГРАНИЦЫ
    If RotateWithCentering(*Figure, *Stack, RotateLeft)
      ; TODO: ДОДЕЛАТЬ ЕТУ ПРОЦЕДУРУ
      RotateWithCentering(*Figure, *Stack, Bool(Not RotateLeft))
    Else
      ProcedureReturn -1
    EndIf
  EndProcedure
  
  
  Procedure IsMovePossible(*Figure.FIGURE, *Stack.STACK, DeltaX.b, DeltaY.b)
    Protected Result.b
    
    *Figure\X + DeltaX
    *Figure\Y + DeltaY
    
    If CheckCollision(*Figure, *Stack)
      Result = #False
    ; НЕТ НУЖДЫ ПРОВЕРЯТЬ ВЫХОД ЗА ГРАНИЦЫ СТАКАНА, CheckCollision() ИТАК ДЕЛАЕТ ЭТО
    ; ElseIf IsFigureInStackBounds(*Figure, *Stack)
    ;  Result = #True
    Else
      Result = #True
    EndIf
    *Figure\X - DeltaX
    *Figure\Y - DeltaY
    ProcedureReturn Result
  EndProcedure
  
  
  Procedure CalcShadowCoord(*Figure.FIGURE, *Stack.STACK)
    Protected FigureY.a
    
    FigureY = *Figure\Y
    While Not CheckCollision(*Figure, *Stack)
      *Figure\Y + 1
    Wend
    *Figure\ShadowY = *Figure\Y - 1
    *Figure\Y = FigureY
  EndProcedure
  
EndModule












; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; CursorPosition = 440
; FirstLine = 394
; Folding = ----0--
; EnableUnicode
; EnableXP