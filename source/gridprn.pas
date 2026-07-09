unit GridPrn;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LCLType, LCLIntf, LCLVersion, Types, Graphics, StdCtrls, Grids,
  Printers, PrintersDlgs;

type
  EGridPrinter = class(Exception);

  TGridPrinter = class;  // forward declaration

  TGridPrnDialog = (gpdNone, gpdPageSetup, gpdPrintDialog, gpdPrinterSetup);

  TGridPrnPrintCellEvent = procedure (Sender: TObject; AGrid: TCustomGrid;
    ACanvas: TCanvas; ACol, ARow: Integer; ARect: TRect) of object;

  TGridPrnGetCellTextEvent = procedure (Sender: TObject; AGrid: TCustomGrid;
    ACol, ARow: Integer; var AText: String) of object;

  TGridPrnGetColCountEvent = procedure (Sender: TObject; AGrid: TCustomGrid;
    var AColCount: Integer) of object;

  TGridPrnGetRowCountEvent = procedure (Sender: TObject; AGrid: TCustomGrid;
    var ARowCount: Integer) of object;

  TGridPrnNewLineEvent = procedure (Sender: TObject; AGrid: TCustomGrid;
    ARow: Integer) of object;

  TGridPrnLinePrintedEvent = procedure (Sender: TObject; AGrid: TCustomGrid;
    ARow, ALastCol: Integer) of object;

  TGridPrnNewPageEvent = procedure (Sender: TObject; AGrid: TCustomGrid;
    APageNo: Integer; AStartCol, AStartRow, AEndCol, AEndRow: Integer) of object;

  TGridPrnManualPageBreakEvent = procedure (Sender: TObject; AGrid: TCustomGrid;
    IsCol: Boolean; AColRowIndex: Integer; var NewPage: Boolean) of object;

  TGridPrnHeaderFooterSection = (hfsLeft, hfsCenter, hfsRight);

  TGridPrnOption = (gpoCenterHor, gpoCenterVert,
    gpoHorGridLines, gpoVertGridLines,
    gpoFixedHorGridLines, gpoFixedVertGridLines,
    gpoHeaderBorderLines, gpoOuterBorderLines
  );
  TGridPrnOptions = set of TGridPrnOption;

const
  DEFAULT_GRIDPRNOPTIONS = [gpoHorGridLines, gpoVertGridLines,
    gpoFixedHorGridLines, gpoFixedVertGridLines, gpoHeaderBorderLines,
    gpoOuterBorderLines];

