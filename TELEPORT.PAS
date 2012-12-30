Program TelegardCallersInPortal;
{---------------------------------------------------------------------------}
{                          .ùúGeneralúInformationúù.                        }
{---------------------------------------------------------------------------}
{

                             North Star Technologies
                       Telegard Callers in Portal of Power
                          Copyright (c) 1997 Jon Parise

Version:  1.2

Description:
    Imports the last few callers in Telegard to Portal's status display.

Legal Notice:
    This source code has been included with this release of TelePort.  You
are free to modify and recompile the source code for your own, personal use.
The modified source code may not be distributed under the existing or new
name.
    The original copyright still belongs to me, Jon Parise.  All future
official releases will only be distributed by me.  Should you make a
significant modification to the source and feel it should be distributed,
please send me your modified code and it will be included in a future release
with full credit for the modification granted to you.
}

Uses  Dos, Crt;

{$I Telegard.Inc}  { Telegard structure definitions }

{---------------------------------------------------------------------------}
{                         .ùúConstantúDeclarationsúù.                       }
{---------------------------------------------------------------------------}
Const
  Product = 'Telegard Callers in Portal of Power';
  Release = '1.2';

  HexId : Array[0..$F] of Char = '0123456789ABCDEF';

{---------------------------------------------------------------------------}
{                           .ùúTypeúDeclarationsúù.                         }
{---------------------------------------------------------------------------}

  { The Portal structures below were taken from PopTypes.Pas released in the
    Portal of Power 0.62 Developer's Kit }

Type
  tFidoAddress = Record
    Zone,
    Net,
    Node,
    Point    : Integer;
   End; { tFidoAddress }

  tEventTimer = Record
    StartTics  : LongInt;
    ExpireTics : LongInt;
   End; { tEventTimer }

  tPortalRec = Record
    Event       : Byte;
    Filler1     : Array[1..14] Of Byte;
    LastRan     : LongInt;
    LastEDate   : LongInt;
    Filler2     : Byte;
    LastEtStart : LongInt;
    Filler3     : Integer;
    Users       : Array[1..5] Of Record
      Name : String[35];
      T    : LongInt;   { Seconds since midnight }
     End;
    UserTime    : LongInt;
    KbdPassword : String[20];
    Filler4     : Array[1..46] Of Byte;
    Calls       : Array[1..2,1..5] Of Record
      Adr  : tFidoAddress;
      Name : String[16];
      T    : LongInt;
     End; { Calls }
    MacroStatus : Boolean;
    Poll        : tFidoAddress;
    LastCalled  : tFidoAddress;
    NextTime    : tEventTimer;
    Filler      : Array[1..408] Of Char;
   End; { tPortalRec }

Type
  tCallers = Record
    Name   : String[35];    { Caller's name (35 chars max) }
    Time   : LongInt;       { Time of call (Unix-style) }
   End; { tCallers }

{---------------------------------------------------------------------------}
{                         .ùúVariableúDeclarationsúù.                       }
{---------------------------------------------------------------------------}

Var
  Callers        : Array[1..5] of tCallers;
  PortalStatus   : tPortalRec;
  TelegardDir    : PathStr;              { Path to Telegard's Data dir }
  PortalDir      : PathStr;              { Path to Portal's main dir }
  Task           : String[2];            { Task num (for Portal??.Dat) }
  J              : Byte;
  {$IfDef Os2}
  Err            : LongInt;
  {$Else}
  Err            : Integer;
  {$EndIf}

{---------------------------------------------------------------------------}
{                         .ùúFunctionúDeclarationsúù.                       }
{---------------------------------------------------------------------------}

{ Detects whether or not Share is installed.  From SWAG, by Lars Hellsten

                                      Sharing Method
Access Method  Compatibility  Deny Write  Deny Read  Deny None
--------------------------------------------------------------
Read Only           0             32          48         64
Write Only          1             33          49         65
Read/Write          2             34          50         66
--------------------------------------------------------------
}

{$IfnDef Os2}
Function ShareInstalled : Boolean;
Var Regs : Registers;

 Begin { ShareInstalled }

  Regs.AH := $16;
  Regs.AL := $00;
  Intr($21, Regs);
  ShareInstalled := (Regs.AL = $FF);

 End; { ShareInstalled }
{$EndIf}

{---------------------------------------------------------------------------}

Function AddBackSlash (S : PathStr) : PathStr;

 Begin
  If S[Length(S)] <> '\' then S := S + '\';
  AddBackSlash := S;
 End;

{---------------------------------------------------------------------------}

{ Converts the Unix datestamp used in Telegard's Laston.Dat file to the
  time formated used by Portal (number of seconds since midnight) }

Function ConvTime (Unix : LongInt) : LongInt;
Var
  Sec  : Word;
  Min  : Word;
  Hour : Word;

 Begin { ConvTime }

   Sec  := Unix mod 60; Unix := Unix div 60;
   Min  := Unix mod 60; Unix := Unix div 60;
   Hour := Unix mod 24;
   ConvTime := Sec + (Min *60) + (Hour * 3600);

 End; { ConvTime }

{---------------------------------------------------------------------------}

Function IntToHex (Num : LongInt; Digits : Byte) : String;
Var
 S : String;
 C : Byte;
 N : Array[1..SizeOf(LongInt)] of Byte Absolute Num;

 Begin { IntToHex }

  S := '';
  For C := 4 DownTo 1 do S := S + HexId[N[C] shr 4] + HexId[n[c] and $F];
  IntToHex := Copy(S,8-Digits+1,Digits);

 End; { IntToHex }

{---------------------------------------------------------------------------}

Function fExist (Fn : PathStr) : Boolean;
Var DirInfo : SearchRec;

 Begin { fExist }

  FindFirst (Fn, Anyfile - Directory - VolumeId, DirInfo);
  FExist := DosError = 0;

 End;  { fExist }


{---------------------------------------------------------------------------}
{                         .ùúProcedureúDeclarationsúù.                      }
{---------------------------------------------------------------------------}

{  Do not change the below copyright information. }
Procedure Copyright;

 Begin { Copyright }

  Writeln;  Writeln;
  TextAttr := LightCyan;
  Writeln (Product + ' v' + Release);
  TextAttr := Cyan;
  Writeln ('Copyright 1997 by Jon Parise.  All rights reserved.');
  TextAttr := DarkGray;
  Writeln ('A North Star Technologies Software Release');
  Writeln;

 End;  { Copyright }

{---------------------------------------------------------------------------}

{ Displays the parameter help screen with examples }
Procedure Help;

 Begin { Help }

  Copyright;
  Writeln;
  TextAttr := White;    Write('     Usage');
  TextAttr := DarkGray; Write(':  ');
  TextAttr := Cyan;     Write('TelePort {Telegard Data Dir} {Portal Dir} [Portal Task]');
  Writeln;  Writeln;
  TextAttr := White;    Write('   Example');
  TextAttr := DarkGray; Write(':  ');
  TextAttr := Cyan;     Write('TelePort D:\Telegard\Data D:\Portal  ');
  Write('  (Writes to Portal.Dat)'); Writeln;
  Write('             ');
  Write('TelePort D:\Telegard\Data D:\Portal 2');
  Write('  (Writes to Portal02.Dat)'); Writeln;
  Writeln;
  Halt (1);

 End;  { Help }

{---------------------------------------------------------------------------}

Procedure ReadTelegardCallers (FileName : String);
Var
  fCallers     : File of LCallers;
  OpenAttempts : Integer;
  GoAhead      : Boolean;
  I            : LongInt;
  TempRec      : LCallers;
  NumCallers   : Byte;

 Begin { ReadTelegardCallers }

  If Not fExist(Filename) then
    Begin
      Writeln;
      Writeln('   ',Filename,' was not found!');
      Halt(3);
    End;
  {$IfnDef Os2} If ShareInstalled then FileMode := 32; {$EndIf}
  Assign(fCallers,FileName);
  OpenAttempts := 1;
  Repeat
    {$I-} Reset(fCallers); {$I+}
    GoAhead := (IOResult = 0);
    If (Not GoAhead) then Inc(OpenAttempts);
  Until (GoAhead) or (OpenAttempts > 1000);

  NumCallers := FileSize(fCallers);

  If NumCallers > 0 then
    Begin
      If NumCallers > 5 then NumCallers := 5;
      Seek(fCallers, FileSize(fCallers) - NumCallers);
      For I := 1 to NumCallers do
        Begin
          Read(fCallers,TempRec);
          Callers[I].Name := TempRec.Handle;
          Callers[I].Time := ConvTime(TempRec.LogonTime);
          { Puts an asterisk in from of the user's name if he/she is new }
          If TempRec.NewUser then Callers[I].Name := '*' + Callers[I].Name;
       End;
    End;

  Close(fCallers);
  {$IfnDef Os2} If ShareInstalled then FileMode := 2; {$EndIf}

 End;  { ReadTelegardCallers }

{---------------------------------------------------------------------------}

Procedure ReadPortalDat (FileName : String);
Var
  fPortal      : File of tPortalRec;
  OpenAttempts : Integer;
  GoAhead      : Boolean;

 Begin { ReadPortalDat }

  If Not fExist(Filename) then
    Begin
      Writeln;
      Writeln('   ',Filename,' was not found!');
      Halt(2);
    End;
  {$IfnDef Os2} If ShareInstalled then FileMode := 32; {$EndIf}
  Assign(fPortal,FileName);
  OpenAttempts := 1;
  Repeat
    {$I-} Reset(fPortal); {$I+}
    GoAhead := (IOResult = 0);
    If (Not GoAhead) then Inc(OpenAttempts);
  Until (GoAhead) or (OpenAttempts > 1000);
  Read (fPortal,PortalStatus);
  Close(fPortal);
  {$IfnDef Os2} If ShareInstalled then FileMode := 2; {$EndIf}

 End;  { ReadPortalDat }

{---------------------------------------------------------------------------}

Procedure WritePortalDat (FileName : String);
Var
  fPortal      : File of tPortalRec;
  OpenAttempts : Integer;
  GoAhead      : Boolean;

 Begin { WritePortalDat }

  {$IfnDef Os2} If ShareInstalled then FileMode := 50; {$EndIf}
  Assign(fPortal,FileName);
  OpenAttempts := 1;
  Repeat
    {$I-} Rewrite(fPortal); {$I+}
    GoAhead := (IOResult = 0);
    If (Not GoAhead) then Inc(OpenAttempts);
  Until (GoAhead) or (OpenAttempts > 1000);
  Write (fPortal,PortalStatus);
  Close(fPortal);
  {$IfnDef Os2} If ShareInstalled then FileMode := 2; {$EndIf}

 End;  { WritePortalDat }

{---------------------------------------------------------------------------}

Procedure ImportIt;
Var I : Byte;

 Begin { ImportIt }

  Copyright;
  TextAttr := Cyan;
  Writeln('Telegard Dir :  ',TelegardDir);
  Writeln('  Portal Dir :  ',PortalDir);
  If Task <> '' then Writeln(' Portal Task :  ',J,' (',Task,')');
  For I := 1 to 5 do
    Begin
      Callers[I].Name := '';
      Callers[I].Time := 0;
    End;
  ReadPortalDat(PortalDir + 'Portal' + Task + '.Dat');
  ReadTelegardCallers(TelegardDir + 'Laston.Dat');
  For I := 1 to 5 do
    Begin
      PortalStatus.Users[I].Name := Callers[I].Name;
      PortalStatus.Users[I].T    := Callers[I].Time;
    End;
  WritePortalDat(PortalDir + 'Portal' + Task + '.Dat');

 End;  { ImportIt }

{---------------------------------------------------------------------------}
{                               .ùúMainúBodyúù.                             }
{---------------------------------------------------------------------------}

Begin { Main }

 If (ParamCount <= 3) and (ParamCount >= 2) then
   Begin
     TelegardDir := AddBackSlash(ParamStr(1));
     PortalDir   := AddBackSlash(ParamStr(2));
     If ParamCount = 3 then
       Begin
         Val(ParamStr(3),J,Err);
         Task := IntToHex(J,2);
         If Length(Task) = 1 then Task := '0' + Task;
         If Task = '00' then Task := '';
       End else Task := '';
   End else Help;

 ImportIt;
 Writeln;
 Writeln('Telegard callers successfully imported into Portal',Task,'.Dat');
 Writeln;

End.  { Main }
