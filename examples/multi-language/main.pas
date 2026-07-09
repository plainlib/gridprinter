unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids,
  StdCtrls, ExtCtrls, ComboEx,
  LCLTranslator, Translations,
  PrintersDlgs, GridPrn, GridPrnPreviewForm, GridPrnPreviewDlg;

type

  { TMainForm }

  TMainForm = class(TForm)
    btnPrint: TButton;
    btnPreview: TButton;
    Button2: TButton;
    ccbPreviewOptions: TCheckComboBox;
    cmbDialogs: TComboBox;
    cmbLanguages: TComboBox;
    GridPrinter1: TGridPrinter;
    GridPrintPreviewDialog1: TGridPrintPreviewDialog;
    Label1: TLabel;
    PageSetupDialog1: TPageSetupDialog;
    Panel1: TPanel;
    PrinterSetupDialog1: TPrinterSetupDialog;
    StringGrid1: TStringGrid;
    procedure btnPrintClick(Sender: TObject);
    procedure btnPreviewClick(Sender: TObject);
    procedure ccbPreviewOptionsItemChange(Sender: TObject; {%H-}AIndex: Integer);
    procedure cmbLanguagesChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FLanguagesDir: String;
    procedure PopulateLanguages;
    procedure SelectLanguage(AIndex: Integer);

  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses
  FileUtil;

resourcestring
  RSNoPrinterDialog = 'No printer dialog';
  RSPageSetupDialog = 'Page setup dialog';
  RSPrinterDialog = 'Printer dialog';
  RSPrinterSetupDialog = 'Printer setup dialog';

  RSNavigationButtons = 'Navigation buttons';
  RSNavigationEdit = 'Navigation edit';
  RSZoomButtons = 'Zoom buttons';
  RSPageOrientationButtons = 'Page orientation buttons';
  RSPageMarginsButtons = 'Page margins button';
  RSHeaderFooterButton = 'Header/footer button';
  RSPrintOrderButtons = 'Print order: colums first or rows first';
  RSCenterButtons = 'Buttons for centering grid on page';
  RSScalePrinterButton = 'Scale printer button';
  RSPageSetupButton = 'Page setup dropdown-menu';
  RSPageNumberInfoPanel = 'Page number info';
  RSZoomLevelInfoPanel = 'Zoom level info';


{ TMainForm }

procedure TMainForm.btnPrintClick(Sender: TObject);
begin
  GridPrinter1.ShowPrintDialog := TGridPrnDialog(cmbDialogs.ItemIndex);
  GridPrinter1.Print;
end;

procedure TMainForm.btnPreviewClick(Sender: TObject);
begin
  GridPrintPreviewDialog1.Execute;
end;

procedure TMainForm.ccbPreviewOptionsItemChange(Sender: TObject; AIndex: Integer);
var
  optns: TGridPrintPreviewOptions;
begin
  optns := [];
  if ccbPreviewOptions.Checked[0] then Include(optns, ppoNavigationBtns);
  if ccbPreviewOptions.Checked[1] then Include(optns, ppoNavigationEdit);
  if ccbPreviewOptions.Checked[2] then Include(optns, ppoZoomBtns);
  if ccbPreviewOptions.Checked[3] then Include(optns, ppoPageOrientationBtns);
  if ccbPreviewOptions.Checked[4] then Include(optns, ppoMarginsBtn);
  if ccbPreviewOptions.Checked[5] then Include(optns, ppoHeaderFooterBtn);
  if ccbPreviewOptions.Checked[6] then Include(optns, ppoPrintOrderBtns);
  if ccbPreviewOptions.Checked[7] then Include(optns, ppoCenterBtns);
  if ccbPreviewOptions.Checked[8] then Include(optns, ppoScalePrinterBtn);
  if ccbPreviewOptions.Checked[9] then Include(optns, ppoPageSetupBtn);
  if ccbPreviewOptions.Checked[10] then Include(optns, ppoPageNumberInfo);
  if ccbPreviewOptions.Checked[11] then Include(optns, ppoZoomLevelInfo);
  GridPrintPreviewDialog1.Options := optns;
end;

procedure TMainForm.cmbLanguagesChange(Sender: TObject);
begin
  SelectLanguage(cmbLanguages.ItemIndex);
end;

procedure TMainForm.FormCreate(Sender: TObject);
const
  NUM_ROWS = 80;
  NUM_COLS = 15;
var
  i, r, c: Integer;
