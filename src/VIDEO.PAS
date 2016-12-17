
Uses Dos,Crt,Objects,Graph;
 (*    컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴      *)
 (* *   CGA/EGA/VGA Full video routines                                * *)
 (* *    - Object oriented routines (all created from TVideo)          * *)
 (* *    - Where possible High level language has been used            * *)
 (* *     to simplify understanding.                                   * *)
 (*    컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴      *)
 (* *  The Following people I am grateful to:                          * *)
 (* *    SWAG Support Team - Your group is extraordinary, it is        * *)
 (* *     great to see all the people that are still interested        * *)
 (* *     in Turbo Pascal (just like me!).                             * *)
 (* *     - Optimized Putpixel routines                                * *)
 (* *     - Mode-X information, bitmap manipulation examples           * *)
 (* *    Michael Abrash - For his wonderful articles about the         * *)
 (* *     mode-x routines/information in Dr.Dobbs. Also thankful       * *)
 (* *     for texture mapping information                              * *)
 (* *    Sean Palmer - For example code on mode-X (taken from SWAG)    * *)
 (* *    Francis Brown - For an idea on how to use SHL/SHR instead     * *)
 (* *     of muls in Mode-X                                            * *)
 (* *    PCGPE Team - Information on EVERYTHING for EVERYTHING!        * *)
 (* *     - Information on graphic algorithms                          * *)
 (* *     - Information on Mode-X (Robert Schmidt)                     * *)
 (* *    ModeX104.zip Package by Matt pritchard - coding examples      * *)
 (* *    Anivga12.zip Package by Kai brotchard - optimization info.    * *)
 (* *     and coding examples.                                         * *)

 { Conditional defines that are/will be included                         }
 {  R+ - Range Checking,  if on there will be Range checking in proc.    }
 {  G+ - 286 Instructions, if on, optimization will be done using 286+   }
 {        instructions where possible                                    }
 { i386 - 386 Instructions, if on, optimization will be done using 386+  }
 {        instructions in time critical routines only                    }


{ The Following modes will/are supported:                                }
{                                                                        }
{  TCGAVideo   320x200x4c - Palette 1    - 0-3 colors       0 pages      }
{  UNIT CGA    320x200x4c - Palette 2    - 0-3 colors       0 pages      }
{              320x200x4c - Palette 3    - 0-3 colors       0 pages      }
{              640x200x2c    8x8  80x25  - 0-1 colors       0 pages      }
{                                                                        }
{  TEGAVideo   640x200x16c   8x8  80x25  - 0-63 colors      2 pages      }
{  UNIT EGA    640x350x16c   8x14 80x25  - 0-63 colors      2 pages      }
{                                                                        }
{  TVGAVideo   640x480x16c   8x16 80x30  - 0-262144 colors  0 pages      }
{  UNIT VGA    640x350x16c   8x14 80x25  - 0-262144 colors  2 pages      }
{              640x200x16c   8x8  80x25  - 0-262144 colors  2 pages      }
{                                                                        }
{  TEGAXVideo  320x200x16c   8x8  40x25   - 0-63 colors     8 pages      }
{  UNIT EGA                                                              }
{ TMode13Video 320x200x256c  8x8  40x25   - 0-262144 colors 0 pages      }
{  UNIT VGA                                                              }
{  THercules   720x348x2c                 - None            0 pages      }
{  UNIT HERCULES                                                         }

{  TModeXVideo 320x240x256c  8x8  40x30   - 0-262144        3 pages      }
{  UNIT VGA    320x200x256c  8x8  40x25   - 0-262144        4 pages      }
{              320x400x256c  8x16 40x25   - 0-262144        2 pages      }
{                                                                        }
{  VESA/SVGA ONLY                                                        }
{  TModeXtend  640x400x256c  8x16 80x25   - 0-512288        0 pages      }
{                                                                        }
{  TVESAVideo  800x600x16c                                               }
{             1024x768x16c                                               }
{             1280x1024x16c                                              }
{                                                                        }
{              320x200x32768c                                            }
{  UNIT VESA                                                             }
{                                                                        }
{                                                                        }
{                                                                        }
{                                                                        }
{                                                                        }



