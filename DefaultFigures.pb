XIncludeFile "TetrisLow.pb"

UseModule TetrisLow

NewMap DefaultFigureBytes.a()
DefaultFigureBytes("+") = $A0
DefaultFigureBytes("*") = $FF
DefaultFigureBytes("o") = $CC
DefaultFigureBytes(" ") = 0

Define *TFigureA.FIGURE, *IFigureA.FIGURE, *LFigureA.FIGURE
Define *ZFigureM.FIGURE
Define *ZFigureFrame.FigureFrame

*TFigureA = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "*** * "))
*IFigureA = CreateFigureAuto(CreateFrameFromS(4, 1, DefaultFigureBytes(), "****"))
*LFigureA = CreateFigureAuto(CreateFrameFromS(2, 3, DefaultFigureBytes(), "** * *"))

*ZFigureFrame = CreateFrameFromS(3, 2, DefaultFigureBytes(), "++  ++")
*ZFigureFrame\NextFrame = CreateFrameFromS(2, 3, DefaultFigureBytes(), " ++++ ")
LinkFrames(*ZFigureFrame, *ZFigureFrame\NextFrame)
*ZFigureM = CreateFigure(*ZFigureFrame)

; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; CursorPosition = 22
; EnableUnicode
; EnableXP