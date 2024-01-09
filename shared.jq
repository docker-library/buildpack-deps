def apt_get_dist_clean:
	if [
		# only suites with APT 2.7.8+ have "apt-get dist-clean"
		# https://tracker.debian.org/news/1492892/accepted-apt-278-source-into-unstable/

		# https://tracker.debian.org/pkg/apt
		# https://packages.debian.org/apt
		"trixie", # TODO once 2.7.8 migrates to testing (and images are rebuilt), this should be removed!
		"bookworm",
		"bullseye",
		"buster",

		# https://launchpad.net/ubuntu/+source/apt
		# https://packages.ubuntu.com/apt
		"noble", # TODO once 2.7.8+ makes it into devel (and images are rebuilt), this should be removed!
		"mantic",
		"lunar",
		"jammy",
		"focal",

		empty
	] | index(env.codename) then
		"rm -rf /var/lib/apt/lists/*"
	else
		"apt-get dist-clean"
	end
;
