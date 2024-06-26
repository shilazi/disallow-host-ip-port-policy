SOURCE_FILES := $(shell test -e src/ && find src -type f)
NAME := $(shell sed -n 's,^name = \"\(.*\)\",\1,p' Cargo.toml)
VERSION := $(shell sed -n 's,^version = \"\(.*\)\",\1,p' Cargo.toml)
WASM_NAME :=$(NAME)-v$(VERSION).wasm

policy.wasm: $(SOURCE_FILES) Cargo.*
	cargo build --target=wasm32-wasip1 --release
	cp target/wasm32-wasip1/release/*.wasm $(WASM_NAME)

artifacthub-pkg.yml: metadata.yml Cargo.toml
	$(warning If you are updating the artifacthub-pkg.yml file for a release, \
	  remember to set the VERSION variable with the proper value. \
	  To use the latest tag, use the following command:  \
	  make VERSION=$$(git describe --tags --abbrev=0 | cut -c2-) annotated-policy.wasm)
	kwctl scaffold artifacthub --metadata-path metadata.yml --version $(VERSION) \
		--questions-path questions-ui.yml --output artifacthub-pkg.yml

annotated-policy.wasm: policy.wasm metadata.yml
	kwctl annotate -m metadata.yml -u README.md -o annotated-policy.wasm $(WASM_NAME)

.PHONY: fmt
fmt:
	cargo fmt --all -- --check

.PHONY: lint
lint:
	cargo clippy -- -D warnings

.PHONY: e2e-tests
e2e-tests: annotated-policy.wasm
	bats e2e.bats

.PHONY: test
test: fmt lint
	cargo test

.PHONY: clean
clean:
	cargo clean
	rm -f $(WASM_NAME) annotated-policy.wasm
