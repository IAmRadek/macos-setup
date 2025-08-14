.POSIX:
.PHONY: default build update bootstrap

default: build

/nix:
	curl -L https://nixos.org/nix/install | sh
	# TODO https://github.com/nix-darwin/nix-darwin/issues/149
	sudo rm /etc/nix/nix.conf

/opt/homebrew/bin/brew:
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o /tmp/brew-install.sh
	bash /tmp/brew-install.sh

.hostname-set:
	@echo "Setting hostname to 'rd'..."
	sudo scutil --set HostName rd
	sudo scutil --set LocalHostName rd
	sudo scutil --set ComputerName rd
	@echo "Hostname set successfully. You may need to restart your terminal."
	touch .hostname-set

bootstrap: /nix /opt/homebrew/bin/brew .hostname-set
	@echo "Bootstrapping nix-darwin with flake..."
	sudo /nix/var/nix/profiles/default/bin/nix --experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .
	@echo "Bootstrap complete! darwin-rebuild is now available."

build: bootstrap
	@if [ -f /run/current-system/sw/bin/darwin-rebuild ]; then \
		echo "Using installed darwin-rebuild..."; \
		sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .; \
	else \
		echo "darwin-rebuild not found, using nix run..."; \
		sudo /nix/var/nix/profiles/default/bin/nix --experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .; \
	fi

update:
	git pull
	nix flake update
	darwin-rebuild switch --flake .
