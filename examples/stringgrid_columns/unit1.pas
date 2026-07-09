unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, ExtCtrls,
  StdCtrls, GridPrn, GridPrnPreviewDlg;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    GridPrinter1: TGridPrinter;
    GridPrintPreviewDialog1: TGridPrintPreviewDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    pnlCol1Alignment: TPanel;
    pnlCol2Alignment: TPanel;
    pnlCol3Alignment: TPanel;
    rbLayoutTop: TRadioButton;
    rbLayoutCenter: TRadioButton;
    rbLayoutBottom: TRadioButton;
    rbCenter2: TRadioButton;
    rbCenter3: TRadioButton;
    rbLeft1: TRadioButton;
    rbCenter1: TRadioButton;
    rbLeft2: TRadioButton;
    rbLeft3: TRadioButton;
    rbRight1: TRadioButton;
    rbRight2: TRadioButton;
    rbRight3: TRadioButton;
    StringGrid1: TStringGrid;
    procedure Button1Click(Sender: TObject);
    procedure rbLayoutChange(Sender: TObject);
    procedure rbAlignmentChange(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  GridPrintPreviewDialog1.Execute;
end;

procedure TForm1.rbLayoutChange(Sender: TObject);
var
  layoutIndex: Integer;
  i: Integer;
begin
  if not (Sender is TRadioButton) then
    exit;
  if not TRadioButton(Sender).Checked then
    exit;
  layoutIndex := TRadioButton(Sender).Tag - 1;
  for i := 0 to StringGrid1.Columns.Count-1 do
  begin
    StringGrid1.Columns[i].Layout := TTextLayout(layoutIndex);
    StringGrid1.Columns[i].Title.Layout := TTextLayout(layoutIndex);
  end;
end;

procedure TForm1.rbAlignmentChange(Sender: TObject);
var
  colIndex, alignmentIndex: Integer;
  col: TGridColumn;
begin
  if not (Sender is TRadioButton) then
    exit;
  if not TRadioButton(Sender).Checked then
    exit;
  colIndex := TRadioButton(Sender).Tag div 10 - 1;
  alignmentIndex := TRadioButton(Sender).Tag mod 10 - 1;
  col := StringGrid1.Columns[colIndex];
  col.Alignment := TAlignment(alignmentIndex);
  col.Title.Alignment := TAlignment(alignmentIndex);
end;

end.

