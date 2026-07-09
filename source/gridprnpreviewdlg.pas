unit GridPrnPreviewDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, GridPrn, GridPrnPreviewForm;

type
  TGridPrintPreviewDialog = class;  // forward declaration

  TGridPrintPreviewFormParams = class(TPersistent)
  private
    FOwner: TGridPrintPreviewDialog;
    FLeft: Integer;
    FTop: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FPixelsPerInch: Integer;
    FPosition: TPosition;
  private
    procedure ReadPPI(Reader: TReader);
    procedure WritePPI(Writer: TWriter);
  protected
    procedure AdjustSize;
    procedure DefineProperties(Filer: TFiler); override;
  public
    constructor Create(AOwner: TGridPrintPreviewDialog);
  published
    property Left: Integer read FLeft write FLeft default 0;
    property Top: Integer read FTop write FTop default 0;
    property Width: Integer read FWidth write FWidth default 800;
    property Height: Integer read FHeight write FHeight default 600;
    property Position: TPosition read FPosition write FPosition default poMainFormCenter;
  end;

  TGridPrintPreviewDialog = class(TComponent)
  private
    FGridPrinter: TGridPrinter;
    FFormParams: TGridPrintPreviewFormParams;
    FOptions: TGridPrintPreviewOptions;
    FZoom: Integer;
    FZoomMode: TGridPrintPreviewZoomMode;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Execute;
  published
    property FormParams: TGridPrintPreviewFormParams read FFormParams write FFormParams;
    property GridPrinter: TGridPrinter read FGridPrinter write FGridPrinter;
    property Options: TGridPrintPreviewOptions
      read FOptions write FOptions default DEFAULT_GRIDPRN_OPTIONS;
    property Zoom: Integer read FZoom write FZoom default 100;
    property ZoomMode: TGridPrintPreviewZoomMode
      read FZoomMode write FZoomMode default zmCustom;
  end;

implementation

uses
  Graphics, Controls, LCLIntf, LCLType, Printers;

{ TGridPrintPreviewFormParams }

constructor TGridPrintPreviewFormParams.Create(AOwner: TGridPrintPreviewDialog);
begin
  inherited Create;
  FOwner := AOwner;
  FWidth := 800;
  FHeight := 600;
  FPosition := poMainFormCenter;
  FPixelsPerInch := ScreenInfo.PixelsPerInchY;
end;

procedure TGridPrintPreviewFormParams.AdjustSize;
var
  ppi: Integer;
begin
  ppi := ScreenInfo.PixelsPerInchY;
  Width := MulDiv(Width, ppi, FPixelsPerInch);
  Height := MulDiv(Height, ppi, FPixelsPerInch);
end;

procedure TGridPrintPreviewFormParams.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('PixelsPerInch', @ReadPPI, @WritePPI, true);
end;

procedure TGridPrintPreviewFormParams.ReadPPI(Reader: TReader);
begin
  FPixelsPerInch := Reader.ReadInteger;
end;

procedure TGridPrintPreviewFormParams.WritePPI(Writer: TWriter);
begin
  Writer.WriteInteger(ScreenInfo.PixelsPerInchY);
end;


{ TGridPrintPreviewDialog }

constructor TGridPrintPreviewDialog.Create(AOwner: TComponent);
begin
  inherited;
  FOptions := DEFAULT_GRIDPRN_OPTIONS;
  FFormParams := TGridPrintPreviewFormParams.Create(self);
  FZoom := 100;
end;

destructor TGridPrintPreviewDialog.Destroy;
begin
  FFormParams.Free;
  inherited;
end;

procedure TGridPrintPreviewDialog.Execute;
var
  F: TGridPrintPreviewForm;
  R: TRect;
begin
  if FGridPrinter = nil then
    exit;

  if Printer.Printers.Count = 0 then
    raise EPrinter.Create('No printers defined.');

  F := TGridPrintPreviewForm.Create(nil);
  try
    F.GridPrinter := FGridPrinter;
    F.Options := FOptions;
    R := Screen.WorkAreaRect;
    if FFormParams.Width > R.Width then FFormParams.Width := R.Width;
    if FFormParams.Height > R.Height then FFormParams.Height := R.Height;
    if FFormParams.Left < R.Left then FFormParams.Left := R.Left;
    if FFormParams.Top < R.Top then FFormParams.Top := R.Top;
    if FFormParams.Left + FFormParams.Width > R.Right then
      FFormParams.Left := R.Right - FFormParams.Width - GetSystemMetrics(SM_CXSIZEFRAME);
    if FFormParams.Top + FFormParams.Height > R.Bottom then
      FFormParams.Top := R.Bottom - FFormParams.Height - GetSystemMetrics(SM_CYCAPTION) - GetSystemMetrics(SM_CYSIZEFRAME);
    F.SetBounds(FFormParams.Left, FFormParams.Top, FFormParams.Width, FFormParams.Height);
    F.Position := FFormParams.Position;
    F.ZoomMode := FZoomMode;
    case FZoomMode of
      zmCustom: F.Zoom := FZoom;
      zmFitWidth: F.ZoomToFitWidth;
      zmFitHeight: F.ZoomToFitHeight;
    end;
    if (F.ShowModal = mrOK) then
      FGridPrinter.Print;
    FFormParams.Left := F.RestoredLeft;
    FFormParams.Top := F.RestoredTop;
    FFormParams.Width := F.RestoredWidth;
    FormParams.Height := F.RestoredHeight;
    FZoom := F.Zoom;
    FZoomMode := F.ZoomMode;
  finally
    F.Free;
  end;
end;

procedure TGridPrintPreviewDialog.Loaded;
begin
  inherited;
  FFormParams.AdjustSize;
end;

procedure TGridPrintPreviewDialog.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FGridPrinter then
      FGridPrinter := nil;
  end;
end;

end.

