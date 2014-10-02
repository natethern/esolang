CC = gcc
ESO_WIKI_FILES = http://esoteric.voxelperfect.net/files

egobf: egobf-0.7.1.tar.bz2
	#cd build
	tar -xjf egobf-0.7.1.tar.bz2
	cd egobf-0.7.1 && ./configure && make

#build:
#	mkdir -p build

egobf-0.7.1.tar.bz2:
	# first try to get the online version
	#-wget -q -O web_download/$@ $ESO_WIKI_FILES/brainfuck/impl/egobf-0.7.1.tar.bz2
	-wget -q -O web_download/$@ http://esoteric.voxelperfect.net/files/brainfuck/impl/$@
	cp -fv web_download/$@ .
	# copy the local copy if the wget failed
	cp -nv web_archive/$@ .
