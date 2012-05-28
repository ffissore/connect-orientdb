REPORTER = spec

test:
	node_modules/mocha/bin/mocha --reporter $(REPORTER)

.PHONY: test
