{************************************************}
{                                                }
{   Interrupt Video Routines                     }
{   Copyright 1995 by Carl Eric Cod�re.          }
{   Montr�al, Canada                             }
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
     CurrentDriver �   -128/For GetModeRange
     Detect        �   0/Requests autodetection
     CGA           �   1
     MCGA          �   2
     EGA           �   3
     EGA64         �   4
     EGAMono       �   5
     IBM8514       �   6
     HercMono      �   7
     ATT400        �   8
     VGA           �   9
     PC3270        �  10

Constant   � Value � Meaning       Constant  � Value � Meaning
�������������������������������   ��������������������������������
           �       �                         �       �
CGAC0  $04 �   0   � 320 x 200     EGALo     �   0   � 640 x 200
CGAC       �   1   � 320 x 200     EGAHi     �   1   � 640 x 350
CGAC2      �   2   � 320 x 200               �       �
CGAC3      �   3   � 320 x 200     EGA64Lo   �   0   � 640 x 200
CGAHi  $06 �   4   � 640 x 200     EGA64Hi   �   1   � 640 x 350
           �       �                         �       �
MCGAC0 $04 �   0   � 320 x 200     ATT400C0  �   0   � 320 x 200
MCGAC1     �   1   � 320 x 200     ATT400C1  �   1   � 320 x 200
MCGAC2     �   2   � 320 x 200     ATT400C2  �   2   � 320 x 200
MCGAC3     �   3   � 320 x 200     ATT400C3  �   3   � 320 x 200
MCGAMed    �   4   � 640 x 200     ATT400Med �   4   � 640 x 200
MCGAHi     �   5   � 640 x 480     ATT400Hi  �   5   � 640 x 400
           �       �                         �       �
EGAMonoHi  �   3   � 640 x 350     IBM8514Lo �   0   � 640 x 480
HercMonoHi �   0   � 720 x 348     IBM8514Hi �   1   � 1024 x 768
           �       �                         �       �
VGALo      �   0   � 640 x 200     PC3270Hi  �   0   � 720 x 350
VGAMed     �   1   � 640 x 350     VGAHi     �   2   � 640 x 480 }
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
