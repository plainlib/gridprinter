unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, memds, DB, BufDataset, Forms, Controls, Graphics, Dialogs,
  DBGrids, ExtCtrls, StdCtrls, GridPrn, GridPrnPreviewDlg, Grids;

type

  { TForm1 }

  TForm1 = class(TForm)
    BufDataset1: TBufDataset;
    Button1: TButton;
    cbShowIndicator: TCheckBox;
    cbShowTitles: TCheckBox;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    GridPrinter1: TGridPrinter;
    GridPrintPreviewDialog1: TGridPrintPreviewDialog;
    Panel1: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure cbShowIndicatorChange(Sender: TObject);
    procedure cbShowTitlesChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure GridPrinter1BeforePrint(Sender: TObject);
    procedure GridPrinter1GetCellText(Sender: TObject; AGrid: TCustomGrid;
      ACol, ARow: Integer; var AText: String);
    procedure GridPrinter1GetRowCount(Sender: TObject; AGrid: TCustomGrid;
      var ARowCount: Integer);
    procedure GridPrinter1NewLine(Sender: TObject; AGrid: TCustomGrid;
      ARow: Integer);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  // Create some dummy dataset
  BufDataset1.FieldDefs.Add('Text', ftString, 20);
  BufDataset1.FieldDefs.Add('Value', ftInteger);
  BufDataset1.FieldDefs.Add('Date', ftDate);
  BufDataset1.CreateDataset;
  BufDataset1.Open;
  for i := 1 to 100 do
    BufDataset1.AppendRecord(['Record ' + IntToStr(i), 100*i, Date()-i]);
  BufDataset1.First;

  // Since the GridPrinter accesses the DBGrid we must assign it to the Grid
  // property only after the Dataset is ready and the DBGrid is able to display
  // valid data.
  GridPrinter1.Grid := DBGrid1;

  cbShowTitles.Checked := dgTitles in DBGrid1.Options;
  cbShowIndicator.Checked := dgIndicator in DBGrid1.Options;
end;

procedure TForm1.GridPrinter1BeforePrint(Sender: TObject);
begin
  DBGrid1.DataSource.Dataset.First;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  bm: TBookmark;
begin
  // Store currently active record so that we can return to it after preview/print.
  bm := BufDataset1.GetBookmark;
  try
    // Disable scrolling of grid
    BufDataset1.DisableControls;
    try
      // Show the grid printpreview
      GridPrintPreviewDialog1.Execute;
    finally
      // Allow scrolling again
      BufDataset1.EnableControls;
    end;
    // Return to the stored record position.
    BufDataset1.GotoBookmark(bm);
  finally
    BufDataset1.FreeBookmark(bm);
  end;
end;

procedure TForm1.cbShowIndicatorChange(Sender: TObject);
begin
  if cbShowIndicator.Checked then
    DBGrid1.Options := DBGrid1.Options + [dgIndicator]
  else
    DBGrid1.Options := DBGrid1.Options - [dgIndicator];
end;

procedure TForm1.cbShowTitlesChange(Sender: TObject);
begin
  if cbShowTitles.Checked then
    DBGrid1.Options := DBGrid1.Options + [dgTitles]
  else
    DBGrid1.Options := DBGrid1.Options - [dgTitles];
end;

{ The OnGetCellText event fires whenever the printer needs the cell text from
  the givel col/row. We don't care about row here because the dataset record
  for this row has been selected already in the OnNewLine event.
  As for the col, we use the field from the DBGrid.Columns rather than from the
  dataset directly since this accounts for rearranging of the column order in
  the grid. The cell text is obtained from this field.
  Note that special care must be taken to correct for offsets due to indicator
  column and title row. }
procedure TForm1.GridPrinter1GetCellText(Sender: TObject; AGrid: TCustomGrid;
  ACol, ARow: Integer; var AText: String);
var
  dbGrid: TDBGrid;
  col: TColumn;
  colOffs: Integer;
begin
  AText := '';

  dbGrid := AGrid as TDBGrid;

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
  of them, we must tell the printer the real number of rows to print. }
procedure TForm1.GridPrinter1GetRowCount(Sender: TObject; AGrid: TCustomGrid;
  var ARowCount: Integer);
var
  dbGrid: TDBGrid;
begin
  dbGrid := AGrid as TDBGrid;
  if dgTitles in dbGrid.Options then
    ARowCount := dbGrid.Datasource.Dataset.RecordCount + 1  // we must 1 for the header row
  else
    ARowCount := dbGrid.Datasource.Dataset.RecordCount;
end;

{ The event OnNewLine fires whenever the printer begins printing a new row
  of cells. This is when the dataset must move on to the next record. But note
  that the records are not necessarily printed in linear order, from first to
  last, because of the GridPrinter's PrintOrder setting. Therefore, we need
  something to identify the row to be printed in the new line. We use the
  dataset's RecNo for this purpose which is a number starting at 1.
  BUT BEWARE: RecNo is not a good parameter for many dataset types, usually
  only for the standard file-based databases! }
procedure TForm1.GridPrinter1NewLine(Sender: TObject; AGrid: TCustomGrid;
  ARow: Integer);
var
  dbGrid: TDBGrid;
begin
  dbGrid := AGrid as TDBGrid;
  if dgTitles in dbGrid.Options then
    dbGrid.DataSource.Dataset.RecNo := ARow
    // RecNo starts at 1. ARow starts at 1, too, since we display the header row
  else
    dbGrid.Datasource.Dataset.RecNo := ARow + 1;
    // We must add 1 to the row index since the header row is hidder here.
end;

end.

