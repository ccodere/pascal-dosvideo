{************************************************}
{                                                }
{   Interrupt Video Routines                     }
{   Copyright 1995 by Carl Eric Codre.          }
{   Montral, Canada                             }
{                                                }
{************************************************}
(* BGI Video routines, supports the modes, as defined in the documentation *)

Uses VideoObj, Graph;





Type
PBGIVideo = ^TBGIVideo;
TBGIVideo = Object(TVideo)
    Constructor Init(Var AMode: Integer);
    Destructor Done; Virtual;
    Procedure Error(S:String);
end;

procedure ATTDriverProc; external;
{$L ATT.OBJ }

procedure CgaDriverProc; external;
{$L CGA.OBJ }

procedure EgaVgaDriverProc; external;
{$L EGAVGA.OBJ }

procedure HercDriverProc; external;
{$L HERC.OBJ }

procedure PC3270DriverProc; external;
{$L PC3270.OBJ }

procedure Vesa16DriverProc; external;
{$L VESA16.OBJ }

procedure IBM8514DriverProc; external;
{$L IBM8514.OBJ }


Constructor TBGIVideo.Init(var AMode: Integer);
{ Amode possible values }
{ PREFIX (High Word)
   $00 - CGA
   $01 - EGA
   $02 - VGA
   $03 - VESA
   $04 - MCGA
   $05 - HERC
   $06 - EGA64
   $07 - EGA-MONO
   $08 - ATT400
   $09 - PC3270
   $10 - IBM8514
   $0000 - AUTO-DETECT
     CurrentDriver ณ   -128/For GetModeRange
     Detect        ณ   0/Requests autodetection
     CGA           ณ   1
     MCGA          ณ   2
     EGA           ณ   3
     EGA64         ณ   4
     EGAMono       ณ   5
     IBM8514       ณ   6
     HercMono      ณ   7
     ATT400        ณ   8
     VGA           ณ   9
     PC3270        ณ  10

Constant   ณ Value ณ Meaning       Constant  ณ Value ณ Meaning
อออออออออออุอออออออุอออออออออออ   อออออออออออุอออออออุออออออออออออ
           ณ       ณ                         ณ       ณ
CGAC0  $04 ณ   0   ณ 320 x 200     EGALo     ณ   0   ณ 640 x 200
CGAC       ณ   1   ณ 320 x 200     EGAHi     ณ   1   ณ 640 x 350
CGAC2      ณ   2   ณ 320 x 200               ณ       ณ
CGAC3      ณ   3   ณ 320 x 200     EGA64Lo   ณ   0   ณ 640 x 200
CGAHi  $06 ณ   4   ณ 640 x 200     EGA64Hi   ณ   1   ณ 640 x 350
           ณ       ณ                         ณ       ณ
MCGAC0 $04 ณ   0   ณ 320 x 200     ATT400C0  ณ   0   ณ 320 x 200
MCGAC1     ณ   1   ณ 320 x 200     ATT400C1  ณ   1   ณ 320 x 200
MCGAC2     ณ   2   ณ 320 x 200     ATT400C2  ณ   2   ณ 320 x 200
MCGAC3     ณ   3   ณ 320 x 200     ATT400C3  ณ   3   ณ 320 x 200
MCGAMed    ณ   4   ณ 640 x 200     ATT400Med ณ   4   ณ 640 x 200
MCGAHi     ณ   5   ณ 640 x 480     ATT400Hi  ณ   5   ณ 640 x 400
           ณ       ณ                         ณ       ณ
EGAMonoHi  ณ   3   ณ 640 x 350     IBM8514Lo ณ   0   ณ 640 x 480
HercMonoHi ณ   0   ณ 720 x 348     IBM8514Hi ณ   1   ณ 1024 x 768
           ณ       ณ                         ณ       ณ
VGALo      ณ   0   ณ 640 x 200     PC3270Hi  ณ   0   ณ 720 x 350
VGAMed     ณ   1   ณ 640 x 350     VGAHi     ณ   2   ณ 640 x 480 }
Var
 grDriver: Integer;
 grMode: Integer;
 Vesa16: Integer;
Begin
 Inherited Init(Amode);
 { INSTALL VESA16 DRIVER }
 Vesa16:=InstallUserDriver('VESA16',Nil);
