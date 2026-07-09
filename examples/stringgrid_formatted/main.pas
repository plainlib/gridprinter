unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Grids,
  StdCtrls, GridPrn, GridPrnPreviewDlg;

type

  { TMainForm }

  TMainForm = class(TForm)
    btnPrint: TButton;
    btnPreview: TButton;
    ButtonPanel: TPanel;
    GridPrinter1: TGridPrinter;
    GridPrintPreviewDialog1: TGridPrintPreviewDialog;
    StringGrid1: TStringGrid;
    procedure btnPreviewClick(Sender: TObject);
    procedure btnPrintClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PrepareCanvasHandler(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
  private

  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.btnPrintClick(Sender: TObject);
begin
  GridPrinter1.Print;
end;

procedure TMainForm.btnPreviewClick(Sender: TObject);
begin
  GridPrintPreviewDialog1.Execute;
end;

procedure TMainForm.FormCreate(Sender: TObject);
const
  NUM_ROWS = 100;
  NUM_COLS = 20;
var
  r, c: Integer;
begin
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
        StringGrid1.Cells[c, r] := Format('C%d R%d', [c, r]);
    end;
    StringGrid1.Cells[6, 5] := 'This is a long text';

    StringGrid1.DefaultColWidth := 80;
    StringGrid1.ColWidths[3] := 40;
    StringGrid1.RowHeights[5] := 60;
    StringGrid1.Options := StringGrid1.Options + [goCellEllipsis];
    StringGrid1.AlternateColor := clMoneyGreen;
    StringGrid1.OnPrepareCanvas := @PrepareCanvasHandler;
    GridPrinter1.OnPrepareCanvas := @PrepareCanvasHandler;
  finally
    StringGrid1.EndUpdate;
  end;
end;

procedure TMainForm.PrepareCanvasHandler(Sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
var
  lCanvas: TCanvas;
  ts: TTextStyle;
begin
  if Sender = StringGrid1 then
    lCanvas := StringGrid1.Canvas
  else
  if Sender = GridPrinter1 then
    lCanvas := GridPrinter1.Canvas
  else
    raise Exception.Create('Unknown sender of OnPrepareCanvas.');

  ts := lCanvas.TextStyle;

  if (ACol = 3) and (ARow >= StringGrid1.FixedRows) and odd(ARow) then
  begin
    lCanvas.Brush.Color := clSkyBlue;
    lCanvas.Font.Color := clBlue;
  end;

  if (ACol = 6) and (ARow = 5) then
  begin
    ts.Wordbreak := true;
    ts.SingleLine := false;
    lCanvas.Font.Size := 12;
    lCanvas.Font.Style := [fsBold];
  end;

  if (ARow = 5) then
  begin
    ts.Alignment := taRightJustify;
  end;

  lCanvas.TextStyle := ts;
end;


end.

