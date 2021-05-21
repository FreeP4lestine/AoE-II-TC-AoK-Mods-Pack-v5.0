; <COMPILER: v1.1.33.09>
SetBatchLines, -1
SetWinDelay, 0
#NoEnv
#SingleInstance, Force
Class ImageButton {
    Static DefGuiColor := ""
    Static DefTxtColor := "Black"
    Static LastError := ""
    Static BitMaps := []
    Static GDIPDll := 0
    Static GDIPToken := 0
    Static MaxOptions := 8
    Static HTML := {BLACK: 0x000000, GRAY: 0x808080, SILVER: 0xC0C0C0, WHITE: 0xFFFFFF, MAROON: 0x800000
        , PURPLE: 0x800080, FUCHSIA: 0xFF00FF, RED: 0xFF0000, GREEN: 0x008000, OLIVE: 0x808000
    , YELLOW: 0xFFFF00, LIME: 0x00FF00, NAVY: 0x000080, TEAL: 0x008080, AQUA: 0x00FFFF, BLUE: 0x0000FF}
    Static ClassInit := ImageButton.InitClass()
    __New(P*) {
        Return False
    }
    InitClass() {
        GuiColor := DllCall("User32.dll\GetSysColor", "Int", 15, "UInt")
        This.DefGuiColor := ((GuiColor >> 16) & 0xFF) | (GuiColor & 0x00FF00) | ((GuiColor & 0xFF) << 16)
        Return True
    }
    GdiplusStartup() {
        This.GDIPDll := This.GDIPToken := 0
        If (This.GDIPDll := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", "Ptr")) {
            VarSetCapacity(SI, 24, 0)
            Numput(1, SI, 0, "Int")
            GDIPToken := ""
            If !DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", GDIPToken, "Ptr", &SI, "Ptr", 0)
                This.GDIPToken := GDIPToken
            Else
                This.GdiplusShutdown()
        }
        Return This.GDIPToken
    }
    GdiplusShutdown() {
        If This.GDIPToken
            DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", This.GDIPToken)
        If This.GDIPDll
            DllCall("Kernel32.dll\FreeLibrary", "Ptr", This.GDIPDll)
        This.GDIPDll := This.GDIPToken := 0
    }
    FreeBitmaps() {
        For K, HBITMAP In This.BitMaps
            DllCall("Gdi32.dll\DeleteObject", "Ptr", HBITMAP)
        This.BitMaps := []
    }
    GetARGB(RGB) {
        ARGB := This.HTML.HasKey(RGB) ? This.HTML[RGB] : RGB
        Return (ARGB & 0xFF000000) = 0 ? 0xFF000000 | ARGB : ARGB
    }
    PathAddRectangle(Path, X, Y, W, H) {
        Return DllCall("Gdiplus.dll\GdipAddPathRectangle", "Ptr", Path, "Float", X, "Float", Y, "Float", W, "Float", H)
    }
    PathAddRoundedRect(Path, X1, Y1, X2, Y2, R) {
        D := (R * 2), X2 -= D, Y2 -= D
        DllCall("Gdiplus.dll\GdipAddPathArc"
        , "Ptr", Path, "Float", X1, "Float", Y1, "Float", D, "Float", D, "Float", 180, "Float", 90)
        DllCall("Gdiplus.dll\GdipAddPathArc"
        , "Ptr", Path, "Float", X2, "Float", Y1, "Float", D, "Float", D, "Float", 270, "Float", 90)
        DllCall("Gdiplus.dll\GdipAddPathArc"
        , "Ptr", Path, "Float", X2, "Float", Y2, "Float", D, "Float", D, "Float", 0, "Float", 90)
        DllCall("Gdiplus.dll\GdipAddPathArc"
        , "Ptr", Path, "Float", X1, "Float", Y2, "Float", D, "Float", D, "Float", 90, "Float", 90)
        Return DllCall("Gdiplus.dll\GdipClosePathFigure", "Ptr", Path)
    }
    SetRect(ByRef Rect, X1, Y1, X2, Y2) {
        VarSetCapacity(Rect, 16, 0)
        NumPut(X1, Rect, 0, "Int"), NumPut(Y1, Rect, 4, "Int")
        NumPut(X2, Rect, 8, "Int"), NumPut(Y2, Rect, 12, "Int")
        Return True
    }
    SetRectF(ByRef Rect, X, Y, W, H) {
        VarSetCapacity(Rect, 16, 0)
        NumPut(X, Rect, 0, "Float"), NumPut(Y, Rect, 4, "Float")
        NumPut(W, Rect, 8, "Float"), NumPut(H, Rect, 12, "Float")
        Return True
    }
    SetError(Msg) {
        This.FreeBitmaps()
        This.GdiplusShutdown()
        This.LastError := Msg
        Return False
    }
    Create(HWND, Options*) {
        Static BCM_SETIMAGELIST := 0x1602
        , BS_CHECKBOX := 0x02, BS_RADIOBUTTON := 0x04, BS_GROUPBOX := 0x07, BS_AUTORADIOBUTTON := 0x09
        , BS_LEFT := 0x0100, BS_RIGHT := 0x0200, BS_CENTER := 0x0300, BS_TOP := 0x0400, BS_BOTTOM := 0x0800
        , BS_VCENTER := 0x0C00, BS_BITMAP := 0x0080
        , BUTTON_IMAGELIST_ALIGN_LEFT := 0, BUTTON_IMAGELIST_ALIGN_RIGHT := 1, BUTTON_IMAGELIST_ALIGN_CENTER := 4
        , ILC_COLOR32 := 0x20
        , OBJ_BITMAP := 7
        , RCBUTTONS := BS_CHECKBOX | BS_RADIOBUTTON | BS_AUTORADIOBUTTON
        , SA_LEFT := 0x00, SA_CENTER := 0x01, SA_RIGHT := 0x02
        , WM_GETFONT := 0x31
        This.LastError := ""
        If !DllCall("User32.dll\IsWindow", "Ptr", HWND)
            Return This.SetError("Invalid parameter HWND!")
        If !(IsObject(Options)) || (Options.MinIndex() <> 1) || (Options.MaxIndex() > This.MaxOptions)
            Return This.SetError("Invalid parameter Options!")
        WinGetClass, BtnClass, ahk_id %HWND%
        ControlGet, BtnStyle, Style, , , ahk_id %HWND%
        If (BtnClass != "Button") || ((BtnStyle & 0xF ^ BS_GROUPBOX) = 0) || ((BtnStyle & RCBUTTONS) > 1)
            Return This.SetError("The control must be a pushbutton!")
        If !This.GdiplusStartup()
            Return This.SetError("GDIPlus could not be started!")
        GDIPFont := 0
        HFONT := DllCall("User32.dll\SendMessage", "Ptr", HWND, "UInt", WM_GETFONT, "Ptr", 0, "Ptr", 0, "Ptr")
        DC := DllCall("User32.dll\GetDC", "Ptr", HWND, "Ptr")
        DllCall("Gdi32.dll\SelectObject", "Ptr", DC, "Ptr", HFONT)
        PFONT := ""
        DllCall("Gdiplus.dll\GdipCreateFontFromDC", "Ptr", DC, "PtrP", PFONT)
        DllCall("User32.dll\ReleaseDC", "Ptr", HWND, "Ptr", DC)
        If !(PFONT)
            Return This.SetError("Couldn't get button's font!")
        VarSetCapacity(RECT, 16, 0)
        If !DllCall("User32.dll\GetWindowRect", "Ptr", HWND, "Ptr", &RECT)
            Return This.SetError("Couldn't get button's rectangle!")
        BtnW := NumGet(RECT, 8, "Int") - NumGet(RECT, 0, "Int")
        BtnH := NumGet(RECT, 12, "Int") - NumGet(RECT, 4, "Int")
        ControlGetText, BtnCaption, , ahk_id %HWND%
        If (ErrorLevel)
            Return This.SetError("Couldn't get button's caption!")
        This.BitMaps := []
        For Index, Option In Options {
            If !IsObject(Option)
                Continue
            BkgColor1 := BkgColor2 := TxtColor := Mode := Rounded := GuiColor := Image := ""
            Loop, % This.MaxOptions {
                If (Option[A_Index] = "")
                    Option[A_Index] := Options.1[A_Index]
            }
            Mode := SubStr(Option.1, 1 ,1)
            If !InStr("0123456789", Mode)
                Return This.SetError("Invalid value for Mode in Options[" . Index . "]!")
            If (Mode = 0)
                && (FileExist(Option.2) || (DllCall("Gdi32.dll\GetObjectType", "Ptr", Option.2, "UInt") = OBJ_BITMAP))
            Image := Option.2
            Else {
                If !(Option.2 + 0) && !This.HTML.HasKey(Option.2)
                    Return This.SetError("Invalid value for StartColor in Options[" . Index . "]!")
                BkgColor1 := This.GetARGB(Option.2)
                If (Option.3 = "")
                    Option.3 := Option.2
                If !(Option.3 + 0) && !This.HTML.HasKey(Option.3)
                    Return This.SetError("Invalid value for TargetColor in Options[" . Index . "]!")
                BkgColor2 := This.GetARGB(Option.3)
            }
            If (Option.4 = "")
                Option.4 := This.DefTxtColor
            If !(Option.4 + 0) && !This.HTML.HasKey(Option.4)
                Return This.SetError("Invalid value for TxtColor in Options[" . Index . "]!")
            TxtColor := This.GetARGB(Option.4)
            Rounded := Option.5
            If (Rounded = "H")
                Rounded := BtnH * 0.5
            If (Rounded = "W")
                Rounded := BtnW * 0.5
            If !(Rounded + 0)
                Rounded := 0
            If (Option.6 = "")
                Option.6 := This.DefGuiColor
            If !(Option.6 + 0) && !This.HTML.HasKey(Option.6)
                Return This.SetError("Invalid value for GuiColor in Options[" . Index . "]!")
            GuiColor := This.GetARGB(Option.6)
            BorderColor := ""
            If (Option.7 <> "") {
                If !(Option.7 + 0) && !This.HTML.HasKey(Option.7)
                    Return This.SetError("Invalid value for BorderColor in Options[" . Index . "]!")
                BorderColor := 0xFF000000 | This.GetARGB(Option.7)
            }
            BorderWidth := Option.8 ? Option.8 : 1
            PBITMAP := ""
            DllCall("Gdiplus.dll\GdipCreateBitmapFromScan0", "Int", BtnW, "Int", BtnH, "Int", 0
            , "UInt", 0x26200A, "Ptr", 0, "PtrP", PBITMAP)
            PGRAPHICS := ""
            DllCall("Gdiplus.dll\GdipGetImageGraphicsContext", "Ptr", PBITMAP, "PtrP", PGRAPHICS)
            DllCall("Gdiplus.dll\GdipSetSmoothingMode", "Ptr", PGRAPHICS, "UInt", 4)
            DllCall("Gdiplus.dll\GdipSetInterpolationMode", "Ptr", PGRAPHICS, "Int", 7)
            DllCall("Gdiplus.dll\GdipSetCompositingQuality", "Ptr", PGRAPHICS, "UInt", 4)
            DllCall("Gdiplus.dll\GdipSetRenderingOrigin", "Ptr", PGRAPHICS, "Int", 0, "Int", 0)
            DllCall("Gdiplus.dll\GdipSetPixelOffsetMode", "Ptr", PGRAPHICS, "UInt", 4)
            DllCall("Gdiplus.dll\GdipGraphicsClear", "Ptr", PGRAPHICS, "UInt", GuiColor)
            If (Image = "") {
                PathX := PathY := 0, PathW := BtnW, PathH := BtnH
                PPATH := ""
                DllCall("Gdiplus.dll\GdipCreatePath", "UInt", 0, "PtrP", PPATH)
                If (Rounded < 1)
                    This.PathAddRectangle(PPATH, PathX, PathY, PathW, PathH)
                Else
                    This.PathAddRoundedRect(PPATH, PathX, PathY, PathW, PathH, Rounded)
                If (BorderColor <> "") && (BorderWidth > 0) && (Mode <> 7) {
                    DllCall("Gdiplus.dll\GdipCreateSolidFill", "UInt", BorderColor, "PtrP", PBRUSH)
                    DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
                    DllCall("Gdiplus.dll\GdipDeleteBrush", "Ptr", PBRUSH)
                    DllCall("Gdiplus.dll\GdipResetPath", "Ptr", PPATH)
                    PathX := PathY := BorderWidth, PathW -= BorderWidth, PathH -= BorderWidth, Rounded -= BorderWidth
                    If (Rounded < 1)
                        This.PathAddRectangle(PPATH, PathX, PathY, PathW - PathX, PathH - PathY)
                    Else
                        This.PathAddRoundedRect(PPATH, PathX, PathY, PathW, PathH, Rounded)
                    BkgColor1 := 0xFF000000 | BkgColor1
                    BkgColor2 := 0xFF000000 | BkgColor2
                }
                PathW -= PathX
                PathH -= PathY
                If (Mode = 0) {
                    DllCall("Gdiplus.dll\GdipCreateSolidFill", "UInt", BkgColor1, "PtrP", PBRUSH)
                    DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
                }
                Else If (Mode = 1) || (Mode = 2) {
                    PBRUSH := ""
                    This.SetRectF(RECTF, PathX, PathY, PathW, PathH)
                    DllCall("Gdiplus.dll\GdipCreateLineBrushFromRect", "Ptr", &RECTF
                    , "UInt", BkgColor1, "UInt", BkgColor2, "Int", Mode & 1, "Int", 3, "PtrP", PBRUSH)
                    DllCall("Gdiplus.dll\GdipSetLineGammaCorrection", "Ptr", PBRUSH, "Int", 1)
                    This.SetRect(COLORS, BkgColor1, BkgColor1, BkgColor2, BkgColor2)
                    This.SetRectF(POSITIONS, 0, 0.5, 0.5, 1)
                    DllCall("Gdiplus.dll\GdipSetLinePresetBlend", "Ptr", PBRUSH
                    , "Ptr", &COLORS, "Ptr", &POSITIONS, "Int", 4)
                    DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
                }
                Else If (Mode >= 3) && (Mode <= 6) {
                    W := Mode = 6 ? PathW / 2 : PathW
                    H := Mode = 5 ? PathH / 2 : PathH
                    This.SetRectF(RECTF, PathX, PathY, W, H)
                    DllCall("Gdiplus.dll\GdipCreateLineBrushFromRect", "Ptr", &RECTF
                    , "UInt", BkgColor1, "UInt", BkgColor2, "Int", Mode & 1, "Int", 3, "PtrP", PBRUSH)
                    DllCall("Gdiplus.dll\GdipSetLineGammaCorrection", "Ptr", PBRUSH, "Int", 1)
                    DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
                }
                Else {
                    DllCall("Gdiplus.dll\GdipCreatePathGradientFromPath", "Ptr", PPATH, "PtrP", PBRUSH)
                    DllCall("Gdiplus.dll\GdipSetPathGradientGammaCorrection", "Ptr", PBRUSH, "UInt", 1)
                    VarSetCapacity(ColorArray, 4, 0)
                    NumPut(BkgColor1, ColorArray, 0, "UInt")
                    DllCall("Gdiplus.dll\GdipSetPathGradientSurroundColorsWithCount", "Ptr", PBRUSH, "Ptr", &ColorArray
                    , "IntP", 1)
                    DllCall("Gdiplus.dll\GdipSetPathGradientCenterColor", "Ptr", PBRUSH, "UInt", BkgColor2)
                    FS := (BtnH < BtnW ? BtnH : BtnW) / 3
                    XScale := (BtnW - FS) / BtnW
                    YScale := (BtnH - FS) / BtnH
                    DllCall("Gdiplus.dll\GdipSetPathGradientFocusScales", "Ptr", PBRUSH, "Float", XScale, "Float", YScale)
                    DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
                }
                DllCall("Gdiplus.dll\GdipDeleteBrush", "Ptr", PBRUSH)
                DllCall("Gdiplus.dll\GdipDeletePath", "Ptr", PPATH)
            } Else {
                If (Image + 0)
                    DllCall("Gdiplus.dll\GdipCreateBitmapFromHBITMAP", "Ptr", Image, "Ptr", 0, "PtrP", PBM)
                Else
                    DllCall("Gdiplus.dll\GdipCreateBitmapFromFile", "WStr", Image, "PtrP", PBM)
                DllCall("Gdiplus.dll\GdipDrawImageRectI", "Ptr", PGRAPHICS, "Ptr", PBM, "Int", 0, "Int", 0
                , "Int", BtnW, "Int", BtnH)
                DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", PBM)
            }
            If (BtnCaption <> "") {
                HFORMAT := ""
                DllCall("Gdiplus.dll\GdipStringFormatGetGenericTypographic", "PtrP", HFORMAT)
                DllCall("Gdiplus.dll\GdipCreateSolidFill", "UInt", TxtColor, "PtrP", PBRUSH)
                HALIGN := (BtnStyle & BS_CENTER) = BS_CENTER ? SA_CENTER
                : (BtnStyle & BS_CENTER) = BS_RIGHT ? SA_RIGHT
                : (BtnStyle & BS_CENTER) = BS_Left ? SA_LEFT
                : SA_CENTER
                DllCall("Gdiplus.dll\GdipSetStringFormatAlign", "Ptr", HFORMAT, "Int", HALIGN)
                VALIGN := (BtnStyle & BS_VCENTER) = BS_TOP ? 0
                : (BtnStyle & BS_VCENTER) = BS_BOTTOM ? 2
                : 1
                DllCall("Gdiplus.dll\GdipSetStringFormatLineAlign", "Ptr", HFORMAT, "Int", VALIGN)
                DllCall("Gdiplus.dll\GdipSetTextRenderingHint", "Ptr", PGRAPHICS, "Int", 0)
                VarSetCapacity(RECT, 16, 0)
                NumPut(BtnW, RECT, 8, "Float")
                NumPut(BtnH, RECT, 12, "Float")
                DllCall("Gdiplus.dll\GdipDrawString", "Ptr", PGRAPHICS, "WStr", BtnCaption, "Int", -1
                , "Ptr", PFONT, "Ptr", &RECT, "Ptr", HFORMAT, "Ptr", PBRUSH)
            }
            HBITMAP := ""
            DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", "Ptr", PBITMAP, "PtrP", HBITMAP, "UInt", 0X00FFFFFF)
            This.BitMaps[Index] := HBITMAP
            DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", PBITMAP)
            DllCall("Gdiplus.dll\GdipDeleteBrush", "Ptr", PBRUSH)
            DllCall("Gdiplus.dll\GdipDeleteStringFormat", "Ptr", HFORMAT)
            DllCall("Gdiplus.dll\GdipDeleteGraphics", "Ptr", PGRAPHICS)
        }
        DllCall("Gdiplus.dll\GdipDeleteFont", "Ptr", PFONT)
        HIL := DllCall("Comctl32.dll\ImageList_Create"
        , "UInt", BtnW, "UInt", BtnH, "UInt", ILC_COLOR32, "Int", 6, "Int", 0, "Ptr")
        Loop, % (This.BitMaps.MaxIndex() > 1 ? 6 : 1) {
            HBITMAP := This.BitMaps.HasKey(A_Index) ? This.BitMaps[A_Index] : This.BitMaps.1
            DllCall("Comctl32.dll\ImageList_Add", "Ptr", HIL, "Ptr", HBITMAP, "Ptr", 0)
        }
        VarSetCapacity(BIL, 20 + A_PtrSize, 0)
        NumPut(HIL, BIL, 0, "Ptr")
        Numput(BUTTON_IMAGELIST_ALIGN_CENTER, BIL, A_PtrSize + 16, "UInt")
        ControlSetText, , , ahk_id %HWND%
        Control, Style, +%BS_BITMAP%, , ahk_id %HWND%
        SendMessage, %BCM_SETIMAGELIST%, 0, 0, , ahk_id %HWND%
        SendMessage, %BCM_SETIMAGELIST%, 0, % &BIL, , ahk_id %HWND%
        This.FreeBitmaps()
        This.GdiplusShutdown()
        Return True
    }
    SetGuiColor(GuiColor) {
        If !(GuiColor + 0) && !This.HTML.HasKey(GuiColor)
            Return False
        This.DefGuiColor := (This.HTML.HasKey(GuiColor) ? This.HTML[GuiColor] : GuiColor) & 0xFFFFFF
        Return True
    }
    SetTxtColor(TxtColor) {
        If !(TxtColor + 0) && !This.HTML.HasKey(TxtColor)
            Return False
        This.DefTxtColor := (This.HTML.HasKey(TxtColor) ? This.HTML[TxtColor] : TxtColor) & 0xFFFFFF
        Return True
    }
}
Class CtlColors
{
    Static Attached := {}
    Static HandledMessages := {Edit: 0, ListBox: 0, Static: 0}
    Static MessageHandler := "CtlColors_OnMessage"
    Static WM_CTLCOLOR := {Edit: 0x0133, ListBox: 0x134, Static: 0x0138}
    Static HTML := {AQUA: 0xFFFF00, BLACK: 0x000000, BLUE: 0xFF0000, FUCHSIA: 0xFF00FF, GRAY: 0x808080, GREEN: 0x008000
        , LIME: 0x00FF00, MAROON: 0x000080, NAVY: 0x800000, OLIVE: 0x008080, PURPLE: 0x800080, RED: 0x0000FF
    , SILVER: 0xC0C0C0, TEAL: 0x808000, WHITE: 0xFFFFFF, YELLOW: 0x00FFFF}
    Static NullBrush := DllCall("GetStockObject", "Int", 5, "UPtr")
    Static SYSCOLORS := {Edit: "", ListBox: "", Static: ""}
    Static ErrorMsg := ""
    Static InitClass := CtlColors.ClassInit()
    __New()
    {
        If (This.InitClass == "!DONE!")
        {
            This["!Access_Denied!"] := True
            Return False
        }
    }
    __Delete()
    {
        If This["!Access_Denied!"]
            Return
        This.Free()
    }
    ClassInit()
    {
        CtlColors := New CtlColors
        Return "!DONE!"
    }
    CheckBkColor(ByRef BkColor, Class)
    {
        This.ErrorMsg := ""
        If (BkColor != "") && !This.HTML.HasKey(BkColor) && !RegExMatch(BkColor, "^[[:xdigit:]]{6}$")
        {
            This.ErrorMsg := "Invalid parameter BkColor: " . BkColor
            Return False
        }
        BkColor := BkColor = "" ? This.SYSCOLORS[Class]
        : This.HTML.HasKey(BkColor) ? This.HTML[BkColor]
        : "0x" . SubStr(BkColor, 5, 2) . SubStr(BkColor, 3, 2) . SubStr(BkColor, 1, 2)
        Return True
    }
    CheckTxColor(ByRef TxColor)
    {
        This.ErrorMsg := ""
        If (TxColor != "") && !This.HTML.HasKey(TxColor) && !RegExMatch(TxColor, "i)^[[:xdigit:]]{6}$")
        {
            This.ErrorMsg := "Invalid parameter TextColor: " . TxColor
            Return False
        }
        TxColor := TxColor = "" ? ""
        : This.HTML.HasKey(TxColor) ? This.HTML[TxColor]
        : "0x" . SubStr(TxColor, 5, 2) . SubStr(TxColor, 3, 2) . SubStr(TxColor, 1, 2)
        Return True
    }
    Attach(HWND, BkColor, TxColor := "") {
        Static ClassNames := {Button: "", ComboBox: "", Edit: "", ListBox: "", Static: ""}
        Static BS_CHECKBOX := 0x2, BS_RADIOBUTTON := 0x8
        Static ES_READONLY := 0x800
        Static COLOR_3DFACE := 15, COLOR_WINDOW := 5
        If (This.SYSCOLORS.Edit = "")
        {
            This.SYSCOLORS.Static := DllCall("User32.dll\GetSysColor", "Int", COLOR_3DFACE, "UInt")
            This.SYSCOLORS.Edit := DllCall("User32.dll\GetSysColor", "Int", COLOR_WINDOW, "UInt")
            This.SYSCOLORS.ListBox := This.SYSCOLORS.Edit
        }
        This.ErrorMsg := ""
        If (BkColor = "") && (TxColor = "")
        {
            This.ErrorMsg := "Both parameters BkColor and TxColor are empty!"
            Return False
        }
        If !(CtrlHwnd := HWND + 0) || !DllCall("User32.dll\IsWindow", "UPtr", HWND, "UInt")
        {
            This.ErrorMsg := "Invalid parameter HWND: " . HWND
            Return False
        }
        If This.Attached.HasKey(HWND)
        {
            This.ErrorMsg := "Control " . HWND . " is already registered!"
            Return False
        }
        Hwnds := [CtrlHwnd]
        Classes := ""
        WinGetClass, CtrlClass, ahk_id %CtrlHwnd%
        This.ErrorMsg := "Unsupported control class: " . CtrlClass
        If !ClassNames.HasKey(CtrlClass)
            Return False
        ControlGet, CtrlStyle, Style, , , ahk_id %CtrlHwnd%
        If (CtrlClass = "Edit")
            Classes := ["Edit", "Static"]
        Else If (CtrlClass = "Button") {
            IF (CtrlStyle & BS_RADIOBUTTON) || (CtrlStyle & BS_CHECKBOX)
                Classes := ["Static"]
            Else
                Return False
        }
        Else If (CtrlClass = "ComboBox")
        {
            VarSetCapacity(CBBI, 40 + (A_PtrSize * 3), 0)
            NumPut(40 + (A_PtrSize * 3), CBBI, 0, "UInt")
            DllCall("User32.dll\GetComboBoxInfo", "Ptr", CtrlHwnd, "Ptr", &CBBI)
            Hwnds.Insert(NumGet(CBBI, 40 + (A_PtrSize * 2, "UPtr")) + 0)
            Hwnds.Insert(Numget(CBBI, 40 + A_PtrSize, "UPtr") + 0)
            Classes := ["Edit", "Static", "ListBox"]
        }
        If !IsObject(Classes)
            Classes := [CtrlClass]
        If (BkColor <> "Trans")
            If !This.CheckBkColor(BkColor, Classes[1])
            Return False
        If !This.CheckTxColor(TxColor)
            Return False
        For I, V In Classes
        {
            If (This.HandledMessages[V] = 0)
                OnMessage(This.WM_CTLCOLOR[V], This.MessageHandler)
            This.HandledMessages[V] += 1
        }
        If (BkColor = "Trans")
            Brush := This.NullBrush
        Else
            Brush := DllCall("Gdi32.dll\CreateSolidBrush", "UInt", BkColor, "UPtr")
        For I, V In Hwnds
            This.Attached[V] := {Brush: Brush, TxColor: TxColor, BkColor: BkColor, Classes: Classes, Hwnds: Hwnds}
        DllCall("User32.dll\InvalidateRect", "Ptr", HWND, "Ptr", 0, "Int", 1)
        This.ErrorMsg := ""
        Return True
    }
    Change(HWND, BkColor, TxColor := "")
    {
        This.ErrorMsg := ""
        HWND += 0
        If !This.Attached.HasKey(HWND)
            Return This.Attach(HWND, BkColor, TxColor)
        CTL := This.Attached[HWND]
        If (BkColor <> "Trans")
            If !This.CheckBkColor(BkColor, CTL.Classes[1])
            Return False
        If !This.CheckTxColor(TxColor)
            Return False
        If (BkColor <> CTL.BkColor)
        {
            If (CTL.Brush)
            {
                If (Ctl.Brush <> This.NullBrush)
                    DllCall("Gdi32.dll\DeleteObject", "Prt", CTL.Brush)
                This.Attached[HWND].Brush := 0
            }
            If (BkColor = "Trans")
                Brush := This.NullBrush
            Else
                Brush := DllCall("Gdi32.dll\CreateSolidBrush", "UInt", BkColor, "UPtr")
            For I, V In CTL.Hwnds
            {
                This.Attached[V].Brush := Brush
                This.Attached[V].BkColor := BkColor
            }
        }
        For I, V In Ctl.Hwnds
            This.Attached[V].TxColor := TxColor
        This.ErrorMsg := ""
        DllCall("User32.dll\InvalidateRect", "Ptr", HWND, "Ptr", 0, "Int", 1)
        Return True
    }
    Detach(HWND)
    {
        This.ErrorMsg := ""
        HWND += 0
        If This.Attached.HasKey(HWND) {
            CTL := This.Attached[HWND].Clone()
            If (CTL.Brush) && (CTL.Brush <> This.NullBrush)
                DllCall("Gdi32.dll\DeleteObject", "Prt", CTL.Brush)
            For I, V In CTL.Classes {
                If This.HandledMessages[V] > 0 {
                    This.HandledMessages[V] -= 1
                    If This.HandledMessages[V] = 0
                        OnMessage(This.WM_CTLCOLOR[V], "")
                }
            }
            For I, V In CTL.Hwnds
                This.Attached.Remove(V, "")
            DllCall("User32.dll\InvalidateRect", "Ptr", HWND, "Ptr", 0, "Int", 1)
            CTL := ""
            Return True
        }
        This.ErrorMsg := "Control " . HWND . " is not registered!"
        Return False
    }
    Free()
    {
        For K, V In This.Attached
        {
            If (V.Brush) && (V.Brush <> This.NullBrush)
                DllCall("Gdi32.dll\DeleteObject", "Ptr", V.Brush)
        }
        For K, V In This.HandledMessages
        {
            If (V > 0)
            {
                OnMessage(This.WM_CTLCOLOR[K], "")
                This.HandledMessages[K] := 0
            }
        }
        This.Attached := {}
        Return True
    }
    IsAttached(HWND)
    {
        Return This.Attached.HasKey(HWND)
    }
}
CtlColors_OnMessage(HDC, HWND)
{
    Critical
    If CtlColors.IsAttached(HWND)
    {
        CTL := CtlColors.Attached[HWND]
        If (CTL.TxColor != "")
            DllCall("Gdi32.dll\SetTextColor", "Ptr", HDC, "UInt", CTL.TxColor)
        If (CTL.BkColor = "Trans")
            DllCall("Gdi32.dll\SetBkMode", "Ptr", HDC, "UInt", 1)
        Else
            DllCall("Gdi32.dll\SetBkColor", "Ptr", HDC, "UInt", CTL.BkColor)
        Return CTL.Brush
    }
}
RandomHex()
{
    Random, Int, 0, 9
    Table := ["A", "B", "C", "D", "E", "F"]
    Random, AInt, 1, 6
    Random, Bol, 0, 1
    If (Bol)
        Return % Int Table[AInt]
    Else
        Return % Table[AInt] Int
}
UpdateModView(GLocation, Ctrl)
{
    RefModFile := {sw:"gra02098", bb:"gra02560", eb:"gra00009", st:"gra01250", lgt:"ter15024", hbf:"gra00424", ns:"ter15030"}
    If (Ctrl = "")
    {
        For ModS, File in RefModFile
        {
            If InStr(File, "gra")
                Drs := "graphics.drs"
            Else If InStr(File, "ter")
                Drs := "terrain.drs"
            Else If InStr(File, "int")
                Drs := "interfac.drs"
            IniRead, RefMD5, Mods\Mods.ini, %ModS%S, %File%
            RunWait, Bin\DrsBuild.exe /e "%GLocation%\Data\%Drs%" %File%.slp /o "%A_ScriptDir%",, Hide
            HashVal := HashFile(File ".slp", 2)
            If (HashVal = RefMD5)
            {
                GuiControl, Main:Hide, %ModS%S
                GuiControl, Main:Hide, %ModS%SU
                GuiControl, Main:Show, %ModS%SI
            }
            Else
            {
                GuiControl, Main:Hide, %ModS%S
                GuiControl, Main:Hide, %ModS%SI
                GuiControl, Main:Show, %ModS%SU
            }
            FileDelete, %File%.slp
        }
    }
    Else
    {
        File := RefModFile[Ctrl]
        If InStr(File, "gra")
            Drs := "graphics.drs"
        Else If InStr(File, "ter")
            Drs := "terrain.drs"
        IniRead, RefMD5, Mods\Mods.ini, %Ctrl%S, %File%
        RunWait, Bin\DrsBuild.exe /e "%GLocation%\Data\%Drs%" %File%.slp /o "%A_ScriptDir%",, Hide
        HashVal := HashFile(File ".slp", 2)
        If (HashVal = RefMD5)
        {
            GuiControl, Main:Hide, %Ctrl%S
            GuiControl, Main:Hide, %Ctrl%SU
            GuiControl, Main:Show, %Ctrl%SI
        }
        Else
        {
            GuiControl, Main:Hide, %Ctrl%S
            GuiControl, Main:Hide, %Ctrl%SI
            GuiControl, Main:Show, %Ctrl%SU
        }
        FileDelete, %File%.slp
    }
}
RestoreMod(GLocation, ModShortName)
{
    If (ModShortName != "tg") && (ModShortName != "to")
    {
        IniRead, Drsname, % "Mods\" ModShortName "\IU.ini", % ModShortName, Drs
        Loop, Parse, % Drsname, `,
        {
            Prename := SubStr(A_LoopField, 1, 3)
            Drs := A_LoopField
            If FileExist("Mods\" ModShortName "\" Prename "*.slp")
                Name := Prename "*.slp"
            Else If FileExist("Mods\" ModShortName "\" Prename "*.bin")
                Name := Prename "*.bin"
            RunWait, Bin\DrsBuild.exe /r "%GLocation%\Data\%Drs%.drs" "%GLocation%\Data\Backup\%ModShortName%\%Name%",, Hide
        }
    }
    Else
    {
        RunWait, Bin\DrsBuild.exe /e "%GLocation%\Data\interfac.drs" int50500.bin /o "%A_ScriptDir%",, hide
        FileReadLine, StartLine, Mods\%ModShortName%\U\int50500.bin, 1
        FileRead, 50500Content, int50500.bin
        Loop, 8
        {
            FileReadLine, LineToBeReplaced, int50500.bin, % StartLine + A_Index - 1
            FileReadLine, ReplacementLine, Mods\%ModShortName%\U\int50500.bin, % A_Index + 1
            50500Content := StrReplace(50500Content, LineToBeReplaced, ReplacementLine)
        }
        FileDelete, int50500.bin
        FileAppend, %50500Content%, int50500.bin
        RunWait, Bin\DrsBuild.exe /r "%GLocation%\Data\interfac.drs" "int50500.bin",, Hide
        Sleep, 1000
        FileDelete, int50500.bin
    }
}
InstallMod(GLocation, ModShortName)
{
    IniRead, Drsname, % "Mods\" ModShortName "\IU.ini", % ModShortName, Drs
    Loop, Parse, % Drsname, `,
    {
        Prename := SubStr(A_LoopField, 1, 3)
        Drs := A_LoopField
        If FileExist("Mods\" ModShortName "\" Prename "*.slp")
            Name := Prename "*.slp"
        RunWait, Bin\DrsBuild.exe /r "%GLocation%\Data\%Drs%.drs" "Mods\%ModShortName%\%Name%",, Hide
    }
}
UninstallMod(GLocation, ModShortName)
{
    IniRead, Drsname, % "Mods\" ModShortName "\IU.ini", % ModShortName, Drs
    Loop, Parse, % Drsname, `,
    {
        Prename := SubStr(A_LoopField, 1, 3)
        Drs := A_LoopField
        If FileExist("Mods\" ModShortName "\" Prename "*.slp")
            Name := Prename "*.slp"
        RunWait, Bin\DrsBuild.exe /r "%GLocation%\Data\%Drs%.drs" "Mods\%ModShortName%\U\%Name%",, Hide
    }
}
ApplyPrevWS(GameLocation, Ver, Type)
{
    If (Type = "AOC")
        Exename := "\age2_x1\age2_x1"
    If (Type = "AOK")
        Exename := "\empires2"
    If FileExist(GameLocation Exename "_" Ver "_" A_ScreenWidth "x" A_ScreenHeight ".exe")
        FileCopy, % GameLocation Exename "_" Ver "_" A_ScreenWidth "x" A_ScreenHeight ".exe", % GameLocation Exename ".exe", 1
}
ApplyPatch(GFolder, Ver, Type)
{
    If (Type = "AOK")
    {
        If (CleanAoK(GFolder) = False)
        {
            MsgBox , 16, % 33_, % 42
            Return
        }
        If (Ver = "2.0b")
            FileCopyDir, % "Versions\2.0a", % GFolder, 1
        FileCopyDir, % "Versions\" Ver, % GFolder, 1
        If (Ver = "2.0c")
        {
            FileCopyDir, % "Versions\2.0c", % GFolder, 1
            LngDLL := GFolder "\language.dll"
            If FileExist("Bin\RH.exe") && FileExist("Bin\679.res") && FileExist("Bin\680.res")
            {
                RunWait, Bin\RH.exe -open "%LngDLL%" -save "%LngDLL%" -action addoverwrite -res Bin\679.res -mask STRINGTABLE,,
                RunWait, Bin\RH.exe -open "%LngDLL%" -save "%LngDLL%" -action addoverwrite -res Bin\680.res -mask STRINGTABLE,,
                FileDelete, Bin\RH.ini
            }
            Else
            {
                MsgBox , 16, % 33_, % 43_
                Return
            }
        }
        If ErrorLevel
        {
            MsgBox , 16, % 33_, % 44_
            Return
        }
    }
    If (Type = "AOC")
    {
        If (CleanAoC(GFolder) = False)
        {
            MsgBox , 16, % 33_, % 42_
            Return
        }
        If (Ver = "1.0e")
            FileCopyDir, % "Versions\1.0c", % GFolder, 1
        FileCopyDir, % "Versions\" Ver, % GFolder, 1
        If ErrorLevel
        {
            MsgBox , 16, % 33_, % 44_
            Return
        }
    }
}
UpdateDRSFile(DataDir, Drsname, Type)
{
    FileCopy, Bin\AOK\Bmp\int*.Bmp, %A_ScriptDir%
    If (Type = "AOC")
    {
        FileCopy, Bin\TC\Bmp\int*.Bmp, %A_ScriptDir%
        RunWait, Bin\PythonCore\PythonCore.exe aoc,, Hide
    }
    Else
        RunWait, Bin\PythonCore\PythonCore.exe aok,, Hide
    Loop, Files, Fixedint\int*.bmp
        RunWait, Bin\Bmp2Slp.exe Fixedint\%A_LoopFileName%,, Hide
    FileCopy, %DataDir%\Data\interfac.drs, %DataDir%\Data\interfac_.drs, 1
    RunWait, Bin\DrsBuild.exe /r "%DataDir%\Data\interfac_.drs" Fixedint\*.slp,, Hide
    If (Type = "AOC")
        RunWait, Bin\DrsBuild.exe /d "%DataDir%\Data\interfac_.drs" int53207.slp,, Hide
    FileMove, %DataDir%\Data\interfac_.drs, %DataDir%\Data\%Drsname%, 1
    FileDelete, *.bmp
    FileRemoveDir, Fixedint, 1
}
DeleteLine(Text, Line)
{
    Result := ""
    Loop, Parse, % Text, `r, `n
    {
        If (A_Index != Line)
            Result .= A_LoopField "`n"
    }
    Return Result
}
UpdateLng(OutDir)
{
    LngIds := ["14:591:9", "8:596:7", "8:1948:7"]
    NewName := "language_" A_ScreenWidth "x" A_ScreenHeight ".dll"
    FileCopy, %OutDir%\language.dll, %OutDir%\%NewName%, 1
    For K, V in LngIds
    {
        Arr := StrSplit(V, ":")
        I := Arr[1], Val := Arr[2], 2Rep := Arr[3]
        RunWait, Bin\RH.exe -open "%OutDir%\language.dll" -save Bin\%Val%.rc -action extract -mask STRINGTABLE`,%Val%`,
        FileRead, OutputVar, Bin\%Val%.rc
        FileReadLine, LineContent, Bin\%Val%.rc, %I%
        If InStr(LineContent, "1280 x 1024")
            OutputVar := DeleteLine(OutputVar, I)
        FileReadLine, LineContent, Bin\%Val%.rc, %2Rep%
        Position := RegexMatch(LineContent, "\d+ x \d+", ResoVar)
        OutputVar := StrReplace(OutputVar, ResoVar, A_ScreenWidth " x " A_ScreenHeight)
        If FileExist("Bin\" Val ".rc")
            FileDelete, Bin\%Val%.rc
        FileAppend, %OutputVar%, Bin\%Val%.rc
        RunWait, Bin\RH.exe -open Bin\%Val%.rc -save Bin\%Val%.res -action compile
        RunWait, Bin\RH.exe -open "%OutDir%\%NewName%" -save "%OutDir%\%NewName%" -action addoverwrite -res Bin\%Val%.res -mask STRINGTABLE`,%Val%`,
        FileDelete, Bin\%Val%.rc
        FileDelete, Bin\%Val%.res
    }
    FileCopy, %OutDir%\%NewName%, %OutDir%\language.dll, 1
    FileDelete, Bin\RH.ini
}
FixDelayedStart()
{
    If InStr(FileExist(A_WinDir "\SysWOW64"), "D")
        WD := "SysWOW64"
    Else If InStr(FileExist(A_WinDir "\SysWow32"), "D")
        WD := "System32"
    If FileExist(A_WinDir "\" WD "\gameux.dll")
    {
        RunWait, takeown /f %A_WinDir%\%WD%\gameux.dll,, Hide
        RunWait, cacls %A_WinDir%\%WD%\gameux.dll /E /P "%username%":F,, Hide
        FileMove, %A_WinDir%\%WD%\gameux.dll, %A_WinDir%\%WD%\gameux_renamed.dll, 1
    }
    If FileExist(A_WinDir "\" WD "\gameux.dll")
    {
        GuiControl, Main:Hide, DSS
        GuiControl, Main:Hide, DSSI
        GuiControl, Main:Show, DSSU
    }
    Else
    {
        GuiControl, Main:Hide, DSS
        GuiControl, Main:Hide, DSSU
        GuiControl, Main:Show, DSSI
    }
}
UnFixDelayedStart()
{
    If InStr(FileExist(A_WinDir "\SysWOW64"), "D")
        WD := "SysWOW64"
    Else If InStr(FileExist(A_WinDir "\SysWow32"), "D")
        WD := "System32"
    If FileExist(A_WinDir "\" WD "\gameux_renamed.dll")
    {
        RunWait, takeown /f %A_WinDir%\%WD%\gameux_renamed.dll,, Hide
        RunWait, cacls %A_WinDir%\%WD%\gameux_renamed.dll /E /P "%username%":F,, Hide
        FileMove, %A_WinDir%\%WD%\gameux_renamed.dll, %A_WinDir%\%WD%\gameux.dll, 1
    }
    If FileExist(A_WinDir "\" WD "\gameux.dll")
    {
        GuiControl, Main:Hide, DSS
        GuiControl, Main:Hide, DSSI
        GuiControl, Main:Show, DSSU
    }
    Else
    {
        GuiControl, Main:Hide, DSS
        GuiControl, Main:Hide, DSSU
        GuiControl, Main:Show, DSSI
    }
}
FixRecords(GameLocation)
{
    Try := 0
    Loop, Files, %GameLocation%\SaveGame\*.*, R
    {
        If InStr("mgx,mgl", A_LoopFileExt) && !InStr(A_LoopFileFullPath, "_RMF")
        {
            RunWait, Bin\mgxfix -f "%A_LoopFileFullPath%",, Hide
            RunWait, Bin\revealfix "%A_LoopFileFullPath%",, Hide
            SplitPath, % A_LoopFileFullPath,, OutDir, OutExtension, OutNameNoExt
            FileMove, % A_LoopFileFullPath, % OutDir "\" OutNameNoExt "_RMF." OutExtension
            If (Try = 0)
                Try++
            If (Try = 1)
            {
                FormatTime, Val,, yyyy'/'MM'/'dd
                UpdateINI("Lst_RBF", Val "|" GameLocation)
                GuiControl, Main:, RBL, %Val%
            }
        }
    }
}
FixIntAoC(OutDir, DrsName)
{
    FileCopy, Bin\AoK\Bmp\int51*.Bmp, %A_ScriptDir%, 1
    FileCopy, Bin\TC\Bmp\int51*.Bmp, %A_ScriptDir%, 1
    Loop, Files, int51*.bmp
        ResizeTntAoC(A_LoopFileName)
    Loop, Files, int51*.bmp
        RunWait, Bin\Bmp2Slp.exe %A_LoopFileName%,, Hide
    FileCopy, %OutDir%\Data\interfac.drs, %OutDir%\Data\%DrsName%, 1
    RunWait, Bin\DrsBuild.exe /r "%OutDir%\Data\%DrsName%" *.slp,, Hide
    Pre := SubStr(DrsName, 1, 3)
    RunWait, Bin\DrsBuild.exe /d "%OutDir%\Data\%DrsName%" %Pre%53207.slp,, Hide
    FileDelete, int51*.bmp
    FileDelete, int51*.slp
    Return 1
}
FixIntAoK(OutDir, DrsName)
{
    FileCopy, Bin\AOK\Bmp\int51*.Bmp, %A_ScriptDir%, 1
    Loop, Files, int51*.bmp
        ResizeTntAoK(A_LoopFileName)
    Loop, Files, int51*.bmp
        RunWait, Bin\Bmp2Slp.exe %A_LoopFileName%,, Hide
    FileCopy, %OutDir%\Data\interfac.drs, %OutDir%\Data\%DrsName%, 1
    RunWait, Bin\DrsBuild.exe /r "%OutDir%\Data\%DrsName%" *.slp,, Hide
    FileDelete, int51*.bmp
    FileDelete, int51*.slp
    Return 1
}
ResizeTntAoC(File)
{
    mc =
    (ltrim join
    2,x86:VVdWU4PsOIt0JFSLRCRMD7ZWDYnRD7ZWDMHhGMHiEAHKD7ZOC8HhCAHKD7ZOCot0JFwB0Q+2VgyJTCQUD7ZODcHiEMHhGAHRD7ZWC8HiCAHKD7ZOCo00Col0JDCLdCRUD7ZOFQ+2VhTB4RjB4hAB0Q+2VhPB4ggByg+2ThKLdCRcD7ZeFY08Cg+2VhSJ3sHiEMHmGMHjGYnxi3QkXAHRD7ZWE8HiCAHKD7ZOEot0JFSNLAoPtk4ZD7ZWGMHhGMHiEAHRD7ZWF8HiCAHKD7ZOFo00Col0JASLdCRcD7ZOGA+2VhfB4RDB4ggB2QHKD7ZOFo00CotMJBSJdCQMi3QkUA+v8I0cMYk0JIlcJAiFyQ+OagUAAItMJFSNUQMrVCRYg/oGi1QkWA+XwQtUJFSD4gMPlMKE0Q+EVAUAAItMJBSNUf+D+gMPhkQFAACLXCRYg+H8i1QkVIlEJEwB2YsCg8MEg8IEiUP8Oct18YtMJFSLRCRMiTQki3QkFInzAfGD4/yJTCQQidqJ8/bDA3Q/i0wkVIt0JFgPtgwRiAwWjUoBOct+KYt0JFQPtkwWAYt0JFiITBYBjUoCOct+EYt0JFQPtkwWAot0JFiITBYCi0wkWItcJAiJbCQYizQkiVkCicuJQRKLTCRQiXMiMfaJSxaLXCQEjVP/id0Pr9cDVCQQiVQkHI1R/w+v0ANUJFgDVCQUiVQkCI20JgAAAABmkIXtD46YAwAAuhkAAACLXCQci0wkCIkUJAHzAfGNdCYAD7YTKfuIESnBgywkAXXxg8YBgf6DAQAAdcaLTCQEi3QkEI2Rrv3//4nND6/XAfKJVCQgadCuAAAAA1QkWANUJBSJVCQQaddRAgAAAfIx9olUJCSNdCYAkIXtD47gAgAAi1QkEItcJCCNDBa6rwAAAAHziRQkjXYAD7YTKfuIESnBgywkAXXxg8YBgf4XAQAAdcaLXCQUi0wkJGnQrwAAADH2A1QkWItsJBiNlBOk/v//jZmkAgAAiVwkLItcJCCJVCQYjZOkAgAAiWwkNItsJASJVCQohe0PjiMCAAC6rwAAAItcJCiLTCQYiRQkAfMB8Y20JgAAAAAPthMp+4gRKcGDLCQBdfGDxgGB/lwBAAB1w4tcJCCNsI79//+LbCQ0iXQkKIHDGAEAAIlcJCCF9g+OfgAAAIlsJDSLTCQQg/5NvU0AAAAPTu4x9o2RFgEAAIlUJBiLVCQkjYoYAQAAiUwkLItcJASF2w+OlAIAAItMJCCLVCQYjRwxjQwyuq8AAACJFCSNdgAPthMp+4gRKcGDLCQBdfGDxgE57nXFg2wkKE2LdCQog0QkEE2F9n+Ki2wkNIt0JFSLXCQUx0QkEIIBAACNtB6CAQAAiXQkGD2CAQAAD46AAAAAiWwkIInFK2wkELp+AgAAgf1+AgAAD0/qMfaLTCQEhckPjsABAACLTCQci1QkCI2cDoIBAACNDBa6GQAAAIkUJI22AAAAAA+2Eyn7iJGCAQAAKcGDLCQBde2DxgE57nW6gUQkEH4CAACLdCQQicKBRCQIfgIAACnyhdJ/iItsJCCLfCQMi3QkMAN0JFyNV/+JdCQID6/VAfKLdCRYiVQkBI0UwI08ljH2A3wkFItUJAyF0n49uh0AAACLXCQEjQw+iRQkAfOQD7YTKeuIkQz+//8pwYMsJAF17YPGAYH+iAAAAHXIg8Q4uAEAAABbXl9dw7odAAAAi1wkCI0MPokUJAHzjXQmAA+2EwHriJEM/v//KcGDLCQBde2DxgGB/ogAAAB1iOu+i1QkGItcJCyNDDK6rwAAAAHziRQkjXYAD7YTAfuIESnBgywkAXXxg8YBgf5cAQAAD4Wf/f//6df9//+NdCYAkItUJCSLTCQQjRwyuq8AAAAB8YkUJI12AA+2EwH7iBEpwYMsJAF18YPGAYH+FwEAAA+F4vz//+kX/f//jXQmAJCLVCQQi0wkCI0cMroZAAAAAfGJFCSNdgAPthMB+4gRKcGDLCQBdfGDxgGB/oMBAAAPhSr8///pX/z//410JgCQi1QkGI0cMotUJAiNDBa6GQAAAIkUJI20JgAAAACNdgAPthMB+4iRggEAACnBgywkAXXtg8YBOe4Phfb9///pN/7//4tUJCyNHDKLVCQYjQwyuq8AAACJFCSNtCYAAAAAD7YTAfuIESnBgywkAXXxg8YBOe4PhSn9///pX/3//4nLi0wkVAHZiUwkEOk++///i1QkVItcJBSLTCRYizQkAdOJXCQQD7Yag8EBg8IBiFn/O1QkEHXuiTQk6Q/7//8=
    )
    mc := mcode(mc)
    f := fileopen(File,"r")
    srcSize := f.length
    varsetcapacity(source,srcSize)
    f.rawread(source,srcSize)
    f.close()
    headerSize := numget(source,0xa)
    dstW := A_ScreenWidth
    dstH := A_ScreenHeight
    dstPixels := dstW*dstH
    dstSize := headerSize+dstPixels
    f := fileopen("Bin\TC\Bmp\Overlay.bmp","r")
    varsetcapacity(overlay,f.length)
    f.rawread(overlay,f.length)
    f.close()
    varsetcapacity(dest,dstSize,0x8)
    if (v := dllcall(mc,int,dstW,int,dstH,ptr,&source,ptr,&dest,ptr,&overlay,"cdecl int"))
    {
        f := fileopen(File,"w")
        f.rawwrite(dest,dstSize)
        f.close()
    }
}
ResizeTntAoK(File)
{
    mc =
    (ltrim join
    2,x86:VVdWU4PsOIt0JFSLRCRMD7ZWDcHiGInRD7ZWDMHiEAHKD7ZOC8HhCAHKD7ZOCot0JFwB0Q+2VgyJTCQUD7ZODcHiEMHhGAHRD7ZWC8HiCAHKD7ZOCo00Col0JDCLdCRUD7ZOFQ+2VhTB4RjB4hAB0Q+2VhPB4ggByg+2ThKLdCRcD7ZeFY08Cg+2VhSJ3sHiEMHmGMHjGYnxi3QkXAHRD7ZWE8HiCAHKD7ZOEot0JFSNLAoPtk4ZD7ZWGMHhGMHiEAHRD7ZWF8HiCAHKD7ZOFo00Col0JASLdCRcD7ZOGA+2VhfB4RDB4ggB2QHKD7ZOFo00CotMJBSJdCQMi3QkUA+v8I0cMYk0JIlcJAiFyQ+OagUAAItMJFSNUQMrVCRYg/oGi1QkWA+XwQtUJFSD4gMPlMKE0Q+EVAUAAItMJBSNUf+D+gMPhkQFAACLXCRYg+H8i1QkVIlEJEwB2YsCg8MEg8IEiUP8Oct18YtMJFSLRCRMiTQki3QkFInzAfGD4/yJTCQQidqJ8/bDA3Q/i0wkVIt0JFgPtgwRiAwWjUoBOct+KYt0JFQPtkwWAYt0JFiITBYBjUoCOct+EYt0JFQPtkwWAot0JFiITBYCi0wkWItcJAiJbCQYizQkiVkCicuJQRKLTCRQiXMii3QkUIlLFotMJASNUf+JzQ+v1wNUJBCJVCQcjVb/MfYPr9AB2gNUJBSJVCQIjbQmAAAAAIXtD46gAwAAuhkAAACLXCQci0wkCIkUJAHzAfGNdCYAD7YTKfuIESnBgywkAXXxg8YBgf6DAQAAdcaLXCQEi3QkEI2Trv3//4ndD6/XAfKJVCQgadCuAAAAA1QkWANUJBSJVCQQaddRAgAAAfIx9olUJCSNdCYAkIXtD47oAgAAi1QkEItcJCCNDBa6rwAAAAHziRQkjXYAD7YTKfuIESnBgywkAXXxg8YBgf4XAQAAdcaLXCQUadCvAAAAA1QkWDH2i2wkGI2UE6T+//+LXCQkiVQkGI2LpAIAAIlsJDSLbCQEiUwkLItMJCCNkaQCAACJVCQohe0PjiMCAAC6rwAAAItcJCiLTCQYiRQkAfMB8Y20JgAAAAAPthMp+4gRKcGDLCQBdfGDxgGB/lwBAAB1w4tMJCCNsI79//+LbCQ0iXQkKIHBGAEAAIlMJCCF9g+OfgAAAIlsJDSLXCQQg/5NvU0AAAAPTu4x9o2TFgEAAIlUJBiLVCQkjZoYAQAAiVwkLItcJASF2w+OlAIAAItMJCCLVCQYjRwxjQwyuq8AAACJFCSNdgAPthMp+4gRKcGDLCQBdfGDxgE57nXFg2wkKE2LdCQog0QkEE2F9n+Ki2wkNIt0JFSLTCQUx0QkEIIBAACNtA6CAQAAiXQkGD2CAQAAD46AAAAAiWwkIInFK2wkELp+AgAAgf1+AgAAD0/qMfaLTCQEhckPjsgBAACLTCQci1QkCI2cDoIBAACNDBa6GQAAAIkUJI22AAAAAA+2Eyn7iJGCAQAAKcGDLCQBde2DxgE57nW6gUQkEH4CAACLdCQQicKBRCQIfgIAACnyhdJ/iItsJCCLfCQMi3QkMAN0JFyNV/+LfCQUiXQkCA+v1QHyMfaJVCQEa9BtA1QkWI28F/T9//+LVCQMhdJ+PbptAAAAi1wkBI0MN4kUJAHzjXQmAJAPthMp64gRKcGDLCQBdfGDxgGB/rAAAAB1yIPEOLgBAAAAW15fXcO6bQAAAItcJAiNDDeJFCQB8w+2EwHriBEpwYMsJAF18YPGAYH+sAAAAHWQ68aNdCYAi0wkLItUJBiNHDGNDDK6rwAAAIkUJI20JgAAAACNdgAPthMB+4gRKcGDLCQBdfGDxgGB/lwBAAAPhZf9///pz/3//410JgCQi1QkEItcJCSNDBa6rwAAAAHziRQkjXYAD7YTAfuIESnBgywkAXXxg8YBgf4XAQAAD4Xa/P//6Q/9//+NdCYAkItUJBCLTCQIjRwyuhkAAAAB8YkUJI12AA+2EwH7iBEpwYMsJAF18YPGAYH+gwEAAA+FIvz//+lX/P//jXQmAJCLVCQIi1wkGI0MFroZAAAAAfOJFCSNdgAPthMB+4iRggEAACnBgywkAXXtg8YBOe4Phfb9///pN/7//4tUJCyNHDKLVCQYjQwyuq8AAACJFCSNtCYAAAAAD7YTAfuIESnBgywkAXXxg8YBOe4PhSn9///pX/3//4nLi0wkVAHZiUwkEOk++///i1QkVItcJBSLTCRYizQkAdOJXCQQD7Yag8EBg8IBiFn/O1QkEHXuiTQk6Q/7//8=
    )
    mc := mcode(mc)
    f := fileopen(File,"r")
    srcSize := f.length
    varsetcapacity(source,srcSize)
    f.rawread(source,srcSize)
    f.close()
    headerSize := numget(source,0xa)
    dstW := A_ScreenWidth
    dstH := A_ScreenHeight
    dstPixels := dstW*dstH
    dstSize := headerSize+dstPixels
    f := fileopen("Bin\AoK\Bmp\Overlay.bmp","r")
    varsetcapacity(overlay,f.length)
    f.rawread(overlay,f.length)
    f.close()
    varsetcapacity(dest,dstSize,0x8)
    if (v := dllcall(mc,int,dstW,int,dstH,ptr,&source,ptr,&dest,ptr,&overlay,"cdecl int"))
    {
        f := fileopen(File,"w")
        f.rawwrite(dest,dstSize)
        f.close()
    }
}
RenameDrsRefAoK(OutDir, Ver, DrsName)
{
    PatchedExe := FileOpen(OutDir "\empires2_" A_ScreenWidth "x" A_ScreenHeight ".exe" , "r")
    PatchedExe.RawRead(NewData, PatchedExeLen := PatchedExe.Length())
    If (Ver = "2.0") || (Ver = "2.0c")
        DrsRef := 2479120
    Else
        DrsRef := 2475120
    Loop, Parse, % DrsName
        NumPut(ASC(A_LoopField), NewData, DrsRef + A_Index - 1, "UChar")
    OutPatchedExe := FileOpen(OutDir "\empires2_" A_ScreenWidth "x" A_ScreenHeight ".exe" , "w")
    OutPatchedExe.RawWrite(NewData, PatchedExeLen)
    OutPatchedExe.Close()
    PatchedExe.Close()
    FileCopy, % OutDir "\empires2_" A_ScreenWidth "x" A_ScreenHeight ".exe", % OutDir "\empires2.exe", 1
    FileMove, % OutDir "\empires2_" A_ScreenWidth "x" A_ScreenHeight ".exe", % OutDir "\empires2_" Ver "_" A_ScreenWidth "x" A_ScreenHeight ".exe", 1
}
RenameDrsRefAoC(OutDir, Ver, DrsName)
{
    PatchedExe := FileOpen(OutDir "\age2_x1\age2_x1_" A_ScreenWidth "x" A_ScreenHeight ".exe" , "r")
    PatchedExe.RawRead(NewData, PatchedExeLen := PatchedExe.Length())
    If (Ver = "1.0")
        DrsRef := 2604688
    Else
        DrsRef := 2551448
    Loop, Parse, % DrsName
        NumPut(ASC(A_LoopField), NewData, DrsRef + A_Index - 1, "UChar")
    OutPatchedExe := FileOpen(OutDir "\age2_x1\age2_x1_" A_ScreenWidth "x" A_ScreenHeight ".exe" , "w")
    OutPatchedExe.RawWrite(NewData, PatchedExeLen)
    OutPatchedExe.Close()
    PatchedExe.Close()
    FileCopy, % OutDir "\age2_x1\age2_x1_" A_ScreenWidth "x" A_ScreenHeight ".exe", % OutDir "\age2_x1\age2_x1.exe", 1
    FileMove, % OutDir "\age2_x1\age2_x1_" A_ScreenWidth "x" A_ScreenHeight ".exe", % OutDir "\age2_x1\age2_x1_" Ver "_" A_ScreenWidth "x" A_ScreenHeight ".exe", 1
}
BinWrite(File, HexData, Offset)
{
    Exe := FileOpen(File , "r")
    ExeLen := Exe.Length()
    Exe.RawRead(Data, ExeLen)
    Loop, Parse, % HexData, "."
    {
        Byte := Format("{:i}", "0x" A_LoopField)
        NumPut(Byte, Data, Offset + A_Index - 1, "UChar")
    }
    oExe := FileOpen(File, "w")
    oExe.RawWrite(Data, ExeLen)
    oExe.Close()
    Exe.Close()
}
WriteDRSRef(GDir, Exe, Ver, Type)
{
    PatchedExe := FileOpen(Exe , "r")
    PatchedExe.RawRead(NewData, PatchedExeLen := PatchedExe.Length())
    WSFilename := ""
    Loop, Files, *.ws
    {
        If (A_LoopFileName ~= "\d+\.ws") && StrLen(A_LoopFileName = 12) && (A_Index = 1)
        {
            WSFilename := A_LoopFileName
            FileDelete, % WSFilename
        }
        Break
    }
    If (WSFilename != "")
    {
        If (Ver = "2.0") || (Ver = "2.0c")
            DrsRef := 2479120
        Else If (Ver = "2.0a") || (Ver = "2.0b")
            DrsRef := 2475120
        Else If (Ver = "1.0")
            DrsRef := 2604688
        Else If (Ver = "1.0c") || (Ver = "1.0e")
            DrsRef := 2551448
        If (Type = "AOK")
        {
            Name := WSFilename "_a"
            Exename := GDir "\empires2"
        }
        If (Type = "AOC")
        {
            Name := WSFilename "_c"
            Exename := GDir "\age2_x1\age2_x1"
        }
        Loop, Parse, % Name
            NumPut(ASC(A_LoopField), NewData, DrsRef + A_Index - 1, "UChar")
        OutPatchedExe := FileOpen(Exe , "w")
        OutPatchedExe.RawWrite(NewData, PatchedExeLen)
        OutPatchedExe.Close()
        PatchedExe.Close()
        FileCopy, % Exe, % Exename ".exe", 1
        FileMove, % Exe, % Exename "_" Ver "_" A_ScreenWidth "x" A_ScreenHeight ".exe", 1
    }
    UpdateDRSFile(GDir, Name, Type)
}
UpdateINI(Ver, Val)
{
    If FileExist(D "\AoEII_Location.ini")
        IniWrite, % Val, % D "\AoEII_Location.ini", AoEII_Location, % Ver
}
CheckEXESize(Exe, Type)
{
    If (Type = "AOK")
    {
        FileGetSize, Size, % Exe, B
        If (Size = 2560000)
        {
            Text := ""
            ExeRaw := FileOpen(Exe , "r")
            ExeRaw.RawRead(Data, ExeLen := ExeRaw.Length())
            Loop 10
                Text .= Chr(NumGet(Data, 2210211 + A_Index - 1, "UChar"))
            ExeRaw.Close()
            If (Text = "patch.dll")
                Return "2.0c"
            Else
                Return "2.0"
        }
        Else If (Size = 2555949)
            Return "2.0a"
        Else If (Size = 2555904)
            Return "2.0b"
        Else
            Return ""
    }
    If (Type = "AOC")
    {
        FileGetSize, Size, % Exe, B
        If (Size = 2695213)
            Return "1.0"
        Else If (Size = 2699309)
        {
            SplitPath, % Exe,, OutDir
            If FileExist(OutDir "\on.ini") && (HashFile(OutDir "\on.ini", 2) = 2AFAC59FF5745529B53B8F71A26333B5)
                Return "1.0e"
            Else
                Return "1.0c"
        }
        Else
            Return ""
    }
}
UpdateVersionView(GFolder, AoKVer, AoCVer)
{
    If (GFolder != "") && (AoKVer != "")
    {
        Ref := ""
        Exe := FileOpen(GFolder "\empires2.exe" , "r")
        Exe.RawRead(Data, ExeLen := Exe.Length())
        If (AOKVer = "2.0") || (AOKVer = "2.0c")
            DrsRef := 2479120
        Else If (AOKVer = "2.0a") || (AOKVer = "2.0b")
            DrsRef := 2475120
        Loop 15
            Ref .= Chr(NumGet(Data, DrsRef + A_Index - 1, "UChar"))
        If FileExist(GFolder "\Data\" Ref) && (Ref ~= "\d+x?\d+(_a\.drs|\.ws|\.ws_a)")
        {
            GuiControl, Main:Hide, WTAoKS
            GuiControl, Main:Hide, WTAoKSU
            GuiControl, Main:Show, WTAoKSI
        }
        Else
        {
            GuiControl, Main:Hide, WTAoKSI
            GuiControl, Main:Hide, WTAoKSU
            GuiControl, Main:Show, WTAoKS
        }
        Exe.Close()
    }
    If (GFolder != "") && (AoCVer != "")
    {
        Ref := ""
        Exe := FileOpen(GFolder "\age2_x1\age2_x1.exe" , "r")
        Exe.RawRead(Data, ExeLen := Exe.Length())
        If (AOCVer = "1.0")
            DrsRef := 2604688
        Else If (AOCVer = "1.0c") || (AOCVer = "1.0e")
            DrsRef := 2551448
        Loop 15
            Ref .= Chr(NumGet(Data, DrsRef + A_Index - 1, "UChar"))
        If FileExist(GFolder "\Data\" Ref) && (Ref ~= "\d+x?\d+(_c\.drs|\.ws|\.ws_c)")
        {
            GuiControl, Main:Hide, WTCS
            GuiControl, Main:Hide, WTCSU
            GuiControl, Main:Show, WTCSI
        }
        Else
        {
            GuiControl, Main:Hide, WTCSI
            GuiControl, Main:Hide, WTCSU
            GuiControl, Main:Show, WTCS
        }
        Exe.Close()
    }
}
UninstallWSAoK(GameLocation)
{
    GetGameVersion(GameLocation, "AOK", "")
    IniRead, AoKVer, % D "\AoEII_Location.ini", AoEII_Location, AoKVer
    ExePath := GameLocation "\Data\" AoKVer "-WSPatchRestore\empires2.exe"
    Dll := GameLocation "\Data\" AoKVer "-WSPatchRestore\language.dll"
    If FileExist(ExePath)
        FileCopy, % ExePath, % GameLocation, 1
    If FileExist(Dll)
        FileCopy, % Dll, % GameLocation, 1
    UpdateVersionView(GameLocation, AoKVer, "")
}
UninstallWSTC(GameLocation)
{
    GetGameVersion(GameLocation, "", "AOC")
    IniRead, AoCVer, % D "\AoEII_Location.ini", AoEII_Location, AoCVer
    ExePath := GameLocation "\Data\" AoCVer "-WSPatchRestore\age2_x1.exe"
    Dll := GameLocation "\Data\" AoCVer "-WSPatchRestore\language.dll"
    If FileExist(ExePath)
        FileCopy, % ExePath, % GameLocation "\age2_x1\", 1
    If FileExist(Dll)
        FileCopy, % Dll, % GameLocation, 1
    UpdateVersionView(GameLocation, "", AoCVer)
}
InstallWSAoK(GameLocation)
{
    GetGameVersion(GameLocation, "AOK", "")
    IniRead, AoKVer, % D "\AoEII_Location.ini", AoEII_Location, AoKVer
    ExePath := GameLocation "\empires2.exe"
    Dll := GameLocation "\language.dll"
    If !InStr(FileExist(GameLocation "\Data\" AoKVer "-WSPatchRestore"), "D")
        FileCreateDir, % GameLocation "\Data\" AoKVer "-WSPatchRestore"
    FileCopy, %ExePath%, % GameLocation "\Data\" AoKVer "-WSPatchRestore", 1
    FileCopy, %Dll%, % GameLocation "\Data\" AoKVer "-WSPatchRestore", 1
    If (AoKVer = "2.0") || (AoKVer = "2.0c")
        RunWait, Bin\Patcher.exe "%ExePath%" Bin\AoK\AoK_2.0.patch,, Hide
    Else If (AoKVer = "2.0a") || (AoKVer = "2.0b")
        RunWait, Bin\Patcher.exe "%ExePath%" Bin\AoK\AoK_2.0ab.patch,, Hide
    FileDelete, *.ws
    DrsName := A_ScreenWidth "x" A_ScreenHeight "_a.drs"
    RenameDrsRefAoK(GameLocation, AoKVer, DrsName)
    FixIntAoK(GameLocation, DrsName)
    UpdateLng(GameLocation)
    UpdateVersionView(GameLocation, AoKVer, "")
}
InstallWSTC(GameLocation)
{
    GetGameVersion(GameLocation, "", "AOC")
    IniRead, AoCVer, % D "\AoEII_Location.ini", AoEII_Location, AoCVer
    ExePath := GameLocation "\age2_x1\age2_x1.exe"
    Dll := GameLocation "\language.dll"
    If !InStr(FileExist(GameLocation "\Data\" AoCVer "-WSPatchRestore"), "D")
        FileCreateDir, % GameLocation "\Data\" AoCVer "-WSPatchRestore"
    FileCopy, %ExePath%, % GameLocation "\Data\" AoCVer "-WSPatchRestore"
    FileCopy, %Dll%, % GameLocation "\Data\" AoCVer "-WSPatchRestore", 1
    If (AoCVer = "1.0")
        RunWait, Bin\Patcher.exe "%ExePath%" Bin\TC\AoC_1.0.patch,, Hide
    Else If (AoCVer = "1.0c") || (AoCVer = "1.0e")
        RunWait, Bin\Patcher.exe "%ExePath%" Bin\TC\AoC_1.0c_1.0e.patch,, Hide
    FileDelete, *.ws
    DrsName := A_ScreenWidth "x" A_ScreenHeight "_c.drs"
    RenameDrsRefAoC(GameLocation, AoCVer, DrsName)
    FixIntAoC(GameLocation, DrsName)
    UpdateLng(GameLocation)
    UpdateVersionView(GameLocation, "", AoCVer)
}
GetGameVersion(GFolder, GameType, GameType_)
{
    AoKVer := "", AoCVer := ""
    If (GameType = "AOK")
    {
        VersionsTable := ["2.0","2.0a","2.0b","2.0c"]
        For I, Ver in VersionsTable
        {
            IniRead, Number, Versions\INI\MD5[%Ver%].ini, %Ver%, NumberOfFiles
            If (Number != "ERROR")
            {
                AoKVer := Ver
                Loop, % Number
                {
                    FileReadLine, IniLine, Versions\INI\MD5[%Ver%].ini, % A_Index + 1
                    Key_Value := StrSplit(IniLine, "=")
                    HashVal := HashFile(GFolder "\" StrReplace(Key_Value[1], Ver "\", ""), 2)
                    If (HashVal != Key_Value[2])
                    {
                        AoKVer := ""
                        Break
                    }
                }
            }
            If (AoKVer = Ver)
                Break
        }
        If (AoKVer = "")
            AoKVer := CheckEXESize(GFolder "\empires2.exe", "AOK")
        UpdateINI("AoKVer", AoKVer)
    }
    If (GameType_ = "AOC")
    {
        VersionsTable := ["1.0","1.0e","1.0c"]
        For I, Ver in VersionsTable
        {
            IniRead, Number, Versions\INI\MD5[%Ver%].ini, %Ver%, NumberOfFiles
            If (Number != "ERROR")
            {
                AoCVer := Ver
                Loop, % Number
                {
                    FileReadLine, IniLine, Versions\INI\MD5[%Ver%].ini, % A_Index + 1
                    Key_Value := StrSplit(IniLine, "=")
                    HashVal := HashFile(GFolder "\" StrReplace(Key_Value[1], Ver "\", ""), 2)
                    If (HashVal != Key_Value[2])
                    {
                        AoCVer := ""
                        Break
                    }
                }
            }
            If (AoCVer = Ver)
                Break
        }
        If (AoCVer = "")
        {
            If FileExist(GFolder "\age2_x1\age2_x1.exe")
                AoCVer := CheckEXESize(GFolder "\age2_x1\age2_x1.exe", "AOC")
            Else If FileExist(GFolder "\age2_x1.exe")
                AoCVer := CheckEXESize(GFolder "\age2_x1.exe", "AOC")
        }
        UpdateINI("AoCVer", AoCVer)
    }
}
FolderExist(FolderPath)
{
    If InStr(FileExist(FolderPath), "D")
        Return 1
    Else
        Return 0
}
Backup(GLocation, ModShortName)
{
    IniRead, Drsname, % "Mods\" ModShortName "\IU.ini", % ModShortName, Drs
    Loop, Parse, % Drsname, `,
    {
        Prename := SubStr(A_LoopField, 1, 3)
        Drs := A_LoopField
        If FileExist("Mods\" ModShortName "\" Prename "*.slp")
            Name := Prename "*.slp"
        If !FolderExist(GLocation "\Data\Backup")
            FileCreateDir, % GLocation "\Data\Backup"
        If !FolderExist(GLocation "\Data\Backup\" ModShortName)
            FileCreateDir, % GLocation "\Data\Backup\" ModShortName
        Loop, Files, % "Mods\" ModShortName "\" Name
        {
            If !FileExist(GLocation "\Data\Backup\" ModShortName "\" A_LoopFileName)
                RunWait, Bin\DrsBuild.exe /e "%GLocation%\Data\%Drs%.drs" "%A_LoopFileName%" /o "%GLocation%\Data\Backup\%ModShortName%",, Hide
        }
    }
}
VerifAoCInstall(GameLocation)
{
    If FileExist(GameLocation "\age2_x1\age2_x1.exe") && FileExist(GameLocation "\language_x1.dll")
        Return 1
    Else
        Return 0
}
CleanAoC(GameLocation)
{
    List =
    (
    age2_x1\age2_x1.exe
    age2_x1\AGE2_X1.ICD
    age2_x1\clcd32.dll
    age2_x1\clokspl.exe
    age2_x1\dplayerx.dll
    age2_x1\drvmgt.dll
    SETUPENU.DLL
    age2_x1\age.dll
    age2_x1\drvmgt.dll
    age2_x1\escape for assault.mod
        age2_x1\fmod.dll
    age2_x1\secdrv.sys
    language_x1_p1.dll
    Data\empires2_x1_p1.dat
    Data\gamedata_x1_p1.drs
    Random\ES@Canals_v2.rms
    Random\ES@Capricious_v2.rms
    Random\ES@Dingos_v2.rms
    Random\ES@Graveyards_v2.rms
    Random\ES@Metropolis_v2.rms
    Random\ES@Moats_v2.rms
    Random\ES@ParadiseIsland_v2.rms
    Random\ES@Pilgrims_v2.rms
    Random\ES@Prairie_v2.rms
    Random\ES@Seasons_v2.rms
    Random\ES@Sherwood_Forest_v2.rms
    Random\ES@Sherwood_Heroes_v2.rms
    Random\ES@Shipwreck_v2.rms
    Random\ES@Team_Glaciers_v2.rms
    Random\ES@The_Unknown_v2.rms
    age2_x1\on.ini
    age2_x1\miniupnpc.dll
    age2_x1\wndmode.dll
    )
    Loop, Parse, % List, `n, `r
    {
        If FileExist(GameLocation "\" LTrim(A_LoopField))
        {
            FileDelete, % GameLocation "\" LTrim(A_LoopField)
            If ErrorLevel
                Return False
        }
    }
    Return True
}
CleanAoK(GameLocation)
{
    List =
    (
    clcd32.dll
    dplayerx.dll
    drvmgt.dll
    empires2.exe
    miniupnpc.dll
    patch.dll
    wndmode.dll
    EMPIRES2.ICD
    mcp.dll
    Data\gamedata.drs
    age.dll
    on.ini
    )
    Loop, Parse, % List, `n, `r
    {
        If FileExist(GameLocation "\" LTrim(A_LoopField))
        {
            FileDelete, % GameLocation "\" LTrim(A_LoopField)
            If ErrorLevel
                Return False
        }
    }
    Return True
}
EnableDisableControl(vTable, Enable)
{
    For I, Var in vTable
    {
        If (Enable)
            GuiControl, Enable, % Var
        Else
            GuiControl, Disabled, % Var
    }
}
HideDisplayProgress(Name, Opt)
{
    If (Opt)
    {
        GuiControl,, % Name, % 0
        GuiControl, Show, % Name
    }
    Else
        GuiControl, Hide, % Name
}
CheckFolder(Result)
{
    RequiredList := "empires2.exe"
    RequiredList .= ",language.dll"
    RequiredList .= ",Data\gamedata.drs"
    RequiredList .= ",Data\graphics.drs"
    RequiredList .= ",Data\interfac.drs"
    RequiredList .= ",Data\Terrain.drs"
    Loop, Parse, % RequiredList, `,
    {
        If !FileExist(Result "\" A_LoopField)
            Return 0
    }
    Return 1
}
HashFile(sFile="", cSz=2)
{
    cSz := (cSz<0||cSz>8) ? 2**22 : 2**(18+cSz), VarSetCapacity( Buffer,cSz,0 )
    hFil := DllCall( "CreateFile", Str,sFile,UInt,0x80000000, Int,3,Int,0,Int,3,Int,0,Int,0 )
    IfLess,hFil,1, Return,hFil
    hMod := DllCall( "LoadLibrary", Str,"advapi32.dll" )
    DllCall( "GetFileSizeEx", UInt,hFil, UInt,&Buffer ), fSz := NumGet( Buffer,0,"Int64" )
    VarSetCapacity( MD5_CTX,104,0 ), DllCall( "advapi32\MD5Init", UInt,&MD5_CTX )
    Loop % ( fSz//cSz + !!Mod( fSz,cSz ) )
    DllCall( "ReadFile", UInt,hFil, UInt,&Buffer, UInt,cSz, UIntP,bytesRead, UInt,0 )
    , DllCall( "advapi32\MD5Update", UInt,&MD5_CTX, UInt,&Buffer, UInt,bytesRead )
    DllCall( "advapi32\MD5Final", UInt,&MD5_CTX )
    DllCall( "CloseHandle", UInt,hFil )
    Loop % StrLen( Hex:="123456789ABCDEF0" )
        N := NumGet( MD5_CTX,87+A_Index,"Char"), MD5 .= SubStr(Hex,N>>4,1) . SubStr(Hex,N&15,1)
    Return MD5, DllCall( "FreeLibrary", UInt,hMod )
}
MCode(mcode)
{
    Static e := {1:4, 2:1}
    If (A_PtrSize = 8)
        c := "x64"
    Else
        c := "x86"
    if (!regexmatch(mcode, "^([0-9]+),(" c ":|.*?," c ":)([^,]+)", m))
        return
    if (!DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", 0, "uint", e[m1], "ptr", 0, "uint*", s, "ptr", 0, "ptr", 0))
        return
    p := DllCall("GlobalAlloc", "uint", 0, "ptr", s, "ptr")
    if (c="x64")
        DllCall("VirtualProtect", "ptr", p, "ptr", s, "uint", 0x40, "uint*", op)
    if (DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", 0, "uint", e[m1], "ptr", p, "uint*", s, "ptr", 0, "ptr", 0))
        return p
    DllCall("GlobalFree", "ptr", p)
}
UpDateButtonView(Var, Control)
{
    Global
    SoundPlay, % "Bin\Wav\Click.wav"
    If (!Checked[Control])
    {
        ImageButton.Create(Var, Opt1_, Opt2_, Opt3_)
        ModsVar[Control] := 1
        Checked[Control] := 1
    }
    Else
    {
        ImageButton.Create(Var, Opt1, Opt2, Opt3)
        ModsVar[Control] := 0
        Checked[Control] := 0
    }
}
WM_LBUTTONDOWN()
{
    PostMessage 0xA1, 2
}
WM_MouseHover()
{
    MouseGetPos,,, Window
    ToolTip, % Window
}
SelectFolderEx(StartingFolder := "", Prompt := "", OwnerHwnd := 0, OkBtnLabel := "")
{
    Static OsVersion := DllCall("GetVersion", "UChar"), IID_IShellItem := 0, InitIID := VarSetCapacity(IID_IShellItem, 16, 0) & DllCall("Ole32.dll\IIDFromString", "WStr", "{43826d1e-e718-42ee-bc55-a1e261c37bfe}", "Ptr", &IID_IShellItem), Show := A_PtrSize * 3, SetOptions := A_PtrSize * 9, SetFolder := A_PtrSize * 12, SetTitle := A_PtrSize * 17, SetOkButtonLabel := A_PtrSize * 18, GetResult := A_PtrSize * 20
    SelectedFolder := ""
    If (OsVersion < 6)
    {
        FileSelectFolder, SelectedFolder, *%StartingFolder%, 3, %Prompt%
        Return % SelectedFolder
    }
    OwnerHwnd := DllCall("IsWindow", "Ptr", OwnerHwnd, "UInt") ? OwnerHwnd : 0
    If !(FileDialog := ComObjCreate("{DC1C5A9C-E88A-4dde-A5A1-60F82A20AEF7}", "{42f85136-db7e-439c-85f1-e4075d135fc8}"))
        Return ""
    VTBL := NumGet(FileDialog + 0, "UPtr")
    DllCall(NumGet(VTBL + SetOptions, "UPtr"), "Ptr", FileDialog, "UInt", 0x00002028, "UInt")
    If (StartingFolder <> "")
    {
        If !DllCall("Shell32.dll\SHCreateItemFromParsingName", "WStr", StartingFolder, "Ptr", 0, "Ptr", &IID_IShellItem, "PtrP", FolderItem)
            DllCall(NumGet(VTBL + SetFolder, "UPtr"), "Ptr", FileDialog, "Ptr", FolderItem, "UInt")
    }
    If (Prompt <> "")
        DllCall(NumGet(VTBL + SetTitle, "UPtr"), "Ptr", FileDialog, "WStr", Prompt, "UInt")
    If (OkBtnLabel <> "")
        DllCall(NumGet(VTBL + SetOkButtonLabel, "UPtr"), "Ptr", FileDialog, "WStr", OkBtnLabel, "UInt")
    If !DllCall(NumGet(VTBL + Show, "UPtr"), "Ptr", FileDialog, "Ptr", OwnerHwnd, "UInt")
    {
        If !DllCall(NumGet(VTBL + GetResult, "UPtr"), "Ptr", FileDialog, "PtrP", ShellItem, "UInt")
        {
            GetDisplayName := NumGet(NumGet(ShellItem + 0, "UPtr"), A_PtrSize * 5, "UPtr")
            If !DllCall(GetDisplayName, "Ptr", ShellItem, "UInt", 0x80028000, "PtrP", StrPtr)
                SelectedFolder := StrGet(StrPtr, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "Ptr", StrPtr)
            ObjRelease(ShellItem)
        }
    }
    If (FolderItem)
        ObjRelease(FolderItem)
    ObjRelease(FileDialog)
    Return SelectedFolder
}
Control(Arr, Opt)
{
    If (!Opt)
    {
        For Key, Val in Arr
        {
            Lng := (Val = "br") || (Val = "de") || (Val = "es") || (Val = "fr") || (Val = "us")
            Ver := (Val = "20") || (Val = "20a") || (Val = "20b") || (Val = "20c") || (Val = "10") || (Val = "10c") || (Val = "10e")
            If (Val = "Bagf") || (Val = "I") || (Val = "U")
            {
                GuiControl, Main:Show, % Val "D"
                GuiControl, Main:Hide, % Val
                GuiControl, Main:Disabled, % Val
            }
            Else if (Lng) || (Ver)
            {
                GuiControl, MFG:Show, % Val "D"
                GuiControl, MFG:Hide, % Val
                GuiControl, MFG:Disabled, % Val
            }
            Else
            {
                If (!ModsVar[Val])
                    GuiControl, Main:Show, % Val "D"
                Else If (ModsVar[Val])
                    GuiControl, Main:Show, % Val "DC"
                GuiControl, Main:Hide, % Val
                GuiControl, Main:Disabled, % Val
            }
        }
    }
    Else If (Opt)
    {
        For Key, Val in Arr
        {
            Lng := (Val = "br") || (Val = "de") || (Val = "es") || (Val = "fr") || (Val = "us")
            Ver := (Val = "20") || (Val = "20a") || (Val = "20b") || (Val = "20c") || (Val = "10") || (Val = "10c") || (Val = "10e")
            If (Val = "Bagf") || (Val = "I") || (Val = "U")
            {
                GuiControl, Main:Show, % Val
                GuiControl, Main:Enable, % Val
                GuiControl, Main:Hide, % Val "D"
            }
            Else if (Lng) || (Ver)
            {
                GuiControl, MFG:Show, % Val
                GuiControl, MFG:Enable, % Val
                GuiControl, MFG:Hide, % Val "D"
            }
            Else
            {
                GuiControl, Main:Show, % Val
                GuiControl, Main:Enabled, % Val
                If (!ModsVar[Val])
                    GuiControl, Main:Hide, % Val "D"
                Else If (ModsVar[Val])
                    GuiControl, Main:Hide, % Val "DC"
            }
        }
    }
}
CloseCallback(self)
{
    WinKill, % "ahk_id " self.hwnd.Client
    ExitApp
}
TV_SetSelColors(HTV, BkgClr := "", TxtClr := "*Default", Dummy := "")
{
    Static OffCode := A_PtrSize * 2
    , OffStage := A_PtrSize * 3
    , OffItem := (A_PtrSize * 5) + 16
    , OffItemState := OffItem + A_PtrSize
    , OffClrText := (A_PtrSize * 8) + 16
    , OffClrTextBk := OffClrText + 4
    , Controls := {}
    , MsgFunc := Func("TV_SetSelColors")
    , IsActive := False
    Local Item, H, TV, Stage
    If (Dummy = "") {
        If (BkgClr = "") && (TxtClr = "")
            Controls.Delete(HTV)
        Else
        {
            If (BkgClr <> "")
                Controls[HTV, "B"] := ((BkgClr & 0xFF0000) >> 16) | (BkgClr & 0x00FF00) | ((BkgClr & 0x0000FF) << 16)
            Else
                Controls[HTV, "B"] := DllCall("SendMessage", "Ptr", HTV, "UInt", 0x111F, "Ptr", 0, "Ptr", 0, "UInt")
            If (TxtClr <> "")
                Controls[HTV, "T"] := ((TxtClr & 0xFF0000) >> 16) | (TxtClr & 0x00FF00) | ((TxtClr & 0x0000FF) << 16)
            Else
                Controls[HTV, "T"] := DllCall("SendMessage", "Ptr", HTV, "UInt", 0x1120, "Ptr", 0, "Ptr", 0, "UInt")
        }
        If (Controls.MaxIndex() = "")
        {
            If (IsActive) {
                OnMessage(0x004E, MsgFunc, 0)
                IsActive := False
            }
        }
        Else If !(IsActive)
        {
            OnMessage(0x004E, MsgFunc)
            IsActive := True
        }
    }
    Else
    {
        H := NumGet(BkgClr + 0, "UPtr")
        If (TV := Controls[H]) && (NumGet(BkgClr + OffCode, "Int") = -12)
        {
            Stage := NumGet(BkgClr + OffStage, "UInt")
            If (Stage = 0x00010001) {
                If (NumGet(BkgClr + OffItemState, "UInt") & 0x0010)
                {
                    NumPut(NumGet(BkgClr + OffItemState, "UInt") & ~0x0010, BkgClr + OffItemState, "UInt")
                    , NumPut(TV.B, BkgClr + OffClrTextBk, "UInt")
                    , NumPut(TV.T, BkgClr + OffClrText, "UInt")
                    Return 0x00
                }
            }
            Else If (Stage = 0x00000001)
                Return 0x20
            Return 0x00
        }
    }
}
ODLV_MeasureItem(wParam, lParam, Msg, HWND) {
    Static ODT_LISTVIEW := 102
    Static offType := 0, offItemHeight := 16
    Static ItemHeight := 20
    If (NumGet(lParam + 0, offType, "UInt") = ODT_LISTVIEW) {
        NumPut(ItemHeight, lParam + 0, offItemHeight, "UInt")
        Return True
    }
}
ODLV_DrawItem(wParam, lParam, Msg, HWND) {
    Static LVM_GETSUBITEMRECT := 0x1038, LVM_GETCOLUMNWIDTH := 0x101D
    Static offItem := 8, offAction := offItem + 4, offState := offAction + 4, offHWND := offState + A_PtrSize
    , offDC := offHWND + A_PtrSize, offRECT := offDC + A_PtrSize, offData := offRECT + 16
    Static ODT_LISTVIEW := 102
    Static ODA_DRAWENTIRE := 0x0001, ODA_SELECT := 0x0002, ODA_FOCUS := 0x0004
    Static ODS_SELECTED := 0x0001, ODS_FOCUS := 0x0010
    HWND := NumGet(lParam + offHWND, 0, "UPtr")
    If (NumGet(lParam + 0, 0, "UInt") = ODT_LISTVIEW) && OD_ListViews.HasKey(HWND) {
        HGUI := OD_ListViews[HWND]
        Item := NumGet(lParam + offItem, 0, "Int") + 1
        Action := NumGet(lParam + offAction, 0, "UInt")
        State := NumGet(lParam + offState, 0, "UInt")
        HDC := NumGet(lParam + offDC, 0, "UPtr")
        RECT := lParam + offRECT
        Gui, %HGUI%:Default
        Gui, ListView, %HWND%
        If (Action & ODA_DRAWENTIRE) || (Action & ODA_SELECT) {
            BgColor := (State & ODS_SELECTED) ? 0x2D83DC : 0xEDF4FD
            Brush := DllCall("Gdi32.dll\CreateSolidBrush", "UInt", BgColor, "UPtr")
            DllCall("User32.dll\FillRect", "Ptr", HDC, "Ptr", RECT, "Ptr", Brush)
            DllCall("Gdi32.dll\DeleteObject", "Ptr", Brush)
            Loop, % LV_GetCount("Column") {
                LV_GetText(Txt, Item, A_Index), Len := StrLen(Txt)
                VarSetCapacity(RCTX, 16, 0)
                NumPut(2, RCTX, 0, "Int")
                NumPut(A_Index - 1, RCTX, 4, "Int")
                SendMessage, %LVM_GETSUBITEMRECT%, % (Item - 1), % &RCTX, , % "ahk_id " . HWND
                If (A_Index = 1) {
                    SendMessage, %LVM_GETCOLUMNWIDTH%, % (A_Index - 1), 0, , % "ahk_id " . HWND
                    NumPut(NumGet(RCTX, 0, "Int") + ErrorLevel, RCTX, 8, "Int")
                } Else {
                    NumPut(NumGet(RCTX, 0, "Int") + 4, RCTX, 0, "Int")
                }
                DllCall("Gdi32.dll\SetBkMode", "Ptr", HDC, "Int", 1)
                DllCall("User32.dll\DrawText", "Ptr", HDC, "Ptr", &Txt, "Int", Len, "Ptr", &RCTX, "UInt", 0)
            }
            Return True
        }
    }
}
FileSelectSpecific(P_OwnerNum,P_Path,P_SelectFileOrFolder="",P_Prompt="",P_ComplementText="",P_Multi="",P_DefaultView="",P_FilterOK="",P_FilterNO="",P_Restrict=1,P_LVHeight="",P_LVWidth="")
{
    global
    if glb_FSOwnerNum
        try, Gui,%glb_FSOwnerNum%:-Disabled
    try Gui,FileSelectSpecific:Destroy
    Menu, FSContextMenu, Add, SELECT, FSSelect
    Menu, FSContextMenu, Add, Create Folder, FSCreateFolder
    Menu, FSContextMenu, Add, Open Folder in Explorer, FSDisplayFolder
    Menu, FSContextMenu, Default, 1&
    glb_FSTitle=%A_ScriptName% - File Select Dialog
    glb_FSInit:=1
    glb_FSFolder:=P_Path
    glb_FSCurrent:=glb_FSFolder
    glb_FSFilterOK:=P_FilterOK
    glb_FSFilterNO:=P_FilterNO
    glb_FSRestrict:=P_Restrict
    glb_FSType:=P_SelectFileOrFolder
    glb_FSReturn:=""
    glb_FSOwnerNum:=P_OwnerNum
    if (P_SelectFileOrFolder="File" or P_SelectFileOrFolder="All")
        LoopType:="FD"
    else if (P_SelectFileOrFolder="Folder")
        LoopType:="D"
    glb_FSLoopType:=LoopType
    if P_Multi
        glb_FSNoMulti:=""
    else
        glb_FSNoMulti:="-Multi"
    StringRight, LastChar, glb_FSFolder, 1
    if LastChar = \
        StringTrimRight, glb_FSFolder, glb_FSFolder, 1
    glb_FSCurrent:=glb_FSFolder
    Gui, FileSelectSpecific: Default
    Gui, FileSelectSpecific: New
    Gui, +HwndFSHwnd
    Gui, +Resize +MinSize300x300 -Caption
    Background := 0x6C1611
    Text := 0xFFFFFF
    Stand := [1, Background, Background, Text]
    Hover := {2: Text, 3: Text, 4: Background}
    Click := {4: "Yellow"}
    if (glb_FSOwnerNum) {
        Gui +Owner%glb_FSOwnerNum%
        Gui, %glb_FSOwnerNum%:+Disabled
    }
    Gui, +OwnDialogs
    Gui, Color, 0xB88850
    Gui, Font, s9 Bold, Calibri
    Gui, Add, Button, xm w20 gFSSwitchView h25 hwndL, % Chr(0x02630)
    ImageButton.Create(L, Stand, Hover, Click)
    Gui, Font, Bold
    Gui, Add, Button, x+5 yp gFSRefresh h25 hwndR, % Chr(0x21BB)
    ImageButton.Create(R, Stand, Hover, Click)
    Gui, Add, Button, x+5 w30 gFSPrevious h25 hwndB, % Chr(0x2190)
    ImageButton.Create(B, Stand, Hover, Click)
    Gui, Font, s10
    Gui, Add, Button, x+5 yp gFSSelect h25 hwndS, % "SELECT"
    ImageButton.Create(S, Stand, Hover, Click)
    Gui, Add, Button, x+110 w30 h25 hwndE, X
    ImageButton.Create(E, Stand, Hover, Click)
    Gui, Add, Edit, xm y+8 w%P_LVWidth% vFSNavBarv, % glb_FSCurrent
    Gui, Add, Text, xm y+8 w%P_LVWidth% vFSPromptv, % P_Prompt
    ListViewPos:= " w" P_LVWidth
    ListViewPos.= " h" P_LVHeight
    Gui, Add, ListView, xm y+10 %ListViewPos% vFSListView gFSListViewHandler %glb_FSNoMulti%, Name|Located In
    if (P_DefaultView="Icon") {
        GuiControl, +Icon, FSListView
        Glb_FSIconView:=1
    } else {
        GuiControl, +Report, FSListView
        Glb_FSIconView:=0
    }
    Gui, Font, s10
    if P_ComplementText
        Gui, Add, Text, xm y+8 w%P_LVWidth% vFSComplementv, % P_ComplementText
    Gui, Font, Italic s9
    if !glb_FSNoMulti
        Gui, Add, Text, xm y+5 w%P_LVWidth% vFSMultiIndicv, % "Hold Ctrl or Shift for Multi-Selection"
    Gui, Font
    FSIconArray:={}
    FSImageListID1 := IL_Create(10)
    FSImageListID2 := IL_Create(10, 10, true)
    LV_SetImageList(FSImageListID1)
    LV_SetImageList(FSImageListID2)
    GuiControl, -Redraw, FSListView
    FSAddLoopFiles()
    FSRedrawCol()
    GuiControl, +Redraw, FSListView
    Dockit(Main, FSHwnd, "L", "Main_FSHwnd")
    glb_FSInit:=0
    return FSHwnd
}
FileSelectSpecificAdjust(P_Path="") {
    global
    if !P_Path
        P_Path:=glb_FSCurrent
    Gui FileSelectSpecific: Default
    GuiControl, -Redraw, FSListView
    LV_Delete()
    FSAddLoopFiles()
    GuiControl,,FSNavBarv, % glb_FSCurrent
    FSRedrawCol()
    GuiControl, +Redraw, FSListView
}
FSAddLoopFiles()
{
    global
    Gui FileSelectSpecific: Default
    FSsfi_size := A_PtrSize + 8 + (A_IsUnicode ? 680 : 340)
    VarSetCapacity(FSsfi, FSsfi_size,0)
    if !glb_FSCurrent {
        DriveGet, FSDriveList, list
        FSDriveLabels:={}
        Loop, parse, FSDriveList
        {
            DriveGet, FSDriveLabel, Label, % A_Loopfield ":"
            FSDriveLabels[A_Index]:=FSDriveLabel
            IconNumber:=FSSetIcon(A_Loopfield ":","",FSIconArray,FSImageListID1,FSImageListID2)
            LV_Add("Icon" . IconNumber, A_Loopfield ": " FSDriveLabels[A_Index], "", "", "")
        }
        return
    }
    Loop, Files, %glb_FSCurrent%\*, %glb_FSLoopType%
    {
        if A_LoopFileAttrib contains H,S
            continue
        If glb_FSfilterOK
            If A_LoopFileExt not in ,%glb_FSfilterOK%
            continue
        If glb_FSFilterNO
            If A_LoopFileExt in %glb_FSFilterNO%
            continue
        IconNumber:=FSSetIcon(A_LoopFileFullPath,A_LoopFileExt,FSIconArray,FSImageListID1,FSImageListID2)
        LV_Add("Icon" . IconNumber, A_LoopFileName, A_LoopFileDir, A_LoopFileSizeKB, A_LoopFileExt)
    }
}
FSSetIcon(P_Filepath,P_FileExt,ByRef P_IconArray,ByRef P_Imagelist1,ByRef P_ImageList2) {
    global
    if P_FileExt in EXE,ICO,ANI,CUR
    {
        ExtID := P_FileExt
        IconNumber = 0
    }
    else
    {
        if !P_FileExt
        {
            if Regexmatch(P_Filepath, ":$")
                P_FileExt:="DRIVE"
            else if InStr(FileExist(P_Filepath), "D")
                P_FileExt:="DIR"
            else if FileExist(P_Filepath)
                P_FileExt:="NOEXT"
        }
        ExtID = 0
        Loop 7
        {
            StringMid, ExtChar, P_FileExt, A_Index, 1
            if not ExtChar
                break
            ExtID := ExtID | (Asc(ExtChar) << (8 * (A_Index - 1)))
        }
        IconNumber := P_IconArray[ExtID]
    }
    if not IconNumber
    {
        if not DllCall("Shell32\SHGetFileInfo" . (A_IsUnicode ? "W":"A"), "str", P_Filepath, "uint", 0, "ptr", &FSsfi, "uint", FSsfi_size, "uint", 0x101)
            IconNumber = 9999999
        else
        {
            hIcon := NumGet(FSsfi, 0)
            IconNumber := DllCall("ImageList_ReplaceIcon", "ptr", P_Imagelist1, "int", -1, "ptr", hIcon) + 1
            DllCall("ImageList_ReplaceIcon", "ptr", P_ImageList2, "int", -1, "ptr", hIcon)
            DllCall("DestroyIcon", "ptr", hIcon)
            P_IconArray[ExtID] := IconNumber
        }
    }
    return IconNumber
}
class Dock
{
    static EVENT_OBJECT_LOCATIONCHANGE := 0x800B
    , EVENT_OBJECT_FOCUS := 0x8005, EVENT_OBJECT_DESTROY := 0x8001
    , EVENT_MIN := 0x00000001, EVENT_MAX := 0x7FFFFFFF
    , EVENT_SYSTEM_FOREGROUND := 0x0003
    __New(Host, Client, Callback := "", CloseCallback := "")
    {
        this.hwnd := []
        this.hwnd.Host := Host
        this.hwnd.Client := Client
        WinSet, ExStyle, +0x80, % "ahk_id " this.hwnd.Client
        this.Bound := []
        this.Callback := IsObject(Callback) ? Callback : ObjBindMethod(Dock.EventsHandler, "Calls")
        this.CloseCallback := IsFunc(CloseCallback) || IsObject(CloseCallback) ? CloseCallback
        this.hookProcAdr := RegisterCallback("_DockHookProcAdr",,, &this)
        idProcess := 0
        idThread := 0
        DllCall("CoInitialize", "Int", 0)
        this.Hook := DllCall("SetWinEventHook"
        , "UInt", Dock.EVENT_SYSTEM_FOREGROUND
        , "UInt", Dock.EVENT_OBJECT_LOCATIONCHANGE
        , "Ptr", 0
        , "Ptr", this.hookProcAdr
        , "UInt", idProcess
        , "UInt", idThread
        , "UInt", 0)
    }
    Unhook()
    {
        DllCall("UnhookWinEvent", "Ptr", this.Hook)
        DllCall("CoUninitialize")
        DllCall("GlobalFree", "Ptr", this.hookProcAdr)
        this.Hook := ""
        this.hookProcAdr := ""
        this.Callback := ""
        WinSet, ExStyle, -0x80, % "ahk_id " this.hwnd.Client
    }
    __Delete()
    {
        this.Delete("Bound")
        If (this.Hook)
            this.Unhook()
        this.CloseCallback := ""
    }
    Add(hwnd, pos := "")
    {
        static last_hwnd := 0
        this.Bound.Push( new this( !NumGet(&this.Bound, 4*A_PtrSize) ? this.hwnd.Client : last_hwnd, hwnd ) )
        If pos Contains Top,Bottom,R,Right,L,Left,Custom
            this.Bound[NumGet(&this.Bound, 4*A_PtrSize)].Position(pos)
        last_hwnd := hwnd
    }
    Position(pos)
    {
        this.pos := pos
        Return this.EventsHandler.EVENT_OBJECT_LOCATIONCHANGE(this, "host")
    }
    class EventsHandler extends Dock.HelperFunc
    {
        Calls(self, hWinEventHook, event, hwnd)
        {
            Critical
            If (hwnd = self.hwnd.Host)
            {
                Return this.Host(self, event)
            }
            If (hwnd = self.hwnd.Client)
            {
                Return this.Client(self, event)
            }
        }
        Host(self, event)
        {
            If (event = Dock.EVENT_SYSTEM_FOREGROUND)
            {
                Return this.EVENT_SYSTEM_FOREGROUND(self.hwnd.Client)
            }
            If (event = Dock.EVENT_OBJECT_LOCATIONCHANGE)
            {
                Return this.EVENT_OBJECT_LOCATIONCHANGE(self, "host")
            }
            If (event = Dock.EVENT_OBJECT_DESTROY)
            {
                self.Unhook()
                If (IsFunc(self.CloseCallback) || IsObject(self.CloseCallback))
                    Return self.CloseCallback()
            }
        }
        Client(self, event)
        {
            If (event = Dock.EVENT_SYSTEM_FOREGROUND)
            {
                Return this.EVENT_SYSTEM_FOREGROUND(self.hwnd.Host)
            }
            If (event = Dock.EVENT_OBJECT_LOCATIONCHANGE)
            {
                Return this.EVENT_OBJECT_LOCATIONCHANGE(self, "client")
            }
        }
        EVENT_SYSTEM_FOREGROUND(hwnd)
        {
            Return this.WinSetTop(hwnd)
        }
        EVENT_OBJECT_LOCATIONCHANGE(self, via)
        {
            Host := this.WinGetPos(self.hwnd.Host)
            Client := this.WinGetPos(self.hwnd.Client)
            If InStr(self.pos, "Top")
            {
                If (via = "host")
                {
                    If (Host.x = "") || (Client.x = "")
                        Return
                    Return this.MoveWindow(self.hwnd.Client
                    , Host.x
                    , Host.y - Client.h
                    , Client.w
                    , Client.h)
                }
                If (via = "client")
                {
                    If (Host.x = "") || (Client.x = "")
                        Return
                    Return this.MoveWindow(self.hwnd.Host
                    , Client.x
                    , Client.y + Client.h
                    , Host.w
                    , Host.h)
                }
            }
            If InStr(self.pos, "Bottom")
            {
                If (via = "host")
                {
                    If (Host.x = "") || (Client.x = "")
                        Return
                    Return this.MoveWindow(self.hwnd.Client
                    , Host.x
                    , Host.y + Host.h
                    , Client.w
                    , Client.h)
                }
                If (via = "client")
                {
                    If (Host.x = "") || (Client.x = "")
                        Return
                    Return this.MoveWindow(self.hwnd.Host
                    , Client.x
                    , Client.y - Host.h
                    , Host.w
                    , Host.h)
                }
            }
            If InStr(self.pos, "R")
            {
                If (via = "host")
                {
                    If (Host.x = "") || (Client.x = "")
                        Return
                    Return this.MoveWindow(self.hwnd.Client
                    , Host.x + Host.w
                    , Host.y
                    , Client.w
                    , Client.h)
                }
                If (via = "client")
                {
                    If (Host.x = "") || (Client.x = "")
                        Return
                    Return this.MoveWindow(self.hwnd.Host
                    , Client.x - Host.w
                    , Client.y
                    , Host.w
                    , Host.h)
                }
            }
            If InStr(self.pos, "L")
            {
                If (via = "host")
                {
                    If (Host.x = "") || (Client.x = "")
                        Return
                    Return this.MoveWindow(self.hwnd.Client
                    , Host.x - Client.w
                    , Host.y
                    , Client.w
                    , Client.h)
                }
                If (via = "client")
                {
                    If (Host.x = "") || (Client.x = "")
                        Return
                    Return this.MoveWindow(self.hwnd.Host
                    , Client.x + Client.w
                    , Client.y
                    , Host.w
                    , Host.h)
                }
            }
            If InStr(self.pos, "Custom")
            {
                If (via = "host")
                {
                    If (Host.x = "") || (Client.x = "")
                        Return
                    Return this.MoveWindow(self.hwnd.Client
                    , Host.x
                    , Host.y
                    , Client.w
                    , Client.h)
                }
                If (via = "client")
                {
                    If (Host.x = "") || (Client.x = "")
                        Return
                    Return this.MoveWindow(self.hwnd.Host
                    , Client.x
                    , Client.y
                    , Host.w
                    , Host.h)
                }
            }
        }
    }
    class HelperFunc
    {
        WinGetPos(hwnd)
        {
            WinGetPos, hX, hY, hW, hH, % "ahk_id " . hwnd
            Return {x: hX, y: hY, w: hW, h: hH}
        }
        MoveWindow(hwnd, x, y, w, h)
        {
            Return DllCall("MoveWindow", "Ptr", hwnd, "Int", x, "Int", y, "Int", w, "Int", h, "Int", 1)
        }
        Run(Target)
        {
            Try Run, % Target,,, OutputVarPID
            Catch,
                Throw, "Couldn't run " Target
            WinWait, % "ahk_pid " OutputVarPID
            Return WinExist("ahk_pid " OutputVarPID)
        }
    }
}
_DockHookProcAdr(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime)
{
    this := Object(A_EventInfo)
    this.Callback.Call(this, hWinEventHook, event, hwnd)
}
MessageBox(Stat, Title, Body, Buttons)
{
    Global
    If WinExist("ahk_id " MB)
        Gui, MB:Destroy
    MBReturn := ""
    Switch Stat
    {
    Case 0:
        SoundPlay, *16
    Case 1:
        SoundPlay, *64
    }
    Gui, MB:-SysMenu -Caption +HwndMB
    Gui, MB:Color, 0xE4B479
    Gui, MB:Font, s14 Bold, Consolas
    Gui, MB:Add, Text, xm ym w275 +Center, % Title
    Gui, MB:Font, s10
    Gui, MB:Add, Edit, xm ym+25 w275 r3 +ReadOnly -VScroll +Center, % Body
    CD := 10
    Gui, MB:Add, Text, xm ym+90 w100 vCountDown, % "Closing in `n" CD " seconds..."
    Y := 90, NextX := 220
    Loop, Parse, Buttons, `,
    {
        Gui, MB:Add, Button, xm+%NextX% ym+%Y% w50 HwndBtn gReturnClick v%A_LoopField%, % A_LoopField
        ImageButton.Create(Btn , {2: 0xB88851, 3: 0xB88851, 4: "Black"}
        , {2: "Black", 3: "Black", 4: 0xFFFFFF}
        , {2: 0xB88851, 3: 0xB88851, 4: 0xFF0000})
        NextX -= 52
    }
    Dockit(Main, MB, "Top", "Main_MB")
    SetTimer, CountDown, 1000
    Return % MB
    ReturnClick:
    MBGUIClose:
        MBReturn := A_GuiControl
        Gui, MB:Destroy
    Return % MBReturn
}
MoreFeatures(Display)
{
    Global
    If (Checked[Display])
    {
        If !WinExist("ahk_id " MFG) && !(MFG)
        {
            Gui, MFG: +HwndMFG -Caption
            Gui, MFG: Color, 0x6C1611
            Gui, MFG: Font, Bold s12, Calibri
            Gui, MFG: Add, Picture, x5 y5, Bin\PNG\Main.png
            Gui, MFG: Add, Text, xm ym+10 w280 +Center +BackgroundTrans, Change to another language!
            Y := 40
            Loop, Files, Lng\*, D
            {
                IniRead, Lng, Lng\Def.ini, Def, %A_LoopFileName%
                Gui, MFG: Add, Picture, xm ym+%Y% w280 v%A_LoopFileName%D +Hidden, Bin\PNG\%A_LoopFileName%_Disabled.png
                Gui, MFG: Add, Button, xm ym+%Y% w280 h30 v%A_LoopFileName% HwndBtn gApplyLanguage, % Lng
                Opt1__ := [0,"Bin\PNG\Lng.png"]
                Opt2__ := {2:"Bin\PNG\Lng_Hover.png"}
                Opt3__ := {2:"Bin\PNG\Lng_Clicked.png"}
                ImageButton.Create(Btn, Opt1__, Opt2__, Opt3__)
                Y += 32
            }
            Gui, MFG: Add, Text, w280 +Center +BackgroundTrans, Change to another version!
            Y += 32
            Y_ := Y
            Gui, MFG: Add, Picture, xm ym+%Y% +BackgroundTrans, Bin\PNG\AOC.png
            Y += 55
            X := 22
            Gui, Main:Submit, NoHide
            GetGameVersion(GameLocation, "AOK", "AOC")
            IniRead, AoKVer, % D "\AoEII_Location.ini", AoEII_Location, AoKVer
            IniRead, AoCVer, % D "\AoEII_Location.ini", AoEII_Location, AoCVer
            Opt1__ := [0,"Bin\PNG\_.png"]
            Opt2__ := {2:"Bin\PNG\__Hover.png"}
            Opt3__ := {2:"Bin\PNG\__Clicked.png"}
            Loop, Files, Versions\*, D
            {
                If (A_LoopFileName ~= "\d.\d[A-Za-z]?")
                {
                    VerName := StrReplace(A_LoopFileName, ".", "")
                    if (VerName = "20")
                    {
                        Gui, MFG: Add, Button, xm+%X% ym+%Y% w96 h30 v15 HwndBtn gOpenUserPatch, 1.5
                        ImageButton.Create(Btn, Opt1__, Opt2__, Opt3__)
                        Y := Y_
                        X += 118
                        Gui, MFG: Add, Picture, xm+%X% ym+%Y% +BackgroundTrans, Bin\PNG\AOK.png
                        X += 22
                        Y += 55
                    }
                    Gui, MFG: Add, Picture, xm+%X% ym+%Y% w96 v%VerName%D +Hidden, Bin\PNG\%A_LoopFileName%__Disabled.png
                    Gui, MFG: Add, Button, xm+%X% ym+%Y% w96 h30 v%VerName% HwndBtn gApplyVersion, % A_LoopFileName
                    ImageButton.Create(Btn, Opt1__, Opt2__, Opt3__)
                    If (A_LoopFileName = AoKVer) || (A_LoopFileName = AoCVer)
                        Control([VerName], 0)
                    Y += 32
                }
            }
        }
        Else
            UpdateVersions()
        WinGetPos, X, Y, Width,, ahk_id %Main%
        X += Width
        Gui, MFG: Show, x%X% y%Y% w310 h570 Hide
        DllCall("AnimateWindow", "UInt", MFG, "Int", 500, "UInt", "0x1")
        Dockit(Main, MFG, "R", "Main_MFG")
        Checked[Display] := 1
    }
    Else
    {
        If WinExist("ahk_id " MFG)
            DllCall("AnimateWindow", "UInt", MFG, "Int", 500, "UInt", "0x90000")
        Checked[Display] := 0
    }
}
Dockit(Host, Client, Pos, DockName)
{
    Global
    Gui, %Host%:Show
    Gui, %Client%:Show
    %DockName% := new Dock(Host, Client)
    %DockName%.Position(Pos)
    %DockName%.CloseCallback := Func("CloseCallback")
}
UpdateVersions()
{
    Global
    Gui, Main:Submit, NoHide
    GetGameVersion(GameLocation, "AOK", "AOC")
    IniRead, AoKVer, % D "\AoEII_Location.ini", AoEII_Location, AoKVer
    IniRead, AoCVer, % D "\AoEII_Location.ini", AoEII_Location, AoCVer
    Loop, Files, Versions\*, D
    {
        If (A_LoopFileName ~= "\d.\d[A-Za-z]?")
        {
            VerName := StrReplace(A_LoopFileName, ".", "")
            If (A_LoopFileName = AoKVer) || (A_LoopFileName = AoCVer)
                Control([VerName], 0)
            Else
                Control([VerName], 1)
        }
    }
}
MineGameFolder()
{
    If !CheckGameRanger()
    Return % ""
WinActivate, % "ahk_exe GameRanger.exe"
WinWaitActive, % "ahk_exe GameRanger.exe"
Send, ^e
WinWaitActive, % "Option"
WinGetActiveTitle, Title
WinGetPos, X, Y, Width,, %Title%
If (Width != 472) && (Title != "Options")
{
    RunWait, % A_AppData "\GameRanger\GameRanger\GameRanger.exe"
    If (ErrorLevel != 0)
    Return % ""
WinWaitActive, % "ahk_exe GameRanger.exe"
Send, ^e
WinWaitActive, % "Option"
WinGetActiveTitle, Title
WinGetPos, X, Y, Width,, %Title%
If (Width != 472) && (Title != "Options")
    Return % ""
}
SendMessage, 0x1330, 0,, SysTabControl321, %Title%
ControlClick, SysListView321, %Title%
ControlSend, SysListView321, {Home}, %Title%
Loop 12
    ControlSend, SysListView321, {Down}, %Title%
Sleep, 1000
ExePath := ""
ControlGetText, ExePath, Edit1, %Title%
If (ExePath = "") || (ExePath = "Not Found")
{
    Loop
    {
        Exit := False
        MsgBox, 52, Try Again?, That Looks Too Fast Try Slower? (%A_Index% Second Delay)
        IfMsgBox, Yes
        {
            WinActivate, % "ahk_exe GameRanger.exe"
            WinWaitActive, % "ahk_exe GameRanger.exe"
            Send, ^e
            WinWaitActive, % "Option"
            WinGetActiveTitle, Title
            WinGetPos, X, Y, Width,, %Title%
            If (Width != 472) && (Title != "Options")
                Return % ""
            SendMessage, 0x1330, 0,, SysTabControl321, %Title%
            ControlClick, SysListView321, %Title%
            ControlSend, SysListView321, {Home}, %Title%
            Loop 10
                ControlSend, SysListView321, {Down}, %Title%
            Sleep, %A_Index%000
            ExePath := ""
            ControlGetText, ExePath, Edit1, %Title%
        }
        IfMsgBox, No
        Exit := True
    }
    Until (Exit) || ((ExePath != "") && (ExePath != "Not Found"))
}
If (Exit)
    Return % ""
WinClose, %Title%
SplitPath, % ExePath, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
Return % OutDir
}
CheckGameRanger()
{
    Process, Exist, GameRanger.exe
    If (ErrorLevel = 0)
    Return 0
Else
    Return 1
}
SetSystemCursor(File)
{
    CursorHandle := DllCall("LoadCursorFromFile", Str, File)
    Cursors = 32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,32651
    Loop, Parse, Cursors, `,
        DllCall("SetSystemCursor", Uint, CursorHandle, Int, A_Loopfield)
}
RestoreCursors()
{
    SPI_SETCURSORS := 0x57
    DllCall("SystemParametersInfo", UInt, 0x57, UInt, 0, UInt, 0, UInt, 0)
}
Global ModsVar := {}, OD_ListViews := {}, Checked := {}
Set := False
Background := 0x6C1611
Text := 0xFFFFFF
Stand := [1, Background, Background, Text]
Hover := {2: Text, 3: Text, 4: Background}
Click := {4: "Yellow"}
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance, Force
Gui, Main: -Caption +HwndMain
Gui, Main:Add, Picture, x5 y5, Bin\PNG\Main.png
Gui, Main:Font, s10 Bold, Calibri
Gui, Main:Color, 0x6C1611
Gui, Main:Add, Text, xm ym+7 BackgroundTrans, AoE II Mods Pack Launcher
Gui, Main:Add, Button, x250 y7 w50 h18 hwndE, X
ImageButton.Create(E, Stand, Hover, Click)
Background := 0x111111
Text := 0xFFFFFF
Stand := [1, Background, Background, Text]
Hover := {2: Text, 3: Text, 4: Background}
Click := {4: "Yellow"}
Gui, Main:Font, s12
Gui, Main:Add, Button, xm y30 w290 h28 hwndBagf vBagf, Browse AoE II Folder
Gui, Main:Add, Picture, xm y30 vBagfD Hidden, Bin\PNG\B_Disabled.png
Opt1 := [0,"Bin\PNG\Bagf.png"]
Opt2 := {2:"Bin\PNG\Bagf_Hover.png"}
Opt3 := {2:"Bin\PNG\Bagf_Clicked.png"}
ImageButton.Create(Bagf, Opt1, Opt2, Opt3)
Gui, Main:Add, Button, xm+2 ym+58 vGR hwndGR gSubmitGR vSubmitGR w12 h14
ImageButton.Create(GR, [0,"Bin\PNG\CB_UnChecked.png"], {2:"Bin\PNG\CB_UnChecked_Hover.png"})
ModsVar["SubmitGR"] := 0, Checked["SubmitGR"] := 0
Gui, Main:Font, s10
Gui, Main:Add, Text, xm+20 ym+57 +BackgroundTrans cBlue gSubmitGR, Collect the game location from GameRanger
Gui, Main:Font, s12
Gui, Main:Add, Button, xm y490 w145 h28 hwndI vI, Install
Gui, Main:Add, Button, xm+145 y490 w145 h28 hwndU vU, Uninstall
Gui, Main:Add, Picture, xm y490 w145 vID Hidden, Bin\PNG\I_Disabled.png
Gui, Main:Add, Picture, xm+145 y490 w145 vUD Hidden, Bin\PNG\U_Disabled.png
Opt1_ := [0,"Bin\PNG\IU.png"]
Opt2_ := {2:"Bin\PNG\IU_Hover.png"}
Opt3_ := {2:"Bin\PNG\IU_Clicked.png"}
ImageButton.Create(I, Opt1_, Opt2_, Opt3_)
ImageButton.Create(U, Opt1_, Opt2_, Opt3_)
Gui, Main:Font, s10
Gui, Main:Add, Edit, xm y85 w290 h18 ReadOnly -HScroll +Center hwndGameLocation vGameLocation BackgroundTrans -e0x200
CtlColors.Attach(GameLocation, "B88851", "000000")
Gui, Main:Font, s13
startY := 108
Opt1 := [0,"Bin\PNG\UnChecked.png"]
Opt2 := {2:"Bin\PNG\UnChecked_Hover.png"}
Opt3 := {2:"Bin\PNG\UnChecked_Clicked.png"}
Opt1_ := [0,"Bin\PNG\Checked.png"]
Opt2_ := {2:"Bin\PNG\Checked_Hover.png"}
Opt3_ := {2:"Bin\PNG\Checked_Clicked.png"}
List := {"1Blue Berries":"bb","2Enchanced Blood":"eb","3HD Burnining Fire":"hbf","4Light Grid Lines":"lgt","5No Snow":"ns","6Short Wall":"sw","7Small Tree":"st","8Widescreen (TAOK)":"WTAOK","9Widescreen (TC)":"WTC","ARecords Bugs Fix":"RB","BDelayed Start Fix":"DS","CMore Features":"MF"}
For ModName, Abriviation in List
{
    ModsVar[Abriviation] := 0, Checked[Abriviation] := 0
    Gui, Main:Add, Button, xm ym+%startY% v%Abriviation% hwnd%Abriviation% gSubmit w24 h28
    Gui, Main:Add, Picture, xm ym+%startY% v%Abriviation%D Hidden, Bin\PNG\Disabled.png
    Gui, Main:Add, Picture, xm ym+%startY% v%Abriviation%DC Hidden, Bin\PNG\Disabled_Checked.png
    startY += 2
    Gui, Main:Add, Text, xm+30 ym+%startY% BackgroundTrans v%Abriviation%T, % SubStr(ModName, 2)
    startY -= 2
    ImageButton.Create(%Abriviation%, Opt1, Opt2, Opt3)
    If (Abriviation = "RB")
    {
        Gui, Main:Font, s12
        Gui, Main:Add, Pic, xm+194 ym+%startY% v%Abriviation%S, Bin\PNG\_.png
        startY += 3
        Gui, Main:Add, Text, xm+194 ym+%startY% w94 h28 +Center BackgroundTrans vRBL, N/A
        startY -= 3
        Gui, Main:Font, s13
    }
    Else If (Abriviation != "MF")
    {
        Gui, Main:Add, Pic, xm+194 ym+%startY% v%Abriviation%S, Bin\PNG\NA.png
        Gui, Main:Add, Pic, xm+194 ym+%startY% v%Abriviation%SI Hidden, Bin\PNG\Installed.png
        Gui, Main:Add, Pic, xm+194 ym+%startY% v%Abriviation%SU Hidden, Bin\PNG\Uninstalled.png
    }
    If (Abriviation = "st")
        startY += 25
    If (Abriviation = "DS")
        startY += 50
    startY += 30
}
Gui, Main:Font, s10
Gui, Main:Add, Edit, xm ym+320 w290 h18 hwndLog vLog +Center BackgroundTrans ReadOnly -e0x200, [---]
CtlColors.Attach(Log, "B88851", "000000")
Gui, Main:Add, Progress, xm+1 ym+465 w287 h16 vWP -Smooth Hidden
Gui, Main:Add, Picture, xm+260 ym+522 +BackgroundTrans gToggleSound vSoundStat, Bin\PNG\SoundOn.png
Sound := True
Gui, Main:Show, w310 h570, AoE II Mods Pack Launcher
OnMessage(0x201, "WM_LBUTTONDOWN")
Control(["bb", "eb", "hbf", "lgt", "ns", "st", "sw", "WTAoK", "WTC", "RB", "MF"], 0)
DriveGet, List, List
Global D
D := SubStr(List, 1, 1) ":"
If FileExist(D "\AoEII_Location.ini")
{
    IniRead, Result, % D "\AoEII_Location.ini", AoEII_Location, Dir
    If (Result != "ERROR")
    {
        If (CheckFolder(Result))
        {
            IniRead, Lst_RBFResult, % D "\AoEII_Location.ini", AoEII_Location, Lst_RBF
            If (Lst_RBFResult != "ERROR") && If (Lst_RBFResult != "")
            {
                If (StrSplit(Lst_RBFResult, "|")[2] = Result)
                    GuiControl, Main:, RBL, % StrSplit(Lst_RBFResult, "|")[1]
                Else
                    GuiControl, Main:, RBL, N/A
            }
            Else
                GuiControl, Main:, RBL, N/A
            GuiControl, Main:, GameLocation, % Result
            Control(["bb", "eb", "hbf", "lgt", "st", "sw", "WTAoK", "RB", "MF"], 1)
            GetGameVersion(Result, "AOK", "")
            IniRead, AoKVer, % D "\AoEII_Location.ini", AoEII_Location, AoKVer
            UpdateVersionView(Result, AoKVer, "")
            If VerifAoCInstall(Result)
            {
                Control(["ns", "WTC"], 1)
                GetGameVersion(Result, "", "AOC")
                IniRead, AoCVer, % D "\AoEII_Location.ini", AoEII_Location, AoCVer
                UpdateVersionView(Result, "", AoCVer)
            }
            UpdateModView(Result, "")
        }
    }
}
If InStr(FileExist(A_WinDir "\SysWow64"), "D")
    WD := "SysWow64"
Else If InStr(FileExist(A_WinDir "\SysWow32"), "D")
    WD := "System32"
If !FileExist(A_WinDir "\" WD "\gameux.dll")
{
    GuiControl, Main:Hide, DSS
    GuiControl, Main:Hide, DSSU
    GuiControl, Main:Show, DSSI
}
Else
{
    GuiControl, Main:Hide, DSS
    GuiControl, Main:Hide, DSSI
    GuiControl, Main:Show, DSSU
}
if A_OSVersion Not In WIN_VISTA,WIN_7
{
    Control(["DS"], 0)
    GuiControl, Main:Hide, DSS
    GuiControl, Main:Hide, DSSU
    GuiControl, Main:Show, DSSI
}
Gui, Main: Add, ActiveX, vAV, WMPLayer.OCX
AV.Settings.setMode("loop" ,true)
AV.Url := "Bin\Wav\Background.mp3"
SetTimer, Update, 250
Return
Update:
    Process, Exist, Voobly.exe
    Voobly := ErrorLevel
    Process, Exist, age2_x1.exe
    age2_x1 := ErrorLevel
    If (Voobly) && (age2_x1)
        ExitApp
    MouseGetPos,,, Window, Control
    If (Window = Main) || (Window = MFG) || (Window = MB) || (Window = FSHwnd)
    {
        If (!CurSet)
        {
            SetSystemCursor("Bin\Cur\Cursor.cur")
            CurSet := True
        }
        Else
        {
            If InStr(Control, "Button") || (Control = "Static4")
            {
                If (!BtnCurSet)
                {
                    SetSystemCursor("Bin\Cur\Hand.cur")
                    BtnCurSet := True
                }
            }
            Else
            {
                If (BtnCurSet)
                {
                    SetSystemCursor("Bin\Cur\Cursor.cur")
                    BtnCurSet := False
                }
            }
        }
    }
    Else If (CurSet) || (BtnCurSet)
    {
        RestoreCursors()
        CurSet := False
    }
Return
Submit:
    GuiControlGet, HwndControl, Hwnd, % A_GuiControl
    UpDateButtonView(HwndControl, A_GuiControl)
    If (A_GuiControl = "MF") || (A_GuiControl = "MF_")
        MoreFeatures(A_GuiControl)
Return
MainButtonInstall:
    SoundPlay, % "Bin\Wav\Click.wav"
    Gui, Main:Submit, NoHide
    GuiControl, Main:Show, WP
    If (GameLocation != "")
        Control(["Bagf", "I", "U", "bb", "eb", "hbf", "lgt", "ns", "st", "sw", "WTAoK", "WTC", "RB", "DS", "MF"], 0)
    Adv := 100 / 13
    For Key, Val in ModsVar
    {
        GuiControl, Main:, WP, +%Adv%
        GuiControlGet, Text,, %Key%T
        GuiControl, Main:, Log, [Working on %Text%...]
        If (Val = 1)
        {
            If InStr(FileExist("Mods\" Key), "D")
            {
                Backup(GameLocation, Key)
                InstallMod(GameLocation, Key)
                UpdateModView(GameLocation, Key)
            }
            Else If (Key = "WTAoK")
                InstallWSAoK(GameLocation)
            Else If (Key = "WTC")
                InstallWSTC(GameLocation)
            Else If (Key = "RB")
                FixRecords(GameLocation)
            Else If (Key = "DS")
                FixDelayedStart()
        }
    }
    GuiControl, Main:, WP, 0
    GuiControl, Main:Hide, WP
    GuiControl, Main:, Log, [---]
    If (GameLocation != "")
        Control(["Bagf", "I", "U", "bb", "eb", "hbf", "lgt", "ns", "st", "sw", "WTAoK", "WTC", "RB", "DS", "MF"], 1)
Return
MainButtonUninstall:
    SoundPlay, % "Bin\Wav\Click.wav"
    Gui, Main:Submit, NoHide
    GuiControl, Main:Show, WP
    If (GameLocation != "")
        Control(["Bagf", "I", "U", "bb", "eb", "hbf", "lgt", "ns", "st", "sw", "WTAoK", "WTC", "RB", "DS", "MF"], 0)
    Adv := 100 / 13
    For Key, Val in ModsVar
    {
        GuiControl, Main:, WP, +%Adv%
        GuiControlGet, Text,, %Key%T
        GuiControl, Main:, Log, [Working on %Text%...]
        If (Val = 1)
        {
            If InStr(FileExist("Mods\" Key), "D")
            {
                UninstallMod(GameLocation, Key)
                UpdateModView(GameLocation, Key)
            }
            Else If (Key = "WTAoK")
                UninstallWSAoK(GameLocation)
            Else If (Key = "WTC")
                UninstallWSTC(GameLocation)
            Else If (Key = "DS")
                UnFixDelayedStart()
        }
    }
    GuiControl, Main:, WP, 0
    GuiControl, Main:Hide, WP
    GuiControl, Main:, Log, [---]
    If (GameLocation != "")
        Control(["Bagf", "I", "U", "bb", "eb", "hbf", "lgt", "ns", "st", "sw", "WTAoK", "WTC", "RB", "DS", "MF"], 1)
Return
MainButtonBrowseAoEIIFolder:
    SoundPlay, % "Bin\Wav\Click.wav"
    If (!Checked["SubmitGR"])
    {
        tmp := ""
        If WinExist("ahk_id " BR)
        {
            WinClose, % "ahk_id " BR
            BR := 0x0
            Return
        }
        WinWaitClose % "ahk_id " BR := FileSelectSpecific(""
        , "C:"
        , "Folder"
        , "Please browse an AoE II folder"
        , "Apply one of the following to do a selection:"
        . "`n1 - Copy and paste the game folder url location inside the edit box just above then click 'ENTER'."
        . "`n2 - Seek the game folder by double clicking on the icons list just above."
        . "`nAfter that select your target folder, and press 'SELECT' button just up the edit box or right mouse click then press 'SELECT'."
        , 0
        , ""
        , ""
        , ""
        , 0
        , "220"
        , "280")
        tmp := glb_FSReturn
    }
    Else
    {
        tmp := MineGameFolder()
        If (tmp = "")
        {
            WinWaitClose, % "ahk_id " MB := MessageBox(0, "Gathering game location from GameRanger", "Could not collect the game location from GameRanger, You might want to browse it manually!", "Retry,Cancel,OK")
            If (MBReturn = "Retry")
                GoSub, MainButtonBrowseAoEIIFolder
            Else If (MBReturn = "OK")
            {
                ImageButton.Create(GR, [0,"Bin\PNG\CB_UnChecked.png"], {2:"Bin\PNG\CB_UnChecked_Hover.png"})
                ModsVar["SubmitGR"] := 0, Checked["SubmitGR"] := 0
                GoSub, MainButtonBrowseAoEIIFolder
            }
            Else If (MBReturn = "Cancel")
                Return
        }
    }
    If (tmp = "")
        Return
    If (CheckFolder(tmp))
    {
        WinWaitClose, % "ahk_id " MB := MessageBox(1, "Save?", "Wanna save this location?", "No,Yes")
        If (MBReturn = "Yes")
        {
            IniRead, Lst_RBFResult, % D "\AoEII_Location.ini", AoEII_Location, Lst_RBF
            If (Lst_RBFResult != "ERROR") && If (Lst_RBFResult != "")
            {
                If (StrSplit(Lst_RBFResult, "|")[2] = tmp)
                    GuiControl, Main:, RBL, % StrSplit(Lst_RBFResult, "|")[1]
                Else
                    GuiControl, Main:, RBL, N/A
            }
            Else
                GuiControl, Main:, RBL, N/A
            IniWrite, %tmp%, %D%\AoEII_Location.ini, AoEII_Location, Dir
        }
        Else
            Return
        Control(["U", "bb", "eb", "hbf", "lgt", "ns", "st", "sw", "WTAoK", "WTC", "RB", "MF"], 0)
        GuiControl, Main:, GameLocation, % tmp
        Control(["U", "bb", "eb", "hbf", "lgt", "st", "sw", "WTAoK", "RB", "MF"], 1)
        GetGameVersion(tmp, "AOK", "")
        IniRead, AoKVer, % D "\AoEII_Location.ini", AoEII_Location, AoKVer
        UpdateVersionView(tmp, AoKVer, "")
        If VerifAoCInstall(tmp)
        {
            Control(["ns", "WTC"], 1)
            GetGameVersion(tmp, "", "AOC")
            IniRead, AoCVer, % D "\AoEII_Location.ini", AoEII_Location, AoCVer
            UpdateVersionView(tmp, "", AoCVer)
        }
        UpdateModView(tmp, "")
        If WinExist("ahk_id " MFG)
            UpdateVersions()
    }
    Else
    {
        WinWaitClose, % "ahk_id " MB := MessageBox(0, "Invalid!", "Invalid game selection!`n" tmp, "Retry,Cancel,OK")
        If (MBReturn = "Retry")
            GoSub, MainButtonBrowseAoEIIFolder
    }
    Gui, Main:Default
Return
ApplyLanguage:
    Gui, Main:Submit, NoHide
    Control(["br", "de", "fr", "es", "us"], 0)
    Sleep, 100
    FileCopyDir, % "Lng\" A_GuiControl, % GameLocation, 1
    If (!ErrorLevel)
    {
        IniRead, Lng, Lng\Def.ini, Def, %A_GuiControl%
        WinWaitClose, % "ahk_id " MB := MessageBox(1, "Language Setting Info!", "'" Lng "' was applied to be the new interface language for your game!"
        . "`n`n(Optional!) Note: This overwrite the resolution options view in game with default ones."
        . "`nTo update them to your screen resolution, install widescreen mod after applying a language.", "OK")
    }
    Else
        WinWaitClose, % "ahk_id " MB := MessageBox(0, "Language Setting Error!", "'" Lng "' was not applied to be the new interface language for your game!"
    . "`nERROR: Could not copy the language files to your game directory! Code: " ErrorLevel ".", "OK")
    Control(["br", "de", "fr", "es", "us"], 1)
Return
ApplyVersion:
    Gui, Main:Submit, NoHide
    Version := SubStr(A_GuiControl, 1, 1) "." SubStr(A_GuiControl, 2, StrLen(A_GuiControl) - 1)
    If Version in 2.0,2.0a,2.0b,2.0c
    {
        If (CleanAoK(GameLocation) = False)
        {
            WinWaitClose, % "ahk_id " MB := MessageBox(0, "Version Applying Error!", "'" Version "' was not applied to be the new version of your game!"
            . "`nERROR: Could not clean the game files to apply '" Version "'!.", "OK")
            Return
        }
        If (Version = "2.0") || (Version = "2.0a") || (Version = "2.0c")
        {
            FileCopyDir, % "Versions\" Version, % GameLocation, 1
            If (Version = "2.0c")
            {
                Run, https://aok.heavengames.com/blacksmith/showfile.php?fileid=13710
                Run, https://aok.heavengames.com/blacksmith/showfile.php?fileid=13609
                Run, http://aokpatch.ml/
            }
        }
        Else
        {
            FileCopyDir, % "Versions\2.0a", % GameLocation, 1
            FileCopyDir, % "Versions\" Version, % GameLocation, 1
        }
        Loop, Parse, % "20,20a,20b,20c", `,
        {
            If (A_LoopField = A_GuiControl)
            {
                Control([A_GuiControl], 0)
                IniWrite, % Version, % D "\AoEII_Location.ini", AoEII_Location, AoKVer
            }
            Else
                Control([A_LoopField], 1)
        }
    }
    If Version in 1.0,1.0c,1.0e
    {
        If (CleanAoC(GameLocation) = False)
        {
            WinWaitClose, % "ahk_id " MB := MessageBox(0, "Version Applying Error!", "'" Version "' was not applied to be the new version of your game!"
            . "`nERROR: Could not clean the game files to apply '" Version "'!.", "OK")
            Return
        }
        If (Version = "1.0") || (Version = "1.0c")
            FileCopyDir, % "Versions\" Version, % GameLocation, 1
        Else
        {
            FileCopyDir, % "Versions\1.0c", % GameLocation, 1
            FileCopyDir, % "Versions\" Version, % GameLocation, 1
        }
        Loop, Parse, % "10,10e,10c", `,
        {
            If (A_LoopField = A_GuiControl)
            {
                Control([A_GuiControl], 0)
                IniWrite, % Version, % D "\AoEII_Location.ini", AoEII_Location, AoCVer
            }
            Else
                Control([A_LoopField], 1)
        }
    }
    WinWaitClose, % "ahk_id " MB := MessageBox(1, "Version Applying Sucess!", "'" Version "' was applied sucessfully to be the new version of your game!", "OK")
Return
CountDown:
    CD -= 1
    If (CD > 1)
        Var := " seconds..."
    Else
        Var := " second..."
    GuiControl, MB:, CountDown, % "Closing in `n" CD Var
    If (CD = 0)
    {
        Gui, MB:Destroy
        SetTimer, CountDown, Off
    }
Return
SubmitGR:
    If (Checked["SubmitGR"])
    {
        ImageButton.Create(GR, [0,"Bin\PNG\CB_UnChecked.png"], {2:"Bin\PNG\CB_UnChecked_Hover.png"})
        ModsVar["SubmitGR"] := 0, Checked["SubmitGR"] := 0
    }
    Else
    {
        ImageButton.Create(GR, [0,"Bin\PNG\CB_Checked.png"], {2:"Bin\PNG\CB_Checked_Hover.png"})
        ModsVar["SubmitGR"] := 1, Checked["SubmitGR"] := 1
    }
Return
OpenUserPatch:
    Run, http://userpatch.aiscripters.net/
Return
ToggleSound:
    If (Sound)
    {
        GuiControl, Main:, SoundStat, Bin\PNG\SoundOff.png
        AV.controls.pause
        Sound := False
    }
    Else
    {
        GuiControl, Main:, SoundStat, Bin\PNG\SoundOn.png
        AV.controls.play
        Sound := True
    }
Return
MainGuiEscape:
MainGuiClose:
MainButtonX:
    RestoreCursors()
ExitApp
FSCreateFolder:
    Gui FileSelectSpecific: Default
    InputBox, FolderName, , % "Enter Folder Name",,,120
    if (ErrorLevel or !FolderName)
        return
    FileCreateDir, % glb_FSCurrent "/" FolderName
    FileSelectSpecificAdjust(glb_FSCurrent)
return
FSDisplayFolder:
    Gui FileSelectSpecific: Default
    FSOpenFolderInExplorer(glb_FSCurrent)
return
FSSwitchView:
    Gui FileSelectSpecific: Default
    GuiControl, -Redraw, FSListView
    if not Glb_FSIconView
        GuiControl, +Icon, FSListView
    else
        GuiControl, +Report, FSListView
    Glb_FSIconView := not Glb_FSIconView
    FSRedrawCol()
    GuiControl, +Redraw, FSListView
return
FSRedrawCol() {
    global
    Gui FileSelectSpecific: Default
    LV_ModifyCol()
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(1, "AutoHdr")
    LV_ModifyCol(3, 60)
    LV_ModifyCol(4, "AutoHdr")
}
FSListViewHandler:
    if A_GuiEvent = DoubleClick
    {
        LV_GetText(FileName, A_EventInfo, 1)
        LV_GetText(FileDir, A_EventInfo, 2)
        FilePath:=FileDir "\" FileName
        if !glb_FSCurrent
        {
            loop, parse, FileName, % ":"
            if (A_Index=1) {
                FilePath := A_Loopfield ":"
                break
            }
        }
        if InStr(FileExist(FilePath), "D") {
            glb_FSCurrent:=FilePath
            FileSelectSpecificAdjust(glb_FSCurrent)
            return
        }
        else if (FileExist(FilePath) and (glb_FSType="File" or glb_FSType="All")) {
            if glb_FSNoMulti
                glb_FSReturn:=FilePath
            else
                glb_FSReturn:=FileDir "`n" FileName
            if (glb_FSOwnerNum)
                Gui, %glb_FSOwnerNum%:-Disabled
            Gui,FileSelectSpecific:Destroy
            return
        }
    }
return
FSPrevious:
    Gui FileSelectSpecific: Default
    if !glb_FSCurrent
        return
    if (glb_FSCurrent=glb_FSFolder and glb_FSRestrict) {
        tooltip You can not navigate above the folder `n%glb_FSFolder%
        SetTimer, RemoveToolTip, -3000
        return
    }
    if !InStr(FileExist(FSGetParentDir(glb_FSCurrent)), "D")
        glb_FSCurrent:=""
    else
        glb_FSCurrent:=FSGetParentDir(glb_FSCurrent)
    FileSelectSpecificAdjust(glb_FSCurrent)
return
FSRefresh:
    Gui FileSelectSpecific: Default
    FileSelectSpecificAdjust(glb_FSCurrent)
return
FSSelect:
    Gui FileSelectSpecific: Default
    RowNumber = 0
    RowOkayed = 0
    if !LV_GetNext(RowNumber) {
        WinWaitClose, % "ahk_id " MB := MessageBox(1, "Not selected!", "Please select a folder first!", "OK")
        return
    }
    Loop
    {
        RowNumber := LV_GetNext(RowNumber)
        if not RowNumber
            break
        LV_GetText(FileName, RowNumber, 1)
        LV_GetText(FileDir, RowNumber, 2)
        FilePath:=FileDir "\" FileName
        if !glb_FSCurrent
        {
            loop, parse, FileName, % ":"
            if (A_Index=1) {
                FilePath := A_Loopfield ":"
                FileName := A_Loopfield ":"
                break
            }
        }
        if !FileExist(FilePath)
            continue
        if (InStr(FileExist(FilePath), "D") and glb_FSType="File")
            continue
        if (!InStr(FileExist(FilePath), "D") and glb_FSType="Folder")
            continue
        RowOkayed++
        glb_FSMultiReturn.= "`n" FileName
    }
    if (RowOkayed=0) {
        WinWaitClose, % "ahk_id " MB := MessageBox(1, "Wrong!", "Sorry wrong selection", "OK")
        return
    }
    if (RowOkayed=1 and glb_FSNoMulti)
        glb_FSReturn:=FilePath
    else
        glb_FSReturn:=FileDir . glb_FSMultiReturn
    if (glb_FSOwnerNum)
        Gui, %glb_FSOwnerNum%:-Disabled
    Gui,FileSelectSpecific:Destroy
return
#If (FSHwnd and WinActive("ahk_id " FSHwnd))
Enter::
GuiControlGet, OutputVar, FileSelectSpecific:FocusV
if (OutputVar="FSNavBarv")
    Gosub, FSNavBar
Return
#If
    FSNavBar:
    Gui, FileSelectSpecific:Default
    GuiControlGet, FSNavBarv
    StringRight, LastChar, FSNavBarv, 1
    if LastChar = \
        StringTrimRight, FSNavBarv, FSNavBarv, 1
    if !InStr(FileExist(FSNavBarv), "D")
        return
    if (glb_FSRestrict and !Instr(FSNavBarv,glb_FSFolder)) {
        tooltip You can not navigate above the folder `n%glb_FSFolder%
        SetTimer, RemoveToolTip, -3000
        return
    }
    GuiControl,,FSNavBarv,% FSNavBarv
    glb_FSCurrent:=FSNavBarv
    FileSelectSpecificAdjust()
return
RemoveToolTip:
    Tooltip
return
FileSelectSpecificGuiContextMenu:
    Gui FileSelectSpecific: Default
    if A_GuiControl <> FSListView
        return
    Menu, FSContextMenu, Show
return
FileSelectSpecificButtonX:
FileSelectSpecificGuiClose:
    if glb_FSOwnerNum
        try, Gui,%glb_FSOwnerNum%:-Disabled
    Gui,Destroy
    tmp := ""
return
FileSelectSpecificGuiSize:
    if A_EventInfo = 1
        return
    if glb_FSInit
        return
    GuiControl, -Redraw, FSListView
    GuiControlGet, FSComplementv
    GuiControlGet, FSMultiIndicv
    GuiControlGet, FSListViewPos, Pos, FSListView
    GuiControl, MoveDraw, FSPromptv, % " W" . (A_GuiWidth-20)
    GuiControl, MoveDraw, FSNavBarv, % " W" . (A_GuiWidth-20)
    FSListGap=
    if (FSComplementv) {
        GuiControl, MoveDraw, FSComplementv, % "y" FSListViewPosY + FSListViewPosH + 10 " W" . (A_GuiWidth-20)
        FSListGap+=10
    }
    GuiControlGet, FSComplementPos, Pos, FSComplementv
    if (FSMultiIndicv) {
        GuiControl, MoveDraw, FSMultiIndicv, % "y" A_GuiHeight-20 " W" . (A_GuiWidth-20)
        FSListGap+=5
    }
    GuiControlGet, FSMultiIndicPos, Pos, FSMultiIndicv
    FSListGap:=Round(FSComplementPosH) + Round(FSMultiIndicPosH) + 15
    GuiControl, MoveDraw, FSListView, % "W" . (A_GuiWidth - 20) . " H" . (A_GuiHeight - FSListViewPosY - Round(FSListGap))
    if (Glb_FSIconView)
        SetTimer, FileSelectSpecificAdjust, -200
    GuiControl, +Redraw, FSListView
Return
FSGetParentDir(Path) {
return SubStr(Path, 1, InStr(SubStr(Path,1,-1), "\", 0, 0)-1)
}
FSOpenFolderInExplorer(P_Folder) {
    global
    if !InStr(FileExist(P_Folder), "D")
        return 0
    Run % P_Folder
}
tjqy_This_and_next_line_added_by_Ahk2Exe:
    Exit
