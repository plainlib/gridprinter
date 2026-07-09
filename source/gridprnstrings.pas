unit GridPrnStrings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

resourcestring
  // Print Preview
  RSPrintPreview = 'Print Preview';
  RSPrint = 'Print';
  RSClose = 'Close';

  RSShowFirstPage = 'Show first page';
  RSShowPrevPage = 'Show previous page';
  RSShowNextPage = 'Show next page';
  RSShowLastPage = 'Show last page';
  RSZoomIn = 'Zoom in';
  RSZoomOut = 'Zoom out';
  RSZoomToFitPageWidth = 'Zoom to fit page width';
  RSZoomToFitPageHeight = 'Zoom to fit page height';
  RSOriginalSize = 'Original size (100%)';
  RSPageMarginsConfig = 'Page margins configuration';
  RSPortrait = 'Portrait';
  RSPortraitHint = 'Portrait page orientation';
  RSLandscape = 'Landscape';
  RSLandscapeHint = 'Landscape page orientation';
  RSHeaderFooter = 'Header/footer...';
  RSHeaderFooterHint = 'Header/footer configuration';
  RSPageMargins = 'Margins';
  RSPageMarginsHint = 'Show/hide page margins';
  RSPrintColsFirst = 'Columns first';
  RSPrintColsFirstHint = 'First print columns from top to bottom,' + LineEnding +
    'then print from left to right';
  RSPrintRowsFirst = 'Rows first';
  RSPrintRowsFirstHint = 'First print rows from left to right,' + LineEnding +
    'then print from top to bottom';
  RSCenterHor = 'Center horizontally';
  RSCenterHorHint = 'Center grid in page horizontally';
  RSCenterVert = 'Center vertically';
  RSCenterVertHint = 'Center grid in page vertically';
  RSScalePrinter = 'Scale printout...';
  RSScalePrinterHint = 'Scaling of print output';
  RSPageSetupHint = 'Page setup options';
  RSPageInfoPanel = 'Page numbers';
  RSZoomInfoPanel = 'Zoom level';

  RSLeftMargin = 'Left margin';
  RSTopMargin = 'Top margin';
  RSRightMargin = 'Right margin';
  RSBottomMargin = 'Bottom margin';
  RSHeaderMargin = 'Header margin';
  RSFooterMargin = 'Footer margin';

  RSPageInfo = 'Page %0:d of %1:d';
  RSZoomInfo = 'Zoom %2:d %%';
  RSPageAndZoomInfo = 'Page %0:d of %1:d, Zoom %2:d %%';

  // Header / footer
  RSHeader = 'Header';
  RSFooter = 'Footer';
  RSShow = 'Show';
  RSFont = 'Font';
  RSHeaderFooterSectionParameterInfo =
    'Each section can contain the following parameters:' + LineEnding +
    '  $DATE - Current date' + LineEnding +
    '  $TIME - Current time' + LineEnding +
    '  $PAGE - Page number' + LineEnding +
    '  $PAGECOUNT - Number of pages' + LineEnding +
    '  $FULL_FILENAME - Full name of the printed file' + LineEnding +
    '  $FILENAME - Name of the printed file, without path' + LineEnding +
    ' $PATH - Path of the printed file';
  RSShowDividingLine = 'Show dividing line';
  RSLineWidthMM = 'Line width (mm)';
  RSLineColor = 'Line color';
  RSTextInLeftAlignedSection = 'Text in left-aligned section';
  RSTextInCenteredSection = 'Text in centered section';
  RSTextInRightAlignedSection = 'Text in right-aligned section';

  // Printer scale factor
  RSPrintingScaleFactor = 'Printer Scale Factor';
  RSSelectScaleFactorForPrinting = 'Select the scale factor for printing';
  RSScaleFactorInfo = 'Current scaling factor: %.2f';
  RSManualScaleFactor = 'Manual scale factor';
  RSScaleGridToWidthOf = 'Scale grid to width of';
  RSScaleGridToHeightOf = 'Scale grid to height of';
  RSPages = 'page(s)';

  // Actions
  RSPrintEllipsis = 'Print...';
  RSPrintPreviewEllipsis = 'Preview...';
  RSPrintGrid = 'Print grid';

implementation

end.

