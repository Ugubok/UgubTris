XIncludeFile "TetrisLow.pb"

UseModule TetrisLow

NewMap DefaultFigureBytes.BLOCK()
Dim *DefaultFigures.FIGURE (7 -1)
AddMapElement(DefaultFigureBytes(), "!")
DefaultFigureBytes()\id = $FF
AddMapElement(DefaultFigureBytes(), "@")
DefaultFigureBytes()\id = $02
AddMapElement(DefaultFigureBytes(), "#")
DefaultFigureBytes()\id = $03
AddMapElement(DefaultFigureBytes(), "$")
DefaultFigureBytes()\id = $04
AddMapElement(DefaultFigureBytes(), "%")
DefaultFigureBytes()\id = $05
AddMapElement(DefaultFigureBytes(), "^")
DefaultFigureBytes()\id = $06
AddMapElement(DefaultFigureBytes(), "&")
DefaultFigureBytes()\id = $07
AddMapElement(DefaultFigureBytes(), "+")
DefaultFigureBytes()\id = $DA

Define.FIGURE *TFigure, *IFigure, *LFigure, *FFigure, *ZFigure, *SFigure, *OFigure

*TFigure = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "!!! ! "))
*IFigure = CreateFigureAuto(CreateFrameFromS(4, 1, DefaultFigureBytes(), "@@@@"))
*LFigure = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "####  "))
*FFigure = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "$$$  $"))
*ZFigure = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), "%%  %%"))
*SFigure = CreateFigureAuto(CreateFrameFromS(3, 2, DefaultFigureBytes(), " ^^^^ "))
*OFigure = CreateFigureAuto(CreateFrameFromS(2, 2, DefaultFigureBytes(), "&&&&"))

*DefaultFigures(0) = *TFigure
*DefaultFigures(1) = *IFigure
*DefaultFigures(2) = *LFigure
*DefaultFigures(3) = *FFigure
*DefaultFigures(4) = *ZFigure
*DefaultFigures(5) = *SFigure
*DefaultFigures(6) = *OFigure


CompilerIf Defined(TETRIS_CUSTOM_FIGURES, #PB_Constant)
  Define.FIGURE *BigTFigureA
  *BigTFigureA = CreateFigureAuto(CreateFrameFromS(3, 3, DefaultFigureBytes(), "*** *  * "))
CompilerEndIf


CompilerIf #False
  ; THIS IS EXAMPLE OF HOW TO MANUALLY CREATE AND LINK FRAMES, THEN CREATE FIGURE FROM IT
  Define *ZFigureM.FIGURE
  Define *ZFigureFrame.FigureFrame
  *ZFigureFrame = CreateFrameFromS(3, 2, DefaultFigureBytes(), "++  ++")
  *ZFigureFrame\NextFrame = CreateFrameFromS(2, 3, DefaultFigureBytes(), " ++++ ")
  LinkFrames(*ZFigureFrame, *ZFigureFrame\NextFrame)
  *ZFigureM = CreateFigure(*ZFigureFrame)
CompilerEndIf

UnuseModule TetrisLow
; IDE Options = PureBasic 5.40 LTS (Windows - x86)
; CursorPosition = 7
; Folding = -
; EnableUnicode
; EnableXP