# -*-makefile-*-

## load essential LetsMT configuration
include Makefile.conf

## Communicate variables to sub-makes
.EXPORT_ALL_VARIABLES:

#########################################################################

## install:  For "monolithic" installations.
## Install all software prerequisites, the repository,
## and configure Apache2 to use the repository.

## install-rr-server:  Install a "RR server" which hosts the DBs.

## install-storage-server:  Make a "resource repository server" which stores
##  data in svn repositories but has no DB of its own.

## install-sge-client:  Install only the repository software so the sge client
##  can execute jobs. Has no DB, storage, apache or webservice.

## install-frontend:  Install client machines that will use the resource
##  repository (but do not run the repository software themselves).

## install-grenzschnitte:  Install Web user interface for the repository.

.PHONY: all
all: install

.PHONY: install install-rr-server
install install-rr-server:  prepare-target stop-db
	$(MAKE) $@ -C installation -f Makefile.prereqs
	$(MAKE) $@ -C installation
	$(MAKE) start-db index-db
	@echo
	@echo "Installation is finished."
	@echo

.PHONY: install-storage-server install-sge-client install-client install-frontend
install-storage-server install-sge-client install-client install-frontend: prepare-target
	$(MAKE) $@ -C installation -f Makefile.prereqs
	$(MAKE) $@ -C installation
	@echo
	@echo "Installation is finished."
	@echo "You need to copy the SSL certificate from the server to this computer."
	@echo "You can do this with the command"
	@echo "    sudo scp -r <user>@<hostname>:/etc/ssl/<hostname> /etc/ssl"
	@echo "where <hostname> is the server address that you provided earlier,"
	@echo "and <user> is a user name to which you have access on that machine."
	@echo



###########################################################################
## OPUS specific installation (remote git & OPUS-specific ssl keys)
##
##   sudo make install-opus .......... install repository server
##   sudo make install-opus-client ... install slurm compute node
##
###########################################################################

## remote git server for OPUS
GITSEVER = version.helsinki.fi
OPUSGIT  = git@${GITSERVER}:OPUS
ADMIN    = tiedeman
KEYHOME  = taito.csc.fi:/proj/OPUS/admin/repository

## stable version
OPUS_STABLE    = vm1637.kaj.pouta.csc.fi
OPUS_STABLE_IP = 192.168.1.19

## development version
OPUS_DEV       = vm0081.kaj.pouta.csc.fi
OPUS_DEV_IP    = 192.168.1.10


## install stable versions
opus-stable opus-client-stable:
	${MAKE} OPUSGIT=git@version.helsinki.fi:OPUS \
		OPUSRR=${OPUS_STABLE} \
		OPUSIP=${OPUS_STABLE_IP} \
	${@:-stable=}

## install development versions
opus-dev opus-client-dev:
	${MAKE} OPUSGIT= \
		OPUSRR=${OPUS_DEV} \
		OPUSIP=${OPUS_DEV_IP} \
	${@:-dev=}

ifndef OPUSRR
  OPUSRR = ${OPUS_STABLE}
  OPUSIP = ${OPUS_STABLE_IP}
endif

## install repository for OPUS with connection to remote git server
.PHONY: install-opus opus
install-opus opus: /var/www/.ssh/config /etc/munge/munge.key /etc/ssl/${HOSTNAME}
	${MAKE} GIT_REMOTE='${OPUSGIT}' HOSTNAME=${OPUSRR} install
	service munge restart
	service slurm-llnl restart
	@echo
	@echo '----------------------------------------------------------';
	@echo "Installation of the OPUS repository backend finished"
	@echo "Don't forget to upload the public key /etc/ssh/opusrr.pub"
	@echo "to the git server at ${OPUSGIT}!"
	@echo '----------------------------------------------------------';
	@echo

.PHONY: install-opus-client opus-client
install-opus-client opus-client: /etc/ssl/${OPUSRR} /etc/munge/munge.key
	${MAKE} SLURM_SERVER=${OPUSIP} LETSMTHOST=${OPUSRR} install-client
	service munge restart
	service slurm-llnl restart

