unit GridPrnScalingForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ButtonPanel, StdCtrls,
  Spin,
  GridPrn;

type

  { TGridPrinterScalingForm }

  TGridPrinterScalingForm = class(TForm)
    ButtonPanel: TButtonPanel;
    fseScalingFactor: TFloatSpinEdit;
    lblPagesHor: TLabel;
    lblPagesVert: TLabel;
    lblInfo: TLabel;
    lblScaleFactorInfo: TLabel;
    rbManualScaleFactor: TRadioButton;
    cbScaleToHeight: TCheckBox;
    cbScaleToWidth: TCheckBox;
    seNumPagesHor: TSpinEdit;
    seNumPagesVert: TSpinEdit;
    procedure cbScaleToWidthOrHeightChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure rbManualScaleFactorChange(Sender: TObject);
  private
    FGridPrinter: TGridPrinter;
    FScalingModeLock: Integer;
    procedure SetGridPrinter(AValue: TGridPrinter);

  public
    procedure UpdateStrings;
    property GridPrinter: TGridPrinter read FGridPrinter write SetGridPrinter;

  end;

var
  GridPrinterScalingForm: TGridPrinterScalingForm;

implementation

{$R *.lfm}

uses
  Math, GridPrnStrings;

procedure TGridPrinterScalingForm.cbScaleToWidthOrHeightChange(Sender: TObject);
begin
  if FScalingModeLock > 0 then
    exit;
  inc(FScalingModeLock);
  rbManualScaleFactor.Checked := not (cbScaleToWidth.Checked or cbScaletoHeight.Checked);
  dec(FScalingModeLock);
end;

procedure TGridPrinterScalingForm.FormActivate(Sender: TObject);
begin
  Constraints.MinHeight := cbScaleToHeight.Top + cbScaleToHeight.Height +
    cbScaleToHeight.BorderSpacing.Bottom + ButtonPanel.Height;
  Constraints.MinWidth := lblPagesVert.Left + lblPagesVert.Width +
    lblPagesVert.BorderSpacing.Right;
  Width := 0;  // enforce constraints
  Height := 0;
end;

procedure TGridPrinterScalingForm.FormCreate(Sender: TObject);
begin
  UpdateStrings;
end;

procedure TGridPrinterScalingForm.OKButtonClick(Sender: TObject);
var
  nhor, nvert: Integer;
begin
  if rbManualScaleFactor.Checked then
  begin
    FGridPrinter.PrintScalingMode := smManual;
    FGridPrinter.PrintScaleFactor := fseScalingFactor.Value;
  end else
  begin
    nhor := IfThen(cbScaleToWidth.Checked, seNumPagesHor.Value, -1);
    nvert := IfThen(cbScaletoHeight.Checked, seNumPagesVert.Value, -1);
    FGridPrinter.ScaleToPages(nhor, nvert);
  end;
end;

procedure TGridPrinterScalingForm.rbManualScaleFactorChange(Sender: TObject);
begin
  if FScalingModeLock > 0 then
    exit;
  if rbManualScaleFactor.Checked then
  begin
    inc(FScalingModeLock);
    cbScaleToWidth.Checked := false;
    cbScaleToHeight.Checked := false;
    dec(FScalingModeLock);
  end;
end;

procedure TGridPrinterScalingForm.SetGridPrinter(AValue: TGridPrinter);
begin
  FGridPrinter := AValue;
  if FGridPrinter <> nil then
  begin
    lblScaleFactorInfo.Caption := Format(RSScaleFactorInfo, [FGridPrinter.PrintScaleFactor]);
    cbScaleToWidth.Checked := (FGridPrinter.PrintScalingMode in [smFitToWidth, smFitAll]) and
      (FGridPrinter.PrintScaleToNumHorPages > 0);
    cbScaleToHeight.Checked := (FGridPrinter.PrintScalingMode in [smFitToHeight, smFitAll]) and
      (FGridPrinter.PrintScaleToNumVertPages > 0);
    rbManualScaleFactor.Checked := FGridPrinter.PrintScalingMode = smManual;
    if FGridPrinter.PrintScalingMode = smManual then
      fseScalingFactor.Value := FGridPrinter.PrintScaleFactor;
    seNumPagesHor.Value := FGridPrinter.PrintScaleToNumHorPages;
    seNumPagesVert.Value := FGridPrinter.PrintScaleToNumVertPages;
  end else
    raise Exception.Create('No GridPrinter specified in TGridPrinterScalingForm.');
end;

procedure TGridPrinterScalingForm.UpdateStrings;
begin
  Caption := RSPrintingScaleFactor;
  lblInfo.Caption := RSSelectScaleFactorForPrinting;
  lblScaleFactorInfo.Caption := RSScaleFactorInfo;
  rbManualScaleFactor.Caption := RSManualScaleFactor;
  cbScaleToWidth.Caption := RSScaleGridToWidthOf;
  cbScaleToHeight.Caption := RSScaleGridToHeightOf;
  lblPagesHor.Caption := RSPages;
  lblPagesVert.Caption := RSPages;
end;

end.

