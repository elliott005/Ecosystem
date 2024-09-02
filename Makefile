build_lovezip:
	zip -r Ecosystem.zip ./*.lua ./assets ./src ./libraries ./Tiled
	mv -vf Ecosystem.zip Ecosystem.love

build_lovejs:	build_lovezip
	npx love.js --compatibility --title "Ecosystem!" --memory 100000000 ./Ecosystem.love www/

test_lovejs:
	firefox http://localhost:8910/ &
	cd www/ && python3 -m http.server 8910