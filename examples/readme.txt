The folder "examples" of the GridPrinter installation contains several sample
projects to demonstrate basic features of the TGridPrinter and the
TGridPrintPreviewDialog:

- "stringgrid" - how to print a stringgrid
- "stringgrid_formatted" - like "stringgrid" sample, but the stringgrid here
  has extra formatting due to the OnPrepareCanvas event handler.
- "stringgrid_columns" - tests whether the Alignment and Layout properties of
  TGridColumn are passed to the GridPrinter automatically.
- "dbgrid" -  how to print a DBGrid using RecNo
- "dbgrid2" - how to print a DBGrid using bookmarks
- "multi-language" - like "stringgrid" sample, but now as a multi-language
  application. Additional translations are welcome.  
- "actions" - demonstrates application of the GridPrinter standard actions in
  printing and previewing a stringgrid without writing a single line of code.
  
Data used in the grids are auto-generated dummy data. 
The csv data file in the "actions" folder is taken from 
https://people.math.sc.edu/Burkardt/datasets/csv/csv.html (license GNU LGPL).

Icons used in the demos are from the Lazarus "general-purpose" images, provided
by Roland Hahn (license: Creative Commons CC0 1.0 Universal, freely available, 
no restrictions in usage).