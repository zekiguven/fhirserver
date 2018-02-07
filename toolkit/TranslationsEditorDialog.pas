unit TranslationsEditorDialog;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  System.Rtti, FMX.Grid.Style, FMX.Grid, FMX.Memo,
  FMX.ScrollBox, FMX.Edit, FMX.StdCtrls, FMX.Controls.Presentation,
  AdvGenerics,
  FHIRTypes, FHIRResources, FHIRUtilities,
  ToolKitUtilities;

type
  TTranslationsEditorForm = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Panel2: TPanel;
    Label1: TLabel;
    edtPrimary: TEdit;
    Panel3: TPanel;
    Label2: TLabel;
    grid: TGrid;
    PopupColumn1: TPopupColumn;
    StringColumn1: TStringColumn;
    btnAdd: TButton;
    btnDelete: TButton;
    procedure FormShow(Sender: TObject);
    procedure gridGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
    procedure btnAddClick(Sender: TObject);
    procedure gridSetValue(Sender: TObject; const ACol, ARow: Integer; const Value: TValue);
    procedure btnDeleteClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    FResource: TFHIRResource;
    FElement: TFHIRString;
    FExtensions : TAdvList<TFhirExtension>;
    procedure SetElement(const Value: TFHIRString);
    procedure SetResource(const Value: TFHIRResource);
  public
    Constructor Create(owner : TComponent); override;
    destructor Destroy; override;

    property Resource : TFHIRResource read FResource write SetResource;
    property Element : TFHIRString read FElement write SetElement;

  end;

var
  TranslationsEditorForm: TTranslationsEditorForm;

function editStringDialog(owner : TComponent; title : String; button : TButton; edit : TEdit; resource : TFHIRResource; element : TFHIRString) : boolean; overload;

implementation

{$R *.fmx}

function editStringDialog(owner : TComponent; title : String; button : TButton; edit : TEdit; resource : TFHIRResource; element : TFHIRString) : boolean;
begin
  TranslationsEditorForm := TTranslationsEditorForm.Create(owner);
  try
    TranslationsEditorForm.Resource := resource.Link;
    TranslationsEditorForm.Element := element.Link;
    TranslationsEditorForm.Caption := title;
    result := TranslationsEditorForm.ShowModal = mrOk;
    if result then
    begin
      if edit <> nil then
        edit.Text := element.value;
      if button <> nil then
        button.ImageIndex := translationsImageIndex(element);
    end;
  finally
    TranslationsEditorForm.Free;
  end;
end;

{ TForm1 }

procedure TTranslationsEditorForm.btnAddClick(Sender: TObject);
begin
  FExtensions.Add(TFHIRExtension.Create);
  grid.RowCount := grid.RowCount + 1;
  grid.Row := grid.RowCount - 1;
  btnDelete.Enabled := true;
end;

procedure TTranslationsEditorForm.btnDeleteClick(Sender: TObject);
begin
  FExtensions.Delete(grid.Row);
  grid.RowCount := grid.RowCount - 1;
  if grid.Row = grid.RowCount then
    grid.Row := grid.RowCount - 1;
end;

procedure TTranslationsEditorForm.Button1Click(Sender: TObject);
var
  ext : TFHIRExtension;
  langs : TStringList;
  s : string;
begin
  langs := TStringList.Create;
  try
    for ext in FExtensions do
    begin
      s := ext.getExtensionString('lang');
      if s = '' then
        raise Exception.Create('Language missing on a translation');
      if langs.IndexOf(s) > -1 then
        raise Exception.Create('Duplicate translation for '+s);
      langs.Add(s);
      ext.url := 'http://hl7.org/fhir/StructureDefinition/translation';
    end;
  finally
    langs.Free;
  end;
  element.value := edtPrimary.Text;
  element.removeExtension('http://hl7.org/fhir/StructureDefinition/translation');
  for ext in FExtensions do
    element.extensionList.add(ext.Link);
  modalResult := mrOk;
end;

constructor TTranslationsEditorForm.Create;
begin
  inherited;
  FExtensions := TAdvList<TFhirExtension>.create;
end;

destructor TTranslationsEditorForm.Destroy;
begin
  FExtensions.Free;
  FElement.Free;
  FResource.Free;
  inherited;
end;

procedure TTranslationsEditorForm.FormShow(Sender: TObject);
var
  ext : TFhirExtension;
  st : TStringList;
  s : String;
begin
  edtPrimary.Text := Element.primitiveValue;
  FExtensions.Clear;
  grid.RowCount := 0;
  for ext in Element.ExtensionList do
    if ext.url = 'http://hl7.org/fhir/StructureDefinition/translation' then
      FExtensions.Add(ext.Link);
  grid.RowCount := FExtensions.Count;
  btnDelete.Enabled := grid.RowCount > 0;
  st := langList;
  try
    PopupColumn1.Items.Clear;
    for s in st do
      PopupColumn1.Items.add(langDesc(s));
  finally
    st.Free;
  end;
end;

procedure TTranslationsEditorForm.gridGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
begin
  case ACol of
    0:Value := FExtensions[ARow].getExtensionString('lang');
    1:Value := FExtensions[ARow].getExtensionString('content');
  end;
end;

procedure TTranslationsEditorForm.gridSetValue(Sender: TObject; const ACol, ARow: Integer; const Value: TValue);
begin
  case ACol of
    0: FExtensions[ARow].setExtension('lang', TFHIRCode.Create(value.AsString));
    1: FExtensions[ARow].setExtension('content', TFHIRString.Create(value.AsString));
  end;
end;

procedure TTranslationsEditorForm.SetElement(const Value: TFHIRString);
begin
  FElement.Free;
  FElement := Value;
end;

procedure TTranslationsEditorForm.SetResource(const Value: TFHIRResource);
begin
  FResource.Free;
  FResource := Value;
end;

end.
