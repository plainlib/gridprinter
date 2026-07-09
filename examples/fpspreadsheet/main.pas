unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  GridPrn, GridPrnPreviewDlg, FPSpreadsheetPrintAdapter,
  fpspreadsheetgrid, fpspreadsheetctrls, fpsAllFormats;

type

  { TMainForm }

  TMainForm = class(TForm)
    Bevel1: TBevel;
    btnPrint: TButton;
    btnPreview: TButton;
    btnOpenFile: TButton;
    GridPrinter1: TGridPrinter;
    GridPrintPreviewDialog1: TGridPrintPreviewDialog;
    OpenDialog1: TOpenDialog;
    ButtonPanel: TPanel;
    sWorkbookSource1: TsWorkbookSource;
    sWorkbookTabControl1: TsWorkbookTabControl;
    sWorksheetGrid1: TsWorksheetGrid;
    procedure btnOpenFileClick(Sender: TObject);
    procedure btnPreviewClick(Sender: TObject);
    procedure btnPrintClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FAdapter: TFPSpreadsheetGridPrinterAdapter;
  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Use a TFPSpreadsheetGridPrinterAdapter to do all the adjustments needed
  // for FPSpreadsheet grids.
  FAdapter := TFPSpreadsheetGridPrinterAdapter.Create(self);
  FAdapter.GridPrinter := GridPrinter1;

  if ParamCount > 0 then
    sWorkbookSource1.LoadFromSpreadsheetFile(ParamStr(1));
end;

procedure TMainForm.btnPrintClick(Sender: TObject);
begin
  GridPrinter1.Print;
end;

procedure TMainForm.btnPreviewClick(Sender: TObject);
begin
  GridPrintPreviewDialog1.Execute;
end;

procedure TMainForm.btnOpenFileClick(Sender: TObject);
begin
  if OpenDialog1.FileName <> '' then
    OpenDialog1.InitialDir := ExtractFileDir(OpenDialog1.FileName);
  if OpenDialog1.Execute then
    sWorkbookSource1.LoadFromSpreadsheetFile(OpenDialog1.FileName);
end;

end.

