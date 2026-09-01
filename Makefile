-include .env

.PHONY: all clean build test test-unit test-integration coverage snapshot format anvil install update deploy deploy-sepolia enable-sale mint reveal help

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Pixel Pioneers — available commands:"
	@echo "  make install           Install dependencies"
	@echo "  make build             Compile contracts"
	@echo "  make test              Run all tests"
	@echo "  make test-unit         Run unit tests only"
	@echo "  make test-integration  Run integration tests only"
	@echo "  make coverage          Run coverage (excludes scripts)"
	@echo "  make snapshot          Gas snapshot"
	@echo "  make anvil             Start local Anvil node"
	@echo "  make deploy            Deploy to local Anvil"
	@echo "  make deploy-sepolia    Deploy + verify on Sepolia"
	@echo "  make enable-sale       Enable public sale (latest deployment)"
	@echo "  make mint              Public mint (latest deployment)"
	@echo "  make reveal            Reveal collection (latest deployment)"

all: clean install build test

clean:
	forge clean

install:
	forge install cyfrin/foundry-devops@0.2.2 --no-commit
	forge install foundry-rs/forge-std@v1.8.2 --no-commit
	forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit

update:
	forge update

build:
	forge build

test:
	forge test -vvv

test-unit:
	forge test --match-path "test/unit/*" -vvv

test-integration:
	forge test --match-path "test/integration/*" -vvv

coverage:
	forge coverage --no-match-coverage "script/"

snapshot:
	forge snapshot

format:
	forge fmt

anvil:
	anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# -----------------------------
# Deployment
# -----------------------------
# Default: local Anvil
NETWORK_ARGS := --rpc-url http://127.0.0.1:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

# Usage: make deploy ARGS="--network sepolia"
ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployPixelPioneers.s.sol:DeployPixelPioneers $(NETWORK_ARGS)

deploy-sepolia:
	@forge script script/DeployPixelPioneers.s.sol:DeployPixelPioneers \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		-vvvv

# -----------------------------
# Post-deploy interactions
# -----------------------------
# Override with: make enable-sale ARGS="--network sepolia"
enable-sale:
	@forge script script/Interactions.s.sol:EnablePublicSale $(NETWORK_ARGS)

mint:
	@forge script script/Interactions.s.sol:MintNFT $(NETWORK_ARGS)

reveal:
	@forge script script/Interactions.s.sol:RevealCollection $(NETWORK_ARGS)