MAKEFLAGS += --silent

RPM_NAME	?= default
RPM_RELEASE	?= 0.1
RPM_ARCH	?= $(shell arch)
RPM_PACKAGER	?= $(shell getent passwd `whoami` | cut -d ':' -f 5) <$(shell whoami)@$(shell hostname -f)>
RPM_TARGET_DIR	?= $(abspath target)
RPM_BUILD_DIR	?= $(RPM_TARGET_DIR)/build
RPM_DISTS_DIR	?= $(RPM_TARGET_DIR)/dists
RPM_WORKS_DIR	?= $(RPM_TARGET_DIR)/works
LOG_FILE	?= $(RPM_NAME).log

rpm_sedsubs	= sed -e "s/\#RPM_NAME\#/$(RPM_NAME)/g"
rpm_sedsubs	+=    -e "s/\#RPM_VERSION\#/$(RPM_VERSION)/g"
rpm_sedsubs	+=    -e "s/\#RPM_RELEASE\#/$(RPM_RELEASE)/g"
rpm_sedsubs	+=    -e "s/\#RPM_ARCH\#/$(RPM_ARCH)/g"
rpm_sedsubs	+=    -e "s/\#RPM_PACKAGER\#/$(RPM_PACKAGER)/g"

all: pre src spec dep rpm post

pre:
	# Empty log file first
	echo `date` - pre >> "$(LOG_FILE)"
	echo -n "Creating build and dist directories... ";
	mkdir -vp \
		"$(RPM_BUILD_DIR)/RPMS" \
		"$(RPM_BUILD_DIR)/SOURCES" \
		"$(RPM_BUILD_DIR)/BUILD" \
		"$(RPM_BUILD_DIR)/SPECS" \
		"$(RPM_BUILD_DIR)/SRPMS" \
		"$(RPM_DISTS_DIR)" \
		>> "$(LOG_FILE)" 2>&1 \
		|| { echo "failed (see "$(LOG_FILE)")"; exit 1; };
	echo "ok"

src: RPM_SPEC	?= specs/main.in
src: REMOTE_SOURCES	?= $(shell sed -n -r -e "s/^\s*Source[0-9]*:\s*(https?|ftp)(:.+)/\1\2/ p" $(RPM_SPEC) | $(rpm_sedsubs))
src: LOCAL_SOURCES	?= $(wildcard src/$(RPM_NAME)/*)
src:
	echo `date` - src >> "$(LOG_FILE)"
	echo -n "Downloading remotes sources if needed... ";
	test -f $(RPM_SPEC) || { echo "failed (see "$(LOG_FILE)")"; exit 1; };
	$(foreach SOURCE,$(REMOTE_SOURCES), test -f "$(RPM_BUILD_DIR)/SOURCES/$(notdir $(SOURCE))" \
		|| wget --no-verbose --append-output="$(LOG_FILE)" --directory-prefix="$(RPM_BUILD_DIR)/SOURCES" "$(SOURCE)" 2>> "$(LOG_FILE)" \
		|| { echo "failed for $(SOURCE) (see "$(LOG_FILE)")"; exit 1;}; \
	)
	echo "ok";

	echo -n "Creating links to local sources if needed... ";
	$(foreach SOURCE,$(LOCAL_SOURCES), test -L "$(RPM_BUILD_DIR)/SOURCES/$(notdir $(SOURCE))" \
		|| ln --verbose --force --symbolic --target-directory="$(RPM_BUILD_DIR)/SOURCES" "$(abspath $(SOURCE))" >> "$(LOG_FILE)" 2>&1 \
		|| { echo "failed for $(SOURCE) (see "$(LOG_FILE)")"; exit 1;}; \
	)
	echo "ok";

spec: RPM_SPEC		?= specs/main.in
spec: RPM_CHANGELOG	?= specs/changelog
spec:
	echo `date` - spec >> "$(LOG_FILE)"
	echo -n "Preparing changelog for the template spec file... ";
	test -f "$(RPM_SPEC)" -a -f "$(RPM_CHANGELOG)" || { echo "failed (see "$(LOG_FILE)")"; exit 1; };
	cp "$(RPM_CHANGELOG)" "$(RPM_BUILD_DIR)/SPECS/changelog" >> "$(LOG_FILE)" 2>&1 || { echo "failed (see "$(LOG_FILE)")"; exit 1; };
	echo "ok";
	echo -n "Generating the spec file from template... ";
	cat "$(RPM_SPEC)" | $(rpm_sedsubs) > "$(RPM_BUILD_DIR)/SPECS/$(RPM_NAME)-$(RPM_VERSION).spec" 2>> "$(LOG_FILE)" || { echo "failed (see "$(LOG_FILE)")"; exit 1; };
	echo "ok";

dep: spec
	echo `date` - dep >> "$(LOG_FILE)"
	echo -n "Installing required build dependencies... ";
	sudo yum-builddep -y "$(RPM_BUILD_DIR)/SPECS/$(RPM_NAME)-$(RPM_VERSION).spec" >> "$(LOG_FILE)" 2>&1 || { echo "failed (see "$(LOG_FILE)")"; exit 1; };
	echo "ok";

rpm:
	echo `date` - rpm >> "$(LOG_FILE)"
	rpmbuild --verbose --define="_topdir $(RPM_BUILD_DIR)" \
		-bb "$(RPM_BUILD_DIR)/SPECS/$(RPM_NAME)-$(RPM_VERSION).spec";

post:
	echo `date` - post >> "$(LOG_FILE)"
	echo -n "Collecting RPMS from build to dists directory... ";
	mv -vf "$(RPM_BUILD_DIR)/RPMS/*/$(RPM_NAME)*-$(RPM_VERSION)-*.rpm" "$(RPM_DISTS_DIR)/" >> "$(LOG_FILE)" 2>&1 || { echo "failed (see "$(LOG_FILE)")"; exit 1; };
	#mv -vf "$(RPM_BUILD_DIR)/SRPMS/$(RPM_NAME)*-$(RPM_VERSION)-*.rpm"  "$(RPM_DISTS_DIR)/" >> "$(LOG_FILE)" 2>&1 || { echo "failed (see "$(LOG_FILE)")"; exit 1; };
	echo "ok";

purge: clean
	echo `date` - purge >> "$(LOG_FILE)"
	echo -n "Removing dist directory and log files... ";
	rm -vrf "$(RPM_DISTS_DIR)" >> "$(LOG_FILE)" 2>&1 || { echo "failed (see "$(LOG_FILE)")"; exit 1; };
	rm -f *.log || { echo "failed"; exit 1; };
	echo "ok";

clean:
	echo `date` - clean >> "$(LOG_FILE)"
	echo -n "Removing build directory... ";
	rm -vrf "$(RPM_BUILD_DIR)" >> "$(LOG_FILE)" 2>&1 || { echo "failed (see "$(LOG_FILE)")"; exit 1; };
	echo "ok";