{  History of the program starting from Version 1.1
  $  = Bug Fix
  +  = Added Feature
  -  = Removed Feature

Version 1.1 (12 May 1995)
  + - Added 320x240x256c routines
  $ - Removed bug from Putpixel routines in mode 13h
  $ - Removed bug in ClearScreen routine for Mode-X
Version 1.2 (14 May 1995)
  + - Optimization for all port access, done in a word instead of
      selecting byte index and then writing data. Now:
       Port[PortIndex]:=ValueAtPort+1 (Byte) + RequiredIndex (Byte)
  + - Added copypage feature
  + - Converted Mode-X putpixel routine in ASM
Version 1.2a
  + - Optimization of routines in some cases by replacing
      STOSB by MOV ES:[DI],AL (applicable to 8086 only)
  $ - Removed Bug on width for Bar and ClearViewport routines
     (always increase width by 1), also updated Drawbitmap and drawsprite.
  + - Putpixel/Getpixel routine now works with Viewports
  + - Line / Circle routine now works with Viewport
}

(* ERROR CODES for GraphError: *)
(* - 01 - Error/Value out of Range *)

Const
  (* Constants Equates for DetectVideoCard Routine *)
  VidNone      = 0;       (* No graphics Card detected   *)
  VidMDA       = 1;       (* Monochrome Display Adapter  *)
  VidCGA       = 2;       (* Color Graphics Adapter      *)
  VidEGAColor  = 3;       (* EGA Color Card              *)
  VidEGAMono   = 4;       (* EGA Monochrome Card         *)
  VidVGAMono   = 5;       (* VGA Monochrome Card         *)
  VidVGAColor  = 6;       (* VGA Color Card              *)
  VidMCGAColor = 7;       (* MCGA Color Card             *)
  VidMCGAMono  = 8;       (* MCGA Monohrome Card         *)
  VidVESASvga  = 9;       (* VESA SVGA Card              *)
  VidVESAXGA   = 10;      (* VESA XGA  Card              *)


Function DetectVideoCard: Byte;
 (* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 *)
 (* *  FUNCTION DetectVideoCard: Byte                          * *)
 (* *                                                          * *)
 (* *  Returns the type of Display adapter present in the      * *)
 (* *  computer. See VidXXXX constants for returned values.    * *)
 (*    Original Routine by EDWIN CALIMBO                         *)
 (*    Some parts rewritten by Carl Eric Codere                  *)
 (* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 *)
Var
  code : Byte;
  Regs : Registers;           (* CPU Registers Type    *)
  Buf:Array[1..256] of Byte;  (* Temporary Buffer      *)
