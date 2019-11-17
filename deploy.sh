#!/bin/bash

version=$(git rev-list --no-merges --count HEAD)

cat > scripting/include/aps_version.inc <<EOT
#if defined _aps_version_included
	#endinput
#endif

#define _aps_version_included

#define APS_MAJOR_VERSION			0
#define APS_MINOR_VERSION			1
#define APS_MAINTENANCE_VERSION		$version
#define APS_VERSION_STR				"0.1.$version"
EOT

zip -9 -r -q --exclude=".git/*" --exclude=".gitignore" --exclude=".gitkeep" --exclude=".travis.yml" --exclude="README.md" --exclude="deploy.sh" advenced-punishment-system.zip .
