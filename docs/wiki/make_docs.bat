echo off

rem set FMT=html
set FMT=chm
echo Downloading wiki...

wikiget --page=GridPrinter

echo.
echo Converting wiki to chm...

wikiconvert --format=%FMT% --css=css/wiki.css --root="GridPrinter wiki page" --title="GridPrinter wiki page (offline version, created %DATE%)" --chm="..\gridprinter-wiki.chm" wikixml/gridprinter.h00.xml

set FMT=