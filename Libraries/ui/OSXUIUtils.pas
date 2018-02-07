unit OSXUIUtils;

{
Copyright (c) 2017+, Health Intersections Pty Ltd (http://www.healthintersections.com.au)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 * Neither the name of HL7 nor the names of its contributors may be used to
   endorse or promote products derived from this software without specific
   prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
}
interface

uses
  {$IFDEF MSWINDOWS}
  FMX.Platform.Win, Winapi.Windows, Winapi.ShellAPI, ComObj, ShlObj, ActiveX, FMX.Types;
  {$ENDIF MSWINDOWS}
  {$IFDEF MACOS}
  FMX.Types, Macapi.AppKit, Macapi.Foundation, Macapi.ObjectiveC, Posix.Stdlib;
  {$ENDIF MACOS}

function SelectDirectory(Handle : TWindowHandle; const ATitle: string; const Existing : String; var ADir: string): boolean;
procedure OpenURL(sCommand: string);

implementation

////
//var
//  NewPath: string;
//begin
//  if SelectDirectory('Please select directory...', NewPath) then
//  begin
//    edSearchPath.Text := NewPath;
//  end;

var
  init : PChar;

{$IFDEF MSWINDOWS}
function BI_CallBack_Proc(hwnd: HWND; uMsg: UINT; lParam: DWORD; lpData: DWORD): integer; stdcall;
var
  PathName: array[0..MAX_PATH] of Char;
begin
  case uMsg of
    BFFM_INITIALIZED: SendMessage(Hwnd, BFFM_SETSELECTION, Ord(True), Integer(init));
    BFFM_SELCHANGED:
      begin
      SHGetPathFromIDList(PItemIDList(lParam), @PathName);
      SendMessage(hwnd, BFFM_SETSTATUSTEXT, 0, Longint(PChar(@PathName)));
      end;
  end;
  Result := 0;
end;

{$ENDIF MSWINDOWS}

function SelectDirectory(Handle : TWindowHandle; const ATitle: string; const Existing : String; var ADir: string): boolean;
{$IFDEF MSWINDOWS}
var
  hr: HRESULT;
  FormHandle: THandle;
  IDList: PItemIDList;
  RootIDList: PItemIDList;
  Malloc: IMalloc;
  lpBuf: LPTSTR;
  BI: TBrowseInfo;
  sCaption: string;
begin
  init := PWideChar(existing);
  Result := False;
  FormHandle := FMX.Platform.Win.WindowHandleToPlatform(Handle).Wnd;
  ADir := '';
  if (SHGetMalloc(Malloc) = S_OK) and (Malloc <> nil) then
  begin
    sCaption := ATitle;
    FillChar(BI, SizeOf(BI), 0);
    lpBuf := Malloc.Alloc(MAX_PATH);
    RootIDList := nil;
    SHGetSpecialFolderLocation(FormHandle, CSIDL_DESKTOP, RootIDList);
    with BI do
    begin
      hwndOwner := FormHandle;
      pidlRoot := RootIDList;
      pszDisplayName := lpBuf;
      lpszTitle := PWideChar(sCaption);
      ulFlags := BIF_NEWDIALOGSTYLE or BIF_USENEWUI;
      lpfn := @BI_CallBack_Proc;
      lParam := 0;
      iImage := 0;
    end;
    try
      hr := CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
      if (hr = S_OK) or (hr = S_FALSE) then
      begin
        IDList := SHBrowseForFolder(BI);
        Result := IDList <> nil;
        if Result then
        begin
          SHGetPathFromIDList(IDList, lpBuf);
          ADir := lpBuf;
          Malloc.Free(RootIDList);
          RootIDList := nil;
          Malloc.Free(IDList);
          IDList := nil;
        end;
        CoUnInitialize();
      end;
    finally
      Malloc.Free(lpBuf);
    end;
end;
{$ENDIF MSWINDOWS}
{$IFDEF MACOS}
var
  LOpenDir: NSOpenPanel;
  LInitialDir: NSURL;
  LDlgResult: Integer;
begin
  Result := False;
  LOpenDir := TNSOpenPanel.Wrap(TNSOpenPanel.OCClass.openPanel);
  LOpenDir.setAllowsMultipleSelection(False);
  LOpenDir.setCanChooseFiles(False);
  LOpenDir.setCanChooseDirectories(True);
  if ADir <> '' then
  begin
    LInitialDir := TNSURL.Create;
    LInitialDir.initFileURLWithPath(NSSTR(ADir));
    LOpenDir.setDirectoryURL(LInitialDir);
  end;
  if ATitle <> '' then
    LOpenDir.setTitle(NSSTR(ATitle));
  LOpenDir.retain;
  try
    LDlgResult := LOpenDir.runModal;
    if LDlgResult = NSOKButton then
    begin
      ADir := string(TNSUrl.Wrap(LOpenDir.URLs.objectAtIndex(0)).relativePath.UTF8String);
      Result := True;
    end;
  finally
    LOpenDir.release;
  end;
{$ENDIF MACOS}
end;

procedure OpenURL(sCommand: string);
begin
{$IFDEF MSWINDOWS}
  ShellExecute(0, 'OPEN', PChar(sCommand), '', '', SW_SHOWNORMAL);
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  _system(PAnsiChar('open ' + AnsiString(sCommand)));
{$ENDIF POSIX}
end;

end.
end.
