unit FHIRToolkitForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Platform,
  FMX.Layouts, FMX.ListBox, FMX.TabControl, FMX.Controls.Presentation, FMX.DialogService,
  System.ImageList, FMX.ImgList,
  IniFiles,
  SystemSupport,
  FHIRBase, FHIRTypes, FHIRResources, FHIRClient, FHIRUtilities,
  ServerForm, CapabilityStatementEditor, BaseResourceFrame, BaseFrame;

type

  TMasterToolsForm = class(TForm)
    tbMain: TTabControl;
    Label2: TLabel;
    TabItem1: TTabItem;
    pnlToolbar: TPanel;
    Panel1: TPanel;
    lbServers: TListBox;
    btnConnect: TButton;
    btnAddServer: TButton;
    btnRemoveServer: TButton;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Label1: TLabel;
    lbFiles: TListBox;
    btnReopen: TButton;
    btnRemoveFile: TButton;
    btnOpen: TButton;
    btnNew: TButton;
    ToolBar1: TToolBar;
    tbnNew: TButton;
    tbnOpen: TButton;
    tbnConnect: TButton;
    odFile: TOpenDialog;
    StyleBook1: TStyleBook;
    ToolbarImages: TImageList;
    tbnSave: TButton;
    tbnSaveAs: TButton;
    tbnClose: TButton;
    Timer1: TTimer;
    sdFile: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbServersClick(Sender: TObject);
    procedure lbFilesClick(Sender: TObject);
    procedure btnRemoveServerClick(Sender: TObject);
    procedure btnAddServerClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnReopenClick(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
    procedure tbnSaveClick(Sender: TObject);
    procedure tbnSaveAsClick(Sender: TObject);
    procedure tbnCloseClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnRemoveFileClick(Sender: TObject);
  private
    { Private declarations }
    FIni : TIniFile;

    procedure saveServers;
    procedure saveFiles;
    procedure openResourceFromFile(filename : String; res : TFHIRResource; format : TFHIRFormat; frameClass : TBaseResourceFrameClass);
    procedure addFileToList(filename : String);
    function doSave : boolean;
    function doSaveAs : boolean;
  public
    { Public declarations }
  end;

var
  MasterToolsForm: TMasterToolsForm;

implementation

{$R *.fmx}

procedure TMasterToolsForm.addFileToList(filename: String);
var
  i : integer;
begin
  for i := lbFiles.Count - 1 downto 0 do
    if lbFiles.items[i] = filename then
      lbFiles.Items.Delete(i);
  lbFiles.Items.Insert(0, filename);
  saveFiles;
  lbFilesClick(nil);
end;

procedure TMasterToolsForm.btnAddServerClick(Sender: TObject);
begin
  TDialogService.InputQuery('Server Address', ['URL'], [''],
    procedure(const AResult: TModalResult; const AValues: array of string)
    begin
      if (AResult = mrOK) and (aValues[0] <> '') then
      begin
        lbServers.Items.Insert(0, aValues[0]);
      end;
    end);
end;

procedure TMasterToolsForm.btnConnectClick(Sender: TObject);
var
  client : TFhirHTTPClient;
  tab : TTabItem;
  serverForm : TServerFrame;
  cs : TFhirCapabilityStatement;
  fcs : IFMXCursorService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXCursorService) then
    fcs := TPlatformServices.Current.GetPlatformService(IFMXCursorService) as IFMXCursorService
  else
    fcs := nil;
  if Assigned(fcs) then
  begin
    Cursor := fcs.GetCursor;
    fcs.SetCursor(crHourGlass);
  end;
  try
    client := TFhirHTTPClient.Create(nil, lbServers.Items[lbServers.ItemIndex], false);
    try
      cs := client.conformance(false);
      try
        tab := tbMain.Add(TTabItem);
        tbMain.ActiveTab := tab;
        tab.Text := lbServers.Items[lbServers.ItemIndex];
        serverForm := TServerFrame.create(tab);
        tab.TagObject := serverForm;
        serverForm.TagObject := tab;
        serverForm.Parent := tab;
        serverForm.tabs := tbMain;
        serverForm.Tab := tab;
        serverForm.Align := TAlignLayout.Client;
        serverForm.Client := client.link;
        serverForm.CapabilityStatement := cs.link;
        serverForm.load;
      finally
        cs.free;
      end;
    finally
      client.Free;
    end;
  finally
    if Assigned(fCS) then
      fcs.setCursor(Cursor);
  end;
end;

