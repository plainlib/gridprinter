unit FPSpreadsheetPrintAdapter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Grids,
  fpSpreadsheet, fpsTypes, fpSpreadsheetGrid,
  GridPrn;

type
  TFPSpreadsheetGridPrinterAdapter = class(TComponent)
  private
    FGridPrinter: TGridPrinter;
    FGridCanvas: TCanvas;
    FOldZoomFactor: Double;
    FOldPadding: Integer;
    FOldGridOptions: TGridOptions;
    FOldColWidths: Array of Integer;
    procedure SetGridPrinter(AValue: TGridPrinter);
  protected
    procedure AfterPrintHandler(Sender: TObject);
    procedure BeforePrintHandler(Sender: TObject);
    procedure GetColCountHandler(Sender: TObject; AGrid: TCustomGrid;
      var AColCount: Integer);
    procedure GetRowCountHandler(Sender: TObject; AGrid: TCustomGrid;
      var ARowCount: Integer);
    procedure PrintCellHandler(Sender: TObject;  AGrid: TCustomGrid;
      ACanvas: TCanvas; ACol, ARow: Integer; ARect: TRect);

    function CheckedGrid: TsWorksheetGrid;
    function GetWorksheetGrid: TsWorksheetGrid;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
  published
    property GridPrinter: TGridPrinter read FGridPrinter write SetGridPrinter;
  end;

implementation

{ TsWorksheetGridHelper
  Helper class to access protected methods of the worksheet grid. }

type
  TsWorksheetGridHelper = class helper for TsWorksheetGrid
  public
    procedure DrawTheCell(aCol,aRow: Integer; aRect: TRect; aState:TGridDrawState);
    procedure DrawTheCellBorders(ACol, ARow: Integer; ARect: TRect; ACell: PCell);
    procedure DrawTheCommentMarker(ARect: TRect);
  end;

procedure TsWorksheetGridHelper.DrawTheCell(aCol,aRow: Integer; aRect: TRect;
  aState:TGridDrawState);
begin
  inherited DrawCell(aCol, aRow, aRect, aState);
end;

procedure TsWorksheetGridHelper.DrawTheCellBorders(ACol, ARow: Integer;
  ARect: TRect; ACell: PCell);
begin
  inherited DrawCellBorders(ACol, ARow, ARect, ACell);
end;

procedure TsWorksheetGridHelper.DrawTheCommentMarker(ARect: TRect);
begin
  inherited DrawCommentMarker(ARect);
end;


{ TFPSpreadsheetGridPrinterAdapter }

procedure TFPSpreadsheetGridPrinterAdapter.AfterPrintHandler(Sender: TObject);
var
  i: Integer;
  worksheetGrid: TsWorksheetGrid;
begin
  worksheetGrid := CheckedGrid;

  // Restore the worksheetgrid's Canvas.
  worksheetGrid.Canvas := FGridCanvas;

  // Restore the orignal value of the CellPadding of the grid
  varCellPadding := FOldPadding;

  // Restore drawing of the grid lines in the worksheet grid
  worksheetGrid.Options := FOldGridOptions;

  // Restore the original grid column widths
  for i := 0 to High(FOldColWidths) do
    worksheetGrid.ColWidths[i] := FOldColWidths[i];

  // Restore the worksheetgrid's ZoomFactor
  worksheetGrid.ZoomFactor := FOldZoomFactor;
end;

procedure TFPSpreadsheetGridPrinterAdapter.BeforePrintHandler(Sender: TObject);
var
  i: Integer;
  worksheetGrid: TsWorksheetGrid;
begin
  worksheetGrid := CheckedGrid;

  // We want to draw on the printer/preview canvas. Therefore, we assign the
  // grid's canvas to that of the GridPrinter. In order to restore the grid
  // canvas after printing, we must store its old canvas.
  FGridCanvas := FGridPrinter.Grid.Canvas;
  worksheetGrid.Canvas := FGridPrinter.Canvas;

  // Since the cells are drawn by the grid we must make sure that the correctly
  // scaled value of the CellPadding is used during printing.
  FOldPadding := varCellPadding;
  varCellPadding := FGridPrinter.Padding;

  // The TsWorksheetGrid paints the grid lines in the DrawCell method. To
  // avoid duplicate drawing (which, BTW, is offset by 1 pixel) we turn off
  // painting of the grid lines in the worksheet grid so that the grid printer
  // can take control. This is needed for correct scaling of the grid line width.
  FOldGridOptions := worksheetGrid.Options;
  worksheetGrid.Options := worksheetGrid.Options - [
    goHorzLine, goVertLine, goFixedHorzLine, goFixedVertLine
  ];

  // Since the worksheet grid can reformat numeric cell values to fit into the
  // cell width we must scale the column widths to the printer resolution:
  SetLength(FOldColWidths, FGridPrinter.ColCount);
  for i := 0 to High(FOldColWidths) do
  begin
    FOldColWidths[i] := worksheetGrid.ColWidths[i];
    worksheetGrid.ColWidths[i] := FGridPrinter.ScaleX(FOldColWidths[i]);
  end;

  // Store the worksheetgrid's ZoomFactor. We may have to change it
  FOldZoomFactor := worksheetGrid.ZoomFactor;
  worksheetGrid.ZoomFactor := FGridPrinter.PrintScaleFactor;
