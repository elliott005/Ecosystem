Remove-Item .\Ecosystem.love
7z a -tzip Ecosystem.zip *.lua assets\ src\ libraries\ Tiled\
Rename-Item -Path .\Ecosystem.zip -NewName .\Ecosystem.love
npx love.js.cmd --compatibility --title "Ecosystem!" --memory 100000000 .\Ecosystem.love www\