type
  TGridPrnOrder = (poRowsFirst, poColsFirst);

  TGridPrnOutputDevice = (odPrinter, odPreview);

  TGridPrnScalingMode = (smManual, smFitToWidth, smFitToHeight, smFitAll);

  TGridPrnMargins = class(TPersistent)
  private
    FMargins: array[0..5] of Double;
    FOwner: TGridPrinter;
    function GetMargin(AIndex: Integer): Double;
    function IsStoredMargin(AIndex: Integer): Boolean;
    procedure SetMargin(AIndex: Integer; AValue: Double);
  protected
    procedure Changed;
  public
    constructor Create(AOwner: TGridPrinter);
  published
    property Left: Double index 0 read GetMargin write SetMargin stored IsStoredMargin;
    property Top: Double index 1 read GetMargin write SetMargin stored IsStoredMargin;
    property Right: Double index 2 read GetMargin write SetMargin stored IsStoredMargin;
    property Bottom: Double index 3 read GetMargin write SetMargin stored IsStoredMargin;
    property Header: Double index 4 read GetMargin write SetMargin stored IsStoredMargin;
    property Footer: Double index 5 read GetMargin write SetMargin stored IsStoredMargin;
  end;

  TGridPrnHeaderFooter = class(TPersistent)
  private
    FFont: TFont;
    FFontSize: Integer;
    FLineColor: TColor;
    FLineWidth: Double;
    FShowLine: Boolean;
    FOwner: TGridPrinter;
    FSectionSeparator: String;
    FSectionText: array[TGridPrnHeaderFooterSection] of string;
    FVisible: Boolean;
    function GetProcessedText(AIndex: TGridPrnHeaderFooterSection): String;
    function GetSectionText(AIndex: TGridPrnHeaderFooterSection): String;
    function GetText: String;
    function IsLineWidthStored: Boolean;
    function IsSectionSepStored: Boolean;
    function IsTextStored: Boolean;
    procedure SetFont(AValue: TFont);
    procedure SetLineColor(AValue: TColor);
    procedure SetLineWidth(AValue: Double);
    procedure SetSectionText(AIndex: TGridPrnHeaderFooterSection; AValue: String);
    procedure SetShowLine(AValue: Boolean);
    procedure SetText(AValue: String);
    procedure SetVisible(AValue: Boolean);
  protected
    procedure Changed(Sender: TObject);
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadFontSize(Reader: TReader);
    procedure WriteFontSize(Writer: TWriter);
  public
    constructor Create(AOwner: TGridPrinter);
    destructor Destroy; override;
    function IsShown: Boolean;
    function IsTextEmpty: Boolean;
    function RealLineColor: TColor;
    function RealLineWidth: Integer;
    property FontSize: Integer read FFontSize write FFontSize;
    property ProcessedText[AIndex: TGridPrnHeaderFooterSection]: String read GetProcessedText;
    property SectionText[AIndex: TGridPrnHeaderFooterSection]: String read GetSectionText;
  published
    property Font: TFont read FFont write SetFont;
    property LineColor: TColor read FLineColor write SetLineColor default clDefault;
    property LineWidth: Double read FLineWidth write SetLineWidth stored IsLineWidthStored;
    property SectionSeparator: String read FSectionSeparator write FSectionSeparator stored IsSectionSepStored;
    property ShowLine: Boolean read FShowLine write SetShowLine default true;
    property Text: String read GetText write SetText stored IsTextStored;
    property Visible: Boolean read FVisible write SetVisible default true;
  end;


  { TGridPrinter }

  TGridPrinter = class(TComponent)
  private
    FBorderLineColor: Integer;
    FBorderLineWidth: Double;
    FFixedLineColor: TColor;
    FFixedLineWidth: Double;
    FFromPage: Integer;
    FGrid: TCustomGrid;
    FGridLineColor: TColor;
    FGridLineWidth: Double;
    FHeader: TGridPrnHeaderFooter;
    FFileName: String;      // to be used by header/footer
    FFooter: TGridPrnHeaderFooter;
    FMargins: TGridPrnMargins;
    FMonochrome: Boolean;
    FOptions: TGridPrnOptions;
    FPadding: Integer;
    FPageHeight: Integer;
    FPageWidth: Integer;
    FPreviewPercent: Integer;          // Scaling factor for preview bitmap
    FPrintDateTime: TDateTime;
    FPrintOrder: TGridPrnOrder;
    FPrintScaleFactor: Double;         // Scaling factor for printing
    FPrintScaleToNumHorPages: Integer;
    FPrintScaleToNumVertPages: Integer;
    FPrintScalingMode: TGridPrnScalingMode;
    FShowPrintDialog: TGridPrnDialog;
    FToPage: Integer;
    FOnAfterPrint: TNotifyEvent;
    FOnBeforePrint: TNotifyEvent;
    FOnGetCellText: TGridPrnGetCellTextEvent;
    FOnGetColCount: TGridPrnGetColCountEvent;
    FOnGetRowCount: TGridPrnGetRowCountEvent;
    FOnLinePrinted: TGridPrnLinePrintedEvent;
    FOnManualPageBreak: TGridPrnManualPageBreakEvent;
    FOnNewLine: TGridPrnNewLineEvent;
    FOnNewPage: TGridPrnNewPageEvent;
    FOnPrepareCanvas: TOnPrepareCanvasEvent;
    FOnPrintCell: TGridPrnPrintCellEvent;
    FOnUpdatePreview: TNotifyEvent;
    function GetBorderLineWidthHor: Integer;
    function GetBorderLineWidthVert: Integer;
    function GetCanvas: TCanvas;
    function GetColWidth(AIndex: Integer): Double;
    function GetFixedLineWidthHor: Integer;
    function GetFixedLineWidthVert: Integer;
    function GetGridLineWidthHor: Integer;
    function GetGridLineWidthVert: Integer;
    function GetOrientation: TPrinterOrientation;
    function GetPageCount: Integer;
    function GetPageNumber: Integer;
    function GetRowHeight(AIndex: Integer): Double;
    function IsBorderLineWidthStored: Boolean;
    function IsFixedLineWidthStored: Boolean;
    function IsGridLineWidthStored: Boolean;
    function IsOrientationStored: Boolean;
    function IsPrintScaleFactorStored: Boolean;
    procedure SetBorderLineColor(AValue: TColor);
    procedure SetBorderLineWidth(AValue: Double);
    procedure SetFileName(AValue: String);
    procedure SetFixedLineColor(AValue: TColor);
    procedure SetFixedLineWidth(AValue: Double);
    procedure SetGrid(AValue: TCustomGrid);
    procedure SetGridLineColor(AValue: TColor);
    procedure SetGridLineWidth(AValue: Double);
    procedure SetOptions(AValue: TGridPrnOptions);
    procedure SetOrientation(AValue: TPrinterOrientation);
  protected
    FFactorX: Double;              // Multiply to convert screen to printer/preview pixels
    FFactorY: Double;
    FLeftMargin: Integer;         // Scaled page margins
    FTopMargin: Integer;
    FRightMargin: Integer;
    FBottomMargin: Integer;
    FHeaderMargin: Integer;
    FFooterMargin: Integer;
    FColWidths: array of Double;      // Array of scaled grid column widts
    FRowHeights: array of Double;     // Array of scaled grid row heights
    FFixedColPos: Integer;            // Scaled right end of the fixed cols
    FFixedRowPos: Integer;            // Scaled bottom end of the fixed rows
    FOutputDevice: TGridPrnOutputDevice;
    FPageBreakRows: array of Integer;  // Indices of first row on new page
    FPageBreakCols: array of Integer;  // Indices of first columns on new page
    FPageNumber: Integer;
    FPageCount: Integer;
    FPageRect: TRect;                  // Bounds of printable rectangle
    FPixelsPerInchX: Integer;
    FPixelsPerInchY: Integer;
    FPreviewBitmap: TBitmap;           // Bitmap to which the preview image is printed
    FPreviewPage: Integer;             // Page request for the preview bitmap
    FColCount: Integer;
    FRowCount: Integer;
    FFixedCols: Integer;
    FFixedRows: Integer;
    FPrinting: Boolean;
    procedure CalcFixedColPos(AStartCol, AEndCol: Integer; var ALeft, ARight: Integer);
    procedure CalcFixedRowPos(AStartRow, AEndRow: Integer; var ATop, ABottom: Integer);
    procedure DoLinePrinted(ARow, ALastCol: Integer); virtual;
    function DoManualPageBreak(IsCol: Boolean; AColRow: Integer): Boolean; virtual;
    procedure DoNewLine(ARow: Integer); virtual;
    procedure DoNewPage(AStartCol, AStartRow, AEndCol, AEndRow: Integer); virtual;
    procedure DoPrepareCanvas(ACol, ARow: Integer); virtual;
    procedure DoPrintCell(ACanvas: TCanvas; ACol, ARow: Integer; ARect: TRect;
      var Done: boolean); virtual;
    procedure DoUpdatePreview; virtual;
    procedure Execute(ACanvas: TCanvas);
    function GetBrushColor(AColor: TColor): TColor;
    function GetFontColor(AColor: TColor): TColor;
    function GetPenColor(AColor: TCOlor): TColor;
    procedure LayoutPageBreaks;
    procedure Loaded; override;
    procedure Measure(APageWidth, APageHeight, XDpi, YDpi: Integer);
    procedure NewPage;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Prepare;
    procedure PrepareCanvas(ACanvas: TCanvas; ACol, ARow: Integer); virtual;
    procedure PrintByCols(ACanvas: TCanvas);
    procedure PrintByRows(ACanvas: TCanvas);
    procedure PrintCell(ACanvas: TCanvas; ACol, ARow: Integer; ARect: TRect); virtual;
    procedure PrintCheckbox(ACanvas: TCanvas; {%H-}ACol, {%H-}ARow: Integer; ARect: TRect;
      ACheckState: TCheckboxstate); virtual;
    procedure PrintColHeaders(ACanvas: TCanvas; ACol1, ACol2, Y: Integer);
    procedure PrintFooter(ACanvas: TCanvas);
    procedure PrintHeader(ACanvas: TCanvas);
    procedure PrintHeaderFooter(ACanvas: TCanvas; HF: TGridPrnHeaderFooter);
    procedure PrintGridLines(ACanvas: TCanvas; AStartCol, AStartRow, AEndCol, AEndRow, XEnd, YEnd: Integer);
    procedure PrintPage(ACanvas: TCanvas; AStartCol, AStartRow, AEndCol, AEndRow: Integer);
    procedure PrintRowHeader(ACanvas: TCanvas; ARow: Integer; X, Y: Double);
    procedure ScaleColWidths(AFactor: Double);
    procedure ScaleRowHeights(AFactor: Double);
    procedure SelectFont(ACanvas: TCanvas; AFont: TFont; AScaleFactor: Double = 1.0);
    property OutputDevice: TGridPrnOutputDevice read FOutputDevice;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CreatePreviewBitmap(APageNo, APercentage: Integer): TBitmap;
    function GetCellText(ACol, ARow: Integer): String; virtual;
    procedure Print;
    procedure ScaleToPages(NumHor, NumVert: Integer);
    function ScaleX(AValue: Integer): Integer; inline;
    function ScaleY(AValue: Integer): Integer; inline;
    procedure UpdatePreview;
    property Canvas: TCanvas read GetCanvas;
    property ColCount: Integer read FColCount;
    property ColWidth[AIndex: Integer]: Double read GetColWidth;
    property FooterMargin: Integer read FFooterMargin;
    property HeaderMargin: Integer read FHeaderMargin;
    property PageHeight: Integer read FPageHeight;
    property PageWidth: Integer read FPageWidth;
    property PageRect: TRect read FPageRect;
    property PixelsPerInchX: Integer read FPixelsPerInchX;
    property PixelsPerInchY: Integer read FPixelsPerInchY;
    property Padding: Integer read FPadding;
    property PageCount: Integer read GetPageCount;
    property PageNumber: Integer read FPageNumber;
    property PrintDateTime: TDateTime read FPrintDateTime;
    property PrintScaleToNumHorPages: Integer read FPrintScaleToNumHorPages write FPrintScaleToNumHorPages;
    property PrintScaleToNumVertPages: Integer read FPrintScaleToNumVertPages write FPrintScaleToNumVertPages;
    property PrintScalingMode: TGridPrnScalingMode read FPrintScalingMode write FPrintScalingMode;
    property RowCount: Integer read FRowCount;
    property RowHeight[AIndex: Integer]: Double read GetRowHeight;
  published
    property Grid: TCustomGrid read FGrid write SetGrid;
    property BorderLineColor: TColor read FBorderLineColor write SetBorderLineColor default clDefault;
    property BorderLineWidth: Double read FBorderLineWidth write SetBorderLineWidth stored IsBorderLineWidthStored;
    property FileName: String read FFileName write SetFileName;
    property FixedLineColor: TColor read FFixedLineColor write SetFixedLineColor default clDefault;
    property FixedLineWidth: Double read FFixedLineWidth write SetFixedLineWidth stored IsFixedLineWidthStored;
    property Footer: TGridPrnHeaderFooter read FFooter write FFooter;
    property FromPage: Integer read FFromPage write FFromPage default 0;
    property GridLineColor: TColor read FGridLineColor write SetGridLineColor default clDefault;
    property GridLineWidth: Double read FGridLineWidth write SetGridLineWidth stored IsGridLineWidthStored;
    property Header: TGridPrnHeaderFooter read FHeader write FHeader;
    property Margins: TGridPrnMargins read FMargins write FMargins;
    property Monochrome: Boolean read FMonochrome write FMonochrome default false;
    property Options: TGridPrnOptions read FOptions write SetOptions default DEFAULT_GRIDPRNOPTIONS;
    property Orientation: TPrinterOrientation read GetOrientation write SetOrientation stored IsOrientationStored;
    property PrintOrder: TGridPrnOrder read FPrintOrder write FPrintOrder default poRowsFirst;
    property PrintScaleFactor: Double read FPrintScaleFactor write FPrintScaleFactor stored IsPrintScaleFactorStored;
    property ShowPrintDialog: TGridPrnDialog read FShowPrintDialog write FShowPrintDialog default gpdNone;
    property ToPage: Integer read FToPage write FToPage default 0;
    property OnAfterPrint: TNotifyEvent read FOnAfterPrint write FOnAfterPrint;
    property OnBeforePrint: TNotifyEvent read FOnBeforePrint write FOnBeforePrint;
    property OnGetCellText: TGridPrnGetCellTextEvent read FOnGetCellText write FOnGetCellText;
    property OnGetRowCount: TGridPrnGetRowCountEvent read FOnGetRowCount write FOnGetRowCount;
    property OnGetColCount: TGridPrnGetColCountEvent read FOnGetColCount write FOnGetColCount;
    property OnLinePrinted: TGridPrnLinePrintedEvent read FOnLinePrinted write FOnLinePrinted;  // Finished printing a line
    property OnManualPageBreak: TGridPrnManualPageBreakEvent read FOnManualPageBreak write FOnManualPageBreak;
    property OnNewLine: TGridPrnNewLineEvent read FOnNewLine write FOnNewLine;  // Started printing a new row of cells.
    property OnNewPage: TGridPrnNewPageEvent read FOnNewPage write FOnNewPage;  // Started printing a new page
    property OnPrepareCanvas: TOnPrepareCanvasEvent read FOnPrepareCanvas write FOnPrepareCanvas;
    property OnPrintCell: TGridPrnPrintCellEvent read FOnPrintCell write FOnPrintCell;
    property OnUpdatePreview: TNotifyEvent read FOnUpdatePreview write FOnUpdatePreview;
  end;

function mm2px(mm: Double; dpi: Integer): Integer;
function px2mm(px: Integer; dpi: Integer): Double;

implementation

uses
  Dialogs, OSPrinters, Themes, Math;

type
  TGridAccess = class(TCustomGrid);

const
  INCH = 25.4;    // 1" = 25.4 mm

  DefaultTextStyle: TTextStyle = (
    Alignment: taLeftJustify;
    Layout: tlCenter;
    SingleLine: true;
    Clipping: true;
    ExpandTabs: false;
    ShowPrefix: false;
    WordBreak: false;
    Opaque: false;
    SystemFont: false;
    RightToLeft: false;
    EndEllipsis: false
  );

function IfThen(cond: Boolean; a, b: Integer): Integer;
begin
  if cond then Result := a else Result := b;
end;

function IfThen(cond: Boolean; a, b: TColor): TColor;
begin
  if cond then Result := a else Result := b;
end;

function DefaultFontSize(AFont: TFont): Integer;
var
  fontData: TFontData;
begin
  fontData := GetFontData(AFont.Reference.Handle);
  Result := abs(fontData.Height) * 72 div ScreenInfo.PixelsPerInchY;