/var/www/.ssh/config: /etc/ssh/opusrr
	mkdir -p ${dir $@}
	echo 'Host *' > $@
	echo '  IdentityFile /etc/ssh/opusrr' >> $@
	chown -R www-data:www-data $@
	chmod 700 $@
	chmod 400 $@
	ssh-keyscan -H ${GITSERVER} > ${dir $@}/known_hosts
	chown -R www-data:www-data ${dir $@}/known_hosts


## copy ssh, ssl and munge keys from KEYHOME

/etc/ssh/opusrr:
	mkdir -p ${dir $@}
	rsync -zav ${ADMIN}@${KEYHOME}/ssh/opusrr* ${dir $@}
	chown www-data:www-data $@ $@.pub
	chmod 400 $@
	chmod 444 $@.pub

/etc/munge/munge.key:
	mkdir -p ${dir $@}
	apt-get -qq install munge
	rsync -zav ${ADMIN}@${KEYHOME}/munge/munge.key $@
	chmod 400 $@
	chmod 700 ${dir $@}
	chown munge:munge ${dir $@} $@

/etc/ssl/${OPUSRR}:
	mkdir -p ${dir $@}
	rsync -zav ${ADMIN}@${KEYHOME}/ssl/${OPUSRR} ${dir $@}
	chmod -R og+rX $@

## generate a new ssh key for remote git access
#
#/etc/ssh/opusrr:
#	ssh-keygen -q -t rsa -f $@ -N ""
#	chown www-data:www-data $@
#	chmod 400 $@


###########################################################################
## end of OPUS specific installation
###########################################################################




## Install the RR Web user interface.
## OBSOLETE
.PHONY: install-grenzschnitte www
install-grenzschnitte www:
	@which letsmt_rest || { \
	    echo "*** The Grenzschnitte needs a LetsMT base installation." >&2 ;\
	    echo "*** Run 'make install' or 'make install-frontend' first." >&2 ;\
	    exit 1 ;\
	}
	$(MAKE) install-grenzschnitte -C installation -f Makefile.prereqs
	$(MAKE) install-grenzschnitte -C installation
	@echo "Installation is finished."


## For quick code updates during development.
## Copy the library and script files to their installed locations and
##  have Apache reload its configuration so that ModPerl runs the new code.
.PHONY: code-update
code-update:
	mkdir -p ${PERL5LIB}
	cp -frp perllib/LetsMT/lib/LetsMT perllib/LetsMT/lib/LetsMT.pm -t ${PERL5LIB}
	@[ -n "${PERL5LIB}" ] && find ${PERL5LIB} -name .svn -exec rm -r {} +
	cp -fp perllib/LetsMT/bin/letsmt_* -t ${PREFIX}/bin
	service apache2 graceful
	@tail -2 /var/log/apache2/error.log \
	    | sed -n -e '/\[error\]/ {s_.*\(\[error\]\)_\1_; s_\\n_\n_g; s_, near _,\n  near _g; p; q1}' \
	    && echo "The updated code has become active."


#########################################################################

## Run automatic tests.
.PHONY: test
test:
	cd ${CURDIR}/perllib/LetsMT/t/fast && bash -c 'prove -r'
	@echo "For thorough testing, run '$(MAKE) test-all'."

.PHONY: test-slow
test-slow:
	cd ${CURDIR}/perllib/LetsMT/t/slow && bash -c 'prove -r'

.PHONY: test-all
test-all:
	cd ${CURDIR}/perllib/LetsMT/t && bash -c 'prove -r'


#########################################################################

.PHONY: doc
doc:
	$(MAKE) all -C perllib/LetsMT/doc

.PHONY: install-doc
install-doc: doc
	$(MAKE) $@ -C installation

	@echo
	@echo "Done installing the documentation."
	@echo


#########################################################################
## uninstalling

.PHONY: real-clean
real-clean:
	@echo "Target 'real-clean' is now called 'purge'."

.PHONY: uninstall purge
uninstall purge: stop-db
	$(MAKE) $@ -C installation
	-$(MAKE) $@ -C www


#########################################################################
## cleaning up