begin
  (* Call VESA XGA/SVGA Adapter Installation check *)
  ASM
   MOV AX,4E00h;         (* XGA Installation Check Service # *)
   LEA DI,[Buf];         (* Pointer to Information Buffer    *)
   MOV BX,DS;
   MOV ES,BX;
   INT 10h;
   CMP AX,004Eh;         (* True if XGA is present           *)
   JE @Yes;
   JMP @End;
   @Yes:
    MOV AL,VidVESAXGA;   (* Exit there is an XGA Driver present *)
    RET;
  @End:                  (* SVGA uses the same buffer           *)
    MOV AX,4f00h;            (* SuperVGA Installation Check Service *)
    INT 10h;
    CMP AX,004Fh;            (* Returns true if card detected       *)
    JE @1Yes;
    JMP @AEnd;
  @1Yes:
    MOV AL, VidVESASvga;
    RET;
  @AEnd:
  end;
  Regs.AH := $1A;      (* call VGA Identify Adapter Function *)
  Regs.AL := $00;      (* clear AL to 0...*)
  Intr($10, Regs);     (* call BIOS *)
  If Regs.AL = $1A then
  begin
    Case Regs.BL of
      $00 : DetectVideoCard := VidNONE;       (* no Graphic card *)
      $01 : DetectVideoCard := VidMDA;        (* monochrome *)
      $02 : DetectVideoCard := VidCGA;        (* cga *)
      $04 : DetectVideoCard := VidEGAColor;   (* ega color *)
      $05 : DetectVideoCard := VidEGAMono;    (* ega mono*)
      $07 : DetectVideoCard := VidVGAMono;    (* vga mono *)
      $08 : DetectVideoCard := VidVGAColor;   (* vga color *)
      $0A,
      $0C : DetectVideoCard := VidMCGAColor;  (* mcga color *)
      $0B : DetectVideoCard := VidMCGAMono;   (* mcga mono *)
      Else
        DetectVideoCard := VidCGA
    end
  end
  Else
  begin
    Regs.AH := $12;         (* use another Function service *)
    Regs.BX := $10;         (* BL = $10 means return EGA info *)
    Intr($10, Regs);        (* call BIOS video Function *)
    If Regs.bx <> $10 Then  (* bx unchanged means EGA is not present *)
    begin
      Regs.AH := $12;
      Regs.BL := $10;
      Intr($10, Regs);
      If Regs.BH = 0 Then
        DetectVideoCard := VidEGAColor
      Else
        DetectVideoCard := VidEGAMono
    end
    Else
    begin
      Intr($11, Regs);     (* eguipment determination service *)
      code := (Regs.AL and $30) shr 4;
      If (code = 3) Then
        DetectVideoCard := VidMDA
      Else
        DetectVideoCard := VidCGA
    end
  end
end; (* DetectVideoCard *)


Procedure SetEGAColor(Const Color:Byte; Red, Green, Blue: Byte);
(* Changes to the specified color given an RGB value *)
(* i.e Converts RGB values to 2 bit values *)
(* Color: 0-15 value *)
Var
  i    : Integer;
  regs : Registers;
begin
  red   := red SHR 6;
  green := green SHR 6;
  blue  := blue SHR 6;
  i     := (red SHL 4) + (green SHL 2) + blue;
  regs.AH := $10;
  regs.AL := 0;
  regs.BH := i;
  regs.BL := Color;  { the colour index to change }
  Intr($10, regs);   (* Call Interrupt Function to change color - for compatibility reasons *)
end;




   procedure ToggleBlink(Blink: Boolean; Const VideoCard: Byte);
   (* Toggles blinking characters in intensity background *)
   (* TRUE = if we want blinking characters - Background colors: 0-15 *)
   (* FALSE = we do not want blinking characters - Foreground Colors: 0-7 *)
   var
     regs    : registers;
     port_   : word;
   begin
     if (VideoCard = VidCGA) or  (VideoCard = VidMDA) then begin
       if VideoCard = VidCGA then port_:= $03D8
                        else port_:= $03B8;
       if not Blink then PortW[port_]:= MemW[Seg0040:$0065] and $00DF
                    else PortW[port_]:= MemW[Seg0040:$0065]  or $0020;
     end else
     (* HMMM... Interessant ??? Checking sans de multiples verification separees *)
     if VideoCard in [VidVGAColor,VidEGAColor,VidVGAMono,VidEGAMono] then begin
       if not Blink then regs.bl:= $00
                    else regs.bl:= $01;
       regs.ah:= $10;
       regs.al:= $03;
       intr($10,regs);
     end;
   end;


Type
 DByte = 0..63;      (* Used for RGB Indexes *)

{$I C:\tp\video1.pas}     (* General Object for Video routines *)
{$I C:\tp\vidcga.pas}     (* CGA routines      (BGI)           *)
{$I C:\tp\videga.pas}     (* EGA/VGA Routines  (BGI)           *)
{$I C:\tp\vidher.pas}     (* Hercules routines (BGI)           *)
{$I C:\tp\vidmodx.pas}    (* Mode-X routines                   *)



Const
 Image2:Array[1..31] of Byte =
 (5, 0,
  5, 0,
  0, 0,
   4,  5,  6,  1, 5,
   3, 00, 00, 12, 5,
   3, 00, 00, 12, 5,
   3, 00, 00, 12, 5,
  12, 24, 24, 24, 5);
 Type
  AnImage = Record
   Width: Word;
   Height:Word;
   Reserved:Word;
   Data: Array[1..10000] of Byte;
  end;
Var
 Video:TMode13Video;
 i:Word;
 Mode: Integer;
 j:word;
 Image: AnImage;
 Color: Byte;
   x,y,d:Word;
  r:Real;

Begin
 Randomize;
 Mode:=2;
{ Video.Init(Mode); }
 Video.Init;
  For i:=0 to 199 do
  Begin
   For j:=0 to 319 do
   Begin
     Video.PutPixel(j,i,Color);
   end;
   Inc(color);
  end;
{  Video.SetWritemode(XorPut); }
{  Video.SystemWrite(35,24,2,'Hello!');
  Video.Getbitmap(Image,160,100,100,100);
  Video.SetColor(15);}
  Repeat
   Video.SetColor(Random(255));
   Video.Bar(Random(10),Random(10),Random(100)+10,Random(100)+11);
   Until Keypressed;
(*    Video.ClearScreen; *)
(*  Video.SetColor(3);
(*  Video.GotoXY(100,100); *)
(*  Video.Circle(Video.GetX, Video.GetY,20); *)
 Video.Done;
end.








