XIncludeFile "TetrisLow.pb"

UseModule TetrisLow

NewMap DefaultFigureBytes.a()
DefaultFigureBytes("+") = $A0
DefaultFigureBytes("*") = $07
DefaultFigureBytes("o") = $CC
DefaultFigureBytes(" ") = 0

Define.FIGURE *TFigureA, *IFigureA, *LFigureA, *FFigureA, *ZFigureA, *SFigureA, *OFigureA
Define *ZFigureM.FIGURE
Define *ZFigureFrame.FigureFrame

*TFigureA = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "*** * "))
*IFigureA = CreateFigureAuto(CreateFrameFromS(4, 1, DefaultFigureBytes(), "****"))
*LFigureA = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "****  "))
*FFigureA = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "***  *"))
*ZFigureA = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "**  **"))
*SFigureA = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), " **** "))
*OFigureA = CreateFigureAuto(CreateFrameFromS(2, 2, DefaultFigureBytes(), "****"))

*ZFigureFrame = CreateFrameFromS(3, 2, DefaultFigureBytes(), "++  ++")
*ZFigureFrame\NextFrame = CreateFrameFromS(2, 3, DefaultFigureBytes(), " ++++ ")
LinkFrames(*ZFigureFrame, *ZFigureFrame\NextFrame)
*ZFigureM = CreateFigure(*ZFigureFrame)

; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; CursorPosition = 10
; EnableUnicode
; EnableXP