end;

procedure FixFontSize(AFont: TFont);
begin
  if AFont.Size = 0 then
    AFont.Size := DefaultFontSize(AFont);
end;

function mm2px(mm: Double; dpi: Integer): Integer;
begin
  Result := round(mm/INCH * dpi);
end;

function px2mm(px: Integer; dpi: Integer): Double;
begin
  Result := px * INCH / dpi;
end;


{ TGridPrnMargins }

constructor TGridPrnMargins.Create(AOwner: TGridPrinter);
var
  i: Integer;
begin
  inherited Create;
  FOwner := AOwner;
  for i := 0 to 3 do FMargins[i] := 20.0;
  for i := 4 to 5 do FMargins[i] := 10.0;
end;

procedure TGridPrnMargins.Changed;
begin
  if (FOwner <> nil) then
    FOwner.UpdatePreview;
end;

function TGridPrnMargins.GetMargin(AIndex: Integer): Double;
begin
  Result := FMargins[AIndex];
end;

function TGridPrnMargins.IsStoredMargin(AIndex: Integer): Boolean;
begin
  case AIndex of
    0..3: Result := FMargins[AIndex] <> 20.0;
    4..5: Result := FMargins[AIndex] <> 10.0;
  end;
end;

procedure TGridPrnMargins.SetMargin(AIndex: Integer; AValue: Double);
begin
  if FMargins[AIndex] <> AValue then
  begin
    FMargins[AIndex] := AValue;
    Changed;
  end;
end;


{ TGridPrnHeaderFooter }

constructor TGridPrnHeaderFooter.Create(AOwner: TGridPrinter);
begin
  inherited Create;
  FOwner := AOwner;

  FSectionSeparator := '|';

  FFont := TFont.Create;
  FixFontSize(FFont);
  FFont.Size := FFont.Size - 1;
  FFont.OnChange := @Changed;

  FLineColor := clDefault;
  FLineWidth := 0;
  FShowLine := true;
  FVisible := true;
end;

destructor TGridPrnHeaderFooter.Destroy;
begin
  FFont.Free;
  inherited;
end;

procedure TGridPrnHeaderFooter.Changed(Sender: TObject);
begin
  if (FOwner <> nil) then
    FOwner.UpdatePreview;
end;

