COFFEE = $(shell find "src" -name "*.coffee")
JS = $(COFFEE:src%.coffee=lib%.js)

all: $(JS)

lib/%.js : src/%.coffee
	./node_modules/.bin/coffee \
		--compile \
		--lint \
		--output lib $<

# To a single test append '-test' to the filename:
#		make test/foo_test.coffee-test

TEST_FILES = $(shell find "test" -name "*_test.coffee")
TESTS = $(TEST_FILES:%=%-test)

test : $(TESTS)

test/%_test.coffee-test : test/%_test.coffee
	./node_modules/.bin/mocha \
		--compilers coffee:coffee-script \
		--ui qunit

# ---

tag:
	git tag v`coffee -e "console.log JSON.parse(require('fs').readFileSync 'package.json').version"`
