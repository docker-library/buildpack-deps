def apt_get_dist_clean:
	if [
		# only suites with APT 2.7.8+ have "apt-get dist-clean"
		# https://tracker.debian.org/news/1492892/accepted-apt-278-source-into-unstable/

		# https://tracker.debian.org/pkg/apt
		# https://packages.debian.org/apt
		"bookworm",
		"bullseye",
		"buster",

		# https://launchpad.net/ubuntu/+source/apt
		# https://packages.ubuntu.com/apt
		"mantic",
		"jammy",
		"focal",

		empty
	] | index(env.codename) then
		"rm -rf /var/lib/apt/lists/*"
	else
		"apt-get dist-clean"
	end
;
