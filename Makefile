.POSIX:
.PHONY: default switch-personal switch-work upgrade hosts cleanup

default:
	@echo "Usage: make switch-personal | make switch-work"
	@exit 1

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

switch-personal: HOST = r__d
switch-work: HOST = rdwk

# First run has no darwin-rebuild yet, so it comes from nix run
switch-personal switch-work: /nix /opt/homebrew/bin/brew
	@if [ -x /run/current-system/sw/bin/darwin-rebuild ]; then \
		sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#$(HOST); \
	else \
		sudo /nix/var/nix/profiles/default/bin/nix --experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#$(HOST); \
	fi

upgrade:
	git pull
	nix flake update

hosts:
	@/usr/bin/grep -qF "chat.local" /etc/hosts || \
		(sudo sh -c 'echo "127.0.0.1 chat.local  # caddy local proxy" >> /etc/hosts' && \
		sudo /usr/bin/dscacheutil -flushcache && \
		echo "Added chat.local to /etc/hosts")
	@/usr/bin/grep -F "chat.local" /etc/hosts

cleanup:
	nix-collect-garbage
