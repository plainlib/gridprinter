unit GridPrnActions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ActnList,
  GridPrn, GridPrnPreviewDlg;

type
  TGridPrinterAction = class(TCustomAction)
  private
    FGridPrinter: TGridPrinter;
    procedure SetGridPrinter(const AValue: TGridPrinter);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ExecuteTarget(Target: TObject); override;
    function HandlesTarget(Target: TObject): Boolean; override;
    procedure UpdateTarget(Target: TObject); override;
  published
    property GridPrinter: TGridPrinter read FGridPrinter write SetGridPrinter;
    property Caption;
    property Enabled;
    property HelpContext;
    property HelpKeyword;
    property HelpType;
    property Hint;
    property ImageIndex;
    property OnExecute;
    property OnHint;
    property OnUpdate;
    property SecondaryShortCuts;
    property ShortCut;
    property Visible;
  end;

  TGridPrintPreviewAction = class(TCustomAction)
  private
    FPreviewDlg: TGridPrintPreviewDialog;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ExecuteTarget(Target: TObject); override;
    function HandlesTarget(Target: TObject): Boolean; override;
    procedure UpdateTarget(Target: TObject); override;
  published
    property PreviewDialog: TGridPrintPreviewDialog read FPreviewDlg write FPreviewDlg;
    property Caption;
    property Enabled;
    property HelpContext;
    property HelpKeyword;
    property HelpType;
    property Hint;
    property ImageIndex;
    property OnExecute;
    property OnHint;
    property OnUpdate;
    property SecondaryShortCuts;
    property ShortCut;
    property Visible;
  end;

implementation

uses
  Grids, GridPrnStrings;

constructor TGridPrinterAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := RSPrint;
  Hint := RSPrintGrid;
end;

procedure TGridPrinterAction.ExecuteTarget(Target: TObject);
begin
  if HandlesTarget(Target) then
    FGridPrinter.Print;
end;

function TGridPrinterAction.HandlesTarget(Target: TObject): Boolean;
begin
  Result := (Target <> nil) and (Target = FGridPrinter);
end;

procedure TGridPrinterAction.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FGridPrinter) then
    FGridPrinter := nil;
end;

procedure TGridPrinterAction.SetGridPrinter(const AValue: TGridPrinter);
begin
  if FGridPrinter <> AValue then
  begin
    FGridPrinter := AValue;
    if FGridPrinter.ShowPrintDialog = gpdNone then
      Caption := RSPrint
    else
      Caption := RSPrintEllipsis;
  end;
end;

procedure TGridPrinterAction.UpdateTarget(Target: TObject);
var
  grid: TCustomGrid;
begin
  if HandlesTarget(Target) then
  begin
    grid := (Target as TGridPrinter).Grid;
    Enabled := (grid <> nil) and grid.Visible;
  end else
    Enabled := false;
end;


{ TGridPrintPreviewAction }

constructor TGridPrintPreviewAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := RSPrintPreviewEllipsis;
  Hint := RSPrintPreview;
end;

procedure TGridPrintPreviewAction.ExecuteTarget(Target: TObject);
begin
  if HandlesTarget(Target) then
    FPreviewDlg.Execute;
end;

function TGridPrintPreviewAction.HandlesTarget(Target: TObject): Boolean;
begin
  Result := (Target <> nil) and (Target = FPreviewDlg);
end;

procedure TGridPrintPreviewAction.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FPreviewDlg) then
    FPreviewDlg := nil;
end;

procedure TGridPrintPreviewAction.UpdateTarget(Target: TObject);
var
  prn: TGridPrinter;
begin
  if HandlesTarget(Target) then
  begin
    prn := (Target as TGridPrintPreviewDialog).GridPrinter;
    Enabled := (prn <> nil) and (prn.Grid <> nil) and prn.Grid.Visible;
  end else
    Enabled := false;
end;

end.

