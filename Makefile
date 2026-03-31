.POSIX:
.PHONY: default build update bootstrap hosts

default: build

/nix:
	curl -L https://nixos.org/nix/install | sh
	# TODO https://github.com/nix-darwin/nix-darwin/issues/149
	sudo rm /etc/nix/nix.conf

/opt/homebrew/bin/brew:
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o /tmp/brew-install.sh
	bash /tmp/brew-install.sh

#.hostname-set:
#	@echo "Setting hostname to 'rdwk'..."
#	sudo scutil --set HostName rdwk
#	sudo scutil --set LocalHostName rdwk
#	sudo scutil --set ComputerName rdwk
#	@echo "Hostname set successfully. You may need to restart your terminal."
#	touch .hostname-set

bootstrap: /nix /opt/homebrew/bin/brew
	@echo "Bootstrapping nix-darwin with flake..."
	sudo /nix/var/nix/profiles/default/bin/nix --experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#$(USER)
	@echo "Bootstrap complete! darwin-rebuild is now available."

build: bootstrap
	@if [ -f /run/current-system/sw/bin/darwin-rebuild ]; then \
		echo "Using installed darwin-rebuild..."; \
		sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#$(USER); \
	else \
		echo "darwin-rebuild not found, using nix run..."; \
		sudo /nix/var/nix/profiles/default/bin/nix --experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#$(USER); \
	fi

upgrade:
	git pull
	nix flake update

update:
	sudo darwin-rebuild switch --flake .#$(USER)

hosts:
	@/usr/bin/grep -qF "chat.local" /etc/hosts || \
		(sudo sh -c 'echo "127.0.0.1 chat.local  # caddy local proxy" >> /etc/hosts' && \
		sudo /usr/bin/dscacheutil -flushcache && \
		echo "Added chat.local to /etc/hosts")
	@/usr/bin/grep -F "chat.local" /etc/hosts

cleanup:
	nix-collect-garbage
