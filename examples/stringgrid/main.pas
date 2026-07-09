unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  PrintersDlgs, GridPrn, GridPrnPreviewDlg;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnPrint: TButton;
    btnPreview: TButton;
    Button2: TButton;
    GridPrinter1: TGridPrinter;
    GridPrintPreviewDialog1: TGridPrintPreviewDialog;
    PageSetupDialog1: TPageSetupDialog;
    PrinterSetupDialog1: TPrinterSetupDialog;
    StringGrid1: TStringGrid;
    procedure btnPrintClick(Sender: TObject);
    procedure btnPreviewClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnPrintClick(Sender: TObject);
begin
  GridPrinter1.Print;
end;

procedure TForm1.btnPreviewClick(Sender: TObject);
begin
  GridPrintPreviewDialog1.Execute;
end;

// Populate the string grid with dummy to have something for printing.
procedure TForm1.FormCreate(Sender: TObject);
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
        StringGrid1.cells[c, r] := Format('C%d R%d', [c, r]);
    end;
  finally
    StringGrid1.EndUpdate;
  end;
end;

end.