begin
  FLanguagesDir := ExpandFileName(Application.Location + '../../languages/');
  PopulateLanguages;
  SelectLanguage(cmbLanguages.ItemIndex);

  cmbDialogs.ItemIndex := 2;
  ccbPreviewOptions.ItemIndex := 0;
  for i := 0 to ccbPreviewOptions.Count-1 do
    ccbPreviewOptions.Checked[i] := TGridPrintPreviewOption(i) in DEFAULT_GRIDPRN_OPTIONS;

  StringGrid1.BeginUpdate;
  try
    StringGrid1.Clear;
    StringGrid1.RowCount := NUM_ROWS + StringGrid1.FixedRows;
    StringGrid1.ColCount := NUM_COLS + StringGrid1.FixedCols;
    for r := StringGrid1.FixedRows to StringGrid1.RowCount-1 do
      StringGrid1.Cells[0, r] := 'Row ' + IntToStr(r);
    for c := StringGrid1.FixedCols to StringGrid1.ColCount-1 do
    begin
      StringGrid1.Cells[c, 0] := 'Column ' + IntToStr(c);
      for r := StringGrid1.FixedRows to StringGrid1.RowCount-1 do
        StringGrid1.cells[c, r] := Format('C%d R%d', [c, r]);
    end;
  finally
    StringGrid1.EndUpdate;
  end;
end;

{ Populates the languages combobox: reads the names of the app's .po files
  in the languages directory and adds the item the combobox. }
procedure TMainForm.PopulateLanguages;
var
  List: TStringList;
  s, lang: String;
  i, j: Integer;
  appLangMask: String;
begin
  List := TStringList.Create;
  try
    appLangMask := ChangeFileExt(ExtractFileName(Application.ExeName), '.*.po');
    FindAllFiles(List, FLanguagesDir, appLangMask);
    for i := 0 to List.Count-1 do
    begin
      s := List[i];
      lang := '';
      for j := Length(s)-3 downto 0 do
      begin
        if s[j] = '.' then
          break;
        lang := s[j] + lang;
      end;
      case lowercase(lang) of
        'de': List[i] := 'de - Deutsch';
        'en': List[i] := 'en - English';
        // Add more cases when translations are available...
      end;
    end;
    List.Sort;
    cmbLanguages.Items.Assign(List);
  finally
    List.Free;
  end;
end;

procedure TMainForm.SelectLanguage(AIndex: Integer);
var
  lang: String;
  i, idx1, idx2: Integer;
begin
  idx1 := cmbDialogs.ItemIndex;
  idx2 := ccbPreviewOptions.ItemIndex;

  // Set the default language - the LCLTranslator translates all app strings
  // as well as the LCL strings...
  if AIndex = -1 then
  begin
    lang := SetDefaultLang('', FLanguagesDir);
    for i := 0 to cmbLanguages.Items.Count-1 do
      if pos(lang + ' - ', cmbLanguages.Items[i]) = 1 then
      begin
        cmbLanguages.ItemIndex := i;
        break;
      end;
  end else
  begin
    lang := cmbLanguages.Items[AIndex];
    lang := Copy(lang, 1, pos(' - ', lang) - 1);
    SetDefaultLang(lang, FLanguagesDir);
  end;
  // ... and translate the strings of the GridPrinter package.
  TranslateUnitResourceStrings('GridPrnStrings', FLanguagesDir + 'GridPrnStrings.' + lang + '.po');

  // The LCL Translator does not update the strings in the comboboxes.

  // Translate the items in the printer dialogs combobox...
  cmbDialogs.Items[0] := RSNoPrinterDialog;
  cmbDialogs.Items[1] := RSPageSetupDialog;
  cmbDialogs.Items[2] := RSPrinterDialog;
  cmbDialogs.Items[3] := RSPrinterSetupDialog;
  cmbDialogs.ItemIndex := idx1;

  // ... and of the preview dialog options check combobox.
  ccbPreviewOptions.Items[0] := RSNavigationButtons;
  ccbPreviewOptions.Items[1] := RSNavigationEdit;
  ccbPreviewOptions.Items[2] := RSZoomButtons;
  ccbPreviewOptions.Items[3] := RSPageOrientationButtons;
  ccbPreviewOptions.Items[4] := RSPageMarginsButtons;
  ccbPreviewOptions.Items[5] := RSHeaderFooterButton;
  ccbPreviewOptions.Items[6] := RSPrintOrderButtons;
  ccbPreviewOptions.Items[7] := RSCenterButtons;
  ccbPreviewOptions.Items[8] := RSScalePrinterButton;
  ccbPreviewOptions.Items[9] := RSPageSetupButton;
  ccbPreviewOptions.Items[10] := RSPageNumberInfoPanel;
  ccbPreviewOptions.Items[11] := RSZoomLevelInfoPanel;
  ccbPreviewOptions.ItemIndex := idx2;
end;

end.

