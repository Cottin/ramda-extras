PATH := ./node_modules/.bin:${PATH}

init:
	npm install

clean:
	rm -rf lib/

build:
	coffee -o lib/ -c src/

dist: clean init build
