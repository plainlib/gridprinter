unit DBGridPrinterAdapter;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Grids, db, dbGrids, GridPrn;

type
  TDBGridPrinterAdapter = class(TComponent)
  private
    FGridPrinter: TGridPrinter;
    FPageStartBookmark: TBookmark;
    FPageStartCol: Integer;
    FPageStartRow: Integer;
    FPageEndCol: Integer;
    FPageEndRow: Integer;
    procedure SetGridPrinter(AValue: TGridPrinter);
  protected
    procedure AfterPrintHandler(Sender: TObject);
    procedure GetCellTextHandler(Sender: TObject; AGrid: TCustomGrid;
      ACol, ARow: Integer; var AText: String);
    procedure GetRowCountHandler(Sender: TObject; AGrid: TCustomGrid;
      var ARowCount: Integer);
    procedure LinePrintedHandler(Sender: TObject; AGrid: TCustomGrid;
      ARow, ALastCol: Integer);
    procedure NewPageHandler(Sender: TObject; AGrid: TCustomGrid;
      APageNo: Integer; AStartCol, AStartRow, AEndCol, AEndRow: Integer);

    function CheckedGrid(AGrid: TCustomGrid): TDBGrid;
  public
    property GridPrinter: TGridPrinter read FGridPrinter write SetGridPrinter;
  end;


implementation

{ The OnAfterPrint event fires after printing/preview. We use it to free the
  bookmark needed for storing the top record of each page. }
procedure TDBGridPrinterAdapter.AfterPrintHandler(Sender: TObject);
var
  dbGrid: TDBGrid;
begin
  dbGrid := CheckedGrid(FGridPrinter.Grid);
  dbGrid.Datasource.Dataset.FreeBookmark(FPageStartBookmark);
end;

function TDBGridPrinterAdapter.CheckedGrid(AGrid: TCustomGrid): TDBGrid;
begin
  if not (AGrid is TDBGrid) then
    raise EGridPrinter.Create('TDBGridPrinterAdapter can only work with descendants ' +
      'of TDBGrid.');

  Result := AGrid as TDBGrid;
  if (Result.Datasource = nil) or (Result.Datasource.Dataset = nil) or (not Result.Datasource.Dataset.Active) then
    raise EGridPrinter.Create('TDBGridPrinterAdapter requires an active dataset.');
end;


{ The OnGetCellText fires whenever a cell is printed and the printer needs to
  know the cell text. }
procedure TDBGridPrinterAdapter.GetCellTextHandler(Sender: TObject;
  AGrid: TCustomGrid; ACol, ARow: Integer; var AText: String);
var
  dbGrid: TDBGrid;
  col: TColumn;
  colOffs: Integer;
begin
  AText := '';
  dbGrid := CheckedGrid(AGrid);

  if (dgIndicator in dbGrid.Options) then
    colOffs := 1
  else
    colOffs := 0;

  if ACol < colOffs then
    exit;

  col := dbGrid.Columns[ACol - colOffs];

  if (ARow = 0) and (dgTitles in dbGrid.Options) then
  begin
    AText := col.FieldName;
    exit;
  end;

  AText := col.Field.AsString;
end;

{ Since the DBGrid does not load all records, but we want to print all
  of them, we must tell the printer the real number of rows to print.
  Note that depending on the type of dataset RecordCount may be wrong,
  in particular when the dataset is filtered.}
procedure TDBGridPrinterAdapter.GetRowCountHandler(Sender: TObject;
  AGrid: TCustomGrid; var ARowCount: Integer);
var
  accept: Boolean;
  n: Integer;
  dbGrid: TDBGrid;
  dataset: TDataset;
begin
  dbGrid := CheckedGrid(AGrid);
  dataset := dbGrid.Datasource.Dataset;

  if dataset.Filtered and Assigned(dataset.OnFilterRecord) then
  begin
    dataset.DisableControls;
    dataset.First;
    n := 0;
    while not dataset.EoF do
    begin
      dataset.OnFilterRecord(dataset, accept);
      if accept then inc(n);
      dataset.Next;
    end;
    dataset.First;
    dataset.EnableControls;
  end else
  begin
    dataset.Last;
    dataset.First;
    n := dataset.RecordCount;
  end;
  ARowCount := n;
  if dgTitles in dbgrid.Options then
    inc(ARowCount);    // added 1 for the header row
end;

{ The event OnLinePrinted fires when the row with the specified index is
  completely printed. The last printed cell has the index ALastCol.
  The purpose of this event is to advance the dataset cursor to the next
  record for printing. This normally is done by Dataset.Next, except for
  the very last row of each page requiring special treatment - see below. }
procedure TDBGridPrinterAdapter.LinePrintedHandler(Sender: TObject;
  AGrid: TCustomGrid; ARow, ALastCol: Integer);
var
  dbGrid: TDBGrid;
  dataset: TDataset;
begin
  dbGrid := CheckedGrid(AGrid);
  dataset := dbGrid.Datasource.Dataset;
  case FGridPrinter.PrintOrder of
    poRowsFirst:
      // When the last row of a "rows first" page has been printed we return
      // to the record of the first line of that page if more pages are following
      // along the row. If we printed the last page of that row we must advance
      // to the next record.
      if (ARow = FPageEndRow) and (ALastCol <> FGridPrinter.ColCount - 1) then
        dataset.GotoBookmark(FPageStartBookmark)
      else
        dataset.Next;
    poColsFirst:
      // When the last row of a "cols first" page has been printed we normally
      // advance to the next record, unless the rows are continued on other
      // pages where we return to the first record of the dataset.
      if (ARow = FGridPrinter.RowCount-1) then
        dataset.First
      else
        dataset.Next;
  end;
end;

{ The event OnNewPage fires when the printer is about to begin a new page.
  The page will contain cells between AStartCol, AStartRow in the top/left corner,
  and AEndCol/AEndRow in the bottom/right corner.
  We are setting a bookmark so that the dataset can return to this record
  in case of page-breaks in "rows-first" print order. }
procedure TDBGridPrinterAdapter.NewPageHandler(Sender: TObject;
  AGrid: TCustomGrid; APageNo: Integer;
  AStartCol, AStartRow, AEndCol, AEndRow: Integer);
var
  dbgrid: TDBGrid;
  dataset: TDataset;
begin
  dbGrid := CheckedGrid(AGrid);
  dataset := dbGrid.Datasource.Dataset;

  FPageStartCol := AStartCol;
  FPageStartRow := AStartRow;
  FPageEndCol := AEndCol;
  FPageEndRow := AEndRow;

  dataset.FreeBookmark(FPageStartBookmark);
  FPageStartBookmark := dataset.GetBookmark;
end;

procedure TDBGridPrinterAdapter.SetGridPrinter(AValue: TGridPrinter);
begin
  if AValue = FGridPrinter then
    exit;
  FGridPrinter := AValue;
  if FGridPrinter = nil then
    exit;
  FGridPrinter.OnAfterPrint := @AfterPrintHandler;
  FGridPrinter.OnGetCellText := @GetCellTextHandler;
  FGridPrinter.OnGetRowCount := @GetRowCountHandler;
  FGridPrinter.OnLinePrinted := @LinePrintedHandler;
  FGridPrinter.OnNewPage := @NewPageHandler;
end;

end.

