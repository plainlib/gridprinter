unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, ExtCtrls,
  StdCtrls, ActnList, Menus, ComCtrls, StdActns, GridPrn, GridPrnActions,
  GridPrnPreviewDlg;

type

  { TMainForm }

  TMainForm = class(TForm)
    ActionList1: TActionList;
    FileExit1: TFileExit;
    FileOpen1: TFileOpen;
    GridPrinter1: TGridPrinter;
    GridPrinterAction1: TGridPrinterAction;
    GridPrintPreviewAction1: TGridPrintPreviewAction;
    GridPrintPreviewDialog1: TGridPrintPreviewDialog;
    ImageList1: TImageList;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    Separator2: TMenuItem;
    MenuItem6: TMenuItem;
    Separator1: TMenuItem;
    StringGrid1: TStringGrid;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    procedure FileOpen1Accept(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

// Auxiliary code to adjust the grid's column widths to the cell text.
procedure AutoAdjustColWidths(AGrid: TStringGrid);
var
  r, c: Integer;
  w, wmax: Integer;
  bmp: TBitmap;
  s: String;
begin
  bmp := TBitmap.Create;
  try
    bmp.SetSize(1, 1);
    bmp.Canvas.Font.Assign(AGrid.Font);
    for c := 0 to AGrid.ColCount-1 do
    begin
      wmax := 0;
      for r := 0 to AGrid.RowCount-1 do
      begin
        s := AGrid.Cells[c, r];
        AGrid.Cells[c, r] := trim(s);
        w := bmp.Canvas.TextWidth(AGrid.Cells[c, r]);
        if w > wmax then wmax := w;
      end;
      AGrid.ColWidths[c] := wmax + 2*varCellPadding;
    end;
  finally
    bmp.Free;
  end;
end;


{ TMainForm }

procedure TMainForm.FileOpen1Accept(Sender: TObject);
begin
  // Load a csv data file
  StringGrid1.LoadFromCSVFile(FileOpen1.Dialog.FileName);
  // Pass the name of the loaded file to the GridPrinter for the header.
  GridPrinter1.FileName := FileOpen1.Dialog.FileName;
  // Adjust the grid column widths
  AutoAdjustColWidths(StringGrid1);
  // The grid was hidden after creation. It must be shown after loading data.
  StringGrid1.Show;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  DefaultFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
end;

end.