end;

function TFPSpreadsheetGridPrinterAdapter.CheckedGrid: TsWorksheetGrid;
begin
  if FGridPrinter = nil then
    raise EGridPrinter.Create('No GridPrinter assigned to the TFPSpreadseetGridPrinterAdapter');

  if FGridPrinter.Grid = nil then
    raise EGridPrinter.Create('TFPSpreadsheetGridPrinterAdapter can only be used '+
      'after the WorksheetGrid has been assigned to the GridPrinter.');

  if not (FGridPrinter.Grid is TsWorksheetGrid) then
    raise EGridPrinter.Create('TFPSpreadsheetGridPrinterAdapter requires that '+
      'the assigned grid is a TsWorksheetGrid.');

  Result := GetWorksheetGrid;
end;

procedure TFPSpreadsheetGridPrinterAdapter.GetColCountHandler(Sender: TObject;
  AGrid: TCustomGrid; var AColCount: Integer);
var
  worksheetGrid: TsWorksheetGrid;
begin
  worksheetGrid := CheckedGrid;
  AColCount := worksheetGrid.Worksheet.GetLastOccupiedColIndex + 1 + worksheetGrid.HeaderCount;
end;

procedure TFPSpreadsheetGridPrinterAdapter.GetRowCountHandler(Sender: TObject;
  AGrid: TCustomGrid; var ARowCount: Integer);
var
  worksheetGrid: TsWorksheetGrid;
begin
  worksheetGrid := CheckedGrid;
  ARowCount := worksheetGrid.Worksheet.GetLastOccupiedRowIndex + 1 + worksheetGrid.HeaderCount;
end;

function TFPSpreadsheetGridPrinterAdapter.GetWorksheetGrid: TsWorksheetGrid;
begin
  Result := TsWorksheetGrid(FGridPrinter.Grid);
end;

procedure TFPSpreadsheetGridPrinterAdapter.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FGridPrinter then
      FGridPrinter := nil;
  end;
end;

procedure TFPSpreadsheetGridPrinterAdapter.PrintCellHandler(Sender: TObject;
  AGrid: TCustomGrid; ACanvas: TCanvas; ACol, ARow: Integer; ARect: TRect);
var
  worksheetGrid: TsWorksheetGrid;
  cell: PCell;
  gr, gc: Integer;
begin
  worksheetGrid := CheckedGrid;
  worksheetGrid.DrawTheCell(ACol, ARow, ARect, []);
  gr := worksheetGrid.GetWorksheetRow(ARow);
  gc := worksheetGrid.GetWorksheetCol(ACol);
  cell := worksheetGrid.Worksheet.FindCell(gr, gc);
  if worksheetGrid.Worksheet.HasComment(cell) then
    worksheetGrid.DrawTheCommentMarker(ARect);     // FIXME
  if uffBorder in worksheetGrid.Worksheet.ReadUsedFormatting(cell) then
    worksheetGrid.DrawTheCellBorders(gc, gr, ARect, cell)
end;

procedure TFPSpreadsheetGridPrinterAdapter.SetGridPrinter(AValue: TGridPrinter);
begin
  if AValue = FGridPrinter then
    exit;
  FGridPrinter := AValue;
  if FGridPrinter = nil then
    exit;

  FGridPrinter.OnBeforePrint := @BeforePrintHandler;
  FGridPrinter.OnAfterPrint := @AfterPrintHandler;
  FGridPrinter.OnGetColCount := @GetColCountHandler;
  FGridPrinter.OnGetRowCount := @GetRowCountHandler;
  FGridPrinter.OnPrintCell := @PrintCellHandler;
end;

end.

