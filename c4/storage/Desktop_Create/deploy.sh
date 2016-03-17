#!/bin/bash
#
# Desktop deploy script - v6.2
#
# Created by Karoly Molnar <kmolnar@cirruscomputing.com>
# Modified by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2016 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

# Include EnterpriseLibre functions
. ${0%/*}/archive/eseriCommon

# Mark start point in log file
echo "$(date) Deploy Desktop Server"

SYSTEM_ANCHOR_DOMAIN=$(getParameter system_anchor_domain)
IT_MAN_USER=$(getParameter manager_username)
DEFAULT_DOCUMENT_TYPE=$(getParameter document_type)
LDAP_LIBNSS_PW=$(getPassword LDAP_PASSWORD_LIBNSS)
LDAP_DIRECTORY_PASSWORD_ROOT=$(getPassword LDAP_DIRECTORY_PASSWORD_ROOT)
MUTTRC_DOMAIN=$(getParameter domain)
MUTTRC_EMAIL_DOMAIN=$(getParameter email_domain)

# Variables

# Template files
LIBNSS_LDAP_CONFIG=/etc/ldap.conf
LIBNSS_LDAP_TEMPLATE_CONFIG=${TEMPLATE_FOLDER}${LIBNSS_LDAP_CONFIG}
MUTTRC_CONFIG=/etc/Muttrc
MUTTRC_TEMPLATE_CONFIG=${TEMPLATE_FOLDER}${MUTTRC_CONFIG}

# Archive files
SYSTEM_KRB5_KEYTAB=/etc/krb5.keytab

# Get the system parameters
eseriGetDNS
eseriGetNetwork

# Get the Private IP address of the SMC C3.
SMC_C3_IP_PRIVATE=$(grep 'SMC_C3_IP_PRIVATE=' $ARCHIVE_FOLDER/SMC_HOST_IP.txt | sed 's|SMC_C3_IP_PRIVATE=||')
echo "SMC_C3_IP_PRIVATE is $SMC_C3_IP_PRIVATE"


# Deploy Keytab
install -o root -g root -m 440 $ARCHIVE_FOLDER/chaos.host.keytab $SYSTEM_KRB5_KEYTAB

# Install Eseriman user
adduser --gecos "Eseriman" --disabled-password eseriman --home $ESERIMAN_HOME
chmod 750 $ESERIMAN_HOME
install -o eseriman -g eseriman -d $ESERIMAN_HOME/keytabs
install -o eseriman -g eseriman -m 440 $ARCHIVE_FOLDER/chaos.eseriman_admin.keytab $ESERIMAN_HOME/keytabs/eseriman-admin.keytab
install -o root -g root -m 755 -d $ESERIMAN_HOME/bin/
install -o root -g root -m 644 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriCommon
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriArchiveAccount
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriChangePassword
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriCreateAccount
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriCreateHomeFolder
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriCreatePassword
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriCreateMailOnlyAccount
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriDeleteAccount
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriDeleteHomeFolder
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriKillNXSession
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriRestoreAccount
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriSetUserMenu
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriAddAlternateEmail
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriAddSenderEmail
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriDeleteAlternateEmail
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriDeleteSenderEmail
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $TEMPLATE_FOLDER/$ESERIMAN_HOME/bin/eseriDirectory.py
sed -i -e "s|\[-LDAP_DIRECTORY_PASSWORD_ROOT-\]|$LDAP_DIRECTORY_PASSWORD_ROOT|" $ESERIMAN_HOME/bin/eseriDirectory.py
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriChangeUserPrimaryEmailLDAP
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriChangeUserFullnameLDAP
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriChangeUserEmailDomainLDAP
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriGeneratePostmasterReport
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriUpdateDovecotPassDBFile
install -o root -g root -m 755 -d $ESERIMAN_HOME/templates/ldap
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/adduser.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/chatgroup-add.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/chatgroup-delete.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/lastUidUpdate.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/nuxeogroup-add.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/nuxeogroup-cleanup.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/nuxeogroup-delete.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/alternateemail-add.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/alternateemail-delete.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/senderemail-add.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/senderemail-delete.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/mailonly-adduser.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/mailonly-groupadd.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/userprimaryemail-change.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/userfullname-change.ldif.template
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/ldap $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/ldap/useremaildomain-change.ldif.template
install -o root -g root -m 755 -d $ESERIMAN_HOME/templates/desktop/
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/desktop/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/desktop/.gtk-bookmarks
# The below menu templates copied when C3 creates a new user, but are then again overwritten by C3 when the create_menu.pl script is called by C3
install -o root -g root -m 755 -d $ESERIMAN_HOME/templates/desktop/.config/menus/
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/desktop/.config/menus/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/desktop/.config/menus/applications.menu.professional
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/desktop/.config/menus/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/desktop/.config/menus/applications.menu.standard
install -o root -g root -m 644 -t $ESERIMAN_HOME/templates/desktop/.config/menus/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/templates/desktop/.config/menus/settings.menu
install -o eseriman -g eseriman -m 700 -d $ESERIMAN_HOME/.ssh
install -o eseriman -g eseriman -m 600 $ARCHIVE_FOLDER/root/ssh/authorized_keys.c3 $ESERIMAN_HOME/.ssh/authorized_keys

# Install libnss-ldap & nscd
debconf-set-selections $ARCHIVE_FOLDER/seed/ldap-auth-config.seed
aptGetInstall nscd libnss-ldap
install -o root -g root -m 640 $LIBNSS_LDAP_TEMPLATE_CONFIG $LIBNSS_LDAP_CONFIG
eseriReplaceValues $LIBNSS_LDAP_CONFIG
sed -i "s/\[-LDAP_PASSWORD_LIBNSS-\]/$LDAP_LIBNSS_PW/" $LIBNSS_LDAP_CONFIG
/etc/init.d/nscd restart

# Install PAM Kerberos
aptGetInstall libpam-krb5

# Add extra repositories and import keys for them
install -o root -g root -m 644 -t /etc/apt/sources.list.d/ $TEMPLATE_FOLDER/etc/apt/sources.list.d/canonical.list
eseriReplaceValues /etc/apt/sources.list.d/canonical.list
install -o root -g root -m 644 -t /etc/apt/sources.list.d/ $TEMPLATE_FOLDER/etc/apt/sources.list.d/xtrathemes.list
eseriReplaceValues /etc/apt/sources.list.d/xtrathemes.list
install -o root -g root -m 644 -t /etc/apt/sources.list.d/ $TEMPLATE_FOLDER/etc/apt/sources.list.d/gnomenu-team-ppa-lucid.list
eseriReplaceValues /etc/apt/sources.list.d/gnomenu-team-ppa-lucid.list
install -o root -g root -m 644 -t /etc/apt/sources.list.d/ $TEMPLATE_FOLDER/etc/apt/sources.list.d/tiheum-equinox-lucid.list
eseriReplaceValues /etc/apt/sources.list.d/tiheum-equinox-lucid.list
install -o root -g root -m 644 -t /etc/apt/sources.list.d/ $TEMPLATE_FOLDER/etc/apt/sources.list.d/libreoffice-ppa-lucid.list
eseriReplaceValues /etc/apt/sources.list.d/libreoffice-ppa-lucid.list
install -o root -g root -m 644 -t /etc/apt/sources.list.d/ $TEMPLATE_FOLDER/etc/apt/sources.list.d/scribus-ng.list
eseriReplaceValues /etc/apt/sources.list.d/scribus-ng.list
wget -q -O - http://lucid-mirror.wan.virtualorgs.net/keys/bisigi.key | apt-key add -
wget -q -O - http://lucid-mirror.wan.virtualorgs.net/keys/gnomenu-team.key | apt-key add -
wget -q -O - http://lucid-mirror.wan.virtualorgs.net/keys/tiheum.key | apt-key add -
wget -q -O - http://lucid-mirror.wan.virtualorgs.net/keys/libreoffice.key | apt-key add -
wget -q -O - http://lucid-mirror.wan.virtualorgs.net/keys/scribus-ng.key | apt-key add -
apt-get update

# Install Java
echo "sun-java6-bin	shared/accepted-sun-dlj-v1-1	boolean	true" | debconf-set-selections
echo "sun-java6-jre	shared/accepted-sun-dlj-v1-1	boolean	true" | debconf-set-selections
aptGetInstall sun-java6-bin sun-java6-jre

# Install the desktop
debconf-set-selections $ARCHIVE_FOLDER/seed/console-setup.seed
debconf-set-selections $ARCHIVE_FOLDER/seed/libpaper1.seed
dpkg -i $ARCHIVE_FOLDER/packages/eseri/eseri-desktop-openvz_0.2-eseri4_all.deb
apt-get -f -y -q install

# Remove pulseaudio temporarily
apt-get -y remove pulseaudio

# Install LibreOffice
#LibreOffice 3.5
#aptGetInstall libreoffice libreoffice-gnome libreoffice-help-en-us libreoffice-pdfimport libreoffice-presentation-minimizer libreoffice-presenter-console libreoffice-report-builder-bin mozilla-libreoffice libreoffice-filter-binfilter libreoffice-officebean odbc-postgresql libreoffice-report-builder libreoffice-emailmerge libreoffice-wiki-publisher libreoffice-style-andromeda libreoffice-style-crystal libreoffice-style-default libreoffice-style-galaxy libreoffice-style-hicontrast libreoffice-style-oxygen libreoffice-style-tango libreoffice-sdbc-postgresql libreoffice-mysql-connector
#LibreOffice 4.0
aptGetInstall libreoffice libreoffice-gnome libreoffice-help-en-us libreoffice-pdfimport libreoffice-presentation-minimizer libreoffice-presenter-console libreoffice-report-builder-bin browser-plugin-libreoffice libreoffice-officebean odbc-postgresql libreoffice-report-builder libreoffice-emailmerge libreoffice-wiki-publisher libreoffice-style-crystal libreoffice-style-human libreoffice-style-galaxy libreoffice-style-hicontrast libreoffice-style-oxygen libreoffice-style-tango

# Install patch and python
aptGetInstall patch python-lxml python-ldap

# Turn off Font Anti Aliasing and warning about format
dpkg-divert --add --rename --divert /usr/lib/libreoffice/share/registry/main.xcd.orig /usr/lib/libreoffice/share/registry/main.xcd
sed -e 's|"FontAntiAliasing"><prop oor:name="Enabled" oor:type="xs:boolean" oor:nillable="false"><value>true</value>|"FontAntiAliasing"><prop oor:name="Enabled" oor:type="xs:boolean" oor:nillable="false"><value>false</value>|;s|"WarnAlienFormat" oor:type="xs:boolean" oor:nillable="false"><value>true</value>|"WarnAlienFormat" oor:type="xs:boolean" oor:nillable="false"><value>false</value>|' /usr/lib/libreoffice/share/registry/main.xcd.orig > /usr/lib/libreoffice/share/registry/main.xcd

# Default document format
if [ "$DEFAULT_DOCUMENT_TYPE" = "MS" ]; then
        # Excel spreadsheet format
        dpkg-divert --add --rename --divert /usr/lib/libreoffice/share/registry/calc.xcd.orig /usr/lib/libreoffice/share/registry/calc.xcd
        sed -e 's|"ooSetupFactoryDefaultFilter"><value>calc8</value>|"ooSetupFactoryDefaultFilter"><value>MS Excel 97</value>|g' /usr/lib/libreoffice//share/registry/calc.xcd.orig > /usr/lib/libreoffice/share/registry/calc.xcd

        # Powerpoint slides format
        dpkg-divert --add --rename --divert /usr/lib/libreoffice/share/registry/impress.xcd.orig /usr/lib/libreoffice/share/registry/impress.xcd
        sed -e 's|"ooSetupFactoryDefaultFilter"><value>impress8</value>|"ooSetupFactoryDefaultFilter"><value>MS PowerPoint 97</value>|g' /usr/lib/libreoffice/share/registry/impress.xcd.orig > /usr/lib/libreoffice/share/registry/impress.xcd

        # MsWord doc format
        dpkg-divert --add --rename --divert /usr/lib/libreoffice/share/registry/writer.xcd.orig /usr/lib/libreoffice/share/registry/writer.xcd
        sed -e 's|"ooSetupFactoryDefaultFilter"><value>writerglobal8</value>|"ooSetupFactoryDefaultFilter"><value>MS Word 97</value>|g;s|"ooSetupFactoryDefaultFilter"><value>writer8</value>|"ooSetupFactoryDefaultFilter"><value>MS Word 97</value>|g' /usr/lib/libreoffice/share/registry/writer.xcd.orig > /usr/lib/libreoffice/share/registry/writer.xcd
fi

# Open all libreoffice apps in un-maximized windows - writer, base and math already open un-maximized.
sed -i -e 's|"ooSetupFactoryWindowAttributes"><value>,,,;4;</value>|"ooSetupFactoryWindowAttributes"><value/>|g' /usr/lib/libreoffice/share/registry/calc.xcd /usr/lib/libreoffice/share/registry/impress.xcd /usr/lib/libreoffice/share/registry/draw.xcd

# Install more packages (These eventually need to be added to the eseri-desktop-openvz package as dependency)
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula boolean true" | debconf-set-selections
aptGetInstall gnucash flashplugin-nonfree ttf-mscorefonts-installer unixodbc unrar zip unzip rar tofrodos db4.6-util gnucash-docs menu libnss3-tools sun-java6-plugin language-pack-gnome-en keepassx

################
##### Gimp #####
################
hasCapability Gimp
if [ $? -eq 0 ] ; then
    aptGetInstall gimp gimp-help-en gimp-data-extras
fi

###################
##### Scribus #####
###################
hasCapability Scribus
if [ $? -eq 0 ] ; then
    aptGetInstall scribus-ng
fi

####################
##### Inkscape #####
####################
hasCapability Inkscape
if [ $? -eq 0 ] ; then
    aptGetInstall inkscape
fi

####################
##### FreeMind #####
####################
hasCapability FreeMind
if [ $? -eq 0 ] ; then
    aptGetInstall freemind
fi

########################
##### ProjectLibre #####
########################
hasCapability ProjectLibre
if [ $? -eq 0 ] ; then
    dpkg -i  $ARCHIVE_FOLDER/packages/projectlibre/projectlibre_1.5.5-1.deb
fi

# Install games that work
aptGetInstall aisleriot glchess glines gnect gnobots2 gnome-mahjongg gnome-sudoku gnomine gnotravex gnotski gtali iagno

# Modify yelp so we can easily override the original yelp package and further upgrades will not remove our modification
dpkg-divert --add --rename --divert /usr/bin/yelp.orig /usr/bin/yelp
install -o root -g root -m 755 -t /usr/bin $ARCHIVE_FOLDER/files/usr/bin/yelp

# Link launchpad integration to yelp that points to the Eseri help
ln -s yelp /usr/bin/launchpad-integration

# SPAM processing hook
hasCapability Email
if [ $? -eq 0 ] ; then
	dpkg-divert --add --rename --divert /usr/bin/bogofilter.bin /usr/bin/bogofilter
	ssh-keygen -b 4096 -t rsa -P "" -f /root/.ssh/id_rsa
	ssh-keyscan -t rsa -H hera.$DOMAIN | tee -a /root/.ssh/known_hosts
	ssh-copy-id -i /root/.ssh/id_rsa root@hera.$DOMAIN
fi

# Install gnomenu
aptGetInstall gnomenu

# Set gnomenu defaults
install -o root -g root -m 644 -t /usr/share/gconf/defaults/ $TEMPLATE_FOLDER/usr/share/gconf/defaults/99_EnterpriseLibre-gnomenu
eseriReplaceValues /usr/share/gconf/defaults/99_EnterpriseLibre-gnomenu

# Deploy files
install -o root -g root -m 644 -t /etc/default/ $ARCHIVE_FOLDER/files/etc/default/locale
install -o root -g root -m 644 -t /etc/firefox/pref/ $ARCHIVE_FOLDER/files/etc/firefox/pref/homepage.properties
install -o root -g root -m 644 -t /etc/auth-client-config/profile.d $ARCHIVE_FOLDER/files/etc/auth-client-config/profile.d/eseri
install -o root -g root -m 440 -t /etc/sudoers.d $ARCHIVE_FOLDER/files/etc/sudoers.d/EnterpriseLibreCloudManager
install -o root -g root -m 440 -t /etc/sudoers.d $ARCHIVE_FOLDER/files/etc/sudoers.d/EnterpriseLibreLeaveSession
install -o root -g root -m 440 -t /etc/sudoers.d $ARCHIVE_FOLDER/files/etc/sudoers.d/EnterpriseLibreDSPAMTrain
install -o root -g root -m 440 -t /etc/sudoers.d $ARCHIVE_FOLDER/files/etc/sudoers.d/eseriman
install -o root -g root -m 755 -t /usr/bin $ARCHIVE_FOLDER/files/usr/bin/bogofilter
install -o root -g root -m 755 -t /usr/local/bin $ARCHIVE_FOLDER/files/usr/local/bin/eseriKrb5Renew
install -o root -g root -m 700 -t /usr/local/bin $ARCHIVE_FOLDER/files/usr/local/bin/EnterpriseLibreLeaveSession
install -o root -g root -m 700 -t /usr/local/bin $ARCHIVE_FOLDER/files/usr/local/bin/EnterpriseLibreCloudManager
eseriReplaceValues /usr/local/bin/EnterpriseLibreCloudManager
install -o root -g root -m 755 -d /usr/local/share/EnterpriseLibre
install -o root -g root -m 755 -t /usr/local/share/EnterpriseLibre $ARCHIVE_FOLDER/files/usr/local/share/EnterpriseLibre/EnterpriseLibreLeaveSession.py
install -o root -g root -m 755 -t /usr/local/share/EnterpriseLibre $TEMPLATE_FOLDER/usr/local/share/EnterpriseLibre/EnterpriseLibreDSPAMTrain
eseriReplaceValues /usr/local/share/EnterpriseLibre/EnterpriseLibreDSPAMTrain
install -o root -g root -m 755 -d /usr/local/share/EnterpriseLibre/glade
install -o root -g root -m 644 -t /usr/local/share/EnterpriseLibre/glade $ARCHIVE_FOLDER/files/usr/local/share/EnterpriseLibre/glade/EnterpriseLibreLeaveSession.glade
install -o root -g root -m 644 -t /usr/local/share/EnterpriseLibre/glade $ARCHIVE_FOLDER/files/usr/local/share/EnterpriseLibre/glade/EnterpriseLibreCloudManager.glade
install -o root -g root -m 755 -d /usr/local/share/desktop-directories/
install -o root -g root -m 644 -t /usr/local/share/desktop-directories/ $ARCHIVE_FOLDER/files/usr/local/share/desktop-directories/collaboration.directory
install -o root -g root -m 644 -t /usr/local/share/desktop-directories/ $ARCHIVE_FOLDER/files/usr/local/share/desktop-directories/projects.directory
install -o root -g root -m 644 -t /usr/local/share/desktop-directories/ $ARCHIVE_FOLDER/files/usr/local/share/desktop-directories/office.directory
install -o root -g root -m 644 -t /usr/local/share/desktop-directories/ $ARCHIVE_FOLDER/files/usr/local/share/desktop-directories/graphics.directory
install -o root -g root -m 644 -t /usr/local/share/desktop-directories/ $ARCHIVE_FOLDER/files/usr/local/share/desktop-directories/accessories.directory
install -o root -g root -m 644 -t /usr/local/share/desktop-directories/ $ARCHIVE_FOLDER/files/usr/local/share/desktop-directories/games.directory
install -o root -g root -m 644 -t /usr/local/share/desktop-directories/ $ARCHIVE_FOLDER/files/usr/local/share/desktop-directories/enterprise.directory
install -o root -g root -m 644 -t /usr/local/share/desktop-directories/ $ARCHIVE_FOLDER/files/usr/local/share/desktop-directories/visualization.directory
install -o root -g root -m 644 -t /usr/local/share/desktop-directories/ $ARCHIVE_FOLDER/files/usr/local/share/desktop-directories/financial.directory
install -o root -g root -m 644 -t /usr/local/share/desktop-directories/ $ARCHIVE_FOLDER/files/usr/local/share/desktop-directories/internet.directory
install -o root -g root -m 755 -d /usr/local/share/applications/
hasCapability Email
if [ $? -eq 0 ] ; then
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/evolution.desktop
fi
hasCapability Internet
if [ $? -eq 0 ] ; then
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/firefox.desktop
fi
hasCapability InstantMessaging
if [ $? -eq 0 ] ; then
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/pidgin.desktop
fi
hasCapability LibreOffice
if [ $? -eq 0 ] ; then
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/openoffice.org-writer.desktop
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/openoffice.org-impress.desktop
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/openoffice.org-base.desktop
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/openoffice.org-calc.desktop
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/openoffice.org-math.desktop
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/openoffice.org-draw.desktop
fi
hasCapability Gimp
if [ $? -eq 0 ] ; then
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/gimp.desktop
fi
hasCapability Scribus
if [ $? -eq 0 ] ; then
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/scribus.desktop
fi
hasCapability Inkscape
if [ $? -eq 0 ] ; then
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/inkscape.desktop
fi
####################
##### FreeMind #####
####################
hasCapability FreeMind
if [ $? -eq 0 ] ; then
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/freemind.desktop
fi

########################
##### ProjectLibre #####
########################
hasCapability ProjectLibre
if [ $? -eq 0 ] ; then
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/projectlibre.desktop
fi

hasCapability VUE
if [ $? -eq 0 ] ; then
    install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/vue.desktop
fi
install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/gnucash.desktop
install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/gnomecc.desktop
install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/enterpriselibre-cloudmanager.desktop
install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/gedit.desktop
install -o root -g root -m 644 -t /usr/local/share/applications/ $ARCHIVE_FOLDER/files/usr/local/share/applications/keepassx.desktop
install -o root -g root -m 755 -d /usr/local/share/icons/hicolor/64x64/apps/
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/EnterpriseLibreHelpAndSupport.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/EnterpriseLibreCloudManager.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/drupal.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/mailinglists.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/wiki.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/nuxeo.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/orangehrm.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/sogo.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/timesheet.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/trac.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/vtiger.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/webhuddle.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/redmine.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/phpscheduleit.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/vue.png
install -o root -g root -m 644 -t /usr/local/share/icons/hicolor/64x64/apps/ $ARCHIVE_FOLDER/files/usr/local/share/icons/hicolor/64x64/apps/syncthing.png
install -o root -g root -m 755 -d /usr/local/share/icons/gnome/22x22/categories/
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/22x22/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/22x22/categories/applications-humanresources.png
install -o root -g root -m 755 -d /usr/local/share/icons/gnome/24x24/categories/
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/24x24/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/24x24/categories/applications-customermanagement.png
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/24x24/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/24x24/categories/applications-web.png
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/24x24/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/24x24/categories/applications-financial.png
install -o root -g root -m 755 -d /usr/local/share/icons/gnome/48x48/categories/
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/48x48/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/48x48/categories/applications-customermanagement.png
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/48x48/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/48x48/categories/applications-humanresources.png
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/48x48/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/48x48/categories/applications-web.png
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/48x48/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/48x48/categories/applications-financial.png
install -o root -g root -m 755 -d /usr/local/share/icons/gnome/16x16/categories/
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/16x16/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/16x16/categories/applications-customermanagement.png
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/16x16/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/16x16/categories/applications-humanresources.png
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/16x16/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/16x16/categories/applications-web.png
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/16x16/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/16x16/categories/applications-financial.png
install -o root -g root -m 755 -d /usr/local/share/icons/gnome/64x64/categories/
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/64x64/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/64x64/categories/applications-collaboration.png
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/64x64/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/64x64/categories/applications-projects.png
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/64x64/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/64x64/categories/applications-enterprise.png
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/64x64/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/64x64/categories/applications-visualization.png
install -o root -g root -m 644 -t /usr/local/share/icons/gnome/64x64/categories/ $ARCHIVE_FOLDER/files/usr/local/share/icons/gnome/64x64/categories/applications-financial.png
install -o root -g root -m 755 -d /usr/local/share/eseri/
install -o root -g root -m 755 -t /usr/local/share/eseri/ $ARCHIVE_FOLDER/files/usr/local/share/eseri/EseriLog
install -o root -g root -m 644 -t /usr/local/share/eseri/ $ARCHIVE_FOLDER/files/usr/local/share/eseri/addressbook.db.dump
install -o root -g root -m 644 -t /usr/local/share/eseri/ $ARCHIVE_FOLDER/files/usr/local/share/eseri/eseriUserCrontab
install -o root -g root -m 755 -t /usr/local/share/eseri/ $ARCHIVE_FOLDER/files/usr/local/share/eseri/eseriUserInit
parseCapabilities /usr/local/share/eseri/eseriUserInit
install -o root -g root -m 755 -t /usr/local/share/eseri/ $ARCHIVE_FOLDER/files/usr/local/share/eseri/eseriUserMenuRedistribute
install -o root -g root -m 755 -t /usr/local/share/eseri/ $ARCHIVE_FOLDER/files/usr/local/share/eseri/pwdecrypt
install -o root -g root -m 755 -t /usr/local/share/eseri/ $ARCHIVE_FOLDER/files/usr/local/share/eseri/pwencrypt
install -o root -g root -m 755 -d /usr/local/share/eseri/desktop/
install -o root -g root -m 644 -t /usr/local/share/eseri/desktop/ $TEMPLATE_FOLDER/usr/local/share/eseri/desktop/StartHere.desktop
install -o root -g root -m 755 -d /usr/local/share/eseri/ffautomation/
install -o root -g root -m 644 -t /usr/local/share/eseri/ffautomation/ $ARCHIVE_FOLDER/files/usr/local/share/eseri/ffautomation/LoginWebhuddle.js
install -o root -g root -m 644 -t /usr/local/share/eseri/ffautomation/ $ARCHIVE_FOLDER/files/usr/local/share/eseri/ffautomation/user.js
install -o root -g root -m 644 -t /usr/local/share/eseri/ffautomation/ $ARCHIVE_FOLDER/files/usr/local/share/eseri/ffautomation/profiles.ini
install -o root -g root -m 644 -t /usr/local/share/eseri/ffautomation/ $ARCHIVE_FOLDER/files/usr/local/share/eseri/ffautomation/Login.js
parseCapabilities /usr/local/share/eseri/ffautomation/Login.js
install -o root -g root -m 755 -d /usr/local/share/eseri/ffautomation/shared
install -o root -g root -m 644 -t /usr/local/share/eseri/ffautomation/shared $ARCHIVE_FOLDER/files/usr/local/share/eseri/ffautomation/shared/testTabbedBrowsingAPI.js
install -o root -g root -m 644 -t /usr/local/share/eseri/ffautomation/shared $ARCHIVE_FOLDER/files/usr/local/share/eseri/ffautomation/shared/testUtilsAPI.js
install -o root -g root -m 755 -d /usr/local/share/eseri/pidgin/
install -o root -g root -m 755 -d /usr/local/share/mime/packages/
install -o root -g root -m 755 -d /usr/local/share/icons/showtime/32x32/mimetypes/
install -o root -g root -m 644 -t /usr/share/gconf/defaults/ $ARCHIVE_FOLDER/files/usr/share/gconf/defaults/99_EnterpriseLibre-artwork
install -o root -g root -m 644 -t /usr/share/gconf/defaults/ $ARCHIVE_FOLDER/files/usr/share/gconf/defaults/99_EnterpriseLibre-metacity
install -o root -g root -m 644 -t /usr/share/gconf/defaults/ $ARCHIVE_FOLDER/files/usr/share/gconf/defaults/99_EnterpriseLibre-panel-default-setup.entries
install -o root -g root -m 755 -d /usr/share/themes/EnterpriseLibre/
install -o root -g root -m 644 -t /usr/share/themes/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/themes/EnterpriseLibre/index.theme
install -o root -g root -m 755 -d /usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/___start-here-glow.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/_start-here-glow.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/start-here-depressed.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/start-here-glow.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/start-here.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/themedata.xml
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Button/Ubuntu_Button_Gnomenu/themepreview.png
install -o root -g root -m 755 -d /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Menu/EnterpriseLibre/EnterpriseLibre.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Menu/EnterpriseLibre/applications-accessories.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Menu/EnterpriseLibre/emblem-favorite.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Menu/EnterpriseLibre/folder-documents.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Menu/EnterpriseLibre/folder-recent.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Menu/EnterpriseLibre/m_tab.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Menu/EnterpriseLibre/search-frame.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Menu/EnterpriseLibre/start-menu.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Menu/EnterpriseLibre/system-search.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Menu/EnterpriseLibre/system-shutdown.png
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Menu/EnterpriseLibre/themedata.xml
install -o root -g root -m 644 -t /usr/share/gnomenu/Themes/Menu/EnterpriseLibre/ $ARCHIVE_FOLDER/files/usr/share/gnomenu/Themes/Menu/EnterpriseLibre/themepreview.png

# Apply authentication configuration
auth-client-config -p eseri -a
/etc/init.d/nscd restart

# Regenerate Icon caches
/usr/bin/gtk-update-icon-cache --force /usr/share/icons/hicolor
/usr/bin/gtk-update-icon-cache --force /usr/share/icons/gnome

# Update gconf defaults
update-gconf-defaults

# Applications
APPLICATION_ESERI_FOLDER=/usr/local/share/applications
install -o root -g root -m 644 -t /usr/local/share/applications $TEMPLATE_FOLDER/usr/local/share/applications/*
eseriReplaceValues $APPLICATION_ESERI_FOLDER/drupal.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/orangehrm.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/mailinglists.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/nuxeo.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/timesheet.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/trac.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/vtiger.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/webhuddle.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/wiki.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/sogo.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/sqlledger.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/redmine.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/phpscheduleit.desktop
eseriReplaceValues $APPLICATION_ESERI_FOLDER/syncthing.desktop

# Create the global shared folder 
mkdir /srv/shared
chmod go+w /srv/shared

# Set Firefox trusted uris for negotiation
cat >>/etc/firefox/pref/firefox.js <<EOF
// Trusted sites
pref("network.negotiate-auth.trusted-uris", "$DOMAIN");
// Home page
pref("browser.startup.homepage", "resource:/defaults/syspref/homepage.properties");
// First run and upgraded pages are disabled
pref("startup.homepage_override_url", "");
pref("startup.homepage_welcome_url", "");
EOF

# Modify the syslog configuration so the login events are going to be collected in /var/log/eseri.log
cat >>/etc/syslog-ng/syslog-ng.conf <<EOF
# Eseri customization START
# local5.*        -/var/log/eseri.log
destination df_eseri { file("/var/log/eseri.log"); };
filter f_eseri { facility(local5); };
log {
        source(s_all);
        filter(f_eseri);
        destination(df_eseri);
};
# Eseri customization END
EOF
/etc/init.d/syslog-ng reload

# Eseri Log 2 Users
install -o root -g root -m 755 $TEMPLATE_FOLDER/etc/cron.hourly/EseriLog2Users /etc/cron.hourly/
eseriReplaceValues /etc/cron.hourly/EseriLog2Users

# Create Eseri log folder
ESERI_LOG_FOLDER=/var/log/eseri
mkdir $ESERI_LOG_FOLDER
chown eseriman:adm $ESERI_LOG_FOLDER

# Deploy XMPP Certificate
hasCapability InstantMessaging
if [ $? -eq 0 ] ; then
	awk 'BEGIN {x = 0}; /^-----BEGIN CERTIFICATE-----/ {x = 1} {if(x == 1) {print}}' $ARCHIVE_FOLDER/xmpp.${DOMAIN}_cert.pem > /usr/local/share/eseri/pidgin/xmpp_crt.pem
fi

# Install required packages for mozmill automation and password manipulation
aptGetInstall python-setuptools python-pip sqlite3
pip install $ARCHIVE_FOLDER/packages/mozmill/mozmill.pybundle

# Install additional themes and icons
aptGetInstall bisigi-themes faenza-icon-theme

# Custom background which is a view of earth from space, with a legend in the lower right corner
install -o root -g root -m 644 -t /usr/share/backgrounds/ $ARCHIVE_FOLDER/files/usr/share/backgrounds/infinity.jpg
IN_RESULT=`ls -l /usr/share/backgrounds/infinity.jpg`
echo "installing our infinity.jpg, $IN_RESULT"

# Nuxeo plugins
hasCapability Nuxeo
if [ $? -eq 0 ] ; then
	# Install Firefox plugins
	FF_PLUGIN_NUXEO_DRAGDROP_VERSION=0.9.15
	mkdir /usr/share/mozilla-nuxeo-dragdrop-$FF_PLUGIN_NUXEO_DRAGDROP_VERSION
	unzip -d /usr/share/mozilla-nuxeo-dragdrop-$FF_PLUGIN_NUXEO_DRAGDROP_VERSION $ARCHIVE_FOLDER/packages/firefox/nuxeo-dragdrop-ff-extension-$FF_PLUGIN_NUXEO_DRAGDROP_VERSION.xpi
	ln -s mozilla-nuxeo-dragdrop-$FF_PLUGIN_NUXEO_DRAGDROP_VERSION /usr/share/mozilla-nuxeo-dragdrop
	ln -s ../../../share/mozilla-nuxeo-dragdrop /usr/lib/firefox-addons/extensions/nuxeo-dragdrop-ff-extension@nuxeo.org
	cat >/usr/share/mozilla-nuxeo-dragdrop/defaults/preferences/defaultprefs.js <<EOF
pref("extensions.nxdnd.encoding", "");
pref("extensions.nxdnd.skipConfirm", true);
EOF

	FF_PLUGIN_NUXEO_PROTOCOL_VERSION=0.5.2
	mkdir /usr/share/mozilla-nuxeo-liveedit-$FF_PLUGIN_NUXEO_PROTOCOL_VERSION
	unzip -d /usr/share/mozilla-nuxeo-liveedit-$FF_PLUGIN_NUXEO_PROTOCOL_VERSION $ARCHIVE_FOLDER/packages/firefox/nuxeo-liveedit-ff-protocolhandler-$FF_PLUGIN_NUXEO_PROTOCOL_VERSION.xpi
	ln -s mozilla-nuxeo-liveedit-$FF_PLUGIN_NUXEO_PROTOCOL_VERSION /usr/share/mozilla-nuxeo-liveedit
	ln -s ../../../share/mozilla-nuxeo-liveedit /usr/lib/firefox-addons/extensions/{76ecb654-ca45-5ba3-7753-cefdac478198}
	find /usr/share/mozilla-nuxeo-liveedit/ -type d -exec chmod 755 '{}' \;
	#The below line is only need for liveedit v0.4.1
	#cat >/usr/share/mozilla-nuxeo-liveedit/chrome.manifest <<EOF
#content nxeditprotocol  jar:chrome/nxeditprotocol.jar!/content/nxeditprotocol/
#skin    nxeditprotocol  classic/1.0     jar:chrome/nxeditprotocol.jar!/skin/classic/nxeditprotocol/
#EOF
	cat >/usr/share/mozilla-nuxeo-liveedit/defaults/preferences/defaultprefs.js <<EOF
// default preferences
pref("extensions.nxedit.username", "Administrator");
pref("extensions.nxedit.password", "Administrator");
pref("extensions.nxedit.workdir", "/tmp/");
pref("extensions.nxedit.defaulteditor", "/usr/bin/gedit");
pref("extensions.nxedit.defaulteditorargs", "%s");
// HashMap mimeMapping = new HashMap();
pref("extensions.nxedit.mimeMapping", "application/vnd.oasis.opendocument.text:/usr/bin/soffice@@argsmacro%3A///LiveEditOOo.launcher.load%28%25s%29;application/vnd.oasis.opendocument.spreadsheet:/usr/bin/soffice@@argsmacro%3A///LiveEditOOo.launcher.load%28%25s%29;application/vnd.oasis.opendocument.presentation:/usr/bin/soffice@@argsmacro%3A///LiveEditOOo.launcher.load%28%25s%29;application/msword:/usr/bin/soffice@@argsmacro%3A///LiveEditOOo.launcher.load%28%25s%29;application/vnd.ms-excel:/usr/bin/soffice@@argsmacro%3A///LiveEditOOo.launcher.load%28%25s%29;application/vnd.ms-powerpoint:/usr/bin/soffice@@argsmacro%3A///LiveEditOOo.launcher.load%28%25s%29;");
// Is NXWss
pref("extensions.nxedit.isnxwss", "false");
EOF
	sed -i -e 's/0666/0600/g' /usr/share/mozilla-nuxeo-liveedit/components/nxEditProtocol.js

	# Install and patch the Nuxeo Liveedit OOo package
	unopkg add --shared $ARCHIVE_FOLDER/packages/ooo_ext/nuxeo-liveedit-ooo-lateststable.oxt
	patch -u `find /var/spool/libreoffice -name actions.xba` < $ARCHIVE_FOLDER/patches/actions.xba.patch
fi

# Install OpenOffice plugins
unopkg add --shared $ARCHIVE_FOLDER/packages/ooo_ext/en_CA_2_0_0.oxt

# Remove mydns from /etc/nsswitch.conf
sed -i -e 's/^hosts:.*$/hosts:\t\tfiles dns/' /etc/nsswitch.conf

# C3 Backwards Compatibility
ln -s /usr/share/ca-certificates/$DOMAIN/CA.crt /usr/share/ca-certificates/$DOMAIN/$DOMAIN.crt

# Remove menu entries that are problematic
dpkg-divert --add --rename --divert /usr/share/applications/alacarte.desktop.disabled /usr/share/applications/alacarte.desktop

dpkg-divert --add --rename --divert /usr/share/applications/display-properties.desktop.disabled /usr/share/applications/display-properties.desktop

dpkg-divert --add --rename --divert /usr/share/applications/gnome-volume-control.desktop.disabled /usr/share/applications/gnome-volume-control.desktop

dpkg-divert --add --rename --divert /usr/share/applications/palimpsest.desktop.disabled /usr/share/applications/palimpsest.desktop

dpkg-divert --add --rename --divert /usr/share/applications/gnome-system-log.desktop.disabled /usr/share/applications/gnome-system-log.desktop

dpkg-divert --add --rename --divert /usr/share/applications/checkbox-gtk.desktop.disabled /usr/share/applications/checkbox-gtk.desktop

dpkg-divert --add --rename --divert /usr/share/applications/gnome-about-me.desktop.disabled /usr/share/applications/gnome-about-me.desktop

dpkg-divert --add --rename --divert /usr/share/applications/gnome-screensaver-preferences.desktop.disabled /usr/share/applications/gnome-screensaver-preferences.desktop

dpkg-divert --add --rename --divert /usr/share/applications/ibus-setup.desktop.disabled /usr/share/applications/ibus-setup.desktop

# Remove Windows Networking from Places -> Network
mkdir /usr/lib/gvfs.disabled
mkdir /usr/share/gvfs/mounts.disabled

dpkg-divert --add --rename --divert /usr/lib/gvfs.disabled/gvfsd-smb /usr/lib/gvfs/gvfsd-smb
dpkg-divert --add --rename --divert /usr/lib/gvfs.disabled/gvfsd-smb-browse /usr/lib/gvfs/gvfsd-smb-browse
dpkg-divert --add --rename --divert /usr/share/gvfs/mounts.disabled/smb-browse.mount /usr/share/gvfs/mounts/smb-browse.mount
dpkg-divert --add --rename --divert /usr/share/gvfs/mounts.disabled/smb.mount /usr/share/gvfs/mounts/smb.mount

# Remove panel applets
dpkg-divert --add --rename --divert /usr/lib/bonobo/servers/GNOME_BattstatApplet.server.disabled /usr/lib/bonobo/servers/GNOME_BattstatApplet.server
dpkg-divert --add --rename --divert /usr/lib/bonobo/servers/GNOME_CPUFreqApplet.server.disabled /usr/lib/bonobo/servers/GNOME_CPUFreqApplet.server
dpkg-divert --add --rename --divert /usr/lib/bonobo/servers/GNOME_DriveMountApplet.server.disabled /usr/lib/bonobo/servers/GNOME_DriveMountApplet.server

# Acrobat reader
debconf-set-selections $ARCHIVE_FOLDER/seed/acroread.seed
aptGetInstall acroread
# Installing latest Adobe Reader
dpkg -i $ARCHIVE_FOLDER/packages/adobe/acroread_9.5.1-1lucid1_i386.deb

#French dictionaries
aptGetInstall hunspell-fr aspell-fr wfrench

# Double-Lock

install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriCreatePamObcConf
install -o root -g root -m 755 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files$ESERIMAN_HOME/bin/eseriCreatePamObcConf.py

install -o root -g root -m 644 -t /etc/pam.d/ $ARCHIVE_FOLDER/files/etc/pam.d/gnome-screensaver
install -o root -g root -m 644 -t /etc/xdg/autostart/ $ARCHIVE_FOLDER/files/etc/xdg/autostart/gnome-screensaver-command.desktop
install -o root -g root -m 755 -t /usr/lib/gnome-screensaver $ARCHIVE_FOLDER/files/usr/lib/gnome-screensaver/gnome-screensaver-dialog
install -o root -g root -m 644 -t /usr/share/gnome-screensaver $ARCHIVE_FOLDER/files/usr/share/gnome-screensaver/lock-dialog-default.ui
install -o root -g root -m 644 -t /usr/share/gnome-screensaver $ARCHIVE_FOLDER/files/usr/share/gnome-screensaver/EnterpriseLibre.png

install -o root -g root -m 644 -t /lib/security/ $ARCHIVE_FOLDER/files/lib/security/pam_obc.so

aptGetInstall mutt
install -o root -g root -m 644 $MUTTRC_TEMPLATE_CONFIG $MUTTRC_CONFIG
sed -i "s/\[-MUTTRC_DOMAIN-\]/$MUTTRC_DOMAIN/" $MUTTRC_CONFIG
sed -i "s/\[-MUTTRC_EMAIL_DOMAIN-\]/$MUTTRC_EMAIL_DOMAIN/" $MUTTRC_CONFIG

#Installing Firefox-24.1.1esr
FIREFOX='firefox-24.1.1esr'
#Copying New Firefox directory
tar -C /usr/lib/ -zxvf $ARCHIVE_FOLDER/packages/firefox/$FIREFOX.tar.gz
chown -R root:root /usr/lib/$FIREFOX
#Replacing Firefox Theme
rm -r /usr/lib/firefox-addons/extensions/\{972ce4c6-7e08-4474-a285-3208198ce6fd\}/
tar -C /usr/lib/firefox-addons/extensions/ -zxvf $ARCHIVE_FOLDER/packages/firefox/$FIREFOX-theme.tar.gz
#Removing Old Language Pack
rm -r /usr/lib/firefox-addons/extensions/langpack-en-GB\@firefox-3.6.ubuntu.com/
#Trusted URI
cat >>/usr/lib/$FIREFOX/defaults/pref/firefox.js <<EOF
// Trusted sites
pref("network.negotiate-auth.trusted-uris", "$DOMAIN");
EOF
#Setting default homepage (Works differently after FF 3.6)
cat >>/etc/firefox/profile/prefs.js <<EOF
user_pref("browser.startup.homepage", "http://www.google.com");
EOF
#Creating links to Firefox
mv /usr/bin/firefox /usr/bin/firefox36
ln -s ../lib/$FIREFOX/firefox.sh /usr/bin/firefox

#Installing Scribus 1.4.1
dpkg -i $ARCHIVE_FOLDER/packages/scribus/scribus_1.4.1-1_i386.deb

#Evolution Work online script
install -o root -g root -m 755 -d /usr/local/share/eseri/evolution/
install -o root -g root -m 644 -t /usr/local/share/eseri/evolution/ $ARCHIVE_FOLDER/files/usr/local/share/eseri/evolution/evolutionWorkOnline.xml
install -o root -g root -m 644 -t /etc/xdg/autostart/ $ARCHIVE_FOLDER/files/etc/xdg/autostart/evolution-work-online.desktop

#Fix for the Start Button which stops working if tapped twice quickly.
patch -u /usr/lib/gnomenu/Menu_Main.py < $ARCHIVE_FOLDER/patches/Menu_Main.py.patch 

hasCapability VUE
if [ $? -eq 0 ] ; then
        install -o root -g root -m 755 -t /usr/bin/ $ARCHIVE_FOLDER/packages/vue/vue
fi

#Gnome Panel Custom
#This executable doesn't display the dialog when applets fail to load.
install -o root -g root -m 755 -t /usr/bin $ARCHIVE_FOLDER/files/usr/bin/gnome-panel
#Gnome Applet Reload script
#This script detects when there is an applet failure and recovers from it at startup only.
install -o root -g root -m 644 -t /etc/xdg/autostart/ $ARCHIVE_FOLDER/files/etc/xdg/autostart/gnome-applet-reload.desktop
install -o root -g root -m 755 -t /usr/local/share/EnterpriseLibre $ARCHIVE_FOLDER/files/usr/local/share/EnterpriseLibre/EnterpriseLibreGnomeAppletReload

# Timezone Config extra pkg
aptGetInstall python-tz 

# Email Validation
aptGetInstall libemail-valid-perl

# Setup crontab for Postmaster Report Generation.
echo "00 02 * * * sudo /var/lib/eseriman/bin/eseriGeneratePostmasterReport" | crontab -u eseriman -

# NX Caps Lock issue fix
aptGetInstall lineakd xdotool

# Restrict user from installing packages locally, disable a few commands.
cd /usr/bin
chmod 750 apt-get dpkg dpkg-deb dpkg-buildpackage dpkg-source aptitude

# Syncthing
hasCapability Syncthing
if [ $? -eq 0 ] ; then
    install -o root -g root -m 755 -t /usr/bin/ $ARCHIVE_FOLDER/packages/syncthing-custom/syncthing
fi

##################
##### Amanda #####
##################

hasCapability Amanda
if [ $? -eq 0 ] ; then
    BACKUP_SERVER=$(getParameter backup_server)
    MYSQL_PASSWORD=$(getPassword DB_PASSWORD_MYSQL)
    
    # Install the required packages
    aptGetInstall libreadline5
    aptGetInstall xinetd
    dpkg -i $ARCHIVE_FOLDER/packages/amanda/libkrb53_1.8.3+dfsg-4squeeze5_all.deb
    dpkg -i $ARCHIVE_FOLDER/packages/amanda/amanda-backup-client_3.3.1-1Ubuntu804_i386.deb
    
    # Copy the xinetd configuration for Amanda
    install -o root -g root -m 644 /var/lib/amanda/example/xinetd.amandaclient /etc/xinetd.d/amandaclient
    /etc/init.d/xinetd restart
    
    # Adding the Backup Server details
    cd /var/lib/amanda
    echo $BACKUP_SERVER backup amdump >> .amandahosts
    echo AnyDish65 >> .am_passphrase
    chown amandabackup:disk ~amandabackup/.amandahosts
    chown amandabackup:disk ~amandabackup/.am_passphrase
    chown amandabackup:disk ~amandabackup/.profile
    chmod 700 ~amandabackup/.amandahosts
    chmod 700 ~amandabackup/.am_passphrase
    chown amandabackup:disk /usr/sbin/amcryptsimple
    chmod 750 /usr/sbin/amcryptsimple

    #Creating amandabackup key
    su - -c "cd ~/.ssh; ssh-keygen -f id_rsa -N '' -t rsa -q" amandabackup

    # Copy the Pre-amcheck Script
    install -o root -g root -m 755 -t /usr/libexec/amanda/application/ $TEMPLATE_FOLDER/usr/libexec/amanda/application/backupChaos.sh
    sed -i "s|\[-MYSQLPW-\]|$MYSQL_PASSWORD|" /usr/libexec/amanda/application/backupChaos.sh
    eseriReplaceValues /usr/libexec/amanda/application/backupChaos.sh
    chown root:disk /usr/libexec/amanda
    chmod 750 /usr/libexec/amanda
    
    # Copy the conf file for amrecover
    install -o amandabackup -g disk -m 600 $TEMPLATE_FOLDER/etc/amanda/amanda-client.conf /etc/amanda/amanda-client.conf
    sed -i "s|\[-BACKUP_SERVER-\]|$BACKUP_SERVER|" /etc/amanda/amanda-client.conf
    
    # Copy the excludePath file
    install -o amandabackup -g disk -d /etc/amanda/exclude
    install -o amandabackup -g disk -m 644 -t /etc/amanda/exclude/ $ARCHIVE_FOLDER/files/etc/amanda/exclude/excludePath    
    eseriReplaceValues /etc/amanda/exclude/excludePath
fi

# For Cloud Manager Backup_Config enhancement.
pip install ordereddict

# Set total_procs to 100:125 for nagios.
cat >>/etc/nagios/nrpe_local.cfg <<EOF
command[check_total_procs]=/usr/lib/nagios/plugins/check_procs -w 100 -c 125
EOF

# Install a script to set the total procs limit for nagios
install -o root -g root -m 440 -t /etc/sudoers.d $ARCHIVE_FOLDER/files/etc/sudoers.d/eseriConfigureNagiosProcsLimit
install -o root -g root -m 700 -t $ESERIMAN_HOME/bin/ $ARCHIVE_FOLDER/files/$ESERIMAN_HOME/bin/eseriConfigureNagiosProcsLimit

hasCapability NoMachine
if [ $? -eq 0 ] ; then
    # Install NX
    dpkg -i $ARCHIVE_FOLDER/packages/nx/nx-3.5/*.deb

    # Deploy nxclient modification for hiding printer attach dialog
    dpkg-divert --add --rename --divert /usr/NX/bin/nxclient.bin /usr/NX/bin/nxclient
    install -o root -g root -m 755 -t /usr/NX/bin $ARCHIVE_FOLDER/files/usr/NX/bin/nxclient

    # Remove NXClient application links
    rm -f /etc/xdg/menus/applications-merged/nxclient.menu

    install -o root -g root -m 755 -d /usr/NX/scripts/eseriEvents/
    install -o root -g root -m 755 -t /usr/NX/scripts/eseriEvents/ $ARCHIVE_FOLDER/files/usr/NX/scripts/eseriEvents/NodeBeforeSessionClose
    install -o root -g root -m 755 -t /usr/NX/scripts/eseriEvents/ $ARCHIVE_FOLDER/files/usr/NX/scripts/eseriEvents/NodeAfterSessionReconnect
    install -o root -g root -m 755 -t /usr/NX/scripts/eseriEvents/ $ARCHIVE_FOLDER/files/usr/NX/scripts/eseriEvents/NodeAfterSessionClose
    install -o root -g root -m 755 -t /usr/NX/scripts/eseriEvents/ $ARCHIVE_FOLDER/files/usr/NX/scripts/eseriEvents/NodeBeforeSessionSuspend
    install -o root -g root -m 755 -t /usr/NX/scripts/eseriEvents/ $ARCHIVE_FOLDER/files/usr/NX/scripts/eseriEvents/NodeBeforeSessionReconnect
    install -o root -g root -m 755 -t /usr/NX/scripts/eseriEvents/ $ARCHIVE_FOLDER/files/usr/NX/scripts/eseriEvents/NodeAfterSessionStart
    install -o root -g root -m 755 -t /usr/NX/scripts/eseriEvents/ $ARCHIVE_FOLDER/files/usr/NX/scripts/eseriEvents/NodeAfterSessionSuspend
    install -o root -g root -m 755 -t /usr/NX/scripts/eseriEvents/ $ARCHIVE_FOLDER/files/usr/NX/scripts/eseriEvents/NodeBeforeSessionStart

    # Generate a new SSH key
    /usr/NX/scripts/setup/nxserver --keygen
    chown nx:root /usr/NX/home/nx/.ssh/authorized_keys2 && \
	chmod 0644 /usr/NX/home/nx/.ssh/authorized_keys2 && \
	chown nx:root /usr/NX/home/nx/.ssh/default.id_dsa.pub && \
	chmod 0644 /usr/NX/home/nx/.ssh/default.id_dsa.pub
    
    # Modify the NX server configuration
    NX_SERVER_CONFIG=/usr/NX/etc/server.cfg
    sed -i '/^#SessionUserLimit/ a\
SessionUserLimit = "1"' $NX_SERVER_CONFIG

    # Modify the NX node configuration
    NX_NODE_CONFIG=/usr/NX/etc/node.cfg
    sed -i '/^#AgentExtraOptions/ a\
AgentExtraOptions = "-noshpix"' $NX_NODE_CONFIG
    sed -i '/^#UserScriptBeforeSessionStart/ a\
UserScriptBeforeSessionStart = "/usr/NX/scripts/eseriEvents/NodeBeforeSessionStart"' $NX_NODE_CONFIG
    sed -i '/^#UserScriptAfterSessionStart/ a\
UserScriptAfterSessionStart = "/usr/NX/scripts/eseriEvents/NodeAfterSessionStart"' $NX_NODE_CONFIG
    sed -i '/^#UserScriptBeforeSessionSuspend/ a\
UserScriptBeforeSessionSuspend = "/usr/NX/scripts/eseriEvents/NodeBeforeSessionSuspend"' $NX_NODE_CONFIG
    sed -i '/^#UserScriptAfterSessionSuspend/ a\
UserScriptAfterSessionSuspend = "/usr/NX/scripts/eseriEvents/NodeAfterSessionSuspend"' $NX_NODE_CONFIG
    sed -i '/^#UserScriptBeforeSessionClose/ a\
UserScriptBeforeSessionClose = "/usr/NX/scripts/eseriEvents/NodeBeforeSessionClose"' $NX_NODE_CONFIG
    sed -i '/^#UserScriptAfterSessionClose/ a\
UserScriptAfterSessionClose = "/usr/NX/scripts/eseriEvents/NodeAfterSessionClose"' $NX_NODE_CONFIG
    sed -i '/^#UserScriptBeforeSessionReconnect/ a\
UserScriptBeforeSessionReconnect = "/usr/NX/scripts/eseriEvents/NodeBeforeSessionReconnect"' $NX_NODE_CONFIG
    sed -i '/^#UserScriptAfterSessionReconnect/ a\
UserScriptAfterSessionReconnect = "/usr/NX/scripts/eseriEvents/NodeAfterSessionReconnect"' $NX_NODE_CONFIG
    sed -i '/^#EnableFileSharing/ a\
EnableFileSharing = "1"' $NX_NODE_CONFIG
    sed -i 's/^MountShareProtocol =.*/MountShareProtocol = "both"/' $NX_NODE_CONFIG

    # Copy the new key to the result folder for further processing - used for user login
    cp /usr/NX/share/keys/default.id_dsa.key $RESULT_FOLDER/default.id_dsa.key

    # Fine tune the SSH Daemon's config file
    sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
    cat >>/etc/ssh/sshd_config <<EOF

# Disallow users in mailonly group
DenyGroups mailonly

# Tunnelled clear text passwords authentication is enabled only on localhost for NX auth
PasswordAuthentication no
Match Address 127.0.0.1
PasswordAuthentication yes
Match Address $SMC_C3_IP_PRIVATE
PasswordAuthentication yes
EOF

    #Copy the SSH/authorized_keys2 file into /etc/skel with the right permissions
    if [ ! -d /etc/skel/.ssh ] ; then
	mkdir /etc/skel/.ssh
	chmod 700 /etc/skel/.ssh
    fi
    echo -n 'no-port-forwarding,no-agent-forwarding,command="/usr/NX/bin/nxnode" ' > /etc/skel/.ssh/authorized_keys2
    cat /usr/NX/etc/keys/node.localhost.id_dsa.pub >> /etc/skel/.ssh/authorized_keys2
    chmod 600 /etc/skel/.ssh/authorized_keys2
fi

hasCapability X2Go
if [ $? -eq 0 ] ; then
    aptGetInstall gnome-colors-common libconfig-simple-perl pwgen libdbd-sqlite3-perl libfile-basedir-perl libfile-which-perl libcapture-tiny-perl libdbd-pg-perl
    dpkg -i $ARCHIVE_FOLDER/packages/x2go/*

    install -o root -g root -m 755 -t /usr/lib/x2go/extensions/post-resume.d/ $ARCHIVE_FOLDER/files/usr/lib/x2go/extensions/post-resume.d/010_post_resume
    install -o root -g root -m 755 -t /usr/lib/x2go/extensions/post-start.d/ $ARCHIVE_FOLDER/files/usr/lib/x2go/extensions/post-start.d/010_post_start
    install -o root -g root -m 755 -t /usr/lib/x2go/extensions/post-suspend.d/ $ARCHIVE_FOLDER/files/usr/lib/x2go/extensions/post-suspend.d/010_post_suspend
    install -o root -g root -m 755 -t /usr/lib/x2go/extensions/post-terminate.d/ $ARCHIVE_FOLDER/files/usr/lib/x2go/extensions/post-terminate.d/010_post_terminate
    install -o root -g root -m 755 -t /usr/lib/x2go/extensions/pre-resume.d/ $ARCHIVE_FOLDER/files/usr/lib/x2go/extensions/pre-resume.d/010_pre_resume
    install -o root -g root -m 755 -t /usr/lib/x2go/extensions/pre-start.d/ $ARCHIVE_FOLDER/files/usr/lib/x2go/extensions/pre-start.d/010_pre_start
    install -o root -g root -m 755 -t /usr/lib/x2go/extensions/pre-suspend.d/ $ARCHIVE_FOLDER/files/usr/lib/x2go/extensions/pre-suspend.d/010_pre_suspend
    install -o root -g root -m 755 -t /usr/lib/x2go/extensions/pre-terminate.d/ $ARCHIVE_FOLDER/files/usr/lib/x2go/extensions/pre-terminate.d/010_pre_terminate

    # Copy the SSH DSA key to the result folder for further processing - not used after replacement of NoMachine.
    cp /etc/ssh/ssh_host_dsa_key $RESULT_FOLDER/default.id_dsa.key
    
    # Fine tune the SSH Daemon's config file
    sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
    cat >>/etc/ssh/sshd_config <<EOF

# Disallow users in mailonly group
DenyGroups mailonly

PasswordAuthentication yes
Match Address 127.0.0.1
PasswordAuthentication yes
Match Address $SMC_C3_IP_PRIVATE
PasswordAuthentication yes
EOF

    #Copy the SSH/authorized_keys2 file into /etc/skel with the right permissions - not used after replacement of NoMachine.
    if [ ! -d /etc/skel/.ssh ] ; then
	mkdir /etc/skel/.ssh
	chmod 700 /etc/skel/.ssh
    fi
    cat /etc/ssh/ssh_host_dsa_key.pub >> /etc/skel/.ssh/authorized_keys2
    chmod 600 /etc/skel/.ssh/authorized_keys2
fi

# Evolution cannot connect to IMAP server with SSL3 disabled. Installed the following compiled package which includes evolution poodle patch.
dpkg -i $ARCHIVE_FOLDER/packages/evolution/evolution-data-server*.deb

exit 0
