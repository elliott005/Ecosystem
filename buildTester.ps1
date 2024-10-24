# replace this string with your path to chrome so it can be opened to show the game
$pathToChrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"

Start-Process -FilePath $pathToChrome -ArgumentList '--start-fullscreen "http://localhost:8910/"'
Set-Location www/
python.exe -m http.server 8910