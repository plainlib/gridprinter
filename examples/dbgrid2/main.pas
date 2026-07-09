unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, BufDataset, Forms, Controls, Graphics, Dialogs, Grids,
  DBGrids, ExtCtrls, StdCtrls, GridPrn, GridPrnPreviewDlg, DBGridPrinterAdapter;

type

  { TForm1 }

  TForm1 = class(TForm)
    BufDataset1: TBufDataset;
    Button1: TButton;
    cbShowTitles: TCheckBox;
    cbShowIndicator: TCheckBox;
    cbFiltered: TCheckBox;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    GridPrinter1: TGridPrinter;
    GridPrintPreviewDialog1: TGridPrintPreviewDialog;
    Panel1: TPanel;
    procedure BufDataset1FilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure cbShowIndicatorChange(Sender: TObject);
    procedure cbShowTitlesChange(Sender: TObject);
    procedure cbFilteredChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FAdapter: TDBGridPrinterAdapter;

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

function RandomString(Len: Integer): String;
var
  i: Integer;
begin
  SetLength(Result, Len);
  Result[1] := Char(ord('A') + Random(26));
  for i := 2 to Len do
    Result[i] := Char(ord('a') + Random(26));
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
const
  NUM_RECORDS = 100;
var
  i: Integer;
begin
  // Create some dummy dataset
  BufDataset1.FieldDefs.Add('TextField1', ftString, 20);
  BufDataset1.FieldDefs.Add('TextField2', ftString, 15);
  BufDataset1.FieldDefs.Add('IntField', ftInteger);
  BufDataset1.FieldDefs.Add('FloatField', ftFloat);
  BufDataset1.FieldDefs.Add('BoolField', ftBoolean);
  BufDataset1.FieldDefs.Add('DateField', ftDate);
  BufDataset1.FieldDefs.Add('TimeField', ftTime);
  BufDataset1.CreateDataset;
  BufDataset1.Open;
  for i := 1 to NUM_RECORDS do
    BufDataset1.AppendRecord([
      'Record ' + IntToStr(i),
      RandomString(Random(10) + 5),
      100*i,
      0.1*i,
      Boolean(Random(2)),
      Date()-i,
      TTime(Random)
    ]);
  BufDataset1.First;

  (BufDataset1.FieldByName('FloatField') as TFloatField).precision := 4;
  // Since the GridPrinter accesses the DBGrid assign it to the Grid property
  // only after the Dataset is ready and the DBGrid can display valid data.
  GridPrinter1.Grid := DBGrid1;

  FAdapter := TDBGridPrinterAdapter.Create(self);
  FAdapter.GridPrinter := GridPrinter1;

  cbShowTitles.Checked := dgTitles in DBGrid1.Options;
  cbShowIndicator.Checked := dgIndicator in DBGrid1.Options;
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

procedure TForm1.BufDataset1FilterRecord(DataSet: TDataSet; var Accept: Boolean
  );
var
  value: Integer;
begin
  value := Dataset.FieldByName('IntField').AsInteger;
  Accept := (value >= 1000) and (value <= 2000);
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

procedure TForm1.cbFilteredChange(Sender: TObject);
begin
  if cbFiltered.Checked then
  begin
    BufDataset1.OnFilterRecord := @BufDataset1FilterRecord;
    BufDataset1.Filtered := true;
  end else
  begin
    BufDataset1.Filtered := false;
    BufDataset1.OnFilterRecord := nil;
  end;
end;

end.