.PHONY: distclean
distclean: clean
	$(MAKE) $@ -C installation -f Makefile.prereqs
	$(MAKE) $@ -C installation
	rm -f perllib/LetsMT/Makefile
	$(MAKE) clean -C perllib/LetsMT/doc
	$(MAKE) $@ -C www

.PHONY: clean
clean:
	rm -rf  perllib/LetsMT/blib \
	        perllib/LetsMT/inc \
	        perllib/LetsMT/pm_to_blib \
	        perllib/LetsMT/META.yml \
	        perllib/LetsMT/MYMETA.json \
	        perllib/LetsMT/MYMETA.yml
	rm -rf  perllib/LetsMT/t/txt \
	        perllib/LetsMT/t/uploads \
	        perllib/LetsMT/t/xml \
	        perllib/LetsMT/t/fast/txt \
	        perllib/LetsMT/t/fast/uploads \
	        perllib/LetsMT/t/fast/xml \
	        perllib/LetsMT/t/slow/txt \
	        perllib/LetsMT/t/slow/uploads \
	        perllib/LetsMT/t/slow/xml \
	        perllib/LetsMT/t/translate.txt
	$(MAKE) $@ -C www


#########################################################################

## Prepare a release file.
## (release number will be copied into LetsMT.pm as VERSION number)
.PHONY: release
release:
	$(eval SVNVERSION=$(shell svnversion))
	$(eval RELEASE=$(shell whiptail --title 'Release number' --inputbox 'What release will this be:' 8 40 "0.50" 2>&1 1>/dev/tty))
	$(eval TMPDIR=$(shell mktemp -d /tmp/letsmt_release_XXXXXX))
# create a tag for the current release
	svn copy  svn://stp.ling.uu.se/letsmt/trunk/dev/src  svn://stp.ling.uu.se/letsmt/tags/${RELEASE}  -m "Release ${RELEASE}"
	svn export  svn://stp.ling.uu.se/letsmt/tags/${RELEASE}  ${TMPDIR}/LetsMT-${RELEASE}
# do not release our internal cron script
	rm -r ${TMPDIR}/LetsMT-${RELEASE}/admin/cron_daily.sh
# write revision and release information to LetsMT.pm & conf.sh
	echo "export LETSMT_SVNVERSION='${SVNVERSION}'" > ${TMPDIR}/LetsMT-${RELEASE}/conf.sh
	echo "export LETSMT_RELEASE='${RELEASE}'"      >> ${TMPDIR}/LetsMT-${RELEASE}/conf.sh
	perl -i -p -e \
	    "s/^\\\$$VERSION\s*=.*\$$/\\\$$VERSION = '$$RELEASE';/" \
	    ${TMPDIR}/LetsMT-${RELEASE}/perllib/LetsMT/lib/LetsMT.pm
# create release package
	tar -zcf LetsMT-${RELEASE}.tar.gz  --directory=${TMPDIR}  LetsMT-${RELEASE}
	rm -r ${TMPDIR}
	@echo "release file: $(PWD)/LetsMT-${RELEASE}.tar.gz"


#########################################################################
## AUXILIARY TARGETS

## Make sure the installation target directory is there.
.PHONY: prepare-target
prepare-target:
	@test -d ${PREFIX} || \
	    { mkdir -p ${PREFIX}; echo "*** mkdir "${PREFIX} >&2; }
	@test -w ${PREFIX} || \
	    { echo "*** Missing write permissions on ${PREFIX}; are you root?" >&2 ; exit 1 ; }


## start or stop TT DB-servers
.PHONY: stop-db
start-db:
	sudo service ttservctl_group restart
	sudo service ttservctl_meta restart


.PHONY: start-db
stop-db:
	[ -x /etc/init.d/ttservctl_group ] && sudo service ttservctl_group stop || true
	[ -x /etc/init.d/ttservctl_meta  ] && sudo service ttservctl_meta  stop || true


# create DB indeces
.PHONY: index-db
index-db:
	${MAKE} -C installation create_metadb_index


# create DB indeces
.PHONY: delete-index
delete-index:
	${MAKE} -C installation delete_metadb_index


#########################################################################
