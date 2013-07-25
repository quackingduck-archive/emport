SRC = $(shell find src -name "*.coffee" -type f | sort)
LIB = $(SRC:src/%.coffee=lib/%.js)

COFFEE=node_modules/.bin/coffee
all: clean setup build test

build: $(LIB)

lib:
	mkdir lib

lib/%.js: src/%.coffee lib
	dirname "$@" | xargs mkdir -p
	$(COFFEE) --js <"$<" >"$@"

clean:
	rm -rf lib
	rm -rf node_modules

setup:
	npm install

# To a single test append '-test' to the filename:
#		make test/foo_test.coffee-test

TEST_FILES = $(shell find "test" -name "*_test.coffee")
TESTS = $(TEST_FILES:%=%-test)

test : build $(TESTS)

test/%_test.coffee-test : test/%_test.coffee
	./node_modules/.bin/mocha \
		--compilers coffee:coffee-script-redux/register \
		--ui qunit

# ---

VERSION_NUMBER = $(shell cat package.json | grep version | cut -d ' ' -f 3 | xargs)

tag:
	git tag v$(VERSION_NUMBER)
