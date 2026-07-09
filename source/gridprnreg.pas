unit GridPrnReg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

procedure Register;

implementation

uses
  ActnList, GridPrn, GridPrnPreviewDlg, GridPrnActions;

{$R gridprinter_icons.res}

procedure Register;
begin
  RegisterComponents('Misc', [TGridPrinter, TGridPrintPreviewDialog]);
  RegisterActions('GridPrinter', [TGridPrinterAction, TGridPrintPreviewAction], nil);
end;

end.

