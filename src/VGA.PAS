Unit VGA;
(* Mode-X / Standard VGA Routines *)


Interface

Uses Videoobj;

Const
 FirstPlane = $0102;   (* 02 = Index to Color plane Select, *)
                       (* 01 = Enable color plane 1         *)
Type
(* Standard mode 13h *)
PVGALoVideo = ^TVGALoVideo;
TVGALoVideo = Object(TVideo)
 Constructor Init;
 Destructor Done; Virtual;
 Procedure PutPixel(Const X,Y: Integer; Const Color: Byte); Virtual;
 Function  GetPixel(Const X,Y: Integer): Integer; Virtual;
 Procedure ClearScreen; Virtual;

 Procedure SetPalette(Const Color: Byte; Const Red, Green, Blue: DByte);

(* CE QU'IL RESTE A FAIRE POUR CES ROUTINES *)


(* *)
 Procedure GetBitmap(var Image; X, Y, Width, Height: Integer); Virtual;
 Procedure DrawBitmap(Var Image; XPos, YPos: Integer); Virtual;
 Procedure DrawSprite(Var Image; XPos, YPos: Integer); Virtual;

 Procedure Bar(X1,Y1,X2,Y2:Integer); Virtual;
 Procedure Rectangle(X1,Y1,X2,Y2: Integer); Virtual;
 Procedure Line(X1, Y1,X2, Y2: Integer); Virtual;
 Procedure Circle(X,Y: Integer; Radius: Word); Virtual;

 Procedure SetColor(Color: Byte); Virtual;
 Procedure SetBkColor(Color: Word); Virtual;
(* Copies a full screen in memory to video screen memory *)
 Procedure CopyToScreen(Image: Pointer);

 Procedure SetViewPort(X1,Y1,X2,Y2: Integer); Virtual;
 Procedure ClearViewPort; Virtual;
end;




(* Some non-speed essential routines have been left in High level pascal *)
(* so people looking at the code understand how it was done.             *)
PModeXVideo = ^TModeXVideo;
TModeXvideo = Object(TVideo)
     OldVidMode: Byte;           (* Old Video Mode *)
     ActStart  : Word;           (* Start offset of active video page  *)
     VisStart  : Word;           (* Start offset of visible video page *)
     WidthBytes:  Word;          (* Width in bytes (planes) per x      *)
     CrtAddress: Word;           (* CRTC Video Address                 *)
     Page0Addr : Word;           (* Page One address                   *)
     Page1Addr : Word;           (* Page Two address                   *)
     Page2Addr : Word;           (* Page Three address                 *)
     Page3Addr : Word;           (* Page 4 address                     *)
    Constructor Init(Var AMode: Integer);
    Destructor Done; Virtual;
    Procedure GotoXY(Const X,Y: Integer); Virtual;
    Procedure PutPixel(Const X,Y: Integer; Const Color: Byte); Virtual;
    Function  GetPixel(Const X,Y: Integer): Integer; Virtual;
    Procedure ClearScreen; Virtual;

(* Page flipping routines *)
(* EGA/VGA Modes only     *)
    Procedure CopyPage(Const SourcePage, DestPage: Byte); Virtual;
    Procedure DisplayPage(Const PageNo: Byte); Virtual;
    Procedure SetActivePage(Const PageNo: Byte); Virtual;

(* Bitmap/sprite routines *)
(* SAME CONVENTION AS IN BORLAND PASCAL FOR BITMAPS/SPRITES *)
{
    Offset      SIZE      Information
    0           Word      Width  of Image
    2           Word      Height of Image
    4           Word      Reserved
    }
{    Procedure GetBitmap(var Image; X,Y,Width,Height: Integer); Virtual;
    Procedure DrawBitmap(Var Image; XPos,YPos: Integer); Virtual;
    Procedure DrawSprite(Var Image;XPos, YPos: Integer); Virtual;
    Procedure CopyBitmap(SourcePage,X1,Y1,X2,Y2,DestPage,DestX1,DestY1: Integer); Virtual;}


(* Color/palette routines *)
    Procedure SetPalette(Const Color: Byte; Const Red, Green, Blue: DByte);(* Sets current drawing color *)
    Procedure SetColor(Color: Byte); Virtual;
    Procedure SetBkColor(Color: Word); Virtual;

{    Procedure SetWriteMode(WriteMode: Integer); Virtual;}


    (* Uses current drawing color set by SetColor *)
{    Procedure Bar(X1,Y1,X2,Y2:Integer); Virtual;}
    Procedure Circle(X,Y: Integer; Radius: Word); Virtual;
    Procedure Rectangle(X1,Y1,X2,Y2: Integer); Virtual;
    Procedure Line(X1, Y1,X2, Y2: Integer); Virtual;
(*    Procedure FillCircle(X,Y: Integer; Radius: Word); Virtual; *)

(* String/Character routines *)

(* Uses Interrupt Fonts to write to screen *)
(* IN MODE-X ALL FONTS ARE 8 by 8          *)
{    Procedure SystemWrite(X,Y: Byte;Const Color:Byte; Const S:String); Virtual;
    Function SystemFontWidth:  Word;
    Function SystemFontHeight: Word;}

(* Uses other fonts to write to screen *)
{    Procedure OutText(Var S:String; FontNo: Integer); Virtual;
    Function TextWidth: Integer;
    Function TextHeight: Integer;
    Procedure ReadChar(Var ACh: Char); Virtual;
    Procedure WriteChar(ACh: Char); Virtual;}
Private
    (* Returns correct CRTC controller address *)
    Function GetCRTAddress: Word;
    Procedure SetVisibleStart(Offset: Integer);
    Procedure SetActiveStart(Offset: Integer);
end;


Implementation



Function TModeXVideo.GetCRTAddress: Word;Assembler;
ASM
 MOV ES, [Seg0040]
 MOV DI, 063h                  ; (* BIOS Work Area - Get CRTC Address *)
 MOV AX, WORD PTR ES:[DI]
end;


Constructor TModeXVideo.Init(Var AMode: Integer);
(* AMode = 1 then 320x200x256c x 4 pages  *)
(*         2 then 320x240x256c x 3 pages  *)
(*         3 then 320x400x256c x 2 pages  *)
Begin
 Inherited Init(AMode);
 (* Get correct CRTC address *)
 CrtAddress:= GetCRTAddress;
 BackColor:=0;
 SpriteColor:=0;
 MaxColor:=255;
 FntXSize:=8;
 FntYSize:=8;
 PalSize:=262144;
 (* In all cases Mode 13h is set at the start *)
   ASM
   (* Get current video mode at BIOS Work Area *)
     PUSH DS                   ; (* Save Data Segment         *)
     LDS SI, [Self]            ; (* Get pointer to Object     *)
     MOV DI, 49h               ; (* Address 0449h             *)
     MOV ES, [Seg0040]
     MOV AL, ES:[DI]
     MOV DS:[SI].OldVidMode, AL ; (* Get current video mode   *)
     POP DS                    ; (* Restore saved DS context  *)
   (* Set Mode 13h Standard Video mode *)
     MOV AX, 13h
     INT 10h
    end;
 Case AMode Of
 (* for this particular mode *)
 2: Begin
   MaxX:=319;
   MaxY:=239;
   MaxPages:=3;
   CurPage:=0;
   Page0Addr:=0;
   Page1Addr:=19200;
   Page2Addr:=38400;
   Page3Addr:=0;    (* no page four in this particular mode *)
(* Put in Mode-Y 320x200x256cx4 pages *)
     (* Turn off the Chain-4 bit (bit 3 at index 4, port 0x3c4): *)
    PortW[$03c4]:=$0604;
         (* Turn off word mode, by setting the Mode Control register
           of the CRT Controller (index 0x17, port 0x3d4): *)
    PortW[CRTAddress]:=$E317;
        (* Turn off doubleword mode, by setting the Underline Location
           register (index 0x14, port 0x3d4): *)
    PortW[CRTAddress]:=$0014;
(* End Mode-Y Set up *)
(* Start Mode-X 320x240x256cx3 pages *)
        (* Modify the vertical sync polarity bits in the Misc. Output
           Register to achieve square aspect ratio: *)
     Port[$03c2]:=$E3;
        (* Modify the vertical timing registers to reflect the increased
           vertical resolution, and to center the image as good as
           possible: *)
     PortW[CRTAddress]:=$2C11;          (* Turn off write protect *)
     PortW[CRTAddress]:=$0D06;          (* Vertical total         *)
     PortW[CRTAddress]:=$3E07;          (* Overflow register      *)
     PortW[CRTAddress]:=$EA10;          (* Vertical retrace start *)
     PortW[CRTAddress]:=$AC11;          (* Vert. retr. end and wprot *)
     PortW[CRTAddress]:=$DF12;          (* Vertical display enable end *)
     PortW[CRTAddress]:=$E715;          (* Start vertical blanking *)
     PortW[CRTAddress]:=$0616;          (* End Vertical blanking   *)
 end;
(* End Mode-X setup *)
 1: Begin
   MaxX:=319;
   MaxY:=199;
   MaxPages:=4;
   CurPage:=0;
   Page0Addr:=0;
   Page1Addr:=16000;
   Page2Addr:=32000;
   Page3Addr:=48000;    (* no page four in this particular mode *)
(* Put in Mode-Y 320x200x256cx4 pages *)
     (* Turn off the Chain-4 bit (bit 3 at index 4, port 0x3c4): *)
    PortW[$03c4]:=$0604;
         (* Turn off word mode, by setting the Mode Control register
           of the CRT Controller (index 0x17, port 0x3d4): *)
    PortW[CRTAddress]:=$E317;
        (* Turn off doubleword mode, by setting the Underline Location
           register (index 0x14, port 0x3d4): *)
    PortW[CRTAddress]:=$0014;
(* End Mode-Y Set up *)
 end;
 end;
    ClearScreen;
    ActStart := 0;     (* Active  display page = 0 *)
    VisStart := 0;     (* Visible display page = 0 *)
   (* SET VISIBLE SCREEN PART TO 000h *)
   DisplayPage(0);
   SetActivePage(0);
   WidthBytes:= (MaxX+1) div 4;             (* Calculate width bytes of screen *)
end;


Destructor TModeXVideo.Done;
Begin
 Inherited Done;
 ASM
  XOR AH, AH
  MOV AL,[OldVidMode]
  INT 10h                ; (* Restore old Video mode *)
 end;
end;

Procedure TModeXVideo.SetActivePage(Const PageNo: Byte);
Begin
 Case PageNo of
 0: SetActiveStart(Page0Addr);
 1: If Page1Addr <> 0 then SetActiveStart(Page1Addr);
 2: If Page2Addr <> 0 then SetActiveStart(Page2Addr);
 3: If Page3Addr <> 0 then SetActiveStart(Page3Addr);
 end;
 CurPage:=PageNo;
end;


Procedure TModeXVideo.DisplayPage(Const PageNo: Byte);
Begin
 Case PageNo of
 0: SetVisibleStart(Page0Addr);
 1: If Page1Addr <> 0 then SetVisibleStart(Page1Addr);
 2: If Page2Addr <> 0 then SetVisibleStart(Page2Addr);
 3: If Page3Addr <> 0 then SetVisibleStart(Page3Addr);
 end;
 VisiblePage:=PageNo;
end;

Procedure TModeXVideo.GotoXY(Const X,Y: Integer);
Begin
 CurX:=X;
 CurY:=Y;
end;





Procedure TModeXVideo.SetActiveStart(Offset: Integer);
(* Selects active display memory offset where to draw *)
Begin
 ActStart:=Offset;
end;

Procedure TModeXVideo.SetVisibleStart(Offset: Integer);
(* Select where the left corner of the screen will be *)
Begin
  (* Index $0C *)
  Port[CRTAddress]:=$0C;
  (* Start Memory Video address High of upper left corner of screen *)
  Port[CRTAddress+1]:=Offset shr 8;
  Port[CRTAddress]:=$0D;
  (* Start Memory Video address Low of upper left corner of screen *)
  Port[CRTAddress]:=Offset and $FF;
end;


Procedure TModeXVideo.PutPixel(Const X,Y: Integer; Const Color: Byte); Assembler;
{Begin
        (* Each address accesses four neighboring pixels, so set
           Write Plane Enable according to which pixel we want
           to modify.  The plane is determined by the two least
           significant bits of the x-coordinate: *)
        Port[$03c4]:=$02;                ; (* Select 2nd Index register *)
        Port[$03c5]:=$01 shl (x and 3);  ; (* Enable correct plane for data write *)
        (* The offset of the pixel into the video segment is
           offset = (width * y + x) / 4, and write the given
           color to the plane we selected above.  Heed the active
           page start selection. *)
        Move(Color,Mem[SegA000:WidthBytes*Y+(X div 4)+ActStart],1);
end;}
ASM
  LES SI, [Self]               ; (* Get pointer to Object in LES SI   *)
  MOV DI,[y]                   ; (* DI = Y coordinate                 *)
(* Multiply by 80 start *)
  MOV BX, DI
{$IFOPT G+}
  SHL DI, 6                    ; (* Faster on 286/386/486 machines    *)
  SHL BX, 4
{$ELSE}
  SHL DI, 1                    ; (* Faster then a move followed bu SHL ,CL!! *)
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL BX, 1
  SHL BX, 1
  SHL BX, 1
  SHL BX, 1
{$ENDIF}
  ADD DI, BX                   ;  (* Multiply Value by 80             *)
(* End multiply by 80  *)
  MOV CX, [X]
  MOV AX, CX
 {DI = Y * LINESIZE, BX = X, coordinates admissible}
{$IFDEF i386}
  SHR AX, 2
{$ELSE}
  SHR AX, 1                    ; (* Faster on 286/86 machines         *)
  SHR AX, 1
{$ENDIF}
  ADD DI, AX                ; {DI = Y * LINESIZE + (X SHR 2) }
  ADD DI, ES:[SI].ActStart  ; (* Pointing at start of Active page *)
(* Select plane to use *)
  MOV DX, 03c4h
  MOV AX, FirstPlane        ; (* Map Mask & Plane Select Register *)
  AND CL, 03h               ; (* Get Plane Bits                   *)
  SHL AH, CL                ; (* Get Plane Select Value           *)
  OUT DX, AX
(* End selection of plane *)
  MOV ES,[SegA000]
  MOV AL, Color
  MOV ES:[DI], AL           ; (* Store AL to ES:[DI] - Faster then STOSB *)
end;                          (* on 8086 machines                        *)

Function  TModeXVideo.GetPixel(Const X,Y: Integer): Integer; Assembler;
ASM
  LES SI, [Self]               ; (* Get pointer to Object in LES SI   *)
  MOV DI,[y]                   ; (* DI = Y coordinate                 *)
(* Multiply by 80 start *)
  MOV BX, DI
{$IFOPT G+}
  SHL DI, 6                    ; (* Faster on 286/386/486 machines    *)
  SHL BX, 4
{$ELSE}
  SHL DI, 1                    ; (* Faster then a move followed bu SHL ,CL!! *)
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL BX, 1
  SHL BX, 1
  SHL BX, 1
  SHL BX, 1
{$ENDIF}
  ADD DI, BX                   ;  (* Multiply Value by 80             *)
(* End multiply by 80  *)
  MOV CX, [X]
  MOV AX, CX
 {DI = Y * LINESIZE, BX = X, coordinates admissible}
{$IFDEF i386}
  SHR AX, 2
{$ELSE}
  SHR AX, 1                    ; (* Faster on 286/86 machines         *)
  SHR AX, 1
{$ENDIF}
  ADD DI, AX                ; {DI = Y * LINESIZE + (X SHR 2) }
  ADD DI, ES:[SI].ActStart  ; (* Pointing at start of Active page *)
(* Select plane to use *)
  MOV DX, 03c4h
  MOV AX, FirstPlane        ; (* Map Mask & Plane Select Register *)
  AND CL, 03h               ; (* Get Plane Bits                   *)
  SHL AH, CL                ; (* Get Plane Select Value           *)
  OUT DX, AX
(* End selection of plane *)
  MOV ES,[SegA000]
  MOV AL, ES:[DI]
  XOR AH, AH
end;

Procedure TModeXVideo.ClearScreen; Assembler;
(* UNFINISHED GET ACTIVE DISPLAY PAGE FIRST *)
ASM
(* Clear Screen Routine *)
 MOV DX,03C4h                 ; (* Go to index #2 of Port 03c5h                  *)
 MOV AL,02
 OUT DX,AL                    ; (* Port[$03c4h] := 02   (Select port Index)      *)
 INC DX                       ; (* 03c5h                                         *)
 MOV AL,0Fh                   ; (* AL = 15 (all bitplanes are selected           *)
 OUT DX,AL                    ; (* All bit planes are selected                   *)
 LES DI, [Self]
 MOV AL, ES:[DI].BackColor
 XOR DI, DI;                  ; (* DI points to Start Offset of Screen    *)
 MOV AH, AL                   ; (* Both AH and AL have the same backcolor *)
 MOV ES,[SegA000]             ; {words = 4*8000h physical words (because of 4     }
 MOV CX,8000h                 ; (* 8000 * 4 = 32000 words to move = 64000 bytes    *)
 CLD
 REP STOSW                    ; (* Store AH and AL to screen                        *)
(* end Clear Screen *)
end;

Procedure TModeXVideo.SetPalette(Const Color: Byte; Const Red, Green, Blue: DByte);Assembler;
ASM
 MOV DX, 03c8h
 MOV AL, Color                 ; (* Put port index in AX          *)
 OUT DX, AL                    ; (* Output AX immediately to port *)
 MOV DX, 03c9h
 MOV AL, Red                   ; (* Move Red Value into Accumulator *)
 OUT DX, AL                    ; (* Output Red Value to port      *)
 MOV AL, Green                 ; (* Mode Green Value into Accumul *)
 OUT DX, AL                    ; (* Output Green Value to port    *)
 MOV AL, Blue                  ; (* Put Blue value into Accumulator *)
 OUT DX, AL                    ; (* Ouput Blue value to port      *)
end;

Procedure TModeXVideo.Line(X1,Y1,X2,Y2: Integer);
var
  i : Word;
  deltax: Integer;
  deltay: Integer;
  numpixels: Integer;
  d: Integer;
  dinc1: Integer;
  dinc2: Integer;
  x : Integer;
  xinc1: Shortint;  (* Values -1, 0 , 1 *)   (* BH *)
  xinc2: Shortint;  (* Values -1, 0 , 1 *)   (* DH *)
  y: Integer;
  yinc1: Shortint;  (* Values -1, 0 , 1 *)   (* DL *)
  yinc2: Shortint;  (* Values -1, 0 , 1 *)   (* CL *)
  Color: Byte;
begin
   Color:= CurColor;
  { Calculate deltax and deltay for initialisation }
  deltax := abs(x2 - x1);
  deltay := abs(y2 - y1);
  { Initialize all vars based on which is the independent variable }
  if deltax >= deltay then
    begin
      { x is independent variable }
      numpixels := deltax + 1;
      d := deltay shl 2 - deltax;
      dinc1 := deltay Shl 1;
      dinc2 := (deltay - deltax) shl 1;
      xinc1 := 1;
      xinc2 := 1;
      yinc1 := 0;
      yinc2 := 1;
    end
  else
    begin
      { y is independent variable }
      numpixels := deltay + 1;
{      d := (2 * deltax) - deltay;}
       d:= deltax shl 2 - deltay;
      dinc1 := deltax Shl 1;
      dinc2 := (deltax - deltay) shl 1;
      xinc1 := 0;
      xinc2 := 1;
      yinc1 := 1;
      yinc2 := 1;
    end;
  { Make sure x and y move in the right directions }
  if x1 > x2 then
    begin
      xinc1 := - xinc1;
      xinc2 := - xinc2;
    end;
  if y1 > y2 then
    begin
      yinc1 := - yinc1;
      yinc2 := - yinc2;
    end;
  { Start drawing at <x1, y1> }
  x := x1;
  y := y1;
  { Draw the pixels }
  for i := 1 to numpixels do
    begin
  (* Putpixel routine *)
  (*  PutPixel( X, Y, Color); *)
   ASM
     LES SI, [Self]               ; (* Get pointer to Object in LES SI   *)
     MOV DI,[y]                   ; (* DI = Y coordinate                 *)
(* Multiply by 80 start *)
     MOV BX, DI
{$IFOPT G+}
     SHL DI, 6                    ; (* Faster on 286/386/486 machines    *)
     SHL BX, 4
{$ELSE}
     SHL DI, 1                    ; (* Faster then a move followed bu SHL ,CL!! *)
     SHL DI, 1
     SHL DI, 1
     SHL DI, 1
     SHL DI, 1
     SHL DI, 1
     SHL BX, 1
     SHL BX, 1
     SHL BX, 1
     SHL BX, 1
{$ENDIF}
     ADD DI, BX                   ;  (* Multiply Value by 80             *)
(* End multiply by 80  *)
     MOV CX, [X]
     MOV AX, CX
 {DI = Y * LINESIZE, BX = X, coordinates admissible}
{$IFDEF i386}
     SHR AX, 2
{$ELSE}
     SHR AX, 1                    ; (* Faster on 286/86 machines         *)
     SHR AX, 1
{$ENDIF}
     ADD DI, AX                ; {DI = Y * LINESIZE + (X SHR 2) }
     ADD DI, ES:[SI].ActStart  ; (* Pointing at start of Active page *)
(* Select plane to use *)
     MOV DX, 03c4h
     MOV AX, FirstPlane        ; (* Map Mask & Plane Select Register *)
     AND CL, 03h               ; (* Get Plane Bits                   *)
     SHL AH, CL                ; (* Get Plane Select Value           *)
     OUT DX, AX
(* End selection of plane *)
    MOV ES,[SegA000]
    MOV AL, [Color]
    MOV ES:[DI], AL           ; (* Store AL to ES:[DI]              *)
   end;
      if d < 0 then
        begin
          d := d + dinc1;
          x := x + xinc1;
          y := y + yinc1;
        end
      else
        begin
          d := d + dinc2;
          x := x + xinc2;
          y := y + yinc2;
        end;
    end;
end;



Procedure TModeXVideo.Circle(X, Y: Integer; Radius:Word);
Var
   Xs, Ys    : Integer;
   Da, Db, S : Integer;
Begin
     if (Radius = 0) then
          Exit;
     if (Radius = 1) then
     begin
          PutPixel(X, Y, CurColor);
          Exit;
     end;
     Xs := 0;
     Ys := Radius;
     Repeat
           Da := Sqr(Xs+1) + Sqr(Ys) - Sqr(Radius);
           Db := Sqr(Xs+1) + Sqr(Ys - 1) - Sqr(Radius);
           S  := Da + Db;
           Xs := Xs+1;
           if (S > 0) then
                Ys := Ys - 1;
           PutPixel(X+Xs-1, Y-Ys+1, CurColor);
           PutPixel(X-Xs+1, Y-Ys+1, CurColor);
           PutPixel(X+Ys-1, Y-Xs+1, CurColor);
           PutPixel(X-Ys+1, Y-Xs+1, CurColor);
           PutPixel(X+Xs-1, Y+Ys-1, CurColor);
           PutPixel(X-Xs+1, Y+Ys-1, CurColor);
           PutPixel(X+Ys-1, Y+Xs-1, CurColor);
           PutPixel(X-Ys+1, Y+Xs-1, CurColor);
     Until (Xs >= Ys);
end;

Procedure TModeXVideo.SetColor(Color: Byte);
Begin
 CurColor:=Color;
end;

Procedure TModeXVideo.SetBkColor(Color: Word);
Begin
 BackColor:=Color;
end;



Procedure TModeXVideo.CopyPage(Const SourcePage, DestPage: Byte);
Var
 SourceAddress: Word;
 DestAddress  : Word;
 ScrSize: Word                 ; (* Screen size in words *)
Begin
 ScrSize:=WidthBytes*(MaxY+1);
 PortW[$03ce]:=$0000+$08;    (* Select bit mask from VRAM to VRAM *)
 Case SourcePage of
 0: SourceAddress:=Page0Addr;
 1: SourceAddress:=Page1Addr;
 2: SourceAddress:=Page2Addr;
 3: SourceAddress:=Page3Addr;
 end;
 Case DestPage of
 0: DestAddress:=Page0Addr;
 1: DestAddress:=Page1Addr;
 2: DestAddress:=Page2Addr;
 3: DestAddress:=Page3Addr;
 end;
 (* If both are the same page save some CPU time by not copying anything *)
 If DestAddress = SourceAddress then Exit;
 (* Two port acesses in one shot *)
 (* Low Byte = Port Index to select and Hight Byte = Value at Port+1 *)
 (* Same thing as:
    Port[$03c4]:=$02 followed by  Port[$03c4+1]:=$0F                 *)
 (* Select port index and Enable all color planes for access         *)
 PortW[$03c4]:=$0F02;
 (* Copy from VRAM to VRAM *)
(* Move(Mem[SegA000:SourceAddress],Mem[SegA000:DestAddress],WidthBytes*(MaxY+1)); *)
 ASM
  PUSH DS
  MOV ES, [SegA000]
  MOV SI, [SourceAddress]
  MOV DI, [DestAddress]
  MOV DS, [SegA000]
  MOV CX, [ScrSize]
  CLD
  REP MOVSB
  POP DS
 end;
 Port[$03ce+1]:=$FF;         (* Select bit mask from SRAM to VRAM *)
end;






Procedure TModeXVideo.Rectangle(X1,Y1,X2,Y2: Integer);
Var
 Width: Word;
 Height: Word;
 i: Word;
Begin
{$IFOPT R+}
 Width := abs(X2-X1);
 Height:= abs(Y2-Y1);
{$ENDIF}
{$IFOPT R-}
 Width := X2-X1;
 Height:= Y2-Y1;
{$ENDIF}
 For i:=0 to Width do
 Begin
(*   PutPixel(X1+i, Y1, CurColor); *)
ASM
  PUSH DS
  LDS SI, [Self]               ; (* Get pointer to Object in LDS SI   *)
  MOV ES,[SegA000]             ; (* ES points to Video Segment        *)
  MOV DI,[y1]                  ; (* DI = Y coordinate                 *)
(* Multiply by 80 start *)
  MOV BX, DI
{$IFOPT G+}
  SHL DI, 6                    ; (* Faster on 286/386/486 machines    *)
  SHL BX, 4
{$ELSE}
  SHL DI, 1                    ; (* Faster then a move followed bu SHL ,CL!! *)
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL BX, 1
  SHL BX, 1
  SHL BX, 1
  SHL BX, 1
{$ENDIF}
  ADD DI, BX                   ;  (* Multiply Value by 80             *)
(* End multiply by 80  *)
  MOV CX, [X1]
  ADD CX, [i]                 ;   (* CX:=CX+i = X1:=X1+i             *)
  MOV AX, CX
 {DI = Y * LINESIZE, BX = X, coordinates admissible}
{$IFDEF i386}
  SHR AX, 2
{$ELSE}
  SHR AX, 1                    ; (* Faster on 286/86 machines         *)
  SHR AX, 1
{$ENDIF}
  ADD DI, AX                    ; {DI = Y * LINESIZE + (X SHR 2) }
  ADD DI, DS:[SI].ActStart      ; (* Pointing at start of Active page *)
(* Select plane to use *)
  MOV DX, 03c4h
  MOV AX, FirstPlane        ; (* Map Mask & Plane Select Register *)
  AND CL, 03h               ; (* Get Plane Bits                   *)
  SHL AH, CL                ; (* Get Plane Select Value           *)
  OUT DX, AX
(* End selection of plane *)
  MOV AL, DS:[SI].CurColor
  MOV ES:[DI], AL              ; (* Store AL to ES:[DI]              *)
(* end putpixel *)
(*   PutPixel(X1+i,Y2, CurColor); *)
  MOV DI,[y2]                   ; (* DI = Y coordinate                 *)
(* Multiply by 80 start *)
  MOV BX, DI
{$IFOPT G+}
  SHL DI, 6                    ; (* Faster on 286/386/486 machines    *)
  SHL BX, 4
{$ELSE}
  SHL DI, 1                    ; (* Faster then a move followed bu SHL ,CL!! *)
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL BX, 1
  SHL BX, 1
  SHL BX, 1
  SHL BX, 1
{$ENDIF}
  ADD DI, BX                   ;  (* Multiply Value by 80             *)
(* End multiply by 80  *)
  MOV CX, [X1]
  ADD CX, [i]
  MOV AX, CX
 {DI = Y * LINESIZE, BX = X, coordinates admissible}
{$IFDEF i386}
  SHR AX, 2
{$ELSE}
  SHR AX, 1                    ; (* Faster on 286/86 machines         *)
  SHR AX, 1
{$ENDIF}
  ADD DI, AX                ; {DI = Y * LINESIZE + (X SHR 2) }
  ADD DI, DS:[SI].ActStart  ; (* Pointing at start of Active page *)
(* Select plane to use *)
  MOV DX, 03c4h
  MOV AX, FirstPlane        ; (* Map Mask & Plane Select Register *)
  AND CL, 03h               ; (* Get Plane Bits                   *)
  SHL AH, CL                ; (* Get Plane Select Value           *)
  OUT DX, AX
(* End selection of plane *)
  MOV AL, DS:[SI].CurColor
  MOV ES:[DI], AL           ; (* Store AL to ES:[DI]              *)
  POP DS
end;
(* end putpixel *)
 end;
 For i:=0 to Height do
 Begin
 ASM
  PUSH DS
  LDS SI, [Self]               ; (* Get pointer to Object in LDS SI   *)
  MOV ES,[SegA000]             ; (* ES points to Video Segment        *)
  MOV DI,[Y1]                  ; (* DI = Y coordinate                 *)
  ADD DI, [i]
(* Multiply by 80 start *)
  MOV BX, DI
{$IFOPT G+}
  SHL DI, 6                    ; (* Faster on 286/386/486 machines    *)
  SHL BX, 4
{$ELSE}
  SHL DI, 1                    ; (* Faster then a move followed bu SHL ,CL!! *)
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL BX, 1
  SHL BX, 1
  SHL BX, 1
  SHL BX, 1
{$ENDIF}
  ADD DI, BX                   ;  (* Multiply Value by 80             *)
(* End multiply by 80  *)
  MOV CX, [X1]
  MOV AX, CX
 {DI = Y * LINESIZE, BX = X, coordinates admissible}
{$IFDEF i386}
  SHR AX, 2
{$ELSE}
  SHR AX, 1                    ; (* Faster on 286/86 machines         *)
  SHR AX, 1
{$ENDIF}
  ADD DI, AX                    ; {DI = Y * LINESIZE + (X SHR 2) }
  ADD DI, DS:[SI].ActStart      ; (* Pointing at start of Active page *)
(* Select plane to use *)
  MOV DX, 03c4h
  MOV AX, FirstPlane        ; (* Map Mask & Plane Select Register *)
  AND CL, 03h               ; (* Get Plane Bits                   *)
  SHL AH, CL                ; (* Get Plane Select Value           *)
  OUT DX, AX
(* End selection of plane *)
  MOV AL, DS:[SI].CurColor
  MOV ES:[DI], AL              ; (* Store AL to ES:[DI]              *)
(* end putpixel *)
(*   PutPixel(X1+i,Y2, CurColor); *)
  MOV DI,[Y1]                   ; (* DI = Y coordinate                 *)
  ADD DI, [i]
(* Multiply by 80 start *)
  MOV BX, DI
{$IFOPT G+}
  SHL DI, 6                    ; (* Faster on 286/386/486 machines    *)
  SHL BX, 4
{$ELSE}
  SHL DI, 1                    ; (* Faster then a move followed bu SHL ,CL!! *)
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL DI, 1
  SHL BX, 1
  SHL BX, 1
  SHL BX, 1
  SHL BX, 1
{$ENDIF}
  ADD DI, BX                   ;  (* Multiply Value by 80             *)
(* End multiply by 80  *)
  MOV CX, [X2]
  MOV AX, CX
 {DI = Y * LINESIZE, BX = X, coordinates admissible}
{$IFDEF i386}
  SHR AX, 2
{$ELSE}
  SHR AX, 1                    ; (* Faster on 286/86 machines         *)
  SHR AX, 1
{$ENDIF}
  ADD DI, AX                ; {DI = Y * LINESIZE + (X SHR 2) }
  ADD DI, DS:[SI].ActStart  ; (* Pointing at start of Active page *)
(* Select plane to use *)
  MOV DX, 03c4h
  MOV AX, FirstPlane        ; (* Map Mask & Plane Select Register *)
  AND CL, 03h               ; (* Get Plane Bits                   *)
  SHL AH, CL                ; (* Get Plane Select Value           *)
  OUT DX, AX
(* End selection of plane *)
  MOV AL, DS:[SI].CurColor
  MOV ES:[DI], AL           ; (* Store AL to ES:[DI]              *)
  POP DS
  end;
{   PutPixel(X1, Y1+i, CurColor);
(* end Putpixel *)
   PutPixel(X2,Y1+i, CurColor);}
 end;
End;









Constructor TMode13Video.Init;
Var
 AMode: Integer;
Begin
 AMode:=$13;
 Inherited Init(AMode);
 ASM
  MOV ES, [Seg0040]            ; (* Get BIOS Work Segment      *)
  MOV DI, 49h                  ; (* Offset = Current Scr Mode  *)
  MOV AL, BYTE PTR ES:[DI]     ; (* Move Current Vid Mode in AL*)
  LES DI, [Self]               ; (* Load Pointer to Object     *)
  MOV ES:[DI].OldVideo, AL     ; (* Move Vid Mode into OldVideo*)
  MOV AX, 0013h                ; (* Setup function call (BIOS) *)
  INT 10h;                     ; (* Change video mode to 13h   *)
 end;
 (* Set up Constants *)
 SpriteColor:=0;
 BackColor:=0;
 CurColor :=0;
 MaxX:= 319;
 MaxY:= 199;
 MaxColor:= 255;
 CurX:= 0;
 CurY:= 0;
 MaxPages:=0;
 FntXSize:=8;
 FntYSize:=8;
 ClearScreen;
 PalSize:=262144;
end;

Destructor TMode13Video.Done;
Begin
 Inherited Done;
 ASM  (* Return to original video mode *)
   LES DI, [Self]
   XOR AH, AH
   MOV AL, ES:[DI].OldVideo
   INT 10h
 end;
end;

Procedure TMode13Video.ClearScreen; Assembler;
ASM
 LES DI, [Self]                ; (* Load a pointer to the object *)
 MOV AL, ES:[DI].BackColor     ; (* Move value of BackColor  *)
 MOV AH, AL                    ; (* BackColor in AL and AH   *)
 MOV ES, [SegA000]             ; (* Get Video Segment        *)
 XOR DI, DI                    ; (* Offset is set to 000     *)
 MOV CX, 32000                 ; (* Mov Loop count in CX     *)
 REP STOSW                     ; (* MOVE AL at ES:[DI]for scr   *)
end;

Procedure TMode13Video.GotoXY(Const X,Y: Integer);
Begin
 CurX:=X;
 CurY:=Y;
end;

Procedure TMode13Video.SetColor(Color: Byte);
Begin
 CurColor:=Color;
End;

Procedure TMode13Video.SetBkColor(Color: Word);
Begin
 BackColor:=Color;
end;


Procedure TMode13Video.PutPixel(Const X,Y: Integer; Const Color: Byte); Assembler;
(* No range checking in regards to viewport *)
ASM
(* Calculate global coordinates from virtual coordinates *)
  LES SI, [Self]
  MOV AX, ES:[SI].ViewY1
  ADD AX, [Y]
  MOV DI, ES:[SI].ViewX1
  ADD DI, [X]
(* End Calculation of Global coordinates                  *)
  MOV ES, [SegA000]            ; (* Get Video Segment            *)
  XCHG AH, AL                  ; (* The value of Y must be in AH *)
  ADD DI, AX
  SHR AX, 1
  SHR AX, 1
  ADD DI, AX
  MOV AL, Color
  CBW
  MOV ES:[DI], AL              ; (* Faster then a SINGLE STOSB on 8086 *)
end;

Procedure TMode13Video.SetPalette(Const Color: Byte; Const Red, Green, Blue: DByte);Assembler;
ASM
 MOV DX, 03c8h
 MOV AL, Color                 ; (* Put port index in AX          *)
 OUT DX, AL                    ; (* Output AX immediately to port *)
 MOV DX, 03c9h
 MOV AL, Red                   ; (* Move Red Value into Accumulator *)
 OUT DX, AL                    ; (* Output Red Value to port      *)
 MOV AL, Green                 ; (* Mode Green Value into Accumul *)
 OUT DX, AL                    ; (* Output Green Value to port    *)
 MOV AL, Blue                  ; (* Put Blue value into Accumulator *)
 OUT DX, AL                    ; (* Ouput Blue value to port      *)
end;


Function  TMode13Video.GetPixel(Const X,Y: Integer): Integer; Assembler;
ASM
(* Calculate global coordinates from virtual coordinates *)
  LES SI, [Self]
  MOV AX, ES:[SI].ViewY1
  ADD AX, [Y]
  MOV DI, ES:[SI].ViewX1
  ADD DI, [X]
(* End Calculation of Global coordinates                  *)
  MOV ES, [SegA000]            ; (* Get Video Segment                 *)
  XCHG AH, AL                  ; (* The vluae of Y must be in AH      *)
  ADD DI, AX                   ; (* DI points to the correct vid offset *)
  SHR AX, 1                    ; (* On 286 faster by 1 cycle then Imm8 *)
  SHR AX, 1
  ADD DI, AX
  LODSB                        ; (* On 8086/286 this is faster thrn MOV *)
end;

Procedure TMode13Video.SetWriteMode(WriteMode: Integer);
Begin
 If WriteMode in [AndPut, XorPut, MovPut, OrPut, CopyPut, NotPut] then
  CurWriteMode := WriteMode;
end;

Procedure TMode13Video.GetBitmap(var Image; X, Y, Width, Height: Integer);Assembler;
(* NO RANGE CHECKING IS PERFORMED *)
(* POSSIBLE OPTIMIZATIONS: Applies also to Drawbitmap routine
           - In the loop calculations can be done faster using other math. equations ?
           - MOVSW if offsets are even
*)
ASM
 PUSH DS                       ; (* Save Data Segment State             *)
 MOV DS, [SegA000]             ; (* DS Points to Video Segment          *)
 LES DI, [Image]               ; (* Load Full pointer to the Image Var  *)
 MOV BX, [Height]              ; (* Get Height Of Bitmap -> BX Register *)
 MOV WORD PTR ES:[DI+2], BX    ; (* BX Contains the height of the bitmap*)
 MOV WORD PTR ES:[DI+4], 00h   ; (* Fill Reserved Word with Zero        *)
  (* Calculate the starting memory offset *)
  XOR AX, AX
  MOV CX, [Y]                  ; (* CX:= YPos                           *)
  MOV AH, CL                   ; (* AX:= CX                             *)
  MOV SI, [X]                  ; (* SI:= XPos                           *)
  ADD SI, AX                   ; (* SI:= AX+SI                          *)
  SHR AX, 1                    ; (* Faster on 286/XT machines           *)
  SHR AX, 1
 ADD SI, AX                    ; (* SI:= AX+SI                          *)
 MOV DX, SI                    ; (* Copy of the SI Pointer              *)
 MOV AX, [Width]               ; (* AX Contains the Width of the Bitmap *)
 MOV WORD PTR ES:[DI], AX
 ADD DI, 5                     ; (* We do not care about 6 first bytes  *)
 CLD                           ; (* Clear the direction flag INC SI/DI  *)
@ALoop:                        ; (* Move Screen Data loop               *)
 MOV CX, AX
 REP MOVSB
 SUB SI, AX                    ; (* OPTIMIZATION IS POSSIBLE            *)
 ADD SI, 320                   ; (* Calculate new screen offset         *)
 DEC BX                        ; (* Height = Height - 1                 *)
 JNZ @Aloop
 POP DS
end;

Procedure TMode13Video.DrawBitmap(Var Image; XPos, YPos: Integer); Assembler;
(* NO RANGE CHECKING IS PERFORMED *)
(* PRACTICALLY THE SAME ROUTINE AS GETBITMAP *)
ASM
 PUSH DS                       ; (* Save Data Segment State             *)
 MOV ES, [SegA000]             ; (* ES Points to Video Segment          *)
 LDS SI, [Image]               ; (* Load Full pointer to the Image Var  *)
 MOV BX, WORD PTR DS:[SI+2]    ; (* BX Contains the height of the bitmap*)
 (* Calculate the starting memory offset *)
  XOR AX, AX
  MOV CX, [YPos]               ; (* CX:= YPos                           *)
  MOV AH, CL                   ; (* AX:= CX                             *)
  MOV DI, [XPos]               ; (* DI:= XPos                           *)
  ADD DI, AX                   ; (* DI:= AX+DI                          *)
  SHR AX, 1                    ; (* Faster on 286/86 machines           *)
  SHR AX, 1
 ADD DI, AX                    ; (* DI:= AX+DI                          *)
 MOV DX, DI                    ; (* Copy of the DI Pointer              *)
 MOV AX, WORD PTR [DS:SI]      ; (* AX Contains the width of the bitmap *)
 INC AX                        ; (* Width:= Width + 1                   *)
 ADD SI, 5                     ; (* We do not care about 6 first bytes  *)
 CLD                           ; (* Clear the direction flag INC SI/DI  *)
@ALoop:                        ; (* Move Screen Data loop               *)
 MOV CX, AX
 REP MOVSB
 SUB DI, AX                    ; (* OPTIMIZATION IS POSSIBLE            *)
 ADD DI, 320                   ; (* Calculate new screen offset         *)
 DEC BX                        ; (* Height = Height - 1                 *)
 JNZ @Aloop
 POP DS
end;

Procedure TMode13Video.DrawSprite(Var Image; XPos, YPos: Integer); Assembler;
(* NO RANGE CHECKING IS PERFORMED *)
ASM
 PUSH DS                       ; (* Save Data Segment State             *)
 MOV ES, [SegA000]             ; (* ES Points to Video Segment          *)
 LDS SI, [Image]               ; (* Load Full pointer to the Image Var  *)
 MOV BX, WORD PTR DS:[SI+2]    ; (* BX Contains the height of the bitmap*)
  (* Calculate the starting memory offset *)
 XOR AX, AX
 MOV CX, [YPos]               ; (* CX:= YPos                           *)
 MOV AH, CL                   ; (* AX:= CX                             *)
 MOV DI, [XPos]               ; (* DI:= XPos                           *)
 ADD DI, AX                   ; (* DI:= AX+DI                          *)
 SHR AX, 1                     ; (* Faster on 86/286 machines          *)
 SHR AX, 1
 ADD DI, AX                    ; (* DI:= AX+DI                          *)
 MOV DX, DI                    ; (* Copy of the DI Pointer              *)
 CLD                           ; (* Clear the direction flag INC SI/DI  *)
 MOV DX, WORD PTR [DS:SI]      ; (* DX Contains the width of the sprite *)
 INC DX                        ; (* Width := Width+1                    *)
 ADD SI, 6                     ; (* We do not care about 6 first bytes  *)
 LDS SI, [Self]                ; (* Point to Object Instance            *)
 MOV AH, DS:[SI].SpriteColor   ; (* Get Current Sprite Color            *)
@LoopZero:
 MOV CX, DX                    ; (* Repeat Width times                  *)
@ALoop:                        ; (* Move Screen Data loop               *)
 LODSB                         ; (* Get Data From DS:[SI] - Advance SI  *)
 CMP AL,AH                     ; (* CMP WITH COLOR - IN THIS CASE COLOR0*)
 JZ @SpriteColor
 MOV ES:[DI], AL               ; (* DATA is not spr color, Move it      *)
@SpriteColor:
 INC DI                        ; (* Increment Offset in ALL Cases       *)
 Loop @ALoop
 SUB DI, DX                    ; (* OPTIMIZATION IS POSSIBLE            *)
 ADD DI, 320                   ; (* Calculate new screen offset         *)
 DEC BX                        ; (* Height = Height - 1                 *)
 JNZ @loopZero
 POP DS
end;


Procedure TMode13Video.Bar(X1,Y1,X2,Y2:Integer);Assembler;
(* ABSOLUTELY NO RANGE CHECKING *)
(* 35% faster with an even width *)
ASM
 MOV AX, 320
 MOV CX, [Y1]
 MOV DX, [Y2]
 SUB DX, CX                    ; (* DX (Height) = DX-CX        *)
 MUL CL                        ; (* AX =  CL*AX                *)
 ADD AX, [X1]                  ; (* Start Memory Offset Of Video Screen *)
 MOV DI, AX                    ; (* DI Points to Memory Offset          *)
 MOV AX, [X1]
 MOV BX, [X2]
 SUB BX, AX                    ; (* BX (Width) = BX-AX         *)
 INC BX                        ; (* Width:= Width+1            *)
 LES SI, [Self]
 MOV AL, ES:[SI].CurColor      ; (* Get current drawing color  *)
 MOV ES, [SegA000]             ; (* ES Points to Video Segment *)
 CLD                           ; (* Clear the direction flag INC SI/DI  *)
@ALoop:                        ; (* Move Screen Data loop               *)
 MOV CX, BX
 REP STOSB                     ; (* Store String Word to Memory (ES:DI) *)
 SUB DI, BX                    ; (* OPTIMIZATION IS POSSIBLE            *)
 ADD DI, 320                   ; (* Calculate new screen offset         *)
 DEC DL                        ; (* Height = Height - 1                 *)
 JNZ @Aloop
end;


Procedure TMode13Video.Line(X1,Y1,X2,Y2: Integer);
var
  i : Word;
  deltax: Integer;
  deltay: Integer;
  numpixels: Integer;
  d: Integer;
  dinc1: Integer;
  dinc2: Integer;
  x : Integer;
  xinc1: Shortint;  (* Values -1, 0 , 1 *)   (* BH *)
  xinc2: Shortint;  (* Values -1, 0 , 1 *)   (* DH *)
  y: Integer;
  yinc1: Shortint;  (* Values -1, 0 , 1 *)   (* DL *)
  yinc2: Shortint;  (* Values -1, 0 , 1 *)   (* CL *)
begin
  (* Calculate Real coordinates relative from viewport *)
  X1:=ViewX1+X1;
  X2:=ViewX1+X2;
  Y1:=ViewY1+Y1;
  Y2:=ViewY1+Y2;
  (* end calculation of real coordinates              *)
{$IFOPT R+}
  (* Check if coordinates are within bounds *)
  If (X1 > MaxX) or (X2 > MaxX) or (Y1 > MaxY) or (Y2 > MaxY) then
   RunError(211);
{$ENDIF}
  { Calculate deltax and deltay for initialisation }
  deltax := abs(x2 - x1);
  deltay := abs(y2 - y1);
  { Initialize all vars based on which is the independent variable }
  if deltax >= deltay then
    begin
      { x is independent variable }
      numpixels := deltax + 1;
      d := deltay shl 2 - deltax;
      dinc1 := deltay Shl 1;
      dinc2 := (deltay - deltax) shl 1;
      xinc1 := 1;
      xinc2 := 1;
      yinc1 := 0;
      yinc2 := 1;
    end
  else
    begin
      { y is independent variable }
      numpixels := deltay + 1;
{      d := (2 * deltax) - deltay;}
       d:= deltax shl 2 - deltay;
      dinc1 := deltax Shl 1;
      dinc2 := (deltax - deltay) shl 1;
      xinc1 := 0;
      xinc2 := 1;
      yinc1 := 1;
      yinc2 := 1;
    end;
  { Make sure x and y move in the right directions }
  if x1 > x2 then
    begin
      xinc1 := - xinc1;
      xinc2 := - xinc2;
    end;
  if y1 > y2 then
    begin
      yinc1 := - yinc1;
      yinc2 := - yinc2;
    end;
  { Start drawing at <x1, y1> }
  x := x1;
  y := y1;
  { Draw the pixels }
  for i := 1 to numpixels do
    begin
  (* Putpixel routine *)
  ASM
    XOR AX, AX
    LES DI, [Self]
    MOV CH, ES:[DI].Curcolor
    MOV ES, [SegA000]
    MOV BX, [Y]
    MOV AH, BL
    MOV DI, [X]
    ADD DI, AX
    SHR AX, 1                  ; (* Faster on 86/286 machines   *)
    SHR AX, 1
    ADD DI, AX
    MOV AL, CH
    CBW
    MOV ES:[DI], AL            ; (* Send Color to screen memory *)
 (* End putpixel *)
     end;
      if d < 0 then
        begin
          d := d + dinc1;
          x := x + xinc1;
          y := y + yinc1;
        end
      else
        begin
          d := d + dinc2;
          x := x + xinc2;
          y := y + yinc2;
        end;
    end;
end;


Procedure TMode13Video.Circle(X, Y: Integer; Radius:Word);
Var
   Xs, Ys    : Integer;
   Da, Db, S : Integer;
Begin
(* Convert viewport coordinates to global coordinates *)
     X:=ViewX1+X;
     Y:=ViewY1+Y;
(* Check if global coordinates are within bounds *)
{$IFOPT R+}
  If (X > MaxX) or (Y > MaxY) then
   RunError(211);
{$ENDIF}
     if (Radius = 0) then
          Exit;
     if (Radius = 1) then
     begin
          PutPixel(X, Y, CurColor);
          Exit;
     end;
     Xs := 0;
     Ys := Radius;
     Repeat
           Da := Sqr(Xs+1) + Sqr(Ys) - Sqr(Radius);
           Db := Sqr(Xs+1) + Sqr(Ys - 1) - Sqr(Radius);
           S  := Da + Db;
           Xs := Xs+1;
           if (S > 0) then
                Ys := Ys - 1;
           PutPixel(X+Xs-1, Y-Ys+1, CurColor);
           PutPixel(X-Xs+1, Y-Ys+1, CurColor);
           PutPixel(X+Ys-1, Y-Xs+1, CurColor);
           PutPixel(X-Ys+1, Y-Xs+1, CurColor);
           PutPixel(X+Xs-1, Y+Ys-1, CurColor);
           PutPixel(X-Xs+1, Y+Ys-1, CurColor);
           PutPixel(X+Ys-1, Y+Xs-1, CurColor);
           PutPixel(X-Ys+1, Y+Xs-1, CurColor);
     Until (Xs >= Ys);
end;

Procedure TMode13Video.Rectangle(X1, Y1, X2, Y2: Integer);
Var
 Width: Word;
 Height: Word;
 i: Word;
 Color: Byte;
Begin
(* Calculate real coordinates from virtual coordinates *)
 X1:=ViewX1+X1;
 X2:=ViewX1+X2;
 Y1:=ViewY1+Y1;
 Y2:=ViewY1+Y2;
(* check if global coordinates are within bounds       *)
{$IFOPT R+}
  If (X1 > MaxX) or (X2 > MaxX) or (Y1 > MaxY) or (Y2 > MaxY) then
   RunError(211);
{$ENDIF}
{$ifopt R+}
 Width := abs(X2-X1);
 Height:= abs(Y2-Y1);
{$endif}
{$ifopt R-}
 Width := X2-X1;
 Height:= Y2-Y1;
{$endif}
 Color:=CurColor;
 For i:=0 to Width do
 Begin
(*   PutPixel(X1+i, Y1, CurColor); *)
  ASM
  XOR AX, AX
  MOV ES, [SegA000]
  MOV BX, [Y1]
  MOV AH, BL
  MOV DI, [X1]
  ADD DI, AX
  ADD DI, [i]
{$IFDEF i386}
  SHR AX, 2
{$ELSE}
  SHR AX, 1
  SHR AX, 1
{$ENDIF}
  ADD DI, AX
  MOV AL, Color
  CBW
  MOV ES:[DI], AL              ; (* Faster then STOSB on 8086 CPU's *)
(* end putpixel *)
(*   PutPixel(X1+i,Y2, CurColor); *)
  XOR AX, AX                   ; (* AX := 0              *)
  MOV BX, [Y2]
  MOV AH, BL
  MOV DI, [X1]
  ADD DI, AX
  ADD DI, [i]
{$IFDEF i386}
  SHR AX, 2
{$ELSE}
  SHR AX, 1
  SHR AX, 1
{$ENDIF}
  ADD DI, AX
  MOV AL, Color
  CBW
  MOV ES:[DI],AL               ; (* Faster then STOSB on 8086 CPU's *)
(* end putpixel *)
  end;
 end;
 For i:=0 to Height do
 Begin
  ASM
(*   PutPixel(X1, Y1+i, CurColor); *)
{  MOV ES, [SegA000] SEGMENT ES IS CONSERVED DURING ROUTINE DO NOT RELOAD *)}
  XOR AX, AX
  MOV BX, [Y1]
  ADD BX, [i]
  MOV AH, BL
  MOV DI, [X1]
  ADD DI, AX
  SHR AX, 1                    ; (* Faster on 286/86 machines  *)
  SHR AX, 1
  ADD DI, AX
  MOV AL, Color
  CBW
  MOV ES:[DI], AL              ; (* Faster then STOSB on 8086 CPU's *)
(* end Putpixel *)
(*   PutPixel(X2,Y1+i, CurColor); *)
  XOR AX, AX                   ; (* AX := 0              *)
  MOV BX, [Y1]
  ADD BX, [i]
  MOV AH, BL
  MOV DI, [X2]
  ADD DI, AX
  SHR AX, 1
  SHR AX, 1
  ADD DI, AX
  MOV AL, Color
  CBW
  MOV ES:[DI], AL              ; (* Faster then STOSB on 8086 CPU's *)
(* end putpixel *)
  end;
 end;
End;


Procedure TMode13Video.CopyToScreen(Image: Pointer); Assembler;
(* Copies 64000 bytes from Image Ptr to Video Screen *)
ASM
 PUSH DS
 LDS SI, [Image]
 MOV ES, [SegA000]
 XOR DI, DI
 MOV CX, 32000
 REP MOVSW
 POP DS
end;


Procedure TMode13Video.SetViewPort(X1,Y1,X2,Y2:Integer);
Begin
{$IFOPT R+}
(* If range checking on, check if within screen bounds *)
(* Call Error procedure Instead of RunError(211) to finish *)
 If (X1 > MaxX) or (X2 > MaxX) then
  RunError(211);
 If (Y1 > MaxY) or (Y2 > MaxY) then
  RunError(211);
 If (X1 > X2) or (Y1 > Y2) then
  RunError(211);
{$ENDIF}
 ViewX1:=X1;
 ViewY1:=Y1;
 ViewWidth:= X2-X1;
 ViewHeight:= Y2-Y1;
 (* Pre-calculate start address of Viewport *)
 (* ViewStart:=320*Y1+X1;                   *)
 (* I don't like mul's                      *)
 ASM
  LES SI, [Self]
  XOR AX, AX                   ; (* AX := 0                   *)
  MOV BX, [Y1]
  MOV AH, BL
  MOV DI, [X1]
  ADD DI, AX
  SHR AX, 1
  SHR AX, 1
  ADD DI, AX                   ; (* DI Points to correct vid offset *)
  MOV ES:[SI].ViewStart, DI
 end;
end;

Procedure TMode13Video.ClearViewPort; Assembler;
ASM
  LES SI, [Self]
  MOV DI, ES:[SI].ViewStart     ;(* Video Offset where start of viewport *)
  MOV DX, ES:[SI].ViewHeight   ; (* DX = Height of Viewport         *)
  MOV BX, ES:[SI].ViewWidth    ; (* BX = Width of viewport          *)
  INC BX                        ; (* Width:= Width+1                *)
  MOV AL, ES:[SI].BackColor     ; (* Get current drawing color  *)
  MOV ES, [SegA000]             ; (* ES Points to Video Segment *)
  CLD                           ; (* Clear the direction flag INC SI/DI  *)
@ALoop:                         ; (* Move Screen Data loop               *)
  MOV CX, BX
  REP STOSB                     ; (* Store String Word to Memory (ES:DI) *)
  SUB DI, BX                    ; (* OPTIMIZATION IS POSSIBLE            *)
  ADD DI, 320                   ; (* Calculate new screen offset         *)
  DEC DL                        ; (* Height = Height - 1                 *)
  JNZ @Aloop
end;

Procedure TMode13Video.WriteXY(X,Y: Integer; S: String); Assembler;
ASM

end;

end.