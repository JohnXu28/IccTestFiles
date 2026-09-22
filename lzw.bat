@echo off
echo ************** Convert TIF to LZW Compression **************
for /r %%f in (*.tif) do (
    echo Processing %%f...
    LZW.exe "%%f" "%%f"
)
echo All done.