procedure TMasterToolsForm.btnOpenClick(Sender: TObject);
var
  res : TFhirResource;
  format : TFHIRFormat;
begin
  if odFile.Execute then
  begin
    try
      format := ffUnspecified;
      res := fileToResource(odFile.Filename, format);
      try
        if res is TFhirCapabilityStatement then
          openResourceFromFile(odFile.Filename, res, format, TCapabilityStatementEditorFrame)
        else
          MessageDlg('Unsupported Resource Type: '+res.fhirType, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
      finally
        res.free;
      end;
    except
      on e : Exception do
        MessageDlg('Error reading Resource: '+e.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
    end;
  end;
end;

procedure TMasterToolsForm.btnRemoveFileClick(Sender: TObject);
var
  i : integer;
begin
  i := lbFiles.ItemIndex;
  lbFiles.items.Delete(i);
  if i = lbFiles.items.Count then
    dec(i);
  lbFiles.ItemIndex := i;
  saveFiles;
  lbFilesClick(nil);
end;

procedure TMasterToolsForm.btnRemoveServerClick(Sender: TObject);
var
  i : integer;
begin
  i := lbServers.ItemIndex;
  lbServers.items.Delete(i);
  if i = lbServers.items.Count then
    dec(i);
  lbServers.ItemIndex := i;
  saveServers;
  lbServersClick(nil);
end;

procedure TMasterToolsForm.btnReopenClick(Sender: TObject);
var
  res : TFhirResource;
  fn : String;
  format : TFHIRFormat;
begin
  fn := lbFiles.Items[lbFiles.ItemIndex];
  try
    format := ffUnspecified;
    res := fileToResource(fn, format);
    try
      if res is TFhirCapabilityStatement then
        openResourceFromFile(fn, res, format, TCapabilityStatementEditorFrame)
      else
        MessageDlg('Unsupported Resource Type: '+res.fhirType, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
    finally
      res.free;
    end;
  except
    on e : Exception do
      MessageDlg('Error reading Resource: '+e.Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
  end;
end;

procedure TMasterToolsForm.tbnSaveClick(Sender: TObject);
begin
  doSave;
end;

procedure TMasterToolsForm.tbnSaveAsClick(Sender: TObject);
begin
  doSaveAs;
end;

procedure TMasterToolsForm.tbnCloseClick(Sender: TObject);
var
  i : integer;
  frame : TBaseFrame;
  procedure closeit;
  begin
    i := tbMain.TabIndex;
    tbMain.ActiveTab.Free;
    if i > 0 then
      tbMain.TabIndex := i - 1
    else
      tbMain.TabIndex := 0;
  end;
begin
  frame := tbMain.ActiveTab.TagObject as TBaseFrame;
  if (frame <> nil) then
  begin
    if frame.isDirty then
    begin
      case MessageDlg(tbMain.ActiveTab.Text+' contains unsaved data. Save the data first?', TMsgDlgType.mtConfirmation, mbYesNoCancel, 0) of
        mrYes :
          if doSave then
            closeit;
        mrNo : closeit;
        mrCancel : exit;
      end;
    end
    else
      closeit;
    end;
end;

procedure TMasterToolsForm.CloseButtonClick(Sender: TObject);
begin
  showMessage('duh');
end;

function TMasterToolsForm.doSave: boolean;
var
  frame : TBaseFrame;
  cs : IFMXCursorService;
begin
  result := false;
  frame := tbMain.ActiveTab.TagObject as TBaseFrame;

  if frame <> nil then
  begin
    if frame.canSave then
    begin
      cs := frame.markbusy;
      try
        result := frame.save;
      finally
        frame.markNotBusy(cs);
      end;
    end
    else
      result := doSaveAs;
  end;
end;

function TMasterToolsForm.doSaveAs: boolean;
var
  frame : TBaseFrame;
  cs : IFMXCursorService;
begin
  result := false;
  frame := tbMain.ActiveTab.TagObject as TBaseFrame;

  if frame <> nil then
  begin
    if sdFile.execute then
    begin
      if frame.canSave then
      begin
        cs := frame.markbusy;
        try
          if sdFile.FilterIndex = 0 then
            result := frame.saveAs(sdFile.Filename, ffXml)
          else if sdFile.FilterIndex = 1 then
            result := frame.saveAs(sdFile.Filename, ffJson)
          else if sdFile.FilterIndex = 2 then
            result := frame.saveAs(sdFile.Filename, ffTurtle)
          else
            raise Exception.Create('Unknown format');
          addFileToList(sdFile.FileName);
        finally
          frame.markNotBusy(cs);
        end;
      end
      else
        result := doSaveAs;
    end;
  end;
end;

procedure TMasterToolsForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  dirty : boolean;
  i : integer;
  obj : TBaseFrame;
begin
  dirty := false;
  for i := 1 to tbMain.TabCount - 1 do
  begin
    obj := tbMain.Tabs[i].TagObject as TBaseFrame;
    if (obj.isDirty) then
      dirty := true;
  end;
  if dirty then
    CanClose := false;
end;

procedure TMasterToolsForm.FormCreate(Sender: TObject);
begin
  FIni := TIniFile.Create(IncludeTrailingPathDelimiter(SystemTemp) + 'settings.ini');
  FIni.ReadSection('Servers', lbServers.Items);
  if lbServers.Items.count = 0 then
    lbServers.Items.add('http://test.fhir.org/r3');
  lbServers.ItemIndex := 0;
  lbServersClick(self);
  FIni.ReadSection('Files', lbFiles.Items);
  if lbFiles.Items.count > 0 then
    lbFiles.ItemIndex := 0;
  lbFilesClick(self);
  Left := FIni.ReadInteger('Window', 'left', left);
  Top := FIni.ReadInteger('Window', 'top', top);
  Width := FIni.ReadInteger('Window', 'width', width);
  Height := FIni.ReadInteger('Window', 'height', height);
end;

procedure TMasterToolsForm.FormDestroy(Sender: TObject);
begin
  saveServers;
  saveFiles;
  try
    FIni.WriteInteger('Window', 'left', left);
    FIni.WriteInteger('Window', 'top', top);
    FIni.WriteInteger('Window', 'width', width);
    FIni.WriteInteger('Window', 'height', height);
  except
  end;
  FIni.Free;
end;

procedure TMasterToolsForm.lbFilesClick(Sender: TObject);
begin
  btnReopen.Enabled := lbFiles.ItemIndex >= 0;
  btnRemoveFile.Enabled := lbFiles.ItemIndex >= 0;
end;

procedure TMasterToolsForm.lbServersClick(Sender: TObject);
begin
  btnConnect.Enabled := lbServers.ItemIndex >= 0;
  btnRemoveServer.Enabled := lbServers.ItemIndex >= 0;
end;

procedure TMasterToolsForm.openResourceFromFile(filename: String; res: TFHIRResource; format : TFHIRFormat; frameClass: TBaseResourceFrameClass);
var
  tab : TTabItem;
  frame : TFrame;
  fcs : IFMXCursorService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXCursorService) then
    fcs := TPlatformServices.Current.GetPlatformService(IFMXCursorService) as IFMXCursorService
  else
    fcs := nil;
  if Assigned(fcs) then
  begin
    Cursor := fcs.GetCursor;
    fcs.SetCursor(crHourGlass);
  end;
  try
    tab := tbMain.Add(TTabItem);
    tbMain.ActiveTab := tab;
    tab.Text := ExtractFileName(filename);
    tab.Hint := filename;
    tab.ShowHint := true;
    frame := frameClass.create(tab);
    tab.TagObject := frame;
    frame.TagObject := tab;
    frame.Parent := tab;
    frame.tabs := tbMain;
    frame.Tab := tab;
    frame.Align := TAlignLayout.Client;
    frame.Filename := filename;
    frame.resource := res.link;
    frame.format := format;
    frame.load;
    addFileToList(filename);
  finally
    if Assigned(fCS) then
      fcs.setCursor(Cursor);
  end;
end;

procedure TMasterToolsForm.saveFiles;
var
  s : String;
begin
  try
    FIni.EraseSection('Files');
    for s in lbFiles.Items do
      FIni.WriteString('Files', s, '');
  except
    // nothing we can do
  end;
end;

procedure TMasterToolsForm.saveServers;
var
  s : String;
begin
  try
    FIni.EraseSection('Servers');
    for s in lbServers.Items do
      FIni.WriteString('Servers', s, '');
  except
    // nothing we can do
  end;
end;

procedure TMasterToolsForm.Timer1Timer(Sender: TObject);
var
  frame : TBaseFrame;
begin
  frame := tbMain.ActiveTab.TagObject as TBaseFrame;
  tbnSave.Enabled := false;
  tbnSaveAs.Enabled := false;
  tbnClose.Enabled := false;
  if (frame <> nil) then
  begin
    tbnClose.Enabled := true;
    tbnSave.Enabled := frame.canSave;
    tbnSaveAs.Enabled := frame.canSaveAs;
  end;
end;

end.