{ Since TGridPrinter does not descend from TControl it does not react on
  LCLScaling. The problem is that the header/footer font size does not
  scale correctly because the PixelsPerInch are always applied without scaling
  the height. A workaround is to store the FontSize separately so that it is
  not affected by the changed PPI, and to apply it to the Font.Size in the
  GridPrinter's Loaded procedure. }
procedure TGridPrnHeaderFooter.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('FontSize', @ReadFontSize, @WriteFontSize, true);
end;

function TGridPrnHeaderFooter.GetProcessedText(AIndex: TGridPrnHeaderFooterSection): String;
const
  UNKNOWN = '<unknown>';

  procedure Replace(AParam: String);
  var
    s: String;
  begin
    if FOwner <> nil then
      case AParam of
        '$PAGECOUNT': s := IntToStr(FOwner.PageCount);
        '$PAGE': s := IntToStr(FOwner.PageNumber);
        '$FULL_FILENAME': s := ExpandFileName(FOwner.FileName);
        '$FILENAME': s := ExtractFileName(FOwner.FileName);
        '$PATH': s := ExtractFilePath(ExpandFileName(FOwner.FileName));
      end
    else
      s := UNKNOWN;
    Result := StringReplace(Result, AParam, s, [rfReplaceAll, rfIgnoreCase]);
  end;

begin
  Result := FSectionText[AIndex];
  Result := StringReplace(Result, '$DATE', DateToStr(FOwner.PrintDateTime), [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '$TIME', TimeToStr(FOwner.PrintDateTime), [rfReplaceAll, rfIgnoreCase]);
  Replace('$PAGECOUNT');
  Replace('$PAGE');
  Replace('$FULL_FILENAME');
  Replace('$FILENAME');
  Replace('$PATH');
end;

function TGridPrnHeaderFooter.GetSectionText(AIndex: TGridPrnHeaderFooterSection): String;
begin
  Result := FSectionText[AIndex];
end;

function TGridPrnHeaderFooter.GetText: String;
begin
  Result :=
    FSectionText[hfsLeft] + FSectionSeparator +
    FSectionText[hfsCenter] + FSectionSeparator +
    FSectionText[hfsRight];
end;

function TGridPrnHeaderFooter.IsLineWidthStored: Boolean;
begin
  Result := FLineWidth > 0;
end;

function TGridPrnHeaderFooter.IsSectionSepStored: Boolean;
begin
  Result := FSectionSeparator <> '|';
end;

function TGridPrnHeaderFooter.IsShown: Boolean;
begin
  Result := FVisible and not IsTextEmpty;
end;

function TGridPrnHeaderFooter.IsTextEmpty: Boolean;
begin
  Result :=
    (FSectionText[hfsLeft] = '') and
    (FSectionText[hfsCenter] = '') and
    (FSectionText[hfsRight] = '');
end;

function TGridPrnHeaderFooter.IsTextStored: Boolean;
begin
  Result := not IsTextEmpty;
end;

procedure TGridPrnHeaderFooter.ReadFontSize(Reader: TReader);
begin
  FFontSize := Reader.ReadInteger;
end;

function TGridPrnHeaderFooter.RealLineColor: TColor;
begin
  if ((FOwner <> nil) and FOwner.Monochrome) or (FLineColor = clDefault) then
    Result := clBlack
  else
    Result := FLineColor;
end;

function TGridPrnHeaderFooter.RealLineWidth: Integer;
begin
  if FLineWidth <= 0 then
    Result := FOwner{%H-}.ScaleY(1)
  else
    Result := mm2px(FLineWidth/FOwner.PrintScaleFactor, FOwner.PixelsPerInchY);
end;

procedure TGridPrnHeaderFooter.SetFont(AValue: TFont);
begin
  FFont.Assign(AValue);
  Changed(nil);
end;

procedure TGridPrnHeaderFooter.SetLineColor(AValue: TColor);
begin
  if FLineColor <> AValue then
  begin
    FLineColor := AValue;
    Changed(nil);
  end;
end;

procedure TGridPrnHeaderFooter.SetLineWidth(AValue: Double);
begin
  if FLineWidth <> AValue then
  begin
    FLineWidth := AValue;
    Changed(nil);
  end;
end;

procedure TGridPrnHeaderFooter.SetSectionText(AIndex: TGridPrnHeaderFooterSection;
  AValue: String);
begin
  if FSectionText[AIndex] <> AValue then
  begin
    FSectionText[AIndex] := AValue;
    Changed(nil);
  end;
end;

procedure TGridPrnHeaderFooter.SetShowLine(AValue: Boolean);
begin
  if FShowLine <> AValue then
  begin
    FShowLine := AValue;
    Changed(nil);
  end;
end;

procedure TGridPrnHeaderFooter.SetText(AValue: String);
var
  sa: TStringArray;
begin
  if GetText = AValue then
    exit;
  sa := AValue.Split([FSectionSeparator]);
  if Length(sa) > 0 then FSectionText[hfsLeft] := sa[0] else FSectionText[hfsLeft] := '';
  if Length(sa) > 1 then FSectionText[hfsCenter] := sa[1] else FSectionText[hfsCenter] := '';
  if Length(sa) > 2 then FSectionText[hfsRight] := sa[2] else FSectionText[hfsRight] := '';
  Changed(self);
end;

procedure TGridPrnHeaderFooter.SetVisible(AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;
    Changed(self);
  end;
end;

procedure TGridPrnHeaderFooter.WriteFontSize(Writer: TWriter);
begin
  FFontSize := FFont.Size;
  Writer.WriteInteger(FFontSize);
end;


{ TGridPrinter }

constructor TGridPrinter.Create(AOwner: TComponent);
begin
  inherited;

  FMargins := TGridPrnMargins.Create(Self);
  FHeader := TGridPrnHeaderFooter.Create(Self);
  FFooter := TGridPrnHeaderFooter.Create(Self);

  FOptions := DEFAULT_GRIDPRNOPTIONS;
  FPrintOrder := poRowsFirst;
  FPrintScaleFactor := 1.0;
  FPrintScaleToNumHorPages := 1;
  FPrintScaleToNumVertPages := 1;
  FBorderLineColor := clDefault;
  FFixedLineColor := clDefault;
  FGridLineColor := clDefault;
  FBorderLineWidth := -1;
  FFixedLineWidth := -1;
  FGridLineWidth := -1;
end;

destructor TGridPrinter.Destroy;
begin
  FHeader.Free;
  FFooter.Free;
  FMargins.Free;
  inherited;
end;

{ Calculates the extent (in printer/preview pixels) of the fixed ccolumns
  (left edge of first and right edge of last fixed column).
  Takes care of the optional horizontal centering of the grid. }
procedure TGridPrinter.CalcFixedColPos(AStartCol, AEndCol: Integer;
  var ALeft, ARight: Integer);
var
  col: Integer;
  w: Double;
  fixedColsWidth: Integer;
begin
  if (gpoCenterHor in FOptions) then
  begin
    // Total width of all fixed columns
    fixedColsWidth := FFixedColPos - FLeftMargin;
    w := fixedColsWidth;
    for col := AStartCol to AEndCol do
      w := w + FColWidths[col];
    // w is total column width on this page
    ALeft := FLeftMargin + round((FPageRect.Width - w) / 2);
    ARight := ALeft + fixedColsWidth;
  end else
  begin
    ALeft := FLeftMargin;
    ARight := FFixedColPos;
  end;
end;

{ Calculates the extent (in printer/preview pixels) of the fixed rows
  (top edge of first and bottom edge of last fixed row).
  Takes care of the optional vertical centering of the grid. }
procedure TGridPrinter.CalcFixedRowPos(AStartRow, AEndRow: Integer;
  var ATop, ABottom: Integer);
var
  row: Integer;
  h: Double;
  fixedRowsHeight: Integer;
begin
  if (gpoCenterVert in FOptions) then
  begin
    // Total height of all fixed rows
    fixedRowsheight := FFixedRowPos - FTopMargin;
    h := fixedRowsHeight;
    for row := AStartRow to AEndRow do
      h := h + FRowHeights[row];
    // h is total row height on this page
    ATop := FTopMargin + round((FPageRect.Height - h) / 2);
    ABottom := ATop + fixedRowsHeight;
  end else
  begin
    ATop := FTopMargin;
    ABottom := FFixedRowPos;
  end;
end;


function TGridPrinter.CreatePreviewBitmap(APageNo, APercentage: Integer): TBitmap;
begin
  if FGrid = nil then
  begin
    Result := nil;
    exit;
  end;

  FOutputDevice := odPreview;

  FPreviewPercent := APercentage;
  FPreviewPage := APageNo;  // out-of-range values are handled by Prepare
  SetGrid(FGrid);
  Prepare;

  FPreviewBitmap := TBitmap.Create;
  FPreviewBitmap.SetSize(FPageWidth, FPageHeight);
  FPreviewBitmap.Canvas.Brush.Color := clWhite;
  FPreviewBitmap.Canvas.FillRect(0, 0, FPageWidth, FPageHeight);

  Execute(FPreviewBitmap.Canvas);

  Result := FPreviewBitmap;
end;

procedure TGridPrinter.DoLinePrinted(ARow, ALastCol: Integer);
begin
  if Assigned(FOnLinePrinted) then
    FOnLinePrinted(Self, FGrid, ARow, ALastCol);
end;

function TGridPrinter.DoManualPageBreak(IsCol: Boolean; AColRow: Integer): Boolean;
begin
  Result := false;
  if Assigned(OnManualPageBreak) then
    OnManualPageBreak(Self, FGrid, IsCol, AColRow, Result);
end;

procedure TGridPrinter.DoNewLine(ARow: Integer);
begin
  if Assigned(FOnNewLine) then
    FOnNewLine(Self, FGrid, ARow);
end;

procedure TGridPrinter.DoNewPage(AStartCol, AStartRow, AEndCol, AEndRow: Integer);
begin
  if Assigned(FOnNewPage) then
    FOnNewPage(Self, FGrid, FPageNumber, AStartCol, AStartRow, AEndCol, AEndRow);
end;

procedure TGridPrinter.DoPrepareCanvas(ACol, ARow: Integer);
begin
  if Assigned(FOnPrepareCanvas) then
    FOnPrepareCanvas(Self, ACol, ARow, []);
end;

procedure TGridPrinter.DoPrintCell(ACanvas: TCanvas; ACol, ARow: Integer;
  ARect: TRect; var Done: Boolean);
begin
  if Assigned(FOnPrintCell) then
  begin
    FOnPrintCell(Self, FGrid, ACanvas, ACol, ARow, ARect);
    Done := true;
  end else
    Done := false;
end;

procedure TGridPrinter.DoUpdatePreview;
begin
  if Assigned(FOnUpdatePreview) and (FOutputDevice = odPreview) then
    FOnUpdatePreview(Self);
end;

procedure TGridPrinter.Execute(ACanvas: TCanvas);
begin
  FPrinting := true;
  if Assigned(FOnBeforePrint) then
    FOnBeforePrint(Self);
  case FPrintOrder of
    poRowsFirst: PrintByRows(ACanvas);
    poColsFirst: PrintByCols(ACanvas);
  end;
  if Assigned(FOnAfterPrint) then
    FOnAfterPrint(Self);
  FPrinting := false;
end;

function TGridPrinter.GetBorderLineWidthHor: Integer;
begin
  if FBorderLineWidth < 0.0 then
    Result := {%H-}ScaleY(2)
  else
    Result := mm2px(FBorderLineWidth, FPixelsPerInchY);
end;

function TGridPrinter.GetBorderLineWidthVert: Integer;
begin
  if FBorderLineWidth < 0.0 then
    Result := {%H-}ScaleX(2)
  else
    Result := mm2px(FBorderLineWidth, FPixelsPerInchX);
end;

// Returns a bright brush even in dark mode
function TGridPrinter.GetBrushColor(AColor: TColor): TColor;
begin
  if (AColor = clDefault) or (AColor = clWindow) or FMonochrome then
    Result := clWhite
  else
    Result := ColorToRGB(AColor);
end;

// Returns a dark pen, even in dark mode
function TGridPrinter.GetFontColor(AColor: TColor): TColor;
begin
  if (AColor = clDefault) or (AColor = clWindowText) or FMonochrome then
    Result := clBlack
  else
    Result := ColorToRGB(AColor);
end;

// Returns a dark font, even in dark mode
function TGridPrinter.GetPenColor(AColor: TCOlor): TColor;
begin
  if (AColor = clDefault) or (AColor = clWindowText) or FMonochrome then
    Result := clBlack
  else
    Result := ColorToRGB(AColor);
end;

function TGridPrinter.GetCanvas: TCanvas;
begin
  if FPrinting then
    case FOutputDevice of
      odPrinter: Result := Printer.Canvas;
      odPreview: Result := FPreviewBitmap.Canvas;
    end
  else
    Result := nil;
end;

function TGridPrinter.GetColWidth(AIndex: Integer): Double;
begin
  Result := FColWidths[AIndex];
end;

function TGridPrinter.GetCellText(ACol, ARow: Integer): String;
var
  col: TGridColumn;
  lGrid: TGridAccess;
begin
  Result := '';
  if FGrid = nil then
    exit;

  lGrid := TGridAccess(FGrid);
  if (ACol = 0) and (FFixedCols > 0) and (ARow >= FFixedRows) and (goFixedRowNumbering in lGrid.Options) then
  begin
    Result := IntToStr(ARow - FFixedRows + 1);
    exit;
  end;

  if lGrid.Columns.Enabled and (ACol >= FFixedCols) and (ARow = 0) and (FFixedRows > 0) then
  begin
    col := lGrid.Columns[ACol - FFixedCols];
    Result := col.Title.Caption;
    exit;
  end;

  if Assigned(FOnGetCellText) then
    FOnGetCellText(self, FGrid, ACol, ARow, Result)
  else
    Result := lGrid.GetCells(Acol, ARow);
end;

function TGridPrinter.GetFixedLineWidthHor: Integer;
begin
  if FFixedLineWidth < 0.0 then
    Result := {%H-}ScaleY(TGridAccess(FGrid).GridLineWidth)
  else
    Result := mm2px(FFixedLineWidth, FPixelsPerInchY);
end;

function TGridPrinter.GetFixedLineWidthVert: Integer;
begin
  if FFixedLineWidth < 0.0 then
    Result := {%H-}ScaleX(TGridAccess(FGrid).GridLineWidth)
  else
    Result := mm2px(FFixedLineWidth, FPixelsPerInchX);
end;

function TGridPrinter.GetGridLineWidthHor: Integer;
begin
  if FGridLineWidth < 0.0 then
    Result := {%H-}ScaleY(TGridAccess(FGrid).GridLineWidth)
  else
    Result := mm2px(FGridLineWidth, FPixelsPerInchY);
end;

function TGridPrinter.GetGridLineWidthVert: Integer;
begin
  if FGridLineWidth < 0.0 then
    Result := {%H-}ScaleX(TGridAccess(FGrid).GridLineWidth)
  else
    Result := mm2px(FGridLineWidth, FPixelsPerInchX);
end;

function TGridPrinter.GetOrientation: TPrinterOrientation;
begin
  Result := Printer.Orientation;
end;

function TGridPrinter.GetPageCount: Integer;
begin
  if FPageCount = 0 then
    Prepare;
  Result := FPageCount;
end;

function TGridPrinter.GetPageNumber: Integer;
begin
  if FPageNumber <= 0 then
    Prepare;
  Result := FPageNumber;
end;

function TGridPrinter.GetRowHeight(AIndex: Integer): Double;
begin
  Result := FRowHeights[AIndex];
end;

function TGridPrinter.IsBorderLineWidthStored: Boolean;
begin
  Result := FBorderLineWidth >= 0.0;
end;

function TGridPrinter.IsFixedLineWidthStored: Boolean;
begin
  Result := FFixedLineWidth >= 0.0;
end;

function TGridPrinter.IsGridLineWidthStored: Boolean;
begin
  Result := FGridLineWidth >= 0.0;
end;

function TGridPrinter.IsOrientationStored: Boolean;
begin
  Result := GetOrientation <> poPortrait;
end;

function TGridPrinter.IsPrintScaleFactorStored: Boolean;
begin
  Result := FPrintScaleFactor <> 1.0;
end;

{ Find the column and row indices before which page breaks are occuring.
  Store them in the arrays FPageBreakCols and FPageBreakRows.
  Note that the indices do not contain the fixed columns/rows. }
procedure TGridPrinter.LayoutPageBreaks;
var
  col, row: Integer;
  n: Integer;
  totalWidth, totalHeight: Double;
begin
  // Scanning horizontally --> get page break column indices
  SetLength(FPageBreakCols, FColCount);
  n := 0;
  totalWidth := FFixedColPos;
  FPageBreakCols[0] := FFixedCols;
  for col := FFixedCols to FColCount-1 do
  begin
    totalWidth := totalWidth + FColWidths[col];
    if ((totalWidth - FPageRect.Right) >= 1) or DoManualPageBreak(true, col) then  // allow 1 pixel for rounding error
    begin
      inc(n);
      FPageBreakCols[n] := col;
      totalWidth := FFixedColPos + FColWidths[col];
    end;
  end;
  SetLength(FPageBreakCols, n+1);

  // Scanning vertically --> get page break row indices
  SetLength(FPageBreakRows, FRowCount);
  n := 0;
  totalHeight := FFixedRowPos;
  FPageBreakRows[0] := FFixedRows;
  for row := FFixedRows to FRowCount-1 do
  begin
    totalHeight := totalHeight + FRowHeights[row];
    if (totalHeight > FPageRect.Bottom) or DoManualPageBreak(false, row) then
    begin
      inc(n);
      FPageBreakRows[n] := row;
      totalHeight := FFixedRowPos + FRowHeights[row];
    end;
  end;
  SetLength(FPageBreakRows, n+1);

  FPageCount := Length(FPageBreakCols) * Length(FPageBreakRows);
end;

procedure TGridPrinter.Loaded;
begin
  inherited;
  // The next lines override the change of Font.Size because LCLScaling does
  // not apply here.
  FHeader.Font.Size := FHeader.FontSize;
  FFooter.Font.Size := FFooter.FontSize;
end;

{ Converts length properties to the specified pixel density. }
procedure TGridPrinter.Measure(APageWidth, APageHeight, XDpi, YDpi: Integer);
begin
  // Multiplication factor needed by ScaleX and ScaleY
  FFactorX := XDpi / ScreenInfo.PixelsPerInchX * FPrintScaleFactor;
  FFactorY := YDpi / ScreenInfo.PixelsPerInchY * FPrintScaleFactor;

  // Margins in the new pixel density units.
  FLeftMargin := mm2px(FMargins.Left, XDpi);
  FTopMargin := mm2px(FMargins.Top, YDpi);
  FRightMargin := mm2px(FMargins.Right, XDpi);
  FBottomMargin := mm2px(FMargins.Bottom, YDpi);
  FHeaderMargin := mm2px(FMargins.Header, YDpi);
  FFooterMargin := mm2px(FMargins.Footer, YDpi);
  FPageRect := Rect(FLeftMargin, FTopMargin, APageWidth - FRightMargin, APageHeight - FBottomMargin);
  FPadding := {%H-}ScaleX(varCellPadding);

  // Calculates column widths and row heights in the new pixel density units
  ScaleColWidths(FFactorX);
  ScaleRowHeights(FFactorY);
end;

procedure TGridPrinter.NewPage;
begin
  if FOutputDevice = odPrinter then
    Printer.NewPage;
end;

procedure TGridPrinter.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FGrid then
      FGrid := nil;
  end;
end;

procedure TGridPrinter.Prepare;
begin
  // Calculate grid indices at which page breaks occur. Since the font size is
  // an integer, the zoomed preview may have slightly different values - which
  // is not desired. Therefore, we calculate this for the printer resolution.
  Measure(Printer.PageWidth, Printer.PageHeight, Printer.XDPI, Printer.YDPI);
  LayoutPagebreaks;

  case FOutputDevice of
    odPrinter:
      begin
        FPixelsPerInchX := Printer.XDPI;
        FPixelsPerInchY := Printer.YDPI;
        FPageWidth := Printer.PageWidth;
        FPageHeight := Printer.PageHeight;
      end;
    odPreview:
      begin
        if FPreviewPercent = 0 then
          exit;
        FPixelsPerInchX := ScreenInfo.PixelsPerInchX * FPreviewPercent div 100;
        FPixelsPerInchY := ScreenInfo.PixelsPerInchY * FPreviewPercent div 100;
        FPageWidth := round(Printer.PageWidth * FPixelsPerInchX / Printer.XDPI);
        FPageHeight := round(Printer.PageHeight * FPixelsPerInchY / Printer.YDPI);
        // Recalculates page dimensions and col/row sizes, now based on
        // the "real" ppi of the preview.
        Measure(FPageWidth, FPageHeight, FPixelsPerInchX, FPixelsPerInchY);
      end;
  end;

  // Stores the current date/time so that all pages have the same date/time
  // in the header/footer.
  FPrintDateTime := Now();
end;

procedure TGridPrinter.PrepareCanvas(ACanvas: TCanvas; ACol, ARow: Integer);
var
  lGrid: TGridAccess;
  col: TGridColumn;
  textStyle: TTextStyle;
  font: TFont;
begin
  lGrid := TGridAccess(FGrid);

  // Background color
  ACanvas.Brush.Style := bsSolid;
  if (ACol < FFixedCols) or (ARow < FFixedRows) then
    ACanvas.Brush.Color := GetBrushColor(IfThen(lGrid.FixedColor = clBtnFace, $E0E0E0, lGrid.FixedColor))
  else
  if lGrid.Columns.Enabled and (ACol >= FFixedCols) then
  begin
    col := lGrid.Columns[ACol - FFixedCols];
    ACanvas.Brush.Color := GetBrushColor(col.Color);
  end else
  begin
    if Odd(ARow) then
      ACanvas.Brush.Color := GetBrushColor(lGrid.Color)
    else
      ACanvas.Brush.Color := GetBrushColor(lGrid.AlternateColor);
  end;

  // Font
  if lGrid.Columns.Enabled and (ACol >= FFixedCols) then
  begin
    col := lGrid.Columns[ACol - FFixedCols];
    if (ARow < FFixedRows) then
      font := col.Title.Font
    else
      font := col.Font;
    SelectFont(ACanvas, font, FPrintScaleFactor);
    ACanvas.Font.Color := GetFontColor(font.Color);
  end else
  begin
    SelectFont(ACanvas, lGrid.Font, FPrintScaleFactor);
    ACanvas.Font.Color := GetFontColor(lGrid.Font.Color);
  end;
  FixFontSize(ACanvas.Font);

  // Text style
  textStyle := DefaultTextStyle;
  if lGrid.Columns.Enabled and (ACol >= FFixedCols) then
  begin
    col := lGrid.Columns[ACol - FFixedCols];
    if (ARow < FFixedRows) then
    begin
      textStyle.Alignment := col.Title.Alignment;
      textStyle.Layout := col.Title.Layout;
      if col.Title.MultiLine then
      begin
        textStyle.Wordbreak := true;
        textStyle.SingleLine := false;
        textStyle.EndEllipsis := false;
      end;
    end else
    begin
      textStyle.Alignment := col.Alignment;
      textStyle.Layout := col.Layout;
    end;
  end;
  if (goCellEllipsis in lGrid.Options) then
    textStyle.EndEllipsis := true;
  ACanvas.TextStyle := textStyle;

  // Fire the event OnPrepareCanvas
  DoPrepareCanvas(ACol, ARow);
end;

procedure TGridPrinter.Print;
var
  pageDlg: TPageSetupDialog;
  printDlg: TPrintDialog;
  prnSetupDlg: TPrinterSetupDialog;
begin
  if FGrid = nil then
    exit;

  if Printer.Printers.Count = 0 then
    raise EPrinter.Create('No printer defined.');

  SetGrid(FGrid);

  case FShowPrintDialog of
    gpdNone:
      ;
    gpdPageSetup:
      begin
        pageDlg := TPageSetupDialog.Create(nil);
        try
          pageDlg.Units := pmMillimeters;
          pageDlg.MarginLeft := round(FMargins.Left*100);
          pageDlg.MarginTop := round(FMargins.Top*100);
          pageDlg.MarginRight := round(FMargins.Right*100);
          pageDlg.MarginBottom := round(FMargins.Bottom*100);
          if pageDlg.Execute then
          begin
            FMargins.FMargins[0] := pageDlg.MarginLeft*0.01;
            FMargins.FMargins[1] := pageDlg.MarginTop*0.01;
            FMargins.FMargins[2] := pageDlg.MarginRight*0.01;
            FMargins.FMargins[3] := pageDlg.MarginBottom*0.01;
            FFromPage := 0;     // all pages
            FToPage := 0;
          end else
            exit;
        finally
          pageDlg.Free;
        end;
      end;
    gpdPrintDialog:
      begin
        printDlg := TPrintDialog.Create(nil);
        try
          printDlg.MinPage := 1;
          printDlg.MaxPage := PageCount;
          printDlg.Options := printDlg.Options + [poPageNums];
          if printDlg.Execute then
          begin
            Printer.Copies := printDlg.Copies;
            if printDlg.PrintRange = prAllPages then
            begin
              FFromPage := 0;    // all pages
              FToPage := 0;
            end else
            begin
              FFromPage := printDlg.FromPage;
              FToPage := printDlg.ToPage;
            end;
          end else
            exit;
        finally
          printDlg.Free;
        end;
      end;
    gpdPrinterSetup:
      begin
        prnSetupDlg := TPrinterSetupDialog.Create(nil);
        try
          if prnSetupDlg.Execute then
          begin
            //
          end else
            exit;
        finally
          prnSetupDlg.Free;
        end;
      end;
  end;

  FOutputDevice := odPrinter;
  Prepare;
  Printer.BeginDoc;
  try
    Execute(Printer.Canvas);
  finally
    Printer.EndDoc;
  end;
end;

{ Advances first along rows when handling page-breaks. }
procedure TGridPrinter.PrintByCols(ACanvas: TCanvas);
var
  vertPage, horPage: Integer;
  col1, col2: Integer;
  row1, row2, row: Integer;
  firstPrintPage, lastPrintPage: Integer;
  printThisPage: Boolean;
begin
  firstPrintPage := IfThen((FFromPage < 1) or (FFromPage > FPageCount), 1, FFromPage);
  lastPrintPage := IfThen((FToPage < 1) or (FToPage > FPageCount), FPageCount, FToPage);

  SelectFont(ACanvas, FGrid.Font, FPrintScaleFactor);
  FPageNumber := 1;

  for horPage := 0 to High(FPageBreakCols) do
  begin
    col1 := FPageBreakCols[horPage];
    if horPage < High(FPageBreakCols) then
      col2 := FPageBreakCols[horPage+1] - 1
    else
      col2 := FColCount-1;

    for vertPage := 0 to High(FPageBreakRows) do
    begin
      row1 := FPageBreakRows[vertPage];
      if vertPage < High(FPageBreakRows) then
        row2 := FPageBreakRows[vertPage+1] - 1
      else
        row2 := FRowCount-1;
      // Print page beginning at col1/row1
      case FOutputDevice of
        odPrinter:  // Render all requested pages
          printThisPage := (FPageNumber >= firstPrintPage) and (FPageNumber <= lastPrintPage);
        odPreview:  // Preview can render only a single page
          printThisPage := (FPageNumber = FPreviewPage);
        else
          raise EGridPrinter.Create('[TGridPrinter.PrintByCols] Unknown output device.');
      end;
      DoNewPage(col1, row1, col2, row2);
      if printThisPage then
        PrintPage(ACanvas, col1, row1, col2, row2)
      else
        for row := row1 to row2 do
          DoLinePrinted(row, col2);
      inc(FPageNumber);
    end;
  end;
end;

{ Advances first along columns when handling page-breaks. }
procedure TGridPrinter.PrintByRows(ACanvas: TCanvas);
var
  vertPage, horPage: Integer;
  col1, col2: Integer;
  row1, row2, row: Integer;
  firstPrintPage, lastPrintPage: Integer;
  printThisPage: Boolean;
begin
  firstPrintPage := IfThen((FFromPage < 1) or (FFromPage > FPageCount), 1, FFromPage);
  lastPrintPage := IfThen((FToPage < 1) or (FToPage > FPageCount), FPageCount, FToPage);

  SelectFont(ACanvas, FGrid.Font, FPrintScaleFactor);
  FPageNumber := 1;

  for vertPage := 0 to High(FPageBreakRows) do
  begin
    row1 := FPageBreakRows[vertPage];
    if vertPage < High(FPageBreakRows) then
      row2 := FPageBreakRows[vertPage+1] - 1
    else
      row2 := FRowCount-1;

    for horPage := 0 to High(FPageBreakCols) do
    begin
      col1 := FPageBreakCols[horPage];
      if horPage < High(FPageBreakCols) then
        col2 := FPageBreakCols[horPage+1] - 1
      else
        col2 := FColCount-1;
      // Print the page beginning at col1/row1
      case FOutputDevice of
        odPrinter:  // Render all requested pages
          printThisPage := (FPageNumber >= firstPrintPage) and (FPageNumber <= lastPrintPage);
        odPreview:  // Preview can render only a single page
          printThisPage := (FPageNumber = FPreviewPage);
        else
          raise EGridPrinter.Create('[TGridPrinter.PrintByRows] Unknown output device.');
      end;
      DoNewPage(col1, row1, col2, row2);
      if printThisPage then
        PrintPage(ACanvas, col1, row1, col2, row2)
      else
        for row := row1 to row2 do
          DoLinePrinted(row, col2);
      inc(FPageNumber);
    end;
  end;
end;

{ Prints the cell at ACol/ARow. The cell will appear in the given rectangle. }
procedure TGridPrinter.PrintCell(ACanvas: TCanvas; ACol, ARow: Integer;
  ARect: TRect);
var
  s: String;
  col: TGridColumn;
  lGrid: TGridAccess;
  checkedState: TCheckboxState;
  done: Boolean = false;
begin
  DoPrintCell(ACanvas, ACol, ARow, ARect, done);
  if done then
    exit;

  lGrid := TGridAccess(FGrid);

  PrepareCanvas(ACanvas, ACol, ARow);
  if not FMonochrome then
    ACanvas.FillRect(ARect);

  s := GetCellText(ACol, ARow);
  InflateRect(ARect, -FPadding, 0);

  // Handle checkbox columns
  if lGrid.Columns.Enabled and (ACol >= FFixedCols) and (ARow >= FFixedRows) then
  begin
    col := lGrid.Columns[ACol - FFixedCols];
    if col.Buttonstyle = cbsCheckboxColumn
    then begin
      if s = col.ValueChecked then
        checkedState := cbChecked
      else
      if s = col.ValueUnChecked then
        checkedState := cbUnchecked
      else
        checkedState := cbGrayed;
      PrintCheckbox(ACanvas, ACol, ARow, ARect, checkedState);
      exit;
    end;
  end;

  // Normal text output
  ACanvas.TextRect(ARect, ARect.Left, ARect.Top, s);
end;

procedure TGridPrinter.PrintCheckbox(ACanvas: TCanvas; ACol, ARow: Integer;
  ARect: TRect; ACheckState: TCheckboxstate);
const
  arrtb:array[TCheckboxState] of TThemedButton =
    (tbCheckBoxUncheckedNormal, tbCheckBoxCheckedNormal, tbCheckBoxMixedNormal);
var
  details: TThemedElementDetails;
  cSize: TSize;
  R: TRect;
  P: Array[0..2] of TPoint;
begin
  // Determine size of checkbox
  details := ThemeServices.GetElementDetails(arrtb[ACheckState]);
  {$IF LCL_FullVersion >= 2030000}
  cSize := ThemeServices.GetDetailSizeForPPI(Details, ScreenInfo.PixelsPerInchX);
  {$ELSE}
  cSize := ThemeServices.GetDetailSize(Details);
  {$IFEND}
  cSize.cx := {%H-}ScaleX(cSize.cx);
  cSize.cy := {%H-}ScaleY(cSize.cy);
  // Position the checkbox within the given rectangle, ARect.
  case ACanvas.TextStyle.Alignment of
    taLeftJustify: R.Left := ARect.Left + FPadding;
    taCenter: R.Left := (ARect.Left + ARect.Right - cSize.cx) div 2;
    taRightJustify: R.Left := ARect.Right - cSize.cx - FPadding;
  end;
  case ACanvas.TextStyle.Layout of
    tlTop: R.Top := ARect.Top + FPadding;
    tlCenter: R.Top := (ARect.Top + ARect.Bottom - cSize.cy) div 2;
    tlBottom: R.Top := ARect.Bottom - cSize.cy - FPadding;
  end;
  R.BottomRight := Point(R.Left + cSize.cx, R.Top + cSize.cy);
  // Prepare pen and brush
  ACanvas.Pen.Width := ScaleX(1){%H-};
  ACanvas.Pen.Color := clBlack;
  ACanvas.Pen.Style := psSolid;
  if ACheckState = cbGrayed then
    ACanvas.Brush.Color := clSilver
  else
    ACanvas.Brush.Color := clWhite;
  ACanvas.Brush.Style := bsSolid;
  // Draw checkbox border (= unchecked state)
  InflateRect(R, -ACanvas.Pen.Width div 2, -ACanvas.Pen.Width div 2);
  ACanvas.Rectangle(R);
  InflateRect(R, -ACanvas.Pen.Width div 2, -ACanvas.Pen.Width div 2);
  // Draw checkmark if checked or grayed
  if ACheckState in [cbChecked, cbGrayed] then
  begin
    if ACheckState = cbGrayed then ACanvas.Pen.Color := clGray;
    ACanvas.Pen.Width := ScaleX(2){%H-};
    P[0] := Point(R.Left + cSize.cx div 6, R.Top + cSize.cy div 2);
    P[1] := Point(R.Left + cSize.cx div 3, R.Bottom - cSize.cy div 6);
    P[2] := Point(R.Right - cSize.cx div 6, R.Top + cSize.cy div 6);
    ACanvas.PolyLine(P);
  end;
end;

{ Prints the column headers: at first the fixed column headers, then the
  headers between ACol1 and ACol2. }
procedure TGridPrinter.PrintColHeaders(ACanvas: TCanvas; ACol1, ACol2, Y: Integer);
var
  R: TRect;
  col, row: Integer;
  x, x2, y1, y2: Double;
  fixedColsLeft: Integer = 0;
  fixedColsRight: Integer = 0;
begin
  CalcFixedColPos(ACol1, ACol2, fixedColsLeft, fixedColsRight);
  x := fixedColsLeft;
  y1 := Y;
  for row := 0 to FFixedRows-1 do
  begin
    y2 := Y + FRowHeights[row];
    for col := 0 to FFixedCols-1 do
    begin
      x2 := x + FColWidths[col];
      R := Rect(round(x), round(y1), round(x2), round(y2));
      PrintCell(ACanvas, col, row, R);
      x := x2;
    end;
    for col := ACol1 to ACol2 do
    begin
      x2 := x + FColWidths[col];
      R := Rect(round(x), round(y1), round(x2), round(y2));
      PrintCell(ACanvas, col, row, R);
      x := x2;
    end;
    y1 := y2;
  end;
end;

procedure TGridPrinter.PrintFooter(ACanvas: TCanvas);
begin
  PrintHeaderFooter(ACanvas, FFooter);
end;

procedure TGridPrinter.PrintGridLines(ACanvas: TCanvas;
  AStartCol, AStartRow, AEndCol, AEndRow, XEnd, YEnd: Integer);
var
  x, y: Double;
  xr, yr: Integer;  // x, y rounded to integer
  col, row: Integer;
  lGrid: TGridAccess;
  fixedColsLeft: Integer = 0;
  fixedColsRight: Integer = 0;
  fixedRowsTop: Integer = 0;
  fixedRowsBottom: Integer = 0;
begin
  lGrid := TGridAccess(FGrid);
  CalcFixedColPos(AStartCol, AEndCol, fixedColsLeft, fixedColsRight);
  CalcFixedRowPos(AStartRow, AEndRow, fixedRowsTop, fixedRowsBottom);

  // Print inner grid lines
  ACanvas.Pen.EndCap := pecFlat;
  ACanvas.Pen.Style := lGrid.GridLineStyle;
  // ... vertical fixed cell lines
  if (goFixedVertLine in lGrid.Options) or (gpoFixedVertGridLines in FOptions) then
  begin
    ACanvas.Pen.Color := GetPenColor(FFixedLineColor); //IfThen(FFixedLineColor = clDefault, lGrid.GridLineColor, FFixedLineColor));
    ACanvas.Pen.Width := GetGridLineWidthVert;
    (*
    col := 1;
    x := fixedColsLeft;
    while col < lGrid.FixedCols do
    begin
      x := x + FColWidths[col-1];
      xr := round(x);
      ACanvas.Line(xr, fixedRowsBottom, xr, YEnd);
      inc(col);
    end;
    *)
    col := AStartCol;
    x := fixedColsRight;
    xr := round(x);
    while (xr < XEnd) and (col < lGrid.ColCount) do
    begin
      x := x + FColWidths[col];
      xr := round(x);
      ACanvas.Line(xr, fixedRowsTop, xr, fixedRowsBottom);
      inc(col);
    end;
  end;
  // ... vertical grid lines
  if (goVertLine in lGrid.Options) or (gpoVertGridLines in FOptions) then
  begin
    ACanvas.Pen.Color := GetPenColor(IfThen(FGridLineColor = clDefault, lGrid.GridLineColor, FGridLineColor));
    ACanvas.Pen.Width := GetGridLineWidthVert;
    col := AStartCol;
    x := fixedColsRight;
    xr := round(x);
    while (xr < XEnd) and (col < FColCount) do
    begin
      x := x + FColWidths[col];
      xr := round(x);
      ACanvas.Line(xr, fixedRowsBottom, xr, YEnd);
      inc(col);
    end;
  end;
  // ... horizontal fixed cell lines
  if (goFixedHorzLine in lGrid.Options) or (gpoFixedHorGridLines in FOptions) then
  begin
    ACanvas.Pen.Color := GetPenColor(FFixedLineColor);
    ACanvas.Pen.Width := GetGridLineWidthHor;
    (*
    row := 1;
    y := fixedRowsTop;
    yr := round(y);
    while row < lGrid.FixedRows do
    begin
      y := y + FRowHeights[row];
      yr := round(y);
      ACanvas.Line(fixedColsRight, yr, XEnd, yr);
      inc(row);
    end;
    *)
    row := AStartRow;
    y := fixedRowsBottom;
    yr := round(y);
    while (yr < YEnd) and (row < FRowCount) do
    begin
      y := y + FRowHeights[row];
      yr := round(y);
      ACanvas.Line(fixedColsLeft, yr, fixedColsRight, yr);
      inc(row);
    end;
  end;
  // ... horizontal grid lines
  if (goHorzLine in lGrid.Options) or (gpoHorGridLines in FOptions) then
  begin
    ACanvas.Pen.Color := GetPenColor(IfThen(FGridLineColor = clDefault, lGrid.GridLineColor, FGridLineColor));
    ACanvas.Pen.Width := GetGridLineWidthHor;
    row := AStartRow;
    y := fixedRowsBottom;
    yr := round(y);
    while (yr < YEnd) and (row < FRowCount) do
    begin
      y := y + FRowHeights[row];
      yr := round(y);
      ACanvas.Line(fixedColsRight, yr, XEnd, yR);
      inc(row);
    end;
  end;

  // Print header border lines between fixed and normal cells
  // ... horizontal
  if gpoHeaderBorderLines in FOptions then
  begin
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Color := GetPenColor(FFixedLineColor);
    ACanvas.Pen.Width := GetFixedLineWidthHor;
    ACanvas.Line(fixedColsLeft, fixedRowsBottom, XEnd, fixedRowsBottom);
    // ... vertical
    ACanvas.Pen.Width := GetFixedLineWidthVert;
    ACanvas.Line(fixedColsRight, fixedRowsTop, fixedColsRight, YEnd);
  end;

  if gpoOuterBorderLines in FOptions then
  begin
    // Print outer border lines
    ACanvas.Pen.EndCap := pecRound;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Color := GetPenColor(FBorderLineColor);
    // ... horizontal
    ACanvas.Pen.Width := GetBorderLineWidthHor;
    ACanvas.Line(fixedColsLeft, fixedRowsTop, XEnd, fixedRowsTop);
    ACanvas.Line(fixedColsLeft, YEnd, XEnd, YEnd);
    // ... vertical
    ACanvas.Pen.Width := GetBorderLineWidthVert;
    ACanvas.Line(fixedColsLeft, fixedRowsTop, fixedColsLeft, YEnd);
    ACanvas.Line(XEnd, fixedRowsTop, XEnd, YEnd);
  end;
end;

procedure TGridPrinter.PrintHeader(ACanvas: TCanvas);
begin
  PrintHeaderFooter(ACanvas, FHeader);
end;

procedure TGridPrinter.PrintHeaderFooter(ACanvas: TCanvas;
  HF: TGridPrnHeaderFooter);
var
  Widths: array[TGridPrnHeaderFooterSection] of Integer = (0, 0, 0);
  Heights: array[TGridPrnHeaderFooterSection] of Integer = (0, 0, 0);
  Flags: array[TGridPrnHeaderFooterSection] of Integer;
  TextRects: array[TGridPrnHeaderFooterSection] of TRect;
  printableWidth: Integer;
  hfs: TGridPrnHeaderFooterSection;
  y: Integer;
  s: String;
begin
  if not HF.IsShown then
    exit;

  SelectFont(ACanvas, HF.Font, 1.0);
  ACanvas.Font.Color := GetFontColor(HF.Font.Color);
  printableWidth := FPageRect.Width;
  if (HF.SectionText[hfsLeft] <> '') and (HF.SectionText[hfsCenter] = '') and (HF.SectionText[hfsRight] = '') then
    Widths[hfsLeft] := printableWidth
  else
  if (HF.SectionText[hfsLeft] = '') and (HF.SectionText[hfsCenter] <> '') and (HF.SectionText[hfsRight] = '') then
    Widths[hfsCenter] := printableWidth
  else
  if (HF.SectionText[hfsLeft] <> '') and (HF.SectionText[hfsCenter] = '') and (HF.SectionText[hfsRight] <> '') then
  begin
    Widths[hfsLeft] := printableWidth div 2;
    Widths[hfsRight] := printableWidth div 2;
  end else
  if (HF.SectionText[hfsLeft] = '') and (HF.SectionText[hfsCenter] = '') and (HF.SectionText[hfsRight] <> '') then
    Widths[hfsRight] := printableWidth
  else begin
    for hfs in TGridPrnHeaderFooterSection do
      Widths[hfs] := printableWidth div 3;
  end;

  // Measure sections
  if HF.SectionText[hfsLeft] <> '' then
  begin
    s := HF.ProcessedText[hfsLeft];
    TextRects[hfsLeft] := Rect(0, 0, Widths[hfsLeft], 0);
    Flags[hfsLeft] := DT_LEFT or DT_TOP or DT_WORDBREAK;
    DrawText(ACanvas.Handle, PChar(s), Length(s), TextRects[hfsLeft], Flags[hfsLeft] or DT_CALCRECT);
    Heights[hfsLeft] := TextRects[hfsLeft].Bottom;
  end;

  if HF.SectionText[hfsCenter] <> '' then
  begin
    s := HF.ProcessedText[hfsCenter];
    TextRects[hfsCenter] := Rect(0, 0, Widths[hfsCenter], 0);
    Flags[hfsCenter] := DT_CENTER or DT_TOP or DT_WORDBREAK;
    DrawText(ACanvas.Handle, PChar(s), Length(s), TextRects[hfsCenter], Flags[hfsCenter] or DT_CALCRECT);
    Heights[hfsCenter] := TextRects[hfsCenter].Bottom;
  end;

  if HF.SectionText[hfsRight] <> '' then
  begin
    s := HF.ProcessedText[hfsRight];
    TextRects[hfsRight] := Rect(0, 0, Widths[hfsRight], 0);
    Flags[hfsRight] := DT_RIGHT or DT_TOP or DT_WORDBREAK;
    DrawText(ACanvas.Handle, PChar(s), Length(s), TextRects[hfsRight], Flags[hfsRight] or DT_CALCRECT);
    Heights[hfsRight] := TextRects[hfsRight].Bottom;
  end;

  if HF = FHeader then
    y := FHeaderMargin
  else
    y := FPageHeight - FFooterMargin - MaxValue(Heights);

  // Prepare print rect
  OffsetRect(TextRects[hfsLeft], FLeftMargin, y);
  OffsetRect(TextRects[hfsCenter], (FPageRect.Left + FPageRect.Right - TextRects[hfsCenter].Right) div 2, y);
  OffsetRect(TextRects[hfsRight], FPageRect.Right - TextRects[hfsRight].Width, y);

  // Print header/footer text
  for hfs in TGridPrnHeaderFooterSection do
    if HF.SectionText[hfs] <> '' then
    begin
      s := HF.ProcessedText[hfs];
      DrawText(ACanvas.Handle, PChar(s), Length(s), TextRects[hfs], Flags[hfs]);
    end;

  // Draw header/footer line
  if FHeader.ShowLine then
  begin
    ACanvas.Pen.Color := FHeader.RealLineColor;
    ACanvas.Pen.Width := FHeader.RealLineWidth;
    ACanvas.Pen.Style := psSolid;
    if HF = FHeader then
      inc(y, {%H-}MaxValue(Heights) + (ACanvas.Pen.Width+1) div 2)
    else
      dec(y, (ACanvas.Pen.Width+1) div 2);
    ACanvas.Line(FPageRect.Left, y, FPageRect.Right, y);
  end;
end;

procedure TGridPrinter.PrintPage(ACanvas: TCanvas;
  AStartCol, AStartRow, AEndCol, AEndRow: Integer);
var
  x, y: Double;
  x2, y2: Double;
  row, col: Integer;
  fixedColsLeft: Integer = 0;
  fixedColsRight: Integer = 0;
  fixedRowsTop: Integer = 0;
  fixedRowsBottom: Integer = 0;
  lastPagePrinted: Boolean;
  R: TRect;
begin
  CalcFixedColPos(AStartCol, AEndCol, fixedColsLeft, fixedColsRight);
  CalcFixedRowPos(AStartRow, AEndRow, fixedRowsTop, fixedRowsBottom);

  // Print column headers
  PrintColHeaders(ACanvas, AStartCol, AEndCol, fixedRowsTop);

  // Print grid cells
  y := fixedRowsBottom;
  for row := AStartRow to AEndRow do
  begin
    DoNewLine(row);
    y2 := y + FRowHeights[row];
    PrintRowHeader(ACanvas, row, fixedColsLeft, y);
    x := fixedColsRight;
    for col := AStartCol to AEndCol do
    begin
      x2 := x + FColWidths[col];
      R := Rect(round(x), round(y), round(x2), round(y2));
      PrintCell(ACanvas, col, row, R);
      x := x2;
    end;
    DoLinePrinted(row, AEndCol);
    y := y2;
  end;

  // Print cell grid lines
  PrintGridLines(ACanvas, AStartCol, AStartRow, AEndCol, AEndRow, round(x2), round(y2));

  // Print header and footer
  PrintHeader(ACanvas);
  PrintFooter(ACanvas);

  // Unless we printed the last cell we must send a pagebreak to the printer.
  lastPagePrinted := (AEndCol = FColCount-1) and (AEndRow = FRowCount-1);
  if not lastPagePrinted then
    NewPage;
end;

{ Prints the row headers of the specified row. Row headers are the cells in the
  FixedCols of that row. The row is positioned at the given y coordinate on
  the canvas. X is the position of the left edge of the grid. }
procedure TGridPrinter.PrintRowHeader(ACanvas: TCanvas; ARow: Integer;
  X, Y: Double);
var
  R: TRect;
  col: Integer;
  y1, y2: Integer;
  x2: Double;
begin
  y1 := round(Y);                      // upper edge of the row
  y2 := round(Y + FRowHeights[ARow]);  // lower edge of the row
  for col := 0 to FFixedCols-1 do
  begin
    x2 := X + FColWidths[col];
    R := Rect(round(X), y1, round(x2), y2);
    PrintCell(ACanvas, col, ARow, R);
    X := x2;
  end;
end;

procedure TGridPrinter.ScaleColWidths(AFactor: Double);
var
  i: Integer;
  w: Double;
  fixed: Double;
begin
  fixed := FLeftMargin;
  SetLength(FColWidths, FColCount);
  for i := 0 to FColCount-1 do
  begin
    w := AFactor * TGridAccess(FGrid).ColWidths[i];
    FColWidths[i] := w;
    if i < FFixedCols then
      fixed := fixed + w;
  end;
  FFixedColPos := round(fixed);
end;

procedure TGridPrinter.ScaleRowHeights(AFactor: Double);
var
  i: Integer;
  h: Double;
  fixed: Double;
begin
  fixed := FTopMargin;
  SetLength(FRowHeights, FRowCount);
  for i := 0 to FRowCount-1 do
  begin
    h := AFactor * TGridAccess(FGrid).RowHeights[i];
    FRowHeights[i] := h;
    if i < FFixedRows then
      fixed := fixed + h;
  end;
  FFixedRowPos := round(fixed);
end;

procedure TGridPrinter.ScaleToPages(NumHor, NumVert: Integer);
var
  i: Integer;
  hFixed, wFixed: Double;
  hTotal, wTotal: Double;
  hFactor, wFactor: Double;
begin
  if (FGrid = nil) or (Printer = nil) or (Printer.Printers.Count = 0) then
    exit;

  FPrintScaleFactor := 1.0;
  Measure(Printer.PageWidth, Printer.PageHeight, Printer.XDPI, Printer.YDPI);

  if NumHor > 0 then
  begin
    FPrintScaleToNumHorPages := NumHor;
    wFixed := FFixedColPos - FLeftmargin;
    wTotal := NumHor * wFixed;
    for i := FFixedCols to FColCount-1 do
      wTotal := wTotal + FColWidths[i];
    wFactor := (NumHor * FPageRect.Width) / wTotal;
  end else
  begin
    wFactor := 1.0;
    FPrintScaleToNumHorPages := -1;
  end;

  if NumVert > 0 then
  begin
    FPrintScaleToNumVertPages := NumVert;
    hFixed := FFixedRowPos - FTopMargin;
    hTotal := NumVert * hFixed;
    for i := FFixedRows to FRowCount-1 do
      hTotal := hTotal + FRowHeights[i];
    hFactor := (NumVert * FPageRect.Height) / hTotal;
  end else
  begin
    hFactor := 1.0;
    FPrintScaleToNumVertPages := -1;
  end;

  if (NumHor > 0) and (NumVert > 0) then
    FPrintScalingMode := smFitAll
  else if (NumHor > 0) then
    FPrintScalingMode := smFitToWidth
  else if (NumVert > 0) then
    FPrintScalingMode := smFitToHeight
  else
    FPrintScalingMode := smManual;

  FPrintScaleFactor := Min(wFactor, hFactor);

  if FPrintScaleFactor > 1.0 then
    FPrintScalefactor := 1.0;  // do not magnify
end;

function TGridPrinter.ScaleX(AValue: Integer): Integer;
begin
  Result := Round(FFactorX * AValue);
end;

function TGridPrinter.ScaleY(AValue: Integer): Integer;
begin
  Result := Round(FFactorY * AValue);
end;

procedure TGridPrinter.SelectFont(ACanvas: TCanvas; AFont: TFont;
  AScaleFactor: Double = 1.0);
var
  fd: TFontData;
  fontSize: Integer;
begin
  ACanvas.Font.Assign(AFont);
  ACanvas.Font.PixelsPerInch := FPixelsPerInchY;
  if AFont.Size = 0 then
  begin
    fd := GetFontData(AFont.Reference.Handle);
    fontSize := round(abs(fd.Height) * 72 / ScreenInfo.PixelsPerInchY * AScaleFactor);
  end else
    fontSize := round(ACanvas.Font.Size * AScaleFactor);
  if fontSize < 3 then fontSize := 3;
  ACanvas.Font.Size := fontSize;
end;

procedure TGridPrinter.SetBorderLineColor(AValue: TColor);
begin
  if FBorderLineColor <> AValue then
  begin
    FBorderLineColor := AValue;
    UpdatePreview;
  end;
end;

procedure TGridPrinter.SetBorderLineWidth(AValue: Double);
begin
  if FBorderLineWidth <> AValue then
  begin
    FBorderLineWidth := AValue;
    UpdatePreview;
  end;
end;

procedure TGridPrinter.SetFileName(AValue: String);
begin
  if FFileName <> AValue then
  begin
    FFileName := AValue;
    UpdatePreview;
  end;
end;

procedure TGridPrinter.SetFixedLineColor(AValue: TColor);
begin
  if FFixedLineColor <> AValue then
  begin
    FFixedLineColor := AValue;
    UpdatePreview;
  end;
end;

procedure TGridPrinter.SetFixedLineWidth(AValue: Double);
begin
  if FFixedLineWidth <> AValue then
  begin
    FFixedLineWidth := AValue;
    UpdatePreview;
  end;
end;

procedure TGridPrinter.SetGrid(AValue: TCustomGrid);
begin
  FGrid := AValue;
  if FGrid <> nil then
  begin
    FColCount := TGridAccess(FGrid).ColCount;
    FRowCount := TGridAccess(FGrid).RowCount;
    FFixedCols := TGridAccess(FGrid).FixedCols;
    FFixedRows := TGridAccess(FGrid).FixedRows;
    if Assigned(FOnGetColCount) then
      FOnGetColCount(Self, FGrid, FColCount);
    if Assigned(FOnGetRowCount) then
      FOnGetRowCount(self, FGrid, FRowCount);
  end else
  begin
    FColCount := 0;
    FRowCount := 0;
    FFixedCols := 0;
    FFixedRows := 0;
  end;
  FPageNumber := 0;
  FPageCount := 0;
end;

procedure TGridPrinter.SetGridLineColor(AValue: TColor);
begin
  if FGridLineColor <> AValue then
  begin
    FGridLineColor := AValue;
    UpdatePreview;
  end;
end;

procedure TGridPrinter.SetGridLineWidth(AValue: Double);
begin
  if FGridLineWidth <> AValue then
  begin
    FGridLineWidth := AValue;
    UpdatePreview;
  end;
end;

procedure TGridPrinter.SetOptions(AValue: TGridPrnOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;
    UpdatePreview;
  end;
end;

procedure TGridPrinter.SetOrientation(AValue: TPrinterOrientation);
begin
  if GetOrientation <> AValue then
  begin
    Printer.Orientation := AValue;
    UpdatePreview;
  end;
end;

procedure TGridPrinter.UpdatePreview;
begin
  if FOutputDevice = odPreview then
    DoUpdatePreview;
end;

end.