(* Register all possible drivers *)
 If RegisterBGIDriver(@ATTDriverProc) < 0 then
  Error('Error Registering Driver');
 If RegisterBGIDriver(@CGADriverProc) < 0 then
  Error('Error Registering Driver');
 If RegisterBGIDriver(@HercDriverProc) < 0 then
  Error('Error Registering Driver');
 If RegisterBGIDriver(@EGAVGADriverProc) < 0 then
  Error('Error Registering Driver');
 If RegisterBGIDriver(@PC3270DriverProc) < 0 then
  Error('Error Registering Driver');
 If RegisterBGIDriver(@Vesa16DriverProc) < 0 then
  Error('Error Registering Driver');
 If RegisterBGIDriver(@IBM8514DriverProc) < 0 then
  Error('Error Registering Driver');
 Case AMode of
 VidCGALo: Begin
            grDriver:=CGA;           { $04   320x200x4c PALETTE 0 }
            grMode  :=CGAC0;
           end;
 VidCGAHi: Begin
            grDriver:=CGA;
            grMode  :=CGAHi;
           end;
 VidEGALo: Begin
            grDriver:=EGA;
            grMode  :=EGALo;
           end;
 VidEGAHi: Begin
            grDriver:=EGA;
            grMode  :=EGAHi;
           end;
 VidVGALo: Begin
            grDriver:=VGA;
            grMode  :=VGALo;
           end;
 VidVGAMed: Begin
             grDriver:=VGA;
             grMode:=VGAMed;
           end;
 VidVGAHi: Begin
             grDriver:=VGA;
             grMode:=VGAHi;
           end;
 VidHercHi: Begin
             grDriver:=HercMono;
             grMode:=HercMonoHi;
            end;
 VidEGAMonoHi:
              Begin
               grDriver:=EGAMono;
               GrMode:=EGAMonoHi;
              end;
 VidMCGALo: Begin
               grDriver:=MCGA;
               grMode:=MCGAC0;
            end;
 VidMCGAMed: Begin
               grDriver:=MCGA;
               grMode:=MCGAMed;
             end;
  VidMCGAHI: Begin
               grDriver:=MCGA;
               grMode:=MCGAHi;
             end;
  VidVESALo: Begin
              grDriver:=VESA16;
              grMode:=VESALo;
             end;
  VidVESAMed: Begin
               grDriver:=VESA;
               grMode:=VESAHi;
              end;
 VidVESAHi:  Begin
              grDriver := VESA;
              grMode := VESAHi;
             end;
  InitGraph
 { Extended / undocumented modes - used in these routines }
 VidX320x240, VidX320x200, VidX320x400: Error('Unsupported');
end;


Procedure TBGIVideo.GotoXY(X,Y: Integer);
Begin
 MoveTo(X,Y);
end;

Procedure TBGIVideo.PutPixel(X,Y: Integer; Color: Byte);
Begin
 PutPixel(X,Y, Word(Color));
end;


Function  TBGIVideo.GetPixel(X,Y: Integer): Byte;
Begin
 GetPixel := Byte(GetPixel(X,Y));
end;


Procedure TBGIVideo.ClearScreen;
Begin
 ClearDevice;
end;


(* Page flipping routines *)
(* EGA/VGA Modes only     *)

    Procedure CopyPage(SourcePage, DestPage: Byte); Virtual;


    Procedure DisplayPage(PageNo: Byte); Virtual;
    Procedure SetActivePage(PageNo: Byte); Virtual;

(* Bitmap/sprite routines *)
(* SAME CONVENTION AS IN BORLAND PASCAL FOR BITMAPS/SPRITES *)
{
    Offset      SIZE      Information
    0           Word      Width  of Image
    2           Word      Height of Image
    4           Word      Reserved
    }
    Procedure GetBitmap(var Image; X,Y,Width,Height: Integer); Virtual;
    Procedure DrawBitmap(Var Image; XPos,YPos: Integer); Virtual;
    Procedure DrawSprite(Var Image;XPos, YPos: Integer); Virtual;
    Procedure CopyBitmap(SourcePage,X1,Y1,X2,Y2,DestPage,DestX1,DestY1: Integer); Virtual;
    (* This color will be invisible *)
    Procedure SetSprColor(Color: Byte);

    Procedure SetPalette(ColorNum: Word; Color: ShortInt);
    (* Sets current drawing color *)
    Procedure SetColor(Color: Byte); Virtual;
    Procedure SetBkColor(Color: Word); Virtual;

    Procedure SetWriteMode(WriteMode: Integer); Virtual;


    (* Uses current drawing color set by SetColor *)
    Procedure Bar(X1,Y1,X2,Y2:Integer); Virtual;
    Procedure Circle(X,Y: Integer; Radius: Word); Virtual;
    Procedure Rectangle(X1,Y1,X2,Y2: Integer); Virtual;
    Procedure Line(X1, Y1,X2, Y2: Integer); Virtual;
(*    Procedure FillCircle(X,Y: Integer; Radius: Word); Virtual; *)

(* String/Character routines *)


(* Viewport routines  *)
Procedure TBGIVideo.SetViewPort(X1, Y1, X2, Y2: Integer);
Begin
 SetViewPort(X1, Y1, X2, Y2);
end

Procedure TBGIVideo.ClearviewPort;
Begin
 ClearViewPort;
end;




end.
